/************************************************************************************/
/*  Archivo:            api_Email.sp                                                 */
/*  Stored procedure:   sp_api_email                                                */
/*  Base de datos:      cobis                                                       */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Jeison Gutierrez                                            */
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
/*  2019-Jul-10       jgutierrez              Emisión Inicial                       */
/*  2020-Jul-07       wviatela                Ajustes para nueva version de sp      */
/*  16/10/20          MBA                     Uso de la variable @s_culture         */
/************************************************************************************/

use cobis
go

if exists ( select 1 from sysobjects where name = 'sp_api_email' )
   drop proc sp_api_email
go


create proc sp_api_email(
   @s_ssn                               int         = NULL,
   @s_user                              varchar(14) = NULL,
   @s_sesn                              int         = NULL,
   @s_term                              varchar(30) = NULL,
   @s_date                              datetime    = NULL,
   @s_srv                               varchar(30) = NULL,
   @s_lsrv                              varchar(30) = NULL,
   @s_rol                               smallint    = NULL,
   @s_ofi                               smallint    = NULL,
   @s_org_err                           char(1)     = NULL,
   @s_error                             int         = NULL,
   @s_sev                               tinyint     = NULL,
   @s_msg                               varchar(64) = NULL,
   @s_org                               char(1)     = NULL,
   @s_culture                           varchar(10) = 'NEUTRAL',
   @t_trn                               int         = NULL,
   @t_debug                             char(1)     = 'N',
   @t_file                              varchar(14) = NULL,
   @t_corr                              char(1)     = 'N',
   @t_ssn_corr                          int         = NULL,
   @t_from                              varchar(32) = NULL,
   @t_rty                               char(1)     = NULL,
   @t_show_version                      bit         = 0,      --Versionamiento

   -- parametros de cabecera
   @i_x_api_key                         varchar(40) = NULL,    --headers.x_api_key
   @i_authorization                     varchar(100)= NULL,    --headers.Authorization
   @i_x_request_id                      varchar(36) = NULL,    --headers.x-request-id
   @i_x_financial_id                    varchar(25) = NULL,    --headers.x-financial-id
   @i_x_end_user_login                  varchar(25) = NULL,    --headers.x-end-user-login
   @i_x_end_user_request_date_time      varchar(25) = NULL,    --headers.x-end-user-request-date-time
   @i_x_end_user_terminal               varchar(25) = NULL,    --headers.x-end-user-terminal
   @i_x_end_user_last_logged_date_time  varchar(25) = NULL,    --headers.x-end-user-last-logged-date-time
   @i_x_jws_signature                   varchar(25) = NULL,    --headers.x-jws-signature
   @i_x_reverse							varchar(25) = NULL,     --headers.x-reverse
   @i_x_requestId_to_reverse			varchar(25) = NULL,     --headers.x-requestId-to-reverse

   -- parametros del servicio
   @i_operacion                         char(1)     = NULL,    --operacion
   @i_customerid                        int         = NULL,    --customerId
   @i_code                              tinyint     = NULL,    --emailId
   @i_mail                              varchar(254)= NULL,    --email.mail
   @i_valid                             char(1)     = 'S',     --valid
   @i_verified                          char(1)     = 'N',     --verified

   -- parametro de salida
   @o_cod_mail                          int         = NULL out, --mail.code
   @o_fecha_proceso                     varchar(25) = NULL out  --fechaProceso
)as

declare 
@w_sp_name                  varchar(30),
@w_error                    int,
@w_mail                     varchar(254),
@w_valid                    char(1),
@w_verified                 char(1),
@w_sp_msg                   varchar(132)

select @w_sp_name = 'sp_api_email'

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

/* Descripción: Realiza la creación de una dirección de correo electrónico a un cliente o prospecto.
 * Operación: [POST] - /customers/{customerId}/emails
 */

if @i_operacion = 'I' begin

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
   @i_ente                    = @i_customerid ,
   @i_descripcion             = @i_mail,
   @i_tipo                    = 'CE',
   @i_verificado              = @i_verified,
   @o_dire                    = @o_cod_mail out

   if @w_error != 0 goto CIERRE
end

/* Descripción: Realiza la consulta detallada de un correo electrónico de un cliente o prospecto por código COBIS del cliente.
 * Operación: [GET] - /customers/{customerId}/emails
 */

if @i_operacion = 'A' begin
/*Emails*/
   select
   'code'                      = di_direccion,
   'mail'                      = di_descripcion,
   'branchCode'                = di_oficina,
   'creationDate'              = di_fecha_registro,
   'lastUpdateDate'            = di_fecha_modificacion,
   'valid'                     = di_vigencia,
   'verified'                  = di_verificado,
   'userLogin'                 = di_funcionario
   from cobis..cl_direccion
   where di_tipo = 'CE'
   and di_ente = @i_customerid 
   
   if @@rowcount = 0 begin
      select @w_error = 1720340 -- No se encontro correo
      goto CIERRE
   end
end

/* Descripción: Realiza la consulta detallada de un correo electrónico de un cliente o prospecto por código COBIS del cliente y del correo.
 * Operación: [GET] - /customers/{customerId}/emails/{emailId}
 */

if @i_operacion = 'Q' begin
   /*Email*/
   select
   'code'                      = di_direccion,
   'mail'                      = di_descripcion,
   'branchCode'                = di_oficina,
   'creationDate'              = di_fecha_registro,
   'lastUpdateDate'            = di_fecha_modificacion,
   'valid'                     = di_vigencia,
   'verified'                  = di_verificado,
   'userLogin'                 = di_funcionario
   from cobis..cl_direccion
   where di_tipo = 'CE'
   and di_ente = @i_customerid 
   and di_direccion = @i_code

   if @@rowcount = 0 begin
      select @w_error = 1720340 -- No se encontro correo
      goto CIERRE
   end
end

/* Descripción: Realiza la modificación de una dirección de correo electrónico a un cliente o prospecto.
 * Operación: [PATCH] - ?/customers?/{customerId}?/emails?/{emailId}
 */

if @i_operacion = 'U' begin
   /*Store current address' state*/
   select
   @w_mail                     = di_descripcion,
   @w_valid                    = di_oficina,
   @w_verified                 = di_verificado
   from cobis..cl_direccion
   where di_tipo = 'CE'
   and di_ente = @i_customerid 
   and di_direccion = @i_code

   if @@rowcount = 0 begin
      select @w_error = 1720340 -- No se encontro correo
      goto CIERRE
   end

   exec @w_error = cobis..sp_direccion_dml
   @s_ssn                      = @s_ssn,
   @s_user                     = @s_user,
   @s_term                     = @s_term,
   @s_date                     = @s_date,
   @s_srv                      = @s_srv,
   @s_lsrv                     = @s_lsrv,
   @s_rol                      = @s_rol,
   @s_ofi                      = @s_ofi,
   @s_org_err                  = @s_org_err,
   @s_error                    = @s_error,
   @s_sev                      = @s_sev,
   @s_msg                      = @s_msg,
   @s_org                      = @s_org,
   @t_debug                    = @t_debug,
   @t_file                     = @t_file,
   @t_trn                      = 172019,
   @t_from                     = @t_from,
   @i_operacion                = 'U',
   @i_ente                     = @i_customerid ,
   @i_direccion                = @i_code,
   @i_tipo                     = 'CE',
   @i_descripcion              = @i_mail,
   @i_verificado               = @i_verified

   if @w_error != 0 goto CIERRE
   
   select @o_cod_mail = @i_code

end

 /* Descripción: Realiza la eliminación de un correo electrónico de un cliente o prospecto.
 * Operación: [DELETE] - ?/customers?/{customerId}?/emails?/{emailId}
 */

if @i_operacion = 'D' begin
    
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
   @t_trn                     = 172021,
   @t_from                    = @t_from,
   @i_operacion               = 'D',
   @i_ente                    = @i_customerid ,
   @i_direccion               = @i_code
   
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

-- Asignar fecha de w_fecha_proceso
select @o_fecha_proceso = convert(varchar(10), fp_fecha,103) +' '+ convert(varchar(10), fp_fecha,108) from cobis..ba_fecha_proceso
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
