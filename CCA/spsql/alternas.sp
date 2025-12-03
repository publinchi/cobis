/******************************************************************************************/
/* Este programa coloca a las operaciones castigadas elv alor del os otros cargo y seguros*/
/******************************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_alternas_especiales')
   drop proc sp_alternas_especiales
go

create proc sp_alternas_especiales 

as
declare
@w_migrada         cuenta,
@w_banco           cuenta,
@w_operacion       int,   
@w_registros       int,
@w_hora            datetime,
@w_error           int,
@w_sec_cas         int,
@w_op_fecha_fin    datetime,
@w_sec_ok          int,
@w_estado          tinyint

select @w_registros  = 0,
       @w_sec_ok      = 0
 
select @w_hora = convert(char(10), getdate(),8)

--print 'alternas.sp A procesar = %1!' + cast (@w_hora as varchar)
select op_operacion,
       op_banco
into #alternas
from ca_operacion
where op_tipo = 'G'
and op_estado = 99

-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select 
         op_operacion,
         op_banco

from #alternas

open cursor_operacion

fetch cursor_operacion
into  @w_operacion,
      @w_banco

while @@fetch_status = 0
begin
   select @w_registros = @w_registros +1
   
   select @w_sec_ok = isnull(max(tr_secuencial),0)
   from  ca_transaccion
   where tr_operacion   =  @w_operacion
   and   tr_tran        in  ('PRV', 'EST','AMO','MIG') 
   and   tr_estado      in  ('ING','CON','ANU')
   and   tr_secuencial_ref <> -999  
   if @w_sec_ok = 0
   begin
      if not exists(select 1
                    from   ca_transaccion
                    where  tr_operacion = @w_operacion
                    and    tr_tran = 'DES'
                    and    tr_estado in ('CON', 'ING', 'PVA'))
      begin
         update ca_operacion
         set op_estado = 6
         where op_operacion = @w_operacion
      end
      

      fetch cursor_operacion
      into  @w_operacion,
            @w_banco
      CONTINUE
   end    
   
   select @w_estado = oph_estado 
   from ca_operacion_his
   where  oph_operacion = @w_operacion
   and    oph_secuencial = @w_sec_ok
   
   if @w_estado != 99
   begin
      ---PRINT 'alternas.sp PROCESO @w_operacion %1! @w_banco %2!@w_sec_ok  %3!' + @w_operacion + @w_banco + @w_sec_ok
      
      update ca_operacion
      set op_estado = @w_estado
      where op_operacion = @w_operacion
   end
   else
      PRINT 'alternas.sp operacion con historia estado en 99 ' + cast (@w_banco as varchar)
   
   fetch cursor_operacion
   into  @w_operacion,
         @w_banco 

end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

select @w_hora = convert(char(10), getdate(),8)

--print 'castigos_seg Finalizo  = %1! %2!' + cast (@w_registros as varchar) + cast (@w_hora as varchar)

return 0
go

exec  sp_alternas_especiales
go
drop proc sp_alternas_especiales
go