/*************************************************************************/
/*   NOMBRE LOGICO:      reajcuot.sp                                     */
/*   NOMBRE FISICO:      sp_reajuste_cuota                               */
/*   BASE DE DATOS:      cob_cartera                                     */
/*   PRODUCTO:           Cartera                                         */
/*   DISENADO POR:       Fabian de la Torre                              */
/*   FECHA DE ESCRITURA: 12 de Febrero 1999                              */
/*************************************************************************/
/*                     IMPORTANTE                                        */
/*   Este programa es parte de los paquetes bancarios que son            */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,       */
/*   representantes exclusivos para comercializar los productos y        */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida      */
/*   y regida por las Leyes de la República de España y las              */
/*   correspondientes de la Unión Europea. Su copia, reproducción,       */
/*   alteración en cualquier sentido, ingeniería reversa,                */
/*   almacenamiento o cualquier uso no autorizado por cualquiera         */
/*   de los usuarios o personas que hayan accedido al presente           */
/*   sitio, queda expresamente prohibido; sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de       */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto       */
/*   en el presente texto, causará violaciones relacionadas con la       */
/*   propiedad intelectual y la confidencialidad de la información       */
/*   tratada; y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.                */
/*************************************************************************/
/*                              PROPOSITO                                */
/*      Aplica el reajuste. Cuando es por Cuota Fija                     */
/*************************************************************************/
/*                              CAMBIOS                                  */
/*      FECHA         AUTOR            CAMBIOS                           */
/*      NOV-2010      ElciraPelaez     Acumulado de cuota Vigente        */
/*                                     se debe recuperar                 */
/*      FEB-03-2020   Luis Ponce       Ajustes Migracion Core Digital    */
/*   DIC/23/2020   P. Narvaez Añadir cambio de estado Judicial y Suspenso*/
/*   ABR/06/2023   K. Rodriguez        S785531 Validación condiciones de */
/*                                     ca_dividendo                      */
/*    06/06/2023	 M. Cordova		  Cambio variable @w_calificacion    */
/*									  de char(1) a catalogo				 */
/*************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reajuste_cuota')
   drop proc sp_reajuste_cuota
go

---INC. 118105 MAR.16.2015

create proc sp_reajuste_cuota
   @s_user                 login        = NULL,
   @s_term                 varchar (30) = NULL,
   @s_date                 datetime     = NULL,
   @s_ofi                  smallint     = NULL,
   @i_fecha_proceso        datetime,
   @i_banco                cuenta,
   @i_operacionca          int,
   @i_dias_anio            int,
   @i_en_linea             char(1),
   @i_reajuste_especial    char(1),
   @i_cuota                money,
   @i_num_dec              smallint,
   @i_dividendo            int,
   @i_acciones             char(1) = 'N',
   @i_valores              char(1) = 'N' ,
   @i_secuencial           int,
   @i_concepto_cap         catalogo,
   @i_concepto_int         catalogo,
   @i_disminuye            char(1) = 'S'
as
declare
   @w_error                int,
   @w_est_cancelado        tinyint,
   @w_est_vigente          tinyint,
   @w_di_fecha_ven         datetime,
   @w_div_vigente          smallint,
   @w_base_calculo         char(1),
   @w_ult_vigente          smallint,
   @w_saldo_cap            money,
   @w_di_fecha_ini         datetime,
   @w_dividendo            int,
   @w_concepto             catalogo,
   @w_num_dividendos       int,
   @w_fecha_fin            datetime,
   @w_num_dividendos_tmp   smallint,
   @w_dividendos_van       smallint,
   @w_num_dividendos_fin   smallint,
   @w_plazo_operacion      int,
   @w_periodo_int          smallint,
   @w_periodo_cap          smallint,
   @w_moneda_nac           smallint,
   @w_num_dec_mn           tinyint,
   @w_toperacion           catalogo,
   @w_banco                cuenta,
   @w_oficina              int,
   @w_observacion          descripcion,
   @w_moneda               smallint,
   @w_gerente              int,
   @w_num_dec              smallint,
   @w_gar_admisible        char(1),
   @w_reestructuracion     char(1),
   @w_calificacion         catalogo,
   @w_reajusta_cuota_uno   char(1),
   @w_valor_cap            money,
   @w_di_de_capital        int,
   @w_fecha_proceso        datetime,
   @w_dias_cuota           int,
   @w_ro_porcentaje_efa    float,
   @w_monto_cap            money,
   @w_valor_cuota_vigente  money,
   @w_ti_cuota_dest        smallint,   -- Para Traslado de Intereses IFJ REQ 379 25/Nov/2005
   @w_tasa_cvigente        float,
   @w_porcentaje_efa       float,
   @w_referencial          catalogo,
   @w_valor_referencial    float,
   @w_fecha_referencial    datetime,
   @w_tasa_ref             catalogo,
   @w_signo                char(1),
   @w_factor               float,
   @w_num_dec_tapl         tinyint,
   @w_forma_pago_int       char(1),
   @w_dias_anio            smallint,
   @w_tdividendo           catalogo,
   @w_parametro_fag        catalogo,
   @w_aso_fag              catalogo,
   @w_di_num_dias          int,
   @w_rc                   int,
   @w_er                   int,
   @w_cuotavigente         money,
   @w_max_dividendo        int,   --- IFJ DEF 7248 Sep 30/2006
   @w_monto_cap_antes      money,
   @w_monto_cap_despues    money,
   @w_procesar_vigente     char(1),
   @w_dias_int             int,
   @w_op_periodo_int       int,
   @w_capital_pagado_novig money,
   @w_cuota_actual         money,
   @w_dif                  money,
   @w_min_no_vigente       int,
   @w_ro_porcentaje        float,
   @w_recalcular           char(1),
   @w_delta_cap            money,
   @w_dividendo_hasta      smallint,
   @w_dias_div_vigente     smallint,
   @w_di_fecha_ini_vig     datetime,
   @w_op_fecha_ini         datetime,
   @w_mas_cuotas           char(1),
   @w_mipymes              varchar(10),
   @w_IVAmipymes           varchar(10),
   @w_tot_div_antes        int,
   @w_estado_op            tinyint

-- REQ 175: PEQUEÑA EMPRESA
--declare @wt_secs_conc TABLE(  --LPO Ajustes Migracion Core Digital
CREATE TABLE #wt_secs_conc(      --LPO Ajustes Migracion Core Digital
concepto        catalogo     not null,
min_sec         tinyint      not null,
cantidad        tinyint      not null
)
   
select 
@w_concepto             =  @i_concepto_int,
@w_dif                  = 0,
@w_capital_pagado_novig = 0


--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_cancelado  = @w_est_cancelado out

select @w_mipymes = pa_char 
from cobis..cl_parametro with (nolock)
where pa_producto  = 'CCA'
and   pa_nemonico  = 'MIPYME'

select 
@w_IVAmipymes     = ro_concepto
from   ca_rubro_op
where  ro_operacion         = @i_operacionca
and    ro_concepto_asociado = @w_mipymes

       
---MONTO CAPITAL
select 
@w_monto_cap_antes = sum(am_cuota)
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_concepto = 'CAP'

---DIVIDENDOS ANTES DE REAJSUTE
select  @w_tot_div_antes = max(di_dividendo)
from ca_dividendo
where di_operacion = @i_operacionca


-- DATOS DE LA OPERACION
select 
@w_base_calculo         = op_base_calculo,
@w_moneda               = op_moneda,
@w_toperacion           = op_toperacion,
@w_banco                = op_banco,
@w_oficina              = op_oficina,
@w_gerente              = op_oficial,
@w_gar_admisible        = isnull(op_gar_admisible, ''), 
@w_reestructuracion     = isnull(op_reestructuracion, ''),
@w_calificacion         = isnull(op_calificacion, ''),
@w_fecha_proceso        = op_fecha_ult_proceso,
@w_tdividendo           = op_tdividendo,
@w_dias_anio            = op_dias_anio,
@w_op_periodo_int       = op_periodo_int,
@w_recalcular           = op_recalcular_plazo,
@w_op_fecha_ini         = op_fecha_ini,
@w_estado_op            = op_estado
from   ca_operacion
where  op_operacion = @i_operacionca


select 
@w_dias_int = @w_op_periodo_int * td_factor
from   ca_tdividendo
where  td_tdividendo = @w_tdividendo

--- DIVIDENDO VIGENTE

select @w_div_vigente      = di_dividendo,
       @w_dias_div_vigente = di_dias_cuota,
       @w_di_fecha_ini_vig  =di_fecha_ini
from ca_dividendo
where di_operacion = @i_operacionca
and di_estado  = @w_est_vigente      


-- MANEJO DE DECIMALES
exec @w_error  = sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_moneda_nac out,
@o_dec_nacional = @w_num_dec_mn out

if @w_error <> 0  return @w_error

-- CALCULAR EL PORCENTAJE DE INTERES TOTAL
select 
@w_ro_porcentaje_efa = ro_porcentaje_efa,
@w_ro_porcentaje     = ro_porcentaje, 
@w_referencial       = ro_referencial,
@w_signo             = ro_signo,
@w_factor            = ro_factor,
@w_forma_pago_int    = ro_fpago,
@w_num_dec_tapl      = isnull(ro_num_dec,2)
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_tipo_rubro = 'I'
and    ro_fpago      in ('P','A') -- PERIODICO VENCIDO O ANTICIPADO

if @w_ro_porcentaje_efa < 0
begin
   select @w_ro_porcentaje_efa = 0
end



select @w_dividendo_hasta = @w_div_vigente

---LAS CUOTAS QUE TENGAN ALGO PAGADO
select @w_dividendo_hasta = isnull(max(di_dividendo),0)
      from ca_amortizacion,ca_dividendo
where am_operacion = @i_operacionca
and   di_operacion = @i_operacionca
and   di_dividendo = am_dividendo
and   di_estado in (0,1)
and   (am_acumulado > 0  or am_pagado > 0)
and   am_concepto  <> @i_concepto_cap


if @w_dividendo_hasta > 0
begin
   select @w_procesar_vigente = 'S'
end
else
begin

	select 
	@w_div_vigente = di_dividendo,
	@w_procesar_vigente = case
	                      when di_fecha_ini < @i_fecha_proceso then 'S'
	                      else 'N'
	                      end
	from   ca_dividendo
	where  di_operacion   = @i_operacionca
	and    di_estado      = @w_est_vigente
	
	if @@rowcount = 0 return  701179

   select @w_dividendo_hasta  = @w_div_vigente
end

if @w_procesar_vigente = 'S' begin

   --- MODIFICACION SOLO DE LA PARTE DE INTERES DEL DIVIDENDO VIGENTE
   exec @w_error = sp_reajuste_interes 
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_date            = @s_date,
   @s_ofi             = @s_ofi,
   @i_operacionca     = @i_operacionca,
   @i_fecha_proceso   = @i_fecha_proceso,
   @i_num_dec         = @i_num_dec,
   @i_base_calculo    = @w_base_calculo,
   @i_recalcular      = @w_recalcular,
   @i_banco           = @w_banco,
   @i_periodo_int     = @w_periodo_int,
   @i_secuencial      = @i_secuencial,
   @i_en_linea        = @i_en_linea,
   @i_tdividendo      = @w_tdividendo,
   @i_dividendo_hasta = @w_dividendo_hasta,
   @i_disminuye       = @i_disminuye
   
   if @w_error <> 0 return @w_error
   
end


select @w_ult_vigente = @w_div_vigente
if (@w_procesar_vigente = 'S' and  @w_di_fecha_ini_vig <>  @w_op_fecha_ini)
begin
 select @w_ult_vigente = @w_ult_vigente + 1
end

-- CALCULAR EL MONTO DEL CAPITAL TOTAL
select @w_saldo_cap = isnull(sum(am_cuota+am_gracia - am_pagado),0)
from   ca_amortizacion, ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_tipo_rubro = 'C'
and    ro_fpago      in ('P','A') -- PERIODICO VENCIDO O ANTICIPADO
and    am_operacion  = @i_operacionca
and    am_concepto   = ro_concepto 
and    am_dividendo >= @w_ult_vigente

if @w_saldo_cap <= 0 return 708214


select @w_max_dividendo = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacionca

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

if @w_error <> 0 return @w_error


-- GENERACION DE LA TABLA TEMPORAL
if @i_reajuste_especial = 'N'
begin
	select @w_num_dividendos = count(1)
	from   ca_dividendo
	where  di_operacion  = @i_operacionca
	and    di_dividendo >= @w_ult_vigente
end
ELSE
begin
	select @w_num_dividendos = count(1)
	from   ca_dividendo
	where  di_operacion  = @i_operacionca
	and    di_dividendo  >= @w_ult_vigente
end


-- FECHA INICIO DEL DIVIDENDO VIGENTE
select 
@w_di_fecha_ini = di_fecha_ini,
@w_di_fecha_ven = di_fecha_ven
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_dividendo = @w_ult_vigente 

if @w_dias_anio = 360 and @w_dias_int % 30 = 0 begin
   select @w_di_fecha_ini = dateadd(mm, -1 * @w_dias_int / 30, @w_di_fecha_ven)
end

if (@i_reajuste_especial = 'N' or @w_di_fecha_ini_vig =  @w_op_fecha_ini ) ---Dia del desembolso
   select @i_cuota = 0
else begin

   if exists (select 1 from ca_transaccion
   where tr_tran = 'MIG'
   and   tr_operacion = @i_operacionca )   
   begin       
              
      select @i_cuota = isnull(sum(am_cuota),0)
      from ca_amortizacion 
      where am_operacion = @i_operacionca
      and   am_concepto in ('CAP', 'INT')
      and   am_dividendo = @w_ult_vigente
   end   
   
   --- RUTINA PARA MANTENER LA CUOTA VIGENTE ESTABLE (SOLO PARA BANCAMIA) 
   if (@w_procesar_vigente = 'S') and (@w_div_vigente <> 1) and (@w_dias_div_vigente = @w_dias_int) begin
      
      -- INI - REQ 175: PEQUEÑA EMPRESA   
      select @w_delta_cap = sum(am_cuota)
      from ca_amortizacion, ca_dividendo
      where am_operacion = @i_operacionca
      and   am_concepto in ('CAP','INT')
      and   am_dividendo = @w_div_vigente
      and   di_operacion  = am_operacion
      and   di_dividendo  = am_dividendo
      and   di_de_capital = 'S'
      and   di_de_interes = 'S'
      
      if @w_delta_cap is not null
         select @w_delta_cap = @i_cuota - @w_delta_cap
      else
         select @w_delta_cap = 0      
      -- FIN - REQ 175: PEQUEÑA EMPRESA
     
      update ca_amortizacion set
      am_cuota     = am_cuota     + @w_delta_cap,
      am_acumulado = am_acumulado + @w_delta_cap
      where am_operacion = @i_operacionca
      and   am_concepto = 'CAP'
      and   am_dividendo = @w_div_vigente
      and   am_cuota - am_pagado + @w_delta_cap > 0
      
      if @@rowcount <> 0 begin
         select @w_saldo_cap = @w_saldo_cap - @w_delta_cap
      end
   end
end


-- VALORES DE CAPITAL NO VIGENTE PAGADOS POR ANTICIPADO
select @w_capital_pagado_novig = isnull(sum(am_pagado), 0)
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_concepto  = 'CAP'
and    am_dividendo > @w_div_vigente

if (@w_capital_pagado_novig > 0) begin

   update ca_amortizacion set    
   am_pagado = 0
   where  am_operacion = @i_operacionca
   and    am_dividendo > @w_div_vigente
   and    am_concepto  = @i_concepto_cap
   
   if @@error <> 0  return 724401
   
   update ca_amortizacion set    
   am_acumulado = am_acumulado + @w_capital_pagado_novig,
   am_pagado    = am_pagado    + @w_capital_pagado_novig,
   am_cuota     = am_cuota     + @w_capital_pagado_novig
   where  am_operacion = @i_operacionca
   and    am_dividendo = @w_div_vigente
   and    am_concepto  = @i_concepto_cap
   
   if @@error <> 0 return 724401
   
end


select 
@w_periodo_int     = opt_periodo_int,
@w_periodo_cap     = opt_periodo_cap
from   ca_operacion_tmp
where  opt_operacion =  @i_operacionca

select @w_plazo_operacion = @w_periodo_int * @w_num_dividendos

update ca_operacion_tmp set    
opt_cuota          = @i_cuota,
opt_tplazo         = opt_tdividendo,
opt_plazo          = @w_plazo_operacion,
opt_fecha_ini      = @w_di_fecha_ini,
opt_monto          = @w_saldo_cap,
opt_fecha_pri_cuot = null -- @w_di_fecha_ven
where  opt_operacion = @i_operacionca

if @@error <> 0 return 710002

update ca_rubro_op_tmp set    
rot_valor = @w_saldo_cap
where  rot_operacion = @i_operacionca
and    rot_tipo_rubro = 'C'
and    rot_fpago      = 'P'

if @@error <> 0 return 710002

-- INI - REQ 175: PEQUEÑA EMPRESA - DETERMINACION DE GRACIA BASE
select 
concepto = am_concepto,
gracia   = case when sum(am_gracia) < 0 then -sum(am_gracia) else 0 end
into #gracia
from ca_rubro_op, ca_amortizacion
where ro_operacion   = @i_operacionca
and   ro_tipo_rubro <> 'C'
and   am_operacion   = ro_operacion
and   am_dividendo   < @w_ult_vigente
and   am_concepto    = ro_concepto      
group by am_concepto

update ca_rubro_op_tmp
set rot_gracia = gracia
from #gracia
where rot_operacion   = @i_operacionca
and   rot_tipo_rubro <> 'C'
and   rot_concepto    = concepto
-- FIN - REQ 175: PEQUEÑA EMPRESA

--EPB:MAR-09-2002 para el reajuste de tablas con ciclo
if @w_ult_vigente  = 1
   select @w_reajusta_cuota_uno = 'S'
else
   select  @w_reajusta_cuota_uno = 'N'


exec @w_error = sp_gentabla
@i_operacionca        = @i_operacionca,
@i_tabla_nueva        = 'S',
@i_reajusta_cuota_uno = @w_reajusta_cuota_uno,
@i_reajuste           = 'S',
@i_cuota_reajuste     = @w_ult_vigente,                        -- REQ 175: PEQUEÑA EMPRESA
@i_cuota_desde_cap    = null,
@o_fecha_fin          = @w_fecha_fin out

if @w_error <> 0 return  @w_error

   
-- SE BORRAN LOS RUBROS QUE NO SE REGENERARON PARA NO ACTUALIZARLOS MAS ABAJO
delete ca_rubro_op_tmp
from   ca_concepto
where  rot_operacion  = @i_operacionca
and    co_concepto    = rot_concepto
and    rot_tipo_rubro = co_categoria
and    rot_tipo_rubro  in ('A', 'S')                           -- REQ 175: PEQUEÑA EMPRESA

---PONER EL ESTADO DEL RUBRO CAP EN EL ESTADO ACTUAL
---PARA QUE SEA ACTAULIZADO  SINO SE PRESENTAN DIFERENCIAS DE CAPITAL 

update ca_amortizacion
set    am_estado    = @w_estado_op
where  am_operacion = @i_operacionca
and    am_concepto  = 'CAP'
and    am_dividendo = @w_ult_vigente

declare cursor_dividendo cursor for select 
di_dividendo
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_dividendo >= @w_ult_vigente
order  by di_dividendo
for read only

open cursor_dividendo

fetch cursor_dividendo into @w_dividendo

while  @@fetch_status = 0 begin

   -- INI - REQ 175: PEQUEÑA EMPRESA
   --delete @wt_secs_conc --LPO Ajustes Migracion Core Digital
   delete #wt_secs_conc --LPO Ajustes Migracion Core Digital
   
   --insert into @wt_secs_conc --LPO Ajustes Migracion Core Digital
   insert into #wt_secs_conc --LPO Ajustes Migracion Core Digital
   select
   am_concepto,         min(am_secuencia),         count(1)
   from ca_amortizacion A
   where am_operacion  = @i_operacionca
   and   am_dividendo  = @w_dividendo
   and   am_estado    <> @w_est_cancelado 
   and   exists(select 1
                from   ca_rubro_op_tmp
                where  rot_operacion = A.am_operacion
                and    rot_concepto  = A.am_concepto )
   group by am_concepto
   
   -- FIN - REQ 175: PEQUEÑA EMPRESA

   update ca_amortizacion  set    
   am_cuota     = case when cantidad > 1 and am_secuencia = min_sec  then 0          else amt_cuota              end,          -- REQ 175: PEQUEÑA EMPRESA
   am_acumulado = case when cantidad > 1 and am_secuencia = min_sec  then 0          else amt_acumulado          end,          -- REQ 175: PEQUEÑA EMPRESA
   am_pagado    = case when cantidad > 1 and am_secuencia = min_sec  then am_pagado  else am_pagado + amt_pagado end,          -- REQ 175: PEQUEÑA EMPRESA
   am_gracia    = case when am_secuencia <> min_sec                  then 0          else amt_gracia             end           -- REQ 175: PEQUEÑA EMPRESA
   from   ca_amortizacion_tmp a, #wt_secs_conc  --@wt_secs_conc  --LPO Ajustes Migracion Core Digital
   where  amt_operacion = @i_operacionca
   and    amt_dividendo = @w_dividendo  - @w_ult_vigente + 1
   and    am_operacion  = @i_operacionca
   and    am_dividendo  = @w_dividendo
   and    am_concepto   = amt_concepto
   and    am_estado    <> @w_est_cancelado
   and    concepto      = am_concepto
   and    exists(select 1                                         -- REQ 175: PEQUEÑA EMPRESA
                 from   ca_rubro_op_tmp
                 where  rot_operacion = a.amt_operacion
                 and    rot_concepto  = a.amt_concepto)
   
   
   if @@error <> 0 return 724401
      select @w_dividendos_van = @w_dividendo - @w_ult_vigente + 1

   
   fetch cursor_dividendo
   into  @w_dividendo
end

close cursor_dividendo
deallocate cursor_dividendo 

-- Valida que las condiciones de las cuotas de los dividendos que sufrieron cambios por el reajuste, 
-- sean iguales a las condiciones antes de realizar la transacción
if exists (select 1 from ca_dividendo with (nolock), ca_dividendo_tmp 
   where di_operacion = @i_operacionca
   and di_operacion  = dit_operacion 
   and di_dividendo  = (dit_dividendo + (@w_ult_vigente - 1))
   and (  di_fecha_ini  <> dit_fecha_ini
       or di_fecha_ven  <> dit_fecha_ven
       or di_dias_cuota <> dit_dias_cuota))
begin
   select @w_error = 725285 -- Error, las condiciones de los dividendos temporales no coinciden con la de los dividendos fijos
   return 725285
end

---EL VALOR PAGADO DEL ULTIMO DIV VIGENTE DEBE AUMENTARSE EN LA CUOTA VIGENTE
---POR QUE SINO HAY DIFERENCIAS DE CAPITAL
update ca_amortizacion
set   am_cuota     = am_cuota + am_pagado,
      am_acumulado = am_acumulado  + am_pagado
where am_operacion = @i_operacionca
and   am_concepto  = 'CAP'
and   am_dividendo = @w_ult_vigente

-- INSERTAR DIVIDENDOS EN CASO DE QUE EL PLAZO SEA MAYOR
-- MAXIMO DIVIDENDO DE LA TABLA DEFINITIVA YA ACTUALIZADA
select @w_num_dividendos_fin = max(di_dividendo)  + 1 
from   ca_dividendo
where  di_operacion     = @i_operacionca

-- NO. DE DIVIDENDO DE LA TABLA TEMPORAL
select @w_num_dividendos_tmp = count(1)
from   ca_dividendo_tmp
where  dit_operacion     = @i_operacionca

-- SI HAY MAS DIVIDENDOS EN LA TEMPORAL GENRADA QUE EN LA ORIGINAL SE INSERTAN ESTOS NUEVOS DIVIDENDO
select @w_mas_cuotas ='N'
if @w_num_dividendos_tmp > @w_dividendos_van 
begin
   select @w_mas_cuotas ='S'
   declare cursor_dividendo_tmp cursor for select 
   dit_dividendo
   from   ca_dividendo_tmp
   where  dit_operacion   = @i_operacionca
   and    dit_dividendo   > @w_dividendos_van
   order  by dit_dividendo
   for read only
   
   open cursor_dividendo_tmp
   
   fetch cursor_dividendo_tmp into  @w_dividendo
   
   while   @@fetch_status = 0  begin 
   
      if (@@fetch_status = -1) return 710004
      
      -- ACTUALIZACION DE LAS NUEVAS CUOTAS TANTO DE CAPITAL COMO DE INTERES
      insert into ca_dividendo(
      di_operacion,    di_dividendo,           di_fecha_ini,
      di_fecha_ven,    di_de_capital,          di_de_interes,
      di_gracia,       di_gracia_disp,         di_estado,
      di_dias_cuota,   di_prorroga,            di_intento,
      di_fecha_can)
      select 
      dit_operacion,   @w_num_dividendos_fin,  dit_fecha_ini,
      dit_fecha_ven,   dit_de_capital,         dit_de_interes,
      dit_gracia,      dit_gracia_disp,        dit_estado,
      dit_dias_cuota,  dit_prorroga,           dit_intento,
      dit_fecha_can
      from   ca_dividendo_tmp
      where  dit_operacion = @i_operacionca
      and    dit_dividendo = @w_dividendo
      
      if @@error <> 0 return 710001
      
      insert into ca_amortizacion(
      am_operacion,    am_dividendo,           am_concepto,
      am_estado,       am_periodo,             
      am_cuota,
      am_gracia,       am_pagado,              
      am_acumulado,
      am_secuencia)
      select 
      amt_operacion,   @w_num_dividendos_fin,  amt_concepto,
      amt_estado,      amt_periodo,            
      case when amt_cuota < 0 then 0
	        else amt_cuota
	   end,
      amt_gracia,      amt_pagado,             
      case when amt_acumulado < 0 then 0
	        else amt_acumulado
	   end,
      amt_secuencia
      from   ca_amortizacion_tmp
      where  amt_operacion = @i_operacionca
      and    amt_dividendo = @w_dividendo
      
      if @@error <> 0 return  710001
     
      select @w_num_dividendos_fin = @w_num_dividendos_fin + 1
      
      fetch cursor_dividendo_tmp into  @w_dividendo
      
   end 
   
   close cursor_dividendo_tmp
   deallocate cursor_dividendo_tmp
   
end -- FIN DE HAY MAS DIVIDENDO PARA INSERTAR A LA TABLA DEFINITIVA
---CALCULAR LA MIPYMES EN LA TABLA DEFINITIVA PARA LAS CUOTAS QUE 
---AUMENTARON

if @w_mas_cuotas ='S'
begin
if exists ( select 1 from ca_amortizacion
            where am_operacion = @i_operacionca
            and am_concepto =   @w_mipymes
            and am_cuota > 0)
   begin           
      exec @w_error  =  sp_calculo_mipymes_Vigente
      @i_operacion   = @i_operacionca,
      @i_mipymes     = @w_mipymes,
      @i_dividendo   = @w_tot_div_antes
      if @w_error <> 0 return @w_error
      
   end
end 


-- ELIMINACION DE LOS DIVIDENDOS SI EL PLAZO ES MENOR
if @w_num_dividendos_tmp < @w_num_dividendos begin

   delete ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_dividendo > @w_num_dividendos_tmp + @w_ult_vigente -1
   
   if @@error <> 0 return 710003
   
   delete ca_cuota_adicional
   where  ca_operacion = @i_operacionca
   and    ca_dividendo > @w_num_dividendos_tmp + @w_ult_vigente -1
   
   if @@error <> 0 return  710003
   
   delete ca_amortizacion
   where  am_operacion = @i_operacionca
   and    am_dividendo > @w_num_dividendos_tmp + @w_ult_vigente -1
   
   if @@error <> 0 return  710003
   
end --FIN NUMERO DE CUOTAS > 1


select @w_num_dividendos_fin = max(di_dividendo)
from   ca_dividendo
where  di_operacion     = @i_operacionca


----INICIO REQ 379 IFJ 25/Nov/2005 
select @w_ti_cuota_dest = min(ti_cuota_dest)
from   ca_traslado_interes
where  ti_operacion = @i_operacionca
and    ti_estado     = 'P'

if @@rowcount > 0
begin
   if @w_ti_cuota_dest <= @w_num_dividendos_fin
   begin
      return 711007
   end
end
--- FIN REQ 379 IFJ 25/Nov/2005 

update ca_rubro_op set    
ro_valor = am_cuota
from   ca_rubro_op_tmp, ca_amortizacion
where  am_operacion = @i_operacionca
and    am_dividendo = @w_num_dividendos_fin
and    am_concepto  = rot_concepto
and    rot_operacion = @i_operacionca
and    ro_operacion  = rot_operacion
and    ro_concepto   = rot_concepto

if @@error <> 0 return 710001

update ca_operacion
set op_cuota = opt_cuota
from ca_operacion_tmp,ca_operacion
where op_operacion = opt_operacion
and opt_operacion = @i_operacionca

-- ELIMINACION DE LAS TABLAS TEMPORALES
exec @w_error = sp_borrar_tmp_int
@i_operacionca = @i_operacionca

if @w_error <> 0 return @w_error

if @i_en_linea = 'S'
   select @w_observacion = 'TRANSACCION GENERADA POR EL reajcuot.sp en Linea'
else 
   select @w_observacion = 'TRANSACCION GENERADA POR EL reajcuot.sp en batch'

                      
select @w_monto_cap_despues = isnull(sum(am_cuota),0)
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_concepto = 'CAP'

if @w_monto_cap_antes <> @w_monto_cap_despues
begin
   PRINT 'Error en el resajuste, no cuadran las cuotas de capital cap_antes' + convert(varchar,@w_monto_cap_antes)+  'cap_despues' + convert(varchar,@w_monto_cap_despues)
   return 710554
end

if (select count(1)
    from   ca_amortizacion
    where  am_operacion = @i_operacionca
    and    am_concepto = 'CAP'
    and    am_cuota < 0) > 0
begin
   PRINT 'Error en el resajuste, Cuota negativa en CAPITAL'
   return 710554
end
if (select count(1)
    from   ca_amortizacion
    where  am_operacion = @i_operacionca
    and    am_concepto  in (@w_mipymes,@w_IVAmipymes)
    and    am_cuota < 0) > 0
begin
   update ca_amortizacion
   set    am_cuota = 0
   where  am_operacion = @i_operacionca
   and    am_concepto in (@w_mipymes,@w_IVAmipymes)
   and    am_cuota < 0
end

return 0

go

