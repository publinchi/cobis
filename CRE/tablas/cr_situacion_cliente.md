# cr_situacion_cliente

## Descripción

Almacena información sobre la situación financiera del cliente al momento de la solicitud de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sc_tramite | Int | 4 | NOT NULL | Número de trámite | |
| sc_ente | Int | 4 | NOT NULL | Código de cliente | |
| sc_activo_corriente | Money | 8 | NULL | Activo corriente del cliente | |
| sc_activo_fijo | Money | 8 | NULL | Activo fijo del cliente | |
| sc_otros_activos | Money | 8 | NULL | Otros activos | |
| sc_total_activos | Money | 8 | NULL | Total de activos | |
| sc_pasivo_corriente | Money | 8 | NULL | Pasivo corriente | |
| sc_pasivo_largo_plazo | Money | 8 | NULL | Pasivo a largo plazo | |
| sc_otros_pasivos | Money | 8 | NULL | Otros pasivos | |
| sc_total_pasivos | Money | 8 | NULL | Total de pasivos | |
| sc_patrimonio | Money | 8 | NULL | Patrimonio del cliente | |
| sc_ingresos_mensuales | Money | 8 | NULL | Ingresos mensuales | |
| sc_egresos_mensuales | Money | 8 | NULL | Egresos mensuales | |
| sc_capacidad_pago | Money | 8 | NULL | Capacidad de pago calculada | |

## Transacciones de Servicio

21036, 21136, 21236

## Índices

- cr_situacion_cliente_Key
- cr_situacion_cliente_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
