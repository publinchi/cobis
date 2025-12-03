# cl_subactividad_ec

## Descripción
Contiene el catálogo de subactividades económicas, que son subdivisiones más específicas de las actividades económicas.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| sa_codigo | catalogo | 10 | NOT NULL | Código de la subactividad | |
| sa_descripcion | descripcion | 254 | NOT NULL | Descripción de la subactividad | |
| sa_actividad | catalogo | 10 | NOT NULL | Código de la actividad a la que pertenece | |
| sa_estado | estado | 1 | NULL | Estado de la subactividad | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| sa_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| sa_usuario | login | 14 | NULL | Usuario que creó | |
| sa_terminal | descripcion | 64 | NULL | Terminal de creación | |
| sa_nivel_riesgo | catalogo | 10 | NULL | Nivel de riesgo | A=Alto<br>M=Medio<br>B=Bajo |

## Relaciones
- Relacionada con cl_actividad_ec a través de sa_actividad

## Notas
Esta tabla proporciona el nivel más detallado de clasificación de actividades económicas.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
