# ca_incentivos_obtencion_indicadores

## Descripción

Tabla que almacena el cálculo de indicadores para incentivos de oficiales de crédito. Contiene los resultados del proceso de evaluación de metas y desempeño.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ioi_secuencial | int | 4 | NOT NULL | Secuencial del registro |
| ioi_periodo | varchar | 6 | NOT NULL | Período de cálculo (YYYYMM) |
| ioi_oficial | smallint | 2 | NOT NULL | Código del oficial |
| ioi_oficina | smallint | 2 | NOT NULL | Código de la oficina |
| ioi_indicador | varchar | 50 | NOT NULL | Nombre del indicador |
| ioi_meta | float | 8 | NOT NULL | Meta establecida |
| ioi_valor_obtenido | float | 8 | NOT NULL | Valor obtenido |
| ioi_porcentaje_cumplimiento | float | 8 | NOT NULL | Porcentaje de cumplimiento |
| ioi_puntaje | float | 8 | NOT NULL | Puntaje asignado |
| ioi_monto_incentivo | money | 8 | NOT NULL | Monto del incentivo calculado |
| ioi_estado | char | 1 | NOT NULL | Estado del cálculo<br><br>C = Calculado<br><br>A = Aprobado<br><br>P = Pagado<br><br>N = Anulado |
| ioi_fecha_calculo | datetime | 8 | NOT NULL | Fecha de cálculo |
| ioi_observacion | varchar | 255 | NULL | Observaciones |

## Índices

- **ca_incentivos_obtencion_indicadores_1** (UNIQUE NONCLUSTERED INDEX): ioi_secuencial
- **ca_incentivos_obtencion_indicadores_2** (NONCLUSTERED INDEX): ioi_periodo, ioi_oficial
- **ca_incentivos_obtencion_indicadores_3** (NONCLUSTERED INDEX): ioi_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
