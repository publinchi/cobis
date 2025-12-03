# cu_item_custodia

## Descripción

Almacena los valores u atributos específicos de una garantía en particular.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ic_filial | Tinyint | 1 | NOT NULL | Código de la filial |
| ic_sucursal | Smallint | 2 | NOT NULL | Código de la sucursal |
| ic_tipo_cust | Varchar | 64 | NOT NULL | Tipo de custodia |
| ic_custodia | Int | 4 | NOT NULL | Código de la custodia |
| ic_item | Tinyint | 1 | NOT NULL | Código del ítem |
| ic_valor_item | Varchar | 64 | NULL | Valor del ítem |
| ic_secuencial | Smallint | 2 | NULL | Código del secuencial |
| ic_codigo_externo | Varchar | 64 | NOT NULL | Código externo para la garantía. |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
