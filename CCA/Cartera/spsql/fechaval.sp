/************************************************************************/
/*   NOMBRE LOGICO:        fechaval.sp                                  */
/*   NOMBRE FISICO:        sp_fecha_valor                               */
/*   BASE DE DATOS:        cob_cartera                                  */
/*   PRODUCTO:             Cartera                                      */
/*   DISENADO POR:         Fabian de la Torre, Patricio Narvaez         */
/*   FECHA DE ESCRITURA:   Feb/99                                       */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Realiza la reversar o aplica fecha valor                           */
/*   Las transacciones Reversibles son:                                 */
/*   Desembolso, Desembolso Parciales, Cambio de Estado Manual,         */
/*   Reajustes, Reestructuraciones, Pagos                               */
/************************************************************************/
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */ 
/*  13/Feb/2019  Adriana Giler.   Eliminacion de ca_desembolso se ejecu_*/
/*                                ta despues de afectar Pasivas         */
/*  13/Jun/2019  Adriana Giler.   Conversion a varchar por decimales    */ 
/*  15/Jul/2019  Sandro Vallejo   Reversa Pagos Grupales e Interciclos  */
/*  19/Jul/2019  Luis Ponce       Cambios Pagos Grupales e Interciclos  */
/*  30/Jul/2019  Adriana Giler.   Reverso de incentivos grupales        */
/*  31/Jul/2019  Adriana Giler.   Reverso de seguros individuales       */
/*  06/Ago/2019  Lorena Regalado  Reversa de Desembolso de Operaciones  */
/*                                Grupales e interciclos                */
/*  10/Sep/2019  Adriana Giler.   Reverso de Prorrogas Grupales         */
/*  12/Dic/2019  Luis Ponce       Correr sp_batch tambien en Reversas   */
/*  13/Ene/2020  Luis Ponce       Error Reversa por Fondos Insuficientes*/
/*  13/Feb/2020  Luis Ponce       Orden obtencion @w_cod_alt en Reversas*/
/*  22/May/2020  Luis Castellanos CDIG Activacion-Reversa Pignoracion   */
/*  30/Jun/2020  Luis Ponce       CDIG Multimoneda Reversar Posicion    */
/*  18/Sep/2020  Sandro Vallejo   Controlar Fecha Valor menor a inicio  */
/*                                de la operacion                       */
/*  10/Nov/2020  Patricio Narvaez Reversa Reestructuraciones            */
/*  19/11/2020   Patricio Narvaez Esquema de Inicio de Dia, 7x24 y      */
/*                                Doble Cierre automatico               */
/*  10/Dic/2020  Patricio Narvaez Reversa de desembolo no borra PRV     */
/*  13/Ene/2021  P.Narvaez        F.Valor en la mora debe actualizar el */ 
/*                                proyectado                            */
/*  11/Mar/2021  W.Prado          Controlar Fecha Valor mayor a Fecha   */ 
/*                                Proceso                               */
/*  20/May/2021  A.Fortiche       se agrega mensaje informativo para    */
/*                                excepciones en fechas festivos        */
/*  02/Jun/2021  K.Rodriguez      Se cambia de estado a No Vigente de   */
/*                                una operación grupal si a todas sus   */
/*                                oper. hijas se aplica reverso de      */
/*                                desembolso                            */
/*  20/Ago/2021  K.Rodriguez      Validar condiciones para rub diferidos*/
/*  19/10/2021   K. Rodríguez     Envío param que identifica Fecha Valor*/
/*                                o reversa hacia el sp_batch           */
/*  19/11/2021   G. Fernandez     Ingreso de nuevos parametros para     */
/*                                proceso de licitud                    */
/*  07/04/2022   G. Fernandez     Se cambia eliminación del desembolso  */
/*                                por la actualizacion de campos        */
/*  01/Jun/2022  G. Fernandez     Se comenta prints                     */
/*  03/Jun/2022  J. Guzman        Cambio en logica de reverso pres. hijo*/
/*  09/Jun/2022  J. Guzman        Validaciones para reversos o fecha    */
/*                                valor en operaciones migradas         */
/*  06/07/2022   K. Rodríguez     Reverso desembolso no actualiza pagado*/
/*  14/07/2022   K. Rodríguez     Quitar manejo error de interfaz Bancos*/
/*                                y se elimina ca_otro_cargo (CARGESCOB)*/
/*  26/07/2022   K. Rodríguez     Actualización del valor acumulado INT */
/*                                al realizar fecha valor               */
/*  01/08/2021   K. Rodríguez     Ajustes reverso pagos afect a Bancos  */
/*  04/08/2021   K. Rodríguez     Ajuste Fecha val a préstamos migrados */
/*  16/08/2021   K. Rodríguez     R-191337: Reversar en Bancos indepen- */
/*                                diente de la fecha de pago            */
/*  07/09/2022   K. Rodríguez     R193119 Respetar error enviado Bancos */
/*  28/09/2022   K. Rodriguez     R194611 Ajuste Rev. trans. en Bancos  */
/*  28/10/2022   K. Rodriguez     R196111 Actualiza de número de ciclos */
/*                                en la tabla cl_ente                   */
/*  27/01/2023   K. Rodriguez     Se incluye al DIF a valida trn manual */
/*  08/02/2023   J. Guzman        Parametro y validaciones para reversos*/
/*                                de prestamos grupales                 */
/*  27/02/2023   G. Fernandez     S787839 Parametro y validaciones para */
/*                                reverso individual de DES. de op. hija*/
/*  22/03/2023   G. Fernandez     S785345 Reverso de registro de bancos */
/*  18/05/2023   G. Fernandez     S785498 Validacion con parametro para */
/*                                evitar reversos de desembolso de dias */
/*                                anteriores                            */
/* 28/07/2023    G. Fernandez     S857741 Parametros de licitud         */
/* 17-Nov-2023   K. Rodríguez     R217688 Ajuste Validacion tanqueo fact*/
/* 06-Dic-2023   K. Rodríguez     R220933 No considerae estado Anulado  */
/*                                para actualiza OP padre a No vigente  */
/* 12-Dic-2023   K. Rodríguez     R221056 Ajuste dias gracia mora y dias*/
/*                                gracia mora disponibles               */
/* 17/Mar/2025   Oscar Diaz       Error #262345                         */
/* 09-Sep-2025   K. Rodríguez     R281628 Validar secuencial en Reverso */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_fecha_valor')
   drop proc sp_fecha_valor
go

create proc sp_fecha_valor (
@s_date                  datetime     = null,
@s_lsrv                  varchar(30)  = null,
@s_ofi                   smallint     = null,
@s_org                   char(1)      = null,
@s_rol                   smallint     = null,
@s_sesn                  int          = null,
@s_ssn                   int          = null,
@s_srv                   varchar(30)  = null,
@s_term                  descripcion  = null,
@s_user                  login        = null,
@s_culture               varchar(10)  = 'NEUTRAL',
@t_rty                   char(1)      = null,
@t_debug                 char(1)      = 'N',
@t_file                  varchar(14)  = null,
@t_trn                   smallint     = null,
@t_ssn_corr              int          = null, --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos  
@t_show_version          bit          = 0, 
@i_fecha_valor           datetime     = '01/01/1900',
@i_banco                 cuenta,
@i_secuencial            int          = NULL,
@i_operacion             char(1)      = NULL,   --(F)Fecha Valor (R)Reversa
@i_observacion           varchar(255) = '',
@i_observacion_corto     char(62)     = '',
@i_fecha_mov             datetime     = NULL,  --NO SE USA
@i_en_linea              char(1)      = 'S',
@i_con_abonos            char(1)      = 'S',  --NO SE USA 
@i_secuencial_hfm        int          = 0,    --NO SE USA 
@i_control_fecha         char(1)      = 'N',  --DEJAR VALOR POR DEFECTO
@i_debug                 char(1)      = 'N',  --DEJAR VALOR POR DEFECTO
@i_es_atx                char(1)      = 'N',
@i_pago_ext              char(1)      = 'N',  
@i_bandera               char(1)      = 'N',  --MANEJO DE REVERSO DE PAGO DE RENOVACION O REESTRUCTURA
@i_grupal                char(1)      = 'N',
@i_control_pinter        char(1)      = 'S',   --CONTROLAR REVERSA PAGO/PRORROGA INTERCICLO --LPO TEC Reversa Grupal 
@i_pago_interfaz         char(1)      = 'N',   -- Variable que permite identificar si es Interfaz de Pago JCHS
@i_secuencial_rv_int     int          = 0,    -- Variable que permite la actualización del reverso de la interfaz JCHS
@i_id_referencia         VARCHAR(50)  = null,  -- id de referencia de la interfaz  
@i_aplica_licitud        CHAR(1)      = null, --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
@i_rev_pago_grupal_hijo  char(1)      = 'N',  --JGU Se envía en 'S' cuando se realiza reverso de pago grupal
@i_rev_liq_grupal        char(1)      = 'N',  --GFP Reverso grupal de las operaciones hijas, es 'S' cuando se envia de reversos desembolso grupal
@o_secuencial_act        int          = null out, -- KDR Devuelve secuencial actualizado cuando se realiza un reverso de Desembolso
-- Parámetros salida factura electrónica
@o_guid  				 varchar(36)  = null out,
@o_fecha_registro        varchar(10)  = null out,
@o_ssn 				 	 int 		  = null out,
@o_orquestador_fact      char(1)      = null out
)     
as 

declare
@w_sp_name               varchar (32),
@w_error                 int,
@w_monto_pag             money,
@w_monto_des             money,
@w_operacionca           int,
@w_secuencial_retro      int,
@w_secuencial_min        int,
@w_tran                  char(10),
@w_prod_rev              catalogo,
@w_abd_monto_mpg         money,
@w_est_novigente        int,
@w_fecha_ult_p           datetime,
@w_es_liq                char(1),
@w_pcobis                tinyint,
@w_cuenta                cuenta,
@w_aplicar_clausula      char(1),
@w_tipo                  char(1),
@w_lin_credito           cuenta,
@w_toperacion            catalogo,
@w_moneda                int,
@w_tramite               int,   
@w_opcion                char(1),  
@w_cliente               int,
@w_fecha_retro           datetime,
@w_contador              int,
@w_ciudad                int,
@w_moneda_trn            smallint,
@w_cotizacion_trn        money,
@w_categoria             catalogo,
@w_fecha_ingreso         datetime,
@w_dias_contr            smallint,
@w_dias_hoy              int,
@w_fecha_credito         datetime,
@w_fecha_contable        datetime,
@w_fecha_proceso         datetime,
@w_periodo               smallint,
@w_agotada               char(1),
@w_contabiliza           char(1),
@w_tipo_gar              varchar(64),
@w_abierta_cerrada       char(1),
@w_estado                char(1),
@w_monto_gar             money, 
@w_moneda_ab             int,
@w_shela                 tinyint,
@w_op_activa             int,
@w_cierre_calificacion   char(1),
@w_numero_comex          cuenta,  
@w_max_secuencial        int,
@w_tipo_linea            catalogo, 
@w_cheque                int,
@w_cod_banco             catalogo,
@w_beneficiario          varchar(50),
@w_sec_aux               int,
@w_ab_sec_rpa            int,        -- FCP Interfaz Ahorros   
@w_carga                 int,        --Reversos pagos cheques propios    
@w_oficina               int,
@w_re_area               int,
@w_categoria_rubro       char(1),
@w_monto_otc             money,
@w_mora_retroactiva      char(1),
@w_estado_op             tinyint,
@w_est_cancelado         tinyint,
@w_procesa               char(1),
@w_monto_pag_mn          money,
@w_monto_des_mn          money,
@w_monto_gar_mn          money,
@w_tipo_oficina_ifase    char(1),
@w_oficina_ifase         int,
@w_codvalor_mpg          int,
@w_saldo_cap_gar         money,
@w_sperror               int,
@w_secuencial_ing        int,
@w_abd_tipo              catalogo,
@w_pasiva                int,
@w_rp_lin_pasiva         catalogo,
@w_tramite_pasivo        int,
@w_tr_fecha_ref          datetime,
@w_tr_fecha_mov          datetime,
@w_oph_fecha_ult_proceso datetime,
@w_estado_trn            catalogo,
@w_fecha_pag             datetime,
@w_cotizacion_pago       money,
@w_moneda_nac            tinyint,
@w_forma_pago            catalogo,
@w_banco_alterno         cuenta,
@w_prodcobis_rev         tinyint,
@w_forma_reversa         catalogo,
@w_forma_original        catalogo,
@w_ht_lugar_his          tinyint,
@w_ht_fecha_his          datetime,
@w_fecha_movi            datetime,
@w_fecha_movi_tran       datetime,

-- FQ CONTROL DE REVERSOS DE PAGO
@w_transaccion_pag       char(1),
@w_secuencial_pag        int,
@w_secuencial_rpa        int,
@w_linea_fpago           catalogo,

-- FQ CONTROL CONTABLE PARA FITAL
@w_saldo_cap_antes_fv    money,
@w_monto_cap_pag         money,
@w_monto_cap_des         money,
@w_monto_cap_crc         money, -- CAPITALIZACION
                         
@w_monto_cap_pag_ing     money,
@w_monto_cap_des_ing     money,
@w_monto_cap_crc_ing     money, -- CAPITALIZACION
                         
@w_saldo_cap_despues_fv  money,
                         
@w_mensaje               varchar(255),
@w_monto_cap_pag_rv      money,
@w_monto_cap_des_rv      money,
@w_monto_cap_crc_rv      money,
                         
@w_monto_cap_pag_rv_ini  money,
@w_monto_cap_des_rv_ini  money,
@w_monto_cap_crc_rv_ini  money,
                         
@w_rev_des               char(1),
@w_tran_manual           char(1),
@w_oper_fechaval         int,
@w_parametro_fval        cuenta,
@w_llave_redescuento     cuenta,
@w_min_sec_prepago       int,
@w_banco_pasivo          cuenta,
@w_op_validacion         catalogo,
@w_capitalizaciones      char(1),
@w_capitaliza            char(1),
@w_producto_foriginal    smallint,
@w_cuenta_des            cuenta,
@w_operacion_des         int,
@w_fecha_des             datetime,
@w_op_naturaleza         char(1),
@w_fecha_hfp             datetime,
@w_secuencial_preferido  int,
@w_pa_cheger             varchar(30),
@w_rowcount              int,
@w_min_dividendo         smallint,
@w_valor_recaudo         money,
@w_valor_iva_recaudo     money,
@w_idlote                int,
@w_sec_orden             int,
@w_orden_pag             int,
@w_forma_rev             catalogo,   
@w_utilizado_cupo        money,
@w_monto_cap             money,
@w_operacion             char(1),
@w_comando               varchar(255),
@w_commit                char(1),
@w_fecha_valor           datetime,
@w_monto_cap_RES         char(1),
@w_fecha_evaluar         datetime,
@w_dm_pagado             char(1),
@w_orden_caja            int,
@w_fecha_ult_proceso     datetime,
@sec_pag_rec             int,    --LCM - 293
@w_banco_hija            cuenta,    -- JAR REQ 246
@w_msg                   varchar(255),
@w_toperacion_ant        catalogo,
@w_estado_cobran_ant     varchar(2),
@w_est_anulado           tinyint,
@w_parametro_fng         catalogo,
@w_div_fng               smallint,
@w_reg_falta             char(1),
@w_parametro_iva_fng     catalogo,
@w_di_fecha_ini          datetime,
@w_sec_rpa_acuerdo       int,                 -- REQ 089: ACUERDOS DE PAGO - 01/DIC/2010
@w_dm_desembolso         tinyint,
@w_op_banco_refin        cuenta,
@w_tramite_prorroga      int,
@w_tipo_norm             int,
@w_norm                  varchar(30),
@w_valida_trn            char(1),
@w_secuencial_ren        int,
@w_operacion_ren         cuenta,
@w_op_monto              money,
@w_in_origen             catalogo,
@w_est_castigado         tinyint,
@w_secuencial            int,
@w_in_ced_ruc            varchar(30),
@w_est_vencido           int,
@w_monto                 money,
@w_corresponsal          varchar(16),
@w_referencia            varchar(64),
@w_monto_pago            money,
@w_status_srv            varchar(64),
@w_trn_id_corresp        varchar(10),
@w_archivo_pago          varchar(255),
@w_diferencia            money,             --AGI 13JUN19 Diferencia mínima 0.01
@w_tipo_grupal           char(1),     --LPO TEC Reversa Grupal
@w_operacion_grupal      int,         --LPO TEC Reversa Grupal
@w_fecha_ult_grupal      datetime,    --LPO TEC Reversa Grupal
@w_secuencial_rev        int,         --LPO TEC Reversa Grupal
@w_banco_interc          cuenta,      --LRE TEC Reversa Desembolso
@w_op_interc             int,         --LRE TEC Reversa Desembolso Op. Grupal/Inrterciclos
@w_sec_des_interc        int,         --LRE TEC Reversa Desembolso Op. Grupal/Inrterciclos
--@w_secuencia_seguro      varchar(100), --LRE 01AGO19 TEC
@w_contador_seg          smallint,     --LRE 01AGO19 TEC
@w_es_grupal             char(1),      --LRE 01AGO19 TEC
@w_cod_alt               int,          --AGI
@w_num_oper_padre        int,          --LRE 03Sep2019 TEC
@w_banco_padre           cuenta,       --LRE 03Sep2019 TEC
@w_sec_divisas           INT,
@w_sec_reversa           INT,
@w_fecha_ini             DATETIME,      --SVA fecha valor menor
@w_tramite_res           int,
@w_banco_op_padre        cuenta,        -- KDR 02Jun2021 Banco Operacion Padre de Operaciones Hijas
@w_tiene_rub_dif        char(1) = 'N',  -- KDR-20/08/2021 Bandera si la operacion tiene rubros diferidos
@w_max_secuencial_diferido  INT,        -- KDR-20/08/2021 Maximo secuencial de un pago precancela o cambio estado manual a castigado de op con rubros diferidos
@w_monto_inter           money,          
@w_secuencial_inter      int,           -- JCHS secuencial ingresado en bancos
@w_param_ibtran          int,
@w_concepto              catalogo,
@w_return                int,
@w_sec_banco             INT,
@w_grupo_padre           int,           -- JCHS Variable número del grupo 
@w_causal                varchar(14),    -- KDR Causal para Bancos según Forma de Pago.
@w_secuencial_act        int,
@w_existe_tran_mig       char(1),
@w_fecha_mov_mig         datetime,
@w_secuencial_tran_mig   int,
@w_num_desembolso        tinyint,
@w_producto              catalogo,
@w_reverso_des_dias_ant  char(1),
@w_ssn_corr_fact         int,
@w_guid_dte_fact         varchar(36),
@w_sec_ing_abono_grupal  int,
@w_ssn_teller            int,
@w_ciclogrup             int --ODI_Error #262345

-- INICIALIZACION DE VARIABLES
select 
@w_sp_name                = 'sp_fecha_valor',
@w_es_liq                 = 'N',
@w_procesa                = 'N',
@w_secuencial_rpa         = -1,
@w_secuencial_pag         = -1,
@w_transaccion_pag        = 'N',
@w_tran_manual            = 'N',
@w_oper_fechaval          = 0,
@w_capitalizaciones       = 'N',
@w_secuencial_preferido   = null,
@w_utilizado_cupo         = 0,
@w_commit                 = 'N',
@w_fecha_valor            = null,
@w_monto_cap_RES          = 'N',
@w_dm_pagado              = 'I',
@sec_pag_rec              = 0,
@w_valida_trn             = 'S',
@w_tipo_grupal            = '' ,         --LPO TEC Reversa Grupal
@w_contador_seg           = 0,
@w_existe_tran_mig        = 'N'        

if @t_show_version = 1
begin
   print 'Stored Procedure ' + @w_sp_name + ' Version 1.0.0.1'  --para enlace
   return 0
end

--LPO TEC Se comenta, aplica en Santander pero No en Te Creemos.
/*
--Reverso de pago grupal
if @i_grupal = 'S' 
begin

    select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso 

    select 
    @w_corresponsal   = co_corresponsal,
    @w_tipo           = co_tipo,
    @w_operacionca    = co_codigo_interno,
    @w_fecha_valor    = co_fecha_valor,
    @w_referencia     = co_referencia,
    @w_moneda         = co_moneda,
    @w_estado         = co_estado,  
    @w_monto_pago     = co_monto,
    @w_trn_id_corresp = co_trn_id_corresp,
    @w_archivo_pago   = co_archivo_ref
    from ca_corresponsal_trn 
    where co_secuencial = @i_secuencial 
    
    if exists (select 1 from ca_corresponsal_trn where co_trn_id_corresp = isnull(@w_trn_id_corresp,'') and co_tipo = 'P' and co_accion = 'R' and co_estado in ('I','P')) 
    begin
        select @w_error = 141157
        goto ERROR
    end
    
    
    exec @w_error = sp_pagos_corresponsal 
    @s_ssn            = @s_ssn,
    @s_sesn           = @s_sesn,
    @s_user           = @s_user,
    @s_term           = @s_term,
    @s_ofi            = @s_ofi,
    @s_srv            = @s_srv,
    @s_lsrv           = @s_lsrv,
    @s_rol            = @s_rol,
    @s_org            = @s_org,
    @i_operacion      = 'I',
    @i_accion         = 'R',
    @i_corresponsal   = @w_corresponsal,
    @i_referencia     = @w_referencia,
    @i_moneda         = @w_moneda,
    @i_status_srv     = @w_status_srv,
    @i_archivo_pago   = @w_archivo_pago,
    @i_trn_id_corresp = @w_trn_id_corresp,
    @i_en_linea       = @i_en_linea,
    @o_msg            = @w_msg out
    
    if @w_error != 0 begin
        goto ERROR
    end
   
   return 0
end
*/ --LPO  TEC Se comenta, aplica en Santander pero No en Te Creemos.

/* VALIDACIÓN DE REVERSOS Y/O FECHA VALOR EN OPERACIONES MIGRADAS */

-- KDR Validar existencia de Secuencial cuando es Reverso
if @i_operacion = 'R' and (@i_secuencial is null or @i_secuencial <= 0)
begin
   select @w_error = 725322 -- Error, No se ha proporcionado secuencial de transacción a Reversar.
   goto ERROR
end

if exists(select 1 
          from ca_transaccion
          where tr_banco = @i_banco
          and   tr_tran  = 'MIG')
begin
   select @w_existe_tran_mig = 'S'

   select @w_fecha_mov_mig       = tr_fecha_mov,
          @w_secuencial_tran_mig = tr_secuencial
   from ca_transaccion
   where tr_banco = @i_banco
   and   tr_tran  = 'MIG'
end

if @w_existe_tran_mig = 'S' and @i_operacion = 'R'
begin
   if @i_secuencial < @w_secuencial_tran_mig
   begin
      select @w_error = 725160
      goto ERROR
   end
end

if @w_existe_tran_mig = 'S' and @i_operacion = 'F'
begin
   if @i_fecha_valor < @w_fecha_mov_mig
   begin
      select @w_error = 725161
      goto ERROR
   end
end


/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_anulado    = @w_est_anulado       out,
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado     out,
@o_est_castigado  = @w_est_castigado     out,
@o_est_vencido    = @w_est_vencido       out

select @w_secuencial_min = min(tr_secuencial)
from   ca_transaccion
where  tr_banco = @i_banco
and    tr_estado <> 'RV'   
and    tr_secuencial > 0

select @w_parametro_fval = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'FECVAL'
and    pa_producto = 'CCA'

select @w_oper_fechaval = op_operacion
from   ca_operacion
where  op_banco = @w_parametro_fval

select @w_moneda_nac = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

select @w_dias_contr = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'DFVAL'

if @@rowcount = 0 
begin
   select @w_error = 710215
   goto ERROR
end

select @i_observacion_corto = convert(char(62), @i_observacion)


select @w_param_ibtran = pa_int  from cobis..cl_parametro
WHERE pa_nemonico = 'IBTRAN'
AND pa_producto = 'CCA'


--- PARAMETRO ACTIVA VERIFICACION DE DATOS DE LA OBLIGACION S/N 
select @w_valida_trn = pa_char
from cobis..cl_parametro 
where pa_nemonico = 'VAL_FV' 
and   pa_producto = 'CCA'

--- PARAMETRO REVERSO DE DESEMBOLSO DE DIAS ANTERIORES 
select @w_reverso_des_dias_ant = pa_char
from cobis..cl_parametro 
where pa_nemonico = 'REDEDA' 
and   pa_producto = 'CCA'

if @w_valida_trn not in ('S','N') select @w_valida_trn = 'S'

-- VALIDAR LA EXISTENCIA DE LA OPERACION 
select 
@w_operacionca       = op_operacion,
@w_op_monto          = op_monto,
@w_fecha_ult_p       = op_fecha_ult_proceso,
@w_lin_credito       = op_lin_credito,
@w_toperacion        = op_toperacion,
@w_moneda            = op_moneda,
@w_cliente           = op_cliente,
@w_opcion            = op_tipo,   
@w_tramite           = op_tramite,
@w_ciudad            = op_ciudad,
@w_numero_comex      = op_num_comex,
@w_tipo_linea        = op_tipo_linea,
@w_lin_credito       = op_lin_credito,
@w_tipo              = op_tipo,
@w_oficina           = op_oficina,
@w_mora_retroactiva  = op_mora_retroactiva,
@w_estado_op         = op_estado,
@w_llave_redescuento = op_codigo_externo,
@w_op_validacion     = op_validacion,
@w_op_naturaleza     = op_naturaleza,
@w_fecha_ini         = op_fecha_ini     --SVA fecha valor menor
from   ca_operacion
where  op_banco  =  @i_banco
and    op_estado <> @w_est_novigente

if @@rowcount = 0 
begin
   select @w_error = 701025
   goto ERROR
end

--LPO TEC Reversa Grupal
/* DETERMINAR SI LA OPERACION CORRESPONDE A INTERCICLO - GRUPAL - INDIVIDUAL */
exec @w_error = sp_tipo_operacion
     @i_banco  = @i_banco,
     @i_en_linea = @i_en_linea,
     @o_tipo   = @w_tipo_grupal out

if @w_error <> 0 goto ERROR

--LRE 08Ago2019 
if @w_tipo_grupal = 'G'
   select @w_es_grupal = 'S'               


/* SI LA OPERACION ES DE INTERCICLO */
if @w_tipo_grupal = 'I' AND @i_operacion = 'F' --LPO TEC Reversa Grupal
begin
   /* DETERMINAR LA FECHA DE ULTIMO PROCESO DE LA OPERACION GRUPAL */
   select @w_fecha_ult_grupal = op_fecha_ult_proceso
   from   ca_operacion
   where  op_banco = (select dc_referencia_grupal from ca_det_ciclo where dc_operacion = @w_operacionca)

   /* SI LA FECHA VALOR DE LA OPERACION INTERCICLO ES MENOR A LA FECHA DE ULTIMO PROCESO DE LA OPERACION GRUPAL */
   if @i_fecha_valor < @w_fecha_ult_grupal 
   BEGIN
      select @w_error = 725057 /*ingresar codigo de error correspondiente*/
                               /*Fecha valor de operacion interciclo menor a fecha de ultimo proceso de operacion grupal. Debe reversar primero la operacion grupal*/
      goto ERROR 
   end
end
--LPO TEC FIN Reversa Grupal


-- FECHA DE PROCESO
select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

if @i_operacion = 'F' 
begin
   if (@i_fecha_valor < @w_fecha_ult_p) 
   begin
      if (@i_fecha_valor < @w_fecha_ini) --SVA fecha valor menor
      begin
         select @w_error = 710494
         goto ERROR
      end
            
      if (exists(select 1 from cobis..cl_dias_feriados 
                 where df_ciudad = (select pa_int from cobis..cl_parametro where pa_nemonico = 'CIUN' and pa_producto = 'ADM')
                 and   df_fecha  = @i_fecha_valor))
      begin
         select @w_error = 808069
         select @w_msg = 'Fecha no valida por dia feriado'
         goto ERROR
      end
   end
   
   if (@i_fecha_valor > @w_fecha_proceso) 
   begin
      select @w_error = 701192
      goto ERROR
   end
   
   select @i_secuencial = null 
   
   if (select count(1) from cob_cartera..ca_abono
		where ab_operacion = @w_operacionca
		and ab_estado <> 'RV'
		and ab_fecha_ing between @i_fecha_valor and @s_date) > 0
   begin
      select @w_error = 725291
      goto ERROR
   end
end   

--LPO TEC Reversa Grupal
/* SI LA OPERACIONM ES GRUPAL Y ES FECHA VALOR, EJECUTAR LAS REVERSAS DE PAGOS POSTERIORES AL FECHA VALOR */
if @w_tipo_grupal = 'G' and @i_operacion = 'F' and (@i_fecha_valor < @w_fecha_ult_p)
begin
   select @w_error = 0

   exec @w_error      = sp_reversa_grupal
        @s_user       = @s_user,
        @s_term       = @s_term,
        @s_srv        = @s_srv,  
        @s_date       = @s_date,
        @s_sesn       = @s_sesn,
        @s_ssn        = @s_ssn,
        @s_ofi        = @s_ofi,
        @s_rol        = @s_rol,
        @i_banco      = @i_banco,
        @i_fecha      = @i_fecha_valor

   if @w_error <> 0 goto ERROR

   /* ACTUALIZAR LOS DATOS DE LA OPERACION */
   select 
   @w_operacionca       = op_operacion,
   @w_op_monto          = op_monto,
   @w_fecha_ult_p       = op_fecha_ult_proceso,
   @w_lin_credito       = op_lin_credito,
   @w_toperacion        = op_toperacion,
   @w_moneda            = op_moneda,
   @w_cliente           = op_cliente,
   @w_opcion            = op_tipo,   
   @w_tramite           = op_tramite,
   @w_ciudad            = op_ciudad,
   @w_numero_comex      = op_num_comex,
   @w_tipo_linea        = op_tipo_linea,
   @w_lin_credito       = op_lin_credito,
   @w_tipo              = op_tipo,
   @w_oficina           = op_oficina,
   @w_mora_retroactiva  = op_mora_retroactiva,
   @w_estado_op         = op_estado,
   @w_llave_redescuento = op_codigo_externo,
   @w_op_validacion     = op_validacion,
   @w_op_naturaleza     = op_naturaleza
   from   ca_operacion
   where  op_banco = @i_banco
end

--LPO FIN TEC Reversa Grupal

--AGI TEC Reversa Prorroga Grupal
/* SI LA OPERACIONM ES GRUPAL Y ES FECHA VALOR, EJECUTAR LAS REVERSAS DE PRORROGAS POSTERIORES AL FECHA VALOR */
if @w_tipo_grupal = 'G' and @i_operacion = 'F' and (@i_fecha_valor < @w_fecha_ult_p)
begin
   select @w_error = 0

   exec @w_error      = sp_reversa_grupal_prorroga
        @s_user       = @s_user,
        @s_term       = @s_term,
        @s_srv        = @s_srv,  
        @s_date       = @s_date,
        @s_sesn       = @s_sesn,
        @s_ssn        = @s_ssn,
        @s_ofi        = @s_ofi,
        @s_rol        = @s_rol,
        @i_banco      = @i_banco,
        @i_fecha      = @i_fecha_valor

   if @w_error <> 0 goto ERROR

   /* ACTUALIZAR LOS DATOS DE LA OPERACION */
   select 
   @w_operacionca       = op_operacion,
   @w_op_monto          = op_monto,
   @w_fecha_ult_p       = op_fecha_ult_proceso,
   @w_lin_credito       = op_lin_credito,
   @w_toperacion        = op_toperacion,
   @w_moneda            = op_moneda,
   @w_cliente           = op_cliente,
   @w_opcion            = op_tipo,   
   @w_tramite           = op_tramite,
   @w_ciudad            = op_ciudad,
   @w_numero_comex      = op_num_comex,
   @w_tipo_linea        = op_tipo_linea,
   @w_lin_credito       = op_lin_credito,
   @w_tipo              = op_tipo,
   @w_oficina           = op_oficina,
   @w_mora_retroactiva  = op_mora_retroactiva,
   @w_estado_op         = op_estado,
   @w_llave_redescuento = op_codigo_externo,
   @w_op_validacion     = op_validacion,
   @w_op_naturaleza     = op_naturaleza
   from   ca_operacion
   where  op_banco = @i_banco
end

--AGI FIN TEC Reversa Grupal Prorroga


/* VERIFICAR SECUENCIAL DE PROCESO */
if @i_secuencial is not null begin
      
   select @w_secuencial_retro = @i_secuencial
         
end else begin

   select @w_secuencial_retro = isnull(min(tr_secuencial),999999999)
   from  ca_transaccion
   where tr_operacion   = @w_operacionca
   and   tr_fecha_ref  >= @i_fecha_valor
   and   tr_estado     in  ('ING','CON')
   and   tr_tran       not in ('RPA', 'HFM','PRV', 'TCO')
   and   tr_secuencial > @w_secuencial_min
end
      
if @w_secuencial_retro = 999999999 begin
      
   select 
   @w_fecha_retro    = @w_fecha_ult_p,
   @w_tran           = '',
   @w_tr_fecha_ref   = @w_fecha_ult_p,
   @w_estado_trn     = '',
   @w_tr_fecha_mov   = @w_fecha_ult_p,
   @w_fecha_retro    = @w_fecha_ult_p
         
end else begin

   -- DATOS DE LA TRANSACCION DE RETROCESO
   select 
   @w_tran           = tr_tran,
   @w_tr_fecha_ref   = tr_fecha_ref,
   @w_estado_trn     = tr_estado,
   @w_tr_fecha_mov   = tr_fecha_mov,
   @w_fecha_retro    = tr_fecha_ref
   from   ca_transaccion 
   where  tr_secuencial = @w_secuencial_retro
   and    tr_operacion  = @w_operacionca

   if @@rowcount = 0 begin
      select @w_error = 710494
      goto ERROR
   end
         
end

if @i_operacion = 'F' 
   select @w_fecha_valor = @i_fecha_valor
else 
begin
   select @w_fecha_valor =  @w_tr_fecha_ref--Se coloca otra vez ya que en reversas no borra PRV con fecha valor antes de la de proceso
   
    -- LGU-ini
   /* CONTROLAR QUE NO REVERSE EL PAGO QUE TIENE SOBRANTE */
   IF EXISTS(select 1
                from  ca_transaccion, ca_det_trn 
                where tr_operacion = @w_operacionca
                AND   tr_secuencial = @w_secuencial_retro
                and   tr_tran    = 'PAG'
                and   tr_estado != 'RV'
                and   dtr_operacion  = tr_operacion 
                and   dtr_secuencial = tr_secuencial
                and   dtr_concepto   = 'SOBRANTE'
                and   dtr_afectacion = 'C')
    BEGIN
      select @w_error = 701191
      goto ERROR
   end   
   -- LGU-fin
end


-- FQ CONTROL
select @w_saldo_cap_antes_fv = sum(am_acumulado - am_pagado)
from   ca_amortizacion
where  am_operacion = @w_operacionca
and    am_concepto  = 'CAP'
   
   
-- CONTROLES PARA PERMITIR O NO FECHA VALOR - REVERSOS
-- ***************************************************
select @w_dias_hoy = datediff(dd,@w_fecha_valor,@w_fecha_proceso)

if @w_dias_hoy > @w_dias_contr and @i_control_fecha = 'S' 
begin
   select @w_error = 710212
   goto ERROR
end

-- CONTROLES PARA REVERSOS POR PRECANCELACIONES DE DESEMBOLSOS
-- ***********************************************************
if @i_operacion = 'R' and @i_bandera = 'N'
BEGIN
   if exists(select 1 from cob_cartera..ca_transaccion 
   where tr_banco = @i_banco 
   and   tr_tran = 'PAG'
   and   (tr_observacion = 'RENOVACION' or tr_observacion = 'REESTRUCTURA'))
   begin
       select @w_error = 701220
       goto ERROR
   end
END

--AGI. TEC Reversa Prorroga Grupal/Inrterciclose
/* SI LA OPERACION ES DE INTERCICLO Y ES REVERSA DE PRORROGA, CON CONTROL DE REVERSA DE PRORROGA INTERCICLO */

if @w_tipo_grupal = 'I' and @i_operacion  = 'R' and @w_tran = 'PRO' and @i_control_pinter = 'S'
begin
   if exists (select 1 
              from   ca_secuencial_prorroga_grupal
              where  pg_operacion   = @w_operacionca
              and    pg_secuencial  = @w_secuencial_retro) 
   begin
      select @w_error = 77538 /*No se puede reversar prorroga de operacion de interciclo, debe hacerlo a traves de la grupal  */
      goto ERROR 
   end
end

/* SI LA OPERACION ES GRUPAL Y ES REVERSA DE PRORROGA, APLICAR LA REVERSA PRORROGA GRUPAL */
if @w_tipo_grupal = 'G' and @i_operacion  = 'R' and @w_tran = 'PRO'  and @i_control_pinter = 'S'
begin
   select @w_error = 0
   exec @w_error          = sp_reversa_prorroga_grupal
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_srv            = @s_srv,  
        @s_date           = @s_date,
        @s_sesn           = @s_sesn,
        @s_ssn            = @s_ssn,
        @s_ofi            = @s_ofi,
        @s_rol            = @s_rol,
        @i_banco          = @i_banco,
        @i_secuencial_ing = @w_secuencial_retro

   if @w_error = 0 
      return 0
   else 
      goto ERROR
end
--FIN AGI

--LPO TEC Reversa Grupal
/* SI LA OPERACION ES DE INTERCICLO Y ES REVERSA DE PAGO, CON CONTROL DE REVERSA DE PAGO INTERCICLO */
if @w_tipo_grupal = 'I' and @i_operacion  = 'R' and @w_tran = 'PAG' and @i_control_pinter = 'S'
begin
   if exists (select 1 
              from   ca_secuencial_pago_grupal, ca_abono
              where  pg_operacion      = ab_operacion
              and    ab_secuencial_ing = pg_secuencial_ing
              and    pg_operacion      = @w_operacionca
              and    pg_secuencial_ing = @w_secuencial_retro) 
   begin
      select @w_error = 725058 /*ingresar codigo de error correspondiente*/
                               /*No se puede reversar pago de operacion de interciclo, debe hacerlo a traves de la grupal  */
      goto ERROR 
   end
end

/* SI LA OPERACION ES GRUPAL Y ES REVERSA DE PAGO, APLICAR LA REVERSA GRUPAL */
if @w_tipo_grupal = 'G' and @i_operacion  = 'R' and @w_tran = 'PAG' and @i_control_pinter = 'S'
begin
   select @w_error = 0

   /* OBTENER EL SECUENCIAL PARA LA REVERSA */
   select @w_secuencial_rev = ab_secuencial_ing
   from   ca_abono
   where  ab_operacion      = @w_operacionca
   and    ab_secuencial_pag = @w_secuencial_retro

   exec @w_error          = sp_reversa_pago_grupal
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_srv            = @s_srv,  
        @s_date           = @s_date,
        @s_sesn           = @s_sesn,
        @s_ssn            = @s_ssn,
        @s_ofi            = @s_ofi,
        @s_rol            = @s_rol,
        @i_banco          = @i_banco,
        @i_secuencial_ing = @w_secuencial_rev

   if @w_error = 0 
      return 0
   else 
      goto ERROR
end
--LPO TEC FIN Reversa Grupal

--LRE 08/Ago/2019 VALIDACIONES PARA REVERSA DE DESEMBOLSO GRUPAL
--SI LA OPERACION ES DE INTERCICLO, NO SE PUEDE REVERSAR
/*if @w_tipo_grupal = 'I' AND @i_operacion = 'R'  and @w_tran = 'DES'
begin
      select @w_error = 725052 
      goto ERROR 
end
*/
-- SI LA OPERACION ES GRUPAL HIJA, NO SE PUEDE REVERSAR
if @i_operacion = 'R'  and @w_tran = 'DES'
   if exists(select 1
         from ca_operacion
         where op_banco = @i_banco     
          and op_grupal = 'S' 
          and op_ref_grupal is not null
          and op_operacion not in (select dc_operacion from ca_det_ciclo))
    begin
       select @w_error = 725053 
       goto ERROR 
    end

--FIN LRE 08/Ago/2019 VALIDACIONES PARA REVERSA DE DESEMBOLSO GRUPAL

-- PROCESO DE FECHA VALOR HACIA ATRAS (PUEDE SER REVERSA O FECHA VALOR)
if @w_fecha_valor < @w_fecha_ult_p or @i_operacion = 'R' begin   

   --- VALIDAR QUE NO SE PUEDA REVERSAR TRANSACCIONES DE CAJA A FECHA VALOR.     
   if @i_operacion = 'R' and @w_tran in( 'PAG','DES') begin
     if @i_es_atx = 'S' and @w_fecha_proceso <> @w_fecha_retro and @i_pago_ext = 'N' 
     begin
        select @w_error = 724520 -- la reversa debe ser HOY desde Caja, Manana desde Cartera
        goto ERROR 
     end
   end      
      
      ---   VERIFICA QUE NO EXISTA OTRAS OPERACIONES MANUALES
   if exists (select 1
   from   ca_transaccion
   where  tr_operacion   = @w_operacionca
   and    ((tr_secuencial >= @w_secuencial_retro and @i_operacion = 'F') or (tr_secuencial > @w_secuencial_retro and @i_operacion = 'R'))
   and    tr_estado     <> 'RV'
   and    tr_tran       in ('DES', 'RES', 'REN', 'ETM','PRO', 'AJP', 'MPC',  'SUM', 'ACE', 'CAS', 'MAN', 'TLI','PNO', 'DIF'))
   begin
      select @w_error = 710075 
      goto ERROR
   end      
   
   --LPO TEC Reversa Grupal
   /* SI LA OPERACION ES DE INTERCICLO O GRUPAL VERIFICAR QUE NO EXISTA PAGOS O CONDONACIONES POSTERIORES */
   if @w_tipo_grupal in ('I', 'G')
   begin
      if exists (select 1
                 from   ca_transaccion
                 where  tr_operacion = @w_operacionca
                 and    ((tr_secuencial >= @w_secuencial_retro and @i_operacion = 'F') or (tr_secuencial > @w_secuencial_retro and @i_operacion = 'R'))
                 and    tr_estado     <> 'RV'
                 and    tr_tran       in ('PAG', 'CON'))
      begin
         select @w_error = 708216 /*ingresar codigo de error correspondiente*/
                                  /*Existe pagos o condonaciones posteriores en operacion Grupal o Interciclo*/
         goto ERROR
      end      
   end
   --LPO TEC FIN Reversa Grupal

   -- VERIFICA QUE NO EXISTAN PAGOS AL REVERSAR EL PRIMER DESEMBOLSO
   if  @i_operacion  = 'R'
   and @w_secuencial_min = @i_secuencial
   and exists (select 1
   from   ca_transaccion
   where  tr_banco      = @i_banco 
   and    tr_estado     <> 'RV'
   and    tr_tran       = 'RPA'
   and    tr_secuencial > 0)
   begin
      select @w_error = 710133
      goto ERROR
   end  
      
            
   -- VERIFICAR LA EXISTENCIA DEL HISTORICO 
   if @w_tran not in ('HFM', 'DES', 'MIG') 
   begin
    
      select @w_tran_manual = 'N'

      if @w_tran  in ('DES','RES', 'REN', 'PRO','AJP','MPC','ETM','SUM','ACE','CAS','MAN', 'TLI','PNO') and @i_operacion = 'R'
         select @w_tran_manual = 'S'

   end
  
   select @w_monto_cap_pag_rv_ini = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       in ('PAG', 'CON', 'PRN')
   and    tr_estado     = 'RV'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = -tr_secuencial
   and    dtr_concepto   = 'CAP'
   and    dtr_codvalor <> 10017
   and    dtr_codvalor <> 10027
   and    dtr_codvalor <> 10097
   and    dtr_codvalor <> 10047
   and    dtr_codvalor <> 10080
   
   select @w_monto_cap_des_rv_ini = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'DES'
   and    tr_estado     = 'RV'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = -tr_secuencial
   and    dtr_concepto   = 'CAP'
   
   select @w_monto_cap_crc_rv_ini = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'CRC'
   and    tr_estado     = 'RV'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = -tr_secuencial
   and    dtr_concepto   = 'CAP'
   
   -- MONTO DE LOS PAGOS QUE SE VAN A REVERSAR
   select @w_monto_cap_pag = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       in ('PAG', 'CON', 'PRN')
   and    tr_estado     in ('CON', 'ING')
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = tr_secuencial
   and    dtr_codvalor <> 10017
   and    dtr_codvalor <> 10027
   and    dtr_codvalor <> 10097
   and    dtr_codvalor <> 10047
   and    dtr_codvalor <> 10080
   and    dtr_concepto   = 'CAP'
   
   -- MONTO DE LOS DESEMBOLSOS QUE SE VAN A REVERSAR
   select @w_monto_cap_des = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'DES'
   and    tr_estado     in ('CON', 'ING')
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = tr_secuencial
   and    dtr_concepto   = 'CAP'
   
   select @w_monto_cap_crc = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'CRC'
   and    tr_estado     in ('CON', 'ING')
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = tr_secuencial
   and    dtr_concepto   = 'CAP'
   
   -- MONTO DE LOS PAGOS QUE SE VAN A REVERSAR PERO QUE ESTAN ING
   select @w_monto_cap_pag_ing = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       in ('PAG','CON', 'PRN')
   and    tr_estado     = 'ING'
   and    dtr_codvalor <> 10017
   and    dtr_codvalor <> 10027
   and    dtr_codvalor <> 10047
   and    dtr_codvalor <> 10097
   and    dtr_codvalor <> 10080
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = tr_secuencial
   and    dtr_concepto   = 'CAP'
   
   -- MONTO DE LOS DESEMBOLSOS QUE SE VAN A REVERSAR PERO QUE ESTAN ING
   select @w_monto_cap_des_ing = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'DES'
   and    tr_estado     = 'ING'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = tr_secuencial
   and    dtr_concepto   = 'CAP'
   
   select @w_monto_cap_crc_ing = isnull(sum(dtr_monto), 0)
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'CRC'
   and    tr_estado     = 'ING'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = tr_secuencial
   and    dtr_concepto   = 'CAP'
   
   if exists (select 1
   from   ca_transaccion, ca_det_trn
   where  tr_operacion    = @w_operacionca
   and    tr_tran         = 'RES'
   and    tr_estado      in ('CON', 'ING')
   and    dtr_operacion   = tr_operacion
   and    dtr_secuencial  = tr_secuencial
   and    dtr_concepto   <> 'CAP'  
   and    tr_secuencial   > 0
   and    dtr_estado     <> 37 )
   begin
      select @w_monto_cap_RES  ='S'
   end
   
   if @@trancount = 0 
   begin 
      begin tran
      select @w_commit = 'S'
   end
   
   -- KDR-20/08/2021 REVERSO DE COMISIONES DIFERIDAS (REGISTRO DE CONTROL Y DEVENGAMIENTO) 
   if @i_operacion  = 'R' --and @w_tran in ('PAG', 'DES', 'ETM')
   begin
      IF EXISTS (SELECT 1 from ca_rubro_op
      WHERE ro_operacion = @w_operacionca
      AND ro_limite = 'S')
      begin
      
         if @w_tran = 'DES'
         begin
            select @w_tiene_rub_dif  = 'S'
         end
      
         if @w_tran = 'PAG'
         begin    
         select @w_max_secuencial_diferido = max(tr_secuencial) FROM ca_transaccion, ca_operacion
         WHERE tr_operacion = @w_operacionca     
            AND tr_operacion = op_operacion
            AND tr_tran      = 'PAG'
            AND tr_estado    <> 'RV'
            AND tr_fecha_ref < op_fecha_fin
            AND op_estado = @w_est_cancelado
            
            IF @w_max_secuencial_diferido = @w_secuencial_retro
            select @w_tiene_rub_dif  = 'S'
         end
         
      if @w_tran = 'ETM'
         begin
         select @w_max_secuencial_diferido = max(tr_secuencial) FROM ca_transaccion, ca_det_trn
         WHERE tr_operacion = @w_operacionca      
            AND tr_operacion = dtr_operacion
            AND tr_tran = 'ETM'
            AND tr_estado <> 'RV'
            AND tr_secuencial = dtr_secuencial
         AND (dtr_codvalor - (dtr_codvalor /1000)*1000)/10 = @w_est_castigado
         
            IF @w_max_secuencial_diferido = @w_secuencial_retro
            select @w_tiene_rub_dif  = 'S'         
         end       
      end
   end

   -- PONER LOS HISTORICOS EN LAS TABLAS DEFINITIVAS
   if @w_secuencial_retro <> 999999999 
   begin 
         exec @w_error  = sp_historia_def
         @i_operacionca = @w_operacionca,  
         @i_secuencial  = @w_secuencial_retro,
         @i_tiene_rub_dif    = @w_tiene_rub_dif    -- KDR-20/08/2021 Bandera si la operacion tiene rubros diferidos
      
         if @w_error  <> 0 
            goto ERROR    
   end 
   
   --VALIDAR LA CONSISTENCIA DE LA TABLA DE AMORTIZACION
   --UNA VEZ SE CARGUE HISTORICOS
   
   select @w_rev_des = 'N'

   if exists(select 1
   from   ca_operacion
   where  op_operacion = @w_operacionca
   and    op_estado = 0)
   begin
      select @w_saldo_cap_despues_fv = 0,
      @w_rev_des = 'S'

   end else  begin

      select @w_saldo_cap_despues_fv = sum(am_acumulado - am_pagado)
      from   ca_amortizacion
      where  am_operacion = @w_operacionca
      and    am_concepto  = 'CAP'
   end
      
    if @w_valida_trn = 'S' 
    begin         
        --AGI 13JUN19-  se convierte en varchar por tema de decimales
        if (convert(varchar,@w_saldo_cap_despues_fv + @w_monto_cap_des - @w_monto_cap_pag + @w_monto_cap_crc) <> convert(varchar,@w_saldo_cap_antes_fv) 
             and @w_rev_des = 'N' and @w_fecha_retro <> '03/01/2004' and @w_tran_manual = 'N' 
             and @w_operacionca <>  @w_oper_fechaval and  @w_monto_cap_RES ='N' )
        begin
            if @i_pago_ext = 'N'
            begin
                select @w_mensaje = 'saldo despues ' + cast(@w_saldo_cap_despues_fv as varchar)
                select @w_mensaje = @w_mensaje + ', DES=' + cast(@w_monto_cap_des as varchar)
                select @w_mensaje = @w_mensaje + ', PAG=' + cast(@w_monto_cap_pag as varchar)
                select @w_mensaje = @w_mensaje + ', CRC=' + cast(@w_monto_cap_crc as varchar)
                select @w_mensaje = @w_mensaje + ', antes=' + cast(@w_saldo_cap_antes_fv as varchar)
                select @w_mensaje = @w_mensaje + ', sec=' + cast(@w_secuencial_retro as varchar)
            end
            select @w_error = 710553
            goto ERROR        
        end    
    end

   if @i_operacion = 'F' and @w_fecha_retro > @w_fecha_valor begin

	  -- Actualiza los dias gracia disponible, cuando se aplica fecha valor a una fecha entre el vencimiento del dividendo 
	  -- vencido más recientey antes de generar la mora retroactiva
      update ca_dividendo with (rowlock)
      set di_gracia_disp = case when datediff(dd, di_fecha_ven, @w_fecha_valor) between 0 and di_gracia then di_gracia - datediff(dd, di_fecha_ven, @w_fecha_valor) else -1 end
      where di_operacion = @w_operacionca
      and   di_estado    = @w_est_vencido
      and   di_gracia    > 0
	  
      if @@error <> 0 begin
          select @w_error  = 710002
          goto ERROR
      end  
	  
      -- Actualiza los días gracia y dias gracia disponible, cuando se aplica fecha valor desde una fecha último proceso igual o
      -- superior de haber generado la mora retroactiva en donde el di_gracia pasó a tener los días de gracia en negativo.
      update ca_dividendo with (rowlock)
      set di_gracia      = di_gracia *-1,
          di_gracia_disp = ((di_gracia*-1)  - datediff(dd, di_fecha_ven, @w_fecha_valor))
      where di_operacion = @w_operacionca
      and   di_estado    = @w_est_vencido
      and   datediff(dd, di_fecha_ven, @w_fecha_valor) <= (di_gracia*-1)
      
      if @@error <> 0 begin
          select @w_error  = 710002
          goto ERROR
      end  
 
      /* INICIALIZAMOS EL CONTADOR DE INTENTOS */
      update ca_dividendo set
      di_intento = 0
      where di_operacion = @w_operacionca
      and   di_estado    = @w_est_vencido
 
      if @@error <> 0 begin
         select @w_error  = 710002
         goto ERROR
      end 
         
      if (@i_debug = 'S') 
         print '@w_fecha_valor :'+convert(varchar, @w_fecha_valor) 
      if (@i_debug = 'S') 
         print '@w_fecha_retro :'+convert(varchar, @w_fecha_retro)  
       
      
      select    
      operacion = tp_operacion, 
      dividendo = tp_dividendo, 
      concepto  = tp_concepto ,
      secuencia = tp_secuencia,
      monto     = isnull(sum(tp_monto),0)
      into #reverso
      from ca_transaccion_prv
      where tp_operacion = @w_operacionca
      and   tp_monto     > 0
      and   tp_estado   in ('CON','ING')
      and   tp_secuencial_ref =0  --EVITAR CONSIDERAR TRANSACCIONES PRV ASOCIADAS A PAGOS EXTRAORDINARIOS
      and   tp_fecha_ref >= @w_fecha_valor -- KDR tp_fecha_ref > @w_fecha_valor
      and   tp_fecha_ref <  @w_fecha_retro -- KDR tp_fecha_ref <=  @w_fecha_retro
      group by tp_operacion,tp_dividendo,tp_concepto,tp_secuencia
         
      /* AJUSTANDO EL VALOR DE PROVISIONES DIARIAS, EN LA MORA EL PROYECTADO ES IGUAL QUE EL ACUMULADO */
      update ca_amortizacion set
      am_acumulado = am_acumulado - monto,
     am_cuota     = case when ro_tipo_rubro = 'M' then am_cuota - monto else am_cuota end
      from #reverso, ca_rubro_op
      where am_operacion = @w_operacionca
      and   am_operacion = operacion
     and   operacion    = ro_operacion
      and   am_dividendo = dividendo
      and   am_concepto  = concepto
     and   concepto     = ro_concepto
      and   am_secuencia = secuencia
      
      if @@error <> 0 begin
         select @w_error  = 710002
         goto ERROR
      end
        
      /* AJUSTANDO LA FECHA DE ULTIMO PROCESO DE LA OPERACION*/
      update ca_operacion set
      op_fecha_ult_proceso = @w_fecha_valor
      where op_operacion = @w_operacionca
      
      if @@error <> 0 begin
            select @w_error  = 710002
            goto ERROR
      end 
   end -- END  operacion = F


   /* PROGRAMACION SOLO PARA REVERSAS */
   if @i_operacion = 'R' begin
	   
	   if (@w_tran = 'PAG' and
		 (select count(1)
		 from ca_transaccion
		 where tr_operacion = @w_operacionca
		 and tr_tran = 'PAG'
		 and tr_estado <> 'RV'
		 and tr_secuencial > @i_secuencial) > 0)
	  begin
	      select @w_error = 725292
	      goto ERROR
      end
   
      /* SECCION PARA INCLUIR ACCIONES CUANDO REVERSAMOS TRASLADO DE OFICINAS */  
      if @w_tran = 'TCO' begin
        delete ca_traslados_cartera
        where  trc_secuencial_trn = @i_secuencial
        and    trc_operacion      = @w_operacionca
        
        if @@error <> 0 
           begin
             select @w_error = 710003
             goto ERROR
           end
      end


      /* SECCION PARA INCLUIR ACCIONES CUANDO REVERSAMOS EL INGRESO DE OTROS CARGOS */  
      if  @w_tran = 'IOC' begin
      
         delete ca_otro_cargo
         where oc_operacion = @w_operacionca
         and   oc_secuencial = @i_secuencial
      
         if @@error <> 0 begin 
            select @w_error = 710003
            goto ERROR
         end
      
      end

      /* SECCION PARA INCLUIR ACCIONES CUANDO REVERSAMOS TRANSACCIONES DE REESTRUCTURACION */
      if  @w_tran = 'RES' begin
      
         /*
         update ca_datos_reestructuraciones_cca
         set res_estado_tran = 'RV'
         where res_operacion_cca  = @w_operacionca
         and   res_secuencial_res = @i_secuencial
      
         if @@error <> 0 begin 
            select @w_error = 710002
            goto ERROR
         end         
         */
         /* REVERSO DE PAGOS ASOCIADOS A LAS REESTRUCTURACIONES */          
         select @w_tramite_res = 0

         select @w_tramite_res = or_tramite
         from   cob_credito..cr_op_renovar
         where  or_num_operacion = @i_banco
         and    or_sec_prn       = @i_secuencial

         if isnull(@w_tramite_res,0) <> 0
         begin

            declare operacion_pag_reest cursor for
            select tr_secuencial,tr_banco from ca_transaccion
            where tr_banco in (select or_num_operacion 
                               from   cob_credito..cr_op_renovar
                               where  or_tramite  = @w_tramite_res
                               and    or_base     = 'N')
            and tr_tran        = 'PAG'
            and tr_estado      in ('ING', 'CON')
            and tr_observacion = 'REESTRUCTURA'
            
            open  operacion_pag_reest
            
            fetch operacion_pag_reest into @w_secuencial_ren, @w_operacion_ren
                  
            while (@@fetch_status = 0) begin 
            
               exec @w_error    = sp_fecha_valor 
               @s_ssn           = @s_ssn,
               @s_srv           = @s_srv,
               @s_user          = @s_user,
               @s_term          = @s_term,
               @s_date          = @s_date,
               @s_ofi           = @s_ofi,
               @i_banco         = @w_operacion_ren,
               @i_secuencial    = @w_secuencial_ren,
               @i_en_linea      = @i_en_linea,
               @i_operacion     = 'R',
               @i_bandera       = 'S'
                     
               if @w_error <> 0 begin 
                     close operacion_pag_reest --cursor_afecta_productos 
                  deallocate operacion_pag_reest --cursor_afecta_productos 
                  goto ERROR
               end
            
               fetch operacion_pag_reest into  @w_secuencial_ren, @w_operacion_ren
            end -- END WHILE
            
            close operacion_pag_reest --cursor_afecta_productos 
            deallocate operacion_pag_reest --cursor_afecta_productos 
         end

         --Eliminar garantias atadas a la operacion final provenientes de operaciones canceladas en la reestructura
         delete cob_credito..cr_gar_propuesta 
         from ca_operacion
         where op_operacion = @w_operacionca
         and   op_tramite   = gp_tramite
         and   gp_garantia in ( select gp_garantia
                                from cob_credito..cr_op_renovar, ca_operacion, cob_credito..cr_gar_propuesta
                                where or_tramite = @w_tramite_res
                                and   or_base     = 'N'
                                and   op_banco = or_num_operacion
                                and   op_tramite = gp_tramite
                                and   gp_est_garantia not in ('A','C')
                               )
         if @@error <> 0 begin
            select @w_error = 710003
            goto ERROR
         end

         update cob_credito..cr_op_renovar
         set   or_finalizo_renovacion = 'Z'   --anulado o reversado
         where or_tramite = @w_tramite_res
         
         if @@error != 0
         begin
           select @w_error = 705075
           goto ERROR
         end         

      end
 
      /* SECCION PARA INCLUIR ACCIONES CUANDO REVERSAMOS TRANSACCIONES DE CASTIGO */
      if @w_tran = 'ETM' begin
      
         if not exists(select 1 from ca_operacion
         where op_cliente    = @w_cliente
         and   op_operacion != @w_operacionca 
         and   op_estado     = @w_est_castigado) 
         begin
         
            select @w_in_origen = codigo
            from   cobis..cl_catalogo
            where  tabla = (select codigo from  cobis..cl_tabla where  tabla = 'cl_refinh')
            and    valor = 'CLIENTES CASTIGADOS'
      
            select @w_in_ced_ruc = en_ced_ruc
            from cobis..cl_ente 
            where en_ente = @w_cliente
            
            delete from cobis..cl_refinh 
            where in_ced_ruc = @w_in_ced_ruc 
            and in_origen = @w_in_origen
        
            if @@error <> 0 begin
               select @w_error = 710003 -- KDR Correccion código
               goto ERROR
            end         
      
         end
        
      end   --FIN CASTIGOS (ETM)

      /* SECCION PARA INCLUIR ACCIONES CUANDO REVERSAMOS EL PRIMER DESEMBOLSO */
      if @w_tran = 'DES' and  @w_secuencial_min = @i_secuencial begin ---el primer desembolso
        
         delete ca_deudores_tmp
         where dt_operacion = @w_operacionca
         
         if @@error <> 0 begin 
            select @w_error = 710003
            goto ERROR
         end
         
         
         if exists (select 1 from ca_normalizacion where nm_tramite = @w_tramite )
         begin     
         
            delete  ca_normalizacion
            where nm_tramite = @w_tramite
            
            if @@error <> 0 begin
               select @w_error  = 701157
               goto ERROR
            end  
            
            delete ca_diferidos
            where dif_operacion = @w_operacionca
            
            if @@error <> 0 begin
               select @w_error  = 701157
               goto ERROR
            end    
         end
         
         delete from cob_cartera..ca_seguros_det where sed_operacion = @w_operacionca
         
         if @@error <> 0 begin
            select @w_error  = 708155
            goto ERROR
         end    
         
         delete from cob_cartera..ca_seguros where se_operacion = @w_operacionca
         
         if @@error <> 0 begin
            select @w_error  = 708155
            goto ERROR
         end 
         

         /* REVERSO DE PAGOS ASOCIADOS A LAS RENOVACIONES */            
         if exists (select 1 from   ca_operacion,  cob_credito..cr_op_renovar
         where  op_banco   = or_num_operacion
         and    or_tramite = @w_tramite
         and    op_estado  = 3)
         begin

            declare operacion_pag_rev cursor for
            select tr_secuencial,tr_banco from ca_transaccion
            where tr_banco in (select op_banco 
                               from   ca_operacion,  cob_credito..cr_op_renovar
                               where  op_banco   = or_num_operacion
                               and    or_tramite = @w_tramite
                               and    op_estado  = 3)
            and tr_tran = 'PAG'
            and tr_estado in ('ING', 'CON')
            and tr_observacion = 'RENOVACION'
            
            open  operacion_pag_rev
            
            fetch operacion_pag_rev into @w_secuencial_ren, @w_operacion_ren
                  
            while (@@fetch_status = 0) begin 
            
               exec @w_error    = sp_fecha_valor 
               @s_ssn           = @s_ssn,
               @s_srv           = @s_srv,
               @s_user          = @s_user,
               @s_term          = @s_term,
               @s_date          = @s_date,
               @s_ofi           = @s_ofi,
               @i_banco         = @w_operacion_ren,
               @i_secuencial    = @w_secuencial_ren,
               @i_en_linea      = @i_en_linea,
               @i_operacion     = 'R',
               @i_bandera       = 'S'
                     
               if @w_error <> 0 begin 
                  close operacion_pag_rev --cursor_afecta_productos 
                  deallocate operacion_pag_rev --cursor_afecta_productos 
                  goto ERROR
               end
            
               fetch operacion_pag_rev into  @w_secuencial_ren, @w_operacion_ren
            end -- END WHILE
            
            close operacion_pag_rev --cursor_afecta_productos 
            deallocate operacion_pag_rev --cursor_afecta_productos 
         end   

            
         delete ca_abono_det
         from   ca_abono
         where  abd_operacion      = @w_operacionca
         and    abd_operacion      = ab_operacion
         and    abd_secuencial_ing = ab_secuencial_ing
         and    ab_secuencial_pag  > @w_secuencial_retro
         
         if @@error <> 0 begin
            select @w_error = 710003 
            goto ERROR
         end
         
         delete ca_abono
         where  ab_operacion = @w_operacionca
         and    ab_secuencial_pag  > @w_secuencial_retro
         
         if @@error <> 0 begin
            select @w_error = 710003
            goto ERROR
         end
                 
         delete ca_tasas
         where  ts_operacion = @w_operacionca
         
         if @@error <> 0 begin
            select @w_error = 710003
            goto ERROR
         end
         
         delete ca_ultima_tasa_op
         where ut_operacion = @w_operacionca   
         
         if @@error <> 0  begin
            select @w_error = 710003
            goto ERROR
         end    
         --LCA CDIG Activacion-Reversa Pignoracion INICIO
         --REVERSO DE ACTIVACION DE GARANTIAS
         
         exec @w_error = cob_custodia..sp_activar_garantia
           @i_opcion    = 'R',
           @s_date      = @s_date,
           @i_tramite   = @w_tramite,
           @i_modo      = 1,
           @i_operacion = 'I',
           @s_ssn       = @s_ssn,
           @s_user      = @s_user,
           @s_term      = @s_term,
           @s_ofi       = @s_ofi
           
         if @w_error != 0 begin
            goto ERROR
         end
         
         --LCA CDIG Activacion-Reversa Pignoracion FIN
         
         --LPO CDIG Multimoneda Reversa INICIO
         /* DETERMINAR SI DEBE REALIZARSE LA REVERSA DE LA TRANSACCION TRIBUTARIA DE CAMBIO DE DIVISAS */
         select @w_sec_divisas = tr_dias_calc
         from   ca_transaccion 
         where  tr_operacion  = @w_operacionca
         and    tr_secuencial = @w_secuencial_retro
         and    tr_tran       = 'DES'
         
         select @w_sec_divisas = isnull(@w_sec_divisas, 0)
         
         
         /* PROCESAR REVERSA DE TRANSACCION TRIBUTARIA DE DIVISAS */
         if @w_sec_divisas > 0
         begin
            select @w_sec_reversa = isnull(trd_sec_divisas,0)
            from   ca_tran_divisas 
            where  trd_operacion  = @w_operacionca
            and    trd_secuencial = @w_secuencial_retro 
            
            if @w_sec_reversa > 0
            begin
               exec @w_error       = cob_cartera..sp_op_divisas_automatica
                    @s_date          = @s_date,        /* Fecha del sistema                                                         */
                    @s_user          = @s_user,        /* Usuario del sistema                                                       */
                    @s_ssn           = @s_ssn,         /* Secuencial Transaccion                                                    */
                    
                    @i_oficina       = @s_ofi,         /* Oficina donde debe ser registrada la transaccion.  Afectar  contablemente */
                    @i_cliente       = @w_cliente,     /* Codigo del cliente a nombre de quien se realiza la operacion de divisas   */
                    @i_modulo        = 'CCA',          /* Nemonico del modulo COBIS que origina la operacion de divisas             */
                    @i_operacion     = 'R',            /* C - Consulta, E - Ejecucion normal , R - Reversar una operacion anterior  */
                    @i_secuencial    = @w_sec_reversa, /* SSN de la operacion normal.  Usado para reversos                          */
                    @i_batch         = @i_en_linea,
                    @i_empresa       = 1,
                    @i_num_operacion = @i_banco,
                    --@i_producto      = 7,              -- Producto Cartera. 
                    @i_masivo        = 'L'             
               
               if @w_error <> 0
               begin
                  select @w_error = @w_error
                  goto ERROR                
               end
            end
         end
         --LPO CDIG Multimoneda Reversa FIN
        
         /* CONTROL DE ESTADO */
         if exists(select 1 from ca_operacion
         where  op_operacion = @w_operacionca
         and    op_estado    <> 0) -- NO QUEDO EN ESTADO VIGENTE
         begin
            select @w_error = 710554
            goto ERROR
         end    

     --SI HAY REVERSO  DEL DESEMBOLSO ELIMINAN LOS REGISTROS 
         --DE DISTRIBUCION DE GARANTIAS PARA ESTE TRAMITE
         if exists(select 1
         from   ca_seguros_base_garantia
         where  sg_tramite = @w_tramite) 
         begin
            delete ca_seguros_base_garantia
            where sg_tramite = @w_tramite
         end            
         
         select @w_es_liq = 'S'
            
      end --FIN SOLO PRIMER DESEMBOLSO
            
            
      /* SECCION PARA INCLUIR ACCIONES CUANDO REVERSAMOS UN DESEMBOLSO SIN IMPORTAR QUE SEA EL PRIMERO O UNO PARCIAL */
      if @w_tran = 'DES'  begin 
      
	     if(@w_tr_fecha_mov < @s_date and @w_reverso_des_dias_ant = 'N' )
		 begin
		     select @w_error = 725290 --ERROR, NO SE PERMITE REVERSAR DESEMBOLSOS DE DÍAS ANTERIORES
			 goto ERROR
		 end
	  
         --LRE 29/Jul/2019 Reversa del Desembolso de Operaciones Grupales
         if @w_tipo_grupal = 'G'
         begin
           --Cursor para Consultar las operaciones Interciclo relacionadas al prestamo grupal
           declare cursor_interciclos cursor
           for 
           select op_banco, op_operacion
           from cob_cartera..ca_operacion x
           where op_ref_grupal  = @i_banco 
           and   op_grupal = 'N'
           and   op_operacion in (select dc_operacion from cob_cartera..ca_det_ciclo 
                                   where dc_referencia_grupal = x.op_ref_grupal and dc_tciclo = 'I')
           and   op_estado not in (0,99,3)
            
           for read only
                                                                                                                                                                                                                                           
           open  cursor_interciclos
           fetch cursor_interciclos into  @w_banco_interc, @w_op_interc
                                                                                                                                                                                                      

           while @@fetch_status = 0
           begin
                                                                                                                                                                                                                                                         
              if (@@fetch_status = -1)
                  return 710004

               --Obtener el secuencial del desembolso de la operación interciclo
               select @w_sec_des_interc = tr_secuencial
               from cob_cartera..ca_transaccion
               where tr_operacion = @w_op_interc
               and   tr_tran      = 'DES'
               and   tr_estado    <> 'RV'


               exec @w_error    = sp_fecha_valor 
               @s_ssn           = @s_ssn,
               @s_srv           = @s_srv,
               @s_user          = @s_user,
               @s_term          = @s_term,
               @s_date          = @s_date,
               @s_ofi           = @s_ofi,
               @i_banco         = @w_banco_interc,
               @i_secuencial    = @w_sec_des_interc,
               @i_en_linea      = @i_en_linea,
               @i_operacion     = 'R',
               @i_bandera       = 'S'
                     
               if @w_error <> 0 begin 
                  close cursor_interciclos 
                  deallocate cursor_interciclos 
                  goto ERROR
               end

            --Reversa seguros y ordenes de pago de Operacion Interciclo
            exec @w_error = sp_reversa_desem_grupal
                 @s_ssn            = @s_ssn,
                 @s_sesn           = @s_sesn,
                 @s_user           = @s_user,
                 @s_date           = @s_date,
                 @s_ofi            = @s_ofi,
                 @i_banco          = @w_banco_interc,
                 @i_secuencial     = @w_sec_des_interc,
                 --@i_secuencial_seg = @w_secuencia_seguro,
                 @i_es_interciclo  = 'S',
                 @i_fecha_proceso  = @w_fecha_proceso
    
           if @w_error <> 0 
           begin
              close cursor_interciclos 
              deallocate cursor_interciclos 
              goto ERROR   
           end



           fetch cursor_interciclos into  @w_banco_interc, @w_op_interc
          end --while
      close cursor_interciclos 
          deallocate cursor_interciclos 

           --Reversa seguros y ordenes de pago de Operacion Grupal
            exec @w_error = sp_reversa_desem_grupal
                 @s_ssn            = @s_ssn,
                 @s_sesn           = @s_sesn,
                 @s_user           = @s_user,
                 @s_date           = @s_date,
                 @s_ofi            = @s_ofi,
                 @i_banco          = @i_banco,
                 @i_secuencial     = @w_secuencial_retro,
                 --LRE 03Ago@i_secuencial_seg = @w_secuencia_seguro,
                 @i_es_interciclo  = 'N',
                 @i_fecha_proceso  = @w_fecha_proceso
    
        if @w_error <> 0 
        begin
              close cursor_interciclos 
              deallocate cursor_interciclos 
              goto ERROR   
        end


         end
         --FIN LRE 29/Jul/2019 Reversa del Desembolso de Operaciones Grupales

         -- REVERSAR INTANT  EN TABLA DE AMORTIZACION_ANT
         if exists (select 1 from   ca_amortizacion_ant
         where  an_secuencial >= @w_secuencial_retro
         and    an_operacion  = @w_operacionca) 
         begin
            delete ca_amortizacion_ant
            where  an_secuencial >= @w_secuencial_retro
            and    an_operacion  = @w_operacionca 
         end
         
         if @w_tipo <> 'R' begin
        
            if exists (select 1
            from ca_relacion_ptmo   
            where rp_activa = @w_operacionca)
            begin
               delete ca_relacion_ptmo   
               where rp_activa = @w_operacionca
            end
         
         end else begin
        
            if exists (select 1
            from ca_relacion_ptmo   
            where rp_pasiva = @w_operacionca)
            begin
               delete ca_relacion_ptmo   
               where rp_pasiva = @w_operacionca
            end
         
         end

           
         -- AFECTACION A OTROS PRODUCTOS
         declare
         cursor_afecta_prod cursor  for select 
         cp_producto_reversa,  dm_monto_mds,  dm_cuenta,  
         isnull(cp_pcobis,0),  dm_moneda,     dm_cotizacion_mds,
         cp_codvalor,          dm_idlote,     dm_desembolso
         from   ca_desembolso, ca_producto 
         where  dm_operacion   = @w_operacionca
         and    dm_secuencial  = @w_secuencial_retro
         and    cp_producto    = dm_producto               
         and    cp_pcobis      is not null 
         and    cp_pcobis      <> 7
         for read only
         
         open cursor_afecta_prod 
         
         fetch cursor_afecta_prod
         into  @w_prod_rev,         @w_monto,       @w_cuenta,
               @w_pcobis,           @w_moneda_trn,  @w_cotizacion_trn,
               @w_codvalor_mpg,     @w_idlote    ,  @w_dm_desembolso
         
         while (@@fetch_status = 0) begin            
            
            --UNICAMENTE ENTRA SI DEBE REVERSAR OTROS PRODUCOTS DE COBIS
            --COMO CUENTA , AHORROS, 
            if @w_pcobis in (3,4,9,19,42) 
            begin
               if @w_pcobis = 9 select @w_cuenta = @i_banco

               if @w_tran = 'DES'   --LRE 21Ago2019
                  select @w_oficina_ifase = @w_oficina
               else
                  select @w_oficina_ifase = @s_ofi

               select @w_tipo_oficina_ifase = dp_origen_dest
               from   ca_trn_oper, cob_conta..cb_det_perfil
               where  to_tipo_trn = 'DES'
               and    to_toperacion = @w_toperacion
               and    dp_empresa    = 1
               and    dp_producto   = 7
               and    dp_perfil     = to_perfil
               and    dp_codval     = @w_codvalor_mpg
               
               if @@rowcount = 0 
               begin
                  select @w_error = 710446
                  goto ERROR
               end
               
               if @w_tipo_oficina_ifase = 'C' 
               begin
                  select @w_oficina_ifase = pa_int
                  from   cobis..cl_parametro
                  where  pa_nemonico = 'OFC'
                  and    pa_producto = 'CON'
                  set transaction isolation level read uncommitted
               end
               
               if @w_tipo_oficina_ifase = 'D' 
               begin
                  select @w_oficina_ifase = @w_oficina
               end
                  
               if @i_debug = 'S' -- FCP Interfaz Ahorros 
               begin
                  if @i_pago_ext = 'N'
                  begin 
                     print 'ANTES DE sp_afect_prod_cobis - REVERSA DESEMBOLSOS '
                     print 'w_secuencial_retro: ' + cast(@w_secuencial_retro as varchar)
                     print 'w_prod_rev: ' + @w_prod_rev
                  end
               end

               --LRE 03Ago Si es interciclo obtener el numero de operacion del padre para obtener el secuencial
               if @w_tipo_grupal = 'I'
               begin
                  select @w_banco_padre = op_ref_grupal 
                  from cob_cartera..ca_operacion 
                  where op_operacion = @w_operacionca

                  if @@rowcount = 0 
                  begin
                     select @w_error = 701025
                     goto ERROR
                  end

                  select @w_num_oper_padre = op_operacion
                  from cob_cartera..ca_operacion
                  where op_banco = @w_banco_padre

                  if @@rowcount = 0 
                  begin
                     select @w_error = 701025
                     goto ERROR
                  end
                  
                  --LPO TEC INICIO, OBTENER EL SECUENCIAL PARA EL REVERSO EN ESTE PUNTO DA PROBLEMAS EN AHORROS, SE LO OBTIENE MÉS ADELANTE
                  /*exec @w_cod_alt = sp_gen_sec
                    @i_operacion  = @w_num_oper_padre
                  */
                  --LPO TEC FIN, OBTENER EL SECUENCIAL PARA EL REVERSO EN ESTE PUNTO DA PROBLEMAS EN AHORROS, SE LO OBTIENE MÉS ADELANTE
                  
               end --FIN LRE 03Ago Si es interciclo obtener el numero de operacion del padre para obtener el secuencial

               
               --LPO TEC INICIO, OBTENER EL SECUENCIAL PARA EL REVERSO EN ESTE PUNTO DA PROBLEMAS EN AHORROS, SE LO OBTIENE MÉS ADELANTE
               /*               
               else
               BEGIN
               
                   exec @w_cod_alt = sp_gen_sec
                        @i_operacion  = @w_operacionca
               end
               */
               --LPO TEC FIN, OBTENER EL SECUENCIAL PARA EL REVERSO EN ESTE PUNTO DA PROBLEMAS EN AHORROS, SE LO OBTIENE MÉS ADELANTE
               
               
               --LPO TEC Se cambió el orden de ejecución para que haya disponible en la cuenta al hacer un reverso del desembolso,
               --se ejecutaba despues de sp_interfaz_otros_modulos y sp_incentivos_grp y daba un error de Fondos Insuficientes.
               --INI AGI 31JUL19 REVERSO DE SEGUROS
               execute @w_error = sp_debito_seguros
                @s_ssn            = @s_ssn,
                @s_sesn           = @s_ssn,
                @s_user           = @s_user,
                @s_date           = @s_date,
                @s_ofi            = @s_ofi,
                @i_opcion         = 'R',
                @i_operacion      = @w_operacionca,
                @i_cta_grupal     = @w_cuenta,
                @i_moneda         = @w_moneda_trn,
                @i_fecha_proceso  = @s_date, 
                @i_oficina        = @s_ofi,
                @i_secuencial_trn = @s_ssn
                
               if @@error <> 0 
               begin
                  select @w_error = 725067
                  goto ERROR
               end         
               --FIN AGI
               
               --LPO TEC INICIO, SE OBTENE EL SECUENCIAL PARA EL REVERSO EN ESTE PUNTO PARA QUE NO DE PROBLEMAS EN AHORROS
               if @w_tipo_grupal = 'I'
               BEGIN
                  exec @w_cod_alt = sp_gen_sec
                    @i_operacion  = @w_num_oper_padre
               END
               ELSE
               BEGIN
                   exec @w_cod_alt = sp_gen_sec
                        @i_operacion  = @w_operacionca                  
               END
               --LPO TEC FIN, SE OBTENE EL SECUENCIAL PARA EL REVERSO EN ESTE PUNTO PARA QUE NO DE PROBLEMAS EN AHORROS
               
               exec @w_error = sp_afect_prod_cobis   
               @s_ssn          = @s_ssn,
               @s_sesn         = @s_sesn,
               @s_srv          = @s_srv,
               @s_user         = @s_user,
               @s_ofi          = @w_oficina_ifase,
               @s_lsrv         = @s_lsrv,
               @s_term         = @s_term,
               @s_rol          = @s_rol,
               @s_date         = @s_date,
               @i_fecha        = @s_date,
               @i_cuenta       = @w_cuenta,
               @i_producto     = @w_prod_rev,
               @i_monto        = @w_monto,
               @i_operacionca  = @w_operacionca,  ---Para reversar moneda extranjera ce_transferencia_pendiente
               @i_opcion       = 7,               --PARA COMERCIO EXTERIOR
               @i_alt          = @w_cod_alt,
               @i_reversa      = 'S',
               @i_mon          = @w_moneda_trn,
               @i_en_linea     = @i_en_linea,
               @i_sec_tran_cca = @w_secuencial_retro, -- FCP Interfaz Ahorros                     
               @i_secuencial_tran = @w_idlote,
               @i_dm_desembolso   = @w_dm_desembolso,
               @i_grupal       =  @w_es_grupal        --LRE 08Ago2019
                   
               if @w_error <> 0 
               begin
                  close cursor_afecta_prod
                  deallocate cursor_afecta_prod
                  goto ERROR
               end
                  
            end   
            --FINALIZA LA INTERFAZ CON OTROS PRODUCTOS
                  
            -- PARA INTERFAZ CON TESORERIA
            select @w_categoria = cp_categoria
            from   ca_producto
            where  cp_producto = @w_prod_rev
            
            select @w_fecha_ingreso = getdate()
            
            if @w_categoria in ('NCAH','NCCC','NDAH','NDCC','EFEC','CHLO','CHOT','CHGE')  
            begin
               if @i_debug = 'S' -- FCP Interfaz Ahorros 
               begin
                  if @i_pago_ext = 'N'
                  begin 
                     print 'ANTES DE sp_interfaz_otros_modulos'
                     print 'w_secuencial_retro: ' + cast(@w_secuencial_retro as varchar)
                  end
               end          
               exec @w_error = sp_interfaz_otros_modulos
               @s_user         = @s_user,
               @i_cliente      = @w_cliente,
               @i_modulo       = 'CCA',
               @i_interfaz     = 'T',
               @i_modo         = 'I',
               @i_obligacion   = @i_banco,
               @i_moneda       = @w_moneda_trn,
               @i_sec_trn      = @w_secuencial_retro,
               @i_fecha_trn    = @w_fecha_ingreso,
               @i_desc_trn     = 'DESEMBOLSO DE CARTERA',
               @i_monto_trn    = @w_monto,
               @i_cotizacion   = @w_cotizacion_trn,
               @i_forma_desm   = @w_prod_rev,
               @i_oficina      = @s_ofi,
               @i_gerente      = @s_user,
               @i_afec_trn     = 'E',     --EGRESO
               @i_tipo_trn     = 'R',      --REVERSA
               @i_categoria    = @w_categoria
               
               if @w_error <> 0 goto ERROR
            end
               
            fetch cursor_afecta_prod into
            @w_prod_rev,     @w_monto,      @w_cuenta,
            @w_pcobis,       @w_moneda_trn, @w_cotizacion_trn,
            @w_codvalor_mpg, @w_idlote,     @w_dm_desembolso
         end --END WHILE
            
         close cursor_afecta_prod
         deallocate cursor_afecta_prod
        
         --GFP 07/04/2022 Se actualiza los campos de desembolso estado, secuencial y pagado
         --Obtención de nuevo secuencial
         exec @w_secuencial_act = sp_gen_sec
            @i_operacion  = @w_operacionca
            
         --Actualizacion de campos estado a 'No Aplicado', se actualiza el nuevo secuencial, y la identificación de pagado a N  
         update ca_desembolso
         set dm_estado     = 'NA',
             dm_secuencial = @w_secuencial_act
             -- dm_pagado     = 'N'               -- KDR Reverso no debe cambiar el PAGADO de las formas de desembolso [El reverso de cada canal debería encargarse]
         where  dm_operacion  = @w_operacionca
         and    dm_secuencial = @w_secuencial_retro
         
         if @@error <> 0 begin
            select @w_error = 710002
            goto ERROR
         end
         
         --GFP Actualizacion de ciclo de cliente
         update cobis..cl_ente 
         set en_nro_ciclo = isnull(en_nro_ciclo, 0) - 1
         where en_ente = @w_cliente
         
         if @@error <> 0
         begin
              select @w_error = 725190
              goto ERROR
         end
         
         -- KDR Variable de salida con nuevo secuencial
         select @o_secuencial_act = @w_secuencial_act 
         
         --INI AGI 25JUL19 REVERSO DE INCENTIVOS   
         exec @w_error =  sp_incentivos_grp
             @s_user              = @s_user,
             @s_sesn              = @s_ssn,
             @s_ssn               = @s_ssn,
             @s_ofi               = @s_ofi ,
             @s_date              = @s_date,
             @s_term              = @s_term,
             @i_opcion            = 'R',
             @i_operacion         = @w_operacionca,  
             @i_secuencial_trn    = @w_secuencial_retro,
             @o_mensaje           = @w_mensaje out
             
        if @@error <> 0 
        begin
            select @w_error = 725065
            goto ERROR
         end         
         --FIN AGI
                  
         
         if exists (select 1 from ca_pago_planificador
         where  pp_operacion = @w_operacionca
         and    pp_estado =  'I')
         begin
            update ca_pago_planificador
            set pp_estado =  'R'
            where   pp_operacion = @w_operacionca
            and     pp_estado =  'I'
         end         
         
         --REVERSO DEL ESTADO DEL DOCUMENTO PARA DD  NR-126
         if (@w_tipo = 'F') or  (@w_tipo = 'D' )  begin
        
            exec @w_error =   sp_reversos_dd
            @i_tramite     = @w_tramite,
            @i_tran        = 'DES',
            @i_operacionca = @w_operacionca
            
            if @w_error <> 0  goto ERROR
         
         end 
         
         select 
         @w_prod_rev       = dm_producto,
         @w_monto          = dm_monto_mds,
         @w_cotizacion_trn = dm_cotizacion_mds,
         @w_moneda_trn     =  dm_moneda
         from   ca_desembolso
         where  dm_operacion = @w_operacionca
            
         -- PARA INTERFAZ CON TESORERIA
         select @w_categoria = cp_categoria
         from   ca_producto
         where  cp_producto = @w_prod_rev
         
         select @w_fecha_ingreso = getdate()
         
         if @w_categoria in ('NCAH','NCCC','NDAH','NDCC','EFEC','CHLO','CHOT','CHGE') 
         begin
            if @i_debug = 'S' -- FCP Interfaz Ahorros 
            begin
               if @i_pago_ext = 'N'
               begin 
                  print 'ANTES DE sp_interfaz_otros_modulos'
                  print 'w_secuencial_retro: ' + cast(@w_secuencial_retro as varchar)
               end
            end         
            exec @w_error = sp_interfaz_otros_modulos
            @s_user         = @s_user,
            @i_cliente      = @w_cliente,
            @i_modulo       = 'CCA',
            @i_interfaz     = 'T',
            @i_modo         = 'I',
            @i_obligacion   = @i_banco,
            @i_moneda       = @w_moneda_trn,
            @i_sec_trn      = @w_secuencial_retro,
            @i_fecha_trn    = @w_fecha_ingreso,
            @i_desc_trn     = 'DESEMBOLSO DE CARTERA',
            @i_monto_trn    = @w_monto,
            @i_cotizacion   = @w_cotizacion_trn,
            @i_forma_desm   = @w_prod_rev,
            @i_oficina      = @s_ofi,
            @i_gerente      = @s_user,
            @i_afec_trn     = 'E',     
            @i_tipo_trn     = 'R',
            @i_categoria    = @w_categoria
            
            if @w_error <> 0  goto ERROR
         end
            
            
         /*CAMBIO DE ESTADO EN EL GENERA ORDEN PARA PAGOS DE CAJA*/
         select 
         @w_sec_orden =  max(dm_secuencial),    
         @w_orden_pag  = dm_orden_caja
         from ca_desembolso
         where dm_operacion =  @w_operacionca      
         group by dm_secuencial,dm_orden_caja

--LPO CDIG No usar sp_genera_orden porque Cajas no la usa INICIO
/*   
         if @w_orden_pag is not null begin 
        
            exec @w_error    = cob_interface..sp_genera_orden
            @s_date           = @s_date,       --> Fecha de proceso
            @s_user           = @s_user,       --> Usuario
            @i_operacion      = 'A',           --> Operacion ('I' -> Insercion, 'A' Anulación)
            @i_causa          = '003',         --> Causal de Ingreso(cc_causa_oioe)
            @i_ente           = @w_cliente,    --> Cod ente,
            @i_tipo           = 'P',           --> 'C' -> Orden de Cobro/Ingreso, 'P' -> Orden de Pago/Egreso
            @i_idorden        = @w_orden_pag,  --> Cód Orden cuando operación 'A', 
            @i_ref1           = 0,             --> Ref. Númerica no oblicatoria
            @i_ref2           = 0,             --> Ref. Númerica no oblicatoria
            @i_ref3           = @i_banco,      --> Ref. AlfaNúmerica no oblicatoria
            @i_interfaz       = 'N'            --> 'N' - Invoca sp_cerror, 'S' - Solo devuelve cód error
            
            if @w_error <> 0 goto ERROR
         
         end
*/
--LPO CDIG No usar sp_genera_orden porque Cajas no la usa FIN

      end 
    
      /* ACCIONES AL REVERSAR PAGOS Y CONDONACIONES */
      if @w_tran in ('PAG', 'CON') begin
         
         /* REVERSO DE LOS PAGOS ASOCIADOS A LA RENOVACION */
         select @w_secuencial = oc_secuencial 
         from ca_otro_cargo 
         where oc_operacion = @w_operacionca 
         and   oc_concepto ='COMPRECAN'
            
         if @@rowcount <> 0  begin
            update ca_transaccion
            set tr_estado ='RV'
            where tr_tran ='IOC'
            and tr_secuencial = @w_secuencial
            and tr_operacion = @w_operacionca
            if @@error <> 0 
            begin
               select @w_error = 710568
               goto ERROR
            end 
       
            delete ca_otro_cargo
            where oc_operacion = @w_operacionca
            and   oc_secuencial = @w_secuencial
            if @@error <> 0 
            begin
               select @w_error = 701157
               goto ERROR
            end 
         end
        
         delete ca_lavado_activos
         where  la_operacion      = @w_operacionca 
         and    la_secuencial_pag = @i_secuencial 
       
         if @@error <> 0 begin 
            select @w_error = 710003
            goto ERROR
         end

         select 
         @w_secuencial_pag = ab_secuencial_pag,
         @w_secuencial_rpa = ab_secuencial_rpa
         from   ca_abono
         where  ab_operacion      = @w_operacionca
         and    ab_secuencial_pag = @w_secuencial_retro
         and    ab_estado         = 'A' -- SOLO SE REVIERTEN PAGOS APLICADOS
         
         if @@rowcount = 0 begin
            select @w_error = 710542
            goto ERROR
         end
         
         select @w_transaccion_pag = 'S'
         
         
         --LPO CDIG Multimoneda Reversa INICIO
         /* DETERMINAR SI DEBE REALIZARSE LA REVERSA DE LA TRANSACCION TRIBUTARIA DE CAMBIO DE DIVISAS */
         
         --/ OBTENER EL SECUENCIAL PARA LA REVERSA /
         select @w_secuencial_rev = ab_secuencial_rpa  --ab_secuencial_ing
         from   ca_abono
         where  ab_operacion      = @w_operacionca
         and    ab_secuencial_pag = @w_secuencial_retro
         
         select @w_sec_divisas = tr_dias_calc
         from   ca_transaccion 
         where  tr_operacion  = @w_operacionca
         and    tr_secuencial = @w_secuencial_rev
         and    tr_tran       = 'RPA'
--         and    tr_estado     = 'RV'
         
         select @w_sec_divisas = isnull(@w_sec_divisas, 0)
         
         if @w_sec_divisas = 0
         begin
            select @w_sec_divisas = tr_dias_calc
            from   ca_transaccion 
            where  tr_operacion  = @w_operacionca
            and    tr_secuencial = @w_secuencial_rev
            and    tr_tran       = 'PAG'
--            and    tr_estado     = 'RV'
         end
         
         select @w_sec_divisas = isnull(@w_sec_divisas, 0)
         
                  
         /* PROCESAR REVERSA DE TRANSACCION TRIBUTARIA DE DIVISAS */
         if @w_sec_divisas > 0
         begin
            select @w_sec_reversa = isnull(trd_sec_divisas,0)
            from   ca_tran_divisas 
            where  trd_operacion  = @w_operacionca
            and    trd_secuencial = @w_sec_divisas 
            
            if @w_sec_reversa > 0
            begin

               exec @w_error       = cob_cartera..sp_op_divisas_automatica
                    @s_date          = @s_date,        /* Fecha del sistema                                                         */
                    @s_user          = @s_user,        /* Usuario del sistema                                                       */
                    @s_ssn           = @s_ssn,         /* Secuencial Transaccion                                                    */
                    
                    @i_oficina       = @s_ofi,         /* Oficina donde debe ser registrada la transaccion.  Afectar  contablemente */
                    @i_cliente       = @w_cliente,     /* Codigo del cliente a nombre de quien se realiza la operacion de divisas   */
                    @i_modulo        = 'CCA',          /* Nemonico del modulo COBIS que origina la operacion de divisas             */
                    @i_operacion     = 'R',            /* C - Consulta, E - Ejecucion normal , R - Reversar una operacion anterior  */
                    @i_secuencial    = @w_sec_reversa, /* SSN de la operacion normal.  Usado para reversos                          */
                    @i_batch         = @i_en_linea,
                    @i_empresa       = 1,
                    @i_num_operacion = @i_banco,
                    --@i_producto      = 7,              -- Producto Cartera. 
                    @i_masivo        = 'L'             
               
               if @w_error <> 0
               begin
                  select @w_error = @w_error
                  goto ERROR                
               end
            end
         end
         --LPO CDIG Multimoneda Reversa FIN
                  
         update ca_abono
         set    ab_estado   = 'RV'
         where  ab_secuencial_pag = @w_secuencial_retro
         and    ab_operacion      = @w_operacionca
         
         if @@error <> 0  begin
            select @w_error = 710002
            goto ERROR
         end
         
         select @w_fecha_pag = ab_fecha_pag,
                @w_secuencial_ing = ab_secuencial_ing
         from   ca_abono
         where  ab_secuencial_pag = @w_secuencial_retro
         and    ab_operacion      = @w_operacionca
         
         
         update cobis..cl_det_producto
         set    dp_estado_ser   = 'V'
         from   cobis..cl_cliente
         where  dp_det_producto = cl_det_producto
         and    dp_producto     = 7
         and    dp_estado_ser   = 'C'
         and    cl_cliente      = @w_cliente
   
         
         ---UN PREPGO SE MARCA COMO REVERSADO SOLO SI AUN NO  HA SIDO APLICADO 
         ---A  LA OBLIGACION PASIVA
         if @w_tipo  = 'C' and @i_operacion = 'R' 
         begin
            --- REVISAR SI LA PASIVA TIENE UN PREPAGO EN ESTADO I PARA ESTE SECUENCIAL DE REVERSO
            select @w_min_sec_prepago = 0
            
            select @w_banco_pasivo = op_banco
            from   ca_operacion
            where  op_cliente = @w_cliente
            and    op_codigo_externo = @w_llave_redescuento
            and    op_tipo = 'R'
            
            if @@rowcount  <> 0 
            begin
               if  exists (select 1
               from   ca_prepagos_pasivas
               where  pp_banco =  @w_banco_pasivo
               and    pp_sec_pagoactiva  = @w_secuencial_retro  )
               begin
                   --DEF-5493
                   --SE INSERTA PARA CONTROL DE PREPAGOS EN PASIVAS
                   insert into ca_prepagos_por_reversos
                   (
                   pr_fecha_cierre_rev, pr_fecha_de_pago, pr_operacion_activa,
                   pr_secuencial_pag,   pr_usuario
                   )
                   values
                   (
                   @w_fecha_proceso,    @w_fecha_pag,     @w_operacionca,
                   @w_secuencial_retro, @s_user
                   )
               end
            end
         end
         
         if @w_tipo  = 'R' 
         begin
            if exists (select 1 from ca_prepagos_pasivas
            where pp_banco =  @i_banco
            and   pp_secuencial_ing = @w_secuencial_ing)
            begin
               update ca_prepagos_pasivas set 
               pp_estado_registro = 'R',
               pp_causal_rechazo  = '7',
               pp_comentario      = 'REVERSO DEL PAGO  OPERACION PASIVA'
               where pp_banco =  @i_banco
               and   pp_secuencial_ing = @w_secuencial_ing          
            end
         end         
         
         -- AFECTACION A OTROS PRODUCTOS            
         declare cursor_afecta_productos cursor
         for select 
         cp_producto_reversa, abs(abd_monto_mpg), abd_cuenta,
         abd_moneda,          abd_cotizacion_mpg, abd_beneficiario,
         isnull(cp_pcobis,0), abd_cheque,         abd_cod_banco,
         abd_carga,           cp_codvalor,        abd_tipo,
         ab_secuencial_rpa -- FCP Interfaz Ahorros                        
         from   ca_abono_det, ca_producto, ca_abono
         where  ab_secuencial_pag = @w_secuencial_retro
         and    ab_operacion      = @w_operacionca
         and    ab_operacion      = abd_operacion
         and    ab_secuencial_ing = abd_secuencial_ing 
         and    ab_operacion      = abd_operacion 
         and    abd_concepto      = cp_producto             
         and    abd_tipo          in('PAG', 'SEG')
         for read only
   
         open  cursor_afecta_productos
         
         fetch cursor_afecta_productos into  
         @w_prod_rev,             @w_abd_monto_mpg,      @w_cuenta,
         @w_moneda_trn,           @w_cotizacion_trn,     @w_beneficiario,
         @w_pcobis,               @w_cheque,             @w_cod_banco,
         @w_carga,                @w_codvalor_mpg,       @w_abd_tipo,             
         @w_ab_sec_rpa   -- FCP Interfaz Ahorros 
         
         while (@@fetch_status = 0) 
         begin  
            if @w_prod_rev is null 
            begin
               close cursor_afecta_productos 
               deallocate cursor_afecta_productos 
               select @w_error = 710345
               goto ERROR
            end
            
            select @w_prodcobis_rev = isnull(cp_pcobis,0)
            from ca_producto
            where cp_producto = @w_prod_rev
            
            --SOLO SI LA FORMA DE REVERSO ES PARA AFECTAR A OTRO PRODUCTO DIFERENTE DE CARTERA
            --SE EJECUTARA EL afpcobis.sp
            
            if @w_prodcobis_rev in (3,4,9,19,26,48) 
            begin --AHO-CTAS-SIDAC-CARTERA
            
               select @w_oficina_ifase = @s_ofi
               
               if @w_abd_tipo ='PAG' 
               begin
                  select @w_tipo_oficina_ifase = dp_origen_dest
                  from   ca_trn_oper, cob_conta..cb_det_perfil
                  where  to_tipo_trn = 'RPA'
                  and    to_toperacion = @w_toperacion
                  and    dp_empresa    = 1
                  and    dp_producto   = 7
                  and    dp_perfil     = to_perfil
                  and    dp_codval     = @w_codvalor_mpg
                  
                  if @@rowcount = 0 
                  begin
                     select @w_error = 710446
                     goto ERROR
                  end
               end
               
               if @w_abd_tipo ='SEG' 
               begin
                  select @w_tipo_oficina_ifase = dp_origen_dest
                  from   ca_trn_oper, cob_conta..cb_det_perfil
                  where  to_tipo_trn = 'PAG'
                  and    to_toperacion = @w_toperacion
                  and    dp_empresa    = 1
                  and    dp_producto   = 7
                  and    dp_perfil     = to_perfil
                  and    dp_codval     = @w_codvalor_mpg
                  
                  if @@rowcount = 0 
                  begin
                     select @w_error = 710446
                     goto ERROR
                  end
               end
               
               if @w_tipo_oficina_ifase = 'C' 
               begin
                  select @w_oficina_ifase = pa_int
                  from   cobis..cl_parametro
                  where  pa_nemonico = 'OFC'
                  and    pa_producto = 'CON'
                  set transaction isolation level read uncommitted
               end
               
               if @w_tipo_oficina_ifase = 'D' 
               begin
                  select @w_oficina_ifase = @w_oficina
               end

               if @w_pcobis  in (3,4,19,26) 
               begin
                  if @i_debug = 'S'  -- FCP Interfaz Ahorros 
                  begin
                     if @i_pago_ext = 'N'
                     begin 
                        print 'ANTES DE sp_afect_prod_cobis - REVERSA PAGOS'                     
                        print 'w_ab_sec_rpa: ' + cast(@w_ab_sec_rpa as varchar)
                        print 'w_prod_rev: ' + @w_prod_rev
                     end
                  end 
   
               --LRE 03Ago Si es interciclo obtener el numero de operacion del padre para obtener el secuencial
               if @w_tipo_grupal = 'I'
               begin
                  select @w_banco_padre = op_ref_grupal 
                  from cob_cartera..ca_operacion 
                  where op_operacion = @w_operacionca

                  select @w_num_oper_padre = op_operacion
                  from cob_cartera..ca_operacion
                  where op_banco = @w_banco_padre
   
                  exec @w_cod_alt = sp_gen_sec
                    @i_operacion  = @w_num_oper_padre
               end
               else
               begin
                  exec @w_cod_alt = sp_gen_sec
                       @i_operacion  = @w_operacionca
               end

                  exec @w_error    = sp_afect_prod_cobis
                  @s_ssn            = @s_ssn,
                  @s_sesn           = @s_sesn,
                  @s_srv            = @s_srv,
                  @s_user           = @s_user,
                  @s_ofi            = @s_ofi,
                  @s_lsrv           = @s_lsrv,
                  @s_term           = @s_term,
                  @s_rol            = @s_rol,
                  @s_date           = @s_date,
                  @t_ssn_corr       = @w_carga,
                  @i_fecha          = @s_date,
                  @i_cuenta         = @w_cuenta,
                  @i_producto       = @w_prod_rev,
                  @i_beneficiario   = @w_beneficiario,   
                  @i_no_cheque      = @w_cheque,         
                  @i_abd_cod_banco  = @w_cod_banco,      
                  @i_reversa        = 'S',               
                  @i_monto          = @w_abd_monto_mpg,
                  @i_operacionca    = @w_operacionca,
                  @i_mon            = @w_moneda_trn,
                  @i_alt            = @w_cod_alt,
                  @i_sec_tran_cca   = @w_ab_sec_rpa, -- FCP Interfaz Ahorros                       
                  @i_en_linea       = @i_en_linea,
                  @i_grupal       =  @w_es_grupal        --LRE 08Ago2019
                  
                  if @w_error <> 0 
                  begin
                     close cursor_afecta_productos 
                     deallocate cursor_afecta_productos 
                     goto ERROR
                  end
               end
               -- PARA INTERFAZ CON TESORERIA
               ------------------------------
               select @w_categoria = cp_categoria
               from   ca_producto
               where  cp_producto = @w_prod_rev
               
               select @w_fecha_ingreso = getdate()

               if @w_categoria in ('NCAH','NCCC','NDAH','NDCC','EFEC','CHLO','CHOT','CHGE') 
               begin
                  exec @w_error = sp_interfaz_otros_modulos
                  @s_user         = @s_user,
                  @i_cliente      = @w_cliente,
                  @i_modulo       = 'CCA',
                  @i_interfaz     = 'T',
                  @i_modo         = 'I',
                  @i_obligacion   = @i_banco,
                  @i_moneda       = @w_moneda_trn,
                  @i_sec_trn      = @w_secuencial_retro,
                  @i_fecha_trn    = @w_fecha_ingreso,
                  @i_desc_trn     = 'DESEMBOLSO DE CARTERA',
                  @i_monto_trn    = @w_abd_monto_mpg,
                  @i_cotizacion   = @w_cotizacion_trn,
                  @i_forma_desm   = @w_prod_rev,
                  @i_oficina      = @s_ofi,
                  @i_gerente      = @s_user,
                  @i_afec_trn     = 'I',    
                  @i_tipo_trn     = 'R',
                  @i_categoria    = @w_categoria
                  
                  if @w_error <> 0 
                  begin
                     goto ERROR
                  end
               end
               
            end
            
            fetch cursor_afecta_productos
            into  @w_prod_rev,         @w_abd_monto_mpg,           @w_cuenta,
                  @w_moneda_trn,       @w_cotizacion_trn,          @w_beneficiario,
                  @w_pcobis,           @w_cheque,                  @w_cod_banco,
                  @w_carga,            @w_codvalor_mpg,            @w_abd_tipo,
                  @w_ab_sec_rpa  -- FCP Interfaz Ahorros
         end -- END WHILE
         
         close cursor_afecta_productos 
         deallocate cursor_afecta_productos 
 
         
         --- REVERSAR INTANT  EN TABLA DE AMORTIZACION_ANT y CONTROL
         if exists (select 1
         from   ca_amortizacion_ant
         where  an_secuencial >= @w_secuencial_retro
         and    an_operacion  = @w_operacionca) 
         begin
            delete ca_amortizacion_ant
            where  an_secuencial >= @w_secuencial_retro
            and    an_operacion  = @w_operacionca 
         end
         
         if exists(select 1
         from   ca_control_intant
         where  con_operacion = @w_operacionca
         and    con_secuencia_pag  >= @w_secuencial_retro) 
         begin
            delete ca_control_intant
            where  con_operacion = @w_operacionca
            and    con_secuencia_pag  >= @w_secuencial_retro
         end
      
      
         /*REVERSA EL VALOR DE LOS HONORARIOS DE ABOGADO E IVA */
         select 
         @w_valor_recaudo = 0,
         @w_min_dividendo = 0
                
         select 
         @w_valor_recaudo = isnull(dtr_monto, 0),
         @w_min_dividendo = dtr_dividendo
         from   ca_transaccion, ca_det_trn
         where  tr_operacion   = @w_operacionca
         and    tr_secuencial  = @w_secuencial_retro
         and    tr_tran        = 'PAG'
         and    tr_estado      = 'RV'
         and    dtr_operacion  = tr_operacion
         and    dtr_secuencial = tr_secuencial
         and    dtr_concepto   = 'HONABO'
         
         if @w_valor_recaudo is null
            select @w_valor_recaudo = 0
      
         --ACTUALIZACION DEL VALOR COBRADO POR COMISION DE RECAUDO
         update ca_rubro_op set 
         ro_valor           = ro_valor - @w_valor_recaudo
         where ro_operacion = @w_operacionca
         and   ro_concepto  = 'HONABO'
      
         update ca_amortizacion set 
         am_cuota     = am_cuota - @w_valor_recaudo,
         am_acumulado = am_acumulado - @w_valor_recaudo
         where am_operacion = @w_operacionca
         and   am_dividendo = @w_min_dividendo
         and   am_concepto  = 'HONABO'
      
         --LECTURA DEL VALOR A REVERSAR POR IVA SOBRE LA COMISION POR RECAUDO Y SU DIVIDENDO CORRESPONDIENTE
         select 
         @w_valor_iva_recaudo  = isnull(dtr_monto, 0),
         @w_min_dividendo      = dtr_dividendo
         from   ca_transaccion, ca_det_trn
         where  tr_operacion   = @w_operacionca
         and    tr_secuencial  = @w_secuencial_retro
         and    tr_tran        = 'PAG'
         and    tr_estado      = 'RV'
         and    dtr_operacion  = tr_operacion
         and    dtr_secuencial = tr_secuencial
         and    dtr_concepto   = 'IVAHONOABO'
         
         if @w_valor_iva_recaudo is null select @w_valor_iva_recaudo = 0
      
         --ACTUALIZACION DEL VALOR COBRADO POR IVA SOBRE LA COMISION DE RECAUDO
         update ca_rubro_op set 
         ro_valor           = ro_valor - @w_valor_iva_recaudo
         where ro_operacion = @w_operacionca
         and   ro_concepto  = 'IVAHONOABO'
      
         update ca_amortizacion set 
         am_cuota     = am_cuota     - @w_valor_iva_recaudo,
         am_acumulado = am_acumulado - @w_valor_iva_recaudo
         where am_operacion = @w_operacionca
         and   am_dividendo = @w_min_dividendo
         and   am_concepto  = 'IVAHONOABO'
      
         if @@error <> 0 begin
             select @w_error = 710002
             goto ERROR
         end
         
      end -- END REVERSO DE PAGOS Y CONDONACIONES
   end  -- END (R)EVERSAS
 
   /**************************************************************************************/
   /* SECCION PARA APLICAR CAMBIOS QUE SE EJECUTAN TANTO EN REVERSAS COMO EN FECHA VALOR */
   /**************************************************************************************/
   
   -- BORRAR LAS TASAS MAYORES AL SECUENCIAL DE REVERSO
   delete ca_tasas
   where  ts_operacion  = @w_operacionca
   and    ts_fecha     >= @w_fecha_retro
   
   if @@error <> 0 begin
      select @w_error = 710003 -- KDR Correccion código
      goto ERROR
   end  
 
   -- ELIMINA LOS REAJUSTES AUTOMATICOS TLU%  o LOS REAJUSTES POR VARIACION DE LA TLU QUE SE
   -- IDENTIFICAN CON  re_desagio = 'e' EN LA TABLA DE REAJUSTES
   delete ca_reajuste
   from   ca_reajuste_det
   where  re_operacion     = @w_operacionca
   and    re_fecha        >= @w_fecha_retro
   and    red_operacion    = @w_operacionca
   and    red_secuencial   = re_secuencial
   and    (red_referencial  like 'TLU%' or re_desagio = 'e')

   if @@error <> 0 begin
      select @w_error = 710003 -- KDR Correccion código
      goto ERROR
   end  

   delete ca_reajuste_det
   --from   ca_reajuste_det d  --LPO CDIG Ajuste por migracion a Java
   where  red_operacion = @w_operacionca
   and    not exists(select 1
   from   ca_reajuste
   where  re_operacion = @w_operacionca
   --and    re_secuencial = d.red_secuencial)  --LPO CDIG Ajuste por migracion a Java
   and    re_secuencial = red_secuencial)  --LPO CDIG Ajuste por migracion a Java
   
   if @@error <> 0 begin
      select @w_error = 710003 -- KDR Correccion código
      goto ERROR
   end  
   
   update ca_traslados_cartera set    
   trc_estado = 'N',
   trc_secuencial_trn = 0
   where  trc_operacion       = @w_operacionca
   and    trc_secuencial_trn >= @w_secuencial_retro
   and    trc_estado         <> 'R'

   if @@error <> 0 
   begin
      select @w_error = 710002
      goto ERROR
   end
      
   update ca_otro_cargo set    
   oc_estado = 'NA'
   where  oc_operacion   = @w_operacionca
   and    oc_secuencial >= @w_secuencial_retro

   if @@error <> 0 
   begin
      select @w_error = 710002
      goto ERROR
   end
   
   -- KDR Se elimina los cargos por Gestión de Cobranza automáticos, El batch los volverá a
   --     cargar si se prestan las condiciones necesarias.
   delete ca_otro_cargo
   where oc_concepto in (select c.codigo from cobis..cl_tabla t, cobis..cl_catalogo c 
                        WHERE t.tabla = 'ca_cargos_gestion_cobranza'
                        AND   t.codigo      = c.tabla
                        AND   c.estado      = 'V')
   and   oc_operacion = @w_operacionca
   and   oc_secuencial >=  @w_secuencial_retro
   
   if @@error <> 0 
   begin
      select @w_error = 710003 -- Error en la eliminacion del registro
      goto ERROR
   end
    
   update ca_abono set    
   ab_estado         = 'NA',
   ab_dias_retencion = ab_dias_retencion_ini
   where  ab_secuencial_pag >= @w_secuencial_retro
   and    ab_operacion       = @w_operacionca
   and    ab_estado     not in ('RV','E', 'ING', 'ANU')
   
   if @@error <> 0 
   begin
      select @w_error = 710002
      goto ERROR
   end
   
   delete ca_abono_det
   from   ca_abono, ca_abono_det
   where  ab_operacion       = abd_operacion
   and    ab_secuencial_ing  = abd_secuencial_ing
   and    ab_operacion       = @w_operacionca
   and    ab_secuencial_pag >=  @w_secuencial_retro
   and    abd_tipo  in('SOB','SEG')
   and    ab_estado     not in ('RV','E', 'ING', 'ANU')      

   if @@error <> 0 
   begin
      select @w_error = 710003
      goto ERROR
   end      
         
   if @w_lin_credito is not null 
      select @w_shela  = 0
   else
      select @w_shela = 1
  
   select 
   @w_monto_pag    = isnull(sum(dtr_monto),0),
   @w_monto_pag_mn = isnull(sum(dtr_monto_mn),0)
   from   ca_transaccion, ca_det_trn, ca_rubro_op
   where  tr_operacion = @w_operacionca
   and    tr_tran  in ('PAG', 'PRN', 'CON')
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_estado     <> 'RV'
   and    tr_secuencial  = dtr_secuencial
   and    tr_operacion   = dtr_operacion
   and    ro_operacion   = tr_operacion
   and    dtr_concepto   = ro_concepto 
   and    ro_tipo_rubro  = 'C' 
   
   select @w_monto_des = isnull(sum(dtr_monto),0),
          @w_monto_des_mn = isnull(sum(dtr_monto_mn),0)
   from   ca_transaccion, ca_det_trn, ca_rubro_op
   where  tr_operacion = @w_operacionca
   and    tr_tran  = 'DES'
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_estado     <> 'RV'
   and    tr_secuencial  = dtr_secuencial
   and    tr_operacion   = dtr_operacion
   and    ro_operacion   = tr_operacion
   and    dtr_concepto   = ro_concepto 
   and    dtr_codvalor  <> 10990
   and    ro_tipo_rubro  = 'C' 
   
   if @w_moneda = 0
      select @w_monto_des = @w_monto_des - @w_monto_pag
   else
      select @w_monto_des = @w_monto_des_mn - @w_monto_pag_mn
   
   if @w_monto_des > 0 
      select @w_tipo ='X' --'D' XSA
   else
      select @w_tipo ='Y',  --'C' XSA
             @w_monto_des = -1 * @w_monto_des 

   if ((@w_monto_des  > 0 and @w_tran = 'DES' ) or ( @w_monto_pag > 0 ))
      and @w_tramite is not null and @w_lin_credito is not null 
      begin
      
      if @w_tran = 'DES'
         select @w_utilizado_cupo = @w_monto_des
      else
         select @w_utilizado_cupo = @w_monto_pag
   
      if @w_opcion = 'R'         -- REDESCUENTO
         select @w_opcion = 'P'  -- PASIVA
      else
         select @w_opcion = 'A'  -- ACTIVA

      exec @w_error = cob_credito..sp_utilizacion
      @s_date        = @s_date,
      @s_lsrv        = @s_lsrv,
      @s_ofi         = @s_ofi,
      @s_org         = @s_org,
      @s_rol         = @s_rol,
      @s_sesn        = @s_sesn,
      @s_srv         = @s_srv,
      @s_ssn         = @s_ssn,
      @s_term        = @s_term,
      @s_user        = @s_user,
      @t_trn         = 21888,
      @i_linea_banco = @w_lin_credito,
      @i_producto    = 'CCA',
      @i_toperacion  = @w_toperacion,
      @i_tipo        = @w_tipo,
      @i_moneda      = @w_moneda,
      @i_monto       = @w_utilizado_cupo,
      @i_secuencial  = @w_secuencial_retro,
      @i_tramite     = @w_tramite,   
      @i_opcion      = @w_opcion,  
      @i_opecca      = @w_operacionca,
      @i_fecha_valor = @w_fecha_valor,
      @i_cliente     = @w_cliente,
      @i_modo        = @w_shela,
      @i_numoper_cex = @w_numero_comex  ---EPB:oct-09-2001
      
      if @@error <> 0 or @@trancount = 0 
      begin
         select @w_error = 710522
         goto ERROR
      end
      
      if @w_error <> 0 
      begin 
         goto ERROR
      end
   end
   
   -- Validación que verifica el secuencial de una operacion grupa, hija e individual
   select @w_sec_ing_abono_grupal = ab_secuencial_ing_abono_grupal
   from ca_abono
   where ab_secuencial_pag = @i_secuencial
   and   ab_operacion      = @w_operacionca

   if (@w_tipo_grupal = 'H' and @w_sec_ing_abono_grupal is not null)
   begin
	  
	  SELECT @w_banco_op_padre = op_ref_grupal  
      FROM cob_cartera..ca_operacion 
      WHERE op_operacion = @w_operacionca
	  
      select @w_ssn_teller = ab_ssn
      from ca_abono, ca_operacion
      where ab_operacion = op_operacion
	  and ab_secuencial_ing = @w_sec_ing_abono_grupal
      and  op_banco = @w_banco_op_padre
	  
   end
   else
   begin
   
      select @w_ssn_teller = ab_ssn
      from ca_abono
      where ab_secuencial_pag = @i_secuencial
      and   ab_operacion      = @w_operacionca
   end

   --REVERSAR REGISTROS CONTABLES'
   exec @w_error =  sp_transaccion
   @s_date             = @s_date,
   @s_ofi              = @s_ofi,
   @s_term             = @s_term,
   @s_user             = @s_user,
   @t_ssn_corr         = @t_ssn_corr, --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos 
   @t_debug            = @t_debug,  --GFP 18-11-2021
   @t_file             = @t_file,  --GFP 18-11-2021
   @i_operacion        = @i_operacion,
   @i_secuencial_retro = @w_secuencial_retro,
   @i_observacion      = @i_observacion_corto,
   @i_operacionca      = @w_operacionca,
   @i_fecha_retro      = @w_fecha_valor,
   @i_es_atx           = @i_es_atx,
   @i_tiene_rub_dif    = @w_tiene_rub_dif,    -- KDR-20/08/2021 Bandera si la operacion tiene rubros diferidos
   @i_aplica_licitud   = @i_aplica_licitud, --GFP 18-11-2021 Ingreso de parametros solo utilizados para licitud de fondos
   @s_ssn              = @w_ssn_teller
        
   if @w_error <> 0 
   begin
      goto ERROR
   end
   
  
 
   /* ACTUALIZACION SALDO FONDO DE RECURSOS POR DESEMBOLSO REVERSADO */
   if @i_operacion = 'R' and @w_tran = 'DES' begin
   
      if isnull(@w_error,0) = 0  begin
      
         exec @w_error = cob_cartera..sp_fuen_recur 
         @s_user        = @s_user,
         @s_term        = @s_term,
         @s_ofi         = @s_ofi,
         @s_ssn         = @s_ssn,
         @s_date        = @s_date,
         @i_operacion   = 'F',
         @i_monto       = @w_op_monto,
         @i_opcion      = 'D',
         @i_reverso     = 'S',
         @i_operacionca = @w_operacionca,
         @i_secuencial  = @w_secuencial_retro,
         @i_dividendo   = 1,
         @i_fecha_proc  = @w_tr_fecha_ref
         
         if @w_error <> 0 goto ERROR
      end
   end

   --LCA CDIG Activacion-Reversa Pignoracion INICIO   
   if @i_operacion = 'R' and @w_tran = 'PAG' and @w_estado_op = @w_est_cancelado begin

      --REVERSO DE CANCELACION DE GARANTIAS
         exec @w_error = cob_custodia..sp_activar_garantia
              @i_opcion    = 'D',
              @s_date      = @s_date,
              @i_tramite   = @w_tramite,
              @i_modo      = 2,
              @i_operacion = 'I',
              @s_ssn       = @s_ssn,
              @s_user      = @s_user,
              @s_term      = @s_term,
              @s_ofi       = @s_ofi

         if @w_error != 0 begin
            goto ERROR
         end

   end
   --LCA CDIG Activacion-Reversa Pignoracion FIN
   
   /* ACTUALIZACION SALDO FONDO DE RECURSOS POR PAGO REVERSADO */

   select @w_monto_cap_pag_rv = isnull(sum(dtr_monto), 0) - @w_monto_cap_pag_rv_ini
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'PAG'
   and    tr_estado     = 'RV'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = tr_secuencial
   and    dtr_codvalor <> 10017
   and    dtr_codvalor <> 10027
   and    dtr_codvalor <> 10097
   and    dtr_concepto   = 'CAP'

   if @w_monto_cap_pag_rv > 0
   begin
      exec @w_error = cob_cartera..sp_fuen_recur 
      @s_user        = @s_user,
      @s_term        = @s_term,
      @s_ofi         = @s_ofi,
      @s_ssn         = @s_ssn,
      @s_date        = @s_date,
      @i_operacion   = 'F',
      @i_monto       = @w_monto_cap_pag_rv,
      @i_opcion      = 'P',
      @i_reverso     = 'S',
      @i_operacionca = @w_operacionca,
      @i_secuencial  = 0,
      @i_dividendo   = 0,
      @i_fecha_proc  = @w_tr_fecha_ref

      if @w_error <> 0 goto ERROR
         
   end   

            
   -- MONTO DE LOS PAGOS QUE SE REVERSARON CON TRANSACCION REV (-tr_secuencial)
   select @w_monto_cap_pag_rv = isnull(sum(dtr_monto), 0) - @w_monto_cap_pag_rv_ini
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       in ('PAG', 'PRN', 'CON')
   and    tr_estado     = 'RV'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = -tr_secuencial
   and    dtr_concepto   = 'CAP'
   and    dtr_codvalor   in (10000, 10010, 10020, 10030,10040,10090)
   
   -- MONTO DE LOS DESEMBOLSOS QUE SE REVERSARON CON TRANSACCION REV (-tr_secuencial)
   select @w_monto_cap_des_rv = isnull(sum(dtr_monto), 0) - @w_monto_cap_des_rv_ini
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'DES'
   and    tr_estado     = 'RV'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = -tr_secuencial
   and    dtr_concepto   = 'CAP'
   and    dtr_codvalor   in (10000, 10010, 10020, 10030,10040)
   
   select @w_monto_cap_crc_rv = isnull(sum(dtr_monto), 0) - @w_monto_cap_crc_rv_ini
   from   ca_transaccion, ca_det_trn
   where  tr_operacion = @w_operacionca
   and    tr_secuencial >= @w_secuencial_retro
   and    tr_tran       = 'CRC'
   and    tr_estado     = 'RV'
   and    dtr_operacion = tr_operacion
   and    dtr_secuencial = -tr_secuencial
   and    dtr_concepto   = 'CAP'
   and    dtr_codvalor   in (10000, 10010, 10020, 10030,10040)
      
   -- VERIFICACION XMA2015

   if @w_valida_trn = 'S'   ---por default llega en 'S'
   begin 

      if (@w_monto_cap_pag - @w_monto_cap_pag_ing) <> @w_monto_cap_pag_rv 
      begin
         if @i_pago_ext = 'N'
         begin
            select @w_mensaje = 'PAGOS ' + convert(varchar, @w_monto_cap_pag)
            select @w_mensaje = @w_mensaje + ', ING=' + convert(varchar, @w_monto_cap_pag_ing)
            select @w_mensaje = @w_mensaje + ', RV=' + convert(varchar, @w_monto_cap_pag_rv)
            select @w_mensaje = @w_mensaje + ', sec=' + convert(varchar, @w_secuencial_retro)
         end
         select @w_error = 710554
         goto ERROR
      end
   
      if (@w_monto_cap_des - @w_monto_cap_des_ing) <> @w_monto_cap_des_rv 
      begin
         if @i_pago_ext = 'N'
         begin
            select @w_mensaje = 'DESEMBOLSOS ' + convert(varchar, @w_monto_cap_des)
            select @w_mensaje = @w_mensaje + ', ING=' + convert(varchar, @w_monto_cap_des_ing)
            select @w_mensaje = @w_mensaje + ', RV=' + convert(varchar, @w_monto_cap_des_rv)
            select @w_mensaje = @w_mensaje + ', sec=' + convert(varchar, @w_secuencial_retro)               
         end   
         select @w_error = 710554
         goto ERROR
      end
   
      if (@w_monto_cap_crc - @w_monto_cap_crc_ing) <> @w_monto_cap_crc_rv 
      begin
         if @i_pago_ext = 'N'
         begin                 
            select @w_mensaje = 'DESEMBOLSOS ' + convert(varchar, @w_monto_cap_crc)
            select @w_mensaje = @w_mensaje + ', ING=' + convert(varchar, @w_monto_cap_crc_ing)
            select @w_mensaje = @w_mensaje + ', RV=' + convert(varchar, @w_monto_cap_crc_rv)
            select @w_mensaje = @w_mensaje + ', sec=' + convert(varchar, @w_secuencial_retro)
         end
         select @w_error = 710554
         goto ERROR
      end
   end

   
   /* ACTUALIZACION SALDO FONDO DE RECURSOS POR DESEMBOLSO REVERSADO */
   if @i_operacion = 'R' and @w_tran = 'DES'
   begin
      select @w_monto_cap_des_rv = isnull(sum(dtr_monto), 0) 
      from   ca_transaccion, ca_det_trn
      where  tr_operacion = @w_operacionca
      and    tr_secuencial >= @w_secuencial_retro
      and    tr_tran       = 'DES'
      and    tr_estado     = 'RV'
      and    dtr_operacion = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto   in (select cp_producto from ca_producto where cp_desembolso  = 'S')
         
      select 
      @w_monto_cap = @w_monto_cap_des_rv,
      @w_operacion = 'D'
   end
   
   -- KDR 02Jun2021 Actualiza estado padre a NO VIGENTE si a todas las hijas se aplico el RV desembolso o tienen estado NO VIGENTE
   IF @i_operacion = 'R' AND @w_tran = 'DES' AND @w_tipo_grupal = 'H' 
   BEGIN
      --GFP Validación para imperdir reverso individual de operaciones hijas
      if(@i_rev_liq_grupal <> 'S')
      begin
         select @w_error = 725274 --Error, operación pertenece a un crédito grupal, no se puede reversar su desembolso individualmente 
         goto ERROR
      end
      
      SELECT @w_banco_op_padre = op_ref_grupal  
      FROM cob_cartera..ca_operacion with (nolock)
      WHERE op_operacion = @w_operacionca
      
      if @@rowcount = 0 
      BEGIN
         select @w_error = 70203 -- ERROR: OPERACION NO EXISTE O NO ES UNA OPERACION GRUPAL 
         goto ERROR
      END
      
       select @w_grupo_padre = op_grupo from ca_operacion
       where op_banco = @w_banco_op_padre 
       
       IF NOT EXISTS (SELECT 1 FROM cob_cartera..ca_operacion with (nolock)
                      WHERE op_ref_grupal = @w_banco_op_padre
                      AND   op_estado not in (0, 99, 6))
       BEGIN 
           update ca_operacion with (rowlock) set
           op_estado = @w_est_novigente
           where op_operacion IN (SELECT op_operacion FROM ca_operacion with (nolock) WHERE op_banco = @w_banco_op_padre)
             
           if @@error <> 0 begin
               select @w_error  = 710002
               goto ERROR
           end 
           
           --JCHS Reverso de Ciclos por cliente
           update cobis..cl_cliente_grupo set
           cg_nro_ciclo = cg_nro_ciclo - 1
           from cob_credito..cr_tramite_grupal, cobis..cl_cliente_grupo
           where cg_grupo = @w_grupo_padre
           and cg_ente = tg_cliente
           and cg_ente = @w_cliente
           and convert(varchar,tg_operacion) <> tg_prestamo
           
           if @@error <> 0
           begin
           
             select @w_error = 725039
             goto ERROR
           
           end
           --JCHS Reverso De Ciclos por grupo
           update cobis..cl_grupo
           set gr_num_ciclo = gr_num_ciclo - 1 
           where gr_grupo = @w_grupo_padre
           
           if @@error <> 0
           begin
             select @w_error = 725039
             goto ERROR
           end
		   
            --ODI_Error #262345 Realiza la reversa del desembolso a la tabla ca_ciclo
		   select @w_ciclogrup = ci_ciclo --número de ciclo a reversar
             from cob_cartera..ca_ciclo 
            where ci_grupo = @w_grupo_padre
			  and ci_prestamo = @w_banco_op_padre
		
		
		   delete cob_cartera..ca_det_ciclo
            where dc_grupo = @w_grupo_padre
              and dc_referencia_grupal = @w_banco_op_padre
              and dc_ciclo_grupo = @w_ciclogrup
		   if @@error <> 0 begin
              select @w_error = 710003
              goto ERROR
		   end

		   delete cob_cartera..ca_ciclo
            where ci_grupo = @w_grupo_padre
              and ci_ciclo = @w_ciclogrup
			  and ci_prestamo = @w_banco_op_padre
		   if @@error <> 0 begin
              select @w_error = 710003
              goto ERROR
		   end
           --FIN_ODI_Error #262345          
           
       END 
       else --JCHS reverso de ciclos por cliente
       begin   
           update cobis..cl_cliente_grupo set
           cg_nro_ciclo = cg_nro_ciclo - 1
           from cob_credito..cr_tramite_grupal, cobis..cl_cliente_grupo
           where cg_grupo = @w_grupo_padre
           and cg_ente = tg_cliente
           and cg_ente = @w_cliente
           and convert(varchar,tg_operacion) <> tg_prestamo
           
           if @@error <> 0
           begin
           
             select @w_error = 725039
             goto ERROR
           
           end
       end
       
   END
   -- Fin Actualiza estado padre a NO VIGENTE 
   
   --GFP Reverso con afectación a bancos
   select @w_num_desembolso = min(dm_desembolso) 
   from ca_desembolso, ca_producto
   where dm_operacion = @w_operacionca
   and dm_producto    = cp_producto
   and cp_categoria   = 'BCOR'
	  
   if @w_tran = 'DES' and @i_operacion = 'R' and @w_num_desembolso is not null
   begin
      
      while @w_num_desembolso is not null 
      begin
	  
	     select @w_cod_banco        = dm_cod_banco,
                @w_cuenta           = dm_cuenta,
                @w_producto         = dm_producto,
                @w_beneficiario     = dm_beneficiario,
                @w_monto_inter      = dm_monto_mds,
		   	    @w_secuencial_inter = dm_carga -- Secuencial s_ssn que se registro en bancos
         from ca_desembolso
         where dm_operacion = @w_operacionca
         and dm_desembolso  = @w_num_desembolso
    
         select @w_categoria = cp_categoria from cob_cartera..ca_producto
         where cp_producto = @w_producto

         select @w_causal = c.valor 
         from cobis..cl_tabla t, cobis..cl_catalogo c
         where t.tabla = 'ca_fpago_causalbancos'
         and t.codigo = c.tabla
         and c.estado = 'V'
         and c.codigo = @w_producto
         
         if @@rowcount = 0 or @w_causal is null
         begin
            select @w_error = 725139 -- Error, no existe causal para la forma de pago actual, revisar catálogo ca_fpago_causalbancos
            goto ERROR
         end
         
         exec @w_return = cob_bancos..sp_tran_general
         @i_operacion      = 'I',
         @i_banco          = @w_cod_banco,
         @i_cta_banco      = @w_cuenta,
         @i_fecha          = @s_date,
         @i_fecha_contable = @s_date,
         @i_tipo_tran      = 106,              -- NOTA DE DEBITO
         @i_causa          = null,             -- En bancos se ingresa la causal
         @i_documento      = @w_beneficiario , -- NRO  DE REFERENCIA BANCARIA INGRESADA
         @i_concepto       = 'REVERSO DE DESEMBOLSO BCOR',
         @i_beneficiario   = @w_beneficiario,
         @i_valor          = @w_monto_inter,
         @i_cheques        = 0,
         @i_producto       = 7, --CARTERA
         @i_desde_cca      = 'S',
         @i_ref_modulo     = @i_banco,
         @i_modulo         = 7, --CARTERA
         @i_ref_modulo2    = @s_ofi,
         @t_trn            = 171013,
         @s_corr           = 'S',
         @s_ssn_corr       = @w_secuencial_inter,
         @s_user           = @s_user,
         @s_ssn            = @s_ssn,
         @o_secuencial     = @w_sec_banco out
           
         if @w_return <> 0 begin
            select @w_error = @w_return
            goto ERROR
         end 

	     select @w_num_desembolso = min(dm_desembolso) 
	     from ca_desembolso, ca_producto
         where dm_operacion = @w_operacionca
         and dm_producto    = cp_producto
         and cp_categoria   = 'BCOR'
	     and dm_desembolso  > @w_num_desembolso
	  end
   end
   
   if @w_tran = 'PAG' and @i_operacion = 'R' and @i_rev_pago_grupal_hijo = 'N'
   begin
   
	  select @w_ssn_corr_fact        = ab_ssn,
             @w_guid_dte_fact        = ab_guid_dte,
             @w_sec_ing_abono_grupal = ab_secuencial_ing_abono_grupal
                 from ca_abono
                 where ab_secuencial_pag = @i_secuencial
                 and   ab_operacion      = @w_operacionca
	  
      if @w_sec_ing_abono_grupal is not null
      begin
         select @w_error = 725261 -- Error, No se puede reversar individualmente, transacción corresponde a un abono grupal
         goto ERROR
      end
	  
      if @w_ssn_corr_fact is not null and @w_guid_dte_fact is not null
	  begin
	     -- Reverso Facturación electrónica
         exec @w_error = sp_tanqueo_fact_cartera
         @s_user             = @s_user,
         @s_date             = @s_date,
         @s_rol              = @s_rol,
         @s_term             = @s_term,
         @s_ofi              = @s_ofi,
         @s_ssn              = @s_ssn,
         @t_corr             = 'S',
         @t_ssn_corr         = @w_ssn_corr_fact,
         @t_fecha_ssn_corr   = @w_tr_fecha_mov,
         @i_ope_banco        = @i_banco,
         @i_externo          = 'N',
         @i_tipo_tran        = 'PAG',
         @i_operacion        = 'R',
         @o_guid             = @o_guid             out,
         @o_fecha_registro   = @o_fecha_registro   out,
         @o_ssn              = @o_ssn              out,
         @o_orquestador_fact = @o_orquestador_fact out
         
         if @w_error <> 0
      begin
		    if @w_error <> 1720647 -- IGNORA ERROR TANQUEO, YA QUE ESTE ERROR REPRESENTA RV A NIVEL DE COBIS 
         goto ERROR
         end			
      end
      
      -- JCHS Reverso pagos Con afectación a bancos
      select @w_operacionca  = op_operacion
      from ca_operacion
      where op_banco = @i_banco
   
      select @w_cod_banco        = abd_cod_banco,
             @w_cuenta           = abd_cuenta,
             @w_monto_inter      = abd_monto_mpg,
             @w_secuencial_inter = abd_secuencial_interfaces,
             @w_beneficiario     = abd_beneficiario,
             @w_concepto         = abd_concepto,
             @w_secuencial_ing   = abd_secuencial_ing
      from ca_abono_det
      where abd_secuencial_ing = (select ab_secuencial_ing 
                                  from ca_abono 
                                  where ab_secuencial_pag = @i_secuencial
                                  and   ab_operacion      = @w_operacionca)
      and abd_operacion = @w_operacionca
      and abd_tipo = 'PAG'        -- KDR Se toma resgitro de tipo 'PAG', ya que podria haber sobrantes 'SOB'
   
      select @w_categoria = cp_categoria from cob_cartera..ca_producto
      where cp_producto = @w_concepto
      
      if(@w_categoria = 'BCOR' OR @w_categoria = 'MOEL') /*and @s_date = (select ab_fecha_pag from ca_abono           -- KDR Se comenta validación para que se reverse en Bancos independiente de cualquier fecha
                                                                        where ab_secuencial_pag = @i_secuencial
                                                                        and   ab_operacion      = @w_operacionca)*/
      begin  
         select @w_causal = c.valor 
         from cobis..cl_tabla t, cobis..cl_catalogo c
         where t.tabla = 'ca_fpago_causalbancos'
         and t.codigo = c.tabla
         and c.estado = 'V'
         and c.codigo = @w_concepto
        
         if @@rowcount = 0 or @w_causal is null
         begin
            select @w_error = 725139 -- Error, no existe causal para la forma de pago actual, revisar catálogo ca_fpago_causalbancos
            goto ERROR
         end
        
         exec @w_return = cob_bancos..sp_tran_general
         @i_operacion      = 'I',
         @i_banco          = @w_cod_banco,
         @i_cta_banco      = @w_cuenta,
         @i_fecha          = @s_date,
         @i_fecha_contable = @s_date,
         @i_tipo_tran      = @w_param_ibtran, -- NOTA DE CREDITO (DEBE TOMARSE DESDE UN NUEVO PARAMETRO GENERAL)
         @i_causa          =  @w_causal,      -- KDR Causal de la forma de pago
         @i_documento      = @w_beneficiario , --NRO  DE REFERENCIA BANCARIA INGRESADA
         @i_concepto       = 'INTERFAZ DE PAGO DESDE COBIS CARTERA',
         @i_beneficiario   = @w_beneficiario,
         @i_valor          = @w_monto_inter,
         @i_cheques        = 0,
         @i_producto       = 7, --CARTERA
         @i_desde_cca      = 'S',
         @i_ref_modulo     = @i_banco,
         @i_modulo         = 7, --CARTERA
         @i_ref_modulo2    = @s_ofi,
         @t_trn            = 171013,
         @s_corr           = 'S',
         @s_ssn_corr       = @w_secuencial_inter,
         @s_user           = @s_user,
         @s_ssn            = @s_ssn,
         @o_secuencial     = @w_sec_banco out
           
         if @w_return <> 0 begin
            select @w_error = @w_return
            goto ERROR
         end 
         
         update ca_abono_det 
         set abd_sec_reverso_bancos = @w_sec_banco
         where abd_operacion      = @w_operacionca
         and   abd_secuencial_ing = @w_secuencial_ing
         and   abd_tipo           = 'PAG'
           
         if @@error != 0
         begin       
            select @w_error = 725188 -- Error al actualizar el secuencial de reverso de transacción de Bancos.
            goto ERROR
         end
       
      end   
   end

   ----JCHS Actualiza el estado reversado de la interfaz
   if @i_pago_interfaz = 'S' and @i_operacion = 'R' and @w_tran = 'PAG'
   begin
        update ca_intefaz_pago set
        ip_estado = 'R'
        where ip_operacionca         = (select op_operacion from cob_cartera..ca_operacion where op_banco = @i_banco)
        and ip_id_referencia_origen  = @i_id_referencia
        and ip_sec_ing_cartera       = @i_secuencial_rv_int
        
        if @@error <> 0 begin
            select @w_error  = 725099 
            goto ERROR
        end 
   end
   
   --GFP 04-10-2021 Notificacion de reveros de transacciones
   if @i_operacion = 'R' and @w_tran in ('PAG', 'DES', 'IOC', 'ETM')
   begin
        exec @w_error = sp_email_notificacion_reverso
        @s_ofi           = @s_ofi,
        @i_banco         = @i_banco,
        @i_secuencial    = @i_secuencial,
        @i_observacion   = @i_observacion
        
        if @w_error <> 0 begin
         goto ERROR
        end
   end

   if @i_operacion = 'R' and @w_tran = 'PAG'
   begin   
      select @w_monto_cap_pag_rv = isnull(sum(dtr_monto), 0)
      from   ca_transaccion, ca_det_trn
      where  tr_operacion   = @w_operacionca
      and    tr_secuencial  >= @w_secuencial_retro
      and    tr_tran        = 'PAG'
      and    tr_estado      = 'RV'
      and    dtr_operacion  = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto   = 'CAP'
  
      select 
      @w_monto_cap = @w_monto_cap_pag_rv,
      @w_operacion = 'P'
   end

   -- BORRAR DATOS EN TABLA PARA SIPLA
   if @w_tran in ('PAG', 'CON') 
   begin
      exec @w_error = sp_interfaz_otros_modulos
      @s_user         = @s_user,
      @i_cliente      = 0,
      @i_modulo       = 'CCA',
      @i_interfaz     = 'S',
      @i_modo         = 'D',
      @i_obligacion   = @i_banco,
      @i_moneda       = 0,
      @i_sec_trn      = @i_secuencial,
      --@i_fecha_trn    = '',
      --@i_desc_trn     = '',
      @i_monto_trn    = 0,
      @i_gerente      = @s_user,
      @i_cotizacion   = 0,
      @i_categoria    = @w_categoria
      
      if @w_error <> 0 begin
         goto ERROR
      end
   end  ---PAG
     
   ---BORRAR REGISTRO DE ABONO VOLUNTARIO INGRESADO POR REVERSO O FECHA VALOR 
   if exists (select 1
   from   ca_abonos_voluntarios
   where  av_operacion_activa = @w_operacionca
   and    av_secuencial_pag   >= @w_secuencial_retro) 
   begin   
      update  ca_abonos_voluntarios
      set   av_estado_registro = @i_operacion --de fecha valor o reverso
      where av_operacion_activa = @w_operacionca
      and   av_secuencial_pag   >= @w_secuencial_retro
   end
   
   
   -- ELIMINAR REGISTROS EN CASO DE REVERSO O FECHA VALOR
   if exists(select 1 from ca_abono_rubro
   where ar_secuencial >= @w_secuencial_retro
   and   ar_operacion   = @w_operacionca)
   begin
      delete ca_abono_rubro
      where ar_secuencial >= @w_secuencial_retro
      and ar_operacion    = @w_operacionca
   end

   if exists (select 1
   from   ca_pasivas_cobro_juridico
   where  pcj_operacion = @w_operacionca) 
   begin
      delete ca_pasivas_cobro_juridico
      where pcj_operacion = @w_operacionca
   end
   

   ---22120 LA tasa almacenada en ca_ultima_tasa_op debe ser la ULTIMA TASA PACTADA CON EL CLIENTE
   ---O LA ULTIMA TASA INGRESADA POR UN REAJUSTE QUE NO SEA LIMINTE DE USURA
   ---POR ESO CON FECHA VALOR SE DEBE ELIMINAR PARA QUE SE BUSQUE LA CORRECTA AL
   ---HACER LA VALIDACION DE LIMITE DE USURA en cambibc.sp
   ---PERO SI NO HAY DONDE BUSCARLA MEJOR NO SE ELIMINA POR QUE EL MANEJO CON HISTORICOS NO ES
   ---FACIL. Y SE DEJA LA QUE ESTE QUE DEBERIA SER LA PACTADA EN EL DESEBOLSO O LA MIGRACION
      
   select @w_fecha_ult_proceso = op_fecha_ult_proceso
   from ca_operacion
   where op_operacion = @w_operacionca
   
   if exists (select 1 from 
   ca_reajuste with (nolock),
   ca_reajuste_det with (nolock)
   where re_operacion = @w_operacionca
   and   red_operacion  =  @w_operacionca
   and   re_secuencial = red_secuencial
   and   re_fecha <= @w_fecha_ult_proceso
   and   isnull(red_referencial,'') not in ('TLU','TLU1','TLU2','TLU3','TLU4','TMM')
   )
   begin              
      delete ca_ultima_tasa_op         
      where ut_operacion = @w_operacionca   
   end
   ---22120   

   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
   
end  --fin de @i_fecha_valor < @w_fecha_ult_p


/* ESQUEMA 7X24, EVITAR QUE CONSULTA DE OPERACIONES LLEVE EL PRESTAMO A LA FECHA DE PROCESO EN CASO DE FECHA VALOR */
delete ca_en_fecha_valor
where  bi_operacion = @w_operacionca

if @@error <> 0 begin
   select @w_error = 710003
   goto ERROR
end


---LOG fecha valor antes de cambiar la @w_fecha_valor
if @w_secuencial_retro  is null select @w_secuencial_retro = 0
  
insert ca_log_fecha_valor values (
@w_operacionca,  @w_secuencial_retro, @i_operacion, 
@w_fecha_valor, 'N',                  @s_user, 
getdate() )

if @@error != 0 
begin
    select @w_error = 710001
    goto ERROR
end

--Para que en reversas regrese la operacion a la fecha de proceso actual y no marque la operacion como en fecha valor
if @i_operacion = 'R'
   select @w_fecha_valor =  @w_fecha_proceso      

if isnull(@w_fecha_valor, @w_fecha_retro) < @w_fecha_proceso begin   
   
   /* INSERTAR REGISTRO SOLO SI LA FECHA VALOR ES MENOR A LA FECHA DE PROCESO */
   insert into ca_en_fecha_valor(
   bi_operacion,   bi_banco,   bi_fecha_valor, 
   bi_user)
   values(
   @w_operacionca, @i_banco,   @w_fecha_valor,  
   @s_user)
   
   if @@error <> 0 begin
      select @w_error = 710001
      goto ERROR
   end
   
end

---ACTUALIZAR PAGOS COMO NO APLICADOS
update ca_abono
set ab_nro_recibo  = -999 
where ab_operacion = @w_operacionca
and   ab_estado    = 'NA'
   
if @@error <> 0 begin
   select @w_error = 710002
   goto ERROR
end

/* SI EL PROCESO ES DE FECHA VALOR - EFECTUAR LA REVERSA DE LOS PAGOS CON GARANTIA LIQUIDA*/
/* PROGRAMACION SOLO PARA REVERSAS */
if @i_operacion = 'F' 
begin
   declare cursor_pagos_gl cursor
   for select distinct
   ab_secuencial_ing
   from   ca_abono, ca_abono_det
   where  ab_secuencial_pag >= @w_secuencial_retro
   and    ab_operacion       = @w_operacionca
   and    ab_operacion       = abd_operacion 
   and    ab_secuencial_ing  = abd_secuencial_ing
   and    ab_estado     not in ('RV','E', 'ING', 'ANU')
   and    abd_concepto       = 'GAR_DEB'
   order by ab_secuencial_ing desc
   for read only

   open  cursor_pagos_gl
   fetch cursor_pagos_gl 
   into  @w_secuencial_pag

   while (@@fetch_status = 0) 
   begin  
      exec @w_error      = sp_eliminar_pagos
      @s_ssn             = @s_ssn,
      @s_srv             = @s_srv,
      @s_date            = @s_date,
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_ofi             = @s_ofi,
      @i_banco           = @i_banco,
      @i_operacion       = 'D',
      @i_secuencial_ing  = @w_secuencial_pag,
      @i_en_linea        = @i_en_linea,
      @i_pago_ext        = 'N'
 
      if @w_error <> 0 
      begin
         close cursor_pagos_gl  
         deallocate cursor_pagos_gl  
         goto ERROR
      end

      update ca_abono set ab_estado = 'RV'
      where ab_secuencial_ing = @w_secuencial_pag
      and   ab_operacion      = @w_operacionca
      and   ab_estado         = 'E' 

      if @@error <> 0 begin
         select @w_error = 710002
         goto ERROR
      end

      fetch cursor_pagos_gl  
      into  @w_secuencial_pag
   end -- END WHILE
         
   close cursor_pagos_gl 
   deallocate cursor_pagos_gl

end   

   
-- FECHA VALOR HACIA ADELANTE (NO PARA REVERSAS)

if @w_es_liq = 'N'  --and  @i_operacion <> 'R' begin  --LPO TEC Se corre batch hacia adelante para dejar la operacion a la fecha original antes de la reversa
BEGIN
   select @w_fecha_ult_p = op_fecha_ult_proceso
   from   ca_operacion
   where  op_banco = @i_banco
   
   if  @w_fecha_ult_p  < @w_fecha_valor  begin
   
      exec @w_error = sp_batch
      @s_user                = @s_user,
      @s_term                = @s_term,
      @s_date                = @s_date,
      @s_ofi                 = @s_ofi,
      @i_en_linea            = @i_en_linea,
      @i_banco               = @i_banco,
      @i_siguiente_dia       = @w_fecha_valor,
      @i_aplicar_clausula    = @w_aplicar_clausula,
      @i_aplicar_fecha_valor = 'S',
      @i_control_fecha       = @i_control_fecha,
      @i_debug               = @i_debug,
      @i_pago_ext            = @i_pago_ext,  --Req 482
      @i_operacionFR         = @i_operacion  -- KDR Llama al batch desde F: Fecha Valor o R: Reversa
      
      if @w_error <> 0 goto ERROR

   end
end

if @w_op_naturaleza =  'A' and @w_tipo <> 'G'  begin
   exec sp_revisa_otros_rubros 
   @i_operacion  = @w_operacionca,
   @i_fechaval   = 'S'
END

return 0

ERROR:

if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end
   
if @i_pago_ext = 'N' and @i_en_linea  = 'S' begin                 
   exec cobis..sp_cerror
   @t_debug   = 'N',
   @t_from    = @w_sp_name,
   @s_culture = @s_culture, 
   @i_num     = @w_error,
   @i_msg     = @w_msg   
end

return @w_error   
             
go

