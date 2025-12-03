# cl_indice_pob_respuesta

## Descripción
Contiene las respuestas posibles para cada pregunta del índice de pobreza (PPI).

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ir_codigo | Int | 4 | NOT NULL | Código de la respuesta | |
| ir_pregunta | Int | 4 | NOT NULL | Código de la pregunta | |
| ir_respuesta | descripcion | 254 | NOT NULL | Texto de la respuesta | |
| ir_puntaje | Decimal | 5,2 | NOT NULL | Puntaje asignado a la respuesta | |
| ir_orden | Smallint | 2 | NOT NULL | Orden de la respuesta | |
| ir_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| ir_usuario | login | 14 | NULL | Usuario que registró | |
| ir_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ir_estado | estado | 1 | NULL | Estado de la respuesta | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_indice_pob_preg a través de ir_pregunta

## Notas
Esta tabla define las opciones de respuesta y sus puntajes para el cálculo del índice de pobreza.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
