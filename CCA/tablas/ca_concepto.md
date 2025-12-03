# ca_concepto

## Descripción

Tabla de parametrización que define los conceptos o rubros que se manejan en el módulo de cartera (capital, interés, seguros, comisiones, etc.). Es una tabla maestra de configuración.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| co_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| co_descripcion | descripcion | 64 | NOT NULL | Descripción del concepto |
| co_tipo | char | 1 | NOT NULL | Tipo de concepto<br><br>C = Capital<br><br>I = Interés<br><br>M = Mora<br><br>S = Seguro<br><br>O = Otros |
| co_categoria | catalogo | 10 | NOT NULL | Categoría del concepto |
| co_estado | char | 1 | NOT NULL | Estado del concepto<br><br>V = Vigente<br><br>I = Inactivo |
| co_contabiliza | char | 1 | NOT NULL | Indica si contabiliza<br><br>S = Si<br><br>N = No |
| co_prioridad | tinyint | 1 | NOT NULL | Prioridad de aplicación del concepto |

## Índices

- **ca_concepto_1** (UNIQUE NONCLUSTERED INDEX): co_concepto

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
