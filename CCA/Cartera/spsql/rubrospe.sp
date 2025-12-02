/************************************************************************/
/*      Archivo:                rubrospe.sp                             */
/*      Stored procedure:       sp_rubros_periodos_diferentes           */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez                           */
/*      Fecha de escritura:     Dic. 2002                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Genera para el periodo indicado en ca_rubro un registro en la   */
/*      tabla de amortizacion   , este sp es llamado de gentabla.sp     */
/************************************************************************/  
/*                              CAMBIOS                                 */
/*      ABR 10 2006      Elcira Pelaez        CXCINTES  NR 433          */ 
/*      MAY 11 2006      Elcira Pelaez        COMISION PRIMERA CUOTA    */
/*                                            def. 6452                 */
/*      AGO 10 2006      FQ                   def. 7000                 */
/*      FEB 03 2020      Luis Ponce           Ajuste Mig. Core Digital  */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_rubros_periodos_diferentes')
   drop proc sp_rubros_periodos_diferentes
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_rubros_periodos_diferentes
@i_operacion	int = NULL

as
declare
@w_sp_name		varchar(30),
@w_op_tdividendo	catalogo,
@w_op_periodo_int	int,
@w_dias_div		int,
@w_div_comision		int,
@w_contador		int,
@w_return               int,
@w_perio_en_meses       int,
@w_rot_concepto         catalogo,
@w_rot_valor            money,
@w_rot_periodo          smallint,
@w_rot_tperiodo         catalogo,
@w_dias_plazo_c         int,
@w_plazo                int,
@w_dias_int	        int,
@w_tplazo               catalogo,
@w_int_en_meses         int,
@w_plazo_en_meses_c     int,
@w_error                int,
@w_dias_plazo           int,
@w_est_vigente          smallint,
@w_est_novigente        smallint,
@w_max_div              int,
@w_min_div              int,
@w_tperiodo_op          catalogo,
@w_dias_div_uno         float,
@w_plazo_mes_div_uno    float,
@w_plazo_mes_div_uno_a    float,
@w_plazo_mes_div_uno_b    float,
@w_rot_base_calculo     money,
@w_rot_porcentaje       float,
@w_moneda               smallint,
@w_num_dec_mn            smallint,
@w_num_dec           smallint,
@w_moneda_n          smallint,
@w_rot_valor_uno     money,
@w_residuo           float,
@w_dias_periodo_int   int,
@w_dias_periodo_rub   int,
@w_dias_cuota_1       int

--- INICIALIZACION VARIABLES 
select @w_sp_name = 'sp_rubros_periodos_diferentes',
@w_rot_concepto	  = '',
@w_div_comision	  = 0,
@w_contador	  = 0,
@w_rot_valor      = 0,
@w_dias_div_uno = 0,
@w_plazo_mes_div_uno = 0,
@w_rot_valor_uno = 0.0


select @w_est_vigente = 1,
       @w_est_novigente = 0


--- VALIDAR EXISTENCIA DE PERIDICIDAD 

if not exists (select 1 from ca_rubro_op_tmp
where rot_operacion = @i_operacion
and rot_periodo is not null)
return 0

--- DATOS OPERACION 
select @w_op_tdividendo  = opt_tdividendo,
       @w_op_periodo_int = opt_periodo_int,
       @w_plazo          = opt_plazo,
       @w_tplazo         = opt_tplazo,
       @w_moneda         = opt_moneda
from ca_operacion_tmp
where opt_operacion	= @i_operacion

select @w_dias_periodo_int = @w_op_periodo_int * td_factor
from   ca_tdividendo
where  td_tdividendo = @w_op_tdividendo

exec @w_return = sp_decimales
     @i_moneda       = @w_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_mn out
     
     
 select @w_max_div = max(dit_dividendo)
 from   ca_dividendo_tmp
 where  dit_operacion = @i_operacion
 and    dit_estado in (@w_est_novigente, @w_est_vigente) 	

 if @w_max_div = 0 
    return 0

 select @w_min_div = min(dit_dividendo)
 from   ca_dividendo_tmp
 where  dit_operacion = @i_operacion
 and    dit_estado in ( @w_est_novigente,@w_est_vigente)


declare cursor_rubros_periodicos_dif 
 cursor for select
rot_concepto,
rot_valor,
rot_periodo,
rot_tperiodo,
rot_base_calculo,
rot_porcentaje
from  ca_rubro_op_tmp, ca_concepto
where rot_operacion = @i_operacion
and   rot_periodo is not null
and   rot_concepto  = co_concepto
and   co_categoria not in ('S','I','M')   -- Los seguros se generan con la periodicidad del interes
for read only

open cursor_rubros_periodicos_dif

fetch cursor_rubros_periodicos_dif into
@w_rot_concepto,
@w_rot_valor,
@w_rot_periodo,
@w_rot_tperiodo,
@w_rot_base_calculo,
@w_rot_porcentaje

--while @@fetch_status not in (-1,0 )
while @@fetch_status = 0
begin
   select @w_dias_periodo_rub = @w_dias_periodo_int * @w_rot_periodo
   
   if @w_dias_periodo_rub <= 30
      select @w_plazo_mes_div_uno = 1
   ELSE
   begin 
      select @w_plazo_mes_div_uno_a = (@w_dias_periodo_rub / 30)
      select @w_plazo_mes_div_uno_b = floor(@w_plazo_mes_div_uno_a) 
      select @w_residuo =  @w_plazo_mes_div_uno_a - @w_plazo_mes_div_uno_b
      if   @w_residuo > 0
         select   @w_plazo_mes_div_uno =  @w_plazo_mes_div_uno_b + 1
      else
         select   @w_plazo_mes_div_uno =  @w_plazo_mes_div_uno_b 
   end
   
   select @w_rot_valor = isnull((@w_rot_base_calculo * (@w_rot_porcentaje/100) )*  (@w_plazo_mes_div_uno/12 ),0)
   select @w_rot_valor = round(@w_rot_valor,@w_num_dec)
   
   update ca_rubro_op_tmp
   set    rot_valor = @w_rot_valor
   where  rot_operacion = @i_operacion
   and    rot_concepto  = @w_rot_concepto
   
	update ca_amortizacion_tmp
	set    amt_cuota     = 0,
	       amt_acumulado  =0
	from   ca_amortizacion_tmp
	where  amt_operacion = @i_operacion
	and    amt_concepto  = @w_rot_concepto	
   
   -- AQUI LA PRUEBA
   declare
       @w_dit_dividendo   int,
       @w_dit_dias_cuota  int,
       @w_rot_fpago       char(1),
       @w_dias_van        int,
       @w_dias_dif_uno    int,
       @w_ult_cuota       int
   
   select @w_ult_cuota = max(dit_dividendo)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion
   
   select @w_dias_div_uno = dit_dias_cuota
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion
   and    dit_dividendo = 1
   
   select @w_dias_van = 0
   
   if @w_dias_div_uno != @w_dias_periodo_int
      select @w_dias_dif_uno = @w_dias_div_uno
   else
      select @w_dias_dif_uno = 0
   
   select @w_rot_fpago = rot_fpago
   from   ca_rubro_op_tmp
   where  rot_operacion = @i_operacion
   and    rot_concepto  = @w_rot_concepto
   
   declare
       cur_div cursor
       for select dit_dividendo, dit_dias_cuota
           from   ca_dividendo_tmp
           where  dit_operacion = @i_operacion
           order  by dit_dividendo
       for read only
   
   open cur_div
   
   fetch cur_div
   into  @w_dit_dividendo, @w_dit_dias_cuota
   
   --while @@fetch_status not in (-1,0)
   while @@fetch_status = 0
   begin
      if @w_rot_fpago = 'A'
      begin
         if @w_dias_van = 0 -- PRIMERA CUOTA (ANTICIPADA)
         begin
            if (@w_dias_div_uno != @w_dias_periodo_int)
            begin
               if @w_dias_div_uno <= 30
                  select @w_plazo_mes_div_uno = 1
               ELSE
               begin 
                  select @w_plazo_mes_div_uno_a = (@w_dias_div_uno / 30)
                  select @w_plazo_mes_div_uno_b = floor(@w_plazo_mes_div_uno_a) 
                  select @w_residuo =  @w_plazo_mes_div_uno_a - @w_plazo_mes_div_uno_b
                  if   @w_residuo > 0
                     select   @w_plazo_mes_div_uno =  @w_plazo_mes_div_uno_b + 1
                  else
                     select   @w_plazo_mes_div_uno =  @w_plazo_mes_div_uno_b 
               end
               
               select @w_rot_valor_uno = isnull((@w_rot_base_calculo * (@w_rot_porcentaje/100) )*  (@w_plazo_mes_div_uno/12 ),0)
               select @w_rot_valor_uno = round(@w_rot_valor_uno,@w_num_dec)
            end
            ELSE
               select @w_rot_valor_uno = @w_rot_valor
            
            update ca_amortizacion_tmp
         	set    amt_cuota     = @w_rot_valor_uno,
         	       amt_acumulado = @w_rot_valor_uno
         	from   ca_amortizacion_tmp
         	where  amt_operacion = @i_operacion
         	and    amt_dividendo = @w_dit_dividendo
         	and    amt_concepto  = @w_rot_concepto
         end
         ELSE
         begin
            if ((@w_dias_van - @w_dias_dif_uno) % @w_dias_periodo_rub) = 0  --LPO Ajustes Migracion Core Digital
            begin
               if   @w_dit_dividendo = @w_ult_cuota
               and  @w_dit_dias_cuota != @w_dias_periodo_rub
                  select @w_rot_valor = round(@w_dit_dias_cuota * @w_rot_valor / (@w_dias_periodo_rub * 1.0), @w_num_dec)
               
               update ca_amortizacion_tmp
               set    amt_cuota     = @w_rot_valor,
                      amt_acumulado = @w_rot_valor
               from   ca_amortizacion_tmp
               where  amt_operacion = @i_operacion
               and    amt_dividendo = @w_dit_dividendo
               and    amt_concepto  = @w_rot_concepto	
            end
         end
      end
      
      if @w_rot_fpago = 'P'
      begin
         if ((@w_dias_van + @w_dit_dias_cuota - @w_dias_dif_uno) % @w_dias_periodo_rub) = 0  --LPO Ajustes Migracion Core Digital
         begin
            update ca_amortizacion_tmp
            set    amt_cuota     = @w_rot_valor,
                   amt_acumulado = @w_rot_valor
            from   ca_amortizacion_tmp
            where  amt_operacion = @i_operacion
            and    amt_dividendo = @w_dit_dividendo
            and    amt_concepto  = @w_rot_concepto	
         end
      end
      
      select @w_dias_van = @w_dias_van + @w_dit_dias_cuota
      
      fetch cur_div
      into  @w_dit_dividendo, @w_dit_dias_cuota
   end
   
   close cur_div
   deallocate cur_div
   goto  SIGUIENTE
   
 SIGUIENTE: 
 fetch   cursor_rubros_periodicos_dif 
 into
 @w_rot_concepto,
 @w_rot_valor,
 @w_rot_periodo,
 @w_rot_tperiodo,
 @w_rot_base_calculo,
 @w_rot_porcentaje


end 
close cursor_rubros_periodicos_dif
deallocate cursor_rubros_periodicos_dif

return 0
go
