/************************************************************************/
/*   Archivo:              aplicarubrosec.sp                            */
/*   Stored procedure:     sp_aplica_rubro_sec                          */
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
set nocount on
go

--- SECCION:ERRORES no quitar esta seccion
if not exists(select 1 from cobis..cl_errores where numero = 720201)
   insert into cobis..cl_errores values(720201, 0, 'No se encontro el registro en ca_amortizacion para aplicar el pago')
go

if not exists(select 1 from cobis..cl_errores where numero = 720202)
   insert into cobis..cl_errores values(720202, 0, 'El monto a aplicar supera el monto proyectado')
go

if not exists(select 1 from cobis..cl_errores where numero = 720203)
   insert into cobis..cl_errores values(720203, 0, 'El monto a aplicar supera el monto acumulado')
go

if not exists(select 1 from cobis..cl_errores where numero = 720204)
   insert into cobis..cl_errores values(720204, 0, 'Error aplicando pago en el rubro de la tabla de amortizacion')
go

if not exists(select 1 from cobis..cl_errores where numero = 720205)
   insert into cobis..cl_errores values(720205, 0, 'Error insertando el detalle de transacción durante la aplicación')
go
--- FINSECCION:ERRORES no quitar esta seccion

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplica_rubro_sec')
   drop proc sp_aplica_rubro_sec
go

create proc sp_aplica_rubro_sec
@s_date                 datetime,
@i_operacion            int,            -- OPERACION A LA QUE PERTENECE EL RUBRO
@i_op_estado            smallint,       -- ESTADO DE LA OBLIGACION
@i_secuencial_pag       int,            -- SECUENCIAL DEL PAGO (PAG)
@i_dividendo            smallint,       -- DIVIDENDO AL CUAL PERTENECE EL RUBRO
@i_concepto             catalogo,       -- RUBRO A ABONAR
@i_secuencia_am         tinyint,        -- SECUENCIA DEL VALOR DEL CONCEPTO EN LA TABLA DE AMORTIZACION
@i_monto_a_aplicar      money,
@i_ro_tipo_rubro        char(1),
@i_ro_fpago             char(1),
@i_co_categoria         char(1),
@i_cotizacion           float,
@i_aplicar_anticipado   char(1),  -- N: SOLO SE PODRA PAGAR HASTA AM_ACUMULADO, S: SE PODRA PAGAR HASTA AM_CUOTA
@i_num_dec              smallint,
@i_moneda               smallint,
@i_codvalor_cto         int,

@o_sobrante             money out,
@o_monto_aplicado       money out,
@o_monto_aplicado_cap   money out

as
declare
   @w_am_estado            smallint,
   @w_am_cuota             money,
   @w_am_acumulado         money,
   @w_am_pagado            money,
   @w_monto_a_aplicar_mn   money,
   @w_codvalor             int

begin
   select @w_am_estado     = am_estado,
          @w_am_cuota      = am_cuota,
          @w_am_acumulado  = am_acumulado,
          @w_am_cuota      = am_cuota,
          @w_am_pagado     = am_pagado
   from   ca_amortizacion
   where  am_operacion = @i_operacion
   and    am_dividendo = @i_dividendo
   and    am_concepto  = @i_concepto
   and    am_secuencia = @i_secuencia_am
   
   if @@rowcount = 0
      return 720201
   
   select @o_sobrante = @i_monto_a_aplicar
   
   if @i_aplicar_anticipado = 'S' -- PERMITE APLICAR HASTA EL PROYECTADO
   begin
      if @i_monto_a_aplicar > (@w_am_cuota - @w_am_pagado)
         select @i_monto_a_aplicar = (@w_am_cuota - @w_am_pagado)
   end
   ELSE -- SOLO HASTA EL ACUMULADO
   begin
      if @i_monto_a_aplicar > (@w_am_acumulado - @w_am_pagado)
         select @i_monto_a_aplicar = (@w_am_acumulado - @w_am_pagado)
   end
   
   select @w_codvalor = (@i_codvalor_cto * 1000) + (@w_am_estado * 10) + 0
   
   -- ACTUALIZAR LA TABLA DE AMORTIZACION
   update ca_amortizacion
   set    am_pagado = am_pagado + @i_monto_a_aplicar
   where  am_operacion = @i_operacion
   and    am_dividendo = @i_dividendo
   and    am_concepto  = @i_concepto
   and    am_secuencia = @i_secuencia_am
   
   if @@error != 0
   begin
      return 720204
   end
   
   if @i_ro_tipo_rubro <> 'M'
   begin
      update ca_amortizacion
      set    am_estado    = 3
      where  am_operacion = @i_operacion
      and    am_dividendo = @i_dividendo
      and    am_concepto  = @i_concepto
      and    am_secuencia = @i_secuencia_am
      and    am_cuota     = am_pagado
   end

   select @w_monto_a_aplicar_mn = round(@i_monto_a_aplicar * @i_cotizacion, 0)
   
   -- INSERTAR EN EL DETALLE DE LA TRANSACCION
   insert into ca_det_trn
         (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
          dtr_concepto,       dtr_estado,     dtr_periodo,
          dtr_codvalor,       dtr_monto,      dtr_monto_mn,
          dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
          dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
          dtr_monto_cont)
   values(@i_secuencial_pag,  @i_operacion,        @i_dividendo,
          @i_concepto,        @w_am_estado,        0,
          @w_codvalor,        @i_monto_a_aplicar,  @w_monto_a_aplicar_mn,
          @i_moneda,          @i_cotizacion,       'N',
          'C',                '00000',        'CARTERA',
          0.00)
   
   if @@error != 0
   begin
      return 720205
   end
   
   select @o_monto_aplicado = isnull(@o_monto_aplicado, 0) + @i_monto_a_aplicar
   
   if @i_co_categoria = 'C'
      select @o_monto_aplicado_cap = isnull(@o_monto_aplicado_cap, 0) + @i_monto_a_aplicar
   
   select @o_sobrante = @o_sobrante - @i_monto_a_aplicar
end

return 0
go
