# cr_situacion_otras

## Descripción

Almacena otra información financiera relevante del cliente.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| so_tramite | Int | 4 | NOT NULL | Número de trámite | |
| so_secuencial | Smallint | 2 | NOT NULL | Secuencial del registro | |
| so_ente | Int | 4 | NOT NULL | Código de cliente | |
| so_tipo_informacion | Varchar | 10 | NULL | Tipo de información | |
| so_descripcion | Varchar | 255 | NULL | Descripción | |
| so_valor | Money | 8 | NULL | Valor asociado | |
| so_observacion | Varchar | 1000 | NULL | Observaciones | |

## Transacciones de Servicio

21042, 21142, 21242

## Índices

- cr_situacion_otras_Key
- cr_situacion_otras_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
