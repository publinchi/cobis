use cob_cartera
go

IF OBJECT_ID ('dbo.sp_qr_ns_garantia_liquida') IS NOT NULL
	DROP PROCEDURE dbo.sp_qr_ns_garantia_liquida
GO

create proc sp_qr_ns_garantia_liquida (	
	@i_operacion		char(1),
	@i_tramite 			int 	= null,
	@i_estado			char(1) = null
)
as


--Consulta
if @i_operacion = 'Q'
begin
	
	select ngl_tramite
	  from ca_ns_garantia_liquida
	 where ngl_estado = 'P' --Pendiente
	 
	 update ca_ns_garantia_liquida
	   set ngl_estado 	= 'E' --En Proceso
	 where ngl_estado 	= 'P'
     
	if @@rowcount = 0
	begin 
		return 1
	end

end

--Actualiza estado
if @i_operacion = 'U'
begin
	update ca_ns_garantia_liquida
	   set ngl_estado 	= @i_estado
	 where ngl_tramite 	= @i_tramite
 
end
return 0

go
