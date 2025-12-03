# Índices por Clave Foránea

Este documento lista todos los índices de clave foránea y otros índices secundarios de las tablas del módulo de cartera COBIS.

## Tablas cob_cartera

### ca_abono
- **ca_abono_3** (NONCLUSTERED INDEX): ab_secuencial_pag
- **ca_abono_4** (NONCLUSTERED INDEX): ab_estado
- **ca_abono_5** (NONCLUSTERED INDEX): ab_fecha_pag
- **ca_abono_idx6** (NONCLUSTERED INDEX): ab_secuencial_rpa, ab_secuencial_ing, ab_operacion, ab_fecha_ing

### ca_abono_grupal_tmp
- **ca_abono_grupal_tmp_2** (NONCLUSTERED INDEX): agt_grupo
- **ca_abono_grupal_tmp_3** (NONCLUSTERED INDEX): agt_operacion_padre

### ca_amortizacion
- **ca_amortizacion_2** (NONCLUSTERED INDEX): am_estado

### ca_archivo_pagos_1
- **ca_archivo_pagos_1_2** (NONCLUSTERED INDEX): ap_lote
- **ca_archivo_pagos_1_3** (NONCLUSTERED INDEX): ap_operacion
- **ca_archivo_pagos_1_4** (NONCLUSTERED INDEX): ap_secuencial_pago

### ca_archivo_pagos_1_tmp
- **ca_archivo_pagos_1_tmp_2** (NONCLUSTERED INDEX): apt_lote
- **ca_archivo_pagos_1_tmp_3** (NONCLUSTERED INDEX): apt_estado

### ca_batch_pagos_corresponsal
- **ca_batch_pagos_corresponsal_2** (NONCLUSTERED INDEX): bpc_fecha_proceso
- **ca_batch_pagos_corresponsal_3** (NONCLUSTERED INDEX): bpc_corresponsal
- **ca_batch_pagos_corresponsal_4** (NONCLUSTERED INDEX): bpc_estado

### ca_cambio_estado_masivo
- **ca_cambio_estado_masivo_2** (NONCLUSTERED INDEX): cem_fecha_proceso
- **ca_cambio_estado_masivo_3** (NONCLUSTERED INDEX): cem_estado

### ca_desembolso
- **ca_desembolso_2** (NONCLUSTERED INDEX): de_fecha_desembolso
- **ca_desembolso_3** (NONCLUSTERED INDEX): de_estado

### ca_det_ciclo
- **ca_det_ciclo_2** (NONCLUSTERED INDEX): dc_cliente

### ca_det_trn
- **ca_det_trn_1** (NONCLUSTERED INDEX): dtr_secuencial, dtr_operacion, dtr_dividendo, dtr_concepto
- **ca_det_trn_2** (NONCLUSTERED INDEX): dtr_operacion

### ca_dividendo
- **ca_dividendo_2** (NONCLUSTERED INDEX): di_estado
- **ca_dividendo_3** (NONCLUSTERED INDEX): di_fecha_ven

### ca_dividendo_his
- **ca_dividendo_his_1** (NONCLUSTERED INDEX): dih_operacion, dih_dividendo, dih_secuencial

### ca_amortizacion_his
- **ca_amortizacion_his_1** (NONCLUSTERED INDEX): amh_operacion, amh_dividendo, amh_concepto, amh_secuencial

### ca_en_fecha_valor
- **ca_en_fecha_valor_2** (NONCLUSTERED INDEX): efv_toperacion, efv_estado

### ca_en_fecha_valor_grupal
- **ca_en_fecha_valor_grupal_2** (NONCLUSTERED INDEX): efvg_toperacion, efvg_estado

### ca_errorlog
- **ca_errorlog_2** (NONCLUSTERED INDEX): er_fecha_proceso
- **ca_errorlog_3** (NONCLUSTERED INDEX): er_operacion
- **ca_errorlog_4** (NONCLUSTERED INDEX): er_estado

### ca_errores_ope_masivas
- **ca_errores_ope_masivas_2** (NONCLUSTERED INDEX): eom_lote
- **ca_errores_ope_masivas_3** (NONCLUSTERED INDEX): eom_fecha_proceso
- **ca_errores_ope_masivas_4** (NONCLUSTERED INDEX): eom_estado

### ca_incentivos_detalle_operaciones
- **ca_incentivos_detalle_operaciones_2** (NONCLUSTERED INDEX): ido_periodo, ido_oficial
- **ca_incentivos_detalle_operaciones_3** (NONCLUSTERED INDEX): ido_operacion

### ca_incentivos_metas
- **ca_incentivos_metas_2** (NONCLUSTERED INDEX): im_periodo, im_estado
- **ca_incentivos_metas_3** (NONCLUSTERED INDEX): im_oficial

### ca_incentivos_obtencion_indicadores
- **ca_incentivos_obtencion_indicadores_2** (NONCLUSTERED INDEX): ioi_periodo, ioi_oficial
- **ca_incentivos_obtencion_indicadores_3** (NONCLUSTERED INDEX): ioi_estado

### ca_log_fecha_valor_grupal
- **ca_log_fecha_valor_grupal_1** (UNIQUE NONCLUSTERED INDEX): lfvg_secuencial
- **ca_log_fecha_valor_grupal_2** (NONCLUSTERED INDEX): lfvg_fecha
- **ca_log_fecha_valor_grupal_3** (NONCLUSTERED INDEX): lfvg_operacion

### ca_operacion
- **ca_operacion_2** (NONCLUSTERED INDEX): op_migrada
- **ca_operacion_3** (NONCLUSTERED INDEX): op_tramite
- **ca_operacion_4** (NONCLUSTERED INDEX): op_cliente
- **ca_operacion_5** (NONCLUSTERED INDEX): op_oficial
- **ca_operacion_6** (NONCLUSTERED INDEX): op_oficina
- **ca_operacion_7** (NONCLUSTERED INDEX): op_banco
- **ca_operacion_8** (NONCLUSTERED INDEX): op_lin_credito
- **ca_operacion_9** (NONCLUSTERED INDEX): op_estado, op_fecha_liq, op_tramite, op_oficial
- **ca_operacion_10** (NONCLUSTERED INDEX): op_oficial, op_tramite, op_cliente, op_estado
- **ca_operacion_idx11** (NONCLUSTERED INDEX): op_naturaleza, op_fecha_ult_proceso, op_cuenta, op_operacion, op_estado, op_forma_pago

### ca_operacion_his
- **ca_operacion_his_1** (NONCLUSTERED INDEX): oph_operacion, oph_secuencial
- **ca_operacion_his_2** (NONCLUSTERED INDEX): oph_fecha

### ca_otro_cargo
- **ca_otro_cargo_2** (NONCLUSTERED INDEX): oc_estado

### ca_param_cargos_gestion_cobranza
- **ca_param_cargos_gestion_cobranza_2** (NONCLUSTERED INDEX): pcgc_toperacion, pcgc_estado

### ca_pin_odp
- **ca_pin_odp_2** (NONCLUSTERED INDEX): po_pin
- **ca_pin_odp_3** (NONCLUSTERED INDEX): po_estado
- **ca_pin_odp_4** (NONCLUSTERED INDEX): po_fecha_vencimiento

### ca_provision_cartera
- **ca_provision_cartera_2** (NONCLUSTERED INDEX): pc_fecha_proceso

### ca_qr_transacciones_tmp
- **ca_qr_transacciones_tmp_2** (NONCLUSTERED INDEX): qrt_codigo_qr
- **ca_qr_transacciones_tmp_3** (NONCLUSTERED INDEX): qrt_operacion
- **ca_qr_transacciones_tmp_4** (NONCLUSTERED INDEX): qrt_estado

### ca_reajuste
- **ca_reajuste_2** (NONCLUSTERED INDEX): re_fecha_reajuste

### ca_registra_traslados_masivos
- **ca_registra_traslados_masivos_2** (NONCLUSTERED INDEX): rtm_fecha_proceso

### ca_rubro_op_his
- **ca_rubro_op_his_1** (NONCLUSTERED INDEX): roh_operacion, roh_concepto, roh_secuencial

### ca_secuencial_atx
- **ca_secuencial_atx_2** (NONCLUSTERED INDEX): sa_secuencial_relacionado, sa_tipo_relacionado
- **ca_secuencial_atx_3** (NONCLUSTERED INDEX): sa_operacion

### ca_tasas
- **ca_tasas_2** (NONCLUSTERED INDEX): ta_fecha_vigencia
- **ca_tasas_3** (NONCLUSTERED INDEX): ta_estado

### ca_transaccion
- **ca_transaccion_2** (NONCLUSTERED INDEX): tr_operacion
- **ca_transaccion_3** (NONCLUSTERED INDEX): tr_fecha_mov
- **ca_transaccion_4** (NONCLUSTERED INDEX): tr_estado
- **ca_transaccion_5** (NONCLUSTERED INDEX): tr_secuencial_ref

### ca_transaccion_prv
- **ca_transaccion_prv_2** (NONCLUSTERED INDEX): tp_operacion
- **ca_transaccion_prv_3** (NONCLUSTERED INDEX): tp_fecha_proceso

### ca_traslados_cartera
- **ca_traslados_cartera_2** (NONCLUSTERED INDEX): tc_operacion
- **ca_traslados_cartera_3** (NONCLUSTERED INDEX): tc_fecha_traslado
- **ca_traslados_cartera_4** (NONCLUSTERED INDEX): tc_secuencial_masivo

### ca_valor
- **ca_valor_2** (NONCLUSTERED INDEX): va_toperacion, va_estado

### ca_valor_det
- **ca_valor_det_2** (NONCLUSTERED INDEX): vd_fecha_vigencia
- **ca_valor_det_3** (NONCLUSTERED INDEX): vd_estado

### ca_7x24_errores
- **ca_7x24_errores_2** (NONCLUSTERED INDEX): er7_fecha
- **ca_7x24_errores_3** (NONCLUSTERED INDEX): er7_operacion
- **ca_7x24_errores_4** (NONCLUSTERED INDEX): er7_estado

### ca_7x24_saldos_prestamos
- **ca_7x24_saldos_prestamos_2** (NONCLUSTERED INDEX): sp_banco
- **ca_7x24_saldos_prestamos_3** (NONCLUSTERED INDEX): sp_cliente
- **ca_7x24_saldos_prestamos_4** (NONCLUSTERED INDEX): sp_fecha_saldos

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
