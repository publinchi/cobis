/************************************************************************/
/*   Archivo:             imptablamsv.sp                                */
/*   Stored procedure:    sp_imp_tabla_amort_msv                        */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        RRB                                           */
/*   Fecha de escritura:  02/Abr/2013                                   */
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
/*   Geera archivo plano con tablas de Amortizacion.                    */
/*                         MODIFICACIONES                               */
/*      FECHA           AUTOR      RAZON                                */
/*  ene-28-2014      Liana Coto   Req 406 Tasa seguro de vida empleados */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'tmp_interes_amortiza_msv')
   drop table tmp_interes_amortiza_msv
go

create table tmp_interes_amortiza_msv
(
 cuota      smallint   null,
 monto      money      null,
 concepto   catalogo   null,
 tasa       float      null,
 spid       int
) --lock datarows
go

if exists (select 1 from sysobjects where name = 'tmp_colateral_msv')
   drop table tmp_colateral_msv
go

create table tmp_colateral_msv
(
 tipo_sub varchar(64)
) 
go

if exists (select 1 from sysobjects where name = 'tmp_plano_msv')
   drop table tmp_plano_msv
go
create table tmp_plano_msv (cadena varchar(1000) not null)

if exists (select 1 from sysobjects where name = 'sp_imp_tabla_amort_msv')
   drop proc sp_imp_tabla_amort_msv
go

create proc sp_imp_tabla_amort_msv(
  
   @i_param1            datetime    = null,
   @i_param2            datetime    = null,
   @i_param3            catalogo    = null,
   @i_param4            int         = null,
   @i_param5            char(1)     = 'N'
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
   @w_reajustable                  char(1),
   @w_periodo_reaj                 int,
   @w_primer_des                   int,
   @w_tasa_ef_anual                float,
   @w_periodicidad_o               char(1),
   @w_modalidad_o                  char(1),
   @w_fecha_fin                    varchar(10),
   @w_fecha_final                  varchar(10),
   @w_fecha_proceso                varchar(10),
   @w_dias_anio                    int,
   @w_base_calculo                 varchar(50),
   @w_tasa_referencial             varchar(12),
   @w_signo_spread                 char(1),
   @w_valor_spread                 float,
   @w_valor_base                   float,
   @w_modalidad                    varchar(50),
   @w_valor_referencial            float,
   @w_sector                       char(1),
   @w_fecha_liq                    varchar(10),
   @w_dia_fijo                     int,
   @w_fecha_pri_cuot               varchar(10),
   @w_recalcular_plazo             varchar(2),
   @w_evitar_feriados              varchar(2),
   @w_ult_dia_habil                varchar(2),
   @w_tasa_equivalente             varchar(2),
   @w_tipo_puntos                  varchar(50),
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
   @w_dist_gracia                  char(1),
   @w_ffin_gracia                  datetime,
   @w_deshacer_tran                char(1),
   @w_estado                       tinyint,
   @w_divini_reg                   smallint,
   @w_di_fecha_ini                 datetime,
   @w_di_fecha_ven                 datetime,
   @w_num_dividendos               smallint,
   @w_plazo_operacion              smallint,
   @w_cuota_desde_cap              smallint,
   @w_est_novigente                tinyint,
   @w_est_credito                  tinyint,
   @w_est_cancelado                tinyint,
   @w_di_de_capital                smallint,
   @w_divs_reg                     smallint,
   @w_concepto_cap                 catalogo,
   @w_capitalizar                  money   ,
   @w_tramite                      int     ,
   @w_tipo_garantia                varchar(50),
   @w_cod_tipogar                  catalogo,
   @w_colaterales                  varchar(20),
   @w_tipo_superior                catalogo,
   @w_vlr_x_amort                  money,
   @w_banco                        cuenta,
   @w_proceso                      int,
   --variables para bcp   
   @w_path_destino                 varchar(100),
   @w_s_app                        varchar(50),
   @w_cmd                          varchar(255),   
   @w_comando                      varchar(255),
   @w_nombre_archivo               varchar(255),  
   @w_anio                         varchar(4),
   @w_mes                          varchar(2),
   @w_dia                          varchar(2),
   @w_msg                          descripcion,
   @w_nemonico_alz                 varchar(10),
   @w_pdf                          varchar(124),
   @w_p_apellido                   varchar(16),
   @w_tipo_mail                    catalogo,
   @w_mail                         descripcion,
   @w_dir_banco                    varchar(255),
   @w_ciu_ofici                    varchar(255),
   @w_tel_ofici                    varchar(16),
   @w_filial                       tinyint,
   --Variables FTP
   @w_passcryp                     varchar(255),
   @w_login                        varchar(255),
   @w_password		           varchar(255),
   @w_FtpServer		           varchar(50),
   @w_tmpfile                      varchar(100),
   @w_return                       int,
   @w_server                       varchar(50),
   @w_path_plano                   varchar(255),
   @w_dividendo                    int,
   @s_user                         varchar(30),
   @w_fecha_formato                int,
   @w_alianza                      varchar(10),
   @w_desalianza                   varchar(255),
   @w_tramite_seg                  int,                                 -- REQ 366: SEGUROS   
   @w_operacion_seg                int,                                 -- REQ 366: SEGUROS   
   @w_nro_tramites                 int,                                 -- REQ 366: SEGUROS 
   @w_tasa_seg_ind                 float,                               -- REQ 366: SEGUROS   
   @w_tasa_seg_1_perd              float,                               -- REQ 366: SEGUROS   
   @w_tasa_seg_exequias            float,                               -- REQ 366: SEGUROS   
   @w_tasa_seg_danos               float,                               -- REQ 366: SEGUROS
   @w_tasa_ef_anual_aux            float,                               -- REQ 366: SEGUROS   se solicita que No se muestre la tasa ponderada al cliente
   @w_valor_total_seg              money,                               -- REQ 366: SEGUROS   Mapea a la tabla de amortizacion el valor original de los seguros del tramite
   @w_segdeem                      catalogo,                             -- REQ 406 Tasa seguro de vida empleados
   --REQ 402
   @w_parametro_fgu                catalogo,                            -- REQ 379: GARANTIAS CON COBRO INDEPENDIENTE 
   @w_parametro_fgu_iva            catalogo,                            -- REQ 379: GARANTIAS CON COBRO INDEPENDIENTE
   @w_rubros                       varchar(10),
   @w_tabla_rubros                 varchar(30),
   @w_envia_mail                   descripcion,
   @w_mail_alianza                 descripcion,
   @w_div_vig                      tinyint,
   @w_div_cap                      tinyint,
   @w_cuota_cap                    money,
   @w_sld_cap_div                  money,
   @w_tiene_reco                   char(1),
   @w_vlr_calc_fijo                money,
   @w_div_pend                     money,
   @w_monto_reconocer              money


if isnull(@i_param3,'T') = 'T' 
   select @i_param3 = null
     
if isnull(@i_param4,0) = 0
   select @i_param4 = null

select   
@w_sp_name       = 'sp_imp_tabla_amort_msv',
@w_deshacer_tran = 'N',
@w_proceso       = 7968,
@s_user          = 'sa',
@w_dividendo     = 9999,
@w_fecha_formato = 103,
@w_alianza       = null,
@w_desalianza    = null

if exists (select 1 from sysobjects where name = 'tmp_plano_msv')
   drop table tmp_plano_msv

create table tmp_plano_msv (cadena varchar(1000) not null)


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

select @w_mon_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
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

select tc_tipo 
into #tipo_garantia
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng

select @w_tipos_gar = count(1) from #tipo_garantia

insert into tmp_colateral_msv
select tc_tipo 
from cob_custodia..cu_tipo_custodia
where tc_tipo_superior = @w_colaterales

if @@error <> 0
begin
   select @w_error = 710001
   goto ERROR
end

select banco = op_banco, estado = 'I'
into #operaciones
from ca_operacion with (nolock), cob_credito..cr_tramite with (nolock)
where op_fecha_liq between CONVERT(varchar, @i_param1, 102) and CONVERT(varchar, @i_param2, 102)
and   tr_tramite    = op_tramite
and  (tr_alianza    = @i_param4 or @i_param4 is null)
and   tr_alianza is not null
and   op_estado not in (0,3,99) 
and  (op_toperacion = @i_param3 or @i_param3 is null)

while 1 = 1 begin

   set rowcount 1

   select @w_banco = banco
   from #operaciones
   where estado = 'I'
   order by banco

   if @@rowcount = 0 begin
      break
   end
   
   set rowcount 0

   -- CABECERA DE LA IMPRESION  EN TABLAS DEFINITIVAS

   select
   @w_operacionca        = op_operacion ,
   @w_cliente            = op_cliente,
   @w_toperacion_desc    = A.valor,
   @w_moneda             = op_moneda,
   @w_oficina            = op_oficina,
   @w_moneda_desc        = mo_descripcion,
   @w_monto              = op_monto,
   @w_monto_aprobado     = op_monto_aprobado,
   @w_plazo              = op_plazo,
   @w_tplazo             = op_tplazo,
   @w_tipo_amortizacion  = op_tipo_amortizacion,
   @w_tdividendo         = op_tdividendo,
   @w_periodo_cap        = op_periodo_cap,
   @w_periodo_int        = op_periodo_int,
   @w_gracia             = isnull(di_gracia,0),
   @w_gracia_cap         = op_gracia_cap,
   @w_gracia_int         = op_gracia_int,
   @w_cuota              = op_cuota,
   @w_mes_gracia         = op_mes_gracia,
   @w_reajustable        = op_reajustable,
   @w_periodo_reaj       = isnull(op_periodo_reajuste,0),
   @w_fecha_fin          = convert(varchar(10),op_fecha_fin,@w_fecha_formato),
   @w_dias_anio          = op_dias_anio,
   @w_base_calculo       = op_base_calculo,
   @w_sector             = op_sector,
   @w_fecha_liq          = convert(varchar(10),op_fecha_liq,@w_fecha_formato),
   @w_dia_fijo           = op_dia_fijo,
   @w_recalcular_plazo   = op_recalcular_plazo,
   @w_evitar_feriados    = op_evitar_feriados,
   @w_ult_dia_habil      = op_dia_habil,
   @w_fecha_ult_pro      = op_fecha_ult_proceso,
   @w_tasa_equivalente   = op_usar_tequivalente,
   @w_op_direccion       = isnull(op_direccion,1),
   @w_op_codigo_externo  = op_codigo_externo,
   @w_margen_redescuento = isnull(op_margen_redescuento,0),
   @w_dist_gracia        = op_dist_gracia,                              
   @w_tramite            = op_tramite,                                    
   @w_estado             = op_estado                  
   from ca_operacion
               inner join cobis..cl_catalogo A on
                op_banco    = @w_banco
                and op_toperacion = A.codigo
                    inner join cobis..cl_moneda on
                     op_moneda = mo_moneda
                           left outer join ca_dividendo on
                           op_operacion = di_operacion
                           and di_estado = 1

   if @@rowcount = 0
   begin
      PRINT 'imptabla.sp error 8'
      select @w_error = 710026
      goto ERROR
   end
          
   select @w_cod_tipogar = '',
          @w_tipo_garantia = '',
          @w_tipo_superior = ''

   select @w_cod_tipogar   = tc_tipo,
          @w_tipo_garantia = tc_descripcion,
          @w_tipo_superior = tc_tipo_superior
   from cob_custodia..cu_tipo_custodia, cob_custodia..cu_custodia, tmp_colateral_msv, cob_credito..cr_gar_propuesta
   where tc_tipo = cu_tipo
   and   tc_tipo_superior = tipo_sub
   and   cu_codigo_externo = gp_garantia
   and   gp_tramite = @w_tramite
   and   gp_est_garantia <> 'A'  --acelis ago 12 2012
   and   cu_estado <> 'A'
   
   /*BUSQUEDA DE CONCEPTOS REQ 379*/
   select @w_rubros = valor 
   from  cobis..cl_tabla t, cobis..cl_catalogo c
   where t.tabla  = 'ca_conceptos_rubros'
   and   c.tabla  = t.codigo
   and   c.codigo = convert(bigint, @w_cod_tipogar)  

   if @w_rubros = 'S' begin

      select @w_tabla_rubros = 'ca_conceptos_rubros_' + cast(@w_cod_tipogar as varchar)

      insert into #conceptos
      select 
      codigo = c.codigo, 
      tipo_gar = @w_cod_tipogar
      from cobis..cl_tabla t, cobis..cl_catalogo c
      where t.tabla  = @w_tabla_rubros
      and   c.tabla  = t.codigo
      
      if @@error <> 0
      begin
         select @w_error = 710001
         goto ERROR
      end      
   end --FIN REQ 379

   /*REQ 402*/
   
   insert into #rubros
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'DES',
          iva = 'N'
   from cob_cartera..ca_rubro, #conceptos
   where ru_fpago = 'L'
   and   codigo = ru_concepto
   and   ru_concepto_asociado is  null

   /*COMICION PERIODICO*/
   insert into #rubros
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'PER',
          iva = 'N'
   from cob_cartera..ca_rubro, #conceptos
   where ru_fpago = 'P'
   and   codigo = ru_concepto
   and   ru_concepto_asociado is  null
   
   /*IVA DESEMBOLSO*/
   insert into #rubros
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'DES',
          iva = 'S'
   from cob_cartera..ca_rubro, #conceptos
   where ru_fpago = 'L'
   and   codigo = ru_concepto
   and   ru_concepto_asociado is not null
 
   /*IVA PERIODICO*/
   insert into #rubros
   select tipo_gar  ,
          ru_concepto ,
          tipo_concepto = 'PER',
          iva = 'S'
   from cob_cartera..ca_rubro, #conceptos
   where ru_fpago = 'P'
   and   codigo = ru_concepto
   and   ru_concepto_asociado is not null


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
          @w_valor_spread = ro_factor,
          @w_modalidad    = ro_fpago,
          @w_valor_referencial = ro_porcentaje_aux,
          @w_tipo_puntos = ro_tipo_puntos,
          @w_concepto_int = ro_concepto
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_fpago      in ('P','A')


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

      /* TASA BASICA REFERENCIAL */
      select @w_valor_base = isnull(vr_valor,0)
      from   ca_valor_referencial
      where  vr_tipo       = @w_tasa_base
      and    vr_secuencial = @w_secuencial_ref

    end

   --DEF-7705 BAC
   select
   @w_ced_ruc    = isnull(en_ced_ruc,p_pasaporte),
   @w_nombre     = ltrim(substring(rtrim(p_p_apellido) + ' ' + rtrim(p_s_apellido) + ' ' + rtrim(en_nombre),1,60)),
   @w_p_apellido = rtrim(p_p_apellido)
   from cobis..cl_ente
   where en_ente = @w_cliente
   
   select @w_filial = pa_tinyint 
   from cobis..cl_parametro
   where pa_nemonico = 'FILIAL'
   and   pa_producto = 'CRE'
   
   select @w_dir_banco = fi_direccion 
   from cobis..cl_filial
   where   fi_filial = @w_filial
           
   select @w_telefono  = isnull(te_valor,'')
   from   cobis..cl_telefono
   where  te_ente      = @w_cliente
   and    te_direccion = @w_op_direccion

   select @w_tipo_mail = pa_char 
   from cobis..cl_parametro
   where pa_producto = 'MIS'
   and pa_nemonico = 'TDW'

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
         select @w_tipo_amortizacion = 'PERSONALIZADA'
   end

   select @w_nom_oficina = of_nombre,
          @w_ciu_ofici   = ci_descripcion
   from cobis..cl_oficina, cobis..cl_ciudad
   where of_oficina = @w_oficina
   and   of_ciudad  = ci_ciudad
   set transaction isolation level read uncommitted
   
   select @w_tel_ofici  = to_valor
   from cobis..cl_oficina, cobis..cl_telefono_of
   where of_oficina  = @w_oficina
   and   to_oficina  = of_oficina
   and   of_telefono = to_secuencial
   set transaction isolation level read uncommitted
   
   select @w_fecha_pri_cuot = convert(varchar(10),di_fecha_ven,@w_fecha_formato)
   from ca_dividendo  
   where di_operacion = @w_operacionca
   and di_dividendo = 1

   /* LCM - 293: CONSULTA LA TABLA DE RECONOCIMIENTO PARA VALIDAR SI LA OBLIGACION TIENE RECONOCIMIENTO */
   select @w_vlr_x_amort = 0

   select @w_vlr_x_amort = pr_vlr - pr_vlr_amort
   from ca_pago_recono with (nolock)
   where pr_operacion = @w_operacionca
   and   pr_estado    = 'A'

   /* LCM - 366: OBTIENE TASAS ASOCIADAS A LOS SEGUROS DEL CLIENTE y VALOR TOTAL ORIGINAL*/
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
   
   drop table #seguros
   
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
      select @w_pl_meses = @w_plazo_am * (select td_factor from cob_cartera..ca_tdividendo where td_tdividendo = @w_tplazo) / 30   
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

   -- DETALLE DE LA TABLA DE AMORTIZACION EN TABLAS DEFINITIVAS
   -- CHEQUEO QUE EXISTA LA OPERACION

   delete tmp_interes_amortiza_msv with (rowlock)
   where cuota >= 0

   -- INI - REQ 175: PEQUEÑA EMPRESA
   -- DETERMINACION DE LA FECHA EN LA QUE TERMINA LA GRACIA DE INTER+S
   if @w_gracia_int > 0 and @w_dist_gracia = 'C'
   begin
      -- AVANCE DE LA OPERACION POSTERIOR A LAS CAPITALIZACIONES
      select @w_ffin_gracia = dateadd(dd, 1, di_fecha_ven)
      from ca_dividendo
      where di_operacion = @w_operacionca
      and   di_dividendo = @w_gracia_int
      
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
         --@s_term            = @s_term,
         @i_banco           = @w_banco,
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
         @o_fecha_fin       = @w_fecha_final out
         
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
   -- FIN - REQ 175: PEQUEÑA EMPRESA

   if exists (select ro_operacion from ca_rubro_op
              where ro_operacion = @w_operacionca
              and ro_tipo_rubro  = 'I' )
   Begin
      declare cursor_operacion cursor for
      select  am_dividendo,
              convert(float, sum(am_cuota + am_gracia)),
              am_concepto,
              isnull(ro_porcentaje,0)
      from ca_amortizacion,ca_rubro_op
      where am_operacion = ro_operacion
      and am_concepto    = ro_concepto
      and ro_operacion   = @w_operacionca
      and ro_tipo_rubro  = 'I'
      and am_dividendo   < @w_dividendo
      group by am_dividendo,am_concepto, ro_porcentaje
      order by am_dividendo desc
   end
   else
   Begin

      declare cursor_operacion cursor for
      select am_dividendo,
             0,
             am_concepto,
             isnull(ro_porcentaje,0)  --Serî de CAP
      from ca_amortizacion,ca_rubro_op
      where am_operacion = ro_operacion
      and am_concepto    = ro_concepto
      and ro_operacion   = @w_operacionca
      and ro_tipo_rubro  = 'C'
      and am_dividendo   < @w_dividendo
      group by am_dividendo,am_concepto, ro_porcentaje
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
      from  ca_amortizacion, ca_tasas
      where ts_operacion = am_operacion
      and   ts_dividendo = am_dividendo
      and   ts_concepto  = am_concepto
      and   ts_operacion = @w_operacionca
      and   ts_dividendo = @w_tcuota
      and   ts_concepto  = @w_tconcepto
      
      
      if @@rowcount > 0
      begin
         insert into tmp_interes_amortiza_msv
               (cuota,     monto,      concepto,      tasa,             spid)
         values(@w_tcuota, @w_tmonto,  @w_tconcepto,  @w_tporcentaje,   @@spid)

         if @@error <> 0
         begin
            select @w_error = 710001
            goto ERROR
         end

         select @w_ult_tasa = @w_tporcentaje
      end
      else
      begin
         if @w_ttasa = 0
            select @w_ttasa = @w_ult_tasa

            insert into tmp_interes_amortiza_msv
               (cuota,     monto,      concepto,      tasa,       spid)
            values(@w_tcuota, @w_tmonto,  @w_tconcepto,  @w_ttasa,   @@spid)

            if @@error <> 0
            begin
               select @w_error = 710001
               goto ERROR
            end            
         end

      fetch cursor_operacion
      into @w_tcuota, @w_tmonto, @w_tconcepto, @w_ttasa
   end
   close cursor_operacion
   deallocate cursor_operacion

   /**********************/

   select @w_tamanio = 20  ----EPBoc01012001

   -- TABLA DE AMORTIZACION

   --set rowcount @w_tamanio   

   -- CAPITAL

   create table #tmp_tabla_msv 
   (
    dividendo      smallint    null,
    fechas         varchar(10) null,
    dias_cuota     smallint    null,
    pgdo_capital   money       null,
    capital        money       null, 
    interes        money       null,
    mora           money       null,
    mipymes        money       null,
    ivamipymes     money       null,
    fng            money       null,
    ivafng         money       null,
    seguros        money       null,
    otros          money       null,
    vlr_cuota      money       null,
    estado         varchar(12) null,
    capitalizado   money       null,
    cuota_cap      money       null,
    cuota_int      money       null,
    cuota_mora     money       null -- CCA 409
   ) 

   if @w_mon_nacional = @w_moneda
   begin
      insert into #tmp_tabla_msv 
      select am_dividendo, '', 0,0,sum(am_cuota + am_gracia),0,0,0,0,0,0,0,0,0,'',0,0,0,0
      from ca_amortizacion,ca_rubro_op
      where
      ro_operacion      = @w_operacionca
      and am_operacion  = ro_operacion
      and am_concepto   = ro_concepto
      and ro_tipo_rubro = 'C'
      and am_dividendo  < @w_dividendo
      group by am_dividendo
      order by am_dividendo desc
  end
  else
  begin  --para que se genere con cuatro decimales.
      insert into #tmp_tabla_msv 
      select am_dividendo, '', 0,0,sum(am_cuota + am_gracia),0,0,0,0,0,0,0,0,0,'',0,0,0,0
      from ca_amortizacion,ca_rubro_op
      where
      ro_operacion      = @w_operacionca
      and am_operacion  = ro_operacion
      and am_concepto   = ro_concepto
      and ro_tipo_rubro = 'C'
      and am_dividendo  < @w_dividendo
      group by am_dividendo
      order by am_dividendo desc
   end

   --OBTIENE EL SALDO ACUMULADO A CAPITAL POR CADA DIVIDENDO
   create table #cap
   ( 
    ca_dividendo int,-- identity, 
    ca_capital money 
   ) 

   insert into #cap 
   select di_dividendo, isnull(sum(am_cuota + am_gracia),0) 
   from ca_dividendo, ca_amortizacion 
   where di_operacion = @w_operacionca 
   and di_operacion = am_operacion 
   and am_dividendo >= di_dividendo 
   and am_concepto = 'CAP' 
   group by di_dividendo, convert(varchar(10),di_fecha_ven,103), case di_estado when 0 then 'NO VIGENTE' when 1 then 'VIGENTE' when 2 then 'VENCIDO' end 
   order by di_dividendo desc 

   --ACTUALIZA EL SALDO A CAPITAL
   update #tmp_tabla_msv set 
   pgdo_capital = ca_capital 
   from #cap 
   where ca_dividendo = dividendo

   -- INTERES

   --set rowcount @w_tamanio
 
   update #tmp_tabla_msv 
   set interes = round(convert(float,monto), @w_num_dec)
   from tmp_interes_amortiza_msv with (nolock)
   where cuota = dividendo

   -- OTROS
   --set rowcount @w_tamanio   

   select am_dividendo=am_dividendo,
          monto = round(convert(float, sum(am_cuota + am_gracia)),@w_num_dec)
   into #otros
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @w_dividendo
   and ro_concepto not in (@w_pmipymes, @w_ivamipymes, @w_parametro_fng, @w_parametro_fag, @w_parametro_usaid, @w_ivafng, @w_ivafag, @w_ivausaid, @w_segdeven, 'IMO',@w_parametro_fgu,@w_parametro_fgu_iva, @w_segdeem)  --Req 406 LC 28/ENE/2014 se agrega @w_segdeem)
   and ro_concepto not in (select rre_concepto from #rubros where tipo_concepto = 'PER')
   and ro_concepto not in (select codigo_sib from cob_credito..cr_corresp_sib where tabla = 'T156')      
   group by am_dividendo
   order by am_dividendo desc

   update #tmp_tabla_msv 
   set otros = monto
   from #otros
   where am_dividendo = dividendo

   drop table #otros
   
   -- FECHAS DE PAGO Y ESTADO

   select
   di_dividendo = di_dividendo,
   fecha = di_fecha_ven,
   descp = es_descripcion,
   dias  = di_dias_cuota
   into #fechas
   from ca_dividendo,ca_estado
   where
   di_operacion     = @w_operacionca
   and di_estado    = es_codigo
   and di_dividendo < @w_dividendo
   order by di_dividendo desc

   update #tmp_tabla_msv 
   set fechas     = convert(varchar(10),fecha,@w_fecha_formato),
       dias_cuota = dias,
       estado     = descp  
   from #fechas
   where di_dividendo = dividendo   

   drop table #fechas
      
   -- MIPYMES
   --set rowcount @w_tamanio   
   
   select am_dividendo = am_dividendo,
          monto = round(convert(float, sum(am_cuota + am_gracia)),@w_num_dec)
   into #pymes
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @w_dividendo
   and ro_concepto    = @w_pmipymes
   group by am_dividendo
   order by am_dividendo desc

   update #tmp_tabla_msv 
   set mipymes = monto
   from #pymes
   where am_dividendo = dividendo

   drop table #pymes
   
   -- IVAMIPYMES
   --set rowcount @w_tamanio   
   
   select am_dividendo = am_dividendo,
          monto =  round(convert(float, sum(am_cuota + am_gracia)),@w_num_dec)
   into #ivapymes
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @w_dividendo
   and ro_concepto    = @w_ivamipymes
   group by am_dividendo
   order by am_dividendo desc
   
   update #tmp_tabla_msv 
   set ivamipymes = monto
   from #ivapymes
   where am_dividendo = dividendo

   drop table #ivapymes

   -- COMISION FNG ANUAL
   --set rowcount @w_tamanio         
   
   select am_dividendo = am_dividendo,
          monto =  round(convert(float, sum(am_cuota + am_gracia)),@w_num_dec)
   into #fng
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca   
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @w_dividendo
   and am_cuota > 0
   and (ro_concepto    in (@w_parametro_fng, @w_parametro_fag, @w_parametro_usaid, @w_parametro_fgu)
        or  ro_concepto    in (select rre_concepto from #rubros where tipo_concepto = 'PER' and iva = 'N'))
   group by am_dividendo
   order by am_dividendo desc

   update #tmp_tabla_msv 
   set fng = monto
   from #fng
   where am_dividendo = dividendo

   drop table #fng
  
   --IVA COMISION FNG     
   --set rowcount @w_tamanio   

   select am_dividendo = am_dividendo, 
          monto =  round(convert(float, sum(am_cuota + am_gracia)),@w_num_dec)
   into #ivafng
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @w_dividendo
   and am_cuota  > 0
   and (ro_concepto  in (@w_ivafng, @w_ivafag, @w_ivausaid, @w_parametro_fgu_iva)
        or  ro_concepto  in (select rre_concepto from #rubros where tipo_concepto = 'PER' and iva = 'S'))
   group by am_dividendo
   order by am_dividendo desc

   update #tmp_tabla_msv 
   set ivafng = monto
   from #ivafng
   where am_dividendo = dividendo

   drop table #ivafng
  	   
  	      
   --SEGURO DECUDORES COBRO VENCIDO  
   --set rowcount @w_tamanio
   
   select am_dividendo = am_dividendo,
          monto =  round(convert(float, sum(am_cuota + am_gracia)),@w_num_dec)
   into #seguro
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @w_dividendo
   and ro_concepto    in (@w_segdeven,@w_segdeem) --Req 406 LC 28/ENE/2014
   group by am_dividendo
   order by am_dividendo desc
   
   update #tmp_tabla_msv 
   set seguros = monto
   from #seguro
   where am_dividendo = dividendo

   drop table #seguro
   
   -- MORA
   --set rowcount @w_tamanio   
   
   select am_dividendo = am_dividendo,
          monto =  round(convert(float, sum(am_cuota + am_gracia)),@w_num_dec)
   into #mora
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacionca
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   < @w_dividendo
   and ro_concepto    = 'IMO'
   group by am_dividendo
   order by am_dividendo desc

   update #tmp_tabla_msv 
   set mora = monto
   from #mora
   where am_dividendo = dividendo

   drop table #mora

   -- OBTIENE VALOR DE LA CUOTA
   update #tmp_tabla_msv 
   set vlr_cuota = capital + interes + otros + mipymes + ivamipymes + fng + ivafng + seguros + mora
   
   -- CONSULTA CAPITAL E INTERES DE LOS SEGUROS ASOCIADOS AL TRAMITE Req. 366
	-- valida que existan seguros asociados
	
     
    create table #cap_seg
   ( 
    dividendo_seg int,-- identity, 
    cuota_cap_seg money ,
    cuota_int_seg money,
    cuota_mora_seg money -- CCA 409
   ) 
	
   select @w_tramite_seg   = op_tramite,
          @w_operacion_seg = op_operacion
   from ca_operacion
   where op_banco = @w_banco
      
   select @w_nro_tramites = count(st_tramite)
   from cob_credito..cr_seguros_tramite
   where st_tramite = @w_tramite_seg  
   
   if @w_nro_tramites > 0 begin
 
      --set rowcount @w_tamanio  
      
      insert  into #cap_seg
      select
              sed_dividendo,
              round(convert(float, sum(sed_cuota_cap)),@w_num_dec),
              round(convert(float, sum(sed_cuota_int)),@w_num_dec),
              round(convert(float, sum(sed_cuota_mora)),@w_num_dec)-- CCA 409      
             
	  from ca_seguros_det, ca_seguros
      where se_sec_seguro = sed_sec_seguro
	  and se_tramite = @w_tramite_seg	
      and sed_dividendo < @w_dividendo
	  and se_estado <> 'C'
      group by sed_dividendo
      order by sed_dividendo desc
   
   end
   else
   begin

      --set rowcount @w_tamanio
      insert  into #cap_seg
      select  di_dividendo,
              convert(float, 0),
              convert(float, 0),
              convert(float, 0)-- CCA 409
      from ca_dividendo
      where di_operacion = @w_operacion_seg 
      and di_dividendo < @w_dividendo	        
      order by di_dividendo desc      
   
   end 
          
   update #tmp_tabla_msv 
   set cuota_cap = cuota_cap_seg,
   cuota_int     = cuota_int_seg,
   cuota_mora    = cuota_mora_seg
   from #cap_seg
   where dividendo_seg = dividendo

   drop table #cap_seg
  
   -- Fin Req. 366
   
   -- CAPITALIZADO
   if @w_gracia_int > 0 and @w_dist_gracia = 'C'
   begin
      --set rowcount 0
      
      select 
      dtr_dividendo  as dividendo,
      sum(dtr_monto) as monto
      into #capitalizado
      from ca_transaccion, ca_det_trn
      where tr_operacion   = @w_operacionca
      and   tr_tran        = 'CRC'
      and   tr_estado     <> 'RV'
      and   dtr_operacion  = tr_operacion
      and   dtr_secuencial = tr_secuencial
      and   dtr_concepto   = @w_concepto_int
      group by dtr_dividendo
      
      --set rowcount @w_tamanio   
      
      select
      am_dividendo,
      case when monto is null then sum(am_cuota - am_pagado) else monto end
      from ca_amortizacion left outer join #capitalizado on am_dividendo = dividendo
      where am_operacion  = @w_operacionca
      and   am_dividendo  < @w_dividendo
      and   am_dividendo <= @w_gracia_int
      and   am_concepto   = @w_concepto_int
      group by am_dividendo, monto
      order by am_dividendo desc
      
      if @w_deshacer_tran = 'S'
         rollback tran   
   end

   -- ESTABLECER BASE DE CALCULO
   if @w_base_calculo = 'E'
      select @w_base_calculo = 'COMERCIAL'

   if @w_base_calculo = 'R'
      select @w_base_calculo = 'REAL'

   -- ESTABLECER MODALIDAD
   if @w_modalidad = 'A'
      select @w_modalidad = 'ANTICIPADA'

   if @w_modalidad = 'P'
      select @w_modalidad = 'VENCIDA'

   -- ESTEBLECER RECALCULAR PLAZO
   if @w_recalcular_plazo = 'S'
      select @w_recalcular_plazo = 'SI'

   if @w_recalcular_plazo = 'N' or @w_recalcular_plazo = ''
      select @w_recalcular_plazo = 'NO'

   -- ESTEBLECER TASA EQUIVALENTE
   if @w_tasa_equivalente = 'S'
      select @w_tasa_equivalente = 'SI'

   if @w_tasa_equivalente = 'N' or @w_tasa_equivalente = ''
      select @w_tasa_equivalente = 'NO'

-- ESTEBLECER DIAS FERIADOS
   if @w_evitar_feriados = 'S'
      select @w_evitar_feriados = 'SI'

   if @w_evitar_feriados = 'N' or @w_evitar_feriados = ''
      select @w_evitar_feriados = 'NO'

-- ESTEBLECER ULTIMO DIA HABIL
   if @w_ult_dia_habil = 'S'
      select @w_ult_dia_habil = 'SI'

   if @w_ult_dia_habil = 'N' or @w_ult_dia_habil = ''
      select @w_ult_dia_habil = 'NO'

-- ESTABLECER TIPO DE PUNTOS
   if @w_tipo_puntos = 'B'
      select @w_tipo_puntos = 'BASE'

   if @w_tipo_puntos = 'N'
      select @w_tipo_puntos = 'NOMINAL'

   if @w_tipo_puntos = 'E'
      select @w_tipo_puntos = 'EFECTIVA'

-- CONSULTA SI EL CLIENTE PERTENECE A UNA ALIANZA
      select @w_desalianza = null,
             @w_nemonico_alz = null,
             @w_alianza = null,
             @w_envia_mail = null,
             @w_mail_alianza = null

      select @w_alianza    = cast(al_alianza as varchar),
             @w_desalianza = isnull((al_nemonico + ' - ' + al_nom_alianza), '  '),
             @w_nemonico_alz = isnull(ltrim(rtrim(al_nemonico)),'  '),
             @w_envia_mail   = al_envia_mail,
             @w_mail_alianza = al_mail_alianza
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
      
   /* 433 - OBTIENE DIVIDENDO, VALOR A CAPITAL DE PAGO POR ABONO EXTRAORDINARIO */
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
             and   dtr_dividendo     = @w_div_cap
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
      where pr_banco = @w_banco
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

      
   if @w_envia_mail = 'S'
   begin 
      select 
      @i_param5 = 'S',
      @w_mail   = ''
          
      if @w_mail_alianza = 'S'
      begin
         select top 1 @w_mail = di_descripcion 
         from   cobis..cl_alianza with (nolock), 
                cobis..cl_direccion with (nolock),
                cobis..cl_alianza_cliente with (nolock)
         where  al_ente     = di_ente
         and    ac_alianza  = al_alianza
         and    ac_ente     = @w_cliente 
         and    di_tipo     = @w_tipo_mail
         and    di_descripcion is not null
         order by di_direccion desc
         
         if @w_mail is null
         begin
            select 
            @w_error = 720010,
            @w_msg   = 'La alianza Debe tener un correo electronico'
            GOTO ERROR
         end
      end   
      else
      begin
         select @w_mail = isnull(di_descripcion,'')   
         from   cobis..cl_direccion 
         where  di_ente      = @w_cliente
         and    di_tipo      = @w_tipo_mail 
            
         if @w_mail is null
         begin
            select top 1 @w_mail = di_descripcion 
            from   cobis..cl_alianza, 
                   cobis..cl_direccion
            where  al_ente = di_ente
            and    di_tipo = @w_tipo_mail
            order by di_direccion desc
         
            if @w_mail is null
            begin
               select 
               @w_error = 720010,
               @w_msg   = 'No se tiene direccion de correo del cliente ni de la alianza'
               GOTO ERROR
            end
         end
      end
   end   
   
   -- Armar nombre PDF

   select @w_anio = convert(varchar(4),datepart(yyyy,@i_param2)),
          @w_mes = convert(varchar(2),datepart(mm,@i_param2)), 
          @w_dia = convert(varchar(2),datepart(dd,@i_param2))  

   select @w_fecha_final  = (@w_anio + right('00' + @w_mes,2) + right('00'+ @w_dia,2))

   select @w_pdf = isnull(@w_nemonico_alz,'EMPTY') + '_TA_' + isnull(@w_p_apellido,'EMPTY')  + '_' + right(isnull(@w_ced_ruc, 'EMPTY'),3)+right(isnull(rtrim(@w_banco), 'EMPTY'),3)+ '_' + @w_fecha_final + '.pdf'

   select @w_fecha_proceso  = right('00'+ @w_dia,2) + '/' + right('00' + @w_mes,2) + '/' +@w_anio 
   
   insert into tmp_plano_msv (cadena) 
   select 
   isnull(rtrim(@w_banco),                            ' ') + '|' +
   isnull(convert(varchar(9),@w_cliente),             ' ') + '|' + isnull(SUBSTRING(@w_nombre,1,60),                          ' ') + '|' + isnull(SUBSTRING(@w_ced_ruc,1,15),                             ' ') + '|' + 
   isnull(SUBSTRING(@w_direccion,1,60),               ' ') + '|' + isnull(SUBSTRING(@w_telefono,1,15),                        ' ') + '|' + isnull(SUBSTRING(@w_toperacion_desc,1,60),                     ' ') + '|' +
   isnull(convert(varchar(12),@w_monto),              ' ') + '|' + isnull(SUBSTRING(@w_moneda_desc,1,20),                     ' ') + '|' + isnull(convert(varchar(3),@w_plazo),                           ' ') + '|' +
   isnull(SUBSTRING(@w_tplazo,1,40),                  ' ') + '|' + isnull(SUBSTRING(@w_tipo_amortizacion,1,40),               ' ') + '|' + isnull(SUBSTRING(@w_tdividendo,1,40),                          ' ') + '|' +
   isnull(convert(varchar(5),round(@w_tasa,2)),       ' ') + '|' + isnull(convert(varchar(2),@w_periodo_cap),                 ' ') + '|' + isnull(convert(varchar(2),@w_periodo_int),                     ' ') + '|' + 
   isnull(convert(varchar(2),@w_mes_gracia),          ' ') + '|' + isnull(convert(varchar(2),@w_gracia),                      ' ') + '|' + isnull(convert(varchar(2),@w_gracia_cap),                      ' ') + '|' + 
   isnull(convert(varchar(2),@w_gracia_int),          ' ') + '|' + isnull(convert(varchar(10),round(@w_tasa_ef_anual_aux,5)),      ' ') + '|' + isnull(convert(varchar(10),@w_fecha_fin,@w_fecha_formato),     ' ') + '|' +
   isnull(convert(varchar(3),@w_dias_anio),           ' ') + '|' + isnull(convert(varchar(50),@w_base_calculo),                ' ') + '|' + isnull(convert(varchar(10),@w_tasa_base),                     ' ') + '|' +
   isnull(convert(varchar(12),@w_valor_base),         ' ') + '|' + isnull(convert(varchar(10),round(@w_valor_spread,5)),       ' ') + '|' + isnull(@w_signo_spread,                                        ' ') + '|' +
   isnull(@w_modalidad,                               ' ') + '|' + isnull(@w_reajustable,                                         ' ') + '|' + isnull(convert(varchar(10),@w_fecha_liq,@w_fecha_formato), ' ') + '|' + isnull(convert(varchar(2),@w_dia_fijo),                        ' ') + '|' +
   isnull(@w_fecha_pri_cuot,                          ' ') + '|' + isnull(@w_recalcular_plazo,                                ' ') + '|' + isnull(@w_evitar_feriados,                                     ' ') + '|' +
   isnull(@w_ult_dia_habil,                           ' ') + '|' + isnull(@w_tasa_equivalente,                                ' ') + '|' + 
   isnull(@w_tipo_puntos,                             ' ') + '|' + isnull(convert(varchar(12),@w_valor_base),                 ' ') + '|' + isnull(convert(varchar(10),@w_fecha_ult_pro,@w_fecha_formato), ' ') + '|' +
   isnull(convert(varchar(1),@w_moneda),              ' ') + '|' + isnull(SUBSTRING(@w_nom_oficina,1,64),                     ' ') + '|' + isnull(convert(varchar(24),@w_op_codigo_externo),              ' ') + '|' +
   isnull(convert(varchar(12),@w_margen_redescuento), ' ') + '|' + isnull(@w_dist_gracia,                                     ' ') + '|' + isnull(convert(varchar(10),@w_cod_tipogar),                    ' ') + '|' +
   isnull(@w_tipo_garantia,                           ' ') + '|' + isnull(convert(varchar(12),@w_vlr_x_amort),                ' ') + '|' + 
   convert(varchar(3),dividendo)                           + '|' + fechas                                                          + '|' + convert(varchar(3),dias_cuota)                                      + '|' + 
   convert(varchar(12),pgdo_capital)                       + '|' + convert(varchar(12),capital)                                    + '|' + convert(varchar(12),interes)                                        + '|' +
   convert(varchar(12),mora)                               + '|' + convert(varchar(12),mipymes)                                    + '|' + convert(varchar(12),ivamipymes)                                     + '|' + 
   convert(varchar(12),fng)                                + '|' + convert(varchar(12),ivafng)                                     + '|' + convert(varchar(12),seguros)                                        + '|' +  
   convert(varchar(12),otros)                              + '|' + convert(varchar(12),vlr_cuota)                                  + '|' + estado                                                              + '|' + 
   convert(varchar(12),capitalizado)                       + '|' + @w_pdf                                                          + '|' + case when @i_param5 = 'S' then isnull(@w_mail,'') else '' end       + '|' + 
   isnull(@w_dir_banco,                               ' ') + '|' + isnull(@w_ciu_ofici,                                       ' ') + '|' + isnull(@w_tel_ofici,                                           ' ') + '|' +
   isnull(@w_alianza,                                 ' ') + '|' + isnull(@w_desalianza,                                      ' ') + '|' + isnull(@w_fecha_proceso,                                       ' ') + '|' +
   isnull(convert(varchar(10),round(@w_tasa_seg_ind,4)),0) + '|' + isnull(convert(varchar(10),round(@w_tasa_seg_1_perd,4)),     0) + '|' + isnull(convert(varchar(10),round(@w_tasa_seg_exequias,4)),       0) + '|' +
   isnull(convert(varchar(10),round(@w_tasa_seg_danos,4)),0) + '|' + isnull(convert(varchar(10),round(@w_valor_total_seg,@w_num_dec)),0) + '|' + convert(varchar(12),cuota_cap)                                + '|' +
   convert(varchar(12),cuota_int)                          + '|' + convert(varchar(12),cuota_mora) + '|' +
   isnull(convert(varchar(10),@w_div_vig )             ,0) + '|' + isnull(convert(varchar(10),@w_cuota_cap)                    ,0) + '|' + isnull(convert(varchar(10),@w_sld_cap_div)                      ,0)
   
   from #tmp_tabla_msv 
  -- order by dividendo

   if @@error <> 0
   begin
      select @w_error = 710001
      goto ERROR
   end
   
   drop table #tmp_tabla_msv
   drop table #cap

   update #operaciones 
   set estado = 'P'
   where banco = @w_banco 

end -- while

   /* GENERACION ARCHIVO PLANO */
   Print '--> Path Archivo Resultante'

   select @w_path_destino = ba_path_destino
   from cobis..ba_batch
   where ba_batch = @w_proceso

   if @@rowcount = 0 Begin
      select @w_error = 720004,
      @w_msg = 'No Existe path_destino para el proceso : ' +  cast(@w_proceso as varchar)
      GOTO ERROR
   end 

   select @w_s_app = pa_char
   from cobis..cl_parametro
   where pa_producto = 'ADM'
   and   pa_nemonico = 'S_APP'

   if @@rowcount = 0 Begin
      select @w_error = 720014,
      @w_msg = 'NO EXISTE RUTA DEL S_APP'
      GOTO ERROR   
   end 

   -- Arma Nombre del Archivo
   print 'Generar el archivo plano AMORTIZACION_CARTERA_MSV_AAAAMMDD.txt !!!!! ' 

   select @w_nombre_archivo = @w_path_destino + 'AMORTIZACION_CARTERA_MSV_' + @w_fecha_final + '.txt' 
   print @w_nombre_archivo

   select @w_cmd       =  'bcp "select cadena from cob_cartera..tmp_plano_msv" queryout ' 
   select @w_comando   = @w_cmd + @w_nombre_archivo + ' -b5000 -c -t"|" -T -S '+ @@servername + ' -e AMORTIZACION_CARTERA_MSV.err' 
   --print @w_comando
   exec @w_error = xp_cmdshell @w_comando

   if @w_error <> 0 Begin
      select @w_msg = 'Error Generando BCP' + @w_comando
      goto ERROR 
   end   

/* OBTIENE USUARIO PARA FTP EL CUAL SE INGRESA DESDE EL MODULO DE SEGURIDAD */
select @w_passcryp = up_password,
       @w_login  = up_login
from   cobis..ad_usuario_xp
where  up_equipo = 'F'

if @@rowcount = 0 begin
  print 'Error lectura Usuario Notificador de Correos '
  return 1
end

/* DESCIFRA PASSWORD */
exec @w_return = CIFRAR...xp_decifrar 
     @i_data = @w_passcryp,
     @o_data = @w_password out

if @w_return <> 0
begin
  print 'Error lectura Usuario Notificador de Correos '
  return 1
end


/* OBTIENE DIRECCION DEL SERVIDOR FTP */
select @w_FtpServer = pa_char
from   cobis..cl_parametro
where  pa_producto = 'MIS'
and    pa_nemonico = 'FTPSRV'
if @@rowcount = 0 begin
  print 'Error lectura Servidor de Notificacion de Correos '
  return 1 
end

/* ELIMINA ARCHIVO INSTRUCCIONES FTP */
select @w_tmpfile = @w_path_destino + @s_user + '_' + 'fuente_ftp_amort'

select @w_tmpfile

select @w_cmd = 'del ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

/* CREA ARCHIVO INSTRUCCIONES FTP */
select @w_cmd = 'echo '  + @w_login +  '>> ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

select @w_cmd = 'echo ' +  @w_password + '>> ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

select @w_cmd = 'echo ' + 'cd tablas_amortizacion\a_procesar '  + ' >> ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

select @w_cmd = 'echo ' + 'put  ' + @w_nombre_archivo + ' >> ' + @w_tmpfile 

exec xp_cmdshell @w_cmd

if @w_error <> 0 begin
   print 'ERROR Realizando Transferencia de Correo '
   return -1 
end 


select @w_cmd = 'echo ' + 'quit ' + '>> ' + @w_tmpfile 
exec xp_cmdshell @w_cmd
  
/* EJECUTA FTP */
select @w_cmd = 'ftp -s:' + @w_tmpfile + ' ' + @w_FtpServer
exec xp_cmdshell @w_cmd

if @@error <> 0  Begin
   print 'Error Transfiriendo Extracto a Notificador de Correos'
   return 1
end
  
select @w_cmd = 'del ' + @w_tmpfile 
exec xp_cmdshell @w_cmd

delete tmp_plano_msv
where cadena >= ''

set rowcount 0

delete tmp_interes_amortiza_msv 
where cuota >= 0

delete tmp_colateral_msv
where tipo_sub >= ''

return 0

ERROR:

if @w_deshacer_tran = 'S'                                          -- REQ 175: PEQUEÑA EMPRESA
   rollback tran   
   
delete tmp_interes_amortiza_msv 
where cuota >= 0

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error
go
