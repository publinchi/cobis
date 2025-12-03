Historia de Cambios

| Versión | Fecha | Autor | Revisado | Aprobado | Descripción |
| --- | --- | --- | --- | --- | --- |
| 1.0.0 | 23-Ago-23 | KDR |     |     | Emisión inicial, Adaptación a plantilla Cobis-Topaz |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |
|     |     |     |     |     |     |

© 2025 Cobiscorp

RESERVADOS TODOS LOS DERECHOS

La información que Cobiscorp proporciona a través de este documento tienen el carácter de referencial y/o informativo, por lo que Cobiscorp podría modificar esta información en cualquier momento y sin previo aviso.

Es responsabilidad del tenor de este documento el cumplimiento de todas las leyes de derechos de autor aplicables. Sin que por ello queden limitados los derechos de autor, ninguna parte de este documento puede ser reproducida, almacenada o introducida en un sistema de recuperación, o transmitida de ninguna forma, ni por ningún medio (ya sea electrónico, mecánico, por fotocopia, grabación o de otra manera) con ningún propósito, sin la previa autorización por escrito de Cobiscorp.

Cobiscorp puede ser titular de patentes, solicitudes de patentes, marcas, derechos de autor, y otros derechos de propiedad intelectual sobre los contenidos de este documento. El suministro de este documento no le otorga ninguna licencia sobre estas patentes, marcas, derechos de autor, u otros derechos de propiedad intelectual, a menos que ello se prevea en un contrato por escrito de licencia de Cobiscorp.

Cobiscorp, COBIS y Cooperative Open Banking Information System son marcas registradas de Cobiscorp.

Otros nombres de compañías y productos mencionados en este documento, pueden ser marcas comerciales o marcas registradas por sus respectivos propietarios.

Tabla de Contenido

[COBIS GARANTÍAS 1](#_Toc143680504)

[DICCIONARIO DE DATOS 1](#_Toc143680505)

[1 Introducción 4](#_Toc143680506)

[2 Diccionario de Datos 4](#_Toc143680507)

[2.1 Tablas cob_custodia 4](#_Toc143680508)

[cu_almacenera 4](#_Toc143680509)

[cu_cambios_estado 4](#_Toc143680510)

[cu_cliente_garantia 5](#_Toc143680511)

[cu_cliente_garantia_tmp 6](#_Toc143680512)

[cu_custodia 7](#_Toc143680513)

[cu_det_trn 11](#_Toc143680514)

[cu_errorlog 12](#_Toc143680515)

[cu_estados_garantia 12](#_Toc143680516)

[cu_garantia_operacion 12](#_Toc143680517)

[cu_gastos 13](#_Toc143680518)

[cu_inspeccion 14](#_Toc143680519)

[cu_inspector 15](#_Toc143680520)

[cu_item 16](#_Toc143680521)

[cu_item_custodia 16](#_Toc143680522)

[cu_poliza 17](#_Toc143680523)

[cu_por_inspeccionar 18](#_Toc143680524)

[cu_recuperacion 19](#_Toc143680525)

[cu_secuenciales 20](#_Toc143680526)

[cu_seqnos 20](#_Toc143680527)

[cu_tipo_custodia 20](#_Toc143680528)

[cu_tran_conta 21](#_Toc143680529)

[cu_tran_cust 22](#_Toc143680530)

[cu_transaccion 23](#_Toc143680531)

[2.2 Tablas de Transacciones de servicio 23](#_Toc143680532)

[cu_tran_servicio 24](#_Toc143680533)

[2.3 INDICES POR CLAVE PRIMARIA 30](#_Toc143680534)

[2.4 INDICES POR CLAVE FORANEA 31](#_Toc143680535)

DICCIONARIO DE DATOS

Tablas Garantías

# Introducción

En este diccionario se encuentran enumeradas las tablas que componen el módulo junto con una pequeña descripción de su uso, tambíen se muestran los campos que tiene cada tabla y se describe su uso.

# Diccionario de Datos

## Tablas cob_custodia

A continuación se muestra el diccionario de datos de este módulo.

### cu_almacenera

Almacena los depósitos y almacenes donde se ubica las mercancías o bienes sobre los cuales constituimos la garantía.

| **Nombre del campo** | **Tipo de dato** | **LONG** | **Car.de dato** | **Descripción** |
| --- | --- | --- | --- | --- |
| al_almacenera | Smallint | 2   | NOT NULL | Código de la almacenera |
| al_nombre | descripcion | 64  | NULL | Nombre de la almacenera. |
| al_direccion | descripcion | 64  | NULL | Dirección de ubicación. |
| al_telefono | Varchar | 20  | NULL | Teléfono de la dirección. |
| al_estado | Char | 1   | NOT NULL | Estado de la almacenera.<br><br>V = Vigente<br><br>C= Cerrada |

### cu_cambios_estado

Registra los cambios de estado que tendrá una garantía.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ce_estado_ini | Char | 1   | NOT NULL | Código del estado inicial.<br><br>F= Vigente futuros créditos<br><br>V= Vigente con obligación<br><br>X= Vigente por cancelar<br><br>C= Cancelada<br><br>P= Propuesta<br><br>A= Anulada |
| ce_estado_fin | Char | 1   | NOT NULL | Código del estado final.<br><br>F= Vigente futuros créditos<br><br>V= Vigente con obligación<br><br>X= Vigente por cancelar<br><br>C= Cancelada<br><br>P= Propuesta<br><br>A= Anulada |
| ce_contabiliza | Char | 1   | NOT NULL | Si contabiliza el movimiento.<br><br>S= Se contabiliza<br><br>N= No se contabiliza |
| ce_tran | catalogo | 10  | NOT NULL | Código de la transacción |
| ce_tipo | Char | 1   | NULL | C= Contabilizada<br><br>I= Ingresada<br><br>R= Reversada |

### cu_cliente_garantia

Almacena los clientes asociados a la garantía y su rol (propietarios y amparados).

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| cg_filial | Tinyint | 1   | NOT NULL | Código de filial. |
| cg_sucursal | Smallint | 2   | NOT NULL | Código de la oficina o sucursal. |
| cg_tipo_cust | descripcion | 64  | NOT NULL | Código del tipo de custodia. |
| cg_custodia | Int | 4   | NOT NULL | Código de la custodia. |
| cg_ente | Int | 4   | NOT NULL | Código del cliente. |
| cg_principal | Char | 1   | NULL | Indicador si es el cliente principal.<br><br>S= Principal<br><br>N= No es principal |
| cg_codigo_externo | Varchar | 64  | NOT NULL | Código externo para la garantía. |
| cg_oficial | int | 4   | NULL | Código del oficial. |
| cg_tipo_garante | catalogo | 10  | NULL | Columna en desuso |
| cg_nombre | descripcion | 64  | NULL | Nombre del cliente |

### cu_cliente_garantia_tmp

Tabla temporal que almacena los clientes asociados a la garantía y su rol (propietarios y amparados).

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripción** |
| --- | --- | --- | --- | --- |
| cg_ssn | Int | 4   | NOT NULL | Secuencial de la sesión. |
| cg_filial | Tinyint | 1   | NOT NULL | Código de filial. |
| cg_sucursal | Smallint | 2   | NOT NULL | Código de la oficina o sucursal. |
| cg_tipo_cust | descripcion | 64  | NOT NULL | Código del tipo de custodia. |
| cg_custodia | Int | 4   | NULL | Código de la custodia. |
| cg_ente | Int | 4   | NOT NULL | Código del cliente. |
| cg_principal | Char | 1   | NULL | Indicador si es el cliente principal.<br><br>S= Principal<br><br>N= No es principal |
| cg_oficial | Int | 4   | NULL | Código del oficial. |
| cg_tipo_garante | catalogo | 10  | NULL | Columna en desuso |
| cg_nombre | descripcion | 64  | NULL | Nombre del cliente |

### cu_custodia

El maestro de garantías registra las garantías administradas en el sistema.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| cu_filial | Tinyint | 1   | NOT NULL | Código de la filial de la garantía. |
| cu_sucursal | Smallint | 2   | NOT NULL | Sucursal a la que pertenece la garantía. |
| cu_tipo | descripcion | 64  | NOT NULL | Tipo de garantía. |
| cu_custodia | Int | 4   | NOT NULL | Código de custodia |
| cu_propuesta | int | 4   | NULL | Codigo de propuesta |
| cu_estado | catalogo | 10  | NULL | Estado de custodia (del catálogo cu_est_custodia) |
| cu_fecha_ingreso | Datetime | 8   | NULL | Fecha de ingreso |
| cu_valor_inicial | Money | 8   | NULL | Valor inicial |
| cu_valor_actual | Money | 8   | NULL | Valor actual |
| cu_moneda | Tinyint | 1   | NULL | Moneda de la garantía |
| cu_garante | Int | 4   | NULL | Código del garante. (En Garantías de Tipo Garantía Personal) |
| cu_instruccion | Varchar | 255 | NULL | Texto de observación de la situación de la garantía |
| cu_descripcion | Varchar | 255 | NULL | Descripción de la custodia |
| cu_poliza | varchar | 20  | NULL | Codigo de póliza. (No se utiliza en esta versión) |
| cu_inspeccionar | Char | 1   | NULL | Indicador de inspección.<br><br>S= Necesita inspección<br><br>N= No necesita inspección |
| cu_motivo_noinsp | catalogo | 10  | NULL | Motivo de no inspección (Del catálogo cu_motivo_noinspeccion). |
| cu_suficiencia_legal | char | 1   | NULL | Indicador de suficiencia legal<br><br>S = Suficiente<br><br>N = No Suficiente<br><br>O = No Aplica<br><br>(No se utiliza en esta versión) |
| cu_fuente_valor | catalogo | 10  | NULL | Indica la razón o fuente del valor de la garantía (cu_fuente_valor): avalúo, factura, precio de mercado, etc. |
| cu_situacion | char | 1   | NULL | Situacion de la garantía. Campo en desuso. |
| cu_almacenera | Smallint | 2   | NULL | Código de almacenera, si la garantía es física y necesita estar en ese espacio físico. |
| cu_aseguradora | varchar | 20  | NULL | Nombre de la aseguradora. (No se utiliza en esta versión) |
| cu_cta_inspeccion | Varchar | 24  | NULL | Número de Cuenta de depósito de valor cancelados a inspectores, (No se utiliza en esta versión) |
| cu_tipo_cta | Varchar | 8   | NULL | Tipo de cuenta de depósito. AHO: Ahorros<br><br>CTE: Corriente<br><br>(No se utiliza en esta versión) |
| cu_direccion_prenda | descripcion | 64  | NULL | Dirección de la prenda |
| cu_ciudad_prenda | descripcion | 64  | NULL | Ciudad de la prenda |
| cu_telefono_prenda | Varchar | 20  | NULL | Teléfono donde se encuentra la prenda. |
| cu_mex_prx_inspec | tinyint | 1   | NULL | Columna en desuso |
| cu_fecha_modif | Datetime | 8   | NULL | Fecha de modificación. |
| cu_fecha_const | Datetime | 8   | NULL | Fecha de constitución de la garantía |
| cu_porcentaje_valor | float | 8   |     | Porcentaje de valor de la custodia. Campo en desuso. |
| cu_periodicidad | catalogo | 10  | NULL | Periodicidad de inspección (Del catálogo cu_des_periodicidad)<br><br>(No se utiliza en esta versión) |
| cu_depositario | Varchar | 255 | NULL | Descripción del depositario. Campo informativo, no se usa en esta version |
| cu_posee_poliza | Char | 1   | NULL | Indicador si posee póliza.<br><br>S= Posee póliza<br><br>N= No posee póliza<br><br>Campo no se usa en esta versión |
| cu_nro_inspecciones | Tinyint | 1   | NULL | Número de inspecciones realizadas (Registradas en cob_custodia..cu_inspeccion). |
| cu_intervalo | Tinyint | 1   | NULL | Número de días del período |
| cu_cobranza_judicial | Char | 1   | NULL | Garantía en cobranza judicial<br><br>S= En cobranza<br><br>N= No está en cobranza |
| cu_fecha_retiro | datetime | 8   | NULL | Fecha retiro de la custodia. Se usa si cu_cobranza_judicial = "S" |
| cu_fecha_devolucion | datetime | 8   | NULL | Fecha devolución de la custodia. Se usa si cu_cobranza_judicial = "S" |
| cu_fecha_modificacion | Datetime | 8   | NULL | Fecha de actualización. |
| cu_usuario_crea | descripcion | 64  | NULL | Usuario de creación de la custodia. |
| cu_usuario_modifica | descripcion | 64  | NULL | Usuario de modificación de la custodia. |
| cu_estado_poliza | Char | 1   | NULL | Código de estado de la póliza.<br><br>V= Vigente<br><br>E= Excepcional<br><br>C= Cerrada<br><br>No se usa en esta version. |
| cu_cobrar_comision | char | 1   | NULL | Caracteristica de cobrar comisión. No se usa en este versión. |
| cu_cuenta_dpf | Varchar | 30  | NULL | Código compuesto de operación DPF pignorada por la garantía. |
| cu_codigo_externo | Varchar | 64  | NOT NULL | Código externo para la garantía. |
| cu_fecha_insp | Datetime | 8   | NULL | Fecha de inspección. |
| cu_abierta_cerrada | Char | 1   | NULL | Característica de abierta o cerrada<br><br>A= Abierta<br><br>C= Cerrada |
| cu_adecuada_noadec | Char | 1   | NULL | Característica de adecuada y no adecuada<br><br>S= Adecuada<br><br>N= No adecuada<br><br>O= No aplica |
| cu_propietario | Varchar | 64  | NULL | Descripción del propietario. (No se utiliza en esta versión) |
| cu_plazo_fijo | Varchar | 30  | NULL | Código compuesto de operación DPF pignorada por la garantía. |
| cu_monto_pfijo | money | 8   |     | Monto de plazo fijo de la custodia |
| cu_oficina | Smallint | 2   | NULL | Código de la oficina |
| cu_oficina_contabiliza | Smallint | 2   | NULL | Código de la oficina que realizara la contabilidad de la custodia. |
| cu_compartida | Char | 1   | NULL | Característica de compartida<br><br>S= Compartida<br><br>N= Sin compartir |
| cu_valor_compartida | Money | 8   | NULL | Valor compartido (Si cu_compartida = 'S') |
| cu_fecha_reg | Datetime | 8   | NOT NULL | Fecha de registro de la custodia. |
| cu_fecha_prox_insp | Datetime | 8   | NULL | Fecha de registro de la próxima inspección. |
| cu_fecha_vencimiento | datetime | 8   | NULL | Fecha de vencimiento de la custodia |
| cu_tipo_cca | catalogo | 10  | NULL | Tipo de cartera de la custodia. No se usa en esta version |
| cu_pais | smallint | 2   | NULL | Codigo de país |
| cu_provincia | smallint | 2   | NULL | Codigo de provincia |
| cu_canton | int | 4   | NULL | Codigo de canton |
| cu_fecha_avaluo | datetime | 8   | NULL | Fecha de avaluo de la custodia |
| cu_ubicacion | catalogo | 10  | NULL | Ubicación de la custodia.( No se usa en esta version) |
| cu_cuantia | char | 1   | NULL | No aplica en esta versión |
| cu_porcentaje_cobertura | float | 8   | NULL | Porcentaje de cobertura de la custodia. ( No se usa en esta version) |
| cu_agotada | char | 1   | NULL | Caracterisitca de agotamiento<br><br>S = Con agotamiento<br><br>N = Sin agotamiento<br><br>No se usa en esta version. |
| cu_clase_custodia | char | 1   | NULL | Clase de custodia. No se usa en esta version. |
| cu_ciudad_gar | int | 4   | NULL | Columna en desuso |
| cu_num_dcto | varchar | 13  | NULL | Columna en desuso |
| cu_clase_vehiculo | varchar | 10  | NULL | Columna en desuso |
| cu_clase_cartera | catalogo | 10  | NULL | Codigo de clase de cartera cuando se activa la garantía. |
| cu_autoriza | varchar | 25  | NULL | Código de autorización. No se usa en esta versión. |
| cu_cuenta_tipo | tinyint | 1   | NULL | Columna en desuso |
| cu_cuenta_hold | Varchar | 30  | NULL | Cuenta hold. No se usa en esta version. |
| cu_cuenta_tipo | Tinyint | 1   | NULL | Tipo de cuenta: ahorros 4, corriente 3. No se usa en esta version. |
| cu_id_bloqueo_cta | int | 4   | NULL | Codigo secuencial de bloqueo para levantamientos |
| cu_fondo_garantia | varchar | 2   | NULL | Columna en desuso |
| cu_valor_avaluo | money | 8   | NULL | Columna en desuso |
| cu_num_documento | varchar | 30  | NULL | Columna en desuso |
| cu_nemonico_cob | catalogo | 10  | NULL | Columna en desuso |

### cu_det_trn

Almacena los valores monetarios de cada transaccion.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| dtr_secuencial | Int | 4   | NOT NULL | Código de secuencial de la transacción. |
| dtr_codigo_externo | Varchar | 64  | NOT NULL | Código externo para la garantía. |
| dtr_codvalor | Int | 4   | NOT NULL | Código valor asociado a la transacción. |
| dtr_valor | Float | 8   | NOT NULL | Valor de la transacción. |
| dtr_clase_cartera | catalogo | 10  | NULL | Columna en desuso |
| dtr_calificacion | catalogo | 10  | NULL | Columna en desuso |

### cu_errorlog

Guarda el manejo de errores en los procesos automáticos.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** |     |
| --- | --- | --- | --- | --- |
| er_fecha_proc | Datetime | 8   | NULL | Fecha de proceso. |
| er_error | Int | 4   | NULL | Numero de error |
| er_usuario | login | 64  | NULL | Código de usuario. |
| er_tran | Int | 4   | NULL | Código de la transacción. |
| er_cuenta | Varchar | 64  | NULL | Numero de cuenta |
| er_descripcion | Varchar | 255 | NULL | Descripción de la garantía. |

### cu_estados_garantia

Almacena la información sobre el mantenimiento de los estados de la garantía.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCION** |
| --- | --- | --- | --- | --- |
| eg_estado | Char | 1   | NOT NULL | Código del estado de la garantía.<br><br>C= Cancelada<br><br>P= Propuesta<br><br>V= Vigente |
| eg_descripcion | descripcion | 64  | NOT NULL | Descripción del estado. |
| eg_codvalor | Int | 4   | NOT NULL | Código valor asociado al estado. |

### cu_garantia_operacion

Registra la relación entre garantía y la operación de cartera.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCION** |
| --- | --- | --- | --- | --- |
| go_filial | Tinyint | 1   | NOT NULL | Código de la filial. |
| go_sucursal | Smallint | 2   | NOT NULL | Código de la sucursal. |
| go_tipo_cust | descripcion | 64  | NOT NULL | Tipo de custodia. |
| go_custodia | Int | 4   | NOT NULL | Código numérico de la custodia. |
| go_operacion | cuenta | 24  | NULL | Código de la operación. |
| go_operacion_cartera | Int | 4   | NULL | Código de la operación en el modulo de cartera. |
| go_operacion_cobis | cuenta | 24  | NOT NULL | Código de la operación Cobis o el código en carácter de la operación. |
| go_fecha | Datetime | 8   | NULL | Fecha de la operación |
| go_codigo_externo | descripcion | 64  | NOT NULL | Código compuesto de la garantía |

### cu_gastos

Registra los gastos por inspecciones, avalúos o visitas a los bienes que se dejan en garantía y que se deberán cobrar al cliente.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| ga_filial | Tinyint | 1   | NOT NULL | Código de la filial. |
| ga_sucursal | Smallint | 2   | NOT NULL | Código de la sucursal. |
| ga_tipo_cust | descripcion | 64  | NOT NULL | Tipo de custodia. |
| ga_custodia | Int | 4   | NOT NULL | Código de la custodia. |
| ga_gastos | Smallint | 2   | NOT NULL | Secuencial del registro de gastos |
| ga_descripcion | Varchar | 64  | NULL | Descripción del gasto |
| ga_monto | Money | 8   | NULL | Valor del monto |
| ga_fecha | Datetime | 8   | NULL | Fecha de registro |
| ga_codigo_externo | Varchar | 64  | NOT NULL | Código compuesto de la garantía |
| ga_registrado | Char | 1   | NULL | Indica si está registrado<br><br>S= Registrado<br><br>N= Sin registrar |

### cu_inspeccion

Registra las inspecciones realizadas o por realizar a los bienes dejados en garantía.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| in_filial | Tinyint | 1   | NOT NULL | Código de la filial |
| in_sucursal | Smallint | 2   | NOT NULL | Código de la sucursal |
| in_tipo_cust | descripcion | 64  | NOT NULL | Tipo de custodia |
| in_custodia | Int | 4   | NOT NULL | Código de la custodia |
| in_fecha_insp | Datetime | 8   | NOT NULL | Fecha de inspección. |
| in_inspector | Tinyint | 1   | NULL | Código del inspector |
| in_estado | catalogo | 10  | NULL | Estado de la inspección<br><br>N= Normal.<br><br>R= Resistencia |
| in_factura | Varchar | 20  | NULL | Código de la factura. |
| in_valor_fact | Money | 8   | NULL | Valor de la factura |
| in_observaciones | Varchar | 255 | NULL | Observación del resultado de la inspección |
| in_instruccion | Varchar | 255 | NULL | Instrucción que deja el inspector |
| in_motivo | catalogo | 10  | NULL | Motivo de la inspección |
| in_valor_avaluo | Money | 8   | NULL | Valor del avalúo |
| in_estado_tramite | Char | 1   | NULL | Estado del trámite<br><br>S= Crédito automático<br><br>N= Crédito manual |
| in_codigo_externo | Varchar | 64  | NOT NULL | Código externo para la garantía. |
| in_registrado | Char | 1   | NULL | Indica si está registrado<br><br>S= Registrado<br><br>N= Sin registrar |

### cu_inspector

Almacena la información sobre mantenimiento de inspectores.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| is_inspector | Tinyint | 1   | NOT NULL | Código del inspector |
| is_cta_inspector | Varchar | 24  | NULL | Cuenta de depósito del inspector |
| is_nombre | descripcion | 64  | NULL | Nombre del inspector |
| is_especialidad | catalogo | 10  | NULL | Especialidad del inspector |
| is_direccion | descripcion | 64  | NULL | Dirección del inspector |
| is_telefono | Varchar | 20  | NULL | Teléfono del inspector |
| is_principal | descripcion | 64  | NULL | Dirección principal |
| is_cargo | descripcion | 64  | NULL | Cargo del inspector |
| is_cliente_inspec | Int | 4   | NULL | Código del inspector si es un cliente de la institución |
| is_tipo_cta | Varchar | 5   | NULL | Tipo de cuenta para depósito |

### cu_item

Registra los atributos específicos asociados a un tipo de garantía

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| it_tipo_custodia | Varchar | 64  | NOT NULL | Tipo de custodia |
| it_item | Tinyint | 1   | NOT NULL | Código ítem de la custodia |
| it_nombre | Varchar | 64  | NULL | Nombre del ítem |
| it_detalle | Varchar | 64  | NULL | Descripción del ítem |
| it_tipo_dato | Char | 1   | NOT NULL | Tipo de dato del ítem<br><br>I= Integer<br><br>F= Float<br><br>C= Char |
| it_mandatorio | Char | 1   | NULL | Indica si es mandatorio |
| It_factura | Char | 1   | NOT NULL | Campo en desuso en esta versión. |

### cu_item_custodia

Almacena los valores u atributos específicos de una garantía en particular.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ic_filial | Tinyint | 1   | NOT NULL | Código de la filial |
| ic_sucursal | Smallint | 2   | NOT NULL | Código de la sucursal |
| ic_tipo_cust | Varchar | 64  | NOT NULL | Tipo de custodia |
| ic_custodia | Int | 4   | NOT NULL | Código de la custodia |
| ic_item | Tinyint | 1   | NOT NULL | Código del ítem |
| ic_valor_item | Varchar | 64  | NULL | Valor del ítem |
| ic_secuencial | Smallint | 2   | NULL | Código del secuencial |
| ic_codigo_externo | Varchar | 64  | NOT NULL | Código externo para la garantía. |

### cu_poliza

Registra las pólizas de seguro que amparan los bienes registrados como garantías.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| po_poliza | Varchar | 40  | NULL | Código de la póliza |
| po_aseguradora | Varchar | 10  | NOT NULL | Código aseguradora |
| po_corredor | Smallint | 2   | NULL | Código del corredor |
| po_fvigencia_inicio | Datetime | 8   | NULL | Fecha de vigencia Inicio |
| po_fvigencia_fin | Datetime | 8   | NULL | Fecha de vigencia Fin |
| po_moneda | Tinyint | 1   | NULL | Código de la moneda |
| po_fendoso_fin | Datetime | 8   | NULL | Fecha de endoso final |
| po_monto_endoso | Money | 8   | NULL | Monto de endoso |
| po_monto_poliza | Money | 8   | NOT NULL | Monto de la póliza |
| po_estado_poliza | Varchar | 10  | NULL | Estado de la póliza  <br><br/>V= Vigente<br><br>E= Excepcional<br><br>C= Cerrada |
| po_descripcion | Varchar | 120 | NULL | Descripción de la póliza |
| po_codigo_externo | Varchar | 64  | NULL | Código compuesto de la garantía |
| po_fecha_endozo | Datetime | 8   | NULL | Fecha en la que se realiza el endoso |
| po_cobertura | Catalogo | 10  | NULL | Cobertura de la póliza |
| po_fendozo_fin | DateTime | 8   | NULL | Fecha final del endoso |
| po_secuencial_pag | int | 4   | NULL | Secuencial de Pago |

### cu_por_inspeccionar

Almacena las garantías cuya inspección es solicitada por el banco.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| pi_filial | Tinyint | 1   | NOT NULL | Código de la filial |
| pi_sucursal | Smallint | 2   | NOT NULL | Código sucursal |
| pi_tipo | Descripcion | 64  | NOT NULL | Código de tipo de garantía |
| pi_custodia | Int | 4   | NOT NULL | Código numérico de garantía |
| pi_fecha_ant | Datetime | 8   | NULL | Fecha de inspección anterior |
| pi_inspector_ant | Tinyint | 1   | NOT NULL | Código de inspector que realizó la inspección anterior |
| pi_estado_ant | Catalogo | 10  | NOT NULL | Estado anterior de la inspección |
| pi_inspector_asig | Tinyint | 1   | NOT NULL | Código de inspector asignado. |
| pi_fecha_asig | Datetime | 8   | NOT NULL | Fecha de asignación de inspector |
| pi_riesgos | Money | 8   | NOT NULL | Monto de riesgo del cliente |
| pi_codigo_externo | Varchar | 64  | NOT NULL | Código compuesto de la garantía |
| pi_inspeccionado | Varchar | 1   | NULL | Indica si ha sido inspeccionado |
| pi_fecha_insp | Datetime | 8   | NULL | Fecha de inspección |
| pi_fenvio_carta | Datetime | 8   | NULL | Fecha de envío de carta |
| pi_frecep_reporte | Datetime | 8   | NULL | Fecha de recepción de reporte |
| pi_deudor | Int | 4   | NULL | Código del cliente |

### cu_recuperacion

Registra los valores efectivamente recuperados de las garantías con vencimientos (ejemplo, cheques, facturas, pagarés, etc.).

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| re_filial | Tinyint | 1   | NOT NULL | Código de filial |
| re_sucursal | Smallint | 2   | NOT NULL | Código de sucursal |
| re_tipo_cust | Descripcion | 64  | NOT NULL | Tipo de custodia |
| re_custodia | Int | 4   | NOT NULL | Código de custodia |
| re_recuperacion | Smallint | 2   | NOT NULL | Código de recuperación |
| re_valor | Money | 8   | NOT NULL | Valor de recuperación |
| re_vencimiento | Smallint | 2   | NOT NULL | Valor de vencimiento |
| re_fecha | Datetime | 8   | NULL | Fecha de recuperación |
| re_cobro_vencimiento | Money | 8   | NULL | Valor de cobro al vencimiento |
| re_cobro_mora | Money | 8   | NULL | Valor en mora |
| re_cobro_comision | Money | 8   | NULL | Valor de comisión |
| re_codigo_externo | Varchar | 64  | NOT NULL | Código compuesto de la garantía |
| re_ret_iva | Moneynt | 8   | NOT NULL | Valor Iva de la recuperación |
| re_ret_fte | Money | 8   | NOT NULL | Valor Retefuente de la recuperación |
| re_operacion | Int | 4   | NOT NULL | Numero de la operación |
| re_secuencial_ab | Int | 4   | NOT NULL | Secuencial de pago |

### cu_secuenciales

Almacena la información acerca del manejo de secuenciales por código de garantía.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| se_garantia | Varchar | 64  | NOT NULL | Código de la garantía |
| se_secuencial | Int | 4   | NOT NULL | Número secuencial siguiente |

### cu_seqnos

Tabla usada para generar secuenciales únicos por sucursal y tipo de garantía.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| se_filial | Tinyint | 1   | NOT NULL | Código de filial |
| se_sucursal | Smallint | 2   | NOT NULL | Código de la sucursal |
| se_codigo | descripcion | 64  | NOT NULL | Tipo de custodia |
| se_actual | Int | 4   | NOT NULL | Número secuencial actual |

### cu_tipo_custodia

Registra los tipos de garantías que se administrará en este módulo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tc_tipo | Varchar | 64  | NOT NULL | Nemónico de tipo |
| tc_tipo_superior | Varchar | 64  | NULL | Nemónico de tipo superior |
| tc_descripcion | Varchar | 255 | NULL | Descripción del tipo de custodia |
| tc_periodicidad | Catalgo | 10  | NULL | Periodicidad del tipo de custodia. Campo en desuso, valor por defecto 1. |
| tc_contabilizar | Char | 1   | NULL | Indicador de contabilidad |
| tc_porcentaje | Float | 8   | NULL | Porcentaje de depreciación |
| tc_adecuada | Char | 1   | NULL | Campo no utilizado en esta versión. Valor por defecto "S". |
| tc_clase_garantia | Varchar | 10  | NULL | Campo no utilizado en esta version |
| tc_producto | Tinyint | 1   | NULL | Código de producto. Valor por defecto NULL. |
| tc_porcen_cobeertura | Float | 8   | NULL | Porcentaje de cobertura |
| tc_tipo_bien | Char | 1   | NULL | Campo no utilizado en esta versión. Valor por defecto NULL. |

### cu_tran_conta

Registra información de las transacciones para contabilidad.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| to_secuencial | int | 4   | NOT NULL | Secuencial de la transaccion |
| to_filial | tinyint | 1   | NOT NULL | Código de la filial |
| to_oficina_orig | smallint | 2   | NOT NULL | Oficina origen de transaccion |
| to_oficina_dest | smallint | 2   | NOT NULL | Oficina destino de transaccion |
| to_tipo_cust | descripcion | 64  | NOT NULL | Tipo de custodia |
| to_moneda | tinyint | 1   | NOT NULL | Tipo de moneda |
| to_valor | money | 8   | NOT NULL | Valor de la transaccion |
| to_valor_me | money | 8   | NOT NULL | Valor moneda extranjera |
| to_operacion | char | 1   | NOT NULL | Tipo de operación de la transaccion |
| to_codigo_externo | varchar | 64  | NOT NULL | Codigo compuesto de la garantia |
| to_contabiliza | char | 1   | NULL | Característica que determina si se contabilizo o no una garantia |
| to_fecha | datetime | 8   | NULL | Fecha en que se realiza la transaccion |
| to_codval | int | 4   | NULL | Codigo valor para obtener perfiles contables |
| to_tipo_cca | catalogo | 10  | NULL | Tipo de cartera |
| to_estado | char | 1   | NULL | Estado de proceso de contabilidad |
| to_secuencial_trn | int | 4   | NULL | Codigo Secuencial de la transaccion |
| to_usuario | login | 64  | NULL | Usuario de la transaccion |

### cu_tran_cust

Guarda la información de las transacciones monetarias para contabilidad.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| trc_tran | Varchar | 10  | NOT NULL | Código de transaccion en garantías |
| trc_perfil | Varchar | 10  | NOT NULL | Perfil asociado a la transacción. |

### cu_transaccion

Registra las transacciones realizadas para modificar las garantías de este módulo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tr_codigo_externo | Varchar | 64  | NOT NULL | Código compuesto de garantía |
| tr_fecha_tran | Datetime | 8   | NOT NULL | Fecha de la transacción |
| tr_descripcion | Varchar | 64  | NULL | Descripción de la transacción |
| tr_usuario | Varchar | 64  | NOT NULL | Usuario que ejecutó la transacción |
| tr_filial | Tinyint | 1   | NOT NULL | Oficina en la que se realiza la transacción |
| tr_sucursal | smallint | 2   | NOT NULL | Sucursal de la transacción |
| tr_tipo_cust | Descripcion | 64  | NOT NULL | Tipo garantía |
| tr_custodia | int | 4   | NOT NULL | Garantía |
| tr_transaccion | smallint | 2   | NOT NULL | Número de la transacción |
| tr_debcred | char | 1   | NOT NULL | Tipo de transacción.  <br><br/>D - Débito<br><br>C - Crédito<br><br>(Catálogo cu_causa_transaccion Devaluación, Revalorización) |
| tr_valor | Money | 8   | NOT NULL | Valor de la transacción |
| tr_valor_anterior | Money | 8   | NULL | Valor anterior de la transacción |

## Tablas de Transacciones de servicio

Cada módulo tiene una Base de Datos, la cual cuenta con una tabla de Transacciones de Servicio, en la que se incluyen todos los campos de todas las tablas que pueden sufrir modificación en la operación del módulo (inserción, actualización o eliminación). Se entiende por Vista de Transacciones de Servicio, aquella porción de la tabla Transacciones de Servicio que compete a determinada Transacción.

Cada modificación de la Base de Datos genera un registro indicando la transacción realizada (secuencial, clase y código), persona que ejecuta la transacción (usuario que envía el requerimiento), desde y dónde (terminal, y servidores de origen y ejecución de la transacción) y los datos de la tabla a modificar.

### cu_tran_servicio

Guarda la información de las transacciones de servicio.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| ts_secuencial | Int | 4   | NOT NULL | Código secuencial |
| ts_tipo_transaccion | Smallint | 2   | NOT NULL | Tipo de transacción |
| ts_clase | Char | 1   | NOT NULL | Clase de movimiento |
| ts_fecha | Datetime | 8   | NULL | Fecha de registro |
| ts_usuario | Varchar | 64  | NULL | Usuario de registro |
| ts_terminal | Varchar | 64  | NULL | Terminal donde se realizo el movimiento |
| ts_correccion | Char | 1   | NULL | Indica si el registro es un reverso.<br><br>S= Es un reverso<br><br>N= No es un reverso |
| ts_ssn_corr | Int | 4   | NULL | Secuencial de corrección |
| ts_reentry | Char | 1   | NULL | Identifica como fue ejecutada la transacción<br><br>S= Ejecutada por REENTRY<br><br>N= No ejecutada por REENTRY |
| ts_origen | Char | 1   | NULL | Origen de la transacción<br><br>L= Local<br><br>R= Remoto |
| ts_nodo | Varchar | 30  | NULL | Descripción de nodo de ejecución |
| ts_remoto_ssn | Int | 4   | NULL | Secuencial de ejecución remota |
| ts_oficina | Tinyint | 1   | NULL | Código de la oficina |
| ts_tabla | Varchar | 255 | NULL | Tabla de modificación |
| ts_tinyint1 | Tinyint | 1   | NULL | Valor modificado de tipo tinyint1 |
| ts_tinyint2 | Tinyint | 1   | NULL | Valor modificado de tipo tinyint2 |
| ts_tinyint3 | Tinyint | 1   | NULL | Valor modificado de tipo tinyint3 |
| ts_tinyint4 | Tinyint | 1   | NULL | Valor modificado de tipo tinyint4 |
| ts_tinyint5 | Tinyint | 1   | NULL | Valor modificado de tipo tinyint5 |
| ts_smallint1 | Smallint | 2   | NULL | Valor modificado de tipo smallint1 |
| ts_smallint2 | Smallint | 2   | NULL | Valor modificado de tipo smallint2 |
| ts_smallint3 | Smallint | 2   | NULL | Valor modificado de tipo smallint3 |
| ts_smallint4 | Smallint | 2   | NULL | Valor modificado de tipo smallint4 |
| ts_int1 | Int | 4   | NULL | Valor modificado de tipo int1 |
| ts_int2 | Int | 4   | NULL | Valor modificado de tipo int2 |
| ts_int3 | Int | 4   | NULL | Valor modificado de tipo int3 |
| ts_int4 | Int | 4   | NULL | Valor modificado de tipo int4 |
| ts_varchar1 | Varchar | 64  | NULL | Valor modificado de tipo varchar1 |
| ts_varchar2 | Varchar | 64  | NULL | Valor modificado de tipo varchar2 |
| ts_varchar3 | Varchar | 64  | NULL | Valor modificado de tipo varchar3 |
| ts_varchar4 | Varchar | 64  | NULL | Valor modificado de tipo varchar4 |
| ts_varchar5 | Varchar | 64  | NULL | Valor modificado de tipo varchar5 |
| ts_varchar6 | Varchar | 64  | NULL | Valor modificado de tipo varchar6 |
| ts_varchar7 | Varchar | 64  | NULL | Valor modificado de tipo varchar7 |
| ts_varchar8 | Varchar | 64  | NULL | Valor modificado de tipo varchar8 |
| ts_varchar9 | Varchar | 64  | NULL | Valor modificado de tipo varchar9 |
| ts_varchar10 | Varchar | 64  | NULL | Valor modificado de tipo varchar10 |
| ts_varchar11 | Varchar | 64  | NULL | Valor modificado de tipo varchar11 |
| ts_varchar12 | Varchar | 64  | NULL | Valor modificado de tipo varchar12 |
| ts_varchar13 | Varchar | 64  | NULL | Valor modificado de tipo varchar13 |
| ts_varchar14 | Varchar | 64  | NULL | Valor modificado de tipo varchar14 |
| ts_varchar15 | Varchar | 64  | NULL | Valor modificado de tipo varchar15 |
| ts_varchar16 | Varchar | 64  | NULL | Valor modificado de tipo varchar16 |
| ts_varchar17 | Varchar | 64  | NULL | Valor modificado de tipo varchar17 |
| ts_varchar18 | Varchar | 64  | NULL | Valor modificado de tipo varchar18 |
| ts_char1 | Char | 1   | NULL | Valor modificado de tipo char1 |
| ts_char2 | Char | 1   | NULL | Valor modificado de tipo char2 |
| ts_char3 | Char | 1   | NULL | Valor modificado de tipo char3 |
| ts_char4 | Char | 1   | NULL | Valor modificado de tipo char4 |
| ts_char5 | Char | 1   | NULL | Valor modificado de tipo char5 |
| ts_char6 | Char | 1   | NULL | Valor modificado de tipo char6 |
| ts_char7 | Char | 1   | NULL | Valor modificado de tipo char7 |
| ts_char8 | Char | 1   | NULL | Valor modificado de tipo char8 |
| ts_char9 | Char | 1   | NULL | Valor modificado de tipo char9 |
| ts_char10 | Char | 1   | NULL | Valor modificado de tipo char10 |
| ts_money1 | Money | 8   | NULL | Valor modificado de tipo money1 |
| ts_money2 | Money | 8   | NULL | Valor modificado de tipo money2 |
| ts_money3 | Money | 8   | NULL | Valor modificado de tipo money3 |
| ts_money4 | Money | 8   | NULL | Valor modificado de tipo money4 |
| ts_money5 | Money | 8   | NULL | Valor modificado de tipo money5 |
| ts_money6 | Money | 8   | NULL | Valor modificado de tipo money6 |
| ts_money7 | Money | 8   | NULL | Valor modificado de tipo money7 |
| ts_money8 | Money | 8   | NULL | Valor modificado de tipo money8 |
| ts_money9 | Money | 8   | NULL | Valor modificado de tipo money9 |
| ts_datetime1 | Datetime | 8   | NULL | Valor modificado de tipo datetime1 |
| ts_datetime2 | Datetime | 8   | NULL | Valor modificado de tipo datetime2 |
| ts_datetime3 | Datetime | 8   | NULL | Valor modificado de tipo datetime3 |
| ts_datetime4 | Datetime | 8   | NULL | Valor modificado de tipo datetime4 |
| ts_datetime5 | Datetime | 8   | NULL | Valor modificado de tipo datetime5 |
| ts_datetime6 | Datetime | 8   | NULL | Valor modificado de tipo datetime6 |
| ts_datetime7 | Datetime | 8   | NULL | Valor modificado de tipo datetime7 |
| ts_datetime8 | Datetime | 8   | NULL | Valor modificado de tipo datetime8 |
| ts_datetime9 | Datetime | 8   | NULL | Valor modificado de tipo datetime9 |
| ts_datetime10 | Datetime | 8   | NULL | Valor modificado de tipo datetime10 |
| ts_float1 | Float | 8   | NULL | Valor modificado de tipo float1 |
| ts_descripcion1 | Varchar | 64  | NULL | Valor modificado de tipo varchar2551 |
| ts_descripcion2 | Varchar | 64  | NULL | Valor modificado de tipo varchar2552 |
| ts_descripcion3 | Varchar | 64  | NULL | Valor modificado de tipo varchar2553 |

## INDICES POR CLAVE PRIMARIA

Descripción de los índices por clave primaria definidos para las tablas del sistema Garantías.

| Tipo Índice |     | UNIQUE CLUSTERED |     |
| --- |     | --- |     | --- | --- |
| **No** | **Índice** | **Tabla** | **Columnas Combinadas** |
| 1   | cu_almacenera_Key | cu_almacenera | al_almacenera |
| 2   | cu_cliente_garantia_Key | cu_cliente_garantia | cg_codigo_externo<br><br>cg_ente |
| 3   | cu_control_inspector_Key | cu_control_inspector | ci_inspector<br><br>ci_fenvio_carta |
| 4   | cu_custodia_Key | cu_custodia | cu_codigo_externo |
| 5   | cu_gastos_Key | cu_gastos | ga_codigo_externo<br><br>ga_gastos |
| 6   | cu_inspeccion_Key | cu_inspeccion | in_codigo_externo<br><br>in_fecha_insp |
| 7   | cu_inspector_Key | cu_inspector | is_inspector |
| 8   | cu_instruccion_Key | cu_inst_operativa | io_codigo_externo<br><br>io_numero |
| 9   | cu_item_custodia_Key | cu_item_custodia | ic_codigo_externo<br><br>ic_secuencial<br><br>ic_item |
| 10  | cu_item_Key | cu_item | it_tipo_custodia<br><br>it_item |
| 11  | cu_mig_custodia_Key | cu_mig_custodia | mc_garante<br><br>mc_ente<br><br>mc_operacion |
| 12  | cu_poliza_Key | cu_poliza | po_aseguradora<br><br>po_poliza<br><br>po_codigo_externo |
| 13  | cu_por_inspeccionar_Key | cu_por_inspeccionar | pi_codigo_externo<br><br>pi_fecha_insp |
| 14  | cu_recuperacion_Key | cu_recuperacion | re_codigo_externo<br><br>re_vencimiento |
| 15  | cu_tipo_custodia_Key | cu_tipo_custodia | tc_tipo |
| 16  | cu_conta_Key | cu_tran_conta | to_secuencial |
| 17  | cu_transaccion_Key | cu_transaccion | tr_codigo_externo<br><br>tr_transaccion |
| 18  | cu_vencimiento_Key | cu_vencimiento | ve_codigo_externo<br><br>ve_vencimiento |

## INDICES POR CLAVE FORANEA

Descripción de los índices por clave foránea definidos para las tablas del sistema Garantías.

| Tipo Índice |     | INDEX |     |
| --- |     | --- |     | --- | --- |
| **No** | **Índice** | **Tabla** | **Columnas Combinadas** |
| 1   | cu_gar_operacion_Key | cu_garantia_operacion | go_codigo_externo<br><br>go_operacion |
| 2   | cu_poliza_key2 | cu_poliza | po_fvigencia_fin |
| 3   | ipo_codigo_externo | cu_poliza | po_codigo_externo |
| 4   | i_cu_cliente_i2 | cu_cliente_garantia | cg_ente<br><br>cg_oficial |
| 5   | i_cu_cliente_i3 | cu_cliente_garantia | cg_oficial |
| 6   | i_cu_custodia_i2 | cu_custodia | cu_filial<br><br>cu_sucursal<br><br>cu_tipo<br><br>cu_custodia |
| 7   | i_cu_custodia_i3 | cu_custodia | cu_tipo |
| 8   | i_cu_custodia_i4 | cu_custodia | cu_garante |
| 9   | cu_errorlog_1 | cu_errorlog | er_fecha_proc |
| 10  | i_cu_det_trn | cu_det_trn | dtr_codigo_externo |
| 11  | i_cu_inspeccion_i2 | cu_inspeccion | in_filial<br><br>in_sucursal<br><br>in_tipo_cust<br><br>in_custodia |
| 12  | cu_recuperacion_1 | cu_recuperacion | re_codigo_externo<br><br>re_vencimiento |
| 13  | cu_transaccion_i2 | cu_transaccion | tr_filial<br><br>tr_fecha_tran |
| 14  | cu_vencimiento_1 | cu_vencimiento | ve_deudor |
| 15  | cu_vencimiento_2 | cu_vencimiento | ve_filial<br><br>ve_sucursal<br><br>ve_tipo_cust<br><br>ve_custodia |
| 16  | cu_vencimiento_3 | cu_vencimiento | ve_cta_debito |