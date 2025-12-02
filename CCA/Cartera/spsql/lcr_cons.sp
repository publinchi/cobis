/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           TBA                                     */
/*      archivo:                lcr_cons.sp                             */
/*      Fecha de escritura:     21/Nov/2018                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*      Consulta los datos de un préstamo                              */
/************************************************************************/  
/*                        MOFICIACIONES                                 */
/* 21/Nov/2018          TBA                  Emision inicial            */
/************************************************************************/  

use cob_cartera
go

IF OBJECT_ID ('sp_lcr_consultar') IS NOT NULL
    DROP PROCEDURE sp_lcr_consultar
GO

create proc sp_lcr_consultar
(
@s_ssn           int         = null,
@s_sesn          int         = null,
@s_date          datetime    = null,
@s_user          login       = null,
@s_term          varchar(30) = null,
@s_ofi           smallint    = null,
@s_srv           varchar(30) = null,
@s_lsrv          varchar(30) = null,
@s_rol           smallint    = null,
@s_org           varchar(15) = null,
@s_culture       varchar(15) = null,
@t_rty           char(1)     = null,
@t_debug         char(1)     = 'N',
@t_file          varchar(14) = null,
@t_trn           smallint    = null,     
@i_banco         cuenta,
@o_msg           varchar(255)= null OUT
)
as 

declare 
@w_error            int,
@w_sp_name          varchar(30),
@w_nombre_cliente   varchar(200),
@w_monto_lcr        money,
@w_monto_disponible money,
@w_pago_total       money,
@w_pago_minimo      money,
@w_fecha_pago       datetime,
@w_referencia_pago  varchar(100),
@w_fecha_ult_acceso datetime,
@w_operacionca      int,
@w_fecha_proceso    datetime,
@w_cliente          int,
@w_nombre           varchar(100),
@w_monto_utilizado  money,
@w_dividendo        int,
@w_sp_referencia    varchar(40),
@w_referencia       varchar(100),
@w_servicio         int,
@w_est_vigente      int,
@w_est_vencida      int ,
@w_num_dec          tinyint,
@w_moneda           int ,
@w_param_umbral     money , 
@w_saldo_capital    money,
@w_id_corresp       int,
@w_convenio         varchar(32),
@w_est_cancelado    int,
@w_porc_cumpl       int,
@w_fecha_ven        datetime,
@w_id_inst_proc     int,
@w_op_estado        int,
@w_tramite          int,
@w_banco            cuenta
 

select @w_sp_name = 'sp_lcr_consultar'
select
@w_sp_name = 'sp_lcr_consultar',
@w_porc_cumpl = 0

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

--estados cca
exec @w_error   = sp_estados_cca
@o_est_vigente  = @w_est_vigente out,
@o_est_vencido  = @w_est_vencida out


--PARAMETRO UMBRAL
select @w_param_umbral = pa_money
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'LCRUMB'
and    pa_producto = 'CCA'

select @w_param_umbral = isnull(@w_param_umbral,100)


select 
@w_operacionca = op_operacion,
@w_cliente     = op_cliente,
@w_moneda      = op_moneda,
@w_fecha_ven   = op_fecha_fin,
@w_op_estado   = op_estado,
@w_banco       = op_banco,
@w_tramite     = op_tramite
from cob_cartera..ca_operacion
where op_banco = @i_banco

if @@rowcount = 0 begin
   select 
   @w_error = 701002,
   @o_msg = 'OPERACION NO EXISTE'
   
   goto ERROR
end

-- CONTROL DEL NUMERO DE DECIMALES
exec @w_error = sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec out

--Estado cancelado
exec sp_estados_cca 
@o_est_cancelado = @w_est_cancelado out

--
if @w_fecha_proceso > @w_fecha_ven and @w_op_estado = @w_est_cancelado
begin
	select 	
	@w_operacionca = op_operacion,
	@w_cliente     = op_cliente,
	@w_fecha_ven   = op_fecha_fin,
	@w_op_estado   = op_estado,
	@w_banco       = op_banco,
	@w_tramite     = op_tramite
	from cob_cartera..ca_operacion
	where op_cliente = @w_cliente
	and op_toperacion = 'REVOLVENTE'
	and @w_fecha_proceso between op_fecha_ini and op_fecha_fin
end

select @w_id_inst_proc = io_id_inst_proc 
from cob_workflow..wf_inst_proceso 
where io_campo_3 = @w_tramite

--NOMBRE
select @w_nombre = isnull(p_p_apellido,'') + ' ' +isnull(p_s_apellido,'') + ' ' + en_nombre + ' ' +isnull(p_s_nombre,'')
from cobis..cl_ente
where en_ente = @w_cliente

--MONTO DE LA LINEA DE CREDITO
select @w_monto_lcr = op_monto_aprobado
from cob_cartera..ca_operacion
where op_operacion = @w_operacionca

--MONTO UTILIZADO
select @w_monto_utilizado = sum(am_cuota-am_pagado)
from cob_cartera..ca_amortizacion
where am_operacion = @w_operacionca
and   am_concepto  = 'CAP'

--MONTO DISPONIBLE
select @w_monto_disponible= @w_monto_lcr - @w_monto_utilizado

--PAGO TOTAL
select @w_pago_total = isnull(sum(am_acumulado - am_pagado),0)
from cob_cartera..ca_amortizacion
where am_operacion = @w_operacionca

if @w_pago_total < 0 select @w_pago_total = 0



--PAGO MINIMO 
select @w_pago_minimo = isnull(sum(am_cuota - am_pagado),0)
from ca_amortizacion, ca_dividendo
where am_operacion = @w_operacionca
and am_operacion   = di_operacion
and am_dividendo   = di_dividendo
and (di_estado     = @w_est_vencida or (di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proceso ))

select @w_fecha_pago  = @w_fecha_proceso


if @w_pago_minimo = 0 begin  --VALOR A PROYECTAR  EN CASO DE NO EXIGIBLES

   exec @w_error  = cob_cartera..sp_lcr_calc_corte
   @i_operacionca   = @w_operacionca,
   @i_fecha_proceso = @w_fecha_proceso,
   @o_fecha_corte   = @w_fecha_pago out
  
   if @w_error <> 0  goto ERROR
  
     --PAGO MINIMO 
   select @w_saldo_capital = sum(am_cuota - am_pagado) 
   from ca_amortizacion
   where am_operacion = @w_operacionca
   and am_concepto = 'CAP'
   
   if  @w_saldo_capital < @w_param_umbral select @w_pago_minimo  = @w_saldo_capital 
   else begin 
      
	  select @w_pago_minimo =  round(@w_saldo_capital/3, 0) 
	  
	  if @w_pago_minimo < @w_param_umbral select @w_pago_minimo = @w_param_umbral
    
   end 
  
end 


--REFERENCIA
select 
@w_id_corresp    = co_id,  
@w_sp_referencia = co_sp_generacion_ref
from cob_cartera..ca_corresponsal
where co_nombre = 'SANTANDER'

exec @w_error = @w_sp_referencia
@i_tipo_tran      = 'PI',
@i_id_referencia  = @w_operacionca,
@i_fecha_lim_pago = @w_fecha_proceso,
@o_referencia     = @w_referencia out

if @w_error <> 0 begin
   goto ERROR
end

--CONVENIO	 
select  @w_convenio = ctr_convenio
from ca_corresponsal_tipo_ref
where ctr_tipo_cobis = 'PI'
and ctr_co_id =  @w_id_corresp
--FECHA ULTIMO ACCESO
select @w_servicio = pa_tinyint
from cobis..cl_parametro 
where pa_nemonico = 'B2CSBV'
and   pa_producto = 'BVI'

select @w_fecha_ult_acceso = il_fecha_in
from cob_bvirtual..bv_in_login, cob_bvirtual..bv_login, cob_bvirtual..bv_ente
where il_login    = lo_login
and   en_ente     = lo_ente
and   lo_servicio = @w_servicio
and   en_ente_mis = @w_cliente

select 
@w_nombre,
@w_monto_lcr,
@w_monto_utilizado,
@w_monto_disponible,
@w_pago_total,
@w_pago_minimo,
@w_fecha_pago,
@w_referencia,
@w_fecha_ult_acceso,
@w_convenio,
@w_banco,
@w_id_inst_proc,
@w_porc_cumpl


select top 20
fecha = tr_fecha_real,
texto = case tr_tran when 'DES' then 'UTILIZACION' else 'PAGO REALIZADO EXITOSAMENTE' end,
monto = dtr_monto 
from cob_cartera..ca_transaccion, cob_cartera..ca_det_trn
where tr_operacion =  dtr_operacion
and tr_secuencial  =  dtr_secuencial
and tr_tran        in ('DES', 'PAG')
and tr_estado      <> 'RV'
and tr_secuencial  >  0
and dtr_afectacion =  'D'
and tr_operacion   =  @w_operacionca
ORDER BY tr_fecha_real desc

return 0

ERROR:
return @w_error

go


