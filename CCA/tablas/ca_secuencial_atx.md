# ca_secuencial_atx

## Descripción

Tabla que almacena la relación de secuenciales entre diferentes transacciones del módulo de cartera. Permite llevar el control de la trazabilidad entre operaciones relacionadas.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| sa_secuencial | int | 4 | NOT NULL | Secuencial principal |
| sa_tipo_secuencial | char | 3 | NOT NULL | Tipo de secuencial<br><br>TRN = Transacción<br><br>PAG = Pago<br><br>RPA = Registro de pago |
| sa_secuencial_relacionado | int | 4 | NOT NULL | Secuencial relacionado |
| sa_tipo_relacionado | char | 3 | NOT NULL | Tipo de secuencial relacionado |
| sa_operacion | int | 4 | NOT NULL | Número de operación |
| sa_fecha | datetime | 8 | NOT NULL | Fecha de la relación |
| sa_estado | char | 1 | NOT NULL | Estado de la relación<br><br>V = Vigente<br><br>R = Reversado |

## Índices

- **ca_secuencial_atx_1** (UNIQUE NONCLUSTERED INDEX): sa_secuencial, sa_tipo_secuencial
- **ca_secuencial_atx_2** (NONCLUSTERED INDEX): sa_secuencial_relacionado, sa_tipo_relacionado
- **ca_secuencial_atx_3** (NONCLUSTERED INDEX): sa_operacion

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
