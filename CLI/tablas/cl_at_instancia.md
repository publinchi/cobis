# cl_at_instancia

## Descripción
Contiene el valor de los atributos de la instancia de una relación entre dos entes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ai_relacion | Int | 4 | NOT NULL | Código identificador de la relación. | |
| ai_ente_i | Int | 4 | NOT NULL | Código secuencial del ente asignado al lado izquierdo de la relación. | |
| ai_ente_d | Int | 4 | NOT NULL | Código secuencial del ente asignado al lado derecho de la relación. | |
| ai_atributo | Tinyint | 1 | NOT NULL | Código identificador del atributo. | |
| ai_valor | Varchar | 255 | NOT NULL | Valor del atributo. | |
| ai_secuencial | Int | 4 | NULL | Secuencial | |

## Relaciones
- Relacionada con cl_relacion a través de ai_relacion
- Relacionada con cl_ente a través de ai_ente_i y ai_ente_d
- Relacionada con cl_at_relacion a través de ai_relacion y ai_atributo

## Notas
Esta tabla almacena los valores específicos de los atributos definidos para cada instancia de relación entre entes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
