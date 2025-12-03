# cr_clientes_renovacion

## Descripción

Almacena información de clientes elegibles para renovación de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| crn_cliente | Int | 4 | NOT NULL | Código de cliente | |
| crn_operacion_anterior | Int | 4 | NOT NULL | Número de operación anterior | |
| crn_monto_sugerido | Money | 8 | NULL | Monto sugerido para renovación | |
| crn_plazo_sugerido | Smallint | 2 | NULL | Plazo sugerido | |
| crn_fecha_elegibilidad | Datetime | 8 | NULL | Fecha desde que es elegible | |
| crn_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento de elegibilidad | |
| crn_estado | Char | 1 | NOT NULL | Estado | P: Pendiente<br>R: Renovado<br>N: No renovado |
| crn_observacion | Varchar | 255 | NULL | Observaciones | |

## Transacciones de Servicio

21049, 21149

## Índices

- cr_clientes_renovacion_Key
- cr_clientes_renovacion_idx1
- cr_clientes_renovacion_idx2

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
