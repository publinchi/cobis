/**********************************************************/
/*  ARCHIVO:         aprobaciones_aso_wf_grp.sp           */
/*  NOMBRE LOGICO:   sp_aprobaciones_aso_wf_grp           */
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
/*  Se consulta las excepciones de politicas específicas  */
/*  por integrante de un grupo                            */
/**********************************************************/
/*                   MODIFICACIONES                       */
/*     FECHA         AUTOR              RAZON             */
/*  16-09-2021    Paul Moreno      Emision Inicial        */
/*  05-11-2021    Patricio Mora    Migración a GFI        */
/**********************************************************/
use cob_workflow
go

if exists(select 1 from sysobjects where name ='sp_aprobaciones_aso_wf_grp')
   drop procedure sp_aprobaciones_aso_wf_grp
go

create procedure sp_aprobaciones_aso_wf_grp
(
  @s_ssn                 int         = null,
  @s_user                varchar(30) = null,
  @s_sesn                int         = null,
  @s_term                varchar(30) = null,
  @s_date                datetime    = null,
  @s_srv                 varchar(30) = null,
  @s_lsrv                varchar(30) = null,
  @s_ofi                 smallint    = null,
  @t_trn                 int         = null,
  @t_debug               char(1)     = 'N',
  @t_file                varchar(14) = null,
  @t_from                varchar(30) = null,
  @s_rol                 smallint    = null,
  @s_org_err             char(1)     = null,
  @s_error               int         = null,
  @s_sev                 tinyint     = null,
  @s_msg                 descripcion = null,
  @s_org                 char(1)     = null,
  @t_rty                 char(1)     = null,  
  @i_cliente             int         = null, --Id cliente                                                                                                                                                                                             
  @i_grupo               int         = null, --Id grupo
  @i_inst_prosc          int         = null  --Instancia de proceso
)   
as
declare 
  @w_id_inst_actividad   int,
  @w_id_paso             int,
  @w_sp_name             varchar(32),
  @w_error               int,
  @w_mensaje             varchar(255)

select @w_sp_name = 'sp_aprobaciones_aso_wf_grp'

if @t_trn != 21835
 begin
    select @w_error = 1720075 -- TRANSACCION NO PERMITIDA
    goto ERROR
 end
 
 if @i_inst_prosc is not null and @i_inst_prosc <> 0
  begin
      select @w_id_inst_actividad    = ia_id_inst_act,
             @w_id_paso              = ia_id_paso
        from wf_inst_actividad 
       where ia_estado               = 'ACT'
         and ia_id_inst_proc         = @i_inst_prosc
         and isnull(ia_tipo_dest,'') <> 'PRO'
  end
    
 if @w_id_inst_actividad is not null
  begin
        select distinct 
                        ia_nombre_act                                                                             'nombre_actividad',
                        ia_estado                                                                                 'estado',
                        'P'                                                                                       'tipo',
                        rl_id                                                                                     'id_tipo',
                        rl_name                                                                                   'nombre',
                        ia_secuencia                                                                              'secuencia',
                        rl_acronym                                                                                'acronym',
                        (case when @w_id_paso = ae_id_paso then 'true' else 'false' end )                         'actual_activity',
                        ae_id_jerarquia                                                                           'id_jerarquia',
                        ae_id_rol                                                                                 'id_rol',
                        null                                                                                      'desc_observacion',
                        (select aa_id_inst_act from wf_asig_actividad where aa_id_asig_act in (rphc_id_asig_act)) 'id_actividad',
                        rl_id                                                                                     'id_regla'
                   from wf_inst_proceso io
             inner join (select cob_workflow..wf_inst_actividad.ia_id_inst_act, cob_workflow..wf_inst_actividad.ia_id_inst_proc, cob_workflow..wf_inst_actividad.ia_codigo_act, cob_workflow..wf_inst_actividad.ia_nombre_act, cob_workflow..wf_inst_actividad.ia_func_asociada, 
                                cob_workflow..wf_inst_actividad.ia_secuencia, cob_workflow..wf_inst_actividad.ia_estado, cob_workflow..wf_inst_actividad.ia_fecha_inicio, cob_workflow..wf_inst_actividad.ia_fecha_fin, cob_workflow..wf_inst_actividad.ia_id_paso, 
                                cob_workflow..wf_inst_actividad.ia_retrasada, cob_workflow..wf_inst_actividad.ia_mensaje, cob_workflow..wf_inst_actividad.ia_tipo_dest, cob_workflow..wf_inst_actividad.ia_id_destinatario, cob_workflow..wf_inst_actividad.id_inst_act_parent, 
                                cob_workflow..wf_inst_actividad.ia_error_politicas, cob_workflow..wf_inst_actividad.ia_ssn                                                                                                                                                              
                   from cob_workflow..wf_inst_actividad 
                  where ia_id_inst_proc = @i_inst_prosc
               group by ia_id_paso, ia_fecha_inicio, ia_id_inst_act, ia_id_inst_proc, ia_codigo_act, ia_nombre_act, ia_func_asociada, ia_secuencia, ia_estado, 
                        ia_fecha_fin, ia_retrasada, ia_mensaje, ia_tipo_dest, ia_id_destinatario, id_inst_act_parent, ia_error_politicas, ia_ssn
                 having ia_fecha_inicio     = max (ia_fecha_inicio)) ia on io_id_inst_proc    = ia_id_inst_proc
             inner join cob_pac..bpl_rule_process_his rph               on io_id_inst_proc    = rph_id_inst_proc
             inner join cob_pac..bpl_rule_process_his_cli               on rph_rule_id        = rphc_rule_id_padre         and rph.rph_id_inst_proc = rphc_id_inst_proc
             inner join cob_pac..bpl_rule r                             on rl_id              = rphc_rule_id
             inner join wf_aprobacion_excepcion ae                      on rphc_rule_id_padre = ae_id_politica_o_documento and ia_id_paso           = ae_id_paso
                    and ae_tipo_excepcion   = 'P'
                  where io_id_inst_proc     = @i_inst_prosc
                    and rphc_grupo_id       = @i_grupo
                    and rphc_cliente_id     = @i_cliente
                    and ia_id_inst_act     <= (select max(ia_id_inst_act) from wf_inst_actividad where ia_id_inst_proc = @i_inst_prosc) --@w_id_inst_actividad --DFL-27/06/2018 Se modifica para que barra todas las actividades en caso de ser paralelas Inc#101805
                    and rph_valor           = 'EXCEPCION'
                    and ('S' is null or 'S' = rph_ultima_evaluacion)
  end
    else
     begin
        select  
            @w_error    = 31076001,
            @w_mensaje  = 'NO EXISTE INSTANCIAS DE ACTIVIDAD PARA LA INSTANCIA O CODIGO ALTERNO DEL PROCESO'
        goto ERROR
     end

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
