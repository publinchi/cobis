/************************************************************************/
/*      Nombre Fisico:          apcuotan.sp                             */
/*      Nombre Logico:          sp_aplicacion_cuota_normal              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     11 de Dic 2001                          */
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
/*                              CAMBIOS                                 */
/*      EPB:FEB-2003            Personalizacion BAC                     */
/*      EPB:12:ABR:2004         La cancelacion de una obligacion siempre*/
/*                              se hace acumulada si el tipo de cobro   */
/*                              es VP debido a que el VP actualiza la   */
/*                              tabla de amortizacion desde la vigente  */
/*                              en adelante dependiendo del VP resultan */
/*                              te  y genera ajuste o devolucion segu el*/
/*                              caso                                    */
/*      ene-14-2005      EPB                  ULT-ACT-ENE142005-11:53   */
/*      ABR 10 2006      Elcira Pelaez        CXCINTES  NR 379          */ 
/*      MAY 11 2006      Elcira Pelaez        Def. 6489  quitar la      */ 
/*                                            ejecucion a reajint.sp    */
/*      MAY-2006         Elcira Pelaez        def 6591 BAC              */
/*      SEP 2006         FQ                   Optimizacion 152          */
/*      FEB-2012         Luis Carlos Moreno   Req-293 Recono. garantias */
/*      MAY-2014         Elcira Pelaez        Tablas Flexibls NR 392    */
/*      05/12/2016          R. Sánchez            Modif. Apropiación    */
/*      16/08/2019       Luis Ponce           Pagos Grupales Te Creemos */
/*      05/12/2019       Luis Ponce           Cobro Indiv Acumulado,    */
/*                                            Proyectado Grupal         */
/*      31/03/2019       Luis Ponce           CDIG ABONO EXTRAORDINARIO */
/*  DIC/03/2020   Patricio Narvaez  Causacion en moneda nacional        */
/* 14/01/2021         P.Narvaez    Rubros anticipados, CoreBase         */
/* 18/02/2021         K. Rodríguez Se comenta uso de concepto CXCINTES  */
/* 24/06/2022         A. Monroy    Ajuste a cancelación de otros rubros */
/*                                 en cuotas no vigentes                */
/* 17/04/2023         G. Fernandez S807925 Ingreso de campo de          */
/*                                 reestructuracion                     */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion   */
/*									  de char(1) a catalogo				*/
/*    07/11/2023     K. Rodriguez  Actualiza valor despreciab           */
/************************************************************************/
 
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplicacion_cuota_normal')
   drop proc sp_aplicacion_cuota_normal
go

---NR 392 Version PRODUCCION  (185)

create proc sp_aplicacion_cuota_normal
@s_sesn                 int          = NULL,
@s_user                 login        = NULL,
@s_term                 varchar (30) = NULL,
@s_date                 datetime     = NULL,
@s_ofi                  smallint     = NULL,
@i_secuencial_ing       int,
@i_secuencial_pag       int,
@i_fecha_proceso        datetime,
@i_operacionca          int,
@i_en_linea             char(1),
@i_tipo_reduccion       char(1),
@i_tipo_reduccion_orig  CHAR(1), -- AMO 20220610
@i_tipo_cobro           char(1),
@i_monto_pago           float,
@i_cotizacion           money,
@i_tcotizacion          char(1),
@i_num_dec              smallint,
@i_num_dec_n            smallint,
@i_saldo_capital        money     = NULL,
@i_pago_vigente         char(1)   = 'N',
@i_dias_anio            int       =  360,
@i_base_calculo         char(1)   =  'R',
@i_tipo                 char(1)   = 'N',
@i_aceptar_anticipos    char(1),
@i_tasa_prepago         float     = 0,
@i_dividendo            int       = 0,
@i_cancela              char(1)   = 'N',
@i_saldo_oper           money,
@i_cancelar             char(1),
@i_cotizacion_dia_sus   float = null,
@i_en_gracia_int        char(1) = 'N',
@i_prepago              char(1) = 'N',
@i_tiene_reco           char(1)   = 'N',
@i_tipo_tabla           catalogo  = null,
@i_tipo_amortizacion    catalogo  = null,
@i_es_precancelacion    CHAR(1)   = NULL, --LPO TEC NUEVA DEFINCION, EN UNA PRECANCELACION PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
@i_debug				CHAR(1)	  = 'N',  -- AMO 20220610
@o_sobrante             float     = NULL out
as

declare
@w_sp_name                descripcion,
@w_ap_prioridad           int,
@w_est_cancelado          tinyint,
@w_est_vencido            tinyint,
@w_est_novigente          tinyint,
@w_est_vigente            tinyint,
@w_max_dividendo          int,   
@w_di_dividendo           int,
@w_di_fecha_ini           datetime,   
@w_di_fecha_ini_aux       datetime,   
@w_di_fecha_ven           datetime,
@w_di_fecha_ven_aux       datetime,
@w_monto_prioridad        money,
@w_monto_dividendo        money,
@w_monto_dividendo_a      money,
@w_monto_pago             money,
@w_am_concepto            catalogo,
@w_ro_tipo_rubro          char(1),
@w_monto_rubro            money,
@w_total_div              money,
@w_salir_prioridad        char(1),
@w_salir_dividendo        char(1),
@w_salir_rubro            char(1),
@w_pa                     char(1),
@w_div_vigente            int,
@w_contador               int,
@w_total_ven              float,
@w_total_ant              money,
@w_inicial_prioridad      float,
@w_inicial_rubro          float,
@w_tipo                   char(1),
@w_tipo_rotativo          char(1),
@w_ahorro                 money,
@w_ahorro_tot             money,
@w_cancelar_div           char(1),
@w_tipo_cobro_o           char(1),
@w_fpago                  char(1),
@w_periodo_int            int,
@w_tdividendo             catalogo,
@w_di_estado              int,
@w_base_calculo           char(1),
@w_recalcular             char(1),
@w_saldo_oper             money,
@w_saldo_ant              money,
@w_saldo_ven              money,
@w_tasa_prepago           float,
@w_contador_div           int,
@w_dias_cuota             int ,
@w_dd                     int ,
@w_dd_antes               int ,
@w_dd_despues             int ,
@w_num_dec_tapl           tinyint,      
@w_tramite                int,      
@w_moneda                 smallint,  
@w_concepto_int           catalogo,
@w_gar_admisible          char(1),
@w_codvalor_nov           int,
@w_codvalor_vig           int,
@w_monto_intfact          money,
@w_causacion              char(1),
@w_ro_concepto            catalogo,
@w_ro_fpago               char(1),
@w_am_cuota_anterior      money,
@w_am_pagado_anterior     money,
@w_op_banco               cuenta, 
@w_op_dias_anio           smallint,
@w_float                  float,
@w_valor_calc             money,
@w_ro_porcentaje          float,
@w_error                  int,
@w_recalcular_cuota       char(1),
@w_de_capital             char(1),
@w_primer_vigente         int,
@w_banco                  cuenta,
@w_num_dividendos         int,
@w_cuota                  money,
@w_fecha_fin              datetime,
@w_estado_dividendo       int,
@w_int_ant                catalogo,
@w_fecha_ven_op           datetime,
@w_fecha_cartera          datetime,
@w_modo                   char(1),
@w_cancelar               char(1),
@w_div_ven_hoy            int,
@w_dividendos             int,
@w_est_suspenso           tinyint, 
@w_estado_op              tinyint, 
@w_edad_op                tinyint,
@w_concepto_dse           catalogo,
@w_param_devseg           catalogo,
@w_codvalor_dse           int,
@w_vencido                money,
@w_anticipado             money,
@w_valor_futuro_int       money,
@w_vp_int                 money,
@w_fecha_proceso          datetime,
@w_dias                   int,
@w_totcuot_int_org        money,
@w_int                    catalogo,
@w_vp_cobrar              money,
@w_totvp_cobrar           money,
@w_causacion_pte          money,
@w_causacion_pte_mn       money, 
@w_codvalor               int,
@w_codvalor1              int,
@w_toperacion             catalogo,
@w_secuencial_vp          int,
@w_oficina_op             smallint,
@w_gerente                int,
@w_reestructuracion       char(1),
@w_calificacion           catalogo, -- MCO 05/06/2023 Se cambio el tipo de dato de char(1) a catalogo
@w_am_estado              tinyint,
@w_am_periodo             tinyint,
@w_observacion            varchar(50),
@w_cuota_cap              money,
@w_valor_int_cap          money,
@w_no_cobrado_int         money,
@w_int_en_vp              money,
@w_concepto_devint        catalogo,
@w_parametro_devint       catalogo,
@w_revisar_reajuste       char(1),
@w_cap                    catalogo,
@w_pagado_vig             money,
@w_causacion_pte_ajuste   money,
@w_secuencial_ajuste      int,
@w_codvalor_ajus          int,
@w_op_estado              smallint,
@w_vlr_despreciable       float,
@w_dif                    money,
@w_aplic                  money,
@w_int_cta                money,
@w_int_pag                money,
@w_int_acu                money,
@w_proyectado_int         money,
@w_op_gracia_int          int,
@w_moneda_nacional        tinyint,
@w_parametro_cxcintes     catalogo,   ---NR 379
@w_concepto_traslado      catalogo,   ---NR 379
@w_rowcount_act           int,
@w_rowcount               int,
@w_bandera_be             char(1),
@w_iva_cj                 catalogo,
@w_iva                    float,
@w_proporcional           char(1),
@w_monto_analisis         money,
@w_monto_mipyme           money,
@w_monto_ivapyme          money,
@w_ivamipymes             catalogo,
@w_mipymes                catalogo,
@w_gracia_int             smallint,                   -- REQ 175: PEQUEÑA EMPRESA
@w_dist_gracia            char(1),                    -- REQ 175: PEQUEÑA EMPRESA
@w_concepto               catalogo,                   -- REQ 175: PEQUEÑA EMPRESA
@w_concepto_ant           catalogo,                   -- REQ 175: PEQUEÑA EMPRESA
@w_dividendo              smallint,                   -- REQ 175: PEQUEÑA EMPRESA
@w_gracia_acum            money,                      -- REQ 175: PEQUEÑA EMPRESA
@w_vlr_gracia             money,                      -- REQ 175: PEQUEÑA EMPRESA
@w_num_div_tmp            smallint,                   -- REQ 175: PEQUEÑA EMPRESA
@w_secuencial             int,                        -- REQ 175: PEQUEÑA EMPRESA
@w_secuencia              int,                        -- REQ 175: PEQUEÑA EMPRESA
@w_secuencia_ant          int,                        -- REQ 175: PEQUEÑA EMPRESA
@w_estado                 tinyint,                    -- REQ 175: PEQUEÑA EMPRESA
@w_vlr_cap                money,       --LCM - 293
@w_vlr_req                money,       --LCM - 293
@w_sob_rec                money,       --LCM - 293
@w_monto_reconocer        money,       --LCM - 293
@w_sec_rpa_rec            int,         --LCM - 293
@w_sec_rpa_pag            int,         --LCM - 293
@w_cap_pag_rec            money,       --LCM - 293
@w_porc_rec               float,       --LCM - 293
@w_cap_div                money,       --LCM - 293
@w_vlr_calc_fijo          money,       --LCM - 293
@w_div_pend               money,       --LCM - 293
@w_tacuerdo               char(1),      -- REQ 089: ACUERDOS DE PAGO - 14/ENE/2011
@w_disponible             MONEY,
@w_tipo_cobro_op          CHAR(1),      --LPO TEC
@w_tipo_cobro_aux         CHAR(1),      --LPO TEC
@w_tipo_grupal            CHAR(1)       --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO


select @w_vlr_despreciable = 1.0 / power(10, (@i_num_dec + 2))

-- INICIALIZACION DE VARIABLES
select 
@w_no_cobrado_int       = 0,
@w_int_en_vp            = 0,
@w_cuota_cap            = 0,
@w_valor_int_cap        = 0,
@w_est_novigente        = 0,
@w_est_vigente          = 1,
@w_est_vencido          = 2,
@w_est_cancelado        = 3,
@w_est_suspenso         = 9,
@w_salir_prioridad      = 'N',
@w_salir_dividendo      = 'N',
@w_salir_rubro          = 'N',
@w_di_fecha_ini         = @i_fecha_proceso,
@w_ahorro_tot           = 0,
@w_tipo_cobro_o         = @i_tipo_cobro,
@w_tasa_prepago         = @i_tasa_prepago,
@w_contador_div         = 0,
@w_num_dec_tapl         = null,
@w_recalcular_cuota     = 'N',
@w_cancelar             = @i_cancelar,
@w_vencido              = 0,
@w_anticipado           = 0,
@w_valor_futuro_int     = 0,
@w_dias                 = 0,
@w_vp_int               = 0,
@w_valor_futuro_int     = 0,
@w_totcuot_int_org      = 0,
@w_vp_cobrar            = 0,
@w_totvp_cobrar         = 0,
@w_causacion_pte        = 0,
@w_causacion_pte_mn     = 0,
@w_revisar_reajuste     = 'N',
@w_pagado_vig           = 0,
@w_causacion_pte_ajuste = 0,
@w_proyectado_int       = 0,
@w_moneda_nacional      = 0,
@w_vlr_cap              = 0,   --LCM - 293
@w_vlr_req              = 0,   --LCM - 293
@w_monto_reconocer      = 0,   --LCM - 293
@w_vlr_calc_fijo        = 0,   --LCM - 293
@w_div_pend             = 0,   --LCM - 293
@w_disponible           = 0
   
   
-- PARAMETROS GENERALES
select @w_ivamipymes  =  pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IVAMIP'
if @@rowcount = 0
   return 710256

   
select @w_mipymes  =  pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'MIPYME'
if @@rowcount = 0
   return 710256



select @w_int_ant = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INTANT'
if @@rowcount = 0
   return 710256


select @w_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
if @@rowcount = 0
return 710428

select @w_cap = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
if @@rowcount = 0
return 710429

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
if @@rowcount = 0
return 710429

select @w_iva = pa_float
from  cobis..cl_parametro
where pa_nemonico = 'PIVA'
and pa_producto = 'CTE'

if @@rowcount = 0
return 710429

/* LCM - 293: CONSULTA LA TABLA DE RECONOCIMIENTO PARA VALIDAR SI LA OBLIGACION TIENE RECONOCIMIENTO */
if @i_tiene_reco = 'S'
   select @w_vlr_calc_fijo = isnull(pr_vlr_calc_fijo,0),
          @w_div_pend      = isnull(pr_div_pend,0)
   from ca_pago_recono with (nolock)
   where pr_operacion = @i_operacionca
   and   pr_estado = 'A'

-- SELECCION DEL DIVIDENDO VIGENTE
select @w_div_vigente = isnull(max(di_dividendo),0)
from   ca_dividendo
where  di_operacion   = @i_operacionca
and    di_estado      = @w_est_vigente

IF @i_debug = 'S'
  PRINT 'sp_aplicacion_cuota_normal 1.1 @w_div_vigente = ' + CONVERT(CHAR(5),@w_div_vigente)

if @w_div_vigente = 0
begin
   select @w_div_vigente = isnull(max(di_dividendo), -1)
   from   ca_dividendo
   where  di_operacion   = @i_operacionca
   and    di_estado      = 2
   
   if @w_div_vigente = -1
      return 708163
end

IF @i_debug = 'S'
  PRINT 'sp_aplicacion_cuota_normal 1.2 @w_div_vigente = ' + CONVERT(CHAR(5),@w_div_vigente)

select @w_am_periodo = am_periodo,
       @w_am_estado  = am_estado
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_concepto  = @w_int
and    am_dividendo = @w_div_vigente

if @w_am_estado = 3
   select @w_am_estado = 1

-- SELECCION DEL TIPO ROTATIVO
select @w_tipo_rotativo = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'ROT'
and    pa_producto = 'CCA'

-- SIGLA DE PERIODICIDAD ANUAL
select @w_pa = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'PAN'
and    pa_producto = 'CCA'


-- FORMA DE PAGO DEL RUBRO INTERES
select @w_num_dec_tapl   = ro_num_dec,
       @w_concepto_int   = ro_concepto,
       @w_ro_porcentaje  = ro_porcentaje
from   ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_tipo_rubro = 'I'

-- CONSULTA DE LOS DATOS DE LA OPERACION
select @w_periodo_int      = op_periodo_int,
       @w_tdividendo       = op_tdividendo,
       @w_base_calculo     = op_base_calculo,
       @w_recalcular       = op_recalcular_plazo,
       @w_tramite          = op_tramite,
       @w_tipo             = op_tipo,
       @w_causacion        = op_causacion,
       @w_gar_admisible    = op_gar_admisible,
       @w_moneda           = op_moneda,
       @w_banco            = op_banco,
       @w_cuota            = op_cuota,
       @w_op_banco         = op_banco,
       @w_op_dias_anio     = op_dias_anio,
       @w_fecha_proceso    = op_fecha_ult_proceso,
       @w_toperacion       = op_toperacion,
       @w_oficina_op       = op_oficina,
       @w_gerente          = op_oficial,
       @w_reestructuracion = op_reestructuracion,
       @w_calificacion     = op_calificacion,
       @w_op_estado        = op_estado,
       @w_fecha_fin        = op_fecha_fin,
       @w_gracia_int       = op_gracia_int,                     -- REQ 175: PEQUEÑA EMPRESA
       @w_dist_gracia      = op_dist_gracia,                    -- REQ 175: PEQUEÑA EMPRESA
       @w_tipo_cobro_op    = op_tipo_cobro   --LPO TEC
from   ca_operacion
where  op_operacion = @i_operacionca

/*
SELECT @w_tipo_cobro_op = dt_tipo_cobro  --LPO TEC Se deja el tipo de cobro desde la Operacion, no desde el Producto
from ca_default_toperacion
WHERE dt_toperacion = @w_toperacion
*/

--LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO:
/*DETERMINA EL TIPO DE OPERACION ((G)rupal, (I)nterciclo, I(N)dividual)*/
EXEC @w_error = sp_tipo_operacion
     @i_banco  = @w_banco,
     @o_tipo   = @w_tipo_grupal out

IF @w_error <> 0
   RETURN @w_error
--LPO TEC FIN NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO


-- INICIO - REQ 089: ACUERDOS DE PAGO - 30/NOV/2010
select @w_tacuerdo = ac_tacuerdo
from cob_credito..cr_acuerdo
where ac_banco               = @w_banco
and   ac_estado              = 'V'                         -- NO ANULADOS
and   @w_fecha_proceso between ac_fecha_ingreso and ac_fecha_proy

if @@rowcount = 0 select @w_tacuerdo = 'X'
-- FIN - REQ 089: ACUERDOS DE PAGO - 30/NOV/2010


select @w_saldo_oper = @i_saldo_oper

select @w_saldo_oper = round (@w_saldo_oper,@i_num_dec)

IF @i_debug = 'S'
  PRINT 'sp_aplicacion_cuota_normal 2.1 @i_monto_pago = ' + CONVERT(CHAR(12), @i_monto_pago) + ' @w_saldo_oper = ' + CONVERT(CHAR(12), @w_saldo_oper)
  
if  @i_monto_pago < @w_saldo_oper
    select @w_cancelar = 'N'
    
IF @i_debug = 'S'
  PRINT 'sp_aplicacion_cuota_normal 2.2 @w_cancelar = ' + CONVERT(CHAR(12), @w_cancelar)

--PARA PEREPAGOS
--PARA QUE NO CANCELE LA CUOTA VIGENTE AL PAGAR TODO EL CAPITAL Y EL INT ACUMUALDO
--YA QUE ESTA CUOTA DEBE SER REGENERADA

IF @i_debug = 'S'
  PRINT 'sp_aplicacion_cuota_normal 3.1 @i_prepago = ' + @i_prepago + ' @w_cancelar = ' + @w_cancelar
  
if @i_prepago = 'S' and @w_cancelar = 'N'
   select @i_tipo_cobro = 'P'

IF @i_debug = 'S'   
  PRINT 'sp_aplicacion_cuota_normal 3.2 @i_tipo_cobro = ' + @i_tipo_cobro
   
if @w_cancelar = 'S'
begin
   -- INI - REQ 175: PEQUEÑA EMPRESA - AJUSTE DE VALOR DE GRACIA PARA PRECANCELACIONES DE ACUERDO A LO ACUMULADO
   if @w_gracia_int > 0
   begin
      select 
      ro_tipo_rubro                 as tipo_rubro,
      am_concepto                   as concepto,
      am_secuencia                  as secuencia,      
      sum(am_acumulado - am_pagado) as saldo
      into #gracia_acum
      from ca_amortizacion, ca_rubro_op
      where am_operacion    = @i_operacionca
      and   am_dividendo   <= @w_gracia_int
      and   am_gracia       < 0
      and   ro_operacion    = am_operacion
      and   ro_concepto     = am_concepto      
      and   ro_tipo_rubro not in ('C', 'M')
      group by ro_tipo_rubro, am_concepto, am_secuencia
            
      update ca_amortizacion
      set am_gracia = saldo
      from #gracia_acum
      where am_operacion  = @i_operacionca
      and   am_dividendo  = @w_gracia_int + 1
      and   am_gracia    >= 0
      and   tipo_rubro   <> 'I'
      and   concepto      = am_concepto
      and   secuencia     = am_secuencia
      
      if @@error <> 0
         return 705050

      if @w_dist_gracia = 'S'
      begin
         select 
         @w_dividendo      = 0,
         @w_concepto       = '',
         @w_concepto_ant   = '',
         @w_secuencia      = 0,
         @w_secuencia_ant  = 0
         
         -- DETERMINAR EL NUMERO DE DIVIDENDOS EXISTENTES
         select @w_num_dividendos = count(1)
         from   ca_dividendo
         where  di_operacion  = @i_operacionca
      
         while 1=1
         begin
            select top 1
            @w_concepto  = am_concepto,
            @w_estado    = am_estado,
            @w_secuencia = am_secuencia,
            @w_dividendo = am_dividendo
            from ca_amortizacion, ca_rubro_op, #gracia_acum
            where am_operacion  = @i_operacionca
            and   am_gracia     > 0
            and   am_concepto  >= @w_concepto
            and   am_secuencia >= case when am_concepto = @w_concepto                                 then @w_secuencia else 0 end
            and   am_dividendo  > case when am_concepto = @w_concepto and am_secuencia = @w_secuencia then @w_dividendo else 0 end
            and   ro_operacion  = am_operacion
            and   ro_concepto   = am_concepto
            and   ro_tipo_rubro = 'I'
            and   tipo_rubro    = ro_tipo_rubro
            and   concepto      = am_concepto
            and   secuencia     = am_secuencia            
            order by am_concepto, am_secuencia, am_dividendo
            
            if @@rowcount = 0
               break
               
            if @w_concepto <> @w_concepto_ant or @w_secuencia <> @w_secuencia_ant
            begin
               select 
               @w_gracia_acum = saldo
               from #gracia_acum
               where concepto  = @w_concepto
               and   secuencia = @w_secuencia
               
               select 
               @w_concepto_ant  = @w_concepto,
               @w_secuencia_ant = @w_secuencia,
               @w_num_div_tmp   = @w_num_dividendos - @w_gracia_int
            end

            select @w_vlr_gracia = round(@w_gracia_acum / @w_num_div_tmp, @i_num_dec)
            
            select 
            @w_gracia_acum = @w_gracia_acum - @w_vlr_gracia,
            @w_num_div_tmp = @w_num_div_tmp - 1
         
            update ca_amortizacion
            set am_gracia = @w_vlr_gracia
            where am_operacion = @i_operacionca
            and   am_dividendo = @w_dividendo
            and   am_concepto  = @w_concepto
            and   am_secuencia = @w_secuencia
            
            select
            @w_error    = @@error,
            @w_rowcount = @@rowcount
            
            if @@error <> 0
               return 705050
               
            if @w_rowcount = 0
            begin
               insert ca_amortizacion(
               am_operacion,     am_dividendo,        am_concepto,
               am_estado,        am_periodo,          am_cuota,
               am_gracia,        am_pagado,           am_acumulado,
               am_secuencia                                    )
               values(
               @i_operacionca,   @w_dividendo,        @w_concepto,
               @w_estado,        0,                   0,
               @w_vlr_gracia,    0,                   0,
               @w_secuencia)
               
               if @@error <> 0
                  return 721305
            end
         end
      end
      else if @w_dist_gracia = 'N'
      begin
         update ca_amortizacion
         set am_gracia = saldo
         from #gracia_acum
         where am_operacion = @i_operacionca
         and   am_dividendo = @w_gracia_int + 1
         and   am_gracia   >= 0
         and   tipo_rubro   = 'I'
         and   concepto     = am_concepto
         and   secuencia    = am_secuencia
         
         if @@error <> 0
            return 705050
      end
   end   
   -- FIN - REQ 175: PEQUEÑA EMPRESA
     
   if @w_moneda  <>  @w_moneda_nacional    and @i_tipo_cobro = 'E'
      select  @i_tipo_cobro = 'A'
   
   select @i_tipo_reduccion = 'N'
   
   if @w_tipo_cobro_o  = 'E'
      select @i_tipo_cobro = 'A'
   
   --SI LA CANCELACION ES TOTAL Y PROYECTADA, LOS ACUMULADOS DE LOS OTROS CONCEPTOS
   --DEBEN ESTAR EN CERO PARA LAS CUOTAS  NO VIGENTES SI EXISTEN VALORES
   
   ---NR-379
   
   select @w_parametro_cxcintes = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'CXCINT'
   set transaction isolation level read uncommitted
   
   /*  -- KDR Sección no aplica para la versión de Finca
   select @w_concepto_traslado  = co_concepto
   from ca_concepto
   where co_concepto = @w_parametro_cxcintes
   
   if @@rowcount = 0 
      return 711017
   */ -- FIN KDR
      
   CREATE TABLE #amort1 (
   operacion INT NULL,
   concepto  VARCHAR(20) NULL,
   dividendo INT NULL,
   categoria CHAR(1) NULL,
   fpago     CHAR(1) NULL
   )
   
   INSERT INTO #amort1
   SELECT am_operacion, co_concepto, am_dividendo, co_categoria, ro_fpago
   from   ca_amortizacion, ca_dividendo,ca_concepto, ca_rubro_op
   where  am_operacion = @i_operacionca
   and    di_operacion = @i_operacionca
   and    am_operacion = di_operacion
   and    am_dividendo = di_dividendo
   and    am_concepto   = co_concepto
   and    co_categoria  not in  ('C', 'M', 'I')  --OTROS CONCEPTOS
   and    am_concepto <> isnull(@w_concepto_traslado,'')  -- NR-379
   and    di_dividendo > @w_div_vigente
   and    am_estado    <> 3
   and    ro_operacion = @i_operacionca
   and    ro_concepto  = am_concepto
   and    ro_fpago    <> 'M'
   
   update ca_amortizacion
   set   am_acumulado = 0
   FROM ca_amortizacion, #amort1
   WHERE am_operacion = operacion
    AND am_operacion  = @i_operacionca
    AND am_concepto   = concepto
    and am_concepto <> isnull(@w_concepto_traslado,'')  -- NR-379
    AND am_dividendo = dividendo
    and am_estado    <> 3
    and am_dividendo > @w_div_vigente    
    
       
   /*
   update ca_amortizacion
   set    am_acumulado = 0
   from   ca_amortizacion, ca_dividendo,ca_concepto, ca_rubro_op
   where  am_operacion = @i_operacionca
   and    di_operacion = @i_operacionca
   and    am_operacion = di_operacion
   and    am_dividendo = di_dividendo
   and    am_concepto   = co_concepto
   and    co_categoria  not in  ('C', 'M', 'I')  --OTROS CONCEPTOS
   and    am_concepto <> @w_concepto_traslado  -- NR-379
   and    di_dividendo > @w_div_vigente
   and    am_estado    <> 3
   and    ro_operacion = @i_operacionca
   and    ro_concepto  = am_concepto
   and    ro_fpago    <> 'M'
   */
   
   
end

---SI EL VALOR QUE LLEGA A ESTE PROGRAMA ES MENOR QUE EL PROYECTADO DE INTERESES
---NO SE CALCULA VP PARA EVITAR ACTUALIZACIONES DEL VALOR INT CUANDO NO PAGARA NADA
select @w_proyectado_int = sum(am_cuota + am_gracia - am_pagado)
from   ca_amortizacion,ca_rubro_op
where  am_operacion = @i_operacionca
and    am_dividendo = @w_div_vigente
and    ro_operacion = am_operacion
and    ro_concepto = am_concepto
and    ro_tipo_rubro = 'I'

-- EL VALOR PRESENTE SE IMPLEMENTA COMO PAGO PROYECTADO PERO 
-- TOMANDO EN CUENTA LOS VALORES AHORRADOS
if @i_tipo_cobro = 'E' select @i_tipo_cobro = 'P'
begin
   --  ESTE PROGRAMA CALCULA EL VALOR PRESENTE Y ACTUALIZA EL
   --  ACUMULADO DE LAS CUOTAS ANTES DE LA APLICACION DEL PAGO
   --  PARA CANCELAR LA OPERACION
   if  @w_cancelar = 'S'  and @w_tipo_cobro_o  = 'E' and @w_fecha_proceso <  @w_fecha_fin and @w_concepto_int <> @w_int_ant and @w_proyectado_int > 0.1
   begin
      if @i_en_gracia_int = 'N' and  @w_moneda  =  @w_moneda_nacional
      begin
         exec @w_error   = sp_actualiza_acum_int_vp
              @i_operacion      = @i_operacionca,
              @i_monto_pago     = 0,
              @i_cancelar       = @w_cancelar,
              @i_secuencial_pag = @i_secuencial_pag,
              @i_fecha_proceso  = @i_fecha_proceso,
              @o_causacion_pte  = @w_causacion_pte out,
              @o_causacion_pte_ajuste = @w_causacion_pte_ajuste out
         
         if @w_error <> 0
         begin
            return @w_error
         end
      end
      ---SI EL VALOR PRESENTE RETORNA NEGATIVOS, SE DISMINUYE
      ---DEL CAPITAL EL VALOR DE ESTE INTERES POR ESTE MOTIVO SE AUTMENTA EL VALOR DEL PAGO
      ---PARA CANCELAR EL CREDITO TOTALMENTE
      
      if @w_causacion_pte < 0 
         select @i_monto_pago = @i_monto_pago + (@w_causacion_pte * -1)
      ---FIN AMENTAR AL PAGO EL VALOR DE INTERESES EN VALOR PRESENTE  POR DEVOLUCION DE INTERESES
     
      ---SI LA OPERACION ESTA CASTIGADA NO SE GENERA PRV POR  PAGO
      if @w_op_estado = 4
         select @w_causacion_pte = 0
   end
end

-- ESTE PROGRAMA CALCULA EL VALOR PRESENTE Y ACTUALIZA EL
-- ACUMULADO DE LAS CUOTAS ANTES DE LA APLICACION DEL PAGO
-- PARA APLICACION DEL PAGO EXTRAORDINARIO NORMAL

if  @w_cancelar = 'N' and @i_tipo_reduccion = 'N'  and @w_tipo_cobro_o = 'E' and @w_fecha_proceso <  @w_fecha_fin and @w_concepto_int <> @w_int_ant
begin
   select @i_tipo_cobro = 'P'
   
   ---SOLO SI EL VALOR PAGADO ES MAYOR  ALMENOS AL INT PROYECTADO SE JUSTIFICA HACER VALOR PRESENTE
   ---CASO CONTRARIO NO PUESTO QUE SE RECALCULARIA EL VALOR DEL INTERES ACUMULADO PARA LA CUOTA VIGENTE 
   --- Y SE CAUSARIA ALGO QUE NO PAGARA POR QUE NO ALCANZA
   
   if  @i_monto_pago > @w_proyectado_int
   begin
      exec @w_error = sp_actualiza_acum_int_vp
           @i_operacion      = @i_operacionca,
           @i_monto_pago     = @i_monto_pago,
           @i_cancelar       = @w_cancelar,
           @i_secuencial_pag = @i_secuencial_pag,
           @i_fecha_proceso  = @i_fecha_proceso,
           @o_causacion_pte  = @w_causacion_pte out,
           @o_causacion_pte_ajuste = @w_causacion_pte_ajuste out
      
      if @w_error <> 0
      begin
         return @w_error
      end
   end
   ELSE
     select @i_tipo_cobro = 'P'
   
   --ESTE VALOR ES LA DEVOLUCION DE INTERES QUE PASA A SER PARTE DEL PAGO
   if @w_causacion_pte < 0 
      select @i_monto_pago = @i_monto_pago + (@w_causacion_pte * -1)
   
   select @w_revisar_reajuste = 'S' ---Puede existir un reajuste de intereses por abono extraordinario NORMAL
   
   ---SI LA OPERACION ESTA CASTIGADA NO SE GENERA PRV POR  PAGO
   if @w_op_estado = 4
      select @w_causacion_pte = 0
end


--FIN  ESTE PROGRAMA CALCULA EL VALOR PRESENTE 
--CURSOR POR DIVIDENDOS 
--ESTE CURSOR SELECCIONA LOS DIVIDENDOS MAS VENCIDOS HASTA EL VIGENTE

select @w_aplic = 0

if @i_dividendo = 0 
   declare
      dividendos cursor
      for select di_dividendo, di_fecha_ven, di_estado,
                 di_dias_cuota
          from ca_dividendo
          where di_operacion  = @i_operacionca
          and   di_estado    <> @w_est_cancelado
          order by di_dividendo
      for read only
else
   declare
      dividendos cursor
      for select di_dividendo, di_fecha_ven, di_estado,
                 di_dias_cuota
          from   ca_dividendo
          where  di_operacion  = @i_operacionca
          and    di_dividendo = @i_dividendo
          and    di_estado    <> @w_est_cancelado
          order  by di_dividendo
      for read only

open dividendos

fetch dividendos
into  @w_di_dividendo, @w_di_fecha_ven, @w_di_estado,
      @w_dias_cuota

while @@fetch_status = 0 begin

   if (@@fetch_status = -1) return 708899 
   
   -- CURSOR POR PRIORIDADES DE PAGO 
   declare prioridades cursor for select distinct ap_prioridad
   from   ca_abono_prioridad
   where  ap_operacion = @i_operacionca
   and    ap_secuencial_ing = @i_secuencial_ing
   order  by ap_prioridad 
   for read only
   
   open prioridades
   
   fetch prioridades  into  @w_ap_prioridad
   
   while @@fetch_status = 0   begin
      
      if (@@fetch_status = -1) return 708899
      
--      IF @w_di_dividendo = @w_div_vigente  --LPO TEC  --LPO CDIG ABONO_XTRA
--         SELECT @w_tipo_cobro_aux = @w_tipo_cobro_op  --LPO CDIG ABONO_XTRA
--      ELSE                                            --LPO CDIG ABONO_XTRA
         SELECT @w_tipo_cobro_aux = @i_tipo_cobro
         
      --LPO TEC NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO:         
      IF @w_di_dividendo = @w_div_vigente AND @w_tipo_grupal = 'G' AND @i_es_precancelacion = 'S'
         SELECT @w_tipo_cobro_aux = 'P' --Proyectado
         
      /* AMO 20220610
      IF @w_di_dividendo = @w_div_vigente AND @w_tipo_grupal IN ('I', 'N') AND @i_es_precancelacion = 'S'
         SELECT @w_tipo_cobro_aux = 'A' --Acumulado
      */
      --LPO TEC FIN NUEVA DEFINCION, PARA GRUPAL SIEMPRE DEBE SER PROYECTADO, Y PARA INDIVIDUAL SIEMPRE ACUMULADO
         
      
      -- MONTO DE LA PRIORIDAD POR TIPO DE COBRO 
      exec @w_error = sp_monto_pago
      @i_operacionca    = @i_operacionca,
      @i_dividendo      = @w_di_dividendo,
      @i_tipo_cobro     = @w_tipo_cobro_aux, --@i_tipo_cobro, LPO TEC
      @i_fecha_pago     = @i_fecha_proceso,
      @i_prioridad      = @w_ap_prioridad,
      @i_secuencial_ing = @i_secuencial_ing,
      @i_dividendo_vig  = @w_div_vigente,
      @i_cancelar       = @w_cancelar,
      @i_en_gracia_int  = @i_en_gracia_int,
      @o_monto          = @w_monto_prioridad out
      
      if @w_error <> 0 return @w_error
      
      if @w_monto_prioridad <= 0 begin
      
         fetch prioridades into  @w_ap_prioridad
         continue
      end
      
      select @w_inicial_prioridad = @w_monto_prioridad
      
      -- NO SE PUEDE PAGAR UN VALOR MAYOR AL VALOR DEL PAGO 
      
      if @w_monto_prioridad >= @i_monto_pago select @w_monto_prioridad = @i_monto_pago
         
      -- SELECCION DE LOS RUBROS POR PRIORIDAD Y DIVIDENDO 
      declare rubros cursor for select 
      ro_concepto, ro_tipo_rubro, ro_fpago
      from   ca_abono_prioridad, ca_rubro_op
      where  ap_secuencial_ing = @i_secuencial_ing
      and    ap_operacion      = @i_operacionca
      and    ap_prioridad      = @w_ap_prioridad
      and    ro_operacion      = @i_operacionca
      and    ro_concepto       = ap_concepto 
      and    @w_monto_prioridad > 0 --  PARA QUE PAGUE VALORES POSITIVOS
      for read only
      
      open rubros
      
      fetch rubros into  
      @w_am_concepto, @w_ro_tipo_rubro, @w_fpago
      
      while @@fetch_status = 0  begin
      
         if (@@fetch_status = -1) return 710004
            
         /* En el calculo del Iva (Robro Anterior) no es posible realizar proporcionalidad por el valor sobrante */
         select @w_proporcional = 'N'
         
         
            
         -- MONTO DEL RUBRO SELECCIONADO
         if @w_proporcional = 'N' begin
            exec @w_error = sp_monto_pago_rubro
            @i_operacionca     = @i_operacionca,
            @i_dividendo       = @w_di_dividendo,
            @i_tipo_cobro      = @w_tipo_cobro_aux, --@i_tipo_cobro, LPO TEC
            @i_fecha_pago      = @i_fecha_proceso,
            @i_concepto        = @w_am_concepto,
            @i_dividendo_vig   = @w_div_vigente, 
            @i_cancelar        = @w_cancelar,
            @i_en_gracia_int   = @i_en_gracia_int,
            @o_monto           = @w_monto_rubro out

            if @w_error <> 0 return @w_error

         end
         
         if @w_monto_rubro <= 0 begin
            fetch rubros into @w_am_concepto,@w_ro_tipo_rubro, @w_fpago
            continue
         end
         
         select @w_inicial_rubro = @w_monto_rubro
         
         select @w_dif = @i_monto_pago
         
         IF @i_debug = 'S'
           PRINT 'sp_aplicacion_cuota_normal antes sp_abona_rubro 4.1 @w_di_dividendo = ' + convert(VARCHAR(10), @w_di_dividendo) + ' @w_am_concepto = ' + @w_am_concepto + ' @i_monto_pago = ' + convert(CHAR(10),@i_monto_pago) + ' @w_monto_prioridad = ' + convert(CHAR(10),@w_monto_prioridad) + ' @w_monto_rubro = ' + convert(CHAR(10),@w_monto_rubro) + ' @i_monto_pago = ' + convert(CHAR(10), @i_monto_pago)
           
          -- APLICACION DEL PAGO PARA EL RUBRO
         exec @w_error = sp_abona_rubro
         @s_ofi                = @s_ofi,
         @s_sesn               = @s_sesn,
         @s_user               = @s_user,
         @s_term               = @s_term,
         @s_date               = @s_date,
         @i_secuencial_pag     = @i_secuencial_pag,
         @i_operacionca        = @i_operacionca,
         @i_dividendo          = @w_di_dividendo,
         @i_concepto           = @w_am_concepto,
         @i_monto_pago         = @i_monto_pago,
         @i_monto_prioridad    = @w_monto_prioridad,
         @i_monto_rubro        = @w_monto_rubro,
         @i_tipo_cobro         = @w_tipo_cobro_aux, --@i_tipo_cobro, --LPO TEC
         @i_en_linea           = @i_en_linea,
         @i_tipo_rubro         = @w_ro_tipo_rubro,
         @i_fecha_pago         = @i_fecha_proceso,
         @i_condonacion        = 'N',
         @i_cotizacion         = @i_cotizacion,
         @i_tcotizacion        = @i_tcotizacion,
         @i_inicial_prioridad  = @w_inicial_prioridad,
         @i_inicial_rubro      = @w_inicial_rubro,
         @i_fpago              = @w_fpago,
         @i_dias_pagados       = @w_dias,
         @i_tasa_pago          = @w_tasa_prepago,
         @i_cotizacion_dia_sus = @i_cotizacion_dia_sus,
         @i_en_gracia_int      = @i_en_gracia_int,
         @o_sobrante_pago      = @i_monto_pago      out
         
         select @w_dif = @w_dif - @i_monto_pago
         select @w_aplic = @w_aplic +  @w_dif

		 IF @i_debug = 'S'
           PRINT 'sp_aplicacion_cuota_normal despues sp_abona_rubro 4.2 @w_di_dividendo = ' + convert(VARCHAR(10), @w_di_dividendo) + ' @w_am_concepto = ' + @w_am_concepto + ' @i_monto_pago = ' + convert(CHAR(10), @i_monto_pago)         
           
         if @w_error <> 0 
           return @w_error
         
         if @w_monto_prioridad <= 0 
           select @w_salir_rubro = 'S'
         
         if @i_monto_pago < @w_vlr_despreciable begin
            select 
            @w_salir_rubro = 'S',
            @w_salir_dividendo = 'S',
            @w_salir_prioridad = 'S'
         end
         
         if @w_salir_rubro = 'S' begin
            select @w_salir_rubro = 'N'
            break
         end
         
         fetch rubros into  
         @w_am_concepto, @w_ro_tipo_rubro, @w_fpago
         
      end -- CURSOR RUBROS 
      
      close rubros
      deallocate rubros
      
      PROXIMO:
      
      if @w_salir_prioridad = 'S' begin
         select @w_salir_prioridad = 'N'
         break
      end
      
      fetch prioridades
      into  @w_ap_prioridad
   end -- CURSOR PRIORIDADES 
   
   close prioridades
   deallocate prioridades
   
  
   -- VERIFICAR CANCELACION DEL DIVIDENDO 
   select @w_cancelar_div = 'N'
   
   if (@i_tipo_cobro = 'A') or (@i_tipo_cobro = 'P'  and  @i_cancelar   = 'S')
   begin
      select @w_total_div= isnull(sum(am_acumulado + am_gracia - am_pagado), 0)
      from   ca_amortizacion, ca_rubro_op, ca_concepto
      where  am_operacion = @i_operacionca
      and    am_operacion  = ro_operacion 
      and    am_concepto    = ro_concepto
      and    am_estado   <> @w_est_cancelado      
      and    co_concepto  = am_concepto
      and    (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir    
                  (am_dividendo between @w_di_dividendo and @w_di_dividendo + charindex (ro_fpago, 'A')
                   and not(co_categoria in ('S','A') and am_secuencia > 1)
                  )
               or (am_dividendo = @w_di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
             )
      
      select @w_total_div = isnull(@w_total_div,0)
         
      select @w_total_div = (abs(@w_total_div) + @w_total_div)/2.0 
         
      if @w_total_div < @w_vlr_despreciable 
        select @w_cancelar_div = 'S'
      
      IF @i_debug = 'S'
        PRINT 'sp_aplicacion_cuota_normal 4.3 @w_cancelar_div = ' + @w_cancelar_div   
   end 


   
   if @i_tipo_cobro = 'P'  and  @i_cancelar   = 'N' and @i_prepago = 'N'
   begin
      select @w_cancelar_div = 'N'
      select @w_total_div=isnull(sum(am_cuota+am_gracia-am_pagado),0)
      from   ca_amortizacion, ca_rubro_op, ca_concepto
      where  am_operacion = @i_operacionca
      and    am_operacion  = ro_operacion 
      and    am_concepto    = ro_concepto
      and    am_estado   <> @w_est_cancelado
      and    co_concepto  = am_concepto
      and    (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir    
                  (am_dividendo between @w_di_dividendo and @w_di_dividendo + charindex (ro_fpago, 'A')
                   and not(co_categoria in ('S','A') and am_secuencia > 1)
                  )
               or (am_dividendo = @w_di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
             )
      
      select @w_total_div = isnull(@w_total_div,0)
      
      select @w_total_div = (abs(@w_total_div) + @w_total_div)/2.0 
      
      if @w_total_div < @w_vlr_despreciable
         select @w_cancelar_div = 'S'
      
      IF @i_debug = 'S'   
        PRINT 'sp_aplicacion_cuota_normal 4.4 @w_cancelar_div = ' + @w_cancelar_div
   end
   
   if @i_tipo_cobro = 'P'  and  @i_cancelar   = 'N' and @i_prepago = 'S'
   begin
      select @w_cancelar_div = 'N'
      select @w_total_div=isnull(sum(am_cuota+am_gracia-am_pagado),0)
      from   ca_amortizacion, ca_rubro_op, ca_concepto
      where  am_operacion = @i_operacionca
      and    am_operacion  = ro_operacion 
      and    am_concepto    = ro_concepto
      and    co_concepto  = am_concepto
      and    (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir        
                  (am_dividendo between @w_di_dividendo and @w_di_dividendo + charindex (ro_fpago, 'A')
                   and not(co_categoria in ('S','A') and am_secuencia > 1)
                  )
               or (am_dividendo = @w_di_dividendo and co_categoria in ('S','A') and am_secuencia > 1)
             )
      
      select @w_total_div = isnull(@w_total_div,0)
      
      select @w_total_div = (abs(@w_total_div) + @w_total_div)/2.0 
      
      if @w_total_div < @w_vlr_despreciable
         select @w_cancelar_div = 'S'
      
      IF @i_debug = 'S'   
        PRINT 'sp_aplicacion_cuota_normal 4.5 @w_cancelar_div = ' + @w_cancelar_div
   end
     
   if @w_cancelar_div = 'S' and @i_cancelar <> 'S' begin
      -- INI - REQ 175: PEQUEÑA EMPRESA - PROVISION FALTANTE DE INTERESES EN GRACIA
      if @w_gracia_int > 0 and @w_dist_gracia <> 'C'
      begin
         if exists(
         select 1
         from ca_amortizacion, ca_rubro_op
         where am_operacion  = @i_operacionca
         and   am_dividendo  = @w_di_dividendo
         and   am_gracia     < 0
         and   am_cuota      > am_acumulado
         and   ro_operacion  = am_operacion
         and   ro_concepto   = am_concepto
         and   ro_tipo_rubro = 'I'            )
         begin
            -- PROVISION DEL VALOR DE GRACIA

            insert into ca_transaccion_prv with (rowlock)(
            tp_fecha_mov,              tp_operacion,              tp_fecha_ref,
            tp_secuencial_ref,         tp_estado,                 tp_dividendo,
            tp_concepto,               tp_codvalor,               
            tp_monto,                  tp_secuencia,              tp_comprobante,
            tp_ofi_oper,               tp_monto_mn,               tp_moneda,
            tp_cotizacion,             tp_tcotizacion,            tp_reestructuracion)
            select
            @s_date,                   @i_operacionca,            @w_fecha_proceso,
            @i_secuencial_pag,         'ING',                     @w_di_dividendo,
            am_concepto,               co_codigo * 1000 + am_estado * 10 + am_periodo,
            am_cuota - am_acumulado,   am_secuencia,              0,
            @w_oficina_op,             round((am_cuota - am_acumulado)*@i_cotizacion,@i_num_dec_n), @w_moneda,
            @i_cotizacion,             @i_tcotizacion,            @w_reestructuracion
            from ca_amortizacion, ca_rubro_op, ca_concepto
            where am_operacion  = @i_operacionca
            and   am_dividendo  = @w_di_dividendo
            and   am_gracia     < 0
            and   am_cuota      > am_acumulado
            and   ro_operacion  = am_operacion
            and   ro_concepto   = am_concepto
            and   ro_tipo_rubro = 'I'
            and   co_concepto   = ro_concepto
            
            if @@error <> 0 return 708165

            update ca_amortizacion
            set am_acumulado = am_cuota
            from ca_rubro_op
            where am_operacion  = @i_operacionca
            and   am_dividendo  = @w_di_dividendo
            and   am_gracia     < 0
            and   am_cuota      > am_acumulado
            and   ro_operacion  = am_operacion
            and   ro_concepto   = am_concepto
            and   ro_tipo_rubro = 'I'
                        
            if @@error <> 0
               return 710002
               
         end
      end
      -- FIN - REQ 175: PEQUEÑA EMPRESA
      
      update ca_dividendo set    
      di_estado    = @w_est_cancelado,
      di_fecha_can = @w_fecha_proceso
      where  di_operacion = @i_operacionca
      and    di_dividendo = @w_di_dividendo
      
      if @@error <>0 return 710002
      
      update ca_amortizacion
      set    am_estado = @w_est_cancelado
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_di_dividendo
      
      if @@error <>0 return 710002
      
      if @w_di_estado = @w_est_vigente  begin  
      
	      -- VIGENTE EL SIGUIENTE
	      update ca_dividendo
	      set    di_estado = @w_est_vigente
	      where  di_operacion = @i_operacionca
	      and    di_dividendo = @w_di_dividendo + 1
	      and    di_estado    = @w_est_novigente
	      
	      if @@error <>0 return 710002
	      
	      update ca_amortizacion
	      set    am_estado = @w_est_vigente
	      from   ca_amortizacion 
	      where  am_operacion = @i_operacionca
	      and    am_dividendo = @w_di_dividendo + 1
	      and    am_estado    = @w_est_novigente
	      
	      if @@error <>0 return 710002
	      
	      update ca_amortizacion with (rowlock) set   
	      am_acumulado = am_cuota,
	      am_estado    = @w_op_estado
	      from ca_rubro_op
	      where am_operacion = ro_operacion
	      and   am_concepto  = ro_concepto
	      and   (am_gracia <= 0 or am_cuota <> 0)                  -- REQ 175: PEQUEÑA EMPRESA
	      and   ro_provisiona = 'N'
	      and   ro_tipo_rubro <> 'C'
	      and   ro_operacion  = @i_operacionca
	      and   am_dividendo  = @w_di_dividendo + 1
         and   am_estado     <> @w_est_cancelado
	      
	      if @@error <> 0 return  705050

      end ---26999 solo este end 
      
      if @w_tacuerdo not in ('P','X')                             -- REQ 089: ACUERDOS DE PAGO
      begin
         update ca_amortizacion with (rowlock) set   
         am_acumulado = am_cuota,
         am_estado    = @w_op_estado
         from ca_rubro_op
         where am_operacion = ro_operacion
         and   am_concepto  = ro_concepto
         and   (am_gracia <= 0 or am_cuota <> 0)                  -- REQ 175: PEQUEÑA EMPRESA
         and   ro_provisiona = 'N'
         and   ro_tipo_rubro <> 'C'
         and   ro_operacion  = @i_operacionca
         and   am_dividendo  = @w_di_dividendo + 1
         and   am_estado     <> @w_est_cancelado
         
         if @@error <> 0 return  705050

      end
   end
   
   if @i_fecha_proceso < @w_di_fecha_ven
      select @w_di_fecha_ini = @w_di_fecha_ven
   
   -- PARA CAMBIAR ESTADO DE RUBROS EN ca_amortizacion
   
   select @w_estado_dividendo =  di_estado
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_dividendo = @w_di_dividendo
   
   if @w_estado_dividendo = @w_est_cancelado and @w_ro_tipo_rubro = 'M'
   begin
         
      update ca_amortizacion
      set    am_estado = @w_est_cancelado
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_di_dividendo
      
      if @@error <>0 return 710002
   end
   
   --FIN PARA CANCELAR EL RUBRO EN ca_amortizacion
   
   if @w_salir_dividendo <> 'N'
   begin
      select @w_salir_dividendo = 'N'
      break
   end
   
   fetch dividendos into  
   @w_di_dividendo, @w_di_fecha_ven, @w_di_estado, @w_dias_cuota
   
end -- CURSOR DIVIDENDOS 

close dividendos
deallocate dividendos

-- VP DIFERENCIA DE CAUSACION SI ESTA ES MAYOR QUE EL ACUMULADO SE DEBE GENERAR UNA 
-- TRANSACCION DE AJUSTE 

if @w_causacion_pte > 0
begin
   exec @w_secuencial_vp = sp_gen_sec
        @i_operacion          = @i_operacionca
   
   select @w_observacion = 'CAUSACION POR COBRO EN VALOR PRESENTE'
   
   -- INSERCION DE CABECERA CONTABLE DE CARTERA 
   insert into ca_transaccion
         (tr_fecha_mov,       tr_toperacion,      tr_moneda,
          tr_operacion,     tr_tran,              tr_secuencial,
          tr_en_linea,      tr_banco,             tr_dias_calc,
          tr_ofi_oper,      tr_ofi_usu,           tr_usuario,
          tr_terminal,      tr_fecha_ref,         tr_secuencial_ref, 
          tr_estado,        tr_observacion,       tr_gerente,
          tr_gar_admisible, tr_reestructuracion,  tr_calificacion,
          tr_fecha_cont,    tr_comprobante)
   values(@s_date,          @w_toperacion,      @w_moneda,
          @i_operacionca,   'PRV',              @w_secuencial_vp, 
          @i_en_linea,      @w_banco,           0,
          @w_oficina_op,    @s_ofi,             @s_user,
          @s_term,          @w_fecha_proceso,   -999,  
          'ING',            @w_observacion,      @w_gerente,
          isnull(@w_gar_admisible,''),isnull(@w_reestructuracion,''),isnull(@w_calificacion,''),
          @s_date,       0)
   
   if @@error <> 0
      return 708165
   
   select @w_causacion_pte_mn = round(@w_causacion_pte * @i_cotizacion, @i_num_dec_n)
   select @w_causacion_pte    =  round(@w_causacion_pte,@i_num_dec)
   
   select @w_codvalor1 = co_codigo
   from   ca_concepto
   where  co_concepto = @w_int
   
   select @w_codvalor1 = (@w_codvalor1 * 1000) + (@w_am_estado * 10) + @w_am_periodo
   
   insert into ca_det_trn
         (dtr_secuencial,   dtr_operacion,  dtr_dividendo,
          dtr_concepto,       dtr_estado,   dtr_periodo,
          dtr_codvalor,       dtr_monto,   dtr_monto_mn,
          dtr_moneda,         dtr_cotizacion,   dtr_tcotizacion,
          dtr_afectacion,     dtr_cuenta,   dtr_beneficiario,
          dtr_monto_cont)
   values(@w_secuencial_vp,    @i_operacionca,      @w_div_vigente,
          @w_int,              1,                   0,
          @w_codvalor1,        @w_causacion_pte,    @w_causacion_pte_mn,
          @w_moneda,           @i_cotizacion,       @i_tcotizacion,
          'D',                 '00000',            'CARTERA',
          0.00)
   
   if @@error <> 0
   begin
      return 708166
   end
end
ELSE
begin
   if @w_causacion_pte < 0 ---INSERTA EL VALOR DEL INTERES PENDIENTE COMO PARTE DEL PAGO
   begin
      select @w_causacion_pte = @w_causacion_pte * -1
      
      -- PARAMETROS GENERALES
      select @w_parametro_devint = pa_char
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'DEVINT'
      select @w_rowcount = @@rowcount
      set transaction isolation level read uncommitted
      
      if @w_rowcount = 0
         return 710426
      
      select @w_concepto_devint = cp_producto,
             @w_codvalor1       = cp_codvalor
      from   ca_producto
      where  cp_producto = @w_parametro_devint
      
      if @@rowcount = 0
         return 710425
      
      select @w_causacion_pte_mn =  round(@w_causacion_pte * @i_cotizacion,@i_num_dec_n)
      select @w_causacion_pte    =  round(@w_causacion_pte,@i_num_dec)
      
      insert into ca_det_trn
            (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
             dtr_concepto,       dtr_estado,     dtr_periodo,
             dtr_codvalor,       dtr_monto,      dtr_monto_mn,
             dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
             dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
             dtr_monto_cont)
      values(@i_secuencial_pag,   @i_operacionca,      -1,
             @w_concepto_devint,  1,                   0,
             @w_codvalor1,        @w_causacion_pte,    @w_causacion_pte_mn,
             @w_moneda,           @i_cotizacion,       @i_tcotizacion,
             'D',                 '00000',            'CARTERA',
             0.00)
      
      if @@error <> 0
      begin
         return 708166
      end

      insert into ca_abono_rubro
            (ar_fecha_pag,        ar_secuencial,         ar_operacion,
             ar_dividendo,        ar_concepto,           ar_estado,
             ar_monto,            ar_monto_mn,           ar_moneda,
             ar_cotizacion,       ar_afectacion,         ar_tasa_pago,
             ar_dias_pagados)
      select @s_date,             dtr_secuencial,        dtr_operacion,
             dtr_dividendo,       dtr_concepto,          dtr_estado,
             dtr_monto,           dtr_monto_mn,          dtr_moneda,
             dtr_cotizacion,      'D',                   0,
             0
      from   ca_det_trn
      where  dtr_secuencial = @i_secuencial_pag   ---FORMA DE PAGO INTERNA DEL SISTEMA
      and    dtr_operacion  = @i_operacionca
      and    dtr_afectacion = 'D'
      and    dtr_concepto not like 'VAC_%'
      
      if @@error <> 0
      begin
         return 708166
      end
   end
end

---SE HACE AJUSTE POR QUE ACUMULADO  ES > QUE VP  Y HAY QUE REVERSAR LA PORCION DE PRV

if @w_causacion_pte_ajuste > 0
begin
   exec @w_secuencial_ajuste = sp_gen_sec
        @i_operacion          = @i_operacionca
   
   select @w_observacion = 'AJUSTE POR COBRO EN VALOR PRESENTE'
   
   -- INSERCION DE CABECERA CONTABLE DE CARTERA
   insert into ca_transaccion
         (tr_fecha_mov,     tr_toperacion,      tr_moneda,
          tr_operacion,     tr_tran,              tr_secuencial,
          tr_en_linea,      tr_banco,             tr_dias_calc,
          tr_ofi_oper,      tr_ofi_usu,           tr_usuario,
          tr_terminal,      tr_fecha_ref,         tr_secuencial_ref, 
          tr_estado,        tr_observacion,       tr_gerente,
          tr_gar_admisible, tr_reestructuracion,  tr_calificacion,
          tr_fecha_cont,    tr_comprobante)    
   values(@s_date,          @w_toperacion,        @w_moneda,
          @i_operacionca,   'PRV',                @w_secuencial_ajuste, 
          @i_en_linea,      @w_banco,             0,
          @w_oficina_op,    @s_ofi,               @s_user,
          @s_term,          @w_fecha_proceso,    -999,  
          'ING',            @w_observacion,      @w_gerente,
          isnull(@w_gar_admisible,''),isnull(@w_reestructuracion,''),isnull(@w_calificacion,''),
          @s_date,       0)
   
   if @@error <> 0
      return 708165 
   
   select @w_causacion_pte_mn = round(@w_causacion_pte_ajuste * @i_cotizacion, @i_num_dec_n)
   select @w_causacion_pte_ajuste    =  round(@w_causacion_pte_ajuste,@i_num_dec)
   
   select @w_codvalor_ajus = co_codigo
   from   ca_concepto
   where  co_concepto = @w_int
   
   select @w_codvalor_ajus     = (@w_codvalor_ajus * 1000) + (@w_am_estado * 10) + @w_am_periodo
   
   insert into ca_det_trn
         (dtr_secuencial,   dtr_operacion,  dtr_dividendo,
          dtr_concepto,       dtr_estado,   dtr_periodo,
          dtr_codvalor,       dtr_monto,   dtr_monto_mn,
          dtr_moneda,         dtr_cotizacion,   dtr_tcotizacion,
          dtr_afectacion,     dtr_cuenta,   dtr_beneficiario,
          dtr_monto_cont)
   values(@w_secuencial_ajuste,  @i_operacionca,      @w_div_vigente,
          @w_int,              1,       0,
          @w_codvalor_ajus,     @w_causacion_pte_ajuste*-1,    @w_causacion_pte_mn*-1,
          @w_moneda,           @i_cotizacion,       @i_tcotizacion,
          'D',                 '00000',            'CARTERA',
          0.00)
   
   if @@error <> 0
   begin
      return 708166
   end
end
-- FIN DE VALIDAR EL DIVIDENDO VIGENTE POR PAGO EXTRAORDINARIO NORMAL 

-- PROCESO PARA CANCELAR TOTALMENTE LA OPERACION
exec sp_calcula_saldo
     @i_operacion         = @i_operacionca,
     @i_tipo_pago         = @i_tipo_cobro,
     @i_tipo_reduccion	  = @i_tipo_reduccion_orig, -- AMO 20220610 SI ES ANTICIPO DE CUOTAS INCLUIR RUBROS DISTINTOS DE C,I O M
     @o_saldo             = @w_saldo_oper out

if @w_saldo_oper > @w_vlr_despreciable
   select  @i_operacionca =  @i_operacionca

ELSE
begin
   -- INI BLOQUE DESPLAZADO - PAQUETE 2 - REQ 266 ANEXO GARANTIA - 14/JUL/2011 - GAL
   if @i_en_linea = 'N'
      select @w_bandera_be = 'S'
   else
      select @w_bandera_be = 'N'
   
   exec @w_error = cob_custodia..sp_activar_garantia
        @i_opcion         = 'C',
        @i_tramite        = @w_tramite,
        @i_modo           = 2,
        @i_operacion      = 'I',
        @s_date           = @s_date,
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_ofi            = @s_ofi,
        @i_bandera_be     = @w_bandera_be
   
   if @w_error <> 0
   begin 
      --PRINT 'aplcuota.sp  salio por error de cob_custodia..sp_activar_garantia ' + cast(@w_error as varchar)
      while @@trancount > 1
            rollback
      return @w_error
   end 
   -- FIN BLOQUE DESPLAZADO - PAQUETE 2 - REQ 266 ANEXO GARANTIA
   
   --GENERACION DE LA COMISION DIFERIDA
   exec @w_error     = sp_comision_diferida
   @s_date           = @s_date,
   @i_operacion      = 'A',
   @i_operacionca    = @i_operacionca,
   @i_secuencial_ref = @i_secuencial_pag,
   @i_num_dec        = @i_num_dec,
   @i_num_dec_n      = @i_num_dec_n,
   @i_cotizacion     = @i_cotizacion,
   @i_tcotizacion    = @i_tcotizacion 
   
   if @w_error <> 0  return 724589  

   update ca_operacion
   set    op_estado = @w_est_cancelado
   where  op_operacion = @i_operacionca

   update ca_dividendo
   set    di_estado    = @w_est_cancelado,
          di_fecha_can = @w_fecha_proceso
   where  di_operacion = @i_operacionca
     and  di_estado    <> 3
   
   update ca_amortizacion
   set    am_estado = @w_est_cancelado
   where  am_operacion = @i_operacionca
   
   if @@error <> 0
   begin
      return 710002
   end 
   
   --ACTUALIZA EL ESTADO DEL PRODUCTO EN CLIENTES
   update cobis..cl_det_producto with (rowlock)
   set    dp_estado_ser = 'C'
   where  dp_producto = 7 
   and    dp_cuenta = @w_banco 
end  -- FIN DE CANCELAR TOTALMENTE LA OPERACION

select @o_sobrante = isnull(@i_monto_pago,0) 

update cob_cartera..ca_abono
set ab_extraordinario = 'S'
where ab_operacion = @i_operacionca 
and ab_secuencial_ing = @i_secuencial_ing 

return 0

go
