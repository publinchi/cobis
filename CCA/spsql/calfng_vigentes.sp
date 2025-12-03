/************************************************************************/
/*      Archivo:                calfng_vigentes.sp                      */
/*      Stored procedure:       sp_calulo_fng_vigentes                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Fecha de escritura:     Marzo 2010                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Recalculo de comision Mipymes, Comision FNG y Seguros deudores  */
/*      vencido                                                         */
/*                              CAMBIOS                                 */
/* FECHA        AUTOR               CAMBIO                              */
/* 16/03/2012   Luis Carlos Moreno  REQ 293 - No recalcular comision FNG*/
/*                                  a las cuotas pendientes cuando la   */
/*                                  obligacion tiene reconocimiento     */
/* 03/02/2020   Luis Ponce          Ajustes Migracion Core Digital      */
/************************************************************************/  
use cob_cartera
go

set ansi_nulls off
go

if exists(select 1 from sysobjects where name = 'sp_calulo_fng_vigentes')
   drop proc sp_calulo_fng_vigentes
go
--- INC 117535 OCT.15.2014

create proc sp_calulo_fng_vigentes
    @i_operacionca          int,
    @i_concepto             catalogo


as
declare
    @w_sp_name              varchar(30),
    @w_return               int,
    @w_num_dec              smallint,
    @w_moneda               smallint,
    @w_fecha_liq            datetime,
    @w_op_monto             money,
    @w_di_dividendo         int,
    @w_di_fecha_ven         datetime,
    @w_valor_rubro          money,
    @w_factor_rubro         float,
    @w_asociado             catalogo,
    @w_porcentaje           float,
    @w_valor_asociado       money,
    @w_plazo_restante       int,
    @w_fecha_fin            datetime,
    @w_saldo_capital        money,
    @w_fpago_seg            char(1),
    @w_error                int,
    @w_fecha_ult_proceso    smalldatetime,
    @w_freq_cobro           int,
    @w_tdividendo           catalogo,
    @w_periodo_fng          tinyint,
    @w_concepto_fng         catalogo,
    @w_di_estado            tinyint,
    @w_max_dividendo_c      int,
    @w_max_dividendo        int,
    @w_valor_no_vig         money,
    @w_div_vigente          int,
    @w_est_vigente          tinyint,
    @w_cod_gar_fng          catalogo,    
    @w_est_cancelado        tinyint,
    @w_parametro_iva_fng    catalogo,
    @w_parametro_fng_des    catalogo,
    @w_monto_parametro      float,
    @w_tramite              int,
    @w_SMV                  money,
    @w_msg				    descripcion,
    @w_dividendo            tinyint,
    @w_fecha_hoy            datetime,
    @w_concepto             catalogo,
    @w_cuota                money,
    @w_codvalor             int,
    @w_periodo_int          smallint,
    @w_monto_prv            money  ,
    @w_estado               char(1)


/** INICIALIZACION VARIABLES **/
select 
    @w_sp_name              = 'sp_calulo_fng_vigentes',
    @w_valor_rubro          = 0,
    @w_porcentaje           = 0,
    @w_valor_asociado       = 0,
    @w_asociado             = '',
    @w_plazo_restante       = 0,
    @w_monto_prv            = 0

    /* ESTADOS DE CARTERA */
exec  sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_cancelado  = @w_est_cancelado out


select @w_cod_gar_fng = pa_char
from cobis..cl_parametro
where pa_producto  = 'GAR'
and   pa_nemonico  = 'CODFNG' 
  
select @w_parametro_iva_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'IVAFNG'

 

/** DATOS OPERACION **/
select @w_fecha_liq         = op_fecha_liq,
       @w_fecha_fin         = op_fecha_fin,
       @w_op_monto          = op_monto,
       @w_moneda            = op_moneda,
       @w_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_tdividendo        = op_tdividendo,
       @w_tramite           = op_tramite,
       @w_periodo_int       = op_periodo_int
from   ca_operacion
where  op_operacion = @i_operacionca


--- PARAMETRO PERIODICIDAD COBRO FNG 
select @w_periodo_fng = pa_tinyint
  from cobis..cl_parametro 
 where pa_nemonico = 'PERFNG'
   and pa_producto = 'CCA'

    if @@rowcount = 0 
       return 708192
   
select @w_concepto_fng = pa_char   
 from cobis..cl_parametro
where pa_nemonico = 'COMFNG'
 and pa_producto = 'CCA'  
 set transaction isolation level read uncommitted


 
select @w_parametro_fng_des = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COFNGD'
set transaction isolation level read uncommitted


 select tc_tipo as tipo into #calfng
from cob_custodia..cu_tipo_custodia
where  tc_tipo_superior  = @w_cod_gar_fng

select @w_estado = cu_estado
from cob_custodia..cu_custodia, 
cob_credito..cr_gar_propuesta, 
cob_credito..cr_tramite
where gp_tramite  = @w_tramite
and gp_garantia = cu_codigo_externo 
and cu_estado   in ('P','F','V','X','C')
and tr_tramite  = gp_tramite
and cu_tipo in (select tipo from #calfng)
if @@rowcount = 0
begin   
  ---print 'NO TIENE GARANTIAAAAAAAAAAAAAAAAAAAAAAAAAAAAA PONE VALORES EN 0'
  
   update ca_amortizacion with (rowlock) set 
   am_cuota     = case when am_pagado > 0 then am_pagado else 0 end,
   am_acumulado = case when am_pagado > 0 then am_pagado else 0 end
   where  am_operacion = @i_operacionca
   and    am_concepto  in (@w_concepto_fng,@w_parametro_iva_fng)
   if @@error <> 0
      return 724401
   else begin
      ---print 'NO TIENE GARANTIAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
      return 0
   end
end

select @w_freq_cobro = @w_periodo_int * td_factor / 30
  from ca_tdividendo
 where td_tdividendo = @w_tdividendo
 
select @w_freq_cobro = @w_periodo_fng / @w_freq_cobro


/* VERIFICA SI EL RUBRO TIENE RUBRO ASOCIADO */
if exists (select 1
           from   ca_rubro_op
           where  ro_operacion         = @i_operacionca
           and    ro_concepto_asociado = @i_concepto)
begin
   select 
   @w_asociado   = ro_concepto,
   @w_porcentaje = ro_porcentaje
   from   ca_rubro_op
   where  ro_operacion         = @i_operacionca
   and    ro_concepto_asociado = @i_concepto
end


/* OBTENER LA FECHA DE VENCIMIENTO FINAL DESDE ca_dividendo */
select @w_fecha_fin = max(di_fecha_ven)
from  ca_dividendo
where di_operacion = @i_operacionca

      
/* NUMERO DE DECIMALES */
exec @w_return = sp_decimales
    @i_moneda      = @w_moneda,
    @o_decimales   = @w_num_dec out

if @w_return != 0 return  @w_return


/* OBTENER FACTOR DE CALCULO DE LOS RUBROS */
select @w_factor_rubro = ro_porcentaje,
       @w_fpago_seg    = ro_fpago
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_concepto  = @i_concepto

if @w_factor_rubro  = 0 
begin

	/*PARAMETRO SALARIO MINIMO VITAL VIGENTE*/
	select @w_SMV      = pa_money 
	from   cobis..cl_parametro with (nolock)
	where  pa_producto  = 'ADM'
	and    pa_nemonico  = 'SMV'

	 select @w_monto_parametro  = @w_op_monto/@w_SMV

   exec @w_error  = sp_matriz_valor
   @i_matriz      = @w_concepto_fng,      
   @i_fecha_vig   = @w_fecha_liq,  
   @i_eje1        = @w_monto_parametro,  
   @o_valor       = @w_factor_rubro out, 
   @o_msg         = @w_msg    out 
         
   if @w_error <> 0  return @w_error
   
   ---print 'calfng_vigentes.sp llego aponer el @w_factor_rubro ' + CAST(@w_factor_rubro as varchar)
   
   update ca_rubro_op set   
   ro_porcentaje      = @w_factor_rubro,
   ro_porcentaje_aux  = @w_factor_rubro
   where ro_operacion = @i_operacionca
   and   ro_concepto  in (@w_concepto_fng,@w_parametro_fng_des)
   if @@error <> 0
      return 720002
end
   
delete ca_base_rubros_p
where rp_operacion = @i_operacionca
   
--LA TABLA ca_base_rubros_p SE CARGA POR CADA OEPRACION QUE TENGA ABONO EXTRAORDINARIO
--PARA ALMACENAR COMO ESTABA LA TABLA ANTES DEL PAGO EXTRAORDINARIO  Y RESPETAR 
--ESTAS FECHAS UNA VEZ SE REGENERE LA TABLA

 select @w_div_vigente = isnull(max(di_dividendo),0)
from  ca_dividendo
where di_operacion  = @i_operacionca
and   di_estado = @w_est_vigente

---print 'calfng_vigentes.sp  @w_div_vigente ' + CAST(@w_div_vigente as varchar) + ' @w_est_cancelado . ' + cast ( @w_est_cancelado as varchar)

if @w_div_vigente = 0
return 0

---PRINT 'calfng_vigentes.sp   llego con @i_concepto     ' + CAST(@i_concepto  as varchar) 
  

 declare 
   Cur_identificar cursor
   for select  
        di_dividendo,
        di_estado
   from ca_dividendo
   where di_operacion = @i_operacionca
   and    di_dividendo >= @w_div_vigente ---EL VIGENTE Y LOS ANTERIORES YA ESTAN REGISTRADOS

	open Cur_identificar
	
	fetch Cur_identificar
	into  @w_di_dividendo,
	      @w_di_estado
	    
	while @@fetch_status = 0
	begin
	   ---Inicializacion de VAriables
	   select @w_valor_no_vig = 0
	   
	   ---SALDO BASE PARA EL CALCULO DE LA COMISION
	   ------------------------------------------------------------
  	   select @w_saldo_capital = isnull(sum(am_cuota - am_pagado),0)
	   from ca_amortizacion
	   where am_operacion = @i_operacionca
	   and am_concepto = 'CAP'
	   and am_dividendo > @w_di_dividendo

---	   PRINT 'calfng_Vigentes.sp  ' +  ' freq_cobro:  '  + CAST(@w_freq_cobro as varchar)+  '   @w_di_dividendo '  + CAST( @w_di_dividendo as varchar)+ ' Factor  '+ CAST(@w_factor_rubro  as varchar)
	   	
		if (@w_di_dividendo % @w_freq_cobro )= 0 and @w_di_dividendo >=  @w_div_vigente  and @w_di_estado <> @w_est_cancelado and @w_estado <> 'X' and @w_estado <> 'C'  --LPO Ajustes Migracion Core Digital
		begin
		       select @w_di_fecha_ven = di_fecha_ven
		        from  ca_dividendo
		        where di_operacion  = @i_operacionca
		        and   di_dividendo  = @w_di_dividendo	
		        	
		        select @w_plazo_restante = datediff(mm,@w_di_fecha_ven,@w_fecha_fin)
		        
		        ---PRINT 'calfng_Vigentes.sp  plazo_restante: ' + CAST(@w_plazo_restante as varchar)+  ' freq_cobro '  + CAST(@w_freq_cobro as varchar)+  ' SalCAP '  + CAST(@w_saldo_capital as varchar)+ 'Factor'+ CAST(@w_factor_rubro  as varchar)
		        		        
		        if @w_plazo_restante >= @w_freq_cobro
		        begin
		            select @w_valor_rubro = round((@w_saldo_capital * @w_factor_rubro / 100.0), @w_num_dec)
		            ---PRINT 'calfng_vigentes.sp   Entro 1  @w_saldo_capital  ' + CAST(@w_saldo_capital  as varchar) + ' @w_factor_rubro '+ CAST(@w_factor_rubro  as varchar)
		        end
		        else
		        begin
		            select @w_valor_rubro = round((((@w_saldo_capital * @w_factor_rubro / 100.0) / @w_freq_cobro) * @w_plazo_restante), @w_num_dec)
		            ---PRINT 'calfng_vigentes.sp   Entro 2  @w_saldo_capital  ' + CAST(@w_saldo_capital  as varchar) + ' @w_factor_rubro '+ CAST(@w_factor_rubro  as varchar) + ' @w_plazo_restante '+ CAST(@w_plazo_restante  as varchar)
		        end
		        
	            insert into ca_base_rubros_p  values (@i_operacionca,@i_concepto,@w_di_dividendo)    
	            
	            ---PRINT 'calfng_vigentes.sp   valor_rubro  ' + CAST(@w_valor_rubro as varchar) + 'di_dividendo' + CAST(@w_di_dividendo as varchar)+ '@i_concepto' + CAST(@i_concepto as varchar)
                  if @w_di_estado = 1
                     select @w_valor_no_vig = @w_valor_rubro
                  else
                     select @w_valor_no_vig = 0	            
	           
	            if exists (select 1 from ca_amortizacion
	                       where am_operacion = @i_operacionca 
	                       and am_dividendo = @w_di_dividendo
	                       and  am_concepto  = @i_concepto)
	            begin                  
		            update ca_amortizacion set 
			        am_cuota     = @w_valor_rubro,
			        am_acumulado = @w_valor_no_vig
				    where am_operacion = @i_operacionca
				    and   am_concepto = @i_concepto
				    and   am_dividendo = @w_di_dividendo
				    and   am_estado  <> @w_est_cancelado
				    and   am_pagado = 0	        
				    
                    if (@@error <> 0) begin
                        PRINT 'calfng_vigentes.sp Error actualizando Rubro  ' + CAST(@i_concepto as varchar)
			            close Cur_identificar
			            deallocate Cur_identificar
			            return 710001
                    end				 
                    ---PRINT 'calfng_vigentes.sp   valor_rubro  ' + CAST(@w_valor_rubro as varchar) + 'di_dividendo' + CAST(@w_di_dividendo as varchar)+ '@i_concepto' + CAST(@i_concepto as varchar)
			    end
			    ELSE
			    begin
    	             insert into ca_amortizacion with (rowlock)
		               (am_operacion,   am_dividendo,   am_concepto,
		                am_cuota,       am_gracia,      am_pagado,
		                am_acumulado,   am_estado,      am_periodo,
		                am_secuencia)
   		             values(@i_operacionca,    @w_di_dividendo, @i_concepto,
		                    @w_valor_rubro,    0,               0,
		                    @w_valor_no_vig ,  @w_di_estado,    0,
		                    1 )
                     if (@@error <> 0) begin
                        PRINT 'calfng_vigentes.sp Error Insertando  Rubro  ' + CAST(@i_concepto as varchar)
			            close Cur_identificar
			            deallocate Cur_identificar
			            return 710001
                     end				 	
                     ---PRINT 'calfng_vigentes.sp   valor_rubro  ' + CAST(@w_valor_rubro as varchar) + '  di_dividendo: ' + CAST(@w_di_dividendo as varchar)+ ' @i_concepto: ' + CAST(@i_concepto as varchar)
			    
			    end
			     ----ASOCIADO
	            if @w_asociado is not null and @w_asociado <> '' and @w_porcentaje <> 0
	            begin
	                select @w_valor_asociado = round((@w_valor_rubro * @w_porcentaje / 100.0), @w_num_dec)
	                insert into ca_base_rubros_p  values (@i_operacionca,@w_asociado,@w_di_dividendo) 

	                 if @w_di_estado = 1
                         select @w_valor_no_vig = @w_valor_asociado
                      else
                         select @w_valor_no_vig = 0	            
	                
	                if exists (select 1 from ca_amortizacion
	                           where am_operacion = @i_operacionca
	                           and   am_dividendo  = @w_di_dividendo
	                           and am_concepto = @w_asociado )
                    begin	                           
			            update ca_amortizacion set 
				        am_cuota     = @w_valor_asociado,
				        am_acumulado = @w_valor_no_vig
					    where am_operacion = @i_operacionca
					    and   am_concepto = @w_asociado
					    and   am_dividendo = @w_di_dividendo
					    and   am_estado  <> @w_est_cancelado
					    and   am_pagado = 0	        
	
	                    if (@@error <> 0) begin
	                        PRINT 'calfng_vigentes.sp Error actualizando Rubro asociado' + CAST(@w_asociado as varchar)
				            close Cur_identificar
				            deallocate Cur_identificar
				            return 710001
	                    end				    
	                   ---PRINT 'calfng_vigentes.sp   valor_rubro  ' + CAST(@w_valor_rubro as varchar) + 'di_dividendo' + CAST(@w_di_dividendo as varchar)+ ' @w_asociado ' + CAST(@w_asociado as varchar)
		            end
		            ELSE
		            begin
			            insert into ca_amortizacion with (rowlock)
			                  (am_operacion,   am_dividendo,   am_concepto,
			                   am_cuota,       am_gracia,      am_pagado,
			                   am_acumulado,   am_estado,      am_periodo,
			                   am_secuencia)
			            values(@i_operacionca,     @w_di_dividendo, @w_asociado,
			                   @w_valor_asociado,0,               0,
			                   @w_valor_no_vig,  @w_di_estado,    0,
			                   1 )
			
			              if (@@error <> 0) begin
			                 PRINT 'calfng_vigentes.sp Error Insertando Rubro Asociado'+ CAST(@w_asociado as varchar)
			                 close Cur_identificar
			                 deallocate Cur_identificar
			                 return 710001
                          end
                          ---PRINT 'calfng_vigentes.sp   valor_rubro  ' + CAST(@w_valor_rubro as varchar) + 'di_dividendo' + CAST(@w_di_dividendo as varchar)+ ' @w_asociado ' + CAST(@w_asociado as varchar)
		            end                            	     
	             end
		    ---PRINT 'calfng_vigentes.sp   cursor VA  @w_di_dividendo    ' + CAST( @w_di_dividendo  as varchar) +  '  @w_di_estado ' + CAST(@w_di_estado as varchar)
		end ---COBRO
	   ELSE
		begin
	      --- Si no es Dividendo de anualidad lo deja en valores cero 
	      update ca_amortizacion with (rowlock) set    
	      am_cuota     = 0,
	      am_acumulado = 0
	      where am_operacion = @i_operacionca
	      and   am_dividendo = @w_di_dividendo 
	      and   am_concepto  in (@i_concepto,@w_asociado)
	      and   am_estado    <> 3
	      and   am_pagado    = 0
		end		
   
	    					 
       fetch Cur_identificar
	   	into  @w_di_dividendo,
	   	      @w_di_estado
	   	
	   select @w_max_dividendo = max(di_dividendo)
	   from ca_dividendo
	   where di_operacion = 	@i_operacionca  
	   
	   select @w_max_dividendo_c  = isnull(max(rp_dividendo ),0)
	    from ca_base_rubros_p
       where rp_operacion = @i_operacionca 
       
       if @w_max_dividendo = @w_max_dividendo_c
       begin
	       delete ca_base_rubros_p
	       where rp_operacion = @i_operacionca 
	       and rp_dividendo = @w_max_dividendo
       end
       
       update ca_amortizacion
       set am_cuota = 0,
           am_acumulado = 0
  	   from ca_amortizacion a
	   where am_operacion = @i_operacionca 
	   and am_concepto in (@i_concepto,@w_asociado)
	   and am_cuota > 0
	   and am_pagado = 0
	   and am_estado <> @w_est_cancelado
	   and am_dividendo >= @w_div_vigente
	   and not exists(select 1 from ca_base_rubros_p
                             where rp_operacion = @i_operacionca
                             and rp_operacion = a.am_operacion
                             and rp_dividendo = a.am_dividendo
                             and rp_concepto = a.am_concepto)
end --while @@fetch_status = 0

close Cur_identificar
deallocate Cur_identificar

	      
     
    
return 0
go