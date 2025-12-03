/************************************************************************/
/*  Archivo:                re_verificacion_regla.sp                    */
/*  Stored procedure:       sp_re_verificacion_regla                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
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
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_re_verificacion_regla')
    drop proc sp_re_verificacion_regla
go

CREATE PROC sp_re_verificacion_regla
(	@s_ssn        	INT         = NULL,
	@s_ofi        	SMALLINT    = NULL,
	@s_user       	login       = NULL,
	@s_date       	DATETIME    = NULL,
	@s_srv		   	VARCHAR(30) = NULL,
	@s_term	   		descripcion = NULL,
	@s_rol		   	SMALLINT    = NULL,
	@s_lsrv	   		VARCHAR(30)	= NULL,
	@s_sesn	   		INT 	    = NULL,
	@s_org		   	CHAR(1)     = NULL,
	@s_org_err	    INT 	    = NULL,
	@s_error     	INT 	    = NULL,
	@s_sev        	TINYINT     = NULL,
	@s_msg        	descripcion = NULL,
	@t_rty        	CHAR(1)     = NULL,
	@t_trn        	INT         = NULL,
	@t_debug      	CHAR(1)     = 'N',
	@t_file       	VARCHAR(14) = NULL,
	@t_from       	VARCHAR(30) = NULL,
	--variables
	@i_id_inst_proc	INT,    -- Codigo de instancia del proceso
	@i_id_inst_act 	INT,	-- Codigo instancia de la atividad
	@i_id_empresa	INT,	-- Codigo de la empresa
	@o_id_resultado SMALLINT  OUT
)
AS DECLARE	-- Variables de trabajo
	@w_tramite					INT,
	@w_tr_promocion_grupo		CHAR(1),
	@w_grupo					INT,
	@w_id_regla					INT,
	@w_version_regla			INT,
	@w_var_dias_atraso_grupal	INT,
	@w_miembro					INT,
	@w_emprendedor				VARCHAR(3),
	@w_var_en_nro_ciclo			SMALLINT,
	@w_var_experiencia			VARCHAR(1),
	@w_var_exp_crediticia		VARCHAR(2),
	@w_tr_promocion				CHAR(1),
	@w_resul_ciclo				VARCHAR(30),
	@w_variables				VARCHAR(255),
	@w_result_values			VARCHAR(255),
	@w_monto_max				MONEY,
	@w_monto_min				MONEY,
	@w_parent					INT,
	@w_cli_monto_grupo			VARCHAR(255),
	@w_cli_increm_grupo			VARCHAR(255),
	@w_retorno_val				VARCHAR(255),
    @w_retorno_id				INT,
	@w_numero_linea				INT,
	@w_error					INT,
	@w_monto_ultimo             MONEY

-- Seteo de variables
SELECT @w_numero_linea = 0
PRINT 'Inicia reverificacion Regla--->'
SELECT	@w_tramite	=	io_campo_3,
		@w_grupo	=	io_campo_1
FROM cob_workflow..wf_inst_proceso
WHERE io_id_inst_proc = @i_id_inst_proc

-- Seteo de los id de la regla Incremental
SELECT  @w_id_regla			= R.rl_id,
		@w_version_regla	= rv_id
FROM cob_pac..bpl_rule R
INNER JOIN cob_pac..bpl_rule_version RV on R.rl_id = RV.rl_id
WHERE R.rl_acronym = 'INC_GRP'
AND RV.rv_status = 'PRO'
AND GETDATE() >= RV.rv_date_start
AND GETDATE() <= RV.rv_date_finish

PRINT 'Inicia reverificacion Regla1--->'

-- Consulta los dias de atraso grupal
EXEC	@w_error		= sp_dias_atraso_grupal
		@i_grupo		= @w_grupo,
		@i_ciclos_ant	= 1,
		@i_es_ciclo_ant	= 'S',
		@o_resultado	= @w_var_dias_atraso_grupal OUTPUT 
IF @w_error <> 0
BEGIN
	EXEC	@w_error	= cobis..sp_cerror
			@t_debug	= 'N',
			@t_file		= '',
			@t_from		= 'sp_re_verificacion_regla',
			@i_num		= @w_error
END
PRINT 'Pasa validacion de dias atraso Grupal--->'
--Obtengo la promocion de grupo
SELECT @w_tr_promocion_grupo = tr_promocion 
FROM cob_credito..cr_tramite 
WHERE tr_tramite =@w_tramite

SELECT  @w_tr_promocion_grupo = ISNULL(@w_tr_promocion_grupo,'N')
IF (@w_tr_promocion_grupo = 'S')
BEGIN
	EXEC cob_credito..sp_var_integrantes_original
	@i_id_inst_proc = @i_id_inst_proc,
	@i_id_inst_act = 1,
	@i_id_asig_act = 1,
	@i_id_empresa = 1,
	@i_id_variable = 1
END
PRINT 'Pasa @w_tr_promocion_grupo Grupal--->'
-- Consulta los clientes del trámite
SELECT	@w_miembro  =	0
SELECT	@w_miembro  =	tg_cliente
FROM cob_credito..cr_tramite_grupal
WHERE tg_tramite = @w_tramite
AND tg_participa_ciclo <> 'N'
AND tg_cliente > @w_miembro
ORDER BY tg_cliente ASC

-- Recorre cada cliente
WHILE @@rowcount > 0
BEGIN	-- Inicio WHILE
	-- Inicia Validar Regla Monto Grupal

	-- Consulta tipo de empresario
	PRINT 'Ingresa al While de clientes--->'
	PRINT '@w_miembro clientes--->'+ convert(varchar(50),@w_miembro)
	SELECT @w_var_en_nro_ciclo = en_nro_ciclo
		FROM  cobis..cl_ente
		WHERE  en_ente   = @w_miembro


	-- Setea el número de ciclos de cliente
	IF (@w_var_en_nro_ciclo IS NULL)
	BEGIN
		SELECT @w_var_en_nro_ciclo = 1
	END
	ELSE
	BEGIN
		SELECT @w_var_en_nro_ciclo = @w_var_en_nro_ciclo+1
	END
	
	PRINT '@w_var_en_nro_ciclo clientes--->'+ convert(varchar(50),@w_var_en_nro_ciclo)

	-- Ejecuta la experiencia crediticia del cliente
	EXEC	@w_error		= cob_credito..sp_var_experiencia_crediticia
			@i_id_cliente	= @w_miembro,
			@o_resultado	= @w_var_exp_crediticia OUTPUT
	-- Valida si Existio error 
	IF @w_error <> 0
	BEGIN
		EXEC	@w_error	= cobis..sp_cerror
				@t_debug	= 'N',
				@t_file		= '',
				@t_from		= 'sp_grupal_reglas',
				@i_num		= @w_error
	END

	-- Valida si el cliente esta en la tabla coloca las promociones
	IF (@w_tr_promocion_grupo = 'S')
	BEGIN
		IF EXISTS(SELECT 1 
				FROM cob_credito..cr_grupo_promo_inicio 
				WHERE gpi_tramite=@w_tramite 
				AND gpi_grupo=@w_grupo AND gpi_ente = @w_miembro)
		BEGIN
			SELECT @w_tr_promocion='S' 
		END
		ELSE
		BEGIN
			SELECT @w_tr_promocion='N' 
		END
	END
	ELSE
	BEGIN
		SELECT @w_tr_promocion='N' 
	END
	
	 PRINT 'Promocion final par el  cliente reverificacion --->'+ convert(varchar(50),@w_tr_promocion)

	SELECT @w_variables = ''
	SELECT @w_result_values = ''
	SELECT @w_parent = ''

	-- Setear el resultado del ciclo
	SET @w_resul_ciclo	= ISNULL(@w_tr_promocion,'N')+ '|' + 
                          ISNULL(CONVERT(VARCHAR, @w_var_en_nro_ciclo), '1') + '|' + 
	  				      ISNULL(CONVERT(VARCHAR, @w_var_dias_atraso_grupal), '0') + '|' + 
	  				      ISNULL(@w_var_exp_crediticia,' ')
						  
	Print'@w_resul_ciclo reverificacion'+ convert(VARCHAR(50),@w_resul_ciclo)					  

	-- Ejecución de la regla para Monto Grupal
	EXEC	@w_error					= cob_pac..sp_rules_param_run
			@s_rol						= @s_rol,
			@i_rule_mnemonic			= 'MONTO_GRP',
			@i_var_values				= @w_resul_ciclo, 
			@i_var_separator			= '|',
			@o_return_variable			= @w_variables  OUT,
			@o_return_results			= @w_result_values   OUT,
			@o_last_condition_parent	= @w_parent OUT

	-- Valida si existio error
	IF @w_error <> 0
	BEGIN
		-- Setea los clientes con error al ejecutar la regla
		IF @w_cli_monto_grupo IS NULL
			SELECT @w_cli_monto_grupo = CONVERT(VARCHAR, @w_miembro)
		ELSE
			SELECT @w_cli_monto_grupo = @w_cli_monto_grupo + ',' + CONVERT(VARCHAR, @w_miembro)
	END
	ELSE
	BEGIN	
         PRINT '@w_variables sp_re_verificacion MTGRP'    + convert(VARCHAR(50),@w_variables)
		 PRINT '@w_result_values sp_re_verificacion MTGRP'+ convert(VARCHAR(50),@w_result_values)
		 PRINT '@w_parent sp_re_verificacion MTGRP'       + convert(VARCHAR(50),@w_parent)	
		 PRINT '@w_miembro sp_re_verificacion MTGRP'       + convert(VARCHAR(50),@w_miembro)
		-- Actualiza tabla de registro de datos de la regla
		UPDATE cob_credito..cr_tramite_grupal SET
            tg_monto_max      = ISNULL(tg_monto_max, replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')),
            tg_monto_max_calc = REPLACE(CONVERT(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|',''),
            tg_monto_min_calc = REPLACE(CONVERT(varchar, substring(@w_result_values, 1,   charindex('|', @w_result_values) - 1)),'|','')
        WHERE tg_tramite = @w_tramite
        AND tg_cliente = @w_miembro
		
		-- Valida si existe error
		SELECT @w_error = @@error
        IF @w_error<>0
        BEGIN
            EXEC	@w_error = cobis..sp_cerror
					@t_debug  = 'N',
					@t_file   = '',
					@t_from   = 'sp_grupal_reglas',
					@i_num    = 2110345
        END
		ELSE
		BEGIN		
			IF EXISTS(	SELECT 1 
						FROM cr_tramite_grupal 
						WHERE tg_tramite = @w_tramite 
						AND tg_cliente = @w_miembro
						AND tg_monto != 0)
			BEGIN
			PRINT 'cliente tiene monto !0 MG'
			-- Validaciones de grupo
			IF NOT EXISTS(	SELECT 1 
						FROM cr_tramite_grupal 
						WHERE tg_tramite = @w_tramite 
						AND tg_cliente = @w_miembro
						AND (tg_monto >= tg_monto_min_calc 
						AND tg_monto <= tg_monto_max_calc))
			BEGIN
			
			PRINT 'cliente no cumple regla de Monto Grupal'
				IF @w_cli_monto_grupo IS NULL
				BEGIN
				PRINT '@w_cli_monto_grupo is null en MG'
				PRINT '@w_cli_monto_grupo is null en MG clientes--->'+ convert(varchar(50),@w_miembro)
					SELECT @w_cli_monto_grupo = CONVERT(VARCHAR, @w_miembro)
				END
				ELSE
				BEGIN
				PRINT '@w_cli_monto_grupo is  not null en MG'
				PRINT '@w_cli_monto_grupo is  not  null en MG clientes--->'+ convert(varchar(50),@w_miembro)
					SELECT @w_cli_monto_grupo = @w_cli_monto_grupo + ',' + CONVERT(VARCHAR, @w_miembro)
			END
		END
	END
	END
	END

 PRINT 'Inicia Incremento Grupal' 
 PRINT '@w_miembro clientes IG--->'+ convert(varchar(50),@w_miembro)
	-- Finaliza Validar Regla Monto Grupal

	-- Inicia Validar Regla Incremento Grupal

	-- Setea variable 
	SELECT	@w_resul_ciclo = NULL

	-- Ejecuta variable por regla
	EXEC	@w_error			= cob_pac..sp_exec_variable_by_rule
			@s_ssn				= @s_ssn,
			@s_sesn				= @s_sesn,
			@s_user				= @s_user,
			@s_term				= @s_term,
			@s_date				= @s_date,
			@s_srv				= @s_srv,
			@s_lsrv				= @s_lsrv,
			@s_ofi				= @s_ofi,
			@t_file				= NULL,
			@s_rol				= @s_rol,
			@s_org_err			= NULL,
			@s_error			= NULL,
			@s_msg				= NULL,
			@s_org				= '',
			@s_culture			= 'ES_EC',
			@t_rty				= '',
			@t_trn				= @t_trn,
			@t_show_version		= 0,
			@i_id_inst_proc		= @i_id_inst_proc,
			@i_id_inst_act		= 0,
			@i_id_asig_act		= 0,
			@i_id_empresa		= 1,
			@i_acronimo_regla	= 'INC_GRP',
			@i_var_nombre		= 'NROCLIND',
			@o_resultado		= @w_resul_ciclo  OUT
			
	-- Valida si el ciclo es mayor a uno volver a ejecutar
	IF @w_resul_ciclo > 1 
	BEGIN
		-- Ejecuta la variable por regla
		EXEC	@w_error			= cob_pac..sp_exec_variable_by_rule
				@s_ssn				= @s_ssn,
				@s_sesn				= @s_sesn,
				@s_user				= @s_user,
				@s_term				= @s_term,
				@s_date				= @s_date,
				@s_srv				= @s_srv,
				@s_lsrv				= @s_lsrv,
				@s_ofi				= @s_ofi,
				@t_file				= NULL,
				@s_rol				= @s_rol,
				@s_org_err			= NULL,
				@s_error			= NULL,
				@s_msg				= NULL,
				@s_org				= '',
				@s_culture			= 'ES_EC',
				@t_rty				= '',
				@t_trn				= @t_trn,
				@t_show_version		= 0,
				@i_id_inst_proc		= @i_id_inst_proc,
				@i_id_inst_act		= 0,
				@i_id_asig_act		= 0,
				@i_id_empresa		= 1,
				@i_acronimo_regla	= 'INC_GRP'
		
		-- Seteo de variables para la regla
		SELECT	@w_retorno_val		= '0',
				@w_retorno_id		= 0,
				@w_variables		= '',
				@w_result_values	= ''
				
		-- Ejecutar Regla
		EXEC	@w_error           = cob_pac..sp_rules_run
	            @s_ssn             = @s_ssn,
	            @s_sesn            = @s_sesn,
	            @s_user            = @s_user,
	            @s_term            = @s_term,
	            @s_date            = @s_date,
	            @s_srv             = @s_srv,
	            @s_lsrv            = @s_lsrv,
	            @s_ofi             = 1,
	            @s_rol             = 3,
	            @t_trn             = 1111,
	            @i_status          = 'V',
	            @i_id_inst_proceso = @i_id_inst_proc,
	            @i_code_rule       = @w_id_regla,
	            @i_version         = @w_version_regla,
	            @o_return_value    = @w_retorno_val   out,
	            @o_return_code     = @w_retorno_id    out,
	            @o_return_variable = @w_variables     out,
	            @o_return_results  = @w_result_values out,
	            @i_mode            = 'WFL',
	            @i_abreviature      = null,
	            @i_simulator       = 'N',
	            @i_nivel           =  0,
	            @i_modo            = 'S'

		-- Valida si existio error
		IF @w_error <> 0
		BEGIN
			-- Setea los clientes con error al ejecutar la regla
			IF @w_cli_increm_grupo IS NULL
				SELECT @w_cli_increm_grupo = CONVERT(VARCHAR, @w_miembro)
			ELSE
				SELECT @w_cli_increm_grupo = @w_cli_increm_grupo + ',' + CONVERT(VARCHAR, @w_miembro)
		END
		ELSE
		BEGIN
		PRINT '@w_retorno_val reverificacion IG:'+ convert(VARCHAR(50),@w_retorno_val)
		PRINT '@w_result_values reverificacion INGRP: '+convert(varchar, @w_result_values)
		    SELECT TOP 1 @w_monto_ultimo = op_monto
	        FROM cob_cartera..ca_operacion ,cob_cartera..ca_estado
	        WHERE op_cliente = @w_miembro
	        AND op_estado= es_codigo
	        AND (es_procesa='S' OR op_estado = 3)
	        ORDER BY op_operacion DESC
	        SELECT @w_monto_ultimo = isnull(@w_monto_ultimo,0)
			PRINT 'w_monto_ultimo reverificacion INGRP: '+convert(varchar, @w_monto_ultimo)
		END
	END	
	ELSE
	BEGIN
	        --PRINT '--------- 100'
	        SELECT @w_retorno_val = 100
	        SELECT @w_monto_ultimo = 999999999
	END
	
     PRINT '@w_retorno_val reverificacion IG1:'+ convert(VARCHAR(50),@w_retorno_val)
	 PRINT 'w_monto_ultimo reverificacion INGRP1: '+convert(varchar, @w_monto_ultimo)
	 PRINT '@w_miembroIG1-->'+ convert(VARCHAR(50),@w_miembro)
	 
	    UPDATE cob_credito..cr_tramite_grupal SET
            tg_incremento = convert(numeric(8,4), @w_retorno_val),
            tg_monto_ult_op = convert(money, @w_monto_ultimo)
        WHERE tg_tramite = @w_tramite
        AND tg_cliente = @w_miembro
        if @w_error<>0
        BEGIN 
            exec @w_error = cobis..sp_cerror
                @t_debug  = 'N',
                @t_file   = '',
                @t_from   = 'sp_grupal_reglas',
                @i_num    = @w_error,
                @i_msg    = 'Error al actualizar campo INCREMENTO del tramite grupal'
        END
		ElSE
		BEGIN
		
	        IF EXISTS(	SELECT 1 
						FROM cr_tramite_grupal 
						WHERE tg_tramite = @w_tramite 
						AND tg_cliente = @w_miembro
						AND tg_monto != 0)
	        BEGIN	
	        	PRINT 'Monto diferente de cero en IG:'
	        IF EXISTS(SELECT 1 FROM cob_credito..cr_tramite_grupal WHERE tg_tramite = @w_tramite  AND
              tg_monto > (tg_monto_ult_op + tg_monto_ult_op * tg_incremento/100.0)
              AND tg_cliente =@w_miembro)
	    						
	    		BEGIN
	    		   	PRINT 'Ingresa en if cuando no pasa la regla de Ig'
	    			IF @w_cli_increm_grupo IS NULL
	    			BEGIN
	    			PRINT '@w_cli_increm_grupo is null en Ig'
	    			PRINT '@w_cli_monto_grupo is null en IG clientes--->'+ convert(varchar(50),@w_miembro)
	    				SELECT @w_cli_increm_grupo = CONVERT(VARCHAR, @w_miembro)
	    			END
	    			ELSE
	    			BEGIN
	    			PRINT '@w_cli_increm_grupo no es en Ig'
	    			PRINT '@w_cli_monto_grupo is  not null en IG clientes--->'+ convert(varchar(50),@w_miembro)
	    				SELECT @w_cli_increm_grupo = @w_cli_increm_grupo + ',' + CONVERT(VARCHAR, @w_miembro)
	    			END
	    		END	
		    END		
		
	    END	
		
	-- Finaliza Validar Regla Incremento Grupal

	-- Siguiente cliente en el WHILE
	SELECT	@w_miembro	=	tg_cliente
	FROM cob_credito..cr_tramite_grupal
	WHERE tg_tramite = @w_tramite
	AND tg_participa_ciclo <> 'N'
	AND tg_cliente > @w_miembro
	ORDER BY tg_cliente ASC
END	-- Fin WHILE
 PRINT 'Inicia Observaciones' 
 
 PRINT 'Observaciones @w_cli_monto_grupo' + convert(VARCHAR(255),@w_cli_monto_grupo)
 PRINT 'Observaciones @w_cli_increm_grupo' + convert(VARCHAR(255),@w_cli_increm_grupo)
-- Valida si existen clientes que no cumplen la regla
IF @w_cli_monto_grupo IS NOT NULL
BEGIN
	-- Ejecuta proceso para setear la obervacion
	EXEC		@w_error = cob_credito..sp_ins_observacion_reverif
				@s_ssn				= @s_ssn,
				@s_sesn				= @s_sesn,
				@s_user				= @s_user,
				@s_term				= @s_term,
				@s_date				= @s_date,
				@s_srv				= @s_srv,
				@s_lsrv				= @s_lsrv,
				@s_ofi				= @s_ofi,
				@t_file				= NULL,
				@s_rol				= @s_rol,
				@s_org_err			= NULL,
				@s_error			= NULL,
				@s_msg				= NULL,
				@s_org				= '',
				@t_rty				= '',
				@t_trn				= @t_trn,
				@i_id_inst_proc	= @i_id_inst_proc,
				@i_id_inst_act 	= NULL,	
				@i_id_empresa	= NULL,	
				@i_clientes		= @w_cli_monto_grupo,
				@i_tipo_regla	= 'M',
				@i_numero_linea	= 1

	-- Seteo variables de salida
	SELECT	@o_id_resultado = 2, -- Seteo para salida de la tarea con DEVOLVER	
			@w_numero_linea = 2
END
ELSE
BEGIN
	-- Seteo variables de salida
	SELECT	@o_id_resultado = 1, -- Seteo para salida de la tarea con OK
			@w_numero_linea = 1
END

-- Valida si existen clientes que no cumplen la regla
IF @w_cli_increm_grupo IS NOT NULL
BEGIN
	-- Ejecuta proceso para setear la obervacion
	EXEC		@w_error = cob_credito..sp_ins_observacion_reverif
				@s_ssn				= @s_ssn,
				@s_sesn				= @s_sesn,
				@s_user				= @s_user,
				@s_term				= @s_term,
				@s_date				= @s_date,
				@s_srv				= @s_srv,
				@s_lsrv				= @s_lsrv,
				@s_ofi				= @s_ofi,
				@t_file				= NULL,
				@s_rol				= @s_rol,
				@s_org_err			= NULL,
				@s_error			= NULL,
				@s_msg				= NULL,
				@s_org				= '',
				@t_rty				= '',
				@t_trn				= @t_trn,
				@i_id_inst_proc		= @i_id_inst_proc,
				@i_id_inst_act 		= NULL,
				@i_id_empresa		= NULL,
				@i_clientes			= @w_cli_increm_grupo,
				@i_tipo_regla		= 'I',
				@i_numero_linea		= @w_numero_linea
END

-- VALIDA SI pasa OK O DEVOLVER
IF @w_cli_increm_grupo IS NOT NULL OR @w_cli_monto_grupo IS NOT NULL
BEGIN
	-- Seteo variables de salida
	SELECT @o_id_resultado = 2 -- Seteo para salida de la tarea con DEVOLVER	
END
ELSE
BEGIN
	-- Seteo variables de salida
	SELECT @o_id_resultado = 1 -- Seteo para salida de la tarea con OK
END

RETURN 0
go
