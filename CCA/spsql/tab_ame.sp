/*tab_am.sp**************************************************************/
/*    Archivo:                tab_ame.sp                                */
/*    Stored Procedure:       sp_cat                                    */
/*    Base de datos:          cob_cartera                               */
/*    Producto:               Cartera                                   */
/*    Disenado por:           Tania Baidal                              */
/*    Fecha de escritura:     29/NOV/2018                               */
/************************************************************************/
/*                            IMPORTANTE                                */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "MACOSA" del Ecuador.                                             */
/*    Su uso no autorizado queda expresamente prohibido asi como        */
/*    cualquier alteracion o agregado hecho por alguno de sus           */
/*    usuarios sin el debido consentimiento por escrito de la           */
/*    Presidencia Ejecutiva de MACOSA o su representante.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*    Generacion de tabla americana a partir de una operacion existente */
/************************************************************************/
/*                             MODIFICACION                             */
/*    FECHA                 AUTOR                 RAZON                 */
/*    30/Nov/2018           TBA                   Emision Inicial       */
/************************************************************************/
use cob_cartera
go
 
if exists (select * from sysobjects where name = 'sp_crea_tab_americana')
   drop proc sp_crea_tab_americana
go
 
create proc sp_crea_tab_americana
   @i_operacionca     int,
   @o_operacionca     int = null out

as
declare 
@w_dividendo          int,
@w_monto_utilizacion  money,
@w_tasa_nominal_anual float,
@w_min_interes        float,
@w_num_dividendos     int,
@w_operacionca        int,
@w_operacion_ant      int,
@w_fecha_ini          datetime,
@w_di_fecha_ini       datetime,
@w_di_fecha_ven       datetime,
@w_tperiodicidad      catalogo,
@w_periodicidad       int,
@w_tplazo             catalogo,
@w_plazo              int,
@w_monto              money,
@w_interes            money

select * 
into #operacion_tmp
from ca_operacion
where op_operacion = @i_operacionca

select *
into #rubro_op_tmp
from ca_rubro_op
where ro_operacion = @i_operacionca

select *
into #dividendo_tmp
from ca_dividendo
where 1 = 2

select * 
into #amortizacion_tmp
from ca_amortizacion
where 1 = 2

select 
@w_tperiodicidad      = op_tdividendo,
@w_periodicidad       = op_periodo_int,
@w_tplazo             = op_tplazo,
@w_plazo              = op_plazo,
@w_monto              = op_monto_aprobado,
@w_fecha_ini          = op_fecha_ini
from #operacion_tmp

select 
@w_periodicidad = @w_periodicidad * td_factor 
from cob_cartera..ca_tdividendo
where td_tdividendo = @w_tperiodicidad

select 
@w_plazo = @w_plazo * td_factor 
from cob_cartera..ca_tdividendo
where td_tdividendo = @w_tplazo

select @w_num_dividendos = @w_plazo / @w_periodicidad

select 
@w_tasa_nominal_anual = ro_porcentaje
from #rubro_op_tmp
where ro_operacion = @i_operacionca
and   ro_concepto  = 'INT'

select @w_interes = @w_monto * (@w_tasa_nominal_anual/100) / 364 * @w_periodicidad

select @w_dividendo = 0, @w_di_fecha_ven = @w_fecha_ini

select 'borrar', @w_num_dividendos

while (@w_dividendo < @w_num_dividendos)
begin
    select @w_dividendo = @w_dividendo + 1
	
    select @w_di_fecha_ini = @w_di_fecha_ven
    select @w_di_fecha_ven = dateadd(day,@w_periodicidad, @w_di_fecha_ven)

    insert into #dividendo_tmp (
	di_operacion,    di_dividendo,   di_fecha_ini,
	di_fecha_ven,    di_de_capital,  di_de_interes, 
	di_gracia,       di_gracia_disp, di_estado,
	di_dias_cuota,   di_intento,     di_prorroga,
	di_fecha_can)
	select 
	@i_operacionca,  @w_dividendo,   @w_di_fecha_ini,
	@w_di_fecha_ven, 'S',            'S', 
	0,               0,              2,
	7,               0,              'N',
	null
   
    insert into #amortizacion_tmp (
	am_operacion,   am_dividendo, am_concepto, 
	am_estado,      am_periodo,   am_cuota, 
	am_gracia,      am_pagado,    am_acumulado, 
	am_secuencia)
    select
	@i_operacionca, @w_dividendo, 'INT',
	1,              0,            @w_interes,
	0.00,           0.00,         @w_interes,
	1

	insert into #amortizacion_tmp (
	am_operacion,   am_dividendo, am_concepto, 
	am_estado,      am_periodo,   am_cuota, 
	am_gracia,      am_pagado,    am_acumulado, 
	am_secuencia)
    select
	@i_operacionca, @w_dividendo, 'CAP',
	1,              0,            case when @w_dividendo = @w_num_dividendos then @w_monto else 0.00 end,
	0.00,           0.00,         0.00,
	1

    
end

select @w_operacionca = -1 * @i_operacionca

delete from ca_operacion    where op_operacion = @w_operacionca
delete from ca_rubro_op     where ro_operacion = @w_operacionca
delete from ca_dividendo    where di_operacion = @w_operacionca
delete from ca_amortizacion where am_operacion = @w_operacionca


update #operacion_tmp    set op_operacion = @w_operacionca, op_banco = @w_operacionca, op_monto = op_monto_aprobado
update #rubro_op_tmp     set ro_operacion = @w_operacionca
update #dividendo_tmp    set di_operacion = @w_operacionca
update #amortizacion_tmp set am_operacion = @w_operacionca

update #rubro_op_tmp     set ro_valor = 0 where  ro_fpago = 'L'


insert into cob_cartera..ca_operacion    select * from #operacion_tmp
insert into cob_cartera..ca_rubro_op     select * from #rubro_op_tmp
insert into cob_cartera..ca_dividendo    select * from #dividendo_tmp
insert into cob_cartera..ca_amortizacion select * from #amortizacion_tmp


select @o_operacionca = @w_operacionca
return 0

go
