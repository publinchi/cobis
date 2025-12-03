# ca_qr_transacciones_tmp

## Descripción

Tabla temporal que almacena consultas de transacciones realizadas a través de códigos QR. Permite el procesamiento asíncrono de consultas.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| qrt_secuencial | int | 4 | NOT NULL | Secuencial de la consulta |
| qrt_codigo_qr | varchar | 100 | NOT NULL | Código QR generado |
| qrt_operacion | int | 4 | NOT NULL | Número de operación |
| qrt_tipo_consulta | varchar | 50 | NOT NULL | Tipo de consulta solicitada |
| qrt_fecha_generacion | datetime | 8 | NOT NULL | Fecha de generación del QR |
| qrt_fecha_vencimiento | datetime | 8 | NOT NULL | Fecha de vencimiento del QR |
| qrt_estado | char | 1 | NOT NULL | Estado de la consulta<br><br>G = Generado<br><br>C = Consultado<br><br>V = Vencido |
| qrt_fecha_consulta | datetime | 8 | NULL | Fecha de consulta |
| qrt_ip_consulta | varchar | 50 | NULL | IP desde donde se consultó |
| qrt_resultado | varchar | 1000 | NULL | Resultado de la consulta |

## Índices

- **ca_qr_transacciones_tmp_1** (UNIQUE NONCLUSTERED INDEX): qrt_secuencial
- **ca_qr_transacciones_tmp_2** (NONCLUSTERED INDEX): qrt_codigo_qr
- **ca_qr_transacciones_tmp_3** (NONCLUSTERED INDEX): qrt_operacion
- **ca_qr_transacciones_tmp_4** (NONCLUSTERED INDEX): qrt_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
