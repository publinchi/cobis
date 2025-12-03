# cl_grupo

## Descripción
Contiene la información de los grupos económicos o solidarios creados en el sistema.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| gr_grupo | Int | 4 | NOT NULL | Código del grupo | |
| gr_nombre | descripcion | 64 | NOT NULL | Nombre del grupo | |
| gr_tipo | catalogo | 10 | NULL | Tipo de grupo | E=Económico<br>S=Solidario |
| gr_oficial | Smallint | 2 | NULL | Oficial asignado al grupo | |
| gr_oficina | Smallint | 2 | NULL | Oficina del grupo | |
| gr_fecha_crea | Datetime | 8 | NOT NULL | Fecha de creación | |
| gr_fecha_mod | Datetime | 8 | NULL | Fecha de modificación | |
| gr_usuario | login | 14 | NULL | Usuario que creó el grupo | |
| gr_terminal | descripcion | 64 | NULL | Terminal de creación | |
| gr_estado | estado | 1 | NULL | Estado del grupo | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| gr_descripcion | descripcion | 254 | NULL | Descripción del grupo | |
| gr_num_miembros | Int | 4 | NULL | Número de miembros del grupo | |
| gr_monto_max | money | 8 | NULL | Monto máximo de crédito grupal | |
| gr_ciclo | Int | 4 | NULL | Número de ciclo actual del grupo | |
| gr_fecha_reunion | Datetime | 8 | NULL | Fecha de reunión del grupo | |
| gr_lugar_reunion | descripcion | 254 | NULL | Lugar de reunión | |
| gr_periodicidad | catalogo | 10 | NULL | Periodicidad de reuniones | S=Semanal<br>Q=Quincenal<br>M=Mensual |

## Relaciones
- Relacionada con cl_oficina a través de gr_oficina
- Relacionada con cc_funcionario a través de gr_oficial
- Relacionada con cl_cliente_grupo para los miembros del grupo

## Notas
Esta tabla gestiona grupos económicos o solidarios, especialmente útil para microfinanzas y créditos grupales.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
