# cl_ns_generales_estado

## Descripción
Almacena estados de notificaciones generales

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ne_secuencial | Int | 4 | NOT NULL | Secuencial del estado | |
| ne_notificacion | Int | 4 | NOT NULL | Código de la notificación | |
| ne_estado | estado | 1 | NOT NULL | Estado | P=Pendiente<br>E=Enviada<br>L=Leída<br>F=Fallida |
| ne_fecha_cambio | Datetime | 8 | NOT NULL | Fecha del cambio de estado | |
| ne_observacion | descripcion | 254 | NULL | Observaciones | |
| ne_usuario | login | 14 | NULL | Usuario que cambió el estado | |
| ne_terminal | descripcion | 64 | NULL | Terminal de registro | |

## Relaciones
- Relacionada con cl_notificacion_general a través de ne_notificacion

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
