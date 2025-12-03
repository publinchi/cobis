# ts_relacion

## Descripción
Vista de servicio para consulta de tipos de relaciones entre entes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| rl_relacion | Int | 4 | NOT NULL | Código de la relación | |
| rl_descripcion | descripcion | 64 | NOT NULL | Descripción de la relación | |
| rl_nemotecnico | Char | 10 | NULL | Código nemotécnico | |
| rl_tipo_i | Char | 1 | NOT NULL | Tipo de ente izquierdo | P=Persona<br>C=Compañía |
| rl_tipo_d | Char | 1 | NOT NULL | Tipo de ente derecho | P=Persona<br>C=Compañía |
| rl_estado | estado | 1 | NULL | Estado de la relación | V=Vigente<br>C=Cancelado<br>E=Eliminado |

## Relaciones
- Vista basada en cl_relacion

## Notas
Esta vista facilita la consulta de tipos de relaciones disponibles en el sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
