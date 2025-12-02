use cob_credito
go

if exists(select 1 from sysobjects where id=object_id('dbo.sp_validar_linea') and type='P')
	drop procedure sp_validar_linea
go
create proc sp_validar_linea (
        @s_sesn            	int,
        @s_user            	login,
        @s_date            	datetime,
        @s_term            	varchar(30),
        @s_ofi             	int,	
        @i_toperacion      	varchar(25) = null,
		@i_moneda			varchar(10),
		@i_monto			money,
		@i_plazo			int,
		@o_valida_linea 	char(1) out
)
as 
	declare @w_sp_name varchar(32),
			@w_plazo_maximo int

select @w_sp_name = 'sp_validar_linea'

	if @i_toperacion is not null
	begin
		if not exists (SELECT 1 FROM cr_datos_linea
						where dl_toperacion = @i_toperacion
						and dl_moneda = @i_moneda
						and @i_monto between dl_monto_minimo and dl_monto_maximo)
		begin
			exec cobis..sp_cerror
			@t_from  = @w_sp_name,
			@i_num   = 2110102
			
			select @o_valida_linea = 'N'
			return 1 
		end
		
		SELECT @w_plazo_maximo = pl_plazo_maximo FROM cr_parametros_linea
		where pl_toperacion = @i_toperacion
		
		if  @i_plazo > @w_plazo_maximo
		begin
			exec cobis..sp_cerror
			@t_from  = @w_sp_name,
			@i_num   = 2110103
			
			select @o_valida_linea = 'N'
			return 1
		end
		
		select @o_valida_linea = 'S'		
		
	end
	else
	begin
		select @o_valida_linea = 'N'
	end
	
	
	

return 0

go
