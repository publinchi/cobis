/***********************************************************************/
/*	Archivo:		        salfanio.sp                    */
/*	Stored procedure:		sp_saldos_fin_anio             */
/*	Base de Datos:			cob_cartera                    */
/*	Producto:			Cartera	               	       */
/*	Disenado por:		        Elcira Pelaez B:               */
/*	Fecha de Documentacion:         Febreo 2003                    */
/***********************************************************************/
/*			IMPORTANTE		       		       */
/*	Este programa es parte de los paquetes bancarios propiedad de  */ 	
/*	"MACOSA".						       */
/*	Su uso no autorizado queda expresamente prohibido asi como     */
/*	cualquier autorizacion o agregado hecho por alguno de sus      */
/*	usuario sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante	       */
/***********************************************************************/  
/*			PROPOSITO				       */
/*	Generar Los saldos de fin de a¤o para las operaciones y los    */
/*      registra en la tabla ca_saldos_fin_anio			       */
/*                         MODIFICACIONES                              */
/*  FECHA            AUTOR       		RAZON                  */
/***********************************************************************/

use cob_cartera
go 

if exists(select 1 from cob_cartera..sysobjects where name = 'sp_saldos_fin_anio')
   drop proc sp_saldos_fin_anio
go

create proc sp_saldos_fin_anio(
        @i_fecha_proceso     datetime

)
as

declare 
   @w_sp_name           varchar(20),
   @w_op_operacion					int,
   @w_saldo_capital         	money,
   @w_saldo_interes         	money,
   @w_saldo_mora            	money,
   @w_saldo_seguros     	money,
   @w_saldo_otros           	money,
   @w_dividendo_vigente         int

select @w_sp_name = 'sp_saldos_fin_anio'

declare saldos_fin_anio cursor  
for select op_operacion,
           op_toperacion
        from ca_operacion
        where op_estado not in (0,99,98,6)
        for read only

open saldos_fin_anio 
fetch saldos_fin_anio into
   @w_op_operacion

if @@fetch_status != 0
begin 
  print 'No hay Operacion(es) a Procesar'
end

while (@@fetch_status = 0)
begin
   if (@@fetch_status = -1)
   begin
     print 'Error en Cursor' 
     return 1
   end 

select @w_dividendo_vigente = max(isnull(di_dividendo,0))
from ca_dividendo
where di_operacion = @w_op_operacion
and   di_estado in (1,2)

/*SALDO_CAPITAL*/
select @w_saldo_capital = $0.0
select @w_saldo_capital = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
from ca_dividendo, ca_amortizacion, ca_rubro_op
where ro_operacion    = @w_op_operacion
and   ro_tipo_rubro   = 'C'  --Capital
and   am_operacion    = ro_operacion
and   am_concepto     = ro_concepto
and   di_operacion    = ro_operacion
and   am_dividendo    = di_dividendo
and   am_estado       <> 3  -- Cancelado

if @w_saldo_capital <= 0
   select @w_saldo_capital = 0

/*SALDO_INTERES*/
select @w_saldo_interes = $0.0

select @w_saldo_interes = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
from ca_dividendo, ca_amortizacion, ca_rubro_op
where ro_operacion    = @w_op_operacion
and   ro_tipo_rubro   = 'I'  --Interes
and   am_operacion    = ro_operacion
and   am_concepto     = ro_concepto
and   di_operacion    = ro_operacion
and   am_dividendo    = di_dividendo
and   di_estado       = 1  -- Vigente
and   am_estado       <> 3  -- Cancelado

if @w_saldo_interes <= 0
   select @w_saldo_interes = 0

/*SALDO_MORA*/
select @w_saldo_mora = $0.0

select @w_saldo_mora = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
from ca_dividendo, ca_amortizacion, ca_rubro_op
where ro_operacion    = @w_op_operacion
and   ro_tipo_rubro   = 'M'  --Mora
and   am_operacion    = ro_operacion
and   am_concepto     = ro_concepto
and   di_operacion    = ro_operacion
and   am_dividendo    = di_dividendo
and   am_estado       <> 3  -- Cancelado

if @w_saldo_mora <= 0
  select @w_saldo_mora = 0

select @w_saldo_seguros = $0.0

select @w_saldo_seguros = isnull(sum(am_acumulado),0)
from ca_dividendo, ca_amortizacion, ca_concepto
where di_operacion    = @w_op_operacion
and   di_operacion    = am_operacion
and   am_concepto     = co_concepto
and   di_estado       <= @w_dividendo_vigente
and   am_dividendo    = di_dividendo
and   am_estado       <> 3 
and   co_categoria    = 'S'

if @w_saldo_seguros <= 0
   select @w_saldo_seguros = 0

/*SALDO_OTROS*/
select @w_saldo_otros = $0.0
select @w_saldo_otros  = isnull(sum(am_acumulado),0)
from ca_dividendo, ca_amortizacion, ca_concepto
where di_operacion    = @w_op_operacion
and   di_operacion    = am_operacion
and   am_concepto     = co_concepto
and   di_estado       <= @w_dividendo_vigente
and   am_dividendo    = di_dividendo
and   am_estado       <> 3 
and   co_categoria    not in ('S','I','C','M')

if @w_saldo_otros <= 0
   select @w_saldo_otros = 0

   insert into ca_saldos_fin_anio values(@i_fecha_proceso,
				@w_op_operacion,
				@w_saldo_capital,
				@w_saldo_interes,
				@w_saldo_mora,
				@w_saldo_seguros,
				@w_saldo_otros)
    if @@error <> 0 
       print 'Error en Insercion en tabla ca_saldosfin_anio'

fetch saldos_fin_anio into
   @w_op_operacion

end

close saldos_fin_anio
deallocate saldos_fin_anio

return 0  
go             
