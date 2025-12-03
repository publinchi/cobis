

use cob_cartera
go


if object_id ('sp_desembolso_incumplido_wf') is not null
   drop procedure sp_desembolso_incumplido_wf
go
/*************************************************************************/
/*   Archivo:            desembolso_incumplido_wf.sp                     */
/*   Stored procedure:   sp_desembolso_incumplido_wf                     */
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
/*   prestamos otorgados, si cumple las condiciones y no ha desembolsado */
/*   envia notificaciones                                                */
/*************************************************************************/
/*                                MODIFICACIONES                         */
/*   FECHA               AUTOR                       RAZON               */
/*   15-09-2018          SMO                   Emision Inicial           */
/*************************************************************************/
create procedure sp_desembolso_incumplido_wf
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
   @w_faltan_docs        int --numero de documentos grupales faltantes



select @w_sp_name = 'sp_desembolso_incumplido_wf'

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
   
   select @w_faltan_docs = count(distinct(rc_codigo_tipo_doc)) from cob_workflow..wf_requisito_actividad WHERE rc_id_paso = @w_id_paso
   AND rc_codigo_tipo_doc 
   NOT IN (select ri_codigo_tipo_doc from cob_workflow..wf_req_inst WHERE ri_id_inst_proc = @w_inst_proc) 

   PRINT 'faltan docs '+convert(VARCHAR(10),@w_faltan_docs) 
   	
   --VALIDA QUE TENGA TODOS LOS DOCUMENTOS DIGITALIZADOS CARGADOS
   if exists(select  1 from cob_credito..cr_documento_digitalizado  where dd_grupo = @w_grupo and dd_cargado= 'N' and dd_inst_proceso = @w_inst_proc ) or @w_faltan_docs <> 0
   begin
       --id de la plantilla
       select @w_id = te_id 
       from cobis..ns_template
       where te_nombre = 'NotifDesembolsosNoRealizados.xslt'

       -- codigo de la etapa de aprobacion 
       select @w_codigo_act_apr = pa_int
       from   cobis..cl_parametro with (nolock)
       where  pa_producto = 'CCA'
       and    pa_nemonico = 'CAAPSO'
      
       -- oficial que atendió el trámite en la etapa de aprobación
       select @w_cod_gerente = fu_funcionario
       from cob_workflow..wf_inst_proceso  ,
         cob_workflow..wf_inst_actividad,
         cob_workflow..wf_asig_actividad,
         cob_workflow..wf_usuario       , 
         cobis..cl_funcionario    
       where io_campo_3         = @w_tramite
       and   ia_id_inst_proc    = io_id_inst_proc
       and   ia_id_inst_act     = aa_id_inst_act
       and   aa_id_destinatario = us_id_usuario
       and   us_login           = fu_login
       and   ia_codigo_act      = @w_codigo_act_apr
   

      select @w_mail_gerente = ''---oc_mail AGI. 22ABR19.  Se comenta porque no se encuentra el campo oc_mail en la tabla cc_oficial
      from cobis..cl_funcionario, cobis..cc_oficial
      where oc_funcionario = @w_cod_gerente

      --rol definido para mesa de operaciones
      select @w_param_mesa = pa_char
      from cobis..cl_parametro 
      where pa_nemonico = 'RMOP' 
      and pa_producto = 'CCA'


       -- codigo del rol de mesa de operaciones
       select @w_rol_mesa = codigo 
       from   cobis..cl_catalogo
       where  tabla        = (select codigo from cobis..cl_tabla
                              where tabla = 'cl_cargo')
       and    upper(valor) = @w_param_mesa 


      -- mail del funcionario con ROL MESA DE OPERACIONES (SI HAY MAS DE UNO TOMA EL PRIMERO)
      select TOP 1 @w_mail_mesa = ''---oc_mail AGI. 22ABR19.  Se comenta porque no se encuentra el campo oc_mail en la tabla cc_oficial
      from cobis..cl_funcionario, cobis..cc_oficial
      where fu_cargo = @w_rol_mesa
      and fu_funcionario = oc_funcionario


       --SECCION NOMBRE DEL GRUPO
       select @w_nombre_grupo = gr_nombre
       from cobis..cl_grupo
       where gr_grupo = @w_grupo

       select @w_subject = 'Digitalización de documentos incompleta del grupo '+@w_nombre_grupo

      --CREACION DEL XML PARA EL ENVIO

       select @w_body = '<?xml version=''1.0'' encoding=''ISO-8859-1''?><data><date>'+convert(varchar(25),@w_fecha_proceso,103)+'</date><group>'+@w_nombre_grupo+'</group></data>'

       if @w_mail_gerente is null begin
          select @w_error = 5000,
                 @w_msg = 'No existe mail para el gerente'
          goto ERROR1
      end 
       if @w_mail_mesa is null begin
           select @w_error = 5000,
                 @w_msg = 'No existe mail para el rol mesa de operaciones'
          goto ERROR1
      end
       exec @w_error =  cobis..sp_despacho_ins
        @i_cliente          = @w_grupo,
        @i_template         = @w_id,
        @i_servicio         = 1,
        @i_estado           = 'P',
        @i_tipo             = 'MAIL',
        @i_tipo_mensaje     = 'I',
        @i_prioridad        = 1,
        @i_from             = null,
        @i_to               = @w_mail_gerente,
        @i_cc               = @w_mail_mesa,
        @i_bcc              = null,
        @i_subject          = @w_subject,
        @i_body             = @w_body,
        @i_content_manager  = 'HTML',
        @i_retry            = 'S',
        @i_fecha_envio      = null,
        @i_hora_ini         = null,
        @i_hora_fin         = null,
        @i_tries            = 0,
        @i_max_tries        = 2,
        @i_var1             = null

       if @w_error <> 0
      begin
          select @w_msg = 'ERROR AL ENVIAR NOTIFICACION DE LA OPERACION '+convert(varchar(100),@w_operacionca),
		  @w_error = 5000
          goto ERROR1
       end


	end
   
   ERROR1:
  print 'ERROR A INSERTAR>> '+convert(varchar(10),@w_error)+' mensaje>>'+@w_msg

   CONTINUAR:
end --end while


return 0
GO
