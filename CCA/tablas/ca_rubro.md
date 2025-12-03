# ca_rubro

## Descripción

Tabla de parametrización de rubros del módulo de cartera. Define las características y comportamiento de cada rubro que se puede aplicar a las operaciones.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ru_codigo | catalogo | 10 | NOT NULL | Código del rubro |
| ru_descripcion | descripcion | 64 | NOT NULL | Descripción del rubro |
| ru_concepto | catalogo | 10 | NOT NULL | Concepto asociado al rubro |
| ru_tipo | char | 1 | NOT NULL | Tipo de rubro<br><br>C = Capital<br><br>I = Interés<br><br>M = Mora<br><br>S = Seguro<br><br>O = Otros |
| ru_prioridad | tinyint | 1 | NOT NULL | Prioridad de aplicación |
| ru_genera_saldo | char | 1 | NOT NULL | Si genera saldo<br><br>S = Si<br><br>N = No |
| ru_afecta_mora | char | 1 | NOT NULL | Si afecta cálculo de mora<br><br>S = Si<br><br>N = No |
| ru_contabiliza | char | 1 | NOT NULL | Si contabiliza<br><br>S = Si<br><br>N = No |
| ru_estado | char | 1 | NOT NULL | Estado del rubro<br><br>V = Vigente<br><br>I = Inactivo |

## Índices

- **ca_rubro_1** (UNIQUE NONCLUSTERED INDEX): ru_codigo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
