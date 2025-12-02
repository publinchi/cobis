MANUAL TECNICO

DICCIONARIO DE DATOS

COBIS - PMO

Historia de Cambios

| Versión | Fecha | Autor | Revisado | Aprobado | Descripción |
| --- | --- | --- | --- | --- | --- |
| 1.0.0 | 01-Jun-21 | ACA | PQU | PQU | Emisión inicial |
| 1.0.1 | 22-Jun-22 | BDU | PQU | PQU | Inclusión tablas de trx de servicio |
| 1.0.2 | 04-Ene-23 | EBA |     |     | Cambio de formato institucional |
| 1.0.3 | 03-Feb-2023 | BDU |     |     | Inclusión de nuevos campos de análisis del negocio |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |

© 2023 Cobiscorp

RESERVADOS TODOS LOS DERECHOS

Es responsabilidad del tenor de este documento el cumplimiento de todas las leyes de derechos de autor aplicables. Sin que por ello queden limitados los derechos de autor, ninguna parte de este documento puede ser reproducida, almacenada o introducida en un sistema de recuperación, o transmitida de ninguna forma, ni por ningún medio (ya sea electrónico, mecánico, por fotocopia, grabación o de otra manera) con ningún propósito, sin la previa autorización por escrito de Cobiscorp.

Cobiscorp puede ser titular de patentes, solicitudes de patentes, marcas, derechos de autor, y otros derechos de propiedad intelectual sobre los contenidos de este documento. El suministro de este documento no le otorga ninguna licencia sobre estas patentes, marcas, derechos de autor, u otros derechos de propiedad intelectual, a menos que ello se prevea en un contrato por escrito de licencia de Cobiscorp.

Cobiscorp, COBIS y Cooperative Open Banking Information System son marcas registradas de Cobiscorp.

Otros nombres de compañías y productos mencionados en este documento, pueden ser marcas comerciales o marcas registradas por sus respectivos propietarios.

Tabla de Contenido

[1\. INTRODUCCIÓN 6](#_Toc128472600)

[_1.1._ El módulo Clientes dentro de la estructura general 6](#_Toc128472601)

[2\. OBJETIVO 7](#_Toc128472602)

[3\. ALCANCE 7](#_Toc128472603)

[4\. DEFINICIONES 8](#_Toc128472604)

[5\. Diccionario de datos 8](#_Toc128472605)

[5.1. Detalle de las estructuras de datos 8](#_Toc128472606)

[5.1.1. cl_actividad_ec 8](#_Toc128472607)

[5.1.2. cl_actualiza (No se usa en esta versión) 8](#_Toc128472608)

[5.1.3. cl_at_instancia 9](#_Toc128472609)

[5.1.4. cl_at_relacion 9](#_Toc128472610)

[5.1.5. cl_cliente 10](#_Toc128472611)

[5.1.6. cl_cliente_grupo 10](#_Toc128472612)

[5.1.7. cl_contacto (No se usa en esta versión) 11](#_Toc128472613)

[5.1.8. cl_det_producto 12](#_Toc128472614)

[5.1.9. cl_ejecutivo 13](#_Toc128472615)

[5.1.10. cl_direccion 14](#_Toc128472616)

[5.1.11. cl_ente 16](#_Toc128472617)

[5.1.12. cl_grupo 27](#_Toc128472618)

[5.1.13. cl_hijos (No se usa en esta versión) 29](#_Toc128472619)

[5.1.14. cl_his_ejecutivo 31](#_Toc128472620)

[5.1.15. cl_his_relacion 31](#_Toc128472621)

[5.1.16. cl_instancia 32](#_Toc128472622)

[5.1.17. cl_mala_ref 32](#_Toc128472623)

[5.1.18. cl_mercado (No se usa en esta versión) 33](#_Toc128472624)

[5.1.19. cl_ref_personal 33](#_Toc128472625)

[5.1.20. cl_referencia (No se usa en esta versión) 35](#_Toc128472626)

[5.1.21. cl_refinh 37](#_Toc128472627)

[5.1.22. cl_relacion 38](#_Toc128472628)

[5.1.23. cl_telefono 39](#_Toc128472629)

[5.1.24. cl_tipo_documento 40](#_Toc128472630)

[5.1.25. cl_com_liquidacion 41](#_Toc128472631)

[5.1.26. cl_narcos 41](#_Toc128472632)

[5.1.27. cl_actividad_principal 42](#_Toc128472633)

[5.1.28. cl_ente_aux 42](#_Toc128472634)

[5.1.29. cl_mod_estados (No se usa en esta versión) 46](#_Toc128472635)

[5.1.30. cl_sector_economico 47](#_Toc128472636)

[5.1.31. cl_subsector_ec 47](#_Toc128472637)

[5.1.32. cl_subactividad_ec 47](#_Toc128472638)

[5.1.33. cl_actividad_economica 48](#_Toc128472639)

[5.1.34. cl_listas_negras (No se usa en esta versión) 49](#_Toc128472640)

[5.1.35. cl_infocred_central (No se usa en esta versión) 50](#_Toc128472641)

[5.1.36. cl_direccion_geo 51](#_Toc128472642)

[5.1.37. cl_dato_adicion 52](#_Toc128472643)

[5.1.38. cl_dadicion_ente 52](#_Toc128472644)

[5.1.39. cl_comercial 53](#_Toc128472645)

[5.1.40. cl_financiera 54](#_Toc128472646)

[5.1.41. cl_economica 54](#_Toc128472647)

[5.1.42. cl_tarjeta 55](#_Toc128472648)

[5.1.43. cl_negocio_cliente 56](#_Toc128472649)

[5.1.44. cl_validacion_listas_externas 58](#_Toc128472650)

[5.1.45. cl_tipo_identificacion 58](#_Toc128472651)

[5.1.46. cl_ptos_matriz_riesgo (No se usa en esta versión) 59](#_Toc128472652)

[5.1.47. cl_info_trn_riesgo 59](#_Toc128472653)

[5.1.48. ts_negocio_cliente 60](#_Toc128472654)

[5.1.49. cl_val_iden (No se usa en esta versión) 61](#_Toc128472655)

[5.1.50. cl_scripts 61](#_Toc128472656)

[5.1.51. cl_registro_identificacion 62](#_Toc128472657)

[5.1.52. cl_registro_cambio 62](#_Toc128472658)

[5.1.53. cl_alertas_riesgo (No se usa en esta versión) 62](#_Toc128472659)

[5.1.54. cl_analisis_negocio 63](#_Toc128472660)

[5.1.55. cl_beneficiario_seguro 65](#_Toc128472661)

[5.1.56. cl_control_empresas_rfe 66](#_Toc128472662)

[5.1.57. cl_direccion_fiscal (No se usa en esta versión) 66](#_Toc128472663)

[5.1.58. cl_documento_actividad (No se usa en esta versión) 67](#_Toc128472664)

[5.1.59. cl_documento_digitalizado 67](#_Toc128472665)

[5.1.60. cl_documento_parametro 68](#_Toc128472666)

[5.1.61. cl_manejo_sarlaft (No se usa en esta versión) 68](#_Toc128472667)

[5.1.62. cl_notificacion_general 69](#_Toc128472668)

[5.1.63. cl_ns_generales_estado (No se usa en esta versión) 69](#_Toc128472669)

[5.1.64. cl_pais_id_fiscal 69](#_Toc128472670)

[5.1.65. cl_productos_negocio 70](#_Toc128472671)

[5.1.66. cl_seccion_validar 70](#_Toc128472672)

[5.1.67. cl_trabajo 70](#_Toc128472673)

[5.1.68. cl_ident_ente 72](#_Toc128472674)

[5.1.69. cl_ref_telefono 72](#_Toc128472675)

[5.1.70. cl_listas_negras_log 73](#_Toc128472676)

[5.1.71. cl_listas_negras_rfe 73](#_Toc128472677)

[5.1.72. cl_indice_pob_preg 74](#_Toc128472678)

[5.1.73. cl_indice_pob_respuesta 74](#_Toc128472679)

[5.1.74. cl_ppi_ente 74](#_Toc128472680)

[5.1.75. cl_det_ppi_ente 75](#_Toc128472681)

[5.1.76. cl_puntaje_ppi_ente 75](#_Toc128472682)

[5.2. Vistas y transacciones de servicios 75](#_Toc128472683)

[5.2.1. cl_tran_servicio 76](#_Toc128472684)

[_5.3._ Vistas 89](#_Toc128472685)

[5.3.1. ts_persona 89](#_Toc128472686)

[5.3.2. ts_compania 93](#_Toc128472687)

[5.3.3. ts_control_empresas_rfe 95](#_Toc128472688)

[5.3.4. ts_direccion 96](#_Toc128472689)

[5.3.5. ts_direccion_fiscal 97](#_Toc128472690)

[5.3.6. ts_direccion_geo 98](#_Toc128472691)

[5.3.7. ts_grupo 99](#_Toc128472692)

[5.3.8. ts_pais_id_fiscal 100](#_Toc128472693)

[5.3.9. ts_analisis_negocio 101](#_Toc128472694)

[5.3.10. ts_cliente_grupo 103](#_Toc128472695)

[5.3.11. ts_persona_prin 104](#_Toc128472696)

[5.3.12. ts_persona_sec 106](#_Toc128472697)

[5.3.13. ts_productos_negocio 108](#_Toc128472698)

[5.3.14. ts_ref_personal 108](#_Toc128472699)

[5.3.15. ts_relacion 109](#_Toc128472700)

[5.3.16. ts_instancia 110](#_Toc128472701)

[5.3.17. ts_telefono 111](#_Toc128472702)

[5.3.18. ts_mala_ref 111](#_Toc128472703)

[5.3.19. ts_tipo_documento 112](#_Toc128472704)

[5.3.20. ts_cia_liquidacion 113](#_Toc128472705)

[5.3.21. ts_adicion_ente 114](#_Toc128472706)

[5.3.22. ts_referencia 114](#_Toc128472707)

[5.3.23. ts_trabajo 115](#_Toc128472708)

[5.3.24. ts_listas_negras 116](#_Toc128472709)

[5.3.25. ts_identificaciones_adicionales 117](#_Toc128472710)

[5.3.26. ts_telefono_ref 117](#_Toc128472711)

[5.3.27. ts_indice_pob_preg 118](#_Toc128472712)

[5.3.28. ts_indice_pob_respuesta 119](#_Toc128472713)

[5.3.29. ts_ppi_ente 119](#_Toc128472714)

[5.3.30. ts_det_ppi_ente 120](#_Toc128472715)

[5.4. Índices por Clave Primaria 121](#_Toc128472716)

[5.5. Índices por Clave Foránea 123](#_Toc128472717)

Lista de Tablas y Figuras

**No table of figures entries found.**

**No table of figures entries found.**

MANUAL TECNICO

Diccionario de Datos

Clientes

# INTRODUCCIÓN

## El módulo Clientes dentro de la estructura general

El presente manual técnico COBIS describe las estructuras que permiten operar el módulo Clientes, en relación a que constituye un elemento de integración de la información, enlazando y relacionando los datos de cada cliente entre los diferentes módulos, consolidando su posición económica, rentabilidad y riesgo ante la Institución. Permite conocer los costos operativos generales de la empresa por cliente y por producto, evitando demoras innecesarias y optimizando tiempo y dinero en el proceso.

Adicionalmente, el módulo de CLIENTES permite la simulación de condiciones operativas de una Institución, el análisis de nuevos productos y servicios considerando las características de los clientes, permitiendo su segmentación por mercados y ubicación geográfica.

Por otra parte, el módulo Clientes interactúa con los siguientes módulos COBIS

- Administración
- XSell
- Crédito
- Cobranzas
- Cartera
- Plazo Fijo
- Cuentas Corrientes
- Cuentas de Ahorros
- Tesorería
- Servicios Bancarios
- Banca Virtual
- Comercio Exterior
- Activos Fijos

Dentro de la funcionalidad del módulo, es válido destacar los siguientes aspectos:

- **Información para mercadeo**

Manejo de información para soporte a las actividades del área de mercadeo de la Institución, con posibilidades de análisis de factibilidad de nuevos productos, distribución geográfica de clientes y evaluación del comportamiento de productos.

El manejo de la distribución geográfica de los clientes se complementa con el análisis de nuevos productos, facilitando la definición de perfiles para potenciales clientes con los atributos que se desee (por ejemplo, edad, ingresos, propiedades, sexo, saldos promedios en cuentas) para encontrar aquellos que cumplan el perfil definido. Además, el conocimiento de la ubicación de estos clientes permite determinar las posibilidades de éxito de productos y realizar la definición de campañas de publicidad dirigidas a los clientes objetivos para cada producto.

- **Información de saldos de clientes**

Obtención de información sobre los saldos, saldos promedios y flujo de movimientos de los productos contratados por el cliente.

# OBJETIVO

Mostrar el modelo de datos que usa el módulo de Clientes.

# ALCANCE

Diccionario de Datos: indica la estructura de cada tabla.

Vistas y Transacciones de Servicio: En esta parte del manual se indica las tablas para el registro de transacciones, de las cuales se necesita información como: qué usuario realizó la transacción, en qué fecha y hora, desde qué y en qué servidor, código de identificación de la transacción, los datos de la transacción, etc. Además, contiene las Vistas que intervienen en el módulo para consultas de Distribución Geográfica.

# DEFINICIONES

No aplica

# Diccionario de datos

## Detalle de las estructuras de datos

### cl_actividad_ec

Guarda información de actividades económicas

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ac_codigo | catalogo | 10  | NOT NULL | Código de la actividad | &nbsp; |
| ac_descripcion | varchar | 200 | NULL | Descripción de la actividad | &nbsp; |
| ac_sensitiva | Char | 1   | NULL | No se usa en esta versión |     |
| ac_industria | catalogo | 10  | NULL | Tipo de industria. | &nbsp; |
| ac_estado | estado | 1   | NULL | Estado de la actividad | V= Vigente C= Cancelado E= Eliminado |
| ac_codSubsector | catalogo | 10  | NULL | Cod. Del subsector |     |
| ac_homolog_pn | catalogo | 10  | NULL | No se usa en esta versión |     |
| ac_homolog_pj | catalogo | 10  | NULL | No se usa en esta versión |     |

### cl_actualiza (No se usa en esta versión)

Guarda la información de datos que han sido modificados en el módulo

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ac_ente | Int | 4   | NOT NULL | Código del ente | &nbsp; |
| ac_fecha | Datetime | 8   | NOT NULL | Fecha de actualización | &nbsp; |
| ac_tabla | descripcion | 64  | NULL | Tabla que se modificó | &nbsp; |
| ac_campo | descripcion | 64  | NULL | Campo que se modificó | &nbsp; |
| ac_valor_ant | descripcion | 64  | NULL | Valor anterior a la modificación | &nbsp; |
| ac_valor_nue | descripcion | 64  | NULL | Valor nuevo del campo | &nbsp; |
| ac_transaccion | Char | 1   | NULL | Operación que se realizó sobre el registro | &nbsp; |
| ac_secuencial1 | Tinyint | 1   | NULL | No aplica | &nbsp; |
| ac_secuencial2 | Tinyint | 1   | NULL | No aplica | &nbsp; |
| ac_hora | Datetime | 8   | NULL | Hora de modificación | &nbsp; |
| ac_user | Login | 14  | NULL | Usuario que modifico |     |
| ac_term | descripcion | 64  | NULL | Terminal de donde se modifico |     |

### cl_at_instancia

Contiene el valor de los atributos de la instancia de una relación entre dos entes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ai_relacion | Int | 4   | NOT NULL | Código identificador de la relación. | &nbsp; |
| ai_ente_i | Int | 4   | NOT NULL | Código secuencial del ente asignado al lado izquierdo de la relación. | &nbsp; |
| ai_ente_d | Int | 4   | NOT NULL | Código secuencial del ente asignado al lado derecho de la relación. | &nbsp; |
| ai_atributo | Tinyint | 1   | NOT NULL | Código identificador del atributo. | &nbsp; |
| ai_valor | Varchar | 255 | NOT NULL | Valor del atributo. | &nbsp; |
| ai_secuencial | Int | 4   | NULL | Secuencial | &nbsp; |

### cl_at_relacion

Contiene los atributos de una relación. Se maneja la información de relaciones legales y otras definidas por el usuario.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ar_relacion | Int | 4   | NOT NULL | Código relación | &nbsp; |
| ar_atributo | Tinyint | 1   | NOT NULL | Secuencial del atributo por relación. | &nbsp; |
| ar_descripcion | descripcion | 64  | NOT NULL | Descripción del título que tiene el atributo dentro de la relación | &nbsp; |
| ar_tdato | Varchar | 30  | NOT NULL | Tipo de dato que tendrá el atributo de la relación | &nbsp; |
| ar_catalogo | varchar | 30  | NULL | Nombre del catalogo a relacionar |     |
| ar_bdatos | Varchar | 30  | NULL | Nombre de la base de datos a relacionar |     |
| ar_sprocedure | Varchar | 50  | NULL | Nombre del Sp a relacionar |     |

### cl_cliente

Todos los clientes que han contratado un producto COBIS.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cl_cliente | Int | 4   | NOT NULL | Código Cobis del cliente al cual se asocia un producto Cobis. | &nbsp; |
| cl_det_producto | Int | 4   | NOT NULL | Secuencial correspondiente al producto específico dentro de la tabla cl_det_producto. | &nbsp; |
| cl_rol | Char | 1   | NOT NULL | Rol del cliente para el producto. | T= Titular. A= Alternante. |
| cl_ced_ruc | numero | 30  | NOT NULL | Número de cédula o ruc del cliente. | &nbsp; |
| cl_fecha | Datetime | 8   | NOT NULL | Fecha de contratación del producto Cobis. | &nbsp; |

### cl_cliente_grupo

Contiene la información de los clientes que pertenecen a un grupo determinado creado en COBIS.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cg_ente | Int | 4   | NOT NULL | Código del ente. | &nbsp; |
| cg_grupo | Int | 4   | NOT NULL | Código del grupo económico al cual pertenece el ente. | &nbsp; |
| cg_usuario | login | 14  | NOT NULL | Login del usuario que crea el registro. | &nbsp; |
| cg_terminal | Varchar | 32  | NOT NULL | Nombre de la terminal desde la cual se crea el registro. | &nbsp; |
| cg_oficial | Smallint | 2   | NULL | Código del oficial asignado al ente. | &nbsp; |
| cg_fecha_reg | Datetime | 8   | NOT NULL | Fecha de registro | &nbsp; |
| cg_rol | catalogo | 10  | NULL | Rol que desempeña el miembro | P: Presidente<br><br>A: Ahorrador<br><br>S: Secretario<br><br>T: Tesorero<br><br>D: Desertor<br><br>M: Integrante<br><br>(cl_rol_grupo) |
| cg_estado | catalogo | 10  | NULL | Estado del grupo | V: Vigente<br><br>C: Cancelado |
| cg_calif_interna | catalogo | 10  | NULL | No Aplica en esta versión, sirve para calificar al grupo. |     |
| cg_fecha_desasociacion | datetime | 8   | NULL | Fecha en la que se desasocia el miembro del grupo. No aplica |     |
| cg_tipo_relacion | catalogo | 10  | NULL | No Aplica |     |
| cg_ahorro_voluntario | money | 8   | NULL | No Aplica en esta versión |     |
| cg_lugar_reunion | varchar | 10  | NULL | No Aplica en esta versión |     |
| cg_nro_ciclo | int | 4   | NULL | Nro del ciclo del integrante en el grupo. | &nbsp; |

### cl_contacto (No se usa en esta versión)

Guarda la información de la persona que sirve de contacto con la compañía.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| co_ente | Int | 4   | NOT NULL | Código del ente | &nbsp; |
| co_contacto | Tinyint | 1   | NOT NULL | Código secuencial del contacto de acuerdo al ente | &nbsp; |
| co_nombre | Varchar | 40  | NOT NULL | Nombre del contacto | &nbsp; |
| co_cargo | Varchar | 32  | NOT NULL | Cargo ocupado en la empresa | &nbsp; |
| co_telefono | Varchar | 12  | NOT NULL | Número de teléfono del contacto | &nbsp; |
| co_direccioi | direccion | 255 | NULL | Dirección del contacto | &nbsp; |
| co_verificado | Char | 1   | NULL | Indicador si los datos del contacto han sido verificados | S= Verificados N= Falta verificar |
| co_fecha_ver | Datetime | 8   | NULL | Fecha de verificación | &nbsp; |
| co_funcionario | login | 14  | NULL | Código del funcionario que realizó el registro | &nbsp; |
| co_direccion | direccion | 255 | NULL | Dirección del contacto | &nbsp; |
| co_email | descripcion | 64  | NULL | Email del contacto | &nbsp; |
| co_fecha_reg | Datetime | 8   | NULL | Fecha de registro | &nbsp; |
| co_fecha_mod | Datetime | 8   | NULL | Fecha de modificación | &nbsp; |
| co_area | varchar | 10  | NULL | Código del área |     |
| co_telefono2 | varchar | 12  | NULL | Telefono 2 |     |
| co_fuente_verif | varchar | 10  | NULL | Fuente de verificación |     |

### cl_det_producto

Contiene la información detallada de un producto cobis contratado por un cliente

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dp_det_producto | Int | 4   | NOT NULL | Secuencial de la tabla (valor único). | &nbsp; |
| dp_filial | Tinyint | 1   | NULL | Código de la filial a la que corresponde el producto contratado por el cliente. | &nbsp; |
| dp_oficina | Smallint | 2   | NOT NULL | Código de la oficina a la que corresponde el producto contratado por el cliente. El valor de este campo debe existir en la tabla cl_oficina. | &nbsp; |
| dp_producto | Tinyint | 1   | NOT NULL | Código Cobis del producto contratado por el cliente. | &nbsp; |
| dp_tipo | Char | 1   | NOT NULL | Tipo de producto Cobis | R= Regular |
| dp_moneda | Tinyint | 1   | NOT NULL | Código de la moneda del producto contratado por el cliente. | &nbsp; |
| dp_fecha | Datetime | 8   | NOT NULL | Fecha de contratación del producto. | &nbsp; |
| dp_comentario | descripcion | 64  | NULL | Definición del producto contratado por el cliente. | &nbsp; |
| dp_monto | Money | 8   | NULL | Monto con el cual se apertura una operación de un producto Cobis. | &nbsp; |
| dp_tiempo | Smallint | 2   | NULL | Tiempo o plazo de duración de la operación contratada por el cliente. | &nbsp; |
| dp_cuenta | cuenta | 24  | NULL | Número de operación o cuenta contratada por el cliente. | &nbsp; |
| dp_estado_ser | Char | 1   | NOT NULL | Indica el estado del servicio. | V= Vigente C= Cancelado E= Eliminado |
| dp_autorizante | Smallint | 2   | NULL | Autorizante del producto al cliente | &nbsp; |
| dp_oficial_cta | Smallint | 2   | NOT NULL | Código del oficial de la cuenta. | &nbsp; |
| dp_cliente_ec | Int | 4   | NULL | Código Cobis del cliente a quien se enviará el estado de cuenta en el caso de cuentas corrientes o ahorros. | &nbsp; |
| dp_direccion_ec | Int | 4   | NULL | Código de la dirección a la que se enviará el estado de cuenta en el caso de cuentas corrientes o ahorros. | &nbsp; |
| dp_descripcion_ec | direccion | 255 | NULL | Definición de la dirección a la que se enviará el estado de cuenta en caso de cuentas corrientes o ahorros. | &nbsp; |
| dp_sector | Char | 3   | NULL | Código del sector al cual corresponde la dirección de envío de estado de cuenta | &nbsp; |
| dp_zona | Char | 3   | NULL | Código de la zona de la dirección de envío del estado de cuenta. | &nbsp; |
| dp_valor_inicial | Money | 8   | NULL | Monto inicial de la cuenta | &nbsp; |
| dp_tipo_producto | Char | 1   | NULL | Tipo de producto | &nbsp; |
| dp_tprestamo | Smallint | 2   | NULL | No aplica | &nbsp; |
| dp_valor_promedio | Money | 8   | NULL | Valor promedio | &nbsp; |
| dp_rol_cliente | Char | 1   | NULL | No aplica | &nbsp; |
| dp_iva_retenido | Money | 8   | NULL | No aplica | &nbsp; |
| dp_base_iva | Money | 8   | NULL | No aplica | &nbsp; |
| dp_retefuente | Money | 8   | NULL | No aplica | &nbsp; |
| dp_base_rtefte | Money | 8   | NULL | No aplica | &nbsp; |
| dp_saldo | Money | 8   | NULL | No aplica | &nbsp; |
| dp_fecha_cambio | Datetime | 8   | NULL | No aplica | &nbsp; |
| dp_fecha_prox_ven | Datetime | 8   | NULL | No aplica | &nbsp; |
| dp_apartado_ec | Int | 4   | NULL | No aplica | &nbsp; |
| dp_sub_tipo | Smallint | 2   | NULL | Código del subtipo de producto de cuentas de ahorros y corrientes | &nbsp; |

### cl_ejecutivo

Contiene la información del ejecutivo de cuenta asignado a una persona natural o jurídica.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ej_ente | Int | 4   | NOT NULL | Código Cobis del ente. | &nbsp; |
| ej_funcionario | Int | 4   | NOT NULL | Código Cobis del oficial asignado al ente. Este código corresponde al de la tabla cc_oficial. | &nbsp; |
| ej_toficial | Char | 1   | NOT NULL | Indica el tipo de oficial, por defecto es general | G= General |
| ej_fecha_asig | Datetime | 8   | NOT NULL | Fecha en la que se asigna el oficial al ente. | &nbsp; |

### cl_direccion

Contiene las direcciones de un cliente tanto físicas como virtuales.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| di_ente | Int | 4   | NOT NULL | Código Cobis del ente. | &nbsp; |
| di_direccion | Tinyint | 1   | NOT NULL | Secuencial de la dirección por ente. | &nbsp; |
| di_descripcion | Varchar | 254 | NULL | Definición detallada de la dirección del ente. | &nbsp; |
| di_parroquia | Int | 4   | NULL | Código de la parroquia a la cual pertenece la dirección. Puede tomar cualquier valor definido en la tabla cl_parroquia. | &nbsp;(cl_parroquia)\*\* |
| di_ciudad | Int | 4   | NULL | Código de la ciudad de la dirección | &nbsp;(cl_ciudad)\*\* |
| di_tipo | catalogo | 10  | NOT NULL | Tipo de dirección, puede tomar cualquier valor definido en la tabla de catálogo | &nbsp;(cl_tdireccion) |
| di_telefono | Tinyint | 1   | NULL | Cantidad de teléfonos que tiene la dirección | &nbsp; |
| di_sector | catalogo | 10  | NULL | Sector de la dirección. Urbana, Rural… | &nbsp;(cl_sector_geografico) |
| di_zona | catalogo | 10  | NULL | Zona de ubicación de la dirección | &nbsp;(cl_zona) |
| di_oficina | Smallint | 2   | NULL | Indica si la dirección es de la oficina o residencia | &nbsp;(cl_oficina) |
| di_fecha_registro | Datetime | 8   | NOT NULL | Fecha de Ingreso de la dirección | &nbsp; |
| di_fecha_modificacion | Datetime | 8   | NOT NULL | Fecha de la última modificación a la dirección | &nbsp; |
| di_vigencia | catalogo | 10  | NOT NULL | Indica el estado de la información | V= Vigente C= Caducada |
| di_verificado | Char | 1   | NOT NULL | Indica en qué estado se encuentra la información. Por defecto todas confirmadas | S= Confirmada N= Sin confirmar |
| di_funcionario | login | 14  | NULL | Funcionario que ingresó la dirección | &nbsp; |
| di_fecha_ver | Datetime | 8   | NULL | Fecha en que se verificó la dirección. No aplica | &nbsp; |
| di_principal | Char | 1   | NULL | Indica si la dirección del cliente es principal. | P= Principal N= No es principal |
| di_barrio | Varchar | 40  | NULL | Indica la descripción del catalogo de barrio | &nbsp;(cl_barrio) |
| di_provincia | Smallint | 2   | NULL | Código de la Provincia/Departamento de la dirección | &nbsp;(cl_provincia)\*\* |
| Di_tienetel | Char | 1   | NULL | No aplica |     |
| di_rural_urb | Char | 1   | NULL | No aplica en esta versión | R= Rural<br><br>U= Urbano |
| di_observacion | Varchar | 80  | NULL | No aplica |     |
| di_obs_verificado | Varchar | 10  | NULL | No aplica |     |
| Di_extfin | Char | 1   | NULL | No aplica |     |
| di_pais | Smallint | 2   | NULL | Código del país de la dirección | (cl_pais) |
| di_departamento | Varchar | 10  | NULL | Código del departamento | cl_ciudad |
| di_tipo_prop | Char | 10  | NULL | Indica el tipo de propiedad de la direccion | ALQ= Alquilada<br><br>ANT= Anticretica<br><br>FAM= Familiar<br><br>PRO= Propia<br><br>(cl_tpropiedad) |
| di_rural_urbano | Char | 1   | NULL | Indica si la dirección está en el perímerto Rural o Urbano | R= Rural<br><br>U= Urbano |
| di_codpostal | Char | 5   | NULL | Código de postal de la dirección | &nbsp; |
| di_casa | Varchar | 40  | NULL | Número de casa | &nbsp; |
| di_calle | Varchar | 70  | NULL | Calle | &nbsp; |
| di_codbarrio | Int | 4   | NULL | Código del Barrio de la dirección. No aplica |     |
| di_correspondencia | Char | 1   | NULL | Indica si la dirección que está ingresando es donde recibirá la correspondencia | S= Confirmada N= Sin confirmar |
| di_alquilada | char | 1   | NULL | Indica si es de alquiler |     |
| di_cobro | char | 1   | NULL | Indica si hay cobro |     |
| di_otrasenas | Varchar | 254 | NULL | Definición detallada de la dirección del ente |     |
| di_canton | int | 4   | NULL | Indica el cantón. No aplica |     |
| di_distrito | int | 4   | NULL | Indica el distrito. No aplica |     |
| di_montoalquiler | money | 8   | NULL | Indica el monto del alquiler |     |
| di_edificio | Varchar | 40  | NULL | Nombre de edificio |     |
| di_so_igu_co | char | 1   | NULL | No aplica |     |
| di_fact_serv_pu | char | 1   | NULL | No aplica |     |
| di_nombre_agencia | Varchar | 20  | NULL | Nombre de Agencia. No aplica |     |
| di_fuente_verif | varchar | 10  | NULL | No aplica |     |
| di_tiempo_reside | Int | 4   | NULL | Tiempo en años que llevo en la residencia |     |
| di_nro | Int | 4   | NULL | No aplica |     |
| di_nro_residentes | Int | 4   | NULL | Número de personas que residen |     |
| di_nro_interno | Int | 4   | NULL | No aplica |     |
| di_negocio | Int | 4   | NULL | Negocio |     |
| di_poblacion | Char | 30  | NULL | Nombre población |     |
| di_referencias_dom | Varchar | 455 | NULL | Referencias de población |     |
| di_otro_tipo | Varchar | 20  | NULL | Otro tipo de residencia |     |
| di_localidad | Varchar | 20  | NULL | Nombre de la localidad |     |
| di_conjunto | Varchar | 40  | NULL | Nombre del conjunto |     |
| di_piso | Varchar | 40  | NULL | Ubicación de piso |     |
| di_numero_casa | Varchar | 40  | NULL | Número de casa |     |

### cl_ente

Contiene la información detallada de un ente, es la tabla maestra de cliente. Un ente puede ser una persona natural o jurídica, la cual puede ser cliente o un potencial cliente (prospecto).

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| en_ente | Int | 4   | NOT NULL | Código identificador del<br><br>ente dentro del sistema. | &nbsp; |
| en_nombre | Varchar | 128 | NOT NULL | Nombre del ente | &nbsp; |
| en_subtipo | Char | 1   | NOT NULL | Indica el tipo de ente. | P= Persona<br><br>C= Compañía |
| en_tipo_ced | Char | 4   | NULL | Tipo de identificacion principal | &nbsp; |
| en_ced_ruc | Numero | 30  | NULL | Número de identificación principal, personal o de compañía | &nbsp; |
| en_nit | Numero | 30  | NULL | Número de identificación tributario. | &nbsp; |
| en_rfc | Varchar | 30  | NULL | Número de identificación RFC para personas Mexicanas, No aplica |     |
| en_tipo_iden | Varchar | 13  | NULL | Tipo de identificación adicional de la persona natural, No aplica |     |
| en_numero_iden | Varchar | 20  | NULL | Número de identificación adicional de la persona natural, No aplica |     |
| en_nomlar | Varchar | 254 | NULL | Nombre completo del ente | &nbsp; |
| en_actividad | catalogo | 10  | NULL | Código Cobis de la actividad económica a la que se dedica el ente. | (cl_actividad) |
| en_retencion | Char | 1   | NOT NULL | Indica si el ente está sujeto a retención. | S= Sujeto a retención<br><br>N= No sujeto a retención |
| en_mala_referencia | Char | 1   | NOT NULL | Indica si el ente tiene alguna mala referencia registrada en el sistema | S= Mala referencia<br><br>N= No tiene mala<br><br>referencia. |
| en_comentario | Varchar | 254 | NULL | Comentario u bservaciones sobre el ente registrado en el sistema. | &nbsp; |
| en_sector | catalogo | 10  | NULL | Código del sector económico al que pertenece el cliente | &nbsp;(cl_sector_economico\*\*) |
| en_referido | Smallint | 2   | NULL | Código secuencial del funcionario que presentó al cliente al banco. No aplica | &nbsp; |
| en_pais | Smallint | 2   | NULL | Código Cobis del país de origen o de nacionalidad del ente. | &nbsp;(cl_pais) |
| en_oficial | Smallint | 2   | NULL | Código del oficial o ejecutivo a cargo del cliente. | &nbsp;(cc_oficial, cl_funcionario\*\*) |
| en_cont_malas | Smallint | 2   | NULL | Número de malas referencias de tiene registrado el ente en el sistema. No aplica | &nbsp; |
| en_doc_validado | Char | 1   | NULL | Indicador si la información proporcionada por el cliente fue verificada. No aplica | S= Verificada<br><br>N= Sin verificar |
| en_rep_superban | Char | 1   | NULL | Indicador si el cliente tiene alguna mala referencia. No aplica | S= Mala referencia<br><br>N= No tiene mala<br><br>referencia. |
| en_tipo_dp | Char | 1   | NULL | Indica el tipo de dirección postal. No aplica | C= Casilla<br><br>D= Dirección |
| en_grupo | Int | 4   | NULL | Código Cobis del grupo económico al que pertenece el ente. | &nbsp; |
| p_s_nombre | Varchar | 20  | NULL | Segundo nombre del cliente natural | &nbsp; |
| p_p_apellido | Varchar | 16  | NULL | Apellido paterno de la persona. | &nbsp; |
| p_s_apellido | Varchar | 16  | NULL | Apellido materno de la persona. | &nbsp; |
| p_c_apellido | Varchar | 20  | NULL | Apellido de casada del cliente natural | &nbsp; |
| p_sexo | sexo | 1   | NULL | Indica el sexo de la persona | M=Masculino<br><br>F= Femenino (cl_sexo) |
| p_genero | char | 2   | NULL | Indica el género de la persona | (cl_genero) |
| p_estado_civil | catalogo | 10  | NULL | Indica el estado civil de la persona. | &nbsp;(cl_ecivil) |
| p_fecha_nac | Datetime | 8   | NULL | Fecha de nacimiento de la persona. | &nbsp; |
| p_ciudad_nac | Int | 4   | NULL | Código del lugar de nacimiento del cliente cuando se trata de cv(departamento) y pasaporte(país) | &nbsp;(cl_ciudad) |
| p_tipo_persona | Catalogo | 10  | NULL | Indica si la persona es funcionario del banco. | F=Funcionario<br><br>N= Natural |
| p_profesion | Catalogo | 10  | NULL | Indica la ocupación o profesión del ente. | &nbsp;(cl_profesion) |
| p_ocupacion | Catalogo | 10  | NULL | Indica la ocupación del ente | (cl_ocupacion) |
| p_lugar_doc | Int | 4   | NULL | Código del lugar de emisión del documento. cuando se trata de cv(departamento) y pasaporte(país) | &nbsp;(cl_provincia)\*\* |
| p_pasaporte | Varchar | 20  | NULL | Número de pasaporte de la persona. No aplica | &nbsp; |
| p_num_cargas | Tinyint | 1   | NULL | Número de personas a cargo del cliente natural | &nbsp; |
| p_num_hijos | Tinyint | 1   | NULL | Número de hijos que tiene el cliente | &nbsp; |
| p_nivel_ing | Money | 8   | NULL | Valor de los ingresos del cliente | &nbsp; |
| p_nivel_egr | Money | 8   | NULL | Valor de los egresos del cliente | &nbsp; |
| p_nivel_estudio | catalogo | 10  | NULL | Código del nivel de estudio del Cliente | &nbsp; |
| p_tipo_vivienda | catalogo | 10  | NULL | Código del tipo de vivienda que posee el cliente. No aplica | &nbsp; |
| p_calif_cliente | catalogo | 10  | NULL | No aplica | &nbsp; |
| p_personal | Tinyint | 1   | NULL | Número de referencias personales registradas para la persona. | &nbsp; |
| p_propiedad | Tinyint | 1   | NULL | Número de propiedades registradas para la persona. No aplica. | &nbsp; |
| p_trabajo | Tinyint | 1   | NULL | Número de empleos registrados para la persona. No aplica | &nbsp; |
| p_soc_hecho | Tinyint | 1   | NULL | Número de sociedades de hecho registradas para la persona. No aplica | &nbsp; |
| p_depa_nac | Smallint | 2   | NULL | Código de la provincia o departamento de nacimiento del cliente | (cl_provincia)\*\* |
| p_pais_emi | Smallint | 2   | NULL | No aplica |     |
| p_depa_emi | Smallint | 2   | NULL | No aplica |     |
| p_dep_doc | Int | 4   | NULL | Código del departamento del documento de identificación | &nbsp;(cl_provincia)\*\* |
| p_numord | Varchar | 4   | NULL | Almacena el número de orden. No aplica | &nbsp; |
| p_carg_pub | Varchar | 200 | NULL | Descripción del cargo que ocupa actualmente el PEP. |     |
| p_rel_carg_pub | Varchar | 10  | NULL | código que representa el cargo Relación de dependencia a cargos públicos, y que está asociado a la persona públicamente Expuesta. | Catálogo: cl_cargo_pep |
| p_situacion_laboral | varchar | 5   | NULL | No aplica |     |
| p_bienes | char | 1   | NULL | No aplica |     |
| p_fecha_emision | Datetime | 8   | NULL | Fecha de emisión del documento principal de la Persona. | &nbsp; |
| p_fecha_expira | Datetime | 8   | NULL | Fecha de expiración del documento principal de la persona. | &nbsp; |
| c_razon_social | Varchar | 128 | NULL | Razón social de la compañía | &nbsp; |
| c_segmento | Char | 10  | NULL | Código del segmento de la compañía | &nbsp; |
| c_cap_suscrito | Money | 8   | NULL | No aplica | &nbsp; |
| c_posicion | catalogo | 10  | NULL | Calificación inicial dada a la compañía. Puede tomar cualquier valor definido en la tabla de catálogo cl_posicion. | &nbsp; |
| c_tipo_compania | catalogo | 10  | NULL | Tipo de compañía. Puede tomar cualquier valor definido en la tabla de catálogo. | ( cl_ctipo) |
| c_rep_legal | Int | 4   | NULL | Código Cobis del ente persona que representa legalmente a la compañía. | &nbsp; |
| c_es_grupo | Char | 1   | NULL | Indica si la compañía es a la vez grupo económico. | S= Grupo económico<br><br>N= No es grupo<br><br>económico |
| c_activo | Money | 8   | NULL | No aplica | &nbsp; |
| c_pasivo | Money | 8   | NULL | No aplica | &nbsp; |
| c_total_activos | Money | 8   | NULL | Valor total de los activos de la compañía | &nbsp; |
| c_total_pasivos | Money | 8   | NULL | No aplica |     |
| c_capital_social | Money | 8   | NULL | Capital social declarado por la compañía. | &nbsp; |
| c_reserva_legal | Money | 8   | NULL | No aplica. | &nbsp; |
| c_cap_pagado | Money | 8   | NULL | Valor del capital pagado para la parte legal | &nbsp; |
| c_fecha_const | Datetime | 8   | NULL | Fecha de constitución de la compañía. | &nbsp; |
| c_plazo | Tinyint | 1   | NULL | Tiempo en años por el cual fue creada la compañía (duración de la compañía). | &nbsp; |
| c_direccion_domicilio | Int | 4   | NULL | Código Cobis de la dirección domiciliaria de la compañía. | &nbsp; |
| c_fecha_inscrp | Datetime | 8   | NULL | Fecha de Inscripción de la compañía | &nbsp; |
| c_fecha_aum_capital | Datetime | 8   | NULL | Fecha en que se realizó el último aumento de capital. | &nbsp; |
| c_tipo_nit | Char | 1   | NULL | No aplica | &nbsp; |
| c_tipo_soc | catalogo | 10  | NULL | No aplica | &nbsp; |
| c_num_empleados | Smallint | 2   | NULL | Número total de empleados que laboran en la compañía | &nbsp; |
| c_sigla | Varchar | 25  | NULL | Nombre comercial de la compañía | &nbsp; |
| c_escritura | Varchar | 10  | NULL | Número de la escritura de constitución de la compañía | &nbsp; |
| c_notaria | Tinyint | 1   | NULL | No aplica | &nbsp; |
| c_ciudad | Int | 4   | NULL | Campo no es utilizado | &nbsp; |
| c_fecha_exp | Datetime | 8   | NULL | Fecha expedición | &nbsp; |
| c_fecha_vcto | Datetime | 8   | NULL | Fecha Vencimiento | &nbsp; |
| c_camara | catalogo | 10  | NULL | No aplica | &nbsp; |
| c_registro | Int | 4   | NULL | No aplica | &nbsp; |
| c_grado_soc | catalogo | 10  | NULL | No aplica | &nbsp; |
| c_edad_laboral_promedio | Float | 8   | NULL | No aplica | &nbsp; |
| c_empleados_ley_50 | Float | 8   | NULL | No aplica | &nbsp; |
| c_codsuper | Char | 10  | NULL | Código de la Súper Intendencia de Bancos que se le asigna al cliente | &nbsp; |
| c_fecha_registro | Datetime | 8   | NULL | Fecha de registro de la compañía | &nbsp; |
| c_fecha_modif | Datetime | 8   | NULL | Fecha de modificación de información de la compañía | &nbsp; |
| c_fecha_verif | Datetime | 8   | NULL | Fecha de verificación de información de datos de la compañía | &nbsp; |
| c_vigencia | catalogo | 10  | NULL | Indicador de la vigencia de la información | &nbsp; |
| c_verificado | Char | 10  | NULL | Indicador si los datos de la compañía han sido verificados | &nbsp; |
| c_funcionario | login | 14  | NULL | Login del usuario que ingresa la información | &nbsp; |
| s_tipo_soc_hecho | catalogo | 10  | NULL | Tipo de sociedad de hecho | &nbsp; |
| en_situacion_cliente | catalogo | 10  | NULL | Código de la situación actual del cliente | &nbsp; |
| en_patrimonio_tec | Money | 8   | NULL | Patrimonio técnico del cliente | &nbsp; |
| en_fecha_patri_bruto | Datetime | 8   | NULL | Fecha de ingreso de la referencia de patrimonio bruto | &nbsp; |
| en_gran_contribuyente | Char | 1   | NULL | No aplica | &nbsp; |
| en_calificacion | catalogo | 10  | NULL | No aplica | &nbsp; |
| en_reestructurado | catalogo | 10  | NULL | No aplica | &nbsp; |
| en_concurso_acreedores | catalogo | 10  | NULL | No aplica | &nbsp; |
| en_concordato | catalogo | 10  | NULL | No aplica | &nbsp; |
| en_vinculacion | Char | 1   | NULL | Indica si el cliente posee alguna vinculación al banco. | S= Posee vinculación<br><br>N= Sin vinculación |
| en_tipo_vinculacion | catalogo | 10  | NULL | Código de la vinculación de cliente con el banco | &nbsp;(cl_tipo_vinculacion) |
| en_oficial_sup | Smallint | 2   | NULL | No aplica | &nbsp; |
| en_cliente | Char | 1   | NULL | No aplica | &nbsp; |
| en_preferen | Char | 1   | NULL | Indicador si el cliente es preferencial | S=Preferencial<br><br>N= Normal |
| en_exc_sipla | Char | 1   | NULL | Indica si el cliente se incluye el FOPA | S= Incluye FOPA<br><br>N= No incluye |
| en_exc_por2 | Char | 1   | NULL | No aplica | &nbsp; |
| en_digito | Char | 2   | NULL | Dígito verificador | &nbsp; |
| en_categoria | Catalogo | 10  | NULL | No aplica |     |
| en_emala_referencia | Catalogo | 10  | NULL | No aplica |     |
| en_banca | Catalogo | 10  | NULL | No aplica |     |
| en_pensionado | Char | 1   | NULL | No aplica |     |
| en_rep_sib | Char | 1   | NULL | No aplica |     |
| en_max_riesgo | Money | 8   | NULL | No aplica |     |
| en_riesgo | Money | 8   | NULL | No aplica |     |
| en_mires_ant | Money | 8   | NULL | No aplica |     |
| en_fmod_ries | Datetime | 8   | NULL | No aplica |     |
| en_user_ries | login | 14  | NULL | No aplica |     |
| en_reservado | Money | 8   | NULL | No aplica |     |
| en_pas_finan | Money | 8   | NULL | No aplica |     |
| en_fpas_finan | Datetime | 8   | NULL | No aplica |     |
| en_fbalance | Datetime | 8   | NULL | No aplica |     |
| en_relacint | Char | 1   | NULL | No aplica |     |
| en_otringr | varchar | 10  | NULL | No aplica |     |
| en_exento_cobro | Char | 1   | NULL | No aplica |     |
| en_doctos_carpeta | Char | 1   | NULL | No aplica |     |
| en_oficina_prod | Smallint | 2   | NULL | No aplica |     |
| en_accion | varchar | 10  | NULL | No aplica |     |
| en_procedencia | varchar | 10  | NULL | No aplica |     |
| en_fecha_negocio | Datetime | 8   | NULL | No aplica |     |
| en_estrato | varchar | 10  | NULL | No aplica |     |
| en_recurso_pub | char | 1   | NULL | No aplica |     |
| en_influencia | char | 1   | NULL | No aplica |     |
| en_persona_pub | char | 1   | NULL | Identifica "si" o "no" una persona es públicamente expuesta |     |
| en_victima | char | 1   | NULL | No aplica |     |
| en_bancarizado | char | 1   | NULL | No aplica |     |
| en_alto_riesgo | char | 1   | NULL | No aplica |     |
| en_fecha_riesgo | Datetime | 8   | NULL | No aplica |     |
| en_estado | Char | 1   | NULL | Indica si el ente está bloqueado | S=Bloqueado<br><br>N= Sin bloqueo |
| en_calif_cartera | char | 5   | NULL | No aplica |     |
| en_cod_otro_pais | Char | 10  | NULL | Código de otro país | &nbsp; |
| en_ingre | Varchar | 10  | NULL | Código de ingresos | &nbsp; |
| en_cem | Money | 8   | NULL | Cupo de endeudamiento máximo del cliente. No aplica | &nbsp; |
| en_promotor | Char | 10  | NULL | Código del promotor del cliente. No aplica | &nbsp; |
| en_inss | Varchar | 20  | NULL | Número de seguro. No aplica | &nbsp; |
| en_licencia | Varchar | 30  | NULL | Número de licencia. No aplica | &nbsp; |
| en_id_tutor | Varchar | 20  | NULL | Identificación de tutor. No aplica | &nbsp; |
| en_nom_tutor | Varchar | 60  | NULL | Nombre tutor | &nbsp; |
| en_referidor_ecu | int | 4   | NULL | No aplica |     |
| en_otros_ingresos | money | 8   | NULL | No aplica |     |
| en_origen_ingresos | descripcion | 64  | NULL | No aplica |     |
| en_nro_ciclo | int | 4   | NULL | No aplica |     |
| en_emproblemado | Char | 1   | NULL | No aplica |     |
| en_dinero_transac | Money | 8   | NULL | No aplica |     |
| en_manejo_doc | Varchar | 25  | NULL | No aplica |     |
| en_persona_pep | Char | 1   | NULL | No aplica |     |
| en_ing_SN | Char | 1   | NULL | No aplica |     |
| en_nac_aux | Int | 4   | NULL | No aplica |     |
| en_banco | Varchar | 20  | NULL | No aplica |     |
| en_nacionalidad | Int | 4   | NULL | Pais de nacionalidad | (cl_pais) |
| en_pais_nac | Varchar | 10  | NULL | Descripción nacionalidad |     |
| en_provincia_nac | Int | 4   | NULL | Provincia de nacionalidad |     |
| en_naturalizado | Char | 1   | NULL | No aplica |     |
| en_forma_migratoria | Varchar | 64  | NULL | No aplica |     |
| en_nro_extranjero | Varchar | 64  | NULL | No aplica |     |
| en_calle_orig | Varchar | 70  | NULL | No aplica |     |
| en_exterior_orig | Varchar | 40  | NULL | No aplica |     |
| en_estado_orig | Varchar | 40  | NULL | No aplica |     |
| en_firma_electronica | Varchar | 30  | NULL | No aplica |     |
| en_localidad | Varchar | 20  | NULL | No aplica |     |
| en_actividad_desc | Varchar | 50  | NULL | No aplica |     |
| en_nivel | Varchar | 10  | NULL | No aplica |     |
| en_inf_laboral | Varchar | 200 | NULL | No aplica |     |
| en_tipo_operacion | Varchar | 10  | NULL | No aplica |     |
| en_provincia_act | Varchar | 10  | NULL | No aplica |     |
| en_lugar_act | Varchar | 100 | NULL | No aplica |     |
| en_filial | Tinyint | 1   | NOT NULL | Código de la filial a la que corresponde la oficina en que se crea el ente. | &nbsp; |
| en_oficina | Smallint | 2   | NOT NULL | Código Cobis de la oficina en que se registra el ente. | &nbsp; |
| en_fecha_crea | Datetime | 8   | NULL | Fecha en que de creación del registro. | &nbsp; |
| en_fecha_mod | Datetime | 8   | NOT NULL | Fecha de última modificación del registro. | &nbsp; |
| en_direccion | Tinyint | 1   | NULL | Número de direcciones que tiene registrado el ente en el sistema. | &nbsp; |
| en_referencia | Tinyint | 1   | NULL | Número de referencias económicas que tiene registrado el ente en el sistema. | &nbsp; |
| en_casilla | Tinyint | 1   | NULL | Número de casillas postales que tiene registrado el ente en el sistema. No aplica | &nbsp; |
| en_casilla_def | Varchar | 24  | NULL | Definición de la casilla postal principal del ente. | &nbsp; |
| en_balance | Smallint | 2   | NULL | Número de balances que tiene registrado el ente en el sistema. | &nbsp; |
| en_tipo_doc_tributario | Char | 4   | NULL | Tipo de identificación tributario. |     |
| en_tipo_residencia | Char | 4   | NULL | Tipo de residencia de las personas extranjeras | Catálogo: cl_tipo_residencia |
| en_asosciada | Catalogo | 10  | NULL | Código del tipo de vinculación. No aplica | &nbsp; |
| en_ciudad_emision | int | 4   | NULL | Ciudad de emisión de la identificación. |     |
| en_ente_migrado | varchar | 30  | NULL | Codigo que tenia el cliente antes de migrar sus datos |     |
| en_codigo_pep_relac | int | 4   | NULL | Código ente cobis de un cliente que es PEP con el que se tiene una relación. |     |
| en_nombre_pep_relac | varchar | 100 | NULL | nombre del ente cobis de un cliente que es PEP con el que se tiene una relación. |     |
| p_fecha_inicio_pep | datetime | 8   | NULL | Fecha desde que el cliente es una persona públicamente expuesta. |     |
| p_fecha_fin_pep | datetime | 8   | NULL | Fecha final hasta cuando el cliente fue una persona públicamente expuesta. |     |
| p_tipo_pep | catalogo | 10  | NULL | Código del tipo de persona públicamente expuesta. Por ejemplo, el código 6 representa al tipo 'Político' | (cl_tipo_pep) |

### cl_grupo

Contiene la información de un grupo económico o solidario creado, el cual puede englobar a varias personas naturales y jurídicas.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gr_grupo | Int | 4   | NOT NULL | Secuencial dentro de la tabla y código identificador del grupo económico en el sistema. | &nbsp; |
| gr_nombre | Descripcion | 64  | NOT NULL | Nombre o definición del grupo económico. | &nbsp; |
| gr_representante | Int | 4   | NULL | Código Cobis del ente miembro principal del grupo económico. | &nbsp; |
| gr_compania | Int | 4   | NULL | No aplica | &nbsp; |
| gr_oficial | Int | 4   | NULL | Funcionario de la entidad financiera a cargo del grupo económico. | &nbsp; |
| gr_fecha_registro | Datetime | 8   | NOT NULL | Fecha en que fue creado el registro en la tabla. | &nbsp; |
| gr_fecha_modificacion | Datetime | 8   | NULL | Fecha de la última modificación del registro. | &nbsp; |
| gr_ruc | numero | 30  | NULL | No aplica | &nbsp; |
| gr_vinculacion | Char | 1   | NULL | Verifica si el banco tiene vinculación con el grupo económico. | S= Posee vinculación N= Sin vinculación |
| gr_tipo_vinculacion | catalogo | 10  | NULL | Tipo de vinculación del grupo contra el banco. | &nbsp; |
| gr_max_riesgo | Money | 8   | NULL | No aplica | &nbsp; |
| gr_riesgo | Money | 8   | NULL | No aplica | &nbsp; |
| gr_usuario | login | 14  | NULL | No aplica | &nbsp; |
| gr_reservado | money | 8   | NULL | No aplica |     |
| gr_tipo_grupo | catalogo | 10  | NULL | Campo que almacena los tipos de grupos económicos, estos valores lo obtiene del catálogo:. | (cl_tipo_grupo) |
| gr_estado | catalogo | 10  | NULL | Estado del Grupo Economico | A: Activo<br><br>I: Inactivo |
| gr_dir_reunion | varchar | 125 | NULL | Dirección de la reunión del grupo |     |
| gr_dia_reunion | catalogo | 10  | NULL | Día de la reunión del grupo |     |
| gr_hora_reunion | datetime | 8   | NULL | Hora de la reunión del grupo |     |
| gr_comportamiento_pago | varchar | 10  | NULL | No aplica |     |
| gr_num_ciclo | int | 4   | NULL | Número de ciclos |     |
| gr_incluir | Char | 1   | NULL | No aplica |     |
| gr_consec_tipo | Int | 4   | NULL | No aplica | &nbsp; |
| gr_suplente | int | 4   | NULL | Funcionario suplente por parte de la entidad financiera encargado del grupo. |     |
| gr_tipo | char | 1   | NULL | Tipo de grupo | S: Solidario<br><br>E: Económico |
| gr_cta_grupal | varchar | 30  | NULL | Número de la cuenta grupal del grupo. No aplica |     |
| gr_sucursal | int | 4   | NULL | Código de la sucursal asociada al grupo |     |
| gr_titular1 | int | 4   | NULL | No aplica |     |
| gr_titular2 | int | 4   | NULL | No aplica |     |
| gr_lugar_reunion | char | 10  | NULL | No aplica |     |
| gr_tiene_ctagr | char | 1   | NULL | No aplica |     |
| gr_tiene_ctain | char | 1   | NULL | No aplica |     |
| gr_dias_atraso | int | 4   | NULL | No aplica |     |
| gr_gar_liquida | char | 1   | NULL | Indica si el grupo cuenta con garantía liquida. No aplica | S: Sí<br><br>N: No |
| gr_clasificacion | varchar | 10  | NULL | No aplica |     |

### cl_hijos (No se usa en esta versión)

Guarda la información del cónyuge e hijos del cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| hi_hijo | Int | 4   | NOT NULL | Código secuencial del hijo o cónyuge de acuerdo al cliente | &nbsp; |
| hi_ente | Int | 4   | NOT NULL | Código secuencial del cliente | &nbsp; |
| hi_conyuge | Int | 4   | NULL | No aplica | &nbsp; |
| hi_nombre | Varchar | 50  | NOT NULL | Nombre del cónyuge o hijo | &nbsp; |
| hi_fecha_nac | Datetime | 8   | NULL | Fecha de nacimiento del cónyuge o hijo | &nbsp; |
| hi_sexo | sexo | 1   | NULL | Código del sexo del cónyuge o hijo | M= Masculino F= Femenino |
| hi_tipo | Char | 1   | NULL | Indicador si el registro es del cónyuge o hijo. | C= Cónyuge H= Hijo |
| hi_papellido | Varchar | 30  | NULL | Primer apellido del cónyuge o hijo | &nbsp; |
| hi_sapellido | Varchar | 30  | NULL | Segundo apellido del cónyuge o hijo | &nbsp; |
| hi_empresa | Varchar | 24  | NULL | Empresa donde trabaja el cónyuge o hijo | &nbsp; |
| hi_telefono | Varchar | 16  | NULL | Teléfono del cónyuge o hijo | &nbsp; |
| hi_documento | numero | 30  | NULL | Número de identificación del cónyuge o hijo | &nbsp; |
| hi_tipo_doc | Char | 4   | NULL | Tipo de documento de identificación | &nbsp; |
| hi_dep_doc | Int | 4   | NULL | Código del departamento del documento de identificación del cónyuge o hijo | &nbsp; |
| hi_mun_doc | Int | 4   | NULL | Código del municipio del documento de identificación del cónyuge o hijo | &nbsp; |
| hi_c_apellido | Varchar | 30  | NULL | Apellido de casada del cónyuge o hijo | &nbsp; |
| hi_s_nombre | Varchar | 50  | NULL | Segundo nombre del cónyuge o hijo | &nbsp; |
| hi_nit | Char | 10  | NULL | Número del NIT del cónyuge o hijo | &nbsp; |
| hi_fecha_expira | Datetime | 8   | NULL | Fecha de expiración de los datos | &nbsp; |
| hi_lugar_doc | Int | 4   | NULL | Código del lugar de emisión del pasaporte del cónyuge o hijo | &nbsp; |
| hi_cod_otro_pais | Char | 10  | NULL | Código de otro país | &nbsp; |
| hi_pasaporte | Varchar | 20  | NULL | Número de pasaporte del cónyuge o hijo | &nbsp; |
| hi_funcionario | login | 14  | NOT NULL | Login del usuario que crea el registro. | &nbsp; |
| hi_fecha_registro | Datetime | 8   | NOT NULL | Fecha que se realizó el registro. | &nbsp; |
| hi_fecha_modificacion | Datetime | 8   | NULL | Fecha de última modificación. | &nbsp; |
| hi_digito | Char | 2   | NULL | Dígito verificador | &nbsp; |
| hi_nacionalidad | Int | 4   | NULL | Nacionalidad del cónyuge o hijo. | &nbsp; |
| hi_ciudad_nac | Int | 4   | NULL | Ciudad de nacimiento del cónyuge o hijo | &nbsp; |
| hi_area | varchar | 10  | NULL | Indica el área donde reside el cónyuge o hijo |     |

### cl_his_ejecutivo

Contiene toda la información histórica de los ejecutivos que han sido asignado a una persona natural o jurídica.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ej_ente | Int | 4   | NOT NULL | Código Cobis del ente. | &nbsp; |
| ej_funcionario | Int | 4   | NOT NULL | Código del funcionario que corresponde el ejecutivo asignado | &nbsp; |
| ej_toficial | Char | 1   | NOT NULL | Tipo de oficial | P= Persona Natural C= Persona Jurídica |
| ej_fecha_asig | Datetime | 8   | NOT NULL | Fecha en que se asignó el nuevo oficial al ente. | &nbsp; |
| ej_fecha_registro | Datetime | 8   | NOT NULL | Fecha en que se registró el nuevo oficial al ente. | &nbsp; |

### cl_his_relacion

Contiene toda la información histórica de las relaciones establecidas entre clientes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| hr_relacion | Int | 4   | NOT NULL | Tipo de relación | &nbsp; |
| hr_ente_i | Int | 4   | NOT NULL | Código Cobis del ente asignado al lado izquierdo de la relación. | &nbsp; |
| hr_ente_d | Int | 4   | NOT NULL | Código Cobis del ente asignado al lado derecho de la relación. | &nbsp; |
| hr_fecha_ini | Datetime | 8   | NOT NULL | Fecha en que inicia la relación. | &nbsp; |
| hr_fecha_fin | Datetime | 8   | NOT NULL | Fecha en que finaliza la relación. | &nbsp; |
| hr_secuencial | Int | 4   | NOT NULL | Secuencial | &nbsp; |

### cl_instancia

Contiene la información de una instancia de una relación entre 2 entes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| in_relacion | Smallint | 2   | NOT NULL | Código de la relación. | &nbsp; |
| in_ente_i | Int | 4   | NOT NULL | Código Cobis del ente asignado al lado izquierdo de la relación. | &nbsp; |
| in_ente_d | Int | 4   | NOT NULL | Código Cobis del ente asignado al lado derecho de la relación. | &nbsp; |
| in_lado | Char | 1   | NOT NULL | Indica a qué lado de la relación se debe aplicar | I= Izquierdo D= Derecho |
| in_fecha | Datetime | 8   | NOT NULL | Fecha en que fue creado el registro en la tabla. | &nbsp; |

### cl_mala_ref

Guarda malas referencias del cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| mr_ente | Int | 4   | NOT NULL | Código Cobis del ente. | &nbsp; |
| mr_mala_ref | Tinyint | 1   | NOT NULL | Secuencial | &nbsp; |
| mr_treferencia | catalogo | 10  | NOT NULL | Tipo de mala referencia. Puede tomar cualquier valor definido en la tabla de catálogo | &nbsp; |
| mr_fecha_registro | Datetime | 8   | NOT NULL | Fecha de registro de la mala referencia | &nbsp; |
| mr_fecha_cov | Char | 12  | NULL | No usado | &nbsp; |
| mr_observacion | Varchar | 255 | NULL | Observaciones | &nbsp; |
| mr_funcionario | login | 14  | NULL | Funcionario a cargo | &nbsp; |

### cl_mercado (No se usa en esta versión)

Guarda la información de las referencias de mercado del cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| me_codigo | Int | 4   | NOT NULL | Código secuencial de la referencia | &nbsp; |
| me_ced_ruc | Char | 13  | NOT NULL | Número de identificación del cliente | &nbsp; |
| me_documento | Int | 4   | NOT NULL | No aplica | &nbsp; |
| me_nombre | Varchar | 40  | NOT NULL | Nombre del cliente | &nbsp; |
| me_fecha_ref | Datetime | 8   | NOT NULL | Fecha de referencia del registro | &nbsp; |
| me_calificador | Char | 40  | NOT NULL | Nombre del calificador de la referencia | &nbsp; |
| me_calificacion | Char | 15  | NOT NULL | Calificación asignada a la referencia | &nbsp; |
| me_fuente | Char | 40  | NOT NULL | Código del origen de la referencia | &nbsp; |
| me_observacion | Char | 80  | NOT NULL | Comentario u observación adicional de la referencia | &nbsp; |
| me_subtipo | Char | 1   | NOT NULL | Indica el tipo de cliente | P= Personal C= Compañía |
| me_tipo_ced | Char | 2   | NOT NULL | Tipo del documento de identificación | &nbsp; |
| me_p_apellido | Varchar | 16  | NULL | Primer apellido del cliente | &nbsp; |
| me_s_apellido | Varchar | 16  | NULL | Segundo apellido del cliente | &nbsp; |
| me_fecha_mod | Datetime | 8   | NULL | Fecha de última modificación del registro | &nbsp; |
| me_estado | catalogo | 10  | NULL | Estado de nacimiento del cliente |     |
| me_nomlar | Varchar | 64  | NULL | Nombre completo del cliente | &nbsp; |
| me_sexo | Varchar | 1   | NULL | Indica el sexo del cliente | M= Masculino<br><br>F= Femenino |

### cl_ref_personal

Información que contiene todas las referencias personales de una persona natural, pueden ser una o varias personas.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| rp_persona | Int | 4   | NOT NULL | Código Cobis del ente. | &nbsp; |
| rp_referencia | Tinyint | 1   | NOT NULL | Secuencial de la referencia por ente. | &nbsp; |
| rp_nombre | Varchar | 60  | NOT NULL | Nombres de la persona que da la referencia. | &nbsp; |
| rp_p_apellido | Varchar | 20  | NOT NULL | Apellido paterno de la persona que da la referencia. | &nbsp; |
| rp_s_apellido | Varchar | 20  | NULL | Apellido materno de la persona que da la referencia. | &nbsp; |
| rp_direccion | direccion | 255 | NULL | Dirección de la persona que da la referencia. No aplica | &nbsp; |
| rp_telefono_d | Char | 12  | NULL | Número de teléfono del domicilio de la persona que da la referencia. | &nbsp; |
| rp_telefono_e | Char | 12  | NULL | Número de teléfono del lugar de trabajo de la persona que da la referencia. No aplica | &nbsp; |
| rp_telefono_o | Char | 12  | NULL | Número de teléfono adicional de la persona que da la referencia. No aplica | &nbsp; |
| rp_parentesco | catalogo | 10  | NOT NULL | Tipo de parentesco que le une al ente con la persona que da la referencia. Puede tomar cualquier valor de la tabla de catálogo cl_parentesco. | &nbsp;(cl_parentesco) |
| rp_fecha_registro | Datetime | 8   | NOT NULL | Fecha en que fue creado el registro en la tabla. | &nbsp; |
| rp_fecha_modificacion | Datetime | 8   | NOT NULL | Fecha de la última modificación del registro. | &nbsp; |
| rp_vigencia | Char | 1   | NOT NULL | Indicador de vigencia del registro. | S= Vigente N= No vigente |
| rp_verificacion | Char | 1   | NOT NULL | Indica si los datos ya han sido verificados. No aplica | S= Verificada N= Falta verificar |
| rp_funcionario | login | 14  | NULL | Login del funcionario que llevo a cabo la verificación de datos. No aplica | &nbsp; |
| rp_descripcion | Varchar | 64  | NULL | Comentario adicional. No aplica | &nbsp; |
| rp_fecha_ver | Datetime | 8   | NULL | Fecha en que se realizó la verificación de datos. No aplica | &nbsp; |
| rp_departamento | Varchar | 10  | NULL | Departamento de la persona que da la referencia.No aplica |     |
| rp_ciudad | Varchar | 10  | NULL | Ciudad de la persona que da la referencia. No aplica |     |
| rp_barrio | Varchar | 10  | NULL | Barrio de la persona que da la referencia. No aplica |     |
| rp_obs_verificado | Varchar | 10  | NULL | No aplica |     |
| rp_calle | Varchar | 80  | NULL | Calle de la persona que da la referencia. No aplica |     |
| rp_nro | Int | 4   | NULL | No aplica |     |
| rp_colonia | Varchar | 10  | NULL | Colonia de la persona que da la referencia. No aplica |     |
| rp_localidad | Varchar | 10  | NULL | Localidad de la persona que da la referencia. No aplica |     |
| rp_municipio | Varchar | 10  | NULL | Municipio de la persona que da la referencia. No aplica |     |
| rp_estado | Varchar | 10  | NULL | Estado de la persona que da la referencia. No aplica |     |
| rp_codpostal | Varchar | 30  | NULL | Código postal de la persona que da la referencia. No aplica |     |
| rp_pais | Varchar | 10  | NULL | País de la persona que da la referencia. No aplica |     |
| rp_tiempo_conocido | Int | 4   | NULL | No aplica |     |
| rp_direccion_e | Varchar | 40  | NULL | Dirección en el extranjero de la persona que da la referencia. No aplica |     |

### cl_referencia (No se usa en esta versión)

Contiene información común de las referencias de una persona natural o jurídica. las referencias pueden ser, bancarias, financieras, económicas y de tarjeta de crédito, las cuales se despliegan en vistas.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| re_ente | int | 4   | NOT NULL | Código Cobis del ente. | &nbsp; |
| re_referencia | tinyint | 1   | NOT NULL | Secuencial de la referencia por ente. | &nbsp; |
| re_tipo | char | 1   | NOT NULL | Indica el tipo de referencia económica | B= Bancaria T= Tarjeta C= Comercial F= Financiera |
| re_tipo_cifras | char | 2   | NULL | Tipo de cifras que se manejan en las referencias de la persona | &nbsp; |
| re_numero_cifras | tinyint | 1   | NULL | Número de cifras que se manejan en las referencias de la persona | &nbsp; |
| re_fecha_registro | datetime | 8   | NULL | Fecha en que fue creado el registro en la tabla. | &nbsp; |
| re_calificacion | char | 2   | NULL | Calificación otorgada por la entidad financiera o institución comercial al ente. | &nbsp; |
| re_verificacion | char | 1   | NOT NULL | Indica si los datos han sido verificados | S= Verificada N= Falta verificar |
| re_fecha_ver | datetime | 8   | NULL | Fecha en que se realizó la verificación de datos. | &nbsp; |
| re_fecha_modificacion | datetime | 8   | NOT NULL | Fecha de la última modificación del registro. | &nbsp; |
| re_vigencia | char | 1   | NOT NULL | Indicador de vigencia del registro. | S= Vigente N= No vigente |
| re_observacion | varchar | 254 | NULL | Comentario que se desee realizar respecto a la referencia económica del ente. | &nbsp; |
| re_funcionario | login | 14  | NULL | Funcionario que ingresó la referencia del cliente | &nbsp; |
| re_nacional | char | 1   | NULL | Indica si la institución está dentro del país | N= Nacional E= Extranjera |
| re_ciudad | int | 4   | NULL | Ciudad | &nbsp; |
| re_sucursal | varchar | 20  | NULL | Descripción de la sucursal de la referencia | &nbsp; |
| re_telefono | char | 16  | NULL | Número de teléfono de la referencia | &nbsp; |
| re_estado | catalogo | 10  | NULL | Estado de la referencia | &nbsp; |
| ec_tipo_cta | catalogo | 10  | NULL | Tipo de cuenta que pasa como referencia económica. puede ser ahorros, corrientes, otras |     |
| ec_moneda | tinyint | 1   | NULL | Moneda de la cuenta del cliente | &nbsp; |
| ec_fec_apertura | datetime | 8   | NULL | Fecha de apertura de la cuenta que va como referencia económica | &nbsp; |
| ec_cuenta | varchar | 20  | NULL | Número de la cuenta que pasa como referencia económica | &nbsp; |
| ec_banco | int | 4   | NULL | Código del banco que reporta la referencia económica del cliente | &nbsp; |
| monto | money | 8   | NULL | Monto | &nbsp; |
| ec_fec_exp_ref | datetime | 8   | NULL | Fecha de expiración de la referencia | &nbsp; |
| fi_banco | int | 4   | NULL | Código Cobis de la entidad financiera en la cual el ente registra una operación pasiva o activa motivo de la referencia. Puede tomar cualquier valor definido en la tabla de catálogo | &nbsp; |
| fi_toperacion | char | 1   | NULL | Indica el tipo de operación realizada por el cliente. | &nbsp; |
| fi_clase | descripcion | 160 | NULL | Clase de ref. financiera | A= Activo P= Pasivo |
| fi_fec_inicio | datetime | 8   | NULL | fecha de inicio de la referencia financiera | &nbsp; |
| fi_fec_vencimiento | datetime | 8   | NULL | Fecha de vencimiento de la referencia financiera | &nbsp; |
| fi_estatus | char | 1   | NULL | Muestra el estado de la referencia financiera. | &nbsp; |
| fi_garantia | char | 1   | NULL | No aplica | A= Activo C= Cancelado |
| fi_cupo_usado | money | 8   | NULL | Saldo de la referencia financiera | &nbsp; |
| fi_monto_vencido | money | 8   | NULL | Monto de la referencia financiera | &nbsp; |
| ta_banco | catalogo | 10  | NULL | Código del banco o entidad financiera que emite la tarjeta de crédito | &nbsp; |
| ta_cuenta | varchar | 30  | NULL | Número de la tarjeta de crédito | &nbsp; |
| ta_fec_apertura | datetime | 8   | NULL | Fecha de apertura de la tarjeta | &nbsp; |
| co_institucion | descripcion | 160 | NULL | Descripción del banco |     |
| co_fecha_ingr_en_inst | datetime | 8   | NULL | Fecha ingreso |     |
| re_obs_verificado | varchar | 10  | NULL | No aplica | &nbsp; |

### cl_refinh

Guarda la información de las referencias inhibitorias del cliente

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| in_codigo | Int | 4   | NOT NULL | Código secuencial de la referencia | &nbsp; |
| in_documento | Int | 4   | NOT NULL | No aplica | &nbsp; |
| in_ced_ruc | numero | 30  | NOT NULL | Número de identificación del cliente | &nbsp; |
| in_nombre | Varchar | 64  | NOT NULL | Nombre del cliente | &nbsp; |
| in_fecha_ref | Datetime | 8   | NOT NULL | Fecha de referencia del registro | &nbsp; |
| in_origen | catalogo | 10  | NOT NULL | Código del origen de la referencia | &nbsp; |
| in_observacion | Varchar | 255 | NOT NULL | Comentario u observación adicional de la referencia | &nbsp; |
| in_fecha_mod | Datetime | 8   | NOT NULL | Fecha de la última modificación del registro | &nbsp; |
| in_subtipo | Char | 1   | NOT NULL | Indica el tipo de cliente | N= Natural J= Jurídica |
| in_p_p_apellido | Varchar | 16  | NULL | Primer apellido del cliente | &nbsp; |
| in_p_s_apellido | Varchar | 16  | NULL | Segundo apellido del cliente | &nbsp; |
| in_tipo_ced | Char | 2   | NULL | Tipo del documento de identificación | &nbsp; |
| in_nomlar | Varchar | 64  | NULL | Nombre completo del cliente | &nbsp; |
| in_estado | catalogo | 10  | NULL | Estado del cliente | &nbsp; |
| in_sexo | Char | 1   | NULL | Sexo del cliente | &nbsp; |
| in_usuario | login | 14  | NULL | Nombre de login del usuario que registra la referencia del cliente | &nbsp; |
| in_aka | Varchar | 120 | NULL |     | &nbsp; |
| in_categoria | Varchar | 20  | NULL | Categoría del cliente | &nbsp; |
| in_subcategoria | Varchar | 20  | NULL | Subcategoría del cliente | &nbsp; |
| in_fuente | Varchar | 20  | NULL |     | &nbsp; |
| in_otroid | Varchar | 20  | NULL |     | &nbsp; |
| in_pasaporte | Varchar | 20  | NULL | Pasaporte del cliente | &nbsp; |
| in_concepto | Varchar | 100 | NULL | Concepto de la referencia del cliente | &nbsp; |
| in_entid | Int | 1   | NULL |     | &nbsp; |

### cl_relacion

Contiene información general de las relaciones que pueden darse entre dos personas naturales o jurídicas.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| re_relacion | Int | 4   | NOT NULL | Secuencial para la tabla e identificador de la relación para el resto del sistema. | &nbsp; |
| re_descripcion | descripcion | 160 | NOT NULL | Nombre o definición de la relación. | &nbsp; |
| re_izquierda | descripcion | 160 | NOT NULL | Mensaje del lado izquierdo de la relación | &nbsp; |
| re_derecha | descripcion | 160 | NOT NULL | Mensaje del lado derecho de la relación | &nbsp; |
| re_tabla | Smallint | 2   | NULL | No aplica. | &nbsp; |
| re_catalogo | Varchar | 10  | NULL | No aplica. | &nbsp; |
| re_atributo | Tinyint | 1   | NOT NULL | Número de atributos definidos para la relación. | &nbsp; |
| re_vinculacion | Varchar | 10  | NULL | Numero de vinculación |     |
| re_tipo_vinculaciion | varchar | 30  | NULL | Nombre de tipo de vinculacion |     |

### cl_telefono

Almacena la información de los teléfonos de las direcciones de una persona natural o jurídica.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| te_ente | Int | 4   | NOT NULL | Código Cobis del ente. | &nbsp; |
| te_direccion | Tinyint | 1   | NOT NULL | Secuencial de la dirección del ente al cual pertenece el número telefónico. | &nbsp; |
| te_secuencial | Tinyint | 1   | NOT NULL | Secuencial del número telefónico para una dirección específica del ente. | &nbsp; |
| te_valor | Varchar | 16  | NULL | Número telefónico del ente. | &nbsp; |
| te_tipo_telefono | Char | 1   | NOT NULL | Tipo de número telefónico, corresponde a un valor definido en la tabla de catálogo cl_ttelefono. | &nbsp;(cl_ttelefono) |
| te_prefijo | Varchar | 10  | NULL | Prefijo del teléfono. No aplica |     |
| te_fecha_registro | Datetime | 8   | NULL | Fecha de registro |     |
| te_fecha_mod | Datetime | 8   | NULL | Fecha de modificacion |     |
| te_tipo_operador | Varchar | 10  | NULL | No aplica |     |
| te_area | Varchar | 10  | NULL | Indica el código de área |     |
| te_telf_cobro | Char | 1   | NULL | Indica si el número telefónico es de cobro. No aplica | S= SI<br><br>N= No |
| te_funcionario | login | 14  | NULL | Login de funcionario |     |
| te_verificado | char | 1   | NULL | Indica si esta verificado. No aplica | S= SI<br><br>N= No |
| te_fecha_ver | Datetime | 8   | NULL | Fecha de Verificación. No aplica |     |
| te_fecha_modificacion | Datetime | 8   | NULL | Fecha de actualización del teléfono |     |

### cl_tipo_documento

Tipos de documentos de identificación soportados.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| td_secuencial | Int | 4   | NOT NULL | Secuencial | &nbsp; |
| td_codigo | Char | 4   | NOT NULL | Código | &nbsp; |
| td_descripcion | Varchar | 60  | NOT NULL | Descripción del documento | &nbsp; |
| td_mascara | Varchar | 20  | NULL | Mascara aplicada | &nbsp; |
| td_tipoper | Char | 1   | NULL | Se define la naturaleza o tipo de persona asociada a una identificación. | P= Persona natural C= Compañía |
| td_provincia | Char | 1   | NULL | Indica si el documento procede de una provincia | S= Provincia N= Normal |
| td_aperrapida | Char | 1   | NULL | Indica si el documento es una apertura rápida. | S= Apertura rápida N= Normal |
| td_bloquea | Char | 1   | NULL | Indica si el documento ha sido bloqueado | S= Bloqueado N= Desbloqueado |
| td_nacionalidad | Varchar | 15  | NULL | País nacionalidad | &nbsp; |
| td_digito | Char | 1   | NULL | Indica si el documento posee dígito verificador | S= Dígito verificador N= Sin dígito |
| td_estado | Char | 1   | NULL | Indica el estado del documento | V= Vigente C= Cancelado E= Eliminado |
| td_desc_corta | varchar | 10  | NULL | Indica la descripción corte del documento |     |
| td_compuesto | char | 1   | NULL | Indica si es compuesto | S= SI<br><br>N= No |
| td_nro_compuesto | tinyint | 1   | NULL | Numero de compuesto |     |
| td_adicional | tinyint | 1   | NULL | Indica si hay adicional |     |
| td_creacion | char | 1   | NULL | Indica si es de cracion |     |
| td_habilitado_mis | char | 1   | NULL | No aplica |     |
| td_tipo_doc | char | 10  | NUL | Tipo de documento | cl_tipo_identificacion |
| td_tipo_residencia | char | 10  | NUL | Tipo de residencia en la que aplica el documento | cl_tipo_residencia |
| td_habilitado_usu | char | 1   | NULL | Indica si esta habilitado el usuario | S= SI<br><br>N= No |
| td_prefijo | varchar | 10  | NULL | Prefijo |     |
| td_subfijo | varchar | 10  | NULL | Sufijo |     |

### cl_com_liquidacion

Tabla en la que se insertan las malas referencias externas.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cl_codigo | Int | 4   | NOT NULL | Código del registro. | &nbsp; |
| cl_nombre | descripcion | 160 | NOT NULL | Nombre de la mala referencia. | &nbsp; |
| cl_tipo | Char | 1   | NOT NULL | Tipo de persona | P: Persona Natural<br><br>C: Persona Jurídica<br><br>N: Sin tipo |
| cl_problema | catalogo | 10  | NOT NULL | Tipo de mala referencia | &nbsp;cl_problema |
| cl_referencia | descripcion | 160 | NULL | Referencia de la mala referencia | &nbsp; |
| cl_ced_ruc | numero | 30  | NULL | Cédula de la persona | &nbsp; |
| cl_fecha | Datetime | 8   | NULL | Fecha de registro | &nbsp; |
| Monto | Money | 8   | NULL | No aplica | &nbsp; |
| cl_tipo_ref | catalogo | 10  | NULL | Tipo de referencia | cl_tipo_mala_referencia |

### cl_narcos

Contiene información de personas que tienen mala referencia por el narcotráfico o lista Clinton.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| na_narcos | Int | 4   | NULL | Código secuencial del registro en la tabla. | &nbsp; |
| na_nombre | Varchar | 40  | NULL | Nombres de la persona asociada la mala referencia por vinculación al narcotráfico. | &nbsp; |
| na_cedula | Char | 13  | NULL | Número de documento de identificación de la persona asociada la mala referencia por vinculación al narcotráfico. | &nbsp; |
| na_pasaporte | Char | 20  | NULL | Número de documento de pasaporte de la persona asociada la mala referencia por vinculación al narcotráfico. | &nbsp; |
| na_nacionalidad | Char | 20  | NULL | Definición de la nacionalidad de la persona asociada a la mala referencia por vinculación al narcotráfico. | &nbsp; |
| na_circular | Char | 12  | NULL | Circular que reporte al cliente como vinculado al narcotráfico | &nbsp; |
| na_fecha | Char | 12  | NULL | Fecha de registro | &nbsp; |
| na_provincia | Char | 15  | NULL | Nombre de la provincia en la cual se origina la información. | &nbsp; |
| na_juzgado | Char | 10  | NULL | Nombre del juzgado que determinó la vinculación de la persona al narcotráfico. | &nbsp; |
| na_juicio | Char | 10  | NULL | Número del juicio con el cual se determinó la vinculación de la persona al narcotráfico. | &nbsp; |

### cl_actividad_principal

Catálogo que contiene información de las actividades principales de los entes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ap_codigo | catalogo | 10  | NOT NULL | Código de actividad principal | &nbsp; |
| ap_descripcion | Varchar | 250 | NULL | Descripción | &nbsp; |
| ap_activ_comer | catalogo | 10  | NULL | Código de actividad comercial a la cual está relacionada (catálogo cl_fuente_ingreso) | &nbsp; |
| ap_estado | Char | 1   | NULL | Estado del registro | V= Vigente E= Eliminado |

### cl_ente_aux

Tabla complementaria de información del ente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ea_ente | Int | 4   | NOT NULL | Código del ente | &nbsp; |
| ea_estado | catalogo | 10  | NOT NULL | Estado del ente | &nbsp; |
| ea_observacion_aut | Varchar | 255 | NULL | Observación del autorizador. No aplica | &nbsp; |
| ea_contrato_firmado | Char | 1   | NULL | Contrato Único | S= Es contrato único N= No es contrato único |
| ea_menor_edad | Char | 1   | NULL | Cliente es menor de edad | S= Es menor de edad<br><br>N= Mayor de edad |
| ea_conocido_como | Varchar | 255 | NULL | Descripción del ente | &nbsp; |
| ea_cliente_planilla | Char | 1   | NULL | Es cliente de planilla | S= Es cliente de planilla<br><br>N= No es cliente de planilla |
| ea_cod_risk | Varchar | 20  | NULL | Código Risk | &nbsp; |
| ea_sector_eco | catalogo | 10  | NULL | Sector económico | &nbsp;(cl_sector_economico) |
| ea_actividad | catalogo | 10  | NULL | Actividad del ente | &nbsp;(cl_actividad_economica) |
| ea_lin_neg | catalogo | 10  | NULL | Línea de Negocio. No aplica | &nbsp; |
| ea_seg_neg | catalogo | 10  | NULL | Segmento de negocio. No aplica | &nbsp; |
| ea_ejecutivo_con | Int | 4   | NULL | Código de Ejecutivo de contacto | &nbsp; |
| ea_suc_gestion | Smallint | 2   | NULL | Sucursal de gestión | &nbsp; |
| ea_constitucion | Smallint | 2   | NULL | Constitución | &nbsp; |
| ea_remp_legal | Int | 4   | NULL | Representante Legal | &nbsp; |
| ea_apoderado_legal | Int | 4   | NULL | Apoderado Legal | &nbsp; |
| ea_no_req_kyc_comp | char | 1   | NULL | No aplica | &nbsp; |
| ea_fuente_ing | catalogo | 10  | NULL | Fuente de ingreso | &nbsp; |
| ea_act_prin | catalogo | 10  | NULL | Actividad principal | &nbsp; |
| ea_detalle | Varchar | 255 | NULL | Detalle de actividad económica | &nbsp; |
| ea_act_dol | Money | 8   | NULL | Actividad dolarizada mensual | &nbsp; |
| ea_cat_aml | catalogo | 10  | NULL | Catálogo AML | &nbsp; |
| ea_fecha_vincula | Datetime | 8   | NULL | Fecha de vinculación | &nbsp; |
| ea_observacion_vincula | Varchar | 255 | NULL | Observación de vinculación |     |
| ea_ced_ruc | numero | 30  | NULL | Guarda la cedula o ruc de la persona |     |
| ea_discapacidad | Char | 1   | NULL | Presencia de discapacidad | S=Cliente tiene discapacidad<br><br>N= Cliente no tiene discapacidad |
| ea_tipo_discapacidad | catalogo | 10  | NULL | Catálogo de Tipo de Discapacidad |     |
| ea_ced_discapacidad | Varchar | 30  | NULL | Cédula de Discapacidad |     |
| ea_id_prefijo | Catalogo | 10  | NULL | Prefijo de número de Identificación |     |
| ea_id_sufijo | Catalogo | 10  | NULL | Sufijo de número de Identificación |     |
| ea_duplicado | Char | 1   | NULL | Número de identificación marcado como duplicado | S,N |
| ea_nivel_egresos | catalogo | 10  | NULL | Catálogo Nivel de Egresos |     |
| ea_ifi | Char | 1   | NULL | Productos en otras IFI | &nbsp;S= Cliente se encuentra en otras IFI<br><br>N= Cliente no está en otras IFI |
| ea_asfi | Char | 1   | NULL | Pleno y Oportuno Pago ASFI | S= Cliente tiene oportuno pago ASFI<br><br>N= Cliente no tiene oportuno pago ASFI |
| ea_path_foto | Varchar | 50  | NULL | Path de la imagen del cliente |     |
| ea_nit | numero | 30  | NULL |     |     |
| ea_nit_venc | datetime | 8   | NULL |     |     |
| ea_num_testimonio | varchar | 10  | NULL | Indica el nùmero de testimonio. |     |
| ea_indefinido | char | 1   | NULL | Indica si la fecha de vigencia correspone a la fecha máxima definida. |     |
| ea_fecha_vigencia | datetime | 8   | NULL | Fecha de vigencia. |     |
| ea_nombre_notaria | varchar | 64  | NULL | Nombre de la notaria |     |
| ea_nombre_notario | varchar | 64  | NULL | Nombre del Notario |     |
| ea_safie | varchar | 20  | NULL | Código cliente SIFIE. No aplica |     |
| ea_sigaf | varchar | 20  | NULL | Código cliente SIGAF. No aplica |     |
| ea_tipo_creacion | char | 1   | NULL | No aplica |     |
| ea_ventas | money | 8   | NULL | Valor en ventas |     |
| ea_ot_ingresos | money | 8   | NULL | Valor otros ingresos |     |
| ea_ct_ventas | money | 8   | NULL | Número de cuenta |     |
| ea_ct_operativo | money | 8   | NULL | No aplica |     |
| ea_ant_nego | int | 4   | NULL | No aplica |     |
| ea_cta_banco | Varchar | 45  | NULL | Número de cuenta principal del ente |     |
| ea_nro_ciclo_oi | int | 4   | NULL | No aplica |     |
| ea_partner | char | 1   | NULL | No aplica |     |
| ea_lista_negra | char | 1   | NULL | Indica si el cliente está en una lista negra | S= Si,<br><br>N= No |
| ea_tecnologico | char | 10  | NULL | No aplica |     |
| ea_fiel | varchar | 20  | NULL | No aplica |     |
| ea_estado_std | varchar | 10  | NULL | No aplica |     |
| ea_experiencia | char | 1   | NULL | No aplica |     |
| ea_fecha_report | datetime | 8   | NULL | No aplica |     |
| ea_fecha_report_resp | datetime | 8   | NULL | No aplica |     |
| ea_numero_ife | varchar | 13  | NULL | No aplica |     |
| ea_num_serie_firma | varchar | 20  | NULL | No aplica |     |
| ea_telef_recados | varchar | 10  | NULL | Teléfono que se usa para comunicar con el cliente. |     |
| ea_persona_recados | varchar | 60  | NULL | No aplica |     |
| ea_antecedente_buro | varchar | 2   | NULL | No aplica |     |
| ea_nivel_riesgo | varchar | 50  | NULL | Nivel de riesgo |     |
| ea_puntaje_riesgo | int | 4   | NULL | Porcentaje de riesgo |     |
| ea_negative_file | char | 1   | NULL | No aplica |     |
| ea_nivel_riesgo_cg | char | 1   | NULL | No aplica |     |
| ea_puntaje_riesgo_cg | char | 3   | NULL | No aplica |     |
| ea_calif_riesgo | char | 1   | NULL | No aplica |     |
| ea_ptos_riesgo | int | 4   | NULL | No aplica |     |
| ea_fecha_evaluacion | datetime | 8   | NULL | No aplica |     |
| ea_sum_vencido | money | 8   | NULL | No aplica |     |
| ea_num_vencido | int | 4   | NULL | No aplica |     |
| ea_calif_buro | varchar | 10  | NULL | No aplica |     |
| ea_calif_3sis | varchar | 10  | NULL | No aplica |     |
| ea_calif_cliente | varchar | 10  | NULL | No aplica |     |
| ea_puntaje_efl | int | 4   | NULL | No aplica |     |
| ea_ingreso_legal | char | 1   | NULL | No aplica |     |
| ea_actividad_legal | char | 1   | NULL | No aplica |     |
| ea_otra_cuenta_banc | char | 1   | NULL | No aplica |     |
| ea_fatca | char | 1   | NULL | No aplica |     |
| ea_crs | char | 1   | NULL | No aplica |     |
| ea_ejerce_control | char | 1   | NULL | No aplica |     |
| ea_s_inversion_ifi | char | 1   | NULL | No aplica |     |
| ea_s_inversion | char | 1   | NULL | No aplica |     |
| ea_ifid | char | 1   | NULL | No aplica |     |
| ea_c_merc_valor | char | 1   | NULL | No aplica |     |
| ea_c_nombre_merc_valor | varchar | 100 | NULL | No aplica |     |
| ea_ong_sfl | char | 1   | NULL | No aplica |     |
| ea_ifi_np | char | 1   | NULL | No aplica |     |
| ea_provincia_res | varchar | 10  | NULL | No aplica |     |

### cl_mod_estados (No se usa en esta versión)

Registra los cambios de estado realizados al ente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| me_sec | Int | 4   | NOT NULL | Secuencial | &nbsp; |
| me_ente | Int | 4   | NULL | Código Ente | &nbsp; |
| me_usuario | login | 14  | NULL | Usuario | &nbsp; |
| me_fecha | Datetime | 8   | NULL | Fecha de cambio | &nbsp; |
| me_est_act | catalogo | 10  | NULL | Estado actual | &nbsp; |
| me_est_nue | catalogo | 10  | NULL | Nuevo estado | &nbsp; |
| me_observacion | descripcion | 160 | NULL | Observación | &nbsp; |
| me_interface | catalogo | 10  | NULL | Interface |     |

### cl_sector_economico

Tabla que almacena los sectores economicos

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| se_codigo | catalogo | 10  | NOT NULL | Codigo de la tabla sector economico |     |
| se_descripcion | descripcion | 160 | NULL | Descripcion del sector economico |     |
| se_estado | estado | 1   | NULL | Estado del campo |     |
| se_codFuentIng | char | 10  | NULL | Cod. De la fuente de ingresos |     |

### cl_subsector_ec

Tabla que almacena subsectores económicos relacionados a un sector económico

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| se_codigo | catalogo | 10  | NOT NULL | Codigo de la tabla subsector economico |     |
| se_descripcion | descripcion | 160 | NULL | Descripcion del subsector economico |     |
| se_estado | estado | 1   | NULL | Estado del campo |     |
| se_codSector | catalogo | 10  | NULL | Cod. Del sector económico |     |

### cl_subactividad_ec

Tabla que almacena subactividades económicas relacionadas a una actividad económica que a nivel de pantalla se visualizara como Actividad.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| se_codigo | catalogo | 10  | NOT NULL | Codigo de la tabla subactividad economica |     |
| se_descripcion | varchar | 254 | NULL | Descripcion de la subactividad |     |
| se_estado | estado | 1   | NULL | Estado del campo |     |
| se_codActEc | catalogo | 10  | NULL | Codigo de actividad económica |     |
| se_codCaedge | varchar | 254 | NULL | No se usa en esta versión |     |
| se_aclaracionFie | varchar | 254 | NULL | No se usa en esta versión |     |
| se_aclaracionFie2 | varchar | 254 | NULL | No se usa en esta versión |     |
| se_aclaracionFie3 | varchar | 254 | NULL | No se usa en esta versión |     |
| se_aclaracionFie4 | varchar | 254 | NULL | No se usa en esta versión |     |

### cl_actividad_economica

Tabla que almacena las actividades económicas.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ae_secuencial | Int | 4   | NOT NULL | Secuencial de la tabla |     |
| ae_ente | Int | 4   | NOT NULL | Codigo del cliente |     |
| ae_actividad | Varchar | 10  | NOT NULL | Codigo de actividad económica |     |
| ae_sector | Varchar | 10  | NOT NULL | Codigo de sector económico |     |
| ae_subactividad | Varchar | 10  | NOT NULL | Codigo de sub actividad económica |     |
| ae_subsector | Varchar | 10  | NOT NULL | Codigo de sub sector económico |     |
| ae_fuente_ing | Varchar | 10  | NOT NULL | Codigo de fuente de ingresos |     |
| ae_principal | Char | 1   | NOT NULL | Indica si la actividad económica es principal o no |     |
| ae_dias_atencion | Varchar | 10  | NOT NULL | Codigo de dias de atención |     |
| ae_horario_atencion | Varchar | 20  | NOT NULL | Horario de atención |     |
| ae_fecha_inicio_act | Datetime | 8   | NULL | Fecha de inicio de la actividad económica |     |
| ae_antiguedad | Int | 4   | NULL | Número de meses de antiguedad |     |
| ae_ambiente | Varchar | 10  | NULL | Codigo de ambiente |     |
| ae_autorizado | Char | 1   | NOT NULL | Indica si la actividad económica es autorizada o no |     |
| ae_afiliado | Char | 1   | NOT NULL | Indica si es afiliado no |     |
| ae_lugar_afiliacion | Varchar | 64  | NULL | Lugar de afiliación |     |
| ae_num_empleados | Int | 4   | NULL | Número de empleados |     |
| ae_desc_actividad | Varchar | 255 | NULL | Descripción de la actividad económica |     |
| ae_ubicacion | Varchar | 10  | NOT NULL | Codigo de tipo de propiedad |     |
| ae_horario_actividad | Varchar | 20  | NOT NULL | Horario de actividad económica |     |
| ae_desc_caedec | Varchar | 255 | NULL | Descripcion de CAEDEC |     |
| ae_estado | Char | 1   | NULL | Estado de la actividad |     |
| ae_verificado | Char | 1   | NULL | Verificación |     |
| ae_fecha_verificacion | Datetime | 8   | NULL | Fecha de verificación |     |
| ae_fuente_verificacion | Varchar | 10  | NULL | Fuente de verificación |     |
| ae_funcionario | login | 14  | NULL | Usuario que realizó el registro |     |
| ae_fecha_modificacion | Datetime | 8   | NULL | Fecha de modificación |     |

### cl_listas_negras (No se usa en esta versión)

Tabla que almacena los clientes que pertenecen a Listas Negras.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pe_persona_id | varchar | 25  | NOT NULL | Secuencial de la tabla |     |
| pe_nombre | varchar | 100 | NOT NULL | Nombre |     |
| pe_paterno | varchar | 100 | NOT NULL | Apellido paterno |     |
| pe_materno | varchar | 100 | NULL | Apellido materno |     |
| pe_curp | varchar | 20  | NULL | Codigo Curp |     |
| pe_rfc | varchar | 15  | NULL | Codigo Rfc |     |
| pe_fecha_nacimiento | varchar | 10  | NULL | Fecha de nacimiento |     |
| pe_lista | varchar | 10  | NULL | Tipo de lista |     |
| pe_estatus | varchar | 20  | NULL | Tipo de estado |     |
| pe_dependencia | varchar | 200 | NULL | Lugar de dependencia |     |
| pe_puesto | varchar | 200 | NULL | Tipo de puesto |     |
| pe_iddispo | int | 4   | NULL | Numero disponbile |     |
| pe_curp_ok | int | 4   | NULL | Estado del curp |     |
| pe_idrel | varchar | 25  | NULL | No aplica |     |
| pe_parentesco | varchar | 20  | NULL | No aplica |     |
| pe_razonsoc | varchar | 250 | NULL | Nombre de la empresa |     |
| pe_rfcmoral | varchar | 15  | NULL | No aplica |     |
| pe_issste | varchar | 50  | NULL | No aplica |     |
| pe_imss | varchar | 50  | NULL | No aplica |     |
| pe_ingresos | varchar | 20  | NULL | Numero de ingresos |     |
| pe_nomcomp | varchar | 300 | NULL | Nombre completo |     |
| pe_apellidos | varchar | 200 | NULL | Apellidos completos |     |
| pe_entidad | varchar | 50  | NULL | Ubicación |     |
| pe_sexo | varchar | 10  | NULL | Sexo |     |
| pe_area | varchar | 200 | NULL | Area de ubicación |     |
| pe_alias | varchar | 250 | NULL | No aplica |     |
| pe_registro_id | varchar | 25  | NULL | No aplica |     |
| pe_tipo_carga | varchar | 2   | NULL | No aplica |     |
| px_excluidos_id | tinyint | 1   | NOT NULL | Tipo de excluido |     |
| pe_fecha_registro | datetime | 8   | NULL | Fecha de ingreso |     |

### cl_infocred_central (No se usa en esta versión)

Tabla que consolida la información de los clientes que se encuentran en los reportes de crédito Infocred.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ic_tipo_id | catalogo | 10  | NULL | Tipo de identificación homologado |     |
| ic_id | Int | 4   | NULL | Número de identificación completa |     |
| ic_nomlar | Varchar | 254 | NULL | Nombres y apellidos de la persona |     |
| ic_fecha_nac | Datetime | 8   | NULL | Fecha de nacimiento de la persona en formato dd/mm/aaaa |     |
| ic_entidad | Varchar | 254 | NULL | Entidad donde se reporta la obligación. |     |
| ic_tipo_obligacion | Varchar | 50  | NULL | Tipo de obligación que tiene el cliente en una entidad específica. |     |
| ic_tipo_credito | Varchar | 254 | NULL | Tipo de crédito que tiene en cliente en una entidad específica |     |
| ic_estado_act | Varchar | 20  | NULL | Estado actual del crédito |     |
| ic_monto_act | money | 8   | NULL | Monto actual del crédito |     |
| ic_fecha_crea_deuda | Datetime | 8   | NULL | Fecha de creación de la deuda |     |
| ic_fecha_act_deuda | Datetime | 8   | NULL | Fecha de actualización de la deuda |     |
| ic_tipo_lista | Varchar | 20  | NULL | Indica el tipo de la lista |     |

### cl_direccion_geo

Tabla que almacena las coordenadas para la georreferenciación de una dirección.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dg_ente | int | 4   | NULL | Codigo de ente |     |
| dg_direccion | int | 4   | NULL | Codigo de direccion |     |
| dg_lat_coord | char | 1   | NULL | No aplica |     |
| dg_lat_grad | tinyint | 1   | NULL | No aplica |     |
| dg_lat_min | tinyint | 1   | NULL | No aplica |     |
| dg_lat_seg | float | 8   | NULL | Numero de latitud |     |
| dg_long_coord | char | 1   | NULL | No aplica |     |
| dg_long_grad | tinyint | 1   | NULL | No aplica |     |
| dg_long_min | tinyint | 1   | NULL | No aplica |     |
| dg_long_seg | float | 8   | NULL | Numero de longitud |     |
| dg_path_croquis | varchar | 50  | NULL | No aplica |     |
| dg_secuencial | int | 4   | NULL | Codigo secuencial |     |
| dg_tipo | varchar | 10  | NULL | Tipo de direccion |     |

### cl_dato_adicion

Almacena los tipos de datos adicionales que pueden tener los clientes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| da_codigo | Smallint | 2   | NOT NULL | Código del dato adicional | &nbsp; |
| da_descripcion | descripcion | 64  | NULL | Descripción del dato adicional | &nbsp; |
| da_tipo_dato | Char | 1   | NOT NULL | Tipo de dato | A: Catalogo<br><br>C: Carácter<br><br>D: Datetime<br><br>F: Float<br><br>I: Int<br><br>M: Money<br><br>P: Pseudocatalogo<br><br>S: Smallint<br><br>T: Tinyint<br><br>X: Texto |
| da_mandatorio | Char | 1   | NOT NULL | Indica si el campo va a ser mandatorio | S: SI<br><br>N: NO |
| da_valor | descripcion | 64  | NULL | El valor del dato adicional |     |
| da_tipo_ente | Char | 1   | NOT NULL | Tipo del cliente |     |
| da_catalogo | Varchar | 30  | NULL | Catalogos de la Base de datos |     |
| da_bdatos | Varchar | 30  | NULL | Bases de datos |     |
| da_sprocedure | Varchar | 50  | NULL | Procedimientos almacenados de la base de datos |     |

### cl_dadicion_ente

Tabla que contiene parametrización del cliente con los diferentes valores de los datos adicionales.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| de_ente | int | 4   | NOT NULL | Código del cliente | &nbsp; |
| de_dato | smallint | 2   | NOT NULL | Código del dato adicional | &nbsp; |
| de_descripcion | descripcion | 64  | NOT NULL | Descripción del dato adicional |     |
| de_tipo_dato | char | 1   | NOT NULL | Tipo de dato | A: Catalogo<br><br>C: Carácter<br><br>D: Datetime<br><br>F: Float<br><br>I: Int<br><br>M: Money<br><br>P: Pseudocatalogo<br><br>S: Smallint<br><br>T: Tinyint<br><br>X: Texto |
| de_valor | descripcion | 64  | NULL | El valor del dato para el cliente |     |

### cl_comercial

Tabla que contiene todas las referencias de tipo comercial

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ente | int | 4   | NOT NULL | Código del cliente | &nbsp; |
| referencia | tinyint | 1   | NOT NULL | Número de la referencia | &nbsp; |
| tipo | char | 1   | NOT NULL | Tipo de la referencia | C: Comercial<br><br>(cl_rtipos) |
| tipo_cifras | char | 2   | NOT NULL | Tipo de cifras | 1: Altas<br><br>2: Medias<br><br>3: Bajas<br><br>(cl_tcifras) |
| numero_cifras | tinyint | 1   | NOT NULL | Número de cifras |     |
| fecha_registro | datetime | 8   | NOT NULL | Fecha en la cual se registra la referencia |     |
| calificacion | char | 2   | NULL | Calificación de la referencia | A: Normal<br><br>B: Aceptable<br><br>C: Apreciable<br><br>D: Significativo<br><br>E: Incobrable<br><br>(cl_posicion) |
| verificacion | char | 1   | NOT NULL | Estado de verificación de la referencia. No aplica | S: Verificado<br><br>N:Falta verificar |
| fecha_ver | datetime | 8   | NULL | Fecha en la que se verifica la referencia. No aplica |     |
| fecha_modificacion | datetime | 8   | NOT NULL | Fecha en la que se actualiza la referencia |     |
| vigencia | char | 1   | NOT NULL | Estado de vigencia de la referencia | S: Vigente |
| observacion | varchar | 254 | NULL | Observación de la referencia |     |
| institucion | descripcion | 64  | NULL | Nombre de la institución asociada |     |
| fecha_ingr_en | datetime | 8   | NULL | Fecha ingreso en el comercio |     |
| funcionario | login | 14  | NULL | Funcionario asociado |     |

### cl_financiera

Tabla que contiene todas las referencias de tipo financiera

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| cliente | int | 4   | NOT NULL | Código del cliente | &nbsp; |
| referencia | tinyint | 1   | NOT NULL | Número de la referencia | &nbsp; |
| treferencia | char | 1   | NOT NULL | Tipo de la referencia | F: Financiera<br><br>(cl_rtipos) |
| institucion | int | 4   | NULL | Código de la institución asociada | \*\*\* |
| toperacion | char | 1   | NULL | Tipo de operación | A: Activa<br><br>P: Pasiva |
| tclase | descripcion | 64  | NULL | Número de la clase |     |
| tipo_cifras | char | 2   | NOT NULL | Tipo de cifras | 1: Altas<br><br>2: Medias<br><br>3: Bajas<br><br>(cl_tcifras) |
| numero_cifras | tinyint | 1   | NOT NULL | Número de cifras |     |
| fecha_inicio | datetime | 8   | NULL | Fecha en la cual se registra la referencia |     |
| fecha_vencimiento | datetime | 8   | NULL | Fecha en la que se vence la referencia |     |
| calificacion | char | 2   | NULL | Calificación de la referencia | A: Normal<br><br>B: Aceptable<br><br>C: Apreciable<br><br>D: Significativo<br><br>E: Incobrable<br><br>(cl_posicion) |
| vigencia | char | 1   | NOT NULL | Estado de vigencia de la referencia |     |
| verificacion | char | 1   | NOT NULL | Estado de verificación de la referencia. No aplica | S: Verificado<br><br>N:Falta verificar |
| fecha_ver | datetime | 8   | NULL | Fecha en la que se verifica la referencia. No aplica |     |
| fecha_modificacion | datetime | 8   | NOT NULL | Fecha en la que se actualiza la referencia |     |
| observacion | varchar | 254 | NULL | Observación de la referencia |     |
| estatus | char | 1   | NULL | Estado de la referencia | A:Activo C: Cancelado |
| fecha_registro | datetime | 8   | NOT NULL | Fecha en la que se registra la referencia |     |
| funcionario | login | 14  | NULL | Funcionario asociado |     |

### cl_economica

Tabla que contiene todas las referencias de tipo bancaria

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ente | int | 4   | NOT NULL | Código del cliente | &nbsp; |
| referencia | tinyint | 1   | NOT NULL | Número de la referencia | &nbsp; |
| tipo | char | 1   | NOT NULL | Tipo de la referencia | B: Bancaria<br><br>(cl_rtipos) |
| tipo_cifras | char | 2   | NULL | Tipo de cifras | 1: Altas<br><br>2: Medias<br><br>3: Bajas<br><br>(cl_tcifras) |
| numero_cifras | tinyint | 1   | NULL | Número de cifras |     |
| fecha_registro | datetime | 8   | NOT NULL | Fecha en la cual se registra la referencia |     |
| calificacion | char | 2   | NULL | Calificación de la referencia | A: Normal<br><br>B: Aceptable<br><br>C: Apreciable<br><br>D: Significativo<br><br>E: Incobrable<br><br>(cl_posicion) |
| verificacion | char | 1   | NOT NULL | Estado de verificación de la referencia. No aplica | S: Verificado<br><br>N:Falta verificar |
| fecha_ver | datetime | 8   | NULL | Fecha en la que se verifica la referencia. No aplica |     |
| fecha_modificacion | datetime | 8   | NOT NULL | Fecha en la que se actualiza la referencia |     |
| vigencia | char | 1   | NOT NULL | Estado de vigencia de la referencia | S: Vigente N: No vigente |
| observacion | varchar | 254 | NULL | Observación de la referencia |     |
| banco | int | 4   | NULL | CódigoNombre del banco asociado | (ba_banco)\*\* |
| cuenta | varchar | 30  | NULL | Número de la Cuenta |     |
| funcionario | login | 14  | NULL | Funcionario asociado |     |
| fec_apertura | datetime | 8   | NULL | Fecha de apertura |     |
| tipo_cta | catalogo | 10  | NULL | Tipo de cuenta | (ba_tcuenta) |
| estado | char | 1   | NULL | Estado de la referencia |     |

### cl_tarjeta

Tabla que contiene todas las referencias de tipo tarjeta de crédito.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ente | int | 4   | NOT NULL | Código del cliente | &nbsp; |
| referencia | tinyint | 1   | NOT NULL | Número de la referencia | &nbsp; |
| tipo | char | 1   | NOT NULL | Tipo de la referencia | T: Tarjeta<br><br>(cl_rtipos) |
| tipo_cifras | char | 2   | NOT NULL | Tipo de cifras | 1: Altas<br><br>2: Medias<br><br>3: Bajas<br><br>(cl_tcifras) |
| numero_cifras | tinyint | 1   | NOT NULL | Número de cifras |     |
| fecha_registro | datetime | 8   | NOT NULL | Fecha en la cual se registra la referencia |     |
| calificacion | char | 2   | NULL | Calificación de la referencia | A: Normal<br><br>B: Aceptable<br><br>C: Apreciable<br><br>D: Significativo<br><br>E: Incobrable<br><br>(cl_posicion) |
| fecha_ver | datetime | 8   | NULL | Fecha en la que se verifica la referencia. No aplica |     |
| fecha_modificacion | datetime | 8   | NULL | Fecha en la que se actualiza la referencia. No aplica |     |
| verificacion | char | 1   | NOT NULL | Estado deverificación. No aplica | S: Verificado<br><br>N: Falta verificar |
| vigencia | char | 1   | NOT NULL | Estado de vigencia de la referencia | S: Vigente N: No vigente |
| observacion | varchar | 254 | NULL | Observación de la referencia |     |
| banco | varchar | 4   | NULL | Nombre del banco asociado | cl_tarjeta |
| cuenta | varchar | 30  | NULL | Número de tarjeta |     |
| funcionario | login | 14  | NULL | Funcionario asociado |     |
| fecha_apertura | datetime | 8   | NULL | Fecha de apertura de la tarjeta |     |

### cl_negocio_cliente

Tabla que contiene los negocios que posee el cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| nc_codigo | int | 4   | NOT NULL | Código del negocio, secuencial |     |
| nc_ente | int | 4   | NOT NULL | Código del cliente al que está asociado el negocio |     |
| nc_nombre | varchar | 60  | NULL | Nombre del negocio |     |
| nc_giro | varchar | 10  | NULL | No aplica |     |
| nc_fecha_apertura | datetime | 8   | NULL | Fecha en la que se registra el nuevo negocio |     |
| nc_calle | varchar | 80  | NULL | Calle en la que se encuentra el negocio |     |
| nc_nro | varchar | 40  | NULL | Número de la calle |     |
| nc_colonia | varchar | 10  | NULL | Código de la colonia en la que se encuentra el negocio | (cl_parroquia)\*\* |
| nc_localidad | varchar | 20  | NULL | Código de la localidad en la que se encuentra el negocio | (cl_barrio) |
| nc_municipio | varchar | 10  | NULL | Código del municipio en el que se encuentra el negocio | (cl_ciudad)\*\* |
| nc_estado | varchar | 10  | NULL | Código del estado en el que se encuentra el negocio |     |
| nc_codpostal | varchar | 5   | NULL | Código postal de la dirección del negocio |     |
| nc_pais | varchar | 10  | NULL | Código del país en el que se encuentra el negocio | (cl_pais) |
| nc_telefono | varchar | 20  | NULL | Télefono del negocio |     |
| nc_actividad_ec | varchar | 10  | NULL | Código de la actividad relacionada al negocio | (cl_actividad_economica)\*\* |
| nc_tiempo_actividad | int | 4   | NULL | Tiempo que se ha realizado la actividad en años |     |
| nc_tiempo_dom_neg | int | 4   | NULL | Tiempo de arraigo del negocio en años |     |
| nc_emprendedor | char | 1   | NULL | Estado que indica si es emprendedor o no | S: Si<br><br>N: No |
| nc_recurso | varchar | 10  | NULL | No aplica |     |
| nc_ingreso_mensual | money | 8   | NULL | Ingreso Mensual del negocio |     |
| nc_tipo_local | varchar | 10  | NULL | Tipo de local |     |
| nc_estado_reg | varchar | 10  | NULL | Estado de vigencia del negocio | V: Vigente<br><br>E: Eliminado |
| nc_destino_credito | varchar | 10  | NULL | Destino del crédito. No aplica |     |
| nc_sector | catalogo | 10  | NULL | Código del sector en el que se encuentra el negocio | (cl_sector_economico)\*\* |
| nc_subsector | catalogo | 10  | NULL | Código del subsector en el que se encuentra el negocio | (cl_subsector_ec)\*\* |
| nc_misma_dir | char | 1   | NULL | Indicador de si el negocio esta ubicado en la misma dirección de domicilio que el cliente | S: Si<br><br>N: No |
| nc_nro_interno | varchar | 40  | NULL | Número interno de la dirección |     |
| nc_referencia_neg | varchar | 225 | NULL | Referencia de ubicación del negocio |     |
| nc_rfc_neg | varchar | 15  | NULL | RFC del negocio. No aplica |     |
| nc_dias_neg | varchar | 20  | NULL | Días en los que atiende el negocio |     |
| nc_hora_ini | varchar | 10  | NULL | Hora de apertura del negocio |     |
| nc_hora_fin | varchar | 10  | NULL | Hora de cierre del negocio |     |
| nc_atiende | varchar | 40  | NULL | Encargado de atender el negocio | 1: DUEÑO<br><br>2: EMPLEADO<br><br>3: FAMILIAR |
| nc_empleados | smallint | 2   | NULL | Número de empleados con los que cuenta el negocio |     |
| nc_actividad_neg | varchar | 70  | NULL | Actividad que realiza el negocio | cl_subactividad_ec |
| nc_tipo_id | char | 4   | NULL | Tipo de identificación tributaria asociada al negocio |     |
| nc_num_id | varchar | 30  | NULL | Número de identificación tributaria asociada al negocio |     |
| nc_sector_region | varchar | 10  | NULL | Sector en el que se encuentra el negocio | (cl_sector) |
| nc_zona | varchar | 10  | NULL | Zona en la que se encuentra el negocio | (cl_zona) |

### cl_validacion_listas_externas

Tabla que contiene la informacion si la persona esta en lista negras, lista persona publica o persona politica.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| rle_ente | int | 4   | NOT NULL | Código del cliente | &nbsp; |
| rle_rol | varchar | 10  | NOT NULL | Numero del rol | &nbsp; |
| rle_producto | int | 4   | NOT NULL | Numero del producto |     |
| rle_cuenta | varchar | 40  | NOT NULL | Numero de la cuenta |     |
| rle_fecha_validacion | datetime | 8   | NOT NULL | Fecha de validacion |     |
| rle_proceso | int | 4   | NULL | Numero de proceso |     |
| rle_lista_negra | char | 1   | NULL | Valida si esta en listas negras | S:SI  <br>N:NO |
| rle_lista_pep | char | 1   | NULL | Validad si es en personas publicamente expuestas | S:SI  <br>N:NO |
| rle_lista_pr | char | 1   | NULL | Valida si es persona expuesta politicamente | S:SI  <br>N:NO |
| rle_observaciones | varchar | 1000 | NULL | Observaciones |     |
| rle_acciones | varchar | 1000 | NULL | Acciones a tomar |     |
| rle_usuario | login | 14  | NULL | Usuario que registro al ente |     |
| rle_fecha_observacion | datetime | 8   | NULL | Ultima fecha de observacion |     |

### cl_tipo_identificacion

Tabla donde se guardan los diversos tipos de identificacion con sus máscaras respectivas.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ti_tipo_cliente | char | 10  | NOT NULL | Tipo de cliente | P: Persona<br><br>C: Compañía |
| ti_tipo_documento | char | 10  | NOT NULL | Tipo de documento | P:Persona<br><br>T:Tributario<br><br>O:Otro |
| ti_nacionalidad | char | 10  | NOT NULL | Nacionalidad | N:Nacional<br><br>E:Extranjero |
| ti_tipo_residencia | char | 10  | NULL | Tipo de residencia | R:Residente<br><br>NULL: No Res. |
| ti_codigo | char | 20  | NOT NULL | Codigo o abreviacion |     |
| ti_descripcion | varchar | 64  | NULL | Descripcion del codigo |     |
| ti_mascara | varchar | 30  | NOT NULL | Mascara del documento |     |

### cl_ptos_matriz_riesgo (No se usa en esta versión)

Tabla donde se guardan los puntos de riesgo de cada clientes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pmr_ente | int | 4   | NOT NULL | Código del cliente | &nbsp; |
| pmr_gpo_matriz_riesgo | varchar | 10  | NOT NULL | Nombre de riesgo | &nbsp; |
| pmr_regla_acronimo | varchar | 10  | NOT NULL | Acronimo |     |
| pmr_puntaje | float | 8   | NULL | Numero de puntaje de riesgo |     |
| pmr_ponderacion | float | 8   | NULL | Numero de ponderacion de riesgo |     |
| pmr_signo | char | 1   | NOT NULL | No aplica |     |
| pmr_detalle | varchar | 100 | NULL | No aplica |     |
| pmr_estado | char | 1   | NOT NULL | Estado del riesgo |     |
| pmr_fecha_registro | datetime | 8   | NOT NULL | Fecha de registro |     |

### cl_info_trn_riesgo

Tabla donde se guardan la informacion de riesgo de cada cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| itr_ente | int | 4   | NOT NULL | Código del cliente | &nbsp; |
| itr_cat_grupo | varchar | 10  | NULL | Nombre del grupo | &nbsp; |
| itr_cat_nivel | varchar | 10  | NULL | Nombre del nivel |     |
| itr_cat_num_trn_mes_ini | varchar | 10  | NULL | Codigo de transaccion inicial |     |
| itr_cat_mto_trn_mes_ini | varchar | 10  | NULL | Codigo de transaccion |     |
| itr_cat_sdo_prom_mes_ini | varchar | 10  | NULL | Codigo de transaccion |     |
| itr_ptos_num_trn_mes_ini | int | 4   | NULL | No aplica |     |
| itr_ptos_mto_trn_mes_ini | int | 4   | NULL | No aplica |     |
| itr_ptos_sdo_prom_mes_ini | int | 4   | NULL | No aplica |     |
| itr_fecha_registro | datetime | 8   | NOT NULL | Fecha de registro |     |
| itr_ultima_fecha_mod | datetime | 8   | NOT NULL | Fecha ultima modificacion |     |

### ts_negocio_cliente

Tabla de auditoría donde se guardan los cambios la informacion de negocio del cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ts_secuencial | int | 4   | NOT NULL | Numero de negocio unico | &nbsp; |
| ts_codigo | int | 4   | NOT NULL | Numero de negocio del cliente | &nbsp; |
| ts_ente | int | 4   | NOT NULL | Numero de cliente |     |
| ts_nombre | varchar | 60  | NULL | Nombre del negocio |     |
| ts_giro | varchar | 10  | NULL | Tipo de giro |     |
| ts_fecha_apertura | datetime | 8   | NULL | Fecha de creacion |     |
| ts_calle | varchar | 80  | NULL | Nombre de la calle |     |
| ts_nro | varchar | 40  | NULL | No aplica |     |
| ts_colonia | varchar | 10  | NULL | Nombre colonia |     |
| ts_localidad | varchar | 20  | NULL | nombre localidad |     |
| ts_municipio | varchar | 10  | NULL | Nombre municipio |     |
| ts_estado | varchar | 10  | NULL | Nombre estado |     |
| ts_codpostal | varchar | 5   | NULL | Numero codigo postal |     |
| ts_pais | varchar | 10  | NULL | Numero de pais |     |
| ts_telefono | varchar | 20  | NULL | Numero de cl_telefono |     |
| ts_actividad_ec | varchar | 10  | NULL | Actividad economica |     |
| ts_tiempo_actividad | int | 4   | NULL | Tiempo de actividad |     |
| ts_tiempo_dom_neg | int | 4   | NULL | Tiempo de atencion |     |
| ts_emprendedor | char | 1   | NULL | Empresa enprendedora |     |
| ts_recurso | varchar | 10  | NULL | No aplica |     |
| ts_ingreso_mensual | money | 8   | NULL | No aplica |     |
| ts_tipo_local | varchar | 10  | NULL | Numero tipo de local |     |
| ts_usuario | login | 14  | NULL | Usuario que registro el negocio |     |
| ts_oficina | int | 4   | NULL | Oficina donde se ingreso el negocio |     |
| ts_fecha_proceso | datetime | 8   | NULL | Fecha de creacion |     |
| ts_operacion | varchar | 1   | NULL | Tipo de operación |     |
| ts_estado_reg | varchar | 10  | NULL | Estado |     |
| ts_destino_credito | varchar | 10  | NULL | No aplica |     |
| ts_sector | catalogo | 10  | NULL | Tipo de sector |     |
| ts_subsector | catalogo | 10  | NULL | Tipo de subsector |     |
| ts_misma_dir | char | 1   | NULL | No aplica |     |
| ts_nro_interno | varchar | 40  | NULL | Numero interno |     |
| ts_referencia_neg | varchar | 225 | NULL | Nombre de pais |     |
| ts_rfc_neg | varchar | 15  | NULL | No aplica |     |
| ts_dias_neg | catalogo | 10  | NULL | Dias de atencion del negocio |     |
| ts_hora_ini | varchar | 10  | NULL | Hora de inicio de atencion |     |
| ts_hora_fin | varchar | 10  | NULL | Hora fin de atencion |     |
| ts_atiende | varchar | 40  | NULL | Persona quien atiende |     |
| ts_empleados | smallint | 2   | NULL | Numero de empleados |     |
| ts_actividad_neg | varchar | 70  | NULL | Actividad del negocio |     |
| ts_nc_tipo_id | char | 4   | NULL | Tipo de identificacion |     |
| ts_nc_num_id | varchar | 30  | NULL | Numero de identificacion |     |

### cl_val_iden (No se usa en esta versión)

Tabla donde se guarda las validaciones ed una transaccion.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| vi_producto | tinyint | 1   | NOT NULL | Numero del producto | &nbsp; |
| vi_transaccion | smallint | 2   | NOT NULL | Numero de transaccion | &nbsp; |
| vi_ind_causal | char | 1   | NOT NULL | Tipo de causa |     |
| vi_causal | varchar | 10  | NULL | Nombre de causa |     |
| vi_estado | chat | 1   | NOT NULL | Estado |     |
| vi_fecha_registro | datetime | 8   | NOT NULL | Fecha de registro |     |
| vi_fecha_modif | datetime | 8   | NULL | Fecha de modificacion |     |

### cl_scripts

Tabla donde se guardan script personalizados para ser usados en funcionalidades.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sc_operacion | catalogo | 10  | NOT NULL | Tipo de operacion | &nbsp; |
| sc_tipo | catalogo | 10  | NOT NULL | Tipo de transaccion | &nbsp; |
| sc_script | varchar | 1000 | NOT NULL | Script a ejecutar |     |

### cl_registro_identificacion

Tabla de auditoría que indica quien y cuando registró una identificación para el cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ri_ente | int | 4   | NOT NULL | Numero del cliente | &nbsp; |
| ri_tipo_iden | char | 4   | NOT NULL | Tipo de identidad | &nbsp; |
| ri_identificacion | numero | 30  | NOT NULL | Numero de identidad |     |
| ri_fecha_act | datetime | 8   | NOT NULL | Fecha de actualizacion |     |
| ri_hora_act | datetime | 8   | NOT NULL | Hora de actualizacion |     |
| ri_usuario | varchar | 30  | NOT NULL | Usuario que agrego |     |
| ri_nom_usuario | varchar | 80  | NULL | Nombre del usuario que agrego |     |

### cl_registro_cambio

Tabla donde se guardan los cambios al Insertar, Actualizar o Eliminar registros en las tablas principales de clientes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| Tipo | Char | 1   | NOT NULL | Tipo de accion realizada | &nbsp; |
| Tabla | Varchar | 100 | NOT NULL | Tabla donde se realizo el cambio | &nbsp; |
| Ente | Int | 4   | NOT NULL | Codigo del ente |     |
| sec1 | Int | 4   | NOT NULL | No aplica |     |
| sec2 | Int | 4   | NOT NULL | No aplica |     |
| Campo | Varchar | 100 | NOT NULL | Campo que se modifico |     |
| Valor | Varchar | 1000 | NULL | Valor por el que se modifico |     |

### cl_alertas_riesgo (No se usa en esta versión)

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ar_id_alerta | int | 4   | NOT NULL | No aplica | &nbsp; |
| ar_sucursal | int | 4   | NOT NULL | No aplica | &nbsp; |
| ar_grupo | int | 4   | NULL | No aplica |     |
| ar_ente | int | 4   | NOT NULL | No aplica |     |
| ar_nombre_grupo | Varchar | 64  | NULL | No aplica |     |
| ar_nombre | Varchar | 254 | NULL | No aplica |     |
| ar_rfc | Varchar | 30  | NULL | No aplica |     |
| ar_contrato | Varchar | 24  | NULL | No aplica |     |
| ar_tipo_producto | Varchar | 255 | NULL | No aplica |     |
| at_tipo_lista | Varchar | 2   | NULL | No aplica |     |
| ar_fecha_consulta | Datetime | 8   | NULL | No aplica |     |
| ar_fecha_alerta | Datetime | 8   | NULL | No aplica |     |
| ar_fecha_operacion | Datetime | 8   | NULL | No aplica |     |
| ar_fecha_dictamina | Datetime | 8   | NULL | No aplica |     |
| ar_fecha_reporte | Datetime | 8   | NULL | No aplica |     |
| ar_observaciones | Varchar | 500 | NULL | No aplica |     |
| ar_nivel_riesgo | Varchar | 255 | NULL | No aplica |     |
| ar_etiqueta | Varchar | 255 | NOT NULL | No aplica |     |
| ar_escenario | Varchar | 300 | NULL | No aplica |     |
| ar_tipo_alerta | Varchar | 100 | NULL | No aplica |     |
| ar_tipo_operacion | Varchar | 255 | NULL | No aplica |     |
| ar_monto | Money | 8   | NULL | No aplica |     |
| ar_status | Varchar | 100 | NULL | No aplica |     |
| ar_genera_reporte | Varchar | 2   | NULL | No aplica |     |
| ar_codigo | Int | 4   | NULL | No aplica |     |

### cl_analisis_negocio

Tabla donde se guarda la información de los datos financieros de cada negocio.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| an_cliente_id | int | 4   | NOT NULL | Código del ente | &nbsp; |
| an_negocio_codigo | int | 4   | NOT NULL | Código del negocio | &nbsp; |
| an_ventas_prom_mes | money | 8   | NOT NULL | Número de ventas por mes |     |
| an_compras_prom_mes | money | 8   | NOT NULL | Número promedio de compras por mes |     |
| an_renta_neg | money | 8   | NOT NULL | Valor de renta de negocio |     |
| an_transporte_neg | money | 8   | NOT NULL | Valor de transporte |     |
| an_personal_neg | money | 8   | NOT NULL | Valor que paga por Personal de negocio |     |
| an_impuestos_neg | money | 8   | NOT NULL | Valor de impuestos del negocio |     |
| an_electrica_neg | money | 8   | NOT NULL | Valor de servicio eléctricos |     |
| an_agua_neg | money | 8   | NOT NULL | Valor de servicio agua |     |
| an_telefono_neg | money | 8   | NOT NULL | Valor de servicio telefonico |     |
| an_otros_neg | money | 8   | NOT NULL | Valor otros negocios |     |
| an_inventario | int | 4   | NOT NULL | Valor del inventario |     |
| an_inversion_neg | money | 8   | NOT NULL | Inversión del negocio |     |
| an_frecuencia_inv | varchar | 10  | NOT NULL | Código de la frecuencia de inversión | DIA: Diaria<br><br>SEM:Semanal<br><br>MEN : Mensual |
| an_presta | char | 1   | NOT NULL | Presta dinero | S:SI<br><br>N:NO |
| an_frecuencia_cobro | varchar | 10  | NULL | Frecuencia del cobro del prestamo | DIA: Diaria<br><br>SEM:Semanal<br><br>MEN : Mensual |
| an_debe_prestamo | char | 1   | NOT NULL | Debe algun prestamo | S:SI<br><br>N:NO |
| an_cuota_pago | money | 8   | NOT NULL | Valor de la cuota |     |
| an_frecuencia_pago | Varchar | 10  | NULL | Frecuencia del pago de la cuota | DIA: Diaria<br><br>SEM:Semanal<br><br>MEN : Mensual |
| an_disponible | money | 8   | NOT NULL | Disponibilidad valor |     |
| an_ganancia_neg | money | 8   | NOT NULL | Gananacia del negoio |     |
| an_frecuencia_util | Varchar | 10  | NOT NULL | Frecuencia de ganancia | DIA: Diaria<br><br>SEM:Semanal<br><br>MEN : Mensual |
| an_capacidad_pago_mes | money | 8   | NOT NULL | Capacidad maxima mensualidad |     |
| an_producto | Varchar | 60  | NOT NULL | Nombre del producto |     |
| an_porcentaje_venta_regs | float |     | NOT NULL | Perocentaje de venta |     |
| an_valor_vivienda | money | 8   | NOT NULL | Valor de la vivienda |     |
| an_valor_negocio | money | 8   | NOT NULL | Valor del negocio |     |
| an_valor_vehiculo | money | 8   | NOT NULL | Valor del vehiculo |     |
| an_valor_mobiliario | money | 8   | NOT NULL | Valor del mobiliario |     |
| an_valor_otros | money | 8   | NOT NULL | Otros valores |     |
| an_ingresos_extra | Char | 1   | NOT NULL | Tiene ingresos extra | DIA: Diaria<br><br>SEM:Semanal<br><br>MEN : Mensual |
| an_monto_extra | money | 8   | NOT NULL | Valor extra |     |
| an_origen_extra | Varchar | 20  | NULL | Nombre del origne de los extra |     |
| an_gastos_alimentos | money | 8   | NOT NULL | Gastos en alimentos |     |
| an_gastos_renta_viv | money | 8   | NOT NULL | Gastos en al renta |     |
| an_gastos_energia_elect | money | 8   | NOT NULL | Gastos de energia |     |
| an_gastos_agua | money | 8   | NOT NULL | Gastos del agua |     |
| an_gastos_telefono | money | 8   | NOT NULL | Gastos del teelfono |     |
| an_gastos_tv | money | 8   | NOT NULL | Gastos de television |     |
| an_gastos_salud | money | 8   | NOT NULL | Gastos en salsud |     |
| an_gastos_transp | money | 8   | NOT NULL | Gastos en transporte |     |
| an_gastos_educ | money | 8   | NOT NULL | Gastos en educacion |     |
| an_gastos_gas | money | 8   | NOT NULL | Gastos en gas |     |
| an_gastos_vestido | money | 8   | NOT NULL | Gastos de ropa |     |
| an_gastos_otros | money | 8   | NOT NULL | Otros gastos |     |
| an_ctas_por_cobrar | money | 8   | NULL | Cuotas por cobrar |     |
| an_ctas_por_pagar_largo_plazo | money | 8   | NULL | Cuotas por pagar |     |
| an_cuota_pago_buro | money | 8   | NOT NULL | Cuota de pago en buró |     |
| an_deuda_corto_buro | money | 8   | NOT NULL | Deuda a corto plazo registrada en buró |     |
| an_deuda_largo_buro | money | 8   | NOT NULL | Deuda a largo plazo registrada en buró |     |
| an_cuota_pago_enlace | money | 8   | NOT NULL | Cuota de pago enlace |     |
| an_deuda_corto_enlace | money | 8   | NOT NULL | Deuda a corto plazo registrada en enlace |     |
| an_deuda_largo_enlace | money | 8   | NOT NULL | Deuda a largo plazo registrada en enlace |     |
| an_valor_vehiculo2 | money | 8   | NOT NULL | Vehículo Negocio |     |
| an_valor_vivienda2 | money | 8   | NOT NULL | Bienes Inmuebles Negocio |     |
| an_ajuste_deuda | money | 8   | NOT NULL | Ajuste por Deudas a Corto Plazo |     |

### cl_beneficiario_seguro

Tabla donde se guarda la información de la persona beneficiaria del seguro del cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| bs_nro_operacion | int | 4   | not null | Numero de operación |     |
| bs_producto | smallint | 2   | not null | Código del producto |     |
| bs_tipo_id | Varchar | 10  | null | Tipo identificación |     |
| bs_ced_ruc | Varchar | 32  | null | Número de identificación |     |
| bs_nombres | Varchar | 100 | not null | Nombre de cliente |     |
| bs_apellido_paterno | Varchar | 100 | null | Primer apellido del cliente |     |
| bs_apellido_materno | Varchar | 100 | null | Segundo apellido del cliente |     |
| bs_porcentaje | float |     | not null | Porcentaje de beneficio |     |
| bs_parentesco | Varchar | 10  | null | Código de el parentesco |     |
| bs_secuencia | int | 4   | not null | Secuencia |     |
| bs_ente | int | 4   | null | No aplica |     |
| bs_fecha_mod | datetime | 8   | not null | Fecha de modificación |     |
| bs_fecha_nac | datetime | 8   | null | Fecha de nacimiento |     |
| bs_telefono | Varchar | 20  | null | Telefono |     |
| bs_direccion | Varchar | 70  | null | Dirección |     |
| bs_provincia | smallint | 2   | null | Provincia de nacimiento |     |
| bs_ciudad | smallint | 2   | null | Código de la Ciudad |     |
| bs_parroquia | int | 4   | null | Código de la parroquia |     |
| bs_codpostal | char | 5   | null | Codigo postal |     |
| bs_localidad | Varchar | 20  | null | No aplica |     |
| bs_ambos_seguros | varchar | 1   | null | No aplica |     |
| bs_tramite | int | 4   | null | No aplica |     |
| bs_seguro | catalogo | 10  | null | No aplica |     |

### cl_control_empresas_rfe

Tabla donde se guardan las empresas de clientes con residencia fiscal.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ce_ente | int | 4   | null | Codigo del ente |     |
| ce_compania | int | 4   | null | Codigo de la compañía |     |
| ce_tipo_control | Varchar | 100 | null | Codigo de tipo de control |     |
| ce_fecha_registro | datetime | 8   | null | Fecha de registro |     |
| ce_fecha_modificacion | datetime | 8   | null | Fecha de modificacion |     |
| ce_vigencia | char | 1   | null | Vigencia | S:SI<br><br>N:NO |
| ce_verificacion | char | 1   | null | Verificacion. No aplica | S:SI<br><br>N:NO |
| ce_funcionario | Varchar | 254 | null | Funcionario |     |

### cl_direccion_fiscal (No se usa en esta versión)

Tabla donde se guardan la informacion de residencia fiscal de los clientes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| df_ente | int | 4   | not null | Codigo del ente |     |
| df_sec | tinyint | 2   | null | Secuancial |     |
| df_tipo | varchar | 30  | null | Tipo de residencia |     |
| df_pais | int | 4   | not null | Codigo de pais |     |
| df_codigo_postal | int | 4   | null | Codigo postal |     |
| df_provincia | varchar | 254 | null | Nombre de la provincia |     |
| df_ciudad | varchar | 254 | null | Nombre de la ciudad |     |
| df_calle_principal | varchar | 254 | null | Nombre de la calle principal |     |
| df_conjunto_edificio | varchar | 254 | null | Nombre del conjunto edificio |     |
| df_num_piso | varchar | 254 | null | Numero de piso |     |
| df_oficina_departamento | varchar | 254 | null | Numero de oficina o apartamento |     |
| df_barrio | varchar | 254 | null | Nombre del barrio |     |
| df_direccion_completa | varchar | 254 | null | Direccion completa |     |
| df_fecha_registro | datetime | 8   | null | Fecha de registro |     |
| df_fecha_modificacion | datetime | 8   | null | Fecha de modificacion |     |
| df_vigencia | char | 1   | null | Vigencia | S:SI<br><br>N:NO |
| df_verificacion | char | 1   | null | Verificado | S:SI<br><br>N:NO |
| df_funcionario | varchar | 254 | null | Usuario que ingreso la informacion |     |

### cl_documento_actividad (No se usa en esta versión)

Tabla donde se guardan los archivos cargados a un negocio.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| da_tipo | char | 1   | NOT NULL | Tipo de actividad | &nbsp; |
| da_producto | catalogo | 10  | NOT NULL | Nombre del producto | &nbsp; |
| da_codigo | caralogo | 10  | NOT NULL | Codigo del producto |     |
| da_actividad | int | 4   | NOT NULL | Codigo de actividad |     |
| da_visible | char | 1   | NOT NULL | Es visible | S: SI<br><br>N: NO |
| da_requerido | char | 1   | NOT NULL | Es requerido | S: SI<br><br>N: NO |
| da_descarga | char | 1   | NOT NULL | Habilitar descarga | S: SI<br><br>N: NO |
| da_subida | char | 1   | NOT NULL | Habilitar subida | S: SI<br><br>N: NO |

### cl_documento_digitalizado

Tabla donde se guardan los archivos cargados de un ente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dd_tipo | char | 1   | NOT NULL | Tipo de documento | &nbsp; |
| dd_inst_proceso | int | 4   | NOT NULL | No aplica | &nbsp; |
| dd_cliente | int | 4   | NOT NULL | Codigo de cliente |     |
| dd_grupo | int | 4   | NOT NULL | No aplica |     |
| dd_codigo | catalogo | 10  | NOT NULL | Codigo del documento |     |
| dd_producto | catalogo | 10  | NOT NULL | Nombre del producto |     |
| dd_fecha | datetime | 8   | NOT NULL | Fecha de ingreso |     |
| dd_cargado | char | 1   | NOT NULL | Cargado | S:SI<br><br>N:NO |
| dd_extension | char | 8   | NULL | Formato del archivo |     |

### cl_documento_parametro

Documentos que se pueden cargar a los distintos tipos de clientes

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dp_tipo | char | 1   | NOT NULL | Tipo de cliente, P: Prospecto | &nbsp; |
| dp_producto | catalogo | 10  | NOT NULL | Tipo de producto, si aplica a un cliente natural, jurídico o grupo. | &nbsp; |
| dp_codigo | catalogo | 10  | NOT NULL | Código del documento a subir |     |
| dp_detalle | descripcion | 160 | NOT NULL | Descripción del documento |     |
| dp_requerido | char | 1   | NULL | Si el documento es requerido o no |     |
| dp_tamanio | tinyint | 1   | NULL | Máximo tamaño del archivo a subir |     |
| dp_estado | char | 1   | NULL | Si el documento está vigente. |     |

### cl_manejo_sarlaft (No se usa en esta versión)

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ms_secuancial | int | 4   | NOT NULL | No aplica | &nbsp; |
| ms_restrictiva | varchar | 12  | NOT NULL | No aplica | &nbsp; |
| ms_origen | varchar | 12  | NULL | No aplica |     |
| ms_estado | varchar | 12  | NULL | No aplica |     |

### cl_notificacion_general

Tabla donde se guarda las notificaciones realizadas a los entes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ng_codigo | int | 4   | NOT NULL | Secuencial | &nbsp; |
| ng_mensaje | varchar | 1000 | NOT NULL | Mensaje de la notificacion | &nbsp; |
| ng_correo | varchar | 60  | NOT NULL | Correo al que se envio |     |
| ng_asunto | varchar | 255 | NOT NULL | Asunto que se envio |     |
| ng_origen | char | 1   | NULL | Origen de la notificacion |     |
| ng_tramite | int | 4   | NULL | Numero de tramite |     |

### cl_ns_generales_estado (No se usa en esta versión)

Tabla donde se guardan los estados de las notificaciones.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| nge_codigo | int | 4   | NOT NULL | Codigo de notificacion | &nbsp; |
| nge_estado | char | 1   | NOT NULL | Estado de la notificacion | &nbsp; |

### cl_pais_id_fiscal

Tabla donde se guarda los paises de residencia fiscal de los entes.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pf_ente | int | 4   | NULL | Codigo del ente | &nbsp; |
| pf_pais | int | 4   | NULL | Codigo del pais | &nbsp;(cl_pais) |
| pf_tipo | varchar | 30  | NULL | Tipo de identififcacion |     |
| pf_identificacion | varchar | 30  | NULL | Numero de identificacion |     |
| pf_fecha_registro | datetime | 8   | NOT NULL | Fecha de registro |     |
| pf_fecha_modificacion | datetime | 8   | NULL | Fecha de modificacion |     |
| pf_vigencia | char | 1   | NULL | Se encuentra vigente | S:SI  <br>NULL:NO |
| pf_verificacion | char | 1   | NULL | Esta verificado. No aplica | S: SI<br><br>N: NO |
| pf_funcionario | varchar | 254 | NULL | Funcionario que agrego la informacion |     |

### cl_productos_negocio

Tabla donde se guardan los productos relacionados al negocio de un cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pn_id | int | 4   | NOT NULL | Secuencial | &nbsp; |
| pn_cliente | int | 4   | NULL | Codigo del ente | &nbsp; |
| pn_negocio_codigo | int | 4   | NULL | Codigo del negocio |     |
| pn_producto | varchar | 60  | NULL | Codigo del producto |     |
| pn_inventario_total | int | 4   | NULL | Cantidad de inventario |     |
| pn_ventas_total | int | 4   | NULL | Ventas en total |     |
| pn_precio_compra | money | 8   | NULL | Precio de compra |     |
| pn_precio_venta | money | 8   | NULL | Precio de venta |     |

### cl_seccion_validar

Tabla donde se guarda la informacion de secciones validadas y no validadas en la pantalla de Información del Cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sv_ente | int | 4   | NOT NULL | Codigo del ente | &nbsp; |
| sv_seccion | catalogo | 10  | NULL | Codigo del seccion a validar | &nbsp; |
| sv_completado | char | 1   | NULL | Codigo de validacion | S: SI<br><br>N: NO |

### cl_trabajo

Tabla donde se guarda la informacion de referencias laborales asociadas al ente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tr_persona | int | 4   | NOT NULL | Identificador del ente | &nbsp; |
| tr_trabajo | tinyint | 1   | NOT NULL | Identificador de la referencia laboral | &nbsp; |
| tr_empresa | descripcion | 160 | NOT NULL | Nombre de la referencia laboral | S: SI<br><br>N: NO |
| tr_cargo | descripcion | 160 | NULL | Descripción del cargo del ente en la referencia laboral |     |
| tr_sueldo | money | 8   | NULL | No aplica |     |
| tr_moneda | tinyint | 1   | NULL | No aplica |     |
| tr_tipo | catalogo | 10  | NULL |     |     |
| tr_fecha_registro | datetime | 8   | NOT NULL | Fecha de registro de la referencia laboral |     |
| tr_fecha_modificacion | datetime | 8   | NOT NULL | Fecha de modificación de la referencia laboral |     |
| tr_vigencia | char | 1   | NOT NULL | Indica si la referencia laboral se encuenta vigente. Al crearla se pone en S | S: Si,<br><br>N: No |
| tr_fecha_ingreso | datetime | 8   | NULL | Fecha de ingreso del ente |     |
| tr_fecha_salida | datetime | 8   | NULL | Fecha de salida del ente |     |
| tr_verificado | char | 1   | NULL | Indica si la referencia laboral ha sido verificada | S: Si,<br><br>N: No |
| tr_funcionario | login | 14  | NULL | No aplica |     |
| tr_fecha_verificacion | datetime | 8   | NULL | No aplica |     |
| tr_tipo_empleo | catalogo | 10  | NULL | No aplica |     |
| tr_recpublicos | char | 1   | NULL | No aplica |     |
| tr_obs_verificado | varchar | 10  | NULL | No aplica |     |
| tr_nombre_emp | varchar | 64  | NULL | Nombre de la referencia laboral |     |
| tr_objeto_emp | varchar | 64  | NULL | No aplica |     |
| tr_direccion_emp | varchar | 254 | NULL | Dirección de la referencia laboral |     |
| tr_telefono | varchar | 20  | NULL | Teléfono |     |
| tr_planilla | varchar | 6   | NULL | Número de planilla |     |
| tr_sub_cargo | descripcion | 160 | NULL | No aplica |     |
| tr_antiguedad | int | 4   | NULL | Antigüedad del ente en la referencia laboral |     |
| tr_iden_emp | varchar | 24  | NULL | No aplica |     |
| tr_tipo_emp | catalogo | 10  | NULL | Tipo de empresa |     |
| tr_actividad | char | 1   | NULL | No aplica |     |
| tr_cod_actividad | catalogo | 10  | NULL | Código de la actividad que desempeña el ente en la referencia laboral |     |
| tr_func_public | catalogo | 10  | NULL | Indica si es funcionario público | S: Si,<br><br>N: No |
| tr_fuente_verif | varchar | 10  | NULL | No aplica |     |
| tr_actividad_ingresof | int | 4   | NULL | No aplica |     |
| tr_descripcion | varchar | 60  | NULL | No aplica |     |
| tr_id_empresa | int | 4   | NULL | Identificador de la referencia en caso de que se haya seleccionado una persona jurídica existente. |     |
| tr_tipo_cargo | catalogo | 10  | NULL | Código del cargo del ente (El código viene dado por el catálogo asociado) |     |

### cl_ident_ente

Tabla donde se guarda la informacion de secciones validadas y no validadas en la pantalla de Información del Cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| Ie_ente | int | 4   | NOT NULL | Codigo del ente | &nbsp; |
| Ie_tipo_doc | catalogo | 10  | NOT NULL | Codigo del tipo de identificacion adicional | &nbsp; |
| Ie_numero | varchar | 20  | NOT NULL | Numero de tipo de identificacion adicional |     |

### cl_ref_telefono

Tabla donde se guardan los diferentes teléfonos de un cliente

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| rt_ente | Int |     | NOT NULL | Código del cliente | &nbsp; |
| rt_secuencial | Tinyint |     | NOT NULL | Secuencial del registro | &nbsp; |
| rt_sec_ref | Tinyint |     | NOT NULL | Secuencial de la referencia |     |
| rt_referencia | Char | 1   | NOT NULL | Tipo de referencia | L: Laboral<br><br>P: Personal |
| rt_tipo_tel | Char | 1   | NOT NULL | Tipo de teléfono | C: Celular<br><br>F: Fijo |
| rt_pais | Varchar | 10  | NULL | Prefijo del país |     |
| rt_area | Varchar | 10  | NULL | Área de donde pertenece el teléfono |     |
| rt_numero_tel | Varchar | 16  | NULL | Número de teléfono |     |

### cl_listas_negras_log

Tabla donde se guardan registros con la información respectiva de las consultas realizadas a listas.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ln_fecha_consulta | datetime |     | NOT NULL | Fecha de la consulta |     |
| ln_usuario | Varchar | 20  | NOT NULL | Nombre de usuario |     |
| ln_id_verificacion | Varchar | 51  | NOT NULL | Id de la verificación |     |
| ln_numero_coincidencias | Tinyint |     | NOT NULL | Número de coincidencias |     |
| ln_nombre | Varchar | 255 | NOT NULL | Nombre de la persona |     |
| ln_apellido | Varchar | 255 | NULL | Apellido de la persona |     |
| ln_tipo_documento | varchar | 24  | NULL | Tipo de documento de la persona |     |
| ln_numero_documento | varchar | 30  | NULL | Número de documento |     |
| ln_fecha_nacimiento | date | 8   | NULL | Fecha de nacimiento |     |
| ln_codigo_cliente | Int |     | NULL | Código del cliente |     |
| ln_nro_proceso | Varchar | 10  | NULL | Número del proceso |     |

### cl_listas_negras_rfe

Tabla donde se registran solo los casos cuando existan coincidencias en la consulta.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ne_id_verificacion | varchar | 51  | NOT NULL | Id de verificación |     |
| ne_coincidencia | Tinyint |     | NOT NULL | Número de coincidencia |     |
| ne_nombre | Varchar | 255 | NOT NULL | Nombre de la persona |     |
| ne_apellido | Varchar | 255 | NULL | Apellido de la persona |     |
| ne_tipo_persona | Char | 1   | NOT NULL | Tipo de persona |     |
| ne_codigo_cliente | int |     | NULL | Código del cliente |     |
| ne_nro_proceso | Varchar | 10  | NULL | Número del proceso |     |
| ne_justificacion | varchar | 255 | NULL | Justificación o descripción |     |
| ne_estado_resolucion | char | 1   | NULL | Estado de la resolución del cliente |     |
| ne_fecha_resolucion | Datetime | 8   | NULL | Fecha de resolución |     |
| ne_nro_aml | varchar | 20  | NULL | Número AML asociado |     |

### cl_indice_pob_preg

Tabla donde se registran las preguntas para determinar el índice de pobreza de un cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ipp_num_preg | int |     | NOT NULL | Id de la pregunta |     |
| ipp_pregunta | varchar | 30  | NOT NULL | Contenido de la pregunta |     |
| ipp_descripcion | varchar | 256 | NOT NULL | Descripción a detalle de la pregunta |     |
| ipp_estado | catalogo |     | NULL | Estado de la pregunta | V: VIGENTE<br><br>C: CANCELADO |
| ipp_usuario_crea | login |     | NULL | Usuario que crea el registro |     |
| ipp_fecha_crea | datetime |     | NULL | Fecha de creación |     |
| ipp_usuario_modif | login |     | NULL | Usuario que modifica el resgistro |     |
| ipp_fecha_modif | datetime |     | NULL | Fecha de modificación |     |

### cl_indice_pob_respuesta

Tabla donde se registran las respuestas para las preguntas que determinan el índice de pobreza de un cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ipr_numero_resp | int |     | NOT NULL | Id de la respuesta |     |
| ipr_num_preg | int |     | NOT NULL | Id de la pregunta |     |
| ipr_respuesta | varchar | 150 | NOT NULL | Contenido de la respuesta |     |
| ipr_score | int |     | NULL | Puntaje de la respuesta |     |
| ipr_estado | catalogo |     | NOT NULL | Estado de la respuesta | V: VIGENTE<br><br>C: CANCELADO |
| ipr_usuario_crea | login |     | NULL | Usuario que crea el registro |     |
| ipr_fecha_crea | datetime |     | NULL | Fecha de creación |     |
| ipr_usuario_modif | login |     | NULL | Usuario que modifica el resgistro |     |
| ipr_fecha_modif | datetime |     | NULL | Fecha de modificación |     |

### cl_ppi_ente

Tabla donde se registran datos de la probabilidad de índice de pobreza de un cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pe_ente | int |     | NOT NULL | Id del cliente |     |
| pe_fecha_ini | varchar | 30  | NOT NULL | Fecha de inicio de validez del registro |     |
| pe_fecha_fin | varchar | 256 | NOT NULL | Fecha de vencimiento de la validez del registro |     |
| pe_usuario | catalogo |     | NULL | Usuario que registra |     |
| pe_fecha_ing | login |     | NULL | Fecha de creación |     |
| pe_fecha_modif | datetime |     | NULL | Fecha de modificación |     |

### cl_det_ppi_ente

Tabla donde se registra el detalle del PPI de un cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dpe_ente | int |     | NOT NULL | Id del cliente |     |
| dpe_num_preg | int |     | NOT NULL | Id de la pregunta |     |
| dpe_numero_resp | int |     | NULL | Id de la respuesta |     |
| dpe_score | int |     | NULL | Puntaje de la respuesta |     |

### cl_puntaje_ppi_ente

Tabla donde se registra el puntaje del PPI de un cliente.

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ppe_fecha | datetime |     | NOT NULL | Fecha del registro |     |
| ppe_ente | int |     | NOT NULL | Id del ente |     |
| ppe_score | int |     | NOT NULL | Puntaje total del PPI |     |

## Vistas y transacciones de servicios

Cada módulo tiene una Base de Datos, la cual cuenta con una tabla de Transacciones de Servicio, en la que se incluyen todos los campos de todas las tablas que pueden sufrir modificación en la operación del módulo (inserción, actualización o eliminación). Se entiende por Vista de Transacciones de Servicio, aquella porción de la tabla Transacciones de Servicio que compete a determinada Transacción.

Cada modificación de la Base de Datos genera un registro indicando la transacción realizada (secuencial, clase y código), persona que ejecuta la transacción (usuario que envía el requerimiento), desde y dónde (terminal, y servidores de origen y ejecución de la transacción) y los datos de la tabla a modificar.

### cl_tran_servicio

Guarda las transacciones de servicio, incluyen todos los campos de todas las tablas que pueden sufrir modificacion en la operación del modulo: insercion, actualizacion o eliminacion.

| Nombre | Tipo | Longitud | Requerido | Descripción |
| --- | --- | --- | --- | --- |
| Monto | money | 8   | NULL |     |
| ts_abreviatura | catalogo | 10  | NULL |     |
| ts_actividad | catalogo | 10  | NULL |     |
| ts_activo | money | 8   | NULL |     |
| ts_af | char | 2   | NULL |     |
| ts_antiguedad | int | 4   | NULL |     |
| ts_aplica_mora | char | 1   | NULL |     |
| ts_archivo | varchar | 14  | NULL |     |
| ts_asfi | char | 1   | NULL |     |
| ts_asosciada | catalogo | 10  | NULL |     |
| ts_balprome | varchar | 10  | NULL |     |
| ts_barrio | char | 40  | NULL |     |
| ts_bienes | char | 1   | NULL |     |
| ts_calif_cliente | catalogo | 10  | NULL |     |
| ts_calificacion | char | 15  | NULL |     |
| ts_calificador | char | 40  | NULL |     |
| ts_calle | varchar | 80  | NULL |     |
| ts_camara | catalogo | 10  | NULL |     |
| ts_canal_extracto | char | 1   | NULL |     |
| ts_carg_pub | char | 1   | NULL |     |
| ts_cargo | smallint | 2   | NULL |     |
| ts_casilla | varchar | 24  | NULL |     |
| ts_categoria | catalogo | 10  | NULL |     |
| ts_ced_discapacidad | varchar | 30  | NULL |     |
| ts_cedruc | numero | 30  | NULL |     |
| ts_cir_comunic | varchar | 10  | NULL |     |
| ts_ciudad | int | 4   | NULL |     |
| ts_ciudad_bien | int | 4   | NULL |     |
| ts_ciudad_nac | int | 4   | NULL |     |
| ts_ciudad_tef | int | 4   | NULL |     |
| ts_clase | char | 1   | NOT NULL |     |
| ts_clase_bienes_e | varchar | 35  | NULL |     |
| ts_cliente_preferencial | char | 1   | NULL |     |
| ts_cobertura | varchar | 30  | NULL |     |
| ts_cod_alterno | int | 4   | NULL |     |
| ts_cod_atr | tinyint | 1   | NULL |     |
| ts_cod_fie_asf | varchar | 10  | NULL |     |
| ts_cod_otro_pais | int | 4   | NULL |     |
| ts_cod_tbl_inf | smallint | 2   | NULL |     |
| ts_codigo | int | 4   | NULL |     |
| ts_codigo_alerta | int | 4   | NULL |     |
| ts_codigo_mr | int | 4   | NULL |     |
| ts_codigocat | catalogo | 10  | NULL |     |
| ts_codpostal | varchar | 30  | NULL |     |
| ts_colonia | varchar | 10  | NULL |     |
| ts_compania | varchar | 36  | NULL |     |
| ts_costo | money | 8   | NULL |     |
| ts_cuenta | cuenta | 24  | NULL |     |
| ts_cuenta_bancaria | char | 16  | NULL |     |
| ts_cupo_usado | money | 8   | NULL |     |
| ts_debito_aut | char | 1   | NULL |     |
| ts_depart_pais | catalogo | 10  | NULL |     |
| ts_departamento | smallint | 2   | NULL |     |
| ts_deposini | varchar | 10  | NULL |     |
| ts_derecha | descripcion | 160 | NULL |     |
| ts_des_cta_afi | char | 1   | NULL |     |
| ts_des_otros_ingresos | catalogo | 10  | NULL |     |
| ts_desc_atr | descripcion | 160 | NULL |     |
| ts_desc_direc | descripcion | 160 | NULL |     |
| ts_desc_ingresos | catalogo | 10  | NULL |     |
| ts_desc_larga | varchar | 255 | NULL |     |
| ts_desc_oingreso | descripcion | 160 | NULL |     |
| ts_desc_seguro | varchar | 64  | NULL |     |
| ts_desc_tbl_inf | descripcion | 160 | NULL |     |
| ts_descmoneda | descripcion | 160 | NULL |     |
| ts_descrip_ref_per | varchar | 64  | NULL |     |
| ts_descripcion | descripcion | 160 | NULL |     |
| ts_dia_pago | tinyint | 1   | NULL |     |
| ts_dias_gracia | tinyint | 1   | NULL |     |
| ts_digito | char | 1   | NULL |     |
| ts_dinero | char | 1   | NULL |     |
| ts_direc | direccion | 255 | NULL |     |
| ts_direccion | int | 4   | NULL |     |
| ts_direccion_hip | varchar | 60  | NULL |     |
| ts_discapacidad | char | 1   | NULL |     |
| ts_dispersion_fondos | char | 1   | NULL |     |
| ts_doc_validado | char | 1   | NULL |     |
| ts_documento | int | 4   | NULL |     |
| ts_egresos | money | 8   | NULL |     |
| ts_emp_postal | varchar | 24  | NULL |     |
| ts_empresa | int | 4   | NULL |     |
| ts_ente | int | 4   | NULL |     |
| ts_ente_externo | int | 4   | NULL |     |
| ts_escritura | int | 4   | NULL |     |
| ts_estado | estado | 1   | NULL |     |
| ts_estado_civil | catalogo | 10  | NULL |     |
| ts_estado_huella | catalogo | 10  | NULL |     |
| ts_estado_ref | catalogo | 10  | NULL |     |
| ts_estatus | char | 1   | NULL |     |
| ts_exc_por2 | char | 1   | NULL |     |
| ts_exc_sipla | char | 1   | NULL |     |
| ts_exonera_estudio | char | 1   | NULL |     |
| ts_fec_aut_asf | datetime | 8   | NULL |     |
| ts_fec_exp_ref | datetime | 8   | NULL |     |
| ts_fec_inicio | datetime | 8   | NULL |     |
| ts_fec_vencimiento | datetime | 8   | NULL |     |
| ts_fecha | datetime | 8   | NULL |     |
| ts_fecha_act_huella | datetime | 8   | NULL |     |
| ts_fecha_constitucion | datetime | 8   | NULL |     |
| ts_fecha_cov | char | 10  | NULL |     |
| ts_fecha_emision | datetime | 8   | NULL |     |
| ts_fecha_escritura | datetime | 8   | NULL |     |
| ts_fecha_exp | datetime | 8   | NULL |     |
| ts_fecha_expira | datetime | 8   | NULL |     |
| ts_fecha_fija | char | 1   | NULL |     |
| ts_fecha_hip | datetime | 8   | NULL |     |
| ts_fecha_ingreso | datetime | 8   | NULL |     |
| ts_fecha_mod | char | 10  | NULL |     |
| ts_fecha_modifi | datetime | 8   | NULL |     |
| ts_fecha_modificacion | datetime | 8   | NULL |     |
| ts_fecha_nac | datetime | 8   | NULL |     |
| ts_fecha_nac_mer | datetime | 8   | NULL |     |
| ts_fecha_nac1 | datetime | 8   | NULL |     |
| ts_fecha_pago | char | 1   | NULL |     |
| ts_fecha_pig | datetime | 8   | NULL |     |
| ts_fecha_ref | char | 10  | NULL |     |
| ts_fecha_reg | datetime | 8   | NULL |     |
| ts_fecha_reg_huella | datetime | 8   | NULL |     |
| ts_fecha_registro | datetime | 8   | NULL |     |
| ts_fecha_ult_mod | datetime | 8   | NULL |     |
| ts_fecha_valuo | datetime | 8   | NULL |     |
| ts_fecha_vcto | datetime | 8   | NULL |     |
| ts_fecha_verificacion | datetime | 8   | NULL |     |
| ts_fecha_verificacion1 | datetime | 8   | NULL |     |
| ts_filial | tinyint | 1   | NULL |     |
| ts_finca | int | 4   | NULL |     |
| ts_folio | int | 4   | NULL |     |
| ts_forma_des | catalogo | 10  | NULL |     |
| ts_forma_homologa | catalogo | 10  | NULL |     |
| ts_fpas_finan | datetime | 8   | NULL |     |
| ts_fuente_verificacion | varchar | 19  | NULL |     |
| ts_funcionario | smallint | 2   | NULL |     |
| ts_garantia | char | 1   | NULL |     |
| ts_gmf_banco | char | 1   | NULL |     |
| ts_grado_soc | catalogo | 10  | NULL |     |
| ts_gravada | money | 8   | NULL |     |
| ts_gravamen_afavor | char | 30  | NULL |     |
| ts_grp_inf | catalogo | 10  | NULL |     |
| ts_grupo | int | 4   | NULL |     |
| ts_hora | datetime | 8   | NULL |     |
| ts_ifi | char | 1   | NULL |     |
| ts_img_huella | varchar | 30  | NULL |     |
| ts_ingre | varchar | 10  | NULL |     |
| ts_ingresos | money | 8   | NULL |     |
| ts_inirelac | char | 4   | NULL |     |
| ts_inss | varchar | 15  | NULL |     |
| ts_izquierda | descripcion | 160 | NULL |     |
| ts_jefe | smallint | 2   | NULL |     |
| ts_jefe_agenc | int | 4   | NULL |     |
| ts_jz | char | 2   | NULL |     |
| ts_libro | int | 4   | NULL |     |
| ts_licencia | varchar | 30  | NULL |     |
| ts_localidad | varchar | 20  | NULL |     |
| ts_login | login | 14  | NULL |     |
| ts_lsrv | varchar | 30  | NULL |     |
| ts_lugar_doc | int | 4   | NULL |     |
| ts_mandat | char | 1   | NULL |     |
| ts_mantiene_condiciones | char | 1   | NULL |     |
| ts_matricula | varchar | 16  | NULL |     |
| ts_mensaje | varchar | 255 | NULL |     |
| ts_moneda | tinyint | 1   | NULL |     |
| ts_monto_vencido | money | 8   | NULL |     |
| ts_motiv_term | catalogo | 10  | NULL |     |
| ts_mpromcre | varchar | 10  | NULL |     |
| ts_mpromdeb | varchar | 10  | NULL |     |
| ts_municipio | varchar | 10  | NULL |     |
| ts_naciona | int | 4   | NULL |     |
| ts_nacional | char | 1   | NULL |     |
| ts_nacionalidad | descripcion | 160 | NULL |     |
| ts_nemdef | char | 6   | NULL |     |
| ts_nemon | char | 6   | NULL |     |
| ts_nit | numero | 30  | NULL |     |
| ts_nit_per | numero | 30  | NULL |     |
| ts_nit_venc | datetime | 8   | NULL |     |
| ts_nivel | tinyint | 1   | NULL |     |
| ts_nivel_egresos | catalogo | 10  | NULL |     |
| ts_nivel_estudio | catalogo | 10  | NULL |     |
| ts_nom_aval | char | 30  | NULL |     |
| ts_nom_empresa | descripcion | 160 | NULL |     |
| ts_nomb_comercial | varchar | 128 | NULL |     |
| ts_nombre | descripcion | 160 | NULL |     |
| ts_nombre_completo | varchar | 255 | NULL |     |
| ts_nombre_empresa | descripcion | 160 | NULL |     |
| ts_nomina | smallint | 2   | NULL |     |
| ts_notaria | tinyint | 1   | NULL |     |
| ts_nro | int | 4   | NULL |     |
| ts_ntrancre | varchar | 10  | NULL |     |
| ts_ntrandeb | varchar | 10  | NULL |     |
| ts_num_cargas | tinyint | 1   | NULL |     |
| ts_num_empleados | smallint | 2   | NULL |     |
| ts_num_hijos | tinyint | 1   | NULL |     |
| ts_num_poliza | varchar | 36  | NULL |     |
| ts_numero | tinyint | 1   | NULL |     |
| ts_o_departamento | smallint | 2   | NULL |     |
| ts_obs_horario | varchar | 120 | NULL |     |
| ts_obserprocta | varchar | 10  | NULL |     |
| ts_observacion | varchar | 255 | NULL |     |
| ts_observaciondir | varchar | 80  | NULL |     |
| ts_observaciones | varchar | 255 | NULL |     |
| ts_ofic_vinc | smallint | 2   | NULL |     |
| ts_oficina | smallint | 2   | NULL |     |
| ts_origen | char | 40  | NULL |     |
| ts_origen_ingresos | descripcion | 160 | NULL |     |
| ts_otros_ingresos | money | 8   | NULL |     |
| ts_p_apellido | descripcion | 160 | NULL |     |
| ts_pais | smallint | 2   | NULL |     |
| ts_pais1 | varchar | 10  | NULL |     |
| ts_parametro_mul | smallint | 2   | NULL |     |
| ts_parroquia | int | 4   | NULL |     |
| ts_pas_finan | money | 8   | NULL |     |
| ts_pasaporte | varchar | 20  | NULL |     |
| ts_pasivo | money | 8   | NULL |     |
| ts_path_croquis | varchar | 50  | NULL |     |
| ts_path_foto | varchar | 50  | NULL |     |
| ts_patrimonio_b | money | 8   | NULL |     |
| ts_patrimonio_tec | money | 8   | NULL |     |
| ts_periodo | int | 4   | NULL |     |
| ts_porcentaje_exonera | float | 8   | NULL |     |
| ts_porcentaje_gmfbanco | float | 8   | NULL |     |
| ts_posicion | catalogo | 10  | NULL |     |
| ts_procedure | int | 4   | NULL |     |
| ts_producto | char | 3   | NULL |     |
| ts_profesion | catalogo | 10  | NULL |     |
| ts_promedio_ventas | money | 8   | NULL |     |
| ts_promotor | char | 10  | NULL |     |
| ts_proposito | catalogo | 10  | NULL |     |
| ts_provincia | smallint | 2   | NULL |     |
| ts_puesto_e | varchar | 10  | NULL |     |
| ts_rango_max | int | 4   | NULL |     |
| ts_rango_min | int | 4   | NULL |     |
| ts_rango_nor_max | int | 4   | NULL |     |
| ts_rango_nor_min | int | 4   | NULL |     |
| ts_razon_social | varchar | 254 | NULL |     |
| ts_referido | smallint | 2   | NULL |     |
| ts_referidor_ecu | int | 4   | NULL |     |
| ts_reg_nat | catalogo | 10  | NULL |     |
| ts_reg_ope | catalogo | 10  | NULL |     |
| ts_regional | varchar | 10  | NULL |     |
| ts_registro | int | 4   | NULL |     |
| ts_rel_carg_pub | char | 1   | NULL |     |
| ts_release | varchar | 12  | NULL |     |
| ts_rep | descripcion | 160 | NULL |     |
| ts_rep_legal | int | 4   | NULL |     |
| ts_rep_superban | char | 1   | NULL |     |
| ts_restado | catalogo | 10  | NULL |     |
| ts_restringue_uso | char | 1   | NULL |     |
| ts_rural_urbano | char | 1   | NULL |     |
| ts_s_apellido | descripcion | 160 | NULL |     |
| ts_saldo_minimo | money | 8   | NULL |     |
| ts_sb | char | 2   | NULL |     |
| ts_sec_huella | int | 4   | NULL |     |
| ts_seccuenta | int | 4   | NULL |     |
| ts_sector | catalogo | 10  | NULL |     |
| ts_secuencia | tinyint | 1   | NULL |     |
| ts_secuencial | int | 4   | NOT NULL |     |
| ts_secuencial1 | int | 4   | NULL |     |
| ts_segundos_lat | float | 8   | NULL |     |
| ts_segundos_long | float | 8   | NULL |     |
| ts_sexo | sexo | 1   | NULL |     |
| ts_sigla | varchar | 25  | NULL |     |
| ts_signo_spread | char | 1   | NULL |     |
| ts_situacion_laboral | varchar | 5   | NULL |     |
| ts_sospechoso | catalogo | 10  | NULL |     |
| ts_srv | varchar | 30  | NULL |     |
| ts_sub_cargo | descripcion | 160 | NULL |     |
| ts_subemp | char | 10  | NULL |     |
| ts_subemp1 | char | 10  | NULL |     |
| ts_subemp2 | char | 10  | NULL |     |
| ts_sucursal | smallint | 2   | NULL |     |
| ts_sucursal_ref | varchar | 80  | NULL |     |
| ts_suplidores | descripcion | 160 | NULL |     |
| ts_tabla | smallint | 2   | NULL |     |
| ts_table | char | 30  | NULL |     |
| ts_tasa_mora | catalogo | 10  | NULL |     |
| ts_tbien | catalogo | 10  | NULL |     |
| ts_tclase | descripcion | 160 | NULL |     |
| ts_telefono | varchar | 14  | NULL |     |
| ts_telefono_1 | char | 12  | NULL |     |
| ts_telefono_2 | char | 12  | NULL |     |
| ts_telefono_3 | char | 12  | NULL |     |
| ts_telefono_ref | varchar | 16  | NULL |     |
| ts_term | varchar | 32  | NULL |     |
| ts_terminal | descripcion | 160 | NULL |     |
| ts_tgarantia | catalogo | 10  | NULL |     |
| ts_tiempo_conocido | int | 4   | NULL |     |
| ts_tiempo_reside | int | 4   | NULL |     |
| ts_tip_punt_at | varchar | 10  | NULL |     |
| ts_tipo | catalogo | 10  | NULL |     |
| ts_tipo_alerta | catalogo | 10  | NULL |     |
| ts_tipo_ced | char | 4   | NULL |     |
| ts_tipo_credito | char | 1   | NULL |     |
| ts_tipo_discapacidad | catalogo | 10  | NULL |     |
| ts_tipo_dp | char | 1   | NULL |     |
| ts_tipo_empleo | catalogo | 10  | NULL |     |
| ts_tipo_horar | varchar | 10  | NULL |     |
| ts_tipo_huella | catalogo | 10  | NULL |     |
| ts_tipo_link | char | 1   | NULL |     |
| ts_tipo_nit | char | 2   | NULL |     |
| ts_tipo_operador | varchar | 10  | NULL |     |
| ts_tipo_producto | tinyint | 1   | NULL |     |
| ts_tipo_recaudador | char | 1   | NULL |     |
| ts_tipo_soc | catalogo | 10  | NULL |     |
| ts_tipo_transaccion | int | 4   | NULL |     |
| ts_tipo_transaccion_producto | int | 4   | NULL |     |
| ts_tipo_vinculacion | catalogo | 10  | NULL |     |
| ts_tipo_vivienda | catalogo | 10  | NULL |     |
| ts_toperacion | char | 1   | NULL |     |
| ts_total_activos | money | 8   | NULL |     |
| ts_totaliza | char | 1   | NULL |     |
| ts_updlogin | login | 14  | NULL |     |
| ts_user | login | 14  | NULL |     |
| ts_usuario | login | 14  | NULL |     |
| ts_val_aval | money | 8   | NULL |     |
| ts_valor | descripcion | 160 | NULL |     |
| ts_valor_spread | tinyint | 1   | NULL |     |
| ts_verificado | char | 1   | NULL |     |
| ts_vinculacion | char | 1   | NULL |     |
| ts_zona | catalogo | 10  | NULL |     |
| ts_gar_liquida | char | 1   | NULL |     |
| ts_pais_nac | varchar | 10  | NULL |     |
| ts_provincia_nac | int | 4   | NULL |     |
| ts_naturalizado | char | 1   | NULL |     |
| ts_forma_migratoria | varchar | 64  | NULL |     |
| ts_nro_extranjero | varchar | 64  | NULL |     |
| ts_calle_orig | varchar | 70  | NULL |     |
| ts_exterior_orig | varchar | 40  | NULL |     |
| ts_estado_orig | varchar | 40  | NULL |     |
| ts_referencias_dom | varchar | 255 | NULL |     |
| ts_otro_tipo | varchar | 20  | NULL |     |
| ts_pais_nac_c | varchar | 10  | NULL |     |
| ts_naturalizado_c | char | 1   | NULL |     |
| ts_forma_mig_c | varchar | 10  | NULL |     |
| ts_numero_ext_c | int | 4   | NULL |     |
| ts_tipo_iden_c | varchar | 10  | NULL |     |
| ts_numero_iden_c | varchar | 32  | NULL |     |
| ts_localidad_c | varchar | 20  | NULL |     |
| ts_calle_orig_c | varchar | 70  | NULL |     |
| ts_exterior_orig_c | varchar | 40  | NULL |     |
| ts_estado_orig_c | varchar | 40  | NULL |     |
| ts_escolaridad_c | catalogo | 10  | NULL |     |
| ts_ocupacion_c | catalogo | 10  | NULL |     |
| ts_actividad_c | catalogo | 10  | NULL |     |
| ts_dependientes_c | int | 4   | NULL |     |
| ts_ident_tipo_c | varchar | 10  | NULL |     |
| ts_ident_num_c | varchar | 30  | NULL |     |
| ts_email_c | varchar | 50  | NULL |     |
| ts_operacion | char | 1   | NULL |     |
| ts_prefijo | varchar | 10  | NULL |     |
| ts_id_verificacion | varchar | 51  | NULL |     |
| ts_coincidencia | tinyint | 2   | NULL |     |
| ts_cuota_pago_buro | money | 8   | NULL |     |
| ts_deuda_corto_buro | money | 8   | NULL |     |
| ts_deuda_largo_buro | money | 8   | NULL |     |
| ts_cuota_pago_enlace | money | 8   | NULL |     |
| ts_deuda_corto_enlace | money | 8   | NULL |     |
| ts_deuda_largo_enlace | money | 8   | NULL |     |
| ts_valor_vehiculo2 | money | 8   | NULL |     |
| ts_valor_vivienda2 | money | 8   | NULL |     |
| ts_ajuste_deuda | money | 8   | NULL |     |

## Vistas

### ts_persona

Transacciones de servicio: 172024

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | Secuencial |
| tipo_transaccion | tipo_transaccion |
| clase | Clase |
| fecha | Fecha |
| usuario | Usuario |
| terminal | Terminal |
| srv | Srv |
| lsrv | Lsrv |
| persona | Persona |
| nombre | Nombre |
| p_apellido | p_apellido |
| s_apellido | s_apellido |
| sexo | Sexo |
| cedula | Cedula |
| pasaporte | pasaporte |
| tipo_ced | tipo_ced |
| pais | Pais |
| profesion | profesion |
| estado_civil | estado_civil |
| actividad | actividad |
| num_cargas | num_cargas |
| nivel_ing | nivel_ing |
| nivel_egr | nivel_egr |
| tipo | Tipo |
| filial | Filial |
| oficina | Oficina |
| casilla_def | casilla_def |
| tipo_dp | tipo_dp |
| fecha_nac | fecha_nac |
| grupo | Grupo |
| oficial | Oficial |
| mala_referencia | mala_referencia |
| comentario | comentario |
| retencion | retencion |
| fecha_mod | fecha_mod |
| fecha_emision | fecha_emision |
| fecha_expira | fecha_expira |
| asosciada | asosciada |
| referido | referido |
| sector | sector |
| nit_per | nit_per |
| ciudad_nac | ciudad_nac |
| lugar_doc | lugar_doc |
| nivel_estudio | nivel_estudio |
| tipo_vivienda | tipo_vivienda |
| calif_cliente | calif_cliente |
| doc_validado | doc_validado |
| rep_superban | rep_superban |
| vinculacion | vinculacion |
| tipo_vinculacion | tipo_vinculacion |
| exc_sipla | exc_sipla |
| exc_por2 | exc_por2 |
| digito | digito |
| s_nombre | s_nombre |
| c_apellido | c_apellido |
| departamento | departamento |
| num_orden | num_orden |
| promotor | promotor |
| nacionalidad | nacionalidad |
| cod_otro_pais | cod_otro_pais |
| inss | inss |
| licencia | licencia |
| ingre | ingre |
| id_tutor | id_tutor |
| nombre_tutor | nombre_tutor |
| usuario_elim | usuario_elim |
| fecha_elim | fecha_elim |
| observacion | observacion |
| Bloquear | bloquear |
| Categoria | categoria |
| referidor_ecu | referidor_ecu |
| carg_pub | carg_pub |
| rel_carg_pub | rel_carg_pub |
| situacion_laboral | situacion_laboral |
| Bienes | bienes |
| otros_ingresos | otros_ingresos |
| origen_ingresos | origen_ingresos |
| Verificado | verificado |
| fecha_verif | fecha_verif |
| ts_estado_referencia | ts_estado_referencia |
| estado_ea | estado_ea |
| observacion_aut | observacion_aut |
| contrato_firmado | contrato_firmado |
| menor_edad | menor_edad |
| conocido_como | conocido_como |
| cliente_planilla | cliente_planilla |
| cod_risk | cod_risk |
| sector_eco | sector_eco |
| actividad_ea | actividad_ea |
| empadronado | empadronado |
| lin_neg | lin_neg |
| seg_neg | seg_neg |
| val_id_check | val_id_check |
| ejecutivo_con | ejecutivo_con |
| suc_gestion | suc_gestion |
| constitucion | constitucion |
| remp_legal | remp_legal |
| apoderado_legal | apoderado_legal |
| act_comp_kyc | act_comp_kyc |
| fecha_act_kyc | fecha_act_kyc |
| no_req_kyc_comp | no_req_kyc_comp |
| act_perfiltran | act_perfiltran |
| fecha_act_perfiltran | fecha_act_perfiltran |
| con_salario | con_salario |
| fecha_consal | fecha_consal |
| sin_salario | sin_salario |
| fecha_sinsal | fecha_sinsal |
| actualizacion_cic | actualizacion_cic |
| fecha_act_cic | fecha_act_cic |
| excepcion_cic | excepcion_cic |
| fuente_ing | fuente_ing |
| act_prin | act_prin |
| Detalle | Detalle |
| act_dol | act_dol |
| cat_aml | cat_aml |
| nivel_egresos | nivel_egresos |
| Ifi | Ifi |
| Asfi | Asfi |
| Discapacidad | Discapacidad |
| tipo_discapacidad | tipo_discapacidad |
| ced_discapacidad | ced_discapacidad |

### ts_compania

Transacciones de servicio: 172008,172009,172023

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| Compania | ts_ente |
| Nombre | ts_nombre |
| Ruc | ts_cedruc |
| Actividad | ts_actividad |
| Posicion | ts_posicion |
| Grupo | ts_grupo |
| rep_legal | ts_rep_legal |
| Activo | ts_activo |
| Pasivo | ts_pasivo |
| Tipo | ts_tipo |
| Filial | ts_filial |
| Pais | ts_pais |
| Oficina | ts_oficina |
| casilla_def | ts_casilla |
| tipo_dp | ts_tipo_dp |
| es_grupo | ts_dinero |
| Retencion | ts_estado_civil |
| fecha_mod | ts_fecha_modificacion |
| mala_referencia | ts_abreviatura |
| Comentario | ts_observacion |
| Oficial | ts_funcionario |
| capital_social | ts_saldo_minimo |
| reserva_legal | ts_costo |
| fecha_const | ts_fecha_nac |
| nombre_completo | ts_nombre_completo |
| Plazo | ts_numero |
| direccion_domicilio | ts_direccion |
| fecha_inscrp | ts_fecha_reg |
| fecha_aum_capital | ts_fecha_emision |
| Asosciada | ts_asosciada |
| Referido | ts_referido |
| Sector | ts_sector |
| tipo_nit | ts_tipo_nit |
| tipo_soc | ts_tipo_soc |
| fecha_emision | ts_fecha_emision |
| lugar_doc | ts_lugar_doc |
| total_activos | ts_total_activos |
| num_empleados | ts_num_empleados |
| Sigla | ts_sigla |
| rep_superban | ts_rep_superban |
| doc_validado | ts_doc_validado |
| Escritura | ts_escritura |
| Notaria | ts_notaria |
| Ciudad | ts_ciudad_bien |
| fecha_exp | ts_fecha_exp |
| fecha_vcto | ts_fecha_vcto |
| Camara | ts_camara |
| Registro | ts_registro |
| grado_soc | ts_grado_soc |
| Vinculacion | ts_vinculacion |
| tipo_vinculacion | ts_tipo_vinculacion |
| exc_sipla | ts_exc_sipla |
| nivel_ing | ts_ingresos |
| nivel_egr | ts_egresos |
| exc_por2 | ts_exc_por2 |
| Categoria | ts_categoria |
| pasivo1 | ts_gravada |
| pas_finan | ts_pas_finan |
| fpas_finan | ts_fpas_finan |
| Opinternac | ts_garantia |
| Numsuc | ts_num_cargas |
| Vigilada | ts_estado_ref |
| Vigencia | ts_tipo_alerta |

### ts_control_empresas_rfe

Transacciones de servicio: 172044

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| Fecha | ts_fecha |
| Hora | ts_hora |
| usuario | ts_usuario |
| terminal | ts_terminal |
| Srv | ts_srv |
| lsrv | ts_lsrv |
| Ente | ts_ente |
| Compania | ts_cod_alterno |
| tipo_control | ts_clase_bienes_e |
| Vigencia | ts_vinculacion |
| verificacion | ts_verificado |

### ts_direccion

Transacciones de servicio: 172016, 172019, 172021

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Hora | ts_hora |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| lsrv | ts_lsrv |
| Ente | ts_ente |
| Direccion | ts_direccion |
| Descripcion | ts_descripcion |
| Vigencia | ts_posicion |
| Sector | ts_sector |
| }zona | ts_zona |
| Parroquia | ts_parroquia |
| Ciudad | ts_ciudad |
| Tipo | ts_tipo |
| Oficina | ts_oficina |
| Verificado | ts_tipo_dp |
| Barrio | ts_barrio |
| Provincia | ts_provincia |
| Codpostal | ts_emp_postal |
| Casa | ts_pasaporte |
| Calle | ts_sucursal_ref |
| Pais | ts_pais |
| Correspondencia | ts_estatus |
| Alquilada | ts_garantia |
| Cobro | ts_mandat |
| Edificio | ts_razon_social |
| Departamento | ts_ingre |
| rural_urbano | ts_dinero |
| fact_serv_pu | ts_toperacion |
| tipo_prop | ts_fecha_ref |
| nombre_agencia | ts_clase_bienes_e |
| fuente_verif | ts_valor |
| fecha_ver | ts_fecha_valuo |
| Reside | ts_tiempo_reside |
| Negocio | ts_lugar_doc |
| referencias_dom | ts_referencias_dom |
| otro_tipo | ts_otro_tipo |
| Localidad | ts_localidad |

### ts_direccion_fiscal

Transacciones de servicio: 172001

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| Fecha | ts_fecha |
| Hora | ts_hora |
| usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| lsrv | ts_lsrv |
| Ente | ts_ente |
| sec_ente | ts_direccion |
| tipo_direccion | ts_archivo |
| Pais | ts_pais |
| Codpostal | ts_emp_postal |
| provincia | ts_calle |
| Ciudad | ts_clase_bienes_e |
| calle_principal | ts_cobertura |
| con_edificio | ts_compania |
| num_piso | ts_num_poliza |
| oficina_departamento | ts_exterior_orig_c |
| Barrio | ts_barrio |
| dir_completa | ts_nombre_completo |
| Vigencia | ts_vinculacion |
| Verificacion | ts_verificado |

### ts_direccion_geo

Transacciones de servicio: 172046, 172047, 172080

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencia | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| oficina_s | ts_oficina |
| Usuario | ts_usuario |
| terminal_s | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| Hora | ts_fecha_modifi |
| Ente | ts_empresa |
| Direccion | ts_moneda |
| latitud_coord | ts_garantia |
| latitud_grados | ts_num_cargas |
| latitud_minutos | ts_filial |
| latitud_segundos | ts_segundos_lat |
| longitud_coord | ts_rep_superban |
| longitud_grados | ts_notaria |
| longitud_minutos | ts_cod_atr |
| longitud_segundos | ts_segundos_long |
| path_croquis | ts_path_croquis |

### ts_grupo

Transacciones de servicio: 172036

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| Grupo | ts_grupo |
| Nombre | ts_nombre |
| Representante | ts_rep_legal |
| Compania | ts_ente |
| Oficial | ts_jefe_agenc |
| fecha_registro | ts_fecha_emision |
| fecha_modificacion | ts_fecha_expira |
| Ruc | ts_cedruc |
| Vinculacion | ts_garantia |
| tipo_vinculacion | ts_tipo |
| max_riesgo | ts_promedio_ventas |
| Riesgo | ts_pasivo |
| Usuario | ts_usuario |
| Reservado | ts_ingresos |
| tipo_grupo | ts_proposito |
| Estado | ts_grado_soc |
| dir_reunion | ts_direc |
| dia_reunion | ts_camara |
| hora_reunion | ts_fpas_finan |
| comportamiento_pago | ts_telefono |
| num_ciclo | ts_escritura |
| gar_liquida | ts_gar_liquida |

### ts_pais_id_fiscal

Transacciones de servicio: 172035

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| operacion | ts_clase |
| Fecha | ts_fecha |
| Hora | ts_hora |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| lsrv | ts_lsrv |
| Ente | ts_ente |
| Pais | ts_depart_pais |
| tipo | ts_tipo |
| Identificacion | ts_ident_num_c |
| Vigencia | ts_vinculacion |
| Verificacion | ts_verificado |

### ts_analisis_negocio

Transacciones de servicio: 172083, 172100

| Campo Vista | Campo Tabla |
| --- | --- |
| an_tipo_transaccion | ts_tipo_transaccion |
| an_clase | ts_clase |
| an_secuencial | ts_secuencial |
| an_tabla | ts_table |
| an_operacion | ts_af |
| an_cliente_id | ts_ente |
| an_negocio_codigo | ts_cod_alterno |
| an_ventas_prom_mes | monto |
| an_compras_prom_mes | ts_activo |
| an_renta_neg | ts_archivo |
| an_transporte_neg | s_balprome |
| an_personal_neg | ts_barrio |
| an_impuestos_neg | ts_calificacion |
| an_electrica_neg | ts_calificador |
| an_agua_neg | ts_calle |
| an_telefono_neg | ts_casilla |
| an_otros_neg | ts_ced_discapacidad |
| an_inventario | ts_ciudad |
| an_inversion_neg | ts_clase_bienes_e |
| an_frecuencia_inv | ts_puesto_e |
| an_presta | ts_asfi |
| an_frecuencia_cobro | ts_cod_fie_asf |
| an_debe_prestamo | ts_cliente_preferencial |
| an_cuota_pago | ts_codpostal |
| an_frecuencia_pago | ts_colonia |
| an_disponible | ts_compania |
| an_ganancia_neg | ts_costo |
| an_frecuencia_util | ts_cuenta_bancaria |
| an_capacidad_pago_mes | ts_cupo_usado |
| an_producto | ts_desc_larga |
| an_porcentaje_venta_regs | ts_direccion_hip |
| an_valor_vivienda | ts_egresos |
| an_valor_negocio | ts_emp_postal |
| an_valor_vehiculo | ts_fecha_cov |
| an_valor_mobiliario | ts_fecha_mod |
| an_valor_otros | ts_fecha_ref |
| an_ingresos_extra | ts_garantia |
| an_monto_extra | ts_fuente_verificacion |
| an_origen_extra | ts_gravamen_afavor |
| an_gastos_alimentos | ts_gravada |
| an_gastos_renta_viv | ts_img_huella |
| an_gastos_energia_elect | ts_ingre |
| an_gastos_agua | ts_ingresos |
| an_gastos_telefono | ts_inss |
| an_gastos_tv | ts_licencia |
| an_gastos_salud | ts_localidad |
| an_gastos_transp | ts_lsrv |
| an_gastos_educ | ts_matricula |
| an_gastos_gas | ts_mensaje |
| an_gastos_vestido | ts_monto_vencido |
| an_gastos_otros | ts_mpromcre |
| an_ctas_por_cobrar | ts_desc_seguro |
| an_ctas_por_pagar_lar | ts_descrip_ref_per |
| an_cuota_pago_buro | ts_cuota_pago_buro |
| an_deuda_corto_buro | ts_deuda_corto_buro |
| an_deuda_largo_buro | ts_deuda_largo_buro |
| an_cuota_pago_enlace | ts_cuota_pago_enlace |
| an_deuda_corto_enlace | ts_deuda_corto_enlace |
| an_deuda_largo_enlace | ts_deuda_largo_enlace |
| an_valor_vehiculo2 | ts_valor_vehiculo2 |
| an_valor_vivienda2 | ts_valor_vivienda2 |
| an_ajuste_deuda | ts_ajuste_deuda |

### ts_cliente_grupo

Transacciones de servicio: 172037, 172038, 172041

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| srv | ts_srv |
| lsrv | ts_lsrv |
| Ente | ts_ente |
| grupo | ts_grupo |
| usuario | ts_usuario |
| Terminal | ts_terminal |
| oficial | ts_jefe_agenc |
| fecha_reg | ts_fecha_emision |
| Rol | ts_profesion |
| estado | ts_estado |
| calif_interna | ts_tipo_huella |
| fecha_desasociacion | ts_fecha_expira |

### ts_persona_prin

Transacciones de servicio: 172000, 172003, 172004, 172005, 172045, 172006

| Campo Vista | Campo Tabla |
| --- | --- |
| ts_secuencial | secuencia |
| ts_tipo_transaccion | tipo_transaccion |
| ts_clase | clase |
| ts_fecha | fecha |
| ts_hora | hora |
| ts_usuario | usuario |
| ts_terminal | terminal |
| ts_srv | srv |
| ts_lsrv | lsrv |
| ts_ente | persona |
| ts_nombre | nombre |
| ts_p_apellido | p_apellido |
| ts_s_apellido | s_apellido |
| ts_ingre | sexo |
| ts_num_poliza | cedula |
| ts_desc_seguro | tipo_ced |
| ts_nacional | pais |
| ts_bienes | profesion |
| ts_garantia | estado_civil |
| ts_estado | actividad |
| ts_codigocat | num_cargas |
| ts_toperacion | nivel_ing |
| ts_observaciones | nivel_egr |
| ts_estatus | tipo |
| ts_sigla | filial |
| ts_abreviatura | oficina |
| ts_reg_nat | fecha_nac |
| ts_reg_ope | grupo |
| ts_grado_soc | oficial |
| ts_codigo_mr | comentario |
| ts_documento | retencion |
| ts_tipo_soc | fecha_mod |
| ts_zona | fecha_expira |
| ts_nombre_completo | sector |
| ts_proposito | ciudad_nac |
| ts_discapacidad | nivel_estudio |
| ts_tipo_discapacidad | tipo_vivienda |
| ts_ced_discapacidad | calif_cliente |
| ts_nivel_egresos | tipo_vinculacion |
| ts_ifi | s_nombre |
| ts_asfi | c_apellido |
| ts_path_foto | secuen_alterno |
| ts_nit | nit |
| ts_nit_venc | pais_nac |
| ts_cod_alterno | provincia_nac |
| ts_oficina | naturalizado |
| ts_af | forma_migratoria |
| ts_aplica_mora | nro_extranjero |
| ts_canal_extracto | calle_orig |
| ts_carg_pub | exterior_orig |
| ts_cliente_preferencial | estado_orig |
| ts_debito_aut | pais_nac_c |
| ts_des_cta_afi | naturalizado_c |
| ts_desc_larga | forma_mig_c |
| ts_dinero | numero_ext_c |
| ts_dispersion_fondos | tipo_iden_c |
| ts_secuencial | numero_iden_c |
| ts_tipo_transaccion | localidad |

### ts_persona_sec

Transacciones de servicio: 172000, 172003, 172004, 172005, 172045, 172006

| Campo Vista | Campo Tabla |
| --- | --- |
| ts_secuencial | secuencia |
| ts_tipo_transaccion | tipo_transaccion |
| ts_clase | clase |
| ts_fecha | fecha |
| ts_hora | hora |
| ts_usuario | usuario |
| ts_terminal | terminal |
| ts_srv | srv |
| ts_lsrv | lsrv |
| ts_ente | persona |
| ts_nombre | nombre |
| ts_p_apellido | p_apellido |
| ts_s_apellido | s_apellido |
| ts_ingre | ingre |
| ts_num_poliza | id_tutor |
| ts_desc_seguro | nombre_tutor |
| ts_nacional | bloquear |
| ts_bienes | bienes |
| ts_garantia | verificado |
| ts_estado | fecha_verif |
| ts_codigocat | estado_ea |
| ts_toperacion | menor_edad |
| ts_observaciones | conocido_como |
| ts_estatus | cliente_planilla |
| ts_sigla | cod_risk |
| ts_abreviatura | sector_eco |
| ts_reg_nat | actividad_ea |
| ts_reg_ope | lin_neg |
| ts_grado_soc | seg_neg |
| ts_codigo_mr | remp_legal |
| ts_documento | apoderado_legal |
| ts_tipo_soc | fuente_ing |
| ts_zona | act_prin |
| ts_nombre_completo | detalle |
| ts_proposito | cat_aml |
| ts_discapacidad | discapacidad |
| ts_tipo_discapacidad | tipo_discapacidad |
| ts_ced_discapacidad | ced_discapacidad |
| ts_nivel_egresos | nivel_egresos |
| ts_ifi | ifi |
| ts_asfi | asfi |
| ts_path_foto | path_foto |
| ts_nit | nit |
| ts_nit_venc | nit_vencimiento |
| ts_cod_alterno | secuen_alterno2 |
| ts_oficina | oficina |
| ts_af | ejerce_control |
| ts_aplica_mora | fatca |
| ts_canal_extracto | crs |
| ts_carg_pub | s_inversion_ifi |
| ts_cliente_preferencial | s_inversion |
| ts_debito_aut | ifid |
| ts_des_cta_afi | c_merc_valor |
| ts_desc_larga | c_nombre_merc_valor |
| ts_dinero | ong_sfl |
| ts_dispersion_fondos | ifi_np |
| ts_secuencial | secuencia |

### ts_productos_negocio

| Campo Vista | Campo Tabla |
| --- | --- |
| tipo_transaccion | pn_tipo_transaccion |
| clase | pn_clase |
| secuencial | on_secuencial |
| table | pn_tabla |
| af  | pn_operacion |
| ente | pn_cliente_id |
| cod_alterno | pn_negocio_codigo |
| ciudad | pn_producto_codigo |
| nom_empresa | pn_producto |
| nro | pn_inventario_total |
| libro | pn_ventas_total |
| egresos | pn_precio_compra |
| ingresos | pn_precio_venta |

### ts_ref_personal

Transacciones de servicio: 172076, 172077, 172078

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | secuencial |
| tipo_transaccion | tipo_transaccion |
| Clase | clase |
| Fecha | fecha |
| Usuario | usuario |
| Terminal | terminal |
| Srv | srv |
| Lsrv | lsrv |
| Ente | persona |
| Tabla | referencia |
| Nombre | nombre |
| p_apellido | p_apellido |
| s_apellido | s_apellido |
| Direc | direccion |
| telefono_1 | telefono_d |
| telefono_2 | telefono_e |
| telefono_3 | telefono_o |
| Tipo | parentesco |
| Posicion | vigencia |
| descrip_ref_per | descripcion |
| Dinero | verificacion |
| Sector | departamento |
| tipo_soc | ciudad |
| Zona | barrio |
| Calle | calle |
| Nro | numero |
| Colonia | colina |
| Localidad | localidad |
| Municipio | municipio |
| Estado | estado |
| Codpostal | codpostal |
| pais1 | pais |
| tiempo_conocido | tiempo |
| Rep | correo |

### ts_relacion

Transacciones de servicio: 172064, 172065, 172066

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | secuencial |
| tipo_transaccion | tipo_transaccion |
| Clase | clase |
| Fecha | fecha |
| Usuario | usuario |
| Terminal | terminal |
| Srv | srv |
| Lsrv | lsrv |
| Codigo | relacion |
| descripcion | descripcion |
| Izquierda | izquierda |
| derecha | derecha |
| vinculacion | vinculacion |
| tipo_vinculacion | tipo_vinculacion |

### ts_instancia

Transacciones de servicio: 172029, 172030

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| clase | ts_clase |
| fecha | ts_fecha |
| usuario | ts_usuario |
| terminal | ts_terminal |
| srv | ts_srv |
| lsrv | ts_lsrv |
| relacion | ts_codigo |
| izquierda | ts_izquierda |
| derecha | ts_derecha |
| lado | ts_valor |
| fecha_relacion | ts_fec_inicio |

### ts_telefono

Transacciones de servicio: 172031, 172032, 172034

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | secuencial |
| cod_alterno | alterno |
| tipo_transaccion | tipo_transaccion |
| clase | clase |
| fecha | fecha |
| hora | hora |
| usuario | usuario |
| terminal | terminal |
| srv | srv |
| lsrv | lsrv |
| ente | ente |
| direccion | direccion |
| codigo | telefono |
| valor | valor |
| tipo | tipo |
| doc_validado | cobro |
| promotor | codarea |
| oficina | oficina |

### ts_mala_ref

Transacciones de servicio: 172139, 172140

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | secuencial |
| tipo_transaccion | tipo_transaccion |
| clase | clase |
| fecha | fecha |
| user | usuario |
| terminal | terminal |
| srv | srv |
| lsrv | lsrv |
| ente | ente |
| referido | mala_ref |
| categoria | treferencia |
| fecha_reg | fecha_registro |
| descripcion | observacion |
| login | login |

### ts_tipo_documento

Transacciones de servicio: 172148, 172149

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | secuencial |
| tipo_transaccion | tipo_transaccion |
| clase | clase |
| fecha | fecha |
| hora | hora |
| oficina | oficina_s |
| usuario | usuario |
| terminal | terminal_s |
| srv | srv |
| lsrv | lsrv |
| codigocat | codigo |
| descripcion | descripcion |
| camara | mascara |
| tipo | tipooper |
| rep_seuperban | aperrapida |
| nacionalidad | nacionalidad |
| doc_validado | digito |
| estado | estado |
| escritura | desc_corta |
| dinero | compuesto |
| num_cargas | nro_compuesto |
| nivel | adicional |
| garantia | creacion |
| mandat | habilitado_mis |
| tipo_dp | habilitado_usu |
| ingre | prefijo |
| ntrandeb | subfijo |

### ts_cia_liquidacion

Transacciones de servicio: 172150

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | secuencial |
| tipo_transaccion | tipo_transaccion |
| clase | clase |
| fecha | fecha |
| usuario | usuario |
| terminal | terminal |
| srv | srv |
| lsrv | lsrv |
| ente | codigo |
| nombre | nombre |
| tipo | tipo |
| sospechoso | problema |
| descripcion | referencia |
| cedruc | ced_ruc |
| fecha_emision | fecha_reg |

### ts_adicion_ente

Transacciones de servicio: 172184, 172185, 172186

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | secuencial |
| tipo_transaccion | tipo_transaccion |
| clase | clase |
| fecha | fecha |
| usuario | usuario |
| terminal | terminal |
| srv | srv |
| lsrv | lsrv |
| ente | ente |
| nomina | dato |
| descripcion | valor |
| codigo | sec_correccion |

### ts_referencia

Transacciones de servicio: 172189, 172190, 172191, 172192

| Campo Vista | Campo Tabla |
| --- | --- |
| secuencial | secuencial |
| tipo_transaccion | tipo_transaccion |
| clase | clase |
| fecha | fecha |
| usuario | usuario |
| terminal | terminal |
| srv | srv |
| lsrv | lsrv |
| ente | ente |
| referencias_dom | referencia |
| tipo | tipo |
| tipo_producto | tipo_cifras |
| egresos | numero_cifras |
| calificacion | calificacion |
| verificado | verificacion |
| fecha_verificacion | fecha_ver |
| inss | institucion |
| nombre_empresa | banco |
| cobertura | cuenta |
| fecha_registro | fecha_registro |
| fecha_modificacion | fecha_modificacion |
| estado | vigencia |
| observacion | observacion |
| fecha_ingreso | fecha_ingr_en_inst |
| toperacion | toperacion |
| tclase | tclase |
| fecha_ingreso | fec_inicio |
| fecha_exp | fec_vencimiento |
| Estatus | estatus |
| fecha_emision | fecha_apert |

### ts_trabajo

Transacciones de servicio: 181, 182, 1230

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| Ente | ts_ente |
| Trabajo | ts_tabla |
| Empresa | ts_empresa |
| Cargo | ts_nombre |
| Moneda | ts_secuencia |
| Sueldo | ts_ingresos |
| Tipo | ts_tipo |
| Verificado | ts_posicion |
| Vigencia | ts_tipo_dp |
| fecha_ingreso | ts_fecha_nac |
| fecha_salida | ts_fecha_reg |
| fecha_modificacion | ts_fecha_modificacion |
| fecha_registro | ts_fecha_registro |
| fecha_verificacion | ts_fec_inicio |
| nom_empresa | ts_nom_empresa |

### ts_listas_negras

Transacciones de servicio: 172218, 172219, 172222

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| ne_id_verificacion | ts_id_verificacion |
| ne_coincidencia | ts_coincidencia |
| ne_nombre | ts_nombre_completo |
| ne_apellido | ts_desc_larga |
| ne_tipo_persona | ts_tipo_dp |
| ne_codigo_cliente | ts_codigo |
| ne_nro_proceso | ts_nro |
| ne_justificacion | ts_observacion |
| ne_estado_resolucion | ts_estatus |
| ne_fecha_resolucion | ts_fecha |
| ne_nro_aml | ts_otro_tipo |

### ts_identificaciones_adicionales

Transacciones de servicio: 172196

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| ente | ts_ente |
| tipo_ident | ts_ident_tipo_c |
| num_ident | ts_ident_num_c |

### ts_telefono_ref

Transacciones de servicio: 172197

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| ente | ts_ente |
| referencia | ts_telefono_ref |
| Tipo_tel | ts_tipo |
| pais | ts_pais |
| area | ts_valor |
| Num_telefono | ts_telefono |
| telefono | ts_codigo |
| Sec_ref | ts_prefijo |

### ts_indice_pob_preg

Transacciones de servicio: 172223

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| num_pregunta | ts_cod_alterno |
| pregunta | ts_licencia |
| descripcion | ts_mensaje |
| estado | ts_categoria |
| usuario_crea | ts_user |
| fecha_crea | ts_fec_inicio |
| usuario_mod | ts_usuario |
| fecha_mod | ts_fec_vencimiento |

### ts_indice_pob_respuesta

Transacciones de servicio: 172224

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| num_pregunta | ts_cod_alterno |
| num_respuesta | ts_libro |
| respuesta | ts_mensaje |
| score | ts_lugar_doc |
| estado | ts_categoria |
| usuario_crea | ts_user |
| fecha_crea | ts_fec_inicio |
| usuario_mod | ts_usuario |
| fecha_mod | ts_fec_vencimiento |

### ts_ppi_ente

Transacciones de servicio: 172225

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| ente | ts_ente |
| fecha_ini | ts_fec_inicio |
| fecha_fin | ts_fec_vencimiento |
| usuario_ppi | ts_user |
| fecha_ing | ts_fecha_emision |
| fecha_mod | ts_fecha_exp |

### ts_det_ppi_ente

Transacciones de servicio: 172226

| Campo Vista | Campo Tabla |
| --- | --- |
| Secuencial | ts_secuencial |
| tipo_transaccion | ts_tipo_transaccion |
| Clase | ts_clase |
| Fecha | ts_fecha |
| Usuario | ts_usuario |
| Terminal | ts_terminal |
| Srv | ts_srv |
| Lsrv | ts_lsrv |
| ente | ts_ente |
| num_pregunta | ts_nro |
| num_respuesta | ts_rango_max |
| score | ts_secuencial1 |

## Índices por Clave Primaria

Descripción de los índices por clave primaria definidos para las tablas del sistema Clientes.

| Tipo de Índice |     | FOREIGN KEY |     |
| --- |     | --- |     | --- | --- |
| **No** | **Índice** | **Tabla** | **Columnas Combinadas** |
|     | cl_sector_economico_Key | cl_sector_economico | se_codigo |
|     | cl_subsector_ec_Key | cl_subsector_ec | se_codigo |
|     | cl_mala_ref_Key | cl_mala_ref | mr_ente<br><br>mr_treferencia |
|     | cl_direccion_geo_Key | cl_direccion_geo | dg_ente<br><br>dg_tipo<br><br>dg_direccion<br><br>dg_secuancial |
|     | cl_asfi_key | cl_asfi | af_codigo<br><br>af_fecha_reporte |
|     | cl_mercado_Key | cl_mercado | me_codigo<br><br>me_nomlar |
|     | cl_validacion_listas_externas_Key | cl_validacion_listas_externas | rle_ente<br><br>rle_rol<br><br>rle_producto<br><br>rle_cuenta<br><br>rle_proceso |
|     | cl_tipo_identificacion_Key | cl_tipo_identificacion | ti_tipo_cliente<br><br>ti_tipo_documento<br><br>ti_nacionalidad<br><br>ti_tipo_residencia<br><br>ti_codigo |
|     | cl_registro_identificacion_Key | cl_registro_identificacion | ri_ente<br><br>ri_tipo_iden<br><br>ri_identificacion<br><br>ri_fecha_act |
|     | cl_ref_personal_Key | cl_ref_personal | rp_persona<br><br>rp_referencia |
|     | cl_instancia_Key | cl_instancia | in_relacion<br><br>in_ente_i<br><br>in_ente_d |
|     | cl_his_ejecutivo_Key | cl_his_ejecutivo | ej_ente<br><br>ej_funcionario<br><br>ej_fecha_registro |
|     | cl_hijo_Key | cl_hijos | hi_ente<br><br>hi_hijo |
|     | cl_grupo_Key | cl_grupo | gr_grupo |
|     | cl_relacion_Key | cl_relacion | re_relacion |
|     | cl_telefono_Key | cl_telefono | te_ente<br><br>te_direccion<br><br>te_secuencial |
|     | cl_tipo_documento_Key | cl_tipo_documento | td_codigo |
|     | cl_com_liquidacion_Key | cl_com_liquidacion | cl_codigo |
|     | cl_actividad_principal_Key | cl_actividad_principal | ap_codigo<br><br>ap_descripcion |
|     | cl_mod_estados_Key | cl_mod_estados | me_sec<br><br>me_ente<br><br>me_fecha |
|     | cl_subsector_ec_Key | cl_subsector_ec | se_codigo |
|     | cl_actividad_ec_Key | cl_actividad_ec | ac_codigo<br><br>ac_descripcion |
|     | cl_at_relacion_Key | cl_at_relacion | ar_relacion<br><br>ar_atributo |
|     | cl_cliente_Key | cl_cliente | cl_cliente<br><br>cl_det_producto |
|     | cl_cliente_grupo_Key | cl_cliente_grupo | cg_grupo<br><br>cg_ente |
|     | cl_det_producto_Key | cl_det_producto | dp_det_producto |
|     | cl_ejecutivo_Key | cl_ejecutivo | ej_ente |
|     | cl_direccion_Key | cl_direccion | di_ente<br><br>di_direccion |
|     | cl_direccion_fiscal_Key | cl_direccion_fiscal | df_ente<br><br>df_pais |
|     | cl_ente_Key | cl_ente | en_ente |
|     | cl_ente_Key2 | cl_ente | en_tipo_ced<br><br>en_ced_ruc |
|     | cl_calificacion_srv_Key | cl_calificacion_srv | cs_fecha<br><br>cs_cliente |
|     | cl_control_empresas_rfe_Key | cl_control_empresas_rfe | ce_ente<br><br>ce_compania |
|     | cl_documento_actividad_Key | cl_documento_actividad | da_tipo<br><br>da_producto<br><br>da_codigo<br><br>da_actividad |
|     | cl_documento_parametro_Key | cl_documento_parametro | dp_tipo<br><br>dp_producto<br><br>dp_codigo |
|     | cl_alianza_Key | cl_alianza | al_alianza |
|     | cl_alianza_banco_Key | cl_alianza_banco | ab_alianza<br><br>ab_banco<br><br>ab_cuenta |
|     | cl_analisis_negocio_Key | cl_analisis_negocio | an_cliente_id<br><br>an_negocio_codigo |
|     | cl_ente_aux_Key | cl_ente_aux | ea_ente |
|     | cl_negocio_cliente_Key | cl_negocio_cliente | nc_ente<br><br>nc_codigo |
|     | cl_notificacion_general_Key | cl_notificacion_general | ng_codigo |
|     | cl_ns_generales_estado_Key | cl_ns_generales_estado | nge_codigo |
|     | cl_pais_id_fiscal_Key | cl_pais_id_fiscal | pf_ente<br><br>pf_pais |
|     | cl_productos_negocio_Key | cl_productos_negocio | pn_cliente<br><br>pn_negocio_codigo<br><br>pn_producto |
|     | cl_productos_negocio_Key2 | cl_productos_negocio | pn_id |
|     | cl_seccion_validar_Key | cl_seccion_validar | sv_ente<br><br>sv_seccion |
|     | cl_info_trn_riesgo_Key | cl_info_trn_riesgo | rle_ente<br><br>rle_rol<br><br>rle_producto<br><br>rle_cuenta<br><br>rle_proceso |
|     | cl_ident_ente_Key | cl_ident_ente | ie_tipo_doc<br><br>ie_numero |
|     | cl_listas_negras_ref | cl_listas_negras_ref | ne_id_verificacion |

## Índices por Clave Foránea

Descripción de los índices por clave foránea definidos para las tablas del sistema Clientes.

| Tipo de Índice |     | UNIQUE |     |
| --- |     | --- |     | --- | --- |
| **No** | **Índice** | **Tabla** | **Columnas Combinadas** |
|     | cl_dato_adicion_idx1 | cl_dato_adicion | da_codigo |
|     | cl_dadicion_ente_idx1 | cl_dadicion_ente | da_ente<br><br>da_dato |
|     | cl_mercado_idx1 | cl_mercado | me_ced_ruc |
|     | cl_mercado_idx2 | cl_mercado | me_nomlar<br><br>me_codigo |
|     | cl_registro_identificacion_idx1 | cl_registro_identificacion | ri_ente |
|     | cl_registro_identificacion_idx2 | cl_registro_identificacion | ri_identificacion |
|     | cl_registro_identificacion_idx3 | cl_registro_identificacion | ri_fecha_act |
|     | cl_ref_personal_idx1 | cl_ref_personal | rp_parentesco |
|     | cl_registro_cambio_idx2 | cl_registro_cambio | campo |
|     | cl_instancia_idx1 | cl_instancia | in_ente_d<br><br>in_ente_i |
|     | cl_instancia_idx2 | cl_instancia | in_ente_i<br><br>in_ente_d |
|     | cl_refinh_idx1 | cl_refinh | in_entid<br><br>in_codigo |
|     | cl_refinh_idx2 | cl_refinh | in_otroid<br><br>in_nombre<br><br>in_fecha_ref<br><br>in_origen<br><br>in_nomlar<br><br>in_estado |
|     | cl_refinh_idx3 | cl_refinh | in_nomlar<br><br>in_codigo |
|     | cl_telefono_idx1 | cl_telefono | te_ente  <br>te_tipo_telefono |
|     | cl_telefono_idx2 | cl_telefono | te_valor |
|     | cl_listas_negras_idx1 | cl_listas_negras | pe_lista<br><br>pe_nombre<br><br>pe_paterno<br><br>pe_materno |
|     | cl_listas_negras_idx2 | cl_listas_negras | pe_lista<br><br>pe_curp |
|     | cl_listas_negras_idx3 | cl_listas_negras | pe_lista<br><br>pe_rfc |
|     | cl_listas_negras_idx4 | cl_listas_negras | pe_lista<br><br>pe_fecha_nacimiento<br><br>pe_nombre<br><br>pe_paterno<br><br>pe_materno |
|     | cl_actualiza_idx1 | cl_actualiza | ac_ente<br><br>ac_fecha |
|     | cl_actualiza_idx2 | cl_actualiza | ac_user<br><br>ac_fecha |
|     | cl_actualiza_idx3 | cl_actualiza | ac_fecha |
|     | cl_det_producto_idx2 | cl_det_prodcuto | dp_cuenta |
|     | cl_det_producto_idx3 | cl_det_prodcuto | dp_producto<br><br>dp_cuenta |
|     | cl_ejecutivo_idx1 | cl_ejecutivo | ej_ente |
|     | cl_direccion_idx1 | cl_direccion | di_tipo<br><br>di_ciudad<br><br>di_parroquia<br><br>di_oficina |
|     | cl_direccion_idx2 | cl_direccion | di_ciudad<br><br>di_parroquia |
|     | cl_ente_idx1 | cl_ente | en_grupo<br><br>en_ente<br><br>en_ced_ruc<br><br>en_tipo_ced |
|     | cl_ente_idx2 | cl_ente | en_oficina<br><br>en_fecha_crea<br><br>en_filial<br><br>en_cliente |
|     | cl_ente_idx3 | cl_ente | p_p_apellido<br><br>p_s_apellido<br><br>en_nobre |
|     | cl_ente_idx4 | cl_ente | en_nomlar |
|     | cl_ente_idx5 | cl_ente | en_subtipo |
|     | cl_ente_idx6 | cl_ente | en_ced_ruc |
|     | cl_his_relacion_idx1 | cl_his_relacion | hr_ente_i<br><br>hr_ente_d |
|     | cl_actividad_principal_idx1 | cl_actividad_principal | ap_codigo |
|     | cl_ente_aux_idx1 | cl_ente_aux | ea_ente<br><br>ea_estado |
|     | cl_alertas_riesgo_idx1 | cl_alertas_riesgo | ar_ente<br><br>ar_etiqueta |
|     | cl_analisis_negocio_idx1 | cl_analisis_negocio | an_cliente_id |
|     | cl_documento_digitalizado_idx1 | cl_documento_digitalizado | dd_inst_proceso<br><br>dd_cliente<br><br>dd_grupo<br><br>dd_codigo<br><br>dd_poducto |
|     | cl_negocio_cliente_idx1 | cl_negocio_cliente | nc_negocio, nc_ente |