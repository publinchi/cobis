/******************************************************************************************/
/* revisa_las las operaciones atrazadas y les busca sie l error                          */                                                                         
/* es por secuecniales*/
/******************************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_revisa_sec')
   drop proc sp_revisa_sec
go

create proc sp_revisa_sec 

as
declare
@w_ro_concepto           catalogo,
@w_banco                 cuenta,
@w_operacion             int,   
@w_se_secuencial         int,
@w_max_sec               int


select @w_max_sec     = 0
       
 

-- CURSOR DE OPERACIONES A ANALIZAR
declare 
   cursor_cuota_can cursor
   for select  
        op_operacion
   from ca_operacion
   where op_estado in (1,2,4,9,10)
   
open cursor_cuota_can

fetch cursor_cuota_can
into  @w_operacion
    
while @@fetch_status = 0
begin
                  
   select @w_max_sec = max(tr_secuencial)
   from ca_transaccion
   where tr_operacion = @w_operacion
  
   select @w_se_secuencial = se_secuencial
   from ca_secuenciales
   where se_operacion = @w_operacion

   ---print '@w_operacion  @w_max_sec @w_se_secuencial ' + cast(@w_operacion as varchar) + ' ' + cast (@w_max_sec as varchar) + ' ' + cast (@w_se_secuencial as varchar)

   if @w_max_sec > @w_se_secuencial
   begin
      update ca_secuenciales 
      set se_secuencial = @w_max_sec + 5
      where se_operacion = @w_operacion

      print 'CAMBIADAS @w_operacion  @w_max_sec @w_se_secuencial ' + cast(@w_operacion as varchar) + ' ' + cast (@w_max_sec as varchar) + ' ' + cast (@w_se_secuencial as varchar)
   end

   fetch cursor_cuota_can
   into  @w_operacion


end --while @@fetch_status = 0

close cursor_cuota_can
deallocate cursor_cuota_can

return 0


