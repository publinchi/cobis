# cu_por_inspeccionar

## Descripción

Almacena las garantías cuya inspección es solicitada por el banco.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| pi_filial | Tinyint | 1 | NOT NULL | Código de la filial |
| pi_sucursal | Smallint | 2 | NOT NULL | Código sucursal |
| pi_tipo | Descripcion | 64 | NOT NULL | Código de tipo de garantía |
| pi_custodia | Int | 4 | NOT NULL | Código numérico de garantía |
| pi_fecha_ant | Datetime | 8 | NULL | Fecha de inspección anterior |
| pi_inspector_ant | Tinyint | 1 | NOT NULL | Código de inspector que realizó la inspección anterior |
| pi_estado_ant | Catalogo | 10 | NOT NULL | Estado anterior de la inspección |
| pi_inspector_asig | Tinyint | 1 | NOT NULL | Código de inspector asignado. |
| pi_fecha_asig | Datetime | 8 | NOT NULL | Fecha de asignación de inspector |
| pi_riesgos | Money | 8 | NOT NULL | Monto de riesgo del cliente |
| pi_codigo_externo | Varchar | 64 | NOT NULL | Código compuesto de la garantía |
| pi_inspeccionado | Varchar | 1 | NULL | Indica si ha sido inspeccionado |
| pi_fecha_insp | Datetime | 8 | NULL | Fecha de inspección |
| pi_fenvio_carta | Datetime | 8 | NULL | Fecha de envío de carta |
| pi_frecep_reporte | Datetime | 8 | NULL | Fecha de recepción de reporte |
| pi_deudor | Int | 4 | NULL | Código del cliente |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
