/************************************************************************/
/*      Archivo:                calculo_tir_tea.sp                      */
/*      Stored procedure:       sp_calculo_tir_tea                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Armando Miramon                         */
/*      Fecha de escritura:     11-Oct-2019                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA", representantes exclusivos para el Ecuador de la       */
/*      "NCR CORPORATION".                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este programa se utiliza para calcular el CAT de un credito     */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*    FECHA           AUTOR           RAZON                             */
/*  11/Oct/19       A. Miramon     Emision Inicial                      */
/*  10/Dic/19       A. Miramon     Ajuste en cálculo de CAT             */
/*  16/Abr/2021   Jose Morocho Q.  CAR-S461002-SAF Calculo del TEA y TCEA*/
/*  5/Nov/2021    Kevin Rodríguez  Cambio de nombre sp y ajustes cálculo*/
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_calculo_tir_tea')
   drop proc sp_calculo_tir_tea
go

CREATE PROC sp_calculo_tir_tea(
    @i_operacionteac      int,
    @i_tablas_definitivas char(1) = 'S',
    @o_tir                DECIMAL(18,10) out,
	@o_tea                DECIMAL(18,10) = null out
    
)
as
declare 
@w_sp_name         varchar(32),
@w_fecha_ini       datetime,
@w_fecha_fin       datetime,
@w_a               DECIMAL(18,10),
@w_b               DECIMAL(18,10),
@w_c               DECIMAL(18,10),
@w_i               int,
@w_j               int,
@w_error           int,
@w_valc            DECIMAL(18,10),
@w_cuota           float, 
@w_dias_cuota_acum float,    
@w_monto           DECIMAL(18,10),
@w_factor          smallint,
@w_fecha_ini_cuota datetime,
@w_fecha_fin_cuota datetime,
@w_tdivi           smallint,
@w_periodica       CHAR(1),
@w_F               FLOAT,
@w_div             int
    
/* Captura nombre de Stored Procedure  */
select @w_sp_name = 'sp_calculo_tir_tea',
@w_i = 1,
@w_periodica = 'S'

if @i_tablas_definitivas = 'N'
begin
   select
   @w_fecha_ini  = opt_fecha_ini,
   @w_tdivi      = opt_periodo_int * a.td_factor
   from ca_operacion_tmp, ca_tdividendo a
   where opt_operacion = @i_operacionteac
   and   a.td_tdividendo = opt_tdividendo
   
   -- Verificar si es Periodica o No periodica
   if exists (select 1 from ca_dividendo_tmp where dit_operacion = @i_operacionteac 
              and datediff(dd,dit_fecha_ini,dit_fecha_ven) <> @w_tdivi) 
   select @w_periodica = 'N'
   
   IF @w_periodica = 'N' SELECT @w_F = 1.0
   ELSE
      select @w_F = tdivi  
      from ca_tasas_periodos 
      where tdivi = @w_tdivi 
   
   select @w_monto = sum(amt_cuota)
   from ca_amortizacion_tmp, ca_dividendo_tmp, ca_rubro_op_tmp
   where amt_operacion = @i_operacionteac
   and dit_operacion = amt_operacion 
   and rot_operacion = amt_operacion 
   and dit_dividendo = amt_dividendo
   and amt_concepto  = rot_concepto
   and rot_tipo_rubro = 'C'

   --a es la tasa diaria mas baja posible
   select @w_a = 0.00
   --b es el monto de incremento para la prospección de la tasa
   select @w_b = (2.00 * @w_F) / 360
   --c es el punto medio de las dos tasas pero al momento inicial es cero
   select @w_c = 0.00

   -- @w_i numero maximo de iteraciones dadas para encontrar la TIR
   while @w_i < 1000
   begin
      select @w_valc = 0
      select @w_c = (@w_a + @w_b) / 2
      
      declare cur_calc_teac cursor for
      select sum(amt_cuota), dit_fecha_ven, dit_dividendo
      from ca_dividendo_tmp, ca_amortizacion_tmp
      where dit_operacion = @i_operacionteac
      and dit_operacion = amt_operacion
      and dit_dividendo = amt_dividendo
      and amt_cuota > 0
      group by dit_fecha_ven, dit_dividendo
      order by dit_fecha_ven
      for read only
         
      open cur_calc_teac
      fetch cur_calc_teac into @w_cuota, @w_fecha_fin_cuota, @w_div
      while @@fetch_status = 0 
      begin         
         select @w_dias_cuota_acum = datediff(dd, @w_fecha_ini, @w_fecha_fin_cuota)
		 IF @w_periodica = 'S'
		    select @w_valc = @w_valc + @w_cuota / power((1 + @w_c), @w_div)
		 ELSE
            select @w_valc = @w_valc + @w_cuota / power((1 + @w_c), @w_dias_cuota_acum)
         fetch cur_calc_teac into @w_cuota, @w_fecha_fin_cuota, @w_div
      end
      close cur_calc_teac
      deallocate cur_calc_teac
      
      if @w_valc < @w_monto
         select @w_b = @w_c
      else
         select @w_a = @w_c
      
      if abs(@w_valc - @w_monto) <= 0.01
      begin
	     if (@w_periodica = 'S')
		 begin
	        select @o_tir = @w_c * 360.00/@w_F
		    select @o_tea = power((1 + @o_tir * @w_F / 360.00), (360.00 / @w_F)) -1
		 end
		 ELSE
		 BEGIN
		    select @o_tir = @w_c * 365.00/@w_F
		    select @o_tea = power((1 + @o_tir * @w_F / 365.00), (365.00 / @w_F)) -1
		 end 
         select @o_tir =  round(@o_tir * 100,4)
		 select @o_tea =  round(@o_tea * 100,4)
		 select @w_i = 1000
      end
      select @w_i = @w_i + 1
   end
end

if @i_tablas_definitivas = 'S'
begin   
   select
   @w_fecha_ini = op_fecha_ini,
   @w_tdivi     = op_periodo_int * a.td_factor
   from ca_operacion, ca_tdividendo a 
   where op_operacion = @i_operacionteac
   and   a.td_tdividendo = op_tdividendo
   
   -- Verificar si es Periodica o No periodica
   if exists (select 1 from ca_dividendo where di_operacion = @i_operacionteac 
              and datediff(dd,di_fecha_ini,di_fecha_ven) <> @w_tdivi) 
   select @w_periodica = 'N'
   
   IF @w_periodica = 'N' SELECT @w_F = 1.0
   ELSE
      select @w_F = tdivi  
      from ca_tasas_periodos 
      where tdivi = @w_tdivi 
   
   select @w_monto = sum(am_cuota)
   from ca_amortizacion, ca_dividendo, ca_rubro_op
   where am_operacion = @i_operacionteac
   and di_operacion = am_operacion 
   and ro_operacion = am_operacion 
   and di_dividendo = am_dividendo
   and am_concepto  = ro_concepto
   and ro_tipo_rubro = 'C'

   --a es la tasa mas baja posible
   select @w_a = 0.00
   --b es el monto de incremento para la prospección de la tasa
   select @w_b = (2.00 * @w_F) / 360
   --c es el punto medio de las dos tasas pero al momento inicial es cero
   select @w_c = 0.00
   -- @w_i numero maximo de iteraciones dadas para encontrar la TIR
   while @w_i < 1000
   begin
      select @w_valc = 0
      select @w_c = (@w_a + @w_b) / 2
      
      declare cur_calc_teac cursor for
      select sum(am_cuota), di_fecha_ven, di_dividendo
      from ca_dividendo, ca_amortizacion
      where di_operacion = @i_operacionteac
      and di_operacion = am_operacion
      and di_dividendo = am_dividendo
      and am_cuota > 0
      group by di_fecha_ven, di_dividendo
      order by di_fecha_ven
      for read only
         
      open cur_calc_teac
         
      fetch cur_calc_teac into @w_cuota, @w_fecha_fin_cuota, @w_div
      while @@fetch_status = 0 
      begin         
         select @w_dias_cuota_acum = datediff(dd, @w_fecha_ini, @w_fecha_fin_cuota)
		 IF @w_periodica = 'S'
		    select @w_valc = @w_valc + @w_cuota / power((1 + @w_c), @w_div)
		 ELSE
            select @w_valc = @w_valc + @w_cuota / power((1 + @w_c), @w_dias_cuota_acum)
         fetch cur_calc_teac into @w_cuota, @w_fecha_fin_cuota, @w_div
      end
      close cur_calc_teac
      deallocate cur_calc_teac

      if @w_valc < @w_monto
         select @w_b = @w_c
      else
         select @w_a = @w_c
      
      if abs(@w_valc - @w_monto) <= 0.01
      begin
	    if (@w_periodica = 'S')
		 begin
	        select @o_tir = @w_c * 360.00/@w_F
		    select @o_tea = power((1 + @o_tir * @w_F / 360.00), (360.00 / @w_F)) -1
		 end
		 ELSE
		 BEGIN
		    select @o_tir = @w_c * 365.00/@w_F
		    select @o_tea = power((1 + @o_tir * @w_F / 365.00), (365.00 / @w_F)) -1
		 end 
         select @o_tir =  round(@o_tir * 100,4)
		 select @o_tea =  round(@o_tea * 100,4)
		 select @w_i = 1000
      end
      select @w_i = @w_i + 1
   end
end

IF @o_tir is null select @o_tir = 0.00
IF @o_tea is null select @o_tea = 0.00

return 0

go
