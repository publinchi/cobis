/************************************************************************/
/*   Archivo:              conscuot.sp                                  */
/*   Stored procedure:     sp_consulta_cuota                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Fabian de la Torre                           */
/*   Fecha de escritura:   Ene. 1998                                    */
/************************************************************************/
/*   IMPORTANTE                                                         */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                           PROPOSITO                                  */
/*   Consulta el valor de una y solo una cuota completa                 */
/************************************************************************/  
/*                           CAMBIOS                                    */
/*   FECHA        AUTOR             CAMBIO                              */
/*   Marzo 2006   Fabian Quintero   Defecto 6230  BAC                   */
/*   junio 2006   Elcira Pelaez     Defecto 6753 BAC ya no lo llama el  */
/*                                  genafopr.sp                         */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_cuota')
   drop proc sp_consulta_cuota
go

create proc sp_consulta_cuota
   @i_operacionca    int,
   @i_moneda         int,
   @i_tipo_cobro     char(1),
   @i_fecha_proceso  datetime,
   @i_en_linea       char(1) = 'S',
   @i_nota_debito    char(1),
   @i_mon_ext        char(1),
   @i_dividendo      int = 0,           ---EPB:Nov-07-2001 para DD
   @i_tipo_op        char(1) = null,    ---EPB:Nov-07-2001 para DD
   @o_monto          money out

as
declare 
   @w_error                 int,
   @w_sp_name               descripcion,
   @w_est_vigente           tinyint,
   @w_est_vencido           tinyint,
   @w_num_dec               tinyint,
   @w_dividendo_min         int,
   @w_dividendo_max         int,
   @w_monto                 money,
   @w_monto_ant             money

--- CARGADO DE VARIABLES DE TRABAJO
select @w_sp_name        = 'sp_consulta_cuota',
       @w_est_vigente    = 1,
       @w_est_vencido    = 2

-- LECTURA DE DECIMALES
exec @w_error = sp_decimales
     @i_moneda       = @i_moneda,
     @o_decimales    = @w_num_dec out

if @w_error != 0
   return @w_error

if @i_tipo_op = 'D'                       --EPB:nov-07-2001
   select @w_dividendo_min = @i_dividendo,
          @w_dividendo_max = @i_dividendo
ELSE
begin
   select @w_dividendo_min = isnull(min(di_dividendo),0)
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and   (di_estado    = @w_est_vencido 
      or ( di_estado = @w_est_vigente  and   di_fecha_ven = @i_fecha_proceso )
          )
   
   select @w_dividendo_max = isnull(max(di_dividendo),0)
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and   (di_estado    = @w_est_vencido
         or ( di_estado = @w_est_vigente and   di_fecha_ven = @i_fecha_proceso )
         )
end

--- PAGOS EN MODALIDAD ACUMULADA 
if @i_tipo_cobro = 'A'
begin 
   if @i_en_linea = 'N' and @i_nota_debito = 'S' and @i_mon_ext = 'S' 
   begin
      select @w_monto = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  am_operacion  = @i_operacionca
      and    ro_operacion  = @i_operacionca
      and    ro_concepto   = am_concepto
      and    ro_fpago     <> 'A'
      and    ro_tipo_rubro <> 'C'
      and    am_dividendo >= @w_dividendo_min
      and    am_dividendo <= @w_dividendo_max
      
      select @w_monto_ant = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = @i_operacionca
      and    ro_operacion  = @i_operacionca
      and    ro_concepto   = am_concepto
      and    ro_fpago      = 'A'
      and    ro_tipo_rubro <> 'C'
      and    am_dividendo >= @w_dividendo_min
      and    am_dividendo <= @w_dividendo_max+1
   end
   ELSE
   begin
      select @w_monto = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  am_operacion  = @i_operacionca
      and    ro_operacion  = @i_operacionca
      and    ro_concepto   = am_concepto
      and    ro_fpago     <> 'A'
      and    am_dividendo >= @w_dividendo_min
      and    am_dividendo <= @w_dividendo_max
      
      select @w_monto_ant = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from  ca_amortizacion,ca_rubro_op
      where am_operacion  = @i_operacionca
      and   ro_operacion  = @i_operacionca
      and   ro_concepto   = am_concepto
      and   ro_fpago      = 'A'
      and   am_dividendo >= @w_dividendo_min
      and   am_dividendo <= @w_dividendo_max + 1
   end
end

--- PAGOS EN MODALIDAD PROYECTADA
if @i_tipo_cobro = 'P' or  @i_tipo_cobro = 'E'
begin
   if @i_en_linea = 'N' and @i_nota_debito = 'S' and @i_mon_ext = 'S'
   begin
      select @w_monto = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  am_operacion  = @i_operacionca
      and    ro_operacion  = @i_operacionca
      and    ro_concepto   = am_concepto
      and    ro_fpago     <> 'A'
      and    ro_tipo_rubro <> 'C'
      and    am_dividendo >= @w_dividendo_min
      and    am_dividendo <= @w_dividendo_max
      
      select @w_monto_ant = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = @i_operacionca
      and    ro_operacion  = @i_operacionca
      and    ro_concepto   = am_concepto
      and    ro_fpago      = 'A'
      and    ro_tipo_rubro <> 'C' 
      and    am_dividendo >= @w_dividendo_min
      and    am_dividendo <= @w_dividendo_max+1
   end
   ELSE
   begin
      select @w_monto = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  am_operacion  = @i_operacionca
      and    ro_operacion  = @i_operacionca
      and    ro_concepto   = am_concepto
      and    ro_fpago     <> 'A'
      and    am_dividendo >= @w_dividendo_min
      and    am_dividendo <= @w_dividendo_max
      
      select @w_monto_ant = isnull(sum(am_cuota + am_gracia - am_pagado),0)
      from   ca_amortizacion,ca_rubro_op
      where  am_operacion  = @i_operacionca
      and    ro_operacion  = @i_operacionca
      and    ro_concepto   = am_concepto
      and    ro_fpago      = 'A'
      and    am_dividendo >= @w_dividendo_min
      and    am_dividendo <= @w_dividendo_max+1
   end
end

--- Consideraciones finales 
select @o_monto = @w_monto + @w_monto_ant

if @o_monto <= 0
   return 710130

return 0
go
