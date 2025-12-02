/************************************************************************/
/*   Archivo:              aplicarubro.sp                               */
/*   Stored procedure:     sp_aplica_rubro                              */
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
/*   Procedimiento que realiza el abono de los rubros de Cartera        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplica_rubro')
   drop proc sp_aplica_rubro
go

create proc sp_aplica_rubro
@s_date                 datetime,
@i_operacion            int,            -- OPERACION A LA QUE PERTENECE EL RUBRO
@i_op_estado            smallint,       -- ESTADO DE LA OBLIGACION
@i_secuencial_pag       int,            -- SECUENCIAL DEL PAGO (PAG)
@i_dividendo            smallint,       -- DIVIDENDO AL CUAL PERTENECE EL RUBRO
@i_concepto             catalogo,       -- RUBRO A ABONAR
@i_monto_a_aplicar      money,
@i_ro_tipo_rubro        char(1),
@i_ro_fpago             char(1),
@i_co_categoria         char(1),
@i_cotizacion           float,
@i_cotizacion_dia_sus   float,
@i_aplicar_anticipado   char(1),  -- N: SOLO SE PODRA PAGAR HASTA AM_ACUMULADO, S: SE PODRA PAGAR HASTA AM_CUOTA
@i_num_dec              smallint,
@i_moneda               smallint,
@i_codvalor_cto         int,

@o_sobrante             money out,
@o_monto_aplicado       money out,
@o_monto_aplicado_cap   money out

as
declare
   @w_error          int,
   @w_am_secuencia   tinyint,
   @w_am_cuota       money,
   @w_am_acumulado   money,
   @w_am_pagado      money,
   @w_am_estado      smallint

begin
   declare
      cur_secuencias cursor
      for select am_secuencia, am_cuota, am_acumulado, am_pagado, am_estado
          from   ca_amortizacion
          where  am_operacion = @i_operacion
          and    am_dividendo = @i_dividendo
          and    am_concepto  = @i_concepto
          order  by am_secuencia
      for read only
   
   open cur_secuencias
   
   fetch cur_secuencias
   into  @w_am_secuencia, @w_am_cuota, @w_am_acumulado, @w_am_pagado, @w_am_estado
   
--   while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin
      if @w_am_estado != 3 -- SE SALTA LAS SECUENCIAS YA PAGADAS
      begin
         exec @w_error = sp_aplica_rubro_sec
              @s_date                 = @s_date,
              @i_operacion            = @i_operacion,
              @i_op_estado            = @i_op_estado,
              @i_secuencial_pag       = @i_secuencial_pag,
              @i_dividendo            = @i_dividendo,
              @i_concepto             = @i_concepto,
              @i_secuencia_am         = @w_am_secuencia,
              @i_monto_a_aplicar      = @i_monto_a_aplicar,
              @i_ro_tipo_rubro        = @i_ro_tipo_rubro,
              @i_ro_fpago             = @i_ro_fpago,
              @i_co_categoria         = @i_co_categoria,
              @i_cotizacion           = @i_cotizacion,
--              @i_cotizacion_dia_sus   = @i_cotizacion_dia_sus,
              @i_aplicar_anticipado   = @i_aplicar_anticipado,
              @i_num_dec              = @i_num_dec,
              @i_moneda               = @i_moneda,
              @i_codvalor_cto         = @i_codvalor_cto,
              @o_sobrante             = @o_sobrante           OUT,
              @o_monto_aplicado       = @o_monto_aplicado     OUT,
              @o_monto_aplicado_cap   = @o_monto_aplicado_cap OUT
         
         if @w_error != 0
            return @w_error
      end
      
      fetch cur_secuencias
      into  @w_am_secuencia, @w_am_cuota, @w_am_acumulado, @w_am_pagado, @w_am_estado
   end
   
   close cur_secuencias
   deallocate cur_secuencias
end

return 0
go
