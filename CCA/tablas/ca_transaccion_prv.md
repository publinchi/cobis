# ca_transaccion_prv

## Descripción

Tabla que almacena las transacciones relacionadas con provisiones de cartera. Registra los movimientos de constitución y liberación de provisiones.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tp_secuencial | int | 4 | NOT NULL | Secuencial de la transacción de provisión |
| tp_fecha_proceso | datetime | 8 | NOT NULL | Fecha del proceso de provisión |
| tp_operacion | int | 4 | NOT NULL | Número de operación |
| tp_tipo_movimiento | char | 1 | NOT NULL | Tipo de movimiento<br><br>C = Constitución<br><br>L = Liberación<br><br>A = Ajuste |
| tp_monto | money | 8 | NOT NULL | Monto de la provisión |
| tp_calificacion | char | 1 | NOT NULL | Calificación de la operación |
| tp_dias_mora | smallint | 2 | NOT NULL | Días de mora |
| tp_estado | char | 1 | NOT NULL | Estado de la transacción<br><br>V = Vigente<br><br>R = Reversada |
| tp_usuario | login | 14 | NOT NULL | Usuario que realizó la transacción |
| tp_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| tp_comprobante | int | 4 | NULL | Número de comprobante contable |

## Índices

- **ca_transaccion_prv_1** (UNIQUE NONCLUSTERED INDEX): tp_secuencial
- **ca_transaccion_prv_2** (NONCLUSTERED INDEX): tp_operacion
- **ca_transaccion_prv_3** (NONCLUSTERED INDEX): tp_fecha_proceso

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
