/************************************************************************/
/*      Archivo:                salpropo.sp                             */
/*      Stored procedure:       sp_saldo_prom_ponderado                 */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Xavier Saquicela                        */
/*      Fecha de escritura:     Jun 1999                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Calculo y actualizacion del saldo promedio ponderado de una     */
/*	operacion a la fecha de proceso dada			        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldo_prom_ponderado')
    drop proc sp_saldo_prom_ponderado
go


create proc sp_saldo_prom_ponderado (
   @s_ssn              int          = null,
   @s_sesn             int          = null,
   @s_srv              varchar (30) = null,
   @s_lsrv             varchar (30) = null,
   @s_user             login        = null,
   @s_date             datetime     = null,
   @s_ofi              smallint     = null,
   @s_rol              tinyint      = null,
   @s_org              char(1)      = null,
   @s_term             varchar (30) = null,
   @i_operacionca        int          = null,
   @i_fecha_proceso    datetime     = null
)
as

declare
   @w_return               int,          /* valor que retorna */
   @w_sp_name              varchar(32),  
   @w_error                int,
   @w_banco		   cuenta,
   @w_base_calculo         char(1),
   @w_fecha_desembolso     datetime,
   @w_monto_des            money,
   @w_fecha_fin            datetime,
   @w_saldo		   money,
   @w_pagado		   money,
   @w_fecha_pag		   datetime,
   @w_tdividendo	   catalogo,
   @w_periodo_int	   smallint,
   @w_di_fecha_ini	   datetime,
   @w_di_fecha_fin	   datetime,
   @w_di_dividendo	   smallint,
   @w_dias_interes	   int,
   @w_di_num_dias	   money, --int,
   @w_dia_proceso	   tinyint,
   @w_mes_proceso	   tinyint,
   @w_anio_proceso	   smallint,
   @w_mes_desem		   tinyint,
   @w_anio_desem	   smallint,
   @w_dias_desem	   money, --tinyint,
   @w_dias_pago		   money, --tinyint,
   @w_total_pagos	   money,
   @w_saldo_prom_pon	   money,
   @w_secuencial_ing	   int,
   @w_est_cancelado	   tinyint

select @w_sp_name = 'sp_saldo_prom_ponderado',
       @w_est_cancelado = 3

select @w_dia_proceso = datepart(dd, @i_fecha_proceso)
select @w_mes_proceso = datepart(mm, @i_fecha_proceso)
select @w_anio_proceso = datepart(yy, @i_fecha_proceso)

select @w_base_calculo = op_base_calculo,
       @w_fecha_desembolso = op_fecha_liq,
       @w_monto_des = op_monto,
       @w_fecha_fin = op_fecha_fin,
       @w_tdividendo = op_tdividendo,
       @w_periodo_int = op_periodo_int,
       @w_banco   = op_banco
from ca_operacion
where op_operacion = @i_operacionca

select @w_mes_desem = datepart(mm, @w_fecha_desembolso)
select @w_anio_desem = datepart(yy, @w_fecha_desembolso)

select @w_saldo = sum(am_acumulado - am_pagado + am_gracia)
from ca_amortizacion, ca_dividendo, ca_rubro_op
where di_operacion = @i_operacionca
and   am_operacion = @i_operacionca
and   ro_operacion = @i_operacionca
and   di_estado <> @w_est_cancelado
and   am_dividendo = di_dividendo
and   ro_tipo_rubro = 'C'
and   ro_fpago = 'P'   --PERIODICO AL VENCIMIENTO
and   am_concepto = ro_concepto

if (@w_mes_proceso = @w_mes_desem) and (@w_anio_proceso = @w_anio_desem)
        select @w_dias_desem = datepart(dd, @w_fecha_desembolso)
else
        select @w_dias_desem = 0

select @w_total_pagos = 0,
       @w_secuencial_ing = 0

/*QUE SUCEDE EN EL CASO DE QUE SE HALLAN DADO MAS DE UN PAGO EN ESTE MES */
while 1 = 1
begin
set rowcount 1

select @w_pagado = sum(abd_monto_mop),
       @w_fecha_pag = ab_fecha_pag,
       @w_secuencial_ing = ab_secuencial_ing
from ca_abono, ca_abono_det
where ab_operacion = @i_operacionca
and   ab_estado = 'A'
and   datepart(mm, ab_fecha_pag) = datepart(mm, @i_fecha_proceso)
and   ab_secuencial_ing > @w_secuencial_ing
and   abd_secuencial_ing = ab_secuencial_ing
and   abd_operacion      = ab_operacion
group by ab_secuencial_ing, ab_fecha_pag
order by ab_secuencial_ing

if @@rowcount = 0
	break

select @w_pagado = isnull(@w_pagado, 0)
select @w_dias_pago = isnull(datepart(dd, @w_fecha_pag), 0)

select @w_total_pagos = @w_total_pagos + (@w_pagado * (@w_dias_pago - @w_dias_desem))

end

set rowcount 0

select @w_dias_interes = td_factor * @w_periodo_int
from ca_tdividendo
where td_tdividendo = @w_tdividendo

select @w_di_fecha_ini = di_fecha_ini,
       @w_di_fecha_fin = di_fecha_ven,
       @w_di_dividendo = di_dividendo
from ca_dividendo
where di_fecha_ini <= @i_fecha_proceso
and   di_fecha_ven >= @i_fecha_proceso
and   di_operacion = @i_operacionca

if @w_base_calculo = 'E'
   select @w_di_num_dias = 30
   /*exec sp_calculo_30_360
	@i_fecha_ini = @w_di_fecha_ini,
	@i_fecha_ven = @w_di_fecha_fin,
	@i_dias_interes = @w_dias_interes,
	@o_dias_int	= @w_di_num_dias out*/
else
   if @w_base_calculo = 'R'
   begin
	select @w_di_num_dias = datepart(dd,
                                 dateadd(dd, -1,
                                  dateadd(mm, 1,
		                   dateadd(dd, (@w_dia_proceso -1) * -1, 
                                                        @i_fecha_proceso))))
   end

--print 'saldo = %1!', @w_saldo
--print 'num dias = %1!', @w_di_num_dias
--print 'dias desem = %1!', @w_dias_desem
--print 'total pagos = %1!', @w_total_pagos
select @w_saldo_prom_pon = (((@w_saldo * (@w_di_num_dias - @w_dias_desem)) + @w_total_pagos) / @w_di_num_dias)

update ca_operacion
set op_sal_pro_pon = @w_saldo_prom_pon
where op_operacion = @i_operacionca

if @@error != 0 begin
     select @w_error = 710142
     goto ERROR
end

return 0

ERROR:
   exec sp_errorlog 
	@i_fecha = @s_date,
   	@i_error = @w_error, 
	@i_usuario=@s_user,
   	@i_tran=7999,
	@i_tran_name=@w_sp_name,
   	@i_cuenta= @w_banco,
	@i_descripcion = 'Error al actualizar el saldo promedio ponderado',
	@i_rollback = 'N'

   return 0

go

