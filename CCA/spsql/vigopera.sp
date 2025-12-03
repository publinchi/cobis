use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_vigente')
   drop proc sp_cambio_estado_vigente
go

/************************************************************************/
/*   Nombre Fisico:        vigopera.sp                                  */
/*   Nombre Logico:        sp_cambio_estado_vigente                     */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Dic-08-2016                                  */
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
/*   Realiza el Traslado de los saldos a Vigentes generando transaccion */
/*   respectiva                                                         */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*  DIC-07-2016  Raul Altamirano  Emision Inicial - Version MX         	*/
/*  DIC/21/2020  P. Narvaez Añadir cambio de estado Judicial y Suspenso	*/
/*  AGO/18/2022  K. Rodríguez     R191954 Det_trn solo para rubros C,I,M*/
/*  SEP/07/2022  K. Rodriguez   R193404 Ajuste det_trn por am_secuencia */
/*  ABR/17/2023  G. Fernandez     S807925 Ingreso de campo de           */
/*                                reestructuracion                      */
/*    JUN/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*  OCT/27/2023  K. Rodriguez   R218297 Ajuste monto de detalle transac.*/
/************************************************************************/  
SET ANSI_NULLS ON
GO

create proc sp_cambio_estado_vigente(
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
@w_secuencial        int,
@w_error             int,   
@w_pago_sostenido    char(1),   
@w_estado            int,
@w_est_cancelado     tinyint,
@w_est_novigente     tinyint,   
@w_est_vigente       tinyint,
@w_fecha_proceso     datetime,
@w_fecha_ult_proceso datetime,
@w_calificacion      catalogo,
@w_moneda            tinyint,   
@w_toperacion        catalogo,
@w_banco             cuenta,
@w_oficina           int,
@w_oficial           int,
@w_reestructuracion  char(1)

select 
@w_sp_name 	   = 'sp_cambio_estado_vigente',
@w_secuencial  = 0

-- VERIFICAR SI TIENE PAGO SOSTENIDO
--GFP Este proceso de pago sostenido no aplica a FINCA
/* 
exec @w_error  = sp_verifica_pago_sostenido_op 
@i_operacion   = @i_operacionca,
@o_psostenido  = @w_pago_sostenido out

if @w_error <> 0 goto ERROR_FIN

if @@error <> 0
begin
   select @w_error  = 722109,  -- Cliente NO ha realizado el pago requerido
		  @o_msg    = 'ERROR AL OBTENER INDICADOR DE PAGO SOSTENIDO' 
   goto ERROR_FIN
end

if @w_pago_sostenido = 'N'
begin
   select @w_error  = 722109  -- Cliente NO ha realizado el pago requerido
   goto ERROR_FIN
end
*/
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
@o_est_vigente    = @w_est_vigente   out

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

if @w_error <> 0 goto ERROR_FIN

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
@w_moneda,              @i_operacionca,                 'EST',
'N',                    @w_banco,                       0,
@w_oficina,             @w_oficina,                     @s_user,
@s_term,                @w_fecha_ult_proceso,           0,
'ING',                 	'CAMBIO ESTADO A VIGENTE'		,@w_oficial,
'',                     @w_reestructuracion,            isnull(@w_calificacion, 'B'),
@w_fecha_proceso,       0)

if @@error <> 0 
begin
   select @w_error = 708165, 
		  @o_msg = 'ERROR AL REGISTRAR LA TRANSACCION CAMBIO DE ESTADO VENCIDO A VIGENTE ' 
   goto ERROR_FIN
end

-- REGISTRAR VALORES QUE SALEN DE LOS ESTADOS INICIALES AGRUPADO POR CONCEPTO Y CODIGO VALOR
--PRIMER DETALLE
insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = min(am_dividendo),
dtr_concepto     = am_concepto,
dtr_estado       = am_estado,
dtr_periodo      = am_periodo,
dtr_codvalor     = co_codigo * 1000 + am_estado * 10 + am_periodo,
dtr_monto        = sum(am_acumulado + am_gracia - am_pagado) * -1,
dtr_monto_mn     = round(((sum(am_acumulado + am_gracia - am_pagado) * -1)*@i_cotizacion),@i_num_dec),
dtr_moneda       = @w_moneda,
dtr_cotizacion   = @i_cotizacion,
dtr_tcotizacion  = @i_tcotizacion,
dtr_afectacion   = 'D',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from ca_amortizacion, ca_rubro_op, ca_concepto
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado
and   ro_operacion = am_operacion
and   ro_concepto  = am_concepto
and   co_concepto  = am_concepto
and   ro_concepto  = co_concepto
and   ro_tipo_rubro in ('C','I','M')        -- KDR 18/08/2021 Solo rubros que contabilizan
group by am_concepto, am_estado, am_periodo, (co_codigo * 1000 + am_estado * 10)
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
dtr_estado       = @w_est_vigente,
dtr_periodo      = am_periodo,
dtr_codvalor     = (co_codigo * 1000 + @w_est_vigente * 10) + am_periodo,
dtr_monto        = sum(am_acumulado + am_gracia - am_pagado),
dtr_monto_mn     = round(sum(am_acumulado + am_gracia - am_pagado)*@i_cotizacion,@i_num_dec),
dtr_moneda       = @w_moneda,
dtr_cotizacion   = @i_cotizacion,
dtr_tcotizacion  = @i_tcotizacion,
dtr_afectacion   = 'D',
dtr_cuenta       = '',
dtr_beneficiario = '',
dtr_monto_cont   = 0
from ca_amortizacion, ca_rubro_op, ca_concepto
where am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado
and   ro_operacion = am_operacion
and   ro_concepto  = am_concepto
and   co_concepto  = am_concepto
and   ro_concepto  = co_concepto
and   ro_tipo_rubro in ('C','I','M')         -- KDR 18/08/2021 Solo rubros que contabilizan
group by am_concepto, am_estado, am_periodo, (co_codigo * 1000 + @w_est_vigente * 10)
having sum(am_acumulado - am_pagado) > 0

if @@error <> 0  begin
   select @w_error = 708165, 
          @o_msg = 'ERROR AL REGISTRAR DETALLES DE TRANSACCION'
   goto ERROR_FIN
end

--- CAMBIAR DE ESTADO AL RUBRO DE LA OPERACION 
update ca_amortizacion set 
am_estado = case 
              when di_estado = @w_est_novigente then @w_est_novigente
              else @w_est_vigente
            end
from ca_dividendo, ca_rubro_op
where am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   am_operacion = @i_operacionca
and   am_estado   <> @w_est_cancelado
and   ro_operacion = am_operacion
and   ro_concepto  = am_concepto
and   ro_tipo_rubro in ('C','I','M')


if @@error <> 0  begin
   select @w_error = 705050,
		  @o_msg = 'ERROR AL ACTUALIZAR EL ESTADO DE LOS RUBROS DE LA OPERACION '
   goto ERROR_FIN
end

/* -- KDR 30/08/2021 Se comenta unificación de rubros para que muestre las saldos según respectivos períodos
--- UNIFICAR RUBROS INNECESARIAMENTE SEPARADOS 
select 
operacion = am_operacion,
dividendo = am_dividendo,
concepto  = am_concepto,
secuencia = min(am_secuencia),
cuota     = isnull(sum(am_cuota),     0.00),
gracia    = isnull(sum(am_gracia),    0.00),
acumulado = isnull(sum(am_acumulado), 0.00),
pagado    = isnull(sum(am_pagado),    0.00)
into #para_juntar
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_estado   <> @w_est_cancelado
group by am_operacion, am_dividendo, am_concepto, am_estado

if @@error <> 0  begin
   select @w_error = 710001, 
		  @o_msg = 'ERROR AL GENERAR TABLA DE TRABAJO para_juntar '
   goto ERROR_FIN
end
   
update ca_amortizacion set
am_cuota     = cuota,
am_gracia    = gracia,
am_acumulado = acumulado,
am_pagado    = pagado
from   #para_juntar
where  am_operacion = operacion
and    am_dividendo = dividendo
and    am_concepto  = concepto
and    am_secuencia = secuencia

if @@error <> 0  
begin
   select @w_error = 705050, 
          @o_msg   = 'ERROR AL ACTUALIZAR LOS SALDOS DE LOS RUBROS UNIFICADOS' 
   goto ERROR_FIN
end
   
delete ca_amortizacion
from   #para_juntar
where  am_operacion  = operacion
and    am_dividendo  = dividendo
and    am_concepto   = concepto
and    am_secuencia  > secuencia
and    am_estado    <> @w_est_cancelado

if @@error <> 0  begin
   select @w_error = 710003, 
		  @o_msg = 'ERROR AL ELIMINAR REGISTROS UNIFICADOS' 
   goto ERROR_FIN
end
*/ -- FIN KDR KDR 30/08/2021

--CAMBIO DE ESTADO DE LA OPERACION A VIGENTE
update ca_operacion set op_estado = @w_est_vigente
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
