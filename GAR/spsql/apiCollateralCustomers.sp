use cob_custodia
go

if exists ( select 1 from sysobjects where name = 'sp_api_collateral_customers' )
   drop proc sp_api_collateral_customers
go

/************************************************************************************/
/*  Archivo:            apiCollateralCustomers.sp                                   */
/*  Stored procedure:   sp_api_collateral_customers                                 */
/*  Base de datos:      cob_custodia                                                */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Laura Chacón                                                */
/*  Fecha de creación:  sep-24-2019                                                 */
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
/*  2019-sep-24      lchacon                  Emisión Inicial                       */
/************************************************************************************/


create proc sp_api_collateral_customers(
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
    @t_trn                               int         = NULL,
    @t_debug                             char(1)     = 'N',
    @t_file                              varchar(14) = NULL,
    @t_corr                              char(1)     = 'N',
    @t_ssn_corr                          int         = NULL,
    @t_from                              varchar(32) = NULL,
    @t_rty                               char(1)     = NULL,

    -- parametros de cabecera
    @i_Authorization                     varchar(100)= NULL,     --headers.Authorization
    @i_x_request_id                      varchar(36) = NULL,     --headers.x-request-id
    @i_x_financial_id                    varchar(25) = NULL,     --headers.x-financial-id
    @i_x_end_user_login                  varchar(25) = NULL,     --headers.x-end-user-login
    @i_x_end_user_request_date_time      varchar(25) = NULL,     --headers.x-end-user-request-date-time
    @i_x_end_user_terminal               varchar(25) = NULL,     --headers.x-end-user-terminal
    @i_x_end_user_last_logged_date_time  varchar(25) = NULL,     --headers.x-end-user-last-logged-date-time
    @i_x_jws_signature                   varchar(25) = NULL,     --headers.x-jws-signature
    @i_x_reverse							varchar(25) = NULL,     --headers.x-reverse
    @i_x_ssn_to_reverse			varchar(25) = NULL,     --headers.x-requestId-to-reverse

    -- parametros del servicio
    @i_operacion                         char(1)     = NULL,     --operacion
    @i_collateralId                      varchar(36) = NULL,    --collateral.code
    @i_customerCode                      int         = NULL,    --collateralCustomer.code
    @i_isMain                            char(6)     = NULL,    --collateralCustomer.isMain

    -- parametro de salida
    @o_code_collateral                   int         = NULL out, --collateral.code
    @o_fecha_proceso                     varchar(25) = NULL out
)as

declare @w_sp_name                      varchar(30),
        @w_error                        int,
        @w_filial                       tinyint,
        @w_sucursal                     smallint,
        @w_custodia                     int,
        @w_tipo_cust                    varchar(64),
        @w_oficial                      smallint,
        @w_nombre                       varchar(64),
		@w_p_p_apellido					varchar(32),
		@w_p_s_apellido 				varchar(16),	
		@w_en_nombre					varchar(16)	

select @w_sp_name = 'sp_api_collateral_customers'
SELECT @w_error = 0



/* ************************************* */
/* VALIDACIÓN DEL SERVICIO               */
/* ************************************* */

/*
validacion que la aplicacion exista mediante el API key que se enuentre registrado
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

SELECT @w_fecha_proceso                = GETDATE()*/

/* ************************************* */
/* OPERACIONES                           */
/* ************************************* */

/* Descripción: Consulta los clientes asociados a una garantía.
 * Operación: [GET] - /collateral/{collateralId}/collateral-customers
 */
if @i_operacion = 'Q'
begin
    if @i_collateralId is null
    begin
        select @w_error = 100000001 -- tabla cobis..cl_errores
        goto CIERRE
    end
	 select @w_filial                    = cu_filial,
           @w_sucursal                  = cu_sucursal,
           @w_custodia                  = cu_custodia,
           @w_tipo_cust                 = cu_tipo
    from cob_custodia..cu_custodia
    where cu_codigo_externo = @i_collateralId
    
    if @@rowcount = 0
    begin
        select @w_error = 141215
        goto CIERRE
    end
	
	exec @w_error = cob_custodia..sp_cliente_garantia
         @s_ssn                         = @s_ssn,
         @s_date                        = @s_date,
         @s_user                        = @s_user,
         @s_term                        = @s_term,
         @s_ofi                         = @s_ofi,
         @t_rty                         = @t_rty,
         @t_trn                         = 19044,
         @t_debug                       = @t_debug,
         @t_file                        = @t_file,
         @t_from                        = @t_from,
         @i_operacion                   = 'S',
         @i_filial                      = @w_filial,
         @i_sucursal                    = @w_sucursal,
         @i_custodia                    = @w_custodia,
         @i_tipo_cust                   = @w_tipo_cust,
		 @i_modo						= 0
	
	if @w_error = 0
	begin
        select @w_error = @w_error
        goto CIERRE
    end
end

/* Descripción: Asociación de un cliente a una garantía.
 * Operación: [POST] - /collateral/{collateralId}/collateral-customers
 */

if @i_operacion = 'I'
begin
    /*Valida la obligatoriedad de los filtros*/
    if (@i_collateralId is null or @i_customerCode is null)
    begin
        select @w_error = 100000001 -- tabla cobis..cl_errores
        goto CIERRE
    end

    select @w_filial                    = cu_filial,
           @w_sucursal                  = cu_sucursal,
           @w_custodia                  = cu_custodia,
           @w_tipo_cust                 = cu_tipo
    from cob_custodia..cu_custodia
    where cu_codigo_externo = @i_collateralId

    if @@rowcount = 0
    begin
        select @w_error = 141215
        goto CIERRE
    end
	
	select @w_oficial                   = en_oficial,
           @w_p_p_apellido              = p_p_apellido,
		   @w_p_s_apellido				= p_s_apellido,
			@w_en_nombre				= en_nombre
    from cobis..cl_ente
    where en_ente = @i_customerCode

    if @@rowcount = 0
    begin
        select @w_error = 2101152
        goto CIERRE
    end
	
	if @w_p_p_apellido is null 
		select @w_p_p_apellido = ''
	if @w_p_s_apellido is null 
		select @w_p_s_apellido = ''
	if @w_en_nombre is null 
		select @w_en_nombre = ''
	
	select @w_nombre = (@w_p_p_apellido+ ' ' + @w_p_s_apellido + ' ' + @w_en_nombre)

    exec @w_error = cob_custodia..sp_cliente_garantia
         @s_ssn                         = @s_ssn,
         @s_date                        = @s_date,
         @s_user                        = @s_user,
         @s_term                        = @s_term,
         @s_ofi                         = @s_ofi,
         @t_rty                         = @t_rty,
         @t_trn                         = 19040,
         @t_debug                       = @t_debug,
         @t_file                        = @t_file,
         @t_from                        = @t_from,
         @i_operacion                   = 'I',
         @i_filial                      = @w_filial,
         @i_sucursal                    = @w_sucursal,
         @i_custodia                    = @w_custodia,
         @i_tipo_cust                   = @w_tipo_cust,
         @i_ente                        = @i_customerCode,
         @i_principal                   = 'N',
         @i_oficial                     = @w_oficial,
         @i_nombre                      = @w_nombre

    if @w_error = 0
    begin
        select @w_error = @w_error
        goto CIERRE
    end
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
Select @o_fecha_proceso = convert(varchar(10), fp_fecha,103) -- +' '+ convert(varchar(10), fp_fecha,108)
from cobis..ba_fecha_proceso

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

return 0
go
