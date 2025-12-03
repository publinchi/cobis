/************************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Archivo:		saldocca.sp				*/
/*	Procedimiento:		sp_saldocca        			*/
/*      Disenado por:           Fabian de la Torre	                */
/*      Fecha de escritura:     Febrero 1999                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Calcula el valor maximo a pagar por un credito tomando en cuenta*/
/*      la modalidad de pago.						*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldocca')
   drop proc sp_saldocca
go

create proc sp_saldocca
@i_fecha_proceso	datetime,
@i_operacionca		int,
@i_tipo_cobro		char(1)   = 'A',
@i_num_dec		smallint,
@i_tasa_prepago         float     = 0,
@i_tipo                 char(1)   = null, ---EPB:nov-07-2001 para DD
@o_monto   		money     = NULL out
as

declare
@w_return		int,
@w_est_novigente        int,
@w_est_vigente          int,
@w_est_cancelado        int,
@w_di_estado            int,
@w_di_fecha_ven         datetime,
@w_di_fecha_ini         datetime,
@w_dividendo            int,
@w_monto                money,
@w_monto_proy           money,
@w_monto_ant            money,
@w_anticipado           money,
@w_vencido              money,
@w_div_vigente          int,
@w_div_cancelado        int,
@w_fpago                char(1),
@w_monto_vigente        money,
@w_dias                 int

/* INICIALIZACION DE VARIABLES */
select 
@w_est_novigente   = 0,
@w_est_vigente     = 1,
@w_est_cancelado   = 3

select @w_fpago = ro_fpago
       from ca_rubro_op
where ro_operacion = @i_operacionca
  and ro_tipo_rubro = 'I'

select @w_div_cancelado = isnull(max(di_dividendo),0)
from ca_dividendo
where di_operacion = @i_operacionca
and   di_estado    = @w_est_cancelado

select @w_div_vigente = di_dividendo,
       @w_di_fecha_ini = di_fecha_ini
from ca_dividendo
where di_operacion = @i_operacionca
and   di_estado    = @w_est_vigente

if @@rowcount = 0 begin
   select @w_fpago = 'P'
   select @w_div_vigente = max(di_dividendo) + 1 
          from ca_dividendo
    where di_operacion = @i_operacionca
      and   di_estado    = @w_est_vigente
end


/* SALDO DEL CREDITO EN MODALIDAD PROYECTADA */
if @i_tipo_cobro = 'P' begin

   select @w_monto = 
   isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from ca_amortizacion
   where am_operacion = @i_operacionca
   and   am_dividendo > @w_div_cancelado

end

if @w_fpago = 'A' and @i_tipo <> 'D'  begin
     exec @w_return = sp_saldo_op_anticipado 
          @i_operacionca = @i_operacionca,
          @i_tipo_cobro  = @i_tipo_cobro, -- P,A,E
          @o_saldo_op    = @o_monto out

     return @w_return

end

/* SALDO DEL CREDITO EN MODALIDAD ACUMULADA */
if @i_tipo_cobro = 'A' begin

     select @w_monto =
       isnull(sum(round(am_acumulado+am_gracia-am_pagado, @i_num_dec)),0)
       from ca_amortizacion
      where am_operacion = @i_operacionca
        and   am_dividendo > @w_div_cancelado

end

if @i_tipo = 'D'  begin  ---EPB:nov-07-2001 para DD

   select @w_monto = 
   isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from ca_amortizacion
   where am_operacion = @i_operacionca
   and   am_dividendo <> @w_div_cancelado
end 




if @i_tipo_cobro = 'E' begin

   select @w_monto = 0

   select @w_div_vigente = di_dividendo
   from ca_dividendo
   where di_operacion = @i_operacionca
   and   di_estado    = @w_est_vigente

   if @@rowcount = 0 select @w_div_vigente = 99999

   /* CURSOR POR DIVIDENDOS **/
   declare dividendos cursor for select
   di_dividendo, di_fecha_ini, di_fecha_ven, di_estado
   from ca_dividendo
   where di_operacion  = @i_operacionca
   and   di_dividendo >= @w_div_vigente
   order by di_dividendo desc
   for read only

   open dividendos

   fetch dividendos into 
   @w_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, @w_di_estado

   while @@fetch_status = 0 begin

      if (@@fetch_status = -1) return 708899

      select @w_vencido =
      isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op
      where ro_operacion = @i_operacionca
      and   ro_operacion = am_operacion
      and   ro_concepto  = am_concepto
      and   am_dividendo = @w_dividendo
      and   ro_fpago    <> 'A'

      select @w_anticipado =
      isnull(sum(am_cuota + am_gracia - am_pagado ),0)
      from ca_amortizacion, ca_rubro_op
      where ro_operacion = @i_operacionca
      and   ro_operacion = am_operacion
      and   ro_concepto  = am_concepto
      and   am_dividendo = @w_dividendo + 1
      and   ro_fpago     = 'A'

      select @w_monto = @w_monto + @w_anticipado + @w_vencido

      if @w_di_estado = @w_est_novigente
         select @w_monto = @w_monto / power((1.0 + @i_tasa_prepago),
         convert( float,(datediff(dd,@w_di_fecha_ini,@w_di_fecha_ven))))

      if @w_di_estado = @w_est_vigente
         select @w_monto = @w_monto / power((1.0 + @i_tasa_prepago),
         convert( float,(datediff(dd,@i_fecha_proceso,@w_di_fecha_ven))))

      fetch dividendos into
      @w_dividendo, @w_di_fecha_ini, @w_di_fecha_ven, @w_di_estado

   end /** CURSOR DIVIDENDOS **/
   close dividendos
   deallocate dividendos

   select @w_vencido =
   isnull(sum(am_cuota + am_gracia - am_pagado ),0)
   from ca_amortizacion
   where am_operacion = @i_operacionca
   and   am_dividendo > @w_div_cancelado
   and   am_dividendo < @w_div_vigente


   select @w_monto = @w_monto + @w_vencido


end

select @o_monto = round(isnull(@w_monto,0),@i_num_dec)

return 0
go
     

