use cob_cartera
go

if object_id ('sp_desembolso_diario_wf') is not null
   drop procedure sp_desembolso_diario_wf
go
/*************************************************************************/
/*   Archivo:            sp_desembolso_diario_wf.sp                      */
/*   Stored procedure:   sp_desembolso_diario_wf                         */
/*   Base de datos:      cob_workflow                                    */
/*   Producto:           Originacion                                     */
/*   Disenado por:       SMO                                             */
/*   Fecha de escritura: 15/09/2018                                      */
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
/*   Este procedimiento almacenado, revisa fecha de dispersion de los    */
/*   prestamos otorgados, si cumple las condiciones desembolsa, caso    */
/*   contrario envia notificaciones                                     */
/*************************************************************************/
/*                                MODIFICACIONES                         */
/*   FECHA               AUTOR                       RAZON               */
/*   15-09-2018          SMO                   Emision Inicial           */
/*************************************************************************/
create procedure sp_desembolso_diario_wf
(
   @s_ssn            int           = null,
   @s_ofi            smallint      = null,
   @s_user           login         = null, 
   @s_date           datetime      = null,
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
   @i_param1          datetime      = null --fecha de proceso
  -- @o_id_resultado   smallint out
)
as
declare
   @w_return            int,
   @w_sp_name           varchar(30),
   @w_resultado         smallint,
   @w_etapa             descripcion,
   @w_operacionca       int,
   @w_tramite           int,
   @w_fecha_proceso     datetime,
   @w_inst_proc         int,
   @w_grupo             int,
   @w_cod_act           int,
   @w_dispersion        char(1),
   @w_empresa           smallint,
   @w_error             int,
   @w_msg               varchar(200),
   @w_id                int,
   @w_oficial           int,
   @w_cod_gerente       int,
   @w_mail_gerente      varchar(50),
   @w_mail_mesa         varchar(50),
   @w_cod_rol_mesa     int,
   @w_nombre_grupo        varchar(50),
   @w_subject            varchar(100),
   @w_body               varchar(500),
   @w_funcionario        int,
   @w_codigo_act_apr       int,
   @w_rol_mesa             int,
   @w_param_mesa         varchar(60),
   @w_id_paso            int,
   @w_faltan_docs        int, --numero de documentos grupales faltantes
   @w_oficina            int

select @w_sp_name = 'sp_desembolso_diario_wf'

if @i_param1 is not null
   select @w_fecha_proceso = @i_param1
else
   select @w_fecha_proceso = fp_fecha 
   from cobis..ba_fecha_proceso

select @w_empresa = pa_tinyint 
from   cobis..cl_parametro
where  pa_nemonico = 'EMP' and pa_producto = 'ADM'

SELECT @w_etapa = pa_char
FROM cobis..cl_parametro 
WHERE pa_nemonico = 'VYDIG'
and pa_producto = 'CCA'

if @@rowcount = 0 
begin
   exec cobis..sp_cerror
   @t_debug = @t_debug,
   @t_file  = @t_file,
   @t_from  = @w_sp_name,
   @i_num   = 2101039 --No se pudo encontrar la etapa correspondiente al Paso Actual en la Ruta 
end

select @w_operacionca = 0		
while 1=1
begin
   set rowcount 1
   select @w_tramite          = op_tramite,
		  @w_operacionca      = op_operacion
     from cob_credito..cr_tramite,
          cob_cartera..ca_operacion
    where op_tramite          = tr_tramite
	  and op_estado           = 0 -- no desembolsada
	  and tr_fecha_dispersion = @w_fecha_proceso
	  and op_operacion        > @w_operacionca
   order by op_operacion
 
   if @@rowcount = 0
   begin
      set rowcount 0
      break
   end
   set rowcount 0
     
   select @w_inst_proc = io_id_inst_proc,
          @w_grupo     =  io_campo_1
   from cob_workflow..wf_inst_proceso
   where io_campo_3 = @w_tramite

   if(@@rowcount = 0)
   begin
      select @w_return = 3107608  --NO EXISTE INSTANCIA DE PROCESO
	  goto CONTINUAR
   end 
   
   -- SI NO ESTA EN LA ETAPA DE VERIFICAR Y DIGITALIZAR SALTA EL WHILE
   SELECT @w_cod_act = ia_id_inst_act
   FROM cob_workflow..wf_inst_actividad 
   WHERE ia_nombre_act   = @w_etapa
   and   ia_id_inst_proc = @w_inst_proc --VERIFICAR Y DIGITALIZAR
   and ia_estado = 'ACT'

   if(@@rowcount = 0)
   begin
      select @w_return = 3107523  --NO EXISTE ACTIVIDAD ASOCIADA.
	  goto CONTINUAR
   end 

   select @w_id_paso	  = ia_id_paso
   from cob_workflow..wf_inst_actividad
   where ia_id_inst_proc =  @w_inst_proc
   and ia_estado 	= 'ACT'
   and ia_tipo_dest is NULL
   
   
   select  @w_faltan_docs = count(distinct(tr_codigo_tipo_doc)) 
   from cob_workflow..wf_tipo_req_act, cob_workflow..wf_tipo_documento 
   where 
   td_codigo_tipo_doc = tr_codigo_tipo_doc
   and td_vigencia_doc = 'V'
   and tr_id_paso = @w_id_paso
   and tr_codigo_tipo_doc 
   NOT IN (select ri_codigo_tipo_doc from cob_workflow..wf_req_inst WHERE ri_id_inst_proc = @w_inst_proc) 
   

    PRINT 'faltan docs '+convert(VARCHAR(10),@w_faltan_docs)+' TRAMITE>>'+convert(varchar,@w_tramite) 
   	
   --VALIDA QUE TENGA TODOS LOS DOCUMENTOS DIGITALIZADOS CARGADOS
   if not exists(select  1 from cob_credito..cr_documento_digitalizado  where dd_grupo = @w_grupo and dd_cargado= 'N' and dd_inst_proceso = @w_inst_proc ) and @w_faltan_docs = 0
   begin    
      print 'DESEMBOLSA!!! >>'+ convert(varchar,@w_tramite) 
      --Cambiar el campo ia_error_politicas, en caso de que tenga error porque la fecha de dispersión no coincidía, ya que si llega a este punto la fecha ya coincide
      update cob_workflow..wf_inst_actividad 
      set ia_error_politicas = 'N' 
	  WHERE ia_nombre_act   = @w_etapa
      and   ia_id_inst_proc = @w_inst_proc --VERIFICAR Y DIGITALIZAR
      and ia_estado = 'ACT'

	  select  @w_oficina = tr_oficina from cob_credito..cr_tramite where tr_tramite =  @w_tramite
     
     begin try 
         exec cob_cartera..sp_ruteo_actividad_wf
         @s_ssn             =  11111, 
         @s_user            =  'sa',
         @s_sesn            =   11111,
         @s_term            =  'srvbatch',
         @s_date            =  @w_fecha_proceso,
         @s_srv             =  '',
         @s_lsrv            =  '',
         @s_ofi             =  @w_oficina,
         @i_tramite         =  @w_tramite,
	     @i_param_etapa         = 'VYDIG'     
      end try
      begin catch
         if @@trancount > 0 rollback transaction
         
         select 
         @w_error = 5000,
         @w_msg = 'ERROR AL RUTEAR EL TRAMITE '+convert(varchar(10),@w_tramite)

      end catch
	  
    end 
  
     ERROR1:
     print 'ERROR A INSERTAR>> '+convert(varchar(10),@w_error)+' mensaje>>'+@w_msg
 
   CONTINUAR:
end --end while


return 0
GO
