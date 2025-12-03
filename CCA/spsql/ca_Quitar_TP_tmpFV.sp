use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_quitar_TP_tmp_FValor')
   drop proc sp_quitar_TP_tmp_FValor
go

create proc sp_quitar_TP_tmp_FValor
as
declare 
   @w_fecha         datetime,
   @w_operacion     int,
   @w_banco         cuenta,
   @w_fecha_hoy    datetime,
   @w_spread        float,
   @w_signo         char(1),
   @w_error         int,
   @w_tr_fecha_ref       datetime,
   @w_secuencial         int

--tasa original = 41.995

-- SELECCIONA UNIVERSO DE OPERACIONES

select @w_fecha_hoy = fc_fecha_cierre from cobis..ba_fecha_cierre where fc_producto = 7

select 'Operaciones a ProcesarFEchaVAlor :'  select count(1)
from ca_quitar_TP_113703

   
select @w_operacion = 0

while 1 = 1 
begin
        set rowcount 1
        
		select  @w_operacion = operacion_tp,
		        @w_banco     = op_banco
		from ca_quitar_TP_113703,ca_operacion with (nolock)
		where  op_operacion = operacion_tp
		and    op_fecha_ult_proceso < @w_fecha_hoy
		and    op_estado <> 3
		and    operacion_tp > @w_operacion
		order by operacion_tp
		
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0

	     	exec @w_error = sp_fecha_valor 
			@s_user              = 'script',        
			@i_fecha_valor       = @w_fecha_hoy,
			@s_term              = 'Terminal', 
			@s_date              = @w_fecha_hoy,
			@i_banco             = @w_banco,
			@i_operacion         = 'F',
			@i_en_linea          = 'N',
			@i_control_fecha     = 'N',
			@i_debug             = 'N'
			if @w_error <> 0
			begin
			  PRINT 'Error No hizo la fecha adelante Revisar   ' + CAST (@w_banco as varchar) + ' @w_tr_fecha_ref  : ' + cast (@w_tr_fecha_ref as varchar)
			end
			ELSE
			begin
    		  PRINT 'Proceso ExitosamenteADelanTE ' + CAST (@w_banco as varchar)
	        end


end ----WHILE
set rowcount 0
set nocount off

return 0

go