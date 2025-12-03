use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_run_rule_generico')
  drop procedure sp_run_rule_generico
go

/************************************************************/
/*   ARCHIVO:         	rule_generico.sp       				*/
/*   NOMBRE LOGICO:   	sp_run_rule_generico               	*/
/*   PRODUCTO:        		CARTERA                        	*/
/************************************************************/
/*                     IMPORTANTE                          	*/
/*   Esta aplicacion es parte de los  paquetes bancarios   	*/
/*   propiedad de MACOSA S.A.                              	*/
/*   Su uso no autorizado queda  expresamente  prohibido   	*/
/*   asi como cualquier alteracion o agregado hecho  por   	*/
/*   alguno de sus usuarios sin el debido consentimiento   	*/
/*   por escrito de MACOSA.                                	*/
/*   Este programa esta protegido por la ley de derechos   	*/
/*   de autor y por las convenciones  internacionales de   	*/
/*   propiedad intelectual.  Su uso  no  autorizado dara   	*/
/*   derecho a MACOSA para obtener ordenes  de secuestro   	*/
/*   o  retencion  y  para  perseguir  penalmente a  los   	*/
/*   autores de cualquier infraccion.                      	*/
/************************************************************/
/*                     PROPOSITO                           	*/
/*   Este procedimiento permite ejecutar una regla en      	*/
/*   particular basado en las variables que tiene		   	*/
/*   asignado				      							*/
/************************************************************/
/*                     MODIFICACIONES                    	*/
/*   FECHA         AUTOR               RAZON                */
/*   05-Dic-2016   Henry Salazar       Emision Inicial.     */
/************************************************************/

create proc sp_run_rule_generico(
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
	@i_abrev_regla  varchar(30),
	@i_var_nombre1  varchar(64)     = NULL,
	@i_var_valor1   varchar(64)     = NULL,
	@i_var_nombre2  varchar(64)     = NULL,
	@i_var_valor2   varchar(64)     = NULL,
	@i_var_nombre3  varchar(64)     = NULL,
	@i_var_valor3   varchar(64)     = NULL,
	@i_banco        varchar(30)		= NULL,
	@o_resultado    varchar(255)	= NULL out
)
as
declare
		@w_sp_name        	varchar(32),
		@w_rule           	int,
		@w_rule_version   	int,
		@w_process_id     	int,
		@w_var_pro_id     	int,
		@w_variable_id    	int,
		@w_retorno_id     	int,
		@w_retorno_val    	varchar(255),
		@w_variables      	varchar(255),
		@w_result_values  	varchar(255),
		@w_error		  	int,
		@w_exec_sp        	varchar(255),
		@w_abrev_prod     	varchar(10),
		@w_abrev_var      	varchar(64),
		@w_nombre_db      	varchar(64),
		@w_nombre_programa	varchar(64),
		@w_resultado       	varchar(64)

select @w_sp_name = 'sp_run_rule_generico'

-- BUSQUEDA DE VERSION DE REGLA
select @w_rule         	= bpl_rule.rl_id,
	   @w_rule_version 	= rv_id
from cob_pac..bpl_rule
inner join cob_pac..bpl_rule_version on bpl_rule.rl_id = bpl_rule_version.rl_id
where bpl_rule.rl_acronym = @i_abrev_regla
	and rv_status in ('PRO')
	and getdate() >= rv_date_start
	and getdate() <= rv_date_finish

if @@rowcount = 0
begin
   select @w_error = 3107568
   exec	@w_error  = cobis..sp_cerror
		@t_debug  = 'N',
		@t_file   = '',
		@t_from   = @w_sp_name,
		@i_num    = @w_error
   return @w_error
end

--INSERTA EL PROCESO DE LA REGLA A EVALUAR
exec cobis..sp_cseqnos
     @i_tabla     = 'bpl_rule_process_ejec',
     @o_siguiente = @w_process_id out

insert into cob_pac..bpl_rule_process
values (@w_process_id, @w_rule_version, getdate(), @i_abrev_regla)

--BUSQUEDA DE VARIABLES

IF @i_abrev_regla IN('CREGRP','MONMAXGR','MONMING','CREGRUP1')
BEGIN

declare cursor_variable cursor FOR

	select distinct vb_codigo_variable, vb_abrev_variable, ip_nombre_bdd, ip_nombre_programa
	from cob_workflow..wf_variable
	join   cob_workflow..wf_info_programa on vb_id_programa = ip_id_programa
	join   cob_pac..bpl_condition_rule on vd_id = vb_codigo_variable
	where vb_abrev_variable = @i_var_nombre1

END
ELSE
begin
declare cursor_variable cursor for
	select distinct vb_codigo_variable, vb_abrev_variable, ip_nombre_bdd, ip_nombre_programa
	from cob_workflow..wf_variable
	join   cob_workflow..wf_info_programa on vb_id_programa = ip_id_programa
	join   cob_pac..bpl_condition_rule on vd_id = vb_codigo_variable
	join   cob_pac..bpl_rule  on rl_id = rv_id
	where rl_acronym = @i_abrev_regla
end
open  cursor_variable
fetch cursor_variable
into  @w_variable_id, @w_abrev_var, @w_nombre_db, @w_nombre_programa

while @@fetch_status = 0
BEGIN
	if @w_abrev_var = @i_var_nombre1
	begin
		select @w_resultado = @i_var_valor1
	end
	else if @w_abrev_var = @i_var_nombre2
	begin
		select @w_resultado = @i_var_valor2
	end
	else if @w_abrev_var = @i_var_nombre3
	begin
		select @w_resultado = @i_var_valor3
	end
	else
	begin
		select @w_abrev_prod = substring(@w_abrev_var, 1, 3)
		select @w_exec_sp =  @w_nombre_db + '..' + @w_nombre_programa

		if @w_abrev_prod = 'CCA'
		begin

			exec @w_error 	= @w_exec_sp
				@s_ssn		= @s_ssn,
				@s_user		= @s_user ,
				@s_sesn		= @s_sesn,
				@s_term		= @s_term,
				@s_date		= @s_date,
				@s_srv		= @s_srv,
				@s_rol		= @s_rol,
				@s_ofi		= @s_ofi,
				@i_banco 	= @i_banco,
				@o_resultado= @w_resultado out
		end

		if @w_error<>0
		begin




			exec @w_error = cobis..sp_cerror
				@t_debug  = 'N',
				@t_file   = '',
				@t_from   = @w_sp_name,
				@i_num    = @w_error
			return @w_error
		end
	end

	--INSERTA VALOR DE VARIABLE EN TABLA PROCESO
	exec cobis..sp_cseqnos
		 @i_tabla     = 'bpl_variable_process_ejec',
		 @o_siguiente = @w_var_pro_id out


	insert into cob_pac..bpl_variable_process
	values (@w_var_pro_id, @w_process_id, @w_variable_id, @w_resultado)

	if @w_error<>0
	begin
		exec @w_error  	= cobis..sp_cerror
			@t_debug  	= 'N',
			@t_file   	=	'',
			@t_from		= @w_sp_name,
			@i_num  	= @w_error
		return @w_error
	end

	fetch cursor_variable
	into  @w_variable_id, @w_abrev_var, @w_nombre_db, @w_nombre_programa
end

close cursor_variable
deallocate cursor_variable

-- EJECUCION DE REGLA
select   @w_retorno_id  = -1
select   @w_retorno_val	= ''

exec @w_error 			= cob_pac..sp_rules_run
     @s_srv             = @s_srv,
     @s_user            = @s_user,
     @s_term            = @s_term,
     @s_ofi             = @s_ofi,
     @s_rol             = @s_rol,
     @s_ssn             = @s_ssn,
     @s_lsrv            = @s_lsrv,
     @s_date            = @s_date,
     @s_sesn            = @s_sesn,
     @s_org             = @s_org,
     @t_trn             = 73506,
	 @i_status          = 'V',
     @i_id_inst_proceso	= @w_process_id,
     @i_code_rule       = @w_rule,
     @i_version         = @w_rule_version,
     @o_return_value    = @w_retorno_val   out,
     @o_return_code     = @w_retorno_id    out,
	 @o_return_variable = @w_variables     out,
	 @o_return_results  = @w_result_values out,
     @i_mode            = 'RULE',
     @i_abreviature	    = null,
     @i_simulator       = 'N',
     @i_nivel           =  0,
     @i_modo            = 'S'

if @w_error<>0
begin
	exec @w_error = cobis..sp_cerror
		@t_debug  = 'N',
		@t_file   = '',
		@t_from   = 'sp_rules_run',
		@i_num    = @w_error
	return @w_error
end

select @o_resultado = @w_retorno_val

return 0
GO

