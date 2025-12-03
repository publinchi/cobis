/************************************************************************/
/*  Archivo:                regla_matriz_riesgo_tmp.sp                  */
/*  Stored procedure:       sp_regla_matriz_riesgo_tmp                  */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_regla_matriz_riesgo_tmp')
    drop proc sp_regla_matriz_riesgo_tmp
GO


create proc sp_regla_matriz_riesgo_tmp (
	@t_debug                   char(1) 	     = 'N',
	@t_file                    varchar(14)   = null,
	@t_from                    varchar(32)   = null,
	@t_show_version            bit           = 0,
	@s_rol                     smallint      = null,
	@i_operacion               char(1)       = null,
	@i_ente              	   int           = null,
	@o_error_mens              varchar(255)  = null out
)
as 

DECLARE
    @w_sp_name           		varchar(32),
    @w_codigo            		int,
    @w_num_error         		int,
    @w_catalogo_cre_des_riesgo  int,
    @w_actividad_economica      varchar(200),
    @w_provincia                smallint,
    @w_cuidad                   int,
    @w_nacionalidad             varchar(64),
	@w_valor_variable_regla     varchar(250),
    @w_segmento                 varchar(10),
    @w_pep                      char(1),
    @w_origen_recursos_var      varchar(10),
    @w_origen_recursos          varchar(64),
    @w_destino_credito_var      varchar(10),
    @w_destino_credito          varchar(64),
    @w_producto                 varchar(64),
	@w_sub_producto             varchar(64),
	@w_trans_internacionales     varchar(250),
	@w_trans_internacionales_sum varchar(250),
    @w_trans_nacionales          varchar(250),
	@w_trans_nacionales_sum      varchar(250),
    @w_deposito	                 varchar(250),
	@w_deposito_sum              varchar(250),	
    @w_retiro	                 varchar(250),
	@w_retiro_sum                varchar(250),
    @w_cv_divisas                varchar(120),
    @w_cv_divisas_sum            varchar(120),
	@w_transaccionalidad_sum     varchar(120),
    @w_mensaje_fallo_regla       varchar(100),
	@w_ejecutar_regla            char(1) = 'S',
    @w_variables                 varchar(255),
    @w_result_values             varchar(255),
    @w_error                     int,
    @w_parent                    int,
    @w_nivel_obtenido            varchar(30),
    @w_resultado_riesgo          varchar(30),
	@w_resul_niv_riesgo          varchar(30),
	@w_resul_rango_calif         int,
	@w_resul_numero_env          varchar(30), 
    @w_resul_numero_rec          varchar(30), 
    @w_resul_monto_env           varchar(30), 
    @w_resul_monto_rec           varchar(30), 
    @w_resul_numero_dep_efec     varchar(30), 
    @w_resul_numero_dep_noefec   varchar(30), 
    @w_resul_monto_dep_efec      varchar(30), 
    @w_resul_monto_dep_noefec    varchar(30),
    @w_es_pep                    varchar(10) ,
    @w_puesto                    varchar(200),
    @w_msm_advertencia           varchar(200),
	@w_cli_a3ccc                 varchar(30),
    @w_cli_a3bloq				 varchar(30),
    @w_cli_condicionado          varchar(30),
	@w_msm_ea_nivel_riesgo       varchar(50)
    

/*  Inicializacion de Variables  */
select @w_sp_name = 'sp_regla_matriz_riesgo'
select @w_mensaje_fallo_regla = 'Fallo Ejecución Regla'
select @w_catalogo_cre_des_riesgo = (select codigo from cobis..cl_tabla where tabla = 'cre_des_riesgo')
select @o_error_mens = '---' -- para validacion
SET    @w_msm_advertencia='ADVERTENCIA: Hubo un problema al generar la Matriz de Riesgo' 
if @i_operacion = 'I'
begin
    /*Validar informacion de datos completos*/
    if exists (select 1 from cobis..cl_seccion_validar where sv_ente = @i_ente and sv_completado = 'N')
	begin
		select @w_ejecutar_regla = 'N'
		--select @o_error_mens = mensaje from cobis..cl_errores where numero = 103164
	end
    

	--/*Validar sub producto que trae la orquestacion de buro*/
    --  if @w_ejecutar_regla = 'S' and not exists (select 1 from   cobis..cl_ente_aux e inner join cobis..cl_producto_santander p on e.ea_ente = p.pr_ente
    --               and e.ea_cta_banco = p.pr_numero_contrato
    --               and e.ea_ente = @i_ente) 
    --begin
	--	select @w_ejecutar_regla = 'N'
	--	select @o_error_mens = mensaje from cobis..cl_errores where numero = 103165
	--end				   
    
    /*Ejecucion regla*/	
    if (@w_ejecutar_regla = 'S')
    begin
        delete from cob_credito..cr_matriz_riesgo_cli_tmp where mr_cliente=@i_ente

        -------------------------------------------------------------
        -- EJECUCION Transferencias Internacionales Monto Enviadas --
        -------------------------------------------------------------
        select @w_result_values = ''		
        select @w_nivel_obtenido = 'BAJO'
        select @w_trans_internacionales = 'TRANSFERENCIAS INTERNACIONALES ENVIADAS'
        
        -- Calculo de Monto de Operaciones para TRANSFERENCIAS INTERNACIONALES ENVIADAS
        select @w_valor_variable_regla = convert(varchar(250), @w_trans_internacionales) + '|' + convert(varchar(250), @w_nivel_obtenido)
        print '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
             @i_rule_mnemonic           = 'MONOPMES',
             @i_var_values              = @w_valor_variable_regla,
             @i_var_separator           = '|',
             @o_return_variable         = @w_variables     out,
             @o_return_results          = @w_result_values out,
             @o_last_condition_parent   = @w_parent        out
        	 
        if @w_error != 0
        begin     	
        	select @o_error_mens = @w_msm_advertencia+' '+@w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule where rl_acronym = 'NUMOPMES' + ' '+ @w_trans_internacionales
        	print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
        
        select @w_resul_monto_env   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
        print 'Regla # Operaciones al Mes - TRANS INTERN ENV - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resul_monto_env)
        
        
        --------------------------------------------------------------
        -- EJECUCION Transferencias Internacionales Monto Recibidas --
        --------------------------------------------------------------
        select @w_result_values = ''		
        select @w_nivel_obtenido = 'BAJO'
        select @w_trans_internacionales = 'TRANSFERENCIAS NACIONALES RECIBIDAS'
        
        -- Calculo de Monto de Operaciones para TRANSFERENCIAS INTERNACIONALES RECIBIDAS
        select @w_valor_variable_regla = convert(varchar(250), @w_trans_internacionales) + '|' + convert(varchar(250), @w_nivel_obtenido)
        print '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
             @i_rule_mnemonic           = 'MONOPMES',
             @i_var_values              = @w_valor_variable_regla,
             @i_var_separator           = '|',
             @o_return_variable         = @w_variables     out,
             @o_return_results          = @w_result_values out,
             @o_last_condition_parent   = @w_parent        out
        	 
        if @w_error != 0
        begin     	
        	select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule where rl_acronym = 'NUMOPMES' + ' '+ @w_trans_internacionales
        	print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
        
        select @w_resul_monto_rec   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
        print 'Regla # Operaciones al Mes - TRANS INTERN ENV - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resul_monto_rec)
        
        
        
        -------------------------------------------
        -- EJECUCION Depositos en Efectivo Monto --
        -------------------------------------------
        select @w_result_values = ''		
        select @w_nivel_obtenido = 'BAJO'
        select @w_trans_internacionales = 'DEPOSITOS EN EFECTIVO'
        
        -- Calculo de Monto de Operaciones para DEPOSITOS EN EFECTIVO
        select @w_valor_variable_regla = convert(varchar(250), @w_trans_internacionales) + '|' + convert(varchar(250), @w_nivel_obtenido)
        print '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
             @i_rule_mnemonic           = 'MONOPMES',
             @i_var_values              = @w_valor_variable_regla,
             @i_var_separator           = '|',
             @o_return_variable         = @w_variables     out,
             @o_return_results          = @w_result_values out,
             @o_last_condition_parent   = @w_parent        out
        	 
        if @w_error != 0
        begin     	
        	select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule where rl_acronym = 'NUMOPMES' + ' '+ @w_trans_internacionales
        	print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
        
        select @w_resul_monto_dep_efec   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
        --print 'Regla # Operaciones al Mes - TRANS INTERN ENV - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resul_monto_dep_efec)
        
        
        
        -------------------------------------------
        -- EJECUCION Depositos No Efectivo Monto --
        -------------------------------------------
        select @w_result_values = ''		
        select @w_nivel_obtenido = 'BAJO'
        select @w_trans_internacionales = 'DEPOSITOS NO EFECTIVO'
        
        -- Calculo de Monto de Operaciones para 'DEPOSITOS NO EFECTIVO
        select @w_valor_variable_regla = convert(varchar(250), @w_trans_internacionales) + '|' + convert(varchar(250), @w_nivel_obtenido)
        print '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
             @i_rule_mnemonic           = 'MONOPMES',
             @i_var_values              = @w_valor_variable_regla,
             @i_var_separator           = '|',
             @o_return_variable         = @w_variables     out,
             @o_return_results          = @w_result_values out,
             @o_last_condition_parent   = @w_parent        out
        	 
        if @w_error != 0
        begin     	
        	select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule where rl_acronym = 'NUMOPMES' + ' '+ @w_trans_internacionales
        	print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
        
        select @w_resul_monto_dep_noefec   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
        print 'Regla # Operaciones al Mes - TRANS INTERN ENV - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resul_monto_dep_noefec)

    
    -- EJECUCION REGLA ACTIVIDAD ECONOMICA
 	select TOP 1 @w_actividad_economica = nc_actividad_ec 
        from   cobis..cl_ente, cobis..cl_negocio_cliente
        where  en_ente         = @i_ente
    	and    en_ente         = nc_ente
        and    nc_estado_reg   = 'V'
    
        select @w_valor_variable_regla = @w_actividad_economica
        exec @w_error                 = cob_pac..sp_rules_param_run
             @s_rol                   = @s_rol,
    	     @i_rule_mnemonic         = 'ACECO',
    	     @i_var_values            = @w_valor_variable_regla, 
    	     @i_var_separator         = '|',
    	     @o_return_variable       = @w_variables     out,
    	     @o_return_results        = @w_result_values out,
    	     @o_last_condition_parent = @w_parent  out
    	        
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'ACECO'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
           
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','') 
        select @w_resultado_riesgo = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')
        
    	PRINT'Regla Actividad Economica - ACECO - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)    
        PRINT'Regla Actividad Economica - ACECO - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
         
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                               values ( @i_ente,    '001',       @w_nivel_obtenido, @w_resultado_riesgo)
    										   
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION REGLA ENTIDAD FEDERATIVA - ZONA GEOGRAFICA
    set @w_valor_variable_regla=' '
    if exists(select 1 from   cobis..cl_direccion where  di_tipo ='RE' and  di_ente = @i_ente) 
    begin
        select top 1 @w_provincia = di_provincia, 
                     @w_cuidad    = di_ciudad
        from   cobis..cl_direccion 
        where  di_tipo ='RE' 
        and    di_ente = @i_ente
     end
     else
     begin
        select top 1 @w_provincia = di_provincia, 
                     @w_cuidad    = di_ciudad
           from   cobis..cl_direccion 
           where  di_tipo ='AE' 
           and    di_ente = @i_ente
     end   
        
        select @w_valor_variable_regla = convert(varchar, @w_provincia)+'|'+convert(varchar,@w_cuidad) 
        exec @w_error                  = cob_pac..sp_rules_param_run
             @s_rol                    = @s_rol,
    	      @i_rule_mnemonic         = 'ENTFEDE1',
    	      @i_var_values            = @w_valor_variable_regla, 
    	      @i_var_separator         = '|',
    	      @o_return_variable       = @w_variables     out,
    	      @o_return_results        = @w_result_values out,
    	      @o_last_condition_parent = @w_parent  out
    	        
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'ENTFEDE1'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
          	
        if @w_result_values is null
        begin
           PRINT'Regla Entidad Financiera - ENTFEDE1 - @w_result_values is null' + convert(varchar(50), @w_result_values) + 'Se procede a ejecutar Regla Entidad Financiera - ENTFEDE2' 
           exec @w_error                  = cob_pac..sp_rules_param_run
               @s_rol                    = @s_rol,
                @i_rule_mnemonic         = 'ENTFEDE2',
                @i_var_values            = @w_valor_variable_regla, 
                @i_var_separator         = '|',
                @o_return_variable       = @w_variables     out,
                @o_return_results        = @w_result_values out,
                @o_last_condition_parent = @w_parent  out
                  
           if @w_error != 0
           begin
			   select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'ENTFEDE2'
			   print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			   
            --goto ERROR
           end
        end
    	 
        if @w_result_values is null
        begin
        	select @w_result_values = 'MEDIO|440'
        end
        
        PRINT'zona geografica'+ convert(VARCHAR(50),@w_result_values)
    		
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
        select @w_resultado_riesgo = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')
         
        PRINT'Regla Entidad Financiera - ENTFEDE1 - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)    
        PRINT'Regla Entidad Financiera - ENTFEDE1 - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
        
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                               values ( @i_ente,    '002',       @w_nivel_obtenido, convert(INT ,@w_resultado_riesgo))
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION REGLA NACIONAL
       select @w_result_values = ''
      /* select @w_nacionalidad = (select valor from cobis..cl_catalogo 
    	                         where tabla = (select codigo 
    							                from cobis..cl_tabla 
    											where tabla = 'cl_nacionalidad') and codigo = E.en_nac_aux) 
       from   cobis..cl_ente E
       where  en_ente = @i_ente
    	*/
    	
       set	@w_nacionalidad='MEXICANA'
       select @w_valor_variable_regla = @w_nacionalidad
       exec @w_error                  = cob_pac..sp_rules_param_run
            @s_rol                    = @s_rol,
    	    @i_rule_mnemonic         = 'NACIONAL',
    	    @i_var_values            = @w_valor_variable_regla, 
    	    @i_var_separator         = '|',
    	    @o_return_variable       = @w_variables     out,
    	    @o_return_results        = @w_result_values out,
    	    @o_last_condition_parent = @w_parent  out
    		
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule where rl_acronym = 'NACIONAL'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','') 
        select @w_resultado_riesgo = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')
         
        PRINT'Regla NACIONAL - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)
        PRINT'Regla NACIONAL - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
      
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                                values ( @i_ente,    '003',       @w_nivel_obtenido, convert(INT ,@w_resultado_riesgo))
    
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION REGLA SEGMENTO RIESGO - SEGMENTO -- Vicky
        select @w_result_values = ''    	
        select @w_sub_producto = p.pr_codigo_subproducto 
        from   cobis..cl_ente_aux e
        inner join cobis..cl_producto_santander p
        on e.ea_ente = p.pr_ente
        and e.ea_cta_banco = p.pr_numero_contrato
        and e.ea_ente = @i_ente
		
		if @@rowcount = 0 begin
		   select @w_nivel_obtenido = 'BAJO', @w_resultado_riesgo = 80
		end
        else begin
           select @w_valor_variable_regla = 'INDIVIDUOS'+'|'+'PARTICULARES'+'|'+@w_sub_producto
           
           exec @w_error                  = cob_pac..sp_rules_param_run
                @s_rol                    = @s_rol,
    	         @i_rule_mnemonic         = 'SEGRIES',
    	         @i_var_values            = @w_valor_variable_regla, 
    	         @i_var_separator         = '|',
    	         @o_return_variable       = @w_variables     out,
    	         @o_return_results        = @w_result_values out,
    	         @o_last_condition_parent = @w_parent  out
    	           
           if @w_error != 0
           begin
		   	select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'SEGRIES'
		   	print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
               --goto ERROR
           end
              	
           if @w_result_values is null
           begin
           	select @w_result_values = '0|0'
           end
              
           select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')    
           select @w_resultado_riesgo = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')
           
           PRINT'Regla SEGMENTO - SEGRIES - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)    
           PRINT'Regla SEGMENTO - SEGRIES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
        end 
		
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                                values ( @i_ente,    '004',       @w_nivel_obtenido, convert(INT ,@w_resultado_riesgo))
    
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION REGLA PRODUCTO
        select @w_result_values = ''
        select @w_producto             = 'Crédito Grupal'
        SELECT @w_valor_variable_regla = @w_producto
        exec @w_error                  = cob_pac..sp_rules_param_run
             @s_rol                    = @s_rol,
    	      @i_rule_mnemonic         = 'PRODRIESG',
    	      @i_var_values            = @w_valor_variable_regla, 
    	      @i_var_separator         = '|',
    	      @o_return_variable       = @w_variables     out,
    	      @o_return_results        = @w_result_values out,
    	      @o_last_condition_parent = @w_parent  out
    	        
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'PRODRIESG'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
        	select @w_result_values = '0|0'
        end
           
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')    
        select @w_resultado_riesgo = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')
        
        PRINT'Regla PRODUCTO - PRODRIESG - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)    
        PRINT'Regla PRODUCTO - PRODRIESG - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
        
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                                values ( @i_ente,    '005',       @w_nivel_obtenido, convert(INT ,@w_resultado_riesgo))
    
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION REGLA PEP
        select @w_result_values = ''
        select @w_pep = en_persona_pep 
    	from   cobis..cl_ente 
    	where  en_ente = @i_ente
    	if(@w_pep is null)
    	begin
         exec cob_credito..sp_valida_pep
         @i_ente=@i_ente,
         @o_es_pep = @w_es_pep OUTPUT,
         @o_puesto = @w_puesto OUTPUT
    	
         print 'Es PEP'+ convert(VARCHAR(10),@w_es_pep)
         print 'Puesto PEP'+ convert(VARCHAR(10),@w_puesto)
         
         update cobis..cl_ente set en_persona_pep=@w_es_pep, p_carg_pub=@w_puesto
         where en_ente=@i_ente
         
         SET @w_pep=@w_es_pep
    	end
    	
        select @w_valor_variable_regla = @w_pep
        exec @w_error                  = cob_pac..sp_rules_param_run
             @s_rol                    = @s_rol,
    	     @i_rule_mnemonic          = 'PEPRIESG',
    	     @i_var_values             = @w_valor_variable_regla, 
    	     @i_var_separator          = '|',
    	     @o_return_variable        = @w_variables     out,
    	     @o_return_results         = @w_result_values out,
    	     @o_last_condition_parent  = @w_parent  out
    	 	
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'PEPRIESG'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is NULL OR @w_result_values=''
        begin
            select @w_result_values = '0|0'
        end
       
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','') 
        select @w_resultado_riesgo = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')
         
        PRINT'Regla PEP - PEPRIESG - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)
        PRINT'Regla PEP - PEPRIESG - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	  
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                                values ( @i_ente,    '006',       @w_nivel_obtenido, convert(INT ,@w_resultado_riesgo))
    											
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION REGLA Origen de Recursos
        select @w_result_values = ''
        select TOP 1 @w_origen_recursos_var = nc_recurso, 
                     @w_origen_recursos     = valor 
    	from  cobis..cl_negocio_cliente, cobis..cl_tabla,cobis..cl_catalogo
        where cl_tabla.tabla in ('cl_recursos_credito') 
    	and   cl_tabla.codigo    = cl_catalogo.tabla 
    	and   cl_catalogo.codigo = nc_recurso 
        and   nc_estado_reg      = 'V' 
    	and   nc_ente            = @i_ente
    
    print 'Print: ----@w_origen_recursos_var:>>>>>' + convert(varchar, @w_origen_recursos_var)
    	
    -- cambiar de menor a mayo por bajo lato y medio
        SELECT @w_valor_variable_regla = @w_origen_recursos_var
        exec @w_error                  = cob_pac..sp_rules_param_run
             @s_rol                    = @s_rol,
    	     @i_rule_mnemonic          = 'ORIRECU',
    	     @i_var_values             = @w_valor_variable_regla, 
    	     @i_var_separator          = '|',
    	     @o_return_variable        = @w_variables     out,
    	     @o_return_results         = @w_result_values out,
    	     @o_last_condition_parent  = @w_parent  out
    	 	
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'ORIRECU'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
       
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','') 
        select @w_resultado_riesgo = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')
    	
        PRINT'Regla ORIGEN RECURSO - ORIRECU - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)
        PRINT'Regla ORIGEN RECURSO - ORIRECU - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	  
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                                values ( @i_ente,    '007',       @w_nivel_obtenido, convert(INT ,@w_resultado_riesgo))
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION REGLA Destino Recursos Catalogo = cl_destino_credito
        select @w_result_values = ''
        select TOP 1 @w_destino_credito_var = nc_destino_credito
        from  cobis..cl_negocio_cliente
        where nc_estado_reg      = 'V' 
    	and   nc_ente            = @i_ente 
    
    	print 'Print: ----@w_destino_credito_var:>>>>>' + convert(varchar, @w_destino_credito_var)
    	
        SELECT @w_valor_variable_regla = @w_destino_credito_var
        exec @w_error                  = cob_pac..sp_rules_param_run
             @s_rol                    = @s_rol,
    	     @i_rule_mnemonic          = 'DESRECU',
    	     @i_var_values             = @w_valor_variable_regla, 
    	     @i_var_separator          = '|',
    	     @o_return_variable        = @w_variables     out,
    	     @o_return_results         = @w_result_values out,
    	     @o_last_condition_parent  = @w_parent  out
    	 	
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'DESRECU'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
       
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','') 
        select @w_resultado_riesgo = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')	
    
        PRINT'Regla Destino Recursos - DESRECU - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)
        PRINT'Regla Destino Recursos - DESRECU - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	  
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                               values ( @i_ente,    '008',       @w_nivel_obtenido, convert(INT ,@w_resultado_riesgo))
    
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION Transferencias Internacionales
        select @w_result_values = ''		
        select @w_nivel_obtenido = 'BAJO'
        select @w_trans_internacionales = 'TRANSFERENCIAS INTERNACIONALES ENVIADAS'
    
    	-- Calculo de Numero de Operaciones para TRANSFERENCIAS INTERNACIONALES ENVIADAS
    	select @w_valor_variable_regla = convert(varchar(250), @w_trans_internacionales) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin     	
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_trans_internacionales
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla # Operaciones al Mes - TRANS INTERN ENV - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	select @w_trans_internacionales_sum = @w_resultado_riesgo
		
    	--Se reasigna para insertar en tabla
    	select @w_resul_numero_env = @w_resultado_riesgo
    --------------------------------------------------------------------------------------------------------------------------------------------
        select @w_trans_internacionales = 'TRANSFERENCIAS INTERNACIONALES RECIBIDAS'
    
    	-- Calculo de Numero de Operaciones para TRANSFERENCIAS INTERNACIONALES RECIBIDAS
    	select @w_valor_variable_regla = convert(varchar(250), @w_trans_internacionales) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_trans_internacionales
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    		
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    
    	select @w_trans_internacionales_sum = convert(int,@w_trans_internacionales_sum) + convert(int,@w_resultado_riesgo)
        PRINT 'Regla # Operaciones al Mes - TRANS INTERN - resultado_riesgo:' + convert(varchar(50), @w_trans_internacionales_sum)
        
        --Se reasigna para insertar en tabla 
        select @w_resul_numero_rec = @w_resultado_riesgo
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- Resultado para mostrar - Transf. internacionales
    
        select @w_nivel_obtenido = ''
    	-- Calculo de Nivel de Riesgo
    	select @w_valor_variable_regla = convert(varchar(250), @w_trans_internacionales_sum)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'TRANSINTER',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'TRANSINTER'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
       
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla Transferencias Internacionales - TRANSINTER - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)
    
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                               values ( @i_ente,    '009',       @w_nivel_obtenido, convert(int ,@w_trans_internacionales_sum))	
    
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION Transferencias Nacionales
        select @w_result_values = ''		
        select @w_nivel_obtenido = 'BAJO'
        select @w_trans_nacionales = 'TRANSFERENCIAS NACIONALES ENVIADAS'
    
    	-- Calculo de Numero de Operaciones para TRANSFERENCIAS NACIONALES ENVIADAS
    	select @w_valor_variable_regla = convert(varchar(250), @w_trans_nacionales) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values          = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_trans_nacionales
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla # Operaciones al Mes - TRANS NACIO ENV - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	select @w_trans_nacionales_sum = @w_resultado_riesgo
    --------------------------------------------------------------------------------------------------------------------------------------------
        select @w_trans_nacionales = 'TRANSFERENCIAS NACIONALES RECIBIDAS'
    
    	-- Calculo de Numero de Operaciones para TRANSFERENCIAS NACIONALES RECIBIDAS
    	select @w_valor_variable_regla = convert(varchar(250), @w_trans_nacionales) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_trans_nacionales
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    		
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    
    	select @w_trans_nacionales_sum = convert(int,@w_trans_nacionales_sum) + convert(int,@w_resultado_riesgo)
        PRINT 'Regla # Operaciones al Mes - TRANS NACIO REC - resultado_riesgo:' + convert(varchar(50), @w_trans_nacionales_sum)
    
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION DEPOSITOS EN EFECTIVO
        select @w_result_values = ''		
        select @w_nivel_obtenido = 'BAJO'
        select @w_deposito = 'DEPOSITOS EN EFECTIVO'
    
    	-- Calculo de Numero de Operaciones para DEPOSITOS EN EFECTIVO
    	select @w_valor_variable_regla = convert(varchar(250), @w_deposito) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_deposito
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)	
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla # Operaciones al Mes - DEPOSITO EFECTIVO - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	select @w_deposito_sum = @w_resultado_riesgo
    	
    	--Se reasigna para insertar en tabla
    	select @w_resul_numero_dep_efec = @w_resultado_riesgo
    --------------------------------------------------------------------------------------------------------------------------------------------
        select @w_deposito = 'DEPOSITOS NO EFECTIVO'
    
    	-- Calculo de Numero de Operaciones para TRANSFERENCIAS NACIONALES RECIBIDAS
    	select @w_valor_variable_regla = convert(varchar(250), @w_deposito) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_deposito
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    		
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla # Operaciones al Mes - DEPOSITO EFECTIVO - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	
    	select @w_deposito_sum = convert(int,@w_deposito_sum) + convert(int,@w_resultado_riesgo)
        PRINT 'Regla # Operaciones al Mes - DEPOSITO EFECTIVO TOTAL - resultado_riesgo:' + convert(varchar(50), @w_deposito_sum)
        
        --Se reasigna para insertar en tabla
    	select @w_resul_numero_dep_noefec = @w_resultado_riesgo
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION RETIROS EN EFECTIVO
        select @w_result_values = ''		
        select @w_nivel_obtenido = 'BAJO'
        select @w_retiro = 'RETIROS EN EFECTIVO'
    
    	-- Calculo de Numero de Operaciones para RETIROS EN EFECTIVO
    	select @w_valor_variable_regla = convert(varchar(250), @w_deposito) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_retiro
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla # Operaciones al Mes - RETIROS EN EFECTIVO - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	select @w_retiro_sum = @w_resultado_riesgo
    --------------------------------------------------------------------------------------------------------------------------------------------
        select @w_deposito = 'RETIROS NO EFECTIVO'
    
    	-- Calculo de Numero de Operaciones para TRANSFERENCIAS NACIONALES RECIBIDAS
    	select @w_valor_variable_regla = convert(varchar(250), @w_deposito) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_retiro
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    		
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla # Operaciones al Mes - RETIROS NO EFECTIVO - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	
    	select @w_retiro_sum = convert(int,@w_retiro_sum) + convert(int,@w_resultado_riesgo)
        PRINT 'Regla # Operaciones al Mes - RETIROS EFECTIVO TOTAL - resultado_riesgo:' + convert(varchar(50), @w_retiro_sum)	
    --------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- EJECUCION Compra-venta divisas
        select @w_result_values = ''
        select @w_nivel_obtenido = 'BAJO'
        select @w_cv_divisas = 'COMPRA DE DIVISAS'
    
    	-- Calculo de Numero de Operaciones para COMPRA DE DIVISAS
    	select @w_valor_variable_regla = convert(varchar(250), @w_cv_divisas) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_cv_divisas
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
       
        PRINT '---------------------------XXXXX-w_result_values:'+ convert(varchar,@w_result_values)
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla # Operaciones al Mes - COMPRA DE DIVISAS - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	select @w_cv_divisas_sum = @w_resultado_riesgo
    --------------------------------------------------------------------------------------------------------------------------------------------
        select @w_cv_divisas = 'VENTA DE DIVISAS'
    
    	-- Calculo de Numero de Operaciones para VENTA DE DIVISAS
    	select @w_valor_variable_regla = convert(varchar(250), @w_cv_divisas) + '|' + convert(varchar(250), @w_nivel_obtenido)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'NUMOPMES',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'NUMOPMES' + ' '+ @w_cv_divisas
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
    		--goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
       
        PRINT '---------------------------XXXXX-w_result_values:'+ convert(varchar,@w_result_values)
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla # Operaciones al Mes - VENTA DE DIVISAS - NUMOPMES - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	
    	select @w_cv_divisas_sum = convert(int,@w_cv_divisas_sum) + convert(int,@w_resultado_riesgo)
        PRINT 'Regla # Operaciones al Mes - Compra-venta divisas - resultado_riesgo:' + convert(varchar(50), @w_cv_divisas_sum)	
    -------------------------------------------------------------------------------------------------------------------------------------------- 	
    -- Resultado para mostrar - Compra-venta divisas
    
        select @w_nivel_obtenido = ''
    	-- Calculo de Nivel de Riesgo
    	select @w_valor_variable_regla = convert(varchar(250), @w_trans_internacionales_sum)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'COMVENTDIV',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'COMVENTDIV'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
       
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla Compra Venta Divisas - COMVENTDIV - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)
    	
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                               values ( @i_ente,    '010',       @w_nivel_obtenido, convert(int ,@w_cv_divisas_sum))	
    										   
    ------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------
    -- EJECUCION Transaccionalidad
        select @w_nivel_obtenido = ''
    	-- Calculo de Nivel de Riesgo
    	select @w_transaccionalidad_sum = convert(int,@w_trans_nacionales_sum) +
    	                                  convert(int,@w_deposito_sum) + convert(int,@w_retiro_sum) 
        PRINT 'Regla Transaccionalidad - TRANSDAD - transaccionalidad_sum:' + convert(varchar(50), @w_transaccionalidad_sum)									  
    	select @w_valor_variable_regla = convert(varchar(250), @w_transaccionalidad_sum)
    	PRINT '---------------------------XXXXX-w_valor_variable_regla:'+ convert(varchar(250),@w_valor_variable_regla)
        exec @w_error                   = cob_pac..sp_rules_param_run
             @s_rol                     = @s_rol,
    	     @i_rule_mnemonic           = 'TRANSDAD',
    	     @i_var_values              = @w_valor_variable_regla,
    	     @i_var_separator           = '|',
    	     @o_return_variable         = @w_variables     out,
    	     @o_return_results          = @w_result_values out,
    	     @o_last_condition_parent   = @w_parent        out
    		 
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'TRANSDAD'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)			
            --goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
       
        select @w_nivel_obtenido   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
    	PRINT 'Regla Transaccionalidad - TRANSDAD - nivel_obtenido:' + convert(varchar(50), @w_nivel_obtenido)
    	
        insert into cob_credito..cr_matriz_riesgo_cli_tmp ( mr_cliente, mr_variable, mr_nivel,          mr_puntaje)
                                               values ( @i_ente,    '011',       @w_nivel_obtenido, convert(int ,@w_transaccionalidad_sum))  
    
    ------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------
    --Ejecucion de regla calculo de nivel de riesgo
        select @w_resul_rango_calif      = sum(mr_puntaje)
    	from   cob_credito..cr_matriz_riesgo_cli_tmp 
        where  mr_cliente  = @i_ente
    	
        /*RESUTLADO DE LA REGLA*/	
       SELECT @w_valor_variable_regla  = @w_resul_rango_calif
       exec   @w_error                 = cob_pac..sp_rules_param_run
          @s_rol                   = @s_rol,
    	      @i_rule_mnemonic         = 'CALFRISK',
    	      @i_var_values            = @w_valor_variable_regla, 
    	      @i_var_separator         = '|',
    	      @o_return_variable       = @w_variables     out,
    	      @o_return_results        = @w_result_values out,
    	      @o_last_condition_parent = @w_parent  out
    		
        if @w_error != 0
        begin
			select @o_error_mens = @w_msm_advertencia+' '+ @w_mensaje_fallo_regla +' '+ rl_name from cob_pac..bpl_rule WHERE rl_acronym = 'CALFRISK'
			print  convert(varchar(255),@o_error_mens) + ' para cliente ' + convert(varchar, @i_ente)
    		--goto ERROR
        end
           	
        if @w_result_values is null
        begin
            select @w_result_values = '0|0'
        end
    
        select @w_resultado_riesgo   = replace(convert(varchar, substring(@w_result_values, 1, charindex('|', @w_result_values) - 1)),'|','')
         
        PRINT 'Regla Calificación Riesgo - CALFRISK - resultado_riesgo:' + convert(varchar(50), @w_resultado_riesgo)
    	
    	update cobis..cl_ente_aux
    	set    ea_nivel_riesgo   = @w_resultado_riesgo,
    	       ea_puntaje_riesgo = @w_resul_rango_calif
        where  ea_ente = @i_ente
    
        if @@error <> 0
        begin   
            select @w_num_error = 103163 --Error al actualizar resultado de riesgo
            goto ERROR
        end	
    end
    --output nivel de riesgo
    if(@w_ejecutar_regla = 'S')
	begin
    select @w_cli_a3ccc        = pa_char FROM cobis..cl_parametro WHERE pa_nemonico ='CA3CCC' AND pa_producto='CLI'
    select @w_cli_a3bloq       = pa_char FROM cobis..cl_parametro WHERE pa_nemonico ='CA3BLO' AND pa_producto='CLI'
    select @w_cli_condicionado = pa_char FROM cobis..cl_parametro WHERE pa_nemonico ='CLICON' AND pa_producto='CLI'


        select @w_msm_ea_nivel_riesgo=ea_nivel_riesgo from cobis..cl_ente_aux where  ea_ente = @i_ente
        
        if(replace(@w_msm_ea_nivel_riesgo,' ','')=replace(@w_cli_a3ccc,' ','') or replace(@w_msm_ea_nivel_riesgo,' ','')=replace(@w_cli_a3bloq,' ',''))
            begin
		    exec cobis..sp_cliente_condicionado
		    @i_ente       =@i_ente
        
            end
        end
	
	/* INSERT NUMERO Y MONTO DE OPERACIONES Y*/
	
	if(@w_ejecutar_regla = 'S')
	begin
	    if exists(select 1 from cob_credito..cr_monto_num_riesgo where mnr_ente = @i_ente)
    	begin
    	    delete cob_credito..cr_monto_num_riesgo where mnr_ente = @i_ente
    	end
	    
	    insert into cob_credito..cr_monto_num_riesgo 
    	values (@i_ente,                    @w_resul_numero_env,                @w_resul_monto_env,                 @w_resul_numero_rec,
    	        @w_resul_monto_rec,         @w_resul_numero_dep_efec,           @w_resul_monto_dep_efec,	        @w_resul_numero_dep_noefec,
    	        @w_resul_monto_dep_noefec)
	    
	end
	
	
end --Fin opcion I

if @i_operacion = 'Q'
begin	
    select 'Actividad'  =  (select valor from cobis..cl_catalogo where tabla = @w_catalogo_cre_des_riesgo and codigo = mr_variable ),
           'Nivel' 		=   mr_nivel,
           'Puntaje' 	=   mr_puntaje
    from   cob_credito..cr_matriz_riesgo_cli_tmp
    where mr_cliente 		= @i_ente    

    select 'Puntaje'      = sum(mr_puntaje), 
           'Calificacion' = ea_nivel_riesgo
    from   cob_credito..cr_matriz_riesgo_cli_tmp, cobis..cl_ente_aux
    where  ea_ente =  mr_cliente
    and    mr_cliente  = @i_ente
    group by ea_nivel_riesgo	
	
end

return 0

ERROR:
    begin --Devolver mensaje de Error 
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = @w_error
    return @w_error
    end
GO
