/************************************************************************************/
/*  Archivo:            api_natural_person.sp                                       */
/*  Stored procedure:   sp_api_natural_person                                       */
/*  Base de datos:      cobis                                                       */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Jeison Dario Gutierrez                                      */
/*  Fecha de creación:  Jun-18-2019                                                 */
/************************************************************************************/
/*          IMPORTANTE                                                              */
/*  Este programa es propiedad de "COBISCORP". Ha sido desarrollado                 */
/*  bajo el ambiente operativo COBIS-sistema desarrollado por                       */
/*  "COBISCORP S.A."-Ecuador                                                        */
/*  Su uso no autorizado queda expresamente prohibido asi como                      */
/*  cualquier alteracion o agregado hecho por alguno de sus                         */
/*  usuarios sin el debido consentimiento por escrito de la                         */
/*  Gerencia General de COBISCORP o su representante.                               */
/************************************************************************************/
/*          PROPOSITO                                                               */
/*  Este procedimiento permite la ejecucion de los procedimientos almacenados para  */
/*  obtener la informacion de un cliente                                            */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  2019-Jun-18       jgutierrez              Emisión Inicial                       */
/*  2020-Jul-03       wviatela                Ajustes con nueva version de sp's     */
/*  2020-Jul-07       FSAP                    Estandarizacion de Clientes           */
/*  2020-Oct-15       MBA                     Uso de la variable @s_culture         */
/************************************************************************************/

use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1
             from sysobjects
            where name = 'sp_api_natural_person')
  drop proc sp_api_natural_person
go

create proc sp_api_natural_person(
       @s_ssn                                       int         = NULL,
       @s_user                                      varchar(14) = NULL,
       @s_sesn                                      int         = NULL,
       @s_term                                      varchar(30) = NULL,
       @s_date                                      datetime    = NULL,
       @s_srv                                       varchar(30) = NULL,
       @s_lsrv                                      varchar(30) = NULL,
       @s_rol                                       smallint    = NULL,
       @s_ofi                                       smallint    = NULL,
       @s_org_err                                   char(1)     = NULL,
       @s_error                                     int         = NULL,
       @s_sev                                       tinyint     = NULL,
       @s_msg                                       varchar(64) = NULL,
       @s_org                                       char(1)     = NULL,
	   @s_culture                                   varchar(10) = 'NEUTRAL',
       @t_trn                                       int         = NULL,
       @t_debug                                     char(1)     = 'N',
       @t_file                                      varchar(14) = NULL,
       @t_corr                                      char(1)     = 'N',
       @t_ssn_corr                                  int         = NULL,
       @t_from                                      varchar(32) = NULL,
       @t_rty                                       char(1)     = NULL,
       @t_show_version                              bit         = 0,
       -- parametros de cabecera                   
       @i_x_api_key                                 varchar(40) = NULL,     --headers.x_api_key
       @i_Authorization                             varchar(100)= NULL,     --headers.Authorization
       @i_x_request_id                              varchar(36) = NULL,     --headers.x-request-id
       @i_x_financial_id                            varchar(25) = NULL,     --headers.x-financial-id
       @i_x_end_user_login                          varchar(25) = NULL,     --headers.x-end-user-login
       @i_x_end_user_request_date_time              varchar(25) = NULL,     --headers.x-end-user-request-date-time
       @i_x_end_user_terminal                       varchar(25) = NULL,     --headers.x-end-user-terminal
       @i_x_end_user_last_logged_date_time          varchar(25) = NULL,     --headers.x-end-user-last-logged-date-time
       @i_x_jws_signature                           varchar(25) = NULL,     --headers.x-jws-signature
       @i_x_reverse                                 varchar(25) = NULL,     --headers.x-reverse
       @i_x_requestId_to_reverse                    varchar(25) = NULL,     --headers.x-requestId-to-reverse
       -- parametros del servicio                   
       @i_operacion                                 char(1)     = NULL,     --operacion
       @i_code                                      int         = NULL,     --customerId
       @i_identification_number                     varchar(20) = NULL,     --naturalPerson.identification.number
       @i_identification_type_code                  catalogo    = NULL,     --naturalPerson.identification.type.code
       @i_name                                      varchar(32) = NULL,     --naturalPerson.names
       @i_othername                                 varchar(20) = NULL,     --naturalPerson.othername --no existe parametro de entrada en sp_crear_persona
       @i_lastname                                  varchar(16) = NULL,     --naturalPerson.lastname
       @i_otherlastname                             varchar(16) = NULL,     --naturalPerson.otherLastName
       @i_status_code                               char(1)     = NULL,     --naturalPerson.status
       @i_subsidiary_code                           tinyint     = NULL,     --subsidiary.code
       @i_branch_code                               smallint    = NULL,     --branch.code
       @i_officer_code                              smallint    = NULL,     --officer.code
       @i_activity_code                             catalogo    = NULL,     --activity.code
       @i_comment                                   varchar(254)= NULL,     --naturalPerson.comment
       @i_documentvalidated                         char(1)     = NULL,     --naturalPerson.documentValidated 
       @i_gender_code                               char(1)     = NULL,     --gender.code
       @i_birthdate                                 datetime    = NULL,     --birthDate
       @i_citybirth_code                            int         = NULL,     --cityBirth.code
       @i_profession_code                           catalogo    = NULL,     --profession.code
       @i_occupation_code                           catalogo    = NULL,     --occupation.code
       @i_maritalstatus_code                        catalogo    = NULL,     --maritalStatus.code
       @i_dependants                                int         = NULL,     --naturalPerson.dependants
       @i_incomelevel                               catalogo    = NUll,     --naturalPerson.incomeLevel                
       @i_degreelevel_code                          catalogo    = NULL,     --degreeLevel.code
       @i_housingtype_code                          catalogo    = NULL,     --housingType.code
       @i_clientquality_code                        catalogo    = NULL,     --clientQuality.code
       @i_politicaloffice                           varchar(200)= NULL,     --naturalPerson.politicaloffice 
       @i_politicalofficedependency_code            catalogo    = NULL,     --naturalPerson.politicalOfficeDependency.code                
       @i_cyclenumber                               int         = NULL,     --naturalPerson.cyclenumber  
       @i_ispep                                     char(1)     = NULL,     --naturalPerson.isPEP
       @i_taxidentification_number                  varchar(32) = NULL,     --taxidentification.number
       @i_taxidentification_type_code               catalogo    = NULL,     --taxidentification.number no se usa
       @i_taxidentification_duedate                 datetime    = NULL,     --taxidentification.duedate -- no se usa
       @i_taxidentification_documentvalidated       char(1)     = NULL,     --taxidentification.documentvalidated no se usa
       @i_externalcode                              varchar(20) = NULL,     --externalCode                          LO RECIBE sp_persona_upd
       @i_countrybirth_code                         int         = NULL,     --countryBirth.code
       @i_provincebirth_code                        smallint    = NULL,     
       @i_foreignernaturalised                      char(1)     = NULL,     --foreignerNaturalised
       @i_immigration                               varchar(64) = NULL,     --immigration 
       @i_foreignidentification_number              varchar(32) = NULL,     --foreignIdentification.number
       @i_originAddress                             varchar(70) = NULL,     --originAddress
       @i_homeTown                                  varchar(40) = NULL,     --homeTown   
       @i_secondaryidentification_number            varchar(20) = NULL,     --secondaryIdentification.number        LO RECIBE sp_persona_upd
       @i_secondaryidentification_type_code         catalogo    = NULL,     --secondaryIdentification.type.code     LO RECIBE sp_persona_upd
       @i_industry_code                             catalogo    = NULL,     --industry.code                         -- Se guarda en dos partes
       @i_sourceofincome_code                       catalogo    = NULL,     --sourceOfIncome.code                   LO RECIBE sp_persona_upd
       @i_disability_code                           catalogo    = NULL,     --disability.code                       LO RECIBE sp_persona_upd
       @i_expenselevel_code                         catalogo    = NULL,     --expenseLevel.code                     LO RECIBE sp_persona_upd
       @i_legalincomesource                         char(1)     = NULL,     --legalIncomeSource
       @i_noconnectiontoillegalnetworks             char(1)     = NULL,     --noConnectionToIllegalNetworks
       @i_americanpersonfinancialpurposes           char(1)     = NULL,     --americanPersonFinancialPurposes
       @i_residentoutsideofusaforfinancialpurposes  char(1)     = NULL,     -- residentOutsideOfUSAForFinancialPurposes
       @i_retention                                 char(1)     = NULL,
       @i_solidaritygroup_code                      int         = NULL,     --solidarityGroup.code no se usa
       -- Los siguientes parametros solo se utilizan en la operacion de creacion I
       -- parametros de direccion principal
       @i_address                                   varchar(254)= NULL,     --address
       @i_subdivision_code                          int         = NULL,     --subdivision.code
       @i_city_code                                 int         = NULL,     --city.code
       @i_address_type_code                         catalogo    = NULL,     --type.code
       @i_region_code                               catalogo    = NULL,     --region.code
       @i_zone_code                                 catalogo    = NULL,     --zone.code
       @i_primaryaddress                            char(1)     = NULL,      --primaryAddress
       @i_neighborhood                              char(40)    = NULL,     --neighborhood
       @i_address_verified                          char(1)     = NULL,      --verified
       @i_province_code                             smallint    = NULL,     --province.code
       @i_country_code                              smallint    = NULL,     --country.code
       @i_propertytype_code                         catalogo    = NULL,     --propertytype.code
       @i_zipcode_code                              varchar(10) = NULL,     --zipcode.code
       @i_street                                    varchar(70) = NULL,     --street
       @i_timeincurrentresidence                    int         = NULL,     --timeInCurrentResidence
       @i_externalnumber                            int         = NULL,     --externalNumber
       @i_numberofpeoplelivinginresidence           int         = NULL,     --numberOfPeopleLivingInResidence
       @i_internalnumber                            int         = NULL,     --internalNumber
       @i_population                                varchar(30) = NULL,     --populations
       @i_directions                                varchar(255)= NULL,     --directions
       @i_town_code                                 varchar(10) = NULL,     --town.code
       @i_geolocatization_latitude                  float(53)   = NULL,     --geolocatization.latitude             LO RECIBE EL SP sp_direccion_geo
       @i_geolocatization_longitude                 float(53)   = NULL,     --geolocatization.longitude            LO RECIBE EL SP sp_direccion_geo
       -- parametros de telefono asociado a la direccion principal
       @i_number                                    varchar(16) = NULL,     --number
       @i_type_code                                 char(2)     = NULL,     --type.code
       @i_prefix                                    varchar(10) = NULL,     --prefix
       @i_customerserviceline_code                  varchar(10) = NULL,     --customerserviceline.code no se usa
       @i_collectionagency                          char(1)     = NULL,      --collectionAgency S o N
       @i_valid                                     char(1)     = NULL,
       @i_area                                      varchar(10) = NULL,     --area
       --parametros de email 
       @i_mail                                      varchar(254)= NULL,     --email.mail
       @i_verified                                  char(1)     = NULL,     --email.verified
       -- parametro de salida
       @o_cod_ente                                  int         = NULL output, --ente
       @o_cod_address                               int         = NULL output, --address.code
       @o_fecha_proceso                             varchar(25) = NULL output  --fechaProceso
)as

declare @w_sp_name                          varchar(30),
        @w_sp_msg                           varchar(132),
        @w_name_1                           varchar(254),
        @w_name_2                           varchar(254),
        @w_error                            int,
        @w_ente                             int

select @w_sp_name = 'sp_api_natural_person'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
  begin
    select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
    select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
    print  @w_sp_msg
    return 0
  end
  
  
---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out


/* ************************************* */
/* OPERACIONES                           */
/* ************************************* */

/* Descripción: Realiza la creación de un cliente o prospecto con los datos básicos. Adicionalmente se permite agregar una única dirección, correo y/o teléfono.
 * Operación: [POST] - /customers/natural-persons
 */
if @i_operacion = 'I'
  begin
    exec @w_error                   = cobis..sp_crear_persona
         @s_ssn                     = @s_ssn,
         @s_user                    = @s_user,
         @s_term                    = @s_term,
         @s_date                    = @s_date,
         @s_srv                     = @s_srv,
         @s_lsrv                    = @s_lsrv,
         @s_rol                     = @s_rol,
         @s_ofi                     = @s_ofi,
         @s_org_err                 = @s_org_err,
         @s_error                   = @s_error,
         @s_sev                     = @s_sev,
         @s_msg                     = @s_msg,
         @s_org                     = @s_org,
         @t_debug                   = @t_debug,
         @t_file                    = @t_file,
         @t_from                    = @t_from,
         @i_operacion               = 'I',
         @t_trn                     = 172000,
         @i_nombre                  = @i_name,
         @i_segnombre               = @i_othername,
         @i_papellido               = @i_lastname,
         @i_sapellido               = @i_otherlastname,
         @i_tipo_ced                = @i_identification_type_code,
         @i_cedula                  = @i_identification_number,
         @i_tipo_iden               = @i_secondaryidentification_type_code,
         @i_numero_iden             = @i_secondaryidentification_number,
         @i_filial                  = @i_subsidiary_code,
         @i_oficina                 = @i_branch_code,
         @i_fecha_nac               = @i_birthdate,
         @i_ciudad_nac              = @i_citybirth_code,
         @i_pais_nac                = @i_countrybirth_code,
         @i_sexo                    = @i_gender_code,
         @i_est_civil               = @i_maritalstatus_code,
         @i_nivel_estudio           = @i_degreelevel_code,
         @i_profesion               = @i_profession_code,
         @i_tipo_vivienda           = @i_housingtype_code,
         @i_actividad               = @i_activity_code,
         @i_sector                  = @i_industry_code,
         @i_oficial                 = @i_officer_code,
         @i_retencion               = @i_retention,
         @i_calif_cliente           = @i_clientquality_code,
         @i_comentario              = @i_comment,
         @i_dir_virtual             = @i_mail,
         @i_dir_virtual_v           = @i_verified,
         @i_banco                   = @i_externalcode,
         @i_numero_iden_c           = @i_secondaryidentification_number,
         @i_tipo_iden_c             = @i_secondaryidentification_type_code,
         @i_ea_fuente_ing           = @i_sourceofincome_code,
         @i_ea_tipo_discapacidad    = @i_disability_code,
         @i_egresos                 = @i_expenselevel_code,
         @i_provincia_nac           = @i_provincebirth_code,
         @i_ocupacion_c             = @i_occupation_code,
         @i_num_cargas              = @i_dependants,
         @i_ingre                   = @i_incomelevel, 
         @i_carg_pub                = @i_politicaloffice,               
         @i_rel_carg_pub            = @i_politicalofficedependency_code,  
         @i_nro_ciclo               = @i_cyclenumber,                   
         @i_pep                     = @i_ispep,                        
         @i_nit                     = @i_taxidentification_number,                                     
         @i_naturalizado            = @i_foreignernaturalised,             
         @i_forma_migratoria        = @i_immigration,                       
         @i_nro_extranjero          = @i_foreignidentification_number,     
         @i_calle_orig              = @i_originAddress,                   
         @i_estado_orig             = @i_homeTown, 
         @i_ingreso_legal           = @i_legalincomesource,                       
         @i_actividad_legal         = @i_noconnectiontoillegalnetworks,            
         @i_fatca                   = @i_americanpersonfinancialpurposes,          
         @i_crs                     = @i_residentoutsideofusaforfinancialpurposes,                                               
         @o_ente                    = @o_cod_ente out
    if @w_error <> 0
      goto CIERRE 
   
    if @i_address is not null
      begin
        exec @w_error              = cobis..sp_direccion_dml
             @s_ssn                = @s_ssn,
             @s_user               = @s_user,
             @s_term               = @s_term,
             @s_date               = @s_date,
             @s_srv                = @s_srv,
             @s_lsrv               = @s_lsrv,
             @s_rol                = @s_rol,
             @s_ofi                = @s_ofi,
             @s_org_err            = @s_org_err,
             @s_error              = @s_error,
             @s_sev                = @s_sev,
             @s_msg                = @s_msg,
             @s_org                = @s_org,
             @t_debug              = @t_debug,
             @t_file               = @t_file,
             @t_trn                = 172016,
             @t_from               = @t_from,
             @i_operacion          = 'I',
             @i_ente               = @o_cod_ente,
             @i_define             = 'S',
             @i_pais               = @i_country_code,
             @i_codpostal          = @i_zipcode_code,
             @i_zona               = @i_zone_code,
             @i_provincia          = @i_province_code ,       --province.code
             @i_ciudad             = @i_city_code,
             @i_parroquia          = @i_subdivision_code,
             @i_localidad          = @i_town_code,
             @i_ci_poblacion       = @i_population,                     
             @i_calle              = @i_street,
             @i_nro                = @i_externalnumber,
             @i_nro_interno        = @i_internalnumber,
             @i_descripcion        = @i_address,
             @i_tiempo_reside      = @i_timeincurrentresidence,
             @i_nro_residentes     = @i_numberofpeoplelivinginresidence,
             @i_tipo               = @i_address_type_code,
             @i_tipo_prop          = @i_propertytype_code,
             @i_principal          = @i_primaryaddress,
             @i_verificado         = @i_verified,
             @i_sector             = @i_region_code,
             @i_barrio             = @i_neighborhood,
             @i_referencias_dom    = @i_directions,                     
             @o_dire               = @o_cod_address out
      end
    if @w_error <> 0
      goto CIERRE
         
    if @o_cod_address  <> 0 and @i_number is not null
      begin
        exec @w_error = cobis..sp_telefono
             @s_ssn                = @s_ssn,
             @s_user               = @s_user,
             @s_term               = @s_term,
             @s_date               = @s_date,
             @s_srv                = @s_srv,
             @s_lsrv               = @s_lsrv,
             @s_rol                = @s_rol,
             @s_ofi                = @s_ofi,
             @s_org_err            = @s_org_err,
             @s_error              = @s_error,
             @s_sev                = @s_sev,
             @s_msg                = @s_msg,
             @t_debug              = @t_debug,
             @t_file               = @t_file,
             @s_org                = @s_org,
             @t_from               = @t_from,
             @t_trn                = 172031,
             @i_operacion          = 'I',
             @i_ente               = @o_cod_ente,
             @i_direccion          = @o_cod_address,
             @i_valor              = @i_number,
             @i_tipo_telefono      = @i_type_code,
             @i_te_telf_cobro      = @i_collectionagency,
             @i_verificado         = @i_valid,
             @i_cod_area           = @i_area,
             @i_prefijo            = @i_prefix
        if @w_error != 0
          goto CIERRE 
      end
      
    if @o_cod_address  <> 0 and @i_geolocatization_latitude is not null and @i_geolocatization_longitude is not null 
      begin
        exec @w_error              = cobis..sp_direccion_geo
             @s_ssn                = @s_ssn,
             @s_user               = @s_user,
             @s_sesn               = @s_sesn,
             @s_term               = @s_term,
             @s_date               = @s_date,
             @s_srv                = @s_srv,
             @s_lsrv               = @s_lsrv,
             @s_rol                = @s_rol,
             @s_ofi                = @s_ofi,
             @s_org_err            = @s_org_err,
             @s_error              = @s_error,
             @s_sev                = @s_sev,
             @s_msg                = @s_msg,
             @s_org                = @s_org,
             @t_debug              = @t_debug,
             @t_file               = @t_file,
             @t_from               = @t_from,
             @t_trn                = 172047,
             @i_operacion          ='I',
             @i_ente               = @o_cod_ente,
             @i_direccion          = @o_cod_address,
             @i_lat_segundos       = @i_geolocatization_latitude,
             @i_lon_segundos       = @i_geolocatization_longitude
        if @w_error != 0
          goto CIERRE 
      end
  end

/* Descripción: Realiza la consulta de los datos básicos de un cliente o prospecto de tipo persona natural mediante el código COBIS.
 * Operación: [GET] - /customers/natural-persons/{customerId}
 */
if @i_operacion = 'Q'
  begin
    /*Valida la existencia del cliente*/
    select @w_ente = en_ente
      from cobis..cl_ente
     where en_ente  = @i_code
    if @@rowcount = 0
      begin
        select @w_error = 1720035
        goto CIERRE
      end

    /*Consulta Inicial de Datos*/
    select 'code'                                           = en_ente,
           'identificationNumber'                           = en_ced_ruc,
           'identificationTypeCode'                         = en_tipo_ced,
           'name'                                           = en_nombre,
           'lastName'                                       = p_p_apellido,
           'otherLastName'                                  = p_s_apellido,
           'status'                                         = ea_estado,
           'subsidiaryCode'                                 = en_filial,
           'branchCode'                                     = en_oficina,
           'enrollmentDate'                                 = en_fecha_crea,
           'lastUpdateDate'                                 = en_fecha_mod,
           'officerCode'                                    = en_oficial,
           'activityCode'                                   = en_actividad,
           'comment'                                        = en_comentario,
           'genderCode'                                     = p_sexo,
           'birthDate'                                      = p_fecha_nac,
           'cityBirthCode'                                  = p_ciudad_nac,
           'professionCode'                                 = p_profesion,
           'maritalStatusCode'                              = p_estado_civil,
           'degreeLevelCode'                                = p_nivel_estudio,
           'housingTypeCode'                                = p_tipo_vivienda,
           'clientQualityCode'                              = p_calif_cliente,
           'externalCode'                                   = en_banco,
           'countryBirthCode'                               = en_pais_nac,
           'secondaryIdentificationNumber'                  = en_numero_iden,
           'secondaryIdentificationTypeCode'                = en_tipo_iden,
           'industryCode'                                   = en_sector,
           'sourceOfIncomeCode'                             = en_origen_ingresos,
           'disabilityCode'                                 = ea_tipo_discapacidad,
           'expenseLevelCode'                               = ea_nivel_egresos,
           
           'otherName'                                      = p_s_nombre,
           'retention'                                      = en_retencion,
           'occupationCode'                                 = p_ocupacion,
           'dependants'                                     = p_num_cargas,
           'incomeLevelCode'                                = en_ingre,
           'politicalOffice'                                = p_carg_pub,
           'politicalOfficeDependencyCode'                  = p_rel_carg_pub,
           'cycleNumber'                                    = en_nro_ciclo,
           'isPEP'                                          = en_persona_pep,
           'taxIdentificationNumber'                        = en_nit,
           'provinceBirthCode'                              = en_provincia_nac,
           'foreignerNaturalised'                           = en_naturalizado,
           'immigration'                                    = en_forma_migratoria,
           'foreignIdentificationNumber'                    = en_nro_extranjero,
           'originAddress'                                  = en_calle_orig,
           'homeTown'                                       = en_estado_orig,
           'legalIncomeSource'                              = ea_ingreso_legal,
           'noConnectionToIllegalNetworks'                  = ea_actividad_legal,
           'americanPersonFinancialPurposes'                = ea_fatca,
           'residentOutsideOfUSAForFinancialPurposes'       = ea_crs
      from cobis..cl_ente e
      left join cobis..cl_ente_aux a  on e.en_ente =  a.ea_ente
     where en_ente   = @w_ente
  end

/* Descripción: Realiza la consulta de los datos básicos de un cliente o prospecto de tipo persona natural por tipo y número de identificación.
 * Operación: [GET] - ?/customers?/natural-persons?/type?/{identificationTypeCode}?/number?/{identificationNumber}
 */
if @i_operacion = 'C'
  begin
    /*Valida la obligatoriedad de los filtros*/
    if (@i_identification_number is NULL or @i_identification_type_code is NULL)
      begin
        select @w_error = 1720325
        goto CIERRE
      end

   /*Valida la existencia del cliente*/
   select  @w_ente = en_ente
   from    cobis..cl_ente
   where   en_ced_ruc  = @i_identification_number
   and     trim(en_tipo_ced) = @i_identification_type_code
   if @@rowcount = 0 begin
      select @w_error = 1720035
      goto CIERRE
   end

    /*Consulta Inicial de Datos*/
    select 'code'                                           = en_ente,
           'identificationNumber'                           = en_ced_ruc,
           'identificationTypeCode'                         = en_tipo_ced,
           'names'                                          = en_nombre,
           'lastName'                                       = p_p_apellido,
           'otherLastName'                                  = p_s_apellido,
           'status'                                         = ea_estado,
           'subsidiaryCode'                                 = en_filial,
           'branchCode'                                     = en_oficina,
           'enrollmentDate'                                 = en_fecha_crea,
           'lastUpdateDate'                                 = en_fecha_mod,
           'officerCode'                                    = en_oficial,
           'activityCode'                                   = en_actividad,
           'comment'                                        = en_comentario,
           'genderCode'                                     = p_sexo,
           'birthDate'                                      = p_fecha_nac,
           'cityBirthCode'                                  = p_ciudad_nac,
           'professionCode'                                 = p_profesion,
           'maritalStatusCode'                              = p_estado_civil,
           'degreeLevelCode'                                = p_nivel_estudio,
           'housingTypeCode'                                = p_tipo_vivienda,
           'clientQualityCode'                              = p_calif_cliente,
           'externalCode'                                   = en_banco,
           'countryBirthCode'                               = en_pais_nac,
           'secondaryIdentificationNumber'                  = en_numero_iden,
           'secondaryIdentificationTypeCode'                = en_tipo_iden,
           'industryCode'                                   = en_sector,
           'sourceOfIncomeCode'                             = en_origen_ingresos,
           'disabilityCode'                                 = ea_tipo_discapacidad,
           'expenseLevelCode'                               = ea_nivel_egresos,
           
           'otherName'                                      = p_s_nombre,
           'retention'                                      = en_retencion,
           'occupationCode'                                 = p_ocupacion,
           'dependants'                                     = p_num_cargas,
           'incomeLevelCode'                                = en_ingre,
           'politicalOffice'                                = p_carg_pub,
           'politicalOfficeDependencyCode'                  = p_rel_carg_pub,
           'cycleNumber'                                    = en_nro_ciclo,
           'isPEP'                                          = en_persona_pep,
           'taxIdentificationNumber'                        = en_nit,
           'provinceBirthCode'                              = en_provincia_nac,
           'foreignerNaturalised'                           = en_naturalizado,
           'immigration'                                    = en_forma_migratoria,
           'foreignIdentificationNumber'                    = en_nro_extranjero,
           'originAddress'                                  = en_calle_orig,
           'homeTown'                                       = en_estado_orig,
           'legalIncomeSource'                              = ea_ingreso_legal,
           'noConnectionToIllegalNetworks'                  = ea_actividad_legal,
           'americanPersonFinancialPurposes'                = ea_fatca,
           'residentOutsideOfUSAForFinancialPurposes'       = ea_crs
      from cobis..cl_ente e
      left join cobis..cl_ente_aux a  on e.en_ente =  a.ea_ente
     where en_ente   = @w_ente
  end

/* Descripción: Realiza la modificación de un cliente o prospecto de tipo persona natural.
 * Operación: [PATCH] - /customers/natural-persons/{customerId}
 */
if @i_operacion = 'U'
  begin
   
    /*Valida la existencia del cliente*/
    select  @w_ente = en_ente
    from    cobis..cl_ente
    where   en_ente  = @i_code
    if @@rowcount = 0
      begin
        select @w_error = 1720035
        goto CIERRE
      end
   
    exec @w_error = cobis..sp_persona_upd
         @s_user                                       = @s_user,
         @s_term                                       = @s_term,
         @s_date                                       = @s_date,
         @i_operacion                                  = 'U',
         @t_trn                                        = 172003,
         @i_tipo                                       = '1',
         @i_persona                                    = @i_code,
         @i_ea_estado                                  = @i_status_code,
         @i_nombre                                     = @i_name,
         @i_segnombre                                  = @i_othername,
         @i_p_apellido                                 = @i_lastname,
         @i_s_apellido                                 = @i_otherlastname,
         @i_tipo_ced                                   = @i_identification_type_code,
         @i_cedula                                     = @i_identification_number,
         @i_tipo_iden                                  = @i_secondaryidentification_type_code,
         @i_numero_iden                                = @i_secondaryidentification_number,
         @i_fecha_nac                                  = @i_birthdate,
         @i_ciudad_nac                                 = @i_citybirth_code,
         @i_pais                                       = @i_countrybirth_code,
         @i_provincia_nac                              = @i_provincebirth_code,
         @i_sexo                                       = @i_gender_code,
         @i_estado_civil                               = @i_maritalstatus_code,
         @i_nivel_estudio                              = @i_degreelevel_code,
         @i_profesion                                  = @i_profession_code,
         @i_tipo_vivienda                              = @i_housingtype_code,
         @i_actividad                                  = @i_activity_code,
         @i_sector                                     = @i_industry_code,
         @i_calif_cliente                              = @i_clientquality_code,
         @i_banco                                      = @i_externalcode,
         @i_ea_fuente_ing                              = @i_sourceofincome_code,
         @i_ea_tipo_discapacidad                       = @i_disability_code,
         @i_egresos                                    = @i_expenselevel_code,
         @i_comentario                                 = @i_comment,
         @i_ocupacion                                  = @i_occupation_code,
         @i_num_cargas                                 = @i_dependants,
         @i_ingre                                      = @i_incomelevel,       
         @i_carg_pub                                   = @i_politicaloffice,             
         @i_rel_carg_pub                               = @i_politicalofficedependency_code, 
         @i_ea_nro_ciclo_oi                            = @i_cyclenumber,                   
         @i_pep                                        = @i_ispep,                        
         @i_nit                                        = @i_taxidentification_number,                                     
         @i_naturalizado                               = @i_foreignernaturalised,             
         @i_forma_migratoria                           = @i_immigration,                       
         @i_nro_extranjero                             = @i_foreignidentification_number,  
         @i_calle_orig                                 = @i_originAddress,                    
         @i_estado_orig                                = @i_homeTown, 
         @i_ea_ingreso_legal                           = @i_legalincomesource,                      
         @i_ea_actividad_legal                         = @i_noconnectiontoillegalnetworks,           
         @i_fatca                                      = @i_americanpersonfinancialpurposes,         
         @i_crs                                        = @i_residentoutsideofusaforfinancialpurposes,
         @i_oficial                                    = @i_officer_code,
         @i_oficina                                    = @i_branch_code,
         @i_origen                                     = 'O'                                   
    if @w_error != 0
      begin
        select @w_error = @w_error
        goto CIERRE
      end

   select @o_cod_ente = @w_ente
end

--Creación de auditoria
/*exec cobis..sp_api_auditoria
    @i_x_request_id                     = @i_x_request_id,
    @i_x_financial_id                   = @i_x_financial_id,
    @i_x_end_user_login                 = @i_x_end_user_login,
    @i_x_end_user_request_date_time     = @i_x_end_user_request_date_time,
    @i_x_end_user_terminal              = @i_x_end_user_terminal,
    @i_x_end_user_last_logged_date_time = @i_x_end_user_last_logged_date_time,
    @i_x_api_key                        = @i_x_api_key,
    @i_fecha_inicio                     = @w_fecha_proceso,
    @i_api_sp_name                      = @w_sp_name,
    @i_api_sp_operation                 = @i_operacion ,
    @i_status_code                          = 'O'*/

return 0

/* ************************************* */
/* CIERRE                                */
/* ************************************* */
CIERRE:
-- Asignar fecha de proceso
Select @o_fecha_proceso = convert(varchar(10), fp_fecha,103) +' '+ convert(varchar(10), fp_fecha,108) from cobis..ba_fecha_proceso

if @w_error != 0
  begin
    --Creacion de Auditoria
    /*exec cobis..sp_api_auditoria
        @i_x_request_id                     = @i_x_request_id,
        @i_x_financial_id                   = @i_x_financial_id,
        @i_x_end_user_login                 = @i_x_end_user_login,
        @i_x_end_user_request_date_time     = @i_x_end_user_request_date_time,
        @i_x_end_user_terminal              = @i_x_end_user_terminal,
        @i_x_end_user_last_logged_date_time = @i_x_end_user_last_logged_date_time,
        @i_x_api_key                        = @i_x_api_key,
        @i_fecha_inicio                     = @w_fecha_proceso,
        @i_api_sp_name                      = @w_sp_name,
        @i_status_code      = 'F',
        @i_api_error_code                   = @w_error,
        @i_api_sp_operation                 = @i_operacion*/
    exec cobis..sp_cerror
        @t_debug   = @t_debug,
        @t_file    = @t_file,
        @t_from    = @w_sp_name,
        @i_num     = @w_error,
		@s_culture = @s_culture 
    return @w_error
  end

go