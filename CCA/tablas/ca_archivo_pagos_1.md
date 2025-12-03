# ca_archivo_pagos_1

## Descripción

Tabla que almacena el archivo de salida de pagos procesados. Contiene los registros de pagos que fueron validados y aplicados exitosamente.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ap_secuencial | int | 4 | NOT NULL | Secuencial del registro |
| ap_lote | int | 4 | NOT NULL | Número de lote de carga |
| ap_operacion | int | 4 | NOT NULL | Número interno de operación |
| ap_banco | varchar | 24 | NOT NULL | Número banco de la operación |
| ap_monto | money | 8 | NOT NULL | Monto del pago |
| ap_fecha_pago | datetime | 8 | NOT NULL | Fecha del pago |
| ap_referencia | varchar | 50 | NULL | Referencia del pago |
| ap_forma_pago | catalogo | 10 | NOT NULL | Forma de pago |
| ap_secuencial_pago | int | 4 | NOT NULL | Secuencial del pago aplicado |
| ap_estado | char | 1 | NOT NULL | Estado del registro<br><br>A = Aplicado<br><br>R = Reversado |
| ap_fecha_proceso | datetime | 8 | NOT NULL | Fecha de procesamiento |
| ap_usuario | login | 14 | NOT NULL | Usuario que procesó el pago |

## Índices

- **ca_archivo_pagos_1_1** (UNIQUE NONCLUSTERED INDEX): ap_secuencial
- **ca_archivo_pagos_1_2** (NONCLUSTERED INDEX): ap_lote
- **ca_archivo_pagos_1_3** (NONCLUSTERED INDEX): ap_operacion
- **ca_archivo_pagos_1_4** (NONCLUSTERED INDEX): ap_secuencial_pago

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
