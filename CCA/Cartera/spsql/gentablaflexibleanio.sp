/************************************************************************/
/*      Archivo:                gentablaflexanio.sp                     */
/*      Stored procedure:       sp_gentabla_flexible_anio               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          2                                       */
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
/*      Genera la tabla de amortizacion FLEXIBLE para un año.           */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-05-13     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
delete cobis..cl_errores where numero between 70002001 and 70002999
go
   insert into cobis..cl_errores values(70002001, 0, 'No cumple condiciones: El numero de disponibles por anio no alcanza el minimo requerido.')
   insert into cobis..cl_errores values(70002003, 0, 'No cumple condiciones: El numero de dias entre disponibles supera el maximo permitido.')
   insert into cobis..cl_errores values(70002004, 0, 'No cumple condiciones: Flujo no alcanza para cubrir el capital de la deuda.')
   insert into cobis..cl_errores values(70002005, 0, 'No cumple condiciones: Flujo no alcanza para cubrir comision Mipyme de alguno de los anios.')
   insert into cobis..cl_errores values(70002006, 0, 'No cumple condiciones: Flujo no alcanza para cubrir intereses requeridos en algun anio')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_gentabla_flexible_anio')
   drop proc sp_gentabla_flexible_anio
go

---NR000392
create proc sp_gentabla_flexible_anio
   @i_debug                char(1) = 'N',
   @i_operacion            int,
   @i_capital_financiar    money,
   @i_fecha_ini_anio       datetime,
   @i_fecha_fin_anio       datetime,
   @i_nro_ult_cuota        smallint,
   @i_num_dec              tinyint,

   @i_op_dia_fijo          smallint,
   @i_op_toperacion        catalogo,
   @i_op_tipo              char,
   @i_fecha_limite_fng     datetime,
   @i_op_dias_anio         smallint, -- EL TIPO MONEY ES PARA EVITAR PROBLEMAS DE AUTOCONVERSION EN LOS CALCULOS
   @i_op_causacion         char,
   @i_parametro_segdeuven  catalogo,
   @i_parametro_segdeuem   catalogo,
   @i_cto_fng_vencido      catalogo,
   @i_cto_fng_iva          catalogo,
   @i_cto_mipyme           catalogo,
   @i_cto_mipyme_iva       catalogo,
   @i_max_dias_cuota       smallint,
   @i_min_cuotas_anio      smallint,
   @i_min_dias_cuotas      tinyint,
   @i_ubicacion_cuota_anio tinyint,
   @i_proporcion_deuda     float,

   @o_saldo_anio           money    OUTPUT,
   @o_control_fecha_fin    tinyint  OUTPUT
as
declare
   @w_error                      int,
   @w_nro_disponibles_anio       smallint,
   @w_fecha_disponible_ini       datetime,
   @w_fecha_disponible_fin       datetime,

   @w_saldo                      money,
   @w_vlr_mipyme_anual           money,
   @w_cuotas_asignadas           smallint,

   @w_fecha_ini_cuota            datetime,
   @w_fecha_fin_cuota            datetime,
   @w_nro_cuota                  smallint,

   @w_dt_fecha                   datetime,
   @w_dt_valor_disponible        money,

   @w_vlr_mipyme_cuota           money,
   @w_dias_cuota                 smallint,
   @w_total_dias_anio_calculo    smallint,
   @w_valorINTTRAS_anterior      money,
   @w_valor_INTTRAS_proximo      money,
   @w_es_valido                  bit,
   @w_fecha_ult_disponible       datetime,
   @w_tasa_mp                    float

begin
   select @w_valorINTTRAS_anterior  = 0,   -- CADA AÑO INICIA SIN TRASLADOS
          @w_valor_INTTRAS_proximo  = 0,
          @o_control_fecha_fin      = 0

   select @w_fecha_ult_disponible = max(dt_fecha)
   from   cob_credito..cr_disponibles_tramite
   where  dt_operacion_cca = @i_operacion

   exec @w_error = sp_buscar_disponibles_anio
        @i_operacion               = @i_operacion,
        @i_fecha_ini_anio          = @i_fecha_ini_anio,
        @o_fecha_fin_anio          = @i_fecha_fin_anio         OUTPUT,
        @o_nro_disponibles_anio    = @w_nro_disponibles_anio   OUTPUT,
        @o_fecha_disponible_ini    = @w_fecha_disponible_ini   OUTPUT,
        @o_fecha_disponible_fin    = @w_fecha_disponible_fin   OUTPUT
   
   if @w_error != 0
      return @w_error

   exec @w_error = sp_dias_cuota_360
        @i_fecha_ini = @i_fecha_ini_anio,
        @i_fecha_fin = @i_fecha_fin_anio,
        @o_dias      = @w_total_dias_anio_calculo OUTPUT

   if @w_error != 0
      return @w_error

   if @i_debug = 'S'
      print 'Este año queda de ' + convert(varchar, @i_fecha_ini_anio, 111)
          + ' a ' + convert(varchar, @i_fecha_fin_anio, 111)
          + ', días ' + convert(varchar, @w_total_dias_anio_calculo)

   select @i_min_cuotas_anio = @i_min_cuotas_anio * @w_total_dias_anio_calculo / 360

   if @i_debug = 'S' 
      print  '1a consulta disponibles ' + convert(varchar, @w_nro_disponibles_anio)
      + ' desde ' + convert(varchar, @w_fecha_disponible_ini, 111) + ' - ' +  convert(varchar, @w_fecha_disponible_fin, 111)
      + ' / ' + convert(varchar, @i_min_cuotas_anio)

   if @w_nro_disponibles_anio < @i_min_cuotas_anio
   begin
      if @w_nro_disponibles_anio = 0
      begin
         if @i_debug = 'S'
            print '   Activar el control de fin de anio prematuro (' + convert(varchar, @i_fecha_ini_anio, 111)  + '-' + convert(varchar, @i_fecha_fin_anio, 111) + ') '
                  + ' por falta de disponibles'
         select @o_control_fecha_fin = 1,
                @o_saldo_anio = @i_capital_financiar
         return 0
      end
      else
      begin
         if @i_debug = 'S'
            print 'flujos del año (' + convert(varchar, @i_fecha_ini_anio, 111)  + '-' + convert(varchar, @i_fecha_fin_anio, 111) + ')  son insuficientes ' + convert(varchar, @w_nro_disponibles_anio)
         return 70002001 -- LOS FLUJOS DISPONIBLES PARA UN AÑO NO ALCANZAN EL MINIMO DE CUOTAS AL AÑO
      end
   end

   select @w_saldo = @i_capital_financiar
   
   select @w_saldo = @i_capital_financiar - isnull(sum(amt_cuota), 0)
   from   ca_amortizacion_tmp
   inner  join ca_rubro_op_tmp on rot_operacion = amt_operacion and rot_concepto = amt_concepto
   where  amt_operacion = @i_operacion
   and    rot_tipo_rubro = 'C'
      
   -- BORRAR LOS REGISTROS QUE HAYAN SIDO GENERADOS
   delete ca_amortizacion_tmp
   where  amt_operacion = @i_operacion
   and    amt_dividendo > @i_nro_ult_cuota

   delete ca_dividendo_tmp
   where  dit_operacion = @i_operacion
   and    dit_dividendo > @i_nro_ult_cuota

   update cob_credito..cr_disponibles_tramite
   set    dt_valido = 'S'
   where  dt_operacion_cca =  @i_operacion
   and    dt_fecha between @i_fecha_ini_anio and @i_fecha_ini_anio
   and    dt_valor_disponible > 0

   if @i_debug = 'S' 
      print ' Iniciando anio con saldo: ' + convert(varchar, @w_saldo)

   --while (@w_saldo > 0) AND (@w_vlr_mipyme_anual > 0) -- Ciclo de intentos
   begin
      -- CALCULAR EL VALOR DE PYME ANUAL
      select @w_vlr_mipyme_anual = 0

      select @w_tasa_mp  = rot_porcentaje
      from   ca_rubro_op_tmp
      where  rot_operacion = @i_operacion
      and    rot_concepto  = @i_cto_mipyme

      if @i_debug = 'S'
         print 'tasa mipyme ' + convert(varchar, @w_tasa_mp)
            + ', saldo ' + convert(varchar, @w_saldo)
            + ', proporcion ' + convert(varchar, @i_proporcion_deuda)
      
      select @w_vlr_mipyme_anual  = round((@w_saldo * @i_proporcion_deuda) * rot_porcentaje / 100.0 
                                           * cast(@w_total_dias_anio_calculo as money) / cast(@i_op_dias_anio as money), @i_num_dec)
      from   ca_rubro_op_tmp
      where  rot_operacion = @i_operacion
      and    rot_concepto  = @i_cto_mipyme

      if @i_debug = 'S'
         print 'Para este año el valor de pyme del año es ' + convert(varchar, @w_vlr_mipyme_anual)

      select @w_cuotas_asignadas = 0

      if @i_nro_ult_cuota > 0 
      begin
         select @w_fecha_ini_cuota = MAX(dit_fecha_ven)
         from   ca_dividendo_tmp
         where  dit_operacion = @i_operacion
      end
      else
      begin
         select @w_fecha_ini_cuota = opt_fecha_ini
         from   ca_operacion_tmp
         where  opt_operacion = @i_operacion
      end

      if @i_debug = 'S' 
         print '>>>>>BUSCAR DISPONIBLES EN FECHAS: ' + convert(varchar, @w_fecha_disponible_ini, 111) + ' con ' + convert(varchar, @w_fecha_disponible_fin, 111)

      select @w_nro_cuota = @i_nro_ult_cuota

      declare cur_disponibles cursor
      for select dt_fecha, dt_valor_disponible
            from   cob_credito..cr_disponibles_tramite
            where  dt_operacion_cca = @i_operacion
            and    dt_fecha >= @w_fecha_disponible_ini and dt_fecha <= @w_fecha_disponible_fin
            and    dt_valor_disponible > 0
            order  by dt_fecha
      FOR READ ONLY

      open cur_disponibles

      fetch cur_disponibles into @w_dt_fecha, @w_dt_valor_disponible

      while @@FETCH_STATUS = 0
      begin
         select @w_fecha_fin_cuota = @w_dt_fecha

         if @i_debug = 'S' 
            print 'INTENTANDO CON EL DISPONIBLE: ' + convert(varchar, @w_dt_fecha, 111) + ' con ' + convert(varchar, @w_dt_valor_disponible)

         update cob_credito..cr_disponibles_tramite
         set    dt_dividendo  = 0
         where  dt_operacion_cca =  @i_operacion
         and    dt_fecha = @w_dt_fecha

         select @w_nro_cuota = @w_nro_cuota + 1

         select @w_cuotas_asignadas = @w_cuotas_asignadas + 1

         select @w_vlr_mipyme_cuota = 0

         exec @w_error = sp_dias_cuota_360
               @i_fecha_ini = @w_fecha_ini_cuota,
               @i_fecha_fin = @w_fecha_fin_cuota,
               @o_dias = @w_dias_cuota OUTPUT
            
         if @w_error != 0
            return @w_error

         if @w_dias_cuota < @i_min_dias_cuotas -- LAS CUOTAS TIENEN DEBEN SER POR LO MENOS DE UNA CANTIDAD PARAMETRIZADA DE DÍAS
         begin
            select @w_nro_cuota = @w_nro_cuota - 1,
                   @w_cuotas_asignadas = @w_cuotas_asignadas - 1
            fetch cur_disponibles into @w_dt_fecha, @w_dt_valor_disponible
            continue
         end

         if @w_dias_cuota > @i_max_dias_cuota or @w_dias_cuota < 0
         begin
            select @w_cuotas_asignadas = @w_cuotas_asignadas - 1,
                     @w_nro_cuota = @w_nro_cuota - 1

            delete ca_amortizacion_tmp
            where  amt_operacion = @i_operacion
            and    amt_dividendo > @w_nro_cuota

            delete ca_dividendo_tmp
            where  dit_operacion = @i_operacion
            and    dit_dividendo > @w_nro_cuota

            if @i_debug = 'S' 
               print 'error de los dias de cuota ' + convert(varchar, @w_fecha_ini_cuota, 111) + ' -> ' + convert(varchar, @w_fecha_fin_cuota, 111) +
                  ' dias= ' +  convert(varchar, @w_dias_cuota) + ' max= ' + convert(varchar, @i_max_dias_cuota) 
                  + ' vr disponible=' + convert(varchar, @w_dt_valor_disponible)

            return 70002003 -- DIAS DE CUOTA DE PAGO FLEXIBLE SE EXCEDE DE LAS POLITICAS
         end

         if @i_debug = 'S' 
            print 'Crear la cuota nro ' + convert(varchar, @w_nro_cuota)
               + ' desde ' + convert(varchar, @w_fecha_ini_cuota, 111) + ' hasta ' +convert(varchar, @w_fecha_fin_cuota, 111)
               + ' dias ' + convert(varchar, @w_dias_cuota)
            
         insert into ca_dividendo_tmp
               (
               dit_operacion,    dit_dividendo,
               dit_fecha_ini,    dit_fecha_ven,
               dit_de_capital,   dit_de_interes,
               dit_gracia,       dit_gracia_disp,
               dit_estado,
               dit_dias_cuota,
               dit_intento,      dit_prorroga,     dit_fecha_can)
         values(@i_operacion,     @w_nro_cuota,
               @w_fecha_ini_cuota,  @w_fecha_fin_cuota,
               'S',                 'S',
               0,                   0,
               0,
               @w_dias_cuota,
               0,                   0,                   cast('01/01/1900' as datetime))
         --
         select @w_es_valido = 0

         if @i_debug = 'S' 
            print 'Cuotas asignadas antes de proyectar: ' + convert(varchar, @w_cuotas_asignadas)

         exec @w_error = sp_proyectar_cuota_flexible
               @i_debug                      = @i_debug,
               @i_operacion                  = @i_operacion,
               @i_op_toperacion              = @i_op_toperacion,
               @i_op_tipo                    = @i_op_tipo,
               @i_num_dec                    = @i_num_dec,
               @i_fecha_limite_fng           = @i_fecha_limite_fng,
               @i_nro_cuota                  = @w_nro_cuota,
               @i_di_fecha_ven               = @w_fecha_fin_cuota,
               @o_ubicacion_cuota_anio       = @i_ubicacion_cuota_anio OUTPUT, -- 1 es primera cuota del año, 2 es ultima cuota del año, otro valor no interesa
               @i_total_dias_anio_calculo    = @w_total_dias_anio_calculo,
               @i_dias_anio                  = @i_op_dias_anio, -- EL TIPO MONEY ES PARA EVITAR PROBLEMAS DE AUTOCONVERSION EN LOS CALCULOS
               @i_saldo_cap                  = @w_saldo,
               @i_causacion                  = @i_op_causacion,
               @i_dias_cuota                 = @w_dias_cuota,
               @i_vlr_disponible             = @w_dt_valor_disponible,
               @i_vlr_mipyme_anual           = @w_vlr_mipyme_anual,
               @i_valor_INTTRAS_anterior     = @w_valorINTTRAS_anterior,
               @i_parametro_segdeuven        = @i_parametro_segdeuven,
               @i_parametro_segdeuem         = @i_parametro_segdeuem,
               @i_cto_fng_vencido            = @i_cto_fng_vencido,
               @i_cto_fng_iva                = @i_cto_fng_iva,
               @i_cto_mipyme                 = @i_cto_mipyme,
               @i_cto_mipyme_iva             = @i_cto_mipyme_iva,
               @o_vlr_mipyme_anual           = @w_vlr_mipyme_anual       OUTPUT,
               @o_valor_INTTRAS_proximo      = @w_valor_INTTRAS_proximo  OUTPUT,
               @o_nuevo_saldo                = @w_saldo                  OUTPUT,
               @o_es_valido                  = @w_es_valido              OUTPUT

         if @w_error != 0
            return @w_error
            
         if  @w_fecha_ult_disponible = @w_fecha_fin_cuota -- ESTA CUOTA CORRESPONDE AL ÚLTIMO DISPONIBLE
         and @w_saldo > 0
         begin
            if @i_debug = 'S'
               print 'SE ALCANZO EL ULTIMO DISPONIBLE PERO NO SE CANCELA TODO EL CAPITAL'
            return 70002004 -- SE ALCANZO EL ULTIMO DISPONIBLE PERO NO SE CANCELA TODO EL CAPITAL
         end

         if @w_saldo = 0 and @w_fecha_fin_cuota < @i_fecha_fin_anio
         begin
            if @i_debug = 'S'
               print '   Activar el control de fin de anio prematuro (' + convert(varchar, @i_fecha_ini_anio, 111)  + '-' + convert(varchar, @i_fecha_fin_anio, 111) + ') '
                     + ' por extinción de saldo'
            select @o_control_fecha_fin = 2,
                   @o_saldo_anio = @i_capital_financiar

            return 0
         end

         if @w_es_valido = 1
         begin
            select @w_fecha_ini_cuota = @w_fecha_fin_cuota

            update cob_credito..cr_disponibles_tramite
            set    dt_dividendo     = @w_nro_cuota
            where  dt_operacion_cca =  @i_operacion
            and    dt_fecha         = @w_dt_fecha
               
            -- Si se acaba el capital antes del la fecha proyectada de fin de año corrido
            if @w_saldo = 0 and @i_fecha_fin_anio > @w_dt_fecha
            begin
               update cob_credito..cr_disponibles_tramite
               set    dt_dividendo  = 0
               where  dt_operacion_cca =  @i_operacion
               and    dt_fecha = @w_dt_fecha

               -- Reducir la busqueda de años
               select @i_fecha_fin_anio = @w_dt_fecha
               exec sp_buscar_disponibles_anio 
                     @i_operacion             = @i_operacion,
                     @i_fecha_ini_anio        = @i_fecha_ini_anio,
                     @o_fecha_fin_anio        = @i_fecha_fin_anio        OUTPUT,
                     @o_nro_disponibles_anio  = @w_nro_disponibles_anio  OUTPUT,
                     @o_fecha_disponible_ini  = @w_fecha_disponible_ini  OUTPUT,
                     @o_fecha_disponible_fin  = @w_fecha_disponible_fin  OUTPUT
               break
            end

            select @w_valorINTTRAS_anterior = @w_valor_INTTRAS_proximo
         end
         ELSE
         begin
            delete ca_amortizacion_tmp
            where  amt_operacion = @i_operacion
            and    amt_dividendo = @w_nro_cuota

            delete ca_dividendo_tmp
            where  dit_operacion = @i_operacion
            and    dit_dividendo = @w_nro_cuota
            
            select @w_cuotas_asignadas = @w_cuotas_asignadas - 1,
                                 @w_nro_cuota = @w_nro_cuota - 1

            if @i_debug = 'S' 
               print 'Pero no es válido, asignadas: ' + convert(varchar, @w_cuotas_asignadas)
         end

         fetch cur_disponibles into @w_dt_fecha, @w_dt_valor_disponible
      end -- FIN CURSOR DE DISPONIBLES

      close cur_disponibles
      deallocate cur_disponibles

      if @w_vlr_mipyme_anual > 0
      begin
         if @i_debug = 'S'
            print '  Fin Barrido de disponibles del anio, quedo saldo de ' + convert(varchar, @w_saldo) + ', y pyme anual ' + convert(varchar, @w_vlr_mipyme_anual)
         return 70002005 -- NO ALCANZA A PAGAR EL VALOR MIPYME EN EL AÑO
      end

      if @i_debug = 'S'
         print '  Contador de cuotas ' + convert(varchar, @w_cuotas_asignadas) + ', vs ' + convert(varchar, @i_min_cuotas_anio)
      if @w_cuotas_asignadas < @i_min_cuotas_anio
      begin
         if @i_debug = 'S'
            print '  Fin Barrido de disponibles del anio, quedo saldo de ' + convert(varchar, @w_saldo) + ', y pyme anual ' + convert(varchar, @w_vlr_mipyme_anual)
         return 70002001 -- LOS FLUJOS DISPONIBLES PARA UN AÑO NO ALCANZAN EL MINIMO DE CUOTAS AL AÑO
      end

      update cob_credito..cr_disponibles_tramite
      set    dt_valido = 'N'
      where  dt_operacion_cca =  @i_operacion
      and    dt_dividendo     =  @w_nro_cuota
      
      if @w_valor_INTTRAS_proximo > 0
      begin
         if @i_debug = 'S'
            print 'Ultima cuota del año no es válida, pasaría el siguiente saldo de interes a la siguiente cuota: '
               +  convert(varchar, @w_valor_INTTRAS_proximo)
         return 70002006
      end
   end

   select @o_saldo_anio = @w_saldo
   return 0

end
go
