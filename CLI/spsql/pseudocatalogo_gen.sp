/*********************************************************************************/
/*  Archivo:                pseudocatalogo_gen.sp            	                 */
/*  Stored procedure:   	sp_pseudocatalogo_gen               				 */
/*  Base de datos:       	cobis                   					         */
/*  Producto:               Clientes              					             */
/*  Disenado por: 			Diego Flores		                                 */
/*  Fecha de escritura: 	04-07-2019	               		 	                 */
/*********************************************************************************/
/*            		                IMPORTANTE 					                 */
/*  Este programa es parte de los paquetes bancarios propiedad de "COBISCORP".   */
/*  Su uso no autorizado queda expresamente prohibido asi cualquier alteracion o */ 
/*  agregado hecho por alguno de sus usuarios sin el debido consentimiento por   */
/*  escrito de la Presidencia Ejecutiva de COBISCORP o su representante.    	 */
/*              		                 PROPOSITO	              				 */
/*  Este programa envía una string como resultado.	 		                     */
/*********************************************************************************/
/*   		              MODIFICACIONES					                     */
/*  FECHA		AUTOR       	RAZON	               			                 */
/*  04-07-2019     	D.Flores   	Emision Inicial.       			                 */
/*********************************************************************************/


use cobis
GO
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select * from sysobjects where name = 'sp_pseudocatalogo_gen')
   drop proc sp_pseudocatalogo_gen
go

create proc sp_pseudocatalogo_gen (
   @s_ssn                int           = NULL,
   @s_user               login         = NULL,
   @s_sesn               int           = NULL,
   @s_term               varchar(32)   = NULL,
   @s_date               datetime      = NULL,
   @s_srv                varchar(30)   = NULL,
   @s_lsrv               varchar(30)   = NULL, 
   @s_rol                smallint      = NULL,
   @s_ofi                smallint      = NULL,
   @s_org_err            char(1)       = NULL,
   @s_error              int           = NULL,
   @s_sev                tinyint       = NULL,
   @s_msg                descripcion   = NULL,
   @s_org                char(1)       = NULL,
   @s_culture            varchar(10)   = 'NEUTRAL',     
   @t_debug              char(1)       = 'N',
   @t_file               varchar(14)   = null,
   @t_from               varchar(32)   = null,
   @t_show_version       bit           = 0,     -- mostrar la version del programa
   @t_trn                int           = NULL,
   @i_operacion          varchar(2),
   -- DATOS PSEUDOCATALOGO GENERICO
   @i_bdatos			varchar(30)		= null, -- Nombre base de datos
   @i_procedimiento     varchar(50)		= null, -- Nombre del procedimiento almacenado
   @i_cliente			int				= null, -- Codigo del cliente
   @i_relacion			int				= null -- Codigo de la relacion
)
as
declare @w_today		datetime,
		@w_sp_name		varchar(32),
		@w_sp_exec		varchar(100),
		@w_result		tinyint,
		@w_sp_msg       varchar(132)
   
select @w_sp_name = 'sp_pseudocatalogo_gen',
       @w_sp_msg       = ''

/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end

--Validaciones Iniciales
if @t_trn <> 172135
begin
	exec cobis..sp_cerror
	   --NO CORRESPONDE CODIGO DE TRANSACCION
	   @t_debug = @t_debug,
	   @t_file  = @t_file,
	   @t_from  = @w_sp_name,
	   @s_culture = @s_culture, 	   
	   @i_num   = 1720070
	return 1
end

if @i_bdatos is null or @i_procedimiento is null
begin
	exec cobis..sp_cerror
	   @t_debug   = @t_debug,
	   @t_file    = @t_file,
	   @t_from    = @w_sp_name,
	   @s_culture = @s_culture, 	   
	   @i_num     = 1720408 -- Error en parametros de ingreso
	return 1
end

set @w_result = null
exec('select @w_result = 1 from ' + @i_bdatos + '..sysobjects where name = ''' + @i_procedimiento + ''' and type = ''P''')
if @w_result is null
begin
	exec cobis..sp_cerror
	   @t_debug   = @t_debug,
	   @t_file    = @t_file,
	   @t_from    = @w_sp_name,
	   @s_culture = @s_culture, 	   
	   @i_num     = 1720409 -- No existe el sp solicitado
	return 1
end
else
begin
	set @w_result = null
end

if @i_operacion = 'S'
begin
	if @t_trn = 172135
	begin
		set @w_sp_exec = @i_bdatos + '..' + @i_procedimiento
		if @i_cliente is not null 
		begin
			set @w_sp_exec = @w_sp_exec + ' @i_cliente = ' + convert(varchar,@i_cliente)
		end
		if @i_relacion is not null and @i_cliente is not null
		begin
			set @w_sp_exec = @w_sp_exec + ', @i_relacion = ' + convert(varchar,@i_relacion)
		end
		exec(@w_sp_exec)
		return 0
	end
end

go