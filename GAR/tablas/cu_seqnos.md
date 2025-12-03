# cu_seqnos

## Descripción

Tabla usada para generar secuenciales únicos por sucursal y tipo de garantía.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| se_filial | Tinyint | 1 | NOT NULL | Código de filial |
| se_sucursal | Smallint | 2 | NOT NULL | Código de la sucursal |
| se_codigo | descripcion | 64 | NOT NULL | Tipo de custodia |
| se_actual | Int | 4 | NOT NULL | Número secuencial actual |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
