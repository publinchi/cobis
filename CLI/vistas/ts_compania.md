# ts_compania

## Descripción
Vista de servicio para consulta de información de compañías o personas jurídicas (entes tipo C).

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| en_ente | Int | 4 | NOT NULL | Código único del ente | |
| en_ced_ruc | numero | 30 | NOT NULL | Número de RUC | |
| en_tipo_ced | catalogo | 10 | NULL | Tipo de documento de identificación | |
| en_nomlar | descripcion | 254 | NULL | Nombre largo de la compañía | |
| en_actividad | catalogo | 10 | NULL | Actividad económica | |
| en_oficina | Smallint | 2 | NULL | Oficina de registro | |
| en_oficial | Smallint | 2 | NULL | Oficial asignado | |
| en_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| en_estado | estado | 1 | NULL | Estado del ente | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| en_email | email | 64 | NULL | Correo electrónico | |
| en_retencion | Char | 1 | NULL | Sujeto a retención | S=Sí<br>N=No |

## Relaciones
- Vista basada en cl_ente donde en_subtipo = 'C'

## Notas
Esta vista filtra únicamente compañías o personas jurídicas para facilitar consultas específicas.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
