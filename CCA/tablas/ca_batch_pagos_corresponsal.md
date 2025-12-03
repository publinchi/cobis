# ca_batch_pagos_corresponsal

## Descripción

Tabla que controla la carga de pagos por archivo desde corresponsales bancarios. Registra el proceso batch de aplicación masiva de pagos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| bpc_lote | int | 4 | NOT NULL | Número de lote |
| bpc_fecha_proceso | datetime | 8 | NOT NULL | Fecha del proceso |
| bpc_corresponsal | catalogo | 10 | NOT NULL | Código del corresponsal |
| bpc_archivo | varchar | 255 | NOT NULL | Nombre del archivo cargado |
| bpc_total_registros | int | 4 | NOT NULL | Total de registros en el archivo |
| bpc_registros_procesados | int | 4 | NOT NULL | Registros procesados exitosamente |
| bpc_registros_error | int | 4 | NOT NULL | Registros con error |
| bpc_monto_total | money | 8 | NOT NULL | Monto total del lote |
| bpc_estado | char | 1 | NOT NULL | Estado del proceso<br><br>P = En proceso<br><br>C = Completado<br><br>E = Con errores |
| bpc_usuario | login | 14 | NOT NULL | Usuario que ejecutó el proceso |
| bpc_fecha_inicio | datetime | 8 | NOT NULL | Fecha de inicio del proceso |
| bpc_fecha_fin | datetime | 8 | NULL | Fecha de fin del proceso |
| bpc_observacion | varchar | 255 | NULL | Observaciones del proceso |

## Índices

- **ca_batch_pagos_corresponsal_1** (UNIQUE NONCLUSTERED INDEX): bpc_lote
- **ca_batch_pagos_corresponsal_2** (NONCLUSTERED INDEX): bpc_fecha_proceso
- **ca_batch_pagos_corresponsal_3** (NONCLUSTERED INDEX): bpc_corresponsal
- **ca_batch_pagos_corresponsal_4** (NONCLUSTERED INDEX): bpc_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
