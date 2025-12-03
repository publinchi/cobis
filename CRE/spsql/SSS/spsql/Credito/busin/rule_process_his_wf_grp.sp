/**********************************************************/
/*  ARCHIVO:         rule_process_his_wf_grp.sp           */
/*  NOMBRE LOGICO:   sp_rule_process_his_wf_grp           */
/*  PRODUCTO:        COBIS WORKFLOW                       */
/**********************************************************/
/*                    IMPORTANTE                          */
/*  Esta aplicacion es parte de los  paquetes bancarios   */
/*  propiedad de COBISCORP.                               */
/*  Su uso no autorizado queda  expresamente  prohibido   */
/*  asi como cualquier alteracion o agregado hecho  por   */
/*  alguno de sus usuarios sin el debido consentimiento   */
/*  por escrito de COBISCORP.                             */
/*  Este programa esta protegido por la ley de derechos   */
/*  de autor y por las convenciones internacionales de    */
/*  propiedad intelectual. Su uso no autorizado dara      */
/*  derecho a COBISCORP para obtener ordenes de secuestro */
/*  o  retencion  y  para  perseguir  penalmente a  los   */
/*  autores de cualquier infraccion.                      */
/**********************************************************/
/*                      PROPOSITO                         */
/*  Consultar las politicas que cumplen por cada          */
/*  integrante del grupo                                  */
/**********************************************************/
/*                   MODIFICACIONES                       */
/*     FECHA         AUTOR              RAZON             */
/*  19-09-2021    Paul Moreno      Emision Inicial        */
/*  05-11-2021    Patricio Mora    Migración a GFI        */
/**********************************************************/
use cob_workflow
go

if exists(select 1 from sysobjects where name ='sp_rule_process_his_wf_grp')
   drop procedure sp_rule_process_his_wf_grp
go

--Creacion de sp
create procedure sp_rule_process_his_wf_grp 
(
    @s_ssn                  int          = null,
    @s_user                 varchar(30)  = null,
    @s_sesn                 int          = null,
    @s_term                 varchar(30)  = null,
    @s_date                 datetime     = null,
    @s_srv                  varchar(30)  = null,
    @s_lsrv                 varchar(30)  = null,
    @s_ofi                  smallint     = null,
    @t_trn                  int          = null,
    @t_debug                char(1)      = 'N',
    @t_file                 varchar(14)  = null,
    @t_from                 varchar(30)  = null,
    @s_rol                  smallint     = null,
    @s_org_err              char(1)      = null,
    @s_error                int          = null,
    @s_sev                  tinyint      = null,
    @s_msg                  descripcion  = null,
    @s_org                  char(1)      = null,
    @t_rty                  char(1)      = null,
    @s_culture              varchar(10)  = null,
    @i_id_inst_proc         int,
    @i_cliente              int          = null,  --Id cliente                                                                                                                                                                                             
    @i_grupo                int          = null   --Id grupo
)
--Declaracion de variables
as 
declare 
    @w_sp_name              varchar(64),
    @w_hist_pol_no_activos  char(1),
    @w_ultima_version       varchar(1),
    @spid                   int,
    @w_ia_id_paso           int,
    @w_table_code           int,
    @w_table_name           varchar(64),
    @w_table_code2          int,
    @w_table_name2          varchar(64),
    @w_msg                  varchar(64),
    @w_codigo_proc          int, 
    @w_version_proc         int,
    @w_error                int

select @w_sp_name     = 'sp_rule_process_his_wf_grp',
       @w_table_name  = 'wf_estado_asignacion',
       @w_table_name2 = 'wf_estado_actividad'

if @t_trn != 21833
begin
    select @w_error = 1720075 -- TRANSACCION NO PERMITIDA
    goto ERROR
end

select @w_table_code = codigo 
  from cobis..cl_tabla 
 where tabla = @w_table_name

if @@rowcount = 0
begin -- No existe registro
  select @w_msg = 'No existe la tabla' + @w_table_name
  exec cobis..sp_cerror
       @i_num  = 2110353,
       @t_from = @w_sp_name
  return 2110353
end

select @w_table_code2 = codigo 
  from cobis..cl_tabla 
 where tabla = @w_table_name2

if @@rowcount = 0
begin -- No existe registro
  select @w_msg = 'No existe la tabla' + @w_table_name2
  exec cobis..sp_cerror
       @i_num  = 2110353,
       @t_from = @w_sp_name
  return 2110353
end

--print 'Consulta todos los historicos de reglas ejecutadas'    
select @w_ultima_version = null
        
select @w_ia_id_paso   = ia_id_paso, 
       @w_codigo_proc  = io_codigo_proc,
       @w_version_proc = io_version_proc 
  from wf_inst_proceso, wf_inst_actividad, wf_asig_actividad
 where io_id_inst_proc = ia_id_inst_proc
   and ia_id_inst_act  = aa_id_inst_act
   and ia_estado       = 'ACT'
   and io_id_inst_proc = @i_id_inst_proc
    
select @spid = @@spid
exec sp_paso_recursivo_wf 
     @i_spid       = @spid, 
     @i_paso_padre = @w_ia_id_paso

select @w_ultima_version = pa_char 
  from cobis..cl_parametro 
 where pa_producto = 'CWF' 
   and pa_nemonico = 'EVULEX'

if @w_ultima_version is null
begin
    select @w_ultima_version  = 'N'
end 

create table #rule_process_his 
(        
    rph_rule_id          int,
    rphc_rule_id         int,
    rph_rule_version     int,
    rph_id_inst_proc     int,
    rph_id_asig_act      int, 
    rph_valor            varchar(255),
    rph_error            varchar(255) null, 
    rph_tipo             varchar(10), 
    rph_cod_variable     int,
    rph_descripcion      varchar(255) null,       
    ac_codigo_actividad  int,
    ac_nombre_actividad  varchar(64),
    rphc_resul_regla     varchar(255)
)

insert into #rule_process_his       
    select  
           rph_rule_id,         -- Id Regla Padre
           rphc_rule_id,        -- Id Regla Hija
           rph_rule_version,
           rph_id_inst_proc,
           rph_id_asig_act, 
           rphc_valor,
           rph_error, 
           rph_tipo,
           rphc_cod_variable,
           rph_descripcion,        
           ac_codigo_actividad,
           ac_nombre_actividad,
           hc.rphc_resultado_regla
      from cob_pac..bpl_rule_process_his h     
inner join cob_pac..bpl_rule_process_his_cli hc on h.rph_rule_id = hc.rphc_rule_id_padre and h.rph_id_inst_proc = hc.rphc_id_inst_proc      
inner join wf_asig_actividad aa on aa.aa_id_asig_act     = h.rph_id_asig_act
inner join wf_inst_actividad ia on ia.ia_id_inst_act     = aa.aa_id_inst_act
inner join wf_actividad      a  on a.ac_codigo_actividad = ia.ia_codigo_act
     where h.rph_id_inst_proc = @i_id_inst_proc
       and h.rph_tipo         = 'P'
       and (@w_ultima_version = 'N' or @w_ultima_version = rph_ultima_evaluacion)
       and rph_is_result      = 1 
       and rphc_id_asig_act   > 0  
       and hc.rphc_grupo_id   = @i_grupo
       and hc.rphc_cliente_id =  @i_cliente

select distinct
                'CODIGO_REGLA'       = rph_rule_id,
                'VERSION_REGLA'      = rph_rule_version,
                'INSTANCIA_PROCESO'  = rph_id_inst_proc,
                'ASIGNA_ACTIVIDAD'   = rph_id_asig_act,
                'NOMBRE_ACTIVIDAD'   = ac_nombre_actividad,
                'CODIGO_VARAIBLE'    = rph_cod_variable,
                'NOMBRE_VARIABLE'    = vb_nombre_variable,
                'VALOR'              = rphc_resul_regla,
                'RESULT'             = (select max(rph_is_result) from cob_pac..bpl_rule_process_his h2 where rph_id_inst_proc = @i_id_inst_proc and rph_error = 'OK' and r.rl_id = h2.rph_rule_id), 
                'ERROR'              = rph_error,
                'TIPO'               = rph_tipo,
                'SISTEMA'            = r.rl_system,     
                'SUBTIPO_REGLA'      = r.rl_subtype ,       
                'NOMBRE_REGLA'       = r.rl_name,
                'ACRONIMO_REGLA'     = r.rl_acronym,
                'DESCRIPCION'        = rph_descripcion,
                'ID JERARQUIA'       = isnull(ae_id_jerarquia,0),
                'ID ROL'             = isnull((select distinct ae_id_rol   from wf_aprobacion_excepcion, cob_pac..bpl_rule_process_his where ae_id_paso in 
				                              (select max(pat_id_paso_fin) from wf_pasos_anteriores_tmp where pat_spid = @spid) and ae_id_politica_o_documento = rph_rule_id),0),
                'CODIGO REGLA HIJA'  = rphc_rule_id 
           from #rule_process_his h
     inner join cob_pac..bpl_rule r on r.rl_id = h.rphc_rule_id
      left join wf_variable       v on v.vb_codigo_variable  =  h.rph_cod_variable
     inner join wf_destinatario d   on d.de_codigo_proceso   =  @w_codigo_proc 
	                           and d.de_version_proceso  = @w_version_proc
                                   and d.de_codigo_actividad = h.ac_codigo_actividad
      left join wf_aprobacion_excepcion ae 
	                            on  rph_rule_id          = ae_id_politica_o_documento 
		                   and ae_tipo_excepcion     = h.rph_tipo
                                   and ae_id_jerarquia       = d.de_id_destinatario
       order by rph_rule_id, rph_id_asig_act, rph_cod_variable
        
delete 
  from cob_workflow..wf_pasos_anteriores_tmp 
 where pat_spid = @spid

return 0

ERROR:
begin --Devolver mensaje de Error
    select @w_error
    exec cobis..sp_cerror
           @t_debug = @t_debug,
           @t_file  = @t_file,
           @t_from  = @w_sp_name,
           @i_num   = @w_error
    return @w_error
end

go
