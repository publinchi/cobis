# cr_gar_tmp

## Descripción

Tabla temporal para el procesamiento de garantías durante operaciones de carga masiva.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| tmp_secuencial | Smallint | 2 | NOT NULL | Secuencial de garantía | |
| tmp_garantia | Varchar | 64 | NULL | Código de garantía | |
| tmp_tipo | Varchar | 10 | NULL | Tipo de garantía | |
| tmp_valor | Money | 8 | NULL | Valor de la garantía | |

## Transacciones de Servicio

Utilizada en procesos de migración.

## Índices

- tmp_tramite_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
