# ca_registra_traslados_masivos

## Descripción

Tabla que registra los traslados masivos de cartera. Permite llevar el control de movimientos de cartera entre oficiales, oficinas o carteras.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| rtm_secuencial | int | 4 | NOT NULL | Secuencial del traslado masivo |
| rtm_fecha_proceso | datetime | 8 | NOT NULL | Fecha del proceso de traslado |
| rtm_tipo_traslado | char | 1 | NOT NULL | Tipo de traslado<br><br>O = Oficial<br><br>F = Oficina<br><br>C = Cartera |
| rtm_origen | varchar | 50 | NOT NULL | Código de origen del traslado |
| rtm_destino | varchar | 50 | NOT NULL | Código de destino del traslado |
| rtm_cantidad_operaciones | int | 4 | NOT NULL | Cantidad de operaciones trasladadas |
| rtm_monto_total | money | 8 | NOT NULL | Monto total trasladado |
| rtm_estado | char | 1 | NOT NULL | Estado del traslado<br><br>P = Procesado<br><br>R = Reversado |
| rtm_usuario | login | 14 | NOT NULL | Usuario que realizó el traslado |
| rtm_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| rtm_observacion | varchar | 255 | NULL | Observaciones del traslado |

## Índices

- **ca_registra_traslados_masivos_1** (UNIQUE NONCLUSTERED INDEX): rtm_secuencial
- **ca_registra_traslados_masivos_2** (NONCLUSTERED INDEX): rtm_fecha_proceso

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
