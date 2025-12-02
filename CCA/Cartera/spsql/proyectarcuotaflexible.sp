/************************************************************************/
/*      Archivo:                proyectarcuotaflexible.sp               */
/*      Stored procedure:       sp_proyectar_cuota_flexible             */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     May. 2014                               */
/*      Nro. procedure          4                                       */
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
/*      Calcula los valores de los rubros de la tabla de amortización   */
/*      Flexible.                                                       */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-05-13     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go

--- SECCION:ERRORES no quitar esta seccion
delete cobis..cl_errores where numero between 70004001 and 70004999
go
   insert into cobis..cl_errores values(70004001, 0, 'Ocurrio un error tecnico calculando el interes corriente.')
   insert into cobis..cl_errores values(70004002, 0, 'Ocurrio un error tecnico calculando un concepto del servicio minimo de la deuda.')
   insert into cobis..cl_errores values(70004003, 0, 'Ocurrio un error al registrar el valor de comision MiPyME.')
   insert into cobis..cl_errores values(70004004, 0, 'Ocurrio un error al registrar el IVA de la comision MiPyME.')
   insert into cobis..cl_errores values(70004005, 0, 'Ocurrio un error en la generacion de la porcion de capital de pago flexible.')
go
--- FINSECCION:ERRORES no quitar esta seccion

if exists (select 1 from sysobjects where name = 'sp_proyectar_cuota_flexible')
   drop proc sp_proyectar_cuota_flexible
go

---NR000392
create proc sp_proyectar_cuota_flexible
   @i_debug                      char(1) = 'N',
   @i_operacion                  int,
   @i_op_toperacion              catalogo,
   @i_op_tipo                    char,
   @i_num_dec                    tinyint,
   @i_fecha_limite_fng           datetime,
   @i_nro_cuota                  smallint,
   @i_di_fecha_ven               datetime,
   @o_ubicacion_cuota_anio       tinyint OUTPUT, -- 1 es primera cuota del año, 2 es ultima cuota del año, otro valor no interesa
   @i_total_dias_anio_calculo    smallint,
   @i_dias_anio                  money, -- EL TIPO MONEY ES PARA EVITAR PROBLEMAS DE AUTOCONVERSION EN LOS CALCULOS
   @i_saldo_cap                  money,
   @i_causacion                  char,
   @i_dias_cuota                 smallint,
   @i_vlr_disponible             money,
   @i_vlr_mipyme_anual           money,
   @i_valor_INTTRAS_anterior     money,
   @i_parametro_segdeuven        catalogo,
   @i_parametro_segdeuem         catalogo,
   @i_cto_fng_vencido            catalogo,
   @i_cto_fng_iva                catalogo,
   @i_cto_mipyme                 catalogo,
   @i_cto_mipyme_iva             catalogo,
   @o_vlr_mipyme_anual           money  OUTPUT,
   @o_valor_INTTRAS_proximo      money  OUTPUT,
   @o_nuevo_saldo                money  OUTPUT,
   @o_es_valido                  bit    OUTPUT
as
declare
   @w_error                int,
   @w_rot_concepto         catalogo,
   @w_rot_tipo_rubro       char,
   @w_rot_porcentaje       float,
   @w_rot_valor            money,
   @w_rot_fpago            char,
   @w_rot_provisiona       char,
   @w_rot_saldo_op         char,
   @w_rot_saldo_insoluto   char,
   @w_rot_porcentaje_efa   float,
   @w_rot_num_dec          tinyint,
   @w_servicio_minimo      money,
   @w_valor_calc           money,
   @w_factor               int,
   @w_valor_para_seg       money,
   @w_valor_cuota_int      money,
   @w_concepto_base        catalogo,
   @w_valor_baser          money,
   @w_tasa_mipyme_iva      float,
   @w_vlr_mipyme_iva       money

begin
   if @i_debug = 'S'
      print '     Calcular los valores de la cuota ' + convert(varchar, @i_nro_cuota) + ' disponible ' + convert(varchar, @i_vlr_disponible)
   -- PRIMERO SE CALCULARA EL INTERES CORRIENTES
   -- SE REALIZA POR CURSOR POR MANTENER LA BAJISIMA POSIBILIDAD DE QUE HAYA MAS DE UN RUBRO DE INTERÉS
   select @w_valor_cuota_int = 0,
          @o_vlr_mipyme_anual = @i_vlr_mipyme_anual

   declare cur_interes cursor
   for select rot_concepto,            rot_tipo_rubro,      rot_porcentaje,
              rot_valor,               rot_fpago,           rot_provisiona,
              rot_saldo_op,            rot_saldo_insoluto,
              rot_porcentaje_cobrar,   rot_num_dec
       from   ca_rubro_op_tmp
       where  rot_operacion  = @i_operacion
       and    rot_fpago      in ('P', 'T') 
       and    rot_tipo_rubro in ('I') 
   for read only
   
   open cur_interes

   fetch cur_interes
   into  @w_rot_concepto,        @w_rot_tipo_rubro,      @w_rot_porcentaje,
         @w_rot_valor,           @w_rot_fpago,           @w_rot_provisiona,
         @w_rot_saldo_op,        @w_rot_saldo_insoluto,
         @w_rot_porcentaje_efa,  @w_rot_num_dec
   
   while @@fetch_status = 0
   begin
      if @w_rot_porcentaje_efa = 0 -- INTERES TOTAL 0
         select @w_valor_calc = 0
      else
      begin
         if @w_rot_fpago in ('P', 'T')
            select @w_rot_fpago = 'V'
            
         -- CALCULAR LA TASA EQUIVALENTE
         exec @w_error = sp_conversion_tasas_int
               @i_periodo_o       = 'A',
               @i_modalidad_o     = 'V',
               @i_num_periodo_o   = 1,
               @i_tasa_o          = @w_rot_porcentaje_efa,
               @i_periodo_d       = 'D',
               @i_modalidad_d     = @w_rot_fpago,
               @i_num_periodo_d   = @i_dias_cuota,
               @i_dias_anio       = @i_dias_anio,
               @i_num_dec         = @w_rot_num_dec,
               @o_tasa_d          = @w_rot_porcentaje output
            
         if @w_error != 0
            return @w_error
      
         exec @w_error = sp_calc_intereses
              @tasa          = @w_rot_porcentaje,
              @monto         = @i_saldo_cap,
              @dias_anio     = @i_dias_anio,
              @num_dias      = @i_dias_cuota,
              @causacion     = @i_causacion,
              @intereses     = @w_valor_calc out
            
         if @w_error != 0
            return @w_error
      end

      select @w_valor_calc = round(@w_valor_calc , @i_num_dec)

      if @i_debug = 'S'
         print '     INTERES por ' + convert(varchar, @w_valor_calc)
              + ', tasa efa=' + convert(varchar, @w_rot_porcentaje_efa)
              + ', tasa nom=' + convert(varchar, @w_rot_porcentaje)
              + ', dias=' + convert(varchar, @i_dias_cuota)

      insert into ca_amortizacion_tmp  with (rowlock)
            (amt_operacion,             amt_dividendo,             amt_concepto,
             amt_cuota,                 amt_gracia,                amt_pagado,
             amt_acumulado,             amt_estado,                amt_periodo,
             amt_secuencia)
      values(@i_operacion,              @i_nro_cuota,              @w_rot_concepto,
             @w_valor_calc,             0,                         0,
             0,                         0,                         0,
             1 )
      
      if (@@error <> 0)
         return 70004001 -- OCURRIÓ UN ERROR TECNICO CALCULANDO EL INTERES CORRIENTE

      select @w_valor_cuota_int = @w_valor_cuota_int + @w_valor_calc
      --
      fetch cur_interes
      into  @w_rot_concepto,        @w_rot_tipo_rubro,      @w_rot_porcentaje,
            @w_rot_valor,           @w_rot_fpago,           @w_rot_provisiona,
            @w_rot_saldo_op,        @w_rot_saldo_insoluto,
            @w_rot_porcentaje_efa,  @w_rot_num_dec
   end

   close cur_interes
   deallocate cur_interes
   
   -- SEGUNDO SE CALCULARAN LOS OTROS CONCEPTOS (SIN INCLUIR CAPITAL NI INTERES), ES DECIR, EL SERVICIO MINIMO DE LA DEUDA
   select @w_servicio_minimo = 0 -- EN EL CURSOR SE IRAN ACUMULANDO PARA VALIDAR SI LA CUOTA ES VÁLIDA

   declare cur_otros cursor
   for select rot_concepto,         rot_tipo_rubro,      rot_porcentaje,
              rot_valor,            rot_fpago,           'S', -- DE MANERA PREDETERMINADA SE PONE EN N PORQUE EN BMIA LOS OTROS CONCEPTOS CAUSAN PERO NO DIARIO
              rot_saldo_op,         rot_saldo_insoluto,
              rot_porcentaje_efa,   rot_num_dec
       from   ca_rubro_op_tmp
       where  rot_operacion  = @i_operacion
       and    rot_fpago      in ('P', 'T') 
       and    rot_tipo_rubro in ('V', 'Q', 'O') 
       and    rot_concepto not in (@i_cto_mipyme, @i_cto_mipyme_iva)
       order by rot_tipo_rubro desc
   for read only

   open  cur_otros
   
   fetch cur_otros
   into  @w_rot_concepto,        @w_rot_tipo_rubro,      @w_rot_porcentaje,
         @w_rot_valor,           @w_rot_fpago,           @w_rot_provisiona,
         @w_rot_saldo_op,        @w_rot_saldo_insoluto,
         @w_rot_porcentaje_efa,  @w_rot_num_dec
   
   while @@fetch_status = 0
   begin
      -- RUBROS DE TIPO PORCENTAJE, VALOR
      if @w_rot_tipo_rubro in ('V', 'O')      
      begin      
         select @w_valor_calc = round (@w_rot_valor, @i_num_dec)
      end
      
      -- RUBROS CALCULADOS
      ---EPB ABR-03-2003 - 2003
      ---CONVENIOS
      if @i_op_tipo = 'V' and not exists (select 1 from cob_credito..cr_corresp_sib where tabla  = 'T115' and codigo = @i_op_toperacion) 
      begin
         -- RUBROS CALCULADOS
         if (@w_rot_tipo_rubro = 'Q'  and @w_rot_saldo_op = 'S') or (@w_rot_tipo_rubro = 'Q'  and @w_rot_saldo_insoluto = 'S')
         begin
            ---EPB: EL valor inicial del rubro   para convenios se hace sobre cap + int
            ---     EL programa calsvid.sp lo recalcula para q que de un valor fijo
            select @w_valor_para_seg = @i_saldo_cap + @w_valor_cuota_int
            select @w_rot_valor = (@w_valor_para_seg * @w_rot_porcentaje / 100.0 / 360.0) * @i_dias_cuota
            select @w_valor_calc = round(@w_rot_valor, @i_num_dec)
         end
      end
      else
      begin  
         if @w_rot_tipo_rubro = 'Q'  and @w_rot_saldo_insoluto = 'S'         
         begin
            select @w_rot_valor = 0                                 --- se calculara en otro proceso
            select @w_valor_calc = round(@w_rot_valor, @i_num_dec)
         end  
         ELSE
         begin
            if @w_rot_tipo_rubro = 'Q' and @w_rot_saldo_op = 'S'
            begin
               if @w_rot_concepto in (@i_parametro_segdeuven, @i_parametro_segdeuem)
               begin
                  select @w_rot_porcentaje =  @w_rot_porcentaje * cast(@i_dias_cuota as float) / 30.0
               end
           
               select @w_rot_valor = @i_saldo_cap * @w_rot_porcentaje /100.0
               select @w_valor_calc = round(@w_rot_valor , @i_num_dec)
               
               IF @w_rot_concepto in (@i_cto_fng_vencido, @i_cto_fng_iva)
               begin
                  if @o_ubicacion_cuota_anio != 1 -- NO ES LA PRIMERA CUOTA DEL AÑO
                     select @w_valor_calc = 0
                  else
                  begin
                     if @i_debug = 'S'
                        print '     COMISION FNG @w_valor_calc = ' + convert(varchar, @w_valor_calc)
                            + ', dias ' + convert(varchar, @i_total_dias_anio_calculo)
                            + ', dias_anio ' + convert(varchar, @i_dias_anio)
                     select @w_valor_calc = @w_valor_calc * cast(@i_total_dias_anio_calculo as money) / cast(@i_dias_anio as money)
                  end
               end
            end
            ELSE
               if @w_rot_tipo_rubro = 'Q'      
               begin      
                  select @w_valor_calc = round(@w_rot_valor , @i_num_dec)
               end         
         end

         ---NR-293
         if  @w_rot_tipo_rubro = 'O'         
         begin         
            --NR-293
            select @w_concepto_base = rot_concepto_asociado
            from ca_rubro_op_tmp
            where rot_operacion = @i_operacion
            and   rot_concepto  = @w_rot_concepto

            select @w_valor_baser = 0
            select   @w_valor_baser = amt_cuota
            from ca_amortizacion_tmp
            where amt_operacion  = @i_operacion
            and   amt_dividendo  = @i_nro_cuota
            and   amt_concepto   = @w_concepto_base                  
            
            if @w_valor_baser > 0
               select @w_valor_calc = round(@w_valor_baser * @w_rot_porcentaje / 100,0)
            else
               select @w_valor_calc = 0
         end                    
      end
      
      if @w_rot_provisiona = 'S'
         select  @w_factor = 0
      else
         select  @w_factor = 1
      
      select @w_servicio_minimo = @w_servicio_minimo + @w_valor_calc
      
      -- INSERTAR EL RUBRO EN TABLA CA_AMORTIZACION_TMP
      if @i_debug = 'S' 
         print '     ' + convert(varchar, @w_rot_concepto) + ' por ' + convert(varchar, @w_valor_calc)
                      
      insert into ca_amortizacion_tmp  with (rowlock)
            (amt_operacion,             amt_dividendo,             amt_concepto,
             amt_cuota,                 amt_gracia,                amt_pagado,
             amt_acumulado,             amt_estado,                amt_periodo,
             amt_secuencia)
      values(@i_operacion,              @i_nro_cuota,              @w_rot_concepto,
             @w_valor_calc,             0,                         0,
             @w_valor_calc * @w_factor, 0,                         0,
             1)
      
      if (@@error <> 0)
         return 70004002 -- OCURRIÓ UN ERROR TECNICO CALCULANDO UN CONCEPTO DEL SERVICIO MÍNIMO DE LA DEUDA
      
      fetch cur_otros
      into  @w_rot_concepto,        @w_rot_tipo_rubro,      @w_rot_porcentaje,
            @w_rot_valor,           @w_rot_fpago,           @w_rot_provisiona,
            @w_rot_saldo_op,        @w_rot_saldo_insoluto,
            @w_rot_porcentaje_efa,  @w_rot_num_dec
   end -- WHILE CURSOR OTROS RUBROS
   
   close cur_otros
   deallocate cur_otros
   
   -- YA SE CONOCE EL SERVICIO MÍNIMO DE LA DEUDA, AHORA SE VA A VALIDAR QUE EL DISPONIBLE SEA SUFICIENTE PARA CUBRIRLO
   if @w_servicio_minimo > @i_vlr_disponible
   begin
      select @o_valor_INTTRAS_proximo = @i_valor_INTTRAS_anterior,
             @o_es_valido = 0
      if @i_debug = 'S' 
         print 'La cuota no es válida ' + convert(varchar, @w_servicio_minimo) + ' > ' + convert(varchar, @i_vlr_disponible) + ' : ' +convert(varchar, @o_es_valido)
   end
   else
      select @o_es_valido = 1

   select @o_ubicacion_cuota_anio = 0 -- SI ERA LA PRIMERA CUOTA, YA NO LO SERÁ MAS
   
   -- DESCONTAR EL SERVICIO MÍNIMO
   select @i_vlr_disponible = @i_vlr_disponible - @w_servicio_minimo -- DESCONTAR EL SERVICIO MINIMO

   -- AHORA, LA COMISIÓN MIPYME Y SU IVA
   -- SOLO SE CALCULARÁ SI QUEDAN POR LO MENOS 5 PESOS, YA QUE ES LO MÍNIMO CON LO QUE SE PUEDE CALCULAR
   -- COMISION E IVA EN LA MISMA CUOTA (4 PESOS DE COMISIÓN Y 1 DE IVA, MEJOR OPCION ES 14 PESOS, PERO VAMOS POR LO BAJO)
   if @i_vlr_disponible >= 5
   begin
      select @w_tasa_mipyme_iva = 0

      select @w_tasa_mipyme_iva = rot_porcentaje
      from   ca_rubro_op_tmp
      where  rot_concepto = @i_cto_mipyme_iva
   
      select @w_vlr_mipyme_iva = ROUND(@i_vlr_mipyme_anual * @w_tasa_mipyme_iva / 100.0, @i_num_dec)

      -- SI LA COMISIÓN Y SU IVA ES SUPERIOR AL DISPONIBLE RECALCULARÁ LA COMISIÓN E IVA PARA QUE QUEPA EN EL DISPONIBLE
      if @i_vlr_disponible < (@i_vlr_mipyme_anual + @w_vlr_mipyme_iva)
      begin
         select @i_vlr_mipyme_anual = ROUND(@i_vlr_disponible / (1.0 + @w_tasa_mipyme_iva /100.0)- 0.5, @i_num_dec)
         select @w_vlr_mipyme_iva = ROUND(@i_vlr_mipyme_anual * @w_tasa_mipyme_iva / 100.0, @i_num_dec)
      end

      if @i_debug = 'S'
      begin
         print '     ' + convert(varchar, @i_cto_mipyme) + ' por ' + convert(varchar, @i_vlr_mipyme_anual) + ', disponible = ' + convert(varchar, @i_vlr_disponible)
      end

      insert into ca_amortizacion_tmp
            (amt_operacion,             amt_dividendo,             amt_concepto,
             amt_cuota,                 amt_gracia,                amt_pagado,
             amt_acumulado,             amt_estado,                amt_periodo,
             amt_secuencia)
      select @i_operacion,              @i_nro_cuota,              rot_concepto,
             @i_vlr_mipyme_anual,       0,                         0,
             0,                         0,                         0,   -- DE MANERA PREDETERMINADA SE PONE EN CERO EL ACUMULADO PORQUE EN BMIA LOS OTROS CONCEPTOS CAUSAN PERO NO DIARIO
             1
      from   ca_rubro_op_tmp
      where  rot_operacion = @i_operacion
      and    rot_concepto = @i_cto_mipyme

      if @@error != 0
      begin
         return 70004003 -- OCURRIÓ UN ERROR AL REGISTRAR EL VALOR DE LA COMISIÓN MIPYME
      end

      if @i_debug = 'S' 
         print '     ' + convert(varchar, @i_cto_mipyme_iva) + ' por ' + convert(varchar, @w_vlr_mipyme_iva)

      insert into ca_amortizacion_tmp
            (amt_operacion,             amt_dividendo,             amt_concepto,
             amt_cuota,                 amt_gracia,                amt_pagado,
             amt_acumulado,             amt_estado,                amt_periodo,
             amt_secuencia)
      select @i_operacion,              @i_nro_cuota,              rot_concepto,
             @w_vlr_mipyme_iva,         0,                         0,
             0,                         0,                         0, -- DE MANERA PREDETERMINADA SE PONE EN CERO EL ACUMULADO PORQUE EN BMIA LOS OTROS CONCEPTOS CAUSAN PERO NO DIARIO
             1
      from   ca_rubro_op_tmp
      where  rot_operacion = @i_operacion
      and    rot_concepto = @i_cto_mipyme_iva

      if @@error != 0
      begin
         return 70004004 -- OCURRIÓ UN ERROR AL REGISTRAR EL IVA DE LA COMISIÓN MIPYME
      end

      select @o_vlr_mipyme_anual = @o_vlr_mipyme_anual - @i_vlr_mipyme_anual

      select @i_vlr_disponible = @i_vlr_disponible - @i_vlr_mipyme_anual - @w_vlr_mipyme_iva
   end

   -- AHORA, FINALMENTE EL CAPITAL, QUE SERÁ LO QUE QUEDE DEL DISPONIBLE
   select @w_valor_calc = 0

   ---
   select @o_valor_INTTRAS_proximo = 0

   if @i_debug = 'S'
      print '     Intereses que vienen ' + convert(varchar, @i_valor_INTTRAS_anterior)
          + ' vs nuevo disponible ' + convert(varchar, @i_vlr_disponible)

   -- DESCONTAR EL INTERES TRASLADADO TEÓRICO
   if @i_vlr_disponible < @i_valor_INTTRAS_anterior
   begin
      select @o_valor_INTTRAS_proximo = @o_valor_INTTRAS_proximo + (@i_valor_INTTRAS_anterior - @i_vlr_disponible)
      select @i_vlr_disponible = 0
   end
   else
   begin
      select @i_vlr_disponible = @i_vlr_disponible - @i_valor_INTTRAS_anterior
   end

   -- DESCONTAR EL INTERES
   if @i_debug = 'S'
      print '     Intereses ' + convert(varchar, @w_valor_cuota_int)

   if @i_vlr_disponible < @w_valor_cuota_int
   begin
      select @o_valor_INTTRAS_proximo = @o_valor_INTTRAS_proximo + (@w_valor_cuota_int - @i_vlr_disponible)
      select @i_vlr_disponible = 0
   end
   else
   begin
      select @i_vlr_disponible = @i_vlr_disponible - @w_valor_cuota_int
   end
   if @i_debug = 'S'
      print '     Quedaran pendientes ' + convert(varchar, @o_valor_INTTRAS_proximo)
          + ' Y nuevo disponible ' + convert(varchar, @i_vlr_disponible)
   

   select @w_valor_calc = @i_vlr_disponible
   
   if @w_valor_calc > @i_saldo_cap
      select @w_valor_calc = @i_saldo_cap

   if @i_debug = 'S'
      print '     CAP por ' + convert(varchar, @w_valor_calc)

   insert into ca_amortizacion_tmp  with (rowlock)
         (amt_operacion,             amt_dividendo,             amt_concepto,
          amt_cuota,                 amt_gracia,                amt_pagado,
          amt_acumulado,             amt_estado,                amt_periodo,
          amt_secuencia)
   select @i_operacion,              @i_nro_cuota,              rot_concepto,
          @w_valor_calc,             0,                         0,
          @w_valor_calc,             0,                         0,
          1
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacion
   and    rot_tipo_rubro = 'C'

   if @@ROWCOUNT = 0 or @@ERROR != 0
      return 70004005 -- OCURRIÓ UN ERROR EN LA GENERACIÓN DE LA PORCION DE CAPITAL DEL PAGO FLEXIBLE
   
   select @o_nuevo_saldo = @i_saldo_cap - @w_valor_calc
   return 0
end
go

