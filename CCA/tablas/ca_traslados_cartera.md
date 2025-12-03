# ca_traslados_cartera

## Descripción

Tabla que registra los traslados individuales de operaciones de cartera entre oficiales, oficinas o carteras. Mantiene el historial de movimientos de cada préstamo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tc_secuencial | int | 4 | NOT NULL | Secuencial del traslado |
| tc_operacion | int | 4 | NOT NULL | Número de operación trasladada |
| tc_fecha_traslado | datetime | 8 | NOT NULL | Fecha del traslado |
| tc_tipo_traslado | char | 1 | NOT NULL | Tipo de traslado<br><br>O = Oficial<br><br>F = Oficina<br><br>C = Cartera |
| tc_origen | varchar | 50 | NOT NULL | Código de origen |
| tc_destino | varchar | 50 | NOT NULL | Código de destino |
| tc_motivo | varchar | 255 | NULL | Motivo del traslado |
| tc_estado | char | 1 | NOT NULL | Estado del traslado<br><br>P = Procesado<br><br>R = Reversado |
| tc_usuario | login | 14 | NOT NULL | Usuario que realizó el traslado |
| tc_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| tc_secuencial_masivo | int | 4 | NULL | Secuencial del traslado masivo asociado |

## Índices

- **ca_traslados_cartera_1** (UNIQUE NONCLUSTERED INDEX): tc_secuencial
- **ca_traslados_cartera_2** (NONCLUSTERED INDEX): tc_operacion
- **ca_traslados_cartera_3** (NONCLUSTERED INDEX): tc_fecha_traslado
- **ca_traslados_cartera_4** (NONCLUSTERED INDEX): tc_secuencial_masivo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
