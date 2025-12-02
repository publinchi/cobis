/******************************************************************************************/
/* Este programa Revisa valores de Hc  FEB - 28 - 2005                                    */
/******************************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_valores_neg_hc')
   drop proc sp_valores_neg_hc
go

create proc sp_valores_neg_hc 

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
@w_estado          tinyint,
@w_fecha_cierre    datetime,
@w_fecha_ref        datetime,
@w_tran             catalogo

select @w_registros  = 0,
       @w_sec_ok      = 0
 
select @w_hora = convert(char(10), getdate(),8)

print 'carevisahc.sp A procesar = ' + cast (@w_hora as varchar)


select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


select distinct sc_operacion,
                sc_banco
into #revisa_hc
from ca_saldos_cartera
where sc_valor < 0
and   sc_concepto != 'INTANT'


-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select 
         sc_operacion,
         sc_banco

from #revisa_hc
open cursor_operacion

fetch cursor_operacion
into  @w_operacion,
      @w_banco

while @@fetch_status = 0
begin
   select @w_registros = @w_registros +1
   
   PRINT 'carevisahc.sp banco ' + @w_banco + ' operacion ' + cast(@w_operacion as varchar)
   
   exec sp_restaurar
   @i_banco = @w_banco
   
   select @w_sec_ok = isnull(min(amh_secuencial),0)
   from  ca_amortizacion_his
   where amh_operacion   =  @w_operacion
   and   amh_acumulado - amh_pagado < 0
   if @w_sec_ok =  0
   begin

      fetch cursor_operacion
      into  @w_operacion,
            @w_banco
      CONTINUE
   end    
   
   
   
   select @w_sec_ok = isnull(max(tr_secuencial),@w_sec_ok)
   from  ca_transaccion

   where tr_operacion   =  @w_operacion
   and   tr_secuencial  < @w_sec_ok
   and   tr_tran        in  ('PRV', 'EST','AMO','MIG') 
   and   tr_estado      in  ('ING','CON','ANU')
   and   tr_secuencial_ref <> -999  --RECONOCER PRV GENERADAS POR PAGOS
    
   if @w_sec_ok =  0
   begin

      fetch cursor_operacion
      into  @w_operacion,
            @w_banco
      CONTINUE
   end    
   
   select @w_fecha_ref = tr_fecha_ref,
          @w_tran      = tr_tran
   from ca_transaccion
   where tr_operacion = @w_operacion
   and   tr_secuencial = @w_sec_ok
   
   select @w_fecha_ref = dateadd(dd,-3,@w_fecha_ref)
   
   select @w_fecha_ref = op_fecha_ini
   from   ca_operacion
   where  op_operacion = @w_operacion
   and    op_fecha_ini > @w_fecha_ref
   
   if @w_fecha_ref < 'mar 1 2004'
      select @w_fecha_ref = 'mar 1 2004'
      
   exec @w_error = sp_fecha_valor
      @s_date              = @w_fecha_cierre,
      @s_lsrv	     	      = 'PRODUCCION',
      @s_ofi               = 9000,
      @s_sesn              = 1,
      @s_ssn               = 1,
      @s_srv               = 'PRODUCCION',
      @s_term              = 'CONSOLA',
      @s_user              = 'script',
      @i_fecha_valor	      = @w_fecha_ref ,
      @i_banco		         = @w_banco,
      @i_operacion         = 'F',   --(F)Fecha Valor (R)Reversa
      @i_observacion       = 'FECHA VALOR POR script'
   
   if @w_error != 0
   begin
      insert into ca_errorlog
              (er_fecha_proc,      er_error,      er_usuario,
               er_tran,            er_cuenta,     er_descripcion,
               er_anexo)
      values(@w_fecha_cierre,      @w_error,      'script',
               7269,               @w_banco,      'neghc',
               null) 

      fetch cursor_operacion
      into  @w_operacion,
            @w_banco
      CONTINUE
   end
   
   exec @w_error = sp_fecha_valor
        @s_date              = @w_fecha_cierre,
        @s_lsrv	     	      = 'PRODUCCION',
        @s_ofi               = 9000,
        @s_sesn              = 1,
        @s_ssn               = 1,
        @s_srv               = 'PRODUCCION',
        @s_term              = 'CONSOLA',
        @s_user              = 'script',
        @i_fecha_valor	      = @w_fecha_cierre,
        @i_banco		         = @w_banco,
        @i_operacion         = 'F',   --(F)Fecha Valor (R)Reversa
        @i_observacion       = 'ADELANTAR FECHA VALOR POR script'
   if @w_error != 0
   begin
      insert into ca_errorlog
              (er_fecha_proc,      er_error,      er_usuario,
               er_tran,            er_cuenta,     er_descripcion,
               er_anexo)
      values(@w_fecha_cierre,      @w_error,      'script',
               7269,               @w_banco,      'neghc adelantando ',
               null)
   end

   fetch cursor_operacion
   into  @w_operacion,
         @w_banco
end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

select @w_hora = convert(char(10), getdate(),8)

print 'carevisahc Finalizo  = ' + cast (@w_registros as varchar ) + ' ' + cast (@w_hora as varchar)


return 0
go
