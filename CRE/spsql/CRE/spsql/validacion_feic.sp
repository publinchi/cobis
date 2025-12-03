/**************************************************************************/
/*  Archivo:                validacion_feic.sp                            */
/*  Stored procedure:       sp_validacion_feic                            */
/*  Producto:               Credito                                       */
/*  Disenado por:           Carlos Obando                                 */
/*  Fecha de escritura:     09-12-2021                                    */
/**************************************************************************/
/*                              IMPORTANTE                                */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad          */
/*  de COBISCorp.                                                         */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como      */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus      */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.     */
/*  Este programa esta protegido por la ley de   derechos de autor        */
/*  y por las    convenciones  internacionales   de  propiedad inte-      */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para    */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir          */
/*  penalmente a los autores de cualquier   infraccion.                   */
/**************************************************************************/
/*               PROPOSITO                                                */
/*   Este programa se usa para los procesos de DFA para originador        */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA       AUTOR           RAZON                                     */
/*  09-12-2021  COB             Emision inicial                           */
/*  06-06-2022  DMO             Se valida participantes de credito grupal */
/**************************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_validacion_feic')
   drop proc sp_validacion_feic
go

create proc sp_validacion_feic (
   @s_ssn                     int           = null,
   @s_sesn                    int           = null,
   @s_user                    login         = null,
   @s_term                    varchar(32)   = null,
   @s_date                    datetime      = null,
   @s_srv                     varchar(30)   = null,
   @s_lsrv                    varchar(30)   = null,
   @s_ofi                     smallint      = null,
   @s_rol                     smallint      = null,
   @s_org_err                 char(1)       = null,
   @s_error                   int           = null,
   @s_sev                     tinyint       = null,
   @s_msg                     descripcion   = null,
   @s_org                     char(1)       = null,
   @s_culture                 varchar(10)   = 'NEUTRAL',
   @t_debug                   char(1)       = 'n',
   @t_file                    varchar(10)   = null,
   @t_from                    varchar(32)   = null,
   @t_trn                     int           = null,
   @t_show_version            bit           = 0,     -- versionamiento
   @i_operacion               char(1)       = null,
   @i_instancia_proceso       int           = null,
   @i_msg                     varchar(255)  = null,
   @i_observacion             int           = null,
   @o_nro_proceso             int           = null output,
   @o_tipo                    char(1)       = null output,
   @o_cliente                 varchar(1000) = null output,
   @o_observacion             int           = null output
)
as
declare @w_sp_name          varchar(30),
        @w_sp_msg           varchar(132),
        @w_oficial          int,
        @w_trn_dir          int,
        @w_error            int,
        @w_existente        bit,
        @w_init_msg_error   varchar(256),
        @w_valor_campo      varchar(30),
        @w_prospecto        char(1)       = 'P',
        @w_param            int, 
        @w_diff             int, 
        @w_date             datetime,
        @w_existe           char(1)       = 'S',
        @w_bloqueo          char(1)       = 'S',
        @w_query            varchar(1000),
        @w_ejec_nombre      varchar(30),
        @w_linea            int,
		@w_tramite 			int ,
		@w_grupo 			int 

select
@w_sp_name          = 'cob_credito..sp_validacion_feic',
@w_error            = 1720548

if @i_operacion = 'Q'  --Devuelve la instancia del numero proceso
begin
   if isnull(@i_instancia_proceso, '') = ''
   begin
      select @w_valor_campo  = '@i_instancia_proceso'
      goto VALIDAR_ERROR
   end

   select @o_nro_proceso = io_campo_3,
          @o_tipo        = io_tipo_cliente
   from cob_workflow..wf_inst_proceso
   where io_id_inst_proc = @i_instancia_proceso

   if @o_nro_proceso = 0 or isnull(@o_nro_proceso,'') = ''
   begin
      select @w_error = 1720599
      goto ERROR_FIN
   end

   if @o_tipo = 'P' --Persona
   begin
      select @o_cliente = io_campo_1
      from cob_workflow..wf_inst_proceso
      where io_id_inst_proc = @i_instancia_proceso
   end
   else --Grupal
   begin
   
	  select 	@w_tramite = io_campo_3 ,
				@w_grupo = io_campo_1 
				from cob_workflow..wf_inst_proceso 
				where io_id_inst_proc = @i_instancia_proceso  
		
      select @o_cliente = concat(@o_cliente, cg_ente,',')
		from cobis..cl_cliente_grupo
		where cg_grupo = @w_grupo
		and cg_ente in 
		(select tg_cliente 
		from cob_credito..cr_tramite_grupal 
		where tg_tramite =@w_tramite 
		and tg_participa_ciclo = 'S')
   end

end

if @i_operacion = 'I'  --Devuelve la instancia del numero proceso
begin
   if isnull(@i_msg, '') = ''
   begin
      select @w_valor_campo  = '@i_msg'
      select @w_error = 2110138
      goto ERROR_FIN
   end

   select @w_ejec_nombre = fu_nombre --Nombre del funcionario
   from   cobis..cl_funcionario
   where  fu_login = @s_user
   
   select @i_instancia_proceso = aa_id_asig_act
   from cob_workflow..wf_inst_actividad,
   cob_workflow..wf_asig_actividad
   where ia_id_inst_proc = @i_instancia_proceso
   and   ia_id_inst_act  = aa_id_inst_act

   if isnull(@i_observacion, 0) = 0 --Numero de la observacion
   begin
      select @o_observacion = max(ob_numero)+1
      from cob_workflow..wf_observaciones
      where ob_id_asig_act = @i_instancia_proceso
   end
   else
   begin
      select @o_observacion = @i_observacion

      select @w_linea = max(ob_lineas)+1
      from cob_workflow..wf_observaciones
      where ob_id_asig_act = @i_instancia_proceso
      and   ob_numero      = @o_observacion

   end
   
   if isnull(@w_linea, 0) = 0 --Linea de la observacion
   begin
      select @w_linea = 1
   end

   --Validaciones de nulos
   if isnull(@o_observacion, 0) = 0
      select @o_observacion = 1
   if isnull(@w_linea, 0) = 0
      select @w_linea = 1

   --Insertando observacion
   if isnull(@i_observacion, 0) = 0 --Numero de la observacion
   begin
      insert into cob_workflow..wf_observaciones( 
              ob_id_asig_act,       ob_numero,      ob_fecha,
              ob_categoria,         ob_lineas,      ob_oficial,
              ob_ejecutivo)
      values (@i_instancia_proceso, @o_observacion, getdate(),
              '',                   @w_linea,       '',
              @w_ejec_nombre)
   end
   else
   begin
      update cob_workflow..wf_observaciones
      set ob_lineas = @w_linea
      where ob_id_asig_act = @i_instancia_proceso
      and ob_numero = @o_observacion
   end
   
   

   --Insertando linea
   insert into cob_workflow..wf_ob_lineas(
          ol_id_asig_act,        ol_observacion, ol_linea,
          ol_texto)
   values(@i_instancia_proceso,  @o_observacion, @w_linea,
          @i_msg)
end

return 0

VALIDAR_ERROR:
   select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo , @w_error, @s_culture)
   goto ERROR_FIN

ERROR_FIN:

   exec cobis..sp_cerror
        @t_debug    = @t_debug,
        @t_file     = @t_file,
        @t_from     = @w_sp_name,
        @i_msg      = @w_sp_msg,
        @i_num      = @w_error
            
   return @w_error

go
