USE cob_cartera
GO
/************************************************************************************/
/*  Archivo:            spLoansPayments.sp                                          */
/*  Stored procedure:   sp_api_loans_payments                                       */
/*  Base de datos:      cob_cartera                                                 */
/*  Producto:           Cobis Open API                                              */
/*  Disenado por:       Luis Castellanos                                            */
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
/*  Ingreso de un Abono a una operacion de Cartera                                  */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  05/MAY/2020       Luis Castellanos        Emision Inicial                       */
/************************************************************************************/

if exists ( select 1 from sysobjects where name = 'sp_api_loans_payments' )
   drop proc sp_api_loans_payments
go

create proc sp_api_loans_payments
   @s_user                 login       = NULL,
   @s_term                 varchar(30) = NULL,
   @s_date                 datetime    = NULL,
   @s_sesn                 int         = NULL,
   @s_ssn                  int,
   @s_srv                  varchar(30),
   @s_ofi                  smallint    = NULL,
   @s_culture              varchar(10) = 'NEUTRAL', --Estandarizacion API

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
   @i_operacion            char(1)     = NULL,
   @i_banco                varchar(16) = NULL,
   @i_operacionca          int         = NULL,
   @i_secuencial           int         = 0,
   @i_beneficiario         varchar(64) = NULL,
   @i_fecha_vig            datetime    = NULL,
   @i_ejecutar             char(1)     = 'S',
   @i_retencion            smallint    = 0,
   @i_en_linea             char(1)     = 'S',
   @i_producto             varchar(10) = NULL,
   @i_monto_mpg            money       = 0,
   @i_cuenta               varchar(16) = NULL,
   @i_moneda               tinyint     = 0,
   @i_dividendo            smallint    = 0,
   @i_cheque               int         = null,
   @i_cod_banco            varchar(10) = null,
   @i_tipo_cobro           varchar(10) = null, 
   @i_tipo_reduccion       char(1)     = null,
   @i_tipo_aplicacion      char(1)     = null,
   @i_pago_ext             char(1)     = 'N',   
   @i_sec_desem_renova     int         = null,
   @i_pago_gar_grupal      char(1)     = 'N',
   @i_formato_fecha        int         = 101,
   @i_referencia_pr        varchar(64) = NULL,-- Por precancelacion grupal
   @i_valor_multa          money       = 0,
   @i_valida_sobrante      char(1)     = 'S',
   @i_simulado             char(1)     = 'N',  --Pago Simulado
   @i_condonacion          char(1)     = 'N',
   @i_rubro_condonar       varchar(10) = NULL, --Conceptos o rubros a condonar 
   @o_secuencial_ing       int         = NULL out,
   @o_msg_matriz           varchar(64) = NULL out  
   as
   declare
   @w_sp_name              varchar(64),
   @w_return               INT,
   @w_op_operacion         INT
   
   

/*  NOMBRE DEL SP Y FECHA DE HOY */
select  @w_sp_name = 'sp_api_payments'


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

   
   
if @i_operacion = 'I'
BEGIN

   --Validacion existencia de la moneda
   IF EXISTS (SELECT 1 FROM cobis..cl_tabla a, cobis..cl_catalogo b where a.codigo = b.tabla and a.tabla = 'cl_moneda' and b.codigo = @i_moneda)
      SELECT @i_moneda = @i_moneda
   ELSE
   BEGIN
      SELECT @w_return = 701069
      GOTO ERROR
   END
   
   --Validacion existencia de la forma de pago y moneda
   IF EXISTS (SELECT 1 FROM cob_cartera..ca_producto WHERE cp_producto = @i_producto AND cp_moneda = @i_moneda)
      SELECT @i_moneda = @i_moneda
   ELSE
   BEGIN  
      SELECT @w_return = 708188 --'La forma de pago no soportada para la moneda de transaccion'
      GOTO ERROR
   END
   
   exec @w_return = sp_pagos_trn
   @s_user             = @s_user,
   @s_term             = @s_term,
   @s_date             = @s_date,
   @s_sesn             = @s_sesn,
   @s_ssn              = @s_ssn,
   @s_srv              = @s_srv,
   @s_ofi              = @s_ofi,
   @i_operacion        = @i_operacion,
   @i_banco            = @i_banco,
   @i_operacionca      = @i_operacionca,
   @i_beneficiario     = @i_beneficiario,
   @i_fecha_vig        = @i_fecha_vig,
   @i_retencion        = @i_retencion,
   @i_producto         = @i_producto,
   @i_monto_mpg        = @i_monto_mpg,
   @i_cuenta           = @i_cuenta,
   @i_moneda           = @i_moneda,
   @i_dividendo        = @i_dividendo,
   @i_cheque           = @i_cheque,
   @i_cod_banco        = @i_cod_banco,
   @i_tipo_cobro       = @i_tipo_cobro,
   @i_tipo_reduccion   = @i_tipo_reduccion,
   @i_tipo_aplicacion  = @i_tipo_aplicacion,
   @i_pago_ext         = @i_pago_ext,
   @i_sec_desem_renova = @i_sec_desem_renova,
   @i_pago_gar_grupal  = @i_pago_gar_grupal,
   @i_formato_fecha    = @i_formato_fecha,
   @i_referencia_pr    = @i_referencia_pr,
   @i_valor_multa      = @i_valor_multa,
   @i_valida_sobrante  = @i_valida_sobrante,
   @i_simulado         = @i_simulado,
   @i_condonacion      = @i_condonacion,
   @i_rubro_condonar   = @i_rubro_condonar,
   @o_secuencial_ing   = @o_secuencial_ing out,
   @o_msg_matriz       = @o_msg_matriz out

   if @w_return <> 0 begin
      GOTO ERROR
   end

   --LPO CDIG API REQUIERE QUE SE DEVUELVA EL CODIGO DEL ENTE CREADO, POR ESTANDAR, EN ESTE CASO EL SECUENCIAL, INICIO
   
   SELECT ab_secuencial_ing
   FROM ca_abono
   WHERE ab_operacion = @i_operacionca
   
   --LPO CDIG API REQUIERE QUE SE DEVUELVA EL CODIGO DEL ENTE CREADO, POR ESTANDAR, EN ESTE CASO EL SECUENCIAL, FIN
   
end

if @i_operacion = 'A'
BEGIN
      
   if @i_secuencial is null select @i_secuencial = 0
   
   
   exec @w_return = sp_prorrateo_pago_grp
   @s_user             = @s_user,
   @s_date             = @s_date,
   @i_operacionca      = @i_operacionca,
   @i_formato_fecha    = @i_formato_fecha,
   @i_secuencial_ing   = @i_secuencial,
   @i_operacion        = 'A',
   @i_sec_detpago      = 0

   if @w_return <> 0 begin
      GOTO ERROR
   end

end

RETURN 0

ERROR:
   exec cobis..sp_cerror 
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @s_culture = @s_culture,
   @i_num   = @w_return
   
return @w_return

GO


/*

declare @o_secuencial_ing   int,
        @o_msg_matriz       varchar(64),
        @w_error int
exec @w_error = sp_api_loans_payments
   @s_user                 = 'luiss',
   @s_term                 = 'termx',
   @s_date                 = null,
   @s_sesn                 = 2,
   @s_ssn                  = 2,
   @s_srv                  = 'CTSSRV',
   @s_ofi                  = 1,
   @i_operacion            = 'I', --'A'Consulta,'I'Ingreso
   @i_banco                = '0001004043',
   @i_operacionca          = NULL,
   @i_secuencial           = NULL,
   @i_beneficiario         = 'LUIS',
   @i_fecha_vig            = '05/04/2020',
   @i_retencion            = 0,
   @i_producto             = 'EFMN', -- catalogo de formas de pago: ca_producto
   @i_monto_mpg            = 100,
   @i_cuenta               = '0001', -- referencia, cuenta aho o cte
   @i_moneda               = 0,
   @i_dividendo            = 0,
   @i_cheque               = NULL,
   @i_cod_banco            = NULL,
   @i_tipo_cobro           = 'P', --'A'cumulado, 'P'royectado 
   @i_tipo_reduccion       = 'T', --'C'uota,'T'iempo
   @i_tipo_aplicacion      = 'D', --'D'ividendos, 'C'onceptos
   @i_pago_ext             = 'N',   
   @i_sec_desem_renova     = null,
   @i_pago_gar_grupal      = 'N',
   @i_referencia_pr        = NULL,-- Por precancelacion grupal
   @i_valor_multa          = 0,
   @i_valida_sobrante      = 'S',
   @i_simulado             = 'N',  --Pago Simulado
   @i_condonacion          = 'N',
   @i_rubro_condonar       = 'CAP', --Conceptos o rubros a condonar 
   @o_secuencial_ing       = @o_secuencial_ing out,
   @o_msg_matriz           = @o_msg_matriz out 
select @o_secuencial_ing, @o_msg_matriz, @w_error

*/
