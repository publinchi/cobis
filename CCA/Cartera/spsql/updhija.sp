use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_hija')
    drop proc sp_actualiza_hija
go

create proc sp_actualiza_hija 
(
    @i_nro_grupal VARCHAR(25),
    @i_nro_hija VARCHAR(25) = NULL
)
as
declare
    @w_sp_name     descripcion
	
	SELECT @w_sp_name = 'sp_actualiza_hija'

return 0
go
