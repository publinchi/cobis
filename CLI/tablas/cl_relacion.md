# cl_relacion

## Descripción
Contiene la definición de los tipos de relaciones que pueden existir entre entes en el sistema.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| rl_relacion | Int | 4 | NOT NULL | Código de la relación | |
| rl_descripcion | descripcion | 64 | NOT NULL | Descripción de la relación | |
| rl_nemotecnico | Char | 10 | NULL | Código nemotécnico | |
| rl_tipo_i | Char | 1 | NOT NULL | Tipo de ente izquierdo | P=Persona<br>C=Compañía |
| rl_tipo_d | Char | 1 | NOT NULL | Tipo de ente derecho | P=Persona<br>C=Compañía |
| rl_estado | estado | 1 | NULL | Estado de la relación | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| rl_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| rl_usuario | login | 14 | NULL | Usuario que creó | |
| rl_terminal | descripcion | 64 | NULL | Terminal de creación | |
| rl_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_instancia para las instancias de esta relación
- Relacionada con cl_at_relacion para los atributos de la relación

## Notas
Esta tabla define los tipos de relaciones posibles entre entes (ej: cónyuge, representante legal, accionista, etc.).

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
