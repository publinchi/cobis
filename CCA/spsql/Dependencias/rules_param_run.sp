use cob_pac
go

if object_id('sp_rules_param_run') is not null
begin
  drop procedure sp_rules_param_run
  if object_id('sp_rules_param_run') is not null
    print 'FAILED DROPPING PROCEDURE sp_rules_param_run'
end
go

create procedure  sp_rules_param_run
(
/*******************************************************************/
/*   ARCHIVO:         rules_param_run.sp                           */
/*   NOMBRE LOGICO:   sp_rules_param_run                           */
/*   PRODUCTO:        ICR                                          */
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
/*   21/Feb/2013  B. Ron             Emision Inicial               */
/*******************************************************************/
   @s_rol	            smallint       = null,
   @i_code_rule         int            = null,
   @i_rule_mnemonic     varchar(10)     = null,
   @i_var_values        varchar(255),
   @i_var_separator     char(1),
   @i_all_nodes         bit            = 0,
   @i_tipo		        char(1)		   = 'E'	,
   @i_parent            int            = null,    
   @o_return_variable   varchar(255) = null out,
   @o_return_results    varchar(255) = null out,
   @o_last_condition_parent    int			   out
  	    
)
as
begin
   declare @w_rv_id           int,           --rule version id
           @w_vd_id           int,           --variable id
           @w_pr_id           int,           --rule process id
           @w_vp_id           int,           --variable process id
           @w_fecha           datetime,
           @w_codigo_variable int,           
           @string            varchar(255),
           @index2            int,
           @string2           varchar(255),                      
           @w_count_var       int,
           @w_count_var_tmp   int,                                  
           @w_result          int,
           @w_return_value    varchar(255),
           @w_return_code     int,
           @w_sp_name         varchar(64),
           @w_return_variable varchar(255),
  	       @w_return_results  varchar(255),
  	       @w_system          varchar(15) 
  	

   select @w_return_value   = '',
          @w_return_code    = -1,
          @w_fecha          = getdate(),
          @w_sp_name        = 'sp_rules_param_run',
          @index2           = 1,          
          @w_count_var_tmp  = 0
   
      --Validamos que exista regla
      if not exists( select 1
                    from cob_pac..bpl_rule
                    where (rl_id = @i_code_rule or rl_acronym = @i_rule_mnemonic))
      begin
         return 3107567
      end
         
      --Validamos formato de variables de entrada
      if (substring(@i_var_values, datalength(@i_var_values), 1) <> @i_var_separator)
         select @i_var_values = @i_var_values + @i_var_separator
      if (substring(@i_var_values, 1, 1) = @i_var_separator)
         select @i_var_values = substring(@i_var_values, 2, datalength(@i_var_values)-1)
   
      select @string = @i_var_values    
      
      --Obtenemos codigo de version de la regla
      select @w_rv_id = rv_id,
             @i_code_rule = r.rl_id,
             @w_system = r.rl_system
      from cob_pac..bpl_rule r, 
           cob_pac..bpl_rule_version v
      where (r.rl_id          = @i_code_rule or r.rl_acronym = @i_rule_mnemonic)
        and  r.rl_id          =  v.rl_id
        and  v.rv_status      = 'PRO'
        
        
      if @w_rv_id is null
      begin -- No existe version para la fecha requerida
         return 3107571
      end
            
      --Validamos que el numero de variables de entrada sea igual al numero
      --de variables definidas para la regla      
      select @w_count_var = count (distinct vd_id)
      from bpl_condition_rule
      where rv_id           = @w_rv_id
        and cr_is_last_son <> 1                                            
            
      while (isnull(@string, '') <> '' )
      begin             
         select @index2          = CHARINDEX(@i_var_separator, @string)
         select @string2         = substring(@string, 1, @index2-1 )
         select @string          = substring(@string, @index2 + 1, datalength(@string))
         if @string2 is not null
            select @w_count_var_tmp = @w_count_var_tmp + 1
      end
      
      if (@w_count_var_tmp <> @w_count_var)
      begin
         return 3107572     
      end 
            
      --Obtenemos codigo de instancia del proceso
      exec cobis..sp_cseqnos
         @i_tabla     = 'bpl_rule_process_ejec',
         @o_siguiente = @w_pr_id out   

      if @w_pr_id is null
      begin -- No existe tabla en tabla de secuenciales.
         return 3107503
      end            
      
      --Insertamos registro en bpl_rule_process
      insert into cob_pac..bpl_rule_process(pr_id,    rv_id,    
                                            pr_date,  pr_system)
                                     values(@w_pr_id, @w_rv_id, 
                                            @w_fecha, @w_system)        
      
      select @index2    = 1,
             @string2   = ''
             
      declare variables cursor for  
      select vd_id 
      from bpl_condition_rule
      where rv_id           = @w_rv_id
        and cr_is_last_son <> 1
	  group by vd_id
	  order by max(cr_id) 
            
      open variables
      fetch variables 	
      into @w_vd_id
      
      while (@@FETCH_STATUS = 0)
      begin
      
         --Verificamos que el codigo de la variable exista
         select @w_codigo_variable = vb_codigo_variable 
         from cob_workflow..wf_variable
         where vb_codigo_variable = @w_vd_id
          
         if  @@rowcount <> 1          
            begin -- No existe la variable requerida
            close variables
            deallocate variables
            return 3107573
         end
         
         if not exists( select 1
                        from cob_pac..bpl_variable_process
                        where pr_id = @w_pr_id
                          and vd_id = @w_codigo_variable)
         begin
      
      --print '@w_vd_id: %1!', @w_vd_id
         --Obtenemos valores para las variables de la regla: @i_var_values
         select @index2        = CHARINDEX(@i_var_separator, @i_var_values)
         select @string2       = substring(@i_var_values, 1, @index2-1 )
         select @i_var_values  = substring(@i_var_values, @index2+1, datalength(@i_var_values)-1)      
         
            --Obtenemos codigo de variable del proceso
            exec cobis..sp_cseqnos
               @i_tabla     = 'bpl_variable_process_ejec',
               @o_siguiente = @w_vp_id out   
            
            if @w_vp_id is null
            begin -- No existe tabla en tabla de secuenciales.
               close variables
               deallocate variables
               return 3107503
            end                        
            
            --Insertamos las variables con sus respectivos valores
            insert into cob_pac..bpl_variable_process(vp_id,              pr_id,    
                                                      vd_id,              vp_value)
                                               values(@w_vp_id,           @w_pr_id,
                                                      @w_codigo_variable, @string2)   
            if @@error != 0 
            begin -- Error en la insercion        
               close variables
               deallocate variables
               return 3107504
            end   
         end           
         fetch variables 
         into @w_vd_id
         
      end
      close variables
      deallocate variables
   
   --print '@i_id_inst_proceso: '+ @w_pr_id +' @i_code_rule: '+ @i_code_rule + ' @i_version: '+ @w_rv_id
   
   if @i_tipo = 'E'
   begin
   select @w_return_value, @w_return_code,@o_return_variable,@o_return_results,@o_last_condition_parent
   --Ejecutamos la regla
   exec @w_result           = sp_rules_run
        @s_rol              = @s_rol,
        @i_id_inst_proceso  = @w_pr_id,
        @i_code_rule        = @i_code_rule,
        @i_version          = @w_rv_id,     
        @i_mode             = 'RULE',
        @i_modo             = 'M',
        @o_return_value     = @w_return_value out,
        @o_return_code      = @w_return_code out,
        @o_return_variable  = @o_return_variable out,
	    @o_return_results   = @o_return_results out,
		@o_last_condition_parent   = @o_last_condition_parent out
     
   if @w_result <> 0       
      return @w_result   
     
   select @w_result, @w_return_value,@w_return_code,@o_return_variable,@o_return_results,@o_last_condition_parent
   return 0
end
	else if @i_tipo = 'S'		-- Ejecución de la regla para sp_claim_task_wf que no modifique los dataset
	begin
		--Ejecutamos la regla
	   exec @w_result           = sp_rules_run
			@s_rol              = @s_rol,
			@i_id_inst_proceso  = @w_pr_id,
			@i_code_rule        = @i_code_rule,
			@i_version          = @w_rv_id,     
			@i_mode             = 'RULE',
			@i_modo             = 'M',
			@i_tipo             = 'S',
			@o_return_value     = @w_return_value out,
			@o_return_code      = @w_return_code out,
			@o_return_variable  = @o_return_variable out,
			@o_return_results   = @o_return_results out,
			@o_last_condition_parent   = @o_last_condition_parent out
		 
	   if @w_result <> 0       
		  return @w_result   
	   return 0
	end
end
go
