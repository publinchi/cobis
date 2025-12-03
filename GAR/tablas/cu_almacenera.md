# cu_almacenera

## Descripción

Almacena los depósitos y almacenes donde se ubica las mercancías o bienes sobre los cuales constituimos la garantía.

## Estructura de la tabla

| **Nombre del campo** | **Tipo de dato** | **LONG** | **Car.de dato** | **Descripción** |
| --- | --- | --- | --- | --- |
| al_almacenera | Smallint | 2 | NOT NULL | Código de la almacenera |
| al_nombre | descripcion | 64 | NULL | Nombre de la almacenera. |
| al_direccion | descripcion | 64 | NULL | Dirección de ubicación. |
| al_telefono | Varchar | 20 | NULL | Teléfono de la dirección. |
| al_estado | Char | 1 | NOT NULL | Estado de la almacenera.<br><br>V = Vigente<br>C= Cerrada |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
