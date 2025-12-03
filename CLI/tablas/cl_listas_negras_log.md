# cl_listas_negras_log

## Descripción
Registra el log de consultas realizadas contra listas negras y restrictivas.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ll_secuencial | Int | 4 | NOT NULL | Secuencial del log | |
| ll_ente | Int | 4 | NOT NULL | Código del ente consultado | |
| ll_tipo_lista | catalogo | 10 | NOT NULL | Tipo de lista consultada | OFAC=OFAC<br>ONU=ONU<br>NAR=Narcotráfico<br>TER=Terrorismo<br>OTR=Otros |
| ll_fecha_consulta | Datetime | 8 | NOT NULL | Fecha y hora de la consulta | |
| ll_resultado | Char | 1 | NOT NULL | Resultado de la consulta | L=Limpio<br>C=Coincidencia<br>E=Error |
| ll_detalle | descripcion | 254 | NULL | Detalle del resultado | |
| ll_porcentaje_match | Decimal | 5,2 | NULL | Porcentaje de coincidencia | |
| ll_usuario | login | 14 | NOT NULL | Usuario que realizó la consulta | |
| ll_terminal | descripcion | 64 | NULL | Terminal desde donde se consultó | |
| ll_transaccion | Int | 4 | NULL | Código de transacción asociada | |
| ll_tiempo_respuesta | Int | 4 | NULL | Tiempo de respuesta en milisegundos | |

## Relaciones
- Relacionada con cl_ente a través de ll_ente

## Notas
Esta tabla mantiene un registro completo de todas las consultas a listas restrictivas para auditoría.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
