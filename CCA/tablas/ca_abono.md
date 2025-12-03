# ca_abono

## Descripción

Es un registro de la información de las características y negociación que el cliente definió al momento de realizar un pago, es un registro de cabecera. También contiene los secuenciales de las transacciones de pagos y registro de pagos.

## Estructura de la Tabla

| **Nombre del campo** | **Tipo de dato** | **LONG** | **Car.de dato** | **Descripción** |
| --- | --- | --- | --- | --- |
| ab_operacion | int | 4 | NOT NULL | Número de operación de cartera |
| ab_secuencial_ing | int | 4 | NOT NULL | Secuencial único de ingreso del pago |
| ab_secuencial_rpa | int | 4 | NOT NULL | Secuencial asociado a la transacción RPA |
| ab_secuencial_pag | int | 4 | NOT NULL | Secuencial de la transacción PAG |
| ab_fecha_ing | datetime | 8 | NOT NULL | Fecha de ingreso del pago |
| ab_fecha_pag | datetime | 8 | NOT NULL | Fecha de aplicación del pago |
| ab_cuota_completa | char | 1 | NOT NULL | Si el pago aplica cuota completa |
| ab_aceptar_anticipos | char | 1 | NOT NULL | Si acepta anticipos |
| ab_tipo_reduccion | char | 1 | NOT NULL | Si regenera la tabla que tipo de reducción realiza:<br><br>N = Pago normal/adelantado<br><br>C = Reducción de cuota<br><br>T = Reducción de tiempo |
| ab_tipo_cobro | char | 1 | NOT NULL | Tipo de cobro:<br><br>P = proyectado<br><br>A = acumulado |
| ab_dias_retencion_ini | int | 4 | NOT NULL | Días de retención inicial |
| ab_dias_retencion | int | 4 | NOT NULL | Días de retención |
| ab_estado | char | 3 | NOT NULL | Estado del pago<br><br>ING = ingresado<br><br>A = Aplicado<br><br>RV = Reversado<br><br>E = Eliminado |
| ab_usuario | login | 14 | NOT NULL | Usuario de aplicación del pago |
| ab_oficina | smallint | 2 | NOT NULL | Oficina que ingresa el pago |
| ab_terminal | descripcion | 160 | NOT NULL | Terminal del usuario que ingresa el pago |
| ab_tipo | char | 3 | NOT NULL | Tipo de abono<br><br>PAG = Pago |
| ab_tipo_aplicacion | char | 1 | NOT NULL | Si el pago se aplica por<br><br>D = Dividendo<br><br>C = Rubro |
| ab_nro_recibo | int | 4 | NOT NULL | Secuencial generado para el recibo. Campo no se usa en esta versión |
| ab_tasa_prepago | Float | 8 | NULL | Porcentaje de la tasa de interés del préstamo |
| ab_dividendo | smallint | 2 | NULL | Número de dividendo para aplicar el pago |
| ab_calcula_devolucion | char | 1 | NULL | Indica si calcula devolución<br><br>S = SI<br><br>N = NO<br><br>Campo no se usa en esta versión |
| ab_prepago_desde_lavigente | char | 1 | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_prepago_desde_lavigente de la tabla ca_default_toperacion. |
| ab_extraordinario | char | 1 | NULL | Permite abono extraordinario<br><br>N = No<br><br>S = Si |
| ab_secuencial_ing_abono_grupal | int | 4 | NULL | Secuencial que solo se registra a operaciones hijas y que identifica el registro de abono Operación Padre (ab_secuencial). |
| ab_ssn | int | 4 | NULL | Secuencial de sesión el cual identifica los registros de tanqueo para facturación electrónica del pago (cob_externos). |
| ab_guid_dte | varchar | 36 | NULL | Número único que apunta a un dte en los registros de tanqueo para facturación electrónica (cob_externos). |

## Índices

- **ca_abono_1** (CLUSTERED INDEX): ab_secuencial_ing, ab_operacion
- **ca_abono_3** (NONCLUSTERED INDEX): ab_secuencial_pag
- **ca_abono_4** (NONCLUSTERED INDEX): ab_estado
- **ca_abono_5** (NONCLUSTERED INDEX): ab_fecha_pag
- **ca_abono_idx6** (NONCLUSTERED INDEX): ab_secuencial_rpa, ab_secuencial_ing, ab_operacion, ab_fecha_ing

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
