# cr_estado_linea

## Descripción

Catálogo de estados posibles para las líneas de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| el_codigo | Char | 1 | NOT NULL | Código del estado | |
| el_descripcion | Varchar | 64 | NOT NULL | Descripción del estado | |
| el_permite_desembolso | Char | 1 | NOT NULL | Permite realizar desembolsos | S: Sí<br>N: No |
| el_permite_modificacion | Char | 1 | NOT NULL | Permite modificaciones | S: Sí<br>N: No |

## Transacciones de Servicio

Tabla de catálogo.

## Índices

- cr_estado_linea_Key

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
