/************************************************************/
/*   ARCHIVO:         	sp_exec_variable_by_rule.sp    		*/
/*   NOMBRE LOGICO:   	sp_exec_variable_by_rule            */
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
/*   18-May-2017   Sonia Rojas         Emision Inicial.     */
/************************************************************/
use cob_pac
go

if exists (select 1 from sysobjects where name = 'sp_exec_variable_by_rule')
   drop proc sp_exec_variable_by_rule
go

create proc sp_exec_variable_by_rule(
	@t_debug       		char(1)     = 'N',
	@t_from        		varchar(30) = null,
	@s_ssn              int,
	@s_sesn             int,
	@s_user             varchar(30),
	@s_term             varchar(30),
	@s_date             datetime,
	@s_srv              varchar(30),
	@s_lsrv             varchar(30),
	@s_ofi              smallint,
	@t_file             varchar(14) = null,
	@s_rol              smallint    = null,
	@s_org_err          char(1)     = null,
	@s_error            int         = null,
	@s_sev              tinyint     = null,
	@s_msg              descripcion = null,
	@s_org              char(1)     = null,
	@s_culture         	varchar(10) = 'NEUTRAL',
	@t_rty              char(1)     = null,
	@t_trn				int,
	@t_show_version     BIT = 0,
    @i_id_inst_proc    	int,    --codigo de instancia del proceso
    @i_id_inst_act     	int,
    @i_id_asig_act     	int,
    @i_id_empresa      	int,
	@i_acronimo_regla	varchar(10),
	@i_var_nombre       varchar(10) = null, -- LGU nombre de una variable especifica
	@o_resultado        VARCHAR(30) = NULL OUTPUT  -- LGU resultado de evaluar una sola variable
)as

declare		@w_sp_name        		varchar(32),
			@w_codigo_variable 		smallint,
			@w_abrev_variable 		varchar(45),
			@w_ip_nombre_bdd	    varchar(50),
			@w_ip_nombre_programa	varchar(30),
			@w_exec_sp				varchar(100),
			@w_error                int

	select @w_codigo_variable = 0
	select @w_sp_name = 'sp_exec_variable_by_rule'

	select top 1    @w_codigo_variable    	= vb_codigo_variable,
					@w_abrev_variable     	= vb_abrev_variable,
					@w_ip_nombre_bdd 	  	= ip_nombre_bdd,
					@w_ip_nombre_programa 	= ip_nombre_programa
	 from cob_workflow..wf_variable vb
	 join cob_workflow..wf_info_programa ip on vb_id_programa = ip_id_programa
	 join cob_pac..bpl_condition_rule cr 	on vd_id = vb_codigo_variable
	 join cob_pac..bpl_rule_version rv 		on cr.rv_id = rv.rv_id
	 join cob_pac..bpl_rule  r 				on rv.rl_id = r.rl_id
	where rv.rv_status 						= 'PRO'
	  and r.rl_acronym 						= @i_acronimo_regla
	  	  and ((vb_codigo_variable 			> @w_codigo_variable AND @i_var_nombre IS NULL) --LGU
		  OR   (vb_codigo_variable 			> @w_codigo_variable AND vb_abrev_variable = @i_var_nombre)) --LGU
	order by vb_codigo_variable asc


	while @@rowcount > 0
	begin
		select @w_exec_sp =  @w_ip_nombre_bdd + '..' + @w_ip_nombre_programa
		--PRINT 'EXEC '  +' '+ @w_ip_nombre_bdd + '..' + @w_ip_nombre_programa + '  ' + convert(VARCHAR,@w_codigo_variable)

		exec @w_error 			= @w_exec_sp
			 @s_ssn         	= @s_ssn,
			 @s_user            = @s_user,
			 @s_sesn            = @s_sesn,
			 @s_term            = @s_term,
			 @s_date            = @s_date,
			 @s_srv             = @s_srv,
			 @s_lsrv            = @s_lsrv,
			 @s_ofi             = @s_ofi,
			 @t_file            = @t_file,
			 @s_rol             = @s_rol,
			 @s_org_err         = @s_org_err,
			 @s_error           = @s_error,
			 @s_sev             = @s_sev,
			 @s_msg             = @s_msg,
			 @s_org             = @s_org,
			 --@s_culture         = @s_culture,
			 @t_rty             = @t_rty,
			 --@t_show_version    = @t_show_version,
			 @i_id_inst_proc    = @i_id_inst_proc,
			 @i_id_inst_act     = @i_id_inst_act,
			 @i_id_asig_act     = @i_id_asig_act,
			 @i_id_empresa      = @i_id_empresa,
	         @i_id_variable     = @w_codigo_variable

		if @w_error<>0
		begin
			exec @w_error  = cobis..sp_cerror
				 @t_debug  = 'N',
				 @t_file   = '',
				 @t_from   = @w_sp_name,
				 @i_num    = @w_error
			return @w_error
		end

        SELECT @o_resultado = va_valor_actual
        FROM cob_workflow..wf_variable_actual
		where va_id_inst_proc = @i_id_inst_proc
		and va_codigo_var   = @w_codigo_variable

		select top 1    @w_codigo_variable    	  = vb_codigo_variable,
						@w_abrev_variable     	  = vb_abrev_variable,
						@w_ip_nombre_bdd 	  	  = ip_nombre_bdd,
						@w_ip_nombre_programa     = ip_nombre_programa
	     from cob_workflow..wf_variable vb
	     join cob_workflow..wf_info_programa ip  on vb_id_programa = ip_id_programa
	     join cob_pac..bpl_condition_rule cr     on vd_id = vb_codigo_variable
	     join cob_pac..bpl_rule_version rv       on cr.rv_id = rv.rv_id
	     join cob_pac..bpl_rule  r               on rv.rl_id = r.rl_id
	    where rv.rv_status 						  = 'PRO'
	      and r.rl_acronym 						  = @i_acronimo_regla
	  	  and ((vb_codigo_variable 			> @w_codigo_variable AND @i_var_nombre IS NULL) --LGU
		  OR   (vb_codigo_variable 			> @w_codigo_variable AND vb_abrev_variable = @i_var_nombre)) --LGU
	 order by vb_codigo_variable asc


	end


return 0

GO

