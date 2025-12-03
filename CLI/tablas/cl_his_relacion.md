# cl_his_relacion

## Descripción
Contiene el histórico de las relaciones entre entes que han sido modificadas o eliminadas.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| hr_secuencial | Int | 4 | NOT NULL | Secuencial del histórico | |
| hr_relacion | Int | 4 | NOT NULL | Código de la relación | |
| hr_ente_i | Int | 4 | NOT NULL | Código del ente izquierdo | |
| hr_ente_d | Int | 4 | NOT NULL | Código del ente derecho | |
| hr_fecha_inicio | Datetime | 8 | NOT NULL | Fecha de inicio de la relación | |
| hr_fecha_fin | Datetime | 8 | NULL | Fecha de fin de la relación | |
| hr_estado | estado | 1 | NOT NULL | Estado de la relación histórica | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| hr_usuario | login | 14 | NULL | Usuario que registró el cambio | |
| hr_fecha_registro | Datetime | 8 | NULL | Fecha de registro del histórico | |
| hr_terminal | descripcion | 64 | NULL | Terminal desde donde se registró | |
| hr_motivo | descripcion | 254 | NULL | Motivo del cambio o eliminación | |

## Relaciones
- Relacionada con cl_relacion a través de hr_relacion
- Relacionada con cl_ente a través de hr_ente_i y hr_ente_d
- Relacionada con cl_instancia (tabla actual de relaciones)

## Notas
Esta tabla mantiene un registro histórico de todas las relaciones entre entes, permitiendo auditoría y trazabilidad.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
