
use cob_workflow
go

if object_id ('sp_pasa_cartera_wf') is not null
   drop procedure sp_pasa_cartera_wf
go
/*************************************************************************/
/*   Archivo:            sp_pasa_cartera_wf.sp                           */
/*   Stored procedure:   sp_pasa_cartera_wf                              */
/*   Base de datos:      cob_workflow                                    */
/*   Producto:           Originacion                                     */
/*   Disenado por:       VBR                                             */
/*   Fecha de escritura: 09/01/2017                                      */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   "MACOSA", representantes exclusivos para el Ecuador de NCR          */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier acion o agregado hecho por alguno de sus                  */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante.                 */
/*************************************************************************/
/*                                  PROPOSITO                            */
/*   Este procedimiento almacenado, cambia el estado del tramite  a A    */
/*   en una actividad automatica                                         */
/*************************************************************************/
/*                                MODIFICACIONES                         */
/*   FECHA               AUTOR                       RAZON               */
/*   27-01-2017          VBR                   Emision Inicial           */
/*   19-05-2017          Jorge Salazar         CGS-S112643               */
/*   07-01-2019          MTA                   Validacion de of. mobil   */
/*************************************************************************/
create procedure sp_pasa_cartera_wf
(
   @s_ssn            int           = null,
   @s_ofi            smallint,
   @s_user           login,
   @s_date           datetime,
   @s_srv            varchar(30)   = null,
   @s_term           descripcion   = null,
   @s_rol            smallint      = null,
   @s_lsrv           varchar(30)   = null,
   @s_sesn           int           = null,
   @s_org            char(1)       = null,
   @s_org_err        int           = null,
   @s_error          int           = null,
   @s_sev            tinyint       = null,
   @s_msg            descripcion   = null,
   @t_rty            char(1)       = null,
   @t_trn            int           = null,
   @t_debug          char(1)       = 'N',
   @t_file           varchar(14)   = null,
   @t_from           varchar(30)   = null,
   --variables
   @i_id_inst_proc   int,    --codigo de instancia del proceso
   @i_id_inst_act    int,
   @i_id_empresa     int,
   @i_etapa_flujo    varchar(10)  = 'FIN',-- LGU 2017-07-13: para ver en que momento se ccrea el DES y LIQ del prestamo
                                          -- (1) IMP: impresion: solo crear OP hijas
                                          -- (2) FIN: al final del flujo: crea DES y LIQ de OP hijas
   @i_fecha_ini      datetime     = null, -- para crear las operaciones hijas
   @o_id_resultado   smallint out
)
as
declare
   @w_error             int,
   @w_return            int,
   @w_tramite           int,
   @w_grupal            varchar(1),
   @w_codigo_proceso    int,
   @w_version_proceso   int,
   @w_cliente           int,
   @w_codigo_tramite    char(50),
   @w_sp_name           varchar(30),
   @w_rule              int,
   @w_rule_version      int,
   @w_retorno_val       varchar(255),
   @w_retorno_id        int,
   @w_variables         varchar(255),
   @w_result_values     varchar(255),
   @w_tasa_grupal       float,
   @w_forma_desembolso  catalogo,
   @w_forma_pago        catalogo,
   @w_cod_oficial       int,
   @w_ofi_def_app_movil smallint,
   @w_fecha_proceso     datetime,
   @w_fecha_dispersion  datetime



select @w_sp_name = 'sp_pasa_cartera_wf'
select @w_error = 0
-- PARAMETRO NOTA DE CREDITO CARTERA
select @w_forma_desembolso = pa_char
from cobis..cl_parametro
where pa_nemonico = 'NCRAHO' --NOTA DE CREDITO AHORRO
and   pa_producto = 'CCA'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end

-- PARAMETRO NOTA DE DEBITO CARTERA
select @w_forma_pago = pa_char
from cobis..cl_parametro
where pa_nemonico = 'NCDAHO' --NOTA DE CREDITO AHORRO
and   pa_producto = 'CCA'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end
/*
select @w_tramite = convert(int, io_campo_3)
from cob_workflow..wf_inst_proceso
where io_id_inst_proc = @i_id_inst_proc
*/
select @w_cod_oficial = oc_oficial,
       @w_grupal  = tr_grupal,
	   @w_tramite = convert(int, io_campo_3)
from cob_workflow..wf_inst_proceso
inner join cob_credito..cr_tramite on io_campo_3 = tr_tramite
inner join cobis..cc_oficial on oc_oficial = tr_oficial
inner join cobis..cl_funcionario on oc_funcionario = fu_funcionario
where io_id_inst_proc = @i_id_inst_proc

-- PRINT 'NUMERO DE OFICINA POR DEFECTO DEL APP MOVIL'
select @w_ofi_def_app_movil = pa_smallint 
from   cobis..cl_parametro 
where  pa_nemonico = 'OFIAPP' 
and    pa_producto = 'CRE'

if(@s_ofi = @w_ofi_def_app_movil)
begin
	select @s_ofi = fu_oficina	
	from   cobis..cl_funcionario, 
	       cobis..cc_oficial
	where  oc_oficial     = @w_cod_oficial
	and    oc_funcionario = fu_funcionario
end

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

/*
select @w_grupal  = tr_grupal
from cob_credito..cr_tramite
where tr_tramite = @w_tramite
*/

/*** Estado A para el tramite, estado Aprobado ***/

if @w_grupal is null begin
   exec @w_error = cob_cartera..sp_pasa_cartera
   @s_ssn     = @s_ssn,
   @s_ofi     = @s_ofi,
   @s_user    = @s_user,
   @s_date    = @s_date,
   @s_term    = @s_term,
   @i_tramite = @w_tramite,
   @i_forma_desembolso = @w_forma_desembolso


   if @w_error <> 0 begin
       select
       @o_id_resultado = 3, -- Error
       @w_error        = @w_error,
       @w_sp_name      = 'cob_cartera..sp_pasa_cartera'
       goto ERROR
   end
end

if @w_grupal = 'S' begin
   select
   @w_rule         = bpl_rule.rl_id,
   @w_rule_version = rv_id
   from cob_pac..bpl_rule inner join cob_pac..bpl_rule_version
   on bpl_rule.rl_id = bpl_rule_version.rl_id
   where rv_status  = 'PRO'
   and   rl_acronym = 'TASA_GRP'
   and   getdate() >= rv_date_start
   and   getdate() <= rv_date_finish

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
   @i_id_inst_proc    = @i_id_inst_proc,
   @i_id_inst_act     = @i_id_inst_act,
   @i_id_asig_act     = 0,
   @i_id_empresa      = @i_id_empresa,
   @i_acronimo_regla  = 'TASA_GRP'

   if @w_error <> 0 begin
       select
       @o_id_resultado = 3, -- error
       @w_error        = @w_error,
       @w_sp_name      = 'cob_pac..sp_exec_variable_by_rule'
       goto ERROR
   end

   --Se ejecuta la regla
   select
   @w_retorno_val   = '0',
   @w_retorno_id    = 0,
   @w_variables     = '',
   @w_result_values = ''

 --  print 'ID. PROCESO: '+ convert(varchar, @i_id_inst_proc)
  -- print 'ID. REGLA: '+ convert(varchar, @w_rule)
  -- print 'ID. VERSION REGLA: '+ convert(varchar, @w_rule_version)

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
   @i_id_inst_proceso = @i_id_inst_proc,
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
       @o_id_resultado = 3, -- error
       @w_error        = @w_error,
       @w_sp_name      = 'cob_pac..sp_rules_run'
       goto ERROR
   end

   select @w_tasa_grupal = convert(float, @w_retorno_val)

--   print '@w_tasa_grupal: '+convert(varchar, @w_tasa_grupal)
   
 --  print 'SMO @i_fecha_ini>> '+convert(varchar,@i_fecha_ini)


      --SMO cuando el desembolso se hace en una fecha posterior a la fecha de dispersión configurada
   select @w_fecha_dispersion = tr_fecha_dispersion 
   from cob_credito..cr_tramite
   where tr_tramite = @w_tramite
	
	
--   print 'SMO @w_fecha_dispersion>> '+convert(varchar,@w_fecha_dispersion)

   if @w_fecha_dispersion < @w_fecha_proceso  
   begin
   	  update cob_cartera..ca_operacion
      set op_fecha_ini = @w_fecha_proceso,
      op_fecha_liq     = @w_fecha_proceso
      where op_tramite = @w_tramite
      
      select @i_fecha_ini = null
   end

   exec @w_error     = cob_cartera..sp_desembolso_grupal
   @s_ofi            = @s_ofi,
   @s_user           = @s_user,
   @s_date           = @s_date,
   @s_term           = @s_term,
   @i_tramite_grupal = @w_tramite,
   @i_oficina        = @s_ofi,
   @i_grupal         = @w_grupal,
   @i_tasa           = @w_tasa_grupal,
   @i_forma_pago     = @w_forma_pago,
   @i_forma_desembolso = @w_forma_desembolso,
   @i_etapa_flujo      = @i_etapa_flujo,      -- LGU: envio etapa para separar la creacion de la liquidacion
   @i_fecha_ini        = @i_fecha_ini -- SMO para crear las hijas con la fecha ini del padre, si es null toma la fecha de proceso

   if @w_error <> 0 begin
       select
       @o_id_resultado = 3, -- error
       @w_error        = @w_error,
       @w_sp_name      = 'cob_cartera..sp_desembolso_grupal'
       goto ERROR
   end
end

select @o_id_resultado = 1 --OK

return 0
ERROR:
    exec cobis..sp_cerror @t_from = @w_sp_name, @i_num = @w_error
    return @w_error
GO
