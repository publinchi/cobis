# cr_gasto_linea

## Descripción

Almacena los gastos asociados a las líneas de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gl_linea | Int | 4 | NOT NULL | Código numérico de línea | |
| gl_secuencial | Smallint | 2 | NOT NULL | Secuencial del gasto | |
| gl_tipo_gasto | Varchar | 10 | NOT NULL | Tipo de gasto | |
| gl_descripcion | Varchar | 255 | NULL | Descripción del gasto | |
| gl_monto | Money | 8 | NOT NULL | Monto del gasto | |
| gl_fecha | Datetime | 8 | NOT NULL | Fecha del gasto | |
| gl_usuario | Varchar | 14 | NOT NULL | Usuario que registra | |
| gl_estado | Char | 1 | NOT NULL | Estado del gasto | V: Vigente<br>A: Anulado |

## Transacciones de Servicio

21047, 21147

## Índices

- cr_gasto_linea_Key
- cr_gasto_linea_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
