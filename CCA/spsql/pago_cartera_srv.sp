/************************************************************************/
/*   Nombre Fisico:        PagoCarteraSrv.sp                            */
/*   Nombre Logico:        sp_pago_cartera_srv      					*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raúl Altamirano Mendez                       */
/*   Fecha de escritura:   Junio 2017                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
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
/*                                   PROPOSITO                          */
/*   Realiza la Aplicacion de los Pagos a los Prestamos procesados en ar*/
/*   chivo de retiro para banco SANTANDER MX, con respuesta OK.         */
/*                              CAMBIOS                                 */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*   FECHA        AUTOR                    RAZON                        */
/* 04/Dic/2017   P. Ortiz      Control de cambios Santander(S147562)    */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_cartera_srv')
   drop proc sp_pago_cartera_srv
go

create proc sp_pago_cartera_srv
(
@s_ssn            int         = null,
@s_user           login       = null,
@s_sesn           int         = null,
@s_term           varchar(30) = null,
@s_date           datetime    = null,
@s_srv            varchar(30) = null,
@s_lsrv           varchar(30) = null,
@s_ofi            smallint    = null,
@s_servicio       int         = null,
@s_cliente        int         = null,
@s_rol            smallint    = null,
@s_culture        varchar(10) = null,
@s_org            char(1)     = null,
@i_banco          cuenta,
@i_fecha_valor    datetime    = null,
@i_forma_pago     catalogo,
@i_monto_pago     money,
@i_cuenta         cuenta       = null, 
@i_ref_leyenda    VARCHAR(40)  = NULL,-- Por seguros VBR
@i_ejecutar_fvalor char(1)     = 'S', -- parametro cuando se llama al sp_pago_cartera_srv no se ejecute la fecha valor y le traiga a las op a fecha actual
@i_en_linea       char(1)      = 'S',
@o_error          int          = null out,
@o_msg            varchar(255) = null out,
@o_secuencial_ing int          = null out,
@o_secuencial     int          = null out
)
as 

declare
@w_error              int,
@w_fecha_proceso      datetime,
@w_fecha_inicial      datetime,
@w_fecha_dia          datetime,
@w_banco              cuenta,
@w_operacionca        int,
@w_fecha_ult_proceso  datetime,
@w_fecha_respuesta    datetime,
@w_cuenta             cuenta,
@w_tipo_reduccion     char(1),
@w_moneda             smallint,
@w_beneficiario       varchar(64),
@w_sp_name            varchar(30),
@w_secuencial_ing     int,
@w_dividendo          INT,
@w_commit             char(1),
@w_est_vigente        int,
@w_est_vencido        int,
@w_fecha_pago         datetime,
@w_tipo               char(3),
@w_return             int,
@w_oficina            smallint,
@w_oficial            smallint,
@w_gar_admisible      char(1),
@w_reestructuracion   char(1),
@w_calificacion       catalogo,
@w_codvalor           INT,
@w_monto_seg          MONEY

select 
@w_sp_name         = 'sp_pago_cartera_srv',
@w_fecha_dia       = getdate(),
@w_commit          = 'N'

/*DETERMINAR FECHA DE PROCESO*/
select 
@w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre 
where  fc_producto = 7

select 
@w_operacionca          = op_operacion,
@w_fecha_ult_proceso    = op_fecha_ult_proceso,
@w_beneficiario         = op_nombre,
@w_cuenta               = isnull(op_cuenta,@i_cuenta),
@w_moneda               = op_moneda,
@w_tipo_reduccion       = op_tipo_reduccion,
@w_oficina              = op_oficina,
@w_oficial              = op_oficial,
@w_fecha_inicial        = op_fecha_ini,
@w_gar_admisible        = op_gar_admisible,
@w_reestructuracion     = op_reestructuracion,
@w_calificacion         = op_calificacion
from  ca_operacion 
where op_banco    = @i_banco

if @@rowcount = 0 begin
   select 
   @w_error = 2101011,
   @o_msg = 'NO EXISTE PRESTAMO ' + @i_banco
   goto ERROR_PROCESO
end


select @w_tipo = substring(@i_ref_leyenda,1,3)

/***** insertar la transaccion para la contabilidad SEGUROS ***/

if @w_tipo = 'SEG' begin

   select @w_monto_seg = se_monto
   from  ca_seguro_externo
   where se_banco  = @i_banco
   and   se_estado = 'N' 
   if @@rowcount <> 0 begin 
       select 
	   @w_error = 70121,
       @o_msg = 'NO EXISTE REGISTRO DE SEGURO EXTERNO DEL PRESTAMO: ' + @i_banco
   end 
   
   exec @o_secuencial = cob_cartera..sp_gen_sec
   @i_operacion       = -4
   
   select @w_codvalor = convert(INT,cr_codvalor + '0')
   from  ca_codvalor_rubro
   where co_concepto    = 'CAP'
   and   es_descripcion = 'VIGENTE'
  
   if @@trancount = 0 begin  
      select @w_commit = 'S'
      begin tran
   end

   update ca_seguro_externo
   set    se_estado = 'S'
   where  se_banco = @i_banco
 
   if @@error <> 0 begin
     select 
	 @w_error = 708152,
	 @o_msg   = 'ERROR AL ACTUALIZAR COMO PAGADO AL SEGURO EXTERNO'
     goto ERROR_PROCESO
   end
 
   insert into ca_transaccion (
   tr_secuencial,        tr_fecha_mov,        tr_toperacion,
   tr_moneda,            tr_operacion,        tr_tran,
   tr_en_linea,          tr_banco,            tr_dias_calc,
   tr_ofi_oper,          tr_ofi_usu,          tr_usuario,
   tr_terminal,          tr_fecha_ref,        tr_secuencial_ref,
   tr_estado,            tr_gerente,          tr_gar_admisible,
   tr_reestructuracion,  tr_calificacion,
   tr_observacion,       tr_fecha_cont,       tr_comprobante
	   )
   values(
   @o_secuencial,        @s_date,             'GRUPAL',
   @w_moneda,            -4,                  'SEG',
   'S',                  @i_banco,            0,
   @w_oficina,           @s_ofi,              @s_user,
   @s_term,              @w_fecha_inicial,     -999,
   'ING',                @w_oficial,          isnull(@w_gar_admisible,''),
   isnull(@w_reestructuracion,''),            isnull(@w_calificacion,''),
   'COBRO SEGURO',       @s_date,             0)

   if @@error <> 0 begin
      select 
	  @w_error = 710030,
	  @o_msg   = 'ERROR AL CREAR TRANSACCION DE SEGUROS'
      goto ERROR_PROCESO
   end


   -- INSERCION DEL DETALLE DE LA TRANSACCION
   insert ca_det_trn (
   dtr_secuencial,    dtr_operacion,           dtr_dividendo,        dtr_concepto,
   dtr_estado,        dtr_periodo,             dtr_codvalor,         dtr_monto,
   dtr_monto_mn,      dtr_moneda,              dtr_cotizacion,       dtr_tcotizacion,
   dtr_afectacion,    dtr_cuenta,              dtr_beneficiario,     dtr_monto_cont
   )
   values(
   @o_secuencial,     @w_operacionca,          0,                    'CAP',
   1,                 0,                       @w_codvalor,          @w_monto_seg,
   @w_monto_seg,      @w_moneda,               1,                    'N',
   'D',               '00000',                 'SEGURO',              0
   )

   if @@error <> 0 begin
      select 
	  @w_error = 710031,
	  @o_msg   = 'ERROR AL CREAR DETALLE TRANSACCION DE SEGUROS'
	  goto ERROR_PROCESO
   end

   if @w_commit = 'S' begin  
      select @w_commit = 'N'
      commit tran
   end   
   
   return 0
end --FIN DE SEGUROS 	


exec @w_error   = sp_estados_cca
@o_est_vigente  = @w_est_vigente   OUT,
@o_est_vencido  = @w_est_vencido   OUT


if @w_error <> 0
begin 
   SELECT
   @w_error = 701103,
   @o_msg = 'Error !:No exite estado vencido'
   goto ERROR_PROCESO
end


select 
@w_dividendo  = isnull(max(di_dividendo),0)
from  ca_dividendo
where di_operacion = @w_operacionca
and di_estado in(@w_est_vigente,@w_est_vencido)

if @@rowcount = 0 begin
   select 
   @w_error = 701103,
   @o_msg = 'NO EXISTE CUOTA EXIGIBLE EN EL PRESTAMO ' + @i_banco
   goto ERROR_PROCESO
end

if @@trancount = 0 begin  
   select @w_commit = 'S'
   begin tran
end


if datediff(dd,@w_fecha_proceso, @i_fecha_valor)<>0 begin 

   exec @w_error = sp_fecha_valor 
   @s_date        = @w_fecha_proceso,     -- @s_date, REQ 457 se cambia para aplicacion de pagos con fecha valor en conciliacion
   @s_user        = @s_user,
   @s_term        = @s_term,
   @s_ofi         = @s_ofi ,
   @t_trn         = 7049,
   @i_fecha_mov   = @w_fecha_proceso, --@w_fecha_ult_proceso,
   @i_fecha_valor = @i_fecha_valor,
   @i_banco       = @i_banco,
   @i_secuencial  = 1,
   @i_operacion   = 'F'
   
   if @w_error != 0 begin
      select @o_msg = 'ERROR AL EJECUTAR PROCESO DE FECHA VALOR INICIAL'
      goto ERROR_PROCESO
   end
  
end


exec @w_error = sp_pago_cartera
@s_user           = @s_user,
@s_term           = @s_term,
@s_date           = @w_fecha_proceso,
@s_sesn           = @s_sesn,
@s_ofi            = @s_ofi ,
@s_ssn            = @s_ssn,
@s_srv            = @s_srv,
@i_banco          = @i_banco,
@i_beneficiario   = @w_beneficiario,
@i_fecha_vig      = @i_fecha_valor,  --Fecha con la que registra el pago en la abono y abono_det
@i_ejecutar       = 'S',
@i_en_linea       = 'S',
@i_producto       = @i_forma_pago, 
@i_monto_mpg      = @i_monto_pago,
@i_cuenta         = @w_cuenta,
@i_moneda         = @w_moneda,
@i_dividendo      = @w_dividendo, 
@i_tipo_reduccion = @w_tipo_reduccion,
@i_pago_gar_grupal= 'N',
@i_pago_ext       = 'N',      
@o_secuencial_ing = @w_secuencial_ing out

if @w_error <> 0 begin
   select @o_msg = 'ERROR AL EJECUTAR PROCESO PAGO DE CARTERA DEL PRESTAMO ' + @i_banco
   goto ERROR_PROCESO
end   

if datediff(dd,@w_fecha_proceso, @i_fecha_valor)<>0 begin

   select 
   @w_fecha_pago = op_fecha_ult_proceso
   from  ca_operacion 
   where op_banco    = @i_banco
   --print 'i_ejecutar_fvalor '+ @i_ejecutar_fvalor
   if(@i_ejecutar_fvalor =  'S' ) --Se ejecuta por defecto fecha valor que es llamado desde el corresponsal_batch opcion B
   begin
      exec @w_error = sp_fecha_valor 
      @s_date        = @w_fecha_proceso,     -- @s_date, REQ 457 se cambia para aplicacion de pagos con fecha valor en conciliacion
      @s_user        = @s_user,
      @s_term        = @s_term,
      @s_ofi         = @s_ofi ,
      @t_trn         = 7049,
      @i_fecha_mov   = @w_fecha_proceso, --@w_fecha_pago,
      @i_fecha_valor = @w_fecha_proceso, --@w_fecha_ult_proceso,
      @i_banco       = @i_banco,
      @i_secuencial  = 1,
      @i_en_linea    = @i_en_linea,
      @i_operacion   = 'F'
      
      if @w_error != 0 begin
         select @o_msg = 'ERROR AL RETORNAR A LA FECHA ORIGINAL DEL PRESTAMO ' + @i_banco
         goto ERROR_PROCESO
      end
   end
end

SELECT @o_secuencial_ing = @w_secuencial_ing



if @w_commit = 'S' begin  
   select @w_commit = 'N'
   commit tran
end

return 0
   
ERROR_PROCESO:

if @w_commit = 'S' begin  
   select @w_commit = 'N'
   rollback tran
end

select @o_error = @w_error

return @w_error

go

