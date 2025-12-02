use cob_pac
go

if object_id('sp_rules_query_values_instance') is not null
begin
  drop procedure sp_rules_query_values_instance
  if object_id('sp_rules_query_values_instance') is not null
    print 'FAILED DROPPING PROCEDURE consulta_valores'
end
go

create procedure  sp_rules_query_values_instance
(
/*******************************************************************/
/*   ARCHIVO:         rules_evaluation_condition.sp                */
/*   NOMBRE LOGICO:   sp_rules_evaluation_condition                */
/*   PRODUCTO:        REE                                          */
/*******************************************************************/
/*   IMPORTANTE                                                    */
/*   Esta aplicacion es parte de los  paquetes bancarios           */
/*   propiedad de MACOSA S.A.                                      */
/*   Su uso no autorizado queda  expresamente  prohibido           */
/*   asi como cualquier alteracion o agregado hecho  por           */
/*   alguno de sus usuarios sin el debido consentimiento           */
/*   por escrito de MACOSA.                                        */
/*   Este programa esta protegido por la ley de derechos           */
/*   de autor y por las convenciones  internacionales de           */
/*   propiedad intelectual.  Su uso  no  autorizado dara           */
/*   derecho a MACOSA para obtener ordenes  de secuestro           */
/*   o  retencion  y  para  perseguir  penalmente a  los           */
/*   autores de cualquier infraccion.                              */
/*******************************************************************/
/*                          PROPOSITO                              */
/*  Permite evaluar las condiciones con los siguientes operadores  */
/*  between, >, >=, <>, <, <=, =                                   */
/*******************************************************************/
/*                     MODIFICACIONES                              */
/*   FECHA        AUTOR              RAZON                         */
/*   15/Nov/2011  Francisco Schnabel Emision Inicial               */
/*   28/Feb/2013  Sergio Hidalgo	 Modificación Control de       */
/*                                   Errores por Código cl_errores */  
/*******************************************************************/             
		@t_trn       		int          = null,
    @i_mode           	varchar(15)  = 'RULE',
    @i_code_var       	int          = null,
    @i_id_inst_proceso  int          = null,
		@i_param1           int          = null,
		@i_param2           varchar(50)  = null,
		@i_param3           int          = null,
		@i_param4           varchar(50)  = null,
	@o_real_value     	varchar(255) = null out
)
as
begin
    declare 	
	@w_retorno      	varchar(255),
	@w_nombre_variable 	varchar(255),
    @w_mensaje_error    varchar(255),
		@w_sp_name          varchar(50),
		@w_procedimiento    varchar(100),
		@w_real_value       varchar(255),
		@w_ret				int
    select 	@w_retorno = null
    SELECT @w_sp_name = 'sp_rules_query_values_instance'
    if (@i_mode = 'RULE')
    begin
		select @w_retorno = vp_value
          from bpl_variable_process
         where pr_id   = @i_id_inst_proceso
           and vd_id   = @i_code_var
		
		if (@@rowcount = 0)
		begin
		select @w_nombre_variable = vb_nombre_variable   from cob_workflow..wf_variable where vb_codigo_variable = @i_code_var
			select @w_mensaje_error = 'LA VARIABLE : ' + @w_nombre_variable + ' NO ESTA SIENDO INSERTADA PARA LA EVALUACIÓN DE LA REGLA'
			
				exec cobis..sp_cerror
				@t_from = @w_sp_name,
				@i_msg  = @w_mensaje_error,
				@i_num  = 3107565
				return 3107565
		end	
		   
    end
    
    if (@i_mode = 'WFL')
    begin
        select @w_retorno = va_valor_actual
          from cob_workflow..wf_variable_actual
         where va_id_inst_proc = @i_id_inst_proceso
           and va_codigo_var   = @i_code_var
		
		if (@@rowcount = 0)
		begin
			select @w_nombre_variable = vb_nombre_variable   from cob_workflow..wf_variable where vb_codigo_variable = @i_code_var
			select @w_mensaje_error = 'LA VARIABLE : ' + @w_nombre_variable + ' NO ESTA SIENDO INSERTADA PARA LA EVALUACIÓN DE LA REGLA'
			
				exec cobis..sp_cerror
				@t_from = @w_sp_name,
				@i_msg  = @w_mensaje_error,
				@i_num  = 3107565
				return 3107565
		end
    end

		if (@i_mode = 'EXT')
		begin


			select @w_procedimiento = ip_nombre_bdd + '..' + ip_nombre_programa from cob_workflow..wf_variable 
			inner join cob_workflow..wf_info_programa on vb_id_programa = ip_id_programa
			where vb_codigo_variable = @i_code_var
		
			 exec @w_procedimiento  
					@t_trn			= @t_trn,
					@i_id_inst_proceso = @i_id_inst_proceso,
					@i_code_var = @i_code_var,
					@i_param1 = @i_param1,
					@i_param2 = @i_param2,
					@i_param3 = @i_param3,
					@i_param4 = @i_param4,
					@o_real_value = @w_retorno out
			
			if (@w_ret > 0)
			begin
			select @w_nombre_variable = vb_nombre_variable   from cob_workflow..wf_variable where vb_codigo_variable = @i_code_var
				select @w_mensaje_error = 'LA VARIABLE : ' + @w_nombre_variable + ' NO ESTA SIENDO INSERTADA PARA LA EVALUACIÓN DE LA REGLA'
				
					exec cobis..sp_cerror
					@t_from = @w_sp_name,
					@i_msg  = @w_mensaje_error,
					@i_num  = 3107565
					return 3107565
			end	
			   
		end

    select @o_real_value = @w_retorno
	return 0
end
go
