/**********************************************************************************************/
/* Este programa Revisa la fecha tr_fecha_ref contra la oph_fecha_ult_proceso MAR - 04 - 2005 */
/**********************************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_revisa_fechas_ref')
   drop proc sp_revisa_fechas_ref
go

create proc sp_revisa_fechas_ref 


as
declare
@w_banco           char(15),
@w_operacion       int,   
@w_registros       int,
@w_secuencial      int,
@w_tran            char(3),
@w_tr_fecha_ref    datetime,
@w_fecha_ult_proceso datetime

select @w_registros  = 0


declare cursor_operacion cursor
for 
select tr_operacion,
       tr_banco,
       tr_secuencial,
       tr_tran,
       tr_fecha_ref
from   ca_transaccion, ca_operacion
where tr_banco = op_banco
and   op_estado in (1,2,3,4,9,10)
and   tr_tran        in  ('PRV', 'EST','AMO','MIG') 
and   tr_fecha_mov >= '03/01/2004'
and   tr_estado      in  ('ING','CON')
and   tr_secuencial_ref <> -999
and   tr_operacion > 4328859 ---ULTIMO DE LA TABLA  ca_fechas_diff
order by 1

open cursor_operacion

fetch cursor_operacion
into  @w_operacion,
      @w_banco,
      @w_secuencial,
      @w_tran,
      @w_tr_fecha_ref

--while @@fetch_status  not in (-1 ,0)
while @@fetch_status  = 0
begin
   
 
   
   select @w_fecha_ult_proceso = oph_fecha_ult_proceso
   from ca_operacion_his
   where oph_operacion = @w_operacion
   and   oph_secuencial = @w_secuencial
   if @@rowcount = 0
   begin
      select @w_fecha_ult_proceso = oph_fecha_ult_proceso
      from cob_cartera_his..ca_operacion_his
      where oph_operacion = @w_operacion
      and   oph_secuencial = @w_secuencial
   end
 
   begin tran
      if @w_fecha_ult_proceso <> @w_tr_fecha_ref
      begin
         select @w_registros = @w_registros +1
         
         PRINT 'carevisa_fhis.sp Operacion ' + cast(@w_operacion as varchar) + ' sec '  + cast(@w_secuencial as varchar)
         
       end   
       commit tran
  
   fetch cursor_operacion
   into  @w_operacion,
         @w_banco,
         @w_secuencial,
         @w_tran,
         @w_tr_fecha_ref
end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

go