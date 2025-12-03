/************************************************************/
/*   ARCHIVO:         sp_busqueda_cli_generico.sp           */
/*   NOMBRE LOGICO:   sp_busqueda_cli_generico              */
/*   PRODUCTO:        COBIS COMMONS CORE                    */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de COBIS.                                    */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de COBIS.                                  */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  internacionales de    */
/*   propiedad intelectual.  Su uso  no  autorizado dara    */
/*   derecho a COBIS  para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*   Descripcion de un parametro COBIS.                     */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA        AUTOR     RAZON                           */
/*   29/01/2019   DFL       Emision Inicial                 */
/*   29/07/20     MBA       Estandarizacion sp y seguridades*/
/************************************************************/

use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO


if exists (select * 
             from sysobjects
            where type = 'P'
              and name = 'sp_busqueda_cli_generico')
  drop proc sp_busqueda_cli_generico
go

create procedure sp_busqueda_cli_generico
(
  @s_ssn                int			= null,
  @s_user               varchar(30)	= null,
  @s_sesn               int			= null,
  @s_term               varchar(30)	= null,
  @s_date               datetime	= null,
  @s_srv                varchar(30)	= null,
  @s_lsrv               varchar(30)	= null,
  @s_ofi                smallint	= null,
  @t_trn                int			= null,
  @t_debug              char(1)     = 'N',
  @t_file               varchar(14) = null,
  @t_from               varchar(30) = null,
  @t_show_version       bit         = 0,
  @s_culture            varchar(10) = null,
  @s_rol                smallint    = null,
  @s_org_err            char(1)     = null,
  @s_error              int         = null,
  @s_sev                tinyint     = null,
  @s_msg                descripcion = null,
  @s_org                char(1)     = null,
  @t_rty                char(1)     = null,
  @i_operacion          char(1)		= 'Q',
  @i_tipo          		char(2)		= null, -- 'PN' --> Persona Natural, 'PJ' --> Persona Juridica, 'GE' --> Grupo Economico
  @i_filtro				char(1)		= null, -- 'I' --> Identificacion, 'C' --> Codigo, 'N' --> Nombre
  @i_modo	            int     	= null,
  @i_identificacion		varchar(30)	= null,
  @i_codigo        		int			= null,
  @i_nombre        		varchar(80)	= null,
  @i_cliente			char(1)		= null
)
As declare
  @w_sp_name 		varchar(64),
  @w_sp_msg         varchar(132),
  @w_query			varchar(8000),
  @w_rowcount		int

/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_busqueda_cli_generico'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/ 

-- VALIDACION DE TRANSACCIONES
if (@t_trn <> 172901)
begin
   exec sp_cerror
    @t_debug  = @t_debug,
    @t_file   = @t_file,
    @t_from   = @w_sp_name,
    @i_num    = 1720075                  
    --NO CORRESPONDE CODIGO DE TRANSACCION
   return 1720075
end

if @i_operacion = 'Q'
begin
	
	if  @i_filtro = 'C'
	begin
		select @w_rowcount = 1  
	end
	else
	begin
		select @w_rowcount = 10
	end
	
	select @w_query = convert(varchar(8000), bc_busqueda)
	from cobis..cl_busqueda_cli_conf
	where bc_operacion = @i_operacion
	and bc_tipo = @i_tipo
	and bc_filtro = @i_filtro
	and bc_modo = @i_modo
	
	if @i_identificacion is not null
	begin
		set @w_query = replace(@w_query, '@i_identificacion', '''' + convert(varchar(30), @i_identificacion) + '''')
	end
	
	if @i_nombre is not null
	begin
		set @w_query = replace(@w_query, '@i_nombre', '''' + convert(varchar(80), @i_nombre) + '''')
	end
	
	if @i_codigo is not null
	begin
		set @w_query = replace(@w_query, '@i_codigo', convert(varchar(20), @i_codigo))
	end
	
	if @i_cliente is not null
	begin
		set @w_query = replace(@w_query, '@i_cliente', '''' + convert(varchar(10), @i_cliente) + '''')
	end
	
	execute(@w_query)
	
	set rowcount 0
end

set rowcount 0
return 0

go
