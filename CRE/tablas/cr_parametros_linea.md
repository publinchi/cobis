# cr_parametros_linea

## Descripción

Almacena parámetros de configuración específicos para líneas de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| pl_linea | Int | 4 | NOT NULL | Código numérico de línea | |
| pl_parametro | Varchar | 64 | NOT NULL | Nombre del parámetro | |
| pl_valor | Varchar | 255 | NULL | Valor del parámetro | |
| pl_tipo_dato | Char | 1 | NULL | Tipo de dato | C: Carácter<br>N: Numérico<br>F: Fecha<br>M: Money |
| pl_descripcion | Varchar | 255 | NULL | Descripción del parámetro | |

## Transacciones de Servicio

21034, 21134

## Índices

- cr_parametros_linea_Key
- cr_parametros_linea_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
