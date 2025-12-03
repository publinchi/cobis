/************************************************************************************/
/*  Archivo:            api_legal_person.sp                                         */
/*  Stored procedure:   sp_api_legal_person                                         */
/*  Base de datos:      cobis                                                       */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Laura Chacon                                                */
/*  Fecha de creación:  nov-14-2019                                                 */
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
/*  2019-nov-14       l.chacon               Emisión Inicial                        */
/*  2020-jul-09       wviatela               Ajustes por actualizacion de sp´s      */
/************************************************************************************/

use cobis
go

if exists ( select 1 from sysobjects where name = 'sp_api_legal_person' )
   drop proc sp_api_legal_person
go

create proc sp_api_legal_person(
   @s_ssn                               int          = NULL,
   @s_user                              varchar(14)  = NULL,
   @s_sesn                              int          = NULL,
   @s_term                              varchar(30)  = NULL,
   @s_date                              datetime     = NULL,
   @s_srv                               varchar(30)  = NULL,
   @s_lsrv                              varchar(30)  = NULL,
   @s_rol                               smallint     = NULL,
   @s_ofi                               smallint     = NULL,
   @s_org_err                           char(1)      = NULL,
   @s_error                             int          = NULL,
   @s_sev                               tinyint      = NULL,
   @s_msg                               varchar(64)  = NULL,
   @s_org                               char(1)      = NULL,
   @t_trn                               int          = NULL,
   @t_debug                             char(1)      = 'N',
   @t_file                              varchar(14)  = NULL,
   @t_corr                              char(1)      = 'N',
   @t_ssn_corr                          int          = NULL,
   @t_from                              varchar(32)  = NULL,
   @t_rty                               char(1)      = NULL,
   -- parametros de cabecera
   @i_x_api_key                         varchar(40)  = NULL,         --headers.x_api_key
   @i_Authorization                     varchar(100) = NULL,         --headers.Authorization
   @i_x_request_id                      varchar(36)  = NULL,         --headers.x-request-id
   @i_x_financial_id                    varchar(25)  = NULL,         --headers.x-financial-id
   @i_x_end_user_login                  varchar(25)  = NULL,         --headers.x-end-user-login
   @i_x_end_user_request_date_time      varchar(25)  = NULL,         --headers.x-end-user-request-date-time
   @i_x_end_user_terminal               varchar(25)  = NULL,         --headers.x-end-user-terminal
   @i_x_end_user_last_logged_date_time  varchar(25)  = NULL,         --headers.x-end-user-last-logged-date-time
   @i_x_jws_signature                   varchar(25)  = NULL,         --headers.x-jws-signature
   @i_x_reverse							varchar(25)  = NULL,     --headers.x-reverse
   @i_x_requestId_to_reverse			varchar(25)  = NULL,     --headers.x-requestId-to-reverse
   -- parametros del servicio
   @i_operacion                         char(1)      = NULL,
   @i_code                              int          = null,         --customerId
   @i_id_number                         varchar(20)  = NULL,         --identification.number
   @i_id_type_code                      catalogo     = NULL,         --identification.type.code
   @i_name                              varchar(32)  = NULL,        --name
   @i_subsidiary                        tinyint      = NULL,        --subsidiary.code
   @i_branch                            smallint     = NULL,        --branch.code
   @i_producer_type                     varchar(10)  = NULL,        --producerType.code
   @i_group                             int          = NULL,         --group.code
   @i_officer                           smallint     = NULL,        --officer.code
   @i_activity                          catalogo     = NULL,        --activity.code
   @i_retention                         char(1)      = NULL,        --isRetainable
   @i_inhhibitory_reference             char(1)      = NULL,        --hasInhibitoryReference
   @i_comment                           varchar(254) = NULL,        --comment
   @i_sector                            varchar(10)  = NULL,        --economicSector.code
   @i_validated                         char(1)      = NULL,        --documentValidated
   @i_superban_reported                 char(1)      = NULL,        --bankingSuperintendenceReported
   @i_income                            money        = NULL,        --income
   @i_expense                           money        = NULL,        --expense
   @i_issuance_date                     datetime     = NULL,        --issuanceDate
   @i_client_risk_quality               varchar(10)  = NULL,        --clientRiskQuality.code
   @i_company_type                      varchar(10)  = NULL,        --companyType.code
   @i_assets                            money        = NULL,        --assets
   @i_liabilities                       money        = NULL,        --liabilities
   @i_ingroup                           char(1)      = NULL,        --inGroup
   @i_fullname                          char(254)    = NULL,        --fullName
   @i_entity_type                       varchar(10)  = NULL,        --entityType.code
   @i_total_assets                      money        = NULL,        --totalAssets
   @i_num_employees                     int          = NULL,        --numberEmployees
   @i_acronym                           varchar(25)  = NULL,        --acronym
   @i_valid                             char(1)      = NULL,        --valid                           NO LO RECIBE EL SP
   @i_client_status                     varchar(10)  = NULL,        --clientStatus.code
   @i_netassets                         money        = NULL,        --netAssets
   @i_grossequitydate                   datetime     = NULL,        --grossEquityDate
   @i_ownership                         char(1)      = NULL,        --majorityOwnership
   @i_clientquality                     catalogo     = NULL,        --clientQuality.code
   @i_grossincome                       char(1)      = NULL,        --grossIncome
   @i_relationship                      varchar(10)  = NULL,        --relationshipType.code
   @i_category                          varchar(10)  = NULL,        --category.code
   @i_rioe                              char(1)      = NULL,        --excemptRIOE
   @i_indebtedness                      money        = NULL,        --indebtednessFinancialSector
   @i_debtdate                          datetime     = NULL,        --debtInFinancialSectorDate
   @i_international_operations          char(1)      = NULL,        --hasInternationalOperations
   @i_nonoperating_income               money        = NULL,        --nonOperatingIncome
   @i_documents_in_folders              char(1)      = NULL,        --documentsInFolders
   @i_status                            char(1)      = NULL,        --status                   NO LO RECIBE EL SP DE NEGOCIO
   @i_country                           smallint     = NULL,         --country
   @i_other_income_amount               money        = null,
   @i_income_source                     descripcion  = null,
   @i_nivel_egresos                     varchar(10)  = NULL,
   @i_mnt_pasivo                        money        = null,
   @i_ventas                            money        = null,
   @i_ct_ventas                         money        = null,
   @i_ct_operativos                     money        = null,
   @i_legal_representative              int          = null,
   @i_firma_electronica                 varchar(30)  = null,
   @i_enrollment_date                   datetime     = null,
   -- Los siguientes parametros solo se utilizan en la operacion de creacion I
   -- parametros de direccion principal
   @i_address                           varchar(254) = NULL,     --address
   @i_type                              catalogo     = NULL,     --type.code
   @i_region                            catalogo     = NULL,     --region.code
   @i_subdivision                       smallint     = NULL,     --subdivision.code
   @i_neighborhood                      char(40)     = NULL,     --neighborhood
   @i_zone                              catalogo     = NULL,     --zone.code
   @i_city                              int          = NULL,     --city.code
   @i_verified                          char(1)      = NULL,      --verified
   @i_primaryaddress                    char(1)      = NULL,      --primaryAddress
   @i_province                          smallint     = NULL,     --province.code
   @i_geo_latitude                      float(53)    = NULL,     --geolocatization.latitude             LO RECIBE EL SP sp_direccion_geo
   @i_geo_longitude                     float(53)    = NULL,     --geolocatization.longitude            LO RECIBE EL SP sp_direccion_geo
   -- parametros de telefono asociado a la direccion principal
   @i_number                            varchar(16)  = NULL,     --number
   @i_phonetype                         char(2)      = NULL,     --type.code
   @i_collectionagency                  char(1)      = NULL,      --collectionAgency S o N
   @i_phonevalid                        char(1)      = NULL,
   @i_area                              varchar(10)  = NULL,     --area
   --parametros de email
   @i_mail                              varchar(254) = NULL,     --email.mail
   @i_email_verified                    char(1)      = NULL,     --email.verified
   -- parametros de salida
   @o_cod_ente                          int          = NULL output, --legalperson.code
   @o_cod_address                       int          = NULL output, --address.code
   @o_fecha_proceso                     varchar(25)  = NULL output
)as

declare @w_sp_name                      varchar(30),
   @w_error                             int,
   @w_ente                              int,
   @w_id_number                         varchar(20),
   @w_id_type_code                      catalogo,
   @w_country                           smallint,
   @w_retention                         char(1),
   @w_name                              varchar(32),
   @w_group                             int

select @w_sp_name = 'sp_api_legal_person'

/* ************************************* */
/* OPERACIONES                           */
/* ************************************* */

/* Descripción: Realiza la creación de un cliente jurídico con los datos básicos. Adicionalmente se permite agregar una única dirección, correo y/o teléfono.
* Operación: [POST] - /customers/legal-persons
*/

if @i_operacion = 'I' begin
   /*Validacion de la obligatoriedad de los filtros*/
   if (@i_id_type_code is null or @i_retention is null or @i_name is null or @i_subsidiary is null or @i_branch is null)
   begin
      select @w_error = 100000001 -- tabla cobis..cl_errores
      goto CIERRE
   end
   
   -- Contenido de la operación
   exec @w_error = cobis..sp_compania_ins
   @s_user                        = @s_user,
   @s_term                        = @s_term,
   @s_date                        = @s_date,
   @t_trn                         = 172008,
   @i_operacion                   = 'I',
   @i_ente                        = 0,
   @i_ced_ruc                     = @i_id_number,
   @i_tipo_ced                    = @i_id_type_code,
   @i_nombre                      = @i_name,
   @i_pais                        = @i_country,
   @i_filial                      = @i_subsidiary,   
   @i_oficina                     = @i_branch,
   @i_retencion                   = @i_retention,
   @i_actividad                   = @i_activity,
   @i_comentario                  = @i_comment,
   @i_sector                      = @i_sector,
   @i_total_activos               = @i_total_assets,
   @i_otros_ingresos              = @i_other_income_amount, 
   @i_origen_ingresos             = @i_income_source, 
   @i_ea_estado                   = @i_status,
   @i_ea_actividad                = @i_activity,
   @i_ea_remp_legal               = @i_legal_representative, 
   @i_egresos                     = @i_nivel_egresos,
   @i_mnt_pasivo                  = @i_mnt_pasivo,
   @i_ventas                      = @i_ventas, 
   @i_ct_ventas                   = @i_ct_ventas, 
   @i_ct_operativos               = @i_ct_operativos, 
   @i_rep_legal                   = @i_legal_representative, 
   @i_firma_electronica           = @i_firma_electronica, 
   @i_tipo_soc                    = @i_entity_type,
   @i_fecha_crea                  = @i_enrollment_date, 
   @i_mala_referencia             = @i_inhhibitory_reference,
   @i_formato_fecha               = 111, -- YYYY/MM/DD
   @o_ente                        = @o_cod_ente out

   if @w_error = 0 begin
      exec @w_error = cobis..sp_direccion_dml
      @s_ssn                         = @s_ssn,
      @s_user                        = @s_user,
      @s_term                        = @s_term,
      @s_date                        = @s_date,
      @s_srv                         = @s_srv,
      @s_lsrv                        = @s_lsrv,
      @s_rol                         = @s_rol,
      @s_ofi                         = @s_ofi,
      @s_org_err                     = @s_org_err,
      @s_error                       = @s_error,
      @s_sev                         = @s_sev,
      @s_msg                         = @s_msg,
      @s_org                         = @s_org,
      @t_debug                       = @t_debug,
      @t_file                        = @t_file,
      @t_trn                         = 172016,
      @t_from                        = @t_from,
      @i_operacion                   = 'I',
      @i_ente                        = @o_cod_ente,
      @i_descripcion                 = @i_address,        --address.address
      @i_tipo                        = @i_type,           --type.code
      @i_sector                      = @i_region,         --region.code
      @i_parroquia                   = @i_subdivision,    --subdivision.code
      @i_barrio                      = @i_neighborhood,   --neighborhood
      @i_zona                        = @i_zone,           --zone.code
      @i_ciudad                      = @i_city,           --city.code
      @i_oficina                     = @i_branch,         --branch.code
      @i_verificado                  = @i_verified,       --verified
      @i_principal                   = @i_primaryaddress, --primaryAddress
      @i_provincia                   = @i_province,       --province.code
      @o_dire                        = @o_cod_address out

      if @w_error = 0 begin
         if @i_geo_latitude is not null and @i_geo_longitude is not null begin
            exec @w_error = cobis..sp_direccion_geo
            @s_ssn                         = @s_ssn,
            @s_user                        = @s_user,
            @s_sesn                        = @s_sesn,
            @s_term                        = @s_term,
            @s_date                        = @s_date,
            @s_srv                         = @s_srv,
            @s_lsrv                        = @s_lsrv,
            @s_rol                         = @s_rol,
            @s_ofi                         = @s_ofi,
            @s_org_err                     = @s_org_err,
            @s_error                       = @s_error,
            @s_sev                         = @s_sev,
            @s_msg                         = @s_msg,
            @s_org                         = @s_org,
            @t_debug                       = @t_debug,
            @t_file                        = @t_file,
            @t_from                        = @t_from,
            @t_trn                         = 1608,
            @i_operacion                   ='I',
            @i_ente                        = @o_cod_ente,
            @i_direccion                   = @o_cod_address,
            @i_lat_segundos                = @i_geo_latitude,
            @i_lon_segundos                = @i_geo_longitude

            if @w_error != 0 goto CIERRE
			
         end

         exec @w_error = cobis..sp_telefono
         @s_ssn                          = @s_ssn,
         @s_user                         = @s_user,
         @s_term                         = @s_term,
         @s_date                         = @s_date,
         @s_srv                          = @s_srv,
         @s_lsrv                         = @s_lsrv,
         @s_rol                          = @s_rol,
         @s_ofi                          = @s_ofi,
         @s_org_err                      = @s_org_err,
         @s_error                        = @s_error,
         @s_sev                          = @s_sev,
         @s_msg                          = @s_msg,
         @s_org                          = @s_org,
         @t_debug                        = @t_debug,
         @t_file                         = @t_file,
         @t_trn                          = 172031,
         @t_from                         = @t_from,
         @i_operacion                    = 'I',
         @i_ente                         = @o_cod_ente,
         @i_direccion                    = @o_cod_address,
         @i_valor                        = @i_number,
         @i_tipo_telefono                = @i_phonetype,
         @i_te_telf_cobro                = @i_collectionagency,
         @i_verificado                   = @i_phonevalid,
         @i_cod_area                     = @i_area,
		 @i_prefijo	                     = null


         if @w_error != 0 goto CIERRE
      end
      
	  exec @w_error = cobis..sp_direccion_dml
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
      @t_trn                     = 172016,
      @t_from                    = @t_from,
      @i_operacion               = 'I',
      @i_ente                    = @o_cod_ente,
      @i_descripcion             = @i_mail,
      @i_tipo                    = 'CE',
      @i_oficina                 = @i_branch,
      @i_verificado              = @i_email_verified
      
      if @w_error != 0 goto CIERRE
   end
   else goto CIERRE

end


/* Descripción: Realiza la consulta de los datos básicos de un cliente o prospecto de tipo jurídico mediante el código COBIS.
* Operación: [GET] - /customers/legal-persons/{customerId}
*/

if @i_operacion = 'Q' begin
   /*Valida la existencia del cliente*/
   select  @w_ente = en_ente
   from    cobis..cl_ente
   where   en_ente  = @i_code
   and     en_subtipo = 'C'

   if @@rowcount = 0 begin
      select @w_error = 2101152
      goto CIERRE
   end

   -- Contenido de la operación
   select
   'code'                              = en_ente,
   'identificationNumber'              = en_ced_ruc,
   'identificationTypeCode'            = en_tipo_ced,
   'issuenceCityCountryCode'           = en_pais,
   'issuenceCityCountryName'           = (select pa_descripcion from cl_pais where pa_pais = en_pais),
   'name'                              = en_nombre,
   'subsidiaryCode'                    = en_filial,
   'branchCode'                        = en_oficina,
   'creationDate'                      = en_fecha_crea,
   'lastUpdateDate'                    = en_fecha_mod,
   'producerTypeCode'                  = en_casilla_def,
   'groupCode'                         = en_grupo,
   'groupName'                         = (select gr_nombre from cl_grupo where gr_grupo = en_grupo),
   'officerCode'                       = en_oficial,
   'activityCode'                      = en_actividad,
   'isRetainable'                      = en_retencion,
   'hasInhibitoryReference'            = en_mala_referencia,
   'comment'                           = en_comentario,
   'economicSectorCode'                = en_sector,
   'bankingSuperintendenceReported'    = en_rep_superban,
   'income'                            = p_nivel_ing,
   'expense'                           = p_nivel_egr,
   'issuanceDate'                      = convert(char(10), p_fecha_emision, 101),
   'companyType'                       = c_tipo_compania,
   'inGroup'                           = c_es_grupo,
   'entityType'                        = c_tipo_soc,
   'totalAssets'                       = c_total_activos,
   'numberEmployees'                   = c_num_empleados,
   'acronym'                           = c_sigla,
   'valid'                             = c_vigencia,
   'clientStatusCode'                  = en_situacion_cliente,
   'clientStatusDescription'           = (select valor from cl_catalogo, cl_tabla where   cl_tabla.tabla = 'cl_situacion_cliente' and cl_catalogo.tabla = cl_tabla.codigo and cl_catalogo.codigo = en_situacion_cliente),
   'netAssets'                         = en_patrimonio_tec,
   'grossEquityDate'                   = convert(char(10), en_fecha_patri_bruto, 101),
   'majorityOwnership'                 = en_gran_contribuyente,
   'clientQualityCode'                 = c_posicion,
   'clientQualityDesc'                 = (select valor from cl_catalogo, cl_tabla where   cl_tabla.tabla = 'cl_calif_cliente' and cl_catalogo.tabla = cl_tabla.codigo and cl_catalogo.codigo = c_posicion),
   'grossIncome'                       = en_reestructurado,
   'relationshipTypeCode'              = en_tipo_vinculacion,
   'relationshipTypeDescription'       = (select valor from cl_catalogo, cl_tabla where  cl_tabla.tabla = 'cl_relacion_banco' and cl_catalogo.tabla = cl_tabla.codigo and cl_catalogo.codigo = en_tipo_vinculacion),
   'isPreferred'                       = en_preferen,
   'excempt'                           = en_exc_sipla,
   'excempt3000'                       = en_exc_por2,
   'categoryCode'                      = en_categoria,
   'categoryDescription'               = (select valor from cl_catalogo, cl_tabla where  cl_tabla.tabla = 'cl_tipo_cliente' and cl_catalogo.tabla = cl_tabla.codigo and cl_catalogo.codigo = en_categoria),
   'totalLiabilities'                  = c_total_pasivos,
   'excemptRIOE'                       = en_rep_sib,
   'indebtednessFinancialSector'       = en_pas_finan,
   'debtInFinancialSectorDate'         = convert(varchar(10), en_fpas_finan, 101),
   'hasInternationalOperations'        = en_relacint,
   'nonOperatingIncome'                = en_otringr,
   'documentsInFolders'                = en_doctos_carpeta,
   'status'                            = en_estado
   from    cobis..cl_ente
   where   en_ente= @w_ente
   and     en_subtipo = 'C'

end

/* Descripción: Realiza la consulta de los datos básicos de un cliente de tipo persona jurídica por tipo y número de identificación.
* Operación: [GET] - ​/customers​/legal-persons​/type​/{identificationTypeCode}​/number​/{identificationNumber}
*/

if @i_operacion = 'C' begin

   /*Valida la obligatoriedad de los filtros*/
   if (@i_id_number is NULL or @i_id_type_code is NULL) begin
      select @w_error = 100000001
      goto CIERRE
   end

   /*Valida la existencia del cliente*/
   select  @w_ente = en_ente
   from    cobis..cl_ente
   where   en_ced_ruc = @i_id_number
   and     en_tipo_ced = trim(@i_id_type_code)
   and     en_subtipo = 'C'

   if @@rowcount = 0 begin
      select @w_error = 2101152
      goto CIERRE
   end

   -- Contenido de la operación
   select
   'code'                              = en_ente,
   'identificationNumber'              = en_ced_ruc,
   'identificationTypeCode'            = en_tipo_ced,
   'issuenceCityCountryCode'           = en_pais,
   'issuenceCityCountryName'           = (select pa_descripcion from cl_pais where pa_pais = en_pais),
   'name'                              = en_nombre,
   'subsidiaryCode'                    = en_filial,
   'branchCode'                        = en_oficina,
   'creationDate'                      = en_fecha_crea,
   'lastUpdateDate'                    = en_fecha_mod,
   'producerTypeCode'                  = en_casilla_def,
   'groupCode'                         = en_grupo,
   'groupName'                         = (select gr_nombre from cl_grupo where gr_grupo = en_grupo),
   'officerCode'                       = en_oficial,
   'activityCode'                      = en_actividad,
   'isRetainable'                      = en_retencion,
   'hasInhibitoryReference'            = en_mala_referencia,
   'comment'                           = en_comentario,
   'economicSectorCode'                = en_sector,
   'bankingSuperintendenceReported'    = en_rep_superban,
   'income'                            = p_nivel_ing,
   'expense'                           = p_nivel_egr,
   'issuanceDate'                      = convert(char(10), p_fecha_emision, 101),
   'companyType'                       = c_tipo_compania,
   'inGroup'                           = c_es_grupo,
   'entityType'                        = c_tipo_soc,
   'totalAssets'                       = c_total_activos,
   'numberEmployees'                   = c_num_empleados,
   'acronym'                           = c_sigla,
   'valid'                             = c_vigencia,
   'clientStatusCode'                  = en_situacion_cliente,
   'clientStatusDescription'           = (select valor from cl_catalogo, cl_tabla where   cl_tabla.tabla = 'cl_situacion_cliente' and cl_catalogo.tabla = cl_tabla.codigo and cl_catalogo.codigo = en_situacion_cliente),
   'netAssets'                         = en_patrimonio_tec,
   'grossEquityDate'                   = convert(char(10), en_fecha_patri_bruto, 101),
   'majorityOwnership'                 = en_gran_contribuyente,
   'clientQualityCode'                 = c_posicion,
   'clientQualityDesc'                 = (select valor from cl_catalogo, cl_tabla where   cl_tabla.tabla = 'cl_calif_cliente' and cl_catalogo.tabla = cl_tabla.codigo and cl_catalogo.codigo = c_posicion),
   'grossIncome'                       = en_reestructurado,
   'relationshipTypeCode'              = en_tipo_vinculacion,
   'relationshipTypeDescription'       = (select valor from cl_catalogo, cl_tabla where  cl_tabla.tabla = 'cl_relacion_banco' and cl_catalogo.tabla = cl_tabla.codigo and cl_catalogo.codigo = en_tipo_vinculacion),
   'isPreferred'                       = en_preferen,
   'excempt'                           = en_exc_sipla,
   'excempt3000'                       = en_exc_por2,
   'categoryCode'                      = en_categoria,
   'categoryDescription'               = (select valor from cl_catalogo, cl_tabla where  cl_tabla.tabla = 'cl_tipo_cliente' and cl_catalogo.tabla = cl_tabla.codigo and cl_catalogo.codigo = en_categoria),
   'totalLiabilities'                  = c_total_pasivos,
   'excemptRIOE'                       = en_rep_sib,
   'indebtednessFinancialSector'       = en_pas_finan,
   'debtInFinancialSectorDate'         = convert(varchar(10), en_fpas_finan, 101),
   'hasInternationalOperations'        = en_relacint,
   'nonOperatingIncome'                = en_otringr,
   'documentsInFolders'                = en_doctos_carpeta,
   'status'                            = en_estado
   from    cobis..cl_ente
   where   en_ente= @w_ente
   and     en_subtipo = 'C'
end

/* Descripción: Modificación de cliente o prospecto de tipo persona jurídica.
* Operación: [PATCH] - /customers/legal-persons/{customerId}
*/

if @i_operacion = 'U' begin
   /*Validacion de la obligatoriedad de los filtros*/
   if @i_code is null begin
      select @w_error = 100000001 -- tabla cobis..cl_errores
      goto CIERRE
   end

   -- Contenido de la operación
   exec @w_error = cobis..sp_compania_ins
   @s_user                        = @s_user,
   @s_term                        = @s_term,
   @s_date                        = @s_date,
   @t_trn                         = 172009,
   @i_operacion                   = 'U',
   @i_ente                        = @i_code,
   @i_ced_ruc                     = @i_id_number,
   @i_tipo_ced                    = @i_id_type_code,
   @i_nombre                      = @i_name,
   @i_pais                        = @i_country,
   @i_filial                      = @i_subsidiary,   
   @i_oficina                     = @i_branch,
   @i_retencion                   = @i_retention,
   @i_actividad                   = @i_activity,
   @i_comentario                  = @i_comment,
   @i_sector                      = @i_sector,
   @i_total_activos               = @i_total_assets,
   @i_otros_ingresos              = @i_other_income_amount, 
   @i_origen_ingresos             = @i_income_source, 
   @i_ea_estado                   = @i_status,
   @i_ea_actividad                = @i_activity,
   @i_ea_remp_legal               = @i_legal_representative, 
   @i_egresos                     = @i_nivel_egresos,
   @i_mnt_pasivo                  = @i_mnt_pasivo,
   @i_ventas                      = @i_ventas, 
   @i_ct_ventas                   = @i_ct_ventas, 
   @i_ct_operativos               = @i_ct_operativos, 
   @i_rep_legal                   = @i_legal_representative, 
   @i_firma_electronica           = @i_firma_electronica, 
   @i_tipo_soc                    = @i_entity_type,
   @i_fecha_crea                  = @i_enrollment_date, 
   @i_mala_referencia             = @i_inhhibitory_reference,
   @i_formato_fecha               = 111 -- YYYY/MM/DD

   if(@w_error !=0) begin
      goto CIERRE
   end

   select @o_cod_ente = @i_code

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
	@i_status                           = 'O'*/

/* ************************************* */
/* CIERRE                                */
/* ************************************* */

CIERRE:
   -- Asignar fecha de proceso

Select @o_fecha_proceso = convert(varchar(10), fp_fecha,103) +' '+ convert(varchar(10), fp_fecha,108) from cobis..ba_fecha_proceso

if @w_error != 0 begin
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
   @i_status                           = 'F',
   @i_api_error_code                   = @w_error,
   @i_api_sp_operation                 = @i_operacion*/

   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_num   = @w_error
   return @w_error
end

return 0
go
