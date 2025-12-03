
use cob_cartera
go

if exists(select 1 from cob_cartera..sysobjects where name = 'sp_carga_pagos_mig')
   drop proc sp_carga_pagos_mig
go

create proc sp_carga_pagos_mig
as

declare @w_pa_operacion		varchar(24),
        @w_pa_fecha_pago	datetime,
	@w_pa_monto		money,
	@w_pa_monto_int		money,
	@w_pa_moneda		int,
 	@w_pa_cotizacion	float,
	@w_pa_forma_pag		varchar(20),
	@w_pa_numero		int,
	@w_operacion		int,
	@w_error_mig 		int


   declare cursor_operacion cursor  
   for   select pa_operacion,
                pa_fecha_pago,
                pa_monto,
                pa_monto_int,
                pa_moneda,
                pa_cotizacion,
                pa_formapag,
                pa_numero
         from   mig_cartera..ca_pagos_mig  
         where  pa_fecha_pago >= '01/01/2004'
         and    pa_fecha_pago <= '02/29/2004' 
         for read only

   open cursor_operacion 
   fetch cursor_operacion into
         @w_pa_operacion,
         @w_pa_fecha_pago,
         @w_pa_monto,
         @w_pa_monto_int,
         @w_pa_moneda,
         @w_pa_cotizacion,
         @w_pa_forma_pag,
         @w_pa_numero

   while (@@fetch_status = 0) 
   begin
      if (@@fetch_status = -1) 
      begin
	 return 1
      end 

      select @w_operacion = op_operacion
      from  ca_operacion
      where op_migrada = @w_pa_operacion
      
      select @w_error_mig = @@error
      if @w_error_mig <> 0
      begin
         print 'Operacion   Error  ' + cast(@w_pa_operacion as varchar) + cast(@w_error_mig as varchar)
      end      

      if @w_pa_moneda = 2
      begin
         insert into ca_abono_rubro(
                ar_fecha_pag,     ar_secuencial,   ar_operacion,    ar_dividendo, ar_concepto,     ar_estado,      
		ar_monto_mn,      ar_cotizacion,   ar_afectacion,   ar_tasa_pago, ar_dias_pagados, ar_monto,
                ar_moneda)
         values(@w_pa_fecha_pago, -68,             @w_operacion,    0,            'INT',           1,
                @w_pa_monto,      @w_pa_cotizacion,'C',             0,            30,              @w_pa_monto_int/@w_pa_cotizacion,
	        convert(tinyint,@w_pa_moneda))
      end                      
      else
      begin
         insert into ca_abono_rubro(
                ar_fecha_pag,     ar_secuencial,    ar_operacion,    ar_dividendo, ar_concepto,    ar_estado,
      		ar_monto_mn,      ar_cotizacion,    ar_afectacion,   ar_tasa_pago, ar_dias_pagados,ar_monto,
                ar_moneda)
         values(@w_pa_fecha_pago, -68,           @w_operacion,       0,            'INT',          1,
                @w_pa_monto,      @w_pa_cotizacion, 'C',             0,            30,             @w_pa_monto_int,
                convert(tinyint,@w_pa_moneda))
      end 
      fetch cursor_operacion into
         @w_pa_operacion,
         @w_pa_fecha_pago,
         @w_pa_monto,
         @w_pa_monto_int,
         @w_pa_moneda,
         @w_pa_cotizacion,
         @w_pa_forma_pag,
         @w_pa_numero
   end
   close cursor_operacion
   deallocate cursor_operacion

return 0  
go             

