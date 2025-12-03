USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_api_loans_amortizations')
   drop proc sp_api_loans_amortizations
GO


CREATE PROCEDURE sp_api_loans_amortizations
/************************************************************************************/
/*  Archivo:            spLoansAmortizations.sp                                     */
/*  Stored procedure:   sp_api_loans_amortizations                                  */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Luis Ponce                                                  */
/*  Fecha de creacion:  07/MAY/2020                                                 */
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
/*  Desembolso y Liquidación en un solo paso, o Registro Desembolso, o Liquidacion  */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  07/MAY/2020       Luis Ponce              Emision Inicial                       */
/************************************************************************************/
(
   @s_sesn                 int          = null,
   @s_date                 DATETIME     = null,
   @s_user                 login        = null,
   @s_culture              varchar(10)  = 'NEUTRAL',
   @s_term                 varchar(30)  = null,
   @s_ssn                  int          = null,
   @s_org                  char(1)      = null,
   @s_srv                  varchar (30) = null,
   @s_ofi                  smallint     = null,
   @s_lsrv                 varchar (30) = null,
   @s_rol                  int          = null,
   @i_operacion            char(1),
   @i_op_operacion         INT          = NULL,
   @i_banco                cuenta       = NULL,
   
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

DECLARE
@w_sp_name        varchar(24),
@w_error          INT,
@w_op_operacion   INT

SELECT @w_sp_name = 'sp_api_loans_amortizations'



/*****************************************************
--LPO OPEN API:

sp_api_loans_amortizations
   -->> GET /loans/{loanId}/loan-amortization
   --> @i_operacion = 'Q' --> sp_qr_table_amortiza_web --(Consulta de la tabla de Amortizacion de un prestamo)

******************************************************/

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


IF @i_operacion = 'Q' 
BEGIN
   
   execute @w_error  = cob_cartera..sp_qr_table_amortiza_web
   @i_banco   = @i_banco,
   @i_opcion  = 'T'
   
   IF @w_error <> 0
      goto ERROR
   
END --FIN @i_operacion = 'Q'

return 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@s_culture = @s_culture, 
@i_num     = @w_error

return @w_error
go
