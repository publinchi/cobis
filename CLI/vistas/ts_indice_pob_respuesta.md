# ts_indice_pob_respuesta

## Descripción
Vista de servicio para consulta de respuestas del índice de pobreza (PPI).

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ir_codigo | Int | 4 | NOT NULL | Código de la respuesta | |
| ir_pregunta | Int | 4 | NOT NULL | Código de la pregunta | |
| ir_respuesta | descripcion | 254 | NOT NULL | Texto de la respuesta | |
| ir_puntaje | Decimal | 5,2 | NOT NULL | Puntaje asignado a la respuesta | |
| ir_orden | Smallint | 2 | NOT NULL | Orden de la respuesta | |
| ir_estado | estado | 1 | NULL | Estado de la respuesta | V=Vigente<br>C=Cancelado |
| texto_pregunta | descripcion | 254 | NULL | Texto de la pregunta | |

## Relaciones
- Vista basada en cl_indice_pob_respuesta con join a cl_indice_pob_preg

## Notas
Esta vista facilita la consulta de respuestas con sus preguntas asociadas.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
