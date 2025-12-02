/******************************************************************************************/
/* ejecuta_conta_oper_tmp.sp eejcuta elñ proceso para contabilizar PRV de un grupo        */  
/* de operaciones */ 
/******************************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ejec_prv_operacion_tmp')
   drop proc sp_ejec_prv_operacion_tmp
go

create proc sp_ejec_prv_operacion_tmp 

as

declare
@w_operacion             int,   
@w_banco                 cuenta

PRINT 'ATENCION Operaciones aprocesar'
select * from ca_contabiliza_operacion

--- CURSOR DE OPERACIONES A ANALIZAR
declare 
   Cur_Icn_dato_uno cursor
   for select  
        co_operacion,
        co_banco
   from ca_contabiliza_operacion
   
open Cur_Icn_dato_uno

fetch Cur_Icn_dato_uno
into  @w_operacion,
      @w_banco
      
    
while @@fetch_status = 0
begin
       ----CONSULTA ANTES POR SI HAY OPERACIONES QUE YA SE LES CORRIO EL PROCESO
	  PRINT 'ENTRO OPERACION QUE VA:   ' + CAST(  @w_banco as varchar) 

      exec sp_caconta_prv_oper
      @s_user              = 'automatico',
      @i_debug             = 'S',
      @i_oper              = @w_operacion
		 
     fetch Cur_Icn_dato_uno
	     into  @w_operacion,
   	           @w_banco

end --while @@fetch_status = 0

close Cur_Icn_dato_uno
deallocate Cur_Icn_dato_uno


return 0
go
