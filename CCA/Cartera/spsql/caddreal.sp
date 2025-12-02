/************************************************************************/
/*	Archivo:		    caddreal.sp				                        */
/*	Stored procedure:	sp_dias_cuota_real     			                */
/*	Base de datos:		cob_cartera				                        */
/*	Producto: 		    Cartera					                        */
/*	Disenado por:  		Diego Aguilar Roman			                    */
/*	Fecha de escritura:	Jul. 1999 				                        */
/************************************************************************/
/*				IMPORTANTE				                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	    */
/*	'MACOSA'.							                                */
/*	Su uso no autorizado queda expresamente prohibido asi como	        */
/*	cualquier alteracion o agregado hecho por alguno de sus		        */
/*	usuarios sin el debido consentimiento por escrito de la 	        */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				PROPOSITO				                                */
/*	Cuando la base de calculo es Real da el # de dias de                */
/*      cada periodo tomando en cuenta los dias reales de cada mes	    */
/*                                                                      */
/************************************************************************/
/*				MODIFICACIONES				                            */
/*	FECHA		AUTOR		  RAZON				                        */
/*  - - -       N/R           Emisión Inicial                           */
/*  21/02/2021  K. Rodríguez  Días dividendo de tipos no divisibles a 30*/
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dias_cuota_real')
	drop proc sp_dias_cuota_real
go

create proc sp_dias_cuota_real
   @i_fecha_ini                    datetime,
   @i_dias_di                      int,
   @i_tdividendo                   char(1),
   @o_dias_di                      int = 0 out

as
declare 
   @w_sp_name                      descripcion,
   @w_return                       int,
   @w_error                        int,
   @w_num_cuotas                   int,
   @w_dias_mes                     int,
   @w_num_mes                      int,
   @w_dias_div			   int,	
   @w_count			   int,	
   @w_meses                        varchar(24)
   
   
/* CARGA DE VARIABLES INICIALES */
select @w_sp_name = 'sp_dias_cuota_real',
       @w_meses   = '312831303130313130313031'

if @i_tdividendo = 'D' begin
  
  select @o_dias_di = isnull(@i_dias_di,0)
  return 0
end


if @i_dias_di <= 15 or @i_dias_di % 30 <> 0 begin   -- KDR 21/02/2021 Para el cálculo de tipo dividendos no divisibles para 30 (35D)
   select @o_dias_di = @i_dias_di
   return 0
end

if (@i_dias_di / 30) < 1 begin
   select @w_num_cuotas = 1	
end
else
   select @w_num_cuotas = @i_dias_di / 30

select @w_count = 1,
       @w_dias_div = 0

select @w_num_mes = datepart(mm,@i_fecha_ini)

while @w_count <= @w_num_cuotas begin

  if @w_num_mes = 12
     select @w_num_mes = 1
  else
     if @w_count > 1
        select @w_num_mes = @w_num_mes + 1

  if @w_num_mes = 2 begin
     if (datepart(yy,@i_fecha_ini) % 4) = 0
        select @w_dias_mes = 29
     else
        select @w_dias_mes = 28
  end
  else
    select @w_dias_mes = convert(int,substring(@w_meses,(@w_num_mes * 2) - 1,2))
 

  select @i_fecha_ini = dateadd(dd,@w_dias_mes,@i_fecha_ini)
  select @w_dias_div = @w_dias_div + @w_dias_mes,
         @w_count = @w_count + 1

end

select @o_dias_di = isnull(@w_dias_div,0)

return 0

ERROR:

return @w_error
 
go
