# cr_buro_credito

## Descripción

Almacena información de consultas a burós de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| bc_secuencial | Int | 4 | NOT NULL | Secuencial de consulta | |
| bc_tramite | Int | 4 | NULL | Número de trámite | |
| bc_cliente | Int | 4 | NOT NULL | Código de cliente | |
| bc_fecha_consulta | Datetime | 8 | NOT NULL | Fecha de consulta | |
| bc_buro | Varchar | 10 | NOT NULL | Código del buró consultado | |
| bc_score | Int | 4 | NULL | Score obtenido | |
| bc_resultado | Varchar | 255 | NULL | Resultado de la consulta | |
| bc_archivo_respuesta | Varchar | 255 | NULL | Ruta del archivo de respuesta | |
| bc_usuario | Varchar | 14 | NOT NULL | Usuario que consulta | |
| bc_costo | Money | 8 | NULL | Costo de la consulta | |

## Transacciones de Servicio

21053, 21153

## Índices

- cr_buro_credito_Key
- cr_buro_credito_idx1
- cr_buro_credito_idx2

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
