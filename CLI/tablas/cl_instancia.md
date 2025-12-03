# cl_instancia

## Descripción
Contiene las instancias de relaciones entre dos entes. Representa la materialización de una relación definida en cl_relacion.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| in_relacion | Int | 4 | NOT NULL | Código de la relación | |
| in_ente_i | Int | 4 | NOT NULL | Código del ente izquierdo de la relación | |
| in_ente_d | Int | 4 | NOT NULL | Código del ente derecho de la relación | |
| in_fecha_inicio | Datetime | 8 | NOT NULL | Fecha de inicio de la relación | |
| in_fecha_fin | Datetime | 8 | NULL | Fecha de fin de la relación | |
| in_estado | estado | 1 | NOT NULL | Estado de la relación | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| in_usuario | login | 14 | NULL | Usuario que creó la relación | |
| in_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| in_terminal | descripcion | 64 | NULL | Terminal desde donde se registró | |
| in_observacion | descripcion | 254 | NULL | Observaciones sobre la relación | |

## Relaciones
- Relacionada con cl_relacion a través de in_relacion
- Relacionada con cl_ente a través de in_ente_i y in_ente_d
- Relacionada con cl_at_instancia para los atributos de la relación

## Notas
Esta tabla almacena las relaciones activas entre entes. Por ejemplo: cónyuge, representante legal, accionista, etc.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
