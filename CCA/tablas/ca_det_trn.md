# ca_det_trn

## Descripción

Tabla que almacena el detalle de las transacciones realizadas en el módulo de cartera. Contiene el desglose de cada movimiento por concepto y dividendo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dtr_secuencial | int | 4 | NOT NULL | Secuencial de la transacción |
| dtr_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| dtr_dividendo | smallint | 2 | NOT NULL | Número de dividendo |
| dtr_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| dtr_estado | tinyint | 1 | NOT NULL | Estado del rubro en el momento de la transacción |
| dtr_monto | money | 8 | NOT NULL | Monto de la transacción |
| dtr_monto_mn | money | 8 | NOT NULL | Monto en moneda nacional |
| dtr_cotizacion | money | 8 | NOT NULL | Cotización aplicada |
| dtr_tcotizacion | char | 1 | NOT NULL | Tipo de cotización<br><br>C = Compra<br><br>V = Venta |
| dtr_afectacion | char | 1 | NOT NULL | Tipo de afectación<br><br>D = Débito<br><br>C = Crédito |
| dtr_monto_cont | money | 8 | NULL | Monto contabilizado |

## Índices

- **ca_det_trn_1** (NONCLUSTERED INDEX): dtr_secuencial, dtr_operacion, dtr_dividendo, dtr_concepto
- **ca_det_trn_2** (NONCLUSTERED INDEX): dtr_operacion

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
