/*************************************************************************/
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Archivo:                recalcINT_TP.sp                          */
/*      Procedimiento:          sp_recalc_int_Tasa_Ponderada             */
/*      Disenado por:           ELcira Pelaez                            */
/*      Fecha de escritura:     AGO.2014                                 */
/*************************************************************************/
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      "MACOSA".                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de  us          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de MACOSA o su representante.              */
/*                              PROPOSITO                                */
/*     Recalcula el INT con la tasa ponderada PRoyecto BANCAMIA          */
/*                              CAMBIOS                                  */
/*      FECHA         AUTOR            CAMBIOS                           */
/*************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_recalc_int_Tasa_Ponderada')
   drop proc sp_recalc_int_Tasa_Ponderada
go

create proc sp_recalc_int_Tasa_Ponderada
   @i_operacionca          int,
   @i_num_dec              tinyint = 0,
   @i_concepto_cap         catalogo = 'CAP'
as
declare
   @w_error                int,
   @w_tasa_equivalente     float,
   @w_ro_porcentaje_efa    float,
   @w_dividendo            smallint,
   @w_cap                  money,
   @w_di_num_dias          smallint,
   @w_int                  money,
   @w_dias_anio            smallint,
   @w_fpago                char(1),
   @w_num_dec_tapl         tinyint

       

-- CALCULAR EL PORCENTAJE DE INTERES TOTAL
select @w_ro_porcentaje_efa = ro_porcentaje_efa,
       @w_fpago             = ro_fpago,
       @w_num_dec_tapl      = ro_num_dec
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_tipo_rubro = 'I'

if @w_ro_porcentaje_efa < 0
begin
   --PRINT 'recalcINT_TP.sp Error tasa con valor no valido @w_ro_porcentaje_efa ' +   cast ( @w_ro_porcentaje_efa as varchar)
   return 710004
end

if @w_fpago = 'P' select @w_fpago = 'V'

select 
@w_dias_anio        = op_dias_anio
from ca_operacion
where op_operacion = @i_operacionca

declare cursor_dividendo_TP cursor for select 
di_dividendo,
di_dias_cuota
from   ca_dividendo
where  di_operacion   = @i_operacionca
order  by di_dividendo
    
for read only

open cursor_dividendo_TP

fetch cursor_dividendo_TP 
into  @w_dividendo,
      @w_di_num_dias

while   @@fetch_status = 0  
begin 
   if (@@fetch_status = -1) 
   return 710004
   
   select @w_cap = 0
   select @w_cap = sum(am_cuota)
   from ca_amortizacion
   where am_operacion = @i_operacionca
   and am_dividendo >= @w_dividendo
   and am_concepto  = 'CAP'

      exec @w_error =  sp_conversion_tasas_int
      @i_dias_anio      = @w_dias_anio,
      @i_periodo_o      = 'A',
      @i_modalidad_o    = 'V',
      @i_num_periodo_o  = 1,
      @i_tasa_o         = @w_ro_porcentaje_efa,
      @i_periodo_d      = 'D',
      @i_modalidad_d    = @w_fpago, 
      @i_num_periodo_d  = @w_di_num_dias,
      @i_num_dec        = @w_num_dec_tapl,
      @o_tasa_d         = @w_tasa_equivalente output
      
   
   select @w_int = (@w_tasa_equivalente * @w_cap) / (100 * 360) * @w_di_num_dias
   select @w_int = round(@w_int,@i_num_dec)
   ---PRINT ' @w_cap ' + cast ( @w_cap as varchar) + ' @w_dividendo ' + cast (@w_dividendo as varchar) +  ' @w_di_num_dias ' + cast ( @w_di_num_dias as varchar) + ' INT ' + cast (@w_int  as varchar)
   
  update ca_amortizacion
   set am_cuota = @w_int
   from ca_amortizacion,
        ca_dividendo
   where am_operacion  = @i_operacionca
   and   am_operacion  = di_operacion
   and   am_dividendo  =  di_dividendo
   and   di_de_interes = 'S'
   and   am_dividendo = @w_dividendo
   and   am_concepto  = 'INT'
   if @@error <> 0 
   begin
     --PRINT 'recalcINT_TP.sp Error actualizando INT con tasa ponderada'
     return 724401
   end
  
   
   fetch cursor_dividendo_TP 
   into  @w_dividendo,
         @w_di_num_dias
   
end 

close cursor_dividendo_TP
deallocate cursor_dividendo_TP


return 0

go

