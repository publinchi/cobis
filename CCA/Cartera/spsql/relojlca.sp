use cob_cartera
go

--create table reloj (programa char(40), proceso smallint, evento char(10), tiempo datetime)

if exists(select 1 from sysobjects where name = 'sp_relojlca')
   drop proc sp_relojlca
go
 
create proc sp_relojlca
 @i_programa   char(40) = 'X',
 @i_proceso    smallint  = 0,
 @i_evento     char(10) = 'X',
 @i_opcion     char(1)  = 'N'
as
if @i_opcion <> 'S'
begin
   if @i_opcion = 'T'
      truncate table reloj
   else
      if @i_opcion = 'B' and @i_programa <> 'X'
         delete reloj where programa = @i_programa and (proceso = @i_proceso or @i_proceso = 0)

   insert into reloj values (@i_programa, @i_proceso, @i_evento, getdate())

end
else
begin
   select B.programa, B.proceso,B.evento, 
          milisegundos = (select datediff(ms, A.tiempo, B.tiempo)
                            from reloj A
                           where B.programa = A.programa
                             and A.evento = '1'
                             and A.proceso = 1),
                tiempo = convert(varchar(8),B.tiempo,8)
     from reloj B
    where (B.programa = @i_programa or @i_programa = 'X')
      and (B.proceso  = @i_proceso  or @i_proceso = 0)
      and (B.evento   = @i_evento   or @i_evento = 'X')       
end

return 0

go