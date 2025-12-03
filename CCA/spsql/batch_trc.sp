/************************************************************************/
/*	Archivo: 		batch_trc.sp				*/
/*	Stored procedure: 	sp_traslado_batch_calif 	        */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez Burbano 		        */
/*	Fecha de escritura: 	Feb 2001			        */
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	'MACOSA', representantes exclusivos para el Ecuador de la 	*/
/*	'NCR CORPORATION'.						*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*      Igualar las operaciones que geenraron TRC                       */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*					      				*/
/************************************************************************/     

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_traslado_batch_calif')
	drop proc sp_traslado_batch_calif
go

create proc sp_traslado_batch_calif (
   @s_user              login,
   @s_term              descripcion,
   @s_lsrv              varchar(30),
   @s_ofi               smallint,
   @s_rol               smallint,
   @s_date              datetime
)

as declare 

@w_return	       int,
@w_sp_name	       varchar(30),
@w_fecha_cierre        datetime,
@w_banco               cuenta,
@w_fecha_proceso       datetime

/* Captura del nombre del Stored Procedure */
select @w_sp_name    = 'sp_traslado_batch_calif'


select @w_fecha_proceso = dateadd(dd, -1, fc_fecha_cierre)
from cobis..ba_fecha_cierre
where fc_producto = 7


declare cursor_batch_trc cursor for                           
select                                       
op_banco
from cob_cartera..ca_operacion
where op_validacion = 'TRC'
order by op_banco
for read only

open  cursor_batch_trc                                        
    
fetch cursor_batch_trc into                                   
@w_banco
                                                          
while @@fetch_status =0 begin

   if @@fetch_status = -1
       return  70899 /* error en la base */ 


              ---PRINT 'batch_trc.sp va a ejecutar el batch con fecha %1!' + cast(@w_fecha_proceso as varchar)

                exec @w_return =  cob_cartera..sp_batch
                    @s_user              = @s_user,
                    @s_term              = @s_term,
                    @s_date              = @w_fecha_proceso, ---FECHA DEL DIA
                    @i_siguiente_dia     = @w_fecha_proceso, ---FECHA DEL DIA
                    @s_ofi               = @s_ofi,
                    @i_debug             = 'N',
                    @i_en_linea          = 'N',
                    @i_banco             = @w_banco,
                    @i_TRC               = 'S' 

	           if @w_return != 0 begin
	              return @w_return
	              print 'Error en batch de regreso @w_return ' + cast(@w_return as varchar)
	           end

                 ---PRINT 'batch_trc.sp sale del batch con fecha %1! ' + cast(@w_fecha_proceso as varchar)

		 update ca_operacion
		 set op_validacion = null
		 where op_banco = @w_banco

   fetch cursor_batch_trc into                                   
   @w_banco
                             
end /* cursor_batch_trc */                                       
                                    
close cursor_batch_trc                                           
deallocate cursor_batch_trc                               

return 0
go
