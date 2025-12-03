/************************************************************************/
/*   NOMBRE LOGICO:      batch1.sp                                      */
/*   NOMBRE FISICO:      sp_batch1                                      */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Credito y Cartera                              */
/*   DISENADO POR:       Fabian de la Torre                             */
/*   FECHA DE ESCRITURA: Ene. 98.                                       */
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
/*   Procedimiento que realiza la ejecucion del fin de dia de           */
/*   cartera.                                                           */
/*      FECHA              AUTOR             CAMBIOS                    */
/*   23/abr/2010   Fdo Carvajal      INTERFAZ CARTERA AHORROS           */
/*   10/Jun/2010   ELcira Pelaez     Causacion Paivas igual que las Act.*/
/*   11/Sep/2014   Carlos Avendaño   457 Atomicidad de Transacciones    */
/*   30/Sep/2015   ELcira Pelaez     Mejoras                            */
/*   14/OC/2015    ELcira Pelaez     no reajustar Normalizaciones       */
/*                                   de forma automatica                */
/*   12/Ago/2015   Elcira Pelaez     500 Cambio Entre lineas FIANGRO    */
/*                                   REQ. BAncamia                      */
/*   05/12/2016    R. Sánchez        Modif. Apropiación                 */
/*   07/06/2017    T. Baidal         Se agrega control fecha en Si      */
/*                                   cuando cambia es fin de mes        */
/*   24/07/2019    Sandro Vallejo    Pagos Grupales e Interciclos       */
/*   26/07/2019    Luis Ponce        Cambio Pagos Grupales e Interciclos*/
/*   12/12/2019    Luis Ponce        Orden Vencimiento Cuota y Operacion*/
/*   21/02/2019    Luis Ponce        CDIG comentar sp_abono_garantia por*/
/*                                   usar rp_ssn que no existe la nube  */
/*   17/03/2020    Luis Ponce        CDIG AJUSTE EN BATCH POR CONTROL DE*/
/*                                   COMMIT EN SPS'S DE AHORROS         */
/*   09/04/2020    Luis Ponce        CDIG Nuevo Esquema de Paralelismo  */
/*   06/08/2020   Sandro Vallejo     Debitos Paralelo                   */
/*   17/08/2020   Sandro Vallejo     Datos Consolidador                 */
/*   01/09/2020   Luis Ponce         CDIG Ajustes por Cobis Language    */
/*   19/11/2020   Patricio Narvaez   Esquema de Inicio de Dia, 7x24 y   */
/*                                   Doble Cierre automatico            */
/*   12/15/2020   Patricio Narvaez   Retornar error en simulacion       */
/*   12/18/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*   19/10/2021*  Kevin Rodríguez    Cálculo automatico de cargos por   */
/*                                   gestión de cobranza y se comenta   */
/*                                   proceso de pagos de garantía       */
/*   19/10/2021   Guisela Fernandez  Correccion de fecha de dia habil   */
/*                                   cuando no son diferentes meses     */
/*   22/04/2021   Guisela Fernandez  Incluye salida de log en caso de   */
/*                                   reajuste                           */
/*   26/07/2022     Kevin Rodríguez  Ajuste ini día después de calc INT */
/*   02/08/2022     Kevin Rodríguez  Comentar sección de eliminar abonos*/
/*   07/09/2022     Kevin Rodríguez  R193404 Se añade Proceso de cambio */
/*                                   de periodo contable                */
/*    06/06/2023	M. Cordova		 Cambio variable @w_calificacion,   */
/*									 @w_calificacion_sus y 				*/
/*									 @w_calificacion_sus4 de char(1) 	*/
/*									 a catalogo							*/
/*   14/08/2023     Kevin Rodríguez  B880687 Limita ejec. Gest. Cobranza*/
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_batch1')
   drop proc sp_batch1
go


CREATE proc sp_batch1
   @s_user                  varchar(14),
   @s_term                  varchar(30),
   @s_date                  datetime,
   @s_ofi                   smallint,
   @s_sesn                  int       = null,
   @i_en_linea              char(1)   = 'N',
   @i_banco                 char(24)  = null,
   @i_siguiente_dia         datetime  = null,
   @i_pry_pago              char(1)   = 'N',
   @i_aplicar_clausula      char(1)   = 'S',  --NO SE USA
   @i_aplicar_fecha_valor   char(1)   = 'N',
   @i_hijo                  varchar(2)= null,
   @i_control_fecha         char(1)   = 'S',
   @i_operacionFR           char(1)   = null,  -- KDR:Fecha valor o Reversa (Si es reversa, no calcula cargos gestión cobranza)
   @i_debug                 char(1)   = 'N',
   @i_pago_ext              char(1)   = 'N',  ---req 482   
   @i_hilo                  smallint  = 1,  --LPO Nuevo Esquema de Paralelismo -- Hilo de ejecucion. Paralelismo 
   @i_sarta                 int       = null,  --LPO Nuevo Esquema de Paralelismo 
   @i_batch                 int       = null,  --LPO Nuevo Esquema de Paralelismo 
   @i_simular_cierre        datetime  = null  --Simular el cierre enviando la fecha de cierre diferente a la de la tabla   
as
declare 
   @w_error              int,
   @w_return             int,
   @w_sp_name            descripcion,
   @w_fecha_proceso         datetime,
   @w_siguiente_dia         datetime,
   @w_fecha_ult_proceso     datetime,
   @w_operacionca           int,
   @w_op_cliente            int,
   @w_op_moneda             smallint,
   @w_op_oficina            smallint,
   @w_oficial               smallint,
   @w_banco                 char(24),
   @w_toperacion            char(10),
   @w_dias_anio             smallint,
   @w_estado                tinyint,
   @w_sector                char(10),
   @w_fecha_prox_pago       datetime,
   @w_est_vigente           tinyint,
   @w_est_vencido           tinyint,
   @w_est_novigente         tinyint,
   @w_est_cancelado         tinyint,
   @w_est_credito           tinyint,
   @w_est_suspenso          tinyint,
   @w_est_castigado         tinyint,
   @w_est_anulado           tinyint,
   @w_est_diferido          tinyint,
   @w_est_condonado          tinyint,
   @w_ciudad_op             int,
   @w_fecha_liq             datetime,
   @w_fecha_ini             datetime,
   @w_commit                char(1),
   @w_dias_clausula         int,
   @w_dias_vencidos         int,
   @w_fecha_cobis           datetime,
   @w_di_fecha_ven          datetime,
   @w_di_dividendo          smallint,
   @w_estado_final          tinyint,
   @w_dias_diferencia       int,
   @w_dividendo             smallint,
   @w_dividendo_cap         smallint,
   @w_rubro_capt            varchar(30),
   @w_calificacion          catalogo,
   @w_op_clase              char(10),
   @w_intereses             money,
   @w_mes_sig               int,
   @w_mes_act               int,
   @w_tdividendo            char(10),
   @w_mes_sig2              int,
   @w_base_calculo          char(1),
   @w_dias_interes          smallint,
   @w_periodo_int           smallint,
   @w_anio_mes_fc           varchar(7),
   @w_anio_mes_fp           varchar(7),
   @w_moneda_uvr            tinyint,
   @w_moneda_nacional       tinyint,
   @w_op_tipo               char(1),
   @w_fecha_tmp             datetime,
   @w_causacion             char(1),
   @w_est_comext            tinyint,
   @w_modalidad             char(1),
   @w_estado_cobranza       char(10),
   @w_oficial_nuevo         smallint,
   @w_dia                   int,
   @w_mes                   datetime,
   @w_suspenso              varchar(64),
   @w_arrastre              char(10),
   @w_suspension            char(10),
   @w_di_fecha_ini          datetime,
   @w_parametro_int         char(10),
   @w_calculo_intant        char(1),
   @w_correr_fecha          char(1),
   @w_monto                 money,
   @w_fecha_fin             datetime,
   @w_numero_reest          int,
   @w_num_renovacion        int,
   @w_tramite               int,
   @w_renovacion            char(1),
   @w_gar_admisible         char(1),
   @w_edad                  int,
   @w_periodo_cap           smallint,
   @w_plazo                 smallint,
   @w_tplazo                char(10),
   @w_destino               char(10),
   @w_mes_antes             smallint,
   @w_mes_despues           smallint,
   @w_op_naturaleza         char(1), 
   @w_di_prorroga           char(1),
   @w_dividendo1            smallint,
   @w_dividendo2            smallint,
   @w_di_fecha_ini1         datetime,
   @w_parametro_col         char(10),
   @w_descripcion           varchar(64),
   @w_msg                   varchar(132),
   @w_parametro_smc         char(10),
   @w_actualizar_fecha      char(1),
   @w_fecha_llega           datetime,
   @w_siguiente_fecha       datetime,
   @w_ofi_matriz            int,
   @w_fecha_cierre          datetime,
   @w_reestructuracion      char(1),
   @w_clausula_aplicada     char(1),
   @w_cotizacion_hoy        money,
   @w_cotizacion_siguiente  money,
   @w_fecha_cotizacion      datetime,
   @w_num_dias_sus          int,
   @w_num_dias_sus4         int,
   @w_min_di_fecha_ven      datetime,
   @w_param_ibc_mn          varchar(11),  
   @w_param_ibc_me          varchar(11),  
   @w_ibc                   varchar(11),  
   @w_ibc_mn                char(1),
   @w_ibc_me                char(1),
   @w_uvr                   char(1),
   @w_opcion_cap            char(1),
   @w_tipo_amortizacion     char(10),
   @w_garantia              varchar(64),
   @w_acepta_anticipos      char(1),
   @w_tipo_reduccion        char(1),
   @w_tipo_cobro            char(1),
   @w_tipo_aplicacion       char(1),
   @w_forma_pago_bsp        char(10),
   @w_div_vigente           smallint,
   @w_op_forma_pago         char(10),           -- FCP Interfaz Ahorros
   @w_op_cuenta             cuenta,             -- FCP Interfaz Ahorros
   @w_dividendo_procesar    smallint,           -- FCP Interfaz Ahorros
   @w_retencion             smallint,           -- FCP Interfaz Ahorros
   @w_estado_dividendo      smallint,           -- FCP Interfaz Ahorros
   @w_es_procesa            char(1),
   @w_ciudad_nacional       int,
   @w_contador              int,
   @w_hora                  varchar(30),
   @w_ms                    datetime,
   @w_ms_min                int,
   @w_concepto_cap          char(10),
   @w_concepto_int          char(10),
   @w_num_dec               tinyint,
   @w_aux1                  tinyint,
   @w_codigo_tmm            varchar(11), 
   @w_codigo_tmmex          varchar(11), 
   @w_parametro_mora        char(10),
   @w_tasa_icte             char(10),
   @w_periodo_anual         char(1),
   @w_mes_actual            int,
   @w_parametro_fag         varchar(30), 
   @w_o_secuencial          int, -- IFJ 06/DIC/2006 -- DEF 4767
   @w_ult_toperacion        char(10),
   @w_ult_oficina           smallint,
   @w_decimales_nacional    tinyint,
   @w_fecha_ini_tmm         datetime,
   @w_max_fecha             datetime,
   @w_max_sec               int,
   @w_tasa_maxima_mora      float,
   @w_tasa_maxima_mora4     float,
   @w_nuevo_interes         char(1),
   @w_tasa_corriente_efa    float,
   @w_tasa_corriente_nom    float,
   @w_op_fecha_prox_segven  datetime,
   @w_trancount             int,
   @w_pago_caja             char(1),
   @w_max_dividendo         smallint,
   @w_op_suspendio          char(1),
   @w_op_fecha_suspenso     datetime,
   @w_calificacion_sus      catalogo,
   @w_calificacion_sus4     catalogo,
   @w_dias_salir_sus        int,
   @w_cuota_validar         int,
   @w_dias_ven_cart         int, -- 609
   @w_codigo_tmm_clase      varchar(11),
   @w_codigo_tmmex_clase    varchar(11),
   @w_tlu_clase             varchar(11),
   @w_tluex_clase           varchar(11),
   @w_rowcount              int,
   @w_mipymes               varchar(10),
   @w_detener_proceso       char(1),
   @w_tramite_reest         int,
   @w_fecha_pag             datetime,
   @w_div_procesado         smallint,              -- REQ 175: PEQUEÑA EMPRESA
   @w_tacuerdo              char(1),                -- REQ 089: ACUERDOS DE PAGO - 15/ENE/2011
   @w_dividendos_vencidos   smallint,
   @w_campana               int,
   @w_tr_tipo               char(1),
   @w_oficina_destino       int,
   @w_oficial_destino       int,
   @w_tipo_grupal           char(1),
   @w_banco_interciclo      cuenta,
   @s_ssn                   INT,      --LPO TEC
   @w_aux                   INT,
   @s_date_sigdiahabil      datetime,
   @s_date_sigdiahabil_aux  datetime,
   @s_date_aux              datetime,
   @w_fecha_proceso_ini_dia datetime,
   @w_fin_mes_contable      datetime,
   @w_cambio_per_contable   char(1)   -- KDR Parámetro que habilita/deshabilita proceso de Cambio de Periodo Contable
   
select @w_trancount = @@trancount
    
/* CARGADO DE VARIABLES DE TRABAJO */
select 
@w_sp_name          = 'sp_batch1',
@s_user             = isnull(@s_user, 'sa'),
@s_term             = isnull(@s_term, 'BATCH_CARTERA'),
@w_commit           = 'N',
@w_actualizar_fecha = 'N',
@w_contador         = 0,
@w_ult_toperacion   = '~',
@w_ult_oficina      = -1,
@w_ms_min           = 80,
@w_max_dividendo    = 0,
@w_ibc_mn           = 'N',
@w_ibc_me           = 'N',
@w_uvr              = 'N',
@w_detener_proceso  = 'N'

select @s_date = convert(varchar(10),fc_fecha_cierre,101)
from   cobis..ba_fecha_cierre with (nolock)
where  fc_producto = 7

--Solo para pruebas @i_simular_cierre se envia la fecha de cierre
if @i_simular_cierre is not null
   select @s_date = @i_simular_cierre

select @s_date_aux         = @s_date,
       @s_date_sigdiahabil = @s_date,
       @s_date_sigdiahabil_aux = @s_date

select 
@w_mes_actual      = datepart(mm, @s_date),
@w_anio_mes_fc     = substring(convert(varchar, @s_date, 111), 1, 7)
 
-- PERIODICIDAD ANUAL
select @w_periodo_anual = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'PAN' --PERIODICIDAD ANUAL
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 begin
   select @w_error = 710367
   goto ERROR_BATCH
end
 
select @w_parametro_mora = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'IMO' ---Concepto MORA
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 begin
   select @w_error = 710367
   goto ERROR_BATCH
end
 
select @w_tasa_icte = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'ICTE' ---Concepto MORA
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 begin
   select @w_tasa_icte = 'ICTE'
end
 
select @w_codigo_tmmex = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'TMMEX' --TASA MAXIMA DE EXTRANJERA
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   goto ERROR_BATCH
end
 
select @w_codigo_tmm = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'TMM'
select @w_rowcount = @@rowcount 
 
if @w_rowcount = 0 begin
   goto ERROR_BATCH
end
 

select @w_parametro_int = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 begin
   select @w_error = 701059
   goto ERROR_BATCH
end
 
-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 begin
   select @w_error = 708174
   goto ERROR_BATCH
end

/* DECIMALES DE LA MONEDA NACIONAL */
exec @w_error   = sp_decimales
@i_moneda       = @w_moneda_nacional,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_aux1    out,
@o_dec_nacional = @w_decimales_nacional out
         
if @w_error <> 0 goto ERROR_BATCH

     
-- CODIGO DE LA MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 begin
   select @w_error = 710256
   goto ERROR_BATCH
end

-- CODIGO SUSPENSION CAUSACION
select @w_parametro_smc = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'SMC'

if @w_rowcount = 0  begin
   select @w_error = 710256
   goto ERROR_BATCH
end
 
-- FORMA DE PAGO AUTOMATICA PARA OBLIGACIONES PASIVAS
select @w_forma_pago_bsp = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'FPBSP'
select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 begin
   select @w_error = 710436
   goto ERROR_BATCH
end
 
-- CODIGO COMERCIO EXTERIOR
select @w_ofi_matriz = isnull(pa_smallint,900)
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CEX'
and    pa_nemonico = 'MATRIZ'
 
-- PARAMENTRO IBC MONEDA NACIONAL
select @w_param_ibc_mn = pa_char 
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'TLU' --TASA LIMITE USURA   ..antes..IBC INTERES BANCARIO CORRIENTE
and    pa_producto = 'CCA'
select  @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 710256
   goto ERROR_BATCH
end
 
-- PARAMENTRO IBC MONEDA EXTRANJERA
select @w_param_ibc_me = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'TLUEX'  --TASA LIMITE USURA M.E.   antes IBCEX' --INTERES BANCARIO CORRIENTE MONEDA EXT.
and    pa_producto = 'CCA'

---CODIGO DEL RUBRO COMISION FAG
select @w_parametro_fag = pa_char
from  cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'COMFAG'
select @w_rowcount = @@rowcount
 
if @w_rowcount = 0 begin
   select @w_error = 710256
   goto ERROR_BATCH
end

-- CODIGO MIPYMES
select @w_mipymes = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'MIPYME'

   
select @w_rowcount = @@rowcount
if @w_rowcount = 0 begin
   select @w_error = 710256
   goto ERROR_BATCH
end

-- ACTIVAR/DESACTIVAR PROCESO DE CAMBIO PERIODO CONTABLE
select @w_cambio_per_contable = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'HPCOAN'
and    pa_producto = 'CCA'

/* DIAS PARA PASAR A SUSPENSO PARA MICROCREDITO */
select @w_num_dias_sus4 = convert(int, valor)
from   cobis..cl_catalogo A with (nolock), cobis..cl_tabla B with (nolock)
where  A.tabla  = B.codigo
and    B.tabla  = 'ca_suspension_clase'
and    A.codigo = '4'

/* CALIFICACION PARA PASO A SUSPENSO DE MICROCREDITO */
select @w_calificacion_sus4 = ltrim(rtrim(valor))
from   cobis..cl_catalogo A with (nolock), cobis..cl_tabla B with (nolock)
where  A.tabla  = B.codigo
and    B.tabla  = 'ca_calificacion_causacion'
and    A.codigo = '4'

/* DETERMINAR LA TASA MAXIMA DE MORA PARA MICROCREDITO PARA LA MONEDA LOCAL*/
select @w_codigo_tmm_clase = rtrim(@w_codigo_tmm)   + '4'

select @w_fecha_ini_tmm = max(vr_fecha_vig)
from   ca_valor_referencial with (nolock)
where  vr_tipo   = @w_codigo_tmm_clase
and    vr_fecha_vig <= @s_date

select @w_max_sec = max(vr_secuencial)
from   ca_valor_referencial with (nolock)
where  vr_tipo      = @w_codigo_tmm_clase
and    vr_fecha_vig = @w_fecha_ini_tmm

select @w_tasa_maxima_mora4 = vr_valor
from   ca_valor_referencial with (nolock)
where  vr_tipo       = @w_codigo_tmm_clase
and    vr_fecha_vig  = @w_fecha_ini_tmm
and    vr_secuencial = @w_max_sec


/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_condonado  = @w_est_condonado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_credito    = @w_est_credito   out

if @w_error <> 0 goto ERROR_BATCH
 
select @w_mes_antes = datepart(mm, @i_siguiente_dia)
 
if @i_aplicar_fecha_valor = 'S' or @i_pry_pago = 'S'
   select @w_siguiente_dia = @i_siguiente_dia
else
   select @w_siguiente_dia = dateadd(dd,1,@i_siguiente_dia)
   
select @w_mes_despues = datepart(mm,@w_siguiente_dia)

-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select @w_error = 101024
   goto ERROR_BATCH
end
 
select @w_anio_mes_fp = substring(convert(varchar, @w_siguiente_dia, 111), 1, 7)

if @w_anio_mes_fp > @w_anio_mes_fc and @i_control_fecha = 'S' begin
   select @w_siguiente_dia = dateadd(dd, -datepart(dd, @w_siguiente_dia)+1, @w_siguiente_dia)
   PRINT 'No se puede procesar mas alla del mes actual: ' + cast(@w_anio_mes_fc as varchar)
end

--Fecha valor envia @i_en_linea = 'N' cuando es 7x24, debe ejecutar como cierre normal
if @i_en_linea = 'N'
begin
   exec @w_error = sp_dia_habil 
   @i_fecha  = @w_siguiente_dia,
   @i_ciudad = @w_ciudad_nacional,
   @o_fecha  = @w_siguiente_dia out

   if @w_error <> 0 goto ERROR_BATCH

   --Siguiente fecha contable para provisiones inicio de dia o doble cierre automatico de fin de mes
   select @s_date_sigdiahabil = dateadd(dd,1, @s_date)

   exec @w_error = sp_dia_habil 
   @i_fecha  = @s_date_sigdiahabil,
   @i_ciudad = @w_ciudad_nacional,
   @o_fecha  = @s_date_sigdiahabil out

   if @w_error <> 0 goto ERROR_BATCH

   select @s_date_sigdiahabil_aux = @s_date_sigdiahabil

end

if @i_pry_pago = 'N' and @i_control_fecha = 'S' begin
   if  @w_siguiente_dia >= @s_date -- NO SE PUEDE PASAR DE LA FECHA DE CIERRE
   and datepart(mm, @w_siguiente_dia) <> @w_mes_actual -- SI LE ESTA CAMBIANDO DEL MES DE CIERRE
   begin
      select @w_siguiente_dia = dateadd(dd, -datepart(dd, @w_siguiente_dia)+1, @w_siguiente_dia)
   end
end

while @w_detener_proceso = 'N' 
begin
   --Por doble cierre automatico se reinicia el @s_date por cada operacion ya que este se modificó antes de las provisiones
   select @s_date = @s_date_aux


   if @i_banco is null 
   begin
      set rowcount 1

      select @w_operacionca = operacion
      from ca_universo with (nolock)
      where  hilo     = @i_hilo --LPO Nuevo Esquema de Paralelismo  --ub_estado = @i_hijo
      and   intentos < 2
      order by id 
      
      if @@rowcount = 0 
      begin
         set rowcount 0
         select @w_detener_proceso = 'S'--LPO Nuevo Esquema de Paralelismo
         break
      end
      
      set rowcount 0
      
      --LPO Nuevo Esquema de Paralelismo INICIO      
      update ca_universo set 
      intentos = intentos + 1, 
      hilo     = 100 -- significa Procesado o procesando 
      where operacion = @w_operacionca 
      and   hilo      = @i_hilo 
      --LPO Nuevo Esquema de Paralelismo FIN
   end
   else
   begin      
      select @w_operacionca = op_operacion
      from ca_operacion, ca_estado with (nolock)
      where op_estado  = es_codigo
      and   es_procesa = 'S' 
      and   op_banco   = @i_banco

      if @@rowcount = 0 break
      
      select @w_detener_proceso = 'S'      
   end

   select @w_contador = @w_contador + 1

   select  
   @w_fecha_ult_proceso = op_fecha_ult_proceso,
   @w_banco             = op_banco        
   from ca_operacion
   where op_operacion = @w_operacionca

   /* Detectar si la Operaciones tiene Pagos de recaudo pendientes con fecha valor */
   
   select @w_fecha_pag = isnull(min(ab_fecha_pag), '12/31/2100')
   from   ca_abono with (nolock)
   where  ab_operacion  = @w_operacionca
   and    ab_estado   in ('ING', 'NA') 
   
   if @w_fecha_pag < @w_fecha_ult_proceso begin 
    
      select @w_sp_name = 'sp_fecha_valor'

      if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '10.sp_fecha_valor' 
      if @i_debug = 'S' print '10.sp_fecha_valor ' + @w_banco
     
      exec @s_ssn = ADMIN...rp_ssn   --LPO TEC sp_fecha_valor necesita el @s_ssn
      
      exec @w_error = sp_fecha_valor  
      @s_ssn               = @s_ssn, --LPO TEC sp_fecha_valor necesita el @s_ssn
      @s_date              = @s_date,
      @s_user              = @s_user,
      @s_term              = @s_term,
      @i_fecha_valor       = @w_fecha_pag,
      @i_banco             = @w_banco,
      @i_operacion         = 'F',
      @i_observacion       = 'Recaudo',
      @i_observacion_corto = 'Recaudo',
      @i_en_linea          = 'N'
      
      if @w_error <> 0 begin
         if @i_en_linea = 'S' goto ERROR 
         exec sp_errorlog 
         @i_fecha     = @s_date,
         @i_error     = @w_error,
         @i_usuario   = @s_user,
         @i_tran      = 7999,
         @i_tran_name = @w_sp_name,
         @i_cuenta    = @w_banco,
         @i_rollback  = 'N'
         select @w_error = 0
      end   
      
   end         


   select             
   @w_op_moneda            = op_moneda,                  
   @w_fecha_ult_proceso    = op_fecha_ult_proceso,
   @w_sector               = op_sector,                     
   @w_fecha_ini            = op_fecha_ini,               
   --@w_op_clase             = op_clase,                    
   @w_op_clase             = op_sector,                    
   @w_tdividendo           = op_tdividendo,             
   @w_monto                = op_monto,                       
   @w_num_renovacion       = isnull(op_num_renovacion,0),     
   @w_renovacion           = op_renovacion,             
   @w_edad                 = isnull(op_edad,0),                         
   @w_tplazo               = op_tplazo,                     
   @w_reestructuracion     = op_reestructuracion, 
   @w_op_fecha_prox_segven = op_fecha_prox_segven,
   @w_banco                = op_banco,                       
   @w_op_oficina           = op_oficina,                
   @w_dias_anio            = op_dias_anio,               
   @w_op_cliente           = op_cliente,                
   @w_dias_clausula        = op_dias_clausula,       
   @w_base_calculo         = op_base_calculo,         
   @w_causacion            = op_causacion,               
   @w_fecha_fin            = op_fecha_fin,               
   @w_destino              = op_destino,                   
   @w_gar_admisible        = isnull(op_gar_admisible,'N'),       
   @w_periodo_cap          = op_periodo_cap,           
   @w_tipo_amortizacion    = op_tipo_amortizacion,
   @w_clausula_aplicada    = op_clausula_aplicada,
   @w_op_suspendio         = op_suspendio,            
   @w_toperacion           = op_toperacion,             
   @w_oficial              = op_oficial,                   
   @w_estado               = op_estado,                     
   @w_fecha_liq            = op_fecha_liq,               
   @w_calificacion         = isnull(op_calificacion,'A'),         
   @w_periodo_int          = op_periodo_int,           
   @w_estado_cobranza      = op_estado_cobranza,      
   @w_numero_reest         = op_numero_reest,         
   @w_tramite              = isnull(op_tramite,0),                   
   @w_op_tipo              = op_tipo,                      
   @w_plazo                = op_plazo,                       
   @w_opcion_cap           = op_opcion_cap,             
   @w_op_naturaleza        = op_naturaleza, 
   @w_op_forma_pago        = op_forma_pago,             -- FCP Interfaz Ahorros
   @w_op_cuenta            = op_cuenta,                 -- FCP Interfaz Ahorros               
   @w_op_fecha_suspenso    = op_fecha_suspenso
   from ca_operacion with (nolock)
   where op_operacion = @w_operacionca
   
   /* EN BATCH LA OFICINA ORIGEN SERA LA DE LA OPERACION */
   if @i_en_linea = 'N' or @s_ofi is null select @s_ofi = @w_op_oficina
   

   /* DETERMINAR EL NUMERO DE DECIMALES CON QUE TRABAJAR */
   if @w_op_moneda = @w_moneda_nacional begin
   
      select @w_num_dec = @w_decimales_nacional
      
   end else begin
   
      -- CONTROL DEL NUMERO DE DECIMALES
      exec @w_error   = sp_decimales
      @i_moneda       = @w_op_moneda,
      @o_decimales    = @w_num_dec out,
      @o_mon_nacional = @w_aux1    out,
      @o_dec_nacional = @w_decimales_nacional out
         
      if @w_error <> 0 goto ERROR
      
   end

   /* DETERMINAR DIAS Y CALIFICACION PARA PASAR A SUSPENSO DE ACUERDO A LA CLASE DE CARTERA */
   if @w_op_clase = '4' begin
   
      select 
      @w_num_dias_sus     = @w_num_dias_sus4,
      @w_calificacion_sus = @w_calificacion_sus4
      
   end else begin

      select @w_num_dias_sus = convert(int, valor)
      from   cobis..cl_catalogo A with (nolock), cobis..cl_tabla B with (nolock)
      where  A.tabla  = B.codigo
      and    B.tabla  = 'ca_suspension_clase'
      and    A.codigo = ltrim(rtrim(@w_op_clase))
      
      --SUSPENSION POR CALIFICAICON
      select @w_calificacion_sus = ltrim(rtrim(valor))
      from   cobis..cl_catalogo A with (nolock), cobis..cl_tabla B with (nolock)
      where  A.tabla  = B.codigo
      and    B.tabla  = 'ca_calificacion_causacion'
      and    A.codigo = ltrim(rtrim(@w_op_clase))
         
   end
   
  
   select @w_nuevo_interes = 'S' -- SE ASUME NUEVA TASA DE INTERES PARA LA OBLIGACION ()
   
   if @w_op_oficina <> @w_ult_oficina begin
      select @w_ciudad_op = of_ciudad
      from   cobis..cl_oficina with (nolock)
      where  of_oficina = @w_op_oficina
      
      select @w_ult_oficina = @w_op_oficina
   end

   -- INICIALIZACION DE VARIABLES
   select 
   @w_fecha_prox_pago = null,
   @w_fecha_tmp       = null,
   @w_dividendo       = null
   
   -- FECHA DE INICIO DE BATCH
   select @w_fecha_proceso = @w_fecha_ult_proceso
   
   -- OBTENER EL CONCEPTO DE CAPITAL
   select @w_concepto_cap = ro_concepto
   from   ca_rubro_op with (nolock)
   where  ro_operacion  = @w_operacionca
   and    ro_tipo_rubro = 'C'
   
   select @w_dias_interes = td_factor * @w_periodo_int
   from   ca_tdividendo with (nolock)
   where  td_tdividendo    = @w_tdividendo
   
   select 
   @w_modalidad    = ro_fpago,
   @w_concepto_int = ro_concepto
   from   ca_rubro_op with (nolock)
   where  ro_operacion  = @w_operacionca
   and    ro_tipo_rubro   = 'I'
   and    ro_provisiona   = 'S'

   if @i_debug = 'S' print 'PROCESANDO OPERACION: ' + @w_banco + ' DESDE ' + convert(varchar,@w_fecha_proceso, 103) + ' AL ' + convert(varchar,@w_siguiente_dia, 103)
   if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '20.Inicio' 
   
   /* PROCESANDO CADA PRESTAMO DESDE LA FECHA DE ULTIMO PROCESO HASTA EL SIGUIENTE D-A HABIL */   
   while @w_fecha_proceso < @w_siguiente_dia begin

      /*Doble cierre automatico en fin de mes: si la operacion esta antes del fin de mes, la fecha contable es el utlimo dia
        habil del mes que cierra, caso contrario el primer dia habil del siguiente mes*/
      if @i_en_linea = 'N' and @i_control_fecha = 'N' and @i_pry_pago = 'N'
      begin
         if datepart(mm, @s_date) <> datepart(mm, @s_date_sigdiahabil_aux)  --Cambio de mes
         begin
            select @w_fin_mes_contable = dateadd(dd,-datepart(dd,@s_date_sigdiahabil_aux),@s_date_sigdiahabil_aux)

            if @w_fecha_proceso < @w_fin_mes_contable   --op. antes del fin de mes
               select @s_date_sigdiahabil    = @s_date 
            else
               select @s_date_sigdiahabil = @s_date_sigdiahabil_aux  --op. despues del fin de mes
         end
		 else 
		 select @s_date_sigdiahabil    = @s_date -- GFP 19/10/2021 se mantiene dia habil del mes
		 
      end
      else  --if @i_en_linea = 'S' or @i_control_fecha = 'S' or @i_pry_pago = 'S'
         select @s_date_sigdiahabil    = @s_date 


      --LPO TEC PAGOS GRUPALES E INTERCICLOS
      /* DETERMINAR SI LA OPERACION CORRESPONDE A INTERCICLO - GRUPAL - INDIVIDUAL */
      if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '30.sp_tipo_operacion' 
      if @i_debug = 'S' print '30.sp_tipo_operacion ' + @w_banco

      exec @w_error = sp_tipo_operacion
      @i_banco      = @w_banco,
      @o_tipo       = @w_tipo_grupal out

      if @w_error <> 0 goto ERROR

      /* PROCESAR LAS OPERACIONES INTERCICLOS DE LA OPERACION GRUPAL QUE ESTEN ATRASADOS */
      if @w_tipo_grupal = 'G'
      begin
         /* SELECCIONAR LAS OPERACIONES INTERCICLOS DE LA OPERACION GRUPAL */
         declare cursor_interciclos cursor for
         select op_banco
         from   ca_operacion, ca_estado                                                                                                                                                                                                                                    
         where  op_operacion         in (select dc_operacion from ca_det_ciclo where dc_referencia_grupal = @w_banco and dc_tciclo = 'I')   
         and    op_estado             = es_codigo
         and    es_procesa            = 'S'
         and    op_fecha_ult_proceso  < @w_fecha_proceso
         order by op_operacion
         for read only
   
         open    cursor_interciclos
         fetch   cursor_interciclos
         into    @w_banco_interciclo

         /* WHILE cursor_interciclos */
         while @@fetch_status = 0 
         begin 
            if (@@fetch_status = -1) 
            begin
               select @w_error = 71003
               goto ERROR
            end

            /* EJECUTAR EL PROCESO BATCH PARA LA OPERACION INTERCICLO */
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '40.sp_batch1' 
            if @i_debug = 'S' print '40.sp_batch1 ' + @w_banco_interciclo

            exec @w_error          = sp_batch1
            @s_user                = @s_user,
            @s_term                = @s_term,
            @s_date                = @s_date,
            @s_ofi                 = @s_ofi,
            @i_en_linea            = @i_en_linea,
            @i_banco               = @w_banco_interciclo,
            @i_siguiente_dia       = @w_fecha_proceso,
            @i_aplicar_fecha_valor = 'N'

            if @w_error <> 0 
            begin
               close cursor_interciclos
               deallocate cursor_interciclos

               goto ERROR
            end

            fetch   cursor_interciclos
            into    @w_banco_interciclo
         end

         close cursor_interciclos
         deallocate cursor_interciclos

      end /* if @w_tipo_grupal = 'G' */
      --LPO TEC FIN PAGOS GRUPALES E INTERCICLOS

	  if (@w_tipo_amortizacion = 'ROTATIVA') begin 

        if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '50.sp_lcr_crear_cuota'
        if @i_debug = 'S' print '50.sp_lcr_crear_cuota ' + @w_banco

	     exec @w_error = sp_lcr_crear_cuota 
        @i_operacionca   = @w_operacionca,
        @i_fecha_proceso =	@w_fecha_proceso	 
         
        if @w_error <> 0 goto ERROR		 
	  end 
	  
   
     select
     @w_oficina_destino = trc_oficina_destino,
     @w_oficial_destino = trc_oficial_destino
     from ca_traslados_cartera 
     where trc_operacion = @w_operacionca 
     and trc_estado = 'I' 
     and trc_fecha_proceso = @w_fecha_proceso
      
      if @@ROWCOUNT <> 0
      begin

       if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '60.sp_traslada_cartera'
       if @i_debug = 'S' print '60.sp_traslada_cartera ' + @w_banco

       exec @w_error = sp_traslada_cartera
		 @s_user              = @s_user,
		 @s_term              = @s_term,
		 @s_date              = @s_date,   
		 @s_ofi               = @s_ofi,
		 @i_operacion         = 'I',    
		 @i_cliente           = @w_op_cliente,   
		 @i_banco             = @w_banco,   
		 @i_oficina_destino   = @w_oficina_destino,
		 @i_oficial_destino   = @w_oficial_destino,
		 @i_en_linea          = @i_en_linea,
		 @i_desde_batch       = 'S'
		 
		 if @w_error <> 0 goto ERROR
		 
	  end
	  
      -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      if @w_op_moneda = @w_moneda_nacional begin
         select @w_cotizacion_hoy = 1.0
      end else begin

         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '70.sp_buscar_cotizacion'
         if @i_debug = 'S' print '70.sp_buscar_cotizacion ' + @w_banco

         exec sp_buscar_cotizacion
         @i_moneda     = @w_op_moneda,
         @i_fecha      = @w_fecha_proceso,
         @o_cotizacion = @w_cotizacion_hoy output
      end
      
      /*APLICACION DE PAGOS POR GARANTIA */
      /* -- KDR 20/10/2021 Se comenta pagos de garantía por uso de rp_ssn 
      if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '80.sp_abono_garantia'
      if @i_debug = 'S' print '80.sp_abono_garantia ' + @w_banco

      exec @w_error = sp_abono_garantia
      @i_operacionca = @w_operacionca,
      @i_en_linea   = @i_en_linea
	  
      if @w_error <> 0 begin
         if @i_en_linea = 'S' goto ERROR 
         exec sp_errorlog 
         @i_fecha     = @s_date,
         @i_error     = @w_error,
         @i_usuario   = @s_user,
         @i_tran      = 7999,
         @i_tran_name = @w_sp_name,
         @i_cuenta    = @w_banco,
         @i_rollback  = 'N'
         select @w_error = 0
      end */ -- Fin KDR Se comenta pagos de garantía por uso de rp_ssn 
      
      --LPO CDIG comentar sp_abono_garantia por usar rp_ssn que no existe la nube (FIN)   	  
      
      if @i_debug = 'S' print 'PROCESANDO OPERACION: ' + @w_banco + ' AL ' + convert(varchar,@w_fecha_proceso, 103)
      
      -- EL SIGUIENTE PROCEDIMIENTO SOLO APLICA A LAS OBLIGACIONES ACTIVAS
      -- BAJO LA SUPOSICION DE QUE LAS PASIVAS NO SE LES PARAMETRIZA MORA
      -- EN CASO CONTRARIO SE DEBE QUITAR LA CONDICION DE LA NATURALEZA.
      if @w_op_naturaleza = 'A' begin
      
         /* CONDICION PARA EVITAR LA CONSULTA DE LA TASA MAXIMA DE MORA DE MICROCREDITO */
         if  @w_op_moneda in (@w_moneda_nacional, @w_moneda_uvr) 
         and @w_fecha_proceso >= @w_fecha_ini_tmm
         and @w_op_clase       = '4'
         begin
         
            select @w_tasa_maxima_mora = @w_tasa_maxima_mora4
         
         end else begin
      
            if @w_op_moneda in (@w_moneda_nacional, @w_moneda_uvr) begin
               select @w_codigo_tmm_clase = rtrim(@w_codigo_tmm)   + @w_op_clase
            end else begin
               select @w_codigo_tmm_clase = rtrim(@w_codigo_tmmex) + @w_op_clase
            end   
   
            select @w_max_fecha = max(vr_fecha_vig)
            from   ca_valor_referencial with (nolock)
            where  vr_tipo   = @w_codigo_tmm_clase
            and    vr_fecha_vig <= @w_fecha_proceso
            
            select @w_max_sec = max(vr_secuencial)
            from   ca_valor_referencial with (nolock)
            where  vr_tipo      = @w_codigo_tmm_clase
            and    vr_fecha_vig = @w_max_fecha
            
            select @w_tasa_maxima_mora = vr_valor
            from   ca_valor_referencial with (nolock)
            where  vr_tipo       = @w_codigo_tmm_clase
            and    vr_fecha_vig  = @w_max_fecha
            and    vr_secuencial = @w_max_sec
            
         end
                  
         select @w_codigo_tmm_clase   = rtrim(@w_codigo_tmm)   + @w_op_clase
         select @w_codigo_tmmex_clase = rtrim(@w_codigo_tmmex) + @w_op_clase
               
      end
      
      -- INICIO - REQ 089: ACUERDOS DE PAGO --
      
      -- BUSQUEDA DE ACUERDO VIGENTE EN LA FECHA VALOR
      select @w_tacuerdo = ac_tacuerdo
      from  cob_credito..cr_acuerdo
      where ac_banco               = @w_banco
      and   ac_estado              = 'V'
      and   @w_fecha_proceso between ac_fecha_ingreso and ac_fecha_proy
      
      if @@rowcount = 0 select @w_tacuerdo = 'X'
      
      -- CUANDO ES ACUERDO DE PRECANCELACION SE CAMBIA 
      -- LA MODALIDAD DE APLICACION DE PAGOS A ACUMULADO
      if @w_tacuerdo = 'P'
      begin
         update ca_operacion with (rowlock)
         set op_tipo_cobro = 'A'
         where op_banco       = @i_banco
         and   op_tipo_cobro <> 'A'
         
         if @@error <> 0
         begin
            print 'ERROR AL MODIFICAR TIPO DE COBRO'
            select @w_error = 705007
            goto ERROR
         end
      end
      -- FIN - REQ 089: ACUERDOS DE PAGO --
 
      if exists (select 1 from ca_otro_cargo with (nolock)
      where  oc_operacion = @w_operacionca
      and    oc_fecha = @w_fecha_proceso
      and    oc_estado = 'NA')
      begin

         select @w_sp_name = 'sp_aplicacion_ioc_batch'
      
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '90.sp_aplicacion_ioc_batch'
         if @i_debug = 'S' print '90.sp_aplicacion_ioc_batch ' + @w_banco
         
         exec @w_error = sp_aplicacion_ioc_batch
         @s_date                     = @s_date,
         @s_user                     = @s_user,
         @s_term                     = @s_term,
         @s_ofi                      = @s_ofi,
         @i_banco                    = @w_banco,
         @i_operacionca              = @w_operacionca,
         @i_toperacion               = @w_toperacion,
         @i_fecha_ult_proceso        = @w_fecha_proceso,
         @i_reestructuracion         = @w_reestructuracion,
         @i_calificacion             = @w_calificacion,
         @i_oficina                  = @w_op_oficina,
         @i_gar_admisible            = @w_gar_admisible,
         @i_moneda                   = @w_op_moneda,
         @i_moneda_nacional          = @w_moneda_nacional,
         @i_sector                   = @w_sector,
         @i_num_dec                  = @w_num_dec,
         @i_gerente                  = @w_oficial,
         @i_en_linea                 = @i_en_linea,
         @i_desde_batch              = 'S'
         
         if @w_error <> 0 begin
            if @i_en_linea = 'S' goto ERROR 
            exec sp_errorlog 
            @i_fecha     = @s_date,
            @i_error     = @w_error,
            @i_usuario   = @s_user,
            @i_tran      = 7999,
            @i_tran_name = @w_sp_name,
            @i_cuenta    = @w_banco,
            @i_rollback  = 'N'
            select @w_error = 0
         end
      end  --iocbatch     

      ---NR 500 
      ---AGO.19.2015
      
	  /* -- KDR Se comenta sección que no aplica a versión De Finca 
      if exists (select 1 from ca_oper_cambio_linea_x_mora 
                 where cl_banco = @w_banco
                 and   cl_estado = 'NA')
      begin

         select @w_sp_name = 'sp_cam_lfinagro_xmora_batch'
      
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '100.sp_cam_lfinagro_xmora_batch'
         if @i_debug = 'S' print '100.sp_cam_lfinagro_xmora_batch ' + @w_banco
         
         exec @w_error = sp_cam_lfinagro_xmora_batch
         @s_user                     = @s_user,
         @i_banco                    = @w_banco,
         @i_operacion                = @w_operacionca
        
         if @w_error <> 0 begin
            if @i_en_linea = 'S' goto ERROR 
            exec sp_errorlog 
            @i_fecha     = @s_date,
            @i_error     = @w_error,
            @i_usuario   = @s_user,
            @i_tran      = 7999,
            @i_tran_name = @w_sp_name,
            @i_cuenta    = @w_banco,
            @i_rollback  = 'N'
            select @w_error = 0
         end
      end  --iocbatch     
      ---NR 500  FIN
	  */ -- Fin KDR Se comenta sección que no aplica a versión De Finca 
  
      if @w_op_naturaleza = 'A' begin
         update ca_abono with (rowlock) set
         ab_dias_retencion = ab_dias_retencion - 1 
         where ab_estado in ('NA','ING')
         and   ab_operacion = @w_operacionca
         and   ab_dias_retencion > 0                    
      end

      /* Eliminar pagos cargados en caja por Reestructuraciones */
      /* Manejo solo para la linea, en batch se separa el proceso por optimizacion */
      if @i_en_linea = 'S' begin 
         select @w_tramite_reest = 0
         select @w_tramite_reest = tc_tramite 
         from cob_credito..cr_tramite (nolock),  cob_credito..cr_tramite_cajas (nolock)
         where tc_tramite = tr_tramite
         and tr_numero_op = @w_operacionca
         and tr_tipo = 'E'
         and tr_estado = 'A'
         and tc_estado = 'I'
         and tc_pago_cobro = 'C'
   
         if @w_tramite_reest > 0 begin
            select @w_sp_name = 'cob_credito..sp_trn_cj_reest'
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '110.sp_trn_cj_reest'
            if @i_debug = 'S' print '110.sp_trn_cj_reest ' + @w_banco
   
            exec @w_error = cob_credito..sp_trn_cj_reest
            @s_date         = @s_date,
            @s_user         = @s_user,
            @i_operacion    = 'R',
            @i_tramite      = @w_tramite_reest 
         end
      END

      if  @w_op_forma_pago is not null
      and exists (select 1 from ca_dividendo with (nolock) 
                 where di_operacion = @w_operacionca
                 and   di_fecha_ven <= @w_fecha_proceso 
                 and   di_estado in (@w_est_vigente,@w_est_vencido))
      and (@w_fecha_proceso > @s_date)      -- SVA Debitos Paralelo (@w_fecha_proceso >= @s_date)
      and (@i_pry_pago = 'N' )           
      and (@i_en_linea = 'N' )
      and not exists(select 1 from cobis..cl_dias_feriados  ---NO INTENTA DE DEBITO CUANDO ES FESTIVO                                                                                                                                                                                                        
                     where df_ciudad = @w_ciudad_nacional
                     and   df_fecha  = @w_fecha_proceso)
      begin
         select @w_sp_name = 'sp_genera_afect_productos'            

         IF @w_tipo_grupal <> 'I' ----LPO TEC PAGOS GRUPALES E INTERCICLOS. Si es Interciclo no debe generar abono
         BEGIN
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '120.sp_genera_afect_productos'
            if @i_debug = 'S' print '120.sp_genera_afect_productos ' + @w_banco

            exec @w_error = sp_genera_afect_productos
            @s_user               = @s_user,
            @s_term               = @s_term,
            @s_ofi                = @w_op_oficina,
            @s_sesn               = @s_sesn,
            @s_date               = @s_date,
            @i_debug              = @i_debug,
            @i_num_dec            = @w_num_dec,
            @i_cotizacion         = @w_cotizacion_hoy,
            @i_operacionca        = @w_operacionca,  
            @i_en_linea           = @i_en_linea,
            @i_forma_pago         = @w_op_forma_pago,
            @i_cuenta             = @w_op_cuenta,
            @i_tipo_grupal        = @w_tipo_grupal --LPO TEC Se envía el tipo porque cuando sea G solo debe crear el abono pero no realizar el pago.
            
            if @w_error <> 0 BEGIN
               if @i_en_linea = 'S' goto ERROR --LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS
               
               --LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS (INICIO)
               IF @i_en_linea = 'N'
               BEGIN
                  select @w_error = 0
               END
               --LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS (FIN)
               
               --LPO Se comenta porque el sp_genera_afect_productos ya registró el error (INICIO), LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS
               /*
               exec sp_errorlog 
               @i_fecha     = @s_date,
               @i_error     = @w_error,
               @i_usuario   = @s_user,
               @i_tran      = 7999,
               @i_tran_name = @w_sp_name,
               @i_cuenta    = @w_banco,
               @i_rollback  = 'N'
               select @w_error = 0
               */
               --LPO Se comenta porque el sp_genera_afect_productos ya registró el error (FIN), LPO CDIG AJUSTE EN BATCH POR CONTROL DE COMMIT EN SPS'S DE AHORROS
            end
         END

         --- LOS ABONOS PODRIAN CANCELAR LA OPERACION
         select @w_estado = op_estado
         from   ca_operacion  with (nolock)
         where  op_operacion =  @w_operacionca
         
         if @w_estado = @w_est_cancelado goto SALIR

      end
      
     
      if @w_tipo_grupal <> 'I' ----LPO TEC PAGOS GRUPALES E INTERCICLOS
      begin

         select @w_sp_name = 'sp_abonos_batch'
         
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion  = '130.sp_abonos_batch'
         if @i_debug = 'S' print '130.sp_abonos_batch ' + @w_banco
        
         exec @w_error = sp_abonos_batch
         @s_user          = @s_user,
         @s_term          = @s_term,
         @s_date          = @s_date,
         @s_ofi           = @s_ofi,
         @i_en_linea      = @i_en_linea,
         @i_fecha_proceso = @w_fecha_proceso,
         @i_operacionca   = @w_operacionca,
         @i_banco         = @w_banco,
         @i_pry_pago      = @i_pry_pago,
         @i_cotizacion    = @w_cotizacion_hoy
         
         if @w_error <> 0 begin
            if @i_en_linea = 'S' goto ERROR 
            exec sp_errorlog 
            @i_fecha     = @s_date,
            @i_error     = @w_error,
            @i_usuario   = @s_user,
            @i_tran      = 7999,
            @i_tran_name = @w_sp_name,
            @i_cuenta    = @w_banco,
            @i_rollback  = 'N'
            select @w_error = 0
         end
         
         --- LOS ABONOS PODRIAN CANCELAR LA OPERACION
         select @w_estado = op_estado
         from   ca_operacion  with (nolock)
         where  op_operacion =  @w_operacionca
         
         if @w_estado = @w_est_cancelado goto SALIR
         
      end

      --LPO TEC PAGOS GRUPALES E INTERCICLOS
      /* PROCESAR LAS OPERACIONES INTERCICLOS DE LA OPERACION GRUPAL - DEL DIA */
      if @w_tipo_grupal = 'G'
      begin
         /* SELECCIONAR LAS OPERACIONES INTERCICLOS DE LA OPERACION GRUPAL */
         declare cursor_interciclos cursor for
         select op_banco
         from   ca_operacion, ca_estado                                                                                                                                                                                                                                    
         where  op_operacion         in (select dc_operacion from ca_det_ciclo where dc_referencia_grupal = @w_banco and dc_tciclo = 'I')   
         and    op_estado             = es_codigo
         and    es_procesa            = 'S'
         and    op_fecha_ult_proceso <= @w_fecha_proceso
         order by op_operacion
         for read only
   
         open    cursor_interciclos
         fetch   cursor_interciclos
         into    @w_banco_interciclo

         /* WHILE cursor_interciclos */
         while @@fetch_status = 0 
         begin 
            if (@@fetch_status = -1) 
            begin
               select @w_error = 71003
               goto ERROR
            end

            /* EJECUTAR EL PROCESO BATCH PARA LA OPERACION INTERCICLO */
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco_interciclo, @i_posicion = '140.sp_batch1'
            if @i_debug = 'S' print '140.sp_batch1 ' + @w_banco_interciclo

            exec @w_error          = sp_batch1
            @s_user                = @s_user,
            @s_term                = @s_term,
            @s_date                = @s_date,
            @s_ofi                 = @s_ofi,
            @i_en_linea            = @i_en_linea,
            @i_banco               = @w_banco_interciclo,
            @i_siguiente_dia       = @w_fecha_proceso,
            @i_aplicar_fecha_valor = 'N'

            if @w_error <> 0 
            begin
               close cursor_interciclos
               deallocate cursor_interciclos

               goto ERROR
            end

            fetch   cursor_interciclos
            into    @w_banco_interciclo
         end

         close cursor_interciclos
         deallocate cursor_interciclos

      end /* if @w_tipo_grupal = 'G' */
      --LPO TEC FIN PAGOS GRUPALES E INTERCICLOS

      /**********************************************************/
      /****        INICIA: ACUERDOS DE PAGOS              *******/
      /**** Invocacion del sp de verificacion de acuerdos *******/

      if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '150.sp_verifica_acuerdo'
      if @i_debug = 'S' print '150.sp_verifica_acuerdo ' + @w_banco

      exec @w_error = sp_verifica_acuerdo 
      @s_user      = @s_user,
      @s_term      = @s_term, 
      @s_date      = @s_date,
      @s_ofi       = @s_ofi,
      @i_debug     = @i_debug,
      @i_banco     = @w_banco,
      @i_fecha     = @w_fecha_proceso
      
      if @w_error <> 0 goto ERROR
      
      /****       FINALIZA: ACUERDOS DE PAGOS             *******/
      /**********************************************************/

      --EXTRACCION DE DATOS -- SOLO EN BATCH 

      
      --/* SVA - Datos Consolidador, se obtiene al inicio del cierre del día o al inicio del el ultimo día
      --   calendario del mes, se cuadra con la contabilidad */
      /* AMO 2022-05-12 SUPRIMIR EJECUCION DE SP_CONSOLIDADOR_CCA
      
      if @i_en_linea = 'N' and @i_pry_pago = 'N' and 
        (@w_fecha_proceso = @s_date_aux or  --@w_fecha_ult_proceso or 
        (datepart(mm, (dateadd(dd, 1, @w_fecha_proceso))) <> datepart(mm, @w_fecha_proceso))) 
      begin
         if exists (select 1 
                    from   ca_estado
                    where  es_codigo = @w_estado
                    and    es_procesa = 'S')
         begin
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '160.sp_consolidador_cca'
            if @i_debug = 'S' print '160.sp_consolidador_cca ' + @w_banco

            exec @w_error = cob_externos..sp_consolidador_cca
            @i_param1          = @w_banco,
            @i_param4          = @i_simular_cierre,
            @i_param3          = @i_debug

            if @w_error <> 0
            begin
               exec sp_errorlog 
               @i_fecha     = @s_date,
               @i_error     = @w_error,
               @i_usuario   = @s_user,
               @i_tran      = 7999,
               @i_tran_name = @w_sp_name,
               @i_cuenta    = @w_banco,
               @i_rollback  = 'N'
            
               select @w_error = 0
            end
         end
      END
      */
      
      -- BUSCAR LA TASA DE MORA QUE LE CORRESPONDE PARA HOY
      -- VENCIMIENTOS DE DIVIDENDOS
      select @w_dividendo2 = di_dividendo
      from   ca_dividendo  with (nolock)
      where  di_operacion = @w_operacionca
      and    di_estado    = @w_est_vigente
      
      select 
      @w_fecha_prox_pago = di_fecha_ven,
      @w_dividendo       = di_dividendo,
      @w_di_fecha_ini    = di_fecha_ini,
      @w_di_prorroga     = di_prorroga 
      from   ca_dividendo  with (nolock)
      where  di_operacion = @w_operacionca
      and    di_dividendo = @w_dividendo2
      
      /* ATOMICIDAD POR FECHA */
      if @i_pry_pago = 'N' begin
         BEGIN TRAN   
         select @w_commit = 'S'
      end
      
      -- INI - REQ 175: PEQUEÑA EMPRESA
      if @w_fecha_prox_pago = @w_fecha_proceso and (@w_op_tipo <> 'D' and @w_opcion_cap = 'S') begin          -- REQ 175: PEQUEÑA EMPRESA
         -- EJECUTAR ACCIONES
         if exists(select 1 from ca_acciones with (nolock)
         where  ac_operacion = @w_operacionca
         and    ac_div_ini  <= @w_dividendo2
         and    ac_div_fin  >= @w_dividendo2)
         and not exists(select 1 from ca_transaccion with (nolock)
         where tr_operacion = @w_operacionca
         and   tr_tran      = 'CRC'
         and   tr_fecha_ref = @w_fecha_proceso
         and   tr_estado   <> 'RV')
         begin
            select @w_sp_name = 'sp_ejecutar_acciones'

            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '170.sp_ejecutar_acciones'
            if @i_debug = 'S' print '170.sp_ejecutar_acciones ' + @w_banco
            
            exec @w_error = sp_ejecutar_acciones  
            @s_user              = @s_user,
            @s_term              = @s_term,
            @s_date              = @s_date,
            -- @s_sesn              = @s_sesn,                        REQ 175: PEQUEÑA EMPRESA
            @s_ofi               = @s_ofi,
            @i_operacionca       = @w_operacionca,
            @i_toperacion        = @w_toperacion,
            @i_moneda            = @w_op_moneda,
            @i_en_linea          = @i_en_linea,
            @i_banco             = @w_banco,
            @i_oficina           = @w_op_oficina,
            @i_fecha_proceso     = @w_fecha_proceso,
            @i_tipo_amortizacion = @w_tipo_amortizacion,
            @i_cotizacion        = @w_cotizacion_hoy --- NR 433
            
            if @w_error <> 0 goto ERROR
            
         end
      end 
      -- FIN - REQ 175: PEQUEÑA EMPRESA      
       
      -- CIRCULAR 11 SUSPENSION DE CAUSACION DE ACUERDO A DIAS DE MORA 
      -- ****************************************************************
      select @w_min_di_fecha_ven = min(di_fecha_ven)
      from   ca_dividendo  with (nolock)
      where  di_operacion =  @w_operacionca
      and    di_estado = @w_est_vencido
      
      -- EPB_09NOV2004 SALIR DE SUSPENSO POR QUE TIENE YA UNA CALIFICACION MENOR Y 0 DIAS DE MORA
      select @w_dias_salir_sus = 0
      
      if @w_min_di_fecha_ven is not null 
          select @w_dias_salir_sus = datediff(dd, @w_min_di_fecha_ven, @w_fecha_proceso)
      
      if   @w_estado in (@w_est_vigente, @w_est_vencido)
      and  @w_op_naturaleza <> 'P' 
      and (@w_min_di_fecha_ven is not null  or @w_calificacion >= @w_calificacion_sus) 
      begin
      
         select 
         @w_estado        = op_estado,
         @w_dias_ven_cart = isnull(op_divcap_original,0)
         from ca_operacion  with (nolock)
         where op_operacion = @w_operacionca

         --LPO CDIG Ajustes por Cobis Language INICIO
         SELECT @w_aux = datediff(dd,@w_min_di_fecha_ven,@w_fecha_proceso)+ @w_dias_ven_cart
         
         if ((@w_aux >= @w_num_dias_sus) or ((@w_calificacion >= @w_calificacion_sus)  and (@w_aux >= 1)) --LPO CDIG Parentesis por migracion a Cobis Language
         and (@w_estado in (@w_est_vigente, @w_est_vencido)))
         
         --LPO CDIG Ajustes por Cobis Language FIN
/*
         if (((datediff(dd,@w_min_di_fecha_ven,@w_fecha_proceso)+ @w_dias_ven_cart) >= @w_num_dias_sus) or (@w_calificacion >= @w_calificacion_sus and (datediff(dd,@w_min_di_fecha_ven,@w_fecha_proceso)+ @w_dias_ven_cart) >= 1))  --LPO CDIG Parentesis por migracion a Cobis Language
         and @w_estado in (@w_est_vigente, @w_est_vencido)
*/         
         begin
            
            --EVALUAR SI SE MARCA LA OPERACION COMO SUSPENDIDA EN op_suspendio
            --PARA QUE NO ENTRE NUEVAMENTE POR ESTA MARCA
            select @w_dias_salir_sus = 0
            if @w_min_di_fecha_ven is not null
               select @w_dias_salir_sus = datediff(dd, @w_min_di_fecha_ven, @w_fecha_proceso)
           
            if @w_dias_salir_sus <  @w_num_dias_sus begin
               --SI ESTA CONDICION SE CUMPLE, LA CAUSACION FUE POR CALIFICACION Y
               --NO DEBE QUEDAR MARCADA EN op_suspendio POR QUE EL BATCH LA VOLVERIA A
               --SUSPENDER POR ESTA MARCA CUANDO YA SALGA DE SUSPENSO AUTOMATICAMENTE
               update ca_operacion with (rowlock)
               set    op_suspendio = 'C'  --POR CALIFICACION
               where  op_operacion = @w_operacionca
            end
           
            select @w_estado = op_estado 
            from   ca_operacion  with (nolock)
            where  op_operacion = @w_operacionca
            
            if exists (select 1 from ca_estado with (nolock) where es_codigo = @w_estado and es_procesa = 'N')
               goto SALIR
         end
      end
 
      select @w_fecha_tmp = @w_fecha_prox_pago
      
      if @w_op_tipo = 'D' begin
         select @w_fecha_tmp = min(di_fecha_ven)
         from   ca_dividendo  with (nolock)
         where  di_operacion  = @w_operacionca
         and    di_estado     = @w_est_vigente
      end
      
      if @w_di_prorroga = 'S' begin
         select @w_dividendo2 = 0
         
         select @w_dividendo2 = min(di_dividendo)
         from   ca_dividendo  with (nolock)
         where  di_operacion = @w_operacionca
         and    di_estado    = @w_est_novigente
         
         select 
         @w_di_fecha_ini1 = di_fecha_ini,
         @w_dividendo1    = di_dividendo
         from   ca_dividendo  with (nolock)
         where  di_operacion = @w_operacionca
         and    di_dividendo = @w_dividendo2
         
         if @w_di_fecha_ini1 = @w_fecha_proceso begin 
         
            update ca_dividendo with (rowlock) set   
            di_estado    = @w_est_vigente
            where di_operacion = @w_operacionca
            and   di_dividendo = @w_dividendo1
            
            if @@error <> 0 begin
               select @w_error =  705043
               goto ERROR
            end
            
            update ca_amortizacion with (rowlock)
            set    am_estado    = @w_est_vigente
            where  am_operacion = @w_operacionca
            and    am_dividendo = @w_dividendo1
            and    am_estado    = @w_est_novigente 
            
            if @@error <> 0 begin
               select @w_error =  705050
               goto ERROR
            end
         end
      end
      
      --SE VALIDA SI PARA EL TRAMITE EN PROCESO SE DEBE REGENERAR EL SEGURO POR EFECTO DE
      --DISTRIBUCION DE GARANTIAS LA OBLIGACION DEBE TENER DIVIDENDO VIGENTE
      if @w_op_naturaleza <> 'P' and @w_fecha_fin >  @w_fecha_proceso begin
         select @w_div_vigente = max(di_dividendo)
         from   ca_dividendo  with (nolock) 
         where  di_operacion = @w_operacionca
         and    di_estado = @w_est_vigente
         
         select @w_max_dividendo = count(1)
         from   ca_dividendo with (nolock)
         where  di_operacion = @w_operacionca
         
         --PARA LA ULTIMA CUOTA VIGENET NO ENTRA, EL SEGURO YA NO SE REGENERA
         if @w_div_vigente <>  @w_max_dividendo and @w_estado <> @w_est_castigado begin
         
            if exists (select 1 from ca_seguros_base_garantia with (nolock)
            where sg_tramite = @w_tramite
            and   sg_fecha_reg = @w_fecha_proceso)
            begin
            
               select @w_sp_name = 'sp_distr_seguros_gar_cca'
               
               if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '180.sp_distr_seguros_gar_cca'
               if @i_debug = 'S' print '180.sp_distr_seguros_gar_cca ' + @w_banco
               
               exec @w_error =  sp_distr_seguros_gar_cca 
               @s_user              = @s_user,
               @i_fecha_proceso     = @w_fecha_proceso,
               @i_tramite           = @w_tramite,
               @i_op_operacion      = @w_operacionca,
               @i_moneda            = @w_op_moneda,
               @i_op_banco          = @w_banco
               
               if @w_error <> 0 goto ERROR
               
            end
         end
      end
	  
	  -------------------------------------------------------------------------------------------------
	  
       --LPO TEC Se invierte el orden de ejecución de estos dos sp's (primero se coloca sp_verifica_vencimiento y luego sp_veri_cambio_est_automatico):
      if @w_fecha_tmp = @w_fecha_proceso begin
      
         select @w_sp_name = 'sp_verifica_vencimiento'
         
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '190.sp_verifica_vencimiento'
         if @i_debug = 'S' print '190.sp_verifica_vencimiento ' + @w_banco
         
         exec @w_error = sp_verifica_vencimiento 
         @s_user               = @s_user,
         @s_term               = @s_term,
         @s_date               = @s_date,
         @s_ofi                = @s_ofi,
         @i_fecha_proceso      = @w_fecha_proceso,
         @i_operacionca        = @w_operacionca,
         @i_oficina            = @w_op_oficina,
         @i_cotizacion         = @w_cotizacion_hoy,
			@i_num_dec_mn         = @w_decimales_nacional
         
         if @w_error <> 0 goto ERROR
      end
           
	  -------------------------------------------------------------------------------------------------
	  --REALIZAR LA VERIFICACION Y EJECUCION DEL PASO AUTOMATICO DE CAMBIO DE ESTADO DE LAS OPERACIONES
	  --DESDE VIGENTE A VENCIDO Y DESDE VENCIDO A VIGENTE
	  if @w_estado in (@w_est_vigente, @w_est_vencido, @w_est_suspenso) --AGI.. Incluye vencido
	  begin
	    select @w_sp_name = 'sp_cambio_estado_op'
         
       if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '200.sp_cambio_estado_op'
       if @i_debug = 'S' print '200.sp_cambio_estado_op ' + @w_banco
  
       exec @w_error = sp_cambio_estado_op
       @s_user           = @s_user,
       @s_term           = @s_term,
       @s_date           = @s_date,
       @s_ofi            = @s_ofi,
       @i_banco          = @w_banco,
       @i_fecha_proceso  = @w_fecha_proceso,
       @i_tipo_cambio    = 'A',
       @i_en_linea       = @i_en_linea,
       @i_cotizacion     = @w_cotizacion_hoy,
       @i_num_dec        = @w_decimales_nacional,
       @o_msg            = @w_msg out

       if @w_error <> 0 goto ERROR
		 
	  end
      --LPO TEC FIN Se invierte el orden de ejecución de estos dos sp's (primero se coloca sp_verifica_vencimiento y luego sp_veri_cambio_est_automatico)

      
      select @w_dividendos_vencidos = 0
	  select @w_dividendos_vencidos = count(1)
	  from ca_dividendo
	  where di_operacion = @w_operacionca
	  and   di_estado    = @w_est_vencido
            
      -- CAMBIOS DE ESTADO DE OPERACIONES
      -- CAMBIO DE ESTADO A SUSPENSO AL PRIMER DIA DE MORA CUANDO YA HA ESTADO EN SUSPENSO ALGUNA VEZ 
      select @w_estado = op_estado
      from ca_operacion  with (nolock)
      where op_operacion = @w_operacionca
      
      -- SI CAMBIO EL IBC REAJUSTAR CAMBIO DE IBC (SOLO OPERACIONES ACTIVAS)
      if @w_op_naturaleza = 'A'  and @w_fecha_fin  > @w_fecha_proceso 
      begin
      
         select 
         @w_ibc_mn = 'N',
         @w_ibc_me = 'N',
         @w_uvr    = 'N'
         
         if @w_op_moneda = @w_moneda_nacional or @w_op_moneda = @w_moneda_uvr begin
         
            select 
            @w_ibc    = rtrim(@w_param_ibc_mn) + @w_op_clase, 
            @w_ibc_mn = 'S' 
            
            if @w_op_moneda = @w_moneda_uvr select @w_uvr = 'S'
            
         end else begin
         
            select 
            @w_ibc    = rtrim(@w_param_ibc_me) + @w_op_clase, 
            @w_ibc_me = 'S'
            
         end
         
         select @w_tlu_clase   = rtrim(@w_param_ibc_mn) + @w_op_clase 
         select @w_tluex_clase = rtrim(@w_param_ibc_me) + @w_op_clase 
         
         select @w_sp_name = 'sp_cambia_ibc' 
         
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '210.sp_cambia_ibc'
         if @i_debug = 'S' print '210.sp_cambia_ibc ' + @w_banco
           
         exec @w_error = sp_cambia_ibc
         @s_date            = @s_date,
         @s_user            = @s_user,
         @s_term            = @s_term,
         @s_ofi             = @s_ofi,
         @i_operacionca     = @w_operacionca,
         @i_moneda          = @w_op_moneda,
         @i_fecha_proceso   = @w_fecha_proceso,
         @i_ibc_mn          = 'N', --LRE 06/May/2019 @w_ibc_mn,
         @i_ibc_me          = @w_ibc_me,
         @i_moneda_nacional = @w_moneda_nacional,
         @i_moneda_uvr      = @w_moneda_uvr,
         @i_concepto_int    = @w_concepto_int,
         @i_param_ibc_mn    = @w_tlu_clase, -- S.Mora -REQ 715
         @i_param_ibc_me    = @w_tluex_clase, -- S.Mora -REQ 715
         @i_est_novigente   = @w_est_novigente,
         @i_est_cancelado   = @w_est_cancelado,
         @i_est_credito     = @w_est_credito,
         @i_est_castigado   = @w_est_castigado,
         @i_est_comext      = @w_est_comext,
         @i_en_linea        = @i_en_linea,
         @i_num_dec         = @w_num_dec,
         @i_concepto_cap    = @w_concepto_cap,
         @i_cotizacion      = @w_cotizacion_hoy ,
         @i_pago_ext        = @i_pago_ext --Req 482
         
         if @@error <> 0 or @w_error <> 0 goto ERROR
         
      end

	  ---SOLO HAY RESJUSTE AUTOMATICO SI HAY DIAS DE MORA CASO CONTRARIO NO
	  ----LOS ESTADO CASTIGADOS TAMPOCO REAJUSTAN
	  
	  if @w_dividendos_vencidos > 0 and @w_estado <> 4 
	  begin
			select   @w_campana  =  tr_campana,
			         @w_tr_tipo  = tr_tipo
			from     cob_credito..cr_tramite 
			where    tr_tramite  =  @w_tramite

          if @w_campana is not null and @w_tr_tipo <> 'M' --  No Reajustar las Normalizaciones 
		  begin
			  select @w_sp_name = 'sp_reajuste_campana'
      
           if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '220.sp_reajuste_campana'
           if @i_debug = 'S' print '220.sp_reajuste_campana ' + @w_banco

			  exec @w_error = sp_reajuste_campana
			  @s_user          = @s_user,
			  @s_term          = @s_term,
			  @s_date          = @s_date,
			  @s_ofi           = @s_ofi,
			  @i_fecha_proceso = @w_fecha_proceso,
			  @i_operacionca   = @w_operacionca
      
			  if @w_error <> 0 goto ERROR
		  end --pertenece a campaña 
	  end
      --COMENTADO EL EVALUAR CLIENTE , ESTO ES UNA REGLA DE NEGOCIO PROPIO DE BMI--CONSULTAR CON FABIAN
      /*Evaluar cliente Prospecto*/
      
 --     select @w_sp_name = 'sp_evaluar_cliente'
      
     -- if @i_debug = 'S' print 'Ejecutando sp: ' + @w_sp_name
     -- exec @w_error = sp_evaluar_cliente
     -- @i_evento      ='BAT',        
     -- @i_operacionca =@w_operacionca
      
      --if @w_error <> 0 goto ERROR
     -- 
      --Fin 300         
	  
      -- FECHA DE REAJUSTE
--      if @w_modalidad = 'P' and  --operaciones con cobro de rubros anticipados si debe reajustar
      if exists(select 1 from ca_reajuste with (nolock)
      where  re_operacion = @w_operacionca
      and    re_fecha     = @w_fecha_proceso)
      begin
         select @w_sp_name = 'sp_reajuste'
         
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '230.sp_reajuste'
         if @i_debug = 'S' print '230.sp_reajuste ' + @w_banco
         
         exec @w_error = sp_reajuste
         @s_user          = @s_user,
         @s_term          = @s_term,
         @s_date          = @s_date,
         @s_ofi           = @s_ofi,
         @i_en_linea      = @i_en_linea,
         @i_fecha_proceso = @w_fecha_proceso,
         @i_operacionca   = @w_operacionca,
         @i_modalidad     = @w_modalidad,
         @i_cotizacion    = @w_cotizacion_hoy,
         @i_num_dec       = @w_num_dec,
         @i_concepto_int  = @w_concepto_int,
         @i_concepto_cap  = @w_concepto_cap,
         @i_moneda_uvr    = @w_moneda_uvr,
         @i_moneda_local  = @w_moneda_nacional
         
		 if @w_error <> 0 begin               --GFP 22/04/2021
            if @i_en_linea = 'S' goto ERROR 
            exec sp_errorlog 
            @i_fecha     = @s_date,
            @i_error     = @w_error,
            @i_usuario   = @s_user,
            @i_tran      = 7999,
            @i_tran_name = @w_sp_name,
            @i_cuenta    = @w_banco,
            @i_rollback  = 'N'
            select @w_error = 0
         end
         
         select @w_nuevo_interes = 'S' -- HAY UN NUEVO INTERES
         
      end

      if @w_nuevo_interes = 'S' begin
         select @w_nuevo_interes = 'N' -- NO VOLVER A BUSCAR LA TASA CORRIENTE
         
         select 
         @w_tasa_corriente_efa = ro_porcentaje_efa,
         @w_tasa_corriente_nom = ro_porcentaje
         from   ca_rubro_op  with (nolock)
         where  ro_operacion   = @w_operacionca
         and    ro_tipo_rubro  = 'I'
         and    ro_fpago      in ('A', 'P')
         
         if @w_tasa_corriente_efa < 0
            select 
            @w_tasa_corriente_efa = 0,
            @w_tasa_corriente_nom = 0
      end
     
	  /* KDR El INICIO DE DÍA SE ACTUALIZA DESPUES DE CALCULAR, INT, IMO, CARGESCOB.
      --INICIO DE DIA
      select @w_fecha_proceso_ini_dia = dateadd(dd,1,@w_fecha_proceso)

      update ca_operacion with (rowlock)
      set    op_fecha_ult_proceso = @w_fecha_proceso_ini_dia
      where  op_operacion = @w_operacionca
      
      if @@error<> 0 begin
         select @w_error = 70507
         goto ERROR
      end*/

	  -------------------------------------------------------------------------------------------------
      -- KDR 15/10/2021: Inclusión de rubro(cobranza) de cargos de gestión de cobranza si el préstamo esta en mora.
      if exists (select 1 from ca_dividendo where di_operacion = @w_operacionca and di_estado = @w_est_vencido)
	             and (isnull(@i_operacionFR, '') <> 'R')
	  BEGIN
	  
	     if exists (select 1 from ca_rubro, cobis..cl_tabla t, cobis..cl_catalogo c
                    where t.tabla = 'ca_cargos_gestion_cobranza'
                    and   t.codigo      = c.tabla
                    and   c.estado      = 'V'
                    and   c.codigo      = ru_concepto
                    and   ru_toperacion = @w_toperacion
                    and   ru_moneda     = @w_op_moneda)
         begin
		 		
            select @w_sp_name = 'sp_cargos_gestion_cobranza_automatico'
            
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '89.sp_cargos_gestion_cobranza_automatico'
            if @i_debug = 'S' print '89.sp_cargos_gestion_cobranza_automatico ' + @w_banco
		  
            exec @w_error = sp_cargos_gestion_cobranza_automatico
            @s_ofi         = @s_ofi,
            @s_user        = @s_user,
            @s_date        = @s_date,
            @s_term        = @s_term,
            @s_sesn        = @s_sesn,
            @i_banco       = @w_banco,
            @i_operacionca = @w_operacionca,
            @i_en_linea    = @i_en_linea
		 
            if @w_error <> 0 begin
               if @i_en_linea = 'S' goto ERROR 
               exec sp_errorlog 
               @i_fecha     = @s_date,
               @i_error     = @w_error,
               @i_usuario   = @s_user,
               @i_tran      = 7999,
               @i_tran_name = @w_sp_name,
               @i_cuenta    = @w_banco,
               @i_rollback  = 'N'
               select @w_error = 0
            end
		  
		  end
	  
	  end
	  -- Fin Inclusión de rubro(cobranza) de cargos de gestión de cobranza si el préstamo esta en mora.


      --DOBLE CIERRE AUTOMATICO
      if datepart(mm, @w_fecha_proceso_ini_dia) <> datepart(mm, @w_fecha_proceso) 
         select @s_date = @s_date_sigdiahabil
      else
         select @s_date = @s_date_sigdiahabil
     
      if @w_op_tipo = 'D' begin

         select @w_sp_name = 'sp_calculo_diario_int_dd'
         
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '240.sp_calculo_diario_int_dd'
         if @i_debug = 'S' print '240.sp_calculo_diario_int_dd ' + @w_banco
         
         exec @w_error =  sp_calculo_diario_int_dd
         @s_user               = @s_user,
         @s_term               = @s_term,
         @s_date               = @s_date,
         @s_ofi                = @s_ofi,
         @i_fecha_proceso      = @w_fecha_proceso, --@w_fecha_proceso_ini_dia
         @i_operacionca        = @w_operacionca,
         @i_cotizacion         = @w_cotizacion_hoy
         
         if @w_error <> 0 begin
            if @i_en_linea = 'S' goto ERROR 
            exec sp_errorlog 
            @i_fecha     = @s_date,
            @i_error     = @w_error,
            @i_usuario   = @s_user,
            @i_tran      = 7999,
            @i_tran_name = @w_sp_name,
            @i_cuenta    = @w_banco,
            @i_rollback  = 'N'
            select @w_error = 0
         end
         
      end else begin

            select @w_sp_name = 'sp_calculo_diario_int'
            
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '250.sp_calculo_diario_int'
            if @i_debug = 'S' print '250.sp_calculo_diario_int ' + @w_banco
            
            exec @w_error = sp_calculo_diario_int
            @s_user               = @s_user,
            @s_term               = @s_term,
            @s_date               = @s_date,
            @s_ofi                = @s_ofi,
            @i_en_linea           = @i_en_linea,
            @i_toperacion         = @w_toperacion,
            @i_banco              = @w_banco,
            @i_operacionca        = @w_operacionca,
            @i_moneda             = @w_op_moneda,
            @i_dias_anio          = @w_dias_anio,
            @i_sector             = @w_sector,
            @i_oficina            = @w_op_oficina,
            @i_fecha_liq          = @w_fecha_liq,
            @i_fecha_ini          = @w_fecha_ini,
            @i_fecha_proceso      = @w_fecha_proceso, --@w_fecha_proceso_ini_dia
            @i_tdividendo         = @w_tdividendo,
            @i_base_calculo       = @w_base_calculo,
            @i_dias_interes       = @w_dias_interes,
            @i_tipo               = @w_op_tipo,
            @i_gerente            = @w_oficial,
            @i_cotizacion         = @w_cotizacion_hoy,
            @i_parametros_llamada = 'S',
            @i_parametro_int      = @w_parametro_int,
            @i_moneda_nacional    = @w_moneda_nacional,
            @i_concepto_cap       = @w_concepto_cap,
            @i_causacion          = @w_causacion,
            @i_fecultpro          = @w_fecha_proceso,
            @i_gar_admisible      = @w_gar_admisible,
            @i_reestructuracion   = @w_reestructuracion,
            @i_calificacion       = @w_calificacion,
            @i_num_dec            = @w_num_dec,
            @i_num_dec_mn         = @w_decimales_nacional

            if @w_error <> 0 goto ERROR
      end
    
      -- CALCULO DIARIO DE INTERESES DE MORA
      if @w_op_naturaleza <> 'P' and @w_dividendos_vencidos > 0
      begin

			 select @w_sp_name = 'sp_calculo_diario_mora'
         
          if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '260.sp_calculo_diario_mora'
          if @i_debug = 'S' print '260.sp_calculo_diario_mora ' + @w_banco

			 exec @w_error = sp_calculo_diario_mora
			 @s_user               = @s_user,
			 @s_term               = @s_term,
			 @s_date               = @s_date,
			 @s_ofi                = @s_ofi,
			 @i_en_linea           = @i_en_linea,
			 @i_banco              = @w_banco,
			 @i_operacionca        = @w_operacionca,
			 @i_moneda             = @w_op_moneda,
			 @i_oficina            = @w_op_oficina,
			 @i_fecha_proceso      = @w_fecha_proceso, --@w_fecha_proceso_ini_dia
			 @i_cotizacion         = @w_cotizacion_hoy ,
			 @i_num_dec            = @w_num_dec,
			 @i_est_suspenso       = @w_est_suspenso,
			 @i_est_vencido        = @w_est_vencido,
			 @i_ciudad_nacional    = @w_ciudad_nacional,
			 @i_num_dec_mn         = @w_decimales_nacional
         
			 if @@error <> 0 select @w_error = 1000
			 
			 if @w_error <> 0 goto ERROR
      end  -- CALCULO DE MORA

      /* -- KDR Se comenta sección que no aplica a versión De Finca
      --GENERACION DE LA COMISION DIFERIDA
      if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '270.sp_comision_diferida'
      if @i_debug = 'S' print '270.sp_comision_diferida ' + @w_banco

      exec @w_error  = sp_comision_diferida
      @s_date        = @s_date,
      @i_operacion   = 'P',
      @i_operacionca = @w_operacionca,
      @i_num_dec     = @w_num_dec,
      @i_num_dec_n   = @w_decimales_nacional,
      @i_cotizacion  = @w_cotizacion_hoy
      
      if @w_error <>0 goto ERROR
      
      if @w_op_naturaleza <> 'P'
      and @w_fecha_fin <=  @w_fecha_proceso and @w_estado <> @w_est_castigado
      begin
         -- LLAMADO AL CALCULO DE LOS SEGUROS DE OBLIGACIONES VENCIDAS
         -- PARA EVITAR QUE QUEDEN DESCUBIERTAS DESPUES DEL VTO. TOTAL
         select @w_sp_name = 'sp_seguro_op_vencidas'
         
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '280.sp_seguro_op_vencidas'
         if @i_debug = 'S' print '280.sp_seguro_op_vencidas ' + @w_banco
         
         exec @w_error = sp_seguro_op_vencidas
         @s_user               = @s_user,
         @s_term               = @s_term,
         @s_date               = @s_date,
         @s_ofi                = @s_ofi,
         @i_en_linea           = @i_en_linea,
         @i_toperacion         = @w_toperacion,
         @i_banco              = @w_banco,
         @i_operacionca        = @w_operacionca,
         @i_moneda             = @w_op_moneda,
         @i_oficina            = @w_op_oficina,
         @i_fecha_proceso      = @w_fecha_proceso,
         @i_dias_interes       = @w_dias_interes,
         @i_tipo               = @w_op_tipo,
         @i_gerente            = @w_oficial,
         @i_cotizacion         = @w_cotizacion_hoy,
         @i_moneda_nacional    = @w_moneda_nacional,
         @i_fecultpro          = @w_fecha_proceso,
         @i_gar_admisible      = @w_gar_admisible,
         @i_reestructuracion   = @w_reestructuracion,
         @i_calificacion       = @w_calificacion,
         @i_num_dec            = @w_num_dec,
         @i_moneda_uvr         = @w_moneda_uvr,
         @i_fecha_prox_segven  = @w_op_fecha_prox_segven out
         
         if @w_error <> 0 goto ERROR
         
      end
	  */  -- FIN KDR Se comenta sección que no aplica a versión De Finca
      
      -- CORRECCION MONETARIA
      if @w_op_moneda = @w_moneda_uvr begin
      
         select 
         @w_cotizacion_siguiente = 0,
         @w_fecha_cotizacion     = @w_fecha_proceso --@w_fecha_proceso_ini_dia
         
         -- OBTENER COTIZACION SIGUIENTE
         exec sp_buscar_cotizacion
         @i_moneda     = @w_op_moneda,
         @i_fecha      = @w_fecha_cotizacion,
         @o_cotizacion = @w_cotizacion_siguiente output
         
         -- EJECUTAR SP DE CORRECCION
         select @w_sp_name = 'sp_correccion_monetaria'
         
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '290.sp_correccion_monetaria'
         if @i_debug = 'S' print '290.sp_correccion_monetaria ' + @w_banco
         
         exec @w_error = sp_correccion_monetaria
         @s_user                 = @s_user,
         @s_term                 = @s_term,
         @s_date                 = @s_date,
         @s_ofi                  = @s_ofi,
         @i_en_linea             = @i_en_linea,
         @i_toperacion           = @w_toperacion,
         @i_banco                = @w_banco,
         @i_operacionca          = @w_operacionca,
         @i_estado_op            = @w_estado, 
         @i_oficina              = @w_op_oficina,
         @i_gerente              = @w_oficial,
         @i_moneda               = @w_op_moneda,
         @i_fecha_proceso        = @w_fecha_proceso, --@w_fecha_proceso_ini_dia
         @i_cotizacion_hoy       = @w_cotizacion_hoy,
         @i_cotizacion_siguiente = @w_cotizacion_siguiente,
         @i_aplicar_fecha_valor  = @i_aplicar_fecha_valor
         
         if @w_error <> 0 goto ERROR
    
      end
      
	  /* -- KDR Se comenta sección que no aplica a versión De Finca
      -- CAPITALIZACION DE INTERESES
      select @w_cuota_validar = isnull(max(gs_cuota),0)
      from   ca_gracia_seguros  with (nolock)
      where  gs_operacion = @w_operacionca
      and    gs_fecha_regeneracion = @w_fecha_proceso
      
      if @w_cuota_validar > 0 begin
         declare 
            @w_est_cuota_validar int
         select @w_est_cuota_validar = di_estado
         from   ca_dividendo with (nolock)
         where  di_operacion = @w_operacionca
         and    di_dividendo = @w_cuota_validar
         
         if @w_est_cuota_validar  <> 3 begin
            select @w_sp_name = 'sp_congela_seguros'
            
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '300.sp_congela_seguros'
            if @i_debug = 'S' print '300.sp_congela_seguros ' + @w_banco
            
            exec @w_error = sp_congela_seguros
            @s_user               = @s_user,
            @s_term               = @s_term,
            @s_date               = @s_date,
            @s_ofi                = @s_ofi,
            @i_fecha_proceso      = @w_fecha_proceso,
            @i_operacionca        = @w_operacionca,
            @i_dividendo_vigente  = @w_cuota_validar 
            
            if @w_error <> 0 begin
               if @i_en_linea = 'S' goto ERROR 
               exec sp_errorlog 
               @i_fecha     = @s_date,
               @i_error     = @w_error,
               @i_usuario   = @s_user,
               @i_tran      = 7999,
               @i_tran_name = @w_sp_name,
               @i_cuenta    = @w_banco,
               @i_rollback  = 'N'
               select @w_error = 0
            end
         end 
      end     
 
      ---Despues de capitalizacion se ejecuta el recalculo de comisiones fag
      if @w_op_naturaleza = 'A' and @w_op_tipo not in ( 'D','R','G','V','N') and @w_op_moneda = @w_moneda_nacional begin
         if exists (select 1 from ca_amortizacion  with (nolock)
         where am_operacion = @w_operacionca
         and   am_concepto  = @w_parametro_fag
         and   am_estado   <> 3)
         begin 
            select @w_sp_name = 'sp_recalculo_fag'
            
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '310.sp_recalculo_fag'
            if @i_debug = 'S' print '310.sp_recalculo_fag ' + @w_banco
            
            exec @w_error = sp_recalculo_fag
            @i_operacionca    = @w_operacionca,
            @i_tramite        = @w_tramite,
            @i_sector         = @w_sector,
            @i_num_dec        = @w_num_dec
            
            if @w_error <> 0 begin
               if @i_en_linea = 'S' goto ERROR 
               exec sp_errorlog 
               @i_fecha     = @s_date,
               @i_error     = @w_error,
               @i_usuario   = @s_user,
               @i_tran      = 7999,
               @i_tran_name = @w_sp_name,
               @i_cuenta    = @w_banco,
               @i_rollback  = 'N'
               select @w_error = 0
            end
         end
      end 
      
      -- TRASLADO CXCINTES
      if (@w_fecha_prox_pago = dateadd(dd,1,@w_fecha_proceso)) and (@w_op_tipo <> 'D' ) 
	  begin
      
         select @w_div_vigente = max(di_dividendo)
         from   ca_dividendo  with (nolock)
         where  di_operacion = @w_operacionca
         and    di_estado = @w_est_vigente
         
         if exists(select 1 from   ca_traslado_interes with (nolock)
         where  ti_operacion = @w_operacionca
         and    ti_cuota_orig  = @w_div_vigente)
         begin 
            select @w_sp_name = 'sp_ejecuta_traslado_int'
            
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '320.sp_ejecuta_traslado_int'
            if @i_debug = 'S' print '320.sp_ejecuta_traslado_int ' + @w_banco
            
            exec @w_error = sp_ejecuta_traslado_int
            @s_user              = @s_user,
            @s_term              = @s_term,
            @s_date              = @s_date,
            @s_ofi               = @s_ofi,
            @i_operacion         = @w_operacionca,
            @i_dividendo_vig     = @w_div_vigente,
            @i_banco             = @w_banco,
            @i_toperacion        = @w_toperacion,
            @i_moneda            = @w_op_moneda,
            @i_oficial           = @w_oficial,
            @i_oficina           = @w_op_oficina,
            @i_gar_admisible     = @w_gar_admisible,
            @i_reestructuracion  = @w_reestructuracion,
            @i_calificacion      = @w_calificacion,
            @i_estado_op         = @w_estado,
            @i_en_linea          = @i_en_linea,
            @i_fecha_proceso     = @w_fecha_proceso
            
            if @w_error <> 0 goto ERROR
            
         end --FIN GENERAR TRASLADO INTERESES
      end
      */  -- FIN KDR Se comenta sección que no aplica a versión De Finca
      
      
	  /* -- KDR Se bloquea sección para que no elimine abonos no aplicados.
      --LPO TEC INICIO, SE BORRA LOS ABONOS PENDIENTES PARA QUE NO QUEDEN CON FECHA MENOR A LA FECHA DE PROCESO DE LA OP.
      --- BORRAR EL DETALLE DE LOS ABONOS PENDIENTES NO APLICADOS
      delete ca_abono_det
      from   ca_abono
      where  abd_operacion     = @w_operacionca
      and    ab_operacion      = abd_operacion
      and    ab_secuencial_ing = abd_secuencial_ing
      and    ab_estado        in ('ING','SUS','E')
      and    ab_secuencial_pag = 0
      and    ab_cuota_completa = 'S'
      
      if @@error <> 0 begin
         select @w_error = 710002, @w_msg = 'ERROR AL ELIMINAR DETALLE DE ABONOS PENDIENTES'
         goto ERROR
      end

      -- BORRAR LOS ABONOS PENDIENTES NO APLICADOS
      delete ca_abono
      where  ab_operacion      = @w_operacionca
      and    ab_estado        in ('ING','SUS','E')
      and    ab_secuencial_pag = 0
      and    ab_cuota_completa = 'S'
       
      if @@error <> 0 begin
         select @w_error = 710002, @w_msg = 'ERROR AL ELIMINAR ABONOS PENDIENTES'
         goto ERROR
      end
      --LPO TEC FIN SE BORRA LOS ABONOS PENDIENTES PARA QUE NO QUEDEN CON FECHA MENOR A LA FECHA DE PROCESO DE LA OP.
	  */
            
      goto SIGUIENTE
      
      ERROR:
      
      if @w_commit = 'S' begin
         rollback tran
         select @w_commit = 'N'
      end

      if @i_en_linea = 'S' begin
         exec cobis..sp_cerror 
         @t_debug= 'N',
         @t_file = null,
         @t_from = @w_sp_name,
         @i_num  = @w_error,
         @i_msg  = @w_msg

         return @w_error
      end       
      
      exec sp_errorlog 
      @i_fecha     = @s_date,
      @i_error     = @w_error,
      @i_usuario   = @s_user,
      @i_tran      = 7999,
      @i_tran_name = @w_sp_name,
      @i_cuenta    = @w_banco,
      @i_descripcion = @w_msg,
      @i_rollback    = 'S'
      
      if @w_commit = 'S'
         while @@trancount > 0 rollback tran

      /* SVA - Datos Consolidador, si la operacion tuvo error, se hizo rollback, por tanto se la vuelve a ingresar
         al consolidador */
         
      /* AMO 2022-05-12 SUPRIMIR EJECUCION DE SP_CONSOLIDADOR_CCA
      if @i_en_linea = 'N' and @i_pry_pago = 'N'
      begin
         if exists (select 1 
                    from   cob_cartera..ca_operacion, cob_cartera..ca_estado
                    where  op_estado  = es_codigo
                    and    es_procesa = 'S' 
                    and    op_banco   = @w_banco)
         begin
            if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '330.sp_consolidador_cca'
            if @i_debug = 'S' print '330.sp_consolidador_cca ' + @w_banco

            exec @w_error = cob_externos..sp_consolidador_cca
            @i_param1          = @w_banco,
            @i_param4          = @i_simular_cierre,
            @i_param3          = @i_debug

            if @w_error <> 0
            begin
               exec sp_errorlog 
               @i_fecha     = @s_date,
               @i_error     = @w_error,
               @i_usuario   = @s_user,
               @i_tran      = 7999,
               @i_tran_name = @w_sp_name,
               @i_cuenta    = @w_banco,
               @i_rollback  = 'N'
            
               select @w_error = 0
            end
         end
      end
      */

      goto SALIR 
               
      SIGUIENTE:
      
      -- VALIDAR CAMBIO DE MES
      select @w_fecha_proceso = dateadd(dd, 1, @w_fecha_proceso)
	  
	  -- NUEVO INICIO DE DÍA
	  update ca_operacion with (rowlock)
      set    op_fecha_ult_proceso = @w_fecha_proceso
      where  op_operacion = @w_operacionca
      
      if @@error<> 0 begin
         select @w_error = 70507
         goto ERROR
      end
	  
      -- KDR 26/08/2022 Proceso para actualizar registros por el cambio de período contable
	  if datepart(yy, @w_fecha_proceso) <> datepart(yy, dateadd(dd, -1, @w_fecha_proceso))
	     and isnull(@w_cambio_per_contable, 'N') = 'S'
	  begin
	  
	     select @w_sp_name = 'sp_cambio_periodo'
		 
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '261.sp_cambio_periodo'
         if @i_debug = 'S' print '261.sp_cambio_periodo ' + @w_banco
		 
         exec @w_error = sp_cambio_periodo
         @s_user          = @s_user,   
         @s_term          = @s_term,
         @s_date          = @s_date,
         @s_ofi           = @s_ofi,
         @i_en_linea      = @i_en_linea,
         @i_toperacion    = @w_toperacion,
         @i_banco         = @w_banco,
         @i_operacionca   = @w_operacionca,
         @i_moneda        = @w_op_moneda,
         @i_oficina       = @w_op_oficina,
         @i_fecha_proceso = @w_fecha_proceso
		 
         if @w_error <> 0 
		 begin
            if @i_en_linea = 'S' goto ERROR 
            exec sp_errorlog 
            @i_fecha     = @s_date,
            @i_error     = @w_error,
            @i_usuario   = @s_user,
            @i_tran      = 7999,
            @i_tran_name = @w_sp_name,
            @i_cuenta    = @w_banco,
            @i_rollback  = 'N'
            select @w_error = 0
         end
	  
	  end
	  -- FIN KDR 26/08/2022 Cambio periodo contable
     
      /* FIN DE ATOMICIDAD POR FECHAS */
      if @i_pry_pago = 'N' begin
         while @@trancount > @w_trancount COMMIT TRAN
         select @w_commit = 'N'
      end
      
   end  -- FIN WHILE @w_fecha_proceso < @w_siguiente_dia (PROCESAMIENTO POR FECHAS)
   

   /* PARA FECHA VALOR APLICAR PAGOS PENDIENTES DEL ULTIMO DIA */
   if @i_en_linea = 'S' 
   begin
      select @w_sp_name = 'sp_abonos_batch (2)'
      
      if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '340.sp_abonos_batch'
      if @i_debug = 'S' print '340.sp_abonos_batch ' + @w_banco
      
      exec @w_error = sp_abonos_batch
      @s_user          = @s_user,
      @s_term          = @s_term,
      @s_date          = @s_date,
      @s_ofi           = @s_ofi,
      @i_en_linea      = @i_en_linea,
      @i_fecha_proceso = @w_fecha_proceso,
      @i_operacionca   = @w_operacionca,
      @i_banco         = @w_banco,
      @i_pry_pago      = @i_pry_pago,
      @i_cotizacion    = @w_cotizacion_hoy
      
      if @w_error <> 0 
      begin
         if @i_en_linea = 'S' 
         begin 
            exec cobis..sp_cerror 
            @t_debug = 'N',
            @t_file  = null,
            @t_from  = @w_sp_name,
            @i_num   = @w_error
            return @w_error
         end  
         exec sp_errorlog 
         @i_fecha     = @s_date,
         @i_error     = @w_error,
         @i_usuario   = @s_user,
         @i_tran      = 7999,
         @i_tran_name = @w_sp_name,
         @i_cuenta    = @w_banco,
         @i_rollback  = 'N'
         select @w_error = 0
      end
   end --APLICANDO PAGOS DEL ULTIMO DIA EN FECHA VALOR

   SALIR:
   
   if @i_pry_pago = 'N' 
   begin
      while @@trancount > @w_trancount COMMIT TRAN
      select @w_commit = 'N'
   end

   /* SVA - Datos Consolidador: datos al inicio del siguiente dia habil para tener los saldos al día*/
   /* AMO 2022-05-12 SUPRIMIR EJECUCION DE SP_CONSOLIDADOR_CCA
   if @i_en_linea = 'N' and @i_pry_pago = 'N' and (@w_fecha_proceso = @w_siguiente_dia) 
   begin
      if exists (select 1 
                 from   cob_cartera..ca_operacion, cob_cartera..ca_estado
                 where  op_estado  = es_codigo
                 and    es_procesa = 'S' 
                 and    op_banco   = @w_banco)
      begin
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '350.sp_consolidador_cca'
         if @i_debug = 'S' print '350.sp_consolidador_cca ' + @w_banco

         exec @w_error = cob_externos..sp_consolidador_cca
		 @i_param1          = @w_banco,
		 @i_param2          = @w_siguiente_dia,
         @i_param4          = @i_simular_cierre,
         @i_param3          = @i_debug

         if @w_error <> 0
         begin
            exec sp_errorlog 
            @i_fecha     = @s_date,
            @i_error     = @w_error,
            @i_usuario   = @s_user,
            @i_tran      = 7999,
            @i_tran_name = @w_sp_name,
            @i_cuenta    = @w_banco,
            @i_rollback  = 'N'
            
            select @w_error = 0
         end
      end
   end 
   */  
end /* while @w_detener_proceso = 'N' */

FIN:
 
----------------- ATX ------------------------
if @i_pry_pago = 'N'  
begin
   if @i_banco is not null 
   begin
      select 
      @w_op_tipo   = op_tipo,
      @w_pago_caja = op_pago_caja
      from ca_operacion with (nolock)
      where op_banco =  @i_banco
      
      if @w_op_tipo  <>  'R'  and  @w_pago_caja = 'S' 
      begin
         select @w_sp_name = 'sp_valor_atx_mas'
         
         if @i_debug = 'S' exec sp_reloj @i_hilo = @i_hilo, @i_banco = @w_banco, @i_posicion = '360.sp_valor_atx_mas'
         if @i_debug = 'S' print '360.sp_valor_atx_mas ' + @w_banco

         exec @w_error = sp_valor_atx_mas
         @s_user  = @s_user,
         @s_date  = @s_date,
         @i_banco = @i_banco
         
         if @w_error <> 0 goto ERROR_BATCH
         
      end 
   end
   --while @@trancount > 0 rollback Req 457
   while @@trancount > @w_trancount rollback

end

if @i_pry_pago = 'N'
   return 0
if @i_pry_pago = 'S'  --para desplegar error si lo hubiere en simulacion
   return @w_error

 
ERROR_BATCH:
while @@trancount > 0 rollback
if @i_en_linea = 'S' begin
   exec cobis..sp_cerror 
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg

   return @w_error
   
end else begin 

   while @@trancount > 0 rollback tran
   
   exec sp_errorlog 
   @i_fecha = @s_date,
   @i_error = @w_error, 
   @i_usuario=@s_user, 
   @i_tran=7999,
   @i_tran_name   = @w_sp_name,
   @i_cuenta      = @w_banco,
   @i_descripcion = @w_msg,
   @i_rollback    = 'S'
end

if @i_pry_pago = 'N'
   return 0
if @i_pry_pago = 'S'  --para desplegar error si lo hubiere en simulacion
   return @w_error
 
go

