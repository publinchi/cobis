USE cob_cartera
GO

if exists (select 1 from sysobjects where name = 'sp_api_loans_disbursements')
   drop proc sp_api_loans_disbursements
GO


CREATE PROCEDURE sp_api_loans_disbursements
/************************************************************************************/
/*  Archivo:            spLoansDisbursements.sp                                     */
/*  Stored procedure:   sp_api_loans_disbursements                                  */
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
   @s_date                 datetime,
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
   @i_ata_cuenta_autom     char(1)      = NULL,
   @i_num_cuenta_ext       VARCHAR(24)  = NULL,
   @i_op_operacion         INT          = NULL,
   @i_banco                cuenta       = NULL,
   @i_producto             catalogo     = '',
   @i_monto_ds             MONEY        = null,
   @i_moneda_ds            smallint     = null,
   @i_pasar_tmp            char(1)      = null,
   @i_formato_fecha        int          = null,
   --@i_cheque               int          = null,
   @i_fecha_liq            datetime     = null,
   @i_regenera_rubro       char(1)      = NULL,
   @i_secuencial           int          = null, --LPO Nuevo
   @i_desembolso           tinyint      = null, --LPO Nuevo   
   
   --Parametros para la prueba de concepto de la coreografia
   @i_coreografia          char(1)      = NULL,
   @i_codigo_respuesta     INT          = NULL,
   --
   
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
@w_op_cuenta                varchar(30),
@w_op_monto_desembolso      MONEY,
@w_op_cliente               int,
@w_grupal                   char(1),
@w_f_acredita_des           varchar(24),
@w_moneda_op                TINYINT,
@w_cotiz_ds                 money  ,
@w_tcotiz_ds                char(1),
@w_cotiz_op                 money,
@w_tcotiz_op                char(1),
@w_toperacion               VARCHAR(10),
@w_cliente                  INT,
@w_plazo                    INT,
@w_tplazo                   VARCHAR(10),
@w_tdividendo               VARCHAR(10),
@w_periodo_cap              INT,
@w_periodo_int              INT,
@w_sp_name                  VARCHAR(64),
@w_op_operacion             INT



/*****************************************************
--LPO OPEN API:

sp_DisbursementsLoans.sp (sp_api_disbursements_loans)
   -->> POST /loans/{loandId}/disbursements
    --> @i_operacion = 'D' --> sp_desembolso_liquida -->(Desembolso y Liquidacion Directas, con la forma de desembolso que venga,
                                                         Si es Nota de credito a cuenta se pide @i_ata_cuenta_autom S/N , si es S
                                                         si se ata automaticamente la cuenta para el desembolso,si es N se pide
                                                         @i_num_cuenta_ext para saber el numero de cuenta en la que se tiene que
                                                         desembolsar.)
    --> @i_operacion = 'R' --> sp_desembolso         -->(Sólo Registro de desembolso con la forma de desembolso que venga)
    --> @i_operacion = 'L' --> sp_liquida            -->(Sòlo Liquidación del préstamo)
    --> @i_operacion = 'E' --> sp_desembolso         -->(Delete de registro de Desembolso)
    --> @i_operacion = 'S' --> sp_desembolso         -->(Consulta de los registros de Desembolso No aplicados)
    
    

******************************************************/


SELECT @w_sp_name = 'sp_api_loans_disbursements'

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



select @i_op_operacion         = op_operacion,
       @w_op_cuenta            = op_cuenta,
       @w_op_monto_desembolso  = op_monto,
       @w_op_cliente           = op_cliente,
       @w_grupal               = op_grupal,
       @w_moneda_op            = op_moneda
from   cob_cartera..ca_operacion
where  op_banco      = @i_banco

SELECT @w_cotiz_ds         =     1,
       @w_tcotiz_ds        =     1,
       @w_cotiz_op         =     1,
       @w_tcotiz_op        =     1


/* ******************** */
/* INTERNACIONALIZACION */
/* ******************** */
exec cobis..sp_ad_establece_cultura
    @o_culture = @s_culture out

select @w_f_acredita_des = pa_char --NOTA DE CREDITO
from cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'NCRAHO'


IF @i_operacion = 'D' 
BEGIN
   
   IF @i_ata_cuenta_autom = 'N' AND @i_num_cuenta_ext IS NULL
   BEGIN
      SELECT @w_error = 250030 --'El número de cuenta es mandatorio.'
      GOTO ERROR
   END

   --Validacion existencia de la moneda
   IF EXISTS (SELECT 1 FROM cobis..cl_tabla a, cobis..cl_catalogo b where a.codigo = b.tabla and a.tabla = 'cl_moneda' and b.codigo = @i_moneda_ds)
      SELECT @i_moneda_ds = @i_moneda_ds
   ELSE   
   BEGIN
      SELECT @w_error = 701069
      GOTO ERROR
   END

   --Validacion existencia de la forma de pago y moneda
    IF EXISTS (SELECT 1 FROM cob_cartera..ca_producto WHERE cp_producto = @i_producto AND cp_moneda = @i_moneda_ds)
      SELECT @i_moneda_ds = @i_moneda_ds
   ELSE   
   BEGIN
      SELECT @w_error = 708188 --'La forma de pago no soportada para la moneda de transaccion'
      GOTO ERROR
   END
    
   
   --DESEMBOLSO / LIQUIDA--
   ------------------------
      
   IF @i_producto IS NULL
      SELECT @i_producto = @w_f_acredita_des
   
      
   IF @i_ata_cuenta_autom = 'S'
   BEGIN      
          
	  execute @w_error  = cob_cartera..sp_vincula_ctaho
	          @s_ssn     = @s_ssn,
	          @s_ofi     = @s_ofi,
	          @s_user    = @s_user,
	          @s_date    = @s_date,
	          @s_sesn    = @s_sesn, --31175,
              @s_term    = @s_term,
              @s_srv     = @s_srv,
              @s_lsrv    = @s_lsrv,
              @i_operacion  = @i_op_operacion
      
      IF @w_error <> 0
         GOTO ERROR
      
   END  --@i_ata_cuenta_autom = 'S'
   
   IF @i_ata_cuenta_autom = 'N'
   BEGIN
   
      update cob_cartera..ca_operacion
      set    op_cuenta    = @i_num_cuenta_ext
      where  op_operacion = @i_op_operacion      
      
      SELECT @w_op_cuenta = @i_num_cuenta_ext
      
   END --@i_ata_cuenta_autom = 'N'
   
   update cob_cartera..ca_operacion
   set    op_estado    = 0 --@w_est_novigente
   where  op_operacion = @i_op_operacion
      
   BEGIN TRAN
   exec @w_error  = cob_cartera..sp_desembolso_liquida
	       @i_banco_ficticio   = @i_op_operacion,
	       @i_banco_real       = @i_banco,
	       @i_formato_fecha    = @i_formato_fecha, --103,
	       @i_moneda_ds        = @i_moneda_ds, --0,
	       @i_producto         = @i_producto, --NCAH_FINAN
	       @i_cuenta           = @w_op_cuenta,
	       @i_monto_ds         = @w_op_monto_desembolso, -- ca_operacion.op_monto_desembolso
	       @i_cotiz_ds         = @w_cotiz_ds, --1,
           @i_moneda_op        = @w_moneda_op,
	       @i_cotiz_op         = @w_cotiz_op, --1,
	       @i_tcotiz_ds        = @w_tcotiz_ds, --1,
	       @i_tcotiz_op        = @w_tcotiz_op, --1,
	       @i_beneficiario     = @w_op_cliente,
	       @i_fecha_liq        = @i_fecha_liq, --@s_date
	       @t_trn              = 7032,
	       @i_operacion        = 'I',
	       @i_pasar_tmp        = @i_pasar_tmp, --'S',
	       @i_externo          = 'N', -- INDICA QUE FUE ENVIADO DESDE EL ORIGINADOR, PARA QUE EL SP NO HAGA COMMITS(ESTO LOS HACE EL SP DE WORKFLOW)
	       @i_regenera_rubro   = @i_regenera_rubro, --'S',
	       @i_grupal           = @w_grupal,
	       @s_srv              = @s_srv, --'CTSSRV',
	       @s_user             = @s_user,
	       @s_term             = @s_term,
	       @s_ofi              = @s_ofi,
	       @s_rol              = @s_rol,
	       @s_ssn              = @s_ssn,
	       @s_lsrv             = @s_lsrv, --'CTSSRV',
	       @s_date             = @s_date, --@w_fecha_proceso,
	       @s_sesn             = @s_ssn,
	       @s_org              = @s_org, --'U',
	       @s_culture          = @s_culture --'NEUTRAL' --'es_EC'
	  
   IF @w_error <> 0
   BEGIN
      ROLLBACK TRAN
      GOTO ERROR
   END
   
   COMMIT TRAN
      
END --FIN @i_operacion = 'D'


IF @i_operacion = 'R'
BEGIN
   
   IF @i_producto = @w_f_acredita_des --NOTA DE CREDITO 'NCAH_FINAN'
   BEGIN
      IF @i_num_cuenta_ext IS NULL
      BEGIN
         SELECT @w_error = 250030 --'El número de cuenta es mandatorio.'
         GOTO ERROR
      END
   END

   --Validacion existencia de la moneda
   IF EXISTS (SELECT 1 FROM cobis..cl_tabla a, cobis..cl_catalogo b where a.codigo = b.tabla and a.tabla = 'cl_moneda' and b.codigo = @i_moneda_ds)
      SELECT @i_moneda_ds = @i_moneda_ds
   ELSE   
   BEGIN
      SELECT @w_error = 701069
      GOTO ERROR
   END

   --Validacion existencia de la forma de pago y moneda
    IF EXISTS (SELECT 1 FROM cob_cartera..ca_producto WHERE cp_producto = @i_producto AND cp_moneda = @i_moneda_ds)
      SELECT @i_moneda_ds = @i_moneda_ds
   ELSE   
   BEGIN
      SELECT @w_error = 708188 --'La forma de pago no soportada para la moneda de transaccion'
      GOTO ERROR
   END
         
   BEGIN TRAN
/*   
   PRINT '@i_op_operacion ' + CAST(@i_op_operacion AS VARCHAR)
   PRINT '@i_banco ' + CAST(@i_banco AS VARCHAR)
   PRINT '@i_formato_fecha ' + CAST(@i_formato_fecha AS VARCHAR)
   PRINT '@i_moneda_ds ' + CAST(@i_moneda_ds AS VARCHAR)
   PRINT '@i_producto ' + CAST(@i_producto AS VARCHAR)
   PRINT '@i_num_cuenta_ext ' + CAST(@i_num_cuenta_ext AS VARCHAR)
   PRINT '@i_op_operacion ' + CAST(@i_op_operacion AS VARCHAR)
   PRINT '@i_op_operacion ' + CAST(@i_op_operacion AS VARCHAR)
   PRINT '@i_op_operacion ' + CAST(@i_op_operacion AS VARCHAR)
*/
   
   update cob_cartera..ca_operacion
   set    op_estado    = 0, --@w_est_novigente
          op_cuenta    = @i_num_cuenta_ext
   where  op_operacion = @i_op_operacion
      
   --INGRESAR DESEMBOLSO--
   -----------------------
   exec @w_error = cob_cartera..sp_desembolso
   @i_banco_ficticio   = @i_op_operacion,
   @i_banco_real       = @i_banco,
   @i_formato_fecha    = @i_formato_fecha,
   @i_origen           = 'B',
   @i_moneda_ds        = @i_moneda_ds,
   @i_producto         = @i_producto, --Forma de desembolso
   @i_cuenta           = @i_num_cuenta_ext, --@i_cuenta,
   @i_monto_ds         = @i_monto_ds,
   @i_cotiz_ds         = @w_cotiz_ds, --1,
   @i_moneda_op        = @w_moneda_op,   
   @i_cotiz_op         = @w_cotiz_op, --1,
   @i_tcotiz_ds        = @w_tcotiz_ds, --1,
   @i_tcotiz_op        = @w_tcotiz_op, --1,   
   @i_beneficiario     = @w_op_cliente,
   @t_trn              = 7032,
   @i_operacion        = 'I',
   @i_pasar_tmp        = @i_pasar_tmp,
   @i_fecha_desembolso = @i_fecha_liq,
   @s_srv              = @s_srv ,
   @s_user             = @s_user,
   @s_term             = @s_term,
   @s_ofi              = @s_ofi  ,
   @s_rol              = @s_rol  ,
   @s_ssn              = @s_ssn  ,
   @s_lsrv             = @s_lsrv ,
   @s_date             = @s_date ,
   @s_sesn             = @s_sesn ,
   @s_org              = @s_org, --'U'  ,
   @s_culture          = @s_culture,
   @i_externo          = 'N',
   @i_regenera_rubro   = @i_regenera_rubro,
   @i_grupal           = @w_grupal
   
   IF @w_error <> 0
   BEGIN
      ROLLBACK TRAN
      GOTO ERROR
   END
   
   if @i_fecha_liq > @s_date
   begin

      --Actualiza la operación con la fecha futura de liquidaciÃƒÂ³n

      select
          @w_toperacion        = opt_toperacion,
          @w_cliente           = opt_cliente,
          @w_plazo             = opt_plazo,
          @w_tplazo            = opt_tplazo,
          @w_tdividendo        = opt_tdividendo,
          @w_periodo_cap       = opt_periodo_cap,
          @w_periodo_int       = opt_periodo_int
      from ca_operacion_tmp
      where opt_banco =  @i_banco
      
      /* CREAR OPERACION TEMPORAL */
       
      exec @w_error = sp_borrar_tmp
      @i_banco  = @i_banco,
      @s_term   = @s_user,
      @s_user   = @s_user
      
      IF @w_error <> 0
      BEGIN
         ROLLBACK TRAN
         GOTO ERROR
      END
      
      exec @w_error = sp_crear_tmp
      @s_user        = @s_user,
      @s_term        = @s_term,
      @i_banco       = @i_banco,
      @i_accion      = 'A'
      
      IF @w_error <> 0
      BEGIN
         ROLLBACK TRAN
         GOTO ERROR
      END
      
      exec @w_error = sp_modificar_operacion
           @s_user               = @s_user,
           @s_sesn               = @s_sesn,
           @s_date               = @s_date,
           @s_term               = @s_term,
           @s_ofi                = @s_ofi,
           @i_calcular_tabla     = 'S',
           @i_tabla_nueva        = 'S',
           @i_recalcular         = 'S',
           @i_cuota              = 0,
           @i_banco              = @i_banco,
           @i_operacionca       = @i_op_operacion,
           @i_fecha_ini         = @i_fecha_liq ,
           @i_plazo             = @w_plazo,
           @i_tplazo            = @w_tplazo,
           @i_periodo_cap       = @w_periodo_cap,
           @i_periodo_int       = @w_periodo_int,
           @i_toperacion        = @w_toperacion,
           @i_monto             = @w_op_monto_desembolso,
           @i_cliente           = @w_cliente,
           @i_regenera_rubro    = @i_regenera_rubro,
           @i_grupal            = @w_grupal
        
      IF @w_error <> 0
      BEGIN
         ROLLBACK TRAN
         GOTO ERROR
      END
      
      exec sp_operacion_def
      @i_banco = @i_banco,
      @s_date  = @s_date,
      @s_sesn  = @s_sesn,
      @s_user  = @s_user,
      @s_ofi   = @s_ofi
      
      exec sp_borrar_tmp
      @i_banco  = @i_banco,
      @s_sesn   = @s_sesn,
      @s_user   = @s_user,
      @s_term   = @s_term
   END
   COMMIT TRAN
END --@i_operacion = 'R' FIN



IF @i_operacion = 'L'
BEGIN
      
   BEGIN TRAN
   --LIQUIDAR DESEMBOLSO--
   ------------------------
   
   exec @w_error = sp_borrar_tmp
   @i_banco  = @i_banco,
   @s_sesn   = @s_sesn,
   @s_user   = @s_user,
   @s_term   = @s_term
   
   if @w_error <> 0
   BEGIN
      ROLLBACK TRAN
      GOTO ERROR
   END   
   
   exec @w_error = sp_crear_tmp
   @s_user        = @s_user,
   @s_term        = @s_term,
   @i_banco       = @i_banco,
   @i_accion      = 'A'
      
   IF @w_error <> 0
   BEGIN
      ROLLBACK TRAN
      GOTO ERROR
   END
   
   exec @w_error = cob_cartera..sp_liquida
   @i_banco_ficticio  = @i_op_operacion,
   @i_banco_real      = @i_banco,
   @i_fecha_liq       = @i_fecha_liq,
   @i_externo         = 'N',
   @i_regenera_rubro  = @i_regenera_rubro,
   @i_grupal          = @w_grupal   ,
   
   @i_coreografia     = @i_coreografia, --LPO CDIG Coreografia
   
   @s_srv             = @s_srv      ,
   @s_user            = @s_user     ,
   @s_term            = @s_term     ,
   @s_ofi             = @s_ofi      ,
   @s_rol             = @s_rol      ,
   @s_ssn             = @s_ssn      ,
   @s_lsrv            = @s_lsrv     ,
   @s_date            = @s_date     ,
   @s_sesn            = @s_sesn     ,
   @s_org             = @s_org
   
   IF @w_error <> 0
   BEGIN
      ROLLBACK TRAN
      GOTO ERROR
   END
   
   IF @i_coreografia <> 'S' --LPO CDIG Coreografia INICIO
   BEGIN
   
   --INI AGI 31JUL19  Cobro de Seguros
   --print 'comienza debito paquete seguros'
   execute @w_error = sp_debito_seguros
           @s_ssn            = @s_ssn,
           @s_sesn           = @s_ssn,
           @s_user           = @s_user,
           @s_date           = @s_date,
           @s_ofi            = @s_ofi,
           @i_operacion      = @i_op_operacion,
           @i_cta_grupal     = @i_num_cuenta_ext,
           @i_moneda         = @i_moneda_ds,
           @i_fecha_proceso  = @i_fecha_liq,
           @i_oficina        = @s_ofi,
           @i_opcion         = 'D',
           @i_secuencial_trn = @s_ssn
   --print 'finaliza proceso debito paquete seguros '
   --FIN AGI
   
   IF @w_error <> 0
   BEGIN
      ROLLBACK TRAN
      GOTO ERROR
   END
      
   --Actualizo estado
   --print 'actualiza estado tabla seguros op'
   update ca_seguros_op
   set so_estado = 'A'
   from  cob_cartera..ca_seguros_op
   where so_operacion  = @i_op_operacion
   
   if @@error != 0
   begin
      ROLLBACK TRAN
      SELECT @w_error = 725044
      GOTO ERROR
   END
   END --LPO CDIG Coreografia FIN
   
         
   COMMIT TRAN
END ----@i_operacion = 'L' FIN


--LPO CDIG API REQUIERE QUE SE DEVUELVA EL CODIGO DEL ENTE CREADO, POR ESTANDAR, EN ESTE CASO EL SECUENCIAL y DESEMBOLSO, INICIO
IF @i_operacion = 'D' OR @i_operacion = 'R' OR @i_operacion = 'L'
BEGIN
   SELECT dm_secuencial, dm_desembolso
   FROM ca_desembolso
   WHERE dm_operacion = @i_op_operacion
END

--LPO CDIG API REQUIERE QUE SE DEVUELVA EL CODIGO DEL ENTE CREADO, POR ESTANDAR, EN ESTE CASO EL SECUENCIAL y DESEMBOLSO, FIN


IF @i_operacion = 'E'
BEGIN
   --ELIMINAR DESEMBOLSOS--
   ------------------------
   
   BEGIN TRAN 
   
   exec @w_error = cob_cartera..sp_desembolso
   @i_banco_ficticio   = @i_op_operacion,
   @i_banco_real       = @i_banco,
   @i_secuencial       = @i_secuencial,
   @i_desembolso       = @i_desembolso,
   @t_trn              = 7032,
   @i_operacion        = 'D',
   @s_srv              = @s_srv ,
   @s_user             = @s_user,
   @s_term             = @s_term,
   @s_ofi              = @s_ofi  ,
   @s_rol              = @s_rol  ,
   @s_ssn              = @s_ssn  ,
   @s_lsrv             = @s_lsrv ,
   @s_date             = @s_date ,
   @s_sesn             = @s_sesn ,
   @s_org              = @s_org,
   @s_culture          = @s_culture
   
   IF @w_error <> 0
   BEGIN
      ROLLBACK TRAN
      GOTO ERROR
   END
   
   COMMIT TRAN
   
END


IF @i_operacion = 'S'
BEGIN
   --CONSULTAR DESEMBOLSOS--
   ------------------------
   exec @w_error = cob_cartera..sp_desembolso
   @i_banco_ficticio   = @i_op_operacion,
   @i_banco_real       = @i_banco,
   --@i_secuencial       = @i_secuencial,
   @i_desembolso       = @i_desembolso,
   @t_trn              = 7032,
   @i_operacion        = 'S',
   @s_srv              = @s_srv ,
   @s_user             = @s_user,
   @s_term             = @s_term,
   @s_ofi              = @s_ofi  ,
   @s_rol              = @s_rol  ,
   @s_ssn              = @s_ssn  ,
   @s_lsrv             = @s_lsrv ,
   @s_date             = @s_date ,
   @s_sesn             = @s_sesn ,
   @s_org              = @s_org,
   @s_culture          = @s_culture
   
   IF @w_error <> 0
   BEGIN
      GOTO ERROR
   END
  
END


IF @i_operacion = 'C' --Confirmacion de la NCAH desde Coreografia
BEGIN
   IF @i_codigo_respuesta = 0 --NCAH Exitosa
   BEGIN
      PRINT 'LLamar al sp_liquida 2da parte '
      BEGIN TRAN
      --LIQUIDAR DESEMBOLSO--
      ------------------------
      
      exec @w_error = sp_borrar_tmp
      @i_banco  = @i_banco,
      @s_sesn   = @s_sesn,
      @s_user   = @s_user,
      @s_term   = @s_term
      
      if @w_error <> 0
      BEGIN
         ROLLBACK TRAN
         GOTO ERROR
      END   
      
      exec @w_error = sp_crear_tmp
      @s_user        = @s_user,
      @s_term        = @s_term,
      @i_banco       = @i_banco,
      @i_accion      = 'A'
      
      IF @w_error <> 0
      BEGIN
         ROLLBACK TRAN
         GOTO ERROR
      END
      
      exec @w_error = cob_cartera..sp_liquida_2
      @i_banco_ficticio  = @i_op_operacion,
      @i_banco_real      = @i_banco,
      @i_fecha_liq       = @i_fecha_liq,
      @i_externo         = 'N',
      @i_regenera_rubro  = @i_regenera_rubro,
      @i_grupal          = @w_grupal   ,
      
      --@i_coreografia     = @i_coreografia, --LPO CDIG Coreografia
   
      @s_srv             = @s_srv      ,
      @s_user            = @s_user     ,
      @s_term            = @s_term     ,
      @s_ofi             = @s_ofi      ,
      @s_rol             = @s_rol      ,
      @s_ssn             = @s_ssn      ,
      @s_lsrv            = @s_lsrv     ,
      @s_date            = @s_date     ,
      @s_sesn            = @s_sesn     ,
      @s_org             = @s_org
      
      IF @w_error <> 0
      BEGIN
         ROLLBACK TRAN
         GOTO ERROR
      END
      
      --INI AGI 31JUL19  Cobro de Seguros
      --print 'comienza debito paquete seguros'
      execute @w_error = sp_debito_seguros
              @s_ssn            = @s_ssn,
              @s_sesn           = @s_ssn,
              @s_user           = @s_user,
              @s_date           = @s_date,
              @s_ofi            = @s_ofi,
              @i_operacion      = @i_op_operacion,
              @i_cta_grupal     = @i_num_cuenta_ext,
              @i_moneda         = @i_moneda_ds,
              @i_fecha_proceso  = @i_fecha_liq,
              @i_oficina        = @s_ofi,
              @i_opcion         = 'D',
              @i_secuencial_trn = @s_ssn
      --print 'finaliza proceso debito paquete seguros '
      --FIN AGI
      
      IF @w_error <> 0
      BEGIN
         ROLLBACK TRAN
         GOTO ERROR
      END
      
      --Actualizo estado
      --print 'actualiza estado tabla seguros op'
      update ca_seguros_op
      set so_estado = 'A'
      from  cob_cartera..ca_seguros_op
      where so_operacion  = @i_op_operacion
      
      if @@error != 0
      begin
         ROLLBACK TRAN
         SELECT @w_error = 725044
         GOTO ERROR
      END
            
      COMMIT TRAN
      
   END
   ELSE --NCAH No Exitosa
   BEGIN
--      PRINT 'LLamar al reverso '
      
      execute @w_error = sp_reverso_liquida
              @s_ssn            = @s_ssn,
              @s_sesn           = @s_ssn,
              @s_user           = @s_user,
              @s_date           = @s_date,
              @s_ofi            = @s_ofi,
              @i_banco_real     = @i_banco
--      PRINT 'LLamar al reverso 2'
      IF @w_error <> 0
      BEGIN
         GOTO ERROR
      END
   END
END


RETURN 0

ERROR:
   exec cobis..sp_cerror 
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @s_culture = @s_culture,
   @i_num   = @w_error
   
   return @w_error

GO
