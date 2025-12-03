# cl_at_relacion

## Descripción
Contiene los atributos de una relación. Se maneja la información de relaciones legales y otras definidas por el usuario.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ar_relacion | Int | 4 | NOT NULL | Código relación | |
| ar_atributo | Tinyint | 1 | NOT NULL | Secuencial del atributo por relación. | |
| ar_descripcion | descripcion | 64 | NOT NULL | Descripción del título que tiene el atributo dentro de la relación | |
| ar_tdato | Varchar | 30 | NOT NULL | Tipo de dato que tendrá el atributo de la relación | |
| ar_catalogo | varchar | 30 | NULL | Nombre del catalogo a relacionar | |
| ar_bdatos | Varchar | 30 | NULL | Nombre de la base de datos a relacionar | |
| ar_sprocedure | Varchar | 50 | NULL | Nombre del Sp a relacionar | |

## Relaciones
- Relacionada con cl_relacion a través de ar_relacion

## Notas
Esta tabla define la estructura de atributos que pueden tener las relaciones entre entes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
