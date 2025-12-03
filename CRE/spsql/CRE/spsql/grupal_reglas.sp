/************************************************************************/
/*  Archivo:                grupal_reglas.sp                            */
/*  Stored procedure:       sp_grupal_reglas                            */
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
/*  Evaluacion de reglas para encontrar el calculo de porc.             */
/*  incremento y monto maximo por cliente                               */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_grupal_reglas')
    drop proc sp_grupal_reglas
go


CREATE PROC sp_grupal_reglas
    @s_ssn              int 	    = NULL,	
    @s_rol              smallint    = null,	
    @s_ofi              smallint    = NULL,	
    @s_sesn             int 	    = NULL,
    @t_trn              int         = null,		
    @s_user             login 	    = NULL,
    @s_term             varchar(30) = NULL,
    @s_date             DATETIME    = NULL,
    @s_srv              varchar(30) = NULL,
    @s_lsrv             varchar(30) = NULL,
    @i_tramite          INT,
    @i_id_rule          VARCHAR(30),
	@i_valida_part       char(1)      = 'S', -- Para indicar si aplica las reglas solo para los integrantes del grupo que participan. Si llega N, entonces valida a todos.
    @o_msg1             varchar(100) = null output,
    @o_msg2             varchar(100) = null OUTPUT,
    @o_msg3             varchar(100) = null OUTPUT,
    @o_msg4             varchar(100) = null OUTPUT
AS

declare @w_rule             int,
        @w_rule_version     int,
        @w_retorno_val      varchar(255),
        @w_retorno_id       int,
        @w_variables        varchar(255),
        @w_result_values    varchar(255),
        @w_error            int,
        @w_id_variable      int,
        @w_miembro          int,
        @w_valor_ant        varchar(255),
        @w_resul_ciclo      VARCHAR(30),
        @w_id_inst_proc     INT,
        @w_monto_ultimo     MONEY,
        @w_grupo            INT,

@w_emprendedor              varchar(3),
@w_var_dias_atraso_grupal   int,
@w_var_en_nro_ciclo         smallint,
@w_var_experiencia          varchar(1),
@w_parent                       int,
@w_var_experiencia_crediticia   varchar(2),
@w_tr_promocion                 char(1),
@w_tr_promocion_grupo           char(1)




		
IF @i_id_rule = 'VAL_TRAMITE'
BEGIN
	select @o_msg1=''
	select @o_msg2=''
	select @o_msg3=''
	select @o_msg4=''
	
	--Existen prestamos cuyo porcentaje de Incremeto grupal es menor o igual a -100
	IF EXISTS(SELECT 1 FROM cr_tramite_grupal WHERE tg_tramite = @i_tramite AND tg_monto > 0 AND
              tg_incremento <=-100)
    begin
        select @o_msg1 = 'Existen prestamos cuyo porcentaje de incremeto grupal es menor o igual a -100'
        SELECT @w_error = 2110321
        exec @w_error = cobis..sp_cerror
                @t_debug  = 'N',
                @t_file   = '',
                @t_from   = 'sp_grupal_reglas',
                @i_num    = @w_error
    end
    -- validar porcentaje
    IF EXISTS(SELECT 1 FROM cr_tramite_grupal WHERE tg_tramite = @i_tramite AND tg_monto > 0 AND
              tg_monto > (tg_monto_ult_op + tg_monto_ult_op * tg_incremento/100.0))
    begin
        select @o_msg1 = 'Existen préstamos  que superan el incremento permitido'
        SELECT @w_error = 2110322
        exec @w_error = cobis..sp_cerror
                @t_debug  = 'N',
                @t_file   = '',
                @t_from   = 'sp_grupal_reglas',
                @i_num    = @w_error
    end
    -- validar monto maximo
    IF EXISTS(SELECT 1 FROM cr_tramite_grupal WHERE tg_tramite = @i_tramite AND tg_monto > tg_monto_max_calc AND tg_monto > 0)
    begin
        SELECT @w_error = 2110323
        select @o_msg2 = 'Existen préstamos con monto superior al monto Máximo'
             exec @w_error = cobis..sp_cerror
                @t_debug  = 'N',
                @t_file   = '',
                @t_from   = 'sp_grupal_reglas',
                @i_num    = @w_error
    end
    -- validar monto maximo
    IF EXISTS(SELECT 1 FROM cr_tramite_grupal WHERE tg_tramite = @i_tramite AND tg_monto < tg_monto_min_calc AND tg_monto > 0)
    BEGIN
        SELECT @w_error = 2110324
        select @o_msg3 = 'Existen préstamos con monto inferior al monto Mínimo'
            exec @w_error = cobis..sp_cerror
                @t_debug  = 'N',
                @t_file   = '',
                @t_from   = 'sp_grupal_reglas',
                @i_num    = @w_error
                
                
        
    end

    RETURN 0
END


select @w_id_inst_proc = io_id_inst_proc,
       @w_grupo        = io_campo_1
from   cob_workflow..wf_inst_proceso
where  io_campo_3 = @i_tramite

select @w_id_inst_proc = isnull(@w_id_inst_proc,-1)
--Obtengo la promocion de grupo
PRINT'Ingresas a verificar promocion del grupo'
SELECT @w_tr_promocion_grupo=tr_promocion FROM cob_credito..cr_tramite WHERE tr_tramite=@i_tramite

select @w_tr_promocion_grupo = isnull(@w_tr_promocion_grupo,'N')
if (@w_tr_promocion_grupo = 'S')
BEGIN
PRINT 'Promocion Grupo es S --->'
EXEC cob_credito..sp_var_integrantes_original
@i_id_inst_proc=@w_id_inst_proc,
@i_id_inst_act=1,
@i_id_asig_act =1,
@i_id_empresa =1,
@i_id_variable =1
END

IF @i_id_rule   = 'MONTO_GRP'
BEGIN
	EXEC @w_error = sp_dias_atraso_grupal
	    @i_grupo			= @w_grupo,
		@i_ciclos_ant		= 1,
		@i_es_ciclo_ant     = 'S',
		@o_resultado    	= @w_var_dias_atraso_grupal OUTPUT 
	if @w_error<>0
	begin
	    exec @w_error = cobis..sp_cerror
	        @t_debug  = 'N',
	        @t_file   = '',
	        @t_from   = 'sp_grupal_reglas',
	        @i_num    = @w_error
	END
END 


select
    @w_rule           = bpl_rule.rl_id,
    @w_rule_version   = rv_id
from cob_pac..bpl_rule
inner join cob_pac..bpl_rule_version  on bpl_rule.rl_id = bpl_rule_version.rl_id
where rv_status   = 'PRO'
and rl_acronym    = @i_id_rule
and getdate()     >= rv_date_start
and getdate()     <= rv_date_finish

select @w_id_variable  = vb_codigo_variable
from cob_workflow..wf_variable
where vb_abrev_variable     = 'CLINROCLIN'

select @w_miembro = 0
select @w_miembro  = tg_cliente
from cob_credito..cr_tramite_grupal
where tg_tramite       =   @i_tramite
and (tg_participa_ciclo <> 'N' or @i_valida_part = 'N')
and tg_cliente         >  @w_miembro
order by tg_cliente desc

while @@rowcount > 0
BEGIN
    print '******VALIDA REGLAS DEL CLIENTE***** '+ convert(varchar(10),@w_miembro)
    select @w_valor_ant   = isnull(va_valor_actual, '')
    from cob_workflow..wf_variable_actual
    where va_id_inst_proc = @w_id_inst_proc
    and va_codigo_var     = @w_id_variable

    if @@rowcount > 0  --ya existe
    begin
        update cob_workflow..wf_variable_actual
        set va_valor_actual = @w_miembro
        where va_id_inst_proc = @w_id_inst_proc
        and va_codigo_var   = @w_id_variable
    end
    else
    begin
        insert into cob_workflow..wf_variable_actual
                (va_id_inst_proc, va_codigo_var, va_valor_actual)
        values (@w_id_inst_proc, @w_id_variable, @w_miembro )

    end

    IF @i_id_rule   = 'INC_GRP'
    BEGIN
        exec @w_error          = cob_pac..sp_exec_variable_by_rule
            @s_ssn             = @s_ssn,
            @s_sesn            = @s_sesn,
            @s_user            = @s_user,
            @s_term            = @s_term,
            @s_date            = @s_date,
            @s_srv             = @s_srv,
            @s_lsrv            = @s_lsrv,
            @s_ofi             = @s_ofi,
            @t_file            = null,
            @s_rol             = @s_rol,
            @s_org_err         = null,
            @s_error           = null,
            @s_msg             = null,
            @s_org             = '',
            @s_culture         = 'ES_EC',
            @t_rty             = '',
            @t_trn             = @t_trn,
            @t_show_version    = 0,
            @i_id_inst_proc    = @w_id_inst_proc,
            @i_id_inst_act     = 0,
            @i_id_asig_act     = 0,
            @i_id_empresa      = 1,
            @i_acronimo_regla  = 'INC_GRP',
            @i_var_nombre      = 'NROCLIND', -- LGU nombre de una variable especifica
            @o_resultado       = @w_resul_ciclo  out-- LGU resultado de evaluar una sola variable

        --print 'Se ejecutan las variables de la regla  RESULTADO CLI ' + convert(VARCHAR, @w_miembro) + ' CICLO ' + @w_resul_ciclo

	    IF @w_resul_ciclo > 1 
	    begin
	        exec @w_error          = cob_pac..sp_exec_variable_by_rule
	            @s_ssn             = @s_ssn,
	            @s_sesn            = @s_sesn,
	            @s_user            = @s_user,
	            @s_term            = @s_term,
	            @s_date            = @s_date,
	            @s_srv             = @s_srv,
	            @s_lsrv            = @s_lsrv,
	            @s_ofi             = @s_ofi,
	            @t_file            = null,
	            @s_rol             = @s_rol,
	            @s_org_err         = null,
	            @s_error           = null,
	            @s_msg             = null,
	            @s_org             = '',
	            @s_culture         = 'ES_EC',
	            @t_rty             = '',
	            @t_trn             = @t_trn,
	            @t_show_version    = 0,
	            @i_id_inst_proc    = @w_id_inst_proc,
	            @i_id_inst_act     = 0,
	            @i_id_asig_act     = 0,
	            @i_id_empresa      = 1,
	            @i_acronimo_regla  = @i_id_rule
	
	        --Se ejecuta la regla
	
	        select @w_retorno_val = '0'
	        select @w_retorno_id = 0
	        select @w_variables = ''
	        select @w_result_values = ''
	
	        exec @w_error           = cob_pac..sp_rules_run
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
	            @i_id_inst_proceso = @w_id_inst_proc,
	            @i_code_rule       = @w_rule,
	            @i_version         = @w_rule_version,
	            @o_return_value    = @w_retorno_val   out,
	            @o_return_code     = @w_retorno_id    out,
	            @o_return_variable = @w_variables     out,
	            @o_return_results  = @w_result_values out,
	            --@s_culture         = 'ES_EC',
	            @i_mode            = 'WFL',
	            @i_abreviature      = null,
	            @i_simulator       = 'N',
	            @i_nivel           =  0,
	            @i_modo            = 'S'
	
	        --print '@w_retorno_val: '+convert(varchar, @w_retorno_val)
	        --print '@w_retorno_id: '+convert(varchar, @w_retorno_id)
	        --print '@w_variables: '+convert(varchar, @w_variables)
	        --print '@w_result_values: '+convert(varchar, @w_result_values)

	        if @w_error<>0
	        begin
	            exec @w_error = cobis..sp_cerror
	                @t_debug  = 'N',
	                @t_file   = '',
	                @t_from   = 'sp_rules_run',
	                @i_num    = @w_error
	        END
	
	        PRINT '@w_retorno_val INGRP: '+convert(varchar, @w_retorno_val)
	        print '@w_retorno_id INGRP: '+convert(varchar, @w_retorno_id)
	        print '@w_variables INGRP: '+convert(varchar, @w_variables)
	        print '@w_result_values INGRP: '+convert(varchar, @w_result_values)
	
	        SELECT TOP 1 @w_monto_ultimo = op_monto
	        FROM cob_cartera..ca_operacion ,cob_cartera..ca_estado
	        WHERE op_cliente = @w_miembro
	        AND op_estado= es_codigo
	        AND (es_procesa='S' OR op_estado = 3)
	        ORDER BY op_operacion DESC
	        SELECT @w_monto_ultimo = isnull(@w_monto_ultimo,0)
	    END -- si cilo es mayor que uno
	    ELSE
	    BEGIN
	        --PRINT '--------- 100'
	        SELECT @w_retorno_val = 100
	        SELECT @w_monto_ultimo = 999999999
	    END
	    
        PRINT @w_retorno_val
        --SELECT 'tramite' = @i_tramite, 'cliente' = @w_miembro, 'incremento' = @w_retorno_val, 'monto_ultimo' = @w_monto_ultimo
        UPDATE cob_credito..cr_tramite_grupal SET
            tg_incremento = convert(numeric(8,4), @w_retorno_val),
            tg_monto_ult_op = convert(money, @w_monto_ultimo)
        WHERE tg_tramite = @i_tramite
        AND tg_cliente = @w_miembro
        select @w_error = @@error
        if @w_error<>0
        BEGIN 
            exec @w_error = cobis..sp_cerror
                @t_debug  = 'N',
                @t_file   = '',
                @t_from   = 'sp_grupal_reglas',
                @i_num    = 2110326
        END

	END 


    IF @i_id_rule = 'MONTO_GRP'
    BEGIN
		SELECT 
			@w_var_en_nro_ciclo = en_nro_ciclo
		FROM  cobis..cl_ente
		WHERE  en_ente   = @w_miembro
	      
		IF (@w_var_en_nro_ciclo IS NULL)
		 BEGIN
		
		 select @w_var_en_nro_ciclo = 1
		end
		else
		 BEGIN
		 select @w_var_en_nro_ciclo = @w_var_en_nro_ciclo+1
		 end
		 PRINT '@w_var_en_nro_ciclo--->'+ convert(VARCHAR(50),@w_var_en_nro_ciclo)
		 
	    --Ejecucion del Experiencia Crediticia
	    EXEC @w_error =cob_credito..sp_var_experiencia_crediticia
         @i_id_cliente=@w_miembro,
         @o_resultado     = @w_var_experiencia_crediticia OUTPUT 
         if @w_error<>0
	      begin
	        exec @w_error = cobis..sp_cerror
	        @t_debug  = 'N',
	        @t_file   = '',
	        @t_from   = 'sp_grupal_reglas',
	        @i_num    = @w_error
	     END
	   PRINT 'ID cliente en Regla--> '+ convert (VARCHAR(50), @w_miembro)
       PRINT 'Var Experiencia Crediticia'+ convert (VARCHAR(50), @w_var_experiencia_crediticia)
		---tr_promocion
       IF (@w_tr_promocion_grupo = 'S')
         BEGIN
          IF EXISTS(SELECT 1 FROM cob_credito..cr_grupo_promo_inicio WHERE gpi_tramite=@i_tramite 
                    AND gpi_grupo=@w_grupo AND gpi_ente=@w_miembro)
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
		
		 PRINT 'Promocion final par el  cliente --->'+ convert(varchar(50),@w_tr_promocion)
	      
        set @w_resul_ciclo = isnull (@w_tr_promocion,'N')+ '|' + 
                             isnull(convert(VARCHAR,@w_var_en_nro_ciclo),'1') + '|' + 
	  				         isnull(convert(VARCHAR,@w_var_dias_atraso_grupal),'0') + '|' + 
	  				         isnull(@w_var_experiencia_crediticia,' ')
	  				         
	
	Print'@w_resul_ciclo'+ convert(VARCHAR(50),@w_resul_ciclo)
	
	-- LLAMA A LA REGLA - RETORNA EL TIPO DE CR+DITO CUANDO SECTOR = 'CR+DITO EMPRESARIAL'
	     exec @w_error    = cob_pac..sp_rules_param_run
	     @s_rol             = @s_rol,
	     @i_rule_mnemonic   = @i_id_rule,
	     @i_var_values      = @w_resul_ciclo, 
	     @i_var_separator   = '|',
	     @o_return_variable = @w_variables  out,
	     @o_return_results  = @w_result_values   OUT,
	     @o_last_condition_parent = @w_parent out
		 --PRINT '----------------------------------------------------------------------'
		 --print' CL : ' + convert(VARCHAR, @w_miembro) + ' EVALUAR =' + @w_resul_ciclo
	     --print '@w_variables: '+convert(varchar, @w_variables)
	     --print '@w_result_values: '+convert(varchar, @w_result_values)
		 --PRINT '----------------------------------------------------------------------'
         
	     if @w_error != 0
	     begin
	          print 'Print: fallo MONTO_GRP para cliente ' + convert(VARCHAR, @w_miembro)
			  print 'Error_fallo_monto_grp_regla:' + convert(VARCHAR, @w_error)
	          GOTO SIGUIENTE
	     end
	     if @w_result_values IS null
	     BEGIN
	     	SELECT @w_result_values = '0|0'
	     end
	
	     PRINT '@w_variables MTGRP'    + convert(VARCHAR(50),@w_variables)
		 PRINT '@w_result_values MTGRP'+ convert(VARCHAR(50),@w_result_values)
		 PRINT '@w_parent MTGRP'       + convert(VARCHAR(50),@w_parent)
--////////////////////////////////////////////////////// 

        --SELECT 'tramite' = @i_tramite, 'cliente' = @w_miembro, 'monto_maximo' = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')
        UPDATE cob_credito..cr_tramite_grupal SET
            tg_monto_max      = isnull(tg_monto_max, replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|','')),
            tg_monto_max_calc = replace(convert(varchar, substring(@w_result_values, charindex('|', @w_result_values) + 1, 300)),'|',''),
            tg_monto_min_calc = replace(convert(varchar, substring(@w_result_values, 1,   charindex('|', @w_result_values) - 1)),'|','')
        WHERE tg_tramite = @i_tramite
        AND tg_cliente = @w_miembro
        select @w_error = @@error
        if @w_error<>0
        begin
            exec @w_error = cobis..sp_cerror
                @t_debug  = 'N',
                @t_file   = '',
                @t_from   = 'sp_grupal_reglas',
                @i_num    = 2110327
        END
        
    END  -- monto grupal


SIGUIENTE:
    select @w_miembro        = tg_cliente
    from cob_credito..cr_tramite_grupal
    where tg_tramite         =   @i_tramite
    and (tg_participa_ciclo   <> 'N' or @i_valida_part = 'N')
    and tg_cliente           >  @w_miembro
    order by tg_cliente desc
end -- WHILE

RETURN 0
go
