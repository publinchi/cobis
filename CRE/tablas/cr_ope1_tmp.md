# cr_ope1_tmp

## Descripción

Tabla temporal para el procesamiento de operaciones durante procesos batch.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_operacion | Int | 4 | NOT NULL | Número de operación | |
| tmp_banco | Varchar | 24 | NULL | Código banco | |
| tmp_cliente | Int | 4 | NULL | Código de cliente | |
| tmp_monto | Money | 8 | NULL | Monto de operación | |
| tmp_estado | Char | 1 | NULL | Estado temporal | |

## Transacciones de Servicio

Utilizada en procesos batch.

## Índices

- tmp_operacion_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
