/************************************************************************/
/*  archivo:                abonogar.sp                                 */
/*  stored procedure:       sp_abono_garantia                           */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: 28/ago/2018                                 */
/************************************************************************/
/*          importante                                                  */
/*  este programa es parte de los paquetes bancarios propiedad de       */
/*  "macosa",representantes exclusivos para el ecuador de la            */
/*  at&t                                                                */
/*  su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  presidencia ejecutiva de macosa o su representante                  */
/************************************************************************/
/*          proposito                                                   */
/*               Aplicacion de Pagos con Garantia                       */
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_abono_garantia')
	drop proc sp_abono_garantia
go

create proc sp_abono_garantia(
@i_operacionca    int,
@i_en_linea       char(1) = 'N'
)		
as
declare
@w_sp_name       	varchar(32),
@w_tramite_grupal   int,
@w_return        	int,
@w_error            int,
@w_msg              varchar(255),
@w_op_fecha_ult_proceso    datetime, 
@w_fecha_proceso    datetime, 
@w_op_fecha_fin     datetime,
@w_monto_garantia   money,
@w_secuencial_ing   int,
@w_fpago            descripcion,
@w_fecha_control    datetime,
@s_ssn              int,
@s_ofi              int, 
@s_user             descripcion,
@s_srv              descripcion,
@s_term             descripcion,
@s_rol              int,
@s_lsrv             descripcion,
@w_ciudad_nacional  int,
@w_beneficiario     varchar(255),
@w_banco            varchar(255),
@w_moneda           int,
@w_commit           char(1),
@w_cuotas_vencidas  int,
@w_cuota_aplicacion int,
@w_operacion_gr     varchar(255),
@w_op_cliente       int,
@w_op_cuenta        varchar(255),
@w_cod_externo      varchar(255),
@w_op_tramite       int,
@w_grupo            int,
@w_aplica_gar_liquida  char(1),
@w_monto_precancelar   money,
@w_monto_pago          money 



--INICIALIZACION DE VARIABLES
exec @s_ssn  = ADMIN...rp_ssn

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

select 
@s_user             ='usrbatch',
@s_srv              ='CTSSRV',
@s_term             ='batch-apl-gar',
@s_rol              =3,
@s_lsrv             ='CTSSRV',
@w_fpago            ='GAR_DEB'

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select @w_error = 101024
   goto ERROR
end

--DATOS DEL PRESTAMO 
select
@w_op_fecha_ult_proceso = op_fecha_ult_proceso,
@w_op_fecha_fin  = op_fecha_fin,
@w_beneficiario  = op_nombre,
@w_banco         = op_banco,
@w_moneda        = op_moneda,
@s_ofi           = op_oficina,
@w_op_cliente    = op_cliente,
@w_op_cuenta     = op_cuenta,
@w_op_tramite    = op_tramite 
from   ca_operacion 
where  op_operacion = @i_operacionca 

if @@rowcount = 0 return 0



--DATOS DE LA OPERACION AGRUPADORA 
select 
@w_operacion_gr= dc_referencia_grupal,
@w_grupo       = dc_grupo 
from   ca_det_ciclo
where  dc_operacion = @i_operacionca

select @w_tramite_grupal  = op_tramite 
from   ca_operacion  
where  op_banco =  @w_operacion_gr

select @w_monto_garantia = isnull(gl_pag_valor,0) -isnull(gl_dev_valor,0) 
from  ca_garantia_liquida
where gl_cliente  = @w_op_cliente
and   gl_tramite  = @w_tramite_grupal

if @@rowcount = 0          return 0
if @w_monto_garantia <= 0  return 0

select @w_monto_precancelar = isnull(sum(am_acumulado-am_pagado),0)    
from ca_amortizacion 
where am_operacion = @i_operacionca
if @w_monto_precancelar <= 0  return 0

--select @w_monto_pago   = case when @w_monto_garantia > @w_monto_precancelar then @w_monto_precancelar else @w_monto_garantia end 
if @w_monto_garantia > @w_monto_precancelar
   select @w_monto_pago = @w_monto_precancelar
else
   select @w_monto_pago = @w_monto_garantia
   
                                      
select @w_aplica_gar_liquida = gr_gar_liquida 
from cobis..cl_grupo
where gr_grupo = @w_grupo
if @@rowcount  = 0  select @w_aplica_gar_liquida = 'S'

if @w_aplica_gar_liquida = 'N' return 0
--DATOS DE LA GARANTIA DEL PRESTAMO 
select @w_cod_externo= gp_garantia
from   cob_credito..cr_gar_propuesta
where  gp_tramite = @w_op_tramite
if @@rowcount = 0          return 0

if exists (select 1 from cobis..cl_dias_feriados where df_fecha = @w_op_fecha_ult_proceso and df_ciudad = @w_ciudad_nacional)
and datepart(dd,@w_op_fecha_ult_proceso) <> 1 
   return 0
			
--MANEJO DE LOS DIAS HABILES
select @w_fecha_control = dateadd(dd,1,@w_op_fecha_ult_proceso)
while exists (select 1 from cobis..cl_dias_feriados where df_fecha = @w_fecha_control and df_ciudad = @w_ciudad_nacional)
and datepart(dd,@w_fecha_control) <> 1 
   select @w_fecha_control = dateadd(dd, 1,@w_fecha_control)

--EJECUCION DE LA REGLA DE NEGOCIO
exec @w_error       = sp_ejecutar_regla
@s_ssn              = @s_ssn,
@s_ofi              = @s_ofi,
@s_user             = @s_user,
@s_date             = @w_fecha_proceso,
@s_srv              = @s_srv,
@s_term             = @s_term,
@s_rol              = @s_rol,
@s_lsrv             = @s_lsrv,
@s_sesn             = 1,
@i_operacionca      = @i_operacionca,
@i_regla            ='APLGAR',                --nemonico de la regla
@o_resultado1       =  @w_cuota_aplicacion out, --cuotas aplicacion    15
@o_resultado2       =  @w_cuotas_vencidas out  --cuota  vencidas       2

if @w_error <> 0 return @w_error 

if @w_cuota_aplicacion is null 
begin
   select 
   @w_error = 710002,
   @w_msg = 'ERROR: NO SE PUDO DETERMINAR LOS VALORES PARA LA REGLA APLGAR'
   goto ERROR
end  

--VERIFICAR SI HOY ES VENCIMIENTO 
if @w_op_fecha_fin > @w_fecha_control 
and not exists (select 1 
				from   ca_dividendo 
				where di_operacion =   @i_operacionca
				and   di_dividendo =   @w_cuota_aplicacion
                and   di_fecha_ini <=  @w_fecha_control     ---- se requiere el pago se aplique la noche anterior al inicio de la cuota
                 ) 
return 0

if @@trancount = 0
begin
   select @w_commit = 'S'
   begin tran
end	  

exec @w_error = sp_pago_cartera
@s_user           = @s_user,
@s_term           = @s_term,
@s_date           = @w_fecha_proceso,
@s_sesn           = 1,
@s_ofi            = @s_ofi ,
@s_ssn            = @s_ssn,
@s_srv            = @s_srv,
@i_banco          = @w_banco,
@i_beneficiario   = @w_beneficiario,
@i_fecha_vig      = @w_op_fecha_ult_proceso, 
@i_ejecutar       = 'S',
@i_en_linea       = @i_en_linea,
@i_tipo_cobro     = 'A', --acumulado
@i_tipo_reduccion = 'T', --reduccion de tiempo 
@i_producto       = @w_fpago, 
@i_monto_mpg      = @w_monto_pago,
@i_moneda         = @w_moneda,
@i_cuenta         = @w_cod_externo,
@o_secuencial_ing = @w_secuencial_ing out

if @w_error <> 0 
begin
   select 
   @w_msg = 'ERROR EN APLICACION DE PAGO (sp_pago_cartera)'
   goto ERROR
end   

if @w_commit = 'S'
begin
   select @w_commit = 'N'
   commit tran
end

return 0

ERROR:
if @w_commit = 'S'
begin
   select @w_commit = 'N'
   rollback tran
end

return @w_error 
go

