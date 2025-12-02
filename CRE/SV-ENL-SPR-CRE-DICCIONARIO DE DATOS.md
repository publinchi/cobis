MANUAL DE USUARIO

DICCIONARIO DE DATOS

COBIS - PMO

Historia de Cambios

| Versión | Fecha | Autor | Revisado | Aprobado | Descripción |
| --- | --- | --- | --- | --- | --- |
| 1.0.0 | 01-Jun-2021 | JMI | PQU | MDA | Emisión inicial |
| 1.0.1 | 15-Dic-2021 | COB | PQU |     | Inclusión tablas |
| 1.0.2 | 23-Jun-2022 | BDU | PQU |     | Inclusión campos en cr_tramite_grupal |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |

© 2023 Cobiscorp

RESERVADOS TODOS LOS DERECHOS

La información que Cobiscorp proporciona a través de este documento tienen el carácter de referencial y/o informativo, por lo que Cobiscorp podría modificar esta información en cualquier momento y sin previo aviso.

Es responsabilidad del tenor de este documento el cumplimiento de todas las leyes de derechos de autor aplicables. Sin que por ello queden limitados los derechos de autor, ninguna parte de este documento puede ser reproducida, almacenada o introducida en un sistema de recuperación, o transmitida de ninguna forma, ni por ningún medio (ya sea electrónico, mecánico, por fotocopia, grabación o de otra manera) con ningún propósito, sin la previa autorización por escrito de Cobiscorp.

Cobiscorp puede ser titular de patentes, solicitudes de patentes, marcas, derechos de autor, y otros derechos de propiedad intelectual sobre los contenidos de este documento. El suministro de este documento no le otorga ninguna licencia sobre estas patentes, marcas, derechos de autor, u otros derechos de propiedad intelectual, a menos que ello se prevea en un contrato por escrito de licencia de Cobiscorp.

Cobiscorp, COBIS y Cooperative Open Banking Information System son marcas registradas de Cobiscorp.

Otros nombres de compañías y productos mencionados en este documento, pueden ser marcas comerciales o marcas registradas por sus respectivos propietarios.

Tabla de Contenido

[1\. INTRODUCCIÓN 6](#_Toc133918127)

[2\. OBJETIVO 7](#_Toc133918128)

[3\. ALCANCE 7](#_Toc133918129)

[4\. definiciones 7](#_Toc133918130)

[5\. DICCIONARIO DE DATOS 7](#_Toc133918131)

[5.1. Detalle de Estructuras de Datos 8](#_Toc133918132)

[5.1.1. cr_asegurados (No se usa en esta versión) 8](#_Toc133918133)

[5.1.2. cr_cambio_estados (No se usa en esta versión) 9](#_Toc133918134)

[5.1.3. cr_campana (No se usa en esta versión) 9](#_Toc133918135)

[5.1.4. cr_campana_toperacion (No se usa en esta versión) 10](#_Toc133918136)

[5.1.5. cr_cau_tramite (Deprecated) 10](#_Toc133918137)

[5.1.6. cr_cliente_campana (No se usa en esta versión) 10](#_Toc133918138)

[5.1.7. cr_clientes_tmp 11](#_Toc133918139)

[5.1.8. cr_cobranza (No se usa en esta versión) 11](#_Toc133918140)

[5.1.9. cr_corresp_sib (No se usa en esta versión) 12](#_Toc133918141)

[5.1.10. cr_costos (No se usa en esta versión) 13](#_Toc133918142)

[5.1.11. cr_cotiz3_tmp 13](#_Toc133918143)

[5.1.12. cr_cotizacion (Deprecated) 14](#_Toc133918144)

[5.1.13. cr_dato_cliente (No se usa en esta versión) 14](#_Toc133918145)

[5.1.14. cr_dato_garantia (No se usa en esta versión) 15](#_Toc133918146)

[5.1.15. cr_dato_operacion (No se usa en esta versión) 16](#_Toc133918147)

[5.1.16. cr_datos_linea 19](#_Toc133918148)

[5.1.17. cr_datos_tramites (No se usa en esta versión) 19](#_Toc133918149)

[5.1.18. cr_def_variables (Deprecated) 19](#_Toc133918150)

[5.1.19. cr_desembolso (No se usa en esta versión) 20](#_Toc133918151)

[5.1.20. cr_deud1_tmp 20](#_Toc133918152)

[5.1.21. cr_deudores 22](#_Toc133918153)

[5.1.22. cr_deudores_tmp 23](#_Toc133918154)

[5.1.23. cr_documento 23](#_Toc133918155)

[5.1.24. cr_errores_sib (No se usa en esta versión) 23](#_Toc133918156)

[5.1.25. cr_errorlog (No se usa en esta versión) 24](#_Toc133918157)

[5.1.26. cr_estacion (Deprecated) 24](#_Toc133918158)

[5.1.27. cr_etapa (Deprecated) 25](#_Toc133918159)

[5.1.28. cr_etapa_estacion (Deprecated) 25](#_Toc133918160)

[5.1.29. cr_excepciones (Deprecated) 26](#_Toc133918161)

[5.1.30. cr_excepcion_tramite 27](#_Toc133918162)

[5.1.31. cr_facturas (No se usa en esta versión) 27](#_Toc133918163)

[5.1.32. cr_gar_anteriores 28](#_Toc133918164)

[5.1.33. cr_gar_p_tmp 29](#_Toc133918165)

[5.1.34. cr_gar_propuesta 30](#_Toc133918166)

[5.1.35. cr_gar_tmp 30](#_Toc133918167)

[5.1.36. cr_garantia_gp (Deprecated) 31](#_Toc133918168)

[5.1.37. cr_garantias_gp (Deprecated) 32](#_Toc133918169)

[5.1.38. cr_grupo_castigo (No se usa en esta versión) 32](#_Toc133918170)

[5.1.39. cr_grupo_tran_castigo (No se usa en esta versión) 33](#_Toc133918171)

[5.1.40. cr_grupo_tran_castigo_tmp (No se usa en esta versión) 33](#_Toc133918172)

[5.1.41. cr_his_calif (No se usa en esta versión) 34](#_Toc133918173)

[5.1.42. cr_hist_credito (No se usa en esta versión) 34](#_Toc133918174)

[5.1.43. cr_imp_documento 35](#_Toc133918175)

[5.1.44. cr_instrucciones (Deprecated) 36](#_Toc133918176)

[5.1.45. cr_lin_grupo (No se usa en esta versión) 37](#_Toc133918177)

[5.1.46. cr_lin_ope_moneda 37](#_Toc133918178)

[5.1.47. cr_linea 38](#_Toc133918179)

[5.1.48. cr_ob_lineas (Deprecated) 40](#_Toc133918180)

[5.1.49. cr_observaciones (Deprecated) 40](#_Toc133918181)

[5.1.50. cr_observacion_castigo (No se usa en esta versión) 41](#_Toc133918182)

[5.1.51. cr_observacion_castigo_tmp (No se usa en esta versión) 41](#_Toc133918183)

[5.1.52. cr_op_renovar 41](#_Toc133918184)

[5.1.53. cr_ope1_tmp 43](#_Toc133918185)

[5.1.54. cr_operacion_cobranza (No se usa en esta versión) 44](#_Toc133918186)

[5.1.55. cr_param_calif (No se usa en esta versión) 44](#_Toc133918187)

[5.1.56. cr_parametros_linea 45](#_Toc133918188)

[5.1.57. cr_pasos (Deprecated) 45](#_Toc133918189)

[5.1.58. cr_poliza_tmp 46](#_Toc133918190)

[5.1.59. cr_productos_linea 47](#_Toc133918191)

[5.1.60. cr_regla (Deprecated) 47](#_Toc133918192)

[5.1.61. cr_req_tramite (Deprecated) 48](#_Toc133918193)

[5.1.62. cr_ruta_tramite (Deprecated) 48](#_Toc133918194)

[5.1.63. cr_secuencia (Deprecated) 49](#_Toc133918195)

[5.1.64. cr_situacion_cliente 49](#_Toc133918196)

[5.1.65. cr_situacion_deudas 50](#_Toc133918197)

[5.1.66. cr_situacion_gar 52](#_Toc133918198)

[5.1.67. cr_situacion_gar_p 53](#_Toc133918199)

[5.1.68. cr_situacion_inversiones 54](#_Toc133918200)

[5.1.69. cr_situacion_lineas 56](#_Toc133918201)

[5.1.70. cr_situacion_otras 57](#_Toc133918202)

[5.1.71. cr_soli_rechazadas_tmp 59](#_Toc133918203)

[5.1.72. cr_situacion_poliza 59](#_Toc133918204)

[5.1.73. cr_temp4_tmp (No se usa en esta versión) 60](#_Toc133918205)

[5.1.74. cr_tinstruccion (Deprecated) 62](#_Toc133918206)

[5.1.75. cr_tipo_tramite 62](#_Toc133918207)

[5.1.76. cr_tmp_datooper (No se usa en esta versión) 62](#_Toc133918208)

[5.1.77. cr_toperacion 66](#_Toc133918209)

[5.1.78. cr_tr_castigo (No se usa en esta versión) 66](#_Toc133918210)

[5.1.79. cr_tr_datos_adicionales (No se usa en esta versión) 67](#_Toc133918211)

[5.1.80. cr_tramite 69](#_Toc133918212)

[5.1.81. cr_tramite_grupal 77](#_Toc133918213)

[5.1.82. cr_truta (Deprecated) 78](#_Toc133918214)

[5.1.83. cr_valor_variables (Deprecated) 78](#_Toc133918215)

[5.1.84. tmp_garantias 79](#_Toc133918216)

[5.1.85. xx_tmp 79](#_Toc133918217)

[5.1.86. cr_transaccion_linea 79](#_Toc133918218)

[5.1.87. cr_det_transaccion_linea 80](#_Toc133918219)

[5.1.88. cr_gasto_linea 81](#_Toc133918220)

[5.1.89. cr_estado_linea 81](#_Toc133918221)

[5.1.90. cr_clientes_credautomatico 82](#_Toc133918222)

[5.1.91. cr_clientes_renovacion 82](#_Toc133918223)

[5.1.92. cr_segmentacion_cliente 82](#_Toc133918224)

[5.1.93. cr_cobranza_tmp 83](#_Toc133918225)

[5.1.94. cr_cobranza_det_tmp 83](#_Toc133918226)

[5.1.95. cr_pago_solidario 84](#_Toc133918227)

[5.1.96. cr_causa_desercion 84](#_Toc133918228)

[5.1.97. cr_accion_desercion 85](#_Toc133918229)

[5.1.98. cr_buro_credito 85](#_Toc133918230)

[5.1.99. cr_cobros 86](#_Toc133918231)

[5.2. Tablas de la base cob_credito_his 87](#_Toc133918232)

[5.2.1. cr_califica_int_mod_his (No se usa en esta versión) 87](#_Toc133918233)

[5.2.2. cr_ruta_tramite (No se usa en esta versión) 87](#_Toc133918234)

[5.2.3. cr_tramite_his (No se usa en esta versión) 87](#_Toc133918235)

[5.3. Vistas y Transacciones de Servicios 87](#_Toc133918236)

[5.3.1. Transacciones de servicio 87](#_Toc133918237)

[5.3.2. Vistas 90](#_Toc133918238)

[5.4. Índices 125](#_Toc133918239)

[5.5. TABLAS DE LA BASE COB_PAC 132](#_Toc133918240)

[5.5.1. tmp_cliente_grupo 132](#_Toc133918241)

[5.5.2. bpl_rule_process_his_cli 132](#_Toc133918242)

[5.6. INDICES DE LA BASE COB_PAC 133](#_Toc133918243)

Lista de Tablas y Figuras

**No table of figures entries found.**

**No table of figures entries found.**

MANUAL DE USUARIO

POLÍTICAS Y REGLAS DE NEGOCIO

EDITOR POLÍTICAS

# INTRODUCCIÓN

El presente manual técnico COBIS describe las estructuras que permiten operar el Módulo de Crédito, en relación con el proceso de concesión de crédito, el control y aprobación de las etapas de dicha solicitud, o su rechazo, y el seguimiento de los prestamos otorgados y rechazados.

Cobis presenta el Módulo de Crédito con un esquema moderno, para que la tecnología asuma el esfuerzo mecánico, y contribuya con elementos de información para dar el soporte a los ejecutivos de la entidad financiera para que realicen una gestión más bien relacionada al servicio del Cliente, y a la administración eficiente del riesgo.

Por otra parte, interactúa con los siguientes módulos COBIS

- Cartera.
- Garantías.
- Plazo Fijo.
- Clientes.
- Cuentas de Ahorros.
- Cuentas Corrientes.
- Comercio Exterior
- XSell

Dentro de la funcionalidad del módulo, es válido destacar los siguientes aspectos:

- Proporciona un medio de aprobación electrónico, que registra los datos generados durante el proceso de aprobación. (Actualmente embebido en el módulo de XSell, originación de créditos)
- Para la toma de decisiones durante la aprobación proporciona un conjunto de consultas que permiten analizar al cliente a través de la información almacenada en otros módulos como son ahorro, créditos, garantías. (Actualmente embebido en el módulo de XSell, Vista Consolidada)
- Proceso de cobro de créditos impagos. (si se posee COBIS Módulo de Cobranzas)
- Regularización de excepciones dadas durante la aprobación de créditos. (Actualmente embebido en el módulo de XSell, originación de créditos)
- Consultas. (Actualmente embebido en el módulo de XSell, originación de créditos)

El módulo COBIS-CREDITO está formado por las siguientes unidades funcionales

- Administrador. (COBIS Admin)
- Mantenimiento a los Parámetros del Módulo de Crédito. (COBIS Admin)
- Administración y Control de Rutas. (COBIS XSell, Worflow)
- Trámites de Crédito. (COBIS XSell, Procesos de negocio)
- Este módulo permite realizar el ruteo de trámites de crédito, para aprobar los mismos. (COBIS XSell, Procesos de negocio)
- Gestión de Crédito. (COBIS XSell, Vista Consolidada)
- Cobranzas de Créditos.(COBIS Cobranzas)
- Consulta para toma de decisiones. (COBIS XSell)

# OBJETIVO

Mostrar el modelo de datos que usa el módulo de Crédito

# ALCANCE

Diccionario de Datos: indica la estructura de cada tabla.

Vistas y Transacciones de Servicio: En esta parte del manual se indica las tablas para el registro de transacciones, de las cuales se necesita información como: qué usuario realizó la transacción, en qué fecha y hora, desde qué y en qué servidor, código de identificación de la transacción, los datos de la transacción, etc. Además, contiene las Vistas que intervienen en el módulo para consultas de Distribución Geográfica.

Índices por Clave Primaria: Descripción de índices por clave primaria para cada una de las tablas creadas.

Indices por Clave Foránea

# definiciones

No aplica

# DICCIONARIO DE DATOS

En este capítulo se presenta una descripción de las tablas con sus respectivos campos señalando su tipo de dato, longitud, descripción de uso, etc. de todas las tablas del Módulo de Crédito.

## Detalle de Estructuras de Datos

### cr_asegurados (No se usa en esta versión)

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| as_secuencial_seguro | int |     |     |     |     |
| as_sec_asegurado | int |     |     |     |     |
| as_tipo_aseg | int |     |     |     |     |
| as_apellidos | varchar(255) | 255 |     |     |     |
| as_nombres | varchar(255) | 255 |     |     |     |
| as_tipo_ced | varchar(10) | 10  |     |     |     |
| as_ced_ruc | varchar(30) | 30  |     |     |     |
| as_lugar_exp | int |     |     |     |     |
| as_fecha_exp | datetime |     |     |     |     |
| as_ciudad_nac | int |     |     |     |     |
| as_fecha_nac | datetime |     |     |     |     |
| as_sexo | varchar(1) | 1   |     |     |     |
| as_estado_civil | varchar(10) | 10  |     |     |     |
| as_parentesco | varchar(10) | 10  |     |     |     |
| as_ocupacion | varchar(10) | 10  |     |     |     |
| as_direccion | varchar(255) | 255 |     |     |     |
| as_telefono | varchar(16) | 16  |     |     |     |
| as_ciudad | int |     |     |     |     |
| as_correo_elec | varchar(255) | 255 |     |     |     |
| as_celular | varchar(16) | 16  |     |     |     |
| as_correspondencia | varchar(255) | 255 |     |     |     |
| as_plan | int |     |     |     |     |
| as_fecha_modif | datetime |     |     |     |     |
| as_usuario_modif | varchar(14) | 14  |     |     |     |
| as_observaciones | varchar(255) | 255 |     |     |     |
| as_act_economica | varchar(10) | 10  |     |     |     |
| as_ente | char(1) | 1   |     |     |     |
| as_fecha_ini_cobertura | datetime |     |     |     |     |
| as_fecha_ini_cobertura | datetime |     |     |     |     |

### cr_cambio_estados (No se usa en esta versión)

Registro del cambio de estado de cobranzas en línea.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ce_cobranza | Varchar | 10  | NOT NULL | Código de cobranza |     |
| ce_secuencial | Int | 4   | NOT NULL | Secuencial del cambio asistido |     |
| ce_estado_ant | Catalogo | 10  | NOT NULL | Estado anterior de la cobranza |     |
| ce_estado_act | Catalogo | 10  | NOT NULL | Estado actual de la cobranza |     |
| ce_funcionario | Login | 14  | NOT NULL | Funcionario que realizó el cambio del estado |     |
| ce_fecha | datetime | 8   | NOT NULL | Fecha que se realizó el cambio de estado |     |

### cr_campana (No se usa en esta versión)

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ca_codigo | Int |     | NOT NULL |     |     |
| ca_nombre | Varchar | 50  | NOT NULL |     |     |
| ca_descripcion | Varchar | 160 | NULL |     |     |
| ca_modalidad | Varchar | 10  | NOT NULL |     |     |
| ca_clientesc | Varchar | 10  | NOT NULL |     |     |
| ca_estado | Char | 1   | NOT NULL |     |     |
| ca_vig_ini | Datetime |     | NULL |     |     |
| ca_vig_fin | Datetime |     | NULL |     |     |
| ca_detalle | Varchar | 250 | NULL |     |     |
| ca_altura_mora | Int |     | NULL |     |     |
| ca_dias_de_vigencia | Int |     | NULL |     |     |
| ca_tipo_campana | Int |     | NULL |     |     |

### cr_campana_toperacion (No se usa en esta versión)

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ct_campana | Int |     | NOT NULL |     |     |
| ct_toperacion | Varchar | 10  | NOT NULL |     |     |

### cr_cau_tramite (Deprecated)

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cr_tramite | Int |     | NOT NULL |     |     |
| cr_etapa | Tinyint |     | NOT NULL |     |     |
| cr_requisito | Varchar | 10  | NOT NULL |     |     |
| cr_tipo | Varchar | 10  | NOT NULL |     |     |

### cr_cliente_campana (No se usa en esta versión)

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cc_cliente | Int |     | NOT NULL |     |     |
| cc_campana | Int |     | NULL |     |     |
| cc_tipo_pref | Varchar | 10  | NOT NULL |     |     |
| cc_fecha | Datetime |     | NOT NULL |     |     |
| cc_oficina | Int |     | NOT NULL |     |     |
| cc_estado | Char | 1   | NOT NULL |     |     |
| cc_acepta_contraoferta | Char | 1   | NULL |     |     |
| cc_asignado_a | Varchar | 14  | NULL |     |     |
| cc_asignado_por | Varchar | 14  | NULL |     |     |
| cc_encuesta | Char | 1   | NULL |     |     |
| cc_fecha_cierre | Datetime |     | NULL |     |     |
| cc_fecha_fin | Datetime |     | NULL |     |     |
| cc_fecha_ini | Datetime |     | NULL |     |     |
| cc_tramite | Int |     | NULL |     |     |

### cr_clientes_tmp

Tabla temporal para almacenar los clientes de la operación, deudor, o integrantes del grupo, para mostrar en la VCC.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | Smallint | 2   | NOT NULL | Identificación de proceso de usuario actual |     |
| ct_tramite | Int | 4   | NULL | Número de trámite que originó el cliente |     |
| ct_usuario | Varchar | 14  | NULL | Código de usuario |     |
| ct_ssn | Int | 4   | NULL | Secuencial de conexión desde front end |     |
| ct_tipo_con | Char | 1   | NULL | Tipo de consolidación | C= Cliente<br><br>G= Grupo<br><br>V= Grupo Vinculado |
| ct_cliente_con | Int | 4   | NULL | Cliente consolidado (deudor o grupo) |     |
| ct_cliente | Int | 4   | NULL | Código del cliente |     |
| ct_relacion | Char | 1   | NULL | Tipo de operación con código relacionado al organismo de control |     |
| ct_identico | Int | 4   | NULL | No aplica |     |

### cr_cobranza (No se usa en esta versión)

Mantenimiento de expedientes de cobranzas generadas en el sistema, tienen relación con las operaciones de cartera. no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| co_cobranza | Varchar | 10  | NOT NULL | Código de cobranza |     |
| co_cliente | Int | 4   | NOT NULL | Código del cliente |     |
| co_estado | Varchar | 10  | NOT NULL | Estado de la cobranza |     |
| co_proceso | Varchar | 10  | NOT NULL | Proceso de la cobranza |     |
| co_etapa | Varchar | 10  | NOT NULL | Etapa de la cobranza (Crédito, Cartera) |     |
| co_ab_interno | Varchar | 14  | NULL | Abogado interno a cargo de la cobranza |     |
| co_fecha_ab_interno | Datetime | 8   | NULL | Fecha en que pasó a cargo de abogado interno |     |
| co_abogado | Varchar | 10  | NULL | Código de abogado externo a cargo de la cobranza |     |
| co_fecha_abogado | Datetime | 8   | NULL | Fecha en que pasó a cargo de abogado externo |     |
| co_fecha_documentos | Datetime | 8   | NULL | Fecha de entrega de documento |     |
| co_fecha_demanda | Datetime | 8   | NULL | Fecha de paso a demanda judicial |     |
| co_juzgado | Varchar | 10  | NULL | Juzgado en que se encuentra el proceso de cobranza |     |
| co_num_juicio | Varchar | 24  | NULL | Número de juicio de la cobranza |     |
| co_informe | Smallint | 2   | NULL | Número de informe |     |
| co_fecha_ingr | Datetime | 8   | NOT NULL | Fecha de ingreso del grupo |     |
| co_usuario_ingr | Varchar | 14  | NOT NULL | Usuario de ingreso del grupo |     |
| co_fecha_mod | Datetime | 8   | NULL | Fecha de modificación |     |
| co_usuario_mod | Varchar | 14  | NULL | Usuario de modificación |     |
| co_oficina | Smallint | 2   | NOT NULL | Código de oficina |     |
| co_secuencial | Int | 4   | NOT NULL | Secuencial de cobranza |     |
| co_cob_externo | Varchar | 14  | NULL |     |     |
| co_fecha_cob_externo | Datetime |     | NULL |     |     |
| co_observa | Varchar | 254 | NULL |     |     |
| co_fecha_judicial | Datetime |     | NULL |     |     |

### cr_corresp_sib (No se usa en esta versión)

Parametrización de correspondencia de códigos del sistema con códigos de entidades de control.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| codigo | Varchar | 10  | NOT NULL | Código de ítem en la base de datos |     |
| tabla | Varchar | 24  | NOT NULL | Nombre de la tabla para la correspondencia |     |
| codigo_sib | Varchar | 10  | NOT NULL | Código de ítem correspondiente en el organismo de control |     |
| descripcion_sib | Varchar | 100 | NULL | Descripción del ítem |     |
| limite_inf | Int | 4   | NULL | Límite inferior para evaluación |     |
| limite_sup | Int | 4   | NULL | Límite superior para evaluación |     |
| monto_inf | Money | 8   | NULL | Monto inferior para comparación |     |
| monto_sup | Money | 8   | NULL | Monto superior para comparación |     |

### cr_costos (No se usa en esta versión)

Mantenimiento de costos de una cobranza; no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cs_cobranza | Varchar | 10  | NOT NULL | Código de cobranza |     |
| cs_costo | Smallint | 2   | NOT NULL | Secuencial de registro de costo |     |
| cs_codigo | Varchar | 10  | NULL | Catálogo de costos de cobranza |     |
| cs_valor | Money | 8   | NULL | Valor del costo incurrido |     |
| cs_moneda | Tinyint | 1   | NULL | Moneda de la cobranza |     |
| cs_fecha_registro | Datetime | 8   | NOT NULL | Fecha de registro del costo de la cobranza |     |
| cs_fecha_confirmacion | Datetime | 8   | NULL | Fecha en que se confirmó el costo de la cobranza |     |
| cs_usuario_confirmacion | Varchar | 14  | NULL | Usuario que confirmó el costo de la cobranza |     |
| cs_valor_pagado | Money | 8   | NULL | Valor pagado del costo |     |
| cs_fecha_pago | Datetime | 8   | NULL | Fecha en que se realizó el pago del costo |     |

### cr_cotiz3_tmp

Registra temporalmente las cotizaciones de las monedas del día de la consulta para mostrar los valores convertidos a la moneda nacional que se mostrarán en la VCC.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| Spid | Smallint | 2   | NOT NULL | Identificación de proceso de usuario actual |     |
| Moneda | Tinyint | 1   | NULL | Código de la moneda (tabla cl_moneda) |     |
| Cotización | Float | 8   | NULL | Valor de la cotización |     |

### cr_cotizacion (Deprecated)

Cotizaciones del módulo de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cz_moneda | Tinyint | 1   | NOT NULL | Código de moneda para cotizar |     |
| cz_fecha | Datetime | 8   | NOT NULL | Fecha de cotización |     |
| cz_valor | Money | 8   | NOT NULL | Valor de cotización |     |
| cz_fecha_modif | Datetime | 8   | NULL | Fecha de modificación |     |
| cz_usuario_modif | Varchar | 14  | NULL | Usuario que modifica el valor de la cotización |     |

### cr_dato_cliente (No se usa en esta versión)

Datos consolidados del cliente para el proceso de calificación de cartera. ; no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dc_fecha | Datetime | 8   | NOT NULL | Fecha de proceso de la información |     |
| dc_ipo_reg | Char | 1   | NOT NULL | Tipo de registro | M= Mensual<br><br>D= Diario |
| dc_cliente | Int | 4   | NOT NULL | Código de cliente |     |
| dc_nombre | Varchar | 160 | NOT NULL | Nombre del cliente |     |
| dc_tipo_id | Char | 2   | NOT NULL | Tipo identificador del cliente |     |
| dc_iden | Varchar | 30  | NOT NULL | Identificador de cliente |     |
| dc_digito | Char | 1   |     |     |     |
| dc_actividad | Varchar | 10  | NOT NULL | Código de actividad económica del cliente |     |
| dc_tipo_compania | Varchar | 10  | NOT NULL |     |     |
| dc_tipo_soc | Varchar | 10  | NOT NULL |     |     |
| dc_situacion | Varchar | 10  | NOT NULL |     |     |
| dc_estado | Varchar | 10  | NOT NULL |     |     |
| dc_fecha_estado | Datetime |     | NOT NULL |     |     |
| dc_val_activos | Money |     | NOT NULL |     |     |
| dc_tipo_cliente | Char | 1   | NOT NULL |     |     |

### cr_dato_garantia (No se usa en esta versión)

Datos consolidados de garantías para el proceso de calificación de cartera. ; no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dg_operacion | Int | 4   | NOT NULL | Código numérico de operación. |     |
| dg_banco | Varchar | 24  | NOT NULL | Código compuesto de operación |     |
| dg_producto | Tinyint | 1   | NOT NULL | Código de producto |     |
| dg_garantia | Varchar | 64  | NOT NULL | Código de garantía real |     |
| dg_tipo | Char | 1   | NOT NULL | Tipo de registro | M= Mensual<br><br>D= Diario |
| dg_cliente | Int |     | NOT NULL |     |     |
| dg_monto_distribuido | Float |     | NOT NULL |     |     |
| dg_clase | Varchar | 10  | NOT NULL |     |     |
| dg_gar_est_deu | Char | 1   | NOT NULL |     |     |
| dg_calif_final | Char | 1   | NOT NULL |     |     |
| dg_porc_resp | Float |     | NOT NULL |     |     |
| dg_valor_resp | Money |     | NOT NULL |     |     |
| dg_sitc | Varchar | 10  | NULL |     |     |
| dg_monto_distr_ini | Float |     | NOT NULL |     |     |
| dg_pdi | Float |     | NULL |     |     |

### cr_dato_operacion (No se usa en esta versión)

Datos consolidados de operaciones para calificación de cartera.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| do_fecha | Datetime | 8   | NOT NULL | Fecha de extracción de información |     |
| do_tipo_reg | Char | 1   | NOT NULL | Tipo de registro | M= Mensual<br><br>D= Diario |
| do_numero_operacion | Int | 4   | NULL | Código numérico de operación |     |
| do_numero_operacion_banco | Varchar | 24  | NULL | Código compuesto de operación |     |
| do_tipo_operacion | Char | 10  | NULL | Tipo de operación |     |
| do_codigo_producto | Tinyint | 1   | NULL | Código de producto |     |
| do_codigo_cliente | Int | 4   | NULL | Código de cliente |     |
| do_oficina | Smallint | 2   | NULL | Código de oficina |     |
| do_sucursal | Smallint | 2   | NULL | Código de sucursal |     |
| do_regional | Varchar | 10  |     |     |     |
| do_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| do_monto | Money | 8   | NULL | Monto original de operación |     |
| do_tasa | Float | 8   | NULL | Tasa de interés del préstamo |     |
| do_periodicidad | Smallint |     | NULL |     |     |
| do_modalidad | Char | 1   | NULL |     |     |
| do_fecha_concesion | Datetime | 8   | NULL | Fecha de concesión |     |
| do_fecha_vencimiento | Datetime | 8   | NULL | Fecha de vencimiento |     |
| do_dias_vcto_div | Smallint | 2   | NULL | Días de vencimiento del dividendo |     |
| do_fecha_vto_div | Datetime | 8   | NULL | Fecha de vencimiento del dividendo |     |
| do_reestructuracion | Char | 1   | NULL | Se trata de cartera reestructurada | S= Cartera reestructurada<br><br>N= No es cartera reestructurada |
| do_fecha_reest | Datetime |     | NULL |     |     |
| do_num_cuota_reest | Smallint |     | NULL |     |     |
| do_no_renovacion | Int | 4   | NULL | Número de renovación |     |
| do_codigo_destino | Varchar | 10  | NULL | Código de destino económico |     |
| do_clase_cartera | Varchar | 10  |     |     |     |
| do_codigo_geografico | Int | 4   | NULL | Código de destino geográfico de la operación |     |
| do_departamento | Smallint |     |     |     |     |
| do_tipo_garantias | Varchar | 24  | NULL | Tipo de garantía real |     |
| do_valor_garantias | Money | 8   | NULL | Valor de garantías |     |
| do_fecha_prox_vto | Datetime |     |     |     |     |
| do_saldo_prox_vto | Money |     |     |     |     |
| do_saldo_cap | Money |     |     |     |     |
| do_saldo_int | Money |     |     |     |     |
| do_saldo_otros | Money |     |     |     |     |
| do_saldo_int_contingente | Money |     |     |     |     |
| do_saldo | Money |     |     |     |     |
| do_estado_contable | Money |     |     |     |     |
| do_estado_desembolso | Char | 1   |     |     |     |
| do_estado_terminos | Char | 1   |     |     |     |
| do_calificacion | Varchar | 10  | NULL | Clasificación de la operación |     |
| do_calif_reest | Varchar | 10  |     |     |     |
| do_reportado | Char | 1   |     |     |     |
| do_linea_credito | Char | 24  | NULL | Código compuesto de línea de crédito |     |
| do_suspenso | Char | 1   |     |     |     |
| do_suspenso_ant | Char | 1   |     |     |     |
| do_periodicidad_cuota | Smallint |     |     |     |     |
| do_edad_mora | Int |     |     |     |     |
| do_valor_mora | Money |     |     |     |     |
| do_fecha_pago | Datetime |     |     |     |     |
| do_valor_cuota | Money | 8   | NULL | Valor de la cuota |     |
| do_cuotas_pag | Smallint |     |     |     |     |
| do_estado_cartera | Tinyint |     |     |     |     |
| do_plazo_dias | Int |     |     |     |     |
| do_freest_ant | Datetime |     |     |     |     |
| do_gerente | Smallint |     |     |     |     |
| do_num_cuotaven | Int | 4   | NULL | Número de cuotas vencidas |     |
| do_saldo_cuotaven | Money |     |     |     |     |
| do_admisible | Char | 1   |     |     |     |
| do_num_cuotas | Smallint |     |     |     |     |
| do_tipo_tarjeta | Char | 1   |     |     |     |
| do_clase_tarjeta | Varchar | 6   |     |     |     |
| do_tipo_bloqueo | Char | 1   |     |     |     |
| do_fecha_bloqueo | Datetime |     |     |     |     |
| do_fecha_cambio | Datetime |     |     |     |     |
| do_ciclo_fact | Datetime |     |     |     |     |
| do_valor_ult_pago | Money | 8   | NULL | Monto de último pago de la operación |     |
| do_fecha_castigo | Datetime | 8   | NULL | Fecha de castigo |     |
| do_num_acta | Varchar | 24  |     |     |     |
| do_gracia_cap | Smallint |     |     |     |     |
| do_gracia_int | Smallint |     |     |     |     |
| do_probabilidad_default | Float |     |     |     |     |
| do_nat_reest | Varchar | 10  |     |     |     |
| do_num_reest | Tinyint |     |     |     |     |
| do_acta_cas | Varchar | 10  |     |     |     |
| do_capsusxcor | Money |     |     |     |     |
| do_intsusxcor | Money |     |     |     |     |
| do_clausula | Char | 1   |     |     |     |
| do_moneda_op | Tinyint |     |     |     |     |

### cr_datos_linea

Tabla para parametrizar los montos mínimos y máximos por moneda de los tipos de líneas de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dl_toperacion | Varchar | 10  | NOT NULL | Tipo de línea de crédito o producto de línea |     |
| dl_moneda | Varchar | 10  | NOT NULL | Código de la moneda |     |
| dl_monto_maximo | Money |     | NOT NULL | Monto máximo permitido para el tipo de línea. |     |
| dl_monto_minimo | Money |     | NOT NULL | Monto mínimo permitido para el tipo de línea. |     |

### cr_datos_tramites (No se usa en esta versión)

Relación de operación de COMEXT con el número de trámite.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dt_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| dt_toperacion | Varchar | 10  | NOT NULL | Tipo de operación |     |
| dt_producto | Varchar | 10  | NOT NULL | Código de producto |     |
| dt_dato | Varchar | 24  | NOT NULL | Nombre del tipo de dato |     |
| dt_valor | Varchar | 255 | NOT NULL | Valor del dato adicional |     |

### cr_def_variables (Deprecated)

Parametrización de variables que intervienen en el ruteo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| df_variable | Tinyint | 1   | NOT NULL | Código de variable |     |
| df_descripcion | Varchar | 64  | NULL | Descripción de variable |     |
| df_programa | Varchar | 40  | NOT NULL | Programa que se ejecuta para obtener el valor de la variable |     |
| df_sp_ayuda | Varchar | 40  | NULL | Programa de ayuda de variables definidas |     |
| df_tipo | Char | 1   | NULL | Tipo de dato | I= Int<br><br>C= Char<br><br>D= Date<br><br>O= Otros |
| df_uso | Char | 1   | NULL | Se almacenan los valores de las variables |     |
| df_banca | Varchar | 10  | NULL |     |     |

### cr_desembolso (No se usa en esta versión)

Registro del cronograma de desembolso de operaciones de cartera.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dm_operacion | Int | 4   | NOT NULL | Código numérico de operación |     |
| dm_secuencial | Int | 4   | NOT NULL | Secuencial de cronograma de desembolso |     |
| dm_fecha_des | Datetime | 8   | NOT NULL | Fecha de cronograma de desembolso |     |
| dm_monto | Money | 8   | NOT NULL | Monto a desembolsar según cronograma |     |
| dm_monto_mn | Money | 8   | NOT NULL | Monto a desembolsar según cronograma en moneda nacional |     |
| dm_cotizacion | Float | 8   | NOT NULL | Cotización de moneda |     |
| dm_estado | Char | 3   | NOT NULL | Estado del registro del cronograma de desembolso |     |

### cr_deud1_tmp

Registra temporalmente la situación de las deudas en cartera. Se llena como tabla temporal para obtener información de las operaciones activas para mostrar en la VCC

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | smallint | 2   | yes | &nbsp;Número de proceso de la base de datos | &nbsp; |
| cliente | int | 4   | no  | &nbsp;Código del cliente cobis | &nbsp; |
| producto | varchar | 10  | no  | &nbsp;Tipo de producto Cobis (Cartera, Comercio exterior) | &nbsp; |
| tipo_operacion | varchar | 10  | no  | &nbsp;Tipo de Operación | &nbsp; |
| desc_tipo_op | varchar | 64  | yes | &nbsp;Descripción del tipo de operación. | &nbsp; |
| operacion | varchar | 24  | yes | &nbsp;Número de operación | &nbsp; |
| linea | varchar | 24  | yes | &nbsp;Número de línea de crédito | &nbsp; |
| tramite | int | 4   | no  | &nbsp;Número del trámite de crédito. | &nbsp; |
| fecha_apt | char | 10  | yes | &nbsp;Fecha de apertura de la la operación. | &nbsp; |
| fecha_vto | char | 10  | yes | &nbsp;Fecha de vencimiento de la operación. | &nbsp; |
| desc_moneda | varchar | 10  | yes | &nbsp;Descripción de la moneda de la operación | &nbsp; |
| monto_orig | money | 8   | yes | &nbsp;Monto original otorgado de la operación | &nbsp; |
| saldo_vencido | money | 8   | yes | &nbsp;Saldo vencido de la operación | &nbsp; |
| saldo_cuota | money | 8   | yes | &nbsp;Saldo de la cuota actúal de la operación | &nbsp; |
| subtotal | money | 8   | yes | &nbsp;Subtotal vencido | &nbsp; |
| saldo_capital | money | 8   | yes | &nbsp;Saldo de capital | &nbsp; |
| valorcontrato | money | 8   | no  | &nbsp;Valor total adeudado | &nbsp; |
| saldo_total | money | 8   | yes | &nbsp;Salto total de la operación | &nbsp; |
| saldo_ml | money | 8   | yes | &nbsp;Saldo en moneda local o nacional. | &nbsp; |
| tasa | varchar | 12  | yes | &nbsp;Tasa del crédito | &nbsp; |
| refinanciamiento | char | 2   | yes | &nbsp;Tipo de refinanciamiento | &nbsp; |
| prox_fecha_pag_int | char | 10  | yes | &nbsp;Fecha de proxímo pago del interés | &nbsp; |
| ult_fecha_pg | char | 10  | yes | &nbsp;Última fecha de pago | &nbsp; |
| estado_conta | varchar | 64  | no  | &nbsp;Estado contable de la operación | &nbsp; |
| clasificacion | varchar | 64  | yes | &nbsp;Calificación o clasificación de la operación | &nbsp; |
| estado | varchar | 64  | yes | &nbsp;Estado de la operación | &nbsp; |
| tipocar | varchar | 10  | no  | &nbsp;Tipo de cartera | &nbsp; |
| moneda | tinyint | 1   | yes | &nbsp;Moneda de la operación | &nbsp; |
| rol | char | 1   | yes | &nbsp;Rol del cliente en la operación | &nbsp; |
| cod_estado | varchar | 10  | yes | &nbsp; | &nbsp; |
| nombre_cliente | varchar | 254 | no  | &nbsp;Nombre del cliente | &nbsp; |
| tipo_deuda | char | 1   | no  | &nbsp;Tipo de deuda: D (directa), I: (Indirecta) | &nbsp; |
| dias_atraso | int | 4   | yes | &nbsp;Días de atraso o mora de la operación | &nbsp; |
| plazo | int | 4   | yes | &nbsp;Plazo de la operación | &nbsp; |
| motivo_credito | varchar | 64  | yes | &nbsp;Motivo por el que se solicitó la operación | &nbsp; |
| tipo_plazo | varchar | 64  | yes | &nbsp;Tipo de frecuencia de la operación. | &nbsp; |
| restructuracion | char | 1   | yes | &nbsp;Indica si es reestructuración o no | &nbsp; |
| fecha_cancelacion | datetime | 8   | yes | &nbsp;Fecha de cancelación de la operación | &nbsp; |
| refinanciado | char | 1   | yes | &nbsp;Indica si el crédito es refinanciado | &nbsp; |
| calificacion | char | 1   | yes | &nbsp;Calificación de la operación | &nbsp; |
| etapa_act | varchar | 255 | yes | &nbsp;No aplica | &nbsp; |
| id_inst_act | int | 4   | yes | &nbsp;No aplica | &nbsp; |
| codigo_alterno | varchar | 50  | yes | &nbsp;No aplica | &nbsp; |

### cr_deudores

Registro de deudores y codeudores de trámites.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| de_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| de_cliente | Int | 4   | NOT NULL | Código de cliente |     |
| de_rol | Catalogo | 10  | NOT NULL | Rol del cliente en el trámite: deudor, codeudor | D: deudor<br><br>C: codeudor<br><br>G: grupo |
| de_ced_ruc | Varchar | 30  | NULL | Identificación del cliente |     |
| de_segvida | Char | 1   | NULL | No aplica en esta versión |     |
| de_cobro_cen | Char | 1   | NOT NULL | No aplica en esta versión |     |

### cr_deudores_tmp

Registro temporal el momento de guardar los deudores y codeudores de trámites desde front end.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dt_ssn | Int | 4   | NOT NULL | Secuencial de conexión desde front end |     |
| dt_tramite | Int | 4   | NULL | Número de trámite |     |
| dt_cliente | Int | 4   | NOT NULL | Código de cliente |     |
| dt_rol | Catalogo | 10  | NOT NULL | Rol del cliente en el trámite: deudor, codeudor |     |
| dt_ced_ruc | Varchar | 35  | NULL | Identificación del cliente |     |
| dt_segvida | Char | 1   | NULL | No aplica en esta versión |     |
| dt_cobro_cen | Char | 1   | NULL | No aplica en esta versión |     |

### cr_documento

Registro de documentos impresos por cada trámite.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| do_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| do_documento | Smallint | 2   | NOT NULL | Código del documento impreso |     |
| do_numero | Tinyint | 1   | NOT NULL | Número de veces que se imprimió el documento para ese trámite |     |
| do_fecha_impresion | Datetime | 8   | NOT NULL | Fecha de impresión |     |
| do_usuario | Varchar | 14  | NOT NULL | Usuario que imprimió el documento la última vez |     |

### cr_errores_sib (No se usa en esta versión)

Registro de errores en procesos batch de crédito para generación de reportes y estructuras para organismos de control.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| es_programa | Char | 12  | NOT NULL | Programa en el que se produjo el error |     |
| es_descripcion | Char | 100 | NOT NULL | Descripción del error |     |
| es_producto | Tinyint | 1   | NULL | Código del producto |     |
| es_operacion | Int | 4   | NULL | Código numérico de operación |     |
| es_money | Money | 8   | NULL | Valor money para revisión |     |
| es_datetime | Datetime | 8   | NULL | Fecha en que se produjo el error |     |
| es_int | Int | 4   | NULL | Valor entero para revisión |     |
| es_char | Char | 20  | NULL | Valor carácter para revisión |     |

### cr_errorlog (No se usa en esta versión)

Registro de errores en procesos batch de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| er_fecha_proc | Datetime | 8   | NOT NULL | Fecha de proceso |     |
| er_usuario | Varchar | 14  | NULL | Usuario que ejecuta el proceso |     |
| er_tran | Int | 4   | NULL | Código de transacción COBIS |     |
| er_garantia | Varchar | 64  | NULL | Código compuesto de garantía |     |
| er_descripcion | Varchar | 255 | NULL | Descripción del error que se produce |     |

### cr_estacion (Deprecated)

Mantenimiento de estaciones del proceso de ruteo. Tabla de la versión estándar del core bancario COBIS, no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| es_estacion | Smallint | 2   | NOT NULL | Código de estación |     |
| es_descripcion | Varchar | 64  | NULL | Descripción de estación |     |
| es_oficina | Smallint | 2   | NOT NULL | Código de oficina |     |
| es_usuario | Varchar | 14  | NULL | Login de usuario asociado a la estación |     |
| es_nivel | Varchar | 10  | NULL | Código de nivel de la estación |     |
| es_carga | Tinyint | 1   | NULL | Número máximo de trámites en la estación |     |
| es_tipo | Char | 1   | NULL | Tipo de estación | P= Persona<br><br>C= Comité<br><br>L= Lógica |
| es_comite | Varchar | 10  | NULL | Nemónico del comité de crédito asociado a la estación |     |
| es_estacion_sup | Smallint | 2   | NULL | Estación superior para aprobación jerárquica |     |
| es_tope | Char | 1   | NULL | Tipo de operación |     |

### cr_etapa (Deprecated)

Mantenimiento de etapas del proceso de ruteo. Tabla de la versión estándar del core bancario COBIS, no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| et_etapa | Tinyint | 1   | NOT NULL | Código de etapa |     |
| et_descripcion | Varchar | 64  | NOT NULL | Descripción de etapa |     |
| et_tipo | Char | 1   | NOT NULL | Tipo de etapa | C= Control<br><br>A= Aprobación<br><br>F= Final |
| et_asignacion | Varchar | 40  | NULL | Programa que realiza la asignación a etapas de control |     |

### cr_etapa_estacion (Deprecated)

Mantenimiento de estaciones por etapa en el proceso de ruteo. Tabla de la versión estándar del core bancario COBIS, no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ee_estacion | Smallint | 2   | NOT NULL | Código de estación |     |
| ee_etapa | Tinyint | 1   | NOT NULL | Código de etapa |     |
| ee_modifica | Char | 1   | NULL | Característica que permite modificar el trámite | S= Modificar<br><br>N= No modificar |
| ee_estado | Char | 1   | NULL | Estado de la estación en la etapa | V= Vigente<br><br>E= Error<br><br>C= Cancelado |
| ee_estacion_sus | Smallint | 2   | NULL | Estación sustituta en la etapa |     |
| ee_firmas_reemplazo | Int | 4   | NULL | Número de firmas de reemplazo para la estación en la etapa |     |

### cr_excepciones (Deprecated)

Registro de excepciones ingresadas para cada trámite.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ex_tramite | Int | 4   | NOT NULL | Código de trámite |     |
| ex_numero | Tinyint | 1   | NOT NULL | Número secuencial de excepción |     |
| ex_codigo | Varchar | 10  | NOT NULL | Código de la excepción |     |
| ex_clase | Char | 1   | NULL | Clase de excepción. | R= Regulatoria<br><br>G= Garantía<br><br>O= Otros |
| ex_texto | Varchar | 255 | NOT NULL | Texto de descripción de la excepción |     |
| ex_estado | Char | 1   | NOT NULL | Estado de la excepción | V= Vigente<br><br>E= Error<br><br>C= Cancelado |
| ex_fecha_aprob | Datetime | 8   | NULL | Fecha de aprobación de la excepción |     |
| ex_login_aprob | Varchar | 14  | NULL | Login de usuario que aprobó la excepción |     |
| ex_fecha_tope | Datetime | 8   | NULL | Fecha máxima para regularizar la excepción |     |
| ex_fecha_regula | Datetime | 8   | NULL | Fecha de regularización de la excepción |     |
| ex_login_regula | Varchar | 14  | NULL | Login del usuario que regularizó la excepción |     |
| ex_razon_regula | Varchar | 255 | NULL | Texto descriptivo de la razón para la regularización |     |
| ex_fecha_reg | Datetime | 8   | NOT NULL | Fecha de registro de la excepción |     |
| ex_login_reg | Varchar | 14  | NOT NULL | Login de usuario que registró la excepción |     |
| ex_garantia | Varchar | 64  | NULL | Código de la garantía objeto de la excepción |     |
| ex_aprob_por | Varchar | 14  | NULL | Login de usuario que aprobó la excepción |     |
| ex_accion | Char | 1   | NULL | Tipo de acción |     |
| ex_comite | Varchar | 10  | NULL | Nemónico del comité que aprueba la excepción |     |
| ex_acta | Varchar | 24  | NULL | Número de acta en la que aprueba el comité |     |

### cr_excepcion_tramite

Registro de excepciones generadas por reglas o políticas para cada trámite, se usa en la aprobación de excepciones de un crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| et_tramite | int | 4   | NOT NULL | Número de trámite |     |
| et_regla | varchar | 30  | NOT NULL | Código de Excepción |     |
| et_fecha_autorizacion | date | 4   | NOT NULL | Fecha de aprobación de excepción |     |
| et_autorizante | varchar | 30  | NOT NULL | Usuario de autorización |     |
| et_autorizada | bit | 1   | NOT NULL | Identifica si el usuario autoriza (1) o no la excepción (0) |     |
| et_observacion | varchar | 100 | NULL | Observación sobre la excepción |     |
| et_tipo_autorizacion | char | 1   | NULL | Tipo de autorización, P: Política, D:documentos |     |
| et_actividad | int | 4   | NULL | Actividad por la que paso la excepción | No aplica en esta versión |

### cr_facturas (No se usa en esta versión)

Registro de documentos para tipo de operación factoring.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| fa_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| fa_documento | Int | 4   | NOT NULL | Número de documento |     |
| fa_num_negocio | Varchar | 64  | NOT NULL | Número de negocio |     |
| fa_grupo | Int | 4   | NOT NULL | Número de grupo de la factura |     |
| fa_valor | Money | 8   | NOT NULL | Valor de la factura ingresada |     |
| fa_moneda | Tinyint | 1   | NOT NULL | Código de moneda |     |
| fa_fecini_neg | Datetime | 8   | NOT NULL | Fecha de inicio de negocio |     |
| fa_fecfin_neg | Datetime | 8   | NOT NULL | Fecha de fin de negocio |     |
| fa_usada | Char | 1   | NOT NULL | Característica de usada- No aplica | S= Usada<br><br>N= No usada |
| fa_dividendo | Smallint | 2   | NULL | Número de dividendo vigente en la factura - No aplica |     |
| fa_referencia | Varchar | 16  | NOT NULL | Texto de referencia de la factura |     |
| fa_porcentaje | Float | 8   | NOT NULL | Porcentaje de tasa de la factura - No aplica |     |

### cr_gar_anteriores

Registro de garantías eliminadas, en reemplazo o sustitución cuando se encuentran atadas a una operación de cartera vigente. Se usa en el flujo de modificatorio de garantías.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ga_tramite | Int | 4   | NOT NULL | Código de trámite |     |
| ga_gar_anterior | Varchar | 64  | NULL | Código compuesto de garantía anterior por canje, garantía que se elimina de la operación. |     |
| ga_gar_nueva | Varchar | 64  | NULL | Código compuesto de nueva garantía por canje, garantía que se añade para la operación. |     |
| ga_operacion | Varchar | 24  | NULL | Código de la operación |     |
| ga_porcentaje | Float | 8   | NULL | Porcentaje de cobertura de la nueva garantía. No se usa |     |
| ga_valor_resp_garantia | Money | 8   | NULL | Valor que respalda la garantía. No se usa |     |

### cr_gar_p_tmp

Registra temporalmente datos de los clientes que tienen información de garantías y pólizas para mostrar en la VCC

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | Smallint | 2   | NOT NULL | Identificación de proceso de usuario actual |     |
| CLIENTE | Int | 4   | NULL | Código del cliente |     |
| TIPO_GAR | Varchar | 15  | NULL | Tipo de garantía |     |
| DESC_GAR | Varchar | 64  | NULL | Descripción de la garantía |     |
| CODIGO | Varchar | 64  | NULL | Código de garantía |     |
| MONEDA | Varchar | 10  | NULL | Código de moneda |     |
| VALOR_INI | Money | 8   | NULL | Valor inicial |     |
| VALOR_ACT | Money | 8   | NULL | Valor actual |     |
| VALOR_ACT_ML | Money | 8   | NULL | Valor actual de la garantía en moneda local |     |
| PORCENTAJE | Float | 8   | NULL | Porcentaje de garantía |     |
| MRC | Money | 8   | NULL | Valor actual de la garantía por el porcentaje de cobertura |     |
| ESTADO | Char | 1   | NULL | Estado de la garantía | C= Cancelada<br><br>P= Propuesta<br><br>V= Vigente |
| PLAZO_FIJO | Varchar | 30  | NULL | Código del Plazo fijo |     |
| TIPO_CTA | descripcion | 64  | NULL | Tipo de cuenta |     |
| FIADOR | descripcion | 64  | NULL | Descripción del cliente fiador o garante personal |     |
| ID_FIADOR | nume | 30  | NULL | Identificador del cliente fiador o garante personal |     |
| nombre_cliente | varchar | 254 | NULL | Nombre del cliente propietario de la garantía |     |
| fechaCancelacion | datetime | 8   | NULL | Fecha en que fue cancelada la garantía |     |
| fechaActivacion | datetime | 8   | NULL cr_gar_propuesta | Fecha en que se activó la garantía |     |

### cr_gar_propuesta

Tabla que almacena las garantías que están asociadas a un trámite de crédito y en fin último a una operación de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gp_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| gp_garantia | Varchar | 64  | NOT NULL | Código compuesto de garantía | Es el número largo de la garantía, la información de la garantía está en la cob_custodia..cu_custodia (cu_codigo_externo) |
| gp_abierta | Char | 1   | NOT NULL | Característica de garantía | A= Abierta<br><br>C= Cerrada |
| gp_deudor | Int | 4   | NOT NULL | Código de cliente del deudor |     |
| gp_est_garantia | Char | 1   | NOT NULL | Estado de la garantía | (cu_est_custodia) |
| gp_porcentaje | Float | 8   | NOT NUL | Porcentaje de cobertura de la garantía |     |
| gp_valor_resp_garantia | Money | 8   | NOT NUL | Valor de la operación que respalda la garantía |     |
| gp_saldo_cap_op | Money | 8   | NUL | Saldo de capital de la operación | No aplica en esta versión |
| gp_prendado | Money | 8   | NUL | Valor prendado de la garantía | No aplica en esta versión |

### cr_gar_tmp

Se usa para la VCC, almacena las garantías que fueron prendadas (depósitos a plazo, cuentas de ahorros o corrientes)

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | Smallint | 2   | NOT NULL | Identificación de proceso de usuario actual |     |
| CLIENTE | Int | 4   | NULL | Código del cliente |     |
| TIPO_GAR | Catalogo | 10  | NULL | Tipo de garantía |     |
| DESC_GAR | Varchar | 255 | NULL | Descripción de la garantía |     |
| CODIGO | Varchar | 64  | NULL | Código de la garantía |     |
| MONEDA | Varchar | 10  | NULL | Código de moneda |     |
| VALOR_INI | Money | 8   | NULL | Valor inicial |     |
| VALOR_ACT | Money | 8   | NULL | Valor actual |     |
| VALOR_ACT_ML | Money | 8   | NULL | Valor actual de la garantía en moneda local |     |
| PORCENTAJE | Float | 8   | NULL | Porcentaje de garantías |     |
| MRC | Money | 8   | NULL | Valor actual de la garantía por el porcentaje de cobertura |     |
| ESTADO | Char | 1   | NULL | Estado de la garantía |     |
| PLAZO_FIJO | Varchar | 30  | NULL | Plazo fijo |     |
| TIPO_CTA | descripcion | 64  | NULL | Tipo de cuenta |     |
| FIADOR | descripcion | 64  | NULL | Descripción del cliente de la operación asociada a la garantía |     |
| ID_FIADOR | numero | 30  | NULL | Identificador del cliente de la operación |     |
| CUSTODIA | Int | 4   | NULL | Código único de la custodia |     |
| nombre_cliente | varchar | 254 | NULL | Nombre del cliente |     |
| fechaCancelacion | datetime | 8   | NULL | Fecha de cancelación de garantía |     |
| fechaActivacion | datetime | 8   | NULL | Fecha de Activación de la garantía |     |
| VALOR_REALIZACION | Money | 8   | NULL | Valor de realización de la garantía |     |

### cr_garantia_gp (Deprecated)

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| estado | varchar(10) | 10  | NULL |     |     |
| credito | varchar(10) | 10  | NULL |     |     |
| clase | char(1) | 1   | NULL |     |     |
| numero | varchar(64) | 64  | NOT NULL |     |     |
| descrip | varchar(64) | 64  | NULL |     |     |
| cliente | varchar(64) | 64  | NULL |     |     |
| moneda | tinyint |     | NULL |     |     |
| inicial | money |     | NULL |     |     |
| actual | money |     | NULL |     |     |
| cobertura | float |     | NULL |     |     |
| margen | money |     | NULL |     |     |
| fecha | varchar(10) | 10  | NULL |     |     |
| avaluador | varchar(64) | 64  | NULL |     |     |
| propietario | varchar(64) | 64  | NULL |     |     |
| sesion | int |     | NULL |     |     |
| estado | varchar(10) | 10  | NOT NULL |     |     |

### cr_garantias_gp (Deprecated)

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tramite | int |     | NOT NULL |     |     |
| garantia | varchar(64) | 64  | NOT NULL |     |     |
| clasificacion | char(1) | 1   | NULL |     |     |
| exceso | char(1) | 1   | NULL |     |     |
| monto | money |     | NULL |     |     |
| clase | char(1) | 1   | NOT NULL |     |     |
| estado | char(1) | 1   | NOT NULL |     |     |
| avaluador | char(64) | 64  | NULL |     |     |
| propietario | char(64) | 64  | NULL |     |     |
| porcentaje | float |     | NULL |     |     |
| valor_resp | money |     | NULL |     |     |
| sesion | int |     | NOT NULL |     |     |

### cr_grupo_castigo (No se usa en esta versión)

Registra los tramites de la agrupación de procesos de castigo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gc_codigo | int | 4   | NOT NULL | Secuencial del registro |     |
| gc_fecha_corte | datetime | 8   | NOT NULL | Fecha de corte del proceso de castigo |     |
| gc_login | login | 14  | NOT NULL | Oficial que procesa el trámite del grupo |     |
| gc_tipo | char | 2   | NOT NULL | Etapa del tramite |     |
| gc_emplazamiento | catalogo | 10  | NOT NULL | Oficina, regiónal ó sugregional |     |
| gc_padre | int | 4   | NUL | Secuencial grupo padre |     |
| gc_coherencia | varchar | 255 | NUL | Coherencia de la solicitud |     |
| gc_comentario | varchar | 255 | NUL | Comentario de la solicitud |     |
| gc_estado | char | 1   | NUL | Estado de la solicitud |     |
| gc_sindico1 | varchar | 64  | NUL | 1° sindico de la solicitud |     |
| gc_sindico2 | varchar | 64  | NUL | 2° sindico de la solicitud |     |

### cr_grupo_tran_castigo (No se usa en esta versión)

Registra los tramites de la agrupación de procesos de castigo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gt_grupo | int | 4   | NOT NULL | Secuencial del grupo |     |
| gt_tran_castigo | int | 4   | NOT NULL | Secuencial de la cr_tr_castigo |     |
| gt_estado | char | 1   | NOT NULL | Estado del registro |     |
| gt_recomendada | char | 1   | NOT NULL | Si recomienda o no el castigo de la operacion | S,N |

### cr_grupo_tran_castigo_tmp (No se usa en esta versión)

Registra los tramites de la agrupación de procesos de castigo temporalmente para luego copiarlos en tablas definitivas.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gtm_grupo | int | 4   | NOT NULL | Secuencial del grupo |     |
| gtm_tran_castigo | int | 4   | NOT NULL | Secuencial de la cr_tr_castigo |     |
| gtm_estado | char | 1   | NOT NULL | Estado del registro |     |

###

### cr_his_calif (No se usa en esta versión)

Registro de histórico de calificación de oficial para operaciones de cartera.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| hc_ente | Int | 4   | NOT NULL | Código de cliente |     |
| hc_historia | Smallint | 2   | NOT NULL | Código de registro histórico |     |
| hc_calificacion | Varchar | 10  | NOT NULL | Calificación del cliente |     |
| hc_fecha_sug | Datetime | 8   | NULL | Fecha de calificación sugerida |     |
| hc_usuario_sug | Varchar | 14  | NULL | Usuario de registro de calificación sugerida |     |
| hc_fecha_conf | Datetime | 8   | NULL | Fecha de confirmación de calificación |     |
| hc_usuario_conf | Varchar | 14  | NULL | Usuario de confirmación de calificación |     |
| hc_fecha_cambio | Datetime | 8   | NOT NUL | Fecha de cambio de calificación |     |
| hc_comentario | Varchar | 255 | NULL | Comentario de calificación |     |
| hc_mantener_cal | Char | 1   | NULL | Mantener calificación del sistema | S= Mantener<br><br>N= Eliminar |

### cr_hist_credito (No se usa en esta versión)

Datos consolidados de créditos otorgados por cliente para consultas: historial crediticio.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ho_ente | Int | 4   | NOT NULL | Código del cliente |     |
| ho_historia | Int | 4   | NOT NULL | Secuencial de registro histórico |     |
| ho_toperacion | Catalogo | 10  | NOT NULL | Tipo de operación |     |
| ho_producto | Catalogo | 10  | NOT NULL | Código de producto |     |
| ho_monto | Money | 8   | NULL | Monto de crédito |     |
| ho_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| ho_periodo | Catalogo | 10  | NULL | Descripción de período de cuotas |     |
| ho_num_periodos | Smallint | 2   | NULL | Número de días de período de cuotas |     |
| ho_num_tra | Int | 4   | NOT NULL | Número de trámite |     |
| ho_num_ope | cuenta | 24  | NULL | Código compuesto de operación |     |
| ho_estado | Char | 1   | NOT NULL | Estado de trámite | V= Vigente<br><br>E= Error<br><br>C= Cancelado |
| ho_fecha_aprob | Datetime | 8   | NULL | Fecha de aprobación de trámite |     |
| ho_fecha_liq | Datetime | 8   | NULL | Fecha de desembolso |     |
| ho_fecha_venc | Datetime | 8   | NULL | Fecha de vencimiento de la operación |     |
| ho_observaciones | Varchar | 255 | NULL | Observaciones del oficial del trámite |     |
| ho_comportamiento | catalogo | 10  | NULL | Catálogo de comportamiento del cliente |     |
| ho_tipo_tram | Char | 1   | NOT NULL | Tipo de trámite |     |

### cr_imp_documento

Parametrización de documentos permitidos para imprimir por cada tipo de operación.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| id_documento | Smallint | 2   | NOT NULL | Código de documento |     |
| id_toperacion | Varchar | 10  | NOT NULL | Tipo de operación |     |
| id_producto | Varchar | 10  | NOT NULL | Código de producto |     |
| id_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| id_descripcion | Varchar | 64  | NOT NULL | Descripción del documento |     |
| id_template | Varchar | 64  | NOT NULL | Nombre físico de la plantilla Word o jasper que se utiliza para imprimir el documento |     |
| id_mnemonico | Varchar | 10  | NOT NULL | Nemónico del documento |     |
| id_tipo_tramite | Char | 1   | NOT NULL | Tipo de trámite, O: original, E: reestructuración, L: Linea, R: Refinanciamiento, etc |     |
| id_dato | Varchar | 10  | NULL | Dato para imprimir información de garantes, deudores, etc. |     |
| id_medio | Char | 1   | NULL | Si es medio de aprobación o no | S= Medio de aprobación<br><br>N= No es medio de aprobación |

### cr_instrucciones (Deprecated)

Mantenimiento de instrucciones operativas de trámites y operaciones vigentes de cartera.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| in_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| in_numero | Smallint | 2   | NOT NULL | Número de instrucción operativa |     |
| in_codigo | Varchar | 10  | NOT NULL | Código de la instrucción |     |
| in_estado | Char | 1   | NULL | Estado de la instrucción | V= Vigente<br><br>E= Error<br><br>C= Cancelado |
| in_texto | Varchar | 255 | NULL | Texto de la instrucción |     |
| in_parametro | Varchar | 10  | NULL | Catálogo de parámetros de instrucción |     |
| in_valor | Money | 8   | NULL | Valor de la instrucción |     |
| in_signo | Char | 2   | NULL | Signo: operación aritmética para realizar con el spread |     |
| in_spread | Float | 8   | NULL | Valor de spread |     |
| in_fecha_aprob | Datetime | 8   | NULL | Fecha de aprobación de la instrucción |     |
| in_login_aprob | Varchar | 14  | NULL | Login usuario de aprobación |     |
| in_fecha_reg | Datetime | 8   | NOT NULL | Fecha de registro de la instrucción |     |
| in_login_reg | Varchar | 14  | NOT NULL | Login de registro de la instrucción |     |
| in_login_eje | Varchar | 14  | NULL | Login de ejecución instrucción |     |
| in_fecha_eje | Datetime | 8   | NULL | Fecha de ejecución de la instrucción |     |
| in_aprob_por | Varchar | 14  | NULL | Login de usuario de aprobación |     |
| in_forma_pago | Varchar | 10  | NULL | Forma de pago |     |
| in_cuenta | Varchar | 24  | NULL | Código compuesto de cuenta para débito |     |
| in_tipo | Char | 1   | NULL | Tipo de trámite |     |
| in_comite | Varchar | 10  | NULL | Nemónico de comité de aprobación |     |
| in_acta | Varchar | 24  | NULL | Código compuesto de acta |     |
| in_garantia | Varchar | 64  | NULL | Código compuesto de garantía |     |
| in_comentario | Varchar | 255 | NULL | Comentario, observación de la instrucción |     |

### cr_lin_grupo (No se usa en esta versión)

Mantenimiento de distribución de la línea por miembro del grupo.  

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| lg_linea | Int | 4   | NOT NULL | Código entero de línea |     |
| lg_cliente | Int | 4   | NOT NULL | Código de cliente |     |
| lg_monto | Money | 8   | NULL | Monto de línea |     |
| lg_utilizado | Money | 8   | NULL | Monto utilizado de línea |     |
| lg_moneda | Tinyint | 1   | NULL | Código de moneda |     |

### cr_lin_ope_moneda

Mantenimiento de distribución de la línea por moneda y tipo de operación.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| om_linea | Int | 4   | NOT NULL | Código numérico de línea |     |
| om_toperacion | Varchar | 10  | NOT NULL | Tipo de operación de la facilidad |     |
| om_producto | Varchar | 10  | NOT NULL | Tipo de producto |     |
| om_moneda | Tinyint | 1   | NOT NULL | Código de moneda |     |
| om_monto | decimal | 16  | NULL | Monto de facilidad de la línea |     |
| om_utilizado | decimal | 16  | NULL | Monto utilizado de la facilidad de la línea |     |
| om_tplazo | Varchar | 10  | NULL | No se usa en esta versión |     |
| om_plazos | Smallint | 2   | NULL | No se usa en esta versión |     |
| om_condicion_especial | Varchar | 255 | NULL | Texto de condición especial de línea |     |
| om_reservado | Varchar | 10  | NULL | No se usa en esta versión |     |
| om_moneda_ope | Int | 4   | NULL | No se usa en esta versión |     |
| om_rotativa | Char | 1   | NULL | No se usa en esta versión |     |

### cr_linea

Mantenimiento de líneas de crédito y sus características operativas.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| li_numero | Int | 4   | NOT NULL | Código numérico de línea de crédito |     |
| li_num_banco | cuenta | 24  | NOT NULL | Código compuesto de línea de crédito, se actualiza cuando instrumento la línea. |     |
| li_oficina | Smallint | 2   | NOT NULL | Código de oficina | (cl_oficina) |
| li_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| li_cliente | Int | 4   | NULL | Código de cliente | (cl_ente)\*\* |
| li_grupo | Int | 4   | NULL | Código de grupo. No aplica |     |
| li_original | Int | 4   | NULL | Código de línea original si es una renovación. No aplica |     |
| li_fecha_aprob | Datetime | 8   | NULL | Fecha de aprobación de la línea |     |
| li_fecha_inicio | Datetime | 8   | NOT NULL | Fecha de inicio de vigencia de la línea |     |
| li_per_revision | catalogo | 10  | NULL | Período de revisión de la línea. No aplica |     |
| li_fecha_vto | Datetime | 8   | NULL | Fecha de vencimiento |     |
| li_dias | Smallint | 2   | NULL | Plazo de la línea en días |     |
| li_condicion_especial | Varchar | 255 | NULL | Texto de condición especial de línea. No aplica |     |
| li_segmento | catalogo | 10  | NULL | Segmento de la línea. No aplica |     |
| li_ult_rev | Datetime | 8   | NULL | Fecha de última revisión de la línea. No aplica |     |
| li_prox_rev | datetime | 8   | NULL | Fecha de próxima revisión. No aplica |     |
| li_usuario_rev | login | 14  | NULL | Usuario de última revisión. No aplica |     |
| li_monto | Money | 8   | NOT NULL | Monto de línea |     |
| li_moneda | Tinyint | 1   | NOT NULL | Código de moneda | (cl_moneda)\*\* |
| li_utilizado | Money | 8   | NULL | Monto utilizado |     |
| li_rotativa | Char | 1   | NOT NULL | Característica de la línea | S= Rotativa<br><br>N= No rotativa |
| li_clase | Catalogo | 10  | NULL | No se usa en esta versión |     |
| li_admisible | Money |     | NULL | No se usa en esta versión |     |
| li_noadmis | Money |     | NULL | No se usa en esta versión |     |
| li_estado | Char | 1   | NULL | Estado de la línea | Si está en estado V, se puede usar para hacer desembolsos bajo línea |
| Li_reservado | Money |     | NULL | No se usa en esta versión |     |
| li_tipo | char | 1   | NULL | No se usa en esta versión |     |
| li_usuario_mod | Login | 8   | NULL | No se usa en esta versión |     |
| li_fecha_mod | Datetime |     | NULL | No se usa en esta versión |     |
| li_dias_vig | Int |     | NULL | No se usa en esta versión |     |
| Li_num_desemb | Int |     | NULL | No se usa en esta versión |     |
| li_dias_vig_prorroga | Int |     | NULL | No se usa en esta versión |     |
| li_fech_apro_prorroga | Datetime |     | NULL | No se usa en esta versión |     |
| li_acta_prorroga | Cuenta | 24  | NULL | No se usa en esta versión |     |
| li_usu_prorroga | Login |     | NULL | No se usa en esta versión |     |
| li_tipo_normal | Char | 1   | NULL | No se usa en esta versión |     |
| li_tipo_plazo | Catalogo | 10  | NULL | No se usa en esta versión |     |
| li_tipo_cuota | Catalogo | 10  | NULL | No se usa en esta versión |     |
| li_cuota_aproximada | Money |     | NULL | No se usa en esta versión |     |
| li_bloq_manual | Char | 1   | NOT NULL | Solo en N en esta versión |     |
| li_tipo_bloq_aut | Char | 1   | NULL | No se usa en esta versión |     |
| li_acumulado_prorroga | Smallint |     | NULL | No se usa en esta versión |     |
| li_naturaleza | Catalogo | 10  | NULL | No se usa en esta versión |     |
|     |     |     |     |     |     |

### cr_ob_lineas (Deprecated)

Mantenimiento de líneas de texto para observaciones del trámite.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ol_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| ol_observacion | Smallint | 2   | NOT NULL | Consecutivo de observación |     |
| ol_linea | Smallint | 2   | NOT NULL | Consecutivo de línea de observación |     |
| ol_texto | Varchar | 255 | NOT NULL | Texto de la línea de la observación |     |

### cr_observaciones (Deprecated)

Mantenimiento de las observaciones del trámite.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ob_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| ob_numero | Smallint | 2   | NOT NULL | Código de observación |     |
| ob_fecha | Datetime | 8   | NOT NULL | Fecha de registro de la observación |     |
| ob_categoria | Varchar | 10  | NULL | Categoría de observación |     |
| ob_etapa | Tinyint | 1   | NOT NULL | Etapa en que se ingresó la observación |     |
| ob_estacion | Smallint | 2   | NOT NULL | Estación en la que se ingresó la observación |     |
| ob_usuario | Varchar | 14  | NOT NULL | Usuario de ingreso |     |
| ob_lineas | Smallint | 2   | NOT NULL | Número de líneas que tiene la observación |     |
| ob_oficial | Char | 1   | NOT NULL | Datos definitivos | S= Datos definitivos<br><br>N= Datos no definitivos |

### cr_observacion_castigo (No se usa en esta versión)

Registra la observación de un trámite que NO va a entrar en el proceso de castigo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| oc_grupo | int | 4   | NOT NULL | Número del grupo al cual pertenece el trámite |     |
| oc_tran_castigo | int | 4   | NOT NULL | Código de la tabla cr_grupo_castigo |     |
| oc_observacion | varchar | 255 | NOT NULL | Texto de porque se excluye la operación |     |

### cr_observacion_castigo_tmp (No se usa en esta versión)

Registra temporalmente la observación de un trámite que NO va a entrar en el proceso de castigo y luego se pasa a tablas definitivas.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| oct_grupo | int | 4   | NOT NULL | Número del grupo al cual pertenece el trámite |     |
| oct_tran_castigo | int | 4   | NOT NULL | Código de la tabla cr_grupo_castigo |     |
| obt_ observacion | varchar | 255 | NOT NULL | Texto de porque se excluye la operación |     |

### cr_op_renovar

Tabla que registra las operaciones que se reestructuran, renovan, o refinancian para originar a otra operación, o para reestructurarse, refinanciarse o renovarse sobre una operación base.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| or_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| or_num_operacion | Varchar | 24  | NOT NULL | Código largo de operación |     |
| or_producto | Varchar | 10  | NOT NULL | Código de producto | Siempre CCA |
| or_abono | Money | 8   | NULL | Monto de abono para cancelar la operación anterior |     |
| or_moneda_abono | Tinyint | 1   | NULL | Moneda de abono | Siempre es la de la operación |
| or_monto_original | Money | 8   | NULL | Monto original de la operación a reestructurar |     |
| or_moneda_original | Tinyint | 1   | NULL | Moneda original de la operación a reestructurar |     |
| or_saldo_original | Money | 8   | NULL | Saldo de la operación a reestructurar |     |
| or_fecha_concesion | Datetime | 8   | NULL | Fecha de concesión |     |
| or_toperacion | Varchar | 10  | NULL | Tipo de operación |     |
| or_operacion_original | Int | 4   | NULL | Código numérico de la operación original |     |
| or_cancelado | Char | 1   | NULL | No aplica |     |
| or_monto_inicial | Money | 8   | NULL | Monto inicial de la renovación. No aplica |     |
| or_moneda_inicial | Tinyint | 1   | NULL | Moneda de la renovación. No aplica |     |
| or_aplicar | char | 1   | NULL | No aplica |     |
| or_capitaliza | Char | 1   | NULL | Característica de capitaliza operación | (cr_monto_rees) |
| or_login | Login |     | NULL | Login del usuario que ingresa los registros |     |
| or_fecha_ingreso | Datetime |     | NULL | Fecha en que se ingresó el registro |     |
| or_finalizo_renovacion | char | 1   | NULL | Si finalizó el proceso de renovación |     |
| or_sec_prn | int | 4   | NULL | Secuencial de cartera cuando ya se renova la operación |     |
| or_oficina_tramite | Smallint | 2   | NULL | Oficina del trámite |     |
| or_base | char | 1   | NULL | Indica si sobre esa operación se refinancia o reestructura |     |

### cr_ope1_tmp

Temporal para almacenar operaciones que se mostrarán en la VCC, solo sirve para el proceso de llenado del proceso de manera temporal.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | Smallint | 2   | NOT NULL | Identificación de proceso de usuario actual |     |
| cliente | Int | 4   | NULL | Código del cliente |     |
| tramite | Int | 4   | NULL | Número de trámite |     |
| numero_op | Int | 4   | NULL | Código numérico de operación. |     |
| numero_op_banco | Varchar | 24  | NULL | Código compuesto de operación. |     |
| producto | Varchar | 10  | NULL | Código de producto |     |
| tipo_riesgo | Varchar | 16  | NULL | Tipo de riesgo. |     |
| tipo_tr | Char | 1   | NULL | Tipo de trámite |     |
| estado | Char | 1   | NULL | Estado de la operación |     |
| monto | Money | 8   | NULL | Monto de la transacción |     |
| moneda | Tinyint | 1   | NULL | Código de moneda. |     |
| toperacion | Varchar | 10  | NULL | Tipo de operación. |     |
| opestado | Tinyint | 1   | NULL | Estado de la operación |     |
| monto_des | Money | 8   | NULL | Rango límite desde |     |
| tipoop | Char | 1   | NULL | Tipo de operación |     |
| usuario | Varchar | 14  | NULL | Login de usuario de conexión. |     |
| secuencia | Int | 4   | NULL | Secuencial de registro. |     |
| tipo_con | Char | 1   | NULL | Tipo de cliente o grupo |     |
| cliente_con | Int | 4   | NULL | Código de cliente o grupo. |     |
| identico | Int | 4   | NULL | No aplica |     |
| tramite_d | Int | 4   | NULL |     |     |
| fecha_nip | Datetime | 8   | NULL | Fecha próxima de pago de interés |     |
| fecha_lip | Datetime | 8   | NULL | Ultima fecha de transacción |     |
| linea | Varchar | 24  | NULL | Consecutivo de línea de observación |     |
| mrc | Money | 8   | NULL | Valor de máximo riesgo de cobertura. |     |
| fecha_apt | Datetime | 8   | NULL | Fecha de apertura |     |
| anticipo | Int | 4   | NULL | Número de anticipo |     |
| rol | Char | 1   | NULL | Rol del deudor | D= Deudor<br><br>C= Codeudor |

### cr_operacion_cobranza (No se usa en esta versión)

Mantenimiento de la relación de operaciones de cartera y cobranzas. no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| oc_cobranza | Varchar | 10  | NOT NULL | Código de cobranza |     |
| oc_num_operacion | Varchar | 24  | NOT NULL | Código compuesto de operación |     |
| oc_producto | Varchar | 10  | NOT NULL | Tipo de producto |     |
| oc_oficina | Smallint | 2   | NULL | Código de oficina |     |
| oc_monto | Money | 8   | NULL | Monto de la operación |     |

### cr_param_calif (No se usa en esta versión)

Parametrización de calificación de cartera, por días de mora y sector de la cartera.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pc_tipo_cartera | Catalogo | 10  | NOT NULL | Código de Tipo de Cartera | C1…<br><br>P1..<br><br>H0…<br><br>M0…<br><br>N0… |
| pc_calificacion | Catalogo | 10  | NULL | Calificación |     |
| pc_desde | Smallint | 2   | NOT NULL | Rango "desde" de días de mora de operación |     |
| pc_hasta | Smallint | 2   | NOT NULL | Rango "hasta" de días de mora de operación |     |
| pc_sector | Catalogo | 10  | NOT NULL | Sector del tipode cartera |     |

### cr_parametros_linea

Tabla de parametrización de líneas de crédito, se indica hasta cuantas líneas por tipo de cliente y plazo máximo, esta tabla se usa solo si se llena desde el APF

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pl_toperacion | varchar(10) | 10  | NOT NULL | Tipo de operación |     |
| pl_numero_lineas | int |     | NOT NULL | Número de líneas de la operación |     |
| pl_tipo_cliente | char(1) | 1   | NOT NULL | Tipo de cliente, Natural o Jurídico |     |
| pl_plazo_maximo | int |     | NOT NULL | Plazo máximo en días de la línea |     |

### cr_pasos (Deprecated)

Parametrización de pasos dentro de una ruta en el proceso de aprobación de trámites. Tabla de la versión estándar del core bancario COBIS, no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pa_truta | Tinyint | 1   | NOT NULL | Tipo de ruta |     |
| pa_paso | Tinyint | 1   | NOT NULL | Consecutivo de paso en la ruta |     |
| pa_etapa | Tinyint | 1   | NOT NULL | Código de etapa |     |
| pa_descripcion | Varchar | 64  | NULL | Descripción del paso en la ruta |     |
| pa_tiempo_estandar | Float | 8   | NULL | Tiempo estándar en el paso |     |
| pa_tipo | Char | 1   | NOT NULL | Tipo de paso | N= Normal<br><br>C= Centralizado<br><br>O= Otros |
| pa_truta_asoc | Tinyint | 1   | NULL | Tipo de ruta asociada al paso |     |
| pa_paso_asoc | Tinyint | 1   | NULL | Paso asociado cuando es centralizado |     |
| pa_etapa_asoc | Tinyint | 1   | NULL | Etapa asociada cuando es centralizado |     |
| pa_picture | Char | 1   | NULL | Característica para pintar el paso en el FE | S= Pintar<br><br>N= No pintar |
| pa_ejecucion | Char | 1   | NULL | No aplica |     |
| pa_clase | Varchar | 10  | NULL | Catálogo de clase de paso |     |

### cr_poliza_tmp

Tabla temporal que se usa en los procesos para mostrar información de pólizas en la VCC.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | Smallint | 2   | NOT NULL | Identificación de proceso de usuario actual |     |
| CLIENTE | Int | 4   | NULL | Código del cliente |     |
| POLIZA | Varchar | 24  | NULL | Número de póliza de seguro. |     |
| TRAMITE | Int | 4   | NULL | Número de trámite al que está atada la póliza. |     |
| COMENTARIO | Varchar | 64  | NULL | Comentario de ingreso de la póliza. |     |
| ASEGURADORA | Varchar | 64  | NULL | Nombre de la aseguradora. |     |
| ESTADO | Varchar | 64  | NULL | Estado de la póliza. |     |
| TIPO_POLIZA | Varchar | 64  | NULL | Tipo de póliza |     |
| FECHA_VEN | Varchar | 10  | NULL | Fecha de vencimiento. |     |
| ANUALIDAD | Money | 8   | NULL | Costo de anualidad. |     |
| VAL_ENDOSO | Money | 8   | NULL | Valor de endoso |     |
| VAL_ENDOSO_ML | Money | 8   | NULL | Valor de endoso en moneda local. |     |
| GARANTIA | Varchar | 24  | NULL | Garantía de la póliza |     |
| AVALUO | Char | 2   | NULL | Valor de avalúo de la garantía |     |
| SEC_POL | Int | 4   | NULL | Secuencial numérico de póliza. |     |
| SEC | Numeric | 12  | NOT NULL | Número secuencial de la póliza |     |
| nombre_cliente | varchar | 254 | NULL | Nombre del cliente de la póliza |     |
| Fecha_cancelación | datetime |     | NULL | Fecha en que se cancela la póliza |     |
| Fecha_activacion | datetime |     | NULL | Fecha en que se activa la póliza |     |

### cr_productos_linea

Tabla usada en la parametrización de los productos de línea, se usa para controlar que tipos de productos de cartera pueden ser asociados a un tipo de línea de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pl_toperacion | varchar(10) | 10  | NOT NULL | Tipo de operación de cartera o de sobregiro |     |
| pl_producto | varchar(10) | 10  | NOT NULL | Producto activo o pasivo |     |
| pl_descripcion | varchar(250) | 250 | NOT NULL | Descripción |     |
| pl_estado | char(1) | 1   | NOT NULL | Estado del registro |     |
| pl_riesgo | char(1) | 1   | NOT NULL | Indica si el riesgo es directo o indirecto |     |
| pl_codigo_sib | varchar(25) | 25  | NOT NULL | Código sib asociado al registro |     |

### cr_regla (Deprecated)

Parametrización de reglas de ruta de aprobación, las reglas son condiciones que permiten saltar etapas en la ruta.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| re_truta | Tinyint | 1   | NOT NULL | Tipo de ruta |     |
| re_paso | Tinyint | 1   | NOT NULL | Número de paso en que se valida la regla |     |
| re_etapa | Tinyint | 1   | NOT NULL | Etapa en la que se valida la regla |     |
| re_regla | Tinyint | 1   | NOT NULL | Código de regla a validar |     |
| re_prioridad | Tinyint | 1   | NOT NULL | Prioridad de la regla en el caso de que exista más de una en la misma etapa |     |
| re_paso_siguiente | Tinyint | 1   | NOT NULL | Paso al que se realiza el "salto" |     |
| re_etapa_siguiente | Tinyint | 1   | NOT NULL | Etapa a la que se realiza el "salto" |     |
| re_descripcion | Varchar | 64  | NULL | Descripción de la regla |     |
| re_programa | Varchar | 40  | NOT NULL | Programa para realizar la validación |     |

### cr_req_tramite (Deprecated)

Mantenimiento de requisitos por trámite.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| rr_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| rr_tipo | Char | 1   | NOT NULL | Tipo de trámite |     |
| rr_etapa | Tinyint | 1   | NOT NULL | Etapa de validación de requisito |     |
| rr_requisito | Varchar | 10  | NOT NULL | Código de requisito |     |
| rr_observacion | Varchar | 64  | NULL | Texto de observación de requisito |     |
| rr_fecha_modif | Datetime | 8   | NULL | Fecha de modificación |     |
| rr_toperacion | Varchar | 10  | NULL | Tipo de operación |     |

### cr_ruta_tramite (Deprecated)

Mantenimiento de ruta de aprobación de trámites. Tabla de la versión estándar del core bancario COBIS, no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| rt_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| rt_secuencia | Smallint | 2   | NOT NULL | Secuencia en al ruta |     |
| rt_truta | Tinyint | 1   | NOT NULL | Tipo de ruta |     |
| rt_paso | Tinyint | 1   | NOT NULL | Secuencia de paso |     |
| rt_etapa | Tinyint | 1   | NOT NULL | Código de etapa |     |
| rt_estacion | Smallint | 2   | NOT NULL | Código de estación |     |
| rt_llegada | Datetime | 8   | NOT NULL | Fecha y hora de llegada a la estación |     |
| rt_salida | Datetime | 8   | NULL | Fecha y hora de salida de la estación |     |
| rt_estado | Int | 4   | NULL | Estado del paso en la ruta |     |
| rt_paralelo | Smallint | 2   | NULL | No aplica |     |
| rt_prioridad | Tinyint | 1   | NOT NULL | Prioridad en el ruteo |     |
| rt_abierto | Char | 1   | NOT NULL | Paso abierto | S= Abierto<br><br>N= Cerrado |
| rt_asociado | Smallint | 2   | NULL | Código de paso asociado |     |
| rt_etapa_sus | Tinyint | 1   | NULL | Etapa sustituta |     |
| rt_estacion_sus | Smallint | 2   | NULL | Estación sustituta |     |
| rt_comite | Char | 1   | NULL | Comité de crédito que aprueba |     |

### cr_secuencia (Deprecated)

Mantenimiento de secuencia de aprobación de trámites. Tabla de la versión estándar del core bancario COBIS, no usada en la versión personalizada para este banco.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| se_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| se_etapa | Tinyint | 1   | NOT NULL | Código de etapa |     |
| se_estacion | Smallint | 2   | NOT NULL | Código de estación |     |
| se_estado | Char | 1   | NULL | Estado del paso de la secuencia | S= Aprobado<br><br>N= No aprobado |
| se_secuencia | Tinyint | 1   | NULL | Número secuencial de paso |     |
| se_tipo | Char | 1   | NULL | Tipo de aprobación | R= Recomienda<br><br>A= Aprueba |
| se_superior | Smallint | 2   | NULL | Estación superior |     |
| se_miembro | Varchar | 10  | NULL | No aplica |     |

### cr_situacion_cliente

Tabla que almacena la información de los clientes que se mostrarán en la VCC

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sc_tramite | Int | 4   | NULL | Número de trámite |     |
| sc_usuario | Varchar | 14  | NULL | Login de conexión |     |
| sc_secuencia | Int | 4   | NULL | Secuencia de registro de situación del cliente |     |
| sc_tipo_con | Char | 1   | NULL | Tipo de cliente | C= Cliente<br><br>G= Grupo |
| sc_cliente_con | Int | 4   | NULL | Código de cliente o grupo |     |
| sc_cliente | Int | 4   | NULL | Código de cliente, si es grupo código de cliente miembro del grupo |     |
| sc_identico | Int | 4   | NULL | No aplica |     |
| sc_rol | Char | 1   | NULL | Rol de cliente | D= Deudor<br><br>C= Codeudor |
| sc_nombre_cliente | Varchar | 254 | NULL | Nombre completo del cliente |     |

### cr_situacion_deudas

Datos consolidados de información de préstamos para consulta en línea de vinculación del cliente que se muestra en la VCC.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sd_cliente | Int | 4   | NULL | Código de cliente |     |
| sd_usuario | Varchar | 14  | NULL | Login de usuario de conexión |     |
| sd_secuencia | Int | 4   | NULL | Secuencia del registro |     |
| sd_tipo_con | Char | 1   | NULL | Tipo de cliente | C= Cliente<br><br>G= Grupo |
| sd_cliente_con | Int | 4   | NULL | Código de cliente o grupo |     |
| sd_identico | Int | 4   | NULL | No aplica |     |
| sd_categoria | Varchar | 10  | NULL | Categoría de producto |     |
| sd_desc_categoria | Varchar | 64  | NULL | Descripción de categoría de producto |     |
| sd_producto | Varchar | 10  | NULL | Código de producto |     |
| sd_tipo_op | Varchar | 10  | NULL | Tipo de operación |     |
| sd_desc_tipo_op | Varchar | 64  | NULL | Descripción de tipo de operación |     |
| sd_tramite | Int | 4   | NULL | Número de trámite |     |
| sd_numero_operacion | Varchar | 24  | NULL | Código compuesto de operación |     |
| sd_operacion | Int | 4   | NULL | Código entero de operación |     |
| sd_tasa | Float | 8   | NULL | Tasa de interés |     |
| sd_fecha_apr | Datetime | 8   | NULL | Fecha de apertura de operación |     |
| sd_fecha_vct | Datetime | 8   | NULL | Fecha de vencimiento de operación |     |
| sd_monto | Money | 8   | NULL | Monto original de operación |     |
| sd_saldo_vencido | Money | 8   | NULL | Saldo vencido de operación |     |
| sd_saldo_x_vencer | Money | 8   | NULL | Saldo por vencer de operación |     |
| sd_monto_ml | Money | 8   | NULL | Monto moneda local |     |
| sd_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| sd_prox_pag_int | Datetime | 8   | NULL | Fecha de próximo pago de interés |     |
| sd_ult_fecha_pg | Datetime | 8   | NULL | Fecha de último pago |     |
| sd_val_utilizado | Money | 8   | NULL | Valor utilizado de la línea |     |
| sd_val_utilizado_ml | Money | 8   | NULL | Valor utilizado de la línea en moneda local |     |
| sd_limite_credito | Money | 8   | NULL | Límite de crédito |     |
| sd_total_cargos | Money | 8   | NULL | Saldo de rubros cargos |     |
| sd_saldo_promedio | Money | 8   | NULL | Saldo promedio |     |
| sd_ult_fecha_mov | Datetime | 8   | NULL | Fecha de último movimiento |     |
| sd_aprobado | Char | 1   | NULL | Monto aprobado |     |
| sd_tarjeta_visa | Varchar | 24  | NULL | Número de tarjeta de crédito |     |
| sd_tramite_d | int | 4   | NULL | Trámite en proceso de aprobación |     |
| sd_subtipo | Varchar | 10  | NULL | Subtipo de cliente: persona o compañía |     |
| sd_tipo_deuda | Char | 1   | NULL | Tipo de riesgo |     |
| sd_calificacion | Varchar | 64  | NULL | Calificación de operación |     |
| sd_estado | Varchar | 64  | NULL | Estado de operación |     |
| sd_fechas_embarque | Varchar | 64  | NULL | Fecha de embarque |     |
| sd_monto_riesgo | Money | 8   | NULL | Monto del riesgo del cliente |     |
| sd_beneficiario | Varchar | 64  | NULL | Descripción del cliente |     |
| sd_tipo_garantia | Varchar | 10  | NULL | Tipo de garantía |     |
| sd_descrip_gar | Varchar | 64  | NULL | Descripción de la garantía |     |
| sd_monto_orig | Money | 8   | NULL | Monto original |     |
| sd_tipoop_car | Char | 1   | NULL | Tipo de operación de cartera |     |
| sd_contrato_act | Money | 8   | NULL | Saldo de contrato actual |     |
| sd_rol | Char | 1   | NULL | Rol del deudor | D= Deudor<br><br>C= Codeudor |
| sd_dias_atraso | Int | 4   | Null | Días de atraso del deudos |     |
| sd_tipo_plazo | Varchar | 255 | Null | Tipo de Plazo |     |
| sd_plazo | Int | 4   | Null | Plazo |     |
| sd_motivo_credito | Varchar | 255 | Null | Motivo del Credito |     |
| sd_tipo_tramite | Char | 1   | Null | Tipo de Tramite |     |
| sd_fecha_cancelacion | Datetime | 8   | Null | Fecha de cancelación de la operación |     |
| sd_refinanciamiento | Char | 1   | Null | La operación es de refinanciamiento |     |
| sd_restructuracion | Char | 1   | Null | La operación es de reestructuración |     |
| sd_ciclo | int |     | Null | Ciclo de la operación |     |

### cr_situacion_gar

Datos consolidados de información de garantías para consulta en línea de vinculación del cliente en la VCC

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sg_cliente | Int | 4   | NULL | Código de cliente |     |
| sg_tramite | Int | 4   | NULL | Número de trámite |     |
| sg_usuario | Varchar | 14  | NULL | Login de usuario de conexión |     |
| sg_secuencia | Int | 4   | NULL | Secuencia de registro |     |
| sg_tipo_con | Char | 1   | NULL | Tipo de cliente | C= Cliente<br><br>G= Grupo |
| sg_cliente_con | Int | 4   | NULL | Código de cliente o grupo |     |
| sg_identico | Int | 4   | NULL | No aplica |     |
| sg_producto | Varchar | 10  | NULL | Código de producto |     |
| sg_tipo_gar | Varchar | 10  | NULL | Código de tipo de garantía |     |
| sg_desc_gar | Varchar | 64  | NULL | Descripción del tipo de garantía |     |
| sg_codigo | Varchar | 64  | NULL | Código compuesto de garantía |     |
| sg_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| sg_valor_ini | Money | 8   | NULL | Valor inicial de garantía |     |
| sg_valor_act | Money | 8   | NULL | Valor actual de garantía |     |
| sg_valor_act_ml | Money | 8   | NULL | Valor actual de garantía en moneda local |     |
| sg_estado | Char | 1   | NULL | Estado de garantía | V= Vigente<br><br>E= Error<br><br>C= Cancelado |
| sg_pfijo | Varchar | 30  | NULL | Código compuesto de operación de plazo fijo que se encuentra pignorado como garantía |     |
| sg_fiador | Varchar | 60  | NULL | Descripción del cliente de la operación asociada a la garantía |     |
| sg_id_fiador | Numero | 30  | NULL | Identificador del cliente de la operación |     |
| sg_tramite_gar | Int | 4   | NULL | Trámite asociado a la garantía |     |
| sg_porc_mrc | Float | 8   | NULL | Porcentaje de cobertura |     |
| sg_valor_mrc | Money | 8   | NULL | Valor de cobertura |     |
| sg_custodia | Int | 4   | NULL | Código único de la custodia |     |
| sg_fechaCancelacion | Datetime | 8   | NULL | Fecha de cancelación de la gtia |     |
| sg_fechaActivacion | Datetime | 8   | NULL | Fecha de Activación de la gtia |     |

### cr_situacion_gar_p

Datos consolidados de información de garantías propuestas para consulta en línea de vinculación del cliente en la VCC

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sg_p_cliente | Int | 4   | NULL | Código de cliente |     |
| sg_p_tramite | Int | 4   | NULL | Número de trámite |     |
| sg_p_usuario | Varchar | 14  | NULL | Login de usuario de conexión |     |
| sg_p_secuencia | Int | 4   | NULL | Secuencia de registro |     |
| sg_p_tipo_con | Char | 1   | NULL | Tipo de cliente | C= Cliente<br><br>G= Grupo |
| sg_p_cliente_con | Int | 4   | NULL | Código de cliente o grupo |     |
| sg_p_identico | Int | 4   | NULL | No aplica |     |
| sg_p_producto | Varchar | 10  | NULL | Código de producto |     |
| sg_p_tipo_gar | Varchar | 10  | NULL | Tipo de garantía |     |
| sg_p_desc_gar | Varchar | 64  | NULL | Descripción de garantía |     |
| sg_p_codigo | Varchar | 64  | NULL | Código compuesto de garantía |     |
| sg_p_moneda | Tinyint | 1   | NULL | Código de moneda de garantía |     |
| sg_p_valor_ini | Money | 8   | NULL | Valor inicial de garantía |     |
| sg_p_valor_act | Money | 8   | NULL | Valor actual de garantía |     |
| sg_p_valor_act_ml | Money | 8   | NULL | Valor actual de garantía en moneda local |     |
| sg_p_estado | Char | 1   | NULL | Estado de la garantía | V= Vigente<br><br>E= Error<br><br>C= Cancelado |
| sg_p_fijo | Varchar | 30  | NULL | Operación de plazo fijo pignorada en la garantía |     |
| sg_p_fiador | Varchar | 60  | NULL | Descripción del cliente de operación asociada a la garantía |     |
| sg_p_id_fiador | Numero | 30  | NULL | Identificador del cliente de la operación |     |
| sg_p_tramite_gar | Int | 4   | NULL | Número de trámite asociado a la garantía |     |
| sg_p_porc_mrc | Float | 8   | NULL | Porcentaje de cobertura |     |
| sg_p_valor_mrc | Money | 8   | NULL | Valor de cobertura |     |
| sg_fechaCancelacion | Datetime | 8   | NULL | Fecha de cancelación de la gtia |     |
| sg_fechaActivacion | Datetime | 8   | NULL | Fecha de Activación de la gtia |     |

### cr_situacion_inversiones

Datos consolidados de información de inversiones (productos pasivos) para consulta en línea de vinculación del cliente en la Vista Consolidada.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| si_cliente | Int | 4   | NULL | Código de cliente |     |
| si_tramite | Int | 4   | NULL | Número de trámite |     |
| si_usuario | Varchar | 14  | NULL | Login de usuario de conexión |     |
| si_secuencia | Int | 4   | NULL | Secuencia de registro |     |
| si_tipo_con | Char | 1   | NULL | Tipo de cliente | C= Cliente<br><br>G= Grupo |
| si_cliente_con | Int | 4   | NULL | Código de cliente o grupo |     |
| si_identico | Int | 4   | NULL | No aplica |     |
| si_categoria | Varchar | 10  | NULL | Categoría del producto |     |
| si_desc_categoria | Varchar | 64  | NULL | Descripción de la categoría del producto |     |
| si_producto | Varchar | 10  | NULL | Código de producto |     |
| si_tipo_op | Varchar | 10  | NULL | Tipo de operación |     |
| si_desc_tipo_op | Varchar | 64  | NULL | Descripción del tipo de operación |     |
| si_numero_operacion | Varchar | 24  | NULL | Código compuesto de operación |     |
| si_tasa | Float | 8   | NULL | Tasa de interés |     |
| si_fecha_apt | Datetime | 8   | NULL | Fecha de apertura |     |
| si_fecha_vct | Datetime | 8   | NULL | Fecha de vencimiento |     |
| si_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| si_saldo | Money | 8   | NULL | Saldo de operación |     |
| si_saldo_ml | Money | 8   | NULL | Saldo de operación en moneda local |     |
| si_saldo_promedio | Money | 8   | NULL | Saldo promedio |     |
| si_interes_acumulado | Money | 8   | NULL | Interés acumulado |     |
| si_valor_garantia | Money | 8   | NULL | Valor de garantía |     |
| si_fecha_ult_mov | Datetime | 8   | NULL | Fecha de último movimiento de la inversión |     |
| si_fecha_prox_p_int | Datetime | 8   | NULL | Fecha de próximo pago de interés |     |
| si_fecha_utl_p_int | Datetime | 8   | NULL | Fecha de último pago de interés |     |
| si_val_nominal | Float | 8   | NULL | Valor nominal de la inversión |     |
| si_precio_mercado | Float | 8   | NULL | Precio de mercado de la inversión |     |
| si_valor_mercado | Float | 8   | NULL | Valor de mercado de la inversión |     |
| si_monto_prendado | Float | 8   | NULL | Monto prendado de la inversión |     |
| si_precio_compra | Float | 8   | NULL | Precio de compra |     |
| si_monto_compra | Float | 8   | NULL | Monto de compra |     |
| si_valor_mercado_ml | Float | 8   | NULL | Valor de mercado moneda local |     |
| si_operacion | Int | 4   | NULL | Código numérico de operación |     |
| si_estado | Varchar | 10  | NULL | Estado de la inversión | V= Vigente<br><br>E= Error<br><br>C= Cancelado |
| si_desc_estado | Varchar | 64  | NULL | Descripción del estado |     |
| si_login | Varchar | 14  | NULL | Login de usuario de consulta |     |
| si_rol | Char | 1   | NULL | Rol del deudor | D= Deudor<br><br>C= Codeudor |
| si_bloqueos | Money | 8   | NULL | Monto de embargo, valor tomado de cuentas de ahorros |     |
| si_plazo | Int | 4   | NULL | Plazo de la inversión |     |
| si_fecha_can | Datetime | 8   | NULL | Fecha de cancelación de inversión |     |
| si_oficina | Int | 4   | NULL | Codigo de Oficina de la inversión |     |
| si_desc_oficina | Descripcion | 64  | NULL | Nombre de la oficina cr_situacion_lineas |     |

### cr_situacion_lineas

Datos consolidados de información de líneas para consulta en línea de vinculación del cliente que se muestran en la VCC en la sección de Contingentes.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sl_cliente | Int | 4   | NULL | Código de cliente |     |
| sl_usuario | Varchar | 14  | NOT NULL | Login de usuario de conexión |     |
| sl_secuencia | Int | 4   | NOT NULL | Secuencia de registro |     |
| sl_tipo_con | Char | 1   | NULL | Tipo de cliente | C= Cliente<br><br>G= Grupo |
| sl_cliente_con | Int | 4   | NULL | Código de cliente o grupo |     |
| sl_identico | Int | 4   | NULL | No aplica |     |
| sl_producto | Varchar | 10  | NULL | Código de producto |     |
| sl_tramite | Int | 4   | NULL | Número de trámite de la operación amparada por la línea |     |
| sl_sector | Varchar | 10  | NULL | Código de sector |     |
| sl_numero_op_banco | Varchar | 64  | NULL | Código compuesto de línea |     |
| sl_linea | Int | 4   | NULL | Código numérico de línea |     |
| sl_fecha_apr | Datetime | 8   | NULL | Fecha de apertura |     |
| sl_fecha_vct | Datetime | 8   | NULL | Fecha de vencimiento de línea |     |
| sl_val_utilizado | Money | 8   | NULL | Monto utilizado |     |
| sl_limite_credito | Money | 8   | NULL | Límite de facilidad |     |
| sl_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| sl_utilizado_ml | Money | 8   | NULL | Monto utilizado de la línea |     |
| sl_tipo | Varchar | 10  | NULL | Tipo de línea |     |
| sl_desc_tipo | Varchar | 64  | NULL | Descripción de tipo |     |
| sl_tramite_d | Int | 4   | NULL | Número de trámite de la línea |     |
| sl_disponible | Money | 8   | NULL | Monto disponible de la línea |     |
| sl_disponible_ml | Money | 8   | NULL | Monto disponible de la línea en moneda local |     |
| sl_tasa | Float | 8   | NULL | Tasa de interés |     |
| sl_execeso | Money | 8   | NULL | No aplica |     |
| sl_tipo_deuda | Char | 1   | NULL | Tipo de deuda | D= Directo<br><br>C= Contingente |
| sl_valor_contrato | Money | 8   | NULL | Valor de contrato |     |
| sl_monto_factoring | Money | 8   | NULL | Monto de operación factoring |     |
| sl_saldo_capital | Money | 8   | NULL | Saldo de capital de la operación amparada por la línea |     |
| sl_monto_riesgo | Money | 8   | NULL | Monto de riesgo del cliente |     |
| sl_emisor | Varchar | 64  | NULL | Descripción del cliente |     |
| sl_estado | Varchar | 10  | NULL | Estado de la línea |     |
| sl_desc_estado | Varchar | 64  | NULL | Descripción del estado |     |
| sl_frecuencia | Varchar | 64  | NULL | Frecuencia de la línea |     |
| sl_plazo | Int |     | NULL | Plazo de la Linea |     |
| sl_rol | Varchar | 32  | NULL | Rol del cliente en la operación |     |
| sl_tipo_rotativo | Varchar | 32  | NULL | Indica si es ROTATIVA o NO |     |

### cr_situacion_otras

Datos consolidados de información de otros riesgos para consulta en línea de vinculación del cliente que se muestran en la VCC.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| so_cliente | Int | 4   | NULL | Código de cliente |     |
| so_usuario | Varchar | 14  | NULL | Login de usuario de conexión |     |
| so_secuencia | Int | 4   | NULL | Secuencia de registro |     |
| so_tipo_con | Char | 1   | NULL | Tipo de cliente | C= Cliente<br><br>G= Grupo |
| so_cliente_con | Int | 4   | NULL | Código de cliente o grupo |     |
| so_identico | Int | 4   | NULL | No aplica |     |
| so_categoria | Varchar | 10  | NULL | Categoría del producto |     |
| so_desc_categoria | Varchar | 64  | NULL | Descripción de categoría del producto |     |
| so_producto | Varchar | 10  | NULL | Código de producto |     |
| so_tipo_op | Varchar | 10  | NULL | Tipo de operación |     |
| so_desc_tipo_op | Varchar | 64  | NULL | Descripción del tipo de operación |     |
| so_tramite | Int | 4   | NULL | Número de trámite |     |
| so_numero_operacion | Varchar | 24  | NULL | Código compuesto de operación |     |
| so_operacion | Int | 4   | NULL | Código numérico de operación |     |
| so_tasa | Float | 8   | NULL | Tasa de interés |     |
| so_fecha_apr | Datetime | 8   | NULL | Fecha de apertura |     |
| so_fecha_vct | Datetime | 8   | NULL | Fecha de vencimiento |     |
| so_monto | Money | 8   | NULL | Monto de operación |     |
| so_saldo_vencido | Money | 8   | NULL | Saldo vencido de operación |     |
| so_saldo_x_vencer | Money | 8   | NULL | Saldo por vencer de operación |     |
| so_monto_ml | Money | 8   | NULL | Monto moneda local |     |
| so_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| so_prox_pag_int | Datetime | 8   | NULL | Fecha de próximo pago de interés |     |
| so_ult_fecha_pg | Datetime | 8   | NULL | Fecha de último pago de interés |     |
| so_val_utilizado | Money | 8   | NULL | Valor utilizado si tiene línea |     |
| so_val_utilizado_ml | Money | 8   | NULL | Valor utilizado en moneda local |     |
| so_limite_credito | Money | 8   | NULL | Límite de crédito en línea |     |
| so_total_cargos | Money | 8   | NULL | Saldo de operación en rubro otros cargos |     |
| so_saldo_promedio | Money | 8   | NULL | Saldo promedio si se trata de una inversión |     |
| so_ult_fecha_mov | Datetime | 8   | NULL | Fecha de último movimiento |     |
| so_aprobado | Char | 1   | NULL | Monto aprobado |     |
| so_tarjeta_visa | Varchar | 24  | NULL | Número de tarjeta visa |     |
| so_tramite_d | Int | 4   | NULL | Código de trámite |     |
| so_subtipo | Varchar | 10  | NULL | Tipo de cliente: persona o compañía |     |
| so_tipo_deuda | Char | 1   | NULL | Tipo de deuda | D= Directo<br><br>C= Contingente |
| so_calificacion | Varchar | 64  | NULL | Calificación |     |
| so_estado | Varchar | 64  | NULL | Estado de la operación |     |
| so_fechas_embarque | Varchar | 64  | NULL | Fechas de embarque |     |
| so_monto_riesgo | Money | 8   | NULL | Monto de riesgo del cliente |     |
| so_beneficiario | Varchar | 64  | NULL | Descripción del beneficiario de la inversión |     |
| so_clase_garantia | Varchar | 10  | NULL | Clase de gtia |     |
| so_rol | Varchar | 16  | NULL | Rol de cliente en la operación |     |

### cr_soli_rechazadas_tmp

Auxiliar que se utiliza para consulta de solicitudes rechazadas, se usa para mostrar información de la posición en la VCC

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | smallint | 2   | NOT NULL | Id solicitud |     |
| numero_id | varchar | 35  | NOT NULL | Número de identificación cliente |     |
| fecha_carga | varchar | 35  | NOT NULL | Fecha de creación |     |
| numero_operacion | varchar | 24  | NULL | Número de operación |     |
| fecha_rechazo | varchar | 35  | NULL | Fecha de rechazo |     |
| motivo | varchar | 150 | NULL | Motivo rechazo |     |
| usuario | varchar | 150 | NOT NULL | Usuario rechazo |     |
| modulo | varchar | 10  | NULL | Módulo de la solicitud |     |

### cr_situacion_poliza

Datos consolidados de información de pólizas de seguros para consulta en línea de vinculación del cliente en la Vista Consolidada.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sp_cliente | Int | 4   | NULL | Código de cliente |     |
| sp_tramite | Int | 4   | NULL | Número de trámite al que está atada la póliza |     |
| sp_usuario | Varchar | 14  | NULL | Login de usuario |     |
| sp_secuencia | Int | 4   | NULL | Secuencia de registro |     |
| sp_tipo_con | Char | 1   | NULL | Tipo de cliente | C= Cliente<br><br>G= Grupo |
| sp_cliente_con | Int | 4   | NULL | Código de cliente o grupo |     |
| sp_identico | Int | 4   | NULL | No aplica |     |
| sp_producto | Varchar | 10  | NULL | Código de producto |     |
| sp_poliza | Varchar | 24  | NULL | Número de póliza de seguro |     |
| sp_tramite_d | Int | 4   | NULL | Número de trámite al que está atada la póliza |     |
| sp_estado | Varchar | 64  | NULL | Estado de la póliza |     |
| sp_comentario | Varchar | 64  | NULL | Comentario de ingreso de la póliza |     |
| sp_aseguradora | Varchar | 64  | NULL | Nombre de la aseguradora |     |
| sp_tipo_pol | Varchar | 10  | NULL | Tipo de Póliza |     |
| sp_desc_pol | Varchar | 64  | NULL | Descripción de la Póliza |     |
| sp_fecha_ven | Varchar | 10  | NULL | Fecha de vencimiento de la póliza |     |
| sp_anualidad | Money | 8   | NULL | Costo de anualidad. |     |
| sp_endoso | Money | 8   | NULL | Valor de endoso |     |
| sp_endoso_ml | Money | 8   | NULL | Valor de endoso en moneda local |     |
| sp_codigo | Varchar | 64  | NULL | Código compuesto de garantía asociada a la póliza |     |
| sp_moneda | Tinyint | 1   | NULL | Código de moneda |     |
| sp_sec_poliza | Int | 4   | NULL | Secuencial numérico de póliza |     |
| sp_tipo_deuda | Char | 1   | NULL | Tipo de crédito | D= Directo<br><br>C= Contingente |
| sp_avaluo | Char | 1   | NULL | Valor de avalúo de la garantía |     |
| sp_fechaCancelacion | Datetime | 8   | NULL | Fecha de cancelación de la gtia |     |
| sp_fechaActivacion | Datetime | 8   | NULL | Fecha de Activación de la gtia |     |

### cr_temp4_tmp (No se usa en esta versión)

Registra temporalmente las operaciones de comercio exterior. Usada en la VCC

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | Smallint | 2   | NOT NULL | Identificación de proceso de usuario actual |     |
| por_vencer | Money | 8   | NULL | Saldo por vencer de operación |     |
| por_vencer_me | Money | 8   | NULL | Saldo por vencer de operación en el mes |     |
| vencido | Money | 8   | NULL | Saldo de capital vencido de operación |     |
| tipo_riesgo | Varchar | 16  | NULL | Tipo de riesgo |     |
| toperacion | Varchar | 26  | NULL | Tipo de operación |     |
| tramite | Int | 4   | NULL | Número del trámite. |     |
| en_tramite | Char | 1   | NULL | Identifica si es un trámite o no | S= Es trámite<br><br>N= No es trámite |
| disponible | Money | 8   | NULL | Monto disponible de la inversión |     |

### cr_tinstruccion (Deprecated)

Parametrización de tipo de instrucciones.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ti_codigo | Varchar | 10  | NOT NULL | Código de tipo de instrucción operativa |     |
| ti_descripcion | Varchar | 64  | NULL | Descripción de instrucción operativa |     |
| ti_aprobacion | Char | 1   | NOT NULL | Tipo de aprobación | E= Estación<br><br>N= Nivel<br><br>M= Monto<br><br>O= Otros |
| ti_nivel_ap | Varchar | 10  | NULL | Nivel que aprueba la instrucción |     |

### cr_tipo_tramite

Parametrización de los distintos tipos de trámite que soporta crédito, no tiene mantenimiento por front end ya que es una tabla que está relacionada con la funcionalidad programada.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tt_tipo | Char | 1   | NOT NULL | Código de tipo de trámite |     |
| tt_descripcion | Varchar | 64  | NOT NULL | Descripción de tipo de trámite |     |
| tt_prioridad | Tinyint | 1   | NOT NULL | Dígito de prioridad |     |

### cr_tmp_datooper (No se usa en esta versión)

Datos temporales para información intermedia en proceso de extracción de operaciones para proceso de reportes regulatorios.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tramite | Int | 4   | NOT NULL | Número de trámite |     |
| operacion | Int | 4   | NOT NULL | Código numérico de operación |     |
| saldo | Money | 8   | NOT NULL | Saldo de operación |     |
| cap_por_vencer | Money | 8   | NOT NULL | Saldo por vencer de operación |     |
| cap_vencido | Money | 8   | NOT NULL | Saldo de capital vencido de operación |     |
| cap_vendido | Money | 8   | NOT NULL | Monto de capital vendido de operación |     |
| int_por_vencer | Money | 8   | NOT NULL | Saldo de interés por vencer |     |
| int_vencido | Money | 8   | NOT NULL | Saldo de interés vencido |     |
| int_vendido | Money | 8   | NOT NULL | Saldo de interés vendido |     |
| otros_vendidos | Money | 8   | NOT NULL | Saldo de otros rubros vendidos |     |
| demanda | Money | 8   | NOT NULL | Saldo en demanda judicial |     |
| castigado | Money | 8   | NOT NULL | Saldo castigado |     |
| resolucion | Money | 8   | NOT NULL | Saldo en estado no devenga intereses |     |
| moneda | Tinyint | 1   | NOT NULL | Código de moneda |     |
| tasa_interes | Float | 8   | NOT NULL | Tasa de interés |     |
| tipo_garantias | Char | 24  | NOT NULL | Tipo de garantía |     |
| valor_garantias | Money | 8   | NOT NULL | Valor de garantía |     |
| toperacion | Char | 10  | NOT NULL | Tipo de operación |     |
| fecha_const_gar | Datetime | 8   | NOT NULL | Fecha de constitución de la garantía |     |
| desembolso | Money | 8   | NOT NULL | Valor de desembolso |     |
| estado | Int | 4   | NOT NULL | Estado de la operación |     |
| origen_fondos | Varchar | 10  | NOT NULL | Catálogo de origen de fondos |     |
| tipo_fondo | Char | 1   | NOT NULL | Tipo de origen de fondos |     |
| linea_credito | Char | 20  | NOT NULL | Código compuesto de línea de crédito |     |
| rotativo | Char | 1   | NOT NULL | Característica de rotativa o no |     |
| gar_deposito | Money | 8   | NULL | Monto en depósito en garantía |     |
| otros_rubros | Money | 8   | NULL | Saldo de otros rubros |     |
| via_judicial | Char | 1   | NULL | Operación en demanda judicial | S= Demanda judicial<br><br>N= No está en demanda judicial |
| vendida | Char | 1   | NULL | Cartera vendida | S= Cartera vendida<br><br>N= Cartera no vendida |
| oficial | Smallint | 2   | NULL | Código de oficial |     |
| tdividendo | Varchar | 10  | NULL | Tipo de dividendo |     |
| periodo_cap | Smallint | 2   | NULL | Período de capital |     |
| periodo_int | Smallint | 2   | NULL | Período de interés |     |
| reestru | Varchar | 1   | NULL | Tipo de trámite |     |
| descripcion | Varchar | 64  | NULL | Descripción de tipo de operación |     |
| operacion_migrada | Varchar | 24  | NULL | Código de operación migrada |     |
| feci_xvencer | Money | 8   | NULL | Saldo de rubro FECI por vencer |     |
| feci_vencido | Money | 8   | NULL | Saldo de rubro FECI vencido |     |
| seg_vida_xvencer | Money | 8   | NULL | Saldo de seguro de vida por vencer |     |
| seg_vida_vencido | Money | 8   | NULL | Saldo de seguro de vida vencido |     |
| seg_incendio_xvencer | Money | 8   | NULL | Saldo de seguro de incendio por vencer |     |
| seg_incendio_vencido | Money | 8   | NULL | Saldo de seguro de incendio vencido |     |
| seg_auto_xvencer | Money | 8   | NULL | Saldo de seguro auto por vencer |     |
| seg_auto_vencido | Money | 8   | NULL | Saldo de seguro auto vencido |     |
| subsidio | Char | 1   | NULL | Tiene subsidio | S= Tiene subsidio<br><br>N= No tiene subsidio |
| porcentaje_subsidio | Float | 8   | NULL | Porcentaje de subsidio |     |
| fecha_ult_reestru | Datetime | 8   | NULL | Fecha de última reestructuración |     |
| fecha_cambio_est_con | Datetime | 8   | NULL | Fecha de cambio de estado contable |     |
| otros_rubros_por_vencer | Money | 8   | NULL | Saldo de otros rubros por vencer |     |
| otros_rubros_vencido | Money | 8   | NULL | Saldo de otros rubros vencidos |     |
| linea_credito_tc | Char | 24  | NULL | Código compuesto de línea de tarjeta de crédito |     |
| mes_gracia | Tinyint | 1   | NULL | Mes de gracia |     |
| forma_pago_capital | Varchar | 10  | NULL | Forma de pago capital |     |
| forma_pago_interes | Varchar | 10  | NULL | Forma de pago interés |     |
| codigo_empresa_planilla | Varchar | 10  | NULL | Código de la empresa de la planilla que generó la operación |     |
| nombre_empresa_planilla | Varchar | 60  | NULL | Nombre de la empresa de la planilla que generó la operación |     |
| numero_planilla | Varchar | 10  | NULL | Número de planilla |     |
| fecha_prox_cuota | Datetime | 8   | NULL | Fecha de próximo pago de cuota |     |
| monto_prox_cuota | Money | 8   | NULL | Monto de próximo pago de cuota |     |
| fecha_prox_capital | Datetime | 8   | NULL | Fecha de próximo pago de capital |     |
| monto_prox_capital | Money | 8   | NULL | Monto de próximo pago de capital |     |
| fecha_prox_interes | Datetime | 8   | NULL | Fecha de próximo pago de interés |     |
| monto_prox_interes | Money | 8   | NULL | Monto próximo pago de interés |     |
| monto_prox_feci | Money | 8   | NULL | Monto próximo pago de rubro FECI |     |
| monto_prox_seg_vida | Money | 8   | NULL | Monto próximo pago de seguro de vida |     |
| monto_prox_seg_incendio | Money | 8   | NULL | Monto próximo pago de seguro de incendio |     |
| monto_prox_seg_desempleo | Money | 8   | NULL | Monto próximo pago de seguro de desempleo |     |
| monto_prox_seg_auto | Money | 8   | NULL | Monto próximo pago de seguro de auto |     |
| n_pagos_por_vencer | Int | 4   | NULL | Número de pagos por vencer |     |
| n_pagos_por_vencer_c | Int | 4   | NULL | Número de pagos de capital por vencer |     |
| n_pagos_por_vencer_i | Int | 4   | NULL | Número de pagos de interés por vencer |     |
| fecha_ult_capital | Datetime | 8   | NULL | Fecha de último pago de capital |     |
| monto_ult_capital | Money | 8   | NULL | Monto de último pago de capital |     |
| fecha_ult_interes | Datetime | 8   | NULL | Fecha de último pago de interés |     |
| monto_ult_interes | Money | 8   | NULL | Monto de último pago de interés |     |
| monto_ult_feci | Money | 8   | NULL | Monto de último pago de rubro FECI |     |
| monto_ult_seg_vida | Money | 8   | NULL | Monto de último pago de seguro de vida |     |
| monto_ult_seg_incendio | Money | 8   | NULL | Monto de último pago de seguro de incendio |     |
| monto_ult_seg_auto | Money | 8   | NULL | Monto de último pago de seguro de auto |     |
| tipo_amortizacion | Varchar | 10  | NULL | Tipo de tabla de amortización |     |
| cuota | Money | 8   | NULL | Valor de la cuota |     |
| fecha_ult_pago | Datetime | 8   | NULL | Fecha de último pago de cuota |     |
| monto_ult_pago | Money | 8   | NULL | Monto de último pago de cuota |     |
| tipo | Char | 1   | NULL | Tipo de operación |     |
| n_pagos_vencidos_c | Int | 4   | NULL | Número de pagos vencidos de capital |     |
| n_pagos_vencidos_i | Int | 4   | NULL | Número de pagos vencidos de interés |     |
| dividendo_vig | Smallint | 2   | NULL | Número de dividendos vigentes |     |

### cr_toperacion

Parametrización de tipos de operación que se utilizarán en el módulo de trámites y que deben tener parametrización en el módulo de cartera.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| to_toperacion | Varchar | 10  | NOT NULL | Código de tipo de operación |     |
| to_producto | Varchar | 10  | NOT NULL | Código de producto |     |
| to_descripcion | Varchar | 64  | NOT NULL | Descripción del tipo de operación |     |
| to_estado | Varchar | 10  | NOT NULL | Estado del tipo de operación |     |
| to_riesgo | Varchar | 10  | NULL | Monto de riesgo máximo |     |
| to_codigo_sib | Varchar | 10  | NULL | Código de tipo de operación de la entidad de control |     |

### cr_tr_castigo (No se usa en esta versión)

Registra las operaciones que están en proceso de castigo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ca_int_proceso | int | 4   | not null | Codigo de la Instancia de proceso(workflow) |     |
| ca_tramite | int | 4   | not null | Codigo del trámite |     |
| ca_fecha_corte | datetime | 8   | not null | Fecha de ejecución del proceso de castigo |     |
| ca_banco | cuenta | 24  | not null | Numero largo de operación de cartera |     |
| ca_cliente | int | 4   | not null | Código del cliente |     |
| ca_agencia | smallint | 2   | not null | Agecia del tramite |     |
| ca_estado | char | 1   | not null | Estado del registro |     |
| ca_problema | varchar | 255 | null | Descripción del problema |     |
| ca_imposibilidad_pago | varchar | 255 | null | Descripcion del porque no se ejecutaron los pagos(1) |     |
| ca_razones | varchar | 255 | null | Razón por la cual entra el proceso de castigo(1) |     |
| ca_coherencia | varchar | 255 | null | Coherencia del tramite |     |
| ca_observacion | varchar | 255 | null | Observación del oficial |     |
| ca_regional | char | 10  | null | Regional del trámite |     |
| ca_subregional | char | 10  | null | Sub-Regional del trámite |     |
| ca_ambito | char | 10  | null | Ambito del trámite |     |
| ca_razones2 | varchar | 255 | Null | Razón por la cual entra el proceso de castigo(2-Continuación) |     |
| ca_razones3 | varchar | 255 | Null | Razón por la cual entra el proceso de castigo(3-Continuación) |     |
| ca_imposibilidad_pago2 | varchar | 255 | Null | Descripcion del porque no se ejecutaron los pagos(2-Continuación) |     |
| ca_imposibilidad_pago3 | varchar | 255 | null | Descripcion del porque no se ejecutaron los pagos(3-Continuación) |     |

### cr_tr_datos_adicionales (No se usa en esta versión)

Registra características adicionales que se quieren ingresar para una solicitud de crédito y que no están soportadas en la maestra: cr_tramite.

Actualmente para Finca no se está llenando.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tr_tramite | int | 4   | &nbsp; | Número de Tramite |     |
| tr_tipo_cartera | catalogo | &nbsp; | &nbsp; | Tipo de Crédito |     |
| tr_mes_cic | int | 4   | &nbsp; | Mes fecha CIC |     |
| tr_anio_cic | int | 4   | &nbsp; | Año fecha CIC |     |
| tr_patrimonio | money | &nbsp; | &nbsp; | Patrimonio de la Actividad Principal del Cliente |     |
| tr_ventas | money | &nbsp; | &nbsp; | Ventas anuales del Cliente |     |
| tr_num_personal_ocupado | int | 4   | &nbsp; | Número de Empleados de la Actividad del Cliente |     |
| tr_indice_tamano_actividad | int | 4   | &nbsp; | Tamaño del Índice de la Actividad Principal del Cliente |     |
| tr_tipo_credito | float | 16  | &nbsp; | Tipo de Crédito |     |
| tr_objeto | catalogo | 10  | &nbsp; | Objeto del Crédito |     |
| tr_actividad | catalogo | 10  | &nbsp; | Actividad del Cliente |     |
| tr_destino_descripcion | descripcion | &nbsp; | &nbsp; | Detalle del Destino del Crédito |     |
| tr_descripcion_oficial | descripcion | &nbsp; | &nbsp; | Descripción que ingresa el Oficial |     |
| tr_activos_productivos | money | &nbsp; | &nbsp; | Valor de los activos Productivos del Cliente |     |
| tr_nivel_endeuda | char | 1   | &nbsp; | Indicador si el Nivel de Deuda a Superado el valor permitido |     |
| tr_convenio | char | 1   | &nbsp; | Valor si el Cliente tiene un Convenio con el Banco |     |
| tr_codigo_convenio | varchar | 10  | &nbsp; | Código del Convenio asociado al Cliente |     |
| tr_observacion_reprog | varchar | 255 | &nbsp; | Observación que se ingresa para la Reprogramación |     |
| tr_motivo_uno | varchar | 255 | &nbsp; | Motivo de Cancelación del Tramite |     |
| tr_motivo_dos | varchar | 225 | &nbsp; | Motivo de Cancelación del Tramite |     |
| tr_motivo_rechazo | varchar | 10  | &nbsp; | Código del Motivo Cancelación del Tramite |     |
| tr_tamano_empresa | catalogo | 10  | &nbsp; | Tamaño de empresa que tiene el Cliente |     |
| tr_en_aprobacion | char | 1   | &nbsp; | Indicador si el trámite se encuentra en etapa de Aprobación |     |
| tr_producto_fie | catalogo | 10  | &nbsp; | Código de Producto FIE |     |
| tr_num_viviendas | tinynt | &nbsp; | &nbsp; | Número de viviendas para Crédito de Vivienda |     |
| tr_tipo_calificacion | catalogo | &nbsp; | &nbsp; | Calificación otorgada al Cliente |     |
| tr_calificacion | catalogo | &nbsp; | &nbsp; | Calificación otorgada por la Central de Riesgos (ASFI) |     |
| tr_es_garantia_destino | char | 1   | &nbsp; | Identificador si la garantía es el destino del crédito |     |
| tr_es_deudor_propietario | char | 1   | &nbsp; | Identificador si el deudor es el propietario de la garantía |     |
| tr_actividad_principal | varchar | 10  | &nbsp; | Código de la actividad Principal del Cliente |     |
| tr_tasa | float | &nbsp; | &nbsp; | Campo Auxiliar que contiene la Tasa del Crédito |     |
| tr_sub_actividad | catalogo | &nbsp; | &nbsp; | Sub actividad del Cliente |     |
| tr_departamento | catalogo | 10  | &nbsp; | Código del Departamento de emisión del tramite |     |
| tr_credito_es | catalogo | &nbsp; | &nbsp; | Si es Crédito Nuevo o por Compra de Cartera |     |
| tr_financiado | char | 1   | &nbsp; | Indicador si el Crédito es Financiado |     |
| tr_presupuesto | money | &nbsp; | &nbsp; | Valor del presupuesto que posee el Cliente para adquisición de Vivienda |     |
| tr_fecha_avaluo | datetime | &nbsp; | &nbsp; | Fecha de Avaluó del bien a adquirir el Cliente |     |
| tr_valor_comercial | money | &nbsp; | &nbsp; | Valor Comercial del Bien a adquirir |     |

### cr_tramite

Mantenimiento de trámites o solicitudes de crédito ingresados en el módulo de crédito, contiene toda la información del trámite, es la tabla maestra del módulo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tr_tramite | Int | 4   | NOT NULL | Número de trámite | &nbsp; |
| tr_tipo | Char | 1   | NOT NULL | Tipo de trámite | O: original individual o grupal<br><br>L: linea<br><br>G: modificatorio garantía<br><br>E: reestructuración<br><br>R: refinanciamiento, renovación |
| tr_oficina | Smallint | 2   | NOT NULL | Código de oficina | &nbsp;(cl_oficina) |
| tr_usuario | Varchar | 14  | NOT NULL | Login de usuario de ingreso de trámite | &nbsp;(cl_funcionario)\*\* |
| tr_fecha_crea | Datetime | 8   | NOT NULL | Fecha de creación de registro | &nbsp; |
| tr_oficial | Smallint | 2   | NOT NULL | Código de oficial del cliente | &nbsp; |
| tr_sector | Varchar | 10  | NOT NULL | Catálogo de sector | &nbsp;(cc_sector) |
| tr_ciudad | Int | 4   | NOT NULL | Código de ciudad | &nbsp;(cl_ciudad) |
| tr_estado | Char | 1   | NOT NULL | Estado de trámite | A - Aprobado |
| N - No Aprobado |
| Z - Cancelado |
| tr_nivel_ap | tinyint | &nbsp; | &nbsp;NULL | &nbsp;No se usa | &nbsp; |
| tr_fecha_apr | Datetime | &nbsp; | &nbsp;NULL | &nbsp;Fecha aprobación solicitud | &nbsp; |
| tr_usuario_apr | login | &nbsp; | &nbsp;NULL | &nbsp;Usuario que aprueba | &nbsp;(cl_funcionario)\*\* |
| tr_numero_op | Int | 4   | NULL | Código numérico secuencial de operación generada por el trámite | &nbsp; |
| tr_numero_op_banco | Varchar | 24  | NULL | Código de operación generada por cartera en el desembolso | &nbsp; |
| tr_riesgo | money | 8   | NULL | No se usa en esta versión | &nbsp; |
| tr_aprob_por | login | 14  | NULL | No se usa en esta versión | &nbsp; |
| tr_nivel_por | tinyint | 1   | NULL | No se usa en esta versión | &nbsp; |
| tr_comite | catalogo | 10  | NULL | No se usa en esta versión | &nbsp; |
| tr_acta | cuenta | 24  | NULL | &nbsp;No se usa en esta versión | &nbsp; |
| tr_proposito | Varchar | 10  | NULL | No se usa en esta versión | &nbsp; |
| tr_razon | Varchar | 10  | NULL | Razón del modificatorio de garantía | &nbsp; |
| tr_txt_razon | Varchar | 255 | NULL | Razón del modificatorio de garantía | &nbsp; |
| tr_efecto | Varchar | 10  | NULL | No se usa en esta versión | &nbsp; |
| tr_cliente | Int | 4   | NULL | Código de cliente deudor del trámite | &nbsp; |
| tr_nombre | &nbsp; | 64  | NULL | &nbsp;No se usa en esta versión | &nbsp; |
| tr_grupo | Int | 4   | NULL | Código de grupo del trámite | &nbsp; |
| tr_fecha_inicio | Datetime | 8   | NULL | Fecha de inicio de la solicitud | &nbsp; |
| tr_num_dias | Smallint | 2   | NULL | Plazo en número de días para líneas de crédito | &nbsp; |
| tr_per_revision | Varchar | 10  | NULL | No se usa en esta versión. | &nbsp; |
| tr_condicion_especial | Varchar | 255 | NULL | No se usa en esta versión. | &nbsp; |
| tr_linea_credito | Int | 4   | NULL | Código numérico de línea de crédito cuando se instrumenta | &nbsp; |
| tr_toperacion | Varchar | 10  | NULL | Código de tipo de operación | &nbsp; |
| tr_producto | Varchar | 10  | NULL | Código de producto. | &nbsp;CCA: Cartera<br><br>CEX: comercio exterior |
| tr_monto | Money | 8   | NULL | Monto de trámite | &nbsp;Monto aprobado de la solicitud |
| tr_moneda | Tinyint | 1   | NULL | Código de moneda | &nbsp;Moneda de la solicitud (cl_moneda)\*\* |
| tr_periodo | Varchar | 10  | NULL | Código de período | &nbsp;(ca_tdividendo) |
| tr_num_periodos | Smallint | 2   | NULL | Número de períodos | &nbsp; |
| tr_destino | Varchar | 10  | NULL | Código de destino | &nbsp;(cr_objeto) |
| tr_ciudad_destino | Int | 4   | NULL | Código de ciudad destino del préstamo | &nbsp;(cl_ciudad) |
| tr_cuenta_corriente | &nbsp;cuenta | &nbsp; | NULL | No aplica en esta versión | &nbsp; |
| tr_renovacion | Smallint | 2   | NULL | Número de renovación | &nbsp; |
| tr_fecha_concesion | Datetime | 8   | NULL | Fecha de concesión del préstamo | &nbsp; |
| tr_rent_actual | float | 8   | NULL | No aplica en esta versión | &nbsp; |
| tr_rent_solicitud | float | 8   | NULL | No aplica en esta versión | &nbsp; |
| tr_rent_recomend | float | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_prod_actual | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_prod_solicitud | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_prod_recomend | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_clase | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_admisible | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_noadmis | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_relacionado | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_pondera | float | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_contabilizado | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_subtipo | Char | 1   | NULL | Subtipo de línea para el tipo de trámite línea de crédito | &nbsp; |
| tr_tipo_producto | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_origen_bienes | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_localizacion | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_plan_inversion | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_naturaleza | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_tipo_financia | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_sobrepasa | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_elegible | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_forward | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_emp_emisora | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_num_acciones | smallint | 2   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_responsable | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_negocio | cuenta | 24  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_reestructuracion | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_concepto_credito | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_aprob_gar | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_cont_admisible | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_mercado_objetivo | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_tipo_productor | varchar | 24  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_valor_proyecto | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_sindicado | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_asociativo | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_margen_redescuento | float | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_ap_ant | datetime | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_llave_redes | cuenta | 24  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_incentivo | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_eleg | datetime | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_op_redescuento | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_redes | datetime | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_solicitud | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_montop | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_monto_desembolsop | money | 8   | NULL | &nbsp;Monto desembolsado | &nbsp; |
| tr_mercado | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_dias_vig | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_cod_actividad | catalogo | 10  | NULL | &nbsp;Actividad a la que se destina el crédito | &nbsp; |
| tr_num_desemb | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_carta_apr | varchar | 64  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_aprov | datetime | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fmax_redes | datetime | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_f_prorroga | datetime | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_nlegal_fi | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fechlimcum | datetime | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_validado | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_sujcred | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fabrica | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_callcenter | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_apr_fabrica | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_monto_solicitado | Money | 5   | NULL | Monto solicitado por el cliente | &nbsp; |
| tr_tipo_plazo | catalogo | 10  | NULL | &nbsp;Tipo de dividendo | &nbsp; |
| tr_tipo_cuota | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_plazo | Smallint | 2   | NULL | Plazo del trámite | &nbsp; |
| tr_cuota_aproximada | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fuente_recurso | varchar | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_tipo_credito | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_migrado | varchar | 16  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_estado_cont | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_fija | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_dia_pago | tinyint | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_tasa_reest | float | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_motivo | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_central | varchar | 2   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_devuelto_mir | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_campana | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_alianza | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_autoriza_central | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_act_financiar | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_negado_mir | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_num_devri | int | 4   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_promocion | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_acepta_ren | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_no_acepta | char | 1000 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_emprendimiento | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_porc_garantia | float | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_grupal | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_experiencia | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_monto_max | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_monto_min | money | 8   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_dispersion | datetime | 8   | NULL | Fecha desembolso | &nbsp; |
| tr_causa | char | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_irenova | datetime | 8   | NULL | Fecha de trámite | &nbsp; |
| tr_linea_cancelar | Int | 4   | NULL | Código numérico de línea a cancelar cuando es renovación. No aplica | &nbsp; |
| tr_tasa_asociada | Char | 1   | NULL | No aplica en esta versión | S= Tiene tasa asociada<br><br>N= No tiene tasa asociada |
| tr_frec_pago | Varchar | 10  | NULL | Frecuencia de Pago | &nbsp; (ca_tdividendo) |
| tr_moneda_solicitada | Tinyint | 1   | NULL | Moneda solicitada por el cliente | &nbsp;(cl_moneda) |
| tr_provincia | Int | 4   | NULL | Provincia donde se genera el trámite | &nbsp;(cl_provincia) |
| tr_monto_desembolso | Money | 5   | NULL | Monto a desembolsar | &nbsp; |
| tr_tplazo | Varchar | 10  | NULL | &nbsp;Tipo de plazo operación | &nbsp; |
| tr_cuota | Money | 5   | NULL | Cuota | &nbsp; |
| tr_proposito_op | Varchar | 10  | NULL | Catálogo de propósito de operación | &nbsp; |
| tr_lin_comext | Varchar | 24  | NULL | Código compuesto de la ínea de las operaciones de COMEXT. No aplica | &nbsp; |
| tr_expromision | Varchar | 10  | NULL | Determina si el proceso es expromisión. No aplica | &nbsp; |
| tr_origen_fondos | Varchar | 10  | NULL | Catálogo de origen de fondos | &nbsp;(cr_origen_fondo) |
| tr_sector_cli | Varchar | 10  | NULL | No aplica en esta versión | &nbsp; |
| tr_truta | tinyint | 1   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_secuencia | smallint | 2   | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_sector_contable | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_enterado | catalogo | 10  | NULL | &nbsp;Catálogo de como se enteró de Finca | &nbsp;(cl_enterado) |
| tr_otros | varchar | 64  | NULL | &nbsp;Descripción de campo otros, sirve para describir en que se usará el dinero. | &nbsp; |
| tr_periodicidad_lcr | catalogo | 10  | NULL | &nbsp;No aplica en esta versión | &nbsp; |

### cr_tramite_grupal

Guarda la relación entre el trámite grupal y los trámites hijos

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tg_tramite | int |     | NOT NULL | Número de solicitud de crédito grupal |     |
| tg_grupo | int |     | NOT NULL | Código del grupo |     |
| tg_cliente | int |     | NOT NULL | Código del cliente |     |
| tg_monto | money |     | NOT NULL | Monto aprobado para el integrante. |     |
| tg_grupal | char(1) | 1   | NOT NULL | Es un trámite grupal | Siempre en S |
| tg_operacion | int |     | NULL | Secuencial de la operación de cartera |     |
| tg_prestamo | varchar(15) | 15  | NULL | Número largo de la operación de cartera. |     |
| tg_referencia_grupal | varchar(15) | 15  | NULL | Número largo de la operación grupal. |     |
| tg_cuenta | varchar(45) | 45  | NULL | Número de la cuenta de ahorros del cliente. No aplica |     |
| tg_cheque | int |     | NULL | No aplica en esta versión |     |
| tg_participa_ciclo | char(1) | 1   | NULL | Indica que el integrante participa en la solicitud grupal. | S: SI participa<br><br>N: NO participa |
| tg_monto_aprobado | money |     | NULL | Monto solicitado por el integrante |     |
| tg_ahorro | money |     | NULL | No aplica en esta versión. |     |
| tg_monto_max | money |     | NULL | No aplica en esta versión. |     |
| tg_bc_ln | char(10) | 10  | NULL | No aplica en esta versión. |     |
| tg_incremento | numeric(8,4) | 8   | NULL | No aplica en esta versión. |     |
| tg_monto_ult_op | money |     | NULL | No aplica en esta versión. |     |
| tg_monto_max_calc | money |     | NULL | No aplica en esta versión. |     |
| tg_nueva_op | int |     | NULL | No aplica en esta versión. |     |
| tg_monto_min_calc | money |     | NULL | No aplica en esta versión. |     |
| tg_conf_grupal | char(1) | 1   | NULL | No aplica en esta versión. |     |
| tg_destino | catalogo |     | NULL | Código del destino de la operación. | (cl_subactividad_ec) |
| tg_sector | catalogo |     | NULL | Código del sector de la operación |     |
| tg_monto_recomendado | money |     | NULL | Monto recomendado |     |
| tg_estado | char(1) |     | S   | Estado de la operación hija |     |
| tg_id_rechazo | catalogo |     | NULL | Causa de rechazo de la operación del integrante. | (cr_motivo_rechazo) |
| tg_descripcion_rechazo | descripcion |     | NULL | Descripción de la causa de rechazo de la operación del integrante. |     |

### cr_truta (Deprecated)

Mantenimiento de tipos de rutas.

| Campo | Tipo | Longitud | Requerido |     | Descripción | Descripción Funcional |
| --- | --- | --- | --- |     | --- | --- |
| ru_truta | Tinyint | 1   | NOT NULL | Código de tipo de ruta |     |     |
| ru_descripcion | Varchar | 64  | NOT NULL | Descripción de la ruta |     |     |
| ru_tipo | Char | 1   | NULL | Tipo de ruta |     | O= Original<br><br>R= Renovación<br><br>P= Otros |
| ru_directa | Char | 1   | NULL | Ruta directa a desembolso |     | S= Desembolso<br><br>N= No desembolsar |
| ru_oficina | Smallint | 2   | NULL | Código de oficina |     |     |

### cr_valor_variables (Deprecated)

Registro del valor de cada variable que se va asignando en el proceso de ruteo de la solicitud de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| vv_tramite | Int | 4   | NOT NULL | Número de trámite |     |
| vv_variable | Tinyint | 1   | NOT NULL | Código de variable |     |
| vv_valor | Varchar | 20  | NULL | Valor de la variable |     |

### tmp_garantias

Tabla temporal de garantías que se usa en el proceso de desembolso.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gp_ssn | Int | 4   | NOT NULL | Código de oficina |     |
| gp_user | Varchar | 14  | NOT NULL | Número de trámite |     |
| gp_garantia | Varchar | 24  | NOT NULL | Tipo de operación |     |
| gp_opcion | Char | 1   | NOT NULL | Código de cliente |     |

### xx_tmp

Es una tabla auxiliar que sirve para la actualización de los montos utilizados en las líneas de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | Smallint | 2   | NOT NULL | Identificación de proceso de usuario actual. |     |
| toperacion | Varchar | 10  | NULL | Tipo de operación |     |
| producto | Varchar | 10  | NULL | Código del producto |     |
| proposito_op | Varchar | 10  | NULL | Propósito de la operación |     |
| moneda | Tinyint | 1   | NULL | Código de la moneda |     |
| utilizado | Money | 8   | NULL | Monto utilizado de la facilidad |     |

### cr_transaccion_linea

Tabla que almacena las transacciones de la líneas de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tl_linea | int | 4   | not null | Numero único de la linea. |     |
| tl_secuencial | int | 4   | not null | Secuencial único de tabla. |     |
| tl_fecha_tran | datetime | 8   | not null | Fecha de transacción. |     |
| tl_transaccion | catalogo | 10  | not null | Transaccion. |     |
| tl_moneda | tinyint | 1   | not null | Código de la moneda. |     |
| tl_valor | float | 8   | not null | Monto de la transacción. |     |
| tl_valor_ref | float | 8   | not null | Monto de referencia de la transacción. |     |
| tl_estado | char(3) | 3   | not null | Estado de la transacción. |     |
| tl_operacion | int | 4   | null | Numero único de operación de cartera. |     |
| tl_oficina | smallint | 2   | null | Oficina de la transacción. |     |
| tl_usuario | login | 14  | null | Login de usuario que realiza la transacción. |     |
| tl_terminal | descripcion | 160 | null | Terminal desde donde se realiza la transacción. |     |
| tl_secuencial_ref | int | 4   | null | Secuencial de referencia. |     |
| tl_pgroup | catalogo | 10  | null | No se utiliza. |     |
| tl_comprobante | int | 4   | null | Número de comprobante contable. |     |
| tl_fecha_cont | datetime | 8   | null | No se utiliza. |     |

### cr_det_transaccion_linea

Tabla que almacena el detalle de las transacciones de las líneas de crédito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dtl_linea | int | 4   | not null | Numero único de la linea. |     |
| dtl_secuencial | int | 4   | not null | Secuencial único de tabla. |     |
| dtl_fecha_tran | datetime | 8   | not null | Fecha de transacción. |     |
| dtl_concepto | catalogo | 10  | null | Concepto de la transacción. |     |
| dtl_valor | money | 8   | not null | Monto de la transacción. |     |
| dtl_moneda | tinyint | 1   | not null | Código de la moneda. |     |
| dtl_oficina | smallint | 2   | not null | Oficina de la transacción. |     |
| dtl_valor_mn | money | 8   | not null | Monto en moneda nacional. |     |
| dtl_cotizacion | float | 8   | not null | Cotización de moneda. |     |

### cr_gasto_linea

Es una tabla que almacena los gastos de las líneas de credito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gl_linea | int | 4   | not null | Numero único de la linea. |     |
| gl_sec | int | 4   | not null | Secuencial único de tabla. |     |
| gl_tipo | catalogo | 10  | not null | Tipo de gasto. |     |
| gl_codigo | catalogo | 10  | not null | Codigo de gasto. |     |
| gl_monto | money | 8   | null | Monto. |     |
| gl_porcentaje | float(53) | 8   | null | Porcentaje de cupo. |     |
| gl_forma_pago | catalogo | 10  | null | Forma de pago. |     |
| gl_cuenta | cuenta | 24  | null | Numero de línea. |     |
| gl_cliente | int | 4   | null | Numero único de cliente. |     |
| gl_fecha | datetime | 8   | null | Fecha de gasto. |     |
| gl_estado | char(1) | 1   | null | Estado. |     |

### cr_estado_linea

Es una tabla que almacena los estados de las líneas de credito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| el_tipo | char(1) | 1   | not null | Tipo de estado. |     |
| el_codigo | catalogo | 10  | not null | Codigo de estado. |     |
| el_desembolso | char(1) | 1   | null | Bandera de desembolso S o N. |     |
| el_cambio_plazo | char(1) | 1   | null | Bandera de cambio de plazo S o N. |     |
| el_acumula_dias | char(1) | 1   | null | Bandera de acumulación de días S o N. |     |
| el_trn_autoriza | int | 4   | null | Numero de autorización. |     |
| el_cambia_estado | char(1) | 1   | null | Bandera de cambio de estado S o N. |     |
| el_estado_nuevo | catalogo | 10  | null | Estado nuevo al realizar cambio. |     |
| el_pide_plazo | char(1) | 1   | null | Bandera de plazo S o N. |     |
| el_cambia_monto | char(1) | 1   | null | Bandera de cambio de monto S o N. |     |
| el_causal_ah | catalogo | 10  | null | No utilizado. |     |
| el_causal_cc | catalogo | 10  | null | No utilizado. |     |

### cr_clientes_credautomatico

Es una tabla que guarda los clientes que aplican a créditos automáticos.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cc_fecha | datetime | 8   | null | Fecha de almacenamiento. |     |
| cc_ente | int | 4   | null | Codigo de cliente. |     |

### cr_clientes_renovacion

Es una tabla que almacena los estados de las líneas de credito.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cr_fecha | datetime | 8   | null | Fecha de almacenamiento. |     |
| cr_ente | int | 4   | null | Codigo de cliente. |     |
| cr_num_banco | varchar(24 ) | 24  | null | Número largo de la operación de cartera. |     |
| cr_grupo | int | 4   | null | Codigo de grupo. |     |
| cr_toperacion | varchar(10) | 10  | null | Acronimo de tipo operación. |     |
| cr_oficial | int | 4   | null | Codigo de oficial. |     |

### cr_segmentacion_cliente

Se guardan los puntajes y resultados del proceso de segmentación que se ejecuta sobre los clientes con créditos activos.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sc_fecha | datetime | 8   | null | Fecha de almacenamiento. |     |
| sc_segmento | catalogo | 10  | null | Segmento de cliente. |     |
| sc_subsegmento | catalogo | 10  | null | Subsegmento de cliente. |     |
| sc_rango | catalogo | 10  | null | Rango de cliente. |     |
| sc_puntaje | int | N/A | null | Puntaje de cliente. |     |
| sc_ente | int | N/A | null | Código de cliente. |     |

### cr_cobranza_tmp

Se guardan los puntajes y resultados del proceso de segmentación que se ejecuta sobre los clientes con créditos activos.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ct_num_banco | cuenta | 24  | not null | Número largo de la operación de cartera. |     |
| ct_num_operacion | int | N/A | not null | Número de la operación de cartera. |     |
| ct_ente | int | N/A | null | Código de cliente. |     |
| ct_nombre_cliente | varchar(254) | 254 | null | Nombre completo de cliente. |     |
| ct_grupo | int | N/A | null | Código de grupo. |     |
| ct_nombre_grupo | varchar(254) | 254 | null | Nombre del grupo. |     |
| ct_dividendos_venc | int | N/A | null | Número de dividendos vencidos |     |
| ct_direccion_negocio | varchar(254) | 254 | null | Dirección de negocio. |     |
| ct_numero_telf | varchar(16) | 16  | null | Teléfono principal |     |
| ct_oficina | int | N/A | null | Código de oficina. |     |
| ct_fecha | date | 8   | null | Fecha de almacenamiento. |     |

### cr_cobranza_det_tmp

Se guardan los puntajes y resultados del proceso de segmentación que se ejecuta sobre los clientes con créditos activos.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cdt_num_banco | cuenta | 24  | not null | Número largo de la operación de cartera. |     |
| cdt_num_operacion | int | N/A | not null | Número de la operación de cartera. |     |
| cdt_dividendo | int | N/A | null | Número de dividendo vencido. |     |
| cdt_fecha_venc | datetime | N/A | null | Fecha de vencimiento. |     |
| cdt_monto_capital | money | N/A | null | Suma de capital vencido. |     |
| cdt_monto_interes | money | N/A | null | Suma de interés vencido. |     |
| cdt_monto_otros_rubros | money | N/A | null | Suma de otros rubros vencidos. |     |
| cdt_fecha | date | 8   | null | Fecha de almacenamiento. |     |

### cr_pago_solidario

Se guardan beneficiarios, clientes solidarios y montos de pagos solidarios.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ps_tramite_grupal | int | N/A | not null | Número de trámite grupal. |     |
| ps_num_operacion | cuenta | 24  | not null | Número largo de la operación de cartera. |     |
| ps_pago_solidario | int | N/A | not null | Identificador de pago solidario. |     |
| ps_ente_beneficiario | int | N/A | not null | Identificador de ente beneficiario. |     |
| ps_ente_solidario | int | N/A | not null | Identificador de ente solidario. |     |
| ps_monto_solidario | money | N/A | not null | Monto que se paga a la operación. |     |

### cr_causa_desercion

Se guarda el histórico de los registros de las causas de deserción de los clientes.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cd_id | int | N/A | null | Número del registro. |     |
| cd_ente | Int | 24  | null | Número del cliente. |     |
| cd_fecha | Date | N/A | null | Fecha del registro. |     |
| cd_obervacion | varchar | 500 | null | Observación registrada de la deserción. |     |
| cd_causa | catalogo | 10  | null | Causa de la deserción. | Catalogo: cr_causa_desercion |
| cd_severidad | catalogo | 10  | null | Criticidad de la deserción. | Catalogo: cr_criticidad_desercion |
| cd_usuario_ingreso | Login | 14  | null | Usuario que ingreso el registro. |     |
| cd_fecha_ingreso | datetime | N/A | null | Fecha de ingreso del registro. |     |
| cd_usuario_modifica | Login | 14  | null | Usuario que modificó el registro. |     |
| cd_fecha_modifica | datetime | N/A | null | Fecha de la modificación del registro. |     |

### cr_accion_desercion

Se guarda información sobre las acciones tomadas frente a una deserción.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ad_id | int | N/A | Not null | Número del registro. |     |
| ad_id_historial | Int | N/A | Not null | Número del histórico al que se hace referencia. |     |
| ad_fecha | datetime | N/A | Not null | Fecha de la acción tomada. |     |
| ad_accion | varchar | 500 | Not null | Texto que describe la acción tomada frente a la deserción. |     |
| ad_resultado | varchar | 500 | Not null | Texto que describe el resultado de la acción tomada frente a la deserción. |     |
| ad_usuario_ingreso | datetime | N/A | Not null | Usuario que ingreso el registro. |     |
| ad_usuario_modif | Login | 14  | null | Usuario que modificó el registro. |     |
| ad_fecha_modif | datetime | N/A | null | Fecha de la modificación del registro. |     |

### cr_buro_credito

Se guarda la información con respecto a la revisión de buró de credito de los clientes.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ts_secuencial | int | 4   | null | Secuencia de registro |     |
| ts_tipo_transaccion | smallint | 2   | not null | Código de transacción |     |
| ts_clase | char | 1   | not null | Clase de registro<br><br>I= Ingreso/Registro |     |
| ts_fecha | datetime | 8   | null | Fecha de inserción de registro de la transacción |     |
| ts_usuario | login | 14  | null | Login de usuario que ejecuta la transacción |     |
| ts_terminal | descripcion | 160 | null | Decripción de terminal |     |
| ts_oficina | smallint | 2   | null | Código de oficina |     |
| ts_tabla | varchar | 30  | null | Descripción de la tabla en la que se modificó el dato |     |
| ts_lsrv | varchar | 30  | null | Descripción del servidor local |     |
| ts_srv | varchar | 30  | null | Descripción del servidor |     |
| ts_smallint01 | smallint | 2   | null | Dato de tipo Smallint |     |
| ts_int01 | int | 4   | null | Dato de tipo Int |     |
| ts_fecha01 | datetime | 8   | null | Dato de tipo Datetime |     |
| ts_int02 | int | 4   | null | Dato de tipo Int |     |
| ts_money01 | money | 8   | null | Dato de tipo Money |     |
| ts_money02 | money | 8   | null | Dato de tipo Money |     |
| ts_money03 | money | 8   | null | Dato de tipo Money |     |
| ts_money04 | money | 8   | null | Dato de tipo Money |     |
| ts_vchar1001 | varchar | 10  | null | Dato de tipo Varchar(10) |     |
| ts_vchar1002 | varchar | 10  | null | Dato de tipo Varchar(10) |     |

### cr_cobros

Se guarda la información con respecto a la recuperación de la cartera que se hizo en campo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| co_secuencial | int | 4   | not null | Secuencia de registro de cobro |     |
| co_operacion | int | 4   | not null | Código numérico de operación. |     |
| co_banco | varchar | 24  | not null | Número largo de la operación de cartera. |     |
| co_ref_grupal | varchar | 24  | null | Número largo de la operación grupal. |     |
| co_cliente | int | 4   | not null | Código del cliente |     |
| co_grupo | int | 4   | null | Código de grupo |     |
| co_oficina | smallint | 2   | not null | Código de oficina |     |
| co_usuario | login | 14  | not null | Login de usuario asociado a la estación |     |
| co_oficial | smallint | 2   | not null | Código de oficial del cliente |     |
| co_recuperador | smallint | 2   | not null | Código de oficial recuperador |     |
| co_estado | catalogo | 10  | not null | Estado del cobro (cr_estado_cobro)<br><br>A-Aplicada<br><br>E-Error<br><br>NA-No Aplicada |     |
| co_fecha_recupera | datetime | 8   | not null | Fecha de recuperación |     |
| co_tipo_producto | catalogo | 10  | not null | Tipo de producto |     |
| co_monto_adeuda | money | 8   | not null | Monto que adeuda la operación al día |     |
| co_monto_recuperado | money | 8   | not null | Monto recuperado |     |
| co_ssn | int | 4   | null | Secuencial de conexión desde front end |     |
| co_hora_aplica | datetime | 8   | null | Hora de aplicación |     |
| co_fecha_aplica | datetime | 8   | null | Fecha de aplicación |     |
| co_usuario_aplica | login | 14  | null | Usuario de aplicación |     |

## Tablas de la base cob_credito_his

### cr_califica_int_mod_his (No se usa en esta versión)

No aplica

### cr_ruta_tramite (No se usa en esta versión)

Información consolidada de garantías, manejo histórico.

### cr_tramite_his (No se usa en esta versión)

Información consolidada de operaciones, manejo histórico

## Vistas y Transacciones de Servicios

### Transacciones de servicio

Cada módulo tiene una Base de Datos, la cual cuenta con una tabla de Transacciones de Servicio, en la que se incluyen todos los campos de todas las tablas que pueden sufrir modificación en la operación del módulo (inserción, actualización o eliminación). Se entiende por Vista de Transacciones de Servicio, aquella porción de la tabla Transacciones de Servicio que compete a determinada Transacción.

Cada modificación de la Base de Datos genera un registro indicando la transacción realizada (secuencial, clase y código), persona que ejecuta la transacción (usuario que envía el requerimiento), desde y dónde (terminal, y servidores de origen y ejecución de la transacción) y los datos de la tabla a modificar.

-  

#### cr_tran_servicio

Transacciones de servicio de trámites, información de respaldo de todas las transacciones que se realizan en el módulo.

| Tabla cr_tran_servicio |     |     |     |     |
| --- |     |     |     |     | --- | --- | --- | --- |
| **Campo** | **Tipo** | **Longitud** | **Requerido** | **Descripción** |
| ts_secuencial | Int | 4   | NULL | Secuencia de registro |
| ts_cod_alterno | Int | 4   | NULL | Código alterno de secuencial - No aplica |
| ts_tipo_transaccion | Smallint | 2   | NOT NULL | Código de transacción |
| ts_clase | Char | 1   | NOT NULL | Clase de registro<br><br>A= Actual<br><br>N= Nuevo<br><br>P= Previo<br><br>O= Otros |
| ts_fecha | Datetime | 8   | NULL | Fecha de inserción de registro de la transacción |
| ts_usuario | Varchar | 14  | NULL | Login de usuario que ejecuta la transacción |
| ts_terminal | Varchar | 64  | NULL | Decripción de terminal |
| ts_oficina | Smallint | 2   | NULL | Código de oficina |
| ts_tabla | Varchar | 30  | NULL | Descripción de la tabla en la que se modificó el dato |
| ts_lsrv | Varchar | 30  | NULL | Descripción del servidor local |
| ts_srv | Varchar | 30  | NULL | Descripción del servidor |
| ts_tinyint01 | Tinyint | 1   | NULL | Dato de tipo Tinyint |
| ts_tinyint02 | Tinyint | 1   | NULL | Dato de tipo Tinyint |
| ts_tinyint03 | Tinyint | 1   | NULL | Dato de tipo Tinyint |
| ts_tinyint04 | Tinyint | 1   | NULL | Dato de tipo Tinyint |
| ts_tinyint05 | Tinyint | 1   | NULL | Dato de tipo Tinyint |
| ts_tinyint06 | Tinyint | 1   | NULL | Dato de tipo Tinyint |
| ts_tinyint07 | Tinyint | 1   | NULL | Dato de tipo Tinyint |
| ts_smallint01 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_smallint02 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_smallint03 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_smallint04 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_smallint05 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_smallint06 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_smallint07 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_smallint08 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_smallint09 | Smallint | 2   | NULL | Dato de tipo Smallint |
| ts_int01 | Int | 4   | NULL | Dato de tipo Smallint |
| ts_int02 | Int | 4   | NULL | Dato de tipo Int |
| ts_int03 | Int | 4   | NULL | Dato de tipo Int |
| ts_int04 | Int | 4   | NULL | Dato de tipo Int |
| ts_int05 | Int | 4   | NULL | Dato de tipo Int |
| ts_int06 | Int | 4   | NOT NULL | Dato de tipo Int |
| ts_money01 | Money | 8   | NOT NULL | Dato de tipo Money |
| ts_money02 | Money | 8   | NULL | Dato de tipo Money |
| ts_money03 | Money | 8   | NULL | Dato de tipo Money |
| ts_money04 | Money | 8   | NULL | Dato de tipo Money |
| ts_float01 | Float | 8   | NULL | Dato de tipo Float |
| ts_float02 | Float | 8   | NULL | Dato de tipo Float |
| ts_catalogo01 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo02 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo03 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo04 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo05 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo06 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo07 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo08 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo09 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo10 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo11 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_catalogo12 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_descripcion01 | Varchar | 64  | NULL | Dato de tipo Descripción |
| ts_descripcion02 | Varchar | 64  | NULL | Dato de tipo Descripción |
| ts_descripcion03 | Varchar | 64  | NULL | Dato de tipo Descripción |
| ts_char101 | Char | 1   | NULL | Dato de tipo Char |
| ts_char102 | Char | 1   | NULL | Dato de tipo Char |
| ts_char103 | Char | 1   | NULL | Dato de tipo Char |
| ts_char104 | Char | 1   | NULL | Dato de tipo Char |
| ts_char105 | Char | 1   | NULL | Dato de tipo Char |
| ts_char106 | Char | 1   | NULL | Dato de tipo Char |
| ts_char107 | Char | 1   | NULL | Dato de tipo Char |
| ts_char108 | Char | 1   | NULL | Dato de tipo Char |
| ts_char109 | Char | 1   | NULL | Dato de tipo Char |
| ts_char110 | Char | 1   | NULL | Dato de tipo Char |
| ts_char111 | Char | 1   | NULL | Dato de tipo Char |
| ts_char112 | Char | 1   | NULL | Dato de tipo Char |
| ts_char113 | Char | 1   | NULL | Dato de tipo Char |
| ts_char114 | Char | 1   | NULL | Dato de tipo Char |
| ts_char115 | Char | 1   | NULL | Dato de tipo Char |
| ts_char116 | Char | 1   | NULL | Dato de tipo Char |
| ts_char117 | Char | 1   | NULL | Dato de tipo Char |
| ts_char118 | Char | 1   | NULL | Dato de tipo Char |
| ts_char119 | Char | 1   | NULL | Dato de tipo Char |
| ts_char201 | Char | 2   | NULL | Dato de tipo Char |
| ts_char301 | Char | 12  | NULL | Dato de tipo Char |
| ts_login01 | Varchar | 14  | NULL | Dato de tipo Login |
| ts_login02 | Varchar | 14  | NULL | Dato de tipo Login |
| ts_login03 | Varchar | 14  | NULL | Dato de tipo Login |
| ts_cuenta01 | Varchar | 24  | NULL | Dato de tipo Cuenta |
| ts_cuenta02 | Varchar | 24  | NULL | Dato de tipo Cuenta |
| ts_cuenta03 | Varchar | 24  | NULL | Dato de tipo Cuenta |
| ts_texto | Varchar | 255 | NULL | Dato de tipo Texto |
| ts_texto2 | Varchar | 255 | NULL | Dato de tipo Texto |
| ts_vchar6401 | Char | 64  | NULL | Dato de tipo Char(64) |
| ts_vchar6402 | Varchar | 64  | NULL | Dato de tipo Varchar(64) |
| ts_vchar6403 | Varchar | 64  | NULL | Dato de tipo Varchar(64) |
| ts_vchar4001 | Varchar | 40  | NULL | Dato de tipo Varchar(40) |
| ts_vchar4002 | Varchar | 40  | NULL | Dato de tipo Varchar(40) |
| ts_fecha01 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_fecha02 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_fecha03 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_fecha04 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_fecha05 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_fecha06 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_fecha07 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_fecha08 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_fecha09 | Datetime | 8   | NULL | Dato de tipo Datetime |
| ts_cliente | Int | 4   | NULL | Código de cliente |
| ts_catalogo13 | Varchar | 10  | NULL | Dato de tipo Catálogo |
| ts_money05 | Money | 8   | NULL | Dato de tipo Money |
| ts_cuenta04 | Varchar | 24  | NULL | Dato de tipo Cuenta |

### Vistas

- - 1.  

#### ts_abogado (No se usa en esta versión)

Transacciones de servicio: 21068, 21168, 21268, 21368, 21468, 21568, 21668

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| abogado | ts_catalogo01 |
| cliente | ts_int01 |
| tipo | ts_char101 |
| nombre | ts_descripcion01 |
| direccion | ts_texto |
| ciudad | ts_int02 |
| login | ts_login01 |
| cuenta | ts_cuenta01 |
| tipo_cuenta | ts_char301 |
| tarjeta | ts_vchar6401 |
| especialidad | ts_catalogo02 |
| clase_interno | ts_catalogo03 |

#### ts_acciones (No se usa en esta versión)

Transacciones de servicio: 21074

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| cobranza | ts_char301 |
| numero | ts_smallint01 |
| taccion | ts_catalogo01 |
| proceso | ts_catalogo02 |
| etapa | ts_catalogo03 |
| descripcion | ts_texto |
| fecha_acc | ts_fecha01 |
| funcionario | ts_login01 |
| fecha_rev | ts_fecha02 |

#### ts_agenda (No se usa en esta versión)

Transacciones de servicio: 21040, 21140, 21240

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| oficial | ts_smallint01 |
| ente | ts_int01 |
| visita | ts_int02 |
| fecha_desde | ts_fecha01 |
| fecha_hasta | ts_fecha02 |
| fecha_visita | ts_fecha03 |
| fecha_conf | ts_fecha04 |
| usuario_conf | ts_login01 |
| categoria | ts_catalogo01 |

#### ts_atribucion (No se usa en esta versión)

Transacciones de servicio: 21080, 21180, 21280, 21380, 21480, 215080, 21680

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| atribucion | ts_tinyint01 |
| etapa | ts_tinyint02 |
| estacion | ts_smallint01 |
| tipo | ts_char101 |
| codigo | ts_catalogo01 |
| usuario_sug | ts_login01 |
| oficial | ts_smallint01 |

#### ts_cobranza (No se usa en esta versión)

Transacciones de servicio: 21067, 21167, 21567 no usada en la versión personalizada para este banco.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| cobranza | ts_char301 |
| cliente | ts_int02 |
| estado | ts_catalogo01 |
| proceso | ts_catalogo02 |
| etapa | ts_catalogo03 |
| ab_interno | ts_login01 |
| fecha_ab_interno | ts_fecha01 |
| abogado | ts_catalogo04 |
| fecha_abogado | ts_fecha02 |
| fecha_documentos | ts_fecha03 |
| fecha_demanda | ts_fecha04 |
| juzgado | ts_catalogo05 |
| num_juicio | ts_cuenta01 |
| informe | ts_smallint01 |
| fecha_ingr | ts_fecha05 |
| usuario_ingr | ts_login02 |
| fecha_mod | ts_fecha06 |
| usuario_mod | ts_login03 |

#### ts_comentarios (No se usa en esta versión)

Transacciones de servicio: 21042

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| alterno | ts_cod_alterno |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| oficial | ts_smallint01 |
| ente | ts_int01 |
| visita | ts_int02 |
| linea | ts_smallint02 |
| texto | ts_texto |

#### ts_conclusiones (No se usa en esta versión)

Transacciones de servicio: 21042

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| alterno | ts_cod_alterno |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| oficial | ts_smallint01 |
| ente | ts_int01 |
| visita | ts_int02 |
| linea | ts_smallint02 |
| texto | ts_texto |

#### ts_condicion (No se usa en esta versión)

Transacciones de servicio: 21081,21181, 21281, 21381, 21481, 21581, 21681

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| atribucion | ts_tinyint01 |
| etapa | ts_tinyint02 |
| estacion | ts_smallint01 |
| condicion | ts_tinyint03 |
| operador | ts_char201 |
| variable | ts_tinyint04 |
| valor | ts_vchar4001 |

#### ts_costos (No se usa en esta versión)

Transacciones de servicio: 21071

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| costo | ts_smallint01 |
| cobranza | ts_char301 |
| codigo | ts_catalogo01 |
| valor | ts_money01 |
| moneda | ts_tinyint01 |
| fecha_registro | ts_fecha01 |
| fecha_confirmacion | ts_fecha02 |
| usuario_confirmacion | ts_login01 |
| valor_pagado | ts_money02 |
| fecha_pago | ts_fecha03 |

#### ts_cotizacion (No se usa en esta versión)

Transacciones de servicio: 21076, 21176, 21276, 21376, 21476, 21576

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| moneda | ts_tinyint01 |
| fecha_cot | ts_fecha01 |
| valor | ts_money01 |
| fecha_modif | ts_fecha02 |

#### ts_dato_toperacion (No se usa en esta versión)

Transacciones de servicio: 21031, 21131, 21231, 21331, 21431, 21531

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| toperacion | ts_catalogo01 |
| producto | ts_catalogo02 |
| dato | ts_catalogo03 |
| descripcion | ts_descripcion01 |
| tipo_dato | ts_tinyint01 |

#### ts_datos_tramites

Transacciones de servicio: 21032, 21132, 21232, 21332, 21432, 21532

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| toperacion | ts_catalogo01 |
| producto | ts_catalogo02 |
| dato | ts_catalogo03 |
| valor | ts_texto |

#### ts_def_variables (No se usa en esta versión)

Transacciones de servicio: 21907, 21908, 21909, 21910, 2149011, 2159012, 2169013

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| variable | ts_tinyint01 |
| descripcion | ts_descripcion01 |
| programa | ts_vchar4001 |
| sp_ayuda | ts_vchar4002 |
| tipo | ts_char101 |
| uso | ts_char102 |

#### ts_destino_economico

Transacciones de servicio: 21082, 21182, 21282, 21382, 21482, 21582, 21682, 21782

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| codigo | ts_vchar6401 |
| codigo_superior | ts_vchar6402 |
| descripcion | ts_descripcion01 |

#### ts_deudores

Transacciones de servicio: 21013, 21113, 21213, 21313, 21413, 21513, 21613

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| cliente | ts_int02 |
| rol | ts_catalogo01 |

#### ts_documento

Transacciones de servicio: 21034, 21434

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| documento | ts_smallint01 |
| numero | ts_tinyint01 |
| fecha_impresion | ts_fecha01 |
| usuario_doc | ts_login01 |

#### ts_estacion (Deprecated)

Transacciones de servicio: 21003, 21103, 21203, 21303, 21403, 21503, 21603, no usada en la versión personalizada para este banco.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| srv | ts_lsrv |
| lsrv | ts_srv |
| estacion | ts_smallint01 |
| descripcion | ts_descripcion01 |
| ofic | ts_smallint02 |
| funcionario | ts_login01 |
| carga | ts_tinyint01 |
| tipo | ts_char101 |
| comite | ts_vchar4001 |
| estacion_sup | ts_smallint03 |
| tope | ts_char102 |
| nivel | ts_catalogo01 |

#### ts_estado_dias

Transacciones de servicio: 21963

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| estado | ts_catalogo01 |
| dias_vto | ts_int01 |

#### ts_etapa (Deprecated)

Transacciones de servicio: 21001, 21101, 21201, 21301, 21401, 21501, 21601, no usada en la versión personalizada para este banco.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| etapa | ts_tinyint01 |
| descripcion | ts_descripcion01 |
| tipo | ts_char101 |
| asignacion | ts_vchar4001 |

#### ts_etapa_estacion (Deprecated)

Transacciones de servicio: 21002, 21102, 21202, 21302, 21402, 21502, 21602, no usada en la versión personalizada para este banco.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| srv | ts_lsrv |
| lsrv | ts_srv |
| estacion | ts_smallint01 |
| etapa | ts_tinyint01 |
| modifica | ts_char101 |
| estado | ts_char102 |
| estacion_sus | ts_smallint02 |

#### ts_excepciones (Deprecated)

Transacciones de servicio: 21015, 21115, 21215, 21415, 21515

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| cod_alterno | ts_cod_alterno |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| numero | ts_tinyint01 |
| codigo | ts_catalogo01 |
| clase_ex | ts_char101 |
| texto | ts_texto |
| fecha_tope | ts_fecha04 |
| estado | ts_char102 |
| fecha_aprob | ts_fecha02 |
| login_aprob | ts_login02 |
| fecha_regula | ts_fecha03 |
| login_regula | ts_login03 |
| razon_regula | ts_texto2 |
| fecha_reg | ts_fecha01 |
| login_reg | ts_login01 |
| garantia | ts_vchar6401 |
| accion | ts_char103 |
| comite | ts_catalogo02 |
| acta | ts_cuenta01 |

#### ts_gar_anteriores

Transacciones de servicio: 21029, 21129, 21229, 21429, 21529

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| accion | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| garantia_anterior | ts_vchar6401 |
| garantia_nueva | ts_vchar6403 |
| operacion | ts_cuenta04 |

#### ts_gar_propuesta

Transacciones de servicio: 21028, 21128, 21228, 21428, 21528

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| accion | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| cod_alterno | ts_cod_alterno |
| tramite | ts_int01 |
| garantia | ts_vchar6401 |
| clase | ts_char103 |
| deudor | ts_int02 |
| estado | ts_char104 |
| porcentaje | ts_float01 |
| valor_resp_garantia | ts_money01 |
| saldo_cap_op | ts_money02 |
| prendado | ts_money05 |

#### ts_imp_documento

Transacciones de servicio: 21033, 21133, 21233, 21433, 21533

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| documento | ts_smallint01 |
| toperacion | ts_catalogo01 |
| producto | ts_catalogo02 |
| moneda | ts_tinyint01 |
| descripcion | ts_descripcion01 |
| template | ts_descripcion02 |
| mnemonico | ts_catalogo03 |
| tipo | ts_char101 |

#### ts_instrucciones (Deprecated)

Transacciones de servicio: 21014, 21114, 21214, 21414, 21514

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| numero | ts_smallint01 |
| codigo | ts_catalogo01 |
| estado | ts_char101 |
| texto | ts_texto |
| parametro | ts_catalogo02 |
| valor_ins | ts_money01 |
| signo | ts_char201 |
| spread | ts_float01 |
| fecha_aprob | ts_fecha02 |
| login_aprob | ts_login02 |
| fecha_reg | ts_fecha01 |
| login_reg | ts_login01 |
| fecha_eje | ts_fecha03 |
| login_eje | ts_login03 |
| comite | ts_catalogo03 |
| acta | ts_cuenta01 |

#### ts_lin_grupo (No se usa en esta versión)

Transacciones de servicio: 21060, 21061, 21062, 21063, 21064

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| srv | ts_srv |
| lsrv | ts_lsrv |
| linea | ts_int01 |
| cliente | ts_int02 |
| monto | ts_money01 |
| utilizado | ts_money02 |

#### ts_lin_ope_moneda

Transacciones de servicio: 21023, 21123, 21232, 21423, 21523

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| linea | ts_int01 |
| toperacion | ts_catalogo01 |
| producto | ts_catalogo02 |
| moneda | ts_tinyint01 |
| monto | ts_money01 |
| utilizado | ts_money02 |
| tplazo | ts_catalogo03 |
| plazos | ts_smallint01 |

#### ts_linea

Transacciones de servicio: 21026, 21126, 21262, 21426, 21526, 21826

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| srv | ts_lsrv |
| lsrv | ts_srv |
| numero | ts_int01 |
| num_banco | ts_cuenta01 |
| ofic | ts_smallint01 |
| tramite | ts_int02 |
| cliente | ts_int03 |
| grupo | ts_int04 |
| original | ts_int05 |
| fecha_aprob | ts_fecha01 |
| fecha_inicio | ts_fecha02 |
| per_revision | ts_catalogo01 |
| fecha_vto | ts_fecha03 |
| dias | ts_smallint02 |
| condicion_especial | ts_texto |
| ultima_rev | ts_fecha04 |
| prox_rev | ts_fecha05 |
| usuario_rev | ts_login01 |
| monto | ts_money01 |
| moneda | ts_tinyint01 |
| utilizado | ts_money02 |
| rotativa | ts_char101 |
| fecha_contrato | ts_fecha06 |
| revolvente | ts_char102 |
| tipo | ts_catalogo02 |
| tipo_tarjeta | ts_catalogo03 |

#### ts_medidas_prec (No se usa en esta versión)

Transacciones de servicio: 21073, 21173, 21273, 21473, 21573

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| cobranza | ts_char301 |
| numero | ts_smallint01 |
| tipo | ts_char101 |
| codificacion | ts_catalogo01 |
| descripcion | ts_descripcion01 |
| depositario | ts_descripcion02 |
| direccion | ts_descripcion03 |
| valor | ts_money01 |
| moneda | ts_tinyint01 |
| fecha_mp | ts_fecha01 |

#### ts_miembros (No se usa en esta versión)

Transacciones de servicio: 21046, 21146, 21262, 21346, 21446, 21546, 21646

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| comite | ts_catalogo01 |
| miembro | ts_login01 |
| cabecera | ts_char101 |

#### ts_observaciones (Deprecated)

Transacciones de servicio: 21016, 21116, 21216, 21416, 21516

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| numero | ts_smallint01 |
| fecha_ob | ts_fecha01 |
| categoria | ts_catalogo01 |
| etapa | ts_tinyint01 |
| estacion | ts_smallint02 |
| usuario_ob | ts_login01 |
| lineas | ts_smallint03 |
| oficial | ts_char101 |

#### ts_op_renovar

Transacciones de servicio: 21030, 21130, 21230, 21430, 21530

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| num_operacion | ts_cuenta01 |
| producto | ts_catalogo01 |
| abono | ts_money01 |
| moneda_abono | ts_tinyint01 |
| monto_original | ts_money02 |
| saldo_original | ts_money03 |
| fecha_concesion | ts_fecha01 |
| toperacion | ts_catalogo02 |
| moneda_original | ts_tinyint02 |
| capitaliza | ts_char117 |

#### ts_operacion_cobranza (No se usa en esta versión)

Transacciones de servicio: 21956, 21957 no usada en la versión personalizada para este banco.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| cobranza | ts_char301 |
| num_operacion | ts_cuenta01 |
| producto | ts_catalogo01 |

#### ts_param_calif

Transacciones de servicio: 21037, 21038, 21039, 21041, 21043

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| clase_car | ts_char101 |
| calificacion | ts_catalogo01 |
| desde | ts_smallint01 |
| hasta | ts_smallint02 |
| porcentaje | ts_float01 |

#### ts_pasos (Deprecated)

Transacciones de servicio: 21005, 21105, 21205, 21305, 21405, 21505, 21605, no usada en la versión personalizada para este banco.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| truta | ts_tinyint01 |
| paso | ts_tinyint02 |
| etapa | ts_tinyint03 |
| descripcion | ts_descripcion01 |
| tiempo_estandar | ts_float01 |
| tipo | ts_char101 |
| truta_asoc | ts_tinyint04 |
| paso_asoc | ts_tinyint05 |
| etapa_asoc | ts_tinyint06 |
| picture | ts_char102 |
| ejecucion | ts_char119 |

#### ts_periodo (No se usa en esta versión)

Transacciones de servicio: 21017, 21117, 21217, 21417, 21517

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| periodo | ts_catalogo01 |
| descripcion | ts_descripcion01 |
| factor | ts_smallint01 |
| estado | ts_catalogo02 |

#### ts_problemas (No se usa en esta versión)

Transacciones de servicio: 21042

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| oficial | ts_smallint01 |
| ente | ts_int01 |
| visita | ts_int02 |
| problema | ts_catalogo01 |

#### ts_regla (Deprecated)

Transacciones de servicio: 21081, 21181, 21281, 21381, 21481, 21581, 21681

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| truta | ts_tinyint01 |
| paso | ts_tinyint02 |
| etapa | ts_tinyint03 |
| regla | ts_tinyint04 |
| prioridad | ts_tinyint05 |
| paso_siguiente | ts_tinyint06 |
| etapa_siguiente | ts_tinyint07 |
| descripcion | ts_descripcion01 |
| programa | ts_vchar4001 |

#### ts_regula (No se usa en esta versión)

Transacciones de servicio: 21144, 21444

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| alterno | ts_cod_alterno |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| excepcion | ts_tinyint01 |
| codigo | ts_catalogo01 |
| estado | ts_char101 |
| fecha_regula | ts_fecha01 |
| login_regula | ts_login01 |
| razon | ts_texto |

#### ts_req_cobranza (No se usa en esta versión)

Transacciones de servicio: 21958, 21959 no usada en la versión personalizada para este banco.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| cobranza | ts_char301 |
| estado | ts_catalogo01 |
| requisito | ts_catalogo02 |
| cumplido | ts_char101 |
| observacion | ts_descripcion01 |

#### ts_req_estado (Deprecated)

Transacciones de servicio: 21962

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| estado | ts_catalogo01 |
| requisito | ts_catalogo02 |
| tipo_cliente | ts_char101 |
| descripcion | ts_descripcion01 |
| obligatorio | ts_char102 |
| observacion | ts_texto |
| estado_dato | ts_catalogo03 |

#### ts_req_etapa (Deprecated)

Transacciones de servicio: 21009, 21109, 21209, 21309, 21409, 21509, 21609

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| etapa | ts_tinyint01 |
| tramite | ts_char101 |
| requisito | ts_catalogo01 |
| mandatorio | ts_char102 |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |

#### ts_req_tramite

Transacciones de servicio: 21051, 21151, 21251, 21451

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| tipo | ts_char101 |
| etapa | ts_tinyint01 |
| requisito | ts_catalogo01 |
| observacion | ts_descripcion01 |
| fecha_modif | ts_fecha01 |

#### ts_ruta_tramite (Deprecated)

Transacciones de servicio: 21801, no usada en la versión personalizada para este banco.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| secuencia | ts_smallint02 |
| etapa | ts_tinyint01 |
| estacion | ts_smallint01 |
| truta | ts_tinyint02 |
| paso | ts_tinyint03 |
| llegada | ts_fecha01 |
| salida | ts_fecha02 |
| estadot | ts_int02 |
| paralelo | ts_smallint03 |
| prioridad | ts_tinyint04 |
| abierto | ts_char101 |
| etapa_sus | ts_tinyint05 |
| estacion_sus | ts_smallint04 |
| comite | ts_char102 |

#### ts_tel_abogado (No se usa en esta versión)

Transacciones de servicio: 21072

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| abogado | ts_catalogo01 |
| telefono | ts_tinyint01 |
| numero | ts_vchar6401 |
| tipo | ts_catalogo02 |

#### ts_texcepcion (Deprecated)

Transacciones de servicio: 21009, 21109, 21209, 21309, 21409, 21509, 21609

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| codigo | ts_catalogo01 |
| tipo | ts_char101 |
| descripcion | ts_descripcion01 |
| nivelap | ts_catalogo02 |
| aprobacion | ts_char102 |

#### ts_tinstruccion (Deprecated)

Transacciones de servicio: 21008, 21108, 21208, 21308, 21408, 21508, 21608

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| codigo | ts_catalogo01 |
| tipo | ts_char101 |
| descripcion | ts_descripcion01 |
| nivel_ap | ts_catalogo02 |
| aprobacion | ts_char102 |

#### ts_toperacion

Transacciones de servicio: 21010, 21110, 21210, 21310, 21410, 21510, 21610

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| toperacion | ts_catalogo01 |
| producto | ts_catalogo02 |
| descripcion | ts_descripcion01 |
| estado | ts_char101 |
| riesgo | ts_char301 |
| codigo_sib | ts_char201 |
| firmas | ts_tinyint01 |

#### ts_tramite

Transacciones de servicio: 21020, 21120, 21220, 21520

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| tipo | ts_char101 |
| oficina_tr | ts_smallint02 |
| usuario_tr | ts_login01 |
| fecha_crea | ts_fecha01 |
| oficial | ts_smallint01 |
| sector | ts_char102 |
| ciudad | ts_smallint03 |
| estado | ts_char103 |
| nivel_ap | ts_tinyint01 |
| fecha_apr | ts_fecha02 |
| usuario_apr | ts_login02 |
| truta | ts_tinyint02 |
| secuencia | ts_smallint04 |
| numero_op | ts_int04 |
| numero_op_banco | ts_cuenta01 |
| proposito | ts_catalogo01 |
| razon | ts_catalogo02 |
| txt_razon | ts_texto2 |
| efecto | ts_catalogo03 |
| cliente | ts_int02 |
| grupo | ts_int03 |
| fecha_inicio | ts_fecha03 |
| num_dias | ts_smallint05 |
| per_revision | ts_catalogo05 |
| condicion_especial | ts_texto |
| linea_credito | ts_int05 |
| toperacion | ts_catalogo07 |
| producto | ts_catalogo08 |
| monto | ts_money01 |
| moneda | ts_tinyint03 |
| periodo | ts_catalogo09 |
| num_periodos | ts_smallint06 |
| destino | ts_catalogo10 |
| ciudad_destino | ts_int06 |
| cuenta_corriente | ts_cuenta02 |
| garantia_limpia | ts_char104 |
| renovacion | ts_smallint08 |
| precancelacion | ts_char107 |
| comite | ts_catalogo11 |
| acta | ts_cuenta03 |
| oficial_conta | ts_smallint09 |
| cem | ts_money04 |
| causa | ts_char118 |
| pgroup | ts_catalogo13 |

#### ts_tramite_grupal

Transacciones de servicio: 21846, 21847, 21848

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| tramite | ts_int01 |
| grupo | ts_int02 |
| cliente | ts_int03 |
| monto | ts_money01 |
| grupal | ts_char101 |
| operacion | ts_int04 |
| prestamo | ts_vchar4001 |
| referencia_grupal | ts_vchar4002 |
| cuenta | ts_texto |
| cheque | ts_int05 |
| participa_ciclo | ts_char102 |
| monto_aprobado | ts_money02 |
| ahorro | ts_money03 |
| monto_max | ts_money04 |
| bc_ln | ts_char303 |
| incremento | ts_int06 |
| monto_ult_op | ts_money05 |
| monto_max_calc | ts_money06 |
| nueva_op | ts_int07 |
| monto_min_calc | ts_money07 |
| conf_grupal | ts_char103 |
| destino | ts_catalogo01 |
| sector | ts_catalogo02 |
| monto_recomendado | ts_money08 |
| estado | ts_char104 |
| id_rechazo | ts_catalogo03 |
| descripcion_rechazo | ts_descripcion01 |

#### ts_truta (Deprecated)

Transacciones de servicio: 21004, 21104, 21204, 21304, 21404, 21504, 21604

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| truta | ts_tinyint02 |
| descripcion | ts_descripcion01 |
| tipo | ts_char101 |

#### ts_creditbureau

Se guarda la información con respecto a la revisión de buró de credito de los clientes.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| oficial | ts_smallint01 |
| ente | ts_int01 |
| fecha_consulta | ts_fecha01 |
| tramite | ts_int02 |
| saldo_cuota | ts_money01 |
| saldo_corto_plazo | ts_money02 |
| saldo_largo_plazo | ts_money03 |
| calificacion | ts_money04 |
| identificacion | ts_vchar1001 |
| documento | ts_vchar1002 |

#### ts_accion_desercion

Se guarda la información respecto a las acciones de deserción.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| id  | ts_int01 |
| id_histotico | ts_int02 |
| acción | ts_descripcion01 |
| resultado | ts_descripcion02 |
| usuario_ingreso | ts_login01 |
| usuario_mod | ts_login02 |
| fecha_ingreso | ts_fecha01 |
| fecha_modif | ts_fecha02 |

#### ts_causa_desercion

Se guarda la información respecto a las causas de deserción.

| Campos Vista | Campos Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| oficina | ts_oficina |
| tabla | ts_tabla |
| lsrv | ts_lsrv |
| srv | ts_srv |
| id  | ts_int01 |
| ente | ts_int02 |
| observacion | ts_descripcion01 |
| causa | ts_catalogo01 |
| severidad | ts_catalogo02 |
| usuario_ingreso | ts_login01 |
| usuario_mod | ts_login02 |
| fecha_ingreso | ts_fecha01 |
| fecha_modif | ts_fecha02 |

## Índices

Descripción de los índices definidos para las tablas del sistema Crédito.

Tipo Índice :

INDEX

**No**

**Índice**

**Tabla**

**Columnas Combinadas**

i_idx_cr_act_financiar

cr_act_financiar

coa_cod_cliente

coa_formulario

| idx1 |
| --- |
| idx2 |
| idx3 |

cr_acuerdo

coa_formulario

cr_acuerdo_his

coa_producto

coa_operacion

idx1

cr_acu

erdo_vencimiento

co_fecha_calif

co_producto

co_operacion

cr_acuerdo_vencimiento_his

co_cliente

cr_acuerdo_vencimiento_tmp

co_fecha_calif,co_operacion

| cr_archivo_redescuento_AKey |
| --- |
| cr_archivo_redescuento_Key |
| cr_archivo_redescuento_Key1 |
| cr_archivo_redescuento_k1 |

cr_archivo_redescuento

cg_fecha,cg_garantia

idx1

cr_asegurados

cg_fecha

cg_garantia

cg_operacion

cr_cambio_estados_Key

cr_cambio_estados

cg_fecha

cg_operacion

| ix_cr_camapana_1 |
| --- |
| ix_cr_campana |

cr_campana

cc_fecha

cc_cliente

cc_operacion

ix_cr_campana_toperacion

cr_campana_toperacion

ca_sec_reg

cr_cau_tramite_Key

cr_cau_tramite

cc_sec_reg

| idx1 |
| --- |
| idx2 |
| idx3 |
| idx4 |
| ix_cr_cliente_campana_1 |
| ix_cr_cliente_campana_2 |
| ix_cr_cliente_campana_3 |

cr_cliente_campana

cliente

cr_clientes_tmp

producto

operacion

| cr_cobranza_AKey |
| --- |
| cr_cobranza_Key |

cr_cobranza

cf_cliente

cr_corresp_sib_1

cr_corresp_sib

cf_producto

cf_operacion

cr_costos_Key

cr_costos

cc_agrupador

cc_oficina

cc_tipo_operacion

cc_oficial

cr_cotiz3_tmp

codigo_sib

cr_cotizacion_Key

cr_cotizacion

codigo

tabla

cr_dato_cliente_Key

cr_dato_cliente

cc_linea

| cr_dato_garantia_K1 |
| --- |
| cr_dato_garantia_K2 |
| cr_dato_garantia_Key |

cr_dato_garantia

cc_tipo

cc_num_banco

| cr_dato_operacion_Akey1 |
| --- |
| cr_dato_operacion_Akey2 |
| cr_dato_operacion_Akey3 |
| cr_dato_operacion_Akey4 |
| cr_dato_operacion_Akey5 |
| idx3 |

cr_dato_operacion

tipo_reg

oficial

codigo_cliente

pk_cr_datos_linea

cr_datos_linea

grupo

cr_datos_tramites_Key

cr_datos_tramites

tipo_reg

codigo_actividad

cr_def_variables_Key

cr_def_variables

tipo_reg

fecha

cr_desembolso

tipo_reg

numero_operacion

producto

tipo_operacion

codigo_garantia

fecha

cr_deud1_tmp

dg_tipo_reg

dg_oficial

dg_grupo

| cr_deudores_1 |
| --- |
| cr_deudores_Key |

cr_deudores

dg_tipo_reg

dg_grupo

dg_fecha

cr_deudores_tmp

di_tipo_reg

di_numero_operacion

di_codigo_producto

cr_documento_Key

cr_documento

di_tipo_reg

di_codigo_cliente

cr_errores_sib_Key

cr_errores_sib

di_tipo_reg

di_codigo_producto

cr_errorlog_K1

cr_errorlog

di_tipo_reg

| cr_estacion_K1 |
| --- |
| cr_estacion_K2 |
| cr_estacion_Key |

cr_estacion

di_numero_operacion_banco

cr_estados_concordato_Key

cr_estados_concordato

di_tipo_reg

di_fecha

cr_etapa_Key

cr_etapa

tipo_reg

numero_operacion

codigo_producto

| cr_etapa_estacion_AKey |
| --- |
| cr_etapa_estacion_Key |

cr_etapa_estacion

tipo_reg

codigo_cliente

| cr_excepcion_AKey |
| --- |
| cr_excepciones_Key |

cr_excepciones

tipo_reg

codigo_producto

cr_excepcion_tramite

linea_credito

cr_facturas_Key

cr_facturas

tipo_reg

codigo_producto

codigo_cliente

oficina

cr_gar_anteriores_Key

cr_gar_anteriores

tipo_reg

fecha

cr_gar_p_tmp

tipo_reg

producto

numero_operacion

tipo_oper

fecha

| cr_gar_propuesta_Key |
| --- |
| i_cr_gar_propuesta_i2 |
| i_cr_gar_propuesta_i3 |

cr_gar_propuesta

di_producto

di_operacion

di_tipo_oper

cr_gar_tmp

fi_tramite

fi_secuencial

cr_garantia_gp

fi_numoperacion

cr_garantias_gp

fn_operacion

fn_sec_negociacion

fn_sec_fpago

cr_grupo_castigo_cl_Key

cr_grupo_castigo

gc_cliente

cr_grupo_tran_castigo_cl_Key

cr_grupo_tran_castigo

ge_producto

ge_operacion

cr_grupo_tran_casti_tmp_cl_Key

cr_grupo_tran_castigo_tmp

gg_grupo

cr_his_calif_Key

cr_his_calif

gc_fecha

gc_num_obligacion

cr_hist_credito_AKey1

| cr_hist_credito_AKey2 |
| --- |
| cr_hist_credito_AKey3 |
| cr_hist_credito_Key |

cr_hist_credito

gc_fecha

gc_tramite

cr_imp_documento_Key

cr_imp_documento

lb_fecha

cr_instrucciones

m_user

m_sesion

m_tramite

cr_lin_grupo_Key

cr_lin_grupo

ma_fecha_reg

cr_lin_ope_moneda_Key

cr_lin_ope_moneda

op_operacion

| cr_linea_AKey |
| --- |
| cr_linea_BKey |
| cr_linea_CKey |
| cr_linea_Dkey |
| cr_linea_Key |
| cr_linea_Key_tr |

cr_linea

or_num_operacion

cr_ob_lineas_Key

cr_ob_lineas

cliente_op

cr_observaciones_Key

cr_observaciones

cliente_op

cr_observacion_castigo_cl_Key

cr_observacion_castigo

fecha

codigo_cliente

cusip

cr_observ_castig_tmp_cl_Key

cr_observacion_castigo_tmp

fecha

codigo_cliente

| cr_op_renovar_Key |
| --- |
| cr_op_renovar_Key2 |

cr_op_renovar

fecha

codigo_cliente

cusip

cr_ope1_tmp

fecha

codigo_cliente

| cr_ope_cob_i2 |
| --- |
| cr_operacion_cobranza_Key |
| cr_operacion_cobranza_Key1 |

cr_operacion_cobranza

sx_tramite

sx_secuencia

cr_param_calif_Key

cr_param_calif

en_subtipo

en_pais

pk_cr_parametros_linea

cr_parametros_linea

en_subtipo

en_ced_ruc

cr_pasos_Key

cr_pasos

en_subtipo

en_pais

cr_poliza_tmp

td_toperacion

td_destino

pk_cr_productos_linea

cr_productos_linea

gp_garantia

cr_regla_Key

cr_regla

tramite

tipo_cus

ubicación

cr_req_tramite_Key

cr_req_tramite

tr_tramite

| cr_ruta_tram_AKey3 |
| --- |
| cr_ruta_tram_AKey4 |
| cr_ruta_tramite_Key |
| cr_ruta_tramite_Key2 |
| cr_ruta_tramite_idx5 |

cr_ruta_tramite

Fecha,

fecha

cr_secuencia_Key

cr_secuencia

tipo_reg,

numero_operacion,

producto,

tipo_operacion,

codigo_garantia,

fecha

cr_situacion_cliente

dg_tipo_reg,

dg_oficial,

dg_grupo

cr_situacion_deudas

dg_tipo_reg,

dg_grupo,

dg_fecha

cr_situacion_gar

di_tipo_reg,

di_numero_operacion,

di_codigo_producto

cr_situacion_gar_p

di_tipo_reg,

di_codigo_cliente

cr_situacion_inversiones

di_tipo_reg,

di_codigo_producto

cr_situacion_lineas

di_tipo_reg

cr_situacion_otras

di_numero_operacion_banco

cr_soli_rechazadas_tmp

di_tipo_reg,

di_fecha

cr_situacion_poliza

tipo_reg,

numero_operacion,

codigo_producto

cr_temp4_tmp

tipo_reg,

codigo_cliente

cr_tinstruccion_Key

cr_tinstruccion

tipo_reg,

codigo_producto

cr_tipo_tramite_Key

cr_tipo_tramite

linea_credito

| cr_tmp_datooper_AKey1 |
| --- |
| cr_tmp_datooper_AKey2 |
| cr_tmp_datooper_Key |

cr_tmp_datooper

tipo_reg,

codigo_producto,

codigo_cliente,

oficina

cr_toperacion_Key

cr_toperacion

tipo_reg,

fecha

cr_tr_castigo_cl_Key

cr_tr_castigo

tipo_reg ,

producto,

numero_operacion,

tipo_oper,

fecha

cr_tr_datos_adicionales

Fecha,

codigo_cliente,

cusip

| cr_tramite_AKey |
| --- |
| cr_tramite_AKey2 |
| cr_tramite_AKey4 |
| cr_tramite_AKey5 |
| cr_tramite_AKey6 |
| cr_tramite_AKey7 |
| cr_tramite_AKey8 |
| cr_tramite_Key |
| cr_tramite_idx10 |
| cr_tramite_idx11 |
| cr_tramite_tr_op_redescuento |

cr_tramite

Fecha,

codigo_cliente

| idx1 |
| --- |
| idx2 |
| idx3 |

cr_tramite_grupal

tipo_reg,

oficial,

codigo_cliente

cr_truta_Key

cr_truta

grupo

cr_valor_variables_Key

cr_valor_variables

tipo_reg,

codigo_actividad

tmp_garantias

xx_tmp

cr_buro_credito_Key

cr_buro_credito

ts_secuencial, ts_tipo_transaccion

cr_cobros_AKey

cr_cobros

co_recuperador, co_oficial, co_fecha_recupera, co_tipo_producto, co_estado

## TABLAS DE LA BASE COB_PAC

### tmp_cliente_grupo

Tabla temporal que se usa para la variable Edad Cliente Grupo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| spid | Int |     | NOT NULL |     |     |
| cg_ente | Int |     | NOT NULL |     |     |
| cg_grupo | Int |     | NOT NULL |     |     |
| cg_usuario | Login |     | NOT NULL |     |     |
| cg_terminal | Varchar | 32  | NOT NULL |     |     |
| cg_oficial | Smallint |     | NULL |     |     |
| cg_rol | Catalogo |     | NULL |     |     |

### bpl_rule_process_his_cli

Tabla utilizada para la variable Edad Cliente Grupo.

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| rphc_rule_id | Int |     | NOT NULL |     |     |
| rphc_rule_version | Int |     | NOT NULL |     |     |
| rphc_id_inst_proc | Int |     | NOT NULL |     |     |
| rphc_id_asig_act | Int |     | NOT NULL |     |     |
| rphc_cod_variable | Int |     | NOT NULL |     |     |
| rphc_valor | Varchar | 255 | NOT NULL |     |     |
| rphc_cod_variable_padre | Int |     | NOT NULL |     |     |
| rphc_cliente_id | Int |     | NOT NULL |     |     |
| rphc_grupo_id | Int |     | NOT NULL |     |     |
| rphc_rule_id_padre | Int |     | NULL |     |     |
| rphc_resultado_regla | Varchar | 255 | NULL |     |     |

## INDICES DE LA BASE COB_PAC

| Tipo Índice : |     | INDEX |     |
| --- |     | --- |     | --- | --- |
| **No** | **Índice** | **Tabla** | **Columnas Combinadas** |
|     | tmp_cl_cliente_grupo_I1 | tmp_cl_cliente_grupo | spid |
|     | bpl_rule_process_his_cli_I1 | bpl_rule_process_his_cli | rphc_rule_id |