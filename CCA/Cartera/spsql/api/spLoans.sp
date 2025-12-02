USE cob_cartera
GO


if exists (select 1 from sysobjects where name = 'sp_api_loans')
   drop proc sp_api_loans
GO


CREATE PROCEDURE sp_api_loans
/************************************************************************************/
/*  Archivo:            spLoans.sp                                                  */
/*  Stored procedure:   sp_api_loans                                                */
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
/*  la creacion y modificacion de operaciones de Cartera                            */
/************************************************************************************/
/*                          MODIFICACIONES                                          */
/*  FECHA             AUTOR                   RAZON                                 */
/*  05/MAY/2020       Luis Ponce              Emision Inicial                       */
/************************************************************************************/
(
@s_ssn                      INT = NULL,
@s_user                     login       = null,
@s_sesn                     int         = null,
@s_term                     descripcion = null, --MTA
@s_date                     datetime    = null,
@s_srv                      varchar(30) = null,
@s_lsrv                     varchar(30) = null,
@s_rol                      smallint    = NULL,
@s_ofi                      smallint    = NULL,
@s_culture                  varchar(10) = 'NEUTRAL', --Estandarizacion API

-------------------------------------------------------
@i_operacion                char(1),
@i_cliente                  INT,
@i_plazo                    INT,
@i_tipo_plazo               VARCHAR(10),
@i_frec_pago                VARCHAR(10),
@i_monto                    MONEY,
@i_monto_desembolso         MONEY,
@i_toperacion               VARCHAR(10),
@i_moneda                   INT,
@i_destino                  varchar(10),
------------------------------------------------
@i_oficial                  INT         = 2, --1,
@i_dia_fijo                 INT         = NULL,
@i_fecha_ini                DATETIME    = NULL, --@w_fecha_desemb, 
@i_monto_aprobado           MONEY       = NULL,
@i_fecha_ven_pc             DATETIME    = NULL, --@w_fecha_primer_pago,
@i_tipo                     CHAR(1)     = 'O',
@i_subtipo                  CHAR(1)     = NULL,
@i_origen_fondos            VARCHAR(10) = NULL, --'PROPIOS',
@i_seguro_basico            CHAR(1)     = 'N', --LPO NO ENVIAR QUITAR DEL API
@i_seguro_voluntario        CHAR(1)     = 'N', --LPO NO ENVIAR QUITAR DEL API

--------------------------------------------------
--LPO CDIG APIS II
@i_op_renovada              cuenta      = null,
@i_migrada                  cuenta      = null,
@i_sector                   VARCHAR(10) = NULL,
@i_linea_credito            cuenta      = null,
@i_per_reajuste             tinyint     = null,
@i_reajuste_especial        char(1)     = NULL,
@i_tipo_prod                CHAR(1)     = NULL,
@i_fpago                    catalogo    = null,
@i_cuenta                   cuenta      = null,
@i_dias_anio                SMALLINT    = NULL,
@i_tipo_amortizacion        VARCHAR(30) = NULL,
@i_tipo_reduccion           CHAR(1)     = NULL,
@i_aceptar_anticipos        CHAR(1)     = NULL,
@i_precancelacion           CHAR(1)     = NULL,
@i_tipo_aplicacion          CHAR(1)     = NULL,
@i_tplazo                   catalogo    = NULL,
@i_tdividendo               catalogo    = NULL,
@i_periodo_cap              INT         = NULL,
@i_periodo_int              INT         = NULL,
@i_dist_gracia              CHAR(1)     = NULL,
@i_gracia_cap               INT         = NULL,
@i_gracia_int               INT         = NULL,
@i_evitar_feriados          CHAR(1)     = NULL,
@i_renovacion               CHAR(1)     = NULL,
@i_mes_gracia               INT         = NULL,
@i_reajustable              CHAR(1)     = NULL,
@i_clase_cartera            catalogo    = NULL,
@i_base_calculo             CHAR(1)     = NULL,
@i_fondos_propios           CHAR(1)     = NULL, --LPO PONER JUNTO A ORIGEN DE FONDOS
@i_causacion                CHAR(1)     = NULL,
@i_convierte_tasa           CHAR(1)     = NULL,
@i_tasa_equivalente         CHAR(1)     = NULL,
@i_nace_vencida             CHAR(1)     = NULL,


--------Datos para Grupales -----------------
@i_grupal                   CHAR(1)     = 'N',
@i_es_grupal                CHAR(1)     = 'N',
@i_grupo                    INT         = NULL,
@i_en_linea                 CHAR(1)     = 'N', 
@i_ref_grupal               cuenta      = NULL,
@i_tipo_cobro               CHAR(1)     = NULL,


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
@i_x_requestId_to_reverse           varchar(25)   = NULL,        --headers.x-requestId-to-reverse

@o_op_banco                 cuenta      = NULL OUT,
@o_op_operacion             INT         = NULL OUT
)
as

declare
@w_error                    INT,
@w_fecha_proceso            DATETIME,
@w_op_banco                 VARCHAR(32),
@w_id_resultado             SMALLINT,
@w_tramite                  INT,
@w_op_operacion             INT,
@w_banco                    varchar(30),
@w_f_acredita_des           varchar(24),
@w_return                   int,
@w_op_cuenta                varchar(30),
@w_op_monto_desembolso      money,
@w_op_cliente               int,
@w_grupal                   char(1),
@w_sector                   VARCHAR(10),
@w_ciudad                   INT,
@w_sp_name                  VARCHAR(64)




--------Datos que podrian necesitarse y se deben calcular para pasar a los demàs sp's -------------
/*   @i_tasa_grupal      = @w_tasa,          
     @i_fondos_propios   = 'S',    
     @i_es_interciclo       
     @w_clase_car      = (select dt_clase_sector 
            from cob_cartera..ca_default_toperacion
                            where dt_toperacion = x.iot_toperacion and dt_moneda = x.iot_moneda),
*/
-------------------------------------------------------------------------------


SELECT @w_sp_name = 'sp_api_loans'

/* ******************** */
/* INTERNACIONALIZACION */
/* ******************** */
exec cobis..sp_ad_establece_cultura
    @o_culture = @s_culture out


IF @i_monto_aprobado IS NULL
   SELECT @i_monto_aprobado = @i_monto

IF @i_monto_desembolso IS NULL
   SELECT @i_monto_desembolso = @i_monto

SELECT @w_sector = (select dt_clase_sector 
                    from cob_cartera..ca_default_toperacion
                    where dt_toperacion = @i_toperacion and dt_moneda = @i_moneda)

IF @i_sector IS NULL
   SELECT @i_sector = @w_sector 
   
   
IF @s_date IS NULL
   SELECT @s_date = fp_fecha from cobis..ba_fecha_proceso

IF @i_operacion = 'I'
BEGIN

   --Validacion existencia del cliente
   IF EXISTS (SELECT 1 FROM cobis..cl_ente WHERE en_ente = @i_cliente)
      SELECT @i_cliente = @i_cliente
   ELSE
   BEGIN
      SELECT @w_error = 250072
      GOTO ERROR
   END
   
   --Validacion existencia del producto y la moneda
   IF EXISTS (SELECT 1 FROM cob_cartera..ca_default_toperacion WHERE dt_toperacion = @i_toperacion AND dt_moneda = @i_moneda)
      SELECT @i_toperacion = @i_toperacion
   ELSE   
   BEGIN
      SELECT @w_error = 710072
      GOTO ERROR
   END
   
   --Validacion existencia del tipo de plazo
   IF EXISTS (SELECT 1 FROM cob_cartera..ca_tdividendo WHERE td_tdividendo = @i_tipo_plazo)
      SELECT @i_cliente = @i_cliente
   ELSE
   BEGIN
      SELECT @w_error = 701000
      GOTO ERROR
   END
   
   --Validacion existencia del destino economico
   IF EXISTS (SELECT 1 FROM cobis..cl_tabla a, cobis..cl_catalogo b where a.codigo = b.tabla and a.tabla = 'cr_destino' and b.codigo = @i_destino)
      SELECT @i_destino = @i_destino
   ELSE
   BEGIN
      SELECT @w_error = 725010
      GOTO ERROR
   END
   
   --Validacion existencia de la moneda
   IF EXISTS (SELECT 1 FROM cobis..cl_tabla a, cobis..cl_catalogo b where a.codigo = b.tabla and a.tabla = 'cl_moneda' and b.codigo = @i_moneda)
      SELECT @i_moneda = @i_moneda
   ELSE
   BEGIN
      SELECT @w_error = 701069
      GOTO ERROR
   END
   
   --Validacion existencia del oficial
   IF EXISTS (SELECT 1 FROM cobis..cc_oficial where oc_oficial = @i_oficial)
      SELECT @i_oficial = @i_oficial
   ELSE
   BEGIN
      SELECT @w_error = 1720161
      GOTO ERROR
   END
   
   --Validacion del dia fijo de pago
   IF @i_dia_fijo > 30 OR @i_dia_fijo < 1
   BEGIN
      SELECT @w_error = 77540 --'Dia Fijo de Pago No Valido'
      GOTO ERROR
   END   
   
   EXEC @w_error = cob_credito..sp_tramite_busin
   @i_tramite                = 0,
   @i_tipo                   = @i_tipo,
   @i_truta                  = 0,
   @i_oficina_tr             = @s_ofi, --1, --9001,
   @i_usuario_tr             = @s_user, --'admuser',
   @i_oficial                = @i_oficial, --2,
   @i_sector                 = @i_sector, --@w_sector, --'T',
   @i_ciudad                 = @s_ofi, --9014,
   @i_cuota                  = 0.0,
   @i_frec_pago              = @i_frec_pago, --'W', --'M',
   @i_monto_solicitado       = @i_monto,
   @i_monto_desembolso       = @i_monto_desembolso, --@i_monto,
   @i_pplazo                 = @i_plazo,
   @i_fecha_inicio           = @s_date, --@w_fecha_proceso,
   @i_toperacion             = @i_toperacion, --'VIVTCASA',--'NEGOCIOS', 
   @i_producto               ='CCA',
   @i_monto                  = @i_monto,
   @i_moneda                 = @i_moneda, --0,
   @i_destino                = @i_destino, --'OC1',
   @i_ssn                    = 3199369,
   @i_id_inst_proc           = 0,
   @i_objeto                 = @i_origen_fondos, --'PROPIOS',
   @i_convenio               = ' ',
   @i_actividad_destino      = '2',
   @i_dia_fijo               = @i_dia_fijo, --7,
   @i_enterado               = '6',
   @i_seguro_basico          = @i_seguro_basico, --'S',
   @i_seguro_voluntario      = @i_seguro_voluntario, --'N',
   @i_cliente_cca            = @i_cliente,
   @i_deudor                 = @i_cliente,
   @t_trn                    = 21820,
   @i_operacion              = 'I',
   @i_op_renovada            = @i_op_renovada,  --LPO CDIG APIS II
   @i_linea_credito          = @i_linea_credito,
   @i_per_reajuste           = @i_per_reajuste,
   @i_reajuste_especial      = @i_reajuste_especial,
   @i_tipo_prod              = @i_tipo_prod,  --LPO CDIG APIS II
   @i_fpago                  = @i_fpago,
   @i_cuenta                 = @i_cuenta,
   @i_dias_anio              = @i_dias_anio,  --LPO CDIG APIS II
   @i_tipo_amortizacion      = @i_tipo_amortizacion, --LPO CDIG APIS II
   @i_tipo_cobro             = @i_tipo_cobro,     --LPO CDIG APIS II
   @i_tipo_reduccion         = @i_tipo_reduccion, --LPO CDIG APIS II
   @i_aceptar_anticipos      = @i_aceptar_anticipos, --LPO CDIG APIS II
   @i_tipo_aplicacion        = @i_tipo_aplicacion,   --LPO CDIG APIS II
   @i_tplazo                 = @i_tplazo,            --LPO CDIG APIS II
   @i_tdividendo             = @i_tdividendo,        --LPO CDIG APIS II
   @i_periodo_cap            = @i_periodo_cap,       --LPO CDIG APIS II
   @i_periodo_int            = @i_periodo_int,       --LPO CDIG APIS II
   @i_dist_gracia            = @i_dist_gracia,       --LPO CDIG APIS II
   @i_gracia_cap             = @i_gracia_cap,        --LPO CDIG APIS II
   @i_gracia_int             = @i_gracia_int,        --LPO CDIG APIS II
   @i_evitar_feriados        = @i_evitar_feriados,   --LPO CDIG APIS II
   @i_renovac                = @i_renovacion,        --LPO CDIG APIS II
   @i_mes_gracia             = @i_mes_gracia,        --LPO CDIG APIS II  
   @i_reajustable            = @i_reajustable,       --LPO CDIG APIS II
   @i_clase_cartera          = @i_clase_cartera,     --LPO CDIG APIS II
   @i_origen_fondos          = @i_origen_fondos,     --LPO CDIG APIS II
   @i_base_calculo           = @i_base_calculo,      --LPO CDIG APIS II   
   @i_tasa_equivalente       = @i_tasa_equivalente,  --LPO CDIG APIS II   
   @i_nace_vencida           = @i_nace_vencida,      --LPO CDIG APIS II      
   --@o_tramite                = 0,
   @s_srv                    = @s_srv,
   @s_user                   = @s_user,
   @s_term                   = @s_term,
   @s_ofi                    = @s_ofi, --1, --9001,
   @s_rol                    = @s_rol, --3,
   @s_ssn                    = @s_ssn, --3199383,
   @s_lsrv                   = @s_lsrv,  --'CTSSRV',
   @s_date                   = @s_date, --@w_fecha_proceso,
   @s_sesn                   = @s_sesn, --31175,
   @o_tramite                = @w_tramite OUT
   
   IF @w_error <> 0
      GOTO ERROR
      
   --select @w_error
   --select @w_op_operacion = op_operacion from   cob_cartera..ca_operacion where op_tramite = @w_tramite
   
   select @w_banco        = op_banco,
          @w_op_operacion = op_operacion
   FROM cob_cartera..ca_operacion where op_tramite = @w_tramite
   
   SELECT @o_op_banco = @w_banco
   SELECT @o_op_operacion = @w_op_operacion
   
END --FIN @i_operacion = 'I'

RETURN 0

ERROR:
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@s_culture = @s_culture, 
@i_num     = @w_error


return @w_error
go
