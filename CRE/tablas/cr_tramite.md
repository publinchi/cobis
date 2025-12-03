# cr_tramite

## Descripción

Mantenimiento de trámites o solicitudes de crédito ingresados en el módulo de crédito, contiene toda la información del trámite, es la tabla maestra del módulo.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tr_tramite | Int | 4 | NOT NULL | Número de trámite | &nbsp; |
| tr_tipo | Char | 1 | NOT NULL | Tipo de trámite | O: original individual o grupal<br>L: linea<br>G: modificatorio garantía<br>E: reestructuración<br>R: refinanciamiento, renovación |
| tr_oficina | Smallint | 2 | NOT NULL | Código de oficina | &nbsp;(cl_oficina) |
| tr_usuario | Varchar | 14 | NOT NULL | Login de usuario de ingreso de trámite | &nbsp;(cl_funcionario)\*\* |
| tr_fecha_crea | Datetime | 8 | NOT NULL | Fecha de creación de registro | &nbsp; |
| tr_oficial | Smallint | 2 | NOT NULL | Código de oficial del cliente | &nbsp; |
| tr_sector | Varchar | 10 | NOT NULL | Catálogo de sector | &nbsp;(cc_sector) |
| tr_ciudad | Int | 4 | NOT NULL | Código de ciudad | &nbsp;(cl_ciudad) |
| tr_estado | Char | 1 | NOT NULL | Estado de trámite | A - Aprobado<br>N - No Aprobado<br>Z - Cancelado |
| tr_nivel_ap | tinyint | &nbsp; | &nbsp;NULL | &nbsp;No se usa | &nbsp; |
| tr_fecha_apr | Datetime | &nbsp; | &nbsp;NULL | &nbsp;Fecha aprobación solicitud | &nbsp; |
| tr_usuario_apr | login | &nbsp; | &nbsp;NULL | &nbsp;Usuario que aprueba | &nbsp;(cl_funcionario)\*\* |
| tr_numero_op | Int | 4 | NULL | Código numérico secuencial de operación generada por el trámite | &nbsp; |
| tr_numero_op_banco | Varchar | 24 | NULL | Código de operación generada por cartera en el desembolso | &nbsp; |
| tr_riesgo | money | 8 | NULL | No se usa en esta versión | &nbsp; |
| tr_aprob_por | login | 14 | NULL | No se usa en esta versión | &nbsp; |
| tr_nivel_por | tinyint | 1 | NULL | No se usa en esta versión | &nbsp; |
| tr_comite | catalogo | 10 | NULL | No se usa en esta versión | &nbsp; |
| tr_acta | cuenta | 24 | NULL | &nbsp;No se usa en esta versión | &nbsp; |
| tr_proposito | Varchar | 10 | NULL | No se usa en esta versión | &nbsp; |
| tr_razon | Varchar | 10 | NULL | Razón del modificatorio de garantía | &nbsp; |
| tr_txt_razon | Varchar | 255 | NULL | Razón del modificatorio de garantía | &nbsp; |
| tr_efecto | Varchar | 10 | NULL | No se usa en esta versión | &nbsp; |
| tr_cliente | Int | 4 | NULL | Código de cliente deudor del trámite | &nbsp; |
| tr_nombre | &nbsp; | 64 | NULL | &nbsp;No se usa en esta versión | &nbsp; |
| tr_grupo | Int | 4 | NULL | Código de grupo del trámite | &nbsp; |
| tr_fecha_inicio | Datetime | 8 | NULL | Fecha de inicio de la solicitud | &nbsp; |
| tr_num_dias | Smallint | 2 | NULL | Plazo en número de días para líneas de crédito | &nbsp; |
| tr_per_revision | Varchar | 10 | NULL | No se usa en esta versión. | &nbsp; |
| tr_condicion_especial | Varchar | 255 | NULL | No se usa en esta versión. | &nbsp; |
| tr_linea_credito | Int | 4 | NULL | Código numérico de línea de crédito cuando se instrumenta | &nbsp; |
| tr_toperacion | Varchar | 10 | NULL | Código de tipo de operación | &nbsp; |
| tr_producto | Varchar | 10 | NULL | Código de producto. | &nbsp;CCA: Cartera<br>CEX: comercio exterior |
| tr_monto | Money | 8 | NULL | Monto de trámite | &nbsp;Monto aprobado de la solicitud |
| tr_moneda | Tinyint | 1 | NULL | Código de moneda | &nbsp;Moneda de la solicitud (cl_moneda)\*\* |
| tr_periodo | Varchar | 10 | NULL | Código de período | &nbsp;(ca_tdividendo) |
| tr_num_periodos | Smallint | 2 | NULL | Número de períodos | &nbsp; |
| tr_destino | Varchar | 10 | NULL | Código de destino | &nbsp;(cr_objeto) |
| tr_ciudad_destino | Int | 4 | NULL | Código de ciudad destino del préstamo | &nbsp;(cl_ciudad) |
| tr_cuenta_corriente | &nbsp;cuenta | &nbsp; | NULL | No aplica en esta versión | &nbsp; |
| tr_renovacion | Smallint | 2 | NULL | Número de renovación | &nbsp; |
| tr_fecha_concesion | Datetime | 8 | NULL | Fecha de concesión del préstamo | &nbsp; |
| tr_rent_actual | float | 8 | NULL | No aplica en esta versión | &nbsp; |
| tr_rent_solicitud | float | 8 | NULL | No aplica en esta versión | &nbsp; |
| tr_rent_recomend | float | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_prod_actual | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_prod_solicitud | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_prod_recomend | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_clase | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_admisible | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_noadmis | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_relacionado | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_pondera | float | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_contabilizado | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_subtipo | Char | 1 | NULL | Subtipo de línea para el tipo de trámite línea de crédito | &nbsp; |
| tr_tipo_producto | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_origen_bienes | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_localizacion | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_plan_inversion | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_naturaleza | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_tipo_financia | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_sobrepasa | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_elegible | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_forward | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_emp_emisora | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_num_acciones | smallint | 2 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_responsable | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_negocio | cuenta | 24 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_reestructuracion | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_concepto_credito | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_aprob_gar | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_cont_admisible | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_mercado_objetivo | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_tipo_productor | varchar | 24 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_valor_proyecto | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_sindicado | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_asociativo | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_margen_redescuento | float | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_ap_ant | datetime | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_llave_redes | cuenta | 24 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_incentivo | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_eleg | datetime | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_op_redescuento | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_redes | datetime | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_solicitud | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_montop | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_monto_desembolsop | money | 8 | NULL | &nbsp;Monto desembolsado | &nbsp; |
| tr_mercado | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_dias_vig | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_cod_actividad | catalogo | 10 | NULL | &nbsp;Actividad a la que se destina el crédito | &nbsp; |
| tr_num_desemb | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_carta_apr | varchar | 64 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_aprov | datetime | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fmax_redes | datetime | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_f_prorroga | datetime | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_nlegal_fi | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fechlimcum | datetime | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_validado | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_sujcred | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fabrica | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_callcenter | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_apr_fabrica | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_monto_solicitado | Money | 5 | NULL | Monto solicitado por el cliente | &nbsp; |
| tr_tipo_plazo | catalogo | 10 | NULL | &nbsp;Tipo de dividendo | &nbsp; |
| tr_tipo_cuota | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_plazo | Smallint | 2 | NULL | Plazo del trámite | &nbsp; |
| tr_cuota_aproximada | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fuente_recurso | varchar | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_tipo_credito | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_migrado | varchar | 16 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_estado_cont | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_fija | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_dia_pago | tinyint | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_tasa_reest | float | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_motivo | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_central | varchar | 2 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_devuelto_mir | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_campana | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_alianza | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_autoriza_central | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_act_financiar | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_negado_mir | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_num_devri | int | 4 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_promocion | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_acepta_ren | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_no_acepta | char | 1000 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_emprendimiento | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_porc_garantia | float | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_grupal | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_experiencia | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_monto_max | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_monto_min | money | 8 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_dispersion | datetime | 8 | NULL | Fecha desembolso | &nbsp; |
| tr_causa | char | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_fecha_irenova | datetime | 8 | NULL | Fecha de trámite | &nbsp; |
| tr_linea_cancelar | Int | 4 | NULL | Código numérico de línea a cancelar cuando es renovación. No aplica | &nbsp; |
| tr_tasa_asociada | Char | 1 | NULL | No aplica en esta versión | S= Tiene tasa asociada<br>N= No tiene tasa asociada |
| tr_frec_pago | Varchar | 10 | NULL | Frecuencia de Pago | &nbsp; (ca_tdividendo) |
| tr_moneda_solicitada | Tinyint | 1 | NULL | Moneda solicitada por el cliente | &nbsp;(cl_moneda) |
| tr_provincia | Int | 4 | NULL | Provincia donde se genera el trámite | &nbsp;(cl_provincia) |
| tr_monto_desembolso | Money | 5 | NULL | Monto a desembolsar | &nbsp; |
| tr_tplazo | Varchar | 10 | NULL | &nbsp;Tipo de plazo operación | &nbsp; |
| tr_cuota | Money | 5 | NULL | Cuota | &nbsp; |
| tr_proposito_op | Varchar | 10 | NULL | Catálogo de propósito de operación | &nbsp; |
| tr_lin_comext | Varchar | 24 | NULL | Código compuesto de la ínea de las operaciones de COMEXT. No aplica | &nbsp; |
| tr_expromision | Varchar | 10 | NULL | Determina si el proceso es expromisión. No aplica | &nbsp; |
| tr_origen_fondos | Varchar | 10 | NULL | Catálogo de origen de fondos | &nbsp;(cr_origen_fondo) |
| tr_sector_cli | Varchar | 10 | NULL | No aplica en esta versión | &nbsp; |
| tr_truta | tinyint | 1 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_secuencia | smallint | 2 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_sector_contable | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |
| tr_enterado | catalogo | 10 | NULL | &nbsp;Catálogo de como se enteró de Finca | &nbsp;(cl_enterado) |
| tr_otros | varchar | 64 | NULL | &nbsp;Descripción de campo otros, sirve para describir en que se usará el dinero. | &nbsp; |
| tr_periodicidad_lcr | catalogo | 10 | NULL | &nbsp;No aplica en esta versión | &nbsp; |

## Transacciones de Servicio

21020, 21120, 21220, 21520

## Índices

- cr_tramite_AKey
- cr_tramite_AKey2
- cr_tramite_AKey4
- cr_tramite_AKey5
- cr_tramite_AKey6
- cr_tramite_AKey7
- cr_tramite_AKey8
- cr_tramite_Key
- cr_tramite_idx10
- cr_tramite_idx11
- cr_tramite_tr_op_redescuento

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
