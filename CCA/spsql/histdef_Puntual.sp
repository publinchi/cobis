
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_historia_def_puntual' and type = 'P')
   drop proc sp_historia_def_puntual
go

create proc sp_historia_def_puntual
   @i_operacionca  int,
   @i_secuencial   int = null
as declare
   @w_error             int,
   @w_return            int,
   @w_max_secuencial    int,
   @w_rc                int,
   @w_dividendo_desde   smallint,
   @w_rowcount_act      int

-- Campos que no se deben recuperar
declare
   @w_op_toperacion        catalogo,
   @w_op_clase             catalogo,
   @w_op_cliente           int,
   @w_op_nombre            descripcion,
   @w_op_tipo_linea        catalogo,
   @w_op_forma_pago        catalogo,
   @w_op_codigo_externo    cuenta,
   @w_op_cuenta            cuenta,
   @w_op_direccion         tinyint,
   @w_op_tipo_empresa      catalogo,
   @w_op_estado_cobranza   catalogo,
   @w_op_oficial           smallint,
   @w_op_oficina           smallint,
   @w_op_gar_admisible     char(1),
   @w_op_calificacion      catalogo

select @w_return = 0



-- VALIDAR EL HISTORIAL QUE SE VA A RESTAURAR
if exists(select 1
          from   ca_operacion_his
          where  oph_operacion = @i_operacionca
          and    oph_secuencial = @i_secuencial)
    select @w_return = @w_return + 1

if exists(select 1
          from   ca_rubro_op_his
          where  roh_operacion = @i_operacionca
          and    roh_secuencial = @i_secuencial)
    select @w_return = @w_return + 1
          
if exists(select 1
          from   ca_dividendo_his
          where  dih_operacion = @i_operacionca
          and    dih_secuencial = @i_secuencial)
    select @w_return = @w_return + 1

if exists(select 1
          from   ca_amortizacion_his
          where  amh_operacion = @i_operacionca
          and    amh_secuencial = @i_secuencial)
    select @w_return = @w_return + 1

if @w_return < 4 begin -- ALGUNA CONDICION NO SE CUMPLIO
   print 'NO SE PUDO RECUPERAR DATOS BASICOS '+ cast(@w_return as varchar) + ' OBLIGACION ' + cast(@i_operacionca as varchar) + ' SEC ' + cast(@i_secuencial as varchar)
   return 710318
end

-- INICIAR RESPALDO DE INFORMACION
delete  ca_operacion
where   op_operacion = @i_operacionca

insert ca_operacion
      (op_operacion,                op_banco,                  op_anterior,
       op_migrada,                  op_tramite,                op_cliente,
       op_nombre,                   op_sector,                 op_toperacion,
       op_oficina,                  op_moneda,                 op_comentario,
       op_oficial,                  op_fecha_ini,              op_fecha_fin,
       op_fecha_ult_proceso,        op_fecha_liq,              op_fecha_reajuste,
       op_monto,                    op_monto_aprobado,         op_destino,
       op_lin_credito,              op_ciudad,                 op_estado,
       op_periodo_reajuste,         op_reajuste_especial,      op_tipo,
       op_forma_pago,               op_cuenta,                 op_dias_anio,
       op_tipo_amortizacion,        op_cuota_completa,         op_tipo_cobro,
       op_tipo_reduccion,           op_aceptar_anticipos,      op_precancelacion,
       op_tipo_aplicacion,          op_tplazo,                 op_plazo,
       op_tdividendo,               op_periodo_cap,            op_periodo_int,
       op_dist_gracia,              op_gracia_cap,             op_gracia_int,
       op_dia_fijo,                 op_cuota,
       op_evitar_feriados,          op_num_renovacion,         op_renovacion,
       op_mes_gracia,               op_reajustable,            op_dias_clausula,
       op_numero_reest,             op_divcap_original,        op_clausula_aplicada,
       op_traslado_ingresos,        op_periodo_crecimiento,    op_tasa_crecimiento,
       op_direccion,                op_clase,                  op_origen_fondos,
       op_calificacion,             op_estado_cobranza,        op_edad,
       op_opcion_cap,               op_tasa_cap,               op_dividendo_cap,
       op_tipo_crecimiento,         op_nro_red,                op_base_calculo,
       op_fondos_propios,           op_dia_habil,              op_recalcular_plazo,
       op_usar_tequivalente,        op_sal_pro_pon,            op_tipo_empresa,
       op_validacion,               op_fecha_pri_cuot,         op_causacion,
       op_grupo_fact,               op_tramite_ficticio,       op_prd_cobis,
       op_convierte_tasa,           op_tipo_linea,             op_subtipo_linea,
       op_bvirtual,                 op_extracto,               op_reestructuracion,
       op_tipo_cambio,              op_ref_exterior,           op_sujeta_nego,
       op_tipo_redondeo,            op_gar_admisible,          op_num_deuda_ext,
       op_fecha_embarque,           op_fecha_dex,              op_naturaleza,
       op_pago_caja,                op_nace_vencida,           op_num_comex,
       op_calcula_devolucion,       op_codigo_externo,         op_margen_redescuento,
       op_entidad_convenio,         op_pproductor,             op_fecha_ult_causacion,
       op_mora_retroactiva,         op_calificacion_ant,       op_cap_susxcor,
       op_prepago_desde_lavigente,  op_fecha_ult_mov,          op_fecha_prox_segven,
       op_suspendio,                op_fecha_suspenso,         op_banca,
       op_valor_cat)
       
select oph_operacion,               oph_banco,                 oph_anterior,
       oph_migrada,                 oph_tramite,               oph_cliente,
       oph_nombre,                oph_sector,                oph_toperacion,
       oph_oficina,               oph_moneda,                oph_comentario,
       oph_oficial,               oph_fecha_ini,             oph_fecha_fin,
       oph_fecha_ult_proceso,       oph_fecha_liq,             oph_fecha_reajuste,
       oph_monto,                   oph_monto_aprobado,        oph_destino,
       oph_lin_credito,             oph_ciudad,                oph_estado,
       oph_periodo_reajuste,        oph_reajuste_especial,     oph_tipo,
       oph_forma_pago,            oph_cuenta,              oph_dias_anio,
       oph_tipo_amortizacion,       oph_cuota_completa,        oph_tipo_cobro,
       oph_tipo_reduccion,          oph_aceptar_anticipos,     oph_precancelacion,
       oph_tipo_aplicacion,         oph_tplazo,                oph_plazo,
       oph_tdividendo,              oph_periodo_cap,           oph_periodo_int,
       oph_dist_gracia,             oph_gracia_cap,            oph_gracia_int,
       oph_dia_fijo,                oph_cuota,
       oph_evitar_feriados,         oph_num_renovacion,        oph_renovacion,
       oph_mes_gracia,              oph_reajustable,           oph_dias_clausula,
       oph_numero_reest,            oph_divcap_original,       oph_clausula_aplicada,
       oph_traslado_ingresos,       oph_periodo_crecimiento,   oph_tasa_crecimiento,
       oph_direccion,             oph_clase,               oph_origen_fondos,
       oph_calificacion,          oph_estado_cobranza,     oph_edad, 
       oph_opcion_cap,              oph_tasa_cap,              oph_dividendo_cap,
       oph_tipo_crecimiento,        oph_nro_red,               oph_base_calculo,
       oph_fondos_propios,          oph_dia_habil,             oph_recalcular_plazo,
       oph_usar_tequivalente,       oph_sal_pro_pon,           @w_op_tipo_empresa,
       oph_validacion,              oph_fecha_pri_cuot,        oph_causacion,
       oph_grupo_fact,              oph_tramite_ficticio,      oph_prd_cobis,
       oph_convierte_tasa,          oph_tipo_linea,          oph_subtipo_linea,
       oph_bvirtual,                oph_extracto,              oph_reestructuracion,
       oph_tipo_cambio,             oph_ref_exterior,          oph_sujeta_nego,
       oph_tipo_redondeo,           oph_gar_admisible,       oph_num_deuda_ext,
       oph_fecha_embarque,          oph_fecha_dex,             oph_naturaleza,
       oph_pago_caja,               oph_nace_vencida,          oph_num_comex,
       oph_calcula_devolucion,      oph_codigo_externo,      oph_margen_redescuento,
       oph_entidad_convenio,        oph_pproductor,            oph_fecha_ult_causacion,
       oph_mora_retroactiva,        oph_calificacion_ant,      oph_cap_susxcor,
       oph_prepago_desde_lavigente, oph_fecha_ult_mov,         oph_fecha_prox_segven,
       oph_suspendio,               oph_fecha_suspenso,        oph_banca,
       oph_valor_cat
from   ca_operacion_his
where  oph_secuencial = @i_secuencial
and    oph_operacion  = @i_operacionca

select @w_error = @@error, @w_rc = @@rowcount

if @w_error != 0 or @w_rc = 0
begin
   return 710269
end

delete  ca_rubro_op
where   ro_operacion = @i_operacionca

insert ca_rubro_op
      (ro_operacion,             ro_concepto,               ro_tipo_rubro,
       ro_fpago,                 ro_prioridad,              ro_paga_mora,
       ro_provisiona,            ro_signo,                  ro_factor,
       ro_referencial,           ro_signo_reajuste,         ro_factor_reajuste,
       ro_referencial_reajuste,  ro_valor,                  ro_porcentaje,
       ro_gracia,                ro_concepto_asociado,      ro_porcentaje_aux,
       ro_redescuento,           ro_intermediacion,         ro_principal,
       ro_porcentaje_efa,        ro_garantia,               ro_tipo_puntos,
       ro_saldo_op,              ro_saldo_por_desem,        ro_base_calculo,
       ro_num_dec,               ro_limite,                 ro_iva_siempre,
       ro_monto_aprobado,        ro_porcentaje_cobrar,      ro_tipo_garantia,
       ro_nro_garantia,          ro_porcentaje_cobertura,   ro_valor_garantia,
       ro_tperiodo,              ro_periodo,                ro_tabla,
       ro_saldo_insoluto,        ro_calcular_devolucion)
select roh_operacion,            roh_concepto,              roh_tipo_rubro,
       roh_fpago,                roh_prioridad,             roh_paga_mora,
       roh_provisiona,           roh_signo,                 roh_factor,
       roh_referencial,          roh_signo_reajuste,        roh_factor_reajuste,
       roh_referencial_reajuste, roh_valor,                 roh_porcentaje,
       roh_gracia,               roh_concepto_asociado,     roh_porcentaje_aux,
       roh_redescuento,          roh_intermediacion,        roh_principal,
       roh_porcentaje_efa,       roh_garantia,              roh_tipo_puntos,
       roh_saldo_op,             roh_saldo_por_desem,       roh_base_calculo,
       roh_num_dec,              roh_limite,                roh_iva_siempre,
       roh_monto_aprobado,       roh_porcentaje_cobrar,     roh_tipo_garantia,
       roh_nro_garantia,         roh_porcentaje_cobertura,  roh_valor_garantia,
       roh_tperiodo,             roh_periodo,               roh_tabla,
       roh_saldo_insoluto,       roh_calcular_devolucion
from   ca_rubro_op_his
where  roh_secuencial = @i_secuencial
and    roh_operacion = @i_operacionca

select @w_error = @@error, @w_rc = @@rowcount

if @w_error != 0 or @w_rc = 0
begin
   return 710270
end

select @w_dividendo_desde = isnull(min(dih_dividendo), 0) -1
from   ca_dividendo_his
where  dih_operacion = @i_operacionca
and    dih_secuencial = @i_secuencial

delete  ca_dividendo
where   di_operacion = @i_operacionca
and     di_dividendo > @w_dividendo_desde

insert ca_dividendo
      (di_operacion,    di_dividendo,     di_fecha_ini,
       di_fecha_ven,    di_de_capital,    di_de_interes,
       di_gracia,       di_gracia_disp,   di_estado,
       di_dias_cuota,   di_intento,       di_prorroga,
       di_fecha_can)
select dih_operacion,   dih_dividendo,    dih_fecha_ini,
       dih_fecha_ven,   dih_de_capital,   dih_de_interes,
       dih_gracia,      dih_gracia_disp,  dih_estado,
       dih_dias_cuota,  dih_intento,      dih_prorroga,
       dih_fecha_can
from   ca_dividendo_his
where  dih_secuencial = @i_secuencial
and    dih_operacion = @i_operacionca

select @w_error = @@error, @w_rc = @@rowcount

if @w_error != 0 or @w_rc = 0
begin
   PRINT 'histdef.sp error insertando en ca_dividendo @i_secuencial , @w_dividendo_desde ' + cast(@i_secuencial as varchar) + cast(@w_dividendo_desde as varchar)
   return 710271
end

 
delete ca_amortizacion
where  am_operacion = @i_operacionca
and    am_dividendo > @w_dividendo_desde

insert ca_amortizacion
      (am_operacion,    am_dividendo,  am_concepto,
       am_estado,       am_periodo,    am_cuota,
       am_gracia,       am_pagado,     am_acumulado,
       am_secuencia)
select amh_operacion,   amh_dividendo, amh_concepto,
       amh_estado,      amh_periodo,   amh_cuota,
       amh_gracia,      amh_pagado,    amh_acumulado,
       amh_secuencia
from   ca_amortizacion_his
where  amh_secuencial = @i_secuencial  --condicion 1
and    amh_operacion = @i_operacionca

select @w_error = @@error, @w_rc = @@rowcount

if @w_error != 0 or @w_rc = 0
begin
   PRINT 'histdef.sp error insertando en ca_amortizacion @i_secuencial - @w_dividendo_desde ' + cast(@i_secuencial as varchar) + cast(@w_dividendo_desde as varchar)
   return 710271
end

-->SI LA OPERACION ESTA EN CA_AMORTIZACION CUMPLIO CON CONDICION 1 
if exists (select 1
           from   ca_correccion_his, ca_amortizacion
           where  coh_operacion = @i_operacionca
           and    coh_operacion = am_operacion)
begin
   delete from ca_correccion where co_operacion = @i_operacionca
   
   if @@error != 0
      return 710272
   
   insert into ca_correccion
         (co_operacion,       co_dividendo,           co_concepto,
          co_correccion_mn,   co_correccion_sus_mn,   co_correc_pag_sus_mn,
          co_liquida_mn)
   select coh_operacion,      coh_dividendo,          coh_concepto,
          coh_correccion_mn,  coh_correccion_sus_mn,  coh_correc_pag_sus_mn,
          coh_liquida_mn
   from   ca_correccion_his
   where  coh_operacion  = @i_operacionca
   and    coh_secuencial = @i_secuencial
   
   select @w_error = @@error, 
          @w_rc = @@rowcount
   
   if @w_error != 0 or @w_rc = 0
      print 'Operacion no tienen Registro de Correccion Monetaria'
       ---- return 710272
end


delete ca_cuota_adicional
where  ca_operacion = @i_operacionca

if @@error != 0
   return 710003

insert ca_cuota_adicional
      (ca_operacion,      ca_dividendo,    ca_cuota )
select cah_operacion,     cah_dividendo,   cah_cuota
from   ca_cuota_adicional_his
where  cah_secuencial = @i_secuencial
and    cah_operacion  = @i_operacionca

if @@error != 0
   return 710273

--RBU
delete ca_valores
where  va_operacion = @i_operacionca

if @@error != 0
   return 710003

insert ca_valores
      (va_operacion,      va_dividendo,    va_rubro,   va_valor)
select vah_operacion,     vah_dividendo,   vah_rubro,  vah_valor 
from   ca_valores_his
where  vah_secuencial = @i_secuencial
and    vah_operacion  = @i_operacionca

if @@error != 0
   return 710275


delete ca_amortizacion_ant
where  an_operacion      = @i_operacionca  -- MPO Ref. 026 02/21/2002

insert ca_amortizacion_ant
      (an_secuencial,         an_operacion,           an_dividendo,
       an_estado,             an_dias_pagados,        an_valor_pagado,
       an_dias_amortizados,   an_valor_amortizado,    an_fecha_pago,
       an_tasa_dia,           an_secuencia)
select anh_secuencial,        anh_operacion,          anh_dividendo,
       anh_estado,            anh_dias_pagados,       anh_valor_pagado,
       anh_dias_amortizados,  anh_valor_amortizado,   anh_fecha_pago,
       anh_tasa_dia,          anh_secuencia
from   ca_amortizacion_ant_his
where  anh_secuencial_his = @i_secuencial    -- MPO Ref. 026 02/21/2002
and    anh_operacion      = @i_operacionca

if @@error != 0
   return 710260

delete ca_diferidos
where  dif_operacion = @i_operacionca

if @@error != 0
   return 710003

insert ca_diferidos
      (dif_operacion, dif_valor_total,            dif_valor_pagado)
select difh_operacion, difh_valor_diferido ,      difh_valor_pagado
from   ca_diferidos_his
where  difh_secuencial  = @i_secuencial
and    difh_operacion  = @i_operacionca

if @@error != 0
   return 710579 

   
delete ca_facturas
where  fac_operacion  = @i_operacionca

insert ca_facturas
  (fac_operacion,        fac_nro_factura,  fac_nro_dividendo, fac_fecha_vencimiento,
   fac_valor_negociado,  fac_pagado,       fac_intant,        fac_intant_amo,
   fac_estado_factura,   fac_dias_factura )
select
   fach_operacion,       fach_nro_factura,    fach_nro_dividendo, fach_fecha_vencimiento,
   fach_valor_negociado, fach_pagado,         fach_intant,        fach_intant_amo,
   fach_estado_factura,  fach_dias_factura
from ca_facturas_his
where  fach_operacion  = @i_operacionca
and    fach_secuencial = @i_secuencial

if @@error != 0
   return 708153

-- INICIO REQ 379 IFJ 22/Nov/2005
delete ca_traslado_interes 
where ti_operacion = @i_operacionca

insert ca_traslado_interes
      (ti_operacion,     ti_cuota_orig,  ti_cuota_dest,  ti_usuario,
       ti_fecha_ingreso, ti_terminal,    ti_estado,      ti_monto)
select tih_operacion,     tih_cuota_orig, tih_cuota_dest, tih_usuario,
       tih_fecha_ingreso, tih_terminal,   tih_estado,     tih_monto 
from  ca_traslado_interes_his
where tih_operacion  = @i_operacionca
and   tih_secuencial = @i_secuencial

if @@error != 0
   return 711005


if exists (select 1
           from   ca_transaccion
           where  tr_operacion   = @i_operacionca
           and    tr_secuencial  = @i_secuencial
           and    tr_tran        = 'MIG'
           )
   select @i_secuencial = @i_secuencial + 1

select @w_max_secuencial = max(oph_secuencial)
from   ca_operacion_his
where  oph_operacion = @i_operacionca
and    oph_secuencial >= @i_secuencial

insert ca_reg_eliminado_his
values(@i_secuencial, @w_max_secuencial, @i_operacionca)


if @@error != 0
   return 710003

return 0

go
