/************************************************************************/
/*   Archivo:              rubrotmp.sp                                  */
/*   Stored procedure:     sp_rubro_tmp                                 */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         R Garces                                     */
/*   Fecha de escritura:   Feb 95                                       */
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
/*   Da mantenimiento a la tabla ca_rubro_op_tmp                        */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* julio-24-2001   EPB               Calculo rubro tipo 'O'             */
/*                                   sobre rubro_asociado               */
/* sep-01-2005     EPB               heredar el mismo referencial para r*/
/*                                   juste con signo y puntos           */
/* mar-2006        FQ                NR 461                             */
/* abr-16-2006     EPB               defecto 6175                       */
/* May 2006        Elcira            Pelaez  Defecto 6487               */
/* AGO 2006        FQ                Defecto BAC                        */
/* AGO 2006        Elcira Pelaez     Defecto 7026                       */
/* AGO 29 2006     Elcira Pelaez     Defecto 7092                       */
/* feb-2007        E.Pelaez          DEF.7936 BAC                       */
/* ABR-2007        E.Pelaez          NR-244   BAC                       */
/* 2008-03-25      M.Roa             Comentar @i_porcentaje_cobrar en   */
/*                                   llamado sp_rubro_calculado         */
/* FEB-2012        L.Moreno          REQ 293 - Ajuste titulos consulta  */
/* ABR-2013        R.Reyes           REQ 353 - Alianzas                 */
/* 05/05/2017        M. Custode           Eliminaciond el conver tramite*/
/*                                        por i_banco                   */
/* 21/Oct/2020     EMP-JJEC          Optimización Rubros calculados     */
/* 05/Nov/2020     EMP-JJEC          Rubros Financiados                 */
/* 11/Nov/2020   P. Narvaez  Reestructuraciones desde Cartera           */
/* 19/11/2020      EMP-JJEC          Control Tasa INT Maxima/Minima     */
/* 19/05/2021   Paulina Quezada(PQU) Operación 'R' para UF simulación   */
/* 11/08/2021   Alfredo Monroy		 Se reutiliza columna ru_limite como*/
/*									 marca de rubro diferido (B.Finca)  */
/* 06/10/2021   Kevin Rodríguez      Se establece base_calculo para ru- */
/*                                   bros Valor Fijo y Porcentaje       */
/* 03/03/2022	Alfredo Monroy		 En case de que no se envie valor en*/
/*									 @i_financiado tomar de la ca_rubro */
/* 08/03/2022   Kevin Rodríguez      Ajuste Base Calculo a No financiados*/
/*                              y validación rub financiado aplica desemb*/
/* 16/05/2021   Kevin Rodríguez      Ajuste filtro de Rubro asociado    */
/* 18/05/2022   Kevin Rodríguez      Se comenta recálculo de Seguro     */
/* 01/06/2022   Guisela Fernandez    Se comenta prints                  */
/* 17/08/2022   Guisela Fernandez    Se actualiza valor de cuota a 0 en */
/*                                   la eliminación de rubros           */
/* 14/09/2022   Kevin Rodríguez      R193060 Tmp de Rubros Financiados  */
/* 13/10/2022   Kevin Rodríguez      R194789 No bloquear tabla para ac- */
/*                                  tualizar y borrar datos with rowlock*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rubro_tmp')
   drop proc sp_rubro_tmp
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO
---NR000353 partiendo de la verion 16

create proc sp_rubro_tmp (
@s_user                    login        = null,
@s_term                    varchar(30)  = null,
@s_date                    datetime     = null,
@s_ofi                     smallint,    
@s_rol                     smallint     = null,
@i_operacion               char(1)      = null,
@i_operacionca             int          = null,
@i_banco                   cuenta       = null,
@i_concepto                catalogo     = null,
@i_tipo_rubro              char(1)      = null,
@i_fpago                   char(1)      = null,
@i_prioridad               smallint     = null,
@i_paga_mora               char(1)      = null,
@i_provisiona              char(1)      = null,
@i_signo                   char(1)      = null, 
@i_factor                  float        = null,
@i_referencial             catalogo     = null,
@i_signo_reajuste          char(1)      = null,
@i_factor_reajuste         float        = null,
@i_referencial_reajuste    catalogo     = null,
@i_valor                   money        = null,
@i_porcentaje              float        = null,
@i_gracia                  money        = null,
@i_tipo_puntos             char(1)      = null,
@i_periodo_o               char(1)      = null,
@i_modalidad_o             char(1)      = null,
@i_externo                 char(1)      = 'S',
@i_control_monto_aprobado  char(1)      = 'S',
@i_banco_real              cuenta       = null,
@i_base_calculo            money        = null, -- KDR Se cambia a null por defecto.
@i_num_dec_tapl            tinyint      = null,
@i_limite                  char(1)      = null,
@i_periodo_c               smallint     = null, 
@i_tperiodo_c              catalogo     = null,
@i_iva_siempre             char(1)      = null,
@i_porcentaje_cobrar       float        = null,
@i_tipo_garantia           varchar(64)  = null,
@i_mante_rubro             char(1)      = 'N',
@i_numero_segv             varchar(255) = null,
@i_numero_codeu            tinyint      = 0,
@i_codigo_clientes         varchar(255) = null,
@i_negociacion             char(1)      = 'N',
@i_crea_ext                char(1)      = null,
@i_financiado              char(1)      = null,
@i_reest                   char(1)      = 'N',  --Desde Reestructuracion
@o_provisiona              char(1)      = null output,
@o_prioridad               tinyint      = null output,
@o_referencial             catalogo     = null output,
@o_valor_referencial       float        = null output,
@o_referencial_reaj        catalogo     = null output,
@o_signo_reaj              char(1)      = null output,
@o_valor_reaj              float        = null output,
@o_modalidad               char(1)      = null output,
@o_periodicidad            char(1)      = null output,
@o_msg_msv                 varchar(255) = null output
)
as
declare
   @w_sp_name                 descripcion,
   @w_toperacion              catalogo,
   @w_moneda                  tinyint,
   @w_fecha_ini               datetime,
   @w_num_dec                 tinyint,
   @w_monto                   money,
   @w_tipo_amortizacion       varchar(10),
   @w_referencia              varchar(255),
   @w_concepto                catalogo,
   @w_porcentaje              float,
   @w_prioridad               tinyint,
   @w_tipo_rubro              char(1),
   @w_tipo_r                  char(1),
   @w_provisiona              char(1),
   @w_referencial             catalogo,
   @w_deb_automatico          char(1),
   @w_signo_reaj              char(1),
   @w_valor_rubro             money,
   @w_valor                   money, 
   @w_signo_default           char(1),
   @w_valor_default           float,
   @w_sector                  catalogo,
   @w_error                   int,
   @w_descripcion             descripcion,
   @w_tipo_valor              catalogo,
   @w_desc_tipo               descripcion,
   @w_desc_referencial        descripcion,
   @w_valor_referencial       float,
   @w_tipo_puntos             char(1),
   @w_signo_maximo            char(1),
   @w_signo_minimo            char(1),
   @w_total_default           float,
   @w_desc_referencial_reaj   descripcion,
   @w_signo_maximo_reaj       char(1),
   @w_signo_minimo_reaj       char(1),
   @w_valor_reaj              float,
   @w_valor_maximo            float,
   @w_valor_minimo            float,
   @w_total_reaj              float,
   @w_valor_referencial_reaj  float,
   @w_valor_maximo_reaj       float,
   @w_total_maximo            float,
   @w_total_minimo            float,
   @w_total_maximo_reaj       float,
   @w_total_minimo_reaj       float,
   @w_valor_minimo_reaj       float,
   @w_clave1                  varchar(255),
   @w_clave2                  varchar(255),
   @w_porcentaje_aux          float,
   @w_num_periodo_d           smallint,
   @w_periodo_d               catalogo,
   @w_periodo_efa             catalogo,
   @w_forma_pago              char(1),
   @w_tipo_tasa               char(1),
   @w_modalidad_d             char(1),
   @w_modalidad_efa           char(1),
   @w_tasa_d                  float,
   @w_modalidad               char(1),
   @w_periodicidad            char(1),
   @w_desc_perio              descripcion,
   @w_periodicidad_anual      varchar(30),
   @w_tasa_efa                float,
   @w_ibc                     float,
   @w_cliente                 int,
   @w_dias_anio               smallint,
   @w_b_calculo               char(1),
   @w_principal               char(1),
   @w_tcero                   varchar(10),
   @w_tasa_tot_int            float,
   @w_num_dias                int,
   @w_tasa_seguro             float,
   @w_tasa_svda               float,
   @w_monto_aprobado          money,
   @w_estado                  tinyint,
   @w_monto_rubcap            money,
   @w_timbre                  catalogo,
   @w_clase_operacion         char(1),
   @w_capital_pag             money,
   @w_monto_orig              money,
   @w_saldo_operacion         char(1),
   @w_saldo_por_desem         char(1),
   @w_base_calculo            money ,
   @w_referencial_reaj        catalogo,
   @w_tasa_eq                 char(1),
   @w_num_dec_tapl            tinyint,
   @w_convierte_tasa          char(1),
   @w_limite                  char(1),
   @w_rango_min               money,
   @w_rango_max               money,
   @w_categoria_rubro         catalogo,
   @w_categoria_cliente       catalogo,
   @w_porcentaje_categoria    tinyint,
   @w_valor_catagoria         money,
   @w_rubro_asociado          catalogo,
   @w_valor_asociado          money,
   @w_factor_a                float,
   @w_tperiodo                catalogo,
   @w_desc_periodo            cuenta,
   @w_periodo                 smallint,
   @w_tipo_garantia           varchar(64),
   @w_valor_garantia          char(1),
   @w_porcentaje_cobertura    char(1),
   @w_nro_garantia            varchar(64),
   @w_op_monto_aprobado       money,
   @w_valor_cliente           money,
   @w_rubro_timbac            catalogo,
   @w_parametro_timbac        catalogo,
   @w_valor_banco             money,
   @w_monto_aprobado_c        char(1),
   @w_des_tipo_garantia       varchar(30),
   @w_tabla_tasa              varchar(30),
   @w_fpago                   catalogo,
   @w_saldo_insoluto          char(1),
   @w_porcentaje_cobrar       float,
   @w_porcentaje_cero         float,
   @w_num_periodo_o           int,
   @w_fecha                   datetime,
   @w_nombre_tasa             catalogo,
   @w_rubro_iva               catalogo,
   @w_tipo_rubro_iva          catalogo,
   @w_iva_siempre             char(1),
   @w_op_oficina              int,
   @w_exento                  char(1),
   @w_concepto_conta_iva      catalogo,
   @w_cotizacion              float,
   @w_moneda_local            smallint,
   @w_fecha_ult_proceso       datetime,
   @w_monto_timbre            money,
   @w_tipogar_hipo            catalogo,
   @w_garhipo                 char(1),
   @w_tramite                 int,
   @w_parametro_segvida       catalogo,
   @w_rot_gracia              money,
   @w_valor_total             money,
   @w_rot_valor               money,
   @w_codigo_clientes         varchar(255),
   @w_pos_bandera             int,
   @w_codcli                  varchar(15),
   @w_numero_codeu            int,
   @w_numero_segv             varchar(255),
   @w_pos_bandera1            int,
   @w_rol                     char(1),
   @w_est_vigente             tinyint,
   @w_est_vencido             tinyint,
   @w_est_suspenso            tinyint,
   @w_est_castigado           tinyint,
   @w_rowcount                int,
   @w_par_fag_des             catalogo,
   @w_parametro_fng_des       catalogo,
   @w_parametro_fag_uni       varchar(30),
   @w_monto_parametro         money,
   @w_SMV                     money,
   @w_concepto_va             catalogo,
   @w_parametro_fng           catalogo,
   @w_parametro_fag           catalogo,
   @w_parametro_fga           catalogo,
   @w_tasa_matriz             char(1) ,
   @w_msg                     varchar(64),
   @w_campana                 int     ,
   @w_monto_mat               float   ,
   @w_monto_abs               float   ,
   @w_clase_cartera           catalogo,
   @w_factor_des              float   ,
   @w_destino                 catalogo,
   --REQ379
   @w_parametro_fgu           catalogo,
   @w_parametro_fgu_per       catalogo,
   @w_colateral               catalogo,
   @w_tipo_gar                varchar(10),
   @w_cod_garantia            varchar(30),
   @w_rubros                  char(1),
   @w_tabla_rubros            varchar(30),
   @w_rubro                    varchar(30),
   @w_tabla_rubro              varchar(64),
   @w_tipo                     varchar(64),
   @w_cont                     int,
   @w_val                      catalogo,
   @w_tplazo                   char(1),
   @w_plazo                    int,
   @w_factor                   int,
   @w_mes_oper                 int,
   @w_mes_calculo              int,
   @w_fecha_fin                datetime,
   --CCA500
   @w_fecha_fin_habil          datetime,
   @w_ciudad_nacional          int,
   @w_es_habil                 char(1),
   @w_dia_semana               int,
   @w_dias_restados            int,
   @w_dias_calculo             float,
   @w_dia_pago                 int,
   @w_financiado               char(1),
   @w_valor_financiado         money,
   @w_otros_financiado         money,
   @w_porcentaje_max           float,
   @w_tasa_maxima              float,
   @w_tasa_minima              float,
   @w_reajuste                 catalogo,    --PQU
   @w_concepto_asociado	       catalogo,    --PQU
   @w_desc_reajuste            descripcion, --PQU
   @w_ru_limite                char(1)

select   @w_sp_name = 'sp_rubro_tmp',
         @w_tasa_matriz = 'N'

create table #conceptos (
codigo    varchar(10),
tipo_gar  varchar(64)
)

create table #rubros (
garantia    varchar(10),
rre_concepto  varchar(64),
tipo_concepto varchar(10)
)


select @w_categoria_rubro = co_categoria
from   ca_concepto
where  co_concepto        = @i_concepto


select @w_parametro_fng_des = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COFNGD'
set transaction isolation level read uncommitted

/* PARAMETRO DE LA GARANTIA DE FNG */
select @w_parametro_fng = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION FGA 
select @w_parametro_fga = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFGA'
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION FAG 
select @w_parametro_fag = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CMFAGP'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted


---CODIGO DEL RUBRO COMISION FAG DES
select @w_par_fag_des = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CMFAGD' 
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION FAG UNICO
select @w_parametro_fag_uni = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMUNI' 
set transaction isolation level read uncommitted


--CODIGO DEL RUBRO TIMBRE
select @w_timbre = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'TIMBRE'
set transaction isolation level read uncommitted


--CODIGO DEL RUBRO TIMBRE PARA EL BANCO
select @w_parametro_timbac = pa_char
from   cobis..cl_parametro 
where  pa_producto = 'CCA'
and    pa_nemonico = 'TIMBAC'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount =  0
begin
   select @w_error    = 710363
   goto ERROR
end

--REQ379
select @w_parametro_fgu = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMGAR'


select @w_parametro_fgu_per = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMGRP'

--CCA 500
--DETERMINA CODIGO DE CIUDAD NACIONAL
select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico        = 'CIUN'
and    pa_producto        = 'ADM'

if @w_rowcount = 0
begin
   select @w_error = 105141
   goto ERROR
end 

/*select @w_rubro_timbac = co_concepto
from   ca_concepto
where  co_concepto = @w_parametro_timbac

if @@rowcount =  0
begin
   select @w_error    = 710364
   goto ERROR
end
*/

--CODIGO DEL RUBRO SEGVIDA
select @w_parametro_segvida = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'SEGURO'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 710370
   goto ERROR
end

---ESTADOS DE LA CARTERA
exec sp_estados_cca
@o_est_vigente   = @w_est_vigente out,
@o_est_vencido   = @w_est_vencido  out,
@o_est_suspenso  = @w_est_suspenso  out,
@o_est_castigado = @w_est_castigado   out

if @w_est_vigente is null begin
   --GFP se suprime print
   --PRINT 'Error en la busqueds de estados  en sp_estados_cca'
   return  710217
end
      
      select @w_estado  = op_estado
      from   ca_operacion
      where  op_banco = @i_banco

      if @i_concepto = @w_par_fag_des  and @w_estado = 99

      if @i_concepto = @w_par_fag_des 
      begin
          -- ELIMINACION DE LAS TABLAS TEMPORALES
          exec @w_error = sp_borrar_tmp_int
               @i_banco = @i_banco
          
          if @w_error <> 0
          begin
		     --GFP se suprime print
             --print 'rubrotmp.sp Error ejecutando sp_borrar_tmp_int'
             select @w_error = 710001
             goto ERROR
         end         
         
         exec  @w_error     = sp_pasotmp
         @s_user            = @s_user,
         @s_term            = @s_term,
         @i_banco           = @i_banco,
         @i_operacionca     = 'S',
         @i_dividendo       = 'S',
         @i_amortizacion    = 'S',
         @i_cuota_adicional = 'S',
         @i_rubro_op        = 'S',
         @i_relacion_ptmo   = 'S',
         @i_nomina          = 'S',
         @i_acciones        = 'S',
         @i_valores         = 'S'
         
         if @w_error <> 0
         begin
		    --GFP se suprime print
            --print 'rubrotmp.sp Error ejecutando sp_pasotmp '
            select @w_error = 710001
            goto ERROR
         end      
      end
      ELSE
      begin

         exec  @w_error     = sp_pasotmp
         @s_user            = @s_user,
         @s_term            = @s_term,
         @i_banco           = @i_banco,
         @i_operacionca     = 'S',
         @i_dividendo       = 'S',
         @i_amortizacion    = 'N',
         @i_cuota_adicional = 'S',
         @i_rubro_op        = 'S',
         @i_relacion_ptmo   = 'S',
         @i_nomina          = 'S',
         @i_acciones        = 'S',
         @i_valores         = 'S'
         
      end 


select @i_operacionca       = opt_operacion,
       @w_sector            = opt_sector,
       @w_toperacion        = opt_toperacion,
       @w_moneda            = opt_moneda,
       @w_fecha_ini         = opt_fecha_ini,
       @w_fecha_fin         = opt_fecha_fin,
       @w_monto_orig        = opt_monto,
       @w_tipo_amortizacion = opt_tipo_amortizacion,--TIPO DE AMORTIZACION
       @w_num_periodo_d     = opt_periodo_int,      --NUMERO DE PERIODICIDAD DESTINO
       @w_periodo_d         = opt_tdividendo,       --PERIODICIDAD DESTINO
       @w_cliente           = opt_cliente,
       @w_dias_anio         = opt_dias_anio,
       @w_b_calculo         = opt_base_calculo,
       @w_monto_aprobado    = opt_monto_aprobado,
       @w_estado            = opt_estado,  
       @w_clase_operacion   = opt_tipo,
       @w_tasa_eq           = opt_usar_tequivalente,
       @w_convierte_tasa    = isnull(opt_convierte_tasa,'S'),
       @w_op_monto_aprobado = opt_monto_aprobado,
       @w_op_oficina        = opt_oficina,
       @w_fecha_ult_proceso = opt_fecha_ult_proceso,
       @w_tramite           = opt_tramite,
       @w_destino           = opt_destino, 
       @w_clase_cartera     = opt_clase,
       @w_dia_pago          = opt_dia_fijo
from   ca_operacion_tmp
where  opt_banco = @i_banco 
   or  opt_operacion = @i_operacionca

if @@rowcount = 0
begin
   select @w_error = 701050 --No existe Operación Temporal
   goto ERROR
end  


select @w_SMV      = pa_money 
from   cobis..cl_parametro
where  pa_producto  = 'ADM'
and    pa_nemonico  = 'SMV'

select @w_monto_parametro  = round(@w_monto_orig/@w_SMV,2)


--PARA LAS OBLIGACIONES CON GARANTIA HIPOTECARIA EL VALOR DEL TIMBRE ES 0
if @i_concepto = @w_timbre
begin  
   select @w_tipogar_hipo = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'GARHIP'
   set transaction isolation level read uncommitted
   
   select @w_garhipo = 'N'
   if exists (select 1 
              from   cob_credito..cr_gar_propuesta,cob_custodia..cu_custodia,cob_custodia..cu_tipo_custodia
              where  cu_codigo_externo = gp_garantia
              and    gp_tramite = @w_tramite
              and    tc_tipo = cu_tipo
              and    tc_tipo_superior = @w_tipogar_hipo )
      select @w_garhipo = 'S'
end

select @w_monto = sum(rot_valor)
from   ca_rubro_op_tmp with (nolock)
where  rot_operacion  =  @i_operacionca
and    rot_tipo_rubro = 'C'

select @w_monto_timbre = @w_monto_aprobado

if @w_monto is null 
   select @w_monto = 0

-- DECIMALES
exec @w_error       = sp_decimales
     @i_moneda      = @w_moneda,
     @o_decimales   = @w_num_dec out

if @w_error <> 0
begin
   select @w_error = 710001
   goto ERROR
end  

-- CONSULTA CODIGO DE MONEDA LOCAL
select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLO'
and    pa_producto = 'ADM'
set transaction isolation level read uncommitted


-- DETERMINAR EL VALOR DE COTIZACION DEL DIA
if @w_moneda = @w_moneda_local
   select @w_cotizacion = 1.0
else
begin
   exec sp_buscar_cotizacion
        @i_moneda     = @w_moneda,
        @i_fecha      = @w_fecha_ult_proceso,
        @o_cotizacion = @w_cotizacion output
end

select @w_monto_timbre = round((@w_monto_timbre * @w_cotizacion),@w_num_dec)

if @i_porcentaje_cobrar > 100.00
begin 
   select @w_error = 710403
   goto ERROR
end

-- PERIODICIDAD ANUAL
select @w_periodo_efa = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'PAN' --PERIODICIDAD ANUAL
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

-- MONTO POR VARIOS RUBROS CAPITAL A EXCEPCION DEL QUE SE MODIFICA
select @w_monto_rubcap = sum(rot_valor)
from   ca_rubro_op_tmp with (nolock)
where  rot_operacion  =  @i_operacionca
and    rot_tipo_rubro = 'C'
and    rot_concepto   <> @i_concepto

select @w_monto_rubcap = isnull(@w_monto_rubcap,0)

select @w_modalidad_efa = 'V'


if @i_operacion  = 'C'   --INSERCION DEL RUBRO SEGVIDA SI LOS CODEUDORES ESTAN MARCADOS SEGVIDA  = S
begin
   if exists (select 1
              from   ca_rubro_op_tmp with (nolock)
              where  rot_operacion  = @i_operacionca
              and    rot_concepto   = @w_parametro_segvida)
   begin
      -- VALOR DEL SEGURO DE VIDA DEUDOR Y CODEUDORES
      select @w_rot_valor  = rot_valor,
             @w_rot_gracia = rot_gracia
      from   ca_rubro_op_tmp with (nolock)
      where  rot_operacion = @i_operacionca
      and    rot_concepto  = @w_parametro_segvida
      
      select @w_valor_total   = 0
      
      if @w_rot_gracia = 0 ---EN EL CAMPO ROT_GRACIA SE GUARDA EL VALOR BASE DEL SEGURO DE VIDA PARA LUEGO MULTIPLICARLO POR EL NUMERO DE REG. DE CODEUDORES
      begin
         select @w_valor_total = @w_rot_valor * @i_numero_codeu
         
         update ca_rubro_op_tmp WITH (rowlock)
         set    rot_valor       = @w_valor_total,
                rot_gracia      = @w_rot_valor
         where  rot_operacion   = @i_operacionca
         and    rot_concepto    = @w_parametro_segvida
      end
      ELSE
      begin
         select @w_valor_total = @w_rot_gracia * @i_numero_codeu
         
         update ca_rubro_op_tmp WITH (rowlock)
         set    rot_valor     = @w_valor_total
         where  rot_operacion = @i_operacionca
         and    rot_concepto  = @w_parametro_segvida
      end
      
      -- MARCA QUE IDENTIFICA QUE CODEUDORES TIENEN SEGURO DE VIDA
      select @w_codigo_clientes = ltrim(rtrim(@i_codigo_clientes))    ---NUMEROS DE OPERACION DE LOS CODEUDORES
      select @w_pos_bandera     = charindex('#',@w_codigo_clientes)
      
      select @w_numero_segv  = ltrim(rtrim(@i_numero_segv))          ---NUMEROS DE ROL DE LOS CODEUDORES
      select @w_pos_bandera1 = charindex('#',@w_numero_segv)
      
      while 0 = 0 
      begin
         if  @w_pos_bandera > 0
         begin
            select @w_codcli          = substring(@w_codigo_clientes,1,@w_pos_bandera - 1)
            select @w_codigo_clientes = substring(@w_codigo_clientes,@w_pos_bandera + 1, datalength(@w_codigo_clientes))
            select @w_pos_bandera     = charindex('#',@w_codigo_clientes)
            
            select @w_rol             = substring(@w_numero_segv,1,@w_pos_bandera1 - 1)
            select @w_numero_segv     = substring(@w_numero_segv,@w_pos_bandera1 + 1, datalength(@w_numero_segv))
            select @w_pos_bandera1    = charindex('#',@w_numero_segv)
            
            if @w_tramite is not null    ---SI YA ESTA CREADO EL TRAMITE,POR LO GENERAL CUANDO EL PROCESO EMPIEZA EN CREDITO
            begin
               update cob_credito..cr_deudores
               set    de_segvida = @w_rol
               where  de_cliente = convert(int,@w_codcli)
               and    de_tramite = @w_tramite
               
               update cob_cartera..ca_deudores_tmp WITH (rowlock) ---SI LA OBLIGACION ES CREADA EN CCA DIRECTAMENTE, CUANDO SE DESEMBOLSE LA OBLIG. SE ACTUALIZARA CR_DEUDORES 
               set dt_segvida  = isnull(@w_rol,'N')
               where dt_deudor = convert(int,@w_codcli)
               and   dt_operacion  = @i_operacionca
               
               ---6487
               update cob_cartera..ca_deu_segvida
               set    dt_segvida = @w_rol
               where  dt_cliente = convert(int,@w_codcli)
               and    dt_operacion  = @i_operacionca
            end
            ELSE
            begin
               update cob_cartera..ca_deudores_tmp WITH (rowlock) ---SI LA OBLIGACION ES CREADA EN CCA DIRECTAMENTE, CUANDO SE DESEMBOLSE LA OBLIG. SE ACTUALIZARA CR_DEUDORES 
               set    dt_segvida  = isnull(@w_rol,'N')
               where  dt_deudor = convert(int,@w_codcli)
               and    dt_operacion  = @i_operacionca
               
               ---6487
               update cob_cartera..ca_deu_segvida
               set dt_segvida = @w_rol
               where dt_cliente = convert(int,@w_codcli)
               and   dt_operacion  = @i_operacionca
            end
         end
         ELSE
         begin
            select @w_codcli          = @w_codigo_clientes,
                   @w_codigo_clientes = ''
         end
         
         if @w_codigo_clientes = '' 
            break
      end
   end
   
   /* KDR 18/05/2022 Se comenta ya que no aplica a versión Finca
   if @w_estado in (@w_est_vigente,@w_est_vencido,@w_est_suspenso,@w_est_castigado)    ---si la obligacion esta vigente, no se puede recalcular desde el frontend (deshabilitado)
   begin
      exec sp_calculo_seguros_sinsol
           @i_operacion    = @i_operacionca
      
      if @w_error <> 0 
      begin
         goto ERROR 
      end
      
      -- CALCULO DE RUBROS CATALOGO
      exec @w_error =  sp_rubros_catalogo
           @i_operacion = @i_operacionca
      
      if @w_error <> 0
         goto ERROR
      -- CALCULO DE RUBROS CATALOGO
   end -- fin KDR*/
end

--MODIFICACION DE UN RUBRO YA EXISTENTE, SI NO EXISTE LO INSERTA
if @i_operacion in ('U','I') 
begin

    --FORMA DE PAGO DEL RUBRO PARA SABER SU MODALIDAD DESTINO(EL DE LA OPER.)
    if @i_concepto is null
    begin
        select @w_error  =  701003
        goto ERROR
    end
   
    --FORMA DE PAGO DEL RUBRO PARA SABER SU MODALIDAD DESTINO(EL DE LA OPER.
    select @w_tipo_rubro           = rot_tipo_rubro,
           @w_principal            = rot_principal,
           @w_saldo_operacion      = rot_saldo_op,
           @w_saldo_insoluto       = rot_saldo_insoluto,
           @w_saldo_por_desem      = rot_saldo_por_desem,
           @w_limite               = rot_limite,
           @w_rubro_asociado       = rot_concepto_asociado,
           @w_monto_aprobado_c     = rot_monto_aprobado,
           @w_porcentaje_cobertura = rot_porcentaje_cobertura,
           @w_tabla_tasa           = rot_tabla,
           @w_fpago                = rot_fpago,
           @w_prioridad            = rot_prioridad,
           @w_provisiona           = rot_provisiona,
           @w_referencial          = rot_referencial,
           @w_signo_reaj           = rot_signo_reajuste,
           @w_porcentaje           = rot_porcentaje,
           @w_tipo_puntos          = rot_tipo_puntos,
           @w_num_dec_tapl         = rot_num_dec,
           @w_valor_garantia       = rot_valor_garantia,
           @w_iva_siempre          = rot_iva_siempre,
           @w_financiado           = rot_financiado,
           @i_tipo_garantia        = rot_tipo_garantia
    from   ca_rubro_op_tmp with (nolock)
    where  rot_operacion = @i_operacionca
    and    rot_concepto  = @i_concepto
   
    if @@rowcount = 0  --INSERCION DE UN NUEVO RUBRO 
    begin

        --- NR-244
        --- VALIDAR LA EXISTENCIA DE UN RUBRO PLANIFICADOR, SOLO DEBE EXISTIR UNO POR OBLIGACION
        if  exists ( select 1
                     from ca_rubro_op_tmp a with (nolock),
                          ca_concepto with (nolock)
                     where a.rot_operacion = @i_operacionca
                     and a.rot_concepto in (select  rp_rubro
                                            from ca_rubro_planificador
                                            where rp_rubro = a.rot_concepto)
                     and co_concepto = a.rot_concepto) 

        begin
            select @w_error = 721101
            goto ERROR
        end  
         
        --- FIN NR-244
      
        select @w_tipo_rubro           = ru_tipo_rubro,
               @w_principal            = ru_principal,
               @i_referencial_reajuste = ru_reajuste,
               @w_saldo_operacion      = ru_saldo_op,
               @w_saldo_por_desem      = ru_saldo_por_desem,
               @w_limite               = ru_limite,
               @w_rubro_asociado       = ru_concepto_asociado,
               @w_monto_aprobado_c     = ru_monto_aprobado,
               @w_porcentaje_cobertura = ru_porcentaje_cobertura,
               @w_tabla_tasa           = ru_tabla,
               @w_fpago                = ru_fpago,
               @w_saldo_insoluto       = ru_saldo_insoluto,
               @w_prioridad            = ru_prioridad,
               @w_valor_garantia       = ru_valor_garantia,
               @w_tipo_garantia        = ru_tipo_garantia,
               @w_financiado           = ru_financiado, -- AMP 20220303 RUBROS FINANCIADOS
               @i_provisiona           = isnull(@i_provisiona, ru_provisiona)
        from   ca_rubro with (nolock)
        where  ru_toperacion = @w_toperacion
        and    ru_concepto   = @i_concepto
        and    ru_moneda     = @w_moneda
    end
	
	-- KDR Validación cuando el rubro es financiado y su forma de pago no es en el desembolso.
	if @w_financiado = 'S' and @w_fpago <> 'L'
	begin
	   select @w_error = 725149 -- Un rubro financiado debe tener como forma de aplicación EN EL DESEMBOLSO, revisar parametrización
       goto ERROR
	end

    if @i_concepto = @w_timbre select @w_limite = 'S'
   
    -- PARA LOS VALORES ENVIADOS DESDE EL FRONT-END (RUBROS POR OPERACION) 
    if @i_iva_siempre is null   select @i_iva_siempre = @w_iva_siempre
   
    if @w_valor_garantia = 'S' and @i_tipo_garantia is null
    begin
        select @w_error = 710371
        goto ERROR
    end
   
    if @i_porcentaje is null    select @i_porcentaje =  @w_porcentaje
   
    if @i_periodo_c > 0   select @i_tperiodo_c = @w_periodo_d
    
    --REQ 402
   select @w_colateral = pa_char
   from cobis..cl_parametro with (nolock)
   where pa_producto = 'GAR'
   and   pa_nemonico = 'GARESP'

   select tc_tipo as tipo_sub 
   into #colateral
   from cob_custodia..cu_tipo_custodia
   where tc_tipo_superior = @w_colateral

   select w_tipo_garantia   = tc_tipo_superior,
          w_tipo            = tc_tipo,
          estado            = 'I',
          w_garantia        = cu_codigo_externo
   into #garantias_operacion_rtmp
   from cob_custodia..cu_custodia, #colateral, cob_credito..cr_gar_propuesta, cob_custodia..cu_tipo_custodia
   Where cu_tipo = tc_tipo
   and   tc_tipo_superior = tipo_sub
   and   gp_tramite  = @w_tramite
   and   gp_garantia = cu_codigo_externo
   and   cu_estado  in ('V','F','P')

   select * 
   into #gar_rtmp
   from #garantias_operacion_rtmp
    
   while 1=1 
   begin
   
      set rowcount 1
      select @w_tipo_garantia   = w_tipo_garantia,
             @w_tipo            = w_tipo,
             @w_cod_garantia    = w_garantia
      from #gar_rtmp
      --where estado = 'I'
        
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
      set rowcount 0
      
      delete #gar_rtmp
      where w_garantia = @w_cod_garantia 
       
      select @w_rubro = valor 
      from  cobis..cl_tabla t, cobis..cl_catalogo c
      where t.tabla  = 'ca_conceptos_rubros'
      and   c.tabla  = t.codigo
      and   c.codigo = convert(bigint, @w_tipo)  

      if @w_rubro = 'S' begin
       
         select @w_tabla_rubro = 'ca_conceptos_rubros_' + cast(@w_tipo as varchar)

         insert into #conceptos
         select 
         codigo = c.codigo, 
         tipo_gar = @w_tipo
         from cobis..cl_tabla t, cobis..cl_catalogo c
         where t.tabla  = @w_tabla_rubro
         and   c.tabla  = t.codigo
          
      end
   end 

   insert into #rubros
   select tipo_gar, ru_concepto, 'DES'
   from cob_cartera..ca_rubro, #conceptos
   where ru_fpago = 'L'
   and   codigo   = ru_concepto
   and   ru_concepto_asociado is  null

   /*COMICION PERIODICO*/
   insert into #rubros
   select tipo_gar, ru_concepto, 'PER'
   from cob_cartera..ca_rubro, #conceptos
   where ru_fpago = 'P'
   and   codigo   = ru_concepto
   and   ru_concepto_asociado is  null
      
    if @i_concepto in (@w_parametro_fng,@w_parametro_fag,@w_par_fag_des,@w_parametro_fng_des,@w_parametro_fag_uni,@w_parametro_fga, @w_parametro_fgu, @w_parametro_fgu_per)
       or @i_concepto in (select rre_concepto from #rubros)
       begin
           ---CALCULO DE LA TASA  PARA LOS FNG O FAG ANUALES O DEL DESEMBOLSO

          if @i_concepto in (@w_parametro_fng,@w_parametro_fng_des)
             select @w_concepto_va = @w_parametro_fng
          if @i_concepto in (@w_parametro_fag,@w_par_fag_des)
             select @w_concepto_va = @w_parametro_fag
          if @i_concepto  = @w_parametro_fag_uni
             select @w_concepto_va =@w_parametro_fag_uni
          if  @i_concepto  = @w_parametro_fga
             select @w_concepto_va =@w_parametro_fga 
          if @i_concepto in (select rre_concepto from #rubros)
                select @w_concepto_va = (select rre_concepto from #rubros 
                                                          where rre_concepto  = @i_concepto
                                                          and   tipo_concepto = 'DES')
           if  @i_concepto  = @w_parametro_fgu --REQ379
                select @w_concepto_va =@w_parametro_fgu     
           if  @i_concepto  = @w_parametro_fgu_per --REQ379
                select @w_concepto_va =@w_parametro_fgu_per   		   
           		   
           		   
           exec @w_error = cob_cartera..sp_matriz_garantias
                @s_date          = @s_date,
                @i_tramite       = @w_tramite,
                @i_concepto      = @w_concepto_va,
                @i_tipo_periodo  = 'P',
                @i_crea_ext      = @i_crea_ext,     ---NR000353 ALIANZAS
                @o_valor         = @w_porcentaje out,
                @o_msg           = @o_msg_msv    out

                if @w_error <> 0  return @w_error 

		   
                select @i_porcentaje  = @w_porcentaje,
		       @w_tasa_matriz = 'S'	   
		                                                   
      end
           
    if @i_referencial is null   select @i_signo = '+'
   
    if @w_monto_aprobado <> 0
    begin
        if @w_tipo_rubro = 'C'
           and (@w_monto_rubcap + @i_valor > @w_monto_aprobado) and @w_estado = 0
           and @i_control_monto_aprobado = 'S'
        begin
            select @w_error = 710021
            goto ERROR
        end
    end
   
    if @w_clase_operacion = 'O'  -- ROTATIVO
    begin
        select @w_capital_pag = sum(amt_pagado)
        from   ca_operacion_tmp with (nolock) ,ca_amortizacion_tmp with (nolock), ca_rubro_op_tmp with (nolock)
        where  opt_banco  = @i_banco_real
        and    amt_operacion  = opt_operacion
        and    amt_operacion  = rot_operacion
        and    amt_concepto   = rot_concepto
        and    rot_tipo_rubro = 'C'
    end
   
    if @w_capital_pag is null  select @w_capital_pag = 0.00

    if @w_tipo_rubro = 'C'     select @i_factor = 0
   
    if @w_monto_aprobado <> 0
    begin
        if @w_tipo_rubro = 'C' and (@w_monto_orig+@w_monto_rubcap+@i_valor-@w_capital_pag)>@w_monto_aprobado
           and @w_estado = 1 and @i_control_monto_aprobado = 'S'
        begin
            if @w_clase_operacion = 'O' and @w_estado = 1 
               select @w_error = 710125
            else
               select @w_error = 710021
               goto ERROR
        end
    end
   
    -- TASA CERO 
    if @i_tipo_puntos = 'N' 
    begin
        select @w_porcentaje_cero = @i_porcentaje  - @i_factor
      
        if @w_porcentaje_cero = 0
        begin
            select @i_periodo_o = opt_tdividendo,  
                   @w_num_periodo_o = opt_periodo_int
            from   ca_operacion_tmp with (nolock)
            where  opt_operacion = @i_operacionca
         
            select @i_modalidad_o = rot_fpago
            from   ca_rubro_op_tmp with (nolock)
            where  rot_operacion = @i_operacionca
            and    rot_concepto like 'INT%'
         
            if @i_modalidad_o = 'P'   select @i_modalidad_o = 'V'
         
            if @i_modalidad_o = 'A'   select @i_modalidad_o = 'A'
         
            if @i_modalidad_o is null  select @i_modalidad_o = 'V'
        end
    end
    else
        select @w_num_periodo_o = 1
   
    -- LA TASA ORIGINAL SE ALMACENA EN ro_porcentaje_aux BCO_ESTADO
    select @w_porcentaje_aux = isnull(@i_porcentaje,0)
   
    select @w_campana= isnull(tr_campana,0)
    from cob_credito..cr_tramite
    where tr_tramite= @w_tramite
    and tr_cliente =@w_cliente

    if @w_campana <> 0 and @i_negociacion = 'S' begin 
       --VALIDACION DEL FACTOR MINIMO QUE SE PUEDE NEGOCIAR POR PARTE DE UN FUNCIONARIO DEPENDIENDO SU ROL. 
    
      exec @w_error = cob_credito..sp_evaluar_min_matriz
      @s_user          =  @s_user          ,
      @s_rol           =  @s_rol           ,
      @i_concepto      =  @i_concepto      ,
      @i_operacionca   =  @i_operacionca   ,
      @i_tramite       =  @w_tramite       ,
      @i_clase_cartera =  @w_clase_cartera ,     
      @i_lin_credito   =  @w_toperacion    ,
      @i_destino       =  @w_destino       ,
      @i_campana       =  @w_campana       ,
      @i_tipo_rubro    =  @w_tipo_rubro    ,
      @o_factor        =  @w_factor_a  out ,
      @o_valor         =  @w_monto_mat out ,
      @o_msg           =  @w_msg       out                                  

      if @w_error <> 0 begin
	     --GFP se suprime print
         --print @w_msg
         return @w_error
      end 
      
      if @i_signo = '-' begin 
         select 
         @w_factor_des = @i_factor * (-1),
         @w_monto_abs  = @w_monto * (-1)        
      end
      else begin
         select 
         @w_factor_des = @i_factor,
         @w_monto_abs  = @w_monto 
      end
      
      if abs(@w_factor_a) < abs(@w_factor_des) begin
	     --GFP se suprime print
		 /*
         select  @w_msg = 'La tasa que tiene permitido negociar es: ' + convert(varchar,@w_factor_a)
         print @w_msg
		 */
         return @w_error
      end 
      
      if abs(@w_monto_mat)< abs(@w_monto_abs) begin
	     --GFP se suprime print
		 /*
         select  @w_msg = 'El Valor que tiene permitido negociar es: ' + convert(varchar,@w_monto_mat)
         print @w_msg
		 */
         return @w_error
      end   
   end
   
    --INSERCION DE LA TRANSACCION DE SERVICIO
    select @w_clave1 = convert(varchar(255),@i_operacionca)
    select @w_clave2 = convert(varchar(255),@i_concepto)
   
    exec @w_error = sp_tran_servicio
         @s_user    = @s_user,
         @s_date    = @s_date,
         @s_ofi     = @s_ofi,
         @s_term    = @s_term,
         @i_tabla   = 'ca_rubro_op',
         @i_clave1  = @w_clave1,
         @i_clave2  = @w_clave2
   
    if @w_error <> 0
    begin
        goto ERROR
    end     
   
    select @w_valor = @i_valor

   
    -- CALCULAR EL VALOR DEL PORCENTAJE 
    if @w_tipo_rubro in ('O') and @w_rubro_asociado is not null 
    begin
        select @w_valor_asociado = 0
      
        select @w_valor_asociado = rot_valor
        from   ca_rubro_op_tmp with (nolock)
        where  rot_operacion = @i_operacionca
        and    rot_concepto = @w_rubro_asociado
      
	    IF @i_operacion = 'U'
           select @w_valor = round( isnull(@i_porcentaje,0) * @w_valor_asociado/100.0, @w_num_dec)
        ELSE
           select @w_valor = round( isnull(@i_porcentaje,0) * @w_valor_asociado/100.0 + isnull(@w_valor,0), @w_num_dec)

    end 
    else
       if @w_tipo_rubro in ('I', 'O')
          select @w_valor = round( isnull(@i_porcentaje,0) * @w_monto/100.0, @w_num_dec)
       else
	      select @w_valor = round( isnull(@i_porcentaje,0) * @w_monto/100.0 + isnull(@w_valor,0), @w_num_dec)
    
    -- RUBROS CALCULADOS  
    if @w_tipo_rubro = 'Q'
       ---AMP 20210811 INICIO SE REUTILIZA VARIABLE RO_LIMITE PARA MARCA DE COMISIONES DIFERIDAS BANCO FINCA 
       begin
          
          select @w_tasa_efa   = 0,
  	             @i_porcentaje =  isnull(@i_porcentaje, @w_porcentaje)
  	                 
          exec @w_error                 = sp_rubro_calculado
                 -- @i_tipo                  = 'Q',
                 -- @i_categoria_rubro       = @w_categoria_rubro,
                 -- @i_tabla_tasa            = @w_tabla_tasa,
                 -- @i_fpago                 = @w_fpago,
               @i_monto                 = @i_base_calculo,
               @i_concepto              = @i_concepto,
               @i_operacion             = @i_operacionca,
               @i_saldo_op              = @w_saldo_operacion,
               @i_saldo_por_desem       = @w_saldo_por_desem,
               @i_porcentaje            = @i_porcentaje,
               @i_saldo_insoluto        = @w_saldo_insoluto,
               @i_tipo_garantia         = @i_tipo_garantia,
               @i_porcentaje_cobertura  = @w_porcentaje_cobertura,
               @i_valor_garantia        = @w_valor_garantia,
               @i_tasa_matriz           = @w_tasa_matriz,
               @o_tasa_calculo          = @w_porcentaje out,
               @o_nro_garantia          = @w_nro_garantia out, 
               @o_base_calculo          = @w_base_calculo out,
               @o_valor_rubro           = @w_valor out
         
          if @w_error <> 0  
             goto ERROR
                            
          if @i_concepto = @w_par_fag_des 
             begin    
                --SE OBTIENE EL PLAZO, TIPO PLAZO Y SU RESPCTIVO FACTOR EN DIAS
                select @w_tplazo = op_tplazo,
                       @w_plazo  = op_plazo,
                       @w_factor = td_factor
                from cob_cartera..ca_operacion, cob_cartera..ca_tdividendo
                where op_tplazo = td_tdividendo
                and   op_operacion = @i_operacionca
                      
                --SE CONVIERTE EN MESES EL PLAZO
                select @w_mes_oper = (@w_plazo * @w_factor)/30 
               
                --SE VALIDA QUE INGRESE SOLO PLAZO IGUAL A 12 MESES PARA CALCULO DE DESEMBOLSO                             
                if @w_mes_oper = 12 
                   begin
                      --OBTIENE LOS DIAS DE CALCULO DE LA OPERACION   
                      select @w_dias_calculo = @w_plazo * @w_factor
                   
                      --OPTIENE NUMERO DE DIAS REALES DE LA OPERACION
                      --DIAS DE DESFACE + DIAS CALCULADOS
                      select @w_dias_calculo = convert(float, (@w_dia_pago - datepart(dd, @w_fecha_ini) + @w_dias_calculo))

                      --SE CALCULA LA FECHA REAL DE TERMINACION DEL CREDITO A PARTIR DEL DESEMBOLSO
                      select @w_fecha_fin_habil = DATEADD(mm, @w_mes_oper, @w_fecha_ini)
                   
                      select 
                      @w_es_habil      = 'N', 
                      @w_dias_restados = 0
                   
                      --DETERMINA EL NUMERO DE DIAS FERIADOS AL FINALIZAR EL CREDITO
                      while @w_es_habil = 'N'
                         begin
                            --RESTA LOS DIAS FESTIVOS SI LA FECHA FIN DEL CREDITO ES UN DIA FESTIVO
                            while exists(select 1 from cobis..cl_dias_feriados
                                         where df_ciudad = @w_ciudad_nacional
                                         and   df_fecha  = @w_fecha_fin_habil)
                               begin
                                  select @w_fecha_fin_habil = dateadd(day, 1, @w_fecha_fin_habil)
                                  select @w_dias_restados   = @w_dias_restados - 1
                               end
                       
                            --OPTIENE EL DIA DE LA SEMANA PARA EL ULTIMO DIA DE PAGO
                            select @w_dia_semana = datepart(dw,@w_fecha_fin_habil) 
                      
                            if @w_dia_semana = 1
                               select @w_dia_semana = 7
                            else
                               select @w_dia_semana = @w_dia_semana - 1

                            --RESTA LOS DIAS FESTIVOS SI LA FECHA FIN DEL CREDITO ES UN DIA FESTIVO FINAGRO (SABADO)
                            if exists(select 1 from cobis..cl_tabla t,cobis..cl_catalogo c
                                   where t.tabla = 'ca_dias_feriados_fag'
                                   and   c.tabla = t.codigo
                                   and   c.codigo = @w_dia_semana
                                   and   c.estado = 'V')
                               begin
                                  select @w_fecha_fin_habil = dateadd(dd, 1, @w_fecha_fin_habil)
                                  select @w_dias_restados   = @w_dias_restados - 1
                               end
                            else
                               begin
                                  --RESTA LOS DIAS FESTIVOS SI LA FECHA FIN DEL CREDITO ES UN DIA FESTIVO
                                  while exists(select 1 from cobis..cl_dias_feriados
                                            where df_ciudad = @w_ciudad_nacional
                                            and   df_fecha  = @w_fecha_fin_habil)
                                  begin
                                    select @w_fecha_fin_habil = dateadd(day, 1, @w_fecha_fin_habil)
                                    select @w_dias_restados   = @w_dias_restados - 1
                                  end
                     
                                  select @w_es_habil = 'S'
                               end
                         end--FIN WHILE

                      --DETERMINA EL NUMERO DE DIAS REALES DE CALCULO RESTANDO FERIADOS
                      select @w_dias_calculo = @w_dias_calculo + @w_dias_restados
                   
                      ----DETERMINA EL NUMERO DE MESES REALES DE CALCULO
                      select @w_dias_calculo = (@w_dias_calculo / 30)
                   
                      if @w_dias_calculo > @w_mes_oper
                         begin
                            select @w_mes_oper = @w_mes_oper + 1
                            select @w_valor = (@w_valor / 12 ) * @w_mes_oper
                         end
                   end
             end    
             
          select @w_valor        = round(@w_valor,@w_num_dec),
                 @i_base_calculo = @w_base_calculo
            
           
          -- SOLAMENTE PARA SEGUROS DE VIDA CODEUDORES   ---XMA
         
          if @w_porcentaje > 0  
             select @i_porcentaje = @w_porcentaje
       end
    ---AMP 20210811 FIN SE REUTILIZA VARIABLE RO_LIMITE PARA MARCA DE COMISIONES DIFERIDAS BANCO FINCA

    --- XMA EL RUBRO INGRESADO...TIENE ASOCIADO OTRO RUBRO??.IVA
    select @w_rubro_iva      = ru_concepto,
           @w_tipo_rubro_iva = ru_tipo_rubro,
           @w_nombre_tasa    = ru_referencial,
           @i_iva_siempre    = ru_iva_siempre
    from   ca_rubro with (nolock)
    where  ru_concepto_asociado = @i_concepto
	and    ru_toperacion        = @w_toperacion  -- KDR 16/05/2021 Validar asociación de Rubro por Tipo producto y moneda
	and    ru_moneda            = @w_moneda      
   
    if @@rowcount <> 0
    begin
        select @w_factor_a    = rot_porcentaje
        from   ca_rubro_op_tmp with (nolock)
        where  rot_operacion    = @i_operacionca
        and    rot_concepto     = @w_rubro_iva
      

        if @w_factor_a is null 
        begin
            -- DETERMINACION DE LA TASA A APLICAR
            select @w_factor_a       = vd_valor_default
            from   ca_valor, ca_valor_det
            where  va_tipo   = @w_nombre_tasa
            and    vd_tipo   = @w_nombre_tasa
            and    vd_sector = @w_sector
         
            if @@rowcount = 0
            begin
			    --GFP se suprime print
				/*
                print '(rubrotmp.sp) concepto asociado. Parametrizar Tasa para rubro.. @w_sector ' + cast(@w_nombre_tasa as varchar) + ' ' + cast(@w_sector as varchar)
				*/
				select @w_error = 710076
                goto ERROR
            end
        end
      
              
        select @w_valor_asociado = @w_factor_a * @w_valor /100.0 
        select @w_valor_asociado = round(@w_valor_asociado,@w_num_dec)
      
              
        --- EPB:AGO-25-2003 VALIDAR SI ES EXENTO DE IVA O NO 
        if @i_iva_siempre = 'S'
        begin
            ---CONCEPTO CONTABLE QUE IDENTIFICA EL IVA PARA CONSULTAR SI EL CLIENTE ES EXENTO O NO
            select @w_concepto_conta_iva = pa_char
            from   cobis..cl_parametro
            where  pa_producto  = 'CCA'
            and    pa_nemonico  =  'CONIVA' 
            and    pa_producto  = 'CCA'
            select @w_rowcount  = @@rowcount
            set transaction isolation level read uncommitted
         
            if @w_rowcount = 0
            begin
                select @w_error =  710449
                goto ERROR
            end
        
            exec @w_error = cob_conta..sp_exenciu
                 @s_date         = @s_date,
                 @s_user         = @s_user,
                 @s_term         = @s_term,
                 @s_ofi          = @s_ofi,
                 @t_trn          = 6251,
                 @t_debug        = 'N',
                 @i_operacion    = 'F',
                 @i_empresa      = 1,
                 @i_impuesto     = 'V',             ---IVA   T TIMBRE
                 @i_concepto     = @w_concepto_conta_iva,
                 @i_debcred      = 'C',            ---VALOR D‚BITO O CR‚DITO
                 @i_ente         = @w_cliente,     ---C¢DIGO  COBIS DEL CLIENTE
                 @i_oforig_admin = @s_ofi,         ---C¢DIGO COBIS DE LA OFICINA ORIGEN ADMIN
                 @i_ofdest_admin = @w_op_oficina,  ---C¢DIGO COBIS DE LA OFICINA DESTINO ADMIN
                 @i_producto     = 7,              ---CODIGO DEL PRODUCTO CARTERA             
                 @i_crea_ext     = @i_crea_ext,     ---NR000353 ALIANZAS
                 @o_exento       = @w_exento  out
         
            if @w_error <> 0
            begin
                select @w_error = 710457
                goto ERROR
            end
        
            if @w_exento = 'S'
               select @w_valor_asociado = 0
        end  ---@i_iva_siempre = 'S'
      
        -- EPB:AGO-25-2003 VALIDAR SI ES EXENTO DE IVA O NO 
        if exists (select 1
                   from   ca_rubro_op_tmp with (nolock)
                   where  rot_operacion = @i_operacionca 
                   and    rot_concepto  = @w_rubro_iva) 
        begin

            update ca_rubro_op_tmp WITH (rowlock)
            set    rot_fpago        = isnull(@i_fpago,rot_fpago),
                   rot_periodo      = isnull(@i_periodo_c,rot_periodo),
                   rot_tperiodo     = isnull(@i_tperiodo_c,rot_tperiodo),
                   rot_valor        = isnull(@w_valor_asociado,0),
                   rot_porcentaje   = isnull(@w_factor_a,0),
                   rot_base_calculo = isnull(@w_valor,0)
            where  rot_operacion         = @i_operacionca 
            and    rot_concepto          = @w_rubro_iva
        end
        else
        begin
            insert into ca_rubro_op_tmp
                    (rot_operacion,             rot_concepto,                rot_tipo_rubro,
                    rot_fpago,                 rot_prioridad,               rot_paga_mora,
                    rot_provisiona,            rot_signo,                   rot_factor,
                    rot_referencial,           rot_signo_reajuste,          rot_factor_reajuste,
                    rot_referencial_reajuste,  rot_valor,                   rot_porcentaje,
                    rot_gracia,                rot_porcentaje_aux,          rot_principal,
                    rot_porcentaje_efa,        rot_concepto_asociado,       rot_garantia,
                    rot_tipo_puntos,        rot_saldo_op,              rot_saldo_por_desem,
                    rot_base_calculo,          rot_num_dec,                 rot_tipo_garantia,       
                    rot_nro_garantia,          rot_porcentaje_cobertura,    rot_valor_garantia,
                    rot_tperiodo,              rot_periodo,                 rot_saldo_insoluto,
                    rot_porcentaje_cobrar,     rot_iva_siempre,             rot_financiado,
                    rot_limite)
            select  @i_operacionca,            @w_rubro_iva,                ru_tipo_rubro,
                    @w_fpago,                  ru_prioridad,                ru_paga_mora,
                    'N',                       null,                        0,
                    ru_referencial,            '+',                         0,
                    null,                      isnull(@w_valor_asociado,0), isnull(@w_factor_a,0),
                    0,                         isnull(@w_factor_a,0),       'N',
                    null,                      ru_concepto_asociado,        0,     
                    null,                      'N',                         'N', 
                    isnull(@w_valor,0),        @w_num_dec,                  ru_tipo_garantia,   
                    null,                     'N',                         'N',
                    @i_tperiodo_c,             @i_periodo_c,                'N',
                    0,                         ru_iva_siempre,              isnull(@i_financiado, ru_financiado),
                    ru_limite
            from   ca_rubro
            where  ru_toperacion = @w_toperacion
            and    ru_moneda     = @w_moneda 
            and    ru_concepto   = @w_rubro_iva 
         
            if @@error <> 0
            begin
                select @w_error = 710002
                goto ERROR
            end
        end
    end  --- POR EJEMPLO EL IVA
   
    -- FIN  CALCULO PARA RUBROS SOBRE RUBROS ASOCIADOS
	
	-- KDR 07/10/2021 Se establece base de calculo para rubros val fijo y porcentaje financiados
	-- AMP 20220303 RUBROS FINANCIADOS, SI NO SE ENVIA @i_financiado SE TOMA DE LA ca_rubro
	if @w_tipo_rubro in ('O','V') and isnull(@i_financiado,@w_financiado) = 'S' and isnull(@i_fpago,@w_fpago) = 'L' and @w_base_calculo is null
       select @w_base_calculo = @w_monto
	   
    if @w_base_calculo is not null
       select @i_base_calculo = @w_base_calculo

    --if @i_valor = 0 and @i_tipo_rubro = 'O' and @i_porcentaje > 0
    --select @w_valor = @i_porcentaje * isnull(@i_base_calculo,0)*0.01

    -- KDR Si el rubro no es financiado, no tiene base de cálculo.
	-- Si presenta inconvenientes relacionados a la base de calculo, Revisar validación de asignación de @w_base_calculo.
	if @i_base_calculo = 0
	   select @i_base_calculo = NULL
	   
	if isnull(@i_financiado,@w_financiado) <> 'S'
	   select @w_base_calculo = null,
	          @i_base_calculo = null
	   
    update ca_rubro_op_tmp WITH (rowlock)
    set    rot_tipo_rubro           = isnull(@i_tipo_rubro,rot_tipo_rubro),
           rot_fpago                = isnull(@i_fpago,rot_fpago),
           rot_prioridad            = isnull(@i_prioridad,rot_prioridad),
           rot_paga_mora            = isnull(@i_paga_mora,rot_paga_mora),
           rot_provisiona           = isnull(@i_provisiona,rot_provisiona),
           rot_signo                = isnull(@i_signo,rot_signo),
           rot_factor               = isnull(@i_factor,rot_factor),
           rot_referencial          = isnull(@i_referencial,rot_referencial),
           rot_tipo_puntos          = isnull(@i_tipo_puntos,rot_tipo_puntos),
           rot_valor                = isnull(@w_valor,rot_valor),
           rot_porcentaje           = isnull(@i_porcentaje,rot_porcentaje),
           rot_gracia               = isnull(@i_gracia,rot_gracia),
           rot_porcentaje_aux       = isnull(@w_porcentaje_aux,rot_porcentaje_aux),
           rot_porcentaje_efa       = isnull(@w_tasa_efa,rot_porcentaje_efa),
           rot_base_calculo      = isnull(@i_base_calculo, rot_base_calculo),
           rot_referencial_reajuste = isnull(@i_referencial_reajuste,rot_referencial_reajuste),
           rot_signo_reajuste       = isnull(@i_signo_reajuste,rot_signo_reajuste),
           rot_factor_reajuste      = isnull(@i_factor_reajuste,rot_factor_reajuste),
           rot_num_dec              = @i_num_dec_tapl,
           rot_periodo              = isnull(@i_periodo_c,rot_periodo),
           rot_tperiodo             = isnull(@i_tperiodo_c,rot_tperiodo),
           rot_tipo_garantia        = isnull(@i_tipo_garantia,rot_tipo_garantia),
           rot_porcentaje_cobrar    = isnull(@i_porcentaje_cobrar,rot_porcentaje_cobrar),
           rot_saldo_insoluto       = isnull(@w_saldo_insoluto,rot_saldo_insoluto),
           rot_financiado           = isnull(@i_financiado,rot_financiado)
    where  rot_operacion      = @i_operacionca
    and    rot_concepto       = @i_concepto 
   
    if @@rowcount = 0               --INSERCION DE UN NUEVO RUBRO
    begin  ----(3)
        -- EN NEGOCIACION DE RUBROS YA NO SE NEGOCIA LOS REAJUSTES
        if @w_tipo_rubro = 'I'
           select @i_signo_reajuste    = isnull(vd_signo_default,' '),
                  @i_factor_reajuste   = isnull(vd_valor_default,0)
           from   ca_valor,ca_valor_det
           where  va_tipo   = @i_referencial_reajuste
           and    vd_tipo   = @i_referencial_reajuste
           and    vd_sector = @w_sector
      
        -- TASA CERO 
        if @i_tipo_puntos = 'N' 
        begin  ---(1)
            select @w_porcentaje_cero = @i_porcentaje  - @i_factor
         
            if @w_porcentaje_cero = 0
            begin  ---(2)
                select @i_periodo_o = opt_tdividendo,  
                       @w_num_periodo_o = opt_periodo_int
                from   ca_operacion_tmp with (nolock)
                where  opt_operacion = @i_operacionca
            
                select @i_modalidad_o = rot_fpago
                from   ca_rubro_op_tmp
                where  rot_operacion = @i_operacionca
                and    rot_concepto = 'INT'
            
                if @i_modalidad_o = 'P'
                   select @i_modalidad_o = 'V'
            
                if @i_modalidad_o = 'A'
                   select @i_modalidad_o = 'A'
            
                if @i_modalidad_o is null
                   select @i_modalidad_o = 'V'
             
                select @i_porcentaje = 0
            
                select @w_tasa_efa = 0
            end  ---(2)
        end ---(1)
   
        -- INSERCION EN LA TABLA TEMPORAL 
        insert into ca_rubro_op_tmp
              (rot_operacion,           rot_concepto,       rot_tipo_rubro,
               rot_fpago,               rot_prioridad,      rot_paga_mora,
               rot_provisiona,          rot_signo,          rot_factor,
               rot_referencial,         rot_signo_reajuste, rot_factor_reajuste,
               rot_referencial_reajuste,rot_valor,          rot_porcentaje,
               rot_gracia,              rot_porcentaje_aux, rot_principal,
               rot_porcentaje_efa,      rot_concepto_asociado,rot_garantia,
               rot_tipo_puntos,         rot_saldo_op,      rot_saldo_por_desem,
               rot_base_calculo,        rot_num_dec,
               rot_tipo_garantia,
               rot_nro_garantia,
               rot_porcentaje_cobertura,
               rot_valor_garantia,
               rot_tperiodo,
               rot_periodo,
               rot_saldo_insoluto,
               rot_porcentaje_cobrar,
               rot_financiado,
               rot_limite)
        select @i_operacionca,            @i_concepto,         ru_tipo_rubro,
        isnull(@w_fpago,ru_fpago), isnull(@i_prioridad,ru_prioridad),  ru_paga_mora,
               @i_provisiona,             @i_signo,            @i_factor,
               @i_referencial,            @i_signo_reajuste,   @i_factor_reajuste,
               @i_referencial_reajuste,   isnull(@w_valor,0),  isnull(@i_porcentaje,0),
               0,                         isnull(@w_porcentaje_aux,0),   @w_principal,
               @w_tasa_efa,               ru_concepto_asociado,0,
               @i_tipo_puntos,            @w_saldo_operacion,  @w_saldo_por_desem, 
               isnull(@w_base_calculo,@i_base_calculo), @i_num_dec_tapl,
               @i_tipo_garantia,   
               @w_nro_garantia,
               @w_porcentaje_cobertura,
               @w_valor_garantia,
               @i_tperiodo_c,
               @i_periodo_c,
               @w_saldo_insoluto,
               @i_porcentaje_cobrar,
               isnull(@i_financiado,ru_financiado),
               ru_limite
        from   ca_rubro
        where  ru_toperacion = @w_toperacion
        and    ru_moneda     = @w_moneda 
        and    ru_concepto   = @i_concepto 
      
        if @@error <> 0
        begin
            select @w_error = 710002
            goto ERROR
        end
    end    ----(3)
   
    if @w_tipo_rubro = 'I'
    begin 
        update ca_reajuste_det_tmp with(rowlock)
        set    red_signo = @i_signo,
               red_factor = @i_factor
        from   ca_reajuste_tmp,ca_reajuste_det_tmp
        where  re_operacion = @i_operacionca
        and    re_secuencial = red_secuencial
        and    re_operacion  = red_operacion
        and    re_fecha >= @s_date
        and    red_concepto = @i_concepto 
    end
   

    if @w_tipo_rubro = 'I'
    begin
        -- CONTROLAR QUE NO SE SOBREPASE EL INTERES BANCARIO CORRIENTE Y CONTROL DE TASA MAX Y MIN
        exec @w_error   = sp_rubro_control_ibc 
             @i_operacionca   = @i_operacionca,
             @i_concepto      = @i_concepto,
             @i_porcentaje    = @i_porcentaje,
             @i_periodo_o     = @i_periodo_o,
             @i_modalidad_o   = @i_modalidad_o,
             @i_num_periodo_o = @w_num_periodo_o 
      
        if @w_error <> 0
        begin
		    --GFP se suprime print
            --PRINT 'rubrotmp.sp Mensaje Informativo Tasa Total de Interes supera el maximo permitido...'
            --select @w_error = @w_return 
            goto ERROR
        end
        
        select @w_tasa_efa = @i_porcentaje
    end


    exec @w_error = sp_actualiza_rubros
         @i_operacionca = @i_operacionca,
         @i_tipo_rubro  = @w_tipo_rubro,
         @i_crear_op    = 'S'   
   
    if @w_error <> 0 
       goto ERROR
end

-- SELECCION DE LOS RUBROS TEMPORALES  
if @i_operacion = 'S' 
begin
   select @w_desc_perio = td_descripcion
   from   ca_tdividendo
   where  td_tdividendo  = @w_periodo_d

   if @i_mante_rubro = 'S' begin      
      select @w_tramite = opt_tramite
      from ca_operacion_tmp
      where  opt_operacion = @i_operacionca

      exec sp_matriz_garantias
      @i_operacion = 'S',
      @i_tramite   = @w_tramite,
      @i_crea_ext  = @i_crea_ext,     ---NR000353 ALIANZAS
      @o_valor     = @w_valor   out,
      @o_msg       = @o_msg_msv out

   end

    select 'Concepto'      = RTRIM(LTRIM((A.rot_concepto))),
          'Tipo'            = A.rot_tipo_rubro,
          'Forma Pago'      = A.rot_fpago,
          'Signo'           = A.rot_signo,
          'Factor'          = A.rot_factor,
          'Referencial'     = RTRIM(LTRIM((A.rot_referencial))),
          'Signo Reajuste'  = A.rot_signo_reajuste,
          'Factor Reajuste' = A.rot_factor_reajuste,
          'Refe.Reajuste'   = A.rot_referencial_reajuste,
          'Valor'           = A.rot_valor,
          'Porcentaje'      = A.rot_porcentaje,
          'Gracia'          = A.rot_gracia,
          'Prioridad'       = convert(int, A.rot_prioridad),
          'rot_valor_max'   = 0.00,
          'rot_valor_min'   = 0.00,
          'Base Calculo'    = A.rot_base_calculo,
          'rot_cuenta_abono'   = null,
          'rot_porcentaje_tea' = 0.00,
          'rot_porcentaje_dia' = 0.00,
          'rot_diferir'        = null,
          'rot_afectacion'     = '',  
          'rot_dias_diferir'   = 0,
          'rot_fdescuento'     = null,
          'rot_financiado'     = A.rot_financiado,
          'rot_fpago_tercero'  = null,
          'rot_cuenta_pago'    = null,
          'Gracia2'            =  isnull(A.rot_gracia,0),
          'rot_tasa_minima'    = 0.00,          
          'Descripcion Concepto' = B.co_descripcion,
          'Descripcion Tipo'     = C.valor,
          'Descripcion Forma de Pago' 	= null,
          'Financiado' = A.rot_financiado,
          'Tasa Maxima' = A.rot_tasa_maxima,
          'Tasa Minima' = A.rot_tasa_minima,
          'Diferido'    = A.rot_limite -- AMP 20211011
     from cob_cartera..ca_rubro_op_tmp A with (nolock),
          cob_cartera..ca_concepto B with (nolock),
     	  cobis..cl_catalogo C with (nolock),
     	  cobis..cl_tabla D with (nolock)
     	--  cob_fpm..fp_whenapplynodetype E  
    where A.rot_operacion = @i_operacionca
      and A.rot_concepto = B.co_concepto 
      and (A.rot_tipo_rubro = @i_tipo_rubro or @i_tipo_rubro is null)
      and D.tabla = 'fp_tipo_rubro'
      and C.tabla = D.codigo
      and A.rot_tipo_rubro = C.codigo
    --  and A.rot_fpago = E.want_applynodetype_id
      and (@i_reest = 'N' or rot_tipo_rubro <> 'C')  --En reestructuras no se modifica el Capital
    order by A.rot_concepto
	
   
   -- AUMENTADO PARA CREDITOS ROTATIVOS
   select opt_tipo
   from   ca_operacion_tmp
   where  opt_operacion = @i_operacionca
end

-- SELECCION DE LOS RUBROS TEMPORALES PARA DESEMBOLSOS PARCIALES
if @i_operacion = 'P' 
begin
    select 'Concepto'      = RTRIM(LTRIM((A.rot_concepto))),
          'Tipo'            = A.rot_tipo_rubro,
          'Forma Pago'      = A.rot_fpago,
          'Signo'           = A.rot_signo,
          'Factor'          = A.rot_factor,
          'Referencial'     = RTRIM(LTRIM((A.rot_referencial))),
          'Signo Reajuste'  = A.rot_signo_reajuste,
          'Factor Reajuste' = A.rot_factor_reajuste,
          'Refe.Reajuste'   = A.rot_referencial_reajuste,
          'Valor'           = A.rot_valor,
          'Porcentaje'      = A.rot_porcentaje,
          'Gracia'          = A.rot_gracia,
          'Prioridad'       = convert(int, A.rot_prioridad),
          'rot_valor_max'   = 0.00,
          'rot_valor_min'   = 0.00,
          'Base Calculo'    = A.rot_base_calculo,
          'rot_cuenta_abono'   = null,
          'rot_porcentaje_tea' = 0.00,
          'rot_porcentaje_dia' = 0.00,
          'rot_diferir'        = null,
          'rot_afectacion'     = '',  
          'rot_dias_diferir'   = 0,
          'rot_fdescuento'     = null,
          'rot_financiado'     = null,
          'rot_fpago_tercero'  = null,
          'rot_cuenta_pago'    = null,
          'Gracia2'            =  isnull(A.rot_gracia,0),
          'rot_tasa_minima'    = 0.00,          
          'Descripcion Concepto' = B.co_descripcion,
          'Descripcion Tipo'   = C.valor,
          'Descripcion Forma de Pago' 	= null,
          'Financiado' = A.rot_financiado,
          'Tasa Maxima' = A.rot_tasa_maxima,
          'Tasa Minima' = A.rot_tasa_minima
     from cob_cartera..ca_rubro_op_tmp A with (nolock),
          cob_cartera..ca_concepto B with (nolock),
     	  cobis..cl_catalogo C with (nolock),
     	  cobis..cl_tabla D with (nolock)
    where A.rot_operacion = @i_operacionca
      and A.rot_concepto = B.co_concepto 
      and (rot_tipo_rubro = 'C' or rot_fpago = 'L')
      and D.tabla = 'fp_tipo_rubro'
      and C.tabla = D.codigo
      and A.rot_tipo_rubro = C.codigo
    order by A.rot_concepto
	
   
   -- AUMENTADO PARA CREDITOS ROTATIVOS
   select opt_tipo
   from   ca_operacion_tmp
   where  opt_operacion = @i_operacionca
end


-- ELIMINACION DE RUBROS TEMPORALES 
if @i_operacion = 'D'
begin
   select @w_clave1 = convert(varchar(255),@i_operacionca)
   select @w_clave2 = convert(varchar(255),@i_concepto)

   exec @w_error = sp_tran_servicio
        @s_user    = @s_user, 
        @s_date    = @s_date, 
        @s_ofi     = @s_ofi,  
        @s_term    = @s_term, 
        @i_tabla   = 'ca_rubro_op',
        @i_clave1  = @w_clave1,
        @i_clave2  = @w_clave2
   
   if @w_error <> 0
   begin
      goto ERROR
   end    

   
   -- VALIDACION SI EL RUBRO ES FINANCIADO
   select @w_valor_financiado = sum(rot_valor) 
     from ca_rubro_op_tmp with (nolock)
    where rot_operacion = @i_operacionca
      and rot_concepto  = @i_concepto
      and rot_financiado = 'S' 
      and rot_valor > 0
   
   -- VALIDACION SI EXISTEN OTROS RUBROS FINANCIADOS
   select @w_otros_financiado = sum(rot_valor) 
     from ca_rubro_op_tmp with (nolock)
    where rot_operacion = @i_operacionca
      and rot_concepto  <> @i_concepto
      and rot_financiado = 'S' 
      and rot_valor > 0
      
   if isnull(@w_otros_financiado,0) > 0
   begin
      select @w_base_calculo = min(rot_base_calculo)
        from ca_rubro_op_tmp with (nolock) 
       where rot_operacion = @i_operacionca
         and rot_financiado = 'S'
         and rot_concepto_asociado is null 
   end
   
   --GFP 17/08/2022 Actualizacion de cuota a 0 para calculo del gentabla
   update ca_operacion_tmp  with(rowlock)
   set opt_cuota = 0
   where opt_operacion = @i_operacionca   
   
   if isnull(@w_valor_financiado,0) > 0 and isnull(@w_otros_financiado,0) = 0
   begin
     
      select @w_base_calculo = rot_base_calculo 
        from ca_rubro_op_tmp  with (nolock)
       where rot_operacion = @i_operacionca
         and rot_concepto  = @i_concepto
         and rot_financiado = 'S' 
     
     if @w_monto_orig = @w_monto_aprobado
     begin
        update ca_operacion_tmp  with(rowlock)
           set opt_monto = @w_base_calculo,
               opt_monto_aprobado = @w_base_calculo
         where opt_operacion = @i_operacionca
     
        if @@error <> 0
           return 710002

        update ca_rubro_op_tmp  with(rowlock)
           set rot_valor = @w_base_calculo
        where rot_operacion = @i_operacionca
          and rot_concepto  = 'CAP'
          
        if @@error <> 0
           return 705003
     end    
     else
     begin
        update ca_operacion_tmp  with(rowlock)
          set opt_monto = @w_base_calculo 
        where opt_operacion = @i_operacionca
     
        if @@error <> 0
           return 710002

        update ca_rubro_op_tmp  with(rowlock)
           set rot_valor = @w_base_calculo 
        where rot_operacion = @i_operacionca
          and rot_concepto  = 'CAP'
          
        if @@error <> 0
           return 705003
     end

     delete ca_rubro_op_tmp with(rowlock)
     where  rot_operacion = @i_operacionca
     and    rot_concepto  = @i_concepto
     
     if @@error <> 0
     begin
        select @w_error = 710003
        goto ERROR
     end 
     
     -- REGENERA LA TABLA
     exec @w_error       = sp_gentabla
     @i_operacionca      = @i_operacionca,
     @i_tabla_nueva      = 'S',
     @i_dias_gracia      = null,
     @i_actualiza_rubros = 'N',
     @i_crear_op         = 'S',
     @i_control_tasa     = null,
     @i_periodo          = null,
     @i_operacion_activa = null,
     @i_gracia_pend      = null,                                -- REQ 175: PEQUEÑA EMPRESA
     @i_divini_reg       = null,                                 -- REQ 175: PEQUEÑA EMPRESA
     @i_reestructuracion = null,                           -- PAQUETE 2 - REQ 212 BANCA RURAL - 28/JUL/2011
     @i_crea_ext         = null,
     @i_simulacion_tflex = null,
     @i_tasa             = null,									   --SRO Santander
     @i_regenera_rubro   = 'S',                             --AGI 28/MAY/2019
     @i_grupal           = null
            
     if @w_error <> 0 begin
        select @w_error = @w_error
        goto ERROR
     end          
   end
   else -- SI EXISTEN MAS RUBROS FINANCIADOS SE ELIMINAN TODOS
   BEGIN
   
      if isnull(@w_otros_financiado,0) > 0 and isnull(@w_valor_financiado,0) > 0 -- KDR Validación para que se eliminen los otros financiados solo si el rubro que se está eliminando es financiado
      begin
         
         if @w_monto_orig = @w_monto_aprobado
         begin
           update ca_operacion_tmp  with(rowlock)
              set opt_monto = @w_base_calculo,
                  opt_monto_aprobado = @w_base_calculo 
            where opt_operacion = @i_operacionca
         
           if @@error <> 0
              return 710002
         
           update ca_rubro_op_tmp  with(rowlock)
              set rot_valor = @w_base_calculo 
           where rot_operacion = @i_operacionca
             and rot_concepto  = 'CAP'
             
           if @@error <> 0
              return 705003
         end    
         else
         begin
           update ca_operacion_tmp  with(rowlock)
             set opt_monto = @w_base_calculo 
           where opt_operacion = @i_operacionca
         
           if @@error <> 0
              return 710002
         
           update ca_rubro_op_tmp  with(rowlock)
              set rot_valor = @w_base_calculo
           where rot_operacion = @i_operacionca
             and rot_concepto  = 'CAP'
             
           if @@error <> 0
              return 705003
         end
		     
         -- KDR 14/09/2022 Tabla temporal de Rubros Financiados			 
		 select rot_concepto as 'concepto' into #rubs_financ from ca_rubro_op_tmp where rot_operacion = @i_operacionca and isnull(rot_financiado,'N') = 'S'
         
         -- ELIMINA RUBROS ASOCIADOS DE RUBROS FINANCIADOS
         delete ca_rubro_op_tmp with(rowlock)
		 from #rubs_financ
         where  rot_operacion = @i_operacionca
		 and rot_concepto_asociado = concepto   -- KDR 14/09/2022
         --and rot_concepto_asociado in (select rot_concepto from ca_rubro_op_tmp where  rot_operacion = @i_operacionca and isnull(rot_financiado,'N') = 'S')
         
         if @@error <> 0
         begin
            select @w_error = 710003
            goto ERROR
         end 

         -- ELIMINA RUBROS FINANCIADOS
         delete ca_rubro_op_tmp with(rowlock)
         where  rot_operacion = @i_operacionca
         and isnull(rot_financiado,'N') = 'S'
         
         if @@error <> 0
         begin
            select @w_error = 710003
            goto ERROR
         end 
         
         -- REGENERA LA TABLA
         exec @w_error       = sp_gentabla
         @i_operacionca      = @i_operacionca,
         @i_tabla_nueva      = 'S',
         @i_dias_gracia      = null,
         @i_actualiza_rubros = 'N',
         @i_crear_op         = 'S',
         @i_control_tasa     = null,
         @i_periodo          = null,
         @i_operacion_activa = null,
         @i_gracia_pend      = null,                                -- REQ 175: PEQUEÑA EMPRESA
         @i_divini_reg       = null,                                 -- REQ 175: PEQUEÑA EMPRESA
         @i_reestructuracion = null,                           -- PAQUETE 2 - REQ 212 BANCA RURAL - 28/JUL/2011
         @i_crea_ext         = null,
         @i_simulacion_tflex = null,
         @i_tasa             = null,									   --SRO Santander
         @i_regenera_rubro   = 'S',                             --AGI 28/MAY/2019
         @i_grupal           = null
                
         if @w_error <> 0 begin
            select @w_error = @w_error
            goto ERROR
         end
       
      end
   end
   
   --XMA SI TIENE RUBRO ASOCIADO SE ELIMINA
   select @w_rubro_iva      = ru_concepto
   from   ca_rubro
   where  ru_concepto_asociado = @i_concepto    
   
   if exists (select 1
              from   ca_rubro_op_tmp with (nolock)
              where  rot_operacion = @i_operacionca 
              and    rot_concepto = @w_rubro_iva) 
   begin
      delete ca_rubro_op_tmp with(rowlock)
      where  rot_operacion = @i_operacionca
      and    rot_concepto  = @w_rubro_iva
      
      if @@error <> 0
      begin
         select @w_error = 710003
         goto ERROR
      end 
   end
   
   delete ca_rubro_op_tmp with(rowlock)
   where rot_operacion = @i_operacionca
   and rot_concepto = @i_concepto
   
   if @@error <> 0
   begin
      select @w_error = 710003
      goto ERROR
   END
   
   if @i_concepto = @w_timbre
   begin
      if exists (select 1
                 from   ca_rubro_op_tmp with (nolock)
                 where  rot_operacion = @i_operacionca
                 and    rot_concepto  = @w_rubro_timbac)
      begin
         delete ca_rubro_op_tmp with(rowlock)
         where  rot_operacion = @i_operacionca
         and    rot_concepto  = @w_rubro_timbac
      end
   end
   
   if @i_concepto = @w_rubro_timbac
   begin
      if exists (select 1
                 from   ca_rubro_op_tmp with (nolock)
                 where  rot_operacion = @i_operacionca
                 and    rot_concepto  = @w_timbre)
      begin
         delete ca_rubro_op_tmp with(rowlock)
         where  rot_operacion = @i_operacionca
         and    rot_concepto  = @w_timbre
      end
   end
end

-- QUERY DE UN RUBRO 
if @i_operacion = 'Q'
begin
   select @w_concepto    = rot_concepto,
          @w_descripcion = (select substring(co_descripcion,1,30)
                            from ca_concepto                    
                   where co_concepto = X.rot_concepto),
          @w_tipo_puntos     = rot_tipo_puntos,
          @w_tipo_valor      = rtrim(ltrim(rot_referencial)),
          @w_tipo_rubro      = rot_tipo_rubro,
          @w_provisiona      = rot_provisiona,
          @w_prioridad       = rot_prioridad,
          @w_deb_automatico  = '',
          @w_valor_default   = rot_factor,
          @w_signo_default   = rot_signo,
          @w_valor_reaj      = rot_factor_reajuste,
          @w_signo_reaj      = rot_signo_reajuste,
          @w_valor_rubro     = rot_valor,
          @w_porcentaje      = rot_porcentaje_aux,
          @w_forma_pago      = rot_fpago,
          @w_saldo_operacion = rot_saldo_op,
          @w_saldo_por_desem = rot_saldo_por_desem, 
          @w_base_calculo      = isnull(rot_base_calculo, 0),
          @w_referencial_reaj  = rot_referencial_reajuste,
          @w_num_dec_tapl      = rot_num_dec,
          @w_periodo           = rot_periodo,
          @w_tperiodo          = rot_tperiodo,
          @w_tipo_garantia     = rot_tipo_garantia,
          @w_porcentaje_cobrar = rot_porcentaje_cobrar,
          @w_valor_garantia    = rot_valor_garantia,
          @w_financiado        = rot_financiado,
          @w_tasa_maxima       = rot_tasa_maxima,
          @w_tasa_minima       = rot_tasa_minima,
		  @w_ru_limite         = rot_limite
   from   ca_rubro_op_tmp X with (nolock)
   where  rot_operacion = @i_operacionca
   and    rot_concepto    = @i_concepto
 
   if @w_tipo_valor is not null
   begin
      -- TIENE UN VALOR REFERENCIAL 
      select @w_desc_tipo    = va_descripcion,
             @w_referencial  = vd_referencia,
             @w_signo_maximo = vd_signo_maximo,
             @w_valor_maximo = vd_valor_maximo,
             @w_signo_minimo = vd_signo_minimo,
             @w_valor_minimo = vd_valor_minimo
      from   ca_valor,ca_valor_det
      where  va_tipo = @w_tipo_valor
      and    vd_tipo   = @w_tipo_valor
      and    vd_sector = @w_sector
  
      if @w_referencial is not null
      begin
         select @w_desc_referencial =  tv_descripcion,
                @w_modalidad        =  tv_modalidad,
                @w_periodicidad     =  tv_periodicidad, 
                @w_tipo_tasa        =  tv_tipo_tasa
         from   ca_tasa_valor with (nolock)
         where  tv_nombre_tasa = @w_referencial
         and    tv_estado        = 'V'
         
         select @w_desc_perio = td_descripcion
         from   ca_tdividendo with (nolock)
         where  td_tdividendo  = @w_periodicidad
         
         select @w_fecha = max(vr_fecha_vig)
         from   ca_valor_referencial with (nolock)
         where  vr_tipo      = @w_referencial
         and    vr_fecha_vig <= @w_fecha_ult_proceso
         
         select @w_valor_referencial = vr_valor 
         from   ca_valor_referencial  with (nolock)
         where  vr_tipo     = @w_referencial
         and    vr_secuencial = (select max(vr_secuencial)
                                 from ca_valor_referencial
                                 where vr_tipo      = @w_referencial
                                 and   vr_fecha_vig = @w_fecha)
         
         if @@rowcount = 0
         begin   --NO EXISTE UNA TASA REFERENCIAL PARA ESA FECHA
		    --GFP se suprime print
            --PRINT '(rubrotmp.sp)error t_referencial, fecha_ult_proceso ' + cast(@w_referencial as varchar) + ' ' + cast(@w_fecha_ult_proceso as varchar)
			select @w_error = 701177
            goto ERROR
         end
 
         exec sp_calcula_valor 
              @i_signo     = @w_signo_default,
              @i_base      = @w_valor_referencial,
              @i_factor    = @w_valor_default,
              @o_resultado = @w_total_default out
         
         exec sp_calcula_valor 
              @i_signo     = @w_signo_maximo,
              @i_base      = @w_valor_referencial,
              @i_factor    = @w_valor_maximo,
              @o_resultado = @w_total_maximo out
         
         exec sp_calcula_valor 
              @i_signo     = @w_signo_minimo,
              @i_base      = @w_valor_referencial,
              @i_factor    = @w_valor_minimo,
              @o_resultado = @w_total_minimo out
      end
      ELSE
      begin
         if @w_tipo_rubro in ('I','O','M','Q')
            if @w_tipo_rubro in ('I')
               select @w_valor_default = @w_total_default,
                      @w_total_default = @w_total_default
            else
               select @w_valor_default = @w_porcentaje,
                      @w_total_default = @w_porcentaje
         else
            select @w_valor_default = @w_valor_rubro, 
                   @w_total_default = @w_valor_rubro
      end
   end
   ELSE
   begin
      if @w_tipo_rubro in ('I','O','M','Q')
         select @w_valor_default = @w_porcentaje,
                @w_total_default = @w_porcentaje
      else
         select @w_valor_default = @w_valor_rubro, 
                @w_total_default = @w_valor_rubro
   end
   
   select @w_desc_periodo = td_descripcion
   from ca_tdividendo with (nolock)
   where td_tdividendo  = @w_tperiodo
   
   select @w_des_tipo_garantia = tc_descripcion
   from   cob_custodia..cu_tipo_custodia with (nolock)
   where  tc_tipo = @w_tipo_garantia
   
   select @o_provisiona=@w_provisiona,
          @o_prioridad=@w_prioridad,
          @o_valor_referencial= @w_valor_referencial,
          @o_signo_reaj=@w_signo_reaj,
          @o_valor_reaj=@w_valor_reaj,
          @o_referencial=@w_referencial,
          @o_referencial_reaj=@w_referencial_reaj,
          @o_modalidad= @w_modalidad,
          @o_periodicidad=@w_periodicidad
   
   select rtrim(ltrim(@w_concepto)),          @w_descripcion,       rtrim(ltrim(@w_tipo_valor)),
          @w_desc_tipo,         @w_provisiona,        @w_prioridad,
          @w_deb_automatico,    @w_referencial,       @w_desc_referencial,
          @w_signo_default,     @w_valor_default,     @w_signo_maximo,
          @w_valor_maximo,      @w_signo_minimo,      @w_valor_minimo,
          @w_valor_referencial, @w_total_default,     @w_total_maximo,
          @w_total_minimo,      @w_modalidad,         @w_periodicidad,
          @w_desc_perio,        @w_tipo_rubro,        @w_tipo_puntos,
          @w_base_calculo, ---25
          @w_saldo_operacion, ---26
          @w_saldo_por_desem, ---27
          @w_tipo_tasa,    ---28    
          @w_num_dec_tapl, --- 29
          @w_tperiodo,          ---30
          @w_periodo,           ---31
          @w_desc_periodo,      ---32
          @w_tipo_garantia,     ---33
          @w_des_tipo_garantia,  ---34
          @w_porcentaje_cobrar,  ---35
          @w_financiado,
          @w_tasa_maxima,
          @w_tasa_minima,
		  @w_ru_limite
          
   return 0
end

--PQU integración se incluye nueva operación para consulta de rubros en simulación
if @i_operacion = 'R'
begin
   select @w_concepto       = rot_concepto,
          @w_descripcion    = (select substring(co_descripcion,1,30)
                                 from cob_cartera..ca_concepto
                                where co_concepto = X.rot_concepto),
          @w_tipo_valor     = rot_referencial,     
          @w_reajuste       = rot_referencial_reajuste,
          @w_tipo_rubro     = rot_tipo_rubro,
          @w_provisiona     = rot_provisiona,
          @w_prioridad      = rot_prioridad,
          @w_deb_automatico = '',
          @w_valor_default  = rot_factor,
          @w_signo_default  = rot_signo,
          @w_valor_reaj     = rot_factor_reajuste,
          @w_signo_reaj     = rot_signo_reajuste,
          @w_valor_rubro    = rot_valor,
          @w_porcentaje     = rot_porcentaje,
          @w_base_calculo   = rot_base_calculo,
          @w_concepto_asociado = rot_concepto_asociado,
          @w_financiado        = rot_financiado,
		  @w_ru_limite         = rot_limite
     from cob_cartera..ca_rubro_op_tmp X with (nolock)
    where rot_operacion = @i_operacionca
      and rot_concepto  = @i_concepto

   if @w_tipo_valor is not null
   begin
       
-- TIENE UN VALOR REFERENCIAL 
      select @w_desc_tipo    = va_descripcion,
             @w_referencial  = vd_referencia,
             @w_signo_maximo = vd_signo_maximo,
             @w_valor_maximo = vd_valor_maximo,
             @w_signo_minimo = vd_signo_minimo,
             @w_valor_minimo = vd_valor_minimo
        from cob_cartera..ca_valor with (nolock),cob_cartera..ca_valor_det with (nolock)
       where va_tipo   = @w_tipo_valor
         and vd_tipo   = @w_tipo_valor
         and vd_sector = @w_sector
      if @w_referencial is not null
      begin
	   
		 select @w_desc_referencial =  tv_descripcion
         from   ca_tasa_valor with (nolock)
         where  tv_nombre_tasa = @w_referencial
         and    tv_estado        = 'V'
			
         select @w_valor_referencial = vr_valor 
           from  cob_cartera..ca_valor_referencial with (nolock)
          where vr_tipo     = @w_referencial
            and vr_secuencial = (select max(vr_secuencial)
                                   from cob_cartera..ca_valor_referencial
                                  where vr_tipo      = @w_referencial
                                    and vr_fecha_vig <= @w_fecha_ini)
         exec cob_cartera..sp_calcula_valor 
              @i_signo     = @w_signo_default,
              @i_base      = @w_valor_referencial,
              @i_factor    = @w_valor_default,
              @o_resultado = @w_total_default out
         exec cob_cartera..sp_calcula_valor 
              @i_signo     = @w_signo_maximo,
              @i_base      = @w_valor_referencial,
              @i_factor    = @w_valor_maximo,
              @o_resultado = @w_total_maximo out
         exec cob_cartera..sp_calcula_valor 
              @i_signo     = @w_signo_minimo,
              @i_base      = @w_valor_referencial,
              @i_factor    = @w_valor_minimo,
              @o_resultado = @w_total_minimo out
      end
      else
      begin
         if @w_tipo_rubro in ('I','O','M','Q')
            select @w_valor_default = @w_porcentaje,                   
                   @w_total_default = @w_porcentaje
         else
            select @w_valor_default = @w_valor_rubro, 
                   @w_total_default = @w_valor_rubro
      end
   end 
   else
   begin
      if @w_tipo_rubro in ('I','O','M','Q')
         select @w_valor_default = @w_porcentaje,
                @w_total_default = @w_porcentaje
      else
         select @w_valor_default = @w_valor_rubro, 
                @w_total_default = @w_valor_rubro
   end
   -- ANALISIS PARA REAJUSTE DE INTERESES 
   if @w_tipo_rubro in ('I', 'M') and @w_reajuste is not null
   begin
      -- TIENE UN VALOR REFERENCIAL 
      select @w_desc_reajuste     = va_descripcion,
             @w_referencial_reaj  = vd_referencia,
             @w_signo_maximo_reaj = vd_signo_maximo,     
             @w_valor_maximo_reaj = vd_valor_maximo,
             @w_signo_minimo_reaj = vd_signo_minimo,
             @w_valor_minimo_reaj = vd_valor_minimo
        from cob_cartera..ca_valor with (nolock),cob_cartera..ca_valor_det with (nolock)
       where va_tipo   = @w_reajuste    
         and vd_tipo   = @w_reajuste
         and vd_sector = @w_sector
      if @w_referencial_reaj is not null
      begin
	  		 
		 select @w_desc_referencial_reaj =  tv_descripcion
         from   ca_tasa_valor with (nolock)
         where  tv_nombre_tasa = @w_referencial_reaj
         and    tv_estado        = 'V'
			
         select @w_valor_referencial_reaj = vr_valor 
           from cob_cartera..ca_valor_referencial with (nolock)
          where vr_tipo = @w_referencial_reaj          
            and vr_secuencial = (select max(vr_secuencial)
                                   from cob_cartera..ca_valor_referencial
                                  where vr_tipo = @w_referencial_reaj
                                    and vr_fecha_vig <= @w_fecha_ini)
         exec cob_cartera..sp_calcula_valor 
              @i_signo     = @w_signo_reaj,
              @i_base      = @w_valor_referencial_reaj,
              @i_factor    = @w_valor_reaj,
              @o_resultado = @w_total_reaj out
         exec cob_cartera..sp_calcula_valor 
              @i_signo     = @w_signo_maximo_reaj,
              @i_base      = @w_valor_referencial_reaj,
              @i_factor    = @w_valor_maximo_reaj,
              @o_resultado = @w_total_maximo_reaj out
         
         exec cob_cartera..sp_calcula_valor 
              @i_signo     = @w_signo_minimo_reaj,
              @i_base      = @w_valor_referencial_reaj,
              @i_factor    = @w_valor_minimo_reaj,
              @o_resultado = @w_total_minimo_reaj out
       
      end
      else
      begin
         if @w_tipo_rubro in ('I','O','M')
            select @w_valor_reaj = @w_porcentaje,
                   @w_total_reaj = @w_porcentaje
         if @w_tipo_rubro = 'Q'
            select @w_valor_reaj = @w_valor_rubro,    
                   @w_total_reaj = @w_porcentaje
         else
            select @w_valor_reaj = @w_valor_rubro, 
                   @w_total_reaj = @w_valor_rubro
      end
   end
   else
   begin

      if @w_tipo_rubro in ('I','O','M','Q')
         select @w_valor_reaj = @w_porcentaje,
                @w_total_reaj = @w_porcentaje
     else
         select @w_valor_reaj = @w_valor_rubro, 
                @w_total_reaj = @w_valor_rubro
   end
   
   select 
   @w_concepto,          @w_descripcion,           @w_tipo_valor,    
   @w_desc_tipo,         @w_provisiona,            @w_prioridad,
   @w_deb_automatico,    @w_referencial,           @w_desc_referencial,
   @w_signo_default,     @w_valor_default,         @w_signo_maximo,
   @w_valor_maximo,      @w_signo_minimo,          @w_valor_minimo,--15
   @w_valor_referencial, @w_total_default,         @w_total_maximo,
   @w_total_minimo,      @w_reajuste,              @w_desc_reajuste,
   @w_referencial_reaj,  @w_desc_referencial_reaj, @w_signo_reaj, 
   @w_valor_reaj,        @w_signo_maximo_reaj,     @w_valor_maximo_reaj,
   @w_signo_minimo_reaj, @w_valor_minimo_reaj,     @w_valor_referencial_reaj,--30
   @w_total_reaj,        @w_total_maximo_reaj,     @w_total_minimo_reaj,
   @w_total_maximo,      @w_total_minimo,          isnull(@w_monto,0),--IOR para Web en base calculo el valor del capital	 
   @w_tipo_rubro,        @w_concepto_asociado,     @w_base_calculo, --DMO SE AÑADE @w_base_calculo, @w_ru_limite,@w_financiado
   @w_ru_limite,		 @w_financiado,'', 
   '',0,0,
   '','','',
   0,'',0,
   '','','',
   '','',0,
   '',0,0,
   ''

   return 0
end
--fin PQU

return 0

ERROR:

if @i_externo = 'S' 
begin
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null,
        @t_from   = @w_sp_name,
        @i_num    = @w_error
--        @i_cuenta = ' '
   
   return @w_error
end
ELSE
   return @w_error

GO

