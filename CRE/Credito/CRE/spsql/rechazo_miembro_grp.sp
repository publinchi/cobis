/**********************************************************/
/*  ARCHIVO:         rechazo_miembro_grp.sp               */
/*  NOMBRE LOGICO:   sp_rechazo_miembro_grp               */
/*  PRODUCTO:        Crédito                              */
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
/*  Ingresa la razón para rechazar a un integrante.       */
/**********************************************************/
/*                   MODIFICACIONES                       */
/*     FECHA         AUTOR              RAZON             */
/*  29-11-2021    Patricio Mora     Emisión inicial       */
/**********************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_rechazo_miembro_grp')
   drop procedure sp_rechazo_miembro_grp
go

create procedure sp_rechazo_miembro_grp
(
    @s_ssn               int          = null,
    @s_user              varchar(30)  = null,
    @s_sesn              int          = null,
    @s_term              varchar(30)  = null,
    @s_date              datetime     = null,
    @s_srv               varchar(30)  = null,
    @s_lsrv              varchar(30)  = null,
    @s_ofi               smallint     = null,
    @t_trn               int          = null,
    @t_debug             char(1)      = 'N',
    @t_file              varchar(14)  = null,
    @t_from              varchar(30)  = null,
    @s_rol               smallint     = null,
    @s_org_err           char(1)      = null,
    @s_error             int          = null,
    @s_sev               tinyint      = null,
    @s_msg               descripcion  = null,
    @s_org               char(1)      = null,
    @t_rty               char(1)      = null,  
    @i_cliente           int          = null,                                                                                                                                                                                   
    @i_grupo             int          = null,
    @i_tramite           int          = null,
    @i_canal             tinyint      = 0,
    @i_operacion         char,
    @i_id_rechazo        catalogo,
    @i_descripcion       descripcion
)
as
declare
    @w_error             int,
    @w_sp_name           varchar(32)

select @w_sp_name = 'sp_rechazo_miembro_grp'

if @i_operacion = 'U'
 begin
    update cob_credito..cr_tramite_grupal
       set tg_descripcion_rechazo = @i_descripcion,
           tg_id_rechazo          = @i_id_rechazo
     where tg_tramite             = @i_tramite  
       and tg_grupo               = @i_grupo
       and tg_cliente             = @i_cliente
 end

return 0

ERROR:
   --Devolver mensaje de Error
   if @i_canal in (0,1) --Frontend o batch
     begin
          exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = @w_error
        return @w_error
     end
   else
      return @w_error

go
