/************************************************************************/
/*  Archivo:                var_limite_intg_cond.sp                     */
/*  Stored procedure:       sp_var_limite_intg_cond                     */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_var_limite_intg_cond' and type = 'P')
   drop proc sp_var_limite_intg_cond
go

CREATE PROCEDURE sp_var_limite_intg_cond
            (@s_ssn        int         = null,
	     @s_ofi        smallint    = null,
	     @s_user       login       = null,
             @s_date       datetime    = null,
	     @s_srv        varchar(30) = null,
	     @s_term	   descripcion = null,
	     @s_rol        smallint    = null,
	     @s_lsrv	   varchar(30) = null,
	     @s_sesn	   int 	       = null,
	     @s_org        char(1)     = null,
         @s_org_err    int 	       = null,
         @s_error      int 	       = null,
         @s_sev        tinyint     = null,
         @s_msg        descripcion = null,
         @t_rty        char(1)     = null,
         @t_trn        int         = null,
         @t_debug      char(1)     = 'N',
         @t_file       varchar(14) = null,
         @t_from       varchar(30)  = null,
         --variables
         @i_id_inst_proc int,    --codigo de instancia del proceso
         @i_id_inst_act  int,    
         @i_id_asig_act  int,
         @i_id_empresa   int, 
         @i_id_variable  smallint 
)
AS
DECLARE @w_sp_name       	varchar(32),
        @w_tramite       	int,
        @w_return        	INT,
        ---var variables	
        @w_asig_actividad 	int,
        @w_valor_ant      	varchar(255),
        @w_valor_nuevo    	varchar(255),
        @w_actividad      	catalogo,
        @w_grupo                int,
        @w_ente                 int,
        @w_fecha                datetime,
        @w_fecha_dif		datetime,
        @w_ttramite             varchar(255),
        @w_promocion            char(1),
        @w_asig_act             int,
        @w_numero               int,
        @w_proceso              varchar(5),
        @w_usuario              varchar(64),
        @w_comentario           varchar(1000),
        @w_nombre               varchar(64),
        @w_exp_credit           varchar(1),
        @w_emprendedor          varchar(1),
        @w_tramite_ant          int,
        @w_cnt_integrantes      int,
        @w_error                int,
        @w_maximo_cond          int,
        @w_condicionados        int,
	    @w_variables            varchar(255),
	    @w_result_values        varchar(255),
	    @w_parent               int,
	    @w_diferencia           int,
	    @w_id                   int,
        @w_ofi_movil_def        smallint,
        @w_msg                  varchar(1000),
        @w_division             int,
        @w_particiones          varchar(250),
        @w_id_observacion       smallint
	    
       

select @w_sp_name='sp_var_limite_intg_cond'

select @w_grupo       = convert(int,io_campo_1),
	   @w_tramite     = convert(int,io_campo_3),
	   @w_ttramite    = io_campo_4,
       @w_asig_act    = convert(int,io_campo_2),
	   @w_tramite_ant = convert(int,io_campo_5)
from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc
and   io_campo_7 = 'S'

select @w_tramite = isnull(@w_tramite,0)
if @w_tramite = 0 return 0

select @w_proceso = pa_int from cobis..cl_parametro where pa_nemonico = 'OAA'
select @w_ofi_movil_def = pa_smallint   from cobis..cl_parametro where pa_nemonico = 'OFIAPP'
select @w_comentario = 'El grupo excede CONDICIONADOS, se recomienda eliminar XX personas con esta prioridad <lista personas>' 

if @w_ttramite = 'GRUPAL'
begin
	--CONFORMACION GRUPAL
	select @w_cnt_integrantes = convert(varchar,count(cg_ente)) 
	from cobis..cl_cliente_grupo 
	where cg_grupo 	= @w_grupo
	and   cg_estado = 'V'
	
	/* Evalua regla de condicionados del grupo */
	exec @w_error           = cob_pac..sp_rules_param_run
	     @s_rol             = @s_rol,
	     @i_rule_mnemonic   = 'LDCC',
	     @i_var_values      = @w_cnt_integrantes, 
	     @i_var_separator   = '|',
	     @o_return_variable = @w_variables  out,
	     @o_return_results  = @w_result_values   OUT,
	     @o_last_condition_parent = @w_parent out 
	if @w_error<>0
	begin
	    exec @w_error = cobis..sp_cerror
	        @t_debug  = 'N',
	        @t_file   = '',
	        @t_from   = 'sp_rules_param_run',
	        @i_num    = @w_error
	end
	
	
	select @w_maximo_cond = convert(int, substring(@w_result_values, 0, len(@w_result_values)))
	
	select @w_condicionados = count(*) 
	from cobis..cl_ente_aux 
	where ea_nivel_riesgo_cg = 'E' --E = Condicionado
	and ea_ente in (select tg_cliente from cob_credito..cr_tramite_grupal where tg_participa_ciclo = 'S' and tg_tramite = @w_tramite)
	
	select @w_diferencia = @w_condicionados - @w_maximo_cond 
	
	if (@w_condicionados > @w_maximo_cond)
	begin
	    set nocount on
        declare @w_lista table
            (id     int         identity,
             ente   int         null,
             nombre varchar(64))
		
		if @w_tramite_ant != null
		begin
			insert into  @w_lista 
			select en_ente, (isnull(en_nombre,'') + ' ' + isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'')) as nombres
			  from cobis..cl_ente_aux, cobis..cl_cliente_grupo, cobis..cl_ente, cob_credito..cr_tramite_grupal
			  where ea_ente            = cg_ente
			   and  ea_ente            = en_ente
			   and  cg_grupo           = @w_grupo
			   and  cg_estado          = 'V'
			   and  ea_nivel_riesgo_cg = 'E'
			   and  tg_tramite         = @w_tramite
			   and  tg_cliente         = ea_ente
			   and  tg_participa_ciclo = 'S'
			   and en_ente     not in (select tg_cliente from cob_credito..cr_tramite_grupal where tg_participa_ciclo = 'S' and tg_tramite = @w_tramite_ant)                    
			order by ea_sum_vencido desc,
					 ea_num_vencido desc
		end
	    insert into  @w_lista 
	    	select en_ente, (isnull(en_nombre,'') + ' ' + isnull(p_p_apellido,'') + ' ' + isnull(p_s_apellido,'')) as nombres
              from cobis..cl_ente_aux, cobis..cl_cliente_grupo, cobis..cl_ente, cob_credito..cr_tramite_grupal
              where ea_ente            = cg_ente
               and  ea_ente            = en_ente
               and  cg_grupo           = @w_grupo
               and  cg_estado          = 'V'
               and  ea_nivel_riesgo_cg = 'E'
			   and  tg_tramite         = @w_tramite
			   and  tg_cliente         = ea_ente
			   and  tg_participa_ciclo = 'S'
			   and en_ente          in (select tg_cliente from cob_credito..cr_tramite_grupal where tg_participa_ciclo = 'S' and tg_tramite = @w_tramite_ant)
	    order by ea_sum_vencido desc,
			     ea_num_vencido desc
	 
	    select @w_id   = 0,
		       @w_msg  = ''
	 
	    while 1 = 1     
	    begin
	        select top 1
			       @w_id     = id,
			       @w_nombre = nombre
	        from @w_lista
	        where id > @w_id      
	        order by id
	        if @@rowcount = 0
		       break
			if @s_ofi != @w_ofi_movil_def
			begin
                 select @w_msg = @w_msg + ', '  + @w_nombre 
			end
			else
			begin
			     select @w_msg = @w_msg + '\n' + @w_nombre
			end
        
			select @w_error = 103168, 
	                @w_msg = replace(replace(mensaje, 'X', convert(varchar, @w_diferencia)), '<lista>', @w_msg)
	                         from cobis..cl_errores 
	                         where numero = 103168
	    end
		
		select @w_id_observacion = ol_observacion from  cob_workflow..wf_ob_lineas 
		where ol_id_asig_act = @w_asig_act 
		and ol_texto like 'El grupo excede CONDICIONADOS, se recomienda eliminar%'
		
		delete cob_workflow..wf_observaciones 
		where ob_id_asig_act = @w_asig_act
		and ob_numero = @w_id_observacion
		
		delete cob_workflow..wf_ob_lineas 
		where ol_id_asig_act = @w_asig_act 
		and ol_observacion = @w_id_observacion
		
		
		select top 1 @w_numero = ob_numero from cob_workflow..wf_observaciones 
		where ob_id_asig_act = @w_asig_act
		order by ob_numero desc
		
		if (@w_numero is not null)
		begin
			select @w_numero = @w_numero + 1 --aumento en uno el maximo
		end
		else
		begin
			select @w_numero = 1
		end
		
		select @w_usuario = fu_nombre from cobis..cl_funcionario where fu_login = @s_user
		
		if(len(@w_msg) > 250)
		begin
			insert into cob_workflow..wf_observaciones (ob_id_asig_act, ob_numero, ob_fecha, ob_categoria, ob_lineas, ob_oficial, ob_ejecutivo)
			values (@w_asig_act, @w_numero, getdate(), @w_proceso, 1, @s_user, @w_usuario)
			
			insert into cob_workflow..wf_ob_lineas (ol_id_asig_act, ol_observacion, ol_linea, ol_texto)
			values (@w_asig_act, @w_numero, 1, @w_comentario)
		end
		else
		begin
			
			insert into cob_workflow..wf_observaciones (ob_id_asig_act, ob_numero, ob_fecha, ob_categoria, ob_lineas, ob_oficial, ob_ejecutivo)
			values (@w_asig_act, @w_numero, getdate(), @w_proceso, 1, @s_user, @w_usuario)
			
			select @w_division = (len(@w_msg)/4)
			
			select @w_particiones = substring(@w_msg,0,@w_division + 1)
			
			insert into cob_workflow..wf_ob_lineas (ol_id_asig_act, ol_observacion, ol_linea, ol_texto)
			values (@w_asig_act, @w_numero, 1, @w_particiones)
			
			select @w_particiones = substring(@w_msg,@w_division + 1,@w_division)
			
			insert into cob_workflow..wf_ob_lineas (ol_id_asig_act, ol_observacion, ol_linea, ol_texto)
			values (@w_asig_act, @w_numero, 2, @w_particiones)
			
			select @w_particiones =  substring(@w_msg,(@w_division *2),@w_division)
			
			insert into cob_workflow..wf_ob_lineas (ol_id_asig_act, ol_observacion, ol_linea, ol_texto)
			values (@w_asig_act, @w_numero, 3, @w_particiones)
			
			select @w_particiones =  substring(@w_msg,(@w_division *3),len(@w_msg))
			
			insert into cob_workflow..wf_ob_lineas (ol_id_asig_act, ol_observacion, ol_linea, ol_texto)
			values (@w_asig_act, @w_numero, 4, @w_particiones)
			
		end
		
		select @w_valor_nuevo = 'NO'
	end
	else
	begin
		select @w_valor_nuevo = 'SI'
	end
	
end

--insercion en estrucuturas de variables

select @w_asig_actividad = max(aa_id_asig_act)
from cob_workflow..wf_asig_actividad
where aa_id_inst_act   in (select max(ia_id_inst_act) from cob_workflow..wf_inst_actividad
                           where ia_id_inst_proc = @i_id_inst_proc)

if @w_asig_actividad is null
  select @w_asig_actividad = 0

-- valor anterior de variable tipo en la tabla cob_workflow..wf_variable
select @w_valor_ant    = isnull(va_valor_actual, '')
  from cob_workflow..wf_variable_actual
 where va_id_inst_proc = @i_id_inst_proc
   and va_codigo_var   = @i_id_variable

if @@rowcount > 0  --ya existe
begin
  --print '@i_id_inst_proc %1! @w_asig_actividad %2! @w_valor_ant %3!',@i_id_inst_proc, @w_asig_actividad, @w_valor_ant
  update cob_workflow..wf_variable_actual
     set va_valor_actual = @w_valor_nuevo 
   where va_id_inst_proc = @i_id_inst_proc
     and va_codigo_var   = @i_id_variable    
end
else
begin
  insert into cob_workflow..wf_variable_actual
         (va_id_inst_proc, va_codigo_var, va_valor_actual)
  values (@i_id_inst_proc, @i_id_variable, @w_valor_nuevo )

end
--print '@i_id_inst_proc %1! @w_asig_actividad %2! @w_valor_ant %3!',@i_id_inst_proc, @w_asig_actividad, @w_valor_ant
if not exists(select 1 from cob_workflow..wf_mod_variable
              where mv_id_inst_proc = @i_id_inst_proc AND
                    mv_codigo_var= @i_id_variable AND
                    mv_id_asig_act = @w_asig_actividad)
BEGIN
    insert into cob_workflow..wf_mod_variable
           (mv_id_inst_proc, mv_codigo_var, mv_id_asig_act,
            mv_valor_anterior, mv_valor_nuevo, mv_fecha_mod)
    values (@i_id_inst_proc, @i_id_variable, @w_asig_actividad,
            @w_valor_ant, @w_valor_nuevo , getdate())
			
	if @@error > 0
	begin
            --registro ya existe
			
          exec cobis..sp_cerror
          @t_debug = @t_debug,
          @t_file = @t_file, 
          @t_from = @t_from,
          @i_num = 2101002
    return 1
	end 

END

return 0
GO
