# cl_sector_economico

## Descripción
Contiene el catálogo de sectores económicos para clasificación de actividades.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| se_codigo | catalogo | 10 | NOT NULL | Código del sector económico | |
| se_descripcion | descripcion | 254 | NOT NULL | Descripción del sector | |
| se_estado | estado | 1 | NULL | Estado del sector | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| se_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| se_usuario | login | 14 | NULL | Usuario que creó | |
| se_terminal | descripcion | 64 | NULL | Terminal de creación | |
| se_nivel_riesgo | catalogo | 10 | NULL | Nivel de riesgo del sector | A=Alto<br>M=Medio<br>B=Bajo |
| se_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_subsector_ec para los subsectores
- Relacionada con cl_actividad_principal para las actividades

## Notas
Esta tabla define los sectores económicos principales para clasificación de clientes y actividades.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
