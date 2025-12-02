/************************************************************************/
/*   Archivo:              saldo_cero.sp                                */
/*   Stored procedure:     sp_saldo_cero_vigente                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         xxxxxxx                                      */
/*   Fecha de escritura:                                                */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*                                                                      */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_saldo_cero_vigente')
   drop proc sp_saldo_cero_vigente
go

create proc sp_saldo_cero_vigente 

as
declare
@w_banco           cuenta,
@w_operacion       int,   
@w_registros       int,
@w_hora            datetime,
@w_error           int,
@w_saldo           money,
@w_sec_ult_pago    int,
@w_fecha_ult_pago  datetime,
@w_tipo_cobro      char(1),
@w_estado          smallint


select @w_registros  = 0,
       @w_saldo  = 0
 
select @w_hora = convert(char(10), getdate(),8)

print 'saldo_cero.sp A Inicio proceso =' + cast(@w_hora as varchar)


-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select 
         am_operacion,
         am_saldo,
         op_banco,
         op_estado
from am_saldos,ca_operacion
where op_operacion = am_operacion
and   op_estado in (1,2,4,9)

open cursor_operacion

fetch cursor_operacion
   into  
      @w_operacion,
      @w_saldo,
      @w_banco,
      @w_estado

while @@fetch_status = 0
begin
      
   select @w_sec_ult_pago = max(ab_secuencial_pag)
   from ca_abono
   where ab_operacion =  @w_operacion
   and   ab_estado = 'A'
   
   select @w_fecha_ult_pago = ab_fecha_pag
   from ca_abono
   where ab_operacion =  @w_operacion
   and   ab_secuencial_pag = @w_sec_ult_pago
   
   begin tran
   
      select @w_registros = @w_registros + 1
      
      update ca_operacion
      set op_estado = 3,
          op_fecha_ult_proceso = @w_fecha_ult_pago
      from ca_operacion
      where op_operacion = @w_operacion
      
      update ca_dividendo
      set di_estado = 3,
          di_fecha_can = @w_fecha_ult_pago
      where di_operacion = @w_operacion
      and di_estado != 3
      
      update ca_amortizacion
      set am_estado = 3
      where am_operacion = @w_operacion
      and am_estado != 3
      
      PRINT 'saldo_cero.sp ACTUALIZADA' + @w_banco + 'FECHA-PAG' + cast(@w_fecha_ult_pago as varchar) + 'SALDO' + cast(@w_saldo as varchar) + 'est' + cast(@w_estado as varchar)
      
   commit tran

        
   fetch cursor_operacion
   into  
      @w_operacion,
      @w_saldo,
      @w_banco,
      @w_estado

end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

select @w_hora = convert(char(10), getdate(),8)

print 'saldo_cero.sp Finalizo  =' + cast(@w_registros as varchar) + ' ' + @w_hora
return 0
go

