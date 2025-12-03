# cr_segmentacion_cliente

## Descripción

Almacena la segmentación de clientes para análisis y estrategias comerciales.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sgc_cliente | Int | 4 | NOT NULL | Código de cliente | |
| sgc_segmento | Varchar | 10 | NOT NULL | Código de segmento | |
| sgc_subsegmento | Varchar | 10 | NULL | Código de subsegmento | |
| sgc_score | Int | 4 | NULL | Puntaje de score | |
| sgc_fecha_segmentacion | Datetime | 8 | NOT NULL | Fecha de segmentación | |
| sgc_usuario | Varchar | 14 | NOT NULL | Usuario que segmenta | |
| sgc_observacion | Varchar | 255 | NULL | Observaciones | |

## Transacciones de Servicio

21050, 21150

## Índices

- cr_segmentacion_cliente_Key
- cr_segmentacion_cliente_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
