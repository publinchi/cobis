use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_operacion_control')
  drop proc sp_operacion_control
go

create proc sp_operacion_control
@i_operacion     int,
@i_saldo_cap     money = null,
@i_dividendo_vig smallint = null
as
declare
   @w_max_div     smallint,
   @w_min_ven     smallint,
   @w_fecha_ven   datetime,
   @w_div_vigente smallint

begin
   return 0
end
go
