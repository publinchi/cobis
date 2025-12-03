# cu_vencimiento

## Descripción

Registra los vencimientos de garantías que tienen fechas de expiración o renovación, como cheques, pagarés, facturas u otros documentos con fecha de vencimiento específica.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| ve_codigo_externo | Varchar | 64 | NOT NULL | Código externo para la garantía |
| ve_vencimiento | Smallint | 2 | NOT NULL | Número secuencial del vencimiento |
| ve_filial | Tinyint | 1 | NOT NULL | Código de la filial |
| ve_sucursal | Smallint | 2 | NOT NULL | Código de la sucursal |
| ve_tipo_cust | Descripcion | 64 | NOT NULL | Tipo de custodia |
| ve_custodia | Int | 4 | NOT NULL | Código de la custodia |
| ve_fecha_vencimiento | Datetime | 8 | NOT NULL | Fecha de vencimiento del documento |
| ve_valor | Money | 8 | NOT NULL | Valor del documento al vencimiento |
| ve_deudor | Int | 4 | NULL | Código del cliente deudor |
| ve_estado | Char | 1 | NULL | Estado del vencimiento<br><br>P= Pendiente<br>C= Cobrado<br>V= Vencido<br>A= Anulado |
| ve_cta_debito | Varchar | 24 | NULL | Cuenta de débito para el cobro |
| ve_tipo_documento | Catalogo | 10 | NULL | Tipo de documento con vencimiento |
| ve_numero_documento | Varchar | 30 | NULL | Número del documento |
| ve_fecha_cobro | Datetime | 8 | NULL | Fecha en que se realizó el cobro |
| ve_valor_cobrado | Money | 8 | NULL | Valor efectivamente cobrado |
| ve_observaciones | Varchar | 255 | NULL | Observaciones sobre el vencimiento |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
