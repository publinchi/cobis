# ca_amortizacion

## Descripción

Tabla que contiene la información detallada de los rubros por cada dividendo de la tabla de amortización. Almacena los valores de capital, interés y otros conceptos para cada cuota del préstamo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| am_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| am_dividendo | smallint | 2 | NOT NULL | Número de dividendo/cuota |
| am_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| am_estado | tinyint | 1 | NOT NULL | Estado del rubro<br><br>0 = Vigente<br><br>1 = Cancelado<br><br>2 = Vencido<br><br>3 = Castigado |
| am_cuota | money | 8 | NOT NULL | Monto de la cuota proyectada |
| am_gracia | char | 1 | NOT NULL | Indica si el dividendo está en período de gracia<br><br>S = Si<br><br>N = No |
| am_pagado | money | 8 | NOT NULL | Monto pagado del rubro |
| am_acumulado | money | 8 | NOT NULL | Monto acumulado del rubro |
| am_en_mora | money | 8 | NOT NULL | Monto en mora del rubro |

## Índices

- **ca_amortizacion_1** (CLUSTERED INDEX): am_operacion, am_dividendo, am_concepto
- **ca_amortizacion_2** (NONCLUSTERED INDEX): am_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
