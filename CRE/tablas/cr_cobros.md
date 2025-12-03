# cr_cobros

## Descripción

Almacena información sobre gestiones de cobro realizadas.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| co_secuencial | Int | 4 | NOT NULL | Secuencial de gestión de cobro | |
| co_operacion | Int | 4 | NOT NULL | Número de operación | |
| co_cliente | Int | 4 | NOT NULL | Código de cliente | |
| co_fecha_gestion | Datetime | 8 | NOT NULL | Fecha de gestión | |
| co_tipo_gestion | Varchar | 10 | NOT NULL | Tipo de gestión | |
| co_resultado | Varchar | 10 | NULL | Resultado de la gestión | |
| co_monto_compromiso | Money | 8 | NULL | Monto comprometido a pagar | |
| co_fecha_compromiso | Datetime | 8 | NULL | Fecha de compromiso de pago | |
| co_observacion | Varchar | 1000 | NULL | Observaciones de la gestión | |
| co_usuario | Varchar | 14 | NOT NULL | Usuario que gestiona | |
| co_estado | Char | 1 | NOT NULL | Estado de la gestión | P: Pendiente<br>C: Cumplido<br>I: Incumplido |

## Transacciones de Servicio

21054, 21154, 21254

## Índices

- cr_cobros_Key
- cr_cobros_idx1
- cr_cobros_idx2

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
