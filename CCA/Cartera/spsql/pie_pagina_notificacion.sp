/************************************************************************/
/*   Archivo:              pie_pagina_notificacion.sp					*/
/*   Stored procedure:     sp_pie_pagina_notificacion					*/
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

if exists (select 1 from sysobjects where name = 'sp_pie_pagina_notificacion')
   drop proc sp_pie_pagina_notificacion
go

create proc sp_pie_pagina_notificacion
(	
   @s_ssn           int         = 1,
   @s_sesn          int         = 1,
   @s_date          datetime    = null,
   @s_user          login       = 'usrbatch',
   @s_term          varchar(30) = 'consola',
   @s_ofi           smallint    = null,
   @s_srv           varchar(30) = 'CTSSRV',
   @s_lsrv          varchar(30) = 'CTSSRV',
   @s_rol           smallint    = null,
   @s_org           varchar(15) = null,
   @s_culture       varchar(15) = null,
   @o_msg          varchar(255)= null out
)
as 

declare	
		@w_error			int,
		@w_mensaje          varchar(150),
		@w_sp_name			varchar(30),
		@w_msg				varchar(255)

select @w_sp_name = 'sp_pie_pagina_notificacion'
		
select cp_pie_pagina as valor
from   cob_cartera..ca_pie_pagina_corresp A,
       cob_cartera..ca_corresponsal B
where  A.co_id = B.co_id
and    B.co_estado = 'A'

if (@@ERROR != 0 and @@rowcount != 0)
begin
   select @w_error = 724639
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


