# cl_narcos

## Descripción
Contiene información de personas o entidades relacionadas con listas de narcotráfico y actividades ilícitas.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| na_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| na_nombre | descripcion | 254 | NOT NULL | Nombre completo | |
| na_identificacion | numero | 30 | NULL | Número de identificación | |
| na_tipo_identificacion | catalogo | 10 | NULL | Tipo de documento | |
| na_nacionalidad | catalogo | 10 | NULL | Nacionalidad | |
| na_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| na_usuario | login | 14 | NULL | Usuario que registró | |
| na_terminal | descripcion | 64 | NULL | Terminal de registro | |
| na_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |
| na_fuente | descripcion | 64 | NULL | Fuente de información | |
| na_observacion | descripcion | 254 | NULL | Observaciones | |
| na_fecha_actualizacion | Datetime | 8 | NULL | Fecha de última actualización | |

## Relaciones
No tiene relaciones directas con otras tablas

## Notas
Esta tabla es crítica para el cumplimiento de normativas de prevención de lavado de activos y financiamiento del terrorismo.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
