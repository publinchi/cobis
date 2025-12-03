USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_api_loans_rejecting')
   drop proc sp_api_loans_rejecting
GO


CREATE PROCEDURE sp_api_loans_rejecting
/************************************************************************************/
/*  Archivo:            spLoansRejecting                                            */
/*  Stored procedure:   sp_api_loans_rejecting                                      */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Luis Ponce                                                  */
/*  Fecha de creacion:  23/SEP/2020                                                 */
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
/*  la Anulacion de Operaciones de Cartera                                          */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  23/SEP/2020       Luis Ponce              Emision Inicial                       */
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
@w_sp_name                  VARCHAR(32),
@w_estado                   VARCHAR(64),
@w_toperacion               VARCHAR(10),
@w_estado_ini               VARCHAR(64),
@w_op_estado                INT,
@w_est_anulado              TINYINT,
@w_es_descripcion           descripcion,
@w_op_operacion             INT



SELECT @w_sp_name = 'sp_api_loans_rejecting'

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

   POST /loans/{loanNumber} ----????????????????????????????????????????????????????????
      --> @i_operacion = 'I' --> sp_cambio_estado_op_ext
      -->(Realiza el cambio de estado a Anulado)

**********************************************************************************/


IF @i_operacion = 'I'
BEGIN
   
   --- ESTADOS DE CARTERA 
   exec @w_error  = sp_estados_cca
   @o_est_anulado = @w_est_anulado OUT
   
   if @w_error <> 0
      GOTO ERROR
   
   --Verificar si el cambio del estado actual al estado final es permitido según la parametrización:   
   
   --Estado Actual
   SELECT @w_toperacion = op_toperacion,
          @w_op_estado  = op_estado
   FROM ca_operacion
   WHERE op_banco = @i_banco
   
   
   IF EXISTS (SELECT 1
              FROM ca_estados_man
              WHERE em_toperacion = @w_toperacion
                AND em_tipo_cambio = 'M'
                AND em_estado_ini  = @w_op_estado
                AND em_estado_fin  = @w_est_anulado)
   BEGIN
   
      --SELECT @w_es_descripcion = es_descripcion FROM ca_estado WHERE es_codigo = @w_est_anulado
   
      EXEC @w_error = cob_cartera..sp_cambio_estado_op_ext
           @s_user       = @s_user,
           @s_term       = @s_term,
           @s_date       = @s_date,
           @s_ofi        =  @s_ofi,      
           @i_banco      = @i_banco,
           @i_estado_fin = @w_est_anulado --@w_es_descripcion --@w_est_anulado
     --      @t_trn        = 7135
      
      IF @w_error <> 0
         GOTO ERROR
   END
   ELSE
   BEGIN
      SELECT @w_error = 1912122  --El cambio de estado no esta parametrizado
      GOTO ERROR
   END
END

return 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@s_culture = @s_culture, 
@i_num     = @w_error

return @w_error
go
