# cl_indice_pob_preg

## Descripción
Contiene las preguntas del índice de pobreza (PPI - Progress out of Poverty Index) para evaluación socioeconómica.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ip_codigo | Int | 4 | NOT NULL | Código de la pregunta | |
| ip_pregunta | descripcion | 254 | NOT NULL | Texto de la pregunta | |
| ip_orden | Smallint | 2 | NOT NULL | Orden de la pregunta | |
| ip_tipo_respuesta | Char | 1 | NOT NULL | Tipo de respuesta | U=Única<br>M=Múltiple<br>N=Numérica |
| ip_categoria | catalogo | 10 | NULL | Categoría de la pregunta | VIV=Vivienda<br>EDU=Educación<br>SAL=Salud<br>ING=Ingresos<br>OTR=Otros |
| ip_activa | Char | 1 | NOT NULL | Indica si está activa | S=Sí<br>N=No |
| ip_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| ip_usuario | login | 14 | NULL | Usuario que registró | |
| ip_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ip_estado | estado | 1 | NULL | Estado de la pregunta | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_indice_pob_respuesta para las respuestas posibles

## Notas
Esta tabla define las preguntas del índice de pobreza utilizado para evaluación socioeconómica de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
