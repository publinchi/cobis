/************************************************************************/
/*   Archivo:              historia.sp                                  */
/*   Stored procedure:     sp_historial                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Guarda historicos para reversas                                    */
/*                               MODIFICACIONES                         */
/*   FECHA        AUTOR          RAZON                                  */
/*   13/MAY/2005  Fabian Quintero No respaldar las cuotas canceladas    */
/*   09/AGO/2005  Elcira Pelaez   No recuperar historia de la tabla de  */
/*                                capitalizaziones ca_acciones          */
/*      10/OCT/2005    FDO CARVAJAL    DIFERIDOS REQ 389                */
/*   10/NOV/2005  Elcira Pelaez   Respaldar tabla Documenos descontados */
/*   22/Nov/2005  Ivan Jimenez    REQ 379 Traslado de Intereses         */
/*   SEP 2006     FQ              Optimizacion 152                      */
/*   May 2007     Fabian Quintero Defecto 8236                          */
/*   Oct 2007     Elcira Pelaez   Defecto 8895 ca_ultima_tasa_op_his    */
/*                                quitar                                */
/*   05/12/2016   R. Sánchez      Modif. Apropiación                    */
/*   06/Dic/2016  I. Yupa         AJUSTES CONTABLES MEXICO              */
/*   18/Mar/2020  Luis Ponce      CDIG Ajustes migracion a Java         */
/*   05/Nov/2020  EMP-JJEC        Rubros Financiados                    */
/*   19/Nov/2020  EMP-JJEC        Control Tasa INT Maxima/Minima        */
/* 06/Ene/2021   P.Narvaez  Tipo de Reestructuracion/Tipo Renovacion    */
/*   18/Ago/2021  K. Rodriguez    Historico ca_control_rubros_diferidos */
/*   13/Jul/2022  G. Fernandez Se cambia manejo de errores por try-catch*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_historial')
   drop proc sp_historial
go

create proc sp_historial
   @i_operacionca     int,
   @i_secuencial   int = null
as
declare 
   @w_tipo_op           char(1),
   @w_dividendo_desde   smallint,
   @w_moneda            tinyint

select @w_tipo_op = isnull(op_tipo,'N'),
       @w_moneda  = op_moneda
from   ca_operacion (nolock)
where  op_operacion = @i_operacionca


-- INICIAR RESPALDO DE INFORMACION
if @w_moneda = 2    ---SOLO PARA MONEDA UVR
begin
   insert ca_correccion_his with (rowlock)
   select @i_secuencial, C.* --LPO CDIG Ajustes por migracion a Java, se coloca alias C
   from   ca_correccion C (nolock)
   where  co_operacion = @i_operacionca
end

begin try
insert ca_operacion_his with (rowlock)
select @i_secuencial,op_operacion,op_banco,op_anterior,op_migrada,op_tramite,op_cliente,op_nombre
,op_sector,op_toperacion,op_oficina
,op_moneda,op_comentario,op_oficial,op_fecha_ini,op_fecha_fin,op_fecha_ult_proceso,op_fecha_liq,op_fecha_reajuste
,op_monto,op_monto_aprobado,op_destino,op_lin_credito,op_ciudad,op_estado,op_periodo_reajuste,op_reajuste_especial
,op_tipo,op_forma_pago,op_cuenta,op_dias_anio,op_tipo_amortizacion,op_cuota_completa,op_tipo_cobro,op_tipo_reduccion
,op_aceptar_anticipos,op_precancelacion,op_tipo_aplicacion,op_tplazo,op_plazo,op_tdividendo,op_periodo_cap,op_periodo_int
,op_dist_gracia,op_gracia_cap,op_gracia_int,op_dia_fijo,op_cuota,op_evitar_feriados,op_num_renovacion,op_renovacion
,op_mes_gracia,op_reajustable,op_dias_clausula,op_divcap_original,op_clausula_aplicada,op_traslado_ingresos
,op_periodo_crecimiento
,op_tasa_crecimiento,op_direccion,op_opcion_cap,op_tasa_cap,op_dividendo_cap,op_clase,op_origen_fondos
,op_calificacion,op_estado_cobranza
,op_numero_reest,op_edad,op_tipo_crecimiento,op_base_calculo,op_prd_cobis,op_ref_exterior,op_sujeta_nego,op_dia_habil
,op_recalcular_plazo,op_usar_tequivalente,op_fondos_propios,op_nro_red,op_tipo_redondeo,op_sal_pro_pon,op_tipo_empresa
,op_validacion,op_fecha_pri_cuot,op_gar_admisible,op_causacion,op_convierte_tasa,op_grupo_fact,op_tramite_ficticio
,op_tipo_linea,op_subtipo_linea,op_bvirtual,op_extracto,op_num_deuda_ext,op_fecha_embarque,op_fecha_dex
,op_reestructuracion,op_tipo_cambio,op_naturaleza,op_pago_caja,op_nace_vencida,op_num_comex,op_calcula_devolucion
,op_codigo_externo,op_margen_redescuento,op_entidad_convenio,op_pproductor,op_fecha_ult_causacion,op_mora_retroactiva
,op_calificacion_ant,op_cap_susxcor,op_prepago_desde_lavigente,op_fecha_ult_mov,op_fecha_prox_segven,op_suspendio
,op_fecha_suspenso,op_honorarios_cobranza,op_banca,op_promocion,op_acepta_ren,op_no_acepta,op_emprendimiento,op_valor_cat
,op_grupo, op_ref_grupal, op_grupal, op_fondeador, op_admin_individual, op_estado_hijas, op_tipo_renovacion, op_tipo_reest
,op_fecha_reest, op_fecha_reest_noestandar 
from   ca_operacion (nolock)
where  op_operacion = @i_operacionca

end try
begin catch
   return 710261
end catch

begin try
insert ca_rubro_op_his with (rowlock)
select @i_secuencial,ro_operacion,ro_concepto,ro_tipo_rubro,ro_fpago,ro_prioridad,ro_paga_mora
,ro_provisiona,ro_signo,ro_factor,ro_referencial,ro_signo_reajuste,ro_factor_reajuste
,ro_referencial_reajuste,ro_valor,ro_porcentaje,ro_porcentaje_aux,ro_gracia
,ro_concepto_asociado,ro_redescuento,ro_intermediacion,ro_principal,ro_porcentaje_efa
,ro_garantia,ro_tipo_puntos,ro_saldo_op,ro_saldo_por_desem,ro_base_calculo
,ro_num_dec,ro_limite,ro_iva_siempre,ro_monto_aprobado,ro_porcentaje_cobrar
,ro_tipo_garantia,ro_nro_garantia,ro_porcentaje_cobertura,ro_valor_garantia
,ro_tperiodo,ro_periodo,ro_tabla,ro_saldo_insoluto,ro_calcular_devolucion,ro_financiado
,ro_tasa_maxima, ro_tasa_minima
from   ca_rubro_op (nolock)
where  ro_operacion  = @i_operacionca

end try
begin catch
   return 710272
end catch

-- BUSCAR EL DIVIDENDO DESDE EL CUAL SE VA A RESPALDAR
select @w_dividendo_desde = 0

if exists(select 1
          from   ca_operacion (nolock)
          where  op_operacion = @i_operacionca
          and    op_tipo     = 'O')
   select @w_dividendo_desde = 0
ELSE
begin
   select @w_dividendo_desde = isnull(min(di_dividendo), 0) - 1
   from   ca_dividendo (nolock)
   where  di_operacion = @i_operacionca
   and    di_estado in (2, 1)
end

begin try
insert ca_dividendo_his with (rowlock)
select @i_secuencial, D.* --LPO CDIG Ajustes por migracion a Java, se coloca alias D
from   ca_dividendo D (nolock)
where  di_operacion   = @i_operacionca
and    di_dividendo > @w_dividendo_desde

end try
begin catch
   return 710263
end catch

begin try
insert ca_amortizacion_his with (rowlock)
select @i_secuencial
	,am_operacion,am_dividendo,am_concepto,am_estado,am_periodo,am_cuota
	,am_gracia,am_pagado,am_acumulado,am_secuencia
from   ca_amortizacion (nolock)
where  am_operacion  = @i_operacionca
and    am_dividendo > @w_dividendo_desde
       
end try
begin catch
   return 710264
end catch

begin try
insert ca_cuota_adicional_his with (rowlock)
select @i_secuencial, CA.* --LPO CDIG Ajustes por migracion a Java, se coloca alias CA
from   ca_cuota_adicional CA (nolock)
where  ca_operacion  = @i_operacionca

end try
begin catch
   return 710265
end catch

begin try
insert ca_valores_his with (rowlock)
select @i_secuencial, VA.* --LPO CDIG Ajustes por migracion a Java, se coloca alias VA
from   ca_valores VA (nolock)
where  va_operacion  = @i_operacionca

end try
begin catch
   return 710267
end catch

begin try
insert ca_amortizacion_ant_his with (rowlock)
select AM.*,@i_secuencial         --LPO CDIG Ajustes por migracion a Java, se coloca alias MA -- MPO Ref. 026 02/21/2002
from   ca_amortizacion_ant AM (nolock)
where  an_operacion  = @i_operacionca

end try
begin catch
   return 710259
end catch

begin try
-- INICIO FCP 10/OCT/2005 - REQ 389
insert ca_diferidos_his with (rowlock)
select @i_secuencial, DI.* --LPO CDIG Ajustes por migracion a Java, se coloca alias DI
from   ca_diferidos DI (nolock)
where  dif_operacion  = @i_operacionca

end try
begin catch
   return 710580
end catch

-- FIN FCP 10/OCT/2005 - REQ 389

begin try
insert ca_facturas_his with (rowlock)
select @i_secuencial, FA.* --LPO CDIG Ajustes por migracion a Java, se coloca alias FA
from   ca_facturas FA (nolock)
where  fac_operacion  = @i_operacionca

end try
begin catch
   return 708154   
end catch

-- INICIO REQ 379 IFJ 22/Nov/2005
begin try
insert ca_traslado_interes_his with (rowlock)
select @i_secuencial,I.*  --LPO CDIG Ajustes por migracion a Java, se coloca alias I
from   ca_traslado_interes I (nolock)
where  ti_operacion  = @i_operacionca

end try
begin catch
   return 711006
end catch
   
-- FIN REQ 379 IFJ 22/Nov/2005   
   
--Inicio de apropiación
-- ca_comision_diferida
begin try
insert ca_comision_diferida_his with (rowlock)
select @i_secuencial, CO.* --LPO CDIG Ajustes por migracion a Java, se coloca alias CO
from   ca_comision_diferida CO (nolock)
where  cd_operacion  = @i_operacionca

end try
begin catch   
   return 724588 
end catch
--Fin de apropiación   
   
-- Seguros asociados a una obligación
   
begin try
insert ca_seguros_his with (rowlock)
select @i_secuencial, SE.* --LPO CDIG Ajustes por migracion a Java, se coloca alias SE
from   ca_seguros SE (nolock)
where  se_operacion  = @i_operacionca

end try
begin catch 
   return 708231
end catch
  
-- ca_seguros_det
begin try
insert ca_seguros_det_his with (rowlock)
select @i_secuencial, SD.* --LPO CDIG Ajustes por migracion a Java, se coloca alias SD
from   ca_seguros_det SD (nolock)
where  sed_operacion  = @i_operacionca

end try
begin catch 
   return 708232      
end catch

-- ca_seguros_can
begin try
insert ca_seguros_can_his with (rowlock)
select @i_secuencial, SC.* --LPO CDIG Ajustes por migracion a Java, se coloca alias SC
from   ca_seguros_can SC (nolock)
where  sec_operacion  = @i_operacionca

end try
begin catch 
   --print 'historia.sp: NO FUE POSIBLE GUARDAR HISTORICOS DE SEGUROS CANCELADOS'   
   return 708232      
end catch

--HISTORICOS DIAS DE MORA
begin try
insert ca_operacion_ext_his with (rowlock)
select @i_secuencial, OE.* --LPO CDIG Ajustes por migracion a Java, se coloca alias OE
from   ca_operacion_ext OE (nolock)
where  oe_operacion  = @i_operacionca
end try
begin catch
   --print 'historia.sp: NO FUE POSIBLE GUARDAR HISTORICOS DE DIAS MORA'   
   return 724596
end catch

-- KDR 18/08/2021 - Históricos Rubros diferidos
begin try
insert ca_control_rubros_diferidos_his with (rowlock)
select @i_secuencial, CRD.*
from  ca_control_rubros_diferidos CRD (nolock)
where crd_operacion = @i_operacionca
--and   crd_dividendo > @w_dividendo_desde				

end try
begin catch
   return 711103
end catch

return 0
go
