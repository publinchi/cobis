# ca_tasas_tmp

## Descripción

Tabla temporal que almacena tasas de interés durante procesos de simulación o modificación, antes de su aplicación definitiva.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tat_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| tat_secuencial | int | 4 | NOT NULL | Secuencial de la tasa |
| tat_fecha_vigencia | datetime | 8 | NOT NULL | Fecha de vigencia de la tasa |
| tat_tasa | float | 8 | NOT NULL | Valor de la tasa de interés |
| tat_tipo_tasa | char | 1 | NOT NULL | Tipo de tasa<br><br>N = Nominal<br><br>E = Efectiva |
| tat_base | smallint | 2 | NOT NULL | Base de cálculo (360, 365, 366) |
| tat_estado | char | 1 | NOT NULL | Estado de la tasa<br><br>V = Vigente<br><br>I = Inactiva |
| tat_usuario | login | 14 | NOT NULL | Usuario que registró la tasa |
| tat_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| tat_observacion | varchar | 255 | NULL | Observaciones |

## Índices

- **ca_tasas_tmp_1** (UNIQUE NONCLUSTERED INDEX): tat_operacion, tat_secuencial

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
