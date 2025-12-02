/************************************************************************/
/* Archivo               :    difdia360R.sp                             */
/* Stored procedure      :    sp_dias_cuota_360_reporte                 */
/* Base de datos         :    cob_cartera                               */
/* Producto              :    Cartera                                   */
/* Disenado por          :    Elcira Pelaez                             */
/* Fecha de escritura    :    marzo-2005                                */
/************************************************************************/
/*                      IMPORTANTE                                      */
/* Este programa es parte de los paquetes bancarios propiedad de        */
/* "MACOSA"                                                             */
/* Su uso no autorizado queda expresamente prohibido asi como           */
/* cualquier alteracion o agregado hecho por alguno de sus              */
/* usuarios sin el debido consentimiento por escrito de la              */
/* Presidencia Ejecutiva de MACOSA o su representante.                  */
/************************************************************************/  
/*                        PROPOSITO                                     */
/*    Determina el numero de dias a aplicar para el interes:360,365,366 */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dias_cuota_360_reporte')
 drop proc sp_dias_cuota_360_reporte
go
create proc sp_dias_cuota_360_reporte
   @i_fecha_ini  datetime = null,
   @i_fecha_fin  datetime = null,
   @i_dia_fijo   int,
   @o_dias       int      = null out
as
declare
  @w_dia1    int,
  @w_dia2    int,
  @w_mes1    int,
  @w_mes2    int,
  @w_fase    int
  
begin
   select @w_mes1 = datepart(mm, @i_fecha_ini),
          @w_mes2 = datepart(mm, @i_fecha_fin),
          @w_dia1 = datepart(dd, @i_fecha_ini),
          @w_dia2 = datepart(dd, @i_fecha_fin)
   
   if @w_mes1 = 2 and @i_dia_fijo > @w_dia1
   begin
      select @w_fase = @i_dia_fijo - @w_dia1
   end
   else
      select @w_fase = 0
   
   -- NORMALIZACION DE DIAS A 30
   --  FECHA_INI
   if @w_mes1 != 2
   begin
     if @w_dia1 = 31
         select @w_dia1 = 30
   end
   
   -- FECHA_FIN
   if @w_mes2 != 2
   begin
      if @w_dia2 = 31
         select @w_dia2 = 30
   end
   else
   begin -- TERMINA EN FEBRERO
      if @w_dia2 >= 28 and @w_dia1 > 28
         select @w_dia2 = @w_dia1
   end
   -- CALCULO CON BASE 30/360
   select @o_dias =  360 * (datepart(yy, @i_fecha_fin) -datepart(yy, @i_fecha_ini))
                 + 30 * (@w_mes2 - @w_mes1)
                 + (@w_dia2 - @w_dia1) - @w_fase
end
go
