# ca_operacion

## Descripción

Tabla maestra del módulo de cartera, contiene la información principal de los préstamos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| op_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| op_banco | cuenta | 24 | NOT NULL | Número banco del préstamo |
| op_anterior | cuenta | 24 | NULL | Número banco del préstamo anterior si fue renovación |
| op_migrada | cuenta | 24 | NULL | Número banco del préstamo, información de la migración |
| op_tramite | int | 4 | NULL | Número del trámite asignado |
| op_cliente | int | 4 | NULL | Código MIS del cliente principal del préstamo |
| op_nombre | descripcion | 160 | NULL | Nombre del cliente. |
| op_sector | catalogo | 10 | NOT NULL | Sector del préstamo, (catalogo cr_clase_cartera). |
| op_toperacion | catalogo | 10 | NOT NULL | Tipo de producto de cartera |
| op_oficina | smallint | 2 | NOT NULL | Oficina donde fue dado de alta el préstamo |
| op_moneda | tinyint | 1 | NOT NULL | Moneda del préstamo |
| op_comentario | varchar | 255 | NULL | Cambio de observación para comentarios |
| op_oficial | smallint | 2 | NOT NULL | Código del oficial responsable del préstamo. |
| op_fecha_ini | datetime | 8 | NOT NULL | Fecha de inicio del préstamo. |
| op_fecha_fin | datetime | 8 | NOT NULL | Fecha fin del préstamo |
| op_fecha_ult_proceso | datetime | 8 | NOT NULL | Fecha que indica la última fecha que fue procesado el préstamo en los procesos batch |
| op_fecha_liq | datetime | 8 | NULL | Fecha de la liquidación/desembolso del préstamo |
| op_fecha_reajuste | datetime | 8 | NULL | Fecha del próximo reajuste de intereses |
| op_monto | money | 8 | NOT NULL | Monto solicitado. |
| op_monto_aprobado | money | 8 | NOT NULL | Monto aprobado para ser desembolsado. |
| op_destino | catalogo | 10 | NOT NULL | Catalogo que indica cual es el destino del préstamo |
| op_lin_credito | cuenta | 24 | NULL | Código banco de la línea de crédito, indica si el préstamo está asociado a una línea/cupo. |
| op_ciudad | int | 4 | NOT NULL | Código de la ciudad donde se ha ingresado el préstamo |
| op_estado | tinyint | 1 | NOT NULL | Catalogo que indica el estado actual del préstamo<br><br>0 = NO VIGENTE<br><br>1 = VIGENTE<br><br>2 = VENCIDO<br><br>3 = CANCELADO<br><br>4 = CASTIGADO<br><br>5 = JUDICIAL<br><br>6 = ANULADO<br><br>7 = CONDONADO<br><br>8 = DIFERIDO<br><br>9 = SUSPENSO<br><br>99 = EN CREDITO<br><br>66 = GRUPAL VIGENTE |
| op_periodo_reajuste | smallint | 2 | NULL | Cada cuantos periodos reajusta |
| op_reajuste_especial | char | 1 | NULL | Si posee reajuste especial<br><br>S = SI<br><br>N = NO |
| op_tipo | char | 1 | NOT NULL | Clase del préstamo<br><br>N = PRESTAMO DE CARTERA<br><br>L = LEASING<br><br>D = DESCUENTO DOCUMENTO<br><br>P = PRESTAMO INTERESES PREPAGADOS<br><br>R = PRESTAMO PASIVO<br><br>(Campo se usa con valor por defecto: N, el resto de clases no se usa en la versión). |
| op_forma_pago | catalogo | 10 | NULL | Catalogo que indica como cancela el cliente las cuotas.<br><br>Valores posibles:<br><br>NULL, No se utiliza en la versión.<br><br>'C' => si al aplicar la forma de pago automática el valor lo aplica por cuota.<br><br>'R' => si al aplicar la forma de pago automática el valor lo aplica por rubro. Es decir en la forma de pago automática solo aplica al rubro definido.<br><br>'M' => si al aplicar la forma de pago automática el valor lo aplica por monto. |
| op_cuenta | cuenta | 24 | NULL | Si es debito en cuenta indica este campo el número de la cuenta |
| op_dias_anio | smallint | 2 | NOT NULL | Días para cálculo de intereses:<br><br>360, 365, 366 |
| op_tipo_amortizacion | varchar | 10 | NOT NULL | Tipo de tabla de amortización entre FRANCESA, ALEMANA, MANUAL. |
| op_cuota_completa | char | 1 | NOT NULL | Si paga cuota completa o no<br><br>S = SI<br><br>N = NO |
| op_tipo_cobro | char | 1 | NOT NULL | Si paga intereses acumulados o proyectados<br><br>A =Paga acumulados<br><br>P =Paga proyectados |
| op_tipo_reduccion | char | 1 | NOT NULL | Si paga cuotas adelantadas que tipo de reducción aplica<br><br>C = Reducción de monto de cuota<br><br>T = Reducción de tiempo<br><br>N = No aplica reducción |
| op_aceptar_anticipos | char | 1 | NOT NULL | Si acepta pagos anticipados<br><br>S = SI<br><br>N =NO |
| op_precancelacion | char | 1 | NOT NULL | Si el préstamo permite precancelación<br><br>S = SI<br><br>N =NO |
| op_tipo_aplicacion | char | 1 | NOT NULL | Tipo de aplicación:<br><br>D = Aplica por dividendo<br><br>C = Aplica por concepto |
| op_tplazo | catalogo | 10 | NULL | Tipo de plazo<br><br>M = mensual<br><br>A = anual<br><br>S = semestral<br><br>T = trimestral<br><br>B = bimestral<br><br>Q = quincenal<br><br>W = semanal<br><br>D = diario |
| op_plazo | smallint | 2 | NULL | Plazo dado de acuerdo al tipo de plazo |
| op_tdividendo | catalogo | 10 | NULL | Tipo de cuota<br><br>Tipo de plazo<br><br>M = Mensual<br><br>A = anual<br><br>………………….. |
| op_periodo_cap | smallint | 2 | NULL | Cada cuantas cuotas paga capital |
| op_periodo_int | smallint | 2 | NULL | Cada cuantas cuotas paga interés |
| op_dist_gracia | char | 1 | NULL | Si tiene distribución de gracia<br><br>S = SI<br><br>N =NO |
| op_gracia_cap | smallint | 2 | NULL | Si tiene gracia de capital<br><br>S = SI<br><br>N =NO |
| op_gracia_int | smallint | 2 | NULL | Si tiene gracia de interés<br><br>S = SI<br><br>N =NO |
| op_dia_fijo | tinyint | 1 | NULL | Si paga en día fijo almacena el número del día del mes |
| op_cuota | money | 8 | NULL | Monto de la cuota pactada. |
| op_evitar_feriados | char | 1 | NULL | Si las cuotas ha sido generadas evitando los días feriados<br><br>S = SI<br><br>N =NO |
| op_num_renovacion | tinyint | 1 | NULL | Indica el número de renovaciones que ha tenido el préstamo |
| op_renovacion | char | 1 | NULL | Indica si permite renovación<br><br>S = SI<br><br>N =NO |
| op_mes_gracia | tinyint | 1 | NOT NULL | Indica el número del mes de gracia, en este mes no se pone a disposición el cobro de cuota |
| op_reajustable | char | 1 | NOT NULL | Indica si el préstamo es reajustable de intereses<br><br>S = SI<br><br>N =NO<br><br>F = FLOTANTE |
| op_dias_clausula | int | 4 | NOT NULL | Contiene el valor de scoring que se asigna a la operación mediante el proceso Batch de carga de scoring interno |
| op_divcap_original | smallint | 2 | NULL | Dividendo del capital original. No se utiliza en esta versión, valor por defecto NULL. |
| op_clausula_aplicada | char | 1 | NULL | Indica si tiene clausula a aplicar (S/N). No se utiliza en esta versión, valor por defecto = 'N'. |
| op_traslado_ingresos | char | 1 | NULL | Indica si tiene traslados de ingresos. No se utiliza en esta versión, valor por defecto = 'N'. |
| op_periodo_crecimiento | smallint | 2 | NULL | No se utiliza en esta versión, valor por defecto = 0 (cero). |
| op_tasa_crecimiento | float | 8 | NULL | No se utiliza en esta versión, valor por defecto = 0 (cero). |
| op_direccion | tinyint | 1 | NULL | Código de dirección. No se utiliza en esta versión, valor por defecto = NULL. |
| op_opcion_cap | char | 1 | NULL | Indica si hay tasa para capital. No se utiliza en esta versión, valor por defecto = 'N'. |
| op_tasa_cap | float | 8 | NULL | Contiene la TEA de la operación. |
| op_dividendo_cap | smallint | 2 | NULL | Código del dividendo capital. No se utiliza en esta versión, valor por defecto = 'NULL'. |
| op_clase | catalogo | 10 | NOT NULL | Código de los tipos de clase de cartera (catalogo cr_clase_cartera) |
| op_origen_fondos | catalogo | 10 | NULL | Se hereda desde XSell del catálogo cr_origen_fondo, Valor por defecto: 1 (Fondo propio) |
| op_calificacion | char | 1 | NULL | Calificación del préstamo<br><br>Catálogo cr_calificacion |
| op_estado_cobranza | catalogo | 10 | NULL | Estado de la cobranza. No se utiliza en esta versión, valor por defecto = NULL. |
| op_numero_reest | int | 4 | NOT NULL | Cantidad de reajustes que tiene el préstamo. |
| op_edad | int | 4 | NULL | Edad del préstamo. No se utiliza en esta versión, valor por defecto = 1. |
| op_tipo_crecimiento | char | 1 | NULL | Tipo de crecimiento del préstamo. No se utiliza en esta versión, valor por defecto = "A". |
| op_base_calculo | char | 1 | NULL | Indica el tipo de base de cálculo |
| op_prd_cobis | tinyint | 1 | NULL | (Campo no se usa en la versión. Valor por defecto: 7). Se hereda del campo dt_prd_cobis de la tabla ca_default_toperacion. |
| op_ref_exterior | cuenta | 24 | NULL | Referencia del préstamo del exterior. No se utiliza en esta versión, valor por defecto = NULL. |
| op_sujeta_nego | char | 1 | NULL | Indica si esta sujeta a negociación (S/N). No se utiliza en esta versión, valor por defecto = 'N'. |
| op_dia_habil | char | 1 | NULL | Trabaja en conjunto con el campo op_evitar_feriados. Establece como fecha de vencimiento al último día hábil antes del feriado si su valor es S, caso contrario establece como fecha de vencimiento al primer día hábil después del feriado. Se hereda del campo dt_dia_habil de la tabla ca_default_toperacion. |
| op_recalcular_plazo | char | 1 | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_recalcular_plazo de la tabla ca_default_toperacion. |
| op_usar_tequivalente | char | 1 | NULL | Indica si se puede usar tasa equivalente. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_usar_tequivalente de la tabla ca_default_toperacion |
| op_fondos_propios | char | 1 | NOT NULL | Indica si tiene fondos propios |
| op_nro_red | varchar | 24 | NULL | Indica el número de red. No se utiliza en esta versión, valor por defecto = NULL. |
| op_tipo_redondeo | tinyint | 1 | NULL | Se hereda del campo dt_tipo_redondeo de la tabla ca_default_toperacion. No se utiliza en esta versión, valor por defecto = NULL. |
| op_sal_pro_pon | money | 8 | NULL | Valor del saldo. (No se usa en esta versión)<br><br>valor por defecto = NULL. |
| op_tipo_empresa | catalogo | 10 | NULL | Código de tipo de empresa<br><br>Se utiliza el catálogo ca_tipo_empresa. No se utiliza en esta versión, valor por defecto = NULL. |
| op_validacion | catalogo | 10 | NULL | Código de tipo de validación<br><br>Se relaciona con el catálogo ca_validacion<br><br>COLUMNA EN DESUSO |
| op_fecha_pri_cuot | datetime | 8 | NULL | Fecha de vencimiento de primera cuota. |
| op_gar_admisible | char | 1 | NULL | Indica si admite o no garantías. No se utiliza en esta versión |
| op_causacion | char | 1 | NULL | Se lo usa en el cálculo diario de interés para la fórmula lineal o exponencial. Se hereda del campo dt_causacion de la tabla ca_default_toperacion. Valores posibles:<br><br>L = Lineal<br><br>E = Exponencial<br><br>Valor por defecto: L |
| op_convierte_tasa | char | 1 | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_convertir_tasa de la tabla ca_default_toperacion. |
| op_grupo_fact | int | 4 | NULL | Código del grupo de facturación. No se utiliza en esta versión, valor por defecto = NULL. |
| op_tramite_ficticio | int | 4 | NULL | Código del tramite ficticio. No se utiliza en esta versión, valor por defecto = NULL. |
| op_tipo_linea | catalogo | 10 | NULL | Código del tipo de línea (ca_tipo_linea). (Campo no se usa en la versión. Valor por defecto: '999'). Se hereda del campo dt_tipo_linea de la tabla ca_default_toperacion |
| op_subtipo_linea | catalogo | 10 | NULL | Catalogo Programa de Credito (ca_subtipo_linea)<br><br>01 = Quirografarias<br><br>02 = Prendarias<br><br>03 = Factoraje<br><br>04 = Arrendamiento Capitalizable<br><br>05 = Microcréditos<br><br>06 = Otros<br><br>07 = Liquidez a otras Cooperativas<br><br>99 = N/A<br><br>**(Campo no se usa en esta versión. Valor por defecto: '05').** Se hereda del campo dt_subtipo_linea de la tabla ca_default_toperacion. |
| op_bvirtual | char | 1 | NULL | Indica si se puede ver en medios virtuales. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_bvirtual de la tabla ca_default_toperacion. |
| op_extracto | char | 1 | NULL | Indica si se pueden generar extractos. (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_extracto de la tabla ca_default_toperacion. |
| op_num_deuda_ext | cuenta | 24 | NULL | Código de número de deuda externa (banco segundo piso). No se utiliza en esta versión, valor por defecto = NULL. |
| op_fecha_embarque | datetime | 8 | NULL | Fecha de embarque<br><br>COLUMNA EN DESUSO. No se utiliza en esta versión, valor por defecto = NULL. |
| op_fecha_dex | datetime | 8 | NULL | Fecha DEX<br><br>COLUMNA EN DESUSO. No se utiliza en esta versión, valor por defecto = NULL. |
| op_reestructuracion | char | 1 | NULL | Indica si hubo reestructuración |
| op_tipo_cambio | char | 1 | NULL | Indica si hubo tipo de cambio. No se utiliza en esta versión, valor por defecto = NULL. |
| op_naturaleza | char | 1 | NULL | Indica la naturaleza de la operación.<br><br>A = Activa<br><br>P = Pasiva<br><br>En esta versión valor por defecto 'A' |
| op_pago_caja | char | 1 | NULL | Indica si se puede realizar pagos por caja. Se hereda del campo dt_pago_caja de la tabla ca_default_toperacion. |
| op_nace_vencida | char | 1 | NULL | Iguala la fecha de vencimiento a la fecha de inicio de los dividendos y de la operación. (Campo no se usa en esta versión. Valor por defecto: N). Se hereda del campo dt_nace_vencida de la tabla ca_default_toperacion |
| op_num_comex | cuenta | 24 | NULL | Código de la operación de comercio exterior. No se utiliza en esta versión, valor por defecto = NULL. |
| op_calcula_devolucion | char | 1 | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_calcula_devolucion de la tabla ca_default_toperacion |
| op_codigo_externo | cuenta | 24 | NULL | Código externo banco segundo piso. No se utiliza en esta versión, valor por defecto = NULL. |
| op_margen_redescuento | float | 8 | NULL | Valor del margen de redescuento. No se utiliza en esta versión, valor por defecto = NULL. |
| op_entidad_convenio | catalogo | 10 | NULL | Código de la entidad convenio. (Campo no se usa en la versión). Se hereda del campo dt_entidad_convenio de la tabla ca_default_toperacion. No se utiliza en esta versión, valor por defecto = NULL |
| op_pproductor | char | 1 | NULL | Indica si el préstamo es de un productor. No se utiliza en esta versión, valor por defecto = NULL. |
| op_fecha_ult_causacion | datetime | 8 | NULL | Fecha de ultima causación . No se utiliza en esta versión, valor por defecto = NULL. |
| op_mora_retroactiva | char | 1 | NULL | Posibles valores S, N. Si está en S, genera gracia de mora automática cuando el vencimiento del dividendo cae en fin de semana o feriado. Valor por defecto: N. Se hereda del campo dt_mora_retroactiva de la tabla ca_default_toperacion. |
| op_calificacion_ant | char | 1 | NULL | Indica la calificación anterior |
| op_cap_susxcor | money | 8 | NULL | Valor de la capitalización suspendida. <br><br>COLUMNA EN DESUSO |
| op_prepago_desde_lavigente | char | 1 | NULL | (Campo no se usa en la versión. Valor por defecto: N). Se hereda del campo dt_prepago_desde_lavigente de la tabla ca_default_toperacion |
| op_fecha_ult_mov | datetime | 8 | NULL | Fecha en que el prestamo recibio su ultimo pago (cancelacion) |
| op_fecha_prox_segven | datetime | 8 | NULL | Fecha de próximo vencimiento de seguro<br><br>COLUMNA EN DESUSO |
| op_suspendio | char | 1 | NULL | Indica si fue suspendida.<br><br>COLUMNA EN DESUSO |
| op_fecha_suspenso | datetime | 8 | NULL | Fecha de suspenso <br><br>COLUMNA EN DESUSO |
| op_honorarios_cobranza | char | 1 | NULL | Indica si hay honorarios por cobranza <br><br>COLUMNA EN DESUSO |
| op_banca | catalogo | 10 | NULL | Códito de la banca <br><br>COLUMNA EN DESUSO |
| op_promocion | char | 1 | NULL | Indica si hay promoción <br><br>COLUMNA EN DESUSO |
| op_acepta_ren | char | 1 | NULL | Indica si hay aceptación de renovación |
| op_no_acepta | varchar | 1000 | NULL | Comentario porque no acepta <br><br>COLUMNA EN DESUSO |
| op_emprendimiento | char | 1 | NULL | Código de emprendimiento.<br><br>COLUMNA EN DESUSO |
| op_valor_cat | float | 8 | NULL | Contiene la TIR de la operación. |
| op_grupo | int | 4 | NULL | Código de Grupo al que pertenece el préstamo. |
| op_ref_grupal | cuenta | 24 | NULL | Número largo de banco padre al que pertenecen las operacines hijas. |
| op_grupal | char | 1 | NULL | Indica si pertenece a un grupo |
| op_fondeador | tinyint | 1 | NULL | Código del fondeador <br><br>COLUMNA EN DESUSO |
| op_admin_individual | char | 1 | NULL | Tipo de administración de operaciones grupales que contiene la definición al momento de crear la operación de si el tipo de préstamo grupal se administra por la operación padre o por las operaciones hijas.<br><br>S = Admin operación hija<br><br>N = Admin operación padre |
| op_estado_hijas | char | 1 | NULL | Indica el estado de las operaciones hijas asociadas a una operación grupal. Aplica solo a la operación padre, I=Ingresadas, P=Procesadas. |
| op_tipo_renovacion | char | 1 | NULL | Si la operación fue Renovada o Refinanciada. Catalogo "ca_tipo_renovacion".<br><br>R: Renovacion<br><br>F: Refinanciamiento |
| op_tipo_reest | char | 1 | NULL | Tipos de reestructuacion /modificación de la operación.<br><br>"N"= CAP<br><br>"S" = CAP e INT<br><br>"T" = TODO |
| op_fecha_reest | datetime | 8 | NULL | Fecha cuando se aplico modificación de la operación de tipo reestructuración. |
| op_fecha_reest_noestandar | datetime | 8 | NULL | Fecha cuando se aplico modificación de la operación de tipo diferimiento u otro.<br><br>COLUMNA EN DESUSO |

## Índices

- **ca_operacion_1** (UNIQUE NONCLUSTERED INDEX): op_operacion
- **ca_operacion_2** (NONCLUSTERED INDEX): op_migrada
- **ca_operacion_3** (NONCLUSTERED INDEX): op_tramite
- **ca_operacion_4** (NONCLUSTERED INDEX): op_cliente
- **ca_operacion_5** (NONCLUSTERED INDEX): op_oficial
- **ca_operacion_6** (NONCLUSTERED INDEX): op_oficina
- **ca_operacion_7** (NONCLUSTERED INDEX): op_banco
- **ca_operacion_8** (NONCLUSTERED INDEX): op_lin_credito
- **ca_operacion_9** (NONCLUSTERED INDEX): op_estado, op_fecha_liq, op_tramite, op_oficial
- **ca_operacion_10** (NONCLUSTERED INDEX): op_oficial, op_tramite, op_cliente, op_estado
- **ca_operacion_idx11** (NONCLUSTERED INDEX): op_naturaleza, op_fecha_ult_proceso, op_cuenta, op_operacion, op_estado, op_forma_pago

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
