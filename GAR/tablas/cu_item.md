# cu_item

## Descripción

Registra los atributos específicos asociados a un tipo de garantía

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| it_tipo_custodia | Varchar | 64 | NOT NULL | Tipo de custodia |
| it_item | Tinyint | 1 | NOT NULL | Código ítem de la custodia |
| it_nombre | Varchar | 64 | NULL | Nombre del ítem |
| it_detalle | Varchar | 64 | NULL | Descripción del ítem |
| it_tipo_dato | Char | 1 | NOT NULL | Tipo de dato del ítem<br><br>I= Integer<br>F= Float<br>C= Char |
| it_mandatorio | Char | 1 | NULL | Indica si es mandatorio |
| It_factura | Char | 1 | NOT NULL | Campo en desuso en esta versión. |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
