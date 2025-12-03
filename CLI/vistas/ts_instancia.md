# ts_instancia

## Descripción
Vista de servicio para consulta de instancias de relaciones entre entes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| in_relacion | Int | 4 | NOT NULL | Código de la relación | |
| in_ente_i | Int | 4 | NOT NULL | Código del ente izquierdo | |
| in_ente_d | Int | 4 | NOT NULL | Código del ente derecho | |
| in_fecha_inicio | Datetime | 8 | NOT NULL | Fecha de inicio de la relación | |
| in_fecha_fin | Datetime | 8 | NULL | Fecha de fin de la relación | |
| in_estado | estado | 1 | NOT NULL | Estado de la relación | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| descripcion_relacion | descripcion | 64 | NULL | Descripción de la relación | |
| nombre_ente_i | descripcion | 254 | NULL | Nombre del ente izquierdo | |
| nombre_ente_d | descripcion | 254 | NULL | Nombre del ente derecho | |

## Relaciones
- Vista basada en cl_instancia con joins a cl_relacion y cl_ente

## Notas
Esta vista facilita la consulta de relaciones activas entre entes con información completa.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
