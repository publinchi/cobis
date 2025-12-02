use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_api_backvalue_loan')
   drop proc sp_api_backvalue_loan
go

create procedure sp_api_backvalue_loan
/************************************************************************************/
/*  Archivo:            sp_api_backvalue_loan.sp                                    */
/*  Stored procedure:   sp_api_backvalue_loan                                       */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Sandro Vallejo                                              */
/*  Fecha de creacion:  18/SEP/2020                                                 */
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
/*  Aplicar Fecha Valor a una Operacion                                             */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/************************************************************************************/
(
   @s_user                             login         = null,
   @s_term                             descripcion   = null,
   @s_date                             datetime      = null,
   @s_ofi                              smallint      = null,
   @s_culture                          varchar(10)   = 'NEUTRAL',   --Estandarizacion API   
   @i_op_operacion                     INT           = NULL,
   @i_banco                            cuenta        = null,
   
   @i_fecha_valor                      datetime      = null,
   -- parametros de cabecera
   @i_x_api_key                        varchar(40)   = NULL,        --headers.x_api_key
   @i_authorization                    varchar(100)  = NULL,        --headers.Authorization
   @i_x_request_id                     varchar(36)   = NULL,        --headers.x-request-id
   @i_x_financial_id                   varchar(25)   = NULL,        --headers.x-financial-id
   @i_x_end_user_login                 varchar(25)   = NULL,        --headers.x-end-user-login
   @i_x_end_user_request_date_time     varchar(25)   = NULL,        --headers.x-end-user-request-date-time
   @i_x_end_user_terminal              varchar(25)   = NULL,        --headers.x-end-user-terminal
   @i_x_end_user_last_logged_date_time varchar(25)   = NULL,        --headers.x-end-user-last-logged-date-time
   @i_x_jws_signature                  varchar(25)   = NULL,        --headers.x-jws-signature
   @i_x_reverse                        varchar(25)   = NULL,        --headers.x-reverse
   @i_x_requestId_to_reverse           varchar(25)   = NULL         --headers.x-requestId-to-reverse
)
as

declare
@w_error   int,
@w_sp_name varchar(24),
@w_op_operacion INT


-- INICIALIZAR VARIABLES
select @w_sp_name = 'sp_api_backvalue_loan'


IF @i_op_operacion IS NOT NULL
      SELECT @i_banco = op_banco FROM cob_cartera..ca_operacion WHERE op_operacion = @i_op_operacion

IF @i_banco IS NOT NULL
      SELECT @i_op_operacion = op_operacion FROM cob_cartera..ca_operacion WHERE op_banco = @i_banco

--Valida que la operacion no sea nula
IF @i_op_operacion IS NULL AND @i_banco IS NULL
BEGIN      
   SELECT @w_error = 725054 --'No existe la operación'
   GOTO ERROR
END

--Validacion existencia de la operacion
SELECT @w_op_operacion = op_operacion FROM cob_cartera..ca_operacion WHERE op_banco = @i_banco
IF @w_op_operacion IS NULL
BEGIN
   SELECT @w_error = 725054 --'No existe la operación'
   GOTO ERROR   
END


-- INTERNACIONALIZACION 
exec cobis..sp_ad_establece_cultura
     @o_culture = @s_culture out

-- OPEN API:
-- GET /loans/{loanNumber}
   --> @i_operacion   = 'F' --> sp_fecha_valor
   --> @i_fecha_valor = fecha valor de la transaccion      
   -->(Aplicar fecha valor de una Operaciones concreta a partir del op_banco y la fecha valor)

exec @w_error  = sp_fecha_valor 
@i_en_linea    = 'N',
@i_banco       = @i_banco,
@i_fecha_valor = @i_fecha_valor,
@i_operacion   = 'F'

if @w_error <> 0
   goto ERROR

return 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@s_culture = @s_culture, 
@i_num     = @w_error

return @w_error
go
