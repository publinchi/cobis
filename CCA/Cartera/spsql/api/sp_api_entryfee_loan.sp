use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_api_entryfee_loan')
   drop proc sp_api_entryfee_loan
go

create procedure sp_api_entryfee_loan
/************************************************************************************/
/*  Archivo:            sp_api_entryfee_loan.sp                                     */
/*  Stored procedure:   sp_api_entryfee_loan                                        */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Sandro Vallejo                                              */
/*  Fecha de creacion:  22/SEP/2020                                                 */
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
/*  Ingresar un rubro tipo multa-otro cargo a una operacion                         */
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
   @i_operacion                        char(1)       = 'I',
   @i_concepto                         varchar(10)   = null,
   @i_monto                            money         = null,
   @i_div_desde                        int           = null,
   @i_div_hasta                        int           = null,
   @i_comentario                       varchar(64)   = null,
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
@w_error      int,
@w_toperacion varchar(10),
@w_moneda     int,
@w_estado     tinyint,
@w_sp_name    varchar(24),
@w_op_operacion INT


-- INICIALIZAR VARIABLES
select @w_sp_name = 'sp_api_entryfee_loan'


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
   --> @i_operacion   = 'I' --> sp_otros_cargos
   --> @i_concepto    = rubro multa/otro cargo,
   --> @i_monto       = monto del rubro,
   --> @i_div_desde   = dividendo desde el cual se ingresa la multa/otro cargo,
   --> @i_div_hasta   = dividendo hasta el cual se ingresa la multa/otro cargo, 
   --> @i_comentario  = comentario u observacion,
   	-->(Ingresar Multa/Otro Cargo a una Operaciones concreta a partir del op_banco,el tipo operacion, moneda, rubro, monto, dividendo desde y dividendo hasta)

-- VALIDAR QUE LA OPERACION EXISTA
select 
@w_toperacion = op_toperacion,
@w_moneda     = op_moneda,
@w_estado     = op_estado
from   ca_operacion
where  op_banco = @i_banco

if @@rowcount = 0
begin
   select @w_error = 701025 -- No existe operacion
   goto ERROR               
end   

-- VALIDAR EL ESTADO DE LA OPERACION PERMITA EL INGRESO DE LA MULTA/OTRO CARGO
if not exists (select 1     
               from   ca_estado 
               where  es_codigo = @w_estado
               and    es_procesa = 'S')
begin
   select @w_error = 710563
   goto ERROR               
end   

-- INGRESO DEL RUBRO MULTA/OTRO CARGO
if @i_operacion = 'I'
begin
   -- VALIDAR QUE EL MONTO INGRESADO SEA MAYOR A 0
   if @i_monto < 0
   begin
      select @w_error = 710006
      goto ERROR               
   end   

   -- CHEQUEA QUE EXISTA EL RUBRO
   if not exists (select 1
                  from   ca_rubro,ca_concepto
                  where  ru_toperacion = @w_toperacion
                  and    ru_moneda     = @w_moneda
                  and    ru_concepto   = @i_concepto
                  and    ru_fpago      = 'M')
   begin
      select @w_error = 710082
      goto ERROR               
   end   

   -- VALIDACION DE VARIABLES
   if @s_user is null
      select @s_user = 'API'
      
   if @s_ofi is null    
      select @s_ofi = pa_smallint
      from   cobis..cl_parametro
      where  pa_nemonico = 'OFICEN'
      and    pa_producto = 'CCA'
   
   if @s_term is null
      select @s_term = 'API'
       
   if @s_date is null    
      select @s_date = fc_fecha_cierre
      from   cobis..ba_fecha_cierre
      where  fc_producto = 7
      
   -- EJECUTAR EL PROCESO DE INGRESO DE LA MULTA/OTRO CARGO
   exec @w_error  = sp_otros_cargos 
   @s_user        = @s_user,
   @s_ofi         = @s_ofi,
   @s_term        = @s_term,
   @s_date        = @s_date,
   @i_banco       = @i_banco,
   @i_operacion   = 'I',
   @i_toperacion  = @w_toperacion,
   @i_moneda      = @w_moneda,
   @i_concepto    = @i_concepto,
   @i_monto       = @i_monto,
   @i_div_desde   = @i_div_desde,
   @i_div_hasta   = @i_div_hasta,
   @i_comentario  = @i_comentario

   if @w_error <> 0
      goto ERROR
      
   --LPO CDIG API REQUIERE QUE SE DEVUELVA EL CODIGO DEL ENTE CREADO, POR ESTANDAR, EN ESTE CASO EL RUBRO CREADO, INICIO
   
   SELECT ro_concepto
   FROM ca_rubro_op
   WHERE ro_operacion =  @i_op_operacion
     AND ro_concepto  =  @i_concepto
   
   --LPO CDIG API REQUIERE QUE SE DEVUELVA EL CODIGO DEL ENTE CREADO, POR ESTANDAR, EN ESTE CASO EL RUBRO CREADO, FIN
   
end

-- OPEN API:
-- GET /loans/{loanNumber}
   --> @i_operacion   = 'F' --> sp_otros_cargos
   -->(Consulta los posibles rubros Multa/Otro Cargo para una Operaciones concreta a partir del op_banco)


-- CONSULTA LOS RUBROS TIPO MULTA/OTRO CARGA PARA LA OPERACION
if @i_operacion = 'F'
begin
   -- EJECUTAR EL PROCESO DE INGRESO DE LA MULTA/OTRO CARGO
   exec @w_error  = sp_otros_cargos 
   @i_banco       = @i_banco,
   @i_operacion   = 'F'

   if @w_error <> 0
      goto ERROR
end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@s_culture = @s_culture, 
@i_num     = @w_error

return @w_error
go
