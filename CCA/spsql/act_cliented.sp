/****************************************************************************/
/* Este programa lee la tabla  ca_cli_deudor  y actualiza la de deudors     */
/* cob_credito..cr_deudores segun los clientes enviados por el BAC          */
/* mail de Genaro Torres 29 marzo 2005  defecto 2615                       */
/****************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'ca_cli_deudor')
drop table ca_cli_deudor
go

create table ca_cli_deudor (
   tramite int not null,
   cliente int not null,
   cedula  numero not null
)
go

if exists (select 1 from sysobjects where name = 'sp_revisa_clientes_deudores')
   drop proc sp_revisa_clientes_deudores
go

create proc sp_revisa_clientes_deudores 

as
declare
@w_banco             cuenta,
@w_operacion         int,   
@w_registros         int,
@w_error             int,
@w_fecha_cierre      datetime,
@w_tramite           int,
@w_cliente           int,
@w_cedula            numero,
@w_de_cliente        int,
@w_de_rol            char(1),
@w_de_ced_ruc        numero,
@w_op_cliente        int

select @w_registros   = 0
 

select @w_fecha_cierre = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


-- CURSOR DE OPERACIONES A ANALIZAR
declare cursor_operacion cursor
for select
      tramite,
      cliente, 
      cedula  
 from ca_cli_deudor

 
 
 open cursor_operacion

fetch cursor_operacion
into  @w_tramite,
      @w_cliente,
      @w_cedula
      

--while @@fetch_status not in (-1 ,0)
while @@fetch_status = 0
begin
         
   select  @w_de_cliente = de_cliente,
           @w_de_rol     = de_rol,
           @w_de_ced_ruc = de_ced_ruc
 from cob_credito..cr_deudores
   where de_tramite =  @w_tramite
   and   de_rol     = 'D'     
   
   
   PRINT '1.DATOS ANTES  : TRAMITE ' + cast(@w_tramite as varchar) + ' CLIENTE ' + cast(@w_de_cliente as varchar) + ' CEDULA ' + cast(@w_de_ced_ruc as varchar)
   
   
   begin tran
      update cob_credito..cr_deudores
      set de_cliente = @w_cliente,
          de_ced_ruc = @w_cedula
      where de_tramite =  @w_tramite
      and   de_rol     = 'D'     
   commit tran   

  PRINT '2.DATOS DESPUES: TRAMITE ' + cast(@w_tramite as varchar) + ' CLIENTE ' + cast(@w_cliente as varchar) + ' CEDULA ' + cast(@w_cedula as varchar)

   fetch cursor_operacion
   into  @w_tramite,
      @w_cliente,
      @w_cedula


end --while @@fetch_status = 0

close cursor_operacion
deallocate cursor_operacion

--print ' Finalizo  = ' + cast (@w_registros as varchar)

return 0
go
