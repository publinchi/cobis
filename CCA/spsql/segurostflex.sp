/************************************************************************/
/*      Archivo:                segurostflex.sp                         */
/*      Stored procedure:       sp_seguros_tflexible                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero                         */
/*      Fecha de escritura:     Jul. 2014                               */
/*      Nro. procedure          7                                       */
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
/*      Genera la tabla de seguros de las tablas flexibles.             */
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-05-13     Fabian Q.      REQ 392 - Pagos Flexibles - BMIA  */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_seguros_tflexible')
   drop proc sp_seguros_tflexible
go

---NR000392
create proc sp_seguros_tflexible
   @i_debug             char(1) = 'N',
   @i_operacionca       int,
   @i_tramite           int,
   @i_saldo_cap         money,
   @i_num_dec           smallint,
   @i_dias_anio         smallint,
   @i_causacion         char(1),
   @i_cuales_tablas     char(1)  = 'T',
   @o_msg_msv           varchar(255) = null out
as
declare
   @w_error             int,
   @w_sec_seguro        int,
   @w_tipo_seguro       int,
   @w_tipo_asegurado    int,
   @w_vr_seguro         money,
   @w_tasa_seguro       float,

   @w_dit_dividendo     smallint,
   @w_dit_fecha_ven     datetime,
   @w_dit_dias_cuota    smallint,

   @w_tasa_nominal      float,
   @w_valor_cap         money,
   @w_valor_cap_pag     money,
   @w_valor_int         money,
   @w_valor_int_pag     money,
   @w_proporcion_cap    float,
   @w_ult_dividendo     int
begin
   select @w_ult_dividendo = 0
   begin try
      delete ca_seguros
      where  se_tramite = @i_tramite

      select @w_error = 70007001
      insert into ca_seguros
            (se_sec_seguro,         se_tipo_seguro, se_sec_renovacion, se_tramite,     se_operacion,    se_fec_devolucion,   se_mto_devolucion,   se_estado)
      select st_secuencial_seguro,  st_tipo_seguro, 0,                 @i_tramite,     @i_operacionca,  NULL,                NULL,                'I'
      from   cob_credito..cr_seguros_tramite
      where  st_tramite = @i_tramite
   
      delete ca_seguros_det
      where  sed_operacion = @i_operacionca

      declare
         cur_asegurados cursor
         for select sed_sec_seguro = st_secuencial_seguro,
                    st_tipo_seguro,
                    sed_tipo_asegurado = as_tipo_aseg,
                    isnull(ps_valor_mensual,0) * isnull(datediff(MONTH,as_fecha_ini_cobertura,as_fecha_fin_cobertura), 0) as vr_seguro,
                    isnull(ps_tasa_efa, 0) as tasa_efa
             from  cob_credito..cr_seguros_tramite with (nolock),
                   cob_credito..cr_asegurados      with (nolock),
                   cob_credito..cr_plan_seguros_vs with (nolock)
             where st_tramite           = @i_tramite
             and   st_secuencial_seguro = as_secuencial_seguro
             and   as_plan              = ps_codigo_plan
             and   st_tipo_seguro       = ps_tipo_seguro
             and   ps_estado            = 'V'      
             and   as_tipo_aseg         = (case when ps_tipo_seguro in(2, 3, 4) then 1 else as_tipo_aseg end)

      open cur_asegurados

      fetch cur_asegurados
      into     @w_sec_seguro, @w_tipo_seguro, @w_tipo_asegurado, @w_vr_seguro, @w_tasa_seguro

      while @@FETCH_STATUS = 0
      begin
         select @w_proporcion_cap = cast(@w_vr_seguro as float) / cast(@i_saldo_cap as float)

         if @i_cuales_tablas = 'T'
            declare
               cur_dividendo  cursor
               for select dit_dividendo, dit_fecha_ven, dit_dias_cuota
                   from   ca_dividendo_tmp
                   where  dit_operacion = @i_operacionca
                   order  by dit_dividendo
         else
            declare
               cur_dividendo  cursor
               for select di_dividendo, di_fecha_ven, di_dias_cuota
                   from   ca_dividendo
                   where  di_operacion = @i_operacionca
                   order  by di_dividendo

         open cur_dividendo

         fetch cur_dividendo
         into  @w_dit_dividendo, @w_dit_fecha_ven, @w_dit_dias_cuota

         while @@FETCH_STATUS = 0
         begin
            -- CALCULAR LA TASA EQUIVALENTE
            exec @w_error = sp_conversion_tasas_int
                  @i_periodo_o       = 'A',
                  @i_modalidad_o     = 'V',
                  @i_num_periodo_o   = 1,
                  @i_tasa_o          = @w_tasa_seguro,
                  @i_periodo_d       = 'D',
                  @i_modalidad_d     = 'V',
                  @i_num_periodo_d   = @w_dit_dias_cuota,
                  @i_dias_anio       = @i_dias_anio,
                  @i_num_dec         = 4,
                  @o_tasa_d          = @w_tasa_nominal output
            
            if @w_error != 0
               return @w_error
            
            exec @w_error = sp_calc_intereses
                 @tasa          = @w_tasa_nominal,
                 @monto         = @w_vr_seguro,
                 @dias_anio     = @i_dias_anio,
                 @num_dias      = @w_dit_dias_cuota,
                 @causacion     = @i_causacion,
                 @intereses     = @w_valor_int OUTPUT
            
            if @w_error != 0
               return @w_error
            
            select @w_valor_int = round(@w_valor_int, @i_num_dec)

            if @i_cuales_tablas = 'T'
               select @w_valor_cap     = round(amt_cuota  * @w_proporcion_cap, @i_num_dec),
                      @w_valor_cap_pag = round(amt_pagado * @w_proporcion_cap, @i_num_dec)
               from   ca_amortizacion_tmp, ca_rubro_op_tmp
               where  rot_operacion = @i_operacionca
               and    rot_tipo_rubro = 'C'
               and    amt_operacion = @i_operacionca
               and    amt_dividendo = @w_dit_dividendo
               and    amt_concepto  = rot_concepto
            else
               select @w_valor_cap = round(am_cuota * @w_proporcion_cap, @i_num_dec),
                      @w_valor_cap_pag = round(am_pagado * @w_proporcion_cap, @i_num_dec)
               from   ca_amortizacion, ca_rubro_op
               where  ro_operacion = @i_operacionca
               and    ro_tipo_rubro = 'C'
               and    am_operacion = @i_operacionca
               and    am_dividendo = @w_dit_dividendo
               and    am_concepto  = ro_concepto

            select @w_valor_int_pag = 0
            if @i_cuales_tablas = 'T'
               select @w_valor_int_pag = round(@w_valor_int * cast(amt_cuota as float) / amt_pagado, @i_num_dec)
               from   ca_amortizacion_tmp, ca_rubro_op_tmp
               where  rot_operacion = @i_operacionca
               and    rot_tipo_rubro = 'I'
               and    amt_operacion = @i_operacionca
               and    amt_dividendo = @w_dit_dividendo
               and    amt_concepto  = rot_concepto
               and    amt_pagado > 0
            else
               select @w_valor_int_pag = round(@w_valor_int * cast(am_cuota as float) / am_pagado, @i_num_dec)
               from   ca_amortizacion, ca_rubro_op
               where  ro_operacion = @i_operacionca
               and    ro_tipo_rubro = 'I'
               and    am_operacion = @i_operacionca
               and    am_dividendo = @w_dit_dividendo
               and    am_concepto  = ro_concepto
               and    am_pagado > 0

            select @w_error = 70007001
            insert into ca_seguros_det
                  (sed_operacion,      sed_sec_seguro,      sed_tipo_seguro,
                   sed_sec_renovacion, sed_tipo_asegurado,  sed_estado,
                   sed_dividendo,      sed_cuota_cap,       sed_pago_cap,
                   sed_cuota_int,      sed_pago_int,        sed_cuota_mora,
                   sed_pago_mora)
            values(@i_operacionca,     @w_sec_seguro,       @w_tipo_seguro,
                   0,                  @w_tipo_asegurado,   1,
                   @w_dit_dividendo,   @w_valor_cap,        @w_valor_cap_pag,
                   @w_valor_int,       @w_valor_int_pag,    0,
                   0)

            select @w_vr_seguro = @w_vr_seguro - @w_valor_cap,
                   @w_ult_dividendo = @w_dit_dividendo
            --
            fetch cur_dividendo
            into  @w_dit_dividendo, @w_dit_fecha_ven, @w_dit_dias_cuota
         end

         close cur_dividendo
         deallocate cur_dividendo

         -- AJUSTE POR REDONDEOS
         update ca_seguros_det
         set    sed_cuota_cap    = sed_cuota_cap + @w_vr_seguro
         where  sed_operacion       = @i_operacionca
         and    sed_sec_seguro      = @w_sec_seguro
         and    sed_tipo_seguro     = @w_tipo_seguro
         and    sed_tipo_asegurado  = @w_tipo_asegurado
         and    sed_dividendo       = @w_ult_dividendo
         --
         fetch cur_asegurados
         into     @w_sec_seguro, @w_tipo_seguro, @w_tipo_asegurado, @w_vr_seguro, @w_tasa_seguro
      end

      close cur_asegurados
      deallocate cur_asegurados
   end try
   begin catch
      return @w_error
   end catch
end
go
