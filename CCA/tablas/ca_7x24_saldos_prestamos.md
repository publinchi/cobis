# ca_7x24_saldos_prestamos

## Descripción

Tabla que almacena los saldos de préstamos para el servicio 7x24. Permite consultas de saldos en tiempo real sin afectar el sistema transaccional.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| sp_operacion | int | 4 | NOT NULL | Número de operación |
| sp_fecha_saldos | datetime | 8 | NOT NULL | Fecha de los saldos |
| sp_banco | cuenta | 24 | NOT NULL | Número banco del préstamo |
| sp_cliente | int | 4 | NOT NULL | Código del cliente |
| sp_estado | tinyint | 1 | NOT NULL | Estado de la operación |
| sp_saldo_capital | money | 8 | NOT NULL | Saldo de capital |
| sp_saldo_interes | money | 8 | NOT NULL | Saldo de interés |
| sp_saldo_mora | money | 8 | NOT NULL | Saldo de mora |
| sp_saldo_otros | money | 8 | NOT NULL | Saldo de otros conceptos |
| sp_saldo_total | money | 8 | NOT NULL | Saldo total |
| sp_cuota_proxima | money | 8 | NOT NULL | Monto de la próxima cuota |
| sp_fecha_proximo_vencimiento | datetime | 8 | NULL | Fecha del próximo vencimiento |
| sp_dias_mora | smallint | 2 | NOT NULL | Días de mora |
| sp_fecha_actualizacion | datetime | 8 | NOT NULL | Fecha de actualización del registro |

## Índices

- **ca_7x24_saldos_prestamos_1** (UNIQUE NONCLUSTERED INDEX): sp_operacion, sp_fecha_saldos
- **ca_7x24_saldos_prestamos_2** (NONCLUSTERED INDEX): sp_banco
- **ca_7x24_saldos_prestamos_3** (NONCLUSTERED INDEX): sp_cliente
- **ca_7x24_saldos_prestamos_4** (NONCLUSTERED INDEX): sp_fecha_saldos

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
