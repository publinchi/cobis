COBIS CARTERA

DICCIONARIO DE DATOS

Historia de Cambios

| Versión | Fecha | Autor | Revisado | Aprobado | Descripción |
| --- | --- | --- | --- | --- | --- |
| 1.0.0 | 23-Ago-23 | KDR |     |     | Emisión inicial adaptado a plantilla Cobis-Topaz. |
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

[COBIS CARTERA 1](#_Toc143698047)

[DICCIONARIO DE DATOS 1](#_Toc143698048)

[1 Introducción 5](#_Toc143698049)

[2 Diccionario de Datos 5](#_Toc143698050)

[2.1 Tablas cob_cartera 5](#_Toc143698051)

[ca_abono 5](#_Toc143698052)

[ca_abono_det 7](#_Toc143698053)

[ca_abono_det_tmp 9](#_Toc143698054)

[ca_abono_prioridad 10](#_Toc143698055)

[ca_abono_prioridad_tmp 10](#_Toc143698056)

[ca_amortizacion 11](#_Toc143698057)

[ca_amortizacion_his 12](#_Toc143698058)

[ca_amortizacion_tmp 12](#_Toc143698059)

[ca_ciclo 13](#_Toc143698060)

[ca_cliente_calificacion 14](#_Toc143698061)

[ca_concepto 14](#_Toc143698062)

[ca_conversion 15](#_Toc143698063)

[ca_cuota_adicional 15](#_Toc143698064)

[ca_datos_adicionales_pasivas 16](#_Toc143698065)

[ca_datos_adicionales_pasivas_t 16](#_Toc143698066)

[ca_decodificador 17](#_Toc143698067)

[ca_default_toperacion 18](#_Toc143698068)

[ca_desembolso 25](#_Toc143698069)

[ca_det_ciclo 28](#_Toc143698070)

[ca_det_trn 28](#_Toc143698071)

[ca_dividendo 29](#_Toc143698072)

[ca_dividendo_his 31](#_Toc143698073)

[ca_dividendo_tmp 32](#_Toc143698074)

[ca_errorlog 33](#_Toc143698075)

[ca_estado 33](#_Toc143698076)

[ca_estados_man 34](#_Toc143698077)

[ca_operacion_datos_adicionales 34](#_Toc143698078)

[ca_operacion 35](#_Toc143698079)

[ca_operacion_his 48](#_Toc143698080)

[ca_operacion_datos_adicionales_tmp 59](#_Toc143698081)

[ca_operacion_tmp 60](#_Toc143698082)

[ca_otro_cargo 70](#_Toc143698083)

[ca_param_cargos_gestion_cobranza 71](#_Toc143698084)

[ca_producto 72](#_Toc143698085)

[ca_provision_cartera 74](#_Toc143698086)

[ca_reajuste 75](#_Toc143698087)

[ca_reajuste_det 76](#_Toc143698088)

[ca_registra_traslados_masivos 77](#_Toc143698089)

[ca_rubro 80](#_Toc143698090)

[ca_rubro_op 84](#_Toc143698091)

[ca_rubro_op_his 87](#_Toc143698092)

[ca_rubro_op_tmp 90](#_Toc143698093)

[ca_secuencial_atx 92](#_Toc143698094)

[ca_tasas 93](#_Toc143698095)

[ca_tasas_tmp 94](#_Toc143698096)

[ca_tdividendo 95](#_Toc143698097)

[ca_tipo_trn 96](#_Toc143698098)

[ca_transaccion_prv 96](#_Toc143698099)

[ca_transaccion 98](#_Toc143698100)

[ca_traslados_cartera 99](#_Toc143698101)

[ca_valor 101](#_Toc143698102)

[ca_valor_det 101](#_Toc143698103)

[ca_pin_odp 102](#_Toc143698104)

[ca_archivo_pagos_1_tmp 103](#_Toc143698105)

[ca_archivo_pagos_1 104](#_Toc143698106)

[ca_en_fecha_valor 105](#_Toc143698107)

[ca_batch_pagos_corresponsal 106](#_Toc143698108)

[ca_incentivos_detalle_operaciones 107](#_Toc143698109)

[ca_incentivos_obtencion_indicadores 108](#_Toc143698110)

[ca_incentivos_metas 110](#_Toc143698111)

[ca_incentivos_metas_tmp 111](#_Toc143698112)

[ca_errores_ope_masivas 111](#_Toc143698113)

[ca_7x24_fcontrol 112](#_Toc143698114)

[ca_7x24_saldos_prestamos 112](#_Toc143698115)

[ca_7x24_errores 113](#_Toc143698116)

[ca_cambio_estado_masivo 114](#_Toc143698117)

[ca_abono_grupal_tmp 115](#_Toc143698118)

[ca_qr_transacciones_tmp 116](#_Toc143698119)

[ca_en_fecha_valor_grupal 117](#_Toc143698120)

[ca_log_fecha_valor_grupal 117](#_Toc143698121)

[2.2 Tablas de Transacciones de servicio 118](#_Toc143698122)

[ca_default_toperacion_ts 118](#_Toc143698123)

[ca_dividendo_ts 124](#_Toc143698124)

[ca_estados_man_ts 125](#_Toc143698125)

[ca_operacion_datos_adicionales_ts 126](#_Toc143698126)

[ca_operacion_ts 128](#_Toc143698127)

[ca_reajuste_det_ts 137](#_Toc143698128)

[ca_reajuste_ts 138](#_Toc143698129)

[ca_rubro_op_ts 139](#_Toc143698130)

[ca_rubro_ts 142](#_Toc143698131)

[ca_valor_det_ts 145](#_Toc143698132)

[ca_valor_referencial_ts 146](#_Toc143698133)

[ca_valor_ts 147](#_Toc143698134)

[ca_pin_odp_ts 147](#_Toc143698135)

[ca_proc_rubro_calculados_ts 148](#_Toc143698136)

[ca_incentivos_metas_ts 152](#_Toc143698137)

[2.3 INDICES POR CLAVE PRIMARIA 153](#_Toc143698138)

[2.4 INDICES POR CLAVE FORANEA 158](#_Toc143698139)

DICCIONARIO DE DATOS

Tablas Cartera

# Introducción

En este diccionario se encuentran enumeradas las tablas que componen el módulo junto con una pequeña descripción de su uso, tambíen se muestran los campos que tiene cada tabla y se describe su uso.

# Diccionario de Datos

## Tablas cob_cartera

A continuación se muestra el diccionario de datos de este módulo.

### ca_abono

Es un registro de la información de las características y negociación que el cliente definio al momento de realizar un pago, es un registro de cabecera. También contiene los secuenciales de las transacciones de pagos y registro de pagos.

| **Nombre del campo** | **Tipo de dato** | **LONG** | **Car.de dato** | **Descripción** |
| --- | --- | --- | --- | --- |
| ab_operacion | int | 4   | NOT NULL | Número de operación de cartera |
| ab_secuencial_ing | int | 4   | NOT NULL | Secuencial único de ingreso del pago |
| ab_secuencial_rpa | int | 4   | NOT NULL | Secuencial asociado a la transacción RPA |
| ab_secuencial_pag | int | 4   | NOT NULL | Secuencial de la transacción PAG |
| ab_fecha_ing | datetime | 8   | NOT NULL | Fecha de ingreso del pago |
| ab_fecha_pag | datetime | 8   | NOT NULL | Fecha de aplicación del pago |
| ab_cuota_completa | char | 1   | NOT NULL | Si el pago aplica cuota completa |
| ab_aceptar_anticipos | char | 1   | NOT NULL | Si acepta anticipos |
| ab_tipo_reduccion | char | 1   | NOT NULL | Si regenera la tabla que tipo de reducción realiza:<br><br>N = Pago normal/adelantado<br><br>C = Reducción de cuota<br><br>T = Reducción de tiempo |
| ab_tipo_cobro | char | 1   | NOT NULL | Tipo de cobro:<br><br>P = proyectado<br><br>A = acumulado |
| ab_dias_retencion_ini | int | 4   | NOT NULL | Días de retención inicial |
| ab_dias_retencion | int | 4   | NOT NULL | Días de retención |
| ab_estado | char | 3   | NOT NULL | Estado del pago<br><br>ING = ingresado<br><br>A = Aplicado<br><br>RV = Reversado<br><br>E = Eliminado |
| ab_usuario | login | 14  | NOT NULL | Usuario de aplicación del pago |
| ab_oficina | smallint | 2   | NOT NULL | Oficina que ingresa el pago |
| ab_terminal | descripcion | 160 | NOT NULL | Terminal del usuario que ingresa el pago |
| ab_tipo | char | 3   | NOT NULL | Tipo de abono<br><br>PAG = Pago |
| ab_tipo_aplicacion | char | 1   | NOT NULL | Si el pago se aplica por<br><br>D = Dividendo<br><br>C = Rubro |
| ab_nro_recibo | int | 4   | NOT NULL | Secuencial generado para el recibo. Campo no se usa en esta versión |
| ab_tasa_prepago | Float | 8   | NULL | Porcentaje de la tasa de interés del prestamo |
| ab_dividendo | smallint | 2   | NULL | Número de dividendo para aplicar el pago |
| ab_calcula_devolucion | char | 1   | NULL | Indica si calcula devolución<br><br>S = SI<br><br>N = NO<br><br>Campo no se usa en esta versión |
| ab_prepago_desde_lavigente | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_prepago_desde_lavigente de la tabla ca_default_toperacion. |
| ab_extraordinario | char | 1   | NULL | Permite abono extraordinario<br><br>N = No<br><br>S = Si |
| ab_secuencial_ing_abono_grupal | int | 4   | NULL | Secuencial que solo se registra a operaciones hijas y que identifica el registro de abono Operación Padre (ab_secuencial). |
| ab_ssn | int | 4   | NULL | Secuencial de sesión el cual identifica los registros de tanqueo para facturación electrónica del pago (cob_externos). |
| ab_guid_dte | varchar | 36  | NULL | Número único que apunta a un dte en los registros de tanqueo para facuración electrónica (cob_externos). |

### ca_abono_det

Es un registro de la información de las formas de pago y los montos entregados por el cliente para realizar un pago, se genera un registro por cada forma de pago

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| abd_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| abd_secuencial_ing | int | 4   | NOT NULL | Secuencial único de ingreso del pago |
| abd_tipo | char | 3   | NOT NULL | PAG = Pago,<br><br>CON= Condonación de deuda<br><br>SOB= Sobrante automático |
| abd_concepto | catalogo | 10  | NOT NULL | Forma de cobro |
| abd_cuenta | cuenta | 24  | NOT NULL | Se utiliza en una forma de Pago con categoría "Banco Corresponsal" o "Monedero Electronico", contiene el código de cuenta del Banco Corresponsal / Proveedor. |
| abd_beneficiario | char | 50  | NOT NULL | Se utiliza para almacenar el campo de Referencia de pago ingresado desde frontEnd (Ej: #Boleta). |
| abd_moneda | tinyint | 1   | NOT NULL | Moneda del pago |
| abd_monto_mpg | money | 8   | NOT NULL | Monto pagado |
| abd_monto_mop | money | 8   | NOT NULL | Monto en la moneda de la operación |
| abd_monto_mn | money | 8   | NOT NULL | Monto en moneda nacional |
| abd_cotizacion_mpg | money | 8   | NOT NULL | Cotización de la moneda del pago |
| abd_cotizacion_mop | money | 8   | NOT NULL | Cotización de la moneda de la operación |
| abd_tcotizacion_mpg | char | 1   | NOT NULL | Tipo de cotización de la moneda del pago |
| abd_tcotizacion_mop | char | 1   | NOT NULL | Tipo de cotización de la moneda de la operación |
| abd_cheque | int | 4   | NULL | Número cheque |
| abd_cod_banco | catalogo | 10  | NULL | Se utiliza en una forma de Pago con categoría "Banco Corresponsal" o "Monedero Electronico", contiene el código de Banco / Proveedor. |
| abd_inscripcion | int | 4   | NULL | Columna de desuso |
| abd_carga | int | 4   | NULL | Columna de desuso |
| abd_porcentaje_con | float | 8   | NULL | Porcentaje de condonación. En está versión registra el monto del pago |
| abd_solidario | char | 1   | NOT NULL | Identificación de pago solidario<br><br>N = No<br><br>S = Si |

### ca_abono_det_tmp

Tabla temporal de trabajo donde se registra la información que será almacenada en la ca_abono_det

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| abdt_user | login | 14  | NOT NULL | Usuario de la transacción |
| abdt_sesn | int | 4   | NOT NULL | Número de sesión cobis |
| abdt_tipo | char | 3   | NOT NULL | PAG = Pago |
| abdt_concepto | catalogo | 10  | NOT NULL | Forma de cobro |
| abdt_operacion | int | 4   | NULL | Número interno de operación de cartera |
| abdt_secuencial_ing | int | 4   | NULL | Secuencial único de ingreso del pago |
| abdt_cuenta | cuenta | 24  | NOT NULL | Número de cuenta seleccionado desde FrontEnd |
| abdt_beneficiario | char | 50  | NULL | Parámetro ingresado desde FrontEnd en el campo referencia |
| abdt_moneda | tinyint | 1   | NOT NULL | Moneda del pago |
| abdt_monto_mpg | money | 8   | NOT NULL | Monto pagado |
| abdt_monto_mop | money | 8   | NOT NULL | Monto en la moneda de la operación |
| abdt_monto_mn | money | 8   | NOT NULL | Monto en moneda nacional |
| abdt_cotizacion_mpg | money | 8   | NOT NULL | Cotización de la moneda del pago |
| abdt_cotizacion_mop | money | 8   | NOT NULL | Cotización de la moneda de la operación |
| abdt_tcotizacion_mpg | char | 1   | NOT NULL | Tipo de cotización de la moneda del pago |
| abdt_tcotizacion_mop | char | 1   | NOT NULL | Tipo de cotización de la moneda de la operación |
| abdt_cheque | int | 4   | NULL | Número cheque |
| abdt_cod_banco | catalogo | 10  | NULL | Código de banco |
| abdt_inscripcion | int | 4   | NULL | Columna de desuso |
| abdt_carga | int | 4   | NULL | Columna de desuso |
| abdt_porcentaje_con | float | 8   | NULL | Porcentaje de condonación |
| abdt_solidario | char | 1   | NOT NULL | Identificación de pago solidario<br><br>N = No<br><br>S = Si |

### ca_abono_prioridad

Se almacena la prioridad en que se aplican los rubros de un pago

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripción** |
| --- | --- | --- | --- | --- |
| ap_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| ap_secuencial_ing | int | 4   | NOT NULL | Secuencial único de ingreso del pago |
| ap_concepto | catalogo | 10  | NOT NULL | Código del rubro o concepto |
| ap_prioridad | int | 4   | NOT NULL | Prioridad de cobro para el concepto |

### ca_abono_prioridad_tmp

Tabla temporal de trabajo donde se almacena la prioridad en que se aplican los rubros de un pago

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| apt_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| apt_secuencial_ing | int | 4   | NOT NULL | Secuencial único de ingreso del pago |
| apt_concepto | catalogo | 10  | NOT NULL | Código del rubro o concepto |
| apt_prioridad | int | 4   | NOT NULL | Prioridad de cobro para el concepto |

### ca_amortizacion

Almacena la información de los rubros (conceptos) y montos que forman parte de cada dividendo de la tabla de amotizacion

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| am_operacion | int | 4   | NOT NULL | &nbsp;Número interno de operación de cartera |
| am_dividendo | smallint | 2   | NOT NULL | &nbsp;Número del dividendo |
| am_concepto | catalogo | 10  | NOT NULL | &nbsp;Código del concepto, rubro |
| am_estado | tinyint | 1   | NOT NULL | &nbsp;Estado del concepto<br><br>0 = NO VIGENTE<br><br>1 = VIGENTE<br><br>5=<br><br>10=<br><br>11=<br><br>4 = Castigado<br><br>3 = Cancelado |
| am_periodo | tinyint | 1   | NOT NULL | 0 = periodo actual<br><br>1 = periodo anterior |
| am_cuota | money | 8   | NOT NULL | &nbsp;Monto del concepto |
| am_gracia | money | 8   | NOT NULL | &nbsp;Monto de gracia |
| am_pagado | money | 8   | NOT NULL | &nbsp;Monto cancelado del rubro |
| am_acumulado | money | 8   | NOT NULL | &nbsp;Monto acumulado/devengado |
| am_secuencia | tinyint | 1   | NOT NULL | &nbsp;Secuencia de valor de concepto |

### ca_amortizacion_his

Tabla histórica donde se almacena la información de los rubros (conceptos) y montos que forman parte de cada dividendo de la tabla de amotizacion

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| amh_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| amh_secuencial | int | 4   | NOT NULL | Secuencial para registrar el histórico |
| amh_dividendo | smallint | 2   | NOT NULL | Número del dividendo |
| amh_concepto | catalogo | 10  | NOT NULL | Código del concepto, rubro |
| amh_secuencia | tinyint | 1   | NOT NULL | Secuencial del registro |
| amh_estado | tinyint | 1   | NOT NULL | Estado del concepto<br><br>0 = no vigente<br><br>1 = Normal<br><br>2 = vencido<br><br>3 = Cancelado<br><br>……. |
| amh_periodo | tinyint | 1   | NOT NULL | Identificación de periodo<br><br>0 = periodo actual<br><br>1 = periodo anterior |
| amh_cuota | money | 8   | NOT NULL | Monto del concepto |
| amh_gracia | money | 8   | NOT NULL | Monto de gracia |
| amh_pagado | money | 8   | NOT NULL | Monto cancelado del rubro |
| amh_acumulado | money | 8   | NOT NULL | Monto acumulado/devengado |

### ca_amortizacion_tmp

Tabla temporal de trabajo donde se almacena la información de los rubros (conceptos) y montos que forman parte de cada dividendo de la tabla de amotizacion

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCION** |
| --- | --- | --- | --- | --- |
| amt_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| amt_dividendo | smallint | 2   | NOT NULL | Número del dividendo |
| amt_concepto | catalogo | 10  | NOT NULL | Código del concepto, rubro |
| amt_secuencia | tinyint | 1   | NOT NULL | Secuencial del registro |
| amt_estado | tinyint | 1   | NOT NULL | Estado del concepto<br><br>0 = no vigente<br><br>1 = Normal<br><br>2 = vencido<br><br>3 = Cancelado<br><br>……. |
| amt_periodo | tinyint | 1   | NOT NULL | Identificación de periodo<br><br>0 = periodo actual<br><br>1 = periodo anterior |
| amt_cuota | money | 8   | NOT NULL | Monto del concepto |
| amt_gracia | money | 8   | NOT NULL | Monto de gracia |
| amt_pagado | money | 8   | NOT NULL | Monto cancelado del rubro |
| amt_acumulado | money | 8   | NOT NULL | Monto acumulado/devengado |

### ca_ciclo

Esta tabla se utiliza para créditos solidarios o grupales y tiene información de control del ciclo de cada credito

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCION** |
| --- | --- | --- | --- | --- |
| ci_grupo | int | 4   | NOT NULL | &nbsp;Código de grupo |
| ci_operacion | int | 4   | NOT NULL | &nbsp;Número interno de la operación |
| ci_ciclo | int | 4   | NULL | &nbsp;Número de ciclo |
| ci_tciclo | char | 1   | NULL | &nbsp;Tipo de ciclo |
| ci_prestamo | varchar | 15  | NOT NULL | &nbsp;Número externo de la operación |
| ci_tramite | int | 4   | NOT NULL | &nbsp;Número de tramite |
| ci_cuenta_aho_grupal | varchar | 16  | NULL | &nbsp;Numero de cuenta de ahorro grupal |
| ci_titular_cta | int | 4   | NULL | &nbsp;Titular de la cuenta 1 |
| ci_titular_cta2 | int | 4   | NULL | &nbsp;Titular de la cuenta 2 |
| ci_debito_cta_grupal | char | 1   | NULL | &nbsp;Acepta debitos de la cuenta grupal<br><br>S= SI<br><br>N= NO |
| ci_fecha_ini | datetime | 8   | NULL | &nbsp;Fecha de inicio |
| ci_monto_ahorro | money | 8   | NULL | &nbsp;Monto de ahorro |

### ca_cliente_calificacion

Tabla donde se almacena la información de la calificación del cliente

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| ca_ente | int | 4   | NOT NULL | Código del cliente |
| ca_fecha_calif | datetime | 8   | NULL | Fecha de calificación |
| ca_puntos_operacion | float | 8   | NULL | Cantidad de puntos de la operación |
| ca_tipo_cliente | char | 5   | NULL | Tipo de cliente |

### ca_concepto

Almacena los conceptos (rubros) de cartera con sus códigos

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| co_concepto | catalogo | 10  | NOT NULL | Código del concepto/rubro |
| co_descripcion | descripcion | 160 | NOT NULL | Descripción del concepto |
| co_codigo | tinyint | 1   | NOT NULL | Código asignado al concepto |
| co_categoria | catalogo | 10  | NOT NULL | Código de categoria al que pertenece el concepto |

### ca_conversion

Tabla de control para la impresión de comprobantes de los pagos y desembolsos, los secuenciales se inicializan por año y oficina

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| cv_codigo_ofi | catalogo | 10  | NOT NULL | Código de la oficina |
| cv_operacion | Int | 4   | NOT NULL | Secuencial actual de la operación |
| cv_pago | Int | 4   | NULL | Secuencial actual del pago |
| cv_liquidacion | Int | 4   | NULL | Secuencial actual de la liquidación |
| cv_anio | smallint | 2   | NOT NULL | Número de año para secuenciales |
| cv_oficina | smallint | 2   | NOT NULL | Codigo de oficina para secuenciales |
| cv_pago_masivo | int | 4   | NULL | Identificacion de pagos masivos 1 |

### ca_cuota_adicional

Tabla que registra las cuotas adicionales de una operación

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ca_operacion | Int | 4   | NOT NULL | Número de operación |
| ca_dividendo | smallint | 2   | NOT NULL | Número del dividendo al cual se asocia la cuota adicional |
| ca_cuota | money | 8   | NOT NULL | Valor/monto de la cuota adicional |

### ca_datos_adicionales_pasivas

Tabla de trabajo donde se almacena los datos adicionales de los prestamos de cartera pasiva

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dap_operacion | Int | 4   | NOT NULL | Número de operación |
| dap_linea | Varchar | 25  | NULL | Número de línea de crédito |
| dap_fecha_aut | Datetime | 8   | NULL | Fecha de autorización |
| dap_num_cont | Varchar | 20  | NULL | Número de contrato |
| dap_tipo_acreedor | catalogo | 10  | NULL | Tipo de acreedor |
| dap_numreg_bc | varchar | 25  | NULL | Número de registro de balance contable |
| dap_tipo_deuda | catalogo | 10  | NULL | Tipo de deuda |
| dap_num_aut | varchar | 100 | NULL | Número de autorización |
| dap_num_facilidad | varchar | 25  | NULL | Numero de facilidad |
| dap_forma_reposicion | catalogo | 10  | NULL | Forma de reposición |
| dap_causa_fin_sub | catalogo | 10  | NULL | Causa de fin de operación |
| dap_mercado_obj_fin | catalogo | 10  | NULL | Mercado objetivo |

### ca_datos_adicionales_pasivas_t

Tabla temporal de trabajo donde se almacena los datos adicionales de los prestamos de cartera pasiva

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dat_operacion | int | 4   | NOT NULL | Número de operación |
| dat_linea | varchar | 25  | NULL | Número de línea de crédito |
| dat_fecha_aut | datetime | 8   | NULL | Fecha de autorización |
| dat_num_cont | varchar | 20  | NULL | Número de contrato |
| dat_tipo_acreedor | catalogo | 10  | NULL | Tipo de acreedor |
| dat_numreg_bc | varchar | 25  | NULL | Número de registro de balance contable |
| dat_tipo_deuda | catalogo | 10  | NULL | Tipo de deuda |
| dat_num_aut | varchar | 100 | NULL | Número de autorización |
| dat_num_facilidad | varchar | 25  | NULL | Numero de facilidad |
| dat_forma_reposicion | catalogo | 10  | NULL | Forma de reposición |
| dat_causa_fin_sub | catalogo | 10  | NULL | Causa de fin de operación |
| dat_mercado_obj_fin | catalogo | 10  | NULL | Mercado objetivo |

### ca_decodificador

Descompone por filas y columnas los datos del prestamo préstamo

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dc_user | login | 14  | NOT NULL | Usuario de registro |
| dc_sesn | int | 4   | NOT NULL | Código de la sesión |
| dc_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| dc_fila | int | 4   | NOT NULL | Número de la fila |
| dc_columna | int | 4   | NOT NULL | Número de la columna |
| dc_valor | varchar | 255 | NOT NULL | Valor de los datos de préstamo (Fecha, prestamo) |

### ca_default_toperacion

Parámetros por tipos de operación

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dt_toperacion | catalogo | 10  | NOT NULL | Código del producto de cartera |
| dt_moneda | tinyint | 1   | NOT NULL | Moneda del producto |
| dt_reajustable | char | 1   | NOT NULL | S = es reajustable<br><br>N = No es reajustable |
| dt_periodo_reaj | tinyint | 1   | NULL | Periodo de reajuste |
| dt_reajuste_especial | char | 1   | NULL | Indica el tipo de reajuste especial<br><br>S = Mantener la cuota<br><br>N = Mantener Plazo |
| dt_renovacion | char | 1   | NOT NULL | Indica si el producto permite renovación.<br><br>S = Si<br><br>N = No |
| dt_tipo | char | 1   | NOT NULL | Tipo de operación<br><br>N = préstamo de cartera<br><br>D = descuento de documento<br><br>L = Leasing<br><br>R = Préstamo pasivos<br><br>P = Préstamo int. Prepagado<br><br>(Campo se usa con valor por defecto: N, el resto de clases no se usa en la versión). |
| dt_estado | catalogo | 10  | NULL | V = Vigente<br><br>B = Bloqueado<br><br>X = producto deshabilitado<br><br>C = Cancelado<br><br>E = Eliminado |
| dt_precancelacion | char | 1   | NOT NULL | S = Permite precancelar<br><br>N = No permite precancelar |
| dt_cuota_completa | char | 1   | NOT NULL | Solo paga cuota completa<br><br>S = Si<br><br>N = No |
| dt_tipo_cobro | char | 1   | NOT NULL | Tipo de pago, paga los interés acumulados o proyectados<br><br>A = Acumulado<br><br>P = Proyectado |
| dt_tipo_reduccion | char | 1   | NOT NULL | Tipo de reducción cuando hay pago extraordinario:<br><br>N = Pago Normal<br><br>C = Pago extraordinario con reducción de cuota<br><br>T = Pago extraordinario con reducción de tiempo |
| dt_aceptar_anticipos | char | 1   | NOT NULL | S = Acepta anticipos<br><br>N = No acepta anticipos |
| dt_tipo_aplicacion | char | 1   | NOT NULL | Indica el tipo de aplicación:<br><br>D = Horizontal (Por cuotas)<br><br>C = Vertical (Por rubros) |
| dt_tplazo | catalogo | 10  | NOT NULL | Tipo de plazo<br><br>M = Mensual<br><br>A = anual |
| dt_plazo | smallint | 2   | NOT NULL | Plazo |
| dt_tdividendo | catalogo | 10  | NOT NULL | Tipo de dividendo<br><br>M = Mensual<br><br>A = anual<br><br>………………….. |
| dt_periodo_cap | smallint | 2   | NOT NULL | Cada cuantos periodos de capital tiene el préstamo |
| dt_periodo_int | smallint | 2   | NOT NULL | Cada cuantos periodos de interés tiene el préstamo |
| dt_gracia_cap | smallint | 2   | NOT NULL | Cuantos periodos de gracia de capital |
| dt_gracia_int | smallint | 2   | NOT NULL | Cuantos periodos de gracia de capital |
| dt_dist_gracia | char | 1   | NOT NULL | Cuando hay periodos de gracia<br><br>N = Paga en primera cuota<br><br>S = distribuir en las cuotas restantes<br><br>M = no pagar, periodos muertos |
| dt_dias_anio | smallint | 2   | NOT NULL | Días para el cálculo de intereses<br><br>360, 365, 366 |
| dt_tipo_amortizacion | catalogo | 10  | NOT NULL | Tipo de amortización<br><br>FRANCESA<br><br>ALEMANA<br><br>MANUAL |
| dt_fecha_fija | char | 1   | NOT NULL | Si el cobro es en fecha fija<br><br>S = SI<br><br>N = NO |
| dt_dia_pago | tinyint | 1   | NOT NULL | Si es en fecha ficha, que día del mes es el día del pago |
| dt_cuota_fija | char | 1   | NOT NULL | Si los pagos son de cuota fija<br><br>S = SI<br><br>N = NO<br><br>CAMPO EN DESUSO |
| dt_dias_gracia | tinyint | 1   | NOT NULL | Días de gracia para mora |
| dt_evitar_feriados | char | 1   | NOT NULL | Si los vencimientos de las cuotas se van a generar evitando feriados<br><br>S = Si evitar feriados<br><br>N = No evita feriados |
| dt_mes_gracia | tinyint | 1   | NOT NULL | Mes(es) de gracia, que no paga cuota, los posibles valores son números del 0 al 12 |
| dt_base_calculo | char | 1   | NULL | Base de cálculo<br><br>E = COMERCIAL<br><br>R = REAL |
| dt_prd_cobis | tinyint | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: 7). Se hereda al campo op_prd_cobis de la tabla ca_operacion |
| dt_dia_habil | char | 1   | NULL | Trabaja en conjunto con el campo dt_evitar_feriados. Establece como fecha de vencimiento al último día hábil antes del feriado si su valor es S, caso contrario establece como fecha de vencimiento al primer día hábil después del feriado. Se hereda al campo op_dia_habil de la tabla ca_operacion |
| dt_recalcular_plazo | char | 1   | NULL | (Campo no se usa en esta versión. Valor por defecto: N). Se hereda al campo op_recalcular_plazo de la tabla ca_operacion |
| dt_usar_tequivalente | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda al campo op_usar_tequivalente de la tabla ca_operación. |
| dt_tipo_redondeo | tinyint | 1   | NULL | (Campo no se usa en esta versión. Valor por defecto: null). Se hereda al campo op_tipo_redondeo de la tabla ca_operacion |
| dt_causacion | char | 1   | NULL | Se lo usa en el cálculo diario de interés para la fórmula lineal o exponencial. Se hereda al campo op_causacion de la tabla ca_operación. Valor por defecto: L. Valores posibles:<br><br>L = Lineal<br><br>E = Exponencial |
| dt_convertir_tasa | char | 1   | NULL | (Campo no se usa en esta versión. Valor por defecto: N). Se hereda al campo op_convertir_tasa de la tabla ca_operación. |
| dt_tipo_linea | catalogo | 10  | NULL | Catálogo Entidad Prestamista (Campo no se usa en la versión. Valor por defecto: 999). Se hereda al campo op_tipo_linea de la tabla ca_operacion |
| dt_subtipo_linea | catalogo | 10  | NULL | Catalogo Programa de Credito (ca_subtipo_linea)<br><br>01 = Quirografarias<br><br>02 = Prendarias<br><br>03 = Factoraje<br><br>04 = Arrendamiento Capitalizable<br><br>05 = Microcréditos<br><br>06 = Otros<br><br>07 = Liquidez a otras Cooperativas<br><br>99 = N/A<br><br>**(Campo no se usa en esta versión. Valor por defecto: 05).** Se hereda al campo op_subtipo_linea de la tabla ca_operación. |
| dt_bvirtual | char | 1   | NULL | (Campo no se usa en esta versión. Valor por defecto: N). Se hereda al campo op_bvirtual de la tabla ca_operación. |
| dt_extracto | char | 1   | NULL | (Campo no se usa en esta versión. Valor por defecto: N). Se hereda al campo op_extracto de la tabla ca_operación. |
| dt_naturaleza | char | 1   | NULL | Indica la naturaleza de la operación.<br><br>A = Activa<br><br>P = Pasiva<br><br>(En la versión solo se usa la naturaleza de tipo Activa). |
| dt_pago_caja | char | 1   | NULL | Indica si el tipo de operación puede recibir pagos por caja. Se hereda al campo op_pago_caja de la tabla ca_operacion |
| dt_nace_vencida | char | 1   | NULL | Iguala la fecha de vencimiento a la fecha de inicio de los dividendos y de la operación. (Campo no se usa en esta versión. Valor por defecto: N). Se hereda al campo op_nace_vencida de la tabla ca_operacion |
| dt_calcula_devolucion | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda al campo op_calcula_devolucion de la tabla ca_operacion |
| dt_categoria | catalogo | 10  | NULL | (Campo no se usa en la versión. Valor por defecto: 1). |
| dt_entidad_convenio | catalogo | 10  | NULL | (Campo no se usa en la versión). Se hereda al campo op_entidad_convenio de la tabla ca_operación. |
| dt_mora_retroactiva | char | 1   | NULL | Posibles valores S, N. Si está en S, genera gracia de mora automática cuando el vencimiento del dividendo cae en fin de semana o feriado. Valor por defecto: N. Se hereda al campo op_mora_retroactiva de la tabla ca_operacion |
| dt_prepago_desde_lavigente | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda al campo op_prepago_desde_lavigente de la tabla ca_operacion |
| dt_dias_anio_mora | smallint | 2   | NULL | Este Campo se lo usa en sp_batch1 para el cálculo diario de interés de mora. Campo no se lo hereda a la tabla ca_operación. Valores posibles: 360, 365. |
| dt_tipo_calif | catalogo | 10  | NULL | (Campo no se usa en la versión) |
| dt_plazo_min | smallint | 2   | NULL | Plazo mínimo |
| dt_plazo_max | smallint | 2   | NULL | Plazo máximo |
| dt_monto_min | money | 8   | NULL | Monto mínimo |
| dt_monto_max | money | 8   | NULL | Monto Máximo |
| dt_clase_sector | catalogo | 10  | NULL | Catálogo de Clase de sector al que pertenece la operación. Los posibles valores vienen del catálogo cr_clase_cartera.<br><br>1 = COMERCIAL<br><br>2 = CONSUMO<br><br>3 = VIVIENDA<br><br>4 = MICROCREDITO |
| dt_clase_cartera | catalogo | 10  | NULL | Catálogo Clasificación de la cartera |
| dt_gar_admisible | char | 1   | NULL | (Campo no se usa en esta versión. Valor por defecto: N) |
| dt_afecta_cupo | char | 1   | NULL | (Campo no se usa en esta versión. Valor por defecto: N) |
| dt_control_dia_pago | char | 1   | NULL | (Campo no se usa en esta versión. Valor por defecto: S). |
| dt_porcen_colateral | float | 8   | NULL | (Campo no se usa en esta versión. Valor por defecto: 0,00). |
| dt_subsidio | char | 1   | NULL | (Campo no se usa en la versión) |
| dt_tipo_prioridad | char | 1   | NULL | (Campo no se usa en la versión) |
| dt_dia_ppago | tinyint | 1   | NULL | (Campo no se usa en la versión) |
| dt_efecto_pago | char | 1   | NULL | (Campo no se usa en la versión) |
| dt_tpreferencial | char | 1   | NULL | (Campo no se usa en la versión) |
| dt_modo_reest | char | 1   | NULL | (Campo no se usa en la versión) |
| dt_cuota_menor | char | 1   | NULL | (Campo no se usa en la versión) |
| dt_fondos_propios | char | 1   | NULL | (Campo no se usa en la versión) |
| dt_admin_individual | char | 1   | NULL | Identificar el manejo de Grupales<br><br>S = Se administra como préstamos individuales<br><br>N = Se administra el padre y los hijos son de referencia. |
| dt_tipo_cartera | catalogo | 10  | NULL | (Campo no se usa en la versión) |
| dt_subtipo_cartera | catalogo | 10  | NULL | (Campo no se usa en la versión) |

### ca_desembolso

Se almacena información detallada de las formas en que se entregara el monto del préstamo al momento de realizar del desembolso al cliente.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dm_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| dm_secuencial | int | 4   | NOT NULL | Secuencial de la operación |
| dm_desembolso | tinyint | 1   | NOT NULL | Secuencial del desembolso |
| dm_producto | catalogo | 10  | NOT NULL | Código de la forma de desembolso |
| dm_cuenta | cuenta | 24  | NULL | Cuando de trata de una cuenta de Cobis es el Código de la cuenta corriente/ahorros donde se realiza el desembolso, Cuando se utiliza en una forma de desembolso Banco Corresponsal o transferencia bancaria, contiene la cuenta del Banco corresponsal/origen. |
| dm_beneficiario | descripcion | 160 | NULL | Beneficiario del desembolso |
| dm_oficina_chg | smallint | 2   | NULL | Oficina de desembolso |
| dm_terminal | descripcion | 160 | NOT NULL | Terminal del usuario que realiza el desembolso |
| dm_dividendo | smallint | 2   | NOT NULL | Número de dividendo (No se utiliza en esta versión) |
| dm_moneda | tinyint | 1   | NOT NULL | Moneda del desembolso |
| dm_monto_mds | money | 8   | NOT NULL | Monto del desembolso |
| dm_monto_mop | money | 8   | NOT NULL | Monto del desembolso en la moneda de la operación |
| dm_monto_mn | money | 8   | NOT NULL | Monto del desembolso en moneda nacional |
| dm_cotizacion_mds | float | 8   | NOT NULL | Cotización de la moneda del desembolso |
| dm_cotizacion_mop | float | 8   | NOT NULL | Cotización de la moneda de la operación |
| dm_tcotizacion_mds | char | 1   | NOT NULL | Tipo de cotización: Normal, Compra o Venta de la moneda del desembolso |
| dm_tcotizacion_mop | char | 1   | NOT NULL | Tipo de cotización: Normal, Compra o Venta de la moneda de la operación |
| dm_estado | char | 3   | NOT NULL | Estado del desembolso<br><br>A = APLICADO<br><br>NA = NOAPLICADO |
| dm_usuario | login | 14  | NOT NULL | Usuario que realiza el desembolso |
| dm_oficina | smallint | 2   | NOT NULL | Oficina origen |
| dm_cod_banco | int | 4   | NULL | Cuando se utiliza en una forma de desembolso Banco Corresponsal o transferencia bancaria, contiene el código del Banco corresponsal/origen. |
| dm_cheque | int | 4   | NULL | Número del cheque |
| dm_fecha | datetime | 8   | NULL | Fecha del desembolso |
| dm_prenotificacion | int | 4   | NULL | Código de la pre notificación. Campo no se usa en esta versión |
| dm_carga | int | 4   | NULL | Registra el secuencial del movimiento bancario (cheque) en el modulo de Bancos. (Para desembolsos Orden de Pago) |
| dm_concepto | varchar | 255 | NULL | Tipo de Concepto / Rubro. Campo no se usa en esta versión |
| dm_valor | money | 8   | NULL | Valor de cheque. Campo no se usa en esta versión |
| dm_ente_benef | int | 4   | NULL | Código del ente beneficiario |
| dm_idlote | int | 4   | NULL | Registra número Transaccional de Banco Corresponsal (Para desembolsos Orden de Pago) |
| dm_pagado | char | 1   | NULL | Indicador si está pagado |
| dm_orden_caja | int | 4   | NULL | Número de la orden de la caja. Campo no se usa en esta versión |
| dm_cruce_restrictivo | char | 1   | NULL | Cruce restrictivo. Campo no se usa en esta versión |
| dm_destino_economico | char | 1   | NULL | Destino económico |
| dm_carta_autorizacion | char | 1   | NULL | Carta de autorización. Campo no se usa en esta versión |
| dm_fecha_ingreso | datetime | 8   | NULL | Fecha de ingreso del desembolso |
| dm_cod_banco_recep | smallint | 2   | NULL | Código de banco receptor, se utiliza cuando la forma de desembolso es por transferencia bancaria. |
| dm_tipo_cta_recep | catalogo | 10  | NULL | Identificación de tipo de cuenta del banco receptor, , se utiliza cuando la forma de desembolso es por transferencia bancaria. Asociado al catálogo "ca_tipo_cuenta_receptor". |
| dm_cta_recep | cuenta | 24  | NULL | Número de cuenta del banco receptor, se utiliza cuando la forma de desembolso es por transferencia bancaria. |

### ca_det_ciclo

Contiene la información detallado de cada uno de los prestamos que forman parte del crédito solidario o grupal

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dc_grupo | int | 4   | NOT NULL | &nbsp;Código del grupo |
| dc_ciclo_grupo | int | 4   | NOT NULL | &nbsp;Ciclo del grupo |
| dc_cliente | int | 4   | NOT NULL | &nbsp;Código del cliente |
| dc_operacion | int | 4   | NOT NULL | &nbsp;Numero interno de la operación |
| dc_referencia_grupal | varchar | 15  | NULL | &nbsp;Código de la operación grupal |
| dc_ciclo | int | 4   | NULL | &nbsp;Número del ciclo |
| dc_tciclo | char | 1   | NULL | &nbsp;Tipo de ciclo |
| dc_saldo_vencido | money | 8   | NULL | &nbsp;Saldo vencido |
| dc_ahorro_ini | money | 8   | NULL | &nbsp;Ahorro inicial |
| dc_ahorro_ini_int | money | 8   | NULL | &nbsp;Ahorro inicial |
| dc_ahorro_voluntario | money | 8   | NULL | &nbsp;Ahorro voluntario |
| dc_incentivos | money | 8   | NULL | &nbsp;Monto de incentivos |
| dc_extras | money | 8   | NULL | &nbsp;Monto de extras |
| dc_devoluciones | money | 8   | NULL | &nbsp;Monto de devoluciones |

### ca_det_trn

Tabla del detalle de la transacción generada en cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dtr_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| dtr_secuencial | int | 4   | NOT NULL | Secuencial por operación de cartera |
| dtr_dividendo | int | 4   | NOT NULL | Número del dividendo |
| dtr_concepto | catalogo | 10  | NOT NULL | Concepto/Rubro afectado por la transacción |
| dtr_estado | tinyint | 1   | NOT NULL | Estado del concepto/rubro |
| dtr_periodo | tinyint | 1   | NOT NULL | Periodo contable del concepto/rubro |
| dtr_codvalor | int | 4   | NOT NULL | Código valor del concepto/rubro |
| dtr_monto | money | 8   | NOT NULL | Monto del concepto/rubro |
| dtr_monto_mn | money | 8   | NOT NULL | Monto en moneda nacional del concepto/rubro |
| dtr_moneda | tinyint | 1   | NOT NULL | Código de la Moneda |
| dtr_cotizacion | float | 8   | NOT NULL | Cotización |
| dtr_tcotizacion | char | 1   | NOT NULL | Tipo de cotización, compra, venta |
| dtr_afectacion | char | 1   | NOT NULL | Afectación contable<br><br>C= CREDITO<br><br>D=DEBITO |
| dtr_cuenta | char | 20  | NOT NULL | Cuenta corriente/ahorros |
| dtr_beneficiario | char | 64  | NOT NULL | Identificación de beneficiario |
| dtr_monto_cont | money | 8   | NOT NULL | Monto contabilizado |

### ca_dividendo

Tabla que contiene información básica de los dividendos de las operaciones

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| di_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| di_dividendo | smallint | 2   | NOT NULL | Número de dividendo o cuota |
| di_fecha_ini | smalldatetime | 4   | NOT NULL | Fecha de inicio del dividendo |
| di_fecha_ven | smalldatetime | 4   | NOT NULL | Fecha final del dividendo |
| di_de_capital | char | 1   | NOT NULL | Si la cuota cobra Capital |
| di_de_interes | char | 1   | NOT NULL | Si la cuota cobra Interés |
| di_gracia | smallint | 2   | NOT NULL | Periodos de gracias |
| di_gracia_disp | smallint | 2   | NOT NULL | Periodos de gracia disponible |
| di_estado | tinyint | 1   | NOT NULL | Estado de la cuota o dividendo<br><br>0 = No vigente<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO |
| di_dias_cuota | Int | 4   | NOT NULL | Días de la cuota |
| di_intento | tinyint | 1   | NOT NULL | Cantidad de intentos. No se usa en esta version, valor por defecto 0. |
| di_prorroga | char | 1   | NOT NULL | Indica si tiene prorroga en su pago<br><br>N = NO. Cantidad de intentos.<br><br>No se usa en esta version, valor por defecto 0. |
| di_fecha_can | smalldatetime | 4   | NULL | Fecha de cancelación de la cuota. Valor por defecto '01/01/1900'. |

### ca_dividendo_his

Tabla que permite registrar posibles errores durante el procesamiento batch de cajas y que apoyan en la posterior revisión técnica u operativa. Tabla histórica que contiene información básica de los dividendos de las operaciones

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dih_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| dih_secuencial | int | 4   | NOT NULL | Código secuencial del histórico |
| dih_dividendo | smallint | 2   | NOT NULL | Número de dividendo o cuota |
| dih_fecha_ini | smalldatetime | 4   | NOT NULL | Fecha de inicio del dividendo |
| dih_fecha_ven | smalldatetime | 4   | NOT NULL | Fecha final del dividendo |
| dih_de_capital | char | 1   | NOT NULL | Si la cuota cobra Capital |
| dih_de_interes | char | 1   | NOT NULL | Si la cuota cobra Interés |
| dih_gracia | smallint | 2   | NOT NULL | Periodos de gracias |
| dih_gracia_disp | smallint | 2   | NOT NULL | Periodos de gracia disponible |
| dih_estado | tinyint | 1   | NOT NULL | Estado de la cuota o dividendo<br><br>0 = No vigente<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO<br><br>4 = CASTIGADO |
| dih_dias_cuota | int | 4   | NOT NULL | Días de la cuota |
| dih_intento | tinyint | 1   | NOT NULL | Cantidad de intentos |
| dih_prorroga | char | 1   | NOT NULL | Indica si tiene prorroga en su pago |
| dih_fecha_can | smalldatetime | 4   | NULL | Fecha de cancelación de la cuota |

### ca_dividendo_tmp

Tabla temporal de trabajo que contiene información básica de los dividendos de las operaciones

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dit_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| dit_dividendo | smallint | 2   | NOT NULL | Número de dividendo o cuota |
| dit_fecha_ini | datetime | 8   | NOT NULL | Fecha de inicio del dividendo |
| dit_fecha_ven | datetime | 8   | NOT NULL | Fecha final del dividendo |
| dit_de_capital | char | 1   | NOT NULL | Si la cuota cobra Capital |
| dit_de_interes | char | 1   | NOT NULL | Si la cuota cobra Interés |
| dit_gracia | smallint | 2   | NOT NULL | Periodos de gracias |
| dit_gracia_disp | smallint | 2   | NOT NULL | Periodos de gracia disponible |
| dit_estado | tinyint | 1   | NOT NULL | Estado de la cuota o dividendo<br><br>0 = No vigente<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO<br><br>4 = CASTIGADO |
| dit_dias_cuota | int | 4   | NOT NULL | Días de la cuota |
| dit_intento | tinyint | 1   | NOT NULL | Cantidad de intentos |
| dit_prorroga | char | 1   | NOT NULL | Indica si tiene prorroga en su pago |
| dit_fecha_can | smalldatetime | 4   | NULL | Fecha de cancelación de la cuota |

### ca_errorlog

Tabla que contiene la bitácora de errores de los procesos batch del módulo de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| er_fecha_proc | datetime | 8   | NOT NULL | Fecha de proceso |
| er_error | int | 4   | NULL | Código que identifica el error |
| er_usuario | login | 14  | NULL | Usuario que realiza la transacción |
| er_tran | int | 4   | NULL | Código asignado a la transacción que generó el error |
| er_cuenta | cuenta | 24  | NULL | Código banco del préstamo |
| er_descripcion | varchar | 255 | NULL | Mensaje descriptivo del error |
| er_anexo | varchar | 255 | NULL | Mensaje secundario/complementario del error. |

### ca_estado

Tabla que almacena los diferentes estados que aplican a los préstamos de cartera.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| es_codigo | tinyint | 1   | NOT NULL | Código asignado al estado |
| es_descripcion | descripcion | 160 | NOT NULL | Descripción del estado |
| es_procesa | char | 1   | NOT NULL | Indica si el estado es procesado por le batch de cartera<br><br>S = SI PROCESA<br><br>N = NO PROCESA |
| es_acepta_pago | char | 1   | NULL | Indica si el estado acepta pagos de cartera<br><br>S = SI ACEPTA<br><br>N = NO ACEPTA |

### ca_estados_man

Tabla que almacena la parametrización de los cambios de estados automáticos/manuales por producto.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| em_toperacion | catalogo | 10  | NOT NULL | Tipo de producto de cartera |
| em_tipo_cambio | char | 1   | NOT NULL | Tipo de cambio<br><br>D = POR DIVIDENDO<br><br>M = MANUAL |
| em_estado_ini | tinyint | 1   | NOT NULL | Estado inicial |
| em_estado_fin | tinyint | 1   | NOT NULL | Estado final |
| em_dias_cont | int | 4   | NULL | Días iniciales |
| em_dias_fin | int | 4   | NOT NULL | Días finales |

### ca_oficial_nomina

Tabla que almacena la parametrización de las nóminas de los oficiales.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| on_sec | int | 4   | NOT NULL | Secuencial numérico de la tabla |
| on_user | login | 14  | NOT NULL | Usuario que realiza la acción de insertar registro |
| on_fecha_creacion | datetime | 8   | NOT NULL | Fecha en la que se realizó la inserción del registro |
| on_fecha_real | datetime | 8   | NOT NULL | Fecha en la que se insertó o actualizó el registro |
| on_oficial | smallint | 2   | NOT NULL | Código del oficial |
| on_nomina | varchar | 5   | NOT NULL | Nómina del oficial |
| on_estado | char | 1   | NOT NULL | Estado del registro de nómina.<br><br>A: Activo<br><br>I: Inactivo |

### ca_operacion_datos_adicionales

Tabla que almacena los datos adicionales de una operación relacionados al estado de gestión de cobranza de las operaciones, lo cual indica según el estado si permite o no realizar pagos; también incluye un campo para identificar el grupo contable de acuerdo a las combinaciones de garantías asociadas a un préstamo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| oda_operacion | int | 4   | NOT NULL | Número de operación de cartera. |
| oda_estado_gestion_cobranza | catalogo | 10  | NULL | Catálogo del estado de gestión de cobranza. Los valores vienen del catálogo (ca_estado_gestion_cobranza) |
| oda_aceptar_pagos | char | 1   | NULL | Campo que indica si el estado de gestión de cobranza acepta o no pagos. Este campo puede tomar como valor por defecto un valor del catálogo ca_pago_gestion_cobranza, que está relacionado con el catálogo del campo oda_estado_gestion_cobranza. |
| oda_grupo_contable | catalogo | 10  | NOT NULL | Valores del catálogo: cr_combinacion_gar, el cual contiene el grupo de combinación de garantías asociadas a un préstamo |
| oda_categoria_plazo | catalogo | 10  | NOT NULL | Valores del catalogo: ca_categoria_plazo, el cual identifica sin el préstamo es: L: Largo Plazo, C: Corto Plazo |
| oda_tipo_documento_fiscal | varchar | 3   | NULL | Identifica el tipo de documento fiscal para generar una factura electrónica. Tiene valores del catálogo ca_tipo_documento_fiscal<br><br>CCF: Comprobante de Crédito Fiscal<br><br>FCF: Factura Consumidor Final |

### ca_operacion

Tabla maestra del módulo de cartera, contiene la información principal de los préstamos.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| op_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| op_banco | cuenta | 24  | NOT NULL | Número banco del préstamo |
| op_anterior | cuenta | 24  | NULL | Número banco del préstamo anterior si fue renovación |
| op_migrada | cuenta | 24  | NULL | Número banco del préstamo, información de la migración |
| op_tramite | int | 4   | NULL | Número del trámite asignado |
| op_cliente | int | 4   | NULL | Código MIS del cliente principal del préstamo |
| op_nombre | descripcion | 160 | NULL | Nombre del cliente. |
| op_sector | catalogo | 10  | NOT NULL | Sector del préstamo, (catalogo cr_clase_cartera). |
| op_toperacion | catalogo | 10  | NOT NULL | Tipo de producto de cartera |
| op_oficina | smallint | 2   | NOT NULL | Oficina donde fue dado de alta el préstamo |
| op_moneda | tinyint | 1   | NOT NULL | Moneda del préstamo |
| op_comentario | varchar | 255 | NULL | Cambio de observación para comentarios |
| op_oficial | smallint | 2   | NOT NULL | Código del oficial responsable del préstamo. |
| op_fecha_ini | datetime | 8   | NOT NULL | Fecha de inicio del préstamo. |
| op_fecha_fin | datetime | 8   | NOT NULL | Fecha fin del préstamo |
| op_fecha_ult_proceso | datetime | 8   | NOT NULL | Fecha que indica la última fecha que fue procesado el préstamo en los procesos batch |
| op_fecha_liq | datetime | 8   | NULL | Fecha de la liquidación/desembolso del préstamo |
| op_fecha_reajuste | datetime | 8   | NULL | Fecha del próximo reajuste de intereses |
| op_monto | money | 8   | NOT NULL | Monto solicitado. |
| op_monto_aprobado | money | 8   | NOT NULL | Monto aprobado para ser desembolsado. |
| op_destino | catalogo | 10  | NOT NULL | Catalogo que indica cual es el destino del préstamo |
| op_lin_credito | cuenta | 24  | NULL | Código banco de la línea de crédito, indica si el préstamo está asociado a una línea/cupo. |
| op_ciudad | int | 4   | NOT NULL | Código de la ciudad donde se ha ingresado el préstamo |
| op_estado | tinyint | 1   | NOT NULL | Catalogo que indica el estado actual del préstamo<br><br>0 = NO VIGENTE<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO<br><br>4 = CASTIGADO<br><br>5 = JUDICIAL<br><br>6 = ANULADO<br><br>7 = CONDONADO<br><br>8 = DIFERIDO<br><br>9 = SUSPENSO<br><br>99 = EN CREDITO<br><br>66 = GRUPAL VIGENTE |
| op_periodo_reajuste | smallint | 2   | NULL | Cada cuantos periodos reajusta |
| op_reajuste_especial | char | 1   | NULL | Si posee reajuste especial<br><br>S = SI<br><br>N = NO |
| op_tipo | char | 1   | NOT NULL | Clase del préstamo<br><br>N = PRESTAMO DE CARTERA<br><br>L = LEASING<br><br>D = DESCUENTO DOCUMENTO<br><br>P = PRESTAMO INTERESES PREPAGADOS<br><br>R = PRESTAMO PASIVO<br><br>(Campo se usa con valor por defecto: N, el resto de clases no se usa en la versión). |
| op_forma_pago | catalogo | 10  | NULL | Catalogo que indica como cancela el cliente las cuotas.<br><br>Valores posibles:<br><br>NULL, No se utiliza en la versión.<br><br>'C' => si al aplicar la forma de pago automática el valor lo aplica por cuota.<br><br>'R' => si al aplicar la forma de pago automática el valor lo aplica por rubro. Es decir en la forma de pago automática solo aplica al rubro definido.<br><br>'M' => si al aplicar la forma de pago automática el valor lo aplica por monto. |
| op_cuenta | cuenta | 24  | NULL | Si es debito en cuenta indica este campo el número de la cuenta |
| op_dias_anio | smallint | 2   | NOT NULL | Días para cálculo de intereses:<br><br>360, 365, 366 |
| op_tipo_amortizacion | varchar | 10  | NOT NULL | Tipo de tabla de amortización entre FRANCESA, ALEMANA, MANUAL. |
| op_cuota_completa | char | 1   | NOT NULL | Si paga cuota completa o no<br><br>S = SI<br><br>N = NO |
| op_tipo_cobro | char | 1   | NOT NULL | Si paga intereses acumulados o proyectados<br><br>A =Paga acumulados<br><br>P =Paga proyectados |
| op_tipo_reduccion | char | 1   | NOT NULL | Si paga cuotas adelantadas que tipo de reducción aplica<br><br>C = Reducción de monto de cuota<br><br>T = Reducción de tiempo<br><br>N = No aplica reducción |
| op_aceptar_anticipos | char | 1   | NOT NULL | Si acepta pagos anticipados<br><br>S = SI<br><br>N =NO |
| op_precancelacion | char | 1   | NOT NULL | Si el préstamo permite precancelación<br><br>S = SI<br><br>N =NO |
| op_tipo_aplicacion | char | 1   | NOT NULL | Tipo de aplicación:<br><br>D = Aplica por dividendo<br><br>C = Aplica por concepto |
| op_tplazo | catalogo | 10  | NULL | Tipo de plazo<br><br>M = mensual<br><br>A = anual<br><br>S = semestral<br><br>T = trimestral<br><br>B = bimestral<br><br>Q = quincenal<br><br>W = semanal<br><br>D = diario |
| op_plazo | smallint | 2   | NULL | Plazo dado de acuerdo al tipo de plazo |
| op_tdividendo | catalogo | 10  | NULL | Tipo de cuota<br><br>Tipo de plazo<br><br>M = Mensual<br><br>A = anual<br><br>………………….. |
| op_periodo_cap | smallint | 2   | NULL | Cada cuantas cuotas paga capital |
| op_periodo_int | smallint | 2   | NULL | Cada cuantas cuotas paga interés |
| op_dist_gracia | char | 1   | NULL | Si tiene distribución de gracia<br><br>S = SI<br><br>N =NO |
| op_gracia_cap | smallint | 2   | NULL | Si tiene gracia de capital<br><br>S = SI<br><br>N =NO |
| op_gracia_int | smallint | 2   | NULL | Si tiene gracia de interés<br><br>S = SI<br><br>N =NO |
| op_dia_fijo | tinyint | 1   | NULL | Si paga en día fijo almacena el número del día del mes |
| op_cuota | money | 8   | NULL | Monto de la cuota pactada. |
| op_evitar_feriados | char | 1   | NULL | Si las cuotas ha sido generadas evitando los días feriados<br><br>S = SI<br><br>N =NO |
| op_num_renovacion | tinyint | 1   | NULL | Indica el número de renovaciones que ha tenido el préstamo |
| op_renovacion | char | 1   | NULL | Indica si permite renovación<br><br>S = SI<br><br>N =NO |
| op_mes_gracia | tinyint | 1   | NOT NULL | Indica el número del mes de gracia, en este mes no se pone a disposición el cobro de cuota |
| op_reajustable | char | 1   | NOT NULL | Indica si el préstamo es reajustable de intereses<br><br>S = SI<br><br>N =NO<br><br>F = FLOTANTE |
| op_dias_clausula | int | 4   | NOT NULL | Contiene el valor de scoring que se asigna a la operación mediante el proceso Batch de carga de scoring interno |
| op_divcap_original | smallint | 2   | NULL | Dividendo del capital original. No se utiliza en esta versión, valor por defecto NULL. |
| op_clausula_aplicada | char | 1   | NULL | Indica si tiene clausula a aplicar (S/N). No se utiliza en esta versión, valor por defecto = 'N'. |
| op_traslado_ingresos | char | 1   | NULL | Indica si tiene traslados de ingresos. No se utiliza en esta versión, valor por defecto = 'N'. |
| op_periodo_crecimiento | smallint | 2   | NULL | No se utiliza en esta versión, valor por defecto = 0 (cero). |
| op_tasa_crecimiento | float | 8   | NULL | No se utiliza en esta versión, valor por defecto = 0 (cero). |
| op_direccion | tinyint | 1   | NULL | Código de dirección. No se utiliza en esta versión, valor por defecto = NULL. |
| op_opcion_cap | char | 1   | NULL | Indica si hay tasa para capital. No se utiliza en esta versión, valor por defecto = 'N'. |
| op_tasa_cap | float | 8   | NULL | Contiene la TEA de la operación. |
| op_dividendo_cap | smallint | 2   | NULL | Código del dividendo capital. No se utiliza en esta versión, valor por defecto = 'NULL'. |
| op_clase | catalogo | 10  | NOT NULL | Código de los tipos de clase de cartera (catalogo cr_clase_cartera) |
| op_origen_fondos | catalogo | 10  | NULL | Se hereda desde XSell del catálogo cr_origen_fondo, Valor por defecto: 1 (Fondo propio) |
| op_calificacion | char | 1   | NULL | Calificación del préstamo<br><br>Catálogo cr_calificacion |
| op_estado_cobranza | catalogo | 10  | NULL | Estado de la cobranza. No se utiliza en esta versión, valor por defecto = NULL. |
| op_numero_reest | int | 4   | NOT NULL | Cantidad de reajustes que tiene el préstamo. |
| op_edad | int | 4   | NULL | Edad del préstamo. No se utiliza en esta versión, valor por defecto = 1. |
| op_tipo_crecimiento | char | 1   | NULL | Tipo de crecimiento del préstamo. No se utiliza en esta versión, valor por defecto = "A". |
| op_base_calculo | char | 1   | NULL | Indica el tipo de base de cálculo |
| op_prd_cobis | tinyint | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: 7). Se hereda del campo dt_prd_cobis de la tabla ca_default_toperacion. |
| op_ref_exterior | cuenta | 24  | NULL | Referencia del préstamo del exterior. No se utiliza en esta versión, valor por defecto = NULL. |
| op_sujeta_nego | char | 1   | NULL | Indica si esta sujeta a negociación (S/N). No se utiliza en esta versión, valor por defecto = 'N'. |
| op_dia_habil | char | 1   | NULL | Trabaja en conjunto con el campo op_evitar_feriados. Establece como fecha de vencimiento al último día hábil antes del feriado si su valor es S, caso contrario establece como fecha de vencimiento al primer día hábil después del feriado. Se hereda del campo dt_dia_habil de la tabla ca_default_toperacion. |
| op_recalcular_plazo | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_recalcular_plazo de la tabla ca_default_toperacion. |
| op_usar_tequivalente | char | 1   | NULL | Indica si se puede usar tasa equivalente. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_usar_tequivalente de la tabla ca_default_toperacion |
| op_fondos_propios | char | 1   | NOT NULL | Indica si tiene fondos propios |
| op_nro_red | varchar | 24  | NULL | Indica el número de red. No se utiliza en esta versión, valor por defecto = NULL. |
| op_tipo_redondeo | tinyint | 1   | NULL | Se hereda del campo dt_tipo_redondeo de la tabla ca_default_toperacion. No se utiliza en esta versión, valor por defecto = NULL. |
| op_sal_pro_pon | money | 8   | NULL | Valor del saldo. (No se usa en esta versión)<br><br>valor por defecto = NULL. |
| op_tipo_empresa | catalogo | 10  | NULL | Código de tipo de empresa<br><br>Se utiliza el catálogo ca_tipo_empresa. No se utiliza en esta versión, valor por defecto = NULL. |
| op_validacion | catalogo | 10  | NULL | Código de tipo de validación<br><br>Se relaciona con el catálogo ca_validacion<br><br>COLUMNA EN DESUSO |
| op_fecha_pri_cuot | datetime | 8   | NULL | Fecha de vencimiento de primera cuota. |
| op_gar_admisible | char | 1   | NULL | Indica si admite o no garantías. No se utiliza en esta versión |
| op_causacion | char | 1   | NULL | Se lo usa en el cálculo diario de interés para la fórmula lineal o exponencial. Se hereda del campo dt_causacion de la tabla ca_default_toperacion. Valores posibles:<br><br>L = Lineal<br><br>E = Exponencial<br><br>Valor por defecto: L |
| op_convierte_tasa | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_convertir_tasa de la tabla ca_default_toperacion. |
| op_grupo_fact | int | 4   | NULL | Código del grupo de facturación. No se utiliza en esta versión, valor por defecto = NULL. |
| op_tramite_ficticio | int | 4   | NULL | Código del tramite ficticio. No se utiliza en esta versión, valor por defecto = NULL. |
| op_tipo_linea | catalogo | 10  | NULL | Código del tipo de línea (ca_tipo_linea). (Campo no se usa en la versión. Valor por defecto: '999'). Se hereda del campo dt_tipo_linea de la tabla ca_default_toperacion |
| op_subtipo_linea | catalogo | 10  | NULL | Catalogo Programa de Credito (ca_subtipo_linea)<br><br>01 = Quirografarias<br><br>02 = Prendarias<br><br>03 = Factoraje<br><br>04 = Arrendamiento Capitalizable<br><br>05 = Microcréditos<br><br>06 = Otros<br><br>07 = Liquidez a otras Cooperativas<br><br>99 = N/A<br><br>(Campo no se usa en esta versión. Valor por defecto: '05'). Se hereda del campo dt_subtipo_linea de la tabla ca_default_toperacion. |
| op_bvirtual | char | 1   | NULL | Indica si se puede ver en medios virtuales. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_bvirtual de la tabla ca_default_toperacion. |
| op_extracto | char | 1   | NULL | Indica si se pueden generar extractos. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_extracto de la tabla ca_default_toperacion. |
| op_num_deuda_ext | cuenta | 24  | NULL | Código de número de deuda externa (banco segundo piso). No se utiliza en esta versión, valor por defecto = NULL. |
| op_fecha_embarque | datetime | 8   | NULL | Fecha de embarque<br><br>COLUMNA EN DESUSO. No se utiliza en esta versión, valor por defecto = NULL. |
| op_fecha_dex | datetime | 8   | NULL | Fecha DEX<br><br>COLUMNA EN DESUSO. No se utiliza en esta versión, valor por defecto = NULL. |
| op_reestructuracion | char | 1   | NULL | Indica si hubo reestructuración |
| op_tipo_cambio | char | 1   | NULL | Indica si hubo tipo de cambio. No se utiliza en esta versión, valor por defecto = NULL. |
| op_naturaleza | char | 1   | NULL | Indica la naturaleza de la operación.<br><br>A = Activa<br><br>P = Pasiva<br><br>En esta versión valor por defecto 'A' |
| op_pago_caja | char | 1   | NULL | Indica si se puede realizar pagos por caja. Se hereda del campo dt_pago_caja de la tabla ca_default_toperacion. |
| op_nace_vencida | char | 1   | NULL | Iguala la fecha de vencimiento a la fecha de inicio de los dividendos y de la operación. (Campo no se usa en esta versión. Valor por defecto: N). Se hereda del campo dt_nace_vencida de la tabla ca_default_toperacion |
| op_num_comex | cuenta | 24  | NULL | Código de la operación de comercio exterior. No se utiliza en esta versión, valor por defecto = NULL. |
| op_calcula_devolucion | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_calcula_devolucion de la tabla ca_default_toperacion |
| op_codigo_externo | cuenta | 24  | NULL | Código externo banco segundo piso. No se utiliza en esta versión, valor por defecto = NULL. |
| op_margen_redescuento | float | 8   | NULL | Valor del margen de redescuento. No se utiliza en esta versión, valor por defecto = NULL. |
| op_entidad_convenio | catalogo | 10  | NULL | Código de la entidad convenio. (Campo no se usa en la versión). Se hereda del campo dt_entidad_convenio de la tabla ca_default_toperacion. No se utiliza en esta versión, valor por defecto = NULL |
| op_pproductor | char | 1   | NULL | Indica si el préstamo es de un productor. No se utiliza en esta versión, valor por defecto = NULL. |
| op_fecha_ult_causacion | datetime | 8   | NULL | Fecha de ultima causación . No se utiliza en esta versión, valor por defecto = NULL. |
| op_mora_retroactiva | char | 1   | NULL | Posibles valores S, N. Si está en S, genera gracia de mora automática cuando el vencimiento del dividendo cae en fin de semana o feriado. Valor por defecto: N. Se hereda del campo dt_mora_retroactiva de la tabla ca_default_toperacion. |
| op_calificacion_ant | char | 1   | NULL | Indica la calificación anterior |
| op_cap_susxcor | money | 8   | NULL | Valor de la capitalización suspendida. <br><br>COLUMNA EN DESUSO |
| op_prepago_desde_lavigente | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_prepago_desde_lavigente de la tabla ca_default_toperacion |
| op_fecha_ult_mov | datetime | 8   | NULL | Fecha en que el prestamo recibio su ultimo pago (cancelacion) |
| op_fecha_prox_segven | datetime | 8   | NULL | Fecha de próximo vencimiento de seguro<br><br>COLUMNA EN DESUSO |
| op_suspendio | char | 1   | NULL | Indica si fue suspendida.<br><br>COLUMNA EN DESUSO |
| op_fecha_suspenso | datetime | 8   | NULL | Fecha de suspenso <br><br>COLUMNA EN DESUSO |
| op_honorarios_cobranza | char | 1   | NULL | Indica si hay honorarios por cobranza <br><br>COLUMNA EN DESUSO |
| op_banca | catalogo | 10  | NULL | Códito de la banca <br><br>COLUMNA EN DESUSO |
| op_promocion | char | 1   | NULL | Indica si hay promoción <br><br>COLUMNA EN DESUSO |
| op_acepta_ren | char | 1   | NULL | Indica si hay aceptación de renovación |
| op_no_acepta | varchar | 1000 | NULL | Comentario porque no acepta <br><br>COLUMNA EN DESUSO |
| op_emprendimiento | char | 1   | NULL | Código de emprendimiento.<br><br>COLUMNA EN DESUSO |
| op_valor_cat | float | 8   | NULL | Contiene la TIR de la operación. |
| op_grupo | int | 4   | NULL | Código de Grupo al que pertenece el préstamo. |
| op_ref_grupal | cuenta | 24  | NULL | Número largo de banco padre al que pertenecen las operacines hijas. |
| op_grupal | char | 1   | NULL | Indica si pertenece a un grupo |
| op_fondeador | tinyint | 1   | NULL | Código del fondeador <br><br>COLUMNA EN DESUSO |
| op_admin_individual | char | 1   | NULL | Tipo de administración de operaciones grupales que contiene la definición al momento de crear la operación de si el tipo de préstamo grupal se administra por la operación padre o por las operaciones hijas.<br><br>S = Admin operación hija<br><br>N = Admin operación padre |
| op_estado_hijas | char | 1   | NULL | Indica el estado de las operaciones hijas asociadas a una operación grupal. Aplica solo a la operación padre, I=Ingresadas, P=Procesadas. |
| op_tipo_renovacion | char | 1   | NULL | Si la operación fue Renovada o Refinanciada. Catalogo "ca_tipo_renovacion".<br><br>R: Renovacion<br><br>F: Refinanciamiento |
| op_tipo_reest | char | 1   | NULL | Tipos de reestructuacion /modificación de la operación.<br><br>"N"= CAP<br><br>"S" = CAP e INT<br><br>"T" = TODO |
| op_fecha_reest | datetime | 8   | NULL | Fecha cuando se aplico modificación de la operación de tipo reestructuración. |
| op_fecha_reest_noestandar | datetime | 8   | NULL | Fecha cuando se aplico modificación de la operación de tipo diferimiento u otro.<br><br>COLUMNA EN DESUSO |

### ca_operacion_his

Tabla histórica que almacena la información maestra de los préstamos de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| oph_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| oph_secuencial | int | 4   | NOT NULL | Secuencial del histórico por operación |
| oph_banco | cuenta | 24  | NOT NULL | Número banco del préstamo anterior si fue renovación |
| oph_anterior | cuenta | 24  | NULL | Número banco del préstamo anterior si fue renovación |
| oph_migrada | cuenta | 24  | NULL | Número banco del préstamo, información de la migración |
| oph_tramite | int | 4   | NULL | Número del trámite asignado |
| oph_cliente | int | 4   | NULL | Código MIS del cliente principal del préstamo |
| oph_nombre | descripcion | 160 | NULL | Nombre del cliente |
| oph_sector | catalogo | 10  | NOT NULL | Sector del préstamo (catalogo cr_clase_cartera) |
| oph_toperacion | catalogo | 10  | NOT NULL | Tipo de producto de cartera |
| oph_oficina | smallint | 2   | NOT NULL | Oficina donde fue dado de alta el préstamo |
| oph_moneda | tinyint | 1   | NOT NULL | Moneda del préstamo |
| oph_comentario | varchar | 255 | NULL | Cambio de observación para comentarios |
| oph_oficial | smallint | 2   | NOT NULL | Código del oficial |
| oph_fecha_ini | datetime | 8   | NOT NULL | Fecha de inicio del préstamo |
| oph_fecha_fin | datetime | 8   | NOT NULL | Fecha fin del préstamo |
| oph_fecha_ult_proceso | datetime | 8   | NOT NULL | Fecha que indica la última fecha que fue procesado el préstamo en los procesos batch |
| oph_fecha_liq | datetime | 8   | NULL | Fecha de la liquidación/desembolso del préstamo |
| oph_fecha_reajuste | datetime | 8   | NULL | Fecha del próximo reajuste de intereses |
| oph_monto | money | 8   | NOT NULL | Monto solicitado |
| oph_monto_aprobado | money | 8   | NOT NULL | Monto aprobado para ser desembolsado |
| oph_destino | catalogo | 10  | NOT NULL | Catalogo que indica cual es el destino del préstamo |
| oph_lin_credito | cuenta | 24  | NULL | Código banco de la línea de crédito, indica si el préstamo está asociado a una línea/cupo. |
| oph_ciudad | int | 4   | NOT NULL | Código de la ciudad donde se ha ingresado el préstamo |
| oph_estado | tinyint | 1   | NOT NULL | Catalogo que indica el estado actual del préstamo<br><br>0 = NO VIGENTE<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO<br><br>4 = CASTIGADO<br><br>5 = JUDICIAL<br><br>6 = ANULADO<br><br>7 = CONDONADO<br><br>8 = DIFERIDO<br><br>9 = SUSPENSO<br><br>99 = EN CREDITO<br><br>66 = GRUPAL VIGENTE |
| oph_periodo_reajuste | smallint | 2   | NULL | Cada cuantos periodos reajusta |
| oph_reajuste_especial | char | 1   | NULL | Si posee reajuste especial<br><br>S = SI<br><br>N = NO |
| oph_tipo | char | 1   | NOT NULL | Clase del préstamo<br><br>N = PRESTAMO DE CARTERA<br><br>L = LEASING<br><br>D = DESCUENTO DOCUMENTO<br><br>P = PRESTAMO INTERESES PREPAGADOS<br><br>R = PRESTAMO PASIVO<br><br>(Campo se usa con valor por defecto: N, el resto de clases no se usa en la versión). |
| oph_forma_pago | catalogo | 10  | NULL | Catalogo que indica como cancela el cliente las cuotas, en efectivo, debito en cuenta, etc. |
| oph_cuenta | cuenta | 24  | NULL | Si es debito en cuenta indica este campo el número de la cuenta |
| oph_dias_anio | smallint | 2   | NOT NULL | Días para cálculo de intereses:<br><br>360, 365, 366 |
| oph_tipo_amortizacion | varchar | 10  | NOT NULL | FRANCESA, ALEMANA, MANUAL |
| oph_cuota_completa | char | 1   | NOT NULL | Si paga cuota completa o no<br><br>S = SI<br><br>N = NO |
| oph_tipo_cobro | char | 1   | NOT NULL | Si paga intereses acumulados o proyectados<br><br>A =Paga acumulados<br><br>P =Paga proyectados |
| oph_tipo_reduccion | char | 1   | NOT NULL | Si paga cuotas adelantadas que tipo de reducción aplica<br><br>C = Reducción de monto de cuota<br><br>T = Reducción de tiempo<br><br>N = No aplica reducción |
| oph_aceptar_anticipos | char | 1   | NOT NULL | Si acepta pagos anticipados<br><br>S = SI<br><br>N =NO |
| oph_precancelacion | char | 1   | NOT NULL | Si el préstamo permite precancelación<br><br>S = SI<br><br>N =NO |
| oph_tipo_aplicacion | char | 1   | NOT NULL | Tipo de aplicación:<br><br>D = Aplica por dividendo<br><br>C = Aplica por concepto |
| oph_tplazo | catalogo | 10  | NULL | Tipo de plazo<br><br>M = mensual<br><br>A = anual<br><br>S = semestral<br><br>T = trimestral<br><br>B = bimestral<br><br>Q = quincenal<br><br>W = semanal<br><br>D = diario |
| oph_plazo | smallint | 2   | NULL | Plazo dado de acuerdo al tipo de plazo |
| oph_tdividendo | catalogo | 10  | NULL | Tipo de cuota<br><br>Tipo de plazo<br><br>M = Mensual<br><br>A = anual<br><br>………………….. |
| oph_periodo_cap | smallint | 2   | NULL | Cada cuantas cuotas paga capital |
| oph_periodo_int | smallint | 2   | NULL | Cada cuantas cuotas paga interés |
| oph_dist_gracia | char | 1   | NULL | Si tiene distribución de gracia<br><br>S = SI<br><br>N =NO |
| oph_gracia_cap | smallint | 2   | NULL | Si tiene gracia de capital<br><br>S = SI<br><br>N =NO |
| oph_gracia_int | smallint | 2   | NULL | Si tiene gracia de interés<br><br>S = SI<br><br>N =NO |
| oph_dia_fijo | tinyint | 1   | NULL | Si paga en día fijo almacena el número del día del mes |
| oph_cuota | money | 8   | NULL | Monto de la cuota pactada |
| oph_evitar_feriados | char | 1   | NULL | Si las cuotas ha sido generadas evitando los días feriados<br><br>S = SI<br><br>N =NO |
| oph_num_renovacion | tinyint | 1   | NULL | Indica el número de renovaciones que ha tenido el préstamo |
| oph_renovacion | char | 1   | NULL | Indica si permite renovación<br><br>S = SI<br><br>N =NO |
| oph_mes_gracia | tinyint | 1   | NOT NULL | Indica el número del mes de gracia, en este mes no se pone a disposición el cobro de cuota |
| oph_reajustable | char | 1   | NOT NULL | Indica si el préstamo es reajustable de intereses<br><br>S = SI<br><br>N =NO |
| oph_dias_clausula | int | 4   | NOT NULL | Cantidad de días de la clausula |
| oph_divcap_original | smallint | 2   | NULL | Dividendo del capital original |
| oph_clausula_aplicada | char | 1   | NULL | Indica si tiene clausula a aplicar (S/N) |
| oph_traslado_ingresos | char | 1   | NULL | Indica si tiene traslados de ingresos |
| oph_periodo_crecimiento | smallint | 2   | NULL | Código de periodo de crecimiento |
| oph_tasa_crecimiento | float | 8   | NULL | Columna en desuso |
| oph_direccion | tinyint | 1   | NULL | Código de dirección |
| oph_opcion_cap | char | 1   | NULL | Indica si hay tasa para capital |
| oph_tasa_cap | float | 8   | NULL | Valor de la tasa capital |
| oph_dividendo_cap | smallint | 2   | NULL | Código del dividendo capital |
| oph_clase | catalogo | 10  | NOT NULL | Código de la clase de cartera (catalogo cr_clase_cartera) |
| oph_origen_fondos | catalogo | 10  | NULL | Se hereda desde XSell del catálogo cr_origen_fondos, Valor por defecto: 1 (Fondo propio). |
| oph_calificacion | char | 1   | NULL | Calificacion del préstamo |
| oph_estado_cobranza | catalogo | 10  | NULL | Estado de la cobranza |
| oph_numero_reest | int | 4   | NOT NULL | Cantidad de reajustes que tiene el préstamo |
| oph_edad | int | 4   | NULL | Edad del préstamo |
| oph_tipo_crecimiento | char | 1   | NULL | Tipo de crecimiento del préstamo |
| oph_base_calculo | char | 1   | NULL | Indica el tipo de base de cálculo. |
| oph_prd_cobis | tinyint | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: 7). Se hereda del campo dt_prd_cobis de la tabla ca_default_toperacion. |
| oph_ref_exterior | cuenta | 24  | NULL | Referencia del préstamo del exterior |
| oph_sujeta_nego | char | 1   | NULL | Indica si esta sujeta a negociación (S/N) |
| oph_dia_habil | char | 1   | NULL | Trabaja en conjunto con el campo oph_evitar_feriados. Establece como fecha de vencimiento al último día hábil antes del feriado si su valor es S, caso contrario establece como fecha de vencimiento al primer día hábil después del feriado. Se hereda del campo dt_dia_habil de la tabla ca_default_toperacion. |
| oph_recalcular_plazo | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_recalcular_plazo de la tabla ca_default_toperacion. |
| oph_usar_tequivalente | char | 1   | NULL | Indica si se puede usar tasa equivalente. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_usar_tequivalente de la tabla ca_default_toperacion. |
| oph_fondos_propios | char | 1   | NOT NULL | Indica si tiene fondos propios |
| oph_nro_red | varchar | 24  | NULL | Indica el número de red |
| oph_tipo_redondeo | tinyint | 1   | NULL | Código de tipo de redondeo |
| oph_sal_pro_pon | money | 8   | NULL | Valor del saldo |
| oph_tipo_empresa | catalogo | 10  | NULL | Código de tipo de empresa |
| oph_validacion | catalogo | 10  | NULL | Código de tipo de validación |
| oph_fecha_pri_cuot | datetime | 8   | NULL | Fecha de primera cuota |
| oph_gar_admisible | char | 1   | NULL | Indica si admite garantías |
| oph_causacion | char | 1   | NULL | Se lo usa en el cálculo diario de interés para la fórmula lineal o exponencial. Se hereda del campo dt_causacion de la tabla ca_default_toperacion. Valor por defecto: L. Valores posibles:<br><br>L = Lineal<br><br>E = Exponencial |
| oph_convierte_tasa | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_convertir_tasa de la tabla ca_default_toperacion. |
| oph_grupo_fact | int | 4   | NULL | Código del grupo de facturación |
| oph_tramite_ficticio | int | 4   | NULL | Código del tramite ficticio |
| oph_tipo_linea | catalogo | 10  | NULL | Código del tipo de línea (ca_tipo_linea). (Campo no se usa en la versión. Valor por defecto: 999). Se hereda del campo dt_tipo_linea de la tabla ca_default_toperacion. |
| oph_subtipo_linea | catalogo | 10  | NULL | Catalogo Programa de Credito (ca_subtipo_linea)<br><br>01 = Quirografarias<br><br>02 = Prendarias<br><br>03 = Factoraje<br><br>04 = Arrendamiento Capitalizable<br><br>05 = Microcréditos<br><br>06 = Otros<br><br>07 = Liquidez a otras Cooperativas<br><br>99 = N/A<br><br>**(Campo no se usa en esta versión. Valor por defecto: 05).** Se hereda del campo dt_subtipo_linea de la tabla ca_default_toperacion. |
| oph_bvirtual | char | 1   | NULL | Indica si se puede ver en medios virtuales. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_bvirtual de la tabla ca_default_toperacion. |
| oph_extracto | char | 1   | NULL | Indica si se pueden generar extractos. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_extracto de la tabla ca_default_toperacion. |
| oph_num_deuda_ext | cuenta | 24  | NULL | Código de número de deuda externa (banco segundo piso) |
| oph_fecha_embarque | datetime | 8   | NULL | Fecha embarque |
| oph_fecha_dex | datetime | 8   | NULL | Fecha DEX |
| oph_reestructuracion | char | 1   | NULL | Indica si hubo reestructuración |
| oph_tipo_cambio | char | 1   | NULL | Indica si hubo tipo de cambio |
| oph_naturaleza | char | 1   | NULL | Indica la naturaleza de la operación.<br><br>A = Activa<br><br>P = Pasiva |
| oph_pago_caja | char | 1   | NULL | Indica si se puede realizar pagos por caja. Se hereda del campo dt_pago_caja de la tabla ca_default_toperacion. |
| oph_nace_vencida | char | 1   | NULL | Iguala la fecha de vencimiento a la fecha de inicio de los dividendos y de la operación. (Campo no se usa en esta versión. Valor por defecto: N). Se hereda del campo dt_nace_vencida de la tabla ca_default_toperacion. |
| oph_num_comex | cuenta | 24  | NULL | Código de la operación de comercio exterior |
| oph_calcula_devolucion | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_calcula_devolucion de la tabla ca_default_toperacion |
| oph_codigo_externo | cuenta | 24  | NULL | Código externo banco segundo piso |
| oph_margen_redescuento | float | 8   | NULL | Valor del margen de redescuento |
| oph_entidad_convenio | catalogo | 10  | NULL | Código de la entidad convenio. (Campo no se usa en la versión). Se hereda del campo dt_entidad_convenio de la tabla ca_default_toperacion. |
| oph_pproductor | char | 1   | NULL | Indica si el préstamo es de un productor |
| oph_fecha_ult_causacion | datetime | 8   | NULL | Fecha de ultima causación |
| oph_mora_retroactiva | char | 1   | NULL | Posibles valores S, N. Si está en S, genera gracia de mora automática cuando el vencimiento del dividendo cae en fin de semana o feriado. Valor por defecto: N. Se hereda del campo dt_mora_retroactiva de la tabla ca_default_toperacion. |
| oph_calificacion_ant | char | 1   | NULL | Indica la calificación anterior |
| oph_cap_susxcor | money | 8   | NULL | Valor de la capitalización suspendida. |
| oph_prepago_desde_lavigente | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_prepago_desde_lavigente de la tabla ca_default_toperacion |
| oph_fecha_ult_mov | datetime | 8   | NULL | Fecha de ultimo movimiento (batch) |
| oph_fecha_prox_segven | datetime | 8   | NULL | Fecha de próximo vencimiento de seguro |
| oph_suspendio | char | 1   | NULL | Indica si fue suspendida |
| oph_fecha_suspenso | datetime | 8   | NULL | Fecha de suspenso |
| oph_honorarios_cobranza | char | 1   | NULL | Indica si hay honorarios por cobranza |
| oph_banca | catalogo | 10  | NULL | Códito de la banca |
| oph_promocion | char | 1   | NULL | Indica si hay promoción |
| oph_acepta_ren | char | 1   | NULL | Indica si hay aceptación de renovación |
| oph_no_acepta | varchar | 1000 | NULL | Comentario porque no acepta |
| oph_emprendimiento | char | 1   | NULL | Código de emprendimiento |
| oph_valor_cat | float | 8   | NULL | Contiene la TIR de la operación. |
| oph_grupo | int | 4   | NULL | Código de Grupo |
| oph_ref_grupal | cuenta | 24  | NULL | Número largo de banco padre al que pertenecen las operacines hijas. |
| oph_grupal | char | 1   | NULL | Indica si pertenece a un grupo |
| oph_fondeador | tinyint | 1   | NULL | Código del fondeador |
| oph_admin_individual | char | 1   | NULL | Tipo de administración de operaciones grupales que contiene la definición al momento de crear la operación de si el tipo de préstamo grupal se administra por la operación padre o por las operaciones hijas.<br><br>S = Admin operación hija<br><br>N = Admin operación padre |
| oph_estado_hijas | char | 1   | NULL | Indica el estado de las operaciones hijas asociadas a una operación grupal. |
| oph_tipo_renovacion | char | 1   | NULL | Si la operación fue Renovada o Refinanciada. Catalogo "ca_tipo_renovacion".<br><br>R: Renovacion<br><br>F: Refinanciamiento |
| oph_tipo_reest | char | 1   | NULL | Tipos de reestructuacion /modificación de la operación. |
| oph_fecha_reest | datetime | 8   | NULL | Fecha cuando se aplico modificación de la operación de tipo reestructuración. |
| oph_fecha_reest_noestandar | datetime | 8   | NULL | Fecha cuando se aplico modificación de la operación de tipo diferimiento u otro. |

### ca_operacion_datos_adicionales_tmp

Tabla temporal que almacena los datos adicionales de una operación relacionados al estado de gestión de cobranza de las operaciones, lo cual indica según el estado si permite o no realizar pagos; también incluye un campo para identificar el grupo contable de acuerdo a las combinaciones de garantías asociadas a un préstamo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| odt_operacion | int | 4   | NOT NULL | Número de operación de cartera. |
| odt_estado_gestion_cobranza | catalogo | 10  | NULL | Catálogo del estado de gestión de cobranza. Los valores vienen del catálogo (ca_estado_gestion_cobranza) |
| odt_aceptar_pagos | char | 1   | NULL | Campo que indica si el estado de gestión de cobranza acepta o no pagos. Este campo puede tomar como valor por defecto un valor del catálogo ca_pago_gestion_cobranza, que está relacionado con el catálogo del campo oda_estado_gestion_cobranza. |
| odt_grupo_contable | catalogo | 10  | NOT NULL | Valores del catálogo: cr_combinacion_gar, el cual contiene el grupo de combinación de garantías asociadas a un préstamo |
| odt_categoria_plazo | catalogo | 10  | NOT NULL | Valores del catalogo: ca_categoria_plazo, el cual identifica sin el préstamo es: L: Largo Plazo, C: Corto Plazo |
| odt_tipo_documento_fiscal | varchar | 3   | NULL | Identifica el tipo de documento fiscal para generar una factura electrónica. Tiene valores del catálogo ca_tipo_documento_fiscal<br><br>CCF: Comprobante de Crédito Fiscal<br><br>FCF: Factura Consumidor Final |

### ca_operacion_tmp

Tabla temporal de trabajo utilizada para almacenar la información maestra de los préstamos de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| opt_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| opt_banco | cuenta | 24  | NOT NULL | Número banco del préstamo |
| opt_anterior | cuenta | 24  | NULL | Número banco del préstamo anterior si fue renovación |
| opt_migrada | cuenta | 24  | NULL | Número banco del préstamo, información de la migración |
| opt_tramite | int | 4   | NULL | Número del trámite asignado |
| opt_cliente | int | 4   | NULL | Código MIS del cliente principal del préstamo |
| opt_nombre | descripcion | 160 | NULL | Nombre del cliente |
| opt_sector | catalogo | 10  | NOT NULL | Sector del préstamo (catalogo cr_clase_cartera) |
| opt_toperacion | catalogo | 10  | NOT NULL | Tipo de producto de cartera |
| opt_oficina | smallint | 2   | NOT NULL | Oficina donde fue dado de alta el préstamo |
| opt_moneda | tinyint | 1   | NOT NULL | Moneda del préstamo |
| opt_comentario | varchar | 255 | NULL | Cambio de observación para comentarios |
| opt_oficial | smallint | 2   | NOT NULL | Código del oficial |
| opt_fecha_ini | datetime | 8   | NOT NULL | Fecha de inicio del préstamo |
| opt_fecha_fin | datetime | 8   | NOT NULL | Fecha fin del préstamo |
| opt_fecha_ult_proceso | datetime | 8   | NOT NULL | Fecha que indica la última fecha que fue procesado el préstamo en los procesos batch |
| opt_fecha_liq | datetime | 8   | NULL | Fecha de la liquidación/desembolso del préstamo |
| opt_fecha_reajuste | datetime | 8   | NULL | Fecha del próximo reajuste de intereses |
| opt_monto | money | 8   | NOT NULL | Monto solicitado |
| opt_monto_aprobado | money | 8   | NOT NULL | Monto aprobado para ser desembolsado |
| opt_destino | catalogo | 10  | NOT NULL | Catalogo que indica cual es el destino del préstamo |
| opt_lin_credito | cuenta | 24  | NULL | Código banco de la línea de crédito, indica si el préstamo está asociado a una línea/cupo. |
| opt_ciudad | int | 4   | NOT NULL | Código de la ciudad donde se ha ingresado el préstamo |
| opt_estado | tinyint | 1   | NOT NULL | Catalogo que indica el estado actual del préstamo<br><br>0 = NO VIGENTE<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO<br><br>4 = CASTIGADO<br><br>5 = JUDICIAL<br><br>6 = ANULADO<br><br>7 = CONDONADO<br><br>8 = DIFERIDO<br><br>9 = SUSPENSO<br><br>99 = EN CREDITO<br><br>66 = GRUPAL VIGENTE |
| opt_periodo_reajuste | smallint | 2   | NULL | Cada cuantos periodos reajusta |
| opt_reajuste_especial | char | 1   | NULL | Si posee reajuste especial<br><br>S = SI<br><br>N = NO |
| opt_tipo | char | 1   | NOT NULL | Clase del préstamo<br><br>N = PRESTAMO DE CARTERA<br><br>L = LEASING<br><br>D = DESCUENTO DOCUMENTO<br><br>P = PRESTAMO INTERESES PREPAGADOS<br><br>R = PRESTAMO PASIVO<br><br>(Campo se usa con valor por defecto: N, el resto de clases no se usa en la versión). |
| opt_forma_pago | catalogo | 10  | NULL | Catalogo que indica como cancela el cliente las cuotas, en efectivo, debito en cuenta, etc. |
| opt_cuenta | cuenta | 24  | NULL | Si es debito en cuenta indica este campo el número de la cuenta |
| opt_dias_anio | smallint | 2   | NOT NULL | Días para cálculo de intereses:<br><br>360, 365, 366 |
| opt_tipo_amortizacion | varchar | 10  | NOT NULL | FRANCESA, ALEMANA, MANUAL |
| opt_cuota_completa | char | 1   | NOT NULL | Si paga cuota completa o no<br><br>S = SI<br><br>N = NO |
| opt_tipo_cobro | char | 1   | NOT NULL | Si paga intereses acumulados o proyectados<br><br>A =Paga acumulados<br><br>P =Paga proyectados |
| opt_tipo_reduccion | char | 1   | NOT NULL | Si paga cuotas adelantadas que tipo de reducción aplica<br><br>C = Reducción de monto de cuota<br><br>T = Reducción de tiempo<br><br>N = No aplica reducción |
| opt_aceptar_anticipos | char | 1   | NOT NULL | Si acepta pagos anticipados<br><br>S = SI<br><br>N =NO |
| opt_precancelacion | char | 1   | NOT NULL | Si el préstamo permite precancelación<br><br>S = SI<br><br>N =NO |
| opt_tipo_aplicacion | char | 1   | NOT NULL | Tipo de aplicación:<br><br>D = Aplica por dividendo<br><br>C = Aplica por concepto |
| opt_tplazo | catalogo | 10  | NULL | Tipo de plazo<br><br>M = mensual<br><br>A = anual<br><br>S = semestral<br><br>T = trimestral<br><br>B = bimestral<br><br>Q = quincenal<br><br>W = semanal<br><br>D = diario |
| opt_plazo | smallint | 2   | NULL | Plazo dado de acuerdo al tipo de plazo |
| opt_tdividendo | catalogo | 10  | NULL | Tipo de cuota<br><br>Tipo de plazo<br><br>M = Mensual<br><br>A = anual<br><br>………………….. |
| opt_periodo_cap | smallint | 2   | NULL | Cada cuantas cuotas paga capital |
| opt_periodo_int | smallint | 2   | NULL | Cada cuantas cuotas paga interés |
| opt_dist_gracia | char | 1   | NULL | Si tiene distribución de gracia<br><br>S = SI<br><br>N =NO |
| opt_gracia_cap | smallint | 2   | NULL | Si tiene gracia de capital<br><br>S = SI<br><br>N =NO |
| opt_gracia_int | smallint | 2   | NULL | Si tiene gracia de interés<br><br>S = SI<br><br>N =NO |
| opt_dia_fijo | tinyint | 1   | NULL | Si paga en día fijo almacena el número del día del mes |
| opt_cuota | money | 8   | NULL | Monto de la cuota pactada |
| opt_evitar_feriados | char | 1   | NULL | Si las cuotas ha sido generadas evitando los días feriados<br><br>S = SI<br><br>N =NO |
| opt_num_renovacion | tinyint | 1   | NULL | Indica el número de renovaciones que ha tenido el préstamo |
| opt_renovacion | char | 1   | NULL | Indica si permite renovación<br><br>S = SI<br><br>N =NO |
| opt_mes_gracia | tinyint | 1   | NOT NULL | Indica el número del mes de gracia, en este mes no se pone a disposición el cobro de cuota |
| opt_reajustable | char | 1   | NOT NULL | Indica si el préstamo es reajustable de intereses<br><br>S = SI<br><br>N =NO |
| opt_dias_clausula | int | 4   | NOT NULL | Cantidad de días de la clausula |
| opt_divcap_original | smallint | 2   | NULL | Dividendo del capital original |
| opt_clausula_aplicada | char | 1   | NULL | Indica si tiene clausula a aplicar (S/N) |
| opt_traslado_ingresos | char | 1   | NULL | Indica si tiene traslados de ingresos |
| opt_periodo_crecimiento | smallint | 2   | NULL | Código de periodo de crecimiento |
| opt_tasa_crecimiento | float | 8   | NULL | Columna en desuso |
| opt_direccion | tinyint | 1   | NULL | Código de dirección |
| opt_opcion_cap | char | 1   | NULL | Indica si hay tasa para capital |
| opt_tasa_cap | float | 8   | NULL | Contiene la TEA de la operación |
| opt_dividendo_cap | smallint | 2   | NULL | Código del dividendo capital |
| opt_clase | catalogo | 10  | NOT NULL | Código de la clase de cartera (catalogo cr_clase_cartera) |
| opt_origen_fondos | catalogo | 10  | NULL | Se hereda desde XSell del catálogo cr_origen_fondos, Valor por defecto: 1 (Fondo propio) |
| opt_calificacion | char | 1   | NULL | Calificacion del préstamo |
| opt_estado_cobranza | catalogo | 10  | NULL | Estado de la cobranza |
| opt_numero_reest | int | 4   | NOT NULL | Cantidad de reajustes que tiene el préstamo |
| opt_edad | int | 4   | NULL | Edad del préstamo |
| opt_tipo_crecimiento | char | 1   | NULL | Tipo de crecimiento del préstamo |
| opt_base_calculo | char | 1   | NULL | Indica el tipo de base de cálculo |
| opt_prd_cobis | tinyint | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: 7). Se hereda del campo dt_prd_cobis de la tabla ca_default_toperacion. |
| opt_ref_exterior | cuenta | 24  | NULL | Referencia del préstamo del exterior |
| opt_sujeta_nego | char | 1   | NULL | Indica si esta sujeta a negociación (S/N) |
| opt_dia_habil | char | 1   | NULL | Trabaja en conjunto con el campo opt_evitar_feriados. Establece como fecha de vencimiento al último día hábil antes del feriado si su valor es S, caso contrario establece como fecha de vencimiento al primer día hábil después del feriado. Se hereda del campo dt_dia_habil de la tabla ca_default_toperacion. |
| opt_recalcular_plazo | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_recalcular_plazo de la tabla ca_default_toperacion. |
| opt_usar_tequivalente | char | 1   | NULL | Indica si se puede usar tasa equivalente. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_usar_tequivalente de la tabla ca_default_toperacion. |
| opt_fondos_propios | char | 1   | NOT NULL | Indica si tiene fondos propios |
| opt_nro_red | varchar | 24  | NULL | Indica el número de red |
| opt_tipo_redondeo | tinyint | 1   | NULL | Código de tipo de redondeo |
| opt_sal_pro_pon | money | 8   | NULL | Valor del saldo |
| opt_tipo_empresa | catalogo | 10  | NULL | Código de tipo de empresa |
| opt_validacion | catalogo | 10  | NULL | Código de tipo de validación |
| opt_fecha_pri_cuot | datetime | 8   | NULL | Fecha de primera cuota |
| opt_gar_admisible | char | 1   | NULL | Indica si admite garantías |
| opt_causacion | char | 1   | NULL | Se lo usa en el cálculo diario de interés para la fórmula lineal o exponencial. Se hereda del campo dt_causacion de la tabla ca_default_toperacion. Valor por defecto: L. Valores posibles:<br><br>L = Lineal<br><br>E = Exponencial |
| opt_convierte_tasa | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_convertir_tasa de la tabla ca_default_toperacion. |
| opt_grupo_fact | int | 4   | NULL | Código del grupo de facturación |
| opt_tramite_ficticio | int | 4   | NULL | Código del tramite ficticio |
| opt_tipo_linea | catalogo | 10  | NULL | Código del tipo de línea (ca_tipo_linea). (Campo no se usa en la versión. Valor por defecto: 999). Se hereda del campo dt_tipo_linea de la tabla ca_default_toperacion. |
| opt_subtipo_linea | catalogo | 10  | NULL | Catalogo Programa de Credito (ca_subtipo_linea)<br><br>01 = Quirografarias<br><br>02 = Prendarias<br><br>03 = Factoraje<br><br>04 = Arrendamiento Capitalizable<br><br>05 = Microcréditos<br><br>06 = Otros<br><br>07 = Liquidez a otras Cooperativas<br><br>99 = N/A<br><br>**(Campo no se usa en esta versión. Valor por defecto: 05).** Se hereda del campo dt_subtipo_linea de la tabla ca_default_toperacion. |
| opt_bvirtual | char | 1   | NULL | Indica si se puede ver en medios virtuales. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_bvirtual de la tabla ca_default_toperacion. |
| opt_extracto | char | 1   | NULL | Indica si se pueden generar extractos. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_extracto de la tabla ca_default_toperacion. |
| opt_num_deuda_ext | cuenta | 24  | NULL | Código de número de deuda externa (banco segundo piso) |
| opt_fecha_embarque | datetime | 8   | NULL | Fecha embarque |
| opt_fecha_dex | datetime | 8   | NULL | Fecha DEX |
| opt_reestructuracion | char | 1   | NULL | Indica si hubo reestructuración |
| opt_tipo_cambio | char | 1   | NULL | Indica si hubo tipo de cambio |
| opt_naturaleza | char | 1   | NULL | Indica la naturaleza de la operación.<br><br>A = Activa<br><br>P = Pasiva |
| opt_pago_caja | char | 1   | NULL | Indica si se puede realizar pagos por caja. Se hereda del campo dt_pago_caja de la tabla ca_default_toperacion |
| opt_nace_vencida | char | 1   | NULL | Iguala la fecha de vencimiento a la fecha de inicio de los dividendos y de la operación. (Campo no se usa en esta versión. Valor por defecto: N). Se hereda del campo dt_nace_vencida de la tabla ca_default_toperacion. |
| opt_num_comex | cuenta | 24  | NULL | Código de la operación de comercio exterior |
| opt_calcula_devolucion | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_calcula_devolucion de la tabla ca_default_toperacion. |
| opt_codigo_externo | cuenta | 24  | NULL | Código externo banco segundo piso |
| opt_margen_redescuento | float | 8   | NULL | Valor del margen de redescuento |
| opt_entidad_convenio | catalogo | 10  | NULL | Código de la entidad convenio. (Campo no se usa en la versión). Se hereda del campo dt_entidad_convenio de la tabla ca_default_toperacion. |
| opt_pproductor | char | 1   | NULL | Indica si el préstamo es de un productor |
| opt_fecha_ult_causacion | datetime | 8   | NULL | Fecha de ultima causación |
| opt_mora_retroactiva | char | 1   | NULL | Posibles valores S, N. Si está en S, genera gracia de mora automática cuando el vencimiento del dividendo cae en fin de semana o feriado. Valor por defecto: N. Se hereda del campo dt_mora_retroactiva de la tabla ca_default_toperacion. |
| opt_calificacion_ant | char | 1   | NULL | Indica la calificación anterior |
| opt_cap_susxcor | money | 8   | NULL | Valor de la capitalización suspendida. |
| opt_prepago_desde_lavigente | char | 1   | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_prepago_desde_lavigente de la tabla ca_default_toperacion |
| opt_fecha_ult_mov | datetime | 8   | NULL | Fecha de ultimo movimiento (batch) |
| opt_fecha_prox_segven | datetime | 8   | NULL | Fecha de próximo vencimiento de seguro |
| opt_suspendio | char | 1   | NULL | Indica si fue suspendida |
| opt_fecha_suspenso | datetime | 8   | NULL | Fecha de suspenso |
| opt_honorarios_cobranza | char | 1   | NULL | Indica si hay honorarios por cobranza |
| opt_banca | catalogo | 10  | NULL | Códito de la banca |
| opt_promocion | char | 1   | NULL | Indica si hay promoción |
| opt_acepta_ren | char | 1   | NULL | Indica si hay aceptación de renovación |
| opt_no_acepta | varchar | 1000 | NULL | Comentario porque no acepta |
| opt_emprendimiento | char | 1   | NULL | Código de emprendimiento |
| opt_valor_cat | float | 8   | NULL | Contiene la TIR de la operación. |
| opt_grupo | int | 4   | NULL | Código de Grupo |
| opt_ref_grupal | cuenta | 24  | NULL | Número largo de banco padre al que pertenecen las operacines hijas. |
| opt_grupal | char | 1   | NULL | Pertenece a un grupo |
| opt_fondeador | tinyint | 1   | NULL | Código del fondeador |
| opt_admin_individual | char | 1   | NULL | Tipo de administración de operaciones grupales que contiene la definición al momento de crear la operación de si el tipo de préstamo grupal se administra por la operación padre o por las operaciones hijas.<br><br>S = Admin operación hija<br><br>N = Admin operación padre |
| opt_estado_hijas | char | 1   | NULL | Indica el estado de las operaciones hijas asociadas a una operación grupal. |
| opt_tipo_renovacion | char | 1   | NULL | Si la operación fue Renovada o Refinanciada. Catalogo "ca_tipo_renovacion".<br><br>R: Renovacion<br><br>F: Refinanciamiento |
| opt_tipo_reest | char | 1   | NULL | Tipos de reestructuacion /modificación de la operación. |
| opt_fecha_reest | datetime | 8   | NULL | Fecha cuando se aplico modificación de la operación de tipo reestructuración. |
| opt_fecha_reest_noestandar | datetime | 8   | NULL | Fecha cuando se aplico modificación de la operación de tipo diferimiento u otro. |

### ca_otro_cargo

Tabla que almacena por cada operación el ingreso de cargos adicionales al préstamo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| oc_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| oc_secuencial | int | 4   | NOT NULL | Secuencial interno por operación |
| oc_fecha | datetime | 8   | NOT NULL | Fecha de ingreso del cargo |
| oc_concepto | catalogo | 10  | NOT NULL | Concepto/rubro parametrizado como otro cargo |
| oc_monto | money | 8   | NOT NULL | Monto del cargo |
| oc_referencia | descripcion | 64  | NULL | Descripción del motivo del ingreso del rubro de otros cargos |
| oc_usuario | login | 14  | NOT NULL | Usuario que realiza la transacción |
| oc_oficina | smallint | 2   | NOT NULL | Oficina donde se realiza la transacción |
| oc_terminal | varchar | 20  | NOT NULL | Terminal (PC) donde se realiza la transacción |
| oc_estado | catalogo | 10  | NOT NULL | Estado del registro<br><br>A = APLICADO<br><br>NA = NO APLICADO |
| oc_div_desde | smallint | 2   | NULL | Dividendo desde donde se aplica el ingreso de cargo |
| oc_div_hasta | smallint | 2   | NULL | Dividendo hasta donde se aplica el ingreso de cargo |
| oc_base_calculo | money | 8   | NULL | Indica la base de calculo del cargo. |
| oc_secuencial_cxp | int | 4   | NULL | No utilizado en esta version |

### ca_param_cargos_gestion_cobranza

Tabla de parametrización que contiene las reglas para el ingreso de valor de cobranza cuando un préstamo genera mora. El valor del cargo depende de la cantidad de días de vencimiento de la cuota más antigua y del monto de mora genera.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| cgc_monto_mora_desde | money | 8   | NULL | Monto inicial de mora (Inicio del rango) |
| cgc_monto_mora_hasta | money | 8   | NULL | Monto final de mora (Final del rango) |
| cgc_dias_mora_desde | int | 4   | NULL | Dia inicial de mora (Inicio del rango) |
| cgc_dias_mora_hasta | int | 4   | NULL | Día final de mora (Final del rango) |
| cgc_valor_cargo | float | 8   | NULL | Valor del cargo de gestión de cobranza en el rango de días y monto |

### ca_producto

Tabla de parametrización que almacena todas las posibles formas de pagos y desembolso a ser aplicadas a un préstamo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| cp_producto | catalogo | 10  | NOT NULL | Código que identifica la forma de cobro o pago |
| cp_descripcion | descripcion | 64  | NOT NULL | Descripción de la forma de cobro/pago |
| cp_categoria | catalogo | 10  | NOT NULL | Código de la categoría, se muestra la información del catálogo cl_cforma |
| cp_moneda | tinyint | 1   | NULL | Moneda asociada a la forma de cobro/pago |
| cp_codvalor | smallint | 2   | NOT NULL | Código valor que asocia la forma de cobro/pago a la contabilidad |
| cp_desembolso | char | 1   | NOT NULL | Indica si aplica en el desembolso<br><br>S = SI<br><br>N =NO |
| cp_pago | char | 1   | NOT NULL | Indica si acepta pagos<br><br>S = SI<br><br>N =NO |
| cp_atx | char | 1   | NOT NULL | Si es un cobro/pago a través de la caja cobis(branch) |
| cp_retencion | tinyint | 1   | NOT NULL | Días de retención |
| cp_pago_aut | char | 1   | NOT NULL | Si es un pago automático para el proceso batch de cartera |
| cp_pcobis | tinyint | 1   | NULL | Código del módulo cobis que está asociado a la forma de cobro/pago |
| cp_producto_reversa | catalogo | 10  | NULL | Código del módulo cobis que está asociado a la reversa |
| cp_afectacion | char | 1   | NULL | Indica el tipo de afectación<br><br>D = Débito<br><br>C = Crédito |
| cp_estado | char | 1   | NULL | Indica el estado en el que se encuentra el producto |
| cp_act_pas | char | 1   | NULL | Indica si es Activa o Pasiva. <br><br>No se usa en Version, Valor por defecto = 'A'. |
| cp_instrum_SB | int | 4   | NULL | Valor del instrumento SBanc.<br><br>No se usa en Version, Valor por defecto = 'NULL'. |
| cp_canal | catalogo | 10  | NULL | Código del canal de recepción.<br><br>No se usa en Version, Valor por defecto = 'NULL'. |

### ca_provision_cartera

Tabla donde se almacena los datos generados por el proceso de provisión de cartera.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| pc_fecha_proceso | datetime | 8   | NOT NULL | Fecha de ejecución del cálculo de provisión. |
| pc_operacion | int | 4   | NOT NULL | Nro. De operación |
| pc_banco | varchar | 24  | NOT NULL | Nro. De Préstamo |
| pc_fult_proceso | datetime | 8   | NOT NULL | Fecha en la que se proceso la operación por última vez. |
| pc_cliente | int | 4   | NOT NULL | Código del cliente |
| pc_nom_cliente | varchar | 96  | NOT NULL | Nombre del Cliente |
| pc_oficina | smallint | 2   | NOT NULL | Código de la oficina del préstamo |
| pc_toperacion | catalogo | 10  | NOT NULL | Tipo de Operación. |
| pc_sector | catalogo | 10  | NOT NULL | Sector de la operación. |
| pc_estado | int | 4   | NOT NULL | Estado de la operación. |
| pc_fecha_ini | datetime | 8   | NOT NULL | Fecha de inicio de la operación |
| pc_fecha_fin | datetime | 8   | NOT NULL | Fecha Fin de la operación |
| pc_monto | money | 8   | NOT NULL | Monto aprobado de la operación |
| pc_plazo | smallint | 2   | NOT NULL | Plazo de la operación |
| pc_tplazo | varchar | 24  | NOT NULL | Tipo de Plazo |
| pc_val_capital | money | 8   | NOT NULL | Valor capital pendiente de pago |
| pc_val_interes | money | 8   | NOT NULL | Valor interes pendiente de pago |
| pc_dias_dev | int | 4   | NOT NULL | Dias de vencimiento |
| pc_cap_vigente | money | 8   | NOT NULL | Valor de capital vigente |
| pc_int_vigente | money | 8   | NOT NULL | Valor de interés vigente |
| pc_cap_vencido | money | 8   | NOT NULL | Valor de capital vencido |
| pc_int_vencido | money | 8   | NOT NULL | Valor de interés vencido |
| pc_tasa | float | 8   | NOT NULL | Tasa interés aplicada al préstamo |
| pc_porc_cap_prov | float | 8   | NOT NULL | Porcentaje de capital a provisionar |
| pc_cap_base_prov | money | 8   | NOT NULL | Capital base a provisionar |
| pc_porc_int_prov | float | 8   | NOT NULL | Porcentaje de interés a provisionar |
| pc_int_base_prov | money | 8   | NOT NULL | Interés base a provisionar |
| pc_porcentaje_prov | float | 8   | NOT NULL | Porcentaje de provisión |
| pc_valor_prov_cap | money | 8   | NOT NULL | Valor provisionado capital |
| pc_valor_prov_int | money | 8   | NOT NULL | Valor provisionado Interés |

### ca_reajuste

Tabla que almacena información de los reajustes por cada operación de cartera.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| re_operacion | int | 4   | NOT NULL | Número interno de operación |
| re_secuencial | int | 4   | NOT NULL | Secuencial de la operación asignado al reajuste |
| re_fecha | datetime | 8   | NOT NULL | Fecha de reajuste |
| re_reajuste_especial | char | 1   | NOT NULL | Si es reajuste especial<br><br>S = SI<br><br>N = NO |
| re_desagio | char | 1   | NULL | Campo no utilizado en esta version |
| re_sec_aviso | int | 4   | NULL | Campo no utilizado en esta version |

### ca_reajuste_det

Almacena el referencial, la tasa y el factor de reajuste por cada operación y concepto (rubro).

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| red_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| red_secuencial | int | 4   | NOT NULL | Secuencial de la operación asignado al reajuste |
| red_concepto | catalogo | 10  | NOT NULL | Concepto/rubro aplicado en el reajuste |
| red_referencial | catalogo | 10  | NULL | Catálogo de la tasa referencial del reajuste |
| red_signo | char | 1   | NULL | Signo de ajuste + - \* / |
| red_factor | float | 8   | NULL | Factor de reajuste |
| red_porcentaje | float | 8   | NULL | Porcentaje de reajuste. |

### ca_registra_traslados_masivos

Tabla que registra información acerca de los préstamos que serán trasladados de oficina u oficial. El contenido de los registros permite identificar los criterios de búsqueda que se aplicó para obtener el/los préstamos para el traslado, además de información de oficina u oficial origen y destino.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| rt_secuencial_traslado | int | 4   | NOT NULL | Secuencial único que identifica cada uno de los traslados realizados. |
| rt_user | login | 14  | NOT NULL | Nombre del usuario que realizó el traslado. |
| rt_rol | int | 4   | NOT NULL | Rol del usuario que realizó el traslado |
| rt_term | varchar | 30  | NOT NULL | Terminal desde donde se realizó el traslado. (Información la manda el CTS). |
| rt_fecha_real | datetime | 8   | NOT NULL | Fecha actual (real) en la que se realizó el traslado. |
| rt_cliente | int | 1   | NULL | Campo que guarda el código del cliente, si se aplicó como criterio de búsqueda de los préstamos para el traslado. |
| rt_banco | varchar | 24  | NULL | Campo que guarda el número de banco del préstamo, si se aplicó como criterio de búsqueda del préstamo para el traslado |
| rt_tramite | int | 4   | NULL | Almacena el número de trámite, si se usó como criterio de búsqueda de los préstamos para el traslado. |
| rt_oficina | smallint | 2   | NULL | Almacena el código de la oficina, si se usó como criterio de búsqueda de los préstamos para el traslado. Se interpreta a este campo como la oficina origen si tiene un valor diferente de vacío. |
| rt_oficial | int | 4   | NULL | Almacena el código del oficial, si se usó como criterio de búsqueda de los préstamos para el traslado. |
| rt_moneda | tinyint | 1   | NULL | Almacena el código de la moneda, si se usó como criterio de búsqueda de los préstamos para el traslado. |
| rt_fecha_ini | datetime | 8   | NULL | Almacena la fecha de inicio o creación del préstamo, si se usó como criterio de búsqueda de los préstamos para el traslado. |
| rt_estado | tinyint | 1   | NULL | Almacena estado de el/los préstamo(s), si se usó como criterio de búsqueda de los préstamos para el traslado. |
| rt_migrada | varchar | 24  | NULL | Almacena el número de operación migrada de el/los préstamo(s), si se usó como criterio de búsqueda de los préstamos para el traslado. |
| rt_tipo_registro | varchar | 24  | NOT NULL | Número Banco del préstamo al cual se realizó el traslado. En el caso que el traslado haya sido de todos los préstamos consultados en la pantalla del contenedor según las condiciones de búsqueda especificadas en las columnas de cliente, banco, tramite, oficina, oficial, moneda, fecha_ini, estado, migrada; el valor de este campo será de -99999. |
| rt_estado_registro | char | 1   | NOT NULL | Identifica el estado del traslado en donde:<br><br>I = Se ingreso el registro de traslado, pero no fue procesado por el batch.<br><br>N = El registro de traslado ya procesado por el batch. |
| rt_oficial_destino | int | 4   | NULL | Código del oficial destino, al cual se realizó el traslado. (Solo aplica para traslado de oficiales). |
| rt_oficina_destino | int | 4   | NULL | Código de la oficina hacia la cual se realizó el traslado de oficina. (Solo aplica para traslado de oficinas). |
| rt_fecha_traslado | datetime | 8   | NOT NULL | Fecha (proceso) en la que se realiza el traslado. (Información la manda el CTS). |
| rt_tipo_traslado | float | 8   | NOT NULL | Identifica que tipo de traslado se realizó.<br><br>F = Oficina<br><br>O = Oficial |
|     |     |     |     |     |

### ca_rubro

Tabla de parametrización que contiene información principal de los rubros (conceptos) utilizados en el módulo de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| ru_toperacion | catalogo | 10  | NOT NULL | Código del tipo de operación de cartera |
| ru_moneda | tinyint | 1   | NOT NULL | Moneda del producto. |
| ru_concepto | catalogo | 10  | NOT NULL | Rubro/concepto asociado al producto. |
| ru_prioridad | tinyint | 1   | NOT NULL | Prioridad de cobro |
| ru_tipo_rubro | catalogo | 10  | NOT NULL | Tipo de rubro:<br><br>C = CAPITAL<br><br>I = INTERES<br><br>M = MORA<br><br>Q = CALCULADO<br><br>O = PORCENTAJE<br><br>V = VALOR FIJO<br><br>Catalogo "fp_tipo_rubro" |
| ru_paga_mora | char | 1   | NOT NULL | Determina si el rubro aplica o no aplica mora.<br><br>S = Cobra Mora<br><br>N = No Cobra Mora |
| ru_provisiona | char | 1   | NOT NULL | Determina si el rubro provisiona o no.<br><br>S = Si Provisiona<br><br>N = No Provisiona |
| ru_fpago | char | 1   | NOT NULL | En que instancia se cobra el rubro:<br><br>L = en la liquidación<br><br>M = Multa/otros cargos<br><br>P = Periódico en las cuotas<br><br>A = Anticipado |
| ru_crear_siempre | char | 1   | NOT NULL | Si al crear la operación se tiene que crear también el rubro<br><br>S = Siempre<br><br>N = No siempre |
| ru_tperiodo | catalogo | 10  | NULL | (Campo en desuso) |
| ru_periodo | smallint | 2   | NULL | (Campo en desuso) |
| ru_referencial | catalogo | 10  | NULL | Catálogo del referencial a aplicar |
| ru_reajuste | catalogo | 10  | NULL | Valor o referencial a aplicar en cambio de tasa |
| ru_banco | char | 1   | NOT NULL | Indica si es para el banco o no (S/N) |
| ru_estado | catalogo | 10  | NOT NULL | Indica el eEstado del rubro<br><br>V = Vigente<br><br>B =Bloqueado<br><br>C =Cancelado<br><br>E = Eliminado<br><br>X = producto deshabilitado |
| ru_concepto_asociado | catalogo | 10  | NULL | Código del Rubro/concepto asociado |
| ru_redescuento | float | 8   | NULL | (Campo en desuso) |
| ru_intermediacion | float | 8   | NULL | (Campo en desuso) |
| ru_principal | char | 1   | NULL | (Campo en desuso) |
| ru_saldo_op | char | 1   | NULL | Sirve para los rubros calculados, "S" = sobre el saldo de capital de la operación |
| ru_saldo_por_desem | char | 1   | NULL | (Campo en desuso) |
| ru_pit | catalogo | 10  | NULL | (Campo en desuso) |
| ru_limite | char | 1   | NULL | Indica si el rubro está diferido o no en el préstamo.<br><br>S = Si<br><br>N = No |
| ru_mora_interes | char | 1   | NULL | (Campo en desuso)<br><br>Valor por defecto = "N" |
| ru_iva_siempre | char | 1   | NULL | Indica si se cobra siempre el iva<br><br>Valor por defecto = "Null" |
| ru_monto_aprobado | char | 1   | NULL | Sirve para rubros calculados, si el cálculo va sobre el monto aprobado solamente |
| ru_porcentaje_cobrar | float | 8   | NULL | (Campo en desuso) |
| ru_tipo_garantia | varchar | 64  | NULL | (Campo en desuso) |
| ru_valor_garantia | char | 1   | NULL | (Campo en desuso) |
| ru_porcentaje_cobertura | char | 1   | NULL | (Campo en desuso) |
| ru_tabla | varchar | 30  | NULL | Indica el nombre del procedimiento almacenado que va a devolver el cálculo/valor para el rubro. |
| ru_saldo_insoluto | char | 1   | NULL | Sirve para rubros calculados, Indica si la base para el cálculo es el saldo insoluto (saldo al momento) |
| ru_calcular_devolucion | char | 1   | NULL | (Campo en desuso) |
| ru_tasa_aplicar | char | 1   | NULL | (Campo en desuso) |
| ru_valor_max | money | 8   | NULL | Valor máximo del rubro |
| ru_valor_min | money | 8   | NULL | Valor mínimo del rubro |
| ru_afectacion | smallint | 2   | NULL | (Campo en desuso) |
| ru_diferir | char | 1   | NULL | (Campo en desuso) |
| ru_tipo_seguro | catalogo | 10  | NULL | (Campo en desuso) |
| ru_tasa_efectiva | char | 1   | NULL | (Campo en desuso) |
| ru_financiado | char | 1   | NULL | Indica si el rubro es financiado o descontado.<br><br>S = Si (Financiado)<br><br>N = No (Descontado) |
| ru_tasa_maxima | float | 8   | NULL | (Campo en desuso) |
| ru_tasa_minima | float | 8   | NULL | (Campo en desuso) |

### ca_rubro_op

Contiene los rubros que están cargados por cada operación de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| ro_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| ro_concepto | catalogo | 10  | NOT NULL | Rubro/Concepto del préstamo |
| ro_tipo_rubro | char | 1   | NOT NULL | Tipo de rubro<br><br>C = CAPITAL<br><br>I = INTERES<br><br>M = MORA<br><br>Q = CALCULADO.<br><br>O = PORCENTAJE<br><br>V = VALOR FIJO |
| ro_fpago | char | 1   | NOT NULL | Catálogo de forma de pago<br><br>L = En la liquidación<br><br>M = Multa/otros cargos<br><br>P = Periódico en las cuotas |
| ro_prioridad | tinyint | 1   | NOT NULL | Prioridad de cobro |
| ro_paga_mora | char | 1   | NOT NULL | Indica si aplica mora<br><br>S = SI<br><br>N = NO |
| ro_provisiona | char | 1   | NOT NULL | Indica si provisiona<br><br>S = SI<br><br>N = NO |
| ro_signo | char | 1   | NULL | Signo de ajuste +, -, \*, / |
| ro_factor | float | 8   | NULL | Porcentaje de ajuste |
| ro_referencial | catalogo | 10  | NULL | Tasa referencial de ajuste |
| ro_signo_reajuste | char | 1   | NULL | Signo para reaajuste +, -, \*, / |
| ro_factor_reajuste | float | 8   | NULL | Porcentaje de reajuste |
| ro_referencial_reajuste | catalogo | 10  | NULL | Tasa referencial de reajuste |
| ro_valor | money | 8   | NOT NULL | Valor/Monto fijo |
| ro_porcentaje | float | 8   | NOT NULL | Porcentaje de la tasa |
| ro_porcentaje_aux | float | 8   | NOT NULL | Porcentaje de la tasa auxiliar, en esta versión va el mismo valor que ro_porcentaje. |
| ro_gracia | money | 8   | NULL | Monto de gracia |
| ro_concepto_asociado | catalogo | 10  | NULL | Rubro/Concepto asociado al concepto principal |
| ro_redescuento | float | 8   | NULL | Valor de redescuento. Campo no se usa en esta versión |
| ro_intermediacion | float | 8   | NULL | Valor de intermediación. Campo no se usa en esta versión |
| ro_principal | char | 1   | NOT NULL | (Campo en desuso) |
| ro_porcentaje_efa | float | 8   | NULL | Porcentaje del EFA (Tasa Efectiva anual) , en esta versión va el mismo valor que ro_porcentaje. |
| ro_garantia | money | 8   | NOT NULL | Valor de la garantía |
| ro_tipo_puntos | char | 1   | NULL | Indica el tipo de puntos, , viene de la tabla ca_valor_det.vd_tipo_puntos<br><br>B: Base<br><br>E: Efectiva |
| ro_saldo_op | char | 1   | NULL | Sirve para los rubros calculados, "S" = sobre el saldo de capital de la operación |
| ro_saldo_por_desem | char | 1   | NULL | (Campo en desuso) |
| ro_base_calculo | money | 8   | NULL | Valor de la base calculo |
| ro_num_dec | tinyint | 1   | NULL | Número de decimales |
| ro_limite | char | 1   | NULL | Indica si el rubro está diferido o no en el préstamo.<br><br>S = Si<br><br>N = No |
| ro_iva_siempre | char | 1   | NULL | Indica si cobrará iva siempre<br><br>Valor por defecto = "N". Campo no se usa en esta versión |
| ro_monto_aprobado | char | 1   | NULL | Sirve para rubros calculados, si el cálculo va sobre el monto aprobado solamente |
| ro_porcentaje_cobrar | float | 8   | NULL | (Campo en desuso) |
| ro_tipo_garantia | varchar | 64  | NULL | (Campo en desuso) |
| ro_nro_garantia | cuenta | 24  | NULL | (Campo en desuso) |
| ro_porcentaje_cobertura | char | 1   | NULL | (Campo en desuso) |
| ro_valor_garantia | char | 1   | NULL | (Campo en desuso) |
| ro_tperiodo | catalogo | 10  | NULL | (Campo en desuso) |
| ro_periodo | smallint | 2   | NULL | (Campo en desuso) |
| ro_tabla | varchar | 30  | NULL | Indica el nombre del procedimiento almacenado que va a devolver el cálculo/valor para el rubro |
| ro_saldo_insoluto | char | 1   | NULL | Sirve para rubros calculados, Indica si la base para el cálculo es el saldo insoluto (saldo al momento) |
| ro_calcular_devolucion | char | 1   | NULL | (Campo en desuso) |
| ro_financiado | char | 1   | NULL | Indica si el rubro es financiado. |
| ro_tasa_maxima | float | 8   | NULL | Valor de la tasa máxima del rubro. Campo en desuso valor por defecto null. |
| ro_tasa_minima | float | 8   | NULL | Valor de la tasa mínima del rubro. Campo en desuso valor por defecto null. |

### ca_rubro_op_his

Tabla histórica que contiene los rubros que están cargados por cada operación de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| roh_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| roh_secuencial | int | 4   | NOT NULL | Secuencial por operación para identificar el histórico |
| roh_concepto | catalogo | 10  | NOT NULL | Rubro/Concepto del préstamo |
| roh_tipo_rubro | char | 1   | NOT NULL | Tipo de rubro<br><br>C = CAPITAL<br><br>F = FECI<br><br>I = INTERES<br><br>M = MORA<br><br>O = PORCENTAJE<br><br>V = VALOR FIJO |
| roh_fpago | char | 1   | NOT NULL | Catálogo de forma de pago<br><br>L = en la liquidación<br><br>M = Multa/otros cargos<br><br>P = Periódico en las cuotas<br><br>A = Anticipado |
| roh_prioridad | tinyint | 1   | NOT NULL | Prioridad de cobro |
| roh_paga_mora | char | 1   | NOT NULL | Si aplica mora<br><br>S = SI<br><br>N = NO |
| roh_provisiona | char | 1   | NOT NULL | Si provisiona<br><br>S = SI<br><br>N = NO |
| roh_signo | char | 1   | NULL | Signo de ajuste +, -, \*, / |
| roh_factor | float | 8   | NULL | Porcentaje de ajuste |
| roh_referencial | catalogo | 10  | NULL | Tasa referencial de ajuste |
| roh_signo_reajuste | char | 1   | NULL | Signo para reajuste +, -, \*, / |
| roh_factor_reajuste | float | 8   | NULL | Porcentaje de reajuste |
| roh_referencial_reajuste | catalogo | 10  | NULL | Tasa referencial de reajuste |
| roh_valor | money | 8   | NOT NULL | Valor/Monto fijo |
| roh_porcentaje | float | 8   | NOT NULL | Porcentaje de la tasa |
| roh_porcentaje_aux | float | 8   | NOT NULL | Porcentaje de la tasa auxiliar |
| roh_gracia | money | 8   | NULL | Monto de gracia |
| roh_concepto_asociado | catalogo | 10  | NULL | Rubro/Concepto asociado al concepto principal |
| roh_redescuento | float | 8   | NULL | Valor de redescuento |
| roh_intermediacion | float | 8   | NULL | Valor de intermediación |
| roh_principal | char | 1   | NOT NULL | Indica si es principal o no |
| roh_porcentaje_efa | float | 8   | NULL | Porcentaje del EFA (Tasa Efectiva anual) |
| roh_garantia | money | 8   | NOT NULL | Valor de la garantía |
| roh_tipo_puntos | char | 1   | NULL | Indica el tipo de puntos |
| roh_saldo_op | char | 1   | NULL | Indica si hay saldo operativo |
| roh_saldo_por_desem | char | 1   | NULL | Indica si hay saldo por desembolso |
| roh_base_calculo | money | 8   | NULL | Valor de base calculo |
| roh_num_dec | tinyint | 1   | NULL | Número de decimales |
| roh_limite | char | 1   | NULL | Indica si tiene limites o no |
| roh_iva_siempre | char | 1   | NULL | Indica si cobrará iva siempre |
| roh_monto_aprobado | char | 1   | NULL | Indica si hay monto aprobado |
| roh_porcentaje_cobrar | float | 8   | NULL | Porcentaje a probar |
| roh_tipo_garantia | varchar | 64  | NULL | Tipo de Garantia |
| roh_nro_garantia | cuenta | 24  | NULL | Número de garantía |
| roh_porcentaje_cobertura | char | 1   | NULL | Indica si la cobertura de garantía es por porcentaje |
| roh_valor_garantia | char | 1   | NULL | Indica si la cobertura de la garantía es por valor |
| roh_tperiodo | catalogo | 10  | NULL | Indica el tipo de periodo |
| roh_periodo | smallint | 2   | NULL | Código de periodo |
| roh_tabla | varchar | 30  | NULL | Indica el tipo de tabla |
| roh_saldo_insoluto | char | 1   | NULL | Indica si hay saldo insoluto |
| roh_calcular_devolucion | char | 1   | NULL | Indica si hay que calcular la devolución. |
| roh_financiado | char | 1   | NULL | Indica si el rubro es financiado. |
| roh_tasa_maxima | float | 8   | NULL | Valor de la tasa máxima del rubro |
| roh_tasa_minima | float | 8   | NULL | Valor de la tasa mínima del rubro |

### ca_rubro_op_tmp

Tabla temporal de trabajo que contiene los rubros que están cargados por cada operación de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| rot_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| rot_concepto | catalogo | 10  | NOT NULL | Rubro/Concepto del préstamo |
| rot_tipo_rubro | char | 1   | NOT NULL | Tipo de rubro<br><br>C = CAPITAL<br><br>I = INTERES<br><br>Q= CALCULADO<br><br>M = MORA<br><br>O = PORCENTAJE<br><br>V = VALOR FIJO |
| rot_fpago | char | 1   | NOT NULL | Catálogo de forma de pago<br><br>L = en la liquidación<br><br>M = Multa/otros cargos<br><br>P = Periódico en las cuotas<br><br>A = Anticipado |
| rot_prioridad | tinyint | 1   | NOT NULL | Prioridad de cobro |
| rot_paga_mora | char | 1   | NOT NULL | Si aplica mora<br><br>S = SI<br><br>N = NO |
| rot_provisiona | char | 1   | NOT NULL | Si provisiona<br><br>S = SI<br><br>N = NO |
| rot_signo | char | 1   | NULL | Signo de ajuste +, -, \*, / |
| rot_factor | float | 8   | NULL | Porcentaje de ajuste |
| rot_referencial | catalogo | 10  | NULL | Tasa referencial de ajuste |
| rot_signo_reajuste | char | 1   | NULL | Signo para reajuste +, -, \*, / |
| rot_factor_reajuste | float | 8   | NULL | Porcentaje de reajuste |
| rot_referencial_reajuste | catalogo | 10  | NULL | Tasa referencial de reajuste |
| rot_valor | money | 8   | NOT NULL | Valor/Monto fijo |
| rot_porcentaje | float | 8   | NOT NULL | Porcentaje de la tasa |
| rot_porcentaje_aux | float | 8   | NOT NULL | Porcentaje de la tasa auxiliar |
| rot_gracia | money | 8   | NULL | Monto de gracia |
| rot_concepto_asociado | catalogo | 10  | NULL | Rubro/Concepto asociado al concepto principal |
| rot_redescuento | float | 8   | NULL | Valor de redescuento |
| rot_intermediacion | float | 8   | NULL | Valor de intermediación |
| rot_principal | char | 1   | NOT NULL | Indica si es principal o no |
| rot_porcentaje_efa | float | 8   | NULL | Porcentaje del EFA (Tasa Efectiva anual) |
| rot_garantia | money | 8   | NOT NULL | Valor de la garantía |
| rot_tipo_puntos | char | 1   | NULL | Indica el tipo de puntos |
| rot_saldo_op | char | 1   | NULL | Indica si hay saldo operativo |
| rot_saldo_por_desem | char | 1   | NULL | Indica si hay saldo por desembolso |
| rot_base_calculo | money | 8   | NULL | Valor de base calculo |
| rot_num_dec | tinyint | 1   | NULL | Número de decimales |
| rot_limite | char | 1   | NULL | Indica si tiene limites o no |
| rot_iva_siempre | char | 1   | NULL | Indica si cobrará iva siempre |
| rot_monto_aprobado | char | 1   | NULL | Indica si hay monto aprobado |
| rot_porcentaje_cobrar | float | 8   | NULL | Porcentaje a probar |
| rot_tipo_garantia | varchar | 64  | NULL | Tipo de Garantia |
| rot_nro_garantia | cuenta | 24  | NULL | Número de garantía |
| rot_porcentaje_cobertura | char | 1   | NULL | Indica si la cobertura de garantía es por porcentaje |
| rot_valor_garantia | char | 1   | NULL | Indica si la cobertura de la garantía es por valor |
| rot_tperiodo | catalogo | 10  | NULL | Indica el tipo de periodo |
| rot_periodo | smallint | 2   | NULL | Código de periodo |
| rot_tabla | varchar | 30  | NULL | Indica el tipo de tabla |
| rot_saldo_insoluto | char | 1   | NULL | Indica si hay saldo insoluto |
| rot_calcular_devolucion | char | 1   | NULL | Indica si hay que calcular la devolución. |
| rot_financiado | char | 1   | NULL | Indica si el rubro es financiado. |
| rot_tasa_maxima | float | 8   | NULL | Valor de la tasa máxima del rubro |
| rot_tasa_minima | float | 8   | NULL | Valor de la tasa mínima del rubro |

### ca_secuencial_atx

Contiene la relación de los secuenciales de cartera con el secuencial de la caja/branch

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| sa_operacion | cuenta | 24  | NULL | Número de operación de cartera |
| sa_ssn_corr | int | 4   | NOT NULL | Código ssn de la transacción ATX |
| sa_producto | catalogo | 10  | NULL | Producto de cartera |
| sa_secuencial_cca | int | 4   | NOT NULL | Secuencial de cartera |
| sa_secuencial_ssn | int | 4   | NULL | Secuencial ssn de atx |
| sa_oficina | smallint | 2   | NULL | Código de oficina Cobis |
| sa_fecha_ing | datetime | 8   | NULL | Fecha de ingreso |
| sa_fecha_real | datetime | 8   | NULL | Fecha real |
| sa_estado | char | 1   | NULL | Estado de la relación |
| sa_ejecutar | char | 1   | NULL | Estado de la ejecución |
| sa_valor_efe | money | 8   | NULL | Valor de Efectivo |
| sa_valor_cheq | money | 8   | NULL | Valor en Cheque |
| sa_error | int | 4   | NULL | Código del error |

### ca_tasas

Tabla que registra por operación la tasa vigente para los rubros que aplican tasa de interés.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| ts_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| ts_dividendo | int | 4   | NOT NULL | Número del dividendo |
| ts_fecha | datetime | 8   | NOT NULL | Fecha de vigencia de la tasa |
| ts_concepto | catalogo | 10  | NOT NULL | Código del rubro/concepto |
| ts_porcentaje | float | 8   | NOT NULL | Porcentaje de la tasa. |
| ts_secuencial | int | 4   | NOT NULL | Secuencial del registro |
| ts_porcentaje_efa | float | 8   | NULL | No utilizado en esta version |
| ts_referencial | catalogo | 10  | NULL | Catálogo del referencial a aplicar |
| ts_signo | char | 1   | NULL | Signo de ajuste +, -, \*, / |
| ts_factor | float | 8   | NULL | Porcentaje de ajuste |
| ts_valor_referencial | float | 8   | NULL | Valor de la tasa referencial |
| ts_fecha_referencial | datetime | 8   | NULL | Fecha de la tasa referencial. |
| ts_tasa_ref | catalogo | 10  | NULL | No utilizado en esta version |

### ca_tasas_tmp

Tabla temporal de trabajo donde se almacena los datos de las tasas que se usan en el módulo de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| spid | smallint | 2   | NOT NULL | Secuencial del proceso |
| va_tipo | varchar | 10  | NULL | Código de tasa |
| va_descripción | varchar | 64  | NULL | Descripción de la tasa |
| vd_referencia | varchar | 10  | NULL | Código de tasa de referencia |
| va_clase | char | 1   | NULL | Tipo de tasa F=Porcentaje V = Valor |
| vd_signo_default | char | 1   | NULL | Código de signo +, - , \*, / |
| vd_valor_default | float | 8   | NULL | Valor de la tasa |
| vd_valor_referencial | float | 8   | NULL | Valor de la tasa referencial |
| vd_aplica_ajuste | char | 1   | NULL | Código de aplica ajuste S/N |
| vd_periodo_ajuste | smallint | 2   | NULL | Número de periodos de ajuste |
|     |     |     |     |     |
|     |     |     |     |     |

### ca_tdividendo

Tabla de parametrización donde se registran los tipos de dividendos utilizados en el módulo, con su correspondiente factor en días

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| td_tdividendo | catalogo | 10  | NOT NULL | Catálogo de tipo de dividendo<br><br>A = ANUAL<br><br>D = DIARIA<br><br>M = MENSUAL<br><br>Q= QUINCENAL<br><br>S = SEMESTRE<br><br>T = TRIMESTRE<br><br>B = BIMESTRE<br><br>W = SEMANAL |
| td_descripcion | descripcion | 64  | NOT NULL | Descripción del tipo de dividendo (D = DIA(S)) |
| td_estado | estado | 1   | NULL | Estado del tipo de dividendo registro<br><br>V = VIGENTE |
| td_factor | smallint | 2   | NOT NULL | Cantidad en días que representa el tipo del dividendo |

### ca_tipo_trn

Tabla de parametrización que registra los tipos de transacciones que se pueden realizar en el módulo

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| tt_codigo | char | 3   | NOT NULL | Código del tipo de transacción<br><br>DES - DESEMBOLSO<br><br>DEV - DEVOLUCIONES A CLIENTES<br><br>EST - CAMBIO DE ESTADO<br><br>ETM - CAMBIO DE ESTADO MANUAL<br><br>FVA - PUNTO DE FECHA VALOR<br><br>IOC - INGRESO DE OTROS CARGOS<br><br>PAG - PAGOS<br><br>PRV - PROVISIONES<br><br>REC - RECOMPRA DE CARTERA<br><br>REJ - REAJUSTE DE INTERESES<br><br>RES - REESTRUCCTURACION<br><br>RPA - REGISTRO DE PAGOS<br><br>…………… |
| tt_descripcion | descripcion | 64  | NOT NULL | Descripción del tipo de transacción |
| tt_reversa | char | 1   | NOT NULL | Indica si aplica reversa o no<br><br>S = SI<br><br>N = NO |
| tt_contable | char | 1   | NULL | Indica si el tipo de transacción es contable/maneja contabilización |

### ca_transaccion_prv

Tabla donde se registran las transacciones de provisión de interés generadas por las operaciones.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| tp_fecha_mov | smalldatetime | 4   | NOT NULL | Fecha de movimiento de la transacción |
| tp_operacion | int | 4   | NOT NULL | Número interno de operación de cartera. |
| tp_fecha_ref | smalldatetime | 4   | NOT NULL | Fecha de referencia de la transacción. |
| tp_secuencial_ref | int | 4   | NOT NULL | Secuencial de referencia. |
| tp_estado | char | 3   | NOT NULL | Estado de la transacción<br><br>ING: Ingresado<br><br>RV: Reversado<br><br>NCO: No contabiliza.<br><br>CON: Contabilizado. |
| tp_comprobante | int | 4   | NULL | Número de comprobante. |
| tp_fecha_cont | smalldatetime | 4   | NULL | Fecha de contabilización. |
| tp_dividendo | smallint | 2   | NOT NULL | Número de dividendo asociado a la transacción. |
| tp_concepto | catalogo | 10  | NULL | Código del rubro o concepto |
| tp_codvalor | int | 4   | NOT NULL | Código valor que asocia la forma de cobro/pago a la contabilidad. |
| tp_monto | money | 8   | NOT NULL | Monto del rubro |
| tp_secuencia | tinyint | 1   | NOT NULL | Secuencia de registro de rubro o concepto. |
| tp_ofi_oper | smallint | 2   | NOT NULL | Oficina de operación |
| tp_monto_mn | money | 8   | NULL | Monto en moneda nacional del concepto/rubro. |
| tp_moneda | tinyint | 1   | NULL | Código de moneda. |
| tp_cotizacion | float | 8   | NULL | Valor de la cotización de moneda |
| tp_tcotizacion | char | 1   | NULL | Tipo de cotización |
| tp_reestructuracion | char | 1   | NOT NULL | Indica si la operación asociada a la transacción hubo reestructuración. |

### ca_transaccion

Tabla donde se registra la cabecera de las transacciones generadas por las operaciones.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| tr_secuencial | int | 4   | NOT NULL | Secuencial por operación asignado a la transacción |
| tr_fecha_mov | smalldatetime | 4   | NOT NULL | Fecha de movimiento |
| tr_toperacion | char | 10  | NOT NULL | Tipo de producto de cartera |
| tr_moneda | tinyint | 1   | NOT NULL | Código de la moneda |
| tr_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| tr_tran | char | 10  | NOT NULL | Tipo de transacción |
| tr_en_linea | char | 1   | NOT NULL | Si la transacción es en línea o no |
| tr_banco | char | 24  | NOT NULL | Código banco del préstamo |
| tr_dias_calc | int | 4   | NOT NULL | Días de calculo |
| tr_ofi_oper | smallint | 2   | NOT NULL | Oficina de la operación |
| tr_ofi_usu | smallint | 2   | NOT NULL | Oficina del usuario |
| tr_usuario | char | 14  | NOT NULL | Código del usuario |
| tr_terminal | char | 30  | NOT NULL | Terminal donde se realizó la transacción |
| tr_fecha_ref | smalldatetime | 4   | NOT NULL | Fecha de referencia de la transacción |
| tr_secuencial_ref | int | 4   | NOT NULL | Secuencial de referencia a la transacción asociada (Registro de Pago de un Pago) |
| tr_estado | char | 10  | NOT NULL | Estado de la transacción.<br><br>ING: Ingresado<br><br>CON: Contabilizado<br><br>RV: Reversado |
| tr_observacion | char | 62  | NOT NULL | Obervación/razón de la transacción. |
| tr_gerente | smallint | 2   | NOT NULL | Código del oficial que ingresó el préstamo. |
| tr_comprobante | int | 4   | NOT NULL | Número de comprobante |
| tr_fecha_cont | datetime | 8   | NOT NULL | Fecha de contabilización |
| tr_gar_admisible | char | 1   | NOT NULL | Indica si la transacción admite garantías. No se utiliza en esta versión y se establece un valor por defecto de 'N' o ''. |
| tr_reestructuracion | char | 1   | NOT NULL | Indica si la operación asociada a la transacción hubo reestructuración. |
| tr_calificacion | catalogo | 10  | NOT NULL | Valor de la calificación del préstamo asociado a la transacción. |
| tr_fecha_real | datetime | 8   | NULL | Fecha real en la que fue realizada la transacción. |

### ca_traslados_cartera

Tabla que almacena información acerca de los traslados que se realizaron a los préstamos de cartera. Esta información se almacena en el proceso batch de Traslado de Oficinas y Oficiales.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| trc_fecha_proceso | datetime | 8   | NOT NULL | Fecha proceso del traslado. |
| trc_cliente | int | 1   | NOT NULL | Código del cliente al que pertenece el préstamo que se trasladó. |
| trc_operacion | int | 4   | NOT NULL | Número de operación del préstamo al cual se realizó el traslado |
| trc_user | login | 14  | NOT NULL | Nombre de usuario que realizó el traslado de la operación |
| trc_term | varchar | 30  | NOT NULL | Terminal desde donde se ejecutó el traslado de la operación. |
| trc_fecha_real | datetime | 8   | NOT NULL | Fecha real en la que se aplicó el traslado de la operación. |
| trc_oficina_origen | int | 4   | NOT NULL | Código de la oficina desde donde viene la operación. |
| trc_oficina_destino | int | 4   | NOT NULL | Código de la oficina hacia donde se aplicó el traslado de la operación. |
| trc_estado | char | 1   | NOT NULL | Estado en el que se encuentra el traslado.<br><br>I = ingresado<br><br>P = Procesado (Cuando se genera las transacciones correspondientes. Procesado por el batch diario) |
| trc_garantias | char | 1   | NOT NULL | (Campo en desuso). |
| trc_credito | char | 1   | NOT NULL | (Campo en desuso). |
| trc_sidac | char | 1   | NOT NULL | (Campo en desuso). |
| trc_fecha_ingreso | datetime | 8   | NOT NULL | Fecha de ingreso del registro de traslado. |
| trc_secuencial_trn | int | 4   | NULL | Número de secuencial de la transacción de traslado (Aplica si ya fue procesado por el batch diario). |
| trc_oficial_destino | smallint | 2   | NOT NULL | Código del oficinal al cual se aplicó el traslado de la operación. |
| trc_oficial_origen | smallint | 2   | NOT NULL | Código del oficial desde el cual viene la operación. |
| trc_saldo_capital | money | 8   | NOT NULL | Saldo de la operación a la cual se realizó el traslado. (Campo en desuso). |

### ca_valor

Tabla de parametrización donde se registra la información principal de las tasas/valores a aplicar

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| va_tipo | varchar | 10  | NOT NULL | Código del tipo de tasa |
| va_descripcion | varchar | 64  | NOT NULL | Descripción del tipo de tasa |
| va_clase | char | 1   | NOT NULL | Si es valor o factor<br><br>V = Valor<br><br>F = Factor |
| va_pit | char | 1   | NULL | Valor de pit |
| va_prime | char | 1   | NULL | Valor de Prime.<br><br>S = SI<br><br>N = NO |

### ca_valor_det

Tabla de parametrización donde se registra el detalle (porcentajes, máximos, mínimos, etc.) de las tasas/valores aplicar

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| vd_tipo | varchar | 10  | NOT NULL | Catálogo de tipo de tasa |
| vd_sector | catalogo | 10  | NOT NULL | Sector/Banca de la tasa |
| vd_signo_default | char | 1   | NULL | Signo por default +, - , \*, / |
| vd_valor_default | float | 8   | NULL | Monto por default |
| vd_signo_maximo | char | 1   | NULL | Signo máximo +, - , \*, / |
| vd_valor_maximo | float | 8   | NULL | Monto máximo |
| vd_signo_minimo | char | 1   | NULL | Signo mínimo +, - , \*, / |
| vd_valor_minimo | float | 8   | NULL | Valor mínimo |
| vd_referencia | varchar | 10  | NULL | Indica la tasa referencial |
| vd_tipo_puntos | char | 1   | NULL | Indica el tipo de puntos. Campo en desuso, valor por defecto "B". |
| vd_num_dec | tinyint | 1   | NULL | Número de decimales. Campo en desuso, valor por defecto 4. |

### ca_pin_odp

Tabla donde se almacenan los pines necesarios para validar autenticación y así poder desembolsar el préstamo

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| po_operacion | int | 4   | NOT NULL | Código largo de la operación |
| po_desembolso | tinyint | 1   | NOT NULL | Código del desembolso |
| po_secuencial_desembolso | int | 4   | NOT NULL | Secuencial del desembolso |
| po_secuencial_pin | int | 4   | NOT NULL | Secuencial del pin |
| po_pin | int | 4   | NOT NULL | PIN |
| po_fecha_generacion | smalldatetime | 4   | NULL | Fecha de generación |
| po_fecha_vencimiento | smalldatetime | 4   | NULL | Fecha de vencimiento del pin |
| po_fecha_bloqueo | smalldatetime | 4   | NULL | Fecha de bloqueo del pin |
| po_fecha_anulacion | smalldatetime | 4   | NULL | Fecha de anulación del pin |
| po_estado | char | 1   | NULL | (N=NORMAL/B=BLOQUEADO/A=ANULADO) |
|     |     |     |     |     |

### ca_archivo_pagos_1_tmp

Tabla donde se almacena la información del archivo de entrada de pagos por medio de la interfaz del proceso batch.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| apt_descripcion | varchar | 50  | NULL | Descripción del pago |
| apt_agencia | varchar | 50  | NULL | Nombre del corresponsal que realiza el pago |
| apt_fecha | datetime | 8   | NULL | Fecha del sistema |
| apt_boleta | int | 4   | NULL | Número de transacción del corresponsal |
| apt_id_cliente | varchar | 20  | NULL | Número del préstamo al que se le va a realizar el pago |
| apt_nombre_cliente | Varchar | 30  | NULL | Nombre del cliente, el formato que se ingresa es Primer apellido seguido de la inicial del primer nombre. Ej: DIAZC |
| apt_valor_pago | Money | 8   | NULL | Valor a pagar |
| apt_fecha_pago | datetime | 8   | NULL | Fecha del pago |
| apt_efectivo | Money | 8   | NULL | Valor en efectivo |
| apt_cheque_propio | Money | 8   | NULL | Valor en cheque propio del banco |
| apt_cheque_local | Money | 8   | NULL | Valor en cheque de otro corresponsal |
| apt_total | Money | 8   | NULL | Sumatoria total de los valores a cancelar, se suman los tres valores anteriores. |

### ca_archivo_pagos_1

Tabla donde se almacena la información del archivo de salida de pagos por medio de la interfaz del proceso batch.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| ap_descripcion | varchar | 50  | NULL | Descripción del pago |
| ap_agencia | varchar | 50  | NULL | Nombre del corresponsal que realiza el pago |
| ap_fecha | datetime | 8   | NULL | Fecha del sistema |
| ap_boleta | int | 4   | NULL | Número de transacción del corresponsal |
| ap_id_cliente | varchar | 20  | NULL | Número del préstamo al que se le va a realizar el pago |
| ap_nombre_cliente | Varchar | 30  | NULL | Nombre del cliente, el formato que se ingresa es Primer apellido seguido de la inicial del primer nombre. Ej: DIAZC |
| ap_valor_pago | Money | 8   | NULL | Valor a pagar |
| ap_fecha_pago | datetime | 8   | NULL | Fecha del pago |
| ap_efectivo | Money | 8   | NULL | Valor en efectivo |
| ap_cheque_propio | Money | 8   | NULL | Valor en cheque propio del banco |
| ap_cheque_local | Money | 8   | NULL | Valor en cheque de otro corresponsal |
| ap_total | Money | 8   | NULL | Sumatoria total de los valores a cancelar, se suman los tres valores anteriores. |
| ap_error | int | 4   | NULL | Código de error que genera si se presenta un error al realizar el pago caso contrario se muestra 0 |
| ap_msg_error | Varchar | 255 | NULL | Mensaje de error correspondiente al código de error generado. |

### ca_en_fecha_valor

Contiene la parametrización de rangos de montos para requerir una validación de montos del supervisor en caso de superarse el rango por transacción.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| bi_operacion | int | 8   | NULL | Número corto del préstamo |
| bi_banco | cuenta | 24  | NULL | Número largo del préstamo |
| bi_fecha_valor | datetime | 8   | NULL | Fecha del último proceso del préstamo |
| bi_user | login | 14  | NULL | Usuario con el que se encuentra autenticado en el sistema |

### ca_batch_pagos_corresponsal

Tabla que permite realizar la carga, validación y pago de todos los registros que se encuentran en un archivo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| bpc_fecha_proceso | datetime | 8   | NULL | Fecha de proceso |
| bpc_nom_catalogo | varchar | 30  | NULL | Nombre del catálogo asociado al banco |
| bpc_num_operacion | varchar | 20  | NULL | Número largo de la operación |
| bpc_valor_pago | money | 14  | NULL | Monto que va aplicar el pago |
| bpc_num_boleta | int | 8   | NULL | Número de transacción del corresponsal. |
| bpc_fecha_pago | datetime | 8   | NULL | Fecha de pago en la que se va aplicar el pago. |
| bpc_estado | char | 1   | NULL | Estado en el que se encuentra el registro.  <br><br/>I: Insertado.  <br>V: Validado.  <br>P: Procesado.  <br>E: Error |
| bpc_cod_error_valida | int | 8   | NULL | Código de error que se genera en la validación. |
| bpc_msg_error_valida | varchar | 4000 | NULL | Mensaje de error correspondiente al código de error de la validación. |
| bpc_cod_error_procesa | int | 8   | NULL | Código de error que se genera en el procesamiento del pago. |
| bpc_msg_error_procesa | varchar | 4000 | NULL | Mensaje de error correspondiente al código de error del procesamiento del pago. |

### ca_incentivos_detalle_operaciones

Tabla que permite el almacenamiento del detalle de las operaciones que intervienen en el calculo de indicadores para cada oficial .

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| ido_fecha_proceso | datetime | 8   | NULL | Fecha de proceso |
| ido_banco | varchar | 24  | NULL | Número largo de la operación |
| ido_estado | varchar | 10  | NULL | Estado de la operación |
| ido_cliente | int |     | NULL | Código del cliente de la operación |
| ido_oficial | int |     | NULL | Código del oficial de la operación. |
| ido_oficina | int |     | NULL | Código del oficina de la operación. |
| ido_toperacion | varchar | 10  | NULL | Tipo de operación. |
| ido_intereses | money |     | NULL | Montos de los interés recuperados de operación. |
| ido_riesgo | money |     | NULL | Monto de capital en riego si existe dividendos vencidos |
| ido_saldo_tot_cap | money |     | NULL | Saldo de capital la operación. |
| ido_dias_vcto_div | int |     | NULL | Días de vencimiento de la operación. |
| ido_capital_conmora | money |     |     | Identificación de capital generado con mora |

### ca_incentivos_obtencion_indicadores

Tabla que permite el almacenamiento del detalle de las operaciones que intervienen en el calculo de incentivos .

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| icc_fecha_proceso | datetime | 8   |     | Fecha de proceso |
| icc_anio | smallint |     |     | Registro de año |
| icc_mes | smallint |     |     | Registro de mes |
| icc_oficina | smallint |     |     | Código del oficina. |
| icc_cod_ofi_superior | smallint |     | NULL | Código de oficial superior |
| icc_oficial | smallint | 1   |     | Código del oficial. |
| icc_nombre_oficial | varchar | 64  | NULL | Nombre del oficial. |
| icc_cod_planilla | smallint |     | NULL | Código de planilla del oficial |
| icc_tipo_cargo | varchar | 10  |     | Tipo de cargo del oficial.<br><br>O = Oficial, S = Supervisor,<br><br>J = Jefe de oficina |
| icc_toperacion | varchar | 10  | NULL | Tipo de operación |
| icc_saldo_total | money |     | NULL | Saldo de capital total por oficial. |
| icc_saldo_vencimiento | money |     | NULL | Saldo de vencimiento por oficial. |
| icc_saldo_castigo | money |     | NULL | Saldo de castigo registrado para el oficial |
| icc_saldo_sin_riesgo | money |     | NULL | Registro de saldo sin riesgo por oficial |
| icc_saldo_excepciones | money |     | NULL | Saldo de excepciones registrado para el oficial |
| icc_calculo_calidad | float |     |     | Porcentaje de dividir el saldo sin riesgo sobre el saldo total |
| icc_riesgo_grupal | float |     | NULL | Indicador de riego grupal por oficina |
| icc_metas_mes | money |     |     | Registro de la meta a cumplir por mes |
| icc_indicador_clientes | int |     |     | Indicador de clientes por oficial |
| icc_indicador_riesgo | float |     |     | Indicador de riesgo por oficial |
| icc_indicador_cumplimiento | float |     |     | Registro del porcentaje de cumplimiento del oficial, se obtiene por la división del saldo total sobre metas del mes |
| icc_indicador_interes | float |     |     | Indicador de interés por oficial |
| icc_porc_clientes | float |     |     | Porcentaje de indicador de clientes |
| icc_porc_riesgo | float |     |     | Porcentaje de indicador de riesgo |
| icc_porc_cumplimiento | float |     |     | Porcentaje de indicador de cumplimiento de cartera |
| icc_incen_clientes | money |     |     | Monto de incentivo obtenido por clientes |
| icc_incen_riesgo | money |     |     | Monto de incentivo obtenido por riesgo |
| icc_incen_cumplimineto | money |     |     | Monto de incentivo obtenido por cumplimiento de cartera |
| icc_total_mensual | money |     |     | Sumatoria de todos los monto de incentivos |
| icc_total_mensual_ajustado | money |     |     | Total de incentivos si existe un ajuste |
| icc_descripcion_ajuste | varchar | 120 | NULL | Descripcion del total de ajuste |
| icc_pago_quincenal | money |     |     | Monto de pago quincenal |

### ca_incentivos_metas

Tabla que permite el almacenamiento de los registros definitivos de las metas para incentivos.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| im_anio | smallint |     | NOT NULL | Año de metas |
| im_oficina | smallint |     | NOT NULL | Oficina del oficial |
| im_cod_asesor | smallint |     | NOT NULL | Codigo del oficial |
| im_mes | tinyint |     | NOT NULL | Mes de las metas |
| im_nombre_asesor | varchar | 64  | NOT NULL | Nombre del oficial |
| im_monto_proyectado | money |     | NOT NULL | Monto asignado al oficial para cumplir con las metas |

### ca_incentivos_metas_tmp

Tabla que permite el almacenamiento de los registros temporales que se leen del documento masivo de las metas para incentivos.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| imt_anio | smallint |     | NOT NULL | Año de metas |
| imt_oficina | smallint |     | NOT NULL | Oficina del oficial |
| imt_cod_asesor | smallint |     | NOT NULL | Codigo del oficial |
| imt_mes | tinyint |     | NOT NULL | Mes de las metas |
| imt_nombre_asesor | varchar | 64  | NOT NULL | Nombre del oficial |
| imt_monto_proyectado | money |     | NOT NULL | Monto asignado al oficial para cumplir con las metas |
| imt_usuario_login | varchar | 64  | NOT NULL | Usuario que realiza la carga o actualización masiva de registros |

### ca_errores_ope_masivas

Tabla que permite el almacenamiento de los errores que se presentan a la hora de realizar validaciones a los registros en carga o actualización masiva de metas para incentivos.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| eom_error | varchar | 500 | NOT NULL | Descripción del error |
| eom_usuario | varchar | 50  | NOT NULL | Usuario que realiza la carga o actualización de registros |

### ca_7x24_fcontrol

Tabla de control que registra la fecha en la cual se generaron los saldos a pagar de las operaciones.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| fc_fecha_proceso | datetime | 8   | NOT NULL | Fecha proceso en la cual se generó el calculo de los saldos a pagar de las operaciones. |

### ca_7x24_saldos_prestamos

Tabla que almacena las operaciones activas de carteras con sus respectivos saldos a pagar hasta la fecha de cierre para poder utilizarse en procesos de fuera de línea.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| sp_fecha_proceso | datetime | 8   | NOT NULL | Fecha de proceso del sistema. |
| sp_num_banco | cuenta | 24  | NOT NULL | Número largo del préstamo (ref ca_operacion.op_banco) |
| sp_num_operacion | int | 4   | NOT NULL | Secuencial del préstamo (ref ca_operacion.op_operacion) |
| sp_saldo_a_pagar | money | 8   | NOT NULL | Monto calculado de pago hasta fecha proceso (monto depende de parametrización de la negociación del producto). |

### ca_7x24_errores

Tabla que permite registrar información sobre los errores ocasionados en la consulta de saldo a pagar o proceso de pagos

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| er_fecha_proceso | datetime | 8   | NOT NULL | Fecha de proceso del sistema. |
| er_fecha_real | datetime | 8   | NOT NULL | Fecha real en la que se registra el registro de error |
| er_user | login | 14  | NOT NULL | Usuario el cual realizó la transacción |
| er_term | descripcion | 160 | NOT NULL | Terminal desde donde se relizó la transacción. |
| er_sesion | int | 4   | NOT NULL | Número de sesión o de registro del usuario que ejecuta la transacción |
| er_operacion | char | 1   | NULL | Identifica la operación realizada por la cual generó el error.<br><br>Q: Consulta<br><br>P: Proceso de pago |
| er_idcolector | smallint | 2   | NULL | Número de colector que realiza la consulta o pago. |
| er_numcuentacolector | varchar | 30  | NULL | Número de cuenta bancaria proporcionada por el colector. |
| er_idreferencia | varchar | 30  | NULL | Número único que identifica el pago (Boleta) y que se registra como número de documento en Bancos. |
| er_reference | varchar | 30  | NULL | Número de operación (número largo) a la cual se va a plicar el pago |
| er_amounttopay | money | 8   | NULL | Monto total con la que se realiza el pago |
| er_fecha_pago | datetime | 8   | NULL | Fecha en la que se realiza el pago |
| er_num_error | int | 4   | NOT NULL | Número de error ocasionado en el proceso de consulta saldo a pagar o proceso de pago (Número registrado en cobis..cl_errores.numero) |
|     |     |     |     |     |

### ca_cambio_estado_masivo

Tabla que permite registrar las operaciones de cartera de cambio de estado masivo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| cem_fecha_proceso | datetime | 8   | NOT NULL | Fecha de proceso. |
| cem_op_banco | cuenta | 24  | NOT NULL | Número largo operación. |
| cem_fecha_valor | datetime | 8   | NOT NULL | Fecha valor registrada en el archivo de entrada. |
| cem_estado_inicial_op | tinyint | 1   | NOT NULL | Estado inicial de la operación de cartera. op_estado |
| cem_estado_final_op | tinyint | 1   | NOT NULL | Estado final de la operación de cartera. op_estado<br><br>4 (castigado) |
| cem_estado_registro | char(1) | 1   | NOT NULL | Estado del registro del cambio.<br><br>"I" =ingresado (default)<br><br>"P"= procesado ok<br><br>"E" = procesado con error |
| cem_fecha_real | datetime | 8   | NOT NULL | Fecha de ingreso de los registros. |
| cem_codigo_error | Int | 4   | NULL | Código de error (solo en tiempo de procesamiento) |

### ca_abono_grupal_tmp

Tabla temporal que permite registrar las condiciones de un abono grupal. Estos registros son considerados como una negociación básica para el abono grupal

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| agt_fecha_real | datetime | 8   | NOT NULL | Fecha real. |
| agt_user | login | 14  | NOT NULL | Usuario que realizá la acción. |
| agt_term | descripcion | 160 | NOT NULL | Terminal desde donde se realiza la acción. |
| agt_sesn | int | 4   | NOT NULL | Número de sesión del usuario que ejecuta la acción. |
| agt_ssn | int | 4   | NOT NULL | Número secuencial único para la transacción. |
| agt_fecha_ing | datetime | 8   | NOT NULL | Fecha de ingreso del abono grupal |
| agt_banco_padre | cuenta | 24  | NOT NULL | Número de operación Padre. |
| agt_banco_hijo | cuenta | 24  | NOT NULL | Número de operación Hijo(s) |
| agt_secuencial | int | 4   | NOT NULL | Secuencial interno de la operación Padre (Solo para uso interno del registro). |
| agt_fpago | catalogo | 10  | NOT NULL | Forma de pago del abono grupal. |
| agt_monto | money | 8   | NOT NULL | Monto a pagar de la operación. (La sumatoria de estos montos es registrada en estructuras de abono para la operación Padre) |

### ca_qr_transacciones_tmp

Tabla temporal que permite registrar las transacciones de cartera, según criterios de búsqueda preestablecidos.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| trt_user | login | 14  | NULL | Usuario quien realiza la transacción de consulta. |
| trt_sesn | int | 4   | NULL | Número de sesión del usuario que ejecuta la acción. |
| trt_operacion | int | 4   | NULL | Secuencial del préstamo al que pertenece la transacción. |
| trt_fecha_mov | smalldatetime | 4   | NULL | Fecha de movimiento de la transacción (Fecha proceso del sistema). |
| trt_ofi_usu | smallint | 2   | NULL | Oficina del usuario con la cual se realizó la transacción. |
| trt_ofi_oper | smallint | 2   | NULL | Oficina de la operación a la cual pertenece la transacción. |
| trt_tran | char | 10  | NULL | Tipo de transacción (Según cob_cartera.ca_tipo_trn.tt.codigo). |
| trt_toperacion | catalogo | 10  | NULL | Tipo de producto a la cual pertenece la operación de la transacción |
| trt_grupo | int | 4   | NULL | Grupo al que pertenece la operación de la transacción (Si es operación grupal). |
| trt_moneda | tinyint | 1   | NULL | Moneda de la transacción. |
| trt_banco | varchar | 24  | NULL | Número del préstamo al que pertenece la transacción. |
| trt_estado | char | 10  | NULL | Estado de la transacción |
| trt_usuario | char | 14  | NULL | Oficial que realizó la transacción |
| trt_terminal | char | 30  | NULL | Terminal desde donde se realizó la transacción |
| trt_fecha_ref | smalldatetime | 4   | NULL | Fecha referencia de la transacción (Fecha último proceso de la operación de la transacción). |
| trt_en_linea | char | 1   | NULL | Indicia si la transación fue realizada en línea. |
| trt_secuencial | int | 4   | NULL | Número de secuencial de la transacción |
| trt_secuencial_ref | int | 4   | NULL | Número de secuencial al que hace referencia la transacción. |
| trt_comprobante | int | 4   | NULL | Número de comprobante contable de la transacción |
| trt_fecha_cont | datetime | 8   | NULL | Fecha de contabilización de la transacción |
| trt_fecha_real | datetime | 8   | NULL | Fecha real en la cual se realizó la transacción. |

### ca_en_fecha_valor_grupal

Tabla que permite registrar un préstamo grupal en caso de que la fecha del último proceso de las operaciones hijas no coincida con la fecha de proceso

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| fvg_operacion | int | 8   | NOT NULL | Número corto del préstamo |
| fvg_banco | cuenta | 24  | NOT NULL | Número largo del préstamo |
| fvg_fecha_valor | datetime | 8   | NOT NULL | Fecha del último Proceso del préstamo |
| fvg_user | login | 14  | NOT NULL | Usuario con el que se encuentra autenticado en el sistema |

### ca_log_fecha_valor_grupal

Tabla que permite registrar un préstamo grupal cuando se aplica Fecha Valor Grupal, funciona como un historico de trasacciones de Fecha Valor a una operación grupal.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| lfv_operacion | int | 8   | NOT NULL | Número corto del préstamo |
| lfv_secuencial_retro | int | 8   | NOT NULL | Secuencial de transacción de reverso, para operación 'F' se ingresa 0 |
| lfv_tipo | Char(1) | 1   | NULL | Tipo de operación de proceso 'F' para fecha valor |
| fvg_fecha_valor | datetime | 8   | NULL | Fecha del último Proceso del préstamo |
| lfv_registro | Varchar(30) | 30  | NULL | Valor por defecto 'N', campo en desuso |
| fvg_user | login | 14  | NULL | Usuario con el que se encuentra autenticado en el sistema |
| lfv_fecha_real | datetime | 8   | NOT NULL | Fecha real de aplicación de fecha valor |

## Tablas de Transacciones de servicio

Cada módulo tiene una Base de Datos, la cual cuenta con una tabla de Transacciones de Servicio, en la que se incluyen todos los campos de todas las tablas que pueden sufrir modificación en la operación del módulo (inserción, actualización o eliminación). Se entiende por Vista de Transacciones de Servicio, aquella porción de la tabla Transacciones de Servicio que compete a determinada Transacción.

Cada modificación de la Base de Datos genera un registro indicando la transacción realizada (secuencial, clase y código), persona que ejecuta la transacción (usuario que envía el requerimiento), desde y dónde (terminal, y servidores de origen y ejecución de la transacción) y los datos de la tabla a modificar.

### ca_default_toperacion_ts

Tabla de transacción de servicios para los parámetros por tipo de operación

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| dts_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| dts_fecha_ts | datetime | 8   | NOT NULL | Fecha de la transacción |
| dts_usuario_ts | login | 14  | NOT NULL | Login del Usuario |
| dts_oficina_ts | smallint | 2   | NOT NULL | Oficina |
| dts_terminal_ts | varchar | 30  | NOT NULL | Código de la terminal |
| dts_toperacion | catalogo | 10  | NOT NULL | Código del producto de cartera |
| dts_moneda | tinyint | 1   | NOT NULL | Moneda del producto |
| dts_reajustable | char | 1   | NOT NULL | S = es reajustable<br><br>N = No es reajustable |
| dts_periodo_reaj | tinyint | 1   | NULL | Periodo de reajuste |
| dts_reajuste_especial | char | 1   | NULL | Si tiene reajuste especial |
| dts_renovacion | char | 1   | NOT NULL | Si el producto permite renovación |
| dts_tipo | char | 1   | NOT NULL | Tipo de operación<br><br>N = préstamo de cartera<br><br>D = descuento de documento<br><br>L = Leasing<br><br>R = Préstamo pasivos<br><br>P = Préstamo int. prepagado |
| dts_estado | catalogo | 10  | NULL | V = Vigente<br><br>B = Bloqueado<br><br>X = producto deshabilitado<br><br>C = Cancelado<br><br>E = Eliminado |
| dts_precancelacion | char | 1   | NOT NULL | S = Permite precancelar<br><br>N = No permite precancelar |
| dts_cuota_completa | char | 1   | NOT NULL | Solo paga cuota completa<br><br>S = Si<br><br>N = No |
| dts_tipo_cobro | char | 1   | NOT NULL | Tipo de pago, paga los interés acumulados o proyectados<br><br>A = Acumulado<br><br>P = Proyectado |
| dts_tipo_reduccion | char | 1   | NOT NULL | Tipo de reducción cuando hay pago extraordinario:<br><br>C = Cuota<br><br>T = Tiempo |
| dts_aceptar_anticipos | char | 1   | NOT NULL | S = Acepta anticipos<br><br>N = No acepta anticipos |
| dts_tipo_aplicacion | char | 1   | NOT NULL | Tipo de aplicación:<br><br>D = Aplica por dividendo<br><br>C = Aplica por concepto |
| dts_tplazo | catalogo | 10  | NOT NULL | Tipo de plazo<br><br>M = Mensual<br><br>A = anual<br><br>………………….. |
| dts_plazo | smallint | 2   | NOT NULL | Plazo |
| dts_tdividendo | catalogo | 10  | NOT NULL | Tipo de dividendo<br><br>M = Mensual<br><br>A = anual<br><br>………………….. |
| dts_periodo_cap | smallint | 2   | NOT NULL | Cada cuanto Periodo de capital tiene el préstamos |
| dts_periodo_int | smallint | 2   | NOT NULL | Cada cuanto Periodo de interés tiene el préstamos |
| dts_gracia_cap | smallint | 2   | NOT NULL | Cuantos periodos de gracia de capital |
| dts_gracia_int | smallint | 2   | NOT NULL | Cuantos periodos de gracia de capital |
| dts_dist_gracia | char | 1   | NOT NULL | Cuando hay periodos de gracia<br><br>N = Paga en primera cuota<br><br>S = distribuir en las cuotas restantes<br><br>M = no pagar, periodos muertos |
| dts_dias_anio | smallint | 2   | NOT NULL | Días para el cálculo de intereses<br><br>360, 365, 366 |
| dts_tipo_amortizacion | catalogo | 10  | NOT NULL | Tipo de amortización<br><br>FRANCESA<br><br>ALEMANA |
| dts_fecha_fija | char | 1   | NOT NULL | Si el cobro es en fecha fija<br><br>S = SI<br><br>N = NO |
| dts_dia_pago | tinyint | 1   | NOT NULL | Si es en fecha ficha, que día del mes es el día del pago |
| dts_cuota_fija | char | 1   | NOT NULL | Si los pagos son de cuota fija<br><br>S = SI<br><br>N = NO |
| dts_dias_gracia | tinyint | 1   | NOT NULL | Días de gracia para mora |
| dts_evitar_feriados | char | 1   | NOT NULL | Si los vencimientos de las cuotas se van a generar evitando feriados<br><br>S = Si evitar feriados<br><br>N = No evita feriados |
| dts_mes_gracia | tinyint | 1   | NOT NULL | Mes de gracia, que no paga cuota |
| dts_base_calculo | char | 1   | NULL | Base de cálculo<br><br>E = COMERCIAL<br><br>R = REAL |
| dts_prd_cobis | tinyint | 1   | NULL | Producto cobis<br><br>7 = CARTERA |
| dts_dia_habil | char | 1   | NULL | Día hábil<br><br>S = SI<br><br>N = NO |
| dts_recalcular_plazo | char | 1   | NULL | Recalcular plazo<br><br>S = SI<br><br>N = NO |
| dts_usar_tequivalente | char | 1   | NULL | Usar tipo equivalente |
| dts_tipo_redondeo | tinyint | 1   | NULL | Tipo de redondeo |
| dts_causacion | char | 1   | NULL | Causación<br><br>L = Lineal<br><br>E = Exponencial |
| dts_convertir_tasa | char | 1   | NULL | Convertir tasa<br><br>S = SI<br><br>N = NO |
| dts_tipo_linea | catalogo | 10  | NULL | Catálogo Entidad Prestamista (ca_tipo_linea) |
| dts_subtipo_linea | catalogo | 10  | NULL | Catalogo Programa de Credito (ca_subtipo_linea)<br><br>01 = Quirografarias<br><br>02 = Prendarias<br><br>03 = Factoraje<br><br>04 = Arrendamiento Capitalizable<br><br>05 = Microcréditos<br><br>06 = Otros<br><br>07 = Liquidez a otras Cooperativas<br><br>99 = N/A |
| dts_bvirtual | char | 1   | NOT NULL | Banca virtual<br><br>S = SI<br><br>N = NO |
| dts_extracto | char | 1   | NOT NULL | Extracto<br><br>N |
| dts_naturaleza | char | 1   | NULL | Naturaleza<br><br>A |
| dts_pago_caja | char | 1   | NULL | Paga en caja<br><br>S = SI<br><br>N = NO |
| dts_nace_vencida | char | 1   | NULL | Indica si el préstamo nace vencido<br><br>S = SI<br><br>N = NO |
| dts_calcula_devolucion | char | 1   | NULL | Calcula devolución<br><br>S = SI<br><br>N = NO |
| dts_categoria | catalogo | 10  | NULL | Catálogo Origen de Los Recursos (ca_categoria_linea) |
| dts_entidad_convenio | catalogo | 10  | NULL | Entidad de convenio |
| dts_mora_retroactiva | char | 1   | NULL | Mora retroactiva<br><br>S = SI<br><br>N = NO |
| dts_prepago_desde_lavigente | char | 1   | NULL | Prepago desde la vigente<br><br>S = SI<br><br>N = NO |
| dts_dias_anio_mora | smallint | 2   | NULL | Días para el cálculo de interés por mora: 360, 365, 366 |
| dts_tipo_calif | catalogo | 10  | NULL | Tipo de calificación |
| dts_plazo_min | smallint | 2   | NULL | Plazo mínimo |
| dts_plazo_max | smallint | 2   | NULL | Plazo máximo |
| dts_monto_min | money | 8   | NULL | Monto mínimo |
| dts_monto_max | money | 8   | NULL | Monto Máximo |
| dts_clase_sector | catalogo | 10  | NULL | Catálogo de Clase de sector |
| dts_clase_cartera | catalogo | 10  | NULL | Catálogo Clasificación de la cartera |
| dts_gar_admisible | char | 1   | NULL | Garantía admisible<br><br>S = SI<br><br>N = NO |
| dts_afecta_cupo | char | 1   | NULL | Afecta al cupo<br><br>S = SI<br><br>N = NO |
| dts_control_dia_pago | char | 1   | NULL | Control día de pago<br><br>S = SI<br><br>N = NO |
| dts_porcen_colateral | float | 8   | NULL | Porcentaje colateral |
| dts_subsidio | char | 1   | NULL | Aplica subsidio agropecuario<br><br>S = SI<br><br>N = NO |
| dts_tipo_prioridad | char | 1   | NULL | Tipo de prioridad |
| dts_dia_ppago | tinyint | 1   | NULL | Día de primer pago |
| dts_efecto_pago | char | 1   | NULL | Forma de afectación de pago (débito/crédito) |
| dts_tpreferencial | char | 1   | NULL |     |
| dts_modo_reest | char | 1   | NULL | Modo de reestructuración de valores en Mora |
| dts_cuota_menor | char | 1   | NULL | Permitir cuota menor a monto de interés<br><br>S = SI<br><br>N = NO |
| dts_fondos_propios | char | 1   | NULL | Fondos propios |
| dts_admin_individual | char | 1   | NULL | Identificar el manejo de Grupales<br><br>S = Se administra como préstamos individuales<br><br>N = Se administra el padre y los hijos son de referenia |

### ca_dividendo_ts

Tabla que contiene información de las transacciones de servicio de los dividendos de las operaciones, log de auditoria

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| dis_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| dis_fecha_ts | datetime | 8   | NOT NULL | Fecha de ingreso del registro |
| dis_usuario_ts | login | 14  | NOT NULL | Código del usuario |
| dis_oficina_ts | smallint | 2   | NOT NULL | Oficina que realiza la transacción |
| dis_terminal_ts | varchar | 30  | NOT NULL | Terminal que realiza la transacción |
| dis_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| dis_dividendo | smallint | 2   | NOT NULL | Número de dividendo o cuota |
| dis_fecha_ini | datetime | 8   | NOT NULL | Fecha de inicio del dividendo |
| dis_fecha_ven | datetime | 8   | NOT NULL | Fecha final del dividendo |
| dis_de_capital | char | 1   | NOT NULL | Si la cuota cobra Capital |
| dis_de_interes | char | 1   | NOT NULL | Si la cuota cobra Interés |
| dis_gracia | smallint | 2   | NOT NULL | Periodos de gracias |
| dis_gracia_disp | smallint | 2   | NOT NULL | Periodos de gracia disponible |
| dis_estado | tinyint | 1   | NOT NULL | Estado de la cuota o dividendo<br><br>0 = No vigente<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO<br><br>4 = CASTIGADO |
| dis_dias_cuota | int | 4   | NOT NULL | Número de días de la cuota |
| dis_intento | tinyint | 1   | NOT NULL | Cantidad de intentos |
| dis_prorroga | char | 1   | NOT NULL | Indica si tiene prórroga en su pago |
| dis_fecha_can | smalldatetime | 4   | NULL | Fecha de cancelación de la cuota. |

### ca_estados_man_ts

Transacción de servicio de la tabla que almacena la parametrización de los cambios de estados automáticos/manuales por producto

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **DESCRIPCIÓN** |
| --- | --- | --- | --- | --- |
| ems_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| ems_fecha_ts | datetime | 8   | NOT NULL | Fecha de la transacción |
| ems_usuario_ts | login | 14  | NOT NULL | Usuario que realiza la transacción |
| ems_oficina_ts | smallint | 2   | NOT NULL | Oficinal de la transacción |
| ems_terminal_ts | varchar | 30  | NOT NULL | Terminal del usuario que realiza la transacción |
| ems_toperacion | catalogo | 10  | NOT NULL | Tipo de producto de cartera |
| ems_tipo_cambio | char | 1   | NOT NULL | Tipo de cambio<br><br>D = POR DIVIDENDO<br><br>M = MANUAL |
| ems_estado_ini | tinyint | 1   | NOT NULL | Estado inicial |
| ems_estado_fin | tinyint | 1   | NOT NULL | Estado final |
| ems_dias_cont | int | 4   | NULL | Días iniciales |

### ca_operacion_datos_adicionales_ts

Transacción de servicio de la tabla que almacena la información de los datos adicionales de una operación, relacionados al estado de gestión de cobranza de las operaciones, lo cual indica según el estado si permite o no realizar pagos; también incluye un campo para identificar el grupo contable de acuerdo a las combinaciones de garantías asociadas a un préstamo.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| oda_secuencial_ts | int | 4   | NOT NULL | Secuencial único por cada registro de las transacciones de servicio. |
| oda_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha proceso en la que se realiza la transacción de servicio. |
| oda_fecha_ts | datetime | 8   | NOT NULL | Fecha real en la que se realiza la transacción de servicio. |
| oda_usuario_ts | login | 14  | NOT NULL | Usuario que realiza la transacción |
| oda_oficina_ts | smallint | 2   | NOT NULL | Oficina desde donde se realizó la transacción. |
| oda_terminal_ts | varchar | 30  | NOT NULL | Terminal del usuario que realiza la transacción |
| oda_accion_ts | char | 1   | NOT NULL | Tipo de acción que se realizó como transacción.<br><br>I = Ingreso<br><br>U = Actualización<br><br>D = Eliminación |
| oda_orden_accion_ts | char | 1   | NOT NULL | Identifica si el registro tiene los datos de antes o después de realizar la acción.<br><br>A = Antes<br><br>D: Después |
| oda_operación_ts | int | 4   | NOT NULL | Número de operación de cartera. |
| oda_estado_gestion_cobranza_ts | catalogo | 10  | NULL | Catálogo del estado de gestión de cobranza. Los valores vienen del catálogo (ca_estado_gestion_cobranza) |
| oda_aceptar_pagos_ts | char | 1   | NULL | Indica si el estado de gestión de cobranza acepta o no pagos. Este campo puede tomar como valor por defecto un valor del catálogo ca_pago_gestion_cobranza, que está relacionado con el catálogo del campo oda_estado_gestion_cobranza. |
| oda_grupo_contable_ts | catalogo | 10  | NOT NULL | Valores del catálogo: cr_combinacion_gar, el cual contiene el grupo de combinación de garantías asociadas a un préstamo |
| oda_categoria_plazo_ts | catalogo | 10  | NOT NULL | Valores del catalogo: ca_categoria_plazo, el cual identifica sin el préstamo es: L: Largo Plazo, C: Corto Plazo |
| oda_tipo_documento_fiscal_ts | varchar | 3   | NULL | Identifica el tipo de documento fiscal para generar una factura electrónica. Tiene valores del catálogo ca_tipo_documento_fiscal<br><br>CCF: Comprobante de Crédito Fiscal<br><br>FCF: Factura Consumidor Final |

### ca_operacion_ts

Transacción de servicio utilizada para almacenar la información maestra de los préstamos de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| ops_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| ops_fecha_ts | datetime | 8   | NOT NULL | Fecha de la transacción |
| ops_usuario_ts | login | 14  | NOT NULL | Usuario de la transacción |
| ops_oficina_ts | smallint | 2   | NOT NULL | Oficina de la transacción |
| ops_terminal_ts | varchar | 30  | NOT NULL | Terminal donde se realiza la transacción |
| ops_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| ops_banco | cuenta | 24  | NOT NULL | Número banco del préstamo |
| ops_anterior | cuenta | 24  | NULL | Número banco del préstamo anterior si fue renovación |
| ops_migrada | cuenta | 24  | NULL | Número banco del préstamo, información de la migración |
| ops_tramite | int | 4   | NULL | Número del trámite asignado |
| ops_cliente | int | 4   | NULL | Código del cliente principal del préstamo |
| ops_nombre | descripcion | 160 | NULL | Nombre del cliente |
| ops_sector | catalogo | 10  | NOT NULL | Sector del préstamo |
| ops_toperacion | catalogo | 10  | NOT NULL | Tipo de producto de cartera |
| ops_oficina | smallint | 2   | NOT NULL | Oficina donde fue dado de alta el préstamo |
| ops_moneda | tinyint | 1   | NOT NULL | Moneda del préstamo |
| ops_comentario | varchar | 255 | NULL | Cambio de observación para comentarios |
| ops_oficial | smallint | 2   | NOT NULL | Código del oficial |
| ops_fecha_ini | datetime | 8   | NOT NULL | Fecha de inicio del préstamo |
| ops_fecha_fin | datetime | 8   | NOT NULL | Fecha fin del préstamo |
| ops_fecha_ult_proceso | datetime | 8   | NOT NULL | Fecha que indica la última fecha que fue procesado el préstamo en los procesos batch |
| ops_fecha_liq | datetime | 8   | NULL | Fecha de la liquidación/desembolso del préstamo |
| ops_fecha_reajuste | datetime | 8   | NULL | Fecha del próximo reajuste de intereses |
| ops_monto | money | 8   | NOT NULL | Monto solicitado |
| ops_monto_aprobado | money | 8   | NOT NULL | Monto aprobado para ser desembolsado |
| ops_destino | catalogo | 10  | NOT NULL | Catalogo que indica cual es el destino del préstamo |
| ops_lin_credito | cuenta | 24  | NULL | Código banco de la línea de crédito, indica si el préstamo está asociado a una línea/cupo. |
| ops_ciudad | int | 4   | NOT NULL | Código de la ciudad donde se ha ingresado el préstamo |
| ops_estado | tinyint | 1   | NOT NULL | Catalogo que indica el estado actual del préstamo<br><br>0 = NO VIGENTE<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO<br><br>4 = CASTIGADO<br><br>5 = JUDICIAL<br><br>6 = ANULADO<br><br>7 = CONDONADO<br><br>8 = DIFERIDO<br><br>9 = SUSPENSO<br><br>99 = EN CREDITO<br><br>66 = GRUPAL VIGENTE |
| ops_periodo_reajuste | smallint | 2   | NULL | Cada cuantos periodos reajusta |
| ops_reajuste_especial | char | 1   | NULL | Si posee reajuste especial<br><br>S = SI<br><br>N = NO |
| ops_tipo | char | 1   | NOT NULL | Clase del préstamo<br><br>N = PRESTAMO DE CARTERA<br><br>L = LEASING<br><br>D = DESCUENTO DOCUMENTO<br><br>P = PRESTAMO INTERESES PREPAGADOS<br><br>P = PRESTAMO PASIVO |
| ops_forma_pago | catalogo | 10  | NULL | Catalogo que indica como cancela el cliente las cuotas, en efectivo, debito en cuenta, etc. |
| ops_cuenta | cuenta | 24  | NULL | Si es debito en cuenta indica este campo el número de la cuenta |
| ops_dias_anio | smallint | 2   | NOT NULL | Días para cálculo de intereses:<br><br>360, 365, 366 |
| ops_tipo_amortizacion | varchar | 10  | NOT NULL | FRANCESA, ALEMANA, MANUAL |
| ops_cuota_completa | char | 1   | NOT NULL | Si paga cuota completa o no<br><br>S = SI<br><br>N = NO |
| ops_tipo_cobro | char | 1   | NOT NULL | Si paga intereses acumulados o proyectados<br><br>A =Paga acumulados<br><br>P =Paga proyectados |
| ops_tipo_reduccion | char | 1   | NOT NULL | Si paga cuotas adelantadas que tipo de reducción aplica<br><br>C = Reducción de monto de cuota<br><br>T = Reducción de tiempo<br><br>N = No aplica reducción |
| ops_aceptar_anticipos | char | 1   | NOT NULL | Si acepta pagos anticipados<br><br>S = SI<br><br>N =NO |
| ops_precancelacion | char | 1   | NOT NULL | Si el préstamo permite precancelación<br><br>S = SI<br><br>N =NO |
| ops_tipo_aplicacion | char | 1   | NOT NULL | Tipo de aplicación:<br><br>D = Aplica por dividendo<br><br>C = Aplica por concepto |
| ops_tplazo | catalogo | 10  | NULL | Tipo de plazo<br><br>M = mensual<br><br>A = anual<br><br>S = semestral<br><br>T = trimestral<br><br>B = bimestral<br><br>Q = quincenal<br><br>W = semanal<br><br>D = diario |
| ops_plazo | smallint | 2   | NULL | Plazo dado de acuerdo al tipo de plazo |
| ops_tdividendo | catalogo | 10  | NULL | Tipo de cuota<br><br>Tipo de plazo<br><br>M = Mensual<br><br>A = anual<br><br>………………….. |
| ops_periodo_cap | smallint | 2   | NULL | Cada cuantas cuotas paga capital |
| ops_periodo_int | smallint | 2   | NULL | Cada cuantas cuotas paga interés |
| ops_dist_gracia | char | 1   | NULL | Si tiene distribución de gracia<br><br>S = SI<br><br>N =NO |
| ops_gracia_cap | smallint | 2   | NULL | Si tiene gracia de capital<br><br>S = SI<br><br>N =NO |
| ops_gracia_int | smallint | 2   | NULL | Si tiene gracia de interés<br><br>S = SI<br><br>N =NO |
| ops_dia_fijo | tinyint | 1   | NULL | Si paga en día fijo almacena el número del día del mes |
| ops_cuota | money | 8   | NULL | Monto de la cuota pactada |
| ops_evitar_feriados | char | 1   | NULL | Si las cuotas ha sido generadas evitando los días feriados<br><br>S = SI<br><br>N =NO |
| ops_num_renovacion | tinyint | 1   | NULL | Indica el número de renovaciones que ha tenido el préstamo |
| ops_renovacion | char | 1   | NULL | Indica si permite renovación<br><br>S = SI<br><br>N =NO |
| ops_mes_gracia | tinyint | 1   | NOT NULL | Indica el número del mes de gracia, en este mes no se pone a disposición el cobro de cuota |
| ops_reajustable | char | 1   | NOT NULL | Indica si el préstamo es reajustable de intereses<br><br>S = SI<br><br>N =NO |
| ops_dias_clausula | int | 4   | NOT NULL | Cantidad de días de la clausula |
| ops_divcap_original | smallint | 2   | NULL | Dividendo del capital original |
| ops_clausula_aplicada | char | 1   | NULL | Indica si tiene clausula a aplicar (S/N) |
| ops_traslado_ingresos | char | 1   | NULL | Indica si tiene traslados de ingresos |
| ops_periodo_crecimiento | smallint | 2   | NULL | Código de periodo de crecimiento |
| ops_tasa_crecimiento | float | 8   | NULL | Columna en desuso |
| ops_direccion | tinyint | 1   | NULL | Código de dirección |
| ops_opcion_cap | char | 1   | NULL | Indica si hay tasa para capital |
| ops_tasa_cap | float | 8   | NULL | Contiene la TEA de la operación. |
| ops_dividendo_cap | smallint | 2   | NULL | Código del dividendo capital |
| ops_clase | catalogo | 10  | NOT NULL | Código de la clase |
| ops_origen_fondos | catalogo | 10  | NULL | Código de los orígenes de los fondos |
| ops_calificacion | char | 1   | NULL | Calificacion del préstamo |
| ops_estado_cobranza | catalogo | 10  | NULL | Estado de la cobranza |
| ops_numero_reest | int | 4   | NOT NULL | Cantidad de reajustes que tiene el préstamo |
| ops_edad | int | 4   | NULL | Edad del préstamo |
| ops_tipo_crecimiento | char | 1   | NULL | Tipo de crecimiento del préstamo |
| ops_base_calculo | char | 1   | NULL | Indica el tipo de base de cálculo |
| ops_prd_cobis | tinyint | 1   | NULL | Código de producto cobis |
| ops_ref_exterior | cuenta | 24  | NULL | Referencia del préstamo del exterior |
| ops_sujeta_nego | char | 1   | NULL | Indica si esta sujeta a negociación (S/N) |
| ops_dia_habil | char | 1   | NULL | Indica si solo trabaja con días hábiles |
| ops_recalcular_plazo | char | 1   | NULL | Indica si se puede recalcular el plazo |
| ops_usar_tequivalente | char | 1   | NULL | Indica si se puede usar tasa equivalente |
| ops_fondos_propios | char | 1   | NOT NULL | Indica si tiene fondos propios |
| ops_nro_red | varchar | 24  | NULL | Indica el número de red |
| ops_tipo_redondeo | tinyint | 1   | NULL | Código de tipo de redondeo |
| ops_sal_pro_pon | money | 8   | NULL | Valor del saldo |
| ops_tipo_empresa | catalogo | 10  | NULL | Código de tipo de empresa |
| ops_validacion | catalogo | 10  | NULL | Código de tipo de validación |
| ops_fecha_pri_cuot | datetime | 8   | NULL | Fecha de primera cuota |
| ops_gar_admisible | char | 1   | NULL | Indica si admite garantías |
| ops_causacion | char | 1   | NULL | Indica si hay causación |
| ops_convierte_tasa | char | 1   | NULL | Indica si se puede convertir la tasa |
| ops_grupo_fact | int | 4   | NULL | Código del grupo de facturación |
| ops_tramite_ficticio | int | 4   | NULL | Código del tramite ficticio |
| ops_tipo_linea | catalogo | 10  | NOT NULL | Código del tipo de línea |
| ops_subtipo_linea | catalogo | 10  | NULL | Código del subtipo de línea |
| ops_bvirtual | char | 1   | NOT NULL | Indica si se puede ver en medios virtuales |
| ops_extracto | char | 1   | NOT NULL | Indica si se pueden generar extractos |
| ops_num_deuda_ext | cuenta | 24  | NULL | Código de número de deuda externa (banco segundo piso) |
| ops_fecha_embarque | datetime | 8   | NULL | Fecha embarque |
| ops_fecha_dex | datetime | 8   | NULL | Fecha DEX |
| ops_reestructuracion | char | 1   | NULL | Indica si hubo reestructuración |
| ops_tipo_cambio | char | 1   | NULL | Indica si hubo tipo de cambio |
| ops_naturaleza | char | 1   | NULL | Indica la naturaleza de la operación<br><br>A = Activa<br><br>P = Pasiva |
| ops_pago_caja | char | 1   | NULL | Indica si se puede realizar pagos por cajas |
| ops_nace_vencida | char | 1   | NULL | Indica si la operación nace vencida |
| ops_num_comex | cuenta | 24  | NULL | Código de la operación de comercio exterior |
| ops_calcula_devolucion | char | 1   | NULL | Indica si se calcula devolución |
| ops_codigo_externo | cuenta | 24  | NULL | Código externo banco segundo piso |
| ops_margen_redescuento | float | 8   | NULL | Valor del margen de redescuento |
| ops_entidad_convenio | catalogo | 10  | NULL | Código de la entidad convenio |
| ops_pproductor | char | 1   | NULL | Indica si el préstamo es de un productor |
| ops_fecha_ult_causacion | datetime | 8   | NULL | Fecha de ultima causación |
| ops_mora_retroactiva | char | 1   | NULL | Indica si hay mora retroactiva |
| ops_calificacion_ant | char | 1   | NULL | Indica la calificación anterior |
| ops_cap_susxcor | money | 8   | NULL | Valor de la capitalización suspendida. |
| ops_prepago_desde_lavigente | char | 1   | NULL | Indica si existe un prepago vigente |
| ops_fecha_ult_mov | datetime | 8   | NULL | Fecha de ultimo movimiento (batch) |
| ops_fecha_prox_segven | datetime | 8   | NULL | Fecha de próximo vencimiento de seguro |
| ops_suspendio | char | 1   | NULL | Indica si fue suspendida |
| ops_fecha_suspenso | datetime | 8   | NULL | Fecha de suspenso |
| ops_honorarios_cobranza | char | 1   | NULL | Indica si hay honorarios por cobranza |
| ops_banca | catalogo | 10  | NULL | Código de la banca |
| ops_promocion | char | 1   | NULL | Indica si hay promoción |
| ops_acepta_ren | char | 1   | NULL | Indica si hay aceptación de renovación |
| ops_no_acepta | varchar | 1000 | NULL | Comentario porque no acepta |
| ops_emprendimiento | char | 1   | NULL | Código de emprendimiento |
| ops_valor_cat | float | 8   | NULL | Contiene la TIR de la operación. |
| ops_grupo | int | 4   | NULL | Código de Grupo |
| ops_ref_grupal | cuenta | 24  | NULL | Referencial Grupal |
| ops_grupal | char | 1   | NULL | Pertenece a un grupo |
| ops_fondeador | tinyint | 1   | NULL | Código del fondeador |
| ops_admin_individual | char | 1   | NULL | Tipo de administración de operaciones grupales que contiene la definición al momento de crear la operación de si el tipo de préstamo grupal se administra por la operación padre o por las operaciones hijas.<br><br>S = Admin operación hija<br><br>N = Admin operación padre |
| ops_estado_hijas | char | 1   | NULL | Indica el estado de las operaciones hijas asociadas a una operación grupal. |
| ops_tipo_renovacion | char | 1   | NULL | Si la operación fue Renovada o Refinanciada. Catalogo "ca_tipo_renovacion".<br><br>R: Renovacion<br><br>F: Refinanciamiento |
| ops_tipo_reest | char | 1   | NULL | Tipos de reestructuacion /modificación de la operación. |
| ops_fecha_reest | datetime | 8   | NULL | Fecha cuando se aplico modificación de la operación de tipo reestructuración. |
| ops_fecha_reest_noestandar | datetime | 8   | NULL | Fecha cuando se aplico modificación de la operación de tipo diferimiento u otro. |

### ca_reajuste_det_ts

Transacción de servicio para el proceso de reajuste de la tabla ca_reajuste_det

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| reds_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso de la transacción |
| reds_fecha_ts | datetime | 8   | NOT NULL | Fecha de ingreso del registro |
| reds_usuario_ts | login | 14  | NOT NULL | Usuario de la transacción |
| reds_oficina_ts | smallint | 2   | NOT NULL | Oficina que realiza la transacción |
| reds_terminal_ts | varchar | 30  | NOT NULL | Terminal de donde se ejecuta la transacción |
| reds_secuencial | int | 4   | NOT NULL | Secuencial de la operación asignado al reajuste |
| red_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| reds_concepto | catalogo | 10  | NOT NULL | Concepto/rubro aplicado en el reajuste |
| reds_referencial | catalogo | 10  | NULL | Catálogo de la tasa referencial del reajuste |
| reds_signo | char | 1   | NULL | Signo de ajuste + - \* / |
| reds_factor | float | 8   | NULL | Factor de reajuste |
| reds_porcentaje | float | 8   | NULL | Porcentaje de reajuste |

### ca_reajuste_ts

Transacción de servicio para el proceso de reajuste de la tabla ca_reajuste

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| res_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso de la transacción |
| res_fecha_ts | datetime | 8   | NOT NULL | Fecha de ingreso del registro |
| res_usuario_ts | login | 14  | NOT NULL | Usuario de la transacción |
| res_oficina_ts | smallint | 2   | NOT NULL | Oficina que realiza la transacción |
| res_terminal_ts | varchar | 30  | NOT NULL | Terminal de donde se ejecuta la transacción |
| res_secuencial | int | 4   | NOT NULL | Secuencial de la transacción |
| res_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| res_fecha | datetime | 8   | NOT NULL | Fecha de la transacción |
| res_reajuste_especial | char | 1   | NOT NULL | Si es reajuste especial<br><br>S = SI<br><br>N = NO |
| res_desagio | char | 1   | NULL | Código de desagio |
| res_sec_aviso | int | 4   | NULL | Código del aviso |

### ca_rubro_op_ts

Tabla de transacción de servicio que contiene los rubros que están cargados por cada operación de cartera

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| ros_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| ros_fecha_ts | datetime | 8   | NOT NULL | Fecha de la transacción |
| ros_usuario_ts | login | 14  | NOT NULL | Usuario de la transacción |
| ros_oficina_ts | smallint | 2   | NOT NULL | Código de la Oficina |
| ros_terminal_ts | varchar | 30  | NOT NULL | Código de la Terminal que realiza la transacción |
| ros_operacion | int | 4   | NOT NULL | Número interno de operación de cartera |
| ros_concepto | catalogo | 10  | NOT NULL | Rubro/Concepto del préstamo |
| ros_tipo_rubro | char | 1   | NOT NULL | En que instancia se cobra el rubro:<br><br>L = en la liquidación<br><br>M = Multa/otros cargos<br><br>P = Periódico en las cuotas<br><br>A = Anticipado |
| ros_fpago | char | 1   | NOT NULL | En que instancia se cobra el rubro:<br><br>L = en la liquidación<br><br>M = Multa/otros cargos<br><br>P = Periódico en las cuotas<br><br>A = Anticipado |
| ros_prioridad | tinyint | 1   | NOT NULL | Prioridad de cobro |
| ros_paga_mora | char | 1   | NOT NULL | Si aplica mora<br><br>S = SI<br><br>N = NO |
| ros_provisiona | char | 1   | NOT NULL | Si provisiona<br><br>S = SI<br><br>N = NO |
| ros_signo | char | 1   | NULL | Signo de ajuste +, -, \*, / |
| ros_factor | float | 8   | NULL | Porcentaje de ajuste |
| ros_referencial | catalogo | 10  | NULL | Tasa referencial de ajuste |
| ros_signo_reajuste | char | 1   | NULL | Signo para reajuste +, -, \*, / |
| ros_factor_reajuste | float | 8   | NULL | Porcentaje de reajuste |
| ros_referencial_reajuste | catalogo | 10  | NULL | Tasa referencial de reajuste |
| ros_valor | money | 8   | NOT NULL | Valor/Monto fijo |
| ros_porcentaje | float | 8   | NOT NULL | Porcentaje de la tasa |
| ros_gracia | money | 8   | NULL | Monto de gracia |
| ros_concepto_asociado | catalogo | 10  | NULL | Rubro/Concepto asociado al concepto principal |
| ros_base_calculo | money | 8   | NULL | Base de calculo |
| ros_financiado | char | 1   | NULL | Si es un rubro financiado<br><br>S = SI<br><br>N = NO |
| ros_tasa_minima | float | 8   | NULL | Porcentaje de tasa mínima |
| ros_porcentaje_aux | float | 8   | NOT NULL | Porcentaje de la tasa auxiliar |
| ros_redescuento | float | 8   | NULL | Valor de redescuento |
| ros_intermediacion | float | 8   | NULL | Valor de intermediación |
| ros_principal | char | 1   | NOT NULL | Indica si es principal o no |
| ros_porcentaje_efa | float | 8   | NULL | Porcentaje del EFA |
| ros_garantia | money | 8   | NOT NULL | Valor de la garantía |
| ros_tipo_puntos | char | 1   | NULL | Indica el tipo de puntos |
| ros_saldo_op | char | 1   | NULL | Indica si hay saldo operativo |
| ros_saldo_por_desem | char | 1   | NULL | Indica si hay saldo por desembolso |
| ros_num_dec | tinyint | 1   | NULL | Número de decimales |
| ros_limite | char | 1   | NULL | Indica si tiene limites o no |
| ros_iva_siempre | char | 1   | NULL | Indica si cobrará iva siempre |
| ros_monto_aprobado | char | 1   | NULL | Indica si hay monto aprobado |
| ros_porcentaje_cobrar | float | 8   | NULL | Porcentaje a probar |
| ros_tipo_garantia | varchar | 64  | NULL | Tipo de Garantia |
| ros_nro_garantia | cuenta | 24  | NULL | Número de garantía |
| ros_porcentaje_cobertura | char | 1   | NULL | Indica si la cobertura de garantía es por porcentaje |
| ros_valor_garantia | char | 1   | NULL | Indica si la cobertura de la garantía es por valor |
| ros_tperiodo | catalogo | 10  | NULL | Indica el tipo de periodo |
| ros_periodo | smallint | 2   | NULL | Código de periodo |
| ros_tabla | varchar | 30  | NULL | Indica el tipo de tabla |
| ros_saldo_insoluto | char | 1   | NULL | Indica si hay saldo insoluto |
| ros_calcular_devolucion | char | 1   | NULL | Indica si hay que calcular la devolución. |
| ros_tasa_maxima | float | 8   | NULL | Porcentaje de tasa máxima |

### ca_rubro_ts

Tabla de transacción de servicio que contiene los rubros para el proceso de carga de rubros

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| rus_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| rus_fecha_ts | datetime | 8   | NOT NULL | Fecha de transacción |
| rus_usuario_ts | login | 14  | NOT NULL | Usuario de la transacción |
| rus_oficina_ts | smallint | 2   | NOT NULL | Oficina de la transacción |
| rus_terminal_ts | varchar | 30  | NOT NULL | Terminal donde se realizó la transacción |
| rus_toperacion | catalogo | 10  | NOT NULL | Código del tipo de producto de cartera |
| rus_moneda | tinyint | 1   | NOT NULL | Moneda del producto |
| rus_concepto | catalogo | 10  | NOT NULL | Rubro/concepto asociado al producto |
| rus_prioridad | tinyint | 1   | NOT NULL | Prioridad de cobro |
| rus_tipo_rubro | catalogo | 10  | NOT NULL | Tipo de rubro:<br><br>C = CAPITAL<br><br>F = FECI<br><br>I = INTERES<br><br>M = MORA<br><br>O = PORCENTAJE<br><br>V = VALOR FIJO |
| rus_paga_mora | char | 1   | NOT NULL | Si aplica mora<br><br>S = SI<br><br>N = NO |
| rus_provisiona | char | 1   | NOT NULL | Si provisiona<br><br>S = SI<br><br>N = NO |
| rus_fpago | char | 1   | NOT NULL | En que instancia se cobra el rubro:<br><br>L = en la liquidación<br><br>M = Multa/otros cargos<br><br>P = Periódico en las cuotas<br><br>T = Anticipado Total |
| rus_crear_siempre | char | 1   | NOT NULL | Si al crear la operación se tiene que crear también el rubro<br><br>S = SI<br><br>N = NO |
| rus_tperiodo | catalogo | 10  | NULL | Tipo de periodo |
| rus_periodo | smallint | 2   | NULL | Número de periodo |
| rus_referencial | catalogo | 10  | NULL | Referencial a aplicar |
| rus_reajuste | catalogo | 10  | NULL | Valor o referencial a aplicar en cambio de tasa |
| rus_banco | char | 1   | NOT NULL | Catálogo de quien pertenece el rubro<br><br>I = Institución (BANCO)<br><br>G =Gobierno (Impuesto)<br><br>P = por pagar terceros |
| rus_estado | catalogo | 10  | NOT NULL | Estado del rubro<br><br>V = Vigente<br><br>B =Bloqueado<br><br>C =Cancelado<br><br>E = Eliminado<br><br>X = producto deshabilitado |
| rus_concepto_asociado | catalogo | 10  | NULL | Código del Rubro/concepto asociado |
| rus_valor_max | money | 8   | NULL | Valor máximo del rubro |
| rus_valor_min | money | 8   | NULL | Valor mínimo del rubro |
| rus_afectacion | smallint | 2   | NULL | Campo no se usa. |
| rus_diferir | char | 1   | NOT NULL | Indica si hay que diferir<br><br>S = SI<br><br>N = NO |
| rus_tipo_seguro | catalogo | 10  | NULL | Catálogos de tipo de seguro |
| rus_tasa_efectiva | char | 1   | NULL | Indica si hay tasa efectiva<br><br>S = SI<br><br>N = NO |
| rus_redescuento | float | 8   | NULL | Valor de redescuento |
| rus_intermediacion | float | 8   | NULL | Valor de intermediación |
| rus_principal | char | 1   | NULL | Indica si es principal o no |
| rus_saldo_op | char | 1   | NULL | Indica si tiene saldo operativo |
| rus_saldo_por_desem | char | 1   | NULL | Indica si tiene saldo por desembolso |
| rus_pit | catalogo | 10  | NULL | Código del PIT |
| rus_limite | char | 1   | NULL | Indica si tiene límites |
| rus_mora_interes | char | 1   | NULL | Indica si aplica mora por interés |
| rus_iva_siempre | char | 1   | NULL | Indica si se cobra siempre el iva |
| rus_monto_aprobado | char | 1   | NULL | Indica si existe monto aprobado |
| rus_porcentaje_cobrar | float | 8   | NULL | Tipo de garantía aplicada |
| rus_tipo_garantia | varchar | 64  | NULL | Indica si existe un valor de garantía a ingresar |
| rus_valor_garantia | char | 1   | NULL | Indica si la garantía será por un porcentaje |
| rus_porcentaje_cobertura | char | 1   | NULL | Indica que tipo de tabla aplicar |
| rus_tabla | varchar | 30  | NULL | Indica si hay o no saldo insoluto |
| rus_saldo_insoluto | char | 1   | NULL | Indica si se calcula la devolución |
| rus_calcular_devolucion | char | 1   | NULL | Tipo de garantía aplicada |
| rus_tasa_aplicar | char | 1   | NULL | Indica si hay tasa a aplicar |
| rus_financiado | char | 1   | NULL | Si es un rubro financiado<br><br>S = SI<br><br>N = NO |
| rus_tasa_maxima | float | 8   | NULL | Porcentaje de la tasa máxima |
| rus_tasa_minima | float | 8   | NULL | Porcentaje de la tasa mínima |

### ca_valor_det_ts

Tabla de transacción de servicio para la tabla ca_valor_det

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| vds_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| vds_fecha_ts | datetime | 8   | NOT NULL | Fecha de la transacción |
| vds_usuario_ts | login | 14  | NOT NULL | Usuario de la transacción |
| vds_oficina_ts | smallint | 2   | NOT NULL | Oficina donde se realiza la transacción |
| vds_terminal_ts | varchar | 30  | NOT NULL | Terminal donde se realiza la transacción |
| vds_tipo | varchar | 10  | NOT NULL | Catálogo de tipo de tasa |
| vds_sector | catalogo | 10  | NOT NULL | Sector/Banca de la tasa |
| vds_signo_default | char | 1   | NULL | Signo por default +, - , \*, / |
| vds_valor_default | float | 8   | NULL | Monto por default |
| vds_signo_maximo | char | 1   | NULL | Signo máximo +, - , \*, / |
| vds_valor_maximo | float | 8   | NULL | Monto máximo |
| vds_signo_minimo | char | 1   | NULL | Signo mínimo +, - , \*, / |
| vds_valor_minimo | float | 8   | NULL | Valor mínimo |
| vds_referencia | varchar | 10  | NULL | Tasa referencial |
| vds_tipo_puntos | char | 1   | NULL | Indica el tipo de puntos |
| vds_num_dec | tinyint | 1   | NULL | Número de decimales |

### ca_valor_referencial_ts

Tabla de transacción de servicio de la tabla ca_valor_referencial

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| vrs_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| vrs_fecha_ts | datetime | 8   | NOT NULL | Fecha de la transacción |
| vrs_usuario_ts | login | 14  | NOT NULL | Usuario de la transacción |
| vrs_oficina_ts | smallint | 2   | NOT NULL | Oficina de la transacción |
| vrs_terminal_ts | varchar | 30  | NOT NULL | Termina que realiza la transacción |
| vrs_secuencial | int | 4   | NOT NULL | Secuencial del registro |
| vrs_tipo | varchar | 10  | NOT NULL | Catálogo de tipo de tasa |
| vrs_valor | float | 8   | NOT NULL | Valor referencial |
| vrs_fecha_vig | datetime | 8   | NOT NULL | Fecha de vigencia |

### ca_valor_ts

Tabla de parametrización de tasas

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LO NG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| vas_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha de proceso |
| vas_fecha_ts | datetime | 8   | NOT NULL | Fecha de la transacción |
| vas_usuario_ts | login | 14  | NOT NULL | Usuario de la transacción |
| vas_oficina_ts | smallint | 2   | NOT NULL | Oficina de la transacción |
| vas_terminal_ts | varchar | 30  | NOT NULL | Terminal que realiza la transacción |
| vas_tipo | varchar | 10  | NOT NULL | Tipo de tasa |
| vas_descripcion | varchar | 64  | NOT NULL | Descripción de la tasa |
| vas_clase | char | 1   | NOT NULL | Si es valor o factor<br><br>V = Valor<br><br>F = Factor |
| vas_prime | char | 1   | NULL | Código PRIME |
| vas_pit | char | 1   | NULL | Código PIT |

### ca_pin_odp_ts

Tabla donde se almacenan las transacciones de servicio de los pines necesarios para validar autenticación y así poder desembolsar el préstamo

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| po_secuencial_ts | int | 4   | NOT NULL | Secuencial único por cada registro de las transacciones de servicio. |
| po_fecha_proceso_ts | datetime | 8   | NOT NULL | Fecha proceso en la que se realiza la transacción de servicio. |
| po_fecha_ts | datetime | 8   | NOT NULL | Fecha real en la que se realiza la transacción de servicio. |
| po_usuario_ts | login | 14  | NOT NULL | Usuario que realiza la transacción |
| po_oficina_ts | smallint | 2   | NOT NULL | Oficina desde donde se realiza la transacción |
| po_terminal_ts | varchar | 30  | NOT NULL | Terminal desde donde se realiza la transacción |
| po_accion_ts | char | 1   | NOT NULL | Tipo de acción que se realizó como transacción.<br><br>I = Ingreso<br><br>B = Bloqueo<br><br>D = Desbloqueo<br><br>A = Anulación |
| po_operación_ts | int | 4   | NOT NULL | Código largo de la operación |
| po_desembolso_ts | tinyint | 1   | NOT NULL | Código del desembolso |
| po_secuencial_desembolso_ts | int | 4   | NOT NULL | Secuencial del desembolso |
| po_secuencial_pin_ts | int | 4   | NOT NULL | Secuencial del pin |
| po_pin_ts | int | 4   | NOT NULL | PIN |
| po_fecha_generacion_ts | smalldatetime | 4   | NULL | Fecha de generación |
| po_fecha_vencimiento_ts | smalldatetime | 4   | NULL | Fecha de vencimiento del pin |
| po_fecha_bloqueo_ts | smalldatetime | 4   | NULL | Fecha de bloqueo del pin |
| po_fecha_anulacion_ts | smalldatetime | 4   | NULL | Fecha de anulación del pin |
| po_estado_ts | char | 1   | NULL | (N=NORMAL/B=BLOQUEADO/A=ANULADO) |

### ca_proc_rubro_calculados_ts

Tabla donde se almacenan los parámetros a utilizarse para el procesamiento del cálculo del valor de los rubros calculados.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| prc_id_proc_rubro | int | 4   | NOT NULL | Identificador de la tabla. |
| prc_operacion | int | 4   | NOT NULL | Número de la operación de cartera. |
| prc_fecha_real | datetime | 8   | NOT NULL | Fecha real en la que se realizó el procesamiento del rubro calculado |
| prc_rubro | catalogo | 10  | NULL | Rubro al cual se procesó el cálculo del valor |
| prc_tramite | int | 4   | NULL | Número de trámite de la operación al que pertenece el rubro calculado |
| prc_dias_frecuencia | smallint | 2   | NULL | Días de frecuencia de la cuota del préstamo |
| prc_plazo | smallint | 2   | NULL | Plazo del préstamo |
| prc_frecuencia_cuotas | catalogo | 10  | NULL | Tipo de frecuencia del préstamo (MES(ES), A-O(S), etc). |
| prc_tipo_amortizacion | varchar | 10  | NULL | Tipo de tabla de amortización. |
| prc_es_grupal | varchar | 10  | NULL | Indica si es una operación 'INDIVIDUAL' o una operación 'GRUPAL'. |
| prc_monto_solicitado | money | 8   | NULL | Monto solicitado del préstamo al que pertenece el rubro calculado |
| prc_monto_autorizado | money | 8   | NULL | Monto autorizado del préstamo al que pertenece el rubro calculado |
| prc_monto_financiado | money | 8   | NULL | Monto total financiado del préstamo al que pertenece el rubro calculado |
| prc_producto | catalogo | 10  | NULL | Nombre del producto de cartera, viene del catálogo ca_toperacion. |
| prc_tasa | float | 8   | NULL | Tasa de interés nominal anual del préstamo al que pertenece el rubro calculado. |
| prc_tasa_IVA | float | 8   | NULL | Tasa o porcentaje IVA configurado en el sistema. |
| prc_oficina | smallint | 2   | NULL | Oficina desde donde se creó el préstamo al que pertenece el rubro calculado. |
| prc_fecha_desembolso | datetime | 8   | NULL | Fecha de desembolso del préstamo al que pertenece el rubro calculado. |
| prc_tipo_persona | char | 1   | NULL | Código del cliente del préstamo. |
| prc_fecha_nac | datetime | 8   | NULL | Fecha de nacimiento del cliente del préstam |
| prc_destino | catalogo | 10  | NULL | Código del destino del préstamo. |
| prc_clase_cartera | catalogo | 10  | NULL | Clase de cartera del préstamo, viene del catálogo cr_clase_cartera. |
| prc_nro_deudores | smallint | 2   | NULL | Número de deudores asociados al préstamo. Préstamo Individual: 1<br><br>Préstamo Grupal: Integrantes de la solicitud grupal. |
| prc_nro_codeudores | smallint | 2   | NULL | Número de codeudores asociados al préstamo (En grupal no hay codeudores). |
| prc_nro_fiadores | smallint | 2   | NULL | Número de fiadores (Garantías personales) asociadas al préstamo (En Grupal no hay fiadores). |
| prc_pertenece_linea | char | 1   | NULL | Indica si el préstamo pertenece a una línea de crédito vigente. |
| prc_aprobado_linea | money | 8   | NULL | Monto aprobado de la línea de crédito del préstamo (si aplica). |
| prc_disponible_linea | money | 8   | NULL | Monto disponible de la línea de crédito del préstamo (si aplica). |
| prc_tipo_solicitud | char | 1   | NULL | Indica si el préstamo es Normal, Reestructurado, Renovado, etc. |
| prc_moneda | tinyint | 1   | NULL | Código de la Moneda asociada al préstamo. |
| prc_fecha_ven | datetime | 8   | NULL | Fecha de vencimiento del préstamo. |
| prc_nro_integrantes | smallint | 2   | NULL | Número de integrantes del grupo en solicitudes grupal, en solicitud individual es uno. |

### ca_incentivos_metas_ts

Tabla donde se almacenan todos los movimientos que se realizan en registros de metas para incentivos, sean operaciones masivas o individuales.

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| ims_id_metas_ts | int |     | NOT NULL | Identificador de la tabla. |
| ims_fecha_proceso_ts | datetime | 16  | NOT NULL | Fecha proceso del sistema. |
| ims_fecha_real_ts | datetime | 16  | NOT NULL | Fecha real en la que se realizó el movimiento. |
| ims_usuario_ts | login | 14  | NOT NULL | Login de usuario que realiza el movimiento |
| ims_oficina_ts | smallint |     | NOT NULL | Oficina del oficial al que se le realiza el movimiento |
| ims_terminal_ts | varchar | 30  | NOT NULL | Terminal del usuario que realiza el movimiento |
| ims_opcion_ts | char | 1   | NOT NULL | Opción del movimiento:<br><br>M - Carga Masiva<br><br>U - Actualización masiva<br><br>A - Actualización individual |
| ims_accion_ts | char | 1   | NOT NULL | Acción realizada en el movimiento del registro:<br><br>I - Inserción de registro<br><br>U - Actulización de registro<br><br>D - Eliminación de registro |
| ims_anio | smallint |     | NOT NULL | Año del registro al que se le realiza el movimiento |
| ims_oficina | smallint |     | NOT NULL | Oficina del oficial al que se le realiza el movimiento. |
| ims_cod_asesor | smallint |     | NOT NULL | Codigo del oficial al que se le realiza el movimiento |
| ims_mes | tinyint |     | NOT NULL | Mes del registro al que se le esta realizando el movimiento. |
| ims_nombre_asesor | varchar | 64  | NOT NULL | Nombre del oficial al que se le realiza el movimiento. |
| ims_monto_proyectado | money |     | NOT NULL | Monto con el cambio al que se le realiza el movimiento. |
| ims_observacion_ts | varchar | 255 | NOT NULL | Descripción del movimiento. |

## INDICES POR CLAVE PRIMARIA

Creación de los índices por clave primaria definidos para las tablas del sistema Cartera

**Indice:** ca_abono_det_1

**Tipo de Indice**: UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_abono_det

**Columnas combinadas:** abd_operacion, abd_secuencial_ing, abd_tipo, abd_concepto, abd_cuenta

**Indice:** ca_abono_det_tmp_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_abono_det_tmp

**Columnas combinadas**: abdt_user, abdt_sesn, abdt_tipo, abdt_concepto

**Indice:** ca_abono_prioridad_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_abono_prioridad

**Columnas combinadas:** ap_operacion, ap_secuencial_ing, ap_concepto

**Indice:** ca_abono_prioridad_tmp_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_abono_prioridad_tmp

**Columnas combinadas:** apt_operacion, apt_secuencial_ing, apt_concepto

**Indice:** ca_amortizacion_1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_amortizacion

**Columnas combinadas:** am_operacion, am_dividendo, am_concepto, am_secuencia

**Indice:** ca_ciclo_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_ciclo

**Columnas combinadas:** ci_grupo, ci_ciclo

**Indice:** ca_comision_diferida1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_comision_diferida

**Columnas combinadas:** cd_operacion, cd_concepto

**Indice:** ca_comision_diferida_his1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_comision_diferida_his

**Columnas combinadas:** cdh_secuencial, cdh_operacion, cdh_concepto

**Indice:** ca_datos_adicionales_pasiva1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_datos_adicionales_pasivas

**Columnas combinadas:** dap_operacion, dat_operacion

**Indice:** ca_decodificador_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_decodificador

**Columnas combinadas:** dc_user, dc_sesn, dc_operacion, dc_fila, dc_columna

**Indice:** ca_default_toperacion_1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_default_toperacion

**Columnas combinadas:** dt_toperacion, dt_moneda

**Indice:** ca_desembolso_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_desembolso

**Columnas combinadas:** dm_operacion, dm_secuencial, dm_desembolso

**Indice:** ca_dividendo_1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_dividendo

**Columnas combinadas:** di_operacion, di_dividendo

**Indice:** ca_estado_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_estado

**Columnas combinadas:** es_codigo

**Indice:** ca_estados_man_1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_estados_man

**Columnas combinadas:** em_toperacion, em_tipo_cambio, em_estado_ini, em_estado_fin

**Indice:** ca_operacion_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_operacion

**Indice:** ca_operacion_7

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_banco

**Indice:** ca_operacion_his_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_operacion_his

**Columnas combinadas:** oph_operacion, oph_secuencial

**Indice:** ca_otro_cargo_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_otro_cargo

**Columnas combinadas:** oc_operacion, oc_secuencial

**Indice:** PK_ca_producto

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_producto

**Columnas combinadas:** cp_producto

**Indice:** ca_reajuste_det_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_reajuste_det

**Columnas combinadas:** red_operacion, red_secuencial, red_concepto

**Indice:** ca_rubro_1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_rubro

**Columnas combinadas:** ru_toperacion, ru_moneda, ru_concepto

**Indice:** ca_rubro_op_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_rubro_op

**Columnas combinadas:** ro_operacion, ro_concepto

**Indice:** ca_secuencial_atx_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_secuencial_atx

**Columnas combinadas:** sa_operacion, sa_secuencial_cca

**Indice:** ca_valor_1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_valor

**Columnas combinadas:** va_tipo

**Indice:** ca_valor_det_1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_valor_det

**Columnas combinadas:** vd_tipo, vd_sector

**Indice:** ca_control_rubros_diferidos1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_control_rubros_diferidos

**Columnas combinadas:** crd_operacion, crd_dividendo, crd_concepto

**Indice:** ca_pin_odp1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_pin_odp

**Columnas combinadas:** po_operacion, po_desembolso, po_secuencial_desembolso, po_secuencial_pin

**Indice:** ca_operacion_datos_adicionales1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_operacion_datos_adicionales

**Columnas combinadas:** oda_operación

**Indice:** ca_operacion_datos_adicionales_ts1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_operacion_datos_adicionales_ts

**Columnas combinadas:** oda_secuencial_ts

**Indice:** ca_pin_odp_ts2

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_pin_odp_ts

**Columnas combinadas:** po_secuencial_ts

**Indice:** ca_registra_traslados_masivos

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_registra_traslados_masivos

**Columnas combinadas:** rt_secuencial_traslado

**Indice:** ca_reg_tra_m_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_registra_traslados_masivos

**Columnas combinadas:** rt_secuencial_traslado

**Indice:** ca_traslados_cartera_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_traslados_cartera

**Columnas combinadas:** trc_fecha_proceso, trc_cliente, trc_operacion

**Indice:** ca_proc_rubro_calculados_ts_1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_proc_rubro_calculados_ts

**Columnas combinadas:** prc_id_proc_rubro

**Indice:** ca_incentivos_metas_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_incentivos_metas

**Columnas combinadas:** im_anio, im_mes, im_oficina, im_cod_asesor

**Indice:** ca_incentivos_metas_ts_1

**Tipo de Indice:** UNIQUE NONCLUSTERED INDEX

**Tabla:** ca_incentivos_metas_ts

**Columnas combinadas:** ims_id_metas_ts, ims_anio, ims_mes, ims_oficina, ims_cod_asesor

## INDICES POR CLAVE FORANEA

Creación de los índices por clave foránea definidos para las tablas del sistema Cartera.

**Indice:** ca_abono_1

**Tipo de Indice:** CLUSTERED INDEX

**Tabla:** ca_abono

**Columnas combinadas:** ab_secuencial_ing, ab_operacion

**Indice:** ca_abono_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_abono

**Columnas combinadas:** ab_secuencial_pag

**Indice:** ca_abono_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_abono

**Columnas combinadas**: ab_estado

**Indice:** ca_abono_5

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_abono

**Columnas combinadas:** ab_fecha_pag

**Indice:** ca_abono_idx6

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_abono

**Columnas combinadas:** ab_secuencial_rpa, ab_secuencial_ing, ab_operacion, ab_fecha_ing

**Indice:** ca_amortizacion_idx2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_amortizacion

**Columnas combinadas:** am_concepto, am_operacion, am_dividendo, am_cuota, am_gracia, am_pagado

**Indice:** ca_amortizacion_his_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_amortizacion_his

**Columnas combinadas:** amh_operacion, amh_secuencial

**Indice:** ca_amortizacion_his_idx2

**Tipo de Indice**: NONCLUSTERED INDEX

**Tabla:** ca_amortizacion_his

**Columnas combinadas:** amh_secuencial, amh_operacion, amh_dividendo, amh_concepto, amh_estado, amh_periodo, amh_cuota, amh_gracia, amh_pagado, amh_acumulado, amh_secuencia

**Indice:** idx1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_amortizacion_tmp

**Columnas combinadas:** amt_operacion, amt_concepto, amt_dividendo

**Indice:** ca_conversion_1

**Tipo de Indice:** CLUSTERED INDEX

**Tabla:** ca_conversion

**Columnas combinadas:** cv_oficina

**Indice:** ca_default_toperacion_ts_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_default_toperacion_ts

**Columnas combinadas:** dts_fecha_proceso_ts

**Indice:** ca_default_toperacion_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_default_toperacion_ts

**Columnas combinadas:** dts_fecha_ts

**Indice:** ca_default_toperacion_ts_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_default_toperacion_ts

**Columnas combinadas:** dts_usuario_ts

**Indice:** ca_default_toperacion_ts_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_default_toperacion_ts

**Columnas combinadas:** dts_oficina_ts

**Indice:** ca_desembolso_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_desembolso

**Columnas combinadas:** dm_fecha, dm_estado

**Indice:** ca_det_ciclo_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_det_ciclo

**Columnas combinadas:** dc_grupo, dc_ciclo_grupo, dc_cliente, dc_ciclo

**Indice:** ca_det_trn_1

**Tipo de Indice:** CLUSTERED INDEX

**Tabla:** ca_det_trn

**Columnas combinadas:** dtr_secuencial, dtr_operacion, dtr_dividendo, dtr_codvalor

**Indice:** ca_dividendo_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_dividendo

**Columnas combinadas:** di_operacion, di_estado

**Indice:** ca_dividendo_idx3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla**: ca_dividendo

**Columnas combinadas:** di_estado, di_operacion, di_dividendo, di_fecha_ven, di_gracia

**Indice:** ca_dividendo_his_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_dividendo_his

**Columnas combinadas:** dih_operacion, dih_secuencial

**Indice: idx1**

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_dividendo_tmp

**Columnas combinadas:** dit_operacion, dit_dividendo

**Indice:** ca_errorlog_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_errorlog

**Columnas combinadas:** er_fecha_proc, er_cuenta

**Indice:** ca_estados_man_ts_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_estados_man_ts

**Columnas combinadas:** ems_fecha_proceso_ts

**Indice:** ca_estados_man_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_estados_man_ts

**Columnas combinadas:** ems_fecha_ts

**Indice:** ca_estados_man_ts_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_estados_man_ts

**Columnas combinadas:** ems_usuario_ts

**Indice:** ca_estados_man_ts_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_estados_man_ts

**Columnas combinadas:** ems_oficina_ts

**Indice:** ca_operacion_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla: c**a_operacion

**Columnas combinadas:** op_migrada

**Indice:** ca_operacion_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_tramite

**Indice:** ca_operacion_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_cliente

**Indice:** ca_operacion_5

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_oficial

**Indice:** ca_operacion_6

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_oficina

**Indice:** ca_operacion_8

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_lin_credito

**Indice:** ca_operacion_9

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_estado, op_fecha_liq, op_tramite, op_oficial

**Indice:** ca_operacion_10

**Tipo de Indice**: NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_oficial, op_tramite, op_cliente, op_estado

**Indice:** ca_operacion_idx11

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion

**Columnas combinadas:** op_naturaleza, op_fecha_ult_proceso, op_cuenta, op_operacion, op_estado, op_forma_pago

**Indice:** idx1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion_tmp

**Columnas combinadas:** opt_operacion

**Indice:** idx2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion_tmp

**Columnas combinadas:** opt_tramite

**Indice:** ca_operacion_ts_idx1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion_ts

**Columnas combinadas:** ops_operacion

**Indice:** idx1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_provision_cartera

**Columnas combinadas:** pc_fecha_proceso

**Indice:** idx2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_provision_cartera

**Columnas combinadas:** pc_operacion

**Indice:** ca_reajuste_1

**Tipo de Indice:** CLUSTERED INDEX

**Tabla:** ca_reajuste

**Columnas combinadas:** re_operacion, re_fecha

**Indice:** ca_reajuste_det_ts_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_reajuste_det_ts

**Columnas combinadas**: reds_fecha_proceso_ts

**Indice:** ca_reajuste_det_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_reajuste_det_ts

**Columnas combinadas:** reds_fecha_ts

**Indice:** ca_reajuste_det_ts_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_reajuste_det_ts

**Columnas combinadas:** reds_usuario_ts

**Indice**: ca_reajuste_det_ts_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_reajuste_det_ts

**Columnas combinadas:** reds_oficina_ts

**Indice:** ca_reajuste_ts_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_reajuste_ts

**Columnas combinadas:** res_fecha_proceso_ts

**Indice:** ca_reajuste_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_reajuste_ts

**Columnas combinadas**: res_fecha_ts

**Indice:** ca_reajuste_ts_3

**Tipo de Indice**: NONCLUSTERED INDEX

**Tabla:** ca_reajuste_ts

**Columnas combinadas:** res_usuario_ts

**Indice:** ca_reajuste_ts_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_reajuste_ts

**Columnas combinadas:** res_oficina_ts

**Indice:** ca_rubro_op_idx2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_op

**Columnas combinadas:** ro_operacion, ro_tipo_rubro, ro_concepto, ro_porcentaje, ro_fpago

**Indice:** ca_rubro_op_idx3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_op

**Columnas combinadas:** ro_operacion, ro_provisiona, ro_tipo_rubro, ro_concepto, ro_fpago, ro_valor, ro_porcentaje, ro_concepto_asociado, ro_porcentaje_efa, ro_num_dec

**Indice:** ca_rubro_op_idx4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_op

**Columnas combinadas:** ro_operacion, ro_paga_mora, ro_concepto, ro_fpago

**Indice:** ca_rubro_op_his_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_op_his

**Columnas combinadas:** roh_operacion, roh_secuencial

**Indice:** idx1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_op_tmp

**Columnas combinadas:** rot_operacion, rot_concepto

**Indice:** ca_rubro_op_tmp_idx2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_op_tmp

**Columnas combinadas:** rot_operacion, rot_tipo_rubro

**Indice:** ca_rubro_ts_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_ts

**Columnas combinadas:** rus_fecha_proceso_ts

**Indice:** ca_rubro_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_ts

**Columnas combinadas:** rus_fecha_ts

**Indice:** ca_rubro_ts_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_ts

**Columnas combinadas:** rus_usuario_ts

**Indice:** ca_rubro_ts_4

**Tipo de Indice**: NONCLUSTERED INDEX

**Tabla:** ca_rubro_ts

**Columnas combinadas:** rus_oficina_ts

**Indice:** ca_tasas_I1

**Tipo de Indice:** CLUSTERED INDEX

**Tabla:** ca_tasas

**Columnas combinadas:** ts_operacion, ts_dividendo, ts_fecha, ts_concepto

**Indice:** ca_transaccion_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_transaccion

**Columnas combinadas:** tr_fecha_mov, tr_tran, tr_ofi_usu

**Indice:** ca_transaccion_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_transaccion

**Columnas combinadas:** tr_fecha_mov, tr_comprobante

**Indice:** ca_transaccion_5

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_transaccion

**Columnas combinadas:** tr_tran, tr_estado, tr_fecha_ref, tr_secuencial, tr_fecha_mov, tr_toperacion, tr_banco, tr_secuencial_ref

**Indice:** ca_transaccion_idx6

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_transaccion

**Columnas combinadas:** tr_operacion, tr_secuencial, tr_tran, tr_estado

**Indice:** ca_transaccion_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_transaccion

**Columnas combinadas:** tr_operacion, tr_secuencial

**Indice:** ca_transaccion_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_transaccion

**Columnas combinadas:** tr_banco

**Indice:** ca_valor_det_ts_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_det_ts

**Columnas combinadas:** vds_fecha_proceso_ts

**Indice:** ca_valor_det_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_det_ts

**Columnas combinadas:** vds_fecha_ts

**Indice:** ca_valor_det_ts_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_det_ts

**Columnas combinadas:** vds_usuario_ts

**Indice:** ca_valor_det_ts_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_det_ts

**Columnas combinadas:** vds_oficina_ts

**Indice:** ca_valor_referencial_ts_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_referencial_ts

**Columnas combinadas:** vrs_fecha_proceso_ts

**Indice**: ca_valor_referencial_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_referencial_ts

**Columnas combinadas:** vrs_fecha_ts

**Indice:** ca_valor_referencial_ts_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_referencial_ts

**Columnas combinadas:** vrs_usuario_ts

**Indice:** ca_valor_referencial_ts_4

**Tipo de Indice**: NONCLUSTERED INDEX

**Tabla:** ca_valor_referencial_ts

**Columnas combinadas:** vrs_oficina_ts

**Indice:** ca_valor_ts_1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_ts

**Columnas combinadas:** vas_fecha_proceso_ts

**Indice:** ca_valor_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_ts

**Columnas combinadas:** vas_fecha_ts

**Indice:** ca_valor_ts_3

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_ts

**Columnas combinadas:** vas_usuario_ts

**Indice:** ca_valor_ts_4

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_valor_ts

**Columnas combinadas:** vas_oficina_ts

**Indice:** ca_control_rubros_diferidos_his1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_control_rubros_diferidos_his

**Columnas combinadas:** crdh_operacion, crdh_secuencial

**Indice:** ca_operacion_datos_adicionales_ts2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_operacion_datos_adicionales_ts

**Columnas combinadas:** oda_operacion_ts

**Indice:** ca_pin_odp_ts1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_pin_odp_ts

**Columnas combinadas:** po_operacion_ts

**Indice:** ca_traslados_cartera_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_traslados_cartera

**Columnas combinadas:** trc_cliente, trc_estado

**Indice:** ca_proc_rubro_calculados_ts_2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_proc_rubro_calculados_ts

**Columnas** combinadas: prc_operacion

**Indice:** ca_rubro_op_ts1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_rubro_op_ts

**Columnas combinadas:** ros_secuencial_ts

**Indice:** ca_rubro_op_ts2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_rubro_op_ts

**Columnas combinadas:** ros_operacion, ros_concepto, ros_fecha_proceso_ts

**Indice:** ca_dividendo_ts1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_dividendo_ts

**Columnas combinadas:** dis_secuencial_ts

**Indice:** ca_rubro_op_ts2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_dividendo_ts

**Columnas combinadas:** dis_operacion, dis_dividendo, dis_fecha_proceso_ts

**Indice:** ca_intefaz_pago1

**Tipo de Indice:** UNIQUE CLUSTERED INDEX

**Tabla:** ca_intefaz_pago

**Columnas combinadas:** ip_id_inter

**Indice:** ca_rubro_op_ts2

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_intefaz_pago

**Columnas combinadas:** ip_operacionca, ip_fecha_pago

**Indice:** ca_7x24_sal_pres_key

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_7x24_saldos_prestamos

**Columnas combinadas:** sp_fecha_proceso,sp_num_banco

**Indice:** ca_7x24_errores_key

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_7x24_errores

**Columnas combinadas:** er_fecha_proceso

**Indice:** ca_cambio_estado_masivo_idx1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_cambio_estado_masivo

**Columnas combinadas:** cem_fecha_proceso, cem_op_banco

**Indice:** ca_qr_transacciones_tmp1

**Tipo de Indice:** NONCLUSTERED INDEX

**Tabla:** ca_qr_transacciones_tmp

**Columnas combinadas:** trt_user, trt_sesn