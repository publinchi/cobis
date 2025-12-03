/************************************************************************/
/*   NOMBRE LOGICO:      sp_cartera_abono                               */
/*   NOMBRE FISICO:      abonoca.sp                                     */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Fabian de la Torre                             */
/*   FECHA DE ESCRITURA: 12 de Febrero 1999                             */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Aplica el abono. Este procedimiento solo puede aplicarse en     */
/*      registros que ya hayan generado registro de pago (RPA).         */
/************************************************************************/
/*                              CAMBIOS                                 */
/*    FECHA          AUTOR              CAMBIOS                         */
/*    JUN-2010       ELcira Pelaez      Manejo Pasivas                  */
/*    JUL-2010       Javier Olmos       Incidencia 7498                 */
/*    NOV-2010       ELcira Pelaez      Diferidos - NR0059              */
/*                                      Depende del NR 128 y 129        */
/*    NOV-2010       ELcira Pelaez      NR-175                          */
/*                                      Cambios sobre la Ver.49         */
/*    MAY-2011       Carlos Hernández	BRA-00212                       */
/*                                      Cambios sobre la ver.79	        */
/*    DIC-2011       Luis Carlos Moreno Pago por reconocimiento RQ 293  */
/*    JUL-2013       Luis Guzmán        Seguros - req. 366              */
/*    NOV-2013       Carlos Avendaño    Variable en linea sp_agotada    */
/*                                      Req. 371                        */
/*    JUL-2014       Luis Carlos Moreno ODS 928 Aceptar pagos a capital */
/*                                      en cuotas vigentes              */
/*    JUL-2014       ELcira Pelaez      NR 392 Tablas Flexibles Bancamia*/
/*    SEP-2014       Luis Carlos Moreno REQ 436 Normalizacion de carter */
/*                                      en cuotas vigentes              */
/*    NOV-2014       Igmar Berganza     Reportes FGA - Req. 397         */
/*    NOV-2014       Luis Carlos Moreno Seguro Empleados (SEGDEUEM)     */
/*                                      RQ 406                          */
/*    NOV-2015       Elcira Pelaez      INC. 0271978 Bancamia           */
/*    AGO-2019       Luis Ponce         Pagos Grupales Te Creemos       */
/*    DIC-2019       Luis Ponce         Cobro Indiv Acumulado,Grupal    */
/*                                      Proyectado                      */
/*    DIC-2019       Luis Ponce         Codigo valor Te Creemos CAP 13  */
/*    FEB-2020       Luis Ponce         Poner excedente de CAP en ultima*/
/*                                      cuota cancelada en Pagos Extraor*/
/*    ABR-2020       Luis Ponce         CDIG Ajustes por migracion Java */
/*    DIC-2020       Patricio Narvaez   Contabilidad provisiones en     */
/*                                      moneda nacional                 */
/*  DIC/22/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*  ENE/21/2021      Luis Ponce         Operaciones Pasivas              */
/*    20/10/2021     G. Fernandez        Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/*    11/04/2021     K. Rodriguez       Bloqueo pago extraor. con reduc.*/
/*                                      de tiempo a créditos con tablas */
/*                                      manuales y abono completo rubros*/
/*    22/04/2022     G. Fernandez     Ingreso de validacion de prestamos*/
/*                                    migrados y tabla de amortizacion  */
/*                                    manual                            */
/*    05/05/2022     G. Fernandez     Actualizacion de manejo de errores*/
/*    01/06/2022     K. Rodriguez     Ajustes condonaciones             */
/*    10/06/2022	 A. Monroy		  Cuando tipo reduccion = N se debe */
/*									  incluir rubros proyectados no vig.*/
/*    08/07/2022     K. Rodriguez     Respetar negociación en apl_concep*/
/*    29/07/2022     K. Rodriguez     Ajustes condonacion               */
/*    10/08/2022     K. Rodriguez     R191162 No cancelar OP por saldos */
/*                                    mínimos                           */
/*    16/08/2022     K. Rodriguez     R191370 Acumular saldo extraordin.*/
/*                                    en cuota vigente 					*/
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*    07/11/2022     K. Rodriguez     R218836 No aplicar pago extraor. a*/
/*                                    préstamo con gracia en divs no vig*/
/*    14/11/2023     K. Rodriguez     R219105 Ajuste abn extraordinario */
/*    06/03/2025     K. Rodriguez     R256950(235424) Optimizaciones    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cartera_abono')
   drop proc sp_cartera_abono
go

create proc sp_cartera_abono
   @s_sesn                    int          = NULL,
   @s_ssn                     int          = null,
   @s_user                    login        = NULL,
   @s_date                    datetime     = NULL,
   @s_ofi                     smallint     = NULL,
   @s_term                    varchar (30) = NULL,
   @s_srv                     varchar (30) = '',
   @s_lsrv                    varchar (30) = null,
   @s_rol                     smallint     = null,          -- PAQUETE 2: REQ 212 - BANCA RURAL - CHE
   @i_secuencial_ing          int,
   @i_operacionca             int,
   @i_fecha_proceso           datetime,
   @i_en_linea                char(1)      = 'S',
   @i_solo_capital            char(1)      = 'N',
   @i_no_cheque               int          = null,
   @i_cuenta                  cuenta       = null,
   @i_dividendo               int          = 0,
   @i_cancela                 char(1)      = 'N',
   @i_renovacion              char(1)      = 'N',
   @i_cotizacion              money,
   @i_por_rubros              char(1)      = 'N',
   @i_pago_ext                char(1)      = 'N',    ---req 0309
   @i_es_norm                 char(1)      = 'N',    ---req 436
   @i_sec_desem_renova        int          = null,
   @i_cuenta_aux               cuenta      = null,
   @i_valor_multa             money        = 0,
   @i_valida_sobrante         char(1)      = 'S',
   @i_simulado                char(1)      = 'N',  --Pago Simulado
   @i_canal_inter	          catalogo     = null,    
   @i_debug					  CHAR(1)	   = 'N', -- AMO 20220610
   @o_msg_matriz              descripcion  = null out   --Req. 300    
AS

DECLARE
   @w_error                   int,
   @w_num_dec_op              int,
   @w_banco                   cuenta,
   @w_operacionca             int,
   @w_monto_mop               money,
   @w_moneda_op               smallint,
   @w_moneda_mn               smallint,
   @w_op_migrada              cuenta,
   @w_oficina_op              int,
   @w_tipo_cobro              char(1),
   @w_tipo_aplicacion         char(1),
   @w_tipo_reduccion          char(1),
   @w_tipo_reduccion_orig     char(1), -- AMO 20220622
   @w_est_vigente             tinyint,
   @w_est_novigente           tinyint,
   @w_est_cancelado           tinyint,
   @w_ab_fecha                datetime,
   @w_toperacion              catalogo,
   @w_sector                  catalogo,
   @w_tipo_linea              catalogo,
   @w_secuencial_pag          int,
   @w_secuencial_rpa          int,
   @w_cotizacion              money,
   @w_tcotizacion             char(1),
   @w_monto_sobrante          float,
   @w_di_dividendo            int,
   @w_dias_anio               smallint,
   @w_base_calculo            char(1),
   @w_aceptar_anticipos       char(1),
   @w_saldo_capital           money,
   @w_fpago                   catalogo,
   @w_cuenta                  cuenta,
   @w_tipo_tabla              catalogo,
   @w_cliente                 int,
   @w_tipo                    char(1),
   @w_tasa_prepago            float,
   @w_div_vigente             int,
   @w_moneda_ab               int,
   @w_monto_gar               money,
   @w_tramite                 int,
   @w_categoria               catalogo,
   @w_fecha_proceso           datetime,
   @w_gerente                 smallint,
   @w_estado                  char(1),
   @w_estado_div              smallint,
   @w_estado_ult_div          smallint,
   @w_agotada                 char(1),
   @w_contabiliza             char(1),
   @w_tipo_gar                varchar(64),
   @w_abierta_cerrada         char(1),
   @w_forma_pago              catalogo,
   @w_monto_mpg               money,
   @w_concepto_int            catalogo,
   @w_int_ant                 catalogo,
   @w_int_fac                 catalogo,
   @w_moneda_local            smallint,
   @w_moneda_pago             smallint,
   @w_grupo                   int,
   @w_num_negocio             varchar(64),
   @w_num_doc                 varchar(16),
   @w_proveedor               int,
   @w_cotizacion_mop          money,
   @w_cancelar                char(1),
   @w_lin_credito             cuenta,
   @w_opcion                  char(1),
   @w_numero_comex            cuenta,
   @w_prod_cobis              int,
   @w_gar_admisible           char(1),
   @w_reestructuracion        char(1),
   @w_calificacion            catalogo,
   @w_num_dec_n               smallint,
   @w_moneda_pag              smallint,
   @w_abd_monto_mn            money,
   @w_abd_monto_mpg           money,
   @w_abd_cotizacion_mpg      money,
   @w_cot_moneda              money,
   @w_nombre                  descripcion,
   @w_abd_cuenta              cuenta,
   @w_cp_afectacion           char(1),
   @w_moneda_uvr              smallint,
   @w_op_estado               tinyint,
   @w_monto_vencido           money,
   @w_monto_aux               money,
   @w_secuencial_uvr          int,
   @w_cod_valor               int,
   @w_rubro_cap               catalogo,
   @w_est_suspenso            tinyint,
   @w_estado_act              tinyint,
   @w_est_vencido             int,
   @w_di_fecha_ven            datetime,
   @w_saldo_oper              money,
   @w_saldo_rubro             money,
   @w_calcular_new            char(1),
   @w_max_div                 int,
   @w_fecha_liq               datetime,
   @w_fecha_ini               datetime,
   @w_fecha_a_causar          datetime,
   @w_tdividendo              catalogo,
   @w_clausula                varchar(1),
   @w_causacion               varchar(2),
   @w_dias_div                int,
   @w_saldo_restante          money,
   @w_vencido_ant             money,
   @w_saldo_oper1             float,
   @w_monto_mop1              float,
   @w_diferencia              float,
   @w_abd_monto_mlo           money,
   @w_dividendo_vigente       int,
   @w_abono_extraordinario    char(1),
   @w_marca_prepas            varchar(10),
   @w_dividendo_vencido       int,
   @w_situacion_cliente       catalogo,
   @w_suspension_manual       catalogo,
   @w_monto_gar_mn            money,
   @w_reconocimiento          char(1),
   @w_saldo_cap_gar           money,
   @w_cotizacion_aju          float,
   @w_fecha_suspenso          datetime,
   @w_cotizacion_dia_sus      money,
   @w_est_castigado           tinyint,
   @w_vlr_despreciable        float,
   @w_monto_condonado         money,
   @w_bandera_be              char(1), --PARA ENVIARLA A GARANTIAS
   @w_param_sobaut            char(24),
   @w_valor_vencido_acum      money,
   @w_op_naturaleza           char(1),
   @w_tipo_cobro_con          catalogo,
   @w_pagado_intant           money,
   @w_parametro_fprsvi        catalogo,
   @w_descripcion             varchar(200),
   @w_sum_cuotas_ant          money,
   @w_sum_saldo_ant           money,
   @w_sum_cuotas_despues      money,
   @w_sum_saldo_despues       money,
   @w_op_monto                money,
   @w_nro_cuotas_pendientes   smallint,
   @w_op_clase                catalogo,
   @w_en_gracia_int           char(1),
   @w_op_gracia_int           int,
   @w_max_sec                 int,
   @w_limite_ajuste           money,
   @w_sec_pago_ant            int,
   @w_fecha_valor             char(1),
   @w_genera_prepago          char(1),
   @w_sec_reversado           int,
   @w_fc_fecha_cierre         datetime,
   @w_tr_estado               catalogo,
   @w_oficina_orig            smallint,
   @w_ab_fecha_pag            varchar(10),
   @w_val_pagado              money,
   @w_consecutivo_sidac       int,
   @w_par_fpago_depogar       catalogo,
   @w_monto_para_sidac        money,
   @w_capitaliza              char(1),
   @w_ab_nro_recibo           int,
   @w_rowcount_act            int,
   @w_gracia_extraordinario   money,
   @w_dividendo_vig_extra     int,
   @w_fecha_fin_op            datetime,
   @w_dtr_D                   float,
   @w_dtr_C                   float,
   @w_diff                    float,
   @w_tr_tran                 catalogo,
   @w_msg                     varchar(100),
   @w_sobrante_pago           money,
   @w_precancelacion          char(1),
   @w_monto_cancelacion       money,
   @w_monto_pago              money,
   @w_com_banco               varchar(30),
   @w_com_canal               varchar(30),
   @w_iva_com_can             varchar(30),
   @w_comisiones_recaudo      money,
   @w_cto                     catalogo,
   @w_valor_saldo_minimo      money,
   @w_monto_residuo           money,
   @w_capital_antes           money,
   @w_saldo_por_diferir       money,
   @w_dif_pago                money,
   @w_diferido_pagado         money,
   @w_diferido_total          money,
   @w_est_diferido            tinyint,
   @w_parametro_BEMPRE        catalogo, -- 175
   @w_op_banca                catalogo,
   @w_solo_capital            char(1),
   @w_ult_cancelado           tinyint,
   @w_ult_cancelado_despues   tinyint,
   @w_en_cancelada            char(1),
   @w_cod_gar_fag	          varchar(10),
   @w_rol                     smallint,
   @w_tipo_gar_act            varchar(10),
   @w_estado_cobranza         varchar(2),
   @w_tipo_empleado           catalogo,
   @w_tipo_persona            catalogo,
   @w_evento_campana          catalogo,       --Req. 300 
   @w_msg_matriz              varchar(255),    --Req. 300 
   @w_fpago_empleado          catalogo,
   @w_fpago_sobrante          catalogo,
   @w_param_est_cobranza      catalogo,
   @w_param_prejuridico       catalogo,
   @w_ab_estado               catalogo,
   @w_li_num_banco            cuenta,
   @w_tr_linea_credito        int,
   @w_tiene_reco              char(1),--LCM - 293
   @w_vlr_x_amort             money,  --LCM - 293   

   @w_orden                   int,
   @w_concepto                catalogo,
   @w_acuerdo                 char(1),
   @w_fecha_ini_control       datetime,
   @w_pago_especial           char(1),
   @w_llave_redes             cuenta,
   @w_saldo_proy              money,
   @w_tipo_amortizacion       catalogo,
   @w_saldo_cap               money,
   @w_dias_calc               smallint,
   @w_comprecan               catalogo,
   @w_max_div_vencido         int,
   @w_saldo                   money,
   @w_comprecan_ref           catalogo,
   @w_tasa_comprecan          float,
   @w_valor_multa             money,
   @w_valor_sobrante          float,
   @w_secuencial_ioc          int,
   @w_tg_tramite		      INT,
   @w_rowcount  			  INT,
   @w_es_precancelacion       CHAR(1),
   @w_om_rotativa             CHAR(1),
   @w_li_numero               INT,
   @w_en_linea                char(1),
   @w_existe_condonacion      char(1),  -- KDR Bandera que identifica si existen registros de condonaciones
   @w_control_abn_extra       char(1)   -- KDR Bandera para control de abono extraodrinario
   
       
--- CARGA DE LOS PARAMETROS DE CARTERA
select 
@s_term                  =  isnull(@s_term,'consola'),
@w_monto_condonado       =  0,
@w_saldo_oper            =  0,
@w_calcular_new          = 'N',
@w_dividendo_vigente     =  0,
@w_abono_extraordinario  = 'N',
@w_reconocimiento        = 'N',
@w_saldo_cap_gar         =  0,
@w_vlr_despreciable      =  0,
@w_valor_vencido_acum    =  0,
@w_en_gracia_int         = 'N',
@w_max_sec               =  0,
@w_consecutivo_sidac     =  0,
@w_capitaliza            = 'N',
@w_comisiones_recaudo    =  0,
@w_acuerdo               = 'N',
@w_pago_especial         = 'N',
@w_evento_campana        = 'PAG',
@w_saldo_cap             = 0,
@w_comprecan             = 'COMPRECAN',
@w_secuencial_ioc        = null,
@w_existe_condonacion    = 'N'


--VALIDACION DE LA EXISTENCIA DEL SECUENCIAL @s_ssn
if @s_ssn is null begin
   exec @s_ssn       = sp_gen_sec
        @i_operacion = @i_operacionca
end

---PARAMETRO TIPO DE AMORTIZACION  NR.392
select @w_tipo_amortizacion = pa_char
from cobis..cl_parametro
where pa_nemonico = 'TFLEXI'

if @@rowcount = 0 return  724007 

--- LECTURA DEL PARAMETRO DE COBRANZA JURIDICA 
select @w_param_est_cobranza =  pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'ESTJUR'
and    pa_producto = 'CRE'
set transaction isolation level read uncommitted
   
--- LECTURA DEL PARAMETRO DE COBRANZA PREJURIDICA 
select @w_param_prejuridico = pa_char
from  cobis..cl_parametro
where pa_nemonico = 'ESTCPR'
and pa_producto = 'CRE'  
   
   
select @w_limite_ajuste = pa_money
from   cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and    pa_nemonico = 'LAJUST'
if @@rowcount = 0
   select @w_limite_ajuste = 1

----AJSUTE TEMPORAL
delete ca_abono_prioridad
where ap_operacion      = @i_operacionca
and   ap_secuencial_ing = @i_secuencial_ing
and ap_concepto  in ('COMUSASEM','IVACOMUSA')
if @@error <> 0 return 707003

delete ca_amortizacion
where am_operacion  = @i_operacionca
and am_concepto in ('COMUSASEM','IVACOMUSA')
if @@error <> 0 return 707003

delete ca_rubro_op
where ro_operacion  = @i_operacionca
and ro_concepto in ('COMUSASEM','IVACOMUSA')
if @@error <> 0 return 707003
----FIN INICIO AJSUTE TEMPORAL

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_diferido   = @w_est_diferido  out

if @@error <> 0 return 708201
      
if @w_error <> 0 return @w_error


if exists (select 1 from ca_operacion, cob_credito..cr_acuerdo where ac_banco = op_banco and op_operacion = @i_operacionca)
   select @w_acuerdo = 'S'

--PARA GEENRACION DE PREPAGOS
select @w_fc_fecha_cierre = fc_fecha_cierre
from   cobis..ba_fecha_cierre 
where  fc_producto = 7

--21NOV2006 ESTE INSERT PARA QUE EL PAGO QUEDE OK
--Y NO GENERE DOS VIGENTES POR ERROR
insert into ca_abono_prioridad  with (rowlock)
select @i_secuencial_ing, @i_operacionca, ro_concepto, ro_prioridad
from   ca_rubro_op r
where  ro_operacion   = @i_operacionca
and    ro_fpago      <> 'L'
and    not exists(select 1
                  from   ca_abono_prioridad
                  where  ap_operacion      = @i_operacionca
                  and    ap_secuencial_ing = @i_secuencial_ing
                  and    ap_concepto       = r.ro_concepto)

if (select count(1) from ca_abono_prioridad
    where ap_operacion      = @i_operacionca
    and   ap_secuencial_ing = @i_secuencial_ing
    and   ap_prioridad = 0) = 2
begin
   set rowcount 1
   update ca_abono_prioridad with (rowlock)
   set    ap_prioridad = -1
   where  ap_operacion = @i_operacionca
   and    ap_secuencial_ing = @i_secuencial_ing
   and    ap_prioridad = 0
   
   if @@error <> 0 return 708152
   set    rowcount 0
end

select @w_int_ant = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTANT'
if @@rowcount = 0 return 710256


select @w_int_fac = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTFAC'
if @@rowcount = 0 return 710256

-- CODIGO DEL RUBRO CAPITAL
select @w_rubro_cap = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
if @@rowcount = 0 return 710076

--MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
if @@rowcount = 0  return 710076

--PARAMETRO PARA FORMA DEPAGO RECONOCIMIENTO SEGURO DE VIDA
select @w_parametro_fprsvi = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA' 
and    pa_nemonico = 'FPRSVI'

-- CONCEPTO COMISION BANCO
select @w_com_banco = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CCBA' 
     
-- CONCEPTO COMISION CANAL
select @w_com_canal = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CCCA'

-- IVA COMISION CANAL
select @w_iva_com_can = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'ICCA'

--CONSULTA CODIGO DE MONEDA LOCAL
select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'MLO'
and    pa_producto = 'ADM'

-- MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
if @@rowcount = 0 return 710076

/*MONTO SALDO MINIMO*/
select @w_valor_saldo_minimo = pa_money
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'SALMIN'
if @@rowcount = 0 return 710076

--- PARÁMETRO CONTROL ABONO EXTRAORDINARIO ENLACE 
select @w_control_abn_extra = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'ABEXEN'
and    pa_producto = 'CCA'

-- DATOS DE CA_OPERACION
select 
@w_banco            = op_banco,
@w_toperacion       = op_toperacion,
@w_op_migrada       = op_migrada,
@w_sector           = op_sector,
@w_moneda_op        = op_moneda,
@w_oficina_op       = op_oficina,
@w_dias_anio        = op_dias_anio,
@w_base_calculo     = op_base_calculo,
@w_tipo_tabla       = op_tipo_amortizacion,
@w_cliente          = op_cliente,
@w_tipo             = op_tipo,
@w_tramite          = op_tramite,
@w_fecha_proceso    = op_fecha_ult_proceso,
@w_gerente          = op_oficial,
@w_tipo_linea       = op_tipo_linea,
@w_lin_credito      = op_lin_credito,
@w_numero_comex     = op_num_comex,
@w_gar_admisible    = op_gar_admisible,
@w_reestructuracion = isnull(op_reestructuracion, ''),
@w_calificacion     = isnull(op_calificacion, 'A'),
@w_nombre           = op_nombre,
@w_op_estado        = op_estado,
@w_llave_redes      = op_codigo_externo,
@w_fecha_liq        = op_fecha_liq,
@w_fecha_ini        = op_fecha_ini,
@w_tdividendo       = op_tdividendo,
@w_clausula         = op_clausula_aplicada,
@w_causacion        = op_causacion,
@w_dias_div         = op_periodo_int,
@w_op_naturaleza    = op_naturaleza,
@w_op_monto         = op_monto,
@w_op_clase         = op_clase,
@w_op_gracia_int    = op_gracia_int,
@w_fecha_fin_op     = op_fecha_fin,
@w_precancelacion   = op_precancelacion,
@w_estado_cobranza  = op_estado_cobranza,
@w_op_banca         = op_banca
from   ca_operacion
where  op_operacion = @i_operacionca

if @@rowcount = 0 
  return 701025

  
-- LECTURA DE DECIMALES
exec @w_error = sp_decimales
@i_moneda       = @w_moneda_op,
@o_decimales    = @w_num_dec_op out,
@o_mon_nacional = @w_moneda_mn  out,
@o_dec_nacional = @w_num_dec_n  out

if @@error <> 0 return 708201
if @w_error <> 0 return  @w_error

if @i_valor_multa > 0
begin
   /*SECUENCIAL DE PAGO*/   
   exec @w_secuencial_ioc = sp_gen_sec
   @i_operacion      = @i_operacionca

end

/*SECUENCIAL DE PAGO*/   
exec @w_secuencial_pag = sp_gen_sec
@i_operacion      = @i_operacionca

--OBTENER CODIGO GARANTIA FAG REQ 00212

select @w_cod_gar_fag = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and pa_nemonico = 'CODFAG'

select tc_tipo as tipo 
into #calfag
from cob_custodia..cu_tipo_custodia
where tc_tipo_superior = @w_cod_gar_fag

select @w_cod_gar_fag = tipo
from #calfag 

--DEFINIR ROL ESPECIAL PARA AUTORIZACION PAGOS REQ 00212

select @w_rol = pa_smallint
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and pa_nemonico = 'ROLPAG'

-- OBTENER RESPALDO ANTES DE LA APLICACION DEL PAGO
exec @w_error  = sp_historial
@i_operacionca  = @i_operacionca,
@i_secuencial   = @w_secuencial_pag

if @@error <> 0 return 708201
if @w_error <> 0 return @w_error

select 
@w_cotizacion        = abd_cotizacion_mop,
@w_tcotizacion       = abd_tcotizacion_mop
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing
and    abd_operacion      = @i_operacionca
and    abd_tipo           = 'PAG'

if @@rowcount = 0 return 710035



-- Registra la multa por precancelacion
if @i_valor_multa > 0
begin
   
   select @w_saldo = sum (am_acumulado- am_pagado)
   from cob_cartera..ca_amortizacion 
   where am_operacion = @i_operacionca
   
   select
   @w_comprecan_ref   = ru_referencial
   from   cob_cartera..ca_rubro
   where  ru_toperacion = @w_toperacion
   and    ru_moneda     = @w_moneda_op
   and    ru_concepto   = 'COMPRECAN'
   
   if @@rowcount = 0 begin
      select @w_error = 701178
      return 701178
   end
   
   /* DETERMINAR LA TASA DE LA COMISION POR PRECANCELACIÓN */
   select 
   @w_tasa_comprecan  = vd_valor_default / 100
   from   ca_valor, ca_valor_det
   where  va_tipo   = @w_comprecan_ref
   and    vd_tipo   = @w_comprecan_ref
   and    vd_sector = @w_sector /* sector comercial */
   
   if @@rowcount = 0 begin
       select @w_error = 701085
       return 701085
   end
   
   select @w_valor_multa   =  round(@w_saldo * @w_tasa_comprecan, @w_num_dec_op) 
   
   select @w_max_div_vencido =isnull(min(di_dividendo),0) 
   from ca_dividendo 
   where di_operacion = @i_operacionca
   and   di_estado in (@w_est_vigente,@w_est_vencido) 

   exec @w_error     = sp_otros_cargos
   @s_date           = @s_date,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_ofi            = @s_ofi,
   @i_banco          = @w_banco,
   @i_toperacion     = @w_toperacion,
   @i_moneda         = @w_moneda_op,
   @i_secuencial_ioc = @w_secuencial_ioc,
   @i_operacion      = 'I',
   @i_desde_batch    = 'N',   
   @i_en_linea       = 'N',
  @i_tipo_rubro     = 'O',
   @i_concepto       = @w_comprecan ,
   @i_monto          = @w_valor_multa,      
   @i_div_desde      = @w_max_div_vencido,      
   @i_div_hasta      = @w_max_div_vencido,
   @i_comentario     = 'GENERADO POR: sp_abonoca'      
          
   if @w_error != 0  begin
      select @w_descripcion = 'Error ejecutando sp_otros_cargos por insertar PRECANCELACION a la operación : ' + @w_banco 
      return 710404
   end
   
   select 
   secuencial = @i_secuencial_ing,
   operacion = ro_operacion,
   concepto  = ro_concepto,
   prioridad = ro_prioridad
   into #prioridades
   from ca_rubro_op
   where ro_operacion = @i_operacionca
   
   delete #prioridades
   from ca_abono_prioridad
   where ap_operacion = operacion
   and   ap_concepto  = concepto
   and   ap_secuencial_ing = @i_secuencial_ing
   
   insert into ca_abono_prioridad select * from #prioridades
   
end

---NR 436 ART12 Normalizacion 
if @i_es_norm = 'S'
begin
  ---Despues de respaldar los diferidos de las operaciones a refinanciar se eliminan
  ---para evitar contabilidad en este pago
  delete ca_diferidos
  where dif_operacion = @i_operacionca
    if @@error <> 0
        return  701157
end
---NR 436 ART12 Normalizacion 

--DATOS DEL ABONO
select 
@w_ab_fecha                 = ab_fecha_ing,
@w_tipo_cobro               = case @i_por_rubros when 'S' then 'A' else ab_tipo_cobro end,
@w_tipo_reduccion           = ab_tipo_reduccion,
@w_tipo_aplicacion          = case @i_por_rubros when 'S' then 'C' else ab_tipo_aplicacion end,
@w_secuencial_rpa           = ab_secuencial_rpa,
@w_operacionca              = ab_operacion,
@w_aceptar_anticipos        = ab_aceptar_anticipos,
@w_tasa_prepago             = ab_tasa_prepago,
@w_oficina_orig             = ab_oficina,
@w_ab_fecha_pag             = convert(varchar(10),ab_fecha_pag,101),
@w_ab_nro_recibo            = ab_nro_recibo,
@w_solo_capital             = ab_extraordinario,
@w_ab_estado                = ab_estado
from   ca_abono
where  ab_operacion      = @i_operacionca
and    ab_secuencial_ing = @i_secuencial_ing
and    ab_secuencial_rpa is not null

if @@rowcount = 0 return 701119

-- AMO 20220610  SE CONSERVA EL TIPO DE REDUCCION ORIGINAL PARA VALIDAR CORRECTAMENTE EL SALDO EN PRECANCELACION O CANCELACION
SELECT  @w_tipo_reduccion_orig = @w_tipo_reduccion

--VERIFICACION SI LA TABLA ES TIPO ROTATIVA
if @w_tipo_amortizacion = 'ROTATIVA'
   select @w_tipo_reduccion           = 'N',
          @w_tipo_aplicacion          = 'P'

---INC. 42961 COBRO DE HONORARIOS CUANDO ES REAPLICACION CON FECHA VALOR
---           POR QUE NO ENTRA AL regabono.sp QUE ES DONDE SE GENERA EL COBRO DE HONORARIOS
if @w_ab_fecha <= @w_fc_fecha_cierre and @w_ab_estado = 'NA' and  @w_estado_cobranza in (@w_param_est_cobranza,@w_param_prejuridico) and @w_tipo_aplicacion <> 'C' and @w_tipo_reduccion <> 'M'
begin
  ---Revisar si se hizo feha valor en este dia
  if exists (select 1  from ca_log_fecha_valor
			 where fv_operacion = @i_operacionca
			 and  fv_tipo = 'F'
			 and  fv_fecha_real > @w_fc_fecha_cierre  ---Fecha_real tien hora or tanto siemrpe es mayor que la de cartera
			 and  fv_secuencial_retro > 0)             
	begin
      if not exists (select 1 from cobis..cl_catalogo c
	                  where c.tabla in (select codigo from cobis..cl_tabla
	                                    where tabla = 'ca_fpago_sin_honorarios')
	                  and c.codigo = @w_fpago
	                  and c.estado = 'V')
         begin 
	         ---Pago En fecha valor , debe generar cobro de honorarios y la forma de pago permite cobro de estos
	        
            select @w_abd_monto_mpg = 0
            select @w_abd_monto_mpg = abd_monto_mpg
            from ca_abono_det
            where abd_operacion = @i_operacionca
            and abd_secuencial_ing = @i_secuencial_ing
            
		   	    exec @w_error       = sp_calculo_honabo
		         @s_user            = @s_user,           --Usuario de conexion
		         @s_ofi             = @s_ofi,            --Oficina del pago (si es por front es la de conexion)
		         @s_term            = @s_term,           --Terminal de operacion
		         @s_date            = @s_date,           --ba_fecha_proceso
		         @i_operacionca     = @i_operacionca,    --op_operacion de la operacion
		         @i_toperacion      = @w_toperacion,     --op_toperacion de la operacion
		         @i_moneda          = @w_moneda_op,      --op_moneda de la operacion
		         @i_monto_mpg       = @w_abd_monto_mpg   --Monto del pago que sera utilizado para el calculo de honabo
		         
		         if @@error <> 0 return 708201
		         if @w_error <> 0 return @w_error
	        end
	end			
end 
---INC. 42961

if @w_solo_capital = 'K'
   select @i_solo_capital = 'S'

if exists (select 1 from ca_abono_det
where  abd_operacion = @w_operacionca
and    abd_secuencial_ing = @i_secuencial_ing
and    abd_tipo = 'CON')
BEGIN
   SELECT @w_existe_condonacion = 'S'
END
--AMP 20220610   
if @w_tipo_reduccion in ('T', 'C') 
   select @w_tipo_cobro = 'A'
   
if @w_tipo_reduccion = 'N' and @w_existe_condonacion <> 'S'
   select @w_tipo_cobro = 'P'
   
-- CALCULAR EL MONTO DEL PAGO
select @w_monto_mop = isnull(sum(abd_monto_mop), 0), @w_cto = max(abd_concepto)
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing 
and    abd_operacion      = @w_operacionca
and    abd_tipo in ('PAG', 'DEV', 'SOB') -- KDR Se suprime 'CON' por que ya se lo toma en cuenta en el tipo PAG.

if isnull(@w_monto_mop, 0) <= 0 return 710129 

--Incidencia 7498 Jul-01-2010
select @w_comisiones_recaudo = sum(cr_comision_ban + cr_comision_can + cr_iva_comision)
from ca_comision_recaudo
where cr_secuencial_ing = @i_secuencial_ing
and   cr_operacion      = @w_operacionca

select @w_monto_mop = @w_monto_mop - isnull(@w_comisiones_recaudo,0)

/*MODIFICACION ANALISIS PARA DETERMINAR SI ES UNA PRECANCELACION*/
if @i_canal_inter = 2
    select @w_en_linea = 'N'
    
IF @i_debug = 'S'
  PRINT '1.1 sp_cartera_abono antes sp_calcula_saldo @w_tipo_cobro = ' + @w_tipo_cobro    
  
exec @w_error        = sp_calcula_saldo
@i_operacion         = @i_operacionca,
@i_tipo_pago         = @w_tipo_cobro, --'A', --LPO TEC
@i_en_linea          = @w_en_linea,
@i_tipo_reduccion	 = @w_tipo_reduccion, -- AMO 20220610 SI ES ANTICIPO DE CUOTAS INCLUIR RUBROS DISTINTOS DE C,I O M
@i_debug             = @i_debug, -- AMO 20220610
@o_saldo             = @w_monto_cancelacion out

if @@error <> 0 
  return 708201
  
IF @i_debug = 'S'
  PRINT '1.2 sp_cartera_abono despues sp_calcula_saldo @w_tipo_cobro = ' + @w_tipo_cobro + ' @w_monto_cancelacion = ' + convert(varchar(10), @w_monto_cancelacion)  

SELECT @w_saldo_oper = @w_monto_cancelacion

select @w_monto_residuo = @w_monto_cancelacion - @w_monto_mop

--- INI - REQ 175: PEQUEÑA EMPRESA

select @w_parametro_BEMPRE = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'BEMPRE'
if @@rowcount = 0 return 721311

if @w_op_banca  = @w_parametro_BEMPRE
begin
   ---53984
    if not exists (select 1 from cobis..cl_catalogo c
    where c.tabla in (select codigo from cobis..cl_tabla
                    where tabla = 'ca_fpago_sin_honorarios')
      and c.codigo = @w_cto)
      begin
		   exec  @w_error = sp_comision_por_prepago
		   @i_operacionca      = @i_operacionca,
		   @i_secuencial_ing   = @i_secuencial_ing,
		   @i_valor_pago       = @w_monto_mop,
		   @i_deuda            = @w_monto_cancelacion
		   
		   if @@error <> 0 return 708201
		   if @w_error <> 0 return  @w_error
	  end

end
-- FIN - REQ 175: PEQUEÑA EMPRESA

/* -- KDR Se comenta sección para que no genere detalle de TRN con un saldo mínimo.
-- RUTINA PARA AJUSTAR EL MONTO DE PAGO PARA EVITAR QUE LA OPERACION QUEDE VENCIDA POR UN MONTO MINIMO
if @w_monto_cancelacion - @w_monto_mop <= @w_valor_saldo_minimo and @w_monto_residuo > 0 begin 
    exec @w_error        = sp_saldos_minimos
    @s_date              = @s_date,
    @s_user              = @s_user,
    @s_sesn              = @s_sesn,
    @i_pago_cuota        = 'N',
    @i_secuencial_ing    = @i_secuencial_ing,
    @i_secuencial_pag    = @w_secuencial_pag,
    @i_operacionca       = @i_operacionca,
    @i_monto_cancelacion = @w_monto_cancelacion,    
    @i_monto_pago        = @w_monto_mop,
    @i_op_estado         = @w_op_estado,
    @i_num_dec           = @w_num_dec_op,
    @i_num_dec_n         = @w_num_dec_n,
    @i_cotizacion        = @w_cotizacion,
    @i_tcotizacion       = @w_tcotizacion

    if @@error <> 0 return 708201    
    if @w_error <> 0 return  @w_error
   
    select @w_monto_mop = @w_monto_cancelacion
         
end
*/

if @w_monto_cancelacion <= @w_monto_mop 
  begin   
    -- AMO 20220610
    IF @w_tipo_reduccion IN ('C','T')
      select  @w_tipo_cobro = 'A'
     
    select @w_evento_campana  = 'CAN'
   
    update ca_abono  with (rowlock) set
    ab_tipo_cobro            = @w_tipo_cobro
    where  ab_operacion      = @i_operacionca
    and    ab_secuencial_ing = @i_secuencial_ing
   
    if @@error <> 0 
      return 708201
  end

/*VALIDACION PARA OPERACIONES QUE VAN A CANCELARCE Y TIENE OPERACION ALTERNA*/
if  @w_monto_mop >= @w_monto_cancelacion
begin
   if exists (select 1 from ca_operacion 
              where op_cliente  = @w_cliente
              and op_toperacion = 'ALT_FNG'
              and op_estado     not in (0,3)
              and op_anterior   = @w_banco)begin         
         return 724524
  end 
end

select @w_capital_antes = sum(am_cuota + am_gracia - am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion  = @w_operacionca
and    ro_operacion  = @w_operacionca
and    am_concepto   = ro_concepto
and    ro_tipo_rubro = 'C' -- CAPITALES

select @w_capital_antes = round(@w_capital_antes, @w_num_dec_op)

/*CONTROL PARA PAGOS EN FECHA VALOR QUE CANCELAN LA OPERACION*/   
if exists (select 1 from ca_abono where ab_estado = 'NA'
and ab_operacion  = @i_operacionca 
and ab_fecha_pag  > @w_fecha_proceso) 
and @w_monto_cancelacion = @w_monto_mop 
begin
   return 708216
end                           
   
--ENE-24-2007-EPB DEF-BAC NRO 7784
-- KDR Pagos extraordinarios con reducción de cuota de préstamos con tipo de Amortización Manual no válido en la versión de Finca Impact
if @w_tipo_tabla = 'MANUAL' and @w_tipo_reduccion = 'C' 
   return 725150 -- No se admite abonos extraordinarios con reducción de Cuota a préstamos con tipo de Amortización Manual
     
--- REQ 237 LAVADO DE ACTIVOS
select 
@w_di_fecha_ven      = di_fecha_ven,
@w_dividendo_vigente = di_dividendo
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vigente
if @@rowcount > 1   
   return 710139

--- REQ 237 LAVADO DE ACTIVOS
select @w_tipo_cobro_con = @w_tipo_cobro
   
select @w_ult_cancelado = max(isnull(di_dividendo,0))
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_cancelado

--VALIDAR SI ES INTANT  PARA REVISAR EL ACUMULADO VENCIDO
select 
@w_concepto_int = ro_concepto,
@w_tasa_prepago = ro_porcentaje
from   ca_rubro_op
where  ro_operacion  = @w_operacionca
and    ro_tipo_rubro = 'I'


select @w_dividendo_vig_extra = @w_dividendo_vigente

-- VALIDACION Relacion Rubro y Rubro Proporcional con Valor Presente 
if (@w_tipo_aplicacion = 'C' or @w_tipo_aplicacion = 'P') and (@w_tipo_cobro = 'E')
    select @w_tipo_cobro = 'A'

-- PARA TIPO DE APLICACION POR CONCEPTO o PROPORCIONAL, SE DEBE HACER
-- TIPO DE REDUCCION DE CUOTA PARA LOS VALORES QUE SOBREN DESPUES DE APLICAR A LOS CONCEPTOS
-- INDICADOS
if (@w_tipo_aplicacion = 'P')
   select  @w_tipo_reduccion = 'C'

select @w_vlr_despreciable = 1.0 / power(10,  isnull((@w_num_dec_op+2), 4))

/*if @w_op_estado = @w_est_suspenso and @w_moneda_op = @w_moneda_uvr begin -- DETERMINAR LA FECHA Y COTIZACION DEL DIA DE LA SUSPENSION
   select @w_fecha_suspenso = null
   
   -- LOCALIZAR LA ULTIMA FECHA DE CAUSACION VIGENTE
   select @w_fecha_suspenso = isnull(max(tr_fecha_ref), @w_fecha_proceso)
   from   ca_transaccion
   where  tr_operacion = @w_operacionca
   and    tr_tran = 'SUA'
   and    tr_estado in ('CON', 'NCO')
   
   -- OBTENER LA COTIZACION DE ESE DIA
   exec sp_buscar_cotizacion
        @i_moneda     = @w_moneda_op,
        @i_fecha      = @w_fecha_suspenso,
        @o_cotizacion = @w_cotizacion_dia_sus out
        
   if @@error <> 0 return 708201        
   
end*/

--EPB05SEP2003
select @w_marca_prepas = abd_beneficiario,
       @w_consecutivo_sidac = abd_cheque
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing 
and    abd_operacion      = @w_operacionca
and    abd_tipo           = 'PAG'

-- DETERMINAR LA SITUACION DEL CREDITO ANTES DEL PAGO
select @w_sum_cuotas_ant = isnull(sum(am_cuota), 0),
       @w_sum_saldo_ant  = isnull(sum(am_acumulado - am_pagado), 0)
from   ca_amortizacion
where  am_operacion = @w_operacionca
and    am_concepto  = @w_rubro_cap

if round(@w_sum_cuotas_ant,2) <> round(@w_op_monto,2) begin
   if exists(select 1 from ca_acciones where ac_operacion = @w_operacionca)
      select @w_sum_cuotas_ant = @w_sum_cuotas_ant
   ELSE 
   begin
      return 710540
   end
end

---INICIO REQ 379 IFJ 22/Nov/2005 
if exists (select 1 from ca_traslado_interes
           where ti_operacion = @w_operacionca
           and   ti_estado     = 'P')
begin
    select @w_tipo_cobro = 'A'
end
--- FIN REQ 379 IFJ 22/Nov/2005 

if @w_op_gracia_int > 0 begin
   if exists(select 1 from   ca_amortizacion
   where  am_operacion = @w_operacionca
   and    am_dividendo = @w_dividendo_vigente
   and    am_concepto  = @w_concepto_int
   and    am_gracia    < 0)
   begin
      select @w_en_gracia_int = 'S'
      
      if @w_tipo_cobro = 'E'
         select @w_tipo_cobro = 'P'
   end
end

if @w_moneda_op = 2 begin

   exec sp_buscar_cotizacion
   @i_moneda     = 2,
   @i_fecha      = @w_fecha_proceso,
   @o_cotizacion = @w_cotizacion_aju out
   
   if @@error <> 0 return 708201
   
   update ca_abono_det  with (rowlock) set
   abd_monto_mop      = round(abd_monto_mn / @w_cotizacion_aju, @w_num_dec_op),
   abd_cotizacion_mop = @w_cotizacion_aju
   where  abd_secuencial_ing = @i_secuencial_ing 
   and    abd_operacion      = @w_operacionca
   and    abd_tipo in ('PAG','SOB','DEV', 'CON')
   
   if @@error <> 0 return 708152
   
end

-- CALCULAR EL MONTO DEL PAGO CONDONADO
select @w_monto_condonado = isnull(sum(abd_monto_mop), 0)
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing 
and    abd_operacion      = @w_operacionca
and    abd_tipo  = 'CON'
-- CALCULAR EL MONTO DEL PAGO CONDONADO

-- SELECCIONAR LA COTIZACION Y EL TIPO DE COTIZACION
if @w_tipo_aplicacion <> 'O' and @w_monto_condonado <= 0 begin -- NO ES DE LA NUEVA CONDONACION

   select 
   @w_cotizacion        = abd_cotizacion_mop,
   @w_tcotizacion       = abd_tcotizacion_mop,
   @w_moneda_ab         = abd_moneda,
   @w_fpago             = abd_concepto
   from   ca_abono_det
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @w_operacionca
   and    abd_tipo           = 'PAG'
   
   if @@rowcount = 0 return 710035
   
end else begin

   select 
   @w_cotizacion    = abd_cotizacion_mop,
   @w_tcotizacion   = abd_tcotizacion_mop,
   @w_moneda_ab     = abd_moneda,
   @w_fpago         = abd_concepto
   from   ca_abono_det
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @w_operacionca
   and    abd_tipo           = 'CON'
   
   if @@rowcount = 0 return 710035
end

select @w_monto_sobrante =  @w_monto_mop - @w_monto_condonado

select @w_dividendo_vencido = isnull(max(di_dividendo),0)
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vencido

if @i_canal_inter = 2
    select @w_en_linea = 'N'
    
select @w_cancelar = 'N' 

/* LCM - 293: LEE LA TABLA DE RECONOCIMIENTO PARA VALIDAR SI LA OBLIGACION TIENE RECONOCIMIENTO ACTIVO */
select @w_vlr_x_amort = 0

select @w_vlr_x_amort = isnull(pr_vlr - pr_vlr_amort,0)
from ca_pago_recono with (nolock)
where pr_operacion = @w_operacionca
and   pr_estado    = 'A'

if @@rowcount > 0
   select @w_tiene_reco = 'S'

/* SUMA EL VALOR PENDIENTE POR AMORTIZAR AL SALDO DE LA OPERACION */
if @w_vlr_x_amort <> 0
   select @w_saldo_oper = @w_saldo_oper + @w_vlr_x_amort

select @w_monto_mop1 = round(convert(float,sum(@w_monto_mop)),4)
select @w_saldo_oper1 = round(convert(float,sum(@w_saldo_oper)),4)

if  @w_moneda_op <> @w_moneda_local begin 
   select @w_diferencia = @w_saldo_oper1 - @w_monto_mop1
   
   if abs(@w_diferencia) <= 0.0009 begin
      select @w_abd_monto_mlo =  round(@w_saldo_oper1 * @w_cotizacion, @w_num_dec_n)
      
      update ca_abono_det  with (rowlock)
      set    abd_monto_mop = @w_saldo_oper1,
             abd_monto_mn  = @w_abd_monto_mlo
      where  abd_secuencial_ing = @i_secuencial_ing 
      and    abd_operacion      = @w_operacionca
      and    abd_tipo = 'PAG'
      
      if @@error <> 0 return 708152
      
      -- CALCULAR EL MONTO DEL PAGO DESPUES DEL UPDATE
      select @w_monto_mop = isnull(sum(abd_monto_mop), 0)
      from   ca_abono_det
      where  abd_secuencial_ing = @i_secuencial_ing 
      and    abd_operacion      = @w_operacionca
      and    abd_tipo = 'PAG'

      select @w_monto_mop1 = round(convert(float,sum(@w_monto_mop)),4)
   end
END

IF @i_debug = 'S'
  PRINT '2.1 sp_cartera_abono @w_monto_mop1 = ' + convert(varchar(12), @w_monto_mop1) + ' @w_saldo_oper1 = ' + convert(varchar(12), @w_saldo_oper1) + ' @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante) + ' @w_precancelacion = ' + @w_precancelacion + ' @w_tipo_reduccion = ' + @w_tipo_reduccion

if  @w_monto_mop1 >=  @w_saldo_oper1 
begin
    if @w_precancelacion = 'S' --and @w_tipo_reduccion != 'N' -- AMO 20220610
	begin
       select @w_monto_sobrante = @w_monto_mop,
              @w_cancelar       = 'S'
              
       IF @w_tipo_reduccion != 'N'
         BEGIN
           SELECT @w_tipo_reduccion = 'N'
      
           update ca_abono  with (rowlock)
           set    ab_tipo_reduccion = 'N'
           where  ab_secuencial_ing = @i_secuencial_ing
           and    ab_operacion      = @w_operacionca
       
           if @@error <> 0 return 708152
         END  
       
    end
    else 
	begin
       return 701190
    end
END

IF @i_debug = 'S'
  PRINT '2.2 sp_cartera_abono @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante) + ' @w_cancelar = ' + @w_cancelar + ' @w_tipo_reduccion = ' + @w_tipo_reduccion

select @w_max_div = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @w_operacionca

--OBLIGACION CON UNA SOLA CUOTA SOLO APLICA NORMALMENTE
if @w_max_div = 1  select @w_tipo_reduccion = 'N'

select @w_estado_ult_div = di_estado
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_dividendo = @w_max_div

select @w_saldo_cap_gar = @i_cotizacion * (sum(am_cuota + am_gracia - am_pagado))
from   ca_amortizacion, ca_rubro_op
where  ro_operacion  = @w_operacionca
and    ro_tipo_rubro = 'C'
and    am_operacion  = @w_operacionca
and    am_estado <> 3
and    am_concepto   = ro_concepto

if (@w_cancelar = 'S') and (@w_estado_ult_div = 2) begin  --CANCELAR OP.VENCIDA... NO IMPORTA TIPO DE COBRO
   select 
   @w_tipo_aplicacion = 'D',
   @w_tipo_cobro      = 'A'
end

--SE ANALIZA QUE ESTA COMPARACION ES PARA ENVIAR  LA CANCELACION A apcuotan.sp
--CUANDO ESTA  NO ESTA VENCIDA TOTALMENTE

if (@w_cancelar = 'S') 
  select @w_calcular_new = 'S'


-- SELECCION DEL DIVIDENDO VIGENTE
select @w_div_vigente = di_dividendo
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vigente

if @w_div_vigente is null select @w_div_vigente = 0

if @w_concepto_int = @w_int_fac  select @w_div_vigente = @i_dividendo

if @w_int_ant = @w_concepto_int  and @w_div_vigente > 0 begin
    --ALMACENAR EL VALOR ACUMULADO A LA FECHA ANTES DE CUALQUIER PAGO
    --PARA SER RESTADO DEL VALOR PAGADO Y TENER EL NETO DE LO QUE SE DEBE AMORTIZAR
    select @w_valor_vencido_acum = isnull(sum(am_acumulado - am_pagado ),0)
    from   ca_amortizacion
    where am_operacion = @i_operacionca
    and   am_dividendo = @w_div_vigente
    and   am_concepto  = @w_int_ant
    and   am_secuencia = 1
    
    if @w_valor_vencido_acum > 0
    begin
       insert into ca_valor_acumulado_antant   with (rowlock)
       values  (@i_operacionca,@w_valor_vencido_acum, @i_secuencial_ing, 1)
       
       if @@error <> 0 return 708154
    end
end

/* Calcular monto proyectado */

select @w_saldo_proy = 0
select @w_saldo_proy = SUM(am_cuota + am_gracia - am_pagado)
from   ca_amortizacion, ca_dividendo
where am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   am_operacion = @i_operacionca
and   di_estado    in (1,2)

/* 433 - SI ES REDUCCION DE CUOTA O DE TIEMPO SE GENERA ABONO EXTRAORDINARIO */

IF @i_debug = 'S'
  PRINT '3.1 sp_cartera_abono @w_saldo_proy = ' + convert(varchar(12), @w_saldo_proy) + ' @w_monto_mop = ' + convert(varchar(12), @w_monto_mop) + ' @w_abono_extraordinario = ' + @w_abono_extraordinario + ' @w_pago_especial = ' + @w_pago_especial

if @w_saldo_proy < @w_monto_mop
begin  
   if @w_tipo_reduccion in ('T','C')

      select @w_abono_extraordinario = 'S',
             @w_pago_especial        = 'S'

END

IF @i_debug = 'S'
  PRINT '3.2 sp_cartera_abono @w_abono_extraordinario = ' + @w_abono_extraordinario + ' @w_pago_especial = ' + @w_pago_especial

select @w_tr_tran = 'PAG'

--436: SI ES UN PAGO DE NORMALIZACION DE CARTERA SE ALMACENA INDICADOR PARA GENERACION DE DIFERIDOS EN CASO DE APLICAR
select @w_dias_calc = 0

if @i_es_norm = 'S'
   select @w_dias_calc = -982
   
   IF @i_renovacion = 'S'
		SELECT @i_cuenta_aux = 'RENOVACION'

-- INSERCION DE CABECERA CONTABLE DE CARTERA
insert into ca_transaccion  with (rowlock)(
tr_fecha_mov,         tr_toperacion,     tr_moneda,
tr_operacion,         tr_tran,           tr_secuencial,
tr_en_linea,          tr_banco,          tr_dias_calc,
tr_ofi_oper,          tr_ofi_usu,        tr_usuario,
tr_terminal,          tr_fecha_ref,      tr_secuencial_ref,
tr_estado,            tr_gerente,        tr_gar_admisible,
tr_reestructuracion,  tr_calificacion,   tr_observacion,
tr_fecha_cont,        tr_comprobante)
values(
@w_fc_fecha_cierre,  @w_toperacion,     @w_moneda_op,
@w_operacionca,      @w_tr_tran,        @w_secuencial_pag,
@i_en_linea,         @w_banco,          @w_dias_calc,
@w_oficina_op,       @w_oficina_orig,   @s_user,
@s_term,             @w_fecha_proceso,  isnull(@i_sec_desem_renova, @w_secuencial_rpa), --RENOVACION
'ING',               @w_gerente,        isnull(@w_gar_admisible,''),
@w_reestructuracion, @w_calificacion,   isnull(@i_cuenta_aux, ''),
@s_date,             0)

if @@error <> 0 return 708165 

-- INSERCION DE CUENTA PUENTE PARA LA APLICACION DEL PAGO
if @w_monto_mop > 0 begin
   insert into ca_det_trn  with (rowlock)(
   dtr_secuencial,    dtr_operacion,  dtr_dividendo,
   dtr_concepto,      dtr_estado,     dtr_periodo,
   dtr_codvalor,      dtr_monto,      dtr_monto_mn,
   dtr_moneda,        dtr_cotizacion, dtr_tcotizacion,
   dtr_afectacion,    dtr_cuenta,     dtr_beneficiario,
   dtr_monto_cont)
   select 
   @w_secuencial_pag, @w_operacionca, dtr_dividendo,
   dtr_concepto,      dtr_estado,     dtr_periodo,
   dtr_codvalor,      dtr_monto,      dtr_monto_mn,
   dtr_moneda,        dtr_cotizacion, dtr_tcotizacion,
   'D',               dtr_cuenta,     dtr_beneficiario,
   dtr_monto_cont
   from   ca_det_trn
   where  dtr_secuencial = @w_secuencial_rpa
   and    dtr_operacion  = @w_operacionca
   AND    dtr_dividendo  = 0  --LPO CDIG Evitar duplicados cuando la forma de Pago es Cuenta Puente
   --and    dtr_concepto like 'VAC_%'
   and    dtr_concepto like 'VAC%'
   
   if @@error <> 0 return 710036    

   -- INSERTAR EL REGISTRO DE LAS FORMAS DE PAGO PARA ca_abono_rubro
   insert into ca_abono_rubro  with (rowlock)(
   ar_fecha_pag,    ar_secuencial,     ar_operacion,
   ar_dividendo,    ar_concepto,       ar_estado,
   ar_monto,        ar_monto_mn,       ar_moneda,
   ar_cotizacion,   ar_afectacion,     ar_tasa_pago,
   ar_dias_pagados)
   select 
   @s_date,         @w_secuencial_pag, @w_operacionca,
   dtr_dividendo,   @w_fpago,          dtr_estado,
   dtr_monto,       dtr_monto_mn,      dtr_moneda,
   dtr_cotizacion,  'D',               0,
   0
   from   ca_det_trn
   where  dtr_secuencial = @w_secuencial_rpa    ---FORMA DE PAGO DEL CLIENTE
   and    dtr_operacion  = @w_operacionca
   and    dtr_afectacion = 'D'
   
   if @@error <> 0 return 710404
   
end 

/* REALIZA EL PAGO DE LOS INTERESES DE MORA DE LA OBLIGACION CUANDO EL TIPO DE REDUCCION ES M */
if @w_tipo_reduccion = 'M'
begin
   exec @w_error =  sp_aplica_mora
   @s_sesn               = @s_sesn,
   @s_user               = @s_user,
   @s_term               = @s_term,
   @s_date               = @s_date,
   @s_ofi                = @s_ofi,
   @i_fecha_proceso      = @i_fecha_proceso,
   @i_operacionca        = @w_operacionca,
   @i_monto_pago         = @w_monto_sobrante,
   @i_cotizacion         = @w_cotizacion,
   @i_cotizacion_dia_sus = @w_cotizacion_dia_sus,
   @i_secuencial_pag     = @w_secuencial_pag,
   @i_en_linea           = @i_en_linea,
   @o_sobrante_pago      = @w_monto_sobrante out
   
   if @@error <> 0 return 708201
   if @w_error <> 0 return @w_error
   if @w_monto_sobrante <> 0 return 724029 --SI EXISTE MONTO SOBRANTE   
end

/* DETERMINAR LA FORMA DE PAGO */
select @w_fpago = abd_concepto
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing 
and    abd_operacion      = @w_operacionca
and    abd_tipo = 'PAG'

-- APLICACION DE CONDONACIONES
-- REQ 089 - ACUERDO DE PAGO - SE REHABILITA PARA PAGO COMBINADO (PAGO+CONDONACION)

if @w_tipo_aplicacion <> 'O'
and exists (select 1 from ca_abono_det
where  abd_operacion = @w_operacionca
and    abd_secuencial_ing = @i_secuencial_ing
and    abd_tipo = 'CON')
begin
   exec @w_error = sp_abono_condonaciones
   @s_ofi            = @s_ofi,
   @s_sesn           = @s_sesn,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @i_secuencial_ing = @i_secuencial_ing,
   @i_secuencial_pag = @w_secuencial_pag,
   @i_secuencial_rpa = @w_secuencial_rpa,   
   @i_fecha_pago     = @i_fecha_proceso,
   @i_div_vigente    = @w_div_vigente,
   @i_en_linea       = @i_en_linea,
   @i_tipo_cobro     = @w_tipo_cobro_con,
   @i_dividendo      = @i_dividendo,
   @i_operacionca    = @w_operacionca,
   @i_cancela        = @w_cancelar,
   @i_num_dec        = @w_num_dec_op
   
   if @w_error <> 0 return @w_error
   
   select @w_existe_condonacion  = 'S'  -- KDR Si se realizó una condonación, terminar proceso
   
end

select  @w_sec_pago_ant = ab_secuencial_pag
from ca_abono
where  ab_secuencial_ing = @i_secuencial_ing
and    ab_operacion      = @w_operacionca

-- MARCAR COMO APLICADO EL ABONO
update ca_abono  with (rowlock)
set    ab_estado         = 'A',
       ab_secuencial_pag = @w_secuencial_pag,
  ab_tipo_reduccion = @w_tipo_reduccion,
       ab_tipo_cobro     = @w_tipo_cobro
where  ab_secuencial_ing = @i_secuencial_ing
and    ab_operacion      = @w_operacionca

if @@error <> 0 return 705048

if @w_existe_condonacion  = 'S'
   return 0

-- DETERMINACION DEL SALDO DE CAPITAL PARA PODER CALCULAR DIAS ENTEROS
-- EN APLICACION DE PAGOS DE INTERESES
select @w_saldo_capital = sum(am_cuota + am_gracia - am_pagado)
from   ca_amortizacion, ca_rubro_op
where  am_operacion  = @w_operacionca
and    ro_operacion  = @w_operacionca
and    am_concepto   = ro_concepto
and    ro_tipo_rubro = 'C' -- CAPITALES

select @w_saldo_capital = round(@w_saldo_capital, @w_num_dec_op)

---SOLO PARA CAPITAL
if (@w_tipo_aplicacion = 'P') begin
   update ca_abono_prioridad  with (rowlock)
   set    ap_prioridad = ap_prioridad + 100
   where  ap_operacion      = @i_operacionca
   and    ap_secuencial_ing = @i_secuencial_ing
   and    ap_prioridad = 0
   
   if @@error <> 0 return 708152
   
   update ca_abono_prioridad  with (rowlock)
   set    ap_prioridad = 0
   where  ap_operacion      = @i_operacionca
   and    ap_secuencial_ing = @i_secuencial_ing
   and    ap_concepto = @w_rubro_cap
   
   if @@error <> 0 return 708152
   
   select @w_saldo_rubro = sum(am_acumulado + am_gracia - am_pagado)
   from   ca_amortizacion
   where  am_operacion = @i_operacionca
   and    am_concepto  = @w_rubro_cap
   
   select @w_saldo_rubro = isnull(@w_saldo_rubro,0)
   
   if @w_monto_sobrante > @w_saldo_rubro return 710442
   exec @w_error = sp_aplicacion_proporcional
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_operacionca    = @w_operacionca,
   @i_secuencial_pag = @w_secuencial_pag,
   @i_monto_pago     = @w_monto_sobrante,
   @i_moneda         = @w_moneda_ab,
   @i_cotizacion     = @w_cotizacion,
   @i_num_dec        = @w_num_dec_op,
   @i_fpago          = @w_fpago,
   @i_en_linea       = @i_en_linea,
   @i_banco          = @w_banco,
   @i_fecha_proceso  = @i_fecha_proceso,
   @o_sobrante       = @w_monto_sobrante out
   
   if @@error <> 0 return 708152
   if @w_error <> 0  return @w_error   
   ---NR-504  sp_tmp_prepagos_causal_11
 
   return 0    -- IFJ 25/Ene/2006 ICR
end


-- NUEVA APLICACION DE CONDONACIONES
if (@w_tipo_aplicacion = 'O') begin
   select @w_cotizacion_dia_sus = isnull(@w_cotizacion_dia_sus, @w_cotizacion)
   select @w_error = 0
 
   exec @w_error = sp_condonacion
   @s_sesn               = @s_sesn,
   @s_ssn                = @s_ssn,
   @s_user               = @s_user,
   @s_date               = @s_date,
   @s_ofi                = @s_ofi,
   @s_term               = @s_term,
   @i_operacionca        = @w_operacionca,        -- NUMERO OBLIGACION QUE RECIBE LA CONDONACION
   @i_en_linea           = @i_en_linea,
   @i_secuencial_ing     = @i_secuencial_ing,
   @i_secuencial_pag     = @w_secuencial_pag,
   @i_cotizacion         = @w_cotizacion,
   @i_cotizacion_dia_sus = @w_cotizacion_dia_sus,
   @i_num_dec_op         = @w_num_dec_op,
   @i_num_dec_mn         = @w_num_dec_n
   
   if @@error <> 0 return 708201
   if @w_error <> 0  return @w_error

   select @w_monto_sobrante = 0
end

-- NUEVA APLICACION A SUSPENSOS
if (@w_tipo_aplicacion = 'S') begin
   select @w_cotizacion_dia_sus = isnull(@w_cotizacion_dia_sus, @w_cotizacion)
   select @w_error = 0
   
   select @w_monto_sobrante = abd_monto_mop
   from   ca_abono_det
   where  abd_operacion      = @w_operacionca
   and    abd_secuencial_ing = @i_secuencial_ing
   and    abd_tipo           = 'PAG'

   exec @w_error = sp_pago_suspenso
   @s_sesn               = @s_sesn,
   @s_ssn                = @s_ssn,
   @s_user               = @s_user,
   @s_date               = @s_date,
   @s_ofi                = @s_ofi,
   @s_term               = @s_term,
   @i_operacionca        = @w_operacionca,        -- NUMERO OBLIGACION QUE RECIBE LA CONDONACION
   @i_secuencial_ing     = @i_secuencial_ing,
   @i_secuencial_pag     = @w_secuencial_pag,
   @i_cotizacion         = @w_cotizacion,
   @i_num_dec_op         = @w_num_dec_op,
   @i_num_dec_mn         = @w_num_dec_n,
   @i_monto_pago         = @w_monto_sobrante,
   @o_sobrante           = @w_monto_sobrante OUT
   
   if @@error <> 0  return 708201
   if @w_error <> 0  return @w_error   
 end
 
 IF @w_monto_residuo = 0 --LPO TEC Es una precancelacion, NUEVA DEFINCION, EN UNA PRECANCELACION PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
    SELECT @w_es_precancelacion = 'S'
 ELSE
    SELECT @w_es_precancelacion = 'N'
    
 IF @i_debug = 'S'
   PRINT '3.3 sp_cartera_abono @w_monto_residuo = ' + convert(varchar(12), @w_monto_residuo) + ' @w_es_precancelacion = ' + @w_es_precancelacion

 IF @i_debug = 'S'
   PRINT '4.1 sp_cartera_abono @w_tipo_aplicacion = ' + @w_tipo_aplicacion + ' @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante) + ' @w_calcular_new = ' + @w_calcular_new + ' @w_cancelar = ' + @w_cancelar
    
-- APLICACION POR RUBROS
if (@w_tipo_aplicacion not in ('D', 'P', 'S', 'O')) and (@w_monto_sobrante > 0)  and (@w_calcular_new = 'N')  and (@w_cancelar = 'N') begin
   exec @w_error = sp_aplicacion_concepto
   @s_sesn               = @s_sesn,
   @s_user               = @s_user,
   @s_term               = @s_term,
   @s_date               = @s_date,
   @s_ofi                = @s_ofi,
   @i_secuencial_ing     = @i_secuencial_ing,
   @i_secuencial_pag     = @w_secuencial_pag,
   @i_fecha_proceso      = @i_fecha_proceso,
   @i_operacionca        = @w_operacionca,
   @i_en_linea           = @i_en_linea,
   @i_tipo_reduccion     = @w_tipo_reduccion,
   @i_tipo_aplicacion    = @w_tipo_aplicacion,
   @i_tipo_cobro         = @w_tipo_cobro,
   @i_monto_pago         = @w_monto_sobrante,
   @i_cotizacion         = @w_cotizacion,
   @i_tcotizacion        = @w_tcotizacion,
   @i_num_dec            = @w_num_dec_op,
   @i_num_dec_n          = @w_num_dec_n,
   @i_saldo_capital      = @w_saldo_capital,
   @i_solo_capital       = @i_solo_capital,
   @i_tipo_tabla         = @w_tipo_tabla,
   @i_cotizacion_dia_sus = @w_cotizacion_dia_sus,
   @i_abono_extraordinario = @w_abono_extraordinario,
   @i_es_precancelacion  = @w_es_precancelacion, --LPO TEC NUEVA DEFINCION, EN UNA PRECANCELACION PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
   @i_abn_rubs_completos = 'S',                   -- KDR, Para abonar todos los rubros ante un abono extraordinario.
   @o_sobrante           = @w_monto_sobrante OUT
   
   if @@error <> 0 
     return 708201
     
   if @w_error <> 0 
     return @w_error   
     
   if @w_monto_sobrante > 0
   begin
   
      select @w_tipo_empleado = pa_char
	  from  cobis..cl_parametro
	  where pa_producto = 'MIS'
	  and   pa_nemonico = 'TIPFUN'
	  
	  select @w_tipo_persona    = p_tipo_persona
      from   cobis..cl_ente 
      where  en_ente = @w_cliente
	  
   end 
END

IF @i_debug = 'S'
  PRINT '4.2 sp_cartera_abono @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante) + ' @w_aceptar_anticipos = ' + @w_aceptar_anticipos + ' @w_tipo_aplicacion = ' + @w_tipo_aplicacion + ' @w_tipo_cobro = ' + @w_tipo_cobro + ' @w_tipo_reduccion = ' + @w_tipo_reduccion

-- APLICACION DEL PAGO POR CUOTAS O DIVIDENDOS

IF @i_debug = 'S'
  PRINT '5.1 sp_cartera_abono @w_tipo_aplicacion = ' + @w_tipo_aplicacion + ' @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante) + ' @w_calcular_new = ' + @w_calcular_new + ' @w_cancelar = ' + @w_cancelar + ' @w_tipo_aplicacion = ' + @w_tipo_aplicacion

if (@w_tipo_aplicacion = 'D') and (@w_monto_sobrante > 0) and (@w_calcular_new = 'N') and (@w_cancelar = 'N') and @w_tipo_aplicacion <> 'C' begin
   select @w_monto_vencido = isnull(sum (am_acumulado - am_pagado), 0)
   from   ca_amortizacion, ca_dividendo
   where  am_operacion = @w_operacionca
   and    am_operacion = di_operacion
   and    am_dividendo = di_dividendo
   and    di_estado    = @w_est_vencido
   
   select @w_vencido_ant  = isnull(sum (am_acumulado - am_pagado), 0)
   from   ca_amortizacion, ca_dividendo, ca_rubro_op
   where  am_operacion = @w_operacionca
   and    am_operacion = di_operacion
   and    am_dividendo = di_dividendo
   and    di_dividendo = @w_div_vigente
   and    am_operacion = ro_operacion
   and    am_concepto  = ro_concepto
   and    ro_fpago     = 'A'
   
   if  @w_vencido_ant < 0  --- No hay valor vencido
       select  @w_vencido_ant = 0
   
   select @w_monto_vencido = @w_monto_vencido + @w_vencido_ant

  -- PAGO POR CUOTAS 

   exec @w_error = sp_aplicacion_cuota
   @s_sesn               = @s_sesn,
   @s_user               = @s_user,
   @s_term               = @s_term,
   @s_date               = @s_date,
   @s_ofi                = @s_ofi,
   @i_secuencial_ing     = @i_secuencial_ing,
   @i_secuencial_pag     = @w_secuencial_pag,
   @i_fecha_proceso      = @i_fecha_proceso,
   @i_operacionca        = @w_operacionca,
   @i_en_linea           = @i_en_linea,
   @i_tipo_reduccion     = @w_tipo_reduccion,
   @i_tipo_cobro         = @w_tipo_cobro,
   @i_monto_pago         = @w_monto_sobrante,
   @i_cotizacion         = @w_cotizacion,
   @i_tcotizacion        = @w_tcotizacion,
   @i_num_dec            = @w_num_dec_op,
   @i_num_dec_n          = @w_num_dec_n,
   @i_saldo_capital      = @w_saldo_capital,
   @i_dias_anio          = @w_dias_anio,
   @i_base_calculo       = @w_base_calculo,
   @i_tipo               = @w_tipo,
   @i_aceptar_anticipos  = @w_aceptar_anticipos,
   @i_tasa_prepago       = @w_tasa_prepago,
   @i_dividendo          = @i_dividendo, 
   @i_monto_vencido      = @w_monto_vencido,
   @i_cancela            = @w_cancelar,
   @i_cotizacion_dia_sus = @w_cotizacion_dia_sus,
   @i_tiene_reco         = @w_tiene_reco,
   @i_abono_extraordinario = 'N',--@w_abono_extraordinario,
   @i_simulado             = @i_simulado,
   @i_canal_inter	       =@i_canal_inter,
   @i_es_precancelacion  = @w_es_precancelacion, --LPO TEC NUEVA DEFINCION, EN UNA PRECANCELACION PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
   @o_sobrante           = @w_monto_sobrante out     
   
   if @@error <> 0 return 708201
   if @w_error <> 0 return @w_error

end   

IF @i_debug = 'S'
  PRINT '5.2 sp_cartera_abono @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante)

-- SELECCION DEL DIVIDENDO VIGENTE
select @w_di_dividendo = di_dividendo
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_vigente

if @@rowcount = 0 
   select @w_di_dividendo = -1

---PARA LAS PASIVAS EL DIA DE LA CANCELACION DEBE APLICAR POR ESTA OPCION   
if @w_tipo = 'R' and  @w_cancelar = 'S'
   select @w_aceptar_anticipos = 'S'   
   
-- APLICAR PAGOS EXTRAORDINARIOS DE REDUCCION DE CUOTA O TIEMPO
if (@w_aceptar_anticipos = 'N') and (@w_monto_sobrante >= @w_vlr_despreciable) and @w_tipo_aplicacion <> 'S'
  return 710435

if @w_abono_extraordinario = 'S' and @w_tipo_reduccion not in ('T', 'C') 
   select @w_tipo_reduccion = 'T'

if @w_tipo_reduccion in ('T', 'C') 
   select @w_tipo_cobro = 'A'

IF @i_debug = 'S'   
  PRINT '6.1 antes abono extra o pago normal sp_cartera_abono @w_aceptar_anticipos = ' + @w_aceptar_anticipos + ' @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante) + ' @w_vlr_despreciable = ' + convert(varchar(12), @w_vlr_despreciable)
  
if @w_aceptar_anticipos = 'S' and @w_monto_sobrante >= @w_vlr_despreciable 
  begin
    select @w_abono_extraordinario = 'S'
	
    -- Si el préstamo es migrado, si tiene gracia en cuotas no vigentes, si es abono extraodrinario
    -- y si esta activo (S) el control de abonos extraordnarios, no se aplica el pago.
    if @w_op_migrada is not null 
       and exists (select 1 from ca_amortizacion, ca_dividendo
                   where am_operacion = @w_operacionca 
    			   and am_operacion = di_operacion
    			   and am_dividendo = di_dividendo
    			   and di_estado   in (@w_est_novigente)
    			   and am_gracia    <> 0)
       and @w_control_abn_extra = 'S'
    begin
       select @w_error = 725307 -- NO SE PUEDE APLICAR PAGO A OPERACION MIGRADA CON VALORES REFINANCIADOS, CONTACTAR A SOPORTE OPERATIVO.
       return @w_error
    end
   
    --SE ANALIZA EL NUMERO DE CUOTAS PENDIENTE PARA SABER SI SE HACE REDUCCION DE T o C
    --O REDUCCION NORMAL I ESTE ES > 2  SE HACE REDUCCION  QUE VIENE SINO SE VA POR
    --NORMAL
   
    --SI LAS CUOTAS PENDIENTES SON
    select @w_nro_cuotas_pendientes = count(1)
    from   ca_dividendo
    where  di_operacion = @w_operacionca
    and    di_estado   in (1,0)

    --VALIDAR SI HAY SALDO DE CAPITAL PARA HACER ABONO EXTRA
    select @w_saldo_cap = sum(am_cuota - am_pagado)
    from ca_amortizacion
    where am_operacion = @w_operacionca
    and   am_concepto  = @w_rubro_cap         
    and   am_estado    <> @w_est_cancelado
   
   
    if  @w_tipo_reduccion   in ('T', 'C')
       and @w_cancelar     = 'N'
       and @w_di_dividendo > 0
       and @w_nro_cuotas_pendientes >= 2
       and @w_saldo_cap > 0
      begin 
	  	
        -- SELECCION DEL DIVIDENDO VIGENTE
        select @w_di_dividendo = di_dividendo
        from   ca_dividendo
        where  di_operacion =  @w_operacionca
        and    di_estado    =  @w_est_vigente
      
        if @@rowcount = 0
          return 710090
		  
		if @w_div_vigente <> @w_di_dividendo
		   select @w_di_dividendo = @w_div_vigente
	 
        select  @w_evento_campana  = 'EXT'    --Req. 300
         
        -- REDUCIR CUOTAS ADICIONALES
        exec @w_error = sp_reduccion_cuota_adicional
             @i_operacion      = @w_operacionca,
             @i_monto_sobrante = @w_monto_sobrante
      
        if @@error <> 0 
          return 708201
          
        if @w_error <> 0 
          return @w_error
	  
	    --GFP 22/04/2022 Validacion para operaciones migradas y con tabla de amortizacion manual
        if exists (select 1 from ca_operacion where op_operacion = @w_operacionca and op_migrada is not null and op_tipo_amortizacion = 'MANUAL' )
          return 725151

        -- APLICACION DEL ABONO EXTRAORDINARIO
        
        IF @i_debug = 'S'
          PRINT '6.1.1 antes abono extra sp_cartera_abono @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante)		  

        exec @w_error = sp_abono_extraordinario
        @s_ssn                = @s_ssn,
        @s_sesn               = @s_sesn,
        @s_user               = @s_user,
        @s_term               = @s_term,
        @s_date               = @s_date,
        @s_ofi                = @s_ofi,
        @s_srv                = @s_srv,
        @s_lsrv               = @s_lsrv,
        @i_secuencial_ing     = @i_secuencial_ing,
        @i_secuencial_pag     = @w_secuencial_pag,
        @i_fecha_proceso      = @i_fecha_proceso,
        @i_operacion          = @w_operacionca,
        @i_en_linea           = @i_en_linea,
        @i_tipo_reduccion     = @w_tipo_reduccion,
        @i_tipo_aplicacion    = @w_tipo_aplicacion,
        @i_monto_pago         = @w_monto_sobrante, 
        @i_cotizacion         = @w_cotizacion,
        @i_tcotizacion        = @w_tcotizacion,
        @i_num_dec            = @w_num_dec_op,
        @i_num_dec_n          = @w_num_dec_n,
        @i_dividendo          = @w_di_dividendo,
        @i_tipo_tabla         = @w_tipo_tabla,
        @i_tiene_reco         = @w_tiene_reco,
        @i_pago_especial      = @w_pago_especial,
        @i_tipo_amortizacion  = @w_tipo_amortizacion,
        @i_es_precancelacion  = @w_es_precancelacion, --LPO TEC NUEVA DEFINCION, EN UNA PRECANCELACION PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO      
        @o_monto_sobrante     = @w_monto_sobrante OUT     
      
        if @@error <> 0 
          return 708201
        
        if @w_error <> 0 
          return @w_error
        
        IF @i_debug = 'S'  
          PRINT '6.1.2 despues abono extra sp_cartera_abono @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante)
      end
    else 
      begin
        select @w_tipo_reduccion = 'N'
     
        if (@w_tipo_reduccion  = 'N') or (@w_cancelar = 'S') begin ---Pago Extraordinario Normal o precancelacion
           select @w_saldo_restante = @w_saldo_oper - @w_monto_mop + @w_monto_sobrante
          
        if @w_cancelar = 'S'
           select @w_monto_sobrante = @w_monto_sobrante - @w_monto_condonado
                  
        select @w_saldo_restante = @w_saldo_restante - @w_monto_condonado
        
        IF @i_debug = 'S'
          PRINT '6.1.3 antes pago normal sp_cartera_abono @w_cancelar = ' + @w_cancelar + ' @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante) + ' @w_saldo_restante = ' + convert(varchar(12), @w_saldo_restante)

        exec @w_error = sp_aplicacion_cuota_normal
        @s_sesn               = @s_sesn,
        @s_user               = @s_user,
        @s_term               = @s_term,
        @s_date               = @s_date,
        @s_ofi                = @s_ofi,
        @i_secuencial_ing     = @i_secuencial_ing,
        @i_secuencial_pag     = @w_secuencial_pag,
        @i_fecha_proceso      = @i_fecha_proceso,
        @i_operacionca        = @w_operacionca,
        @i_en_linea           = @i_en_linea,
        @i_tipo_reduccion     = @w_tipo_reduccion,
        @i_tipo_reduccion_orig = @w_tipo_reduccion_orig, -- AMO 20220610
        @i_debug			  = @i_debug, -- AMO 20220610
        @i_tipo_cobro         = @w_tipo_cobro,
        @i_monto_pago         = @w_monto_sobrante,
        @i_cotizacion         = @w_cotizacion,
        @i_tcotizacion        = @w_tcotizacion,
        @i_num_dec            = @w_num_dec_op,
        @i_num_dec_n          = @w_num_dec_n,
        @i_saldo_capital      = @w_saldo_capital,
        @i_dias_anio          = @w_dias_anio,
        @i_base_calculo       = @w_base_calculo,
        @i_tipo               = @w_tipo,
        @i_aceptar_anticipos  = @w_aceptar_anticipos,
        @i_tasa_prepago       = @w_tasa_prepago,
        @i_dividendo          = @i_dividendo,     -----PARA DESCUENTO DOCUMENTOS
        @i_saldo_oper         = @w_saldo_restante,
        @i_cancelar           = @w_cancelar,
        @i_cotizacion_dia_sus = @w_cotizacion_dia_sus,
        @i_en_gracia_int      = @w_en_gracia_int,
        @i_tiene_reco         = @w_tiene_reco,
        @i_tipo_tabla         = @w_tipo_tabla,
        @i_tipo_amortizacion  = @w_tipo_amortizacion,
        @i_es_precancelacion  = @w_es_precancelacion, --LPO TEC NUEVA DEFINCION, EN UNA PRECANCELACION PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
        @o_sobrante           = @w_monto_sobrante OUT
         
        if @@error <> 0 
          return 708201
          
        if @w_error <> 0 
          return @w_error        

        IF @i_debug = 'S'
          PRINT '6.1.4 despues pago normal sp_cartera_abono @w_monto_sobrante = ' + convert(varchar(12), @w_monto_sobrante)

      end
   end
end

--LAS PASIVAS NO DEBEN GENERAR SOBRANTE MAYOR AL LIMITE DE AJUSTE FCONTABLE PARA ESTA MONEDA

if @w_monto_sobrante >= @w_vlr_despreciable and @w_op_naturaleza = 'P' and  @w_moneda_op = @w_moneda_mn
   return 710511
   
if @w_monto_sobrante >= @w_limite_ajuste and @w_op_naturaleza = 'P' and  @w_moneda_op <> @w_moneda_mn
   return 710511
   
if @w_monto_sobrante < @w_limite_ajuste and @w_op_naturaleza = 'P' and  @w_moneda_op <> @w_moneda_mn
   select @w_monto_sobrante = 0


-- INSERCION DE CA_ABONO_DET  PARA SOBRANTE AUTOMATICO
select @w_fpago = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'SOBAUT'

select @w_fpago_sobrante = isnull(@w_fpago, '')
      
--EPB:15MAR2004
if exists (select 1
           from   ca_abono_det
           where  abd_secuencial_ing = @i_secuencial_ing
           and    abd_operacion      = @w_operacionca
           and    abd_tipo           = 'SOB'
           and    abd_concepto       = @w_fpago)
   select @w_fpago = @w_fpago
else begin

   if @w_monto_sobrante >= @w_vlr_despreciable   begin

      insert into ca_abono_det  with (rowlock)
            (abd_secuencial_ing,    abd_operacion,         abd_tipo,            
             abd_concepto ,         abd_cuenta,            abd_beneficiario,
             abd_moneda,            abd_monto_mpg,         abd_monto_mop,         
             abd_monto_mn,          abd_cotizacion_mpg,    abd_cotizacion_mop,
             abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,           
             abd_cod_banco,         abd_inscripcion,       abd_carga,
			 abd_solidario)                                                 --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      values(@i_secuencial_ing,     @w_operacionca,        'SOB',                
             @w_fpago,              '',                    'DEVOLUCION SALDO PAGAR MAYOR AL DE CANCELACION',                                     
             0,                     0,                     0,                     
             0,                     1,                     1,
             'C',                   'C',                   null,                 
             null,                  null,                  null,
			 'N')
      
      if @@error <> 0 
	  begin
         return 710295
      end
   end
end --EXISTE EL SOB

-- SOBRANTE AUTOMATICOS
if (@w_moneda_op = @w_moneda_mn and @w_monto_sobrante >= @w_vlr_despreciable)
   or (@w_moneda_op <> @w_moneda_mn and @w_monto_sobrante >= @w_vlr_despreciable)
begin
   select 
   @w_fpago      = abd_concepto,
   @w_cuenta     = abd_cuenta,
   @w_moneda_pag = abd_moneda,
   @w_abd_cuenta = abd_cuenta
   from   ca_abono_det
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @w_operacionca
   and    abd_tipo           = 'SOB'
   
   if @@rowcount = 0
      return 710115
   
   -- CONVERSION DEL MONTO CALCULADO A LA MONEDA DE PAGO Y OPERACION
   exec @w_error = sp_conversion_moneda
   @s_date             = @i_fecha_proceso,
   @i_opcion           = 'L',
   @i_moneda_monto     = @w_moneda_op,
   @i_moneda_resultado = @w_moneda_pag,
   @i_monto            = @w_monto_sobrante,
   @i_fecha            = @i_fecha_proceso,
   @o_monto_resultado  = @w_abd_monto_mpg out,
   @o_tipo_cambio      = @w_abd_cotizacion_mpg out
   
   if @@error <> 0 return 708201
   if @w_error <> 0 return @w_error
 
   exec @w_error = sp_conversion_moneda
   @s_date             = @i_fecha_proceso,
   @i_opcion           = 'L',
   @i_moneda_monto     = @w_moneda_op,
   @i_moneda_resultado = @w_moneda_mn,
   @i_monto            = @w_monto_sobrante,
   @i_fecha            = @i_fecha_proceso,
   @o_monto_resultado  = @w_abd_monto_mn out,
   @o_tipo_cambio      = @w_cot_moneda out
   
   if @@error <> 0 return 708201
   if @w_error <> 0 return @w_error
     
   update ca_abono_det  with (rowlock)
   set    abd_monto_mop = @w_monto_sobrante,
          abd_monto_mpg = @w_abd_monto_mn,
          abd_monto_mn  = @w_abd_monto_mn,
          abd_cotizacion_mop =   @w_cot_moneda
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @w_operacionca
   and    abd_tipo           = 'SOB'
   
   if @@error <> 0 return 708152

   --* INSERCION DEL DETALLE DE LA TRANSACCION
   insert into ca_det_trn  with (rowlock)
         (dtr_secuencial,            dtr_operacion,     dtr_dividendo,
          dtr_concepto,              dtr_estado,        dtr_periodo, 
          dtr_codvalor,              dtr_monto,         dtr_monto_mn,
          dtr_moneda,                dtr_cotizacion,    dtr_tcotizacion,
          dtr_afectacion,            dtr_cuenta,        dtr_beneficiario,
          dtr_monto_cont)
   select @w_secuencial_pag,         @w_operacionca,    -1,
          @w_fpago,                  0,                 0,
          cp_codvalor,               @w_monto_sobrante, @w_abd_monto_mn,
          @w_moneda_op,              1,                 'N',
          isnull(cp_afectacion, 'C'), @w_cuenta,         '',
          0
   from   ca_producto
   where  cp_producto = @w_fpago
   
   if @@error <> 0  return 710001
      
   select @w_monto_sobrante = 0
end

-- SI EXISTE EXCESO ENTONCES ERROR
if @w_monto_sobrante >= @w_vlr_despreciable
   return 710109
   
-- SI EL PAGO ES DE RECAUDO Y CONTIENE COMISION E IVA DE COMISION
select @w_fpago = abd_concepto
from   ca_abono_det
where  abd_secuencial_ing = @i_secuencial_ing 
and    abd_operacion      = @w_operacionca
and    abd_tipo = 'PAG'

if @w_abd_cuenta is not null and @w_abd_cuenta <> ' ' and @w_abd_cuenta <> ''
   select @w_fpago = @w_abd_cuenta

insert into ca_det_trn  with (rowlock)
      (dtr_secuencial,                    dtr_operacion,     dtr_dividendo,
       dtr_concepto,                      dtr_estado,        dtr_periodo, 
       dtr_codvalor,                      dtr_monto,         dtr_monto_mn,
       dtr_moneda,                        dtr_cotizacion,    dtr_tcotizacion,
       dtr_afectacion,                    dtr_cuenta,        dtr_beneficiario,
       dtr_monto_cont)                    
select @w_secuencial_pag,                 @w_operacionca,    -1,
       @w_com_banco,                      0,                 0,
       (co_codigo * 1000) + (1*10) + (0), cr_comision_ban,   cr_comision_ban,
       @w_moneda_op,                      1,                 'N',
       'C',                               @w_fpago,         '',
       0
from   ca_concepto, ca_comision_recaudo
where  cr_secuencial_ing = @i_secuencial_ing
and    cr_operacion      = @w_operacionca
and    co_concepto       = @w_com_banco
and    cr_comision_ban   > 0
if @@error <> 0 return 708154

insert into ca_det_trn  with (rowlock)
      (dtr_secuencial,                    dtr_operacion,     dtr_dividendo,
       dtr_concepto,                      dtr_estado,        dtr_periodo, 
       dtr_codvalor,                      dtr_monto,         dtr_monto_mn,
       dtr_moneda,                        dtr_cotizacion,    dtr_tcotizacion,
       dtr_afectacion,                    dtr_cuenta,        dtr_beneficiario,
       dtr_monto_cont)                    
select @w_secuencial_pag,                 @w_operacionca,    -1,
       @w_com_canal,                      0,                 0,
       (co_codigo * 1000) + (1*10) + (0), cr_comision_can,   cr_comision_can,
       @w_moneda_op,                      1,                 'N',
       'C',                               @w_fpago,          '',
       0
from   ca_concepto, ca_comision_recaudo
where  cr_secuencial_ing = @i_secuencial_ing
and    cr_operacion      = @w_operacionca
and    co_concepto       = @w_com_canal
and    cr_comision_can   > 0
if @@error <> 0 return 708154

insert into ca_det_trn  with (rowlock)
      (dtr_secuencial,                    dtr_operacion,     dtr_dividendo,
       dtr_concepto,                      dtr_estado,        dtr_periodo, 
       dtr_codvalor,                      dtr_monto,         dtr_monto_mn,
       dtr_moneda,                        dtr_cotizacion,    dtr_tcotizacion,
       dtr_afectacion,                    dtr_cuenta,        dtr_beneficiario,
       dtr_monto_cont)                    
select @w_secuencial_pag,                 @w_operacionca,    -1,
       @w_iva_com_can,                    0,                 0,
       (co_codigo * 1000) + (1*10) + (0), cr_iva_comision,   cr_iva_comision,
       @w_moneda_op,                      1,                 'N',
       'C',  @w_fpago,          '',
       0
from   ca_concepto, ca_comision_recaudo
where  cr_secuencial_ing = @i_secuencial_ing
and    cr_operacion      = @w_operacionca
and    co_concepto       = @w_iva_com_can
and    cr_iva_comision   > 0
if @@error <> 0 return 708154

if @i_en_linea = 'S' and @w_tipo <> 'R' begin
   exec @w_error = sp_valor_atx_mas
        @s_user  = @s_user,
        @s_date  = @s_date,
        @i_banco = @w_banco
   
        if @@error <> 0 return 708201
        if @w_error <> 0 return @w_error
end


/* RUTINA PARA AJUSTAR EL MONTO DE PAGO PARA EVITAR QUE LA OPERACION QUEDE VENCIDA POR UN MONTO MINIMO */
/*if @w_tipo_reduccion not in ('C','T')  
   and @w_cancelar = 'N'
   and not exists (select 1 from ca_abono_det
            where abd_tipo  = 'CON'
           and   abd_operacion      = @i_operacionca 
           and   abd_secuencial_ing = @i_secuencial_ing)

 begin 

   exec @w_error        = sp_saldos_minimos
   @s_date              = @s_date,
   @s_user              = @s_user,
   @s_sesn              = @s_sesn,
   @i_pago_cuota        = 'S',
   @i_secuencial_ing    = @i_secuencial_ing,
   @i_secuencial_pag    = @w_secuencial_pag,
   @i_operacionca       = @i_operacionca,
   @i_op_estado         = @w_op_estado,
   @i_monto_cancelacion = 0,
   @i_monto_pago        = 0
  
   if @@error <> 0 return 708201
   if @w_error <> 0 return  @w_error
    
end*/
    
--PARA ACTUALIZAR VALORES EN GARANTIAS Y CUPO DE CREDITO - DIFERIDOS
if exists (select 1
           from   ca_det_trn 
           where  dtr_secuencial = @w_secuencial_pag 
           and    dtr_operacion  = @w_operacionca
           and    dtr_concepto   = @w_rubro_cap)
begin
   select @w_monto_gar = isnull(sum(dtr_monto),0)
   from   cob_cartera..ca_det_trn
   where  dtr_operacion  = @w_operacionca
   and    dtr_secuencial = @w_secuencial_pag
   and    dtr_concepto   = @w_rubro_cap
   and    dtr_codvalor  <> 10099
   and    dtr_codvalor  <> 10019
   and    dtr_codvalor  <> 10990
   and    dtr_codvalor  <> 10017
   and    dtr_codvalor  <> 10027
   and    dtr_codvalor  <> 10097
   and    dtr_codvalor  <> 10080
   and    substring(convert(varchar,dtr_codvalor),4,1) <> '8' -- Codigo de Diferidos
   and    dtr_codvalor  <> 10047
   and    dtr_codvalor  not in (select distinct limite_sup
                                from cob_credito..cr_corresp_sib
                                where tabla = 'T143') -- Validacion por lectura a la tabla de correspondencia limite_sup Req. 397    
  
   select @w_monto_gar_mn = sum(dtr_monto_mn)
   from   cob_cartera..ca_det_trn
   where  dtr_operacion  = @w_operacionca
   and    dtr_secuencial = @w_secuencial_pag
   and    dtr_concepto   = @w_rubro_cap 
   and    dtr_codvalor  <> 13099 --LPO TEC Se cambia a 13 los códigos valor del Capital
   and    dtr_codvalor  <> 13019
   and    substring(convert(varchar,dtr_codvalor),4,1) <> '8' -- Codigo de Diferidos
   and    dtr_codvalor  <> 13080
   and    dtr_codvalor  <> 13990
   and    dtr_codvalor  <> 13017
   and    dtr_codvalor  <> 13027
   and    dtr_codvalor  <> 13097
   and    dtr_codvalor  <> 13047
   and    dtr_codvalor  <> 13092 --LCM NO TENER EN CUENTA LOS VALORES AMORTIZADOS
   and    dtr_codvalor  <> 13094 --LCM NO TENER EN CUENTA LOS VALORES AMORTIZADOS

   --LPO Ajustes por migracion a Java INICIO
   /*
   select 
   'orden'     = row_number() over (order by dif_concepto asc),
   'concepto'  = dif_concepto
   into #diferidos
   from ca_diferidos
   where dif_operacion = @w_operacionca
   */
   --LPO Ajustes por migracion a Java FIN
   
   --LPO Ajustes por migracion a Java INICIO
   CREATE TABLE #diferidos (
   orden    INT IDENTITY ,
   concepto VARCHAR(10) NULL
   )

   INSERT INTO #diferidos (concepto)
   SELECT dif_concepto
   from ca_diferidos
   where dif_operacion = @w_operacionca
   order by dif_concepto ASC
   --LPO Ajustes por migracion a Java FIN
   
   select @w_orden = 0
   while 1=1
   begin
   
      select top 1
      @w_orden    = orden,
      @w_concepto = concepto
      from #diferidos
      order by orden asc
      if @@rowcount = 0
         break   
         
      if exists (select 1 from ca_diferidos
                 where dif_operacion = @w_operacionca
                 and  dif_concepto = @w_concepto
                 and (dif_valor_total - dif_valor_pagado) > 0)
      begin
         select @w_saldo_por_diferir =  sum(dif_valor_total - dif_valor_pagado),
                @w_diferido_pagado   =  sum(dif_valor_pagado),
                @w_diferido_total    =  sum(dif_valor_total)
         from  ca_diferidos
         where dif_operacion = @w_operacionca
         and   dif_concepto  = @w_concepto
         
         if @w_cancelar  = 'S' begin
            select @w_dif_pago = @w_diferido_total - @w_diferido_pagado
         end
         else begin
            if @w_capital_antes = 0
            begin
               select @w_dif_pago = @w_saldo_por_diferir
            end
            else 
            begin
               select @w_dif_pago = ( @w_saldo_por_diferir / @w_capital_antes) * @w_monto_gar
               select @w_dif_pago =  round(@w_dif_pago,@w_num_dec_op)
            end
         
            if (@w_diferido_pagado + @w_dif_pago)  > @w_diferido_total
               select @w_dif_pago = @w_saldo_por_diferir
         end
             
         update ca_diferidos
         set    dif_valor_pagado = dif_valor_pagado + @w_dif_pago
         where dif_operacion = @w_operacionca
         and   dif_concepto  = @w_concepto

         if @@error <> 0 return 708152
                     
         ---GENERACION DE LA TRANSACCION
         select @w_cotizacion = isnull(@w_cotizacion,1)
         insert into ca_det_trn  with (rowlock)
	  	       (dtr_secuencial,                    dtr_operacion,     dtr_dividendo,
	  	        dtr_concepto,                      dtr_estado,        dtr_periodo, 
	  	        dtr_codvalor,                      dtr_monto,         
	  	        dtr_monto_mn,
	  	        dtr_moneda,                        dtr_cotizacion,    dtr_tcotizacion,
	  	        dtr_afectacion,                    dtr_cuenta,        dtr_beneficiario,
	  	        dtr_monto_cont)                    
	  	 select @w_secuencial_pag,                 @w_operacionca,    -1,
	  	        @w_concepto,                       @w_est_diferido,    0,
	  	        (co_codigo * 1000) + (@w_est_diferido * 10),     @w_dif_pago,      
	  	         round( (@w_dif_pago * @w_cotizacion) ,@w_num_dec_n),
	  	        @w_moneda_ab,                      @w_cotizacion,                 'N',
	  	        'C',                               '',                'PORCION DE PAGO AL DIFERIDO',
	  	        0
	  	 from   ca_concepto
	  	 where  co_concepto = @w_concepto
      
	     if @@error <> 0 
		 begin
	        select @w_error = 708166
	        return  @w_error
	     end
	  end
	  delete from #diferidos where orden = @w_orden
  
   end -- end while 
   
   if @w_tipo  not in ('D','G','R')
   begin
      select @w_estado          = cu_estado,
             @w_agotada         = cu_agotada,
             @w_abierta_cerrada = cu_abierta_cerrada,
             @w_tipo_gar        = cu_tipo
      from   cob_custodia..cu_custodia,
             cob_credito..cr_gar_propuesta
      where  gp_garantia = cu_codigo_externo 
      and    cu_agotada = 'S'
      and    gp_tramite = @w_tramite
      
      select @w_contabiliza = tc_contabilizar
      from   cob_custodia..cu_tipo_custodia
      where  tc_tipo = @w_tipo_gar
      
      if (@w_estado = 'V' and @w_agotada = 'S' and @w_abierta_cerrada = 'C' and @w_contabiliza = 'S')
      begin
         
         select @w_capitaliza = 'N'
         
         if exists (select 1 from ca_acciones
                    where ac_operacion = @w_operacionca)
                    select @w_capitaliza = 'S'    ---433
   
         exec @w_error = cob_custodia..sp_agotada 
         @s_ssn           = @s_ssn,
         @s_date          = @s_date,
         @s_user          = @s_user,
         @s_term          = @s_term,
         @s_ofi           = @s_ofi,
         @t_trn           = 19911,
         @t_debug         = 'N',
         @t_file          = NULL,
         @t_from          = NULL,
         @i_operacion     = 'P',          -- pago  'R' reversa de pago
         @i_monto         = @w_monto_gar, -- monto del pago
         @i_monto_mn      = @w_monto_gar_mn, ---monto moneda nacional
         @i_moneda        = @w_moneda_ab, -- moneda del pago
         @i_saldo_cap_gar = @w_saldo_cap_gar,
         @i_tramite       = @w_tramite,    -- tramite 
         @i_capitaliza    = @w_capitaliza, --- NR 433
         @i_en_linea      = @i_en_linea   --CAV Req 371 - Para controlar errores en WS
         
         if @@error <> 0 return 708201
         if @w_error <> 0 return @w_error 
   
      end
   end -- FIN TIPO DE DOCUMENTO
   
   if @w_tipo = 'R'           -- REDESCUENTO
      select @w_opcion = 'P'  -- PASIVA
   else
      select @w_opcion = 'A'  -- ACTIVA
   
   if @w_moneda_op <> 0
      select @w_monto_gar =  @w_monto_gar_mn
   
   --- Solo se ejecuta este sp si es credito rotativo caso contrario no es necesario   
   
    if @w_lin_credito is not null and @w_tramite is not null and @w_monto_gar > 0
    begin
                  
      exec @w_error = cob_credito..sp_utilizacion
      @s_ofi         = @s_ofi,
      @s_sesn        = @s_sesn,
      @s_user        = @s_user,
      @s_term        = @s_term,
      @s_date        = @s_date,
      @t_trn         = 21888,
      @i_linea_banco = @w_lin_credito,
      @i_producto    = 'CCA',
      @i_toperacion  = @w_toperacion,
      @i_tipo        = 'R', -- (R)Pagos
      @i_moneda      = @w_moneda_op,
      @i_monto       = @w_monto_gar,
      @i_opcion      = @w_opcion,  -- LuisG
      @i_tramite     = @w_tramite,  -- XSA
      @i_secuencial  = @w_secuencial_pag,  --XSA
      @i_opecca      = @w_operacionca,
      @i_cliente     = @w_cliente,
      @i_fecha_valor = @i_fecha_proceso,
      @i_modo        = 1
      
      if @@error <> 0  return 720309
      if @w_error <> 0 return @w_error
      
   end
end ---FIN DE ACTUALIZAR VALORES EN GARANTIAS Y CUPO DE CREDITO   



--PARA SIPLA sp_interfaz_otros_modulos


-- DEVOLUCION DE SEGUROS EN CASO DE PRECANCELACION  NO APLICA PARA LOS CASTIGADOS
if @w_div_vigente > 0 and @w_cancelar = 'S' and @w_tipo <> 'R' and @w_op_estado <> 4  and @i_renovacion <> 'S' and @w_forma_pago <> @w_parametro_fprsvi begin
   select @w_di_fecha_ven = di_fecha_ven
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = @w_est_vigente
   
   if @w_di_fecha_ven >  @w_fecha_proceso begin
      ---PRECANCELACION DE LA OBLIGACION UNICA OPCION VALIDA PARA DEVOLCUIONDE SEGUROS
      
      exec @w_error = sp_devolcuiones_seguros
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ssn            = @s_ssn,
      @s_sesn           = @s_sesn,
      @s_srv            = @s_srv,
      @s_ofi            = @s_ofi,
      @i_operacionca    = @w_operacionca,
      @i_div_vigente    = @w_div_vigente,
      @i_secuencial_ing = @i_secuencial_ing,
      @i_secuencial_pag = @w_secuencial_pag,
      @i_num_dec_op     = @w_num_dec_op,
      @i_en_linea       = @i_en_linea
      
      if @@error <> 0 return 708201
      if @w_error <> 0  return @w_error
      
  end
end

---INC.88796 pagos con Fecha Valor Unicamente estan generando 2 pagos con un mismo RPA
if @w_ab_fecha <= @w_fc_fecha_cierre  
begin
    select @w_fecha_ini_control = dateadd(dd,-30,@w_fc_fecha_cierre) ---INC 93801
	select tr_secuencial_ref,'tot'=count(1)
	into #pagos
	from ca_transaccion
	where tr_operacion =  @w_operacionca
	and tr_tran = 'PAG'
	and tr_estado <> 'RV'
	and tr_secuencial >= 0
    and tr_fecha_mov > @w_fecha_ini_control  ---INC 93801
	group by tr_secuencial_ref
	
	if exists (select 1 from #pagos
	           where tot > 1)
	begin
	  return 703075
	end
end
--- FIN INC.88796

-- ESTADO ACTUAL DE LA OPERACION
select @w_estado_act = op_estado
from   ca_operacion
where  op_operacion = @w_operacionca


---INC 86176
if @w_estado_act = @w_est_cancelado begin

   if exists (select 1 from ca_abono
           where ab_operacion = @w_operacionca
           and ab_secuencial_ing = @i_secuencial_ing
           and ab_estado  in ('ING','NA')
           )
           return 723902

   exec @w_error = sp_salir_espera_can
   @s_ssn  			  = 	@s_ssn, 
   @s_user            = 	@s_user,
   @s_sesn            = 	@s_sesn,
   @s_term            = 	@s_term,
   @s_date            = 	@s_date,
   @s_srv             = 	@s_srv,
   @s_lsrv            = 	@s_lsrv,
   @s_ofi             = 	@s_ofi,
   @i_operacionca     =     @w_operacionca
 
   
   if @w_error <> 0  return @w_error
   
   
   if @w_tipo_tabla = 'ROTATIVA' begin 
      
	  update ca_amortizacion set
      am_cuota      = am_pagado    ,
	  am_acumulado  = am_pagado  
	  where am_operacion = @w_operacionca
	  and   am_concepto not in ( 'CAP') 
	  and   am_estado = @w_est_cancelado
	  
	  if @@error <> 0 return 708152
	  
   end
		
		 
   select @w_valor_sobrante  = isnull(abd_monto_mop, 0)
   from   ca_abono_det
   where  abd_secuencial_ing = @i_secuencial_ing
   and    abd_operacion      = @w_operacionca
   and    abd_tipo           = 'SOB'
   and    abd_concepto       = @w_fpago_sobrante
		   	
end
---FIN ICN 8676

---LLS-46150
if @w_estado_act = @w_est_castigado
begin
  if exists (select 1 from ca_amortizacion
             where am_operacion = @w_operacionca
             and am_estado not in (0,3,4) )
     update ca_amortizacion
     set am_estado = @w_est_castigado
     where am_operacion = @w_operacionca
     and   am_estado not in (0,3,4)  

     if @@error <> 0 return 724401          
end
---LLS-46150

if @w_estado_act <> @w_est_cancelado
begin
   exec @w_error = sp_cambio_estado_op
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_ofi            = @s_ofi,
   @i_banco          = @w_banco,
   @i_fecha_proceso  = @w_fecha_proceso,
   @i_tipo_cambio    = 'A',
   @i_en_linea       = @i_en_linea,
   @i_num_dec        = @w_num_dec_n,
   @o_msg            = @w_msg out

   if @@error <> 0 return 708201
   if @w_error <> 0 return @w_error

end

-- ESTADO ACTUAL DE LA OPERACION PUDO HABER CAMBIADO POR EL CAMBIO DE ESTADO
select @w_estado_act = op_estado
from   ca_operacion
where  op_operacion = @w_operacionca


if @i_en_linea = 'N'
   select @w_bandera_be = 'S'
else
   select @w_bandera_be = 'N'

if @w_tramite is not null begin

   exec @w_error = cob_custodia..sp_activar_garantia
   @i_opcion         = 'C',
   @i_tramite        = @w_tramite,
   @i_reconocimiento = @w_reconocimiento,
   @i_modo           = 2,
   @i_operacion      = 'I',
   @s_date           = @s_date,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_ofi            = @s_ofi,
   @i_bandera_be     = @w_bandera_be
   
   if @@error <> 0 return 708201
   if @w_error <> 0 return @w_error

end

-- REVISAR SITUACION DEL CREDITO
select @w_gracia_extraordinario = isnull(ro_gracia, 0)
from   ca_rubro_op
where  ro_operacion = @w_operacionca
and    ro_concepto = @w_rubro_cap

select @w_ult_cancelado_despues = max(isnull(di_dividendo,0))
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado    = @w_est_cancelado

---if @i_pago_ext = 'N' print 'abonoca.sp @w_gracia_extraordinario ' + CAST (@w_gracia_extraordinario as varchar)
---SI NO SE CANCELO NINGUNA CUOTA Y ES APLICAION POR CONCEPTO
---HAY QUE VALIODAR DONDE PONER EL VALOR EXTRA POR QUE LA CANCELADA NO SE COPIO
---EN EL HISTORICO

select @w_en_cancelada = 'S'

if @w_ult_cancelado = @w_ult_cancelado_despues and  @w_tipo_aplicacion = 'C'
   select @w_en_cancelada = 'N'

if (@w_gracia_extraordinario>0) 
begin  ---8
   select @w_dividendo_vigente = di_dividendo
   from   ca_dividendo
   where  di_operacion = @w_operacionca
   and    di_estado    = 1
   
   if @@rowcount = 0
    begin ----9
      select @w_dividendo_vigente = max(di_dividendo)
      from   ca_dividendo
      where  di_operacion = @w_operacionca
    end ---9
   
   declare
      @w_saldo_cancelado  money
   
   select @w_saldo_cancelado = isnull(sum(am_acumulado-am_pagado),0) 
   from   ca_amortizacion
   where  am_operacion  = @i_operacionca
   and    am_concepto = @w_rubro_cap
   
   select @w_saldo_cancelado = @w_saldo_cancelado -  @w_gracia_extraordinario
   -- VERIFICAR SI EL PAGO EXTRAORIDINARIO CANCELO EL PRESTAMO
   
   -- KDR 16/08/2021 Rutina para acumular el saldo extraordinario (manejado como gracia) en la cuota vigente y no en la última cancelada
   -- ya que si se acumula en la última cancelada, se produce un error en fecha valor y reversas ya que este proceso al guardar y recuperar
   -- historiales no toma en cuenta a cuotas canceladas, por lo que se producen descuadre del saldo capital del préstamo. 
   if (@w_saldo_cancelado > 0) and (@w_saldo_cancelado <= @w_vlr_despreciable )   ---INC. 53417
   begin ---- 6
    select @w_saldo_cancelado = sum(am_acumulado - am_pagado)
      from   ca_amortizacion
      where  am_operacion = @w_operacionca
      and    am_dividendo >= @w_dividendo_vig_extra
      and    am_concepto  = @w_rubro_cap
      
      if @w_saldo_cancelado = @w_gracia_extraordinario 
      begin --- 7
         update ca_amortizacion  with (rowlock)
         set    am_pagado = am_acumulado
         where  am_operacion = @w_operacionca
         and    am_concepto  = @w_rubro_cap
         and    am_dividendo >= @w_dividendo_vig_extra
         and    am_pagado < am_acumulado

         if @@error <> 0 return 708152

      end ---- 7
      else
      begin
         update ca_amortizacion with (rowlock)
		   set   am_cuota     = am_cuota     + @w_gracia_extraordinario,
	            am_acumulado = am_acumulado + @w_gracia_extraordinario,
	            am_pagado    = am_pagado    + @w_gracia_extraordinario
		   where  am_operacion = @w_operacionca
		   and    am_dividendo = @w_dividendo_vig_extra -- KDR 16/08/2021 LPO Poner excedente de CAP en la cuota vigente en Pagos Extraordinarios
		   and    am_concepto  = @w_rubro_cap
      end
   end --- 6
   ELSE 
   begin --- 5
      update ca_rubro_op  with (rowlock)
      set    ro_gracia = 0
      where  ro_operacion = @w_operacionca
      and    ro_concepto = @w_rubro_cap
      
      if @@error <> 0 return 708152
      
      if 3 = (select di_estado
              from   ca_dividendo
              where  di_operacion = @w_operacionca
              and    di_dividendo = @w_dividendo_vigente)
      begin ---3
         update ca_amortizacion  with (rowlock)
         set    am_cuota     = am_cuota     + @w_gracia_extraordinario,
                am_acumulado = am_acumulado + @w_gracia_extraordinario,
                am_pagado    = am_pagado    + @w_gracia_extraordinario
       
         where  am_operacion = @w_operacionca
         and    am_dividendo = @w_dividendo_vig_extra -- KDR 16/08/2021 LPO Poner excedente de CAP en la cuota vigente en Pagos Extraordinarios
         and    am_concepto  = @w_rubro_cap
         
         if @@error <> 0 return 708152

      end  ---3
      ELSE
      begin ---2
        if @w_en_cancelada = 'S'
         begin  --- 1    
	         update ca_amortizacion  with (rowlock)
	         set    am_cuota     = am_cuota     + @w_gracia_extraordinario,
	                am_acumulado = am_acumulado + @w_gracia_extraordinario,
	                am_pagado    = am_pagado    + @w_gracia_extraordinario
	         where  am_operacion = @w_operacionca
	         and    am_dividendo = @w_dividendo_vig_extra -- KDR 16/08/2021 LPO Poner excedente de CAP en la cuota vigente en Pagos Extraordinarios
	         and    am_concepto  = @w_rubro_cap
	         
	         if @@error <> 0 return 708152
	      end --- 1
         ELSE
		     begin ---0
		         update ca_amortizacion  with (rowlock)
		             set    am_cuota     = am_cuota     + @w_gracia_extraordinario,
	                    am_acumulado = am_acumulado + @w_gracia_extraordinario,
	                    am_pagado    = am_pagado    + @w_gracia_extraordinario
		         where  am_operacion = @w_operacionca
		         and    am_dividendo = @w_dividendo_vig_extra -- KDR 16/08/2021 LPO Poner excedente de CAP en la cuota vigente en Pagos Extraordinarios
		         and    am_concepto  = @w_rubro_cap
		         
		         if @@error <> 0 return 708152
		    end ---0
       end --- 2
     end ---5
end --- 8

select 
@w_sum_cuotas_despues = isnull(sum(am_cuota), 0),
@w_sum_saldo_despues  = isnull(sum(am_acumulado - am_pagado), 0)
from   ca_amortizacion
where  am_operacion = @w_operacionca
and    am_concepto  = @w_rubro_cap

if round(@w_sum_cuotas_despues,2) <> round(@w_sum_cuotas_ant,2)
begin
   if @i_pago_ext = 'N'
   begin
      return 710539
   end
end

if @w_monto_gar_mn > 0 begin --Pago de CAPITAL
  
   select @w_val_pagado = 0
   
 select @w_val_pagado = round(@w_sum_saldo_despues + @w_monto_gar_mn,2)
   
   if  round(@w_sum_saldo_ant,2) <> @w_val_pagado and @w_moneda_op = 0
   begin
      return  711022 --LPO CDIG Multimoneda Se comenta
   end
end

--- ACTUALIZACION DE SALDOS INTERFAZ PALM 
execute @w_error = sp_datos_palm 
@i_operacionca   = @w_operacionca, 
@i_operacion     = 'P',
@i_monto_cap     = @w_monto_mop,
@i_reversa       = 'N'

if @@error <> 0 return 708201
if @w_error <> 0 return @w_error

-- VALIDACION DE DIVIDENDOS VIGENTES DESPUES DEL PAGO
if (select count(1) from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado  = 1) > 1
   return 711060
-- VALIDACION DE DIVIDENDOS VIGENTES DESPUES DEL PAGO
 
--GENERAR NUEVAMENTE EL NUMERO DE RECIBO
if @w_op_naturaleza = 'A' and @w_ab_nro_recibo =  -999 begin
   select @w_ab_nro_recibo = 0

   exec sp_numero_recibo
   @i_tipo    = 'P',
   @i_oficina = @s_ofi,
   @o_numero  = @w_ab_nro_recibo out
   
   update ca_abono  with (rowlock)
   set    ab_nro_recibo = @w_ab_nro_recibo
   where  ab_operacion      = @i_operacionca
   and    ab_secuencial_ing = @i_secuencial_ing
   
   if @@error <> 0 return 708201
   
end

--01JUN19 Seccion comentada por solicitud de Luis Castellano
/*
if @w_tipo_aplicacion <> 'O' begin -- NO ES LA NUEVA CONDONACION

    select @w_dtr_D = isnull(sum(dtr_monto_mn),0)
   from   ca_det_trn
   where  dtr_operacion   = @i_operacionca
   and    dtr_secuencial  = @w_secuencial_pag
   and    dtr_codvalor   <> 10990
   and    dtr_codvalor   <> 10099
   and    substring(convert(varchar,dtr_codvalor),4,1) <> '8' -- Codigo de Diferidos
   and    dtr_codvalor   <> 10019
   and    dtr_codvalor   <> 10080
   and    dtr_afectacion  = 'D'
   
   
   select @w_dtr_C =  isnull(sum(dtr_monto_mn),0)
   from   ca_det_trn
   where  dtr_operacion   = @i_operacionca
   and    dtr_secuencial  = @w_secuencial_pag
   and    dtr_codvalor   <> 10990
   and    dtr_codvalor   <> 10099
   and    dtr_codvalor   <> 10019
   and    dtr_codvalor   <> 10370
   and    substring(convert(varchar,dtr_codvalor),4,1) <> '8' -- Codigo de Diferidos
   and    dtr_codvalor   <> 10080
   and    dtr_afectacion  = 'C'
   
   if @w_dtr_D  <> @w_dtr_C begin
      select @w_diff = (@w_dtr_D  - @w_dtr_C)
      
      if (@w_moneda_op =  @w_moneda_local) and (abs(@w_diff) > @w_limite_ajuste) begin
         if @i_pago_ext = 'N'
            PRINT 'abonoca.sp  DIF. en tran PAG = ' + CAST(@w_diff AS VARCHAR) + ' Debitos: ' + CAST(@w_dtr_D AS VARCHAR) + ' Creditos: ' + CAST(@w_dtr_C AS VARCHAR)           
         return 710289
      end
   end
   
end
*/

--COMENTADO EL EVALUAR CLIENTE , ESTO ES UNA REGLA DE NEGOCIO PROPIO DE BMI--CONSULTAR CON FABIAN
/*
-------------------------------------------------
--llamar sp_evaluar_cliente  Req. 300
-------------------------------------------------

--execute @w_error =   sp_evaluar_cliente
--@i_evento        =   @w_evento_campana,
--@i_operacionca   =   @i_operacionca,
--@i_secuencial    =   @i_secuencial_ing,
--@o_msg_matriz    =   @w_msg_matriz  out

--if @w_error <> 0
  -- return @w_error

--if @w_msg_matriz is not null and @i_pago_ext = 'N' --Se restringe mensaje para ejecución desde canales
   --print   @w_msg_matriz   
-------------------------------------------------
--fin Req. 300 
-------------------------------------------------
*/
--LA FECHA ULT_MOV SE DEBE ACTUALIZAR PARA QUE LAS CANCELADAS SEAN BIEN PASADAS AL CONSOLIDADOR
--DEF 7293
if @w_op_naturaleza = 'A' and @w_estado_act = 3 begin
   update ca_operacion  with (rowlock)
   set    op_fecha_ult_mov = @w_fc_fecha_cierre
   where  op_operacion     = @i_operacionca
   
   if @@error <> 0 return 708152
   
   insert into ca_activas_canceladas  with (rowlock)
   (can_operacion,   can_fecha_can,   can_usuario,  can_tipo,   can_fecha_hora)
   values(@i_operacionca,  @w_fc_fecha_cierre, @s_user,  @w_tipo,    getdate() )
   
   if @@error <> 0 return 708154
   
   -- INICIO - REQ 089 - ACUERDO DE PAGO - 07/ENE/2011
   update cob_credito..cr_acuerdo_vencimiento set
   av_estado       = 'OK',
   av_fecha_estado = @i_fecha_proceso
   from cob_credito..cr_acuerdo
   where ac_banco    = @w_banco
   and   ac_estado   = 'V'
   and   av_acuerdo  = ac_acuerdo
   and   av_estado  <> 'OK'
     
   if @@error <> 0  return 710568
   -- FIN - REQ 089 - ACUERDO DE PAGO   

end

---Inc 117737
--- ESte Sp es llamado unicamente si es abono Normal, para Abonos Extraordiarios la revisiones se hacen en el abnextra.sp
 if @w_estado_act  in (1,4,9) and @w_op_naturaleza =  'A' and @w_tipo <> 'G'  and @w_fecha_fin_op >  @w_fc_fecha_cierre  
    and @w_tipo_reduccion = 'N' and  @w_tipo_aplicacion = 'D'
  begin
     exec sp_revisa_otros_rubros 
     @i_operacion  = @i_operacionca
     if @@error <> 0 return 708201
  end
---Inc -117737


-- Inicio Fin Req. 366 Seguros
if exists (select 1 from cob_credito..cr_seguros_tramite where st_tramite = @w_tramite) and @w_tipo_tabla <> @w_tipo_amortizacion
begin
  
    if @w_abono_extraordinario = 'S' and @w_tipo_reduccion <> 'N' begin

         exec @w_error      = sp_seguros
         @i_opcion          = 'P'              ,
	     @i_tramite         = @w_tramite       ,
	     @i_secuencial_pago = @w_secuencial_pag, 
	     @i_secuencial_ing  = @i_secuencial_ing,
	     @i_extraordinario  = 'S'  	        
	     
         if @w_error <> 0 return @w_error

         
         exec @w_error           = sp_seguros
         @i_opcion          = 'G'       ,
         @i_tramite         = @w_tramite,
         @i_secuencial_pago = @w_secuencial_pag,
         @i_extraordinario  = 'S'  	        
	     
         if @w_error <> 0 return @w_error
         
   end
   else begin
      exec @w_error      = sp_seguros
      @i_opcion          = 'P'              ,
	  @i_tramite         = @w_tramite       ,
	  @i_secuencial_pago = @w_secuencial_pag, 
	  @i_secuencial_ing  = @i_secuencial_ing
	     
      if @w_error <> 0 return @w_error
   end
end
-- Fin Req 366

--Si la operacion tiene el rubro Seguro deudores empleado (SEGDEUEM) y tiene un traslado de linea procesado cuya linea
--destino no tiene el rubro SEGDEUEM y no tiene cuotas vencidas se elimina el rubro de la ca_rubro_op
if exists (select 1 from cob_cartera..ca_rubro_op
           where ro_operacion = @w_operacionca
           and   ro_concepto = 'SEGDEUEM')
begin
   if exists (select 1 from cob_cartera..ca_traslado_linea
              where  tl_operacion = @w_operacionca 
              and    tl_estado = 'P'
              and    tl_linea_destino not in (select c.codigo from  cobis..cl_catalogo c, cobis..cl_tabla d where d.codigo = c.tabla and d.tabla = 'ca_lineas_em'))
   begin
      if not exists (select 1 from cob_cartera..ca_dividendo
                     where di_operacion = @w_operacionca
                     and   di_estado = 2)
      begin
         delete cob_cartera..ca_rubro_op
         where ro_operacion = @w_operacionca
         and   ro_concepto = 'SEGDEUEM'
         
         if @@error <> 0 return 707003
      end
   end
end 

if exists (select 1 from cob_credito..cr_seguros_tramite where st_tramite = @w_tramite) and @w_tipo_tabla = @w_tipo_amortizacion
begin

   exec @w_error = sp_seguros_tflexible
   @i_debug             = 'N',
   @i_operacionca       = @w_operacionca,
   @i_tramite           = @w_tramite,
   @i_saldo_cap         = @w_op_monto,
   @i_num_dec           = @w_num_dec_op,
   @i_dias_anio         = @w_dias_anio,
   @i_causacion         = @w_causacion,
   @i_cuales_tablas     = 'D',
   @o_msg_msv           = null
   
   if @w_error <> 0 return @w_error

END


return 0

GO

