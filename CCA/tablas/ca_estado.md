# ca_estado

## Descripción

Tabla de catálogo que define los estados posibles de los préstamos en el módulo de cartera. Es una tabla maestra de configuración.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| es_codigo | tinyint | 1 | NOT NULL | Código del estado |
| es_descripcion | descripcion | 64 | NOT NULL | Descripción del estado |
| es_permite_transacciones | char | 1 | NOT NULL | Si permite transacciones en este estado<br><br>S = Si<br><br>N = No |
| es_permite_pagos | char | 1 | NOT NULL | Si permite pagos en este estado<br><br>S = Si<br><br>N = No |
| es_genera_interes | char | 1 | NOT NULL | Si genera intereses en este estado<br><br>S = Si<br><br>N = No |
| es_genera_mora | char | 1 | NOT NULL | Si genera mora en este estado<br><br>S = Si<br><br>N = No |
| es_activo | char | 1 | NOT NULL | Si el estado está activo<br><br>S = Si<br><br>N = No |

## Índices

- **ca_estado_1** (UNIQUE NONCLUSTERED INDEX): es_codigo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
