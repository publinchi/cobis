# cu_gastos

## Descripción

Registra los gastos por inspecciones, avalúos o visitas a los bienes que se dejan en garantía y que se deberán cobrar al cliente.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripcion** |
| --- | --- | --- | --- | --- |
| ga_filial | Tinyint | 1 | NOT NULL | Código de la filial. |
| ga_sucursal | Smallint | 2 | NOT NULL | Código de la sucursal. |
| ga_tipo_cust | descripcion | 64 | NOT NULL | Tipo de custodia. |
| ga_custodia | Int | 4 | NOT NULL | Código de la custodia. |
| ga_gastos | Smallint | 2 | NOT NULL | Secuencial del registro de gastos |
| ga_descripcion | Varchar | 64 | NULL | Descripción del gasto |
| ga_monto | Money | 8 | NULL | Valor del monto |
| ga_fecha | Datetime | 8 | NULL | Fecha de registro |
| ga_codigo_externo | Varchar | 64 | NOT NULL | Código compuesto de la garantía |
| ga_registrado | Char | 1 | NULL | Indica si está registrado<br><br>S= Registrado<br>N= Sin registrar |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
