/************************************************************************/
/*      Archivo:                valfutur.sp                             */
/*      Stored procedure:       sp_valor_futuro                         */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Rodrigo Garces                          */
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
/*      Procedimiento que realiza el calculo del valor futuro           */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valor_futuro')
   drop proc sp_valor_futuro
go

create proc sp_valor_futuro
@i_operacionca	int      = null,
@i_dividendo    smallint = null,
@i_fecha_pago	datetime = null,
@i_monto	money    = null,
@o_monto_futuro	money    = null out
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
@w_capital_adicional money,
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

/** CONSULTA DE LA TASA DE INTERES ACTUAL DE LA OPERACION **/
select @w_tasa_interes = sum(ro_porcentaje)
from ca_rubro_op
where ro_operacion = @i_operacionca
and   ro_fpago    in ('P','A')
and   ro_tipo_rubro= 'I'

/* CAPITAL ADICIONAL */
select @w_capital_adicional = sum(am_cuota+am_gracia-am_pagado)
from   ca_amortizacion,ca_rubro_op
where  am_operacion = @i_operacionca
and    am_dividendo = @i_dividendo  
and    ro_operacion = @i_operacionca
and    ro_concepto  = am_concepto
and    ro_tipo_rubro= 'C'

select @i_monto = @i_monto + @w_capital_adicional

/** CURSOR DE DIVIDENDO **/
declare dividendos cursor for
select di_dividendo,di_fecha_ini, di_fecha_ven
from ca_dividendo
where di_operacion = @i_operacionca
and di_dividendo  <= @i_dividendo   
and di_fecha_ven  >= @i_fecha_pago
order by di_dividendo 
for read only
   
open dividendos

fetch dividendos into @w_dividendo,@w_fecha_ini,@w_fecha_fin

while @@fetch_status = 0 
begin
   if @@fetch_status = -1 return 710004

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
   select @i_monto = @i_monto * @w_factor
   fetch dividendos into @w_dividendo,@w_fecha_ini,@w_fecha_fin
end
close dividendos
deallocate dividendos  

select @o_monto_futuro = isnull(@i_monto-@w_capital_adicional,0.00)

return 0
go

