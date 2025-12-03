# cl_actividad_principal

## Descripción
Contiene el catálogo de actividades económicas principales clasificadas por sector.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ap_codigo | catalogo | 10 | NOT NULL | Código de la actividad principal | |
| ap_descripcion | descripcion | 254 | NOT NULL | Descripción de la actividad | |
| ap_sector | catalogo | 10 | NULL | Código del sector económico | |
| ap_estado | estado | 1 | NULL | Estado de la actividad | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| ap_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| ap_usuario | login | 14 | NULL | Usuario que creó | |
| ap_terminal | descripcion | 64 | NULL | Terminal de creación | |
| ap_nivel_riesgo | catalogo | 10 | NULL | Nivel de riesgo asociado | A=Alto<br>M=Medio<br>B=Bajo |

## Relaciones
- Relacionada con cl_sector_economico a través de ap_sector

## Notas
Esta tabla clasifica las actividades económicas principales para categorización de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
