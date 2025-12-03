use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_cuentas_ajuste')
   drop proc sp_cuentas_ajuste
go


create proc sp_cuentas_ajuste
@s_user     login,
@i_accion   char,
@i_cuenta   cuenta
as
begin
   if @i_accion = 'L' -- LISTAR
   begin
      set rowcount 40
      select ca_cuenta   Cuenta,
             ca_usuario  Usuario
      from   ca_cuentas_ajuste
      where  ca_cuenta > @i_cuenta
      and    ca_estado = 'V'
      order by ca_cuenta
      set rowcount 0
      return 0
   end
   
   if @i_accion = 'I' -- INGRESAR
   begin
      begin tran
      
      insert into ca_cuentas_ajuste
            (ca_cuenta, ca_usuario, ca_fecha)
      values(@i_cuenta, @s_user,        getdate())
      
      if @@error != 0
      begin
         print 'No se pudo completar la transaccion'
         rollback
      end
      else
         commit
      
      return 0
   end
   
   if @i_accion = 'D' -- BORRAR
   begin
      begin tran
      
      update ca_cuentas_ajuste
      set    ca_estado  = 'D',
             ca_usuario = @s_user
      where  ca_cuenta = @i_cuenta
      and    ca_estado = 'V'
      
      if @@error != 0
      begin
         print 'No se pudo completar la transaccion'
         rollback
      end
      else
         commit
      return 0
   end
   return 0
end
go

/*
insert into ca_cuentas_ajuste
values ('10201010', 'V', getdate(), 'fq')
  ca_cuenta   cuenta,
  ca_estado   char,
  ca_fecha    datetime,
  ca_usuario  login
)


*/