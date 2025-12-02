/************************************************************************/
/*   Nombre Fisico:      cavalprv.sp                                    */
/*   Nombre Logico:      sp_valida_existencia_prv                       */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Elcira Pelaez                                  */
/*   Fecha de escritura: Ene 2004                                       */
/************************************************************************/
/*                                IMPORTANTE                            */
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
/*                                 PROPOSITO                            */
/*   Procedimiento que valida si existe ya una transaccion PRV  y retor */
/*   na el secuencial respectivo                                        */
/************************************************************************/
/*      FECHA           AUTOR      CAMBIO                               */
/*   MAY 2006           FQ         NR428                                */
/*   DIC 2006           IFJ        DEF 4767                             */
/*   ABR-10-2007         FGQ        DEFECTO 4767 Revision Pasivas       */
/*   AGO-23-2007        JJRO       Optimizacion OPT_224                 */
/*   06/06/2023	     M. Cordova	   Cambio variable @w_calificacion,   	*/
/*								   de char(1) a catalogo 				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valida_existencia_prv')
   drop proc sp_valida_existencia_prv
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_valida_existencia_prv
   @s_user                login,
   @s_term                varchar(30),
   @s_date                datetime,
   @s_ofi                 smallint,
   @i_en_linea            char(1) = 'N',
   @i_operacionca         int,
   @i_fecha_proceso       datetime,
   @i_tr_observacion      char(62) = '',
   @i_gar_admisible       char(1),
   @i_reestructuracion    char(1),
   @i_calificacion        catalogo,
   @i_toperacion          catalogo,
   @i_moneda              smallint,
   @i_oficina             int,
   @i_banco               cuenta,
   @i_gerente             smallint,
   @i_moneda_uvr          smallint,
   @i_tipo                char(1) = ' ',
   @i_tran                catalogo = 'PRV',
   @i_secuencial_ref      int      = 0,
   @o_secuencial          int  out

as
declare
   @w_secuencial        int,
   @w_error             int,
   @w_transaccion_nueva char(1),
   @w_tran              catalogo,
   @w_fecha_ini         datetime,
   @w_sec_op_control    int      -- IFJ Def 4767

select @w_secuencial          = null,
       @w_transaccion_nueva   = 'N'

if exists(select 1
          from cobis..cl_tabla t, cobis..cl_catalogo c
          where t.tabla = 'ca_incentivo_vis'
          and   c.tabla = t.codigo
          and   c.codigo = @i_toperacion
          and   c.estado = 'V') -- LA LINEA ES DE INCENTIVO VIS
begin
   select @w_fecha_ini = di_fecha_ini
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_dividendo = 1
   
   select @w_fecha_ini = dateadd(yy, 5, @w_fecha_ini)
   
   if @i_fecha_proceso = @w_fecha_ini
   begin
      if (select count(1)
                from   ca_transaccion
                where  tr_operacion = @i_operacionca
                and    tr_tran = 'INCVIS'
                and    tr_estado = 'NCO') > 0
         select @i_fecha_proceso = @w_fecha_ini
      ELSE
      begin
         exec @w_secuencial = sp_gen_sec
              @i_operacion  = @i_operacionca
         
         -- ESTA TRANSACCION HACE QUE SE REQUIERA UNA NUEVA PRV
         insert into ca_transaccion
               (tr_secuencial,     tr_fecha_mov,        tr_toperacion,
                tr_moneda,         tr_operacion,        tr_tran,
                tr_en_linea,       tr_banco,            tr_dias_calc,
                tr_ofi_oper,       tr_ofi_usu,          tr_usuario,
                tr_terminal,       tr_fecha_ref,        tr_secuencial_ref,
                tr_estado,         tr_observacion,      tr_gerente,
                tr_gar_admisible,  tr_reestructuracion,
                tr_calificacion,   tr_fecha_cont,       tr_comprobante)
         values(@w_secuencial,     @s_date,             @i_toperacion,
                @i_moneda,         @i_operacionca,      'INCVIS',
                @i_en_linea,       @i_banco,            1,
                @i_oficina,        @i_oficina,          @s_user,
                @s_term,           @i_fecha_proceso,    0,
                'NCO',             @i_tr_observacion,   @i_gerente,
                @i_gar_admisible,  @i_reestructuracion,
                @i_calificacion,   @s_date,             0)
         
         select @w_transaccion_nueva = 'S'
         goto VERIFICACION
      end
   end
end

-- Inicio IFJ Def 4767
select @w_sec_op_control = oc_ult_sectran
from   ca_operacion_control
where  oc_operacion = @i_operacionca

select @w_sec_op_control = isnull(@w_sec_op_control, 0)

-- SE BUSCA LA ULTIMA TRANSACCION VALIDA
select @w_secuencial = max(tr_secuencial)
from   ca_transaccion
where  tr_operacion = @i_operacionca
and    (tr_estado   in ('CON', 'ING') or tr_tran in('SUA', 'HFM','MIG','HFP'))
having max(tr_secuencial) >= @w_sec_op_control 

-- Fin IFJ Def 4767

if @w_secuencial is null -- NO SE ENCONTRO UNA ULTIMA TRANSACCION
begin
   select @w_transaccion_nueva = 'S'
end
ELSE -- VERIFICAR QUE LA ULTIMA TRANSACCION ES UNA TRANSACCION PRV
begin
   if @i_tipo = 'D'
      select @w_tran = 'AMO'
   ELSE
   begin
      if @i_moneda = @i_moneda_uvr
         select @w_tran = 'CMO'
      else
         select @w_tran = 'PRV'
   end
   
   if exists(select 1
             from   ca_transaccion
             where  tr_operacion  = @i_operacionca
             and    tr_secuencial = @w_secuencial
             and    tr_tran       = @w_tran
             and    tr_secuencial_ref != -999) --- CUANDO SE CREA LA PRV ENSEGUIDA SE CREA UNA CMO
                                              ---         POR ESO SE BUSCA LA CMO
                                              --- NOTA: LA TRANSACCION CMO LA CREA EL este sp
                                              ---       LOS DETALLES DE LA CMO LOS CREA cada sp QUE LO LLAMA
   begin
      select @w_transaccion_nueva = 'N'
      if @w_tran = 'CMO'
         select @w_secuencial = @w_secuencial - 1
   end
   ELSE
      select @w_transaccion_nueva = 'S'     -- LA ULTIMA TRANSACCION NO CORRESPONDE PARA CAUSACION
end

VERIFICACION:
if @w_transaccion_nueva = 'S'
begin -- CREAR LA NUEVA TRANSACCION PRV
   exec @w_secuencial = sp_gen_sec
        @i_operacion  = @i_operacionca
   
   -- OBTENER RESPALDO EN QUIEBRE DE CAUSACION
   if @i_secuencial_ref != -999
   begin
      exec @w_error  = sp_historial
           @i_operacionca  = @i_operacionca,
           @i_secuencial   = @w_secuencial
      
      if @w_error != 0
         return @w_error
   end
   
   insert into ca_transaccion
         (tr_secuencial,     tr_fecha_mov,        tr_toperacion,
          tr_moneda,         tr_operacion,        tr_tran,
          tr_en_linea,       tr_banco,            tr_dias_calc,
          tr_ofi_oper,       tr_ofi_usu,          tr_usuario,
          tr_terminal,       tr_fecha_ref,        tr_secuencial_ref,
          tr_estado,         tr_observacion,      tr_gerente,
          tr_gar_admisible,  tr_reestructuracion,
          tr_calificacion,   tr_fecha_cont,        tr_comprobante)
   values(@w_secuencial,     @s_date,              @i_toperacion,
          @i_moneda,         @i_operacionca,       @i_tran,
          @i_en_linea,       @i_banco,             1,
          @i_oficina,        @i_oficina,           @s_user,
          @s_term,           @i_fecha_proceso,     @i_secuencial_ref,
          'ING',             @i_tr_observacion,    @i_gerente,
          @i_gar_admisible,  @i_reestructuracion,
          @i_calificacion,   @s_date,              0)
   
   if @@error != 0
      return 708165
   
   if @i_moneda = @i_moneda_uvr
   begin
      -- CREAR LA TRANSACCION CMO ADJUNTA
      insert into ca_transaccion
            (tr_secuencial,     tr_fecha_mov,        tr_toperacion,
             tr_moneda,         tr_operacion,        tr_tran,
             tr_en_linea,       tr_banco,            tr_dias_calc,
             tr_ofi_oper,       tr_ofi_usu,          tr_usuario,
             tr_terminal,       tr_fecha_ref,        tr_secuencial_ref,
             tr_estado,         tr_observacion,      tr_gerente,
             tr_gar_admisible,  tr_reestructuracion,
             tr_calificacion,   tr_fecha_cont,       tr_comprobante)
      values(@w_secuencial+1,   @s_date,             @i_toperacion,
             @i_moneda,         @i_operacionca,      'CMO',
             @i_en_linea,       @i_banco,            1,
             @i_oficina,        @i_oficina,          @s_user,
             @s_term,           @i_fecha_proceso,    0,
             'ING',             'CMO ADJUNTA',       @i_gerente,
             @i_gar_admisible,  @i_reestructuracion,
             @i_calificacion,   @s_date,             0)
      
      if @@error != 0
         return 708165
   end
end
ELSE -- SE PUEDE USAR LA ULTIMA TRANSACCION QUE ES PRV
begin
   update ca_transaccion
   set    tr_dias_calc  = tr_dias_calc + 1,
          tr_estado     = 'ING',
          tr_fecha_mov  = @s_date
   where  tr_secuencial = @w_secuencial
   and    tr_operacion  = @i_operacionca
   
   if @@error != 0
      return 708165
   
   if @i_moneda = @i_moneda_uvr
   begin
      update ca_transaccion
      set    tr_dias_calc  = tr_dias_calc + 1,
             tr_estado     = 'ING',
             tr_fecha_mov  = @s_date  
      where  tr_secuencial = @w_secuencial + 1
      and    tr_operacion  = @i_operacionca
      
      if @@error != 0
         return 708165
   end
end 

select @o_secuencial = @w_secuencial

return 0

go
