# cu_recuperacion

## Descripción

Registra los valores efectivamente recuperados de las garantías con vencimientos (ejemplo, cheques, facturas, pagarés, etc.).

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| re_filial | Tinyint | 1 | NOT NULL | Código de filial |
| re_sucursal | Smallint | 2 | NOT NULL | Código de sucursal |
| re_tipo_cust | Descripcion | 64 | NOT NULL | Tipo de custodia |
| re_custodia | Int | 4 | NOT NULL | Código de custodia |
| re_recuperacion | Smallint | 2 | NOT NULL | Código de recuperación |
| re_valor | Money | 8 | NOT NULL | Valor de recuperación |
| re_vencimiento | Smallint | 2 | NOT NULL | Valor de vencimiento |
| re_fecha | Datetime | 8 | NULL | Fecha de recuperación |
| re_cobro_vencimiento | Money | 8 | NULL | Valor de cobro al vencimiento |
| re_cobro_mora | Money | 8 | NULL | Valor en mora |
| re_cobro_comision | Money | 8 | NULL | Valor de comisión |
| re_codigo_externo | Varchar | 64 | NOT NULL | Código compuesto de la garantía |
| re_ret_iva | Moneynt | 8 | NOT NULL | Valor Iva de la recuperación |
| re_ret_fte | Money | 8 | NOT NULL | Valor Retefuente de la recuperación |
| re_operacion | Int | 4 | NOT NULL | Numero de la operación |
| re_secuencial_ab | Int | 4 | NOT NULL | Secuencial de pago |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
