/************************************************************************/
/*      Archivo:                modopint.sp                             */
/*      Stored procedure:       sp_modificar_operacion_int              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre, Rodrigo Garces      */
/*      Fecha de escritura:     Ene. 1998                               */
/************************************************************************/
/* IMPORTANTE                                                           */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* COBISCORP S.A.representantes exclusivos para el Ecuador de la        */
/* AT&T                                                                 */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier autorizacion o agregado hecho por alguno de sus            */
/* usuario sin el debido consentimiento por escrito de la               */
/* Presidencia Ejecutiva de COBISCORP o su representante                */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Modifica una operacion de Cartera con sus rubros asociados y su */
/*      tabla de amortizacion                                           */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR             RAZON                         */
/* FEB 2006     Fabian Quintero       Corr. para el BAC def.5961        */
/* SEP-06-2006  Elcira Pelaez         Correccion manejo Factoring BAC   */
/* Abr-10-2008  MRoa                  Validación plazo y monto de       */
/*                                    aprobación                        */
/* ACT-25-2008                        Cambios para reliquidar con       */
/*                                    fecha de liquidacion segun        */
/*                                    BANCAMIA y tambien se actualiza   */
/*                                    para no validar monto y plazos    */
/*                                     si la operacion est ya desembolsa*/
/* EPB: JUL-06-2010                   Inc. 00129 Dia Pago               */
/* 06/ENE/2017  Lorena Regalado       Incluir concepto de agrupamiento  */
/*                                    de operaciones                    */
/* 15/Abr/2019   Adriana Giler        Incluir conceptos de Campos de    */
/*                                    Grupales                          */ 
/* 22/Nov/2019   Luis Ponce           Pasar i_grupal al sp_gentabla para*/
/*                                   que calcule INT Indiv. por la regla*/
/* 03/Abr/2020   Luis Ponce             CDIG. Ajustes creacion operacion*/
/* 05/Nov/2020   EMP-JJEC             Rubros Financiados                */
/* 06/Ene/2021   P.Narvaez  Tipo de Reestructuracion/Tipo Renovacion    */
/* 06/Oct/2021   J.Hernandez      Se actualiza el plazo del prestamo    */
/*                                 debido a que se encuentra en 0       */
/* 06/Ene/2022   G. Fernandez     Ingreso de nuevo parametro de grupo   */
/*                                contable                              */
/* 15/Mar/2022   K. Rodriguez     Ajuste control cálculo de plazo/cuota */
/* 22/03/2022   Kevin Rodríguez   Cambio Val defecto de param grupo     */
/* 09/05/2022   Kevin Rodríguez   Quitar fecha primer ven. Diferimiento */
/* 01/06/2022   Guisela Fernandez Se comenta prints                     */
/* 17/06/2022   Kevin Rodriguez   Envío param fecha_primer_ven(gentabla)*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_modificar_operacion_int')
    drop proc sp_modificar_operacion_int
go
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

---NR000353
create proc sp_modificar_operacion_int
   @s_user                     login        = null,
   @s_sesn                     int          = null,
   @s_date                     datetime     = null,
   @s_term                     varchar(30)  = null,
   @s_ofi                      smallint     = null,
   @i_calcular_tabla           char(1)      = 'N',
   @i_tabla_nueva              char(1)      = 'S',
   @i_operacionca              int          = null,
   @i_banco                    cuenta       = null,
   @i_anterior                 cuenta       = null,
   @i_migrada                  cuenta       = null,
   @i_tramite                  int          = null,
   @i_cliente                  int          = null,
   @i_nombre                   descripcion  = null,
   @i_sector                   catalogo     = null,
   @i_toperacion               catalogo     = null,
   @i_oficina                  smallint     = null,
   @i_moneda                   smallint     = null,
   @i_comentario               varchar(255) = null,
   @i_oficial                  smallint     = null,
   @i_fecha_ini                datetime     = null,
   @i_fecha_fin                datetime     = null,
   @i_fecha_ult_proceso        datetime     = null,
   @i_fecha_liq                datetime     = null,
   @i_fecha_pri_cuot           datetime     = null,
   @i_fecha_reajuste           datetime     = null,
   @i_monto                    money        = null,
   @i_monto_aprobado           money        = null,
   @i_destino                  catalogo     = null,
   @i_lin_credito              cuenta       = null,
   @i_ciudad                   int          = null,
   @i_estado                   tinyint      = null,
   @i_periodo_reajuste         smallint     = null,
   @i_reajuste_especial        char(1)      = null,
   @i_tipo                     char(1)      = null,
   @i_forma_pago               catalogo     = null,
   @i_cuenta                   cuenta       = null,
   @i_dias_anio                smallint     = null,
   @i_tipo_amortizacion        varchar(10)  = null,
   @i_cuota_completa           char(1)      = null,
   @i_tipo_cobro               char(1)      = null,
   @i_tipo_reduccion           char(1)      = null,
   @i_aceptar_anticipos        char(1)      = null,
   @i_precancelacion           char(1)      = null,
   @i_operacion                char(1)      = null,
   @i_tipo_aplicacion          char(1)      = null,
   @i_tplazo                   catalogo     = null,
   @i_plazo                    int          = null,
   @i_tdividendo               catalogo     = null,
   @i_periodo_cap              int          = null,
   @i_periodo_int              int          = null,
   @i_dist_gracia              char(1)      = null,
   @i_gracia_cap               int          = null,
   @i_gracia_int               int          = null,
   @i_dia_fijo                 int          = null,
   @i_cuota                    money        = null,
   @i_evitar_feriados          char(1)      = null,
   @i_num_renovacion           int          = null,
   @i_renovacion               char(1)      = null,
   @i_mes_gracia               tinyint      = null,
   @i_formato_fecha            int          = 101,
   @i_upd_clientes             char(1)      = null,
   @i_dias_gracia              smallint     = null,
   @i_reajustable              char(1)      = null,
   @i_salida                   char(1)      = 'S',
   @i_dias_clausula            int          = null,
   @i_periodo_crecimiento      smallint     = null,
   @i_tasa_crecimiento         float        = null,
   @i_control_tasa             char(1)      = 'S',
   @i_direccion                tinyint      = null,
   @i_opcion_cap               char(1)      = null,
   @i_tasa_cap                 float        = null,
   @i_dividendo_cap            smallint     = null,
   @i_tipo_cap                 char(1)      = null,
   @i_clase_cartera            catalogo  = null,
   @i_origen_fondos            catalogo     = null,
   @i_tipo_crecimiento         char(1)      = null,
   @i_num_reest                int          = null,
   @i_base_calculo             char(1)      = null,
   @i_ult_dia_habil            char(1)      = null,
   @i_recalcular               char(1)      = null,
   @i_tasa_equivalente         char(1)      = null,
   @i_tipo_empresa             catalogo     = null,
   @i_validacion               catalogo     = null,
   @i_fondos_propios           char(1)      = null,
   @i_ref_exterior             cuenta       = null,
   @i_sujeta_nego              char(1)      = null,
   @i_ref_red                  varchar(24)  = null,
   @i_tipo_redondeo            tinyint      = null,
   @i_causacion                char(1)      = null,
   @i_tramite_ficticio         int          = null,
   @i_grupo_fact               int          = null,
   @i_convierte_tasa           char(1)      = null,
   @i_bvirtual                 char(1)      = null,
   @i_extracto                 char(1)      = null,
   @i_fec_embarque             datetime     = null,
   @i_fec_dex                  datetime     = null,
   @i_num_deuda_ext            cuenta       = null,
   @i_num_comex                cuenta       = null,
   @i_pago_caja                char(1)      = null,
   @i_nace_vencida             char(1)      = null,
   @i_calcula_devolucion       char(1)      = null,
   @i_oper_pas_ext             varchar(64)  = null,
   @i_reestructuracion         char(1)      = null,
   @i_mora_retroactiva         char(1)      = null,
   @i_prepago_desde_lavigente  char(1)      = null,
   @i_operacion_activa         int          = null,
   @i_actualiza_rubros         char(1)      = 'S',
   @i_valida_param             char(1)      = 'N',    --SE CAMBIA VALOR POR DEFECTO POR QUE LA METRIZ NO ES APLICABLE PARA MX
   @i_signo                    char(1)      = null,
   @i_factor                   float        = null,
   @i_gracia_pend              char(1)      = 'N',                -- REQ 175: PEQUEÑA EMPRESA
   @i_divini_reg               smallint     = null,               -- REQ 175: PEQUEÑA EMPRESA
   @i_crea_ext                 char(1)      = null,
   @i_simulacion_tflex         char         = 'N',
   @i_grupal                   char(1)      = null,     --LRE 06/ENE/2017
   @i_dia_pago                 int          = null,     --LRE 08/ABR/2019
   @i_fecha_fija               char(1)      = 'S',      --LRE 08/ABR/2019
   @i_regenera_rubro           char(1)      = 'S',      --AGI 28/MAY/2019
   @i_tasa             		   float		= null, 	--SRO Santander
   @i_grupo                    int          = null,     --AGI TeCreemos     -- KDR Se respeta el parámetro enviado
   @i_ref_grupal               cuenta       = null,     --AGI TeCreemos
   @i_es_grupal                char(1)      = 'N',      --AGI TeCreemos
   @i_fondeador             tinyint     = null,     --AGI TeCreemos 
   @i_fecha_dispersion         datetime     = null,
   @i_tipo_renovacion          char(1)      = null,
   @i_tipo_reest               char(1)      = null,
   @i_grupo_contable           catalogo      = null, --GFP 06/Ene/2022
   @o_msg_msv                  varchar(255) = null out
as

declare
   @w_sp_name                  descripcion,
   @w_error                    int,
   @w_fecha_reajuste           datetime,
   @w_fecha_fin                datetime,
   @w_fecha_f                  char(10),
   @w_num_dec                  tinyint,
   @w_plazo                    int,
   @w_tplazo                   catalogo,
   @w_cuota                    money,
   @w_dias_gracia              int,
   @w_monto_tmp                money,
   @w_monto_aprobado_tmp       money,
   @w_num_periodo_d            smallint,
   @w_periodo_d                catalogo,
   @w_actualiza_rubros         char(1),
   @w_dias_dividendo           int,
   @w_dias_aplicar             int,
   @w_operacionca              varchar(30),
   @w_tipo                     char(1),
   @w_tipo_plazo               catalogo,
   @w_plazo_op       smallint,
   @w_tdividendo               catalogo,
   @w_periodo_cap              int,
   @w_tipo_amortizacion        varchar(10),
   @w_max_dia_grac             int,
   @w_sal_min_cla_car          int,
   @w_sal_min_vig              money,
   @w_estado                   tinyint,
   @w_valor_clase              money,
   @w_tasa_eq                  char(1),
   @w_cliente_ficticio         int,
   @w_dias_anio                int,
   @w_dias_prestamo            int,
   @w_convierte_tasa           char(1),
   @w_estado_cancelado         tinyint,
   @w_estado_no_vigente        tinyint,
   @w_oficial_original         smallint,
   @w_nace_vencida             char(1),
   @w_toperacion               catalogo,
   @w_tipo_linea               catalogo,
   @w_calcula_devolucion       char(1),
   @w_concepto_interes         catalogo,
   @w_concepto_cenrie          catalogo,
   @w_concepto_micseg          catalogo,
   @w_concepto_exequi          catalogo,
   @w_prueba_int               float,
   @w_estado_op                tinyint,
   @w_oficina                  int,
   @w_gerente                  int,
   @w_cliente                  int,
   @w_moneda                   int,
   @w_fecha_cartera            datetime,
   @w_dias_contr               int,
   @w_dias_hoy                 int,
   @w_llave_activa             cuenta,
   @w_activa                   int,
   @w_fecha_ult_proceso        datetime,
   @w_op_relacionada           int,
   @w_ciudad_nacional          int,
   @w_cod_entidad              catalogo,
   @w_bandera_valor            char(1),
   @w_nombre                   descripcion,
   @w_estado_actual            smallint,
   @w_op_naturaleza            char(1),
   @w_rubros_basicos           int,
   @w_calcular_tabla_sv        char(1),
   @w_rowcount                 int,
   @w_control_dia_pago         char(1),
   @w_pa_dimive                tinyint,
   @w_pa_dimave                tinyint,
   @w_parametro_fag            catalogo,
   @w_valor_seguros            money,          -- Req. 366 Seguros
   @w_tramite                  int,
   @w_num_dias                 int,
   @w_tr_tipo                  char(1),
   @w_subtipo_linea            catalogo,        --LRE 06/ENE/2017
   @w_grupo                    int,
   @w_ref_grupal               cuenta , 
   @w_es_grupal                char(1) ,
   @w_fondeador                tinyint,
   @w_dias_di                  smallint,
   @w_plazoccatmp              int,              --JCHS
   @w_cambio_plazo             char(1),
   @w_tdividendo_orig          catalogo

/* CARGAR VALORES INICIALES */
select
@w_calcular_tabla_sv = @i_calcular_tabla,
@w_sp_name           = 'sp_modificar_operacion_int'

/* CONTROLAR DIA MINIMO DEL MES PARA FECHAS DE VENCIMIENTO */
select @w_pa_dimive = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'DIMIVE'
and   pa_producto = 'CCA'

/* CONTROLAR DIA MAXIMO DEL MES PARA FECHAS DE VENCIMIENTO */
select @w_pa_dimave = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'DIMAVE'
and   pa_producto = 'CCA'

select @w_dias_contr = pa_smallint
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'DCTRA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error = 710215
   goto ERROR
end

select @w_fecha_cartera = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7  -- 7 pertence a Cartera

--- ESTADOS
select @w_estado_cancelado = es_codigo
from ca_estado where es_descripcion = 'CANCELADO'

select @w_estado_no_vigente = es_codigo
from ca_estado where es_descripcion = 'NO VIGENTE'

select @w_max_dia_grac = pa_int
from cobis..cl_parametro
where pa_producto = 'CCA'
and  pa_nemonico = 'MDG'
set transaction isolation level read uncommitted

select @w_concepto_interes = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_concepto_cenrie = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CENRIE'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_concepto_micseg = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'MICSEG'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_concepto_exequi = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'EXEQUI'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION FAG
select @w_parametro_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CMFAGP'

if @w_max_dia_grac < @i_dias_gracia begin
   select @w_error = 701180
   goto ERROR
end

select
@i_operacionca       = opt_operacion,
@w_num_periodo_d     = opt_periodo_int,
@w_periodo_d         = opt_tdividendo,
@w_tipo_plazo        = opt_tplazo,
@w_plazo_op          = opt_plazo,
@i_plazo             = isnull(@i_plazo,  opt_plazo),
@w_tdividendo_orig   = opt_tdividendo,
@w_tdividendo        = isnull(@i_tdividendo, opt_tdividendo),
@w_periodo_cap       = opt_periodo_cap,
@w_tipo_amortizacion = ltrim(rtrim(opt_tipo_amortizacion)),
@w_tasa_eq           = opt_usar_tequivalente,
@w_fecha_ult_proceso = opt_fecha_ult_proceso,
@w_estado            = opt_estado,
@w_tipo              = opt_tipo,
@w_dias_anio         = opt_dias_anio,
@w_convierte_tasa    = opt_convierte_tasa,
@w_toperacion        = opt_toperacion,
@w_estado_op         = opt_estado,
@w_oficina           = opt_oficina,
@w_gerente           = opt_oficial,
@w_cliente           = opt_cliente,
@w_moneda            = opt_moneda,
@w_tipo_linea        = opt_tipo_linea,
@w_nombre            = opt_nombre,
@w_op_naturaleza     = opt_naturaleza,
@i_tdividendo        = isnull(@i_tdividendo,  opt_tdividendo),
@i_periodo_cap       = isnull(@i_periodo_cap, opt_periodo_cap),
@i_monto             = isnull(@i_monto,       opt_monto),
@w_tramite           = opt_tramite,
@w_subtipo_linea     = opt_subtipo_linea,    --LRE 06/ENE/2017
@w_grupo             = opt_grupo,
@w_ref_grupal        = opt_ref_grupal,
@w_es_grupal         = opt_grupal,
@w_fondeador         = opt_fondeador
from ca_operacion_tmp
where (opt_banco = @i_banco) or (opt_operacion  = @i_operacionca)

-- FQ REQ 392: LAS OBLIGACIONES EN TRAMITE NO DEBEN CALCULAR TABLA FLEXIBLE DEBIDO A QUE NO SE CONOCE EL FLUJO FINAL
--             Y LAS POLITICAS DE GENERACION DE TFLEXIBLE PODRIAN DETENER EL RUTEO DEL TRAMITE

--PRINT 'en modopint subtipoLINEA '+ @w_subtipo_linea

if @i_base_calculo = 'C' select @i_base_calculo = 'E' --LPO CDIG Ajustes Creacion/Modificacion Operacion

if @w_estado_op = 99 and @i_simulacion_tflex = 'N'
and @w_tipo_amortizacion = (select pa_char
                            from   cobis..cl_parametro with (nolock)
                            where  pa_producto  = 'CCA'
                            and    pa_nemonico  = 'TFLEXI')
begin

   select @i_periodo_cap       = isnull(@i_periodo_cap,1),
          @i_periodo_int       = isnull(@i_periodo_int,1),
          @i_tdividendo        = 'M',
          @i_plazo             = isnull(@i_plazo,tr_plazo),
          @i_tplazo            = isnull(@i_tplazo,'M'),
          @i_tipo_amortizacion = 'FRANCESA'
   from cob_credito..cr_tramite
   where tr_tramite = @w_tramite

   if @i_periodo_int = 0
   begin
      select @i_periodo_cap = 1,
             @i_periodo_int = 1
   end

   if @i_periodo_cap < @i_periodo_int
   begin
      select @i_periodo_cap = @i_periodo_int
   end

end
-- REQ. 366 GENERA MONTO BASE DE LA OPERACION
-- Validacion Seguros asociados

if exists (select 1 from cob_credito..cr_seguros_tramite
           where st_tramite = @w_tramite)
begin

   select @w_valor_seguros = isnull(sum(isnull(ps_valor_mensual,0) * isnull(datediff(mm,as_fecha_ini_cobertura,as_fecha_fin_cobertura),0)),0)
   from cob_credito..cr_seguros_tramite with (nolock),
        cob_credito..cr_asegurados      with (nolock),
        cob_credito..cr_plan_seguros_vs
   where st_tramite           = @w_tramite
   and   st_secuencial_seguro = as_secuencial_seguro
   and   as_plan              = ps_codigo_plan
   and   st_tipo_seguro       = ps_tipo_seguro
   and   ps_estado            = 'V'
   and   as_tipo_aseg         = (case when ps_tipo_seguro in(2,3,4) then 1 else as_tipo_aseg end)

   select @i_monto = isnull((@i_monto - @w_valor_seguros),0) -- Otra forma de obtener el monto sin seguros es tomar el @i_monto y restarle el valor total
   from cob_credito..cr_tramite with (nolock) -- de los seguros, valor que se obtiene con el select que se realiza en la operacion C
   where tr_tramite = @w_tramite              -- del SP cob_credito..sp_seguros_tramite.

   select @i_monto_aprobado = @i_monto

end  -- Fin Generar monto base de la operación Req. 366

select
@w_operacionca = convert(varchar,  @i_operacionca),
@i_oficina     = isnull(@i_oficina,@w_oficina),
@i_oficial     = isnull(@i_oficial,@w_gerente),
@i_cliente     = isnull(@i_cliente,@w_cliente),
@i_nombre      = isnull(@i_nombre, @w_nombre),
@i_moneda      = isnull(@i_moneda, @w_moneda),
@s_date        = isnull(@s_date,   @w_fecha_cartera)

---Inc00129
if @w_tipo = 'C' or @w_tipo = 'R'
   select @i_dia_fijo = datepart(dd, @i_fecha_ini)

--LPO CDIG. Ajustes creacion operacion INICIO

--GFP cambios para tipo de plazo 28D
select @w_dias_di = @i_periodo_int * td_factor
from   ca_tdividendo
Where  td_tdividendo = @i_tdividendo

IF (@i_fecha_fija = 'N')
   select @i_dia_fijo = 0
else
begin
	if(@w_dias_di % 30 <> 0 )
	BEGIN
	select @w_error = 711100
	goto ERROR
	end
end
   
--LPO CDIG. Ajustes creacion operacion FIN
---Inc00129

-- CONSULTA CODIGO DE FINAGRO EN PARAMETRO GENERAL
select  @w_cod_entidad = pa_char
from    cobis..cl_parametro
where   pa_nemonico = 'FINAG'
and     pa_producto = 'CCA'
set transaction isolation level read uncommitted

if @i_prepago_desde_lavigente = 'S' and (@w_tipo <> 'R' or @w_tipo_linea <> @w_cod_entidad)
begin
   select @w_error = 710463
   goto ERROR
end

-- VALIDACION DE LA FECHA DE INICIO DE LA OPERACION
-- PARAMETRO CODIGO CIUDAD FERIADOS NACIONALES

--if  @w_tipo_amortizacion <> 'MANUAL' and @w_estado_op = @w_estado_no_vigente
if  @i_tipo_amortizacion <> 'MANUAL' and @w_estado_op = @w_estado_no_vigente
begin
   select @w_ciudad_nacional = pa_int
   from   cobis..cl_parametro
   where  pa_nemonico = 'CIUN'
   and    pa_producto = 'ADM'
   set transaction isolation level read uncommitted

   if exists(select 1
             from   cobis..cl_dias_feriados
             where  df_fecha   = @i_fecha_ini
             and    df_ciudad  = @w_ciudad_nacional)
   begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         print 'Fecha Inicio Operacion es Festivo Nacional: ' + cast(@i_fecha_ini as varchar)
      else
	  */
      select @o_msg_msv = 'Fecha Inicio Operacion es Festivo Nacional: ' + cast(@i_fecha_ini as varchar)

      select @w_error = 710471
      goto ERROR
   end
end

if @w_tipo in ('C','R') and convert(varchar(24),@i_operacionca) <> @i_banco
begin
   if @i_cliente <> @w_cliente
   begin
   --PRINT 'modopint.sp @i_cliente ' + cast(@i_cliente as varchar) + ' @w_cliente ' + cast(@w_cliente as varchar)
      select @w_error = 710454
      goto ERROR
   end
end

select @w_dias_hoy = datediff(dd,@i_fecha_ini,@w_fecha_cartera)

if @w_dias_hoy > @w_dias_contr
begin
   select @w_error = 710212
   goto ERROR
end

select @w_tipo_linea       = dt_tipo_linea,
       @w_control_dia_pago = dt_control_dia_pago
from   ca_default_toperacion
where  dt_toperacion = @w_toperacion
and    dt_moneda     = @i_moneda

if @w_tipo = 'D' and @i_tramite_ficticio is not null
begin
   select @w_cliente_ficticio = tr_cliente
   from   cob_credito..cr_tramite
   where  tr_tramite = @i_tramite_ficticio
   and    tr_toperacion = 'FAC'

   if @@rowcount = 0
   begin
    select @w_error = 710150
      goto ERROR
   end

   if @i_cliente <> @w_cliente_ficticio
   begin
      select @w_error = 710151
      goto ERROR
   end
end

-- TRANSACCION DE SERVICIO
exec @w_error  = sp_tran_servicio
@s_user      = @s_user,
@s_date      = @s_date,
@s_ofi       = @s_ofi,
@s_term      = @s_term,
@i_tabla     = 'ca_operacion',
@i_clave1    = @w_operacionca

if @w_error <> 0 begin
   --print 'error modopint.sp ...en sp_transervicio'
   goto ERROR
end

--GFP 06/Ene/2022 Transaccion de servicio para ca_operacion_datos_adicionales
exec @w_error  = sp_tran_servicio
@s_user      = @s_user,
@s_date      = @s_date,
@s_ofi       = @s_ofi,
@s_term      = @s_term,
@i_tabla     = 'ca_operacion_datos_adicionales',
@i_clave1    = @w_operacionca,
@i_clave2    = 'I',
@i_clave3    = 'A'

if @w_error <> 0 begin
   --print 'error modopint.sp ...en sp_transervicio'
   goto ERROR
end


--SI SE MODIFICO LA PERIODICIDAD ACTUALIZO TASAS EQUIVALENTES
if @w_num_periodo_d  = isnull(@i_periodo_int,@w_num_periodo_d)
   and @w_periodo_d  = isnull(@i_tdividendo,@w_periodo_d)
   and @w_tipo <> 'D'
   select @w_actualiza_rubros = 'N'
else
   select @w_actualiza_rubros = 'S'

-- SI EXISTEN RUBROS FINANACIADOS SE GENERA LA TABLA
if exists (select 1 from ca_rubro_op_tmp 
            where rot_operacion = @i_operacionca
              and rot_financiado = 'S' 
              and rot_fpago <> 'P')
begin
   select @i_calcular_tabla   = 'S',
          @i_actualiza_rubros = 'N',
          @i_regenera_rubro   = 'S'
end

--if ((@w_convierte_tasa = 'S' and @i_convierte_tasa = 'N') or (@w_convierte_tasa = 'N' and @i_convierte_tasa = 'S')) and @w_tipo_amortizacion <> 'MANUAL'
if ((@w_convierte_tasa = 'S' and @i_convierte_tasa = 'N') or (@w_convierte_tasa = 'N' and @i_convierte_tasa = 'S')) and @i_tipo_amortizacion <> 'MANUAL'
   select @w_actualiza_rubros = 'S',
   @i_calcular_tabla   = 'S'

---REFRESCAR LA TASA Y LA TABLA CUANDO DESMARCA TASA EQUIVALENTE
if (@w_tasa_eq = 'S' and @i_tasa_equivalente = 'N') or  (@w_tasa_eq = 'N' and @i_tasa_equivalente = 'S')
   select @w_actualiza_rubros = 'S',
   @i_calcular_tabla = 'S'

if @w_dias_anio <> @i_dias_anio
   select @w_actualiza_rubros = 'S'

---PARA OPERACIONES REESTRUCTURADAS

--if @i_reestructuracion = 'S' and ltrim(rtrim(@w_tipo_amortizacion)) <> 'MANUAL'
if @i_reestructuracion = 'S' and ltrim(rtrim(@i_tipo_amortizacion)) <> 'MANUAL'
   select @i_calcular_tabla   = 'S'

select @w_estado_actual = op_estado
from ca_operacion
where op_operacion = @i_operacionca

if @w_estado_actual  in (1,2,3,4,9) and @w_calcular_tabla_sv = 'N'
   select @i_calcular_tabla   = 'N'

--OBTENCION DE LOS DIAS DEL DIVIDENDO PARA DIAS CLAUSULA

select @i_dias_clausula = 0

---CONTROL PARA CREDITOS ROTATIVOS
select @w_tipo = opt_tipo
from ca_operacion_tmp
where opt_operacion = @i_operacionca

if @w_tipo is null or @w_tipo = ''
   select @w_tipo      = op_tipo
   from   ca_operacion
   where  op_operacion = @i_operacionca


if @w_tipo ='O' and ((@i_tipo_cobro <> 'A' and @i_tipo_cobro <> null) or
   (@i_tipo_reduccion <> 'N' and @i_tipo_reduccion <> null))
begin
   select @w_error = 710096
   goto ERROR
end

if @w_error <> 0 begin
   select @w_error = @w_error
   goto ERROR
end


---BANDERA PARA SABER SI SE HA DIGITADO UN VALOR DE CAPITAL O DE CUOTA FIJA PARA GENERAR LA TABLA DE AMORTIZACION
---ES NECESARIO CUANDO SE GENERA AUTOMATICAMENTE UNA TABLA DE AMORTIZACION A PARTIR DE OTRA, COMO EN EL CASO DE
---OPERACIONES DE REDESCUENTO
if @i_cuota = 0
   select @w_bandera_valor = 'A'   ---'A' GENERA TABLA DE AMORTIZACION PROPORCIONALMENTE DE ACUERDO AL PLAZO Y AL MONTO
else
   select @w_bandera_valor = 'D'   ---'D' GENERA TABLA DE AMORTIZACION DE ACUERDO AL VALOR DIGITADO EN EL FRONT-END

-- NR 293
declare
   @w_cto_fng_vencido   catalogo,
   @w_meses_fng_vencido int,
   @w_banco_anterior    cuenta,
   @w_fecha_limite_fng  datetime,
   @w_operacion_ant     int,
   @w_saldo_ant         money

select @w_cto_fng_vencido = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CFNGMV'
and    pa_producto = 'CCA'

select @w_meses_fng_vencido = pa_int
from   cobis..cl_parametro
where  pa_nemonico = 'MFNGMV'
and    pa_producto = 'CCA'

if exists(select 1
          from   ca_rubro_op
          where  ro_operacion = @i_operacionca
and    ro_concepto  = @w_cto_fng_vencido)
begin
   if not (@i_tdividendo = 'M' and @i_periodo_int = 1)
   begin
      return 711018
   end

   if (@i_anterior is not null) -- ALGUNA CLASE DE RENOVACION
   begin
      select @w_fecha_limite_fng = op_fecha_dex,
             @w_operacion_ant    = op_operacion
      from   ca_operacion
      where op_banco = @i_anterior

      select @w_saldo_ant = sum(am_acumulado-am_pagado)
      from   ca_amortizacion
      where  am_operacion = @w_operacion_ant
      and    am_concepto  = 'CAP'

      if @w_saldo_ant < @i_monto -- EL MONTO NO PUEDE SUPERAR AL ANTERIOR
      begin
         return 711019
      end
   end
   ELSE
   begin
  select @w_fecha_limite_fng = dateadd(mm, @w_meses_fng_vencido, @i_fecha_ini)
   end

   update ca_operacion_tmp
   set    opt_fecha_dex = @w_fecha_limite_fng
   where  opt_operacion = @i_operacionca
end
-- FIN 293


if @i_tipo is null
begin
   select  @i_tipo = dt_tipo
   from ca_default_toperacion
   where dt_toperacion = @w_toperacion
end

-- CCA 436 Normalizacion
select @w_tr_tipo = isnull(tr_tipo,'X')
from cob_credito..cr_tramite
where tr_tramite = @i_tramite
if @@rowcount  = 0
   select @w_tr_tipo = 'X'

/*CONTROL PLAZO LINEA*/
if isnull(@i_valida_param, 'S') = 'S' and @w_tr_tipo <> 'M' begin
   if @i_toperacion is null
      select @i_toperacion = @w_toperacion

   exec @w_error    = sp_parametros_matriz
   @i_fecha          = @w_fecha_ult_proceso,
   @i_toperacion     = @i_toperacion,  --LPO INC. 242 Interventoria
   @i_plazo          = @i_plazo,
   @i_tplazo         = @i_tplazo,
   @i_monto_valida   = @i_monto,
   @i_cliente        = @i_cliente,
   @o_msg            = @o_msg_msv out

   if @w_error <> 0 begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         print @o_msg_msv
      else
	  */
      select @o_msg_msv = @o_msg_msv + '.' + 'modopint.sp-->saliendo de sp_parametros_matriz' + cast(@w_error as varchar)

   return @w_error
   end
end

--CONTROL CAMBIO GARANTIA FAG PERIODICA A UNICA
if exists(select 1 from ca_rubro_op_tmp
where rot_operacion = @i_operacionca
and   rot_concepto  = @w_parametro_fag)
begin

   if @i_plazo = 1 begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         print 'Es necesario devolver la operacion a tramites para poder realizar el cambio a plazo unico'
      else
	  */
      select @o_msg_msv = 'Es necesario devolver la operacion a tramites para poder realizar el cambio a plazo unico'
      return @w_error
      --goto ERROR
   end
end


-- LGU-ini 10/abr/2017 calcular plazo y fecha de una interciclo
exec @w_error = sp_emergente_fecha
	@i_toperacion     = @i_toperacion,
	@i_cliente        = @i_cliente,
	@i_fecha_ini      = @i_fecha_ini,
	@i_plazo          = @i_plazo,
	@i_fecha_pri_cuot = @i_fecha_pri_cuot,
	@o_plazo          = @i_plazo          output,
	@o_fecha_pri_cuot = @i_fecha_pri_cuot output

if @w_error <> 0
begin
  --GFP se suprime print
  --print 'modopint.sp: sp_emergente_fecha.sp ... No existen Dividendoa para crear un Emergente ' + cast(@w_error as varchar)
  select @w_error = @w_error
  goto ERROR
end
-- LGU-fin 10/abr/2017 calcular plazo y fecha de una interciclo

--- MODIFICAR LA OPERACION TEMPORAL

exec @w_error = sp_operacion_tmp
@s_user                      = @s_user,
@s_sesn                      = @s_sesn,
@s_date                      = @s_date,
@i_operacionca               = @i_operacionca,
@i_banco                     = @i_banco,
@i_anterior                  = @i_anterior,
@i_migrada                   = @i_migrada,
@i_tramite                   = @i_tramite,
@i_cliente                   = @i_cliente,
@i_nombre                    = @i_nombre,
@i_sector                    = @i_sector,
@i_toperacion                = @i_toperacion,
@i_oficina                   = @i_oficina,
@i_moneda                    = @i_moneda,
@i_comentario                = @i_comentario,
@i_oficial                   = @i_oficial,
@i_fecha_ini                 = @i_fecha_ini,
@i_fecha_fin                 = @i_fecha_fin,
@i_fecha_ult_proceso         = @i_fecha_ult_proceso,
@i_fecha_liq                 = @i_fecha_liq,
@i_fecha_reajuste            = @i_fecha_reajuste,
@i_fecha_pri_cuot            = @i_fecha_pri_cuot,
@i_monto                     = @i_monto,
@i_monto_aprobado            = @i_monto_aprobado,
@i_destino                   = @i_destino,
@i_lin_credito               = @i_lin_credito,
@i_ciudad                    = @i_ciudad,
@i_estado                    = @i_estado,
@i_periodo_reajuste          = @i_periodo_reajuste,
@i_reajuste_especial         = @i_reajuste_especial,
@i_tipo                      = @i_tipo, --(Hipot/Redes/Normal)
@i_forma_pago                = @i_forma_pago,
@i_cuenta                    = @i_cuenta,
@i_dias_anio                 = @i_dias_anio,
@i_tipo_amortizacion         = @i_tipo_amortizacion,
@i_cuota_completa            = @i_cuota_completa,
@i_tipo_cobro                = @i_tipo_cobro,
@i_tipo_reduccion            = @i_tipo_reduccion,
@i_aceptar_anticipos         = @i_aceptar_anticipos,
@i_precancelacion            = @i_precancelacion,
@i_operacion                 = 'U',
@i_tipo_aplicacion           = @i_tipo_aplicacion,
@i_tplazo                    = @i_tplazo,
@i_plazo                     = @i_plazo,
@i_tdividendo                = @i_tdividendo,
@i_periodo_cap               = @i_periodo_cap,
@i_periodo_int               = @i_periodo_int,
@i_dist_gracia               = @i_dist_gracia,
@i_gracia_cap                = @i_gracia_cap,
@i_gracia_int                = @i_gracia_int,
@i_dia_fijo                  = @i_dia_fijo,
@i_evitar_feriados           = @i_evitar_feriados,
@i_num_renovacion            = @i_num_renovacion,
@i_renovacion                = @i_renovacion,
@i_mes_gracia                = @i_mes_gracia,
@i_cuota                     = @i_cuota,
@i_upd_clientes              = @i_upd_clientes,
@i_reajustable               = @i_reajustable,
@i_dias_clausula             = @i_dias_clausula,
@i_periodo_crecimiento       = @i_periodo_crecimiento,
@i_tasa_crecimiento          = @i_tasa_crecimiento,
@i_direccion                 = @i_direccion,
@i_opcion_cap                = @i_opcion_cap,
@i_tasa_cap                  = @i_tasa_cap,
@i_dividendo_cap             = @i_dividendo_cap,
@i_clase_cartera             = @i_clase_cartera,
@i_origen_fondos             = @i_origen_fondos,
@i_tipo_empresa              = @i_tipo_empresa,
@i_validacion                = @i_validacion,
@i_num_reest                 = @i_num_reest,
@i_base_calculo              = @i_base_calculo,
@i_ult_dia_habil             = @i_ult_dia_habil,
@i_recalcular                = @i_recalcular,
@i_tasa_equivalente          = @i_tasa_equivalente,
@i_fondos_propios            = @i_fondos_propios,
@i_ref_exterior              = @i_ref_exterior,
@i_sujeta_nego               = @i_sujeta_nego,
@i_ref_red                   = @i_ref_red,
@i_tipo_redondeo             = @i_tipo_redondeo,
@i_causacion                 = @i_causacion,
@i_tramite_ficticio          = @i_tramite_ficticio,
@i_grupo_fact                = @i_grupo_fact,
@i_convierte_tasa            = @i_convierte_tasa,
@i_bvirtual                  = @i_bvirtual,
@i_extracto                  = @i_extracto,
@i_pago_caja                 = @i_pago_caja,
@i_nace_vencida              = @i_nace_vencida,
@i_tipo_linea                = @w_tipo_linea,
@i_fec_embarque              = @i_fec_embarque,
@i_fec_dex                   = @i_fec_dex,
@i_num_deuda_ext             = @i_num_deuda_ext,
@i_num_comex                 = @i_num_comex,
@i_calcula_devolucion        = @i_calcula_devolucion,
@i_reestructuracion          = @i_reestructuracion,
@i_mora_retroactiva          = @i_mora_retroactiva,
@i_prepago_desde_lavigente   = @i_prepago_desde_lavigente,
@i_tipo_crecimiento          = @w_bandera_valor,
@i_oper_pas_ext              = @i_oper_pas_ext,
@i_grupal                    = @i_grupal,          --LRE 06/ENE/2017
@i_subtipo_linea             = @w_subtipo_linea,   --LRE 06/ENE/2017
@i_grupo                     = @i_grupo,                  --AGI TeCreemos
@i_ref_grupal                = @i_ref_grupal,             --AGI TeCreemos
@i_es_grupal                 = @i_es_grupal,              --AGI TeCreemos
@i_fondeador                 = @i_fondeador,            --AGI TeCreemos
@i_tipo_renovacion           = @i_tipo_renovacion,
@i_tipo_reest                = @i_tipo_reest,
@i_grupo_contable            = @i_grupo_contable        --GFP 06/Ene/2022

if @w_error <> 0
begin
   --GFP se suprime print
   /*
   if @i_crea_ext is null
      print 'error modopint.sp ... saliendo de sp_operacion_tmp' + cast(@w_error as varchar)
   else
   */
   select @o_msg_msv = 'error modopint.sp ... saliendo de sp_operacion_tmp' + cast(@w_error as varchar)
   select @w_error = @w_error
   goto ERROR
end

---LLS88334 No habilitar las tablas manuales
--if ltrim(rtrim(@w_tipo_amortizacion)) = 'MANUAL'
if ltrim(rtrim(@i_tipo_amortizacion)) = 'MANUAL'
begin
   select @w_error = 723905
   goto ERROR
end   


--- ACTUALIZAR EL RUBRO DE CALCULO DE COMISIONES POR CONSULTAS A LA CENTRAL DE RIESGOS
--- ESTO SE HACE DEBIDO A QUE EL NUMERO DE CLIENTES CON CONSULTA A LA CENTRAL PUDO CAMBIAR
if exists(select 1 from ca_rubro_op_tmp
where rot_operacion = @i_operacionca
and   rot_concepto  = @w_concepto_cenrie)
begin

   exec @w_error = sp_rubro_tmp
   @s_user        = @s_user,
   @s_term        = @s_term,
   @s_date        = @s_date,
   @s_ofi         = @s_ofi,
   @i_operacion   = 'U',
   @i_operacionca = @i_operacionca,
   @i_concepto    = @w_concepto_cenrie,
   @i_crea_ext    = @i_crea_ext,
   @o_msg_msv     = @o_msg_msv out

   if @w_error <> 0 return @w_error

end

--- ACTUALIZAR EL RUBRO MICROSEGURO PREVIENDO CAMBIOS EN EL VALOR DESDE TRAMITES
if exists(select 1 from ca_rubro_op_tmp
where rot_operacion = @i_operacionca
and   rot_concepto  = @w_concepto_micseg)
begin
   exec @w_error = sp_rubro_tmp
   @s_user        = @s_user,
   @s_term        = @s_term,
   @s_date        = @s_date,
   @s_ofi         = @s_ofi,
   @i_operacion   = 'U',
   @i_operacionca = @i_operacionca,
   @i_concepto    = @w_concepto_micseg,
   @i_crea_ext    = @i_crea_ext,
   @o_msg_msv     = @o_msg_msv out

   if @w_error <> 0 return @w_error

end

--- ACTUALIZAR EL RUBRO SEGURO EXEQUIAL PREVIENDO CAMBIOS EN EL VALOR DESDE TRAMITES
if exists(select 1 from ca_rubro_op_tmp
where rot_operacion = @i_operacionca
and   rot_concepto  = @w_concepto_exequi)
begin
   exec @w_error = sp_rubro_tmp
   @s_user        = @s_user,
   @s_term        = @s_term,
   @s_date        = @s_date,
   @s_ofi         = @s_ofi,
   @i_operacion   = 'U',
   @i_operacionca = @i_operacionca,
   @i_concepto    = @w_concepto_exequi,
   @i_crea_ext    = @i_crea_ext,
   @o_msg_msv     = @o_msg_msv out

   if @w_error <> 0 return @w_error

end

/*ACTUALIZA SIGNO Y SPREAD OPERACIONES	QUE UTILIZAN LA MATRIZ DE TASA_MAX Y TASA_MIN */
if (@i_signo is not null and @i_factor is not null) Begin
   update ca_rubro_op_tmp set
   rot_signo           =  @i_signo,
   rot_factor          =  @i_factor
   where rot_operacion =  @i_operacionca
   and   rot_concepto  =  @w_concepto_interes
   if @@error <> 0 return 710002

End

--- ACTUALIZA EL CLIENTE EN LA OP PASIVA SOLO PARA DESEMBOLSO POR PRIMERA VEZ DESEMBOLSADO
--- EN CASO DE QUE EL DESEMBOLSO HALLA SIDO REVERSADO, Y SE ESTA DESEMBOLSADO NUEVAMENTE,
--- NO SE DEBE ACTUALIZAR EL CLIENTE EN LA PASIVA PORQUE EN EL CONSOLIDADOR, YA EXISTEN VALORES PARA ESE CLIENTE

if @w_tipo in ('C','R') and convert(varchar(24),@i_operacionca) = @i_banco
begin
   if @w_tipo = 'C'
   begin
      if exists (select 1  from ca_relacion_ptmo
                 where rp_activa = @i_operacionca)
      begin
         select @w_op_relacionada = rp_pasiva
         from ca_relacion_ptmo
         where rp_activa = @i_operacionca

         update ca_operacion
         set op_cliente = @i_cliente,
             op_nombre  = @i_nombre
        where op_operacion = @w_op_relacionada
      end
   end

   if @w_tipo = 'R'
   begin
      if exists (select 1  from ca_relacion_ptmo
                 where rp_pasiva = @i_operacionca)
      begin
         select @w_op_relacionada = rp_activa
         from ca_relacion_ptmo
         where rp_pasiva = @i_operacionca

         update ca_operacion
         set op_cliente = @i_cliente,
             op_nombre  = @i_nombre
         where op_operacion = @w_op_relacionada
      end
   end
end

---DIAS DE GRACIA CUANDO LLAMO DESDE RUBROS
select @w_dias_gracia =dit_gracia
from   ca_dividendo_tmp
where  dit_operacion = @i_operacionca
and    dit_dividendo = 1

if @i_dias_gracia is null
   select @i_dias_gracia = @w_dias_gracia

if @i_tipo_amortizacion is null
begin
   if @w_tipo_amortizacion = 'MANUAL' and @w_estado_actual = 0
   begin
      select  @i_calcular_tabla = 'N'
      --Print 'Si su tabla es manual, Actualizar la tabla de Amortizacion, BOTON TRANSMITIR'
 end
end

--if ltrim(rtrim(@w_tipo_amortizacion)) = 'MANUAL' and @w_tipo <> 'D'
if ltrim(rtrim(@i_tipo_amortizacion)) = 'MANUAL' and @w_tipo <> 'D'
   select  @i_calcular_tabla = 'N'

if  @w_op_naturaleza = 'A'
begin
   select @w_rubros_basicos = isnull(count(1),0)
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacionca
   and   (rot_tipo_rubro  = 'C' or  rot_tipo_rubro  = 'I' or   rot_tipo_rubro  = 'M')

   if @w_rubros_basicos < 3
   begin
      --GFP se suprime print
	  /*
      if @i_crea_ext is null
         PRINT 'modopint.sp entro a este error @w_rubros_basicos ' + cast(@w_rubros_basicos as varchar)
      else
	  */
      select @o_msg_msv = 'modopint.sp entro a este error @w_rubros_basicos ' + cast(@w_rubros_basicos as varchar)
      select @w_error = 710562
      goto ERROR
   end
end

if  @w_op_naturaleza = 'P'
begin
   select @w_rubros_basicos = isnull(count(1),0)
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacionca
   and    rot_tipo_rubro in ('C','I')

   if @w_rubros_basicos < 2
   begin
      select @w_error = 710562
      goto ERROR
   end
end

if @w_estado_actual  = 3
   select @i_calcular_tabla = 'N'

if @w_estado_actual  = 3 and ltrim(rtrim(@i_ref_grupal)) > ''
   select @i_calcular_tabla = 'S'

  
   
--RFP 126 FACTORING Para cambio de tasa
if @w_tipo =  'D' and @w_estado_actual = 0
   select @i_calcular_tabla = 'S'

   
SELECT @w_cambio_plazo = 'N'
if ((@w_plazo_op <> @i_plazo and isnull(@i_plazo, 0) > 0) OR ((@w_plazo_op = @i_plazo) AND (@w_tdividendo_orig <> @i_tdividendo))) AND @w_tr_tipo NOT IN ('R','E')
	SELECT @w_cambio_plazo = 'S'

 
if @i_calcular_tabla = 'S'
begin

   -- KDR Si es un Diferimiento de Préstamo, no se usa la fecha de primer vencimiento establecida a la operación para la generación de la tabla.
   if @i_tipo_reest = 'D'                      
      update ca_operacion_tmp 
      set opt_fecha_pri_cuot = NULL
      where opt_operacion = @i_operacionca
	  
	  if @@error <> 0
         return 701002
   
   exec @w_error       = sp_gentabla
      @i_operacionca      = @i_operacionca,
      @i_tabla_nueva      = @i_tabla_nueva,
      @i_dias_gracia      = @i_dias_gracia,
      @i_actualiza_rubros = @i_actualiza_rubros,
      @i_crear_op         = 'S',
      @i_control_tasa     = @i_control_tasa,
      @i_periodo          = @w_tdividendo,
      @i_operacion_activa = @i_operacion_activa,
      @i_gracia_pend      = @i_gracia_pend,                                -- REQ 175: PEQUEÑA EMPRESA
      @i_divini_reg       = @i_divini_reg,                                 -- REQ 175: PEQUEÑA EMPRESA
      @i_reestructuracion = @i_reestructuracion,                           -- PAQUETE 2 - REQ 212 BANCA RURAL - 28/JUL/2011
      @i_crea_ext         = @i_crea_ext,
      @i_simulacion_tflex = @i_simulacion_tflex,
      @i_tasa             = @i_tasa,									   --SRO Santander
      @i_regenera_rubro   = @i_regenera_rubro,                             --AGI 28/MAY/2019
      @i_grupal           = @i_grupal,       --LPO TEC Para que obtenga el INT de la regla para Individuales.
      @i_cambio_plazo     = @w_cambio_plazo,
	  @i_fecha_ven_pc     = @i_fecha_pri_cuot, -- KDR Actualizar tabla si se recibe Fecha vencimiento de primera cuota
      @o_fecha_fin        = @w_fecha_fin  out,
      @o_cuota            = @w_cuota      out,
      @o_plazo            = @w_plazo      out,
      @o_tplazo           = @w_tplazo     out,
      @o_msg_msv          = @o_msg_msv    out

   if @w_error <> 0 begin
      --print '(modopint.sp) Error al ejecutar sp_gentabla'
  select @w_error = @w_error
      goto ERROR
   end
      
   select @w_plazoccatmp = opt_plazo 
   from ca_operacion_tmp
   where opt_banco = @i_banco
   
   
   if(@w_plazoccatmp = 0 and @w_plazo > 0)
   begin
        update ca_operacion_tmp
		set opt_plazo = @w_plazo
		where opt_banco = @i_banco
		
		select @w_plazoccatmp = opt_plazo 
        from ca_operacion_tmp
        where opt_banco = @i_banco
   end
      
   --- ACTUALIZACION DE LA OPERACION
   if isnull(@i_periodo_reajuste,0) <> 0
   begin
      if @i_periodo_reajuste % @i_periodo_int = 0
         select @w_fecha_reajuste = dit_fecha_ven
         from   ca_dividendo_tmp
         where  dit_operacion = @i_operacionca
         and    dit_dividendo = @i_periodo_reajuste / @i_periodo_int
      else
         select @w_fecha_reajuste = dateadd(dd,td_factor*@i_periodo_reajuste, @i_fecha_ini)
         from ca_tdividendo
         where td_tdividendo = @i_tdividendo

      select @w_fecha_reajuste = isnull(@i_fecha_reajuste,@w_fecha_reajuste)
   end
   ELSE
      select @w_fecha_reajuste = '01/01/1900' --OJO

   if @i_salida = 'S'
   begin
      select @w_fecha_f  = convert(varchar(10),@w_fecha_fin,@i_formato_fecha)

      select @w_fecha_f,@w_cuota,@w_plazo,@w_tplazo,td_descripcion
      from   ca_tdividendo
      where  td_tdividendo = @w_tplazo

      select @i_clase_cartera

      select  c.valor
      from    cobis..cl_tabla t, cobis..cl_catalogo c
      where   c.tabla = t.codigo
      and     t.tabla = 'cr_clase_cartera'
      and     c.codigo = ltrim(rtrim(@i_clase_cartera))
      set transaction isolation level read uncommitted
   end
end

if @w_tipo = 'D'
begin   --PARA FACTORING
   update ca_operacion_tmp
   set opt_tdividendo = 'D'
   where opt_operacion = @i_operacionca
end

--PROCESAMIENTO OPERACION NACE VENCIDA
select @w_nace_vencida = opt_nace_vencida
from   ca_operacion_tmp
where  opt_operacion = @i_operacionca

if @w_nace_vencida = 'S'
begin
   update ca_operacion_tmp
   set    opt_fecha_fin = opt_fecha_ini
   where  opt_operacion = @i_operacionca

   if @@error <> 0
      return 701002

   update ca_dividendo_tmp
   set    dit_fecha_ven = dit_fecha_ini
   where  dit_operacion = @i_operacionca

   if @@error <> 0
      return 705043

   update ca_amortizacion_tmp
   set    amt_acumulado = amt_cuota
   where  amt_operacion = @i_operacionca

   if @@rowcount = 0
      return 705022

   --- CANCELACION DEL INTERES
   update ca_amortizacion_tmp
   set    amt_pagado    = 0,
          amt_acumulado = 0,
          amt_cuota     = 0,
          amt_estado    = @w_estado_cancelado
   where  amt_operacion = @i_operacionca
   and    amt_concepto = @w_concepto_interes

   if @@rowcount = 0
      return 705022
end

return 0

ERROR:

return @w_error
GO

