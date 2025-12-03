USE cobis
go
if exists (select 1 from sysobjects where name = 'sp_nro_ciclo')
  drop procedure sp_nro_ciclo
go
/****************************************************************/
/*   ARCHIVO:         	nro_ciclo.sp					        */
/*   NOMBRE LOGICO:   	sp_nro_ciclo                  			*/
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
/*   Este procedimiento permite obtener la el numero de ciclo   */
/*   de un cliente                                              */
/****************************************************************/
/*                     MODIFICACIONES                       	*/
/*   FECHA         AUTOR               RAZON                	*/
/*   05-Abr-2017   Tania Baidal        Emision Inicial.     	*/
/****************************************************************/

create proc sp_nro_ciclo(
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
	@i_ente         int		        = NULL,	
	@o_resultado    int  out
)
as
declare	@w_sp_name 	varchar(64),
		@w_error	int
		
select @w_sp_name = 'sp_nro_ciclo'

print 'sp_nro_ciclo'
select @o_resultado = ISNULL(en_nro_ciclo, 1)
from cobis..cl_ente
where en_ente = @i_ente


if @@rowcount = 0
begin
   select @w_error = 6904007 --No existieron resultados asociados a la operacion indicada   
   exec   @w_error  = cobis..sp_cerror
          @t_debug  = 'N',
          @t_file   = '',
          @t_from   = @w_sp_name,
          @i_num    = @w_error
   return @w_error
end

go
