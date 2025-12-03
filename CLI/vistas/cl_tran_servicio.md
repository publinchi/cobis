# cl_tran_servicio

## Descripción
Tabla de transacciones de servicio que registra todas las operaciones realizadas en el módulo de clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ts_secuencial | Int | 4 | NOT NULL | Secuencial de la transacción | |
| ts_tipo_transaccion | Char | 1 | NOT NULL | Tipo de transacción | I=Inserción<br>U=Actualización<br>D=Eliminación<br>C=Consulta |
| ts_clase | Char | 1 | NOT NULL | Clase de transacción | N=Normal<br>R=Reverso |
| ts_fecha | Datetime | 8 | NOT NULL | Fecha de la transacción | |
| ts_usuario | login | 14 | NOT NULL | Usuario que ejecutó la transacción | |
| ts_terminal | descripcion | 64 | NOT NULL | Terminal desde donde se ejecutó | |
| ts_srv | descripcion | 64 | NULL | Nombre del servidor | |
| ts_lsrv | descripcion | 64 | NULL | Nombre del servidor lógico | |
| ts_ente | Int | 4 | NULL | Código del ente afectado | |
| ts_cod_transaccion | Int | 4 | NOT NULL | Código de la transacción | |
| ts_oficina | Smallint | 2 | NULL | Oficina donde se realizó | |
| ts_datos | Text | - | NULL | Datos de la transacción en formato XML o JSON | |

## Relaciones
- Relacionada con cl_ente a través de ts_ente

## Notas
Esta tabla es fundamental para auditoría y trazabilidad de todas las operaciones del módulo.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
