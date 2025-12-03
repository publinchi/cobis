/****************************************************************************/
/*  NOMBRE LOGICO:        qroper.sp                                         */
/*  NOMBRE FISICO:        sp_qr_operacion                                   */
/*  BASE DE DATOS:        cob_cartera                                       */
/*  PRODUCTO:             CARTERA                                           */
/*  DISENADO POR:         Sandra Ortiz                                      */
/*  FECHA DE ESCRITURA:   10/30/1994                                        */
/****************************************************************************/
/*                     IMPORTANTE                                           */
/*   Este programa es parte de los paquetes bancarios que son               */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,          */
/*   representantes exclusivos para comercializar los productos y           */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida         */
/*   y regida por las Leyes de la República de España y las                 */
/*   correspondientes de la Unión Europea. Su copia, reproducción,          */
/*   alteración en cualquier sentido, ingeniería reversa,                   */
/*   almacenamiento o cualquier uso no autorizado por cualquiera            */
/*   de los usuarios o personas que hayan accedido al presente              */
/*   sitio, queda expresamente prohibido; sin el debido                     */
/*   consentimiento por escrito, de parte de los representantes de          */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto          */
/*   en el presente texto, causará violaciones relacionadas con la          */
/*   propiedad intelectual y la confidencialidad de la información          */
/*   tratada; y por lo tanto, derivará en acciones legales civiles          */
/*   y penales en contra del infractor según corresponda.                   */
/****************************************************************************/
/*                           PROPOSITO                                      */
/*   Este programa ejecuta el query de operaciones de cartera               */
/*   llamado por el SP sp_operacion_qry.                                    */
/****************************************************************************/
/*                         MODIFICACIONES                                   */
/*  FECHA              AUTOR             RAZON                              */
/* Enero 17 de 2003   Jennifer Velandia  nuevos conceptos                   */
/*                                       no se pueden enviar mas datos      */
/*                                       por el tamato fue necesario        */
/*                                       reutilizar algunos                 */
/* Enero 14 2004      Elcira Pelaez      Cambios para el BAC                */
/* MAYO-2006          Elcira Pelaez      Def. Cart.Sobregiros Dias Ven      */
/* Julio-2006         Elcira Pelaez      Def. No.desembolso Rotativo        */
/* Julio-2007         Elcira Pelaez      NR-293 quita variable              */
/* Junio-2010         Elcira Pelaez      DES. ORIGEN FONDOS                 */
/* Junio-2010         Ivonne Torres      CAR001                             */
/* 04/10/2010         Yecid Martinez     Fecha valor baja Intensidad        */
/*                                       NYMR 7x24                          */
/* 04/Nov/2010        Elcira Pelaez B.   Nr-059 Datos Diferidos             */
/*                                       Depende del NR 7x27                */
/* 13/Dic/2011        Luis Carlos Moreno Pago por reconocimiento RQ 293     */
/*   Oct 2012         Jcortes            Req 0331                           */
/*   Feb 2014         Igmar Berganza     Req 397 Reportes FGA               */
/* 07/Nov/2014        Luis Carlos Moreno CCA 436 Nomalizacion de Cartera    */
/* 09/Jun/2014        Carlos Avendaño    Req 518 - Validacion Referidos     */
/* 04/Jul/2017        M. Taco            Cargar la cuenta del cliente       */
/*                                       para flujos individuales           */
/* 29/Abr/2019        L.Gerardo Barron   Cambios en la obtencion de datos   */
/*                                       para Creacion de operaciones       */
/* 29/Abr/2019        Edison Cajas       CAR-B230777-TEC - No aplica para   */
/*                                       TeCreemos                          */
/* 17/Jun/2019        Jonathan Tomala    CONSULTA DE DATOS PARA OPERACIONES */
/*                                       GRUPALES, HIJAS, INTERCICLAS       */
/* 24/Jun/2019        Jonathan Tomala    Operacion G Actualiza Grupales     */
/*                                       Operacion H Actualiza Hijas        */
/* 25/Jun/2019        Jonathan Tomala    Info-Grupales - monto min esperado */
/* 18/Nov/2020        P.Narvaez          Habilitar sp_validar_fecha para    */
/*                                       7x24                               */
/* 14/Ene/2021        Luis Ponce         Operaciones Pasivas                */
/* 18/May/2021        Lucas Blandòn      Calculo de Tir TEa                 */
/* 22/May/2021        Alfredo Monroy     Calculo de Tir TEa                 */
/* 26/May/2021        Aldair Fortiche    Se deshabilita sp_validar_fecha    */
/*                                       7x24 para que no ejecute proceso   */
/*                                       automatico en la consulta          */
/* 25/Ago/2021        G. Fernandez       Incremento de campo en query para  */
/*                                       valor de scoring                   */
/* 17/Sep/2021        G. Fernandez       Obtencion de nuevos campos para la */
/*                                       gestion de cobranza                */
/* 06/Ene/2022        G. Fernandez       Nuevo campo de grupo contable      */
/* 07/Abr/2022        K. Rdriguez        Fecha de castigo préstamos         */
/* 19/Abr/2022        K. Rodríguez       Cambio catálogo destino finan. op  */
/* 26/Abr/2022        J. Guzman          Consulta de tipo dividendo y su    */
/*                                       descripción                        */
/* 09/May/2022        B. Dueñas          Se agrega valor a la fecha castigo */
/* 13/Jun/2022        G. Fernandez       Campo de para valores descontados  */
/*                                       reemplaza el valor de capitalizado */
/* 28/Jul/2022        J. Guzman          se cambia lógica de fecha castigo  */
/*                                       cuando el préstamo es estado 4(CAS)*/
/* 31/Oct/2022        G. Fernandez       R196423 Se inicializa fecha castigo*/
/*                                       a null                             */
/* 12/Ene/2023        G. Fernandez       R200366 se independiza las fechas  */
/*                                       de vencimiento y castigo en los    */
/*                                       query de resultados                */
/* 06/Abr/2023        G. Fernandez       Ingreso de campo categoria plazo   */
/* 06/Jun/2023	      M. Cordova		 Cambio variable @w_calificacion    */
/*									     de char(1) a catalogo				*/
/* 07/Jun/23          K. Rodríguez       S809862 Tipo Documento. tributario */
/****************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_qr_operacion')
   drop proc sp_qr_operacion
go

create proc sp_qr_operacion (
@s_user                  varchar(14),
@s_term                  varchar(30),
@s_date                  datetime,
@s_ofi                   smallint,
@t_trn                  INT       = NULL, --LPO CDIG Cambio de Servicios a Blis                  
@i_banco                cuenta  = null,
@i_formato_fecha        int     = null,
@i_operacion            char(1) = null
)
as
declare
   @w_sp_name                      varchar(32),
   @w_return                       int,
   @w_operacionca                  int,
   @w_banco                        cuenta,
   @w_cliente                      int,
   @w_toperacion                   catalogo,
   @w_oficina                      smallint,
   @w_moneda                       tinyint,
   @w_oficial                      smallint,
   @w_fecha_ini                    datetime,
   @w_fecha_fin                    datetime,
   @w_monto                        money,
   @w_tplazo                       catalogo,
   @w_plazo                        smallint,
   @w_destino                      catalogo,
   @w_producto                     tinyint,
   @w_lin_credito                  cuenta,
   @w_reajuste                     char(1),
   @w_reajuste_periodo             smallint,
   @w_reajuste_especial            char (1),
   @w_reajuste_fecha               datetime,
   @w_reajuste_num                 tinyint,
   @w_ciudad                       int,
   @w_estado                       descripcion,
   @w_renovaciones                 tinyint,
   @w_porcentaje                   float,
   @w_valor                        int,
   @w_nem_producto                 catalogo,
   @w_cuenta                       cuenta,
   @w_cuota_completa               char(1),
   @w_anticipado_int               char(1),
   @w_reajuste_intereses           char(1),
   @w_reduccion                    char(1),
   @w_cuota_anticipada             char(1),
   @w_dias_anio                    smallint,
   @w_tipo_amortizacion            varchar(10),
   @w_cuota_fija                   char(1),
   @w_cuota                        money,
   @w_cuota_capital                money,
   @w_periodos_gracia              tinyint,
   @w_periodos_gracia_int          tinyint,
   @w_dist_gracia                  char(1),
   @w_tdividendo                   catalogo,
   @w_periodo_cap                  smallint,
   @w_periodo_int                  smallint,
   @w_dias_gracia                  tinyint,
   @w_dia_pago                     tinyint,
   @w_renovacion                   char(1),
   @w_num_renovacion               tinyint,
   @w_precancelacion               char(1),
   @w_tipo                         char(1),
   @w_base_calculo                 char(1),
   @w_porcentaje_fin               float,
   @w_tasa_fin                     float,
   @w_tramite                      int,
   @w_tramite_max                  int,
   @w_fecha_prox_pag               datetime,
   @w_direccion                    tinyint,
   --- DESCRIPCIONES
   @w_desc_toperacion              descripcion,
   @w_desc_reajuste                descripcion,
   @w_desc_tvencimiento            descripcion,
   @w_desc_tdividendo              descripcion,
   @w_desc_t_empresa               descripcion,
   @w_desc_tmnio_empresa           descripcion,
   @w_desc_tplazo                  descripcion,
   @w_desc_moneda                  descripcion,
   @w_desc_ciudad                  descripcion,
   @w_desc_destino                 descripcion,
   @w_desc_producto                descripcion,
   @w_desc_ofi                     descripcion,
   @w_inicio                       varchar(10),
   @w_fin                          varchar(10),
   @w_nombre                       descripcion,
   @w_tasa                         float,
   @w_valint                       float,
   @w_referencial                  catalogo,
   @w_desc_referencial             descripcion,
   @w_nom_oficial                  descripcion,
   @w_sector                       catalogo,
   @w_banca                        catalogo,  --xma

   @w_des_sector                   descripcion,
   @w_anterior                     cuenta,
   @w_migrada                      cuenta,
   @w_desembolso                   int,
   @w_refer                        varchar(255),
   @w_fecha_liq                    datetime,
   @w_cuota_adic                   char(1),
   @w_monto_aprobado               money,
   @w_tipo_aplicacion              char(1),
   @w_mes_gracia                   tinyint,
   @w_gracia_int                   tinyint,
   @w_num_dec                      tinyint,
   @w_fecha_fija                   char(1),
   @w_meses_hip                    tinyint,
   @w_evitar_feriados              char(1),
   @w_fecha_ult_proceso            datetime,
   @w_saldo_operacion              money,
   @w_dias_clausula                int,
   @w_clausula_aplicada            char(1),
   @w_periodo_crecimiento          smallint,
   @w_tasa_crecimiento             float,
   @w_desc_direccion               varchar(254),
   @w_desc_tipo                    descripcion,
   @w_clase_cartera                catalogo,
   @w_desc_clase_cartera           descripcion,
   @w_origen_fondos                catalogo,
   @w_fondos_propios               char(1),
   @w_tabla                        descripcion,
   @w_desc_origen_fondos           descripcion,
   @w_calificacion                 catalogo,
   @w_fecha_ini_venc               datetime,
   @w_desc_calificacion            descripcion,
   @w_numero_reest                 int ,
   @w_saldo_operacion_finan        money,
   @w_fecha_ult_rees               datetime,
   @w_dias_venc                    int,
   @w_prd_cobis                    tinyint,
   @w_ref_exterior                 catalogo,
   @w_sujeta_nego                  char(1),
   @w_ref_red                      varchar(24),
   @w_sal_pro_pon                  money,
   @w_tipo_empresa                 catalogo,
   @w_validacion                   catalogo,
   @w_fecha_pri_cuota              datetime,
   @w_tr_subtipo                   char(1),
   @w_des_subtipo                  varchar(20),
   @w_recalcular                   char(1),
   @w_dia_habil                    char(1),
   @w_usa_tasa_eq                  char(1),
   @w_grupo_fact                   int,
   @w_reajustable                  char(1),
   @w_bvirtual                     char(1),
   @w_extracto                     char(1),
   @w_reestructuracion             char(1),
   @w_subtipo                      char(1),
   @w_fecha_embarque               datetime,
   @w_fecha_dex                    datetime,
   @w_num_deuda_ext                cuenta,
   @w_num_comex                    cuenta,
   @w_nace_vencida                 char(1),
   @w_calcula_devolucion           char(1),
   @w_edad                         int,
   @w_estado_cobranza              descripcion,
   @w_cobranza                     catalogo,
   @w_tipo_linea                   catalogo,
   @w_div_vencido                  int,
   @w_dias_cap_ven                 int,
   @w_op_pasiva_externa            varchar(64),
   @w_op_margen_redescuento        float,
   @w_naturaleza                   char(1),                  --jvc
   @w_des_naturaleza               descripcion,
   @w_categoria_linea              descripcion,
   @w_des_entidad_presta           descripcion,
   @w_programa                     catalogo,
   @w_des_programa                 descripcion,
   @w_desc_entidad                 descripcion,
   @w_opcion_cap                   char(1),
   @w_mercado_objetivo             catalogo,
   @w_mercado                      catalogo,
   @w_des_mercado_objetivo         descripcion,
   @w_des_mercado                  descripcion,
   @w_tipo_productor               catalogo,
   @w_des_tipo_productor           descripcion,
   @w_des_edad                     descripcion,
   @w_ct_desde                     catalogo,
   @w_ct_hasta                     catalogo ,
   @w_fecha_mora_desde             datetime,
   @w_cod_actividad                catalogo,
   @w_des_actprod                  descripcion,
   @w_num_desemb                   int,
   @w_situacion                    catalogo,
   @w_causal                       catalogo,
   @w_desc_situacion               descripcion,
   @w_desc_causal                  descripcion,
   @w_total_desc_situacion         descripcion,
   @w_total_desc_causal            descripcion,
   @w_op_divcap_original           smallint,
   @w_vx_monto                     money,        -- IFJ 30/Ene/2006 REQ 316
   @w_vx_monto_max                 money,        -- IFJ 30/Ene/2006 REQ 316
   @w_vx_valor_vencido             money,         -- IFJ 30/Ene/2006 REQ 316
   @w_fecha_ini_sobr               datetime,         --IFJ 609
   @w_error                        int,
   @w_total_honabo                 money,
   @w_regimen                      char(1),
   @w_porc_juridico                float,
   @w_divisor                      float,
   @w_monto_base                   money,
   @w_monto_honabo                 money,
   @w_monto_iva                    money,
   @w_porc_prejuridico             float,
   @w_iva                          float,
   @w_saldo_cap                    money,
   @w_fecha_migracion              datetime,
   @w_abogado                      int,             -- ITO 10/06/2010 CAR001
   @w_nom_abogado                  varchar(255),    -- ITO 10/06/2010 CAR001
   @w_total_diferido               money,
   @w_pendiente_diferido           money,
   @w_op_padre                     cuenta,
   @w_op_hija                      cuenta,
   @w_capitalizado                 money,           -- REQ 175: PEQUEÃ‘A EMPRESA
   @w_fecha_castigo                datetime,
   @w_est_castigado                tinyint,
   @w_op_estado                    tinyint,
   @w_calif_orig                   catalogo,        -- PAQUETE 2: REQ 260 - MIR VINCULANTE CALIF - 01/JUL/2011
   @w_desc_calif_orig              descripcion,     -- PAQUETE 2: REQ 260 - MIR VINCULANTE CALIF - 01/JUL/2011
   @w_calif_segui                  catalogo,        -- PAQUETE 2: REQ 260 - MIR VINCULANTE CALIF - 01/JUL/2011
   @w_desc_calif_segui             descripcion,     -- PAQUETE 2: REQ 260 - MIR VINCULANTE CALIF - 01/JUL/2011
   @w_apl_cartera                  tinyint,         -- PAQUETE 2: REQ 260 - MIR VINCULANTE CALIF - 01/JUL/2011
   @w_fecha_ult_calif              datetime,        -- PAQUETE 2: REQ 260 - MIR VINCULANTE CALIF - 01/JUL/2011
   @w_tipo_calif_seg               catalogo,         -- PAQUETE 2: REQ 260 - MIR VINCULANTE CALIF - 01/JUL/2011
   @w_telefonos                    varchar(50),
   @w_telefono1_ab                 varchar(15),
   @w_telefono2_ab                 varchar(15),
   @w_ab_cliente                   int,
   @w_direccion1                   varchar(50),
   @w_vlr_rec_ini                  money,           -- REQ 293 - LCM - PAGOS POR RECONOCIMIENTO
   @w_vlr_x_amort                  money,           -- REQ 293 - LCM - PAGOS POR RECONOCIMIENTO
   @w_tiene_reco                   char(1),         -- REQ 293 - LCM - PAGOS POR RECONOCIMIENTO
   @w_sec_rpa_rec                  int,             -- REQ 293 - LCM - PAGOS POR RECONOCIMIENTO
   @w_sec_rpa_pag                  int,             -- REQ 293 - LCM - PAGOS POR RECONOCIMIENTO
   @w_recono                       money,           -- REQ 293 - LCM - PAGOS POR RECONOCIMIENTO
   @w_vx_monto_rec                 money,           -- REQ 293 - LCM - PAGOS POR RECONOCIMIENTO
   @w_vx_valor_vencido_rec         money,           -- REQ 293 - LCM - PAGOS POR RECONOCIMIENTO
   @w_des_alianza                  varchar(255),    -- REQ 353
   @w_campana                      int,             -- Req 0331
   @w_camp_det                     varchar(64),
   @w_parametro_cta_pte            catalogo,        -- REQ 436
   @w_llave_finagro                varchar(30),     -- REQ 479 - AAMG - LLAVE FINAGRO
   @w_finagro                      char(1),         -- REQ 479 - 2 - AAMG -- INDICADOR SI OPERACION ES FINAGRO
   @w_gar_finagro                  varchar(30),      -- REQ 479 - ERO - GARANTIA FINAGRO
   @w_marca_reest                  char(1),
   @w_dias_venc_completo           varchar(500),
   @w_ant_per_calculo              INT,
   @w_cat1                         float,
   @w_op_pproductor                varchar(64),  --GFP 23-08-2021
   @w_tir                          float,
   @w_tea                          float,
   @w_estado_gestion_cobranza      varchar(30),
   @w_aceptar_pagos                char(1),
   @w_grupo_contable               catalogo,      --GFP 06/Ene/2022
   @w_sec_camb_est_cast            int,           --KDR Secuencial de transacción de cambio de estado manual a Castigada
   @w_descontados                  money,
   @w_categoria_plazo              varchar(64),
   @w_tipo_doc_tributario          varchar(64)

SELECT @w_ant_per_calculo = 0

/*  Captura nombre de Stored Procedure  */
select
@w_sp_name        = 'sp_qr_operacion',
@w_tipo_calif_seg = 'SEGU',
@w_apl_cartera    = 7,
@w_marca_reest    = 'N'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_castigado  = @w_est_castigado out

-- INI JAR REQ 246
if @i_operacion = 'D'  -- Valores Diferidos
begin
   select 'RUBRO  '            = dif_concepto,
          'TOTAL DIFERIDO'     = isnull(dif_valor_total,0),
          'PENDIENTE DIFERIDO' = isnull(dif_valor_total,0) - isnull(dif_valor_pagado,0)
     from ca_diferidos, ca_operacion
    where op_banco     = @i_banco
      and op_operacion = dif_operacion

   return 0
end
-- FIN JAR REQ 246


/*Operaciones Pasivas*/
IF @i_operacion = 'P'
BEGIN
   SELECT dap_tipo_acreedor,    
          dap_linea,      
          dap_numreg_bc,        
          dap_num_cont,
          dap_tipo_deuda,    
          dap_fecha_aut,        
          dap_num_aut,    
          dap_num_facilidad,    
          dap_forma_reposicion,
          dap_causa_fin_sub, 
          dap_mercado_obj_fin,
          op_plazo,
          op_tplazo
   FROM ca_datos_adicionales_pasivas, ca_operacion
   WHERE dap_operacion = op_operacion
     AND op_banco      = @i_banco
     
   RETURN 0     
END



-- REQ 479 AAM LLAVE FINAGRO

select @w_llave_finagro = vo_oper_finagro,
       @w_gar_finagro   = vo_num_gar
from   cob_cartera..ca_val_oper_finagro
where  vo_operacion = @i_banco
and    vo_estado    = 'P'
order by vo_fecha desc

-- REQ 479 AAM VALIDA FINAGRO
select @w_finagro = 'S'
from   cob_cartera..ca_opera_finagro
where  of_pagare = @i_banco

select @w_finagro = isnull(@w_finagro, 'N')

/*  Captura nombre de Stored Procedure  */
select   @w_sp_name = 'sp_qr_operacion'

select @w_producto = pd_producto
from cobis..cl_producto
where pd_abreviatura = 'CCA'
set transaction isolation level read uncommitted

/*
--7x24
EXEC @w_return = sp_validar_fecha
   @s_user  = @s_user,
   @s_term  = @s_term,
   @s_date  = @s_date,
   @s_ofi   = @s_ofi,
   @i_banco = @i_banco

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end
*/


/* INICIALIZA VARIABLES DE RECONOCIMIENTO */
select @w_vx_monto_rec = 0,
       @w_vx_valor_vencido_rec = 0

select
   @w_operacionca         = op_operacion,
   @w_banco               = op_banco,
   @w_fecha_ini           = op_fecha_ini,
   @w_fecha_fin           = op_fecha_fin,
   @w_toperacion          = op_toperacion,
   @w_desc_toperacion     = op_toperacion,
   @w_monto               = op_monto,
   @w_tplazo              = op_tplazo,
   @w_plazo               = op_plazo,
   @w_destino             = op_destino,
   @w_desc_destino        = ( select valor
                              from cobis..cl_catalogo y, cobis..cl_tabla t
                              where t.tabla = 'cr_objeto'
                              and   y.tabla   = t.codigo
                              and   y.codigo  = x.op_destino),
   @w_oficina             = op_oficina,
   @w_moneda              = op_moneda,
   @w_oficial             = op_oficial,
   @w_lin_credito         = op_lin_credito,
   @w_nem_producto        = op_forma_pago,
   @w_cuenta              = op_cuenta,
   @w_reajustable         = op_reajustable,
   @w_reajuste_fecha      = op_fecha_reajuste,
   @w_reajuste_periodo    = op_periodo_reajuste,
   @w_reajuste_especial   = op_reajuste_especial,
   @w_cliente             = op_cliente,
   @w_ciudad              = op_ciudad,
   @w_cuota_completa      = op_cuota_completa,
   @w_anticipado_int      = op_tipo_cobro,
   @w_reajuste_intereses  = op_reajuste_especial,
   @w_reduccion           = op_tipo_reduccion,
   @w_cuota_anticipada    = op_aceptar_anticipos,
   @w_dias_anio           = op_dias_anio,
   @w_tipo_amortizacion   = op_tipo_amortizacion,
   @w_cuota               = op_cuota,
   @w_cuota_capital       = 0,
   @w_periodos_gracia     = op_gracia_cap,
   @w_periodos_gracia_int = op_gracia_int,
   @w_dist_gracia         = op_dist_gracia,
   @w_tdividendo          = op_tdividendo,
   @w_periodo_cap         = op_periodo_cap,
   @w_periodo_int         = op_periodo_int,
   @w_dias_gracia         = 0,
   @w_fecha_pri_cuota     = op_fecha_pri_cuot,
   @w_dia_pago            = op_dia_fijo,
   @w_renovacion          = op_renovacion ,
   @w_num_renovacion      = op_num_renovacion,
   @w_precancelacion      = op_precancelacion,
   @w_tipo                = op_tipo,
   @w_desc_tipo           = (select valor
                             from cobis..cl_catalogo
                             where tabla = (select codigo
                                            from  cobis..cl_tabla
                                            where tabla  = 'ca_tipo_prestamo')
                                            and   codigo = x.op_tipo),

   @w_tramite             = op_tramite,
   @w_fecha_prox_pag      = null,
   @w_desc_ofi            = (select of_nombre
                             from cobis..cl_oficina
                             where of_oficina = x.op_oficina),
   @w_sector              = op_sector,
   @w_banca               = op_banca,
   @w_anterior            = op_anterior,
   @w_migrada             = op_migrada,
   @w_refer               = op_comentario,
   @w_desembolso          = 0,
   @w_fecha_liq           = op_fecha_liq,
   @w_nombre              = op_nombre,
   @w_monto_aprobado      = op_monto_aprobado,
   @w_tipo_aplicacion     = op_tipo_aplicacion,
   @w_gracia_int          = op_gracia_int,
   @w_mes_gracia          = op_mes_gracia,
   @w_evitar_feriados     = op_evitar_feriados,
   @w_fecha_ult_proceso   = op_fecha_ult_proceso,
   @w_dias_clausula       = op_dias_clausula,
   @w_clausula_aplicada   = op_clausula_aplicada,
   @w_periodo_crecimiento = op_periodo_crecimiento,
   @w_tasa_crecimiento    = op_tasa_crecimiento,
   @w_direccion           = op_direccion,
   @w_clase_cartera       = op_clase,
   @w_origen_fondos       = op_origen_fondos,
   @w_calificacion        = isnull(op_calificacion,'A'),
   @w_fondos_propios      = op_fondos_propios,
   @w_numero_reest        = op_numero_reest,
   @w_prd_cobis           = op_prd_cobis,
   @w_ref_exterior        = op_ref_exterior,
   @w_sujeta_nego         = op_sujeta_nego,
   @w_ref_red             = op_nro_red,
   @w_sal_pro_pon         = op_sal_pro_pon,
   @w_tipo_empresa        = op_tipo_empresa,
   @w_dia_habil           = isnull(op_dia_habil,'N'),
   @w_recalcular          = isnull(op_recalcular_plazo,'N'),
   @w_usa_tasa_eq         = isnull(op_usar_tequivalente,'N'),
   @w_base_calculo        = op_base_calculo,
   @w_validacion          = op_validacion,
   @w_grupo_fact          = op_grupo_fact,
   @w_bvirtual            = op_bvirtual,
   @w_extracto            = op_extracto,
   @w_reestructuracion    = op_reestructuracion,
   @w_subtipo             = op_tipo_cambio,
   @w_fecha_embarque      = op_fecha_embarque,
   @w_fecha_dex           = op_fecha_dex,
   @w_num_deuda_ext       = op_num_deuda_ext,
   @w_nace_vencida        = op_nace_vencida,
   @w_num_comex           = op_num_comex,
   @w_calcula_devolucion  = op_calcula_devolucion,
   @w_edad                = op_edad,
   @w_cobranza            = op_estado_cobranza,
   @w_tipo_linea          = op_tipo_linea,
   @w_op_pasiva_externa   = op_codigo_externo,
   @w_op_margen_redescuento = isnull(op_margen_redescuento,0),
   @w_naturaleza          = op_naturaleza,          --jvc
   @w_desc_entidad        = (select valor
                             from cobis..cl_catalogo
                             where tabla = (select codigo
                                            from  cobis..cl_tabla
                                            where tabla  = 'ca_tipo_linea')
                             and   codigo = x.op_tipo_linea),
   @w_programa      = op_subtipo_linea,
   @w_opcion_cap          = op_opcion_cap,
   @w_op_divcap_original  = isnull(op_divcap_original, 0),
   @w_op_estado           = op_estado,
   @w_op_pproductor       = convert(varchar(24), op_dias_clausula),      -- GFP 23-08-2021
   @w_tir				  = op_valor_cat,  		-- AMP 20210522
   @w_tea				  = op_tasa_cap         -- GFP cambio de campo op_tasa_crecimiento 
from ca_operacion x
where x.op_banco  = @i_banco

if @@rowcount = 0
begin
   select @w_error = 710238
   goto ERROR
end


-- INI 24/06/2019 JTO IMPLEMENTACION DE OPERACION G ACTUALIZA GRUPALES
if @i_operacion = 'G'  -- ACTUALIZA GRUPALES
begin
/* LRE S276526 Se comenta pues en TEC se usa administracion grupal

   exec @w_error = cob_cartera..sp_actualiza_grupal
        @i_banco     = @w_banco,
        @i_tramite   = @w_tramite,
        @i_desde_cca = 'N'

   if @w_error <> 0 goto ERROR */

   return 0
end
-- FIN 24/06/2019 JTO IMPLEMENTACION DE OPERACION G ACTUALIZA GRUPALES


-- INI 24/06/2019 JTO IMPLEMENTACION DE OPERACION G ACTUALIZA HIJAS
if @i_operacion = 'H'  -- ACTUALIZA HIJAS
begin
   exec @w_error = cob_cartera..sp_actualiza_hijas
        @i_banco = @w_banco

   if @w_error <> 0 goto ERROR
   return 0
end
-- FIN 24/06/2019 JTO IMPLEMENTACION DE OPERACION G ACTUALIZA HIJAS


IF @w_naturaleza = 'A'
BEGIN
   select @w_desc_toperacion     = ltrim(rtrim(@w_desc_toperacion)) + ' - ' + cx.valor
   from cobis..cl_catalogo cx,  cobis..cl_tabla tx
   where   tx.tabla    = 'ca_toperacion'
   and     cx.tabla    = tx.codigo
   and     cx.codigo   = @w_toperacion
END

IF @w_naturaleza = 'P' --LPO Operaciones Pasivas
BEGIN
   select @w_desc_toperacion     = ltrim(rtrim(@w_desc_toperacion)) + ' - ' + cx.valor
   from cobis..cl_catalogo cx,  cobis..cl_tabla tx
   where   tx.tabla    = 'ca_toperacion_pas'
   and     cx.tabla    = tx.codigo
   and     cx.codigo   = @w_toperacion
END

if @@rowcount = 0 select @w_desc_toperacion = 'SIN DESCRIPCION'

select @w_desc_moneda         = mo_descripcion
from cobis..cl_moneda
where   mo_moneda   = @w_moneda

if @@rowcount = 0 select @w_desc_moneda = 'SIN DESCRIPCION'

select
@w_desc_ciudad         = ci_descripcion
from cobis..cl_ciudad
where ci_ciudad = @w_ciudad

if @@rowcount = 0 select @w_desc_ciudad = 'SIN DESCRIPCION'


select @w_estado = substring(es_descripcion,1,30)
from ca_estado
where es_codigo = @w_op_estado

if @@rowcount = 0 select @w_estado = 'SIN DESCRIPCION'



select @w_tramite_max = max(tr_tramite)   -- Selecciona el tramite mas actual para la operacion, se usa en Reestructuracion
from cob_credito..cr_tramite
where tr_tipo = 'E'
and tr_estado = 'A'
and tr_numero_op_banco = @i_banco

if @w_tramite_max is null
   select @w_tramite_max = @w_tramite


-- INI JAR REQ 218 - ALERTAS CUPOS
if @i_operacion = 'C'
begin
   exec @w_error = cob_credito..sp_alertas
      @i_cliente = @w_cliente

   if @w_error <> 0 goto ERROR
   return 0
end
-- FIN JAR REQ 218

-- INI - REQ 175: PEQUEÃ‘A EMPRESA - CONSULTA DEL VALOR CAPITALIZADO POR GRACIA
if @w_gracia_int > 0 and @w_dist_gracia = 'C'
begin
   select @w_capitalizado = ro_base_calculo
   from ca_rubro_op
   where ro_operacion = @w_operacionca
   and   ro_concepto  = 'CAP'

   select @w_capitalizado = isnull(@w_capitalizado, 0)
end
else
   select @w_capitalizado = 0
-- FIN - REQ 175: PEQUEÃ‘A EMPRESA - CONSULTA DEL VALOR CAPITALIZADO POR GRACIA

select @w_total_diferido     = 0,
       @w_pendiente_diferido = 0

if @w_naturaleza = 'A'
begin
   select @w_pendiente_diferido =  isnull(sum(dif_valor_total - dif_valor_pagado),0),
          @w_total_diferido     =  isnull(sum(dif_valor_total),0)
    from  ca_diferidos
    where dif_operacion = @w_operacionca
end
--PRINT '--INICIO NYMR 7x24 Ejecuto FECHA VALOR BAJA INTENSIDAD ' + CAST(@w_operacionca as varchar)



--PRINT '--FIN NYMR 7x24 Ejecuto FECHA VALOR BAJA INTENSIDAD ' + CAST(@w_operacionca as varchar)
--REQ 518 --Se lee nuevamente la fecha de ult proceso para validar luego de actualizar la fecha
select
@w_fecha_ult_proceso   = op_fecha_ult_proceso
from ca_operacion with (nolock)
where op_banco  = @i_banco


-- ITO 10/06/2010 CAR001
select @w_abogado     = co_abogado,
       @w_nom_abogado = (select ab_nombre
      from cob_credito..cr_abogado
                         where a.co_abogado = ab_abogado),
       @w_ab_cliente   = (select ab_cliente
                         from cob_credito..cr_abogado
                         where a.co_abogado = ab_abogado
                        )
from cob_credito..cr_operacion_cobranza,
     cob_credito..cr_cobranza a
where oc_num_operacion = @i_banco   -- '1712MP-11223-1'
and oc_cobranza = co_cobranza
-- FIN CAR001

select  te_direccion,te_tipo_telefono,te_telefono = case when te_prefijo <> '' then ltrim(rtrim(te_prefijo)) + isnull(te_valor,0) else te_valor end,di_descripcion
into #telefonos
from cobis..cl_direccion, cobis..cl_telefono
where di_ente      = te_ente
and   di_direccion = te_direccion
and   di_ente     = @w_ab_cliente
order by te_tipo_telefono

select @w_telefono1_ab = ''
set rowcount 1
select @w_telefono1_ab = te_telefono,
       @w_direccion1 = di_descripcion
  from #telefonos
where te_direccion = 1
order by te_tipo_telefono
set rowcount 0

select @w_telefono2_ab = ''
select @w_telefono2_ab = te_telefono  from #telefonos
where te_direccion = 2

if @w_direccion1 = '' or @w_direccion1 is null
   select @w_direccion1 = 'NO HAY DIRECCIONES REGISTRADAS'

if @w_telefono1_ab = ''
begin
   select @w_telefonos = 'NO HAY TELEFONOS REGISTRADOS'
end
ELSE
begin
	if @w_telefono2_ab <> ''
	begin
	   select @w_telefonos = ltrim(rtrim(@w_telefono1_ab)) + ' / ' + ltrim(rtrim(@w_telefono2_ab))
	end
	ELSE
	begin
	   select @w_telefonos = ltrim(rtrim(@w_telefono1_ab))
	end
end

--CCA 436
select @w_parametro_cta_pte = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'PTENOR'
and    pa_producto = 'CCA'

if @@ROWCOUNT = 0
begin
   select @w_error = 708153
   goto ERROR
end

select @w_desembolso = isnull(count(1),0)
from  ca_desembolso
where dm_operacion = @w_operacionca
and   dm_estado = 'A'
and   dm_producto <> @w_parametro_cta_pte -- CCA 436 NO SE TIENE EN CUENTA EL PAGO DE LA OBLIGACION POR NORMALIZACION


/*DESCRIPCIONES DE CLASE DE CARTERA Y ORIGEN DE FONDOS*/
select @w_desc_clase_cartera = valor
from  cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla  = 'cr_clase_cartera'
and   X.codigo = Y.tabla
and   Y.codigo = @w_clase_cartera
set transaction isolation level read uncommitted


/* DESRIPCION DE LA EDAD*/
select @w_ct_desde = convert(varchar(10),ct_desde),
       @w_ct_hasta = convert(varchar(10),ct_hasta)
from  cob_credito..cr_param_cont_temp
where ct_codigo   = @w_edad
and   ct_clase    = @w_clase_cartera

select @w_des_edad = '('+ convert(varchar(10),@w_edad) + ') --> ' + @w_desc_clase_cartera + ' DESDE ' + ltrim(rtrim(@w_ct_desde)) + ' HASTA ' + ltrim(rtrim(@w_ct_hasta)) + ' MESES'


/* DECIMALES */
exec sp_decimales
      @i_moneda      = @w_moneda,
      @o_decimales   = @w_num_dec out

select @w_desc_producto = cp_descripcion
from   ca_producto
where  cp_producto = @w_nem_producto

if @w_desc_producto is null or @w_desc_producto = '' select @w_desc_producto = 'NO TIENE FORMA DE PAGO'

/** TIPO DE REAJUSTE **/
select @w_desc_tplazo = td_descripcion
from   ca_tdividendo
where  td_tdividendo = @w_tplazo

/** LINEA DE CREDITO  **/
select
   @w_inicio = NULL,
   @w_fin    = NULL
select
      @w_inicio = convert (varchar(10), li_fecha_inicio,@i_formato_fecha),
      @w_fin    = convert (varchar(10), li_fecha_vto,@i_formato_fecha)
from  cob_credito..cr_linea
where li_num_banco = @w_lin_credito

select   @w_tr_subtipo = tr_subtipo,
         @w_campana    = tr_campana --Req 0331
from     cob_credito..cr_tramite
where    tr_tramite = @w_tramite

/*SE OBTIENE LA DESCRIPCION DE LA CAMPAÂ¥A --Req 0331*/

select   @w_camp_det = ca_descripcion
from     cob_credito..cr_campana
where    ca_codigo = @w_campana

if @w_tr_subtipo = 'O'
   select @w_des_subtipo = 'ORIGINAL'

if @w_tr_subtipo = 'R'
   select @w_des_subtipo = 'RENOVACION'

if @w_tr_subtipo = 'E'
   select @w_des_subtipo = 'REESTRUCTURACION'

if @w_tr_subtipo = 'P'
   select @w_des_subtipo = 'PRORROGA'

if @w_tr_subtipo = 'S'
   select @w_des_subtipo = 'SUBRROGACION'

if @w_tr_subtipo = 'T'
   select @w_des_subtipo = 'OTRO SI'

if @w_tr_subtipo = 'U'
   select @w_des_subtipo = 'FUSION'


/**  FECHAS DE REAJUSTE  **/
select @w_reajuste_fecha = min(re_fecha)
from  ca_reajuste
where re_operacion = @w_operacionca
and   re_fecha    >= @w_fecha_ult_proceso

/**  TOTAL DE INTERES  **/
select
      @w_tasa=  isnull(sum(ro_porcentaje) ,0)
from  ca_rubro_op,ca_amortizacion
where ro_operacion  =  @w_operacionca
and   ro_tipo_rubro =  'I'
and   ro_fpago      in ('P','A')
and   am_operacion  =  @w_operacionca
and   am_concepto   =  ro_concepto


select @w_desc_tdividendo = valor
from cobis..cl_catalogo 
where tabla = (select codigo 
               from cobis..cl_tabla 
               where tabla = 'ca_tdividendo') 
and  codigo = @w_tdividendo

select @w_nom_oficial = fu_nombre
from  cobis..cl_funcionario, cobis..cc_oficial
where oc_oficial= @w_oficial
and   fu_funcionario = oc_funcionario
set transaction isolation level read uncommitted


select @w_des_sector   = Y.valor
from   cobis..cl_tabla X,cobis..cl_catalogo Y
where  X.tabla      = 'cl_banca_cliente'  --xma 'cc_tipo_banca'  --'cc_sector'@w_sector
and    X.codigo     = Y.tabla
--and    Y.codigo     = @w_sector  xma
and    Y.codigo     = @w_banca

set transaction isolation level read uncommitted

/** VERIFICAR SI PRESENTA CUOTAS ADICIONALES **/
if exists(select 1 from ca_cuota_adicional
          where ca_operacion = @w_operacionca
          and ca_cuota <> 0)
   select @w_cuota_adic = 'S'
else
   select @w_cuota_adic = 'N'

if isnull(@w_dia_pago,0) = 0
   select @w_fecha_fija = 'N'
else
   select @w_fecha_fija = 'S'

if @w_tipo_amortizacion = 'FRANCESA'
   select @w_cuota_fija = 'S'
else
   select @w_cuota_fija = 'N'

if isnull(@w_reajustable,'N') = 'N'
   select @w_reajuste = 'N',
   @w_reajuste_periodo = 0
else
   select @w_reajuste = 'S'


/*SALDO DE LA OPERACION. MODIFICADO*/
select @w_saldo_operacion = isnull(sum(am_cuota + am_gracia - am_pagado),0)
from  ca_amortizacion, ca_rubro_op
where am_operacion = @w_operacionca
and   ro_operacion = @w_operacionca
and   ro_tipo_rubro= 'C'
and   ro_concepto  = am_concepto


/* JAR REQ 230 - INCLUIR CALCULO DE SALDO DE HONORARIOS */
if exists (select 1 from cob_credito..cr_hono_mora   -- INI JAR REQ 230
            where hm_estado_cobranza = @w_cobranza)
begin

   /* INCLUIR CALCULO DE SALDO DE HONORARIOS */
   exec @w_return    = sp_saldo_honorarios
   @i_banco          = @i_banco,
   @i_num_dec        = @w_num_dec,
   @o_saldo_tot      = @w_saldo_cap out

   if @w_return <> 0
   begin
      /** SALDO TOTAL DE LA OPERACION   **/
      exec @w_return   = sp_calcula_saldo
      @i_operacion     = @w_operacionca,
      @i_tipo_pago     = 'A', --@w_anticipado_int,
      @o_saldo         = @w_saldo_operacion_finan out

      if @w_return <> 0
      begin
         select @w_error = @w_return
         goto ERROR
      end


      select @w_saldo_operacion_finan = isnull(@w_saldo_operacion_finan,0)
   end

   select @w_saldo_operacion_finan = isnull(@w_saldo_cap, 0)
end
else
begin

   /** SALDO TOTAL DE LA OPERACION   **/
   exec @w_return   = sp_calcula_saldo
   @i_operacion     = @w_operacionca,
   @i_tipo_pago     = 'A', --@w_anticipado_int,
   @o_saldo         = @w_saldo_operacion_finan out

   if @w_return <> 0
   begin
      select @w_error = @w_return
      goto ERROR
   end


   select @w_saldo_operacion_finan = isnull(@w_saldo_operacion_finan,0)
end

/* LCM - 293: CONSULTA LA TABLA DE RECONOCIMIENTO PARA VALIDAR SI LA OBLIGACION TIENE RECONOCIMIENTO */
select @w_vlr_x_amort = 0,
       @w_vlr_rec_ini = 0,
       @w_tiene_reco  = 'N'

select @w_vlr_x_amort = pr_vlr - pr_vlr_amort,
       @w_vlr_rec_ini = pr_vlr
from ca_pago_recono with (nolock)
where pr_operacion = @w_operacionca
and   pr_estado    = 'A'

if @@rowcount > 0
   select @w_tiene_reco = 'S'

/*OBTENIENDO DESCRIPCION DE LA DIRECCION DEL CLIENTE */
select @w_desc_direccion = di_descripcion
from  cobis..cl_direccion
where di_ente    = @w_cliente
and   di_direccion = @w_direccion
set transaction isolation level read uncommitted

if @w_desc_direccion is null or @w_desc_direccion = '' select @w_desc_direccion = 'NO EXISTE DESCRIPCION DE LA DIRECCION DEL CLIENTE'

/*DESCRIPCIONES DE TIPO DE EMPRESA*/
select @w_desc_t_empresa = isnull(valor,'NO EXISTE DESCRIPCION DE TIPO DE EMPRESA')
from  cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_tipo_empresa'
and   X.codigo= Y.tabla
and   Y.codigo= @w_tipo_empresa
set transaction isolation level read uncommitted

/*DESCRIPCIONES DE TAMAÂ¥O DE EMPRESA*/
select @w_desc_tmnio_empresa = isnull(valor,'NO EXISTE DESCRIPCION DE TAMANO DE EMPRESA')
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_validacion'
and   X.codigo= Y.tabla
and   Y.codigo= @w_validacion
set transaction isolation level read uncommitted

if   @w_fondos_propios = 'S'
     select @w_tabla = 'ca_fondos_propios'
else
     select @w_tabla = 'ca_fondos_nopropios'


select @w_desc_origen_fondos = ''

select @w_categoria_linea = dt_categoria
from ca_default_toperacion --, ca_operacion
where dt_toperacion = @w_toperacion

if @w_tipo  in ('R','C') begin
	select @w_desc_origen_fondos = valor
	from cobis..cl_tabla X, cobis..cl_catalogo Y
	where X.tabla = 'ca_categoria_linea'
	and   X.codigo= Y.tabla
	and   Y.codigo= @w_origen_fondos
	set transaction isolation level read uncommitted
end
else begin
	select @w_desc_origen_fondos = valor
	from cobis..cl_tabla X, cobis..cl_catalogo Y
	where X.tabla = 'cr_fuente_recurso'
	and   X.codigo= Y.tabla
	and   Y.codigo= @w_origen_fondos
	set transaction isolation level read uncommitted
end

/* JCQ 02/18/2003 DescripciÂ¢n del Programa de Crâ€šdito en Tabla de Catalogos */

select @w_des_programa = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_subtipo_linea'
and   X.codigo= Y.tabla
and   Y.codigo=   @w_programa
set transaction isolation level read uncommitted


/*CALIFICACION DE LA CARTERA*/
--GFP Concatenacion de valores de calificacion
select @w_desc_calificacion = @w_calificacion + ' - ' +valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'cr_calificacion'
and   X.codigo= Y.tabla
and   Y.codigo= @w_calificacion
set transaction isolation level read uncommitted

/*FECHA ULTIMA REESTRUCTURACION*/
select @w_fecha_ult_rees = max(tr_fecha_mov)
from ca_transaccion
where tr_tran in ('RES','PNO')
and   tr_operacion = @w_operacionca
and   tr_estado <> 'RV'
and   tr_secuencial > 0

if @w_fecha_ult_rees is null
begin

   select @w_marca_reest = oc_marca
   from cob_cartera..ca_carga_oper_conflicto
   where oc_tramite = @w_tramite

   if @w_marca_reest <> 'S'
   begin
      select @w_fecha_ult_rees = max(tr_fecha_mov)
      from  ca_transaccion, cob_credito..cr_normalizacion, cob_cartera..ca_operacion
      where tr_tran       = 'DES'
      and   tr_operacion  = @w_operacionca
      and   op_banco      = tr_banco
      and   tr_estado     <> 'RV'
      and   nm_tramite    = op_tramite
      and   nm_tipo_norm  <> 1 --DIFERENTE A PRORROGA DE CUOTA
      and   tr_secuencial > 0
   end

end

/** ESTADO DE COBRANZA **/
select @w_estado_cobranza = c.valor
from   cobis..cl_tabla t,
cobis..cl_catalogo c
where  t.tabla = 'cr_estado_cobranza'
and    c.tabla = t.codigo
and    c.codigo = @w_cobranza
set transaction isolation level read uncommitted


--- MINIMO DIVIDENDO VENCIDO CON CAPITAL
select @w_div_vencido = isnull(min(di_dividendo),0)
from ca_amortizacion, ca_rubro_op,ca_dividendo
where am_operacion = @w_operacionca
and ro_operacion = @w_operacionca
and am_operacion = di_operacion
and am_dividendo = di_dividendo
and am_cuota - am_pagado > 0   ---Que no este pagado
and di_estado    = 2
and ro_tipo_rubro= 'C'
and ro_concepto  = am_concepto


select @w_dias_cap_ven = 0
if @w_div_vencido > 0
begin
   select @w_dias_cap_ven = datediff(dd,di_fecha_ven,@w_fecha_ult_proceso)
   from ca_dividendo
   where di_operacion = @w_operacionca
   and di_dividendo = @w_div_vencido
   if @w_dias_cap_ven < 0
      select @w_dias_cap_ven = 0
   --end
end

--- DIAS DE VENCIMIENTO MORA VA REAL

-- FECHA FIN MINIMA DE DIVIDENDOS VENCIDOS

select @w_dias_venc = 0
select @w_fecha_mora_desde = convert(varchar(12),(min(di_fecha_ven)),101)
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_estado = 2 --Vencido

if  @w_fecha_mora_desde  is null
    select @w_fecha_mora_desde = convert(DATETIME,'01/01/1900')

if  @w_fecha_mora_desde > convert(DATETIME,'01/01/1900')
begin
   select @w_dias_venc = isnull(datediff(day,@w_fecha_mora_desde,@w_fecha_ult_proceso) ,0)
end
else
   select @w_dias_venc = 0


if @w_dias_venc < 0
   select @w_dias_venc = 0


if @w_refer  = 'CARTERIZACION DE SOBREGIRO'
   select @w_dias_venc = @w_dias_venc +  isnull(@w_op_divcap_original, 0)


if @w_naturaleza = 'A'
   select  @w_des_naturaleza = 'ACTIVA'
else
    select  @w_des_naturaleza = 'PASIVA'


select  @w_mercado_objetivo = tr_mercado_objetivo,
        @w_tipo_productor   = tr_tipo_productor,
        @w_mercado          = tr_mercado,
        @w_cod_actividad    = isnull(tr_cod_actividad,'NO EXISTE CODIGO DE ACTIVIDAD'),
        @w_num_desemb       = tr_num_desemb

from cob_credito..cr_tramite
 where tr_tramite = @w_tramite


-- DESCRIPCION DEL MERCADO OBJETIVO

--Se comenta la ejecucion de la tabla cl_mobj_subtipo hasta encontar los criterios de creacion
select    @w_des_mercado_objetivo = '   '
--select    @w_des_mercado_objetivo = isnull(ms_descripcion,'NO EXISTE DESCRIPCION DEL MERCADO OBJETIVO')
--from     cobis..cl_mobj_subtipo
--where   ms_codigo = @w_mercado_objetivo
--set transaction isolation level read uncommitted

-- DESCRIPCION DEL MERCADO

select @w_des_mercado  = isnull(valor,'NO EXISTE DESCRIPCION DEL MERCADO ')
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla
                where tabla = 'cl_mercado_objetivo')
and codigo = @w_mercado
set transaction isolation level read uncommitted


-- DESCRIPCION DEL TIPO PRODUCTOR

select @w_des_tipo_productor = valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla
                where tabla = 'cl_tipo_productor')
and codigo = @w_tipo_productor
set transaction isolation level read uncommitted

-- DESCRIPCION DEL CODIGO DE ACTIVIDAD PRODUCTIVA

select @w_des_actprod = isnull(valor,'NO EXISTE DESCRIPCION DEL CODIGO DE ACTIVIDAD PRODUCTIVA')
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla
                where tabla = 'cr_actividad_productiva')
and codigo = @w_cod_actividad
set transaction isolation level read uncommitted


-- SITUACION JURIDICA Y CAUSAL DEL CLIENTE
select @w_situacion = cn_situacion,
       @w_causal    = cn_causal
from cob_credito..cr_concordato
where cn_cliente = @w_cliente


-- DESCRIPCION DE LA SITUACION DEL CLIENTE
select @w_desc_situacion = isnull(valor,'NO EXISTE SITUACION CLIENTE')
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'cl_situacion_cliente'
and X.codigo = Y.tabla
and Y.codigo = @w_situacion
set transaction isolation level read uncommitted

if @w_desc_situacion is null or @w_desc_situacion = '' select @w_desc_situacion = 'NO EXISTE SITUACION CLIENTE'

-- DESCRIPCION DE LA CAUSAL DE LA SITUACION DEL CLIENTE
select @w_desc_causal = valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'cr_causal_situacion'
and X.codigo = Y.tabla
and Y.codigo = @w_causal
set transaction isolation level read uncommitted


select @w_total_desc_causal    = @w_causal + '  ' +  @w_desc_causal

if @w_total_desc_causal is null or @w_total_desc_causal = '' select @w_total_desc_causal = 'NO EXISTE DESCRIPCION DE LA CAUSAL DE LA SITUACION DEL CLIENTE'

-- INI - PAQUETE 2: REQ 260 - MIR VINCULANTE CALIF - 01/JUL/2011 - GAL
-- CALIFICACION DE ORIGINACION
select
@w_calif_orig      = cm_calificacion,
@w_desc_calif_orig = C.valor
from cob_credito..cr_calificacion_orig, cobis..cl_tabla T, cobis..cl_catalogo C
where cm_tramite = @w_tramite
and   T.tabla    = 'cr_calificacion'
and   C.tabla    = T.codigo
and   C.codigo   = cm_calificacion

-- CALIFICACION DE SEGUIMIENTO
select @w_fecha_ult_calif = max(dc_fecha)
from cob_conta_super..sb_dato_calificacion
where dc_cliente    = @w_cliente
and   dc_aplicativo = @w_apl_cartera
and   dc_tip_calif  = @w_tipo_calif_seg
and   dc_banco = @w_banco

select
@w_calif_segui      = dc_calificacion,
@w_desc_calif_segui = C.valor
from cob_conta_super..sb_dato_calificacion, cobis..cl_tabla T, cobis..cl_catalogo C
where dc_cliente    = @w_cliente
and   dc_aplicativo = @w_apl_cartera
and   dc_tip_calif  = @w_tipo_calif_seg
and   dc_banco      = @w_banco
and   dc_fecha      = @w_fecha_ult_calif
and   T.tabla       = 'cr_calificacion'
and   C.tabla       = T.codigo
and   C.codigo      = dc_calificacion
-- FIN - PAQUETE 2: REQ 260


-- FECHA DE MIGRACION
select @w_fecha_migracion = tr_fecha_mov
  from ca_transaccion
 where tr_tran = 'MIG'
   and tr_operacion = @w_operacionca

-- Fecha de castigo
-- GFP Se comenta codigo no aplica a FINCA
/*
if @w_op_estado = @w_est_castigado 
begin

   select @w_fecha_castigo = tr_fecha_ref
   from ca_transaccion
   where tr_operacion = @w_operacionca
   and   tr_tran      = 'CAS'
   and   tr_estado   <> 'RV'

   select @w_fecha_castigo = tr_fecha_mov
   from ca_transaccion_bancamia
   where tr_banco     = @w_banco
   and   tr_tran      = 'CAS'
   and   tr_estado   <> 'RV'

end
*/
-- Inicio IFJ 30/Ene/2006 REQ 316
-- VALORES DE LA OBLIGACION EN TABLA ca_valor_atx

exec @w_return = sp_valor_atx_mas
@i_banco = @w_banco

if @w_return <> 0
begin
   return @w_return
end

select   @w_vx_valor_vencido = vx_valor_vencido,
         @w_vx_monto         = vx_monto,
         @w_vx_monto_max     = vx_monto_max
from     ca_valor_atx
where    vx_banco = @w_banco
-- Fin IFJ 30/Ene/2006 REQ 316

/* SI TIENE PAGO POR RECONOCIMIENTO ADICIONA A LOS VALORES DE SALDO EL VALOR RECONOCIDO */
if @w_tiene_reco = 'S'
begin

   /* OBTIENE EL SECUENCIAL RPA DEL PAGO POR RECONOCIMIENTO */
   select @w_sec_rpa_rec = dtr_secuencial
   from
   ca_transaccion with (nolock),
   ca_det_trn with (nolock)
   where tr_operacion  = @w_operacionca
   and   tr_operacion  = dtr_operacion
   and   tr_secuencial = dtr_secuencial
   and   tr_secuencial > 0
   and   tr_tran       = 'RPA'
   and   tr_estado     <> 'RV'
   and   dtr_concepto  in (select c.codigo from cobis..cl_tabla t, cobis..cl_catalogo c
                           where t.tabla = 'ca_fpago_reconocimiento'
                           and   t.codigo = c.tabla) -- Req. 397  Forma de pago por reconocimiento


   /* OBTIENE EL SECUENCIAL PAG DEL PAGO POR RECONOCIMIENTO */
   select @w_sec_rpa_pag = ab_secuencial_pag
   from ca_abono with (nolock)
   where ab_operacion = @w_operacionca
   and   ab_secuencial_rpa = @w_sec_rpa_rec

   /* OBTIENE EL VALOR A CAPITAL PAGADO POR EL RECONOCIMIENTO PARA LAS CUOTAS VENCIDAS */
   if @w_sec_rpa_pag <> 0
   begin
      select @w_recono = isnull(sum(am_cuota),0)
      from ca_det_trn with (nolock), ca_amortizacion with (nolock),ca_dividendo
      where di_operacion  = @w_operacionca
      and   am_operacion  = di_operacion
      and   am_dividendo  = di_dividendo
      and   di_estado     = 2
      and   am_dividendo  = dtr_dividendo
      and   dtr_secuencial = @w_sec_rpa_pag
      and   dtr_operacion = am_operacion
      and   dtr_concepto = 'CAP'
      and   am_concepto  = dtr_concepto
      and   dtr_monto <= am_cuota
   end
   /* Suma Valor por amortizar al saldo de la operacion */
   select @w_saldo_operacion = @w_saldo_operacion + isnull(@w_vlr_x_amort,0)
   /* Suma Valor por amortizar al saldo financiero de la operacion */
   select @w_saldo_operacion_finan = @w_saldo_operacion_finan + isnull(@w_vlr_x_amort,0)
   /* Suma Valor por amortizar al saldo a la fecha de la operacion */
   select @w_vx_monto_rec = @w_vx_monto + isnull(@w_vlr_x_amort,0)
   /* Suma valor capital normal + Valor Capital Reconocimiento Dividendos Vencidos */
   select @w_vx_valor_vencido_rec = @w_vx_valor_vencido + @w_recono

end

exec    sp_op_anterior
        @i_banco    = @w_banco,
        @o_anterior = @w_anterior  out

select  @w_fecha_ini_sobr = dateadd(dd, -@w_op_divcap_original, @w_fecha_ini)  -- IFJ 609

-- INI JAR REQ 256
/* OPERACIONES PADRE-HIJA PARA REESTRUCTURACIONES ACTIVAS */
if @w_fecha_ult_rees is not null
begin
   -- OP PADRE
  select @w_op_padre = op_banco
   from ca_operacion, ca_op_reest_padre_hija
   where ph_op_hija  = @w_operacionca
   and ph_op_padre = op_operacion

   -- OP HIJA
   select @w_op_hija = op_banco
   from ca_operacion, ca_op_reest_padre_hija
   where ph_op_padre = @w_operacionca
   and ph_op_hija  = op_operacion
   -- FIN JAR REQ 256
end

-- FIN 246 Reestructuracion


--Hallar Alianza
select @w_des_alianza = null
    --Se comenta hasta encontrar los criterios de creacion de la tabla cl_alianza_cliente
    select @w_des_alianza = '  ' 
/*if @w_operacionca is not null
begin
   -- SI EL TRAMITE TIENE OPERAICON EN CARTERA VERIFICA QUE EXISTA.
   select @w_des_alianza = isnull((al_nemonico + ' - ' + al_nom_alianza), '  ')
   from cobis..cl_alianza_cliente with (nolock),
        cobis..cl_alianza         with (nolock),
        cob_cartera..ca_operacion with (nolock),
        cob_credito..cr_tramite   with (nolock)
   where ac_ente      =  @w_cliente
   and   ac_alianza   = al_alianza
   and   ac_alianza   = tr_alianza
   and   al_estado    = 'V'
   and   ac_estado    = 'V'
   and   op_operacion = @w_operacionca
   and   op_tramite   = tr_tramite
end else begin
   select @w_des_alianza = isnull((al_nemonico + ' - ' + al_nom_alianza), '  ')
    from cobis..cl_alianza_cliente with (nolock),
         cobis..cl_alianza         with (nolock)
   where ac_ente    = @w_cliente
   and   ac_alianza = al_alianza
   and   al_estado  = 'V'
   and   ac_estado  = 'V'
   
end
*/--fin de cometario en espera

--MTA Inicio Cuando el flujo es individual consulta la cuenta del cliente en las tablas del cliente
if (@w_toperacion = 'INDIVIDUAL')
begin
   select @w_cliente =  tr_cliente
     from cob_credito..cr_tramite
	where tr_tramite = @w_tramite

   select @w_cuenta = isnull(ea_cta_banco,0)
     from cobis..cl_ente_aux
    where ea_ente = @w_cliente
end
--MTA Fin

--select @w_dias_venc_completo = (case
--when @w_op_divcap_original > 0  and @w_refer  = 'CARTERIZACION DE SOBREGIRO' then
--   convert(varchar,@w_dias_venc) + ' Fecha de Inicio Sobregiro = ' + convert(varchar(10),@w_fecha_ini_sobr,@i_formato_fecha)
--else
--   convert(varchar,@w_dias_venc)
--end)
if @w_op_divcap_original > 0 and @w_refer = 'CARTERIZACION DE SOBREGIRO'
   select @w_dias_venc_completo = convert(varchar,@w_dias_venc) + ' Fecha de Inicio Sobregiro = ' + convert(varchar(10),@w_fecha_ini_sobr,@i_formato_fecha)
else
   select @w_dias_venc_completo = convert(varchar,@w_dias_venc)
   
--GFP Consulta de datos adicionales del prestamo
SELECT  @w_estado_gestion_cobranza = oda_estado_gestion_cobranza,
        @w_aceptar_pagos           = oda_aceptar_pagos,
		@w_grupo_contable          = oda_grupo_contable, --GFP 06/Ene/2022
		@w_categoria_plazo         = (select valor from   cobis..cl_catalogo y, cobis..cl_tabla t
                                                       where  t.tabla = 'ca_categoria_plazo'
                                                       and    y.tabla   = t.codigo
                                                       and    y.codigo  = oda_categoria_plazo),
        @w_tipo_doc_tributario     = (select valor from cobis..cl_catalogo c, cobis..cl_tabla t
                                                       where  t.tabla = 'ca_tipo_documento_fiscal'
                                                       and    c.tabla   = t.codigo
                                                       and    c.codigo  = oda_tipo_documento_fiscal)
FROM cob_cartera..ca_operacion_datos_adicionales
WHERE oda_operacion = @w_operacionca

if @@rowcount = 0
begin
   select @w_error = 710238
   goto ERROR
end

select @w_estado_gestion_cobranza = @w_estado_gestion_cobranza + ' - ' +valor
from cobis..cl_tabla X, cobis..cl_catalogo Y
where X.tabla = 'ca_estado_gestion_cobranza'
and   X.codigo= Y.tabla
and Y.codigo = @w_estado_gestion_cobranza

-- KDR Fecha de castigo
select @w_fecha_castigo = null
if @w_op_estado = @w_est_castigado 
begin
    select @w_sec_camb_est_cast = max(tr_secuencial)
    from ca_operacion, ca_transaccion 
    where op_operacion = @w_operacionca
    and op_operacion = tr_operacion
    and tr_tran = 'ETM'
    and tr_observacion = 'CAMBIO DE ESTADO A CASTIGADO'
    and tr_estado <> 'RV'
    
    select @w_fecha_castigo = tr_fecha_ref
    from ca_transaccion
    where tr_secuencial = @w_sec_camb_est_cast
    and   tr_operacion = @w_operacionca
	
	select @w_fecha_fin = @w_fecha_castigo --GFP R200366 Cuando la operación esta castigada se establece como fecha fin la fecha de castigo
end

--GFP  Se obtiene valores descontados en el desembolso
select @w_descontados = isnull(sum(ro_valor),0)
from ca_rubro_op
where ro_operacion = @w_operacionca
and   ro_fpago     = 'L'

--Concatenación información tipo de dividendo
select @w_desc_tdividendo = concat(@w_tdividendo, ' - ', @w_desc_tdividendo)

select
@w_operacionca, --0
@w_banco,
@w_tramite,
@w_lin_credito,
@w_estado,
@w_cliente,
@w_toperacion,
@w_desc_toperacion,
@w_moneda,
--@w_desc_moneda, 10  reemplazado por entidad
@w_desc_entidad,
@w_oficina, --10
@w_oficial,
convert(varchar(10),@w_fecha_ini,@i_formato_fecha),
convert(varchar(10),@w_fecha_fin,@i_formato_fecha),  --14 GFP Campo de fecha de vencimiento
convert(varchar(10),@w_fecha_prox_pag,@i_formato_fecha), --15
round(@w_monto,@w_num_dec),
@w_tplazo,
@w_desc_tplazo,
@w_plazo,
@w_tdividendo,  --20
@w_desc_tdividendo,
@w_periodo_cap,
@w_periodo_int,
@w_periodos_gracia,
@w_periodos_gracia_int,
@w_dist_gracia,
@w_destino,
@w_desc_destino,
@w_ciudad,
@w_desc_ciudad, --30
@w_nem_producto,
@w_desc_producto,
@w_cuenta,
@w_reajuste_periodo,
convert(varchar(10),@w_reajuste_fecha,@i_formato_fecha),
@w_reajuste_num,
@w_renovacion,
@w_num_renovacion,
@w_precancelacion,
@w_tipo, -- 40
@w_porcentaje_fin,
@w_tasa_fin,
@w_cuota_completa,
@w_anticipado_int,
@w_reajuste_intereses,
@w_reduccion,
@w_cuota_anticipada,
@w_dias_anio,
@w_tipo_amortizacion,
@w_cuota_fija, -- 50
--convert(float, @w_cuota), --LPO CDIG duplicado
round(@w_cuota,@w_num_dec),
round(@w_cuota_capital,@w_num_dec),
@w_dias_gracia,
@w_dia_pago,
@w_desc_ofi,
@w_inicio,
@w_fin,
@w_nombre,
@w_tasa,
@w_referencial, -- 60
@w_desc_referencial,
@w_opcion_cap, ---@w_nom_oficial,
@w_ant_per_calculo, --0, -- Anterior periodo de calculo
@w_reajuste_especial,

--xma @w_sector,
@w_banca,

@w_des_sector,
@w_anterior,
@w_migrada,
@w_refer,
@w_desembolso, -- 70
convert(varchar(10),@w_fecha_liq,@i_formato_fecha),
@w_cuota_adic,
@w_meses_hip,
round(@w_monto_aprobado,@w_num_dec),
@w_tipo_aplicacion,
@w_gracia_int,
@w_mes_gracia,
@w_num_dec,
@w_fecha_fija,
@w_reajuste,   -- 80
@w_evitar_feriados,
convert(varchar(10),@w_fecha_ult_proceso,@i_formato_fecha),
round(@w_saldo_operacion,@w_num_dec),
@w_dias_clausula,
@w_clausula_aplicada,
@w_periodo_crecimiento,
@w_tasa_crecimiento,
@w_desc_direccion,
@w_desc_tipo,
@w_clase_cartera,    --90
@w_desc_clase_cartera,
@w_des_programa,
@w_desc_origen_fondos,
@w_desc_calificacion,
@w_numero_reest,
round(@w_saldo_operacion_finan,@w_num_dec),
convert(varchar(10),@w_fecha_ult_rees,@i_formato_fecha),
--IFJ 609
@w_dias_venc_completo,
@w_fondos_propios ,
@w_prd_cobis , --100
@w_ref_exterior,
@w_sujeta_nego,
@w_ref_red,
round(@w_sal_pro_pon,@w_num_dec),
@w_tipo_empresa   ,
@w_desc_t_empresa,
@w_validacion   ,
@w_desc_tmnio_empresa,
convert(varchar(10),@w_fecha_pri_cuota,@i_formato_fecha),
--@w_des_subtipo, 110  fue reemplazado por naturaleza
@w_des_naturaleza,
@w_base_calculo,
@w_recalcular,
@w_dia_habil,
@w_usa_tasa_eq ,
@w_grupo_fact, ---116
@w_dias_cap_ven, ---116
@w_bvirtual,
@w_extracto,
@w_reestructuracion,
@w_subtipo,   --120
convert(varchar(10),@w_fecha_embarque,@i_formato_fecha),
convert(varchar(10),@w_fecha_dex,@i_formato_fecha),
@w_num_deuda_ext,
@w_nace_vencida,
@w_num_comex,    --125
@w_calcula_devolucion,
@w_des_edad, --127
@w_estado_cobranza,  ---128
@w_op_pasiva_externa,
round(convert(money,@w_op_margen_redescuento),@w_num_dec),   --130
convert(char(10),@w_fecha_migracion, @i_formato_fecha),
@w_nom_abogado,        -- 132
@w_total_diferido,     -- 133
@w_pendiente_diferido, -- 134
@w_descontados ,       -- 135      REQ 175: PEQUEÃ‘A EMPRESA
@w_telefonos,          -- 136
@w_direccion1,         -- 137
@w_vlr_rec_ini,        -- 138      REQ 293: PAGOS POR RECONOCIMIENTO
@w_vlr_x_amort,        -- 139      REQ 293: PAGOS POR RECONOCIMIENTO
@w_op_padre,           -- 140  JAR REQ 256
@w_op_hija,            -- 141  JAR REQ 256
@w_tramite_max,        -- 142  Tramite para Reestructuracion
@w_des_alianza,        -- 143  NR 353
@w_llave_finagro,      -- 144  REQ 479 LLave Finagro
@w_finagro,            -- 145
@w_gar_finagro,        -- 146  REQ 479 Garantia Finagro
@w_sector,
round(@w_tir,@w_num_dec),  -- AMP 20210522
round(@w_tea,@w_num_dec),   -- AMP 20210522
@w_op_pproductor,      -- 150  GFP valor de Scoring
@w_estado_gestion_cobranza,  --151 GFP estado de cobranza
@w_aceptar_pagos,            --152 GFP identificacion si acepta pagos o no
@w_grupo_contable,           --153 GFP 06/Ene/2022 identificacion de grupo contable
@w_categoria_plazo,          -- GFP Categoria de plazo
@w_tipo_doc_tributario       -- KDR Tipo de coumento tributario

select
@w_mercado_objetivo,                                   ----1
@w_des_mercado_objetivo,                               ----2
@w_tipo_productor,                                     ----3
@w_des_tipo_productor,                                 ----4
@w_desc_moneda,                                        ----5
@w_nom_oficial,                                        ----6
@w_mercado,                                            ----7
@w_des_mercado,                                        ----8
@w_cod_actividad,                                      ----9
@w_des_actprod,                                        ----10
@w_num_desemb,                                         ----11
@w_desc_situacion,                                     ----12
@w_total_desc_causal,                                  ----13
convert(varchar(10),@w_fecha_castigo,@i_formato_fecha),----14
@w_calif_orig,                                         ----15
@w_desc_calif_orig,                                    ----16
@w_calif_segui,                                        ----17
@w_desc_calif_segui,                                   ----18
@w_toperacion,                                         ----19
@w_desc_toperacion,                                    ----20
@w_campana,                                            ----21
@w_camp_det                                            ----22

-- Inicio IFJ 30/Ene/2006 REQ 316
select
round(@w_vx_valor_vencido,@w_num_dec),   -- 1  Valor Vencido de Oblicacion
round(@w_vx_monto,@w_num_dec),           -- 2  Valor Vigente de Obligacion
round(@w_vx_monto_max,@w_num_dec),       -- 3  Valor de Cancelacion de Obligacion
round(@w_vx_valor_vencido_rec,@w_num_dec), -- 4  Valor Vencido de Oblicacion mas valor de reconocimiento
round(@w_vx_monto_rec,@w_num_dec)       -- 5  Valor Vigente de Obligacion mas valor de reconocimiento


-- Fin IFJ 30/Ene/2006 REQ 316

--INICIO JTO 17/JUNIO/2019  -- CONSULTA DE DATOS PARA OPERACIONES GRUPALES, HIJAS, INTERCICLAS
SELECT b.op_grupo
,j.gr_nombre
,d.en_ente
,d.en_nombre
,d.p_p_apellido
,d.p_s_apellido
,d.en_nombre + ' ' + d.p_p_apellido + ' ' + d.p_s_apellido
,b.op_grupal  -- VERIFICO SI ES GRUPO EL PADRE DE ESA FORMA SE QUE ES PADRE O ES HIJA
,a.op_ref_grupal
,e.dc_tciclo
,CASE WHEN a.op_grupal = 'S' AND a.op_ref_grupal IS null THEN 'GRUPAL' -- ES GRUPAL SI EL CAMPO OP_GRUPAL = S Y OP_REF_GRUPAL ES NULL
      WHEN e.dc_tciclo = 'N' THEN 'HIJA'
      WHEN e.dc_tciclo = 'I' THEN 'INTERCICLO' END
,isnull(e.dc_ciclo_grupo,h.ci_ciclo)
,e.dc_ciclo
,convert(varchar(10),f.di_fecha_ini,@i_formato_fecha)
,g.tr_tipo
,g.tr_subtipo
,CASE WHEN g.tr_tipo = 'O' THEN 'IN'
      WHEN g.tr_tipo = 'R' AND g.tr_subtipo = 'N' THEN 'RN'
      WHEN g.tr_tipo = 'R' AND g.tr_subtipo = 'F' THEN 'RF' END
,b.op_cuenta
,isnull(h.ci_monto_ahorro, 0)  -- JTO 25/06/2019 MONTO MINIMO ESPERADO
,CASE WHEN b.op_admin_individual = 'N' THEN 'GRUPAL'
      WHEN b.op_admin_individual = 'S' THEN 'INDIVIDUAL' END
,b.op_admin_individual
,a.op_estado
,i.es_descripcion
,a.op_tramite
,b.op_tramite
FROM cob_cartera..ca_operacion a
INNER JOIN cob_cartera..ca_operacion b ON ((b.op_banco = a.op_banco AND b.op_ref_grupal IS NULL) OR  b.op_banco = a.op_ref_grupal)
INNER JOIN cobis..cl_cliente_grupo c ON c.cg_grupo = b.op_grupo AND c.cg_rol = 'P'
INNER JOIN cobis..cl_ente d ON d.en_ente = c.cg_ente
LEFT JOIN cob_cartera..ca_det_ciclo e ON e.dc_grupo = b.op_grupo AND e.dc_referencia_grupal = b.op_banco AND e.dc_operacion = a.op_operacion
INNER JOIN cob_cartera..ca_dividendo f ON f.di_operacion = a.op_operacion AND f.di_dividendo = 1
INNER JOIN cob_credito..cr_tramite g ON g.tr_tramite = a.op_tramite
LEFT JOIN cob_cartera..ca_ciclo h ON h.ci_grupo = b.op_grupo AND h.ci_prestamo = b.op_banco AND h.ci_operacion = b.op_operacion
INNER JOIN cob_cartera..ca_estado i ON i.es_codigo = a.op_estado
INNER JOIN cobis..cl_grupo j ON j.gr_grupo = b.op_grupo
WHERE a.op_banco= @i_banco
--FIN JTO 17/JUNIO/2019  -- CONSULTA DE DATOS PARA OPERACIONES GRUPALES, HIJAS, INTERCICLAS

return 0


ERROR:
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_file  = null,
   @t_from  = @w_sp_name,
   @i_num   = @w_error

   return @w_error




GO

