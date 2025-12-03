# ca_transaccion

## Descripción

Tabla que almacena la cabecera de todas las transacciones realizadas en el módulo de cartera. Registra información general de cada movimiento.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tr_secuencial | int | 4 | NOT NULL | Secuencial único de la transacción |
| tr_fecha_mov | datetime | 8 | NOT NULL | Fecha del movimiento |
| tr_tran | smallint | 2 | NOT NULL | Código de la transacción |
| tr_secuencial_ref | int | 4 | NULL | Secuencial de referencia |
| tr_estado | char | 1 | NOT NULL | Estado de la transacción<br><br>CON = Confirmada<br><br>ING = Ingresada<br><br>RV = Reversada |
| tr_operacion | int | 4 | NOT NULL | Número de operación |
| tr_fecha_ref | datetime | 8 | NULL | Fecha de referencia |
| tr_observacion | varchar | 255 | NULL | Observaciones de la transacción |
| tr_usuario | login | 14 | NOT NULL | Usuario que realizó la transacción |
| tr_terminal | descripcion | 160 | NOT NULL | Terminal desde donde se realizó |
| tr_oficina | smallint | 2 | NOT NULL | Oficina donde se realizó la transacción |
| tr_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| tr_comprobante | int | 4 | NULL | Número de comprobante contable |

## Índices

- **ca_transaccion_1** (UNIQUE NONCLUSTERED INDEX): tr_secuencial
- **ca_transaccion_2** (NONCLUSTERED INDEX): tr_operacion
- **ca_transaccion_3** (NONCLUSTERED INDEX): tr_fecha_mov
- **ca_transaccion_4** (NONCLUSTERED INDEX): tr_estado
- **ca_transaccion_5** (NONCLUSTERED INDEX): tr_secuencial_ref

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
