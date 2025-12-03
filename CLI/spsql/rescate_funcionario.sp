/************************************************************************/
/*    Archivo:                  rescate_funcionario.sp                  */
/*    Stored procedure:         sp_rescate_funcionario                  */
/*    Base de datos:            cobis                                   */
/*    Producto:                 CLIENTES                                */
/*    Disenado por:             RIGG                                    */
/*    Fecha de escritura:       18/Sep/2019                             */
/************************************************************************/
/*                             IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "COBISCORP",  representantes  exclusivos  para  el Ecuador de la  */
/*    "NCR CORPORATION".                                                */
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */
/*    Presidencia Ejecutiva de COBISCORP o su representante.            */
/************************************************************************/
/*                              PROPOSITO                               */
/* Este programa administra el rescate que pueden hacer los funcionarios*/
/*                                                                      */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*    FECHA               AUTOR        RAZON                            */
/*    18/Sep/2019         RIGG         Emision Inicial	                */
/*    11/06/20            MBA          Estandarizacion sp y seguridades */
/************************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sys.objects where name = 'sp_rescate_funcionario')
   drop proc sp_rescate_funcionario
go 
create proc sp_rescate_funcionario
	@s_user			login = NULL,
	@s_term			char(20) = NULL,
	@s_date			datetime = NULL,
	@s_ofi			smallint = NULL,
	@t_debug                char(1) = 'N',
    @t_file                 varchar(10) = NULL,
	@t_trn              int,
	@t_show_version     bit           = 0,     
	@i_operacion		char(1),
    @i_oficina          int= NULL,
	@i_funcionario      int= NULL,
	@i_nivel            char(1)= NULL
as
declare	@w_sp_name		varchar(32),
    @w_sp_msg       varchar(132),
	@w_return		int,
	@w_error		int,
	@w_msg			varchar(1000),
	@w_renovacion   int,
	@w_inauguracion int


/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_rescate_funcionario'
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

if (@t_trn is null or @t_trn <> 172010)
begin
		  
	exec cobis..sp_cerror
		@t_debug = @t_debug,
		@t_file  = @t_file,
		@t_from  = @w_sp_name,
		@i_num   = 1720075
	return 1720075
end
	 
if (@i_operacion = 'S')
begin
    select distinct  oc_oficial 'No. Oficial',
		    fu_nombre 'Nombre Oficial',
		    re_nivel 'Nivel',
			of_oficina 'No. Oficina',
		    of_nombre 'Nombre Oficina' 
	from cobis..cl_rescate_funcionario,cobis..cl_funcionario,cobis..cl_oficina,cc_oficial
	where re_oficina = of_oficina
	and   of_oficina = fu_oficina
	and oc_funcionario = fu_funcionario
	and re_funcionario = oc_oficial
end 

if (@i_operacion = 'I')
begin

	if (@i_oficina is null or @i_funcionario is null or @i_nivel is null)
		begin
					exec cobis..sp_cerror
					@t_debug  = @t_debug,
					@t_file   = @t_file,
					@t_from   = @w_sp_name,				
					@i_num    = 1720082 
					return 1720082
		end 
		
	if exists(select 1 from cobis..cl_rescate_funcionario where re_funcionario = @i_funcionario)
		begin
			exec cobis..sp_cerror
			@t_debug  = @t_debug,
			@t_file   = @t_file,
			@t_from   = @w_sp_name,				
			@i_num    = 1720225
			return 1720225
		
		end	

	insert into cobis..cl_rescate_funcionario (re_oficina,re_funcionario,re_nivel)
	values (@i_oficina,@i_funcionario,@i_nivel)
	if (@@error <> 0)
	    begin
	        exec cobis..sp_cerror
	        @t_debug   = @t_debug,
	        @t_file    = @t_file,
	        @t_from    = @w_sp_name,
	        @i_num     = 1720083
	        return 1720083
	     end
		 
		 
end 

if (@i_operacion = 'U')
begin
	if (@i_oficina is null or @i_funcionario is null or @i_nivel is null)
		begin
					exec cobis..sp_cerror
					@t_debug  = @t_debug,
					@t_file   = @t_file,
					@t_from   = @w_sp_name,				
					@i_num    = 1720082 
					return 1720082
		end 

		update cobis..cl_rescate_funcionario
		set re_nivel = @i_nivel 
		where re_funcionario = @i_funcionario
		and re_oficina = @i_oficina
		if (@@error <> 0)
			begin
				exec cobis..sp_cerror
				@t_debug   = @t_debug,
				@t_file    = @t_file,
				@t_from    = @w_sp_name,
				@i_num     = 1720083
				return 1720083
			 end
end 

if (@i_operacion = 'D')
begin
	if (@i_funcionario is null)
		begin
					exec cobis..sp_cerror
					@t_debug  = @t_debug,
					@t_file   = @t_file,
					@t_from   = @w_sp_name,				
					@i_num    = 220081 
					return 220081
		end 

		delete from cobis..cl_rescate_funcionario where re_funcionario = @i_funcionario
		if (@@error <> 0)
			begin
				exec cobis..sp_cerror
				@t_debug  = @t_debug,
				@t_file   = @t_file,
				@t_from   = @w_sp_name,
				@i_num    = 1720085
				--ERROR EN ELIMINACION
				return 1720085
			end
end