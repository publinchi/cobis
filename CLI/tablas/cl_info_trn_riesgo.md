# cl_info_trn_riesgo

## Descripción
Almacena información de transacciones relacionadas con la evaluación de riesgo del cliente.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| itr_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| itr_ente | Int | 4 | NOT NULL | Código del ente | |
| itr_tipo_transaccion | catalogo | 10 | NOT NULL | Tipo de transacción | |
| itr_fecha_transaccion | Datetime | 8 | NOT NULL | Fecha de la transacción | |
| itr_monto | money | 8 | NULL | Monto de la transacción | |
| itr_moneda | Tinyint | 1 | NULL | Código de moneda | |
| itr_origen | descripcion | 64 | NULL | Origen de la transacción | |
| itr_destino | descripcion | 64 | NULL | Destino de la transacción | |
| itr_nivel_riesgo | catalogo | 10 | NULL | Nivel de riesgo detectado | A=Alto<br>M=Medio<br>B=Bajo |
| itr_alerta_generada | Char | 1 | NULL | Indica si generó alerta | S=Sí<br>N=No |
| itr_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |
| itr_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| itr_usuario | login | 14 | NULL | Usuario que registró | |
| itr_terminal | descripcion | 64 | NULL | Terminal de registro | |
| itr_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de itr_ente

## Notas
Esta tabla registra transacciones relevantes para el análisis de riesgo del cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
