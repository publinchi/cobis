# cl_notificacion_general

## Descripción
Almacena notificaciones generales enviadas a los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ng_secuencial | Int | 4 | NOT NULL | Secuencial de la notificación | |
| ng_ente | Int | 4 | NOT NULL | Código del ente destinatario | |
| ng_tipo | catalogo | 10 | NOT NULL | Tipo de notificación | EM=Email<br>SM=SMS<br>CA=Carta<br>LL=Llamada<br>OT=Otros |
| ng_asunto | descripcion | 254 | NULL | Asunto de la notificación | |
| ng_mensaje | Text | - | NULL | Contenido del mensaje | |
| ng_fecha_envio | Datetime | 8 | NOT NULL | Fecha de envío | |
| ng_fecha_lectura | Datetime | 8 | NULL | Fecha de lectura | |
| ng_estado | estado | 1 | NOT NULL | Estado de la notificación | P=Pendiente<br>E=Enviada<br>L=Leída<br>F=Fallida |
| ng_prioridad | catalogo | 10 | NULL | Prioridad | A=Alta<br>M=Media<br>B=Baja |
| ng_destinatario | Varchar | 254 | NULL | Dirección del destinatario (email, teléfono, etc.) | |
| ng_usuario | login | 14 | NULL | Usuario que generó la notificación | |
| ng_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ng_observacion | descripcion | 254 | NULL | Observaciones | |
| ng_intentos_envio | Tinyint | 1 | NULL | Número de intentos de envío | |

## Relaciones
- Relacionada con cl_ente a través de ng_ente

## Notas
Esta tabla gestiona todas las notificaciones enviadas a los clientes por diferentes canales.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
