# ca_abono_det_tmp

## Descripción

Tabla temporal que almacena el detalle de las formas de pago durante el proceso de ingreso de un pago, antes de su aplicación definitiva.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| adt_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| adt_secuencial_ing | int | 4 | NOT NULL | Secuencial único de ingreso del pago |
| adt_tipo | char | 3 | NOT NULL | PAG = Pago,<br><br>CON= Condonación de deuda<br><br>SOB= Sobrante automático |
| adt_concepto | catalogo | 10 | NOT NULL | Forma de cobro |
| adt_cuenta | cuenta | 24 | NOT NULL | Se utiliza en una forma de Pago con categoría "Banco Corresponsal" o "Monedero Electronico", contiene el código de cuenta del Banco Corresponsal / Proveedor. |
| adt_beneficiario | char | 50 | NOT NULL | Se utiliza para almacenar el campo de Referencia de pago ingresado desde frontEnd (Ej: #Boleta). |
| adt_moneda | tinyint | 1 | NOT NULL | Moneda del pago |
| adt_monto_mpg | money | 8 | NOT NULL | Monto pagado |
| adt_monto_mop | money | 8 | NOT NULL | Monto en la moneda de la operación |
| adt_monto_mn | money | 8 | NOT NULL | Monto en moneda nacional |
| adt_cotizacion_mpg | money | 8 | NOT NULL | Cotización de la moneda del pago |
| adt_cotizacion_mop | money | 8 | NOT NULL | Cotización de la moneda de la operación |
| adt_tcotizacion_mpg | char | 1 | NOT NULL | Tipo de cotización de la moneda del pago |
| adt_tcotizacion_mop | char | 1 | NOT NULL | Tipo de cotización de la moneda de la operación |
| adt_cheque | int | 4 | NULL | Número cheque |
| adt_cod_banco | catalogo | 10 | NULL | Se utiliza en una forma de Pago con categoría "Banco Corresponsal" o "Monedero Electronico", contiene el código de Banco / Proveedor. |
| adt_inscripcion | int | 4 | NULL | Columna de desuso |
| adt_carga | int | 4 | NULL | Columna de desuso |
| adt_porcentaje_con | float | 8 | NULL | Porcentaje de condonación. En está versión registra el monto del pago |
| adt_solidario | char | 1 | NOT NULL | Identificación de pago solidario<br><br>N = No<br><br>S = Si |

## Índices

- **ca_abono_det_tmp_1** (UNIQUE NONCLUSTERED INDEX): adt_operacion, adt_secuencial_ing, adt_tipo, adt_concepto, adt_cuenta

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
