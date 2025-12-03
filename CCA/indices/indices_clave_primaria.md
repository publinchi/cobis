# Índices por Clave Primaria

Este documento lista todos los índices de clave primaria de las tablas del módulo de cartera COBIS.

## Tablas cob_cartera

### ca_abono
- **ca_abono_1** (CLUSTERED INDEX): ab_secuencial_ing, ab_operacion

### ca_abono_det
- **ca_abono_det_1** (UNIQUE NONCLUSTERED INDEX): abd_operacion, abd_secuencial_ing, abd_tipo, abd_concepto, abd_cuenta

### ca_abono_det_tmp
- **ca_abono_det_tmp_1** (UNIQUE NONCLUSTERED INDEX): adt_operacion, adt_secuencial_ing, adt_tipo, adt_concepto, adt_cuenta

### ca_abono_grupal_tmp
- **ca_abono_grupal_tmp_1** (UNIQUE NONCLUSTERED INDEX): agt_secuencial

### ca_abono_prioridad
- **ca_abono_prioridad_1** (UNIQUE NONCLUSTERED INDEX): ap_operacion, ap_secuencial_ing, ap_dividendo, ap_concepto

### ca_abono_prioridad_tmp
- **ca_abono_prioridad_tmp_1** (UNIQUE NONCLUSTERED INDEX): apt_operacion, apt_secuencial_ing, apt_dividendo, apt_concepto

### ca_amortizacion
- **ca_amortizacion_1** (CLUSTERED INDEX): am_operacion, am_dividendo, am_concepto

### ca_amortizacion_tmp
- **ca_amortizacion_tmp_1** (CLUSTERED INDEX): amt_operacion, amt_dividendo, amt_concepto

### ca_archivo_pagos_1
- **ca_archivo_pagos_1_1** (UNIQUE NONCLUSTERED INDEX): ap_secuencial

### ca_archivo_pagos_1_tmp
- **ca_archivo_pagos_1_tmp_1** (UNIQUE NONCLUSTERED INDEX): apt_secuencial

### ca_batch_pagos_corresponsal
- **ca_batch_pagos_corresponsal_1** (UNIQUE NONCLUSTERED INDEX): bpc_lote

### ca_cambio_estado_masivo
- **ca_cambio_estado_masivo_1** (UNIQUE NONCLUSTERED INDEX): cem_secuencial

### ca_ciclo
- **ca_ciclo_1** (UNIQUE NONCLUSTERED INDEX): ci_grupo, ci_ciclo

### ca_cliente_calificacion
- **ca_cliente_calificacion_1** (NONCLUSTERED INDEX): cc_cliente, cc_fecha

### ca_concepto
- **ca_concepto_1** (UNIQUE NONCLUSTERED INDEX): co_concepto

### ca_conversion
- **ca_conversion_1** (UNIQUE NONCLUSTERED INDEX): cv_tipo

### ca_cuota_adicional
- **ca_cuota_adicional_1** (UNIQUE NONCLUSTERED INDEX): ca_operacion, ca_secuencial

### ca_datos_adicionales_pasivas
- **ca_datos_adicionales_pasivas_1** (UNIQUE NONCLUSTERED INDEX): dap_operacion, dap_campo

### ca_datos_adicionales_pasivas_t
- **ca_datos_adicionales_pasivas_t_1** (UNIQUE NONCLUSTERED INDEX): dapt_operacion, dapt_campo

### ca_decodificador
- **ca_decodificador_1** (UNIQUE NONCLUSTERED INDEX): de_operacion, de_campo, de_posicion

### ca_default_toperacion
- **ca_default_toperacion_1** (UNIQUE NONCLUSTERED INDEX): dt_toperacion, dt_moneda

### ca_desembolso
- **ca_desembolso_1** (UNIQUE NONCLUSTERED INDEX): de_operacion, de_secuencial

### ca_det_ciclo
- **ca_det_ciclo_1** (UNIQUE NONCLUSTERED INDEX): dc_grupo, dc_ciclo, dc_operacion

### ca_dividendo
- **ca_dividendo_1** (CLUSTERED INDEX): di_operacion, di_dividendo

### ca_dividendo_tmp
- **ca_dividendo_tmp_1** (CLUSTERED INDEX): dit_operacion, dit_dividendo

### ca_en_fecha_valor
- **ca_en_fecha_valor_1** (UNIQUE NONCLUSTERED INDEX): efv_codigo

### ca_en_fecha_valor_grupal
- **ca_en_fecha_valor_grupal_1** (UNIQUE NONCLUSTERED INDEX): efvg_codigo

### ca_errorlog
- **ca_errorlog_1** (UNIQUE NONCLUSTERED INDEX): er_secuencial

### ca_errores_ope_masivas
- **ca_errores_ope_masivas_1** (UNIQUE NONCLUSTERED INDEX): eom_secuencial

### ca_estado
- **ca_estado_1** (UNIQUE NONCLUSTERED INDEX): es_codigo

### ca_estados_man
- **ca_estados_man_1** (UNIQUE NONCLUSTERED INDEX): em_estado_origen, em_estado_destino

### ca_incentivos_detalle_operaciones
- **ca_incentivos_detalle_operaciones_1** (UNIQUE NONCLUSTERED INDEX): ido_secuencial

### ca_incentivos_metas
- **ca_incentivos_metas_1** (UNIQUE NONCLUSTERED INDEX): im_codigo

### ca_incentivos_metas_tmp
- **ca_incentivos_metas_tmp_1** (UNIQUE NONCLUSTERED INDEX): imt_codigo

### ca_incentivos_obtencion_indicadores
- **ca_incentivos_obtencion_indicadores_1** (UNIQUE NONCLUSTERED INDEX): ioi_secuencial

### ca_oficial_nomina
- **ca_oficial_nomina_1** (UNIQUE NONCLUSTERED INDEX): on_oficial, on_oficina, on_fecha_inicio

### ca_operacion
- **ca_operacion_1** (UNIQUE NONCLUSTERED INDEX): op_operacion

### ca_operacion_datos_adicionales
- **ca_operacion_datos_adicionales_1** (UNIQUE NONCLUSTERED INDEX): oda_operacion, oda_campo

### ca_operacion_tmp
- **ca_operacion_tmp_1** (UNIQUE NONCLUSTERED INDEX): opt_operacion

### ca_otro_cargo
- **ca_otro_cargo_1** (UNIQUE NONCLUSTERED INDEX): oc_operacion, oc_secuencial

### ca_param_cargos_gestion_cobranza
- **ca_param_cargos_gestion_cobranza_1** (UNIQUE NONCLUSTERED INDEX): pcgc_codigo

### ca_pin_odp
- **ca_pin_odp_1** (UNIQUE NONCLUSTERED INDEX): po_operacion, po_secuencial

### ca_producto
- **ca_producto_1** (UNIQUE NONCLUSTERED INDEX): pr_codigo

### ca_provision_cartera
- **ca_provision_cartera_1** (UNIQUE NONCLUSTERED INDEX): pc_operacion, pc_fecha_proceso

### ca_qr_transacciones_tmp
- **ca_qr_transacciones_tmp_1** (UNIQUE NONCLUSTERED INDEX): qrt_secuencial

### ca_reajuste
- **ca_reajuste_1** (UNIQUE NONCLUSTERED INDEX): re_operacion, re_secuencial

### ca_reajuste_det
- **ca_reajuste_det_1** (UNIQUE NONCLUSTERED INDEX): rd_operacion, rd_secuencial, rd_dividendo, rd_concepto

### ca_registra_traslados_masivos
- **ca_registra_traslados_masivos_1** (UNIQUE NONCLUSTERED INDEX): rtm_secuencial

### ca_rubro
- **ca_rubro_1** (UNIQUE NONCLUSTERED INDEX): ru_codigo

### ca_rubro_op
- **ca_rubro_op_1** (UNIQUE NONCLUSTERED INDEX): ro_operacion, ro_concepto

### ca_rubro_op_tmp
- **ca_rubro_op_tmp_1** (UNIQUE NONCLUSTERED INDEX): rot_operacion, rot_concepto

### ca_secuencial_atx
- **ca_secuencial_atx_1** (UNIQUE NONCLUSTERED INDEX): sa_secuencial, sa_tipo_secuencial

### ca_tasas
- **ca_tasas_1** (UNIQUE NONCLUSTERED INDEX): ta_operacion, ta_secuencial

### ca_tasas_tmp
- **ca_tasas_tmp_1** (UNIQUE NONCLUSTERED INDEX): tat_operacion, tat_secuencial

### ca_tdividendo
- **ca_tdividendo_1** (UNIQUE NONCLUSTERED INDEX): td_codigo

### ca_tipo_trn
- **ca_tipo_trn_1** (UNIQUE NONCLUSTERED INDEX): tt_codigo

### ca_transaccion
- **ca_transaccion_1** (UNIQUE NONCLUSTERED INDEX): tr_secuencial

### ca_transaccion_prv
- **ca_transaccion_prv_1** (UNIQUE NONCLUSTERED INDEX): tp_secuencial

### ca_traslados_cartera
- **ca_traslados_cartera_1** (UNIQUE NONCLUSTERED INDEX): tc_secuencial

### ca_valor
- **ca_valor_1** (UNIQUE NONCLUSTERED INDEX): va_codigo

### ca_valor_det
- **ca_valor_det_1** (UNIQUE NONCLUSTERED INDEX): vd_codigo, vd_secuencial

### ca_7x24_errores
- **ca_7x24_errores_1** (UNIQUE NONCLUSTERED INDEX): er7_secuencial

### ca_7x24_fcontrol
- **ca_7x24_fcontrol_1** (UNIQUE NONCLUSTERED INDEX): fc_fecha_proceso

### ca_7x24_saldos_prestamos
- **ca_7x24_saldos_prestamos_1** (UNIQUE NONCLUSTERED INDEX): sp_operacion, sp_fecha_saldos

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
