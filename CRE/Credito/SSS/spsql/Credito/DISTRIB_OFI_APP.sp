/************************************************************************/
/*  Archivo:                DISTRIB_OFI_APP.sp                          */
/*  Stored procedure:       SP_DISTRIBUIDOR_OFICIAL_APP                 */
/*  Base de Datos:          cob_workflow                                */
/*  Producto:               Credito                                     */
/*  Fecha de Documentacion: 10/Sept/2019                                */
/************************************************************************/
/*          IMPORTANTE                                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA",representantes exclusivos para el Ecuador de la            */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de MACOSA o su representante                  */
/************************************************************************/
/*          PROPOSITO                                                   */
/*   Retorna el usuario destinatario que creo el crédito el crédito     */
/*   desde la APP                                                       */
/*                                                                      */
/************************************************************************/
/*          MODIFICACIONES                                              */
/*  FECHA       AUTOR           RAZON                                   */
/*  2019/09/18  José Escobar    Emisión Inicial                         */
/* **********************************************************************/

use cob_workflow
go

if exists (select 1 from sysobjects where name = 'SP_DISTRIBUIDOR_OFICIAL_APP')
   drop proc SP_DISTRIBUIDOR_OFICIAL_APP
go

create proc SP_DISTRIBUIDOR_OFICIAL_APP (
    @s_ssn                  int            = null,
    @s_user                 varchar(30)    = null,
    @s_sesn                 int            = null,
    @s_term                 varchar(30)    = null,
    @s_date                 datetime       = null,
    @s_srv                  varchar(30)    = null,
    @s_lsrv                 varchar(30)    = null,
    @s_rol                  smallint       = null,
    @s_ofi                  smallint       = null,
    @s_org_err              char(1)        = null,
    @s_error                int            = null,
    @s_sev                  tinyint        = null,
    @s_msg                  descripcion    = null,
    @s_org                  char(1)        = null,
    @t_rty                  char(1)        = null,
    @t_trn                  int            = null,
    @t_debug                char(1)        = null,
    @t_file                 varchar(14)    = null,
    @t_from                 varchar(30)    = null,
    @i_id_inst_proc         int,
    @i_id_inst_act          int,
    @i_id_proceso           smallint,
    @i_version_proc         smallint,
    @i_id_actividad         int,
    @i_id_empresa           smallint,
    @i_oficina_asig         smallint,
    @i_id_rol_dest          int,
    @i_ij_id_item_jerarquia int,
    @o_id_destinatario      int out,
    @o_ij_id_item_jerarquia int out 
)
as

declare @w_id_destinatario    int,
        @w_sp_name            varchar(32)

set @w_sp_name = 'SP_DISTRIBUIDOR_OFICIAL_APP'

select @w_id_destinatario = us_id_usuario
from   cob_workflow..wf_inst_proceso
inner join cob_workflow..wf_usuario on us_login = io_usuario_crea and us_estado_usuario = 'ACT'
where  io_id_inst_proc    = @i_id_inst_proc
and    io_canal           = 20 -- CREADO DE LA APP

if @@rowcount = 0
begin
    --No se puede determinar siguiente estacion de trabajo
    exec cobis..sp_cerror @t_debug = @t_debug, @t_file  = @t_file,  @t_from  = @w_sp_name, @i_num   = 2101033
    return 1
end

if @w_id_destinatario is not null
begin
   set @o_id_destinatario = @w_id_destinatario
   return 0
end
else
begin
    --No se puede determinar siguiente estacion de trabajo
    exec cobis..sp_cerror @t_debug = @t_debug, @t_file  = @t_file,  @t_from  = @w_sp_name, @i_num   = 2101033
    return 1
end

return 0
go
