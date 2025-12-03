# cr_tramite_grupal

## Descripción

Guarda la relación entre el trámite grupal y los trámites hijos.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tg_tramite | int | | NOT NULL | Número de solicitud de crédito grupal | |
| tg_grupo | int | | NOT NULL | Código del grupo | |
| tg_cliente | int | | NOT NULL | Código del cliente | |
| tg_monto | money | | NOT NULL | Monto aprobado para el integrante. | |
| tg_grupal | char(1) | 1 | NOT NULL | Es un trámite grupal | Siempre en S |
| tg_operacion | int | | NULL | Secuencial de la operación de cartera | |
| tg_prestamo | varchar(15) | 15 | NULL | Número largo de la operación de cartera. | |
| tg_referencia_grupal | varchar(15) | 15 | NULL | Número largo de la operación grupal. | |
| tg_cuenta | varchar(45) | 45 | NULL | Número de la cuenta de ahorros del cliente. No aplica | |
| tg_cheque | int | | NULL | No aplica en esta versión | |
| tg_participa_ciclo | char(1) | 1 | NULL | Indica que el integrante participa en la solicitud grupal. | S: SI participa<br>N: NO participa |
| tg_monto_aprobado | money | | NULL | Monto solicitado por el integrante | |
| tg_ahorro | money | | NULL | No aplica en esta versión. | |
| tg_monto_max | money | | NULL | No aplica en esta versión. | |
| tg_bc_ln | char(10) | 10 | NULL | No aplica en esta versión. | |
| tg_incremento | numeric(8,4) | 8 | NULL | No aplica en esta versión. | |
| tg_monto_ult_op | money | | NULL | No aplica en esta versión. | |
| tg_monto_max_calc | money | | NULL | No aplica en esta versión. | |
| tg_nueva_op | int | | NULL | No aplica en esta versión. | |
| tg_monto_min_calc | money | | NULL | No aplica en esta versión. | |
| tg_conf_grupal | char(1) | 1 | NULL | No aplica en esta versión. | |
| tg_destino | catalogo | | NULL | Código del destino de la operación. | (cl_subactividad_ec) |
| tg_sector | catalogo | | NULL | Código del sector de la operación | |
| tg_monto_recomendado | money | | NULL | Monto recomendado | |
| tg_estado | char(1) | | S | Estado de la operación hija | |
| tg_id_rechazo | catalogo | | NULL | Causa de rechazo de la operación del integrante. | (cr_motivo_rechazo) |
| tg_descripcion_rechazo | descripcion | | NULL | Descripción de la causa de rechazo de la operación del integrante. | |

## Transacciones de Servicio

21846, 21847, 21848

## Índices

- idx1
- idx2
- idx3

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
