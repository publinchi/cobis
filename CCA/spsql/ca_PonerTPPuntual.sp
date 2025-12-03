use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_poner_TP_tmp_puntual')
   drop proc sp_poner_TP_tmp_puntual
go

create proc sp_poner_TP_tmp_puntual
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
   @w_fecha_ult_proceso  datetime,
   @w_secuencial         int


-- SELECCIONA UNIVERSO DE OPERACIONES

select @w_fecha_hoy = fc_fecha_cierre from cobis..ba_fecha_cierre where fc_producto = 7

delete ca_reajuste
where re_operacion in (5084930,5086525,5082159,5082715,5085538,5085235)

delete ca_reajuste_det
where red_operacion in (5084930,5086525,5082159,5082715,5085538,5085235)

select @w_operacion = 0

while 1 = 1 
begin
        set rowcount 1
        
		select  @w_operacion = op_operacion,
		        @w_spread    = spread,
		        @w_signo     = signo,
		        @w_banco     = op_banco,
		        @w_fecha_ult_proceso = op_fecha_ult_proceso
		from cob_cartera..ca_TP_tmp,
		     cob_cartera..ca_operacion with (nolock),
		     cob_cartera..ca_rubro_op with (nolock)
		where op_operacion in (5084930,5086525,5082159,5082715,5085538,5085235)      
        and puntos_hoy = 0
		and   spread  <> 0  ----ma MAtriz retorno puntos
		and op_tramite = tramite
		and op_estado = 1
        and ro_operacion = op_operacion
        and ro_concepto = 'INT'
        and ro_factor = 0
		and  op_operacion > @w_operacion
		order by op_operacion
		
      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0

          
          
           select @w_tr_fecha_ref  = '01/01/1900'
	       select @w_tr_fecha_ref = tr_fecha_ref
	       from ca_transaccion
	       where tr_operacion = @w_operacion
	       and   tr_tran = 'DES'
	       and   tr_estado <> 'RV'
	       and   tr_secuencial >= 0
	
            if @w_fecha_ult_proceso <> @w_tr_fecha_ref
            begin
		     	exec @w_error = sp_fecha_valor 
				@s_user              = 'script',        
				@i_fecha_valor       = @w_tr_fecha_ref,
				@s_term              = 'Terminal', 
				@s_date              = @w_fecha_hoy,
				@i_banco             = @w_banco,
				@i_operacion         = 'F',
				@i_en_linea          = 'N',
				@i_control_fecha     = 'N',
				@i_debug             = 'N'
				if @w_error <> 0
				begin
				  PRINT 'Error No hizo la fecha valor REVISAR   ' + CAST (@w_banco as varchar) + ' @w_tr_fecha_ref  : ' + cast (@w_tr_fecha_ref as varchar)
				end
			end
			select @w_fecha_ult_proceso = op_fecha_ult_proceso
			from ca_operacion
			where op_operacion = @w_operacion
			
			if  @w_fecha_ult_proceso = @w_tr_fecha_ref
			begin
                    PRINT 'Entro a registrar   ' + CAST (@w_banco as varchar)
					   exec @w_secuencial = sp_gen_sec
					        @i_operacion  = @w_operacion
					   
					   insert into ca_reajuste with (rowlock)
					         (re_secuencial,         re_operacion,     re_fecha,
					          re_reajuste_especial,  re_desagio)
					   values(@w_secuencial,         @w_operacion
					          ,@w_tr_fecha_ref,   'N',           'E') 
					   
					   if @@error <> 0
						begin
						  PRINT 'Error en ca_reajuste   ' + CAST (@w_banco as varchar)
						end
					   
					   -- INSERCION DEL DETALLE DE REAJUSTE
					    
					   insert into ca_reajuste_det with (rowlock)
					         (red_secuencial,  red_operacion,    red_concepto,  red_referencial,
					          red_signo,       red_factor,       red_porcentaje)
					   values(@w_secuencial,   @w_operacion,   'INT',   'TIBA',
					          @w_signo,        @w_spread,       0 )
					   
					   if @@error <> 0
						begin
						  PRINT 'Error  en ca_reajuste_det  ' + CAST (@w_banco as varchar)
						end
			 end    


end ----WHILE
PRINT ''
PRINT 'Reajustes registrados'
select op_banco,re_fecha,red_concepto ,red_referencial, red_signo ,red_factor
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