use cob_pac
go

if object_id('sp_rules_run') is not null
begin
  drop procedure sp_rules_run
  if object_id('sp_rules_run') is not null
    print 'FAILED DROPPING PROCEDURE sp_rules_run'
end
go

CREATE PROCEDURE sp_rules_run
(
/*******************************************************************/
/*   ARCHIVO:         rules_run.sp                                 */
/*   NOMBRE LOGICO:   sp_rules_run                                 */
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
/*  Procedimiento recursivo para encontrar el resultado de la regla*/
/*******************************************************************/
/*                     MODIFICACIONES                              */
/*   FECHA        AUTOR              RAZON                         */
/*   15/Nov/2011  Francisco Schnabel Emision Inicial               */
/*   27/Feb/2013  Sergio Hidalgo	 Modificación ICR              */
/*******************************************************************/
    @i_mode              varchar(15)    = 'RULE',
    @i_id_inst_proceso   int            = 0,
    @i_code_rule         int            = 0,
    @i_abreviature	 	 varchar(10)	= null,
    @i_version           int            = 0,
    @i_all_nodes         bit            = 0,
    @i_parent            int            = 0,
    @i_simulator         char           = 'N',
    @i_modo		 		 char           = 'S',
	@i_tipo		 		 		char           = 'E',
    @i_nivel             int            = 0,
    @i_param1           int          = null,
    @i_param2           varchar(50)  = null,
    @i_param3           int          = null,
    @i_param4           varchar(50)  = null,
    @o_return_value      varchar(255)   out,
    @o_return_code       int            out,
	@o_return_value_desc varchar(255)   = null out,
	@o_return_variable   varchar(255)   = null out,
	@o_return_results    varchar(255)   = null out,
	@o_last_condition_parent    int		= -1	   out,
	
    @s_srv               varchar(30)= null,
    @s_user              varchar(30)= null,
    @s_term              varchar(30)= null,
    @s_ofi               smallint= null,
    @s_rol	             smallint    	= null,
    @s_ssn               int= 0,
    @s_lsrv              varchar(30)= null,
    @s_date              datetime= null,
    @s_sesn              int =0,
    @s_org               char(1)     	= null,
    @t_trn               int= 0,
    @i_id_cond_rule	     int            = 0,   
    @i_id_customer       int          	= 0,
    @i_id_card 	         varchar (16) 	= null,
	@i_evaluar_pol       tinyint		= 0,--Se incrementa para evaluar politicas atadas al paso del WF
    @i_status            varchar (1)  	= 'V'
)
as
begin
	DECLARE 
        @w_id                     int,
        @w_parent                 int,
        @w_name                   varchar(25),
        @w_operator               varchar(15),
        @w_isLastSon              bit,
        @w_max_value              varchar(255),
        @w_min_value              varchar(255),
        @w_real_value             varchar(255),
        @w_data_type              varchar(15),
        @w_result                 int,
        @w_function_result        bit,
        @w_code_var               int,
		@w_rule_production	  	  char(4),
        @w_nivel                  int,
	    @w_rd_es_ejecucion        int,
        @w_sp_name                varchar(64),
		@w_rule_type              varchar(20),
		@w_cr_max_value           varchar(255), 
		@w_vd_id                  int,
		@w_variables              varchar(255), 
		@w_result_values          varchar(255),
		@w_var_nemonic            varchar(10),
		@w_num_result             int

	select @w_function_result = 0	
  
	/*Verifica si la regla esta en producción*/
	if (@i_simulator = 'N')
	begin
		if (@i_abreviature is null)
		begin	 
			select @w_rule_production = bpl_rule_version.rv_status
			from bpl_rule
			inner join bpl_rule_version on bpl_rule.rl_id = bpl_rule_version.rl_id
			where bpl_rule.rl_id = @i_code_rule
			and bpl_rule_version.rv_id = @i_version
			
			if (@w_rule_production = 'DIS')
				return 3107568
  
                	select @w_rd_es_ejecucion  = bpl_rule_rol_det.rd_es_ejecucion 
                	from bpl_rule_rol_det 
                	inner join bpl_rule on bpl_rule.rl_id= bpl_rule_rol_det.rl_id 
                	where bpl_rule.rl_id=@i_code_rule 
                	and bpl_rule_rol_det.rr_id_rol=@s_rol
                
                	if (@w_rd_es_ejecucion=0)
                    		return 3107577
		end
		else
		begin
                
			select @w_rule_production = bpl_rule_version.rv_status
			from bpl_rule
			inner join bpl_rule_version on bpl_rule.rl_id = bpl_rule_version.rl_id
			where bpl_rule.rl_acronym = @i_abreviature
			and bpl_rule_version.rv_id = @i_version		 
                
			if (@w_rule_production = 'DIS')
				return 3107568
			
			select @w_rd_es_ejecucion  = bpl_rule_rol_det.rd_es_ejecucion 
                	from bpl_rule_rol_det
                	inner join bpl_rule on bpl_rule.rl_id = bpl_rule_rol_det.rl_id
                	where bpl_rule.rl_acronym = @i_abreviature 
                	and bpl_rule_rol_det.rr_id_rol =@s_rol 

                	if(@w_rd_es_ejecucion=0)
                    	return 3107577 
		end
	end	

	/*Verifica si la regla existe*/
	if (@i_abreviature is null)
	begin
		if not exists (select 1
				from bpl_rule
				inner join bpl_rule_version on bpl_rule.rl_id = bpl_rule_version.rl_id
				where bpl_rule.rl_id = @i_code_rule
				and bpl_rule_version.rv_id = @i_version)
				return 3107567                
	end
	else
	begin
		if not exists (select 1
			  from bpl_rule
		inner join bpl_rule_version on bpl_rule.rl_id = bpl_rule_version.rl_id
			 where bpl_rule.rl_acronym = @i_abreviature
			   and bpl_rule_version.rv_id = @i_version)
				return 3107567                    		
	end
	
	/*Se consulta las condiciones de la regla */
	if (@i_mode = 'RULE' or @i_mode = 'EXT')
	begin
		if (@i_abreviature is null)
		begin
			if @i_parent = 0 
			begin
			DECLARE conditions CURSOR LOCAL
			FOR
			   select cr_id, 
					  cr_operator, 
					  cr_is_last_son, 
					  cr_max_value, 
					  cr_min_value, 
					  vb_tipo_datos,
					  vd_id,
					  cr_parent
				 from bpl_rule
				inner join bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
				inner join bpl_condition_rule on bpl_rule_version.rv_id = bpl_condition_rule.rv_id 
				inner join cob_workflow..wf_variable  on  vd_id = vb_codigo_variable
				where cr_parent is null
				  and bpl_rule.rl_id          = @i_code_rule
				  and bpl_rule_version.rv_id  = @i_version
			end
			else
			begin
				DECLARE conditions CURSOR LOCAL
				FOR
				select cr_id, 
					  cr_operator, 
					  cr_is_last_son, 
					  cr_max_value, 
					  cr_min_value, 
					  vb_tipo_datos,
					  vd_id,
					  cr_parent
				 from bpl_rule
				inner join bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
				inner join bpl_condition_rule on bpl_rule_version.rv_id = bpl_condition_rule.rv_id 
				inner join cob_workflow..wf_variable  on  vd_id = vb_codigo_variable
				where cr_parent = @i_parent
				  and bpl_rule.rl_id          = @i_code_rule
				  and bpl_rule_version.rv_id  = @i_version
			end
		end
		else
		begin
			if @i_parent = 0
			begin
				DECLARE conditions CURSOR LOCAL
				FOR
				   select cr_id, 
						  cr_operator, 
						  cr_is_last_son, 
						  cr_max_value, 
						  cr_min_value, 
						  vb_tipo_datos,
						  vd_id,
						  cr_parent
					 from bpl_rule
					inner join bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
					inner join bpl_condition_rule on bpl_rule_version.rv_id = bpl_condition_rule.rv_id 
					inner join cob_workflow..wf_variable  on  vd_id = vb_codigo_variable
					where cr_parent is null
					  and bpl_rule.rl_acronym     = @i_abreviature
					  and bpl_rule_version.rv_id  = @i_version
			end
			else
			begin
				DECLARE conditions CURSOR LOCAL
				FOR
				   select cr_id, 
						  cr_operator, 
						  cr_is_last_son, 
						  cr_max_value, 
						  cr_min_value, 
						  vb_tipo_datos,
						  vd_id,
						  cr_parent
					 from bpl_rule
					inner join bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
					inner join bpl_condition_rule on bpl_rule_version.rv_id = bpl_condition_rule.rv_id 
					inner join cob_workflow..wf_variable  on  vd_id = vb_codigo_variable
					where cr_parent = @i_parent
					  and bpl_rule.rl_acronym     = @i_abreviature
					  and bpl_rule_version.rv_id  = @i_version
			end
		end
	end
    
	if (@i_mode = 'WFL')
	begin
	
		if @i_evaluar_pol = 1
			select @i_all_nodes = 1
			
		if (@i_abreviature is null)
		begin
			if @i_parent = 0
			begin
				DECLARE conditions CURSOR LOCAL
				FOR
				   select cr_id, 
						  cr_operator, 
						  cr_is_last_son, 
						  cr_max_value, 
						  cr_min_value, 
						  vb_tipo_datos,
						  vd_id,
						  cr_parent
					 from bpl_rule
					inner join bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
					inner join bpl_condition_rule on bpl_rule_version.rv_id = bpl_condition_rule.rv_id 
					inner join cob_workflow..wf_variable  on  vd_id = vb_codigo_variable
					where cr_parent is null
					  and bpl_rule.rl_id         = @i_code_rule
					  and bpl_rule_version.rv_id = @i_version
			end 
			else
			begin
				DECLARE conditions CURSOR LOCAL
				FOR
				   select cr_id, 
						  cr_operator, 
						  cr_is_last_son, 
						  cr_max_value, 
						  cr_min_value, 
						  vb_tipo_datos,
						  vd_id,
						  cr_parent
					 from bpl_rule
					inner join bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
					inner join bpl_condition_rule on bpl_rule_version.rv_id = bpl_condition_rule.rv_id 
					inner join cob_workflow..wf_variable  on  vd_id = vb_codigo_variable
					where cr_parent = @i_parent
					  and bpl_rule.rl_id          = @i_code_rule
					  and bpl_rule_version.rv_id = @i_version
			end
		end
		else
		begin
			if @i_parent = 0
			begin
				DECLARE conditions CURSOR LOCAL
				FOR
				   select cr_id, 
						  cr_operator, 
						  cr_is_last_son, 
						  cr_max_value, 
						  cr_min_value, 
						  vb_tipo_datos,
						  vd_id,
						  cr_parent
					 from bpl_rule
					inner join bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
					inner join bpl_condition_rule on bpl_rule_version.rv_id = bpl_condition_rule.rv_id 
					inner join cob_workflow..wf_variable  on  vd_id = vb_codigo_variable
					where (cr_parent is null)
					  and bpl_rule.rl_acronym     = @i_abreviature
					  and bpl_rule_version.rv_id  = @i_version
			end
			else
			begin
				DECLARE conditions CURSOR LOCAL
				FOR
				   select cr_id, 
						  cr_operator, 
						  cr_is_last_son, 
						  cr_max_value, 
						  cr_min_value, 
						  vb_tipo_datos,
						  vd_id,
						  cr_parent
					 from bpl_rule
					inner join bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
					inner join bpl_condition_rule on bpl_rule_version.rv_id = bpl_condition_rule.rv_id 
					inner join cob_workflow..wf_variable  on  vd_id = vb_codigo_variable
					where cr_parent = @i_parent
					  and bpl_rule.rl_acronym     = @i_abreviature
					  and bpl_rule_version.rv_id  = @i_version
			end		
		end
	end
	
	--Se recupera el tipo de la regla para saber si es politica o regla
	select  @w_rule_type = r.rl_type from bpl_rule r inner join bpl_rule_version rv on r.rl_id = rv.rl_id where r.rl_id =@i_code_rule and rv.rv_id =@i_version

    select @w_nivel = @i_nivel + 1
	OPEN conditions
	FETCH conditions into @w_id,  @w_operator, @w_isLastSon, @w_max_value, @w_min_value, @w_data_type, @w_code_var, @w_parent	
	WHILE (@@FETCH_STATUS = 0 and (@o_return_code <= 0 or @i_all_nodes = 1 ))
	BEGIN
		if (@w_isLastSon = 0)
		begin 
			exec @w_result     = sp_rules_query_values_instance             
				 @i_mode       = @i_mode,
				 @i_code_var   = @w_code_var,
				 @i_id_inst_proceso  = @i_id_inst_proceso,
                 @i_param1     = @i_param1,
                 @i_param2     = @i_param2,
                 @i_param3     = @i_param3,
                 @i_param4     = @i_param4,
				 @t_trn        = @t_trn,
				 @o_real_value = @w_real_value out
				 
				 if  @w_result <> 0
                                 begin
                                    close conditions
                                    deallocate  conditions
                                    return @w_result
                                 end
			
			/*TODO: Manejar Error*/			 
			exec @w_result     = sp_rules_evaluation_condition
			   @i_operator     = @w_operator, 
			   @i_min_value    = @w_min_value,
			   @i_max_value    = @w_max_value,
			   @i_real_value   = @w_real_value,
			   @i_data_type    = @w_data_type,
			   @o_return_value = @w_function_result out
			   
			   if  @w_result <> 0
                           begin
                                close conditions
                                deallocate  conditions
                                return @w_result
                           end
			
			/*TODO: Manejar Error*/
			if (@w_function_result = 1 )
			begin
				exec @w_result       		= sp_rules_run
					 @i_id_inst_proceso     = @i_id_inst_proceso,
					 @i_code_rule    		= @i_code_rule,
					 @i_abreviature  		= @i_abreviature,
					 @i_version      		= @i_version,
					 @i_parent       		= @w_id,
					 @i_mode         		= @i_mode,
					 @i_simulator    		= @i_simulator,
					 @i_nivel        		= @w_nivel,
                     @i_modo         		= @i_modo,
					 @i_tipo        		= @i_tipo,
					 @o_return_value 		= @o_return_value out,
					 @o_return_code  		= @o_return_code out,
					 @o_return_value_desc  	= @o_return_value_desc out,
					 @s_srv               	= @s_srv,
					 @s_user              	= @s_user,
    				 @s_term              	= @s_term,
					 @s_ofi               	= @s_ofi,
    				 @s_rol	             	= @s_rol,
    				 @s_ssn               	= @s_ssn,
    				 @s_lsrv              	= @s_lsrv,
    				 @s_date              	= @s_date,
    				 @s_sesn              	= @s_sesn,
    				 @s_org               	= @s_org,
    				 @t_trn              	= @t_trn,
    				 @i_id_cond_rule		= @i_id_cond_rule,   
    				 @i_id_customer       	= @i_id_customer,
    				 @i_id_card 	    	= @i_id_card,
					 @i_evaluar_pol			= @i_evaluar_pol,	
    				 @i_status          	= 'V',
					 @i_param1     = @i_param1,
					 @i_param2     = @i_param2,
					 @i_param3     = @i_param3,
					 @i_param4     = @i_param4,
    				 @o_return_variable     = @o_return_variable out,
	                 @o_return_results      = @o_return_results out,
					 @o_last_condition_parent = @o_last_condition_parent out
    				 
					 
			    if  @w_result <> 0
                            begin
                               close conditions
                               deallocate  conditions
                               return @w_result
                            end

			end
			
		end
		else
		begin
			if (@i_modo = 'S')
				begin
					select @o_return_value = @w_max_value
					select @o_return_code  = @w_code_var
					
					select @w_num_result = count(*)
						from bpl_condition_rule
						where cr_last_parent_condition = @w_parent and cr_is_last_son = 1
						
						
						-- Concatenar resultados 
						select @w_variables     = '', 
						       @w_result_values = '',
						       @w_cr_max_value = '', 
						       @w_vd_id = null,
						       @o_return_variable ='',
						       @o_return_results ='',
							   @o_last_condition_parent = null
						       
						
 						declare cursor_resultado cursor for
                           select cr_max_value, vd_id 
                           from   bpl_condition_rule
						   where  cr_last_parent_condition = @w_parent 
						   and    cr_is_last_son = 1            
                        open cursor_resultado
                        fetch next from cursor_resultado into  @w_cr_max_value, @w_vd_id
            
 						if @@FETCH_STATUS = 2
 						begin
                           close cursor_resultado
                           deallocate cursor_resultado
                           return 3107578

                        end
      
 						while @@fetch_status = 0
                        begin
                           
                           select @w_var_nemonic = ''
                           
                           select @w_var_nemonic =  vb_abrev_variable 
                           from   cob_workflow..wf_variable 
                           where  vb_codigo_variable = @w_vd_id
                           
                           select @w_variables = @w_variables + @w_var_nemonic + '|'       
                           select @w_result_values = @w_result_values + @w_cr_max_value + '|'
                           
                           --select @w_var_nemonic,@w_variables,@w_result_values  
		 
                           fetch next from cursor_resultado into  @w_cr_max_value, @w_vd_id
                        end
      
 						close cursor_resultado
 						deallocate cursor_resultado
                        
                        select @o_return_variable = @w_variables 
                        select @o_return_results = @w_result_values
						select @o_last_condition_parent = @w_parent
                               
						
						
						-- FIN Concatenar Resultados 
				end
			else
				begin
					if @w_rule_type ='R'
					begin
						if @i_tipo = 'E'
							begin
						select cr_max_value, vd_id from bpl_condition_rule
						where cr_last_parent_condition = @w_parent and cr_is_last_son = 1
						
						select @w_num_result = count(*)
						from bpl_condition_rule
						where cr_last_parent_condition = @w_parent and cr_is_last_son = 1
						
						-- Concatenar resultados 
						select @w_variables     = '', 
						       @w_result_values = '',
						       @w_cr_max_value = '', 
						       @w_vd_id = null,
						       @o_return_variable ='',
						       @o_return_results ='',
							   @o_last_condition_parent = null
						       
 						declare cursor_resultado cursor for
                           select cr_max_value, vd_id 
                           from   bpl_condition_rule
						   where  cr_last_parent_condition = @w_parent 
						   and    cr_is_last_son = 1            
                        open cursor_resultado
                        fetch next from cursor_resultado into  @w_cr_max_value, @w_vd_id
            
 						if @@FETCH_STATUS = 2
 						begin
                           close cursor_resultado
                           deallocate cursor_resultado
                           return 3107578

                        end
      
 						while @@fetch_status = 0
                        begin
                           
                           select @w_var_nemonic = ''
                           
                           select @w_var_nemonic =  vb_abrev_variable 
                           from   cob_workflow..wf_variable 
                           where  vb_codigo_variable = @w_vd_id
                           
                           select @w_variables = @w_variables + @w_var_nemonic + '|'       
                           select @w_result_values = @w_result_values + @w_cr_max_value + '|'
                           
                           --select @w_var_nemonic,@w_variables,@w_result_values  
		 
                           fetch next from cursor_resultado into  @w_cr_max_value, @w_vd_id
                        end
      
 						close cursor_resultado
 						deallocate cursor_resultado
                        
                        select @o_return_variable = @w_variables 
                        select @o_return_results = @w_result_values
                               
						select @o_return_variable,@o_return_results
						select @o_last_condition_parent = @w_parent
							-- FIN Concatenar Resultados 
						end
						else if @i_tipo = 'S'			-- Ejecución de la regla para sp_claim_task_wf que no modifique los dataset
						begin
							select @w_num_result = count(*)
							from bpl_condition_rule
							where cr_last_parent_condition = @w_parent and cr_is_last_son = 1
							
							-- Concatenar resultados 
							select @w_variables     = '', 
								   @w_result_values = '',
								   @w_cr_max_value = '', 
								   @w_vd_id = null,
								   @o_return_variable ='',
								   @o_return_results ='',
								   @o_last_condition_parent = null
								   
							declare cursor_resultado cursor for
							   select cr_max_value, vd_id 
							   from   bpl_condition_rule
							   where  cr_last_parent_condition = @w_parent 
							   and    cr_is_last_son = 1            
							open cursor_resultado
							fetch next from cursor_resultado into  @w_cr_max_value, @w_vd_id
				
							if @@FETCH_STATUS = 2
							begin
							   close cursor_resultado
							   deallocate cursor_resultado
							   return 3107578

							end
		  
							while @@fetch_status = 0
							begin
							   
							   select @w_var_nemonic = ''
							   
							   select @w_var_nemonic =  vb_abrev_variable 
							   from   cob_workflow..wf_variable 
							   where  vb_codigo_variable = @w_vd_id
							   
							   select @w_variables = @w_variables + @w_var_nemonic + '|'       
							   select @w_result_values = @w_result_values + @w_cr_max_value + '|'
							   
							   --select @w_var_nemonic,@w_variables,@w_result_values  
			 
							   fetch next from cursor_resultado into  @w_cr_max_value, @w_vd_id
							end
		  
							close cursor_resultado
							deallocate cursor_resultado
							
							select @o_return_variable = @w_variables 
							select @o_return_results = @w_result_values
							select @o_last_condition_parent = @w_parent
						
						-- FIN Concatenar Resultados 
					end
					end
					else
					
					begin	
							if exists(select 1
									    from bpl_condition_rule cr
						          inner join bpl_result_policies rp on cr.cr_max_value =  convert(varchar(12),rp.rp_id) 
							           where cr.cr_last_parent_condition = @w_parent 
							             and cr_is_last_son = 1)
							begin							
							if (@i_simulator = 'N')
								begin
								
								if exists(select 1 
											 from bpl_condition_rule cr
									   inner join bpl_rule_exceptions re on re.cr_id_result = cr.cr_id_result
									        where cr.cr_last_parent_condition = @w_parent 
										      and cr_is_last_son = 1
											  and re_status = 'V'
											  and re.re_date_before <= getdate()
										      and re.re_date_after > = getdate()
											  and (re_id_customer = @i_id_customer
											   or re_id_card     = @i_id_card))
								begin	   
										select rp.rp_result, rp.rp_id 
										  from bpl_condition_rule cr
									inner join bpl_rule_exceptions re on re.cr_id_result = cr.cr_id_result
									inner join bpl_result_policies rp on re.re_result =  convert(varchar(12),rp.rp_id) 
										 where cr.cr_last_parent_condition = @w_parent 
										   and cr_is_last_son = 1
										   and re_status = 'V'
										   and re.re_date_before <= getdate()
										   and re.re_date_after > = getdate()
										   and (re_id_customer = @i_id_customer
											or re_id_card     = @i_id_card)
									   
										select @o_return_value = rp.rp_result, @o_return_code = cr.vd_id, @o_return_value_desc = rp.rp_name
										  from bpl_condition_rule cr
									inner join bpl_rule_exceptions re on re.cr_id_result = cr.cr_id_result
									inner join bpl_result_policies rp on re.re_result =  convert(varchar(12),rp.rp_id) 
										 where cr.cr_last_parent_condition = @w_parent 
										   and cr_is_last_son = 1
										   and re_status = 'V'
										   and re.re_date_before <= getdate()
										   and re.re_date_after > = getdate()
										   and (re_id_customer = @i_id_customer
											or re_id_card     = @i_id_card)
										
										select @o_last_condition_parent = @w_parent
								
								end
								else
								begin
									select rp.rp_result, rp.rp_id 
									  from bpl_condition_rule cr
								inner join bpl_result_policies rp on cr.cr_max_value =  convert(varchar(12),rp.rp_id) 
									 where cr.cr_last_parent_condition = @w_parent 
									   and cr_is_last_son = 1
								   
									select @o_return_value = rp.rp_result, @o_return_code = cr.vd_id, @o_return_value_desc = rp.rp_name
									  from bpl_condition_rule cr
								inner join bpl_result_policies rp on cr.cr_max_value =  convert(varchar(12),rp.rp_id) 
									 where cr.cr_last_parent_condition = @w_parent 
									   and cr_is_last_son = 1
									
									select @o_last_condition_parent = @w_parent
								end
								end
								else 
								begin
									select cr_max_value, vd_id from bpl_condition_rule
									where cr_last_parent_condition = @w_parent and cr_is_last_son = 1
								end
								
							end
							
					end


				end
		end
	   
	FETCH conditions INTO @w_id, @w_operator, @w_isLastSon, @w_max_value, @w_min_value, @w_data_type, @w_code_var, @w_parent
	END
	
	if (@i_nivel = 0)
	begin
		delete bpl_variable_process where pr_id = @i_id_inst_proceso
		delete bpl_rule_process where pr_id = @i_id_inst_proceso
	end
	
	--if (@@FETCH_STATUS = -1)
		--return 3107569
	
	CLOSE conditions
    deallocate conditions
	return 0
end

-- go
-- sp_procxmode 'dbo.sp_rules_run', 'Unchained'
go
