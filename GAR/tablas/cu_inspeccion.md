# cu_inspeccion

## Descripción

Registra las inspecciones realizadas o por realizar a los bienes dejados en garantía.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| in_filial | Tinyint | 1 | NOT NULL | Código de la filial |
| in_sucursal | Smallint | 2 | NOT NULL | Código de la sucursal |
| in_tipo_cust | descripcion | 64 | NOT NULL | Tipo de custodia |
| in_custodia | Int | 4 | NOT NULL | Código de la custodia |
| in_fecha_insp | Datetime | 8 | NOT NULL | Fecha de inspección. |
| in_inspector | Tinyint | 1 | NULL | Código del inspector |
| in_estado | catalogo | 10 | NULL | Estado de la inspección<br><br>N= Normal.<br>R= Resistencia |
| in_factura | Varchar | 20 | NULL | Código de la factura. |
| in_valor_fact | Money | 8 | NULL | Valor de la factura |
| in_observaciones | Varchar | 255 | NULL | Observación del resultado de la inspección |
| in_instruccion | Varchar | 255 | NULL | Instrucción que deja el inspector |
| in_motivo | catalogo | 10 | NULL | Motivo de la inspección |
| in_valor_avaluo | Money | 8 | NULL | Valor del avalúo |
| in_estado_tramite | Char | 1 | NULL | Estado del trámite<br><br>S= Crédito automático<br>N= Crédito manual |
| in_codigo_externo | Varchar | 64 | NOT NULL | Código externo para la garantía. |
| in_registrado | Char | 1 | NULL | Indica si está registrado<br><br>S= Registrado<br>N= Sin registrar |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
