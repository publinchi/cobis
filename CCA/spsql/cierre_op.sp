use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cierre_op')
   drop proc sp_cierre_op
go

---AGO-25-2011

create proc sp_cierre_op 
@i_banco     cuenta,
@i_fecha     datetime,
@i_en_linea  char(1) =  'S'

as declare 
@w_fecha_proceso	datetime,
@w_return           int


select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7
select @w_return = 0


select op_fecha_ult_proceso from ca_operacion where op_banco = @i_banco

exec sp_fecha_valor 
@s_user              = 'sa',        
@i_fecha_valor       = @i_fecha,
@s_term              = 'Terminal', 
@s_date              = @w_fecha_proceso,
@i_banco             = @i_banco,
@i_operacion         = 'F',
@i_en_linea          = 'S',
@i_control_fecha     = 'N',
@i_debug             = @i_en_linea

select op_fecha_ult_proceso from ca_operacion where op_banco = @i_banco

return 0   
go
   

