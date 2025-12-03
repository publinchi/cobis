# tmp_garantias

## Descripción

Tabla temporal para el procesamiento de garantías en operaciones masivas.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| tmp_garantia | Varchar | 64 | NOT NULL | Código de garantía | |
| tmp_tipo | Varchar | 10 | NULL | Tipo de garantía | |
| tmp_valor | Money | 8 | NULL | Valor de la garantía | |
| tmp_porcentaje | Float | 8 | NULL | Porcentaje de cobertura | |
| tmp_estado | Char | 1 | NULL | Estado temporal | |

## Transacciones de Servicio

Utilizada en procesos batch.

## Índices

- tmp_tramite_garantia_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
