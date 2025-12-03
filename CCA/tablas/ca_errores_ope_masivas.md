# ca_errores_ope_masivas

## Descripción

Tabla que registra los errores ocurridos durante procesos de operaciones masivas. Permite llevar el control de registros que no pudieron ser procesados.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| eom_secuencial | int | 4 | NOT NULL | Secuencial del error |
| eom_lote | int | 4 | NOT NULL | Número de lote del proceso masivo |
| eom_tipo_proceso | varchar | 50 | NOT NULL | Tipo de proceso masivo |
| eom_fecha_proceso | datetime | 8 | NOT NULL | Fecha del proceso |
| eom_operacion | varchar | 24 | NULL | Número de operación (si aplica) |
| eom_linea | int | 4 | NOT NULL | Número de línea del archivo |
| eom_codigo_error | int | 4 | NOT NULL | Código del error |
| eom_descripcion_error | varchar | 255 | NOT NULL | Descripción del error |
| eom_datos_registro | varchar | 1000 | NULL | Datos del registro con error |
| eom_estado | char | 1 | NOT NULL | Estado del error<br><br>P = Pendiente<br><br>C = Corregido<br><br>I = Ignorado |
| eom_usuario | login | 14 | NOT NULL | Usuario que ejecutó el proceso |

## Índices

- **ca_errores_ope_masivas_1** (UNIQUE NONCLUSTERED INDEX): eom_secuencial
- **ca_errores_ope_masivas_2** (NONCLUSTERED INDEX): eom_lote
- **ca_errores_ope_masivas_3** (NONCLUSTERED INDEX): eom_fecha_proceso
- **ca_errores_ope_masivas_4** (NONCLUSTERED INDEX): eom_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
