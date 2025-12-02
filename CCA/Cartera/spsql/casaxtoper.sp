/************************************************************************/
/*	Archivo:		casaxtoper.sp				*/
/*	Stored procedure:	sp_saldos_x_toperacion	        	*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Ricardo Reyes Beltr n			*/
/*	Fecha de escritura:	May. 2002 				*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldos_x_toperacion')
	drop proc sp_saldos_x_toperacion
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_saldos_x_toperacion
	@i_fecha_ini	datetime,
	@i_fecha_fin	datetime,
	@i_toperacion	varchar(10)
as declare
	@w_op_operacion		int,
	@w_op_cliente		int,
	@w_op_nombre		varchar(50),
	@w_saldo_tot		money,
	@w_saldo_prv		money,
	@w_saldo_imo		money,
	@w_saldo_int		money,
	@w_saldo_cap		money,
	@w_saldo_otr		money,
	@w_en_ced_ruc		varchar(12),
	@w_ts_porcentaje	float,
	@w_ts_porcentaje_nom	float,
	@w_ts_referencial	catalogo,
	@w_sp_name		varchar(30),
	@w_op_banco		cuenta,
	@w_fecha_max_tasa	datetime,
	@w_ts_factor		float,
	@w_sus_front_end	char(1),
	@w_sus_back_end		char(1),
	@w_op_fecha_ini		datetime,
	@w_op_toperacion	catalogo

/* VARIABLES DE TRABAJO */
select
@w_sp_name        	= 'sp_saldos_x_toperacion'

delete ca_saldos_x_toperacion WHERE car_banco >= ''

/* CURSOR CONTROL CADA UNO DE LOS DIVIDENDOS */
declare cursor_operacion cursor for
select  op_operacion,
	op_banco,
	op_toperacion,
	op_cliente,
	op_nombre,
	op_fecha_ini
from ca_operacion
where (charindex (@i_toperacion,op_toperacion) = 1 or @i_toperacion is null)
and op_estado not in (0,3,4,6,98,99)
order by op_toperacion
for read only

open    cursor_operacion 
fetch   cursor_operacion into
	@w_op_operacion,		
	@w_op_banco,
	@w_op_toperacion,
	@w_op_cliente,
	@w_op_nombre,
	@w_op_fecha_ini
 	
while  @@fetch_status = 0 
begin /*WHILE CURSOR DIVIDENDOS*/

   if (@@fetch_status = -1) return 708999

	select 	@w_saldo_int 		= 0,
		@w_saldo_imo 		= 0,
		@w_saldo_cap 		= 0,
		@w_saldo_otr 		= 0,
		@w_saldo_tot 		= 0,
		@w_saldo_prv 		= 0,
		@w_fecha_max_tasa 	= '01/01/1999',
		@w_ts_porcentaje 	= 0,
		@w_ts_referencial 	= '',
		@w_en_ced_ruc 		= '',
		@w_ts_factor		= 0,
		@w_ts_porcentaje_nom	= 0,
		@w_sus_front_end	= '',
		@w_sus_back_end		= ''

		
	select @w_saldo_int = isnull(sum(am_acumulado - am_pagado),0)
        from ca_amortizacion, ca_concepto
	where am_operacion = @w_op_operacion
	and am_concepto = co_concepto
	and co_categoria = 'I'

	select @w_saldo_imo = isnull(sum(am_acumulado - am_pagado),0)
        from ca_amortizacion, ca_concepto
	where am_operacion = @w_op_operacion
	and am_concepto = co_concepto
	and co_categoria = 'M'

	select @w_saldo_cap = isnull(sum(am_cuota + am_gracia - am_pagado),0)
        from ca_amortizacion, ca_concepto
	where am_operacion = @w_op_operacion
	and am_concepto = co_concepto
	and co_categoria = 'C'

	select @w_saldo_otr = isnull(sum(am_cuota + am_gracia - am_pagado),0)
        from ca_amortizacion, ca_concepto
	where am_operacion = @w_op_operacion
	and am_concepto = co_concepto
	and co_categoria not in ('C','I','M')

	select @w_saldo_tot = @w_saldo_int + @w_saldo_imo + @w_saldo_cap + @w_saldo_otr 

	select @w_saldo_prv = isnull(sum(dtr_monto_mn),0)
	from ca_transaccion, ca_det_trn
	where tr_secuencial = dtr_secuencial
	and tr_operacion = dtr_operacion
	and tr_operacion = @w_op_operacion
	and tr_tran in ('PRV','AMO')
	and tr_estado = 'CON'
	and tr_fecha_mov >= @i_fecha_ini
	and tr_fecha_mov <= @i_fecha_fin

	select @w_fecha_max_tasa = max(ts_fecha)
	from ca_tasas, ca_concepto
	where ts_operacion = @w_op_operacion
	and ts_concepto = co_concepto
	and co_categoria = 'I'

	if @w_fecha_max_tasa = '01/01/1999'
	begin
		select @w_ts_porcentaje = ro_porcentaje_efa,
		       @w_ts_referencial = ro_referencial,
		       @w_ts_factor = ro_factor,
		       @w_ts_porcentaje_nom = ro_porcentaje
		from ca_rubro_op, ca_concepto
		where ro_operacion = @w_op_operacion
		and ro_concepto = co_concepto
		and co_categoria = 'I'
	end
	else
	begin
		select @w_ts_porcentaje = ts_porcentaje_efa,
		       @w_ts_referencial = ts_referencial,
		       @w_ts_factor = ts_factor,
		       @w_ts_porcentaje_nom = ts_porcentaje
		from ca_tasas, ca_concepto
		where ts_operacion = @w_op_operacion
		and ts_fecha = @w_fecha_max_tasa 
		and ts_concepto = co_concepto
		and co_categoria = 'I'
	end

	select @w_sus_front_end	= convert(varchar(1),op_estado)
	from ca_operacion
	where op_operacion = @w_op_operacion
	and op_estado = 9

	select	@w_sus_back_end	= convert(varchar(1),am_estado)
	from ca_amortizacion
	where am_operacion = @w_op_operacion
	and am_estado = 9

	select @w_en_ced_ruc = en_ced_ruc
	from cobis..cl_ente
	where en_ente = @w_op_cliente
	set transaction isolation level read uncommitted

	insert into ca_saldos_x_toperacion values (
	ltrim(@w_op_nombre), 	@w_en_ced_ruc, 		@w_op_banco,		@w_op_toperacion,
	@w_ts_porcentaje, 	@w_ts_porcentaje_nom,	@w_ts_factor,		@w_ts_referencial,	
	@w_saldo_prv,		@w_saldo_tot,		@w_sus_front_end,	@w_sus_back_end,	
	@w_op_fecha_ini	)	

   fetch   cursor_operacion into
	@w_op_operacion,		
	@w_op_banco,
	@w_op_toperacion,
	@w_op_cliente,
	@w_op_nombre,
	@w_op_fecha_ini
  
end /*WHILE CURSOR DIVIDENDOS*/
close cursor_operacion 
deallocate cursor_operacion 


return 0

go
