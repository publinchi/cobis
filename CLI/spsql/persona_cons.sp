/********************************************************************/
/*    NOMBRE LOGICO: sp_persona_cons                                */
/*    NOMBRE FISICO: persona_cons.sp                                */
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
/* Este programa permite consultar toda la información de cl_ente   */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*FECHA           AUTOR           RAZON                             */
/*30/04/19         JMEG         Emision Inicial                     */
/*24/06/19         RIGG         Ajustar subconsulta parámetros CRE  */
/*14/05/20         DGA          Ajustar numero caracteres cargopub  */
/*16/06/20         MBA          Estandarizacion sp y seguridades    */
/*26/06/20         FSAP         Estandarizacion clientes            */
/*24/11/20         EGL          Agregando variables para genero     */
/*09/12/20         IYU          Eliminar trn 172111 para busq.      */
/*                              de conyugue                         */
/*16/12/20         IYU          Agregar nuevos campos conyugue      */
/*22/12/20         IYU          Orden de relaciones conyugue        */
/*12/06/21         COB          Actualizacion Tipos Identificacion  */
/*31/06/21         COB          Agregar nuevos campos PEP           */
/*17/01/23         BDU          S762873: Se agregan nuevos campos   */
/*23/03/23         EBA          Cambios para APP asesores.          */
/*28/03/23         BDU          Agregar pseudonimo a consulta       */
/*05/04/23         EBA          Nueva opreacion consulta clientes   */
/*21/06/23         EBA          S849151 Validación para solicitudes */
/*11/12/2024       GRO          R248888:campos conozca su cliente   */
/*25/03/2025       BDU          R248888:Campo lugar de trabajo APP  */
/********************************************************************/


use cobis
go

SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER OFF
go

if exists (select 1 from sysobjects where name = 'sp_persona_cons')
   drop proc sp_persona_cons
go

create procedure sp_persona_cons (
   @s_ssn                  int             = null,
   @s_user                 login           = null,
   @s_term                 varchar(32)     = null,
   @s_date                 datetime        = null,
   @s_srv                  varchar(30)     = null,
   @s_lsrv                 varchar(30)     = null,
   @s_ofi                  smallint        = null,
   @s_rol                  smallint        = null,
   @s_org_err              char(1)         = null,
   @s_error                int             = null,
   @s_sev                  tinyint         = null,
   @s_msg                  descripcion     = null,
   @s_org                  char(1)         = null,
   @s_culture              varchar(10)     = 'NEUTRAL',
   @t_debug                char(1)         = 'N',
   @t_file                 varchar(10)     = null,
   @t_from                 varchar(32)     = null,
   @t_trn                  int             = null,
   @i_operacion            char(1),
   @i_persona              int             = null,
   @i_tipo                 char(1)         = null,
   @i_nit                  numero          = null,
   @i_formato_fecha        int             = null,
   @i_is_app               char(1)         = 'N',
   @i_identificacion       varchar(20)     = null,
   @t_show_version         bit             = 0,
   @o_nit                  varchar(20)     = null out,
   @o_retencion            char(1)         = null out,
   @o_sub_tipo             char(1)         = null out,
   @o_pjuridica            char(10)        = null out,
   @o_ced_ruc              char(25)        = null out,
   @i_modo                 int             = NULL,
   @s_sesn                 int             = null
)
as
declare
   @w_today                        datetime,
   @w_sp_name                      varchar(32),
   @w_sp_msg                       varchar(132),
   @w_return                       int,
   @w_dias_anio_nac                smallint,
   @w_dias_anio_act                smallint,
   @w_inic_anio_nac                datetime,
   @w_inic_anio_act                datetime,
   @w_anio_nac                     char(4),
   @w_anio_act                     char(4),
   @w_siguiente                    int,
   @w_codigo                       int,
   @w_nombre                       varchar(64),
   @w_p_apellido                   varchar(30),
   @w_s_apellido                   varchar(30),
   @w_sexo                         descripcion,
   @w_genero                       descripcion,
   @w_tipo_ced                     char(4),
   @w_cedula                       numero,
   @w_pasaporte                    varchar(20),
   @w_pais                         smallint,
   @w_des_pais                     descripcion,
   @w_ocupacion                    catalogo,
   @w_des_ocupacion                descripcion,
   @w_estado_civil                 catalogo,
   @w_des_estado_civil             descripcion,
   @w_num_cargas                   tinyint,
   @w_num_hijos                    tinyint,
   @w_nivel_ing                    money,
   @w_nivel_egr                    money,
   @w_filial                       int,
   @w_oficina                      smallint,
   @w_oficina_origen               smallint,
   @w_des_oficina                  descripcion,
   @w_tipo                         catalogo,
   @w_des_tipo                     descripcion,
   @w_nivel_estudio                catalogo,
   @w_des_niv_est                  descripcion,
   @w_tipo_vivienda                catalogo,
   @w_des_tipo_vivienda            descripcion,
   @w_calif_cliente                catalogo,
   @w_des_calif_cliente            descripcion,
   @w_grupo                        int,
   @w_des_grupo                    descripcion,
   @w_fecha_nac                    datetime,
   @w_fechanac                     varchar(10),
   @w_fechareg                     varchar(10),
   @w_fechamod                     varchar(10),
   @w_fechaing                     varchar(10),
   @w_cod_sex                      sexo,
   @w_cod_gender                   char(2),
   @w_fechaexp                     varchar(10),
   @w_ciudad_nac                   int,
   @w_lugar_doc                    int,
   @w_doc_validado                 char(1),
   @w_rep_superban                 char(1),
   @w_des_lugar_doc                descripcion,
   @w_des_ciudad_nac               descripcion,
   @w_es_mayor_edad                char(1),            /* 'S' o 'N' */
   @w_tipoced                      char(4),
   @w_mayoria_edad                 smallint,           /* expresada en años */
   @w_oficial                      smallint,
   @w_des_oficial                  descripcion,
   @w_des_referido                 descripcion,
   @w_retencion                    char(1),
   @w_exc_sipla                    char(1),
   @w_exc_por2                     char(1),
   @w_asosciada                    catalogo,
   @w_tipo_vinculacion             catalogo,
   @w_des_tipo_vinculacion         descripcion,
   @w_mala_referencia              char(1),
   @w_actividad                    catalogo,
   @w_des_actividad                descripcion,
   @w_comentario                   varchar(254),
   @w_nit                          numero,
   @w_referido                     smallint,
   @w_cod_sector                   catalogo,
   @w_des_sector                   descripcion,
   @w_gran_contribuyente           char(1),
   @w_situacion_cliente            catalogo,
   @w_des_situacion_cliente        varchar(50),
   @w_patrim_tec                   money,
   @w_fecha_patrim_bruto           varchar(10),
   @w_total_activos                money,
   @w_catalogo                     catalogo,
   @w_nom_temp                     descripcion,
   @w_oficial_sup                  smallint,
   @w_des_oficial_sup              descripcion,
   @w_preferen                     char(1),
   @w_cem                          money,
   @w_direccion                    int,
   @w_c_apellido                   varchar(30) ,  --Campo apellido casada
   @w_segnombre                    varchar(50) ,  --Campo segundo nombre
   @w_depart_doc                   smallint    ,  --Codigo del departamento
   @w_numord                       char(4)     ,  --Codigo de orden CV
   @w_des_dep_doc                  varchar(20) ,
   @w_des_ciudad                   varchar(20),
   @w_promotor                     varchar(10),
   @w_des_promotor                 varchar(64),
   @w_num_pais_nacionalidad        int,     -- Codigo del pais de la nacionalidad del cliente
   @w_des_nacionalidad             descripcion,
   @w_cod_otro_pais                char(10),      -- Codigo del pais centroamericano
   @w_inss                         varchar(20),   -- Numero de seguro
   @w_licencia                     varchar(30),   -- Numero de licencia
   @w_ingre                        varchar(10),   -- Ingresos
   @w_des_ingresos                 varchar(60),
   @w_principal_login              login,       -- login del oficial principal
   @w_suplente_login               login,         -- login del oficial suplente
   @w_en_id_tutor                  varchar(20),   -- ID del tutor
   @w_en_nom_tutor                 varchar(60),   -- Nombre del Tutor
   @w_bloquear                     char(1),        -- Cliente bloqueado
   @w_relacion                     catalogo,
   @w_digito                       char(2),
   @w_desc_tipo_ced                descripcion,
   @w_canal_bv                     tinyint,
   @w_tipo_medio                   varchar(6),
   @w_desc_tipo_medio              varchar(64),
   @w_categoria                    catalogo,   --I.CVA Abr-23-07
   @w_categoria_cli                varchar(255),
   @w_descripcion_cobis            varchar(64),
   @w_desc_categoria               varchar(64), --I.CVA Abr-23-07
   @w_es_cliente                   char, --AVI vista consolidada
   @w_referido_ext                 int,             -- REQ CL00012
   @w_des_referido_ext             descripcion,     -- REQ CL00012
   @w_referidor_ecu                int,
   @w_rel_carg_pub                 varchar(10),
   @w_vu_pais                      catalogo,
   @w_vu_banco                     catalogo,
   @w_situacion_laboral            varchar(5),      -- ini CL00031 RVI
   @w_des_situacion_laboral        descripcion,
   @w_bienes                       char(1),
   @w_otros_ingresos               money,
   @w_origen_ingresos              descripcion,     -- fin CL00031 RVI
   @o_ea_estado                    catalogo,
   @w_ea_estado_desc               descripcion,
   @o_ea_observacion_aut           varchar(255 ),
   @o_ea_contrato_firmado          char(1),
   @o_ea_menor_edad                char(1),
   @o_ea_conocido_como             varchar(255 ),
   @o_ea_cliente_planilla          char(1),
   @o_ea_cod_risk                  varchar(20),
   @o_ea_sector_eco                catalogo,
   @o_ea_actividad                 catalogo,
   @o_ea_empadronado               char(1),
   @o_ea_lin_neg                   catalogo,
   @o_ea_seg_neg                   catalogo,
   @o_ea_val_id_check              catalogo,
   @o_ea_ejecutivo_con             int,
   @o_ea_suc_gestion               smallint,
   @o_ea_constitucion              smallint,
   @o_ea_emp_planilla              char(1),
   @o_ea_remp_legal                int,
   @o_ea_apoderado_legal           int,
   @o_ea_act_comp_kyc              char(1),
   @o_ea_fecha_act_kyc             varchar(10),
   @o_ea_no_req_kyc_comp           char(1),
   @o_ea_act_perfiltran            char(1),
   @o_ea_fecha_act_perfiltran      varchar(10),
   @o_ea_con_salario               char(1),
   @o_ea_fecha_consal              varchar(10),
   @o_ea_sin_salario               char(1),
   @o_ea_fecha_sinsal              varchar(10),
   @o_ea_actualizacion_cic         char(1),
   @o_ea_fecha_act_cic             varchar(10),
   @o_ea_excepcion_cic             char(1),
   @o_ea_excepcion_pad             char(1),
   @o_ea_fuente_ing                catalogo,
   @o_ea_act_prin                  catalogo,
   @o_ea_detalle                   varchar(255),
   @o_ea_act_dol                   money,
   @o_ea_cat_aml                   catalogo,
   @w_ea_desc_aml                  descripcion,
   @o_ea_observacion_vincula       varchar(255),
   @o_ea_fecha_vincula             varchar(10),
   @o_arma_categoria               varchar(255),
   @o_c_funcionario                varchar(50),
   @o_c_verificado                 char(1),
   @w_moneda_dolar                 tinyint,
   @w_cotizacion                   float,
   @w_sueldo1                      money,
   @w_sueldo2                      money,
   @w_sueldo_dolar                 money,
   @o_fuente_ing                   varchar(255),
   @o_actividad_princ              varchar(255),
   @w_ultima_fecha                 datetime,
   @o_fecha_veri                   varchar(10),
   @o_act_cic                      char(1),
   @o_excep_cic                    char(1),
   @w_discapacidad                 char(1),
   @w_tipo_discapacidad            catalogo,
   @w_desc_discapacidad            descripcion,
   @w_ced_discapacidad             varchar(30),
   @w_asfi                         char(1),
   @w_egresos                      catalogo,
   @w_desc_egresos                 descripcion,
   @w_ifi                          char(1),
   @w_nacio_tipo_ced               varchar(15),
   @w_path_foto                    varchar(50),
   @w_nit_id                       numero,
   @w_nit_venc                     varchar(10),
   @w_calif_cli                    catalogo,
   @w_descalif_cli                 descripcion,
   @w_conyuge                      varchar(64),
   @w_emproblemado                 char(1),
   @w_dinero_transac               money,
   @w_pep                          char(1),
   @w_mnt_pasivo                   money,
   @w_vinculacion                  char(1),
   @w_ant_nego                     int,
   @w_ventas                       money,
   @w_ot_ingresos                  money,
   @w_ct_ventas                    money,
   @w_ct_operativos                money,
   @w_ea_nro_ciclo_oi              money, --LPO Santander
   @w_ing_SN                       char(1),
   @w_otringr                      VARCHAR(10),
   @w_depa_nac                     SMALLINT,
   @w_nac_aux                      INT,
   @w_pais_emi                     SMALLINT,
   @w_num_ciclos                   INT,
   @w_ea_cta_banco                 VARCHAR(45),
      --MTA
   @w_cod_relacion                 int,
   @w_cod_conyugue                 INT,
   ---Nuevos campos para validaciones PXSG--
   @w_fecha_mod_cli                DATETIME,
   @w_fecha_proceso                DATETIME,
   @w_meses_vigentes               INT,
   @w_parametro_cli                INT,
   @w_vigencia                     INT,
   ---Nuevos campos para envio de mail al oficial PXSG--
   @w_cliente                      INT,
   @w_nombre_cli                   VARCHAR(50),
   @w_apellido                     VARCHAR(50),
   @w_mail_oficial                 varchar(30),
   @w_email_body                   varchar(1000),
   @w_banco                        varchar(20),
   @w_estado_std                   varchar(50),
   @w_risk_level                   varchar(20),
   @w_credit_bureau                varchar(20),
   @w_num_ciclos_en                int,
   @w_partner                      char(1),
   @w_lista_negra                  char(1),
   @w_tecnologico                  char(10),
   @w_id_grupo                     int,
   @w_nombre_grupo                 varchar(64)  ,
   @w_oficial_ente                 INT,
   @w_tmail                        VARCHAR(10),
   @w_edad_max                     smallint,
   @w_telefono_recados             varchar(10),
   @w_numero_ife                   varchar(13),
   @w_numero_serie_firma_elect     varchar(20),
   @w_persona_recados              varchar(60),
   @w_antecedentes_buro            varchar(2),
   @w_telef_referencia_uno         varchar(10),
   @w_telef_referencia_dos         varchar(10),
   @w_num_referencia               int,
   @w_existe_alerta                CHAR(1),
   -------nuevos valores para consulta--------
   @w_pais_nac                     varchar(10),
   @w_provincia_nac                int,
   @w_naturalizado                 CHAR(1),
   @w_forma_migratoria             varchar(64),
   @w_nro_extranjero               varchar(64),
   @w_calle_orig                   varchar(70),
   @w_exterior_orig                varchar(40),
   @w_estado_orig                  varchar(40),
   -----
   @w_email_c                      varchar(50),
   @w_con_como_c                   varchar(255),
   @w_telef_recados_c              varchar(20),
   --
   @w_ident_tipo_c                 varchar(10),
   @w_ident_num_c                  varchar(30),

   @w_tipo_iden                     varchar(13),
   @w_numero_iden                   varchar(20),
   @w_act_cny                       varchar(30),
   @w_tipo_doc_cny                  varchar(30),
   @w_act_desc_cny                  varchar(50),
   @w_ing_men_cny                   money,
   @w_act_economica                 varchar(10),
   @w_donde_labora                  varchar(200),
   @w_ingresos_mensuales            varchar(10),
   @w_operacion                     char(1),
   @w_entidad_federativa            varchar(10),
   @w_lugar_act                     varchar(100),
   @w_pregunta1                     char(1),
   @w_pregunta2                     char(1),
   @w_pregunta3                     char(1),
   @w_fatca                         char(1),
   @w_crs                           char(1),
   @w_provincia_res                 varchar(10),
   @w_nivel_cuenta                  catalogo,
   @w_cat_num_trn_mes_ini           catalogo,
   @w_cat_mto_trn_mes_ini           catalogo,
   @w_cat_sdo_prom_mes_ini          catalogo,
   @w_can_anticipada                char(1),     
   @w_orig_fondo                    varchar(20), 
   @w_pag_adcapital                 char(1),     
   @w_cuota_adi                     money,       
   @w_tipo_iden_personal            varchar(4),
   @w_num_iden_personal             numero,
   @w_tipo_iden_tributario          varchar(4),
   @w_num_iden_tributario           numero,
   @w_tipo_iden_adicional           varchar(13),
   @w_num_iden_adicional            numero,
   @w_tipo_residencia               char(4),
   @w_ente_migrado                  varchar(30),
   @w_nombre_oficial                varchar(64),
   @w_persona_pub                   char(1),
   @w_carg_pub                      varchar(200),
   @w_rel_carga_pub                 varchar(10),
   @w_cod_rel_carga_pub             int,
   @w_nombre_pep_relac              varchar(100),
   @w_fecha_inicio_pep              varchar(10),
   @w_fecha_fin_pep                 varchar(10),
   @w_tipo_pep                      catalogo,
   @w_asunto_mail                   varchar(200),
   @w_head_mail                     varchar(200),
   @w_ciudad_emi                    int,
   @w_email_cliente                 varchar(50),
   @w_pseudonimo                    descripcion,
   @w_pseudonimo_par                tinyint

/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_persona_cons'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/

select @w_today = @s_date
select @w_mail_oficial = '1'

--MTA Inicio
select @w_mayoria_edad = pa_tinyint  --Edad minima
  from cobis..cl_parametro
 where pa_nemonico = 'MDE'
   and pa_producto = 'ADM'

select @w_edad_max = pa_tinyint --Edad maxima
  from cobis..cl_parametro
 where pa_nemonico='EMAX'
   and pa_producto = 'CLI'
--MTA Fin
if @s_culture = 'NEUTRAL'
begin
   ---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
   exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
end
select @w_asunto_mail = re_valor                                                                                                                                                                           
from   cobis..cl_errores 
inner join cobis..ad_error_i18n 
on    (numero = pc_codigo_int                                                                                                                                                                                                                        
       and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
where  numero = 1720612 


select @w_head_mail = re_valor                                                                                                                                                                           
from   cobis..cl_errores 
inner join cobis..ad_error_i18n 
on   (numero = pc_codigo_int 
      and re_cultura like '%'+REPLACE(upper(@s_culture), '_', '%')+'%')                                                                                                                                                                                                           
where numero = 1720613

if @i_operacion = 'Q' --CONSULTA DE DATOS DE PERSONA
   begin
      if @t_trn = 172039 or @t_trn = 132
         begin
		    -- ULTIMA OBSERVACION DEL AUTORIZADOR (CAMBIO DE ESTADO)
            select @w_ultima_fecha = max(me_fecha)
            from cl_mod_estados
            where me_ente  = @i_persona

            select @o_ea_observacion_aut = me_observacion
            from cl_mod_estados
            where me_ente  = @i_persona
            and me_fecha = @w_ultima_fecha

            select
               @w_p_apellido                 = a.p_p_apellido,
               @w_s_apellido                 = a.p_s_apellido,
               @w_nombre                     = a.en_nombre,
               @w_cedula                     = CASE WHEN a.en_tipo_ced='SD' then ''  else a.en_ced_ruc end,  
               @w_pasaporte                  = a.p_pasaporte,
               @w_pais                       = a.en_pais,
               @w_ciudad_nac                 = a.p_ciudad_nac,
               @w_fecha_nac                  = a.p_fecha_nac,
               @w_fechanac                   = convert(char(10), a.p_fecha_nac, @i_formato_fecha),
               @w_fechareg                   = convert(char(10), a.en_fecha_crea, @i_formato_fecha),
               @w_fechamod                   = convert(char(10), a.en_fecha_mod, @i_formato_fecha),
               @w_retencion                  = a.en_retencion,
               @w_mala_referencia            = a.en_mala_referencia,
               @w_comentario                 = a.en_comentario,
               @w_fechaing                   = convert(char(10), a.p_fecha_emision, @i_formato_fecha),
               @w_fechaexp                   = convert(char(10), a.p_fecha_expira, @i_formato_fecha),
               @w_tipoced                    = a.en_tipo_ced,
               @w_asosciada                  = a.en_asosciada,
               @w_tipo_vinculacion           = a.en_tipo_vinculacion,
               @w_nit                        = a.en_rfc,
               @w_referido                   = a.en_referido,
               @w_cod_sector                 = a.en_sector,
               @w_cod_sex                    = a.p_sexo,
               @w_cod_gender                 = a.p_genero,
               @w_ocupacion                  = a.p_ocupacion, 
               @w_actividad                  = a.en_actividad,
               @w_estado_civil               = a.p_estado_civil,
               @w_tipo                       = a.p_tipo_persona,
               @w_nivel_estudio              = a.p_nivel_estudio,
               @w_grupo                      = a.en_grupo,
               @w_oficial                    = a.en_oficial,
               @w_lugar_doc                  = a.p_lugar_doc,
               @w_tipo_vivienda              = a.p_tipo_vivienda,
               @w_calif_cliente              = a.p_calif_cliente,
               @w_num_hijos                  = a.p_num_hijos,
               @w_nivel_ing                  = a.p_nivel_ing,
               @w_nivel_egr                  = a.p_nivel_egr,
               @w_num_cargas                 = a.p_num_cargas,
               @w_oficina_origen             = a.en_oficina ,
               @w_doc_validado               = a.en_doc_validado ,
               @w_rep_superban               = a.en_rep_superban ,
               @w_filial                     = a.en_filial,
               @w_gran_contribuyente         = a.en_gran_contribuyente,
               @w_situacion_cliente          = a.en_situacion_cliente,
               @w_patrim_tec                 = a.en_patrimonio_tec,
               @w_fecha_patrim_bruto         = convert(char(10), a.en_fecha_patri_bruto, @i_formato_fecha),
               @w_total_activos              = a.c_total_activos,
               @w_oficial_sup                = a.en_oficial_sup,
               @w_preferen                   = a.en_preferen,
               @w_exc_sipla                  = a.en_exc_sipla,
               @w_exc_por2                   = a.en_exc_por2,
               @w_digito                     = a.en_digito,
               @w_cem                        = a.en_cem,
               @w_c_apellido                 = a.p_c_apellido,
               @w_segnombre                  = a.p_s_nombre,
               @w_depart_doc                 = a.p_dep_doc,
               @w_numord                     = a.p_numord,
               @w_promotor                   = a.en_promotor,
               @w_num_pais_nacionalidad      = a.en_nacionalidad,
               @w_cod_otro_pais              = a.en_cod_otro_pais,
               @w_inss                       = a.en_inss,
               @w_licencia                   = a.en_licencia,
               @w_ingre                      = a.en_ingre,
               @w_en_id_tutor                = a.en_id_tutor,  --ID del tutor
               @w_en_nom_tutor               = a.en_nom_tutor,        --Nombre del Tutor
               @w_bloquear                   = a.en_estado,
               @w_categoria                  = a.en_concordato,  --I.CVA Abr-23-07 Campo para categoria
               --@w_es_cliente                 = (select case when (en_ente in (select cl_cliente from cl_cliente(index cl_cliente_Key))) then 'S' else 'N' end from cl_ente where en_ente = @i_persona and en_subtipo = 'P'),
               @w_es_cliente                 = (select case when (en_ente in (select cl_cliente from cl_cliente with (index (cl_cliente_Key)))) then 'S' else 'N' end from cl_ente where en_ente = @i_persona and en_subtipo = 'P'),
               @w_referido_ext               = a.en_referidor_ecu,
               @w_rel_carg_pub               = a.p_rel_carg_pub,
               @w_situacion_laboral          = a.p_situacion_laboral,
               @w_bienes                     = a.p_bienes,
               @w_otros_ingresos             = a.en_otros_ingresos,
               @w_origen_ingresos            = a.en_origen_ingresos,
               @o_ea_estado                  = b.ea_estado,
               --@o_ea_observacion_aut         = b.ea_observacion_aut,
               @o_ea_contrato_firmado        = b.ea_contrato_firmado,
               @o_ea_menor_edad              = b.ea_menor_edad,
               @o_ea_conocido_como           = b.ea_conocido_como,
               @o_ea_cliente_planilla        = b.ea_cliente_planilla,
               @o_ea_cod_risk                = b.ea_cod_risk,
               @o_ea_empadronado             = 'N',--b.ea_empadronado,
               @o_c_funcionario              = a.c_funcionario,
               @o_ea_sector_eco              = b.ea_sector_eco,
               @o_ea_actividad               = b.ea_actividad,
               @o_ea_lin_neg                 = b.ea_lin_neg,
               @o_ea_seg_neg                 = b.ea_seg_neg,
               @o_ea_val_id_check            = 'N',--b.ea_val_id_check,
               @o_ea_ejecutivo_con           = b.ea_ejecutivo_con,
               @o_ea_suc_gestion             = b.ea_suc_gestion,
               @o_ea_constitucion            = b.ea_constitucion,
               @o_ea_emp_planilla            = b.ea_cliente_planilla,
               @o_ea_remp_legal              = b.ea_remp_legal,
               @o_ea_apoderado_legal         = b.ea_apoderado_legal,
               @o_ea_act_comp_kyc            = 'N',--b.ea_act_comp_kyc,
               @o_ea_fecha_act_kyc           = convert(char(10), getdate(), @i_formato_fecha),--convert(char(10), b.ea_fecha_act_kyc, @i_formato_fecha),
               @o_ea_no_req_kyc_comp         = 'N',--b.ea_no_req_kyc_comp,
               @o_ea_act_perfiltran          = 'N',--b.ea_act_perfiltran,
               @o_ea_fecha_act_perfiltran    = convert(char(10),getdate(), @i_formato_fecha),--convert(char(10),b.ea_fecha_act_perfiltran, @i_formato_fecha),
               @o_ea_con_salario             = 'N',--b.ea_con_salario,
               @o_ea_fecha_consal            = convert(char(10),getdate(), @i_formato_fecha),--convert(char(10),b.ea_fecha_consal, @i_formato_fecha),
               @o_ea_sin_salario             = 'N',--b.ea_sin_salario,
               @o_ea_fecha_sinsal            = convert(char(10), getdate(), @i_formato_fecha),--convert(char(10), b.ea_fecha_sinsal, @i_formato_fecha),
               @o_ea_actualizacion_cic       = 'N',--b.ea_actualizacion_cic,
               @o_ea_fecha_act_cic           = convert(char(10), getdate(), @i_formato_fecha),--convert(char(10), b.ea_fecha_act_cic, @i_formato_fecha),
               @o_ea_excepcion_cic           = 'N',--b.ea_excepcion_cic,
               @o_ea_excepcion_pad           = 'N',--b.ea_excepcion_pad,
               @o_ea_fuente_ing              = b.ea_fuente_ing,
               @o_ea_act_prin                = b.ea_act_prin,
               @o_ea_detalle                 = b.ea_detalle,
               @o_ea_act_dol                 = isnull(b.ea_act_dol, 0),
               @o_ea_cat_aml                 = b.ea_cat_aml,
               @o_ea_observacion_vincula     = b.ea_observacion_vincula,
               @o_ea_fecha_vincula           = convert(char(10), b.ea_fecha_vincula, @i_formato_fecha),
               @o_c_verificado               = a.c_verificado,
               @o_fecha_veri                 = convert(char(10), a.c_fecha_verif, @i_formato_fecha),
               @o_act_cic                    = 'N',--b.ea_actualizacion_cic,
               @o_excep_cic                  = 'N',--b.ea_excepcion_cic,
               @w_discapacidad               = b.ea_discapacidad,
               @w_tipo_discapacidad          = b.ea_tipo_discapacidad,
               @w_ced_discapacidad           = b.ea_ced_discapacidad,
               @w_asfi                       = b.ea_asfi,
               @w_egresos                    = b.ea_nivel_egresos,
               @w_ifi                        = b.ea_ifi,
               @w_path_foto                  = b.ea_path_foto,
               @w_nit_id                     = b.ea_nit,
               @w_nit_venc                   = convert(char(10), b.ea_nit_venc, @i_formato_fecha),
               @w_calif_cli                  = a.en_calif_cartera,
               @w_emproblemado               = a.en_emproblemado,
               @w_dinero_transac             = a.en_dinero_transac,
               @w_pep                        = a.en_persona_pep,
               -- @i_mnt_activo              money         = null, --@i_total_activos
               @w_mnt_pasivo                 = a.c_pasivo,
               @w_vinculacion                = a.en_vinculacion,
               /*@w_vinculacion                = (select case when (en_nit in (select fu_cedruc from cobis..cl_funcionario))
                                                then 'S' else 'N' end from cl_ente where en_ente = @i_persona),*/
               @w_ant_nego                   = b.ea_ant_nego,
               @w_ventas                     = b.ea_ventas,
               --@i_ot_ingresos    money = null,   @i_otros_ingresos
               @w_ct_ventas                  = ea_ct_ventas,
               @w_ct_operativos              = ea_ct_operativo,
               @w_ea_nro_ciclo_oi            = ea_nro_ciclo_oi,  --LPO Santander
               @w_ing_SN                     = en_ing_SN,
               @w_otringr                    = en_otringr ,
               @w_depa_nac                   = en_provincia_nac,
               @w_nac_aux                    = en_nac_aux,
               @w_pais_emi                   = p_pais_emi,
               @w_ea_cta_banco               = b.ea_cta_banco,
               @w_banco                      = a.en_banco,
               @w_estado_std                 = ea_estado_std,
               @w_risk_level                 = p_calif_cliente,
               @w_credit_bureau              = (select convert(varchar(20),ib_riesgo) from cob_credito..cr_interface_buro where ib_cliente = en_ente),
               @w_partner                    = ea_partner,
               @w_lista_negra                = ea_lista_negra,
               @w_tecnologico                = ea_tecnologico,
               @w_telefono_recados           = ea_telef_recados,
               @w_numero_ife                 = ea_numero_ife   ,
               @w_numero_serie_firma_elect   = ea_num_serie_firma,
               @w_persona_recados            = ea_persona_recados,
               @w_antecedentes_buro          = ea_antecedente_buro,
               @w_pais_nac                   = a.en_pais_nac,
               @w_provincia_nac              = a.en_provincia_nac,
               @w_naturalizado               = a.en_naturalizado,
               @w_forma_migratoria           = a.en_forma_migratoria,
               @w_nro_extranjero             = a.en_nro_extranjero,
               @w_calle_orig                 = a.en_calle_orig,
               @w_exterior_orig              = a.en_exterior_orig,
               @w_estado_orig                = a.en_estado_orig,
               @w_tipo_iden                  = a.en_tipo_iden,
               @w_numero_iden                = a.en_numero_iden,
               @w_act_desc_cny               = a.en_actividad_desc,
               @w_tipo_iden_personal         = a.en_tipo_ced,
               @w_num_iden_personal          = a.en_ced_ruc,
               @w_tipo_iden_tributario       = a.en_tipo_doc_tributario,
               @w_num_iden_tributario        = a.en_rfc,
               @w_tipo_iden_adicional        = a.en_tipo_iden,
               @w_num_iden_adicional         = a.en_numero_iden,
               @w_tipo_residencia            = a.en_tipo_residencia,
               @w_ente_migrado               = a.en_ente_migrado,
               @w_nombre_oficial             = (select fu_nombre from cl_funcionario f, cc_oficial o 
                                                where a.en_oficial = o.oc_oficial and o.oc_funcionario = f.fu_funcionario),
               @w_persona_pub                = isnull(a.en_persona_pub, 'N'),
               @w_carg_pub                   = a.p_carg_pub,
               @w_rel_carga_pub              = a.p_rel_carg_pub,
               @w_cod_rel_carga_pub          = a.en_codigo_pep_relac,
               @w_nombre_pep_relac           = a.en_nombre_pep_relac,
               @w_fecha_inicio_pep           = convert(char(10), a.p_fecha_inicio_pep, @i_formato_fecha),
               @w_fecha_fin_pep              = convert(char(10), a.p_fecha_fin_pep, @i_formato_fecha),
               @w_tipo_pep                   = a.p_tipo_pep,
               @w_ciudad_emi                 = a.en_ciudad_emision
            from  cl_ente as a
            inner join cl_ente_aux b on (a.en_ente = b.ea_ente)
            where a.en_subtipo = 'P'
            and a.en_ente    = @i_persona

            --print 'Promotor: %1!',@w_promotor

            if @@rowcount = 0
               begin
                  exec sp_cerror  @t_debug    = @t_debug,
                     @t_file     = @t_file,
                     @t_from     = @w_sp_name,
                     @i_num      = 1720074
                     --NO EXISTE DATO SOLICITADO
                  return 1
               end

            select @w_relacion = cg_tipo_relacion
            from cl_cliente_grupo
            where cg_ente = @i_persona

            if @w_cod_sex is not null
               begin
                  select @w_sexo = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo = @w_cod_sex
                  and cl_catalogo.tabla  = cl_tabla.codigo
                  and cl_tabla.tabla     = 'cl_sexo'

                  if @@rowcount = 0
                     begin
           exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720025
                        return 1
                     end
            end
            
            if @w_cod_gender is not null
               begin
                  select @w_genero = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo = @w_cod_gender
                  and cl_catalogo.tabla  = cl_tabla.codigo
                  and cl_tabla.tabla     = 'cl_genero'

                  if @@rowcount = 0
                     begin
           exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720380
                        return 1
                     end
            end

            --I.CVA Abr-23-07 Categoria
            if @w_categoria is not null
               begin
                  select @w_desc_categoria = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_categoria
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_categoria'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720348
                        return 1
                     end
            end
            if @w_actividad is not NULL
               begin
                  select  @w_des_actividad= ac_descripcion
                  from cl_actividad_ec
                  where ac_codigo = @w_actividad

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720059
                        return 1
                     end
               end

            if @w_cod_sector is not NULL
               begin
                  select  @w_des_sector= cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_cod_sector
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_sector_economico'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720042
                        return 1
                     end
            end

            if @w_situacion_cliente is not NULL
               begin
                  select  @w_des_situacion_cliente = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_situacion_cliente
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_situacion_cliente'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720600
                        return 1
                     end
            end

            if (@w_estado_civil is not NULL and @w_estado_civil <> '')
               begin
                  select @w_des_estado_civil = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_estado_civil
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_ecivil'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720057
                           --NO EXISTE DATO SOLICITADO
                        return 1
                     end
            end

            if @w_nivel_estudio is not NULL
               begin
                  select @w_des_niv_est = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_nivel_estudio
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_nivel_estudio'

                  if @@rowcount = 0 -- JLi
                  begin
                     exec sp_cerror  @t_debug    = @t_debug,
                        @t_file     = @t_file,
                        @t_from     = @w_sp_name,
                        @i_num      = 1720029
                     return 1
                  end
            end

            if @w_tipo_vinculacion is not NULL
               begin
                  if(@w_vinculacion = 'S') --MTA VALIDACION INTERFAZ CLIENTE VINCULADO
                  begin
                  --PRINT ('@w_vinculacio <<<')+CONVERT(VARCHAR(60),@w_vinculacion)
                  select @w_tipo_vinculacion = '013'  --FUNCIONARIO DEL BANCO
                     select @w_des_tipo_vinculacion = cl_catalogo.valor
                       from cl_catalogo, cl_tabla
                       where cl_catalogo.codigo       = @w_tipo_vinculacion
                         and cl_catalogo.tabla        = cl_tabla.codigo
                         and cl_tabla.tabla           = 'cl_relacion_banco'

                     if @@rowcount = 0
                        begin
                           exec sp_cerror  @t_debug    = @t_debug,
                              @t_file     = @t_file,
                              @t_from     = @w_sp_name,
                              @i_num      = 1720162
                           return 1
                        end
                  end
                  else
                  begin
                     select @w_des_tipo_vinculacion = cl_catalogo.valor
                       from cl_catalogo, cl_tabla
                       where cl_catalogo.codigo       = @w_tipo_vinculacion
                         and cl_catalogo.tabla        = cl_tabla.codigo
                         and cl_tabla.tabla           = 'cl_relacion_banco'

                     if @@rowcount = 0 -- JLI
                        begin
                           exec sp_cerror  @t_debug    = @t_debug,
                              @t_file     = @t_file,
                              @t_from     = @w_sp_name,
                              @i_num      = 1720162
                           return 1
                        end
                  end
            end

            if @w_tipo is not NULL
               begin
                  select @w_des_tipo = cl_catalogo.valor
             from cl_catalogo, cl_tabla
              where cl_catalogo.codigo   = @w_tipo
                  and cl_catalogo.tabla   = cl_tabla.codigo
                  and cl_tabla.tabla      = 'cl_ptipo'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720058
                        return 1
                        --NO EXISTE TIPO DE PERSONA
                     end
            end

            if @w_ocupacion is not NULL
               begin
                  select @w_des_ocupacion = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_ocupacion
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_ocupacion' 

                  if @@rowcount = 0
                     begin
                        /*print 'pase profesion'*/
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720026
                        --NO EXISTE DATO SOLICITADO
                        return 1
                     end
            end

            if (@w_tipo_vivienda is not NULL and @w_tipo_vivienda <> '')
               begin
                  select @w_des_tipo_vivienda = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_tipo_vivienda
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_tipo_vivienda'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720030
                           --NO EXISTE TIPO DE VIVIENDA
                        return 1
                     end
            end

            --print 'Promotor: %1!',@w_promotor
            if @w_promotor is not NULL
               begin
                  select @w_des_promotor = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_promotor
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_promotor'

                  if @@rowcount = 0 -- JLi
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720228
                           --NO EXISTE PROMOTOR
                        return 1
                     end
            end

            -- ingresos JLi
            if @w_ingre is not NULL
               begin
                  select @w_des_ingresos = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = @w_ingre
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_ingresos'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720229
                        --NO EXISTE DATO SOLICITADO
                        return 1
                     end
            end

            --VALIDANDO EL LUGAR DE NACIMIENTO
            /*if @w_ciudad_nac is NULL
               begin
          select @w_des_ciudad_nac = NULL
     end
            else
               begin
                  select  @w_des_ciudad_nac = pa_descripcion
                  from  cl_pais
                  where  @w_ciudad_nac = pa_pais

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 101001
                        --NO EXISTE DATO SOLICITADO
                        return 1
                     end
            end*/

            --if @w_tipoced = 'PA'
            if @w_tipoced ='P' or @w_tipoced = 'E' --or @w_tipoced = 'PE' or @w_tipoced = 'N'
               begin
                  select  @w_des_lugar_doc = pa_descripcion
                  --@w_des_lugar_doc = pa_nacionalidad
          from  cl_pais
                  where  pa_pais          = @w_lugar_doc

                  /* if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 101001
                           --NO EXISTE DATO SOLICITADO
                        return 1
                     end*/
               end
            else
               begin
                  select  @w_des_lugar_doc = ci_descripcion
                  from  cl_ciudad
                  where  ci_ciudad        = @w_lugar_doc
                  --and    ci_provincia = @w_depart_doc

                  /*if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 101001
                           --NO EXISTE DATO SOLICITADO
                        return 1
                     end*/
            end

            if @w_grupo is NULL
               select @w_grupo = NULL
            else
               begin
                  select  @w_des_grupo = gr_nombre
                  from  cl_grupo
                  where  @w_grupo     = gr_grupo

                  /*if @@rowcount = 0
                     begin
                        --print 'pase Grupo'
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 101001
                           --NO EXISTE DATO SOLICITADO
     return 1
                     end*/
            end

            --select SOBRE LA TABLA DE CL_FUNCIONARIO
            if @w_oficial is NULL or @w_oficial = 0
               select  @w_oficial = NULL
            else
               begin --MODIFICACION FUNCIONARIOS REC
                  select @w_nom_temp = fu_nombre,
                     @w_principal_login = fu_login
                  from cc_oficial,cl_funcionario
                  where oc_oficial = @w_oficial
                  and oc_funcionario = fu_funcionario

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720040
                        return 1
                     end

                  select @w_des_oficial = substring(@w_nom_temp,1,45)
                  --FIN MODIFICACION FUNCIONARIOS
                  if @@rowcount = 0
                     begin
                        --print 'pase Mod. FIn Funcionarios'
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720040
                           --NO EXISTE FUNCIONARIO
                        return 1
                     end
            end

            --select SOBRE LA TABLA DE CL_FUNCIONARIO
            if @w_oficial_sup is NULL
               select  @w_oficial_sup = NULL
            else
               begin --MODIFICACION FUNCIONARIOS REC
                  /*select @w_nom_temp = fu_nombre
                     from cl_funcionario
                     where fu_funcionario = @w_oficial_sup*/

                  select @w_nom_temp = fu_nombre,
                     @w_suplente_login = fu_login
                  from cc_oficial,cl_funcionario
                  where oc_oficial = @w_oficial_sup
                  and oc_funcionario = fu_funcionario

                  if @@rowcount = 0
                     begin
                        --print 'pase Mod. Funcionarios'
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720040
                           --NO EXISTE FUNICIONARIO
                        return 1
                     end

                  select @w_des_oficial_sup = substring(@w_nom_temp,1,45)
                  --FIN MODIFICACION FUNCIONARIOS
                  if @@rowcount = 0
                     begin
                        --print 'pase Mod. FIn Funcionarios'
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720040
                           --NO EXISTE FUNICIONARIO
                        return 1
                     end
            end

            --select SOBRE LA TABLA DE CL_FUNCIONARIO
            if @w_referido is NULL
               select  @w_referido = NULL
            else
               begin
                  select  @w_des_referido = substring(fu_nombre,1,45)
                  from  cl_funcionario
                  where  @w_referido     = fu_funcionario

                  if @@rowcount = 0
                     begin
                        --print 'pase referido'
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720040
                           --NO EXISTE FUNICIONARIO
                        return 1
                     end
            end

    --select SOBRE LA TABLA DE CL_PAIS
            if @w_pais is NULL
               select @w_pais = NULL
            else
               begin
                  select      @w_des_pais = pa_descripcion
                  from cl_pais
                  where pa_pais   = @w_pais

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720027
                        return 1
                     end
            end

            --PARA NACIONALIDAD
            --select SOBRE LA TABLA DE CL_PAIS
            if @w_num_pais_nacionalidad is NULL
               select @w_num_pais_nacionalidad = NULL
            else
               begin
                  select  @w_des_nacionalidad = pa_nacionalidad
                  from cl_pais
                  where @w_num_pais_nacionalidad = pa_pais

                  if @@rowcount = 0
                     begin
                        --print 'Error en Pais'
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720027
                        --NO EXISTE PAIS
                        return 1
              end
               end

            --select SOBRE LA TABLA DE CL_OFICINA
            /*select  @w_des_oficina = of_nombre
            from cl_oficina
            where @w_oficina_origen= of_oficina
            and @w_filial        = of_filial

            if @@rowcount = 0
               begin
                  --print 'pase des_oficina'
                  exec sp_cerror  @t_debug    = @t_debug,
                     @t_file     = @t_file,
                     @t_from     = @w_sp_name,
                     @i_num      = 101016
                     --NO EXISTE DATO SOLICITADO
                  return 1
            end*/

            --ACTUAL
            --SPO Inclusion de la descripcion del departamento

            if @w_depart_doc is not NULL
               begin
                  select @w_des_dep_doc  = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = convert(char(4),@w_depart_doc)
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_provincia'

                  /*if @@rowcount = 0
                     begin
                        print 'No existe departamento'
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 101010
                           --NO EXISTE DATO SOLICITADO
                        return 1
                     end*/
            end

            /*if @w_ciudad_nac is not NULL
               begin
                  select @w_des_ciudad  = cl_catalogo.valor
                  from cl_catalogo, cl_tabla
                  where cl_catalogo.codigo       = convert(char(4),@w_ciudad_nac)
                  and cl_catalogo.tabla        = cl_tabla.codigo
                  and cl_tabla.tabla           = 'cl_ciudad'

                  if @@rowcount = 0
                     begin
                        print 'No existe ciudad'
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 101001
                           --NO EXISTE DATO SOLICITADO
                        return 1
                     end
               end*/

            if @w_tipoced <> null
               begin
                  select @w_desc_tipo_ced  = td_descripcion,
                     @w_nacio_tipo_ced = td_nacionalidad
                  from cl_tipo_documento
                  where td_codigo = @w_tipoced

                  if @@rowcount = 0
                     begin
                        exec sp_cerror
                           @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720230
                           --NO EXISTE TIPO DE IDENTIFICACION
                        return 1
                     end
            end

            --I. CVA MAR-23-06 OBTENER EL TIPO DE SERVICIO DE BANCA VIRTUAL PARA EL CLIENTE
            /*select  @w_canal_bv = af_canal
            from cobis..bv_afiliados_bv
            where af_ente_mis = @i_persona

            if @@rowcount > 0
               select  @w_tipo_medio           = b.codigo,
                  @w_desc_tipo_medio      = b.valor
               from cobis..cl_tabla a,  cobis..cl_catalogo b
               where a.tabla = 'bv_servicio'
               and b.tabla = a.codigo
               and b.codigo = convert(varchar(10),@w_canal_bv)*/
               --F. CVA Mar-23-06

            -- Ini EAN - HSBC - 14/AGO/2012
            select @o_actividad_princ = ap_descripcion
            from  cl_ente a,
               cl_ente_aux b,
               cl_actividad_principal
            where a.en_ente  = @i_persona
            and a.en_ente    = b.ea_ente
            and a.en_subtipo = 'P'
            and ap_codigo    = b.ea_act_prin

            select @o_fuente_ing = cat.valor
            from  cl_ente a,
               cl_ente_aux b,
               cl_catalogo cat, cl_tabla tbl
            where a.en_ente    = @i_persona
            and a.en_ente    = b.ea_ente
            and a.en_subtipo = 'P'
            and tbl.tabla    = 'cl_fuente_ingreso'
            and cat.tabla    = tbl.codigo
            and cat.codigo   = b.ea_fuente_ing
            -- Fin EAN - HSBC - 14/AGO/2012

            --DESCRIPCION DE DISCAPACIDAD
            if @w_tipo_discapacidad is not NULL
               begin
                  select @w_desc_discapacidad = cl_catalogo.valor
                  from    cl_catalogo, cl_tabla
                  where   cl_catalogo.codigo   = @w_tipo_discapacidad
                  and     cl_catalogo.tabla    = cl_tabla.codigo
                  and     cl_tabla.tabla       = 'cl_discapacidad'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720020
                           --CODIGO DE DISCAPACIDAD INCORRECTO
                        return 1
                     end
            end

            --DESCRIPCION DE NIVEL DE EGRESOS
             if @w_egresos is not NULL
               begin
                  select @w_desc_egresos = cl_catalogo.valor
                  from    cl_catalogo, cl_tabla
                  where   cl_catalogo.codigo   = @w_egresos
                  and     cl_catalogo.tabla    = cl_tabla.codigo
                  and     cl_tabla.tabla       = 'cl_nivel_egresos'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720231
                           --NO EXISTE CODIGO DE NIVEL DE EGRESOS
                        return 1
                     end
               end

            --DESCRIPCION DE LA CALIFICACION DEL CLIENTE
            if @w_calif_cli is not NULL
               begin
                  select @w_des_calif_cliente = cl_catalogo.valor
                  from    cl_catalogo, cl_tabla
                  where   cl_catalogo.codigo   = @w_calif_cli
                  and     cl_catalogo.tabla    = cl_tabla.codigo
                  and     cl_tabla.tabla       = 'ca_calif_cliente'

                  select @w_descalif_cli = @w_des_calif_cliente

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720232
                           --NO EXISTE TIPO DE CALIFICACION
                        return 1
                     end
               end

            --DESCRIPCION DE CATEGORIA AML
            if @o_ea_cat_aml is not NULL
               begin
                  select @w_ea_desc_aml = cl_catalogo.valor
               from    cl_catalogo, cl_tabla
                  where   cl_catalogo.codigo   = @o_ea_cat_aml
                  and     cl_catalogo.tabla    = cl_tabla.codigo
                  and     cl_tabla.tabla       = 'cl_categoria_AML'

                  if @@rowcount = 0
                     begin
                        exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720233
                           --NO EXISTE CODIGO DE CATEGORIA AML
                        return 1
                     end
               end

               --DESCRIPCION DE ESTADO DEL CLIENTE
           if @o_ea_estado is not NULL
                begin
                   select @w_ea_estado_desc = cl_catalogo.valor
                   from    cl_catalogo, cl_tabla
                   where   cl_catalogo.codigo   = @o_ea_estado
                   and     cl_catalogo.tabla    = cl_tabla.codigo
                   and     cl_tabla.tabla       = 'cl_estados_ente'

                   if @@rowcount = 0
                      begin
                         exec sp_cerror  @t_debug    = @t_debug,
                            @t_file     = @t_file,
                            @t_from     = @w_sp_name,
                            @i_num      = 1720234
                            --NO EXISTE ESTADO
                         return 1
                      end
                end

                --CONYUGE
                --MTA Inicio
                --select @w_lado_relacion = 'I'
                select @w_cod_relacion = pa_tinyint --relación cónyuge
                  from cobis..cl_parametro
                 where pa_nemonico = 'CONY'
                   and pa_producto = 'CLI'
                select @w_cod_conyugue = in_ente_d
                  from cobis..cl_instancia
                 where in_relacion = @w_cod_relacion
                   and in_ente_i= @i_persona

                select @w_conyuge = en_nombre+' '+ isnull(p_s_nombre, '')+' '+ p_p_apellido +' '+ isnull(p_s_apellido, '')
                  from cobis..cl_ente
                 where en_ente = @w_cod_conyugue

                --Se comenta para tomar la información de relaciones entre clientes de la cl_instancia
                /*select @w_conyuge = hi_nombre +" "+ hi_s_nombre +" "+ hi_papellido +" "+ hi_sapellido
                  from cl_hijos
                 where hi_ente=@i_persona
                   and hi_tipo='C'
                */
                --MTA Fin

            -- Para obtner el nombre del grupo e id
            select @w_id_grupo     = cg_grupo,
                   @w_nombre_grupo = gr_nombre
            from   cobis..cl_cliente_grupo CG, cobis..cl_grupo GR
            where  CG.cg_estado = 'V' and CG.cg_fecha_desasociacion is null
            and    CG.cg_ente = @i_persona
            and    CG.cg_grupo  = GR.gr_grupo

            --Obtener números de referencia pantalla datos complementarios
            select @w_num_referencia = min(rp_referencia)--rp_telefono_d
            from cobis..cl_ref_personal
            where rp_persona = @i_persona

            select  @w_telef_referencia_uno = rp_telefono_d
            from cobis..cl_ref_personal
            where rp_persona   = @i_persona
            and   rp_referencia= @w_num_referencia

            if @w_telef_referencia_uno is not null
            begin
                 select  @w_telef_referencia_dos = rp_telefono_d
                 from cobis..cl_ref_personal
                 where rp_persona   = @i_persona
                 and   rp_referencia> @w_num_referencia
            end

            if isnull(@i_tipo,'Z') <> 'O'--Consulta Normal Func Clientes
               begin
                  if  @i_modo = 0
                     --PRIMERA PARTE
                     begin
                        --Se obtiene el pseudonimo del cliente
                        select @w_pseudonimo_par = pa_tinyint
                        from cobis.dbo.cl_parametro
                        where pa_nemonico = 'CODPSE'
                        and pa_producto = 'CLI'
                        
                        select @w_pseudonimo = de_valor
                        from cobis..cl_dadicion_ente 
                        where de_ente = @i_persona 
                        and de_dato = @w_pseudonimo_par
                        --Se obtiene correo de cliente para la busqueda
                        select @w_email_cliente = isnull(di_descripcion,'')
                        from cobis..cl_direccion 
                        where di_tipo = 'CE'
                        and di_ente = @i_persona
                        --print 'Promotor: %1!',@w_promotor

                        --INICIO FOR 2016-02-05 se agrega una bandera en la consulta que indica si se trata de un cliente menor de edad o mayor de edad
                        declare @w_anios_edad int, @w_menor_edad varchar(2)  -- Valores SI o NO

                        select @w_anios_edad = datediff(yy, @w_fecha_nac, fp_fecha) from cobis..ba_fecha_proceso

                        if (@w_anios_edad>@w_mayoria_edad) and (@w_anios_edad<@w_edad_max)
                           select @w_menor_edad = 'NO'
                        else
                           select @w_menor_edad = 'SI'

                        select @w_num_ciclos=ea_nro_ciclo_oi from cobis..cl_ente_aux where ea_ente=@i_persona
                        --Validaciones en Clientes--
                        select @w_fecha_mod_cli=en_fecha_mod,
                               @w_num_ciclos_en=en_nro_ciclo
                        from cobis..cl_ente where en_ente=@i_persona
                        select @w_fecha_proceso=fp_fecha from cobis..ba_fecha_proceso;
                        select @w_parametro_cli=pa_int from cl_parametro where pa_nemonico='FDVP' AND pa_producto='CLI'
                        select @w_meses_vigentes=( DATEDIFF(mm,@w_fecha_mod_cli,@w_fecha_proceso));

                        if @w_meses_vigentes>@w_parametro_cli
                        select @w_vigencia =1
                        else
                        select @w_vigencia = 0
                        --verifico si la condicion es verdadera--
                       if(@w_vigencia=1)
                       begin
                       --obtengo los datos del cliente--
                       select @w_cliente=c.en_ente,
                         @w_nombre_cli= c.en_nombre,
                         @w_apellido=c.p_p_apellido,
                         @w_oficial_ente = c.en_oficial

                        from cl_ente c
                        where  en_ente=@i_persona

                        --PRINT ('codigo')+CONVERT(VARCHAR(30),@w_cliente)
                        --PRINT ('nombre')+CONVERT(VARCHAR(30),@w_nombre_cli)
                        --PRINT ('apellido')+CONVERT(VARCHAR(30),@w_apellido)
                        --obtengo el mail del oficial del cliente--
                        select @w_tmail = pa_char from cobis..cl_parametro where pa_nemonico= 'TEMFU' AND pa_producto = 'ADM'

                        -- CORREO PARA OFICIAL
                        select TOP 1 @w_mail_oficial = isnull(mf_descripcion, '1')
                        from cobis..cc_oficial, cobis..cl_funcionario, cobis..cl_medios_funcio
                        where oc_oficial = @w_oficial_ente
                        and fu_funcionario = oc_funcionario
                        and fu_funcionario = mf_funcionario
                        and mf_tipo  = @w_tmail


                        ---envio el correo al oficial--
                        if @w_mail_oficial <> '1'
                        begin

                            select  @w_email_body = '' +@w_nombre_cli +' '+ @w_apellido +'.<br><br>' + @w_asunto_mail + '<br><br><br>'

                           exec cobis..sp_notificacion_general
                                @i_operacion    = 'I',
                                @i_mensaje      = @w_email_body,
                                @i_correo       = @w_mail_oficial,
                                @i_asunto       =  @w_head_mail

                        end
                       end --- vigencia

                        if @w_cod_rel_carga_pub <> NULL
                        begin
                           select @w_nombre_pep_relac = en_nomlar
                           from cl_ente 
                           where en_ente = @i_persona
                        end

                        -- FIN FOR
                        select
                           @w_fechanac,                                                       -- 1
                           @w_tipoced,                                                        -- 2
                           @w_cedula,                                                         -- 3
                           @w_fechaing,                                                       -- 4
                           @w_fechaexp,                                                       -- 5
                           @w_ciudad_emi,                                                      -- 6
                           @w_des_lugar_doc,                                                  -- 7
                           @w_nombre,                                                         -- 8
                           @w_p_apellido,                                                     -- 9
                           @w_s_apellido,                                                     -- 10
                           @w_ciudad_nac,                                                     -- 11
                           @w_des_ciudad_nac,                                                 -- 12
                           @w_sexo,                                                           -- 13
                           @w_cod_sex,                                                        -- 14
                           @w_estado_civil,                                                   -- 15
                           @w_des_estado_civil,                                               -- 16
                           @w_ocupacion,                                                      -- 17
                           @w_des_ocupacion,                                                  -- 18
                           @w_actividad,                                                      -- 19
                           @w_des_actividad,                                                  -- 20
                           @w_pasaporte,                                                      -- 21
                           @w_pais,                                                           -- 22
                           @w_des_pais,                                                       -- 23
                           @w_cod_sector,                                                     -- 24
                           @w_des_sector,                                                     -- 25
                           @w_nivel_estudio,                                                  -- 26
                           @w_des_niv_est,                                                    -- 27
                           @w_tipo,                                                           -- 28
                           @w_des_tipo,                                                       -- 29
                           @w_tipo_vivienda,                                                  -- 30
                           isnull(@w_des_tipo_vivienda,''),                                   -- 31
                           @w_num_cargas,                                                     -- 32
                           @w_comentario,                                                     -- 33
                           @w_referido,                                                       -- 34
                           @w_num_hijos,                                                      -- 35
                           @w_rep_superban,                                                   -- 36
                           @w_doc_validado,                                                   -- 37
                           @w_oficial,                                                        -- 38
                           @w_des_oficial,                                                    -- 39
                           @w_fechareg,                                                       -- 40
                           @w_fechamod,                                                       -- 41
                           @w_grupo,                                                          -- 42
                           @w_des_grupo,                                                      -- 43
                           case when @t_trn = 132 then (select c.valor from cobis..cl_tabla t ,cobis..cl_catalogo c where t.codigo = c.tabla and t.tabla = 'cr_sol_exp' and @w_retencion = c.codigo) else @w_retencion end,-- 44
                           @w_mala_referencia,                                                -- 45
                           @w_tipo_vinculacion,                                               -- 46
                           case when @t_trn = 132 then null else @w_nit end,                  -- 47
                           @w_calif_cli,                                                      -- 48
                           @w_des_calif_cliente,                                              -- 49
                           @w_des_tipo_vinculacion,                                           -- 50
                           @w_nivel_ing,                                                      -- 51
                           @w_oficina_origen,                                                 -- 52
                           @w_des_oficina,                                                    -- 53
                           @w_des_referido,                                                   -- 54
                           @w_gran_contribuyente,                                             -- 55
                           @w_situacion_cliente,                                              -- 56
                           @w_des_situacion_cliente,                                          -- 57
                           @w_patrim_tec,                                                     -- 58
                           convert(char(10),@w_fecha_patrim_bruto,101),                       -- 59
                           @w_total_activos,                                                  -- 60
                           @w_oficial_sup,                                                    -- 61
                           @w_des_oficial_sup,                                                -- 62
                           @w_preferen,                                                       -- 63
                           @w_nivel_egr,                                                      -- 64
                           @w_exc_sipla,                                                      -- 65
                           @w_exc_por2,                                                       -- 66
                           @w_digito,                                                         -- 67
                           @w_cem,                                                            -- 68
                           @w_segnombre,                                                      -- 69
                           @w_c_apellido,                                                     -- 70
                           @w_depart_doc,                                                     -- 71
                           @w_des_dep_doc,                                                    -- 72
                           @w_numord,                                                         -- 73
                           @w_des_ciudad,                                                     -- 74
                           @w_promotor,                                                       -- 75
                           @w_des_promotor,                                                   -- 76
                           @w_num_pais_nacionalidad,                                          -- 77
                           @w_des_nacionalidad,                                               -- 78
                           @w_cod_otro_pais,                                                  -- 79
                           @w_inss,                                                           -- 80
                           @w_menor_edad,                                                     -- 81
                           @w_conyuge,                                                        -- 82
                           @w_persona_pub,                                                    -- 83
                           @w_ing_SN,                                                         -- 84
                           @w_otringr,                                                        -- 85
                           @w_depa_nac,                                                       -- 86
                           @w_nac_aux,                                                        -- 87
                           @w_pais_emi,                                                       -- 88
                           @w_carg_pub,                                                       -- 89
                           @w_rel_carg_pub,                                                   -- 90
                           @w_ea_cta_banco,                                                   -- 91
                           @w_num_ciclos,                                                     -- 92
                           @w_vigencia,                                                       -- 93
                           @w_banco,                                                          -- 94
                           @w_estado_std,                                                     -- 95
                           isnull(@w_num_ciclos_en,0),                                        -- 96
                           @w_partner,                                                        -- 97
                           @w_lista_negra,                                                    -- 98
                           @w_tecnologico,                                                    -- 99
                           @w_id_grupo,                                                       -- 100
                           @w_nombre_grupo,                                                   -- 101
                           @w_telefono_recados,                                               -- 102
                           @w_numero_ife,                                                     -- 103
                           @w_numero_serie_firma_elect,                                       -- 104
                           @w_persona_recados,                                                -- 105
                           @w_antecedentes_buro,                                              -- 106
                           @w_telef_referencia_uno,                                           -- 107
                           @w_telef_referencia_dos,                                           -- 108
                           isnull(@w_existe_alerta,'N'),                                      -- 109
                           @w_pais_nac,                                                       -- 110
                           @w_provincia_nac,                                                  -- 111
                           @w_naturalizado,                                                   -- 112
                           @w_forma_migratoria,                                               -- 113
                           @w_nro_extranjero,                                                 -- 114
                           @w_calle_orig,                                                     -- 115
                           @w_exterior_orig,                                                  -- 116
                           @w_estado_orig,                                                    -- 117
                           @w_ident_tipo_c,                                                   -- 118
                           @w_ident_num_c,                                                    -- 119
                           @w_tipo_iden,                                                      -- 120
                           @w_numero_iden,                                                    -- 121
                           @w_act_desc_cny,                                                   -- 122
                           @w_ing_men_cny,                                                    -- 123
                           @w_genero,                                                         -- 124
                           @w_cod_gender,                                                     -- 125
                           @w_tipo_iden_personal,                                             -- 126
                           @w_num_iden_personal,                                              -- 127
                           case when @t_trn = 132 then null else @w_tipo_iden_tributario end, -- 128
                           case when @t_trn = 132 then null else @w_num_iden_tributario end,  -- 129
                           case when @t_trn = 132 then null else @w_tipo_iden_adicional end,  -- 130
                           case when @t_trn = 132 then null else @w_num_iden_adicional end,   -- 131
                           @w_tipo_residencia,                                                -- 132
                           @w_ente_migrado,                                                   -- 133
                           @w_nombre_oficial,                                                 -- 134
                           @w_persona_pub,                                                    -- 135
                           @w_carg_pub,                                                       -- 136
                           @w_rel_carga_pub,                                                  -- 137
                           @w_cod_rel_carga_pub,                                              -- 138
                           @w_nombre_pep_relac,                                               -- 139
                           @w_fecha_inicio_pep,                                               -- 140
                           @w_fecha_fin_pep,                                                  -- 141
                           @w_tipo_pep,                                                       -- 142
                           @w_ciudad_emi,                                                     -- 143
                           @o_ea_conocido_como,                                               -- 144
                           @w_email_cliente,                                                  -- 145
                           @w_pseudonimo                                                      -- 146
                     end
                  else if @i_modo = 1
  --SEGUNDA PARTE
                     begin
                        select
                           @w_licencia,                                           -- 1
                           @w_ingre,                                              -- 2
                           @w_des_ingresos,                                       -- 3
                           @w_principal_login,                                    -- 4
                           @w_suplente_login,                                     -- 5
                           @w_en_id_tutor,                                        -- 6
                           @w_en_nom_tutor,                                       -- 7
                           @w_bloquear,                                           -- 8
                           @w_relacion,                                           -- 9
                           @w_desc_tipo_ced,                                      -- 10
                           @w_tipo_medio,                                         -- 11
                           @w_desc_tipo_medio,                                    -- 12
                           @w_categoria,                                          -- 13
                           @w_desc_categoria,                                     -- 14
                           @w_es_cliente,                                         -- 15
                           @w_referido_ext,                                       -- 16
                           @w_des_referido_ext,                                   -- 17
                           @w_carg_pub,                                           -- 18
                           @w_rel_carg_pub,                                       -- 19
                           @w_situacion_laboral,                                  -- 20
                           @w_des_situacion_laboral,                              -- 21
                           @w_bienes,                                             -- 22
                           @w_otros_ingresos,                                     -- 23
                           @w_origen_ingresos,                                    -- 24
                           @o_ea_estado,                                          -- 25
                           @o_ea_observacion_aut,                                 -- 26
                           @o_ea_contrato_firmado,                                -- 27
                           @o_ea_menor_edad,                                      -- 28
                           @o_ea_conocido_como,                                   -- 29
                           @o_ea_cliente_planilla,                                -- 30
                           @o_ea_cod_risk,                                        -- 31
                           @o_ea_empadronado,                                     -- 32
                           @o_ea_sector_eco,                                      -- 33
                           @o_ea_actividad,                                       -- 34
                           @o_c_funcionario,                                      -- 35
                           @o_arma_categoria,                                     -- 36
                           isnull(@o_ea_act_comp_kyc, 'N'),                       -- 37
                           isnull(@o_ea_fecha_act_kyc, '01/01/1900'),             -- 38
                           isnull(@o_ea_no_req_kyc_comp, 'N'),                    -- 39
                           isnull(@o_ea_act_perfiltran, 'N'),                     -- 40
                           isnull(@o_ea_fecha_act_perfiltran, '01/01/1900'),      -- 41
                           isnull(@o_ea_con_salario, 'N'),                        -- 42
                           isnull(@o_ea_fecha_consal, '01/01/1900'),              -- 43
                           isnull(@o_ea_sin_salario, 'N'),                        -- 44
                           isnull(@o_ea_fecha_sinsal, '01/01/1900'),              -- 45
                           @o_ea_lin_neg,                                         -- 46
                           @o_ea_seg_neg,                                         -- 47
                           @o_ea_val_id_check,                                    -- 48
                           @o_ea_ejecutivo_con,                                   -- 49
                           @o_ea_suc_gestion,                                     -- 50
                           @o_ea_constitucion,                                    -- 51
                           @o_ea_emp_planilla,                                    -- 52
                           @o_ea_remp_legal,                                      -- 53
                           @o_ea_apoderado_legal,                                 -- 54
                           @o_ea_actualizacion_cic,                               -- 55
                           @o_ea_fecha_act_cic,                                   -- 56
                           @o_ea_excepcion_cic,                                   -- 57
                           @o_ea_fuente_ing,                                      -- 58
                           @o_ea_act_prin,                                        -- 59
                           @o_ea_detalle,                                         -- 60
                           isnull(@o_ea_act_dol, 0),                              -- 61
                           @o_ea_cat_aml,                                         -- 62
                           @o_ea_observacion_vincula,                             -- 63
                           @o_ea_fecha_vincula,                                   -- 64
                           isnull(@o_c_verificado, 'N'),                          -- 65
                           @o_actividad_princ,                                    -- 66
                           @o_fuente_ing,                                         -- 67
                           @o_fecha_veri,                                         -- 68
                           @o_act_cic,                                            -- 69
                           @o_excep_cic,                                          -- 70
                           @o_ea_excepcion_pad,                                   -- 71
                           @w_discapacidad,                                       -- 72
                           @w_tipo_discapacidad,                                  -- 73
                           @w_desc_discapacidad,                                  -- 74
                           @w_ced_discapacidad,                                   -- 75
                           @w_asfi,                                               -- 76
                           @w_egresos,                                            -- 77
                           @w_desc_egresos,                                       -- 78
                           @w_ifi,                                                -- 79
                           @w_ea_desc_aml,                                        -- 80
                           @w_nacio_tipo_ced,                                     -- 81
                           @w_path_foto,                                          -- 82
                           @w_nit_id ,                                            -- 83
                           @w_nit_venc,                                           -- 84
                           @w_calif_cli,                                          -- 85
                           @w_descalif_cli,                                       -- 86
                           @w_ea_estado_desc,                                     -- 87
                           @w_emproblemado,                                       -- 88
                           @w_dinero_transac,                                     -- 89
                           @w_pep,                                                -- 90
                           @w_mnt_pasivo,                                         -- 91
                           @w_vinculacion,                                        -- 92
                           @w_ant_nego,                                           -- 93
                           @w_ventas,                                             -- 94
                           @w_ct_ventas,                                          -- 95
                           @w_ct_operativos,                                      -- 96
                           @w_total_activos,                                      -- 97
                           @w_risk_level ,                                        -- 98
                           @w_credit_bureau,                                      -- 99
                           @w_ea_nro_ciclo_oi,                                    -- 100   --LPO Santander
                           @w_telefono_recados,                                   -- 101
                           @w_numero_ife,                                         -- 102
                           @w_numero_serie_firma_elect,                           -- 103
                           @w_persona_recados,                                    -- 104
                           @w_antecedentes_buro,                                  -- 105
                           @w_telef_referencia_uno,                               -- 106
                           @w_telef_referencia_dos,                               -- 107
                           @w_pasaporte,                                          -- 108
                           @w_persona_pub,                                        -- 109
                           @w_pais_nac,                                           -- 110
                           @w_provincia_nac,                                      -- 111
                           @w_naturalizado,                                       -- 112
                           @w_forma_migratoria,                                   -- 113
                           @w_nro_extranjero,                                     -- 114
                           @w_calle_orig,                                         -- 115
                           @w_exterior_orig,                                      -- 116
                           @w_estado_orig ,                                       -- 117
                           @w_tipo_iden,                                          -- 118
                           @w_numero_iden,                                        -- 119
                           @w_num_cargas                                          -- 120 depend
                     end
                  /*
                  select
                     @w_fechanac,                                           -- 1
                     @w_tipoced,                                            -- 2
                     @w_cedula,                                             -- 3
                     @w_fechaing,                                           -- 4
                     @w_fechaexp,                                           -- 5
                     @w_lugar_doc,                                          -- 6
                     @w_des_lugar_doc,                                      -- 7
                     @w_nombre,                                             -- 8
                     @w_p_apellido,                                         -- 9
                     @w_s_apellido,                                         -- 10
                     @w_ciudad_nac,                                         -- 11
                     @w_des_ciudad_nac,                                     -- 12
                     @w_sexo,                                               -- 13
                     @w_cod_sex,                                            -- 14
                     @w_estado_civil,                                       -- 15
                     @w_des_estado_civil,                                   -- 16
                     @w_ocupacion,                                          -- 17
                     @w_des_ocupacion,                                      -- 18
                     @w_actividad,                                          -- 19
                     @w_des_actividad,                                      -- 20
                     @w_pasaporte,                                          -- 21
                     @w_pais,                                               -- 22
                     @w_des_pais,                                           -- 23
                     @w_cod_sector,                                         -- 24
                     @w_des_sector,                                         -- 25
                     @w_nivel_estudio,                                      -- 26
                     @w_des_niv_est,                                        -- 27
                     @w_tipo,                                               -- 28
                     @w_des_tipo,                                           -- 29
                     @w_tipo_vivienda,                                      -- 30
                     isnull(@w_des_tipo_vivienda,''),                       -- 31
                     @w_num_cargas,                                         -- 32
                     @w_comentario,                                         -- 33
                     @w_referido,                                           -- 34
                     @w_num_hijos,                                          -- 35
                     @w_rep_superban,                                       -- 36
                     @w_doc_validado,                                       -- 37
                     @w_oficial,                                            -- 38
                     @w_des_oficial,                                        -- 39
                     @w_fechareg,                                           -- 40
                     @w_fechamod,                                           -- 41
                     @w_grupo,                                              -- 42
                     @w_des_grupo,                                          -- 43
                     @w_retencion,                                          -- 44
                     @w_mala_referencia,                                    -- 45
                     @w_tipo_vinculacion,                                   -- 46
                     @w_nit,                                                -- 47
                     @w_calif_cli,                                          -- 48
                     @w_des_calif_cliente,                                  -- 49
                     @w_des_tipo_vinculacion,                               -- 50
                     @w_nivel_ing,                                          -- 51
                     @w_oficina_origen,                                     -- 52
                     @w_des_oficina,                                        -- 53
                     @w_des_referido,                                       -- 54
                     @w_gran_contribuyente,                                 -- 55
                     @w_situacion_cliente,                                  -- 56
                     @w_des_situacion_cliente,                              -- 57
                     @w_patrim_tec,                                         -- 58
                     convert(char(10),@w_fecha_patrim_bruto,101),           -- 59
                     @w_total_activos,                                      -- 60
                     @w_oficial_sup,                                        -- 61
                     @w_des_oficial_sup,                                    -- 62
                     @w_preferen,                                           -- 63
                     @w_nivel_egr,                                          -- 64
                     @w_exc_sipla,                                          -- 65
                     @w_exc_por2,                                           -- 66
                     @w_num_hijos,                                          -- 35
                     @w_rep_superban,                                       -- 36
                     @w_doc_validado,                                       -- 37
                     @w_oficial,                                            -- 38
                     @w_des_oficial,                                        -- 39
                     @w_fechareg,                                           -- 40
                     @w_fechamod,                                           -- 41
                     @w_grupo,                                              -- 42
                     @w_des_grupo,                                          -- 43
                     @w_retencion,                                          -- 44
                     @w_mala_referencia,                                    -- 45
                     @w_tipo_vinculacion,                                   -- 46
                     @w_nit,                                                -- 47
                     @w_calif_cli,                                          -- 48
                     @w_des_calif_cliente,                                  -- 49
                     @w_des_tipo_vinculacion,                               -- 50
                     @w_nivel_ing,                                          -- 51
                     @w_oficina_origen,                                     -- 52
                     @w_des_oficina,                                        -- 53
                     @w_des_referido,                                       -- 54
                     @w_gran_contribuyente,                                 -- 55
                     @w_situacion_cliente,                                  -- 56
                     @w_des_situacion_cliente,                              -- 57
                     @w_patrim_tec,                                         -- 58
                     convert(char(10),@w_fecha_patrim_bruto,101),           -- 59
                     @w_total_activos,                                      -- 60
                     @w_oficial_sup,                                        -- 61
                     @w_des_oficial_sup,                                    -- 62
                     @w_preferen,                                           -- 63
                     @w_nivel_egr,                                          -- 64
                     @w_exc_sipla,                                          -- 65
                     @w_exc_por2,                                           -- 66
                     @w_digito,                                             -- 67
                     @w_cem,                                                -- 68
                     @w_segnombre,                                          -- 69
                     @w_c_apellido,                                         -- 70
                     @w_depart_doc,                                         -- 71
                     @w_des_dep_doc,                                        -- 72
                     @w_numord,                                             -- 73
                     @w_des_ciudad,                                         -- 74
                     @w_promotor,                                           -- 75
                     @w_des_promotor,                                       -- 76
                     @w_num_pais_nacionalidad,                              -- 77
                     @w_des_nacionalidad,                                   -- 78
                     @w_cod_otro_pais,                                      -- 78
                     @w_inss,                                               -- 80
                     @w_licencia,                                           -- 81
                     @w_ingre,                                              -- 82
                     @w_des_ingresos,                                       -- 83
                     @w_principal_login,                                    -- 84
                     @w_suplente_login,                                     -- 85
                     @w_en_id_tutor,                                        -- 86
                     @w_en_nom_tutor,                                       -- 87
                     @w_bloquear,                                           -- 88
                     @w_relacion,                                           -- 89
                     @w_desc_tipo_ced,                                      -- 90
                     @w_tipo_medio,                                         -- 91
                     @w_desc_tipo_medio,                                    -- 92
                     @w_categoria,                                          -- 93
                     @w_desc_categoria,                                     -- 94
                     @w_es_cliente,                                         -- 95
                     @w_referido_ext,                                       -- 96
                     @w_des_referido_ext,                                   -- 97
                     @w_carg_pub,                                           -- 98
                     @w_rel_carg_pub,                                       -- 99
                     @w_situacion_laboral,                                  -- 100
                     @w_des_situacion_laboral,                              -- 101
                     @w_bienes,                                             -- 102
                     @w_otros_ingresos,                                     -- 103
                     @w_origen_ingresos,                                    -- 104
                     @o_ea_estado,                                          -- 105
                     @o_ea_observacion_aut,                                 -- 106
                     @o_ea_contrato_firmado,                                -- 107
                     @o_ea_menor_edad,                                      -- 108
                     @o_ea_conocido_como,                                   -- 109
                     @o_ea_cliente_planilla,                                -- 110
                     @o_ea_cod_risk,                                        -- 111
                     @o_ea_empadronado,                                     -- 112
                     @o_ea_sector_eco,                                      -- 113
                     @o_ea_actividad,                                       -- 114
                     @o_c_funcionario,                                      -- 115
                     @o_arma_categoria,                                     -- 116
                     isnull(@o_ea_act_comp_kyc, 'N'),                       -- 117
                     isnull(@o_ea_fecha_act_kyc, '01/01/1900'),             -- 118
                     isnull(@o_ea_no_req_kyc_comp, 'N'),                    -- 119
                     isnull(@o_ea_act_perfiltran, 'N'),                     -- 120
                     isnull(@o_ea_fecha_act_perfiltran, '01/01/1900'),      -- 121
                     isnull(@o_ea_con_salario, 'N'),                        -- 122
                     isnull(@o_ea_fecha_consal, '01/01/1900'),              -- 123
                     isnull(@o_ea_sin_salario, 'N'),                        -- 124
                     isnull(@o_ea_fecha_sinsal, '01/01/1900'),              -- 125
                     @o_ea_lin_neg,                                         -- 126
                     @o_ea_seg_neg,                                         -- 127
                     @o_ea_val_id_check,                                    -- 128
                     @o_ea_ejecutivo_con,                                   -- 129
                     @o_ea_suc_gestion,                                     -- 130
                     @o_ea_constitucion,                                    -- 131
                     @o_ea_emp_planilla,                                    -- 132
                     @o_ea_remp_legal,                                      -- 133
                     @o_ea_apoderado_legal,                                 -- 134
                     @o_ea_actualizacion_cic,                               -- 135
                     @o_ea_fecha_act_cic,                                   -- 136
                     @o_ea_excepcion_cic,                                   -- 137
                     @o_ea_fuente_ing,                                      -- 138
                     @o_ea_act_prin,                                        -- 139
                     @o_ea_detalle,                                         -- 140
                     isnull(@o_ea_act_dol, 0),                              -- 141
                     @o_ea_cat_aml,                                         -- 142
                     @o_ea_observacion_vincula,                             -- 143
                     @o_ea_fecha_vincula,                                   -- 144
                     isnull(@o_c_verificado, 'N'),                          -- 145
                     @o_actividad_princ,                                    -- 146
                     @o_fuente_ing,                                         -- 147
                     @o_fecha_veri,                                         -- 148
                     @o_act_cic,                                            -- 149
                     @o_excep_cic,                                          -- 150
                     @o_ea_excepcion_pad,                                   -- 151
                     @w_discapacidad,                                       -- 152
                     @w_tipo_discapacidad,                                  -- 153
                     @w_desc_discapacidad,                                  -- 154
                     @w_ced_discapacidad,                                   -- 155
                     @w_asfi,                                               -- 156
                     @w_egresos,                                            -- 157
                     @w_desc_egresos,                                       -- 158
                     @w_ifi,                                                -- 159
                     @w_ea_desc_aml,                                        -- 160
                     @w_nacio_tipo_ced,                                     -- 161
                     @w_path_foto,                                          -- 162
                     @w_nit_id ,                                            -- 163
                     @w_nit_venc,                                           -- 164
                     @w_calif_cli,                                          -- 165
                     @w_descalif_cli                                        -- 166
                  */
               end
            else if @i_tipo = 'O'--Consulta de un Cliente desde Otros Productos
               begin --NO ELIMINAR CABECERAS, YA QUE SON REQUERIDAS POR ATMADMIN
                  -- ESTA OPCION NO ES UTILIZADA POR FUNCIONALIDADES DE CLIENTES.
                  select
                     'Número Documento'                = @w_cedula,                                             -- 2
                     'Nombres'                         = @w_nombre,                                             -- 7
                     'Primer Apellido'                 = @w_p_apellido,                                         -- 8
                     'Segundo Apellido'                = @w_s_apellido,                                         -- 9
                     'Sexo'                            = @w_sexo,                                               -- 12
                     'Código Sexo'                     = @w_cod_sex,                                            -- 13
                     'Pasaporte'                       = @w_pasaporte,                                          -- 20
                     'Código País'                     = @w_pais,                                               -- 21
                     'País'                            = @w_des_pais,                                           -- 22
                     'Código Sector'                   = @w_cod_sector,                                         -- 23
                     'Sector Económico'                = @w_des_sector,                                         -- 24
                     'Tipo de Persona'                 = @w_tipo,                                               -- 27
                     'Desc. Tipo de Persona'           = @w_des_tipo,                                           -- 28
                     'Oficial de Cuenta'               = @w_oficial,                                            -- 37
                     'Nombre Oficial de Cta.'          = @w_des_oficial,                                        -- 38
                     'Cod. Grupo Económico'            = @w_grupo,                                              -- 41
                     'Grupo Económico'                 = @w_des_grupo,                                          -- 42
                     'Malas Referencias'               = @w_mala_referencia,                                    -- 44
                     'Número RUC'                      = @w_nit,                                                -- 46
                     'Categoria'                       = @w_categoria,                                          -- 92
                     'Desc. Categoria'                 = @w_desc_categoria,                                     -- 93
                     'Cliente Planilla'                = @o_ea_cliente_planilla,                                -- 109
                     'Arma Categoria'                  = @o_arma_categoria,                                     -- 115
                     'País Nacimiento'               = @w_pais_nac,
                     'Provincia Nacimiento'            = @w_provincia_nac,
                     'Naturalizado'                    = @w_naturalizado,
                     'Forma Migratoria'                = @w_forma_migratoria,
                     'Nro Extranjero'                = @w_nro_extranjero,
                     'Calle Orig'                    = @w_calle_orig,
                     'Exterior Orig'                 = @w_exterior_orig,
                     'Estado Orig'                     = @w_estado_orig
                  return 0
               end

            --VERIFICAR SI TIENE DIRECCION SCA QA
            select @w_direccion = count (1)
            from cl_direccion where di_ente = @i_persona

            select isnull(@w_direccion,0)
         end
      else
         begin
            exec sp_cerror
               @t_debug      = @t_debug,
               @t_file       = @t_file,
               @t_from       = @w_sp_name,
               @i_num        = 1720075
               --NO CORRESPONDE CODIGO DE TRANSACCION
            return 1
         end
   end

if @i_operacion='V'
   begin
      if @t_trn = 172039
         begin
            if @i_tipo='N'
               begin
                  if exists (select en_ente
                           from cl_ente
                           where en_nit=@i_nit and en_subtipo='P')  and @i_nit is not null
                     begin
       exec sp_cerror  @t_debug    = @t_debug,
                           @t_file     = @t_file,
                           @t_from     = @w_sp_name,
                           @i_num      = 1720053
                        return 1
                     end
           end
         end
      else
         begin
            exec sp_cerror
               @t_debug      = @t_debug,
               @t_file       = @t_file,
               @t_from       = @w_sp_name,
               @i_num        = 1720075
               --NO CORRESPONDE CODIGO DE TRANSACCION
            return 1
         end
   end

--HELP
if @i_operacion = 'H'
   --CONSULTA UNICAMENTE DEL NOMBRE COMPLETO DE UNA PERSONA
   begin
      if @t_trn = 172040
         begin
            select  en_nomlar,
               en_tipo_ced,
               en_ced_ruc ,
               en_retencion,
               en_mala_referencia
            from    cl_ente
            where   en_ente = @i_persona
            and      en_subtipo = 'P'

            if @@rowcount = 0
               begin
                  exec sp_cerror  @t_debug    = @t_debug,
               @t_file     = @t_file,
                     @t_from     = @w_sp_name,
                     @i_num      = 1720074
                  --NO EXISTE DATO SOLICITADO
                  return 1
               end
         end
      else
         begin
            exec sp_cerror
               @t_debug      = @t_debug,
               @t_file       = @t_file,
               @t_from       = @w_sp_name,
               @i_num        = 1720075
               --NO CORRESPONDE CODIGO DE TRANSACCION
            return 1
         end
   end

if @i_operacion = 'C' --Consulta los datos del conyuge
begin
   select @w_act_cny = pa_char from cobis..cl_parametro
   where pa_nemonico='ACTCNY' AND  pa_producto='CLI'

   select @w_tipo_doc_cny = pa_char from cobis..cl_parametro
   where pa_nemonico='TIDOCY' AND  pa_producto='CLI'

   if not exists (select 1 from cobis..cl_instancia where in_ente_i = @i_persona
      AND in_relacion = (select pa_tinyint from cobis..cl_parametro where pa_nemonico = 'CONY' and pa_producto = 'CLI'))
   begin
      select
         'codigo'                           = 0,
         'nombre'                           = null,
         'segNombre'                        = null,
         'apellidoPat'                      = null,
         'apellidoMat'                      = null,
         'tipoDocument'                     = null,
         'curp'                             = null,
         'rfc'                              = null,
         'fechaVenIdentif'                  = null,
         'fechaNacimiento'                  = null,
         'sexo'                             = null,
         'lugarNacimiento'                  = null,
         'paisNacimiento'                   = null,
         'naturalizado'                     = null,
         'formaMigratoria'                  = '',
         'numeroExtranjero'                 = '',
         'calleOrigen'                      = '',
         'numeroOrigen'                     = '',
         'estadoOrigen'                     = '',
         'escolaridad'                      = null,
         'ocupacion'                        = null,
         'actividad'                        = null,
         'dependientes'                     = 0,
         'tipoIdentificacion'               = @w_tipo_doc_cny,
         'numeroIdentificacion'             = '',
         'email'                            = '',
         'actividadConyuge'                 = '',
         'ingresoMensual'                   = 0.0,
         'genero'                           = '',
         'tipoIddentificacionPersonal'      = '',
         'numeroIddentificacionPersonal'    = '',
         'tipoIddentificacionTributario'    = '',
         'numeroIddentificacionTributario'  = '',
         'tipoIddentificacionAdicional'     = '',
         'numeroIddentificacionTributario'  = '',
         'tipoResidencia'                   = '',
         'apellidoCasada'                   = '',
         'conComo'                          = '',
         'ciudadEmi'                        = null,
         'FechaEmi'                         = null,
         'TelefRecados'                     = '',
		 'InfLaboral'                       = null  
         
      from cl_ente where en_ente = @i_persona

   end
   else
   begin
      select @w_email_c = isnull(di_descripcion,'')
      from cobis..cl_direccion where di_tipo = 'CE'
         and di_ente = (select top 1 in_ente_d from cobis..cl_instancia where in_ente_i = @i_persona
         AND in_relacion = (select pa_tinyint from cobis..cl_parametro where pa_nemonico = 'CONY' and pa_producto = 'CLI')
        order by in_ente_d desc)
      select @w_con_como_c      = ea_conocido_como, 
             @w_telef_recados_c = ea_telef_recados  
      from cobis.dbo.cl_ente_aux 
      where ea_ente = (select top 1 in_ente_d from cobis..cl_instancia where in_ente_i = @i_persona
         AND in_relacion = (select pa_tinyint from cobis..cl_parametro where pa_nemonico = 'CONY' and pa_producto = 'CLI')
        order by in_ente_d desc) --209 es Conyuge
      
      select
         'codigo'                           = en_ente,
         'nombre'                           = en_nombre,
         'segNombre'                        = p_s_nombre,
         'apellidoPat'                      = p_p_apellido,
         'apellidoMat'                      = p_s_apellido,
         'tipoDocument'                     = en_tipo_ced,
         'curp'                             = en_ced_ruc,
         'rfc'                              = en_nit,
         'fechaVenIdentif'                  = convert(char(10), p_fecha_expira, 103),
         'fechaNacimiento'                  = convert(char(10), p_fecha_nac, 103),
         'sexo'                             = p_sexo,
         'lugarNacimiento'                  = en_provincia_nac,
         'paisNacimiento'                   = isnull(en_pais_nac,'0'),
         'naturalizado'                     = isnull(en_naturalizado,''),
         'formaMigratoria'                  = isnull(en_forma_migratoria,''),
         'numeroExtranjero'                 = isnull(en_nro_extranjero,''),
         'calleOrigen'                      = isnull(en_calle_orig,''),
         'numeroOrigen'                     = isnull(en_exterior_orig,''),
         'estadoOrigen'                     = isnull(en_estado_orig,''),
         'escolaridad'                      = p_nivel_estudio,
         'ocupacion'                        = p_ocupacion,
         'actividad'                        = en_actividad,
         'dependientes'                     = isnull(p_num_cargas,0),
         'tipoIdentificacion'               = isnull(en_tipo_iden, @w_tipo_doc_cny),
         'numeroIdentificacion'             = isnull(en_numero_iden,''),
         'email'                            = @w_email_c,
         'actividadConyuge'                 = en_actividad_desc,
         'ingresoMensual'                   = null,
         'genero'                           = p_genero,
         'tipoIddentificacionPersonal'      = en_tipo_ced,
         'numeroIddentificacionPersonal'    = en_ced_ruc,
         'tipoIddentificacionTributario'    = en_tipo_doc_tributario,
         'numeroIddentificacionTributario'  = en_rfc,
         'tipoIddentificacionAdicional'     = en_tipo_iden,
         'numeroIddentificacionTributario'  = en_numero_iden,
         'tipoResidencia'                   = en_tipo_residencia,
         'domicilioPaisOrigen'              = en_calle_orig,
         'numeroExterior'                   = en_exterior_orig,
         'estado'                           = en_estado_orig,
         'apellidoCasada'                   = p_c_apellido,
         'conComo'                          = @w_con_como_c,
         'ciudadEmi'                        = en_ciudad_emision,
         'FechaEmi'                         = convert(char(10), p_fecha_emision, 103),
         'TelefRecados'                     = @w_telef_recados_c,
		 'InfLaboral'                       = en_inf_laboral   
      from cl_ente
      where en_ente = (select top 1 in_ente_d from cobis..cl_instancia where in_ente_i = @i_persona
         AND in_relacion = (select pa_tinyint from cobis..cl_parametro where pa_nemonico = 'CONY' and pa_producto = 'CLI')
        order by in_ente_d desc) --209 es Conyuge
   end
end

if @i_operacion = 'Y'
   begin
      if @t_trn=172040
         begin
            select @o_retencion = (case a.en_retencion when 'N' then 'S' else 'N' end),
                   --@o_nit       = b.ea_nit,--JAN Inc63931
                   @o_nit       = case a.en_subtipo when 'C' then (case a.en_tipo_ced when 'NIT' then a.en_ced_ruc else null end) else b.ea_nit end,
                   @o_sub_tipo  = a.en_subtipo,
                   @o_pjuridica = a.c_segmento,
                   @o_ced_ruc   = a.en_ced_ruc
            from cl_ente a
            inner join cl_ente_aux b on (a.en_ente = b.ea_ente)
            where a.en_ente    = @i_persona

            if @@rowcount = 0
               begin
                  exec sp_cerror
                     @t_debug    = @t_debug,
                     @t_file     = @t_file,
                     @t_from     = @w_sp_name,
                     @i_num      = 1720074
                     --NO EXISTE DATO SOLICITADO
                  return 1
               end
         end
   end

if @i_operacion = 'T' -- Datos complementarios
begin

    if (@t_trn <> 172112)
    begin 
       /* Tipo de transaccion no corresponde */ 
       exec cobis..sp_cerror 
            @t_debug = @t_debug, 
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 1720275
       return 1720275
    end

    --Obtener números de referencia pantalla datos complementarios
    select @w_num_referencia = min(rp_referencia)--rp_telefono_d
    from cobis..cl_ref_personal
    where rp_persona = @i_persona

    select  @w_telef_referencia_uno = rp_telefono_d
    from cobis..cl_ref_personal
    where rp_persona   = @i_persona
    and   rp_referencia= @w_num_referencia

    if @w_telef_referencia_uno is not null
    begin
         select  @w_telef_referencia_dos = rp_telefono_d
         from cobis..cl_ref_personal
         where rp_persona   = @i_persona
         and   rp_referencia> @w_num_referencia
    end

    select @w_pasaporte                  = a.p_pasaporte,
           @w_telefono_recados           = ea_telef_recados,
           @w_numero_ife                 = ea_numero_ife   ,
           @w_numero_serie_firma_elect   = ea_num_serie_firma,
           @w_persona_recados            = ea_persona_recados,
           @w_antecedentes_buro          = ea_antecedente_buro
    from  cl_ente as a
    inner join cl_ente_aux b on (a.en_ente = b.ea_ente)
    where a.en_subtipo = 'P'
    and a.en_ente    = @i_persona

    select
      'telefonoRecados'         = @w_telefono_recados,                                   -- 1
      'numeroIfe'               = @w_numero_ife,                                         -- 2
      'numeroSerieFirmaElect'   = @w_numero_serie_firma_elect,                           -- 3
      'personaRecados'          = @w_persona_recados,                                    -- 4
      'antecedentesBuro'        = CASE WHEN @w_antecedentes_buro ='S' THEN 'true'        -- 5
                                  WHEN @w_antecedentes_buro ='N' THEN 'false'
                                  end,
      'telefReferenciaUno'      = @w_telef_referencia_uno,                               -- 6
      'telefReferenciaDos'      = @w_telef_referencia_dos ,                              -- 7
      'pasaporte'               = @w_pasaporte,                                          -- 8
      'codigoCliente'           = @i_persona                                             -- 9
end

if @i_operacion = 'A' -- Datos de Conozca su Cliente
begin
   if @t_trn = 172039
   begin
      select @w_act_economica       = ente.en_actividad,
            @w_donde_labora         = ente.en_inf_laboral,
            @w_ingresos_mensuales   = ente.en_ingre,
            @w_operacion            = ente.en_tipo_operacion,
            @w_entidad_federativa   = ente.en_provincia_act,
            @w_lugar_act            = ente.en_lugar_act,
            @w_pregunta1            = aux.ea_ingreso_legal,
            @w_pregunta2            = aux.ea_actividad_legal,
            @w_pregunta3            = aux.ea_otra_cuenta_banc,
            @w_provincia_res        = aux.ea_provincia_res
      from  cl_ente ente, cl_ente_aux aux
      where ente.en_ente = @i_persona
      and aux.ea_ente = @i_persona
      
      select @w_nivel_cuenta        = itr_cat_nivel,
             @w_cat_num_trn_mes_ini = itr_cat_num_trn_mes_ini,
             @w_cat_mto_trn_mes_ini = itr_cat_mto_trn_mes_ini,
             @w_cat_sdo_prom_mes_ini= itr_cat_sdo_prom_mes_ini,
			 @w_can_anticipada      = itr_can_anticipada,
			 @w_orig_fondo          = itr_orig_fondo,
			 @w_pag_adcapital       = itr_pag_adcapital,
			 @w_cuota_adi           = itr_cuota_adi
        from cobis..cl_info_trn_riesgo
       where itr_ente = @i_persona
        
     select
         'actividadEconomica'       = @w_act_economica,          -- 1
         'dondeLabora'              = @w_donde_labora,           -- 2
         'ingresosMensaules'        = @w_ingresos_mensuales,     -- 3
         'operacion'                = @w_operacion,              -- 4
         'entidadFederativa'        = @w_entidad_federativa,     -- 5
         'lugarActividad'           = @w_lugar_act,              -- 6
         'pagoAdicional'            = @w_pregunta1,              -- 7
         'pregunta2'                = @w_pregunta2,              -- 8
         'pregunta3'                = @w_pregunta3,              -- 9
         'entidadResidencia'        = @w_provincia_res,          -- 10
         'nivelCuenta'              = @w_nivel_cuenta,           -- 11
         'idNumTrnMesIni'           = @w_cat_num_trn_mes_ini,    -- 12
         'idMtoTrnMesIni'           = @w_cat_mto_trn_mes_ini,    -- 13
         'cancelaAntCred'           = @w_cat_sdo_prom_mes_ini,   -- 14
		 'CancelaAnticipada'        = @w_can_anticipada,         -- 15 
		 'origenFondos'             = @w_orig_fondo,             -- 16
         'PagoAdCapital'            = @w_pag_adcapital,		     -- 17 
		 'cuotaAdicional'           = @w_cuota_adi               -- 18
   end
end

if @i_operacion = 'F' -- Datos de Residencia Fiscales
begin
    if @t_trn <> 172039
      begin 
        /* Tipo de transaccion no corresponde */ 
        exec cobis..sp_cerror 
             @t_debug = @t_debug, 
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end
    if exists (select ea_ente from cl_ente_aux where ea_ente=@i_persona)
    begin
      select @w_fatca        = aux.ea_fatca,
             @w_crs          = aux.ea_crs
        from cl_ente_aux aux
       where aux.ea_ente = @i_persona

      select 'pregunta1'         = @w_fatca,  -- 1
             'pregunta2'         = @w_crs     -- 2
    end
end
if @i_operacion = 'S' -- Consulta general clientes / prospectos
begin
    if exists (select 1 from cl_ente ce where en_ced_ruc = @i_identificacion)
    begin
		select @i_persona = en_ente
		  from cl_ente ce 
         where en_ced_ruc = @i_identificacion
	end
	else
	begin
		exec sp_cerror
               @t_debug      = @t_debug,
               @t_file       = @t_file,
               @t_from       = @w_sp_name,
               @i_num        = 1720035
               --NO EXISTE EL CLIENTE
        return 1
	end
	if @i_persona <> 0
	begin
	    select @w_email_c = isnull(di_descripcion,'')
          from cobis..cl_direccion where di_tipo = 'CE'
           and di_ente = @i_persona
		select @w_con_como_c      = ea_conocido_como, 
               @w_telef_recados_c = ea_telef_recados  
         from  cobis.dbo.cl_ente_aux 
         where ea_ente = @i_persona
		select @w_tipo_doc_cny = pa_char 
		  from cobis..cl_parametro
         where pa_nemonico='TIDOCY' AND  pa_producto='CLI'
		
		select
         'codigo'                           = en_ente,
         'nombre'                           = en_nombre,
         'segNombre'                        = p_s_nombre,
         'apellidoPat'                      = p_p_apellido,
         'apellidoMat'                      = p_s_apellido,
         'tipoDocument'                     = en_tipo_ced,
         'curp'                             = en_ced_ruc,
         'rfc'                              = en_nit,
         'fechaVenIdentif'                  = convert(char(10), p_fecha_expira, @i_formato_fecha),
         'fechaNacimiento'                  = convert(char(10), p_fecha_nac, @i_formato_fecha),
         'sexo'                             = p_sexo,
         'lugarNacimiento'                  = en_provincia_nac,
         'paisNacimiento'                   = isnull(en_pais_nac,'0'),
         'naturalizado'                     = isnull(en_naturalizado,''),
         'formaMigratoria'                  = isnull(en_forma_migratoria,''),
         'numeroExtranjero'                 = isnull(en_nro_extranjero,''),
         'calleOrigen'                      = isnull(en_calle_orig,''),
         'numeroOrigen'                     = isnull(en_exterior_orig,''),
         'estadoOrigen'                     = isnull(en_estado_orig,''),
         'escolaridad'                      = p_nivel_estudio,
         'ocupacion'                        = p_ocupacion,
         'actividad'                        = en_actividad,
         'dependientes'                     = isnull(p_num_cargas,0),
         'tipoIdentificacion'               = isnull(en_tipo_iden, @w_tipo_doc_cny),
         'numeroIdentificacion'             = isnull(en_numero_iden,''),
		 'email'                            = @w_email_c,
         'actividadConyuge'                 = en_actividad_desc,
         'ingresoMensual'                   = null,
         'genero'                           = p_genero,
         'tipoIddentificacionPersonal'      = en_tipo_ced,
         'numeroIddentificacionPersonal'    = en_ced_ruc,
         'tipoIddentificacionTributario'    = en_tipo_doc_tributario,
         'numeroIddentificacionTributario'  = en_rfc,
         'tipoIddentificacionAdicional'     = en_tipo_iden,
         'numeroIddentificacionTributario'  = en_numero_iden,
         'tipoResidencia'                   = en_tipo_residencia,
         'domicilioPaisOrigen'              = en_calle_orig,
         'numeroExterior'                   = en_exterior_orig,
         'estado'                           = en_estado_orig,
         'apellidoCasada'                   = p_c_apellido,
         'conComo'                          = @w_con_como_c,
         'ciudadEmi'                        = en_ciudad_emision,
         'FechaEmi'                         = convert(char(10), p_fecha_emision, @i_formato_fecha),
         'TelefRecados'                     = @w_telef_recados_c,
         'lugarTrabajo'                     = en_inf_laboral
      from cl_ente
	  where en_ente = @i_persona
	end
end
if @i_operacion = 'B' -- Valida si el cliente aceptó consultar sus datos al Buró
begin
--VALIDACION AL CONSULTAR DESDE LA CREACIÓN DE SOLICITUDES INDIVIDUALES Y GRUPALES
   select @w_antecedentes_buro = ea_antecedente_buro
   from cl_ente_aux
   where ea_ente = @i_persona
   if @w_antecedentes_buro = 'N'
   begin
      exec sp_cerror
      @t_debug      = @t_debug,
      @t_file       = @t_file,
      @t_from       = @w_sp_name,
      @i_num        = 1720666
      --ERROR, CLIENTE NO AUTORIZADO PARA CONSULTAR BURO
      return 1          
   end
end

return 0

go
