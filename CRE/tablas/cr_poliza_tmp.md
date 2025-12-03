# cr_poliza_tmp

## Descripción

Tabla temporal para el procesamiento de información de pólizas de seguro asociadas a créditos.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| tmp_numero_poliza | Varchar | 30 | NOT NULL | Número de póliza | |
| tmp_aseguradora | Varchar | 64 | NULL | Nombre de aseguradora | |
| tmp_monto_asegurado | Money | 8 | NULL | Monto asegurado | |
| tmp_fecha_inicio | Datetime | 8 | NULL | Fecha inicio vigencia | |
| tmp_fecha_fin | Datetime | 8 | NULL | Fecha fin vigencia | |

## Transacciones de Servicio

Utilizada en procesos batch.

## Índices

- tmp_tramite_poliza_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
