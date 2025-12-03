# ca_incentivos_metas

## Descripción

Tabla que almacena las metas establecidas para el cálculo de incentivos a oficiales de crédito. Define los objetivos y parámetros de evaluación.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| im_codigo | int | 4 | NOT NULL | Código de la meta |
| im_periodo | varchar | 6 | NOT NULL | Período de vigencia (YYYYMM) |
| im_indicador | varchar | 50 | NOT NULL | Nombre del indicador |
| im_descripcion | varchar | 255 | NOT NULL | Descripción de la meta |
| im_tipo_meta | char | 1 | NOT NULL | Tipo de meta<br><br>I = Individual<br><br>O = Oficina<br><br>G = General |
| im_oficial | smallint | 2 | NULL | Código del oficial (si es individual) |
| im_oficina | smallint | 2 | NULL | Código de la oficina (si es por oficina) |
| im_valor_meta | float | 8 | NOT NULL | Valor de la meta |
| im_peso | float | 8 | NOT NULL | Peso del indicador en el cálculo total |
| im_monto_incentivo | money | 8 | NOT NULL | Monto del incentivo por cumplimiento |
| im_estado | char | 1 | NOT NULL | Estado de la meta<br><br>V = Vigente<br><br>I = Inactiva |
| im_fecha_inicio | datetime | 8 | NOT NULL | Fecha de inicio de vigencia |
| im_fecha_fin | datetime | 8 | NOT NULL | Fecha de fin de vigencia |

## Índices

- **ca_incentivos_metas_1** (UNIQUE NONCLUSTERED INDEX): im_codigo
- **ca_incentivos_metas_2** (NONCLUSTERED INDEX): im_periodo, im_estado
- **ca_incentivos_metas_3** (NONCLUSTERED INDEX): im_oficial

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
