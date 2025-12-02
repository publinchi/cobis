/************************************************************************/
/*  Archivo:                consulta_linea_int.sp                       */
/*  Stored procedure:       sp_consulta_linea_int                       */
/*  Base de Datos:          cob_interface                               */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Mieles                                 */
/*  Fecha de Documentacion: 04/10/2021                                  */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante.              */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_interface               */ 
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  04/10/2021       jmieles        Emision Inicial                     */
/* **********************************************************************/ 
 use cob_interface
go

if exists(select 1 from sysobjects where name ='sp_consulta_linea_int')
   drop procedure sp_consulta_linea_int
go

create proc sp_consulta_linea_int
(
 	   @s_ssn                     int              = null,
       @s_user                    login            = null,
       @s_sesn                    int              = null,
       @s_term                    descripcion      = null,         
       @s_date                    datetime         = null,
       @s_srv                     varchar(30)      = null,
       @s_lsrv                    varchar(30)      = null,
       @s_rol                     smallint         = null,
       @s_ofi                     smallint         = null,
       @s_org_err                 char(1)          = null,
       @s_error                   int              = null,
       @s_sev                     tinyint          = null,
       @s_msg                     descripcion      = null,
       @s_org                     char(1)          = null,
       @t_rty                     char(1)          = null,
       @t_trn                     int              = null,
       @t_debug                   char(1)          = 'N',
       @t_file                    varchar(14)      = null,
       @t_from                    varchar(30)      = null,
       @t_show_version            bit              = 0,          
       @s_culture                 varchar(10)      = 'NEUTRAL',
       @i_operacion               char(1)          = null,
       @i_tramite	              int              = null
)
as
declare
        @w_tramite                   int,
       @w_tipo                      char(1) ,
       @w_desc_tipo                 descripcion,
       @w_oficina_tr                smallint,
       @w_desc_oficina              descripcion,
       @w_usuario_tr                login ,
       @w_nom_usuario_tr            varchar(30),
       @w_fecha_crea                datetime ,
       @w_oficial                   smallint ,
       @w_sector                    catalogo,
       @w_ciudad                    int ,
       @w_desc_ciudad               descripcion,
       @w_estado                    char(1) ,
       @w_secuencia                 smallint ,
       @w_numero_op                 int,
       @w_numero_op_banco           cuenta,
       @w_desc_ruta                 descripcion,
       @w_proposito                 catalogo ,
       @w_des_proposito             descripcion,
       @w_razon                     catalogo ,
       @w_des_razon                 descripcion,
       @w_txt_razon                 varchar(255),
       @w_efecto                    catalogo,
       @w_des_efecto                descripcion,
       @w_cliente                   int ,
       @w_grupo                     int ,
       @w_fecha_inicio              datetime ,
       @w_num_dias                  smallint ,
       @w_per_revision              catalogo ,
       @w_condicion_especial        varchar(255),
       @w_linea_credito             int,          
       @w_toperacion                catalogo ,
       @w_producto                  catalogo ,
       @w_monto                     money ,
       @w_moneda                    tinyint,
       @w_periodo                   catalogo,
       @w_num_periodos              smallint,
       @w_destino                   catalogo,
       @w_ciudad_destino            int,
       @w_renovacion                smallint,
       @w_fecha_concesion           datetime,

       @w_fecha_reajuste            datetime,
       @w_monto_desembolso          money,
       @w_monto_desembolso_tr       money,
       @w_periodo_reajuste          tinyint,
       @w_reajuste_especial         char(1),
       @w_forma_pago                catalogo,
       @w_cuenta                    cuenta,
       @w_cuota_completa            char(1),
       @w_tipo_cobro                char(1),
       @w_tipo_reduccion            char(1),
       @w_aceptar_anticipos         char(1),
       @w_precancelacion            char(1),
       @w_tipo_aplicacion           char(1),
       @w_renovable                 char(1),
       @w_reajustable               char(1),
       @w_val_tasaref               float,

       @w_des_oficial               descripcion,
       @w_des_sector                descripcion,
       @w_des_nivel_ap              descripcion,
       @w_nom_ciudad                descripcion,      
       @w_nom_cliente               varchar(255),
       @w_ciruc_cliente             varchar(35),      
       @w_nom_grupo                 descripcion,
       @w_des_per_revision          descripcion,
       @w_des_segmento              descripcion,
       @w_des_toperacion            descripcion,
       @w_des_moneda                descripcion,
       @w_des_periodo               descripcion,
       @w_des_destino               descripcion,
       @w_des_fpago                 descripcion,
       @w_li_num_banco              cuenta,
       @w_des_comite                descripcion,
       @w_paso                      tinyint,
       @w_numero_operacion          int,
       @w_cont_dividendos           int,

       @w_banco_rest                cuenta,          
       @w_operacion_rest            int,            
       @w_toperacion_rest           catalogo,       
       @w_fecha_vto_rest            datetime,        
       @w_monto_rest                money,           
       @w_saldo_rest                money,           
       @w_moneda_rest               tinyint,        
       @w_renovacion_rest           smallint,        
       @w_renovable_rest            char(1),         
       @w_fecha_ini_rest            datetime,        
       @w_producto_rest             catalogo,       
       @w_csector_contable          catalogo,
       @w_cdes_sector_contable      descripcion,
       @w_origen_fondo              catalogo,
       @w_des_origen_fondo          descripcion,
       @w_fondos_propios            char(1),
       @w_sector_contable           catalogo,
       @w_des_sector_contable       descripcion,
       @w_plazo                     catalogo,
       @w_des_plazo                 descripcion,
       @w_num_banco_cartera         cuenta,
       @w_tipo_top                  char(1),
       @w_causa                     char(1),         
       @w_migrada                   cuenta,          
       @w_lin_op                    cuenta,
       @w_tipo_prioridad            char(1),
       @w_descripcion               varchar(40),
       @w_proposito_op              catalogo,        
       @w_des_proposito_op          descripcion,     
       @w_linea_cancelar            int,
       @w_linea_cancelar_str        varchar(24),
       @w_fecha_irenova             datetime,
       @w_subsidio                  char(1),
       @w_porcentaje_subsidio       float,
       @w_tasa_asociada             char(1),
       @w_tpreferencial             char(1),
       @w_porcentaje_preferencial   float,
       @w_monto_preferencial        money,
       @w_abono_ini                 money,
       @w_opcion_compra             money,
       @w_beneficiario              descripcion,
       @w_financia                  char(1),
       @w_tipo_t                    descripcion,
       @w_tipo_opera_t              descripcion,
       @w_asunto                    varchar(255),
       @w_motivo                    varchar(255),
       @w_tipo_amortizacion         catalogo,
       @w_dias_prorroga             smallint,
       @w_numero_prorrogas          smallint,
       @w_des_tope_asunto           varchar(65),
       @w_des_clase_asunto          varchar(65),
       @w_fecha_fin_new             datetime,
       @w_dias_a_prorrogar          int,
       @w_efecto_pago               char(1),
       /* SYR AGO-2007 */
       @w_min_paso                  tinyint,
       @w_pa_etapa                  tinyint,
       @w_count                     int,
       @w_estacion                  smallint,
       @w_etapa_inicial             tinyint,
       @w_anticipo                  int,                
       @w_monto_solicitado          money,
       @w_cuota                     money,
       @w_frec_pago                 catalogo,
     @w_moneda_solicitada         tinyint,
       @w_provincia                 int,
       @w_pplazo                    smallint,
       @w_tplazo                    catalogo,
       @w_sindicado                 char(1),            
       @w_tipo_cartera              catalogo,
       @w_destino_descripcion       descripcion,
       @w_mes_cic                   int,
       @w_anio_cic                  int,
       @w_patrimonio                money,
       @w_ventas                    money,
       @w_num_personal_ocupado      int,
       @w_tipo_credito              catalogo ,
       @w_indice_tamano_actividad   float,
       @w_objeto                    catalogo ,
       @w_actividad                 catalogo ,
       @w_descripcion_oficial       descripcion ,
       @w_origen_fondos             catalogo,
       @w_des_frec_pago             descripcion,
       @w_ventas_anuales            money,             
       @w_activos_productivos       money,             
       @w_simbolo_moneda            varchar(10),        
       @w_sector_cli                catalogo,
       @w_li_dias                   smallint,         
       @w_expromision               catalogo,
       @w_level_indebtedness        char(1),
       @w_convenio                  char(1),
       @w_codigo_cliente_empresa    varchar(10),
       @w_lin_comext                cuenta,
       @w_reprograming_Observ       varchar(255),
       @w_motivo_uno                varchar(255),       
       @w_motivo_dos                varchar(255),       
       @w_motivo_rechazo            catalogo,
       @w_numero_testimonio         varchar(50),
       @w_producto_fie              catalogo,
       @w_num_viviendas             tinyint,
       @w_tipo_calificacion         catalogo,
       @w_calificacion              catalogo,
       @w_es_garantia_destino       char(1),
       @w_es_deudor_propietario     char(1),
       @w_tamanio_empresa           varchar(10),
       @w_des_oficial_con           varchar(255),
       @w_codigo_usr_con            int,
       @w_fun_linea                 int,
       @w_des_fun_linea             varchar(255),
       @w_oficial_linea             int,
       @w_tasa                      float,
       @w_sub_actividad             catalogo,
       @w_sub_actividad_desc        varchar(255),
       @w_departamento              catalogo,
       @w_parroquia                 catalogo,
       @w_canton                    catalogo,
       @w_barrio                    catalogo,
       @w_fecha_ven                 datetime,
       @w_rotativa                  char(1),
       @w_linea                     int,
       @w_fecha_ini                 datetime,
       @w_dias                      int,
       @w_dias_anio                 int,               
       @w_dia_fijo                  smallint,          
       @w_enterado                  catalogo,          
       @w_otros_ent                 varchar(64),      
       @w_seguro_basico             char(1),            
       @w_seguro_voluntario         catalogo,          
       @w_tr_porc_garantia          float,              
       @w_sp_name1                varchar(100),
	   @w_error                   int

if (@i_operacion <> 'S')
 begin
    select
    @w_error = 2110173
    goto ERROR
 end
 
if not exists(select 1 
                from cob_credito..cr_tramite 
               where tr_tramite = @i_tramite 
                 and tr_tipo    = 'L')
 begin
    select
    @w_error = 2110192
    goto ERROR
 end

if @i_operacion = 'S'
begin


select
     @w_tramite             = tr_tramite,
     @w_tipo                = tr_tipo,
     @w_oficina_tr          = tr_oficina,
     @w_usuario_tr          = tr_usuario,
     @w_nom_usuario_tr      = a.fu_nombre,
     @w_fecha_crea          = tr_fecha_crea,
     @w_oficial             = tr_oficial,
     @w_sector              = tr_sector,
     @w_ciudad              = tr_ciudad,
     @w_estado              = tr_estado,
     @w_numero_op           = tr_numero_op,
     @w_numero_op_banco     = tr_numero_op_banco,
     @w_proposito           = tr_proposito,         
     @w_razon               = tr_razon,
     @w_txt_razon           = rtrim(tr_txt_razon),
     @w_efecto              = tr_efecto,
     @w_cliente             = tr_cliente,              
     @w_grupo               = tr_grupo,
     @w_fecha_inicio        = tr_fecha_inicio,
     @w_num_dias            = datediff(month,tr_fecha_inicio,(dateadd( day, tr_num_dias, tr_fecha_inicio))),--tr_num_dias,
     @w_per_revision        = tr_per_revision,
     @w_condicion_especial  = tr_condicion_especial,
     @w_linea_credito       = tr_linea_credito,         
     @w_toperacion          = tr_toperacion,
     @w_producto            = tr_producto,
     @w_monto               = tr_monto,
     @w_moneda              = tr_moneda,
     @w_periodo             = tr_periodo,
     @w_num_periodos        = tr_num_periodos,
     @w_destino             = tr_destino,
     @w_ciudad_destino      = tr_ciudad_destino,
     @w_renovacion          = tr_renovacion,
     @w_fecha_concesion     = tr_fecha_concesion,
     @w_causa               = tr_causa,
     @w_proposito_op        = tr_proposito_op,          
     @w_linea_cancelar      = tr_linea_cancelar,
     @w_fecha_irenova       = tr_fecha_irenova,
     @w_tasa_asociada       = tr_tasa_asociada,
     @w_cuota               = tr_cuota,
     @w_frec_pago           = tr_frec_pago,
     @w_moneda_solicitada   = tr_moneda_solicitada,
     @w_provincia           = tr_provincia,
     @w_monto_solicitado    = tr_monto_solicitado,
     @w_monto_desembolso_tr = tr_monto_desembolso,
     @w_pplazo              = tr_plazo,
     @w_tplazo              = tr_tplazo,
     @w_origen_fondos       = tr_origen_fondos,
     @w_sector_cli          = tr_sector_cli,
     @w_expromision         = tr_expromision,
     @w_lin_comext          = tr_lin_comext,
     @w_enterado            = tr_enterado,              
     @w_otros_ent           = tr_otros,                
     @w_tr_porc_garantia    = tr_porc_garantia,        
     @w_sub_actividad       = tr_cod_actividad          
from cob_credito..cr_tramite
     left outer join cobis..cl_funcionario a on tr_usuario = a.fu_login
     where tr_tramite = @i_tramite


if @@rowcount = 0
begin
   /*Registro no existe */
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = 'sp_consulta_linea_int',
   @i_num   = 2101005
   return 2101005
end


if @w_tipo != 'C'
begin
exec cob_credito..sp_tr_datos_adicionales
    @t_trn= 21118,
    @i_operacion       = 'S',
     @i_tramite         =@i_tramite
end


select @w_secuencia = rt_secuencia,
       @w_paso =  rt_paso
from   cob_credito..cr_ruta_tramite
where  rt_tramite = @i_tramite
and    rt_salida is NULL
if @@rowcount = 0
       select @w_secuencia = max(rt_secuencia)
       from   cob_credito..cr_ruta_tramite
       where  rt_tramite = @i_tramite


select @w_desc_tipo = tt_descripcion
from   cob_credito..cr_tipo_tramite
where  tt_tipo = @w_tipo


select @w_desc_oficina = of_nombre
from   cobis..cl_oficina
where  of_oficina = @w_oficina_tr

select @w_desc_ciudad = ci_descripcion
from   cobis..cl_ciudad
where  ci_ciudad = @w_ciudad

if @w_linea_credito is not null
begin

   select @w_li_num_banco = li_num_banco
   from   cob_credito..cr_linea
   where  li_numero = @w_linea_credito
end


    select @w_des_oficial = fu_nombre
    from cobis..cc_oficial, cobis..cl_funcionario
    where oc_oficial = @w_oficial
    and oc_funcionario = fu_funcionario


    select @w_des_sector = a.valor
    from cobis..cl_catalogo a, cobis..cl_tabla b
      
    where  b.tabla = 'cl_sector_neg'
    and a.codigo = @w_sector
    and a.tabla = b.codigo

    if @w_destino is not null
        select @w_des_destino = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_destino
        and a.tabla = b.codigo
        and b.tabla = 'cr_destino'


    if @w_tipo in ('O', 'R', 'E', 'F')
       select @w_cliente = de_cliente
       from   cr_deudores
       where  de_tramite = @i_tramite
       and    de_rol = 'D'
    if @w_cliente is not null
        select @w_nom_cliente = rtrim(substring(en_nomlar,1,datalength(en_nomlar))),    
               @w_ciruc_cliente = substring(en_ced_ruc,1,datalength(en_ced_ruc))        
        from cobis..cl_ente
        where en_ente = @w_cliente

    if @w_grupo is not null
        select @w_nom_grupo = gr_nombre
        from cobis..cl_grupo
        where gr_grupo = @w_grupo

    if @w_per_revision is not null
        select @w_des_per_revision = pe_descripcion
        from cr_periodo
        where pe_periodo = @w_per_revision

    if @w_toperacion is not null
        begin
           if @w_tipo = 'L' or @w_tipo = 'P'
                select @w_des_toperacion = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_toperacion
        and a.tabla = b.codigo
        and b.tabla = 'cr_clase_linea'
           else
        select @w_des_toperacion = to_descripcion
        from cr_toperacion
        where to_toperacion =@w_toperacion
        and to_producto = @w_producto
        end

    if @w_moneda is not null
        select @w_des_moneda = mo_descripcion
        from cobis..cl_moneda
        where mo_moneda = @w_moneda

    if @w_ciudad_destino is not null
        select @w_nom_ciudad = ci_descripcion
        from cobis..cl_ciudad
        where ci_ciudad = @w_ciudad_destino

    if @w_razon is not null
        select @w_des_razon = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_razon
        and a.tabla = b.codigo
    and b.tabla = 'cr_razon'

    if @w_proposito is not null
        select @w_des_proposito = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_proposito
        and a.tabla = b.codigo
        and b.tabla = 'cr_proposito'

    if @w_efecto is not null
        select @w_des_efecto = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_efecto
    and a.tabla = b.codigo
        and b.tabla = 'cr_efecto'


    select @w_des_frec_pago = td_descripcion
    from   cob_cartera..ca_tdividendo
    where  td_tdividendo = @w_frec_pago


    if @w_moneda is not null
        select @w_simbolo_moneda = mo_simbolo
        from cobis..cl_moneda
        where mo_moneda = @w_moneda
        
    if @w_sub_actividad is not null
        select @w_sub_actividad_desc = se_descripcion
        from   cobis..cl_subactividad_ec
        where  se_codigo = @w_sub_actividad
        

if @w_producto = 'CCA'
begin

   select @w_numero_operacion        = op_operacion,
          @w_fecha_reajuste          = op_fecha_reajuste,
          @w_monto_desembolso        = op_monto,
          @w_periodo_reajuste        = op_periodo_reajuste,
          @w_reajuste_especial       = op_reajuste_especial,
          @w_forma_pago              = op_forma_pago,
          @w_cuenta                  = op_cuenta,
          @w_cuota_completa          = op_cuota_completa,
          @w_tipo_cobro              = op_tipo_cobro,
          @w_tipo_reduccion          = op_tipo_reduccion,
          @w_aceptar_anticipos       = op_aceptar_anticipos,
          @w_precancelacion          = op_precancelacion,
          @w_tipo_aplicacion         = op_tipo_aplicacion,
          @w_renovable               = op_renovacion,
          @w_reajustable             = op_reajustable,
          @w_fecha_inicio            = op_fecha_ini,
          @w_periodo                 = op_tplazo,
          @w_des_periodo             = td_descripcion,
          @w_num_periodos            = op_plazo,
          @w_fondos_propios          = op_fondos_propios,
          @w_num_banco_cartera       = op_banco,
          @w_tipo_top                = op_tipo,
          @w_migrada                 = op_migrada,               
          @w_tipo_amortizacion       = op_tipo_amortizacion,
          @w_fecha_fin_new           = op_fecha_fin,
          @w_dias_anio               = op_dias_anio,
          @w_banco_rest              = op_anterior,
          @w_dia_fijo                = op_dia_fijo,              
          @w_cuota                   = isnull(@w_cuota,op_cuota) 
   from   cob_cartera..ca_operacion
          left outer join cob_cartera..ca_tdividendo on td_tdividendo = op_tplazo
   where  op_tramite = @i_tramite

   if @w_tipo_top = 'R'
   select @w_li_num_banco = @w_lin_op

   if @w_tipo_amortizacion = 'MANUAL'
      select @w_des_periodo = 'DIAS'



	if (@w_numero_op_banco is null or rtrim(@w_numero_op_banco) ='')
		select @w_numero_op_banco = @w_num_banco_cartera



   select @w_des_sector_contable = a.valor
   from cobis..cl_catalogo a, cobis..cl_tabla b
   where a.codigo = @w_sector_contable
     and a.tabla = b.codigo
     and b.tabla = 'cu_sector'

select  @w_des_origen_fondo = null  



   if @w_tipo_top = 'I'
        select @w_des_plazo = a.valor
                from cobis..cl_catalogo a, cobis..cl_tabla b
                where a.codigo = @w_plazo
                and a.tabla = b.codigo
                and b.tabla = 'ca_plazo_titulos'
   else
        select @w_des_plazo = a.valor
                from cobis..cl_catalogo a, cobis..cl_tabla b
                where a.codigo = @w_plazo
                and a.tabla = b.codigo
                and b.tabla = 'ca_plazo_contable'


   if @w_forma_pago is not null
   begin
          select @w_des_fpago = cp_descripcion
       from cob_cartera..ca_producto
       where cp_producto = @w_forma_pago
   end

   select @w_val_tasaref=  isnull(sum(ro_porcentaje) ,0)
   from   cob_cartera..ca_rubro_op
   where  ro_operacion  =  @w_numero_operacion
      and ro_tipo_rubro =  'I'
      and ro_fpago      in ('P','A','T') 

   select @w_cont_dividendos = count(*)
   from   cob_cartera..ca_dividendo
   where  di_operacion = @w_numero_operacion


   if @w_tipo = 'E'
   begin
    
      select  @w_operacion_rest     = op_operacion,
              @w_toperacion_rest    = op_toperacion,
              @w_fecha_vto_rest     = op_fecha_fin,
              @w_monto_rest         = op_monto,
              @w_moneda_rest        = op_moneda,
              @w_renovacion_rest    = op_num_renovacion,
              @w_renovable_rest     = op_renovacion,
              @w_fecha_ini_rest     = op_fecha_liq,
              @w_producto_rest      = 'CCA'
      from    cob_cartera..ca_operacion
      where   op_banco = @w_banco_rest
  
      select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0))-- - isnull(am_exponencial,0))--TCRM
      from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
      where  ro_operacion = @w_operacion_rest
         and ro_tipo_rubro in ('C')    
         and am_operacion = ro_operacion
         and am_concepto  = ro_concepto

     
      select @w_numero_prorrogas=count(*)
        from cob_cartera..ca_transaccion
  where tr_operacion = @w_numero_operacion
         and tr_tran      = 'RES'
         and tr_estado   != 'RV'

     
      select @w_dias_a_prorrogar = isnull(DATEDIFF(dd, @w_fecha_vto_rest, @w_fecha_fin_new),0)
   end
end


select @w_des_proposito_op = a.valor
  from cobis..cl_catalogo a, cobis..cl_tabla b
 where a.codigo = @w_proposito_op
   and a.tabla = b.codigo
   and b.tabla = 'cr_proposito_linea'

select @w_tipo_t =  tt_descripcion,
       @w_tipo_opera_t = (select valor from cobis..cl_catalogo   
                          where codigo = cob_credito..cr_tramite.tr_toperacion
                            and tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_toperacion'))
from cob_credito..cr_tramite, cob_credito..cr_tipo_tramite
where tt_tipo = tr_tipo
 and tr_tramite = @w_tramite

select @w_asunto =  'Aprobación de ' + rtrim(@w_tipo_t) + ', ' + rtrim(@w_tipo_opera_t)

if @w_tipo = 'P'
begin
   select @w_motivo = (select valor from cobis..cl_catalogo   
                         where codigo = cr_prorroga.pr_motivo
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_motivo_linea')),
          @w_des_clase_asunto  = (select valor from cobis..cl_catalogo  
                         where codigo = cob_credito..cr_tramite.tr_toperacion
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_clase_linea')),
          @w_des_tope_asunto         = (select valor from cobis..cl_catalogo
                         where codigo = cr_prorroga.pr_tipo
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_tipo_linea')),
          @w_numero_testimonio = pr_numero_testimonio,
          @w_moneda_solicitada =cob_credito..cr_tramite.tr_moneda_solicitada
   from cr_prorroga, cob_credito..cr_tramite
   where pr_tramite = @w_tramite
     and pr_tramite = tr_tramite
     and tr_tramite = @w_tramite

   select @w_asunto = 'Modificación de ' +  rtrim(@w_des_clase_asunto)  + ' ' + rtrim(@w_des_tope_asunto) + ' por ' + rtrim(@w_motivo)
end

if @w_tipo = 'L'
begin
   select @w_des_tope_asunto       = (select valor from cobis..cl_catalogo
                         where codigo = cob_credito..cr_linea.li_tipo
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_tipo_linea')),
          @w_des_clase_asunto = (select valor from cobis..cl_catalogo   -- actividad
                         where codigo = cob_credito..cr_tramite.tr_toperacion
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_clase_linea')),
          @w_li_dias = li_dias
   from cob_credito..cr_linea, cob_credito..cr_tramite
   where li_tramite = @w_tramite
     and tr_tramite = li_tramite
     and tr_tramite = @w_tramite

   select @w_asunto = 'Aprobación de ' + rtrim(@w_des_clase_asunto)  + ' ' + rtrim(@w_des_tope_asunto)
end

if @w_tipo = 'G'
begin
   select @w_asunto = 'Aprobación de ' + rtrim(@w_tipo_t) + ', ' + rtrim(@w_des_proposito) + ', ' +  rtrim(@w_des_razon)  + '.'
end

select  @w_des_oficial_con    = fu_nombre,
        @w_codigo_usr_con     = oc_oficial
from cobis..cc_oficial, cobis..cl_funcionario
where oc_funcionario = fu_funcionario
and   fu_login       = @s_user

select  @w_oficial_linea = tr_oficial
from cob_credito..cr_linea,cob_credito..cr_tramite
where li_tramite = tr_tramite
and   li_numero  = @w_linea_credito


if exists (select 1 from cob_credito..cr_linea where li_tramite = @w_tramite)
begin
   select @w_fecha_ven = li_fecha_vto,
          @w_rotativa  = li_rotativa,
          @w_linea     = li_numero,
          @w_fecha_ini = li_fecha_inicio,
          @w_dias      = li_dias
     from cob_credito..cr_linea
    where li_tramite = @i_tramite
end

if exists ( select dp_mnemonico FROM cobis..cl_depart_pais WHERE dp_departamento=@w_departamento)
    begin
        select @w_departamento = dp_mnemonico FROM cobis..cl_depart_pais WHERE dp_departamento=@w_departamento
    end


select
       @w_tramite,                                      
       --@w_desc_ruta,                                    
       @w_tipo,                                        
       --@w_desc_tipo,                                    
       @w_oficina_tr,                                   
       @w_desc_oficina,                                 
       @w_usuario_tr,                                   
       @w_nom_usuario_tr,                               
       @w_fecha_crea,                                   
       @w_oficial ,                                     
       @w_ciudad ,                                      
       @w_desc_ciudad ,                                 
       @w_estado ,                                      
       /*@w_secuencia ,                                   
       --@w_numero_op_banco ,                             
       @w_proposito ,                                   
       @w_des_proposito,                                
       @w_razon ,                                       
       @w_des_razon,                                    
       @w_txt_razon ,                                  
       @w_efecto,                                       
       @w_des_efecto,  */                                 
       @w_cliente ,                                    
       --@w_grupo ,                                       
       @w_fecha_inicio,                                 
       @w_num_dias ,                                    
       --@w_per_revision ,                                
       --@w_condicion_especial ,                          
       @w_toperacion,                                
       --@w_producto ,                                   
       --@w_li_num_banco,                                 
       @w_monto ,                                       
       @w_moneda,                                       
       --@w_periodo,                                      
       @w_num_periodos,      
      /* @w_destino,                                      
       @w_provincia,                                   
       @w_renovacion ,                                  
       @w_fecha_reajuste,     
       @w_monto_desembolso,                            
       @w_periodo_reajuste,                             
       @w_reajuste_especial,                            
       @w_forma_pago,                                   
       @w_cuenta,                                       
       @w_cuota_completa,                               
       @w_tipo_cobro,                                   
       @w_tipo_reduccion,                               
       @w_aceptar_anticipos,                            
       @w_precancelacion,                               
       @w_tipo_aplicacion,                             
       @w_renovable,                                    
       @w_reajustable,                                  
       @w_val_tasaref,                                  
       @w_fecha_concesion,  */                            
       @w_sector,                                       
       @w_des_oficial,                                
       @w_des_sector,                                   
       /*@w_des_nivel_ap,                                 
       @w_nom_ciudad,  */                                 
       @w_nom_cliente,                                  
       @w_ciruc_cliente,                                
       /*@w_nom_grupo,                                    
       @w_des_per_revision,                             
       @w_des_segmento,                                 
       @w_des_toperacion, */                              
       @w_des_moneda,                                   
       --@w_des_periodo,                                  
       --@w_des_destino,                                  
       --@w_des_fpago,                                    
       --@w_paso,                                         
       --@w_cont_dividendos,                              
       --@w_banco_rest,                                   
       --@w_operacion_rest,                               
       --@w_toperacion_rest,                              
       --@w_fecha_vto_rest,                               
       --@w_monto_rest,                                   
       --@w_saldo_rest,                                   
       --@w_moneda_rest,                                  
       --@w_renovacion_rest,                              
       --@w_renovable_rest,                               --80
       --@w_fecha_ini_rest,
       --@w_producto_rest,
       --@w_origen_fondo,
       --@w_des_origen_fondo,
       --@w_fondos_propios,
       --@w_sector_contable,
       --@w_des_sector_contable,
       --@w_plazo + ' (' + @w_des_plazo ,
       --@w_proposito_op + ' (' + @w_des_proposito_op ,
       --@w_tipo_top,                                  
       --@w_causa,                                       
       --@w_migrada,                                     
       --@w_tipo_prioridad,                               
       --@w_descripcion,                                  
       --@w_efecto_pago,                                  
       --@w_monto_solicitado,                             
       --@w_cuota,                                        
       --@w_periodo,                                      
       @w_moneda_solicitada,                            
       --@w_provincia,                                    
       --@w_monto_desembolso_tr ,
       --@w_pplazo ,
       --@w_tplazo ,
       --@w_sindicado ,
      -- @w_tipo_cartera ,
       --isnull(@w_destino_descripcion,''),               
       --@w_mes_cic ,                                     
       --@w_anio_cic ,                                    
       --@w_patrimonio ,                                  
       --@w_ventas ,                            
       --@w_num_personal_ocupado ,                        
       --@w_tipo_credito ,
       --@w_indice_tamano_actividad ,
       --@w_objeto ,
       --@w_sub_actividad,                                
       --isnull(@w_descripcion_oficial,' '),
       @w_origen_fondos,
       --@w_des_frec_pago,                               
       --@w_ventas_anuales,                               
       --@w_activos_productivos,                         
       @w_simbolo_moneda,                              
       --@w_sector_cli,                                   
       @w_li_dias,                                     
       --@w_expromision,                                  
       --@w_numero_op,                                   
       --@w_level_indebtedness,                           
       --@w_convenio,                                     
       --@w_codigo_cliente_empresa,                       
       --@w_num_banco_cartera,                            
       --@w_lin_comext,                                  
       --@w_reprograming_Observ,                         
       --@w_motivo_uno,                                  
       --@w_motivo_dos,                                   
       --@w_motivo_rechazo,
       --@w_numero_testimonio,
       --@w_linea_credito,
       --@w_producto_fie,
       --@w_num_viviendas,
       --@w_tipo_calificacion,
       --@w_calificacion,                                 
       --@w_es_garantia_destino,                          
       --@w_es_deudor_propietario,                        
      -- @w_tamanio_empresa,                              
       @w_codigo_usr_con,                               
       --@w_ciudad_destino,                               
       --@w_oficial_linea,                                
       --'N',                                            
       --@w_dias_anio,                                    
       --@w_sub_actividad,                                
       --@w_sub_actividad_desc,                          
       --' ',                                             
       --' ',                                             
       --' ',                                             
       @w_fecha_ven,                                    
       @w_rotativa,                                     
       @w_linea,                                        
       @w_fecha_ini,                                    
       @w_dias                                     
       --@w_sector                                       
       --@w_dia_fijo,                                     
       --@w_enterado,                                    
       --@w_otros_ent,                                    
       --@w_seguro_basico,                               
       --@w_seguro_voluntario
select @w_linea_cancelar_str=li_num_banco
  from cob_credito..cr_linea
 where li_numero=@w_linea_cancelar


select @w_count = 0

select @w_estacion = es_estacion
from cob_credito..cr_estacion
where es_usuario = @w_usuario_tr



select  @w_linea_cancelar_str,
        convert(char(10),@w_fecha_irenova,0),
        @w_subsidio,
        @w_porcentaje_subsidio,
        @w_tasa_asociada,
        @w_abono_ini,
        @w_opcion_compra,
        @w_beneficiario,             
        @w_financia,
        @w_tpreferencial,            --10
        @w_porcentaje_preferencial,
        @w_monto_preferencial,
        @w_asunto,
        @w_tipo_amortizacion,
        @w_dias_prorroga,
        @w_numero_prorrogas,
        @w_dias_a_prorrogar,
        @w_etapa_inicial,            
        @w_anticipo                 
		
end
		
return 0

ERROR:
--Devolver mensaje de Error
exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file,
       @t_from  = @w_sp_name1,
       @i_num   = @w_error
return @w_error

go