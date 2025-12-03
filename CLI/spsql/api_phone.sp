/************************************************************************************/
/*  Archivo:            api_phone.sp                                                */
/*  Stored procedure:   sp_api_phone                                                */
/*  Base de datos:      cobis                                                       */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Leehener Cabeza Durango                                     */
/*  Fecha de creación:  Jul-10-2019                                                 */
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
/*  2019-Jul-10       lcabeza                 Emisión Inicial                       */
/*  2020-Jul-07       FSAP                    Estandarizacion Clientes              */
/*  16/10/20          MBA                     Uso de la variable @s_culture         */
/************************************************************************************/

use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTifIER off
go

if exists ( select 1 from sysobjects where name = 'sp_api_phone' )
    drop proc sp_api_phone
go

create proc sp_api_phone(
    @s_ssn                              int         = NULL,
    @s_user                             varchar(14) = NULL,
    @s_sesn                             int         = NULL,
    @s_term                             varchar(30) = NULL,
    @s_date                             datetime    = NULL,
    @s_srv                              varchar(30) = NULL,
    @s_lsrv                             varchar(30) = NULL,
    @s_rol                              smallint    = NULL,
    @s_ofi                              smallint    = NULL,
    @s_org_err                          char(1)     = NULL,
    @s_error                            int         = NULL,
    @s_sev                              tinyint     = NULL,
    @s_msg                              varchar(64) = NULL,
    @s_org                              char(1)     = NULL,
	@s_culture                          varchar(10) = 'NEUTRAL',
    @t_trn                              int         = NULL,
    @t_debug                            char(1)     = 'N',
    @t_file                             varchar(14) = NULL,
    @t_corr                             char(1)     = 'N',
    @t_ssn_corr                         int         = NULL,
    @t_from                             varchar(32) = NULL,
    @t_rty                              char(1)     = NULL,
	@t_show_version                     bit         = 0,

    -- parametros de cabecera
    @i_x_api_key                        varchar(40) = NULL,     --headers.x_api_key
    @i_authorization                    varchar(100)= NULL,     --headers.Authorization
    @i_x_request_id                     varchar(36) = NULL,     --headers.x-request-id
    @i_x_financial_id                   varchar(25) = NULL,     --headers.x-financial-id
    @i_x_end_user_login                 varchar(25) = NULL,     --headers.x-end-user-login
    @i_x_end_user_request_date_time     varchar(25) = NULL,     --headers.x-end-user-request-date-time
    @i_x_end_user_terminal              varchar(25) = NULL,     --headers.x-end-user-terminal
    @i_x_end_user_last_logged_date_time varchar(25) = NULL,     --headers.x-end-user-last-logged-date-time
    @i_x_jws_signature                  varchar(25) = NULL,     --headers.x-jws-signature
    @i_x_reverse                        varchar(25) = NULL,     --headers.x-reverse
    @i_x_requestid_to_reverse           varchar(25) = NULL,     --headers.x-requestId-to-reverse

    -- parametros del servicio
    @i_operacion                        char(1)     = NULL,     --operacion
    @i_customerid                       int         = NULL,     --customerId
    @i_addressid                        tinyint     = NULL,     --addressId
    @i_code                             int         = NULL,     --phoneId
    @i_number                           varchar(16) = NULL,     --phone.number
    @i_type                             char(2)     = NULL,     --phone.type.code
    @i_prefix                           varchar(10) = NULL,     --phone.prefix
    @i_area                             varchar(10) = NULL,     --phone.area
    @i_collectionagency                 char(1)     = NULL,     --phone.collectionAgency
    @i_valid                            char(1)     = NULL,     --phone.valid
	@i_customerserviceline_code         varchar(10) = NULL,     --customerserviceline.code

    -- parametro de salida
    @o_cod_phone                        int         = NULL out, --code.phone
    @o_fecha_proceso                    varchar(25) = NULL out  --fechaProceso

)as

declare @w_sp_name                      varchar(30),
        @w_sp_msg                       varchar(132),
        @w_error                        int,
        @w_number                       varchar(16),
        @w_type                         char(2),
        @w_prefix                       varchar(10),
        @w_area                         varchar(10),
        @w_collectionagency             char(1)


select @w_sp_name = 'sp_api_phone'


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
/* VALIDACIÓN DEL SERVICIO               */
/* ************************************* */

/* validacion que la aplicacion exista mediante el API key que se enuentre registrado
exec @w_error=cobis..sp_api_validation
    @i_api_key                          = @i_x_api_key,
    @i_operation                        = 'A'

if @w_error != 0
    goto CIERRE

Validar que el x-request-id no este duplicado para el mismo codigo de la aplicacion
exec @w_error=cobis..sp_api_validation
    @i_x_request_id                     = @i_x_request_id,
    @i_operation                        = 'O'

if @w_error != 0
    goto CIERRE

SELECT @w_fecha_proceso                 = GETDATE()*/

/* ************************************* */
/* OPERACIONES                           */
/* ************************************* */

/* Descripción: Realiza la creación de un teléfono de contacto a una dirección de un cliente o prospecto.
 * Operación: [POST] - /customers/{customerId}/addresses/{addressId}/phones
 */

if @i_operacion = 'I'
 begin
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
        @i_ente                         = @i_customerid,
        @i_direccion                    = @i_addressid,
        @i_valor                        = @i_number,
        @i_tipo_telefono                = @i_type,
        @i_te_telf_cobro                = @i_collectionagency,
        @i_verificado                   = i_valid,
        @i_cod_area                     = @i_area,
        @i_prefijo                      = @i_prefix,
		@i_customerserviceline_code     = @i_customerserviceline_code --pendiente de agregar parametro en el sp    sp_telefono                
    if @w_error != 0
        goto CIERRE

    select @o_cod_phone = max (te_secuencial)
    from cobis..cl_telefono
    where te_ente = @i_customerid
    and te_direccion = @i_addressid

 end

/* Descripción: Realiza la consulta detallada de un teléfono asociados a una dirección de un cliente o prospecto por código COBIS del cliente.
 * Operación: [GET] - /customers/{customerId}/addresses/{addressId}/phones
 */
if @i_operacion = 'A'
begin
    select
        'code'                          = te_secuencial,
        'number'                        = te_valor,
        'typeCode'                      = te_tipo_telefono,
        'prefix'                        = te_prefijo,
        'creationDate'                  = te_fecha_registro,
        'lastUpdateDate'                = te_fecha_mod,
        'area'                          = te_area,
        'collectionAgency'              = te_telf_cobro,
        'userLogin'                     = te_funcionario,
        'valid'                         = te_verificado,
        
        'customerServiceLineCode'       = te_tipo_operador
    from cobis..cl_telefono
    where te_ente = @i_customerid and te_direccion = @i_addressid

    if @@rowcount = 0
    begin
        select @w_error = 1720151 -- No se encontro telefono
        goto CIERRE
    end
end

/* Descripción: Realiza la consulta detallada de un teléfono asociado a una dirección de un cliente o prospecto por código COBIS del cliente y del teléfono.
 * Operación: [GET] - /customers/{customerId}/addresses/{addressId}/phones/{phoneId}
 */

if @i_operacion = 'Q'
begin
    select
        'code'                          = te_secuencial,
        'number'                        = te_valor,
        'typeCode'                      = te_tipo_telefono,
        'prefix'                        = te_prefijo,
        'creationDate'                  = te_fecha_registro,
        'lastUpdateDate'                = te_fecha_mod,
        'area'                          = te_area,
        'collectionAgency'              = te_telf_cobro,
        'user'                          = te_funcionario,
        'valid'                         = te_verificado,
        
        'customerServiceLineCode'       = te_tipo_operador
    from cobis..cl_telefono
    where te_ente = @i_customerid
    and te_direccion = @i_addressid
    and te_secuencial = @i_code

    if @@rowcount = 0
    begin
        select @w_error = 1720151 -- No se encontro telefono
        goto CIERRE
    end
end

/* Descripción: Realiza la modificación de un teléfono de contacto de una dirección de un cliente o prospecto.
 * Operación: [PATCH] - ?/customers/{customerId}/addresses/{addressId}/phones/{phoneId}
 */

if @i_operacion = 'U'
begin
    exec @w_error = cobis..sp_telefono
        @s_ssn                              = @s_ssn,
        @s_user                             = @s_user,
        @s_term                             = @s_term,
        @s_date                             = @s_date,
        @s_srv                              = @s_srv,
        @s_lsrv                             = @s_lsrv,
        @s_rol                              = @s_rol,
        @s_ofi                              = @s_ofi,
        @s_org_err                          = @s_org_err,
        @s_error                            = @s_error,
        @s_sev                              = @s_sev,
        @s_msg                              = @s_msg,
        @s_org                              = @s_org,
        @t_debug                            = @t_debug,
        @t_file                             = @t_file,
        @t_trn                              = 172032,
        @t_from                             = @t_from,
        @i_operacion                        = 'U',
        @i_secuencial                       = @i_code,
        @i_ente                             = @i_customerid,
        @i_direccion                        = @i_addressid,
        @i_valor                            = @i_number,
        @i_tipo_telefono                    = @i_type,
        @i_te_telf_cobro                    = @i_collectionagency,
        @i_cod_area                         = @i_area,
        @i_prefijo                          = @i_prefix,
		@i_customerserviceline_code         = @i_customerserviceline_code --pendiente de agregar parametro en el sp    sp_telefono                
    
    if @w_error != 0
        goto CIERRE

    select @o_cod_phone                     = @i_code
end

/* Descripción: Realiza la eliminación de un teléfono de una dirección de un cliente o prospecto.
 * Operación: [DELETE] - ?/customers/{customerId}/addresses/{addressId}/phones/{phoneId}
 */

if @i_operacion = 'D'
begin

    select te_secuencial from cobis..cl_telefono where te_ente = @i_customerid and te_direccion = @i_addressid and te_secuencial = @i_code
    if @@rowcount = 0
        begin
            select @w_error = 1720151 -- No se encontro telefono
            goto CIERRE
        end
        
    exec @w_error = cobis..sp_telefono
        @s_ssn                          = @s_ssn,
        @s_user                         = @s_user,
        --@s_sesn                       = @s_sesn,
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
        @t_trn                          = 172034,
        @t_from                         = @t_from,
        @i_operacion                    = 'D',
        @i_ente                         = @i_customerid,
        @i_direccion                    = @i_addressid,
        @i_secuencial                   = @i_code

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
    @i_api_sp_operation                 = @i_operacion ,
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
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @i_num      = @w_error,
	    @s_culture  = @s_culture
    return @w_error

end

go

