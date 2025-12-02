/************************************************************************/
/*	Archivo:		intpasma.sp				*/
/*	Stored procedure:	sp_int_pasivas_manuales   		*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Elcira Pelaez          			*/
/*	Fecha de escritura:	Jun. 2003 				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Recalcula el interes para operaciones pasivas con tabla manual  */
/*									*/
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_int_pasivas_manuales')
	drop proc sp_int_pasivas_manuales
go

create proc sp_int_pasivas_manuales
@i_operacionca                  int

 
as
declare 
@w_sp_name			   descripcion,
@w_return			   int,
@w_error			   int,
@w_di_num_dias                  int,
@w_dividendo                    int,
@w_cont_cap                     int,
@w_cont_int                     int,
@w_cuota_cap                    money,
@w_float                        money,
@w_monto_cap                    money,
@w_saldo_cap                    money,
@w_cap_aux                      money,
@w_int_aux                      money,
@w_valor_rubro                  money,
@w_porcentaje                   money,
@w_valor_calc                   float,
@w_valor_grcap                  money,
@w_valor_grint                  money,
@w_valor_gr                     money,
@w_int_total                    money,
@w_di_fecha_ini                 datetime,
@w_di_fecha_ven                 datetime,
@w_concepto                     catalogo,
@w_estado                       tinyint,
@w_tipo_rubro                   char(1),
@w_fpago                        char(1),
@w_de_capital                   char(1),
@w_de_interes                   char(1),
@w_aux                          tinyint,
@w_est_no_vigente	        tinyint, 
@w_est_vigente		        tinyint,
@w_referencial_reajuste         catalogo,
@w_signo_reajuste               char(1),
@w_factor_reajuste              float,
@w_porcentaje_reajuste          float,
@w_porcentaje_efa               float,
@w_valor_referencial            float,
@w_dias_despues		        int,
@w_dias_antes		        int,
@w_max_secuencia                tinyint,
@w_di_vigente                   smallint,
@w_am_cuota                     money,
@w_am_acumulado                 money,
@w_causacion                    char(1),
@w_dias_int                     int,    
@w_tasa_equivalente             char(1),
@w_int_total_eq                 money,
@w_moneda                       smallint,
@w_num_dec                      smallint,
@w_moneda_nac                   smallint,
@w_num_dec_mn                   smallint,
@w_am_estado                    int,
@w_ro_concepto                  cuenta,
@w_dif_prv                      money,
@w_secuencial                   int



/* CARGA DE VARIABLES INICIALES */
select @w_sp_name   = 'sp_int_pasivas_manuales'

/* DEFINICION DE ESTADOS */
select @w_est_no_vigente = 0,
       @w_est_vigente    = 1

select @w_causacion = op_causacion,
       @w_tasa_equivalente = op_usar_tequivalente,
       @w_moneda           = op_moneda
from ca_operacion 
where op_operacion = @i_operacionca


/* MANEJO DE DECIMALES PARA LA MONEDA DE LA OPERACION */
/** MANEJO DE DECIMALES **/
exec @w_return = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out,
@o_mon_nacional = @w_moneda_nac out,
@o_dec_nacional = @w_num_dec_mn out

if @w_return <> 0 return @w_return




/* CALCULAR EL MONTO DEL CAPITAL TOTAL */
select @w_monto_cap = sum(am_cuota+am_gracia-am_pagado)
from ca_amortizacion,ca_rubro_op
where ro_operacion  = @i_operacionca
and   ro_tipo_rubro = 'C'
and   am_operacion = @i_operacionca
and   am_concepto  = ro_concepto 


/* CALCULAR EL PORCENTAJE DE INTERES TOTAL */
select @w_int_total = sum(ro_porcentaje)
from ca_rubro_op
where ro_operacion = @i_operacionca
and   ro_tipo_rubro = 'I'
and   ro_fpago      in ('P','A') -- PERIODICO VENCIDO O ANTICIPADO
if @w_int_total <= 0 begin
      select @w_int_total = 0
/*      PRINT 'intpasma.sp @w_int_total %1!',@w_int_total
      select @w_error = 710119
      goto ERROR*/
end


/* LAZO PRINCIPAL DE DIVIDENDOS */
select 
@w_saldo_cap = @w_monto_cap,
@w_cont_cap  = 0,
@w_cont_int  = 0

declare cursor_dividendo cursor for
select
di_dividendo,  di_fecha_ini,  di_fecha_ven,
di_de_capital, di_de_interes, di_estado, di_dias_cuota
from   ca_dividendo
where  di_operacion  = @i_operacionca
for read only

open  cursor_dividendo
fetch cursor_dividendo into
@w_dividendo,  @w_di_fecha_ini, @w_di_fecha_ven,
@w_de_capital, @w_de_interes,   @w_estado, @w_di_num_dias


while   @@fetch_status = 0 begin /*WHILE CURSOR PRINCIPAL*/

   if (@@fetch_status = -1) begin
      select @w_error = 710004
      goto ERROR
   end


   select 
   @w_cap_aux = @w_monto_cap,
   @w_int_aux = @w_int_total


   /* CURSOR DE RUBROS TABLA CA_RUBRO_OP */
   declare cursor_rubros cursor for
   select
   ro_concepto,   ro_tipo_rubro, ro_porcentaje, ro_valor,ro_fpago 
   from   ca_rubro_op
   where  ro_operacion  = @i_operacionca
   and    ro_fpago      in ('P','A') -- PERIODICO VENCIDO O ANTICIPADO
   and    ro_tipo_rubro in ('I') 
   order by ro_tipo_rubro desc
   for read only

   open  cursor_rubros
   fetch cursor_rubros into
   @w_concepto, @w_tipo_rubro, @w_porcentaje, @w_valor_rubro,@w_fpago
   
   while   @@fetch_status = 0 
   begin /*WHILE CURSOR RUBROS*/
   
      if (@@fetch_status = -1) begin
         select @w_error = 710004
         goto ERROR
      end

   ---PRINT 'intpasma.sp  antes de sp_calc_intereses @w_int_total %1!,@w_dividendo %2!',@w_int_total,@w_dividendo

   exec @w_return = sp_calc_intereses
   @tasa          = @w_int_total,
   @monto         = @w_saldo_cap,
   @dias_anio     = 360,
   @num_dias      = @w_di_num_dias,
   @causacion     = 'L',
   @intereses     = @w_valor_calc out
 
   if @w_return != 0 return @w_return

   select @w_valor_calc = round (@w_valor_calc,@w_num_dec)
  
   if @w_valor_calc >= 0 begin

      	update ca_amortizacion 
	      set    am_cuota     = @w_valor_calc
	      where  am_operacion = @i_operacionca  
	      and    am_dividendo = @w_dividendo
	      and    am_concepto  = @w_concepto

	      if (@@error <> 0)       begin
	        select @w_error = 710003
	        goto ERROR
      	      end

    end

      fetch cursor_rubros into
      @w_concepto, @w_tipo_rubro, @w_porcentaje, @w_valor_rubro,@w_fpago
   
   end /*WHILE CURSOR RUBROS*/
   close cursor_rubros
   deallocate cursor_rubros


   /* DISMINUIR AL SALDO DE CAPITAL LA CUOTA DE CAPITAL DEL DIV ACTUAL */
   select @w_valor_calc = sum(am_cuota+am_gracia-am_pagado)
   from   ca_amortizacion,ca_rubro_op
   where  am_operacion = @i_operacionca
   and    am_dividendo = @w_dividendo
   and    ro_operacion = @i_operacionca
   and    ro_concepto  = am_concepto
   and    ro_tipo_rubro= 'C'
   and    ro_fpago     in ('P','A')

   select @w_saldo_cap  = @w_saldo_cap - @w_valor_calc
  
   fetch   cursor_dividendo into
   @w_dividendo,  @w_di_fecha_ini, @w_di_fecha_ven,
   @w_de_capital, @w_de_interes,   @w_estado,@w_di_num_dias
   

end /*WHILE CURSOR DIVIDENDOS*/
close cursor_dividendo
deallocate cursor_dividendo

return 0

ERROR:

return @w_error
 
go


