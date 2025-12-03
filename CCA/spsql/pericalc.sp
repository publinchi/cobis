/************************************************************************/
/*	Archivo:		    pericalc.sp                                     */
/*	Stored procedure:	sp_pericalc                                     */
/*	Base de datos:		cob_cartera                                     */
/*	Producto: 		    Cartera                                         */
/*	Disenado por:  		Fabian de la Torre                              */
/*	Fecha de escritura:	Jul. 1997                                       */
/************************************************************************/
/*				IMPORTANTE                                              */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	"MACOSA".                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier alteracion o agregado hecho por alguno de sus             */
/*	usuarios sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*				PROPOSITO                                               */
/*	Genera dividendo adicional donde se acumula todo el monto de        */
/*      capital de los dividendos que quedan fuera del periodo de       */ 
/*      calculo especificado, ademas elimina a todos esos registros     */
/*      de ca_dividendo_tmp y ca_amortizacion_tmp.                      */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pericalc')
	drop proc sp_pericalc
go

create proc sp_pericalc
@i_operacionca                  int,
@i_tplazo                       catalogo,
@i_periodo_cal                  int,
@i_tdividendo                   catalogo,
@i_periodo_cap                  int,
@i_periodo_int                  int
 
as
declare 
@w_sp_name                      descripcion,
@w_return                       int,
@w_error                        int,
@w_dias_op                      int,
@w_dias_di                      int,
@w_dias_paso                    int,
@w_meses_di                     int,
@w_num_dividendos               int,
@w_dividendo                    int,
@w_cont                         int,
@w_dia_fijo                     int,
@w_di_de_cap                    char(1),
@w_di_de_int                    char(1),
@w_est_no_vigente               tinyint,
@w_est_vigente                  tinyint,
@w_di_fecha_ini                 datetime,
@w_di_fecha_ven                 datetime,
@w_prorroga                     char(1)

/* CARGA DE VARIABLES INICIALES */
select @w_sp_name = 'sp_pericalc'

select 
@w_est_no_vigente = 0,
@w_est_vigente    = 1

/* CALCULAR NUMERO DE DIVIDENDOS */
select 
@w_dias_op = 0,
@w_dias_di = 0

select @w_dias_op = @i_periodo_cal * td_factor
from ca_tdividendo
where td_tdividendo = @i_tplazo

if @w_dias_op = 0 begin
   select @w_error = 710007
   goto ERROR
end

select @w_dias_di = @i_periodo_int * td_factor
from ca_tdividendo
where td_tdividendo = @i_tdividendo

if @w_dias_di = 0 begin
   select @w_error = 710007
   goto ERROR
end


if @w_dias_op % @w_dias_di <> 0 begin
   select @w_error = 710008
   PRINT 'pericalc.sp error 710008 @i_periodo_cal' + @i_periodo_cal
   goto ERROR
end

select @w_num_dividendos = @w_dias_op / @w_dias_di

/* BUSCAR FECHA DEL NUEVO DIVIDENDO */
select @w_di_fecha_ven = dit_fecha_ven
from ca_dividendo_tmp
where dit_operacion = @i_operacionca
and   dit_dividendo = @w_num_dividendos

/* BORRAR DIVIDENDOS FUERA DEL PERIODO DE CALCULO */
delete ca_dividendo_tmp
where dit_operacion = @i_operacionca
and   dit_dividendo > @w_num_dividendos

if @@error <> 0 begin
   select @w_error = 710003
   goto ERROR
end

/* INSERTAR DIVIDENDO */
if exists (select 1 from ca_prorroga
           where pr_operacion = @i_operacionca
             and pr_nro_cuota = @w_num_dividendos+1)
   select @w_prorroga = 'S'
else
   select @w_prorroga = 'N'


insert into ca_dividendo_tmp 
(dit_operacion,		dit_dividendo,		dit_fecha_ini,
dit_fecha_ven,		dit_de_capital,		dit_de_interes,
dit_gracia,		    dit_gracia_disp,	dit_estado,
dit_prorroga,		dit_dias_cuota,		dit_intento,
dit_fecha_can)
values (
@i_operacionca,   @w_num_dividendos+1, @w_di_fecha_ven,
@w_di_fecha_ven,  'S',                 'N',
0,                0,                   @w_est_no_vigente, 
@w_prorroga,	  0,                   0,
'01/01/1900')

if @@error <> 0 begin
   select @w_error = 710001
   goto ERROR
end

 
/* INSERTAR NUEVOS REGISTROS EN LA TABLA DE AMORTIZACION */
insert into ca_amortizacion_tmp
(amt_operacion,   amt_dividendo,   amt_concepto,
amt_cuota,        amt_gracia,      amt_pagado,
amt_acumulado,    amt_estado,      amt_periodo,
amt_secuencia)
select
@i_operacionca,               -1,     amt_concepto,
sum(amt_cuota + amt_gracia),   0,     0,
0,                             @w_est_no_vigente  ,0,
1
from ca_amortizacion_tmp, ca_rubro_op_tmp
where amt_operacion = @i_operacionca
and   amt_dividendo > @w_num_dividendos
and   rot_operacion = @i_operacionca
and   rot_concepto  = amt_concepto
and   rot_fpago     = 'P'
and   rot_tipo_rubro= 'C'
group by amt_concepto

if @@error <> 0 begin
   select @w_error = 710001
   goto ERROR
end

/* BORRAR REGISTROS DE LA TABLA CA_AMORTIZACION_TMP */
delete ca_amortizacion_tmp
where amt_operacion = @i_operacionca
and   amt_dividendo > @w_num_dividendos

if @@error <> 0 begin
   select @w_error = 710003
   goto ERROR
end

/* ACTUALIZAR NUMERO DE DIVIDENDO EN LA TABLA DE AMORTIZACION */
update ca_amortizacion_tmp set
amt_dividendo = @w_num_dividendos+1
where amt_operacion = @i_operacionca
and   amt_dividendo = -1
 
if @@error <> 0 begin
   select @w_error = 710002
   goto ERROR
end

return 0

ERROR:

return @w_error
 
go
