use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_api_loans_partialdisbursement')
   drop proc sp_api_loans_partialdisbursement
go

create procedure sp_api_loans_partialdisbursement
/************************************************************************************/
/*  Archivo:            sp_api_loans_partialdisbursement.sp                         */
/*  Stored procedure:   sp_api_loans_partialdisbursement                            */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Sandro Vallejo                                              */
/*  Fecha de creacion:  24/SEP/2020                                                 */
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
/*  Desembolso y Liquidacion (Desembolsos Parciales)                                */
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
   @i_producto                         varchar(10)   = null,
   @i_cuenta                           varchar(24)   = null,
   @i_monto_ds                         money         = null,
   @i_moneda_ds                        int           = null,
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
@w_error             int,
@w_sp_name           varchar(24),
@w_monto             money,
@w_monto_apr         money,
@w_moneda            int,
@w_operacionca       int,
@w_cp_pcobis         int,
@w_fecha_ult_proceso DATETIME,
@w_op_operacion      INT


-- INICIALIZAR VARIABLES
select @w_sp_name = 'sp_api_loans_partialdisbursement'

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

-- VALIDAR QUE LA OPERACION EXISTA
select 
@w_operacionca       = op_operacion,
@w_moneda            = op_moneda,
@w_monto             = op_monto,
@w_monto_apr         = op_monto_aprobado,
@w_fecha_ult_proceso = op_fecha_ult_proceso
from   ca_operacion
where  op_banco = @i_banco

if @@rowcount = 0
begin
   select @w_error = 725054 -- No existe operacion
   goto ERROR               
end   

-- VALIDAR QUE LA OPERACION TENGA DISPONIBLE PARA REALIZAR DESEMBOLSO PARCIAL
if @w_monto >= @w_monto_apr
begin
   select @w_error = 710021 -- El desembolso no puede exceder el monto aprobado
   goto ERROR               
end

-- OPEN API:
-- GET /loans/{loanNumber}
   --> @i_operacion   = 'C' --> 
   -->(Consulta los valores aprobado y desembolsado para una Operaciones concreta a partir del op_banco)

-- CONSULTA LOS VALORES APROBADO y DESEMBOLSADO DE UNA OPERACION
if @i_operacion = 'C'
begin
   select 'Moneda '             = @w_moneda,
          'Monto Aprobado '     = @w_monto_apr,
          'Monto Desembolsado ' = @w_monto

   return 0
end

-- OPEN API:
-- GET /loans/{loanNumber}
   --> @i_operacion   = 'I' --> 
   -->(Realiza la ejecución del desembolso parcial para una Operaciones concreta a partir del op_banco)

-- INGRESO DEL DESEMBOLSO PARCIAL
if @i_operacion = 'I'
begin
   select @w_cp_pcobis = 0,
          @i_monto_ds  = round(@i_monto_ds, 2)
   
   -- VALIDAR LA FORMA DE DESEMBOLSO Y MONEDA DE DESEMBOLSO
   select @w_cp_pcobis = isnull(cp_pcobis, 0)
   from   ca_producto
   where  cp_producto   = @i_producto
   and    cp_moneda     = @i_moneda_ds
   and    cp_desembolso = 'S'
   and    cp_estado     = 'V'
   
   if @@rowcount = 0
   begin
      select @w_error = 710416 -- Forma de Pago no definida en ca_producto
      goto ERROR
   end                  
   
   -- SI LA FORMA DE PAGOS ES DEBITO A CUENTAS VALIDAR EL INGRESO DE LA CUENTA
   if @w_cp_pcobis in (3,4) AND @i_cuenta is null
   begin
      select @w_error = 701043 -- La Cuenta no existe o no esta activa
      goto ERROR
   end                  

   -- VALIDAR QUE NO EXISTA OTROS DESEMBOLSOS PENDIENTES ANTERIORES A LA FECHA
   if exists (select 1 
              from   ca_desembolso
              where  dm_operacion = @w_operacionca
              and    dm_estado    = 'NA'
              and    dm_fecha    <= @w_fecha_ult_proceso)
   begin
      select @w_error = 710073 -- Fecha de desembolso fuera de rango
      goto ERROR
   end  

   -- VALIDAR MONTO DE DESEMBOLSO
   if isnull(@i_monto_ds,0) <= 0
   begin
      select @w_error = 710129 -- Monto de pago Cero
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


   -- ATOMICIDAD DE TRANSACCION
   BEGIN TRAN

   -- EJECUTAR EL INGRESO DE LA FORMA DE DESEMBOLSO
   exec @w_error  = sp_desembolso_parcial
   @s_culture           = @s_culture,   --Internacionalizacion
   @s_user              = @s_user,
   @s_term              = @s_term,
   @s_date              = @s_date,
   @s_ofi               = @s_ofi,
   @i_operacion         = 'I',
   @i_banco_real        = @i_banco,
   @i_banco_ficticio    = @i_banco,
   @i_producto          = @i_producto,
   @i_cuenta            = @i_cuenta,
   @i_monto_ds          = @i_monto_ds,
   @i_moneda_ds         = @i_moneda_ds,
   @i_moneda_op         = @w_moneda,
   @i_cotiz_ds          = 1,  --1.0,
   @i_cotiz_op          = 1,  --1.0,
   @i_tcotiz_ds         = 'V',
   @i_tcotiz_op         = 'V'
   
   if @w_error <> 0
      goto ERROR


   -- EJECUTAR EL INGRESO DE LA FORMA DE DESEMBOLSO
   exec @w_error  = sp_desembolso_parcial
   @s_culture           = @s_culture,   --Internacionalizacion
   @s_user              = @s_user,
   @s_term              = @s_term,
   @s_date              = @s_date,
   @s_ofi               = @s_ofi,
   @i_operacion         = 'L',
   @i_banco_real        = @i_banco,
   @i_banco_ficticio    = @i_banco,
   @i_moneda_op         = @w_moneda
   
   if @w_error <> 0
      goto ERROR   

   COMMIT TRAN
   

   --LPO CDIG API REQUIERE QUE SE DEVUELVA EL CODIGO DEL ENTE CREADO, POR ESTANDAR, EN ESTE CASO EL SECUENCIAL y DESEMBOLSO, INICIO
   
   SELECT dm_secuencial, dm_desembolso
   FROM ca_desembolso
   WHERE dm_operacion = @i_op_operacion
   
   --LPO CDIG API REQUIERE QUE SE DEVUELVA EL CODIGO DEL ENTE CREADO, POR ESTANDAR, EN ESTE CASO EL SECUENCIAL y DESEMBOLSO, FIN
   
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
