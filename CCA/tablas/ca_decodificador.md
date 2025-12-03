# ca_decodificador

## Descripción

Tabla que permite la descomposición de datos del préstamo para análisis y reportería. Facilita la extracción de información específica de campos compuestos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| de_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| de_campo | varchar | 50 | NOT NULL | Nombre del campo a decodificar |
| de_posicion | tinyint | 1 | NOT NULL | Posición del dato dentro del campo |
| de_longitud | tinyint | 1 | NOT NULL | Longitud del dato a extraer |
| de_valor | varchar | 100 | NULL | Valor extraído |
| de_descripcion | varchar | 255 | NULL | Descripción del valor extraído |

## Índices

- **ca_decodificador_1** (UNIQUE NONCLUSTERED INDEX): de_operacion, de_campo, de_posicion

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
