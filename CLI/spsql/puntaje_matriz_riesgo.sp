/************************************************************************/
/*  Archivo:                puntaje_matriz_riesgo.sp                    */
/*  Stored procedure:       sp_puntaje_matriz_riesgo                    */
/*  Base de datos:          cobis                                       */
/*  Producto:               Clientes                                    */
/*  Disenado por:                                                       */
/*  Fecha de escritura:                                                 */
/************************************************************************/
/*                            IMPORTANTE                                */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA", representantes exclusivos para el Ecuador de la           */
/*  "NCR CORPORATION".                                                  */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Obtiene el puntaje para la matriz de riesgo                         */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA           AUTOR     RAZON                                     */
/*  23-Dic-2020     EGL       Emision inicial                           */
/*  08-Feb-2021     EGL       Puntaje Servicios                         */
/*  17-Feb-2021     EGL       Parametros de sistema y validacion trn    */
/*  20-Feb-2021     EGL       Registro de historico solo cuando cambia  */
/*  23-Feb-2021     MGB       Cambio en converts de decimal a float     */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where name = 'sp_puntaje_matriz_riesgo')
   drop procedure sp_puntaje_matriz_riesgo
go
create procedure sp_puntaje_matriz_riesgo (
	  @s_ssn							int				= null
	, @s_user							login			= null
	, @s_term							varchar(32)		= null
	, @s_date							datetime		= null
	, @s_srv							varchar(30)		= null
	, @s_lsrv							varchar(30)		= null
	, @s_rol							smallint		= null
	, @s_ofi							smallint		= null
	, @s_org_err						char(1)			= null
	, @s_error							int				= null
	, @s_sev							tinyint			= null
	, @s_msg							descripcion		= null
	, @s_org							char(1)			= null
	, @s_culture						varchar(10)		= 'NEUTRAL'
	, @t_trn							int				= 172168
	, @t_debug							char(1)			= 'N'
	, @t_file							varchar(14)		= null
	, @t_from							varchar(30)		= null
	, @t_show_version					bit				= 0
	, @i_ente							int				= null
	, @i_operacion						char(1)			= 'I'
)                                              
											   
as

-- DECLARACION DE PARAMETROS GLOBALES
declare
	  @w_sp_name						varchar(32)
	, @w_sp_msg							varchar(130)

-- INICIALIZACION DE PARAMETROS GLOBALES
select 
	  @w_sp_name			= 'sp_puntaje_matriz_riesgo'

-- VERSIONAMIENTO DEL PROGRAMA
if @t_show_version = 1
begin
	select @w_sp_msg = concat('Stored procedure ' , @w_sp_name, ' Version 4.0.0.0')
	print  @w_sp_msg
	return 0
end

---- EJECUTAR SP DE LA CULTURA
exec cobis..sp_ad_establece_cultura
	@o_culture = @s_culture out

-- VALIDACION DE TRN
if (@t_trn <> 172168 and @i_operacion = 'I') -- 172168: INSERTAR PUNTAJE DE EVALUACION DE MATRIZ DE RIESGOS
begin 
	exec cobis..sp_cerror 		
		@s_culture = @s_culture,
        @t_debug = @t_debug, 
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1720275 -- ERROR: TIPO DE TRANSACCION NO CORRESPONDE
   return 1
end  

if @i_operacion = "I"    
begin                                  
												
	declare 		
		  @w_ente							int
		, @w_tipo_persona					char(1)
		, @w_genero							char(2)
		, @w_fecha_nac						datetime
		, @w_edad							int
		, @w_nacionalidad					int
		, @w_provincia_nac					int
		, @w_tipo_residencia_mex			char(10) -- SE DEBE CONSIDERAR ESTE DATO UNA VEZ AGREGADO DESDE EL FRONTEND
		, @w_actividad_ec					char(10)
		, @w_actividad_fo					char(1)
		, @w_persona_pep					char(1)
		, @w_persona_pb 					char(1)  -- SE DEBE CONSIDERAR ESTE DATO UNA VEZ SE INDIQUE LAS CONDICIONES PARA BLOQUEAR DE LISTAS NEGRAS POR EL SISTEMA FINANCIERO MEXICANO
		, @w_dependencia					varchar(10)
		, @w_nivel_puesto					varchar(10)
		, @w_ingresos						varchar(10)
		, @w_rule_mnemonic					varchar(10)
		, @w_variable						varchar(1000)
		, @w_gpo_matriz_riesgo				varchar(10)
		, @w_variables						varchar(255)	
		, @w_result_values					varchar(255)
		, @w_last_condition_parent			varchar(1000)
		, @w_delimitador					char(1)
		, @w_posicion						smallint
		, @w_posicion_anterior				smallint
		, @w_cont_ptos_x_var				decimal(5,1)
		, @w_cont_ptos						decimal(5,1)
		, @w_puntaje_ant					decimal(5,1)
		, @w_ponederacion					decimal(5,2)
		, @w_ponederacion_ant				decimal(5,2)
		, @w_detalle						varchar(100)
		, @w_cat_num_trn_mes_ini			varchar(10) 
		, @w_cat_mto_trn_mes_ini			varchar(10) 
		, @w_cat_sdo_prom_mes_ini			varchar(10) 	
		, @w_param_pmrcnp					tinyint
		, @w_param_pmrcar					tinyint
		, @w_param_pmrsia					tinyint
		, @w_param_pmrvva					tinyint
		, @w_param_pmrrri					tinyint
		, @w_param_pmrsei					tinyint
		, @w_param_pmrdpt					tinyint
		, @w_cod_servicio					varchar(10)
		, @w_det_servicio					varchar(50)
		, @w_porcentaje_serv				float
		, @w_date_diff						datetime
	
	-- INICIAR VARIABLES DE TRABAJO
	select
		@w_sp_name = 'sp_puntaje_matriz_riesgo'
		, @w_ente = @i_ente
		, @w_delimitador = '|'
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_cont_ptos = 0
		, @w_ponederacion = 0
	
	-- PASAR LOS DATOS DE CLIENTE
	select	
		@w_tipo_persona     		= en_subtipo
		, @w_genero					= p_genero
		, @w_fecha_nac				= p_fecha_nac	
		, @w_nacionalidad			= en_nacionalidad
		, @w_tipo_residencia_mex 	= null -- SE DEBE CONSIDERAR ESTE DATO UNA VEZ AGREGADO DESDE EL FRONTEND
		, @w_actividad_ec			= en_actividad
		, @w_actividad_fo			= ea_actividad_legal
		, @w_persona_pep			= en_persona_pep
		, @w_persona_pb 			= null -- SE DEBE CONSIDERAR ESTE DATO UNA VEZ SE INDIQUE LAS CONDICIONES PARA BLOQUEAR DE LISTAS NEGRAS POR EL SISTEMA FINANCIERO MEXICANO
		, @w_provincia_nac			= en_provincia_nac	
		, @w_dependencia			= p_rel_carg_pub
		, @w_nivel_puesto			= p_carg_pub
		, @w_ingresos				= en_ingre
	from	cobis..cl_ente 
	inner join cobis..cl_ente_aux on ea_ente = en_ente
	where	en_ente = @w_ente
	
	-- SE OBTIENE LA EDAD A PARTIR DE LA FECHA DE NACIMIENTO
	if @w_fecha_nac is not null
	begin

		select @w_date_diff = DATEADD(YY,DATEDIFF(YEAR, @w_fecha_nac,GETDATE()), @w_fecha_nac)

		if(@w_date_diff > GETDATE())
		begin
			select @w_edad = DATEDIFF(YEAR, @w_fecha_nac, GETDATE()) - 1
		end
		else
		begin
			select @w_edad = DATEDIFF(YEAR, @w_fecha_nac, GETDATE())
		end
		
	end
	
	-- OBTENER PARAMETRO MATRIZ RIESGO - CANALES DE ENVIO NO PRESENCIALES
	select @w_param_pmrcnp = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'CLI'
	and pa_nemonico = 'PMRCNP'
	
	-- OBTENER PARAMETRO MATRIZ RIESGO - CANALES DE ACCESO INMEDIATO A LOS RECURSOS
	select @w_param_pmrcar = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'CLI'
	and pa_nemonico = 'PMRCAR'
	
	-- OBTENER PARAMETRO MATRIZ RIESGO - SISTEMA AUTOMATIZADO
	select @w_param_pmrsia = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'CLI'
	and pa_nemonico = 'PMRSIA'
	
	-- OBTENER PARAMETRO MATRIZ RIESGO - VALIDACION Y VERIFICACION AUTOMATIZADA
	select @w_param_pmrvva = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'CLI'
	and pa_nemonico = 'PMRVVA'
	
	-- OBTENER PARAMETRO MATRIZ RIESGO - RESPALDO Y RESGUARDO DE INFORMACION
	select @w_param_pmrrri = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'CLI'
	and pa_nemonico = 'PMRRRI'
	
	-- OBTENER PARAMETRO MATRIZ RIESGO - SEGURIDAD INFORMATICA
	select @w_param_pmrsei = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'CLI'
	and pa_nemonico = 'PMRSEI'
	
	-- OBTENER PARAMETRO MATRIZ RIESGO - DESPERFECTO DE LA PLATAFORMA TECNOLOGICA
	select @w_param_pmrdpt = pa_tinyint
	from cobis..cl_parametro
	where pa_producto = 'CLI'
	and pa_nemonico = 'PMRDPT'
	
	-- OBTENER DATOS DE TRANSACCIONES
	select
		@w_cat_num_trn_mes_ini		= itr_cat_num_trn_mes_ini
		, @w_cat_mto_trn_mes_ini	= itr_cat_mto_trn_mes_ini
		, @w_cat_sdo_prom_mes_ini	= itr_cat_sdo_prom_mes_ini
	from	cobis..cl_info_trn_riesgo 
	where	itr_ente = @w_ente
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE Y SERVICIOS DINÁMICOS RUBRO SERVICIOS
	------------------------------------------------------------------------------------------------------------------------------
	
	select @w_porcentaje_serv = 0
	
	declare servicios_cursor cursor for 
	select C.codigo, C.valor
	from cobis..cl_catalogo C 
	inner join cobis..cl_tabla T on C.tabla = T.codigo 
	where T.tabla = 'cl_mr_servicios' 
	order by codigo
	
	open servicios_cursor
	fetch next from servicios_cursor
	into @w_cod_servicio, @w_det_servicio
	
	while @@fetch_status = 0
	begin
		
		select @w_porcentaje_serv = es_porcentaje 
		from cl_mr_ente_servicios
		where es_estado = 'V'
		and es_ente = @w_ente
		and es_servicio = @w_cod_servicio
		
		select 
			  @w_rule_mnemonic = @w_cod_servicio
			, @w_variable = @w_porcentaje_serv
			, @w_gpo_matriz_riesgo = 'GSE'
			, @w_detalle = 'El dato para ' + @w_det_servicio + ' es nulo'
			, @w_ponederacion = @w_porcentaje_serv
		
		if @w_tipo_persona is not null
		begin
			select @w_detalle = 'No existen resultados para la regla ' + @w_det_servicio
			
			exec cob_pac..sp_rules_param_run
				@i_rule_mnemonic         = @w_rule_mnemonic,
				@i_var_values            = @w_variable,
				@i_var_separator         = @w_delimitador,
				@o_return_variable       = @w_variables  out,
				@o_return_results        = @w_result_values   out,
				@o_last_condition_parent = @w_last_condition_parent out
				
			if @w_result_values is not null
			begin
				select @w_detalle = 'OK'
				select @w_result_values = ltrim(rtrim(@w_result_values))
				select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
				if @w_posicion > 0
				begin
					select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))			
				end	
			end
		end
		
		select 
			  @w_puntaje_ant = pmr_puntaje
			, @w_ponederacion_ant = pmr_ponderacion
		from cobis..cl_ptos_matriz_riesgo 
		where pmr_estado = 'V' 
		and pmr_ente = @w_ente 
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
		begin
			update cobis..cl_ptos_matriz_riesgo
			set pmr_estado = 'C'
			where pmr_ente = @w_ente
			and pmr_regla_acronimo = @w_rule_mnemonic
			
			insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
				values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
		end
	
		select 
			@w_variable = ''
			, @w_gpo_matriz_riesgo = ''
			, @w_posicion = 0
			, @w_posicion_anterior =0
			, @w_cont_ptos_x_var = 0
			, @w_ponederacion = 0
			, @w_result_values = null		
			, @w_porcentaje_serv = 0
	
		fetch next from servicios_cursor
		into @w_cod_servicio, @w_det_servicio
	end
	close servicios_cursor
	deallocate servicios_cursor	
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[TIPE] 		TIPO PERSONA
	-- REGLA: 		[RTIPE] 	TIPO PERSONA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RTIPE'
		, @w_variable = @w_tipo_persona
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para TIPO PERSONA es nulo'
		
	if @w_tipo_persona is not null
	begin	
		select @w_detalle = 'No existen resultados para la regla TIPO PERSONA'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end	
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null	
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[GENE] 		GENERO
	-- REGLA: 		[RGENE] 	GENERO
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RGENE'
		, @w_variable = @w_genero
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para GENERO es nulo'
	
	if @w_genero is not null
	begin	
		select @w_detalle = 'No existen resultados para la regla GENERO'
	
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null	
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[EDAD] 		EDAD
	-- REGLA: 		[REDAD] 	EDAD
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'REDAD'
		, @w_variable = @w_edad
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para EDAD es nulo'
	
	if @w_edad is not null
	begin
		select @w_detalle = 'No existen resultados para la regla EDAD'
	
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null	
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[NACI] 		NACIONALIDAD
	-- REGLA: 		[RNACI] 	NACIONALIDAD
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RNACI'
		, @w_variable = @w_nacionalidad
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para NACIONALIDAD es nulo'
	
	if @w_nacionalidad is not null
	begin
		select @w_detalle = 'No existen resultados para la regla NACIONALIDAD'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[REME] 		RESIDENTE MEXICO
	-- REGLA: 		[RREME] 	RESIDENTE MEXICO
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RREME'
		, @w_variable = @w_tipo_residencia_mex
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para RESIDENTE MEXICO es nulo'
	
	if @w_tipo_residencia_mex is not null
	begin
		select @w_detalle = 'No existen resultados para la regla RESIDENTE MEXICO'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[ACEP] 		ACTIVIDAD ECONOMICA PRINCIPAL
	-- REGLA: 		[RACEP] 	ACTIVIDAD ECONOMICA PRINCIPAL
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RACEP'
		, @w_variable = @w_actividad_ec
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para ACTIVIDAD ECONOMICA PRINCIPAL es nulo'
	
	if @w_actividad_ec is not null
	begin
		select @w_detalle = 'No existen resultados para la regla ACTIVIDAD ECONOMICA PRINCIPAL'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[ACFO] 		ACTIVIDAD FORMAL
	-- REGLA: 		[RACFO] 	ACTIVIDAD FORMAL
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RACFO'
		, @w_variable = @w_actividad_fo
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para ACTIVIDAD FORMAL es nulo'
	
	if @w_actividad_fo is not null
	begin
		select @w_detalle = 'No existen resultados para la regla ACTIVIDAD FORMAL'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[POEX] 		POLITICAMENTE EXPUESTA
	-- REGLA: 		[RPOEX] 	POLITICAMENTE EXPUESTA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RPOEX'
		, @w_variable = @w_persona_pep
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para POLITICAMENTE EXPUESTA es nulo'
	
	if @w_persona_pep is not null
	begin
		select @w_detalle = 'No existen resultados para la regla POLITICAMENTE EXPUESTA'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[PRBL] 		PREVIAMENTE BLOQUEADA
	-- REGLA: 		[RPRBL] 	PREVIAMENTE BLOQUEADA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RPRBL'
		, @w_variable = @w_persona_pb
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para PREVIAMENTE BLOQUEADA es nulo'
	
	if @w_persona_pb is not null
	begin
		select @w_detalle = 'No existen resultados para la regla PREVIAMENTE BLOQUEADA'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[DEPE] 		DEPENDENCIA PPE
	-- REGLA: 		[RDEPE] 	DEPENDENCIA PPE
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RDEPE'
		, @w_variable = @w_dependencia
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para DEPENDENCIA PPE es nulo'
	
	if @w_dependencia is not null
	begin
		select @w_detalle = 'No existen resultados para la regla DEPENDENCIA PPE'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))			
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[NIPU] 		NIVEL PUESTO PPE
	-- REGLA: 		[RNIPU] 	NIVEL PUESTO PPE
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RNIPU'
		, @w_variable = @w_nivel_puesto
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para NIVEL PUESTO PPE es nulo'
	
	if @w_nivel_puesto is not null
	begin
		select @w_detalle = 'No existen resultados para la regla NIVEL PUESTO PPE'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))			
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[INBM] 		INGRESOS BRUTOS MENSUALES PPE
	-- REGLA: 		[RINBM] 	INGRESOS BRUTOS MENSUALES PPE
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RINBM'
		, @w_variable = @w_ingresos
		, @w_gpo_matriz_riesgo = 'GCL'
		, @w_detalle = 'El dato para INGRESOS BRUTOS MENSUALES PPE es nulo'
	
	if @w_ingresos is not null
	begin
		select @w_detalle = 'No existen resultados para la regla INGRESOS BRUTOS MENSUALES PPE'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))			
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[NAPF] 		NACIONALES PUERTO FRONTERA
	-- REGLA: 		[RNAPF] 	NACIONALES PUERTO FRONTERA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RNAPF'
		, @w_variable = @w_provincia_nac
		, @w_gpo_matriz_riesgo = 'GAG'
		, @w_detalle = 'El dato para NACIONALES PUERTO FRONTERA es nulo'
	
	if @w_provincia_nac is not null
	begin
		select @w_detalle = 'No existen resultados para la regla NACIONALES PUERTO FRONTERA'	
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[NAAD] 		NACIONALES ACTIVIDAD DELICTIVA
	-- REGLA: 		[RNAAD] 	NACIONALES ACTIVIDAD DELICTIVA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RNAAD'
		, @w_variable = @w_provincia_nac
		, @w_gpo_matriz_riesgo = 'GAG'
		, @w_detalle = 'El dato para NACIONALES ACTIVIDAD DELICTIVA es nulo'
	
	if @w_provincia_nac is not null
	begin
		select @w_detalle = 'No existen resultados para la regla NACIONALES ACTIVIDAD DELICTIVA'	
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[PRFP] 		PAISES REGIMEN FISCAL PREFERENTE
	-- REGLA: 		[RPRFP] 	PAISES REGIMEN FISCAL PREFERENTE
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RPRFP'
		, @w_variable = @w_nacionalidad
		, @w_gpo_matriz_riesgo = 'GAG'
		, @w_detalle = 'El dato para PAISES REGIMEN FISCAL PREFERENTE es nulo'
	
	if @w_nacionalidad is not null
	begin
		select @w_detalle = 'No existen resultados para la regla PAISES REGIMEN FISCAL PREFERENTE'	
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[PPLD] 		PAISES DEFICIENTE SUPERVISION PLD
	-- REGLA: 		[RPPLD] 	PAISES DEFICIENTE SUPERVISION PLD
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RPPLD'
		, @w_variable = @w_nacionalidad
		, @w_gpo_matriz_riesgo = 'GAG'
		, @w_detalle = 'El dato para PAISES DEFICIENTE SUPERVISION PLD es nulo'
	
	if @w_nacionalidad is not null
	begin
		select @w_detalle = 'No existen resultados para la regla PAISES DEFICIENTE SUPERVISION PLD'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[PAAT] 		PAISES ACTIVIDAD TERRORISTA
	-- REGLA: 		[RPAAT] 	PAISES ACTIVIDAD TERRORISTA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RPAAT'
		, @w_variable = @w_nacionalidad
		, @w_gpo_matriz_riesgo = 'GAG'
		, @w_detalle = 'El dato para PAISES ACTIVIDAD TERRORISTA es nulo'
	
	if @w_nacionalidad is not null
	begin
		select @w_detalle = 'No existen resultados para la regla PAISES ACTIVIDAD TERRORISTA'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null	
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[PAAD] 		PAISES ACTIVIDAD DELICTIVA
	-- REGLA: 		[RPAAD] 	PAISES ACTIVIDAD DELICTIVA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RPAAD'
		, @w_variable = @w_nacionalidad
		, @w_gpo_matriz_riesgo = 'GAG'
		, @w_detalle = 'El dato para PAISES ACTIVIDAD DELICTIVA es nulo'
	
	if @w_nacionalidad is not null
	begin
		select @w_detalle = 'No existen resultados para la regla PAISES ACTIVIDAD DELICTIVA'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[CENP] 		CANALES ENVIO PRESENCIALES
	-- REGLA: 		[RCENP] 	CANALES ENVIO PRESENCIALES
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RCENP'
		, @w_variable = @w_param_pmrcnp
		, @w_gpo_matriz_riesgo = 'GTC'
		, @w_detalle = 'El dato para CANALES ENVIO PRESENCIALES es nulo'
	
	if @w_param_pmrcnp is not null
	begin
		select @w_detalle = 'No existen resultados para la regla CANALES ENVIO PRESENCIALES'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = @w_param_pmrcnp	
				select @w_ponederacion = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[CAIR] 		CANALES ACCESO INMEDIATO RECURSOS
	-- REGLA: 		[RCAIR] 	CANALES ACCESO INMEDIATO RECURSOS
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RCAIR'
		, @w_variable = @w_param_pmrcar
		, @w_gpo_matriz_riesgo = 'GTC'
		, @w_detalle = 'El dato para CANALES ACCESO INMEDIATO RECURSOS es nulo'
	
	if @w_param_pmrcar is not null
	begin
		select @w_detalle = 'No existen resultados para la regla CANALES ACCESO INMEDIATO RECURSOS'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = @w_param_pmrcar	
				select @w_ponederacion = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0	
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[NUTM] 		NUMERO TRANSACCIONES MENSUAL
	-- REGLA: 		[RNUTM] 	NUMERO TRANSACCIONES MENSUAL
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RNUTM'
		, @w_variable = @w_cat_num_trn_mes_ini
		, @w_gpo_matriz_riesgo = 'GTC'
		, @w_detalle = 'El dato para NUMERO TRANSACCIONES MENSUAL es nulo'
		
	if @w_cat_num_trn_mes_ini is not null
	begin	
		select @w_detalle = 'No existen resultados para la regla NUMERO TRANSACCIONES MENSUAL'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end	
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[MOTM] 		MONTO TRANSACCIONES MENSUAL
	-- REGLA: 		[RMOTM] 	MONTO TRANSACCIONES MENSUAL
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RMOTM'
		, @w_variable = @w_cat_mto_trn_mes_ini
		, @w_gpo_matriz_riesgo = 'GTC'
		, @w_detalle = 'El dato para MONTO TRANSACCIONES MENSUAL es nulo'
		
	if @w_cat_mto_trn_mes_ini is not null
	begin	
		select @w_detalle = 'No existen resultados para la regla MONTO TRANSACCIONES MENSUAL'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end	
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[SAPM] 		SALDO PROMEDIO MENSUAL
	-- REGLA: 		[RSAPM] 	SALDO PROMEDIO MENSUAL
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RSAPM'
		, @w_variable = @w_cat_sdo_prom_mes_ini
		, @w_gpo_matriz_riesgo = 'GTC'
		, @w_detalle = 'El dato para SALDO PROMEDIO MENSUAL es nulo'
		
	if @w_cat_sdo_prom_mes_ini is not null
	begin	
		select @w_detalle = 'No existen resultados para la regla SALDO PROMEDIO MENSUAL'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
		
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
				select @w_posicion_anterior = @w_posicion		
				select @w_posicion   = charindex('|', @w_result_values, @w_posicion_anterior + 1)
				select @w_ponederacion = convert(float, substring(@w_result_values, @w_posicion_anterior + 1, (@w_posicion - @w_posicion_anterior) - 1))
			end	
		end	
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		, @w_result_values = null
		
	------------------------------------------------------------------------------------------------------------------------------
	-- ***************************************************************************************************************************
	-- ************************************    P    E    N    D    I    E    N    T    E     *************************************
	-- ***************************************************************************************************************************
	-- VARIABLE:	[TRZF] 		TRANSFERENCIAS ZONA RIESGO
	-- REGLA: 		[RTRZF] 	TRANSFERENCIAS ZONA RIESGO
	------------------------------------------------------------------------------------------------------------------------------
	
	
	
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[SIAU] 		SISTEMA AUTOMATIZADO
	-- REGLA: 		[RSIAU] 	SISTEMA AUTOMATIZADO
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RSIAU'
		, @w_variable = @w_param_pmrsia
		, @w_gpo_matriz_riesgo = 'GIT'
		, @w_detalle = 'El dato para SISTEMA AUTOMATIZADO es nulo'
	
	if @w_param_pmrsia is not null
	begin
		select @w_detalle = 'No existen resultados para la regla SISTEMA AUTOMATIZADO'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = @w_param_pmrsia	
				select @w_ponederacion = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0	
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[VAVA] 		VALIDACION VERIFICACION AUTOMATIZADA
	-- REGLA: 		[RVAVA] 	VALIDACION VERIFICACION AUTOMATIZADA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RVAVA'
		, @w_variable = @w_param_pmrvva
		, @w_gpo_matriz_riesgo = 'GIT'
		, @w_detalle = 'El dato para VALIDACION VERIFICACION AUTOMATIZADA es nulo'
	
	if @w_param_pmrvva is not null
	begin
		select @w_detalle = 'No existen resultados para la regla VALIDACION VERIFICACION AUTOMATIZADA'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = @w_param_pmrvva	
				select @w_ponederacion = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[RERI] 		RESPALDO RESGUARDO INFORMACION
	-- REGLA: 		[RRERI] 	RESPALDO RESGUARDO INFORMACION
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RRERI'
		, @w_variable = @w_param_pmrrri
		, @w_gpo_matriz_riesgo = 'GIT'
		, @w_detalle = 'El dato para RESPALDO RESGUARDO INFORMACION es nulo'
	
	if @w_param_pmrrri is not null
	begin
		select @w_detalle = 'No existen resultados para la regla RESPALDO RESGUARDO INFORMACION'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = @w_param_pmrrri	
				select @w_ponederacion = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[SEIN] 		SEGURIDAD INFORMATICA
	-- REGLA: 		[RSEIN] 	SEGURIDAD INFORMATICA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RSEIN'
		, @w_variable = @w_param_pmrsei
		, @w_gpo_matriz_riesgo = 'GIT'
		, @w_detalle = 'El dato para SEGURIDAD INFORMATICA es nulo'
	
	if @w_param_pmrsei is not null
	begin
		select @w_detalle = 'No existen resultados para la regla SEGURIDAD INFORMATICA'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = @w_param_pmrsei	
				select @w_ponederacion = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end
	
	select 
		@w_variable = ''
		, @w_gpo_matriz_riesgo = ''
		, @w_posicion = 0
		, @w_posicion_anterior =0
		, @w_cont_ptos_x_var = 0
		, @w_ponederacion = 0
		
	------------------------------------------------------------------------------------------------------------------------------
	-- VARIABLE:	[DEPT] 		DESPERFECTO PLATAFORMA TECNOLOGICA
	-- REGLA: 		[RDEPT] 	DESPERFECTO PLATAFORMA TECNOLOGICA
	------------------------------------------------------------------------------------------------------------------------------
	select 
		@w_rule_mnemonic = 'RDEPT'
		, @w_variable = @w_param_pmrdpt
		, @w_gpo_matriz_riesgo = 'GIT'
		, @w_detalle = 'El dato para DESPERFECTO PLATAFORMA TECNOLOGICA es nulo'
	
	if @w_param_pmrdpt is not null
	begin
		select @w_detalle = 'No existen resultados para la regla DESPERFECTO PLATAFORMA TECNOLOGICA'
		
		exec cob_pac..sp_rules_param_run
			@i_rule_mnemonic         = @w_rule_mnemonic,
			@i_var_values            = @w_variable,
			@i_var_separator         = @w_delimitador,
			@o_return_variable       = @w_variables  out,
			@o_return_results        = @w_result_values   out,
			@o_last_condition_parent = @w_last_condition_parent out
	
		if @w_result_values is not null
		begin
			select @w_detalle = 'OK'
			select @w_result_values = ltrim(rtrim(@w_result_values))
			select @w_posicion   = charindex(@w_delimitador, @w_result_values, 1)
			if @w_posicion > 0
			begin
				select @w_cont_ptos_x_var = @w_param_pmrdpt	
				select @w_ponederacion = convert(float, substring(@w_result_values, 1, @w_posicion - 1))
			end	
		end
	end
	
	select 
		  @w_puntaje_ant = pmr_puntaje
		, @w_ponederacion_ant = pmr_ponderacion
	from cobis..cl_ptos_matriz_riesgo 
	where pmr_estado = 'V' 
	and pmr_ente = @w_ente 
	and pmr_regla_acronimo = @w_rule_mnemonic
	
	if @w_puntaje_ant <> @w_cont_ptos_x_var or @w_ponederacion_ant <> @w_ponederacion
	begin
		update cobis..cl_ptos_matriz_riesgo
		set pmr_estado = 'C'
		where pmr_ente = @w_ente
		and pmr_regla_acronimo = @w_rule_mnemonic
		
		insert into cobis..cl_ptos_matriz_riesgo(pmr_ente, pmr_gpo_matriz_riesgo, pmr_regla_acronimo, pmr_puntaje, pmr_ponderacion, pmr_signo, pmr_detalle, pmr_estado, pmr_fecha_registro)
			values (@w_ente, @w_gpo_matriz_riesgo, @w_rule_mnemonic, @w_cont_ptos_x_var, @w_ponederacion, '*', @w_detalle, 'V', getdate())				
	end	                   
	
	return 0
end
go
