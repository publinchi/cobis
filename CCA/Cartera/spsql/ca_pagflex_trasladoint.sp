/************************************************************************/
/*   Archivo:            ca_pagflex_trasladoint.sp                      */
/*   Stored procedure:   sp_ca_pagflex_traslado_int                     */
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
/*   Procedimiento  que hace el traslado de una porcion del rubro INT   */
/*   el dia del vencimiento de la cuota a una cuota siguiente.          */
/*   este traslado se hace en el concepto siguiente  INTTRAS            */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA           AUTOR      RAZON                                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca_pagflex_traslado_int')
   drop proc sp_ca_pagflex_traslado_int
go

create proc sp_ca_pagflex_traslado_int
   @s_user            login,
   @s_term            varchar(30),
   @s_date            datetime,
   @s_ofi             int,
   @i_operacionca     int,
   @i_dividendo       int,
   @i_ejecuto         varchar(50),
   @i_secuencial      int = 0 ---Recibe el secuencial_ing del pago para registrar el traslado de INT
      

as  
declare 
   @w_error                   int,
   @w_disponible              money,
   @w_valor_amortizacion      money,
   @w_banco                   cuenta,
   @w_valor_trasladar         money,
   @w_concepto                catalogo,
   @w_valor_deuda             money,
   @w_secuencia               tinyint,
   @w_concepto_trasINT        catalogo,
   @w_am_estado               smallint,
   @w_max_div                 smallint,
   @w_div_sigte               smallint,
   @w_valor_sobrante          money,
   @w_valor_pagar             money,
   @w_toperacion              catalogo,
   @w_gar_admisible           catalogo,
   @w_reestructuracion        catalogo, 
   @w_calificacion            catalogo,
   @w_fecha_proceso           datetime,
   @w_oficial                 int,
   @w_oficina                 int,
   @w_moneda                  smallint,
   @w_sec_traslado            int,
   @w_inttras_deuda           money,
   @w_parametro_int           catalogo,
   @w_max_sec                 tinyint,
   @w_observacion             varchar(60)


--PARAMETROS GENERALES

select @w_concepto_trasINT = pa_char
 from cobis..cl_parametro
where pa_nemonico = 'TRASIN'
if @@rowcount = 0
   return  724003

select @w_parametro_int = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'INT'
if @@rowcount = 0
   return  701059



select @w_banco             = op_banco,
       @w_toperacion        = op_toperacion,
       @w_oficina           = op_oficina,
	   @w_gar_admisible     = isnull(op_gar_admisible,'N'),
	   @w_reestructuracion  = isnull(op_reestructuracion,'N'),
	   @w_calificacion      = isnull(op_calificacion,'A'),
	   @w_fecha_proceso     = op_fecha_ult_proceso,
	   @w_oficial           = op_oficial,
       @w_moneda            = op_moneda     

from ca_operacion with (nolock)
where op_operacion = @i_operacionca

select @w_max_div = max(di_dividendo)
from ca_dividendo
where di_operacion = @i_operacionca

---NO HAY TRASLADO EN EL ULTIMO DIVIDENDO
if @w_max_div = @i_dividendo
return 0

---SI ELREGISTRO ESTA MARCADO COMO dt_valido = 'N' ES POR QUE HAY UN FIN DE AÑO
----ESTO NO SE TRSLADA
if exists (Select 1 
from cob_credito..cr_disponibles_tramite
where dt_operacion_cca  = @i_operacionca
and   dt_dividendo =  @i_dividendo
and   dt_valido = 'N')
return 0


---SI EL VALRO DA 0 O NEGATIVO,ES UN ERROR QUE SE REGISRTA PARA VERIFICACIONES
select @w_disponible = 0
select @w_disponible = dt_valor_disponible
from cob_credito..cr_disponibles_tramite
where dt_operacion_cca  = @i_operacionca
and   dt_dividendo =  @i_dividendo
and   dt_valido = 'S'

if @w_disponible <= 0
begin
	   insert into ca_errorlog
	   (er_fecha_proc,     er_error,      er_usuario,
	   er_tran,            er_cuenta,     er_descripcion,
	   er_anexo)
	   values(@s_date,     723999,        @s_user,
	   7269,               @w_banco,      'TRASLADO INTERES PAGO FLEXIBLE',
	   'sp_ca_pagflex_traslado_int'
	   ) 
	
	return 0
end

select @w_valor_amortizacion = 0
select @w_valor_amortizacion = (sum(am_cuota ))
 from ca_amortizacion,ca_rubro_op
where am_operacion = @i_operacionca
and am_dividendo = @i_dividendo
and am_operacion = ro_operacion
and am_concepto = ro_concepto
and ro_tipo_rubro <> 'M'
and ro_fpago  not in ('L','A')
and am_cuota > 0


select @w_valor_trasladar = 0
select @w_valor_trasladar = @w_valor_amortizacion - @w_disponible

---RETORNAR SI NO HAY QUE TRASLADAR
if @w_valor_trasladar <= 0
return 0

select @w_valor_sobrante = @w_valor_trasladar
select @w_div_sigte = @i_dividendo + 1
declare cur_traslado_int cursor for select
am_concepto,
am_estado,
am_cuota - am_pagado,
am_secuencia
from ca_amortizacion,ca_rubro_op
where am_operacion = @i_operacionca
and am_dividendo = @i_dividendo
and am_operacion = ro_operacion
and am_concepto = ro_concepto
and am_estado   <> 3
and ro_tipo_rubro in ('F','I')
and ro_fpago  not in ('L','A')
and am_cuota > 0

order by ro_prioridad,am_secuencia desc

for read only
open cur_traslado_int
fetch cur_traslado_int into
@w_concepto,
@w_am_estado,
@w_valor_deuda,
@w_secuencia

while @@fetch_status  = 0
begin


    select @w_valor_pagar = 0
    
    if @w_valor_sobrante >= @w_valor_deuda
    begin
       select @w_valor_pagar = @w_valor_deuda
    end   
    ELSE
    begin
       if (@w_valor_sobrante < @w_valor_deuda ) and (@w_valor_sobrante > 0 )
           select @w_valor_pagar = @w_valor_sobrante
    end   
       
    ---PRINT 'VA DIV:  ' + cast (@i_dividendo as varchar) +  ' CONCEPTO: ' + cast (@w_concepto as varchar) + ' ESTADO : ' + cast (@w_am_estado as varchar) + ' SECUENCIA : ' + cast (@w_secuencia as varchar) + ' valor_sobrante : ' + cast( @w_valor_sobrante as varchar)  + '_valor_pagar: ' + cast(@w_valor_pagar as varchar)
    
    if @w_valor_pagar > 0
    begin   
	   ---PONER EL VALRO COMO PAGADO EN LA CUOTA ORIGINAL
	    update ca_amortizacion
	    set    am_pagado = am_pagado + @w_valor_pagar
	    where am_operacion = @i_operacionca
	    and   am_dividendo = @i_dividendo
	    and   am_concepto  = @w_concepto
	    and   am_secuencia = @w_secuencia
	    and   am_estado    = @w_am_estado
	       
	    ---PONER EL VALOR EN LA CUOTA SIGUIENTE EN EL PARAMTRO @w_concepto_trasINT 
	    ---COMO DEUDA
	    
	    
	    if not exists (select 1 
	               from ca_rubro_op
				    where ro_operacion = @i_operacionca
				    and   ro_concepto  = @w_concepto_trasINT 
				    )
		begin
		 ---INSERTAR EL CONCEPTO EN LA TABLA DE RUBROS PARA QUE DESPUES SE PUEDA VISUALIZAR EN LA TABLA DE AMORTIZACION
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
	      null,                     0,                           0,
	      0,                        0,                           'N',
	      null,                     ru_concepto_asociado,        0,     
	      null,                     'N',                         'N', 
	      0.00,                     0,                           ru_tipo_garantia,   
	      null,                     'N',                         'N',
	      'M',                      1,                           'N',
	      0,                        ru_iva_siempre
	      from   ca_rubro
	      where  ru_toperacion = @w_toperacion
	      and    ru_moneda     = 0 
	      and    ru_concepto   = @w_concepto_trasINT
	   
	      if @@error <> 0 return 724002 
	      
	      if @i_ejecuto  = ltrim(rtrim('sp_aplicacion_cuota_normal')) and @i_secuencial > 0
	      begin
	           if not exists (select 1 from ca_abono_prioridad
	                          where ap_operacion      = @i_operacionca
	                          and   ap_secuencial_ing = @i_secuencial
	                          and   ap_concepto       =   @w_concepto_trasINT)
	            begin                
		             insert into ca_abono_prioridad
			         select @i_secuencial, @i_operacionca, ro_concepto, ro_prioridad
			         from   ca_rubro_op
			         where ro_operacion = @i_operacionca
				     and   ro_concepto  = @w_concepto_trasINT
				     if @@error <> 0 return 724019 
			     end
	      end
	      	 
		end
	     
	    if exists (select 1 
	               from ca_amortizacion
				    where am_operacion = @i_operacionca
				    and   am_dividendo = @w_div_sigte
				    and   am_concepto  = @w_concepto_trasINT 
				    and   am_estado    = @w_am_estado

				    )
		begin
		        set rowcount 1
	 	        update ca_amortizacion
		        set am_cuota  = am_cuota  + @w_valor_pagar,
		            am_acumulado = am_acumulado +  @w_valor_pagar
			    where am_operacion = @i_operacionca
			    and   am_dividendo = @w_div_sigte
			    and   am_concepto  = @w_concepto_trasINT 
			    and   am_estado    = @w_am_estado
			    if @@error <> 0  return  724004
			    set rowcount 0

		end 
		ELSE
		begin
		   ---INSERTAR EL CONCEPTO CON LA SECUENCIAL RESPECTIVA
		   select @w_max_sec = isnull(max(am_secuencia),0)
		   from ca_amortizacion
           where am_operacion = @i_operacionca
		   and   am_dividendo = @w_div_sigte
		   and   am_concepto  = @w_concepto_trasINT 
		   
		   select @w_max_sec = @w_max_sec + 1
		   
	 	   insert into ca_amortizacion (
		   am_operacion,     am_dividendo,     am_concepto,
		   am_estado,        am_periodo,       am_cuota,
		   am_gracia,        am_pagado,        am_acumulado,
		   am_secuencia)
		   values(
		   @i_operacionca,   @w_div_sigte,     @w_concepto_trasINT ,
		   @w_am_estado,     0,                @w_valor_pagar,
		   0,                0,                @w_valor_pagar,
		   @w_max_sec)
            		   
	       if @@error <> 0 return  724000 
		end		                 
	    
	    
	    ---RESTAR EL VALOR PAGADO DEL VALRO A TRASLADAR
	    select @w_valor_sobrante = @w_valor_sobrante - @w_valor_pagar
    end ---VALOR A PAGAR ES VALIDO
   


	fetch cur_traslado_int into
	@w_concepto,
	@w_am_estado,
	@w_valor_deuda,
	@w_secuencia
      
end ---Cursor
close cur_traslado_int
deallocate cur_traslado_int

--- REGISTRO DE LA TRANSACCION INFORMATIVA

  exec @w_sec_traslado = sp_gen_sec
   @i_operacion = @i_operacionca
   
   if @i_ejecuto  = ltrim(rtrim('sp_verifica_vencimiento'))
      select @w_observacion =  'TRASLADO INT TABLA FLEXIBLE EN VENCIMIENTO'
   if @i_ejecuto  = ltrim(rtrim('sp_aplicacion_cuota_normal'))      
      select @w_observacion =  'TRASLADO INT TABLA FLEXIBLE EN PAGO ADELANTO CUOTA'
      
   insert into ca_transaccion with (rowlock)(
   tr_secuencial,       tr_fecha_mov,              tr_toperacion,
   tr_moneda,           tr_operacion,              tr_tran,
   tr_en_linea,         tr_banco,                  tr_dias_calc,
   tr_ofi_oper,         tr_ofi_usu,                tr_usuario,
   tr_terminal,         tr_fecha_ref,              tr_secuencial_ref,
   tr_estado,           tr_observacion,            tr_gerente,
   tr_comprobante,      tr_fecha_cont,             tr_gar_admisible,
   tr_reestructuracion, tr_calificacion,           tr_fecha_real)           
   values(                                         
   @w_sec_traslado,      @s_date,                   @w_toperacion,
   @w_moneda,           @i_operacionca,            'TIP',
   'N',                 @w_banco,                  0,
   @w_oficina,          @w_oficina,                @s_user,
   @s_term,             @w_fecha_proceso,          0,
   'NCO',               @w_observacion,            @w_oficial,
   0,                   @s_date,                   @w_gar_admisible,
   @w_reestructuracion, @w_calificacion,           getdate()
   )
            
   if @@error <> 0  return 703041
   
---ACTUALIZAR EL VALOR EN CA_RUBOR_OP
select @w_inttras_deuda = 0
select @w_inttras_deuda = sum(am_cuota - am_pagado)
from ca_amortizacion
where am_operacion =  @i_operacionca
and am_concepto = @w_concepto_trasINT

update ca_rubro_op
set ro_valor = @w_inttras_deuda
where ro_operacion =  @i_operacionca
and ro_concepto = @w_concepto_trasINT
if @@error <> 0 return  724005

---PONER CANCELADO LOS CONCEPTOS QU ESTAN TOTALMENTE PAGADOS
---POR EFECTOS DEL TRASLADO
update ca_amortizacion
set am_estado = 3
from ca_amortizacion
where am_operacion =  @i_operacionca
and am_concepto  in (@w_concepto_trasINT,@w_parametro_int)
and (am_cuota - am_pagado) = 0
if @@error <> 0 return  724006

return 0
go