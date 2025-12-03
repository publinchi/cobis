/********************************************************************/
/*   NOMBRE LOGICO:         sp_persona_upd                          */
/*   NOMBRE FISICO:         persona_upd.sp                          */
/*   BASE DE DATOS:         cobis                                   */
/*   PRODUCTO:              Clientes                                */
/*   DISENADO POR:          JMEG                                    */
/*   FECHA DE ESCRITURA:    30-Abr-2019                             */
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
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Actualiza la información de una persona natural                */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA          AUTOR              RAZON                        */
/*   30-Abr-2019    JMEG.         Emision Inicial                   */
/*   24-May-2019    RIGG.         Agrega @i_tipo_iden,@i_numero_iden*/
/*   06-Dic-2019    AMG.          Se modifica validación de cédula  */
/*                                identidad                         */
/*   01-Jun-2020    A. Hurtado.   Agrega @i_inf_laboral,            */
/*                                @i_tipo_operacion,                */
/*                                @i_provincia_act, @i_lugar_act    */
/*                                @i_ea_ingreso_legal,              */
/*                                @i_ea_actividad_legal             */
/*   07-Jul-2020    AMGE          Renombre sp_actualizar_p_natural  */
/*                                cambia a sp_persona_upd           */
/*   15-Oct-2020    MBA           Uso de la variable @s_culture     */
/*   24-Nov-2020    EGL           Agregando variable @i_genero      */
/*   03-Dic-2020    EGL           Agregando variable @i_genero      */
/*   09-Dic-2020    IYU           Eliminar instancia y correcciontrn*/
/*                                sp_registra_ident                 */
/*   14-Dic-2020    IYU           Correcta operacion de registro de */
/*                                identificacion                    */
/*   15-Dic-2020    IYU           Eliminar relacion con conyugue    */
/*   12-Ene-2021    IYU           Actualizacion Tipos Identificacion*/
/*   31-Jun-2021    COB           Agregar nuevos campos PEP         */
/*   17-Ene-2023    BDU           S762873: Se agregan nuevos campos */
/*   28-Mar-2023    EBA           S763654: Actualizacion client app */
/*                                movil                             */
/*   28-Mar-2023    Bruno Duenas. Agregar pseudonimo                */
/*   29-May-2023    P. Jarrin.    BM Sincronización Medios - S832369*/
/*   27-Jun-2023    O. Guaño      S851475: Se consulta actividad    */
/*                                     econóimica para actualización*/ 
/*   30-Jun-2023   E. Báez        S849151 se realiza la conversión  */
/*                                de los tipos de documento         */
/*                                principal y tributario que vienen */
/*                                desde la app enbase a la máscara  */
/*                                parametrizada.                    */
/*   28/Junio/23    BDU           S849165 Se quita 'DE' del apellido*/
/*   10/Julio/23    EBA           B850916 Se obtiene valor Soltero  */
/*                                del catalogo estado civil         */
/*   16/Agosto/23   EBA           R213339 Se valida si la actividad */
/*                                económica llega vacía.            */
/*   24/Agosto/23   BDU           RR213480  Se permite fecha de fin */
/*                                de PEP vacía.                     */
/*   09/Sept/23     BDU           R214440-Sincronizacion automatica */
/*   20/Oct/2023    BDU           R217831-Ajuste validacion error   */
/*   15/11/2023     OGU           R219376: Se asocia la oficina del */
/*                                oficial                           */
/*   22/12/23       BDU           R221783-Validar provincia 0       */
/*   22/01/24       BDU           R224055-Validar oficina app       */
/*   06/03/24       BDU           R228486: Se corrige validación DUI*/
/*   26/07/2024     BDU           R241331:Se agrega valor por       */
/*                                defecto ofi                       */
/*   11/12/2024     GRO           R248888:campos conozca su cliente */
/*   16/09/2025     BDU           R:campos conozca su cliente */
/********************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_persona_upd')
   drop proc sp_persona_upd
go

create proc sp_persona_upd(
  @s_user                    login,
  @s_term                    varchar(32),
  @s_date                    datetime,
  @s_ofi                     int           = null,
  @s_ssn                     int           = null,
  @s_srv                     varchar(30)   = null,
  @s_lsrv                    varchar(30)   = null,
  @s_culture                 varchar(10)   = 'NEUTRAL',
  @t_trn                     int,
  @t_show_version            bit           = 0,    -- MOSTRAR LA VERSION DEL PROGRAMA
  @t_debug                   char(1)       = 'N',
  @t_file                    varchar(10)   = null,
  @i_operacion               char(1),              -- Accion de programa
  @i_batch                   char(1)       = 'N',  -- Es proceso batch? S/N
  @i_verificado              char(1)       = 'N',  -- Datos del Clientes fueron verificados?
  @i_persona                 int           = null, -- Codigo del ente
  @i_nombre                  varchar(50)   = null, -- Primer nombre del ente
  @i_p_apellido              varchar(30)   = null, -- Primer apellido del ente
  @i_s_apellido              varchar(30)   = null, -- Segundo apellido del ente
  @i_sexo                    char(1)       = null, -- Codigo del sexo del ente
  @i_genero                  char(2)       = null, -- Codigo del genero del ente
  @i_fecha_nac               datetime      = null, -- Fecha de nacimiento del ente
  @i_tipo_ced                char(4)       = null, -- Tipo de identificacion del ente
  @i_tipo_tributario         char(4)       = null,  -- tipo identificacion tributario
  @i_cedula                  varchar(20)   = null, -- Numero de identificacion del ente
  @i_pasaporte               varchar(20)   = null, -- Numero de pasaporte del ente
  @i_pais                    smallint      = null, -- pais emisor del pasaporte
  @i_ciudad_nac              int           = null, -- Codigo del municipio o pais de nacimiento
  @i_lugar_doc               int           = null, -- Codigo del municipio o pais de documento
  @i_nivel_estudio           catalogo      = null, -- Nivel de estudio de la persona
  @i_tipo_vivienda           catalogo      = null, -- Tipo de vivienda de la persona
  @i_profesion               catalogo      = null, -- Codigo de la profesion de la persona
  @i_estado_civil            catalogo      = null, -- Codigo  del estado civil de la persona
  @i_num_cargas              tinyint       = null, -- Numero de hijos
  @i_nivel_ing               money         = null, -- No se utiliza
  @i_nivel_egr               money         = null, -- No se utiliza
  @i_filial                  tinyint       = null, -- Codigo de la filial
  @i_oficina                 smallint      = null, -- Codigo de la oficina
  @i_tipo                    catalogo      = null, -- Codigo de la SIB
  @i_grupo                   int           = null, -- Codigo del grupo
  @i_oficial                 smallint      = null, -- Codigo del oficial del ente
  @i_oficial_sup             smallint      = null, -- Codigo del oficial suplente del ente
  @i_retencion               char(1)       = null,  -- Indicador si el ente es sujeto a impuestos
  @i_exc_sipla               char(1)       = null, -- No se utiliza
  @i_exc_por2                char(1)       = null, -- No se utiliza
  @i_asosciada               catalogo      = null, -- No se utiliza
  @i_tipo_vinculacion        catalogo      = null, -- Codigo del tipo de vinculacion de quien presento al cliente
  @i_actividad               catalogo      = null, -- Codigo de la actividad del ente
  @i_comentario              varchar(254)  = null, -- Comentario u observacion adicional del ente
  @i_fecha_emision           datetime      = null, -- No se utiliza
  @i_fecha_expira            datetime      = null, -- Fecha de expiracion del pasaporte del ente
  @i_sector                  catalogo      = null, -- No se utiliza
  @i_referido                smallint      = null, -- Codigo de la persona que presento al cliente
  @i_gran_contribuyente      char(1)       = null, -- No se utiliza
  @i_situacion_cliente       catalogo      = null, -- Situacion actual del cliente
  @i_patrim_tec              money         = null, -- Patrimonio bruto
  @i_fecha_patrim_bruto      datetime      = null, -- Fecha del patrimonio bruto
  @i_total_activos           money         = null, -- Total de activos
  @i_rep_superban            char(1)       = null, -- Indicador si es reportado por la SIB
  @i_preferen                char(1)       = null, -- Indicador si es cliente preferencial
  @i_cem                     money         = null, -- Cupo de endeudamiento maximo
  @i_c_apellido              varchar(30)   = null, -- Apellido casada del ente
  @i_segnombre               varchar(50)   = null, -- Segundo nombre del ente
  @i_nit                     varchar(30)   = null, -- NIT del ente
  @i_depart_doc              smallint      = null, -- Codigo del departamento
  @i_numord                  char(4)       = null, -- Codigo de orden CV
  @i_promotor                varchar(10)   = null, -- Codigo del promotor del cliente
  @i_doc_validado            char(1)       = null,   -- Indicador si la informacion del cliente esta verificada
  @i_nacionalidad            int           = null, -- Codigo del pais de la nacionalidad del cliente
  @i_codigo                  char(10)      = null, -- Codigo pais centroamericano
  @i_inss                    varchar(15)   = null, -- Numero de seguro
  @i_licencia                varchar(30)   = null, -- Numero de licencia
  @i_ingre                   varchar(10)   = null, -- Codigo de ingresos
  @i_en_id_tutor             varchar(20)   = null, --ID del Tutor
  @i_en_nom_tutor            varchar(60)   = null, --Tutor
  @i_digito                  char(2)       = null,
  @i_valprov                 char(1)       = null,
  @i_categoria               catalogo      = null, --CVA Abr-23-07
  @i_referidor_ecu           int           = null, --Campo referidor CL00005 OPA
  @i_carg_pub                varchar(200)  = null,
  @i_rel_carg_pub            varchar(10)   = null,
  @i_situacion_laboral       varchar(5)    = null, -- ini CL00031 RVI
  @i_bienes                  char(1)       = null,
  @i_otros_ingresos          money         = null,
  @i_origen_ingresos         descripcion   = null, -- fin CL00031 RVI
  @i_ejecutar                char(1)       = 'N',  --MALDAZ 06/25/2012 HSBC CLI-0565
  @i_ea_estado               catalogo      = null,
  @i_ea_observacion_aut      varchar(255)  = null,
  @i_ea_contrato_firmado     char(1)       = null,
  @i_ea_menor_edad           char(1)       = null,
  @i_ea_conocido_como        varchar(255)  = null,
  @i_ea_cliente_planilla     char(1)       = null,
  @i_ea_cod_risk             varchar(20)   = null,
  @i_ea_sector_eco           catalogo      = null,
  @i_ea_actividad            catalogo      = null,
  @i_ea_empadronado          char(1)       = null,
  @i_ea_lin_neg              catalogo      = null,
  @i_ea_seg_neg              catalogo      = null,
  @i_ea_val_id_check         catalogo      = null,
  @i_ea_ejecutivo_con        int           = null,
  @i_ea_suc_gestion          smallint      = null,
  @i_ea_constitucion         smallint      = null,
  @i_ea_remp_legal           int           = null,
  @i_ea_apoderado_legal      int           = null,
  @i_ea_act_comp_kyc         char(1)       = null,
  @i_ea_fecha_act_kyc        datetime      = null,
  @i_ea_no_req_kyc_comp      char(1)       = null,
  @i_ea_act_perfiltran       char(1)       = null,
  @i_ea_fecha_act_perfiltran datetime      = null,
  @i_ea_con_salario          char(1)       = null,
  @i_ea_fecha_consal         datetime      = null,
  @i_ea_sin_salario          char(1)       = null,
  @i_ea_fecha_sinsal         datetime      = null,
  @i_ea_actualizacion_cic    char(1)       = null,
  @i_ea_fecha_act_cic        datetime      = null,
  @i_ea_fuente_ing           catalogo      = null,
  @i_ea_act_prin             catalogo      = null,
  @i_ea_detalle              varchar(255)  = null,
  @i_ea_act_dol              money         = null,
  @i_ea_cat_aml              catalogo      = null,
  @i_fecha_verifi            datetime      = null,
  @i_ea_discapacidad         char(1)       = null,    --PRESENCIA DE DISCAPACIDAD
  @i_ea_tipo_discapacidad    catalogo      = null,    --TIPO DE DISCAPACIDAD
  @i_ea_ced_discapacidad     varchar(30)   = null,    --CEDULA DE DISCAPACIDAD
  @i_egresos                 catalogo      = null,
  @i_ifi                     char(1)       = null,
  @i_asfi                    char(1)       = null,
  @i_path_foto               varchar(50)   = null,
  @i_nit_venc                datetime      = null,
  @i_emproblemado            char(1)       = null, --santander
  @i_dinero_transac          money         = null,
  @i_pep                     char(1)       = null,
  @i_mnt_pasivo              money         = null,
  @i_vinculacion             char(1)       = null,
  @i_ant_nego                int           = null,
  @i_ventas                  money         = null,
  @i_ct_ventas               money         = null,
  @i_ct_operativos           money         = null,
  @i_ea_indefinido           char(1)       = null,  --MTA nuevo campo no mapeado
  @i_persona_pub             char(1)       = null,
  @i_ing_SN                  char(1)       = null,  --Tiene otros Ingresos?
  @i_otringr                 VARCHAR(10)   = null,  --Otras fuentes de Ingresos
  @i_depa_nac                SMALLINT      = null,  --Provincia de nacimiento
  @i_nac_aux                 int           = null,  --Nacionalidad que se muestra en front-end
  @i_pais_emi                smallint      = null,  --Pais de emision del pasaporte
  @i_ea_nro_ciclo_oi         int           = null,
  @i_ea_cta_banco            varchar(45)   = null,
  @i_banco                   varchar(20)   = null,
  @i_estado_std              catalogo      = null,
  @i_calificacion            catalogo      = null,
  @i_calif_cliente           catalogo      = null,
  @i_partner                 char(1)       = null,
  @i_lista_negra             char(1)       = null,
  @i_telefono_recados        varchar(10)   = null,
  @i_numero_ife              varchar(13)   = null,
  @i_numero_serie_firma      varchar(20)   = null,
  @i_persona_recados         varchar(60)   = null,
  @i_antecedentes_buro       varchar(2)    = null,
  @i_pais_nac                varchar(20)   = null,
  @i_provincia_nac           varchar(20)   = null,
  @i_naturalizado            char(1)       = null,
  @i_forma_migratoria        varchar(64)   = null,
  @i_nro_extranjero          varchar(64)   = null,
  @i_calle_orig              varchar(70)   = null,
  @i_exterior_orig           varchar(40)   = null,
  @i_estado_orig             varchar(40)   = null,
  @i_tipo_iden               varchar(13)   = null,
  @i_numero_iden             varchar(20)   = null,
  @i_lug_trab                varchar(200)  = null,
  @i_inf_laboral             varchar(200)  = null, --know your customer workPlace
  @i_tipo_operacion          varchar(10)   = null,
  @i_provincia_act           varchar(10)   = null,
  @i_lugar_act               varchar(100)  = null,
  @i_ea_ingreso_legal        char(1)       = null,
  @i_ea_actividad_legal      char(1)       = null,
  @i_ea_otra_cuenta          char(1)       = null,
  @i_fatca                   char(1)       = null,
  @i_crs                     char(1)       = null,
  @i_ocupacion               varchar(20)   = null,
  @i_origen                  char(1)       = 'F',
  @i_provincia_res           varchar(10)   = null,
  @i_nivel_cuenta            catalogo      = null,
  @i_cat_num_trn_mes_ini     catalogo      = null,
  @i_cat_mto_trn_mes_ini     catalogo      = null,
  @i_cat_sdo_prom_mes_ini    catalogo      = null,
  @i_cat_gpo_mtz_riesgo      catalogo      = null,
  @i_pto_num_trn_mes_ini     int           = null,
  @i_pto_mto_trn_mes_ini     int           = null,
  @i_pto_sdo_prom_mes_ini    int           = null,
  @i_can_anticipada          char(1)       = null, --R248888: cancelar anticipadamente el crédito
  @i_orig_fondo              varchar(20)   = null, --R248888: origen de fondos
  @i_pag_adcapital           char(1)       = null, --R248888: abonar en concepto de pago de capital
  @i_cuota_adi               money         = null, --R248888: cuota adicional
  @i_tipo_residencia         varchar(4)    = null,
  @i_codigo_pep_relac        int           = null,
  @i_nombre_pep_relac        varchar(100)  = null,
  @i_fecha_inicio_pep        datetime      = null,
  @i_fecha_fin_pep           datetime      = null,
  @i_tipo_pep                catalogo      = null,
  @i_is_app                  char(1)       = 'N',
  @i_pseudonimo              descripcion   = null, -- Pseudonimo del cliente 
  @o_estado                  catalogo      = null  output,
  @o_vinculado               catalogo      = null  output
)
as
declare
  @w_sp_name                    varchar(32),
  @w_sp_msg                     varchar(132),
  @w_mayoria_edad               int,
  @w_nemocda                    catalogo,
  @w_nemovda                    catalogo,
  @w_nemomed                    catalogo,
  @w_error                      int,
  @w_nat_jur_hogar              catalogo,
  @w_funcionario                login,
  @w_cedula                     numero,
  @w_tipo_ced                   char(4),
  @w_oficial                    int,
  @w_nombre_completo            varchar(200),
  @w_conyuge                    int,
  @w_relacion_ca                int,
  @w_pais_local                 catalogo,
  @w_fatca                      char(1),
  @w_crs                        char(1),
  @v_fatca                      char(1),
  @v_crs                        char(1),
  @w_nombre_pep_relac           varchar(100),
  @w_num                        int,
  @w_diff                       int,
  @w_date                       datetime,
  @w_bloqueo                    char(1),
  @w_nacionalidad               varchar(10),
  @w_longitud                   int,
  @w_valida_long                int,
  @w_respuesta                  int,
  @w_pseudonimo_par             tinyint,
  @w_telefono_recados_a         varchar(10),
  @w_telefono_recados_d         varchar(10),
  @w_linked_s                   varchar(32),
  @w_sp_local_name              varchar(30),
  @w_bdd                        varchar(32),
  @w_sp_linked_s                varchar(255),
  @w_mascara                    varchar(30),
  @w_doc_prin_mascara           varchar(30),
  @w_doc_trib_mascara           varchar(30),
  @w_default_estado_civil       catalogo,
  -- R214440-Sincronizacion automatica
  @w_sincroniza      char(1),
  @w_ofi_app         smallint

select
@w_sp_name       = 'sp_persona_upd',
@w_sp_msg        = ''

/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

if @i_is_app = 'S'
begin
   select @i_genero = @i_sexo
   if @i_actividad is null or @i_actividad = '' or @i_actividad = '000'
   begin
      select @i_actividad = en_actividad
        from cobis..cl_ente
       where en_ente = @i_persona
   end
   
   select @i_oficina = fu_oficina                         --R219376: Se asocia la oficina del oficial
     from cobis..cc_oficial, cobis..cl_funcionario
    where oc_oficial = @i_oficial
      and fu_funcionario = oc_funcionario
end

---- EJECUTAR SP DE LA CULTURA ---------------------------------------
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out


/* CARGAR PARAMETROS GENERALES */
select @w_mayoria_edad = pa_tinyint                   from cobis..cl_parametro where pa_producto = 'ADM' and pa_nemonico = 'MDE'
select @w_pais_local   = convert(varchar,pa_smallint) from cobis..cl_parametro where pa_nemonico = 'CP'  and pa_producto = 'CLI'
select @w_nemocda      = pa_char                      from cobis..cl_parametro where pa_producto = 'CLI' and pa_nemonico = 'CDA'
select @w_nemovda      = pa_char                      from cobis..cl_parametro where pa_producto = 'CLI' and pa_nemonico = 'VDA'
select @w_nemomed      = pa_char                      from cobis..cl_parametro where pa_producto = 'CLI' and pa_nemonico = 'MED'


/* SEGURIDADES */
if @i_operacion = 'R'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end
if @i_operacion = 'C'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end
if @i_operacion = 'B'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end
if @i_operacion = 'E'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end
if @i_operacion = 'M'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end
if @i_operacion = 'A'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end
if @i_operacion = 'D'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end
if @i_operacion = 'U'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end
if @i_operacion = 'F'and @t_trn <> 172003 begin  select @w_error = 1720016 goto ERROR_FIN end



 --en sql cts convierte en null las cadenas vacías, por esta razón se envía un * que se debe reemplazar por cadena vacía
if @i_s_apellido = '*' select @i_s_apellido = ''
if @i_segnombre  = '*' select @i_segnombre  = ''

/*DATOS BASICOS DEL CLIENTE*/
select
@w_funcionario  = c_funcionario,
@w_cedula       = en_ced_ruc,
@w_tipo_ced     = en_tipo_ced,
@w_oficial      = en_oficial,
@i_pais_nac     = isnull(@i_pais_nac,          en_pais_nac),
@i_nacionalidad = isnull(@i_nacionalidad,      en_nacionalidad),
@i_estado_civil = isnull(@i_estado_civil,      p_estado_civil),
@i_sexo         = isnull(@i_sexo,              p_sexo),
@i_genero       = isnull(@i_genero,              p_genero),
@i_nombre       = isnull(@i_nombre,            en_nombre),
@i_segnombre    = isnull(@i_segnombre,         p_s_nombre),
@i_p_apellido   = isnull(@i_p_apellido,        p_p_apellido),
@i_s_apellido   = isnull(@i_s_apellido,        p_s_apellido),
@i_fecha_nac    = isnull(@i_fecha_nac,         p_fecha_nac),
@i_tipo_ced     = isnull(@i_tipo_ced,          en_tipo_ced),
@i_cedula       = isnull(@i_cedula,            en_ced_ruc),
@i_nit          = isnull(@i_nit,               en_nit),
@i_pasaporte    = isnull(@i_pasaporte,         p_pasaporte),
@i_oficial      = isnull(@i_oficial,           en_oficial),
@i_ciudad_nac   = isnull(@i_ciudad_nac,        p_ciudad_nac)
from cl_ente
where en_ente    = @i_persona
and   en_subtipo = 'P'  -- Persona Natural

if @@rowcount = 0 begin
   select @w_error = 1720021  --no existe la persona
   goto ERROR_FIN
end

/* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
if @i_persona is not null and @i_persona <> 0
begin
   select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_persona
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

/*Validacion celular recados*/
if(@i_telefono_recados is not null and @i_telefono_recados <> '')
begin
   select @w_longitud = LEN(@i_telefono_recados) --longitud de valor de telefono
   select @w_valida_long = pa_smallint from cl_parametro where pa_nemonico = 'DCEL' and pa_producto = 'CLI'
   if @w_longitud <> @w_valida_long
   begin
      select @w_error = 1720539 -- 'El Celular no es valido'
      goto ERROR_FIN 
   end
   /*Validar dígitos consecutivos*/
   select @w_respuesta = cobis.dbo.fn_valida_telefono(@i_telefono_recados)
   if @w_respuesta <> 0
   begin
      select @w_error = 1720536 -- 'El teléfono no es valido'
      goto ERROR_FIN 
   end
end


/* VERIFICAR EXISTENCIA DE TABLA AUXILAR */
select
@i_numero_ife = isnull(@i_numero_ife,         ea_numero_ife)
from cl_ente_aux
where ea_ente = @i_persona

if @@rowcount = 0 begin

   --SI NO EXISTE EN CL_ENTE_AUX, CREO EL REGISTRO VACIO PARA EVITAR INCONSISTENCIAS
   insert into cobis..cl_ente_aux (ea_ente, ea_estado) values (@i_persona, '')

   if @@error <> 0 begin
      select @w_error = 1720325
      goto ERROR_FIN
   end
end


/* LIMPIEZA DE DATOS */
select
@i_cedula       = ltrim(rtrim(@i_cedula)),
@i_nombre       = ltrim(rtrim(upper(@i_nombre    ))),
@i_segnombre    = ltrim(rtrim(upper(@i_segnombre ))),
@i_p_apellido   = ltrim(rtrim(upper(@i_p_apellido))),
@i_s_apellido   = ltrim(rtrim(upper(@i_s_apellido))),
@i_c_apellido   = ltrim(rtrim(upper(@i_c_apellido))),
@i_actividad    = ltrim(rtrim(upper(@i_actividad)))

while @i_nombre     <> replace(@i_nombre,    '  ',' ') select @i_nombre     = replace(@i_nombre,    '  ',' ')
while @i_segnombre  <> replace(@i_segnombre, '  ',' ') select @i_segnombre  = replace(@i_segnombre, '  ',' ')
while @i_p_apellido <> replace(@i_p_apellido,'  ',' ') select @i_p_apellido = replace(@i_p_apellido,'  ',' ')
while @i_c_apellido <> replace(@i_c_apellido,'  ',' ') select @i_c_apellido = replace(@i_c_apellido,'  ',' ')


-- Tipos de identificacion de personas nacionales
if @i_tipo_ced in ('CI','CID','CIEE','CPN','ND','RUN') begin
   select @w_nat_jur_hogar =pa_char
   from  cobis..cl_parametro
   where pa_producto ='CLI'
   and   pa_nemonico ='NAJUHO'
end

-- Tipos de identificacion de personas extranjeras
if @i_tipo_ced in ('CIE','DCC','DCD','DCO','DCR','PAS','DE') begin
   select @w_nat_jur_hogar =pa_char
   from cobis..cl_parametro
   where pa_producto ='CLI'
   and pa_nemonico ='NAJUHE'
end


/* SI NO ESTA DADO, SE ASUME QUE LA PERSONA ES SOLTERA */
select @w_default_estado_civil = codigo
from cobis..cl_catalogo 
where tabla = (select codigo from cl_tabla where tabla = 'cl_ecivil')
and valor like 'SO%'

if @i_estado_civil is null select @i_estado_civil = @w_default_estado_civil

/* NOMBRE COMPLETO DE LA PERSONA NATURAL */
select @w_nombre_completo = concat(@i_nombre, ' ', @i_segnombre, ' ', @i_p_apellido, ' ', @i_s_apellido)

if @i_sexo = 'F' and @i_estado_civil = @w_nemocda and @i_c_apellido is not null  -- mujer casada que usa apellido del esposo
   select @w_nombre_completo = concat(@w_nombre_completo, ' ', @i_c_apellido)

if @i_estado_civil = @w_nemomed
   select @w_nombre_completo = concat(@w_nombre_completo, ' (MENOR)')


/* MANEJO DEL PAIS DE NACIMIENTO Y LA NACIONALIDAD*/
select @i_pais_nac     = isnull(@i_pais_nac,     @w_pais_local)
select @i_nacionalidad = isnull(@i_nacionalidad, @i_pais_nac  )

if @i_nacionalidad <> @w_pais_local
begin
   select @w_nacionalidad = 'E'
end
else
begin
   select @w_nacionalidad = 'N'
end

--VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION
if(select ti_estado from cl_tipo_identificacion 
   where ti_codigo         = @i_tipo_ced 
   and   ti_tipo_documento = 'P' 
   and   ti_nacionalidad   = @w_nacionalidad 
   and   ti_tipo_cliente   = 'P') != 'V'
begin
   select @w_error = 1720605
   goto ERROR_FIN
end

--VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION TRIBUTARIA
if(select ti_estado from cl_tipo_identificacion 
   where ti_codigo         = @i_tipo_tributario 
   and   ti_tipo_documento = 'T' 
   and   ti_nacionalidad   = @w_nacionalidad 
   and   ti_tipo_cliente   = 'P') != 'V'
begin
   select @w_error = 1720607
   goto ERROR_FIN
end


/* POR ESTA OPCION, DESDE FRONT END NO SE PUEDE CAMBIAR LA OFICINA Y EL OFICIAL DEL CLIENTE*/
if @i_origen = 'F'
begin
   if @i_oficial is null or @i_oficial = ''
   begin
      select
         @i_oficial = oc_oficial,
         @i_oficina = fu_oficina
      from cobis..cc_oficial, cobis..cl_funcionario
      where fu_login       = @w_funcionario
      and   fu_funcionario = oc_funcionario
   end
end

/* SI EL CLIENTE ES UNA PERSONA LOCAL, NO DEBE TENER ESTOS DATOS */
if @w_pais_local = @i_pais_nac begin
   select
   @i_naturalizado      = '',
   @i_forma_migratoria  = '',
   @i_nro_extranjero    = '',
   @i_calle_orig        = '',
   @i_exterior_orig     = '',
   @i_estado_orig       = ''
end



--SI EXISTE CODIGO DE GRUPO, ASEGURARSE DE QUE EXISTA
if @i_grupo is not null begin

   if not exists (select 1 from cl_grupo where gr_grupo = @i_grupo )
   begin
      select @w_error = 1720052
      goto ERROR_FIN
   end

   --FORZAR QUE TODOS LOS CLIENTES DEL GRUPO TENGAN UN MISMO OFICIAL, EL DEL GRUPO.
   select @i_oficial = gr_oficial
   from cl_grupo
   where gr_grupo = @i_grupo

end


/* VALIDAR CATALOGOS */
if (@i_egresos is not null)
begin
   exec @w_error = sp_validar_catalogo @i_tabla = 'cl_nivel_egresos',    @i_valor = @i_egresos           if @w_error <> 0 goto ERROR_FIN --1720373
end
if (@i_ingre is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_ingresos',         @i_valor = @i_ingre                if @w_error <> 0 goto ERROR_FIN --1720374
end
if (@i_tipo_vinculacion is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_relacion_banco',   @i_valor = @i_tipo_vinculacion     if @w_error <> 0 goto ERROR_FIN --1720037
end
if (@i_ant_nego is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_referencia_tiempo',@i_valor = @i_ant_nego             if @w_error <> 0 goto ERROR_FIN --1720375
end
if (@i_otringr is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_fuente_ingreso',   @i_valor = @i_otringr              if @w_error <> 0 goto ERROR_FIN --1720376
end
if (@i_ea_cat_aml is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_categoria_AML',    @i_valor = @i_ea_cat_aml           if @w_error <> 0 goto ERROR_FIN --1720377
end
if (@i_ea_tipo_discapacidad is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_discapacidad',     @i_valor = @i_ea_tipo_discapacidad if @w_error <> 0 goto ERROR_FIN --1720020
end
if (@i_sexo is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_sexo',             @i_valor = @i_sexo                 if @w_error <> 0 goto ERROR_FIN --1720025
end
if (@i_genero is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_genero',           @i_valor = @i_genero               if @w_error <> 0 goto ERROR_FIN --1720380
end
if (@i_profesion is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_profesion',        @i_valor = @i_profesion            if @w_error <> 0 goto ERROR_FIN --1720026
end
if (@i_pais is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_pais',             @i_valor = @i_pais                 if @w_error <> 0 goto ERROR_FIN --1720027
end
if (@i_estado_civil is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_ecivil',           @i_valor = @i_estado_civil         if @w_error <> 0 goto ERROR_FIN --1720057
end
if (@i_tipo is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_ptipo',            @i_valor = @i_tipo                 if @w_error <> 0 goto ERROR_FIN --1720058
end
if (@i_actividad is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_actividad_ec',     @i_valor = @i_actividad            if @w_error <> 0 goto ERROR_FIN --1720059
end
if (@i_sector is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_sector_economico', @i_valor = @i_sector               if @w_error <> 0 goto ERROR_FIN --1720042
end
if (@i_promotor is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_promotor',         @i_valor = @i_promotor             if @w_error <> 0 goto ERROR_FIN --1720060
end
if (@i_nivel_estudio is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_nivel_estudio',    @i_valor = @i_nivel_estudio        if @w_error <> 0 goto ERROR_FIN --1720029
end
if (@i_tipo_vivienda is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_tipo_vivienda',    @i_valor = @i_tipo_vivienda        if @w_error <> 0 goto ERROR_FIN --1720030
end
if (@i_oficial is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cc_oficial',          @i_valor = @i_oficial              if @w_error <> 0 goto ERROR_FIN --1720051
end
if (@i_oficial_sup is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cc_oficial',          @i_valor = @i_oficial_sup          if @w_error <> 0 goto ERROR_FIN --1720051
end
if (@i_depart_doc is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_provincia',        @i_valor = @i_depart_doc           if @w_error <> 0 goto ERROR_FIN --1720378
end
if (@i_orig_fondo is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_origen_fondos',        @i_valor = @i_orig_fondo           if @w_error <> 0 goto ERROR_FIN --1720378
end

if (@i_nivel_cuenta is not null)
begin
    exec @w_error = sp_validar_catalogo @i_tabla = 'cl_nivel_cuenta',        @i_valor = @i_nivel_cuenta           if @w_error <> 0 goto ERROR_FIN --1720381
    if (@i_nivel_cuenta = '1')
    begin
        if (@i_cat_num_trn_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_num_trn_mes_n1',        @i_valor = @i_cat_num_trn_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720382
        end
        if (@i_cat_mto_trn_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_mto_trn_mes_n1',        @i_valor = @i_cat_mto_trn_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720383
        end
        if (@i_cat_sdo_prom_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_sdo_prom_mes_n1',        @i_valor = @i_cat_sdo_prom_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720384
        end
    end
    if (@i_nivel_cuenta = '2')
    begin
        if (@i_cat_num_trn_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_num_trn_mes_n2',        @i_valor = @i_cat_num_trn_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720385
        end
        if (@i_cat_mto_trn_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_mto_trn_mes_n2',        @i_valor = @i_cat_mto_trn_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720386
        end
        if (@i_cat_sdo_prom_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_sdo_prom_mes_n2',        @i_valor = @i_cat_sdo_prom_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720387
        end
    end
    if (@i_nivel_cuenta = '3')
    begin
        if (@i_cat_num_trn_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_num_trn_mes_n3',        @i_valor = @i_cat_num_trn_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720388
        end
        if (@i_cat_mto_trn_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_mto_trn_mes_n3',        @i_valor = @i_cat_mto_trn_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720389
        end
        if (@i_cat_sdo_prom_mes_ini is not null)
        begin
            exec @w_error = sp_validar_catalogo @i_tabla = 'cl_sdo_prom_mes_n3',        @i_valor = @i_cat_sdo_prom_mes_ini           if @w_error <> 0 goto ERROR_FIN --1720390
        end
    end
end

if (@i_cat_gpo_mtz_riesgo is not null)
begin
exec @w_error = sp_validar_catalogo @i_tabla = 'cl_gpo_matriz_riesgo',        @i_valor = @i_cat_gpo_mtz_riesgo           if @w_error <> 0 goto ERROR_FIN --1720391
end

--VERIFICAR SI EXISTE LA CIUDAD DE NACIMIENTO
/*
PQU quitar esto
if @i_valprov ='N' begin
   exec @w_error =  sp_validar_catalogo @i_tabla = 'cl_pais',   @i_valor = @i_ciudad_nac    if @w_error <> 0 goto ERROR_FIN --1720027
end else begin
   exec @w_error =  sp_validar_catalogo @i_tabla = 'cl_provincia', @i_valor = @i_ciudad_nac    if @w_error <> 0 goto ERROR_FIN --1720028
end
*/

if @i_retencion is null
begin
   select @i_retencion = en_retencion from cl_ente where en_ente = @i_persona
end

-- VALORES VALIDOS PARA LA RETENCION
if @i_retencion not in ('N', 'S') begin
   select @w_error = 1720326
   goto ERROR_FIN
end


--Fuente de Ingresos
if not exists(select 1 from cl_actividad_principal
              where ap_activ_comer = @i_ea_fuente_ing)
              and @i_ea_fuente_ing is not null
begin
    select @i_ea_act_prin = 'NA'
end

-- SI LA PERSONA ES UN FUNCIONARIO, ESTA VINCULADO A LA INSTITUCION
if @i_cedula is not null and @i_nit is not null and exists (select 1 from cobis..cl_funcionario where fu_cedruc in (@i_cedula, @i_nit))
begin
    select @i_vinculacion = 'S'
end

if @i_codigo_pep_relac <> NULL and @i_codigo_pep_relac <> 0
begin
   select @w_nombre_pep_relac = en_nomlar
   from cl_ente 
   where en_ente = @i_codigo_pep_relac
end
else
begin
   select @w_nombre_pep_relac = @i_nombre_pep_relac
end

begin tran
--se pone los numeros de identificacion en uppercase
select @i_cedula      = upper(@i_cedula)
select @i_nit         = upper(@i_nit)
select @i_numero_iden = upper(@i_numero_iden)

--Registro antes del cambio
insert into ts_persona_prin (
secuencia,              tipo_transaccion,      clase,
fecha,                  usuario,               terminal,
srv,                    lsrv,                  persona,
nombre,                 p_apellido,            s_apellido,
sexo,                   cedula,                tipo_ced,
pais,                   profesion,             estado_civil,
actividad,              num_cargas,            nivel_ing,
nivel_egr,              tipo,                  filial,
oficina,                fecha_nac,             grupo,
oficial,                comentario,            retencion,
fecha_mod,              fecha_expira,          sector,
ciudad_nac,             nivel_estudio,         tipo_vivienda,
calif_cliente,          tipo_vinculacion,      pais_nac,
provincia_nac,          naturalizado,          forma_migratoria,
nro_extranjero,         calle_orig,            exterior_orig,
estado_orig,            hora)
select
@s_ssn,                 @t_trn,                'A',
getdate(),              @s_user,               @s_term,
@s_srv,                 @s_lsrv,               @i_persona,
en_nombre,              p_p_apellido,          p_s_apellido,
p_sexo,                 en_ced_ruc,            en_tipo_ced,
en_pais,                p_ocupacion,           p_estado_civil,
en_actividad,           p_num_cargas,          p_nivel_ing,
p_nivel_egr,            en_subtipo,            en_filial,
en_oficina,             p_fecha_nac,           en_grupo,
en_oficial,             en_comentario,         en_retencion,
en_fecha_mod,           p_fecha_expira,        en_sector,
p_ciudad_nac,           p_nivel_estudio,       p_tipo_vivienda,
en_calificacion,        en_tipo_vinculacion,   en_pais_nac,
en_provincia_nac,       en_naturalizado,       en_forma_migratoria,
en_nro_extranjero,      en_calle_orig,         en_exterior_orig,
en_estado_orig,         getdate()
from cl_ente
where en_ente = @i_persona

--ERROR EN CREACION DE TRANSACCION DE SERVICIO
if @@error <> 0 begin
   select @w_error = 1720049
   goto ERROR_FIN
end

--Validación para guardar identificación principal y tributaria con máscara definida
if @i_is_app = 'S'
begin
    if @i_tipo_ced = 'DUI' and charindex('-', @i_cedula) = 0
    begin
        --Tipo de identificación Principal
        select @w_mascara = ti_mascara
        from  cobis..cl_tipo_identificacion
        where ti_codigo = @i_tipo_ced
        and   ti_tipo_cliente = 'P'
        and   ti_tipo_documento = 'P'
        and   ti_nacionalidad   = @w_nacionalidad
        and   ti_estado = 'V'
        
        select @w_doc_prin_mascara = cobis.dbo.fn_parsea_identificacion (@i_cedula, @w_mascara)
        select @i_cedula = @w_doc_prin_mascara
    end
    
    if @i_tipo_tributario = 'NIT' and (@i_nit is not null and @i_nit <> '')
    begin
        --Tipo de identificación Tributaria
        select @w_mascara = ti_mascara
        from  cobis..cl_tipo_identificacion
        where ti_codigo = @i_tipo_tributario
        and   ti_tipo_cliente = 'P'
        and   ti_tipo_documento = 'T'
        and   ti_nacionalidad   = @w_nacionalidad
        and   ti_estado = 'V'
        
        select @w_doc_trib_mascara = cobis.dbo.fn_parsea_identificacion (@i_nit, @w_mascara)
        select @i_nit = @w_doc_trib_mascara
    end
end

--VERIFICAR QUE NO ESTE PREVIAMENTE INSERTADA UNA PERSONA CON EL MISMO TIPO Y NÚMERO DE DOCUMENTO
if exists (select 1 from  cl_ente
           where  en_ced_ruc  = @i_cedula
           and    en_tipo_ced = @i_tipo_ced
           and    en_ente    <> @i_persona)
begin
   select @w_error = 1720482
   goto ERROR_FIN
end

--VERIFICAR QUE NO ESTE PREVIAMENTE INSERTADA UNA PERSONA CON LA MISMA IDENTIFICACION TRIBUTARIA
if exists (select 1 from  cl_ente
           where  en_nit     =  @i_nit
           and    en_ente    <> @i_persona
           and    isnull(@i_nit,'') <> '')
begin
   select @w_error = 1720484
   goto ERROR_FIN
end

--VERIFICAR QUE NO ESTE PREVIAMENTE INSERTADA UNA PERSONA CON LA MISMO PASAPORTE
if exists (select 1 from  cl_ente
           where  p_pasaporte   = @i_pasaporte
           and    en_ente      <> @i_persona
           and    isnull(@i_pasaporte,'') <> '')
begin
   select @w_error = 1720054
   goto ERROR_FIN
end

if @i_depa_nac = 0
begin
   select @i_depa_nac = null
end

if @i_ciudad_nac = 0
begin
   select @i_ciudad_nac = null
end

select @w_valida_long = pa_smallint from cl_parametro where pa_nemonico = 'DCEL' and pa_producto = 'CLI'

update cobis..cl_ente set
p_tipo_persona         = isnull(@i_tipo,              p_tipo_persona),
c_tipo_compania        = isnull(@w_nat_jur_hogar,     c_tipo_compania),
en_nit                 = isnull(@i_nit,               en_nit),
en_digito              = isnull(@i_digito,            en_digito),
en_rfc                 = isnull(@i_nit,               en_rfc),
en_ced_ruc             = isnull(@i_cedula,            en_ced_ruc),
en_tipo_ced            = isnull(@i_tipo_ced,          en_tipo_ced),
p_pasaporte            = isnull(@i_pasaporte,         p_pasaporte),
en_inss                = isnull(@i_inss,              en_inss),     --numero seguro social
en_licencia            = isnull(@i_licencia,          en_licencia), -- licencia de conducir
en_tipo_iden           = isnull(@i_tipo_iden,         en_tipo_iden),
en_numero_iden         = isnull(@i_numero_iden,       en_numero_iden),
--p_fecha_emision        = isnull(@i_fecha_emision,     p_fecha_emision), --se actualiza en datos sensiblles
--p_fecha_expira         = isnull(@i_fecha_expira,      p_fecha_expira), --se actualiza en datos sensibles
en_banco               = isnull(@i_banco,             en_banco),    -- Nro con que el cliente se registra en el banco
en_doc_validado        = isnull(@i_doc_validado,      en_doc_validado),
p_lugar_doc            = isnull(@i_lugar_doc,         p_lugar_doc),
p_dep_doc              = isnull(@i_depart_doc,        p_dep_doc),

en_nombre              = isnull(@i_nombre,            en_nombre),
p_s_nombre             = isnull(@i_segnombre,         p_s_nombre),
p_p_apellido           = isnull(@i_p_apellido,        p_p_apellido),
p_s_apellido           = isnull(@i_s_apellido,        p_s_apellido),
p_c_apellido           = isnull(@i_c_apellido, 		  p_c_apellido), -- apellido de casada (solo mujeres)
en_nomlar              = isnull(@w_nombre_completo,   en_nomlar),

en_calificacion        = isnull(@i_calificacion,      en_calificacion),
p_calif_cliente        = isnull(@i_calif_cliente,     p_calif_cliente),
p_sexo                 = isnull(@i_sexo,              p_sexo),
p_genero               = isnull(@i_genero,            p_genero),

p_estado_civil         = isnull(@i_estado_civil,      p_estado_civil),
p_fecha_nac            = isnull(@i_fecha_nac,         p_fecha_nac),
en_filial              = isnull(@i_filial,            en_filial),
en_oficina             = isnull(@i_oficina,           en_oficina),
en_oficial             = isnull(@i_oficial,           -1),   --valor defecto stacktrace
en_oficial_sup         = isnull(@i_oficial_sup,       en_oficial_sup),

p_pais_emi             = isnull(@i_pais_emi,          p_pais_emi),
en_nac_aux             = isnull(@i_nac_aux,           en_nac_aux),
p_nivel_estudio        = isnull(@i_nivel_estudio,     p_nivel_estudio),
p_profesion            = isnull(@i_profesion,         p_profesion),
p_num_cargas           = isnull(@i_num_cargas,        p_num_cargas),

en_pais_nac            = isnull(@i_pais_nac,          en_pais_nac),
p_depa_nac             = isnull(@i_depa_nac ,         p_depa_nac),
en_provincia_nac       = isnull(@i_depa_nac,          en_provincia_nac),
p_ciudad_nac           = isnull(@i_ciudad_nac,        p_ciudad_nac),
en_nacionalidad        = isnull(@i_nacionalidad,      en_nacionalidad),

en_emproblemado        = isnull(@i_emproblemado,      en_emproblemado),  --persona con problemas econï¿½micos
en_concordato          = isnull(@i_categoria,         en_concordato),    --persona en quiebra en acuerdo de acreedores
en_persona_pep         = isnull(@i_pep,               en_persona_pep),
p_carg_pub             = isnull(@i_carg_pub,          p_carg_pub),
en_persona_pub         = isnull(@i_persona_pub,       en_persona_pub),
p_rel_carg_pub         = isnull(@i_rel_carg_pub,      p_rel_carg_pub),

en_naturalizado        = isnull(@i_naturalizado,      en_naturalizado),
en_forma_migratoria    = isnull(@i_forma_migratoria,  en_forma_migratoria),
en_nro_extranjero      = isnull(@i_nro_extranjero,    en_nro_extranjero),
en_calle_orig          = isnull(@i_calle_orig,        en_calle_orig),
en_exterior_orig       = isnull(@i_exterior_orig,     en_exterior_orig),
en_estado_orig         = isnull(@i_estado_orig,       en_estado_orig),

en_actividad           = isnull(@i_actividad,         en_actividad),
en_ingre               = isnull(@i_ingre,             en_ingre),
en_ing_SN              = isnull(@i_ing_SN,            en_ing_SN),  -- Tiene otros ingresos? S/N
en_otringr             = isnull(@i_otringr ,          en_otringr),
en_otros_ingresos      = isnull(@i_otros_ingresos,    en_otros_ingresos),
p_nivel_ing            = isnull(@i_nivel_ing,         p_nivel_ing),
p_nivel_egr            = isnull(@i_nivel_egr,         p_nivel_egr),
p_bienes               = isnull(@i_bienes,            p_bienes),
en_origen_ingresos     = isnull(@i_origen_ingresos,   en_origen_ingresos),

en_tipo_vinculacion    = isnull(@i_tipo_vinculacion,  en_tipo_vinculacion),
en_id_tutor            = isnull(@i_en_id_tutor,       en_id_tutor),
en_nom_tutor           = isnull(@i_en_nom_tutor,      en_nom_tutor),

c_total_activos        = isnull(@i_total_activos,     c_total_activos),
c_pasivo               = isnull(@i_mnt_pasivo,        c_pasivo),
en_patrimonio_tec      = isnull(@i_patrim_tec,        en_patrimonio_tec),
en_fecha_patri_bruto   = isnull(@i_fecha_patrim_bruto,en_fecha_patri_bruto),
en_dinero_transac      = isnull(@i_dinero_transac,    en_dinero_transac),

en_vinculacion         = isnull(@i_vinculacion,       en_vinculacion),
en_retencion           = isnull(@i_retencion,         en_retencion),

en_pais                = isnull(@i_pais,              en_pais),  --nacionalidad

en_fecha_mod           = isnull(@s_date,              en_fecha_mod),
en_grupo               = isnull(@i_grupo,             en_grupo),
en_preferen            = isnull(@i_preferen,          en_preferen),
en_comentario          = isnull(@i_comentario,        en_comentario),

en_asosciada           = isnull(@i_asosciada,         en_asosciada),
en_referido            = isnull(@i_referido,          en_referido),
en_sector              = isnull(@i_sector,            en_sector),
p_tipo_vivienda        = isnull(@i_tipo_vivienda,     p_tipo_vivienda),

en_gran_contribuyente  = isnull(@i_gran_contribuyente,en_gran_contribuyente),
en_situacion_cliente   = isnull(@i_situacion_cliente, en_situacion_cliente),
en_rep_superban        = isnull(@i_rep_superban,      en_rep_superban),
en_exc_sipla           = isnull(@i_exc_sipla,         en_exc_sipla),
en_exc_por2            = isnull(@i_exc_por2,          en_exc_por2),
en_cem                 = isnull(@i_cem,               en_cem),
p_numord               = isnull(@i_numord,            p_numord),
en_promotor            = isnull(@i_promotor,          en_promotor),
c_codsuper             = isnull(@i_tipo,              c_codsuper),

en_cod_otro_pais       = isnull(@i_codigo,            en_cod_otro_pais),

en_referidor_ecu       = isnull(@i_referidor_ecu,     en_referidor_ecu),
p_situacion_laboral    = isnull(@i_situacion_laboral, p_situacion_laboral),
c_verificado           = isnull(@i_verificado,        c_verificado),
c_fecha_verif          = @s_date, --* Debe guardar la fecha de proceso

en_inf_laboral         = isnull(isnull(@i_inf_laboral, @i_lug_trab),  en_inf_laboral),
en_tipo_operacion      = isnull(@i_tipo_operacion,    en_tipo_operacion),
en_provincia_act       = isnull(@i_provincia_act,     en_provincia_act),
en_lugar_act           = isnull(@i_lugar_act,         en_lugar_act),

p_ocupacion            = isnull(@i_ocupacion,         p_ocupacion),
en_tipo_doc_tributario = isnull(@i_tipo_tributario,   en_tipo_doc_tributario),
en_tipo_residencia     = isnull(@i_tipo_residencia,   en_tipo_residencia),

en_codigo_pep_relac    = isnull(@i_codigo_pep_relac,  en_codigo_pep_relac),
en_nombre_pep_relac    = isnull(@w_nombre_pep_relac,  en_nombre_pep_relac),
p_fecha_inicio_pep     = isnull(@i_fecha_inicio_pep,  p_fecha_inicio_pep),
p_fecha_fin_pep        = @i_fecha_fin_pep, --Campo puede ser null
p_tipo_pep             = isnull(@i_tipo_pep,          p_tipo_pep)
where en_ente     = @i_persona
and   en_subtipo  = 'P'



if @i_persona_pub = 'E' or @i_persona_pub = 'N'
begin
   update cobis..cl_ente set
   p_carg_pub          = NULL,
   p_rel_carg_pub      = NULL,
   en_codigo_pep_relac = NULL,
   en_nombre_pep_relac = NULL,
   p_fecha_inicio_pep  = NULL,
   p_fecha_fin_pep     = NULL,
   p_tipo_pep          = NULL
   where en_ente     = @i_persona
   and   en_subtipo  = 'P'
end

if @@error <> 0 begin
   select @w_error = 1720036
   goto ERROR_FIN
end

-- BM Sincronización de medios
select @w_telefono_recados_a = isnull(ea_telef_recados,'')
  from cobis..cl_ente_aux 
 where ea_ente = @i_persona

update cobis..cl_ente_aux set
ea_nit               = isnull(@i_nit,                 ea_nit),
ea_ced_ruc           = isnull(@i_cedula,              ea_ced_ruc),
ea_telef_recados     = isnull(@i_telefono_recados,    ea_telef_recados),
ea_numero_ife        = isnull(@i_numero_ife,          ea_numero_ife),
ea_num_serie_firma   = isnull(@i_numero_serie_firma,  ea_num_serie_firma),
ea_persona_recados   = isnull(@i_persona_recados,     ea_persona_recados),
ea_antecedente_buro  = isnull(@i_antecedentes_buro,   ea_antecedente_buro),
ea_cta_banco         = isnull(@i_ea_cta_banco,        ea_cta_banco),   --numero de cuenta de ahorros donde el cliente trabaja
ea_estado_std        = isnull(@i_estado_std,          ea_estado_std),
ea_ct_ventas         = isnull(@i_ct_ventas,           ea_ct_ventas),
ea_ct_operativo      = isnull(@i_ct_operativos,       ea_ct_operativo),
ea_ventas            = isnull(@i_ventas,              ea_ventas),
ea_nro_ciclo_oi      = isnull(@i_ea_nro_ciclo_oi,     ea_nro_ciclo_oi),  --numero de ciclos en otras entidades
ea_cat_aml           = isnull(@i_ea_cat_aml,          ea_cat_aml),
ea_nivel_egresos     = isnull(@i_egresos,             ea_nivel_egresos),
ea_ant_nego          = isnull(@i_ant_nego,            ea_ant_nego),
ea_estado            = isnull(@i_ea_estado,           ea_estado),
ea_contrato_firmado  = isnull(@i_ea_contrato_firmado, ea_contrato_firmado),
ea_menor_edad        = isnull(@i_ea_menor_edad,       ea_menor_edad),
--ea_conocido_como     = isnull(@i_ea_conocido_como,    ea_conocido_como), -- Se actualiza en datos sensibles
ea_cliente_planilla  = isnull(@i_ea_cliente_planilla, ea_cliente_planilla),
ea_cod_risk          = isnull(@i_ea_cod_risk,         ea_cod_risk),
ea_sector_eco        = isnull(@i_ea_sector_eco,       ea_sector_eco),
ea_actividad         = isnull(@i_ea_actividad,        ea_actividad),
ea_lin_neg           = isnull(@i_ea_lin_neg,          ea_lin_neg),
ea_seg_neg           = isnull(@i_ea_seg_neg,          ea_seg_neg),
ea_ejecutivo_con     = isnull(@i_ea_ejecutivo_con,    ea_ejecutivo_con),
ea_suc_gestion       = isnull(@i_ea_suc_gestion,      ea_suc_gestion),
ea_constitucion      = isnull(@i_ea_constitucion,     ea_constitucion),
ea_remp_legal        = isnull(@i_ea_remp_legal,       ea_remp_legal),
ea_apoderado_legal   = isnull(@i_ea_apoderado_legal,  ea_apoderado_legal),
ea_fuente_ing        = isnull(@i_ea_fuente_ing,       ea_fuente_ing),
ea_act_prin          = isnull(@i_ea_act_prin,         ea_act_prin),
ea_detalle           = isnull(@i_ea_detalle,          ea_detalle),
ea_act_dol           = isnull(@i_ea_act_dol,          ea_act_dol),
ea_discapacidad      = isnull(@i_ea_discapacidad,     ea_discapacidad),
ea_tipo_discapacidad = isnull(@i_ea_tipo_discapacidad,ea_tipo_discapacidad),
ea_ced_discapacidad  = isnull(@i_ea_ced_discapacidad, ea_ced_discapacidad),
ea_ifi               = isnull(@i_ifi,                 ea_ifi),
ea_asfi              = isnull(@i_asfi,                ea_asfi),
ea_path_foto         = isnull(@i_path_foto,           ea_path_foto),
ea_nit_venc          = isnull(@i_nit_venc,            ea_nit_venc),
ea_indefinido        = isnull(@i_ea_indefinido,       ea_indefinido),
ea_partner           = isnull(@i_partner,             ea_partner),
ea_lista_negra       = isnull(@i_lista_negra,         ea_lista_negra),
ea_ingreso_legal     = isnull(@i_ea_ingreso_legal,    ea_ingreso_legal),
ea_actividad_legal   = isnull(@i_ea_actividad_legal,  ea_actividad_legal),
ea_otra_cuenta_banc  = isnull(@i_ea_otra_cuenta,      ea_otra_cuenta_banc),
ea_provincia_res     = isnull(@i_provincia_res,       ea_provincia_res)
where ea_ente = @i_persona

if @@error <> 0 begin
   select @w_error =  1720327
   goto ERROR_FIN
end
if @i_pseudonimo is not null
begin
   select @w_pseudonimo_par = pa_tinyint
   from cobis.dbo.cl_parametro
   where pa_nemonico = 'CODPSE'
   and pa_producto = 'CLI'
   
   if not exists(select 1 from cobis..cl_dadicion_ente where de_ente = @i_persona and de_dato = @w_pseudonimo_par)
   begin
      exec @w_error = cobis..sp_dad_ente
      @s_ssn             = @s_ssn,
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_date            = @s_date,
      @s_srv             = @s_srv,
      @s_lsrv            = @s_lsrv,
      @s_ofi             = @s_ofi,
      @t_debug           = 'N',
      @t_file            = '',
      @t_from            = @w_sp_name,
      @t_trn             = 172184,
      @i_operacion       = 'I',
      @i_ente            = @i_persona,
      @i_dato            = @w_pseudonimo_par,
      @i_tipodato        = 'C',
      @i_valor           = @i_pseudonimo,
      @i_tipoente        = 'P'
   end
   else
   begin
      exec @w_error = cobis..sp_dad_ente
      @s_ssn             = @s_ssn,
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_date            = @s_date,
      @s_srv             = @s_srv,
      @s_lsrv            = @s_lsrv,
      @s_ofi             = @s_ofi,
      @t_debug           = 'N',
      @t_file            = '',
      @t_from            = @w_sp_name,
      @t_trn             = 172186,
      @i_operacion       = 'U',
      @i_ente            = @i_persona,
      @i_dato            = @w_pseudonimo_par,
      @i_tipodato        = 'C',
      @i_valor           = @i_pseudonimo,
      @i_tipoente        = 'P'
   end
end



if exists(select 1 from cobis..cl_info_trn_riesgo where itr_ente = @i_persona)
begin
    update cobis..cl_info_trn_riesgo
    set itr_cat_grupo               = isnull(@i_cat_gpo_mtz_riesgo,       itr_cat_grupo),
        itr_cat_nivel               = isnull(@i_nivel_cuenta,       itr_cat_nivel),
        itr_cat_num_trn_mes_ini     = isnull(@i_cat_num_trn_mes_ini,       itr_cat_num_trn_mes_ini),
        itr_cat_mto_trn_mes_ini     = isnull(@i_cat_mto_trn_mes_ini,       itr_cat_mto_trn_mes_ini),
        itr_cat_sdo_prom_mes_ini    = isnull(@i_cat_sdo_prom_mes_ini,       itr_cat_sdo_prom_mes_ini),
        itr_ptos_num_trn_mes_ini    = isnull(@i_pto_num_trn_mes_ini,       itr_ptos_num_trn_mes_ini),
        itr_ptos_mto_trn_mes_ini    = isnull(@i_pto_mto_trn_mes_ini,       itr_ptos_mto_trn_mes_ini),
        itr_ptos_sdo_prom_mes_ini   = isnull(@i_pto_sdo_prom_mes_ini,       itr_ptos_sdo_prom_mes_ini),
        itr_ultima_fecha_mod        = isnull(@s_date,       itr_ultima_fecha_mod),
		itr_can_anticipada          = isnull(@i_can_anticipada, itr_can_anticipada),
		itr_orig_fondo              = isnull(@i_orig_fondo,     itr_orig_fondo),
		itr_pag_adcapital           = isnull(@i_pag_adcapital,  itr_pag_adcapital),
		itr_cuota_adi               = isnull(@i_cuota_adi,      itr_cuota_adi)
    where itr_ente = @i_persona

    if @@error <> 0 begin
        select @w_error =  1720392
        goto ERROR_FIN
    end
end else
begin
    insert into cobis..cl_info_trn_riesgo(
        itr_ente,                   itr_cat_grupo,              itr_cat_nivel,              itr_cat_num_trn_mes_ini,
        itr_cat_mto_trn_mes_ini,    itr_cat_sdo_prom_mes_ini,   itr_ptos_num_trn_mes_ini,   itr_ptos_mto_trn_mes_ini,
        itr_ptos_sdo_prom_mes_ini,  itr_fecha_registro,         itr_ultima_fecha_mod,       itr_can_anticipada,
		itr_orig_fondo,             itr_pag_adcapital,   		itr_cuota_adi)
    values(
        @i_persona,                 @i_cat_gpo_mtz_riesgo,      @i_nivel_cuenta,            @i_cat_num_trn_mes_ini,
        @i_cat_mto_trn_mes_ini,     @i_cat_sdo_prom_mes_ini,    @i_pto_num_trn_mes_ini,     @i_pto_mto_trn_mes_ini,
        @i_pto_sdo_prom_mes_ini,    @s_date,                    @s_date,                    @i_can_anticipada,
		@i_orig_fondo,              @i_pag_adcapital,   		@i_cuota_adi)

    if @@error <> 0 begin
        select @w_error =  1720393
        goto ERROR_FIN
    end
end

--Registro despues del cambio
--Registro antes del cambio
insert into ts_persona_prin (
secuencia,              tipo_transaccion,      clase,
fecha,                  usuario,               terminal,
srv,                    lsrv,                  persona,
nombre,                 p_apellido,            s_apellido,
sexo,                   cedula,                tipo_ced,
pais,                   profesion,             estado_civil,
actividad,              num_cargas,            nivel_ing,
nivel_egr,              tipo,                  filial,
oficina,                fecha_nac,             grupo,
oficial,                comentario,            retencion,
fecha_mod,              fecha_expira,          sector,
ciudad_nac,             nivel_estudio,         tipo_vivienda,
calif_cliente,          tipo_vinculacion,      pais_nac,
provincia_nac,          naturalizado,          forma_migratoria,
nro_extranjero,         calle_orig,            exterior_orig,
estado_orig,            hora)
select
@s_ssn,                 @t_trn,                'A',
getdate(),              @s_user,               @s_term,
@s_srv,                 @s_lsrv,               @i_persona,
en_nombre,              p_p_apellido,          p_s_apellido,
p_sexo,                 en_ced_ruc,            en_tipo_ced,
en_pais,                p_ocupacion,           p_estado_civil,
en_actividad,           p_num_cargas,          p_nivel_ing,
p_nivel_egr,            en_subtipo,            en_filial,
en_oficina,             p_fecha_nac,           en_grupo,
en_oficial,             en_comentario,         en_retencion,
en_fecha_mod,           p_fecha_expira,        en_sector,
p_ciudad_nac,           p_nivel_estudio,       p_tipo_vivienda,
en_calificacion,        en_tipo_vinculacion,   en_pais_nac,
en_provincia_nac,       en_naturalizado,       en_forma_migratoria,
en_nro_extranjero,      en_calle_orig,         en_exterior_orig,
en_estado_orig,         getdate()
from cl_ente
where en_ente = @i_persona

--ERROR EN CREACION DE TRANSACCION DE SERVICIO
if @@error <> 0 begin
   select @w_error = 1720049
   goto ERROR_FIN
end

/*
if @i_estado_civil in ('SO', 'DI', 'VI') begin

   select @w_conyuge = 0

   select @w_conyuge = in_ente_d
   from  cobis..cl_instancia
   where  in_ente_i = @i_persona

   if @@rowcount <> 0 begin

      select @w_conyuge = in_ente_i
      from  cobis..cl_instancia
      where  in_ente_d = @i_persona

   end

   update cobis..cl_ente set
   p_estado_civil= @i_estado_civil
   where en_ente = @w_conyuge

   if @@error <> 0 begin
      select @w_error = 1720036
      goto ERROR_FIN
   end
   
   select @w_relacion_ca = pa_tinyint
   from cobis..cl_parametro
   where pa_nemonico = 'CONY' --Relacion Conyuge
   and   pa_producto = 'CLI'

   delete cobis..cl_instancia
   where  (in_ente_i   = @i_persona or in_ente_d = @i_persona)
   and  in_relacion = @w_relacion_ca

   if @@error <> 0 begin
      select @w_error = 1720069
      goto ERROR_FIN
   end

end
*/
/* Si cambia de oficial o se le asigna oficial */
if isnull(@w_oficial, '') <> isnull(@i_oficial,'') begin

   insert into cobis..cl_his_ejecutivo(
   ej_ente,         ej_funcionario,           ej_toficial,
   ej_fecha_asig,   ej_fecha_registro)
   select
   ej_ente,         ej_funcionario,           ej_toficial,
   ej_fecha_asig,   getdate()
   from cl_ejecutivo
   where ej_ente        = @i_persona
   and   ej_funcionario = @w_oficial  --oficial anterior

   if @@error <> 0 begin
      select @w_error = 1720064
      goto ERROR_FIN
   end

   delete cl_ejecutivo
   where ej_ente = @i_persona

   if @@error <> 0 begin
      select @w_error = 1720065
      goto ERROR_FIN
   end


   insert into cobis..cl_ejecutivo(
   ej_ente,      ej_funcionario,   ej_toficial,
   ej_fecha_asig)
   values(
   @i_persona,   @i_oficial,       'G',
   getdate() )

   if @@error <> 0 begin
      select @w_error  = 1720066
      goto ERROR_FIN
   end

end


if @i_tipo_ced <> @w_tipo_ced or @w_cedula <> @i_cedula begin

   exec @w_error = cobis..sp_registra_ident
   @s_user           = @s_user,
   @t_trn            = 172006,
   @i_operacion      = 'U',
   @i_ente           = @i_persona,
   @i_tipo_iden      = @w_tipo_ced,
   @i_identificacion = @w_cedula

   if @w_error <> 0 goto ERROR_FIN

end


commit tran


--UPDATE de campos del ente
if @i_operacion = 'C' begin -- Datos Complementarios

   if (select en_nombre from cobis..cl_ente where en_ente = @i_persona) is not null
   begin
      exec cobis..sp_seccion_validar
      @i_ente       = @i_persona,
      @i_operacion  = 'V',
      @i_seccion    = '1', --1 es Informacion General
      @i_completado = 'S'
   end

end


if @i_operacion = 'M' begin --UPDATE de información del cliente enviada por el mobile, PROYECTO SANTANDER

   if (select b.ea_antecedente_buro from cobis..cl_ente_aux b where ea_ente = @i_persona) is not null
   begin
      exec cobis..sp_seccion_validar
      @i_ente       = @i_persona,
      @i_operacion  = 'V',
      @i_seccion    = '2', --1 es Informacion General
      @i_completado  = 'S'
   end

end   -- finaliza @i_operacion = 'M'



if @i_operacion = 'U' begin
    --Actualiza secciones
    exec cobis..sp_seccion_validar
    @i_ente         = @i_persona,
    @i_operacion    = 'V',
    @i_seccion      = '2', --1 es IDENTITY
    @i_completado   = 'S'
end


--Extraer estado para actualizar al guarda
select @o_estado = ea_estado
from cl_ente_aux
where ea_ente = @i_persona

--Extraer vinculado para actualizar al guarda
select @o_vinculado = en_vinculacion
from cl_ente
where en_ente = @i_persona
-- UPDATE de campos cl_ente_aux (Residencia Fiscal)
if @i_operacion = 'F'
begin
 if @t_trn <> 172003
      begin
        /* Tipo de transaccion no corresponde */
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = 1720075
        return 1720075
      end

    select  @w_fatca    = b.ea_fatca,
            @w_crs      = b.ea_crs
      from  cobis..cl_ente_aux b
     where  b.ea_ente   = @i_persona
     begin tran

    -- CAPTURAR LOS DATOS QUE HAN CAMBIADO
    select @v_fatca     = @w_fatca,
           @v_crs       = @w_crs

    if @w_fatca = @i_fatca
      select @w_fatca = null, @v_fatca = null
    else
      select @w_fatca = @i_fatca

    if @w_crs = @i_crs
      select @w_crs = null, @v_crs = null
    else
      select @w_crs = @i_crs

    -- ACTUALIZACION DE DATOS
    update cl_ente_aux
       set ea_fatca      = @i_fatca,
           ea_crs        = @i_crs
     where ea_ente       = @i_persona
    if @@error <> 0
    begin
      exec sp_cerror
           @t_debug    = @t_debug,
           @t_file     = @t_file,
           @t_from     = @w_sp_name,
           @i_num      = 1720030
      return 1
    end

   insert into ts_persona_sec
               (secuencia,                    tipo_transaccion,             clase,                    fecha,
                usuario,                      terminal,                     srv,                      lsrv,
                persona,                      fatca,                        crs,                      hora)
        values (@s_ssn,                       @t_trn,                       'P',                      @s_date,
                @s_user,                      @s_term,                      @s_srv,                   @s_lsrv,
                @i_persona,                   @v_fatca,                     @v_crs,                   getdate())

        if @@error <> 0
          begin
            --Error en creacion de transaccion de servicio
            exec cobis..sp_cerror
                 @t_debug   = @t_debug,
                 @t_file    = @t_file,
                 @t_from    = @w_sp_name,
                 @i_num     = 1720049
            return 1720049
          end

        insert into ts_persona_sec
               (secuencia,                    tipo_transaccion,             clase,                        fecha,
                usuario,                      terminal,                     srv,                          lsrv,
                persona,                      fatca,                        crs,                          hora)
        values (@s_ssn,                       @t_trn,                       'A',                          @s_date,
                @s_user,                      @s_term,                      @s_srv,                       @s_lsrv,
                @i_persona,                   @v_fatca,                     @v_crs,                       getdate())
        if @@error <> 0
          begin
            --Error en creación de transacción de servicio
            exec cobis..sp_cerror
                 @t_debug   = @t_debug,
                 @t_file    = @t_file,
                 @t_from    = @w_sp_name,
                 @i_num     = 1720049
            return 1720049
          end
  commit tran

end

-- BM Sincronización de medios
select @w_telefono_recados_d = isnull(ea_telef_recados,'')
  from cobis..cl_ente_aux 
 where ea_ente = @i_persona

if (@w_telefono_recados_a  <> @w_telefono_recados_d)
begin    
    select @w_sp_local_name = 'sp_itf_act_menvio',
           @w_bdd           = 'cob_bvirtual'
    select @w_linked_s      = pa_char from cobis..cl_parametro where pa_nemonico = 'SRVL' and pa_producto = 'BVI'
    select @w_sp_linked_s   = '[' + @w_linked_s + '].[' + @w_bdd + '].[dbo].[' + @w_sp_local_name + ']'    
    
    exec @w_sp_linked_s
         @t_trn      = 18580,
         @i_ente_mis = @i_persona,
         @i_modo     = 'TC',
         @i_mail     = '',
         @i_celular  = @i_telefono_recados,
         @i_origen   = 'CLI',
         @s_srv      = @s_srv,
         @s_user     = @s_user ,
         @s_term     = @s_term,
         @s_ofi      = @s_ofi,
         @s_ssn      = @s_ssn,
         @s_lsrv     = @s_lsrv,
         @s_date     = @s_date,
         @s_sesn     = @s_ssn
end


select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Clientes
if @i_persona is not null and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
begin
   exec @w_error = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @i_persona,
      @t_debug      = @t_debug
   
   if @w_error <> 0 and @w_error is not null
   begin
      goto ERROR_FIN
   end
end

return 0

ERROR_FIN:
while @@trancount > 0 rollback
if @i_batch = 'N' begin

   exec sp_cerror
   @t_debug   = 'N',
   @t_file    = '',
   @t_from    = @w_sp_name,
   @i_num     = @w_error,
   @s_culture = @s_culture

end

return @w_error

go
