# ca_amortizacion_tmp

## Descripción

Tabla temporal que almacena la información de rubros por dividendo durante procesos de simulación o modificación de la tabla de amortización, antes de su aplicación definitiva.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| amt_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| amt_dividendo | smallint | 2 | NOT NULL | Número de dividendo/cuota |
| amt_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| amt_estado | tinyint | 1 | NOT NULL | Estado del rubro<br><br>0 = Vigente<br><br>1 = Cancelado<br><br>2 = Vencido<br><br>3 = Castigado |
| amt_cuota | money | 8 | NOT NULL | Monto de la cuota proyectada |
| amt_gracia | char | 1 | NOT NULL | Indica si el dividendo está en período de gracia<br><br>S = Si<br><br>N = No |
| amt_pagado | money | 8 | NOT NULL | Monto pagado del rubro |
| amt_acumulado | money | 8 | NOT NULL | Monto acumulado del rubro |
| amt_en_mora | money | 8 | NOT NULL | Monto en mora del rubro |

## Índices

- **ca_amortizacion_tmp_1** (CLUSTERED INDEX): amt_operacion, amt_dividendo, amt_concepto

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
