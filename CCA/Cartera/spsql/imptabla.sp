/************************************************************************/
/*   Archivo:             imptabla.sp                                   */
/*   Stored procedure:    sp_imp_tabla_amort                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:        Francisco Yacelga                             */
/*   Fecha de escritura:    09/Dic./1997                                */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Consulta para imprimir la tabla de amortizacion y en caso de la    */
/* simulacion  solamente es una opcion mas.                             */
/*                         MODIFICACIONES                               */
/*      FECHA           AUTOR      RAZON                                */
/*      nov-30-2005   Elcira Pelaez   enviar llave erdescuento y margen */
/*      ene-09-2007   Elcira Pelaez   def 7705                          */
/*      ene-19-2012   Luis C. Moreno  RQ293 Saldo por amort. reconoc.   */
/*      ago-13 2012     Acelis  controlar estados garantias Req 272     */
/*      jul-23-2013   Luis Guzman     Req. 366 Seguros                  */
/*      jun-06-2014   Luis Moreno     Req. 433 Pagos Anticipados        */
/*      Ago-04-2014   Fabian Quintero Req. 392 Pagos Flexibles          */
/*      Dic-03-2014   Luis Guzman     Req. 409 Tasa Seguros             */
/*      Dic-03-2014   Liana Coto  Req 406 Tasa seguro de vida empleados */
/*      Jun-22-2015   Elcira Pelaez   Homologacion con produccion NR 397*/
/*                                     406-409-424                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'tmp_interes_amortiza_tmp')
   drop table tmp_interes_amortiza_tmp
go
--- NR.397-406-409-424
create table tmp_interes_amortiza_tmp
(
 cuota      smallint   null,
 monto      money      null,
 concepto   catalogo   null,
 tasa       float      null,
 spid       int--,
-- @t_trn                  INT       = NULL
) --lock datarows
go


if exists (select 1 from sysobjects where name = 'sp_imp_tabla_amort')
   drop proc sp_imp_tabla_amort
go
--- REQ 392
create proc sp_imp_tabla_amort (
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = null,
   @t_trn               smallint    = null,
   @i_operacion         char(1)     = null,
   @i_banco             cuenta      = null,
   @i_formato_fecha     int         = null,
   @i_dividendo         int         = null
)
as
declare
   @w_sp_name                      varchar(32),
   @w_error                        int,
   @w_operacionca                  int,
   @w_tamanio                      int,
   @w_tipo                         char(1),
   @w_det_producto                 int,
   @w_cliente                      int,
   @w_nombre                       varchar(60),
   @w_direccion                    varchar(100),
   @w_ced_ruc                      varchar(15),
   @w_telefono                     varchar(15),
   @w_toperacion_desc              varchar(100),
   @w_moneda                       tinyint,
   @w_moneda_desc                  varchar(30),
   @w_monto                        money,
   @w_plazo                        smallint,
   @w_tplazo                       varchar(30),
   @w_tipo_amortizacion            varchar(15),
   @w_tdividendo                   varchar(30),
   @w_periodo_cap                  smallint,
   @w_periodo_int                  smallint,
   @w_gracia                       smallint,
   @w_gracia_cap                   smallint,
   @w_gracia_int                   smallint,
   @w_cuota                        money,
   @w_tasa                         float,
   @w_mes_gracia                   tinyint,
   @w_reajustable                   char(1),
   @w_periodo_reaj                 int,
   @w_primer_des                   int,
   @w_tasa_ef_anual                float,
   @w_periodicidad_o               char(1),
   @w_modalidad_o                  char(1),
   @w_fecha_fin                    varchar(10),
   @w_dias_anio                    int,
   @w_base_calculo                 char(1),
   @w_tasa_referencial             varchar(12),
   @w_signo_spread                 char(1),
   @w_valor_spread                 float,
   @w_valor_base                   float,
   @w_modalidad                    char(1),
   @w_valor_referencial            float,
   @w_sector                       char(1),
   @w_fecha_liq                    varchar(10),
   @w_dia_fijo                     int,
   @w_fecha_pri_cuot               varchar(10),
   @w_recalcular_plazo             char(1),
   @w_evitar_feriados              char(1),
   @w_ult_dia_habil                char(1),
   @w_tasa_equivalente             char(1),
   @w_tipo_puntos                  char(1),
   @w_ref_exterior                 cuenta,
   @w_fec_embarque                 varchar(15),
   @w_fec_dex                      varchar(15),
   @w_num_deuda_ext                cuenta,
   @w_num_comex                    cuenta,
   @w_secuencial_ref               int,
   @w_tasa_base                    catalogo,
   @w_saldo_actual                 money,
   @w_saldo_cap                    money,
   @w_saldo_mora                   money,
   @w_saldo_venc                   money,
   @w_capital_rubro                money,
   @w_tcuota                       smallint,
   @w_tmonto                       money,
   @w_tconcepto                    catalogo,
   @w_ttasa                        float,
   @w_tporcentaje                  float,
   @w_fecha_base                   datetime,
   @w_num_dec                      tinyint,
   @w_oficina                      smallint,
   @w_nom_oficina                  varchar(64),
   @w_ult_tasa                     float,
   @w_concepto_int                 catalogo,
   @w_mon_nacional                 tinyint,
   @w_fecha_ult_pro                datetime,
   @w_monto_aprobado               money,
   @w_fecha                        datetime,
   @w_op_direccion                 tinyint,
   @w_op_codigo_externo            cuenta,
   @w_margen_redescuento           float,
   @w_rowcount                     int,
   @w_pmipymes                     catalogo,
   @w_ivamipymes                   catalogo,
   @w_parametro_fng                catalogo,
   @w_parametro_fag                catalogo,
   @w_parametro_usaid              catalogo,
   @w_ivafng                       catalogo,
   @w_ivafag                       catalogo,
   @w_ivausaid                     catalogo,
   @w_segdeven                     catalogo,
   @w_cod_gar_fng                  catalogo,
   @w_cod_gar_fag                  catalogo,
   @w_cod_gar_usaid                catalogo,
   @w_gar_op                       catalogo,
   @w_tipos_gar                    int,
   @w_cobros_amortiza              int,
   @w_cobros                       float,
   @w_pl_meses                     int,
   @w_plazo_am                     int,
   @w_dist_gracia                  char(1),                             -- REQ 175: PEQUENA EMPRESA
   @w_ffin_gracia                  datetime,                            -- REQ 175: PEQUENA EMPRESA
   @w_deshacer_tran                char(1),                             -- REQ 175: PEQUENA EMPRESA
   @w_estado                       tinyint,                             -- REQ 175: PEQUENA EMPRESA
   @w_divini_reg                   smallint,                            -- REQ 175: PEQUENA EMPRESA
   @w_di_fecha_ini                 datetime,                            -- REQ 175: PEQUENA EMPRESA
   @w_di_fecha_ven                 datetime,                            -- REQ 175: PEQUENA EMPRESA
   @w_num_dividendos               smallint,                            -- REQ 175: PEQUENA EMPRESA
   @w_plazo_operacion              smallint,                            -- REQ 175: PEQUENA EMPRESA
   @w_cuota_desde_cap              smallint,                            -- REQ 175: PEQUENA EMPRESA
   @w_est_novigente                tinyint,                             -- REQ 175: PEQUENA EMPRESA
   @w_est_credito                  tinyint,                             -- REQ 175: PEQUENA EMPRESA
   @w_est_cancelado                tinyint,                             -- REQ 175: PEQUENA EMPRESA
   @w_di_de_capital                smallint,                            -- REQ 175: PEQUENA EMPRESA
   @w_divs_reg                     smallint,                            -- REQ 175: PEQUENA EMPRESA
   @w_concepto_cap                 catalogo,                            -- REQ 175: PEQUENA EMPRESA
   @w_capitalizar                  money   ,                            -- REQ 175: PEQUENA EMPRESA
   @w_tramite                      int     ,                            -- REQ 212: BANCA RURAL
   @w_tipo_garantia                varchar(50),                         -- REQ 212: BANCA RURAL
   @w_cod_tipogar                  catalogo,                            -- REQ 212: BANCA RURAL
   @w_colaterales                  varchar(20),                         -- REQ 212: BANCA RURAL
   @w_tipo_superior                catalogo,                            -- REQ 212: BANCA RURAL
   @w_vlr_x_amort                  money,                               -- REQ 293: RECONOCIMIENTO GARANTIAS FNG Y USAID
   @w_tramite_seg                  int,                                 -- REQ 366: SEGUROS   
   @w_nro_tramites                 int,                                 -- REQ 366: SEGUROS   
   @w_tasa_seg_ind                 float,                               -- REQ 366: SEGUROS   
   @w_tasa_seg_1_perd              float,                               -- REQ 366: SEGUROS   
   @w_tasa_seg_exequias            float,                               -- REQ 366: SEGUROS   
   @w_tasa_seg_danos               float,                               -- REQ 366: SEGUROS   
   @w_operacion_seg                int,                                 -- REQ 366: SEGUROS   
   @w_tasa_ef_anual_aux            float,                               -- REQ 366: SEGUROS   se solicita que No se muestre la tasa ponderada al cliente
   @w_valor_total_seg              money,                               -- REQ 366: SEGUROS   Mapea a la tabla de amortizacion el valor original de los seguros del tramite
   @w_alianza                      int,                                 -- REQ 353: Alianzas
   @w_desalianza                   varchar(255),
   @w_segdeem                      catalogo,                            -- REQ 406 Tasa seguro de vida empleados
   @w_parametro_fgu                catalogo,                            -- REQ 379: GARANTIAS CON COBRO INDEPENDIENTE 
   @w_parametro_fgu_iva            catalogo,                            -- REQ 379: GARANTIAS CON COBRO INDEPENDIENTE
   @w_rubros                       varchar(10),
   @w_tabla_rubros                 varchar(30),
   @w_div_vig                      tinyint,
   @w_div_cap                      tinyint,
   @w_cuota_cap                    money,
   @w_sld_cap_div                  money,
   @w_tiene_reco                   char(1),
   @w_vlr_calc_fijo                money,
   @w_div_pend                     money,
   @w_monto_reconocer              money,
   @w_td_factor                    int

-- FQ: NR-392
declare
   @w_tflexible                     catalogo

select @w_tflexible = pa_char
from   cobis..cl_parametro
where  pa_producto  = 'CCA'
and    pa_nemonico  = 'TFLEXI'
set transaction isolation level read uncommitted

declare @wt_estados_org table(
dividendo      smallint      not null,
estado         tinyint       not null)
   
create table #conceptos (
 codigo    varchar(10),
 tipo_gar  varchar(64)
 )

create table #rubros (
garantia      varchar(10),
rre_concepto  varchar(64),
tipo_concepto varchar(10),
iva           varchar(5),
)   
   
select @w_sp_name       = 'sp_imp_tabla_amort',
       @i_formato_fecha = 103,
       @w_deshacer_tran = 'N'                                                  -- REQ 175: PEQUENA EMPRESA

select @w_moneda = op_moneda
from   ca_operacion
where  op_banco = @i_banco

select @w_mon_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

-- CONCEPTO PRINCIPAL INTERES
select @w_concepto_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'

if @@rowcount = 0 
   return 710076

-- CONCEPTO PRINCIPAL CAPITAL
select @w_concepto_cap = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'

if @@rowcount = 0 
   return 710076


/*PARAMETRO COMISION MIPYMES */
select @w_pmipymes = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MIPYME'
set transaction isolation level read uncommitted

/*PARAMETRO IVA COMISION MIPYMES */
select @w_ivamipymes = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAMIP'
set transaction isolation level read uncommitted

/* Parametro de garantias colaterales */
select @w_colaterales = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'GARESP'

/*PARAMETRO DE LA GARANTIA DE FNG*/
select @w_parametro_fng = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'
set transaction isolation level read uncommitted

/*PARAMETRO DE LA GARANTIA FAG*/
select @w_parametro_fag = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CMFAGP'

/*PARAMETRO DE LA GARANTIA USAID*/
select @w_parametro_usaid = pa_char    
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'CMUSAP'

/*PARAMETRO IVA DE LA GARANTIA DE FNG*/
select @w_ivafng = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG'
set transaction isolation level read uncommitted

/*PARAMETRO DE IVA DE LA GARANTIA FAG*/
select @w_ivafag = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFAG'

/*PARAMETRO DE IVA DE LA GARANTIA USAID*/
select @w_ivausaid = pa_char    
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'ICMUSA'

select @w_cod_gar_fng = pa_char
from cobis..cl_parametro
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

-- Tipo Garantia Padre FAG
select @w_cod_gar_fag = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and   pa_nemonico = 'CODFAG'

select @w_cod_gar_usaid = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'GAR'
and pa_nemonico = 'CODUSA'

/*PARAMETRO DE SEGURO VENCIDO*/
select @w_segdeven = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'SEDEVE'
set transaction isolation level read uncommitted

--PARAMETRO PARA SEGURO VIDA DE EMPLEADOS Req 406 LC 28/ENE/2014
select @w_segdeem = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'SEDEEM'

/*PARAMETRO DE LA GARANTIA DE FGU REQ 379*/
select @w_parametro_fgu = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto = 'CCA'
and   pa_nemonico = 'COMGRP'
set transaction isolation level read uncommitted

/*PARAMETRO DE LA GARANTIA DE FGU*/
select @w_parametro_fgu_iva = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAGRP'
set transaction isolation level read uncommitted

-- ESTADOS DE CARTERA
exec @w_error = sp_estados_cca
@o_est_novigente = @w_est_novigente out,
@o_est_credito   = @w_est_credito   out,
@o_est_cancelado = @w_est_cancelado out

-- DECIMALES
exec sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out

select tc_tipo into #tipo_garantia
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng

select @w_tipos_gar = count(1) from #tipo_garantia

if @i_operacion = 'C' or @i_operacion = 'D'
begin
   select @w_tramite = op_tramite
   from   cob_cartera..ca_operacion
   where  op_banco = @i_banco
   
   select tc_tipo as tipo_sub 
   into #colateral
   from cob_custodia..cu_tipo_custodia
   where tc_tipo_superior = @w_colaterales
   
   select @w_cod_tipogar   = tc_tipo,
          @w_tipo_garantia = tc_descripcion,
          @w_tipo_superior = tc_tipo_superior
   from cob_custodia..cu_tipo_custodia, cob_custodia..cu_custodia, #colateral, cob_credito..cr_gar_propuesta
   where tc_tipo = cu_tipo
   and   tc_tipo_superior = tipo_sub
   and   cu_codigo_externo = gp_garantia
   and   gp_tramite = @w_tramite
   and   gp_est_garantia <> 'A'  --acelis ago 12 2012
   and   cu_estado <> 'A'
   
   -- BUSQUEDA DE CONCEPTOS REQ 379
   select @w_rubros = valor 
   from  cobis..cl_tabla t, cobis..cl_catalogo c
   where t.tabla  = 'ca_conceptos_rubros'
   and   c.tabla  = t.codigo
   and   c.codigo = convert(bigint, @w_cod_tipogar)  

   if @w_rubros = 'S'
   begin
      select @w_tabla_rubros = 'ca_conceptos_rubros_' + cast(@w_cod_tipogar as varchar)

      insert into #conceptos
      select codigo = c.codigo, 
             tipo_gar = @w_cod_tipogar
      from   cobis..cl_tabla t, cobis..cl_catalogo c
      where  t.tabla  = @w_tabla_rubros
      and    c.tabla  = t.codigo
   end --FIN REQ 379

   -- REQ 402
   insert into #rubros
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'DES',
          iva = 'N'
   from   cob_cartera..ca_rubro, #conceptos
   where  ru_fpago = 'L'
   and    codigo = ru_concepto
   and    ru_concepto_asociado is  null

   -- COMICION PERIODICO
   insert into #rubros
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'PER',
          iva = 'N'
   from   cob_cartera..ca_rubro, #conceptos
   where  ru_fpago = 'P'
   and    codigo = ru_concepto
   and    ru_concepto_asociado is  null
   
   -- IVA DESEMBOLSO
   insert into #rubros
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'DES',
          iva = 'S'
   from   cob_cartera..ca_rubro, #conceptos
   where  ru_fpago = 'L'
   and    codigo = ru_concepto
   and    ru_concepto_asociado is not null
   
   -- IVA PERIODICO
   insert into #rubros
   select tipo_gar,
          ru_concepto ,
          tipo_concepto = 'PER',
          iva = 'S'
   from   cob_cartera..ca_rubro, #conceptos
   where  ru_fpago = 'P'
   and    codigo = ru_concepto
   and    ru_concepto_asociado is not null
end -- C o D

-- CABECERA DE LA IMPRESION  EN TABLAS DEFINITIVAS
if @i_operacion = 'C'
begin
   select
   @w_operacionca       = op_operacion ,
   @w_cliente           = op_cliente,
   @w_toperacion_desc   = A.valor,
   @w_moneda            = op_moneda,
   @w_oficina           = op_oficina,
   @w_moneda_desc       = mo_descripcion,
   @w_monto             = op_monto,
   @w_monto_aprobado    = op_monto_aprobado,
   @w_plazo             = op_plazo,
   @w_tplazo            = op_tplazo,
   @w_tipo_amortizacion = op_tipo_amortizacion,
   @w_tdividendo        = op_tdividendo,
   @w_periodo_cap       = op_periodo_cap,
   @w_periodo_int       = op_periodo_int,
   @w_gracia            = isnull(di_gracia,0),
   @w_gracia_cap        = op_gracia_cap,
   @w_gracia_int        = op_gracia_int,
   @w_cuota             = op_cuota,
   @w_mes_gracia        = op_mes_gracia,
   @w_reajustable       = op_reajustable,
   @w_periodo_reaj      = isnull(op_periodo_reajuste,0),
   @w_fecha_fin         = convert(varchar(10),op_fecha_fin,@i_formato_fecha),
   @w_dias_anio         = op_dias_anio,
   @w_base_calculo      = op_base_calculo,
   @w_sector            = op_sector,
   @w_fecha_liq         = convert(varchar(10),op_fecha_liq,@i_formato_fecha),
   @w_dia_fijo          = op_dia_fijo,
   --@w_fecha_pri_cuot    = convert(varchar(10),op_fecha_ini,@i_formato_fecha),
   @w_recalcular_plazo  = op_recalcular_plazo,
   @w_evitar_feriados   = op_evitar_feriados,
   @w_ult_dia_habil     = op_dia_habil,
   @w_fecha_ult_pro     = op_fecha_ult_proceso,
   @w_tasa_equivalente  = op_usar_tequivalente,
   @w_op_direccion      = isnull(op_direccion,(select di_direccion from cobis..cl_direccion where di_ente = op_cliente and di_principal = 'S')),
   @w_op_codigo_externo  = op_codigo_externo,
   @w_margen_redescuento  = isnull(op_margen_redescuento,0),
   @w_dist_gracia         = op_dist_gracia,                              -- REQ 175: PEQUENA EMPRESA
   @w_tramite           = op_tramite                                     -- REQ 212: BANCA RURAL
   from ca_operacion
   inner join cobis..cl_catalogo A on op_banco    = @i_banco and op_toperacion = A.codigo
   inner join cobis..cl_moneda     on op_moneda = mo_moneda
   left outer join ca_dividendo    on op_operacion = di_operacion and di_estado = 1
   
   if @@rowcount = 0
   begin
      PRINT 'imptabla.sp error 8'
      select @w_error = 710026
      goto ERROR
   end
   
   if @w_tipo_superior = @w_cod_gar_fag
      select @w_cod_tipogar = 'FAG - ' + @w_cod_tipogar
      
   if @w_tipo_superior = @w_cod_gar_fng
      select @w_cod_tipogar = 'FNG - ' + @w_cod_tipogar
      
   if @w_op_direccion = 0
      select @w_op_direccion = 1

   select @w_tplazo   = td_descripcion
   from ca_tdividendo
   where td_tdividendo = @w_tplazo

   select @w_tdividendo= td_descripcion
   from ca_tdividendo
   where td_tdividendo = @w_tdividendo

   select @w_tasa = isnull(sum(ro_porcentaje),0),
          @w_tasa_ef_anual = isnull(sum(ro_porcentaje_efa),0),
          @w_tasa_ef_anual_aux = isnull(sum(ro_porcentaje_aux),0)
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')

   select @w_tasa_referencial = ro_referencial,
          @w_signo_spread = ro_signo,
          @w_valor_spread = round(ro_factor,4),
          @w_modalidad    = ro_fpago,
          @w_valor_referencial = ro_porcentaje_aux,
          @w_tipo_puntos = ro_tipo_puntos,
          @w_concepto_int = ro_concepto
   from   ca_rubro_op
   where  ro_operacion  =  @w_operacionca
   and    ro_tipo_rubro =  'I'
   and    ro_fpago      in ('P','A')

   if @w_tasa_referencial is not null
   begin
      select  @w_tasa_base  = vd_referencia
      from  ca_valor, ca_valor_det,ca_tasa_valor
      where va_tipo        = @w_tasa_referencial
      and   vd_tipo        = @w_tasa_referencial
      and   tv_nombre_tasa = vd_referencia
      and   vd_sector      = @w_sector

      select @w_fecha = max(vr_fecha_vig)
      from   ca_valor_referencial
      where  vr_tipo     = @w_tasa_base
      and  vr_fecha_vig <= @w_fecha_ult_pro

      select @w_secuencial_ref = max(vr_secuencial)
      from   ca_valor_referencial
      where  vr_tipo     = @w_tasa_base
      and  vr_fecha_vig  = @w_fecha

      -- TASA BASICA REFERENCIAL
      select @w_valor_base = isnull(vr_valor,0)
      from   ca_valor_referencial
      where  vr_tipo       = @w_tasa_base
      and    vr_secuencial = @w_secuencial_ref
   end

   --DEF-7705 BAC
   select @w_ced_ruc  = isnull(en_ced_ruc,p_pasaporte),
          @w_nombre   = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,60))
   from   cobis..cl_ente
   where  en_ente = @w_cliente
   
   select @w_telefono  = isnull(te_valor,'')
   from   cobis..cl_telefono
   where  te_ente      = @w_cliente
   and    te_direccion = @w_op_direccion
   
   select @w_direccion = isnull(di_descripcion,'')   
   from   cobis..cl_direccion 
   where  di_ente      = @w_cliente
   and    di_direccion = @w_op_direccion

   if ltrim(rtrim(@w_tipo_amortizacion)) = 'ALEMANA'
      select @w_tipo_amortizacion = 'CAPITAL FIJO'
   else
   begin
      if ltrim(rtrim(@w_tipo_amortizacion)) = 'FRANCESA'
         select @w_tipo_amortizacion = 'CUOTA FIJA'
      else
         if @w_tipo_amortizacion != @w_tflexible
            select @w_tipo_amortizacion = 'PERSONALIZADA'
   end

   select @w_nom_oficina = of_nombre
   from cobis..cl_oficina
   where of_oficina = @w_oficina
   set transaction isolation level read uncommitted
   
   select @w_fecha_pri_cuot = convert(varchar(10),di_fecha_ven,@i_formato_fecha)
   from ca_dividendo  
   where di_operacion = @w_operacionca
   and di_dividendo = 1

   -- LCM - 293: CONSULTA LA TABLA DE RECONOCIMIENTO PARA VALIDAR SI LA OBLIGACION TIENE RECONOCIMIENTO
   select @w_vlr_x_amort = 0

   select @w_vlr_x_amort = pr_vlr - pr_vlr_amort
   from ca_pago_recono with (nolock)
   where pr_operacion = @w_operacionca
   and   pr_estado    = 'A'

   -- LCM - 366: OBTIENE TASAS ASOCIADAS A LOS SEGUROS DEL CLIENTE y VALOR TOTAL ORIGINAL
   select @w_tasa_seg_ind      = 0,
          @w_tasa_seg_1_perd   = 0,
          @w_tasa_seg_exequias = 0,
          @w_tasa_seg_danos    = 0,
          @w_valor_total_seg   = convert(float,0)

   select codigo,codigo_sib
   into #seguros
   from cob_credito..cr_corresp_sib
   where tabla = 'T155'

   select @w_tasa_seg_ind      = isnull(ro_porcentaje,0) from cob_cartera..ca_rubro_op, #seguros where ro_operacion = @w_operacionca and   ro_concepto  = codigo_sib and   codigo = 1
   select @w_tasa_seg_1_perd   = isnull(ro_porcentaje,0) from cob_cartera..ca_rubro_op, #seguros where ro_operacion = @w_operacionca and   ro_concepto  = codigo_sib and   codigo = 2
   select @w_tasa_seg_exequias = isnull(ro_porcentaje,0) from cob_cartera..ca_rubro_op, #seguros where ro_operacion = @w_operacionca and   ro_concepto  = codigo_sib and   codigo = 3
   select @w_tasa_seg_danos    = isnull(ro_porcentaje,0) from cob_cartera..ca_rubro_op, #seguros where ro_operacion = @w_operacionca and   ro_concepto  = codigo_sib and   codigo = 4
   
   select @w_valor_total_seg = isnull(sum(isnull(ps_valor_mensual,0) * isnull(datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura),0)),0)
   from cob_credito..cr_seguros_tramite with (nolock),
        cob_credito..cr_asegurados      with (nolock),
        cob_credito..cr_plan_seguros_vs
   where st_tramite           = @w_tramite
   and   st_secuencial_seguro = as_secuencial_seguro
   and   as_plan              = ps_codigo_plan
   and   st_tipo_seguro       = ps_tipo_seguro
   and   ps_estado            = 'V'      
   and   as_tipo_aseg         = (case when ps_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)                                            

   select @w_alianza    = null,
          @w_desalianza = null
   
   if @w_operacionca is not null 
   begin 
      -- SI EL TRAMITE TIENE OPERAICON EN CARTERA VERIFICA QUE EXISTA.
      select @w_alianza    = al_alianza,
             @w_desalianza = isnull((al_nemonico + ' - ' + al_nom_alianza), '  ')
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
   end
   ELSE
   begin 
      select @w_alianza = al_alianza,
             @w_desalianza = isnull((al_nemonico + ' - ' + al_nom_alianza), '  ')
      from cobis..cl_alianza_cliente with (nolock),
            cobis..cl_alianza         with (nolock)
      where ac_ente    = @w_cliente
      and   ac_alianza = al_alianza
      and   al_estado  = 'V'
      and   ac_estado  = 'V'
   end   
   
   -- 433 - OBTIENE DIVIDENDO, VALOR A CAPITAL DE PAGO POR ABONO EXTRAORDINARIO
   -- OBTIENE DIVIDENDO VIGENTE
   select @w_div_vig = 0,
          @w_div_cap = 0,
          @w_cuota_cap = 0,
          @w_sld_cap_div= 0
          
   select @w_div_vig = di_dividendo
   from cob_cartera..ca_dividendo
   where di_operacion = @w_operacionca
   and   di_estado = 1
   
   -- OBTIENE PRIMER DIVIDENDO CON COBRO DE CAPITAL 
   select @w_div_cap = min(di_dividendo)
   from cob_cartera..ca_dividendo
   where di_operacion = @w_operacionca
   and   di_estado <> 3
   and   di_de_capital = 'S'
   
   -- OBTIENE SALDO A CAPITAL
   if exists(select 1 from cob_cartera..ca_abono ,cob_cartera..ca_det_trn
             where dtr_operacion     = @w_operacionca
             and   dtr_concepto      = 'CAP'
             and   ab_operacion      = dtr_operacion
             and   ab_tipo_reduccion in ('C','T')
             and   ab_estado         = 'A'
             ---and   dtr_dividendo     = @w_div_cap  INC. 117124 partiendo de la version 62
             and   dtr_secuencial    = ab_secuencial_pag)
   begin
      select @w_cuota_cap = sum(am_cuota) from cob_cartera..ca_amortizacion 
      where am_operacion = @w_operacionca
      and   am_concepto = 'CAP'
      and   am_dividendo = @w_div_vig

      select @w_sld_cap_div = sum(am_cuota - am_pagado) from cob_cartera..ca_amortizacion 
      where am_operacion = @w_operacionca
      and   am_dividendo = @w_div_vig
      
      -- VALIDA SI LA OPERACION TIENE RECONOCIMIENTO
      select @w_tiene_reco      = 'N',
             @w_vlr_calc_fijo   = 0,
             @w_div_pend        = 0,
             @w_monto_reconocer = 0

      select
      @w_vlr_calc_fijo = pr_vlr_calc_fijo,
      @w_div_pend      = pr_div_pend
      from cob_cartera..ca_pago_recono
      where pr_banco = @i_banco
      and   pr_estado    = 'A'

      if @@rowcount <> 0
         select @w_tiene_reco = 'S'
         
      if @w_tiene_reco = 'S' and @w_div_pend > 0
      begin
      
         -- SUMA EL VALOR FIJO DE RECONOCIMIENTO AL VALOR DE LA CUOTA VIGENTE
         select @w_monto_reconocer = round(isnull(@w_vlr_calc_fijo / @w_div_pend, 0),0)
         
         select @w_sld_cap_div = @w_sld_cap_div + @w_monto_reconocer
      end
   end

   select
   @w_cliente,                                           SUBSTRING(@w_nombre,1,100) ,           SUBSTRING(@w_ced_ruc,1,15),
   SUBSTRING(@w_direccion,1,100),                        SUBSTRING(@w_telefono,1,15),           SUBSTRING(@w_toperacion_desc,1,60),
   round(convert(float,@w_monto),@w_num_dec),            SUBSTRING(@w_moneda_desc,1,20),        @w_plazo,
   SUBSTRING(@w_tplazo,1,40),                            SUBSTRING(@w_tipo_amortizacion,1,40),  SUBSTRING(@w_tdividendo,1,40),
   @w_tasa,                                              @w_periodo_cap,                        @w_periodo_int,
   @w_mes_gracia,                                        @w_gracia,                             @w_gracia_cap,
   @w_gracia_int,                                        @w_tasa_ef_anual_aux,                  SUBSTRING(@w_fecha_fin,1,12),
   @w_dias_anio,                                         @w_base_calculo,                       @w_tasa_base,
   @w_valor_base,                                        @w_valor_spread,                       @w_signo_spread,
   @w_modalidad,                                         @w_fecha_liq,                          @w_dia_fijo,
   @w_fecha_pri_cuot,                                    @w_recalcular_plazo,                   @w_evitar_feriados,
   @w_ult_dia_habil,                                     @w_tasa_equivalente,                   @w_reajustable,
   @w_tipo_puntos,                                       @w_valor_base,                         convert(varchar(10),@w_fecha_ult_pro,@i_formato_fecha),
   @w_moneda,                                            SUBSTRING(@w_nom_oficina,1,64),        @w_op_codigo_externo,
   @w_margen_redescuento,                                @w_dist_gracia,                        @w_cod_tipogar,
   @w_tipo_garantia,                                     @w_vlr_x_amort,                        @w_tasa_seg_ind,
   @w_tasa_seg_1_perd,                                   @w_tasa_seg_exequias,                  @w_tasa_seg_danos,
   round(convert(float, @w_valor_total_seg),@w_num_dec), @w_alianza,                            @w_desalianza,
   isnull(@w_div_vig,0),                                 isnull(@w_cuota_cap,0),                isnull(@w_sld_cap_div,0)
   
   -- Si la operacion Tiene FNG pero no calculo valores
            
   select @w_gar_op = cu_tipo from cob_credito..cr_gar_propuesta, cob_custodia..cu_custodia , cob_cartera..ca_operacion
   where gp_garantia = cu_codigo_externo and   gp_tramite  = op_tramite                   
   and   cu_tipo in (select tc_tipo from #tipo_garantia)
   and   op_operacion = @w_operacionca
   and   cu_estado <> 'A' and   gp_est_garantia  <> 'A'

   select @w_plazo_am = max(di_dividendo)
   from ca_dividendo
   where di_operacion = @w_operacionca
   
   if @w_tplazo <> 'M'                                                                                                                                                                                                   
   begin
	  select @w_td_factor = td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @w_tplazo
      select @w_pl_meses = @w_plazo_am * @w_td_factor / 30   
      --select @w_pl_meses = @w_plazo_am * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @w_tplazo) / 30   
   end
   else  
      select @w_pl_meses = @w_plazo_am     
   
   if exists ( select 1 from #tipo_garantia                           
               where tc_tipo  = @w_gar_op
             )           
             and  @w_pl_meses > 12
   begin
      -- validar si el plazo es multiplo de 12
      select @w_cobros = (@w_pl_meses / 12.00)
      if abs(@w_cobros - (@w_pl_meses / 12)) = 0
         select @w_cobros = @w_cobros - 1
             
      select @w_cobros_amortiza = 0 --REQ379

      select @w_cobros_amortiza = count(1)
      from cob_cartera..ca_amortizacion , 
           cob_cartera..ca_operacion,
           cob_cartera..ca_rubro_op  --REQ379
      where am_operacion = op_operacion     
      and   op_operacion = @w_operacionca
      and   am_concepto  = @w_parametro_fng 
      and   am_cuota   > 0
      and   am_concepto    = ro_concepto
      and   am_operacion   = ro_operacion--REQ379
      and   ro_porcentaje <> 0

      if (@w_cobros - @w_cobros_amortiza) > 0.99 and @w_cobros_amortiza <> 0 
      begin
         print 'La tabla de Amortizacion no Genero el rubro FNG Anual correctamente, Por favor revisar' + 'Tipos Gar ' + cast(@w_tipos_gar as varchar)
         select @w_error = 2103013
         goto   ERROR
      end    
   end
end -- C

-- DETALLE DE LA TABLA DE AMORTIZACION EN TABLAS DEFINITIVAS
if @i_operacion = 'D'
begin
   -- CHEQUEO QUE EXISTA LA OPERACION
   delete tmp_interes_amortiza_tmp with (rowlock) where spid = @@spid 
   
   select @w_operacionca    = op_operacion,
          @w_gracia_int     = op_gracia_int,              -- REQ 175: PEQUENA EMPRESA
          @w_fecha_ult_pro  = op_fecha_ult_proceso,       -- REQ 175: PEQUENA EMPRESA
          @w_dist_gracia    = op_dist_gracia,             -- REQ 175: PEQUENA EMPRESA
          @w_estado         = op_estado,                  -- REQ 175: PEQUENA EMPRESA
          @w_monto          = op_monto,                   -- REQ 175: PEQUENA EMPRESA
          @w_periodo_int    = op_periodo_int,             -- REQ 175: PEQUENA EMPRESA
          @w_tipo_amortizacion = op_tipo_amortizacion    -- REQ 392
   from   ca_operacion
   where  op_banco = @i_banco
   
   if @@rowcount = 0
   begin
      PRINT 'imptabla.sp error 9'
      select @w_error = 710026
      goto ERROR
   end

   -- INI - REQ 175: PEQUENA EMPRESA
   -- DETERMINACION DE LA FECHA EN LA QUE TERMINA LA GRACIA DE INTER+S
   if @w_gracia_int > 0 and @w_dist_gracia = 'C'
   and @w_tipo_amortizacion != @w_tflexible -- REQ.392 PARA LA TABLA DE AMORTIZACION FLEXIBLE NO APLICA EL RECALCULO DE LA TABLA
   begin
      -- AVANCE DE LA OPERACION POSTERIOR A LAS CAPITALIZACIONES
      select @w_ffin_gracia = dateadd(dd, 1, di_fecha_ven)
      from   ca_dividendo
      where  di_operacion = @w_operacionca
      and    di_dividendo = @w_gracia_int
      
      if @w_fecha_ult_pro < @w_ffin_gracia
      begin   
         begin tran
         
         -- REGENERACION DE LA TABLA DE AMORTIZACION CON LA CAPITALIZACION
         select 
         @w_deshacer_tran = 'S',
         @w_divini_reg    = @w_gracia_int + 1
         
         -- LIMPIEZA DE LAS TABLAS TEMPORALES
         exec @w_error = sp_borrar_tmp_int
         @i_operacionca = @w_operacionca
         
         if @w_error <> 0
            goto ERROR

         -- CONDICIONES INICIALES DE LA REGENERACION
         select @w_saldo_cap = sum(am_cuota - am_pagado)
         from ca_amortizacion, ca_rubro_op
         where am_operacion  = @w_operacionca
         and   am_estado    <> @w_est_cancelado
         and   ro_operacion  = am_operacion
         and   ro_concepto   = am_concepto 
         and   ro_tipo_rubro = 'C'
         
         select @w_capitalizar = sum(am_cuota + am_gracia - am_pagado)
         from ca_amortizacion
         where am_operacion  = @w_operacionca
         and   am_dividendo <= @w_gracia_int
         and   am_concepto   = @w_concepto_int

         select @w_saldo_cap = @w_saldo_cap + @w_capitalizar
         
         select @w_num_dividendos = count(1)
         from   ca_dividendo
         where  di_operacion  = @w_operacionca
         and    di_dividendo >= @w_divini_reg
         
         select @w_plazo_operacion = @w_periodo_int * @w_num_dividendos
         
         select 
         @w_di_fecha_ini = di_fecha_ini,
         @w_di_fecha_ven = di_fecha_ven
         from   ca_dividendo
         where  di_operacion = @w_operacionca
         and    di_dividendo = @w_divini_reg
         
         select @w_di_de_capital = min(di_dividendo)
         from   ca_dividendo
         where  di_operacion  = @w_operacionca
         and    di_dividendo >= @w_divini_reg
         and    di_de_capital = 'S'
         
         select @w_cuota_desde_cap = @w_di_de_capital - @w_divini_reg + 1
         
         -- PASO DE LA OPERACION A TEMPORALES
         exec @w_error = sp_pasotmp
         @s_user            = @s_user,
         @s_term            = @s_term,
         @i_banco           = @i_banco,
         @i_operacionca     = 'S',
         @i_dividendo       = 'N',
         @i_amortizacion    = 'N',
         @i_cuota_adicional = 'S',
         @i_rubro_op        = 'S',
         @i_valores         = 'S', 
         @i_acciones        = 'N'  
         
         if @w_error <> 0
            goto ERROR
         
         update ca_operacion_tmp set 
         opt_cuota          = 0,
         opt_plazo          = @w_plazo_operacion,
         opt_fecha_ini      = @w_di_fecha_ini,
         opt_monto          = @w_saldo_cap
         where opt_operacion = @w_operacionca
         
         if @@error <> 0
         begin
            select @w_error = 710002
            goto ERROR
         end
         
         update ca_rubro_op_tmp set
         rot_valor        = @w_saldo_cap,
         rot_base_calculo = @w_capitalizar
         where rot_operacion  = @w_operacionca
         and   rot_concepto   = @w_concepto_cap
         
         if @@error <> 0
         begin
            select @w_error = 710002
            goto ERROR
         end
         
         exec @w_error = sp_gentabla
         @i_operacionca     = @w_operacionca,
         @i_tabla_nueva     = 'S',
         @i_accion          = 'S',
         @i_cuota_accion    = @w_divini_reg,
         @i_cuota_desde_cap = @w_cuota_desde_cap,
         @o_fecha_fin       = @w_fecha_fin out
         
         if @w_error <> 0
            goto ERROR
         
         update ca_amortizacion set
         am_cuota     = amt_cuota,
         am_acumulado = amt_acumulado
         from ca_amortizacion_tmp, ca_rubro_op_tmp
         where amt_operacion   = @w_operacionca
         and   am_operacion    = amt_operacion
         and   am_dividendo    = amt_dividendo + @w_divini_reg - 1
         and   am_concepto     = amt_concepto
         and   am_estado      <> 3
         and   rot_operacion   = amt_operacion
         and   rot_concepto    = amt_concepto
         and   rot_tipo_rubro  = 'C'
         
         if @@error <> 0
         begin
            select @w_error = 705050
            goto ERROR
         end
         
         update ca_amortizacion set
         am_cuota  = amt_cuota,
         am_gracia = amt_gracia
         from ca_amortizacion_tmp, ca_rubro_op_tmp
         where amt_operacion   = @w_operacionca
         and   am_operacion    = amt_operacion
         and   am_dividendo    = amt_dividendo + @w_divini_reg - 1
         and   am_concepto     = amt_concepto
         and   am_estado      <> 3
         and   rot_operacion   = amt_operacion
         and   rot_concepto    = amt_concepto
         and   rot_tipo_rubro <> 'C'
         
         if @@error <> 0
         begin
            select @w_error = 705050
            goto ERROR
         end
            
         select @w_divs_reg = count(1)
         from ca_dividendo_tmp
         where dit_operacion = @w_operacionca
         
         -- SI HAY MAS DIVIDENDOS EN LA TEMPORAL GENRADA QUE EN LA ORIGINAL SE INSERTAN ESTOS NUEVOS DIVIDENDO
         if @w_divs_reg > @w_num_dividendos
         begin      
            -- ACTUALIZACION DE LAS NUEVAS CUOTAS TANTO DE CAPITAL COMO DE INTERES
            insert into ca_dividendo(
            di_operacion,        di_dividendo,           
            di_fecha_ini,        di_fecha_ven,           di_de_capital,
            di_de_interes,       di_gracia,              di_gracia_disp,
            di_estado,           di_dias_cuota,          di_prorroga,
            di_intento,          di_fecha_can)
            select 
            dit_operacion,       dit_dividendo + @w_divini_reg - 1,
            dit_fecha_ini,       dit_fecha_ven,          dit_de_capital,         
            dit_de_interes,      dit_gracia,             dit_gracia_disp,
            dit_estado,          dit_dias_cuota,         dit_prorroga,
            dit_intento,         dit_fecha_can
            from   ca_dividendo_tmp
            where  dit_operacion = @w_operacionca
            and    dit_dividendo > @w_num_dividendos
            
            if @@error <> 0 
            begin
               select @w_error = 710001
               goto ERROR
            end
            
            insert into ca_amortizacion(
            am_operacion,        am_dividendo,           
            am_concepto,         am_estado,              am_periodo,             
            am_cuota,            am_gracia,              am_pagado,              
            am_acumulado,        am_secuencia)
            select 
            amt_operacion,       amt_dividendo + @w_divini_reg - 1,
            amt_concepto,        amt_estado,             amt_periodo,            
            amt_cuota,           amt_gracia,             amt_pagado,             
            amt_acumulado,       amt_secuencia
            from   ca_amortizacion_tmp
            where  amt_operacion = @w_operacionca
            and    amt_dividendo > @w_num_dividendos
            
            if @@error <> 0
            begin
               select @w_error = 710001
               goto ERROR
            end
         
         end -- FIN DE HAY MAS DIVIDENDO PARA INSERTAR A LA TABLA DEFINITIVA
         
         -- ELIMINACION DE LOS DIVIDENDOS SI EL PLAZO ES MENOR
         if @w_divs_reg < @w_num_dividendos
         begin
            delete ca_dividendo
            where  di_operacion = @w_operacionca
            and    di_dividendo > @w_divs_reg + @w_divini_reg - 1
            
            if @@error <> 0
            begin
               select @w_error = 710003
               goto ERROR
            end
            
            delete ca_cuota_adicional
            where  ca_operacion = @w_operacionca
            and    ca_dividendo > @w_divs_reg + @w_divini_reg - 1
            
            if @@error <> 0
            begin
               select @w_error = 710003
               goto ERROR
            end
            
            delete ca_amortizacion
            where  am_operacion = @w_operacionca
            and    am_dividendo > @w_divs_reg + @w_divini_reg - 1
            
            if @@error <> 0
            begin
               select @w_error = 710003
               goto ERROR
            end
            
         end --FIN NUMERO DE CUOTAS > 1
         
         -- ELIMINACION DE LAS TABLAS TEMPORALES
         exec @w_error = sp_borrar_tmp_int
         @i_operacionca = @w_operacionca
         
         if @w_error <> 0
            goto ERROR

         -- PARA PRESENTACION DE CUOTA CERO EN INTERESES
         update ca_amortizacion
         set am_gracia = am_pagado - am_cuota
         where am_operacion  = @w_operacionca
         and   am_dividendo <= @w_gracia_int
         and   am_concepto   = @w_concepto_int
         
         if @@error <> 0
         begin
            select @w_error = 710002
            goto ERROR
         end  
      end
   end
   -- FIN - REQ 175: PEQUENA EMPRESA

   if exists (select ro_operacion from ca_rubro_op
              where ro_operacion = @w_operacionca
              and ro_tipo_rubro  = 'I' )
   begin
      declare  
         cursor_operacion cursor
         for select am_dividendo,
                    convert(float, sum(am_cuota + am_gracia)),
                    am_concepto,
                    isnull(ro_porcentaje, 0)
             from   ca_amortizacion, ca_rubro_op
             where  am_operacion = ro_operacion
             and    am_concepto    = ro_concepto
             and    ro_operacion   = @w_operacionca
             and    ro_tipo_rubro  = 'I'
             and    am_dividendo   < @i_dividendo
             group  by am_dividendo,am_concepto, ro_porcentaje
             order  by am_dividendo desc
   end
   else
   begin
      declare
         cursor_operacion cursor
         for select am_dividendo,
                    0,
                    am_concepto,
                    isnull(ro_porcentaje, 0)  --Sera de CAP
             from   ca_amortizacion,ca_rubro_op
             where  am_operacion = ro_operacion
             and    am_concepto    = ro_concepto
             and    ro_operacion   = @w_operacionca
             and    ro_tipo_rubro  = 'C'
             and    am_dividendo   < @i_dividendo
             group  by am_dividendo,am_concepto, ro_porcentaje
             order by am_dividendo desc
   end

   open cursor_operacion
   fetch cursor_operacion
   into @w_tcuota, @w_tmonto, @w_tconcepto, @w_ttasa

   select @w_ult_tasa = @w_ttasa

   while @@fetch_status = 0
   begin
      if @@fetch_status = -1
      begin
         select @w_error = 70899
         goto  ERROR
      end

      select @w_tporcentaje = ts_porcentaje
      from   ca_amortizacion, ca_tasas
      where  ts_operacion = am_operacion
      and    ts_dividendo = am_dividendo
      and    ts_concepto  = am_concepto
      and    ts_operacion = @w_operacionca
      and    ts_dividendo = @w_tcuota
      and    ts_concepto  = @w_tconcepto

      if @@rowcount > 0
      begin
         insert into tmp_interes_amortiza_tmp
               (cuota,     monto,      concepto,      tasa,             spid)
         values(@w_tcuota, @w_tmonto,  @w_tconcepto,  @w_tporcentaje,   @@spid)

         select @w_ult_tasa = @w_tporcentaje
      end
      else
      begin
         if @w_ttasa = 0
            select @w_ttasa = @w_ult_tasa

         insert into tmp_interes_amortiza_tmp
            (cuota,     monto,      concepto,      tasa,       spid)
         values(@w_tcuota, @w_tmonto,  @w_tconcepto,  @w_ttasa,   @@spid)
      end

      fetch cursor_operacion
      into @w_tcuota, @w_tmonto, @w_tconcepto, @w_ttasa
   end

   close cursor_operacion
   deallocate cursor_operacion

   /**********************/

   select @w_tamanio = 7  ----EPBoc01012001

   -- TABLA DE AMORTIZACION

   set rowcount @w_tamanio   

   -- MAPEA CUOTA: Numero de cuota, y Valor total de la cuota
   if @w_mon_nacional = @w_moneda
   begin
      select am_dividendo, sum(am_cuota + am_gracia)
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion      = @w_operacionca
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    ro_tipo_rubro = 'C'
      and    am_dividendo  < @i_dividendo
      group  by am_dividendo
      order  by am_dividendo desc
  end
  else
  begin  --para que se genere con cuatro decimales.
      select am_dividendo,
             convert(float, sum(am_cuota + am_gracia))
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion      = @w_operacionca
      and    am_operacion  = ro_operacion
      and    am_concepto   = ro_concepto
      and    ro_tipo_rubro = 'C'
      and    am_dividendo  < @i_dividendo
      group  by am_dividendo
      order  by am_dividendo desc
   end
   
   set rowcount @w_tamanio
   
   -- MAPEA INTERES: Numero de cuota, Valor, Concepto, Tasa
   select cuota,
          round(convert(float,monto), @w_num_dec),
          concepto,
          tasa
   from   tmp_interes_amortiza_tmp
   where  spid = @@spid
   order  by cuota desc, concepto, tasa

   -- OTROS
   set rowcount @w_tamanio   

   -- MAPEA OTROS: Numero de cuota, Valor
   select am_dividendo,
          round(convert(float, sum(am_cuota + am_gracia)), @w_num_dec)
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I', 'F')
   and am_dividendo   < @i_dividendo
   and ro_concepto not in (@w_pmipymes, @w_ivamipymes, @w_parametro_fng, @w_parametro_fag, @w_parametro_usaid, @w_ivafng, @w_ivafag, @w_ivausaid, @w_segdeven, 'IMO',@w_parametro_fgu,@w_parametro_fgu_iva, @w_segdeem) --Req 406 LC 28/ENE/2014 se agrega  @w_segdeem)
   and ro_concepto not in (select rre_concepto from #rubros where tipo_concepto = 'PER')
   and ro_concepto not in (select codigo_sib from cob_credito..cr_corresp_sib where tabla = 'T156')   
   group by am_dividendo
   order by am_dividendo desc

   
   set rowcount @w_tamanio  

   -- MAPEA PAGOS: Numero de cuota, Valor pagado
   select  am_dividendo,
           round(convert(float, sum(am_pagado)), @w_num_dec)
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and am_dividendo   < @i_dividendo
   and ro_tipo_rubro = 'C'
   group by am_dividendo
   order by am_dividendo desc

   set rowcount @w_tamanio   

   -- MAPEA FECHAS y ESTADO: Fecha como texto y formateada, Descripcion del estado, dias de la cuota
   select convert(varchar(10), di_fecha_ven, @i_formato_fecha),
          es_descripcion,
          di_dias_cuota
   from   ca_dividendo, ca_estado
   where  di_operacion     = @w_operacionca
   and    di_estado    = es_codigo
   and    di_dividendo < @i_dividendo
   order by di_dividendo desc
   
   set rowcount @w_tamanio   
   
   -- MAPEA MIPYME: Numero de cuota, y valor
   select am_dividendo,
          round(convert(float, sum(am_cuota + am_gracia)), @w_num_dec)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion = @w_operacionca
   and    am_operacion   = ro_operacion
   and    am_concepto    = ro_concepto
   and    ro_tipo_rubro  not in ('C', 'I', 'F')
   and    am_dividendo   < @i_dividendo
   and    ro_concepto    = @w_pmipymes
   group  by am_dividendo
   order  by am_dividendo desc
   
   set rowcount @w_tamanio   
   
   -- MAPEA IVA MIPYME: Numero de cuota, y valor
   select am_dividendo,
          round(convert(float, sum(am_cuota + am_gracia)), @w_num_dec)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion   = @w_operacionca
   and    am_operacion   = ro_operacion
   and    am_concepto    = ro_concepto
   and    ro_tipo_rubro  not in ('C', 'I', 'F')
   and    am_dividendo   < @i_dividendo
   and    ro_concepto    = @w_ivamipymes
   group  by am_dividendo
   order  by am_dividendo desc

   set rowcount @w_tamanio         
   
   -- MAPEA FNG ANUAL: Numero de cuota, y valor
   select am_dividendo,
          round(convert(float, sum(am_cuota + am_gracia)), @w_num_dec)
   from   ca_amortizacion,ca_rubro_op
   where  ro_operacion = @w_operacionca
   and    am_operacion   = ro_operacion
   and    am_concepto    = ro_concepto
   and    ro_tipo_rubro  not in ('C', 'I', 'F')
   and    am_dividendo   < @i_dividendo
   and    am_cuota > 0
   and    (ro_concepto    in (@w_parametro_fng, @w_parametro_fag, @w_parametro_usaid, @w_parametro_fgu)
           or  ro_concepto    in (select rre_concepto from #rubros where tipo_concepto = 'PER' and iva = 'N'))
   group  by am_dividendo
   order  by am_dividendo desc
   
   set rowcount @w_tamanio   

   -- MAPEA IVA FNG ANUAL: Numero de cuota, y valor
   select am_dividendo,
          round(convert(float, sum(am_cuota + am_gracia)), @w_num_dec)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion = @w_operacionca
   and    am_operacion   = ro_operacion
   and    am_concepto    = ro_concepto
   and    ro_tipo_rubro  not in ('C', 'I', 'F')
   and    am_dividendo   < @i_dividendo
   and    am_cuota  > 0
   and   (ro_concepto  in (@w_ivafng, @w_ivafag, @w_ivausaid, @w_parametro_fgu_iva)
          or  ro_concepto  in (select rre_concepto from #rubros where tipo_concepto = 'PER' and iva = 'S'))
   group  by am_dividendo
   order  by am_dividendo desc
      
   set rowcount @w_tamanio
   
   -- MAPEA SEGURO DEUDORES VENCIDO: Numero de cuota, y valor
   select am_dividendo,
          round(convert(float, sum(am_cuota + am_gracia)), @w_num_dec)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion = @w_operacionca
   and    am_operacion   = ro_operacion
   and    am_concepto    = ro_concepto
   and    ro_tipo_rubro  not in ('C', 'I', 'F')
   and    am_dividendo   < @i_dividendo
   and    ro_concepto    in (@w_segdeven,@w_segdeem) --Req 406 LC 28/ENE/2014
   group  by am_dividendo
   order  by am_dividendo desc
   
   
   set rowcount @w_tamanio   
   
   -- MAPEA MORA: Numero de cuota, y valor
   select am_dividendo,
          round(convert(float, sum(am_cuota + am_gracia)), @w_num_dec)
   from   ca_amortizacion,ca_rubro_op
   where  ro_operacion = @w_operacionca
   and    am_operacion   = ro_operacion
   and    am_concepto    = ro_concepto
   and    ro_tipo_rubro  not in ('C', 'I', 'F')
   and    am_dividendo   < @i_dividendo
   and    ro_concepto    = 'IMO'
   group  by am_dividendo
   order  by am_dividendo desc

   -- CONSULTA CAPITAL E INTERES DE LOS SEGUROS ASOCIADOS AL TRAMITE Req. 366
   -- valida que existan seguros asociados
   
   select @w_tramite_seg   = op_tramite,
          @w_operacion_seg = op_operacion
   from   ca_operacion
   where  op_banco = @i_banco
   
   select @w_nro_tramites = count(st_tramite)
   from   cob_credito..cr_seguros_tramite
   where  st_tramite = @w_tramite_seg  
   
   -- MAPEA FINANCIACION DE MICRO SEGUROS: Numero de cuota, Valor de CAPITAL, y Valor de Interes
   if @w_nro_tramites > 0
   begin
      set rowcount @w_tamanio  
      
      select sed_dividendo,
             round(convert(float, sum(sed_cuota_cap)), @w_num_dec),
             round(convert(float, sum(sed_cuota_int)), @w_num_dec),              
             round(convert(float, sum(sed_cuota_mora)),@w_num_dec)  -- CCA 409     	  
      from  ca_seguros_det, ca_seguros
      where se_sec_seguro = sed_sec_seguro
      and   se_tramite = @w_tramite_seg   
      and   sed_dividendo < @i_dividendo
      and   se_estado <> 'C'
      group by sed_dividendo
      order by sed_dividendo desc
   end
   ELSE -- NO TIENE, ENTONCES MAPEAR EN FALSO PARA QUE FRONTEND NO TENGA LIOS
   begin
      set rowcount @w_tamanio
      
      select di_dividendo,
             convert(float, 0),
             convert(float, 0),              
             convert(float, 0) -- CCA 409
      from   ca_dividendo
      where  di_operacion = @w_operacion_seg 
      and    di_dividendo < @i_dividendo           
      order  by di_dividendo desc
   end  -- Fin Req. 366

   -- CAPITALIZADO
   if @w_gracia_int > 0 and @w_dist_gracia = 'C'
   begin
      set rowcount 0
      
      select dtr_dividendo  as dividendo,
             sum(dtr_monto) as monto
      into   #capitalizado
      from   ca_transaccion, ca_det_trn
      where  tr_operacion   = @w_operacionca
      and    tr_tran        = 'CRC'
      and    tr_estado     <> 'RV'
      and    dtr_operacion  = tr_operacion
      and    dtr_secuencial = tr_secuencial
      and    dtr_concepto   = @w_concepto_int
      group  by dtr_dividendo
      
      set rowcount @w_tamanio   
      
      -- MAPEA CAPITALIZACIONES: Numero de cuota, y monto
      select am_dividendo,
             case
               when monto is null then sum(am_cuota - am_pagado)
               else monto
             end
      from   ca_amortizacion left outer join #capitalizado on am_dividendo = dividendo
      where  am_operacion  = @w_operacionca
      and    am_dividendo  < @i_dividendo
      and    am_dividendo <= @w_gracia_int
      and    am_concepto   = @w_concepto_int
      group  by am_dividendo, monto
      order  by am_dividendo desc
      
      if @w_deshacer_tran = 'S'
         rollback tran   
   end
   ELSE -- NO TIENE, ENTONCES MAPEAR EN FALSO PARA QUE FRONTEND NO TENGA LIOS
   begin
      set rowcount @w_tamanio
      
      select di_dividendo,
             convert(float, 0)
      from   ca_dividendo
      where  di_operacion = @w_operacion_seg 
      and    di_dividendo < @i_dividendo           
      order  by di_dividendo desc
   end

   -- MAPEA DISPONIBLES DE TABLA FLEXIBLE: Numero de cuota, y monto disponible
   if @w_tipo_amortizacion = @w_tflexible
   begin
      if not exists(select 1
                    from   cob_credito..cr_disponibles_tramite
                    where  dt_operacion_cca = @w_operacionca)
      begin
         PRINT 'imptabla.sp error, prestamo con tabla flexible pero sin datos de disponibles'
         select @w_error = 710026
         goto ERROR
      end

      set rowcount 0

      exec @w_error = sp_imprimir_inttras
           @i_operacion = @w_operacionca,
           @i_user      = @s_user

      if @w_error != 0
         goto ERROR

      set rowcount @w_tamanio

      select tfi_dividendo, tfi_vr_disponible,
             tfi_inttras_cta
      from   cob_cartera..tmp_tflexible_inttras
      where  tfi_operacion = @w_operacionca
      and    tfi_dividendo < @i_dividendo
      and    tfi_user      = @s_user
      order  by tfi_dividendo desc

      set rowcount @w_tamanio
   end
   ELSE -- NO TIENE, ENTONCES MAPEAR EN FALSO PARA QUE FRONTEND NO TENGA LIOS
   begin
      set rowcount @w_tamanio
      
      select di_dividendo,
             convert(float, 0),
             convert(float, 0)
      from   ca_dividendo
      where  di_operacion = @w_operacion_seg 
      and    di_dividendo < @i_dividendo           
      order  by di_dividendo desc
   end
end -- D

-- CABECERA DE LA IMPRESION  EN TABLAS TEMPORALES
if @i_operacion = 'T'
begin
   select @w_operacionca       = opt_operacion ,
          @w_cliente           = opt_cliente,
          @w_toperacion_desc   = A.valor,
          @w_moneda            = opt_moneda,
          @w_moneda_desc       = mo_descripcion,
          @w_monto             = opt_monto,
          @w_plazo             = opt_plazo,
          @w_tplazo            = opt_tplazo,
          @w_tipo_amortizacion = opt_tipo_amortizacion,
          @w_tdividendo        = opt_tdividendo,
          @w_periodo_cap       = opt_periodo_cap,
          @w_periodo_int       = opt_periodo_int,
          @w_gracia            = isnull(dit_gracia,0),
          @w_gracia_cap        = opt_gracia_cap,
          @w_gracia_int        = opt_gracia_int,
          @w_cuota             = opt_cuota,
          @w_mes_gracia        = opt_mes_gracia,
          @w_reajustable       = opt_reajustable,
          @w_periodo_reaj      = isnull(opt_periodo_reajuste,0),
          @w_fecha_fin         = convert(varchar(10),opt_fecha_fin,@i_formato_fecha),
          @w_dias_anio         = opt_dias_anio,
          @w_base_calculo      = opt_base_calculo,
          @w_sector            = opt_sector,
          @w_fecha_liq         = convert(varchar(10),opt_fecha_liq,@i_formato_fecha),
          @w_dia_fijo          = opt_dia_fijo,
          --@w_fecha_pri_cuot    = convert(varchar(10),opt_fecha_ini,@i_formato_fecha),
          @w_recalcular_plazo  = opt_recalcular_plazo,
          @w_evitar_feriados   = opt_evitar_feriados,
          @w_ult_dia_habil     = opt_dia_habil,
          @w_tasa_equivalente  = opt_usar_tequivalente,
          @w_op_direccion      = isnull(opt_direccion,(select di_direccion from cobis..cl_direccion where di_ente = opt_cliente and di_principal = 'S'))
   from   ca_operacion_tmp
   inner join cobis..cl_catalogo A on opt_banco = @i_banco and opt_toperacion = A.codigo
   inner join cobis..cl_moneda     on opt_moneda = mo_moneda
   left outer join ca_dividendo_tmp on opt_operacion = dit_operacion and dit_estado = 1

   if @@rowcount = 0
   begin
      PRINT 'imptabla.sp error 2'
      select @w_error = 710026
      goto ERROR
   end

   select @w_tplazo   = td_descripcion
   from   ca_tdividendo
   where  td_tdividendo = @w_tplazo

   select @w_tdividendo= td_descripcion
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo

   select @w_tasa     =  isnull(ts_porcentaje,0)
   from   ca_tasas
   where  ts_operacion = @w_operacionca
   and    ts_secuencial = (select min(ts_secuencial)
                           from   ca_tasas
                           where  ts_operacion = @w_operacionca)
   
   select @w_tasa_referencial = rot_referencial,
          @w_signo_spread = rot_signo,
          @w_valor_spread = rot_factor,
          @w_modalidad    = rot_fpago,
          @w_valor_referencial = rot_porcentaje_aux
   from   ca_rubro_op_tmp
   where  rot_operacion  =  @w_operacionca
   and    rot_tipo_rubro =  'I'
   and    rot_fpago      in ('P', 'A')
   
   select @w_tasa_referencial = vd_referencia from ca_valor_det
   where  vd_tipo = @w_tasa_referencial
   and    vd_sector = @w_sector

   select @w_valor_base = pi_valor
   from   cobis..te_pizarra
   where  pi_referencia = @w_tasa_referencial

   set transaction isolation level read uncommitted

   -- DEUDOR
   -- Encuentra el Producto

   select @w_tipo = pd_tipo
   from   cobis..cl_producto
   where  pd_producto = 7

   set transaction isolation level read uncommitted

   -- Encuentra el Detalle de Producto

   select @w_det_producto = dp_det_producto
   from   cobis..cl_det_producto
   where  dp_producto = 7
   and    dp_tipo   = @w_tipo
   and    dp_moneda = @w_moneda
   and    dp_cuenta = @i_banco

   select  @w_rowcount = @@rowcount

   set transaction isolation level read uncommitted

   if @w_rowcount = 0
   begin
      PRINT 'imptabla.sp error 3'
      select @w_error = 710026
      goto ERROR
   end

   -- Realizar la consulta de Informacion General de Cliente
   select @w_ced_ruc   = isnull(cl_ced_ruc,p_pasaporte),
          @w_nombre    = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' '
                       + rtrim(en_nombre),1,60)),
          @w_telefono  = isnull(te_valor,''),
          @w_direccion = isnull(di_descripcion,'')
   from   cobis..cl_cliente
   inner join cobis..cl_ente on cl_det_producto = @w_det_producto and cl_rol = 'D' and en_ente = cl_cliente and cl_cliente = @w_cliente
   left outer join cobis..cl_telefono on te_ente = en_ente
   left outer join cobis..cl_direccion on di_ente  = cl_cliente
   where te_direccion  = @w_op_direccion
   and   di_direccion  = @w_op_direccion

   set transaction isolation level read uncommitted

   exec @w_error = sp_control_tasa
        @i_operacionca  = @w_operacionca,
        @i_temporales   = 'S',
        @i_ibc          = 'N',
        @o_tasa_total_efe = @w_tasa_ef_anual  output
   
   if @w_error <> 0
   begin
      goto ERROR
   end

   select @w_fecha_pri_cuot = convert(varchar(10),di_fecha_ven,@i_formato_fecha)
   from   ca_dividendo  
   where  di_operacion = @w_operacionca
   and    di_dividendo = 1
   
   select @w_cliente,        @w_nombre ,           @w_ced_ruc,
          @w_direccion,      @w_telefono,          @w_toperacion_desc,
          @w_monto,          @w_moneda_desc,       @w_plazo,
          @w_tplazo,         @w_tipo_amortizacion, @w_tdividendo,
          @w_tasa,           @w_periodo_cap,       @w_periodo_int,
          @w_mes_gracia,     @w_gracia,            @w_gracia_cap,
          @w_gracia_int,     @w_tasa_ef_anual,     @w_fecha_fin,
          @w_dias_anio ,     @w_base_calculo,      @w_tasa_referencial,
          @w_valor_base,     @w_valor_spread,      @w_signo_spread,
          @w_modalidad,      @w_fecha_liq,         @w_dia_fijo,
          @w_fecha_pri_cuot, @w_recalcular_plazo,  @w_evitar_feriados,
          @w_ult_dia_habil,  @w_tasa_equivalente,  @w_reajustable
end

-- CABECERA DE LA IMPRESION  EN TABLAS TEMPORALES EN SIMULACIONS
if @i_operacion = 'Z'
begin
   select @w_operacionca       = opt_operacion ,
   @w_cliente           = opt_cliente,
   @w_toperacion_desc   = A.valor,
   @w_moneda            = opt_moneda,
   @w_moneda_desc       = mo_descripcion,
   @w_monto             = opt_monto,
   @w_plazo             = opt_plazo,
   @w_tplazo            = opt_tplazo,
   @w_tipo_amortizacion = opt_tipo_amortizacion,
   @w_tdividendo        = opt_tdividendo,
   @w_periodo_cap       = opt_periodo_cap,
   @w_periodo_int       = opt_periodo_int,
   @w_gracia            = isnull(dit_gracia,0),
   @w_gracia_cap        = opt_gracia_cap,
   @w_gracia_int        = opt_gracia_int,
   @w_cuota             = opt_cuota,
   @w_mes_gracia        = opt_mes_gracia,
   @w_reajustable       = opt_reajustable,
   @w_periodo_reaj      = isnull(opt_periodo_reajuste,0),
   @w_fecha_fin         = convert(varchar(10),opt_fecha_fin,@i_formato_fecha),
   @w_dias_anio         = opt_dias_anio,
   @w_base_calculo      = opt_base_calculo,
   @w_sector            = opt_sector,
   @w_fecha_liq         = convert(varchar(10),opt_fecha_liq,@i_formato_fecha),
   @w_dia_fijo          = opt_dia_fijo,
   --@w_fecha_pri_cuot    = convert(varchar(10),opt_fecha_ini,@i_formato_fecha),
   @w_recalcular_plazo  = opt_recalcular_plazo,
   @w_evitar_feriados   = opt_evitar_feriados,
   @w_ult_dia_habil     = opt_dia_habil,
   @w_tasa_equivalente  = opt_usar_tequivalente
   from ca_operacion_tmp
     inner join cobis..cl_catalogo A on
           opt_banco = @i_banco
           and opt_toperacion = A.codigo
             inner join cobis..cl_moneda on
             opt_moneda = mo_moneda
                left outer join ca_dividendo_tmp on
                opt_operacion = dit_operacion
                and dit_estado = 1

   if @@rowcount = 0
   begin
      PRINT 'imptabla.sp error 4'
      select @w_error = 710026
      goto ERROR
   end

   select @w_tplazo   = td_descripcion
   from ca_tdividendo
   where td_tdividendo = @w_tplazo

   select @w_tdividendo= td_descripcion
   from ca_tdividendo
   where td_tdividendo = @w_tdividendo

   select @w_tasa_referencial = rot_referencial,
          @w_signo_spread = rot_signo,
          @w_valor_spread = rot_factor,
          @w_modalidad    = rot_fpago,
          @w_valor_referencial = rot_porcentaje_aux,
          @w_tasa              = rot_porcentaje
   from ca_rubro_op_tmp
   where rot_operacion  =  @w_operacionca
   and   rot_tipo_rubro =  'I'
   and   rot_fpago      in ('P', 'A')

   select @w_tasa_referencial = vd_referencia from ca_valor_det
   where vd_tipo = @w_tasa_referencial
   and vd_sector = @w_sector

   select @w_valor_base = pi_valor
   from cobis..te_pizarra
   where pi_referencia = @w_tasa_referencial
   set transaction isolation level read uncommitted

   exec @w_error = sp_control_tasa
   @i_operacionca = @w_operacionca,
   @i_temporales  = 'S',
   @i_ibc         = 'N',
   @o_tasa_total_efe = @w_tasa_ef_anual  output

   if @w_error <> 0
   begin
      goto ERROR
   end

   
   select @w_fecha_pri_cuot = convert(varchar(10),di_fecha_ven,@i_formato_fecha)
   from ca_dividendo  
   where di_operacion = @w_operacionca
   and di_dividendo = 1
   
   select
   @w_cliente,        @w_nombre ,           @w_ced_ruc,
   @w_direccion,      @w_telefono,          @w_toperacion_desc,
   @w_monto,          @w_moneda_desc,       @w_plazo,
   @w_tplazo,         @w_tipo_amortizacion, @w_tdividendo,
   @w_tasa,           @w_periodo_cap,       @w_periodo_int,
   @w_mes_gracia,     @w_gracia,            @w_gracia_cap,
   @w_gracia_int,     @w_tasa_ef_anual,     @w_fecha_fin,
   @w_dias_anio ,     @w_base_calculo,      @w_tasa_referencial,
   @w_valor_base,     @w_valor_spread,      @w_signo_spread,
   @w_modalidad,      @w_fecha_liq,         @w_dia_fijo,
   @w_fecha_pri_cuot, @w_recalcular_plazo,  @w_evitar_feriados,
   @w_ult_dia_habil,  @w_tasa_equivalente,  @w_reajustable,
   @w_moneda

end

/* SIMULACION DE LA TABLA DE AMORTIZACION */
if @i_operacion = 'S'
begin
   /* CHEQUE DE EXISTA LA OPERACION */

   select
   @w_operacionca = opt_operacion
   from ca_operacion_tmp
   where opt_banco = @i_banco

   if @@rowcount = 0
   begin
      PRINT 'imptabla.sp error 5'
      select @w_error = 710026
     goto ERROR
   end

   select @w_tamanio = 10

   /* TABLA DE AMORTIZACION */
      /* CAPITAL */

   set rowcount @w_tamanio

   select amt_dividendo,convert(float, sum(amt_cuota + amt_gracia))
   from ca_amortizacion_tmp,ca_rubro_op_tmp
   where
   rot_operacion      = @w_operacionca
   and amt_operacion  = rot_operacion
   and amt_concepto   = rot_concepto
   and rot_tipo_rubro = 'C'
   and amt_dividendo  < @i_dividendo
   group by amt_dividendo
   order by amt_dividendo desc

   /* INTERES */

   set rowcount @w_tamanio

   select amt_dividendo,convert(float, sum(amt_cuota + amt_gracia))
   from ca_amortizacion_tmp, ca_rubro_op_tmp
   where rot_operacion = @w_operacionca
   and amt_operacion   = rot_operacion
   and amt_concepto    = rot_concepto
   and rot_tipo_rubro  in ('I', 'F')
   and amt_dividendo   < @i_dividendo
   group by amt_dividendo
   order by amt_dividendo desc

      /* OTROS */

   set rowcount @w_tamanio

   select amt_dividendo,convert(float, sum(amt_cuota + amt_gracia))
   from ca_amortizacion_tmp,ca_rubro_op_tmp
   where rot_operacion = @w_operacionca
   and amt_operacion   = rot_operacion
   and amt_concepto    = rot_concepto
   and rot_tipo_rubro  not in ('C', 'I', 'F')
   and amt_dividendo   < @i_dividendo
   group by amt_dividendo
   order by amt_dividendo desc

      /* ABONO */

   set rowcount @w_tamanio

   select  amt_dividendo,convert(float, sum(amt_pagado))
   from ca_amortizacion_tmp,ca_rubro_op_tmp
   where rot_operacion = @w_operacionca
   and amt_operacion   = rot_operacion
   and amt_concepto    = rot_concepto
   and amt_dividendo   < @i_dividendo
   group by amt_dividendo
   order by amt_dividendo desc

      /* FECHAS DE PAGO Y ESTADO */
   set rowcount @w_tamanio

   select
   convert(varchar(10), dit_fecha_ven, @i_formato_fecha),
   es_descripcion,
   dit_dias_cuota
   from ca_dividendo_tmp,ca_estado
   where dit_operacion     = @w_operacionca
   and   dit_estado        = es_codigo
   and   dit_dividendo     < @i_dividendo
   order by dit_dividendo desc


end

set rowcount 0

delete tmp_interes_amortiza_tmp where spid = @@spid
return 0

ERROR:

if @w_deshacer_tran = 'S'                                          -- REQ 175: PEQUENA EMPRESA
   rollback tran   
   
delete tmp_interes_amortiza_tmp where spid = @@spid
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error
go
