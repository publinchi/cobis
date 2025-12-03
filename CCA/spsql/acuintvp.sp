/************************************************************************/
/*   Archivo:              acuintvp.sp                                  */
/*   Stored procedure:     sp_actualiza_acum_int_vp                     */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         ELCIRA PELAEZ                                */
/*   Fecha de escritura:   Feb. 2.003                                   */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*      - @i_cancelar = S                                               */
/*      Programa ejecutado si hay precancelacion de la operacion        */
/*   Calcular VP para las cuotas vigentes y no vigentes                 */ 
/*      y distribuye el valor presente en todas las cuotas iniciando    */
/*      desde la vigente                                                */
/*      Tambien retorna el valor que debe ser contabilizado como        */
/*      como causacion pendiente entre lo que va a cumulado   y el      */
/*      total de intereses  en valor presente                           */ 
/*      -@i_canelar = N                                                 */ 
/*   Calcular VP para el pago extraordinario Normal = 'N'               */ 
/*      actualizando los acumulado para la aplicacion del pago ya con   */
/*      el Interes en VP                                                */
/*      Si una de las cuotas tiene un valor acumulado, el sistema le    */
/*      retorna la causacion pendiente correspondiente a lo que paga de */
/*      interes en VP  para generar el respectivo PRV y contabilizar    */
/************************************************************************/
/*                     MODIFICACIONES                                   */
/*     FECHA          AUTOR               RAZON                         */
/*                                                                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_acum_int_vp')
   drop proc sp_actualiza_acum_int_vp
go

create proc sp_actualiza_acum_int_vp
        @i_operacion            int,
        @i_monto_pago           money = 0,
        @i_cancelar             char(1) = 'N',
        @i_secuencial_pag       int = null,
        @i_fecha_proceso        datetime = null,
        @o_causacion_pte        money = null out,
        @o_causacion_pte_ajuste money = null out


as
declare
   @w_sp_name      descripcion,
   @w_return      int,
   @w_concepto      catalogo,
   @w_concepto_int      catalogo,
   @w_operacion      int,
   @w_di_estado            tinyint,
   @w_est_vigente          tinyint,
   @w_est_novigente        tinyint,
   @w_est_cancelado        tinyint,
   @w_est_vencido          tinyint,
   @w_interes              money, 
   @w_valor_futuro_int     money, 
   @w_div_vigente          int,
   @w_dividendo            int,
   @w_num_periodo_d        int,
   @w_periodo_d            catalogo,
   @w_valor_pagado         money,
   @w_fecha_proceso        datetime,
   @w_valor_dia_rubro      money,
   @w_dias                 int,
   @w_di_fecha_ven         datetime,
   @w_dias_anio            int,       
   @w_base_calculo         char(1),
   @w_forma_pago_int       char(1),
   @w_num_dec_tapl         tinyint,
   @w_porcentaje           float,
   @w_tasa_prepago         float,
   @w_vp_total             money,
   @w_vp_cobrar            money,
   @w_cuota_cap            money,
   @w_valor_int_cap        money,
   @w_no_cobrado_int       money,
   @w_int_en_vp            money,
   @w_int_en_vp1           money,
   @w_numdec_op            smallint,
   @w_moneda               smallint,
   @w_proy_secuen_uno       money,
   @w_interes_acum_total     money,
   @w_vp_sobrante          money,
   @w_am_cuota              money,
   @w_contador             int,
   @w_max_div              smallint,
   @w_valor_pago           money,
   @w_acumulado_int_cap    money,
   @w_devolucion           money,
   @w_vp                   char(1),
   @w_int_devol            money,
   @w_otros_rubros         money,
   @w_otros_rubros2        money,
   @w_proy_secuen_dos       money,
   @w_proy_cuota_vig_tot   money,
   @w_sobrante_sec_uno     money,
   @w_acum_secuen_uno       money,
   @w_acum_secuen_dos       money,
   @w_nuevo_acumulado       money

select   @w_sp_name = 'sp_actualiza_acum_int_vp'
   

-- ESTADOS PARA CARTERA 
select
@w_est_vigente   = 1,
@w_est_novigente = 0,
@w_est_vencido   = 2,
@w_est_cancelado = 3



select
    @w_interes            = 0,
   @o_causacion_pte       = 0,
   @w_am_cuota            = 0,
   @w_div_vigente         = 50000,
   @w_acumulado_int_cap   = 0,
   @w_valor_futuro_int    = 0,
   @w_vp_total            = 0,
   @w_vp_cobrar           = 0,
   @w_valor_pago          = 0,
   @w_no_cobrado_int      = 0,
   @w_int_en_vp           = 0,
   @w_int_en_vp1          = 0,
   @w_cuota_cap           = 0,
   @w_valor_int_cap       = 0,
   @w_proy_secuen_uno     = 0,
   @w_numdec_op           = 0,
   @w_interes_acum_total  = 0,
   @w_vp_sobrante         = 0,
   @w_max_div             = 0,
   @w_int_devol           = 0,
   @w_devolucion          = 0,
   @w_proy_secuen_dos     = 0,
   @w_proy_cuota_vig_tot  = 0,
   @w_sobrante_sec_uno    = 0,
   @w_acum_secuen_uno     = 0,
   @w_acum_secuen_dos     = 0

-- INFORMACION DE OPERACION 

select 
   @w_num_periodo_d      = op_periodo_int,
   @w_periodo_d          = op_tdividendo,
   @w_fecha_proceso      = op_fecha_ult_proceso,
   @w_moneda             = op_moneda,
   @w_dias_anio          = op_dias_anio,
   @w_base_calculo       = op_base_calculo
from ca_operacion
where  op_operacion       = @i_operacion

-- DECIMALES 
exec @w_return = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_numdec_op out
if @w_return != 0
   return @w_return

select @w_div_vigente  = isnull(di_dividendo,0),
       @w_di_fecha_ven = di_fecha_ven 
from   ca_dividendo
where  di_operacion = @i_operacion
and    di_estado    = @w_est_vigente

select @w_max_div  = isnull(di_dividendo,0)
from   ca_dividendo
where  di_operacion = @i_operacion

select @w_forma_pago_int = ro_fpago,
       @w_num_dec_tapl   = ro_num_dec,
       @w_concepto_int   = ro_concepto,
       @w_porcentaje     = ro_porcentaje
from ca_rubro_op
where ro_operacion  = @i_operacion
and   ro_tipo_rubro = 'I'

if @w_forma_pago_int = 'P' 
   select @w_forma_pago_int = 'V'

if @i_cancelar = 'N'
begin
   if @i_monto_pago = 0
      return 0
   
   select @w_valor_pago = @i_monto_pago
end

---PRINT   'acuintvp.sp   @i_monto_pago  %1! @i_cancelar %2!',@i_monto_pago,@i_cancelar

if @i_cancelar = 'S'  
begin
   declare
      cursor_valor_presente cursor
      for select di_dividendo, di_fecha_ven, di_estado
          from   ca_dividendo
          where  di_operacion  = @i_operacion
          and    di_dividendo >= @w_div_vigente
          order  by di_dividendo desc
      for read only
end
ELSE
begin
   declare
      cursor_valor_presente cursor
      for select di_dividendo, di_fecha_ven, di_estado
          from   ca_dividendo
          where  di_operacion  = @i_operacion
          and    di_dividendo >= @w_div_vigente
      for read only
end

open cursor_valor_presente

fetch cursor_valor_presente
into  @w_dividendo, @w_di_fecha_ven, @w_di_estado

while @@fetch_status = 0 
begin
   if (@@fetch_status = -1)
      return 708899
   
   select @w_valor_futuro_int = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion = @i_operacion
   and    ro_operacion = am_operacion
   and    ro_concepto  = am_concepto
   and    am_dividendo = @w_dividendo
   and    ro_fpago     != 'A'
   and    ro_tipo_rubro ='I'
   and    am_estado     != @w_est_cancelado  

   
   if @w_di_estado = @w_est_vigente  and @w_valor_futuro_int > 0
   begin
      ----PROYECTADOS PARA COMPARA POSTERIORMENTE DONDE COLOCAR EL VALOR DE INT EN VP 
      ----SEGUN EL SECUENCIAL
	  select @w_proy_secuen_uno = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion = @i_operacion
      and    ro_operacion   = am_operacion
      and    ro_concepto    = am_concepto
      and    am_dividendo   = @w_dividendo
      and    am_estado     != @w_est_cancelado               
      and    ro_fpago      != 'A'
      and    ro_tipo_rubro =  'I'
      and    am_secuencia  = 1
	  
      
	  select @w_proy_secuen_dos = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion = @i_operacion
      and    ro_operacion   = am_operacion
      and    ro_concepto    = am_concepto
      and    am_dividendo   = @w_dividendo
      and    am_estado     != @w_est_cancelado                     
      and    ro_fpago      != 'A'
      and    ro_tipo_rubro  = 'I'
      and    am_secuencia   = 2
      
	 
      ---ACUMULADOS PARA SABER SI HAY  REVERSO DE TRANSACCION PRV DESPUES DEL CALCULO DEL VP
      select @w_acum_secuen_uno = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion = @i_operacion
      and    ro_operacion   = am_operacion
      and    ro_concepto    = am_concepto
      and    am_dividendo   = @w_dividendo
      and    am_estado     != @w_est_cancelado
      and    ro_fpago      != 'A'
      and    ro_tipo_rubro  = 'I'
      and    am_secuencia   = 1
      
      select @w_acum_secuen_dos = isnull(sum(am_acumulado + am_gracia - am_pagado),0)
      from   ca_amortizacion, ca_rubro_op
      where  ro_operacion = @i_operacion
      and    ro_operacion   = am_operacion
      and    ro_concepto    = am_concepto
      and    am_dividendo   = @w_dividendo
      and    am_estado   != @w_est_cancelado                    
      and    ro_fpago      != 'A'
      and    ro_tipo_rubro  = 'I'
      and    am_secuencia   = 2
      
      select  @w_proy_cuota_vig_tot = @w_proy_secuen_uno + @w_proy_secuen_dos 
      select  @w_interes_acum_total =  @w_acum_secuen_uno + @w_acum_secuen_dos
   end
   
   select @w_dias = datediff(dd,@w_fecha_proceso,@w_di_fecha_ven)           
   
   if @w_dias_anio = 360  
   begin
      exec sp_dias_cuota_360
           @i_fecha_ini = @w_fecha_proceso,
           @i_fecha_fin = @w_di_fecha_ven,
           @o_dias      = @w_dias out
   end
   
   exec @w_return =  sp_conversion_tasas_int
        @i_dias_anio      = @w_dias_anio,
        @i_base_calculo   = @w_base_calculo,
        @i_periodo_o      = @w_periodo_d,
        @i_modalidad_o    = @w_forma_pago_int,
        @i_num_periodo_o  = @w_num_periodo_d,
        @i_tasa_o         = @w_porcentaje,
        @i_periodo_d      = 'D',
        @i_modalidad_d    = 'A',
        @i_num_periodo_d  = @w_dias,
        @i_num_dec        = @w_num_dec_tapl,
        @o_tasa_d         = @w_tasa_prepago output
   
   if @w_return != 0
      return @w_return
   
   select @w_cuota_cap  = isnull(am_cuota - am_pagado,0)
   from   ca_amortizacion,ca_rubro_op 
   where  am_operacion = @i_operacion
   and    am_operacion  = ro_operacion
   and    am_concepto = ro_concepto
   and    ro_tipo_rubro = 'C'
   and    am_dividendo   =  @w_dividendo
   
   -- AGO EXTRA NORMAL CUOTAS
   -- CUANDO EL VALOR DEL PAGO LLEGA A SER MENOR QUE LA CUOTA DE CAPITAL             
   -- SE TOMA ESTE VALOR COMO CUOTA DE CAPITAL PARA TRAER A VP EL EXEDENTE QUE QUEDA 
   -- + INTERSE FUTURO, NO LA CUOTA COMPLETA DE CAPITAL YA QUE NO LA ALCANZARA A PAGAR COMPLETAMENTE
   
   select @w_vp = 'S'
   
   select  @w_valor_int_cap = @w_valor_futuro_int + @w_cuota_cap
   if @i_cancelar = 'N'
   begin
      if @w_valor_pago > 0 and  @w_valor_pago < @w_cuota_cap   
         break  ---Valor presente de cuotas completas
      select  @w_valor_int_cap = @w_valor_futuro_int + @w_cuota_cap
   end
   
   exec @w_return = sp_calculo_valor_presente
        @i_tasa_prepago       = @w_tasa_prepago,
        @i_valor_int_cap      = @w_valor_int_cap,
        @i_dias               = @w_dias,
        @i_valor_futuro_int   = @w_valor_futuro_int,
        @i_numdec_op          = @w_numdec_op,
        @o_monto              = @w_vp_cobrar  output
   
   if @w_return != 0
      return @w_return
   
   select @w_int_en_vp      =  @w_vp_cobrar
   select @w_devolucion     =  isnull( @w_valor_futuro_int  - @w_int_en_vp,0)
   
   -- CALCULA VALORES DIFERENTES A INTERES 
   select @w_otros_rubros = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion   = @i_operacion
   and    ro_operacion   = am_operacion
   and    ro_concepto    = am_concepto
   and    ro_fpago      != 'A'
   and    ro_tipo_rubro != 'I'
   and    am_estado     != @w_est_cancelado            
   and    am_dividendo   = @w_dividendo
   
   -- CALCULA VALORES DIFERENTES A INTERES PARA RUBROS ANTICIPADOS 
   select @w_otros_rubros2 = isnull(sum(am_cuota + am_gracia - am_pagado ),0)
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion   = @i_operacion
   and    ro_operacion   = am_operacion
   and    ro_concepto    = am_concepto
   and    ro_fpago       = 'A'
   and    ro_tipo_rubro != 'I'
   and    am_estado     != @w_est_cancelado            
   and    am_dividendo   = @w_dividendo + 1
   
   select @w_otros_rubros = @w_otros_rubros + @w_otros_rubros2
   
   if @i_cancelar = 'N'
   begin
      if @w_valor_pago <= 0
         break
      
      select @w_acumulado_int_cap = @w_cuota_cap + @w_int_en_vp
      select @w_valor_pago = @w_valor_pago - @w_acumulado_int_cap - @w_otros_rubros
   end ---Cancelar = 'N'
   
   select @w_vp_total = @w_vp_total + @w_int_en_vp
   
   fetch cursor_valor_presente
   into  @w_dividendo, @w_di_fecha_ven, @w_di_estado
end -- CURSOR cursor_valor_presente 

close cursor_valor_presente
deallocate cursor_valor_presente

-- ANALIZAR EL VALOR DE INTERES EN  VP  SE  COLOCA EN LA CUOTA VIGENTE O 
-- DISTRIBUIRLO EN LAS CUOTAS QUE ALCANCEL DE LA TABLA                   

select @w_interes = @w_vp_total

if @w_interes > 0 
begin
   if @w_proy_cuota_vig_tot >= @w_interes      ---LA CUOTA UNO CUBRE TODO EL VP EN LOS SECUENCIALES EXISTENTES
   begin 
      select @w_sobrante_sec_uno =  0 
      
      if @w_proy_secuen_uno > @w_interes       --- SECUENCIAL UNO CUBRE TODO EL INTERES EN VP  
      begin 
         update ca_amortizacion
         set    am_acumulado = am_pagado + @w_interes --- POR QUE EL SALDO A PAGAR ES= ACUMULADO - PAGADO
         from   ca_amortizacion, ca_rubro_op
         where  ro_operacion = @i_operacion
         and    ro_operacion = am_operacion
         and    ro_concepto  = am_concepto
         and    am_dividendo = @w_div_vigente
         and    ro_fpago  != 'A'
         and    ro_tipo_rubro='I'
         and    am_secuencia = 1
         
         if @w_acum_secuen_uno > @w_interes
            select @o_causacion_pte_ajuste  =  @w_acum_secuen_uno - @w_interes
         else
            select @o_causacion_pte  =  @w_interes - @w_acum_secuen_uno 
      end 
      ELSE 
      begin
         if @w_proy_secuen_uno < @w_interes     --- SECUENCIAL UNO CUBRE UNA PARTE DEL VP
         begin 
            select @w_sobrante_sec_uno =  isnull(@w_interes -  @w_proy_secuen_uno,0)
            
            update ca_amortizacion
            set    am_acumulado = @w_proy_secuen_uno
            from   ca_amortizacion, ca_rubro_op
            where  ro_operacion = @i_operacion
            and    ro_operacion   = am_operacion
            and    ro_concepto    = am_concepto
            and    am_dividendo   = @w_div_vigente
            and    ro_fpago  != 'A'
            and    ro_tipo_rubro ='I'
            and    am_secuencia  = 1
         end 
         
         if @w_sobrante_sec_uno > 0             ---SECUENCIAL DOS CUBRE EL SOBRANTE DEL VP
         begin  
            update ca_amortizacion
            set    am_acumulado = @w_sobrante_sec_uno
            from   ca_amortizacion, ca_rubro_op
            where  ro_operacion  = @i_operacion
            and    ro_operacion    = am_operacion
            and    ro_concepto     = am_concepto
            and    am_dividendo    = @w_div_vigente
            and    ro_fpago       != 'A'
            and    ro_tipo_rubro   = 'I'
            and    am_secuencia    = 2
            
            if @w_acum_secuen_dos > @w_sobrante_sec_uno 
               select @o_causacion_pte_ajuste = @w_acum_secuen_dos - @w_sobrante_sec_uno       ---AJUSTE PRV (-)
            else
               select @o_causacion_pte = @w_sobrante_sec_uno  - @w_acum_secuen_dos             ---AJUSTE PRV (+)
         end
      end
   end --FIN ACTUALIZAR EL VP EN LA CUOTA VIGENTE 
   ELSE
   begin -- DISTRIBUIR EL VP @w_interes EN LAS CUOTAS QUE ALCANCE 
      select @w_contador    = @w_div_vigente
      select @w_vp_sobrante = @w_interes
      
      while @w_contador  <= @w_max_div  
      begin
         select @w_am_cuota = isnull(sum(am_cuota),0)
         from   ca_amortizacion, ca_rubro_op
         where  ro_operacion = @i_operacion
         and    ro_operacion = am_operacion
         and    ro_concepto  = am_concepto
         and    am_dividendo = @w_contador
         and    am_estado     != @w_est_cancelado         
         and    ro_fpago  != 'A'
         and    ro_tipo_rubro='I'   
         
         if @w_vp_sobrante  >= @w_am_cuota  
         begin
            ---ANALIZAR LAS SECUENCIAS
            if @w_proy_secuen_uno > 0 
            begin
               update ca_amortizacion
               set    am_acumulado = am_cuota
               from   ca_amortizacion, ca_rubro_op
               where  ro_operacion = @i_operacion
               and    ro_operacion = am_operacion
               and    ro_concepto  = am_concepto
               and    am_dividendo = @w_contador
               and    ro_fpago  != 'A'
               and    ro_tipo_rubro='I'   
               and    am_secuencia = 1
            end
            
            if @w_proy_secuen_dos > 0 
            begin
                update ca_amortizacion
                set    am_acumulado = am_cuota
                from   ca_amortizacion, ca_rubro_op
                where  ro_operacion = @i_operacion
                and    ro_operacion = am_operacion
                and    ro_concepto  = am_concepto
                and    am_dividendo = @w_contador
                and    ro_fpago  != 'A'
                and    ro_tipo_rubro='I'   
                and    am_secuencia = 2
            end
         end 
         ELSE
         begin
            if @w_vp_sobrante > 0 
            begin
               update ca_amortizacion
               set    am_acumulado = @w_vp_sobrante
               from   ca_amortizacion, ca_rubro_op
               where  ro_operacion = @i_operacion
               and    ro_operacion = am_operacion
               and    ro_concepto  = am_concepto
               and    am_dividendo = @w_contador
               and    ro_fpago  != 'A'
               and    ro_tipo_rubro='I'   
            END 
            ELSE
               break
         end
         
         select @w_contador = @w_contador + 1
         select @w_vp_sobrante = round(@w_vp_sobrante - @w_am_cuota,@w_numdec_op)
      end ---FIN DEL WHILE
      
     if @w_interes > @w_interes_acum_total                ----GENERA UN PRV (+) 
        select @o_causacion_pte =  @w_interes - @w_interes_acum_total
   end  -- FIN DISTRIBUIR EL VP @w_interes EN LAS CUOTAS QUE ALCANCE 
end ---@w_interes > 0
ELSE
begin
   if @w_interes <> 0
   begin
      select @w_nuevo_acumulado =  @w_interes + @w_interes_acum_total
      
      if @w_nuevo_acumulado > 0
      begin
         update ca_amortizacion
         set    am_acumulado = @w_nuevo_acumulado
         from   ca_amortizacion, ca_rubro_op
         where  ro_operacion = @i_operacion
         and    ro_operacion = am_operacion
         and    ro_concepto  = am_concepto
         and    am_dividendo = @w_div_vigente
         and    ro_fpago  != 'A'
         and    ro_tipo_rubro='I'
         
         select @o_causacion_pte_ajuste = @w_interes * -1  ---SE HACE AJUSTE POR QUE ACUMULADO  ES > QUE VP 
      end
      ELSE
      begin
         update ca_amortizacion
         set    am_acumulado = 0
         from   ca_amortizacion, ca_rubro_op
         where  ro_operacion = @i_operacion
         and    ro_operacion = am_operacion
         and    ro_concepto  = am_concepto
         and    am_dividendo = @w_div_vigente
         and    ro_fpago  != 'A'
         and    ro_tipo_rubro='I'   
         
         select @o_causacion_pte =   @w_nuevo_acumulado    ---SE HACE DEVOLUCION DE INTERES POR QUE EL VP > QUE ACUMULADO
         select @o_causacion_pte_ajuste = @w_interes_acum_total  ---SE HACE AJUSTE POR QUE SE DEVUELVE MAS DE LO ACUMULADO 
      end
   end
end   
return 0
go
