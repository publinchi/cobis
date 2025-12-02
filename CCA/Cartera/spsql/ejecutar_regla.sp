/************************************************************************/
/*  archivo:                ejecutar_regla.sp                           */
/*  stored procedure:       sp_ejecutar_regla                           */
/*  base de datos:          cob_cartera                                 */
/*  producto:               credito                                     */
/*  disenado por:           Andy Gonzalez                               */
/*  fecha de documentacion: 28/ago/2018                                 */
/************************************************************************/
/*          importante                                                  */
/*  este programa es parte de los paquetes bancarios propiedad de       */
/*  "macosa",representantes exclusivos para el ecuador de la            */
/*  at&t                                                                */
/*  su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  presidencia ejecutiva de macosa o su representante                  */
/************************************************************************/
/*          proposito                                                   */
/*               Ejecucion de reglas de cartera                         */
/*  srojas              13-Nov-2018           Ejecución de reglas sp    */
/*                                            asociado a variables.     */
/************************************************************************/

use cob_cartera 
go

if exists(select 1 from sysobjects where name ='sp_ejecutar_regla')
	drop proc sp_ejecutar_regla
go

create proc sp_ejecutar_regla(
@s_ssn                     int           = null,
@s_ofi                     smallint,
@s_user                    login,
@s_date                    datetime,
@s_srv                     varchar(30)   = null,
@s_term                    descripcion   = null,
@s_rol                     smallint      = null,
@s_lsrv                    varchar(30)   = null,
@s_sesn                    int           = null,
@s_org                     char(1)       = null,
@s_org_err                 int           = null,
@s_error                   int           = null,
@s_sev                     tinyint       = null,
@s_msg                     descripcion   = null,
@t_rty                     char(1)       = null,
@t_trn                     int           = null,
@t_debug                   char(1)       = 'N',
@t_file                    varchar(14)   = null,
@t_from                    varchar(30)   = null,
@i_operacionca             int           = null,
@i_en_linea                char(1)       = 'S',
@i_regla                   varchar(10),                  --Nemonico de la Regla,
@i_id_inst_proc            int           = null,      
@i_valor_variable_regla    varchar(255)  = null,
@i_tipo_ejecucion          VARCHAR(30)   = 'WORKFLOW',
@o_resultado1              varchar(255)  = null out ,     --Variable de Salida concatenada en Pipes
@o_resultado2              varchar(255)  = null out
)		
as
declare
@w_sp_name       	varchar(32),
@w_tramite       	int,
@w_return        	int,
@w_rule             int,
@w_rule_version     int,
@w_id_empresa       int,
@w_inst_proceso     int,
@w_ins_act          int,
@w_retorno_val      varchar(255),
@w_retorno_id       int,
@w_result_values    varchar(255),
@w_error            int,
@w_msg              varchar(255),
@w_operacion        int,
@w_operacion_gr     varchar(20),
@w_resultado1       varchar(255),
@w_resultado2       varchar(255),
@w_parent           int,
@w_variables        varchar(255),
@w_id_programa      int,
@w_codigo_variable  int = 0,
@w_banco            cuenta

select @w_sp_name = 'sp_ejecutar_regla'


if @i_id_inst_proc is null and @i_operacionca is not null begin
   select @w_banco = op_banco
   from cob_cartera..ca_operacion
   where op_operacion = @i_operacionca
   
   select @w_operacion_gr= dc_referencia_grupal from ca_det_ciclo
   where dc_operacion = @i_operacionca
   
   if @@rowcount = 0 begin  --INDIVIDUAL
   select @w_tramite  = op_tramite 
   from   ca_operacion 
   where  op_operacion = @i_operacionca
   
   end else begin          --GRUPAL
   select @w_tramite  = ci_tramite  
   from   ca_ciclo 
   where  ci_prestamo = @w_operacion_gr
   end 
   
   --DETERMINAR INSTANCIA DE PROCESO
   select @w_inst_proceso = io_id_inst_proc
   from   cob_workflow..wf_inst_proceso
   where  io_campo_3 = @w_tramite
   
   if @@rowcount = 0 begin
      select
      @w_error = 701103,
      @w_msg = 'Error !:No exite tramite'
      
      goto ERROR 
             
   end 
end 

select @w_inst_proceso = isnull(@w_inst_proceso, @i_id_inst_proc)

select
@w_rule         = bpl_rule.rl_id,
@w_rule_version = rv_id
from cob_pac..bpl_rule inner join cob_pac..bpl_rule_version
on bpl_rule.rl_id = bpl_rule_version.rl_id
where rv_status  = 'PRO'
and   rl_acronym = @i_regla
and   getdate() >= rv_date_start
and   getdate() <= rv_date_finish

if @@rowcount = 0 begin

   select
   @w_error = 701103,
   @w_msg = 'La regla no existe o no está en Producción'
   
   goto ERROR    
end
   
PRINT   'Regla:'+convert(VARCHAR,@w_rule)
if @i_tipo_ejecucion = 'REGLA' begin
     
   exec 
   @w_error                   = cob_pac..sp_rules_param_run
   @s_rol                     = @s_rol,
   @i_rule_mnemonic           = @i_regla,
   @i_var_values              = @i_valor_variable_regla,
   @i_var_separator           = '|',
   @i_modo                    = 'S',
   @i_tipo                    = 'S',
   @o_return_variable         = @w_variables     out,
   @o_return_results          = @w_result_values out,
   @o_last_condition_parent   = @w_parent        out
		
   if @w_error <> 0 begin
      select
      @w_error        = @w_error,
      @w_sp_name      = 'cob_pac..sp_rules_param_run',
      @w_msg          = 'Error al ejecutar sp_rules_param_run '
      goto ERROR     
   end
   
end
else if @i_tipo_ejecucion = 'WORKFLOW' begin
   

   if @w_inst_proceso is null begin
      select
      @w_error = 70216,
      @w_msg = 'Error !:No exite Instancia de Proceso'
	  goto ERROR 
   end
   else begin
      select @w_ins_act = ia_id_inst_act 
      from  cob_workflow..wf_inst_actividad
      where ia_id_inst_proc = @w_inst_proceso
      
      if @@rowcount = 0 begin
         select
         @w_error = 701103,
         @w_msg = 'Error !:No exite Instancia de Actividad'
         
         goto ERROR    
            
      end
   end

   --Se ejecutan las variables de la regla
   exec @w_error      = cob_pac..sp_exec_variable_by_rule
   @s_ssn             = @s_ssn,
   @s_sesn            = @s_sesn,
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_date            = @s_date,
   @s_srv             = @s_srv,
   @s_lsrv            = @s_lsrv,
   @s_ofi             = @s_ofi,
   @t_trn             = @t_trn,
   @i_id_inst_proc    = @w_inst_proceso,
   @i_id_inst_act     = @w_ins_act,
   @i_id_asig_act     = 0,
   @i_id_empresa      = @w_id_empresa,
   @i_acronimo_regla  = @i_regla
   
   if @w_error <> 0 begin
   select
   @w_error        = @w_error,
   @w_sp_name      = 'cob_pac..sp_exec_variable_by_rule',
   @w_msg          = 'Error al ejecutar sp_exec_variable_by_rule '
      goto ERROR     
   end
   
   select
   @w_retorno_val   = '0',
   @w_retorno_id    =  0 ,
   @w_variables     = '' ,
   @w_result_values = ''
   
   --Ejecucion de la regla 
   exec @w_error      = cob_pac..sp_rules_run
   @s_ssn             = @s_ssn,
   @s_sesn            = @s_sesn,
   @s_user            = @s_user,
   @s_term            = @s_term,
   @s_date            = @s_date,
   @s_srv             = @s_srv,
   @s_lsrv            = @s_lsrv,
   @s_ofi             = @s_ofi,
   @s_rol             = @s_rol,
   @t_trn             = @t_trn,
   @i_id_inst_proceso = @w_inst_proceso,
   @i_code_rule       = @w_rule,
   @i_version         = @w_rule_version,
   @o_return_value    = @w_retorno_val   out,
   @o_return_code     = @w_retorno_id    out,
   @o_return_variable = @w_variables     out,
   @o_return_results  = @w_result_values out,
   @i_mode            = 'WFL',
   @i_simulator       = 'N',
   @i_nivel           =  0,
   @i_modo            = 'S'
   
   if @w_error <> 0 begin
      select
      @w_error        = @w_error,
      @w_sp_name      = 'cob_pac..sp_rules_run',
      @w_msg         = 'Error al ejecutar sp_rules_run'
	  
      goto ERROR   
   end     
end
else begin
   select
   @w_error        = 70217,
   @w_sp_name      = 'cob_pac..sp_rules_run',
   @w_msg          = 'Tipo de Ejecución no válida'
   
   goto ERROR
end

if @w_result_values is not null and datalength(@w_result_values) > 0 begin
   select @w_resultado1  = convert(varchar,substring(@w_result_values, 1, charindex('|', @w_result_values)-1))
   
   if datalength(@w_result_values) > (charindex('|', @w_result_values) +1 ) begin
      select @w_resultado2  = convert(varchar,substring(@w_result_values, charindex('|', @w_result_values)+1, datalength(@w_result_values)-1))
      select @w_resultado2  = convert(varchar,substring(@w_resultado2,1 ,charindex('|', @w_resultado2)-1))
   end
end
   
select @o_resultado1 =@w_resultado1,
       @o_resultado2 =@w_resultado2


      
return 0

ERROR:

if @i_en_linea = 'S' begin 
   exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error,
   @i_msg   = @w_msg

end else begin 
   exec sp_errorlog 
   @i_fecha     = @s_date,
   @i_error     = @w_error,
   @i_usuario   = @s_user,
   @i_tran      = 7999,
   @i_tran_name = @w_sp_name,
   @i_cuenta    = @w_banco,
   @i_rollback  = 'N'
   
end  
   
   
return @w_error
go

