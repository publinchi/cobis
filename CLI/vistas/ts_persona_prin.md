# ts_persona_prin

## Descripción
Vista de servicio para consulta de información principal de personas naturales.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| en_ente | Int | 4 | NOT NULL | Código único del ente | |
| en_ced_ruc | numero | 30 | NOT NULL | Número de cédula | |
| en_nombre_completo | descripcion | 254 | NULL | Nombre completo concatenado | |
| en_sexo | Char | 1 | NULL | Sexo | M=Masculino<br>F=Femenino |
| en_fecha_nac | Datetime | 8 | NULL | Fecha de nacimiento | |
| en_edad | Int | 4 | NULL | Edad calculada | |
| en_estado_civil | catalogo | 10 | NULL | Estado civil | |
| en_email | email | 64 | NULL | Correo electrónico | |
| en_estado | estado | 1 | NULL | Estado del ente | V=Vigente<br>C=Cancelado<br>E=Eliminado |

## Relaciones
- Vista basada en cl_ente donde en_subtipo = 'P'

## Notas
Esta vista proporciona información resumida y principal de personas naturales.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
