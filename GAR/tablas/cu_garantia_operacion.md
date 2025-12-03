# cu_garantia_operacion

## Descripción

Registra la relación entre garantía y la operación de cartera.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **DESCRIPCION** |
| --- | --- | --- | --- | --- |
| go_filial | Tinyint | 1 | NOT NULL | Código de la filial. |
| go_sucursal | Smallint | 2 | NOT NULL | Código de la sucursal. |
| go_tipo_cust | descripcion | 64 | NOT NULL | Tipo de custodia. |
| go_custodia | Int | 4 | NOT NULL | Código numérico de la custodia. |
| go_operacion | cuenta | 24 | NULL | Código de la operación. |
| go_operacion_cartera | Int | 4 | NULL | Código de la operación en el modulo de cartera. |
| go_operacion_cobis | cuenta | 24 | NOT NULL | Código de la operación Cobis o el código en carácter de la operación. |
| go_fecha | Datetime | 8 | NULL | Fecha de la operación |
| go_codigo_externo | descripcion | 64 | NOT NULL | Código compuesto de la garantía |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
