use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_caconta')
   drop proc sp_caconta
go

create procedure sp_caconta
/************************************************************************/
/*   NOMBRE LOGICO:      conta.sp                                       */
/*   NOMBRE FISICO:      sp_caconta                                     */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:                                                      */
/*   FECHA DE ESCRITURA:                                                */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   Generar los registros de cuentas contables de las trasacciones     */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*      FECHA           AUTOR             RAZON                         */
/*   Jul-07-2010   Elcira Pelaez  MANEJO nuevo sp_ca07_pf   para sacar  */
/*                                @w_clave (cal-gar-clase-mon-org.fondo)*/
/*   Feb-23-2011   Elcira Pelaez  Control error en consulta Operacione  */
/*   Sep-02-2019   Luis Ponce     Sp para resolucion de parametros      */
/*   DIC-12-2019   Luis Ponce     No considerar transaccion VEN en conta*/
/*   Ago-27-2020   Sandro Vallejo Paralelismo de todas las transacc.    */
/*   01/Dec/2020  P.Narvaez   Tomar la fecha de cierre de Cartera, cont-*/
/*                            tabilizar provisiones en moneda extrangera*/
/*  16/07/21       G.Fernandez      Estandarizacion de parametros       */
/*  12/01/2022     G.Fernandez      Ingreso de nueva clave por sector   */
/*                                  y grupo de garantia del prestamo    */
/*  07/02/2022     G.Fernandez      Para transacciones TCO se ingresa   */
/*                                  la oficina del campo dtr_cuenta GFP */
/*  25/02/2022     G.Fernandez  Coreccion de generacion de comprobantes */
/*                              sin duplicidad y de forma agrupada      */
/*  25/03/22       G.Fernandez  Incluir numero de operaciones negativas */
/*                              para rubros diferidos, incluir concepto */
/*                              en campo agrupado                       */
/*  01/04/2022     G.Fernandez  Nuevo paramemetro de fecha de procesos, */
/*                              se valida param de banco con la cadena  */
/*                              NULL por ejecucion de visual batch      */
/*  10/06/2022     G.Fernandez  Se actualiza registro de comprobantes y */
/*                              asientos contables con fecha de proceso */
/*  14/06/2022     G.Fernandez  Control para contabilización de rubros  */
/*                              tipo mora                               */
/*  15/06/2022     G.Fernandez  Validaciónes de null en parametro de    */
/*                              banco y  transacciones a contabilizar   */
/*  16/06/2022     K. Rodriguez Cambio de asignación descripción perfil */
/*  30/06/2022     G.Fernandez  Cambio de codigo de error para débito y */
/*                              crédito no cuadran                      */
/*  21/07/2022     Wlopez       CCA-R189662-GFI                         */
/*  23/07/2022     G.Fernandez  Actualización para proceso individual   */
/*  05/08/2022     Wlopez       CCA-R191094-GFI                         */
/*  08/08/2022     K.Rodríguez  Cambio condición monto(regularizacion)  */
/*  31/08/2022     G.Fernandez  R192715 Inicialización de variable      */
/*                              tipo_rubro                              */
/*  17/04/2023     G. Fernandez S807925 Ingreso de nuevo campo de       */
/*                              reestructuracion                        */
/*  21/04/2023     G. Fernandez S807925 Homologacion de estados para    */
/*                              pruebas                                 */
/*  21/04/2023     G. Fernandez B816885 Ingreso de nuevos campos para   */
/*                              obtener claves de PRV 	                */
/*  06/06/2023	   M. Cordova	Cambio variable @ct_calificacion   		*/
/*								de char(1) a catalogo					*/
/*  07/06/2023     G. Fernandez S841159 Ajuste el la terminacion de la  */
/*                              originacion de la operacion             */
/*	13/07/2023	   M. Cordova	Modificacion de proceso de contabilización*/
/*								automática de transacciones				*/
/*	21/07/2023	   G. Fernandez	R215869 Se inicializa variable de origi-*/
/*								nacion para obtener cuenta contable		*/
/*	02/10/2023	   G. Fernandez	Correción de obtención de originación   */
/*	05/10/2023	   G. Fernandez	Validación de estado en trn condonación */ 
/*  28/11/2023     K. Rodriguez R220410  Ajuste Oficina de operación    */
/************************************************************************/

   @i_param1             int           = 0,             --hilo
   @i_param2             login         = 'sp_caconta',  --user
   @i_param3             char(1)       = 'N',           --debug
   @i_param4             cuenta        = null,          --banco
   @i_param5             datetime      = null           --fecha de proceso
 
as declare
   @w_error             int,
   @w_mon_nac           int,
   @w_num_dec_mn        int,
   @w_ar_origen         int,
   @w_asiento           int,
   @w_comprobante       int,
   @w_debcred           int,
   @w_oficina           smallint,
   @w_re_ofconta        int,
   @w_fecha_proceso     smalldatetime,
   @w_fecha_hasta       smalldatetime,
   @w_fecha_mov         smalldatetime,
   @w_mensaje           varchar(255),
   @w_descripcion       varchar(255),
   @w_concepto          varchar(255),
   @w_cuenta_final      varchar(40),
   @w_sp_name           descripcion,
   @w_cotizacion        float,
   @w_perfil            varchar(10),
   @w_of_origen_cur     int,
   @w_op_oficina        int,
   @w_fecha_val         datetime,
   @w_tran_cur          varchar(10),
   @w_op_moneda         int,
   @w_toperacion        varchar(10),
   @w_reverso           char(1),
   @w_monto_cur         money,
   @w_dtr_moneda        int,
   @w_sector            varchar(10),
   @w_dtr_monto         money,
   @w_dtr_monto_mn      money,
   @w_dtr_concepto      varchar(20),
   @w_dtr_codval        int,
   @w_dtr_codval_trn    int,
   @w_dp_cuenta         varchar(40),
   @w_parametro         varchar(24),
   @w_dp_debcred        char(1),
   @w_dp_constante      char(1),
   @w_dp_origen_dest    char(1),
   @w_debito            money,
   @w_credito           money,
   @w_debito_me         money,
   @w_credito_me        money,
   @w_tot_debito        money,
   @w_tot_credito       money,
   @w_tot_debito_me     money,
   @w_tot_credito_me    money,
   @w_estado_prod       char(1),
   @w_cod_producto      tinyint,
   @w_moneda_as         int,
   @w_secuencial        int,
   @w_secuencial_ref    int,
   @w_re_area           int,
   @w_gar_admisible     varchar(1),
   @w_calificacion      catalogo,
   @w_clase_cart        varchar(10),
   @w_subtipo_cart      varchar(10),
   @w_ente              int,
   @w_banco             varchar(24),
   @w_con_iva           varchar(1),
   @w_valor_base        money,
   @w_con_timbre        varchar(1),
   @w_valor_timbre      money,
   @w_porcentaje_iva    float,
   @w_referencial_iva   varchar(20),
   @w_maxfecha_iva      datetime,
   @w_dtr_cuenta        cuenta,
   @w_bcp_parametro     varchar(100),
   @w_afecta            varchar(1),
   @w_valor_ref         varchar(5),
   @w_cont              int,
   @w_operacionca       int,
   @w_cheque            int,
   @w_marcados          int,
   @w_llenado           varchar(24),
   @w_clave             varchar(40),
   @w_stored            cuenta,
   @w_dp_area           varchar(10),
   @w_oficina_aux       smallint,
   @w_factor            int,
   @w_comprobante_base  int,
   @w_idlote            int,
   @w_commit            char(1),
   @w_rowcount          int,
   @w_op_origen_fondos  varchar(10),
   @w_entidad_convenio  varchar(1),
   @w_bancamia          varchar(24),
   @w_valret            money,
   @w_conret            char(1),
   @w_categoria         char(1),
   @w_montodes	        money,
   @w_cliente_al        varchar(20),
   @w_tramite           int,
   @w_dm_producto       catalogo,
   @w_detener_proceso   char(1),
   @w_agrupado          varchar(64),
   @w_xtercero          char(1),
   @w_tasa_iva          float,
   @w_iva               catalogo,  
   @w_oda_grupo_contable catalogo,
   @w_fecha_ref         datetime,  --GFP 25/02/2022 Para generación de comprobantes individuales
   @w_contabilizar_mora char(1),
   @w_tipo_rubro        catalogo,
 --Variables para parametros batch
   @i_hilo              int           ,
   @s_user              login         ,
   @i_debug             char(1)       ,
   @i_banco             cuenta        ,
   --INI WLO_R189662
   @w_hora              int,
   @w_minuto            int,
   @w_segundo           int,
   @w_milisegundo       int,
   --FIN WLO_R189662
   @w_categoria_plazo   varchar(10),
   @w_originacion       varchar(10),
   @w_reestructuracion  char(1),
   @w_dtr_estado        tinyint,
   @w_est_condonado           tinyint,
   @w_est_vigente             tinyint,
   @w_est_vencido             tinyint,
   @w_est_novigente           tinyint,
   @w_est_cancelado           tinyint,
   @w_est_vencido_prorroga    tinyint,
   @w_est_vencido_cobro_admin tinyint,
   @w_est_judicial            tinyint,
   @w_est_castigado           tinyint,
   @w_est_suspenso            tinyint


--GFP Manejo de null por visual batch
IF @i_param4 = 'NULL'
  select @i_param4 = null
   
--GFP 16/07/2021 paso de parametros de batch a variables locales
select
   @i_hilo      =  @i_param1,
   @s_user      =  @i_param2,
   @i_debug     =  @i_param3,
   @i_banco     =  @i_param4   
   
/* VARIABLES DE TRABAJO */
select
@w_sp_name         = 'caconta.sp',
@w_mensaje         = '',
@w_estado_prod     = 'V',
@w_cod_producto    = 7, 
@w_valor_base      = 0,
@w_llenado         = '                       ',
@w_commit          = 'N',
@w_xtercero        = 'N',
@w_detener_proceso = 'N'

--INI WLO_R189662
if @i_debug = 'S'
begin
   print '--> sp_caconta.Inicio Contabilidad...'
   select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
   print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
end
--FIN WLO_R189662

-- DETERMINAR FECHA PROCESO 
select @w_fecha_proceso = isnull(@i_param5,fc_fecha_cierre)
from   cobis..ba_fecha_cierre with (nolock)
where  fc_producto = @w_cod_producto

-- SELECCION DEL AREA DE CARTERA 
select @w_ar_origen = pa_smallint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'ARC'

if @@rowcount = 0 
begin
   select 
   @w_mensaje = ' ERR NO DEFINIDA AREA DE CARTERA ' ,
   @w_error   = 708176
   goto ERRORFIN
end

-- DETERMINAR LA MONEDA NACIONAL Y CANTIDAD DE DECIMALES
select @w_mon_nac = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

select @w_num_dec_mn = pa_tinyint                                                                                                                                                                                                                         
from   cobis..cl_parametro with (nolock)                                                                                                                                                                                                                  
where  pa_producto = 'CCA'                                                                                                                                                                                                                                  
and    pa_nemonico = 'NDE' 
   
--Parametro para determinar si se paga mora
select @w_contabilizar_mora = pa_char                                                                                                                                                                                                                         
from   cobis..cl_parametro with (nolock)                                                                                                                                                                                                                  
where  pa_producto = 'CCA'                                                                                                                                                                                                                                  
and    pa_nemonico = 'CORUMO' 

--- ESTADOS DE CARTERA
exec  sp_estados_cca
@o_est_vigente                = @w_est_vigente             out, --1
@o_est_vencido                = @w_est_vencido             out, --2
@o_est_cancelado              = @w_est_cancelado           out, --3
@o_est_castigado              = @w_est_castigado           out, --4
@o_est_suspenso               = @w_est_suspenso            out, --9
@o_est_novigente              = @w_est_novigente           out, --0
@o_est_condonado              = @w_est_condonado           out, --7
@o_est_vencido_prorroga       = @w_est_vencido_prorroga    out, --10
@o_est_vencido_cobro_admin    = @w_est_vencido_cobro_admin out, --11
@o_est_judicial               = @w_est_judicial            out  --5

-- SI PROCESA POR OPERACION INICIALIZARLA
if @i_banco is not null
begin
   select @w_operacionca = op_operacion
   from   ca_operacion
   where  op_banco = @i_banco
   
   if @@rowcount = 0 
   begin
      select @w_error   = 701049,
             @w_mensaje = 'REVISAR EXISTENCIA DE LA OPERACION en  ca_operacion' 
      goto ERRORFIN
   end
end

-- CREACION DE TABLAS DE TRABAJO
if not exists (select 1 from sysobjects where name = '#ca_conta_trn_tmp')
begin
   create table #ca_conta_trn_tmp(
    ct_operacion        int         not null,
    ct_secuencial       int         not null,
    ct_banco            varchar(24) null,
    ct_agrupado         varchar(64) null,
    ct_tran             varchar(10) null,
    ct_ofi_usu          smallint    null,
    ct_ofi_oper         smallint    null,
    ct_toperacion       varchar(10) null,
    ct_fecha_mov        datetime    null,
    ct_fecha_ref        datetime    null,
    ct_perfil           varchar(10) null,
    ct_sector           varchar(10) null,
    ct_moneda           tinyint     null,
    ct_gar_admisible    char(1)     null,
    ct_calificacion     catalogo     null,
    ct_clase            varchar(10) null,
    ct_cliente          int         null,
    ct_tramite          int         null,
    ct_categoria        varchar(10) null,
    ct_entidad_convenio char(1)     null, 
    ct_subtipo_linea    varchar(10) null,
    ct_concepto         varchar(10) null,
    ct_codvalor         int         null,
    ct_monto            money       null,
    ct_reestructuracion char(1)     null,	)

   --create nonclustered index #ca_conta_trn_tmp_1 on #ca_conta_trn_tmp (ct_operacion, ct_secuencial) 
   create index ca_conta_trn_tmp_1 on #ca_conta_trn_tmp (ct_operacion, ct_secuencial) 
end   

if not exists (select 1 from sysobjects where name = '#detalles')
begin      
   create table #detalles( 
    dtr_concepto         varchar(10) null,        
    dtr_codvalor         int         null,            
    dtr_moneda           int         null,  
    dtr_cuenta           varchar(20) null,          
    dtr_monto            money       null,
    dtr_dividendo        int         null,
    dtr_secuencial       int         null,
    dtr_operacion        int         null,
    dtr_monto_mn         money       null,
    dtr_cotizacion       float       null,
	dtr_estado           tinyint     null)
end

if not exists (select 1 from sysobjects where name = '#detalles_prv')
begin      
   create table #detalles_prv( 
    de_asiento          int         IDENTITY(1,1),   
    de_banco            varchar(24) null,
    de_toperacion       varchar(10) null,
    de_operacion        int         null,
    de_concepto         varchar(10) null,
    de_codvalor         int         null,
    de_moneda           int         null,
    de_monto            money       null,
    de_ref_iva          varchar(10) null,
    de_maxfec_iva       datetime    null,
    de_porc_iva         float       null,
    de_valor_base       money       null,
    de_cuenta           varchar(30) null,
    de_debcred          char(1)     null,
    de_constante        varchar(3)  null,
    de_origen_dest      char(1)     null,
    de_area             varchar(10) null,
    de_tipo_area        varchar(10) null,
    de_oficina          smallint    null,
    de_clave            varchar(40) null,
    de_cuenta_final     varchar(40) null,
    de_debito           money       null,
    de_credito          money       null,
    de_con_iva          char(1)     null,
    de_fecha_mov        datetime    null,
    de_sector           varchar(10) null,
    de_gar_admisible    char(1)     null,
    de_calificacion     catalogo     null, 
    de_clase            varchar(10) null,
    de_cliente          int         null,
    de_ent_convenio     char(1)     null,
    de_subtipo_linea    varchar(10) null,
    de_monto_mn         money       null,
    de_cotizacion       float       null,
    de_debito_me        money       null,
    de_credito_me       money       null,
	de_estado           int         null,
	de_reestructuracion char(1)     null,
    de_categoria_plazo  char(1)     null,
	de_originacion      varchar(10) null)
end


if not exists (select 1 from sysobjects where name = '#iva')
begin      
   create table #iva( 
    ref_iva             varchar(10),
    estado              char(1))    
end

if not exists (select 1 from sysobjects where name = '#provision_sincodval')
begin      
   create table #provision_sincodval( 
     ps_banco  cuenta,
     ps_descripcion varchar(255),
     ps_agrupado    varchar(64), 
     ps_operacion   int,
     ps_codvalor    int,
	 ps_fecha_ref   datetime    null,)    
end


-- LAZO DE TRANSACCIONES A CONTABILIZAR 
while @w_detener_proceso = 'N' 
begin 

   select @w_error = 0

   -- TRANSACCIONES MASIVAS
   if @i_banco is null
   begin 
      --INI WLO_R189662
      if @i_debug = 'S'
      begin
         print 'Hilo ' +  convert(varchar,@i_hilo)
         select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
         print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
      end
      --FIN WLO_R189662

      set rowcount 1 
 
      select @w_agrupado         = agrupado,
             @w_comprobante_base = comprobante 
      from   ca_universo_conta with (nolock) --WLO_R189662
      where  hilo     = @i_hilo 
      and    intentos < 2 
      order by id 

      if @@rowcount = 0 
      begin 
         set rowcount 0 
         select @w_detener_proceso = 'S' 
         break --WLO_R189662
      end 
 
      --INI WLO_R189662
      if @i_debug = 'S'
      begin
         print 'Agrupado ' + @w_agrupado 
         select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
         print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
      end
      --FIN WLO_R189662
   
      set rowcount 0 
 
      --BEGIN TRAN --WLO_R189662
      
      update ca_universo_conta set 
      intentos = intentos + 1, 
      hilo     = 100 -- significa Procesado o procesando 
      where agrupado = @w_agrupado  
      and   hilo     = @i_hilo 
      
      --COMMIT TRAN --WLO_R189662
	  
	  set @w_xtercero = 'S' ----GFP 25/02/2022 Para grupacion de comprobantes
   end 
   else
   --TRANSACCIONES POR OPERACION
   begin   
      -- DETERMINAR EL ESTADO DE ADMISION DE COMPROBANTES CONTABLES EN COBIS CONTABILIDAD 
      select @w_estado_prod = pr_estado
      from   cob_conta..cb_producto with (nolock)
      where  pr_empresa  = 1
      and    pr_producto = @w_cod_producto

      -- VALIDA EL PRODUCTO EN CONTABILIDAD 
      if @w_estado_prod not in ('V','E') 
      begin
         select 
         @w_error   = 601018,
         @w_mensaje = ' PRODUCTO NO VIGENTE EN CONTA ' 
         goto ERRORFIN
      end

      -- DETERMINAR EL RANGO DE FECHAS DE LAS TRANSACCIONES QUE SE INTENTARAN CONTABILIZAR 
      /*Solo se contabiliza las transacciones hasta la fecha de cierre de cartera, ya que pueden
      haber transacciones con fecha de mañana o siguiente dia habil por el nuevo esquema de 
      inicio de dia de causaciones de intereses*/

      select @w_fecha_hasta = @w_fecha_proceso

      select @w_fecha_mov   = isnull(min(co_fecha_ini),'01/01/1900')
      from   cob_conta..cb_corte with (nolock)
      where  co_empresa = 1
      and    co_estado in ('A','V')
      and    co_fecha_ini <= @w_fecha_hasta

      if @w_fecha_mov = '01/01/1900' 
      begin
         select 
         @w_error   = 601078,
         @w_mensaje = ' ERROR NO EXISTEN PERIODOS DE CORTE ABIERTOS ' 
         goto ERRORFIN
      end

      -- DETERMINAR CODIGO DE BANCAMIA PARA EMPLEADOS
      select @w_bancamia  = convert(varchar(24),pa_int)
      from   cobis..cl_parametro
      where  pa_nemonico = 'CCBA'
      and    pa_producto = 'CTE'

      delete ca_conta_trn_tmp
      where ct_operacion = @w_operacionca
 
      -- CARGAR TRANSACCIONES DE LA OPERACION
      insert into ca_conta_trn_tmp    
      select ct_operacion        = tr_operacion,
             ct_secuencial       = tr_secuencial,     
             ct_banco            = tr_banco, 
             ct_agrupado         = isnull(rtrim(tr_tran), '') + '-' + isnull(rtrim(tr_banco), '') + '-' + isnull(rtrim(convert(varchar,tr_secuencial)),''),
             ct_tran             = convert(varchar(10), tr_tran),
             ct_ofi_usu          = tr_ofi_usu,     
             ct_ofi_oper         = op_oficina,   --tr_ofi_oper, KDR Se toma ofi actual del préstamo (la trn podría tener una oficina distinta si el préstamo tubo un traslado de oficina)       
             ct_toperacion       = convert(varchar(10), tr_toperacion),     
             ct_fecha_mov        = tr_fecha_mov,
             ct_fecha_ref        = tr_fecha_ref,
             ct_perfil           = to_perfil,
             ct_sector           = convert(varchar(10), op_sector),
             ct_moneda           = tr_moneda,
             ct_gar_admisible    = case when isnull(op_gar_admisible,'N') = 'S' then 'I' else 'O' end,
             ct_calificacion     = isnull(ltrim(rtrim(op_calificacion)), 'A'),
             ct_clase            = op_clase,
             ct_cliente          = op_cliente,
             ct_tramite          = op_tramite,
             ct_categoria        = dt_categoria,
             ct_entidad_convenio = case when dt_entidad_convenio = @w_bancamia then '1' else '0' end,
             ct_subtipo_linea    = op_subtipo_linea,
             ct_concepto         = '',
             ct_codvalor         = 0,
             ct_monto            = 0,
             ct_monto_mn         = 0,
             ct_cotizacion       = 0,
			 ct_reestructuracion = tr_reestructuracion,
			 ct_categoria_plazo = oda_categoria_plazo
      from   ca_operacion, ca_default_toperacion,ca_tipo_trn, ca_operacion_datos_adicionales,ca_transaccion T LEFT JOIN ca_trn_oper O ON T.tr_toperacion = O.to_toperacion and T. tr_tran = to_tipo_trn
      where  op_operacion   = @w_operacionca
      and    op_operacion   = tr_operacion
      and    tr_tran        > ''
      and    tr_estado      = 'ING'
      and    tr_fecha_mov  <= @w_fecha_hasta
      and    tr_fecha_mov  >= @w_fecha_mov
      and    tr_ofi_usu    >= 1
      and    tr_tran   not in ('PRV','REJ','MIG','HFM','VEN') --LPO TEC Se exluye transaccion VEN
      and    tr_operacion   = op_operacion
      and    op_toperacion  = dt_toperacion
      and    op_moneda      = dt_moneda
	  and    tr_tran        = tt_codigo  --GFP Se ingresa por validacion transaccion contabilizable si o no
	  and    tt_contable    = 'S'
	  and    op_operacion   = oda_operacion
      union all
      select ct_operacion        = case when tp_operacion < 0 then tp_operacion * -1 else tp_operacion end, --GFP 25/03/22
             ct_secuencial       = tp_secuencial_ref,     
             ct_banco            = op_banco, 
             ct_agrupado         = 'PRV-' + isnull(rtrim(op_banco),'') + '-Sec' + isnull(rtrim(convert(varchar,tp_secuencial_ref)),'')+ '-Rub' + isnull(rtrim(convert(varchar,tp_concepto)),'') + --GFP 25/03/22
			                        '-Fec' + isnull(rtrim(convert(varchar,tp_fecha_mov,101)),'') + '-CodVal' + isnull(rtrim(convert(varchar,tp_codvalor )),'') +'-Reest' + convert(varchar,tp_reestructuracion),
             ct_tran             = 'PRV',
             ct_ofi_usu          = op_oficina, -- tp_ofi_oper, 
             ct_ofi_oper         = op_oficina, -- tp_ofi_oper,       
             ct_toperacion       = convert(varchar(10), op_toperacion),     
             ct_fecha_mov        = tp_fecha_mov,
             ct_fecha_ref        = tp_fecha_ref,
             ct_perfil           = to_perfil,
             ct_sector           = convert(varchar(10), op_sector),
             ct_moneda           = op_moneda,
             ct_gar_admisible    = case when isnull(op_gar_admisible,'N') = 'S' then 'I' else 'O' end,
             ct_calificacion     = isnull(ltrim(rtrim(op_calificacion)), 'A'),
             ct_clase            = op_clase,
             ct_cliente          = op_cliente,
             ct_tramite          = op_tramite,
             ct_categoria        = dt_categoria,
             ct_entidad_convenio = case when dt_entidad_convenio = @w_bancamia then '1' else '0' end,
             ct_subtipo_linea    = op_subtipo_linea,
             ct_concepto         = tp_concepto,
             ct_codvalor         = tp_codvalor,
             ct_monto            = sum(tp_monto),
             ct_monto_mn         = sum(tp_monto_mn),
             ct_cotizacion       = tp_cotizacion,
			 ct_reestructuracion = tp_reestructuracion,
			 ct_categoria_plazo = oda_categoria_plazo
      from   ca_transaccion_prv, ca_default_toperacion,ca_operacion_datos_adicionales, ca_operacion O LEFT JOIN ca_trn_oper T ON O.op_toperacion = T.to_toperacion and T.to_tipo_trn = 'PRV'
      where  op_operacion   = @w_operacionca
      and    (tp_operacion   = op_operacion OR tp_operacion * -1  = op_operacion )  --GFP 25/03/22
      and    tp_estado      = 'ING'
      and    tp_fecha_mov  <= @w_fecha_hasta
      and    tp_fecha_mov  >= @w_fecha_mov
      and    op_toperacion  = dt_toperacion
      and    op_moneda      = dt_moneda
      and    to_tipo_trn    = 'PRV'
	  and    op_operacion   = oda_operacion
	  group by tp_operacion, tp_secuencial_ref,op_banco, op_oficina, op_toperacion, tp_fecha_mov, tp_fecha_ref,
	           to_perfil,op_sector,op_moneda,op_gar_admisible,op_calificacion,op_clase,op_cliente,op_tramite,
	           dt_categoria, dt_entidad_convenio,op_subtipo_linea,tp_concepto,tp_codvalor,tp_cotizacion,tp_reestructuracion,
			   oda_categoria_plazo
   end

   truncate table #ca_conta_trn_tmp 
   
   if @i_banco is not null
      insert into #ca_conta_trn_tmp
      select ct_operacion, ct_secuencial,       ct_banco,         ct_agrupado,  ct_tran,     ct_ofi_usu, 
             ct_ofi_oper,  ct_toperacion,       ct_fecha_mov,     ct_fecha_ref, ct_perfil,   ct_sector,
             ct_moneda,    ct_gar_admisible,    ct_calificacion,  ct_clase,     ct_cliente,  ct_tramite, 
             ct_categoria, ct_entidad_convenio, ct_subtipo_linea, ct_concepto,  ct_codvalor, ct_monto,
			 ct_reestructuracion
      from   ca_conta_trn_tmp with (nolock)
      where  ct_operacion  = @w_operacionca
   else
   begin
      set rowcount 1
      
      insert into #ca_conta_trn_tmp
      select       ct_operacion, ct_secuencial,       ct_banco,         ct_agrupado,  ct_tran,     ct_ofi_usu, 
                   ct_ofi_oper,  ct_toperacion,       ct_fecha_mov,     ct_fecha_ref, ct_perfil,   ct_sector,
                   ct_moneda,    ct_gar_admisible,    ct_calificacion,  ct_clase,     ct_cliente,  ct_tramite, 
                   ct_categoria, ct_entidad_convenio, ct_subtipo_linea, ct_concepto,  ct_codvalor, ct_monto,
				   ct_reestructuracion
      from   ca_conta_trn_tmp with (nolock)
      where  ct_agrupado = @w_agrupado
      
      set rowcount 0
   end

   -- CARGA LAS TRANSACCIONES A PROCESAR 
   declare cursor_tran cursor read_only for --WLO_R189662
   select ct_operacion, ct_agrupado, ct_tran,   ct_ofi_usu,  ct_ofi_oper, ct_toperacion, ct_fecha_mov, 
          ct_perfil,    ct_sector,   ct_moneda, ct_concepto, ct_codvalor, ct_monto,      ct_fecha_ref,
		  ct_reestructuracion
   from   #ca_conta_trn_tmp 

   open  cursor_tran
   fetch cursor_tran 
   into  @w_operacionca, @w_agrupado, @w_tran_cur,  @w_of_origen_cur, @w_op_oficina, @w_toperacion, @w_fecha_mov, 
         @w_perfil,      @w_sector,   @w_op_moneda, @w_dtr_concepto,  @w_dtr_codval, @w_dtr_monto,  @w_fecha_ref,   
         @w_reestructuracion
   while @@fetch_status = 0 
   begin         
      -- VARIABLES INICIALES
      select  
      @w_asiento        = 0,
      @w_tot_credito    = 0,
      @w_tot_debito     = 0,
      @w_tot_credito_me = 0,
      @w_tot_debito_me  = 0,
      @w_mensaje        = '',
      @w_cuenta_final   = '',
      @w_reverso        = 'N',
      @w_comprobante    = 0,
      @w_cliente_al     = null,
      @w_secuencial     = 0,
	  @w_tipo_rubro     = null,
	  @w_originacion    = null
	  
      -- LEER DATOS RESTANTES  
      if @i_banco IS NOT NULL 
      or @w_tran_cur <> 'PRV'
      begin
         select 
         @w_secuencial       = ct_secuencial,
         @w_banco            = ct_banco,
         @w_fecha_val        = ct_fecha_ref,
         @w_gar_admisible    = ct_gar_admisible,
         @w_calificacion     = ct_calificacion,
         @w_clase_cart       = ct_clase,
         @w_ente             = ct_cliente,
         @w_op_origen_fondos = ct_categoria,
         @w_entidad_convenio = ct_entidad_convenio,
         @w_tramite          = ct_tramite,   
         @w_subtipo_cart     = ct_subtipo_linea
         from   ca_conta_trn_tmp with (nolock)
         where  ct_agrupado = @w_agrupado
         
         if @w_secuencial < 0 select @w_reverso = 'S'
      end
   
      -- CONCEPTO DEL COMPROBANTE 
      select @w_descripcion = 'Ban:'+ isnull(ltrim(rtrim(@w_banco)),'')              + ' ' +
                              'Sec:' + isnull(convert(varchar,@w_secuencial),'')     + ' ' +
                              'Trn:' + isnull(ltrim(rtrim(@w_tran_cur)),'')          + ' ' +   
                              'Rev:' + isnull(convert(char(1),@w_reverso),'')        + ' ' +
                              'TOp:' + isnull(ltrim(rtrim(@w_toperacion)),'')        + ' ' +
                              'FVa:' + isnull(convert(varchar(10),@w_fecha_val,103),'')   

      -- VALIDAR RELACION TRANSACCION - PERFIL CONTABLE
      if @w_perfil IS NULL
      begin 
         select 
         @w_error   = 701148,
         @w_mensaje = ' ERROR NO EXISTE TRN ' + isnull(@w_tran_cur,'') + ' PARA EL TOp:' + isnull(@w_toperacion,'') + ' EN LA TABLA ca_trn_oper'
         goto ERROR1
      end							  
                
      if @i_debug = 'S'
      begin
         print ''
         print 'CONTABILIZANDO... ' + @w_descripcion 
         select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())                 --WLO_R189662
         print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo) --WLO_R189662
      end

      -- CONTABILIDAD ELIMINADA... MARCAR REGISTRO COMO CONTABILIZADO
      if @w_estado_prod = 'E' 
      begin
         select @w_comprobante = -1  -- Contabilidad eliminada
         goto MARCAR
      end

      -- VALIDAR QUE EXISTA PERFIL CONTABLE
      if not exists (select 1 
                     from   cob_conta..cb_perfil with (nolock)
                     where  pe_empresa  = 1
                     and    pe_producto = @w_cod_producto
                     and    pe_perfil   = @w_perfil) 
      begin
         select 
         @w_error   = 701148,
         @w_mensaje = ' ERROR NO EXISTE PERFIL ' + @w_perfil + ' EN LA TABLA cb_perfil'
         goto ERROR1
      end
            
      -- LIMPIAR TABLA DE DETALLES DE TRANSACCION
      truncate table #detalles
      truncate table #detalles_prv

      -- INSERTAR TABLA DE DETALLES DE TRANSACCION 
      if @w_tran_cur = 'PRV' --and @i_banco IS NULL 
      begin

         /*Las transacciones PRV que no tienen parametrizaco su codigo valor en el perfil contable, se las debe excluir
         de la tabla ca_conta_trn_tmp y reportar como error, para que no se queden como contabilizadas al final en MARCAR*/
         truncate table #provision_sincodval
		 
		 select @w_tipo_rubro = ru_tipo_rubro from cob_cartera..ca_rubro with (nolock) --WLO_R189662
         where ru_toperacion  = @w_toperacion
         and   ru_concepto    = @w_dtr_concepto
         
         if ( @w_contabilizar_mora = 'N' and @w_tipo_rubro = 'M' )
         begin 
            goto SIGUIENTE
         end
		 else 
         begin
            insert into #provision_sincodval
            select ct_banco, 'No existe el codigo valor ' + convert(varchar,ct_codvalor) + ' en el perfil ' + ct_perfil + ' rubro ' + ct_concepto, 
                   ct_agrupado, ct_operacion, ct_codvalor, ct_fecha_ref
            from ca_conta_trn_tmp with (nolock)
            where  ct_agrupado   = @w_agrupado
            and   abs(ct_monto) >= 0.01
            and   ct_codvalor not in ( select  distinct dp_codval from cob_conta..cb_det_perfil with (nolock) --WLO_R189662
                                       where dp_empresa  = 1
                                       and   dp_perfil   = @w_perfil
                                       and   dp_producto = @w_cod_producto ) -- cartera
            and   ct_fecha_ref = @w_fecha_ref
         end
		 
         if (select count(1) from #provision_sincodval) > 0
         begin
            insert into ca_errorlog 
            select @w_fecha_mov, 701148, @s_user, 7000, ps_banco, ps_descripcion, null
            from #provision_sincodval

            delete ca_conta_trn_tmp
            from #provision_sincodval
            where ct_operacion = ps_operacion
            and   ct_agrupado  = ps_agrupado
            and   ct_codvalor  = ps_codvalor
			   and   ct_fecha_ref = ps_fecha_ref

            --INI WLO_R189662
            if @i_debug = 'S'
            begin
               print 'Error --> PRV agrupado: ' + @w_agrupado 
               select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
               print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
            end
            --FIN WLO_R189662
            --goto MARCAR
         end

         -- TRANSACCIONES AGRUPADAS
         --SET IDENTITY_INSERT #detalles_prv OFF
          
         -- PRV AGRUPADA POR TERCERO
         if @w_xtercero = 'S'
         begin
            insert into #detalles_prv 
            (de_banco,                de_toperacion,              de_operacion, 
             de_concepto,             de_codvalor,                de_moneda,      
             de_monto,                de_ref_iva,                 de_maxfec_iva, 
             de_porc_iva,             de_valor_base,              de_cuenta,  
             de_debcred,              de_constante,               de_origen_dest,
             de_area,                 de_tipo_area,               de_oficina,   
             de_clave,                de_cuenta_final,            de_debito,      
             de_credito,              de_con_iva,                 de_fecha_mov,  
             de_sector,               de_gar_admisible,           de_calificacion, 
             de_clase,                de_cliente,                 de_ent_convenio,
             de_subtipo_linea,        de_monto_mn,                de_cotizacion,
             de_debito_me,            de_credito_me,              de_estado,
			 de_reestructuracion,     de_categoria_plazo,         de_originacion)
            select
             ct_banco,                ct_toperacion,              ct_operacion,  
             ct_concepto,             ct_codvalor,                ct_moneda,
             round(sum(ct_monto),2),  convert(varchar(10),'N/A'), convert(datetime, '01/01/1900'),
             convert(float,0.0),      convert(money,0),           dp_cuenta,               
             dp_debcred,              dp_constante,               dp_origen_dest,           
             dp_area,                 dp_area,                    ct_ofi_oper,
             convert(varchar(40),''), convert(varchar(40),''),    convert(money,0),
             convert(money,0),        'N',                        ct_fecha_mov,
             ct_sector,               ct_gar_admisible,           ct_calificacion, 
             ct_clase,                ct_cliente,                 ct_entidad_convenio,
             ct_subtipo_linea,        round(sum(ct_monto_mn),2),  ct_cotizacion,
             0,                       0,                          0,
			 isnull(ct_reestructuracion,'N'),     ct_categoria_plazo,         ''
            from   ca_conta_trn_tmp with (nolock) , cob_conta..cb_det_perfil with (nolock) --WLO_R189662
            where  ct_agrupado    = @w_agrupado
            and    dp_empresa     = 1
            and    dp_producto    = @w_cod_producto  -- cartera
            and    dp_perfil      = @w_perfil
            and    dp_codval      = ct_codvalor 
            and    abs(ct_monto) >= 0.01
            group by ct_banco,    ct_operacion,  ct_agrupado,         ct_tran,          ct_ofi_usu, 
                     ct_ofi_oper, ct_toperacion, ct_fecha_mov,        ct_perfil,        ct_sector, 
                     ct_moneda,   ct_concepto,   ct_codvalor,         ct_gar_admisible, ct_calificacion, 
                     ct_clase,    ct_cliente,    ct_entidad_convenio, ct_subtipo_linea, dp_cuenta, 
                     dp_debcred,  dp_constante,  dp_origen_dest,      dp_area,          ct_cotizacion,
					 ct_reestructuracion, ct_categoria_plazo
            having round(sum(ct_monto),2) <> 0.00 --WLO_R191094
            if @@rowcount = 0 
               goto MARCAR
         end
         else
         -- PRV AGRUPADA SIN TERCERO
         begin
            insert into #detalles_prv
            (de_banco,                de_toperacion,              de_operacion, 
             de_concepto,             de_codvalor,                de_moneda,      
             de_monto,                de_ref_iva,                 de_maxfec_iva, 
             de_porc_iva,             de_valor_base,              de_cuenta,  
             de_debcred,              de_constante,               de_origen_dest,
             de_area,                 de_tipo_area,               de_oficina,   
             de_clave,                de_cuenta_final,            de_debito,      
             de_credito,              de_con_iva,                 de_fecha_mov,  
             de_sector,               de_gar_admisible,           de_calificacion, 
             de_clase,                de_cliente,                 de_ent_convenio,
             de_subtipo_linea,        de_monto_mn,                de_cotizacion,
             de_debito_me,            de_credito_me,              de_estado,
			 de_reestructuracion,     de_categoria_plazo,         de_originacion)
            select
             ct_banco,                ct_toperacion,              ct_operacion,  
             ct_concepto,             ct_codvalor,                ct_moneda,
             round(sum(ct_monto),2),  convert(varchar(10),'N/A'), convert(datetime, '01/01/1900'),
             convert(float,0.0),      convert(money,0),           dp_cuenta,               
             dp_debcred,              dp_constante,               dp_origen_dest,           
             dp_area,                 dp_area,                    ct_ofi_oper,
             convert(varchar(40),''), convert(varchar(40),''),    convert(money,0),
             convert(money,0),        'N',                        ct_fecha_mov,
             ct_sector,               ct_gar_admisible,           ct_calificacion, 
             ct_clase,                0,                          ct_entidad_convenio,
             ct_subtipo_linea,        round(sum(ct_monto_mn),2),  ct_cotizacion,
             0,                       0,                          0,
			 isnull(ct_reestructuracion,'N'),     ct_categoria_plazo,         ''
            from   ca_conta_trn_tmp with (nolock) , cob_conta..cb_det_perfil with (nolock) --WLO_R189662
            where  ct_agrupado    = @w_agrupado
            and    dp_empresa     = 1 
            and    dp_producto    = @w_cod_producto  -- cartera
            and    dp_perfil      = @w_perfil
            and    dp_codval      = ct_codvalor 
            and    abs(ct_monto) >= 0.01
			and    ct_fecha_ref   = @w_fecha_ref  ----GFP 25/02/2022 Para generación de comprobantes individuales
            group by ct_agrupado,      ct_tran,          ct_ofi_usu,      ct_ofi_oper,  ct_toperacion, 
                     ct_fecha_mov,     ct_perfil,        ct_sector,       ct_moneda,    ct_concepto,   
                     ct_codvalor,      ct_gar_admisible, ct_calificacion, ct_clase,     ct_entidad_convenio, 
                     ct_subtipo_linea, dp_cuenta,        dp_debcred,      dp_constante, dp_origen_dest,      
                     dp_area,          ct_cotizacion,    ct_reestructuracion, ct_categoria_plazo,
					 ct_banco,         ct_operacion
            having round(sum(ct_monto),2) <> 0.00 --WLO_R191094
            if @@rowcount = 0 
               goto MARCAR
         end	 
      end      
      else
      begin
         -- TRANSACCION INDIVIDUAL   
         insert into #detalles
         select dtr_concepto,      dtr_codvalor,  dtr_moneda,     dtr_cuenta,
                sum(dtr_monto),    dtr_dividendo, dtr_secuencial, dtr_operacion,
                sum(dtr_monto_mn), dtr_cotizacion,dtr_estado
         from   ca_det_trn with (nolock)
         where  dtr_secuencial = @w_secuencial
         and    dtr_operacion  = @w_operacionca
         group by dtr_concepto, dtr_codvalor, dtr_moneda, dtr_cuenta, dtr_dividendo, dtr_secuencial, dtr_operacion,
                  dtr_cotizacion,dtr_estado

         if @@rowcount = 0 
            goto MARCAR
            
         -- SI SE TRATA DE UNA REVERSA DE TRANSACCION
         if @w_reverso = 'S'
            select @w_factor = -1
         else
            select @w_factor = 1            

         if @w_tran_cur in ('PAG','EST','ETM')
         begin
            update #detalles set dtr_codvalor = dtr_codvalor 
            from   ca_dividendo with (nolock) --WLO_R189662
            where  dtr_secuencial  = @w_secuencial
            and    dtr_operacion   = @w_operacionca 
            and    di_operacion    = dtr_operacion
            and    di_dividendo    = dtr_dividendo
            and    di_fecha_ven    < @w_fecha_val
            and    dtr_codvalor%10 = 0
            and    dtr_codvalor   >= 10000
       
            if @@error <> 0
            begin
               select 
               @w_error   = 701148,
               @w_mensaje = ' ERROR ACTUALIZACION CODIGO VALOR EXIGIBLE/NO EXIGIBLE' 
               goto ERROR1
            end
         end
      end
      
      -- VALIDACION Y GENERACION DE NUMERO DE COMPROBANTE
      if @w_fecha_mov = @w_fecha_proceso and @i_banco is null
         select @w_comprobante = @w_comprobante_base
      else 
      begin
         BEGIN TRAN
         
         /* RESERVAR UN RANGO DE COMPROBANTES */
         exec @w_error = cob_conta..sp_cseqcomp
         @i_tabla     = 'cb_scomprobante', 
         @i_empresa   = 1,
         @i_fecha     = @w_fecha_proceso, --GFP 10/06/2022
         @i_modulo    = 7,
         @i_modo      = 0, -- Numera por EMPRESA-FECHA-PRODUCTO
         @o_siguiente = @w_comprobante out

         if @w_error = 0 
            COMMIT TRAN
         else
         begin
            ROLLBACK TRAN
            select 
            @w_mensaje = ' ERROR AL GENERAR NUMERO COMPROBANTE ' 
            goto ERROR1
         end
      end

      if @i_debug = 'S' 
      begin
         print '   @w_comprobante: ' + cast(@w_comprobante as varchar)
         print '   @w_perfil:      ' + @w_perfil
         select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())                 --WLO_R189662
         print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo) --WLO_R189662
      end

      -- INICIALIZAR TRANSACCIONALIDAD
      BEGIN TRAN 
      select @w_commit = 'S'

--      if @i_banco IS NOT NULL 
--      or (@i_banco IS NULL and @w_tran_cur <> 'PRV')

      if @w_tran_cur <> 'PRV'
      begin
         -- TRANSACCIONES INDIVIDUALES
         -- CURSOR PARA OBTENER LOS DETALLES DEL PERFIL RESPECTIVO
          --si no existe el codigo valor en el perfil, se genera el outer join para que ingrese y reportarlo 
          -- com error y que no se quede como contabilizada la transaccion
         select @w_dtr_codval = -1, @w_dtr_codval_trn = null

         declare cursor_perfil cursor for 
         select dtr_concepto, isnull(dp_codval,-1), dtr_codvalor,  dtr_moneda,  
                dtr_cuenta,   dp_cuenta,      dp_debcred,        
                dp_constante, dp_origen_dest, dp_area,
                dtr_monto,    dtr_monto_mn,   dtr_cotizacion,
				dtr_estado
         from   #detalles
         left outer join cob_conta..cb_det_perfil on dp_codval = dtr_codvalor 
         and    dp_empresa      = 1
         and    dp_producto     = @w_cod_producto  --cartera
         and    dp_perfil       = @w_perfil
         where  abs(dtr_monto) >= power(convert(float, 10), isnull(@w_num_dec_mn, 0) * -1)
      
         open  cursor_perfil
         fetch cursor_perfil 
         into  @w_dtr_concepto, @w_dtr_codval,     @w_dtr_codval_trn, @w_dtr_moneda,
               @w_dtr_cuenta,   @w_dp_cuenta,      @w_dp_debcred,       
               @w_dp_constante, @w_dp_origen_dest, @w_dp_area,          
               @w_dtr_monto,    @w_dtr_monto_mn,   @w_cotizacion,
			   @w_dtr_estado

         while @@fetch_status = 0 
         begin
            if @i_debug = 'S' 
            begin
               print '    RUBRO:  ' + @w_dtr_concepto    
               print '    Param:  ' + @w_dp_cuenta
               print '    CodVal: ' + cast(@w_dtr_codval as varchar)
               print '    Sector: ' + @w_sector
               print '    Perfil: ' + @w_perfil
               print '    ClaCart:' + @w_clase_cart
               print '    Subtipo:' + @w_subtipo_cart
               print '    TipoOpe:' + @w_toperacion
               print '    Total:  ' + cast(@w_secuencial as varchar)
               print '    Of_orig:' + cast(@w_of_origen_cur as varchar)
               print '    Of_dest:' + cast(@w_op_oficina as varchar)
	           print '    Monto:  ' + cast(@w_dtr_monto as varchar)
               select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())                 --WLO_R189662
               print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo) --WLO_R189662
            end

            if @w_dtr_codval = -1  --No existe el codigo valor en el perfil
            begin 
               select @w_tipo_rubro = ru_tipo_rubro from cob_cartera..ca_rubro with (nolock) --WLO_R189662
               where ru_toperacion  = @w_toperacion
               and   ru_concepto    = @w_dtr_concepto
               
               if ( @w_contabilizar_mora = 'N' and @w_tipo_rubro = 'M' )
               begin 
                  goto SIGUIENTE_PERFIL
               end
               else
               begin
                  select 
                  @w_mensaje  = 'No existe el codigo valor ' + convert(varchar,@w_dtr_codval_trn) + ' del rubro ' + @w_dtr_concepto + ' en el perfil ' + @w_perfil,
                  @w_error    = 701148
                  close cursor_perfil
                  deallocate cursor_perfil
                  goto ERROR1
               end
            end

            select 
            @w_debito         = 0.00,
            @w_debito_me      = 0.00,
            @w_credito        = 0.00,
            @w_credito_me     = 0.00,
            @w_dtr_concepto   = ltrim(rtrim(@w_dtr_concepto)),
            @w_con_iva        = 'N',
            @w_conret         = 'N',  
            @w_valor_base     = 0,
            @w_con_timbre     = 'N',
            @w_valor_timbre   = 0,
            @w_valor_ref      = null,
            @w_afecta         = null,
            @w_porcentaje_iva = 0,
            @w_dtr_monto      = @w_dtr_monto * @w_factor
      
            select @w_re_area = ta_area 
            from   cob_conta..cb_tipo_area with (nolock)
            where  ta_tiparea  = @w_dp_area
            and    ta_empresa  = 1
            and    ta_producto = 7
      
            if @@rowcount = 0 select @w_re_area = @w_ar_origen

            /* CONCEPTO DEL ASIENTO */
            select @w_concepto = @w_descripcion

            if @w_operacionca > 0
	           select @w_concepto = @w_concepto +
               ' Cpt:'  + isnull(@w_dtr_concepto,'') +
               ' CVa:'  + isnull(convert(varchar,@w_dtr_codval),'')

            -- TRANSACCION REALIZADA POR SERVICIOS BANCARIOS 
/*         
            if @w_tran_cur = 'DES' 
            begin
               select @w_idlote = 0
            
               select @w_idlote = isnull(dm_idlote,0)
               from   ca_desembolso with (nolock)
               where  isnull(dm_idlote ,0) > 0
               and    dm_producto = @w_dtr_concepto
               and    dm_estado   = 'A'
               and    dm_secuencial = @w_secuencial
               and    dm_operacion  = @w_operacionca       
                  
               if @w_idlote > 0 
               begin
                  exec @w_error = cob_sbancarios..sp_qry_num_inst
                  @i_sec        = @w_idlote,
                  @i_interfaz   = 'S',
                  @o_numero     = @w_cheque out
            
                  if @w_error <> 0 
                  begin
                     select 
                     @w_mensaje  = ' ERR CONSULTA CHEQUE ENTREGADO POR DESEMBOLSO' + '-',
                     @w_error    = 710004
                     close cursor_perfil
                     deallocate cursor_perfil
                     goto ERROR1
                  end
            
                  if @w_cheque is null 
                  begin
                     select 
                     @w_mensaje  = ' ERR CONSULTA CHEQUE ENTREGADO POR DESEMBOLSO VALOR NULO' + '-',
                     @w_error    = 710004
                     close cursor_perfil
                     deallocate cursor_perfil
                     goto ERROR1
                  end            
            
                  select @w_concepto = @w_concepto + ' Chq:' + isnull(convert(varchar(24),@w_cheque), '')
                  select @w_descripcion = @w_descripcion + ' Chq:'  + isnull(convert(varchar(24),@w_cheque), '')
               end  
               else 
               begin 
                  select @w_dm_producto = null
                  select @w_dm_producto = dm_producto 
                  from   ca_desembolso with (nolock)
                  where  isnull(dm_idlote ,0) = 0
                  and    dm_producto   = @w_dtr_concepto
                  and    dm_estado     = 'A'
                  and    dm_secuencial = @w_secuencial
                  and    dm_operacion  = @w_operacionca      

                  -- Si  no existe el desembolso se consulta la transaccion para encontrar el concepto
                  -- en caso de ser un reverso
                  if  @w_dm_producto is null
                      select @w_dm_producto = dtr_concepto
                      from   cob_cartera..ca_det_trn
                      where  dtr_secuencial = @w_secuencial
                      and    dtr_operacion  = @w_operacionca 
                      and    dtr_concepto   = 'NCAH_FINAN'
             
                  -- Se toma el ente de la alianza para el desemboolso
                  if @w_dm_producto = 'NCAH_FINAN' 
                  begin 
                     select @w_cliente_al = NULL
                  
                     select @w_cliente_al = convert(varchar(20), al_ente )
                     from   cob_credito..cr_tramite, cobis..cl_alianza, cobis..cl_alianza_cliente
                     where  tr_tramite = @w_tramite
                     and    tr_alianza = al_alianza 
                     and    tr_cliente = ac_ente
                     and    tr_alianza = al_alianza 
                  end
               end
            end
*/

            -- CONTABILIDAD DE IMPUESTOS (SOLO PARA RUBROS TIPO IVA)
            select @w_categoria = co_categoria 
            from   ca_concepto with (nolock)
            where  co_concepto  = @w_dtr_concepto

            select @w_referencial_iva = ru_referencial
            from   ca_rubro with (nolock)
            where  ru_concepto   = @w_dtr_concepto
            and    ru_toperacion = @w_toperacion

            select @w_maxfecha_iva = max(vr_fecha_vig)
            from   ca_valor_referencial with (nolock)
            where  vr_tipo = @w_referencial_iva

            select @w_porcentaje_iva = vr_valor
            from   ca_valor_referencial with (nolock)
            where  vr_tipo      = @w_referencial_iva
            and    vr_fecha_vig = @w_maxfecha_iva
      
            select @w_montodes = ro_base_calculo
            from   ca_rubro_op with (nolock) --WLO_R189662
            where  ro_operacion = @w_operacionca
            and    ro_concepto  = @w_dtr_concepto
      
            if @w_categoria ='A'
            begin         
               select @w_con_iva = 'S'
               select @w_porcentaje_iva = isnull(@w_porcentaje_iva,0)         
            
               if @w_porcentaje_iva > 0.01 
                  select @w_valor_base=isnull(@w_dtr_monto,0)/(@w_porcentaje_iva*0.01)
               
               select @w_valret = null      
            end
         
            if @w_categoria = 'T'  
            begin         
               select @w_conret  = 'S'
               select @w_porcentaje_iva = isnull(@w_porcentaje_iva,0)         
            
               if @w_porcentaje_iva > 0 
               begin
                  select @w_valret     = @w_dtr_monto
                  select @w_valor_base = @w_montodes
               end      
            end

            -- REVERSAS EN CASO DE NEGATIVOS, INVERTIR SIGNOS DEL ASIENTO
            if @w_dtr_monto < 0 
            begin
               if @w_dp_debcred = '2' select @w_dp_debcred = '1'   
               else select @w_dp_debcred = '2'   
               
               select @w_dtr_monto = -1 * @w_dtr_monto
            end

            select @w_debcred = convert(int,@w_dp_debcred)
   
            -- DETERMINAR MONTO EN MONEDA NACIONAL */         
            if @w_dtr_moneda <> @w_mon_nac 
            begin
               if (@w_dtr_monto_mn = 0 or @w_cotizacion = 0)
               begin
                  exec @w_error = sp_buscar_cotizacion
                  @i_moneda     = @w_dtr_moneda,
                  @i_fecha      = @w_fecha_proceso,
                  @o_cotizacion = @w_cotizacion output
         
                  if @w_error <> 0 
                  begin      
                     select 
                     @w_mensaje  = 'Error en Busqueda Cotizacion',
                     @w_error    = 701070
                     close cursor_perfil
                     deallocate cursor_perfil
                     goto ERROR1
                  end
            
                  select @w_dtr_monto_mn = round(@w_cotizacion * @w_dtr_monto,2)
               end
            end 
            else 
            begin
               select 
               @w_cotizacion   = 1,
               @w_dtr_monto_mn = @w_dtr_monto                    
            end

            -- DETERMINAR VALORES DE DEBITO Y CREDITO EN MONEDA NACIONAL 
            select
            @w_debito  = @w_dtr_monto_mn*(2-@w_debcred),
            @w_credito = @w_dtr_monto_mn*(@w_debcred-1)
      
            -- DETERMINAR VALORES DE DEBITO Y CREDITO EN MONEDA EXTRANJERA 
--            if  @w_dp_constante = 'T' 
--            and @w_dtr_moneda  <> @w_mon_nac
            if @w_dtr_moneda  <> @w_mon_nac
               select
               @w_debito_me  = @w_dtr_monto * (2-@w_debcred),
               @w_credito_me = @w_dtr_monto * (@w_debcred-1)
            else
               select 
               @w_debito_me  = 0.00,
               @w_credito_me = 0.00

            select @w_moneda_as = @w_dtr_moneda

            -- FORZAR MONEDA LOCAL SEGUN CORRESPONDA 
/*            if @w_dp_constante = 'L' 
               select 
               @w_moneda_as  = @w_mon_nac,
               @w_debito_me  = 0.00,
               @w_credito_me = 0.00
            else
               select @w_moneda_as = @w_dtr_moneda
*/
            /* DETERMINAR OFICINA A LA QUE SE CONTABILIZARA */
            if @w_dp_origen_dest = 'O' 
               select @w_oficina = @w_of_origen_cur
            if @w_dp_origen_dest = 'D' and @w_tran_cur <> 'TCO'
               select @w_oficina = @w_op_oficina
            if @w_dp_origen_dest = 'D' and @w_tran_cur = 'TCO'
               select @w_oficina = convert(int,@w_dtr_cuenta) -- GFP Se cambia a campo dtr_cuenta que tener codigo de oficina origen y destino
            if @w_dp_origen_dest = 'C' 
               select @w_oficina = ta_ofi_central
               from   cob_conta..cb_tipo_area with (nolock) --WLO_R189662
               where  ta_empresa  = 1
               and    ta_producto = @w_cod_producto
               and    ta_tiparea  = @w_dp_area

            -- DETERMINAR LA CUENTA CONTABLE DONDE REGISTRAR EL ASIENTO 
            if substring(@w_dp_cuenta,1,1) in ('1','2','3','4','5','6','7','8','9','0')
               select @w_cuenta_final   = @w_dp_cuenta
            else 
            begin
               select @w_stored = pa_stored
               from   cob_conta..cb_parametro with (nolock)
               where  pa_empresa   = 1
               and    pa_parametro = @w_dp_cuenta
   
               if @@rowcount = 0 
               begin
                  select 
                  @w_mensaje  = ' ERR NO EXISTE TABLA DE CUENTAS ' +  @w_dp_cuenta + '(cb_parametro)',
                  @w_error    = 701102
                  close cursor_perfil
                  deallocate cursor_perfil
                  goto ERROR1
               end
         
               if @w_tran_cur = 'TLI' 
                  select @w_entidad_convenio = convert(int, @w_dtr_cuenta)

               if @w_dtr_concepto = 'SOBRANTE'
               begin
                  select @w_secuencial_ref = tr_secuencial_ref -- secuencial del RPA
                  from   ca_transaccion with (nolock) --WLO_R189662
                  where  tr_operacion  = @w_operacionca
                  and    tr_secuencial = abs(@w_secuencial)
    
                  set rowcount 1
                          
                  select @w_dtr_concepto = dtr_concepto  -- FORMA DE PAGO
                  from   ca_det_trn with (nolock) --WLO_R189662
                  where  dtr_operacion  = @w_operacionca
                  and    dtr_secuencial = @w_secuencial_ref
                  and    dtr_concepto  <> 'VAC0'
                  
                  set rowcount 0
               end 
			   
			   select @w_oda_grupo_contable = oda_grupo_contable,
			          @w_categoria_plazo    = oda_categoria_plazo
               from ca_operacion_datos_adicionales with (nolock) 
               where oda_operacion = @w_operacionca
			   
			   --GFP Homologacion de estados para pruebas

			   if @w_dtr_estado = @w_est_novigente
			       select @w_dtr_estado = @w_est_vigente
				   
			   if @w_dtr_estado in (@w_est_vencido,@w_est_vencido_prorroga,@w_est_vencido_cobro_admin,@w_est_judicial)
			       select @w_dtr_estado = @w_est_vencido
				   
			   if @w_dtr_estado = @w_est_condonado
			       select @w_dtr_estado =  (@w_dtr_codval / 10) - (((@w_dtr_codval / 10) / 100)*100)

			   if (isnull(@w_reestructuracion,'N') = 'S')
			   begin
			      select @w_originacion = 'E'
			   end
			   else
			   begin
				  
				  -- MCO Cambio para que se contabilice dentro del nivel de cuentas "Originales" a las transacciones 
				  -- que provengan de operaciones que se hayan originado en un trámite de Renovación
				  select @w_originacion = case when (tr_tipo = 'O' or (tr_tipo = 'R' and tr_subtipo = 'R')) then 'O'										   
											   when tr_tipo = 'R' and tr_subtipo in ('N','F')   then 'R-F' end
				  from cob_credito..cr_tramite, ca_operacion with (nolock)
				  where op_tramite = tr_tramite
				  and op_operacion = @w_operacionca
			   end

               if @w_stored = 'sp_ca01_pf'
                  select @w_clave = rtrim(ltrim(isnull(@w_sector,''))) +'.' + rtrim(ltrim(isnull(@w_clase_cart,''))) +'.'+ rtrim(ltrim(isnull(@w_subtipo_cart, '99'))) +'.'+ rtrim(ltrim(isnull(@w_toperacion, '')))
               if @w_stored = 'sp_ca02_pf'   
                  select @w_clave = isnull(convert(varchar,@w_dtr_moneda),'')
               if @w_stored = 'sp_ca03_pf'      
                  select @w_clave = rtrim(ltrim(isnull(@w_clase_cart,''))) +'.'+ rtrim(ltrim(isnull(@w_sector,'')))
               if @w_stored = 'sp_ca04_pf'   
                  select @w_clave = rtrim(ltrim(isnull(@w_dtr_concepto,'')))
               if @w_stored = 'sp_tipo_oper' 
                  select @w_clave = rtrim(ltrim(isnull(@w_toperacion, ''))) --LPO TEC Sp de resolucion de parametros.
               --if @w_stored = 'sp_ca05_pf'    
                  --select @w_clave = @w_toperacion
               --if @w_stored = 'sp_ca06_pf' 
                  --select @w_clave = @w_dtr_cuenta
               --if @w_stored = 'sp_ca07_pf' 
                  --select @w_clave = @w_calificacion +'.'+ @w_gar_admisible +'.'+ @w_clase_cart +'.'+convert(varchar,@w_dtr_moneda) +'.'+ @w_op_origen_fondos + '.' + @w_entidad_convenio
               --if @w_stored = 'sp_ca08_pf' 
                  --select @w_clave = @w_clase_cart +'.'+convert(varchar,@w_dtr_moneda) +'.'+ @w_op_origen_fondos + '.' + @w_entidad_convenio				  
			   --GFP 12/01/2022 Clave de asociacion de sector y grupo contable por garantias
			   if @w_stored = 'sp_ca09_pf'
                  select @w_clave = right('0'+rtrim(ltrim(isnull(@w_sector,''))),2) +'.'+ right('0'+rtrim(ltrim(isnull(@w_oda_grupo_contable, ''))),2) --GFP resolucion de parametro por combinacion de garantia.   
			   if @w_stored = 'sp_ca10_pf'
                  select @w_clave = rtrim(ltrim(@w_clase_cart)) +'.'+ rtrim(ltrim(@w_categoria_plazo))+'.'+ rtrim(ltrim(@w_dtr_estado))+'.'+ rtrim(ltrim(@w_originacion))

               select @w_cuenta_final = isnull(rtrim(ltrim(re_substring)), '')
               from   cob_conta..cb_relparam with (nolock)
               where  re_empresa             = 1
               and    re_parametro           = @w_dp_cuenta
               and    ltrim(rtrim(re_clave)) = @w_clave
                     
               if @@rowcount = 0 select @w_cuenta_final = ''
            end

            if @i_debug = 'S'  
            begin
                print '      Generando asiento... of: ' + cast(@w_oficina      as varchar)
                print '            Nro. Compro......: ' + cast(@w_comprobante  as varchar)
                print '            Cuenta Final.....: ' + cast(@w_cuenta_final as varchar)
                print '            Ente.............: ' + cast(@w_ente         as varchar)
                print '            afect............: ' + cast(@w_dp_debcred   as varchar)
                print '            debito...........: ' + cast(@w_debito       as varchar)
                print '            credito..........: ' + cast(@w_credito      as varchar)
                print '            debito me........: ' + cast(@w_debito_me    as varchar)
                print '            credito me.......: ' + cast(@w_credito_me   as varchar)
                select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())                 --WLO_R189662
                print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo) --WLO_R189662
	        end
      
	        
            -- GENERAR ASIENTO DEL COMPROBANTE 
            if @w_cuenta_final <> '' and @w_credito+@w_debito >= 0.01  
            begin
               select @w_asiento     = @w_asiento + 1        
               select @w_oficina_aux = @w_oficina

               --TOTALIZAR DATOS DE COMPROBANTE
               select 
               @w_tot_credito    = @w_tot_credito    + @w_credito,
               @w_tot_debito     = @w_tot_debito     + @w_debito,
               @w_tot_credito_me = @w_tot_credito_me + @w_credito_me,
               @w_tot_debito_me  = @w_tot_debito_me  + @w_debito_me
			   
         
               /* DETERMINAR OFICINA DESTINO*/
               select @w_re_ofconta = re_ofconta
               from   cob_conta..cb_relofi with (nolock)
               where  re_filial  = 1
               and    re_empresa = 1
               and    re_ofadmin = @w_oficina_aux

               if @@rowcount = 0 
               begin
                  select 
                  @w_mensaje  = 'ERR NO EXISTE OF.CONTABLE (cb_relofi) ' + convert(varchar,@w_oficina) + '- @w_dp_origen_dest ' + CONVERT(VARCHAR,@w_dp_origen_dest) + '-'  ,
                  @w_error    = 701102
                  close cursor_perfil
                  deallocate cursor_perfil
                  goto ERROR1
               end

               if @w_conret = 'S'
                  select @w_dtr_monto = null
				                     
               insert into cob_conta_tercero..ct_sasiento_tmp with (rowlock) (                                                                                                                                              
               sa_producto,        sa_fecha_tran,        sa_comprobante,
               sa_empresa,         sa_asiento,           sa_cuenta,
               sa_oficina_dest,    sa_area_dest,         sa_credito,
               sa_debito,          sa_concepto,          sa_credito_me,
               sa_debito_me,       sa_cotizacion,        sa_tipo_doc,
               sa_tipo_tran,       sa_moneda,            sa_opcion,
               sa_ente,            sa_con_rete,          sa_base,
               sa_valret,          sa_con_iva,           sa_valor_iva,
               sa_iva_retenido,    sa_con_ica,           sa_valor_ica,
               sa_con_timbre,      sa_valor_timbre,      sa_con_iva_reten,
               sa_con_ivapagado,   sa_valor_ivapagado,   sa_documento,
               sa_mayorizado,      sa_con_dptales,       sa_valor_dptales,
               sa_posicion,        sa_debcred,           sa_oper_banco,
               sa_cheque,          sa_doc_banco,         sa_fecha_est, 
               sa_detalle,         sa_error )
               values (
               7,                  @w_fecha_proceso,     @w_comprobante,  --GFP 10/06/2022
               1,                  @w_asiento,           @w_cuenta_final,
               @w_re_ofconta,      @w_re_area,           @w_credito,
               @w_debito,          isnull(@w_concepto,   @w_descripcion), @w_credito_me,
               @w_debito_me,       @w_cotizacion,        'N',
              'A',                 @w_moneda_as,         0,
               @w_ente,            @w_conret,            @w_valor_base,
               @w_valret,          @w_con_iva,           @w_dtr_monto,
               null,               null,                 null,
               null,               null,                 null,
               null,               null,                 @w_banco,
               'N',                null,                 null,
               'S',                @w_dp_debcred,        null,
               null,               @w_cliente_al,        null,
               null,               'N' )
         
               if @@error <> 0 
               begin
                  select 
                  @w_mensaje = 'ERROR AL INSERTAR REGISTROS EN LA TABLA ct_sasiento_tmp ',
                  @w_error   = 710001
                  close cursor_perfil
                  deallocate cursor_perfil
                  goto ERROR1
               end
            end
					
			SIGUIENTE_PERFIL:

            fetch cursor_perfil 
            into  @w_dtr_concepto, @w_dtr_codval,     @w_dtr_codval_trn, @w_dtr_moneda,
                  @w_dtr_cuenta,   @w_dp_cuenta,      @w_dp_debcred,       
                  @w_dp_constante, @w_dp_origen_dest, @w_dp_area,          
                  @w_dtr_monto,    @w_dtr_monto_mn,   @w_cotizacion,
				  @w_dtr_estado

         end  -- cursol de los detalles del perfil

         close cursor_perfil
         deallocate cursor_perfil
  
         -- GENERACION DEL COMPROBANTE 
         select @w_re_ofconta = re_ofconta
         from   cob_conta..cb_relofi with (nolock)
         where  re_filial  = 1
         and    re_empresa = 1
         and    re_ofadmin = @w_of_origen_cur

         if @@rowcount = 0 
         begin     
            select 
            @w_mensaje = ' ERR NO EXISTE OF.ORIGEN ' + convert(varchar,@w_of_origen_cur)+ '-',
            @w_error   = 701102
            goto ERROR1
         end
   
         if abs(@w_tot_debito - @w_tot_credito) >= 0.01 
         begin
            select 
            @w_mensaje = 'NO CUADRAN DEBITOS CON CREDITOS: D-> ' +  convert(varchar,@w_tot_debito)+ ' C-> ' + convert(varchar,@w_tot_credito),
            @w_error   = 710324  --GFP 710324
            goto ERROR1
         end

         if @w_tot_debito >= 0.01 or @w_tot_credito >= 0.01 
         begin
            --INI WLO_R189662
            if @i_debug = 'S'
            begin
               print '   Generando comprobante... of: ' + cast(@w_re_ofconta as varchar)
               select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
               print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
            end
            --FIN WLO_R189662
      
            insert into cob_conta_tercero..ct_scomprobante_tmp with (rowlock) (
            sc_producto,       sc_comprobante,   sc_empresa,
            sc_fecha_tran,     sc_oficina_orig,  sc_area_orig,
            sc_digitador,      sc_descripcion,   sc_fecha_gra,      
            sc_perfil,         sc_detalles,      sc_tot_debito,
            sc_tot_credito,    sc_tot_debito_me, sc_tot_credito_me,
            sc_automatico,     sc_reversado,     sc_estado,
            sc_mayorizado,     sc_observaciones, sc_comp_definit,
            sc_usuario_modulo, sc_tran_modulo,   sc_error)
            values (
            @w_cod_producto,   @w_comprobante,   1,
            @w_fecha_proceso,  @w_re_ofconta,    @w_ar_origen,   --GFP 10/06/2022
            @s_user,           @w_descripcion,   getdate(),     
            @w_perfil,         @w_asiento,       @w_tot_debito,
            @w_tot_credito,    @w_tot_debito_me, @w_tot_credito_me,
            @w_cod_producto,   'N',              'I',
            'N',               null,             null,
            'sa',              @w_secuencial,   'N')
      
            if @@error <> 0 
            begin
               select 
               @w_mensaje = 'ERROR AL INSERTAR REGISTROS EN LA TABLA ct_scomprobante_tmp ', 
               @w_error   = 710001
               goto ERROR1
            end

            update ca_transaccion with (rowlock)set 
            tr_comprobante  =  @w_comprobante,
            tr_fecha_cont   =  @w_fecha_proceso,
            tr_estado       =  'CON'
            where tr_operacion  = @w_operacionca
            and   tr_secuencial = @w_secuencial
            and   tr_estado     = 'ING'

            select
            @w_error    = @@error,
            @w_rowcount = @@rowcount

            if @w_error <> 0 
            begin
               select @w_mensaje = ' ERR AL ACTUALIZAR TABLA DE TRANSACCIONES ' 
               select @w_error = 700002
               goto ERROR1
            end 
      	
            if @w_commit = 'S' 
            begin 
               commit tran
               select @w_commit = 'N'
            end                 
      
            goto SIGUIENTE
      
         end --if @w_tot_debito >= 0.01 or @w_tot_credito >= 0.01 
      end --if @i_banco IS NOT NULL  -- TRANSACCIONES INDIVIDUALES
      else
      -- TRANSACCION AGRUPADA
      begin
         -- LIMPIAR TABLAS DE TRABAJO
         truncate table #iva
         select 
         @w_debito     = 0.00,
         @w_debito_me  = 0.00,
         @w_credito    = 0.00,
         @w_credito_me = 0.00,
         @w_asiento    = 0

         -- Validacion Rubros IVA
         update #detalles_prv set
         de_ref_iva = ru_referencial
         from  ca_rubro with (nolock)
         where ru_concepto               = de_concepto
         and   ru_toperacion             = de_toperacion
         and   ru_concepto_asociado is not null
                         
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR UPDATE #detalles_prv (rubro iva) ',
            @w_error   = 710001
            goto ERROR1
         end

         insert into #iva
         select de_ref_iva, 'N'
         from   #detalles_prv
         where  de_ref_iva <> 'N/A'
         group by de_ref_iva

         while 1 = 1 
         begin
            set rowcount 1

            select @w_iva = ref_iva
            from   #iva
            where estado = 'N'

            if @@rowcount = 0 
            begin
               set rowcount 0
               break
            end

            set rowcount 0

            select @w_maxfecha_iva = max(vr_fecha_vig)
            from   ca_valor_referencial with (nolock)
            where  vr_tipo       = @w_iva
            and    vr_fecha_vig <= @w_fecha_mov

            select @w_tasa_iva = vr_valor
            from   ca_valor_referencial with (nolock)
            where  vr_tipo      = @w_iva
            and    vr_fecha_vig = @w_maxfecha_iva

            update #detalles_prv set 
            de_maxfec_iva = @w_maxfecha_iva,
            de_con_iva    = 'S',
            de_porc_iva   = @w_tasa_iva,
            de_valor_base = de_monto/(@w_tasa_iva*0.01)
            where  de_ref_iva  = @w_iva

            if @@error <> 0 
            begin
               select 
               @w_mensaje = 'ERROR UPDATE #detalles_prv (iva) ',
               @w_error   = 710001
               goto ERROR1
            end

            update #iva set estado = 'S'
            where  ref_iva = @w_iva

            if @@error <> 0 
            begin
               select 
               @w_mensaje = 'ERROR UPDATE #iva (estado) ',
               @w_error   = 710001
               goto ERROR1
            end
         end
      
         -- Reversas de Negativos, Invertir el signo del asiento
         update #detalles_prv set
         de_debcred = case when de_debcred = '2' then '1' else '2' end,
         de_monto    = de_monto * -1,
         de_monto_mn = de_monto_mn * -1
         where  de_monto < 0
   
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR UPDATE #detalles_prv (reversas neg) ',
            @w_error   = 710001
            goto ERROR1
         end

         -- Tipo Area  
         update #detalles_prv set
         de_tipo_area = ta_tiparea 
         from cob_conta..cb_tipo_area with (nolock)
         where ta_tiparea  = de_tipo_area  
         and   ta_empresa  = 1
         and   ta_producto = @w_cod_producto

         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR UPDATE #detalles_prv  (tipo area) ',
            @w_error   = 710001
            goto ERROR1
         end
		 --GFP 12/01/2022
		 select @w_oda_grupo_contable = oda_grupo_contable 
		 from ca_operacion_datos_adicionales with (nolock) --WLO_R189662
         where oda_operacion = @w_operacionca
	 
		 --GFP Actualizacion de estado de transacciones
		 update #detalles_prv
		 set de_estado =  case when (de_codvalor / 10) - (((de_codvalor / 10) / 100)*100) in (@w_est_novigente,@w_est_vigente) then @w_est_vigente 
		                       when (de_codvalor / 10) - (((de_codvalor / 10) / 100)*100) in (@w_est_vencido,@w_est_vencido_prorroga,@w_est_vencido_cobro_admin,@w_est_judicial) then @w_est_vencido
							   else (de_codvalor / 10) - (((de_codvalor / 10) / 100)*100) end
		 where substring(de_cuenta, 1, 1) not in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
		 
		 -- MCO Cambio para que se contabilice dentro del nivel de cuentas "Originales" a las transacciones que provengan de 
		 -- operaciones que se hayan originado en un trámite de Renovación
		 update #detalles_prv 
		 set de_originacion = case when de_reestructuracion = 'S' then 'E'
		                           when (tr_tipo = 'O' or (tr_tipo = 'R' and tr_subtipo = 'R')) then 'O'										   
								   when tr_tipo = 'R' and tr_subtipo in ('N','F')   then 'R-F' end
		 from cob_credito..cr_tramite, ca_operacion
		 where op_tramite = tr_tramite
		 and op_operacion = de_operacion
		 
         -- Define clave
         update #detalles_prv set
         de_clave = case when pa_stored = 'sp_ca01_pf'   then rtrim(ltrim(isnull(de_sector,''))) +'.'+ rtrim(ltrim(isnull(de_clase,''))) +'.'+ rtrim(ltrim(isnull(de_subtipo_linea, '99'))) +'.'+ rtrim(ltrim(isnull(de_toperacion, ''))) 
                         when pa_stored = 'sp_ca02_pf'   then isnull(convert(varchar,de_moneda),'')
                         when pa_stored = 'sp_ca03_pf'   then rtrim(ltrim(isnull(de_clase,''))) +'.'+ rtrim(ltrim(isnull(de_sector,'')))
                         when pa_stored = 'sp_ca04_pf'   then rtrim(ltrim(isnull(de_concepto,'')))
                         when pa_stored = 'sp_tipo_oper' then rtrim(ltrim(isnull(de_toperacion,'')))
						 when pa_stored = 'sp_ca09_pf'   then right('0'+rtrim(ltrim(isnull(de_sector,''))),2) +'.'+ right('0'+rtrim(ltrim(isnull(@w_oda_grupo_contable, ''))),2) --GFP resolucion de parametro por combinacion de garantia.
						 when pa_stored = 'sp_ca10_pf'   then rtrim(ltrim(de_clase)) +'.'+ rtrim(ltrim(de_categoria_plazo))+'.'+ rtrim(ltrim(de_estado))+'.'+ rtrim(ltrim(de_originacion)) --GFP Generacion de clave
                        else '' end
         from   cob_conta..cb_parametro with (nolock)
         where  pa_empresa   = 1
         and    pa_parametro = de_cuenta
  
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR UPDATE #detalles_prv (clave) ',
            @w_error   = 710001
            goto ERROR1
         end

         -- Define Cuenta Final
         update #detalles_prv set  
         de_cuenta_final = de_cuenta
         where substring(de_cuenta, 1, 1) in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
   
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR UPDATE #detalles _prv (cuenta final) ',
            @w_error   = 710001
            goto ERROR1
         end
         
         -- Define Cuenta Final
         update #detalles_prv set 
         de_cuenta_final = isnull(rtrim(ltrim(re_substring)), '')
         from   cob_conta..cb_relparam with (nolock)
         where  re_empresa             = 1
         and    re_parametro           = de_cuenta
         and    ltrim(rtrim(re_clave)) = de_clave
   
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR UPDATE #detalles_prv (cuenta final) ',
            @w_error   = 710001
            goto ERROR1
         end

         --- FCP - Utiliza la oficina destino segun la parametrizacion del detalle de perfil *
         -- Oficina Centralizada
         update #detalles_prv set 
         de_oficina = re_ofconta
         from   cob_conta..cb_relofi with (nolock), cob_conta..cb_tipo_area with (nolock)
         where  re_filial      = 1
         and    re_empresa     = 1    
         and    ta_empresa     = 1
         and    re_ofadmin     = ta_ofi_central   
         and    ta_producto    = @w_cod_producto
         and    ta_tiparea     = de_tipo_area
         and    de_origen_dest = 'C'

         -- Oficina Contable
         select @w_re_ofconta = re_ofconta
         from   cob_conta..cb_relofi with (nolock)
         where  re_filial  = 1
         and    re_empresa = 1
         and    re_ofadmin = @w_op_oficina

         if @@rowcount = 0 
         begin
            select 
            @w_mensaje = 'ERROR AL Encontrar Oficina Contable #detalles_prv ', 
            @w_error   = 710001
            goto ERROR1
         end      

         -- Oficina Destino cuando no es Centralizada
         update #detalles_prv set 
         de_oficina = @w_re_ofconta
         where  de_origen_dest <> 'C'

         if @@error <> 0 
         begin 
            select 
            @w_mensaje = 'ERROR AL Actualizar Oficina Destino #detalles_prv ', 
            @w_error   = 710001
            goto ERROR1
         end

         -- Area Contable
         update #detalles_prv set 
         de_area = ta_area
         from   cob_conta..cb_tipo_area with (nolock)
         where  ta_tiparea  = de_area
         and    ta_empresa  = 1
         and    ta_producto = @w_cod_producto

         if @@error <> 0 
         begin 
            select 
            @w_mensaje = 'ERROR AL Actualizar Area #detalles_prv ', 
            @w_error   = 710001
            goto ERROR1
         end
         
         --- Valores Debito y Credito Moneda Nacional 
         update #detalles_prv set 
         de_debito     = de_monto_mn*(2-de_debcred),
         de_credito    = de_monto_mn*(de_debcred-1)
         where de_moneda = @w_mon_nac      
       
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR UPDATE #detalles (debito) #detalles_prv ',
            @w_error   = 710001
            goto ERROR1
         end

         --- Valores Debito y Credito Moneda extranjera
         update #detalles_prv set 
         de_debito     = de_monto_mn*(2-de_debcred),
         de_credito    = de_monto_mn*(de_debcred-1),
         de_debito_me  = de_monto*(2-de_debcred),
         de_credito_me = de_monto*(de_debcred-1)
         where de_moneda <> @w_mon_nac      
       
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR UPDATE #detalles (debito) #detalles_prv ',
            @w_error   = 710001
            goto ERROR1
         end

         select 
         @w_debito     = isnull(sum(de_debito),0),  
         @w_credito    = isnull(sum(de_credito),0), 
         @w_debito_me  = isnull(sum(de_debito_me),0),  
         @w_credito_me = isnull(sum(de_credito_me),0), 
         @w_valor_base = isnull(sum(de_monto),0),
         @w_asiento    = count(1)
         from  #detalles_prv

         --- CONCEPTO DEL COMPROBANTE 
         select @w_descripcion = @w_agrupado + ' Vlr:' + convert(varchar,@w_valor_base/2)  --GFP 25/02/2022 Se divide por dos por duplicidad de credito y debito
   
         --INI WLO_R189662
         if @i_debug = 'S'
         begin
            print 'procesando ofi: ' + convert(varchar, @w_op_oficina) + ' descripcion: ' + @w_descripcion
            select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
            print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
         end
         --FIN WLO_R189662
		 
         --- INGRESA COMPROBANTE 
         insert into cob_conta_tercero..ct_scomprobante_tmp with (rowlock) (
         sc_producto,       sc_comprobante,   sc_empresa,
         sc_fecha_tran,     sc_oficina_orig,  sc_area_orig,
         sc_digitador,      sc_descripcion,   sc_fecha_gra,      
         sc_perfil,         sc_detalles,      sc_tot_debito,
         sc_tot_credito,    sc_tot_debito_me, sc_tot_credito_me,
         sc_automatico,     sc_reversado,     sc_estado,
         sc_mayorizado,     sc_observaciones, sc_comp_definit,
         sc_usuario_modulo, sc_tran_modulo,   sc_error)
         values (
         @w_cod_producto,   @w_comprobante,   1,
         @w_fecha_proceso,  @w_re_ofconta,    @w_ar_origen,    --GFP 10/06/2022
         @s_user,           @w_descripcion,   convert(char(10),getdate(),101),     
         @w_perfil,         @w_asiento,       @w_debito,
         @w_credito,        @w_debito_me,     @w_credito_me,
         @w_cod_producto,   'N',	          'I',
         'N',               null,             null,
         'sa',              -999,             'N')
   
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR AL INSERTAR REGISTROS EN LA TABLA ct_scomprobante_tmp ', 
            @w_error   = 710001
            goto ERROR1
         end   

         --- INGRESA ASIENTO 
         insert into cob_conta_tercero..ct_sasiento_tmp with (rowlock) (                                                                                                                                              
         sa_producto,        sa_fecha_tran,      sa_comprobante,
         sa_empresa,         sa_asiento,         sa_cuenta,
         sa_oficina_dest,    sa_area_dest,       sa_credito,
         sa_debito,          sa_credito_me,      sa_concepto,        
         sa_debito_me,       sa_cotizacion,      sa_tipo_doc,
         sa_tipo_tran,       sa_moneda,          sa_opcion,
         sa_ente,            sa_con_rete,        sa_base,
         sa_valret,          sa_con_iva,         sa_valor_iva,
         sa_iva_retenido,    sa_con_ica,         sa_valor_ica,
         sa_con_timbre,      sa_valor_timbre,    sa_con_iva_reten,
         sa_con_ivapagado,   sa_valor_ivapagado, sa_documento,
         sa_mayorizado,      sa_con_dptales,     sa_valor_dptales,
         sa_posicion,        sa_debcred,         sa_oper_banco,
         sa_cheque,          sa_doc_banco,       sa_fecha_est, 
         sa_detalle,         sa_error )
         select
         @w_cod_producto,    @w_fecha_proceso,   @w_comprobante,    --GFP 10/06/2022
         1,                  de_asiento,         de_cuenta_final,
         de_oficina,         de_area,            de_credito, 
         de_debito,          de_credito_me,      'PRV. Op:'+ isnull(de_banco, '') + ' Co:' + de_concepto +' Cv:' + convert(varchar,de_codvalor),              
         de_debito_me,       de_cotizacion,      'N',
         'A',                de_moneda,          0,
         de_cliente,         null,               de_valor_base,
         null,               de_con_iva,         de_monto,
         null,               null,               null,
         null,               null,               null,
         null,               null,               de_banco,
         'N',                null,               null,
         'S',                de_debcred,         null,
         null,               null,               null,
         null,               'N' 
         from  #detalles_prv
   
         if @@error <> 0 
         begin
            select 
            @w_mensaje = 'ERROR AL INSERTAR REGISTROS EN LA TABLA ct_sasiento_tmp ',
            @w_error   = 710001
            goto ERROR1
         end
		 
		 --GFP 25/02/2022 Para generación de comprobantes grupales e individuales
         if @w_tran_cur = 'PRV' and @i_banco IS NULL
		 begin
		    update ca_transaccion_prv with (rowlock) set 
            tp_comprobante  =  @w_comprobante,
            tp_fecha_cont   =  @w_fecha_proceso,
            tp_estado       =  'CON'
            from   ca_conta_trn_tmp WITH (INDEX (ca_conta_trn_tmp_2) , nolock ), ca_transaccion_prv with (INDEX (idx1)) 
            where  ct_agrupado       = @w_agrupado
            and    tp_operacion      = ct_operacion --WLO_R189662
            and    tp_secuencial_ref = ct_secuencial
            and    tp_fecha_mov      = ct_fecha_mov
            and    tp_fecha_ref      = ct_fecha_ref
            and    tp_concepto       = ct_concepto
            and    tp_codvalor       = ct_codvalor
			and    tp_estado         = 'ING'
            and    @w_op_oficina     = ct_ofi_oper -- tp_ofi_oper       = ct_ofi_oper
            
            if @@error <> 0 
            begin 
               select @w_mensaje = ' ERR AL ACTUALIZAR TABLA DE TRANSACCIONES PRV ' 
               select @w_error = 700002
               goto ERROR1
            end
		
          --INI WLO_R189662
          update ca_transaccion_prv with (rowlock) set 
            tp_comprobante  =  @w_comprobante,
            tp_fecha_cont   =  @w_fecha_proceso,
            tp_estado       =  'CON'
            from   ca_conta_trn_tmp WITH (INDEX (ca_conta_trn_tmp_2) , nolock ), ca_transaccion_prv with (INDEX (idx1)) 
            where  ct_agrupado       = @w_agrupado
            and    tp_operacion      = ct_operacion * -1
            and    tp_secuencial_ref = ct_secuencial
            and    tp_fecha_mov      = ct_fecha_mov
            and    tp_fecha_ref      = ct_fecha_ref
            and    tp_concepto       = ct_concepto
            and    tp_codvalor       = ct_codvalor
			and    tp_estado         = 'ING'
            and    @w_op_oficina     = ct_ofi_oper  -- tp_ofi_oper       = ct_ofi_oper
            and    tp_operacion      < 0
            
            if @@error <> 0 
            begin 
               select @w_mensaje = ' ERR AL ACTUALIZAR TABLA DE TRANSACCIONES PRV ' 
               select @w_error = 700002
               goto ERROR1
            end
          --FIN WLO_R189662
		 end
		 else
		 begin
            update ca_transaccion_prv with (rowlock) set 
            tp_comprobante  =  @w_comprobante,
            tp_fecha_cont   =  @w_fecha_proceso,
            tp_estado       =  'CON'
            from   ca_conta_trn_tmp WITH (INDEX (ca_conta_trn_tmp_2) , nolock ), ca_transaccion_prv with (INDEX (idx1)) 
            where  ct_agrupado       = @w_agrupado
            and    tp_operacion      = ct_operacion --WLO_R189662
            and    tp_secuencial_ref = ct_secuencial
            and    tp_fecha_mov      = ct_fecha_mov
            and    tp_fecha_ref      = ct_fecha_ref
            and    tp_concepto       = ct_concepto
            and    tp_codvalor       = ct_codvalor
            and    @w_op_oficina     = ct_ofi_oper    -- tp_ofi_oper       = ct_ofi_oper
            and    tp_estado         = 'ING'
		    and    tp_fecha_ref      = @w_fecha_ref
		    
            select
            @w_error    = @@error,
            @w_rowcount = @@rowcount
		    
            if @w_error <> 0
            begin
               select @w_mensaje = ' ERR AL ACTUALIZAR TABLA DE TRANSACCIONES PRV ' 
               select @w_error = 700002
               goto ERROR1
            end 

            --INI WLO_R189662
            update ca_transaccion_prv with (rowlock) set 
            tp_comprobante  =  @w_comprobante,
            tp_fecha_cont   =  @w_fecha_proceso,
            tp_estado       =  'CON'
            from   ca_conta_trn_tmp WITH (INDEX (ca_conta_trn_tmp_2) , nolock ), ca_transaccion_prv with (INDEX (idx1)) 
            where  ct_agrupado       = @w_agrupado
            and    tp_operacion      = ct_operacion * -1
            and    tp_secuencial_ref = ct_secuencial
            and    tp_fecha_mov      = ct_fecha_mov
            and    tp_fecha_ref      = ct_fecha_ref
            and    tp_concepto       = ct_concepto
            and    tp_codvalor       = ct_codvalor
            and    @w_op_oficina     = ct_ofi_oper    --tp_ofi_oper       = ct_ofi_oper
            and    tp_estado         = 'ING'
            and    tp_fecha_ref      = @w_fecha_ref
            and    tp_operacion      < 0

            select
            @w_error    = @@error,
            @w_rowcount = @@rowcount

            if @w_error <> 0
            begin
               select @w_mensaje = ' ERR AL ACTUALIZAR TABLA DE TRANSACCIONES PRV ' 
               select @w_error = 700002
               goto ERROR1
            end 
            --FIN WLO_R189662
		 end
       
         if @w_commit = 'S' 
         begin 
            commit tran
            select @w_commit = 'N'
         end                 
      
         goto SIGUIENTE
      end  --if @i_banco IS NOT NULL -- TRANSACCION AGRUPADA

      MARCAR:

--      if @i_banco IS NOT NULL 
--      or (@i_banco IS NULL and @w_tran_cur <> 'PRV')

      if @w_tran_cur <> 'PRV'
      -- TRANSACCION INDIVIDUAL
      begin
         update ca_transaccion with (rowlock)set 
         tr_comprobante  =  @w_comprobante,
         tr_fecha_cont   =  @w_fecha_proceso,
         tr_estado       =  'CON'
         where tr_operacion  = @w_operacionca
         and   tr_secuencial = @w_secuencial
      
         if @@error <> 0 
         begin 
            select @w_mensaje = ' ERR AL ACTUALIZAR TABLA DE TRANSACCIONES ' 
            select @w_error = 700002
            goto ERROR1
         end
      end   
      else  
      -- TRANSACCION AGRUPADA
      begin
         update ca_transaccion_prv with (rowlock) set 
         tp_comprobante  =  @w_comprobante,
         tp_fecha_cont   =  @w_fecha_proceso,
         tp_estado       =  'CON'
         from   ca_conta_trn_tmp WITH (INDEX (ca_conta_trn_tmp_2) , nolock ), ca_transaccion_prv with (INDEX (idx1)) 
         where  ct_agrupado       = @w_agrupado
         and    tp_operacion      = ct_operacion
         and    tp_secuencial_ref = ct_secuencial
         and    tp_fecha_mov      = ct_fecha_mov
         and    tp_fecha_ref      = ct_fecha_ref
         and    tp_concepto       = ct_concepto
         and    tp_codvalor       = ct_codvalor
		 and    tp_estado         = 'ING'
         and    @w_op_oficina     = ct_ofi_oper   --tp_ofi_oper       = ct_ofi_oper
         
         if @@error <> 0 
         begin 
            select @w_mensaje = ' ERR AL ACTUALIZAR TABLA DE TRANSACCIONES PRV ' 
            select @w_error = 700002
            goto ERROR1
         end 
      end
    
      if @w_commit = 'S' 
      begin 
         commit tran
         select @w_commit = 'N'
      end  
      
      goto SIGUIENTE

      ERROR1:
      
      if @w_commit = 'S' 
      begin
         rollback tran
         select @w_commit = 'N'
      end      

      select @w_mensaje = isnull(@w_descripcion, convert(varchar(10), @w_operacionca)) + ' ' + @w_mensaje

      --INI WLO_R189662
      if @i_debug = 'S'
      begin
         print '            ERROR1 --> ' + @w_mensaje
         select @w_hora = datepart(hh,getdate()),@w_minuto = datepart(mi,getdate()), @w_segundo = datepart(ss,getdate()), @w_milisegundo = datepart(ms,getdate())
         print 'HORA: ' + convert(varchar(10),@w_hora) + ' ' + convert(varchar(10),@w_minuto) + ' ' + convert(varchar(10),@w_segundo) + ' ' + convert(varchar(10),@w_milisegundo)
      end
      --FIN WLO_R189662

      exec sp_errorlog
      @i_fecha       = @w_fecha_proceso, 
      @i_error       = @w_error, 
      @i_usuario     = @s_user,
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name, 
      @i_rollback    = 'N',
      @i_cuenta      = @w_banco, 
      @i_descripcion = @w_mensaje

      SIGUIENTE:

      if @w_commit = 'S' 
      begin 
         commit tran
         select @w_commit = 'N'
      end  

      fetch cursor_tran 
      into  @w_operacionca, @w_agrupado, @w_tran_cur,  @w_of_origen_cur, @w_op_oficina, @w_toperacion, @w_fecha_mov, 
            @w_perfil,      @w_sector,   @w_op_moneda, @w_dtr_concepto,  @w_dtr_codval, @w_dtr_monto,  @w_fecha_ref,
            @w_reestructuracion			

   end  -- cursor de transacciones

   close cursor_tran 
   deallocate cursor_tran  
   
   if @i_banco is not NULL
   begin
      select @w_detener_proceso = 'S' 
      break 
   end

end --while @w_detener_proceso = 'N' 
   
return 0

ERRORFIN:

if @w_commit = 'S' 
begin 
   rollback tran            
   select @w_commit = 'N'
end   

exec sp_errorlog
@i_fecha       = @w_fecha_proceso, 
@i_error       = @w_error, 
@i_usuario     = @s_user,
@i_tran        = 7000, 
@i_tran_name   = @w_sp_name, 
@i_rollback    = 'N',
@i_cuenta      = 'CONTABILIDAD', 
@i_descripcion = @w_mensaje

return @w_error

go
