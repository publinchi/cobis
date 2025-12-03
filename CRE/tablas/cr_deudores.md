# cr_deudores

## Descripción

Registro de deudores y codeudores de trámites.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| de_tramite | Int | 4 | NOT NULL | Número de trámite | |
| de_cliente | Int | 4 | NOT NULL | Código de cliente | |
| de_rol | Catalogo | 10 | NOT NULL | Rol del cliente en el trámite: deudor, codeudor | D: deudor<br>C: codeudor<br>G: grupo |
| de_ced_ruc | Varchar | 30 | NULL | Identificación del cliente | |
| de_segvida | Char | 1 | NULL | No aplica en esta versión | |
| de_cobro_cen | Char | 1 | NOT NULL | No aplica en esta versión | |

## Transacciones de Servicio

21013, 21113, 21213, 21313, 21413, 21513, 21613

## Índices

- cr_deudores_1
- cr_deudores_Key

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
