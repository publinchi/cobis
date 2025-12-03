/********************************************************************/
/*    NOMBRE LOGICO: sp_datos_sensibles_cliente                     */
/*    NOMBRE FISICO: datos_sensibles_cliente.sp                     */
/*    PRODUCTO: Clientes                                            */
/*    Disenado por: JMEG                                            */
/*    Fecha de escritura: 30-Abril-19                               */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                           PROPOSITO                              */
/*   Este programa sirve para la actulizacion de datos sensibles    */
/*   de un cliente                                                  */
/********************************************************************/
/*               MODIFICACIONES                                     */
/*     FECHA          AUTOR                RAZON                    */
/*   16/Julio/2019    JMEG   Versión Inicial                        */
/*   12/Junio/2020    FSAP   Estandarizacion de Clientes            */
/*   24/Noviembre/20  EGL    Agregando variable @i_genero           */
/*   09/Diciembre/20  IYU    Actualizar campo estado civil          */
/*   12/Enero/21      IYU    Actualizacion Tipos Identificacion     */
/*   23/Marzo/21      COB    Coreccion verificacion de cliente      */
/*   30/Marzo/21      JOR    Condición CURP y RFC no nulos          */
/*   10/Mayo/21       JGU    Func. Apellido de casada               */
/*   17/Agosto/21     COB    Eliminar validacion de otros modulos   */
/*   17/Enero/23      BDU    S762873: Se agregan nuevos campos      */
/*   23/Marzo/22      BDU    S801301 Se quita campo obligatorio     */
/*   30/Jun/2023      EBA    S849151 se realiza la conversión       */
/*                           de los tipos de documento              */
/*                           principal y tributario que             */
/*                           vienen desde la app enbase a la        */
/*                           máscara parametrizada.                 */
/*   28/Junio/23      BDU    S849165 Se quita 'DE' del apellido     */
/*   10/Julio/23      EBA    B850916 Se obtiene el valor Soltero    */
/*                           del catalogo estado civil              */
/* 09/Septiembre/23   BDU    R214440-Sincronizacion automatica      */
/* 05/Octubre/23      BDU    R214440-Ajuste campo lugar doc         */
/* 20/Octubre/2023    BDU    R217831-Ajuste validacion error        */
/* 08/Noviembre/2023  BDU    R217831-Se permite Conocido Por vacio  */
/* 20/Noviembre/2023  BDU    R219616-Validacion cambio de oficial   */
/* 21/Noviembre/2023  BDU    R219616-Ajuste validacion oficial      */
/* 22/Diciembre/2023  BDU    R221783-Validar provincia 0            */
/* 22/Enero/2024      BDU    R224055-Validar oficina app            */
/* 06/Marzo/2024      BDU    R228486: Se corrige validación DUI     */
/* 28/Mayo/2024       DMO    R236030:Se corrige actualizacion nombre*/
/* 05/Septiembre/2024 BDU    R245295:Se agrega valor por defecto ofi*/
/* 05/Junio/2025     GRO     R248888:campos conozca su cliente      */
/********************************************************************/
use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_datos_sensibles_cliente')
   drop PROCEDURE sp_datos_sensibles_cliente
go

create PROCEDURE sp_datos_sensibles_cliente (
    @t_trn                     int,
    @s_ssn                     int           = null,
    @s_user                    login         = null,
    @s_term                    varchar(32)   = null,
    @s_date                    datetime,
    @s_srv                     varchar(30)   = null,
    @s_lsrv                    varchar(30)   = null,
    @s_ofi                     smallint      = null,
    @s_rol                     smallint      = NULL,
    @t_debug                   char(1)       ='N',
    @t_file                    varchar(14)   = null,
    @t_show_version            bit           = 0,
    @i_batch                   char(1)       = 'N',
    @i_ente                    int,
    @i_nombre                  varchar(64) ,
    @i_segnombre               varchar(50)   = null,
    @i_p_p_apellido            varchar(64) ,
    @i_p_s_apellido            varchar(64)   = null,
    @i_sexo                    varchar(10)   = null,
    @i_genero                  varchar(10)   = null,
    @i_fecha_nac               datetime      = null,
    @i_provincia_nac           int           = null,
    @i_estado_civil            catalogo      = null, -- Codigo  del estado civil de la persona
    @i_curp                    varchar(30)   = null,
    @i_rfc                     varchar(15)   = null,
    @i_apellido_c              varchar(30)   = null,
    @i_oficial                 int           = null,
    @i_migrado                 varchar(30)   = null,
    @i_identificationType      varchar(64)   = null,
    @i_identificationNumber    varchar(64)   = null,
    @i_tipo_residencia         varchar(4)    = null,
    @i_ea_con_como             varchar(255)  = null,
    @i_ciudad_emi              int           = null,
    @i_fecha_emi               datetime      = null,
    @i_fecha_vto               datetime      = null,
    @i_is_app                  char(1)       = 'N',
    @i_lug_trab                varchar(200)  = null,      
    @o_identificationType      varchar(64)   = null out,
    @o_identificationNumber    varchar(64)   = null out
)
AS
  declare 
  @w_sp_name                    descripcion,
  @w_sp_msg                     varchar(132),
  @w_edad_max                   smallint,    --MTA edad maxima
  @w_edad_min                   smallint,    --MTA edad minima
  @w_anios_edad                 smallint,
  @w_nombre                     varchar(64) ,
  @w_segnombre                  varchar(50)   = null,
  @w_p_p_apellido               varchar(64) ,
  @w_p_s_apellido               varchar(64) ,
  @w_sexo                       varchar(10) ,
  @w_fecha_nac                  datetime ,
  @w_provincia_nac              int ,
  @w_curp                       varchar(30) ,
  @w_rfc                        varchar(15),
  @w_nomlar                     varchar(100),
  @w_ea_curp                    varchar(30) ,
  @w_ea_rfc                     varchar(15),
  @w_g_curp                     varchar(30) ,
  @w_g_rfc                      varchar(15),
  @w_msg                        varchar(100),
  @w_return                     int,
  @w_nombre_completo            varchar(254),
  @w_s_nombre_t                 varchar(50),
  @w_s_apellido_t               varchar(30),
  @w_estado_civil               catalogo,
  @w_nemovda                    char(3),
  @w_estados                    varchar(15),
  @w_nemomed                    char(3),
  --campos para tablas de seguridad
  @w_referidor_ecu              int,
  @w_dias_anio_nac              smallint,
  @w_dias_anio_act              smallint,
  @w_inic_anio_nac              datetime,
  @w_inic_anio_act              datetime,
  @w_anio_nac                   char(4),
  @w_anio_act                   char(4),
  @w_siguiente                  int,
  @w_codigo                     int,
  @w_p_apellido                 varchar(30),
  @w_s_apellido                 varchar(30),
  @w_paso                       char(1),
  @w_tipo_ced                   char(4),
  @w_cedula                     numero,
  @w_pasaporte                  varchar(20),
  @w_pais                       smallint,
  @w_profesion                  catalogo,
  @w_num_cargas                 tinyint,
  @w_nivel_ing                  money,
  @w_nivel_egr                  money,
  @w_filial                     int,
  @w_oficina                    smallint,
  @w_tipo                       catalogo,
  @w_grupo                      int,
  @w_es_mayor_edad              char(1),     /* 'S' o 'N' */
  @w_mayoria_edad               smallint,   /* expresada en años */
  @w_oficial                    smallint,
  @w_oficial_sup                smallint,
  @w_retencion                  char(1),
  @w_exc_sipla                  char(1),
  @w_exc_por2                   char(1),
  @w_asosciada                  catalogo,
  @w_tipo_vinculacion           catalogo,
  @w_vinculacion                char(1),
  @w_mala_referencia            char(1),
  @w_actividad                  catalogo,
  @w_comentario                 varchar(254),
  @w_fecha_emision              datetime,
  @w_fecha_expira               datetime,
  @w_nivel_estudio              catalogo,
  @w_doc_validado               char(1),
  @w_tipo_vivienda              catalogo,
  @w_calif_cliente              catalogo,
  @w_total_activos              money,
  @w_rep_superban               char(1),
  @w_preferen                   char(1),
  @w_cem                        money,
  @w_nit_id                     numero,
  @w_nit_venc                   datetime,
  @w_catalogo                   catalogo,
  @w_sector                     catalogo,
  @w_nit                        numero,
  @w_referido                   smallint,
  @w_ciudad_nac                 int,
  @w_lugar_doc                  int,
  @w_gran_contribuyente         char(1) ,
  @w_situacion_cliente          catalogo,
  @w_patrim_tec                 money,
  @w_fecha_patrim_bruto         datetime ,
  @w_c_apellido                 varchar(30),  -- Campo apellido casada
  @w_s_nombre                   varchar(50),  -- Campo segundo nombre
  @w_depart_doc                 smallint,  -- Codigo del departamento
  @w_numord                     char(4),  -- Codigo de orden CV
  @w_promotor                   varchar(10),
  @w_num_pais_nacionalidad      int,    -- Codigo del pais de la nacionalidad del cliente
  @w_cod_otro_pais              char(10), -- Codigo de pais centroamericano
  @w_inss                       varchar(15), -- Numero de seguro
  @w_licencia                   varchar(30), -- Numero de licencia
  @w_ingre                      varchar(10), -- Codigo de Ingresos
  @w_en_id_tutor                varchar(20),  --ID del Tutor
  @w_en_nom_tutor               varchar(60),
  @w_digito                     char(2),
  @w_categoria                  catalogo,  --CVA Abr-23-07
  @w_carg_pub                   varchar(10),
  @w_rel_carg_pub               varchar(10),
  @w_situacion_laboral          varchar(5),  -- ini CL00031 RVI
  @w_bienes                     char(1),
  @w_otros_ingresos             money,
  @w_origen_ingresos            descripcion,
  @w_vu_pais                    catalogo,
  @w_vu_banco                   catalogo,
  @w_td_digito                  char(2),        -- CLI0517 - Determina si el tipo de documento es mandatorio o no.
  @w_ea_estado                  catalogo,
  @w_ea_observacion_aut         varchar(255 ),
  @w_ea_contrato_firmado        char(1),
  @w_ea_menor_edad              char(1),
  @w_ea_conocido_como           varchar(255 ),
  @w_ea_cliente_planilla        char(1),
  @w_ea_cod_risk                varchar(20),
  @w_ea_sector_eco              catalogo,
  @w_ea_actividad               catalogo,
  @w_ea_empadronado             char(1),
  @w_ea_lin_neg                 catalogo,
  @w_ea_seg_neg                 catalogo,
  @w_ea_val_id_check            catalogo,
  @w_ea_ejecutivo_con           int,
  @w_ea_suc_gestion             smallint,
  @w_ea_constitucion            smallint,
  @w_ea_remp_legal              int,
  @w_ea_apoderado_legal         int,
  @w_ea_act_comp_kyc            char(1),
  @w_ea_fecha_act_kyc           datetime,
  @w_ea_no_req_kyc_comp         char(1),
  @w_ea_act_perfiltran          char(1),
  @w_ea_fecha_act_perfiltran    datetime,
  @w_ea_con_salario             char(1),
  @w_ea_fecha_consal            datetime,
  @w_ea_sin_salario             char(1),
  @w_ea_fecha_sinsal            datetime,
  @w_ea_actualizacion_cic       char(1),
  @w_ea_fecha_act_cic           datetime,
  @w_ea_fuente_ing              catalogo,
  @w_ea_act_prin                catalogo,
  @w_ea_detalle                 varchar(255),
  @w_ea_act_dol                 money,
  @w_ea_cat_aml                 catalogo,
  @w_ea_observacion_vincula     varchar(255),
  @w_ea_fecha_vincula           datetime,
  @w_estado_ente                char(1),
  @w_doble_aut                  char(1), --Miguel Aldaz  06/22/2012 Doble autorizacion CLI-0565 HSBC
  @w_autorizacion               int,     --Miguel Aldaz  06/22/2012 Doble autorizacion CLI-0565 HSBC
  @w_estado_campo               char(1), --Miguel Aldaz  06/24/2012 Doble autorizacion CLI-0565 HSBC
  @w_nomb_user                  varchar(64),
  @w_ea_ced_ruc                 varchar(30),
  @w_ea_discapacidad            char(1),
  @w_ea_tipo_discapacidad       catalogo,
  @w_ea_ced_discapacidad        varchar(30),
  @w_asfi                       char(1),
  @w_egresos                    catalogo,
  @w_ifi                        char(1),
  @w_path_foto                  varchar(50),
  @w_nat_jur_hogar              catalogo,
  @w_tipo_compania              catalogo,
  @w_ea_indefinido              char(1),
  @w_banco                      varchar(20),
  @w_estado_std                 varchar(10),
  @w_calificacion               varchar(10),
  @w_relacion_ca                int,
  @w_partner                    char(1),
  @w_lista_negra                char(1),
  @w_in_ente_d                  int,
  @w_telefono_recados           varchar(10),
  @w_numero_ife                 varchar(13),
  @w_numero_serie_firma_elect   varchar(20),
  @w_persona_recados            varchar(60),
  @w_antecedentes_buro          varchar(2),
  @w_conyuge                    int,
  @w_error                      int,
  @w_pais_local                 int,
  @w_mexico                     int ,
  @w_tipo_residencia            char(2),
  @w_num                        int,
  @w_param                      int, 
  @w_diff                       int,
  @w_date                       datetime,
  @w_bloqueo                    char(1),
  @w_nacionalidad               varchar(10),
  @w_mascara                    varchar(30),
  @w_doc_prin_mascara           varchar(30),
  @w_default_estado_civil       catalogo,
  -- R214440-Sincronizacion automatica
  @w_sincroniza      char(1),
  @w_ofi_app         smallint

select @w_sp_name = 'sp_datos_sensibles_cliente'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.2')
  print  @w_sp_msg
  return 0
end

/* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
if @i_ente is not null and @i_ente <> 0
begin
   select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_ente
   if @w_bloqueo = 'S'
   begin
      exec sp_cerror
      @t_debug  = @t_debug,
      @t_file   = @t_file,
      @t_from   = @w_sp_name,
      @i_num    = 1720604
      return 1720604
   end
end 

--MTA Inicio
select @w_edad_min = pa_tinyint  --Edad minima
  from cobis..cl_parametro
 where pa_producto = 'ADM'
   and pa_nemonico = 'MDE'

select @w_edad_max = pa_tinyint --Edad maxima
  from cobis..cl_parametro
 where pa_producto = 'ADM'
   and pa_nemonico='EMAX'
--MTA Fin

select @w_nemovda = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'VDA'

select @w_nemomed = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'MED'

select @w_estados = pa_char--inc 69991
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'ECAC'

select @w_sp_name = 'sp_datos_sensibles_cliente'

set @i_identificationNumber = upper(@i_identificationNumber)
if @t_trn is null or @t_trn <> 172045
begin
  /* Codigo de transaccion invalido */
  exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_num   = 1720075
   return 1720075
end
     
select @w_anios_edad = datediff(yy, @i_fecha_nac, fp_fecha) 
  from cobis..ba_fecha_proceso
  
if ((@w_anios_edad < @w_edad_min) or (@w_anios_edad > @w_edad_max))
begin
  exec cobis..sp_cerror
     @t_debug    = @t_debug,
     @t_file     = @t_file,
     @t_from     = @w_sp_name,
     @i_num      = 1720044
  return 1720044
end

  select  
    @w_nombre                  = a.en_nombre,
    @w_segnombre               = a.p_s_nombre,
    @w_p_p_apellido            = a.p_p_apellido,
    @w_p_s_apellido            = a.p_s_apellido,
    @w_sexo                    = a.p_sexo,
    @w_curp                    = a.en_ced_ruc,
    @w_fecha_nac               = a.p_fecha_nac,
    @w_rfc                     = a.en_nit,
    @w_provincia_nac           = a.en_provincia_nac,
    @w_nomlar                  = a.en_nomlar,
    @w_estado_civil            = a.p_estado_civil,
    @w_tipo_ced                = a.en_tipo_ced,
    @w_pasaporte               = a.p_pasaporte,
    @w_pais                    = a.en_pais,
    @w_profesion               = a.p_profesion,
    @w_estado_civil            = a.p_estado_civil,
    @w_num_cargas              = a.p_num_cargas,
    @w_nivel_ing               = a.p_nivel_ing,
    @w_nivel_egr               = a.p_nivel_egr,
    @w_tipo                    = a.p_tipo_persona,
    @w_filial                  = a.en_filial,
    @w_oficina                 = a.en_oficina,
    @w_grupo                   = a.en_grupo,
    @w_oficial                 = a.en_oficial,
    @w_oficial_sup             = a.en_oficial_sup,
    @w_retencion               = a.en_retencion,
    @w_actividad               = a.en_actividad,
    @w_comentario              = a.en_comentario,
    @w_fecha_emision           = a.p_fecha_emision,
    @w_fecha_expira            = a.p_fecha_expira,
    @w_asosciada               = a.en_asosciada,
    @w_tipo_vinculacion        = a.en_tipo_vinculacion,
    @w_vinculacion             = a.en_vinculacion,
    @w_sector                  = a.en_sector,
    @w_referido                = a.en_referido,
    @w_ciudad_nac              = a.p_ciudad_nac,
    @w_nivel_estudio           = a.p_nivel_estudio,
    @w_tipo_vivienda           = a.p_tipo_vivienda,
    @w_doc_validado            = a.en_doc_validado,
    @w_calif_cliente           = a.p_calif_cliente,
    @w_lugar_doc               = a.p_lugar_doc ,
    @w_gran_contribuyente      = a.en_gran_contribuyente,
    @w_situacion_cliente       = a.en_situacion_cliente,
    @w_patrim_tec              = a.en_patrimonio_tec,
    @w_fecha_patrim_bruto      = a.en_fecha_patri_bruto,
    @w_total_activos           = a.c_total_activos,
    @w_rep_superban            = a.en_rep_superban,
    @w_preferen                = a.en_preferen,
    @w_exc_sipla               = a.en_exc_sipla,
    @w_exc_por2                = a.en_exc_por2,
    @w_digito                  = a.en_digito,
    @w_cem                     = a.en_cem,
    @w_c_apellido              = a.p_c_apellido,
    @w_depart_doc              = a.p_dep_doc,
    @w_numord                  = a.p_numord,
    @w_promotor                = a.en_promotor,
    @w_num_pais_nacionalidad   = a.en_nacionalidad,
    @w_cod_otro_pais           = a.en_cod_otro_pais,
    @w_inss                    = a.en_inss,
    @w_licencia                = a.en_licencia,
    @w_ingre                   = a.en_ingre,
    @w_en_id_tutor             = a.en_id_tutor,
    @w_en_nom_tutor            = a.en_nom_tutor,
    @w_categoria               = a.en_concordato, --CVA Abr-23-07
    @w_referidor_ecu           = a.en_referidor_ecu,
    @w_carg_pub                = a.p_carg_pub,
    @w_rel_carg_pub            = a.p_rel_carg_pub,
    @w_situacion_laboral       = a.p_situacion_laboral,  -- ini CL00031 RVI
    @w_bienes                  = a.p_bienes,
    @w_otros_ingresos          = a.en_otros_ingresos,
    @w_origen_ingresos         = a.en_origen_ingresos ,     -- fin CL00031 RVI}
    @w_tipo_compania           = a.c_tipo_compania, -- PJI CC-CTA-220
    @w_banco                   = a.en_banco,
    @w_calificacion            = a.en_calificacion,
    @w_tipo_residencia         = a.en_tipo_residencia
  from cl_ente a
  where a.en_ente = @i_ente
   
  
  if @@rowcount = 0
  begin
    exec sp_cerror
    @t_debug      = @t_debug,
    @t_file      = @t_file,
    @t_from      = @w_sp_name,
    @i_num       = 1720129
    return 1720129
    --NO EXISTE PERSONA
  end
  
  select @w_default_estado_civil = codigo
  from cobis..cl_catalogo 
  where tabla = (select codigo from cl_tabla where tabla = 'cl_ecivil')
  and valor like 'SO%'
  
  if @i_estado_civil is null select @i_estado_civil = @w_default_estado_civil
  
  select @w_estado_civil = @i_estado_civil
  select @w_c_apellido = @i_apellido_c

  select
       
       @w_ea_rfc  = b.ea_nit,
   @w_ea_curp = b.ea_ced_ruc
  from cobis..cl_ente_aux b
  where b.ea_ente = @i_ente
  
  select @w_pais_local      = pa_smallint 
    from cobis..cl_parametro 
    where pa_nemonico = 'CP'    
    and pa_producto = 'CLI'  -- PAIS DONDE ESTÁ EL BANCO
    
  if @i_nombre <>  @w_nombre or 
     @i_segnombre <> @w_segnombre or
     @i_p_p_apellido <> @w_p_p_apellido or
     @i_p_s_apellido <> @w_p_s_apellido or
     @i_sexo  <> @w_sexo or
     @i_fecha_nac <> @w_fecha_nac or
     @i_provincia_nac <> @w_provincia_nac
  begin
  
    -- PARA TEMAS QUE SOLO APLICAN PARA MX
    select @w_mexico =  codigo 
    from  cobis..cl_catalogo
    where tabla = (select top 1 codigo from cobis..cl_tabla where tabla = 'cl_pais'  ) 
    and   valor like '%MEXICO%'
    
    if @w_pais_local = @w_mexico 
    begin
        if (@i_curp is null or @i_curp = @w_curp) or (@i_rfc is null or @i_rfc = @i_rfc)
        begin
        
          --creacion del CURP y RFC
          select @w_msg = @i_nombre + ' ' + @i_segnombre
          exec @w_return = cobis..sp_generar_curp
            @i_primer_apellido       = @i_p_p_apellido,
            @i_segundo_apellido      = @i_p_s_apellido,
            @i_nombres               = @w_msg,
            @i_sexo                  = @i_sexo,
            @i_fecha_nacimiento      = @i_fecha_nac,
            @i_entidad_nacimiento    = @i_provincia_nac,
            @o_mensaje               = @w_msg  out,
            @o_curp                  = @w_g_curp out,
            @o_rfc                   = @w_g_rfc  out

          if @w_return <> 0
          begin

            
            if @i_batch = 'N'
            begin
              exec cobis..sp_cerror
              
               @t_debug= @t_debug,
               @t_file   = @t_file,
               @t_from   = @w_sp_name,
               --@i_msg    = @w_msg,
               @i_num    = @w_return
               return @w_return
            end  
            ELSE
            begin
              PRINT ' desde batch ' + @i_batch + '  1720046'
              return 1720046
            end
          end
          
          if (@i_curp is null or @i_curp = @w_curp)
          begin
            set @i_curp = @w_g_curp
              
     
          end
          
          if (@i_rfc is null or @i_rfc = @i_rfc)
          begin
            set @i_rfc = @w_g_rfc
               
          end
        
        end
      
    end    
  end
  
  if @w_pais_local <> @w_num_pais_nacionalidad
  begin
     select @w_nacionalidad = 'E'
  end
  else
  begin
     select @w_nacionalidad = 'N'
  end
  
 
  --VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION
if(select ti_estado from cl_tipo_identificacion 
   where ti_codigo         = @i_identificationType 
   and   ti_tipo_documento = 'P' 
   and   ti_nacionalidad   = @w_nacionalidad 
   and   ti_tipo_cliente   = 'P') != 'V'
begin
   exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file   = @t_file,
                   @t_from   = @w_sp_name,
                   @i_num    = 1720605
                   return 1720605
end
  
  --ARMADO DEL NOMBRE LARGO DEL CLIENTE, TOMANDO EN CUENTA SI ES CASADA, VIUDA O MENOR DE EDAD

    if @i_segnombre <> null
       select @w_s_nombre_t = ' '+ @i_segnombre

    if @i_p_s_apellido <> null
       select @w_s_apellido_t = ' '+ @i_p_s_apellido
       
if @i_sexo = 'F'
begin
  If (@w_estados like ('%'+@w_estado_civil+'%')) and (@w_estado_civil <>@w_nemovda)--inc 69991 si estado civil es casada o divorciada y diferente de viuda
  begin
     select @w_nombre_completo = isnull(@i_nombre, en_nombre) + @w_s_nombre_t + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + @w_s_apellido_t  from cl_ente where en_ente = @i_ente 
     if @w_c_apellido is not null
     begin
         select @w_nombre_completo = concat(@w_nombre_completo, ' ', @w_c_apellido)
     end
  end
  else if @w_estado_civil = @w_nemovda --68572
  begin
   
     select @w_nombre_completo = isnull(@i_nombre, en_nombre) + ' ' + isnull(p_s_nombre, @i_segnombre) + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + ' ' + isnull(@i_p_s_apellido, p_s_apellido) from cl_ente where en_ente = @i_ente 
  end
  else If @w_estado_civil = @w_nemomed
  begin
   --select @w_nombre_completo = isnull(@i_nombre, en_nombre) + ' ' + isnull(p_s_nombre, @i_segnombre) + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + ' ' + isnull(@i_p_s_apellido, p_s_apellido)+ ' (MENOR) ' from cl_ente where en_ente = @i_ente 
   select @w_nombre_completo = isnull(@i_nombre, en_nombre) + @w_s_nombre_t + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + @w_s_apellido_t + ' (MENOR) ' from cl_ente where en_ente = @i_ente 
  end
  else
  begin
     --select @w_nombre_completo = isnull(@i_nombre, en_nombre) + ' ' + isnull(p_s_nombre, @i_segnombre) + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + ' ' + isnull(@i_p_s_apellido, p_s_apellido) from cl_ente where en_ente = @i_ente 
     select @w_nombre_completo = isnull(@i_nombre, en_nombre) + @w_s_nombre_t + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + @w_s_apellido_t from cl_ente where en_ente = @i_ente 
  end
end
else
begin
   if @w_estado_civil = @w_nemomed
    begin
       --select @w_nombre_completo = isnull(@i_nombre, en_nombre) + ' ' + isnull(p_s_nombre, @i_segnombre) + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + ' ' + isnull(@i_p_s_apellido, p_s_apellido) + ' (MENOR) ' from cl_ente where en_ente = @i_ente 
       select @w_nombre_completo = isnull(@i_nombre, en_nombre) + @w_s_nombre_t + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + @w_s_apellido_t + ' (MENOR) ' from cl_ente where en_ente = @i_ente 
    end
   else
    begin
       --select @w_nombre_completo = isnull(@i_nombre, en_nombre) + ' ' + isnull(p_s_nombre, @i_segnombre) + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + ' ' + isnull(@i_p_s_apellido, p_s_apellido) from cl_ente where en_ente = @i_ente 
       select @w_nombre_completo = isnull(@i_nombre, en_nombre) + @w_s_nombre_t + ' ' + isnull(@i_p_p_apellido, p_p_apellido) + @w_s_apellido_t from cl_ente where en_ente = @i_ente 
    end
end


-- valida si se cambio el oficial y si el oficial es distinto a los de sus creditos
if (@i_oficial <> @w_oficial)
and exists(select 1 
           from cob_cartera..ca_operacion with (nolock) 
           where op_cliente = @i_ente 
           and op_estado not in (0,3,99,6)
           and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))) --tiene solicitudes
and ((select count(1) from (select  op_oficial, count(op_oficial) as cont
                           from cob_cartera..ca_operacion with (nolock) 
                           where op_cliente = @i_ente
                           and op_estado not in (0,3,99,6)
                           and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null))
                           group by op_oficial) G) <> 1 --Tiene mas de un oficial en las solicitudes
      or @i_oficial not in (select op_oficial 
                         from cob_cartera..ca_operacion with (nolock) 
                         where op_cliente = @i_ente 
                         and op_estado not in (0,3,99,6)
                         and  (op_grupal = 'N' or (op_grupal = 'S' and op_ref_grupal is not null)))) --el oficial a actualizar no es oficial de sus solicitudes
begin
   exec sp_cerror  
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720534
   return 1720534
end

--Validación para guardar identificación principal y tributaria con máscara definida
if @i_is_app = 'S'
begin
    if @i_identificationType = 'DUI'  and charindex('-', @i_identificationNumber) = 0
    begin
        --Tipo de identificación Principal
        select @w_mascara = ti_mascara
        from  cobis..cl_tipo_identificacion
        where ti_codigo = @i_identificationType
        and   ti_tipo_cliente = 'P'
        and   ti_tipo_documento = 'P'
        and   ti_nacionalidad   = @w_nacionalidad
        and   ti_estado = 'V'
        
        select @w_doc_prin_mascara = cobis.dbo.fn_parsea_identificacion (@i_identificationNumber, @w_mascara)
        select @i_identificationNumber = @w_doc_prin_mascara
    end
end

  
  if @i_provincia_nac = 0
  begin
     select @i_provincia_nac = null
  end

  
begin tran
     update cobis..cl_ente
      set en_nombre           = isnull(@i_nombre, en_nombre),
        p_p_apellido          = isnull(@i_p_p_apellido, p_p_apellido),
        p_s_apellido          = @i_p_s_apellido,
        p_sexo                = isnull(@i_sexo, p_sexo),
        p_genero              = isnull(@i_genero, p_genero),
        en_ced_ruc            = isnull(@i_identificationNumber, en_ced_ruc),
        en_tipo_ced           = isnull(@i_identificationType, en_tipo_ced),
        en_fecha_mod          = @s_date,
        p_fecha_nac           = isnull(@i_fecha_nac, p_fecha_nac),
        en_nomlar             = isnull(@w_nombre_completo, en_nomlar),
        p_s_nombre            = @i_segnombre,
        c_fecha_verif         = @s_date, --* Debe guardar la fecha de proceso
        en_provincia_nac      = isnull(@i_provincia_nac, en_provincia_nac),
        p_estado_civil        = isnull(@w_estado_civil,  p_estado_civil),
        p_c_apellido          = @w_c_apellido,
        en_oficial            = COALESCE(@i_oficial, en_oficial, -2), --Validacion de nulos
        en_ente_migrado       = @i_migrado,
        en_tipo_residencia    = isnull(@i_tipo_residencia, @w_tipo_residencia),
        en_ciudad_emision     = isnull(@i_ciudad_emi, en_ciudad_emision),
        p_lugar_doc           = isnull(@i_ciudad_emi, en_ciudad_emision),
        p_fecha_emision       = isnull(@i_fecha_emi, p_fecha_emision),
        p_fecha_expira        = isnull(@i_fecha_vto, p_fecha_expira),
        en_inf_laboral        = isnull(@i_lug_trab,en_inf_laboral)		
       
      where en_ente = @i_ente

   if @@error <> 0
    begin
       exec sp_cerror  @t_debug    = @t_debug,
             @t_file     = @t_file,
             @t_from     = @w_sp_name,
             @i_num      = 1720017
       return 1720017
    end
  
     
    select @w_conyuge = 0

    select @w_conyuge = in_ente_d 
    from  cobis..cl_instancia 
    where  in_ente_i = @i_ente

    if @@rowcount <> 0 begin 
    
       select @w_conyuge = in_ente_i
       from  cobis..cl_instancia 
       where  in_ente_d = @i_ente
       
    end
    
    update cobis..cl_ente set 
    p_estado_civil= @w_estado_civil
    where en_ente = @w_conyuge
       
    if @@error <> 0 begin
         exec cobis..sp_cerror
            @t_debug= @t_debug,
            @t_file   = @t_file,
            @t_from   = @w_sp_name,
            --@i_msg    = @w_msg,
            @i_num    = 1720036
         return 1720036
    end
       
    if @w_estado_civil not in (select c.codigo 
                               from cobis..cl_catalogo c, 
                                    cobis..cl_tabla t
                               where t.codigo = c.tabla
                               and t.tabla = 'cl_ecivil_conyuge') 
    begin	
	
       select @w_relacion_ca = (select pa_tinyint from cobis..cl_parametro 
                             where pa_nemonico = 'CONY' and pa_producto='CLI')
                             
       if @w_conyuge is not null and @w_conyuge <> 0
        begin
          delete cobis..cl_instancia
          where  (in_ente_i   = @i_ente or in_ente_d = @i_ente)
          and  in_relacion = @w_relacion_ca
       
           if @@error <> 0 
		     begin
            exec cobis..sp_cerror
                   @t_debug= @t_debug,
                   @t_file   = @t_file,
                   @t_from   = @w_sp_name,
                   --@i_msg    = @w_msg,
                   @i_num    = 1720069
                return 1720069
          
             end
    
          -- transaccion de servicio
         insert into cobis..ts_instancia (
         secuencial,                             tipo_transaccion,                       clase,
         fecha,                                  usuario,                                terminal,
         srv,                                    lsrv,                                   relacion,
         izquierda,                              derecha,                                lado,                            
         fecha_relacion)
         values(
         @s_ssn,                                 172030,                                 'E',
         getdate(),                              @s_user,                                @s_term,
         @s_srv,                                 @s_lsrv,                                @w_relacion_ca,
         @i_ente,                                @w_conyuge,                             'I',
         getdate()   
         )
         if @@error <> 0
           begin
            exec cobis..sp_cerror
               @t_debug= @t_debug,
               @t_file   = @t_file,
               @t_from   = @w_sp_name,
               @i_num    = 1720415
            return 1720415
           end
        end
        
    end

  
 update cobis..cl_ente_aux
      set ea_ced_ruc                 = isnull(@i_identificationType, ea_ced_ruc),
          ea_conocido_como           = @i_ea_con_como
      where ea_ente = @i_ente
     
if @@error <> 0
   begin
        exec sp_cerror
             @t_debug    = @t_debug,
             @t_file     = @t_file,
             @t_from     = @w_sp_name,
             @i_num      = 1720063
        return 1720063
   end
 
 
  --TRANSACCION DE SERVICIO - DATOS PREVIOS-PRMERA PARTE
    insert into ts_persona_prin (secuencia,     tipo_transaccion,    clase,               fecha,                 usuario,
                            terminal,           srv,                 lsrv,                persona,               nombre,
                            p_apellido,         s_apellido,          sexo,                cedula,                /*pasaporte,*/
                            tipo_ced,           pais,                profesion,           estado_civil,          actividad,
                            num_cargas,         nivel_ing,           nivel_egr,           tipo,                  filial,
                            oficina,            /*casilla_def,*/     /*tipo_dp,*/         fecha_nac,             grupo,
                            oficial,            comentario,          retencion,           fecha_mod,             /*fecha_emision,*/
                            fecha_expira,       /*asosciada,*/       /*referido,*/        sector,                /*nit_per,*/
                            ciudad_nac,         /*lugar_doc,*/       nivel_estudio,       tipo_vivienda,         calif_cliente,
                            /*doc_validado,*/   /*rep_superban,*/    /*vinculacion,*/     tipo_vinculacion,      /*exc_sipla,*/
                            /*exc_por2,*/       /*digito,*/          s_nombre,            c_apellido , secuen_alterno/*,          departamento,
                            num_orden,          promotor,            nacionalidad,        cod_otro_pais,         inss,
                            licencia,           ingre,               id_tutor,            nombre_tutor,          categoria,
                            referidor_ecu,      carg_pub,            rel_carg_pub,        situacion_laboral,     bienes,
                            otros_ingresos,     origen_ingresos,     estado_ea,           observacion_aut,       contrato_firmado,
                            menor_edad,         conocido_como,       cliente_planilla,    cod_risk,              sector_eco,
                            actividad_ea,       empadronado,         lin_neg,             seg_neg,               val_id_check,
                            ejecutivo_con,      suc_gestion,         constitucion,        remp_legal,            apoderado_legal,
                            act_comp_kyc,       fecha_act_kyc,       no_req_kyc_comp,     act_perfiltran,        fecha_act_perfiltran,
                            con_salario,        fecha_consal,        sin_salario,         fecha_sinsal,          actualizacion_cic,
                            fecha_act_cic,      fuente_ing,          act_prin,            detalle,               act_dol,
                            cat_aml,            discapacidad,        tipo_discapacidad,   ced_discapacidad,      nivel_egresos,
                            ifi,                asfi,                path_foto,           nit,                   nit_vencimiento*/,hora)

                    values (@s_ssn,                    @t_trn,                    'P',                         @s_date,                     @s_user,
                            @s_term,                   @s_srv,                    @s_lsrv,                     @i_ente,                  @w_nombre,
                            @w_p_p_apellido,           @w_p_s_apellido,             @w_sexo,                     @w_curp,                   /*@w_pasaporte,*/
                            @w_tipo_ced,               @w_pais,                   @w_profesion,                @w_estado_civil,             @w_actividad,
                            @w_num_cargas,             @w_nivel_ing,              @w_nivel_egr,                @w_tipo,                     @w_filial,
                            @s_ofi,                /*null,*/                  /* null,*/                   @w_fecha_nac,                @w_grupo,
                            @w_oficial,                @w_comentario,             @w_retencion,                getdate(),                   /*@w_fecha_emision,*/
                            @w_fecha_expira,           /*@w_asosciada,*/          /*@w_referido,*/             @w_sector,                   /*@w_nit,*/
                            @w_ciudad_nac,             /*@w_lugar_doc,*/          @w_nivel_estudio,            @w_tipo_vivienda,            @w_calif_cliente,
                            /*@w_doc_validado,*/       /*@w_rep_superban,*/       /*@w_vinculacion,*/          @w_tipo_vinculacion,         /*@w_exc_sipla,*/
                            /*@w_exc_por2,*/           /*@w_digito,*/             @w_s_nombre,                 @w_c_apellido,                     1/*,             @w_depart_doc,
                            @w_numord,                 @w_promotor,               @w_num_pais_nacionalidad,    @w_cod_otro_pais,            @w_inss,
                            @w_licencia,               @w_ingre,                  @w_en_id_tutor,              @w_en_nom_tutor,             @w_categoria,
                            @i_referidor_ecu,          @i_carg_pub,               @i_rel_carg_pub,             @w_situacion_laboral,        @w_bienes,
                            @w_otros_ingresos,         @w_origen_ingresos,        @w_ea_estado,                @w_ea_observacion_aut,       @w_ea_contrato_firmado,
                            @w_ea_menor_edad,          @w_ea_conocido_como,       @w_ea_cliente_planilla,      @w_ea_cod_risk,              @w_ea_sector_eco,
                            @w_ea_actividad,           @w_ea_empadronado,         @w_ea_lin_neg,               @w_ea_seg_neg,               @w_ea_val_id_check,
                            @w_ea_ejecutivo_con,       @w_ea_suc_gestion,         @w_ea_constitucion,          @w_ea_remp_legal,            @w_ea_apoderado_legal,
                            @w_ea_act_comp_kyc,        @w_ea_fecha_act_kyc,       @w_ea_no_req_kyc_comp,       @w_ea_act_perfiltran,        @w_ea_fecha_act_perfiltran,
                            @w_ea_con_salario,         @w_ea_fecha_consal,        @w_ea_sin_salario,           @w_ea_fecha_sinsal,          @w_ea_actualizacion_cic,
                            @w_ea_fecha_act_cic,       @w_ea_fuente_ing,          @w_ea_act_prin,              @w_ea_detalle,               @w_ea_act_dol,
                            @w_ea_cat_aml,             @w_ea_discapacidad,        @w_ea_tipo_discapacidad,     @w_ea_ced_discapacidad,      @w_egresos,
                            @w_ifi,                    @w_asfi,                   @w_path_foto,                @w_nit_id,                   @w_nit_venc*/, getdate())

   if @@error <> 0
      begin
         exec sp_cerror
            @t_debug    = @t_debug,
            @t_file     = @t_file,
            @t_from     = @w_sp_name,
            @i_num      = 1720049
      return 1720049
         --ERROR EN CREACION DE TRANSACCION DE SERVICIO

      end

    --TRANSACCION DE SERVICIO - DATOS PREVIOS-SEGUNDA PARTE
    insert into ts_persona_sec (secuencia,      tipo_transaccion,    clase,               fecha,                 usuario,
                            terminal,           srv,                 lsrv,                persona,               nombre,
                            p_apellido,         s_apellido,          /*sexo,              cedula,                pasaporte,
                            tipo_ced,           pais,                profesion,           estado_civil,          actividad,
                            num_cargas,         nivel_ing,           nivel_egr,           tipo,                  filial,
                            oficina,            casilla_def,         tipo_dp,             fecha_nac,             grupo,
                            oficial,            comentario,          retencion,           fecha_mod,             fecha_emision,
                            fecha_expira,       asosciada,           referido,            sector,                nit_per,
                            ciudad_nac,         lugar_doc,           nivel_estudio,       tipo_vivienda,         calif_cliente,
                            doc_validado,       rep_superban,        vinculacion,         tipo_vinculacion,      exc_sipla,
                            exc_por2,           digito,              s_nombre,            c_apellido,            departamento,
                            num_orden,          promotor,            nacionalidad,        cod_otro_pais,         inss,
                            licencia,*/         ingre,             id_tutor,            nombre_tutor,          /*categoria,*/
                            /*referidor_ecu,    carg_pub,            rel_carg_pub,        situacion_laboral,*/   bienes,
                            /*otros_ingresos,   origen_ingresos,*/   estado_ea,           /*observacion_aut,*/   /*contrato_firmado,*/
                            menor_edad,         conocido_como,       cliente_planilla,    cod_risk,              sector_eco,
                            actividad_ea,       /*empadronado,*/     lin_neg,             seg_neg,               /*val_id_check,*/
                            /*ejecutivo_con,    suc_gestion,         constitucion,*/      remp_legal,            apoderado_legal,
                            /*act_comp_kyc,     fecha_act_kyc,       no_req_kyc_comp,     act_perfiltran,        fecha_act_perfiltran,*/
                            /*con_salario,      fecha_consal,        sin_salario,         fecha_sinsal,          actualizacion_cic,
                            fecha_act_cic,*/    fuente_ing,          act_prin,            detalle,               /*act_dol,*/
                            cat_aml,            discapacidad,        tipo_discapacidad,   ced_discapacidad,      nivel_egresos,
                            ifi,                asfi,                /*path_foto,*/       nit,                   nit_vencimiento, secuen_alterno2, oficina, hora)

                    values (@s_ssn,                    @t_trn,                    'P',                         @s_date,                     @s_user,
                            @s_term,                   @s_srv,                    @s_lsrv,                     @i_ente,                  @w_nombre,
                            @w_p_apellido,             @w_s_apellido,             /*@w_sexo,                   @w_cedula,                   @w_pasaporte,
                            @w_tipo_ced,               @w_pais,                   @w_profesion,                @w_estado_civil,             @w_actividad,
                            @w_num_cargas,             @w_nivel_ing,              @w_nivel_egr,                @w_tipo,                     @w_filial,
                            @s_ofi,                    null,                      null,                        @w_fecha_nac,                @w_grupo,
                            @w_oficial,                @w_comentario,             @w_retencion,                getdate(),                   @w_fecha_emision,
                            @w_fecha_expira,           @w_asosciada,              @w_referido,                 @w_sector,                   @w_nit,
                            @w_ciudad_nac,             @w_lugar_doc,              @w_nivel_estudio,            @w_tipo_vivienda,            @w_calif_cliente,
                            @w_doc_validado,           @w_rep_superban,           @w_vinculacion,              @w_tipo_vinculacion,         @w_exc_sipla,
                            @w_exc_por2,               @w_digito,                 @w_s_nombre,                 @w_c_apellido,               @w_depart_doc,
                            @w_numord,                 @w_promotor,               @w_num_pais_nacionalidad,    @w_cod_otro_pais,            @w_inss,
                            @w_licencia,*/             @w_ingre,                  @w_en_id_tutor,              @w_en_nom_tutor,             /*@w_categoria,*/
                            /*@i_referidor_ecu,*/      /*@i_carg_pub,*/           /*@i_rel_carg_pub,*/         /*@w_situacion_laboral,*/    @w_bienes,
                            /*@w_otros_ingresos,*/     /*@w_origen_ingresos,*/    @w_ea_estado,                /*@w_ea_observacion_aut,*/   /*@w_ea_contrato_firmado,*/
                            @w_ea_menor_edad,          @i_ea_con_como,            @w_ea_cliente_planilla,      @w_ea_cod_risk,              @w_ea_sector_eco,
                            @w_ea_actividad,           /*@w_ea_empadronado,*/     @w_ea_lin_neg,               @w_ea_seg_neg,               /*@w_ea_val_id_check,*/
                            /*@w_ea_ejecutivo_con,*/   /*@w_ea_suc_gestion,*/     /*@w_ea_constitucion,*/      @w_ea_remp_legal,            @w_ea_apoderado_legal,
                            /*@w_ea_act_comp_kyc,*/    /*@w_ea_fecha_act_kyc,*/   /*@w_ea_no_req_kyc_comp,*/   /*@w_ea_act_perfiltran,*/    /*@w_ea_fecha_act_perfiltran,*/
                            /*@w_ea_con_salario,*/     /*@w_ea_fecha_consal,*/    /*@w_ea_sin_salario,*/       /*@w_ea_fecha_sinsal,*/      /*@w_ea_actualizacion_cic,*/
                            /*@w_ea_fecha_act_cic,*/   @w_ea_fuente_ing,          @w_ea_act_prin,              @w_ea_detalle,               /*@w_ea_act_dol,*/
                            @w_ea_cat_aml,             @w_ea_discapacidad,        @w_ea_tipo_discapacidad,     @w_ea_ced_discapacidad,      @w_egresos,
                            @w_ifi,                    @w_asfi,                   /*@w_path_foto,*/            @w_nit_id,                   @w_nit_venc,2, @s_ofi, getdate())


   if @@error <> 0
   begin
 exec sp_cerror
   @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_num      = 1720049
  return 1720049
       /*'Error en creacion de transaccion de servicio'*/

   end

    --TRANSACCION DE SERVICIO - DATOS ACTUALES-PRIMERA PARTE
  
  insert into ts_persona_prin (secuencia,     tipo_transaccion,    clase,               fecha,                 usuario,
                            terminal,           srv,                 lsrv,                persona,               nombre,
                            p_apellido,         s_apellido,          sexo,                cedula,                /*pasaporte,*/
                            tipo_ced,           pais,                profesion,           estado_civil,          actividad,
                            num_cargas,         nivel_ing,           nivel_egr,           tipo,                  filial,
                            oficina,            /*casilla_def,*/     /*tipo_dp,*/         fecha_nac,             grupo,
                            oficial,            comentario,          retencion,           fecha_mod,             /*fecha_emision,*/
                            fecha_expira,       /*asosciada,*/       /*referido,*/        sector,                /*nit_per,*/
                            ciudad_nac,         /*lugar_doc,*/       nivel_estudio,       tipo_vivienda,         calif_cliente,
                            /*doc_validado,*/   /*rep_superban,*/    /*vinculacion,*/     tipo_vinculacion,      /*exc_sipla,*/
                            /*exc_por2,*/       /*digito,*/          s_nombre,            c_apellido , secuen_alterno/*,          departamento,
                            num_orden,          promotor,            nacionalidad,        cod_otro_pais,         inss,
                            licencia,           ingre,               id_tutor,            nombre_tutor,          categoria,
                            referidor_ecu,      carg_pub,            rel_carg_pub,        situacion_laboral,     bienes,
                            otros_ingresos,     origen_ingresos,     estado_ea,           observacion_aut,       contrato_firmado,
                            menor_edad,         conocido_como,       cliente_planilla,    cod_risk,              sector_eco,
                            actividad_ea,       empadronado,         lin_neg,             seg_neg,               val_id_check,
                            ejecutivo_con,      suc_gestion,         constitucion,        remp_legal,            apoderado_legal,
                            act_comp_kyc,       fecha_act_kyc,       no_req_kyc_comp,     act_perfiltran,        fecha_act_perfiltran,
                            con_salario,        fecha_consal,        sin_salario,         fecha_sinsal,          actualizacion_cic,
                            fecha_act_cic,      fuente_ing,          act_prin,            detalle,               act_dol,
                            cat_aml,            discapacidad,        tipo_discapacidad,   ced_discapacidad,      nivel_egresos,
                            ifi,                asfi,                path_foto,           nit,                   nit_vencimiento*/,hora)
                    values (@s_ssn,                    @t_trn,                    'P',                         @s_date,                     @s_user,
                            @s_term,                   @s_srv,                    @s_lsrv,                     @i_ente,                  @i_nombre,
                            @i_p_p_apellido,           @i_p_s_apellido,           @i_sexo,                     @i_curp,                   /*@w_pasaporte,*/
                            @w_tipo_ced,               @w_pais,                   @w_profesion,                @w_estado_civil,             @w_actividad,
                            @w_num_cargas,             @w_nivel_ing,              @w_nivel_egr,                @w_tipo,                     @w_filial,
                            @s_ofi,                    /*null,*/                  /* null,*/                   @i_fecha_nac,                @w_grupo,
                            @w_oficial,                @w_comentario,             @w_retencion,                getdate(),                   /*@w_fecha_emision,*/
                            @w_fecha_expira,           /*@w_asosciada,*/          /*@w_referido,*/             @w_sector,                   /*@w_nit,*/
                            @w_ciudad_nac,             /*@w_lugar_doc,*/          @w_nivel_estudio,            @w_tipo_vivienda,            @w_calif_cliente,
                           /*@w_doc_validado,*/       /*@w_rep_superban,*/       /*@w_vinculacion,*/          @w_tipo_vinculacion,         /*@w_exc_sipla,*/
                            /*@w_exc_por2,*/           /*@w_digito,*/             @i_segnombre,                 @w_c_apellido,                     1/*,             @w_depart_doc,
                            @w_numord,                 @w_promotor,               @w_num_pais_nacionalidad,    @w_cod_otro_pais,            @w_inss,
                            @w_licencia,               @w_ingre,                  @w_en_id_tutor,              @w_en_nom_tutor,             @w_categoria,
                            @i_referidor_ecu,          @i_carg_pub,               @i_rel_carg_pub,             @w_situacion_laboral,        @w_bienes,
                            @w_otros_ingresos,         @w_origen_ingresos,        @w_ea_estado,                @w_ea_observacion_aut,       @w_ea_contrato_firmado,
                            @w_ea_menor_edad,          @w_ea_conocido_como,       @w_ea_cliente_planilla,      @w_ea_cod_risk,              @w_ea_sector_eco,
                            @w_ea_actividad,           @w_ea_empadronado,         @w_ea_lin_neg,               @w_ea_seg_neg,               @w_ea_val_id_check,
                            @w_ea_ejecutivo_con,       @w_ea_suc_gestion,         @w_ea_constitucion,          @w_ea_remp_legal,            @w_ea_apoderado_legal,
                            @w_ea_act_comp_kyc,        @w_ea_fecha_act_kyc,       @w_ea_no_req_kyc_comp,       @w_ea_act_perfiltran,        @w_ea_fecha_act_perfiltran,
                            @w_ea_con_salario,         @w_ea_fecha_consal,        @w_ea_sin_salario,           @w_ea_fecha_sinsal,          @w_ea_actualizacion_cic,
                            @w_ea_fecha_act_cic,       @w_ea_fuente_ing,          @w_ea_act_prin,              @w_ea_detalle,               @w_ea_act_dol,
                            @w_ea_cat_aml,             @w_ea_discapacidad,        @w_ea_tipo_discapacidad,     @w_ea_ced_discapacidad,      @w_egresos,
                            @w_ifi,                    @w_asfi,                   @w_path_foto,                @w_nit_id,                   @w_nit_venc*/, getdate())

    
   if @@error <> 0
   begin
 exec sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
 @t_from     = @w_sp_name,
    @i_num      = 1720049
 return 1720049
   end


   --TRANSACCION DE SERVICIO - DATOS ACTUALES-SEGUNDA PARTE
   
 insert into ts_persona_sec (secuencia,      tipo_transaccion,    clase,               fecha,                 usuario,
                            terminal,           srv,                 lsrv,                persona,               nombre,
                            p_apellido,         s_apellido,          /*sexo,              cedula,                pasaporte,
                            tipo_ced,           pais,                profesion,           estado_civil,          actividad,
                            num_cargas,         nivel_ing,           nivel_egr,           tipo,                  filial,
                            oficina,            casilla_def,         tipo_dp,             fecha_nac,             grupo,
                            oficial,            comentario,          retencion,           fecha_mod,             fecha_emision,
                            fecha_expira,       asosciada,           referido,            sector,                nit_per,
                            ciudad_nac,         lugar_doc,           nivel_estudio,       tipo_vivienda,         calif_cliente,
                            doc_validado,       rep_superban,        vinculacion,         tipo_vinculacion,      exc_sipla,
                            exc_por2,           digito,              s_nombre,            c_apellido,            departamento,
                            num_orden,          promotor,            nacionalidad,        cod_otro_pais,         inss,
                            licencia,*/         ingre,             id_tutor,            nombre_tutor,          /*categoria,*/
                            /*referidor_ecu,    carg_pub,            rel_carg_pub,        situacion_laboral,*/   bienes,
                            /*otros_ingresos,   origen_ingresos,*/   estado_ea,           /*observacion_aut,*/   /*contrato_firmado,*/
                            menor_edad,         conocido_como,       cliente_planilla,    cod_risk,              sector_eco,
                            actividad_ea,       /*empadronado,*/     lin_neg,             seg_neg,               /*val_id_check,*/
                            /*ejecutivo_con,    suc_gestion,         constitucion,*/      remp_legal,            apoderado_legal,
                            /*act_comp_kyc,     fecha_act_kyc,       no_req_kyc_comp,     act_perfiltran,        fecha_act_perfiltran,*/
                            /*con_salario,      fecha_consal,        sin_salario,         fecha_sinsal,          actualizacion_cic,
                            fecha_act_cic,*/    fuente_ing,          act_prin,            detalle,               /*act_dol,*/
                            cat_aml,            discapacidad,        tipo_discapacidad,   ced_discapacidad,      nivel_egresos,
                            ifi,                asfi,                /*path_foto,*/       nit,                   nit_vencimiento, secuen_alterno2, oficina, hora)

                    values (@s_ssn,                    @t_trn,                   'P',                          @s_date,                     @s_user,
                            @s_term,                   @s_srv,                    @s_lsrv,                     @i_ente,                  @i_nombre,
                            @i_p_p_apellido,           @i_p_s_apellido,           /*@w_sexo,                   @w_cedula,                   @w_pasaporte,
                            @w_tipo_ced,               @w_pais,                   @w_profesion,                @w_estado_civil,             @w_actividad,
                            @w_num_cargas,             @w_nivel_ing,              @w_nivel_egr,                @w_tipo,                     @w_filial,
                            @s_ofi,                    null,                      null,                        @w_fecha_nac,                @w_grupo,
                            @w_oficial,                @w_comentario,             @w_retencion,                getdate(),                   @w_fecha_emision,
                            @w_fecha_expira,           @w_asosciada,              @w_referido,                 @w_sector,                   @w_nit,
                            @w_ciudad_nac,             @w_lugar_doc,              @w_nivel_estudio,            @w_tipo_vivienda,            @w_calif_cliente,
                            @w_doc_validado,           @w_rep_superban,           @w_vinculacion,              @w_tipo_vinculacion,         @w_exc_sipla,
                            @w_exc_por2,               @w_digito,                 @w_s_nombre,                 @w_c_apellido,               @w_depart_doc,
                            @w_numord,                 @w_promotor,               @w_num_pais_nacionalidad,    @w_cod_otro_pais,            @w_inss,
                            @w_licencia,*/             @w_ingre,                  @w_en_id_tutor,              @w_en_nom_tutor,             /*@w_categoria,*/
                            /*@i_referidor_ecu,*/      /*@i_carg_pub,*/           /*@i_rel_carg_pub,*/         /*@w_situacion_laboral,*/    @w_bienes,
                            /*@w_otros_ingresos,*/     /*@w_origen_ingresos,*/    @w_ea_estado,                /*@w_ea_observacion_aut,*/   /*@w_ea_contrato_firmado,*/
                            @w_ea_menor_edad,          @w_ea_conocido_como,       @w_ea_cliente_planilla,      @w_ea_cod_risk,              @w_ea_sector_eco,
                            @w_ea_actividad,           /*@w_ea_empadronado,*/     @w_ea_lin_neg,               @w_ea_seg_neg,               /*@w_ea_val_id_check,*/
                            /*@w_ea_ejecutivo_con,*/   /*@w_ea_suc_gestion,*/     /*@w_ea_constitucion,*/      @w_ea_remp_legal,            @w_ea_apoderado_legal,
                            /*@w_ea_act_comp_kyc,*/    /*@w_ea_fecha_act_kyc,*/   /*@w_ea_no_req_kyc_comp,*/   /*@w_ea_act_perfiltran,*/    /*@w_ea_fecha_act_perfiltran,*/
                            /*@w_ea_con_salario,*/     /*@w_ea_fecha_consal,*/    /*@w_ea_sin_salario,*/       /*@w_ea_fecha_sinsal,*/      /*@w_ea_actualizacion_cic,*/
                            /*@w_ea_fecha_act_cic,*/   @w_ea_fuente_ing,          @w_ea_act_prin,              @w_ea_detalle,               /*@w_ea_act_dol,*/
                            @w_ea_cat_aml,             @w_ea_discapacidad,        @w_ea_tipo_discapacidad,     @w_ea_ced_discapacidad,      @w_egresos,
                            @w_ifi,                    @w_asfi,                   /*@w_path_foto,*/            @i_rfc,                   @w_nit_venc,2, @s_ofi, getdate())

 
  if @@error <> 0
begin
 exec sp_cerror  @t_debug    = @t_debug,
     @t_file     = @t_file,
     @t_from     = @w_sp_name,
     @i_num      = 1720049
 return 1
end
    
exec @w_return = cobis..sp_ente_upd
        @s_user           = @s_user,
        @i_operacion      = 'U',
        @i_ente           = @i_ente
  if @w_return <> 0
  begin
     return 1
  end

set @o_identificationType = @i_identificationType
set @o_identificationNumber = @i_identificationNumber

commit tran

select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Clientes

if @i_ente is not null  and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
begin
   exec @w_error = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @i_ente,
      @t_debug      = @t_debug
   if @w_error <> 0 and @w_error is not null
   begin 
     exec cobis..sp_cerror 
       @t_debug = @t_debug, 
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = @w_error
     return @w_error
   end
end
return 0  

go
