# ca_incentivos_metas_tmp

## Descripción

Tabla temporal que almacena metas de incentivos durante procesos de carga o modificación masiva, antes de su aplicación definitiva.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| imt_codigo | int | 4 | NOT NULL | Código de la meta |
| imt_periodo | varchar | 6 | NOT NULL | Período de vigencia (YYYYMM) |
| imt_indicador | varchar | 50 | NOT NULL | Nombre del indicador |
| imt_descripcion | varchar | 255 | NOT NULL | Descripción de la meta |
| imt_tipo_meta | char | 1 | NOT NULL | Tipo de meta<br><br>I = Individual<br><br>O = Oficina<br><br>G = General |
| imt_oficial | smallint | 2 | NULL | Código del oficial (si es individual) |
| imt_oficina | smallint | 2 | NULL | Código de la oficina (si es por oficina) |
| imt_valor_meta | float | 8 | NOT NULL | Valor de la meta |
| imt_peso | float | 8 | NOT NULL | Peso del indicador en el cálculo total |
| imt_monto_incentivo | money | 8 | NOT NULL | Monto del incentivo por cumplimiento |
| imt_estado | char | 1 | NOT NULL | Estado de la meta<br><br>V = Vigente<br><br>I = Inactiva |
| imt_fecha_inicio | datetime | 8 | NOT NULL | Fecha de inicio de vigencia |
| imt_fecha_fin | datetime | 8 | NOT NULL | Fecha de fin de vigencia |
| imt_usuario | login | 14 | NOT NULL | Usuario que cargó el registro |
| imt_fecha_carga | datetime | 8 | NOT NULL | Fecha de carga |

## Índices

- **ca_incentivos_metas_tmp_1** (UNIQUE NONCLUSTERED INDEX): imt_codigo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
