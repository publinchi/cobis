# MANUAL DE USUARIO - DICCIONARIO DE DATOS

## INTRODUCCIÓN

El presente manual técnico COBIS describe las estructuras que permiten operar el Módulo de Crédito, en relación con el proceso de concesión de crédito, el control y aprobación de las etapas de dicha solicitud, o su rechazo, y el seguimiento de los prestamos otorgados y rechazados.

## OBJETIVO

Mostrar el modelo de datos que usa el módulo de Crédito

## ALCANCE

Diccionario de Datos: indica la estructura de cada tabla.

## ÍNDICE DE TABLAS

### Base de Datos cob_credito

#### Tablas Principales

- [cr_asegurados](tablas/cr_asegurados.md) (No se usa en esta versión)
- [cr_cambio_estados](tablas/cr_cambio_estados.md) (No se usa en esta versión)
- [cr_campana](tablas/cr_campana.md) (No se usa en esta versión)
- [cr_campana_toperacion](tablas/cr_campana_toperacion.md) (No se usa en esta versión)
- [cr_cau_tramite](tablas/cr_cau_tramite.md) (Deprecated)
- [cr_cliente_campana](tablas/cr_cliente_campana.md) (No se usa en esta versión)
- [cr_clientes_tmp](tablas/cr_clientes_tmp.md)
- [cr_cobranza](tablas/cr_cobranza.md) (No se usa en esta versión)
- [cr_corresp_sib](tablas/cr_corresp_sib.md) (No se usa en esta versión)
- [cr_costos](tablas/cr_costos.md) (No se usa en esta versión)
- [cr_cotiz3_tmp](tablas/cr_cotiz3_tmp.md)
- [cr_cotizacion](tablas/cr_cotizacion.md) (Deprecated)
- [cr_dato_cliente](tablas/cr_dato_cliente.md) (No se usa en esta versión)
- [cr_dato_garantia](tablas/cr_dato_garantia.md) (No se usa en esta versión)
- [cr_dato_operacion](tablas/cr_dato_operacion.md) (No se usa en esta versión)
- [cr_datos_linea](tablas/cr_datos_linea.md)
- [cr_datos_tramites](tablas/cr_datos_tramites.md) (No se usa en esta versión)
- [cr_def_variables](tablas/cr_def_variables.md) (Deprecated)
- [cr_desembolso](tablas/cr_desembolso.md) (No se usa en esta versión)
- [cr_deud1_tmp](tablas/cr_deud1_tmp.md)
- [cr_deudores](tablas/cr_deudores.md)
- [cr_deudores_tmp](tablas/cr_deudores_tmp.md)
- [cr_documento](tablas/cr_documento.md)
- [cr_errores_sib](tablas/cr_errores_sib.md) (No se usa en esta versión)
- [cr_errorlog](tablas/cr_errorlog.md) (No se usa en esta versión)
- [cr_estacion](tablas/cr_estacion.md) (Deprecated)
- [cr_etapa](tablas/cr_etapa.md) (Deprecated)
- [cr_etapa_estacion](tablas/cr_etapa_estacion.md) (Deprecated)
- [cr_excepciones](tablas/cr_excepciones.md) (Deprecated)
- [cr_excepcion_tramite](tablas/cr_excepcion_tramite.md)
- [cr_facturas](tablas/cr_facturas.md) (No se usa en esta versión)
- [cr_gar_anteriores](tablas/cr_gar_anteriores.md)
- [cr_gar_p_tmp](tablas/cr_gar_p_tmp.md)
- [cr_gar_propuesta](tablas/cr_gar_propuesta.md)
- [cr_gar_tmp](tablas/cr_gar_tmp.md)
- [cr_garantia_gp](tablas/cr_garantia_gp.md) (Deprecated)
- [cr_garantias_gp](tablas/cr_garantias_gp.md) (Deprecated)
- [cr_grupo_castigo](tablas/cr_grupo_castigo.md) (No se usa en esta versión)
- [cr_grupo_tran_castigo](tablas/cr_grupo_tran_castigo.md) (No se usa en esta versión)
- [cr_grupo_tran_castigo_tmp](tablas/cr_grupo_tran_castigo_tmp.md) (No se usa en esta versión)
- [cr_his_calif](tablas/cr_his_calif.md) (No se usa en esta versión)
- [cr_hist_credito](tablas/cr_hist_credito.md) (No se usa en esta versión)
- [cr_imp_documento](tablas/cr_imp_documento.md)
- [cr_instrucciones](tablas/cr_instrucciones.md) (Deprecated)
- [cr_lin_grupo](tablas/cr_lin_grupo.md) (No se usa en esta versión)
- [cr_lin_ope_moneda](tablas/cr_lin_ope_moneda.md)
- [cr_linea](tablas/cr_linea.md)
- [cr_ob_lineas](tablas/cr_ob_lineas.md) (Deprecated)
- [cr_observaciones](tablas/cr_observaciones.md) (Deprecated)
- [cr_observacion_castigo](tablas/cr_observacion_castigo.md) (No se usa en esta versión)
- [cr_observacion_castigo_tmp](tablas/cr_observacion_castigo_tmp.md) (No se usa en esta versión)
- [cr_op_renovar](tablas/cr_op_renovar.md)
- [cr_ope1_tmp](tablas/cr_ope1_tmp.md)
- [cr_operacion_cobranza](tablas/cr_operacion_cobranza.md) (No se usa en esta versión)
- [cr_param_calif](tablas/cr_param_calif.md) (No se usa en esta versión)
- [cr_parametros_linea](tablas/cr_parametros_linea.md)
- [cr_pasos](tablas/cr_pasos.md) (Deprecated)
- [cr_poliza_tmp](tablas/cr_poliza_tmp.md)
- [cr_productos_linea](tablas/cr_productos_linea.md)
- [cr_regla](tablas/cr_regla.md) (Deprecated)
- [cr_req_tramite](tablas/cr_req_tramite.md) (Deprecated)
- [cr_ruta_tramite](tablas/cr_ruta_tramite.md) (Deprecated)
- [cr_secuencia](tablas/cr_secuencia.md) (Deprecated)
- [cr_situacion_cliente](tablas/cr_situacion_cliente.md)
- [cr_situacion_deudas](tablas/cr_situacion_deudas.md)
- [cr_situacion_gar](tablas/cr_situacion_gar.md)
- [cr_situacion_gar_p](tablas/cr_situacion_gar_p.md)
- [cr_situacion_inversiones](tablas/cr_situacion_inversiones.md)
- [cr_situacion_lineas](tablas/cr_situacion_lineas.md)
- [cr_situacion_otras](tablas/cr_situacion_otras.md)
- [cr_soli_rechazadas_tmp](tablas/cr_soli_rechazadas_tmp.md)
- [cr_situacion_poliza](tablas/cr_situacion_poliza.md)
- [cr_temp4_tmp](tablas/cr_temp4_tmp.md) (No se usa en esta versión)
- [cr_tinstruccion](tablas/cr_tinstruccion.md) (Deprecated)
- [cr_tipo_tramite](tablas/cr_tipo_tramite.md)
- [cr_tmp_datooper](tablas/cr_tmp_datooper.md) (No se usa en esta versión)
- [cr_toperacion](tablas/cr_toperacion.md)
- [cr_tr_castigo](tablas/cr_tr_castigo.md) (No se usa en esta versión)
- [cr_tr_datos_adicionales](tablas/cr_tr_datos_adicionales.md) (No se usa en esta versión)
- [cr_tramite](tablas/cr_tramite.md)
- [cr_tramite_grupal](tablas/cr_tramite_grupal.md)
- [cr_truta](tablas/cr_truta.md) (Deprecated)
- [cr_valor_variables](tablas/cr_valor_variables.md) (Deprecated)
- [tmp_garantias](tablas/tmp_garantias.md)
- [xx_tmp](tablas/xx_tmp.md)
- [cr_transaccion_linea](tablas/cr_transaccion_linea.md)
- [cr_det_transaccion_linea](tablas/cr_det_transaccion_linea.md)
- [cr_gasto_linea](tablas/cr_gasto_linea.md)
- [cr_estado_linea](tablas/cr_estado_linea.md)
- [cr_clientes_credautomatico](tablas/cr_clientes_credautomatico.md)
- [cr_clientes_renovacion](tablas/cr_clientes_renovacion.md)
- [cr_segmentacion_cliente](tablas/cr_segmentacion_cliente.md)
- [cr_cobranza_tmp](tablas/cr_cobranza_tmp.md)
- [cr_cobranza_det_tmp](tablas/cr_cobranza_det_tmp.md)
- [cr_pago_solidario](tablas/cr_pago_solidario.md)
- [cr_causa_desercion](tablas/cr_causa_desercion.md)
- [cr_accion_desercion](tablas/cr_accion_desercion.md)
- [cr_buro_credito](tablas/cr_buro_credito.md)
- [cr_cobros](tablas/cr_cobros.md)

### Base de Datos cob_credito_his

- [cr_califica_int_mod_his](tablas/cr_califica_int_mod_his.md) (No se usa en esta versión)
- [cr_ruta_tramite_his](tablas/cr_ruta_tramite_his.md) (No se usa en esta versión)
- [cr_tramite_his](tablas/cr_tramite_his.md) (No se usa en esta versión)

### Base de Datos cob_pac

- [tmp_cliente_grupo](tablas/tmp_cliente_grupo.md)
- [bpl_rule_process_his_cli](tablas/bpl_rule_process_his_cli.md)

---

**Nota:** Para ver el detalle completo de cada tabla, haz clic en el enlace correspondiente.

---

*Si deseas invitarme un café, visita: https://buymeacoffee.com/publinchi4*
