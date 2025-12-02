/*********************************************************************/
/*   NOMBRE LOGICO:      gentabla.sp	                             */
/*   NOMBRE FISICO:      sp_gentabla                                 */
/*   BASE DE DATOS:      cob_cartera                                 */
/*   PRODUCTO:           Cartera                                     */
/*   DISENADO POR:       Fabian de la Torre                          */
/*   FECHA DE ESCRITURA: Ene. 1998                                   */
/*********************************************************************/
/*                     IMPORTANTE                                    */
/*   Este programa es parte de los paquetes bancarios que son        */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,   */
/*   representantes exclusivos para comercializar los productos y    */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida  */
/*   y regida por las Leyes de la República de España y las          */
/*   correspondientes de la Unión Europea. Su copia, reproducción,   */
/*   alteración en cualquier sentido, ingeniería reversa,            */
/*   almacenamiento o cualquier uso no autorizado por cualquiera     */
/*   de los usuarios o personas que hayan accedido al presente       */
/*   sitio, queda expresamente prohibido; sin el debido              */
/*   consentimiento por escrito, de parte de los representantes de   */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto   */
/*   en el presente texto, causará violaciones relacionadas con la   */
/*   propiedad intelectual y la confidencialidad de la información   */
/*   tratada; y por lo tanto, derivará en acciones legales civiles   */
/*   y penales en contra del infractor según corresponda.            */
/*********************************************************************/
/*                     PROPOSITO                                     */
/*	Genera la tabla de amortizacion automatica.	                     */
/*********************************************************************/
/*                     MODIFICACIONES                                */
/*   FECHA              AUTOR              RAZON                     */
/*   OCT-2005       Elcira Pelaez  Cambios para el BAC  DD           */
/*   MAR-2006       Elcira Pelaez  NR-433                            */
/*   MAR-2006       Fabian Q.      NR 461                            */
/*   MAY-2006       Fabian Q.      DEFECTO 407  NR 461               */
/*   2008-03-25     MRoa           NB-GAP-EF-CCA-014 Comision MIPYMES*/
/*   2008-03-26     MRoa           NB-GAP-EF-CCA-015 Comision FNG    */
/*   2010-01-03     Johan Ardila   REQ 197 - USAID FAG               */
/*   2014-05-13     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/*   2015-05-22     Jorge Salazar  CGS-S112643                       */
/*   15/04/2019     A. Giler        Operaciones Grupales             */
/*   10/06/2019     Luis Ponce     Creacion OP.Grupal Te Creemos     */
/*   02/01/2020     Luis Ponce     Manejo dia fijo-varios tplazo(SVA)*/
/*   05/11/2020     EMP-JJEC       Rubros Financiados                */
/*   DIC-11-2020   Patricio Narvaez Incluir rubro FECI               */
/*   MAY/18/2022   Kevin Rodríguez  Se comenta recálculo de Seguro   */
/*   Jun/01/2022   Guisela Fernandez   Se comenta prints             */
/*   AGO/23/2022   Kevin Rodríguez  R192160 Valida mes de gracia     */
/*   OCT/19/2022   Kevin Rodríguez  R195663 Quitar Val. mes de gracia*/
/*   FEB/02/2022   G.Fernandez      S771318 Eliminacion de cuotas    */
/*                                  adicionales                      */
/*   ABR/05/2023   G.Fernandez      S785442 Se ingresa campo para    */
/*                                  categoria de plazo               */
/*   ABR/28/2023   K. Rodríguez     S814865 Validar divs mensuales   */
/*   AGO/21/2023   K. Rodríguez     R214508 Ajuste tipo reduccion de */ 
/*                                  Ops hijas                        */
/*********************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_gentabla')
   drop proc sp_gentabla
go
---NR000353 abr.04.2013
create proc sp_gentabla
   @s_user                         login        = null,
   @s_date                         datetime     = null,
   @s_term                         varchar(30)  = null,
   @s_ofi                          smallint     = null,
   @i_operacionca                  int,
   @i_tabla_nueva                  char(1),
   @i_dias_gracia                  smallint     = 0, 
   @i_actualiza_rubros             char(1)      = 'N',
   @i_control_tasa                 char(1)      = 'S',
   @i_crear_op                     char(1)      = 'N',
   @i_periodo                      catalogo     = null,
   @i_causacion                    char(1)      = 'L', 
   @i_batch_dd                     char(1)      = 'N',
   @i_tramite_hijo                 int          = null,
   @i_reajusta_cuota_uno           char(1)      = 'N', 
   @i_reajuste                     char(1)      = 'N', 
   @i_cuota_reajuste               smallint     = null,               -- REQ 175: PEQUEÑA EMPRESA
   @i_operacion_activa             int          = null,
   @i_cuota_desde_cap              int          = null,
   @i_cuota_abnextra               smallint     = null,
   @i_desde_abnextra               char(1)      = 'N',
   @i_accion                       char(1)      = 'N',                -- REQ 175: PEQUEÑA EMPRESA
   @i_cuota_accion                 smallint     = null,               -- REQ 175: PEQUEÑA EMPRESA
   @i_gracia_pend                  char(1)      = 'N',                -- REQ 175: PEQUEÑA EMPRESA
   @i_divini_reg                   smallint     = null,               -- REQ 175: PEQUEÑA EMPRESA
   @i_reestructuracion             char(1)      = 'N',                -- PAQUETE 2 - REQ 212: BANCA RURAL - 28/JUL/2011
   @i_regenera_rubro               char(1)      = 'S',
   @i_crea_ext                     char(1)      = 'S',
   @i_simulacion_tflex             char         = 'N',
   @i_cambio_fecha                 char(1)      = 'N',
   @i_promocion                    char(1)      = 'N',
   @i_tasa                         float        = null,               --JSA Santander
   @i_fecha_ven_pc                 DATETIME     = NULL,               --LPO TEC  
   @i_tasa_grupal                  FLOAT        = NULL,               --LPO TEC
   @i_grupal                       CHAR(1)      = NULL,               --LPO TEC   
   @i_cambio_plazo                 char(1)      = 'N',     
   @o_fecha_fin                    datetime     = null out,
   @o_plazo                        int          = null out,
   @o_tplazo                       catalogo     = null out,
   @o_cuota                        money        = null out,
   @o_msg_msv                      varchar(255) = null out
     
as
declare 
   @w_error                        int,
   @w_return                       int,
   @w_dias_plazo                   int,
   @w_dias_dividendo               int,
   @w_oficina                      smallint,
   @w_monto_cap                    money, 
   @w_tasa_int                     float,
   @w_operacionca                  int,
   @w_fecha_ini                    datetime,
   @w_tplazo                       catalogo,
   @w_plazo                        int,   
   @w_tdividendo                   catalogo,
   @w_periodo_cap                  smallint,
   @w_periodo_int                  smallint,
   @w_dist_gracia                  char(1),
   @w_gracia_cap                   smallint,
   @w_gracia_int                   smallint,
   @w_mes_gracia                   tinyint,
   @w_periodo_cal                  smallint,
   @w_tipo_tabla                   catalogo,
   @w_dia_fijo                     tinyint,
   @w_cuota                        float,
   @w_dias_anio                    smallint,
   @w_evitar_feriados              char(1),
   @w_moneda                       tinyint,
   @w_num_dec                      tinyint,
   @w_div_vigente                  smallint,
   @w_divcap_original              smallint,
   @w_tipo                         catalogo ,
   @w_periodo_crecimiento          smallint,
   @w_tasa_crecimiento             float,
   @w_plazo_aux                    int,
   @w_rotativo                     char(1),
   @w_opcion_cap                   char(1),
   @w_tasa_cap                     float,
   @w_dividendo_cap                smallint,
   @w_interes                      money, 
   @w_di_num_dias                  smallint,
   @w_int_total                    money,
   @w_tipo_crecimiento             char(1),
   @w_base_calculo                 char(1),
   @w_ult_dia_habil                char(1),
   @w_recalcular                   char(1),
   @w_dias_interes                 smallint,
   @w_dias_op                      int,
   @w_dias_di                      int,
   @w_fecha_pri_cuot               datetime,
   @w_tipo_redondeo                tinyint, 
   @w_ult_dividendo                int,     
   @w_convierte_tasa               char(1), 
   @w_toperacion                   varchar(10),
   @w_tramite                      int,
   @w_valor_rubro                  money,
   @w_prueba_int                   float,
   @w_tipo_linea                   catalogo,
   @w_cuotas_activa                int,
   @w_per_cap_cuotas               smallint,
   @w_primera_cuota_cap            smallint,
   @w_cod_gar_fng                  catalogo,
   @w_parametro_fng                catalogo,
   @w_pmipymes                     catalogo,
   @w_parametro_usaid              catalogo,             -- JAR REQ 197
   @w_parametro_fag                catalogo,             -- JAR REQ 197
   @w_banco                        cuenta,               -- 09/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_conc_org                     catalogo,             -- 09/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_conc_dest                    catalogo,             -- 09/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_divf_ini                     smallint,             -- 09/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_divf_fin                     smallint,             -- 09/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_tipo_rubro                   char(1),              -- 09/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_vlr_gracia                   money,                -- 09/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_desplazamiento               char(1),              -- 17/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_cuota_desde                  smallint,             -- 17/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_concepto_cap                 varchar(30),          -- 17/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_concepto_int                 varchar(30),          -- 17/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
   @w_par_fag_uni                  catalogo,
   @w_estado_op                    smallint,
   @w_est_credito                  tinyint ,
   @w_periodico_e                  float, 
   @w_plazo_e                      float, 
   @w_plazo_o                      int, 
   @w_periodico                    int, 
   @w_diferencia                   float,
   @w_reestructuracion             char(1),
   @w_spread                       float,
   @w_signo                        char(1),
   @w_alterna                      catalogo,
   @w_porcentaje_mipymes           float,
   @w_dias_cuota1                  smallint,
    --REQ 402
   @w_parametro_fgu                varchar(10),
   @w_colateral                    catalogo,
   @w_tipo_garantia                varchar(10),
   @w_garantia                     varchar(10),
   @w_cod_garantia                 varchar(10),
   @w_rubro                        char(1),
   @w_tabla_rubro                  varchar(30),
   @w_concepto_des                 varchar(10),
   @w_concepto_per                 varchar(10),
   @w_iva_des                      varchar(10),
   @w_iva_per                      varchar(10),
   @w_cont                         int,
   @w_cod_gar_usaid                catalogo,
   @w_cod_gar_fag                  catalogo,
   @w_asociado                     catalogo,
   @w_tr_tipo                      char(1), 
   @w_tipo_norm                    int,
   @w_div_mensuales                char(1),   ------REAM CAMBIO
   @w_est_novigente                tinyint,
   @w_ref_grupal                   cuenta,
   @w_grupo                        INT,
   @w_num_dividendos               int,  --LPO TEC Manejo dia fijo-varios tplazo(SVA)
   @w_monto                        money,
   @w_monto_aprobado               money,
   @w_valor_financiado             money,
   @w_rot_base_calculo             money,
   @w_monto_rub_fin                money,
   @w_param_tiempo_plazo           int,
   @w_num_dias_op                  int,
   @w_categoria_plazo              char(1)
   
-- FQ: NR-392
declare
   @w_tflexible                     catalogo

select @w_tflexible = pa_char
from   cobis..cl_parametro
where  pa_producto  = 'CCA'
and    pa_nemonico  = 'TFLEXI'
set transaction isolation level read uncommitted

create table #conceptos_gen (
codigo    varchar(10),
tipo_gar  varchar(64)
)

create table #rubros_gen (
garantia      varchar(10),
rre_concepto  varchar(64),
tipo_concepto varchar(10),
iva           varchar(5),
)

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_credito    = @w_est_credito out,
@o_est_novigente  = @w_est_novigente out

/*CODIGO PADRE GARANTIA DE FNG*/
select @w_cod_gar_fng = pa_char
from cobis..cl_parametro
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'
set transaction isolation level read uncommitted

select @w_cod_gar_usaid = pa_char
from cobis..cl_parametro
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODUSA'
set transaction isolation level read uncommitted

select @w_cod_gar_fag = pa_char
  from cobis..cl_parametro with (nolock)
 where pa_producto = 'GAR'
   and pa_nemonico = 'CODFAG'
set transaction isolation level read uncommitted

/*PARAMETRO DE LA GARANTIA DE FNG*/
select @w_parametro_fng = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'
set transaction isolation level read uncommitted

-- INI JAR REQ 197
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
and    pa_nemonico = 'CMFAGP'  -- JAR REQ 197
set transaction isolation level read uncommitted
-- FIN JAR REQ 197

---CODIGO DEL RUBRO COMISION FAG UNICO
select @w_par_fag_uni = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMUNI' 
set transaction isolation level read uncommitted

---CODIGO DEL RUBRO COMISION GAR UNIFICADA REQ379
select @w_parametro_fgu = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COMGRP'
set transaction isolation level read uncommitted

/*PARAMETRO COMISION MIPYMES */
select @w_pmipymes = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'MIPYME'
set transaction isolation level read uncommitted

-- CODIGO DEL CONCEPTO CAPITAL
select @w_concepto_cap = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'CAP'

if @@rowcount = 0
   return 710076
   
-- CODIGO DEL CONCEPTO INTERES
select @w_concepto_int = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'

if @@rowcount = 0
   return 710076
   
--GFP UMBRAL DE TIEMPO PARA CATEGORIA DE PLAZO
select @w_param_tiempo_plazo = pa_int
from  cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'UTPCP'
set transaction isolation level read uncommitted

-- CARGAR VALORES INICIALES
select
@w_cuotas_activa  = 0,
@w_cuota_desde    = 0,                                -- REQ 175: PEQUEÑA EMPRESA
@w_desplazamiento = 'N',                               -- REQ 175: PEQUEÑA EMPRESA
@w_monto_rub_fin  = 0

select 
@w_banco               = opt_banco,                            -- 09/FEB/2011 - REQ 175 - PEQUEÑA EMPRESA
@w_fecha_ini           = opt_fecha_ini,
@w_tplazo              = opt_tplazo,
@w_plazo               = opt_plazo,
@w_tdividendo          = opt_tdividendo,
@w_periodo_cap         = opt_periodo_cap,
@w_periodo_int         = opt_periodo_int,
@w_dist_gracia         = opt_dist_gracia,
@w_gracia_cap          = opt_gracia_cap,
@w_gracia_int          = opt_gracia_int,
@w_mes_gracia          = opt_mes_gracia,
@w_tipo_tabla          = opt_tipo_amortizacion,
@w_dia_fijo            = opt_dia_fijo,
@w_cuota               = opt_cuota,
@w_dias_anio           = opt_dias_anio,
@w_evitar_feriados     = opt_evitar_feriados,
@w_moneda              = opt_moneda,
@w_oficina             = opt_oficina,
@w_periodo_crecimiento = opt_periodo_crecimiento,
@w_tasa_crecimiento    = opt_tasa_crecimiento,
@w_tipo                = opt_tipo,
@w_opcion_cap          = opt_opcion_cap,
@w_tasa_cap            = opt_tasa_cap,
@w_dividendo_cap       = opt_dividendo_cap,
@w_tipo_crecimiento    = opt_tipo_crecimiento, 
@w_base_calculo        = opt_base_calculo,     
@w_fecha_pri_cuot      = opt_fecha_pri_cuot,   
@w_ult_dia_habil       = opt_dia_habil,        
@w_recalcular          = opt_recalcular_plazo, 
@w_tipo_redondeo       = opt_tipo_redondeo,    
@w_convierte_tasa      = isnull(opt_convierte_tasa,'S'),
@w_toperacion          = opt_toperacion,
@w_tramite             = opt_tramite,
@w_tipo_linea          = opt_tipo_linea,
@w_estado_op           = opt_estado,
@w_reestructuracion    = opt_reestructuracion,
@w_ref_grupal          = opt_ref_grupal,
@w_grupo               = opt_grupo,
@w_monto               = opt_monto,
@w_monto_aprobado      = opt_monto_aprobado
from   ca_operacion_tmp with (nolock)
where  opt_operacion = @i_operacionca

/*-- KDR 23/08/2022 Mes de no pago no aplica en la versión de Finca Impact. (Se comenta ya que la validación la realiza el FrontEnd)
if isnull(@w_mes_gracia, 0) > 0
begin
   select @w_error = 725186 -- Error, no se puede calcular tablas de amortización con mes de no pago.
   return @w_error
end*/

--LPO TEC Si es grupal se coloca la primera fecha de vencimiento de la primera cuota que viene de la interface
IF @i_grupal = 'S'
   SELECT @w_fecha_pri_cuot = @i_fecha_ven_pc

select @w_tr_tipo = isnull(tr_tipo,'X'),
       @w_tipo_norm = tr_grupo
from cob_credito..cr_tramite
where tr_tramite = @w_tramite
if @@rowcount  = 0
   select @w_tr_tipo = 'X'
       
IF (@i_cambio_plazo = 'S' AND @w_cuota > 0 )  --JCM no se actualiza correctamente bien el plazo
begin
   select @w_cuota = 0
end
    
---ORS 866 LOS RUBROS QUE NO ESAN PARAMETRIZADOS NO DEBEN IR EN LA TABLA
delete ca_rubro_op_tmp
where rot_operacion = @i_operacionca
and rot_concepto in  ( select c.codigo
                       from cobis..cl_catalogo c
                       where tabla in (select t.codigo 
                       from cobis..cl_tabla t 
                       where t.tabla = 'ca_rubros_pendientes')
                     )
if @@error <> 0
begin
   return 710003
end 

if @i_tabla_nueva <> 'D'
begin

   -- ELIMINACION DE LA TABLA DE AMORTIZACION TEMPORAL
   if @w_estado_op in (@w_est_credito,@w_est_novigente) --and @i_regenera_rubro = 'S')  
   begin

       if @i_actualiza_rubros = 'N'  --Para rubros financiados
       begin

          select @w_valor_financiado = sum(rot_valor) 
            from ca_rubro_op_tmp 
           where rot_operacion = @i_operacionca 
             and isnull(rot_financiado,'N') = 'S' 
             and rot_valor > 0
          
          if isnull(@w_valor_financiado,0) > 0
          begin
            
             -- LA BASE DE CALCULO DE UN RUBRO FINANCIADO SIEMPRE SERA EL VALOR ANTES DE FINANCIADOS
             select @w_rot_base_calculo = min(rot_base_calculo)
             from ca_rubro_op_tmp 
             where rot_operacion = @i_operacionca 
               and rot_financiado = 'S'
               and rot_concepto_asociado is null
             
             if @w_monto = @w_monto_aprobado
             begin
                update ca_operacion_tmp
                   set opt_monto = @w_rot_base_calculo + @w_valor_financiado,
                       opt_monto_aprobado = @w_rot_base_calculo + @w_valor_financiado
                 where opt_operacion = @i_operacionca
             
                if @@error <> 0
                   return 710002
				else
				   begin
						select @w_monto_rub_fin  = opt_monto
						from   ca_operacion_tmp  with (nolock)
						where  opt_operacion = @i_operacionca   
				   end
   
                update ca_rubro_op_tmp
                   set rot_valor = @w_rot_base_calculo + @w_valor_financiado
                where rot_operacion = @i_operacionca
                  and rot_concepto  = 'CAP'
                  
     if @@error <> 0
                   return 705003
             end    
             else
             begin
                update ca_operacion_tmp
                  set opt_monto = @w_rot_base_calculo + @w_valor_financiado
                where opt_operacion = @i_operacionca
             
                if @@error <> 0
                   return 710002

                update ca_rubro_op_tmp
                   set rot_valor = @w_rot_base_calculo + @w_valor_financiado
                where rot_operacion = @i_operacionca
                  and rot_concepto  = 'CAP'
                  
                if @@error <> 0
                   return 705003
             end
          end
       
       end

       --SE QUITO EL LLAMADO AL gen_rubtmp POR QUE SE PERDIAN LOS CAMBIOS NEGOCIADOS EN LA PANTALLA 
       --DE RUBROS POR OPERACION EN CREACION Y ACTUALIZACION DE OPERACIONES NO DESEMBOLSADAS   
       
       /********************* RQ537 MODIFICACION TASA PONDERADA PARA NORMALIZACION ***************/
       if @w_tr_tipo = 'M' and @w_tipo_norm in (2,3) and @w_estado_op = 99
       begin
          exec @w_error       = cob_cartera..sp_tasa_normalizacion_tr
               @s_user        = @s_user,
               @s_ofi         = @s_ofi,   
               @s_term        = @s_term,
               @s_date        = @s_date,
               @i_tramite     = @w_tramite,
               @i_tipo_norm   = @w_tipo_norm

          if @w_error <> 0 return @w_error
       end
       /******************************************************************************************/
   end

   delete ca_dividendo_tmp
   where  dit_operacion = @i_operacionca

   if @@error <> 0
      return 710003

   delete ca_amortizacion_tmp
   where  amt_operacion = @i_operacionca

   if @@error <> 0
      return 710003
end

select @w_alterna = 'N'
if exists (select 1   from cobis..cl_catalogo
      where tabla = (select codigo from cobis..cl_tabla
                     where tabla = 'ca_especiales')
      and  valor  = @w_toperacion)
begin
   select @w_alterna = 'S'
end

------REAM CAMBIO
select @w_div_mensuales = 'S'

-- KDR Versión no Aplica el uso de catalogos de dividendos quincenales/semanales
/*if exists (select 1 from cobis..cl_catalogo
           where tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_toper_sem')
           and   codigo = @w_toperacion)
    select @w_div_mensuales = 'N'
	
if exists (select 1 from cobis..cl_catalogo
           where tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_toper_quin')
           and   codigo = @w_toperacion)
    select @w_div_mensuales = 'N'	*/
------REAM CAMBIO

-- KDR Identificar si tipo de dividendo es mensual o divisible a mensual
if (select td_factor % 30 
    from ca_tdividendo
    where td_tdividendo = @w_tdividendo) = 0
   select @w_div_mensuales = 'S'
else
   select @w_div_mensuales = 'N'
   
-- CONTROL PERIODICIDADES UNICAS - 212
if @w_alterna = 'N' and @w_tipo_tabla != 'FLEXIBLE'
begin
    if @w_div_mensuales = 'S'   ------REAM CAMBIO
    BEGIN

    select @w_plazo_e = 12 -- Se valida contra anualidades       
    while 1 = 1 begin

       select @w_plazo_o = td_factor / 30
       from   ca_tdividendo
       where  td_tdividendo = @w_tdividendo

       if isnull(@w_plazo_o,0) < 1   begin
                 select @o_msg_msv = 'Periodicidad permitida multiplos de Mes'
          return 722209
       end

       if @w_plazo_o <= @w_plazo_e begin
          select @w_periodico_e = @w_plazo_e/(@w_plazo_o),
                 @w_periodico   = @w_plazo_e/(@w_plazo_o)
          select @w_diferencia = @w_periodico_e - @w_periodico

          if @w_diferencia > 0 and @w_plazo > 1 begin
             select @o_msg_msv = 'Periodicidad Seleccionada solo permite un Dividendo como plazo (Pago Unico)'
             return 722207
          end
          break
       end
       else
          select @w_plazo_e + 12
    end

    END
end
-- NO PUEDE EXISTIR UN RUBRO INTERES VENCIDO Y UN INTERES ANTICIPADO
-- DIEGO CAMBIO PARA QUE NO CONTROLE CUANDO SE LA CREA POR PRIMERA VEZ
if @i_control_tasa = 'C'
begin
   if exists(select 1
             from   ca_rubro_op_tmp
             where  rot_operacion  = @i_operacionca
             and    rot_fpago      = 'P'
             and    rot_tipo_rubro = 'I')
   begin
      if exists(select 1
                from   ca_rubro_op_tmp
                where  rot_operacion  = @i_operacionca
                and    rot_fpago      = 'A'
                and    rot_tipo_rubro = 'I')
         return 710127
   end
end

-- BORRA LOS DIVIDENDOS ORIGINALES CUANDO CALCULA LA TABLA AUTOMATICAMENTE
if @w_tipo_tabla = 'FRANCESA' or @w_tipo_tabla = 'ALEMANA' or @w_tipo_tabla = @w_tflexible -- FQ: NR-392
   delete ca_dividendo_original_tmp
   where dot_operacion = @i_operacionca

if @w_tipo_tabla = 'MANUAL' and @w_tipo <> 'D'  and @w_tipo <> 'F' 
   select @w_tipo_tabla = 'ALEMANA'

-- INI - REQ 175: PEQUEÑA EMPRESA - NO APLICA
-- EN REAJUSTES QUE MODIFICA LA TABLA NO SE CONSIDERA LOS PERIODOS DE GRACIA
-- if @i_reajuste = 'S'                
--    select @w_gracia_cap = 0,
--           @w_gracia_int = 0
if @i_accion = 'S'                              -- SI VENGO DE CAPITALIZACION
   select 
   @w_desplazamiento = 'S',
   @w_cuota_desde    = @i_cuota_accion

if @i_reajuste = 'S'
   select 
   @w_desplazamiento = 'S',
   @w_cuota_desde    = @i_cuota_reajuste
   
if @i_desde_abnextra = 'S'
   select 
   @w_desplazamiento = 'S',
   @w_cuota_desde    = @i_cuota_abnextra
   
if isnull(@i_divini_reg, 0) > 0                            -- SI VENGO DE MODIFICACION DE OPERACION
   select 
   @w_desplazamiento = 'S',
   @w_cuota_desde    = @i_divini_reg

if @w_cuota_desde > 0 and @i_reestructuracion = 'N'
begin
   if @w_gracia_int > 0
   begin
      if @w_gracia_int - @w_cuota_desde + 1 > 0
         select @w_gracia_int = @w_gracia_int - @w_cuota_desde + 1
      else
         select @w_gracia_int = 0
   end

   if @w_gracia_cap > 0
   begin
      if @w_gracia_cap - @w_cuota_desde + 1 > 0
         select @w_gracia_cap = @w_gracia_cap - @w_cuota_desde + 1
      else
         select @w_gracia_cap = 0
   end
end

-- FIN - REQ 175: PEQUEÑA EMPRESA - NO APLICA   

-- SI EXISTE CAPITALIZACION Y SE HA DEFINIDO UNA CUOTA INICIAL
-- ENTONCES DETERMINAR EL NUMERO DE DIVIDENDOS DE GRACIA DE CAPITAL

if @w_opcion_cap = 'C'
   select @w_dividendo_cap = 0

-- SI EXISTE CAPITALIZACION Y SI ESTA SE APLICA EN UN DIVIDENDO ESPECIFICO
-- GENERAR LA TABLA CON ESTE NUMERO DE DIVIDENDOS DE GRACIA DE CAPITAL

if @w_opcion_cap = 'D' and @w_gracia_cap < @w_dividendo_cap  
   select @w_gracia_cap = @w_dividendo_cap 

exec @w_error     = sp_decimales
     @i_moneda    = @w_moneda,
     @o_decimales = @w_num_dec out

if @w_error <> 0
   return @w_error

-- KDR Se comenta sección por reasignacion de monto.
if @w_estado_op = @w_est_credito
begin
   if @w_monto_rub_fin <> 0  --Se añade validacion para actualizacion de rubros finaciados JCM 25/11/2021
     begin
	   update cob_cartera..ca_rubro_op_tmp 
	   set    rot_valor = @w_monto_rub_fin
	   where  rot_operacion = @i_operacionca
	   and    rot_fpago     = 'P'
	   and    rot_tipo_rubro= 'C'
	 end
	else
	 begin
	   update cob_cartera..ca_rubro_op_tmp 
	   set    rot_valor = @w_monto
	   where  rot_operacion = @i_operacionca
	   and    rot_fpago     = 'P'
	   and    rot_tipo_rubro= 'C'
	 end
end

select @w_monto_cap = isnull(sum(rot_valor),0)
from   ca_rubro_op_tmp
where  rot_operacion = @i_operacionca
and    rot_fpago     = 'P'
and    rot_tipo_rubro= 'C'

if @w_monto_cap = 0
   select @w_monto_cap = sum(ro_valor) 
   from   ca_rubro_op
   where  ro_operacion = @i_operacionca
   and    ro_fpago     = 'P'
   and    ro_tipo_rubro= 'C'

--ACTUALIZACION DE RUBROS A LA TASA EQUIVALENTE POR POSIBLES MODIFICACION DE
--LA PERIODICIDAD EN EL FRONT - END DE TABLA DE AMORTIZACION

if @i_actualiza_rubros = 'S'
BEGIN
   --LPO TEC Si es grupal se asigna la @i_tasa = @i_tasa_grupal
   IF @i_grupal = 'S'
      SELECT @i_tasa = @i_tasa_grupal
            
 exec @w_error       = sp_actualiza_rubros
        @i_operacionca = @i_operacionca,
        @i_crear_op    = @i_crear_op,
        @i_tasa        = @i_tasa -- JSA Santander
   
   if @w_error <> 0
   begin
      return @w_error
   end
end
 
-- VERIFICAR QUE LA TASA TOTAL NO HAYA SUPERADO EL 1.5 DEL IBC
if @i_control_tasa = 'S'
begin
   exec @w_error       = sp_control_tasa
        @i_operacionca = @i_operacionca,
        @i_temporales  = 'S',
        @i_ibc         = 'S'

   if @w_error <> 0
      return @w_error
end

--CALCULO DE LA TASA TOTAL DEL PRESTAMO

select @w_tasa_int = 0

select @w_tasa_int = sum(rot_porcentaje) --TASA DE INTERES TOTAL
from   ca_rubro_op_tmp
where  rot_operacion  = @i_operacionca
and    rot_fpago      in ('P', 'A')
and    rot_tipo_rubro in ('I','F')

-- CALCULO DEL PLAZO DEL PRESTAMO
-- ******************************   
if   @w_cuota <> 0 and (@w_tipo_tabla = 'ALEMANA' or @w_tipo_tabla = 'FRANCESA')  
begin
   -- REDEFINIR PERIODO DE CALCULO Y TIPO DE PLAZO
   select @w_dias_plazo = td_factor
   from   ca_tdividendo
   where  td_tdividendo = @w_tplazo
   
   if @@rowcount = 0
      return 710007

      select @w_dias_dividendo = td_factor
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo

   if @@rowcount = 0
      return 710007

   select @w_tplazo = @w_tdividendo,
          @w_periodo_cal = /*@w_periodo_cal * */ (@w_dias_plazo / @w_dias_dividendo)   
       
   if @w_periodo_cal is not null begin  --jos
      -- CALCULAR EL PLAZO  
      exec @w_error       = sp_calcular_plazo
           @i_operacionca = @i_operacionca,
           @i_tipo_tabla  = @w_tipo_tabla,
           @i_monto_cap   = @w_monto_cap,
           @i_tasa_int    = @w_tasa_int,
           @i_tdividendo  = @w_tdividendo,
           @i_periodo_cap = @w_periodo_cap,
           @i_periodo_int = @w_periodo_int,
           @i_gracia_cap  = @w_gracia_cap,
           --@i_gracia_int= @w_gracia_int,
           @i_dias_anio   = @w_dias_anio,
           @i_cuota       = @w_cuota,
           @i_capitaliza  = @w_opcion_cap,
           @o_plazo       = @w_plazo out

      if @w_error <> 0
         return @w_error
   end  --jos

   -- CALCULAR NUMERO DE DIVIDENDOS
   select @w_dias_op = 0,
          @w_dias_di = 0

   select @w_dias_op = @w_plazo * td_factor
   from   ca_tdividendo
   where  td_tdividendo = @w_tplazo
   
   select @w_dias_di = @w_periodo_int * td_factor
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo
   
   if @w_dias_op % @w_dias_di <> 0
   begin
      select @w_plazo = round(@w_dias_op / @w_dias_di,0) * @w_dias_di
   end
   select @o_plazo   = @w_plazo,
   @o_tplazo  = @w_tdividendo
end
ELSE
begin   
   select
   @o_plazo   = @w_plazo,
   @o_tplazo  = @w_tplazo

   --LPO TEC INI Manejo dia fijo-varios tplazo(SVA)
   --SI LA OPERACION ORIGINAL SOLO TIENE UN DIVIDENDO, TERMINA
   if @w_plazo = 0
   begin
      select @w_dias_op = isnull(count(*), 0)
        from ca_dividendo
       where di_operacion = @i_operacionca
      if @w_dias_op = 1 return 0
   end


   -- CALCULAR NUMERO DE DIVIDENDOS 
   select @w_dias_op = @w_plazo * td_factor
   from   ca_tdividendo
   where  td_tdividendo = @w_tplazo
   
   if isnull(@w_dias_op,0) <= 0  return 710007

   select @w_dias_di = @w_periodo_int * td_factor
     from   ca_tdividendo
    where  td_tdividendo = @w_tdividendo
   if isnull(@w_dias_di,0) <= 0  return 710007
   
   --GFP se suprime print
   /*
   if @w_dias_op % @w_dias_di <> 0  
   begin
     print 'La periodicidad de pago del interes debe ser multipo del plazo. Revisar la Tabla de Amortizacion generada'     
   end
   */
   select @w_num_dividendos = round(convert(float,@w_dias_op) / convert(float,@w_dias_di),0) --CVA Ago-06-07
   
end
--LPO TEC FIN Manejo dia fijo-varios tplazo(SVA)

if @w_tipo_tabla = @w_tflexible -- FQ: NR-392
begin

   if @w_estado_op = @w_est_credito and @i_simulacion_tflex = 'N'
   begin
      select @o_fecha_fin       = opt_fecha_fin,
             @o_plazo           = opt_plazo,
             @o_tplazo          = opt_tplazo,
             @o_cuota           = opt_cuota
      from   ca_operacion_tmp  with (nolock)
      where  opt_operacion = @i_operacionca
   end
   else
   begin
      declare
         @w_fecha_fin      datetime
      exec @w_error       = sp_gentabla_flexible
           @i_debug       = 'N',
           @i_operacionca = @i_operacionca,
           @i_num_dec     = @w_num_dec,
           @o_fecha_fin   = @o_fecha_fin    OUTPUT,
           @o_plazo       = @o_plazo        OUTPUT,
           @o_tplazo      = @o_tplazo       OUTPUT,
           @o_cuota       = @o_cuota        OUTPUT,
           @o_msg_msv     = @o_msg_msv      OUTPUT

      if @w_error != 0
         return @w_error
   end
   return 0
end


if @w_tipo <> 'D'  and @w_tipo <> 'F'
begin
   --GENERAR LOS DIVIDENDOS EN TABLAS TEMPORALES
   if @i_desde_abnextra = 'N'
   begin       
      exec @w_error              = sp_genditmp
           @i_tabla_nueva        = @i_tabla_nueva,
           @i_oficina            = @w_oficina,
           @i_operacionca        = @i_operacionca,
           @i_plazo              = @w_plazo,
           @i_tplazo             = @w_tplazo,
           @i_tdividendo         = @w_tdividendo,
           @i_periodo_cap        = @w_periodo_cap,
           @i_periodo_int        = @w_periodo_int,
           @i_mes_gracia         = @w_mes_gracia,
           @i_fecha_pri_cuot     = @w_fecha_pri_cuot,
           @i_fecha_ini          = @w_fecha_ini,
           @i_dia_fijo           = @w_dia_fijo,
           @i_evitar_feriados    = @w_evitar_feriados,
           @i_dias_gracia        = @i_dias_gracia,
           @i_cuota              = @w_cuota,
           @i_ult_dia_habil      = @w_ult_dia_habil,
           @i_base_calculo       = @w_base_calculo, 
           @i_recalcular         = @w_recalcular,
           @i_gracia_cap         = @w_gracia_cap,
           @i_gracia_int         = @w_gracia_int,
           @i_reajusta_cuota_uno = @i_reajusta_cuota_uno, 
           @i_reajuste           = @i_reajuste,
           @i_cuota_desde_cap    = @i_cuota_desde_cap,
           @i_cambio_fecha       = @i_cambio_fecha

      if (@w_error <> 0)
      begin      
         return @w_error
      end
      
      if @i_reajuste = 'S' and @i_reajusta_cuota_uno = 'S' 
      begin
         ---113744
         ---CUANDO HAY REAJUSTE DE LA CUOTA NRO.1 EL SISTEMA NO
         ---RESPETA LOS DIAS PEQUEÑOS O MAS GRANDES DE LA PRIMERA CUOTA
         ---EL SIEMPRE PONE EL 30,60,90,180
         ---POR ESTO SE DEBE RESCATAR PARA EL REAJUSTE DE LACUOTA UNO EL VALOR DE LOS DIAS
         select @w_dias_cuota1 = di_dias_cuota
         from ca_dividendo
         where di_operacion = @i_operacionca
         and  di_dividendo = 1
         
         update ca_dividendo_tmp
         set dit_dias_cuota = @w_dias_cuota1
         where dit_operacion = @i_operacionca
         and  dit_dividendo = 1
        ---113744
      end

   end
   ELSE -- DESDE ABNEXTRA
   begin
      --CUANDO VIENE DESDE ABONO EXTRAORDINARIO SE COPIA LA DEFINICI-N DE LAS CUOTAS QUE FALTAN
      delete ca_cuota_adicional_tmp
      where  cat_operacion = @i_operacionca

      if @@error <> 0
         return 710003

      insert into ca_dividendo_tmp
      select *
      from   ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_dividendo >= @i_cuota_abnextra

      if @@error <> 0
         return 710001

      update ca_dividendo_tmp with (rowlock)
      set    dit_dividendo = dit_dividendo - @i_cuota_abnextra + 1
      where  dit_operacion = @i_operacionca

      if @@error <> 0
         return 710002

      insert into ca_cuota_adicional_tmp
      select di_operacion, di_dividendo, 0
      from   ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_dividendo >= @i_cuota_abnextra

      if @@error <> 0
         return 710001

      update ca_cuota_adicional_tmp
      set    cat_cuota = ca_cuota
      from   ca_cuota_adicional
      where  ca_operacion = @i_operacionca
      and    ca_dividendo >= @i_cuota_abnextra
      and    cat_operacion = @i_operacionca
      and    cat_dividendo = ca_dividendo

      if @@error <> 0
         return 710002

      update ca_cuota_adicional_tmp
      set    cat_dividendo = cat_dividendo - @i_cuota_abnextra + 1
      where  cat_operacion = @i_operacionca

      if @@error <> 0
         return 710002
   end

   -- INI - REQ 175: PEQUEÑA EMPRESA 
   update ca_dividendo_tmp with (rowlock)
   set dit_de_capital = 'N'
   where dit_operacion  = @i_operacionca
   and   dit_dividendo <= @w_gracia_cap

   if @@error <> 0
      return 710002

   update ca_dividendo_tmp with (rowlock)
   set dit_de_interes = 'N'
   where dit_operacion  = @i_operacionca
   and   dit_dividendo <= @w_gracia_int

   if @@error <> 0
      return 710002

   if exists(
   select 1 from ca_dividendo_tmp, ca_cuota_adicional_tmp 
   where dit_operacion  = @i_operacionca
   and   dit_de_capital = 'N'
   and   cat_operacion  = dit_operacion
   and   cat_dividendo  = dit_dividendo
   and   cat_cuota      > 0                               )
      return 721323

   if @i_accion = 'N' and @i_reajuste = 'N' and @i_desde_abnextra = 'N' and @i_gracia_pend = 'N'
   begin
      -- GRACIA DEFAULT ES 0
      update ca_rubro_op_tmp
      set rot_gracia = 0
      where rot_operacion   = @i_operacionca
      and   rot_tipo_rubro <> 'C'

      if @@error <> 0
         return 710002
   end

   if @i_accion = 'S' or @i_reajuste = 'S' or @i_desde_abnextra = 'S' or @i_gracia_pend = 'S'
   begin
      if @i_accion = 'S'
      begin
         update ca_dividendo_tmp
         set dit_dias_cuota = di_dias_cuota
         from ca_dividendo
         where dit_operacion = @i_operacionca
         and   dit_dividendo = 1
         and   di_operacion  = dit_operacion
         and   di_dividendo  = @w_cuota_desde

         if @@error <> 0
            return 710002
      end

      -- DETERMINACION DE GRACIA BASE
      select 
      concepto = am_concepto,
      gracia   = case when sum(am_gracia) < 0 then -sum(am_gracia) else 0 end
      into #gracia
      from ca_rubro_op, ca_amortizacion
      where ro_operacion   = @i_operacionca
      and   ro_tipo_rubro <> 'C'
      and   am_operacion   = ro_operacion
      and   am_dividendo   < @w_cuota_desde
      and   am_concepto    = ro_concepto      
      group by am_concepto

      update ca_rubro_op_tmp
      set rot_gracia = gracia
      from #gracia
      where rot_operacion   = @i_operacionca
      and   rot_tipo_rubro <> 'C'
      and   rot_concepto    = concepto

      if @@error <> 0
         return 710002
   end
   -- FIN - REQ 175: PEQUEÑA EMPRESA

   --AJUSTAR EL PLAN DE CUOTAS DE LA PASIVA
   if @i_operacion_activa is not null
   begin
      select @w_cuotas_activa = max(di_dividendo)
      from   ca_dividendo
      where  di_operacion = @i_operacion_activa

      delete ca_dividendo_tmp
      where  dit_operacion = @i_operacionca
      and    dit_dividendo > @w_cuotas_activa

      if @@error <> 0
         return 710003
   end
end 
ELSE
begin
   if @i_batch_dd  <> 'S' 
   begin
      exec @w_error       =  cob_cartera..sp_divfact
           @i_operacionca = @i_operacionca, 
           @i_tramite     = @w_tramite

      if @w_error <> 0
      begin
         return @w_error
      end
   end

   if (@i_batch_dd  = 'S' and @w_tipo = 'F' )
   begin
      exec @w_error       =  cob_cartera..sp_divfact_batch
           @i_operacionca = @i_operacionca, 
           @i_tramite     = @i_tramite_hijo
      if @w_error <> 0
      begin
         return @w_error
      end
   end
end

if (@w_tipo_tabla = 'MANUAL' and @w_tipo = 'D' )  or   (@w_tipo_tabla = 'MANUAL' and @w_tipo = 'F' )
begin
   if @i_batch_dd  <> 'S'
   begin
      exec @w_error = cob_cartera..sp_tablafac
      @i_operacionca   = @i_operacionca
      
      if (@w_error <> 0)
      begin
         return @w_error
      end         
   end

   if (@i_batch_dd  = 'S' and @w_tipo = 'F' )
   begin
      exec @w_error = cob_cartera..sp_tablafac_batch
      @i_operacionca      = @i_operacionca
      
      if (@w_error <> 0)
         return @w_error
   end
end

-- FQ: CONVERTIR LA FORMA EN QUE SE INTERPRETA @w_gracia_cap

select @w_primera_cuota_cap = 0

if @w_tipo <> 'D'  and  @w_tipo <> 'F' and @w_gracia_cap > 0
begin
   -- NUMERO DE CUOTAS DE INTERES POR CADA DE CAPITAL
   select @w_per_cap_cuotas = @w_periodo_cap / @w_periodo_int
   -- PRIMERA CUOTA DONDE SE COBRA CAPITAL POR EFECTO DE LA GRACIA
   select @w_primera_cuota_cap = (@w_gracia_cap + 1) * @w_per_cap_cuotas - 1 - isnull(@i_cuota_abnextra, 0)
   if @w_primera_cuota_cap < 0 select @w_primera_cuota_cap = 0

end

if  @w_estado_op in (1,9) and @i_reestructuracion = 'S'
begin
    ---sila tasa es 0 asi debe continuar
    ---porque es una Reestructuracion
    select @w_porcentaje_mipymes = 0

    select @w_porcentaje_mipymes = isnull(ro_porcentaje,0)
    from   ca_rubro_op
    where  ro_operacion = @i_operacionca
    and    ro_concepto  = @w_pmipymes

    if @w_porcentaje_mipymes = 0
    begin
       update ca_rubro_op_tmp
       set rot_porcentaje = 0,
       rot_porcentaje_efa = 0,
       rot_porcentaje_aux = 0,
       rot_valor = 0
       where  rot_operacion = @i_operacionca
       and    rot_concepto  = @w_pmipymes

    if @@error <> 0
        return 710568 
    end
end

if @w_tipo_tabla = 'ROTATIVA' begin  

   select 
   @w_cuota     = 0, 
   @w_monto_cap = 0
   
   select @w_dias_interes = td_factor * @w_periodo_int
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo

   if @@rowcount = 0 begin
         select @o_msg_msv = 'gentabla.sp tipo Dividendo'
         return 710007
   end
   
   exec  @w_error       = sp_dist_rotativa
         @i_operacionca = @i_operacionca
   
   if @w_error <> 0 return @w_error
 
end

if @w_tipo_tabla = 'FRANCESA' --CUOTA FIJA
begin
   --VERIFICAR QUE LA CUOTA HAYA SIDO DADA PARA EL CASO DE CRECIMIENTO PERIODICO
   --CON  CAPITALIZACION
   if @w_cuota = 0
   begin   
   
      exec @w_error               = sp_cuota_francesa
           @i_operacionca         = @i_operacionca,
           @i_monto_cap           = @w_monto_cap,
           @i_gracia_cap          = @w_gracia_cap,                  -- REQ 175: PEQUEÑA EMPRESA
           @i_tasa_int            = @w_tasa_int,
           @i_fecha_ini           = @w_fecha_ini,
           @i_dias_anio           = @w_dias_anio,
           @i_num_dec             = @w_num_dec,
           @i_periodo_crecimiento = @w_periodo_crecimiento,
           @i_tasa_crecimiento    = @w_tasa_crecimiento,
           @i_tipo_crecimiento    = @w_tipo_crecimiento,
           @i_opcion_cap          = @w_opcion_cap,
           @i_causacion           = @i_causacion, --RBU
           @o_cuota               = @w_cuota out

      if (@w_error <> 0)
         return @w_error
   end

   select @w_dias_interes = td_factor * @w_periodo_int
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo

   if @@rowcount = 0 begin
      select @o_msg_msv = 'gentabla.sp tipo Dividendo'
      return 710007
   end

   exec @w_error               = sp_dist_francesa
        @i_operacionca         =  @i_operacionca,
        @i_cuota               =  @w_cuota,
        @i_gracia_cap          =  @w_gracia_cap,
        @i_dist_gracia         =  @w_dist_gracia,
        @i_gracia_int          =  @w_gracia_int,
        @i_dias_anio           =  @w_dias_anio,
        @i_periodo_crecimiento =  @w_periodo_crecimiento,
        @i_tasa_crecimiento    =  @w_tasa_crecimiento,
        @i_num_dec             =  @w_num_dec,
        @i_opcion_cap          =  @w_opcion_cap,
        @i_tipo_crecimiento    =  @w_tipo_crecimiento,
        @i_causacion           =  @i_causacion,
        @o_plazo               =  @w_plazo_aux out

   if (@w_error <> 0)
      return @w_error

   if @w_plazo_aux is not null
      select @o_plazo = @w_plazo_aux, 
             @o_tplazo = @w_tdividendo

end

if @w_tipo_tabla = 'ALEMANA' --CAPITAL CONSTANTE
begin
   if @w_cuota = 0
   begin
      if @i_desde_abnextra = 'N'
      begin
         exec @w_error        = sp_cuota_alemana
              @i_operacionca  = @i_operacionca,
              @i_monto_cap    = @w_monto_cap,
              @i_gracia_cap   = @w_gracia_cap,
              @i_num_dec      = @w_num_dec,
              @o_cuota        = @w_cuota out
      end
      ELSE -- SE ESTA EJECUTANDO DESDE ABONO EXTRAORDINARIO
      begin

         select @w_primera_cuota_cap = 0
         exec @w_error        = sp_cuota_alemana
              @i_operacionca  = @i_operacionca,
              @i_monto_cap    = @w_monto_cap,
              @i_gracia_cap   = 0,
              @i_num_dec      = @w_num_dec,
              @o_cuota        = @w_cuota out
      end

      if (@w_error <> 0)
      begin         
         return @w_error
      end
   end

   select @w_dias_interes = td_factor * @w_periodo_int
   from   ca_tdividendo
   where  td_tdividendo = @w_tdividendo

   if @@rowcount = 0
      return 710007 
   exec @w_error          = sp_dist_alemana
        @i_operacionca    =  @i_operacionca,
        @i_cuota_cap      =  @w_cuota,
        @i_gracia_cap     =  @w_primera_cuota_cap, -- AHORA SE LE PASA LA PRIMERA CUOTA DONDE SE COBRA CAPITAL
        @i_dist_gracia    =  @w_dist_gracia,
        @i_gracia_int     =  @w_gracia_int,
        @i_dias_anio      =  @w_dias_anio,
        @i_num_dec        =  @w_num_dec,
        @i_opcion_cap     =  @w_opcion_cap,
        @i_tasa_cap       =  @w_tasa_cap,
        @i_dividendo_cap  =  @w_dividendo_cap,
        @i_base_calculo   =  @w_base_calculo,
        @i_recalcular     =  @w_recalcular,
        @i_dias_interes   =  @w_dias_interes,
        @i_tipo_redondeo  =  @w_tipo_redondeo,
        @i_causacion      =  @i_causacion, --RBU
        @o_plazo          =  @w_plazo_aux out

   if (@w_error <> 0)
   begin
      return @w_error
   end

   if @w_plazo_aux is not null
      select @o_plazo = @w_plazo_aux, 
      @o_tplazo = @w_tdividendo
end


/* CALCULO MIPYMES */
if exists (select 1
           from   ca_rubro_op_tmp
           where  rot_operacion = @i_operacionca
           and    rot_concepto  = @w_pmipymes)
begin   
   exec @w_error          = sp_calculo_mipymes
        @i_operacion      = @i_operacionca,
        @i_desplazamiento = @w_desplazamiento,          -- @i_desde_abnextra = @i_desde_abnextra    -   REQ 175: PEQUEÑA EMPRESA
        @i_cuota_desde    = @w_cuota_desde              -- @i_cuota_abnextra = @i_cuota_abnextra    -   REQ 175: PEQUEÑA EMPRESA

   if @w_error <> 0
      return @w_error
end
else 
begin -- SI NO TIENE MIPYME, QUITAR EL ASOCIADO
   select @w_asociado = rot_concepto
   from   ca_rubro_op_tmp
   where  rot_operacion         = @i_operacionca
   and    rot_concepto_asociado = @w_pmipymes
   
	delete ca_amortizacion_tmp
	where amt_operacion  = @i_operacionca
	and amt_concepto  in(@w_asociado, @w_pmipymes)

   if @@error <> 0
   begin
      return  710002
   end   	
end

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
   into #garantias_operacion_gtabla
   from cob_custodia..cu_custodia, #colateral, cob_credito..cr_gar_propuesta, cob_custodia..cu_tipo_custodia
   Where cu_tipo = tc_tipo
   and   tc_tipo_superior = tipo_sub
   and   gp_tramite  = @w_tramite
   and   gp_garantia = cu_codigo_externo
   and   cu_estado  in ('V','F','P')

   select @w_garantia = w_tipo,
          @w_tipo_garantia   = w_tipo_garantia
   from #garantias_operacion_gtabla

   select @w_rubro = valor 
   from  cobis..cl_tabla t, cobis..cl_catalogo c
   where t.tabla  = 'ca_conceptos_rubros'
   and   c.tabla  = t.codigo
   and   c.codigo = convert(bigint, @w_garantia)  


   if @w_rubro = 'S' begin

      select @w_tabla_rubro = 'ca_conceptos_rubros_' + cast(@w_garantia as varchar)

      insert into #conceptos_gen
      select 
      codigo = c.codigo, 
      tipo_gar = @w_garantia
      from cobis..cl_tabla t, cobis..cl_catalogo c
      where t.tabla  = @w_tabla_rubro
      and   c.tabla  = t.codigo

   end

   /*COMICION DESEMBOLSO*/
   insert into #rubros_gen
   select tipo_gar, ru_concepto, 'DES', 'N'
   from cob_cartera..ca_rubro, #conceptos_gen
   where ru_fpago = 'L'
   and   codigo   = ru_concepto
   and   ru_concepto_asociado is null

   /*COMICION PERIODICO*/
   insert into #rubros_gen
   select tipo_gar, ru_concepto, 'PER', 'N'
   from cob_cartera..ca_rubro, #conceptos_gen
   where ru_fpago = 'P'
   and   codigo   = ru_concepto
   and   ru_concepto_asociado is null

   /*IVA DESEMBOLSO*/
   insert into #rubros_gen
   select tipo_gar, ru_concepto, 'DES', 'S'
   from cob_cartera..ca_rubro, #conceptos_gen
   where ru_fpago = 'L'
   and   codigo   = ru_concepto
   and   ru_concepto_asociado is not null

   /*IVA PERIODICO*/
   insert into #rubros_gen
   select tipo_gar, ru_concepto, 'PER', 'S'
   from cob_cartera..ca_rubro, #conceptos_gen
   where ru_fpago = 'P'
   and   codigo   = ru_concepto
   and   ru_concepto_asociado is not null


   --CAPTURA DE CONCEPTOS
   select @w_concepto_des = rre_concepto
   from #rubros_gen
   where tipo_concepto = 'DES' 
   and iva = 'N'

   select @w_concepto_per = rre_concepto
   from #rubros_gen
   where tipo_concepto = 'PER' 
   and iva = 'N'

   select @w_iva_des = rre_concepto
   from #rubros_gen
   where tipo_concepto = 'DES' 
   and iva = 'S'

   select @w_iva_per = rre_concepto
   from #rubros_gen
   where tipo_concepto = 'PER' 
   and iva = 'S'

/* CALCULO COMFNGANU */
if exists (select 1
           from   ca_rubro_op_tmp
           where  rot_operacion = @i_operacionca
           and    rot_concepto  in (@w_parametro_fng, @w_concepto_per)) and @w_tipo_garantia = @w_cod_gar_fng
begin   
   exec @w_error             = sp_calculo_fng
        @i_operacion         = @i_operacionca,
        @i_desde_abnextra    = @w_desplazamiento,          -- @i_desde_abnextra    -   REQ 175: PEQUEÑA EMPRESA
        @i_cuota_abnextra    = @w_cuota_desde,              -- @i_cuota_abnextra    -   REQ 175: PEQUEÑA EMPRESA
        @i_parametro_fng     = @w_concepto_per,
        @i_parametro_fngd    = @w_concepto_des,
        @i_parametro_fng_iva = @w_iva_per

   if @w_error <> 0
      return @w_error
end
else -- SINO TIENE COMISION ENTONCES QUITAR EL ASOCIADO
begin
	delete ca_amortizacion_tmp
	where amt_operacion = @i_operacionca
	and amt_concepto    in (@w_iva_per, @w_concepto_per)

   if @@error <> 0
   begin
      return  710002
   end
end

/* CALCULO COMFNGANU REQ379*/
if exists (select 1
           from   ca_rubro_op_tmp
           where  rot_operacion = @i_operacionca
           and    rot_concepto  = @w_parametro_fgu)

begin   
   exec @w_error          = sp_calculo_uni
        @i_operacion      = @i_operacionca,
        @i_desde_abnextra = @w_desplazamiento,          -- @i_desde_abnextra    -   REQ 379: UNIFICACION
        @i_cuota_abnextra = @w_cuota_desde              -- @i_cuota_abnextra    -   REQ 379: UNIFICACION

   if @w_error <> 0
      return @w_error
end

-- INI JAR REQ 197
/* CALCULO COMUSASEM */
if exists (select 1
           from   ca_rubro_op_tmp
           where  rot_operacion = @i_operacionca
           and    rot_concepto  in (@w_parametro_usaid,@w_concepto_per))and @w_tipo_garantia = @w_cod_gar_usaid
begin      
   exec @w_error               = sp_calculo_usaid
        @i_operacion           = @i_operacionca,
        @i_desde_abnextra      = @i_desde_abnextra,
        @i_parametro_usaid     = @w_concepto_per,  --REQ402
        @i_parametro_usaidd    = @w_concepto_des,
        @i_parametro_usaid_iva = @w_iva_per

   if @w_error <> 0
      return @w_error
end
else -- SI NO TIENE COMISION ENTONCES QUITAR EL ASOCIADO
begin
	delete ca_amortizacion_tmp
	where amt_operacion  = @i_operacionca
	and amt_concepto in(@w_iva_per,@w_parametro_usaid)

   if @@error <> 0
   begin
      return  710002
   end   	
end

/* CALCULO COMFAGANU */
if exists (select 1
           from   ca_rubro_op_tmp
           where  rot_operacion in (@i_operacionca, @w_concepto_per)) and @w_tipo_garantia = @w_cod_gar_fag
begin
   if @w_reestructuracion = 'S'
   begin
      select @w_div_vigente = di_dividendo from ca_dividendo where di_operacion = @i_operacionca
      select @w_div_vigente = isnull(@w_div_vigente ,0)
   end

   exec @w_error             = sp_calculo_fag
        @i_operacion         = @i_operacionca,
        @i_desde_abnextra    = @i_desde_abnextra,
        @i_cuota_abnextra    = @w_div_vigente,
        @i_parametro_fag     = @w_concepto_per,   --REQ402
        @i_parametro_fagd    = @w_concepto_des,
        @i_parametro_fag_iva = @w_iva_per

   if @w_error <> 0
      return @w_error
end
else
begin
	delete ca_amortizacion_tmp
	where amt_operacion = @i_operacionca
	and   amt_concepto  in (@w_iva_per, @w_concepto_per)

   if @@error <> 0
   begin
      return  710002
   end   	
end
-- FIN JAR REQ 197

---LINEAS DE CONVENIO
if @w_tipo  =  'V' and not exists (select 1 from cob_credito..cr_corresp_sib where tabla  = 'T115' and codigo = @w_toperacion) 
begin  
   -- CALCULO DEL SEGURO DE VIDA
   exec @w_error = sp_calculo_seguro_vida 
   @i_operacion = @i_operacionca,
   @i_tasa_int  = @w_tasa_int

   if @w_error <> 0
      return @w_error
--LINEAS DE CONVENIO
end
ELSE
begin
   ---NR-433     
   if @i_accion = 'N' and @i_desde_abnextra = 'N' and  @i_reajuste = 'N'
   begin
      exec @w_error = sp_rubros_periodos_diferentes
      @i_operacion = @i_operacionca

      if @w_error <> 0
         return @w_error

      /* KDR 18/05/2022 Se comenta ya que no aplica a versión Finca
	  -- CALCULO DE RUBROS CATALOGO - NR 461
      exec @w_error =  sp_rubros_catalogo
      @i_operacion = @i_operacionca

      if @w_error <> 0
         return @w_error
         --CALCULO DE RUBROS CATALOGO - NR 461 -- fin KDR*/
   end
   ELSE
   begin
      -- DEFECTO 407  NR 461
      delete ca_amortizacion_tmp
      where  amt_operacion = @i_operacionca
      and    amt_concepto = (select a.codigo
                             from   cobis..cl_tabla b,
                                    cobis..cl_catalogo a
                             where  b.tabla = 'ca_rubros_catalogos'
                             and    b.codigo = a.tabla )

      delete ca_amortizacion_tmp
      where  amt_operacion = @i_operacionca
      and    amt_concepto  = (select rot_concepto
                              from   ca_rubro_op_tmp, ca_concepto
                              where  rot_operacion = @i_operacionca
                              and    rot_concepto_asociado = (select a.codigo
                                                              from   cobis..cl_tabla b,
                                                                     cobis..cl_catalogo a
                                                              where  b.tabla = 'ca_rubros_catalogos'
                                                              and    b.codigo = a.tabla )
                              and    co_concepto = rot_concepto
                              and    co_categoria = 'A')
   end
   --NR-433

   /* KDR 18/05/2022 Se comenta ya que no aplica a versión Finca
   -- CALCULO DEL SEGURO DE VIDA SOBRE VALOR INSOLUTO
   exec @w_error = sp_calculo_seguros_sinsol
   @i_operacion = @i_operacionca

   if @w_error <> 0
      return @w_error
   -- CALCULO DEL SEGURO DE VIDA SOBRE VALOR INSOLUTO -- FIN KDR*/
end

if @w_tipo <> 'D'  and  @w_tipo <> 'F'
begin

   
   select @o_cuota = isnull(@w_cuota,0)

   -- RETORNO DE LA FECHA DE VENCIMIENTO DE LA OPERACION
   select @o_fecha_fin = max(dit_fecha_ven)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacionca

   -- ACTUALIZACION DEL MONTO Y DE LA FECHA DE VENCIMIENTO DE LA OP
   
   update ca_operacion_tmp
   set    opt_fecha_fin  = @o_fecha_fin,
          opt_monto      = @w_monto_cap,
          opt_cuota      = isnull(@w_cuota,0)
   where  opt_operacion = @i_operacionca

   if @@error <> 0
   begin
      return  710002
   end   
   
   --GFP Actualizacion de la categoria de plazo
   select @w_num_dias_op = datediff(day,opt_fecha_ini,opt_fecha_fin)
   from ca_operacion_tmp  with (nolock)
   where  opt_operacion = @i_operacionca
   
   if (isnull(@w_num_dias_op, 0) <= @w_param_tiempo_plazo)
   begin
      select @w_categoria_plazo = 'C'
   end
   else
   begin
      select @w_categoria_plazo = 'L'
   end
   
   update ca_operacion_datos_adicionales_tmp
   set odt_categoria_plazo = @w_categoria_plazo
   where  odt_operacion = @i_operacionca

   if @@error <> 0
   begin
      return  710002
   end  
   
end 

-- INI - REQ 175 - PEQUEÑA EMPRESA - MANEJO DE GRACIA
if @i_accion = 'N' and @i_desde_abnextra = 'N' and @i_reajuste = 'N' and isnull(@i_divini_reg, 0) = 0 and @w_gracia_int > 0
begin
   delete ca_acciones_tmp
   where act_operacion = @i_operacionca

   if @w_dist_gracia = 'C'
   begin
      select @w_vlr_gracia = isnull(rot_gracia, 0)
      from ca_rubro_op_tmp
      where rot_operacion  = @i_operacionca
      and   rot_concepto   = @w_concepto_int

      select @w_vlr_gracia  = @w_vlr_gracia + isnull(sum(amt_cuota - amt_pagado), 0)
      from ca_amortizacion_tmp
      where amt_operacion     = @i_operacionca
      and   amt_dividendo    <= @w_gracia_int
      and   amt_concepto      = @w_concepto_int

      if @w_vlr_gracia > 0
      begin
         select
         @w_conc_org  = @w_concepto_int,
         @w_conc_dest = @w_concepto_cap,
         @w_divf_ini  = @w_gracia_int + 1,
         @w_divf_fin  = @w_gracia_int + 1

         exec @w_error       = sp_acciones
              @t_trn         = 7212,
              @i_operacion   = 'I',
              @i_banco       = @w_banco,
              @i_rubro       = @w_conc_org,
              @i_div_ini     = 1,
              @i_div_fin     = @w_gracia_int,
              @i_valor       = @w_vlr_gracia,
              @i_porcentaje  = 100,
              @i_rubrof      = @w_conc_dest,
              @i_divf_ini    = @w_divf_ini,
              @i_divf_fin    = @w_divf_fin,
              @i_crea_ext    = @i_crea_ext,
              @o_msg_msv     = @o_msg_msv out

         if @w_error <> 0
            return @w_error
      end
   end
end
-- FIN - REQ 175

-- SI SE TRATA DE UN CREDITO ROTATIVO, ALMACENAR LOS DIVIDENDOS ORIGINALES
if @i_tabla_nueva = 'D' and @w_tipo <> 'D'   and @w_tipo <> 'F'
begin
   -- VERIFICAR SI ES PRESTAMO DE TIPO ROTATIVO
   select @w_rotativo = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'ROT'  
   set transaction isolation level read uncommitted

   if @w_rotativo = @w_tipo
   begin

      select @w_divcap_original = count(1)
      from   ca_dividendo_tmp
      where  dit_operacion = @i_operacionca
      and    dit_de_capital = 'S'

      update ca_operacion_tmp
      set    opt_divcap_original = @w_divcap_original
      from   ca_dividendo_tmp
      where  opt_operacion     = @i_operacionca

      if @@error <> 0
         return 710002
   end
end

if @w_tipo <> 'D'  and @w_tipo <> 'F'
begin
   -- RECONSTRUIR VALORES
   update ca_amortizacion_tmp
   set    amt_acumulado = amt_acumulado + isnull(vat_valor,0),
          amt_cuota     = amt_cuota     + isnull(vat_valor,0)
   from   ca_valores_tmp
   where  vat_operacion = @i_operacionca
   and    vat_operacion = amt_operacion
   and    vat_dividendo = amt_dividendo
   and    vat_rubro = amt_concepto

   if @@error <> 0
   begin
      return 710002
   end

   select @w_ult_dividendo = max(dit_dividendo)
   from   ca_dividendo_tmp
   where  dit_operacion = @w_operacionca

   -- RECONSTRUIR VALORES
   insert into ca_valores_tmp_rub
   select vat_operacion, vat_rubro, isnull(sum(vat_valor), 0)
   from   ca_valores_tmp
   where  vat_operacion = @i_operacionca
   and    vat_dividendo > @w_ult_dividendo
   group  by vat_operacion, vat_rubro

   update ca_amortizacion_tmp
   set    amt_acumulado =  amt_acumulado + vat_valor,
          amt_cuota     =  amt_cuota     + vat_valor
   from   ca_valores_tmp_rub
   where  amt_operacion = @i_operacionca
   and    amt_dividendo = @w_ult_dividendo
   and    amt_concepto  = vat_rubro
   and    vat_operacion = @i_operacionca

   if @@error <> 0
   begin
      delete ca_valores_tmp_rub
      where  vat_operacion = @i_operacionca
      return 710002
   end

   delete ca_valores_tmp_rub
   where  vat_operacion = @i_operacionca
end

--GFP Se elimina las cuotas adicionales cuando existe reduccion de dividendos
delete ca_cuota_adicional_tmp
where  cat_operacion = @i_operacionca
and    cat_dividendo > (select max(dit_dividendo)
                        from ca_dividendo_tmp
                        where dit_operacion = @i_operacionca)

return 0
go
