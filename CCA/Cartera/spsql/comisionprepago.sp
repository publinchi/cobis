/************************************************************************/
/*   Archivo:              comisionprepago.sp                           */
/*   Stored procedure:     sp_comision_por_prepago                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez Burbano                        */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza el el cobro de una comision por efecto de prepagar         */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA           AUTOR             RAZON                            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_comision_por_prepago')
   drop proc sp_comision_por_prepago
go

create proc sp_comision_por_prepago
@i_operacionca          int,
@i_secuencial_ing       int,
@i_valor_pago           money,
@i_deuda                money

as 

declare
@w_cot_moneda           money,
@w_dividendo            int,
@w_cumple2              char(1),
@w_valor_comision       money,
@w_moneda_op            smallint,
@w_sp_name              descripcion,
@w_concepto             varchar(12),
@w_est_vigente          int,
@w_est_vencido          int,
@w_est_novigente        int,
@w_est_cancelado        int,
@w_est_castigado        int,
@w_op_estado            int,
@w_error                int,
@w_parametro_PCPRE      float,
@w_parametro_PPAGAD     float,
@w_parametro_PCCOM      float,
@w_parametro_RUBCPR     catalogo,
@w_toperacion           catalogo,
@w_valor_porcentual     money,
@w_amortizado_cap       float,
@w_cumple1              char(1),
@w_am_secuencia         smallint,
@w_estado               tinyint,
@w_min_prioridad        tinyint,
@w_op_monto             money,
@w_cap_pag              money

---INICIALIZAR VARIABLES
select 
@w_sp_name        = 'sp_comision_por_prepago'

--- ESTADOS DE CARTERA 
exec @w_error = sp_estados_cca
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_vencido    = @w_est_vencido   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_castigado  = @w_est_castigado out

---PARAMETROS GENERALES

---% PARA DETERMINAR COBRO DE COMISION X PREPAGOS
select @w_parametro_PCPRE = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'PCPRE'
if @@rowcount = 0
   return 721307

---% PARA VALIDAR SI UN PAGO ES PERPAGO
select @w_parametro_PPAGAD = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'PPAGAD'
if @@rowcount = 0
   return 721308

---% QUE SE COBRA SOBRE EL VALOR AGADO
select @w_parametro_PCCOM = pa_float
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'PCCOM'
if @@rowcount = 0
   return 721309

---PARAMETRO QUE IDENTIFICA EL RUBRO PARA COBRO DE COMISION

select @w_parametro_RUBCPR = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'RUBCPR'
if @@rowcount = 0
   return 721310

select @w_concepto = co_concepto
from ca_concepto
where co_concepto = @w_parametro_RUBCPR
if @@rowcount = 0
    return 721304

---DATOS OPERACION
select 
@w_moneda_op          = op_moneda,
@w_op_estado          = op_estado,
@w_toperacion         = op_toperacion,
@w_op_monto           = op_monto
from ca_operacion
where op_operacion  = @i_operacionca

if @w_op_estado = @w_est_castigado
 return 0 

select @w_cap_pag = sum(am_pagado)
from ca_rubro_op, ca_amortizacion
where ro_operacion  = @i_operacionca
and   ro_tipo_rubro = 'C'
and   am_operacion  = ro_operacion
and   am_concepto   = ro_concepto

---VALIDAR EL CAPITAL  VALOR AMORTIZADO 
select @w_amortizado_cap  = (convert(float, @w_cap_pag) / convert(float, @w_op_monto)) * 100.0

if @w_amortizado_cap <=  @w_parametro_PCPRE
   select @w_cumple1 = 'S'
else
   select @w_cumple1 = 'N'  

---print 'comisionprepago.sp @w_amortizado_cap : ' + convert(varchar,@w_amortizado_cap) + '@w_parametro_PCPRE : ' + convert(varchar,@w_parametro_PCPRE)
  

select @w_valor_porcentual = (@i_deuda * @w_parametro_PPAGAD) / 100.0
select @w_valor_porcentual = round(@w_valor_porcentual, 0)

if @i_valor_pago >= @w_valor_porcentual
   select @w_cumple2 = 'S'
else
   select @w_cumple2 = 'N'  
 
  
---print 'comisionprepao.sp @w_cumple1 :' + @w_cumple1 + ' @w_cumple2 ' + @w_cumple2
 
if  (@w_cumple1 = 'S')  and (@w_cumple2 = 'S')
begin
  select @w_valor_comision = (@i_valor_pago * @w_parametro_PCCOM)/100
  select @w_valor_comision = round(@w_valor_comision,0)

  ---INSERTAR EL RUBRO SI NO EXISTE

     if exists(select 1 from ca_rubro_op 
               where ro_operacion = @i_operacionca
               and   ro_concepto  = @w_concepto) 
      begin
         update ca_rubro_op 
         set ro_valor = ro_valor + @w_valor_comision
         where ro_operacion = @i_operacionca
         and   ro_concepto  = @w_concepto
      end
      ELSE
       begin
	      insert into ca_rubro_op(
	      ro_operacion,             ro_concepto,                ro_tipo_rubro,
	      ro_fpago,                 ro_prioridad,               ro_paga_mora,
	      ro_provisiona,            ro_signo,                   ro_factor,
	      ro_referencial,           ro_signo_reajuste,          ro_factor_reajuste,
	      ro_referencial_reajuste,  ro_valor,                   ro_porcentaje,
	      ro_gracia,                ro_porcentaje_aux,          ro_principal,
	      ro_porcentaje_efa,        ro_concepto_asociado,       ro_garantia,
	      ro_tipo_puntos,           ro_saldo_op,                ro_saldo_por_desem,
	      ro_base_calculo,          ro_num_dec,                 ro_tipo_garantia,       
	      ro_nro_garantia,          ro_porcentaje_cobertura,    ro_valor_garantia,
	      ro_tperiodo,              ro_periodo,                 ro_saldo_insoluto,
	      ro_porcentaje_cobrar,     ro_iva_siempre)
	      select 
	      @i_operacionca,           ru_concepto,                 ru_tipo_rubro,
	      ru_fpago,                 ru_prioridad,                ru_paga_mora,
	      'N',                      null,                        0,
	      ru_referencial,           '+',                         0,
	      null,                     @w_valor_comision,           0,
	      0,                        0,                           'N',
	      null,                     ru_concepto_asociado,        0,     
	      null,                     'N',                         'N', 
	      0.00,                     0,                           ru_tipo_garantia,   
	      null,                     'N',                         'N',
	      'M',                      1,                           'N',
	      0,                        ru_iva_siempre
	      from   ca_rubro
	      where  ru_toperacion = @w_toperacion
	      and    ru_moneda     = @w_moneda_op 
	      and    ru_concepto   = @w_concepto
	   
	      if @@error <> 0 return 721303
       end
   ---INERTARLO EN CA_AMORTIZACION PARA QUE SE COBRE EN EL PAGO
   select @w_dividendo = isnull(min(di_dividendo),0)
   from ca_dividendo
   where di_operacion = @i_operacionca
   and di_estado in (@w_est_vigente, @w_est_vencido)
   
   select @w_estado = di_estado
   from ca_dividendo
   where di_operacion = @i_operacionca
   and   di_dividendo = @w_dividendo
   
   select @w_am_secuencia = isnull(max(am_secuencia),0)
   from   ca_amortizacion
   where  am_operacion    = @i_operacionca
   and    am_dividendo    = @w_dividendo
   and    am_concepto     = @w_concepto
   
   select @w_am_secuencia = @w_am_secuencia + 1
   
   insert ca_amortizacion
	      (am_operacion,   am_dividendo,      am_concepto,
	       am_estado,      am_periodo,        am_cuota,
	       am_gracia,      am_pagado,         am_acumulado,
	       am_secuencia )
	values(@i_operacionca, @w_dividendo,     @w_concepto,
	       @w_estado,      0,                @w_valor_comision,
	       0,              0,                @w_valor_comision,
	       @w_am_secuencia)
	
	if @@error != 0
	   return 721305

	if exists (select 1 from   ca_abono_prioridad  
	           where ap_operacion      = @i_operacionca
	           and   ap_secuencial_ing = @i_secuencial_ing
	           and   ap_concepto       = @w_concepto )
	begin
	   update ca_abono_prioridad
	   set ap_prioridad = 0
       where ap_operacion      = @i_operacionca
       and   ap_secuencial_ing = @i_secuencial_ing
       and   ap_concepto       = @w_concepto 
	end
	else
	begin           
	    insert ca_abono_prioridad 
		       (ap_secuencial_ing, ap_operacion,  ap_concepto, ap_prioridad)
		values (@i_secuencial_ing, @i_operacionca,@w_concepto, 0)
	
		if @@error != 0
		   return 721306	
	 end
    	   

	if (select count(1) from ca_abono_prioridad
	    where ap_operacion      = @i_operacionca
	    and   ap_secuencial_ing = @i_secuencial_ing
	    and   ap_prioridad = 0) > 1
	begin
	   update ca_abono_prioridad with (rowlock)
	   set    ap_prioridad      = -1
	   where  ap_operacion      = @i_operacionca
	   and    ap_secuencial_ing = @i_secuencial_ing
	   and    ap_prioridad      = 0
	   and    ap_concepto       = @w_concepto
	end


end  --Cobro de comision


return 0

                    
go                    
                    
                    
                                                            

