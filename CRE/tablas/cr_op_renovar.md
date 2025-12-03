# cr_op_renovar

## Descripción

Almacena información de operaciones candidatas para renovación.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| or_operacion | Int | 4 | NOT NULL | Número de operación | |
| or_banco | Varchar | 24 | NOT NULL | Código de operación banco | |
| or_cliente | Int | 4 | NOT NULL | Código de cliente | |
| or_monto_original | Money | 8 | NULL | Monto original de la operación | |
| or_saldo_capital | Money | 8 | NULL | Saldo de capital actual | |
| or_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |
| or_estado | Char | 1 | NOT NULL | Estado de renovación | P: Pendiente<br>R: Renovada<br>N: No renovada |
| or_tramite_renovacion | Int | 4 | NULL | Número de trámite de renovación | |
| or_fecha_proceso | Datetime | 8 | NULL | Fecha de procesamiento | |

## Transacciones de Servicio

21033, 21133

## Índices

- cr_op_renovar_Key
- cr_op_renovar_idx1
- cr_op_renovar_idx2

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
