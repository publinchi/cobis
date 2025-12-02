/************************************************************************/
/*   Archivo:              PagoCorresponsalXML.sp                       */
/*   Stored procedure:     sp_pago_corresponsal_xml      				*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raúl Altamirano Mendez                       */
/*   Fecha de escritura:   Junio 2017                                   */
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
/*   Realiza la Aplicacion de los Pagos a los Prestamos procesados en ar*/
/*   chivo de retiro para banco SANTANDER MX, con respuesta OK.         */
/*                              CAMBIOS                                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_corresponsal_xml')
   drop proc sp_pago_corresponsal_xml
go

create proc sp_pago_corresponsal_xml
(
	@s_user          login       = null,
	@s_ofi           smallint    = null,
	@s_date          datetime    = null,
	@s_term          varchar(30) = null,

	@i_fecha         datetime	 = null,

   @o_valida_error  char(1)    = 'S' out,
	@o_msg           varchar(255) = null out
)
as 

declare	
		@w_error		int,
		@w_return		int,
		@w_mensaje		varchar(150),
		@w_sp_name		varchar(30),
		@w_msg			varchar(255)

select @w_sp_name = 'sp_pago_corresponsal_xml'

exec @w_return = cob_cartera..sp_generador_xml 
	@i_fecha = @i_fecha,
	@i_batch = 7071,
	@i_param = 'PFPCO',
   @o_valida_error = @o_valida_error out

if @w_return != 0 
begin
   select @w_error = @w_return
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


