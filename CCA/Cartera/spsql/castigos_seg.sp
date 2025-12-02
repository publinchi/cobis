/******************************************************************************************/
/* Este programa coloca a las operaciones castigadas elv alor del os otros cargo y seguros*/
/******************************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_coloca_seguros_cas')
   drop proc sp_coloca_seguros_cas
go

create proc sp_coloca_seguros_cas 

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
@w_div_vigente     int,
@w_sec_ok          int

select @w_registros  = 0,
       @w_div_vigente = 0,
       @w_sec_ok      = 0
 
select @w_hora = convert(char(10), getdate(),8)

print 'castigos_seg.sp A procesar = ' + @w_hora

-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select 
         op_operacion,
         op_banco,
         op_fecha_fin
from ca_operacion,ca_castigo_masivo
where op_banco = cm_banco
and   op_estado = 4
and   cm_fecha_castigo = '12/28/2004'

open cursor_operacion

fetch cursor_operacion
into  @w_operacion,
      @w_banco,
      @w_op_fecha_fin 

while @@fetch_status = 0
begin
   exec sp_restaurar
        @i_banco = @w_banco
   
   select @w_registros = @w_registros +1
      
   select @w_sec_cas = tr_secuencial
   from   ca_transaccion
   where  tr_operacion = @w_operacion
   and    tr_tran = 'CAS'
   and    tr_estado in ('ING', 'CON')
   
   if @@rowcount = 0
   begin
      PRINT 'castigos_seg.sp ERRORRRR NO HAY SECUENCIAL  @w_banco ' + @w_banco
      fetch cursor_operacion
      into  @w_operacion,
            @w_banco,
            @w_op_fecha_fin 
      CONTINUE
      
   end    
   else   
   begin
      select @w_sec_ok = isnull(max(tr_secuencial),0)
      from  ca_transaccion
      where tr_operacion   =  @w_operacion
      and   tr_secuencial  <  @w_sec_cas
      and   tr_tran        in  ('PRV', 'EST','AMO','MIG') 
      and   tr_estado      in  ('ING','CON','ANU')
      and   tr_secuencial_ref <> -999  
      if @w_sec_ok = 0
      begin
         PRINT 'castigos_seg.sp ERRORRRR NO HAY SECUENCIAL  @w_banco ' + @w_banco
         fetch cursor_operacion
         into  @w_operacion,
               @w_banco,
               @w_op_fecha_fin 
         CONTINUE
      end    
   end   
   
   PRINT 'castigos_seg.sp PROCESO @w_operacion ' + cast(@w_operacion as varchar) + ' @w_banco ' + @w_banco + ' @w_sec_ok ' + cast(@w_sec_ok as varchar)
   
   --ACTUALIZACION EN ca_amortizacion DE LOS OTROS CONCEPTOS CON SECUENCIAL ANTES DE LA TRAN CAS
   
   update ca_amortizacion
   set    am_cuota     = amh_cuota,
          am_acumulado = amh_acumulado
   from   ca_amortizacion_his
   where  am_operacion = @w_operacion
   and    am_estado != 3
   and    am_concepto not in ('CAP', 'INT', 'IMO', 'INTANT', 'CXCINTES')    
   and    amh_operacion  = am_operacion
   and    amh_secuencial = @w_sec_ok
   and    amh_dividendo  = am_dividendo
   and    amh_concepto   = am_concepto
   and    amh_secuencia  = am_secuencia
   
   --ACTAULIZAR LA HISTORIA > AL SEC OK

   update ca_amortizacion_his
   set    amh_cuota     = am_cuota,
          amh_acumulado = am_acumulado
   from   ca_amortizacion,
          ca_amortizacion_his
   where  am_operacion = @w_operacion
   and    am_estado != 3
   and    am_concepto not in ('CAP', 'INT', 'IMO', 'INTANT', 'CXCINTES') 
   and    amh_operacion  = am_operacion
   and    amh_secuencial > @w_sec_ok
   and    amh_dividendo  = am_dividendo
   and    amh_concepto   = am_concepto
   and    amh_secuencia   = am_secuencia


   update cob_cartera_his..ca_amortizacion_his
   set    amh_cuota     = am_cuota,
          amh_acumulado = am_acumulado
   from   ca_amortizacion,
          cob_cartera_his..ca_amortizacion_his
   where  am_operacion = @w_operacion
   and    am_estado != 3
   and    am_concepto not in ('CAP', 'INT', 'IMO', 'INTANT', 'CXCINTES') 
   and    amh_operacion  = am_operacion
   and    amh_secuencial > @w_sec_ok
   and    amh_dividendo  = am_dividendo
   and    amh_concepto   = am_concepto
   and    amh_secuencia   = am_secuencia

      
      
   select @w_div_vigente = isnull(max(dih_dividendo),0)
   from   ca_dividendo_his
   where  dih_operacion = @w_operacion
   and    dih_secuencial = @w_sec_ok
   and    dih_estado = 1
   
   if @w_div_vigente > 0
   begin
      PRINT 'operacion Vigente ' + @w_banco
      update ca_amortizacion
      set    am_cuota     = am_pagado,
             am_acumulado = am_pagado
      from   ca_amortizacion, 
             ca_concepto
      where  am_operacion = @w_operacion
      and    am_concepto = co_concepto
      and    co_categoria = 'S'
      and    am_dividendo >= @w_div_vigente
      and    am_estado != 3
      
      update ca_amortizacion_his
      set    amh_cuota     = amh_pagado,
             amh_acumulado = amh_pagado
      from   ca_amortizacion_his, 
             ca_concepto
      where  amh_operacion = @w_operacion
      and    amh_concepto = co_concepto
      and    co_categoria = 'S'
      and    amh_dividendo >= @w_div_vigente
      and    amh_estado != 3

      update cob_cartera_his..ca_amortizacion_his
      set    amh_cuota     = amh_pagado,
             amh_acumulado = amh_pagado
      from   cob_cartera_his..ca_amortizacion_his, 
             ca_concepto
      where  amh_operacion = @w_operacion
      and    amh_concepto = co_concepto
      and    co_categoria = 'S'
      and    amh_dividendo >= @w_div_vigente
      and    amh_estado != 3         
   end
   
   fetch cursor_operacion
   into  @w_operacion,
         @w_banco ,
         @w_op_fecha_fin
end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

select @w_hora = convert(char(10), getdate(),8)

print 'castigos_seg Finalizo  = ' + cast(@w_registros as varchar) + ' ' + @w_hora

return 0
go

