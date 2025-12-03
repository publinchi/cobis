use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_TPPuntualFin_tmp')
   drop proc sp_TPPuntualFin_tmp
go

create proc sp_TPPuntualFin_tmp
as
declare 
   @w_operacion     int,
   @w_banco         cuenta,
   @w_fecha_hoy    datetime,
   @w_error         int,
   @w_fecha_ult_proceso  datetime,
   @w_secuencial         int


-- SELECCIONA UNIVERSO DE OPERACIONES

select @w_fecha_hoy = fc_fecha_cierre from cobis..ba_fecha_cierre where fc_producto = 7


select @w_operacion = 0

while 1 = 1 
begin
        set rowcount 1
        
		select  @w_operacion = op_operacion,
		        @w_banco     = op_banco,
		        @w_fecha_ult_proceso = op_fecha_ult_proceso
		from    cob_cartera..ca_operacion with (nolock)
		where op_operacion in (5084930,5086525,5082159,5082715,5085538,5085235)      
		and  op_operacion > @w_operacion
		and op_fecha_ult_proceso = op_fecha_ini
		order by op_operacion
		
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0
      
                -----APlica FEcha valor y reajusta la tasa
                if @w_fecha_ult_proceso  <> @w_fecha_hoy
                begin
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
					  PRINT 'Error No hizo la fecha valor ADELANTE  REVISAR   ' + CAST (@w_banco as varchar) 
					end
				end


end ----WHILE
PRINT ''
PRINT 'Reajustes Realizados'
select op_banco,red_concepto ,red_referencial, red_signo ,red_factor
 from ca_reajuste with (nolock),
      ca_operacion with (nolock),
      ca_reajuste_det  with (nolock)
where re_operacion in (5084930,5086525,5082159,5082715,5085538,5085235)
and re_operacion = op_operacion
and re_operacion = red_operacion
and red_secuencial = re_secuencial



set rowcount 0
set nocount off

return 0

go