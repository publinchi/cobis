# cu_det_trn

## Descripción

Almacena los valores monetarios de cada transaccion.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| dtr_secuencial | Int | 4 | NOT NULL | Código de secuencial de la transacción. |
| dtr_codigo_externo | Varchar | 64 | NOT NULL | Código externo para la garantía. |
| dtr_codvalor | Int | 4 | NOT NULL | Código valor asociado a la transacción. |
| dtr_valor | Float | 8 | NOT NULL | Valor de la transacción. |
| dtr_clase_cartera | catalogo | 10 | NULL | Columna en desuso |
| dtr_calificacion | catalogo | 10 | NULL | Columna en desuso |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
