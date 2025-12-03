# cr_linea

## Descripción

Mantenimiento de líneas de crédito y sus características operativas.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| li_numero | Int | 4 | NOT NULL | Código numérico de línea de crédito | |
| li_num_banco | cuenta | 24 | NOT NULL | Código compuesto de línea de crédito, se actualiza cuando instrumento la línea. | |
| li_oficina | Smallint | 2 | NOT NULL | Código de oficina | (cl_oficina) |
| li_tramite | Int | 4 | NOT NULL | Número de trámite | |
| li_cliente | Int | 4 | NULL | Código de cliente | (cl_ente)\*\* |
| li_grupo | Int | 4 | NULL | Código de grupo. No aplica | |
| li_original | Int | 4 | NULL | Código de línea original si es una renovación. No aplica | |
| li_fecha_aprob | Datetime | 8 | NULL | Fecha de aprobación de la línea | |
| li_fecha_inicio | Datetime | 8 | NOT NULL | Fecha de inicio de vigencia de la línea | |
| li_per_revision | catalogo | 10 | NULL | Período de revisión de la línea. No aplica | |
| li_fecha_vto | Datetime | 8 | NULL | Fecha de vencimiento | |
| li_dias | Smallint | 2 | NULL | Plazo de la línea en días | |
| li_condicion_especial | Varchar | 255 | NULL | Texto de condición especial de línea. No aplica | |
| li_segmento | catalogo | 10 | NULL | Segmento de la línea. No aplica | |
| li_ult_rev | Datetime | 8 | NULL | Fecha de última revisión de la línea. No aplica | |
| li_prox_rev | datetime | 8 | NULL | Fecha de próxima revisión. No aplica | |
| li_usuario_rev | login | 14 | NULL | Usuario de última revisión. No aplica | |
| li_monto | Money | 8 | NOT NULL | Monto de línea | |
| li_moneda | Tinyint | 1 | NOT NULL | Código de moneda | (cl_moneda)\*\* |
| li_utilizado | Money | 8 | NULL | Monto utilizado | |
| li_rotativa | Char | 1 | NOT NULL | Característica de la línea | S= Rotativa<br>N= No rotativa |
| li_clase | Catalogo | 10 | NULL | No se usa en esta versión | |
| li_admisible | Money | | NULL | No se usa en esta versión | |
| li_noadmis | Money | | NULL | No se usa en esta versión | |
| li_estado | Char | 1 | NULL | Estado de la línea | Si está en estado V, se puede usar para hacer desembolsos bajo línea |
| Li_reservado | Money | | NULL | No se usa en esta versión | |
| li_tipo | char | 1 | NULL | No se usa en esta versión | |
| li_usuario_mod | Login | 8 | NULL | No se usa en esta versión | |
| li_fecha_mod | Datetime | | NULL | No se usa en esta versión | |
| li_dias_vig | Int | | NULL | No se usa en esta versión | |
| Li_num_desemb | Int | | NULL | No se usa en esta versión | |
| li_dias_vig_prorroga | Int | | NULL | No se usa en esta versión | |
| li_fech_apro_prorroga | Datetime | | NULL | No se usa en esta versión | |
| li_acta_prorroga | Cuenta | 24 | NULL | No se usa en esta versión | |
| li_usu_prorroga | Login | | NULL | No se usa en esta versión | |
| li_tipo_normal | Char | 1 | NULL | No se usa en esta versión | |
| li_tipo_plazo | Catalogo | 10 | NULL | No se usa en esta versión | |
| li_tipo_cuota | Catalogo | 10 | NULL | No se usa en esta versión | |
| li_cuota_aproximada | Money | | NULL | No se usa en esta versión | |
| li_bloq_manual | Char | 1 | NOT NULL | Solo en N en esta versión | |
| li_tipo_bloq_aut | Char | 1 | NULL | No se usa en esta versión | |
| li_acumulado_prorroga | Smallint | | NULL | No se usa en esta versión | |
| li_naturaleza | Catalogo | 10 | NULL | No se usa en esta versión | |

## Transacciones de Servicio

21026, 21126, 21262, 21426, 21526, 21826

## Índices

- cr_linea_AKey
- cr_linea_BKey
- cr_linea_CKey
- cr_linea_Dkey
- cr_linea_Key
- cr_linea_Key_tr

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
