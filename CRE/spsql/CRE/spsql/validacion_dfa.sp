/**************************************************************************/
/*  Archivo:                validacion_dfa.sp                             */
/*  Stored procedure:       sp_validacion_dfa                             */
/*  Producto:               Credito                                       */
/*  Disenado por:           Carlos Obando                                 */
/*  Fecha de escritura:     11-11-2021                                    */
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
/*  11-11-2021  COB             Emision inicial                           */
/**************************************************************************/
use cob_credito
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select 1 from sysobjects where name = 'sp_validacion_dfa')
   drop proc sp_validacion_dfa
go

create proc sp_validacion_dfa (
   @s_ssn                     int,
   @s_sesn                    int           = null,
   @s_user                    login         = null,
   @s_term                    varchar(32)   = null,
   @s_date                    datetime,
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
   @t_rty                     char(1)       = null,
   @i_operacion               char(1)       = null,
   @i_instancia_proceso       int           = null,
   @o_nro_proceso             int           = null output,
   @o_msg                     varchar(256)  = null output
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_oficial               int,
        @w_trn_dir               int,
        @w_error                 int,
        @w_existente             bit,
        @w_init_msg_error        varchar(256),
        @w_valor_campo           varchar(30),
        @w_prospecto             char(1)       = 'P',
        @w_param                 int, 
        @w_diff                  int, 
        @w_date                  datetime,
        @w_existe                char(1)       = 'S',
        @w_bloqueo               char(1)       = 'S',
        @w_query                 varchar(1000)

select
@w_sp_name          = 'cob_credito..sp_validacion_dfa',
@w_error            = 1720548

if @i_operacion = 'Q'  --Devuelve la instancia del numero proceso
begin
   if isnull(@i_instancia_proceso, '') = ''
   begin
      select @w_valor_campo  = '@i_instancia_proceso'
      goto VALIDAR_ERROR
   end

   select @o_nro_proceso = io_campo_3 from cob_workflow..wf_inst_proceso
   where io_id_inst_proc = @i_instancia_proceso

   select @o_msg = 'Regresado por analisis, DPI borroso'

   if @o_nro_proceso = 0 or isnull(@o_nro_proceso,'') = ''
   begin
      select @w_error = 1720599
      goto ERROR_FIN
   end
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

