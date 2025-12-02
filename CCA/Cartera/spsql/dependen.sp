/************************************************************************/
/*	Archivo: 		dependen.sp				*/
/*	Stored procedure: 	sp_dependencias				*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Francisco Yacelga 	  		*/
/*	Fecha de escritura: 	28/Ene./1998				*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Consulta de los datos de una operacion 	                 	*/
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_dependencias')
   drop proc sp_dependencias
go

create proc sp_dependencias (
   @i_nom_sp            varchar(32) = null,
   @i_id_sp  		int         = null   

)

as
declare	@w_sp_name	varchar(32),
       	@w_return	int,
	@w_error	int,
        @w_name		varchar(255),
        @w_name_dep	varchar(255),
	@w_id           int
        

/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_dependencias '

create table  #ca_depende (
 de_sec         int,
 de_id		int,
 de_name	varchar(255)
)

begin tran

declare cursor_procedures cursor for 
select name, id from sysobjects where type = 'P'
and ( name      =  @i_nom_sp  or @i_nom_sp is null)
and ( @i_id_sp  =  id         or @i_id_sp  is null)
for read only
     
open cursor_procedures 
fetch cursor_procedures into @w_name,@w_id

while (@@fetch_status = 0) begin
  
   exec sp_recursivo
   @i_id_padre  = @w_id,
   @i_name      = @w_name,
   @i_ntab 	= 0,
   @i_id	= @w_id,
   @o_salir	= @w_return out


  fetch cursor_procedures into @w_name,@w_id

end

close cursor_procedures 
deallocate cursor_procedures 

select de_name from #ca_depende 
order by de_sec desc

commit tran

return 0
go


