# cl_registro_identificacion

## Descripción
Registra el historial de identificaciones de los clientes, permitiendo trazabilidad de cambios.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ri_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| ri_ente | Int | 4 | NOT NULL | Código del ente | |
| ri_tipo_identificacion | catalogo | 10 | NOT NULL | Tipo de identificación | |
| ri_numero | numero | 30 | NOT NULL | Número de identificación | |
| ri_fecha_emision | Datetime | 8 | NULL | Fecha de emisión | |
| ri_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |
| ri_lugar_emision | Int | 4 | NULL | Lugar de emisión | |
| ri_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| ri_usuario | login | 14 | NULL | Usuario que registró | |
| ri_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ri_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado<br>H=Histórico |
| ri_motivo_cambio | descripcion | 254 | NULL | Motivo del cambio si aplica | |
| ri_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de ri_ente
- Relacionada con cl_tipo_identificacion a través de ri_tipo_identificacion

## Notas
Esta tabla mantiene un historial completo de todas las identificaciones del cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
