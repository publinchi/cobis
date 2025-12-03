# ca_incentivos_detalle_operaciones

## Descripción

Tabla que almacena el detalle de operaciones para el cálculo de incentivos a oficiales de crédito. Registra información específica de cada préstamo que participa en el esquema de incentivos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ido_secuencial | int | 4 | NOT NULL | Secuencial del registro |
| ido_periodo | varchar | 6 | NOT NULL | Período de cálculo (YYYYMM) |
| ido_operacion | int | 4 | NOT NULL | Número de operación |
| ido_oficial | smallint | 2 | NOT NULL | Código del oficial |
| ido_oficina | smallint | 2 | NOT NULL | Código de la oficina |
| ido_toperacion | catalogo | 10 | NOT NULL | Tipo de operación |
| ido_monto_desembolsado | money | 8 | NOT NULL | Monto desembolsado |
| ido_fecha_desembolso | datetime | 8 | NOT NULL | Fecha de desembolso |
| ido_saldo_capital | money | 8 | NOT NULL | Saldo de capital |
| ido_dias_mora | smallint | 2 | NOT NULL | Días de mora |
| ido_calificacion | char | 1 | NOT NULL | Calificación de la operación |
| ido_estado | char | 1 | NOT NULL | Estado del registro<br><br>P = Procesado<br><br>A = Anulado |
| ido_fecha_proceso | datetime | 8 | NOT NULL | Fecha de procesamiento |

## Índices

- **ca_incentivos_detalle_operaciones_1** (UNIQUE NONCLUSTERED INDEX): ido_secuencial
- **ca_incentivos_detalle_operaciones_2** (NONCLUSTERED INDEX): ido_periodo, ido_oficial
- **ca_incentivos_detalle_operaciones_3** (NONCLUSTERED INDEX): ido_operacion

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
