/******************************************************************************************/
/* defecto Operaciones que tienen cuoas canceladas y saldo                                */                                                                         
/******************************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_revisa_cuota_can')
   drop table ca_revisa_cuota_can
go
create table ca_revisa_cuota_can
(
banco      cuenta   null,
operacion  int   null,
estado_op  smallint  null,
dividendo  int null,
val_pte    float null,
estado     char(1)    
)



if exists (select 1 from sysobjects where name = 'sp_revisa_cuota_cancelada')
   drop proc sp_revisa_cuota_cancelada
go

create proc sp_revisa_cuota_cancelada 

as
declare
@w_ro_concepto           catalogo,
@w_banco                 cuenta,
@w_operacion             int,   
@w_registros             int,
@w_error                 int,
@w_fecha_cierre          datetime,
@w_tran                  catalogo,
@w_fecha_rej             datetime,
@w_sec_rej               int,
@w_secuencial            int,
@w_ro_referencial        catalogo,
@w_ro_signo              char(1),
@w_ro_factor             float,
@w_ro_tipo_puntos        char(1),
@w_fecha_ult_proceso     datetime,
@w_max_sec               int,
@w_modalidad             char(1),
@w_concepto_int          catalogo,
@w_fecha                 char(12),
@w_dividendo             int,
@w_div                   int,
@w_fecha_valor           char(12),
@w_fecha_ini             datetime



select @w_registros   = 0,
       @w_sec_rej     = 0,
       @w_max_sec     = 0
       
 

select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

if not exists (select 1 from  ca_revisa_cuota_can )
   insert into ca_revisa_cuota_can
   select op_banco,op_operacion,op_estado,am_dividendo,'saldo'=am_acumulado - am_pagado ,'I'
   from ca_operacion,ca_amortizacion
   where am_operacion = op_operacion
   and op_estado in (1,2,4,9)
   and am_concepto = 'CAP'
   and am_acumulado - am_pagado > 0
   and am_estado = 3

select distinct operacion
into #procesar
from ca_revisa_cuota_can

-- CURSOR DE OPERACIONES A ANALIZAR
declare 
   cursor_cuota_can cursor
   for select  operacion
       from #procesar

open cursor_cuota_can

fetch cursor_cuota_can
into  
  @w_operacion
    

--while @@fetch_status not in (-1, 0)
while @@fetch_status = 0
begin

             select @w_banco = op_banco
             from ca_operacion
             where op_operacion =  @w_operacion
             
             select @w_dividendo = 0

             select @w_div = min(dividendo)
             from  ca_revisa_cuota_can
             where operacion = @w_operacion


             if  @w_div = 1
             begin
                 PRINT 'revisar problema de migracion -->  ' + cast(@w_banco as varchar)
             end
             ELSE
             begin
               select @w_fecha_ini  = di_fecha_ini
               from ca_dividendo
               where di_operacion = @w_operacion
               and di_dividendo = @w_div
               
               select @w_fecha_valor  = convert(char(12),@w_fecha_ini,101)
               PRINT 'Hace rFeValor hasta  ' + cast(@w_fecha_valor as varchar) + ' de banco '  + cast(@w_banco as varchar)
               
             end

                  
   fetch cursor_cuota_can
   into  @w_operacion



end --while @@fetch_status = 0

close cursor_cuota_can
deallocate cursor_cuota_can

return 0
go