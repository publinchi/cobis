# cu_transaccion

## Descripción

Registra las transacciones realizadas para modificar las garantías de este módulo.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tr_codigo_externo | Varchar | 64 | NOT NULL | Código compuesto de garantía |
| tr_fecha_tran | Datetime | 8 | NOT NULL | Fecha de la transacción |
| tr_descripcion | Varchar | 64 | NULL | Descripción de la transacción |
| tr_usuario | Varchar | 64 | NOT NULL | Usuario que ejecutó la transacción |
| tr_filial | Tinyint | 1 | NOT NULL | Oficina en la que se realiza la transacción |
| tr_sucursal | smallint | 2 | NOT NULL | Sucursal de la transacción |
| tr_tipo_cust | Descripcion | 64 | NOT NULL | Tipo garantía |
| tr_custodia | int | 4 | NOT NULL | Garantía |
| tr_transaccion | smallint | 2 | NOT NULL | Número de la transacción |
| tr_debcred | char | 1 | NOT NULL | Tipo de transacción.<br><br>D - Débito<br>C - Crédito<br>(Catálogo cu_causa_transaccion Devaluación, Revalorización) |
| tr_valor | Money | 8 | NOT NULL | Valor de la transacción |
| tr_valor_anterior | Money | 8 | NULL | Valor anterior de la transacción |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
