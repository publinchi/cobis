
/***********************************************************************/
/*      Archivo:                        sp_tramite_busin.sp            */
/*      Stored procedure:               sp_tramite_busin               */
/*      Base de Datos:                  cob_pac                        */
/*      Producto:                       Credito                        */
/*      Disenado por:                   Jonatan Rueda                  */
/***********************************************************************/
/*                         IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "COBISCORP", representantes exclusivos para el Ecuador de la       */
/*  "COBISCORP CORPORATION".                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier alteracion o agregado hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de la            */
/*  Presidencia Ejecutiva de COBISCORP o su representante.             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*  Implementacion de regla desde el sp tramite modificado             */
/*    para te creemos                                                  */
/*                                                                     */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                       RAZON              */
/*   11/Mar/2019     Jonatan Rueda     Emision Inicial                 */
/*   13-Mar-2019     Edison Cajas      Se Agrega nuevos campos Datos   */
/*                                     del Credito                     */
/*   07/May/2019     Felipe Borja      Int. orquestador originacion    */
/*   10/Jul/2019     Jonathan Tomalá   Modificacion manejo de seguros  */
/*   07/Ago/2019     Jose Escobar      Manejo de seguros               */
/***********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_tramite_busin')
   drop proc sp_tramite_busin
go

IF OBJECT_ID ('dbo.sp_tramite_busin') IS NOT NULL
    DROP PROCEDURE dbo.sp_tramite_busin
GO

CREATE PROCEDURE dbo.sp_tramite_busin (
@s_ssn                      int         = null,
@s_user                     login       = null,
@s_sesn                     int         = null,
@s_term                     descripcion = null, --MTA
@s_date                     datetime    = null,
@s_srv                      varchar(30) = null,
@s_lsrv                     varchar(30) = null,
@s_rol                      smallint    = NULL,
@s_ofi                      smallint    = NULL,
@s_org_err                  char(1)     = NULL,
@s_error                    int         = NULL,
@s_sev                      tinyint     = NULL,
@s_msg                      descripcion = NULL,
@s_org                      char(1)     = NULL,
@t_rty                      char(1)     = null,
@t_trn                      int         = null,
@t_debug                    char(1)     = 'N',
@t_file                     varchar(14) = null,
@t_from                     varchar(30) = null,
@t_show_version             bit         = 0, -- Mostrar la version del programa
@s_culture                  varchar(10) = 'NEUTRAL',
@i_operacion                char(1)     = null,
@i_tramite                  int         = null,
@i_tipo                     char(1)     = null,
@i_truta                    tinyint     = null,
@i_oficina_tr               smallint    = null,
@i_usuario_tr               login       = null,
@i_fecha_crea               datetime    = null,
@i_oficial                  smallint    = null,
@i_sector                   catalogo    = null,
@i_ciudad                   int         = null,
@i_estado                   char(1)     = null,
--@i_nivel_ap               tinyint     = null,
--@i_fecha_apr              datetime    = null,
--@i_usuario_apr            login       = null,
@i_numero_op_banco          cuenta      = null,
@i_migarada                 cuenta      = null,        --RZ
@i_cuota                    money       = null,
@i_frec_pago                catalogo    = null,
@i_moneda_solicitada        tinyint     = null,
@i_provincia                int         = null,
@i_monto_solicitado         money       = null,
@i_monto_desembolso         money       = null,
@i_pplazo                   smallint    = null,
@i_tplazo                   catalogo    = null,
/* campos para tramites de garantias */
@i_proposito                catalogo    = null,
@i_razon                    catalogo    = null,
@i_txt_razon                varchar(255)= null,
@i_efecto                   catalogo    = null,
/* campos para lineas de credito */
@i_cliente                  int         = null,
@i_grupo                    int         = null,
@i_fecha_inicio             datetime    = null,
@i_num_dias                 smallint    = 0,
@i_per_revision             catalogo    = null,
@i_condicion_especial       varchar(255)= null,
@i_rotativa                 char(1)     = null,
@i_destino_fondos           varchar(255)= null,
@i_comision_tramite         float       = null,
@i_subsidio                 float       = null,
@i_tasa_aplicar             float       = null,
@i_tasa_efectiva            float       = null,
@i_plazo_desembolso         smallint    = null,
@i_forma_pago               varchar(255)= null,
@i_plazo_vigencia           smallint    = null,
@i_origen_fondos            varchar(255)= null,
@i_formalizacion            catalogo    = null,
@i_cuenta_corrientelc       cuenta      = null,
/* operaciones originales y renovaciones */
@i_linea_credito            cuenta      = null,
@i_toperacion               catalogo    = null,
@i_producto                 catalogo    = null,
@i_monto                    money       = null,
@i_moneda                   tinyint     = null,
@i_periodo                  catalogo    = null,
@i_num_periodos             smallint    = 0,
@i_destino                  catalogo    = null,
@i_ciudad_destino           int         = null,
--@i_cuenta_corriente cuenta            = null,
--@i_garantia_limpia  char(1)           = null,  --JSB 99-07-14 cambio de char por char(1)
-- solo para prestamos de cartera
@i_reajustable              char(1)     = null,
@i_per_reajuste             tinyint     = null,
@i_reajuste_especial        char(1)     = null,
@i_fecha_reajuste           datetime    = null,
@i_cuota_completa           char(1)     = null,
@i_tipo_cobro               char(1)     = null,
@i_tipo_reduccion           char(1)     = null,
@i_aceptar_anticipos        char(1)     = null, --JSB 99-07-14 cambio de char por char(1)
@i_precancelacion           char(1)     = null, --JSB 99-07-14 cambio de char por char(1)
@i_tipo_aplicacion          char(1)     = null, --JSB 99-07-14 cambio de char por char(1)
@i_renovable                char(1)     = null, --JSB 99-07-14 cambio de char por char(1)
@i_fpago                    catalogo    = null,
@i_cuenta                   cuenta      = null,
-- generales
@i_renovacion               smallint    = null,
@i_cliente_cca              int         = null,
@i_es_acta                  char(1)     = null,
@i_op_renovada              cuenta      = null,
@i_deudor                   int         = null,
-- reestructuraciones
@i_op_reestructurar         cuenta      = null,
@i_sector_contable          catalogo    = null,  --TME 08/09/98 nuevas variables
@i_cupos_terceros           catalogo    = null,
--@i_tamano_empresa         catalogo    = null,
--@i_referencia_bmi         varchar(30) = null,
--@i_unidad_medida          catalogo    = null,
--i_tipo_empresa            catalogo    = null,
--@i_tipo_sector            catalogo    = null,
--@i_cantidad               int = null,
@i_origen_fondo             catalogo    = null,  --JCL 26/05/98
@i_fondos_propios           char(1)     = null,
--@i_clabas                 catalogo    = null,
--@i_claope                 catalogo    = null,
--@i_fecha_contrato         datetime    = null,
@i_plazo                    catalogo    = null,
--i_uso_financiamiento      varchar(24) = null,
--@i_forma_cont             catalogo    = null,
--@i_dias_desembolso        smallint    = null,
--@i_fecha_ins_desembolso   datetime    = null,
@i_tram_anticipo            int         = null,
@i_ssn                      int         = null,
--Financiamientos           JSB 99-03-30
@i_trm_tmp                  int         = null,
@i_revolvente               char(1)     = null,
--@i_oficial_conta          smallint    = null,
@i_her_ssn                  int         = null,
--@i_cem                    money       = null,     --cem
@i_causa                    char(1)     = null,     -- Personalizaci+n Banco Atlantic
@i_contabiliza              char(1)     = null,     --Persobalizaci+n Banco Atlantic
@i_tvisa                    varchar(24) = null,     --Persobalizaci+n Banco Atlantic
@i_migrada                  cuenta      = null,        --RZ
@i_tipo_linea               varchar(10) = null,
@i_plazo_dias_pago          int         = null,
@i_tipo_prioridad           char(1)     = null,
@i_linea_credito_pas        cuenta      = null,
--@i_documento              varchar(10) = null,
@i_linea_cancelar           varchar(20) = null,
@i_fecha_irenova            datetime    = null,
@i_fdescuento               catalogo    = null,    --Vivi
@i_cta_descuento            cuenta      = null,    --Vivi
@i_proposito_op             catalogo    = null,    --Vivi
@i_subtipo                  catalogo    = null,    --Vivi - CD00013, 2/May/05
@i_tipo_tarjeta             catalogo    = null,    --Vivi - CD00013, 2/May/05
@i_motivo                   catalogo    = null,    --Vivi
@i_plazo_pro                int         = null,    --Vivi
@i_fecha_valor              char(1)     = null,    --Vivi
@i_estado_lin               catalogo    = null,    --Vivi
@i_tasa_asociada            char(1)     = null,
@i_tpreferencial            char(1)     = 'N',
@i_porcentaje_preferencial  float       = null,
@i_monto_preferencial       money       = 0,
@i_abono_ini                money       = null,
@i_opcion_compra            money       = null,
@i_beneficiario             descripcion = null,
@i_ult_tramite              int         = null,    --Vivi, Tramite del que hereda condiciones si tiene linea asociada
@i_empleado                 int         = null,    --Vivi, C+digo del empleado para Tarjeta Corporativa
@i_financia                 char(1)     = null,
@i_tran_servicio            char(1)     = 'S',     --DAG
@i_medio                    int         = null,
@i_migracion                char(1)     = 'N',     --Vivi, se envia S cuando se desea migrar
@i_nombre_empleado          varchar(40) = null,       --Nombre del Empleado para Linea Visa
@i_formato_fecha            tinyint     = 103,     --LIM 30/Mar/2006
@i_canal                    tinyint     = 0,          -- Canal: 0=Fronend  1=Batch   2=Workflow
@i_promotor                 int         = null,
@i_comision_pro             float       = null,
@i_iniciador                descripcion = null,
@i_entrevistador            descripcion = null,
@i_vendedor                 descripcion = null,
@i_cuenta_vende             descripcion = null,
@i_agencia_venta            descripcion = null,
@i_aut_valor_aut            money       = null,
@i_aut_abono_aut            money       = null,
@i_canal_venta              catalogo    = null,
@i_referido                 varchar(1)  = null,
@i_FIniciacion              datetime    = null,
-- Prestamos Gemelos
@i_gemelo                   char(1)     = null,
@i_tasa_prest_orig          float       = null,
@i_banco_padre              cuenta      = null,
@i_num_cuenta               char(16)    = null,
@i_prod_bancario            smallint    = null,
@i_actsaldo                 char(1)     = 'N',

--PCOELLO Para manejo de Promociones
@i_monto_promocion          money        = null,       --Valor que se va a dar al cliente por promocion
@i_saldo_promocion          money        = null,       --Saldo pendiente de pago de la promocion
@i_tipo_promocion           catalogo     = null,    --Tipo de promocion
@i_cuota_promocion          money        = null,       --Cuota mensual a pagar por el cliente por promocion
@i_workflow                 char(1)      = null,     -- ABE Variable para que se ejecute desde el m=dulo de Workflow
@i_id_inst_proc             int          = null,         --Instancia de proceso de CWF
@i_compra_operacion         char(1)      = 'N',      --SRO, 25 Marzo 2009, indica si la operacion de factoring es comprada o no.
@i_destino_descripcion      descripcion  = null,   --DCH, 02-Feb-2015 Descripcion especifica del destino
@i_patrimonio               money        = null,        --JMA, 02-Marzo-2015
@i_ventas                   money        = null,         --JMA, 02-Marzo-2015
@i_num_personal_ocupado     int          = null,           --JMA, 02-Marzo-2015
@i_tipo_credito             catalogo     =  null,     --JMA, 02-Marzo-2015
@i_indice_tamano_actividad  float        = null,       --JMA, 02-Marzo-2015
@i_objeto                   catalogo     = null,     --JMA, 02-Marzo-2015
@i_actividad                catalogo     = null,     --JMA, 02-Marzo-2015
@i_descripcion_oficial      descripcion  = null,    --JMA, 02-Marzo-2015
@i_sindicado                char(1)      = 'N',    --JMA, 02-Marzo-2015
@i_tipo_cartera             catalogo     = null,    --JMA, 02-Marzo-2015
@i_ventas_anuales           money        = null,    --NMA, 10-Abril-2015
@i_activos_productivos      money        = null,     --NMA, 10-Abril-2015
@i_sector_cli               catalogo     = null,  -- JCA, 05-Mayo-2015 ORI-H005-3 Activdad Analisis del Oficial / Sector y Actividad del Cliente
@i_cuota_maxima             float        = null,    --NMA campo nuevo en cr_liquida
@i_cuota_maxima_linea       float        = null,     --NMA campo nuevo en cr_liquida
@i_expromision              catalogo     = null,     --JES 05-Junio-2015

@i_level_indebtedness       char(1)      = null,                      --DCA
@i_asigna_fecha_cic         char(1)      = null,

@i_convenio                 char(1)      = null,
@i_codigo_cliente_empresa   varchar(10)  = null,
@i_reprogramingObserv       varchar(255) = null, --MCA - Observación de la reprogramación
@i_motivo_uno               varchar(255) = null, -- ADCH, 05/10/2015 motivo para tipo de solicitud
@i_motivo_dos               varchar(255) = null, -- ADCH, 05/10/2015 motivo para tipo de solicitud
@i_motivo_rechazo           catalogo     = null,
@i_valida_estado            char(1)      = 'S',
@i_numero_testimonio        varchar(50)  = null,
@i_tamanio_empresa          VARCHAR(5)   = null, -- ABE Tamaño de la empresa
@i_producto_fie             catalogo     = null,
@i_num_viviendas            tinyint      = null,
@i_tipo_calificacion        catalogo     = null,
@i_calificacion             catalogo     = null,
@i_es_garantia_destino      char(1)      = null,
@i_tasa                     float        = null,
@i_sub_actividad            catalogo     = null,
@i_departamento             catalogo     = null,

--CAMPOS AUMENTADOS EN INTEGRACION FIE
@i_actividad_destino        catalogo     = null,       --SPO Actividad economica de destino
@i_parroquia                catalogo     = null,   -- ITO:12/12/2011
@i_canton                   catalogo     = null,
@i_barrio                   catalogo     = null,
@i_toperacion_ori           catalogo     = null, --Policia Nacional: Se incrementa por tema de interceptor
@i_credito_es               catalogo     = null,
@i_financiado               char(2)      = null,
@i_presupuesto              money        = null,
@i_fecha_avaluo             datetime     = null,
@i_valor_comercial          money        = null,
@o_tramite                  int          = null out,
@i_dia_fijo                 smallint     = null,
@i_enterado                 catalogo     = null,
@i_otros_ent                varchar(64)  = null,
-- FBO Tabla Amortizacion
@i_pasa_definitiva          char(1)      = 'S',
@i_regenera_rubro           char(1)      = 'S',
-- Manejo de seguros
@i_seguro_basico            char(1)      = null,
@i_seguro_voluntario        char(1)      = null,
@i_tipo_seguro              catalogo     = NULL,
@i_tipo_prod                CHAR(1)      = NULL,  --LPO CDIG APIS II   
@i_dias_anio                SMALLINT     = NULL,  --LPO CDIG APIS II
@i_tipo_amortizacion        VARCHAR(30)  = NULL,  --LPO CDIG APIS II
@i_tdividendo               SMALLINT     = NULL,  --LPO CDIG APIS II
@i_periodo_cap              INT          = NULL,  --LPO CDIG APIS II
@i_periodo_int              INT          = NULL,  --LPO CDIG APIS II
@i_dist_gracia              CHAR(1)      = NULL,  --LPO CDIG APIS II   
@i_gracia_cap               INT          = NULL,  --LPO CDIG APIS II
@i_gracia_int               INT          = NULL,  --LPO CDIG APIS II
@i_evitar_feriados          CHAR(1)      = NULL,  --LPO CDIG APIS II
@i_renovac                  CHAR(1)      = NULL,  --LPO CDIG APIS II
@i_mes_gracia               INT          = NULL,  --LPO CDIG APIS II
@i_clase_cartera            catalogo     = NULL,  --LPO CDIG APIS II
@i_base_calculo             CHAR(1)      = NULL,  --LPO CDIG APIS II
@i_causacion                CHAR(1)      = NULL,  --LPO CDIG APIS II
@i_convierte_tasa           CHAR(1)      = NULL,  --LPO CDIG APIS II
@i_tasa_equivalente         CHAR(1)      = NULL,  --LPO CDIG APIS II
@i_nace_vencida             CHAR(1)      = NULL   --LPO CDIG APIS II


)
as
declare
@w_spid                     smallint,     --OGU 07/08/2012
@w_today                    datetime,     /* fecha del dia */
@w_error                    int,          /* valor que retorna */
@w_sp_name                  varchar(32),  /* nombre stored proc*/
@w_existe                   tinyint,      /* existe el registro*/
@w_tramite                  int,
--@w_truta                  tinyint ,
@w_tipo                     char(1) ,
@w_oficina_tr               smallint,
@w_usuario_tr               login ,
@w_fecha_crea               datetime ,
@w_oficial                  smallint ,
@w_sector                   catalogo ,
@w_ciudad                   int ,
@w_estado                   char(1) ,
--@w_nivel_ap               tinyint ,
--@w_fecha_apr              datetime ,
--@w_usuario_apr            login ,
--@w_secuencia              smallint ,
@w_numero_op                int,
@w_numero_op_banco          cuenta,
--@w_aprob_por              login,
--@w_nivel_por              tinyint,
--@w_comite                 catalogo,
--@w_acta                   cuenta,
@w_proposito                catalogo ,   /* garantias */
@w_razon                    catalogo ,
@w_txt_razon                varchar(255),
@w_efecto                   catalogo,
@w_cliente                  int ,       /* lineas de credito */
@w_grupo                    int ,
@w_fecha_inicio             datetime ,
@w_num_dias                 smallint ,
@w_per_revision             catalogo ,
@w_condicion_especial       varchar(255),
@w_linea_credito            int ,    /* renovaciones y operaciones */
@w_toperacion               catalogo ,
@w_producto                 catalogo ,
@w_monto                    money,
@w_moneda                   tinyint,
@w_periodo                  catalogo,
@w_num_periodos             smallint,
@w_destino                  catalogo,
@w_ciudad_destino           int,
@w_cuenta_corriente         cuenta ,
--@w_garantia_limpia        char(1) ,
@w_renovacion               smallint,
@w_fecha_concesion          datetime,
@w_cuota                    money,
@w_frec_pago                catalogo,
@w_moneda_solicitada        tinyint,
@w_provincia                int,
@w_monto_solicitado         money,
@w_monto_desembolso         money,
@w_pplazo                   smallint,
@w_tplazo                   catalogo,
/* variables de trabajo */
@w_cont                     int,
@w_numero_aux               int,
@w_linea                    int,
@w_numero_linea             int,
@w_numero_operacion         int,
@w_prioridad                tinyint,
--@o_tramite                int,
@o_linea_credito            cuenta,
@o_numero_op                cuenta,
/* variables para ingreso en cr_ruta_tramite */
@w_estacion                 smallint,
@w_etapa                    tinyint,
@w_login                    login,
@w_paso                     tinyint,
--@w_clabas                 catalogo,
--@w_claope                 catalogo,
@w_origen_fondo             catalogo,
@w_fondos_propios           char(1),
--@w_fecha_contrato         datetime,
@w_cupos_terceros           catalogo,
@w_sector_contable          catalogo,
--@w_tram_anticipo          int,
@w_monto_anticipo           money,
@w_monto_org                money,
@w_monto_linea              money,
@w_moneda_df                tinyint,
--@w_oficial_conta          smallint,
--@w_cem                    money,  --cem
@w_causa                    char(1),     --Personalizaci+n Banco Atlantic
@w_tipo_linea               varchar(10),
@w_tipo_prioridad           char(1),
@w_tot_reg                  int,
@w_operacionca              int,
--@w_documento              varchar(10),
@w_fecha_irenova            datetime,
@w_linea_cancelar           int,
@w_linea_can_sobvis         int,
@w_subtplazo                catalogo,     --Vivi - CD00013
@w_subplazos                smallint,       --Vivi
@w_subdplazo                int,
@w_subtbase                 varchar(10),
@w_subporcentaje            float,
@w_subsigno                 char(1),
@w_subvalor                 float,
@w_linea_cred_ant           cuenta,         --Vivi
@w_tipo_visa                catalogo,       --Vivi
@w_tipo_sobregiro           catalogo,       --Vivi
@w_motivo_suspen            catalogo,       --Vivi
@w_motivo_cancel            catalogo,       --Vivi
@w_tasa_asociada            char(1),
@w_tasa                     float,           --Vivi
@w_medio                    int,
@w_tot                      int,
@w_li_monto                 money,                -- FCP
@w_sp_name1                 VARCHAR(35),  /* nombre stored proc*/
@w_est_vencido              int,
@w_saldo_imo                money,
@w_rubro_imo                catalogo,
@w_grupo_eco                int,             -- BSA
@w_tipo_oper                char(1),
@w_codpais                  VARCHAR(30),  --MDI 21/Nov/2011
@w_nemonico                 VARCHAR(30),
@w_fecha_nueva              datetime,
@w_fecha_anterior           datetime,
@w_banco_anterior           VARCHAR(20),
@w_destino_descripcion      descripcion,
@w_motivo_uno               VARCHAR(255),   -- ADCH, 05/10/2015 motivo para tipo de solicitud
@w_motivo_dos               VARCHAR(255),    -- ADCH, 05/10/2015 motivo para tipo de solicitud

@w_variables                VARCHAR(64),
@w_return_variable          VARCHAR(25),
@w_return_results           VARCHAR(25),
@w_return_results_plazo     VARCHAR(255),
@w_last_condition_parent    VARCHAR(10),
@w_tipo_pa                  VARCHAR(10),
@w_band_regla               INT,
@w_msg                      VARCHAR(255),
@w_valIni                   VARCHAR(20),
@w_valFin                   VARCHAR(20),
@w_frecuency                VARCHAR(20),
@w_plazo_meses              FLOAT,
@w_tramite_ret int,
@w_td_factor   int

if @t_show_version = 1
begin
    print 'Stored procedure sp_tramite_busin, Version 4.0.0.2'
    return 0
end

select @w_spid = @@spid       --OGU 07/08/2012
select @w_return_results = null;

-- JTO Inicio: SOLO SI LA VARIABLE @i_monto_solicitado viene nulo se le asignara el valor de @i_monto
if @i_monto_solicitado is null
begin
-- DFL Inicio: Cambios en variables equivalentes para version base de FIE
   SELECT @i_monto_solicitado = @i_monto
end
-- JTO FIN: SOLO SI LA VARIABLE @i_monto_solicitado viene nulo se le asignara el valor de @i_monto
SELECT @i_moneda_solicitada = @i_moneda
SELECT @i_revolvente = @i_rotativa
-- DFL

select @w_codpais = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ABPAIS'
and pa_producto = 'ADM'

select @w_nemonico = pa_char
from cobis..cl_parametro
where pa_nemonico = 'CLIENT'
and pa_producto = 'ADM'



select     @w_today  = isnull(@s_date, fp_fecha)
from    cobis..ba_fecha_proceso
select     @w_moneda_df = pa_tinyint
from       cobis..cl_parametro
where      pa_nemonico = 'MLOCR'
and        pa_producto = 'CRE'

select @w_sp_name = 'sp_tramite_busin',
       @w_est_vencido = 2

-- Valida si el parametro @i_tplazo es null lo setea con el campo @i_frec_pago
IF @i_tplazo IS NULL
BEGIN
 SELECT @i_tplazo = @i_frec_pago
END

-- Valida si el parametro @i_fecha_irenova es null lo setea con el campo @i_fecha_inicio
if @i_fecha_irenova is null
  begin
      select @i_fecha_irenova = @i_fecha_inicio
  end

-- Se valida si el i_cliente es null para igualar con i_cliente_cca
IF @i_cliente IS NULL
BEGIN
   SELECT @i_cliente = @i_cliente_cca
END

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn != 21820 and @i_operacion = 'I') or
(@t_trn != 21820 and @i_operacion = 'U') or  --21120
(@t_trn != 21220 and @i_operacion = 'D') or
(@t_trn not in (21820,73932) and @i_operacion = 'Q') --21520
begin --Tipo de transaccion no corresponde
   select @w_error = 2101006
   goto ERROR
end
/*if @i_tipo in ('O', 'R', 'E', 'F', 'L', 'P')
    select @i_cem = isnull(@i_cem, 0)*/

if @i_operacion != 'Q'
begin
 /* Chequeo de Existencias */
 /**************************/
 SELECT
     @w_tramite = tr_tramite,
     --@w_truta = tr_truta,
     @w_tipo = tr_tipo,
     @w_oficina_tr = tr_oficina,
     @w_usuario_tr = tr_usuario,
     @w_fecha_crea = tr_fecha_crea,
     @w_oficial = tr_oficial,
     @w_sector = tr_sector,
     @w_ciudad = tr_ciudad,
     @w_estado = tr_estado,
    --@w_nivel_ap = tr_nivel_ap ,
     --@w_fecha_apr = tr_fecha_apr,
     --@w_usuario_apr    = tr_usuario_apr ,
     @w_numero_op = tr_numero_op,
     @w_numero_op_banco = tr_numero_op_banco,
     --@w_aprob_por = tr_aprob_por,
     --@w_nivel_por = tr_nivel_por,
     --@w_comite    = tr_comite,
     --@w_acta      = tr_acta,
     /* garantias*/
     @w_proposito = tr_proposito,
     @w_razon = tr_razon,
     @w_txt_razon = rtrim(tr_txt_razon),
     @w_efecto = tr_efecto,
     /*lineas*/
     @w_cliente = tr_cliente,
     @w_grupo = tr_grupo,
     @w_fecha_inicio = tr_fecha_inicio,
     @w_num_dias = tr_num_dias,
     @w_per_revision = tr_per_revision,
     @w_condicion_especial = tr_condicion_especial,
     /*renov. y operaciones*/
     @w_linea_credito = tr_linea_credito,
     @w_toperacion = tr_toperacion,
     @w_producto = tr_producto,
     @w_monto = tr_monto,
     @w_moneda = tr_moneda,
     @w_periodo = tr_periodo,
     @w_num_periodos = tr_num_periodos,
     @w_destino = tr_destino,
     @w_ciudad_destino = tr_ciudad_destino,
     --@w_cuenta_corriente = tr_cuenta_corriente,
     --@w_garantia_limpia = tr_garantia_limpia,
      @w_renovacion = tr_renovacion,
     --@w_tram_anticipo = tr_tram_anticipo,
     --@w_oficial_conta = tr_oficial_conta,
     --@w_cem = tr_cem,
     @w_causa = tr_causa,         --Personalizaci+n Banco Atlantic
     @w_tipo_linea       = tr_toperacion,
     --@w_documento        = tr_documento,
     @w_fecha_irenova    = tr_fecha_irenova,
     @w_linea_cancelar   = tr_linea_cancelar,
     @w_tasa_asociada    = tr_tasa_asociada,
     --@w_medio            = tr_medio,
     @w_cuota            = tr_cuota,
     @w_frec_pago        = tr_frec_pago,
     @w_moneda_solicitada = tr_moneda_solicitada,
     @w_provincia        = tr_provincia,
     @w_monto_solicitado = tr_monto_solicitado,
     @w_monto_desembolso = tr_monto_desembolso,
     @w_pplazo           = tr_plazo,
     @w_tplazo           = tr_tplazo



 FROM cr_tramite
 WHERE tr_tramite = @i_tramite
 if @@rowcount > 0
  select @w_existe = 1
 else
  select @w_existe = 0

if (@i_tipo = 'P' and (@i_operacion = 'I' or @i_operacion = 'U')) or
   (@i_tipo = 'L' and @i_operacion = 'U')
begin

     /** OBTIENE TIPO DE LINEA DE SOBREGIRO  **/
     --Vivi
     select @w_tipo_sobregiro = pa_char
       from cobis..cl_parametro
      where pa_producto = 'CRE' and pa_nemonico = 'OPSOBG'

     /** OBTIENE MOTIVO DE SUSPENSION Y CANCELACION DE LA LINEA DE SOBREGIRO  **/
    select @w_motivo_suspen = pa_char
      from cobis..cl_parametro
     where pa_producto = 'CRE' and pa_nemonico = 'MOTSUS'

    select @w_motivo_cancel = pa_char
      from cobis..cl_parametro
     where pa_producto = 'CRE' and pa_nemonico = 'MOTCAN'

    -- VERIFICAR LAS DISTRIBUCIONES CONTRA EL MONTO DE LA LINEA
    -- cotizaciones
    /* Lleno una tabla temporal con la cotizacion de las monedas */
       insert into cr_cotiz3_tmp
       (spid, moneda, cotizacion)
       select distinct @w_spid,
       a.ct_moneda, a.ct_compra
       from   cb_cotizaciones a
       where  ct_fecha = (select max(b.ct_fecha)
                  from  cb_cotizaciones b
            where b.ct_moneda = a.ct_moneda
            and   b.ct_fecha <= @w_today)
       -- insertar un registro para la moneda local
    if not exists (select * from cr_cotiz3_tmp
               where moneda = @w_moneda_df)
    insert into cr_cotiz3_tmp (spid, moneda, cotizacion)
       values (@w_spid, @w_moneda_df, 1)

    -- NUEVO MONTO DE LA LINEA DE CREDITO EN ML
    select     @w_monto_linea = isnull(@i_monto,isnull(@w_monto,0)) * cotizacion
    from     cr_cotiz3_tmp
    where    isnull(@i_moneda,isnull(@w_moneda,0)) = moneda

    if @i_tipo = 'L'
        select    @w_numero_linea = li_numero,
                @w_linea_cred_ant = li_num_banco --Vivi
        from    cr_linea
        where    li_tramite = @i_tramite
    else
        select    @w_numero_linea = li_numero * -1,
                @w_linea_cred_ant = li_num_banco, --Vivi
                @w_monto_org      = isnull(li_utilizado, 0),
                @w_li_monto       = li_monto      -- FCP
        from    cr_linea
        where    li_num_banco = @i_linea_credito


      /** VERIFICA SI ES PRORROGA QUE EXISTA SOLO UNA ACTIVA **/
      if (@i_tipo = 'P' and (@i_operacion = 'I' or @i_operacion = 'U')) and
          exists( select 1 from cr_tramite
                 where tr_tipo = 'P' and tr_tramite != @i_tramite and tr_linea_credito = abs(@w_numero_linea) and tr_numero_op_banco is null and tr_estado != 'Z' )
      begin
         select @w_error = 2101079
         goto ERROR
      end


      /** NO SE PERMITE CREAR UNA PRORROGA CON VALOR MENOR AL UTILIZADO**/
      if @w_monto_linea < @w_monto_org and @i_tipo = 'P' and @i_motivo != @w_motivo_suspen
      begin
         if @w_tipo_sobregiro = isnull(@w_toperacion, @i_tipo_linea) and @i_motivo = @w_motivo_cancel
             select @w_tipo_sobregiro = @w_toperacion
         else
         begin
            if @i_motivo = @w_motivo_cancel
            begin
               select @w_error = 2101084
               goto ERROR
            end
         end
      end
/* IOR se comenta para caso de devolucion y cambio de monto total, se controla en la distribucion
    -- EVALUACION CON DISTRIBUCION DE LA LINEA
    if exists (    select  1
        from     cr_lin_ope_moneda, cr_cotiz3_tmp
        where     om_linea = @w_numero_linea
        and    om_moneda = moneda
        and om_monto * cotizacion > @w_monto_linea     )
    begin
        -- ERROR: Existen distribuciones que superan el monto total de la Linea de Credito
              select @w_error = 2101085
              goto ERROR
    end
*/


  /** MONTO APROBADO DEL SUBLIMITE NO DEBE SER MENOR A UTILIZADO DEL SUBLIMITE **/
     if (@i_tipo = 'L' or (@i_tipo = 'P' and @i_motivo != @w_motivo_suspen ) ) and
             exists (select 1 from cr_lin_ope_moneda
                     where om_linea = @w_numero_linea
                       and om_monto < om_utilizado )
     begin
         if @w_tipo_sobregiro = isnull(@w_toperacion, @i_tipo_linea) and @i_motivo = @w_motivo_cancel
              select @w_tipo_sobregiro = @w_toperacion
         -- else
         -- begin
         --       if @i_motivo in ( @w_motivo_cancel, 'DISM', 'REDI')
         --       begin
                   --              -- ' Existen distribuciones en que el monto es menor al Utilizado del Sublimite'
         --          select @w_error = 2101086
         --          goto ERROR
         --       end
           -- end
     end


    -- EVALUACION CON DISTRIBUCION DE LA LINEA EN MIEMBROS DE GRUPO
    if exists (    select  1
        from     cr_lin_grupo
        where     lg_linea = @w_numero_linea
        and lg_monto > isnull(@i_monto,isnull(@w_monto,0)) )
    begin
        -- ERROR: Existen distribuciones entre los miembros de grupo que superan
        -- el monto total de la Linea de Credito
          select @w_error = 2101085
              goto ERROR
    end

     /** OBTIENE TIPO DE LINEA DE VISA  **/
     --Vivi
     select @w_tipo_visa = pa_char
       from cobis..cl_parametro
      where pa_producto = 'CRE'
        and pa_nemonico = 'OPVISA'

end

/*INI SNU 13/08/2009 Validacion para la reestructuracion */
if @i_tipo = 'E'
begin
   select @w_saldo_imo  = sum(am_cuota + am_gracia - am_pagado)
     from cob_cartera..ca_operacion, cob_cartera..ca_amortizacion, cob_cartera..ca_rubro_op
    where op_operacion  = am_operacion
      and am_operacion  = ro_operacion
      and am_concepto   = ro_concepto
      and ro_tipo_rubro = 'M'
      and op_banco      = @i_op_reestructurar


  if (@w_nemonico = 'MIB'  and @w_codpais = 'PA') -- MDI  para MIB
  begin
     select @w_tipo_oper = op_tipo  from cob_cartera..ca_operacion where op_banco  = @i_op_reestructurar

     if @w_tipo_oper != 'N'
     begin
        exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 2110385
       return 1
     end
   end


   /* SE COMENTA POR EL REDMINE 60437 PROYECTO FIE
   if isnull(@w_saldo_imo,0) != 0
   begin
      exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = 2107036,
           @i_msg   = 'No se puede crear reestructuraciones, la operacion tiene saldo de Interes en Mora'
      return 1
   end*/
end


if @i_tipo = 'R'
  if (@w_nemonico = 'MIB'  and @w_codpais = 'PA') -- MDI  para MIB
  begin
    select @w_fecha_nueva = op_fecha_ini from cob_cartera..ca_operacion where op_tramite = @i_tramite

   select @w_banco_anterior = or_num_operacion, @w_fecha_anterior = op_fecha_ult_proceso
   from cob_credito..cr_op_renovar, cob_cartera..ca_operacion
   where or_tramite = @i_tramite
     and op_banco   = or_num_operacion
     and op_fecha_ult_proceso != @w_fecha_nueva
   if @@rowcount != 0
   begin
       print 'Atención la operación nueva inicia el :'+ convert(varchar(10),@w_fecha_nueva,103) +'  y la operación anterior  '+ @w_banco_anterior +' tiene fecha valor al '+ convert(varchar(10),@w_fecha_anterior,103)
       return 1
   end

  end

/* FIN SNU 13/08/2009 Validacion para la reestructuracion */

/* BSA 15/09/2009 Validacion de distribucion a miembro del grupo */

if @i_tipo = 'O' and @i_linea_credito is not null
begin
     select @w_linea     = li_numero,
            @w_grupo_eco = li_grupo
     from   cr_linea
     where  li_num_banco = @i_linea_credito

     if @w_grupo_eco is not null
     begin
          /* SRO INI 06/NOV/2009 CR00071 */
          if @w_existe = 1
          begin
             select @i_deudor = de_cliente
             from cob_credito..cr_deudores
             where de_tramite = @i_tramite
               and de_rol = 'D'
          end
          /* SRO FIN 06/NOV/2009 CR00071 */

          if not exists(select 1 from cr_lin_grupo
          where    lg_linea   = @w_linea
          and      lg_cliente = @i_deudor)

          begin
               exec cobis..sp_cerror
                  @t_debug  =  @t_debug,
                  @t_file   =  @t_file,
                  @t_from   =  @w_sp_name,
                  @i_num    =  2107037
               return 1
          end
      end
end

/* ABE select @w_secuencia = rt_secuencia,
       @w_paso =  rt_paso
from   cr_ruta_tramite
where  rt_tramite = @i_tramite
and    rt_salida is NULL
if @@rowcount = 0
       select @w_secuencia = max(rt_secuencia)
       from   cr_ruta_tramite
       where  rt_tramite = @i_tramite*/

/* Chequeo de Linea de Credito */
if @i_linea_credito is not null
begin
    if (@i_operacion = 'I' or @i_operacion = 'U') and @i_tipo = 'O'
    begin
        if exists (    select  1
                      from     cr_lin_ope_moneda, cr_linea
                     where     om_linea = li_numero
                       and li_num_banco = @i_linea_credito
                       and om_toperacion = @i_toperacion
                       and  ((om_monto - om_utilizado) < isnull(@i_monto,isnull(@w_monto,0))))
        begin
            exec cobis..sp_cerror
                          @t_debug  =  @t_debug,
                          @t_file   =  @t_file,
                          @t_from   =  @w_sp_name,
                          @i_num    =  2107043
            return 1
        end
    end

    select
    @w_numero_linea = li_numero,
    @w_li_monto     = li_monto      -- FCP
    from       cob_credito..cr_linea
    where    li_num_banco = @i_linea_credito
    If @@rowcount = 0
    begin
        if @i_operacion = 'I'
              delete cr_deudores_tmp where dt_ssn = @i_ssn
            /** registro no existe **/
            select @w_error = 2101010
            goto ERROR
    end

     /** VERIFICA SI ES PRORROGA QUE EXISTA SOLO UNA ACTIVA **/
     if (@i_tipo = 'P' and (@i_operacion = 'I' or @i_operacion = 'U')) and
         exists( select 1 from cr_tramite
                 where tr_tipo = 'P' and tr_tramite != @i_tramite and tr_linea_credito = abs(@w_numero_linea) and tr_numero_op_banco is null and tr_estado != 'Z' )
     begin
         select @w_error = 2101079
         goto ERROR
     end

     --IOR - 2015/05/10
     /*If (@i_operacion = 'I' or @i_operacion = 'U') and @i_tipo != 'P' and @i_tipo != 'L' and @i_tipo != 'G'
     begin
        if not exists( select 1 from cr_lin_ope_moneda
                        where om_linea      = @w_numero_linea and
                              om_toperacion  = @i_toperacion and
                              om_producto    = @i_producto   and
                              om_moneda      = isnull(@i_moneda,@w_moneda) and
                              om_proposito_op= @i_proposito_op  )
        begin
           -- FCP CREA LA DISTRIBUCION POR EL PROPOSITO INEXISTENTE
           print 'sp_tramite:  SE CREA UN PROPOSITO ESPECIFICO AUTOMATICAMENTE EN LA DISTRIBUCION'

           exec @w_error = sp_lin_ope_moneda
              @s_ssn          = @s_ssn,
              @s_user         = @s_user,
              @s_sesn         = @s_sesn,
              @s_term         = @s_term,
              @s_date         = @s_date,
              @s_srv          = @s_srv,
              @s_lsrv     = @s_lsrv,
              @s_rol          = @s_rol,
              @s_ofi          = @s_ofi,
              @s_org_err      = @s_org_err,
              @s_error        = @s_error,
              @s_sev          = @s_sev,
              @s_msg          = @s_msg,
              @s_org          = @s_org,
              @t_rty          = @t_rty,
              @t_debug        = @t_debug,
              @t_file         = @t_file,
              @t_from         = @t_from,
                @t_trn          = 21023,
                 @i_operacion    = 'I',
             @i_linea        = @w_numero_linea,
             @i_toperacion   = @i_toperacion,
             @i_producto     = @i_producto,
             @i_moneda       = isnull(@i_moneda,@w_moneda),
              @i_monto        = @w_li_monto,
             @i_condicion_especial = @i_condicion_especial,
             @i_proposito_op = @i_proposito_op

           if @w_error != 0 goto ERROR

           -- FCP COMENTO PARA LIBERACION
           --select @w_error =  2101081
           --goto ERROR
        end
     end*/
end

/* Chequeo de Numero de operacion */
if @i_numero_op_banco is not null
begin
    If @i_producto = 'CCA'
    begin
        select    @w_numero_operacion = op_operacion
        from       cob_cartera..ca_operacion
        where    op_banco = @i_numero_op_banco
        If @@rowcount = 0
        begin
                if @i_operacion = 'I'
                      delete cr_deudores_tmp where dt_ssn = @i_ssn
        /** registro no existe **/
                   select @w_error =  2101011
                   goto ERROR
        end
    end
 end
end


If @i_operacion = 'I' or @i_operacion = 'U'
begin

   /* SYR 12/Julio/2007 */
   /* Chequeo Anticipos */
   if (@i_tram_anticipo = 1 and @i_operacion = 'U')
   begin

        select @w_monto_anticipo = isnull(sum(tr_monto), 0)
        from cr_tramite
        where tr_tramite = @i_tramite

        select @w_monto_org = isnull(sum(tr_monto), 0)
        from cr_anticipo, cr_tramite
        where an_tram_anticipo = @i_tramite
          and tr_tramite = an_tramite_org

        if isnull(@i_monto,isnull(@w_monto,0)) >= @w_monto_org
        begin
       if @i_operacion = 'I'
              delete cr_deudores_tmp where dt_ssn = @i_ssn

           select @w_error =  710271 --'[sp_tramite_busin] El monto del anticipo tiene que ser menor al monto original'
           goto ERROR
        end
   end

   /** Obtener prioridad **/
   SELECT @w_prioridad = tt_prioridad
   from   cr_tipo_tramite
   where  tt_tipo = @i_tipo

   if @@rowcount = 0
   begin
      select @w_prioridad = 1
   end
   --INTEGRACION A FIE, CORRECCION DE LOS CAMPOS PARA INSERCION O ACTUALIZACION (I o U)
    /*SELECT @i_provincia = @i_ciudad_destino
    SELECT @i_ciudad_destino = convert(INT,@i_parroquia)*/


--LPO CDIG Se quitan estas reglas porque eran solo de la version Te Creemos INICIO
/*
   --VALIDACION DE REGLAS
--REGLA DE DIA DE PAGO
select @w_frecuency = td_tdividendo
        from   cob_cartera..ca_tdividendo
        where  td_tdividendo = @i_tplazo

select @w_variables = @i_toperacion + '|'
                      + @w_frecuency

--PRINT 'VARIABLES DIA_PAGO::'+ @w_variables

   exec @w_error               = cob_pac..sp_rules_param_run
      @s_rol                   = @s_rol,
      @i_rule_mnemonic         = 'DIA_PAGO',
      @i_var_values            = @w_variables,
      @i_var_separator         = '|',
      @o_return_variable       = @w_return_variable  OUT,
      @o_return_results        = @w_return_results   OUT,
      @o_last_condition_parent = @w_last_condition_parent OUT

SELECT @w_return_results = replace(@w_return_results,'|','')

SELECT @w_valIni = substring(@w_return_results,1,(charindex('-',@w_return_results)-1))

SELECT @w_valFin = substring(@w_return_results,charindex('-',@w_return_results)+1,(len(@w_return_results)-(charindex('-',@w_return_results)-1)))

--PRINT '@w_valIni:::'+ @w_valIni+'::@w_valFin::'+@w_valFin+'::@i_dia_fijo::'+CONVERT(varchar(20), @i_dia_fijo)

IF(convert(INT,@w_valIni) > @i_dia_fijo OR convert(INT,@w_valFin) < @i_dia_fijo)
BEGIN
     select @w_error =  2110105
     goto ERROR
END

    --REGLA DE PLAZOS
           --validacion de los campo tipo de tramite

    if @i_tplazo not in('W','Q' )
        begin
			select @w_td_factor = td_factor from cob_cartera..ca_tdividendo where  td_tdividendo = @i_tplazo
            select  @w_plazo_meses = (isnull(@i_pplazo, 0) * @w_td_factor)/30.0
--            select  @w_plazo_meses = isnull((@i_pplazo * (select td_factor
--                                         from   cob_cartera..ca_tdividendo
--                                         where  td_tdividendo = @i_tplazo)
--                                         )/30.0,0)
        end
        else
        begin
           if @i_tplazo = 'W'
           begin
               SELECT  @w_plazo_meses = convert(INT,(@i_pplazo/(52/12.0)))
           end
           if @i_tplazo = 'Q'
           begin
               SELECT @w_plazo_meses = @i_pplazo / 2
           end
        end
        print '::plazo en meses::'+convert(varchar(25),@w_plazo_meses)

--LPO CDIG Se comenta temporalmente hasta revisar con el eqipo de Workflow y Cobis Language el manejo de reglas INICIO

    if(@w_plazo_meses > 0)
    begin
        IF (@i_tipo = 'R')
          SELECT  @w_tipo_pa='S'
        ELSE
          SELECT @w_tipo_pa = 'N'

        select @w_variables = @i_toperacion + '|'
                              + convert(VARCHAR(25),@i_monto)+ '|'
                              + (SELECT p_calif_cliente FROM cobis..cl_ente
                                 WHERE en_ente = @i_deudor) + '|'
                              + @w_tipo_pa

        --PRINT 'VARIABLES:>'+ @w_variables
           exec @w_error               = cob_pac..sp_rules_param_run
                @s_rol                   = @s_rol,
                @i_rule_mnemonic         = 'RPLAZ',
                @i_var_values            = @w_variables,
                @i_var_separator         = '|',
                @o_return_variable       = @w_return_variable  OUT,
                @o_return_results        = @w_return_results_plazo   OUT,
                @o_last_condition_parent = @w_last_condition_parent OUT

           --PRINT 'Error obtenido:'+ convert(varchar(20),@w_error)
              IF @w_error > 0
              begin
                 goto ERROR
              end
              else
              Begin
                SELECT @w_return_results_plazo = replace(@w_return_results_plazo,'|','')
                IF @w_return_results_plazo is null
              BEGIN
                    --El cliente no cumple con la calificación esperada
                    select @w_error =  2110107
                    goto ERROR
                END
            IF @w_return_results_plazo = '0'
              BEGIN
             select @w_error =  2110104
             goto ERROR
              END
        --PRINT 'RETORNO VARIABLE:>'+ @w_return_variable
        --PRINT 'RETORNO RESULTS:>'+ @w_return_results_plazo
        --PRINT '@i_pplazo:>'+ convert(varchar(25),@i_pplazo)
            --comparacion de los plazos a validar
            if not exists(SELECT number FROM cob_pac..intlist_to_tbl(@w_return_results_plazo,',') WHERE number = @w_plazo_meses)
                BEGIN
                 --print 'error plazo'
                 select @w_msg = 'Plazo no permitido, Los plazos permitidos son: '+ convert(varchar(100),@w_return_results_plazo)+' meses'
                 exec cobis..sp_cerror
                      @t_debug = @t_debug,
                      @t_file  = @t_file,
                      @t_from  = @w_sp_name,
                      @i_num   = 2110106,
                      @i_sev   = 1,
                      @i_msg   = @w_msg
                return @w_error
               END
              end
    end
    else
    begin
         select @w_msg = 'Plazo no permitido'
             exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file,
                  @t_from  = @w_sp_name,
                  @i_num   = 2110106,
                  @i_sev   = 1,
                  @i_msg   = @w_msg
             return @w_error
    END

--LPO CDIG Se comenta temporalmente hasta revisar con el eqipo de Workflow y Cobis Language el manejo de reglas FIN
*/
--LPO CDIG Se quitan estas reglas porque eran solo de la version Te Creemos FIN
end



/* Insercion del registro */
/**************************/
if @i_operacion = 'I'
begin
    if @i_tipo is NULL
    begin
        delete cr_deudores_tmp where dt_ssn = @i_ssn
        /* Campos NOT NULL con valores nulos */
        select @w_error =  2101001
        goto ERROR
    end

    if @i_linea_cancelar is not NULL   --recupero numero interno de linea
    begin
       select @w_linea_cancelar=li_numero
         from cr_linea
        where li_num_banco=@i_linea_cancelar
    end

    --INTEGRACION FIE
    IF(@i_cliente IS NULL AND @i_tipo = 'G')
    BEGIN
        SELECT @i_cliente = op_cliente FROM cob_cartera..ca_operacion WHERE op_banco = @i_numero_op_banco
    END

/*Incluir Financiamientos  SBU: 20/abr/2000 */
if (@i_deudor is NULL  and @i_tipo = 'O')
or (@i_deudor is NULL  and @i_tipo = 'R')
or (@i_deudor is NULL  and @i_tipo = 'F')
--or (@i_deudor is NULL  and @i_tipo = 'L')         --Vivi -- DFL
or (@i_deudor is NULL  and @i_tipo = 'P')         --Vivi
begin
if @i_operacion = 'I'
    delete cr_deudores_tmp where dt_ssn = @i_ssn
/* Campos NOT NULL con valores nulos */
    select @w_error =  2101001
    goto ERROR
end

if @w_existe = 1
begin
   if @i_operacion = 'I'
      delete cr_deudores_tmp where dt_ssn = @i_ssn

    select @w_error =  2101002
    goto ERROR
end

--Llamada al stored procedure que inserta tramites
--BEGIN TRAN --Optimizacion JSA
   if @i_trm_tmp is null
begin
      select @i_trm_tmp = @i_ssn

end
select @w_sp_name1 = 'cob_credito..sp_in_tramite_busin',
       @i_monto  = isnull(@i_monto,isnull(@w_monto,0)),
       @i_moneda = isnull(@i_moneda,isnull(@w_moneda,0))

   exec @w_error = @w_sp_name1  --cob_credito..sp_in_tramite
       @s_ssn     = @s_ssn,
       @s_user    = @s_user,
       @s_sesn    = @s_sesn,
       @s_term    = @s_term,
       @s_date    = @s_date,
       @s_srv     = @s_srv,
       @s_lsrv    = @s_lsrv,
       @s_rol     = @s_rol,
       @s_ofi     = @s_ofi,
       @s_org_err = @s_org_err,
       @s_error   = @s_error,
       @s_sev     = @s_sev,
       @s_msg     = @s_msg,
       @s_org     = @s_org,
       @t_rty     = @t_rty,
       @t_trn     = @t_trn,
       @t_debug   = @t_debug,
       @t_file    = @t_file,
       @t_from    = @t_from,
       @i_operacion       = @i_operacion,
       @i_tramite         = @i_tramite,
       @i_tipo            = @i_tipo,
       --@i_truta           = @i_truta,
       @i_oficina_tr      = @i_oficina_tr,
       @i_usuario_tr      = @i_usuario_tr,
       @i_fecha_crea      = @i_fecha_crea,
       @i_oficial         = @i_oficial,
       @i_sector          = @i_sector,
       @i_ciudad          = @i_ciudad,
       @i_estado          = @i_estado,
       @i_numero_op_banco = @i_numero_op_banco,
       @i_cuota           = @i_cuota,
       @i_frec_pago       = @i_frec_pago,
       @i_moneda_solicitada = @i_moneda_solicitada,
       @i_provincia       = @i_provincia,
       @i_monto_solicitado = @i_monto_solicitado,
       @i_monto_desembolso = @i_monto_desembolso,
       @i_pplazo           = @i_pplazo,
       @i_tplazo           = @i_tplazo,
       /* campos para tramites de garantias */
       @i_proposito       = @i_proposito,
       @i_razon           = @i_razon,
       @i_txt_razon       = @i_txt_razon,
       @i_efecto          = @i_efecto,
       /* campos para lineas de credito */
       @i_cliente         = @i_cliente,
       @i_grupo           = @i_grupo,
       @i_fecha_inicio    = @i_fecha_inicio,
       @i_num_dias        = @i_num_dias,
       @i_per_revision    = @i_per_revision,
       @i_condicion_especial = @i_condicion_especial,
       @i_rotativa           = @i_rotativa,
       @i_destino_fondos     = @i_destino_fondos,
       @i_comision_tramite   = @i_comision_tramite,
       @i_subsidio           = @i_subsidio,
       @i_tasa_aplicar       = @i_tasa_aplicar,
       @i_tasa_efectiva      = @i_tasa_efectiva,
       @i_plazo_desembolso   = @i_plazo_desembolso,
       @i_forma_pago         = @i_forma_pago,
       @i_plazo_vigencia     = @i_plazo_vigencia,
       @i_formalizacion      = @i_formalizacion,
       @i_cuenta_corrientelc = @i_cuenta_corrientelc,
       /* operaciones originales y renovaciones */
       @i_linea_credito      = @i_linea_credito,
       @i_toperacion         = @i_toperacion,
       @i_producto           = @i_producto,
       @i_monto              = @i_monto,
       @i_moneda             = @i_moneda,
       @i_periodo            = @i_periodo,
       @i_num_periodos       = @i_num_periodos,
       @i_destino            = @i_destino,
       @i_ciudad_destino     = @i_ciudad, --@i_ciudad_destino,
       -- solo para prestamos de cartera
       @i_reajustable        = @i_reajustable,
       @i_per_reajuste       = @i_per_reajuste,
       @i_reajuste_especial  = @i_reajuste_especial,
       @i_fecha_reajuste     = @i_fecha_reajuste,
       @i_cuota_completa     = @i_cuota_completa,
       @i_tipo_cobro         = @i_tipo_cobro,
       @i_tipo_reduccion     = @i_tipo_reduccion,
       @i_aceptar_anticipos  = @i_aceptar_anticipos,
       @i_precancelacion     = @i_precancelacion,
       @i_tipo_aplicacion    = @i_tipo_aplicacion,
       @i_renovable          = @i_renovable,
       @i_fpago              = @i_fpago,
       @i_cuenta     = @i_cuenta,
       -- generales
       @i_renovacion         = @i_renovacion,
       @i_cliente_cca        = @i_cliente_cca,
       @i_op_renovada        = @i_op_renovada,
       @i_deudor             = @i_deudor,
       -- reestructuracion
       @i_op_reestructurar   = @i_op_reestructurar,
       @i_sector_contable    = @i_sector_contable,
       @i_origen_fondo       = @i_origen_fondo,
       @i_fondos_propios     = @i_fondos_propios,
       @i_plazo              = @i_plazo,
       @i_numero_linea         = null,
       -- Financiamientos
       @i_revolvente           = @i_revolvente,
       @i_trm_tmp              = @i_trm_tmp,
       @i_her_ssn              = @i_her_ssn,
       @i_causa                = @i_causa,
       @i_contabiliza          = @i_contabiliza,
       @i_tvisa                = @i_tvisa,
       @i_migrada              = @i_migrada,
       @i_tipo_linea           = @i_tipo_linea,
       @i_plazo_dias_pago      = @i_plazo_dias_pago,
       @i_tipo_prioridad       = @i_tipo_prioridad,
       @i_linea_credito_pas    = @i_linea_credito_pas,
       --Vivi
       @i_proposito_op         = @i_proposito_op,
       @i_linea_cancelar       = @w_linea_cancelar,
       @i_fecha_irenova        = @i_fecha_irenova,
       @i_subtipo              = @i_subtipo,         --Vivi - CD00013
       @i_tipo_tarjeta         = @i_tipo_tarjeta,       --Vivi - CD00013
       @i_motivo               = @i_motivo,           --Vivi
       @i_plazo_pro            = @i_plazo_pro,        --Vivi
       @i_fecha_valor          = @i_fecha_valor,      --Vivi
       @i_estado_lin           = @i_estado_lin,       --Vivi
       @i_subtplazo            = @w_subtplazo,        --Vivi - CD00013
       @i_subplazos            = @w_subplazos,
       @i_subdplazo            = @w_subdplazo,
       @i_subtbase             = @w_subtbase,
       @i_subporcentaje        = @w_subporcentaje,
       @i_subsigno             = @w_subsigno,
       @i_subvalor             = @w_subvalor,
       @i_tasa_asociada        = @i_tasa_asociada,
       @i_tpreferencial        = @i_tpreferencial,
       @i_porcentaje_preferencial = @i_porcentaje_preferencial,
       @i_monto_preferencial      = @i_monto_preferencial,
       @i_abono_ini               = @i_abono_ini,
       @i_opcion_compra           = @i_opcion_compra,
       @i_beneficiario            = @i_beneficiario,
       @i_financia                = @i_financia,
       @i_ult_tramite             = @i_ult_tramite,     --Vivi, Tramite del que hereda condiciones si tiene linea asociada
       @i_empleado                = @i_empleado,        --Vivi, C+digo del empleado para Tarjeta Corporativa
       @i_ssn                     = @i_ssn,
       @i_nombre_empleado         = @i_nombre_empleado,
       @i_canal                   = @i_canal,
       @i_promotor                = @i_promotor,
       @i_comision_pro            = @i_comision_pro,
       @i_iniciador               = @i_iniciador,
       @i_entrevistador           = @i_entrevistador,
       @i_vendedor                = @i_vendedor,
       @i_cuenta_vende            = @i_cuenta_vende ,
       @i_agencia_venta           = @i_agencia_venta,
       @i_aut_valor_aut           = @i_aut_valor_aut,
       @i_aut_abono_aut           = @i_aut_abono_aut,
       @i_canal_venta             = @i_canal_venta,
       @i_referido                = @i_referido,
       @i_FIniciacion             = @i_FIniciacion,
       --Prestamos Gemelos
       @i_gemelo                  = @i_gemelo,
       @i_tasa_prest_orig         = @i_tasa_prest_orig,
       @i_banco_padre             = @i_banco_padre,
       @i_num_cuenta              = @i_num_cuenta,
       @i_prod_bancario           = @i_prod_bancario,

       --PCOELLO MANEJO DE PROMOCIONES
       @i_monto_promocion      = @i_monto_promocion,
       @i_saldo_promocion      = @i_saldo_promocion,
       @i_tipo_promocion       = @i_tipo_promocion,
       @i_cuota_promocion      = @i_cuota_promocion,
       --SRO INI Factoring VERSION
 @i_destino_descripcion  = @i_destino_descripcion, --DC 04-Feb-2015
       @i_expromision          = @i_expromision,
          @i_objeto              = @i_objeto,
       @i_actividad          = @i_actividad,
       @i_descripcion_oficial = @i_descripcion_oficial,
       @i_tipo_cartera        = @i_tipo_cartera,
       @i_sector_cli          = @i_sector_cli,

       @i_convenio                  = @i_convenio,
       @i_codigo_cliente_empresa    = @i_codigo_cliente_empresa,
       @i_tipo_credito              = @i_tipo_credito,   -- ADCH, 05/10/2015 motivo para tipo de solicitud
       @i_motivo_uno                = @i_motivo_uno,     -- ADCH, 05/10/2015 motivo para tipo de solicitud
       @i_motivo_dos                = @i_motivo_dos,     -- ADCH, 05/10/2015 motivo para tipo de solicitud
       @i_motivo_rechazo            = @i_motivo_rechazo,
       @i_tamanio_empresa           = @i_tamanio_empresa,
       @i_producto_fie              = @i_producto_fie,
       @i_num_viviendas             = @i_num_viviendas,
       @i_reprogramingObserv        = @i_reprogramingObserv,
       @i_sub_actividad             = @i_sub_actividad,
       @i_departamento              = @i_departamento,
       @i_credito_es                = @i_credito_es,
       @i_financiado                = @i_financiado,
       @i_presupuesto               = @i_presupuesto,
       @i_fecha_avaluo              = @i_fecha_avaluo,
       @i_valor_comercial           = @i_valor_comercial,
       --SRO FIN Factoring VERSION
       --INTEGRACION FIE
       @i_actividad_destino         = @i_actividad_destino,  -- SPO Campo Actividad de destino de la operacion
       @i_parroquia                 = @i_parroquia,  -- ITO:13/12/2011 parroquia
       @i_canton                    = @i_canton,
       @i_barrio                    = @i_barrio,
       @i_toperacion_ori = @i_toperacion_ori, --Policia Nacional: Se incrementa por tema de interceptor  VERIFICAR SI SE INCLUYE

--       @o_retorno    = @i_tramite out,
       @o_retorno = @w_tramite_ret out,
       @i_dia_fijo   = @i_dia_fijo,
       @i_enterado   = @i_enterado,
       @i_otros_ent  = @i_otros_ent,
       @i_seguro_basico             = @i_seguro_basico ,
       @i_seguro_voluntario         = @i_seguro_voluntario,
       @i_tipo_seguro               = @i_tipo_seguro,
       @i_tipo_prod                 = @i_tipo_prod, --LPO CDIG APIS II
       @i_dias_anio                 = @i_dias_anio,  --LPO CDIG APIS II
       @i_tipo_amortizacion         = @i_tipo_amortizacion, --LPO CDIG APIS II
       @i_tdividendo                = @i_tdividendo,  --LPO CDIG APIS II
       @i_periodo_cap               = @i_periodo_cap, --LPO CDIG APIS II
       @i_periodo_int               = @i_periodo_int, --LPO CDIG APIS II
       @i_dist_gracia               = @i_dist_gracia, --LPO CDIG APIS II
       @i_gracia_cap                = @i_gracia_cap,
       @i_gracia_int                = @i_gracia_int,
       @i_evitar_feriados           = @i_evitar_feriados,
       @i_renovac                   = @i_renovac,
       @i_mes_gracia                = @i_mes_gracia,
       @i_clase_cartera             = @i_clase_cartera,
       @i_origen_fondos             = @i_origen_fondos,
       @i_base_calculo              = @i_base_calculo,
       @i_causacion                 = @i_causacion,
       @i_convierte_tasa            = @i_convierte_tasa,
       @i_tasa_equivalente          = @i_tasa_equivalente,
       @i_nace_vencida              = @i_nace_vencida
              
       
   if @w_error != 0
   begin
      --rollback tran Optimizacion JSA
      delete cr_deudores_tmp where dt_ssn = @i_ssn
         print 'FBO2: Tramite: ' + convert(varchar(10), @w_tramite_ret)
      goto ERROR
   end

   delete cr_deudores_tmp where dt_ssn = @i_ssn

   --select @o_tramite = @i_tramite
     select @o_tramite = @w_tramite_ret

--COMMIT TRAN -- Optimizacion JSA
end --Fin de i_operacion = 'I'


/* Actualizacion del registro */
/******************************/
if @i_operacion = 'U'
begin
--  eliminacion de formas de pago en el caso de existir cambio de tipo de operacion
--  en un producto de comercio exterior
    select     @w_toperacion=tr_toperacion,
        @w_producto=tr_producto
    from     cr_tramite
    where   tr_tramite = @i_tramite

    if  @i_tramite is NULL or @i_tipo is NULL

    begin
    /* Campos NOT NULL con valores nulos */
       select @w_error = 2101001
       goto ERROR
    end

    if @w_existe = 0
    begin
    /* Registro a actualizar no existe */
       select @w_error = 2105002
       goto ERROR
    end

    if @i_linea_cancelar is not NULL   --recupero numero interno de linea
    begin
       select @w_linea_cancelar=li_numero
         from cr_linea
        where li_num_banco=@i_linea_cancelar
    end
    else
        select @w_linea_cancelar = null

    /**==============================================================================**/
    /**     SI EL CAMPO TASA ASOCIADA A LA PRENDA ES 'S' OBTIENE TASA CALCULADA      **/
    /**     OJOOO, debe ir antes del Begin Tran, x creacion de tablas temporales     **/
    --Vivi
    if ((@i_tipo = 'L' or @i_tipo = 'P') and @w_toperacion != @w_tipo_visa and @i_tasa_asociada = 'S'  )
       or ((@i_tipo = 'O' or @i_tipo = 'R' or @i_tipo = 'E' or @i_tipo = 'F') and @i_tasa_asociada = 'S'  )
    BEGIN

           /* OBTIENE TASA DEL SUBLIMITE DE LA LINEA **/
         /* exec @w_error = sp_tasa_asociada
               @s_user            = @s_user,
               @s_date            = @s_date,
               @t_trn             = 21981,
               @t_file            = @t_file,
               @t_from            = @t_from,
               @i_operacion       = 'C',
               @i_tramite         = @i_tramite,
               @i_devuelve        = 'N',
               @o_tasa            = @w_tasa out

          if @w_error != 0
          begin
             return 1
          end*/

          /**  TASA NO VALIDA  **/
          if @w_tasa is null
          begin
              /* Error en insercion de transaccion de servicio */
              select @w_error = 2101071
              goto ERROR
          end

    END     /** END DE TASA ASOCIADA **/
/**==============================================================================**/


/* llamada al stored procedure de actualizacion */
BEGIN TRAN
/*PARA TIPO DE TRAMITE TIPO LINEA BORRA LOS DEUDORES ACTUALES Y GRABA LOS **/
/*NUEVOS, YA QUE PUEDE CAMBIAR DE GRUPO A PERSONA/CIA.                    **/

/*Se quita la validiaci¾n ya que esto se lo debe hacer para todos los trßmites Version Cobis 4.4*/
if exists( select 1 from cr_deudores_tmp, cobis..cl_ente where dt_ssn = @i_ssn and en_ente = dt_cliente)
begin
   delete cr_deudores where de_tramite = @i_tramite

   insert cr_deudores
   select @i_tramite, dt_cliente, dt_rol, en_ced_ruc, dt_segvida, dt_cobro_cen
   from cr_deudores_tmp, cobis..cl_ente
   where dt_ssn = @i_ssn
     and en_ente = dt_cliente
   if @@error != 0
   begin
      rollback tran
     /* Error en insercion de registro */
      select @w_error = 2103001
      goto ERROR
   end

   delete cr_deudores_tmp where dt_ssn = @i_ssn
end

        select @i_oficial = isnull(@i_oficial,@w_oficial),
               @w_sp_name1 = 'cob_credito..sp_up_tramite_busin',
               @i_monto  = isnull(@i_monto,isnull(@w_monto,0)),
               @i_moneda = isnull(@i_moneda,isnull(@w_moneda,0))

   exec @w_error = @w_sp_name1 -- cob_credito..sp_up_tramite
        /* parametros de tran-server */
        @s_ssn              = @s_ssn,
        @s_user             = @s_user,
        @s_sesn             = @s_sesn,
        @s_term             = @s_term,
        @s_date             = @s_date,
        @s_srv              = @s_srv,
        @s_lsrv             = @s_lsrv,
        @s_rol              = @s_rol,
        @s_ofi              = @s_ofi,
        @s_org_err          = @s_org_err,
        @s_error            = @s_error,
        @s_sev              = @s_sev,
        @s_msg              =  @s_msg,
        @s_org              = @s_org,
        @t_rty              = @t_rty,
        @t_trn              = @t_trn,
        @t_debug            = @t_debug,
        @t_file             = @t_file,
        @t_from             =  @t_from,
        /* parametros de input */
        @i_operacion        = @i_operacion,
        @i_tramite          = @i_tramite,
        @i_tipo             = @i_tipo,
        -- @i_truta         = @i_truta,
        @i_oficina_tr       = @i_oficina_tr,
        @i_usuario_tr       = @i_usuario_tr,
        @i_fecha_crea       = @i_fecha_crea,
        @i_oficial          = @i_oficial,
        @i_sector           = @i_sector,
        @i_ciudad           = @i_ciudad,
        @i_estado           = @i_estado,
        --@i_nivel_ap       = @i_nivel_ap,
        -- @i_fecha_apr     = @i_fecha_apr,
        --@i_usuario_apr    = @i_usuario_apr,
        @i_numero_op_banco  = @i_numero_op_banco,
        @i_cuota            = @i_cuota,
        @i_frec_pago        = @i_frec_pago,
        @i_moneda_solicitada = @i_moneda_solicitada,
        @i_provincia        = @i_provincia,
        @i_monto_solicitado = @i_monto_solicitado,
        @i_monto_desembolso = @i_monto_desembolso,
        @i_pplazo           = @i_pplazo,
        @i_tplazo           = @i_tplazo,
        @i_proposito        = @i_proposito,
        @i_razon            = @i_razon,
        @i_txt_razon        = @i_txt_razon,
        @i_efecto           = @i_efecto,
        @i_cliente          = @i_cliente,
        @i_grupo            = @i_grupo,
        @i_fecha_inicio     = @i_fecha_inicio,
        @i_num_dias         = @i_num_dias,
        @i_per_revision     = @i_per_revision,
        @i_condicion_especial = @i_condicion_especial,
        @i_rotativa         = @i_rotativa,
        @i_linea_credito    = @i_linea_credito,
        @i_toperacion       = @i_toperacion,
        @i_toperacion_ori   = @i_toperacion_ori,
        @i_producto         = @i_producto,
        @i_monto            = @i_monto,
        @i_moneda           = @i_moneda,
        @i_periodo          = @i_periodo,
        @i_num_periodos     = @i_num_periodos,
        @i_destino          = @i_destino,
        @i_ciudad_destino   = @i_ciudad_destino,
        --@i_cuenta_corriente = @i_cuenta_corriente,
        --@i_garantia_limpia = @i_garantia_limpia,
        @i_reajustable      =  @i_reajustable,
        @i_per_reajuste     = @i_per_reajuste,
        @i_reajuste_especial = @i_reajuste_especial,
        @i_fecha_reajuste   = @i_fecha_reajuste,
        @i_cuota_completa   = @i_cuota_completa,
        @i_tipo_cobro       = @i_tipo_cobro,
        @i_tipo_reduccion   = @i_tipo_reduccion,
        @i_aceptar_anticipos = @i_aceptar_anticipos,
        @i_precancelacion   = @i_precancelacion,
        @i_tipo_aplicacion  = @i_tipo_aplicacion,
        @i_renovable        = @i_renovable,
        @i_fpago            = @i_fpago,
        @i_cuenta           = @i_cuenta,
        @i_renovacion       = @i_renovacion,
        @i_cliente_cca      = @i_cliente_cca,
        @i_op_renovada      = @i_op_renovada,
        @i_deudor           = @i_deudor,
        -- reestructuracion
        @i_op_reestructurar = @i_op_reestructurar,
        -- Financiamientos SBU: 20/abr/2000
        @i_destino_fondos   = @i_destino_fondos,
        @i_comision_tramite = @i_comision_tramite,
        @i_subsidio         = @i_subsidio,
        @i_tasa_aplicar     = @i_tasa_aplicar,
        @i_tasa_efectiva    = @i_tasa_efectiva,
        @i_plazo_desembolso = @i_plazo_desembolso,
        @i_forma_pago       = @i_forma_pago,
        @i_plazo_vigencia   = @i_plazo_vigencia,
        @i_origenfondos     = @i_origen_fondos,
        @i_formalizacion    = @i_formalizacion,
        @i_cuenta_corrientelc = @i_cuenta_corrientelc,
        /* valores del registro actual */
        @i_w_tipo           = @w_tipo,
        --@i_w_truta        = @w_truta,
        @i_w_oficina_tr     = @w_oficina_tr,
        @i_w_usuario_tr     = @w_usuario_tr,
        @i_w_fecha_crea     = @w_fecha_crea,
        @i_w_oficial        = @w_oficial,
        @i_w_sector         = @w_sector,
        @i_w_ciudad         = @w_ciudad,
        @i_w_estado         = @w_estado,
        --@i_w_nivel_ap     = @w_nivel_ap,
        --@i_w_fecha_apr    = @w_fecha_apr,
        --@i_w_usuario_apr  = @w_usuario_apr,
        @i_w_numero_op_banco = @w_numero_op_banco,
        @i_w_numero_op      = @w_numero_op,
        @i_w_proposito      = @w_proposito,
        @i_w_razon          = @w_razon,
        @i_w_txt_razon      = @w_txt_razon,
        @i_w_efecto         = @w_efecto,
        @i_w_cliente        = @w_cliente,
        @i_w_grupo          = @w_grupo,
        @i_w_fecha_inicio   = @w_fecha_inicio,
        @i_w_num_dias       = @w_num_dias,
        @i_w_per_revision   = @w_per_revision,
        @i_w_condicion_especial = @w_condicion_especial,
        @i_w_linea_credito  = @w_linea_credito,
        @i_w_toperacion     = @w_toperacion,
        @i_w_producto       = @w_producto,
        @i_w_monto          = @w_monto,
        @i_w_moneda         = @w_moneda,
        @i_w_periodo        = @w_periodo,
        @i_w_num_periodos   = @w_num_periodos,
        @i_w_destino        = @w_destino,
        @i_w_ciudad_destino =  @w_ciudad_destino,
        --@i_w_cuenta_corriente = @w_cuenta_corriente,
        --@i_w_garantia_limpia  = @w_garantia_limpia,
        @i_w_renovacion     = @w_renovacion,
        @i_w_plazo          = @w_pplazo,
        @i_w_tplazo         =  @w_tplazo,
        -- nuevas variable Salvador
        @i_sector_contable  = @i_sector_contable,
        --@i_cupos_terceros = @i_cupos_terceros,
        --@i_tamano_empresa = @i_tamano_empresa,
        --@i_referencia_bmi = @i_referencia_bmi,
        --@i_unidad_medida  = @i_unidad_medida,
        --@i_tipo_empresa   = @i_tipo_empresa,
        --@i_tipo_sector    = @i_tipo_sector,
        --@i_cantidad       = @i_cantidad,
        @i_origen_fondo     = @i_origen_fondo,
        @i_fondos_propios   = @i_fondos_propios,
        --@i_clabas         = @i_clabas,
        --@i_claope         = @i_claope,
        --@i_fecha_contrato = @i_fecha_contrato,
        @i_plazo            = @i_plazo,
        --@i_uso_financiamiento = @i_uso_financiamiento,
        --@i_forma_cont     = @i_forma_cont,
        --@i_dias_desembolso = @i_dias_desembolso,
        --@i_fecha_ins_desembolso = @i_fecha_ins_desembolso,
        --@i_tram_anticipo  = @i_tram_anticipo,
        @i_revolvente       = @i_revolvente,
        -- @i_w_oficial_conta = @w_oficial_conta,
        --@i_oficial_conta  = @i_oficial_conta,
        --@i_w_cem          = @w_cem,  --cem
        --@i_cem            = @i_cem,  --cem
        @i_causa            = @i_causa,            --Personalizacion Banco Atlantic
        @i_contabiliza      = @i_contabiliza,      --Personalizacion Banco Atlantic
        @i_tvisa            = @i_tvisa,            --Personalizacion Banco Atlantic
        @i_migrada          = @i_migrada,          --RZ Personalizacion Banco Atlantic
        @i_tipo_linea       = @i_tipo_linea,
        @i_plazo_dias_pago  =  @i_plazo_dias_pago,
        @i_tipo_prioridad   = @i_tipo_prioridad,
        @i_linea_credito_pas = @i_linea_credito_pas,
        --@i_documento      = @i_documento,
        --@i_fdescuento     = @i_fdescuento,        --Vivi
        @i_cta_descuento    = @i_cta_descuento,       --Vivi
        @i_proposito_op     = @i_proposito_op,
        @i_linea_cancelar   = @w_linea_cancelar,
        @i_fecha_irenova    = @i_fecha_irenova,
        @i_subtipo          = @i_subtipo,             --Vivi - CD00013
        @i_tipo_tarjeta     = @i_tipo_tarjeta,        --Vivi - CD00013
        @i_motivo           = @i_motivo,              --Vivi
        @i_plazo_pro        = @i_plazo_pro,           --Vivi
        @i_fecha_valor      = @i_fecha_valor,         --Vivi
        @i_estado_lin       = @i_estado_lin,          --Vivi
        @i_subtplazo        = @w_subtplazo,           --Vivi - CD00013
        @i_subplazos        = @w_subplazos,
        @i_subdplazo        = @w_subdplazo,
        @i_subtbase         = @w_subtbase,
        @i_subporcentaje    = @w_subporcentaje,
        @i_subsigno         = @w_subsigno,
        @i_subvalor         = @w_subvalor,
        @i_tasa_asociada    = @i_tasa_asociada,
        @i_tasa_prenda      = @w_tasa,        --Vivi
        @i_tpreferencial    = @i_tpreferencial,
        @i_porcentaje_preferencial = @i_porcentaje_preferencial,
        --@i_monto_preferencia = @i_monto_preferencial,
        @i_abono_ini        = @i_abono_ini,
        @i_opcion_compra    = @i_opcion_compra,
        @i_beneficiario     = @i_beneficiario,
        @i_financia         = @i_financia,
        @i_ult_tramite      = @i_ult_tramite,                   --Tramite del que hereda condiciones si tiene linea asociada
        @i_empleado         = @i_empleado,                      --Vivi, C+digo del empleado para Tarjeta Corporativa
        @i_nombre_empleado  = @i_nombre_empleado,
        @i_actsaldo         = @i_actsaldo,
        @i_canal            = null,
        @i_destino_descripcion = @i_destino_descripcion,
        @i_patrimonio       = @i_patrimonio,
        @i_ventas           = @i_ventas,
        @i_num_personal_ocupado =@i_num_personal_ocupado,
        @i_tipo_credito     = @i_tipo_credito,
        @i_indice_tamano_actividad = @i_indice_tamano_actividad,
        @i_objeto           = @i_objeto,
        @i_actividad        = @i_actividad,
        @i_descripcion_oficial = @i_descripcion_oficial,
        @i_tipo_cartera     = @i_tipo_cartera,
        @i_ventas_anuales   = @i_ventas_anuales,                --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales
        @i_activos_productivos = @i_activos_productivos,        --NMA 10-Abr-2015 datos nuevos en tabla cr_tr_datos adicionales
        @i_sector_cli       = @i_sector_cli,
        @i_cuota_maxima     = @i_cuota_maxima,                  --NMA campo nuevo en cr_liquida
        @i_cuota_maxima_linea = @i_cuota_maxima_linea,          --NMA campo nuevo en cr_liquida
        @i_expromision      = @i_expromision,

        @i_level_indebtedness = @i_level_indebtedness,          --DCA
        @i_asigna_fecha_cic = @i_asigna_fecha_cic,
        @i_convenio         = @i_convenio,
        @i_codigo_cliente_empresa = @i_codigo_cliente_empresa,
        @i_reprogramingObserv  = @i_reprogramingObserv,         -- MCA - Ingresa para observación de la reprogramación
        @i_motivo_uno          = @i_motivo_uno,                 -- ADCH, 05/10/2015 motivo para tipo de solicitud
        @i_motivo_dos          = @i_motivo_dos,                 -- ADCH, 05/10/2015 motivo para tipo de solicitud
        @i_motivo_rechazo      = @i_motivo_rechazo,
        @i_valida_estado       = @i_valida_estado,
        @i_numero_testimonio   = @i_numero_testimonio,
        @i_tamanio_empresa     = @i_tamanio_empresa,
        @i_producto_fie        = @i_producto_fie,
        @i_num_viviendas       = @i_num_viviendas,
        @i_tipo_calificacion   = @i_tipo_calificacion,
        @i_calificacion        = @i_calificacion,
        @i_es_garantia_destino = @i_es_garantia_destino,
        @i_tasa                = @i_tasa,
        @i_sub_actividad       = @i_sub_actividad,
        @i_departamento        = @i_departamento,
         --INTEGRACION FIE
        @i_actividad_destino   = @i_actividad_destino,          -- SPO Campo Actividad de destino de la operacion
        @i_parroquia           = @i_parroquia,                  -- ITO:13/12/2011 parroquia
        @i_canton              = @i_canton,
        @i_barrio              = @i_barrio,
        @i_credito_es          = @i_credito_es,
        @i_financiado          = @i_financiado,
        @i_presupuesto         = @i_presupuesto,
        @i_fecha_avaluo        = @i_fecha_avaluo,
        @i_valor_comercial     = @i_valor_comercial,
        @i_dia_fijo            = @i_dia_fijo,
        @i_enterado            = @i_enterado,
        @i_otros_ent           = @i_otros_ent,
        @i_pasa_definitiva     = @i_pasa_definitiva,
        @i_regenera_rubro      = @i_regenera_rubro,
        @i_seguro_basico       = @i_seguro_basico ,
        @i_seguro_voluntario   = @i_seguro_voluntario,
        @i_tipo_seguro         = @i_tipo_seguro
    if @w_error != 0
    begin
        rollback tran
        return 1
    end

    COMMIT TRAN
end

/* Eliminacion de registros */
/****************************/
if @i_operacion = 'D'
begin
    if @w_existe = 0
    begin
       select @w_error = 2101005
       goto ERROR
    end

    exec @w_error = cob_credito..sp_de_tramite
                 -- parametros de tran-server
                 @s_ssn          = @s_ssn,        @s_user         = @s_user,       @s_sesn           = @s_sesn,         @s_term          = @s_term,
                 @s_date         = @s_date,       @s_srv          = @s_srv,        @s_lsrv           = @s_lsrv,         @s_rol           = @s_rol,
                 @s_ofi          = @s_ofi,        @s_org_err      = @s_org_err,    @s_error          = @s_error,        @s_sev           = @s_sev,
                 @s_msg          = @s_msg,        @s_org          = @s_org,        @t_rty            = @t_rty,          @t_trn           = @t_trn,
                 @t_debug        = @t_debug,      @t_file         = @t_file,       @t_from           = @t_from,
                 -- parametros de input
                 @i_operacion    = @i_operacion,  @i_tramite      = @i_tramite,    @i_toperacion     = @i_toperacion,   @i_id_inst_proc  = @i_id_inst_proc,
                 -- registro anterior
                 @i_w_tipo       = @w_tipo,       @i_w_oficina_tr = @w_oficina_tr, @i_w_oficial      = @w_oficial,      @i_w_ciudad_destino     = @w_ciudad_destino,
                 @i_w_usuario_tr = @w_usuario_tr, @i_w_fecha_crea = @w_fecha_crea, @i_w_sector       = @w_sector,       @i_w_ciudad             = @w_ciudad,
                 @i_w_razon      = @w_razon,      @i_w_proposito  = @w_proposito,  @i_w_numero_op    = @w_numero_op,    @i_w_numero_op_banco    = @w_numero_op_banco,
                 @i_w_txt_razon  = @w_txt_razon,  @i_w_efecto     = @w_efecto,     @i_w_cliente      = @w_cliente,      @i_w_fecha_inicio       = @w_fecha_inicio,
                 @i_w_num_dias   = @w_num_dias,   @i_w_grupo      = @w_grupo,      @i_w_per_revision = @w_per_revision, @i_w_condicion_especial = @w_condicion_especial,
                 @i_w_toperacion = @w_toperacion, @i_w_producto   = @w_producto,   @i_w_monto        = @w_monto,        @i_w_linea_credito      = @w_linea_credito,
                 @i_w_moneda     = @w_moneda,     @i_w_periodo    = @w_periodo,    @i_w_destino      = @w_destino,      @i_w_num_periodos       = @w_num_periodos,
                 @i_w_estado     = @w_estado,     @i_w_renovacion = @w_renovacion
    if @w_error != 0
    begin
        goto ERROR
    end
    return 0
end

/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'Q'
begin
  select @w_tipo           = tr_tipo,
         @w_cliente        = tr_cliente,
         @w_grupo          = tr_grupo
  from    cr_tramite
  where    tr_tramite = @i_tramite

  if @@rowcount = 0
  begin
   /*Registro no existe */
     select @w_error = 2101005
     goto ERROR
  end

  if @i_cliente is not null or @i_grupo is not null
  begin
      if @w_tipo in ('O', 'R', 'E', 'F')
        if @i_cliente is not null
        begin
              if not exists (    select     1
                from    cr_deudores
                where    de_tramite = @i_tramite
                and    de_cliente = @i_cliente
                and    de_rol = 'D')
                begin
                   /*Registro no existe */
                   select @w_error = 2101005
                   goto ERROR
                end
        end
        else
        begin
           /*Registro no existe */
           select @w_error = 2101005
           goto ERROR
        end

      if @w_tipo in ('L', 'P', 'G')
        if     (@i_cliente != @w_cliente and @i_grupo != @w_grupo ) or
               (@i_cliente != @w_cliente and @i_grupo is null) or
               (@i_grupo != @w_grupo and @i_cliente is null)
            begin
                           select @w_error = 2101005
                           goto ERROR
            end
   end

          select @w_sp_name1 = 'cob_credito..sp_query_tramite_busin'

   exec @w_error = @w_sp_name1 --sp_query_tramite_busin
        @s_user = @s_user,
        @t_debug           = @t_debug,
        @t_file            = @t_file,
        @t_from            = @t_from,
        @i_tramite         = @i_tramite,
        @i_numero_op_banco = @i_numero_op_banco,
        @i_linea_credito   = @i_linea_credito,
        @i_producto        = @i_producto,
        @i_es_acta         = @i_es_acta,
        @i_formato_fecha   = @i_formato_fecha    --LIM 30/Mar/2006
        if @w_error != 0 goto ERROR


   -- PASAR LAS FORMAS DE PAGO A LA TABLA TEMPORAL, PUES SE LE DA MANTENIMIENTO DESDE CREDITO
  /* if @w_tipo in ('O', 'R', 'E', 'F')
   begin
      select @w_operacionca = op_operacion
        from cob_cartera..ca_operacion
       where op_tramite = @i_tramite

      delete cob_cartera..ca_pago_automatico_tmp
       where pat_operacion = @w_operacionca

      if @@error != 0
      begin
         select @w_error = 710003
         goto ERROR
      end

       select pa_operacion,
       pa_forma_pago,
       pa_cuenta,
       pa_monto,
       pa_rubro,
       pa_institucion,
       pa_cliente,
       pa_rol,
       pa_comentario
       from cob_cartera..ca_pago_automatico
       where  pa_operacion = @w_operacionca

      if @@error != 0
      begin
         select @w_error = 710001
         goto ERROR
      end
   end*/


end


/* Consulta opcion QUERY */
/*************************/
if @i_operacion = 'W'
begin

   -- PASAR LAS FORMAS DE PAGO A LA TABLA TEMPORAL, PUES SE LE DA MANTENIMIENTO DESDE CREDITO
   if @w_tipo in ('O', 'R', 'E', 'F')
   begin

      select @w_operacionca = op_operacion
      from cob_cartera..ca_operacion
      where op_tramite = @i_tramite

      delete cob_cartera..ca_pago_automatico_tmp
      where pat_operacion = @w_operacionca
      if @@error != 0
      begin
         select @w_error = 710003
         goto ERROR
      end

      select pa_operacion,
      pa_forma_pago,
      pa_cuenta,
      pa_monto,
      pa_rubro,
      pa_institucion,
      pa_cliente,
      pa_rol,
      pa_comentario
      from cob_cartera..ca_pago_automatico
      where  pa_operacion = @w_operacionca
      if @@error != 0
      begin
         select @w_error = 710001
         goto ERROR
      end
   end
end

delete cr_cotiz3_tmp where spid = @w_spid
return 0
ERROR:
   --Devolver mensaje de Error
   if @i_canal in (0,1) --Frontend o batch
   begin
      exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
        return @w_error
   end
   else
    begin
    while @@trancount > 0 rollback tran
      exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_error
      return @w_error
    end
GO
