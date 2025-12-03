# ts_persona

## Descripción
Vista de servicio para consulta de información de personas naturales (entes tipo P).

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| en_ente | Int | 4 | NOT NULL | Código único del ente | |
| en_ced_ruc | numero | 30 | NOT NULL | Número de cédula | |
| en_tipo_ced | catalogo | 10 | NULL | Tipo de documento de identificación | |
| en_nombre | descripcion | 64 | NULL | Primer nombre | |
| en_snombre | descripcion | 64 | NULL | Segundo nombre | |
| en_apellido | descripcion | 64 | NULL | Primer apellido | |
| en_sapelido | descripcion | 64 | NULL | Segundo apellido | |
| en_sexo | Char | 1 | NULL | Sexo | M=Masculino<br>F=Femenino |
| en_estado_civil | catalogo | 10 | NULL | Estado civil | |
| en_fecha_nac | Datetime | 8 | NULL | Fecha de nacimiento | |
| en_lugar_nac | Int | 4 | NULL | Lugar de nacimiento | |
| en_nacionalidad | catalogo | 10 | NULL | Nacionalidad | |
| en_profesion | catalogo | 10 | NULL | Profesión | |
| en_nivel_estudio | catalogo | 10 | NULL | Nivel de estudios | |
| en_actividad | catalogo | 10 | NULL | Actividad económica | |
| en_tipo_vivienda | catalogo | 10 | NULL | Tipo de vivienda | |
| en_oficina | Smallint | 2 | NULL | Oficina de registro | |
| en_oficial | Smallint | 2 | NULL | Oficial asignado | |
| en_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| en_estado | estado | 1 | NULL | Estado del ente | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| en_email | email | 64 | NULL | Correo electrónico | |

## Relaciones
- Vista basada en cl_ente donde en_subtipo = 'P'

## Notas
Esta vista filtra únicamente personas naturales para facilitar consultas específicas.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
