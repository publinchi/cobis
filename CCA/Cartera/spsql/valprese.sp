/************************************************************************/
/*      Archivo:                valprese.sp                             */
/*      Stored procedure:       sp_valor_presente                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Marcelo Poveda                          */
/*      Fecha de escritura:     Ene. 1998                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Procedimiento que realiza el calculo del valor presente .       */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valor_presente')
   drop proc sp_valor_presente
go

create proc sp_valor_presente
@i_operacionca	int      = null,
@i_div_estado	tinyint  = null,
@i_fecha_pago	datetime = null,
@i_concepto	catalogo = null,
@o_monto	money    = null out
as
declare
@w_tipo_rubro	char(1),
@w_monto_rubro	money,
@w_gracia	money,
@w_tasa_interes	float,
@w_est_vigente	tinyint,
@w_fecha_ini	datetime,
@w_fecha_fin	datetime,
@w_factor	float,
@w_dias_anio	int,
@w_dividendo	int,
@w_cuota_capital money,
@w_dividendo1   float,
@w_divisor	float,
@w_aux          money,
@w_fpago        char(1),
@w_monto_adicional money,
@w_capital_total money,
@w_monto_total   money,
@w_moneda        tinyint,
@w_num_dec       tinyint,
@w_return        int,
@w_error         int

/** INICIALIZACION DE VARIABLES **/
select @w_est_vigente     = 1
select @w_aux             = 0
select @w_monto_adicional = 0

/** INFORMACION DE OPERACION **/
select 
@w_dias_anio = op_dias_anio,
@w_moneda    = op_moneda
from ca_operacion
where op_operacion = @i_operacionca

/** MANEJO DE DECIMALES **/
exec @w_return = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out

if @w_return != 0 return @w_return

/** VERIFICAR TIPO DE RUBRO **/
select 
@w_tipo_rubro = ro_tipo_rubro,
@w_fpago      = ro_fpago
from ca_rubro_op
where ro_operacion = @i_operacionca
and ro_concepto    = @i_concepto

if @@rowcount = 0 return 999999

/** SELECCIONAR EL MONTO DEL RUBRO **/
select 
@w_monto_rubro = sum(am_cuota-am_pagado),
@w_gracia = sum(am_gracia)
from ca_amortizacion,ca_dividendo
where am_operacion = @i_operacionca
and am_concepto    = @i_concepto
and di_operacion   = @i_operacionca
and di_estado      = @i_div_estado
and am_dividendo   = di_dividendo

if @w_monto_rubro <> 0 and @w_tipo_rubro = 'I' and @w_fpago = 'P' 
begin
   /** CONSULTA DE LA TASA DE INTERES ACTUAL DE LA OPERACION **/
   select @w_tasa_interes = ts_porcentaje
   from ca_tasas,ca_dividendo
   where ts_operacion = @i_operacionca
   and di_operacion   = @i_operacionca
   and di_estado      = @w_est_vigente
   and ts_concepto    = @i_concepto
   and ts_dividendo   <= di_dividendo
   and ts_fecha       <= @i_fecha_pago
   group by ts_operacion,ts_concepto,ts_dividendo,ts_fecha,ts_porcentaje
   having ts_fecha = max(ts_fecha)

   if @@rowcount = 0 return 710037

   if @i_div_estado <> @w_est_vigente 
   begin 
      /** MONTO TOTAL DE CAPITAL **/
      select  @w_monto_total =                            
      sum(am_cuota+am_gracia-am_pagado)     
      from ca_amortizacion,ca_rubro_op,ca_dividendo 
      where am_operacion = @i_operacionca                  
      and ro_operacion   = @i_operacionca                    
      and ro_tipo_rubro  = 'C'                              
      and ro_concepto    = am_concepto                        
      and di_operacion   = @i_operacionca
      and di_dividendo   = am_dividendo
      and di_estado      = @i_div_estado

      /** CURSOR DE DIVIDENDO **/
      declare dividendos cursor for
      select di_dividendo,di_fecha_ini, di_fecha_ven
      from ca_dividendo
      where di_operacion = @i_operacionca
      and di_estado      = @i_div_estado
      order by di_dividendo desc  
      for read only
         
      open dividendos

      fetch dividendos into @w_dividendo,@w_fecha_ini,@w_fecha_fin

      while @@fetch_status = 0 
      begin

         if @@fetch_status = -1 return 710004

         /** SELECCIONAR EL MONTO DEL RUBRO DE LA CUOTA **/
         select @w_monto_rubro = sum(am_cuota-am_pagado),
         @w_gracia = sum(am_gracia)
         from ca_amortizacion
         where am_operacion = @i_operacionca
         and am_dividendo   = @w_dividendo 
         and am_concepto    = @i_concepto

         /** SELECCIONAR EL MONTO DE CAPITAL DE LA CUOTA **/
         select  @w_cuota_capital=
         sum(am_cuota+am_gracia-am_pagado)
         from ca_amortizacion,ca_rubro_op
         where am_operacion = @i_operacionca
         and am_dividendo   = @w_dividendo
         and ro_operacion   = @i_operacionca
         and ro_tipo_rubro  = 'C'
         and ro_concepto    = am_concepto  
          
         /** ADICIONAR EL MONTO DE CAPITAL AL MONTO DEL RUBRO **/
         select @w_monto_rubro = @w_monto_rubro + @w_cuota_capital + 
                                 @w_monto_adicional 

         /** CALCULO DEL DIVISOR **/
         select @w_divisor = datediff(dd,@w_fecha_ini,@w_fecha_fin)

         /** CALCULO DEL DIVIDENDO **/
         if @w_fecha_ini < @i_fecha_pago begin
            select @w_dividendo1=datediff(dd,@i_fecha_pago,@w_fecha_fin)
         end else 
         begin 
            select @w_dividendo1= @w_divisor
         end

         /** CALCULO DEL FACTOR DE INTERES **/
         select @w_factor = (@w_tasa_interes * @w_divisor) /
         (@w_dias_anio * 100)
         select @w_factor = 1 + @w_factor
         select @w_factor=exp(log(@w_factor)*(@w_dividendo1/@w_divisor))

         /** CALCULO DEL VALOR PRESENTE **/          
            
         select @w_monto_rubro = @w_monto_rubro / @w_factor
         select @w_monto_adicional = @w_monto_rubro 
         fetch dividendos into @w_dividendo,@w_fecha_ini,@w_fecha_fin
      end
      close dividendos
      deallocate dividendos  

      /** TRAER EL CALCULO OBTENIDO A LA FECHA DE PAGO **/             
      if @w_fecha_ini > @i_fecha_pago 
      begin                               
         select @w_divisor = datediff(dd,di_fecha_ini,di_fecha_ven)
         from   ca_dividendo
         where  di_operacion = @i_operacionca
         and    di_estado    = 1 
 
         select @w_dividendo1= datediff(dd,@i_fecha_pago,@w_fecha_ini)     
         select @w_factor    = (@w_tasa_interes * @w_divisor) /                 
                               (@w_dias_anio * 100)                
         select @w_factor = @w_factor + 1 
         select @w_factor = exp(log(@w_factor)*(@w_dividendo1/@w_divisor))     
         select @w_monto_rubro = @w_monto_rubro / @w_factor                  
      end
      select @w_monto_rubro = @w_monto_rubro - @w_monto_total
   end else 
   begin 
      -- ESTADO VIGENTE
      
      select @w_fecha_fin = di_fecha_ven,
             @w_fecha_ini = di_fecha_ini,
             @w_dividendo = di_dividendo
      from   ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_estado      = @i_div_estado

      -- SELECCIONAR EL MONTO DE CAPITAL DE LA CUOTA
      select @w_cuota_capital=sum(am_cuota+am_gracia-am_pagado)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion = @i_operacionca
      and    am_dividendo  = @w_dividendo
      and    ro_operacion  = @i_operacionca
      and    ro_tipo_rubro = 'C'
      and    ro_concepto   = am_concepto  

      -- AUMENTAR EL MONTO DE CAPITAL AL MONTO DEL RUBRO
      select @w_monto_rubro = @w_monto_rubro + @w_cuota_capital        
        
      -- CALCULO DEL DIVISOR
      select @w_divisor = datediff(dd,@w_fecha_ini,@w_fecha_fin)

      -- CALCULO DEL DIVIDENDO
      select @w_dividendo1 = datediff(dd,@i_fecha_pago,@w_fecha_fin)

      -- CONSULTA DEL FACTOR DE INTERES
      select @w_factor = @w_tasa_interes * @w_divisor / (@w_dias_anio * 100) 
      select @w_factor = 1 + @w_factor
      select @w_factor = exp(log(@w_factor)*(@w_dividendo1/@w_divisor)) 
      -- CALCULO DEL VALOR PRESENTE
      select @w_monto_rubro = @w_monto_rubro / @w_factor
      -- ELIMINAR EL MONTO DE CAPITAL
      select @w_monto_rubro = @w_monto_rubro - @w_cuota_capital 

   end 
end 

select @w_monto_rubro = @w_monto_rubro + @w_gracia 
select @o_monto = isnull(@w_monto_rubro,0.00)

return 0
go

