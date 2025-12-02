/************************************************************************/
/*	Archivo:		    calplazo.sp				                        */
/*	Stored procedure:	sp_calcular_plazo  			                    */
/*	Base de datos:		cob_cartera				                        */
/*	Producto: 		    Cartera					                        */
/*	Disenado por:  		Fabian de la Torre			                    */
/*	Fecha de escritura:	Jul. 1997 				                        */
/************************************************************************/
/*				                IMPORTANTE				                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	'MACOSA'.							                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				                 PROPOSITO				                */
/*	Determina el numero de cuotas cuota de la tabla			            */
/*	de amortizacion.						                            */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calcular_plazo')
	drop proc sp_calcular_plazo  
go
create proc sp_calcular_plazo  
    @i_operacionca          int,
	@i_tipo_tabla           varchar(10)     = 'FRANCESA',
	@i_monto_cap            money 		= 0,
	@i_tasa_int	            float,
	@i_tdividendo           catalogo,
   	@i_periodo_cap          int 		= 1,
   	@i_periodo_int          int 		= 1,
	@i_gracia_cap           tinyint 	= 0,
	@i_dias_anio            smallint 	= 360,
	@i_cuota                money 		= 0,
    @i_capitaliza           char(1) 	= 'N', 
	@o_plazo                int out
as
declare @w_sp_name          descripcion,
	@w_return               int,
	@w_error                int,
	@w_dias_capital         int,
	@w_dias_interes         int,
	@w_money                money,
    @w_otros                money,
	@w_float                float,
	@w_factor_i             float,
	@w_adicionales          float,
	@w_factor               smallint


select @w_sp_name = 'sp_calcular_plazo'

--- CALCULAR NUMERO DE DIAS DE CAPITAL 
select @w_dias_capital =  td_factor * @i_periodo_cap
from ca_tdividendo 
where td_tdividendo = @i_tdividendo

--- CALCULAR NUMERO DE DIAS DE INTERES 
select @w_dias_interes =  td_factor * @i_periodo_int
from ca_tdividendo 
where td_tdividendo = @i_tdividendo

--- CALCULAR RELACION ENTRE PERIODOS DE GRACIA DE INTERES Y CAPITAL 
select @w_factor = @i_periodo_cap / @i_periodo_int

if @i_tipo_tabla = 'FRANCESA' begin

   --- CALCULAR VALOR RUBROS TIPO PORCENTAJE Y VALOR 

   select @w_otros = isnull(@w_otros,0)

   --- VALOR PRESENTE DE CUOTAS ADICIONALES  

   select 
   @w_adicionales = 0,
   @w_factor_i= @w_dias_interes * @i_tasa_int / (100.00*@i_dias_anio)
   
   select @w_adicionales = 
   isnull(sum(cat_cuota/(power(1+@w_factor_i, cat_dividendo))),0)
   from  ca_cuota_adicional_tmp
   where cat_operacion = @i_operacionca

   --- CALCULAR VALOR REDUCIDO DE CUOTA 
   select @w_factor_i= @w_dias_capital * @i_tasa_int / (100.00*@i_dias_anio)

   select @w_money = @i_cuota - @w_otros

   select @w_float = @w_money - @w_factor_i * (@i_monto_cap - @w_adicionales)
   
   --- VALOR NO ALCANZA A PAGAR EL PRESTAMO    
   if @w_float <= 0 begin
      if @i_capitaliza <> 'N'   -- AUMENTADO 01/Feb/99
         select @w_float = -1
      else 
      begin
         if @i_periodo_int = @i_periodo_cap
         begin
	         select @w_error = 710000
	         goto ERROR
         end
         else
         begin
            select @w_error = 722238
            goto ERROR
         end
      end
      if @i_periodo_int <> @i_periodo_cap
      begin
        select @w_error = 722238
        goto ERROR
      end
   end
   else
   begin
      if @i_periodo_int <> @i_periodo_cap
      begin
        select @w_error = 722238
        goto ERROR
      end
   end
          
   --- FORMULA PARA CALCULAR EL TIEMPO 
   if @w_float > 0 
      if @w_factor_i = 0.00
         select @w_float =(@i_monto_cap - @w_adicionales) / @w_money
      else
         select @w_float = (log(@w_money)-log(@w_float)) /log(@w_factor_i +1.00)
   else
      select @w_float = 555 --PARAMETRO NUMERO MAXIMO DE CUOTAS

end

if @i_tipo_tabla = 'ALEMANA' begin

   --- CUOTAS ADICIONALES  
   select @w_adicionales = 0

   select @w_adicionales = sum(isnull(cat_cuota,0))
   from  ca_cuota_adicional_tmp
   where cat_operacion = @i_operacionca

   select  @w_float = (@i_monto_cap - isnull(@w_adicionales,0)) / @i_cuota

end


--- TOMAR EN CUENTA PERIODOS DE GRACIA 
select @o_plazo = round(@w_float,0)

if @w_float > convert(float, @o_plazo)
   select @o_plazo = @o_plazo + 1

if @i_gracia_cap > 0
   select @o_plazo = @o_plazo + @i_gracia_cap
   
select @o_plazo = @o_plazo * @w_factor * @i_periodo_int


return 0

ERROR:
return @w_error

go

