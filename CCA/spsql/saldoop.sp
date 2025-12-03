/************************************************************************/
/*   Archivo:              saldoop.sp                                   */
/*   Stored procedure:     sp_pago_renovacion                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   Junio 2006                                   */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Calcula los saldos acumulados de una obligación                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldo_operacion')
   drop proc sp_saldo_operacion
go

create proc sp_saldo_operacion (
       @i_operacion      int,           -- NUMERO DE LA OBLIGACION QUE SE RENUEVA (OBLIGACION ANTERIOR)
       @i_dividendo      smallint = 0
)
as
declare
   @w_op_moneda            smallint,
   @w_op_fecha_ult_proceso datetime,
   @w_cotizacion           float
begin
   delete ca_saldo_operacion_tmp
   where  sot_operacion = @i_operacion
   
   select @w_op_fecha_ult_proceso = op_fecha_ult_proceso,
          @w_op_moneda            = op_moneda
   from   ca_operacion
   where  op_operacion = @i_operacion
   
   if @w_op_moneda = 0
      select @w_cotizacion = 1
   else
      exec sp_buscar_cotizacion
           @i_moneda = @w_op_moneda,
           @i_fecha  = @w_op_fecha_ult_proceso,
           @o_cotizacion = @w_cotizacion OUT
   
   insert into ca_saldo_operacion_tmp
         (sot_operacion,         sot_estado_dividendo,            sot_concepto,
          sot_estado_concepto,   sot_saldo_acumulado,             sot_saldo_mn)
   select @i_operacion,          di_estado,                       am_concepto,
          am_estado,             sum(am_acumulado  + am_gracia - am_pagado),   0
   from   ca_rubro_op, ca_dividendo, ca_concepto, ca_amortizacion
   where  ro_operacion = @i_operacion
   and    co_concepto  = ro_concepto
   
   and    di_operacion = ro_operacion
   and    (di_dividendo = @i_dividendo or @i_dividendo = 0)
   and    am_operacion = ro_operacion
   and    am_concepto  = ro_concepto
   and    (       (ro_tipo_rubro in ('I', 'C', 'M') and di_estado in (2, 1, 0) )
           or (not (ro_tipo_rubro in ('I', 'C', 'M'))
               and (   (ro_fpago = 'M' and di_estado in (2, 1, 0) )
                    or (ro_fpago = 'A' and di_estado = 2)
                    or (ro_fpago = 'P' and di_estado in (2, 1))
                   )
               )
          )
   and   (
          (    am_dividendo = di_dividendo + charindex (ro_fpago, 'A')
           and not(co_categoria in ('S', 'A') and am_secuencia > 1)
          )
          or (co_categoria in ('S', 'A') and am_secuencia > 1 and am_dividendo = di_dividendo)
         )
   group by di_estado, am_concepto, am_estado
   
   if @@error != 0
   begin
      return 721901
   end
   
   update ca_saldo_operacion_tmp
   set    sot_saldo_mn = round(sot_saldo_acumulado * @w_cotizacion,0)
   where  sot_operacion = @i_operacion
   
   return 0
end
go
