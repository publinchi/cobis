# cu_estados_garantia

## Descripción

Almacena la información sobre el mantenimiento de los estados de la garantía.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **DESCRIPCION** |
| --- | --- | --- | --- | --- |
| eg_estado | Char | 1 | NOT NULL | Código del estado de la garantía.<br><br>C= Cancelada<br>P= Propuesta<br>V= Vigente |
| eg_descripcion | descripcion | 64 | NOT NULL | Descripción del estado. |
| eg_codvalor | Int | 4 | NOT NULL | Código valor asociado al estado. |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
