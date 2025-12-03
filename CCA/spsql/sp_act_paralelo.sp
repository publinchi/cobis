use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_act_paralelo')
   drop proc sp_act_paralelo
go
 


create proc sp_act_paralelo 
 @i_programa    varchar(10),
 @i_proceso     int,
 @i_modo        int
as


if @i_modo = 0
begin
   begin tran
   update ca_paralelo_tmp
   set    estado     = 'P',
          hora       = getdate(),          
          reintentos = isnull(reintentos, 0) + 1
   where  programa = @i_programa
   and    proceso =  @i_proceso
   and    estado  = 'C'
   commit tran
end

if @i_modo = 1  --contar_estados
begin
   begin tran

   update ca_paralelo_tmp
   set    estado = 'P'
   where  programa = @i_programa
   and    estado   = 'T'
   and    spid is null
   commit tran
end

if @i_modo = 2 --marcar errado
begin
   begin tran
   update ca_paralelo_tmp
   set    estado = 'E'
   where  programa = @i_programa
   and    proceso  = @i_proceso
   and    estado   = 'P'
   commit tran
end

if @i_modo = 3 --reejecutar
begin
   begin tran
   update ca_paralelo_tmp
   set    estado = 'C'
   where  programa = @i_programa
   and    proceso =  @i_proceso
   and    estado  = 'P'
   commit tran
end



return 0

 
go

 
