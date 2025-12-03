# cr_situacion_inversiones

## Descripción

Almacena información sobre las inversiones del cliente.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| si_tramite | Int | 4 | NOT NULL | Número de trámite | |
| si_secuencial | Smallint | 2 | NOT NULL | Secuencial de la inversión | |
| si_ente | Int | 4 | NOT NULL | Código de cliente | |
| si_tipo_inversion | Varchar | 10 | NULL | Tipo de inversión | |
| si_institucion | Varchar | 64 | NULL | Institución donde está la inversión | |
| si_descripcion | Varchar | 255 | NULL | Descripción de la inversión | |
| si_monto | Money | 8 | NULL | Monto de la inversión | |
| si_fecha_inicio | Datetime | 8 | NULL | Fecha de inicio | |
| si_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |
| si_tasa_interes | Float | 8 | NULL | Tasa de interés | |

## Transacciones de Servicio

21040, 21140, 21240

## Índices

- cr_situacion_inversiones_Key
- cr_situacion_inversiones_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
