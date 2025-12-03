/***********************************************************************/
/*	Archivo:			qrusuario.sp                   */
/*	Stored procedure:		sp_qr_usuario                  */
/*	Base de Datos:			cob_cartera                    */
/*	Producto:			Cartera	                       */
/*	Disenado por:			Marcelo Poveda                 */
/*	Fecha de Documentacion: 	30/Ago/95                      */
/***********************************************************************/
/*			IMPORTANTE		       		       */
/*	Este programa es parte de los paquetes bancarios propiedad de  */ 
/*	"MACOSA".						       */
/*	Su uso no autorizado queda expresamente prohibido asi como     */
/*	cualquier autorizacion o agregado hecho por alguno de sus      */
/*	usuario sin el debido consentimiento por escrito de la         */
/*	Presidencia Ejecutiva de MACOSA o su representante	       */
/************************************************************************/  
/*			PROPOSITO				       */
/*	Este stored procedure permite consultar usuarios del sistema   */
/***********************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_qr_usuario')
	drop proc sp_qr_usuario
go

create proc sp_qr_usuario (
@i_operacion		char(1) = null,
@i_usuario		login = null,
@i_siguiente            catalogo = null
)
as
declare	
@w_sp_name	varchar(32),	
@w_return	int,
@w_nombre	descripcion,
@w_oficina	smallint,
@w_rowcount     int
		
/*  Captura nombre de Stored Procedure  */
select @w_sp_name = 'sp_qr_usuario'

/* Consulta F5 */
select @i_siguiente = isnull(@i_siguiente,'')

if @i_operacion = 'Q' begin

   set rowcount 20
   select  Login = fu_login,
   Nombre = fu_nombre,
   Oficina = fu_oficina
   from	cobis..cl_funcionario
   where fu_login > @i_siguiente
   order by fu_login 
   set transaction isolation level read uncommitted

   set rowcount 0

end

/* Consulta LostFocus */
if @i_operacion = 'L' begin

   select 
   @w_nombre = fu_nombre,
   @w_oficina = fu_oficina
   from	cobis..cl_funcionario
   where fu_login = @i_usuario
   select @w_rowcount = @@rowcount
   set transaction isolation level read uncommitted

   if @w_rowcount = 0 begin
      exec cobis..sp_cerror
      @t_debug= 'N', @t_file = null,
      @t_from = @w_sp_name, @i_num  = 701164
      return 1   
   end	

   select @w_nombre
   select @w_oficina
			
end
return 0
go

