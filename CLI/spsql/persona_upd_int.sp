/********************************************************************/
/*    NOMBRE LOGICO: sp_persona_upd_int                             */
/*    NOMBRE FISICO: persona_upd_int.sp                             */
/*    PRODUCTO: Clientes                                            */
/*    Disenado por: ACU                                             */
/*    Fecha de escritura: 07-Septiembre-21                          */
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
/* Sp cascara para actualizar la información de una persona natural */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*  FECHA         AUTOR        RAZON                                */
/*  30/08/21      ACU          Emision Inicial                      */
/*  27/06/22      BDU          Funcionalidad para cambiar conyuge   */
/*  28/03/23      EBA          S763654: Actualizacion client app    */
/*                                       movil                      */
/*  30/03/23      BDU          Se agrega pseudonimo                 */
/*  26/06/23      EBA          S849151 Se envía parámetro @i_is_app */
/*                             hacia al sp sp_persona_upd para      */
/*                             realizar validacion de tipos de      */
/*                             documentos principal y tributario.   */
/*  16/08/23      EBA          R213339 Se valida si la actividad    */
/*                             económica llega vacía y se valida    */
/*                             la máscara del tip. ident            */    
/*  15/11/2023    OGU          R219376: Se asocia la oficina del    */
/*                             oficial                              */  
/*  12/03/24      BDU          R228486: Se cambia validacion mascara*/
/*  27/03/25      BDU          R248888: Se actualiza nombre param   */ 
/********************************************************************/
use cob_interface
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_persona_upd_int')
   drop proc sp_persona_upd_int
go

create proc sp_persona_upd_int(
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
  @i_tipo_tributario         char(4)         = null,  -- tipo identificacion tributario
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
  @i_retencion               char(1)       = 'N',  -- Indicador si el ente es sujeto a impuestos
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
  @i_inf_laboral             varchar(200)  = null,
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
  @i_tipo_residencia         varchar(4)       = null,
  @i_codigo_pep_relac        int           = null,
  @i_nombre_pep_relac        varchar(100)  = null,
  @i_fecha_inicio_pep        datetime      = null,
  @i_fecha_fin_pep           datetime      = null,
  @i_tipo_pep                catalogo      = null,
  @i_migrado                 varchar(30)   = null,
  @i_conyuge                 int           = null, -- Codigo del conyuge
  @i_pseudonimo              descripcion   = null, -- Pseudonimo del cliente
  @o_estado                  catalogo      = null  output,
  @o_vinculado               catalogo      = null  output,
  @o_identificationType      varchar(64)   = null out,
  @o_identificationNumber    varchar(64)   = null out
) with encryption 
as
declare
  @w_sp_name                    varchar(32),
  @w_sp_msg                     varchar(132),
  @w_error                      int,
  @w_valor_campo                varchar(30),
  @w_pais_default               int,
  @w_pais_local                 int,
  @w_tipo_nacionalidad          char(1),
  @w_mascara                    varchar(64),
  @w_conyuge                    int,
  @w_relacion_ca                catalogo
  
select @w_sp_name = 'sp_persona_upd_int'
select @w_error = 1720548

select @i_ciudad_nac = p_ciudad_nac 
from   cobis..cl_ente
where  en_ente = @i_persona

select @w_pais_default = pa_smallint
   from cobis..cl_parametro
   where pa_nemonico = 'CP' --CODIGO DE PAIS
   and   pa_producto = 'CLI'
     
/*VALIDACIONES CAMPOS null String*/
if @i_banco = 'null'
begin
   select @i_banco = null
end

if @i_c_apellido = 'null'
begin
   select @i_c_apellido = null
end

if @i_calle_orig = 'null'
begin
   select @i_calle_orig = null
end

if @i_carg_pub = 'null'
begin
   select @i_carg_pub = null
end

if @i_estado_orig = 'null'
begin
   select @i_estado_orig = null
end

if @i_exterior_orig = 'null'
begin
   select @i_exterior_orig = null
end

if @i_forma_migratoria = 'null'
begin
   select @i_forma_migratoria = null
end

if @i_migrado = 'null'
begin
   select @i_migrado = null
end

if @i_naturalizado = 'null'
begin
   select @i_naturalizado = null
end

if @i_nro_extranjero = 'null'
begin
   select @i_nro_extranjero = null
end

if @i_numero_iden = 'null'
begin
   select @i_numero_iden = null
end

if @i_rel_carg_pub = 'null'
begin
   select @i_rel_carg_pub = null
end

if @i_tipo_iden = 'null'
begin
   select @i_tipo_iden = null
end

if @i_tipo_residencia = 'null'
begin
   select @i_tipo_residencia = null
end

select @w_sp_msg = convert(varchar,@w_error)+ ' - ' + re_valor                                                                                                                                                                           
from   cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int                                                                                                                                                                                                                        
and    re_cultura = UPPER(@s_culture))                                                                                                                                                                                                           
where numero = @w_error 

/* VALIDACIONES */
/* CAMPOS REQUERIDOS PARA PROSPECTO SOLTERO */
if isnull(@i_persona,'') = '' and @i_persona <> 0
begin
   select @w_valor_campo  = 'personSequential'
   goto VALIDAR_ERROR
end


if isnull(@i_nombre,'') = ''
begin
   select @w_valor_campo  = 'firstName'
   goto VALIDAR_ERROR
end

if isnull(@i_p_apellido,'') = ''
begin
   select @w_valor_campo  = 'surname'
   goto VALIDAR_ERROR
end


if isnull(@i_pais,'') = ''
begin
   select @w_valor_campo  = 'nationalityCode'
   goto VALIDAR_ERROR
end


if isnull(@i_depa_nac,'') = ''
begin
   select @w_valor_campo  = 'provOfBirth'
   goto VALIDAR_ERROR
end

if isnull(@i_fecha_nac,'') = ''
begin
   select @w_valor_campo  = 'birthDate'
   goto VALIDAR_ERROR
end

if isnull(@i_tipo_ced,'') = ''
begin
   select @w_valor_campo  = 'identificationType'
   goto VALIDAR_ERROR
end

if isnull(@i_cedula,'') = ''
begin
   select @w_valor_campo  = 'documentNumber'
   goto VALIDAR_ERROR
end

if isnull(@i_sexo,'') = ''
begin
   select @w_valor_campo  = 'sexCode'
   goto VALIDAR_ERROR
end

if isnull(@i_genero,'') = ''
begin
   select @w_valor_campo  = 'genderCode'
   goto VALIDAR_ERROR
end

if isnull(@i_estado_civil,'') = ''
begin
   select @w_valor_campo  = 'maritalStatusCode'
   goto VALIDAR_ERROR
end

if isnull(@i_retencion,'') = ''
begin
   select @w_valor_campo  = 'withholdingTax'
   goto VALIDAR_ERROR
end

if isnull(@i_num_cargas,'') = '' and @i_num_cargas <> 0
begin
   select @w_valor_campo  = 'economicDependents'
   goto VALIDAR_ERROR
end

if isnull(@i_nivel_estudio,'') = ''
begin
   select @w_valor_campo  = 'levelStudy'
   goto VALIDAR_ERROR
end

if isnull(@i_actividad,'') = ''
begin
   select @w_valor_campo  = 'economicActivity'
   goto VALIDAR_ERROR
end

if isnull(@i_ocupacion,'') = ''
begin
   select @w_valor_campo  = 'occupation'
   goto VALIDAR_ERROR
end

if isnull(@i_oficial,'') = ''
begin
   select @w_valor_campo  = 'official' --validar q oficial exista
   goto VALIDAR_ERROR
end

/* CAMPOS REQUERIDOS DEPENDIENDO DE LA DATA */
if @i_tipo_tributario is not null -- si ingresa Tipo de indeficacion tributaria
begin
    if isnull(@i_nit,'') = ''
    begin
       select @w_valor_campo  = 'numberIdentificationTributaria'
       goto VALIDAR_ERROR
    end
end

/* FIN DE CAMPOS REQUERIDOS DEPENDIENDO DE LA DATA */



/* VALIDACIONES DE CATALOGOS */
-- pais 
if not exists(select 1 from cobis..cl_pais where pa_pais = @i_pais)
begin
   select @w_error = 1720110
   select @w_valor_campo  = @i_pais
   goto VALIDAR_ERROR
end
if convert(smallint,@i_pais) = @w_pais_default
begin
   -- provincia
   if not exists(select 1 from cobis..cl_provincia 
             where pv_provincia = @i_depa_nac
             and   pv_pais      = @i_pais)
   begin
      select @w_error = 1720110
      select @w_valor_campo  = @i_depa_nac
      goto VALIDAR_ERROR
   end
end
-- tipo de residencia
if @i_tipo_residencia is not null
begin
    exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_tipo_residencia', @i_valor = @i_tipo_residencia
    if @w_error <> 0 and @w_error != 1720018
    begin
       set @w_sp_msg = null
       goto ERROR_FIN 
    end
    else if @w_error = 1720018 
    begin
        select @w_valor_campo  = @i_tipo_residencia         
        select @w_error = 1720552 
        goto VALIDAR_ERROR 
    end
end

-- tipo de identificacion
if convert(smallint,@i_pais) = @w_pais_default
     select @w_tipo_nacionalidad = 'N'
else
     select @w_tipo_nacionalidad = 'E'

if exists(select 1 from cobis..cl_tipo_identificacion where ti_tipo_cliente = 'P' 
          and ti_tipo_documento = 'P' 
          and ti_nacionalidad   = @w_tipo_nacionalidad 
          and ti_codigo         = @i_tipo_ced)
begin
    select @w_mascara = ti_mascara from cobis..cl_tipo_identificacion where ti_tipo_cliente = 'P' 
       and ti_tipo_documento = 'P' 
       and ti_nacionalidad   = @w_tipo_nacionalidad 
       and ti_codigo         = @i_tipo_ced
	   
    if charindex('-', @i_cedula) = 0  --Se manda sin mascara
    begin
       select @w_mascara = replace(@w_mascara, '-', '')
    end
    
    if(len(@w_mascara) <> len(@i_cedula))
    begin
         select @w_valor_campo  = @i_tipo_ced        
         select @w_error = 1720550 
         goto VALIDAR_ERROR          
    end
end
else          
begin
     select @w_valor_campo  = @i_tipo_ced         
     select @w_error = 1720552 
     goto VALIDAR_ERROR 
end
      
-- tipo de identificacion tributaria
if @i_tipo_tributario is not null
begin

    if not exists(select 1 from cobis..cl_tipo_identificacion where ti_tipo_cliente = 'P' 
              and ti_tipo_documento = 'T' 
              and ti_nacionalidad = @w_tipo_nacionalidad 
              and ti_codigo = @i_tipo_tributario)
    begin
       select @w_valor_campo  = @i_tipo_tributario         
       select @w_error = 1720552 
       goto VALIDAR_ERROR 
    end
end

-- sexo
exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_sexo', @i_valor = @i_sexo
if @w_error <> 0 and @w_error != 1720018 
begin
   select @w_valor_campo  = @i_sexo
   goto VALIDAR_ERROR 
end
else if @w_error = 1720018 
begin
   select @w_valor_campo  = @i_sexo         
   select @w_error = 1720552 
   goto VALIDAR_ERROR 
end

-- genero
exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_genero', @i_valor = @i_genero
if @w_error <> 0 and @w_error != 1720018
begin
   select @w_valor_campo  = @i_genero
   goto VALIDAR_ERROR
end
else if @w_error = 1720018 
begin
   select @w_valor_campo  = @i_genero         
   select @w_error = 1720552 
   goto VALIDAR_ERROR 
end

-- estado civil
exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_ecivil', @i_valor = @i_estado_civil
if @w_error <> 0 and @w_error != 1720018
begin
   select @w_valor_campo  = @i_estado_civil
   goto VALIDAR_ERROR
end 
else if @w_error = 1720018 
begin
   select @w_valor_campo  = @i_estado_civil         
   select @w_error = 1720552 
   goto VALIDAR_ERROR 
end

-- sujeto de retencion
exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cr_sol_exp', @i_valor = @i_retencion
if @w_error <> 0 and @w_error != 1720018
begin
   select @w_valor_campo  = @i_retencion
   goto VALIDAR_ERROR
end 
else if @w_error = 1720018 
begin 
   select @w_valor_campo  = @i_retencion         
   select @w_error = 1720552 
   goto VALIDAR_ERROR 
end

-- escolaridad
exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_nivel_estudio', @i_valor = @i_nivel_estudio
if @w_error <> 0 and @w_error != 1720018
begin
   select @w_valor_campo  = @i_nivel_estudio
   goto VALIDAR_ERROR
end 
else if @w_error = 1720018 
begin
   select @w_valor_campo  = @i_nivel_estudio         
   select @w_error = 1720552 
   goto VALIDAR_ERROR 
end

-- actividad economica
exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_actividad_ec', @i_valor = @i_actividad
if @w_error <> 0 and @w_error != 1720018
begin
   select @w_valor_campo  = @i_actividad
   goto VALIDAR_ERROR
end
else if @w_error = 1720018 
begin
   select @w_valor_campo  = @i_actividad         
   select @w_error = 1720552 
   goto VALIDAR_ERROR 
end

-- ocupacion
exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_ocupacion', @i_valor = @i_ocupacion
if @w_error <> 0 and @w_error != 1720018
begin
   select @w_valor_campo  = @i_ocupacion
   goto VALIDAR_ERROR
end
else if @w_error = 1720018 
begin
   select @w_valor_campo  = @i_ocupacion         
   select @w_error = 1720552 
   goto VALIDAR_ERROR 
end

/*VALIDACION PARA OFICINA CUANDO LLEGA NULL*/
if @i_oficina is null or @i_oficina = 0 or @i_oficina = ''
begin
   select @i_oficina = fu_oficina                      --R219376: Se asocia la oficina del oficial
     from cobis..cc_oficial, cobis..cl_funcionario
    where oc_oficial = @i_oficial
      and fu_funcionario = oc_funcionario
end
-- oficial
if not exists (select 1
               from cobis..cl_funcionario, 
                    cobis..cc_oficial, 
                    cobis..ad_usuario
               where fu_funcionario = oc_funcionario
               and   oc_oficial     = @i_oficial
               and   us_oficina     = @i_oficina
               and   us_login       = fu_login)   
begin
   select @w_error = 1720551
   set @w_sp_msg = null
   goto ERROR_FIN
end
/* FIN DE VALIDACIONES DE CATALOGOS */

/* PASO A MAYUSCULAS*/

select @i_nombre = upper(@i_nombre)
select @i_p_apellido = upper(@i_p_apellido)

if @i_segnombre is not null
begin
   select @i_segnombre = upper(@i_segnombre)
end

if @i_s_apellido is not null
begin
   select @i_s_apellido = upper(@i_s_apellido)
end

if @i_c_apellido is not null
begin
   select @i_c_apellido = upper(@i_c_apellido)
end

/* FIN DE PASO A MAYUSCULAS */


exec @w_error = cobis..sp_persona_upd
@s_user                    = @s_user,                    
@s_term                    = @s_term,                   
@s_date                    = @s_date,                    
@s_ofi                     = @s_ofi,                     
@s_ssn                     = @s_ssn,                     
@s_srv                     = @s_srv,                     
@s_lsrv                    = @s_lsrv,                    
@s_culture                 = @s_culture,                 
@t_trn                     = 172003,                     
@t_show_version            = @t_show_version,            
@t_debug                   = @t_debug,                   
@t_file                    = @t_file,                    
@i_operacion               = @i_operacion,               
@i_batch                   = @i_batch,                   
@i_verificado              = @i_verificado,              
@i_persona                 = @i_persona,                 
@i_nombre                  = @i_nombre,                  
@i_p_apellido              = @i_p_apellido,              
@i_s_apellido              = @i_s_apellido,              
@i_sexo                    = @i_sexo,                    
@i_genero                  = @i_genero,                  
@i_fecha_nac               = @i_fecha_nac,               
@i_tipo_ced                = @i_tipo_ced,                
@i_tipo_tributario         = @i_tipo_tributario,         
@i_cedula                  = @i_cedula,                  
@i_pasaporte               = @i_pasaporte,               
@i_pais                    = @i_pais,                    
@i_ciudad_nac              = @i_ciudad_nac,              
@i_lugar_doc               = @i_lugar_doc,               
@i_nivel_estudio           = @i_nivel_estudio,           
@i_tipo_vivienda           = @i_tipo_vivienda,           
@i_profesion               = @i_profesion,               
@i_estado_civil            = @i_estado_civil,            
@i_num_cargas              = @i_num_cargas,              
@i_nivel_ing               = @i_nivel_ing,               
@i_nivel_egr               = @i_nivel_egr,               
@i_filial                  = @i_filial,                  
@i_oficina                 = @i_oficina,                 
@i_tipo                    = @i_tipo,                    
@i_grupo                   = @i_grupo,                   
@i_oficial                 = @i_oficial,                 
@i_oficial_sup             = @i_oficial_sup,             
@i_retencion               = @i_retencion,               
@i_exc_sipla               = @i_exc_sipla,               
@i_exc_por2                = @i_exc_por2,                
@i_asosciada               = @i_asosciada,               
@i_tipo_vinculacion        = @i_tipo_vinculacion,        
@i_actividad               = @i_actividad,               
@i_comentario              = @i_comentario,              
@i_fecha_emision           = @i_fecha_emision,           
@i_fecha_expira            = @i_fecha_expira,            
@i_sector                  = @i_sector,                  
@i_referido                = @i_referido,                
@i_gran_contribuyente      = @i_gran_contribuyente,      
@i_situacion_cliente       = @i_situacion_cliente,       
@i_patrim_tec              = @i_patrim_tec,              
@i_fecha_patrim_bruto      = @i_fecha_patrim_bruto,      
@i_total_activos           = @i_total_activos,           
@i_rep_superban            = @i_rep_superban,            
@i_preferen                = @i_preferen,                
@i_cem                     = @i_cem,                     
@i_c_apellido              = @i_c_apellido,              
@i_segnombre               = @i_segnombre,               
@i_nit                     = @i_nit,                     
@i_depart_doc              = @i_depart_doc,              
@i_numord                  = @i_numord,                  
@i_promotor                = @i_promotor,                
@i_doc_validado            = @i_doc_validado,            
@i_nacionalidad            = @i_nacionalidad,            
@i_codigo                  = @i_codigo,                  
@i_inss                    = @i_inss,                    
@i_licencia                = @i_licencia,                
@i_ingre                   = @i_ingre,                   
@i_en_id_tutor             = @i_en_id_tutor,             
@i_en_nom_tutor            = @i_en_nom_tutor,            
@i_digito                  = @i_digito,                  
@i_valprov                 = @i_valprov,                 
@i_categoria               = @i_categoria,               
@i_referidor_ecu           = @i_referidor_ecu,           
@i_carg_pub                = @i_carg_pub,                
@i_rel_carg_pub            = @i_rel_carg_pub,            
@i_situacion_laboral       = @i_situacion_laboral,       
@i_bienes                  = @i_bienes,                  
@i_otros_ingresos          = @i_otros_ingresos,          
@i_origen_ingresos         = @i_origen_ingresos,         
@i_ejecutar                = @i_ejecutar,                
@i_ea_estado               = @i_ea_estado,               
@i_ea_observacion_aut      = @i_ea_observacion_aut,      
@i_ea_contrato_firmado     = @i_ea_contrato_firmado,     
@i_ea_menor_edad           = @i_ea_menor_edad,           
@i_ea_conocido_como        = @i_ea_conocido_como,        
@i_ea_cliente_planilla     = @i_ea_cliente_planilla,     
@i_ea_cod_risk             = @i_ea_cod_risk,             
@i_ea_sector_eco           = @i_ea_sector_eco,           
@i_ea_actividad            = @i_ea_actividad,            
@i_ea_empadronado          = @i_ea_empadronado,          
@i_ea_lin_neg              = @i_ea_lin_neg,              
@i_ea_seg_neg              = @i_ea_seg_neg,              
@i_ea_val_id_check         = @i_ea_val_id_check,         
@i_ea_ejecutivo_con        = @i_ea_ejecutivo_con,        
@i_ea_suc_gestion          = @i_ea_suc_gestion,          
@i_ea_constitucion         = @i_ea_constitucion,         
@i_ea_remp_legal           = @i_ea_remp_legal,           
@i_ea_apoderado_legal      = @i_ea_apoderado_legal,      
@i_ea_act_comp_kyc         = @i_ea_act_comp_kyc,         
@i_ea_fecha_act_kyc        = @i_ea_fecha_act_kyc,        
@i_ea_no_req_kyc_comp      = @i_ea_no_req_kyc_comp,      
@i_ea_act_perfiltran       = @i_ea_act_perfiltran,       
@i_ea_fecha_act_perfiltran = @i_ea_fecha_act_perfiltran, 
@i_ea_con_salario          = @i_ea_con_salario,          
@i_ea_fecha_consal         = @i_ea_fecha_consal,         
@i_ea_sin_salario          = @i_ea_sin_salario,          
@i_ea_fecha_sinsal         = @i_ea_fecha_sinsal,         
@i_ea_actualizacion_cic    = @i_ea_actualizacion_cic,    
@i_ea_fecha_act_cic        = @i_ea_fecha_act_cic,        
@i_ea_fuente_ing           = @i_ea_fuente_ing,           
@i_ea_act_prin             = @i_ea_act_prin,             
@i_ea_detalle              = @i_ea_detalle,              
@i_ea_act_dol              = @i_ea_act_dol,              
@i_ea_cat_aml              = @i_ea_cat_aml,              
@i_fecha_verifi            = @i_fecha_verifi,            
@i_ea_discapacidad         = @i_ea_discapacidad,         
@i_ea_tipo_discapacidad    = @i_ea_tipo_discapacidad,    
@i_ea_ced_discapacidad     = @i_ea_ced_discapacidad,     
@i_egresos                 = @i_egresos,                 
@i_ifi                     = @i_ifi,                     
@i_asfi                    = @i_asfi,                    
@i_path_foto               = @i_path_foto,               
@i_nit_venc                = @i_nit_venc,                
@i_emproblemado            = @i_emproblemado,            
@i_dinero_transac          = @i_dinero_transac,          
@i_pep                     = @i_pep,                     
@i_mnt_pasivo              = @i_mnt_pasivo,              
@i_vinculacion             = @i_vinculacion,             
@i_ant_nego                = @i_ant_nego,                
@i_ventas                  = @i_ventas,                  
@i_ct_ventas               = @i_ct_ventas,               
@i_ct_operativos           = @i_ct_operativos,           
@i_ea_indefinido           = @i_ea_indefinido,           
@i_persona_pub             = @i_persona_pub,             
@i_ing_SN                  = @i_ing_SN,                  
@i_otringr                 = @i_otringr,                 
@i_depa_nac                = @i_depa_nac,                
@i_nac_aux                 = @i_nac_aux,                 
@i_pais_emi                = @i_pais_emi,                
@i_ea_nro_ciclo_oi         = @i_ea_nro_ciclo_oi,         
@i_ea_cta_banco            = @i_ea_cta_banco,            
@i_banco                   = @i_banco,                   
@i_estado_std              = @i_estado_std,              
@i_calificacion            = @i_calificacion,            
@i_calif_cliente           = @i_calif_cliente,           
@i_partner                 = @i_partner,                 
@i_lista_negra             = @i_lista_negra,             
@i_telefono_recados        = @i_telefono_recados,        
@i_numero_ife              = @i_numero_ife,              
@i_numero_serie_firma      = @i_numero_serie_firma,      
@i_persona_recados         = @i_persona_recados,         
@i_antecedentes_buro       = @i_antecedentes_buro,       
@i_pais_nac                = @i_pais_nac,                
@i_naturalizado            = @i_naturalizado,            
@i_forma_migratoria        = @i_forma_migratoria,        
@i_nro_extranjero          = @i_nro_extranjero,          
@i_calle_orig              = @i_calle_orig,              
@i_exterior_orig           = @i_exterior_orig,           
@i_estado_orig             = @i_estado_orig,             
@i_tipo_iden               = @i_tipo_iden,               
@i_numero_iden             = @i_numero_iden,             
@i_lug_trab                = @i_inf_laboral,             
@i_tipo_operacion          = @i_tipo_operacion,          
@i_provincia_act           = @i_provincia_act,           
@i_lugar_act               = @i_lugar_act,               
@i_ea_ingreso_legal        = @i_ea_ingreso_legal,        
@i_ea_actividad_legal      = @i_ea_actividad_legal,      
@i_ea_otra_cuenta          = @i_ea_otra_cuenta,          
@i_fatca                   = @i_fatca,                   
@i_crs                     = @i_crs,                     
@i_ocupacion               = @i_ocupacion,               
@i_origen                  = @i_origen,                  
@i_provincia_res           = @i_provincia_res,           
@i_nivel_cuenta            = @i_nivel_cuenta,            
@i_cat_num_trn_mes_ini     = @i_cat_num_trn_mes_ini,     
@i_cat_mto_trn_mes_ini     = @i_cat_mto_trn_mes_ini,     
@i_cat_sdo_prom_mes_ini    = @i_cat_sdo_prom_mes_ini,    
@i_cat_gpo_mtz_riesgo      = @i_cat_gpo_mtz_riesgo,      
@i_pto_num_trn_mes_ini     = @i_pto_num_trn_mes_ini,     
@i_pto_mto_trn_mes_ini     = @i_pto_mto_trn_mes_ini,     
@i_pto_sdo_prom_mes_ini    = @i_pto_sdo_prom_mes_ini,    
@i_tipo_residencia          =@i_tipo_residencia,         
@i_codigo_pep_relac        = @i_codigo_pep_relac,        
@i_nombre_pep_relac        = @i_nombre_pep_relac,        
@i_fecha_inicio_pep        = @i_fecha_inicio_pep,        
@i_fecha_fin_pep           = @i_fecha_fin_pep,           
@i_tipo_pep                = @i_tipo_pep,
@i_pseudonimo              = @i_pseudonimo,
@i_is_app                  = 'S',                
@o_estado                  = @o_estado out,              
@o_vinculado               = @o_vinculado out

if @w_error <> 0
begin
   set @w_sp_msg = null
   goto ERROR_FIN;
end

/* ACTUALIZACION DE DATOS SENSIBLES */
exec @w_error = cobis..sp_datos_sensibles_cliente
@t_trn                     = 172045,
@s_ssn                     = @s_ssn,
@s_user                    = @s_user,
@s_term                    = @s_term,
@s_date                    = @s_date,    
@s_srv                     = @s_srv ,
@s_lsrv                    = @s_lsrv,
@s_ofi                     = @s_ofi,
@s_rol                     = NULL,
@t_debug                   = @t_debug,
@t_file                    = @t_file,
@t_show_version            = @t_show_version,
@i_batch                   = @i_batch,
@i_ente                    = @i_persona,
@i_nombre                  = @i_nombre,
@i_segnombre               = @i_segnombre,
@i_p_p_apellido            = @i_p_apellido,
@i_p_s_apellido            = @i_s_apellido,
@i_sexo                    = @i_sexo,
@i_genero                  = @i_genero,
@i_fecha_nac               = @i_fecha_nac,
@i_provincia_nac           = @i_depa_nac,
@i_estado_civil            = @i_estado_civil,
@i_curp                    = null,
@i_rfc                     = null,
@i_apellido_c              = @i_c_apellido,
@i_oficial                 = @i_oficial,
@i_migrado                 = @i_migrado,
@i_identificationType      = @i_tipo_ced,
@i_identificationNumber    = @i_cedula,
@i_tipo_residencia         = @i_tipo_residencia,
@i_ciudad_emi              = @i_lugar_doc,
@i_fecha_emi               = @i_fecha_emision,
@i_fecha_vto               = @i_fecha_expira,
@i_ea_con_como             = @i_ea_conocido_como,
@i_is_app                  = 'S',
@o_identificationType      = @o_identificationType out,
@o_identificationNumber    = @o_identificationNumber out

if @w_error <> 0
begin
   set @w_sp_msg = null
   goto ERROR_FIN;
end

--RELACION DE CONYUGE
if @i_conyuge is not null and @i_conyuge <> 0
begin
   --VALIDA QUE EXISTA
   if not exists(select 1 from cobis..cl_ente where en_ente = @i_conyuge)
   begin
      select @w_sp_msg = null
      select @w_error = 1720021
      goto ERROR_FIN
   end
   
   --VALIDAR QUE NO ESTE RELACIONADO EL CONYUGE CON OTRO
   if exists(select 1 from cobis..cl_instancia where in_ente_d in (@i_conyuge) or in_ente_i in (@i_conyuge))
   begin
      select @w_sp_msg = null
      select @w_error = 1720525
      goto ERROR_FIN
   end
   
   update cobis..cl_ente set p_estado_civil = 'CA' where en_ente = @i_conyuge
   
   if @@rowcount = 0
   begin
      select @w_sp_msg = null
      select @w_error = 1720368
      goto ERROR_FIN
   end
   
   
   select @w_relacion_ca = (select pa_tinyint from cobis..cl_parametro 
                            where  pa_nemonico = 'CONY' 
                            and    pa_producto='CLI')
   --obtener al conyuge
   select @w_conyuge = in_ente_d 
   from  cobis..cl_instancia 
   where  in_ente_i   = @i_persona
   and    in_relacion = @w_relacion_ca
   --Si el conyuge al ingresar es diferente del actual
   if @i_conyuge <> isnull(@w_conyuge, @i_conyuge)
   begin
      --eliminar la relacion
      delete cobis..cl_instancia
      where  (in_ente_i   = @i_persona or in_ente_d = @i_persona)
      and  in_relacion = @w_relacion_ca
      
      if @@error <> 0
      begin
         select @w_sp_msg = null
         select @w_error = 1720197
         goto ERROR_FIN
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
      @i_persona,                             @w_conyuge,                             'I',
      getdate()   
      )
      if @@error <> 0
      begin
         select @w_sp_msg = null
         select @w_error = 1720415
         goto ERROR_FIN
      end
   end
   
   --obtener al conyuge
   select @w_conyuge = in_ente_d 
   from  cobis..cl_instancia 
   where  in_ente_i   = @i_persona
   and    in_relacion = @w_relacion_ca
   
   --Si no tiene conyuge
   if not exists(select 1
                 from  cobis..cl_instancia 
                 where  in_ente_i   = @i_persona
                 and    in_relacion = @w_relacion_ca)
   begin
      --Crear la relacion
      exec @w_error = cobis..sp_instancia
         @s_ssn          = @s_ssn,         
         @s_user         = @s_user,        
         @s_term         = @s_term,        
         @s_date         = @s_date,        
         @s_srv          = @s_srv,         
         @s_lsrv         = @s_lsrv,         
         @s_ofi          = @s_ofi,         
         @s_culture      = @s_culture,     
         @t_trn          = 172029,           
         @t_show_version = @t_show_version,
         @i_operacion    = 'I',       
         @i_derecha      = @i_conyuge,     
         @i_izquierda    = @i_persona,   
         @i_lado         = 'C'  
      
      if @w_error <> 0
      begin
         set @w_sp_msg = null
         goto ERROR_FIN;
      end
      
      insert into cobis..ts_instancia (
      secuencial,                             tipo_transaccion,                       clase,
      fecha,                                  usuario,                                terminal,
      srv,                                    lsrv,                                   relacion,
      izquierda,                              derecha,                                lado,                            
      fecha_relacion)
      values(
      @s_ssn,                                 172029,                                 'N',
      getdate(),                              @s_user,                                @s_term,
      @s_srv,                                 @s_lsrv,                                @w_relacion_ca,
      @i_persona,                             @i_conyuge,                             'I',
      getdate()   
      )
      
      if @@error <> 0
      begin
         select @w_sp_msg = null
         select @w_error = 1720415
         goto ERROR_FIN
      end
   end  
end

return 0             

VALIDAR_ERROR:
select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo , @w_error, @s_culture)
goto ERROR_FIN

ERROR_FIN:

exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_msg      = @w_sp_msg,
         @i_num      = @w_error
         
return @w_error

go
