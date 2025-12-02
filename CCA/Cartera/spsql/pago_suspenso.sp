/************************************************************************/
/*   Archivo:              pago_suspenso.sp                             */
/*   Stored procedure:     sp_pago_suspenso                             */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Fabian Quintero                              */
/*   Fecha de escritura:   Junio 2006                                   */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Procedimiento que realiza el pago de suspensos de una obligación   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pago_suspenso')
   drop proc sp_pago_suspenso
go

create proc sp_pago_suspenso (
       @s_sesn                 int,
       @s_ssn                  int,
       @s_user                 login,
       @s_date                 datetime,
       @s_ofi                  int,
       @s_term                 varchar(30),
       @i_operacionca          int,        -- NÚMERO OBLIGACION QUE RECIBE EL PAGO
       @i_secuencial_ing       int,
       @i_secuencial_pag       int,
       @i_cotizacion           money,
       @i_num_dec_op           tinyint,
       @i_num_dec_mn           tinyint,
       @i_monto_pago           money,
       @o_sobrante             money OUT
)
as
declare
   @w_error                      int,
   
   @w_op_estado                  smallint,
   
   @w_ro_fpago                   char(1),
   @w_ro_tipo_rubro              char(1),
   @w_co_categoria               catalogo,
   @w_co_codigo                  tinyint,
   @w_op_moneda                  smallint,
   
   @w_am_concepto                catalogo,
   @w_di_dividendo               smallint,
   
   @w_am_dividendo               smallint,
   @w_am_acumulado               money,
   @w_am_pagado                  money,
   @w_am_gracia                  money,
   @w_am_secuencia               tinyint,
   
   @w_monto_aplicado             money,
   @w_monto_aplicado_cap         money
begin
   select @w_monto_aplicado_cap = 0
   
   select @w_op_estado  = op_estado,
          @w_op_moneda  = op_moneda
   from   ca_operacion
   where  op_operacion = @i_operacionca
   
   if @@rowcount = 0
   begin
      select @w_error = 720501
      goto SALIDA_ERROR
   end
   
   if @w_op_estado in (0, 3, 6)
   begin
      select @w_error = 720502
      goto SALIDA_ERROR
   end
   
   select @o_sobrante = @i_monto_pago
   
   declare
      cur_dividendo cursor
      for select di_dividendo
          from   ca_dividendo
          where  di_operacion = @i_operacionca
          and    di_estado in (1, 2) -- SOLO SE TIENE EN CUENTA DIVIDENDOS VENCIDOS O VIGENTES
          order  by di_dividendo
      for read only
   
   open cur_dividendo
   
   fetch cur_dividendo
   into  @w_di_dividendo
   
--   while @@fetch_status not in (-1,0)  and @o_sobrante > 0
   while @@fetch_status = 0 and @o_sobrante > 0
   begin
      declare
         cur_amortizacion cursor
         for select am_dividendo,   am_acumulado,  am_pagado,
                    am_gracia,      am_secuencia,  am_concepto,
                    ro_fpago,       ro_tipo_rubro, co_categoria,
                    co_codigo
             from   ca_amortizacion, ca_rubro_op, ca_concepto
             where  ro_operacion = @i_operacionca
             and    am_operacion = @i_operacionca
             and    am_dividendo = @w_di_dividendo + charindex('A', ro_fpago)
             and    am_concepto  = ro_concepto
             and    am_estado    = 9
             and    am_acumulado > am_pagado
             and    co_concepto  = am_concepto
             order  by ro_prioridad DESC
         for read only
      
      open cur_amortizacion
      
      fetch cur_amortizacion
      into  @w_am_dividendo,  @w_am_acumulado,  @w_am_pagado,
            @w_am_gracia,     @w_am_secuencia,  @w_am_concepto,
            @w_ro_fpago,      @w_ro_tipo_rubro, @w_co_categoria,
            @w_co_codigo
      
--      while @@fetch_status not in (-1,0) and @o_sobrante > 0
      while @@fetch_status = 0 and @o_sobrante > 0
      begin
         -- VERIFICAR QUE ES PAGABLE
         if   @w_am_acumulado > 0
         and  @w_am_pagado < @w_am_acumulado
         begin
            -- PAGAR
            exec @w_error = sp_aplica_rubro_sec
                 @s_date                 = @s_date,
                 @i_operacion            = @i_operacionca,
                 @i_op_estado            = @w_op_estado,
                 @i_secuencial_pag       = @i_secuencial_pag,
                 @i_dividendo            = @w_am_dividendo,
                 @i_concepto             = @w_am_concepto,
                 @i_secuencia_am         = @w_am_secuencia,
                 @i_monto_a_aplicar      = @o_sobrante,
                 @i_ro_tipo_rubro        = @w_ro_tipo_rubro,
                 @i_ro_fpago             = @w_ro_fpago,
                 @i_co_categoria         = @w_co_categoria,
                 @i_cotizacion           = @i_cotizacion,
                 @i_aplicar_anticipado   = 'N',
                 @i_num_dec              = @i_num_dec_op,
                 @i_moneda               = @w_op_moneda,
                 @i_codvalor_cto         = @w_co_codigo,
                 @o_sobrante             = @o_sobrante           OUT,
                 @o_monto_aplicado       = @w_monto_aplicado     OUT,
                 @o_monto_aplicado_cap   = @w_monto_aplicado_cap OUT
            
            if @w_error != 0
            begin
               goto SALIDA_ERROR
            end
         end
         
         fetch cur_amortizacion
         into  @w_am_dividendo,  @w_am_acumulado,  @w_am_pagado,
               @w_am_gracia,     @w_am_secuencia,  @w_am_concepto,
               @w_ro_fpago,      @w_ro_tipo_rubro, @w_co_categoria,
               @w_co_codigo
      end
      
      close cur_amortizacion
      deallocate cur_amortizacion
      
      fetch cur_dividendo
      into  @w_di_dividendo
   end
   
   close cur_dividendo
   deallocate cur_dividendo
   
   if exists(select 1
             from   ca_amortizacion
             where  am_operacion = @i_operacionca
             and    am_acumulado < am_pagado)
      return 720503
end

return 0

SALIDA_ERROR:
   return @w_error
go
