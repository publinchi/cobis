use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_categoria')
  drop procedure sp_categoria
go

/****************************************************************/
/*   ARCHIVO:         	sp_categoria.sp					        */
/*   NOMBRE LOGICO:   	sp_categoria                  			*/
/*   PRODUCTO:        		CARTERA                             */
/****************************************************************/
/*                     IMPORTANTE                           	*/
/*   Esta aplicacion es parte de los  paquetes bancarios    	*/
/*   propiedad de MACOSA S.A.                               	*/
/*   Su uso no autorizado queda  expresamente  prohibido    	*/
/*   asi como cualquier alteracion o agregado hecho  por    	*/
/*   alguno de sus usuarios sin el debido consentimiento    	*/
/*   por escrito de MACOSA.                                 	*/
/*   Este programa esta protegido por la ley de derechos    	*/
/*   de autor y por las convenciones  internacionales de    	*/
/*   propiedad intelectual.  Su uso  no  autorizado dara    	*/
/*   derecho a MACOSA para obtener ordenes  de secuestro    	*/
/*   o  retencion  y  para  perseguir  penalmente a  los    	*/
/*   autores de cualquier infraccion.                       	*/
/****************************************************************/
/*                     PROPOSITO                            	*/
/*   Este procedimiento permite obtener la categoria de una     */
/*   operacion				      								*/
/****************************************************************/
/*                     MODIFICACIONES                       	*/
/*   FECHA         AUTOR               RAZON                	*/
/*   05-Dic-2016   Henry Salazar       Emision Inicial.     	*/
/****************************************************************/

create proc sp_categoria(
	@s_ssn			int 			= NULL,
	@s_user			login 			= NULL,
	@s_sesn			int 			= NULL,
	@s_term			varchar(30) 	= NULL,
	@s_date			datetime 		= NULL,
	@s_srv			varchar(30) 	= NULL,
	@s_lsrv			varchar(30) 	= NULL, 
	@s_rol			smallint 		= NULL,
	@s_ofi			smallint 		= NULL,
	@s_org_err		char(1) 		= NULL,
	@s_error		int 			= NULL,
	@s_sev			tinyint 		= NULL,
	@s_msg			descripcion 	= NULL,
	@s_org			char(1) 		= NULL,
	@t_debug		char(1) 		= 'N',
	@t_file			varchar(14) 	= NULL,
	@t_from			varchar(32) 	= NULL,
	@t_trn			int 			= NULL,    
	@i_banco        varchar(30)		= NULL,	
	@o_resultado    varchar(64)    	= NULL out
)
as
declare	@w_sp_name 	varchar(64),
		@w_error	int
		
select @w_sp_name = 'sp_categoria'

select @o_resultado = op_clase 
from ca_operacion 
where op_banco = @i_banco

if @@rowcount = 0
begin
   select @w_error = 6904007 --No existieron resultados asociados a la operación indicada   
   exec   @w_error  = cobis..sp_cerror
          @t_debug  = 'N',
          @t_file   = '',
          @t_from   = @w_sp_name,
          @i_num    = @w_error
   return @w_error
end

return 0
go
