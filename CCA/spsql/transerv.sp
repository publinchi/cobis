/************************************************************************/
/*  NOMBRE LOGICO:        transerv.sp                                   */
/*  NOMBRE FISICO:        sp_tran_servicio                              */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         P. Narvaez                                    */
/*  FECHA DE ESCRITURA:   17/12/1997                                    */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*                              PROPOSITO                               */
/*      Insercion de transacciones de servicio para cada tabla          */
/************************************************************************/  
/*                          CAMBIOS                                     */
/*   10-ABR-2020       Luis Ponce       CDIG Ajustes por migracion Java */
/*   05-NOV-2020       EMP-JJEC         Rubros Financiados              */
/*   19/Nov/2020       EMP-JJEC         Control Tasa INT Maxima/Minima  */
/* 06/Ene/2021   P.Narvaez  Tipo de Reestructuracion/Tipo Renovacion    */
/* 10/Jun/2021   G. Fernandez       Agrego nombre de campos en el insert*/
/*                                     ca_default_toperacion_ts         */
/* 01/Sep/2021   R. Rincon       Se agrega transaccion para ca_pin_odp  */
/* 30/Sep/2021   K.Rodríguez     Corrección registro transacción pin-odp*/
/*                               y Estado gestión de cobranza           */
/* 10/Ene/2022   G. Fernandez    Ingreso de campo de grupo contable     */
/* 30/Nov/2022   J. Guzman       Logica para ca_incentivos_metas_ts     */
/* 06/ABR/2023   g. Fernandez    Ingreso de campo de oda_categoria_plazo*/
/* 07/Jun/2023   K. Rodríguez    S809862 Tipo Documento. tributario TS  */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_tran_servicio')
	drop proc sp_tran_servicio
go

---Mar-14-2011 Inc-18565  Ver.  partiendo de 1

create proc sp_tran_servicio
   @s_date                 datetime,
   @s_user                 login,
   @s_ofi                  smallint,
   @s_term                 varchar(30),
   @i_tabla                varchar(255),
   @i_clave1               varchar(255),
   @i_clave2               varchar(255) = null,
   @i_clave3               varchar(255) = null,
   @i_clave4               varchar(255) = null,
   @i_clave5               varchar(255) = null,
   @i_clave6               varchar(255) = null,
   @i_clave7               varchar(255) = null,
   @i_clave8               varchar(255) = null,
   @i_clave9               varchar(255) = null,
   @i_clave10              varchar(255) = null
as

declare 
   @w_error             int ,
   @w_operacionca       int ,
   @w_sp_name           descripcion

-- VARIABLES INICIALES
select @w_sp_name = 'sp_tran_servicio'

begin tran

if @i_tabla = 'matriz_valor'
begin
   insert into ca_matriz_valor_ts
   select @s_user, @s_ofi, @s_term,'U', getdate(),  *
   from   ca_matriz_valor_tmp
   where mvt_matriz    = convert(char(10),@i_clave1)
   and   mvt_fecha_vig = convert(datetime,@i_clave2)
   and   mvt_rango1    = convert(int,@i_clave3) 
   and   mvt_rango2    = convert(int,@i_clave4) 
   and   mvt_rango3    = convert(int,@i_clave5) 
   and   mvt_rango4    = convert(int,@i_clave6) 
   and   mvt_rango5    = convert(int,@i_clave7) 
   and   mvt_rango6    = convert(int,@i_clave8) 
   and   mvt_rango7    = convert(int,@i_clave9) 
   and   mvt_valor     = convert(float,@i_clave10)    

   if @@error <> 0
      return 721902
end      

if @i_tabla = 'eje_rango'
begin
   insert into ca_eje_rango_ts
   select @s_user, @s_ofi, @s_term,@i_clave3, getdate(),  *
   from   ca_eje_rango_tmp
   where ert_matriz    = convert(char(10),@i_clave1)
   and   ert_fecha_vig = convert(datetime,@i_clave2)
   and   ert_eje       = convert(int,@i_clave4)
   and   ert_rango     = convert(int,@i_clave5)
   
   if @@error <> 0
      return 721903
end

if @i_tabla = 'eje'
begin
   insert into ca_eje_ts
   select @s_user, @s_ofi, @s_term,@i_clave3, getdate(),  *
   from   ca_eje_tmp
   where ejt_matriz    = convert(char(10),@i_clave1)
   and   ejt_fecha_vig = convert(datetime,@i_clave2)
   and   ejt_eje       = convert(int,@i_clave4)
   
   if @@error <> 0
      return 721904
end

if @i_tabla = 'ca_operacion'
begin
   insert into ca_operacion_ts
   select @s_date, getdate(), @s_user, @s_ofi, @s_term,
     op_operacion,op_banco,op_anterior,op_migrada,op_tramite,op_cliente,op_nombre,op_sector,op_toperacion,op_oficina
	,op_moneda,op_comentario,op_oficial,op_fecha_ini,op_fecha_fin,op_fecha_ult_proceso,op_fecha_liq,op_fecha_reajuste
	,op_monto,op_monto_aprobado,op_destino,op_lin_credito,op_ciudad,op_estado,op_periodo_reajuste,op_reajuste_especial
	,op_tipo,op_forma_pago,op_cuenta,op_dias_anio,op_tipo_amortizacion,op_cuota_completa,op_tipo_cobro,op_tipo_reduccion
	,op_aceptar_anticipos,op_precancelacion,op_tipo_aplicacion,op_tplazo,op_plazo,op_tdividendo,op_periodo_cap,op_periodo_int
	,op_dist_gracia,op_gracia_cap,op_gracia_int,op_dia_fijo,op_cuota,op_evitar_feriados,op_num_renovacion,op_renovacion
	,op_mes_gracia,op_reajustable,op_dias_clausula,op_divcap_original,op_clausula_aplicada,op_traslado_ingresos
	,op_periodo_crecimiento,op_tasa_crecimiento,op_direccion,op_opcion_cap,op_tasa_cap,op_dividendo_cap
	,op_clase,op_origen_fondos,op_calificacion,op_estado_cobranza,op_numero_reest,op_edad,op_tipo_crecimiento
	,op_base_calculo,op_prd_cobis,op_ref_exterior,op_sujeta_nego,op_dia_habil,op_recalcular_plazo,op_usar_tequivalente
	,op_fondos_propios,op_nro_red,op_tipo_redondeo,op_sal_pro_pon,op_tipo_empresa,op_validacion,op_fecha_pri_cuot
	,op_gar_admisible,op_causacion,op_convierte_tasa,op_grupo_fact,op_tramite_ficticio,op_tipo_linea,op_subtipo_linea
	,op_bvirtual,op_extracto,op_num_deuda_ext,op_fecha_embarque,op_fecha_dex,op_reestructuracion,op_tipo_cambio
	,op_naturaleza,op_pago_caja,op_nace_vencida,op_num_comex,op_calcula_devolucion,op_codigo_externo,op_margen_redescuento
	,op_entidad_convenio,op_pproductor,op_fecha_ult_causacion,op_mora_retroactiva,op_calificacion_ant,op_cap_susxcor
	,op_prepago_desde_lavigente,op_fecha_ult_mov,op_fecha_prox_segven,op_suspendio,op_fecha_suspenso
	,op_honorarios_cobranza,op_banca,op_promocion,op_acepta_ren,op_no_acepta,op_emprendimiento,op_valor_cat
    ,op_grupo, op_ref_grupal, op_grupal,op_fondeador, op_admin_individual, op_estado_hijas, op_tipo_renovacion, op_tipo_reest
    ,op_fecha_reest, op_fecha_reest_noestandar
   from   ca_operacion
   where  op_operacion = convert(int,@i_clave1) 
   
   if @@error <> 0
      return 710047
end

if @i_tabla = 'ca_reajuste'
begin
   insert into ca_reajuste_ts 
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date, getdate(), @s_user, @s_ofi, @s_term, re_secuencial, re_operacion, re_fecha, re_reajuste_especial, re_desagio, re_sec_aviso  --LPO CDIG Ajuste por migracion a Java
   from   ca_reajuste
   where  re_operacion  = convert(int, @i_clave1)
   and    re_secuencial = convert(int, @i_clave2)
   
   if @@error <> 0
      return 710048
end

if @i_tabla = 'ca_reajuste_det'
begin
   insert into ca_reajuste_det_ts 
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *   --LPO CDIG Ajuste por migracion a Java
   select @s_date, getdate(), @s_user, @s_ofi, @s_term, red_secuencial, red_operacion, red_concepto, red_referencial, red_signo, red_factor, red_porcentaje    --LPO CDIG Ajuste por migracion a Java
   from   ca_reajuste_det
   where  red_operacion  = convert(int,@i_clave1)
   and    red_secuencial = convert(int,@i_clave2)
   and    red_concepto   = convert(char(10), @i_clave3)
   
   if @@error <> 0
      return 710049
end

if @i_tabla = 'ca_default_toperacion'
begin
	--GFP Agrega nombre de campos en el insert para el mapeo correcto
   insert into ca_default_toperacion_ts (dts_fecha_proceso_ts, dts_fecha_ts, dts_usuario_ts, dts_oficina_ts, dts_terminal_ts,
	dts_toperacion          , dts_moneda              		, dts_reajustable         , dts_periodo_reaj           ,
	dts_reajuste_especial   , dts_renovacion          		, dts_tipo                , dts_estado                 ,
	dts_precancelacion      , dts_cuota_completa      		, dts_tipo_cobro          , dts_tipo_reduccion         ,
	dts_aceptar_anticipos   , dts_tipo_aplicacion     		, dts_tplazo              , dts_plazo                  ,
	dts_tdividendo          , dts_periodo_cap         		, dts_periodo_int         , dts_gracia_cap             ,
	dts_gracia_int          , dts_dist_gracia         		, dts_dias_anio           , dts_tipo_amortizacion      ,
	dts_fecha_fija          , dts_dia_pago            		, dts_cuota_fija          , dts_dias_gracia            ,
	dts_evitar_feriados     , dts_mes_gracia          		, dts_base_calculo        , dts_prd_cobis              ,
	dts_dia_habil           , dts_recalcular_plazo    		, dts_usar_tequivalente   , dts_tipo_redondeo          ,
	dts_causacion           , dts_convertir_tasa      		, dts_tipo_linea          , dts_subtipo_linea          ,
	dts_bvirtual            , dts_extracto            		, dts_naturaleza          , dts_pago_caja              ,
	dts_nace_vencida        , dts_calcula_devolucion  		, dts_categoria           , dts_entidad_convenio       ,
	dts_mora_retroactiva    , dts_prepago_desde_lavigente   , dts_dias_anio_mora      , dts_tipo_calif             ,
	dts_plazo_min           , dts_plazo_max                 , dts_monto_min           , dts_monto_max              ,
	dts_clase_sector        , dts_clase_cartera             , dts_gar_admisible       , dts_afecta_cupo            ,
	dts_control_dia_pago    , dts_porcen_colateral          , dts_subsidio            , dts_tipo_prioridad         ,
	dts_dia_ppago           , dts_efecto_pago               , dts_tpreferencial       , dts_modo_reest             ,
	dts_cuota_menor         , dts_fondos_propios            , dts_admin_individual)
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date, getdate(), @s_user, @s_ofi, @s_term,   --LPO CDIG Ajuste por migracion a Java
	dt_toperacion             ,	dt_moneda                 ,	dt_reajustable            ,	dt_periodo_reaj           ,
	dt_reajuste_especial      ,	dt_renovacion             ,	dt_tipo                   ,	dt_estado                 ,
	dt_precancelacion         ,	dt_cuota_completa         ,	dt_tipo_cobro             ,	dt_tipo_reduccion         ,
	dt_aceptar_anticipos      ,	dt_tipo_aplicacion        ,	dt_tplazo                 ,	dt_plazo                  ,
	dt_tdividendo             ,	dt_periodo_cap            ,	dt_periodo_int            ,	dt_gracia_cap             ,
	dt_gracia_int             ,	dt_dist_gracia            ,	dt_dias_anio              ,	dt_tipo_amortizacion      ,
	dt_fecha_fija             ,	dt_dia_pago               ,	dt_cuota_fija             ,	dt_dias_gracia            ,
	dt_evitar_feriados        ,	dt_mes_gracia             ,	dt_base_calculo           ,	dt_prd_cobis              ,
	dt_dia_habil              ,	dt_recalcular_plazo       ,	dt_usar_tequivalente      ,	dt_tipo_redondeo          ,
	dt_causacion              ,	dt_convertir_tasa         ,	dt_tipo_linea             ,	dt_subtipo_linea          ,
	dt_bvirtual               ,	dt_extracto               ,	dt_naturaleza             ,	dt_pago_caja              ,
	dt_nace_vencida           ,	dt_calcula_devolucion     ,	dt_categoria              ,	dt_entidad_convenio       ,
	dt_mora_retroactiva       ,	dt_prepago_desde_lavigente,	dt_dias_anio_mora         ,	dt_tipo_calif             ,
	dt_plazo_min              ,	dt_plazo_max              ,	dt_monto_min              ,	dt_monto_max              ,
	dt_clase_sector           ,	dt_clase_cartera          ,	dt_gar_admisible          ,	dt_afecta_cupo            ,
	dt_control_dia_pago       ,	dt_porcen_colateral       ,	dt_subsidio               ,	dt_tipo_prioridad         ,
	dt_dia_ppago              ,	dt_efecto_pago            ,	dt_tpreferencial          ,	dt_modo_reest             ,
	dt_cuota_menor            ,	dt_fondos_propios         ,	dt_admin_individual
   from   ca_default_toperacion
   where  dt_toperacion   = @i_clave1
   and    dt_moneda       = convert(int,@i_clave2)
   
   if @@error <> 0
      return 710050
end

if @i_tabla = 'ca_rubro'
begin
   insert into ca_rubro_ts 
   
   select @s_date, getdate(), @s_user, @s_ofi, @s_term
	,ru_toperacion,ru_moneda,ru_concepto,ru_prioridad,ru_tipo_rubro,ru_paga_mora,ru_provisiona,ru_fpago,ru_crear_siempre
	,ru_tperiodo,ru_periodo,ru_referencial,ru_reajuste,ru_banco,ru_estado,ru_concepto_asociado,ru_redescuento,ru_intermediacion
	,ru_principal,ru_saldo_op,ru_saldo_por_desem,ru_pit,ru_limite,ru_mora_interes,ru_iva_siempre,ru_monto_aprobado
	,ru_porcentaje_cobrar,ru_tipo_garantia,ru_valor_garantia,ru_porcentaje_cobertura,ru_tabla,ru_saldo_insoluto,ru_calcular_devolucion
	,ru_tasa_aplicar,ru_valor_max,ru_valor_min,ru_afectacion,ru_diferir,ru_tipo_seguro,ru_tasa_efectiva, ru_financiado
	,ru_tasa_maxima, ru_tasa_minima
	
   from   ca_rubro
   where  ru_toperacion   = @i_clave1
   and    ru_moneda       = convert(tinyint,@i_clave2)
   and    ru_concepto     = @i_clave3
   
   if @@error <> 0
      return 710051
end

if @i_tabla = 'ca_rubro_op'
begin
   insert into ca_rubro_op_ts 
   
   select @s_date, getdate(), @s_user, @s_ofi, @s_term
	,ro_operacion,ro_concepto,ro_tipo_rubro,ro_fpago,ro_prioridad,ro_paga_mora,ro_provisiona,ro_signo,ro_factor
	,ro_referencial,ro_signo_reajuste,ro_factor_reajuste,ro_referencial_reajuste,ro_valor,ro_porcentaje,ro_porcentaje_aux
	,ro_gracia,ro_concepto_asociado,ro_redescuento,ro_intermediacion,ro_principal,ro_porcentaje_efa,ro_garantia
	,ro_tipo_puntos,ro_saldo_op,ro_saldo_por_desem,ro_base_calculo,ro_num_dec,ro_limite,ro_iva_siempre,ro_monto_aprobado
	,ro_porcentaje_cobrar,ro_tipo_garantia,ro_nro_garantia,ro_porcentaje_cobertura,ro_valor_garantia,ro_tperiodo,ro_periodo
	,ro_tabla,ro_saldo_insoluto,ro_calcular_devolucion,ro_financiado
	,ro_tasa_maxima, ro_tasa_minima
   from   ca_rubro_op
   where  ro_operacion   = convert(int,@i_clave1)
   and    ro_concepto    = @i_clave2
   
   if @@error <> 0
      return 710052
end

if @i_tabla = 'ca_valor_referencial'
begin
   insert into ca_valor_referencial_ts (vrs_fecha_proceso_ts, vrs_fecha_ts, 
    vrs_usuario_ts, vrs_oficina_ts, vrs_terminal_ts, vrs_tipo, 
    vrs_valor, vrs_fecha_vig, vrs_secuencial)
   select @s_date, getdate(), @s_user, @s_ofi, @s_term, vr_tipo,
    vr_valor, vr_fecha_vig, vr_secuencial
   from   ca_valor_referencial
   where  vr_tipo      = @i_clave1
   and    vr_fecha_vig = @i_clave2
   and    vr_secuencial = convert(int,@i_clave3)
   
   if @@error <> 0
      return 710053
end

if @i_tabla = 'ca_valor'
begin
   insert into ca_valor_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date, getdate(), @s_user, @s_ofi, @s_term, va_tipo, va_descripcion, va_clase, va_pit, va_prime  --LPO CDIG Ajuste por migracion a Java
   from   ca_valor
   where  va_tipo      = @i_clave1
   
   if @@error <> 0
	  return 710054
end


if @i_tabla = 'ca_valor_det'
begin
   insert into ca_valor_det_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date,          getdate(),       @s_user,         @s_ofi,          @s_term,       vd_tipo, vd_sector, vd_signo_default, vd_valor_default,
	      vd_signo_maximo,	vd_valor_maximo, vd_signo_minimo, vd_valor_minimo, vd_referencia, vd_tipo_puntos,     vd_num_dec  --LPO CDIG Ajuste por migracion a Java
   from   ca_valor_det
   where  vd_tipo   = @i_clave1
   and    vd_sector = @i_clave2
   
   if @@error <> 0
      return 710055
end

if @i_tabla = 'ca_estados_man'
begin
   insert into ca_estados_man_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date,       getdate(),    @s_user,     @s_ofi,   @s_term,   em_toperacion,   em_tipo_cambio,   em_estado_ini,
          em_estado_fin, em_dias_cont, em_dias_fin  --LPO CDIG Ajuste por migracion a Java
   from   ca_estados_man
   where  em_toperacion  = @i_clave1
   and    em_tipo_cambio = @i_clave2
   and    em_estado_ini  = convert(tinyint,@i_clave3)
   and    em_estado_fin  = convert(tinyint,@i_clave4)
   
   if @@error <> 0
      return 710056
end

if @i_tabla = 'ca_estados_rubro'
begin
   insert into ca_estados_rubro_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date, getdate(), @s_user, @s_ofi, @s_term, er_toperacion, er_concepto, er_estado, er_dias_cont, er_dias_fin  --LPO CDIG Ajuste por migracion a Java
   from   ca_estados_rubro
   where  er_toperacion  = @i_clave1
   and    er_concepto    = @i_clave2
   and    er_estado      = convert(tinyint,@i_clave3)
   
   if @@error <> 0
      return 710057
end

if @i_tabla = 'ca_dividendo'
begin
   insert into ca_dividendo_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date,         getdate(),         @s_user,       @s_ofi,      @s_term,        di_operacion,    di_dividendo,  di_fecha_ini,
	      di_fecha_ven,    di_de_capital,     di_de_interes, di_gracia,   di_gracia_disp, di_estado,       di_dias_cuota, di_intento,
          di_prorroga,     di_fecha_can  --LPO CDIG Ajuste por migracion a Java
   from   ca_dividendo
   where  di_operacion   = convert(int,@i_clave1)
   and    di_dividendo   = convert(int,@i_clave2)
   
   if @@error <> 0
      return 721600
end

-- CEH REQ 264 DESEMBOLSOS GMF
if @i_tabla = 'ca_desembolso'
begin
   insert into ca_desembolso_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date,               getdate(),             @s_user,               @s_ofi,                @s_term,               dm_secuencial         ,
          dm_operacion          ,dm_desembolso         ,dm_producto           ,dm_cuenta             ,dm_beneficiario       ,dm_oficina_chg        ,
          dm_usuario            ,dm_oficina            ,dm_terminal           ,dm_dividendo          ,dm_moneda             ,dm_monto_mds          ,
          dm_monto_mop          ,dm_monto_mn           ,dm_cotizacion_mds     ,dm_cotizacion_mop     ,dm_tcotizacion_mds    ,dm_tcotizacion_mop    ,
          dm_estado             ,dm_cod_banco          ,dm_cheque             ,dm_fecha              ,dm_prenotificacion    ,dm_carga              ,
          dm_concepto           ,dm_valor              ,dm_ente_benef         ,dm_idlote             ,dm_pagado             ,dm_orden_caja         ,
          dm_cruce_restrictivo  ,dm_destino_economico  ,dm_carta_autorizacion ,dm_fecha_ingreso        --LPO CDIG Ajuste por migracion a Java
   from   ca_desembolso
   where  dm_operacion   = convert(int,@i_clave1)
   
   if @@error <> 0
      return 721600 
end
-- FIN REQ 264
if @i_tabla = 'ca_param_condona'
begin
   insert into ca_param_condona_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, @i_clave2, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date,              getdate(),           @s_user,           @s_ofi,               @s_term,                 @i_clave2,          
          pc_codigo,            pc_estado,           pc_banca,          pc_rubro,             pc_mora_inicial,         pc_mora_final,
          pc_ano_castigo,       pc_porcentaje_max,   pc_valor_maximo,   pc_valores_vigentes,  pc_control_autorizacion, pc_valores_noven  --LPO CDIG Ajuste por migracion a Java
   from   ca_param_condona
   where  pc_codigo   = convert(smallint,@i_clave1)
   
   if @@error <> 0
      return 721600 
end

if @i_tabla = 'ca_rol_condona'
begin
   insert into ca_rol_condona_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, @i_clave3, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date, getdate(), @s_user, @s_ofi, @s_term, @i_clave3, rc_rol, rc_condonacion  --LPO CDIG Ajuste por migracion a Java
   from   ca_rol_condona
   where  rc_rol   = convert(tinyint,@i_clave1)
   and    rc_condonacion = convert(smallint,@i_clave2)
   
   if @@error <> 0
      return 721600
end

if @i_tabla = 'ca_rol_autoriza_condona'
begin
   insert into ca_rol_autoriza_condona_ts
   
   --select @s_date, getdate(), @s_user, @s_ofi, @s_term, @i_clave3, *  --LPO CDIG Ajuste por migracion a Java
   select @s_date, getdate(), @s_user, @s_ofi, @s_term, @i_clave3, rac_rol_condona, rac_rol_autoriza  --LPO CDIG Ajuste por migracion a Java
   from   ca_rol_autoriza_condona
   where  rac_rol_condona   = convert(tinyint,@i_clave1)
   and    rac_rol_autoriza  = convert(smallint,@i_clave2)
   
   if @@error <> 0
      return 721600 
end

if @i_tabla = 'ca_condonacion'
begin

   if @i_clave4 = 'I'
   begin
      insert into ca_condonacion_ts  (
      cos_fecha_proceso_ts,cos_fecha_ts        ,cos_usuario_ts      ,cos_oficina_ts  ,            
      cos_terminal_ts     ,cos_operacion_ts,    cos_secuencial      ,cos_operacion   ,
      cos_fecha_aplica    ,cos_valor           ,cos_porcentaje      ,cos_concepto    ,
      cos_estado_concepto ,cos_usuario         ,cos_rol_condona     ,cos_autoriza    ,
      cos_estado          ,cos_excepcion       ,cos_porcentaje_par )
      select 
      @s_date            ,getdate()           ,@s_user              ,@s_ofi          ,
      @s_term            ,@i_clave4           ,co_secuencial        ,co_operacion    ,
      co_fecha_aplica    ,co_valor            ,co_porcentaje        ,co_concepto     ,
      co_estado_concepto ,co_usuario          ,co_rol_condona       ,co_autoriza     ,
      co_estado          ,co_excepcion        ,co_porcentaje_par 
      from   ca_condonacion
      where  co_operacion   = convert(int,@i_clave1)
      and    co_secuencial  = convert(int,@i_clave2)
      and    co_concepto    = convert(varchar(10),@i_clave3)
   
      if @@error <> 0
         return 721600 
   end

   if @i_clave4 in ('A','E','R')
   begin
      insert into ca_condonacion_ts (
      cos_fecha_proceso_ts,cos_fecha_ts        ,cos_usuario_ts      ,cos_oficina_ts      ,cos_terminal_ts     ,cos_operacion_ts    ,
      cos_secuencial      ,cos_operacion       ,cos_fecha_aplica    ,cos_valor           ,cos_porcentaje      ,
      cos_concepto        ,cos_estado_concepto ,cos_usuario         ,cos_rol_condona     ,cos_autoriza        ,
      cos_estado          ,cos_excepcion       ,cos_porcentaje_par         )
      
      select @s_date      ,getdate()           ,@s_user             ,@s_ofi             ,@s_term            , @i_clave4, 
      min(co_secuencial)  ,min(co_operacion)    ,min(co_fecha_aplica),sum(co_valor)      , 0,
      ''                  ,min(co_estado_concepto), min(co_usuario)  ,min(co_rol_condona), min(co_autoriza),
      min(co_estado)      ,min(co_excepcion)    , min(co_porcentaje_par)
      from   ca_condonacion
      where  co_operacion   = convert(int,@i_clave1)
      and    co_secuencial  = convert(int,@i_clave2)
      
      if @@error <> 0
         return 721600 
   end

end

if @i_tabla = 'ca_pin_odp'
begin
   insert into ca_pin_odp_ts (
		po_fecha_proceso_ts,           po_fecha_ts,            po_usuario_ts,           po_oficina_ts, 
		po_terminal_ts,                po_accion_ts,           po_operacion_ts,         po_desembolso_ts,
		po_secuencial_desembolso_ts,   po_secuencial_pin_ts,   po_pin_ts,               po_fecha_generacion_ts,
		po_fecha_vencimiento_ts,       po_fecha_bloqueo_ts,    po_fecha_anulacion_ts,   po_estado_ts
   ) select
		@s_date,                       getdate(),              @s_user,                 @s_ofi,          
		@s_term,                       @i_clave5,              po_operacion,            po_desembolso,
		po_secuencial_desembolso,      po_secuencial_pin,      po_pin,                  po_fecha_generacion,
		po_fecha_vencimiento,          po_fecha_bloqueo,       po_fecha_anulacion,      po_estado
   from   ca_pin_odp
   where po_operacion 				= convert(int, @i_clave1)
   and po_desembolso 				= convert(tinyint, @i_clave2)
   and po_secuencial_desembolso 	= convert(int, @i_clave3)
   and po_secuencial_pin 			= convert(int, @i_clave4)
   
   if @@error != 0
      return 721600 
end

if @i_tabla = 'ca_operacion_datos_adicionales'
begin
   insert into ca_operacion_datos_adicionales_ts (
		oda_fecha_proceso_ts, oda_fecha_ts,                    oda_usuario_ts,            oda_oficina_ts,   
		oda_terminal_ts,      oda_accion_ts,                   oda_orden_accion_ts,
		oda_operacion_ts, 	  oda_estado_gestion_cobranza_ts,  oda_aceptar_pagos_ts,      oda_grupo_contable_ts,
		oda_categoria_plazo_ts, oda_tipo_documento_fiscal_ts
   ) select
		@s_date,              getdate(),                       @s_user,                   @s_ofi,          
		@s_term,              @i_clave2,                       @i_clave3,
		oda_operacion,        oda_estado_gestion_cobranza,     oda_aceptar_pagos,         oda_grupo_contable,
		oda_categoria_plazo,  oda_tipo_documento_fiscal
   from   ca_operacion_datos_adicionales
   where oda_operacion 	= convert(int, @i_clave1)
   
   if @@error != 0
      return 721600 
end

if @i_tabla = 'ca_incentivos_metas'
begin
   insert into ca_incentivos_metas_ts(
       ims_fecha_proceso_ts,    ims_fecha_real_ts,     ims_usuario_ts,        ims_oficina_ts,
	   ims_terminal_ts,         ims_accion_ts,         ims_anio,              ims_oficina,             
	   ims_cod_asesor,          ims_mes,               ims_nombre_asesor,     ims_monto_proyectado,          
	   ims_observacion_ts,      ims_opcion_ts
   ) select
		@s_date,                getdate(),             @s_user,               @s_ofi,          
		@s_term,                @i_clave6,             im_anio,               im_oficina,
		im_cod_asesor,          im_mes,                im_nombre_asesor,      im_monto_proyectado,  
		@i_clave5,              @i_clave7
   from   ca_incentivos_metas
   where im_anio        = convert(int, @i_clave1)
   and im_oficina       = convert(tinyint, @i_clave2)
   and im_cod_asesor 	= convert(int, @i_clave3)
   and im_mes 			= convert(int, @i_clave4)
   
   if @@error != 0
      return 721600 
end

commit tran

return 0

  

GO

