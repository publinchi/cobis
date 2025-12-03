/******************************************************************************************/
/* Este programa hace fecha valor  a un grupo de operaciones a una fecha                  */
/* dada                                                                                   */
/* Defecto No. 3111                                                                       */
/******************************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'ca_causacion_adelantada')
   drop table ca_causacion_adelantada
go

if exists (select 1 from sysobjects where name = 'sp_fechavalor_masiva')
   drop proc sp_fechavalor_masiva
go

create proc sp_fechavalor_masiva 

as
declare
@w_banco             cuenta,
@w_operacion         int,   
@w_registros         int,
@w_error             int,
@w_fecha_cierre      datetime,
@w_di_fecha_ini      datetime



select @w_registros   = 0
 

select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7



set forceplan on

select op_operacion, op_banco, di_fecha_ini, di_fecha_ven,di_dividendo,am_acumulado,am_cuota,am_pagado,di_operacion
into ca_causacion_adelantada
from   ca_operacion, ca_dividendo, ca_amortizacion --(index ca_amortizacion_1)
where  di_estado in (1, 2, 9)
and    di_operacion = op_operacion
and    di_estado = 1
and    op_fecha_ult_proceso < di_fecha_ven
and    am_operacion = op_operacion
and    am_dividendo = di_dividendo
and    am_concepto = 'INT'
and    am_acumulado = am_cuota
and    am_cuota != 0
and    am_estado != 3
and    am_pagado < am_cuota
and   op_naturaleza = 'P'

update ca_causacion_adelantada
set di_operacion = 0
WHERE op_operacion >= 0


-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for 
select 
op_operacion, 
op_banco, 
di_fecha_ini
from  ca_causacion_adelantada
 
open cursor_operacion

fetch cursor_operacion
into  
@w_operacion,
@w_banco,
@w_di_fecha_ini
      

while @@fetch_status = 0
begin
         

         exec  sp_restaurar
	       @i_banco		= @w_banco
                 
         exec @w_error = sp_fecha_valor
            @s_date              = @w_fecha_cierre,
            @s_lsrv	     	      = 'PRODUCCION',
            @s_ofi               = 9000,
            @s_sesn              = 1,
            @s_ssn               = 1,
            @s_srv               = 'CONSOLA',
            @s_term              = 'CONSOLA',
            @s_user              = 'script',
            @i_fecha_valor       = @w_di_fecha_ini,
            @i_banco		         = @w_banco,
            @i_operacion         = 'F',   --(F)Fecha Valor (R)Reversa
            @i_observacion       = 'FECHA VALOR POR  ADELANTO DE CAUSACION',
            @i_en_linea          = 'N'
            if @w_error <> 0
            begin
                PRINT 'error saliendo de fechaval.sp banco ' + cast(@w_banco as varchar) + ' error ' + cast(@w_error as varchar)
            end
            
           
   select @w_registros = @w_registros +1
           

   fetch cursor_operacion
   into         
        @w_operacion,
	     @w_banco,
	     @w_di_fecha_ini


end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

print ' Finalizo  No. Registros = ' + cast(@w_registros as varchar)

return 0
go

