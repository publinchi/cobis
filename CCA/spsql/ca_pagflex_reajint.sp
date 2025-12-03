/************************************************************************/
/*   Archivo:            ca_pagflex_reajint.sp                          */
/*   Stored procedure:   sp_ca_pagflex_reajuste_int                     */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Elcira PElaez Burbano                          */
/*   Fecha de escritura: May 2014                                       */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                          PROPOSITO                                   */
/*   Procedimiento  que reajusta el interes corriente  en tablas        */
/*   eb tablas FLEXIBLES                                                */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA           AUTOR      RAZON                                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca_pagflex_reajuste_int')
   drop proc sp_ca_pagflex_reajuste_int
go

create proc sp_ca_pagflex_reajuste_int
@s_user              login,
@s_term              varchar(30),
@s_date              datetime, 
@s_ofi               int,
@i_operacionca       int,
@i_fecha_proceso     datetime,
@i_banco             cuenta = null,
@i_disminuye         char(1) = 'S'
  
   
as
declare 
   @w_error                      int,
   @w_di_dias_cuota              int,
   @w_dividendo                  smallint,
   @w_saldo_cap                  money,
   @w_valor_calc                 float,
   @w_di_fecha_ini               datetime,
   @w_di_fecha_ven               datetime,
   @w_concepto                   catalogo,
   @w_estado                     tinyint,
   @w_tipo_rubro                 char(1),
   @w_fpago                      char(1),
   @w_est_vigente                tinyint,
   @w_est_cancelado              tinyint,
   @w_di_vigente                 smallint,
   @w_am_acumulado               money,
   @w_moneda                     smallint,
   @w_num_dec                    smallint,
   @w_moneda_nac                 smallint,
   @w_num_dec_mn                 smallint,
   @w_observacion                descripcion,
   @w_oficina                    int,
   @w_am_secuencia               smallint,
   @w_valor_calc_final           money,
   @w_am_estado                  smallint,
   @w_am_cuota                   money,
   @w_contador                   int,
   @w_numero_cuotas_restantes    int,
   @w_fecha_proceso              datetime,
   @w_am_pagado                  money,
   @w_base_calculo               char(1),
   @w_valor_cuota_vigente        money,
   @w_num_dec_tapl               tinyint,
   @w_forma_pago_int             char(1),
   @w_dias_anio                  smallint,
   @w_tdividendo                 catalogo,
   @w_periodo_int                int,
   @w_tasa_cvigente              float,
   @w_porcentaje_efa             float,
   @w_referencial                catalogo,
   @w_sec_max                    int,
   @w_valor_referencial          float,
   @w_fecha_referencial          datetime,
   @w_tasa_ref                   catalogo,
   @w_signo                      char(1),
   @w_factor                     float,
   @w_cuotavigente               money,
   @w_tasa_equivalente           float,
   @w_dias_tasa_equivalente      int,
   @w_cursor_div                 char(1),
   @w_cursor_rub                 char(1),
   @w_dias_pagados               smallint,
   @w_dias_causados              smallint,
   @w_fecha_hoy_causado          datetime,
   @w_fecha_hoy_pagado           datetime,
   @w_valor_int_dia              money,
   @w_saldo_base                 money,
   @w_dividendo_hasta            smallint

-- DEFINICION DE ESTADOS
select 
@w_est_vigente         = 1,
@w_est_cancelado       = 3,
@w_valor_calc_final    = 0,
@w_am_pagado           = 0,
@w_valor_cuota_vigente = 0,
@w_cuotavigente        = 0,
@w_contador            = 0,
@w_cursor_rub          = 'N',
@w_cursor_div          = 'N'

select 
@w_moneda           = op_moneda,
@w_oficina          = op_oficina,
@w_fecha_proceso    = op_fecha_ult_proceso,
@w_base_calculo     = op_base_calculo,
@w_dias_anio        = op_dias_anio,
@w_tdividendo       = op_tdividendo,
@w_periodo_int      = op_periodo_int
from   ca_operacion 
where  op_operacion = @i_operacionca

-- MANEJO DE DECIMALES PARA LA MONEDA DE LA OPERACION
exec @w_error = sp_decimales
@i_moneda       = @w_moneda,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_moneda_nac out,
@o_dec_nacional = @w_num_dec_mn out

if @w_error <> 0  goto ERROR

select 
@w_di_vigente   = di_dividendo,
@w_di_fecha_ven = di_fecha_ven
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_estado    = @w_est_vigente

if @@error <> 0 begin 
   select @w_error = 710001
   goto ERROR
end

select @w_dividendo_hasta = max(di_dividendo)
from   ca_dividendo
where  di_operacion = @i_operacionca

-- CALCULAR EL MONTO DEL CAPITAL TOTAL
select @w_saldo_cap = sum(am_cuota+am_gracia-am_pagado)
from   ca_amortizacion, ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_tipo_rubro = 'C'
and    ro_fpago      in ('P','A') -- PERIODICO VENCIDO O ANTICIPADO
and    am_operacion = @i_operacionca
and    am_concepto  = ro_concepto 
and    am_dividendo >= @w_di_vigente

---print ' ca_pagflex_reajint.sp va  @w_di_vigente:  ' + cast (  @w_di_vigente as varchar)

declare cursor_dividendo cursor for select 
di_dividendo,   di_fecha_ini,  di_fecha_ven,
di_estado,      di_dias_cuota
from   ca_dividendo
where  di_operacion  = @i_operacionca
and    di_dividendo  between @w_di_vigente and @w_dividendo_hasta
order  by di_dividendo
for read only

open cursor_dividendo

select @w_cursor_div = 'S'

fetch cursor_dividendo into  
@w_dividendo,  @w_di_fecha_ini,  @w_di_fecha_ven,
@w_estado,     @w_di_dias_cuota

while @@fetch_status = 0 begin --(1) WHILE CURSOR PRINCIPAL DIVIDENDOS
   
   if @w_di_dias_cuota < 0 begin
      select @w_error = 710097
      goto ERROR
   end
   
  select @w_saldo_base = @w_saldo_cap
  
   --- CURSOR DE RUBROS TABLA CA_RUBRO_OP
   declare cursor_rubros cursor for select 
   ro_concepto,      ro_tipo_rubro,       ro_fpago,         
   ro_fpago,         ro_num_dec,          ro_porcentaje_efa,   
   ro_referencial,   ro_signo,            ro_factor
   from   ca_rubro_op
   where  ro_operacion  = @i_operacionca
   and    ro_fpago      in ('P', 'A') -- PERIODICO VENCIDO O ANTICIPADO
   and    ro_tipo_rubro in ('I') 
   order by ro_tipo_rubro desc
   for read only
   
   open cursor_rubros
   select @w_cursor_rub = 'S'
   
   fetch cursor_rubros  into  
   @w_concepto,         @w_tipo_rubro,       @w_fpago,         
   @w_forma_pago_int,   @w_num_dec_tapl,     @w_porcentaje_efa,   
   @w_referencial,      @w_signo,            @w_factor
   
   while   @@fetch_status = 0  
   begin -- (2) WHILE CURSOR RUBROS
   
       
      select @w_am_secuencia = isnull(max(am_secuencia), -999)
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_dividendo
      and    am_concepto  = @w_concepto
      
      if @w_am_secuencia < 0 goto SIG_RUBRO
      
      select 
      @w_am_estado    = am_estado,
      @w_am_acumulado = am_acumulado,
      @w_am_pagado    = am_pagado,
      @w_am_cuota     = am_cuota
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_dividendo
      and    am_concepto  = @w_concepto
      and    am_secuencia = @w_am_secuencia
      
      if @w_am_estado = @w_est_cancelado goto SIG_RUBRO

            
      if @w_fpago = 'P' select @w_fpago = 'V'
      
      -- CALCULAR TASA EQUIVALENTE
      exec @w_error =  sp_conversion_tasas_int
      @i_dias_anio      = @w_dias_anio,
      @i_periodo_o      = 'A',
      @i_modalidad_o    = 'V',
      @i_num_periodo_o  = 1,
      @i_tasa_o         = @w_porcentaje_efa,
      @i_periodo_d      = 'D',
      @i_modalidad_d    = @w_fpago, 
      @i_num_periodo_d  = @w_di_dias_cuota,
      @i_num_dec        = @w_num_dec_tapl,
      @o_tasa_d         = @w_tasa_equivalente output
      
      if @w_error <> 0 goto ERROR

     ---CALCULO TOTAL
      exec @w_error = sp_calc_intereses
      @tasa          = @w_tasa_equivalente,
      @monto         = @w_saldo_base,                          
      @dias_anio     = 360,
      @num_dias      = @w_di_dias_cuota,
      @causacion     = 'L',
      @intereses     = @w_valor_calc out
    

      if @w_error <> 0 goto ERROR
      --LGAR      
          select @w_valor_int_dia = @w_am_cuota / @w_di_dias_cuota

      select @w_valor_calc            = round (@w_valor_calc,@w_num_dec),            
             @w_dias_pagados          = 0,
             @w_dias_causados         = 0,
             @w_fecha_hoy_causado     = @i_fecha_proceso,
             @w_fecha_hoy_pagado      = @i_fecha_proceso,
             @w_dias_tasa_equivalente = @w_di_dias_cuota


      if (@w_am_pagado > 0) or (@w_am_acumulado > 0)
      begin ---(4)
      
        if (@w_am_pagado > 0)
         begin
            ---DE DEBE ANALIZAR A CUANTOS DIAS CORRESPONDE ESTE PAGADO
            ---CON RESPECTO AL PROYECTADO
            select @w_dias_pagados  = round(@w_am_pagado / @w_valor_int_dia,0)
            
            if @w_dias_pagados <= 0
               select @w_dias_pagados = 1
               
            select @w_fecha_hoy_pagado = dateadd(dd,@w_dias_pagados,@w_di_fecha_ini)

         end
         if @w_am_acumulado > 0
         begin
            ---DE DEBE ANALIZAR A CUANTOS DIAS CORRESPONDE ESTE ACUMULADO
            ---CON RESPECTO AL PROYECTADO
            select @w_dias_causados  = round(@w_am_acumulado / @w_valor_int_dia,0)
   
               if @w_dias_causados <= 0
               select @w_dias_causados = 1

               select @w_fecha_hoy_causado = dateadd(dd,@w_dias_causados,@w_di_fecha_ini)            

         end

         if  @w_fecha_hoy_pagado >= @w_fecha_hoy_causado
         begin

              exec @w_error = sp_dias_cuota_360
              @i_fecha_ini = @w_fecha_hoy_pagado,
              @i_fecha_fin = @w_di_fecha_ven,
              @o_dias      = @w_dias_tasa_equivalente OUTPUT

              if @w_error <> 0 goto ERROR              
                            
          end    
          ELSE
          begin
              exec @w_error = sp_dias_cuota_360
              @i_fecha_ini = @w_fecha_hoy_causado,
              @i_fecha_fin = @w_di_fecha_ven,
              @o_dias      = @w_dias_tasa_equivalente OUTPUT
                 
              if @w_error <> 0 goto ERROR              
          end
        
          if @w_dias_tasa_equivalente <= 0
             select @w_dias_tasa_equivalente = 1
         
      end ---(4)
      
---PRINT 'reajint.sp DIV ' + cast ( @w_dividendo as varchar) + ' dias_tasa_equivalente :  ' + cast(@w_dias_tasa_equivalente  as varchar) + ' @w_di_dias_cuota :  ' + cast(@w_di_dias_cuota  as varchar)
      
      
      if @w_dividendo = @w_di_vigente
      begin ---(1)
        if @w_dias_tasa_equivalente <= @w_di_dias_cuota  
        begin ---(2)
        
           -- TASA EQUIVALENTE PARA LOS DIAS DESDE HOY A FECHA VENCIIENTO DE LA CUOTA VIGENTE
           if @w_fpago = 'P' select @w_fpago = 'V'           
           
           exec @w_error =  sp_conversion_tasas_int
           @i_dias_anio      = @w_dias_anio,
           @i_periodo_o      = 'A',
           @i_modalidad_o    = 'V',
           @i_num_periodo_o  = 1,
           @i_tasa_o         = @w_porcentaje_efa, 
           @i_periodo_d      = 'D',
           @i_modalidad_d    = @w_fpago, 
           @i_num_periodo_d  = @w_dias_tasa_equivalente,
           @i_num_dec        = @w_num_dec_tapl,
           @o_tasa_d         = @w_tasa_cvigente output
           
           if @w_error <> 0 goto ERROR

           exec @w_error = sp_calc_intereses
           @tasa          = @w_tasa_cvigente,
           @monto         = @w_saldo_base,                          -- @w_saldo_cap - REQ 175: PEQUEÑA EMPRESA
           @dias_anio     = 360,
           @num_dias      = @w_dias_tasa_equivalente,
           @causacion     = 'L',
           @intereses     = @w_valor_cuota_vigente out
           
           if @w_error <> 0 goto ERROR

           select @w_cuotavigente = round(isnull(@w_am_acumulado,0) + isnull(@w_valor_cuota_vigente,0) ,@w_num_dec)

           if @w_cuotavigente < @w_am_pagado                       select @w_cuotavigente = @w_am_pagado
           if @w_cuotavigente > @w_am_cuota and @i_disminuye = 'S' select @w_cuotavigente = @w_am_cuota
          
           update ca_amortizacion 
           set    am_cuota     = @w_cuotavigente
           where  am_operacion = @i_operacionca  
           and    am_dividendo = @w_dividendo
           and    am_concepto  = @w_concepto
           and    am_secuencia = @w_am_secuencia
           
           if (@@error <> 0)begin
              select @w_error = 710003
              goto ERROR
           end
        end ---(2) @w_dias_tasa_equivalente > 0
             
      END  ---(1)
      ELSE 
      BEGIN  --- (3) Dividendos no vigentes
         
         
            update ca_amortizacion 
            set    am_cuota     = @w_valor_calc
            where  am_operacion = @i_operacionca
            and    am_dividendo = @w_dividendo
            and    am_concepto  = @w_concepto
            
            if (@@error <> 0) begin
               select @w_error = 710003
               goto ERROR
            end
            
            
      END ---(3)
      
      SIG_RUBRO:
      
      fetch cursor_rubros  into  
      @w_concepto,         @w_tipo_rubro,       @w_fpago,         
      @w_forma_pago_int,   @w_num_dec_tapl,     @w_porcentaje_efa,   
      @w_referencial,      @w_signo,            @w_factor
      
   end -- WHILE CURSOR RUBROS
   
   close cursor_rubros
   deallocate cursor_rubros
   select @w_cursor_rub = 'N'
   
   -- DISMINUIR AL SALDO DE CAPITAL LA CUOTA DE CAPITAL DEL DIV ACTUAL
   select @w_valor_calc = sum(am_cuota+am_gracia-am_pagado)
   from   ca_amortizacion,ca_rubro_op
   where  am_operacion = @i_operacionca
   and    am_dividendo = @w_dividendo
   and    ro_operacion = @i_operacionca
   and    ro_concepto  = am_concepto
   and    ro_tipo_rubro= 'C'
   and    ro_fpago     in ('P','A')
   
   select @w_saldo_cap  = @w_saldo_cap - @w_valor_calc
   
   fetch cursor_dividendo into  
   @w_dividendo,  @w_di_fecha_ini,  @w_di_fecha_ven,
   @w_estado,     @w_di_dias_cuota
   
end -- (2) WHILE CURSOR DIVIDENDOS

close cursor_dividendo
deallocate cursor_dividendo

select @w_cursor_div = 'N'

return 0

ERROR:

if @w_cursor_rub = 'S' begin
   close cursor_rubros
   deallocate cursor_rubros
end

if @w_cursor_div = 'S' begin
   close cursor_dividendo
   deallocate cursor_dividendo
end

return @w_error
 
go

