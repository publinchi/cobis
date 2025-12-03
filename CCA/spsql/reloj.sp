use cob_cartera
go

if object_id ('dbo.sp_reloj') is not null
	drop procedure sp_reloj
go

create proc sp_reloj  
@i_hilo       smallint, 
@i_banco      cuenta, 
@i_posicion   varchar(50) 
as 
 
insert into ca_reloj values (@i_hilo, @i_banco, @i_posicion, getdate()) 
 
return 0 

go
