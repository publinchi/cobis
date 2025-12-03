# cu_inst_operativa

## Descripción

Almacena las instrucciones operativas asociadas a las garantías, permitiendo registrar indicaciones específicas para el manejo de cada custodia.

## Estructura de la tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **Descripción** |
| --- | --- | --- | --- | --- |
| io_codigo_externo | Varchar | 64 | NOT NULL | Código externo para la garantía |
| io_numero | Smallint | 2 | NOT NULL | Número secuencial de la instrucción |
| io_fecha | Datetime | 8 | NULL | Fecha de registro de la instrucción |
| io_instruccion | Varchar | 255 | NULL | Texto de la instrucción operativa |
| io_usuario | Varchar | 64 | NULL | Usuario que registra la instrucción |
| io_estado | Char | 1 | NULL | Estado de la instrucción<br><br>V= Vigente<br>C= Cumplida<br>A= Anulada |
| io_tipo | Catalogo | 10 | NULL | Tipo de instrucción operativa |

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
