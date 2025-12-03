# cr_gar_propuesta

## Descripción

Tabla que almacena las garantías que están asociadas a un trámite de crédito y en fin último a una operación de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| gp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| gp_garantia | Varchar | 64 | NOT NULL | Código compuesto de garantía | Es el número largo de la garantía, la información de la garantía está en la cob_custodia..cu_custodia (cu_codigo_externo) |
| gp_abierta | Char | 1 | NOT NULL | Característica de garantía | A= Abierta<br>C= Cerrada |
| gp_deudor | Int | 4 | NOT NULL | Código de cliente del deudor | |
| gp_est_garantia | Char | 1 | NOT NULL | Estado de la garantía | (cu_est_custodia) |
| gp_porcentaje | Float | 8 | NOT NUL | Porcentaje de cobertura de la garantía | |
| gp_valor_resp_garantia | Money | 8 | NOT NUL | Valor de la operación que respalda la garantía | |
| gp_saldo_cap_op | Money | 8 | NUL | Saldo de capital de la operación | No aplica en esta versión |
| gp_prendado | Money | 8 | NUL | Valor prendado de la garantía | No aplica en esta versión |

## Transacciones de Servicio

21028, 21128, 21228, 21428, 21528

## Índices

- cr_gar_propuesta_Key
- i_cr_gar_propuesta_i2
- i_cr_gar_propuesta_i3

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
