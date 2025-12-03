# ca_log_fecha_valor_grupal

## Descripción

Tabla que registra el log de validaciones de fecha valor para préstamos grupales. Mantiene un historial de las validaciones realizadas.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| lfvg_secuencial | int | 4 | NOT NULL | Secuencial del log |
| lfvg_fecha | datetime | 8 | NOT NULL | Fecha del registro |
| lfvg_operacion | int | 4 | NOT NULL | Número de operación |
| lfvg_tipo_operacion | char | 1 | NOT NULL | Tipo de operación<br><br>P = Padre<br><br>H = Hija |
| lfvg_fecha_valor | datetime | 8 | NOT NULL | Fecha valor validada |
| lfvg_monto | money | 8 | NOT NULL | Monto de la transacción |
| lfvg_resultado_validacion | char | 1 | NOT NULL | Resultado de la validación<br><br>A = Aprobada<br><br>R = Rechazada |
| lfvg_motivo_rechazo | varchar | 255 | NULL | Motivo del rechazo (si aplica) |
| lfvg_usuario | login | 14 | NOT NULL | Usuario que realizó la operación |
| lfvg_terminal | descripcion | 160 | NOT NULL | Terminal desde donde se realizó |

## Índices

- **ca_log_fecha_valor_grupal_1** (UNIQUE NONCLUSTERED INDEX): lfvg_secuencial
- **ca_log_fecha_valor_grupal_2** (NONCLUSTERED INDEX): lfvg_fecha
- **ca_log_fecha_valor_grupal_3** (NONCLUSTERED INDEX): lfvg_operacion

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
