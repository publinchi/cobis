# ca_otro_cargo

## Descripción

Tabla que almacena cargos adicionales que se pueden aplicar a las operaciones de cartera, fuera de los conceptos regulares de la tabla de amortización.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| oc_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| oc_secuencial | int | 4 | NOT NULL | Secuencial del cargo |
| oc_concepto | catalogo | 10 | NOT NULL | Código del concepto del cargo |
| oc_monto | money | 8 | NOT NULL | Monto del cargo |
| oc_fecha_generacion | datetime | 8 | NOT NULL | Fecha de generación del cargo |
| oc_fecha_vencimiento | datetime | 8 | NOT NULL | Fecha de vencimiento del cargo |
| oc_estado | char | 1 | NOT NULL | Estado del cargo<br><br>V = Vigente<br><br>P = Pagado<br><br>A = Anulado |
| oc_observacion | varchar | 255 | NULL | Observaciones del cargo |
| oc_usuario | login | 14 | NOT NULL | Usuario que generó el cargo |
| oc_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| oc_monto_pagado | money | 8 | NOT NULL | Monto pagado del cargo |

## Índices

- **ca_otro_cargo_1** (UNIQUE NONCLUSTERED INDEX): oc_operacion, oc_secuencial
- **ca_otro_cargo_2** (NONCLUSTERED INDEX): oc_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
