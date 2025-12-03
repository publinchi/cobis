use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_judicial')
   drop proc sp_cambio_estado_judicial
go

/************************************************************************/
/*   Nombre Fisico:        camestju.sp                                  */
/*   Nombre Logico:        sp_cambio_estado_judicial                    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Patricio Narvaez                             */
/*   Fecha de escritura:   Dic-21-2020                                  */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Realiza el Traslado de los saldos a Judicial generando transaccion */
/*   respectiva                                                         */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*  DIC/21/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*  ABR/17/2023   Guisela Fernandez     S807925 Ingreso de campo de     */
/*                                      reestructuracion                */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/************************************************************************/  
SET ANSI_NULLS ON
GO

create proc sp_cambio_estado_judicial(
   @s_user          login,
   @s_term          varchar(30),
   @i_operacionca   int,
   @i_cotizacion    float,
   @i_tcotizacion   char(1) = 'N',
   @i_num_dec       tinyint,
   @o_msg           varchar(100) = null out
)as 

declare
@w_sp_name           varchar(64),
@w_return            int,
@w_secuencial        int,
@w_error             int,   
@w_pago_sostenido    char(1),   
@w_estado            int,
@w_est_cancelado     tinyint,
@w_est_novigente     tinyint,   
@w_est_vencido       tinyint,   
@w_fecha_proceso     datetime,
@w_fecha_ult_proceso datetime,
@w_calificacion      catalogo,
@w_moneda            tinyint,   
@w_toperacion        catalogo,
@w_banco             cuenta,
@w_oficina           int,
@w_oficial           int,
@w_est_judicial      tinyint,
@w_reestructuracion  char(1)

select 
@w_sp_name 	   = 'sp_cambio_estado_judicial',
@w_secuencial  = 0

--FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7
 
--OBTIENE DATOS DE LA OPERACION
select 
@w_toperacion        = op_toperacion,
@w_moneda            = op_moneda,
@w_banco             = op_banco,
@w_oficina           = op_oficina,
@w_oficial           = op_oficial,       
@w_estado            = op_estado,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_calificacion      = op_calificacion,
@w_reestructuracion  = isnull(op_reestructuracion, 'N')
from  ca_operacion
where op_operacion = @i_operacionca

if @@rowcount = 0                
begin
	select @w_error = 701025, 
		   @o_msg = 'NO EXISTE OPERACION' 
	goto ERROR_FIN
end   
	   
--- ESTADOS DE CARTERA 
exec @w_error     = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_judicial   = @w_est_judicial  out

if @w_error <> 0                
begin
	select @w_error = 710217, 
		   @o_msg = 'NO ENCONTRO ESTADO VENCIDO/VIGENTE PARA CARTERA ' 
	goto ERROR_FIN
end

--GENERAR HISTORIAL DE TRN
exec @w_secuencial = sp_gen_sec
@i_operacion       = @i_operacionca 

exec @w_error   = sp_historial
@i_operacionca  = @i_operacionca,
@i_secuencial   = @w_secuencial

if @w_error <> 0 
begin
   select @w_error = 710269, 
		  @o_msg = 'ERROR SACANDO HISTORICO' 
   goto ERROR_FIN
end

--TRANSACCION CAMBIO DE ESTADO
insert into ca_transaccion(
tr_secuencial,          tr_fecha_mov,                   tr_toperacion,
tr_moneda,              tr_operacion,                   tr_tran,
tr_en_linea,            tr_banco,                       tr_dias_calc,
tr_ofi_oper,            tr_ofi_usu,                     tr_usuario,
tr_terminal,            tr_fecha_ref,                   tr_secuencial_ref,
tr_estado,              tr_observacion,                 tr_gerente,
tr_gar_admisible,       tr_reestructuracion,            tr_calificacion,
tr_fecha_cont,          tr_comprobante)  
values(
@w_secuencial,          @w_fecha_proceso,               @w_toperacion,
@w_moneda,              @i_operacionca,                 'ETM',
'N',                    @w_banco,                       0,
@w_oficina,             @w_oficina,                     @s_user,
@s_term,                @w_fecha_ult_proceso,           0,
'ING',                 	'CAMBIO ESTADO A JUDICIAL'		,@w_oficial,
'',                     @w_reestructuracion,            isnull(@w_calificacion, 'B'),
@w_fecha_proceso,       0)

if @@error <> 0 
begin
   select @w_error = 708165, 
		  @o_msg = 'ERROR AL REGISTRAR LA TRANSACCION CAMBIO DE ESTADO VENCIDO A VIGENTE ' 
   goto ERROR_FIN
end

-- REGISTRAR VALORES QUE SALEN DE LOS ESTADOS INICIALES 
--PRIMER DETALLE
insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = min(am_dividendo),
dtr_concepto     = am_concepto,
dtr_estado       = am_estado,
dtr_periodo      = 0,
dtr_codvalor     = co_codigo * 1000 + am_estado * 10,
dtr_monto        = sum(am_acumulado - am_pagado) * -1,
dtr_monto_mn     = round(((sum(am_acumulado - am_pagado) * -1)*@i_cotizacion),@i_num_dec),
dtr_moneda       = @w_moneda,
dtr_cotizacion   = @i_cotizacion,
dtr_tcotizacion  = @i_tcotizacion,
dtr_afectacion   = 'D',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from ca_amortizacion, ca_concepto
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado
and   co_concepto  = am_concepto
group by am_concepto, am_estado, (co_codigo * 1000 + am_estado * 10)
having sum(am_acumulado - am_pagado) > 0

if @@error <> 0  begin
   select @w_error = 708165, 
          @o_msg = 'ERROR AL REGISTRAR DETALLES DE TRANSACCION'
   goto ERROR_FIN
end

--SEGUNDO DETALLE
insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = min(am_dividendo),
dtr_concepto     = am_concepto,
dtr_estado       = @w_est_judicial,
dtr_periodo      = 0,
dtr_codvalor     = (co_codigo * 1000 + @w_est_judicial * 10),
dtr_monto        = sum(am_acumulado - am_pagado),
dtr_monto_mn     = round(sum(am_acumulado - am_pagado)*@i_cotizacion,@i_num_dec),
dtr_moneda       = @w_moneda,
dtr_cotizacion   = @i_cotizacion,
dtr_tcotizacion  = @i_tcotizacion,
dtr_afectacion   = 'D',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from ca_amortizacion, ca_concepto
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado
and   co_concepto  = am_concepto
group by am_concepto, (co_codigo * 1000 + @w_est_judicial * 10)
having sum(am_acumulado - am_pagado) > 0

if @@error <> 0  begin
   select @w_error = 708165, 
          @o_msg = 'ERROR AL REGISTRAR DETALLES DE TRANSACCION'
   goto ERROR_FIN
end

--- CAMBIAR DE ESTADO AL RUBRO DE LA OPERACION 
update ca_amortizacion set 
am_estado = @w_est_judicial
from ca_dividendo
where am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado

if @@error <> 0  begin
   select @w_error = 705050,
		  @o_msg = 'ERROR AL ACTUALIZAR EL ESTADO DE LOS RUBROS DE LA OPERACION '
   goto ERROR_FIN
end

--CAMBIO DE ESTADO DE LA OPERACION A VIGENTE
update ca_operacion set op_estado = @w_est_judicial
where op_operacion = @i_operacionca

if @@error <> 0 
begin
   select @w_error = 705076, 
		  @o_msg = 'ERROR AL ACTUALIZAR ESTADO DE LA OPERACION' 
   goto ERROR_FIN
end

return 0

ERROR_FIN:
   
return @w_error


GO
