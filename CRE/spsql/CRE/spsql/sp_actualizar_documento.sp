/**************************************************************************/
/*  Archivo:                    sp_actualizar_documento.sp                */
/*  Stored procedure:           sp_actualizar_documento                   */
/*  Base de Datos:              cob_credito                               */
/*  Producto:                   Credito                                   */
/**************************************************************************/
/*                     IMPORTANTE                                         */
/*   Este programa es parte de los paquetes bancarios que son             */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,        */
/*   representantes exclusivos para comercializar los productos y         */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida       */
/*   y regida por las Leyes de la República de España y las               */
/*   correspondientes de la Unión Europea. Su copia, reproducción,        */
/*   alteración en cualquier sentido, ingeniería reversa,                 */
/*   almacenamiento o cualquier uso no autorizado por cualquiera          */
/*   de los usuarios o personas que hayan accedido al presente            */
/*   sitio, queda expresamente prohibido; sin el debido                   */
/*   consentimiento por escrito, de parte de los representantes de        */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto        */
/*   en el presente texto, causará violaciones relacionadas con la        */
/*   propiedad intelectual y la confidencialidad de la información        */
/*   tratada; y por lo tanto, derivará en acciones legales civiles        */
/*   y penales en contra del infractor según corresponda.                 */
/**************************************************************************/
/*                          PROPOSITO                                     */
/*  Este stored procedure permite asociar documento con cliente o instancia*/
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA          AUTOR                         RAZON                    */
/*  20/Ene/2023   Dilan Morales             S717215 - Inicio              */
/*  19/Dic/2023   Dilan Morales             R221386: Se adapta sp         */
/**************************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_actualizar_documento')
   drop proc sp_actualizar_documento
go

CREATE proc sp_actualizar_documento (
    @s_ssn                  int             = null,
    @s_sesn                 int             = null,
    @s_culture              varchar(10)     = null,
    @s_user                 login           = null,
    @s_term                 varchar(30)     = null,
    @s_date                 datetime        = null,
    @s_srv                  varchar(30)     = null,
    @s_lsrv                 varchar(30)     = null,
    @s_ofi                  smallint        = null,
    @s_rol                  smallint        = NULL,
    @s_org_err              char(1)         = NULL,
    @s_error                int             = NULL,
    @s_sev                  tinyint         = NULL,
    @s_msg                  descripcion     = NULL,
    @s_org                  char(1)         = NULL,
    @t_show_version         bit             = 0,
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
    @i_id_inst_proc         int             = null,
	@i_tipo_ent             varchar(10)     = 'CL', --Aplica para cliente CL y Grupo GRUPO
	@i_ente                 int             = null,
	@i_nombre_tipo_doc      varchar(100)    = null,
	@i_nombre_archivo       varchar(255)    = null,
	@i_observacion          varchar(255)    = null
)
as
declare @w_sp_name              varchar(32),
        @w_error                int,
		@w_tramite              int
        
select @w_sp_name = 'sp_actualizar_documento'

select @w_tramite = io_campo_3 from cob_workflow..wf_inst_proceso where io_id_inst_proc = @i_id_inst_proc

if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @w_tramite)
begin
	exec @w_error = cob_interface..sp_management_doc_member
		 @s_user                = @s_user,
		 @s_term                = @s_term,
		 @s_ofi                 = @s_ofi,
		 @s_ssn                 = @s_ssn,
		 @s_date                = @s_date,
		 @i_tipo_entidad        = @i_tipo_ent,
		 @i_ente                = @i_ente,
		 @i_nombre_tipo_doc     = @i_nombre_tipo_doc,
		 @i_ruta_servidor       = @i_nombre_archivo,
		 @i_observacion         = @i_observacion
		 
    if @w_error != 0
    begin
       goto ERROR
    end
end
else
begin
	exec @w_error = cob_interface..sp_management_doc_inbox
		 @s_user                = @s_user,
		 @s_term                = @s_term,
		 @s_ofi                 = @s_ofi,
		 @s_ssn                 = @s_ssn,
		 @s_date                = @s_date,
		 @i_tramite             = @w_tramite,
		 @i_nombre_tipo_doc     = @i_nombre_tipo_doc,
		 @i_nameDocument        = @i_nombre_archivo,
		 @i_observation         = @i_observacion
		 
    if @w_error != 0
    begin
       goto ERROR
    end
end
	   
	   


return 0

ERROR:
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = @w_error
    return @w_error
go
