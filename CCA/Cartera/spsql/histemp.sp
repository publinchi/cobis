/************************************************************************/
/*	Archivo:		histemp.sp                                          */
/*	Stored procedure:	sp_historia_tmp                                 */
/*	Base de datos:		cob_cartera                                     */
/*	Producto: 		Credito y Cartera                                   */
/*	Disenado por:  	        Zoila Bedon                                 */
/*	Fecha de escritura:	Dic. 1997                                       */
/************************************************************************/
/*				IMPORTANTE                                              */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	"MACOSA".                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier alteracion o agregado hecho por alguno de sus             */
/*	usuarios sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de MACOSA o su representante.                 */
/*				PROPOSITO                                               */
/*	Procedimiento que realiza el historial de Cartera                   */
/************************************************************************/
/*				MODIFICACIONES                                          */
/*	FECHA		AUTOR		RAZON                                       */
/*	14/May/99	XSA(CONTEXT)	Manejo de los nuevos campos de          */
/*					la tabla ca_rubro_op_tmp corres-                    */
/*					pondientes a los cambios de ru-                     */
/*					bros calculados.                                    */
/*  Abr-03-2008  M.Roa  Adicion de di_fecha_can en insert               */
/*      MAR-07-2019      Adriana Giler    CCA-S226083-Campos de Grupales*/
/************************************************************************/
use cob_cartera
go

if exists (
select 1 from sysobjects where name = 'sp_historia_tmp' and type = 'P')
   drop proc sp_historia_tmp

go

create proc sp_historia_tmp
	@i_operacionca 	 	int,
	@i_secuencial		int = null
		
as
declare @w_error                 int,
        @w_return                int,
        @w_sp_name               descripcion

/** CARGADO DE VARIABLES DE TRABAJO **/
select 
@w_sp_name   = 'sp_historia_tmp'

/* INICIAR RESPALDO DE INFORMACION */

delete  ca_operacion_tmp
where   opt_operacion = @i_operacionca

insert ca_operacion_tmp (
opt_operacion,        opt_banco,            opt_anterior,      
opt_migrada,          opt_tramite,          opt_cliente,
opt_nombre,           opt_sector,           opt_toperacion,
opt_oficina,          opt_moneda,           opt_comentario,
opt_oficial,          opt_fecha_ini,        opt_fecha_fin,
opt_fecha_ult_proceso,opt_fecha_liq,        opt_fecha_reajuste,
opt_monto,            opt_monto_aprobado,   opt_destino,
opt_lin_credito,      opt_ciudad,           opt_estado,
opt_periodo_reajuste, opt_reajuste_especial,opt_tipo,
opt_forma_pago,       opt_cuenta,           opt_dias_anio,
opt_tipo_amortizacion,opt_cuota_completa,   opt_tipo_cobro,
opt_tipo_reduccion,   opt_aceptar_anticipos,opt_precancelacion,
opt_tipo_aplicacion,  opt_tplazo,           opt_plazo,
opt_tdividendo,       opt_periodo_cap,      opt_periodo_int,
opt_dist_gracia,      opt_gracia_cap,       opt_gracia_int,
opt_dia_fijo,         opt_cuota,            opt_evitar_feriados,  
opt_num_renovacion,   opt_renovacion,       opt_mes_gracia, 
opt_reajustable,      opt_sal_pro_pon,      opt_tipo_empresa,
opt_validacion,       opt_fecha_pri_cuot,   opt_causacion,
opt_tipo_linea,       opt_subtipo_linea,   opt_bvirtual,
opt_extracto,         opt_reestructuracion, opt_tipo_cambio,
opt_valor_cat,        opt_grupo,            opt_ref_grupal, 
opt_grupal,           opt_fondeador 
)
select
oph_operacion,        oph_banco,            oph_anterior,      
oph_migrada,          oph_tramite,          oph_cliente,
oph_nombre,           oph_sector,           oph_toperacion,
oph_oficina,          oph_moneda,           oph_comentario,
oph_oficial,          oph_fecha_ini,        oph_fecha_fin,
oph_fecha_ult_proceso,oph_fecha_liq,        oph_fecha_reajuste,
oph_monto,            oph_monto_aprobado,   oph_destino,
oph_lin_credito,      oph_ciudad,           oph_estado,
oph_periodo_reajuste, oph_reajuste_especial,oph_tipo,
oph_forma_pago,       oph_cuenta,           oph_dias_anio,
oph_tipo_amortizacion,oph_cuota_completa,   oph_tipo_cobro,
oph_tipo_reduccion,   oph_aceptar_anticipos,oph_precancelacion,
oph_tipo_aplicacion,  oph_tplazo,           oph_plazo,
oph_tdividendo,       oph_periodo_cap,      oph_periodo_int,
oph_dist_gracia,      oph_gracia_cap,       oph_gracia_int,
oph_dia_fijo,         oph_cuota,            oph_evitar_feriados,
oph_num_renovacion,   oph_renovacion,       oph_mes_gracia, 
oph_reajustable,      oph_sal_pro_pon,	    oph_tipo_empresa, 
oph_validacion,       oph_fecha_pri_cuot,   oph_causacion,
oph_tipo_linea,       oph_subtipo_linea,   oph_bvirtual,
oph_extracto,         oph_reestructuracion, oph_tipo_cambio,
oph_valor_cat,        oph_grupo,            oph_ref_grupal, 
oph_grupal,           oph_fondeador

from   ca_operacion_his
where  oph_secuencial = @i_secuencial

delete  ca_rubro_op_tmp
where   rot_operacion = @i_operacionca

insert ca_rubro_op_tmp (
rot_operacion,           rot_concepto,      rot_tipo_rubro,
rot_fpago,               rot_prioridad,     rot_paga_mora,
rot_provisiona,          rot_signo,         rot_factor,       
rot_referencial,         rot_signo_reajuste,rot_factor_reajuste,
rot_referencial_reajuste,rot_valor,         rot_porcentaje,         
rot_gracia,              rot_concepto_asociado,
rot_saldo_op,		 rot_saldo_por_desem, rot_base_calculo,
rot_num_dec) 
select
roh_operacion,           roh_concepto,      roh_tipo_rubro , 
roh_fpago,               roh_prioridad,     roh_paga_mora,           
roh_provisiona,          roh_signo,         roh_factor,
roh_referencial,         roh_signo_reajuste,roh_factor_reajuste,     
roh_referencial_reajuste,roh_valor,         roh_porcentaje,
roh_gracia,        roh_concepto_asociado ,
roh_saldo_op,		 roh_saldo_por_desem, roh_base_calculo,
roh_num_dec  
from  ca_rubro_op_his
where roh_secuencial = @i_secuencial

if @@error != 0 return 710001


delete  ca_dividendo_tmp
where   dit_operacion = @i_operacionca

insert ca_dividendo_tmp (
dit_operacion,        dit_dividendo,        dit_fecha_ini,        
dit_fecha_ven,        dit_de_capital,       dit_de_interes,        
dit_gracia,           dit_gracia_disp,      dit_estado,
dit_prorroga,	      dit_dias_cuota,	    dit_intento,
dit_fecha_can	 
)
select
dih_operacion,        dih_dividendo,        dih_fecha_ini,        
dih_fecha_ven,        dih_de_capital,       dih_de_interes,     
dih_gracia,           dih_gracia_disp,      dih_estado,
dih_prorroga,	      dih_dias_cuota,	    dih_intento,
dih_fecha_can	
from   ca_dividendo_his
where  dih_secuencial = @i_secuencial

if @@error != 0 return 710001

delete  ca_amortizacion_tmp
where   amt_operacion = @i_operacionca      

insert  ca_amortizacion_tmp (
amt_operacion,         amt_dividendo,        amt_concepto,   
amt_estado,            amt_periodo,          amt_cuota,
amt_gracia,            amt_pagado ,          amt_acumulado,
amt_secuencia      
)
select
amh_operacion,         amh_dividendo,        amh_concepto,
amh_estado,            amh_periodo,          amh_cuota,
amh_gracia,            amh_pagado,           amh_acumulado,
amh_secuencia      
from   ca_amortizacion_his
where  amh_secuencial = @i_secuencial   --condicion 1    



if exists (select 1 from ca_correccion_his,ca_amortizacion_tmp -->si la operacion esta en ca_amortizacion_tmp cumplio con condicion 1 
	   where coh_operacion = @i_operacionca and coh_operacion = amt_operacion)

begin

   delete from ca_correccion_tmp where cot_operacion = @i_operacionca	

   insert into ca_correccion_tmp
  (cot_operacion,	cot_dividendo,	         cot_concepto,
   cot_correccion_mn,	cot_correccion_sus_mn,   cot_correc_pag_sus_mn,
   cot_liquida_mn)
   select
   coh_operacion,	coh_dividendo,	         coh_concepto,
   coh_correccion_mn,	coh_correccion_sus_mn,   coh_correc_pag_sus_mn,
   coh_liquida_mn
   from ca_correccion_his
   where coh_operacion = @i_operacionca

end   


if @@error != 0 
   return 710001

return 0

go
 
