# cl_subsector_ec

## Descripción
Contiene el catálogo de subsectores económicos, que son subdivisiones de los sectores económicos.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ss_codigo | catalogo | 10 | NOT NULL | Código del subsector | |
| ss_descripcion | descripcion | 254 | NOT NULL | Descripción del subsector | |
| ss_sector | catalogo | 10 | NOT NULL | Código del sector al que pertenece | |
| ss_estado | estado | 1 | NULL | Estado del subsector | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| ss_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| ss_usuario | login | 14 | NULL | Usuario que creó | |
| ss_terminal | descripcion | 64 | NULL | Terminal de creación | |
| ss_nivel_riesgo | catalogo | 10 | NULL | Nivel de riesgo del subsector | A=Alto<br>M=Medio<br>B=Bajo |

## Relaciones
- Relacionada con cl_sector_economico a través de ss_sector
- Relacionada con cl_actividad_ec para las actividades del subsector

## Notas
Esta tabla permite una clasificación más detallada de las actividades económicas.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
