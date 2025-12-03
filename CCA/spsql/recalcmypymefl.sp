/************************************************************************/
/*      Archivo:                recalcmypymefl.sp                       */
/*      Stored procedure:       sp_recalc_mipyme_flexible               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          5                                       */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Recalcula los valores proyectados de comisión MiPyme de la      */
/*      tabla de amortizacion FLEXIBLE.                                 */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-05-13     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
if not exists(select 1 from cobis..cl_errores where numero = 70005003)
   insert into cobis..cl_errores values(70005003, 0, 'FALTA DEFINICION DE PARAMETRO GENERAL DE CONCEPTO DE COMISION MIPYME')
go
if not exists(select 1 from cobis..cl_errores where numero = 70005004)
   insert into cobis..cl_errores values(70005004, 0, 'FALTA DEFINICION DE PARAMETRO GENERAL DE CONCEPTO DE IVA DE COMISION MIPYME')
go
if not exists(select 1 from cobis..cl_errores where numero = 70005005)
   insert into cobis..cl_errores values(70005005, 0, 'AL PRESTAMO LE FALTA EL CONCEPTO DE COMISION MIPYME')
go
if not exists(select 1 from cobis..cl_errores where numero = 70005001)
   insert into cobis..cl_errores values(70005001, 0, 'NO SE ENCUENTRA EL PRESTAMO')
go
if not exists(select 1 from cobis..cl_errores where numero = 70005002)
   insert into cobis..cl_errores values(70005002, 0, 'ERROR RECALCULANDO LA COMISION MIPYME, EL NUEVO VALOR RESULTA MAYOR AL PRECALCULADO')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_recalc_mipyme_flexible')
   drop proc sp_recalc_mipyme_flexible
go

---NR000392
create proc sp_recalc_mipyme_flexible
   @i_debug                         char(1) = 'N',
   @i_operacionca                   int,
   @i_num_dec                       tinyint
as
declare
   @w_saldo                   money,
   @w_control_fecha_fin       tinyint,
   @w_icta                    smallint,
   @w_ult_div                 smallint,
   @w_error                   int,

   @w_monto_cap               money,
   @w_cap_distribuido         money,
   @w_op_fecha_ini            datetime,
   @w_op_fecha_fin            datetime,
   @w_op_fecha_ult_proceso    datetime,
   @w_anio_corriente          smallint,
   @w_anio_reproceso          smallint,
   @w_fecha_ini               datetime,
   @w_fecha_fin               datetime,
   @w_cto_mipyme              catalogo,
   @w_cto_mipyme_iva          catalogo,
   
   @w_dividendo_ini           smallint,
   @w_dividendo_fin           smallint,
   @w_tasa_mipyme             float,
   @w_tasa_mipyme_iva         float,
   @w_mipyme_previo           money,
   @w_dias_anio               float,
   @w_vlr_mipyme_anual        money,
   @w_proporcion_cambio       float,
   @w_diferencia_redondeo     money,

   @w_op_dia_fijo             smallint,
   @w_op_toperacion           catalogo,
   @w_op_tipo                 char,
   @w_fecha_limite_fng        datetime,
   @w_op_dias_anio            smallint,
   @w_op_causacion            char,
   @w_parametro_segdeuven     catalogo,
   @w_parametro_segdeuem      catalogo,
   @w_cto_fng_vencido         catalogo,
   @w_cto_fng_iva             catalogo,
   @w_max_dias_cuota          smallint,
   @w_min_cuotas_anio         smallint
begin
   select @w_tasa_mipyme = 0

   select @w_cto_mipyme = pa_char
   from cobis..cl_parametro  with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'MIPYME'

   if @@ROWCOUNT = 0
   begin
      return 70005003 -- FALTA DEFINICION DE PARAMETRO GENERAL DE CONCEPTO DE COMISION MIPYME
   end
   
   select @w_cto_mipyme_iva = pa_char
   from cobis..cl_parametro  with (nolock)
   where pa_producto = 'CCA'
   and   pa_nemonico = 'IVAMIP'

   if @@ROWCOUNT = 0
   begin
      return 70005004 -- FALTA DEFINICION DE PARAMETRO GENERAL DE CONCEPTO DE IVA DE COMISION MIPYME
   end
   
   select @w_tasa_mipyme = ro_porcentaje
   from   ca_rubro_op
   where  ro_operacion = @i_operacionca
   and    ro_concepto  = @w_cto_mipyme

   if @@ROWCOUNT = 0
   begin
      -- ESTA OPERACION NO TIENE CONCEPTO MIPYME
      return 0
   end

   select @w_tasa_mipyme_iva = 0

   select @w_tasa_mipyme_iva = ro_porcentaje
   from   ca_rubro_op
   where  ro_operacion = @i_operacionca
   and    ro_concepto  = @w_cto_mipyme_iva

   if @@ROWCOUNT = 0
   begin
      return 70005005 -- AL PRESTAMO LE FALTA EL CONCEPTO DE COMISION MIPYME
   end
   -- CALCULAR EL MONTO DEL CAPITAL TOTAL
   select @w_monto_cap    = sum(ro_valor)
   from   ca_rubro_op
   where  ro_operacion  = @i_operacionca
   and    ro_tipo_rubro = 'C'
   and    ro_fpago      in ('P','A','T') -- PERIODICO VENCIDO 

   select @w_op_fecha_ini           = op_fecha_ini,
          @w_op_fecha_fin           = op_fecha_fin,
          @w_op_dias_anio           = op_dias_anio
   from   ca_operacion
   where  op_operacion = @i_operacionca

   if @@ROWCOUNT = 0
   begin
      return 70005001 -- NO SE ENCUENTRA EL PRESTAMO
   end
   
   select @w_op_fecha_ult_proceso   = null

   select @w_op_fecha_ult_proceso   = min(di_fecha_ini)
   from   ca_dividendo
   where  di_operacion = @i_operacionca
   and    di_estado = 0

   if @w_op_fecha_ult_proceso is null
   begin
      return 0 -- NO TIENE CUOTAS EN ESTADO NO VIGENTE (FUTURAS, POR LO TANTO NO HAY NADA QUE RECALCULAR)
   end

   if @w_op_fecha_ult_proceso < @w_op_fecha_ini
      select @w_op_fecha_ult_proceso = @w_op_fecha_ini

   select @w_anio_corriente = 0

   while (@w_op_fecha_ult_proceso >= DATEADD(YEAR, @w_anio_corriente, @w_op_fecha_ini) )
   begin
      select @w_anio_corriente = @w_anio_corriente + 1
   end
   
   select @w_fecha_ini = DATEADD(YEAR, @w_anio_corriente, @w_op_fecha_ini),
          @w_fecha_fin = DATEADD(YEAR, @w_anio_corriente + 1, @w_op_fecha_ini)

   if @i_debug = 'S'
      print 'AÑO CORRIENTE ' +  convert(varchar, @w_anio_corriente)
         + ' (' + convert(varchar, @w_fecha_ini) + ' - '+ convert(varchar, @w_fecha_fin) +')'

   select @w_anio_reproceso = @w_anio_corriente
   select @w_fecha_ini = DATEADD(YEAR, @w_anio_reproceso, @w_op_fecha_ini),
          @w_fecha_fin = DATEADD(YEAR, @w_anio_reproceso + 1, @w_op_fecha_ini)

   while @w_fecha_ini < @w_op_fecha_fin
   begin
      select @w_dividendo_ini = min(di_dividendo),
             @w_dividendo_fin = max(di_dividendo)
      from   ca_dividendo
      where  di_operacion = @i_operacionca
      and    di_fecha_ven >= @w_fecha_ini
      and    di_fecha_ven < @w_fecha_fin

      if @i_debug = 'S'
      begin
         print ''
         print 'RECALCULAR EL AÑO ' + convert(varchar, @w_anio_reproceso) + ' (' + convert(varchar, @w_fecha_ini) + ' - '+ convert(varchar, @w_fecha_fin) +')'
               + '  (' + convert(varchar, isnull(@w_dividendo_ini, 0)) + ' - '+ convert(varchar, isnull(@w_dividendo_fin, 0)) +')'
      end
      -- OBTENER EL VALOR DE COMISION QUE SE HABÍA CALCULADO ANTERIORMENTE
      select @w_mipyme_previo = isnull(sum(am_cuota), 0)
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo between @w_dividendo_ini and @w_dividendo_fin
      and    am_concepto = @w_cto_mipyme

      if @w_mipyme_previo = 0
      begin
         if @i_debug = 'S'
            print 'ANIO SIN COMISION ' + convert(varchar, @w_anio_reproceso) + ' (' + convert(varchar, @w_fecha_ini) + ' - '+ convert(varchar, @w_fecha_fin) +')'

         select @w_anio_reproceso = @w_anio_reproceso + 1
         select @w_fecha_ini = DATEADD(YEAR, @w_anio_reproceso, @w_op_fecha_ini),
                @w_fecha_fin = DATEADD(YEAR, @w_anio_reproceso + 1, @w_op_fecha_ini)

         continue -- SI EN ESTE AÑO NO HAY COMISION ENTONCES PASAR AL SIGUIENTE AÑO
      end

      -- OBTENER EL 'SALDO' DE CAPITAL TEORICO (BASADO EN EL PROYECTADO PARA EL AÑO)
      -- EL ES TOTAL MENOS LO DISTRIBUIDO EN CUOTAS ANTERIORES AL AÑO QUE SE ESTA REPROCESANDO
      select @w_cap_distribuido = isnull(sum(am_cuota), 0)
      from   ca_amortizacion
      inner  join ca_rubro_op on am_operacion = ro_operacion and am_concepto = ro_concepto
      where  ro_operacion = @i_operacionca
      and    ro_tipo_rubro = 'C'
      and    ro_fpago      in ('P','A','T') -- PERIODICO VENCIDO 
      and    am_dividendo < @w_dividendo_ini

      select @w_saldo = @w_monto_cap - @w_cap_distribuido

      -- CALCULAR EL VALOR DE COMISIÓN PARA EL AÑO EN CUESTION
      select @w_vlr_mipyme_anual = @w_saldo * @w_tasa_mipyme / 100.0-- ESTE ES EL CALCULO DE UN AÑO COMPLETO

      if @i_debug = 'S'
         print 'valor anio ' + convert(varchar, @w_vlr_mipyme_anual) + ' = ' + convert(varchar, @w_saldo) + ' * ' + convert(varchar, @w_tasa_mipyme)
             + '  distribuido ' + convert(varchar, @w_cap_distribuido)

      if @i_debug = 'S'
         print 'fecha fin anio ' + convert(varchar, @w_fecha_fin) + ' ?> ' + convert(varchar, @w_op_fecha_fin) 

      if @w_fecha_fin > @w_op_fecha_fin -- SE DEBE PROPORCIONAR AL NUMERO DE DIAS DEL AÑO
      begin
         if @i_debug = 'S'
            print 'AÑO PARCIAL'
         
         exec @w_error = sp_dias_cuota_360
               @i_fecha_ini = @w_fecha_ini,
               @i_fecha_fin = @w_op_fecha_fin,
               @o_dias      = @w_dias_anio OUTPUT
            
         if @w_error != 0
            return @w_error

         select @w_vlr_mipyme_anual = @w_vlr_mipyme_anual * @w_dias_anio / @w_op_dias_anio
      end

      select @w_vlr_mipyme_anual = round(@w_vlr_mipyme_anual, @i_num_dec)

      if @w_vlr_mipyme_anual > @w_mipyme_previo
      begin
         if @i_debug = 'S'
            print 'ERROR, SUBIO LA COMISION DE ' + convert(varchar, @w_mipyme_previo) + ' a ' + convert(varchar, @w_vlr_mipyme_anual)
         return 70005002 -- ERROR RECALCULANDO LA COMISION MIPYME, EL NUEVO VALOR RESULTA MAYOR AL PRECALCULADO
      end

      if @w_vlr_mipyme_anual = @w_mipyme_previo
      begin
         if @i_debug = 'S'
            print 'ANIO SIN CAMBIO'

         select @w_anio_reproceso = @w_anio_reproceso + 1
         select @w_fecha_ini = DATEADD(YEAR, @w_anio_reproceso, @w_op_fecha_ini),
                @w_fecha_fin = DATEADD(YEAR, @w_anio_reproceso + 1, @w_op_fecha_ini)

         continue -- SI NO HAY CAMBIO ENTONCES PASAR AL SIGUIENTE AÑO
      end
      
      select @w_proporcion_cambio = @w_vlr_mipyme_anual / @w_mipyme_previo

      if @i_debug = 'S'
      begin
         print 'antes= ' + convert(varchar, @w_mipyme_previo) + ', ahora= ' + convert(varchar, @w_vlr_mipyme_anual)
             + ', proporcion= ' + convert(varchar, @w_proporcion_cambio)
      end

      -- RECALCULAR LOS VALORES DE COMISIÓN PARA LAS CUOTAS DEL AÑO
      update ca_amortizacion
      set    am_cuota = round(am_cuota * @w_proporcion_cambio, @i_num_dec),
             am_acumulado = round(am_acumulado * @w_proporcion_cambio, @i_num_dec)
      where  am_operacion = @i_operacionca
      and    am_dividendo between @w_dividendo_ini and @w_dividendo_fin
      and    am_concepto = @w_cto_mipyme
      
      -- REVISAR QUE EL NUEVO VALOR DE LAS COMISIONES SEA IGUAL AL RECALCULO ANUAL (PUEDE SER DIFERENTE POR EFECTO DE LOS REDONDEOS)
      select @w_mipyme_previo = isnull(sum(am_cuota), 0)
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo between @w_dividendo_ini and @w_dividendo_fin
      and    am_concepto = @w_cto_mipyme

      if @w_mipyme_previo > @w_vlr_mipyme_anual -- LOS REDONDEOS QUEDARON POR DEBAJO
      begin -- AJUSTAR ALGUNA DE LAS CUOTAS RESTANDOLE
         select @w_diferencia_redondeo = @w_mipyme_previo - @w_vlr_mipyme_anual

         if @i_debug = 'S'
            print 'SE REDONDEO POR ENCIMA, DIFERENCIA = ' + convert(varchar, @w_diferencia_redondeo)

         set rowcount 1
         update ca_amortizacion
         set    am_cuota = am_cuota - @w_diferencia_redondeo,
                am_acumulado = am_acumulado - @w_diferencia_redondeo
         where  am_operacion = @i_operacionca
         and    am_dividendo between @w_dividendo_ini and @w_dividendo_fin
         and    am_concepto = @w_cto_mipyme
         and    am_cuota >= @w_diferencia_redondeo
         set rowcount 0
      end
      else
      begin -- AJUSTAR ALGUNA DE LAS CUOTAS SUMANDOLE
         select @w_diferencia_redondeo = @w_vlr_mipyme_anual - @w_mipyme_previo

         if @i_debug = 'S'
            print 'SE REDONDEO POR DEBAJO, DIFERENCIA = ' + convert(varchar, @w_diferencia_redondeo)

         set rowcount 1
         update ca_amortizacion
         set    am_cuota = am_cuota + @w_diferencia_redondeo,
                am_acumulado = am_acumulado + @w_diferencia_redondeo
         where  am_operacion = @i_operacionca
         and    am_dividendo between @w_dividendo_ini and @w_dividendo_fin
         and    am_concepto = @w_cto_mipyme
         set rowcount 0
      end

      -- CALCULAR EL IVA DE LA COMISION
      update ca_amortizacion
      set    am_cuota = (select round(am_cuota * @w_tasa_mipyme_iva / 100.0, @i_num_dec)
                         from   ca_amortizacion
                         where  am_operacion = @i_operacionca
                         and    am_dividendo = A.am_dividendo
                         and    am_concepto  = @w_cto_mipyme
                         )
      from   ca_amortizacion as A
      where  am_operacion = @i_operacionca
      and    am_dividendo between @w_dividendo_ini and @w_dividendo_fin
      and    am_concepto = @w_cto_mipyme_iva

      update ca_amortizacion
      set    am_acumulado = am_cuota * (case
                                        when ro_provisiona = 'S' then 0.0
                                        else 1.0
                                        end)
      from   ca_rubro_op
      where  am_operacion = @i_operacionca
      and    am_dividendo between @w_dividendo_ini and @w_dividendo_fin
      and    am_concepto = @w_cto_mipyme_iva
      and    ro_operacion = @i_operacionca
      and    ro_concepto = @w_cto_mipyme_iva
      --
      select @w_anio_reproceso = @w_anio_reproceso + 1
      select @w_fecha_ini = DATEADD(YEAR, @w_anio_reproceso, @w_op_fecha_ini),
             @w_fecha_fin = DATEADD(YEAR, @w_anio_reproceso + 1, @w_op_fecha_ini)
   end
   
   return 0
end
go
