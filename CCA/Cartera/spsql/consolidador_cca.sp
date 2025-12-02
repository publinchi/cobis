/************************************************************************/
/*   NOMBRE LOGICO:      consolidador_cca.sp                            */
/*   NOMBRE FISICO:      sp_consolidador_cca                            */
/*   BASE DE DATOS:      cob_externos                                   */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Ricardo Reyes                                  */
/*   FECHA DE ESCRITURA: Abr.09.                                        */
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
/*   Extraccion de datos para el consolidador ex_dato_operacion         */
/************************************************************************/
/*                               MODIFICACIONES                         */
/*  FECHA              AUTOR          CAMBIO                            */
/*  OCT-2010  Elcira Pelaez    Diferidos NR059                          */
/*  ENE-2012  Luis C. Moreno   RQ293-RECONOCIMIENTO GARANTIAS           */
/*  MAY-2013  Andres A. Muñoz  RQ353-ALIANZAS COMERCIALES               */
/*  ABR-2014  Liana Coto       Req 425 -- FORMATO 507                   */
/*  JUN-2014  Luis Guzmán      Req. 394 - Venta Cartea Castigada        */
/*  JUL-2014  Luisa Bernal     RQ375-TRASLADO CARTERA_CUPOS             */
/*  ENE/2015  Liana Coto       REQ486 PASO REPOSITORIO                  */
/*                             DATOS TRASLADOS CLIENTES                 */
/*  DIC-2014  Oskar Orozco     Req. 472 - Nuevo Campo de mora           */
/*  DIC-2014  LIANA COTO       REQ479 FINAGRO                           */
/*  OCT-2016  JORGE SALAZAR    MIGRACION COBIS CLOUD                    */
/*  ABR-2017  TANIA BAIDAL     CL_ENTE_AUX POR CL_ENTE_ADICIONAL        */
/*  AGO-2017  SANDRA ECHEVERRI AJUSTE PARA PROVISIONES                  */
/*  SEP-2017  TANIA BAIDAL     SE MODIFICA ESTRUCTURA ex_dato_operacion */
/*  ENE-2018  LGU              MODIFICAR ESTRUCTURA ex_dato_operacion   */
/*                                              ex_dato_operacion_rubro */
/*                                                    ex_dato_cuota_pry */
/*  AGO-2020  AMGE             Ajuste de actualización                  */
/*  AGO-2020  Sandro Vallejo   Ajuste Datos Consolidador                */
/*  16/07/21  G.Fernandez      Estandarizacion de parametros            */
/*  03/09/21  G.Fernandez      Se comenta referencias a tablas que no   */
/*                             exiten en el ambiente hasta ver su uso   */
/*  07/07/22  G.Fernandez      Se incluye param5 para borrar datos de   */
/*                             las tablas cob_externos en un reproceso  */
/*  05/05/23  G.Fernandez      S785513 Ingreso de nuevos campos         */
/*  24/08/23  K. Rodriguez     Correcc. cod_val de tabla de rubros      */
/*  16/11/23  E. Medina        R219160 ca_toperacion no GRUPAL          */
/************************************************************************/  

use cob_externos
go
 
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select 1 from sysobjects where name = 'sp_consolidador_cca')
   drop proc sp_consolidador_cca
go
---INC. 112734 MAY.06.2013
CREATE proc sp_consolidador_cca(
   @i_param1                 varchar(20) = null,  -- Nro. Prestamo
   @i_param2                 datetime    = null,  -- Fecha de pro
   @i_param3                 char(1)     = 'N',   -- Debug
   @i_param4                 datetime    = null,  -- Simular cierre
   @i_param5                 char(1)     = 'N'    -- Validación de reproceso en la misma fecha
)
as 
declare
   @w_error                 int,
   @w_sp_name               varchar(64),
   @w_fecha_proceso         datetime,
   @w_fecha_ini             datetime,   
   @w_fecha_ven             datetime,   
   @w_msg                   varchar(64),
   @w_rubro_int             char(10),
   @w_rubro_intant          char(10),
   @w_rubro_ivaint          char(10),
   @w_rubro_imo             char(10),
   @w_est_vigente           tinyint,
   @w_est_novigente         tinyint,
   @w_est_vencido           tinyint,
   @w_est_cancelado         tinyint,
   @w_est_suspenso          tinyint,
   @w_est_castigado         tinyint,
   @w_est_diferido          tinyint,
   @w_fecha_fm              datetime,
   @w_ciudad                int,
   @w_sig_habil             datetime,
   @w_fin_mes               char(1),
   @w_dias_gracia_reest     tinyint,   --Nuevo Desarrollo Control de Cambio Reest
   @w_rubro_cap             catalogo,
   @w_concepto_rec_fng      varchar(30),
   @w_concepto_rec_usa      varchar(30),
   @w_cod_gar_esp           varchar(30),
   @w_cod_gar_fng           varchar(30),
   @w_cod_gar_usaid         varchar(30),
   @w_cto_int               catalogo,
   @w_cto_inttras           catalogo,
   @w_numdias               int, 
   @w_div_min_sig           int,
   @w_div_min_ex            int,
   @w_fecha_ven_ant         datetime,
   @w_fecha_ven_sig         datetime,
   @w_operacion             int,
   @w_num_div_cap 			int,
   @w_num_div_int 			int,
   @w_tdividendo			char(1),
   @w_factor				int,
   @w_mod_pago				int,
   @w_num_ciclo_ant         int,
   @w_grupo_act             int,
   @w_return                int,
   @w_resultado             int,
   @w_codigo_act_apr        int,
   @w_codigo_act_cuest      int,
   @w_dias_atraso           int,   
   @w_operaciones_aux       int,
   @w_ciclo_actual          int,
   @w_dias_atr_cic_ant      int ,
   @w_grupo_aux             int,
   @w_ciudad_nacional       int, 
   @w_operacionca           int,
   @w_cliente               int,
   @w_op_numero_reest       int,
   @w_sacumv                varchar(15),
   @w_op_estado             int,
 --Variables para parametros batch
   @i_banco                 varchar(20), 
   @i_fecha_proceso         datetime,
   @i_debug                 char(1),
   @i_simular_cierre        DATETIME
   
IF @i_param1 = 'NULL'
  SELECT @i_param1 = null
   
--GFP 16/07/2021 paso de parametros de batch a variables locales
select
   @i_banco              =  @i_param1,
   @i_fecha_proceso      =  @i_param2,
   @i_debug              =  @i_param3,
   @i_simular_cierre     =  @i_param4      
   
set ansi_warnings off

/* CARGADO DE VARIABLES DE TRABAJO */
select 
@w_sp_name   = 'sp_consolidador',
@w_fin_mes   = 'N',
@w_operacion = 0

/*DETERMINAR LA FECHA DE PROCESO */
if @i_fecha_proceso is null
   select @w_fecha_proceso = fc_fecha_cierre  --cierre contable
   from cobis..ba_fecha_cierre
   where fc_producto = 7
else 
   select @w_fecha_proceso = @i_fecha_proceso  --cierre siguiente dia habil, para saldos al día

--Simular el cierre enviando la fecha de cierre diferente a la de la tabla   
if @i_simular_cierre is not null
begin
   if @i_fecha_proceso is null
      select @w_fecha_proceso = @i_simular_cierre
   else 
      select @w_fecha_proceso = @i_fecha_proceso  --cierre siguiente dia habil, para saldos al día
end

select @w_fecha_ini     = dateadd(dd,1-datepart(dd,@w_fecha_proceso), @w_fecha_proceso)

-- CONCEPTOS DE INTERES
select @w_cto_int = 'INT',
       @w_cto_inttras = 'INTTRAS'

select @w_cto_int = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'

select @w_cto_inttras = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'TRASIN'

-- Codigo padre para garantias colaterales
select @w_cod_gar_esp = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'GARESP'

---parametro para el cargue de los reconocimientos
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

select @w_cod_gar_usaid = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and pa_nemonico = 'CODUSA'

select @w_concepto_rec_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'RECFNG'

select @w_concepto_rec_usa = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'RECUSA'

/* CIUDAD DE FERIADOS */
select @w_ciudad = pa_int
from cobis..cl_parametro
where pa_nemonico = 'CIUN'
and   pa_producto = 'ADM'

/*CODIGO ACTIVIDAD APROBACION SOLICITUDES*/
select @w_codigo_act_apr = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAAPSO'

/* PARAMETRO ACUMULADOS */
select @w_sacumv = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'FSAMIN'
and    pa_producto = 'CCA'

/*CODIGO ACTIVIDAD CUESTIONARIOS*/
select @w_codigo_act_cuest = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAAPCU'

select @w_fecha_fm = '01/01/1900'

/* PARAMETRO GENERAL INTERES */
select @w_rubro_int = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INT'

if @@rowcount = 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'NO EXISTE EL PARAMETRO GENERAL "INT" PARA CARTERA'
   goto ERROR
end

select @w_rubro_cap = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'

if @@rowcount = 0 
begin
   select 
   @w_error = 710076, 
   @w_msg   = 'NO EXISTE EL PARAMETRO GENERAL "CAP" PARA CARTERA'
   goto ERROR
end

/* PARAMETRO GENERAL INTERES */
select @w_rubro_intant = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'INTANT'

if @@rowcount = 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'NO EXISTE EL PARAMETRO GENERAL "INTANT" PARA CARTERA'
   goto ERROR
end

/* PARAMETRO GENERAL IVA INTERES */
select @w_rubro_ivaint = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'RUIVIN'

if @@rowcount = 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'NO EXISTE EL PARAMETRO GENERAL "IVAINT" PARA CARTERA'
   goto ERROR
end

/* PARAMETRO GENERAL INTERES DE MORA */
select @w_rubro_imo = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'IMO'

if @@rowcount = 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'NO EXISTE EL PARAMETRO GENERAL "INTANT" PARA CARTERA'
   goto ERROR
end

/* DETERMINAR SI HOY ES EL ULTIMO HABIL DEL MES */
select @w_sig_habil = dateadd(dd, 1, @w_fecha_proceso)

while exists (select 1
                  from cobis..cl_dias_feriados
                  where df_fecha = @w_sig_habil
                  and   df_ciudad = @w_ciudad)
begin
   select @w_sig_habil = dateadd(dd, 1, @w_sig_habil)
end

if datepart(mm, @w_sig_habil) <> datepart(mm, @w_fecha_proceso)
   select @w_fin_mes = 'S'

/* PARAMETRO GENERAL PARA DIAS DE REESTRUCTURACION */
select @w_dias_gracia_reest = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'DIASGR'
and    pa_producto = 'CRE'

if @w_dias_gracia_reest is null 
   select @w_dias_gracia_reest = 10

/* ESTADOS DE CARTERA */
exec @w_error = cob_cartera..sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_diferido   = @w_est_diferido  out

if @w_error <> 0 goto ERROR

/* CREAR TABLA DE TRABAJO */
CREATE TABLE #operaciones (
	cop_fecha                  DATETIME NOT NULL,
	cop_operacion              INT NOT NULL,
	cop_banco                  VARCHAR (24),
	cop_toperacion             VARCHAR (10),
	cop_aplicativo             TINYINT,
	cop_destino                VARCHAR (10),
	cop_clase                  VARCHAR (30),
	cop_cliente                INT,
	cop_documento_tipo         VARCHAR (30) NULL,
	cop_documento_nume         VARCHAR (30) NULL,
	cop_oficina                INT,
	cop_moneda                 TINYINT,
	cop_monto                  MONEY,
	cop_tasa                   FLOAT,
	cop_modalidad              CHAR (1),
	cop_tplazo                 VARCHAR (10),
	cop_plazo_dias             INT,
	cop_fecha_liq              DATETIME,
	cop_fecha_fin              DATETIME,
	cop_edad_mora              INT,
	cop_reestructuracion       CHAR (1),
	cop_fecha_reest            DATETIME NULL,
	cop_natur_reest            VARCHAR (30) NULL,
	cop_num_reest              TINYINT,
	cop_num_renovacion         INT,
	cop_estado                 TINYINT,
	cop_cupo_credito           VARCHAR (30) NULL,
	cop_num_cuotas             SMALLINT,
	cop_per_cuotas             SMALLINT,
	cop_val_cuota              MONEY,
	cop_cuotas_pag             SMALLINT,
	cop_cuotas_ven             SMALLINT,
	cop_saldo_ven              MONEY,
	cop_fecha_prox_vto         DATETIME,
	cop_fecha_ult_pago         DATETIME NULL,
	cop_valor_ult_pago         MONEY,
	cop_fecha_castigo          DATETIME NULL,
	cop_num_acta               VARCHAR (30) NULL,
	cop_clausula               CHAR (1),
	cop_oficial                SMALLINT,
	cop_naturaleza             VARCHAR (1),
	cop_fuente_recurso         VARCHAR (10),
	cop_categoria_producto     VARCHAR (1),
	cop_valor_vencido          MONEY,
	cop_tipo_garantias         VARCHAR (1),
	cop_op_anterior            VARCHAR (24) NULL,
	cop_edad_cod               TINYINT,
	cop_num_cuotas_reest       TINYINT,
	cop_tramite                INT,
	cop_nota_int               TINYINT NULL,
	cop_fecha_ini_mora         DATETIME NULL,
	cop_gracia_mora            SMALLINT NULL,
	cop_estado_cobranza        VARCHAR (10) NULL,
	cop_tasa_mora              FLOAT NULL,
	cop_tasa_com               FLOAT NULL,
	cop_entidad_convenio       VARCHAR (10) NULL,
	cop_fecha_cambio_linea     DATETIME NULL,
	cop_valor_nominal          NUMERIC (2, 2),
	cop_emision                VARCHAR (1),
	cop_sujcred                VARCHAR (10) NULL,
	cop_cap_vencido            MONEY,
	cop_valor_proxima_cuota    MONEY,
	cop_saldo_total_Vencido    MONEY,
	cop_saldo_otr              MONEY,
	cop_saldo_cap_total        MONEY,
	cop_regional               VARCHAR (30) NULL,
	cop_edad_mora_365          INT NULL,
	cop_normalizado            CHAR (30) NULL,
	cop_tipo_norm              TINYINT NULL,
	cop_frec_pagos_cap         INT NULL,
	cop_frec_pagos_int         INT NULL,
	cop_fec_pri_amort_cubierta INT NULL,
	cop_monto_condo            INT NULL,
	cop_fecha_condo            INT NULL, 
	cop_monto_castigo          INT NULL,
	cop_inte_castigo           INT NULL,
	cop_monto_bonifica         INT NULL,
	cop_inte_refina            INT NULL,
	cop_emproblemado           CHAR (30) NULL,
	cop_mod_pago               INT NULL,
	cop_sector                 VARCHAR (10),
	cop_subtipo_linea          VARCHAR (10),
	cop_cociente_pago          FLOAT,
	cop_numero_ciclos          INT NULL	,
	cop_grupo                  INT NULL,
	cop_numero_integrantes     INT NULL,
	cop_valor_cat              FLOAT,
	cop_gar_liq_orig           MONEY NULL,
	cop_gar_liq_fpago          DATETIME NULL,
	cop_gar_liq_dev            MONEY NULL,
	cop_gar_liq_fdev           DATETIME NULL,
	cop_cuota_capital          MONEY NULL,
	cop_cuota_int              MONEY NULL,
	cop_cuota_iva              MONEY NULL,
	cop_fecha_suspenso         DATETIME NULL,
	cop_cuenta                 VARCHAR (24) NULL,
	cop_tdividendo             VARCHAR (10) NULL,
	cop_vencimiento_div        INT NULL,
	cop_plazo                  VARCHAR (64) NULL,
	cop_subtipo_producto       VARCHAR (64) NULL,
	cop_atraso_grupal          INT NULL,
	cop_fecha_dividendo_ven    DATETIME NULL,
	cop_fecha_apr_tramite      DATETIME NULL,
	cop_cuota_min_vencida      MONEY NULL,
	cop_fecha_proceso          DATETIME NULL,
	cop_subproducto_cuenta     VARCHAR (10) NULL,
	cop_cuota_max_vencida      MONEY NULL,
	cop_atraso_gr_ant          INT NULL ,
	cop_ciclo_actual           INT NULL,
	cop_calificacion_cli       VARCHAR (10) NULL)

/* CARGA DE OPERACIONES ACTIVAS */
/* PROCESA UNA OPERACION */
if @i_banco is not null 
begin
   if @i_debug = 'S' print 'a.sp_consolidador_cca ' + @i_banco
   if @i_debug = 'S' exec cob_cartera..sp_reloj @i_hilo = 1, @i_banco = @i_banco, @i_posicion = 'a.sp_consolidador_cca'

   /* INICIALIZAR VARIABLES DE LA OPERACION */
   select @w_operacionca     = op_operacion,
          @w_cliente         = op_cliente,
          @w_op_estado       = op_estado,
          @w_op_numero_reest = op_numero_reest
   from   cob_cartera..ca_operacion
   where  op_banco = @i_banco

   /* VERIFICAR SI DEBE BORRAR INFORMACION DE LA OPERACION */
   if exists (select 1 
              from   cob_externos..ex_dato_operacion 
              where  do_fecha      = @w_fecha_proceso
              and    do_aplicativo = 7
              and    do_banco      = @i_banco)
   begin           
      /* BORRAR TODA LA INFORMACION GENERADA POR CARTERA EN COB_EXTERNOS */
      delete cob_externos..ex_dato_operacion
      where  do_fecha      = @w_fecha_proceso
      and    do_aplicativo = 7
      and    do_banco      = @i_banco

      delete cob_externos..ex_dato_transaccion
      where  dt_fecha      = @w_fecha_proceso
      and    dt_aplicativo = 7
      and    dt_banco      = @i_banco

      delete cob_externos..ex_dato_transaccion_det
      where  dd_fecha      = @w_fecha_proceso
      and    dd_aplicativo = 7
      and    dd_banco      = @i_banco
  
      delete cob_externos..ex_dato_operacion_rubro
      where  dr_fecha      = @w_fecha_proceso
      and    dr_aplicativo = 7
      and    dr_banco      = @i_banco
  
      delete cob_externos..ex_dato_deudores
      where  de_fecha      = @w_fecha_proceso
      and    de_aplicativo = 7
      and    de_banco      = @i_banco
   
      delete cob_externos..ex_dato_cuota_pry
      where  dc_fecha      = @w_fecha_proceso
      and    dc_aplicativo = 7
      and    dc_banco      = @i_banco
   
      delete cob_externos..ex_dato_condonacion
      where  dc_fecha      = @w_fecha_proceso
      and    dc_aplicativo = 7
      and    dc_banco      = @i_banco
   end

   /* DATOS DE LA OPERACION */
   insert into #operaciones
   select    
   cop_fecha                 =  @w_fecha_proceso,
   cop_operacion             =  op_operacion,   
   cop_banco                 =  convert(varchar(24),op_banco),             
   cop_toperacion            =  convert(varchar(10),op_toperacion),  
   cop_aplicativo            =  convert(tinyint,7),           
   cop_destino               =  convert(varchar(10),op_destino),                   
   cop_clase                 =  convert(varchar,op_clase),                    
   cop_cliente               =  op_cliente,  
   cop_documento_tipo        =  convert(varchar,null),
   cop_documento_nume        =  convert(varchar,null),              
   cop_oficina               =  convert(int,op_oficina),                
   cop_moneda                =  op_moneda,                  
   cop_monto                 =  op_monto,  
   cop_tasa                  =  convert(float,0),
   cop_modalidad             =  convert(char(1),'V'),
   cop_tplazo                =  op_tplazo,
   cop_plazo_dias            =  convert(int,op_plazo * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = op_tplazo)),
   cop_fecha_liq             =  op_fecha_liq,               
   cop_fecha_fin             =  op_fecha_fin,  
   cop_edad_mora             =  0,             
   cop_reestructuracion      =  convert(char(1),case when isnull(op_numero_reest,0) > 0 then 'S'          else 'N'  end), 
   cop_fecha_reest           =  case when isnull(op_numero_reest,0) > 0 then op_fecha_ini else null end,
   cop_natur_reest           =  convert(varchar,null),
   cop_num_reest             =  convert(tinyint,isnull(op_numero_reest,0)), 
   cop_num_renovacion        =  convert(int,isnull(op_num_renovacion,0)),
   cop_estado                =  op_estado, --case op_estado when 3 then 4 when 4 then 3 else 1 end,   
   cop_cupo_credito          =  convert(varchar,op_lin_credito),
   cop_num_cuotas            =  op_plazo,
   cop_per_cuotas            =  op_periodo_int * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = op_tdividendo),
   cop_val_cuota             =  op_cuota,
   cop_cuotas_pag            =  convert(smallint,0),
   cop_cuotas_ven            =  convert(smallint,0),
   cop_saldo_ven             =  convert(money,0),
   cop_fecha_prox_vto        =  op_fecha_fin,
   cop_fecha_ult_pago        =  convert(datetime,null),
   cop_valor_ult_pago        =  convert(money,0),
   cop_fecha_castigo         =  convert(datetime,case when op_estado = @w_est_castigado then '10/14/2008' else null end),
   cop_num_acta              =  convert(varchar,null),
   cop_clausula              =  isnull(op_clausula_aplicada,'N'),
   cop_oficial               =  op_oficial,
   cop_naturaleza            =  case when op_naturaleza = 'A' and op_tipo <> 'G' then '1' 
                                     when op_naturaleza = 'A' and op_tipo =  'G' then '3'
                                     else '2'
                                end,
   cop_fuente_recurso        = op_origen_fondos,
   cop_categoria_producto    =  '1',
   cop_valor_vencido         =  convert(money, 0),
   cop_tipo_garantias        =  case when isnull(op_gar_admisible,'N') = 'N' then 'O' else 'E' end,
   cop_op_anterior           =  op_anterior,
   cop_edad_cod              =  convert(tinyint, 0),
   cop_num_cuotas_reest      =  convert(tinyint, 0),
   cop_tramite               =  op_tramite,
   /* INI - GAL 01/AGO/2010 - OMC */
   cop_nota_int              =  convert(tinyint, null),
   cop_fecha_ini_mora        =  convert(datetime, null),
   cop_gracia_mora           =  convert(smallint, null),
   cop_estado_cobranza       =  op_estado_cobranza,
   cop_tasa_mora             =  convert(float, null),
   cop_tasa_com              =  convert(float, null),
   /* FIN - GAL 01/AGO/2010 - OMC */
   cop_entidad_convenio      = op_entidad_convenio,
   cop_fecha_cambio_linea    = null,
   cop_valor_nominal         = 0.00,
   cop_emision               = ' ',
   cop_sujcred               = (select tr_sujcred 
                                from   cob_credito..cr_tramite
                                where  tr_numero_op = op_operacion 
                                and    tr_tramite = (select max(tr_tramite) 
                                                     from   cob_credito..cr_tramite
                                                     where  tr_numero_op = op_operacion) 
                                and    tr_fecha_apr is not null ),
   cop_cap_vencido           = convert(money, 0),
   /*Req 378 12/08/2013*/
   cop_valor_proxima_cuota   = convert(money,0),
   cop_saldo_total_Vencido   = convert(money,0),
   cop_saldo_otr             = convert(money,0),
   cop_saldo_cap_total       = convert(money,0),
   cop_regional              = convert(varchar,null),
   cop_edad_mora_365         = convert(int,0), --OMOG Req. 472. 03/DIC/2014
   cop_normalizado           = convert(char,null),
   cop_tipo_norm             = convert(tinyint,null),
   cop_frec_pagos_cap        = 0,
   cop_frec_pagos_int        = 0,
   cop_fec_pri_amort_cubierta= null,
   cop_monto_condo           = null,
   cop_fecha_condo           = null,
   cop_monto_castigo         = null,
   cop_inte_castigo          = null,
   cop_monto_bonifica        = null,
   cop_inte_refina           = null,
   cop_emproblemado          = convert(char,null),
   cop_mod_pago              = null,
   cop_sector                = op_sector,
   cop_subtipo_linea         = op_subtipo_linea,
   cop_cociente_pago         = convert(float, 1),
   cop_numero_ciclos         = convert(int, null),
   cop_grupo                 = convert(int, null),
   cop_numero_integrantes    = convert(int, null),
   -- LGU-2018-01-25
   /* CAMPOS NUEVOS PARA EL ESTADO DE CUENTA */
   cop_valor_cat             = op_valor_cat,
   cop_gar_liq_orig          = convert(money, null),
   cop_gar_liq_fpago         = convert(datetime, null),
   cop_gar_liq_dev           = convert(money, null),
   cop_gar_liq_fdev          = convert(datetime, null),
   cop_cuota_capital         = convert(money, null),
   cop_cuota_int             = convert(money, null),
   cop_cuota_iva             = convert(money, null),
   cop_fecha_suspenso        = op_fecha_suspenso,
   cop_cuenta                = op_cuenta,
   cop_tdividendo            = op_tdividendo,
   cop_vencimiento_div       = convert(int, 0),
   cop_plazo                 = convert(varchar(64),''),
   cop_subtipo_producto      = convert(varchar(64),''),
   cop_atraso_grupal         = convert(int, 0),
   cop_fecha_dividendo_ven   = convert(datetime, null),
   cop_fecha_apr_tramite     = op_fecha_ini,
   cop_cuota_min_vencida     = convert(money, null),   
   cop_fecha_proceso         = op_fecha_ult_proceso,
   cop_subproducto_cuenta    = convert(varchar(10) ,null),
   cop_cuota_max_vencida     = convert(money         ,null),
   cop_atraso_gr_ant         = convert(int         ,0),
   cop_ciclo_actual          = convert(int         ,0),
   cop_calificacion_cli      = null
   from   cob_cartera..ca_operacion
   where  op_banco = @i_banco 
end   
else
begin
   if @i_debug = 'S' print 'b.sp_consolidador_cca ' + @i_banco
   if @i_debug = 'S' exec cob_cartera..sp_reloj @i_hilo = 1, @i_banco = @i_banco, @i_posicion = 'b.sp_consolidador_cca'
   
   /* BORRA DATOS DE TABLAS SIN OPERACION */
   delete cob_externos..ex_traslado_ctas_ca_ah
   where  tc_fecha_corte = @w_fecha_proceso
   
  --GFP 07/07/22 Se borran registros para reproceso
   if(@i_param5 = 'S')
   begin
      delete cob_externos..ex_dato_operacion
      where  do_fecha      = @w_fecha_proceso
      and    do_aplicativo = 7

      delete cob_externos..ex_dato_transaccion
      where  dt_fecha      = @w_fecha_proceso
      and    dt_aplicativo = 7

      delete cob_externos..ex_dato_transaccion_det
      where  dd_fecha      = @w_fecha_proceso
      and    dd_aplicativo = 7
  
      delete cob_externos..ex_dato_operacion_rubro
      where  dr_fecha      = @w_fecha_proceso
      and    dr_aplicativo = 7
  
      delete cob_externos..ex_dato_deudores
      where  de_fecha      = @w_fecha_proceso
      and    de_aplicativo = 7
   
      delete cob_externos..ex_dato_cuota_pry
      where  dc_fecha      = @w_fecha_proceso
      and    dc_aplicativo = 7
   
      delete cob_externos..ex_dato_condonacion
      where  dc_fecha      = @w_fecha_proceso
      and    dc_aplicativo = 7
   end

   /* BUSCA TODAS LAS OPERACIONES YA REGISTRADAS */
   select do_operacion
   into   #operaciones_existentes
   from   cob_externos..ex_dato_operacion
   where  do_fecha      = @w_fecha_proceso
   and    do_aplicativo = 7

   /* DETERMINA LAS OPERACIONES NO REGISTRADAS */
   select operacion = op_operacion
   into   #operaciones_noregistradas
   from   cob_cartera..ca_operacion, cob_cartera..ca_estado
   where  op_estado         = es_codigo
   and    es_procesa        = 'S' 
   and    op_operacion not in (select do_operacion from #operaciones_existentes)
   
   /* CARGA TODAS LAS OPERACIONES NO REGISTRADAS Y CANCELADAS */
   insert into #operaciones
   select    
   cop_fecha                 =  @w_fecha_proceso,
   cop_operacion             =  op_operacion,   
   cop_banco                 =  convert(varchar(24),op_banco),             
   cop_toperacion            =  convert(varchar(10),op_toperacion),  
   cop_aplicativo            =  convert(tinyint,7),           
   cop_destino               =  convert(varchar(10),op_destino),                   
   cop_clase                 =  convert(varchar,op_clase),                    
   cop_cliente               =  op_cliente,  
   cop_documento_tipo        =  convert(varchar,null),
   cop_documento_nume        =  convert(varchar,null),              
   cop_oficina               =  convert(int,op_oficina),                
   cop_moneda                =  op_moneda,                  
   cop_monto                 =  op_monto,  
   cop_tasa                  =  convert(float,0),
   cop_modalidad             =  convert(char(1),'V'),
   cop_tplazo                =  op_tplazo,
   cop_plazo_dias            =  convert(int,op_plazo * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = op_tplazo)),
   cop_fecha_liq             =  op_fecha_liq,               
   cop_fecha_fin             =  op_fecha_fin,  
   cop_edad_mora             =  0,             
   cop_reestructuracion      =  convert(char(1),case when isnull(op_numero_reest,0) > 0 then 'S' else 'N'  end), 
   cop_fecha_reest           =  case when isnull(op_numero_reest,0) > 0 then op_fecha_ini else null end,
   cop_natur_reest           =  convert(varchar,null),
   cop_num_reest             =  convert(tinyint,isnull(op_numero_reest,0)), 
   cop_num_renovacion        =  convert(int,isnull(op_num_renovacion,0)),
   cop_estado                =  op_estado, --case op_estado when 3 then 4 when 4 then 3 else 1 end,   
   cop_cupo_credito          =  convert(varchar,op_lin_credito),
   cop_num_cuotas            =  op_plazo,
   cop_per_cuotas            =  op_periodo_int * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = op_tdividendo),
   cop_val_cuota             =  op_cuota,
   cop_cuotas_pag            =  convert(smallint,0),
   cop_cuotas_ven            =  convert(smallint,0),
   cop_saldo_ven             =  convert(money,0),
   cop_fecha_prox_vto        =  op_fecha_fin,
   cop_fecha_ult_pago        =  convert(datetime,null),
   cop_valor_ult_pago        =  convert(money,0),
   cop_fecha_castigo         =  convert(datetime,case when op_estado = @w_est_castigado then '10/14/2008' else null end),
   cop_num_acta              =  convert(varchar,null),
   cop_clausula              =  isnull(op_clausula_aplicada,'N'),
   cop_oficial               =  op_oficial,
   cop_naturaleza            =  case when op_naturaleza = 'A' and op_tipo <> 'G' then '1' 
                                     when op_naturaleza = 'A' and op_tipo =  'G' then '3'
                                     else '2'
                                end,
   cop_fuente_recurso        = op_origen_fondos,
   cop_categoria_producto    =  '1',
   cop_valor_vencido         =  convert(money, 0),
   cop_tipo_garantias        =  case when isnull(op_gar_admisible,'N') = 'N' then 'O' else 'E' end,
   cop_op_anterior           =  op_anterior,
   cop_edad_cod              =  convert(tinyint, 0),
   cop_num_cuotas_reest      =  convert(tinyint, 0),
   cop_tramite               =  op_tramite,
   /* INI - GAL 01/AGO/2010 - OMC */
   cop_nota_int              =  convert(tinyint, null),
   cop_fecha_ini_mora        =  convert(datetime, null),
   cop_gracia_mora           =  convert(smallint, null),
   cop_estado_cobranza       =  op_estado_cobranza,
   cop_tasa_mora             =  convert(float, null),
   cop_tasa_com              =  convert(float, null),
   /* FIN - GAL 01/AGO/2010 - OMC */
   cop_entidad_convenio      = op_entidad_convenio,
   cop_fecha_cambio_linea    = null,
   cop_valor_nominal         = 0.00,
   cop_emision               = ' ',
   cop_sujcred               = (select tr_sujcred 
                                from   cob_credito..cr_tramite
                                where  tr_numero_op = op_operacion 
                                and    tr_tramite = (select max(tr_tramite) 
                                                     from   cob_credito..cr_tramite
                                                     where  tr_numero_op = op_operacion) 
                                and    tr_fecha_apr is not null ),
   cop_cap_vencido           = convert(money, 0),
   /*Req 378 12/08/2013*/
   cop_valor_proxima_cuota   = convert(money,0),
   cop_saldo_total_Vencido   = convert(money,0),
   cop_saldo_otr             = convert(money,0),
   cop_saldo_cap_total       = convert(money,0),
   cop_regional              = convert(varchar,null),
   cop_edad_mora_365         = convert(int,0), --OMOG Req. 472. 03/DIC/2014
   cop_normalizado           = convert(char,null),
   cop_tipo_norm             = convert(tinyint,null),
   cop_frec_pagos_cap        = 0,
   cop_frec_pagos_int        = 0,
   cop_fec_pri_amort_cubierta= null,
   cop_monto_condo           = null,
   cop_fecha_condo           = null,
   cop_monto_castigo         = null,
   cop_inte_castigo          = null,
   cop_monto_bonifica        = null,
   cop_inte_refina           = null,
   cop_emproblemado          = convert(char,null),
   cop_mod_pago              = null,
   cop_sector                = op_sector,
   cop_subtipo_linea         = op_subtipo_linea,
   cop_cociente_pago         = convert(float, 1),
   cop_numero_ciclos         = convert(int, null),
   cop_grupo                 = convert(int, null),
   cop_numero_integrantes    = convert(int, null),
   -- LGU-2018-01-25
   /* CAMPOS NUEVOS PARA EL ESTADO DE CUENTA */
   cop_valor_cat             = op_valor_cat,
   cop_gar_liq_orig          = convert(money, null),
   cop_gar_liq_fpago         = convert(datetime, null),
   cop_gar_liq_dev           = convert(money, null),
   cop_gar_liq_fdev          = convert(datetime, null),
   cop_cuota_capital         = convert(money, null),
   cop_cuota_int             = convert(money, null),
   cop_cuota_iva             = convert(money, null),
   cop_fecha_suspenso        = op_fecha_suspenso,
   cop_cuenta                = op_cuenta,
   cop_tdividendo            = op_tdividendo,
   cop_vencimiento_div       = convert(int, 0),
   cop_plazo                 = convert(varchar(64),''),
   cop_subtipo_producto      = convert(varchar(64),''),
   cop_atraso_grupal         = convert(int, 0),
   cop_fecha_dividendo_ven   = convert(datetime, null),
   cop_fecha_apr_tramite     = op_fecha_ini,
   cop_cuota_min_vencida     = convert(money, null),   
   cop_fecha_proceso         = op_fecha_ult_proceso,
   cop_subproducto_cuenta    = convert(varchar(10) ,null),
   cop_cuota_max_vencida     = convert(money         ,null),
   cop_atraso_gr_ant         = convert(int         ,0),
   cop_ciclo_actual          = convert(int         ,0),
   cop_calificacion_cli      = null
   from   cob_cartera..ca_operacion
   where (op_operacion in (select operacion from #operaciones_noregistradas))
   --> OPERACIONES CANCELADAS DURANTE EL MES DE PROCESO
   or    (op_estado    = @w_est_cancelado and op_fecha_ult_proceso between @w_fecha_ini and @w_fecha_proceso)     
   --> OPERACIONES CANCELADAS DURANTE EL MES DE PROCESO CON FECHA VALOR A MESES ANTERIORES)
   or    (op_estado=@w_est_cancelado and op_fecha_ult_proceso < @w_fecha_ini and op_fecha_ult_mov between @w_fecha_ini and @w_fecha_proceso)

   create index idx1 on #operaciones(cop_operacion)
   create index idx2 on #operaciones(cop_banco)

   /* BORRAR OPERACIONES EXISTENTES */
   delete #operaciones 
   from   cob_externos..ex_dato_operacion 
   where  cop_banco     = do_banco
   and    do_fecha      = @w_fecha_proceso
   and    do_aplicativo = 7

   /* NO REPORTA OPERACIONES QUE FUERON CANCELADAS EN MESES ANTERIORES Y QUE VOLVIERON A SER CANCELADAS EN EL MES DE PROCESO POR FECHA VALOR */
   select op_banco,  op_fecha_ult_mov, op_fecha_ult_proceso 
   into   #canceladas
   from   #operaciones, cob_cartera..ca_operacion
   where  cop_estado             = @w_est_cancelado
   and    cop_banco              = op_banco
   and    op_fecha_ult_proceso   < @w_fecha_ini 
   and    op_fecha_ult_mov between @w_fecha_ini and @w_fecha_proceso

   delete #operaciones
   from   cob_conta_super..sb_dato_operacion, #canceladas
   where  do_banco          = op_banco
   and    do_fecha          = op_fecha_ult_proceso 
   and    cop_banco         = op_banco
   and    do_estado_cartera = @w_est_cancelado
end   

---25045
if exists (select 1 from cob_cartera..ca_diferidos)
begin
   select cop_banco, concepto = dif_concepto, 'valDiff' =sum(dif_valor_total - dif_valor_pagado ), adicionar='S'
   into   #diferidos
   from   #operaciones, cob_cartera..ca_diferidos
   where  cop_operacion = dif_operacion
   group by cop_banco, dif_concepto
end
   
---25045
update #operaciones
set   cop_vencimiento_div = 1
from  cob_cartera..ca_dividendo
where cop_operacion = di_operacion
and   di_fecha_ven = @w_fecha_proceso

update #operaciones
set   cop_plazo    = td_descripcion
from  cob_cartera..ca_operacion,
      cob_cartera..ca_tdividendo
where cop_operacion = op_operacion       
and   td_tdividendo = op_tdividendo

/* ELIINAR LAS GRUPALES PADRES */
-- LGU-2018-02-20
if exists (select 1 from cob_credito..cr_tramite_grupal)
begin
   select DISTINCT tg_referencia_grupal
   INTO   #grupales_padre
   FROM   #operaciones, cob_credito..cr_tramite_grupal, cob_cartera..ca_operacion
   WHERE  cop_estado            = @w_est_cancelado
   and    cop_banco             = op_banco
   and    op_fecha_ult_proceso <= @w_fecha_proceso 
   and    cop_banco             = tg_referencia_grupal
   
   delete #operaciones
   FROM   #grupales_padre
   where  cop_banco = tg_referencia_grupal

   /* ACTUALIZAR VALOR Y FECHA DE PAGO DE LA GARANTIA LIQUIDA */
   -- LGU-2018-01-25
   UPDATE #operaciones SET
   cop_gar_liq_orig   = gl_monto_garantia,
   cop_gar_liq_fpago  = gl_pag_fecha,
   cop_gar_liq_dev    = gl_dev_valor,
   cop_gar_liq_fdev   = gl_dev_fecha
   FROM   cob_cartera..ca_garantia_liquida, cob_credito..cr_tramite_grupal
   WHERE  gl_grupo          = tg_grupo
   AND    gl_cliente        = tg_cliente
   AND    gl_tramite        = tg_tramite
   AND    gl_monto_garantia > 0
   AND    tg_monto          > 0
   AND    cop_banco         = tg_prestamo
end   
--///////////////////////////

/* DETERMINAR LA TASA DE LA OPERACION */
update #operaciones set
cop_tasa      = ro_porcentaje_efa,
cop_modalidad = case ro_fpago when 'P' then 'V' else 'A' end
from cob_cartera..ca_rubro_op
where ro_operacion = cop_operacion
and   ro_concepto  = @w_rubro_int
and   ro_fpago in ('A', 'P')

/* DETERMINAR OPERACIONES REESTRUCTURADAS */
if @w_op_numero_reest > 0 or @i_banco is NULL
begin
   /* DETERMINAR LA FECHA DE REESTRUCTURACION */
   select tr_operacion, tr_fecha_ref=max(tr_fecha_ref)
   into   #reest
   from   cob_cartera..ca_transaccion, #operaciones
   where  tr_operacion = cop_operacion
   and    tr_tran     in ('RES', 'PNO')
   and    tr_estado   <> 'RV'
   group by tr_operacion

   update #operaciones set
   cop_reestructuracion =  'S', 
   cop_fecha_reest      =  tr_fecha_ref
   from   #reest
   where  tr_operacion = cop_operacion
   
   /* PARA OPERACIONES REESTRUCTURADAS, DETERMINAR EL MOTIVO DE LA REESTRUCTURACION */
   update #operaciones set
   cop_natur_reest =  tr_motivo
   from   cob_credito..cr_tramite
   where  tr_numero_op         = cop_operacion
   and    tr_tipo              = 'E'
   and    cop_reestructuracion = 'S'
end   

/* PARA OPERACIONES NORMALIZADAS, DETERMINAR EL TIPO DE HERRAMIENTA */
/* OTROS TIPOS DE NORMALIZACION */
if exists (select 1 from cob_cartera..ca_normalizacion)
begin
   update #operaciones set
   cop_normalizado =  'S',
   cop_tipo_norm   = b.nm_tipo_norm
   from cob_cartera..ca_normalizacion a, cob_credito..cr_normalizacion b
   where a.nm_tramite   = b.nm_tramite
   and   b.nm_operacion = cop_banco
end   

/* DETERMINAR LA FECHA DEL PROXIMO VENCIMIENTO */
update #operaciones set
cop_fecha_prox_vto =  di_fecha_ven
from cob_cartera..ca_dividendo
where di_operacion = cop_operacion
and   di_estado    = @w_est_vigente

/* DETERMINAR VALORES DE CUOTAS */
select 
co_banco         = cop_banco,
co_cuota_capital = sum(case when am_concepto  = @w_rubro_cap then isnull(am_cuota,0)  else 0 end),
co_cuota_int     = sum(case when am_concepto in (@w_rubro_int, @w_rubro_intant) then isnull(am_cuota+am_gracia,0)  else 0 end),
co_cuota_iva     = sum(case when am_concepto  = @w_rubro_ivaint then isnull(am_cuota+am_gracia,0)  else 0 end)   
into   #cuota
from   cob_cartera..ca_dividendo d, cob_cartera..ca_amortizacion a, #operaciones o
where  cop_operacion = di_operacion
and    di_operacion  = am_operacion
and    am_operacion  = cop_operacion
and    am_dividendo  = di_dividendo
and    di_fecha_ven  = cop_fecha_prox_vto 
group by cop_banco, cop_operacion, cop_toperacion

/* ACTUALIZAR VALORES DE CUOTAS */
update #operaciones
SET    cop_cuota_capital = co_cuota_capital,
       cop_cuota_int     = co_cuota_int    ,
       cop_cuota_iva     = co_cuota_iva    
FROM   #cuota
where  cop_banco  = co_banco

/**********************************************************/
/* Actualizacion SubProducto                              */
/**********************************************************/
/* --GFP 03/09/2021 Deshabilitación temporal hasta su uso
if exists (select 1 FROM cobis..cl_producto_santander)
begin
   update #operaciones
   set    cop_subproducto_cuenta = pr_codigo_subproducto
   from   cobis..cl_producto_santander
   where  cop_cliente   = pr_ente
end
*/ --GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso

/* DETERMINAR MONTO NO PROYECTADO DEL PROXIMO VENCIMIENTO */ --Req 378 12/08/2013
update #operaciones
set    cop_valor_proxima_cuota = isnull((select SUM(am_cuota+am_gracia) 
                                         from   cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                         where  am_operacion = di_operacion
                                         and    am_dividendo = di_dividendo
                                         and    di_estado    = @w_est_vigente
                                         and    am_operacion = cop_operacion),0)

update #operaciones
set    cop_cuota_min_vencida = isnull((select SUM(am_cuota+am_gracia) 
                                       from   cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                       where  am_operacion = di_operacion
                                       and    am_dividendo = di_dividendo
                                       and    di_estado    = @w_est_vencido
                                       and    am_operacion = cop_operacion
                                       and    di_dividendo = (select max(di_dividendo)
                                                              from   cob_cartera..ca_dividendo
                                                              where  di_estado   = @w_est_vencido
                                                              and    di_operacion= cop_operacion)),0)

update #operaciones
set    cop_cuota_max_vencida = isnull((select SUM(am_cuota+am_gracia) 
                                       from   cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo
                                       where  am_operacion = di_operacion
                                       and    am_dividendo = di_dividendo
                                       and    di_estado    = @w_est_vencido
                                       and    am_operacion = cop_operacion
                                       and    di_dividendo = (select min(di_dividendo)
                                                              from cob_cartera..ca_dividendo
                                                              where  di_estado   = @w_est_vencido
                                                              and    di_operacion= cop_operacion)),0)
								   
/* DETERMINAR LA CANTIDAD DE CUOTAS VENCIDAS Y CANCELADAS */ 
select 
operacion  = di_operacion,
vencidas   = sum(case when di_estado = @w_est_vencido   then 1 else 0 end),
canceladas = sum(case when di_estado = @w_est_cancelado then 1 else 0 end)
into   #resumen_cuotas
from   cob_cartera..ca_dividendo 
where  di_estado in (@w_est_vencido, @w_est_cancelado)
group by di_operacion
  
update #operaciones set
cop_cuotas_pag =  canceladas,
cop_cuotas_ven =  vencidas
from   #resumen_cuotas
where  cop_operacion = operacion

/* DETERMINAR SI EL CLIENTE ESTA EMPROBLEMADO */ 
--GFP actualizacion de campo de calificacion a cliente
update #operaciones 
set    cop_emproblemado  = en_emproblemado,
       cop_calificacion_cli  = en_calificacion
from   cobis..cl_ente
where  cop_cliente = en_ente

/* DETERMINAR EL SALDO VENCIDO */
select 
operacion = am_operacion,
saldo_ven = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado))) / 2
into   #saldo_ven
from   cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo 
where  am_operacion = di_operacion
and    am_dividendo = di_dividendo
and    di_estado   in (@w_est_vencido, @w_est_vigente)
group by am_operacion
    
update #operaciones 
set    cop_saldo_ven = saldo_ven
FROM   #saldo_ven
where  cop_operacion = operacion

/* DETERMINAR EL COCIENTE PAGO */
select 
operacion  = cop_operacion, 
dividendo  = di_dividendo, 
dividendo2 = di_dividendo, 
per_cuota  = cop_per_cuotas, 
pagado     = sum(am_pagado),
cuota      = sum(am_cuota+am_gracia), 
promedio   = case when sum(am_cuota+am_gracia) > 0 then sum(am_pagado)/sum(am_cuota+am_gracia) else 0 end
into  #promedios
from  #operaciones, cob_cartera..ca_dividendo, cob_cartera..ca_amortizacion
where cop_operacion = am_operacion
and   cop_operacion = di_operacion
and   di_dividendo  = am_dividendo
and   (di_estado   in (@w_est_vencido, @w_est_cancelado) or 
                      (di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proceso))
group by cop_operacion, di_dividendo, cop_per_cuotas
order by cop_operacion, di_dividendo

select 
max_operacion = cop_operacion, 
max_dividendo = max(di_dividendo)
into  #maximos
from  #operaciones , cob_cartera..ca_dividendo
where cop_operacion = di_operacion
and   (di_estado   in (@w_est_vencido, @w_est_cancelado) or 
                      (di_estado = @w_est_vigente and di_fecha_ven = @w_fecha_proceso))
group by cop_operacion

update #promedios 
set    dividendo = max_dividendo - dividendo + 1
from   #maximos
where  operacion = max_operacion
/* --GFP 03/09/2021 Deshabilitación temporal hasta su uso
select operacion, cociente = avg(promedio) 
into   #cociente_pago
from   #promedios, cob_conta_super..sb_cuota_p_pago
where  per_cuota  = pp_periodo_cuota
and    dividendo <= pp_cuotas
group by operacion

update #operaciones 
set    cop_cociente_pago = cociente
from   #cociente_pago
where  operacion = cop_operacion 
*/ --GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso

/* DETERMINAR NUMERO DE CICLOS */
if exists (select 1 from cob_credito..cr_tramite_grupal)
begin
   select 
   operacion     = cop_operacion,
   grupo         = dc_grupo,
   numero_ciclos = isnull(max(dc_ciclo_grupo),0)
   into   #ciclos
   from   #operaciones, cob_cartera..ca_det_ciclo
   where  dc_cliente     = cop_cliente 
   and    dc_operacion   = cop_operacion
   group by cop_operacion, dc_grupo

   update #operaciones set
   cop_grupo         = grupo,
   cop_numero_ciclos = numero_ciclos
   from   #ciclos
   where  cop_operacion = operacion

   update #operaciones 
   set    cop_ciclo_actual = gr_num_ciclo
   from   cobis..cl_grupo 
   where  cop_grupo = gr_grupo

   /* DETERMINAR NUMERO DE INTEGRANTES */
   update #operaciones set
   cop_numero_integrantes = (select isnull(count(dc_grupo),0)
                             from cob_cartera..ca_det_ciclo
                             where dc_grupo       = cop_grupo
                             and   dc_ciclo_grupo = cop_numero_ciclos)

   /* ATRASO GRUPAL */
   select
   banco      = cop_banco,
   max_atraso = max(datediff(dd, di_fecha_ven, case when di_estado = @w_est_cancelado then di_fecha_can else @w_fecha_proceso end))
   into    #max_atraso
   from    #operaciones, cob_cartera..ca_dividendo
   where   di_operacion = cop_operacion
   and     di_fecha_ven < @w_fecha_proceso
   group by cop_banco

   update #operaciones set 
   cop_atraso_grupal = max_atraso,
   cop_atraso_gr_ant = max_atraso
   from   #max_atraso
   where  cop_banco = banco
end   

/* SALDOS ACUMULADOS DE LA CUOTA MAS VENCIDA */  --Req 378 12/08/2013
if (@i_banco is null and exists (select 1 from cob_cartera..ca_rubro_op where ro_concepto = @w_sacumv))
or (@i_banco is not null and exists (select 1 from cob_cartera..ca_rubro_op WHERE ro_operacion = @w_operacionca and ro_concepto = @w_sacumv))
begin
   select 
   operacion_tot = am_operacion,
   dividendo_tot = am_dividendo,
   saldo_ven_tot = (sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado))) / 2
   into   #saldo_menor_ven
   from   cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo , #operaciones
   where  am_operacion  = di_operacion
   and    cop_operacion = di_operacion
   and    am_dividendo  = di_dividendo
   and    di_estado     = @w_est_vencido
   and    am_concepto   = @w_sacumv
   group by am_operacion, am_dividendo

   delete #saldo_menor_ven   
   where  saldo_ven_tot <= 0

   select 
   operacion_div = operacion_tot,
   dividendo_div = min(dividendo_tot)
   into   #saldo_menor_ven_div
   from   #saldo_menor_ven
   group by operacion_tot  

   update #operaciones set
   cop_saldo_otr = saldo_ven_tot 
   from   #saldo_menor_ven, #saldo_menor_ven_div
   where  cop_operacion = operacion_tot
   and    operacion_tot = operacion_div
   and    dividendo_tot = dividendo_div 
end

/* DETERMINAR EL SALDO TOTAL SOLO VENCIDO */ --Req 378 12/08/2013
select 
operacion = am_operacion,
saldo_ven = isnull((sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado))) / 2,0),
fecha_vencimiento = min(di_fecha_ven)
into   #saldo_tot_ven
from   cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo 
where  am_operacion = di_operacion
and    am_dividendo = di_dividendo
and    di_estado    = @w_est_vencido
group by am_operacion
    
update #operaciones set
cop_saldo_total_Vencido = saldo_ven,
cop_fecha_dividendo_ven = fecha_vencimiento,
cop_valor_vencido       = saldo_ven
FROM   #saldo_tot_ven
where  cop_operacion = operacion

/* DETERMINAR EL CAPITAL VENCIDO */
select 
operacion = am_operacion,
cap_mora  = isnull(sum(am_cuota-am_pagado),0)
into   #cap_mora
from   cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo 
where  am_operacion = di_operacion
and    am_dividendo = di_dividendo
and    am_concepto  = @w_rubro_cap
and    di_estado    = @w_est_vencido
group by am_operacion
    
update #operaciones set
cop_cap_vencido = cap_mora
from   #cap_mora
where  cop_operacion = operacion

/* DETERMINAR EL SALDO CAPITAL TOTAL*/ --Req 378 12/08/2013 -
select 
operacion      = am_operacion,
cap_tot        = sum(am_cuota-am_pagado),
cap_num_cuotas = max(di_dividendo)
into   #cap_mora_tot
from   cob_cartera..ca_amortizacion, cob_cartera..ca_dividendo 
where  am_operacion = di_operacion
and    am_dividendo = di_dividendo
and    am_concepto  = @w_rubro_cap
group by am_operacion
    
update #operaciones set
cop_saldo_cap_total = cap_tot,
cop_num_cuotas      = cap_num_cuotas
from   #cap_mora_tot
where  cop_operacion = operacion

/* REGIONAL */ --Req 378 12/08/2013
select 
operacion = cop_operacion,
regional  = of_zona
into   #regional
from   cobis..cl_oficina, #operaciones
where  cop_oficina = of_oficina

update #operaciones
set    cop_regional = of_nombre
from   #regional, cobis..cl_oficina
where  regional  = of_oficina
and    operacion = cop_operacion

/* DETERMINAR LA FECHA DE CASTIGO */
if (@i_banco is not null and @w_op_estado = @w_est_castigado)
or (@i_banco is null)
begin
   update #operaciones set
   cop_fecha_castigo = tr_fecha_ref
   from cob_cartera..ca_transaccion 
   where tr_operacion = cop_operacion
   and   tr_tran      = 'CAS'
   and   tr_estado   <> 'RV'
   and   cop_estado   = @w_est_castigado
end

/* DETERMINAR FECHA Y MONTO DEL ULTIMO PAGO */
if (@i_banco is not null and exists (select 1 from cob_cartera..ca_abono where ab_operacion = @w_operacionca))
or (@i_banco is null)
begin
   select 
   operacion  = ab_operacion, 
   fecha      = max(ab_fecha_pag),
   secuencial = 0
   into   #ult_pago
   from   cob_cartera..ca_abono, #operaciones  
   where  ab_tipo        = 'PAG'
   and    ab_estado not in ('RV', 'E')
   and    ab_operacion   = cop_operacion 
   group by  ab_operacion

   select 
   operacion  = operacion, 
   fecha      = fecha,
   secuencial = max(ab_secuencial_ing)
   into   #ult_pago_2
   from   cob_cartera..ca_abono, #ult_pago
   where  ab_operacion = operacion
   and    ab_fecha_pag = fecha
   group by operacion, fecha

   select 
   operacion = operacion, 
   fecha     = fecha,
   monto     = sum(abd_monto_mop)
   into   #ult_pago_3
   from   cob_cartera..ca_abono_det, #ult_pago_2
   where  abd_operacion      = operacion
   and    abd_secuencial_ing = secuencial
   group by operacion, fecha

   update #operaciones set
   cop_fecha_ult_pago  =  fecha,
   cop_valor_ult_pago  =  monto
   from   #ult_pago_3
   where  cop_operacion = operacion
   and    monto         > 0
end   

/* DIAS DE MORA */
if (@i_banco is not null and exists (select 1 from cob_cartera..ca_dividendo where di_operacion = @w_operacionca and di_estado = @w_est_vencido))
or (@i_banco is null)
begin
   select 
   operacion = di_operacion,
   fecha_ini = min(di_fecha_ven),
   dias_360  = datediff(mm, isnull(min(di_fecha_ven),@w_fecha_proceso), @w_fecha_proceso) * 30 + datediff(dd, dateadd(mm, datediff(mm, isnull(min(di_fecha_ven),@w_fecha_proceso),@w_fecha_proceso), isnull(min(di_fecha_ven),@w_fecha_proceso)),@w_fecha_proceso),
   dias_365  = datediff(dd, isnull(min(di_fecha_ven),@w_fecha_proceso), @w_fecha_proceso) + 1
   into   #dias_mora
   from   cob_cartera..ca_dividendo, #operaciones
   where  di_estado  = @w_est_vencido
   and    di_operacion = cop_operacion
   group by di_operacion

   update #operaciones set
   cop_edad_mora       =  dias_360,
   cop_edad_mora_365   =  dias_365
   from   #dias_mora
   where  cop_operacion = operacion
end   

/* ACTUALIZACION PARA TEMPORALIDAD DIARIA */
update #operaciones set
cop_edad_cod  = ct_codigo 
from   cob_credito..cr_param_cont_temp
where  cop_clase           =  ct_clase
and    cop_edad_mora/30.0  >  case when ct_desde = 0 then -30000 else ct_desde end
and    cop_edad_mora/30.0 <= ct_hasta

if (@i_banco is not null and exists (select 1 from cob_cartera..ca_fecha_reest_control where fr_operacion = @w_operacionca))
or (@i_banco is null)
begin
   select 
   operacion = op_operacion, 
   fecha     = fr_fecha
   into   #op_reest_1
   from   cob_cartera..ca_operacion, cob_cartera..ca_fecha_reest_control
   where  op_operacion = fr_operacion

   select 
   operacion     = di_operacion,
   cuotas_total  = sum(case when di_fecha_ven > fecha and di_fecha_ven <= @w_fecha_proceso and di_fecha_ven > fecha then 1 else 0 end),
   cuotas_can_ok = sum(case when di_estado = 3 and (dateadd(dd,@w_dias_gracia_reest,di_fecha_ven) >= di_fecha_can) and di_fecha_ven > fecha then 1 else 0 end),
   cuotas_ven_ok = sum(case when di_estado = 2 and (dateadd(dd,@w_dias_gracia_reest,di_fecha_ven) >= @w_fecha_proceso) and di_fecha_ven > fecha then 1 else 0 end)
   into   #op_reest_2
   from   #op_reest_1, cob_cartera..ca_dividendo
   where  di_operacion  = operacion
   and    di_fecha_ven  > fecha 
   and    di_fecha_ven <= @w_fecha_proceso
   and    di_estado    <> 0
   group by di_operacion

   select 
   operacion_di = di_operacion,
   fecha_di     = max(dateadd(dd, 1, di_fecha_ven))
   into #op_reest_3
   from #op_reest_1, cob_cartera..ca_dividendo
   where di_operacion  = operacion
   and   di_fecha_ven  >  fecha 
   and   di_fecha_ven <= @w_fecha_proceso
   and   di_estado     = @w_est_vencido
   group by di_operacion

   update #operaciones set
   cop_num_cuotas_reest =  case when cuotas_can_ok + cuotas_ven_ok >= cuotas_total then cuotas_can_ok else 0 end
   from   #op_reest_2
   where  cop_operacion = operacion
end   

-- INI - GAL 27/JUL/2010
update #operaciones set 
cop_nota_int = ci_nota
from   cob_credito..cr_califica_int_mod
where  ci_banco = cop_banco

select 
operacion  = di_operacion,
dividendo  = min(di_dividendo)
into   #min_dividendo
from   cob_cartera..ca_dividendo, #operaciones
where  di_estado   <> @w_est_cancelado
and    di_operacion = cop_operacion
group by di_operacion

select 
operacion = di_operacion,
fecha_ven = di_fecha_ven,
gracia    = di_gracia
into   #min_vto
from   #min_dividendo, cob_cartera..ca_dividendo
where  di_operacion = operacion
and    di_dividendo = dividendo

update #operaciones set 
cop_fecha_ini_mora = fecha_ven,
cop_gracia_mora    = gracia
from  #min_vto
where cop_operacion = operacion

update #operaciones set 
cop_tasa_mora = ro_porcentaje_efa
from cob_cartera..ca_rubro_op
where ro_operacion = cop_operacion
and   ro_concepto  = @w_rubro_imo

update #operaciones set 
cop_tasa_com  = ro_porcentaje
from   cob_cartera..ca_rubro_op
where  ro_operacion = cop_operacion
and    ro_concepto in (@w_rubro_int, @w_rubro_intant)
-- FIN - GAL 27/JUL/2010 

--Actualizacion Fecha de Cambio de Linea (Control de Cambio 224 -Empleados)
update #operaciones set
cop_fecha_cambio_linea = tl_fecha_traslado
from   cob_cartera..ca_traslado_linea
where  tl_operacion = cop_operacion
and    tl_estado    = 'P'
	
/*FRECUENCIA DE PAGO DE CAPITAL*/
select @w_operacion = 0
while (1=1)
begin
   set rowcount 1
    
   select @w_operacion =  cop_operacion 
   from   #operaciones 
   where  cop_operacion > @w_operacion
   order by cop_operacion
	
   if @@rowcount = 0 
   begin
      set rowcount 0
      break
   end

   set rowcount 0	
   
   select @w_div_min_ex = min(di_dividendo) 
   from   cob_cartera..ca_dividendo
   where  di_estado    in (@w_est_novigente, @w_est_vigente, @w_est_vencido)
   and    di_operacion  = @w_operacion
   and    di_de_capital = 'S'

   select @w_fecha_ven_ant = di_fecha_ven
   from   cob_cartera..ca_dividendo
   where  di_operacion  = @w_operacion 
   and     di_dividendo = @w_div_min_ex

   select @w_div_min_sig = min(di_dividendo) 
   from   cob_cartera..ca_dividendo
   where  di_estado    in (@w_est_novigente, @w_est_vigente, @w_est_vencido)
   and    di_operacion  = @w_operacion 
   and    di_dividendo  > @w_div_min_ex 
   and    di_de_capital = 'S'
 
   select @w_fecha_ven_sig = di_fecha_ven
   from   cob_cartera..ca_dividendo
   where  di_operacion = @w_operacion 
   and    di_dividendo = @w_div_min_sig

   select @w_numdias = datediff (dd,@w_fecha_ven_ant,@w_fecha_ven_sig)
	
   update #operaciones set 
   cop_frec_pagos_cap  = isnull(@w_numdias,0)
   where cop_operacion = @w_operacion
end

/*FRECUENCIA DE PAGO DE INTERES */
select @w_operacion = 0
while (1=1)
begin
   set rowcount 1
    
   select @w_operacion =  cop_operacion 
   from   #operaciones 
   where  cop_operacion > @w_operacion
   order by cop_operacion
	
   if @@rowcount = 0 
   begin
      set rowcount 0
      break
   end

   set rowcount 0	
	
   select @w_div_min_ex = min(di_dividendo) 
   from   cob_cartera..ca_dividendo
   where  di_estado    in (@w_est_novigente, @w_est_vigente, @w_est_vencido)
   and    di_operacion  = @w_operacion
   and    di_de_interes = 'S'

   select @w_fecha_ven_ant = di_fecha_ven
   from   cob_cartera..ca_dividendo
   where  di_operacion = @w_operacion 
   and    di_dividendo = @w_div_min_ex

   select @w_div_min_sig = min(di_dividendo) 
   from   cob_cartera..ca_dividendo
   where  di_estado    in (@w_est_novigente, @w_est_vigente, @w_est_vencido)  
   and    di_operacion  = @w_operacion 
   and    di_dividendo  > @w_div_min_ex 
   and    di_de_interes = 'S'
 
   select @w_fecha_ven_sig = di_fecha_ven
   from   cob_cartera..ca_dividendo
   where  di_operacion = @w_operacion 
   and    di_dividendo = @w_div_min_sig

   select @w_numdias = datediff (dd,@w_fecha_ven_ant,@w_fecha_ven_sig)
	
   update #operaciones set 
   cop_frec_pagos_int  = @w_numdias
   where cop_operacion = @w_operacion
end

/*Modalidad de Pago*/
select @w_operacion = 0
while (1=1)
begin
   set rowcount 1
    
   select @w_operacion =  cop_operacion 
   from   #operaciones 
   where  cop_operacion > @w_operacion
   order by cop_operacion
	
   if @@rowcount = 0 
   begin
      set rowcount 0
      break
   end

   set rowcount 0	
	
   select @w_num_div_cap = count(di_dividendo) 
   from   cob_cartera..ca_dividendo
   where  di_operacion  = @w_operacion
   and    di_de_capital = 'S'
        
   select @w_num_div_int = count(di_dividendo) 
   from   cob_cartera..ca_dividendo
   where  di_operacion  = @w_operacion
   and    di_de_interes = 'S'
		
   if @w_num_div_cap = 1 and @w_num_div_int = 1
	  select @w_mod_pago = 1 
   else
   begin
   	  if @w_num_div_cap = 1 and @w_num_div_int > 1
		 select @w_mod_pago = 2
	  else
	  begin
	  	 select @w_tdividendo = op_tdividendo
		 from   cob_cartera..ca_operacion 
		 where  op_operacion = @w_operacion
					
		 select @w_factor = td_factor 
		 from   cob_cartera..ca_tdividendo
		 where  td_tdividendo = @w_tdividendo
					
		 if @w_factor > 30
		    select @w_mod_pago = 3
						
		 if @w_factor > 1 and @w_factor < 15 
			select @w_mod_pago = 4
							
		 if @w_factor = 15 
		    select @w_mod_pago = 5	
					
		 if @w_factor = 30
		    select @w_mod_pago = 6
	  end
   end

   update #operaciones set 
   cop_mod_pago  = @w_mod_pago
   where cop_operacion = @w_operacion
end

--SUBPRODUCTO CUENTA 
--TRAMITES GRUPALES SE INICIALIZA TODOS EN N
create table #tramites (
tramite   int,
promocion char(1))

if exists (select 1 from cob_credito..cr_tramite_grupal)
begin
   insert into #tramites 
   select distinct
   tramite   = cop_tramite,
   promocion = case tr_promocion when 'S' then 'S' else 'N' end
   from   cob_credito..cr_tramite_grupal, #operaciones, cob_credito..cr_tramite t
   where  tg_grupo           = cop_grupo 
   and    tg_operacion       = cop_operacion 
   and    tg_tramite         = t.tr_tramite
   and    tg_monto           > 0
   and    tg_participa_ciclo = 'S'
   and    tg_prestamo       <> tg_referencia_grupal
end   

--LPO CDIG Se crea #tramites_1 para usarla a continuación porque MySql no soporta el uso de la misma tabla #tramites en una misma sentencia
create table #tramites_1 (
tramite   int,
promocion char(1))

INSERT INTO #tramites_1 (tramite, promocion)
SELECT tramite, promocion FROM #tramites
--LPO CDIG FIN


--TRAMITES INDIVIDUALES 
insert into #tramites
select 
tramite   = tr_tramite,
promocion = isnull(tr_promocion,'') 
from   #operaciones, cob_credito..cr_tramite
where  cop_tramite     = tr_tramite
--and    tr_tramite not in (select tramite from #tramites) --LPO CDIG Se quita #tramites y se usa #tramites_1
and    tr_tramite not in (select tramite from #tramites_1)

update #operaciones set 
cop_subtipo_producto = case promocion when 'S' then 'PROMO' when 'N' then 'TRADICIONAL' else 'INDIVIDUAL' end
--from   #tramites , #operaciones --LPO CDIG Se quita la tabla porque en MySql no se soporta la misma tabla en update from
from   #tramites
where  cop_tramite = tramite

if @i_debug = 'S' print 'c.sp_consolidador_cca ' + @i_banco
if @i_debug = 'S' exec cob_cartera..sp_reloj @i_hilo = 1, @i_banco = @i_banco, @i_posicion = 'c.sp_consolidador_cca'

/* REGISTRO DE LOS SALDOS DIARIOS DE LAS OPERACIONES EN COB_EXTERNOS */
insert into cob_externos..ex_dato_operacion (
do_fecha,                  do_operacion,              do_banco,                  do_toperacion,
do_aplicativo,             do_destino_economico,      do_clase_cartera,          do_cliente,
do_documento_tipo,         do_documento_numero,       do_oficina,                do_moneda,
do_monto,                  do_tasa,                   do_modalidad,              do_plazo_dias,
do_fecha_desembolso,       do_fecha_vencimiento,      do_edad_mora,              do_reestructuracion,
do_fecha_reest,            do_nat_reest,              do_num_reest,              do_num_renovaciones,
do_estado,                 do_cupo_credito,           do_num_cuotas,             do_periodicidad_cuota,
do_valor_cuota,            do_cuotas_pag,             do_cuotas_ven,             do_saldo_ven,
do_fecha_prox_vto,         do_fecha_ult_pago,         do_valor_ult_pago,         do_fecha_castigo,
do_num_acta,               do_clausula,               do_oficial,                do_naturaleza,
do_fuente_recurso,         do_categoria_producto,     do_cap_mora,               do_tipo_garantias,
do_op_anterior,            do_edad_cod,               do_num_cuotas_reest,       do_tramite,
do_nota_int,               do_fecha_ini_mora,         do_gracia_mora,            do_estado_cobranza,
do_tasa_mora,              do_tasa_com,               do_entidad_convenio,       do_fecha_cambio_linea,
do_valor_nominal,          do_emision,                do_sujcred,                do_cap_vencido,
do_valor_proxima_cuota,    do_saldo_total_Vencido,    do_saldo_otr,              do_saldo_cap_total,
do_regional,               do_dias_mora_365,          do_normalizado,            do_tipo_norm, 
do_frec_pagos_capital,     do_frec_pagos_int,         do_fec_pri_amort_cubierta, do_monto_condo,
do_fecha_condo,            do_monto_castigo,          do_inte_castigo,           do_monto_bonifica,
do_inte_refina,            do_emproblemado,           do_mod_pago,               do_tipo_cartera,
do_subtipo_cartera,        do_cociente_pago,          do_numero_ciclos,          do_numero_integrantes,
/* LGU. NUEVOS CAMPOS */
do_grupo,                  do_valor_cat,              do_gar_liq_orig,           do_gar_liq_fpago,
do_gar_liq_dev,            do_gar_liq_fdev,
do_cuota_cap  ,            do_cuota_int   ,           do_cuota_iva   ,           do_fecha_suspenso,
do_cuenta     ,            do_plazo       ,           do_venc_dividendo,         do_fecha_aprob_tramite,
do_subtipo_producto,       do_atraso_grupal,          do_fecha_dividendo_ven,    do_tplazo             ,
do_cuota_min_vencida,      do_fecha_proceso,          do_subproducto,            do_cuota_max_vencida,      
do_atraso_gr_ant,          do_tipo_reg,               do_prox_cuota_int,         do_prox_cuota_otros,
do_pago_cap,               do_pago_int,               do_pago_otros,             do_tdividendo,
do_calificacion_cli)
select 
cop_fecha,                 cop_operacion,             cop_banco,                 cop_toperacion,
cop_aplicativo,            cop_destino,               cop_clase,                 cop_cliente,
cop_documento_tipo,        cop_documento_nume,        cop_oficina,               cop_moneda,
cop_monto,                 cop_tasa,                  cop_modalidad,             cop_plazo_dias,
cop_fecha_liq,             cop_fecha_fin,             cop_edad_mora,             cop_reestructuracion,
cop_fecha_reest,           cop_natur_reest,           cop_num_reest,             cop_num_renovacion,
cop_estado,                cop_cupo_credito,          cop_num_cuotas,            cop_per_cuotas,
cop_val_cuota,             cop_cuotas_pag,            cop_cuotas_ven,            cop_saldo_ven,
cop_fecha_prox_vto,        cop_fecha_ult_pago,        cop_valor_ult_pago,        cop_fecha_castigo,
cop_num_acta,              cop_clausula,              cop_oficial,               cop_naturaleza,
cop_fuente_recurso,        cop_categoria_producto,    cop_valor_vencido,         cop_tipo_garantias,
cop_op_anterior,           cop_edad_cod,              cop_num_cuotas_reest,      cop_tramite,
cop_nota_int,              cop_fecha_ini_mora,        cop_gracia_mora,           cop_estado_cobranza,
cop_tasa_mora,             cop_tasa_com,              cop_entidad_convenio,      cop_fecha_cambio_linea,
cop_valor_nominal,         cop_emision,               cop_sujcred,               cop_cap_vencido,
cop_valor_proxima_cuota,   cop_saldo_total_Vencido,   cop_saldo_otr,             cop_saldo_cap_total,
cop_regional,              cop_edad_mora_365,         cop_normalizado,           cop_tipo_norm,
cop_frec_pagos_cap,        cop_frec_pagos_int,        cop_fec_pri_amort_cubierta,cop_monto_condo,
cop_fecha_condo,           cop_monto_castigo,         cop_inte_castigo,          cop_monto_bonifica,
cop_inte_refina,           cop_emproblemado,          cop_mod_pago,              cop_sector,
cop_subtipo_linea,         cop_cociente_pago,         cop_numero_ciclos,         isnull(cop_numero_integrantes,0),
/* LGU. NUEVOS CAMPOS */
cop_grupo,                 cop_valor_cat,             cop_gar_liq_orig,          cop_gar_liq_fpago,
cop_gar_liq_dev,           cop_gar_liq_fdev,
cop_cuota_capital,         cop_cuota_int,             cop_cuota_iva,             cop_fecha_suspenso,
cop_cuenta,                cop_plazo,                 cop_vencimiento_div,       cop_fecha_apr_tramite,
cop_subtipo_producto,      cop_atraso_grupal,         cop_fecha_dividendo_ven,   cop_tplazo,
cop_cuota_min_vencida,     cop_fecha_proceso,         cop_subproducto_cuenta,    cop_cuota_max_vencida,     
cop_atraso_gr_ant,         'M',                       '0',                       '0',
'0',                       '0',                       '0',                       cop_tdividendo,
cop_calificacion_cli              
from  #operaciones

if @@error <> 0 
begin
   select 
   @w_error = 724504,
   @w_msg   = 'Error en al Grabar en table cob_externos..ex_dato_operacion'
   goto ERROR
end

/* REGISTRO DEL DETALLE DE SALDOS DIARIOS EN COB_EXTERNOS */
insert into cob_externos..ex_dato_operacion_rubro (
dr_fecha,         dr_banco,         dr_toperacion,     dr_aplicativo,     dr_concepto,       dr_estado, 
dr_exigible,      dr_codvalor,      dr_valor,          dr_cuota,          dr_acumulado,      dr_pagado,    
dr_categoria,     dr_rubro_aso,     dr_cat_rub_aso,    dr_valor_vigente,  dr_valor_suspenso, dr_valor_castigado, 
dr_valor_diferido)
select 
dr_fecha            = @w_fecha_proceso,
dr_banco            = cop_banco,
dr_toperacion       = cop_toperacion,
dr_aplicativo       = cop_aplicativo,
dr_concepto         = am_concepto,
dr_estado           = case when am_estado in (@w_est_novigente, @w_est_vigente) then @w_est_vigente else am_estado end,
dr_exigible         = case when di_estado in (@w_est_vencido) then 1 else 0 end,
dr_codvalor         = co_codigo * 1000 + case when am_estado in (@w_est_novigente, @w_est_vigente) then @w_est_vigente else am_estado end * 10 + am_periodo, -- case when di_estado in(@w_est_vencido) then 1 else 0 end,
dr_valor            = isnull((sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado))) / 2,0),
dr_cuota            = isnull(sum(isnull(am_cuota+am_gracia,0)), 0),
dr_acumulado        = isnull((sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado))) / 2,0),
dr_pagado           = isnull(sum(isnull(am_pagado,0)), 0),
dr_categoria        = co_categoria, 
dr_rubro_aso        = null,
dr_cat_rub_aso      = null,
dr_valor_vigente    = 0,
dr_valor_suspenso   = 0,
dr_valor_castigado  = 0,
dr_valor_diferido   = 0
from   #operaciones, cob_cartera..ca_amortizacion,cob_cartera..ca_dividendo, cob_cartera..ca_concepto
where  cop_operacion = am_operacion
and    am_concepto   = co_concepto
and    cop_operacion = di_operacion
and    am_dividendo  = di_dividendo
and    di_estado    in (@w_est_vigente, @w_est_novigente, @w_est_vencido)
group by cop_banco, cop_toperacion, cop_aplicativo, am_concepto, 
         case when am_estado in (@w_est_novigente, @w_est_vigente) then @w_est_vigente else am_estado end, 
         case when di_estado in (@w_est_vencido) then 1 else 0 end,
         co_codigo * 1000 + case when am_estado in (@w_est_novigente, @w_est_vigente) then @w_est_vigente else am_estado end * 10 + am_periodo, --case when di_estado in(@w_est_vencido) then 1 else 0 end,
         co_categoria

if @@error <> 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'Error en al Grabar en table cob_externos..ex_dato_operacion_rubro'
   goto ERROR
end

/* REGISTRO DEL DETALLE DE SALDOS DIARIOS EN COB_EXTERNOS */ 
/* DIVIDENDO CANCELADOS */
-- LGU 2018-01-25
insert into cob_externos..ex_dato_operacion_rubro (
dr_fecha,         dr_banco,         dr_toperacion,     dr_aplicativo,     dr_concepto,       dr_estado, 
dr_exigible,      dr_codvalor,      dr_valor,          dr_cuota,          dr_acumulado,      dr_pagado,    
dr_categoria,     dr_rubro_aso,     dr_cat_rub_aso,    dr_valor_vigente,  dr_valor_suspenso, dr_valor_castigado, 
dr_valor_diferido)
select 
@w_fecha_proceso,
cop_banco,
cop_toperacion,
cop_aplicativo,
am_concepto,
@w_est_cancelado,
@w_est_cancelado,
0,
isnull((sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado))) / 2,0),
isnull(sum(isnull(am_cuota+am_gracia,0)), 0),
isnull((sum(am_acumulado + am_gracia - am_pagado) + abs(sum(am_acumulado + am_gracia - am_pagado))) / 2,0),
isnull(sum(isnull(am_pagado,0)), 0),
co_categoria,
null,
null,
dr_valor_vigente   = 0,
dr_valor_suspenso  = 0,
dr_valor_castigado = 0,
dr_valor_diferido  = 0
from   #operaciones, cob_cartera..ca_amortizacion,  cob_cartera..ca_dividendo,  cob_cartera..ca_concepto
where  cop_operacion = am_operacion
and    am_concepto   = co_concepto
and    cop_operacion = di_operacion
and    am_dividendo  = di_dividendo
and    di_estado     = @w_est_cancelado
group by cop_banco, cop_toperacion, cop_aplicativo, am_concepto, co_categoria

if @@error <> 0 
begin
   select 
   @w_error = 724504, 
   @w_msg = 'Error en al Grabar en table cob_externos..ex_dato_operacion_rubro DIV = CAN'
   goto ERROR
end

if exists (select 1 from cob_cartera..ca_diferidos)
begin
   /* CCA 246 - DETERMINA LOS NUEVOS RUBROS QUE SE DEBEN INGRESAR EN LA TABLA EX_DATO_OPERACION_RUBRO PARA LOS DIFERIDOS */
   update #diferidos
   set    adicionar = 'N'
   from   cob_externos..ex_dato_operacion_rubro with (nolock)
   where  rtrim(cop_banco)+rtrim(concepto) = rtrim(dr_banco)+rtrim(dr_concepto)

   if @@error <> 0
   begin
      select 
      @w_error = 724504, 
      @w_msg   = 'Error al Actualizar el indicador de adicion en tabla #diferidos'
      goto ERROR
   end

   /* CCA 246 - REGISTRA RUBROS DE DIFERIDOS EN EX_DATO_OPERACION_RUBRO */
   insert into cob_externos..ex_dato_operacion_rubro (
   dr_fecha,         dr_banco,         dr_toperacion,     dr_aplicativo,     dr_concepto,       dr_estado, 
   dr_exigible,      dr_codvalor,      dr_valor,          dr_cuota,          dr_acumulado,      dr_pagado,    
   dr_categoria,     dr_rubro_aso,     dr_cat_rub_aso ,    dr_valor_vigente,  dr_valor_suspenso, dr_valor_castigado, 
   dr_valor_diferido)
   select
   @w_fecha_proceso, o.cop_banco,  o.cop_toperacion, o.cop_aplicativo, d.concepto, @w_est_diferido,
   0, co_codigo * 1000 + @w_est_diferido * 10 + 0, /* diferido no exigible*/ valDiff, 0,0,0, 
   co_categoria,    null,             null,               0,                 0,                  0,
   0
   from   #diferidos d, #operaciones o, cob_cartera..ca_concepto
   where  adicionar   = 'S'
   and    o.cop_banco = d.cop_banco
   and    concepto    = co_concepto
   and    valDiff     > 0

   if @@error <> 0 
   begin
      select 
      @w_error = 724504, 
      @w_msg   = 'Error en al Grabar diferidos en tabla cob_externos..ex_dato_operacion_rubro'
      goto ERROR
   end
end

update cob_externos..ex_dato_operacion_rubro
set    dr_rubro_aso = ru_concepto_asociado
from   cob_cartera..ca_rubro, #operaciones
where  cop_banco      = dr_banco
and    ru_toperacion  = dr_toperacion
and    ru_concepto    = dr_concepto
and    dr_fecha       = @w_fecha_proceso
and    dr_aplicativo  = 7

update cob_externos..ex_dato_operacion_rubro
set    dr_cat_rub_aso = co_categoria
from   cob_cartera..ca_rubro, cob_cartera..ca_concepto, #operaciones
where  cop_banco      = dr_banco
and    ru_toperacion  = dr_toperacion
and    ru_concepto    = dr_rubro_aso
and    dr_rubro_aso   = co_concepto
and    dr_fecha       = @w_fecha_proceso
and    dr_aplicativo  = 7

/* REGISTRO DE LAS TRANSACCIONES DIARIAS EN COB_EXTERNOS */
insert into cob_externos..ex_dato_transaccion
select 
@w_fecha_proceso,   tr_secuencial,       tr_banco, 
tr_toperacion,      7,                   tr_fecha_mov,        
tr_tran,            
case when tr_secuencial > 0 then 'N' else 'S' end, 
case when tr_tran = 'DES' then 'C' else 'D' end,
'OFI',
tr_ofi_usu,         0,                   tr_usuario, 
tr_terminal,        tr_fecha_real,        null,
null
from   cob_cartera..ca_transaccion, #operaciones
where  tr_operacion = cop_operacion
and    tr_fecha_mov = @w_fecha_proceso
and    tr_estado   <> 'RV'
and    tr_tran     in ('PAG', 'DES')

if @@error <> 0 
begin 
   select 
   @w_error = 724504, 
   @w_msg   = 'Error en al Grabar en table cob_externos..ex_dato_transaccion'
   goto ERROR
end

select cop_banco, ab_secuencial_pag, ab_secuencial_rpa, sa_ssn_corr 
into   #OperacionATX
from   cob_cartera..ca_secuencial_atx, #operaciones, cob_cartera..ca_abono
where  cop_operacion     = ab_operacion
and    sa_operacion      = cop_banco
and    sa_fecha_ing      = ab_fecha_pag
and    sa_fecha_ing      = @w_fecha_proceso
and    ab_secuencial_ing = sa_secuencial_cca
and    ab_estado        <> 'RV'

update cob_externos..ex_dato_transaccion 
set    dt_secuencial_caja = sa_ssn_corr
from   #OperacionATX
where  dt_fecha       = @w_fecha_proceso
and    dt_aplicativo  = 7
and    dt_banco       = cop_banco
and    dt_secuencial  = ab_secuencial_pag
and    dt_tipo_trans  = 'PAG'

if @@error <> 0
begin 
   select 
   @w_error = 724504, 
   @w_msg   = 'Error en Actualizar secuencial PAG caja ex_dato_transaccion'
   goto ERROR
end

/* REGISTRO DEL DETALLE DE TRANSACCIONES DIARIAS EN COB_EXTERNOS */
insert into cob_externos..ex_dato_transaccion_det
(dd_fecha,           dd_secuencial,  dd_banco,          
 dd_toperacion,      dd_aplicativo,  dd_concepto,       
 dd_moneda,          dd_cotizacion,  dd_monto,          
 dd_codigo_valor,    dd_dividendo)
select 
@w_fecha_proceso,    tr_secuencial,  tr_banco,
tr_toperacion,       7,              dtr_concepto,   
dtr_moneda,          dtr_cotizacion, sum(dtr_monto),
convert(varchar(24), dtr_codvalor),  dtr_dividendo 
from   cob_cartera..ca_det_trn, cob_cartera..ca_transaccion, #operaciones
where  tr_operacion   = cop_operacion
and    tr_operacion   = dtr_operacion
and    tr_secuencial  = dtr_secuencial
and    tr_fecha_mov   = @w_fecha_proceso
and    tr_estado     <> 'RV'
and    tr_tran       in ('PAG', 'DES', 'RPA')
and    dtr_concepto not like 'VAC%'
group by tr_secuencial, tr_banco, tr_toperacion, dtr_concepto, dtr_moneda, dtr_cotizacion, dtr_afectacion, dtr_codvalor, dtr_dividendo

if @@error <> 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'Error en al Grabar en table cob_externos..ex_dato_transaccion_det'
   goto ERROR
end

/*ACTUALIZACION  DE LA FORMA DE DESMBOLSO "CAJA" */
update cob_externos..ex_dato_transaccion_det 
set    dd_concepto = 'CAJA'
from   cob_externos..ex_dato_transaccion, #operaciones
where  cop_banco     = dt_banco
and    dt_fecha      = @w_fecha_proceso
and    dt_aplicativo = 7
and    dt_fecha      = dd_fecha
and    dt_aplicativo = dd_aplicativo
and    dt_banco      = dd_banco
and    dt_secuencial = dd_secuencial
and    dt_tipo_trans = 'DES'
and    dd_concepto  in (select cp_producto from cob_cartera..ca_producto where cp_atx = 'S')

if @@error <> 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'Error en al ACTUALIZAR FORMA DESEMBOLSO "CAJA"  ex_dato_transaccion_det'
   goto ERROR
end

/*ACTUALIZACION  SECUENCIAL DE PAGO */
update cob_externos..ex_dato_transaccion_det 
set    dd_secuencial = tr_secuencial
from   cob_cartera..ca_transaccion, #operaciones
where  cop_banco         = dd_banco
and    dd_fecha          = @w_fecha_proceso
and    dd_aplicativo     = 7
and    tr_banco          = dd_banco
and    tr_secuencial_ref = dd_secuencial
and    tr_tran           = 'PAG'

if @@error <> 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'Error en al ACTUALIZAR SECUENCIAL PAGO  ex_dato_transaccion_det'
   goto ERROR
end

/* INFORMACION FORMA DE PAGO, CANAL DE RECEPCION DE PAGO */
select ab_secuencial_rpa, ab_secuencial_pag,  cop_banco, ab_fecha_ing, isnull(cp_canal,'OFI') as cp_canal 
into   #oper_canal
from   cob_cartera..ca_abono, cob_cartera..ca_abono_det, cob_cartera..ca_producto, #operaciones
where  cop_operacion     = ab_operacion 
and    ab_secuencial_ing = abd_secuencial_ing
and    ab_operacion      = abd_operacion
and    abd_concepto      = cp_producto
and    ab_fecha_ing      = @w_fecha_proceso
and    abd_tipo     not in (select codigo 
                            from   cobis..cl_catalogo
                            where  tabla = (select codigo 
                                            from   cobis..cl_tabla
                                            where  tabla = 'ca_excluir_conc'))
                       
update cob_externos..ex_dato_transaccion set
dt_canal = cp_canal
from   #oper_canal
where  dt_fecha       = @w_fecha_proceso
and    dt_aplicativo  = 7
and    dt_banco       = cop_banco
and    dt_fecha       = ab_fecha_ing
and    dt_secuencial in (ab_secuencial_rpa, ab_secuencial_pag) 

if @@error <> 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'Error en Actualizar campo CANAL ex_dato_transaccion'
   goto ERROR
end

/* REGISTRO DEL DETALLE DE DEUDORES Y CODEUDORES DE LOS PRESTAMOS */
insert into cob_externos..ex_dato_deudores
select 
@w_fecha_proceso,
cop_banco,
cop_toperacion,  
7,
cl_cliente,
ltrim(rtrim(cl_rol)),
null,
null
from   cobis..cl_det_producto, cobis..cl_cliente, #operaciones
where  cop_banco       = dp_cuenta
and    dp_det_producto = cl_det_producto
and    dp_producto     = 7 -- Req. 381 CB Red Posicionada

if @@error <> 0 
begin
   select 
   @w_error = 724504, 
   @w_msg   = 'Error en al Grabar en table cob_externos..ex_dato_deudores'
   goto ERROR
end

if @i_debug = 'S' print 'd.sp_consolidador_cca ' + @i_banco
if @i_debug = 'S' exec cob_cartera..sp_reloj @i_hilo = 1, @i_banco = @i_banco, @i_posicion = 'd.sp_consolidador_cca'

if @w_fin_mes = 'S' 
/* --GFP 03/09/2021 Deshabilitación temporal hasta su uso
or exists (select 1 
           from   cob_conta_super..sb_calendario_proyec
           where  cp_fecha_proc = @w_fecha_proceso)
*/ --GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
begin
   /* REGISTRO DEL LAS FECHAS DE FUTUROS VENCIMIENTOS DE LA OPERACION */
   insert into cob_externos..ex_dato_cuota_pry
   select 
   @w_fecha_proceso,
   cop_banco,
   cop_toperacion,  
   7,
   di_dividendo,
   di_fecha_ven,
   di_estado,
   saldo            = isnull(sum(am_cuota-am_pagado),0),
   
   /* NUEVOS CAMPOS PARA SACAR EL ESTADO DE CUENTA DESDE EL CONSOLIDADOR */
   /* VALORES CUOTA */
   /*--GFP 03/09/2021 Deshabilitación temporal hasta su uso
   di_cap_cuota     = sum(case when am_concepto      = @w_rubro_cap then am_cuota else 0 end),
   di_int_cuota     = sum(case when am_concepto     in (@w_rubro_int,@w_rubro_intant) then am_cuota+am_gracia else 0 end),
   di_imo_cuota     = sum(case when am_concepto      = 'COMMORA'    then am_cuota else 0 end),
   di_pre_cuota     = sum(case when am_concepto      = 'COMPRECAN'  then am_cuota else 0 end),
   di_iva_int_cuota = sum(case when am_concepto      = @w_rubro_ivaint then am_cuota+am_gracia else 0 end),
   di_iva_imo_cuota = sum(case when am_concepto      = 'IVA_CMORA'  then am_cuota else 0 end),
   di_iva_pre_cuota = sum(case when am_concepto      = 'IVA_COMPRE' then am_cuota else 0 end),
   di_otros_cuota   = sum(case when am_concepto not in (@w_rubro_cap,@w_rubro_int,@w_rubro_intant, 'COMMORA', 'COMPRECAN', @w_rubro_ivaint, 'IVA_CMORA', 'IVA_COMPRE') then am_cuota else 0 end),
   */--GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
   /* VALORES ACUMULADOS */
   /*--GFP 03/09/2021 Deshabilitación temporal hasta su uso
   di_int_acum      = sum(case when am_concepto     in (@w_rubro_int,@w_rubro_intant) then ((am_acumulado + am_gracia - am_pagado) + abs(am_acumulado + am_gracia - am_pagado)) / 2 else 0 end),
   di_iva_int_acum  = sum(case when am_concepto      = @w_rubro_ivaint then ((am_acumulado + am_gracia - am_pagado) + abs(am_acumulado + am_gracia - am_pagado)) / 2 else 0 end),
   */--GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
   /* VALORES PAGADOS */
   /*--GFP 03/09/2021 Deshabilitación temporal hasta su uso
   di_cap_pag       = sum(case when am_concepto      = @w_rubro_cap then am_pagado else 0 end),
   di_int_pag       = sum(case when am_concepto     in (@w_rubro_int,@w_rubro_intant) then am_pagado else 0 end),
   di_imo_pag       = sum(case when am_concepto      = 'COMMORA'    then am_pagado else 0 end),
   di_pre_pag       = sum(case when am_concepto      = 'COMPRECAN'  then am_pagado else 0 end),
   di_iva_int_pag   = sum(case when am_concepto      = @w_rubro_ivaint then am_pagado else 0 end),
   di_iva_imo_pag   = sum(case when am_concepto      = 'IVA_CMORA'  then am_pagado else 0 end),
   di_iva_pre_pag   = sum(case when am_concepto      = 'IVA_COMPRE' then am_pagado else 0 end),
   di_otros_pag     = sum(case when am_concepto not in (@w_rubro_cap,@w_rubro_int,@w_rubro_intant, 'COMMORA', 'COMPRECAN', @w_rubro_ivaint, 'IVA_CMORA', 'IVA_COMPRE') then am_pagado else 0 end),
   */--GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
   /* FECHA DE CANCELACION DE LA CUOTA */
   /*--GFP 03/09/2021 Deshabilitación temporal hasta su uso
   max(di_fecha_can),
   null,
   */--GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
   null,
   null
   from  cob_cartera..ca_dividendo d,cob_cartera..ca_amortizacion a, #operaciones o
   where cop_operacion = di_operacion
   and   di_operacion  = am_operacion
   and   am_operacion  = cop_operacion
   and   am_dividendo  = di_dividendo
   group by cop_banco, cop_operacion, cop_toperacion, di_dividendo, di_fecha_ven, di_estado

   if @@error <> 0 
   begin
      select 
      @w_error = 724504, 
      @w_msg   = 'Error en al Grabar en table cob_externos..ex_dato_cuota_pry'
      goto ERROR
   end

   select
   ult_banco     = tr_banco,
   ult_dividendo = dtr_dividendo,
   ult_fecha_pag = max(tr_fecha_ref)
   into   #ultpagos
   from   cob_cartera..ca_transaccion, cob_cartera..ca_det_trn, #operaciones
   where  tr_operacion  = dtr_operacion
   and    tr_operacion  = cop_operacion
   and    tr_secuencial = dtr_secuencial
   and    tr_tran       = 'PAG'
   and    tr_estado    <> 'RV'
   group by tr_banco, dtr_dividendo

   if @@error != 0
   begin
      select
      @w_error = 708192, 
      @w_msg = 'Error en al Consultar Ultimos Pagos'
      goto ERROR
   end
   /*--GFP 03/09/2021 Deshabilitación temporal hasta su uso
   update cob_externos..ex_dato_cuota_pry set
   dc_fecha_upago  = ult_fecha_pag
   from   #ultpagos
   where  ult_banco     = dc_banco
   and    ult_dividendo = dc_num_cuota
   
   if @@error != 0  
   begin
      select 
      @w_error = 724504,
      @w_msg   = 'Error en al Grabar en table cob_externos..ex_dato_cuota_pry'
      goto ERROR
   end
   */--GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
end

/* LCM - 230 - INSERTAR CONDONACIONES */
if (@i_banco is null and exists (select 1 from cob_cartera..ca_condonacion))
or (@i_banco is not null and exists (select 1 from cob_cartera..ca_condonacion where co_operacion = @w_operacionca))
begin
   --GFP 03/09/2021 Campos comentados temporal hasta su uso
   insert into cob_externos..ex_dato_condonacion (
   dc_fecha,           dc_aplicativo,  --dc_secuencial,     
   dc_banco,           --dc_cliente,     
   dc_fecha_cond,  
   dc_monto,           --dc_porcentaje,  dc_concepto, 
   --dc_estado_concepto, 
   --dc_usuario,     dc_rol_condona,
   --dc_autoriza,        dc_estado,      
   dc_origen,      
   dc_fecha_proc,      dc_tipo_id,     dc_ced_ruc)
   select
   @w_fecha_proceso,   7,              --co_secuencial,
   cop_banco,          --cop_cliente,    
   co_fecha_aplica,
   co_valor,           --co_porcentaje,  co_concepto,     
   --co_estado_concepto, 
   --co_usuario,     co_rol_condona,
   --co_autoriza,        co_estado,      
   null,
   null,               cop_toperacion, '0'
   from  cob_cartera..ca_condonacion, #operaciones
   where co_operacion    = cop_operacion  
   and   co_fecha_aplica = @w_fecha_proceso
   and   co_estado      <> 'R'

   if @@error <> 0 
   begin
      select 
      @w_error = 724504, 
      @w_msg   = 'Error en al Grabar en tabla cob_externos..ex_dato_condonacion'
      goto ERROR
   end   
end

if @i_debug = 'S' print 'e.sp_consolidador_cca ' + @i_banco
if @i_debug = 'S' exec cob_cartera..sp_reloj @i_hilo = 1, @i_banco = @i_banco, @i_posicion =  'e.sp_consolidador_cca'

/**Si es fin mes pasa las condonaciones reversadas del mes**/
if @w_fin_mes = 'S' 
begin
   --GFP 03/09/2021 Campos comentados temporal hasta su uso
   insert into cob_externos..ex_dato_condonacion (
   dc_fecha,           dc_aplicativo,  --dc_secuencial,     
   dc_banco,           --dc_cliente,     
   dc_fecha_cond,  
   dc_monto,           --dc_porcentaje,  dc_concepto, 
   --dc_estado_concepto, dc_usuario,     dc_rol_condona,
   --dc_autoriza,        dc_estado,      
   dc_origen,      
   dc_fecha_proc,      dc_tipo_id,     dc_ced_ruc)
   select
   @w_fecha_proceso,   7,              --co_secuencial,
   cop_banco,          --cop_cliente,    
   co_fecha_aplica,
   co_valor,          -- co_porcentaje,  co_concepto,     
   --co_estado_concepto, co_usuario,     co_rol_condona,
   --co_autoriza,        co_estado,      
   null,
   null,               cop_toperacion, '0'
   from  cob_cartera..ca_condonacion, #operaciones
   where co_operacion                 = cop_operacion  
   and   datepart(mm,co_fecha_aplica) = datepart(mm, @w_fecha_proceso)
   and   datepart(yy,co_fecha_aplica) = datepart(yy, @w_fecha_proceso)
   and   co_estado                    = 'R'
   
   if @@error <> 0 
   begin
      select 
      @w_error = 724504, 
      @w_msg   = 'Error en al Grabar en tabla cob_externos..ex_dato_condonacion'
      goto ERROR
   end
end

--REQ486 PASO REPOSITORIO DATOS TRASLADOS CLIENTES
--OBTENIENDO DATOS DE TRASLADO DE CUENTAS DE CARTERA
if (@i_banco is null and exists (select 1 from cob_cartera..ca_traslados_cartera))
begin
   insert into cob_externos..ex_traslado_ctas_ca_ah (
   tc_fecha_corte, tc_cliente,  tc_oficina_ini, tc_oficina_fin, tc_tipo_prod)
   select distinct  
   trc_fecha_proceso, trc_cliente, trc_oficina_origen, trc_oficina_destino, 'A'
   from   cob_cartera..ca_traslados_cartera
   where  trc_fecha_proceso = @w_fecha_proceso
   order by trc_fecha_proceso, trc_cliente

   if @@error <> 0 
   begin
      select 
      @w_error = 724504, 
      @w_msg   = 'ERROR AL INSERTAR EN EX_TRASLADO_CTAS_CA_AH'
      goto ERROR
   end   
end 

if @i_debug = 'S' print 'f.sp_consolidador_cca ' + @i_banco
if @i_debug = 'S' exec cob_cartera..sp_reloj @i_hilo = 1, @i_banco = @i_banco, @i_posicion = 'f.sp_consolidador_cca'

return 0

ERROR:

exec cob_cartera..sp_errorlog 
@i_fecha     = @w_fecha_proceso,
@i_error     = @w_error, 
@i_usuario   = 'sa', 
@i_tran      = 7999,
@i_tran_name = @w_sp_name,
@i_cuenta    = 'Masivo',
@i_anexo     = @w_msg,
@i_rollback  = 'S'

return @w_error

go

