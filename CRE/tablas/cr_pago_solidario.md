# cr_pago_solidario

## Descripción

Almacena información sobre pagos solidarios realizados en créditos grupales.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ps_secuencial | Int | 4 | NOT NULL | Secuencial del pago solidario | |
| ps_operacion_deudor | Int | 4 | NOT NULL | Operación del deudor moroso | |
| ps_cliente_deudor | Int | 4 | NOT NULL | Cliente deudor | |
| ps_operacion_pagador | Int | 4 | NOT NULL | Operación del que paga | |
| ps_cliente_pagador | Int | 4 | NOT NULL | Cliente que realiza el pago | |
| ps_monto | Money | 8 | NOT NULL | Monto del pago solidario | |
| ps_fecha | Datetime | 8 | NOT NULL | Fecha del pago | |
| ps_usuario | Varchar | 14 | NOT NULL | Usuario que registra | |
| ps_observacion | Varchar | 255 | NULL | Observaciones | |
| ps_estado | Char | 1 | NOT NULL | Estado del pago | V: Vigente<br>A: Anulado |

## Transacciones de Servicio

21051, 21151

## Índices

- cr_pago_solidario_Key
- cr_pago_solidario_idx1
- cr_pago_solidario_idx2

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
