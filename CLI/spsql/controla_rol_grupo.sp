/*************************************************************************/
/*   ARCHIVO:            controla_rol_grupo.sp                           */
/*   NOMBRE LOGICO:      sp_controla_rol_grupo                           */
/*   Base de datos:      cobis                                           */
/*   PRODUCTO:           CLI                                             */
/*   Fecha de escritura: Jul 2021                                        */
/*************************************************************************/
/*                           IMPORTANTE                                  */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/*************************************************************************/
/*                           PROPOSITO                                   */
/*  Valida la existenda de los integrantes de un grupo solidario         */
/*  teniendo en cuenta los roles que deben existir en un grupo.          */
/*************************************************************************/
/*                        MODIFICADO POR                                 */
/*  19/07/2021             ACA                primera versión            */
/*************************************************************************/

use cobis
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go


if exists (select 1 from sysobjects where name = 'sp_controla_rol_grupo')
   drop proc sp_controla_rol_grupo
go
create procedure sp_controla_rol_grupo(
       @t_show_version          bit                 = 0,
       @t_trn                   int                 = null,
	   @t_debug                 char(1)             = 'N',
	   @t_file                  varchar(10)         = null,
       @s_date                  datetime            = null,
       @s_user                  login               = null,
       @s_ssn                   int                 = null,
       @s_sesn                  int                 = null,
       @s_term                  varchar(32)         = null,
       @s_srv                   varchar(30)         = null,
       @s_lsrv                  varchar(30)         = null,
       @s_rol                   smallint            = null,
       @s_ofi                   smallint            = null,
       @s_culture               varchar(10)         = null,
       @s_org                   char(1)             = null,
       @i_grupo                 int                 = null, --Código del grupo
	    @o_roles_obligatorios    smallint            = 0 out --salida de los roles obligatorios que faltan
)

as

declare
@w_error     int,
@w_sp_name   descripcion,
@w_tipo_grupo char(1) --Solidario

/* INICIAR VARIABLES DE TRABAJO  */
select 
@w_sp_name           = 'sp_controla_rol_grupo',
@w_tipo_grupo = 'S'

if(@w_tipo_grupo = 'S')
begin
   if exists (select 1 from cl_grupo where gr_grupo = @i_grupo and gr_tipo = @w_tipo_grupo)
   begin
      select c.codigo, estado
      into #roles_grupo
      from cobis..cl_catalogo c, 
      cobis..cl_tabla t 
      where c.tabla = t.codigo 
      and t.tabla = 'cl_rol_controlar'
      and c.estado = 'V'
	  
	  delete #roles_grupo from cobis..cl_cliente_grupo
      where cg_grupo = @i_grupo
      and cg_estado = 'V'
      and codigo = cg_rol

      select @o_roles_obligatorios = isnull(count(1),0) from #roles_grupo
   end
   else
   begin
      exec sp_cerror
		   @t_debug    = @t_debug,
		   @t_file     = @t_file,
		   @t_from     = @w_sp_name,
		   @i_num      = 1720533
		   /* 'Grupo no valido'*/
	  return 1
   end
end
else
begin
   exec sp_cerror
      @t_debug    = @t_debug,
      @t_file     = @t_file,
      @t_from     = @w_sp_name,
      @i_num      = 1720532
      /* 'Grupo no valido'*/
   return 1
end

return 0

go
