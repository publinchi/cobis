/************************************************************************/
/*   Archivo:            ca_pagflex_recalotros.sp                       */
/*   Stored procedure:   sp_ca_pagflex_recal_otros                     */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Elcira PElaez Burbano                          */
/*   Fecha de escritura: May 2014                                       */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                          PROPOSITO                                   */
/*   Procedimiento  recalcula otros rubros despues de un cambiode saldo */
/*   de capital en las tablas FLEXIBLES                                 */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA           AUTOR      RAZON                                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca_pagflex_recal_otros')
   drop proc sp_ca_pagflex_recal_otros
go

create proc sp_ca_pagflex_recal_otros
   @s_user              login,
   @s_term              varchar(30),
   @s_date              datetime,
   @s_ofi               int,
   @i_operacionca       int,
   @i_num_dec           int = 0

as  
declare 
   @w_error             int,
   @w_dividendo         smallint,
   @w_operacion         int,
   @w_fecha_ini         datetime,
   @w_fecha_ven         datetime,
   @w_di_dias_cuota     smallint,
   @w_ult_div_vig       smallint,
   @w_est_cancelado     tinyint,
   @w_est_novigente     tinyint,
   @w_est_vigente       tinyint,
   @w_ro_concepto       catalogo, 
   @w_ro_tipo_rubro     catalogo, 
   @w_ro_porcentaje     float,
   @w_nro_periodos      smallint,
   @w_parametro_segdeuven catalogo,
   @w_saldo_capital       money,
   @w_valor_rubro         money,
   @w_di_estado          tinyint,
   @w_valor_no_vig       money,
   @w_porcentaje_aso     float,
   @w_asociado           float,
   @w_valor_asociado     float

  
      
--PARAMETROS GENERALES
exec @w_error = sp_estados_cca
     @o_est_vigente    = @w_est_vigente   out,
     @o_est_cancelado  = @w_est_cancelado out,
     @o_est_novigente  = @w_est_novigente out

if @w_error <> 0
   return @w_error

select @w_parametro_segdeuven = pa_char
from   cobis..cl_parametro  with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'SEDEVE'
       
select @w_ult_div_vig = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_estado = 1

declare
   Cur_RPInterno cursor
   for select di_dividendo,
              di_operacion,
              di_fecha_ini,
              di_fecha_ven,
              di_dias_cuota,
              di_estado
       from   ca_dividendo
       where  di_operacion = @i_operacionca
       and    di_estado  in(1, 0 )
       order  by di_dividendo asc 
   for read only

open  Cur_RPInterno

fetch Cur_RPInterno
into  @w_dividendo,
      @w_operacion,
      @w_fecha_ini,
      @w_fecha_ven,
      @w_di_dias_cuota,
      @w_di_estado

while @@fetch_status  = 0
begin --INICIO
   ---Nro.PERIDOS DE INT EN 30 DIAS
   select @w_nro_periodos = round(@w_di_dias_cuota  /30 ,0)
      
   ---SALDO DE CAPITAL POR CUOTA
   select @w_saldo_capital = isnull(sum(am_cuota - am_pagado),0)
   from   ca_amortizacion,
          ca_rubro_op
   where  am_operacion = @i_operacionca
   and    am_operacion = ro_operacion
   and    ro_tipo_rubro = 'C'
   and    am_concepto = ro_concepto
   and    am_dividendo >= @w_dividendo

   ---CURSOR DE RUBROS QUE DEPENDEN DEL SALDO
   declare
      cur_RPRubros cursor
      for select ro_concepto, 
                 ro_tipo_rubro, 
                 ro_porcentaje
          from   ca_rubro_op
          where  ro_operacion  = @i_operacionca
          and    ro_saldo_op = 'S'
          and    ro_fpago in ('A','P') 
          order by ro_tipo_rubro desc
      for read only

   open  cur_RPRubros 
   fetch cur_RPRubros
   into  @w_ro_concepto, 
         @w_ro_tipo_rubro, 
         @w_ro_porcentaje

   while @@fetch_status  = 0
   begin --INICIO RUBROS
      select @w_valor_rubro = 0              
   
      if @w_ro_concepto = @w_parametro_segdeuven
      begin
         select @w_ro_porcentaje =  @w_ro_porcentaje * @w_nro_periodos
         select @w_valor_rubro = @w_saldo_capital * @w_ro_porcentaje / 100.0
         select @w_valor_rubro = round(@w_valor_rubro , @i_num_dec)
               
         if @w_valor_rubro > 0
         begin
            if @w_di_estado = 1
               select @w_valor_no_vig = @w_valor_rubro
            else
               select @w_valor_no_vig = 0      
                        
			
            update ca_amortizacion
            set    am_cuota      = case 
                                     when @w_valor_rubro > am_pagado then @w_valor_rubro
                                     else am_cuota
                                   end,
                   am_acumulado  = case 
                                     when @w_valor_no_vig > am_pagado then @w_valor_no_vig
                                     else am_acumulado
                                   end
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_dividendo
            and    am_concepto  = @w_ro_concepto

            if @@error <> 0
               return 724026
                  
            ---VALIDAR SI TIENE ASOCIADO
            select @w_asociado       = ro_concepto,
                   @w_porcentaje_aso = ro_porcentaje
            from   ca_rubro_op
            where  ro_operacion         = @i_operacionca   
            and    ro_concepto_asociado = @w_ro_concepto

            if (@@rowcount = 0) and (@w_porcentaje_aso > 0) and (@w_asociado is not null)
            begin ---ASOCIADO
               select @w_valor_asociado = round((@w_valor_rubro * @w_porcentaje_aso / 100.0), @i_num_dec)

               if @w_di_estado = 1
                  select @w_valor_no_vig = @w_valor_asociado
               else
                  select @w_valor_no_vig = 0    
                  
                  
               update ca_amortizacion
               set    am_cuota     = case 
                                       when @w_valor_asociado > am_pagado then @w_valor_asociado
                                        else am_cuota
                                     end,
                      am_acumulado =  case
                                        when @w_valor_no_vig > am_pagado then @w_valor_no_vig
                                       else am_acumulado
                                     end
               where  am_operacion = @i_operacionca
               and    am_dividendo = @w_dividendo
               and    am_concepto  = @w_asociado

               if @@error <> 0
                  return 724027
            end   ---ASOCIADO
         end --- VALOR > 0
      end
          
      fetch cur_RPRubros
      into  @w_ro_concepto, 
            @w_ro_tipo_rubro, 
            @w_ro_porcentaje
   end ---FIN RUBROS

   close cur_RPRubros
   deallocate cur_RPRubros
                 
   fetch Cur_RPInterno
   into  @w_dividendo,
         @w_operacion,
         @w_fecha_ini,
         @w_fecha_ven,
         @w_di_dias_cuota,
         @w_di_estado
end ---Cursor

close Cur_RPInterno
deallocate Cur_RPInterno

return 0
go