# ca_tasas

## Descripción

Tabla que almacena las tasas de interés vigentes para cada operación de cartera. Registra el historial de tasas aplicadas a lo largo de la vida del préstamo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ta_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| ta_secuencial | int | 4 | NOT NULL | Secuencial de la tasa |
| ta_fecha_vigencia | datetime | 8 | NOT NULL | Fecha de vigencia de la tasa |
| ta_tasa | float | 8 | NOT NULL | Valor de la tasa de interés |
| ta_tipo_tasa | char | 1 | NOT NULL | Tipo de tasa<br><br>N = Nominal<br><br>E = Efectiva |
| ta_base | smallint | 2 | NOT NULL | Base de cálculo (360, 365, 366) |
| ta_estado | char | 1 | NOT NULL | Estado de la tasa<br><br>V = Vigente<br><br>I = Inactiva |
| ta_usuario | login | 14 | NOT NULL | Usuario que registró la tasa |
| ta_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| ta_observacion | varchar | 255 | NULL | Observaciones |

## Índices

- **ca_tasas_1** (UNIQUE NONCLUSTERED INDEX): ta_operacion, ta_secuencial
- **ca_tasas_2** (NONCLUSTERED INDEX): ta_fecha_vigencia
- **ca_tasas_3** (NONCLUSTERED INDEX): ta_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
