# cu_tran_servicio

## Descripción

Guarda la información de las transacciones de servicio.

Cada módulo tiene una Base de Datos, la cual cuenta con una tabla de Transacciones de Servicio, en la que se incluyen todos los campos de todas las tablas que pueden sufrir modificación en la operación del módulo (inserción, actualización o eliminación). Se entiende por Vista de Transacciones de Servicio, aquella porción de la tabla Transacciones de Servicio que compete a determinada Transacción.

Cada modificación de la Base de Datos genera un registro indicando la transacción realizada (secuencial, clase y código), persona que ejecuta la transacción (usuario que envía el requerimiento), desde y dónde (terminal, y servidores de origen y ejecución de la transacción) y los datos de la tabla a modificar.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| ts_secuencial | Int | 4 | NOT NULL | Código secuencial |
| ts_tipo_transaccion | Smallint | 2 | NOT NULL | Tipo de transacción |
| ts_clase | Char | 1 | NOT NULL | Clase de movimiento |
| ts_fecha | Datetime | 8 | NULL | Fecha de registro |
| ts_usuario | Varchar | 64 | NULL | Usuario de registro |
| ts_terminal | Varchar | 64 | NULL | Terminal donde se realizo el movimiento |
| ts_correccion | Char | 1 | NULL | Indica si el registro es un reverso.<br><br>S= Es un reverso<br>N= No es un reverso |
| ts_ssn_corr | Int | 4 | NULL | Secuencial de corrección |
| ts_reentry | Char | 1 | NULL | Identifica como fue ejecutada la transacción<br><br>S= Ejecutada por REENTRY<br>N= No ejecutada por REENTRY |
| ts_origen | Char | 1 | NULL | Origen de la transacción<br><br>L= Local<br>R= Remoto |
| ts_nodo | Varchar | 30 | NULL | Descripción de nodo de ejecución |
| ts_remoto_ssn | Int | 4 | NULL | Secuencial de ejecución remota |
| ts_oficina | Tinyint | 1 | NULL | Código de la oficina |
| ts_tabla | Varchar | 255 | NULL | Tabla de modificación |
| ts_tinyint1 | Tinyint | 1 | NULL | Valor modificado de tipo tinyint1 |
| ts_tinyint2 | Tinyint | 1 | NULL | Valor modificado de tipo tinyint2 |
| ts_tinyint3 | Tinyint | 1 | NULL | Valor modificado de tipo tinyint3 |
| ts_tinyint4 | Tinyint | 1 | NULL | Valor modificado de tipo tinyint4 |
| ts_tinyint5 | Tinyint | 1 | NULL | Valor modificado de tipo tinyint5 |
| ts_smallint1 | Smallint | 2 | NULL | Valor modificado de tipo smallint1 |
| ts_smallint2 | Smallint | 2 | NULL | Valor modificado de tipo smallint2 |
| ts_smallint3 | Smallint | 2 | NULL | Valor modificado de tipo smallint3 |
| ts_smallint4 | Smallint | 2 | NULL | Valor modificado de tipo smallint4 |
| ts_int1 | Int | 4 | NULL | Valor modificado de tipo int1 |
| ts_int2 | Int | 4 | NULL | Valor modificado de tipo int2 |
| ts_int3 | Int | 4 | NULL | Valor modificado de tipo int3 |
| ts_int4 | Int | 4 | NULL | Valor modificado de tipo int4 |
| ts_varchar1 | Varchar | 64 | NULL | Valor modificado de tipo varchar1 |
| ts_varchar2 | Varchar | 64 | NULL | Valor modificado de tipo varchar2 |
| ts_varchar3 | Varchar | 64 | NULL | Valor modificado de tipo varchar3 |
| ts_varchar4 | Varchar | 64 | NULL | Valor modificado de tipo varchar4 |
| ts_varchar5 | Varchar | 64 | NULL | Valor modificado de tipo varchar5 |
| ts_varchar6 | Varchar | 64 | NULL | Valor modificado de tipo varchar6 |
| ts_varchar7 | Varchar | 64 | NULL | Valor modificado de tipo varchar7 |
| ts_varchar8 | Varchar | 64 | NULL | Valor modificado de tipo varchar8 |
| ts_varchar9 | Varchar | 64 | NULL | Valor modificado de tipo varchar9 |
| ts_varchar10 | Varchar | 64 | NULL | Valor modificado de tipo varchar10 |
| ts_varchar11 | Varchar | 64 | NULL | Valor modificado de tipo varchar11 |
| ts_varchar12 | Varchar | 64 | NULL | Valor modificado de tipo varchar12 |
| ts_varchar13 | Varchar | 64 | NULL | Valor modificado de tipo varchar13 |
| ts_varchar14 | Varchar | 64 | NULL | Valor modificado de tipo varchar14 |
| ts_varchar15 | Varchar | 64 | NULL | Valor modificado de tipo varchar15 |
| ts_varchar16 | Varchar | 64 | NULL | Valor modificado de tipo varchar16 |
| ts_varchar17 | Varchar | 64 | NULL | Valor modificado de tipo varchar17 |
| ts_varchar18 | Varchar | 64 | NULL | Valor modificado de tipo varchar18 |
| ts_char1 | Char | 1 | NULL | Valor modificado de tipo char1 |
| ts_char2 | Char | 1 | NULL | Valor modificado de tipo char2 |
| ts_char3 | Char | 1 | NULL | Valor modificado de tipo char3 |
| ts_char4 | Char | 1 | NULL | Valor modificado de tipo char4 |
| ts_char5 | Char | 1 | NULL | Valor modificado de tipo char5 |
| ts_char6 | Char | 1 | NULL | Valor modificado de tipo char6 |
| ts_char7 | Char | 1 | NULL | Valor modificado de tipo char7 |
| ts_char8 | Char | 1 | NULL | Valor modificado de tipo char8 |
| ts_char9 | Char | 1 | NULL | Valor modificado de tipo char9 |
| ts_char10 | Char | 1 | NULL | Valor modificado de tipo char10 |
| ts_money1 | Money | 8 | NULL | Valor modificado de tipo money1 |
| ts_money2 | Money | 8 | NULL | Valor modificado de tipo money2 |
| ts_money3 | Money | 8 | NULL | Valor modificado de tipo money3 |
| ts_money4 | Money | 8 | NULL | Valor modificado de tipo money4 |
| ts_money5 | Money | 8 | NULL | Valor modificado de tipo money5 |
| ts_money6 | Money | 8 | NULL | Valor modificado de tipo money6 |
| ts_money7 | Money | 8 | NULL | Valor modificado de tipo money7 |
| ts_money8 | Money | 8 | NULL | Valor modificado de tipo money8 |
| ts_money9 | Money | 8 | NULL | Valor modificado de tipo money9 |
| ts_datetime1 | Datetime | 8 | NULL | Valor modificado de tipo datetime1 |
| ts_datetime2 | Datetime | 8 | NULL | Valor modificado de tipo datetime2 |
| ts_datetime3 | Datetime | 8 | NULL | Valor modificado de tipo datetime3 |
| ts_datetime4 | Datetime | 8 | NULL | Valor modificado de tipo datetime4 |
| ts_datetime5 | Datetime | 8 | NULL | Valor modificado de tipo datetime5 |
| ts_datetime6 | Datetime | 8 | NULL | Valor modificado de tipo datetime6 |
| ts_datetime7 | Datetime | 8 | NULL | Valor modificado de tipo datetime7 |
| ts_datetime8 | Datetime | 8 | NULL | Valor modificado de tipo datetime8 |
| ts_datetime9 | Datetime | 8 | NULL | Valor modificado de tipo datetime9 |
| ts_datetime10 | Datetime | 8 | NULL | Valor modificado de tipo datetime10 |
| ts_float1 | Float | 8 | NULL | Valor modificado de tipo float1 |
| ts_descripcion1 | Varchar | 64 | NULL | Valor modificado de tipo varchar2551 |
| ts_descripcion2 | Varchar | 64 | NULL | Valor modificado de tipo varchar2552 |
| ts_descripcion3 | Varchar | 64 | NULL | Valor modificado de tipo varchar2553 |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
