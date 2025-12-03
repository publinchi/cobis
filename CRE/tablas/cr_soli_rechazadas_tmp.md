# cr_soli_rechazadas_tmp

## Descripción

Tabla temporal para almacenar información de solicitudes rechazadas durante procesos batch.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| tmp_cliente | Int | 4 | NULL | Código de cliente | |
| tmp_fecha_rechazo | Datetime | 8 | NULL | Fecha de rechazo | |
| tmp_motivo_rechazo | Varchar | 10 | NULL | Código de motivo de rechazo | |
| tmp_observacion | Varchar | 255 | NULL | Observaciones | |

## Transacciones de Servicio

Utilizada en procesos batch.

## Índices

- tmp_tramite_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
