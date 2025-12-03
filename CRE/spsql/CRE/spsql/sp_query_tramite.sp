/***********************************************************************/
/*      Archivo:                        query_tramite.sp               */
/*      Stored procedure:               sp_query_tramite               */
/*      Base de Datos:                  cob_credito                    */
/*      Producto:                       Credito                        */
/*      Disenado por:                   Isaac Parra                    */
/*      Fecha de Documentacion:         27/Jul/95                      */
/***********************************************************************/
/*                      IMPORTANTE                                     */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  'COBISCORP'.                                                       */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de COBISCORP o su representante.             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*  Este stored procedure verifica la existencia de un tramite         */
/*  y hace QUERY del mismo.                                            */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*    FECHA           AUTOR                     RAZON                  */
/*  11/Abr/97     Isaac Parra       Emision Inicial                    */
/*  17/Dic/97     Myriam Davila     Upgrade Cartera                    */
/*  26/May/98     Julio Lopez       Personalizacion SV                 */
/*  15/Oct/01     Susana Paredes    Revision V. Base                   */
/*  07/Abr/05     Vivi Arias        Agrega campos de dscto.            */
/*  Oct/2005      N.Maldonado       Correccion campo fdes              */
/*  Abr/2006      Viviana Arias     Días a prorrogar para              */
/*                                  reestructuraciones.                */
/*  Ago/11/2007   Sandra Robayo     Consulta si se encuentra en        */
/*                                  etapa incial de la ruta.           */
/*  Sep/20/2007   Sandra Robayo     CD00254                            */
/*  27-Mar-2009   Sandra Robayo     Obtener campo que indica si la     */
/*                                  operacion de factoring es comprada */
/*                                  por el banco o no. VERSION         */
/*                                  FACTORING.                         */
/*  10-Abr-2015   Nancy Martillo    Se agregan campos query para       */
/*                                  datos adicionales                  */
/*  27-May-2015   Adriana Chiluisa  Se agrega el campo plazo           */
/*                                  de linea en dias                   */
/*  29/Sept/2015  Mariela Cabay     Se agrega Obsrv  reprogramación    */
/*  15/Abr/2021   Paulina Quezada   Ajustes para IMPACT FINCA          */
/*  14/Dic/2021   Esteban Baez      Reestructuracion mayor monto       */
/*  05/Abr/2022   Dilan Morales     Ajustes para Lineas numero banco   */
/*  10/May/2022   Dilan Morales     Se añade @w_vinculacion            */
/*  21/Jun/2022   Dilan Morales     Se añade @w_es_grupal              */
/***********************************************************************/
use cob_credito
go

if object_id ('cob_credito..sp_query_tramite') is not null
    drop proc sp_query_tramite
go

create proc sp_query_tramite (
       @s_user                      login         = null,
       @t_debug                     char(1)       = 'N',
       @t_file                      varchar(14)   = null,
       @t_from                      varchar(30)   = null,
       @t_show_version              bit           = 0,         -- Mostrar la version del programa
       @i_tramite                   int           = null,
       @i_numero_op_banco           char(24)      = null,
       @i_linea_credito             char(24)      = null,
       @i_producto                  catalogo      = null,
       @i_es_acta                   char(1)       = null,
       @i_formato_fecha             tinyint       = 103        --LIM 30/Mar/2006
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
       @w_linea_credito             int,            /* renovaciones y operaciones */
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
       -- variables para datos adicionales de operaciones de cartera
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
       /* variables para completar datos del registro de un tramite */
       @w_des_oficial               descripcion,
       @w_des_sector                descripcion,
       @w_des_nivel_ap              descripcion,
       @w_nom_ciudad                descripcion,      /*descripcion de tr_ubicacion */
       @w_nom_cliente               varchar(255),
       @w_ciruc_cliente             varchar(35),      --RZ
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
       -- variables para operacion a reestructurar
       @w_banco_rest                cuenta,          --numero de banco
       @w_operacion_rest            int,             --secuencial
       @w_toperacion_rest           catalogo,        --tipo de operacion
       @w_fecha_vto_rest            datetime,        --fecha vencimiento
       @w_monto_rest                money,           --monto original
       @w_saldo_rest                money,           --saldo capital
       @w_moneda_rest               tinyint,         --moneda
       @w_renovacion_rest           smallint,        --numero de renovacion
       @w_renovable_rest            char(1),         --renovable
       @w_fecha_ini_rest            datetime,        --fecha concesion
       @w_producto_rest             catalogo,        --producto
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
       @w_causa                     char(1),         --Personalizaci¢n Banco Atlantic
       @w_migrada                   cuenta,          --RZ Personalizaci¢n Banco Atlantic
       @w_lin_op                    cuenta,
       @w_tipo_prioridad            char(1),
       @w_descripcion               varchar(40),
       @w_proposito_op              catalogo,        --Vivi
       @w_des_proposito_op          descripcion,     --Vivi
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
       @w_anticipo                  int,                --SYR CD00254
       @w_monto_solicitado          money,
       @w_cuota                     money,
       @w_frec_pago                 catalogo,
     @w_moneda_solicitada         tinyint,
       @w_provincia                 int,
       @w_pplazo                    smallint,
       @w_tplazo                    catalogo,
       @w_sindicado                 char(1),            --JMA Datos Adicionales FIE
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
       @w_ventas_anuales            money,              --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales
       @w_activos_productivos       money,              --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales
       @w_simbolo_moneda            varchar(10),        --Adry
       @w_sector_cli                catalogo,
       @w_li_dias                   smallint,           --Adry
       @w_expromision               catalogo,
       @w_level_indebtedness        char(1),
       @w_convenio                  char(1),
       @w_codigo_cliente_empresa    varchar(10),
       @w_lin_comext                cuenta,
       @w_reprograming_Observ       varchar(255),
       @w_motivo_uno                varchar(255),       -- ADCH, 05/10/2015 motivo para tipo de solicitud
       @w_motivo_dos                varchar(255),       -- ADCH, 05/10/2015 motivo para tipo de solicitud
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
       @w_dias_anio                 int,                --PQU integración
       @w_dia_fijo                  smallint,           --PQU integración
       @w_enterado                  catalogo,           --PQU integración
       @w_otros_ent                 varchar(64),        --PQU integración
       @w_seguro_basico             char(1),            --PQU integración
       @w_seguro_voluntario         catalogo,           --PQU integración
       @w_tr_porc_garantia          float,              --PQU integración
       @w_monto_maximo              money,              --EBA reestructuracion
       @w_vinculacion               char(1),            --DMO vinculacion
       @w_es_grupal                 char(1)             --DMO  listas negras                

if @t_show_version = 1
begin
    print 'Stored procedure sp_query_tramite, Version 4.0.0.2'
    return 0
end

-- ********************
/* Chequeo de Existencias */
/**************************/
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
     @w_proposito           = tr_proposito,             /* garantias*/
     @w_razon               = tr_razon,
     @w_txt_razon           = rtrim(tr_txt_razon),
     @w_efecto              = tr_efecto,
     @w_cliente             = tr_cliente,               /*lineas*/
     @w_grupo               = tr_grupo,
     @w_fecha_inicio        = tr_fecha_inicio,
     @w_num_dias            = datediff(month,tr_fecha_inicio,(dateadd( day, tr_num_dias, tr_fecha_inicio))),--tr_num_dias,
     @w_per_revision        = tr_per_revision,
     @w_condicion_especial  = tr_condicion_especial,
     @w_linea_credito       = tr_linea_credito,         /*renov. y operaciones*/
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
     @w_proposito_op        = tr_proposito_op,          --Vivi
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
     @w_enterado            = tr_enterado,              --PQU integración
     @w_otros_ent           = tr_otros,                 --PQU integración
     @w_tr_porc_garantia    = tr_porc_garantia,         --PQU integración
     @w_sub_actividad       = tr_cod_actividad          --PQU integración
from cr_tramite
     left outer join cobis..cl_funcionario a on tr_usuario = a.fu_login
     where tr_tramite = @i_tramite

-- Si registro no existe ==> error
if @@rowcount = 0
begin
   /*Registro no existe */
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = 'sp_query_tramite',
   @i_num   = 2101005
   return 2101005
end

/*********** TRAER DATOS COMPLEMENTARIOS **************/
--Consulta datos adicionales
if @w_tipo != 'C'
begin
exec sp_tr_datos_adicionales
    @t_trn= 21118,
    @i_operacion       = 'S',
     @i_tramite         =@i_tramite
end

-- Obtener la secuencia en la que se encuentra en su ruta
select @w_secuencia = rt_secuencia,
       @w_paso =  rt_paso
from   cr_ruta_tramite
where  rt_tramite = @i_tramite
and    rt_salida is NULL
if @@rowcount = 0
       select @w_secuencia = max(rt_secuencia)
       from   cr_ruta_tramite
       where  rt_tramite = @i_tramite

-- descripcion del tipo de tramite*/
select @w_desc_tipo = tt_descripcion
from   cr_tipo_tramite
where  tt_tipo = @w_tipo

-- descripcion de la oficina
select @w_desc_oficina = of_nombre
from   cobis..cl_oficina
where  of_oficina = @w_oficina_tr

-- descripcion de la ciudad
select @w_desc_ciudad = ci_descripcion
from   cobis..cl_ciudad
where  ci_ciudad = @w_ciudad

if @w_linea_credito is not null
begin
-- numero de banco de la linea de credito
   select @w_li_num_banco = li_num_banco
   from   cob_credito..cr_linea
   where  li_numero = @w_linea_credito
end

-- nombre del oficial
    select @w_des_oficial = fu_nombre
    from cobis..cc_oficial, cobis..cl_funcionario
    where oc_oficial = @w_oficial
    and oc_funcionario = fu_funcionario

-- descripcion del sector
    select @w_des_sector = a.valor
    from cobis..cl_catalogo a, cobis..cl_tabla b
         -- Se cambia por problemas con cc
         -- JCL 09-Feb-99
    where  b.tabla = 'cl_sector_neg' -- 'cc_sector'
    and a.codigo = @w_sector
    and a.tabla = b.codigo
-- descripcion del destino
    if @w_destino is not null
        select @w_des_destino = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_destino
        and a.tabla = b.codigo
        and b.tabla = 'cr_destino'

-- nombre del cliente
    /*Incluir Financiamientos SBU: 20/abr/2000 */
    if @w_tipo in ('O', 'R', 'E', 'F')
       select @w_cliente = de_cliente
       from   cr_deudores
       where  de_tramite = @i_tramite
       and    de_rol = 'D'
    if @w_cliente is not null
        select @w_nom_cliente = rtrim(substring(en_nomlar,1,datalength(en_nomlar))),    --RZ
               @w_ciruc_cliente = substring(en_ced_ruc,1,datalength(en_ced_ruc))        --RZ
        from cobis..cl_ente
        where en_ente = @w_cliente
-- nombre del grupo
    if @w_grupo is not null
        select @w_nom_grupo = gr_nombre
        from cobis..cl_grupo
        where gr_grupo = @w_grupo
-- periodicidad de revision
    if @w_per_revision is not null
        select @w_des_per_revision = pe_descripcion
        from cr_periodo
        where pe_periodo = @w_per_revision
-- tipo de operacion
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
-- moneda
    if @w_moneda is not null
        select @w_des_moneda = mo_descripcion
        from cobis..cl_moneda
        where mo_moneda = @w_moneda
-- ciudad destino
    if @w_ciudad_destino is not null
        select @w_nom_ciudad = ci_descripcion
        from cobis..cl_ciudad
        where ci_ciudad = @w_ciudad_destino
-- descripcion de razon de cambio de garantia
    if @w_razon is not null
        select @w_des_razon = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_razon
        and a.tabla = b.codigo
    and b.tabla = 'cr_razon'
-- descripcion de proposito de cambio de garantia
    if @w_proposito is not null
        select @w_des_proposito = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_proposito
        and a.tabla = b.codigo
        and b.tabla = 'cr_proposito'
-- descripcion de efecto de cambio de garantia
    if @w_efecto is not null
        select @w_des_efecto = a.valor
        from cobis..cl_catalogo a, cobis..cl_tabla b
        where a.codigo = @w_efecto
    and a.tabla = b.codigo
        and b.tabla = 'cr_efecto'

-- descripcion de la frecuencia de pago            -- Adry
    select @w_des_frec_pago = td_descripcion
    from   cob_cartera..ca_tdividendo
    where  td_tdividendo = @w_frec_pago

-- simbolo moneda                                  -- Adry
    if @w_moneda is not null
        select @w_simbolo_moneda = mo_simbolo
        from cobis..cl_moneda
        where mo_moneda = @w_moneda
        
    if @w_sub_actividad is not null
        select @w_sub_actividad_desc = se_descripcion
        from   cobis..cl_subactividad_ec
        where  se_codigo = @w_sub_actividad
        
--monto maximo para un tamite EBA
---EBA 2021-12-14 DEVUELVE EL MONTO MAXIMO PARA VALIDACION DE OPERACIONES REESTRUCTURACION INDIVIDUAL 
if @w_toperacion is not null and @w_moneda is not null
select @w_monto_maximo = dt_monto_max
from   cob_cartera..ca_default_toperacion
where  dt_toperacion = @w_toperacion
and    dt_moneda     = @w_moneda

---FIN EBA 2021-12-14 DEVUELVE EL MONTO MAXIMO PARA VALIDACION DE OPERACIONES REESTRUCTURACION INDIVIDUAL       
        
/* traer los valores adicionales de las tablas de cartera */
if @w_producto = 'CCA'
begin
   /* calculo en base al No. tramite */
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
          @w_migrada                 = op_migrada,               --RZ Banco Atlantic
          @w_tipo_amortizacion       = op_tipo_amortizacion,
          @w_fecha_fin_new           = op_fecha_fin,
          @w_dias_anio               = op_dias_anio,
          @w_banco_rest              = op_anterior,
          @w_dia_fijo                = op_dia_fijo,              --PQU integración se añade
          @w_cuota                   = isnull(@w_cuota,op_cuota) --PQU integración se añade
   from   cob_cartera..ca_operacion
          left outer join cob_cartera..ca_tdividendo on td_tdividendo = op_tplazo
   where  op_tramite = @i_tramite

   if @w_tipo_top = 'R'
   select @w_li_num_banco = @w_lin_op

   if @w_tipo_amortizacion = 'MANUAL'
      select @w_des_periodo = 'DIAS'

 /*PQU integracion
                                                                                       
   select @w_cuenta = pa_cuenta  --PQU integración se quita comentar
     from cob_cartera..ca_pago_automatico
    where pa_operacion = @w_numero_operacion
   */ --fin PQU integracion                             


    if (@w_numero_op_banco is null or rtrim(@w_numero_op_banco) ='')
        select @w_numero_op_banco = @w_num_banco_cartera


 -- descripcion de Sector Contable
   select @w_des_sector_contable = a.valor
   from cobis..cl_catalogo a, cobis..cl_tabla b
   where a.codigo = @w_sector_contable
     and a.tabla = b.codigo
     and b.tabla = 'cu_sector'

select  @w_des_origen_fondo = null  

-- descripcion del plazo contable

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

--  *******************
   if @w_forma_pago is not null
   begin
          select @w_des_fpago = cp_descripcion
       from cob_cartera..ca_producto
       where cp_producto = @w_forma_pago
   end
   -- tasa de interes
   select @w_val_tasaref=  isnull(sum(ro_porcentaje) ,0)
   from   cob_cartera..ca_rubro_op
   where  ro_operacion  =  @w_numero_operacion
      and ro_tipo_rubro =  'I'
      and ro_fpago      in ('P','A','T') --Para el caso de desc. docume. se aumenta el parametro T
   -- contador de dividendos
   select @w_cont_dividendos = count(*)
   from   cob_cartera..ca_dividendo
   where  di_operacion = @w_numero_operacion
   -- datos de la operacion a reestructurar

   if @w_tipo = 'E'
   begin
      --obtener los datos de la operacion
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
      --obtener el saldo de capital
      select @w_saldo_rest = sum(isnull(am_cuota,0) + isnull(am_gracia,0) - isnull(am_pagado,0))-- - isnull(am_exponencial,0))--TCRM
      from   cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
      where  ro_operacion = @w_operacion_rest
         and ro_tipo_rubro in ('C')    -- tipo de rubro capital
         and am_operacion = ro_operacion
         and am_concepto  = ro_concepto

      --obtener el numero de veces reestructurada
      select @w_numero_prorrogas=count(*)
        from cob_cartera..ca_transaccion
  where tr_operacion = @w_numero_operacion
         and tr_tran      = 'RES'
         and tr_estado   != 'RV'

      --DIAS A PRORROGAR
      select @w_dias_a_prorrogar = isnull(DATEDIFF(dd, @w_fecha_vto_rest, @w_fecha_fin_new),0)
   end
end

--Vivi, DESCRIPCION DEL PROPOSITO DE LA OPERACION
select @w_des_proposito_op = a.valor
  from cobis..cl_catalogo a, cobis..cl_tabla b
 where a.codigo = @w_proposito_op
   and a.tabla = b.codigo
   and b.tabla = 'cr_proposito_linea'

select @w_tipo_t =  tt_descripcion,
       @w_tipo_opera_t = (select valor from cobis..cl_catalogo   -- actividad
                          where codigo = cr_tramite.tr_toperacion
                            and tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_toperacion'))
from cr_tramite, cr_tipo_tramite
where tt_tipo = tr_tipo
 and tr_tramite = @w_tramite

select @w_asunto =  'Aprobación de ' + rtrim(@w_tipo_t) + ', ' + rtrim(@w_tipo_opera_t)

if @w_tipo = 'P'
begin
   select @w_motivo = (select valor from cobis..cl_catalogo   -- actividad
                         where codigo = cr_prorroga.pr_motivo
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_motivo_linea')),
          @w_des_clase_asunto  = (select valor from cobis..cl_catalogo   -- actividad
                         where codigo = cr_tramite.tr_toperacion
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_clase_linea')),
          @w_des_tope_asunto         = (select valor from cobis..cl_catalogo
                         where codigo = cr_prorroga.pr_tipo
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_tipo_linea')),
          @w_numero_testimonio = pr_numero_testimonio,
          @w_moneda_solicitada =cr_tramite.tr_moneda_solicitada
   from cr_prorroga, cr_tramite
   where pr_tramite = @w_tramite
     and pr_tramite = tr_tramite
     and tr_tramite = @w_tramite

   select @w_asunto = 'Modificación de ' +  rtrim(@w_des_clase_asunto)  + ' ' + rtrim(@w_des_tope_asunto) + ' por ' + rtrim(@w_motivo)
end

if @w_tipo = 'L'
begin
   select @w_des_tope_asunto       = (select valor from cobis..cl_catalogo
                         where codigo = cr_linea.li_tipo
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_tipo_linea')),
          @w_des_clase_asunto = (select valor from cobis..cl_catalogo   -- actividad
                         where codigo = cr_tramite.tr_toperacion
                           and tabla = (select codigo from cobis..cl_tabla where tabla = 'cr_clase_linea')),
          @w_li_dias = li_dias
   from cr_linea, cr_tramite
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



--DMO VERIFICACION SI EXISTE VINCULACION ENTRE CLIENTE
select @w_vinculacion = 'N'

IF EXISTS (select 1
from cobis..cl_relacion, cobis..cl_instancia,cobis..cl_ente
where in_ente_i = @w_cliente 
and in_relacion = re_relacion
and in_ente_d = en_ente)
BEGIN
    select @w_vinculacion = 'S'
END


select  @w_oficial_linea = tr_oficial
from cob_credito..cr_linea,cob_credito..cr_tramite
where li_tramite = tr_tramite
and   li_numero  = @w_linea_credito

----------------------------
--Consulta datos de la linea
----------------------------
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


select @w_es_grupal = 'N'
if exists(select 1 from cr_tramite_grupal where tg_tramite = @i_tramite)
BEGIN
    select @w_es_grupal = 'S'
END


/********* retorno al front-end ****************/
select
       @w_tramite,                                      --1
       @w_desc_ruta,                                    
       @w_tipo,                                         
       @w_desc_tipo,                                    
       @w_oficina_tr,                                   
       @w_desc_oficina,                                 
       @w_usuario_tr,                                   
       @w_nom_usuario_tr,                               
       @w_fecha_crea,                                   
       @w_oficial ,                                     --10
       @w_ciudad ,                                      
       @w_desc_ciudad ,                                 
       @w_estado ,                                      
       @w_secuencia ,                                   
       isnull(@w_numero_op_banco, 'L'+convert( varchar,@w_tramite)) ,                             
       @w_proposito ,                                   /* datos de garantias */
       @w_des_proposito,                                
       @w_razon ,                                       
       @w_des_razon,                                    
       @w_txt_razon ,                                   --20
       @w_efecto,                                       
       @w_des_efecto,                                   
       @w_cliente ,                                     /* datos de lineas de credito */
       @w_grupo ,                                       
       @w_fecha_inicio,                                 
       @w_num_dias ,                                    
       @w_per_revision ,                                
       @w_condicion_especial ,                          
       @w_toperacion,                                   /* datos de originales y renovaciones */
       @w_producto ,                                    --30
       @w_li_num_banco,                                 
       @w_monto ,                                       
       @w_moneda,                                       
       @w_periodo,                                      
       @w_num_periodos,      
       @w_destino,                                      
       @w_provincia,                                    --PQU integración se añade
       @w_renovacion ,                                  
       @w_fecha_reajuste,     /* datos para cartera */
       @w_monto_desembolso,                             --40
       @w_periodo_reajuste,                             
       @w_reajuste_especial,                            
       @w_forma_pago,                                   
       @w_cuenta,                                       
       @w_cuota_completa,                               
       @w_tipo_cobro,                                   
       @w_tipo_reduccion,                               
       @w_aceptar_anticipos,                            
       @w_precancelacion,                               
       @w_tipo_aplicacion,                              --50
       @w_renovable,                                    
       @w_reajustable,                                  
       @w_val_tasaref,                                  
       @w_fecha_concesion,                              /* todos los tramites */ --LIM 30/Mar/2006 Se cambia 103 por @i_formato_fecha
       @w_sector,                                       
       @w_des_oficial,                                  /* datos complementarios */
       @w_des_sector,                                   
       @w_des_nivel_ap,                                 
       @w_nom_ciudad,                                   
       @w_nom_cliente,                                  --60
       @w_ciruc_cliente,                                
       @w_nom_grupo,                                    
       @w_des_per_revision,                             
       @w_des_segmento,                                 
       @w_des_toperacion,                               
       @w_des_moneda,                                   
       @w_des_periodo,                                  
       @w_des_destino,                                  
       @w_des_fpago,                                    
       @w_paso,                                         /* paso en la ruta*/ --70
       @w_cont_dividendos,                              /* contador de dividendos*/
       @w_banco_rest,                                   /* operacion a reestructurar*/
       @w_operacion_rest,                               
       @w_toperacion_rest,                              
       @w_fecha_vto_rest,                               
       @w_monto_rest,                                   
       @w_saldo_rest,                                   
       @w_moneda_rest,                                  
       @w_renovacion_rest,                              
       @w_renovable_rest,                               --80
       @w_fecha_ini_rest,
       @w_producto_rest,
       @w_origen_fondo,
       @w_des_origen_fondo,
       @w_fondos_propios,
       @w_sector_contable,
       @w_des_sector_contable,
       @w_plazo + ' (' + @w_des_plazo ,
       @w_proposito_op + ' (' + @w_des_proposito_op ,
       @w_tipo_top,                                     --90
       @w_causa,                                        --Personalizaci¢n Banco Atlantic
       @w_migrada,                                      --RZ Banco Atlantic
       @w_tipo_prioridad,                               
       @w_descripcion,                                  
       @w_efecto_pago,                                  
       @w_monto_solicitado,                             
       isnull(@w_cuota, 0),                                        
       @w_periodo,                                      --@w_frec_pago,
       @w_moneda_solicitada,                            
       @w_provincia,                                    --100
       @w_monto_desembolso_tr ,
       @w_pplazo ,
       @w_tplazo ,
       @w_sindicado ,
       @w_tipo_cartera ,
       isnull(@w_destino_descripcion,''),               --Adry
       @w_mes_cic ,                                     
       @w_anio_cic ,                                    
       @w_patrimonio ,                                  
       @w_ventas ,                              --110
       @w_num_personal_ocupado ,                        
       @w_tipo_credito ,
       @w_indice_tamano_actividad ,
       @w_objeto ,
       @w_sub_actividad,                                --@w_actividad ,--Integracion con FIE, no se muestra este campo, si no por catalogo su subActividad
       isnull(@w_descripcion_oficial,' '),
       @w_origen_fondos,
       @w_des_frec_pago,                                --Adry
       @w_ventas_anuales,                               --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales
       @w_activos_productivos,                          --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales          --120
       @w_simbolo_moneda,                               --Adry
       @w_sector_cli,                                   --JCA
       @w_li_dias,                                      --Adry
       @w_expromision,                                  
       @w_numero_op,                                    --NMA 23-06-2015
       @w_level_indebtedness,                           --NMA 22-07-2015
       @w_convenio,                                     
       @w_codigo_cliente_empresa,                       
       @w_num_banco_cartera,                            --Adry
       @w_lin_comext,                                   --Adry         --130
       @w_reprograming_Observ,                          --MCA Observación de reprogramación
       @w_motivo_uno,                                   -- ADCH, 05/10/2015 motivo para tipo de solicitud
       @w_motivo_dos,                                   -- ADCH, 05/10/2015 motivo para tipo de solicitud
       @w_motivo_rechazo,
       @w_numero_testimonio,
       @w_linea_credito,
       @w_producto_fie,
       @w_num_viviendas,
       @w_tipo_calificacion,
       @w_calificacion,                                 --140
       @w_es_garantia_destino,                          
       @w_es_deudor_propietario,                        
       @w_tamanio_empresa,                              
       @w_vinculacion,                                  --DMO DATA PARA VINCULACION
       @w_ciudad_destino,                               --@w_des_oficial_con,en Front es ciudad
       @w_oficial_linea,                                
       'N',                                             --@w_des_fun_linea,  --op_clase para calculo de interes en tabla de amortizacion
       @w_dias_anio,                                    --@w_tasa,
       @w_sub_actividad,                                
       @w_sub_actividad_desc,                           --150
       ' ',                                             --@w_departamento,--PQU integración se coloca un texto vacio
       ' ',                                             
       ' ',                                             
       @w_fecha_ven,                                    
       @w_rotativa,                                     
       @w_linea,                                        
       @w_fecha_ini,                                    
       @w_dias,                                         
       @w_sector,                                       -- DFL Fin
       @w_dia_fijo,                                     -- 160  --PQU integración se añade
       @w_enterado,                                     --PQU integración se añade
       @w_otros_ent,                                    --PQU integración se añade
       @w_seguro_basico,                                --PQU integración se añade
       @w_seguro_voluntario,
       @w_monto_maximo,                                 --EBA monto maximo permitido para operaciones de reestructuracion 
       @w_es_grupal                                     --DMO verificacion si es grupal
select @w_linea_cancelar_str=li_num_banco
  from cr_linea
 where li_numero=@w_linea_cancelar

/*  SYR AGO-2007 Se consulta si el tramite se encuentra en la etapa incial */
select @w_count = 0

select @w_estacion = es_estacion
from cob_credito..cr_estacion
where es_usuario = @w_usuario_tr

/********* retorno al front-end PART II ****************/

select  @w_linea_cancelar_str,
        convert(char(10),@w_fecha_irenova,@i_formato_fecha),
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
        @w_etapa_inicial,            -- SYR 23
        @w_anticipo                  -- SYR CD00254
return 0
GO

