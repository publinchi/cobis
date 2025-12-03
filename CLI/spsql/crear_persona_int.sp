/************************************************************************/
/*   NOMBRE LOGICO:         sp_crear_persona_int                        */
/*   NOMBRE FISICO:         crear_persona_int.sp                        */
/*   BASE DE DATOS:         cobis                                       */
/*   PRODUCTO:              Clientes                                    */
/*   DISENADO POR:          JMEG                                        */
/*   FECHA DE ESCRITURA:    30-Abr-2019                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
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
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_crear_persona                           */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/08/21         ACU       Emision Inicial                      */
/*      21/03/22         PJA       Se agrega controles para desplegar   */
/*                                 mensaje de error                     */
/*      30/03/23         BDU       Se agrega pseudonimo                 */
/*      07/09/23         OGU       S896481 - Inclusión de campos para la*/  
/*                                 creación de clientes modo Offline APP*/
/*      15/11/23         OGU       R219376: Se asocia la oficina del    */
/*                                 oficial                              */     
/*      12/03/24         BDU       R228486: Se cambia validacion mascara*/
/************************************************************************/


use cob_interface
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_crear_persona_int')
   drop proc sp_crear_persona_int
go

create procedure sp_crear_persona_int (
       @s_ssn                              int,
       @s_sesn                             int           = null,
       @s_user                             login         = null,
       @s_term                             varchar(32)   = null,
       @s_date                             datetime,
       @s_srv                              varchar(30)   = null,
       @s_lsrv                             varchar(30)   = null,
       @s_ofi                              smallint      = null,
       @s_rol                              smallint      = null,
       @s_org_err                          char(1)       = null,
       @s_error                            int           = null,
       @s_sev                              tinyint       = null,
       @s_msg                              descripcion   = null,
       @s_org                              char(1)       = null,
       @s_culture                          varchar(10)   = 'NEUTRAL',
       @t_debug                            char(1)       = 'n',
       @t_file                             varchar(10)   = null,
       @t_from                             varchar(32)   = null,
       @t_trn                              int           = null,
       @t_show_version                     bit           = 0,     -- versionamiento
       @i_nombre                           descripcion   = null,  -- primer nombre del cliente
       @i_papellido                        descripcion   = null,  -- primer apellido del cliente
       @i_sapellido                        descripcion   = null,  -- segundo apellido del cliente
       @i_filial                           tinyint       = null,  -- codigo de la filial
       @i_oficina                          smallint      = null,  -- codigo de la oficina
       @i_tipo_ced                         char(4)       = null,  -- tipo del documento de identificacion
       @i_tipo_tributario                  char(4)       = null,  -- tipo identificacion tributario
       @i_cedula                           varchar(30)   = null,  -- numero del documento de identificacion
       @i_login_oficial                    varchar(20)   = null,  -- codigo del oficial asignado al cliente
       @i_c_apellido                       varchar(30)   = null,  -- apellido casada
       @i_segnombre                        varchar(50)   = null,  -- segundo nombre
       @i_sector                           catalogo      = null,  -- sector economico del cliente
       @i_sexo                             varchar(10)   = null,  -- codigo del sexo del cliente
       @i_genero                           varchar(10)   = null,  -- codigo del genero del cliente
       @i_est_civil                        varchar(10)   = null,  -- estado civil del cliente
       @i_ea_estado                        catalogo      = null,  -- estado cliente
       @i_dir_virtual                      varchar(50)   = null,    -- email del cliente
       @i_dir_virtual_v                    char(1)       = 'N',   -- email del cliente esta verificado?
       @i_fecha_expira                     datetime     = null,
       @i_fecha_nac                        datetime      = null,
       @i_profesion                        catalogo      = null,  -- carrera profesional
       @i_ocupacion                        catalogo      = null,
       @i_tipo_vivienda                    catalogo      = null,
       @i_nombre_c                         descripcion   = null,  -- primer nombre del c=nyuge
       @i_papellido_c                      descripcion   = null,  -- primer apellido del c=nyuge
       @i_sapellido_c                      descripcion   = null,  -- segundo apellido del c=nyuge
       @i_tipo_ced_c                       char(4)       = null,  -- tipo del documento de identificacion c=nyuge
       @i_tipo_tributario_c                char(4)       = null,  -- tipo del documento de identificacion tributario c=nyuge
       @i_cedula_c                         varchar(30)   = null,  -- numero del documento de identificacion c=nyuge
       @i_segnombre_c                      varchar(50)   = null,  -- segundo nombre c=nyuge
       @i_sexo_c                           varchar(10)   = null,  -- codigo del sexo del c=nyuge
       @i_genero_c                         varchar(10)   = null,  -- codigo del genero del conyuge
       @i_est_civil_c                      varchar(10)   = null,  -- estado civil del c=nyuge
       @i_ea_estado_c                      catalogo      = null,  -- estado del c=nyuge
       @i_c_apellido_c                     varchar(30)   = null,
       @i_fecha_expira_c                   datetime     = null,
       @i_fecha_nac_c                      datetime        = null,
       @i_profesion_c                      catalogo      = null,
       @i_sector_c                         catalogo      = null,
       @i_calif_cliente                    catalogo      = null,
       @i_vinculacion                      char(1)       = null,
       @i_tipo_vinculacion                 varchar(10)   = null,
       @i_emproblemado                     char(1)       = null,  -- manejo de emproblemados
       @i_dinero_transac                   money         = null,  -- mnt de dinero transacciona mensualmente
       @i_manejo_doc                       varchar(25)   = null,  -- manejo de documentos
       @i_pep                              char(1)       = null,  -- s/n persona expuesta politicamente
       @i_mnt_activo                       money         = null,  -- monto de los activos del cliente
       @i_mnt_pasivo                       money         = null,  -- monto de los pasivos del cliente
       @i_tiempo_reside                    int           = null,  -- tiempo de residencia (meses)
       @i_ant_nego                         int           = null,  -- antiguedad del negicio (meses)
       @i_ventas                           money         = null,  -- ventas
       @i_ot_ingresos                      money         = null,  -- otros ingresos
       @i_ct_ventas                        money         = null,  -- costos ventas
       @i_ct_operativos                    money         = null,  -- costos operativos
       @i_ciudad_nac                       int           = null,  -- lgu santander: calculo de curp y rfc
       @i_ciudad_nac_c                     int           = null,  -- lgu santander: calculo de curp y rfc
       @i_operacion                        char(1),
       @i_ea_nro_ciclo_oi                  int           = null,  -- lpo santander --numero de ciclos en otras entidades
       @i_comentario                       varchar(254)  = null,
       @i_batch                            char(1)       = 'N'      , -- lgu: sp que se dispara desde fe o batch
       @i_num_ciclos                       int            = null,
       @i_banco                            varchar(20)   = null,
       @i_pais_nac                         varchar(20)   = null,
       @i_nacionalidad                     int           = null,
       @i_provincia_nac                    int             = null,
       @i_naturalizado                     char(1)         = null,
       @i_forma_migratoria                 varchar(64)   = null,
       @i_nro_extranjero                   varchar(64)   = null,
       @i_calle_orig                       varchar(70)   = null,
       @i_exterior_orig                    varchar(40)   = null,
       @i_estado_orig                      varchar(40)   = null,
       @i_escolaridad                      catalogo      = null,
       @i_nivel_estudio                    catalogo      = null,
       @i_actividad                        catalogo      = null,
       @i_retencion                        char(1)       = 'N',
       @i_ea_fuente_ing                    catalogo      = null,
       @i_ea_discapacidad                  char(1)       = null,    --PRESENCIA DE DISCAPACIDAD
       @i_ea_tipo_discapacidad             catalogo      = null,    --TIPO DE DISCAPACIDAD
       @i_ea_ced_discapacidad              varchar(30)   = null,    --CEDULA DE DISCAPACIDAD
       @i_pais_nac_c                       varchar(20)   = null,
       @i_nacionalidad_c                   int           = null,
       @i_provincia_nac_c                  int           = null,
       @i_naturalizado_c                   char(1)         = null,
       @i_forma_mig_c                      varchar(10)   = null,
       @i_numero_ext_c                     varchar(64)   = null,
       @i_tipo_iden_c                      varchar(13)   = null,
       @i_numero_iden_c                    varchar(32)   = null,
       @i_localidad                       varchar(20)   = null,
       @i_calle_orig_c                     varchar(70)   = null,
       @i_exterior_orig_c                  varchar(40)   = null,
       @i_estado_orig_c                    varchar(40)   = null,
       @i_escolaridad_c                    catalogo      = null,
       @i_nivel_estudio_c                  catalogo      = null,
       @i_ocupacion_c                      catalogo      = null,
       @i_actividad_c                      catalogo      = null,
       @i_ident_tipo_c                     varchar(10)   = null,
       @i_ident_num_c                      varchar(30)  = null,
       @i_email_c                          varchar(50)   = null,
       @i_email_c_v                        char(1)       = null, --email del conyuge está verificado
       @i_nro_ciclo                        int           = null,
       @i_ingre                            varchar(10)   = null,  -- codigo de ingreso de la persona
       @i_oficial                          int           = null,
       @i_tipo_iden                        varchar(13)   = null,
       @i_numero_iden                      varchar(20)   = null,
       @i_num_cargas                       int           = null,
       @i_sic_asincronico                  char(1)       = 's',
       @i_estado_afiliacion                catalogo      = null,
       @i_ingresoMensual                   money         = null,
       @i_actividad_desc                   varchar(50)   = null,
       @i_egresos                          catalogo      = null,
       @i_carg_pub                         varchar(200)  = null,
       @i_rel_carg_pub                     varchar(10)   = null,
       @i_nit                              varchar(30)   = null,  -- numero de identificacion tributaria del cliente
       @i_nit_c                            varchar(30)   = null,  -- numero de identificacion tributaria del conyugue
       @i_ingreso_legal                    char(1)       = null,
       @i_actividad_legal                  char(1)       = null,
       @i_fatca                            char(1)       = null,
       @i_crs                              char(1)       = null,
       @i_entidad_act                      catalogo      = null,
       @i_other_project                    char(1)       = 'N',  -- agregado para proyecto TRF MX
       @i_tipo_residencia                  char(2)       = null, -- Tipo Residencia Conyugue
       @i_tipo_residencia_c                char(2)       = null, -- Tipo Residencia Conyugue
       @i_migrado                          varchar(30)   = null,
       @i_existente                        varchar(5)    = 'false',
       @i_pseudonimo                       descripcion   = null, -- Pseudonimo del cliente
       @i_ea_con_como                      varchar(255)  = null, -- Conocido como S896481
       @i_ciudad_emi                       int           = null, -- Lugar de emisión S896481
       @i_fecha_emi                        datetime      = null, -- Fecha emisión S896481
       @i_ea_telef_recados                 varchar(20)   = null, -- Teléfono S896481
       @i_antecedentes_buro                varchar(2)    = null, -- Autorización Buro S896481
       @i_persona_recados                  varchar(60)   = null, -- Autorización recibir notificaciones S896481
       @i_is_app                           char(1)       = 'S',  -- S896481: Valor por defecto para ejecutar la creación de clientes offline desde la APP
       @o_ente                             int           = null  out,
       @o_dire                             int           = null  out,
       @o_ente_c                           int           = null  out,
       @o_curp                             varchar(32)   = null  out, -- lgu: calculo de rfc y curp
       @o_rfc                              varchar(32)   = null  out, -- lgu: calculo de rfc y curp
       @o_curp_c                           varchar(32)   = null  out, -- lgu: calculo de rfc y curp
       @o_rfc_c                            varchar(32)   = null  out -- lgu: calculo de rfc y curp
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_relacion              int,
        @w_oficial               int,
        @w_estado_prospecto      char(1),
        @w_lado_relacion         char(1),
        @w_ente_c                int,
        @w_trn_dir               int,
        @w_error                 int,
        @w_operacion             char(1),
        @w_existente             bit,
        @w_valor_campo           varchar(30),
        @w_pais_default          int,
        @w_pais_local            int,
        @w_tipo_nacionalidad     char(1),
        @w_tipo_nacionalidad_c   char(1),
        @w_mascara               varchar(64)


/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cobis..sp_crear_persona_int',
@w_sp_msg           = '',
@w_oficial          = @i_oficial,
@w_operacion        = '',
@w_error            = 1720548

select @w_pais_default = pa_smallint
   from cobis..cl_parametro
   where pa_nemonico = 'CP' --CODIGO DE PAIS
   and   pa_producto = 'CLI'

---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out   

select @w_sp_msg = convert(varchar,@w_error)+ ' - ' + re_valor                                                                                                                                                                           
   from   cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int                                                                                                                                                                                                                        
   and    re_cultura = UPPER(@s_culture))                                                                                                                                                                                                           
   where numero = @w_error 


if @i_operacion = 'I' or @i_operacion = 'U'
begin
    /* VALIDACIONES */
    /* CAMPOS REQUERIDOS PARA PROSPECTO SOLTERO */
    if isnull(@i_nombre,'') = ''
    begin
        select @w_valor_campo  = 'firstName'
      goto VALIDAR_ERROR
    end
    
    if isnull(@i_papellido,'') = ''
    begin
        select @w_valor_campo  = 'surname'
      goto VALIDAR_ERROR
    end
    
    if isnull(@i_pais_nac,'') = ''
    begin
        select @w_valor_campo  = 'nationalityCode'
      goto VALIDAR_ERROR
    end
    
    if isnull(@i_provincia_nac,'') = ''
    begin
        select @w_valor_campo  = 'countyOfBirth'
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
    
    if isnull(@i_est_civil,'') = ''
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
        select @w_valor_campo  = 'officialID' --validar q oficial exista
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
    
    
    
    if @i_pais_nac <> @w_pais_default -- si es extranjero
    begin
        if isnull(@i_tipo_residencia,'') = ''
        begin
            select @w_valor_campo  = 'typeHome'
          goto VALIDAR_ERROR
        end
    end
    /* FIN DE CAMPOS REQUERIDOS DEPENDIENDO DE LA DATA */
    
    
    /* CAMPOS REQUERIDOS PARA PROSPECTO CASADO */
    if @i_is_app <> 'S' --S896481: Validación para no ejecutar esta sección al crear clientes offline desde la APP
    begin
       if ((@i_est_civil in (select c.codigo
                          from cobis..cl_catalogo c, cobis..cl_tabla t
                          where t.tabla  = 'cl_ecivil_conyuge'
                          and c.tabla = t.codigo)) and @i_cedula_c is not null)
       begin
       
           if isnull(@i_nombre_c,'') = ''
           begin
               select @w_valor_campo  = 'firstNameSpouse'
             goto VALIDAR_ERROR
           end 
           
           if isnull(@i_papellido_c,'') = ''
           begin
               select @w_valor_campo  = 'surnameSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_pais_nac_c,'') = ''
           begin
               select @w_valor_campo  = 'nationalityCodeSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_provincia_nac_c,'') = ''
           begin
               select @w_valor_campo  = 'countryOfBirthSpouse' -- cambiar nombre de propiedad en dto
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_fecha_nac_c,'') = ''
           begin
               select @w_valor_campo  = 'birthDateSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_tipo_ced_c,'') = ''
           begin
               select @w_valor_campo  = 'identificationTypeSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_cedula_c,'') = ''
           begin
               select @w_valor_campo  = 'identificationNumberSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_sexo_c,'') = ''
           begin
               select @w_valor_campo  = 'sexCodeSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_genero_c,'') = ''
           begin
               select @w_valor_campo  = 'genderCodeSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_fecha_nac_c,'') = ''
           begin
               select @w_valor_campo  = 'birthDateSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_actividad_c,'') = ''
           begin
               select @w_valor_campo  = 'activitySpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_nivel_estudio_c,'') = ''
           begin
               select @w_valor_campo  = 'studiesLevelSpouse'
             goto VALIDAR_ERROR
           end
           
           if isnull(@i_ocupacion_c,'') = ''
           begin
               select @w_valor_campo  = 'ocupationSpouse'
             goto VALIDAR_ERROR
           end
           
           /* CAMPOS REQUERIDOS DEPENDIENDO DE LA DATA */
           if @i_tipo_tributario_c is not null
           begin
               if isnull(@i_nit_c,'') = ''
               begin
                   select @w_valor_campo  = 'numberIdentificationTributarioSpouse'
                 goto VALIDAR_ERROR
               end
           end
           /* FIN DE CAMPOS REQUERIDOS DEPENDIENDO DE LA DATA */
       end
    end
    /* FIN CAMPOS REQUERIDOS */

   
    /* VALIDACIONES DE CATALOGOS */
    -- pais 
    if not exists(select 1 from cobis..cl_pais where pa_pais = @i_pais_nac)
    begin
       select @w_error = 1720110
       select @w_valor_campo  = @i_pais_nac
       goto VALIDAR_ERROR
    end
    
    -- provincia
    if not exists(select 1 from cobis..cl_provincia 
              where pv_provincia = @i_provincia_nac
              and   pv_pais      = @i_pais_nac)
    begin
       select @w_error = 1720110
       select @w_valor_campo  = @i_provincia_nac
       goto VALIDAR_ERROR
    end
    
    -- tipo de residencia
    if @i_tipo_residencia is not null
    begin
        exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_tipo_residencia', @i_valor = @i_tipo_residencia
        if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
        else if @w_error = 1720018 
        begin 
            select @w_valor_campo  = @i_tipo_residencia         
            select @w_error = 1720552 
            goto VALIDAR_ERROR 
        end
    end
    
    -- tipo de identificacion
    if convert(smallint,@i_pais_nac) = @w_pais_default
         select @w_tipo_nacionalidad = 'N'
    else
         select @w_tipo_nacionalidad = 'E'
    
    if  exists(select 1 from cobis..cl_tipo_identificacion where ti_tipo_cliente = 'P' 
              and ti_tipo_documento = 'P' 
              and ti_nacionalidad   = @w_tipo_nacionalidad 
              and ti_codigo         = @i_tipo_ced)
    begin
        select @w_mascara = ti_mascara from cobis..cl_tipo_identificacion where ti_tipo_cliente = 'P' 
           and ti_tipo_documento = 'P' 
           and ti_nacionalidad   = @w_tipo_nacionalidad 
           and ti_codigo         = @i_tipo_ced

        if charindex('-', @i_cedula) = 0 --Se manda sin mascara
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
    exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_ecivil', @i_valor = @i_est_civil
    if @w_error <> 0 and @w_error != 1720018
    begin
        select @w_valor_campo  = @i_est_civil
        goto VALIDAR_ERROR
    end 
    else if @w_error = 1720018 
    begin 
        select @w_valor_campo  = @i_est_civil         
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
    
    -- estado de afiliacion
    if @i_estado_afiliacion is not null
    begin
        exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_situacion_cliente', @i_valor = @i_estado_afiliacion
        if @w_error <> 0 and @w_error != 1720018
        begin
            select @w_valor_campo  = @i_estado_afiliacion
            goto VALIDAR_ERROR
        end
        else if @w_error = 1720018 
        begin 
            select @w_valor_campo  = @i_estado_afiliacion         
            select @w_error = 1720552 
            goto VALIDAR_ERROR 
        end
    end
    
    -- oficial
    if @i_oficina is null or @i_oficina = '' or @i_is_app = 'S' --S896481: Siempre que sea la ejecución desde la APP tomará la oficina de login
    begin
      select @i_oficina = fu_oficina                            --R219376: Se asocia la oficina del oficial    
        from cobis..cc_oficial, cobis..cl_funcionario
       where oc_oficial = @i_oficial
         and fu_funcionario = oc_funcionario
    end

    
    if not exists (select 1
                   from cobis..cl_funcionario, cobis..cc_oficial, cobis..ad_usuario
                   where fu_funcionario = oc_funcionario
                   and oc_oficial = @i_oficial
                   and us_oficina = @i_oficina
                   and us_login = fu_login)   
    begin      
      select @w_sp_msg = null
      select @w_error = 1720551
      goto ERROR_FIN        
    end
    
    if @i_is_app <> 'S'   --S896481: Validación para no ejecutar esta sección al crear clientes offline desde la APP
    begin
       -- validaciones de conyuge
       if (@i_est_civil in (select c.codigo
                          from cobis..cl_catalogo c, cobis..cl_tabla t
                          where t.tabla  = 'cl_ecivil_conyuge'
                          and c.tabla = t.codigo) and @i_cedula_c is not null)
       begin
           -- pais
           if not exists(select 1 from cobis..cl_pais where pa_pais = @i_pais_nac_c)
           begin
              select @w_sp_msg = null
              select @w_error = 1720110
              goto ERROR_FIN
           end
           
           -- provincia
           if not exists(select 1 from cobis..cl_provincia 
                     where pv_provincia = @i_provincia_nac_c
                     and   pv_pais      = @i_pais_nac_c)
           begin
              select @w_sp_msg = null      
              select @w_error = 1720110
              goto ERROR_FIN
           end
           
           -- tipo de residencia
           if @i_tipo_residencia_c is not null
           begin
               exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_tipo_residencia', @i_valor = @i_tipo_residencia_c
               if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
               else if @w_error = 1720018 
               begin 
                   select @w_valor_campo  = @i_tipo_residencia_c         
                   select @w_error = 1720552 
                   goto VALIDAR_ERROR 
               end
           end
           
           -- tipo de identificacion
           if @i_pais_nac_c = @w_pais_default
                select @w_tipo_nacionalidad_c = 'N'
           else
                select @w_tipo_nacionalidad_c = 'E'
           
           if not exists(select 1 from cobis..cl_tipo_identificacion where ti_tipo_cliente = 'P' 
                     and ti_tipo_documento = 'P' 
                     and ti_nacionalidad = @w_tipo_nacionalidad_c 
                     and ti_codigo = @i_tipo_ced_c)
           begin
               select @w_valor_campo  = @i_tipo_ced_c         
               select @w_error = 1720552 
               goto VALIDAR_ERROR 
           end
           
           -- tipo de identificacion tributaria
           if @i_tipo_tributario_c is not null
           begin
               if not exists(select 1 from cobis..cl_tipo_identificacion where ti_tipo_cliente = 'P' 
                         and ti_tipo_documento = 'T' 
                         and ti_nacionalidad = @w_tipo_nacionalidad_c 
                         and ti_codigo = @i_tipo_tributario_c)
               begin
                   select @w_valor_campo  = @i_tipo_tributario_c         
                   select @w_error = 1720552 
                   goto VALIDAR_ERROR 
               end
           end
           
           -- sexo
           exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_sexo', @i_valor = @i_sexo_c
           if @w_error <> 0 and @w_error != 1720018
           begin
               select @w_valor_campo  = @i_sexo_c
               goto VALIDAR_ERROR
           end
           else if @w_error = 1720018 
           begin 
               select @w_valor_campo  = @i_sexo_c         
               select @w_error = 1720552 
               goto VALIDAR_ERROR 
           end
           
           -- genero
           exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_genero', @i_valor = @i_genero_c
           if @w_error <> 0 and @w_error != 1720018
           begin
               select @w_valor_campo  = @i_genero_c
               goto VALIDAR_ERROR
           end
           else if @w_error = 1720018 
           begin 
               select @w_valor_campo  = @i_genero_c         
               select @w_error = 1720552 
               goto VALIDAR_ERROR 
           end
           
           -- escolaridad
           exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_nivel_estudio', @i_valor = @i_nivel_estudio_c
           if @w_error <> 0 and @w_error != 1720018
           begin
               select @w_valor_campo  = @i_nivel_estudio_c
               goto VALIDAR_ERROR
           end
           else if @w_error = 1720018 
           begin 
               select @w_valor_campo  = @i_nivel_estudio_c         
               select @w_error = 1720552 
               goto VALIDAR_ERROR 
           end
           
           -- actividad economica
           exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_actividad_ec', @i_valor = @i_actividad_c
           if @w_error <> 0 and @w_error != 1720018
           begin
               select @w_valor_campo  = @i_actividad_c
               goto VALIDAR_ERROR
           end
           else if @w_error = 1720018 
           begin 
               select @w_valor_campo  = @i_actividad_c         
               select @w_error = 1720552 
               goto VALIDAR_ERROR 
           end
           
           -- ocupacion
           exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_ocupacion', @i_valor = @i_ocupacion_c
           if @w_error <> 0 and @w_error != 1720018
           begin
               select @w_valor_campo  = @i_ocupacion_c
               goto VALIDAR_ERROR
           end
           else if @w_error = 1720018 
           begin 
               select @w_valor_campo  = @i_ocupacion_c         
               select @w_error = 1720552 
               goto VALIDAR_ERROR 
           end
           
       end
    end   
    /* FIN DE VALIDACIONES DE CATALOGOS */

    /* PASO A MAYUSCULAS*/
    
    select @i_nombre = upper(@i_nombre)
    select @i_papellido = upper(@i_papellido)
    
    if @i_segnombre is not null
    begin
        select @i_segnombre = upper(@i_segnombre)
    end
    
    if @i_sapellido is not null
    begin
        select @i_sapellido = upper(@i_sapellido)
    end
    
    if @i_c_apellido is not null
    begin
        select @i_c_apellido = upper(@i_c_apellido)
    end

    if @i_is_app <> 'S' --S896481: Validación para no ejecutar esta sección al crear clientes offline desde la APP
    begin
        if (@i_est_civil in (select c.codigo
                           from cobis..cl_catalogo c, cobis..cl_tabla t
                           where t.tabla  = 'cl_ecivil_conyuge'
                           and c.tabla = t.codigo) and @i_cedula_c is not null)
        begin
            
            select @i_nombre_c = upper(@i_nombre_c)
            select @i_papellido_c = upper(@i_papellido_c)
            
            if @i_segnombre_c is not null
            begin
                select @i_segnombre_c = upper(@i_segnombre_c)
            end
            
            if @i_sapellido_c is not null
            begin
                select @i_sapellido_c = upper(@i_sapellido_c)
            end
            
            if @i_c_apellido_c is not null
            begin
                select @i_c_apellido_c = upper(@i_c_apellido_c)
            end
        
        end
    end
    /* FIN DE PASO A MAYUSCULAS */
end

   exec @w_error = cobis..sp_crear_persona
       @s_ssn                    = @s_ssn,
       @s_sesn                   = @s_sesn,
       @s_user                   = @s_user,
       @s_term                   = @s_term,
       @s_date                   = @s_date,
       @s_srv                    = @s_srv,
       @s_lsrv                   = @s_lsrv,
       @s_ofi                    = @s_ofi,
       @s_rol                    = @s_rol,
       @s_org_err                = @s_org_err,
       @s_error                  = @s_error,
       @s_sev                    = @s_sev,
       @s_msg                    = @s_msg,
       @s_org                    = @s_org,
       @s_culture                = @s_culture,
       @t_debug                  = @t_debug,
       @t_file                   = @t_file,
       @t_from                   = @t_from,
       @t_trn                    = 172000,
       @t_show_version           = @t_show_version,
       @i_nombre                 = @i_nombre,
       @i_papellido              = @i_papellido,
       @i_sapellido              = @i_sapellido,
       @i_filial                 = @i_filial,
       @i_oficina                = @i_oficina,
       @i_tipo_ced               = @i_tipo_ced,
       @i_tipo_tributario        = @i_tipo_tributario,
       @i_cedula                 = @i_cedula,
       @i_login_oficial          = @i_login_oficial,
       @i_c_apellido             = @i_c_apellido,
       @i_segnombre              = @i_segnombre,
       @i_sector                 = @i_sector,
       @i_sexo                   = @i_sexo,
       @i_genero                 = @i_genero,
       @i_est_civil              = @i_est_civil,
       @i_ea_estado              = @i_ea_estado,
       @i_dir_virtual            = @i_dir_virtual,
       @i_dir_virtual_v          = @i_dir_virtual_v,
       @i_fecha_expira           = @i_fecha_expira,
       @i_fecha_nac              = @i_fecha_nac,
       @i_profesion              = @i_profesion,
       @i_ocupacion              = @i_ocupacion,
       @i_tipo_vivienda          = @i_tipo_vivienda,
       @i_nombre_c               = @i_nombre_c,
       @i_papellido_c            = @i_papellido_c,
       @i_sapellido_c            = @i_sapellido_c,
       @i_tipo_ced_c             = @i_tipo_ced_c,
       @i_tipo_tributario_c      = @i_tipo_tributario_c,
       @i_cedula_c               = @i_cedula_c,
       @i_segnombre_c            = @i_segnombre_c,
       @i_sexo_c                 = @i_sexo_c,
       @i_genero_c               = @i_genero_c,
       @i_est_civil_c            = @i_est_civil_c,
       @i_ea_estado_c            = @i_ea_estado_c,
       @i_c_apellido_c           = @i_c_apellido_c,
       @i_fecha_expira_c         = @i_fecha_expira_c,
       @i_fecha_nac_c            = @i_fecha_nac_c,
       @i_profesion_c            = @i_profesion_c,
       @i_sector_c               = @i_sector_c,
       @i_calif_cliente          = @i_calif_cliente,
       @i_vinculacion            = @i_vinculacion,
       @i_tipo_vinculacion       = @i_tipo_vinculacion,
       @i_emproblemado           = @i_emproblemado,
       @i_dinero_transac         = @i_dinero_transac,
       @i_manejo_doc             = @i_manejo_doc,
       @i_pep                    = @i_pep,
       @i_mnt_activo             = @i_mnt_activo,
       @i_mnt_pasivo             = @i_mnt_pasivo,
       @i_tiempo_reside          = @i_tiempo_reside,
       @i_ant_nego               = @i_ant_nego,
       @i_ventas                 = @i_ventas,
       @i_ot_ingresos            = @i_ot_ingresos,
       @i_ct_ventas              = @i_ct_ventas,
       @i_ct_operativos          = @i_ct_operativos,
       @i_ciudad_nac             = @i_ciudad_nac,
       @i_ciudad_nac_c           = @i_ciudad_nac_c,
       @i_operacion              = @i_operacion,
       @i_ea_nro_ciclo_oi        = @i_ea_nro_ciclo_oi,
       @i_comentario             = @i_comentario,
       @i_batch                  = @i_batch,
       @i_num_ciclos             = @i_num_ciclos,
       @i_banco                  = @i_banco,
       @i_pais_nac               = @i_pais_nac,
       @i_nacionalidad           = @i_nacionalidad,
       @i_provincia_nac          = @i_provincia_nac,
       @i_naturalizado           = @i_naturalizado,
       @i_forma_migratoria       = @i_forma_migratoria,
       @i_nro_extranjero         = @i_nro_extranjero,
       @i_calle_orig             = @i_calle_orig,
       @i_exterior_orig          = @i_exterior_orig,
       @i_estado_orig            = @i_estado_orig,
       @i_escolaridad            = @i_escolaridad,
       @i_nivel_estudio          = @i_nivel_estudio,
       @i_actividad              = @i_actividad,
       @i_retencion              = @i_retencion,
       @i_ea_fuente_ing          = @i_ea_fuente_ing,
       @i_ea_discapacidad        = @i_ea_discapacidad,
       @i_ea_tipo_discapacidad   = @i_ea_tipo_discapacidad,
       @i_ea_ced_discapacidad    = @i_ea_ced_discapacidad,
       @i_pais_nac_c             = @i_pais_nac_c,
       @i_nacionalidad_c         = @i_nacionalidad_c,
       @i_provincia_nac_c        = @i_provincia_nac_c,
       @i_naturalizado_c         = @i_naturalizado_c,
       @i_forma_mig_c            = @i_forma_mig_c,
       @i_numero_ext_c           = @i_numero_ext_c,
       @i_tipo_iden_c            = @i_tipo_iden_c,
       @i_numero_iden_c          = @i_numero_iden_c,
       @i_localidad              = @i_localidad,
       @i_calle_orig_c           = @i_calle_orig_c,
       @i_exterior_orig_c        = @i_exterior_orig_c,
       @i_estado_orig_c          = @i_estado_orig_c,
       @i_escolaridad_c          = @i_escolaridad_c,
       @i_nivel_estudio_c        = @i_nivel_estudio_c,
       @i_ocupacion_c            = @i_ocupacion_c,
       @i_actividad_c            = @i_actividad_c,
       @i_ident_tipo_c           = @i_ident_tipo_c,
       @i_ident_num_c            = @i_ident_num_c,
       @i_email_c                = @i_email_c,
       @i_email_c_v              = @i_email_c_v,
       @i_nro_ciclo              = @i_nro_ciclo,
       @i_ingre                  = @i_ingre,
       @i_oficial                = @i_oficial,
       @i_tipo_iden              = @i_tipo_iden,
       @i_numero_iden            = @i_numero_iden,
       @i_num_cargas             = @i_num_cargas,
       @i_sic_asincronico        = @i_sic_asincronico,
       @i_estado_afiliacion      = @i_estado_afiliacion,
       @i_ingresoMensual         = @i_ingresoMensual,
       @i_actividad_desc         = @i_actividad_desc,
       @i_egresos                = @i_egresos,
       @i_carg_pub               = @i_carg_pub,
       @i_rel_carg_pub           = @i_rel_carg_pub,
       @i_nit                    = @i_nit,
       @i_nit_c                  = @i_nit_c,
       @i_ingreso_legal          = @i_ingreso_legal,
       @i_actividad_legal        = @i_actividad_legal,
       @i_fatca                  = @i_fatca,
       @i_crs                    = @i_crs,
       @i_entidad_act            = @i_entidad_act,
       @i_other_project          = @i_other_project,
       @i_tipo_residencia        = @i_tipo_residencia,
       @i_tipo_residencia_c      = @i_tipo_residencia_c,
       @i_migrado                = @i_migrado,
       @i_existente              = @i_existente,
       @i_pseudonimo             = @i_pseudonimo,
       @i_is_app                 = @i_is_app,   
       @i_ea_con_como            = @i_ea_con_como,       --S896481: Conocido como 
       @i_ciudad_emi             = @i_ciudad_emi,        --S896481: Ciudad de emisión 
       @i_fecha_emi              = @i_fecha_emi,         --S896481: Fecha de emisión   
       @i_ea_telef_recados       = @i_ea_telef_recados,  --S896481: Teléfono 
       @i_antecedentes_buro      = @i_antecedentes_buro, --S896481: Buró 
       @i_persona_recados        = @i_persona_recados,   --S896481: Información S896481
       @o_ente                   = @o_ente out,
       @o_dire                   = @o_dire out,
       @o_ente_c                 = @o_ente_c out,
       @o_curp                   = @o_curp out,
       @o_rfc                    = @o_rfc out,
       @o_curp_c                 = @o_curp_c out,
       @o_rfc_c                  = @o_rfc_c out

   if @w_error <> 0 or @o_ente is null
   begin
    goto VALIDAR_ERROR
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
