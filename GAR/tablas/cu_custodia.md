# cu_custodia

## Descripción

El maestro de garantías registra las garantías administradas en el sistema.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| cu_filial | Tinyint | 1 | NOT NULL | Código de la filial de la garantía. |
| cu_sucursal | Smallint | 2 | NOT NULL | Sucursal a la que pertenece la garantía. |
| cu_tipo | descripcion | 64 | NOT NULL | Tipo de garantía. |
| cu_custodia | Int | 4 | NOT NULL | Código de custodia |
| cu_propuesta | int | 4 | NULL | Codigo de propuesta |
| cu_estado | catalogo | 10 | NULL | Estado de custodia (del catálogo cu_est_custodia) |
| cu_fecha_ingreso | Datetime | 8 | NULL | Fecha de ingreso |
| cu_valor_inicial | Money | 8 | NULL | Valor inicial |
| cu_valor_actual | Money | 8 | NULL | Valor actual |
| cu_moneda | Tinyint | 1 | NULL | Moneda de la garantía |
| cu_garante | Int | 4 | NULL | Código del garante. (En Garantías de Tipo Garantía Personal) |
| cu_instruccion | Varchar | 255 | NULL | Texto de observación de la situación de la garantía |
| cu_descripcion | Varchar | 255 | NULL | Descripción de la custodia |
| cu_poliza | varchar | 20 | NULL | Codigo de póliza. (No se utiliza en esta versión) |
| cu_inspeccionar | Char | 1 | NULL | Indicador de inspección.<br><br>S= Necesita inspección<br>N= No necesita inspección |
| cu_motivo_noinsp | catalogo | 10 | NULL | Motivo de no inspección (Del catálogo cu_motivo_noinspeccion). |
| cu_suficiencia_legal | char | 1 | NULL | Indicador de suficiencia legal<br><br>S = Suficiente<br>N = No Suficiente<br>O = No Aplica<br>(No se utiliza en esta versión) |
| cu_fuente_valor | catalogo | 10 | NULL | Indica la razón o fuente del valor de la garantía (cu_fuente_valor): avalúo, factura, precio de mercado, etc. |
| cu_situacion | char | 1 | NULL | Situacion de la garantía. Campo en desuso. |
| cu_almacenera | Smallint | 2 | NULL | Código de almacenera, si la garantía es física y necesita estar en ese espacio físico. |
| cu_aseguradora | varchar | 20 | NULL | Nombre de la aseguradora. (No se utiliza en esta versión) |
| cu_cta_inspeccion | Varchar | 24 | NULL | Número de Cuenta de depósito de valor cancelados a inspectores, (No se utiliza en esta versión) |
| cu_tipo_cta | Varchar | 8 | NULL | Tipo de cuenta de depósito. AHO: Ahorros<br>CTE: Corriente<br>(No se utiliza en esta versión) |
| cu_direccion_prenda | descripcion | 64 | NULL | Dirección de la prenda |
| cu_ciudad_prenda | descripcion | 64 | NULL | Ciudad de la prenda |
| cu_telefono_prenda | Varchar | 20 | NULL | Teléfono donde se encuentra la prenda. |
| cu_mex_prx_inspec | tinyint | 1 | NULL | Columna en desuso |
| cu_fecha_modif | Datetime | 8 | NULL | Fecha de modificación. |
| cu_fecha_const | Datetime | 8 | NULL | Fecha de constitución de la garantía |
| cu_porcentaje_valor | float | 8 |  | Porcentaje de valor de la custodia. Campo en desuso. |
| cu_periodicidad | catalogo | 10 | NULL | Periodicidad de inspección (Del catálogo cu_des_periodicidad)<br>(No se utiliza en esta versión) |
| cu_depositario | Varchar | 255 | NULL | Descripción del depositario. Campo informativo, no se usa en esta version |
| cu_posee_poliza | Char | 1 | NULL | Indicador si posee póliza.<br><br>S= Posee póliza<br>N= No posee póliza<br>Campo no se usa en esta versión |
| cu_nro_inspecciones | Tinyint | 1 | NULL | Número de inspecciones realizadas (Registradas en cob_custodia..cu_inspeccion). |
| cu_intervalo | Tinyint | 1 | NULL | Número de días del período |
| cu_cobranza_judicial | Char | 1 | NULL | Garantía en cobranza judicial<br><br>S= En cobranza<br>N= No está en cobranza |
| cu_fecha_retiro | datetime | 8 | NULL | Fecha retiro de la custodia. Se usa si cu_cobranza_judicial = "S" |
| cu_fecha_devolucion | datetime | 8 | NULL | Fecha devolución de la custodia. Se usa si cu_cobranza_judicial = "S" |
| cu_fecha_modificacion | Datetime | 8 | NULL | Fecha de actualización. |
| cu_usuario_crea | descripcion | 64 | NULL | Usuario de creación de la custodia. |
| cu_usuario_modifica | descripcion | 64 | NULL | Usuario de modificación de la custodia. |
| cu_estado_poliza | Char | 1 | NULL | Código de estado de la póliza.<br><br>V= Vigente<br>E= Excepcional<br>C= Cerrada<br>No se usa en esta version. |
| cu_cobrar_comision | char | 1 | NULL | Caracteristica de cobrar comisión. No se usa en este versión. |
| cu_cuenta_dpf | Varchar | 30 | NULL | Código compuesto de operación DPF pignorada por la garantía. |
| cu_codigo_externo | Varchar | 64 | NOT NULL | Código externo para la garantía. |
| cu_fecha_insp | Datetime | 8 | NULL | Fecha de inspección. |
| cu_abierta_cerrada | Char | 1 | NULL | Característica de abierta o cerrada<br><br>A= Abierta<br>C= Cerrada |
| cu_adecuada_noadec | Char | 1 | NULL | Característica de adecuada y no adecuada<br><br>S= Adecuada<br>N= No adecuada<br>O= No aplica |
| cu_propietario | Varchar | 64 | NULL | Descripción del propietario. (No se utiliza en esta versión) |
| cu_plazo_fijo | Varchar | 30 | NULL | Código compuesto de operación DPF pignorada por la garantía. |
| cu_monto_pfijo | money | 8 |  | Monto de plazo fijo de la custodia |
| cu_oficina | Smallint | 2 | NULL | Código de la oficina |
| cu_oficina_contabiliza | Smallint | 2 | NULL | Código de la oficina que realizara la contabilidad de la custodia. |
| cu_compartida | Char | 1 | NULL | Característica de compartida<br><br>S= Compartida<br>N= Sin compartir |
| cu_valor_compartida | Money | 8 | NULL | Valor compartido (Si cu_compartida = 'S') |
| cu_fecha_reg | Datetime | 8 | NOT NULL | Fecha de registro de la custodia. |
| cu_fecha_prox_insp | Datetime | 8 | NULL | Fecha de registro de la próxima inspección. |
| cu_fecha_vencimiento | datetime | 8 | NULL | Fecha de vencimiento de la custodia |
| cu_tipo_cca | catalogo | 10 | NULL | Tipo de cartera de la custodia. No se usa en esta version |
| cu_pais | smallint | 2 | NULL | Codigo de país |
| cu_provincia | smallint | 2 | NULL | Codigo de provincia |
| cu_canton | int | 4 | NULL | Codigo de canton |
| cu_fecha_avaluo | datetime | 8 | NULL | Fecha de avaluo de la custodia |
| cu_ubicacion | catalogo | 10 | NULL | Ubicación de la custodia.( No se usa en esta version) |
| cu_cuantia | char | 1 | NULL | No aplica en esta versión |
| cu_porcentaje_cobertura | float | 8 | NULL | Porcentaje de cobertura de la custodia. ( No se usa en esta version) |
| cu_agotada | char | 1 | NULL | Caracterisitca de agotamiento<br><br>S = Con agotamiento<br>N = Sin agotamiento<br>No se usa en esta version. |
| cu_clase_custodia | char | 1 | NULL | Clase de custodia. No se usa en esta version. |
| cu_ciudad_gar | int | 4 | NULL | Columna en desuso |
| cu_num_dcto | varchar | 13 | NULL | Columna en desuso |
| cu_clase_vehiculo | varchar | 10 | NULL | Columna en desuso |
| cu_clase_cartera | catalogo | 10 | NULL | Codigo de clase de cartera cuando se activa la garantía. |
| cu_autoriza | varchar | 25 | NULL | Código de autorización. No se usa en esta versión. |
| cu_cuenta_tipo | tinyint | 1 | NULL | Columna en desuso |
| cu_cuenta_hold | Varchar | 30 | NULL | Cuenta hold. No se usa en esta version. |
| cu_cuenta_tipo | Tinyint | 1 | NULL | Tipo de cuenta: ahorros 4, corriente 3. No se usa en esta version. |
| cu_id_bloqueo_cta | int | 4 | NULL | Codigo secuencial de bloqueo para levantamientos |
| cu_fondo_garantia | varchar | 2 | NULL | Columna en desuso |
| cu_valor_avaluo | money | 8 | NULL | Columna en desuso |
| cu_num_documento | varchar | 30 | NULL | Columna en desuso |
| cu_nemonico_cob | catalogo | 10 | NULL | Columna en desuso |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
