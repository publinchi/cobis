# ts_persona_sec

## Descripción
Vista de servicio para consulta de información secundaria de personas naturales.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| en_ente | Int | 4 | NOT NULL | Código único del ente | |
| en_profesion | catalogo | 10 | NULL | Profesión | |
| en_nivel_estudio | catalogo | 10 | NULL | Nivel de estudios | |
| en_actividad | catalogo | 10 | NULL | Actividad económica | |
| en_tipo_vivienda | catalogo | 10 | NULL | Tipo de vivienda | |
| en_lugar_nac | Int | 4 | NULL | Lugar de nacimiento | |
| en_nacionalidad | catalogo | 10 | NULL | Nacionalidad | |
| nombre_profesion | descripcion | 64 | NULL | Descripción de la profesión | |
| nombre_actividad | descripcion | 64 | NULL | Descripción de la actividad | |

## Relaciones
- Vista basada en cl_ente donde en_subtipo = 'P' con joins a catálogos

## Notas
Esta vista proporciona información complementaria de personas naturales.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
