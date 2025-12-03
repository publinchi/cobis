# cu_tran_conta

## Descripción

Registra información de las transacciones para contabilidad.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| to_secuencial | int | 4 | NOT NULL | Secuencial de la transaccion |
| to_filial | tinyint | 1 | NOT NULL | Código de la filial |
| to_oficina_orig | smallint | 2 | NOT NULL | Oficina origen de transaccion |
| to_oficina_dest | smallint | 2 | NOT NULL | Oficina destino de transaccion |
| to_tipo_cust | descripcion | 64 | NOT NULL | Tipo de custodia |
| to_moneda | tinyint | 1 | NOT NULL | Tipo de moneda |
| to_valor | money | 8 | NOT NULL | Valor de la transaccion |
| to_valor_me | money | 8 | NOT NULL | Valor moneda extranjera |
| to_operacion | char | 1 | NOT NULL | Tipo de operación de la transaccion |
| to_codigo_externo | varchar | 64 | NOT NULL | Codigo compuesto de la garantia |
| to_contabiliza | char | 1 | NULL | Característica que determina si se contabilizo o no una garantia |
| to_fecha | datetime | 8 | NULL | Fecha en que se realiza la transaccion |
| to_codval | int | 4 | NULL | Codigo valor para obtener perfiles contables |
| to_tipo_cca | catalogo | 10 | NULL | Tipo de cartera |
| to_estado | char | 1 | NULL | Estado de proceso de contabilidad |
| to_secuencial_trn | int | 4 | NULL | Codigo Secuencial de la transaccion |
| to_usuario | login | 64 | NULL | Usuario de la transaccion |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
