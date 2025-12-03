# Índices de Clave Primaria

Este documento lista todos los índices de clave primaria (Primary Key) de las tablas del módulo de Crédito.

## Base de Datos cob_credito

### Tablas Principales

| Tabla | Nombre del Índice | Campos |
| --- | --- | --- |
| cr_tramite | cr_tramite_Key | tr_tramite |
| cr_linea | cr_linea_Key | li_numero |
| cr_deudores | cr_deudores_Key | de_tramite, de_cliente |
| cr_tramite_grupal | idx1 | tg_tramite, tg_cliente |
| cr_gar_propuesta | cr_gar_propuesta_Key | gp_tramite, gp_garantia |
| cr_documento | cr_documento_Key | do_tramite, do_secuencial |
| cr_excepcion_tramite | cr_excepcion_tramite_Key | et_tramite, et_secuencial |
| cr_imp_documento | cr_imp_documento_Key | id_tramite, id_tipo_documento, id_fecha_impresion |
| cr_datos_linea | cr_datos_linea_Key | dl_linea, dl_parametro |
| cr_lin_ope_moneda | cr_lin_ope_moneda_Key | lom_linea, lom_toperacion, lom_moneda |
| cr_parametros_linea | cr_parametros_linea_Key | pl_linea, pl_parametro |
| cr_productos_linea | cr_productos_linea_Key | prl_linea, prl_producto |
| cr_op_renovar | cr_op_renovar_Key | or_operacion |
| cr_situacion_cliente | cr_situacion_cliente_Key | sc_tramite, sc_ente |
| cr_situacion_deudas | cr_situacion_deudas_Key | sd_tramite, sd_secuencial |
| cr_situacion_gar | cr_situacion_gar_Key | sg_tramite, sg_secuencial |
| cr_situacion_gar_p | cr_situacion_gar_p_Key | sgp_tramite, sgp_secuencial |
| cr_situacion_inversiones | cr_situacion_inversiones_Key | si_tramite, si_secuencial |
| cr_situacion_lineas | cr_situacion_lineas_Key | sl_tramite, sl_secuencial |
| cr_situacion_otras | cr_situacion_otras_Key | so_tramite, so_secuencial |
| cr_situacion_poliza | cr_situacion_poliza_Key | sp_tramite, sp_secuencial |
| cr_tipo_tramite | cr_tipo_tramite_Key | tt_codigo |
| cr_toperacion | cr_toperacion_Key | to_codigo |
| cr_transaccion_linea | cr_transaccion_linea_Key | tl_secuencial |
| cr_det_transaccion_linea | cr_det_transaccion_linea_Key | dtl_secuencial, dtl_secuencial_det |
| cr_gasto_linea | cr_gasto_linea_Key | gl_linea, gl_secuencial |
| cr_estado_linea | cr_estado_linea_Key | el_codigo |
| cr_clientes_credautomatico | cr_clientes_credautomatico_Key | cca_cliente |
| cr_clientes_renovacion | cr_clientes_renovacion_Key | crn_cliente, crn_operacion_anterior |
| cr_segmentacion_cliente | cr_segmentacion_cliente_Key | sgc_cliente, sgc_fecha_segmentacion |
| cr_pago_solidario | cr_pago_solidario_Key | ps_secuencial |
| cr_causa_desercion | cr_causa_desercion_Key | cd_codigo |
| cr_accion_desercion | cr_accion_desercion_Key | ad_secuencial |
| cr_buro_credito | cr_buro_credito_Key | bc_secuencial |
| cr_cobros | cr_cobros_Key | co_secuencial |

### Tablas Temporales

| Tabla | Nombre del Índice | Campos |
| --- | --- | --- |
| cr_clientes_tmp | tmp_cliente_idx | tmp_cliente |
| cr_cotiz3_tmp | tmp_tramite_idx | tmp_tramite, tmp_secuencial |
| cr_deud1_tmp | tmp_tramite_idx | tmp_tramite, tmp_cliente |
| cr_deudores_tmp | tmp_tramite_cliente_idx | tmp_tramite, tmp_cliente |
| cr_gar_p_tmp | tmp_tramite_garantia_idx | tmp_tramite, tmp_garantia |
| cr_gar_tmp | tmp_tramite_idx | tmp_tramite, tmp_secuencial |
| cr_poliza_tmp | tmp_tramite_poliza_idx | tmp_tramite, tmp_numero_poliza |
| cr_soli_rechazadas_tmp | tmp_tramite_idx | tmp_tramite |
| cr_ope1_tmp | tmp_operacion_idx | tmp_operacion |
| tmp_garantias | tmp_tramite_garantia_idx | tmp_tramite, tmp_garantia |
| cr_cobranza_tmp | tmp_operacion_idx | tmp_operacion |
| cr_cobranza_det_tmp | tmp_operacion_secuencial_idx | tmp_operacion, tmp_secuencial |

## Base de Datos cob_pac

| Tabla | Nombre del Índice | Campos |
| --- | --- | --- |
| tmp_cliente_grupo | tmp_cliente_idx | tmp_cliente |
| bpl_rule_process_his_cli | bpl_rule_process_his_cli_Key | brp_secuencial |

## Notas

- Las claves primarias garantizan la unicidad de los registros en cada tabla.
- Los índices de clave primaria se crean automáticamente al definir la restricción PRIMARY KEY.
- Estos índices son fundamentales para el rendimiento de las consultas y la integridad referencial.

---

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
