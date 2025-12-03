# ts_grupo

## Descripción
Vista de servicio para consulta de información de grupos económicos o solidarios.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| gr_grupo | Int | 4 | NOT NULL | Código del grupo | |
| gr_nombre | descripcion | 64 | NOT NULL | Nombre del grupo | |
| gr_tipo | catalogo | 10 | NULL | Tipo de grupo | E=Económico<br>S=Solidario |
| gr_oficial | Smallint | 2 | NULL | Oficial asignado al grupo | |
| gr_oficina | Smallint | 2 | NULL | Oficina del grupo | |
| gr_fecha_crea | Datetime | 8 | NOT NULL | Fecha de creación | |
| gr_estado | estado | 1 | NULL | Estado del grupo | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| gr_descripcion | descripcion | 254 | NULL | Descripción del grupo | |
| gr_num_miembros | Int | 4 | NULL | Número de miembros del grupo | |
| gr_monto_max | money | 8 | NULL | Monto máximo de crédito grupal | |
| gr_ciclo | Int | 4 | NULL | Número de ciclo actual del grupo | |
| nombre_oficial | descripcion | 64 | NULL | Nombre del oficial | |
| nombre_oficina | descripcion | 64 | NULL | Nombre de la oficina | |

## Relaciones
- Vista basada en cl_grupo con joins a tablas de administración

## Notas
Esta vista facilita la consulta de grupos con información completa de oficiales y oficinas.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
