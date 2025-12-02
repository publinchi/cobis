/************************************************************************/
/*	Archivo:		datconca.sp				*/
/*	Stored procedure:	sp_consolican				*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera	                  		*/
/*	Disenado por:  		Fabian de la Torre                      */
/*	Fecha de escritura:	Mar 1999. 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA"							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/*				PROPOSITO				*/
/*	Procedimiento que realiza la llamada al sp_tmp_datooper que     */
/*	llena los datos de consolidador en tabla temporal. 		*/
/************************************************************************/
/******************** PARA OBLIGACIONES CANCELADAS **********************/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consolican')
   drop proc sp_consolican
go

create proc sp_consolican
as 
declare 
@w_error                int,          
@w_return               int,    
@w_operacionca		int,    
@w_banco		cuenta,
@w_sp_name              descripcion,  
@w_fecha_proceso	datetime,
@w_est_cancelado	int,
@w_dot_numero_operacion int,
@w_commit		char(1)

/* EJECUCION DEL PROCESO */
select                                  
@w_sp_name        = 'sp_consolican'

select @w_est_cancelado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CANCELADO'

create table #operacion_cancelada (
operacion	int,
banco        	cuenta,
fecha_proceso	datetime
)

insert into #operacion_cancelada
select                                       
	op_operacion,      
	op_banco,
	op_fecha_ult_proceso

from cob_credito..cr_dato_operacion, cob_cartera..ca_operacion
where do_numero_operacion_banco = op_banco
and do_estado_contable <> 4
and op_estado = 3
and do_tipo_reg = 'D'
order by do_codigo_cliente, do_numero_operacion_banco

/* CURSOR PARA LEER TODAS LAS OPERACIONES A PROCESAR */       
declare cursor_operacion_cancelada cursor for                           
select  operacion,      
	banco,
	fecha_proceso
from #operacion_cancelada
for read only

open  cursor_operacion_cancelada
    
fetch cursor_operacion_cancelada into                                   
	@w_operacionca,    
	@w_banco,
	@w_fecha_proceso

while @@fetch_status = 0 begin

      print 'Operaci¢n ='+ @w_banco

      exec @w_return = cob_cartera..sp_consolidador
      @s_user              = 'sa',
      @s_date              = @w_fecha_proceso,
      @i_banco             = @w_banco,
      @i_modo              = 'N',
      @i_en_linea	   = 'S'

      if @w_return != 0  begin
              PRINT 'datconca.sp  error sale de sp_consolidador' + cast(@w_return as varchar)
         return @w_return
      end

     fetch cursor_operacion_cancelada into                                   
	@w_operacionca,    
	@w_banco,
	@w_fecha_proceso                             

end /* cursor_operacion_nuevo */                                       
                                    
close cursor_operacion_cancelada
deallocate cursor_operacion_cancelada

return 0
go

