/**************************************************************************/
/*   Nombre Fisico:        histdef.sp                                     */
/*   Nombre Logico:        sp_historia_def_117668                         */
/*   Base de datos:        cob_cartera                                    */
/*   Producto:             Credito y Cartera                              */
/*   Disenado por:         Zoila Bedon                                    */
/*   Fecha de escritura:   Dic. 1997                                      */
/***********************************************************************  */
/*                               IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios que son       	  */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  	  */
/*   representantes exclusivos para comercializar los productos y   	  */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida 	  */
/*   y regida por las Leyes de la República de España y las         	  */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  	  */
/*   alteración en cualquier sentido, ingeniería reversa,           	  */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    	  */
/*   de los usuarios o personas que hayan accedido al presente      	  */
/*   sitio, queda expresamente prohibido; sin el debido             	  */
/*   consentimiento por escrito, de parte de los representantes de  	  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  	  */
/*   en el presente texto, causará violaciones relacionadas con la  	  */
/*   propiedad intelectual y la confidencialidad de la información  	  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  	  */
/*   y penales en contra del infractor según corresponda. 				  */
/***********************************************************************  */
/*                               MODIFICACIONES                           */
/*  FECHA              AUTOR          CAMBIO                              */
/*  OCT-2010         Elcira Pelaez    Transaccion RES y Diferidos NR059   */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_op_calificacion  */
/*									  de char(1) a catalogo				  */
/**************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_historia_def_117668' and type = 'P')
   drop proc sp_historia_def_117668
go
---INC. 117668
create proc sp_historia_def_117668
   @i_operacionca  int,
   @i_secuencial   int = null
as declare
   @w_error             int,
   @w_return            int,
   @w_max_secuencial    int,
   @w_rc                int,
   @w_dividendo_desde   smallint,
   @w_rowcount_act      int,
   @w_estado_op         tinyint

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

select 
@w_op_toperacion       = op_toperacion,
@w_op_clase            = op_clase,
@w_op_cliente          = op_cliente,
@w_op_nombre           = op_nombre,
@w_op_tipo_linea       = op_tipo_linea,
@w_op_forma_pago       = op_forma_pago,
@w_op_codigo_externo   = op_codigo_externo,
@w_op_cuenta           = op_cuenta,
@w_op_direccion        = op_direccion,
@w_op_tipo_empresa     = op_tipo_empresa,
@w_op_estado_cobranza  = op_estado_cobranza,
@w_op_oficial          = op_oficial,
@w_op_oficina          = op_oficina,
@w_op_gar_admisible    = op_gar_admisible,
@w_op_calificacion     = op_calificacion
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0 begin
   print 'Error obteniendo datos estaticos de la obligacion ' + cast(@i_operacionca as varchar)
   return 710318
end

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
       op_suspendio,                op_fecha_suspenso,         op_banca)
       
select oph_operacion,               oph_banco,                 oph_anterior,
       oph_migrada,                 oph_tramite,               @w_op_cliente,
       @w_op_nombre,                oph_sector,                @w_op_toperacion,
       @w_op_oficina,               oph_moneda,                oph_comentario,
       @w_op_oficial,               oph_fecha_ini,             oph_fecha_fin,
       oph_fecha_ult_proceso,       oph_fecha_liq,             oph_fecha_reajuste,
       oph_monto,                   oph_monto_aprobado,        oph_destino,
       oph_lin_credito,             oph_ciudad,                oph_estado,
       oph_periodo_reajuste,        oph_reajuste_especial,     oph_tipo,
       @w_op_forma_pago,            @w_op_cuenta,              oph_dias_anio,
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
       @w_op_direccion,             @w_op_clase,               oph_origen_fondos,
       @w_op_calificacion,          @w_op_estado_cobranza,     oph_edad, 
       oph_opcion_cap,              oph_tasa_cap,              oph_dividendo_cap,
       oph_tipo_crecimiento,        oph_nro_red,               oph_base_calculo,
       oph_fondos_propios,          oph_dia_habil,             oph_recalcular_plazo,
       oph_usar_tequivalente,       oph_sal_pro_pon,           @w_op_tipo_empresa,
       oph_validacion,              oph_fecha_pri_cuot,        oph_causacion,
       oph_grupo_fact,              oph_tramite_ficticio,      oph_prd_cobis,
       oph_convierte_tasa,          @w_op_tipo_linea,          oph_subtipo_linea,
       oph_bvirtual,                oph_extracto,              oph_reestructuracion,
       oph_tipo_cambio,             oph_ref_exterior,          oph_sujeta_nego,
       oph_tipo_redondeo,           @w_op_gar_admisible,       oph_num_deuda_ext,
       oph_fecha_embarque,          oph_fecha_dex,             oph_naturaleza,
       oph_pago_caja,               oph_nace_vencida,          oph_num_comex,
       oph_calcula_devolucion,      @w_op_codigo_externo,      oph_margen_redescuento,
       oph_entidad_convenio,        oph_pproductor,            oph_fecha_ult_causacion,
       oph_mora_retroactiva,        oph_calificacion_ant,      oph_cap_susxcor,
       oph_prepago_desde_lavigente, oph_fecha_ult_mov,         oph_fecha_prox_segven,
       oph_suspendio,               oph_fecha_suspenso,        oph_banca
from   ca_operacion_his
where  oph_secuencial = @i_secuencial
and    oph_operacion  = @i_operacionca

select @w_error = @@error, @w_rc = @@rowcount

if @w_error <> 0 or @w_rc = 0
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

if @w_error <> 0 or @w_rc = 0
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

if @w_error <> 0 or @w_rc = 0
begin
   PRINT 'histdef.sp error insertando en ca_dividendo @i_secuencial , @w_dividendo_desde ' + cast(@i_secuencial as varchar) + cast(@w_dividendo_desde as varchar)
   return 710271
end

--select @w_rowcount_act = sqlcontext.gettriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN', 'N')
--EXEC sp_addextendedproperty
--    'CCA_TRIGGER','S',@level0type='Schema',@level0name=dbo,
--    @level1type='Table',@level1name=ca_amortizacion,
--    @level2type='Trigger',@level2name=tg_ca_amortizacion_can
 
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
--select @w_rowcount_act = sqlcontext.rmtriggercontext ('CCA_TRIGGER', 'AMORTIZACION_CAN')
--EXEC sp_dropextendedproperty
--      'CCA_TRIGGER',@level0type='Schema',@level0name=dbo,
--        @level1type='Table',@level1name=ca_amortizacion,
--        @level2type='Trigger',@level2name=tg_ca_amortizacion_can

if @w_error <> 0 or @w_rc = 0
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
   
   if @@error <> 0
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
   
   if @w_error <> 0 or @w_rc = 0
      print 'Operacion no tienen Registro de Correccion Monetaria'
       ---- return 710272
end


delete ca_cuota_adicional
where  ca_operacion = @i_operacionca

if @@error <> 0
   return 710003

insert ca_cuota_adicional
      (ca_operacion,      ca_dividendo,    ca_cuota )
select cah_operacion,     cah_dividendo,   cah_cuota
from   ca_cuota_adicional_his
where  cah_secuencial = @i_secuencial
and    cah_operacion  = @i_operacionca

if @@error <> 0
   return 710273

--RBU
delete ca_valores
where  va_operacion = @i_operacionca

if @@error <> 0
   return 710003

insert ca_valores
      (va_operacion,      va_dividendo,    va_rubro,   va_valor)
select vah_operacion,     vah_dividendo,   vah_rubro,  vah_valor 
from   ca_valores_his
where  vah_secuencial = @i_secuencial
and    vah_operacion  = @i_operacionca

if @@error <> 0
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

if @@error <> 0
   return 710260

delete ca_diferidos
where  dif_operacion = @i_operacionca

if @@error <> 0
   return 710003

insert ca_diferidos
      (dif_operacion, dif_valor_total,            dif_valor_pagado,  dif_concepto)
select difh_operacion, difh_valor_diferido ,      difh_valor_pagado, difh_concepto
from   ca_diferidos_his
where  difh_secuencial  = @i_secuencial
and    difh_operacion  = @i_operacionca

if @@error <> 0
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

if @@error <> 0
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

if @@error <> 0
   return 711005

-- FIN REQ 379 IFJ 22/Nov/2005

-- ELIMINAR LOS REGISTROS DEL HISTORIAL
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

--delete ca_operacion_his
--where  oph_secuencial >= @i_secuencial
--and    oph_operacion  =  @i_operacionca

if @@error <> 0
   return 710003
   
-- Tablas Seguros asociados a la Operación

delete  ca_seguros
where   se_operacion = @i_operacionca

insert ca_seguros
      (se_sec_seguro,      se_tipo_seguro,    se_sec_renovacion,    
       se_tramite,         se_operacion,      se_fec_devolucion,
       se_mto_devolucion,  se_estado)
select seh_sec_seguro,     seh_tipo_seguro,   seh_sec_renovacion,    
       seh_tramite,        seh_operacion,     seh_fec_devolucion,
       seh_mto_devolucion, seh_estado
from   ca_seguros_his
where  seh_secuencial = @i_secuencial
and    seh_operacion  = @i_operacionca

select @w_error = @@error, @w_rc = @@rowcount

if @w_error <> 0 --or @w_rc = 0
begin
   return 708229
end


delete  ca_seguros_det 
where   sed_operacion = @i_operacionca

insert ca_seguros_det
      (sed_operacion,       sed_sec_seguro,      sed_tipo_seguro,
       sed_sec_renovacion,  sed_tipo_asegurado,  sed_estado,
       sed_dividendo,       sed_cuota_cap,       sed_pago_cap,
       sed_cuota_int,       sed_pago_int,        sed_cuota_mora,
       sed_pago_mora)
select sedh_operacion,      sedh_sec_seguro,     sedh_tipo_seguro,
       sedh_sec_renovacion, sedh_tipo_asegurado, sedh_estado,
       sedh_dividendo,      sedh_cuota_cap,      sedh_pago_cap,
       sedh_cuota_int,      sedh_pago_int,       sedh_cuota_mora,
       sedh_pago_mora
from   ca_seguros_det_his
where  sedh_secuencial = @i_secuencial
and    sedh_operacion  = @i_operacionca

select @w_error = @@error, @w_rc = @@rowcount

if @w_error <> 0 --or @w_rc = 0
begin
   return 708230
end

delete  ca_seguros_can
where   sec_operacion = @i_operacionca

insert ca_seguros_can
      (sec_sec_seguro,      sec_tipo_seguro,    sec_sec_renovacion,    
       sec_tramite,         sec_operacion,      sec_fec_can,
       sec_sec_pag)
select sech_sec_seguro,     sech_tipo_seguro,   sech_sec_renovacion,    
       sech_tramite,        sech_operacion,     sech_fec_can,
       sech_sec_pag
from   ca_seguros_can_his
where  sech_secuencial = @i_secuencial
and    sech_operacion  = @i_operacionca

select @w_error = @@error, @w_rc = @@rowcount

if @w_error <> 0 --or @w_rc = 0
begin
   print 'histdef.sp: NO FUE POSIBLE RECUPERAR HISTORICO DE SEGUROS CANCELADOS'
   return 708229
end
   

 
return 0

go
