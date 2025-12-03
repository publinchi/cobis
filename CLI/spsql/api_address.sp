/************************************************************************************/
/*  Archivo:            api_Address.sp                                               */
/*  Stored procedure:   sp_api_address                                              */
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
/*  2020-Jul-07       FSAP               Estandarizacion Clientes                   */
/************************************************************************************/

use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1
             from sysobjects
            where name = 'sp_api_address')
  drop proc sp_api_address
go

create proc sp_api_address(
       @s_ssn                                int         = NULL,
       @s_user                               varchar(14) = NULL,
       @s_sesn                               int         = NULL,
       @s_term                               varchar(30) = NULL,
       @s_date                               datetime    = NULL,
       @s_srv                                varchar(30) = NULL,
       @s_lsrv                               varchar(30) = NULL,
       @s_rol                                smallint    = NULL,
       @s_ofi                                smallint    = NULL,
       @s_org_err                            char(1)     = NULL,
       @s_error                              int         = NULL,
       @s_sev                                tinyint     = NULL,
       @s_msg                                varchar(64) = NULL,
       @s_org                                char(1)     = NULL,
       @t_trn                                int         = NULL,
       @t_debug                              char(1)     = 'N',
       @t_file                               varchar(14) = NULL,
       @t_corr                               char(1)     = 'N',
       @t_ssn_corr                           int         = NULL,
       @t_from                               varchar(32) = NULL,
       @t_rty                                char(1)     = NULL,
       @t_show_version                       bit         = 0,
	   -- parametros de cabecera
       @i_x_api_key                         varchar(40) = NULL,     --headers.x_api_key
       @i_Authorization                     varchar(100)= NULL,     --headers.Authorization
       @i_x_request_id                      varchar(36) = NULL,     --headers.x-request-id
       @i_x_financial_id                    varchar(25) = NULL,     --headers.x-financial-id
       @i_x_end_user_login                  varchar(25) = NULL,     --headers.x-end-user-login
       @i_x_end_user_request_date_time      varchar(25) = NULL,     --headers.x-end-user-request-date-time
       @i_x_end_user_terminal               varchar(25) = NULL,     --headers.x-end-user-terminal
       @i_x_end_user_last_logged_date_time  varchar(25) = NULL,     --headers.x-end-user-last-logged-date-time
       @i_x_jws_signature                   varchar(25) = NULL,     --headers.x-jws-signature
       @i_x_reverse                         varchar(25) = NULL,     --headers.x-reverse
       @i_x_requestId_to_reverse            varchar(25) = NULL,     --headers.x-requestId-to-reverse
       -- parametros del servicio
       @i_operacion                         char(1)     = NULL,    --operacion
       @i_ente_code                         int         = null,    --customerId
       @i_code                              tinyint     = NULL,    --addressId
       @i_address                           varchar(254)= NULL,    --address.address
       @i_subdivision_code                  catalogo    = NULL,    --subdivision.code
       @i_city_code                         int         = NULL,    --city.code
       @i_type_code                         catalogo    = NULL,    --type.code
       @i_region_code                       catalogo    = NULL,    --region.code
       @i_zone_code                         catalogo    = NULL,    --zone.code
       @i_valid                             char(1)     = 'S',     --valid                         NO LO RECIBE EL SP
       @i_verified                          char(1)     = 'N',     --verified
       @i_primaryaddress                    char(1)     = 'N',     --primaryAddress
       @i_neighborhood                      varchar(40) = NULL,    --neighborhood
       @i_province_code                     smallint    = NULL,    --province.code
       @i_country_code                      smallint    = NULL,    --country                       NO LO RECIBE EL SP
	   @i_propertytype_code                 catalogo    = NULL,    --propertytype.code
       @i_zipcode_code                      catalogo    = NULL,    --zipCode.code                  NO LO RECIBE EL SP
       @i_street                            varchar(70) = NULL,    --street                        NO LO RECIBE EL SP
       @i_externalnumber                    int         = NULL,    --externalNumber                NO LO RECIBE EL SP
       @i_timeincurrentresidence            int         = NULL,    --timeInCurrentResidence
       @i_numberofpeoplelivinginresidence   int         = NULL,    --numberOfPeopleLivingInResidence
	   @i_internalnumber                    int         = NULL,    --internalNumber                NO LO RECIBE EL SP
	   @i_population                        varchar(30) = NULL,    --populations
       @i_directions                        varchar(255)= NULL,    --directions
       @i_town_code                         varchar(10) = NULL,    --town.code
       @i_geo_latitude                      float       = NULL,    --geolocatization.latitude      LO RECIBE EL SP sp_direccion_geo
       @i_geo_longitude                     float       = NULL,    --geolocatization.longitude     LO RECIBE EL SP sp_direccion_geo
       -- parametro de salida
       @o_cod_address                       int         = NULL out, --address.code
       @o_fecha_proceso                     varchar(25) = NULL out    --fechaProceso
)as

declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_error                 int,
        @w_address               varchar(254),
        @w_subdivision           int,
        @w_city                  int,
        @w_type                  catalogo,
        @w_region                catalogo,
        @w_zone                  catalogo,
        @w_valid                 char(1),
        @w_verified              char(1),
        @w_primaryaddress        char(1),
        @w_neighborhood          varchar(40),
        @w_province              smallint,
        @w_country               smallint,
        @w_zipcode                catalogo,
        @w_street                varchar(70),
        @w_externalnumber        int,
        @w_internalnumber        int,
        @w_geo_latitude          float,
        @w_geo_longitude         float

select @w_sp_name = 'sp_api_address'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
  begin
    select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
    select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
    print  @w_sp_msg
    return 0
  end

/* ************************************* */
/* VALIDACIÓN DEL SERVICIO               */
/* ************************************* */

/* validacion que la aplicacion exista mediante el API key que se enuentre registrado
exec @w_error=cobis..sp_api_validation
     @i_api_key                        = @i_x_api_key,
     @i_operation                      = 'A'

if @w_error != 0
    goto CIERRE

Validar que el x-request-id no este duplicado para el mismo codigo de la aplicacion
exec @w_error=cobis..sp_api_validation
     @i_x_request_id                   = @i_x_request_id,
     @i_operation                      = 'O'

if @w_error != 0
    goto CIERRE

SELECT @w_fecha_proceso                = GETDATE() */

/* ************************************* */
/* OPERACIONES                           */
/* ************************************* */

/* Descripción: Realiza la creación de una dirección de correspondencia a un cliente o prospecto.
 * Operación: [POST] - /customers/{customerId}/addresses
 */
if @i_operacion = 'I'
  begin
    select top 1 en_ente
      from cobis..cl_ente
     where en_ente = @i_ente_code
    if @@rowcount = 0
      begin
        select @w_error = 1720021 -- No existe prospecto o cédula incorrecta.
        goto CIERRE
      end

    select @w_subdivision = CAST (@i_subdivision_code AS int )
    
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
         @i_ente                        = @i_ente_code,
         @i_define                      = 'S',
         @i_pais                        = @i_country_code,
		 @i_codpostal                   = @i_zipcode_code,
         @i_zona                        = @i_zone_code,
		 @i_provincia                   = @i_province_code ,       --province.code
         @i_ciudad                      = @i_city_code,
         @i_parroquia                   = @i_subdivision_code,
         @i_localidad                   = @i_town_code,
		 @i_ci_poblacion                = @i_population,                     
		 @i_calle                       = @i_street,
         @i_nro                         = @i_externalnumber,
         @i_nro_interno                 = @i_internalnumber,
         @i_descripcion                 = @i_address,
         @i_tiempo_reside               = @i_timeincurrentresidence,
		 @i_nro_residentes              = @i_numberofpeoplelivinginresidence,
         @i_tipo                        = @i_type_code,
         @i_tipo_prop                   = @i_propertytype_code,
         @i_principal                   = @i_primaryaddress,
         @i_verificado                  = @i_verified,
         @i_sector                      = @i_region_code,
         @i_barrio                      = @i_neighborhood,
         @i_referencias_dom             = @i_directions,                     
         @o_dire                        = @o_cod_address out
    if @w_error = 0
      begin
        if @i_geo_latitude is not null and @i_geo_longitude is not null
          begin
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
                 @t_trn                         = 172047,
                 @i_operacion                   ='I',
                 @i_ente                        = @i_ente_code,
                 @i_direccion                   = @o_cod_address,
                 @i_lat_segundos                = @i_geo_latitude,
                 @i_lon_segundos                = @i_geo_longitude
            if @w_error != 0
              begin
                goto CIERRE
              end
          end
        else
          begin
            goto CIERRE
          end
      end
  end

/* Descripción: Realiza la consulta de las direcciones asociadas al cliente o prospecto por el código COBIS del cliente.
 * Operación: [GET] - /customers/{customerId}/addresses
 */
if @i_operacion = 'A'
  begin
    /*Addresses*/
    select 'code'                            = di_direccion,
           'address'                         = di_descripcion,
           'subdivisionCode'                 = di_parroquia,
           'cityCode'                        = di_ciudad,
           'typeCode'                        = di_tipo,
           'regionCode'                      = di_sector,
           'zoneCode'                        = di_zona,
           'branchCode'                      = di_oficina,
           'creationDate'                    = di_fecha_registro,
           'lastUpdateDate'                  = di_fecha_modificacion,
           'valid'                           = di_vigencia,
           'verified'                        = di_verificado,
           'userLogin'                       = di_funcionario,
           'primaryAddress'                  = di_principal,
           'neighborhood'                    = di_barrio,
           'provinceCode'                    = di_provincia,
           'countryCode'                     = di_pais,
           'zipCode'                         = di_codpostal,
           'street'                          = di_calle,
           'externalNumber'                  = di_casa,
           'internalNumber'                  = di_nro_interno,
           'geoLatitude'                     = dg_lat_seg,
           'geoLongitude'                    = dg_long_seg,
                                             
           'propertyType'                    = di_tipo_prop,
           'timeInCurrentResidence'          = di_tiempo_reside,
           'numberOfPeopleLivingInResidence' = di_nro_residentes ,
           'population'                      = di_poblacion,
           'directions'                      = di_referencias_dom,
           'townCode'                        = di_localidad
      from cobis..cl_direccion d
      left join cobis..cl_direccion_geo g
        on d.di_ente       = g.dg_ente
       and d.di_direccion  = g.dg_direccion
     where di_tipo        in  ('AE','DE','RE')
      and di_ente          = @i_ente_code
    if @@rowcount = 0 
      begin
        select @w_error = 1720324 -- No se encontraron direcciones para el cliente
        goto CIERRE
      end
  end

/* Descripción: Realiza la consulta de las direcciones asociadas al cliente o prospecto por el código COBIS de la dirección.
 * Operación: [GET] - /customers/{customerId}/addresses/{addressId}
 */
if @i_operacion = 'Q'
  begin
    /*Addresses*/
    select 'code'                            = di_direccion,
           'address'                         = di_descripcion,
           'subdivisionCode'                 = di_parroquia,
           'cityCode'                        = di_ciudad,
           'typeCode'                        = di_tipo,
           'regionCode'                      = di_sector,
           'zoneCode'                        = di_zona,
           'branchCode'                      = di_oficina,
           'creationDate'                    = di_fecha_registro,
           'lastUpdateDate'                  = di_fecha_modificacion,
           'valid'                           = di_vigencia,
           'verified'                        = di_verificado,
           'userLogin'                       = di_funcionario,
           'primaryAddress'                  = di_principal,
           'neighborhood'                    = di_barrio,
           'provinceCode'                    = di_provincia,
           'countryCode'                     = di_pais,
           'zipCode'                         = di_codpostal,
           'street'                          = di_calle,
           'externalNumber'                  = di_casa,
           'internalNumber'                  = di_nro_interno,
           'geoLatitude'                     = dg_lat_seg,
           'geoLongitude'                    = dg_long_seg,
                                             
           'propertyType'                    = di_tipo_prop,
           'timeInCurrentResidence'          = di_tiempo_reside,
           'numberOfPeopleLivingInResidence' = di_nro_residentes ,
           'population'                      = di_poblacion,
           'directions'                      = di_referencias_dom,
           'townCode'                        = di_localidad
      from cobis..cl_direccion d
      left join cobis..cl_direccion_geo g
        on d.di_ente        = g.dg_ente
       and d.di_direccion   = g.dg_direccion
     where di_tipo         in ('AE','DE','RE')
       and di_ente          = @i_ente_code
       and di_direccion     = @i_code
    if @@rowcount = 0
      begin
        select @w_error = 1720324 -- No se encontraron direcciones para el cliente
        goto CIERRE
      end
  end

/* Descripción: Realiza la modificación de una dirección de correspondencia a un cliente o prospecto.
 * Operación: [PATCH] - ?/customers/{customerId}/addresses/{addressId}
 */
if @i_operacion = 'U'
  begin
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
         @t_trn                         = 172019,
         @t_from                        = @t_from,
         @i_operacion                   = 'U',
         @i_ente                        = @i_ente_code,
         @i_define                      = 'S',
         @i_direccion                   = @i_code,
		 @i_pais                        = @i_country_code,
		 @i_codpostal                   = @i_zipcode_code,
         @i_zona                        = @i_zone_code,
		 @i_provincia                   = @i_province_code ,       --province.code
         @i_ciudad                      = @i_city_code,
         @i_parroquia                   = @i_subdivision_code,
         @i_localidad                   = @i_town_code,
		 @i_ci_poblacion                = @i_population,                     
		 @i_calle                       = @i_street,
         @i_nro                         = @i_externalnumber,
         @i_nro_interno                 = @i_internalnumber,
         @i_descripcion                 = @i_address,
         @i_tiempo_reside               = @i_timeincurrentresidence,
		 @i_nro_residentes              = @i_numberofpeoplelivinginresidence,
         @i_tipo                        = @i_type_code,
         @i_tipo_prop                   = @i_propertytype_code,
         @i_principal                   = @i_primaryaddress,
         @i_verificado                  = @i_verified,
		 @i_sector                      = @i_region_code,
         @i_barrio                      = @i_neighborhood,
         @i_referencias_dom             = @i_directions
    if @w_error = 0
      begin
        if @i_geo_latitude is not null and @i_geo_longitude is not null
          begin
            exec @w_error = cobis..sp_direccion_geo
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
                 @t_from                        = @t_from,
                 @t_trn                         = 1608,
                 @i_operacion                   ='I',
                 @i_ente                        = @i_ente_code,
                 @i_direccion                   = @i_code,
                 @i_lat_segundos                = @i_geo_latitude,
                 @i_lon_segundos                = @i_geo_longitude
            if @w_error != 0
                goto CIERRE
          end

        select @o_cod_address = @i_code
      end
    else
      goto CIERRE  
  end

/* Descripción: Realiza la eliminación de una dirección de correspondencia a un cliente o prospecto.
 * Operación: [DELETE] - ?/customers?/{customerId}?/addresses?/{addressId}
 */
if @i_operacion = 'D'
  begin
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
         @t_trn                         = 172021,
         @t_from                        = @t_from,
         @i_operacion                   = 'D',
         @i_ente                        = @i_ente_code,
         @i_direccion                   = @i_code
    if @w_error != 0
      goto CIERRE
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
    @i_api_sp_operation                 = @i_operacion,
    @i_status                           = 'O'*/
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

go