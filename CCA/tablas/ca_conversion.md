# ca_conversion

## Descripción

Tabla de control que almacena los secuenciales utilizados en diferentes procesos del módulo de cartera. Permite llevar un control de numeración única.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| cv_tipo | char | 3 | NOT NULL | Tipo de secuencial<br><br>OPE = Operación<br><br>TRN = Transacción<br><br>PAG = Pago<br><br>RPA = Registro de pago |
| cv_secuencial | int | 4 | NOT NULL | Último secuencial utilizado |
| cv_fecha | datetime | 8 | NOT NULL | Fecha de actualización del secuencial |

## Índices

- **ca_conversion_1** (UNIQUE NONCLUSTERED INDEX): cv_tipo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
