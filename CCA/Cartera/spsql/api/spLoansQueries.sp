USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_api_loans_queries')
   drop proc sp_api_loans_queries
GO


CREATE PROCEDURE sp_api_loans_queries
/************************************************************************************/
/*  Archivo:            spLoansQueries.sp                                           */
/*  Stored procedure:   sp_api_loans_queries                                        */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Luis Ponce                                                  */
/*  Fecha de creacion:  05/MAY/2020                                                 */
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
/*  Consulta de las Operaciones de un cliente y los Datos de una Operacion concreta */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  05/MAY/2020       Luis Ponce              Emision Inicial                       */
/************************************************************************************/
(
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_date              datetime    = null,
   @s_ofi               smallint    = NULL,
   @s_culture           varchar(10) = 'NEUTRAL', --Estandarizacion API   
   @i_banco             cuenta      = NULL,
   @i_op_operacion      INT         = NULL,
   @i_operacion         CHAR(1)     = NULL,
   @i_tramite           int         = null,
   @i_cliente           int         = null,
   @i_grupo             int         = null,
   @i_oficina           smallint    = null,
   @i_moneda            tinyint     = null,
   @i_oficial           int         = null,
   @i_fecha_ini         datetime    = null,
   @i_toperacion        catalogo    = null,
   @i_estado            descripcion = null,
   @i_migrada           cuenta      = null,
   @i_siguiente         int         = 0,
   @i_formato_fecha     int         = null,
   @i_condicion_est     tinyint     = null,
   @i_num_documento     varchar(30) = NULL,
   @i_web               char(1)     = 'N',
   @i_grupal            char(1)     = 'N',
   @i_categoria         int         = 0,
   
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
@w_op_operacion             INT,
@w_sp_name                  VARCHAR(32)


SELECT @w_sp_name = 'sp_api_loans_queries'


/* ******************** */
/* INTERNACIONALIZACION */
/* ******************** */
exec cobis..sp_ad_establece_cultura
    @o_culture = @s_culture out

/*****************************************************
--LPO OPEN API:

GET /loans/customers/{customerId} 
   --> @i_operacion = 'A' --> sp_buscar_operaciones
   (Busca el Listado de Operaciones de un Cliente)
******************************************************/

IF @i_operacion = 'A' 
BEGIN
   
   EXEC @w_error = sp_buscar_operaciones
   @s_user            =    @s_user         ,
   @i_banco           =    @i_banco        ,
   @i_tramite         =    @i_tramite      ,
   @i_cliente         =    @i_cliente      ,
   @i_grupo           =    @i_grupo        ,
   @i_oficina         =    @i_oficina      ,
   @i_moneda          =    @i_moneda       ,
   @i_oficial         =    @i_oficial      ,
   @i_fecha_ini       =    @i_fecha_ini    ,
   @i_toperacion      =    @i_toperacion   ,
   @i_estado          =    @i_estado       ,
   @i_migrada         =    @i_migrada      ,
   @i_siguiente       =    @i_siguiente    ,
   @i_formato_fecha   =    @i_formato_fecha,
   @i_condicion_est   =    @i_condicion_est,
   @i_num_documento   =    @i_num_documento,
   @i_web             =    @i_web          ,
   @i_grupal          =    @i_grupal       ,
   @i_categoria       =    @i_categoria
         
   IF @w_error <> 0
      GOTO ERROR
      
END --FIN @i_operacion = 'A'

/*********************************************************************************
--LPO OPEN API:

   GET /loans/{loanId}
      --> @i_operacion = 'Q' --> sp_qr_operacion       
      (Información Básica de una Operaciones concreta a partir del op_operacion)
   GET /loans/{loanNumber}
      --> @i_operacion = 'Q' --> sp_qr_operacion       
      -->(Información Básica de una Operaciones concreta a partir del op_banco)
**********************************************************************************/

IF @i_operacion = 'Q' 
BEGIN
   
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
   
   EXEC @w_error = sp_qr_operacion
   @s_user                  = @s_user,
   @s_term                  = @s_term,
   @s_date                  = @s_date,
   @s_ofi                   = @s_ofi,
   @i_banco                 = @i_banco,
   @i_formato_fecha         = @i_formato_fecha--,
--   @i_operacion             = @i_operacion             
   
   IF @w_error <> 0
      GOTO ERROR
         
END --@i_operacion = 'Q' FIN

return 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@s_culture = @s_culture, 
@i_num     = @w_error

return @w_error
go
