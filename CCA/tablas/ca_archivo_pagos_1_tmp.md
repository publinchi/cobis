# ca_archivo_pagos_1_tmp

## Descripción

Tabla temporal que almacena el archivo de entrada de pagos cargados desde archivos externos. Contiene los registros antes de ser procesados y validados.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| apt_secuencial | int | 4 | NOT NULL | Secuencial del registro |
| apt_lote | int | 4 | NOT NULL | Número de lote de carga |
| apt_operacion | varchar | 24 | NOT NULL | Número de operación (banco) |
| apt_monto | money | 8 | NOT NULL | Monto del pago |
| apt_fecha_pago | datetime | 8 | NOT NULL | Fecha del pago |
| apt_referencia | varchar | 50 | NULL | Referencia del pago |
| apt_forma_pago | varchar | 10 | NULL | Forma de pago |
| apt_estado | char | 1 | NOT NULL | Estado del registro<br><br>P = Pendiente<br><br>V = Validado<br><br>E = Error |
| apt_error | varchar | 255 | NULL | Descripción del error (si existe) |
| apt_fecha_carga | datetime | 8 | NOT NULL | Fecha de carga del archivo |
| apt_usuario | login | 14 | NOT NULL | Usuario que cargó el archivo |

## Índices

- **ca_archivo_pagos_1_tmp_1** (UNIQUE NONCLUSTERED INDEX): apt_secuencial
- **ca_archivo_pagos_1_tmp_2** (NONCLUSTERED INDEX): apt_lote
- **ca_archivo_pagos_1_tmp_3** (NONCLUSTERED INDEX): apt_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
