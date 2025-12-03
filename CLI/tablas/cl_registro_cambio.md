# cl_registro_cambio

## Descripción
Registra todos los cambios realizados en la información de los clientes para auditoría y trazabilidad.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| rc_secuencial | Int | 4 | NOT NULL | Secuencial del registro de cambio | |
| rc_ente | Int | 4 | NOT NULL | Código del ente | |
| rc_tabla | Varchar | 64 | NOT NULL | Nombre de la tabla modificada | |
| rc_campo | Varchar | 64 | NOT NULL | Campo modificado | |
| rc_valor_anterior | Varchar | 254 | NULL | Valor anterior del campo | |
| rc_valor_nuevo | Varchar | 254 | NULL | Valor nuevo del campo | |
| rc_tipo_operacion | Char | 1 | NOT NULL | Tipo de operación | I=Inserción<br>U=Actualización<br>D=Eliminación |
| rc_fecha_cambio | Datetime | 8 | NOT NULL | Fecha y hora del cambio | |
| rc_usuario | login | 14 | NOT NULL | Usuario que realizó el cambio | |
| rc_terminal | descripcion | 64 | NULL | Terminal desde donde se realizó | |
| rc_transaccion | Int | 4 | NULL | Código de transacción | |
| rc_oficina | Smallint | 2 | NULL | Oficina donde se realizó el cambio | |
| rc_motivo | descripcion | 254 | NULL | Motivo del cambio | |

## Relaciones
- Relacionada con cl_ente a través de rc_ente

## Notas
Esta tabla es fundamental para auditoría, permitiendo rastrear todos los cambios realizados en la información de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
