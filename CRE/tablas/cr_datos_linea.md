# cr_datos_linea

## Descripción

Almacena información adicional y parámetros específicos de las líneas de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dl_linea | Int | 4 | NOT NULL | Código numérico de línea de crédito | |
| dl_parametro | Varchar | 64 | NOT NULL | Nombre del parámetro | |
| dl_valor | Varchar | 255 | NULL | Valor del parámetro | |
| dl_tipo_dato | Char | 1 | NULL | Tipo de dato del valor | C: Carácter<br>N: Numérico<br>F: Fecha |

## Transacciones de Servicio

21026, 21126, 21262

## Índices

- cr_datos_linea_Key
- cr_datos_linea_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
