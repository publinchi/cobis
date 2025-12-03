/************************************************************************/
/*   Nombre Fisico      :     cartsobrbatch.sp                          */
/*   Nombre Logico      :     sp_carterizacion_batch                    */
/*   Base de datos      :     cob_cartera                               */
/*   Producto           :     Cartera                                   */
/*   Disenado por       :     Ivan Jimenez                              */
/*   Fecha de escritura :     Abr 2006                                  */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios que son       	*/
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	*/
/*   representantes exclusivos para comercializar los productos y   	*/
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	*/
/*   y regida por las Leyes de la República de España y las         	*/
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	*/
/*   alteración en cualquier sentido, ingeniería reversa,           	*/
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	*/
/*   de los usuarios o personas que hayan accedido al presente      	*/
/*   sitio, queda expresamente prohibido; sin el debido             	*/
/*   consentimiento por escrito, de parte de los representantes de  	*/
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	*/
/*   en el presente texto, causará violaciones relacionadas con la  	*/
/*   propiedad intelectual y la confidencialidad de la información  	*/
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	*/
/*   y penales en contra del infractor según corresponda. 				*/
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Ejecuta sp_carterizacion_sobregiro para carterizar los sobrrgiros  */
/*   para despues vencer la obligacion                                  */
/************************************************************************/
/*                        ACTUALIZACIONES                               */
/*  FECHA            AUTOR             RAZON                            */
/*  17/Jul/2007       FGQ               Correccion def.8494   BAC       */
/*    06/06/2023	 M. Cordova		 Cambio variable @w_calificacion,   */
/*									 de char(1) a catalogo 				*/
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_carterizacion_batch')
   drop proc sp_carterizacion_batch
go

---PRINT 'VER. 2.0 Def.8494 EPB-Jul-17-2007'

create proc sp_carterizacion_batch
as
declare
   @w_sp_name           varchar(30),
   @w_error             int,
   @w_user              login,
   @w_sesn              int,
   @w_ofi               smallint,
   @w_date              datetime,
   @w_term              varchar(30),
   @w_cliente           int,
   @w_toperacion        catalogo,
   @w_oficina           smallint,
   @w_fecha_ini         datetime,
   @w_total_sobregiro   money,
   @w_lin_credito       cuenta,
   @w_codigo_ext_gar    cuenta,
   @w_dias_vencido      smallint,
   @w_calificacion      catalogo,
   @w_operacion         int,
   @w_cs_secuencial     varchar(15)

select @w_sp_name = 'sp_carterizacion_batch'

declare
   carterizar cursor  
   for select cs_sesn,           cs_user,
              cs_ofi,            cs_date,
              cs_term,           cs_cliente,
              cs_toperacion,     cs_oficina,
              cs_fecha_ini,      cs_total_sobregiro,
              cs_lin_credito,    cs_codigo_ext_gar,
              cs_dias_vencido,   cs_calificacion,
              convert(varchar, cs_secuencial)
       from   ca_carteriza_sobregiros
       where  cs_estado_cateriza = 'I'
       and    cs_cliente         > 0
   for update

open carterizar

fetch carterizar
into  @w_sesn,          @w_user,
      @w_ofi,           @w_date,
      @w_term,          @w_cliente,
      @w_toperacion,    @w_oficina,
      @w_fecha_ini,     @w_total_sobregiro,
      @w_lin_credito,   @w_codigo_ext_gar,
      @w_dias_vencido,  @w_calificacion,
      @w_cs_secuencial

--while @@fetch_status not in (-1, 0)
while @@fetch_status = 0
begin
   BEGIN TRAN
   
   exec @w_error = sp_carterizacion_sobregiro
        @s_user            = @w_user,
        @s_sesn            = @w_sesn,
        @s_ofi             = @w_ofi,
        @s_date            = @w_date,
        @s_term            = @w_term,
        @i_cliente         = @w_cliente,
        @i_toperacion      = @w_toperacion,
        @i_oficina         = @w_oficina,
        @i_fecha_ini       = @w_fecha_ini,
        @i_total_sobregiro = @w_total_sobregiro,
        @i_lin_credito     = @w_lin_credito,
        @i_codigo_ext_gar  = @w_codigo_ext_gar,
        @i_dias_vencido    = @w_dias_vencido,
        @i_calificacion    = @w_calificacion,
        @i_procesa_batch   = 'S',
        @i_operacion       = @w_operacion OUT
   
   if @w_error != 0
      goto ERROR_OPERC
      
   -- Actualiza el estado de carterizacion a (P) Procesado
   update ca_carteriza_sobregiros
   set   cs_estado_cateriza = 'P',
         cs_operacion       = @w_operacion
   where current of carterizar
   
   if @@rowcount = 0
   begin
      select @w_error = @@error
      goto ERROR_OPERC
   end
   
   while @@trancount > 0 COMMIT
   
   goto SIGUIENTE_OPERC
   
ERROR_OPERC:
   while @@trancount > 0 ROLLBACK
   
   BEGIN TRAN
   
   exec sp_errorlog
        @i_fecha                = @w_date,
        @i_error                = @w_error,
        @i_usuario              = @w_user,
        @i_tran                 = 7000,
        @i_tran_name            = '',
        @i_rollback             = 'S',
        @i_cuenta               = @w_cs_secuencial
   
   while @@trancount > 0 COMMIT
   
SIGUIENTE_OPERC:
   fetch carterizar
   into  @w_sesn,          @w_user,
         @w_ofi,           @w_date,
         @w_term,          @w_cliente,
         @w_toperacion,    @w_oficina,
         @w_fecha_ini,     @w_total_sobregiro,
         @w_lin_credito,   @w_codigo_ext_gar,
         @w_dias_vencido,  @w_calificacion,
         @w_cs_secuencial
end

close carterizar
deallocate carterizar 


/******************************************************/
/*      CURSOR PARA VENCER LAS OBLIGACIONES           */
/******************************************************/

declare
   @w_op_banco    cuenta

declare vencer_obligacion cursor  
for select cs_user,        cs_ofi,
           cs_date,        cs_term,
           cs_fecha_ini,   cs_operacion,
           cs_toperacion
   from  ca_carteriza_sobregiros
   where cs_estado_cateriza = 'P'
   and   cs_cliente         > 0
   and   cs_estado_batch    = 'N'
for update
 
open vencer_obligacion

fetch vencer_obligacion
into  @w_user,          @w_ofi,
      @w_date,          @w_term,
      @w_fecha_ini,     @w_operacion,
      @w_toperacion
   
--while @@fetch_status not in (-1, 0)
while @@fetch_status = 0
begin

   select @w_op_banco = op_banco
   from   ca_operacion
   where  op_operacion = @w_operacion
   
   exec @w_error = sp_batch
      @s_user           = @w_user,
      @s_term           = @w_term,
      @s_date           = @w_date,
      @s_ofi            = 9000,
      @i_en_linea       = 'N',
      @i_banco          = @w_op_banco,
      @i_siguiente_dia  = @w_fecha_ini
   
   if @w_error != 0
      goto ERROR_BATCH
   
   -- Actualiza el estado de batch a (S) Procesado batch1
   update ca_carteriza_sobregiros
   set    cs_estado_batch   = 'S'
   where current of vencer_obligacion

   if @@rowcount = 0
   begin
      select @w_error = @@error
      goto ERROR_BATCH
   end

   COMMIT TRAN
   
   goto SIGUIENTE_BATCH

ERROR_BATCH:
   while @@trancount > 0 ROLLBACK
   
   BEGIN TRAN
   
   exec sp_errorlog
        @i_fecha                = @w_date,
        @i_error                = @w_error,
        @i_usuario              = @w_user,
        @i_tran                 = 7000,
        @i_tran_name            = '',
        @i_rollback             = 'S',
        @i_cuenta               = @w_op_banco
   
   while @@trancount > 0 COMMIT

SIGUIENTE_BATCH:
   fetch vencer_obligacion
   into  @w_user,          @w_ofi,
         @w_date,          @w_term,
         @w_fecha_ini,     @w_operacion,
         @w_toperacion
end

close vencer_obligacion
deallocate vencer_obligacion

return 0

go
