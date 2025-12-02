/************************************************************************/
/*      Nombre Fisico:          catrncgr.sp                             */
/*      Nombre Logico:          sp_cambio_garantia                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Diego Aguilar                           */
/*      Fecha de escritura:     Jul 1999                                */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*                              PROPOSITO                               */
/*   Cambio de Garantias CGR  este sp es llamado por Garantias          */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*      FECHA              AUTOR                  RAZON                 */
/*    sep-27-2005        Eclira Pelaez          Generacion de Tran.     */
/*                                              solo en estados procesa-*/
/*                                              bles                    */
/*    Nov-03-2005        Eclira Pelaez          def. 5182               */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

if not exists(select 1 from cobis..cl_errores where numero = 711042)
   insert into cobis..cl_errores values (711042, 1, 'No se puede hacer cambio de ganantia mientras existan CGR pendientes de contabilizar')
go
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_garantia')
    drop proc sp_cambio_garantia
go

create proc sp_cambio_garantia
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              smallint     = null,
   @s_term             varchar (30) = null,
   @i_tramite          int          = null,
   @i_operacion        char(1)      = 'I',
   @i_gar_admisible    char(1)
as

declare
   @w_error                int,
   @w_toperacion           catalogo,
   @w_op_oficina           smallint,
   @w_op_moneda            smallint,
   -- VARIABLES PARA MANEJO DE DECIMALES
   @w_num_dec              tinyint,
   @w_num_dec_mn           tinyint,
   -- VARIABLES PARA LA GENERACION DEL NUMERO BANCO ALR
   @w_operacionca          int,
   @w_banco                cuenta,
   @w_op_gar_admisible_ant char(1),
   @w_gerente              smallint,
   @w_fecha_proceso        datetime,
   @w_moneda_nac           smallint,
   @w_reestructuracion     char(1),
   @w_calificacion         catalogo,
   @w_estado_op            int,
   @w_secuencial           int,
   @w_op_tipo              char(1),
   @w_descripcion          descripcion

-- VARIABLES INICIALES
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre 
where  fc_producto = 7

if @i_operacion = 'I'
begin
   select @w_operacionca            = op_operacion,
          @w_op_moneda              = op_moneda,
          @w_banco                  = op_banco,
          @w_op_oficina             = op_oficina,
          @w_toperacion             = op_toperacion,
          @w_op_gar_admisible_ant   = isnull(op_gar_admisible, 'N'),
          @w_estado_op              = op_estado,
          @w_gerente                = op_oficial,
          @w_reestructuracion       = isnull(op_reestructuracion, ''),
          @w_calificacion           = isnull(op_calificacion, ''),
          @w_op_tipo                = op_tipo
   from   ca_operacion
   where  op_tramite = @i_tramite
   
   -- NO HAY CAMBIO PARA LAS CASTIGADAS
   if @w_estado_op = 4
      return 0
   
   -- NO HAY CAMBIO 
   if @i_gar_admisible is null or (@i_gar_admisible = @w_op_gar_admisible_ant)
      return 0
   
   -- NO HAY CAMBIO PARA LAS PASIVAS
   if @w_op_tipo = 'R'
      return 0
   
   if exists(select 1
             from   ca_transaccion
             where  tr_operacion = @w_operacionca
             and    tr_tran = 'CGR'
             and    tr_estado in ('PVA', 'ING'))
   begin
      return 711042
   end
   
   -- MANEJO DE DECIMALES
   exec @w_error = sp_decimales
        @i_moneda       = @w_op_moneda,
        @o_decimales    = @w_num_dec    out,
        @o_mon_nacional = @w_moneda_nac out,
        @o_dec_nacional = @w_num_dec_mn out
   
   exec @w_secuencial = sp_gen_sec
        @i_operacion   = @w_operacionca
   
   --SOLO GENERA TRANSACCION PARA ESTADOS PROCESABLES
   if exists (select 1 from ca_estado
              where  es_codigo = @w_estado_op
              and    es_procesa = 'S')
   begin
      exec @w_error = sp_trasladador
           @s_user               = @s_user,
           @s_term               = @s_term,
           @s_date               = @s_date,
           @s_ofi                = @s_ofi,
           @i_trn                = 'CGR',
           @i_toperacion         = @w_toperacion,
           @i_oficina            = @w_op_oficina,
           @i_banco              = @w_banco,
           @i_operacionca        = @w_operacionca,
           @i_moneda             = @w_op_moneda,
           @i_fecha_proceso      = @w_fecha_proceso,
           @i_gerente            = @w_gerente,
           @i_moneda_nac         = @w_moneda_nac,
           @i_garantia           = @w_op_gar_admisible_ant,
           @i_reestructuracion   = @w_reestructuracion,
           @i_cuenta_final       = @i_gar_admisible,
           @i_cuenta_antes       = @w_op_gar_admisible_ant,
           @i_calificacion       = @w_calificacion,
           @i_estado_actual      = @w_estado_op,
           @i_secuencial         = @w_secuencial
      
      if @@error <> 0
         return 708152
      
      if @w_error != 0  
      begin
         PRINT 'catrncgr.sp Error Ejecutando sp_trasladador'
         return  @w_error
      end
   end 
   
   select @w_descripcion = 'catrncgr.sp ANTES DE ACTUALIZAR LA ca_operacion con ' + @i_gar_admisible
   
   insert into ca_errorlog
         (er_fecha_proc,      er_error,      er_usuario,
          er_tran,            er_cuenta,     er_descripcion,
          er_anexo)
   values('10/10/2010' ,   0,              @s_user,
          7269,               @w_banco,      @w_descripcion,
          'MENSAJE PARA CONTROL TECNICO UNICAMENTE') 
   
   -- ACTUALIZACION DE ca_operacion
   update ca_operacion
   set    op_gar_admisible = @i_gar_admisible
   where  op_operacion = @w_operacionca
   
   if @@error <> 0
      return 710002
   
   --- ACTUALIZACION DE LA HISTORICA 
   update ca_operacion_his
   set    oph_gar_admisible = @i_gar_admisible
   where  oph_operacion = @w_operacionca
   
   if @@error <> 0
      return  710002
   
   update cob_cartera_his..ca_operacion_his
   set    oph_gar_admisible = @i_gar_admisible
   where  oph_operacion = @w_operacionca
   
   if @@error <> 0
      return 710002
   
   update cob_cartera_depuracion..ca_operacion_his
   set    oph_gar_admisible = @i_gar_admisible
   where  oph_operacion = @w_operacionca
   
   if @@error <> 0
      return 710002
   
   select @i_gar_admisible = op_gar_admisible
   from   ca_operacion
   where  op_operacion = @w_operacionca
   
   select @w_descripcion = 'catrncgr.sp DESPUES DE ACTUALIZAR LA ca_operacion queda con ' + @i_gar_admisible
   
   insert into ca_errorlog
         (er_fecha_proc,      er_error,      er_usuario,
         er_tran,            er_cuenta,     er_descripcion,
         er_anexo)
   values('10/10/2010' ,   0,              @s_user,
          7269,               @w_banco,      @w_descripcion,
          'MENSAJE PARA CONTROL TECNICO UNICAMENTE') 
   
   --- ANULAR LAS TRANSACCIONES ANTERIORES PARA EVITAR  CONTABILIZACION DE REVERSOS
   update ca_transaccion
   set    tr_estado = 'ANU',
          tr_observacion = 'ANULADA POR EFECTO DE ULTIMO CAMBIO DE GARANTIA'
   where  tr_operacion = @w_operacionca
   and    tr_tran = 'CGR'
   and    tr_fecha_mov < @w_fecha_proceso
   
   if @@error <> 0
      return  708152
end ---Operacion I 

return 0

go
