/************************************************************************/
/*   Archivo:              condonacion.sp                               */
/*   Stored procedure:     sp_condonacion                               */
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
/*   Procedimiento que realiza el pago a una obligación por renovación  */
/************************************************************************/

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
if not exists(select 1 from cobis..cl_errores where numero = 720401)
   insert into cobis..cl_errores values(720401, 0, 'No se encontro el registro de detalle de conceptos a condonar')
go

if not exists(select 1 from cobis..cl_errores where numero = 720402)
   insert into cobis..cl_errores values(720402, 0, 'No se encontro la obligación a condonar')
go

if not exists(select 1 from cobis..cl_errores where numero = 720403)
   insert into cobis..cl_errores values(720403, 0, 'Estado de la obligación no valido para condonaciones')
go

if not exists(select 1 from cobis..cl_errores where numero = 720404)
   insert into cobis..cl_errores values(720404, 0, 'Error en la determinación del numero de decimales de la moneda de la obligacion')
go

if not exists(select 1 from cobis..cl_errores where numero = 720405)
   insert into cobis..cl_errores values(720405, 0, 'Error en la registro de la transaccion de condonacion')
go

if not exists(select 1 from cobis..cl_errores where numero = 720407)
   insert into cobis..cl_errores values(720407, 0, 'Error en actualización del valor disponible de la garantía')
go

if not exists(select 1 from cobis..cl_errores where numero = 720408)
   insert into cobis..cl_errores values(720408, 0, 'Error en actualización del estado de agotada de la garantía')
go

if not exists(select 1 from cobis..cl_errores where numero = 720409)
   insert into cobis..cl_errores values(720409, 0, 'Error en llamada para utilización del cupo')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_condonacion')
   drop proc sp_condonacion
go

create proc sp_condonacion
@s_sesn                 int,
@s_ssn                  int,
@s_user                 login,
@s_date                 datetime,
@s_ofi                  int,
@s_term                 varchar(30),
@i_operacionca          int,        -- NÚMERO OBLIGACION QUE RECIBE LA CONDONACION
@i_en_linea             char(1),
@i_secuencial_ing       int,            -- SECUENCIAL DE PAGO
@i_secuencial_pag       int,
@i_cotizacion           money,
@i_cotizacion_dia_sus   money,
@i_num_dec_op           tinyint,
@i_num_dec_mn           tinyint
as
declare
   @w_error                      int,
   
   @w_op_estado                  smallint,
   @w_monto_sobrante             money,
   
   @w_ro_fpago                   char(1),
   @w_ro_tipo_rubro              char(1),
   @w_co_categoria               catalogo,
   @w_co_codigo                  tinyint,
   @w_op_moneda                  smallint,
   @w_op_banco                   cuenta,
   
   @w_abd_concepto               catalogo,
   @w_abd_monto_mpg              money,
   @w_estado_concepto            smallint,
   @w_ro_concepto                catalogo,
   @w_di_dividendo               smallint,
   
   @w_am_dividendo               smallint,
   @w_am_acumulado               money,
   @w_am_pagado                  money,
   @w_am_gracia                  money,
   @w_am_secuencia               tinyint,
   
   @w_monto_aplicado             money,
   @w_monto_aplicado_cap         money
begin
   select @i_cotizacion_dia_sus = isnull(@i_cotizacion_dia_sus, @i_cotizacion)
   
   select @w_monto_aplicado_cap = 0
   
   select @w_op_banco   = op_banco,
          @w_op_estado  = op_estado,
          @w_op_moneda  = op_moneda
   from   ca_operacion
   where  op_operacion = @i_operacionca
   
   if @@rowcount = 0
   begin
      select @w_error = 720402
      goto SALIDA_ERROR
   end
   
   if @w_op_estado in (0, 3, 6)
   begin
      select @w_error = 720403
      goto SALIDA_ERROR
   end
   
   declare -- CURSOR DE LOS CONCEPTOS A CONDONAR
      cur_condonar cursor
      for select abd_concepto,   convert(int, abd_cuenta),  ro_fpago,
                 abd_monto_mpg,  ro_tipo_rubro,             co_categoria,
                 co_codigo
          from   ca_abono_det, ca_rubro_op, ca_concepto
          where  abd_operacion      = @i_operacionca
          and    abd_secuencial_ing = @i_secuencial_ing
          and    ro_operacion       = @i_operacionca
          and    ro_concepto        = abd_concepto
          and    co_concepto        = abd_concepto
      for read only
   
   open cur_condonar
   
   fetch cur_condonar
   into  @w_abd_concepto,  @w_estado_concepto,  @w_ro_fpago,
         @w_abd_monto_mpg, @w_ro_tipo_rubro,    @w_co_categoria,
         @w_co_codigo
   
   if @@fetch_status in (-1, 0)
   begin
      return 708201
   end
   
   --while @@fetch_status not in (-1, 0)
   while @@fetch_status = 0
   begin
      select @w_monto_sobrante = @w_abd_monto_mpg
      
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
      
      --while @@fetch_status not in (-1,0)
      while @@fetch_status = 0
      begin
         declare
            cur_amortizacion cursor
            for select am_dividendo,   am_acumulado,  am_pagado,
                       am_gracia,      am_secuencia
                from   ca_amortizacion
                where  am_operacion = @i_operacionca
                and    am_dividendo = @w_di_dividendo + charindex('A', @w_ro_fpago)
                and    am_concepto  = @w_abd_concepto
                and    am_estado    = @w_estado_concepto
         
         open cur_amortizacion
         
         fetch cur_amortizacion
         into  @w_am_dividendo,  @w_am_acumulado,  @w_am_pagado,
               @w_am_gracia,     @w_am_secuencia
         
         --while @@fetch_status not in (-1, 0)
         while @@fetch_status = 0
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
                    @i_concepto             = @w_abd_concepto,
                    @i_secuencia_am         = @w_am_secuencia,
                    @i_monto_a_aplicar      = @w_monto_sobrante,
                    @i_ro_tipo_rubro        = @w_ro_tipo_rubro,
                    @i_ro_fpago             = @w_ro_fpago,
                    @i_co_categoria         = @w_co_categoria,
                    @i_cotizacion           = @i_cotizacion,
                    @i_cotizacion_dia_sus   = @i_cotizacion_dia_sus,
                    @i_aplicar_anticipado   = 'N',
                    @i_num_dec              = @i_num_dec_op,
                    @i_moneda               = @w_op_moneda,
                    @i_codvalor_cto         = @w_co_codigo,
                    @o_sobrante             = @w_monto_sobrante     OUT,
                    @o_monto_aplicado       = @w_monto_aplicado     OUT,
                    @o_monto_aplicado_cap   = @w_monto_aplicado_cap OUT
               
               if @w_error != 0
               begin
                  goto SALIDA_ERROR
               end
            end
            
            fetch cur_amortizacion
            into  @w_am_dividendo,  @w_am_acumulado,  @w_am_pagado,
                  @w_am_gracia,     @w_am_secuencia
         end
         
         close cur_amortizacion
         deallocate cur_amortizacion
         
         fetch cur_dividendo
         into  @w_di_dividendo
      end
      
      close cur_dividendo
      deallocate cur_dividendo
      
      fetch cur_condonar
      into  @w_abd_concepto,  @w_estado_concepto,  @w_ro_fpago,
            @w_abd_monto_mpg, @w_ro_tipo_rubro,    @w_co_categoria,
            @w_co_codigo
   end
   
   close cur_condonar
   deallocate cur_condonar
end

return 0

SALIDA_ERROR:
   return @w_error
go
