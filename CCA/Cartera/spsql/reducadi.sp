/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:                reducadi.sp                             */
/*      Stored procedure:	sp_reduccion_cuota_adicional		*/
/*      Disenado por:           Patricio Narv ez                        */
/*      Fecha de escritura:     08 Febrero de 1999                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".		                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Si el sobrante al ejecutar un pago extraordinario es menor al   */
/*      monto total de cuotas adicionales, se debe reducir el valor de  */
/*      las cuotas adicionales.                                         */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reduccion_cuota_adicional')
   drop proc sp_reduccion_cuota_adicional
go

create proc sp_reduccion_cuota_adicional
@i_operacion         int,         
@i_monto_sobrante    money

as

declare
@w_sp_name               descripcion,
@w_return                int,
@w_cuota                 money,
@w_monto_adicionales     money,
@w_dividendo             smallint,
@w_saldo_capital         money

select 
@w_sp_name  = 'sp_reduccion_cuota_adicional'

/*SALDO DE CAPITAL*/
select @w_saldo_capital = sum(am_cuota+am_gracia-am_pagado)
from ca_amortizacion,ca_rubro_op
where am_operacion  = @i_operacion
and   ro_operacion  = @i_operacion 
and   am_concepto   = ro_concepto
and   ro_tipo_rubro = 'C'

select @w_saldo_capital = @w_saldo_capital - @i_monto_sobrante

declare adicionales cursor for
select  ca_cuota, ca_dividendo
from ca_cuota_adicional
where ca_operacion  = @i_operacion
and   ca_cuota > 0.0                 --CUOTAS ADICIONALES
order by ca_dividendo desc
for read only

open adicionales

fetch adicionales into @w_cuota, @w_dividendo

while (@@fetch_status = 0)
begin 

   select @w_monto_adicionales = sum(ca_cuota)
   from ca_cuota_adicional
   where ca_operacion = @i_operacion

   select @w_monto_adicionales = isnull(@w_monto_adicionales,0)

   /*NO EXISTEN CUOTAS ADICIONALES PARA ESA OPERACION*/
   if @w_monto_adicionales = 0
      break    

   /*EL TOTAL DE LAS CUOTAS ADICIONALES ES INFERIOR AL SALDO DE CAPITAL*/
   if @w_monto_adicionales < @w_saldo_capital
      break

   update  ca_cuota_adicional set 
   ca_cuota = 0
   where ca_operacion = @i_operacion
   and   ca_dividendo = @w_dividendo

   if @@error != 0 return 710002


   fetch adicionales into @w_cuota, @w_dividendo
end

close adicionales
deallocate adicionales

return 0

go
