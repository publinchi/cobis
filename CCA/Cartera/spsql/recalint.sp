/************************************************************************/
/*   Archivo:              recalint.sp                                  */
/*   Stored procedure:     sp_recalcula_interes                         */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         X. Saquicela                                 */
/*   Fecha de escritura:   Mar. 2000                                    */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*   PROPOSITO                                                          */
/*   Recalcula los intereses de cada dividendo a partir del vigente.    */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_recalcula_interes')
   drop proc sp_recalcula_interes
go

create proc sp_recalcula_interes
   @i_operacionca       int,
   @i_fecha_proceso     datetime,
   @i_num_dec           tinyint
as
declare 
   @w_error             int,
   @w_num_dividendos    int,
   @w_di_dias_cuota     int,
   @w_dividendo         int,
   @w_adicional         money,
   @w_saldo_cap         money,
   @w_ro_porcentaje     float,
   @w_ro_porcentaje_efa float,
   @w_valor_calc        float,
   @w_di_fecha_ini      datetime,
   @w_di_fecha_ven      datetime,
   @w_ro_concepto       catalogo,
   @w_di_estado         tinyint,
   @w_ro_fpago          char(1),
   @w_est_vigente       tinyint,
   @w_max_secuencia     tinyint,
   @w_di_vigente        smallint,
   @w_causacion         char(1),
   @w_op_dias_anio      smallint,
   @w_op_base_calculo   char(1)

-- DEFINICION DE ESTADOS
select @w_est_vigente    = 1

select @w_causacion = op_causacion,
       @w_op_dias_anio    = op_dias_anio,
       @w_op_base_calculo = op_base_calculo
from   ca_operacion 
where  op_operacion = @i_operacionca

select @w_di_vigente = di_dividendo,
       @w_di_fecha_ven = di_fecha_ven
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_estado    = @w_est_vigente

if @@error <> 0
begin
   select @w_error = 710001
   goto ERROR
end

if @w_di_fecha_ven = dateadd(dd, 1, @i_fecha_proceso)
begin
   select @w_di_vigente = @w_di_vigente + 1
   
   select @w_di_fecha_ven = di_fecha_ven
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_dividendo = @w_di_vigente
   
   if @@error <> 0
   begin
      select @w_error = 710001
      goto ERROR
   end
end

-- CALCULAR EL MONTO DEL CAPITAL TOTAL
select @w_saldo_cap = sum(am_cuota - am_pagado)
from   ca_amortizacion, ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_tipo_rubro = 'C'
and    ro_fpago      in ('P', 'A') -- PERIODICO VENCIDO O ANTICIPADO
and    am_operacion = @i_operacionca
and    am_concepto  = ro_concepto 
and    am_dividendo >= @w_di_vigente

-- DETERMINAR EL NUMERO DE DIVIDENDOS EXISTENTES
select @w_num_dividendos = count (1)
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_dividendo >= @w_di_vigente

-- LAZO PRINCIPAL DE DIVIDENDOS
declare
   cursor_dividendo cursor
   for select di_dividendo,   di_fecha_ini,  di_fecha_ven,
              di_estado,      di_dias_cuota
       from   ca_dividendo
       where  di_operacion  = @i_operacionca
       and    di_dividendo >= @w_di_vigente
       order  by di_dividendo
   for read only

open  cursor_dividendo

fetch cursor_dividendo
into @w_dividendo,   @w_di_fecha_ini,  @w_di_fecha_ven,
     @w_di_estado,   @w_di_dias_cuota

while   @@fetch_status = 0 --WHILE CURSOR PRINCIPAL
begin
   if (@@fetch_status = -1)
   begin
      select @w_error = 710004
      goto ERROR
   end
   
   -- CONTROL DE DIAS PARA ANIOS BISIESTOS
   exec @w_error = sp_dias_anio
        @i_fecha     = @w_di_fecha_ini,
        @i_dias_anio = @w_op_dias_anio,
        @o_dias_anio = @w_op_dias_anio OUT
   
   if @w_error != 0
      return @w_error
   
   -- CURSOR DE RUBROS TABLA CA_RUBRO_OP
   declare
      cursor_rubros cursor
      for select ro_concepto, ro_porcentaje, ro_fpago, ro_porcentaje_efa
          from   ca_rubro_op
          where  ro_operacion  = @i_operacionca
          and    ro_fpago      in ('P','A') -- PERIODICO VENCIDO O ANTICIPADO
          and    ro_tipo_rubro = 'I'
          order  by ro_tipo_rubro desc
   for read only
   
   open  cursor_rubros
   
   fetch cursor_rubros
   into  @w_ro_concepto, @w_ro_porcentaje, @w_ro_fpago, @w_ro_porcentaje_efa
   
   while   @@fetch_status = 0 --WHILE CURSOR RUBROS
   begin
      if (@@fetch_status = -1)
      begin
         select @w_error = 710004
         goto ERROR
      end
      
      -- ACTUALIZAR EL RUBRO EN TABLA CA_AMORTIZACION
      select @w_max_secuencia = max(am_secuencia)
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_dividendo
      and    am_concepto  = @w_ro_concepto
      
      -- QUITAR LO QUE FALTE POR CALCULAR
      update ca_amortizacion
      set    am_cuota = am_acumulado -- SI NO TIENE NADA ACUMULADO QUEDA EN CERO
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_dividendo
      and    am_concepto  = @w_ro_concepto
      and    am_secuencia = @w_max_secuencia
      
      select @w_valor_calc = 0
      
      -- RUBROS DE TIPO INTERES
      if @w_ro_porcentaje_efa > 0
      begin
         if @w_ro_fpago in ('P', 'T')
            select @w_ro_fpago = 'V'
         
         if @w_di_estado != @w_est_vigente
         begin
            -- CALCULAR LA TASA EQUIVALENTE
            exec @w_error = sp_conversion_tasas_int
                 @i_periodo_o       = 'A',
                 @i_modalidad_o     = 'V',
                 @i_num_periodo_o   = 1,
                 @i_tasa_o          = @w_ro_porcentaje_efa,
                 @i_periodo_d       = 'D',
                 @i_modalidad_d     = @w_ro_fpago,
                 @i_num_periodo_d   = @w_di_dias_cuota,
                 @i_dias_anio       = @w_op_dias_anio,
                 @o_tasa_d          = @w_ro_porcentaje output
            
            if @w_error != 0
               return @w_error
            
            exec @w_error = sp_calc_intereses
                 @tasa      = @w_ro_porcentaje,
                 @monto     = @w_saldo_cap,
                 @dias_anio = @w_op_dias_anio,
                 @num_dias  = @w_di_dias_cuota,
                 @causacion = @w_causacion, 
                 @intereses = @w_valor_calc out
            
            if @w_error != 0
               return @w_error
            
            select @w_valor_calc = round(@w_valor_calc, @i_num_dec)
         end
         ELSE -- DIVIDENDO VIGENTE
         begin
            if @i_fecha_proceso != @w_di_fecha_ven -- AUN FALTA ALGO POR CALCULAR DEL VIGENTE
            begin
               -- DETERMINAR LOS DIAS QUE FALTAN
               if @w_op_base_calculo = 'E'
               begin
                  exec @w_error = sp_dias_cuota_360
                       @i_fecha_ini = @i_fecha_proceso,
                       @i_fecha_fin = @w_di_fecha_ven,
                       @o_dias      = @w_di_dias_cuota out 
                  
                  if @w_error != 0
                     goto ERROR   
               end
               ELSE
               begin
                  select @w_di_dias_cuota = datediff(dd,@i_fecha_proceso,@w_di_fecha_ven)
               end
               
               -- CALCULAR LA TASA EQUIVALENTE
               exec @w_error = sp_conversion_tasas_int
                    @i_periodo_o       = 'A',
                    @i_modalidad_o     = 'V',
                    @i_num_periodo_o   = 1,
                    @i_tasa_o          = @w_ro_porcentaje_efa,
                    @i_periodo_d       = 'D',
                    @i_modalidad_d     = @w_ro_fpago,
                    @i_num_periodo_d   = @w_di_dias_cuota,
                    @i_dias_anio       = @w_op_dias_anio,
                    @o_tasa_d          = @w_ro_porcentaje output
               
               if @w_error != 0
                  return @w_error
               
               exec @w_error = sp_calc_intereses
                    @tasa      = @w_ro_porcentaje,
                    @monto     = @w_saldo_cap,
                    @dias_anio = @w_op_dias_anio,
                    @num_dias  = @w_di_dias_cuota,
                    @causacion = @w_causacion, 
                    @intereses = @w_valor_calc out
               
               if @w_error != 0
                  return @w_error
               
               select @w_valor_calc = round(@w_valor_calc, @i_num_dec)
            end
         end
         
         update ca_amortizacion 
         set    am_cuota     = am_cuota + isnull(@w_valor_calc, 0)
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_dividendo
         and    am_concepto  = @w_ro_concepto
         and    am_secuencia = @w_max_secuencia
         
         if (@@error <> 0)
         begin
            select @w_error = 710003
            goto ERROR
         end
      end
      
      fetch cursor_rubros
      into  @w_ro_concepto, @w_ro_porcentaje, @w_ro_fpago, @w_ro_porcentaje_efa
   end --WHILE CURSOR RUBROS
   
   close cursor_rubros
   deallocate cursor_rubros
   
   -- DISMINUIR AL SALDO DE CAPITAL LA CUOTA DE CAPITAL DEL DIV ACTUAL
   select @w_valor_calc = sum(am_cuota+am_pagado)
   from   ca_amortizacion,ca_rubro_op
   where  am_operacion = @i_operacionca
   and    am_dividendo = @w_dividendo
   and    ro_operacion = @i_operacionca
   and    ro_concepto  = am_concepto
   and    ro_tipo_rubro= 'C'
   
   select @w_saldo_cap  = @w_saldo_cap - @w_valor_calc
   
   fetch cursor_dividendo
   into  @w_dividendo,  @w_di_fecha_ini, @w_di_fecha_ven,
         @w_di_estado,  @w_di_dias_cuota
end --WHILE CURSOR DIVIDENDOS

close cursor_dividendo
deallocate cursor_dividendo

return 0

ERROR:

return @w_error
 
go
