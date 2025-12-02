use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_rule_condonacion')
  drop procedure sp_rule_condonacion
go

/************************************************************/
/*   ARCHIVO:         rule_condonacion.sp               	*/
/*   NOMBRE LOGICO:   sp_rule_condonacion               	*/
/*   PRODUCTO:        CARTERA                               */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*   Este procedimiento permite consultar el porcentaje     */
/*   máximo de codonación aplicado a una operación          */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA         AUTOR               RAZON                */
/*   06-Dic-2016   Henry Salazar       Emision Inicial.     */
/************************************************************/

create proc sp_rule_condonacion(
	@s_ssn			   int 			= NULL,
	@s_user			   login 		= NULL,
	@s_sesn			   int 			= NULL,
	@s_term			   varchar(30) 	= NULL,
	@s_date			   datetime 	= NULL,
	@s_srv			   varchar(30) 	= NULL,
	@s_lsrv			   varchar(30) 	= NULL, 
	@s_rol			   smallint 	= NULL,
	@s_ofi			   smallint 	= NULL,
	@s_org_err		   char(1) 		= NULL,
	@s_error		   int 			= NULL,
	@s_sev			   tinyint 		= NULL,
	@s_msg			   descripcion 	= NULL,
	@s_org			   char(1) 		= NULL,
	@t_debug		   char(1) 		= 'N',
	@t_file			   varchar(14) 	= NULL,
	@t_from			   varchar(32) 	= NULL,
	@t_trn			   int 			= NULL,		
	@i_banco 		   varchar(30),
	@o_porcentaje  	   float        = 0 out      
)
as
declare	@w_sp_name        varchar(32),
		@w_error		  int		
		
select @w_sp_name = 'sp_rule_condonacion'

exec sp_run_rule_generico 
	@s_ssn 		    = @s_ssn,
	@s_user 	    = @s_user,
	@s_sesn		    = @s_sesn,
	@s_term		    = @s_term,
	@s_date		    = @s_date,
	@s_srv		    = @s_srv,
	@s_lsrv		    = @s_lsrv,
	@s_rol		    = @s_rol,
	@s_ofi		    = @s_ofi,
	@s_org_err	    = @s_error,
	@s_error	    = @s_error,
	@s_sev		    = @s_sev,
	@s_msg		    = @s_msg,
	@s_org		    = @s_org,
	@t_debug	    = @t_debug,
	@t_file		    = @t_file,
	@t_from		    = @t_from,
	@t_trn			= @t_trn,	
	@i_abrev_regla 	= 'PORCOND',
	@i_banco      	= @i_banco,
	@o_resultado    = @o_porcentaje out

if @w_error<>0
begin
	exec @w_error = cobis..sp_cerror
		@t_debug  = 'N',
		@t_file   = '',
		@t_from   = 'sp_run_rule_generico',
		@i_num    = @w_error
	return @w_error
end

return 0
go
