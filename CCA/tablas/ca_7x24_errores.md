# ca_7x24_errores

## Descripción

Tabla que registra los errores ocurridos en el servicio 7x24 durante consultas y pagos. Permite llevar un log de incidencias para análisis y corrección.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| er7_secuencial | int | 4 | NOT NULL | Secuencial del error |
| er7_fecha | datetime | 8 | NOT NULL | Fecha del error |
| er7_tipo_operacion | varchar | 50 | NOT NULL | Tipo de operación (consulta, pago, etc.) |
| er7_operacion | int | 4 | NULL | Número de operación (si aplica) |
| er7_cliente | int | 4 | NULL | Código del cliente (si aplica) |
| er7_codigo_error | int | 4 | NOT NULL | Código del error |
| er7_descripcion_error | varchar | 255 | NOT NULL | Descripción del error |
| er7_datos_entrada | varchar | 1000 | NULL | Datos de entrada de la transacción |
| er7_ip_origen | varchar | 50 | NULL | IP de origen de la solicitud |
| er7_canal | varchar | 20 | NULL | Canal de origen (web, móvil, etc.) |
| er7_estado | char | 1 | NOT NULL | Estado del error<br><br>P = Pendiente<br><br>R = Resuelto<br><br>I = Ignorado |
| er7_fecha_resolucion | datetime | 8 | NULL | Fecha de resolución |

## Índices

- **ca_7x24_errores_1** (UNIQUE NONCLUSTERED INDEX): er7_secuencial
- **ca_7x24_errores_2** (NONCLUSTERED INDEX): er7_fecha
- **ca_7x24_errores_3** (NONCLUSTERED INDEX): er7_operacion
- **ca_7x24_errores_4** (NONCLUSTERED INDEX): er7_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
