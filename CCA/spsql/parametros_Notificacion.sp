/************************************************************************/
/*   Archivo:              parametros_Notificacion.sp					*/
/*   Stored procedure:     sp_parametros_notificacion					*/
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

if exists (select 1 from sysobjects where name = 'sp_parametros_notificacion')
   drop proc sp_parametros_notificacion
go

create proc sp_parametros_notificacion
(	
	@i_param		varchar(60),
	@o_msg          varchar(255)= null out
)
as 

declare	
		@w_error			int,
		@w_mensaje          varchar(150),
		@w_sp_name			varchar(30),
		@w_param_NXML		varchar(10),
		@w_param_NJAS		varchar(10),
		@w_param_NPDF		varchar(10),
		@w_msg				varchar(255)

select @w_sp_name = 'sp_parametros_notificacion'

select	@w_param_NXML	= @i_param + '_NXML',
		@w_param_NJAS	= @i_param + '_NJAS',
		@w_param_NPDF	= @i_param + '_NPDF'

select b.codigo, b.valor
	from cobis..cl_tabla a, cobis..cl_catalogo b
	where a.codigo = b.tabla
	and a.tabla = 'ca_param_notif'
	and b.estado = 'V'
	and b.codigo in (@w_param_NXML, @w_param_NJAS, @w_param_NPDF)

if (@@ERROR != 0 and @@rowcount != 0)
begin
   select @w_error = 724628
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
   select @o_msg
   return @w_error

go


