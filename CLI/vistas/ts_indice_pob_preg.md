# ts_indice_pob_preg

## Descripción
Vista de servicio para consulta de preguntas del índice de pobreza (PPI).

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ip_codigo | Int | 4 | NOT NULL | Código de la pregunta | |
| ip_pregunta | descripcion | 254 | NOT NULL | Texto de la pregunta | |
| ip_orden | Smallint | 2 | NOT NULL | Orden de la pregunta | |
| ip_tipo_respuesta | Char | 1 | NOT NULL | Tipo de respuesta | U=Única<br>M=Múltiple<br>N=Numérica |
| ip_categoria | catalogo | 10 | NULL | Categoría de la pregunta | VIV=Vivienda<br>EDU=Educación<br>SAL=Salud<br>ING=Ingresos<br>OTR=Otros |
| ip_activa | Char | 1 | NOT NULL | Indica si está activa | S=Sí<br>N=No |
| ip_estado | estado | 1 | NULL | Estado de la pregunta | V=Vigente<br>C=Cancelado |

## Relaciones
- Vista basada en cl_indice_pob_preg

## Notas
Esta vista facilita la consulta de preguntas del índice de pobreza.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
