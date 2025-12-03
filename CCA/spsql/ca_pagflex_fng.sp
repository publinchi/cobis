/************************************************************************/
/*   Archivo:            ca_pagflex_fng.sp                              */
/*   Stored procedure:   sp_ca_pagflex_fng                              */
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
/*   Procedimiento  que calcula el FNG para las tablas FLEXIBLES        */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA           AUTOR      RAZON                                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca_pagflex_fng')
   drop proc sp_ca_pagflex_fng
go

create proc sp_ca_pagflex_fng
@s_user              login,
@s_term              varchar(30),
@s_date              datetime, 
@s_ofi               int,
@i_operacionca       int,
@i_num_dec           int = 0

  
   
as
declare 
@w_moneda               smallint,
@w_op_monto             money,
@w_di_dividendo         int,
@w_di_fecha_ini         datetime,
@w_di_fecha_ven         datetime,
@w_di_estado            int,
@w_valor_fng            money,
@w_factor               float,
@w_porcentaje           float,
@w_fecha_fin            datetime,
@w_periodo_fng          tinyint,   
@w_cod_gar_fng          catalogo,
@w_parametro_fng        catalogo,
@w_fecha_ult_proceso    datetime,
@w_error                int,
@w_tdividendo           catalogo, 
@w_freq_cobro           int,      
@w_saldo_cap            money,    
@w_div_despl            smallint, 
@w_periodo_int          smallint, 
@w_di_dias_cuota        smallint,
@w_periodo_cal_fng      smallint,
@w_parametro_iva_fng    catalogo,
@w_estado               catalogo,
@w_dias_periodo         smallint,
@w_tramite              int,
@w_dias_cuota_faltan    int,
@w_dias_totales         int,
@w_porcentaje_aso       float,
@w_valor_no_vig         money,
@w_valor_asociado       money

select 
@w_valor_fng         = 0,
@w_porcentaje        = 0,
@w_dias_cuota_faltan = 0,
@w_saldo_cap         = 0,
@w_dias_totales      = 0

--- PARAMETRO PERIODICIDAD COBRO FNG 
select @w_periodo_fng = pa_tinyint
  from cobis..cl_parametro 
 where pa_nemonico = 'PERFNG'
   and pa_producto = 'CCA'

select @w_cod_gar_fng = pa_char
from cobis..cl_parametro with (nolock)
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG'

select @w_parametro_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

select @w_parametro_iva_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG'

select @w_porcentaje_aso = 0
select @w_porcentaje_aso = ro_porcentaje
from   ca_rubro_op
where  ro_operacion  = @i_operacionca
and    ro_concepto   = @w_parametro_iva_fng
  

--- DATOS OPERACION 
select 
@w_fecha_fin         = op_fecha_fin,
@w_op_monto          = op_monto,
@w_moneda            = op_moneda,
@w_tdividendo        = op_tdividendo,
@w_tramite           = op_tramite,         
@w_periodo_int       = op_periodo_int
from   ca_operacion
where  op_operacion    = @i_operacionca

---VALIDAR QUE LA GARANTIA ESTE VIGENTE CASO CONTRARIO EL VALRO PASA A 0
---POR QUE PUEDE HABER RECONOCIMIENTO DE GARANTIAS

select tc_tipo as tipo into #calfng
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng


select @w_estado = cu_estado
from cob_custodia..cu_custodia, 
cob_credito..cr_gar_propuesta, 
cob_credito..cr_tramite
where gp_tramite  = @w_tramite
and gp_garantia = cu_codigo_externo 
and cu_estado   in ('P','F','V')
and tr_tramite  = gp_tramite
and cu_tipo in (select tipo from #calfng)
if @@rowcount = 0
begin   

   update ca_amortizacion with (rowlock) set 
   am_cuota     = case when am_pagado > 0 then am_pagado else 0 end,
   am_acumulado = case when am_pagado > 0 then am_pagado else 0 end
   where  am_operacion = @i_operacionca
   and    am_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)
   and    am_estado <> 3
   if @@error <> 0
     return 724020
   else 
   begin
     PRINT 'ca_pagflex_fng.sp No tiene Garantia'
     return 0
   end
end
ELSE
begin
   ---LOS VALORES DEBEN PONERSER EN 0 PARA LUEGO RECALCULARLOS NUEVAMENTE
   
   update ca_amortizacion with (rowlock) set 
   am_cuota     = case when am_pagado > 0 then am_pagado else 0 end,
   am_acumulado = case when am_pagado > 0 then am_pagado else 0 end
   where  am_operacion = @i_operacionca
   and    am_concepto  in (@w_parametro_fng,@w_parametro_iva_fng)
   and    am_estado <> 3
   if @@error <> 0
     return 724025
end

select @w_periodo_cal_fng = @w_periodo_fng * 30
     
select @w_factor = ro_porcentaje
from ca_rubro_op
where ro_operacion = @i_operacionca
and   ro_concepto  = @w_parametro_fng

select @w_dias_periodo = 0

--- CURSOR DE DIVIDENDOS 
declare cur_flexible_fng cursor for 
select 
di_dividendo,          
di_fecha_ini,       
di_fecha_ven,
di_estado,
di_dias_cuota
from  ca_dividendo
where di_operacion = @i_operacionca
order by di_dividendo asc
for read only

open    cur_flexible_fng
fetch   cur_flexible_fng
into    
@w_di_dividendo,        
@w_di_fecha_ini,     
@w_di_fecha_ven,
@w_di_estado,
@w_di_dias_cuota

/* WHILE CURSOR PRINCIPAL */
while @@fetch_status = 0 
begin
     
      select @w_saldo_cap = sum(am_cuota - am_pagado)
      from   ca_amortizacion, ca_rubro_op
      where  am_operacion  = @i_operacionca
      and    ro_operacion  = am_operacion
      and    am_dividendo >= @w_di_dividendo 
      and    ro_concepto   = am_concepto 
      and    ro_tipo_rubro = 'C'

     select @w_dias_periodo = @w_dias_periodo + @w_di_dias_cuota
      
     if ( @w_dias_periodo >= @w_periodo_cal_fng ) 
     begin
     
       select @w_dias_cuota_faltan = sum(di_dias_cuota )
       from ca_dividendo 
       where di_operacion = @i_operacionca
       and di_dividendo >= @w_di_dividendo
            
       if @w_dias_cuota_faltan >= @w_periodo_cal_fng
       begin
	       select @w_valor_fng = round((@w_saldo_cap * @w_factor / 100.0), @i_num_dec)
	       ---PRINT 'ca_pagflex_fng.sp : ' + cast (@w_di_dividendo as varchar)  + ' dias_pe : ' + cast (@w_dias_periodo as varchar)  + ' DIAFALTA: ' + cast (@w_dias_cuota_faltan as varchar) + ' Vlorfng: ' + cast ( @w_valor_fng as varchar)

       end
       else
       begin
	       select @w_valor_fng = round((((@w_saldo_cap * @w_factor / 100.0) / @w_periodo_cal_fng) * @w_dias_cuota_faltan), @i_num_dec)
	       ---PRINT 'ca_pagflex_fng.sp else : ' + cast (@w_di_dividendo as varchar)  + ' dias_per : ' + cast (@w_dias_periodo as varchar)  + ' DIASFALTA: ' + cast (@w_dias_cuota_faltan as varchar)  + ' Vlorfng: ' + cast ( @w_valor_fng as varchar)
       end
       
              
       if  (@w_valor_fng > 0) and (@w_di_estado in (1,0))
       begin ---INSERTAR EL VALOR O ACTUALIZARLO
                 if @w_di_estado = 1
                     select @w_valor_no_vig = @w_valor_fng
                  else
                     select @w_valor_no_vig = 0	            
	           
	            if exists (select 1 from ca_amortizacion
	                       where am_operacion = @i_operacionca 
	                       and am_dividendo = @w_di_dividendo
	                       and  am_concepto  = @w_parametro_fng)
	            begin                  
		            update ca_amortizacion set 
			        am_cuota     = @w_valor_fng,
			        am_acumulado = @w_valor_no_vig
				    where am_operacion = @i_operacionca
				    and   am_concepto = @w_parametro_fng
				    and   am_dividendo = @w_di_dividendo
				    and   am_estado  <> 3
				    and   am_pagado = 0	        
				    
                    if (@@error <> 0) begin
			            close cur_flexible_fng
			            deallocate cur_flexible_fng
			            return 724021
                    end				 
			    end
			    ELSE
			    begin
    	             insert into ca_amortizacion with (rowlock)
		               (am_operacion,   am_dividendo,   am_concepto,
		                am_cuota,       am_gracia,      am_pagado,
		                am_acumulado,   am_estado,      am_periodo,
		                am_secuencia)
   		             values(@i_operacionca,    @w_di_dividendo, @w_parametro_fng,
		                    @w_valor_fng,    0,               0,
		                    @w_valor_no_vig ,  @w_di_estado,    0,
		                    1 )
                     if (@@error <> 0) begin
			            close cur_flexible_fng
			            deallocate cur_flexible_fng
			            return 724022
                     end				 	
			    end 
			    ---VALOR ASOCIADO
			    if @w_porcentaje_aso > 0
			    begin
                    select @w_valor_asociado = round((@w_valor_fng * @w_porcentaje_aso / 100.0), @i_num_dec)
	                 if @w_di_estado = 1
	                     select @w_valor_no_vig = @w_valor_asociado
	                  else
	                     select @w_valor_no_vig = 0	            
                                         
		            if exists (select 1 from ca_amortizacion
		                       where am_operacion = @i_operacionca 
		                       and am_dividendo = @w_di_dividendo
		                       and  am_concepto  = @w_parametro_iva_fng)
		            begin                  
			            update ca_amortizacion set 
				        am_cuota     = @w_valor_asociado,
				        am_acumulado = @w_valor_no_vig
					    where am_operacion = @i_operacionca
					    and   am_concepto = @w_parametro_iva_fng
					    and   am_dividendo = @w_di_dividendo
					    and   am_estado  <> 3
					    and   am_pagado = 0	        
					    
	                    if (@@error <> 0) begin
				            close cur_flexible_fng
				            deallocate cur_flexible_fng
				            return 724023
	                    end				 
				    end
				    ELSE
				    begin
	    	             insert into ca_amortizacion with (rowlock)
			               (am_operacion,   am_dividendo,   am_concepto,
			                am_cuota,       am_gracia,      am_pagado,
			                am_acumulado,   am_estado,      am_periodo,
			                am_secuencia)
	   		             values(@i_operacionca,    @w_di_dividendo, @w_parametro_iva_fng,
			                    @w_valor_asociado, 0,               0,
			                    @w_valor_no_vig ,  @w_di_estado,    0,
			                    1 )
	                     if (@@error <> 0) begin
				            close cur_flexible_fng
				            deallocate cur_flexible_fng
				            return 724024
	                     end				 	
				    end 
                  
			    end --ASOCIADO
			             
       end ---INSERTAR EL VALOR O ACTUALIZARLO
        select @w_valor_fng          = 0,
		        @w_valor_asociado    = 0,
		        @w_saldo_cap         = 0,
		        @w_dias_periodo      = 0,
		        @w_dias_cuota_faltan = 0

     end ---VALIDACION GENERAL HAY QUE INSERTAR
         
     ---INICIALIZO VARIABLE DE CALCULO 
   
   fetch   cur_flexible_fng
   into    
   @w_di_dividendo,        
   @w_di_fecha_ini,     
   @w_di_fecha_ven,
   @w_di_estado,
   @w_di_dias_cuota

end /*WHILE CURSOR RUBROS SFIJOS*/

close cur_flexible_fng
deallocate cur_flexible_fng   
return 0   
go
