/************************************************************************/
/*   Archivo:              consulta_nombre_empresa.sp					      */
/*   Stored procedure:     sp_consulta_nombre_empresa					      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Pedro Rafael Montenegro Rosales              */
/*   Fecha de escritura:   Julio 2017                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza la consulta de los parametros para la ejecucion del envio  */
/*   de una notificacion.										        */
/*                              CAMBIOS                                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_nombre_empresa')
   drop proc sp_consulta_nombre_empresa
go

create proc sp_consulta_nombre_empresa
(	
	@i_param		   varchar(60),
	@o_msg         varchar(255)= null out
)
as 

declare	
		@w_error			   int,
		@w_mensaje        varchar(150),
		@w_sp_name			varchar(30),
		@w_msg				varchar(255)

select @w_sp_name = 'sp_consulta_nombre_empresa'
		
select em_descripcion as valor
	from cob_conta..cb_empresa
	where em_empresa in (select pa_tinyint
		from cobis..cl_parametro 
		where pa_nemonico = 'EMP' 
		and pa_producto = 'ADM')

if (@@ERROR != 0 and @@rowcount != 0)
begin
   select @w_error = 724646
	goto ERROR_PROCESO
end

return 0
   
ERROR_PROCESO:
	select @w_msg = mensaje
		from cobis..cl_errores with (nolock)
		where numero = @w_error
		set transaction isolation level read uncommitted
	  
   select @w_msg = isnull(@w_msg, @w_mensaje)
	  
   select @o_msg = ltrim(rtrim(@w_msg))
   return @w_error

go


