/*ecdatope.sp CONT_SUP **************************************************/
/*  Archivo:                         datooper_conta.sp                 */
/*  Stored procedure:                sp_datos_operacion                 */
/*  Base de datos:                   cob_conta_super                    */
/*  Producto:                        REC                                */
/*  Fecha de escritura:              01/05/2009                         */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "COBISCORP",                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Insertando saldos de creditos desde cob_externos a cob_conta_super  */
/*  sb_dato_operacion y sb_dato_operacion_rubro                         */
/*  TO = TODOS                                                          */
/*  DO = SALDOS DE OPERACIONES SB_DATO_OPERACION                        */
/*                             SB_DATO_OPERACION_RUBROTODOS             */
/*  DT = DATOS DE TRANSACCIONES SB_DATO_TRANSACCION                     */
/*                              SB_DATO_TRANSACCION_DET                 */
/*                              SB_DATO_TRANSACCION_EFEC                */
/*  DD = DATO DE DEUDORES SB_DATO_DEUDORES                              */
/*  PY = DATOS DE PROYECCIONES SB_DATO_CUOTA_PRY                        */
/*                             SB_DATO_RUBRO_PRY                        */
/*  CL = DATOS GENERALES DE CLIENTES SB_DATO_CLIENTE                    */
/*                                   SB_DATO_SITUACION_CLIENTE          */
/*  TR = DATOS DE TRAMITES SB_DATO_TRAMITE                              */
/*  DC = DATOS DE COBRANZAS SB_DATO_COBRANZA                            */
/*  TE = DATOS DE TESORERIA SB_DATO_TESORERIA                           */
/*  SD = DATOS DE SIT-DIAN  SB_DATO_DECLARACIONT                        */
/*  IE = DATOS DE INVENTARIO EFECTIVO  SB_DATO_INVENTARIO_EFECTIVO      */
/*  IN = DATOS DE INVERSION  SB_DATO_INVERSION_ACT                      */
/*                           SB_DATO_INVERSION_PAS                      */
/*  DM = DATOS DE MADURACION  SB_DATO_MADURACION                        */
/*  DB = DATOS DE BANCOS      SB_DATO_BANCOS                            */
/*  DP = DATOS DE POLIZAS     SB_DATO_POLIZA                            */
/*  TP = DATOS DE TASA PIZARRA     SB_DATO_TASA_PIZARRA                 */
/*  DE = DATOS DE EMPLEADO_F338    SB_DATO_EMPLEADO_F338                */
/*  DS = DATOS DE SECTOR DESAGREGA    SB_DATO_SECTOR_DESAGREGA          */
/*  DI = DATOS DE IPC         SB_DATO_IPC                               */
/*  IF = DATOS DE NEXTDAY     SB_DATO_NEXTDAY                           */
/*  HM = DATOS DE CARTERAS_COLECTIVAS     SB_CARTERAS_COLECTIVAS        */
/*  DF = DATOS DE INVENTARIOFRWD          SB_DATO_INVENTARIOFRWD        */
/*  TV = DATOS DE TIPO_VENCIMIENTOS       SB_TIPO_VENCIMIENTOS          */ 
/************************************************************************/
/*                       MODIFICACIONES                                 */
/*  FECHA        AUTOR       RAZON                                      */
/*  01-Jun-05    R.Castillo  Emision Inicial                            */
/*  17-Mar-21    CCA         Se agregaron campos adicionales a las      */
/*                           tablas                                     */
/*  11-May-21    K.Rodriguez Se comenta lógica de uso de algunas tablas */
/*                           y campos de cob_externos.                  */
/*  01-Jul-21    A.Fortiche Se ajusta el campo dr_valor para insercion  */
/*							en tabla sb_dato_operacion_rubro, adicional */
/*							se actualiza campo dt_ente en tabla 		*/
/*							sb_dato_telefono para las fuentes del		*/
/*							repositorio									*/
/*  02-Jul-21    A.Fortiche Se realizan modificaciones por errores de	*/
/*							campos no existentes en ambiente de 		*/
/*							certificacion								*/
/*  03-Sep-21    G.Fernandez Se comenta referencias a tablas que no     */
/*                           exiten en el ambiente hasta ver su uso     */
/*  11-Abr-22    W.Lopez     Se comenta referencias a tablas que no se  */
/*                           usan                                       */
/*  20/09/22     K.Rodriguez R193790: Corrección de nombre de funcion   */
/*                           CaracteresEspeciales                       */
/*  05/05/23     G.Fernandez S785513 Ingreso de nuevos campos           */
/************************************************************************/

use cob_conta_super
go

SET ANSI_NULLS OFF
go

SET QUOTED_IDENTIFIER OFF
go

if exists ( select 1 from sysobjects where name = 'sp_datos_operacion')
   drop proc sp_datos_operacion
go

create proc sp_datos_operacion(  
@i_param1              datetime,           --@i_fecha_proceso
@i_param2              varchar(2),         --@i_operacion
@i_param3              int        = null   --@i_aplicativo, si null hace todos los aplicativos
)  
as  
declare  
@i_descrp_error          varchar(255),
@i_fecha_proceso         datetime,
@i_toperacion            varchar(2),      
@w_msg                   varchar(255),  
@w_sp_name               varchar(30),  
@w_retorno               int,   
@w_ente_version          int = 0,  
@w_fuente                descripcion,  
@w_aplicativo            int,  
@w_ult_finmes            datetime,  
@w_mes                   int,  
@w_anios                 int,  
@w_nit_cliente           varchar(16),
@w_fecha_ejecucion       datetime,
@w_total_reg_ex          int,
@w_total_reg_sb          int,
@w_estructura            varchar(40),
@w_existe                char(1), 
@w_secuencial            int,       
@w_concepto              varchar(10),
@w_tabla                 varchar(10),
@w_path_destino          varchar(255),
@w_cmd                   varchar(255),   
@w_comando               varchar(400),
@w_nombre_archivo        varchar(255),
@w_existencia            char(1), 
@w_origen                char(1),
@w_hora                  smallint,
@w_minu                  smallint,
@w_banco                 int = 0,
@w_ciudad                int,
@w_siguiente_dia         datetime,
@w_error                 int,
@w_reg                   int

select  
@i_fecha_proceso  = @i_param1,  
@i_toperacion     = @i_param2,
@w_aplicativo     = @i_param3,  
@w_retorno        = 0,  
@w_sp_name        = 'sp_datos_operacion',  
@w_msg            = 'FIN DEL PROCESO'  


/*CREACION DE TABLAS TEMPORALES DE TRABAJO */  
create table #aplicativo(aplicativo int null) 

create table #errores (error int not null,mensaje varchar(100) not null)

create table #control (tabla varchar(100))

create table #dato_fatca (
   df_fecha                                       datetime                      null,          
   df_empresa                                     int                           null,          
   df_tipo_identificacion                         varchar(2)                    null,          
   df_numero_identificacion                       varchar(30)                   null,          
   df_nombre                                      varchar(200)                  null,          
   df_direccion                                   varchar(200)                  null,          
   df_cod_prod                                    varchar(50)                   null,          
   df_valor_producto                              money                         null,          
   df_producto                                    int                           null,          
   df_intereses                                   money                         null,          
   df_fecha_proc                                  datetime                      null,          
   df_aplicativo                                  int                           null,          
   df_origen                                      char(4)                       null,  
   df_cliente                                     int                           null,
   df_subtipo                                     char(1)                       null
)

create table #dato_custodia(
   dc_fecha                                       datetime                      not null,
   dc_aplicativo                                  int                           not null,
   dc_empresa                                     int                           not null,
   dc_garantia                                    varchar(64)                   not null,
   dc_oficina                                     int                           not null,
   dc_cliente                                     int                           null,
   dc_documento_tipo                              varchar(2)  null,
   dc_documento_numero                            varchar(24)                   null,
   dc_categoria                                   varchar(1)                    not null,
   dc_tipo                                        varchar(14)                   not null,
   dc_ubicacion_pais                              int                           null,
   dc_ubicacion_provincia                         int                           null,
   dc_ubicacion_canton                            int                           null,
   dc_ubicacion_direccion                         varchar(64)                   null,
   dc_ubicacion_telefono                          varchar(20)                   null,
   dc_descripcion                                 varchar(64)                   null,
   dc_garante                                     int                           null,
   dc_garantia_aplicativo                         int                           null,
   dc_garantia_banco                              varchar(24)                   null,
   dc_fecha_ingreso                               datetime                      null,
   dc_fecha_vencimiento                           datetime                      null,
   dc_idonea                                      varchar(1)                    not null,
   dc_moneda                                      int                           not null,
   dc_fecha_avaluo                                smalldatetime                 not null,
   dc_valor_avaluo                                money                         not null,
   dc_valor_inicial                               money                         not null,
   dc_valor_actual                                money                         not null,
   dc_porcentaje_max_cobertura                    float                         null,
   dc_estado                                      varchar(1)                    not null,
   dc_abierta                                     varchar(1)                    not null,
   dc_num_reserva                                 varchar(13)                   null,
   dc_calidad_gar                                 varchar(10)                   null,
   dc_valor_uti_opera                             money                         null,
   dc_fideicomiso_id                              catalogo                      null,
   dc_fiduciaria_nombre                           varchar(200)                  null,
   dc_registro_id                                 catalogo                      null,
   dc_registro_emisor                             catalogo                      null,
   dc_registro_custodio                           varchar(60)                   null,
   dc_hipoteca_id                                 varchar(60)                   null,
   dc_poliza_id                                   varchar(60)                   null,
   dc_poliza_aseguradora                          varchar(100)                  null,
   dc_poliza_fecha                                datetime                      null,
   dc_avaluador_id                                catalogo                      null,
   dc_instr_financiero                            catalogo                      null,
   dc_emisor_calif                                catalogo                      null,
   dc_emision_calif                               catalogo                      null,
   dc_fuente_valor                                varchar(10)                   null,
   dc_compartida_otras_entidades                  char(1)                       null,
   dc_origen                                      varchar(10)      default 'B'  null,
   dc_fecha_proc                                  varchar(10)                   null,
   dc_oficial                                     int                           null,
   dc_fecha_cambio_estado                         datetime                      null,
   dc_usuario_cambio                              varchar(64)                   null,
   dc_ubicacion_distrito                          varchar(64)                   null      
)

create table #dato_bloqueo (
   bo_fecha                                       datetime                      not null,      
   bo_banco                                       varchar(24)                   not null,      
   bo_aplicativo                                  tinyint                       not null,      
   bo_secuencial                                  int                           not null, 
   bo_secuencial_ref                              int                           null,
   bo_causa_bloqueo                               varchar(10)                   not null,      
   bo_fecha_bloqueo                               datetime                      not null,      
   bo_fecha_modif                                 datetime                      null,      
   bo_fecha_desbloqueo                            datetime                      null,          
   bo_estado                                      char(1)                       not null,      
   bo_origen                                      varchar(70)                   null,          
   bo_fecha_proc                                  datetime                      null,
   bo_funcionario								  varchar(10)					null
   )

delete sb_errorlog  
where er_fuente = @w_sp_name  

/*Codigo de ente asignado al Banco */  
select @w_nit_cliente = pa_char  
from   cobis..cl_parametro  
where  pa_nemonico    = 'NVP'  
and    pa_producto    = 'SUP'  
 
select @w_fecha_ejecucion=getdate()

select @w_ente_version = en_ente   
from   cobis..cl_ente   
where  en_ced_ruc      = @w_nit_cliente  
and    en_tipo_ced     = 'N'  


if @@rowcount = 0 insert into #errores values('3600042','ERROR NO EXISTE CODIGO DE ENTE ASIGNADO A LA ENTIDAD BANCARIA')   
 
/* DETERMINAR LA LISTA DE APLICATIVOS QUE REPORTAN DATOS */
if @w_aplicativo is null begin

   select @w_aplicativo = 0   

   if @i_toperacion in ('TO','DO') begin  --procesar todas las tablas  

      insert into #aplicativo  
      select distinct dt_aplicativo  
      from   cob_externos..ex_dato_tesoreria  
      where  dt_fecha = @i_fecha_proceso  
      
      insert into #aplicativo  
      select distinct do_aplicativo  
      from   cob_externos..ex_dato_operacion  
      where  do_fecha = @i_fecha_proceso  
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      insert into #aplicativo  
      select distinct dp_aplicativo  
      from   cob_externos..ex_dato_pasivas  
      where  dp_fecha = @i_fecha_proceso
      */  
      
   end
 
   if @i_toperacion in ('TO', 'TE') begin  --solo datos de tesoreria  
      insert into #aplicativo  
      select distinct dt_aplicativo  
      from   cob_externos..ex_dato_tesoreria  
      where  dt_fecha = @i_fecha_proceso  
   end

   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO', 'IE') begin  --solo datos de inventario efectivo  
      insert into #aplicativo  
      select distinct ie_aplicativo  
      from   cob_externos..ex_dato_inventario_efectivo  
      where  ie_fecha = @i_fecha_proceso  
   end
   */

   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO', 'IN') begin  --solo datos de inversion  
      insert into #aplicativo  
      select distinct ia_aplicativo  
      from   cob_externos..ex_dato_inversion_act  
      where  ia_fecha = @i_fecha_proceso  
      
      insert into #aplicativo  
      select distinct ip_aplicativo  
      from   cob_externos..ex_dato_inversion_pas  
      where  ip_fecha = @i_fecha_proceso
   end
   */

   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO', 'DM') begin  --solo datos de maduracion  
      insert into #aplicativo  
      select distinct ma_aplicativo  
      from   cob_externos..ex_dato_maduracion  
      where  ma_fecha = @i_fecha_proceso  
   end
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO', 'DP') begin  --solo datos de Poliza  
      insert into #aplicativo  
      select distinct dp_aplicativo  
      from   cob_externos..ex_dato_poliza  
      where  dp_fecha = @i_fecha_proceso  
   end
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO', 'TP') begin  --solo datos de Tasa Pizarra  
      insert into #aplicativo  
      select distinct tp_aplicativo  
      from   cob_externos..ex_dato_tasa_pizarra  
      where  tp_fecha = @i_fecha_proceso  
   end
   */
  
   if @i_toperacion in ('TO','DT') begin  --solo datos de las transacciones  
      insert into #aplicativo  
      select distinct dt_aplicativo  
      from   cob_externos..ex_dato_transaccion  
      where  dt_fecha = @i_fecha_proceso

      insert into #aplicativo  
      select distinct dd_aplicativo  
      from   cob_externos..ex_dato_transaccion_det  
      where  dd_fecha_proc = @i_fecha_proceso
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      insert into #aplicativo  
      select distinct di_aplicativo  
      from   cob_externos..ex_dato_transaccion_efec  
      where  di_fecha = @i_fecha_proceso
      */
   end  
  
   if @i_toperacion in ('TO','PY') begin  --solo proyecciones de cuotas  
      insert into #aplicativo  
      select distinct dc_aplicativo  
      from   cob_externos..ex_dato_cuota_pry  
      where  dc_fecha = @i_fecha_proceso  
   end  
     
   if @i_toperacion in ('TO','DD') begin  --solo datos de los deudores  
      insert into #aplicativo  
      select distinct de_aplicativo  
      from   cob_externos..ex_dato_deudores  
      where  de_fecha = @i_fecha_proceso  
   end  
  
   if @i_toperacion in ('TO','DC') begin  --solo datos de Cobranzas  
      insert into #aplicativo  
      select distinct dc_aplicativo  
      from   cob_externos..ex_dato_cobranza  
      where  dc_fecha = @i_fecha_proceso  
   end

   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','DB') begin  --solo datos de Bancos  
      insert into #aplicativo  
      select distinct db_aplicativo  
      from   cob_externos..ex_dato_bancos  
      where  db_fecha = @i_fecha_proceso  
   end 
   */   
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','SD') begin  --solo datos de SIT - DIAN  FORMATO 1012 --DECLARACION TRIBUTARIA
      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_dato_declaracionT
      where  dt_fecha = @i_fecha_proceso
   end
   */
   
   
   if @i_toperacion in ('TO','FA') begin  --solo datos de DIAN  FORMATO FATCA
      insert into #aplicativo
      select distinct df_aplicativo
      from   cob_externos..ex_dato_fatca
      where  df_fecha = @i_fecha_proceso
      
      select @w_origen='C'--cargue por plantilla CIBF
   end
   
   if @i_toperacion in ('TO','CL') begin  --solo datos CLIENTE
   
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      insert into #aplicativo
      select distinct dc_aplicativo
      from   cob_externos..ex_dato_cliente
      where  dc_fecha = @i_fecha_proceso
      */
      
       /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      insert into #aplicativo
      select distinct dd_aplicativo
      from   cob_externos..ex_dato_direccion
      where  dd_fecha = @i_fecha_proceso
      */

      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_dato_telefono
      where  dt_fecha = @i_fecha_proceso

      insert into #aplicativo
      select distinct da_aplicativo
      from   cob_externos..ex_dato_accionistas
      where  da_fecha = @i_fecha_proceso

      insert into #aplicativo
      select distinct ce_aplicativo
      from   cob_externos..ex_cliente_exonerado
      where  ce_fecha_proc = @i_fecha_proceso

      insert into #aplicativo
      select distinct bo_aplicativo
     from   cob_externos..ex_dato_bloqueo
      where  bo_fecha_proc = @i_fecha_proceso

      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_dato_educa_hijos
      where  dt_fecha_modif = @i_fecha_proceso

      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_dato_escolaridad_log
      where  dt_fecha_actualizacion = @i_fecha_proceso

      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_dato_sostenibilidad
      where  dt_fecha_modif = @i_fecha_proceso

      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_dato_sostenibilidad_log
      where  dt_fecha_actualizacion = @i_fecha_proceso

      insert into #aplicativo
      select distinct fe_aplicativo
      from   cob_externos..ex_forma_extractos
      where  fe_fecha = @i_fecha_proceso
     
      insert into #aplicativo
      select distinct dcc_aplicativo
      from   cob_externos..ex_dato_central_cliente
      where  dcc_fecha_proc = @i_fecha_proceso
     
      insert into #aplicativo
      select distinct dcp_aplicativo
      from   cob_externos..ex_dato_central_producto
      where  dcp_fecha_proceso = @i_fecha_proceso
     
      insert into #aplicativo
      select distinct dch_aplicativo
      from   cob_externos..ex_dato_central_huella
      where  dch_fecha_proc = @i_fecha_proceso
     
      insert into #aplicativo
      select distinct dcs_aplicativo
      from   cob_externos..ex_dato_central_score
      where  dcs_fecha_proceso = @i_fecha_proceso
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      insert into #aplicativo
      select distinct cg_aplicativo
      from   cob_externos..ex_dato_cliente_grupo
      where  cg_fecha = @i_fecha_proceso
      */
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      insert into #aplicativo
      select distinct do_aplicativo
      from   cob_externos..ex_dato_oficina
      where  do_fecha = @i_fecha_proceso
      */
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      insert into #aplicativo
      select distinct bc_aplicativo
      from   cob_externos..ex_dato_buro_credito
      where  bc_fecha = @i_fecha_proceso
      */
   end  
   
   if @i_toperacion in ('TO','HV') begin  --solo datos HECHOS VIOLENTOS
      insert into #aplicativo
      select distinct dh_aplicativo
      from   cob_externos..ex_dato_hechos_violentos
      where  dh_fecha = @i_fecha_proceso  
   end
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','CG') begin  --solo datos CUSTODIA GARANTIA
      insert into #aplicativo
      select distinct dc_aplicativo
      from   cob_externos..ex_dato_custodia
      where  dc_fecha = @i_fecha_proceso
      
      insert into #aplicativo
      select distinct dg_aplicativo
      from   cob_externos..ex_dato_garantia
      where  dg_fecha = @i_fecha_proceso
      
   end
   */
   
   if @i_toperacion in ('TO','TF') begin  --solo datos de TARIFAS
      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_datos_tarifas
      where  dt_fecha = @i_fecha_proceso  

      insert into #aplicativo
      select distinct pt_aplicativo
      from   cob_externos..ex_param_tarifas
      where  pt_fecha = @i_fecha_proceso  
   end
   
   if @i_toperacion in ('TO','PA') begin  --solo datos de PASIVAS
   
       /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      insert into #aplicativo
      select distinct dp_aplicativo
      from   cob_externos..ex_dato_pasivas
      where  dp_fecha = @i_fecha_proceso 
      */ 

      insert into #aplicativo
      select distinct bo_aplicativo
      from   cob_externos..ex_dato_bloqueo
      where  bo_fecha = @i_fecha_proceso
     
      insert into #aplicativo
      select distinct rc_aplicativo
      from   cob_externos..ex_relacion_canal
      where  rc_fecha_proceso = @i_fecha_proceso
   end 
   
    /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','DE') begin  --solo datos de EMPLEADO_F338
      insert into #aplicativo
      select distinct de_aplicativo
      from   cob_externos..ex_dato_empleado_f338
      where  de_fecha = @i_fecha_proceso  
   end 
   */
   
   if @i_toperacion in ('TO','DS') begin  --solo datos de SECTOR_DESAGREGA
      insert into #aplicativo
      select distinct ds_aplicativo
      from   cob_externos..ex_dato_sector_desagrega
      where  ds_fecha = @i_fecha_proceso  
   end
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','IF') begin  --solo datos de NEXTDAY
      insert into #aplicativo
      select distinct dn_aplicativo
      from   cob_externos..ex_dato_nextday
      where  dn_fecha_proc = @i_fecha_proceso  
   end
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','HM') begin  --solo datos de CARTERAS_COLECTIVAS
      insert into #aplicativo
      select distinct cc_aplicativo
      from   cob_externos..ex_carteras_colectivas
      where  cc_fecha_proc = @i_fecha_proceso  
   end
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','DF') begin  --solo datos de INVENTARIOFRWD
      insert into #aplicativo
      select distinct di_aplicativo
      from   cob_externos..ex_dato_inventariofrwd
      where  di_fecha_proc = @i_fecha_proceso  
   end
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','TV') begin  --solo datos de TIPO_VENCIMIENTOS
      insert into #aplicativo
      select distinct tv_aplicativo
      from   cob_externos..ex_tipo_vencimientos
      where  tv_fecha_proc = @i_fecha_proceso  
   end 
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','AP') begin  --solo datos de APF
      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_dato_tarifa
      where  dt_fecha = @i_fecha_proceso  

      insert into #aplicativo
      select distinct dp_aplicativo
      from   cob_externos..ex_dato_producto
      where  dp_fecha = @i_fecha_proceso  
   end
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('TO','WF') begin  --solo datos de WORKFLOW
      insert into #aplicativo
      select distinct dt_aplicativo
      from   cob_externos..ex_dato_tramite
      where  dt_fecha = @i_fecha_proceso  
   end
   */
   
end else 
begin
      insert into #aplicativo
      select @w_aplicativo

      select @w_aplicativo=0
end
  

/* DETERMINAR LA FECHA DEL ULTIMO FIN DE MES */  
select @w_ult_finmes = max(do_fecha)  
from   sb_dato_operacion   
where  do_fecha <= dateadd(dd,-1*datepart(dd,@i_fecha_proceso),@i_fecha_proceso)  
  
 
 /* DETERMINAR EL SIGUIENTE DIA HABIL (ULTIMO PROCESO) */
select @w_siguiente_dia = dateadd(dd,1,@i_fecha_proceso)

while datepart(mm,@i_fecha_proceso) = datepart(mm,@w_siguiente_dia)
and   exists(select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad and df_fecha  = @w_siguiente_dia)
begin
   select @w_siguiente_dia = dateadd(dd, 1, @w_siguiente_dia)
end

while 1 = 1 begin   -- lazo para procesar cada uno de los aplicativos reportados  

   select top 1 @w_aplicativo = aplicativo  
   from   #aplicativo  
   where  aplicativo > @w_aplicativo  
   order by aplicativo  

   if @@rowcount = 0 break     

   /* DATOS DE LAS OPERACIONES */  
   if @i_toperacion in ('DO','TO') begin  
  
      /*ENTRAR BORRANDO LAS TABLAS DE TRABAJO TEMPORALES */  
      truncate table sb_datos_corte_anterior_tmp  
      truncate table sb_datos_rubros_tmp  
      truncate table sb_dato_operacion_tmp  

      
      insert into sb_dato_operacion_tmp(  
      do_fecha              ,do_empresa            ,do_operacion          ,do_banco              ,
      do_tipo_operacion     ,do_aplicativo         ,do_clase_cartera                             ,
      do_codigo_cliente     ,do_oficina            , 
      do_ciudad             ,do_pais               ,do_area               ,do_moneda             , 
      do_monto              ,do_tasa               ,do_modalidad          ,do_plazo_dias         ,
      do_fecha_vencimiento  ,do_edad_mora          ,do_reestructuracion   ,
      do_fecha_reest        ,do_nat_reest          ,do_num_reest          ,do_no_renovacion      ,
      do_num_cuotas         ,do_periodicidad_cuota ,  
      do_valor_cuota        ,do_cuotas_pag         ,do_num_cuotaven       ,do_saldo_cuotaven     ,
      do_fecha_prox_vto     ,do_fecha_ult_pago     ,do_valor_ult_pago     ,do_fecha_castigo      ,
      do_num_acta           ,do_clausula           ,do_oficial            ,do_naturaleza         ,
      do_fuente_recurso     ,do_categoria_producto ,do_tipo_garantias     ,
      do_op_anterior        ,do_edad_cod           ,do_num_cuotas_reest   ,do_tramite            ,
      do_nota_int           ,do_fecha_ini_mora     ,do_gracia_mora        ,do_estado_cobranza    ,                 -- GAL 01/AGO/2010 - OMC (do_nota_int)  
      do_tasa_mora          ,do_tasa_com           ,do_entidad_convenio   ,do_fecha_cambio_linea ,        -- GAL 01/AGO/2010 - OMC
      do_valor_nominal      ,do_emision            ,do_sujcred            ,do_cap_vencido        ,
      do_valor_proxima_cuota,do_saldo_total_Vencido,do_saldo_otr          ,do_saldo_cap_total    ,                 --Req 378 12/08/2013  (do_valor_proxima_cuota)    
      do_regional           ,do_dias_mora_365      ,do_normalizado        ,do_tipo_norm          ,                 --OMOG 03/DIC/2014. Req 472. Se agrega el campo do_dias_mora_365  
      do_tipo_productor     ,do_tipo_reg           ,do_acuerdo_pago       ,do_origen             , 
      do_fecha_proc         ,do_fecha_sobregiro    ,do_valor_sgiro_semana ,do_ingresos_orig      ,  
      do_comisiones         ,do_cuota_manejo       ,do_honorarios         ,do_prox_cuota_int     ,
      do_prox_cuota_otros   ,do_pago_cap           ,do_pago_int           ,do_pago_otros         ,                 -- RPL 04/04/2018
      do_frec_pagos_capital ,do_frec_pagos_int     ,do_fec_pri_amort_cubierta, do_monto_condo    ,     
      do_fecha_condo        ,do_monto_castigo      ,do_inte_castigo       ,do_monto_bonifica     ,
      do_inte_refina        ,do_emproblemado       ,do_mod_pago           ,do_tipo_cartera       , 
      do_subtipo_cartera    ,do_fecha_ult_pago_cap ,do_valor_ult_pago_cap ,do_fecha_ult_pago_int ,
      do_valor_ult_pago_int ,do_inte_vencido       ,do_inte_vencido_fbalance, do_dias_mora_ant   ,
      do_grupal             ,do_cociente_pago      ,do_numero_ciclos      ,do_numero_integrantes ,    
      do_grupo              ,do_valor_cat          ,do_gar_liq_orig       ,do_gar_liq_fpago      ,
      do_gar_liq_dev        ,do_gar_liq_fdev       ,do_cuota_cap          ,do_cuota_int          ,
      do_cuota_iva          ,do_fecha_suspenso     ,do_cuenta             ,do_venc_dividendo     , 
      do_plazo              ,do_fecha_aprob_tramite,do_subtipo_producto   ,do_atraso_grupal      ,
      do_fecha_dividendo_ven,do_cuota_min_vencida  ,do_tplazo             ,do_fecha_proceso      ,
      do_subproducto        ,do_cuota_max_vencida  ,do_atraso_gr_ant      ,do_provision          ,       
      do_codigo_destino     ,do_fecha_concesion    ,do_saldo_cap          ,do_saldo_int          ,
      do_saldo_otros        ,do_saldo_int_contingente, do_saldo           ,do_linea_credito      ,
      do_estado_cartera     ,do_valor_mora         ,do_fecha_pago         ,do_moneda_op          ,
      do_estado_contable    ,
      do_situacion_cliente  ,do_calificacion       ,do_probabilidad_default,     
      do_calificacion_mr    ,do_proba_incum        ,do_perd_incum         ,do_tipo_emp_mr        ,
      do_valor_garantias    ,do_admisible          ,do_prov_cap           ,do_prov_int           ,
      do_prov_cxc           ,do_prov_con_int       ,do_prov_con_cxc       ,do_prov_con_cap       , 
      do_calif_reest        ,do_saldo_otr_contingente, do_cap_liq         ,do_cap_hip            ,                 -- GAL 01/AGO/2010 - OMC
      do_cap_des            ,do_int_liq            ,do_int_hip            ,do_int_des            ,
      do_unidad_atraso      ,do_probabilidad_incumplimiento, do_severidad_perdida, do_monto_expuesto,
	  do_tdividendo         ,do_calificacion_cli)
      /* KDR 11-May-2021 Se comentan campos que no existen en la estructura de la tabla
	  do_documento_tipo     ,do_documento_numero   ,do_fecha_desembolso,  ,do_estado             ,
	  do_cupo_credito       ,do_cap_mora           ,do_provision_niif     ,do_provision_comp     ,
	  do_periodo_cap        ,do_periodo_int        ,do_toperacion_desc    ,do_facilidad_cred     ,
	  do_valor_bloqueos     ,do_valor_pignoraciones,do_calificacion_riesgo,do_canal_apertura     ,
	  do_periodo_gracia     ,do_fecha_pri_vencimiento, do_destino_economico, do_feci             ,
      do_monto_aprobado     ,do_preferencial)*/    
      select   
      do_fecha              ,do_empresa            ,do_operacion          ,do_banco              ,
      do_toperacion         ,do_aplicativo         ,do_clase_cartera                             , 
      case do_cliente when 0 then @w_ente_version else do_cliente end     ,do_oficina            ,    
      do_ciudad             ,do_pais               ,do_area               ,do_moneda             ,
      do_monto              ,do_tasa               ,do_modalidad          ,do_plazo_dias         ,
      do_fecha_vencimiento  ,do_edad_mora          ,isnull(do_reestructuracion, '0')    ,
      do_fecha_reest        ,do_nat_reest          ,do_num_reest          ,isnull(do_num_renovaciones, 0)    ,  
      do_num_cuotas         ,do_periodicidad_cuota ,
      do_valor_cuota        ,do_cuotas_pag         ,do_cuotas_ven         ,do_saldo_ven          ,
      do_fecha_prox_vto     ,do_fecha_ult_pago     ,do_valor_ult_pago     ,do_fecha_castigo      ,
      do_num_acta           ,do_clausula           ,isnull(do_oficial,0)  ,do_naturaleza         ,
      do_fuente_recurso     ,do_categoria_producto ,do_tipo_garantias     ,
      do_op_anterior        ,isnull(do_edad_cod,0) ,do_num_cuotas_reest   ,do_tramite            ,
      do_nota_int           ,do_fecha_ini_mora     ,do_gracia_mora        ,do_estado_cobranza    ,                 -- GAL 01/AGO/2010 - OMC (do_nota_int)  
      do_tasa_mora          ,do_tasa_com           ,isnull(do_entidad_convenio, '0')   ,do_fecha_cambio_linea ,      -- GAL 01/AGO/2010 - OMC  
      do_valor_nominal      ,do_emision            ,do_sujcred            ,do_cap_vencido        ,                 -- DAL Bonos 
      do_valor_proxima_cuota,do_saldo_total_Vencido,do_saldo_otr          ,do_saldo_cap_total    ,                 --Req 378 12/08/2013  (do_valor_proxima_cuota)   
      do_regional           ,do_dias_mora_365      ,do_normalizado        ,do_tipo_norm          ,                 --OMOG 03/DIC/2014. Req 472. Se agrega el campo do_dias_mora_365  
      do_tipo_productor     ,do_tipo_reg           ,do_acuerdo_pago       ,do_origen             , 
      do_fecha_proc         ,do_fecha_sobregiro    ,do_valor_sgiro_semana ,do_ingresos_orig      ,
      do_comisiones         ,do_cuota_manejo       ,do_honorarios         ,do_prox_cuota_int     ,
      do_prox_cuota_otros   ,do_pago_cap           ,do_pago_int           ,do_pago_otros         ,
      do_frec_pagos_capital ,do_frec_pagos_int     ,do_fec_pri_amort_cubierta, do_monto_condo    ,
      do_fecha_condo        ,do_monto_castigo      ,do_inte_castigo       ,do_monto_bonifica     ,
      do_inte_refina        ,do_emproblemado       ,do_mod_pago           ,do_tipo_cartera       , 
      do_subtipo_cartera    ,do_fecha_ult_pago_cap ,do_valor_ult_pago_cap ,do_fecha_ult_pago_int ,
      do_valor_ult_pago_int ,do_inte_vencido       ,do_inte_vencido_fbalance, do_dias_mora_ant   ,
      do_grupal ,do_cociente_pago      ,do_numero_ciclos      ,do_numero_integrantes , 
      do_grupo              ,do_valor_cat          ,do_gar_liq_orig       ,do_gar_liq_fpago      ,
      do_gar_liq_dev        ,do_gar_liq_fdev       ,do_cuota_cap          ,do_cuota_int          ,
      do_cuota_iva          ,do_fecha_suspenso     ,do_cuenta             ,do_venc_dividendo     ,
      do_plazo              ,do_fecha_aprob_tramite,do_subtipo_producto   ,do_atraso_grupal      ,
      do_fecha_dividendo_ven,do_cuota_min_vencida  ,do_tplazo             ,do_fecha_proceso      ,
      do_subproducto        ,do_cuota_max_vencida  ,do_atraso_gr_ant      ,do_provision          ,
      do_destino_economico  ,do_fecha_desembolso   ,do_saldo_cap_total    ,0                     ,
      0                     ,0                     ,0                     ,do_cupo_credito       ,
      do_estado             ,do_cap_mora           ,do_fecha_pago         ,do_moneda_op          ,
      case when do_estado = 4 then 3 when do_estado = 3 then 4  when do_estado in (1,9) then 1 else do_estado end,
      'NOR'                 ,'A'                   ,do_probabilidad_default,     
      ''                    ,0                     ,0                     ,''                    ,
      0                     ,''                    ,0                     ,0                     ,
      0                     ,0                     ,0                     ,0                     , 
      do_calif_reest        ,0                     , do_cap_liq           ,do_cap_hip            ,                 -- GAL 01/AGO/2010 - OMC
      do_cap_des            ,do_int_liq            ,do_int_hip            ,do_int_des            ,
      do_unidad_atraso      ,do_probabilidad_incumplimiento, do_severidad_perdida, do_monto_expuesto,
	  do_tdividendo         ,do_calificacion_cli
	  /* KDR 11-May-2021 Se comentan campos que no se usan en la estructura de la tabla sb_dato_operacion_tmp
	  do_documento_tipo     ,do_documento_numero   ,do_fecha_desembolso   ,do_estado             ,
	  do_cupo_credito       ,do_cap_mora           ,do_provision_niif     ,do_provision_comp     ,
	  do_periodo_cap        ,do_periodo_int        ,do_toperacion_desc    ,do_facilidad_cred     ,
	  do_valor_bloqueos     ,do_valor_pignoraciones,do_calificacion_riesgo,do_canal_apertura     ,
	  do_periodo_gracia     ,do_fecha_pri_vencimiento, do_destino_economico, do_feci             ,
	  do_monto_aprobado     ,do_preferencial
	  */
      from cob_externos..ex_dato_operacion  
      where do_fecha      = @i_fecha_proceso  
      and   do_aplicativo = @w_aplicativo  
        
      if @@error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_OPERACION_TMP' )           
         
      /* REPORTAR TODOS LOS CREDITOS QUE NO SE ENCUENTRE EL CLIENTE */   
      insert into sb_errorlog  
      select  
      er_fecha        = @i_fecha_proceso,          
      er_fecha_proc   = getdate(),        
      er_fuente       = @w_sp_name,  
      er_origen_error = do_banco,    
      er_descrp_error = 'CLIENTE NO EXISTE'   
      from  sb_dato_operacion with (index = idx2)  
      where do_codigo_cliente = @w_ente_version  
      and   do_fecha          = @i_fecha_proceso  
        

      insert into sb_datos_corte_anterior_tmp(  
      aplicativo           ,banco                        ,prov_cap,  
      prov_int             ,prov_cxc                     ,prov_con_int,  
      prov_con_cxc         ,prov_con_cap                 ,calificacion,  
      calificacion_mr      ,proba_incum                  ,perd_incum,  
      tipo_emp_mr          ,situacion_cli                ,edad_cod,  
      tipo_gar             ,valor_gar                    ,calif_reest)  
      select                 
      do_aplicativo        ,do_banco                     ,do_prov_cap,  
      do_prov_int          ,do_prov_cxc                  ,do_prov_con_int,  
      do_prov_con_cxc      ,do_prov_con_cap              ,do_calificacion,  
      do_calificacion_mr   ,do_proba_incum          ,do_perd_incum,  
      do_tipo_emp_mr       ,do_situacion_cliente         ,0,  
      do_tipo_garantias,   isnull(do_valor_garantias,0)  ,do_calif_reest         
      from  sb_dato_operacion  
      where do_fecha      = @w_ult_finmes  
      and   do_aplicativo = @w_aplicativo  
        
      if @@error <> 0 insert into #errores values ('3600001', 'ERROR AL BUSCAR LOS DATOS DEL CORTE ANTERIOR' )  
        

      update sb_dato_operacion_tmp set  
      do_prov_cap          = prov_cap,  
      do_prov_int          = prov_int,  
      do_prov_cxc          = prov_cxc,  
      do_prov_con_int      = prov_con_int,  
      do_prov_con_cxc      = prov_con_cxc,  
      do_prov_con_cap      = prov_con_cap,  
      do_calificacion      = calificacion,  
      do_calificacion_mr   = calificacion_mr,  
      do_proba_incum       = proba_incum,  
      do_perd_incum        = perd_incum,  
      do_tipo_emp_mr       = tipo_emp_mr,  
      do_situacion_cliente = situacion_cli,  
      do_calif_reest       = calif_reest,  
      do_valor_garantias   = valor_gar  
      from sb_datos_corte_anterior_tmp  
      where do_banco           = banco                
      
      if @@error <> 0  insert into #errores values ('3600003', 'ERROR AL ACTUALIZAR LOS DATOS DEL CORTE ANTERIOR')
   
      select @w_mes   = datepart(mm, @i_fecha_proceso)  
      select @w_anios = datepart(yy, @i_fecha_proceso)  
        
      update sb_dato_operacion_tmp  
      set    do_calif_reest              = do_calificacion  
      where  do_reestructuracion         = 'S'  
      and    datepart(mm,do_fecha_reest) = @w_mes  
      and    datepart(yy,do_fecha_reest) = @w_anios  
        
      if @@error <> 0  insert into #errores values ('3600003','ERROR AL ACTUALIZAR LOS DATOS DE REESTRUCTURADOS' )
        
    
      insert into sb_datos_rubros_tmp (banco,          aplicativo,          saldo_cap,  
                                       saldo_int,      saldo_otr,           int_cont,  
                                       saldo_cap_cas,  saldo_int_cas,       saldo_otr_cas,  
                                       otr_cont)  
      select   
      banco          = dr_banco,  
      aplicativo     = @w_aplicativo,  
      saldo_cap      = sum(case when dr_concepto     in ('CAP')             then dr_valor_vigente + dr_valor_suspenso else 0 end),  
      saldo_int      = sum(case when dr_concepto     in ('INT','IMO','IMOSEGVID','IMOSEGPRI','IMOSEGEXE','IMOSEGDAN')       then dr_valor_vigente    else 0 end),  
      saldo_otr      = sum(case when dr_concepto not in ('CAP','INT','IMO','IMOSEGVID','IMOSEGPRI','IMOSEGEXE','IMOSEGDAN') then dr_valor_vigente    else 0 end),  
      int_cont       = sum(case when dr_concepto     in ('INT','IMO','IMOSEGVID','IMOSEGPRI','IMOSEGEXE','IMOSEGDAN')       then dr_valor_suspenso   else 0 end),  
      saldo_cap_cas  = sum(case when dr_concepto     in ('CAP')                                                             then dr_valor_castigado  else 0 end),  
      saldo_int_cas  = sum(case when dr_concepto     in ('INT','IMO','IMOSEGVID','IMOSEGPRI','IMOSEGEXE','IMOSEGDAN')       then dr_valor_castigado  else 0 end),         
      saldo_otr_cas  = sum(case when dr_concepto not in ('CAP','INT','IMO','IMOSEGVID','IMOSEGPRI','IMOSEGEXE','IMOSEGDAN') then dr_valor_castigado  else 0 end),  
      otr_cont       = sum(case when dr_concepto not in ('CAP','INT','IMO','IMOSEGVID','IMOSEGPRI','IMOSEGEXE','IMOSEGDAN') then dr_valor_suspenso   else 0 end)
      from cob_externos..ex_dato_operacion_rubro  
      where dr_fecha      = @i_fecha_proceso  
      and   dr_aplicativo = @w_aplicativo  
      group by dr_banco, dr_origen, dr_fecha_proc  
        
     if @@error <> 0  insert into #errores values ('3600001','ERROR NO EXISTEN SALDOS DE RUBROS EN LA TABLA ex_dato_operacion_rubro'  ) 
                
    
      if exists (select 1 from cob_conta_super..sb_datos_rubros_tmp ) 
      begin                    
     update sb_dato_operacion_tmp set  
         do_saldo_cap             = case do_estado_cartera when 4 then saldo_cap_cas else saldo_cap end,  
         do_saldo_int             = case do_estado_cartera when 4 then saldo_int_cas else saldo_int end,  
         do_saldo_otros           = case do_estado_cartera when 4 then saldo_otr_cas else saldo_otr end,  
         do_saldo_int_contingente = case do_estado_cartera when 4 then 0             else int_cont  end,  
         do_saldo_otr_contingente = case do_estado_cartera when 4 then 0             else otr_cont  end,                     -- GAL/AZU 30/JUL/2010 - OMC  
         do_saldo                 = case do_estado_cartera  
                                when 4 then saldo_cap_cas + saldo_int_cas + saldo_otr_cas  
                                else saldo_cap + saldo_int + saldo_otr + int_cont + otr_cont      -- GAL/AZU 10/AGO/2010 - OMC - (otr_cont)  
                                end   
        from sb_datos_rubros_tmp  
        where do_banco           = banco       
        
        if @@error <> 0  insert into #errores values ('3600003','ERROR AL ACTUALIZAR LOS SALDOS DE LA OPERACION'  )  
              
      end
             
      /* 
     SI EXISTEN, LOS DATOS DE LA SB_DATO_OPERACION */  
      if exists (select 1 from cob_externos..ex_dato_operacion where do_fecha = @i_fecha_proceso and do_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_operacion where do_fecha = @i_fecha_proceso and do_aplicativo = @w_aplicativo) begin  
            delete sb_dato_operacion  
            where  do_fecha      = @i_fecha_proceso  
            and    do_aplicativo = @w_aplicativo  
         end
      end
      else  insert into #errores values ('3600042','ERROR NO EXISTE INFORMACION PARA LA FECHA EN EX_DATO_OPERACION')             
         
      update sb_dato_operacion_tmp set  
      do_saldo_int             = dc_saldo_int,  
      do_saldo_otros           = dc_saldo_otros,  
      do_saldo_int_contingente = dc_saldo_int_contingente,  
      do_linea_credito         = dc_linea_credito,  
      do_fecha_pago            = dc_fecha_pago,  
      do_saldo_cuotaven        = dc_saldo_cuotaven,  
      do_situacion_cliente     = dc_situacion_cliente,  
      do_calificacion          = dc_calificacion,  
      do_probabilidad_default  = dc_probabilidad_default,  
      do_calificacion_mr       = dc_calificacion_mr,  
      do_proba_incum           = dc_proba_incum,  
      do_perd_incum            = dc_perd_incum,  
      do_tipo_emp_mr           = dc_tipo_emp_mr,  
      do_valor_garantias       = dc_valor_garantias,  
      do_prov_cap              = dc_prov_cap,  
      do_prov_int              = dc_prov_int,  
      do_prov_cxc              = dc_prov_cxc,  
      do_prov_con_int          = dc_prov_con_int,  
      do_prov_con_cxc          = dc_prov_con_cxc,  
      do_prov_con_cap          = dc_prov_con_cap,  
      do_calif_reest           = dc_calif_reest,  
      do_saldo_otr_contingente = dc_saldo_otr_contingente  
      from cob_externos..ex_dato_cierre_def  
      where do_banco      = dc_banco  
      and   do_fecha      = dc_fecha  
      and   do_aplicativo = dc_aplicativo  
         
      if @@error <> 0 insert into #errores values('3600003','ERROR AL ACTUALIZAR LOS DATOS DEL CORTE ANTERIOR')  
         
      update sb_dato_operacion_tmp set
      do_saldo =  isnull(do_saldo_int,0) + isnull(do_saldo_otros,0) + isnull(do_saldo_int_contingente,0) +
                  isnull(do_saldo_otr_contingente,0) + isnull(do_saldo_cap_total,0) 
           
           
      print 'Inicia insercion --> sb_dato_operacion ' + convert(varchar(40),getdate())
      print ' '
           
      insert into sb_dato_operacion  
      select * from sb_dato_operacion_tmp 
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_OPERACION')  
      if @w_reg > 0 insert into #control values ('dato_operacion')

     
  
      /***ELIMINANDO DATOS EN SB_DATO_OPERACION_RUBRO ***/  
      if exists (select 1 from cob_externos..ex_dato_operacion_rubro where dr_fecha = @i_fecha_proceso and dr_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_operacion_rubro where dr_fecha = @i_fecha_proceso and dr_aplicativo = @w_aplicativo) begin  
            delete sb_dato_operacion_rubro  
            where dr_fecha      = @i_fecha_proceso  
            and   dr_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_OPERACION_RUBRO')          
             
            
      /***INSERTANDO DATOS EN SB_DATO_OPERACION_RUBRO ***/  
      insert into cob_conta_super..sb_dato_operacion_rubro(  
      dr_fecha,             dr_banco,             dr_toperacion,     
      dr_aplicativo,        dr_concepto,          dr_estado, 
      dr_exigible,          dr_codvalor,          dr_valor,          
      dr_cuota,             dr_acumulado,         dr_pagado,    
      dr_categoria,         dr_rubro_aso,         dr_cat_rub_aso,    
      dr_valor_vigente,     dr_valor_suspenso,    dr_valor_castigado, 
      dr_valor_diferido,    dr_empresa,           dr_origen,            dr_fecha_proc )
      select   
      dr_fecha,             dr_banco,             dr_toperacion,     
      dr_aplicativo,        dr_concepto,          dr_estado, 
      dr_exigible,          dr_codvalor,          dr_valor,          
      dr_cuota,             dr_acumulado,         dr_pagado,    
      dr_categoria,         dr_rubro_aso,         dr_cat_rub_aso,    
      dr_valor_vigente,     dr_valor_suspenso,    dr_valor_castigado, 
      dr_valor_diferido,    dr_empresa,           dr_origen,            dr_fecha_proc
      from cob_externos..ex_dato_operacion_rubro  
      where dr_fecha      = @i_fecha_proceso  
      and   dr_aplicativo = @w_aplicativo   
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_OPERACION_RUBRO')  
      if @w_reg > 0 insert into #control values ( 'dato_operacion_rubro'  ) 
 
     
      /*Datos Operacion Externos - Version Falabella*/  
      if exists (select 1 from cob_externos..ex_dato_operacion_ext where do_fecha = @i_fecha_proceso and do_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_operacion_ext where do_fecha = @i_fecha_proceso and do_aplicativo = @w_aplicativo) begin  
            delete sb_dato_operacion_ext  
            where  do_fecha      = @i_fecha_proceso  
            and    do_aplicativo = @w_aplicativo  
         end
      end  
      else insert into #errores values('3600042','ERROR: NO EXISTE INFORMACION EN EX_DATO_OPERACION_EXT' )  
               
      insert into sb_dato_operacion_ext(  
      do_consecutivo,       do_fecha_op,            do_es_cliente,       do_id_cliente,       do_tipo_id,  
      do_nombre_cliente,    do_ciiu_cliente,        do_nat_juridica,     do_tipo_op,          do_tipo_cta,  
      do_num_cta,           do_ciudad_cta,          do_depart_cta,       do_moneda_origen,    do_valor_origen,  
      do_valor_usd,         do_valor_pesos,         do_tasa_cambio,      do_modalidad_pago,   do_tipo_entidad_op,  
      do_cod_entidad_op,    do_declaracion_cambio,  do_num_declaracion,  do_cod_asig_banco,   do_cod_banco_exterior,  
      do_cod_cumplimiento,  do_clase_mercado,       do_agente_op,        do_id_agente_op,     do_nombre_agente,  
      do_num_formulario,    do_gir_div,             do_estado,           do_operacion_index,  do_fecha_index,  
      do_pais_cli,          do_dpto_cli,            do_ciudad_cli,       do_fecha,            do_aplicativo,
      do_nom_contraparte,   do_fecha_proc)  
      select  
      do_consecutivo,       do_fecha_op,            do_es_cliente,       do_id_cliente,       do_tipo_id,  
      do_nombre_cliente,    do_ciiu_cliente,        do_nat_juridica,     do_tipo_op,          do_tipo_cta,  
      do_num_cta,           do_ciudad_cta,          do_depart_cta,       do_moneda_origen,    do_valor_origen,  
      do_valor_usd,         do_valor_pesos,         do_tasa_cambio,      do_modalidad_pago,   do_tipo_entidad_op,  
      do_cod_entidad_op,    do_declaracion_cambio,  do_num_declaracion,  do_cod_asig_banco,   do_cod_banco_exterior,  
      do_cod_cumplimiento,  do_clase_mercado,       do_agente_op,        do_id_agente_op,     do_nombre_agente,  
      do_num_formulario,    do_gir_div,             do_estado,           do_operacion_index,  do_fecha_index,  
      do_pais_cli,          do_dpto_cli,            do_ciudad_cli,       do_fecha,            do_aplicativo,
      do_nom_contraparte,   do_fecha_proc      
      from  cob_externos..ex_dato_operacion_ext  
      where do_fecha      = @i_fecha_proceso  
      and   do_aplicativo = @w_aplicativo  
            
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_OPERACION_EXT')  
      if @w_reg > 0 insert into #control values ('dato_operacion_ext') 
  
            
      /*Datos Tarjetas Debito y Credito - Version Falabella*/  
      if exists (select 1 from cob_externos..ex_dato_tarjetas where dt_fecha_proceso = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_tarjetas where dt_fecha_proceso = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin  
            delete sb_dato_tarjetas  
            where  dt_fecha_proceso = @i_fecha_proceso  
            and    dt_aplicativo    = @w_aplicativo  
         end  
      else insert into #errores values('3600042','ERROR: NO EXISTE INFORMACI? PARA LA FECHA EN EX_DATO_TARJETAS')
         
      insert into sb_dato_tarjetas (  
      dt_cod_franq,     dt_cod_bin,        dt_num_tarjeta,   dt_miembro,        dt_cod_comp,      dt_cod_grupo,  
      dt_scupo_retiro,  dt_scupo_compras,  dt_scupo_transf,  dt_cod_exencion,   dt_cod_comision,  dt_subtipo,  
      dt_plan_renova,   dt_en_correo,      dt_llave_1,       dt_llave_2,        dt_llave_3,       dt_mes_gracia,  
      dt_estado_ant,    dt_estado,         dt_fec_crea,      dt_fec_emision,    dt_fec_reexp,     dt_fec_ven,  
      dt_fec_ult_ven,   dt_fec_ult_cuo,    dt_fec_pro_cuo,   dt_fec_ult_ref,    dt_fec_ult_uso,   dt_fec_cam_est,  
      dt_tipo_ident,    dt_num_ident,      dt_ind_tprep,     dt_ind_tamp,       dt_tipo_idamp,    dt_tid_amp,  
      dt_tarj_amp,      dt_nom_corto,      dt_num_rep,       dt_num_reexp,      dt_ofi_cont,      dt_ofi_entrega,  
      dt_ofi_radic,     dt_ofi_report,     dt_tipo_tarj,     dt_tarj_ant,       dt_tarj_sig,      dt_moneda,  
      dt_saldo_disp,    dt_acum_diario,    dt_fec_nvto,      dt_indicador_1,    dt_indicador_2,   dt_indicador_3,  
      dt_indicador_4,   dt_indicador_5,    dt_filler_1,      dt_filler_2,       dt_filler_3,      dt_filler_4,  
      dt_filler_5,      dt_valor_1,        dt_valor_2,       dt_valor_3,        dt_valor_4,       dt_valor_5,  
      dt_fecha_1,       dt_fecha_2,        dt_fecha_3,       dt_fecha_4,        dt_fecha_5,       dt_usr_modif,  
      dt_fec_modif,     dt_hora_modif,     dt_aplicativo,    dt_fecha_proceso,  dt_origen,        dt_fecha_proc)  
      select  
      dt_cod_franq,     dt_cod_bin,        dt_num_tarjeta,   dt_miembro,        dt_cod_comp,      dt_cod_grupo,  
      dt_scupo_retiro,  dt_scupo_compras,  dt_scupo_transf,  dt_cod_exencion,   dt_cod_comision,  dt_subtipo,  
      dt_plan_renova,   dt_en_correo,      dt_llave_1,       dt_llave_2,        dt_llave_3,       dt_mes_gracia,  
      dt_estado_ant,    dt_estado,         dt_fec_crea,      dt_fec_emision,    dt_fec_reexp,     dt_fec_ven,  
      dt_fec_ult_ven,   dt_fec_ult_cuo,    dt_fec_pro_cuo,   dt_fec_ult_ref,    dt_fec_ult_uso,   dt_fec_cam_est,  
      dt_tipo_ident,    dt_num_ident,      dt_ind_tprep,     dt_ind_tamp,       dt_tipo_idamp,    dt_tid_amp,  
      dt_tarj_amp,      dt_nom_corto,      dt_num_rep,       dt_num_reexp,      dt_ofi_cont,      dt_ofi_entrega,  
      dt_ofi_radic,     dt_ofi_report,     dt_tipo_tarj,     dt_tarj_ant,       dt_tarj_sig,      dt_moneda,  
      dt_saldo_disp,    dt_acum_diario,    dt_fec_nvto,      dt_indicador_1,    dt_indicador_2,   dt_indicador_3,  
      dt_indicador_4,   dt_indicador_5,    dt_filler_1,      dt_filler_2,       dt_filler_3,      dt_filler_4,  
      dt_filler_5,      dt_valor_1,        dt_valor_2,       dt_valor_3,        dt_valor_4,       dt_valor_5,  
      dt_fecha_1,       dt_fecha_2,        dt_fecha_3,       dt_fecha_4,        dt_fecha_5,       dt_usr_modif,  
      dt_fec_modif,     dt_hora_modif,     dt_aplicativo,    dt_fecha_proceso,  dt_origen,        dt_fecha_proc  
      from  cob_externos..ex_dato_tarjetas  
      where dt_fecha_proceso = @i_fecha_proceso  
      and   dt_aplicativo    = @w_aplicativo  
         
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TARJETAS')  
      if @w_reg > 0 insert into #control values ('dato_tarjetas')   
           
      /*Novedad de Tarjetas - Version Falabella*/  
      if exists (select 1 from cob_externos..ex_tarjeta_novedades where dn_fecha_proceso = @i_fecha_proceso and dn_aplicativo = @w_aplicativo) begin
         if exists (select 1 from sb_tarjeta_novedades where dn_fecha_proceso = @i_fecha_proceso and dn_aplicativo = @w_aplicativo) begin  
            delete sb_tarjeta_novedades  
            where  dn_fecha_proceso = @i_fecha_proceso  
            and    dn_aplicativo    = @w_aplicativo  
         end  
      end
      else insert into #errores values('3600042','ERROR: NO EXISTE INFORMACI? PARA LA FECHA EN EX_DATO_TARJETAS')      
            
      insert into sb_tarjeta_novedades (  
      dn_secuencial,     dn_cod_franquicia,  dn_cod_bin,       dn_num_tarjeta,     dn_miembro,        dn_tipo_novedad,  
      dn_fecha_novedad,  dn_hora_novedad,    dn_est_novedad,   dn_tipo_repos,      dn_subtipo,        dn_estado_bloq,  
      dn_nuevo_bin,      dn_nueva_tarj,      dn_trn_orgiinal,  dn_valor_trn_orig,  dn_valor_novedad,  dn_valor_imp,  
      dn_total_cobrar,   dn_imp_emergencia,  dn_n_liq_impo,    dn_estado_cobro,    dn_campo_mod,      dn_dato_ant,  
      dn_dato_nuevo,     dn_aplic_cuenta,    dn_numero_uenta,  dn_oficina,         dn_tipo_iden,      dn_identificacion,  
      dn_empresa,        dn_orig_nov,        dn_indicador_1,   dn_indicador_2,     dn_indicador_3,    dn_indicador_4,  
      dn_indicador_5,    dn_filler_1,        dn_filler_2,      dn_filler_3,        dn_filler_4,       dn_filler_5,  
      dn_valor_1,        dn_valor_2,         dn_valor_3,       dn_valor_4,         dn_valor_5,        dn_fecha_1,  
      dn_fecha_2,        dn_fecha_3,         dn_fecha_4,       dn_fecha_5,         dn_usr_novedad,    dn_pant_novedad,  
      dn_usr_aproba,     dn_pant_aproba,     dn_fec_aproba,    dn_hora_aproba,     dn_aplicativo,     dn_fecha_proceso,
      dn_origen,         dn_fecha_proc)  
      select  
      dn_secuencial,     dn_cod_franquicia,  dn_cod_bin,       dn_num_tarjeta,     dn_miembro,        dn_tipo_novedad,  
      dn_fecha_novedad,  dn_hora_novedad,    dn_est_novedad,   dn_tipo_repos,      dn_subtipo,        dn_estado_bloq,  
      dn_nuevo_bin,      dn_nueva_tarj,      dn_trn_orgiinal,  dn_valor_trn_orig,  dn_valor_novedad,  dn_valor_imp,  
      dn_total_cobrar,   dn_imp_emergencia,  dn_n_liq_impo,    dn_estado_cobro,    dn_campo_mod,      dn_dato_ant,  
      dn_dato_nuevo,     dn_aplic_cuenta,    dn_numero_uenta,  dn_oficina,         dn_tipo_iden,      dn_identificacion,  
      dn_empresa,        dn_orig_nov,        dn_indicador_1,   dn_indicador_2,     dn_indicador_3,    dn_indicador_4,  
      dn_indicador_5,    dn_filler_1,        dn_filler_2,      dn_filler_3,        dn_filler_4,       dn_filler_5,  
      dn_valor_1,        dn_valor_2,         dn_valor_3,       dn_valor_4,         dn_valor_5,        dn_fecha_1,  
      dn_fecha_2,        dn_fecha_3,         dn_fecha_4,       dn_fecha_5,         dn_usr_novedad,    dn_pant_novedad,  
      dn_usr_aproba,     dn_pant_aproba,     dn_fec_aproba,    dn_hora_aproba,     dn_aplicativo,     dn_fecha_proceso,
      dn_origen,         dn_fecha_proc
      from  cob_externos..ex_tarjeta_novedades  
      where dn_fecha_proceso = @i_fecha_proceso  
      and   dn_aplicativo    = @w_aplicativo  
         
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_TARJETA_NOVEDADES')  
      if @w_reg > 0 insert into #control values ('tarjeta_novedades' )

            
      /* VENTA CARTERA CASTIGADA */  
      /***ELIMINANDO DATOS EN sb_valor_venta ***/  
      if exists (select 1 from cob_externos..ex_valor_venta where vv_fecha = @i_fecha_proceso and vv_aplicativo = @w_aplicativo)  
         if exists (select 1 from sb_valor_venta where vv_fecha = @i_fecha_proceso and vv_aplicativo = @w_aplicativo)  
         begin            
            delete sb_valor_venta  
            where vv_fecha      = @i_fecha_proceso  
            and   vv_aplicativo = @w_aplicativo  
         end  
      end
      else insert into #errores values('3600042','ERROR: NO EXISTE INFORMACION PARA LA FECHA EN EX_VALOR_VENTA')     
      
      /***INSERTANDO DATOS EN SB_VALOR_VENTA ***/  
      insert into cob_conta_super..sb_valor_venta(  
      vv_aplicativo, vv_fecha, vv_operacion, vv_valor)  
      select   
      vv_aplicativo, vv_fecha, vv_operacion, vv_valor  
      from cob_externos..ex_valor_venta  
      where vv_fecha      = @i_fecha_proceso  
      and   vv_aplicativo = @w_aplicativo   
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_VALOR_VENTA')  
      if @w_reg > 0 insert into #control values ('valor_venta' )

      /*--GFP 03/09/2021 Deshabilitación temporal hasta su uso     
      if exists (select 1 from cob_externos..ex_dato_venta_cartera where dv_fecha_corte = @i_fecha_proceso and dv_aplicativo = @w_aplicativo) begin
         delete from cob_conta_super..sb_dato_venta_cartera where dv_fecha_corte = @i_fecha_proceso and dv_aplicativo = @w_aplicativo
      end
      
      insert into cob_conta_super..sb_dato_venta_cartera (
      dv_fecha_corte,         dv_fecha_venta,         dv_empresa,
      dv_id_venta,            dv_valor_venta,         dv_forma_pago,
      dv_condiciones_contrato,dv_documento_entidad,   dv_tipo_doc,
      dv_nacionalidad,        dv_origen,              dv_fecha_proc,
      dv_aplicativo)
      select 
      dv_fecha_corte,         dv_fecha_venta,         dv_empresa,
      dv_id_venta,            dv_valor_venta,         dv_forma_pago,
      dv_condiciones_contrato,dv_documento_entidad,   dv_tipo_doc,
      dv_nacionalidad,        dv_origen,              dv_fecha_proc,
      dv_aplicativo
      from cob_externos..ex_dato_venta_cartera
      where dv_fecha_corte = @i_fecha_proceso
      and   dv_aplicativo  = @w_aplicativo
         
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_VENTA_CARTERA')  
      if @w_reg > 0 insert into #control values ('dato_venta_cartera')

      
      if exists (select 1 from cob_externos..ex_dato_venta_cartera_det where dd_fecha_corte = @i_fecha_proceso and dd_aplicativo = @w_aplicativo) begin
         delete from cob_conta_super..sb_dato_venta_cartera_det where dd_fecha_corte = @i_fecha_proceso and dd_aplicativo = @w_aplicativo
      end
      
     insert into cob_conta_super..sb_dato_venta_cartera_det(
      dd_fecha_corte,       dd_fecha_venta,       dd_empresa,
      dd_banco,             dd_tipo_documento,    dd_documento,
      dd_nombre,            dd_codigo_ciiu,       dd_aplicativo,
      dd_saldo_cap,         dd_saldo_int,         dd_honorarios,
      dd_cuota_manejo,      dd_comisiones,        dd_otros_conceptos,
      dd_provi_constituidas,dd_prov_reversadas,   dd_calificacion,
      dd_fecha_calificacion,dd_tipo_operacion,    dd_redescuento,
      dd_id_venta,          dd_valor_venta,       dd_origen,
      dd_fecha_proc)
      select 
      dd_fecha_corte,       dd_fecha_venta,       dd_empresa,
      dd_banco,             dd_tipo_documento,    dd_documento,
      dd_nombre,            dd_codigo_ciiu,       dd_aplicativo,
      dd_saldo_cap,         dd_saldo_int,         dd_honorarios,
      dd_cuota_manejo,      dd_comisiones,        dd_otros_conceptos,
      dd_provi_constituidas,dd_prov_reversadas,   dd_calificacion,
      dd_fecha_calificacion,dd_tipo_operacion,    dd_redescuento,
      dd_id_venta,          dd_valor_venta,       dd_origen,
      dd_fecha_proc
      from cob_externos..ex_dato_venta_cartera_det
      where dd_fecha_corte = @i_fecha_proceso
      and   dd_aplicativo  = @w_aplicativo
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_VENTA_CARTERA_DET')  
      if @w_reg > 0 insert into #control values ('dato_venta_cartera_det')

    
      if exists (select 1 from cob_externos..ex_dato_hist_reest_mod where dh_fecha = @i_fecha_proceso and dh_aplicativo = @w_aplicativo)
      begin
         delete cob_conta_super..sb_dato_hist_reest_mod
         where dh_fecha      = @i_fecha_proceso
         and   dh_aplicativo = @w_aplicativo
      end
      */ --GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
      /***INSERTA DATOS EN SB_DATO_HIST_REEST_MOD***/
	  /* --GFP 03/09/2021 Deshabilitación temporal hasta su uso
      insert into cob_conta_super..sb_dato_hist_reest_mod(
      dh_fecha                ,dh_aplicativo              ,dh_banco,  
      dh_tipo                 ,dh_fecha_reest_mod         ,dh_saldo_cap_previo,
      dh_saldo_int_previo     ,dh_saldo_otr_previo        ,dh_saldo_cap_resul,
      dh_saldo_int_resul      ,dh_saldo_otr_resul         ,dh_prov_cap_pro_previo,
      dh_prov_int_pro_previo  ,dh_prov_otros_pro_previo   ,dh_prov_cap_pro_resul,  
      dh_prov_int_pro_resul   ,dh_prov_otros_pro_resul    ,dh_prov_cap_con_previo,
      dh_prov_int_con_previo  ,dh_prov_otros_con_previo   ,dh_prov_cap_con_resul,  
      dh_prov_int_con_resul   ,dh_prov_otros_con_resul    ,dh_dias_mora_previo,
      dh_gracia_capital       ,dh_gracia_interes          ,dh_calificacion_previa,
      dh_calificacion_resul   ,dh_altura_vida_previa      ,dh_tasa_referencial_previa ,
      dh_tasa_previo          ,dh_plazo_previo     )
      select
      dh_fecha                ,dh_aplicativo              ,dh_banco,  
      dh_tipo                 ,dh_fecha_reest_mod         ,dh_saldo_cap_previo,
      dh_saldo_int_previo     ,dh_saldo_otr_previo        ,dh_saldo_cap_resul,
      dh_saldo_int_resul      ,dh_saldo_otr_resul         ,dh_prov_cap_pro_previo,
      dh_prov_int_pro_previo  ,dh_prov_otros_pro_previo   ,dh_prov_cap_pro_resul,  
      dh_prov_int_pro_resul   ,dh_prov_otros_pro_resul    ,dh_prov_cap_con_previo,
      dh_prov_int_con_previo  ,dh_prov_otros_con_previo   ,dh_prov_cap_con_resul,  
      dh_prov_int_con_resul   ,dh_prov_otros_con_resul    ,dh_dias_mora_previo,
      dh_gracia_capital       ,dh_gracia_interes          ,dh_calificacion_previa,
      dh_calificacion_resul   ,dh_altura_vida_previa      ,dh_tasa_referencial_previa,
      dh_tasa_previo          ,dh_plazo_previo     
      from cob_externos..ex_dato_hist_reest_mod
      where dh_fecha      = @i_fecha_proceso
      and   dh_aplicativo = @w_aplicativo
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_HIST_REEST_MOD')  
      if @w_reg > 0 insert into #control values ('dato_hist_reest_mod')


      if exists (select 1 from cob_externos..ex_dato_det_reest_mod where dr_fecha = @i_fecha_proceso and dr_aplicativo = @w_aplicativo)
      begin
         delete cob_conta_super..sb_dato_det_reest_mod
         where dr_fecha      = @i_fecha_proceso
       and   dr_aplicativo = @w_aplicativo
      end
     */ --GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
      /***INSERTA DATOS EN SB_DATO_DET_REEST_MOD***/
	  /* --GFP 03/09/2021 Deshabilitación temporal hasta su uso
      insert into cob_conta_super..sb_dato_det_reest_mod(
      dr_fecha,        dr_aplicativo, dr_banco,             dr_banco_orig,
      dr_calificacion, dr_plazo,      dr_tasa_referencial,  dr_tasa)
      select
      dr_fecha,          dr_aplicativo,  dr_banco,             dr_banco_orig,
      dr_calificacion,   dr_plazo,       dr_tasa_referencial,  dr_tasa  
      from cob_externos..ex_dato_det_reest_mod
      where dr_fecha      = @i_fecha_proceso
      and   dr_aplicativo = @w_aplicativo
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_DET_REEST_MOD')  
      if @w_reg > 0 insert into #control values ('dato_det_reest_mod')
*/ --GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
   end          
       
   /* DATOS DE LAS TRANSACCIONES */  
   if @i_toperacion in ('DT','TO') Begin  
         
      if exists (select 1 from cob_externos..ex_dato_transaccion where dt_fecha = @i_fecha_proceso and   dt_aplicativo = @w_aplicativo) begin   
         if exists (select 1 from sb_dato_transaccion where dt_fecha = @i_fecha_proceso and   dt_aplicativo = @w_aplicativo) begin  
            delete cob_conta_super..sb_dato_transaccion where dt_aplicativo = @w_aplicativo and dt_fecha = @i_fecha_proceso  
         end  
      end
      else insert into #errores values('3600042','ERROR NO EXISTE INFORMACI? PARA LA FECHA EN LA TABLA EX_DATO_TRANSACCION')  
         
      /*** INSERTA DATOS EN SB_DATO_TRANSACCION ***/  
      insert into cob_conta_super..sb_dato_transaccion(  
      dt_fecha,        dt_secuencial,      dt_banco,       dt_toperacion,  
      dt_aplicativo,   dt_fecha_trans,     dt_tipo_trans,  dt_reversa,  
      dt_naturaleza,   dt_canal,           dt_oficina,     dt_secuencial_caja,  
      dt_usuario,      dt_terminal,        dt_fecha_hora,  dt_origen,    
      dt_fecha_proc)   -- dt_cliente)                                            -- KDR 11-May-2021 Se comentan campos que no existen en la estructura de la tabla
      select   
   dt_fecha,        dt_secuencial,      dt_banco,       dt_toperacion,  
      dt_aplicativo,   dt_fecha_trans,     dt_tipo_trans,  dt_reversa,  
      dt_naturaleza,   dt_canal,           dt_oficina,     dt_secuencial_caja,  
      dt_usuario,      dt_terminal,        dt_fecha_hora,  dt_origen,    
      dt_fecha_proc   -- dt_cliente                                              -- KDR 11-May-2021 Se comentan campos que no existen en la estructura de la tabla  
      from cob_externos..ex_dato_transaccion  
      where dt_fecha      = @i_fecha_proceso  
      and   dt_aplicativo = @w_aplicativo  
            
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TRANSACCION')  
      if @w_reg > 0 insert into #control values ('dato_transaccion')

           
      /*** ELIMINANDO DATOS EN SB_DATO_TRANSACCION_DET ***/  
      if exists (select 1 from cob_externos..ex_dato_transaccion_det where dd_fecha = @i_fecha_proceso and dd_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_transaccion_det where dd_fecha = @i_fecha_proceso and dd_aplicativo = @w_aplicativo) begin  
            delete sb_dato_transaccion_det  
            where  dd_aplicativo = @w_aplicativo  
            and    dd_fecha      = @i_fecha_proceso  
         end  
      end   
      else insert into #errores values('3600042','ERROR NO EXISTE INFORMACION PARA LA FECHA EN EX_DATO_TRANSACCION_DET')      

     /*** INSERTA DATOS EN SB_DATO_TRANSACCION_DET ***/    
      insert into cob_conta_super..sb_dato_transaccion_det(  
      dd_fecha,        dd_secuencial,      dd_banco,              dd_toperacion,  
      dd_aplicativo,   dd_concepto,        dd_moneda,             dd_cotizacion,  
      dd_monto,        dd_codigo_valor,    dd_origen_efectivo,    dd_dividendo,      
      dd_origen,       dd_fecha_proc)      -- dd_causal)                                       -- KDR 11-May-2021 Se comentan campos que no existen en la estructura de la tabla
      select  
      dd_fecha,        dd_secuencial,      dd_banco,              dd_toperacion,  
      dd_aplicativo,   dd_concepto,        dd_moneda,             isnull(dd_cotizacion,0),      
      dd_monto,        dd_codigo_valor,    dd_origen_efectivo,    dd_dividendo,      
      dd_origen,       dd_fecha_proc      -- dd_causal                                         -- KDR 11-May-2021 Se comentan campos que no existen en la estructura de la tabla
      from cob_externos..ex_dato_transaccion_det  
      where dd_fecha      = @i_fecha_proceso  
      and   dd_aplicativo = @w_aplicativo  
          
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TRANSACCION_DET')  
      if @w_reg > 0 insert into #control values ('dato_transaccion_det')
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso  
      -- ELIMINANDO DATOS EN SB_DATO_TRANSACCION_EFEC  
      if exists (select 1 from #aplicativo, ex_dato_transaccion_efec where di_fecha = @i_fecha_proceso and   di_aplicativo = aplicativo) begin  
         delete cob_conta_super..sb_dato_transaccion_efec 
         from   #aplicativo, sb_dato_transaccion_efec 
         where  di_aplicativo = aplicativo  
         and    di_fecha      = @i_fecha_proceso  
      end  
         
      -- INSERTA DATOS EN SB_DATO_TRANSACCION_EFEC 
      insert into cob_conta_super..sb_dato_transaccion_efec(  
      di_fecha,                   di_aplicativo,              di_secuencial_caja,      di_banco,  
      di_nombre_tit,              di_doc_tipo_tit,            di_iden_tit,             di_cliente,  
      di_doc_tipo_pri_autor,      di_iden_pri_autor,          di_nombres_pri_autor,    di_p_apellido_pri_autor,  
      di_s_apellido_pri_autor,    di_doc_tipo_seg_autor,      di_iden_seg_autor,       di_nombres_seg_autor,     
      di_p_apellido_seg_autor,    di_s_apellido_seg_autor,    di_origen,               di_fecha_proc,           
      di_oficina_origen,          di_tipo_trn_sb16,           di_pais_pri_autor,       di_empresa,  
      di_fecha_real,              di_tipo_trans,              di_causal,               di_pais_titular,
      di_usuario,                 di_moneda,                  di_monto,                di_monto_sem,
   di_monto_mes)  
      select  
      di_fecha,                   di_aplicativo,              di_secuencial_caja,      di_banco,  
      di_nombre_tit,              di_doc_tipo_tit,            di_iden_tit,             di_cliente,  
      di_doc_tipo_pri_autor,      di_iden_pri_autor,          di_nombres_pri_autor,    di_p_apellido_pri_autor,  
      di_s_apellido_pri_autor,    di_doc_tipo_seg_autor,      di_iden_seg_autor,       di_nombres_seg_autor,     
      di_p_apellido_seg_autor,    di_s_apellido_seg_autor,    di_origen,               di_fecha_proc,           
      di_oficina_origen,          di_tipo_trn_sb16,           di_pais_pri_autor,       di_empresa,  
      di_fecha_real,              di_tipo_trans,              di_causal,               di_pais_titular,
      di_usuario,                 di_moneda,                  di_monto,                di_monto_sem,
      di_monto_mes   
      from cob_externos..ex_dato_transaccion_efec  
      where di_fecha      = @i_fecha_proceso  
      and   di_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TRANSACCION_EFEC')  
      if @w_reg > 0 insert into #control values ('dato_transaccion_efec')
      */

   end  --FIN DT
         
   /* DATOS DE LAS PROYECCIONES DE CUOTAS */  
   if @i_toperacion in ('PY','TO') Begin  
   
      /*** ELIMINANDO DATOS EN SB_DATO_CUOTA_PRY ***/  
      if exists (select 1 from cob_externos..ex_dato_cuota_pry where dc_fecha = @i_fecha_proceso and dc_aplicativo = @w_aplicativo) 
      begin  
         if exists (select 1 from sb_dato_cuota_pry where dc_fecha = @i_fecha_proceso and dc_aplicativo = @w_aplicativo) 
         begin  
            delete cob_conta_super..sb_dato_cuota_pry from   sb_dato_cuota_pry 
            where  dc_aplicativo = @w_aplicativo  
            and    dc_fecha      = @i_fecha_proceso     
         end
      end
      else insert into #errores values('3600042','ERROR: NO EXISTE INFORMACION PARA LA FECHA EN EX_DATO_CUOTA_PRY' ) 
  
         
      /*** INSERTA DATOS EN SB_DATO_CUOTA_PRY ***/  
      insert into cob_conta_super..sb_dato_cuota_pry(  
      dc_fecha,          dc_banco,        dc_toperacion,       dc_aplicativo,       dc_num_cuota,
      dc_fecha_vto,      dc_estado,       dc_valor_pry,        dc_origen,           dc_fecha_proc)  
      select   
      dc_fecha,          dc_banco,        dc_toperacion,       dc_aplicativo,       dc_num_cuota,
      dc_fecha_vto,      dc_estado,       dc_valor_pry,        dc_origen,           dc_fecha_proc  
      from cob_externos..ex_dato_cuota_pry  
      where dc_fecha      = @i_fecha_proceso   
      and   dc_aplicativo = @w_aplicativo  
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_CUOTA_PRY')  
      if @w_reg > 0 insert into #control values ('dato_cuota_pry')

         
      /*** ELIMINANDO DATOS EN SB_DATO_RUBRO_PRY ***/  
      if exists (select 1 from cob_externos..ex_dato_rubro_pry where dr_fecha = @i_fecha_proceso and dr_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_rubro_pry where dr_fecha = @i_fecha_proceso and dr_aplicativo = @w_aplicativo) begin  
            delete sb_dato_rubro_pry where dr_aplicativo = @w_aplicativo and dr_fecha = @i_fecha_proceso  
         end
      end
         
      /*** INSERTA DATOS EN SB_DATO_RUBRO_PRY ***/    
      insert into cob_conta_super..sb_dato_rubro_pry(  
      dr_fecha,        dr_banco,       dr_toperacion,      dr_aplicativo,  
      dr_num_cuota,    dr_concepto,    dr_estado,          dr_valor_pry,
      dr_origen,       dr_fecha_proc)  
      select   
      dr_fecha,        dr_banco,       dr_toperacion,      dr_aplicativo,  
      dr_num_cuota,    dr_concepto,    dr_estado,          dr_valor_pry,
      dr_origen,       dr_fecha_proc      
      from cob_externos..ex_dato_rubro_pry  
      where dr_fecha      = @i_fecha_proceso   
      and   dr_aplicativo = @w_aplicativo           
         
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_RUBRO_PRY')  
      if @w_reg > 0 insert into #control values ('dato_rubro_pry')

   end 
         
   /* DATOS DE LOS DEUDORES DE LAS OPERACIONES */  
   if @i_toperacion in ('DD','TO') begin  

      /*** ELIMINA DATOS EN SB_DATO_DEUDORES ***/  
      if exists (select 1 from cob_externos..ex_dato_deudores where de_fecha = @i_fecha_proceso and de_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_deudores where de_fecha = @i_fecha_proceso and de_aplicativo = @w_aplicativo) begin  
            delete sb_dato_deudores  
            where de_aplicativo = @w_aplicativo  
            and   de_fecha      = @i_fecha_proceso  
         end  
      end
      else insert into #errores values('3600042','ERROR NO EXISTE INFORMACION PARA LA FECHA EN EX_DATO_DEUDORES')   
      
      /*** INSERTA DATOS EN SB_DATO_DEUDORES ***/  
      insert into cob_conta_super..sb_dato_deudores(  
      de_fecha,        de_banco,       de_toperacion,     de_aplicativo,  
      de_rol,          de_cliente,     de_origen,         de_fecha_proc)  
      select   
      de_fecha,        de_banco,       de_toperacion,      de_aplicativo,  
      de_rol,          case de_cliente when 0 then @w_ente_version else de_cliente end, de_origen,    de_fecha_proc        
      from  cob_externos..ex_dato_deudores  
      where de_fecha      = @i_fecha_proceso  
      and   de_aplicativo = @w_aplicativo  
         
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_DEUDORES')  
      if @w_reg > 0 insert into #control values ('dato_deudores')

   end   
    
   
   /* DATOS DE COBRANZAS */  
   if @i_toperacion in ('DC','TO') begin  
         
   /*** ELIMINA DATOS EN SB_DATO_COBRANZA ***/  
      if exists (select 1 from cob_externos..ex_dato_cobranza where dc_fecha = @i_fecha_proceso and dc_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_cobranza where dc_fecha = @i_fecha_proceso and dc_aplicativo = @w_aplicativo) begin  
            delete sb_dato_cobranza  
            where dc_fecha      = @i_fecha_proceso  
            and   dc_aplicativo = @w_aplicativo  
         end  
      end
      else insert into #errores values('3600042','ERROR NO EXISTE INFORMACION PARA LA FECHA PARA EX_DATO_COBRANZA')
         
      /*** INSERTA DATOS EN SB_DATO_COBRANZA***/  
      insert into cob_conta_super..sb_dato_cobranza(  
      dc_fecha                     ,dc_aplicativo               ,dc_cobranza                  ,  
      dc_banco                     ,dc_estado                   ,dc_ente_abogado              ,  
      dc_fecha_citacion            ,dc_fecha_acuerdo            ,dc_origen                    ,
      dc_fecha_proc)
      select   
      dc_fecha                     ,dc_aplicativo               ,dc_cobranza                  ,  
      dc_banco                     ,dc_estado                   ,dc_ente_abogado              ,  
      dc_fecha_citacion            ,dc_fecha_acuerdo            ,dc_origen                    ,
      dc_fecha_proc
      from cob_externos..ex_dato_cobranza  
      where dc_fecha      = @i_fecha_proceso  
      and   dc_aplicativo = @w_aplicativo  
         
      select 
     @w_error = @@error,
     @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_COBRANZA')  
      if @w_reg > 0 insert into #control values ('dato_cobranza')

        
   end --operacion DC  
         
   /* DATOS DE TESORERIA */  
   if @i_toperacion in ('TE','TO') begin  
         
      /*** ELIMINA DATOS EN SB_DATO_TESORERIA ***/  
      if exists (select 1 from cob_externos..ex_dato_tesoreria where dt_fecha = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_tesoreria where dt_fecha = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin  
            delete sb_dato_tesoreria where dt_aplicativo = @w_aplicativo and dt_fecha = @i_fecha_proceso   
         end  
      end
      else insert into #errores values('3600042','ERROR NO EXISTE INFORMACION PARA LA FECHA PARA EX_DATO_TESORERIA')
      
         
      insert Into cob_conta_super..sb_dato_tesoreria (  
      dt_fecha,                dt_banco,                dt_toperacion,         dt_aplicativo,          
      dt_categoria_producto,   dt_cliente,              dt_documento_tipo,     dt_documento_numero,    
      dt_oficina,              dt_moneda,               dt_valor_nominal,      dt_valor_inicial,        
      dt_valorizacion_mercado, dt_valorizacion_interes, dt_tipo_tasa,          dt_referencial,         
      dt_factor,               dt_spread,               dt_tasa_orig,          dt_tasa_actual,           
      dt_modalidad,            dt_plazo_dias,           dt_fecha_apertura,     dt_fecha_vencimiento,     
      dt_estado,               dt_num_cuotas,           dt_periodicidad_cuota, dt_valor_cuota,            
      dt_fecha_prox_vto,       dt_tipo_doc_oficial,     dt_documento_oficial,  dt_naturaleza,          
      dt_tipo_inversion,       dt_ubicacion_contrato,   dt_renovado,           dt_fecha_ren,
      dt_origen,               dt_fecha_proc)  
      Select  
      dt_fecha,                dt_banco,                dt_toperacion,         dt_aplicativo,          
      dt_categoria_producto,   dt_cliente,              dt_documento_tipo,     dt_documento_numero,    
      dt_oficina,              dt_moneda,               dt_valor_nominal,      dt_valor_inicial,        
      dt_valorizacion_mercado, dt_valorizacion_interes, dt_tipo_tasa,          dt_referencial,         
      dt_factor,               dt_spread,               dt_tasa_orig,          dt_tasa_actual,           
      dt_modalidad,            dt_plazo_dias,           dt_fecha_apertura,     dt_fecha_vencimiento,     
      dt_estado,               dt_num_cuotas,           dt_periodicidad_cuota, dt_valor_cuota,            
      dt_fecha_prox_vto,       dt_tipo_doc_oficial,     dt_documento_oficial,  dt_naturaleza,          
      dt_tipo_inversion,       dt_ubicacion_contrato,   dt_renovado,           dt_fecha_ren,
      dt_origen,               dt_fecha_proc      
      From  cob_externos..ex_dato_tesoreria  
      Where dt_fecha      = @i_fecha_proceso  
      And   dt_aplicativo = @w_aplicativo  
         
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TESORERIA')  
      if @w_reg > 0 insert into #control values ('dato_tesoreria')

   end -- operacion TE
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DE INVENTARIO EFECTIVO 
   if @i_toperacion in ('IE','TO') begin  
         
      --ELIMINANDO DATOS EN SB_DATO_INVENTARIO_EFECTIVO 
      if exists (select 1 from cob_externos..ex_dato_inventario_efectivo where ie_fecha = @i_fecha_proceso and ie_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_inventario_efectivo where ie_fecha = @i_fecha_proceso and ie_aplicativo = @w_aplicativo) begin  
            delete sb_dato_inventario_efectivo  
            where ie_fecha      = @i_fecha_proceso  
            and   ie_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_INVENTARIO_EFECTIVO')          
             
            
      --INSERTANDO DATOS EN SB_DATO_INVENTARIO_EFECTIVO 
      insert into cob_conta_super..sb_dato_inventario_efectivo(  
      ie_fecha,           ie_empresa,     ie_aplicativo,    ie_moneda,    ie_tmoneda,
      ie_denominacion,    ie_cantidad,    ie_valor,         ie_oficina)
      select   
      ie_fecha,           ie_empresa,     ie_aplicativo,    ie_moneda,    ie_tmoneda,
      ie_denominacion,    ie_cantidad,    ie_valor,         ie_oficina 
      from cob_externos..ex_dato_inventario_efectivo  
      where ie_fecha      = @i_fecha_proceso  
      and   ie_aplicativo = @w_aplicativo   
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_INVENTARIO_EFECTIVO')  
      if @w_reg > 0 insert into #control values ( 'dato_inventario_efectivo'  )

   end -- operacion IE
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DE INVERSION
   if @i_toperacion in ('IN','TO') begin  
         
      -- ELIMINANDO DATOS EN SB_DATO_INVERSION_ACT  
      if exists (select 1 from cob_externos..ex_dato_inversion_act where ia_fecha = @i_fecha_proceso and ia_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_inversion_act where ia_fecha = @i_fecha_proceso and ia_aplicativo = @w_aplicativo) begin  
            delete sb_dato_inversion_act  
            where ia_fecha      = @i_fecha_proceso  
            and   ia_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_INVERSION_ACT')          
             
            
      -- INSERTANDO DATOS EN SB_DATO_INVERSION_ACT
      insert into cob_conta_super..sb_dato_inversion_act(
      ia_fecha,                  ia_aplicativo,                 ia_empresa,                ia_ente,                   ia_ente_tactividad,                  
      ia_banco,                  ia_tcodigo_instr,              ia_codigo_instr,           ia_oficina,                ia_area,       
      ia_pais,                   ia_ciudad,                     ia_categoria,              ia_sector,                 ia_toperacion,      
      ia_toperacion_desc,        ia_instr_financiero,           ia_fecha_emision,          ia_fecha_adquisicion,      ia_fecha_vencimiento,        
      ia_calificacion_riesgo,    ia_periodicidad,               ia_garante,                ia_valor_adquisicion,      ia_valor_libros,
      ia_valor_nominal,          ia_precio_mercado,             ia_valor_mercado,          ia_valor_subyacente,       ia_ttasa,
      ia_tasa,                   ia_spread,                     ia_base_calc_int,          ia_duracion_modificada,    ia_duracion,
      ia_saldo_int,              ia_ticker,                     ia_numero_cupones,         ia_moneda,                 ia_custodio,
      ia_relacion_emisor,        ia_costo_amortizado,           ia_metodo_valoracion,      ia_ytm,                    ia_ganancia_acumulada,
      ia_provision,              ia_cotiza_habitualmente,       ia_dias_ult_cotizacion,    ia_volatilidad,            ia_metodo_volatilidad,
      ia_fecha_venta,            ia_porcentaje_participacion)
      select 
      ia_fecha,                  ia_aplicativo,                 ia_empresa,                ia_ente,                   ia_ente_tactividad,                  
      ia_banco,                  ia_tcodigo_instr,              ia_codigo_instr,           ia_oficina,                ia_area,       
      ia_pais,                   ia_ciudad,                     ia_categoria,              ia_sector,                 ia_toperacion,      
      ia_toperacion_desc,        ia_instr_financiero,           ia_fecha_emision,          ia_fecha_adquisicion,      ia_fecha_vencimiento,        
      ia_calificacion_riesgo,    ia_periodicidad,               ia_garante,                ia_valor_adquisicion,      ia_valor_libros,
      ia_valor_nominal,          ia_precio_mercado,             ia_valor_mercado,          ia_valor_subyacente,       ia_ttasa,
      ia_tasa,                   ia_spread,                     ia_base_calc_int,          ia_duracion_modificada,    ia_duracion,
      ia_saldo_int,              ia_ticker,    ia_numero_cupones,         ia_moneda,                 ia_custodio,
      ia_relacion_emisor,        ia_costo_amortizado,           ia_metodo_valoracion,      ia_ytm,                    ia_ganancia_acumulada,
      ia_provision,              ia_cotiza_habitualmente,       ia_dias_ult_cotizacion,    ia_volatilidad,            ia_metodo_volatilidad,
      ia_fecha_venta,            ia_porcentaje_participacion 
      from cob_externos..ex_dato_inversion_act  
      where ia_fecha      = @i_fecha_proceso  
      and   ia_aplicativo = @w_aplicativo     
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_INVERSION_ACT')  
      if @w_reg > 0 insert into #control values ( 'dato_inversion_act'  )
     
      
      -- ELIMINANDO DATOS EN SB_DATO_INVERSION_PAS  
      if exists (select 1 from cob_externos..ex_dato_inversion_pas where ip_fecha = @i_fecha_proceso and ip_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_inversion_pas where ip_fecha = @i_fecha_proceso and ip_aplicativo = @w_aplicativo) begin  
            delete sb_dato_inversion_pas  
            where ip_fecha      = @i_fecha_proceso  
            and   ip_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_INVERSION_PAS')          
             
            
      -- INSERTANDO DATOS EN SB_DATO_INVERSION_PAS 
      insert into cob_conta_super..sb_dato_inversion_pas(
      ip_fecha,                   ip_aplicativo,             ip_empresa,              ip_ente,                 ip_ente_tactividad,
      ip_banco,                   ip_tcodigo_instr,          ip_codigo_instr,         ip_oficina,              ip_area,      
      ip_pais,                    ip_ciudad,                 ip_categoria,            ip_sector,               ip_toperacion,
      ip_toperacion_desc,         ip_fecha_emision,          ip_fecha_adquisicion,    ip_fecha_vencimiento,    ip_calificacion_riesgo,
      ip_periodicidad,            ip_garante,                ip_valor_adquisicion,    ip_valor_libros,         ip_valor_nominal,
      ip_valor_mercado,           ip_valor_subyacente,       ip_ttasa,                ip_tasa,                 ip_spread,
      ip_base_calc_int,           ip_duracion_modificada,    ip_duracion,             ip_saldo_int,            ip_ticker,
      ip_numero_cupones,          ip_instr_financiero,       ip_moneda,               ip_custodio,             ip_relacion_emisor,
      ip_costo_amortizado,        ip_metodo_valoracion,      ip_ytm,                  ip_ganancia_acumulada,   ip_provision,
      ip_cotiza_habitualmente,    ip_dias_ult_cotizacion,    ip_volatilidad,          ip_metodo_volatilidad,   ip_fecha_venta, 
      ip_porcentaje_participacion)
      select 
      ip_fecha,                   ip_aplicativo,             ip_empresa,              ip_ente,                 ip_ente_tactividad,
      ip_banco,                   ip_tcodigo_instr,          ip_codigo_instr,         ip_oficina,              ip_area,      
      ip_pais,                    ip_ciudad,                 ip_categoria,            ip_sector,               ip_toperacion,
      ip_toperacion_desc,         ip_fecha_emision,          ip_fecha_adquisicion,    ip_fecha_vencimiento,    ip_calificacion_riesgo,
      ip_periodicidad,            ip_garante,                ip_valor_adquisicion,    ip_valor_libros,         ip_valor_nominal,
      ip_valor_mercado,           ip_valor_subyacente,       ip_ttasa,                ip_tasa,                 ip_spread,
      ip_base_calc_int,           ip_duracion_modificada,    ip_duracion,             ip_saldo_int,            ip_ticker,
      ip_numero_cupones,          ip_instr_financiero,       ip_moneda,               ip_custodio,             ip_relacion_emisor,
      ip_costo_amortizado,        ip_metodo_valoracion,   ip_ytm,                  ip_ganancia_acumulada,   ip_provision,
      ip_cotiza_habitualmente,    ip_dias_ult_cotizacion,    ip_volatilidad,          ip_metodo_volatilidad,   ip_fecha_venta, 
      ip_porcentaje_participacion     
      from cob_externos..ex_dato_inversion_pas  
      where ip_fecha      = @i_fecha_proceso  
      and   ip_aplicativo = @w_aplicativo      
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_INVERSION_PAS')  
      if @w_reg > 0 insert into #control values ( 'dato_inversion_pas'  )

   end -- operacion IN
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DE MADURACION 
   if @i_toperacion in ('DM','TO') begin  
         
     -- ELIMINANDO DATOS EN SB_DATO_MADURACION  
      if exists (select 1 from cob_externos..ex_dato_maduracion where ma_fecha = @i_fecha_proceso and ma_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_maduracion where ma_fecha = @i_fecha_proceso and ma_aplicativo = @w_aplicativo) begin  
            delete sb_dato_maduracion  
            where ma_fecha      = @i_fecha_proceso  
            and   ma_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_MADURACION')          

      -- INSERTANDO DATOS EN SB_DATO_MADURACION  
      insert into cob_conta_super..sb_dato_maduracion(
      ma_fecha,        ma_aplicativo,    ma_empresa,    ma_banco,    ma_cuotas_can,
      ma_cuotas_ve,    ma_cuotas_pv,     ma_ve07,       ma_ve06,     ma_ve05,      
      ma_ve04,         ma_ve03,          ma_ve02,       ma_ve01,     ma_pv01,      
      ma_pv02,         ma_pv03,          ma_pv04,       ma_pv05,     ma_pv06,   
      ma_pv07,         ma_pv08,          ma_pv09)
      select
      ma_fecha,        ma_aplicativo,    ma_empresa,    ma_banco,    ma_cuotas_can,
      ma_cuotas_ve,    ma_cuotas_pv,     ma_ve07,       ma_ve06,     ma_ve05,      
      ma_ve04,         ma_ve03,          ma_ve02,       ma_ve01,     ma_pv01,      
      ma_pv02,         ma_pv03,          ma_pv04,       ma_pv05,     ma_pv06,   
      ma_pv07,         ma_pv08,          ma_pv09   
      from cob_externos..ex_dato_maduracion  
      where ma_fecha      = @i_fecha_proceso  
      and   ma_aplicativo = @w_aplicativo   
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_MADURACION')  
      if @w_reg > 0 insert into #control values ( 'dato_maduracion'  )

   end -- operacion DM
   */        
            
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DE POLIZAS 
   if @i_toperacion in ('DP','TO') begin  
         
     -- ELIMINANDO DATOS EN SB_DATO_POLIZA  
      if exists (select 1 from cob_externos..ex_dato_poliza where dp_fecha = @i_fecha_proceso and dp_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_poliza where dp_fecha = @i_fecha_proceso and dp_aplicativo = @w_aplicativo) begin  
            delete sb_dato_poliza  
            where dp_fecha      = @i_fecha_proceso  
            and   dp_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_POLIZA')          
             
            
      -- INSERTANDO DATOS EN SB_DATO_POLIZA 
      insert into cob_conta_super..sb_dato_poliza(
      dp_fecha,               dp_aplicativo,          dp_empresa,          dp_garantia,   
      dp_poliza,              dp_aseguradora,         dp_fecha_vig_ini,    dp_fecha_vig_fin,
      dp_fecha_endoso_ini,    dp_fecha_endoso_fin,    dp_moneda,           dp_monto_poliza,
      dp_monto_endoso,        dp_estado_poliza,       dp_tipo_cobertura,   dp_descripcion)
      select
      dp_fecha,               dp_aplicativo,          dp_empresa,          dp_garantia,   
      dp_poliza,              dp_aseguradora,         dp_fecha_vig_ini,    dp_fecha_vig_fin,
      dp_fecha_endoso_ini,    dp_fecha_endoso_fin,    dp_moneda,           dp_monto_poliza,
      dp_monto_endoso,        dp_estado_poliza,       dp_tipo_cobertura,   dp_descripcion   
      from cob_externos..ex_dato_poliza  
      where dp_fecha      = @i_fecha_proceso  
      and   dp_aplicativo = @w_aplicativo   
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_POLIZA')  
      if @w_reg > 0 insert into #control values ( 'dato_poliza'  )

   end -- operacion DP
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DE TASA PIZARRA  
   if @i_toperacion in ('TP','TO') begin  
         
     -- ELIMINANDO DATOS EN SB_DATO_TASA_PIZARRA 
      if exists (select 1 from cob_externos..ex_dato_tasa_pizarra where tp_fecha = @i_fecha_proceso and tp_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_tasa_pizarra where tp_fecha = @i_fecha_proceso and tp_aplicativo = @w_aplicativo) begin  
            delete sb_dato_tasa_pizarra  
            where tp_fecha      = @i_fecha_proceso  
            and   tp_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_TASA_PIZARRA')          
             
            
      -- INSERTANDO DATOS EN SB_DATO_TASA_PIZARRA 
      insert into cob_conta_super..sb_dato_tasa_pizarra(
      tp_fecha,        tp_aplicativo,      tp_empresa,        tp_naturaleza,
      tp_actividad,    tp_rango_tiempo,    tp_rango_monto,    tp_tasa)
      select
      tp_fecha,        tp_aplicativo,      tp_empresa,        tp_naturaleza,
      tp_actividad,    tp_rango_tiempo,    tp_rango_monto,    tp_tasa  
      from cob_externos..ex_dato_tasa_pizarra  
      where tp_fecha      = @i_fecha_proceso  
      and   tp_aplicativo = @w_aplicativo   
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TASA_PIZARRA')  
      if @w_reg > 0 insert into #control values ( 'dato_tasa_pizarra'  )

   end -- operacion TP
   */
   
    /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DE EMPLEADO_F338 
   if @i_toperacion in ('DE','TO') begin  
         
      -- ELIMINANDO DATOS EN SB_DATO_EMPLEADO_F338  
      if exists (select 1 from cob_externos..ex_dato_empleado_f338 where de_fecha = @i_fecha_proceso and de_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_empleado_f338 where de_fecha = @i_fecha_proceso and de_aplicativo = @w_aplicativo) begin  
            delete sb_dato_empleado_f338  
            where de_fecha      = @i_fecha_proceso  
            and   de_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_EMPLEADO_F338')           
      
      -- INSERTANDO DATOS EN SB_DATO_EMPLEADO_F338  
      insert into cob_conta_super..sb_dato_empleado_f338(
      de_fecha       ,de_tipo_documento   ,de_documento    ,de_valor    ,de_moneda   ,         
      de_operacion   ,de_fecha_proc     	,de_aplicativo   ,de_origen)         
      select
      de_fecha       ,de_tipo_documento   ,de_documento    ,de_valor    ,de_moneda   ,         
      de_operacion   ,de_fecha_proc     	,de_aplicativo   ,de_origen
      from cob_externos..ex_dato_empleado_f338  
      where de_fecha      = @i_fecha_proceso  
      and   de_aplicativo = @w_aplicativo 
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_EMPLEADO_F338')  
 if @w_reg > 0 insert into #control values ( 'dato_empleado_f338'  )

   end -- operacion DE
   */

   /* DATOS DE SECTOR_DESAGREGA */  
   if @i_toperacion in ('DS','TO') begin  
         
      /***ELIMINANDO DATOS EN SB_DATO_SECTOR_DESAGREGA ***/  
      if exists (select 1 from cob_externos..ex_dato_sector_desagrega where ds_fecha = @i_fecha_proceso and ds_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_sector_desagrega where ds_fecha = @i_fecha_proceso and ds_aplicativo = @w_aplicativo) begin  
            delete sb_dato_sector_desagrega  
            where ds_fecha      = @i_fecha_proceso  
            and   ds_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_SECTOR_DESAGREGA')           
      
      /***INSERTANDO DATOS EN SB_DATO_SECTOR_DESAGREGA ***/        
      insert into cob_conta_super..sb_dato_sector_desagrega(
      ds_fecha            ,ds_toperacion   ,ds_num_operacion   ,ds_tipoid       ,  	
      ds_identificacion   ,ds_digito_ver   ,ds_nombre          ,ds_valor        ,
      ds_moneda           ,ds_origen       ,ds_aplicativo      ,ds_fecha_proc)     
      select
      ds_fecha            ,ds_toperacion   ,ds_num_operacion   ,ds_tipoid       ,  	
      ds_identificacion   ,ds_digito_ver   ,ds_nombre          ,ds_valor        ,
      ds_moneda           ,ds_origen       ,ds_aplicativo      ,ds_fecha_proc  
      from cob_externos..ex_dato_sector_desagrega  
      where ds_fecha      = @i_fecha_proceso  
      and   ds_aplicativo = @w_aplicativo 
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_SECTOR_DESAGREGA')  
      if @w_reg > 0 insert into #control values ( 'dato_sector_desagrega'  )

   end -- operacion DS
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DE IPC  
   if @i_toperacion in ('DI','TO') begin  
         
      -- ELIMINANDO DATOS EN SB_DATO_IPC  
      if exists (select 1 from cob_externos..ex_dato_ipc where ip_fecha_proc = @i_fecha_proceso ) begin  
         if exists (select 1 from sb_dato_ipc where ip_fecha_proc = @i_fecha_proceso ) begin  
            delete sb_dato_ipc  
            where  ip_fecha_proc = @i_fecha_proceso
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_IPC')          
             
      -- INSERTA DATOS EN SB_DATO_IPC 
      insert into cob_conta_super..sb_dato_ipc(  
      ip_periodo     , ip_ipc        , ip_var_mensual , ip_var_anio_corrido ,
      ip_var_anual   , ip_aplicativo , ip_origen      , ip_fecha_proc      
      )
      select   
      ip_periodo     , ip_ipc        , ip_var_mensual , ip_var_anio_corrido ,
      ip_var_anual   , ip_aplicativo , ip_origen      , ip_fecha_proc 
      from cob_externos..ex_dato_ipc
      where ip_fecha_proc    = @i_fecha_proceso

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_IPC')  
      if @w_reg > 0 insert into #control values ( 'dato_inventario_efectivo'  )

   end -- operacion DI
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS NEXTDAY  
   if @i_toperacion in ('IF','TO') begin  
         
      -- ELIMINANDO DATOS EN SB_DATO_NEXTDAY 
      if exists (select 1 from cob_externos..ex_dato_nextday where dn_fecha_proc = @i_fecha_proceso and dn_aplicativo = @w_aplicativo ) begin  
         if exists (select 1 from sb_dato_nextday where dn_fecha_proc = @i_fecha_proceso and dn_aplicativo = @w_aplicativo ) begin  
            delete sb_dato_nextday  
            where  dn_fecha_proc = @i_fecha_proceso
            and    dn_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_NEXTDAY')          
              
      -- INSERTA DATOS EN SB_DATO_NEXTDAY 
      insert into cob_conta_super..sb_dato_nextday(  
      dn_referencia            , dn_tipo_operacion     , dn_id_cliente             ,
      dn_fecha_valor           , dn_fecha_pago         , dn_fecha_venc             ,
      dn_plazo                 , dn_plazo_original     , dn_valor_nominal          ,
      dn_valor_moneda_legal    , dn_cotizacion_pactada , dn_cotizacion_spot_cierre ,
      dn_tasa                  , dn_tasa_mon_legal     , dn_valoracion_derechos    ,
      dn_valoracion_obligacion , dn_pyg                , dn_aplicativo             ,
      dn_empresa               , dn_fecha_proc         , dn_origen
      )
	   select   
      dn_referencia            , dn_tipo_operacion     , dn_id_cliente             ,
      dn_fecha_valor           , dn_fecha_pago         , dn_fecha_venc             ,
      dn_plazo                 , dn_plazo_original     , dn_valor_nominal          ,
      dn_valor_moneda_legal    , dn_cotizacion_pactada , dn_cotizacion_spot_cierre ,
      dn_tasa                  , dn_tasa_mon_legal     , dn_valoracion_derechos    ,
      dn_valoracion_obligacion , dn_pyg                , dn_aplicativo             ,
      dn_empresa               , dn_fecha_proc         , dn_origen
	   from  cob_externos..ex_dato_nextday
      where dn_fecha_proc = @i_fecha_proceso
      and   dn_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_NEXTDAY')  
      if @w_reg > 0 insert into #control values ( 'dato_nextday'  )

   end -- operacion IF
   */

   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS CARTERAS_COLECTIVAS  
   if @i_toperacion in ('HM','TO') begin  
         
      -- ELIMINANDO DATOS EN SB_CARTERAS_COLECTIVAS 
      if exists (select 1 from cob_externos..ex_carteras_colectivas where cc_fecha_proc = @i_fecha_proceso and cc_aplicativo = @w_aplicativo ) begin  
         if exists (select 1 from sb_carteras_colectivas where cc_fecha_proc = @i_fecha_proceso and cc_aplicativo = @w_aplicativo ) begin  
            delete sb_carteras_colectivas  
            where  cc_fecha_proc = @i_fecha_proceso
            and    cc_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_CARTERAS_COLECTIVAS')          
               
      -- INSERTA DATOS EN SB_CARTERAS_COLECTIVAS  
      insert into cob_conta_super..sb_carteras_colectivas(  
      cc_cartera_colectiva , cc_id_cliente , cc_factor_riesgo_actual,
      dn_saldo_actual      , dn_moneda     , dn_rendimiento_dia, cc_aplicativo,
      cc_empresa           , cc_fecha_proc , cc_origen
	   )
	   select   
      cc_cartera_colectiva , cc_id_cliente , cc_factor_riesgo_actual,
      dn_saldo_actual      , dn_moneda     , dn_rendimiento_dia, cc_aplicativo,
      cc_empresa           , cc_fecha_proc , cc_origen
      from  cob_externos..ex_carteras_colectivas
      where cc_fecha_proc = @i_fecha_proceso  
      and   cc_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_CARTERAS_COLECTIVAS')  
      if @w_reg > 0 insert into #control values ( 'carteras_colectivas'  )

   end -- operacion HM
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS INVENTARIOFRWD  
   if @i_toperacion in ('DF','TO') begin  
         
      -- ELIMINANDO DATOS EN SB_DATO_INVENTARIOFRWD  
      if exists (select 1 from cob_externos..ex_dato_inventariofrwd where di_fecha_proc = @i_fecha_proceso and di_aplicativo = @w_aplicativo ) begin  
         if exists (select 1 from sb_dato_inventariofrwd where di_fecha_proc = @i_fecha_proceso and di_aplicativo = @w_aplicativo ) begin  
            delete sb_dato_inventariofrwd  
            where  di_fecha_proc = @i_fecha_proceso
            and    di_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_INVENTARIOFRWD')          
               
      -- INSERTA DATOS EN SB_DATO_INVENTARIOFRWD       
      insert into sb_dato_inventariofrwd (
      di_tipo                   ,di_modalidad              ,di_portafolio            ,di_referencia         ,di_cliente             ,                      
      di_identificacion         ,di_fecha_inv              ,di_fecha_apertura        ,di_fecha_pago         ,di_fecha_venc          ,                      
      di_plazo                  ,di_dias_al_venc           ,di_mon_nominal           ,di_mon_conv           ,di_monto               ,                      
      di_valor_moneda           ,di_cot_spot               ,di_cot_fwd               ,di_devaluacion        ,di_tasa_me             ,                      
      di_tasa_mp                ,di_derecho_ayer           ,di_obligacion_ayer       ,di_derecho_hoy        ,di_obligacion_hoy      ,                      
      di_pyg                    ,di_tasa_estimada          ,di_tasa_val_usd          ,di_tasa_val_divisa    ,di_pyg_dia             ,                      
      di_formula_derecho        ,di_formula_obligacion     ,di_aplicativo            ,di_empresa            ,di_fecha_proc          ,di_origen)                 
	   select   
      di_tipo                   ,di_modalidad              ,di_portafolio            ,di_referencia         ,di_cliente             ,                      
      di_identificacion         ,di_fecha_inv              ,di_fecha_apertura        ,di_fecha_pago         ,di_fecha_venc          ,                      
      di_plazo                  ,di_dias_al_venc           ,di_mon_nominal           ,di_mon_conv           ,di_monto               ,                      
      di_valor_moneda           ,di_cot_spot               ,di_cot_fwd               ,di_devaluacion        ,di_tasa_me             ,                      
      di_tasa_mp                ,di_derecho_ayer           ,di_obligacion_ayer       ,di_derecho_hoy        ,di_obligacion_hoy      ,                      
      di_pyg                    ,di_tasa_estimada          ,di_tasa_val_usd          ,di_tasa_val_divisa    ,di_pyg_dia             ,                      
      di_formula_derecho        ,di_formula_obligacion     ,di_aplicativo            ,di_empresa            ,di_fecha_proc          ,di_origen    
      from  cob_externos..ex_dato_inventariofrwd
      where di_fecha_proc = @i_fecha_proceso  
      and   di_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_INVENTARIOFRWD')  
      if @w_reg > 0 insert into #control values ( 'dato_inventariofrwd'  )

   end -- operacion DF
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS TIPO_VENCIMIENTOS  
   if @i_toperacion in ('TV','TO') begin  
         
      -- ELIMINANDO DATOS EN SB_TIPO_VENCIMIENTOS  
      if exists (select 1 from cob_externos..ex_tipo_vencimientos where tv_fecha_proc = @i_fecha_proceso and tv_aplicativo = @w_aplicativo ) begin  
         if exists (select 1 from sb_tipo_vencimientos where tv_fecha_proc = @i_fecha_proceso and tv_aplicativo = @w_aplicativo ) begin  
            delete sb_tipo_vencimientos  
            where  tv_fecha_proc = @i_fecha_proceso
            and    tv_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_TIPO_VENCIMIENTOS')          
               
      -- INSERTA DATOS EN SB_TIPO_VENCIMIENTOS             
      insert into sb_tipo_vencimientos(
      tv_portafolio  ,tv_producto                   ,tv_estadoinversion           ,tv_valorgarantia            ,tv_referencia            ,  
      tv_razonsocial             ,tv_valorcompra                ,tv_valornominal              ,tv_fechacompra              ,tv_fechaemision          ,  
      tv_fechavcto               ,tv_tasacupon                  ,tv_tasanominalperiodo        ,tv_vigenciatasavariable     ,tv_tasareferencia        ,  
      tv_nemotecnico             ,tv_margenactual               ,tv_utilidadperdidamercado    ,tv_preciomercado            ,tv_resumen365mercado     ,  
      tv_valorpresentemercado    ,tv_utilidaperdidatircompra    ,tv_precio_tircompra          ,tv_valorpresentetircompra   ,tv_refval                ,  
      tv_diasvcto                ,tv_tircompra                  ,tv_duracion                  ,tv_duracionmodificada       ,tv_tipovcto              ,  
      tv_plazovcto               ,tv_fechavalor                 ,tv_aplicativo                ,tv_empresa                  ,tv_fecha_proc            ,tv_origen)           
	   select   
      tv_portafolio              ,tv_producto                   ,tv_estadoinversion           ,tv_valorgarantia            ,tv_referencia            ,  
      tv_razonsocial             ,tv_valorcompra                ,tv_valornominal              ,tv_fechacompra              ,tv_fechaemision          ,  
      tv_fechavcto               ,tv_tasacupon                  ,tv_tasanominalperiodo        ,tv_vigenciatasavariable     ,tv_tasareferencia        ,  
      tv_nemotecnico             ,tv_margenactual               ,tv_utilidadperdidamercado    ,tv_preciomercado            ,tv_resumen365mercado     ,  
      tv_valorpresentemercado    ,tv_utilidaperdidatircompra    ,tv_precio_tircompra          ,tv_valorpresentetircompra   ,tv_refval                ,  
      tv_diasvcto                ,tv_tircompra                  ,tv_duracion                  ,tv_duracionmodificada       ,tv_tipovcto              ,  
      tv_plazovcto               ,tv_fechavalor                 ,tv_aplicativo                ,tv_empresa                  ,tv_fecha_proc            ,tv_origen                       
      from  cob_externos..ex_tipo_vencimientos
      where tv_fecha_proc = @i_fecha_proceso  
      and   tv_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_TIPO_VENCIMIENTOS')  
      if @w_reg > 0 insert into #control values ( 'tipo_vencimientos'  )

   end -- operacion TV
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DE BANCOS 
   if @i_toperacion in ('DB','TO') begin  
         
      -- ELIMINANDO DATOS EN SB_DATO_BANCOS
      if exists (select 1 from cob_externos..ex_dato_bancos where db_fecha = @i_fecha_proceso and db_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_bancos where db_fecha = @i_fecha_proceso and db_aplicativo = @w_aplicativo) begin  
            delete sb_dato_bancos  
            where db_fecha      = @i_fecha_proceso  
            and   db_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_BANCOS')          
             
      -- INSERTANDO DATOS EN SB_DATO_BANCOS 
      insert into cob_conta_super..sb_dato_bancos(  
      db_fecha,     db_aplicativo,    db_empresa,    db_banco,
      db_tcuenta,   db_cuenta,        db_moneda,     db_saldo)
      select   
      db_fecha,     db_aplicativo,    db_empresa,    db_banco,
      db_tcuenta,   db_cuenta,        db_moneda,     db_saldo 
      from cob_externos..ex_dato_bancos  
      where db_fecha      = @i_fecha_proceso  
      and   db_aplicativo = @w_aplicativo             
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_BANCOS')  
      if @w_reg > 0 insert into #control values ( 'dato_bancos'  )

   end -- operacion DB
   */
   
   /*DATOS DE HECHOS VIOLENTOS*/
   if @i_toperacion in ('HV','TO') begin

      /*** ELIMINA DATOS EN SB_DATO_HECHOS_VIOLENTOS***/
      delete cob_conta_super..sb_dato_hechos_violentos
      where  dh_fecha      = @i_fecha_proceso
      and    dh_aplicativo = @w_aplicativo

      /*** INSERTA DATOS EN SB_DATO_HECHOS_VIOLENTOS ***/
      insert into cob_conta_super..sb_dato_hechos_violentos(
      dh_fecha,           dh_cliente,         dh_tramite,                     dh_fecha_radicacion,
      dh_toperacion,      dh_rechazado,       dh_causa_rechazo,               dh_evento,
      dh_fecha_evento,    dh_ciudad_evento,   dh_municipio_evento,            dh_corregimiento_evento,
      dh_inspeccion,      dh_vereda,          dh_sitio,                       dh_destino,
      dh_aplicativo,      dh_origen,          dh_fecha_proc)
      select
      dh_fecha,           dh_cliente,         dh_tramite,                     dh_fecha_radicacion,
      dh_toperacion,      dh_rechazado,       isnull(dh_causa_rechazo,''),    dh_evento,
      dh_fecha_evento,    dh_ciudad_evento,   dh_municipio_evento,            dh_corregimiento_evento,
      dh_inspeccion,      dh_vereda,          dh_sitio,                       dh_destino,
      dh_aplicativo,      dh_origen,          dh_fecha_proc
      from cob_externos..ex_dato_hechos_violentos
      where dh_fecha = @i_fecha_proceso
      and   dh_aplicativo = @w_aplicativo
   
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_HECHOS_VIOLENTOS')  
      if @w_reg > 0 insert into #control values ('dato_hechos_violentos')

   
      /*** ACTUALIZANDO CODIGO DE CLIENTE BANCAMIA PARA AQUELLOS QUE NO EXISTEN EN COBIS ***/
      update cob_conta_super..sb_dato_hechos_violentos
      set    dh_cliente = @w_banco
      where  dh_cliente = 0
      and    dh_fecha   = @i_fecha_proceso
   
      /*** INSERTANDO LOG DE ERRORES ***/
      if @@error <> 0 insert into #errores values ((select dh_tramite + dh_toperacion
      from cob_conta_super..sb_dato_hechos_violentos
      where  dh_cliente = 0
      and    dh_fecha   = @i_fecha_proceso),'ERROR CLIENTE NO EXISTE')
  
   end

   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   if @i_toperacion in ('CG','TO') begin
     
      -- ELIMINA DATOS EN SB_DATO_CUSTODIA
      if exists (select 1 from cob_externos..ex_dato_custodia where dc_fecha = @i_fecha_proceso and dc_aplicativo = @w_aplicativo) 
      begin
         delete cob_conta_super..sb_dato_custodia
         where  dc_aplicativo = @w_aplicativo
         and    dc_fecha      = @i_fecha_proceso 
      end
      
      INSERTA DATOS EN SB_DATO_CUSTODIA
      insert into #dato_custodia
      select * from cob_externos..ex_dato_custodia
      where dc_fecha      = @i_fecha_proceso
      and   dc_aplicativo = @w_aplicativo
   
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN #DATO_CUSTODIA')  
      if @w_reg > 0 insert into #control values ('dato_custodia')
        
     
      -- ACTUALIZANDO CODIGO DE CLIENTE
      update #dato_custodia
      set    dc_cliente          = en_ente
      from   cobis..cl_ente
      where  dc_cliente          = 0
      and    dc_fecha            = @i_fecha_proceso
      and    dc_documento_tipo   = en_ced_ruc
      and    dc_documento_numero = en_ced_ruc
    
      -- ACTUALIZANDO CODIGO DE CLIENTE BANCAMIA PARA AQUELLOS QUE NO EXISTEN EN COBIS
      update #dato_custodia
      set    dc_cliente = @w_banco
      where  dc_cliente = 0
      and    dc_fecha   = @i_fecha_proceso
   
      if @@error <> 0 insert into #errores values ('3600002', 'ERROR AL ACTUALIZAR LA TABLA #DATO_CUSTODIA')
      
      insert into cob_conta_super..sb_dato_custodia(
      dc_fecha,                       dc_aplicativo,             dc_garantia,               dc_oficina,
      dc_cliente,                     dc_categoria,              dc_tipo,                   dc_idonea,
      dc_fecha_avaluo,                dc_moneda,                 dc_valor_avaluo,           dc_valor_actual,
      dc_estado,                      dc_abierta,                dc_num_reserva,            dc_documento_tipo,      
      dc_documento_numero,            dc_calidad_gar,            dc_valor_uti_opera,        dc_origen,    
      dc_fecha_proc,                  dc_empresa,                dc_fideicomiso_id,         dc_fiduciaria_nombre,     
      dc_ubicacion_pais,              dc_registro_id,            dc_registro_emisor,        dc_registro_custodio,  
      dc_hipoteca_id,                 dc_poliza_id,              dc_poliza_aseguradora,     dc_poliza_fecha, 
      dc_avaluador_id,                dc_valor_inicial,          dc_instr_financiero,       dc_emisor_calif,       
      dc_emision_calif,               dc_fecha_vencimiento,      dc_fuente_valor,           dc_compartida_otras_entidades,   
      dc_porcentaje_max_cobertura,    dc_ubicacion_provincia,    dc_ubicacion_canton,       dc_ubicacion_direccion,  
      dc_ubicacion_telefono,          dc_descripcion,            dc_garantia_aplicativo,    dc_garantia_banco,         
      dc_fecha_ingreso,               dc_garante,                dc_oficial,                dc_fecha_cambio_estado,
      dc_usuario_cambio,              dc_ubicacion_distrito)      
      select 
      dc_fecha,                       dc_aplicativo,             dc_garantia,               dc_oficina,
      dc_cliente,                     dc_categoria,              dc_tipo,                   dc_idonea,
      dc_fecha_avaluo,                dc_moneda,                 dc_valor_avaluo,           dc_valor_actual,
      dc_estado,                      dc_abierta,                dc_num_reserva,            dc_documento_tipo,      
      dc_documento_numero,            dc_calidad_gar,            dc_valor_uti_opera,        dc_origen,    
      dc_fecha_proc,                  dc_empresa,                dc_fideicomiso_id,         dc_fiduciaria_nombre,     
      dc_ubicacion_pais,              dc_registro_id,            dc_registro_emisor,        dc_registro_custodio,  
      dc_hipoteca_id,                 dc_poliza_id,              dc_poliza_aseguradora,     dc_poliza_fecha, 
      dc_avaluador_id,                dc_valor_inicial,          dc_instr_financiero,       dc_emisor_calif,       
      dc_emision_calif,               dc_fecha_vencimiento,      dc_fuente_valor,           dc_compartida_otras_entidades,   
      dc_porcentaje_max_cobertura,    dc_ubicacion_provincia,    dc_ubicacion_canton,       dc_ubicacion_direccion,  
      dc_ubicacion_telefono,          dc_descripcion,            dc_garantia_aplicativo,    dc_garantia_banco,         
      dc_fecha_ingreso,               dc_garante,                dc_oficial,                dc_fecha_cambio_estado,
      dc_usuario_cambio,              dc_ubicacion_distrito
      from  #dato_custodia
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_CUSTODIA')  
      if @w_reg > 0 insert into #control values ('dato_custodia')
      
	  
      -- ELIMINA DATOS EN SB_DATO_GARANTIA
      if exists (select 1 from cob_conta_super..sb_dato_garantia  where dg_fecha = @i_fecha_proceso and dg_aplicativo = @w_aplicativo) begin
         delete cob_conta_super..sb_dato_garantia
         where  dg_aplicativo = @w_aplicativo
         and    dg_fecha      = @i_fecha_proceso 
      end 

      -- INSERTA DATOS EN SB_DATO_GARANTIA
      insert into cob_conta_super..sb_dato_garantia(
      dg_fecha,              dg_banco,              dg_toperacion,
      dg_aplicativo,         dg_garantia,           dg_cobertura,
      dg_origen,             dg_fecha_proc,         dg_cobertura_cap,
      dg_cobertura_int,      dg_valor_cobertura,    dg_empresa,
      dg_banco_naturaleza)
      select
      dg_fecha,              dg_banco,              dg_toperacion,
      dg_aplicativo,         dg_garantia,           dg_cobertura,
      dg_origen,             dg_fecha_proc,         dg_cobertura_cap,
      dg_cobertura_int,      dg_valor_cobertura,    dg_empresa,
      dg_banco_naturaleza
      from  cob_externos..ex_dato_garantia
      where dg_fecha = @i_fecha_proceso
      and   dg_aplicativo = @w_aplicativo
   
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_GARANTIA')  
      if @w_reg > 0 insert into #control values ('dato_garantia')
   
      -- Movimiento Provision - Version Falabella
      if exists (select 1 from sb_mov_provision where mp_fecha = @i_fecha_proceso and mp_aplicativo = @w_aplicativo) begin
         delete sb_mov_provision
         where  mp_fecha      = @i_fecha_proceso
         and    mp_aplicativo = @w_aplicativo
      end
   
      insert into sb_mov_provision (
      mp_fecha,          mp_cliente,  mp_oficina,
      mp_clase_cartera,  mp_tipo,     mp_rubro,
      mp_calificacion,   mp_gasto,    mp_ingreso,
      mp_aplicativo,     mp_origen,   mp_fecha_proc)
      select
      mp_fecha,          mp_cliente,  mp_oficina,
      mp_clase_cartera,  mp_tipo,     mp_rubro,
      mp_calificacion,   mp_gasto,    mp_ingreso,
      mp_aplicativo,     mp_origen,   mp_fecha_proc
      from  cob_externos..ex_mov_provision
      where mp_fecha = @i_fecha_proceso

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_MOV_PROVISION')  
      if @w_reg > 0 insert into #control values ('mov_provision')

   end
   */

   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   -- DATOS DECLARACION TRIBUTARIA
   if @i_toperacion in ('SD','TO')  begin  --FORMATO 1012
         
      select 
      @w_secuencial    = 0,
      @w_existe        = 'S',
      @i_descrp_error  = 'NO EXISTEN CONCEPTOS FORMATO-1012  : '
         
      create table #concepto (
      secuencial  int identity(1,1),
      concepto    varchar(10)   null
      )     
         
      insert into #concepto (concepto) 
      select distinct dt_concepto
      from cob_externos..ex_dato_declaracionT

      select @w_tabla = codigo 
      from cobis..cl_tabla 
      where tabla = 'sit_concepto_declaracionT'
         
      while 1=1 begin
     
         select top 1
         @w_secuencial = secuencial,
         @w_concepto   = concepto
         from #concepto
         where secuencial >= @w_secuencial
         order by secuencial
       
         if @@rowcount = 0 break
         
         if not exists ( select 1 from cobis..cl_catalogo where tabla  = @w_tabla and codigo = @w_concepto)
         begin
            select @w_existe  = 'N'
            select @w_concepto = @w_concepto + '  '
            select @i_descrp_error  =  @i_descrp_error + @w_concepto 
         end   
        
         select @w_secuencial  =  @w_secuencial + 1
      end   
         
      drop table #concepto
   
      if @w_existe  = 'N' insert into #errores values('3600003', 'ERROR AL ELIMINAR TABLA')
         
      -- ELIMINA DATOS EN SB_DATO_DECLARACIONT
      truncate table sb_dato_declaracionT
         
      -- INSERTA DATOS EN SB_DATO_DECLARACIONT
      insert into cob_conta_super..sb_dato_declaracionT(
      dt_fecha,      dt_concepto,      dt_tdoc,
      dt_documento,  dt_monto,         dt_aplicativo,
      dt_origen,     dt_secuencial)
           
      select 
      dt_fecha,      dt_concepto,      dt_tdoc,
      dt_documento,  dt_monto,         dt_aplicativo,
      dt_origen,     dt_secuencial
      from cob_externos..ex_dato_declaracionT
      where dt_fecha      = @i_fecha_proceso
      and   dt_aplicativo = @w_aplicativo
   
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_DECLARACIONT')  
      if @w_reg > 0 insert into #control values ('dato_declaracionT')

   end --operacion SD
   */
         
   if @i_toperacion in ('FA','TO') and datepart(dd,@i_fecha_proceso)=31 and datepart(mm,@i_fecha_proceso)=12
   begin    
         
      /***ELIMINANDO DATOS EN sb_dato_fatca ***/   
      if exists (select 1 from sb_dato_fatca  
      where df_fecha      =  @i_fecha_proceso
      and df_origen       <> @w_origen
      and df_aplicativo   =  @w_aplicativo)  
      begin            
         delete sb_dato_fatca    
         where df_fecha      = @i_fecha_proceso  
         and df_origen      <> @w_origen
         and df_aplicativo   =  @w_aplicativo
      end   
         
      /*Valida existencia*/  
      select  @w_existencia =pa_char
      from   cobis..cl_parametro  
      where  pa_nemonico    = 'EXDAT'  
      and    pa_producto    = 'SUP' 
     
      if @@rowcount = 0 insert into #errores values ('360020', 'NO EXISTE PARAMETRO EXDAT QUE VALIDA EXISTENCIA CLIENTES FATCA')  
         
      select @w_existencia=isnull(@w_existencia,'N')

      insert into #dato_fatca  
     (df_fecha,                 df_empresa,        df_tipo_identificacion,
      df_numero_identificacion, df_nombre,         df_direccion,             
      df_producto,              df_valor_producto, df_intereses,             
      df_fecha_proc,            df_aplicativo,     df_origen,                
      df_cod_prod)
      select 
      df_fecha,                 df_empresa,        df_tipo_identificacion,
      df_numero_identificacion, df_nombre,         df_direccion,             
      df_producto,              df_valor_producto, df_intereses,             
      df_fecha_proc,            df_aplicativo,     df_origen,                
      df_cod_prod 
      from cob_externos..ex_dato_fatca  a
      where df_fecha      = @i_fecha_proceso
      and df_aplicativo   =  @w_aplicativo
      if @@error <> 0 insert into #errores values ('360021','ERROR EN CONSOLIDACION DE DATOS FATCA') 

      create index [idx1] on [#dato_fatca] (df_fecha)    
          
      if @w_existencia='S'
      begin 
         update #dato_fatca  
         set df_cliente=en_ente, df_nombre = en_nomlar,    df_subtipo=en_subtipo
         from cobis..cl_ente 
         where en_ced_ruc=df_numero_identificacion 
         and  en_tipo_ced = df_tipo_identificacion
          
         if exists (select 1 from  cob_conta_super..sb_dato_direccion where dd_fecha=@i_fecha_proceso)
         begin
            update #dato_fatca 
            set df_direccion = dd_descripcion 
            from cob_conta_super..sb_dato_direccion
            where df_fecha = @i_fecha_proceso
            and  df_cliente=dd_cliente
            and  dd_principal ='S'
            and  dd_direccion=1 
         end   
         
         update sb_dato_fatca  
         set df_direccion=di_descripcion
         from cobis..cl_direccion
         where  df_cliente=di_ente
         and  di_direccion=1 
         and  di_principal ='S'
            
      end else begin
     
         update #dato_fatca  set df_cliente=en_ente, df_subtipo=en_subtipo
         from cobis..cl_ente 
         where en_ced_ruc=df_numero_identificacion and  en_tipo_ced = df_tipo_identificacion
      end   
      
      update #dato_fatca set 
      df_nombre        = dbo.CaracteresEspeciales(df_nombre),     -- KDR 19/09/2022 Se cambia a nuevo nombre de funcion CaracteresEspeciales
      df_direccion     = dbo.CaracteresEspeciales(df_direccion) 
         
      --borra de la temporal los registros preexistentes del cargue de fatca  para no subirlos otra vez
      delete #dato_fatca   from  #dato_fatca A, sb_dato_fatca B 
      where  A.df_cliente= B.df_cliente and A.df_fecha=B.df_fecha and A.df_empresa=B.df_empresa
      and   A.df_producto=B.df_producto
         
  update #dato_fatca 
      set df_nombre        = dbo.CaracteresEspeciales(df_nombre),
      df_direccion     = dbo.CaracteresEspeciales(df_direccion) 
                
      if exists(select 1 from  #dato_fatca  where df_cliente is  null)
      begin  
         insert into #errores values ('3600002','ERROR EL CAMPO DF_CLIENTE(ENTE) TIENE VALORES NULOS') 
      end         
         
      /*** INSERTA DATOS EN SB_DATO_FATCA ***/  
      insert into cob_conta_super..sb_dato_fatca( 
      df_fecha,                 df_empresa,               df_cliente,    
      df_tipo_identificacion,   df_numero_identificacion, df_nombre,    
      df_direccion,             df_subtipo,               df_cod_prod,        
      df_valor_producto,        df_producto,              df_intereses,
      df_fecha_proc,            df_aplicativo,            df_origen) 
      select 
      df_fecha,                 df_empresa,               df_cliente,    
      df_tipo_identificacion,   df_numero_identificacion, df_nombre,    
      df_direccion,             df_subtipo,               df_cod_prod,        
      df_valor_producto,        df_producto,              df_intereses,
      df_fecha_proc,            df_aplicativo,            df_origen  
      from #dato_fatca 
   
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_FATCA')  
      if @w_reg > 0 insert into #control values ('dato_fatca')

   end  

   --TABLAS DE PASIVAS
   If @i_toperacion in ('PA','TO') 
   BEGIN
      
       /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      If exists (select 1 from sb_dato_pasivas where dp_fecha = @i_fecha_proceso and dp_aplicativo = @w_aplicativo) 
      Begin
         Delete sb_dato_pasivas
         Where dp_aplicativo = @w_aplicativo
         And   dp_fecha      = @i_fecha_proceso
         
         If @@error <> 0 insert into #errores values ('3600003', 'ERROR ELIMINANDO DATOS EN SB_DATO_PASIVAS')
      End

      -- Insercion de Registros por Fecha de Proceso
      Insert Into cob_conta_super..sb_dato_pasivas(
      dp_fecha,              dp_banco,              dp_toperacion,         dp_aplicativo,
      dp_categoria_producto, dp_naturaleza_cliente, dp_cliente,            dp_oficina,      
      dp_oficial,            dp_moneda,             dp_monto,              dp_tasa,               
      dp_modalidad,          dp_plazo_dias,         dp_fecha_apertura,     dp_fecha_radicacion,
      dp_fecha_vencimiento,  dp_num_renovaciones,   dp_estado,             dp_razon_cancelacion,  
      dp_num_cuotas,         dp_periodicidad_cuota, dp_saldo_disponible,   dp_saldo_int,          
      dp_saldo_camara12h,    dp_saldo_camara24h,    dp_saldo_camara48h,    dp_saldo_remesas,      
      dp_condicion_manejo,   dp_exen_gmf,           dp_fecha_ini_exen_gmf, dp_fecha_fin_exen_gmf, 
      dp_tesoro_nacional,    dp_ley_exen           ,dp_tasa_variable      ,dp_referencial_tasa,
      dp_signo_spread       ,dp_spread             ,dp_signo_puntos       ,dp_puntos,
      dp_signo_tasa_ref     ,dp_puntos_tasa_ref    ,dp_cupo_sgiro_aut     ,dp_dias_sgiro_aut,
      dp_fecha_sgiro_aut    ,dp_fecha_ult_proc     ,dp_valor_bloqueos     ,dp_valor_pignoraciones,
      dp_empresa            ,dp_documento_tipo     ,dp_documento_numero   ,dp_ciudad,
      dp_pais               ,dp_area               ,dp_origen             ,dp_fecha_proc, 
      dp_provisiona         ,dp_toperacion_desc)
      Select 
      dp_fecha,              dp_banco,              dp_toperacion,         dp_aplicativo,
      dp_categoria_producto, dp_naturaleza_cliente, dp_cliente,            dp_oficina,   
      dp_oficial,            dp_moneda,             dp_monto,              dp_tasa,               
      dp_modalidad,          dp_plazo_dias,         dp_fecha_apertura,     dp_fecha_radicacion,
      dp_fecha_vencimiento,  dp_num_renovaciones,   dp_estado,             dp_razon_cancelacion,  
      dp_num_cuotas,         dp_periodicidad_cuota, dp_saldo_disponible,   dp_saldo_int,          
      dp_saldo_camara12h,    dp_saldo_camara24h,    dp_saldo_camara48h,    dp_saldo_remesas,      
      dp_condicion_manejo,   dp_exen_gmf,           dp_fecha_ini_exen_gmf, dp_fecha_fin_exen_gmf, 
      dp_tesoro_nacional,    dp_ley_exen           ,dp_tasa_variable      ,dp_referencial_tasa,
      dp_signo_spread       ,dp_spread             ,dp_signo_puntos       ,dp_puntos,
      dp_signo_tasa_ref     ,dp_puntos_tasa_ref    ,dp_cupo_sgiro_aut     ,dp_dias_sgiro_aut,
      dp_fecha_sgiro_aut    ,dp_fecha_ult_proc     ,dp_valor_bloqueos     ,dp_valor_pignoraciones,
      dp_empresa            ,dp_documento_tipo     ,dp_documento_numero   ,dp_ciudad,
      dp_pais               ,dp_area               ,dp_origen             ,dp_fecha_proc, 
      dp_provisiona         ,dp_toperacion_desc
      From cob_externos..ex_dato_pasivas
      Where dp_fecha      = @i_fecha_proceso
      and   dp_aplicativo = @w_aplicativo
   
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
  
      if @w_error <> 0 insert into #errores values ('3600001','ERROR INSERTANDO DATOS EN SB_DATO_PASIVAS')  
      if @w_reg    > 0 insert into #control values ('dato_pasivas')
      */
      --WLO
      --If exists (Select 1 From  sb_dato_bloqueo where bo_fecha = @i_fecha_proceso and bo_aplicativo = @w_aplicativo) 
      --Begin
      --   Delete sb_dato_bloqueo
      --   Where  bo_aplicativo = @w_aplicativo
      --   and    bo_fecha      = @i_fecha_proceso
      --    
      --   If @@error <> 0 insert into #errores values ('3600002','ERROR ELIMINANDO DATOS EN SB_DATO_BLOQUEO')
      --End
      
      -- Insercion de Bloqueos  'A'
     -- Insert Into #dato_bloqueo
     --(bo_fecha ,              bo_banco,                bo_aplicativo,
     -- bo_secuencial,          bo_secuencial_ref,       bo_causa_bloqueo,
     -- bo_fecha_bloqueo,       bo_fecha_desbloqueo,     bo_estado,      
     -- bo_origen,              bo_fecha_proc,           bo_funcionario)
     -- Select * from cob_externos..ex_dato_bloqueo
     -- where bo_fecha      = @i_fecha_proceso
     -- and   bo_estado     =  'A'
     -- and   bo_aplicativo = @w_aplicativo
  
      --select 
      --@w_error = @@error,
      --@w_reg   = @@rowcount
   
      --if @w_error <> 0 insert into #errores values ('3600001','ERROR INSERTANDO DATOS EN SB_dato_bloqueo')  
      --if @w_reg    > 0 insert into #control values ('dato_bloqueo')
   
      -- Actualizacion de Bloqueos A -> C
      --Update #dato_bloqueo Set 
      --bo_fecha_desbloqueo = bo_fecha_bloqueo,
      --bo_estado           = bo_estado,
      --bo_fecha_modif      = Convert(Varchar(10),Getdate(),101)      
      --where bo_fecha      = @i_fecha_proceso
      --and   bo_estado  = 'C'

      --Insert Into sb_dato_bloqueo (
      --bo_fecha,         bo_banco,         bo_aplicativo,       bo_secuencial, bo_secuencial_ref,
      --bo_causa_bloqueo, bo_fecha_bloqueo, bo_fecha_desbloqueo, bo_estado,     bo_fecha_modif,
      --bo_origen,        bo_fecha_proc,	  bo_funcionario)
      --Select
      --bo_fecha,         bo_banco,         bo_aplicativo,       bo_secuencial, bo_secuencial_ref,
      --bo_causa_bloqueo, bo_fecha_bloqueo, bo_fecha_desbloqueo, bo_estado,     Convert(Varchar(10),Getdate(),101),
      --bo_origen,        bo_fecha_proc,	  bo_funcionario
      --from #dato_bloqueo

      --If @@error <> 0 insert into #errores values ('3600002', 'ERROR ACTUALIZANDO BLOQUEOS EN SB_dato_bloqueo')
       
      if (datepart(mm,@w_siguiente_dia) <> datepart(mm,@i_fecha_proceso)) 
      begin

         /*** ELIMINA DATOS EN TRAN MENSUAL Y RECHAZOS DE TRANSACCIONES***/
      If exists (Select 1 From  sb_tran_mensual a,cob_externos..ex_tran_mensual b where a.tm_ano=b.tm_ano and a.tm_mes=b.tm_mes and a.tm_cuenta=b.tm_cuenta and a.tm_cod_trn=b.tm_cod_trn and a.tm_cantidad=b.tm_cantidad) 
      Begin
        --Ajuste por traduccion 
         create table #tran_mensual(
         temp_tm_ano                             char(4)                   not null,      
         temp_tm_mes                                         char(2)                       not null,      
         temp_tm_cuenta                                      varchar(24)                   not null,      
         temp_tm_cod_trn                                     int                           not null,      
         temp_tm_cantidad                                    int                           not null
         )
       
         insert into #tran_mensual
         select * from sb_tran_mensual a, cob_externos..ex_tran_mensual b
         where a.tm_ano=b.tm_ano
         and a.tm_mes=b.tm_mes 
         and a.tm_cuenta=b.tm_cuenta 
         and a.tm_cod_trn=b.tm_cod_trn 
         and a.tm_cantidad=b.tm_cantidad
   
   
         Delete sb_tran_mensual
         from #tran_mensual
         where tm_ano=temp_tm_ano
         and tm_mes=temp_tm_mes 
         and tm_cuenta=temp_tm_cuenta 
         and tm_cod_trn=temp_tm_cod_trn 
         and tm_cantidad=temp_tm_cantidad
       
         If @@error <> 0 insert into #errores values ('3600002','ERROR ELIMINANDO DATOS EN SB_TRAN_MENSUAL')
      End       
         Insert Into cob_conta_super..sb_tran_mensual(  
         tm_ano,                tm_mes,               tm_cuenta,                              
         tm_cod_trn,            tm_cantidad
         )
         Select 
         tm_ano,                tm_mes,               tm_cuenta,                              
         tm_cod_trn,            tm_cantidad 
         From cob_externos..ex_tran_mensual

         select 
         @w_error = @@error,
         @w_reg   = @@rowcount

         if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_TRAN_MENSUAL')  
         if @w_reg > 0 insert into #control values ('tran_mensual')
      
         Insert Into cob_conta_super..sb_tran_rechazos(  
         tr_fecha,              tr_oficina,               tr_cod_cliente,         tr_id_cliente,                            
         tr_nom_cliente,        tr_cta_banco,             tr_tipo_tran,           tr_nom_tran,
         tr_vlr_comision,       tr_vlr_iva,               tr_modulo,              tr_causal_rech   
         )
         Select 
         tr_fecha,              tr_oficina,               tr_cod_cliente,         tr_id_cliente,                            
         tr_nom_cliente,        tr_cta_banco,             tr_tipo_tran,           tr_nom_tran,
         tr_vlr_comision,       tr_vlr_iva,               tr_modulo,              tr_causal_rech 
         From cob_externos..ex_tran_rechazos

         select 
         @w_error = @@error,
         @w_reg   = @@rowcount

         if @w_error <> 0 insert into #errores values ('3600001','ERROR INSERTANDO DATOS EN SB_TRAN_RECHAZOS')  
         if @w_reg    > 0 insert into #control values ('tran_rechazos')

      end

      /*** REQ 453: PASO DE INFORMACION DE RELACIONES A CANALES ***/
      If exists (Select 1 From  sb_relacion_canal Where rc_fecha_proceso = @i_fecha_proceso And rc_aplicativo = @w_aplicativo) 
      Begin
         Delete sb_relacion_canal
         Where rc_aplicativo    = @w_aplicativo
         And   rc_fecha_proceso = @i_fecha_proceso
          
         If @@error <> 0 insert into #errores values ('3600003','ERROR ELIMINANDO DATOS EN SB_RELACION_CANAL')
      End

      -- Insercion de Relacion a Canal
      Insert Into sb_relacion_canal (
      rc_cuenta,        rc_cliente,          rc_tel_celular,    rc_tarj_debito,
      rc_canal,         rc_motivo,           rc_estado,         rc_fecha,
      rc_fecha_mod,     rc_usuario,          rc_subtipo,        rc_tipo_operador,
      rc_aplicativo,    rc_fecha_proceso)
      select
      rc_cuenta,        rc_cliente,          rc_tel_celular,    rc_tarj_debito,
      rc_canal,         rc_motivo,           rc_estado,         rc_fecha,
      rc_fecha_mod,     rc_usuario,          rc_subtipo,        rc_tipo_operador,
      rc_aplicativo,    rc_fecha_proceso
      from cob_externos..ex_relacion_canal
      where rc_fecha_proceso  = @i_fecha_proceso
      and   rc_aplicativo     = @w_aplicativo
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_RELACION_CANAL')  
      if @w_reg    > 0 insert into #control values ('relacion_canal')


   end -- FIN PASIVAS

           
   /* DATOS GENERALES DE CLIENTES */  
   if @i_toperacion = 'CL' or @i_toperacion = 'TO' BEGIN
   
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso  
      -- ELIMINA DATOS EN SB_DATO_CLIENTE 
      if exists (select 1 from cob_externos..ex_dato_cliente where dc_fecha = @i_fecha_proceso and dc_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_cliente where dc_fecha = @i_fecha_proceso  and dc_aplicativo = @w_aplicativo) begin  
            delete sb_dato_cliente where dc_fecha  = @i_fecha_proceso  and dc_aplicativo = @w_aplicativo
         end   
      end
      else insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_CLIENTE')  
       
      -- INSERTA DATOS EN SB_DATO_CLIENTE  
      insert into cob_conta_super..sb_dato_cliente(  
      dc_fecha             ,dc_cliente         ,dc_tipo_ced            ,  
      dc_ced_ruc           ,dc_nombre          ,dc_p_apellido          ,  
      dc_s_apellido        ,dc_subtipo         ,dc_oficina             ,  
      dc_oficial           ,dc_sexo            ,dc_actividad           ,  
      dc_retencion         ,dc_sector          ,dc_situacion_cliente   ,  
      dc_victima           ,dc_exc_sipla       ,dc_estado_civil        ,  
      dc_nivel_ing         ,dc_nivel_egr       ,dc_fecha_ingreso       ,  
      dc_fecha_mod         ,dc_fecha_nac       ,dc_ciudad_nac          ,  
      dc_iden_conyuge      ,dc_tipo_doc_cony   ,dc_p_apellido_cony     ,  
      dc_s_apellido_cony   ,dc_nombre_cony     ,dc_estrato             ,  
      dc_tipo_vivienda     ,dc_pais            ,dc_nivel_estudio       ,  
      dc_num_carga         ,dc_PEP             ,dc_fecha_vinculacion   ,  
      dc_hipoteca_viv      ,dc_num_activas     ,dc_estado_cliente      ,  
      dc_banca             ,dc_segmento        ,dc_subsegmento         ,  
      dc_actprincipal      ,dc_actividad2      ,dc_actividad3          ,  
      dc_bancarizado       ,dc_alto_riesgo     ,dc_fecha_riesgo        ,      
      dc_perf_tran         ,dc_riesgo          ,dc_nit                 ,                 
      dc_aplicativo        ,dc_origen          ,dc_fecha_proc          ,           
      dc_tamano_empresa    ,dc_razon_social    ,dc_grupo_documento     ,
      dc_tipo_vinculacion  ,dc_grupo_nombre    ,dc_tipo_ente           ,
      dc_seg_comercial     ,dc_seg_riesgo)  
      select   
      dc_fecha             ,dc_cliente         ,dc_tipo_ced            ,  
      dc_ced_ruc           ,dc_nombre          ,dc_p_apellido          ,  
      dc_s_apellido        ,dc_subtipo         ,dc_oficina             ,  
      dc_oficial           ,dc_sexo            ,dc_actividad           ,  
      dc_retencion         ,dc_sector          ,dc_situacion_cliente   ,  
      dc_victima           ,dc_exc_sipla       ,dc_estado_civil        ,  
      dc_nivel_ing         ,dc_nivel_egr       ,dc_fecha_ingreso       ,  
      dc_fecha_mod         ,dc_fecha_nac       ,dc_ciudad_nac          ,  
      dc_iden_conyuge      ,dc_tipo_doc_cony   ,dc_p_apellido_cony     ,  
      dc_s_apellido_cony   ,dc_nombre_cony     ,dc_estrato             ,  
      dc_tipo_vivienda     ,dc_pais            ,dc_nivel_estudio       ,  
      dc_num_carga         ,dc_PEP             ,dc_fecha_vinculacion   ,  
      dc_hipoteca_viv      ,dc_num_activas     ,dc_estado_cliente      ,  
      dc_banca            ,dc_segmento        ,dc_subsegmento         ,  
      dc_actprincipal      ,dc_actividad2      ,dc_actividad3          ,  
      dc_bancarizado      ,dc_alto_riesgo     ,dc_fecha_riesgo        ,      
      dc_perf_tran         ,dc_riesgo          ,dc_nit                 ,                 
      dc_aplicativo        ,dc_origen          ,dc_fecha_proc          ,           
      dc_tamano_empresa    ,dc_razon_social    ,dc_grupo_documento     ,
      dc_tipo_vinculacion  ,dc_grupo_nombre    ,dc_tipo_ente           ,
      dc_seg_comercial    ,dc_seg_riesgo
      from cob_externos..ex_dato_cliente  
      where dc_fecha      = @i_fecha_proceso        
      and   dc_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_CLIENTE')  
      if @w_reg > 0 insert into #control values ('dato_cliente')
      */
      
       /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      -- ELIMINA DATOS EN SB_DATO_DIRECCION     
      if exists (select 1 from cob_externos..ex_dato_direccion where dd_fecha = @i_fecha_proceso and   dd_aplicativo = @w_aplicativo ) begin        
         if exists (select 1 from sb_dato_direccion where dd_fecha = @i_fecha_proceso and   dd_aplicativo = @w_aplicativo)
         begin  
            delete sb_dato_direccion 
            where dd_fecha      = @i_fecha_proceso
            and   dd_aplicativo = @w_aplicativo  
         end   
      end
      else insert into #errores values('3600003','ERROR NO EXISTE INFORMACION PARA LA FECHA EN EX_DATO_DIRECCION')
            
      insert into cob_conta_super..sb_dato_direccion(  
      dd_fecha                ,dd_cliente             ,dd_direccion   ,  
      dd_descripcion          ,dd_ciudad              ,dd_tipo        ,  
      dd_fecha_ingreso        ,dd_fecha_modificacion  ,dd_principal   ,  
      dd_rural_urb            ,dd_provincia           ,dd_parroquia   ,
      dd_aplicativo           ,dd_origen              ,dd_fecha_proc  ,   
      dd_documento_tipo       ,dd_lat_geo             ,dd_long_geo)  
      select  
      dd_fecha                ,dd_cliente             ,dd_direccion   ,  
      dd_descripcion          ,dd_ciudad              ,dd_tipo        ,  
      dd_fecha_ingreso        ,dd_fecha_modificacion  ,dd_principal   ,  
      dd_rural_urb            ,dd_provincia           ,dd_parroquia   ,
      dd_aplicativo           ,dd_origen              ,dd_fecha_proc  ,   
      dd_documento_tipo       ,dd_lat_geo             ,dd_long_geo
      from cob_externos..ex_dato_direccion  
      where dd_fecha      = @i_fecha_proceso     
      and   dd_aplicativo = @w_aplicativo  
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_DIRECCION')  
      if @w_reg > 0 insert into #control values ('dato_direccion')
      */
   
      if exists (select 1 from cob_externos..ex_dato_telefono where dt_fecha = @i_fecha_proceso and dt_aplicativo = @w_aplicativo)  begin      
         if exists (select 1 from sb_dato_telefono where dt_fecha = @i_fecha_proceso and dt_aplicativo = @w_aplicativo)  begin
            delete sb_dato_telefono where dt_fecha  = @i_fecha_proceso and dt_aplicativo = @w_aplicativo 
         end   
      end      
      else insert into #errores values('3600003','ERROR EXISTE INFORMACION PARA LA FECHA EN EX_DATO_TELEFONO')
            
      insert into cob_conta_super.. sb_dato_telefono(  
      dt_fecha                ,dt_ente         ,dt_direccion       ,  
      dt_secuencial           ,dt_valor           ,dt_tipo_telefono   ,  
      dt_prefijo              ,dt_fecha_registro   ,dt_fecha_mod       ,  
      dt_tipo_operador        ,dt_aplicativo      ,dt_origen          ,
      dt_fecha_proc)  
      select  
      dt_fecha                ,dt_ente         ,dt_direccion       ,  
      dt_secuencial           ,dt_valor           ,dt_tipo_telefono   ,  
      dt_prefijo        ,dt_fecha_registro   ,dt_fecha_mod       ,  
      dt_tipo_operador        ,dt_aplicativo      ,dt_origen          ,
      dt_fecha_proc
      from cob_externos..ex_dato_telefono  
      where dt_fecha      = @i_fecha_proceso   
      and   dt_aplicativo = @w_aplicativo
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TELEFONO')  
      if @w_reg > 0 insert into #control values ('dato_telefono')
   
            
      /*Datos Accionistas - Version Falabella*/  
      if exists (select 1 from cob_externos..ex_dato_accionistas where da_fecha = @i_fecha_proceso and da_aplicativo=@w_aplicativo) begin  
         if exists (select 1 from sb_dato_accionistas where da_fecha = @i_fecha_proceso and da_aplicativo=@w_aplicativo) begin  
            delete sb_dato_accionistas  
            where  da_fecha     = @i_fecha_proceso  
          and    da_aplicativo= @w_aplicativo
         end
      end
      else insert into #errores values('3600002','ERROR NO EXISTE INFORMACION PARA LA FECHA EN LA TABLA EX_DATO_ACCIONISTAS')
            
      insert into sb_dato_accionistas (   
      da_fecha,                              da_tipo_identificacion,                        da_numero_identificacion,                 da_ciiu,  
      da_tipo_accionista,                    da_naturaleza_juridica,                        da_tipo_capital,                          da_nacionalidad,  
      da_acciones_ordinarias,                da_acciones_privilegiadas,                     da_acciones_con_dividendo_preferencial,   da_personas_juridicas,  
      da_inversionistas_extranjeros,         da_entidad_publica,                            da_numero_acciones_individuales,          da_valor_nominal_accion,  
      da_valor_nominal_accion_valorizacion,  da_valor_patrimonial_accion_sin_valorizacion,  da_utilidad_por_accion,                   da_perdida_por_accion,  
      da_aplicativo,                         da_padre,                                      da_porcentaje,                            da_accion_readquirida_ordinaria,     
      da_accion_readquirida_privilegiada,    da_accion_readquirida_preferenciales,          da_origen,                                da_fecha_proc)  
      select  
      da_fecha,                              da_tipo_identificacion,                        da_numero_identificacion,                 da_ciiu,  
      da_tipo_accionista,                    da_naturaleza_juridica,                        da_tipo_capital,                          da_nacionalidad,  
      da_acciones_ordinarias,                da_acciones_privilegiadas,                     da_acciones_con_dividendo_preferencial,   da_personas_juridicas,  
      da_inversionistas_extranjeros,         da_entidad_publica,                            da_numero_acciones_individuales,          da_valor_nominal_accion,  
      da_valor_nominal_accion_valorizacion,  da_valor_patrimonial_accion_sin_valorizacion,  da_utilidad_por_accion,                   da_perdida_por_accion,  
      da_aplicativo,                         da_padre,                                      da_porcentaje,                            da_accion_readquirida_ordinaria,     
      da_accion_readquirida_privilegiada,    da_accion_readquirida_preferenciales,          da_origen,                                da_fecha_proc
      from  cob_externos..ex_dato_accionistas  
      where da_fecha      = @i_fecha_proceso  
      and   da_aplicativo = @w_aplicativo     
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_ACCIONISTAS')  
      if @w_reg > 0 insert into #control values ('dato_accionistas')
            
      delete cob_conta_super..sb_cliente_exonerado  
      where ce_fecha_corte = @i_fecha_proceso
      and   ce_aplicativo  = @w_aplicativo
     
      if @@error <> 0 insert into #errores values('3600002','ERROR AL BORRAR SB_CLIENTE_EXONERADO')
            
      insert into cob_conta_super..sb_cliente_exonerado (  
      ce_secuencial,  ce_fecha_corte, ce_entidad_reg,  
      ce_cliente,     ce_tipo_ced,    ce_ced_ruc,  
      ce_banco,       ce_razon,       ce_exonerado,  
      ce_tipo_carga,  ce_aplicativo,  ce_origen,
      ce_fecha_proc)  
      select   
      ce_secuencial,  ce_fecha_corte, ce_entidad_reg,  
      isnull((select en_ente from cobis..cl_ente where en_ced_ruc = ce_ced_ruc and en_tipo_ced = ce_tipo_ced),0), ce_tipo_ced, ce_ced_ruc,  
      ce_banco,       ce_razon,       ce_exonerado,  
      ce_tipo_carga,  ce_aplicativo,  ce_origen,
      ce_fecha_proc   
      from cob_externos..ex_cliente_exonerado  
      where ce_fecha_corte = @i_fecha_proceso 
      and   ce_aplicativo  = @w_aplicativo
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_CLIENTE_EXONERADO')  
      if @w_reg > 0 insert into #control values ('cliente_exonerado')
   
      --WLO      
      --delete sb_dato_bloqueo
      --where bo_fecha      = @i_fecha_proceso
      --and   bo_aplicativo = @w_aplicativo
     
      --if @@error <> 0 insert into #errores values('3600002','ERROR AL BORRAR SB_dato_bloqueo')  
            
            
      --insert into cob_conta_super..sb_dato_bloqueo (
      --bo_fecha,       bo_banco,            bo_aplicativo,
      --bo_secuencial,  bo_causa_bloqueo,    bo_fecha_bloqueo,
      --bo_fecha_modif, bo_fecha_desbloqueo, bo_estado,
      --bo_origen,      bo_fecha_proc,       bo_secuencial_ref)
      --select 
      --bo_fecha,       bo_banco,            bo_aplicativo,
      --bo_secuencial,  bo_causa_bloqueo,    bo_fecha_bloqueo,
      --getdate(),      bo_fecha_desbloqueo, bo_estado,
      --bo_origen,      bo_fecha_proc,       bo_secuencial_ref
      --from cob_externos..ex_dato_bloqueo
      --where bo_fecha      = @i_fecha_proceso
      --and   bo_aplicativo = @w_aplicativo
      
      --select 
      --@w_error = @@error,
      --@w_reg   = @@rowcount
      
      --if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_dato_bloqueo')  
      --if @w_reg > 0 insert into #control values ('dato_bloqueo')
   
      if exists (select 1 from cob_externos..ex_dato_educa_hijos where dt_fecha_modif = @i_fecha_proceso) begin        
         if exists (select 1 from sb_dato_educa_hijos where dt_fecha_modif = @i_fecha_proceso) begin  
            delete sb_dato_educa_hijos where dt_fecha_modif = @i_fecha_proceso  
         end   
      end
      else insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_EDUCA_HIJOS')
            
      insert into cob_conta_super..sb_dato_educa_hijos(  
      dt_secuencial                ,dt_cliente             ,dt_edad   ,  
      dt_niv_edu                   ,dt_hijos               ,dt_fecha_modif,
      dt_aplicativo)  
      select  
      dt_secuencial                ,dt_cliente             ,dt_edad   ,  
      dt_niv_edu                   ,dt_hijos               ,dt_fecha_modif,
      dt_aplicativo
      from cob_externos..ex_dato_educa_hijos  
      where dt_fecha_modif = @i_fecha_proceso     
      and   dt_aplicativo  = @w_aplicativo     
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_EDUCA_HIJOS')  
      if @w_reg > 0 insert into #control values ('dato_educa_hijos')
   
       
      if exists (select 1 from cob_externos..ex_dato_escolaridad_log where dt_fecha_actualizacion = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin        
         if exists (select 1 from sb_dato_escolaridad_log where dt_fecha_actualizacion = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin  
            delete sb_dato_escolaridad_log where dt_fecha_actualizacion = @i_fecha_proceso and dt_aplicativo = @w_aplicativo
   end   
 end
      else insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_ESCOLARIDAD')
            
      insert into cob_conta_super..sb_dato_escolaridad_log 
      select * from cob_externos..ex_dato_escolaridad_log  
      where dt_fecha_actualizacion = @i_fecha_proceso     
      and   dt_aplicativo          = @w_aplicativo     
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_ESCOLARIDAD_LOG')  
      if @w_reg > 0 insert into #control values ('dato_escolaridad_log')
   
      
      if exists (select 1 from cob_externos..ex_dato_sostenibilidad where dt_fecha_modif = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin        
         if exists (select 1 from sb_dato_sostenibilidad where dt_fecha_modif = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin  
            delete sb_dato_sostenibilidad where dt_fecha_modif = @i_fecha_proceso  and dt_aplicativo = @w_aplicativo
         end   
      end
      else insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_SOSTENIBILIDAD')
            
      insert into cob_conta_super..sb_dato_sostenibilidad
      select * from cob_externos..ex_dato_sostenibilidad  
      where dt_fecha_modif  = @i_fecha_proceso     
      and   dt_aplicativo   = @w_aplicativo      
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_SOSTENIBILIDAD')  
      if @w_reg > 0 insert into #control values ('dato_sostenibilidad')
       
   
      if exists (select 1 from cob_externos..ex_dato_sostenibilidad_log where dt_fecha_actualizacion = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin        
         if exists (select 1 from sb_dato_sostenibilidad_log where dt_fecha_actualizacion = @i_fecha_proceso and dt_aplicativo = @w_aplicativo) begin  
            delete sb_dato_sostenibilidad_log where dt_fecha_actualizacion = @i_fecha_proceso  and dt_aplicativo = @w_aplicativo
         end   
      end
      else insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_SOSTENIBILIDAD_LOG')
            
      insert into cob_conta_super..sb_dato_sostenibilidad_log
      select * from cob_externos..ex_dato_sostenibilidad_log  
      where dt_fecha_actualizacion = @i_fecha_proceso     
      and   dt_aplicativo          = @w_aplicativo
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_SOSTENIBILIDAD_LOG')  
      if @w_reg > 0 insert into #control values ('dato_sostenibilidad_log')
   
      
      if exists (select 1 from cob_externos..ex_forma_extractos where fe_fecha = @i_fecha_proceso and fe_aplicativo = @w_aplicativo) begin        
         if exists (select 1 from sb_forma_extractos where fe_fecha = @i_fecha_proceso and fe_aplicativo = @w_aplicativo) begin  
            delete sb_forma_extractos where fe_fecha = @i_fecha_proceso and fe_aplicativo = @w_aplicativo
         end   
      end
      else insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_FORMA_EXTRACTOS')
            
      insert into cob_conta_super..sb_forma_extractos 
      select * from cob_externos..ex_forma_extractos  
      where fe_fecha      = @i_fecha_proceso     
      and   fe_aplicativo = @w_aplicativo    
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_FORMA_EXTRACTOS')  
      if @w_reg > 0 insert into #control values ('forma_extractos')
   
      /*** ELIMINA DATOS EN sb_dato_central_cliente ***/
      delete sb_dato_central_cliente
      where dcc_fecha_proceso = @i_fecha_proceso 
      and   dcc_aplicativo    = @w_aplicativo
      
     /*** INSERTA DATOS EN sb_dato_central_cliente ***/       
      insert into cob_conta_super..sb_dato_central_cliente(
      dcc_fecha_proceso,          dcc_orden_consulta,   dcc_central,             
      dcc_fecha_cons,             dcc_tipo_id,          dcc_num_id,              
      dcc_estado_id,              dcc_respuesta,        dcc_aplicativo,
      dcc_ente,                   dcc_origen,           dcc_fecha_proc)          
      select   
      dcc_fecha_proceso,          dcc_orden_consulta,   dcc_central,             
      dcc_fecha_cons,             dcc_tipo_id,          dcc_num_id,              
      dcc_estado_id,              dcc_respuesta,        dcc_aplicativo,
      dcc_ente,                   dcc_origen,           dcc_fecha_proc          
      from cob_externos..ex_dato_central_cliente 
      where dcc_fecha_proceso = @i_fecha_proceso 
      and   dcc_aplicativo    = @w_aplicativo
       
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_CENTRAL_CLIENTE')  
      if @w_reg > 0 insert into #control values ('dato_central_cliente')
   
   
      /*** ELIMINA DATOS EN sb_dato_central_huella ***/   
      delete sb_dato_central_huella
      where dch_fecha_proceso = @i_fecha_proceso 
      and   dch_aplicativo    = @w_aplicativo

      /*** INSERTA DATOS EN sb_dato_central_huella ***/       
      insert into cob_conta_super..sb_dato_central_huella(
      dch_fecha_proceso,             dch_orden_consulta,           dch_fecha_cons,      
      dch_tipo_prod,                 dch_entidad,                  dch_oficina,             
      dch_ciudad,                    dch_aplicativo,               dch_origen,
      dch_fecha_proc)         
      select 
      dch_fecha_proceso,             dch_orden_consulta,           dch_fecha_cons,      
      dch_tipo_prod,                 dch_entidad,                  dch_oficina,             
      dch_ciudad,                    dch_aplicativo,               dch_origen,
      dch_fecha_proc         
      from cob_externos..ex_dato_central_huella 
      where dch_fecha_proceso = @i_fecha_proceso 
      and   dch_aplicativo    = @w_aplicativo
       
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_CENTRAL_HUELLA')  
      if @w_reg > 0 insert into #control values ('dato_central_huella')
   
   
      /*** ELIMINA DATOS EN sb_dato_central_score ***/
      delete sb_dato_central_score
      where dcs_fecha_proceso = @i_fecha_proceso 
      and   dcs_aplicativo    = @w_aplicativo
     
     /*** INSERTA DATOS EN sb_dato_central_score ***/       
      insert into cob_conta_super..sb_dato_central_score(
      dcs_fecha_proceso,             dcs_orden_consulta,             dcs_tipo,                
      dcs_puntaje,                   dcs_aplicativo)              
      select                                      
      dcs_fecha_proceso,             dcs_orden_consulta,             dcs_tipo,                
      dcs_puntaje,                   dcs_aplicativo              
      from cob_externos..ex_dato_central_score    
      where dcs_fecha_proceso = @i_fecha_proceso  
      and   dcs_aplicativo    = @w_aplicativo
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount
   
      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_CENTRAL_SCORE')  
      if @w_reg > 0 insert into #control values ('dato_central_score')
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      -- ELIMINANDO DATOS EN SB_DATO_CLIENTE_GRUPO 
      if exists (select 1 from cob_externos..ex_dato_cliente_grupo where cg_fecha = @i_fecha_proceso and cg_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_cliente_grupo where cg_fecha = @i_fecha_proceso and cg_aplicativo = @w_aplicativo) begin  
        delete sb_dato_cliente_grupo  
            where cg_fecha      = @i_fecha_proceso  
            and   cg_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_CLIENTE_GRUPO')          
             
            
      -- INSERTANDO DATOS EN SB_DATO_CLIENTE_GRUPO 
      insert into cob_conta_super..sb_dato_cliente_grupo(  
      cg_empresa,          cg_aplicativo,      cg_fecha,        cg_grupo_tipo,      cg_grupo,
      cg_grupo_nombre,     cg_grupo_tdoc,      cg_grupo_doc,    cg_subgrupo,        cg_subgrupo_nombre,
      cg_subgrupo_tdoc,    cg_subgrupo_doc,    cg_cliente,      cg_tipo_relacion,   cg_ciclo,
      cg_rol,              cg_fecha_ingreso,   cg_fecha_salida)
      select   
      cg_empresa,          cg_aplicativo,      cg_fecha,        cg_grupo_tipo,      cg_grupo,
      cg_grupo_nombre,     cg_grupo_tdoc,      cg_grupo_doc,    cg_subgrupo,        cg_subgrupo_nombre,
      cg_subgrupo_tdoc,    cg_subgrupo_doc,    cg_cliente,      cg_tipo_relacion,   cg_ciclo,
      cg_rol,              cg_fecha_ingreso,   cg_fecha_salida 
      from cob_externos..ex_dato_cliente_grupo  
      where cg_fecha      = @i_fecha_proceso  
      and   cg_aplicativo = @w_aplicativo   
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_CLIENTE_GRUPO')  
      if @w_reg > 0 insert into #control values ( 'dato_cliente_grupo'  )
      */
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
      -- ELIMINANDO DATOS EN SB_DATO_OFICINA
      if exists (select 1 from cob_externos..ex_dato_oficina where do_fecha = @i_fecha_proceso and do_aplicativo = @w_aplicativo) begin  
         if exists (select 1 from sb_dato_oficina where do_fecha = @i_fecha_proceso and do_aplicativo = @w_aplicativo) begin  
            delete sb_dato_oficina  
            where do_fecha      = @i_fecha_proceso  
            and   do_aplicativo = @w_aplicativo
         end
      end  
      else insert into #errores values('3600042','ERROR NO HAY DATOS PARA LA FECHA PROCESO EX_DATO_OFICINA')          
             
            
      -- INSERTANDO DATOS EN SB_DATO_OFICINA  
      insert into cob_conta_super..sb_dato_oficina(
      do_fecha,             do_empresa,             do_aplicativo,    do_oficina,          do_tipo_oficina,
      do_nombre,            do_region_economica,    do_pais,          do_corregimiento,    do_direccion,
      do_telefono1,         do_telefono2,           do_fax,           do_resp_nombre,      do_resp_cargo,
      do_estado_oficina,    do_aba,                 do_swift,         do_web)
      select
      do_fecha,             do_empresa,             do_aplicativo,    do_oficina,          do_tipo_oficina,
      do_nombre,            do_region_economica,    do_pais,          do_corregimiento,    do_direccion,
      do_telefono1,         do_telefono2,           do_fax,           do_resp_nombre,      do_resp_cargo,
      do_estado_oficina,    do_aba,                 do_swift,         do_web   
      from cob_externos..ex_dato_oficina  
      where do_fecha      = @i_fecha_proceso  
      and   do_aplicativo = @w_aplicativo   
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_OFICINA')  
      if @w_reg > 0 insert into #control values ( 'dato_oficina'  )
      */
      
      /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso  
      -- Elimina en sb_dato_buro_credito PERU
      if exists (select 1 from cob_externos..ex_dato_buro_credito tarx, cob_conta_super..sb_dato_buro_credito tars where tarx.bc_fecha = @i_fecha_proceso and tars.bc_fecha = tarx.bc_fecha and tars.bc_aplicativo = tarx.bc_aplicativo) 
      begin   
         delete cob_conta_super..sb_dato_buro_credito
         where  bc_aplicativo = @w_aplicativo
         and    bc_fecha      = @i_fecha_proceso
      end
      
      insert into sb_dato_buro_credito(
         bc_fecha, bc_empresa, bc_aplicativo,
         bc_ente,  bc_xml                    )
      select
         bc_fecha, bc_empresa, bc_aplicativo,
         bc_ente,  bc_xml
      from cob_externos..ex_dato_buro_credito
     */
    
   end -- operacion 'CL'   

   -- Tarifas Servc. Financieros
   If @i_toperacion in ('TF','TO') begin

      /*** ELIMINA DATOS EN SB_PARAM_TARIFAS - SB_DATOS_TARIFAS  ***/
     select @i_fecha_proceso = fp_fecha
      from   cobis..ba_fecha_proceso
      if exists (select 1 from cob_externos..ex_param_tarifas tarx, cob_conta_super..sb_param_tarifas tars where tarx.pt_fecha = @i_fecha_proceso and tars.pt_fecha = tarx.pt_fecha and tars.pt_aplicativo = tarx.pt_aplicativo) 
      begin
         delete cob_conta_super..sb_param_tarifas
         where  pt_aplicativo = @w_aplicativo
         and    pt_fecha      = @i_fecha_proceso
      end

      insert Into sb_param_tarifas(
      pt_fecha,   pt_aplicativo,  pt_nemonico,       pt_concepto,  pt_campo1,  pt_campo2,
      pt_campo3,  pt_campo4,      pt_campo5,         pt_campo6,    pt_campo7,  pt_campo8,
      pt_campo9,  pt_campo10,     pt_forma_calculo,  pt_estado)    
      select
      pt_fecha,   pt_aplicativo,  pt_nemonico,       pt_concepto,  pt_campo1,  pt_campo2,
      pt_campo3,  pt_campo4,      pt_campo5,         pt_campo6,    pt_campo7,  pt_campo8,
      pt_campo9,  pt_campo10,     pt_forma_calculo,  pt_estado
      from  cob_externos..ex_param_tarifas
      where pt_fecha =  @i_fecha_proceso
      
      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_PARAM_TARIFAS')  
      if @w_reg > 0 insert into #control values ('param_tarifas')

      
      -- Elimina en sb_datos_tarifas 
      if exists (select 1 from cob_externos..ex_datos_tarifas tarx, cob_conta_super..sb_datos_tarifas tars where tarx.dt_fecha = @i_fecha_proceso and tars.dt_fecha = tarx.dt_fecha and tars.dt_aplicativo = tarx.dt_aplicativo) 
      begin   
         delete cob_conta_super..sb_datos_tarifas
         where  dt_aplicativo = @w_aplicativo
         and    dt_fecha      = @i_fecha_proceso
      end
      
      insert into sb_datos_tarifas(
      dt_fecha,    dt_aplicativo,    dt_nemonico,  dt_campo1,  dt_campo2,  dt_campo3,
      dt_campo4,   dt_campo5,        dt_campo6,    dt_campo7,  dt_campo8,  dt_campo9,
      dt_campo10,  dt_base_calculo,  dt_valor,     dt_estado,  dt_origen,  dt_fecha_proc)
      select
      dt_fecha,    dt_aplicativo,    dt_nemonico,  dt_campo1,  dt_campo2,  dt_campo3,
      dt_campo4,   dt_campo5,        dt_campo6,    dt_campo7,  dt_campo8,  dt_campo9,
      dt_campo10,  dt_base_calculo,  dt_valor,     dt_estado,  dt_origen,  dt_fecha_proc    
      from  cob_externos..ex_datos_tarifas
      where dt_fecha      = @i_fecha_proceso
      and   dt_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATOS_TARIFAS')  
      if @w_reg > 0 insert into #control values ('datos_tarifas')

   end
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso
   If @i_toperacion in ('TO','AP') BEGIN
         -- BORRADO DATO_TARIFA
      if exists (select 1 from cob_externos..ex_dato_tarifa tarx, cob_conta_super..sb_dato_tarifa tars where tarx.dt_fecha = @i_fecha_proceso and tars.dt_fecha = tarx.dt_fecha and tars.dt_aplicativo = tarx.dt_aplicativo) 
      begin   
         delete cob_conta_super..sb_dato_tarifa
         where  dt_aplicativo = @w_aplicativo
         and    dt_fecha      = @i_fecha_proceso
      end
      -- INSERCION EN SB_DATO_TARIFA
      insert into sb_dato_tarifa(
      dt_fecha,    dt_empresa,      dt_aplicativo,    dt_tipo_operacion,
      dt_rubro, dt_tasa,         dt_valor_fijo)
      select
      dt_fecha,    dt_empresa,      dt_aplicativo,    dt_tipo_operacion,
      dt_rubro,    dt_tasa,         dt_valor_fijo
      from  cob_externos..ex_dato_tarifa
      where dt_fecha      = @i_fecha_proceso
      and   dt_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TARIFA')  
      if @w_reg > 0 insert into #control values ('dato_tarifa')
      --BORRADO SB_DATO_PRODUCTO
      if exists (select 1 from cob_externos..ex_dato_producto tarx, cob_conta_super..sb_dato_producto tars where tarx.dp_fecha = @i_fecha_proceso and tars.dp_fecha = tarx.dp_fecha and tars.dp_aplicativo = tarx.dp_aplicativo) 
      begin   
         delete cob_conta_super..sb_dato_producto
         where  dp_aplicativo = @w_aplicativo
         and    dp_fecha      = @i_fecha_proceso
      end
      
      insert into sb_dato_producto(
      dp_fecha,    dp_empresa,      dp_aplicativo,    dp_producto,
      dp_nombre,   dp_naturaleza,   dp_estado)
      select
      dp_fecha,    dp_empresa,      dp_aplicativo,    dp_producto,
      dp_nombre,   dp_naturaleza,   dp_estado
      from  cob_externos..ex_dato_producto
      where dp_fecha      = @i_fecha_proceso
      and   dp_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_PRODUCTO')  
      if @w_reg > 0 insert into #control values ('dato_producto')

   end
   */
   
   /* -- KDR 11/May/2019 Deshabilitación temporal hasta su uso    
   If @i_toperacion in ('TO','WF') BEGIN
         -- BORRADO DATO_TRAMITE
      if exists (select 1 from cob_externos..ex_dato_tramite tarx, cob_conta_super..sb_dato_tarifa tars where tarx.dt_fecha = @i_fecha_proceso and tars.dt_fecha = tarx.dt_fecha and tars.dt_aplicativo = tarx.dt_aplicativo) 
      begin   
         delete cob_conta_super..sb_dato_tarifa
         where  dt_aplicativo = @w_aplicativo
         and    dt_fecha      = @i_fecha_proceso
      end
      -- INSERCION EN SB_DATO_TRAMITE
      insert into sb_dato_tramite(
      dt_fecha,      dt_empresa,       dt_aplicativo,    dt_insta_proce,   dt_banco,
      dt_solicitud,  dt_nombre,        dt_cliente,       dt_canal,         dt_funcionario,
      dt_producto,   dt_oficina,       dt_monto,         dt_tasa,          dt_actividad,
      dt_evento,     dt_descripcion,   dt_fechaevento,   dt_resultado,     dt_tipo_rechazo,
      dt_comentario)
      select
      dt_fecha,      dt_empresa,       dt_aplicativo,    dt_insta_proce,   dt_banco,
      dt_solicitud,  dt_nombre,        dt_cliente,       dt_canal,         dt_funcionario,
      dt_producto,   dt_oficina,       dt_monto,         dt_tasa,          dt_actividad,
      dt_evento,     dt_descripcion,   dt_fechaevento,   dt_resultado,     dt_tipo_rechazo,
      dt_comentario
      from  cob_externos..ex_dato_tramite
      where dt_fecha      = @i_fecha_proceso
      and   dt_aplicativo = @w_aplicativo

      select 
      @w_error = @@error,
      @w_reg   = @@rowcount

      if @w_error <> 0 insert into #errores values('3600001','ERROR INSERTANDO DATOS EN SB_DATO_TRAMITE')  
      if @w_reg > 0 insert into #control values ('dato_tramite')
   END
   */
    
end --while 
--WLO
----INSERTA ERRORES ENCONTRADOS
--insert into sb_errorlog
--select @i_fecha_proceso,@w_fecha_ejecucion,@w_sp_name,error, mensaje
--from #errores /* --GFP 03/09/2021 Deshabilitación temporal hasta su uso
--, sb_dato_operacion_consolidador 
--
--exec  cob_conta_super..sp_dato_operacion_consolidador
--@i_param1        = @i_param1,
--@i_param2        = @i_param2
--*/ --GFP FIN 03/09/2021 Deshabilitación temporal hasta su uso
return 0 


go