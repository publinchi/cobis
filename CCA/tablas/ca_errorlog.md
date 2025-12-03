# ca_errorlog

## Descripción

Tabla que funciona como bitácora de errores de los procesos batch del módulo de cartera. Registra todos los errores ocurridos durante la ejecución de procesos automáticos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| er_secuencial | int | 4 | NOT NULL | Secuencial del error |
| er_fecha_proceso | datetime | 8 | NOT NULL | Fecha del proceso que generó el error |
| er_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro del error |
| er_proceso | varchar | 50 | NOT NULL | Nombre del proceso batch |
| er_operacion | int | 4 | NULL | Número de operación afectada |
| er_error | int | 4 | NOT NULL | Código del error |
| er_descripcion | varchar | 255 | NOT NULL | Descripción del error |
| er_severidad | char | 1 | NOT NULL | Severidad del error<br><br>I = Informativo<br><br>W = Warning<br><br>E = Error<br><br>F = Fatal |
| er_estado | char | 1 | NOT NULL | Estado del error<br><br>P = Pendiente<br><br>R = Resuelto<br><br>I = Ignorado |

## Índices

- **ca_errorlog_1** (UNIQUE NONCLUSTERED INDEX): er_secuencial
- **ca_errorlog_2** (NONCLUSTERED INDEX): er_fecha_proceso
- **ca_errorlog_3** (NONCLUSTERED INDEX): er_operacion
- **ca_errorlog_4** (NONCLUSTERED INDEX): er_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
