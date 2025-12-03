# cl_actividad_ec

## Descripción
Guarda información de actividades económicas

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ac_codigo | catalogo | 10 | NOT NULL | Código de la actividad | |
| ac_descripcion | varchar | 200 | NULL | Descripción de la actividad | |
| ac_sensitiva | Char | 1 | NULL | No se usa en esta versión | |
| ac_industria | catalogo | 10 | NULL | Tipo de industria. | |
| ac_estado | estado | 1 | NULL | Estado de la actividad | V= Vigente C= Cancelado E= Eliminado |
| ac_codSubsector | catalogo | 10 | NULL | Cod. Del subsector | |
| ac_homolog_pn | catalogo | 10 | NULL | No se usa en esta versión | |
| ac_homolog_pj | catalogo | 10 | NULL | No se usa en esta versión | |

## Relaciones
- Relacionada con cl_subsector_ec a través de ac_codSubsector

## Notas
Esta tabla almacena el catálogo de actividades económicas disponibles en el sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
