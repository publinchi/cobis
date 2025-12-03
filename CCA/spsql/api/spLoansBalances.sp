use cob_cartera
go
/************************************************************************************/
/*  Archivo:            spLoansBalances.sp             			            */
/*  Stored procedure:   sp_api_loans_balances                                       */
/*  Base de datos:      cob_cartera                     		            */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Luis Castellanos                                            */
/*  Fecha de creacion:  06/MAY/2020                                                 */
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
/*  Consulta de Balance y datos del pr¢ximo pago                                    */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  11/MAY/2020       Luis Castellanos        Emision Inicial                       */
/************************************************************************************/


if exists (select 1 from sysobjects where name = 'sp_api_loans_balances')
  drop proc sp_api_loans_balances
go
create proc sp_api_loans_balances
   @s_user                 char(30) 	= null,
   @s_term                 char(30) 	= null,
   @s_ofi                  int 	 	    = null,
   @s_culture              varchar(10)  = 'NEUTRAL',   --Estandarizacion API   --LPO Nuevo

   -- parametros de cabecera
   @i_Authorization                    varchar(100)    = NULL,     --headers.Authorization
   @i_x_request_id                     varchar(36)     = NULL,     --headers.x-request-id
   @i_x_financial_id                   varchar(25)     = NULL,     --headers.x-financial-id
   @i_x_end_user_login                 varchar(25)     = NULL,     --headers.x-end-user-login
   @i_x_end_user_request_date_time     varchar(25)     = NULL,     --headers.x-end-user-request-date-time
   @i_x_end_user_terminal              varchar(25)     = NULL,     --headers.x-end-user-terminal
   @i_x_end_user_last_logged_date_time varchar(25)     = NULL,     --headers.x-end-user-last-logged-date-time
   @i_x_jws_signature                  varchar(25)     = NULL,     --headers.x-jws-signature
   @i_x_reverse			       varchar(25)     = NULL,     --headers.x-reverse
   @i_x_ssn_to_reverse		       varchar(25)     = NULL,     --headers.x-requestId-to-reverse

   -- parametros de los servicios
   @i_operacion            char(1)  	= null,
   @i_operacionca          int      	= null,
   @i_banco                varchar(16)	= null,
   @i_formato_fecha        int    	 	= 101,
   @i_tipo_cobro           char(1)  	= null,
   @i_detalle_rubro	   char(1)		= 'N',
   @o_msg_matriz           varchar(64) 	= NULL out 
as

declare @w_sp_name              varchar(32),
        @w_return               INT,
        @w_op_operacion         INT
        

-- INICIALIZACION DE VARIABLES
select  @w_sp_name       = 'sp_api_loans_balances'

IF @i_operacionca IS NOT NULL
      SELECT @i_banco = op_banco FROM cob_cartera..ca_operacion WHERE op_operacion = @i_operacionca

IF @i_banco IS NOT NULL
      SELECT @i_operacionca = op_operacion FROM cob_cartera..ca_operacion WHERE op_banco = @i_banco

--Valida que la operacion no sea nula
IF @i_operacionca IS NULL AND @i_banco IS NULL
BEGIN      
   SELECT @w_return = 725054 --'No existe la operación'
   GOTO ERROR
END


--Validacion existencia de la operacion
SELECT @w_op_operacion = op_operacion FROM cob_cartera..ca_operacion WHERE op_banco = @i_banco
IF @w_op_operacion IS NULL
BEGIN
   SELECT @w_return = 725054 --'No existe la operación'
   GOTO ERROR   
END


-- INTERNACIONALIZACION 
exec cobis..sp_ad_establece_cultura
     @o_culture = @s_culture out




if @i_operacion = 'S'
begin

   select @i_tipo_cobro = isnull(@i_tipo_cobro, op_tipo_cobro)
     from cob_cartera..ca_operacion
    where op_banco = @i_banco

   exec @w_return = sp_saldo_cartera
        @s_user          = @s_user,
        @s_term          = @s_term,
        @s_ofi           = @s_ofi,
        @i_operacion     = 'S',
        @i_operacionca   = null,
        @i_banco         = @i_banco,
        @i_formato_fecha = @i_formato_fecha,
        @i_tipo_cobro    = @i_tipo_cobro,
        @i_detalle_rubro = @i_detalle_rubro,
        @o_msg_matriz    = @o_msg_matriz out 
        
   if @w_return <> 0 begin
      select @o_msg_matriz = 'ERROR NO SE OBTUVO LOS SALDOS DEL PRESTAMO'
      goto ERROR
   end
end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@s_culture = @s_culture, 
@i_num     = @w_return

return @w_return
go

/*
declare @o_msg varchar(64)

exec sp_api_loans_balances
        @s_user          = 'lcastell',
        @s_term          = 'termx',
        @s_ofi           = 1,
        @i_operacion     = 'S',
        @i_operacionca   = null,
        @i_banco         = '0001004043',
        @i_formato_fecha = 101,
        @i_tipo_cobro    = 'P',
	@i_detalle_rubro = 'S',
	@o_msg_matriz    = @o_msg out 

select @o_msg
*/
