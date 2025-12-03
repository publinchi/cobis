/************************************************************************/
/*	Archivo:		    sumarop.sp                                      */
/*	Stored procedure:	sp_sumarop                                      */
/*	Base de datos:		cob_cartera                                     */
/*	Producto: 		    Cartera                                         */
/*	Disenado por:  		R Garces                                        */
/*	Fecha de escritura:	Jul. 1997                                       */
/************************************************************************/
/*				IMPORTANTE                                              */
/*	Este programa es parte de los paquetes bancarios propiedad de       */
/*	"MACOSA".                                                           */
/*	Su uso no autorizado queda expresamente prohibido asi como          */
/*	cualquier alteracion o agregado hecho por alguno de sus             */
/*	usuarios sin el debido consentimiento por escrito de la             */
/*	Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*				PROPOSITO                                               */
/*	Suma dos tablas de amortizaciones temporales y el resultado         */
/*      se obtiene en una tercera temporal                              */
/*  Abr-04-2008  M.Roa  Se adiciono dit_fecha_can en insert a tmp       */ 
/************************************************************************/  
/*                         MODIFICACIONES                               */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/* **********************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_sumarop')
	drop proc sp_sumarop
go

create proc sp_sumarop
   @i_operacion_origen            int,
   @i_operacion_destino           int,
   @i_cotizacion_mop              float
 
as
declare 
   @w_sp_name                      descripcion,
   @w_return                       int,
   @w_error                        int,
   @w_dividendo                    int,
   @w_concepto			   catalogo,
   @w_cuota			   money, 
   @w_gracia			   money,
   @w_pagado 			   money,
   @w_acumulado			   money,
   @w_est_no_vigente               tinyint,
   @w_est_vigente                  tinyint,
   @w_periodo        		   int,
   @w_estado                       tinyint,
   @w_secuencial                   int,
   @w_div_ini                      int,
   @w_total_div                    smallint,
   @w_tipo_rotativo                varchar(30),
   @w_div_cap			   smallint,
   @w_tipo			   catalogo,
   @w_liquida_mn                   money,
   @w_correccion_mn                money,
   @w_correccion_sus_mn            money,
   @w_correc_pag_sus_mn            money,
   @w_cotizacion                   money,
   @w_monto                        money,
   @w_monto_aprobado               money,
   @w_monto_total                  money,
   @w_seguro_vida                  catalogo,
   @w_seguro_extra                 catalogo,
   @w_monto_cp                     money,
   @w_num_dec_mn                   tinyint,
   @w_rowcount                     int


/* CARGA DE VARIABLES INICIALES */
select @w_sp_name = 'sp_sumarop'

select 
@w_est_no_vigente = 0,
@w_est_vigente    = 1

/* SELECCIONES PARA PRESTAMOS ROTATIVOS */
select @w_tipo_rotativo = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ROT'
and   pa_producto = 'CCA' 
set transaction isolation level read uncommitted

select @w_tipo = opt_tipo  
from ca_operacion_tmp
where opt_operacion = @i_operacion_origen


/** NUMERO DE DECIMALES PARA MONEDA NACIONAL **/
select @w_num_dec_mn = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'DECMN'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 return 710076



/*PARA PRESTAMOS ROTATIVOS*/

if @w_tipo = @w_tipo_rotativo 
begin 
   select @w_total_div = count(*)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion_destino
end
else
begin
   select @w_total_div = count(*)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion_origen
end

select @w_div_ini = dit_dividendo 
from   ca_dividendo_tmp
where  dit_operacion = @i_operacion_destino
and    dit_estado    = @w_est_vigente

if @w_div_ini is null and @w_tipo = @w_tipo_rotativo
   select @w_div_ini = max(dit_dividendo)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion_destino
   
if exists (select 1 
           from   ca_dividendo_tmp A,ca_dividendo_tmp B
           where  A.dit_operacion = @i_operacion_origen 
           and    B.dit_operacion = @i_operacion_destino
           and    A.dit_dividendo = 1
           and    B.dit_dividendo = @w_div_ini
           and    A.dit_fecha_ven = B.dit_fecha_ven)
   select  @w_div_ini = @w_div_ini - 1

declare cursor_amortizacion cursor for
/*
select
amt_dividendo,         amt_concepto,          amt_cuota,
amt_gracia,	       amt_pagado,            amt_acumulado,
amt_periodo,           amt_estado,            amt_correccion_mn, 
amt_correccion_sus_mn, amt_correc_pag_sus_mn, amt_liquida_mn
from   ca_amortizacion_tmp
where  amt_operacion  = @i_operacion_origen
order  by amt_dividendo,amt_concepto
*/

-- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion

select
amt_dividendo,         amt_concepto,          amt_cuota,
amt_gracia,	       amt_pagado,            amt_acumulado,
amt_periodo,           amt_estado,            cot_correccion_mn, 
cot_correccion_sus_mn, cot_correc_pag_sus_mn, cot_liquida_mn
from   ca_amortizacion_tmp,ca_correccion_tmp
where  amt_operacion  = @i_operacion_origen
and    amt_operacion  = cot_operacion
and    amt_dividendo  = cot_dividendo
and    amt_concepto   = cot_concepto
order  by amt_dividendo,amt_concepto
for read only

-- fin cambio

open  cursor_amortizacion
fetch cursor_amortizacion into
@w_dividendo,      @w_concepto,           @w_cuota,
@w_gracia,         @w_pagado,             @w_acumulado,
@w_periodo,        @w_estado,             @w_liquida_mn,
@w_correccion_mn,  @w_correccion_sus_mn,  @w_correc_pag_sus_mn

while   @@fetch_status = 0 begin /*WHILE CURSOR PRINCIPAL*/   

   if (@@fetch_status = -1) begin
      select @w_error = 710004
      goto ERROR
   end           

   select @w_secuencial = max(amt_secuencia)
   from   ca_amortizacion_tmp
   where  amt_operacion = @i_operacion_destino
   and    amt_dividendo = @w_dividendo + @w_div_ini
   and    amt_concepto  = @w_concepto

   if exists (select 1
              from   ca_rubro_op_tmp 
              where  rot_operacion  = @i_operacion_destino
              and    rot_concepto   = @w_concepto
              and    rot_tipo_rubro = 'C')
      select 
      @w_liquida_mn = round(convert(float, @w_cuota) * convert(float, @i_cotizacion_mop), @w_num_dec_mn)
   else
      select @w_cotizacion = 0

/*    
   update ca_amortizacion_tmp set 
   amt_cuota             = amt_cuota + @w_cuota,
   amt_gracia            = amt_gracia + @w_gracia,
   amt_acumulado         = amt_acumulado + @w_acumulado,
   amt_pagado            = amt_pagado + @w_pagado, 
   amt_liquida_mn        = isnull(amt_liquida_mn,0) + isnull(@w_liquida_mn,0),
   amt_correccion_mn     = isnull(amt_correccion_mn,0) + isnull(@w_correccion_mn,0),
   amt_correccion_sus_mn = isnull(amt_correccion_sus_mn,0) + isnull(@w_correccion_sus_mn,0), 
   amt_correc_pag_sus_mn = isnull(amt_correc_pag_sus_mn,0) + isnull(@w_correc_pag_sus_mn,0)    
   where  amt_operacion  = @i_operacion_destino
   and    amt_dividendo  = @w_dividendo + @w_div_ini
   and    amt_concepto   = @w_concepto
   and    amt_secuencia  = @w_secuencial

*/

-- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion

   update ca_amortizacion_tmp set 
   amt_cuota             = amt_cuota + @w_cuota,
   amt_gracia            = amt_gracia + @w_gracia,
   amt_acumulado         = amt_acumulado + @w_acumulado,
   amt_pagado            = amt_pagado + @w_pagado
   from ca_amortizacion_tmp,ca_correccion_tmp
   where  amt_operacion  = @i_operacion_destino
   and    amt_dividendo  = @w_dividendo + @w_div_ini
   and    amt_concepto   = @w_concepto
   and    amt_secuencia  = @w_secuencial
   and    amt_operacion  = cot_operacion
   and    amt_dividendo  = cot_dividendo
   and    amt_concepto   = cot_concepto

/*xma*/

   update ca_correccion_tmp set 
   cot_liquida_mn        = isnull(cot_liquida_mn,0) + isnull(@w_liquida_mn,0),
   cot_correccion_mn     = isnull(cot_correccion_mn,0) + isnull(@w_correccion_mn,0),
   cot_correccion_sus_mn = isnull(cot_correccion_sus_mn,0) + isnull(@w_correccion_sus_mn,0), 
   cot_correc_pag_sus_mn = isnull(cot_correc_pag_sus_mn,0) + isnull(@w_correc_pag_sus_mn,0)    
   from ca_amortizacion_tmp,ca_correccion_tmp
   where  amt_operacion  = @i_operacion_destino
   and    amt_dividendo  = @w_dividendo + @w_div_ini
   and    amt_concepto   = @w_concepto
   and    amt_secuencia  = @w_secuencial
   and    amt_operacion  = cot_operacion
   and    amt_dividendo  = cot_dividendo
   and    amt_concepto   = cot_concepto
--fin cambio

   if @@error <> 0 begin
      select @w_error = 710003
      goto ERROR
   end          

   fetch cursor_amortizacion into
   @w_dividendo,     @w_concepto,          @w_cuota,
   @w_gracia,        @w_pagado,            @w_acumulado,
   @w_periodo,       @w_estado,            @w_liquida_mn,
   @w_correccion_mn, @w_correccion_sus_mn, @w_correc_pag_sus_mn

end  

close cursor_amortizacion
deallocate cursor_amortizacion


/* INSERCION DE DIVIDENDOS Y AMORTIZACIONES NUEVAS */
/* PARA PRESTAMOS ROTATIVOS */
if @w_tipo = @w_tipo_rotativo
begin
   insert into ca_dividendo_tmp
   select 
   @i_operacion_destino,      dit_dividendo + @w_div_ini,    dit_fecha_ini,
   dit_fecha_ven,             dit_de_capital,                dit_de_interes,
   dit_gracia,                dit_gracia_disp,               dit_estado,
   dit_dias_cuota,            dit_intento,                   dit_prorroga,
   dit_fecha_can
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion_origen
   and    dit_dividendo > @w_total_div - @w_div_ini 

   if @@error !=0 return 710002

/*
   insert into ca_amortizacion_tmp
   select 
   @i_operacion_destino,  amt_dividendo + @w_div_ini ,amt_concepto,
   amt_estado,            amt_periodo,amt_cuota,      amt_gracia,
   amt_pagado,            amt_acumulado,              
   amt_secuencia,         amt_correccion_mn,          amt_correccion_sus_mn, 
   amt_correc_pag_sus_mn, amt_liquida_mn
   from   ca_amortizacion_tmp
   where  amt_operacion = @i_operacion_origen
   and    amt_dividendo > @w_total_div - @w_div_ini
*/
-- cambio de los campos am_correccion_xxx a la nueva tabla ca_correccion

   insert into ca_amortizacion_tmp
   select 
   @i_operacion_destino,  amt_dividendo + @w_div_ini ,amt_concepto,
   amt_estado,            amt_periodo,amt_cuota,      amt_gracia,
   amt_pagado,            amt_acumulado,              
   amt_secuencia
   from   ca_amortizacion_tmp
   where  amt_operacion = @i_operacion_origen
   and    amt_dividendo > @w_total_div - @w_div_ini

  if exists (select 1 from ca_correccion_tmp,ca_amortizacion_tmp 
	 where cot_operacion = @i_operacion_origen and cot_operacion = amt_operacion)
   begin
	insert into ca_correccion_tmp(
   	cot_operacion,	    cot_dividendo,	     cot_concepto,
   	cot_correccion_mn,  cot_correccion_sus_mn,   cot_correc_pag_sus_mn,
   	cot_liquida_mn)
	select
   	cot_operacion,	    cot_dividendo,	     cot_concepto,
   	cot_correccion_mn,  cot_correccion_sus_mn,   cot_correc_pag_sus_mn,
   	cot_liquida_mn   	
        from ca_correccion_tmp
   	where cot_operacion = @i_operacion_origen
        and cot_dividendo > @w_total_div - @w_div_ini

   end

-- fin cambio

   if @@error !=0 return 710002

   /*ACTUALIZACION DEL PLAZO,TIPO DE PLAZO Y DIV_CAP DE LA OPERACION*/
   /*update ca_operacion_tmp
   set --opt_divcap_original = count(*),
       opt_tplazo          = opt_tdividendo,
       opt_plazo           = count(*),
       opt_fecha_fin       = max(dit_fecha_ven)
   from ca_dividendo_tmp
   where dit_operacion     = @i_operacion_destino
   and   opt_operacion     = @i_operacion_destino    
   and   dit_de_capital    = 'S'
   
end*/
/***********************INICIO TRANFORMACION SQL 2005****************************/

update cob_cartera..ca_operacion_tmp
set --opt_divcap_original = count(*),
       opt_tplazo          = opt_tdividendo,
       opt_plazo           = ssma_aggr.conteo,
       opt_fecha_fin       = ssma_aggr.maxfecha
from
(
select count(*) as conteo,max(dit_fecha_ven) as maxfecha
from cob_cartera..ca_dividendo_tmp,cob_cartera..ca_operacion_tmp
where dit_operacion			= @i_operacion_destino
	  and opt_operacion     = @i_operacion_destino    
      and dit_de_capital    = 'S'
) ssma_aggr
where opt_operacion >= 0

end
/***********************FIN TRANFORMACION SQL 2005****************************/
update B
set    B.rot_valor = B.rot_valor + A.rot_valor
from   ca_rubro_op_tmp B,ca_rubro_op_tmp A
where  B.rot_operacion = @i_operacion_destino
and    A.rot_operacion = @i_operacion_origen
and    A.rot_concepto  = B.rot_concepto
and   (A.rot_tipo_rubro = 'C' or A.rot_fpago = 'L')

if @@error <> 0 begin
   select @w_error = 710002
   goto ERROR
end 


update B set
B.opt_monto       = B.opt_monto + A.opt_monto,
B.opt_cuota       = B.opt_cuota + A.opt_cuota
from   ca_operacion_tmp B,ca_operacion_tmp A
where  B.opt_operacion   = @i_operacion_destino
and    A.opt_operacion   = @i_operacion_origen

if @@error <> 0 begin
   select @w_error = 710002
   goto ERROR
end          

return 0

ERROR:

return @w_error
 
go
