/************************************************************************/
/*  Archivo:            capryrub.sp                                     */
/*  Stored procedure:   sp_proyeccion_rubro                             */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:       Fabian de la Torre / Gabriel Alvis              */
/*  Fecha de escritura: 25/Oct/2010                                     */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Proyecta los valores de rubros de operaciones con acuerdo de pago   */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA         AUTOR             RAZON                               */
/************************************************************************/

use cob_cartera
go

if object_id('sp_proyeccion_rubro') is not null
   drop proc sp_proyeccion_rubro
go

create proc sp_proyeccion_rubro
@i_operacionca    int          = null,
@i_tipo_acuerdo   varchar(10)  = null,
@i_fecha_pry      datetime     = null,
@i_acuerdo        int          = null,
@o_cap            money        = null  out,
@o_int            money        = null  out,
@o_imo            money        = null  out,
@o_hon            money        = null  out,
@o_ivahon         money        = null  out,
@o_otr            money        = null  out,
@o_cap_pry        money        = null  out,
@o_int_pry        money        = null  out,
@o_imo_pry        money        = null  out,
@o_hon_pry        money        = null  out,
@o_ivahon_pry     money        = null  out,
@o_otr_pry        money        = null  out
as

declare
@w_error                  int,
@w_sp_name                varchar(32),
@w_msg                    varchar(255),
@w_porcentaje             float,
@w_dias_anio              smallint,
@w_causacion              char(1),
@w_saldo_cap              money,
@w_cap_mora               money,
@w_dias                   smallint,
@w_dias_p                 datetime,
@w_fecha_ult_proceso      datetime,
@w_oficina                int,
@w_proyeccion             money,
@w_di_dividendo           smallint,
@w_di_fecha_ven           datetime,
@w_di_vigente_pry         smallint,
@w_di_fecha_ini_pry       datetime,
@w_fecha_ini              datetime,
@w_fecha_fin              datetime,
@w_op_estado              int,
@w_moneda                 tinyint,
@w_num_dec                tinyint,
@w_est_vigente            tinyint,
@w_est_vencido            tinyint,
@w_est_novigente          tinyint,
@w_est_cancelado          tinyint,
@w_est_credito            tinyint,
@w_est_anulado            tinyint,
@w_param_cap              varchar(30),
@w_param_int              varchar(30),
@w_param_mora             varchar(30),
@w_param_honabo           varchar(30),
@w_param_ivahonabo        varchar(30),
@w_cont_dias              smallint,
@w_proy_dia               float,
@w_mora_div               money,
@w_toperacion             catalogo,
@w_dias_anio_mora         smallint,
@w_banco				  cuenta,
@w_cap_acu        		  money,
@w_int_acu        		  money,
@w_imo_acu        		  money,
@w_otr_acu        		  money,
@w_pag_acu				  money,
@w_fecha_ant              datetime,
@w_negocio_ant            int	
   
-- CONDICIONES INICIALES
select 
@w_sp_name      = 'sp_proyeccion_rubro',
@w_error        = 0

-- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_anulado    = @w_est_anulado   out,
@o_est_credito    = @w_est_credito   out

if @w_error <> 0
   goto ERROR


-- PARAMETROS DE CONCEPTOS
select @w_param_cap = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CAP'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701060
   goto ERROR
end

select @w_param_int = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701059
   goto ERROR
end

select @w_param_mora = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IMO'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701084
   goto ERROR
end

select @w_param_honabo = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'HONABO'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701015
   goto ERROR
end

select @w_param_ivahonabo = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'IVAHOB'
and    pa_producto = 'CCA'

if @@rowcount = 0 
begin
   select @w_error = 701015
   goto ERROR
end


-- CONTROL DE PARAMETROS
if @i_operacionca is null or @i_fecha_pry is null or @i_tipo_acuerdo is null
begin
   select 
   @w_error = 2600100,
   @w_msg   = 'FALTAN PARAMETROS OBLIGATORIOS'
   goto ERROR
end

-- VALIDACIONES
select 
@w_dias_anio         = op_dias_anio,
@w_causacion         = op_causacion,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_oficina           = op_oficina,
@w_op_estado         = op_estado,
@w_moneda            = op_moneda,
@w_toperacion        = op_toperacion,
@w_banco             = op_banco
from ca_operacion
where op_operacion = @i_operacionca

select @w_dias_anio_mora = dt_dias_anio_mora
from ca_default_toperacion
where dt_toperacion = @w_toperacion
and   dt_moneda     = @w_moneda


-- CONTROL DEL NUMERO DE DECIMALES
exec @w_error = sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec out
   
if @w_error <> 0
   goto ERROR
   
select @w_cap_acu=0
select @w_int_acu=0
select @w_imo_acu=0
select @w_otr_acu=0


if exists(
select 1 from cobis..cl_dias_feriados, cobis..cl_oficina
where  df_fecha   = @i_fecha_pry
and    df_ciudad  = of_ciudad
and    of_oficina = @w_oficina                          )
begin
   select 
   @w_error = 708144,
   @w_msg   = 'FECHA DE PROYECCION ES DIA FESTIVO'
   goto ERROR
end

if @w_fecha_ult_proceso >= @i_fecha_pry and not exists(select 1 from cob_credito..cr_acuerdo where ac_banco = @w_banco and ac_pago_cubierto = 'S') begin
   select 
   @w_error = 101140,
   @w_msg   = 'FECHA DE PROYECCION DEBE SER MAYOR A FECHA DE ULTIMO PROCESO DE LA OPERACION'
   goto ERROR
end

if @w_op_estado in (@w_est_credito, @w_est_novigente, @w_est_anulado, @w_est_cancelado) begin
   select 
   @w_error = 101140,
   @w_msg   = 'OPERACION NO VIGENTE'
   goto ERROR
end


/**************** ACUERDO DE NORMALIZACION ****************/
/* -> CONGELAMIENTO DE CUOTAS VENCIDAS                    */
if @i_tipo_acuerdo = 'N' begin

   /* DETERMINAR LOS SALDOS DE LOS RUBROS A LA FECHA DE PROCESO */
   select 
   @o_cap    = isnull(sum(case when am_concepto = @w_param_cap       then am_cuota + am_gracia - am_pagado else 0 end), 0),
   @o_int    = isnull(sum(case when am_concepto = @w_param_int       then am_cuota + am_gracia - am_pagado else 0 end), 0),
   @o_imo    = isnull(sum(case when am_concepto = @w_param_mora      then am_cuota + am_gracia - am_pagado else 0 end), 0),
   @o_hon    = isnull(sum(case when am_concepto = @w_param_honabo    then am_cuota + am_gracia - am_pagado else 0 end), 0),
   @o_ivahon = isnull(sum(case when am_concepto = @w_param_ivahonabo then am_cuota + am_gracia - am_pagado else 0 end), 0),
   @o_otr    = isnull(sum(case when am_concepto not in (@w_param_cap, @w_param_int, @w_param_mora, @w_param_honabo, @w_param_ivahonabo) then am_cuota + am_gracia - am_pagado else 0 end), 0)
   from ca_dividendo, ca_amortizacion
   where di_operacion = @i_operacionca
   and   di_estado    = @w_est_vencido
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo
 
   if exists (select 1 from cob_credito..cr_acuerdo where ac_acuerdo = @i_acuerdo
              and ac_fecha_proy < @i_fecha_pry and ac_estado = 'V')
   begin           
   select @w_cap_acu = sum(ac_cap_cond),
          @w_int_acu = sum(ac_int_cond),
          @w_imo_acu = sum(ac_imo_cond),
          @w_otr_acu = sum(ac_otr_cond),
          @w_pag_acu = sum(av_neto) 
   from   cob_credito..cr_acuerdo, cob_credito..cr_acuerdo_vencimiento
   where ac_acuerdo = @i_acuerdo
   and   ac_fecha_proy < @i_fecha_pry   
   and   ac_acuerdo = av_acuerdo
   and   av_fecha   = ac_fecha_proy
   and   ac_tacuerdo = @i_tipo_acuerdo
   and   ac_estado   = 'V'
   end       
   
   select @w_pag_acu = @w_pag_acu - ((isnull(@o_int_pry,0) + isnull(@o_otr_pry,0) + isnull(@o_imo_pry,0)))
   
   /* EN CUOTAS VENCIDAS, EL UNICO RUBRO QUE DEBE PROYECTARSE ES LA MORA */  

   /* DETERMINAR LA TASA DE MORA */
   select @w_porcentaje = ro_porcentaje_efa
   from ca_rubro_op
   where ro_operacion = @i_operacionca
   and   ro_concepto  = @w_param_mora
   
   if @@rowcount = 0 begin
      select
      @w_error = 708147,
      @w_msg   = 'TASA DE INTERES DE MORA NO DEFINIDA'
      goto ERROR
   end

   select @w_dias = datediff(dd, @w_fecha_ult_proceso, @i_fecha_pry)
   
   select 
   @w_proyeccion = @o_imo,
   @w_cont_dias  = 1
   
   while @w_cont_dias <= @w_dias
   begin
      
      exec @w_error = sp_calc_intereses 
      @tasa           = @w_porcentaje,
      @monto          = @o_cap,
      @dias_anio      = @w_dias_anio_mora,
      @num_dias       = 1,
      @causacion      = 'E',
      @causacion_acum = @w_proyeccion,
      @intereses      = @w_proy_dia   out 
      
      if @w_error <> 0 goto ERROR

      select 
      @w_proyeccion = @w_proyeccion + round(@w_proy_dia, @w_num_dec),
      @w_cont_dias  = @w_cont_dias + 1
       
      
   end  
   
   select 
   @o_cap_pry    = @o_cap - (isnull(@w_cap_acu,0)+ isnull(@w_pag_acu,0)) ,
   @o_int_pry    = @o_int - isnull(@w_int_acu,0),
   @o_imo_pry    = isnull(@w_proyeccion, 0) - isnull(@w_imo_acu,0),
   @o_hon_pry    = @o_hon,
   @o_ivahon_pry = @o_ivahon,
   @o_otr_pry    = @o_otr - isnull(@w_otr_acu,0)   
   return 0
   
end


/**************** ACUERDO DE PRECANCELACION ****************/
/* -> SE DEBE PROYECTAR LA TOTALIDAD DE LA OPERACION       */
/* -> SE CONGELA TODA LA OPERACION                         */
if @i_tipo_acuerdo = 'P' begin

   select 
   @w_di_vigente_pry = isnull(min(di_dividendo), 9999)
   from ca_dividendo 
   where di_operacion  = @i_operacionca
   and   di_fecha_ven >= @i_fecha_pry
   and   di_estado    <> @w_est_cancelado
   
   
   select @w_negocio_ant = 0
   select @w_negocio_ant = max(ac_acuerdo), 
          @w_fecha_ant   = max(ac_fecha_proy)
   from cob_credito..cr_acuerdo where ac_banco = @w_banco 
   and ac_fecha_proy < @i_fecha_pry
   and ac_estado     = 'V'
  
   if @w_negocio_ant = 0 begin
      select
      @w_di_fecha_ini_pry = di_fecha_ini,
      @w_dias             = datediff(dd, di_fecha_ini, @i_fecha_pry)
      from ca_dividendo
      where di_operacion = @i_operacionca
      and   di_dividendo = @w_di_vigente_pry
      
      if @@rowcount = 0 select @w_di_fecha_ini_pry = '12/31/2999'
   end
   else begin
      select @w_dias = datediff(dd, @w_fecha_ant, @i_fecha_pry)
   end
   
   /* DETERMINAR EL SALDO TOTAL DE CAPITAL, HONORARIOS E IVA SOBRE HONORARIOS */
   select 
   @o_cap    = isnull(sum(case when am_concepto = @w_param_cap       then am_cuota + am_gracia - am_pagado else 0 end), 0),
   @o_hon    = isnull(sum(case when am_concepto = @w_param_honabo    then am_cuota + am_gracia - am_pagado else 0 end), 0),
   @o_ivahon = isnull(sum(case when am_concepto = @w_param_ivahonabo then am_cuota + am_gracia - am_pagado else 0 end), 0)
   from ca_dividendo, ca_amortizacion
   where di_operacion  = @i_operacionca
   and   di_estado    <> @w_est_cancelado
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   am_concepto  in (@w_param_cap, @w_param_honabo, @w_param_ivahonabo) 
   
   /* DETERMINAR LOS INTERESES COMPLETAMENTE DEVENGADOS A LA FECHA DE PROCESO */
   select @o_int = isnull(sum(am_acumulado - am_pagado ), 0)
   from ca_dividendo, ca_amortizacion
   where di_operacion = @i_operacionca
   and   di_estado   in (@w_est_vigente, @w_est_vencido)
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo
   and   am_concepto  = @w_param_int
      
   /* DETERMINAR LOS INTERESES COMPLETAMENTE DEVENGADOS A LA FECHA DE PROYECCION */
   select @o_int_pry = isnull(sum(am_cuota + am_gracia - am_pagado ), 0)
   from ca_dividendo, ca_amortizacion
   where di_operacion  = @i_operacionca
   and   di_estado    <> @w_est_cancelado
   and   di_dividendo  < @w_di_vigente_pry
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   am_concepto   = @w_param_int
   
   if @w_fecha_ult_proceso > @w_di_fecha_ini_pry begin
   
      select @w_dias = datediff(dd, @w_fecha_ult_proceso, @i_fecha_pry)
      
  select @o_int_pry = @o_int_pry + isnull(sum(am_acumulado - am_pagado ), 0)
      from ca_dividendo, ca_amortizacion
      where di_operacion  = @i_operacionca
      and   di_estado    <> @w_est_cancelado
      and   di_dividendo  = @w_di_vigente_pry
      and   am_operacion  = di_operacion
      and   am_dividendo  = di_dividendo
      and   am_concepto   = @w_param_int
   end
   
   /* CALCULAR EL VALOR YA DEVENGADO DE MORA A LA FECHA DEL ACUERDO */
   select @o_imo = isnull(sum(am_cuota + am_gracia - am_pagado ), 0)
   from ca_dividendo, ca_amortizacion
   where di_operacion  = @i_operacionca
   and   di_estado    <> @w_est_cancelado
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   am_concepto   = @w_param_mora
   
   /* DETERMINAR VALORES DEVENGADOS DE OTROS RUBROS A LA FECHA DE PROCESO */
   select @o_otr = isnull(sum(am_cuota + am_gracia - am_pagado ), 0)
   from ca_dividendo, ca_amortizacion
   where di_operacion  = @i_operacionca
   and   di_estado    in (@w_est_vigente, @w_est_vencido)
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   am_concepto not in (@w_param_cap, @w_param_int, @w_param_mora, @w_param_honabo, @w_param_ivahonabo)
   
   
   /* DETERMINAR VALORES DEVENGADOS DE OTROS RUBROS A LA FECHA PROYECCION */
   select @o_otr_pry = isnull(sum(am_cuota + am_gracia - am_pagado ), 0)
   from ca_dividendo, ca_amortizacion
   where di_operacion  = @i_operacionca
   and   di_estado    <> @w_est_cancelado
   and   di_dividendo <= @w_di_vigente_pry
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   am_concepto not in (@w_param_cap, @w_param_int, @w_param_mora, @w_param_honabo, @w_param_ivahonabo)
  
   if @w_negocio_ant > 0 begin           
      select @w_cap_acu = sum(ac_cap_cond),
             @w_int_acu = sum(ac_int_cond),
             @w_imo_acu = sum(ac_imo_cond),
             @w_otr_acu = sum(ac_otr_cond),
             @w_pag_acu = sum(av_monto) 
      from   cob_credito..cr_acuerdo, cob_credito..cr_acuerdo_vencimiento
      where ac_banco = @w_banco
      and   ac_fecha_proy < @i_fecha_pry
      and   ac_acuerdo    = @w_negocio_ant      
      and   ac_acuerdo    = av_acuerdo
      and   ac_fecha_proy = av_fecha                    
 
   end                 

   select @w_pag_acu = @w_pag_acu - ((isnull(@o_int_pry,0) + isnull(@o_otr_pry,0) + isnull(@o_imo_pry,0)))
        
   select @o_int_pry = @o_int_pry - @w_int_acu
   select @o_otr_pry = @o_otr_pry - @w_otr_acu  
   
   if @o_int_pry < 0
      select @o_int_pry = 0
   if @o_otr_pry < 0
      select @o_otr_pry = 0
   if @w_pag_acu < 0
      select @w_pag_acu  = 0

      
   /* PROYECCION DE INTERESES CORRIENTES */
   if @w_dias > 0 begin
          
      -- DETERMINCION DEL PORCENTAJE
      select @w_porcentaje = ro_porcentaje
      from ca_rubro_op
      where ro_operacion = @i_operacionca
      and   ro_concepto  = @w_param_int
      
      if @@rowcount = 0
      begin
         select
         @w_error = 722101,
         @w_msg   = 'TASA DE INTERES CORRIENTE NO DEFINIDA'
         goto ERROR
      end

      if @w_negocio_ant > 0 begin       
         select @w_saldo_cap = @o_cap - isnull(@w_pag_acu,0)
      end 
      else begin
         select @w_saldo_cap = sum(am_cuota + am_gracia - am_pagado)
         from ca_amortizacion
         where am_operacion  = @i_operacionca
         and   am_dividendo >= @w_di_vigente_pry
         and   am_concepto   = @w_param_cap
      end
      
      exec @w_error = sp_calc_intereses 
      @tasa       = @w_porcentaje,
      @monto      = @w_saldo_cap,
      @dias_anio  = @w_dias_anio,
      @num_dias   = @w_dias,
      @causacion  = @w_causacion,
      @intereses  = @w_proyeccion   out   
      
      if @w_error <> 0 goto ERROR       
               
      select @o_int_pry = @o_int_pry + isnull(round(@w_proyeccion, @w_num_dec), 0)
      
   end

   /* PROYECCION DE LA MORA */
   
   -- DETERMINAR LOS DIVIDENDOS INVOLUCRADOS EN LA PROYECCION
   select 
   dividendo = di_dividendo,
   fecha_ven = di_fecha_ven
   into #div_pry
   from ca_dividendo
   where di_operacion   = @i_operacionca
   and   di_estado     <> @w_est_cancelado
   and   di_dividendo   < @w_di_vigente_pry
   
   -- DETERMINACION DEL PORCENTAJE DE MORA   
   select @w_porcentaje = ro_porcentaje_efa
   from ca_rubro_op
   where ro_operacion = @i_operacionca
   and   ro_concepto  = @w_param_mora
   
   if @@rowcount = 0 begin
      select
      @w_error = 708147,
      @w_msg   = 'TASA DE INTERES DE MORA NO DEFINIDA'
      goto ERROR
   end   

   -- CICLO DE PROYECCION   
   select 
   @o_imo_pry      = 0,
   @w_di_dividendo = 0
   
   while 1=1 begin
   
      select top 1
      @w_di_dividendo = dividendo,
      @w_di_fecha_ven = fecha_ven,
      @w_dias         = datediff(dd, fecha_ven, @i_fecha_pry)
      from #div_pry
      where dividendo > @w_di_dividendo
      order by dividendo
      
      if @@rowcount = 0 break
         
      /* DETERMINAR EL SALDO DE CAPITAL VENCIDO DE LA CUOTA ACTUAL*/
      select @w_cap_mora = isnull(sum(am_cuota + am_gracia - am_pagado), 0)
      from ca_amortizacion
      where am_operacion = @i_operacionca
      and   am_dividendo = @w_di_dividendo
      and   am_concepto  = @w_param_cap

      if @w_fecha_ult_proceso > @w_di_fecha_ven  select @w_dias = datediff(dd, @w_fecha_ult_proceso, @i_fecha_pry)
      
      if @w_cap_mora > 0 begin
      
         select @w_mora_div = isnull(sum(am_cuota + am_gracia - am_pagado), 0)
         from ca_amortizacion
         where am_operacion = @i_operacionca
         and   am_dividendo = @w_di_dividendo
         and   am_concepto  = @w_param_mora
    
         select 
         @w_proyeccion = @w_mora_div,
         @w_cont_dias  = 0
         
         while @w_cont_dias < @w_dias
         begin
            exec @w_error = sp_calc_intereses 
            @tasa            = @w_porcentaje,
            @monto           = @w_cap_mora,
            @dias_anio       = @w_dias_anio_mora,
            @num_dias        = 1,
            @causacion       = 'E',
            @causacion_acum  = @w_proyeccion,
            @intereses       = @w_proy_dia   out
            
            if @w_error <> 0 goto ERROR
            
            select 
            @w_proyeccion = @w_proyeccion + round(@w_proy_dia, @w_num_dec),
            @w_cont_dias  = @w_cont_dias + 1
         end
         
         select @o_imo_pry = (@o_imo_pry + isnull(@w_proyeccion, 0)) - @w_imo_acu 
         if @o_imo_pry < 0
            select @o_imo_pry = 0        
      end

   end
   
   select @o_cap_pry     = @o_cap - isnull(@w_pag_acu,0),
          @o_hon_pry     = @o_hon,
          @o_ivahon_pry  = @o_ivahon  
          
   return 0


end

return 0

ERROR:

print @w_msg
return @w_error

