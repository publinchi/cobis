USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_api_loans_extentions')
   drop proc sp_api_loans_extentions
GO


CREATE PROCEDURE sp_api_loans_extentions
/************************************************************************************/
/*  Archivo:            spLoansExtentions.sp                                        */
/*  Stored procedure:   sp_api_loans_extentions                                     */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Luis Ponce                                                  */
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
/*  la Prorroga de Cuotas de Operaciones de Cartera                                 */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  18/SEP/2020       Luis Ponce              Emision Inicial                       */
/************************************************************************************/
(
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_date              datetime    = null,
   @s_ofi               smallint    = NULL,
   @s_srv               varchar (30) = null,
   @s_lsrv              varchar (30) = null,
   @s_org               char(1)      = null,
   @t_trn               int          = null,   
   @s_ssn               int          = null,
   @s_sesn              int          = NULL,   
   @s_culture           varchar(10) = 'NEUTRAL', --Estandarizacion API   
   @i_banco             cuenta      = NULL,
   @i_op_operacion      INT         = NULL,
   @i_operacion         CHAR(1)     = NULL,
   @i_formato_fecha     int         = null,
   @i_cuota             smallint     = null,
   @i_valor_calculado   money        = null,
   @i_fecha_vencimiento datetime     = null,
   @i_fecha_max_prorroga datetime     = null,
   @i_fecha_prorroga    datetime     = null,
   
   
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
@w_error                    INT,
@w_fmax_prorroga            DATETIME,
@w_min_dividendo            INT,
@w_sp_name                  VARCHAR(32),
@w_op_operacion             INT


SELECT @w_sp_name = 'sp_api_loans_extentions'

--LPO Si @i_op_operacion viene con valor se busca el op_banco para consultar la operacion,
--caso contrario se consulta con el @i_banco que viene:
   
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



/* ******************** */
/* INTERNACIONALIZACION */
/* ******************** */
exec cobis..sp_ad_establece_cultura
    @o_culture = @s_culture out

/*********************************************************************************
--LPO OPEN API:

   GET /loans/{loanId} ----??????????????????????????????????????????????????????????????????????????
      --> @i_operacion = 'Q' --> sp_prorroga_cuota (@i_operacion='Q')
      (Información de la cuota vigente y la siguiente No vigente para prorrogar)
   GET /loans/{loanNumber} ----??????????????????????????????????????????????????????????????????????????
      --> @i_operacion = 'S' --> sp_prorroga_cuota (@i_operacion='I', @i_modo='A')
      -->(Muestra una Simulacion de como quedarian las cuotas con la prorroga)
   POST /loans/{loanNumber} ----??????????????????????????????????????????????????????????????????????????
      --> @i_operacion = 'I' --> sp_prorroga_cuota (@i_operacion='I', @i_modo='B')
      -->(Realiza efectivamente la prorroga)
           
**********************************************************************************/



IF @i_operacion = 'Q' 
BEGIN
   
   
   EXEC @w_error = cob_cartera..sp_prorroga_cuota
   @i_operacion             = 'Q',
   @s_user                  = @s_user,
   @s_term                  = @s_term,
   @s_date                  = @s_date,
   @s_ofi                   = @s_ofi,
   @s_srv                   = @s_srv,
   @s_ssn                   = @s_ssn,
   @s_lsrv                  = @s_lsrv,
   @s_sesn                  = @s_sesn,
   @s_org                   = @s_org,
   @i_banco                 = @i_banco,
   @i_fecha                 = @s_date,
   @i_formato_fecha         = @i_formato_fecha, --103,
   @i_cuota                 = 0
    --@t_trn=7235,
    --@s_culture='es_EC'
   
   IF @w_error <> 0
      GOTO ERROR

END --@i_operacion = 'Q' FIN


IF @i_operacion IN ('S', 'I')
BEGIN
   --CALCULO PROXIMA CUOTA
   select
   @w_min_dividendo = isnull(min(di_dividendo),0)
   from   ca_dividendo, ca_operacion
   where  di_operacion = op_operacion
     AND  op_banco     = @i_banco
     AND  di_estado    = 1
        
   --LPO. Obtener la fecha de vencimiento del primer dividendo no vigente menos un dia
   select @w_fmax_prorroga =  dateadd(dd,-1,di_fecha_ven)
   from ca_dividendo, ca_operacion
   where  di_operacion = op_operacion
     AND op_banco      = @i_banco
     AND di_dividendo  = @w_min_dividendo + 1
        
   --Validacion fecha maxima de prorroga
   IF @w_fmax_prorroga < @i_fecha_prorroga
   BEGIN
      SELECT @w_error =  708217
      GOTO ERROR
   END
END


IF @i_operacion = 'S'
BEGIN
   
   
   EXEC @w_error = cob_cartera..sp_prorroga_cuota
   @i_operacion             = 'I',
   @i_modo                  = 'A',
   @s_user                  = @s_user,
   @s_term                  = @s_term,
   @s_date                  = @s_date,
   @s_ofi                   = @s_ofi,
   @s_srv                   = @s_srv,
   @s_ssn                   = @s_ssn,
   @s_lsrv                  = @s_lsrv,
   @s_sesn                  = @s_sesn,
   @s_org                   = @s_org,
   @i_banco                 = @i_banco,
   @i_fecha                 = @s_date,
   @i_formato_fecha         = @i_formato_fecha, --103,
   @i_cuota                 = @i_cuota, --1
   @i_fecha_vencimiento     = @i_fecha_vencimiento, --fecha ven cuota
   @i_fecha_max_prorroga    = @w_fmax_prorroga, --fecha de vencimiento del primer dividendo no vigente menos 1 dia
   @i_fecha_prorroga        = @i_fecha_prorroga --se digita por el usuario
   --@t_trn=7232,
   --@s_culture='es_EC'
      
   IF @w_error <> 0
      GOTO ERROR
      
      
END --@i_operacion = 'S' FIN



IF @i_operacion = 'I'
BEGIN      
   
   EXEC @w_error = cob_cartera..sp_prorroga_cuota
   @i_operacion             = 'I',
   @i_modo                  = 'B',
   @s_user                  = @s_user,
   @s_term                  = @s_term,
   @s_date                  = @s_date,
   @s_ofi                   = @s_ofi,
   @s_srv                   = @s_srv,
   @s_ssn                   = @s_ssn,
   @s_lsrv                  = @s_lsrv,
   @s_sesn                  = @s_sesn,
   @s_org                   = @s_org,
   @i_banco                 = @i_banco,
   @i_fecha                 = @s_date,
   @i_formato_fecha         = @i_formato_fecha, --103,
   @i_cuota                 = @i_cuota, --1
   @i_fecha_vencimiento     = @i_fecha_vencimiento, --fecha ven cuota
   @i_fecha_max_prorroga    = @w_fmax_prorroga, --fecha de vencimiento del primer dividendo no vigente menos 1 dia
   @i_fecha_prorroga        = @i_fecha_prorroga, --se digita por el usuario
   @i_valor_calculado       = 0
   --@t_trn=7232,
   --@s_culture='es_EC'
   
   IF @w_error <> 0
      GOTO ERROR
      
      
END --@i_operacion = 'I' FIN


return 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@s_culture = @s_culture, 
@i_num     = @w_error

return @w_error
go
