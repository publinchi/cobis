/************************************************************************/
/*  Archivo:              sp_valida_integrante_int.sp                   */
/*  Stored procedure:     sp_valida_integrante_int                      */
/*  Base de datos:        cob_interface                                 */
/*  Producto:             credito                                       */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   06/Sep/2021                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCORP.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCORP para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  sp de validacion para servicio rest de operaciones por integrante   */
/*  por grupo                                                           */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  06/Sep/2021   William Lopez   Emision Inicial                       */
/************************************************************************/
use cob_interface
go

if exists(select 1 from sysobjects where name = 'sp_valida_integrante_int' and type = 'P')
    drop procedure sp_valida_integrante_int
go

create procedure sp_valida_integrante_int
(
   @s_ssn                 int           = null,
   @s_sesn                int           = null,
   @s_ofi                 smallint      = null,
   @s_rol                 smallint      = null,
   @s_user                login         = null,
   @s_date                datetime      = null,
   @s_term                descripcion   = null,
   @t_debug               char(1)       = 'N',
   @t_file                varchar(10)   = null,
   @t_from                varchar(32)   = null,
   @s_srv                 varchar(30)   = null,
   @s_lsrv                varchar(30)   = null,
   @i_grupo               int           = null,
   @i_tramite             int           = null,
   @i_ente                int           = null,
   @i_monto               money         = 0,
   @i_participa_ciclo     char(1)       = null,
   @i_tg_monto_aprobado   money         = null,
   @i_ahorro              money         = null,
   @i_monto_max           money         = null,
   @i_bc_ln               char(10)      = null,
   @i_tr_cod_actividad    catalogo      = null,
   @i_sector              catalogo      = null, 
   @i_monto_recomendado   money         = null
)
as 
declare
   @w_sp_name      varchar(65),
   @w_return       int,
   @w_error        int,
   @w_sector       catalogo,
   @w_destino      catalogo,
   @w_en_ente      int,
   @w_cg_ente      int,
   @w_gr_grupo     int

select @w_sp_name      = 'sp_valida_integrante_int',
       @w_error        = 0,
       @w_return       = 0,
       @w_sector       = null,
       @w_destino      = null,
       @w_en_ente      = null,
       @w_cg_ente      = null,
       @w_gr_grupo     = null

--validacion de montos
if (@i_monto < 0 or @i_monto is null) or (@i_tg_monto_aprobado < 0 or @i_tg_monto_aprobado is null) or (@i_monto_recomendado < 0 or @i_monto_recomendado is null)
begin 
   select @w_return = 2110133
   goto SALIR
end

--validacion del sector
select @w_sector = c.valor
from   cobis..cl_tabla t,
       cobis..cl_catalogo c
where  t.tabla  = 'cc_sector'
and    t.codigo = c.tabla
and    c.codigo = @i_sector
if @@rowcount = 0
begin 
   select @w_return = 2110126
   goto SALIR
end

--validacion del destino
select @w_destino = se_codigo
from   cobis..cl_subactividad_ec
where  se_codigo  = @i_tr_cod_actividad
if @@rowcount = 0
begin 
   select @w_return = 2110127
   goto SALIR
end

--validacion que grupo exista
select @w_gr_grupo = gr_grupo
from   cobis..cl_grupo
where  gr_grupo = @i_grupo
if @@rowcount = 0
begin 
   select @w_return = 2110130
   goto SALIR
end

--validacion que integrante existe en la cl_ente
select @w_en_ente = en_ente
from   cobis..cl_ente
where  en_ente = @i_ente
if @@rowcount = 0
begin 
   select @w_return = 2110129
   goto SALIR
end

--validacion que integrante existe en la cl_cliente_grupo
select @w_cg_ente = cg_ente
from   cobis..cl_cliente_grupo
where  cg_ente  = @i_ente
and    cg_grupo = @i_grupo
if @@rowcount = 0
begin 
   select @w_return = 2110128
   goto SALIR
end

--validacion que tramite exista en tramite grupal
select @w_cg_ente = cg_ente
from   cobis..cl_cliente_grupo,
       cob_credito..cr_tramite_grupal
where  cg_ente    = tg_cliente
and    cg_grupo   = tg_grupo
and    tg_tramite = @i_tramite
and    cg_estado  = 'V'
if @@rowcount = 0
begin 
   select @w_return = 2110131
   goto SALIR
end

--validacion que cliente y grupo esten asociados a tramite
select @w_cg_ente = cg_ente
from   cobis..cl_cliente_grupo,
       cob_credito..cr_tramite_grupal
where  cg_ente    = tg_cliente
and    cg_grupo   = tg_grupo
and    tg_tramite = @i_tramite
and    tg_grupo   = @i_grupo
and    tg_cliente = @i_ente
and    cg_estado  = 'V'
if @@rowcount = 0
begin 
   select @w_return = 2110132
   goto SALIR
end

SALIR:
return @w_return

ERROR:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return
   return @w_return
go
