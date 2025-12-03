# Índices de Clave Foránea

Este documento lista todos los índices de clave foránea (Foreign Key) de las tablas del módulo de Crédito y sus relaciones con otras tablas.

## Base de Datos cob_credito

### Tabla: cr_tramite

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| tr_oficina | cl_oficina | of_oficina | Oficina del trámite |
| tr_usuario | cl_funcionario | fu_login | Usuario que crea el trámite |
| tr_usuario_apr | cl_funcionario | fu_login | Usuario que aprueba |
| tr_oficial | cl_funcionario | fu_funcionario | Oficial de crédito |
| tr_sector | cc_sector | se_sector | Sector económico |
| tr_ciudad | cl_ciudad | ci_ciudad | Ciudad |
| tr_cliente | cl_ente | en_ente | Cliente deudor |
| tr_grupo | cl_grupo | gr_grupo | Grupo (si aplica) |
| tr_moneda | cl_moneda | mo_moneda | Moneda |
| tr_periodo | ca_tdividendo | td_tdividendo | Tipo de dividendo |
| tr_destino | cr_objeto | ob_objeto | Destino del crédito |
| tr_ciudad_destino | cl_ciudad | ci_ciudad | Ciudad destino |
| tr_toperacion | cr_toperacion | to_codigo | Tipo de operación |
| tr_provincia | cl_provincia | pv_provincia | Provincia |
| tr_frec_pago | ca_tdividendo | td_tdividendo | Frecuencia de pago |
| tr_moneda_solicitada | cl_moneda | mo_moneda | Moneda solicitada |
| tr_origen_fondos | cr_origen_fondo | of_codigo | Origen de fondos |
| tr_enterado | cl_enterado | en_codigo | Cómo se enteró |

### Tabla: cr_linea

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| li_oficina | cl_oficina | of_oficina | Oficina de la línea |
| li_tramite | cr_tramite | tr_tramite | Trámite origen |
| li_cliente | cl_ente | en_ente | Cliente titular |
| li_grupo | cl_grupo | gr_grupo | Grupo (si aplica) |
| li_moneda | cl_moneda | mo_moneda | Moneda de la línea |

### Tabla: cr_deudores

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| de_tramite | cr_tramite | tr_tramite | Trámite |
| de_cliente | cl_ente | en_ente | Cliente deudor/codeudor |

### Tabla: cr_tramite_grupal

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| tg_tramite | cr_tramite | tr_tramite | Trámite grupal |
| tg_grupo | cl_grupo | gr_grupo | Grupo |
| tg_cliente | cl_ente | en_ente | Cliente integrante |
| tg_destino | cl_subactividad_ec | sa_subactividad | Destino del crédito |
| tg_id_rechazo | cr_motivo_rechazo | mr_codigo | Motivo de rechazo |

### Tabla: cr_gar_propuesta

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| gp_tramite | cr_tramite | tr_tramite | Trámite |
| gp_garantia | cu_custodia | cu_codigo_externo | Garantía en custodia |
| gp_deudor | cl_ente | en_ente | Cliente deudor |

### Tabla: cr_documento

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| do_tramite | cr_tramite | tr_tramite | Trámite |
| do_tipo_documento | cl_tabla | codigo | Tipo de documento |
| do_usuario_recepcion | cl_funcionario | fu_login | Usuario que recibe |

### Tabla: cr_excepcion_tramite

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| et_tramite | cr_tramite | tr_tramite | Trámite |
| et_tipo_excepcion | cl_tabla | codigo | Tipo de excepción |
| et_usuario_solicita | cl_funcionario | fu_login | Usuario solicitante |
| et_usuario_aprueba | cl_funcionario | fu_login | Usuario aprobador |

### Tabla: cr_imp_documento

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| id_tramite | cr_tramite | tr_tramite | Trámite |
| id_usuario | cl_funcionario | fu_login | Usuario que imprime |

### Tabla: cr_datos_linea

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| dl_linea | cr_linea | li_numero | Línea de crédito |

### Tabla: cr_lin_ope_moneda

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| lom_linea | cr_linea | li_numero | Línea de crédito |
| lom_toperacion | cr_toperacion | to_codigo | Tipo de operación |
| lom_moneda | cl_moneda | mo_moneda | Moneda |

### Tabla: cr_parametros_linea

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| pl_linea | cr_linea | li_numero | Línea de crédito |

### Tabla: cr_productos_linea

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| prl_linea | cr_linea | li_numero | Línea de crédito |

### Tabla: cr_op_renovar

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| or_operacion | ca_operacion | op_operacion | Operación de cartera |
| or_cliente | cl_ente | en_ente | Cliente |
| or_tramite_renovacion | cr_tramite | tr_tramite | Trámite de renovación |

### Tabla: cr_situacion_cliente

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| sc_tramite | cr_tramite | tr_tramite | Trámite |
| sc_ente | cl_ente | en_ente | Cliente |

### Tabla: cr_situacion_deudas

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| sd_tramite | cr_tramite | tr_tramite | Trámite |
| sd_ente | cl_ente | en_ente | Cliente |

### Tabla: cr_situacion_gar

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| sg_tramite | cr_tramite | tr_tramite | Trámite |

### Tabla: cr_situacion_gar_p

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| sgp_tramite | cr_tramite | tr_tramite | Trámite |

### Tabla: cr_situacion_inversiones

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| si_tramite | cr_tramite | tr_tramite | Trámite |
| si_ente | cl_ente | en_ente | Cliente |

### Tabla: cr_situacion_lineas

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| sl_tramite | cr_tramite | tr_tramite | Trámite |
| sl_ente | cl_ente | en_ente | Cliente |

### Tabla: cr_situacion_otras

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| so_tramite | cr_tramite | tr_tramite | Trámite |
| so_ente | cl_ente | en_ente | Cliente |

### Tabla: cr_situacion_poliza

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| sp_tramite | cr_tramite | tr_tramite | Trámite |

### Tabla: cr_transaccion_linea

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| tl_linea | cr_linea | li_numero | Línea de crédito |
| tl_operacion | ca_operacion | op_operacion | Operación relacionada |
| tl_usuario | cl_funcionario | fu_login | Usuario |
| tl_oficina | cl_oficina | of_oficina | Oficina |

### Tabla: cr_det_transaccion_linea

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| dtl_secuencial | cr_transaccion_linea | tl_secuencial | Transacción de línea |

### Tabla: cr_gasto_linea

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| gl_linea | cr_linea | li_numero | Línea de crédito |
| gl_usuario | cl_funcionario | fu_login | Usuario |

### Tabla: cr_clientes_credautomatico

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| cca_cliente | cl_ente | en_ente | Cliente |

### Tabla: cr_clientes_renovacion

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| crn_cliente | cl_ente | en_ente | Cliente |
| crn_operacion_anterior | ca_operacion | op_operacion | Operación anterior |

### Tabla: cr_segmentacion_cliente

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| sgc_cliente | cl_ente | en_ente | Cliente |
| sgc_usuario | cl_funcionario | fu_login | Usuario |

### Tabla: cr_pago_solidario

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| ps_operacion_deudor | ca_operacion | op_operacion | Operación del deudor |
| ps_cliente_deudor | cl_ente | en_ente | Cliente deudor |
| ps_operacion_pagador | ca_operacion | op_operacion | Operación del pagador |
| ps_cliente_pagador | cl_ente | en_ente | Cliente pagador |
| ps_usuario | cl_funcionario | fu_login | Usuario |

### Tabla: cr_accion_desercion

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| ad_cliente | cl_ente | en_ente | Cliente |
| ad_causa_desercion | cr_causa_desercion | cd_codigo | Causa de deserción |
| ad_usuario | cl_funcionario | fu_login | Usuario |

### Tabla: cr_buro_credito

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| bc_tramite | cr_tramite | tr_tramite | Trámite |
| bc_cliente | cl_ente | en_ente | Cliente |
| bc_usuario | cl_funcionario | fu_login | Usuario |

### Tabla: cr_cobros

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| co_operacion | ca_operacion | op_operacion | Operación |
| co_cliente | cl_ente | en_ente | Cliente |
| co_usuario | cl_funcionario | fu_login | Usuario |

## Base de Datos cob_pac

### Tabla: tmp_cliente_grupo

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| tmp_cliente | cl_ente | en_ente | Cliente |
| tmp_grupo | cl_grupo | gr_grupo | Grupo |

### Tabla: bpl_rule_process_his_cli

| Campo | Tabla Referenciada | Campo Referenciado | Descripción |
| --- | --- | --- | --- |
| brp_cliente | cl_ente | en_ente | Cliente |
| brp_usuario | cl_funcionario | fu_login | Usuario |

## Notas sobre Integridad Referencial

- Las claves foráneas garantizan la integridad referencial entre tablas relacionadas.
- Previenen la inserción de registros huérfanos (sin padre en la tabla referenciada).
- Facilitan las operaciones de JOIN en consultas SQL.
- Algunos campos pueden tener restricciones ON DELETE CASCADE o ON DELETE RESTRICT según la lógica del negocio.

## Convenciones de Nomenclatura

- **cl_**: Tablas del módulo de Clientes
- **ca_**: Tablas del módulo de Cartera
- **cr_**: Tablas del módulo de Crédito
- **cu_**: Tablas del módulo de Custodia
- **cc_**: Tablas de Catálogos Comunes

---

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
