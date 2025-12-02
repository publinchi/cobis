/************************************************************************/
/*   Archivo:              venopera.sp                                  */
/*   Stored procedure:     sp_cambio_estado_vencido                     */
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
/*   Realiza el Traslado de los saldos generando transaccion de CASTIGO */
/************************************************************************/
/*                               CAMBIOS                                */
/*      FECHA          AUTOR            CAMBIO                          */
/*      DIC-07-2016    Raul Altamirano  Emision Inicial - Version MX    */
/*      DIC-23-2019    Luis Ponce       No manejar rubros en Suspenso   */
/*      MAR-17-2020    Luis Ponce       CDIG am_estado=2 y am_cuota <> 0*/
/*  DIC/21/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*  ABR/17/2023   Guisela Fernandez     S807925 Ingreso de campo de     */
/*                                      reestructuracion                */
/*  OCT/27/2023   K. Rodriguez          R218297 Ajuste monto de detalle */
/*                                      transacción                     */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_vencido')
   drop proc sp_cambio_estado_vencido
go

SET ANSI_NULLS ON
GO

create proc sp_cambio_estado_vencido(
   @s_user                login,
   @s_term                varchar(30),
   @i_operacionca         int,
   @i_cotizacion          float,
   @i_tcotizacion         char(1) = 'N',
   @i_num_dec             tinyint,
   @o_msg                 varchar(100) = null out)
as 

declare
@w_secuencial           int,
@w_error                int,
@w_estado               int,
@w_est_cancelado        tinyint,
@w_est_novigente        tinyint,
@w_est_vencido          tinyint,
@w_fecha_proceso        datetime,
@w_fecha_ult_proceso    datetime,
@w_moneda               tinyint,
@w_toperacion           catalogo,
@w_banco                cuenta,
@w_oficina              int,
@w_oficial              int,
@w_reestructuracion     char(1)

-- CARGAR VARIABLES DE TRABAJO
select
@w_secuencial    = 0

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_vencido    = @w_est_vencido   out

if @@error <> 0  begin
   select @w_error = 710001, @o_msg = 'NO ENCONTRARON ESTADOS PARA CARTERA'
   goto ERROR_FIN
end


select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7


select 
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_toperacion        = op_toperacion,
@w_moneda            = op_moneda,
@w_banco             = op_banco,
@w_oficina           = op_oficina,
@w_oficial           = op_oficial,
@w_estado            = op_estado,
@w_reestructuracion  = isnull(op_reestructuracion, 'N')
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0                
   return 0
   
--- GENERAR LA TRANSACCION DE CASTIGO 
exec @w_secuencial = sp_gen_sec
@i_operacion       = @i_operacionca

exec @w_error   = sp_historial
@i_operacionca  = @i_operacionca,
@i_secuencial   = @w_secuencial

if @w_error <> 0 
begin
   select @w_error = 724510, @o_msg = 'ERROR SACANDO HISTORICO' 
   goto ERROR_FIN
end

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
'ING',                  'CAMBIO ESTADO A VENCIDO',     @w_oficial,
'',                     @w_reestructuracion,            'E',
@w_fecha_proceso,       0)

if @@error <> 0 begin
   select @w_error = 708165, @o_msg = 'ERROR AL REGISTRAR LA TRANSACCION DE CAMBIO DE ESTADO A VENCIDO' 
   goto ERROR_FIN
end


--- REGISTRAR VALORES QUE SALEN DE LOS ESTADOS INICIALES 
insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = min(am_dividendo),
dtr_concepto     = am_concepto,
dtr_estado       = case am_estado when @w_est_novigente then @w_estado else am_estado end,
dtr_periodo      = am_periodo,
dtr_codvalor     = co_codigo * 1000 + (case am_estado when @w_est_novigente then @w_estado else am_estado end) * 10 + am_periodo,
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
and   am_estado   <> @w_est_vencido  --al regresar de suspenso a vencido rubros como el capital no salieron de vencido
and   am_operacion = ro_operacion
and   am_concepto  = ro_concepto
and   ro_concepto  = co_concepto
and   ro_tipo_rubro in ('C','I','M')
and   co_concepto  = am_concepto
group by am_concepto, case am_estado when @w_est_novigente then @w_estado else am_estado end, am_periodo,
         co_codigo * 1000 + case am_estado when @w_est_novigente then @w_estado else am_estado end * 10
having sum(am_acumulado - am_pagado) > 0

if @@error <> 0  begin
   select @w_error = 708165, @o_msg = 'ERROR AL REGISTRAR DETALLES EN ESTADO ACTUAL'
   goto ERROR_FIN
end

insert into ca_det_trn
select 
dtr_secuencial   = @w_secuencial,
dtr_operacion    = @i_operacionca,
dtr_dividendo    = min(am_dividendo),
dtr_concepto     = am_concepto,
dtr_estado       = @w_est_vencido,
dtr_periodo      = am_periodo,
dtr_codvalor     = co_codigo * 1000 + @w_est_vencido * 10 + am_periodo,
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
and   am_estado   <> @w_est_vencido  --al regresar de suspenso a vencido rubros como el capital no salieron de vencido
and   am_operacion = ro_operacion
and   am_concepto  = ro_concepto
and   ro_concepto  = co_concepto
and   ro_tipo_rubro in ('C','I','M')
and   co_concepto  = am_concepto
group by am_concepto, am_periodo, co_codigo * 1000 + @w_est_vencido * 10
having sum(am_acumulado - am_pagado) > 0

if @@error <> 0  begin
   select @w_error = 708165, @o_msg = 'ERROR AL REGISTRAR DETALLES EN NUEVO ESTADO'
   goto ERROR_FIN
end

update ca_operacion set    
op_estado           = @w_est_vencido
where  op_operacion = @i_operacionca

if @@error <> 0  begin
   select @w_error = 710003, @o_msg = 'ERROR AL ACTUALIZAR DATOS DE OPERACION'
   goto ERROR_FIN
end

--CAPITAL Y DIVIDENDOS VENCIDOS
update ca_amortizacion set
am_estado = @w_est_vencido
from  ca_rubro_op
where am_operacion = @i_operacionca
and   ro_tipo_rubro in ('C','I','M')
and   ro_operacion = @i_operacionca
and   ro_concepto  = am_concepto
and   am_estado    <> @w_est_cancelado
and   am_estado    <> @w_est_vencido  --al regresar de suspenso a vencido rubros como el capital no salieron de vencido

if @@error <> 0  begin
   select @w_error = 710002, @o_msg = 'ERROR AL ACTUALIZAR CAMBIO DE ESTADO A VENCIDO'
   goto ERROR_FIN
end

return 0

ERROR_FIN:

return @w_error



GO

