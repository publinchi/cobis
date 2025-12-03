/************************************************************************/
/*   Archivo:             dias_causar_360.sp                            */
/*   Stored procedure:    sp_dias_causar_360                            */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Fabian G. Quintero                            */
/*   Fecha de escritura:  Jul-2007                                      */
/************************************************************************/
/*                            IMPORTANTE                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                             PROPOSITO                                */
/*   Este sp calcula el numero de dias de un rango de fechas enviado    */
/*   como parametro                                                     */
/************************************************************************/  
/*                            MODIFICACIONES                            */
/*   FECHA              AUTOR                  RAZON                    */
/*                                                                      */
/************************************************************************/  

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_dias_causar_360')
   drop proc sp_dias_causar_360
go

create proc sp_dias_causar_360 (
   @i_fecha_ini  datetime, -- ESTA FECHA SE INCLUYE EN LA CAUSACION
   @i_fecha_fin  datetime, -- ESTA NO SE INCLUYE EN LA CAUSACION
   @o_dias       int      OUT
)
as
declare
  @w_dia1 int,
  @w_dia2 int,
  @w_mes1 int,
  @w_mes2 int,
  @w      int
begin
   if @i_fecha_ini > @i_fecha_fin
      return 722501
   
   -- FECHA INI ES LA QUE SE INCLUYE EN LA CAUSACION
   if datepart(dd, @i_fecha_ini) = 31 -- ESTE DIA NO ES COMERCIAL, SE PASA AL SIGUIENTE MES
   begin
      select @i_fecha_ini = dateadd(dd, 1, @i_fecha_ini)
   end
   
   if @i_fecha_ini = @i_fecha_fin
   begin
      select @o_dias = 0
      return 0
   end
   

   select @w_mes1 = datepart(mm, @i_fecha_ini),
          @w_mes2 = datepart(mm, @i_fecha_fin),
          @w_dia1 = datepart(dd, @i_fecha_ini),
          @w_dia2 = datepart(dd, @i_fecha_fin)
   
   -- CALCULO CON BASE 30/360
   select @o_dias =  360 * (datepart(yy, @i_fecha_fin) -datepart(yy, @i_fecha_ini))
                    + 30 * (@w_mes2 - @w_mes1)
                    + (@w_dia2 - @w_dia1)
end

go
