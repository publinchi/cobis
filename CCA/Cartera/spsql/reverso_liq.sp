/************************************************************************/
/*   Stored procedure:     sp_reverso_liquida                           */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*   05/Nov/2020   Luis Ponce    Prueba de Coreografia de Servicios     */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reverso_liquida')
   drop proc sp_reverso_liquida
go

create proc sp_reverso_liquida
(  @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              int          = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @t_trn              INT          = NULL, --LPO CDIG Cambio de Servicios a Blis      
   @i_banco_ficticio   cuenta       = null,
   @i_banco_real       cuenta       = null,
   @i_fecha_liq        datetime     = null,
   @i_externo          char(1)      = 'S',
   @i_capitalizacion   char(1)      = 'N',
   @i_afecta_credito   char(1)      = 'S',
   @i_operacion_ach    char(1)      = null,
   @i_nom_producto     char(3)      = null,
   @i_tramite_batc     char(1)      = 'N',
   @i_tramite_hijo     int          = 0,
   @i_prenotificacion  int          = null,
   @i_carga            int          = null,
   @i_reestructura     char(1)      = null,
   @i_banderafe        char(1)      = 'S',  @i_cca_sobregiro    char(1)      = 'N',
   @i_renovacion       char(1)      = 'N',
   @i_crea_ext         char(1)      = null,
   @i_tasa             float		= null, --SRO Santander
   @i_futuro           char(1)      = 'N',  --AGI desembolsos futuros
   @i_es_renovacion    char(1)      = 'N',  --LGBC Variable para validar si el proceso eejecutado es renovacion
   @i_regenera_rubro   char(1)      = null,
   @i_grupal           char(1)      = null,

   --Parametros para la prueba de concepto de la coreografia
   --@i_coreografia          char(1)      = 'N',
   
   --
   
   @o_banco_generado   cuenta       = null out,
   @o_respuesta        char(1)      = null out,
   @o_rotativo         char(1)      = null out, --Contrato cupo rotativo
   @o_msg              varchar(255) = null out
)
as declare
   @w_return               int,
   @w_sp_name              varchar(32),
   @w_error                int,
   @w_monto_gastos         money,
   @w_monto_op             money,
   @w_monto_des            money,
   @w_afectacion           char(1),
   @w_operacionca_ficticio int,
   @w_operacionca_real     int,
   @w_toperacion           catalogo,
   @w_oficina              int,
   @w_moneda               smallint,
   @w_fecha_ini            datetime,
   @w_fecha_fin            datetime,
   @w_est_vigente          tinyint,
   @w_est_cancelado        tinyint,
   @w_est_novigente        tinyint,
   @w_dm_producto          catalogo,
   @w_dm_cuenta            cuenta,
   @w_dm_beneficiario      descripcion,
   @w_moneda_n             tinyint,
   @w_dm_moneda            tinyint,
   @w_dm_desembolso        int,
   @w_dm_monto_mds         money,
   @w_dm_cotizacion_mds    float,
   @w_dm_tcotizacion_mds   char(1),
   @w_dm_cotizacion_mop    float,
   @w_dm_tcotizacion_mop   char(1),
   @w_dm_monto_mn          money,
   @w_dm_monto_mop         money,
   @w_ro_concepto          catalogo,
   @w_ro_valor_mn          money,
   @w_ro_tipo_rubro        char(1),
   @w_estado_op            tinyint,
   @w_codvalor             int,
   @w_num_dec              tinyint,
   @w_num_dec_mn           tinyint,
   @w_tramite              int,
   @w_lin_credito          varchar(24),
   @w_monto                money,
   @w_op_tipo              char(1),
   @w_secuencial           int,
   @w_sec_liq              int,
   @w_sector               catalogo,
   @w_ro_porcentaje        float,
   @w_fecha_ult_proceso    datetime,
   @w_oficial              smallint,
   @w_tplazo               catalogo,
   @w_plazo                int,
   @w_plazo_meses          int,
   @w_destino              catalogo,
   @w_ciudad               int,
   @w_num_renovacion       int,
   @w_di_fecha_ven         datetime,
   @w_int_ant              money,
   @w_int_ant_total        money,
   @w_min_dividendo        int,
   @w_operacionca          int,
   @w_operacion_real       int,
   @w_banco                cuenta,
   @w_cliente              int,
   @w_clase                catalogo,
   @w_opcion               char(1),
   @w_gar_admisible        char(1),
   @w_admisible            char(1),
   @w_tipo_garantia        tinyint,
   @w_grupo                int,
   @w_num_negocio          varchar(64),
   @w_num_doc              varchar(16),
   @w_proveedor            int,
   @w_producto             tinyint,
   @w_op_activa            int,
   @w_tasa_equivalente     char(1),
   @w_prod_cobis_ach       smallint,
   @w_categoria            catalogo,
   @w_fecha_ini_activa     datetime,
   @w_fecha_fin_activa     datetime,
   @w_fecha_ini_pasiva     datetime,
   @w_fecha_fin_pasiva     datetime,
   @w_fecha_liq_pasiva     datetime,
   @w_est_pasiva           tinyint,
   @w_op_pasiva            int,
   @w_banco_pasivo         cuenta,
   @w_op_monto_pasiva      money,
   @w_op_monto_activa      money,
   @w_porcentaje_redes     float,
   @w_dias_anio            smallint,
   @w_monto_cex            money,
   @w_num_oper_cex         cuenta,
   @w_moneda_local         smallint,
   @w_concepto_can         catalogo,
   @w_monto_mn             money,
   @w_cot_mn               money,
   @w_saldo_real_pasiva    money,
   @w_valor_activas        money,
   @w_reestructuracion     char(1),
   @w_calificacion         char(1),
   @w_valor_credito        money,
   @w_moneda_uvr           tinyint,
   @w_est_suspenso         tinyint,
   @w_tr_tipo              char(1),
   @w_op_anterior          cuenta,
   @w_monto_aprobado_cr    money,
   @w_op_numero_reest      int,
   @w_monto_desem_cca      money,
   @w_ro_valor             money,
   @w_rubro_timbac         catalogo, --- PILAS CON EL USO DE ESTA VARIABLE
   @w_parametro_timbac     varchar(30),
   @w_valor_timbac         money,
   @w_ro_fpago             catalogo,
   @w_tipo_amortizacion    catalogo,
   @w_dias_div             int,
   @w_tdividendo           catalogo,
   @w_fecha_a_causar       datetime,
   @w_fecha_liq            datetime,
   @w_clausula             catalogo,
   @w_base_calculo         catalogo,
   @w_causacion            catalogo,
   @w_valor_primera        money,
   @w_max_dividendo        int,
   @w_monto_validacion     money,
   @w_op_lin_credito       cuenta,
   @w_li_tramite           int,
   @w_minimo_sec           int,
   @w_monto_credito        money,
   @w_total_adicionales    money,
   @w_capitaliza           money,
   @w_codvalor_diferido    int,
   @w_est_diferido         tinyint,
   @w_cod_capital          catalogo,
   @w_cotizacion           money,
   @w_naturaleza           char(1),
   @w_tr_contabilizado     char(1),
   @w_tipo_oficina_ifase   char(1),
   @w_oficina_ifase        int,
   @w_tipo_empresa         catalogo,
   @w_op_naturaleza        char(1),
   @w_concepto_intant      catalogo,
   @w_monto_total_mn       money,
   @w_cotizacion_des       float,
   @w_dtr_C                money,
   @w_dtr_D                money,
   @w_limite_ajuste        money,
   @w_diff                 money,
   @w_valor_tf             float,
   @w_tasa_ref             catalogo,
   @w_ts_fecha_referencial datetime,
   @w_ts_valor_referencial float,
   @w_fecha_liq_val        datetime,
   @w_valor_colchon        money,
   @w_codvalor_col         int,
   @w_can_deu              int,
   @w_parametro_col        catalogo,
   @w_concepto_col         catalogo,
   @w_rowcount             int,
   @w_pa_cheger            varchar(30),
   @w_pa_cheotr            varchar(30),
   @w_fecha_pro_k          datetime,
   @w_fecha_car_k          datetime,
   @w_dia                  int,    --jos
   @w_banco_ya             cuenta,  --jos
   @w_parametro_apecr      catalogo,
   @w_valor_rubro          money,
   @w_instrumento          int,
   @w_subtipo              int,
   @w_num_orden            int,
   @w_pagado               char(1),
   @w_num_secuencial       int,
   @w_fpago_pasiva         catalogo,
   @w_parametro_fppasiva   catalogo,
   @w_origen_recursos      catalogo,
   @w_toperacion_pas       catalogo,
   @w_parametro_fng        catalogo,
   @w_parametro_fgu        catalogo,
   @w_parametro_usaid      catalogo,
   @w_parametro_fag        catalogo,
   @w_segdeven             catalogo,
   @w_cod_gar_fng          catalogo,
   @w_gar_op               catalogo,
   @w_tipos_gar            int,
   @w_cobros_amortiza      int,
   @w_cobros               float,
   @w_tramite_new          int,
   @w_oper_ant             cuenta,
   @w_existe               tinyint,
   @w_fdesembolso          catalogo,
   @w_operacionca_ant      int,
   @w_sec_ing_hoy          int,
   @w_num_div              smallint,
   @w_num_amor             smallint,
   @w_mipymes              varchar(10),
   @w_valor_mipyme         money,
   @w_op_clase             catalogo,
   @w_rotativo             varchar(64), --Ceh Req 00278 Contrato cupo rotativo
   @w_abd_concepto         catalogo,
   @w_codvalor_hi          int,
   @w_pa_DESFVA            catalogo,
   @w_seguro_asociado      char(1),
   @w_fecha_inicio         datetime,
   @w_error_sis            int,
   @w_op_monto             money,
   @w_op_monto_aprobado    money,
   @w_edad_cliente         int,
   @w_variables            varchar(255),
   @w_result_values        varchar(255),
   @w_parent               int,
   @w_porcentaje_bloquea   int,
   @w_monto_bloquea        money,
   @w_mensaje_bloqueo      varchar(100),
   @w_contador             int,
   @w_cant_seguro          int,
   @w_sec_seguro           int,
   @w_secuencia_seguro     varchar(100),
   @w_num_tran             int,
   @w_num_temp             int,
   @w_cod_alt              int,
   @w_siglas_com_adm       catalogo,                 --LRE 09/Sep/2019
   @w_siglas_iva_com_adm   catalogo,                  --LRE 09/Sep/2019
   @w_parametro_sincap     catalogo,   --LPO TEC
   @w_rub_asociado         catalogo,   --LPO TEC
   @w_grupal               CHAR(1),    --LPO TEC
   @w_seguros              MONEY,      --LPO TEC
--LPO CDIG Multimoneda
   @w_dtr_sec              int,    --FTU 15/10/2012 COTIZACION
   @w_msg                  varchar(255), --FTU 24/20/2012 COTIZACION
   @w_num_banco           varchar(24),   
   @w_empresa             INT,
   @w_tipo_cotiza         char(1),
   @w_total               MONEY,
   @w_total_mn            MONEY,
   @w_monto_op_mn         MONEY,
   @w_cot_usd             FLOAT,
   @w_factor              FLOAT,
   @w_moneda_dolar        INT,
   @w_sec_divisas         INT,
   @w_sec_reversa         INT,
   @w_moneda_ds           INT
   
   

-- FQ: NR-392
declare
   @w_tflexible                     catalogo,
   @w_op_tipo_amortizacion          catalogo

select @w_tflexible = ''

--LRE 06Sep19 PARAMETROS RUBROS PRESTAMOS GRUPALES TEC

select @w_siglas_com_adm = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('COMGCO')

select @w_siglas_iva_com_adm = pa_char from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico in ('IVAGCO')

--CODIGO DEL RUBRO SEGURO DE INCAPACIDAD --LPO TEC
select @w_parametro_sincap = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'SEGINC'
set transaction isolation level read uncommitted


select @w_tflexible = pa_char
from   cobis..cl_parametro
where  pa_producto  = 'CCA'
and    pa_nemonico  = 'TFLEXI'
set transaction isolation level read uncommitted

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso  out,
@o_est_diferido   = @w_est_diferido  out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_novigente  = @w_est_novigente  out


-- VARIABLES INICIALES
select @w_sp_name       = 'sp_reverso_liquida',
       @w_dtr_C         = 0,
       @w_dtr_D         = 0,
       @w_seguro_asociado = 'N'

--- LECTURA DEL PARAMETRO DESEMBOLSO FECHA VALOR
select @w_pa_DESFVA = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'DESFVA'


/* LECTURA DEL PARAMETRO CHEQUE DE GERENCIA */
select @w_pa_cheger = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'CHEGER'
select @w_rowcount    = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 701012 --No existe parametro cheque de gerencia
   goto ERROR
end

/* LECTURA DEL PARAMETRO CHEQUE LOCAL (Otros Bancos) */
select @w_pa_cheotr = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto    = 'CCA'
and    pa_nemonico    = 'CHELOC'
select @w_rowcount    = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 701012 --No existe parametro cheque de Otros Bancos
   goto ERROR
end

select @w_cod_gar_fng = pa_char
from cobis..cl_parametro
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

-- CONSULTA CODIGO DE MONEDA LOCAL
select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'MLO'
and    pa_producto = 'ADM'

-- Codigo de moneda base para tipos de cambio (DOLAR)
select @w_moneda_dolar = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
  and pa_nemonico = 'CDOLAR'  

-- CODIGO DEL MONEDA UVR
select @w_moneda_uvr = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'MUVR'
select @w_rowcount= @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 711069
   goto ERROR
end

--LECTURA DEL PARAMETRO CODIGO APERTURA DE CREDITO
select @w_parametro_apecr = pa_char
from cobis..cl_parametro  with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'APECR'

-- CODIGO DE CAPITAL
select @w_cod_capital = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 710429
   goto ERROR
end

/*PARAMETRO DE LA GARANTIA DE FNG*/
select @w_parametro_fng = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

---CODIGO DEL RUBRO COMISION GAR UNIFICADA
select @w_parametro_fgu = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMGRP'
set transaction isolation level read uncommitted

/*PARAMETRO DE LA GARANTIA DE USAID*/
select @w_parametro_usaid = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CMUSAP'
set transaction isolation level read uncommitted

/*PARAMETRO DE LA GARANTIA DE FAG*/
select @w_parametro_fag = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CMFAGP'
set transaction isolation level read uncommitted

/* PARAMETRO DE FORMA DE PAGO PRESTAMOS HIJA*/
select @w_abd_concepto = pa_char
  from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'DESREE'

select @s_date = fc_fecha_cierre
from   cobis..ba_fecha_cierre
where  fc_producto = 7

select tc_tipo into #tipo_garantia
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng


select @w_tipos_gar = count(1) from #tipo_garantia


select @w_operacion_real         = op_operacion,
       @w_oficina                = op_oficina,
       @w_moneda                 = op_moneda,
       @w_op_tipo_amortizacion   = op_tipo_amortizacion,
       @w_op_monto               = op_monto,
       @w_op_monto_aprobado      = op_monto_aprobado,
       @w_tramite                = op_tramite,
       @w_rotativo               = op_lin_credito,
       @w_toperacion             = op_toperacion, --LGU 2017-09-03
       @w_grupo                  = op_grupo,
       @w_grupal                 = op_grupal,
       @w_cliente                = op_cliente
from   ca_operacion
where  op_banco = @i_banco_real

-- DETERMINAR EL SECUENCIAL DE DESEMBOLSO A APLICAR
select @w_secuencial  = min(dm_secuencial),
       @w_moneda_ds   = dm_moneda
from   ca_desembolso
where  dm_operacion  = @w_operacion_real
and    dm_estado     = 'NA'
GROUP BY dm_moneda


if @w_secuencial <= 0 or @w_secuencial is null begin
  select @w_error = 701121
  goto ERROR
end

--LPO REVERSA LIQUIDA por Coreografia INICIO

-- CONSULTA CODIGO DE MONEDA LOCAL
select  @w_moneda_local = pa_tinyint
from    cobis..cl_parametro
where   pa_nemonico = 'MLO'
and     pa_producto = 'ADM'

IF @w_moneda_ds <> @w_moneda_local
BEGIN
         --LPO CDIG Multimoneda Reversa INICIO
         /* DETERMINAR SI DEBE REALIZARSE LA REVERSA DE LA TRANSACCION TRIBUTARIA DE CAMBIO DE DIVISAS */
         select @w_sec_divisas = tr_dias_calc
         from   ca_transaccion 
         where  tr_operacion  = @w_operacion_real
         and    tr_secuencial = @w_secuencial --@w_secuencial_retro
         and    tr_tran       = 'DES'
         
         select @w_sec_divisas = isnull(@w_sec_divisas, 0)
         
         
         /* PROCESAR REVERSA DE TRANSACCION TRIBUTARIA DE DIVISAS */
         if @w_sec_divisas > 0
         begin
            select @w_sec_reversa = isnull(trd_sec_divisas,0)
            from   ca_tran_divisas 
            where  trd_operacion  = @w_operacion_real --@w_operacionca
            and    trd_secuencial = @w_secuencial --@w_secuencial_retro 
            
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
                    @i_batch         = 'S', --@i_en_linea,
                    @i_empresa       = 1,
                    @i_num_operacion = @i_banco_real,
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
END
  

DELETE ca_tran_divisas
WHERE trd_operacion  = @w_operacion_real
  AND trd_secuencial = @w_secuencial
  AND trd_tran       = 'DES'


DELETE ca_desembolso
where  dm_operacion      = @w_operacion_real
   and dm_secuencial     = @w_secuencial
   
INSERT INTO ca_desembolso
SELECT DH.*
FROM ca_desembolso_his DH
WHERE dm_secuencial = @w_secuencial
  AND dm_operacion  = @w_operacion_real

DELETE ca_desembolso_his
WHERE dm_secuencial = @w_secuencial
  AND dm_operacion  = @w_operacion_real


DELETE ca_det_trn
WHERE dtr_operacion  = @w_operacion_real
  AND dtr_secuencial = @w_secuencial

  
DELETE ca_transaccion
WHERE tr_secuencial = @w_secuencial
  AND tr_operacion  = @w_operacion_real
  AND tr_tran       = 'DES'
       

--delete históricos
DELETE ca_operacion_his
WHERE oph_secuencial = @w_secuencial
  AND oph_operacion  = @w_operacion_real
  
  
DELETE ca_rubro_op_his
WHERE roh_secuencial = @w_secuencial
  AND roh_operacion  = @w_operacion_real


DELETE ca_dividendo_his
WHERE dih_secuencial = @w_secuencial
  AND dih_operacion  = @w_operacion_real

DELETE ca_amortizacion_his
WHERE amh_secuencial = @w_secuencial
  AND amh_operacion  = @w_operacion_real
  

DELETE ca_cuota_adicional_his
WHERE cah_secuencial = @w_secuencial
  AND cah_operacion  = @w_operacion_real


--LPO REVERSA LIQUIDA por Coreografia FIN


return 0

ERROR:

exec cobis..sp_cerror
        @t_debug = 'N',
        @t_file  = '',
        @t_from  = @w_sp_name,
        @i_num   = @w_error

   return @w_error
GO

