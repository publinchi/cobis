# ca_abono_det

## Descripción

Es un registro de la información de las formas de pago y los montos entregados por el cliente para realizar un pago, se genera un registro por cada forma de pago.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| abd_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| abd_secuencial_ing | int | 4 | NOT NULL | Secuencial único de ingreso del pago |
| abd_tipo | char | 3 | NOT NULL | PAG = Pago,<br><br>CON= Condonación de deuda<br><br>SOB= Sobrante automático |
| abd_concepto | catalogo | 10 | NOT NULL | Forma de cobro |
| abd_cuenta | cuenta | 24 | NOT NULL | Se utiliza en una forma de Pago con categoría "Banco Corresponsal" o "Monedero Electronico", contiene el código de cuenta del Banco Corresponsal / Proveedor. |
| abd_beneficiario | char | 50 | NOT NULL | Se utiliza para almacenar el campo de Referencia de pago ingresado desde frontEnd (Ej: #Boleta). |
| abd_moneda | tinyint | 1 | NOT NULL | Moneda del pago |
| abd_monto_mpg | money | 8 | NOT NULL | Monto pagado |
| abd_monto_mop | money | 8 | NOT NULL | Monto en la moneda de la operación |
| abd_monto_mn | money | 8 | NOT NULL | Monto en moneda nacional |
| abd_cotizacion_mpg | money | 8 | NOT NULL | Cotización de la moneda del pago |
| abd_cotizacion_mop | money | 8 | NOT NULL | Cotización de la moneda de la operación |
| abd_tcotizacion_mpg | char | 1 | NOT NULL | Tipo de cotización de la moneda del pago |
| abd_tcotizacion_mop | char | 1 | NOT NULL | Tipo de cotización de la moneda de la operación |
| abd_cheque | int | 4 | NULL | Número cheque |
| abd_cod_banco | catalogo | 10 | NULL | Se utiliza en una forma de Pago con categoría "Banco Corresponsal" o "Monedero Electronico", contiene el código de Banco / Proveedor. |
| abd_inscripcion | int | 4 | NULL | Columna de desuso |
| abd_carga | int | 4 | NULL | Columna de desuso |
| abd_porcentaje_con | float | 8 | NULL | Porcentaje de condonación. En está versión registra el monto del pago |
| abd_solidario | char | 1 | NOT NULL | Identificación de pago solidario<br><br>N = No<br><br>S = Si |

## Índices

- **ca_abono_det_1** (UNIQUE NONCLUSTERED INDEX): abd_operacion, abd_secuencial_ing, abd_tipo, abd_concepto, abd_cuenta

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
