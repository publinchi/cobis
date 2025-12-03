/************************************************************************/
/*Archivo             :   carevisa.sp                                   */
/*Stored procedure    :   sp_revisa_boc                                 */
/*Base de datos       :   cob_cartera                                   */
/*Producto            :   Credito y Cartera                             */
/*Disenado por        :   Elcira Pelaez                                 */
/*Fecha de escritura  :   jun.2005                                      */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*Este programa es parte de los paquetes bancarios propiedad de         */
/*'MACOSA'                                                              */
/*Su uso no autorizado queda expresamente prohibido asi como            */
/*cualquier alteracion o agregado hecho por alguno de sus               */
/*usuarios sin el debido consentimiento por escrito de la               */
/*Presidencia Ejecutiva de MACOSA o su representante.                   */
/************************************************************************/
/*                      PROPOSITO                                       */
/*     Analisis de operaciones despues del batch                        */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA          AUTOR             CAMBIOS                        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_revisa_boc')
   drop proc sp_revisa_boc
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

---INC 111176 ABR.06.2013
create proc sp_revisa_boc
as
declare 
   @w_sp_name       descripcion,
   @w_concepto_fng  catalogo,
   @w_operacion     int,
   @w_cliente       int,
   @w_estado        smallint,
   @w_diferencia    money,
   @w_cuenta        cuenta,
   @w_nombre        varchar(50),
   @w_fecha_ini_mes datetime,
   @w_am_dividendo  smallint,
   @w_fecha         datetime,
   @w_sec           int,
   @w_sec_his       int,
   @w_fecha_existe  datetime,
   @w_dif           char(1),
   @w_oficina_op    int

---  CARGADO DE VARIABLES DE TRABAJO 
select 
@w_sp_name          = 'sp_revisa_boc'


select @w_concepto_fng = pa_char   
 from cobis..cl_parametro
where pa_nemonico = 'COMFNG'
and pa_producto = 'CCA'  
set transaction isolation level read uncommitted

select @w_fecha_existe = max(rb_fecha)
from ca_revisa_boc
where rb_concepto = @w_concepto_fng

--INI AGI. 22ABR19.  Se comenta porque no se encuentra el campo bo_diferencia Y  bo_cliente en la tabla cb_boc
/* 
select 'cliente' = bo_cliente,'dif'=sum(bo_diferencia)
into #cliente
from cob_conta..cb_boc with (nolock)
where bo_producto = 7
and   bo_diferencia <> 0
group by bo_cliente

select bo_fecha , bo_cuenta ,  bo_cliente , bo_val_opera, bo_val_conta , bo_diferencia , cu_nombre
into #diferencias
 from #cliente,cob_conta..cb_boc with (nolock),cob_conta..cb_cuenta
where dif <> 0
and cliente = bo_cliente
and  bo_producto = 7
and   bo_diferencia <> 0
and bo_cuenta = cu_cuenta
and cu_nombre like '%FNG%'
order by bo_cliente
*/  --FIN AGI

set rowcount 1
select @w_fecha = bo_fecha from #diferencias
set rowcount 0

if @w_fecha = @w_fecha_existe
begin
   ----Indica que las diferencias ya se cargaron 
   return 0
end

select @w_operacion = 0

select @w_fecha_ini_mes = dateadd(dd, 1 - datepart(dd, @w_fecha) , @w_fecha)

--INI AGI. 22ABR19.  Se comenta porque no se encuentra el campo bo_diferencia Y  bo_cliente en la tabla cb_boc
/*
select bo_fecha,op_operacion,bo_cliente,op_estado,bo_diferencia,bo_cuenta,cu_nombre,op_oficina
into #oper
 from #diferencias,ca_operacion o
where op_cliente = bo_cliente
and op_fecha_ult_proceso >=  @w_fecha_ini_mes
and op_estado  in(1,2,3,4,9)
and exists (select 1 from ca_transaccion_prv 
            where tp_operacion = o.op_operacion
            and tp_concepto = @w_concepto_fng)
*/--FIN AGI


select @w_fecha = fp_fecha
from cobis..ba_fecha_proceso

---Los registros dobles no entrar a validacion
select oper = op_operacion,'tot'=count(1)
into #eli
 from #oper
group by op_operacion
having count(1) > 1

delete #oper
from #oper,#eli
where oper = op_operacion

while 1 = 1 begin

      set rowcount 1

      select @w_operacion  = op_operacion,
             @w_cliente    = 0,--bo_cliente,
             @w_estado     = op_estado,
             @w_diferencia = 0,--bo_diferencia,
             @w_cuenta     = bo_cuenta,
             @w_nombre     = cu_nombre,
             @w_oficina_op = op_oficina
      from #oper
      where op_operacion  > @w_operacion
      order by op_operacion

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end

      set rowcount 0
      
      select @w_dif ='S'
      if  exists (select 1 from ca_revisa_boc
           where rb_cliente    = @w_cliente
           and   rb_diferencia = @w_diferencia
           and   rb_concepto   = @w_concepto_fng
           and   rb_fecha      = @w_fecha)
      begin    
         select @w_dif ='N'
      end

      if not exists (select 1 from ca_transaccion_prv
                     where tp_operacion = @w_operacion
                     and   tp_concepto  = @w_concepto_fng
                     and   tp_estado    = 'ING'
                     )
                     and @w_dif ='S'
       begin
                   
	        insert into ca_revisa_boc (rb_fecha,           rb_operacion ,rb_cliente   ,rb_concepto  ,
	                                   rb_diferencia,        rb_cuenta,     rb_nombre)
	             values               (@w_fecha,             @w_operacion,  @w_cliente,  @w_concepto_fng,
	                                   @w_diferencia,        @w_cuenta,     @w_nombre)       
	        if @@error <> 0
	           return 710566		
	      
	      select @w_am_dividendo  = 12     
	      select @w_am_dividendo = max(am_dividendo)
	      from ca_amortizacion
	      where am_operacion = @w_operacion
	      and am_concepto = @w_concepto_fng
	      and am_acumulado > 0
	      
	      if  @w_am_dividendo is null
	          select  @w_am_dividendo = 12
	          
	      if @w_diferencia > 0
	         select @w_sec = 0
	      else   
	         select @w_sec = -999
	      
	        if @w_estado = 3
	        begin
		        select @w_sec_his = max(oph_secuencial)
		        from ca_operacion_his
		        where oph_operacion = @w_operacion
		
		         select @w_estado = oph_estado
		        from ca_operacion_his
		        where oph_operacion = @w_operacion
		        and oph_secuencial = @w_sec_his
	        end
	
		    insert into ca_transaccion_prv with (rowlock)
			(
			tp_fecha_mov,        tp_operacion,        tp_fecha_ref,
			tp_secuencial_ref,   tp_estado,           tp_dividendo,
			tp_concepto,         tp_codvalor,         tp_monto,
			tp_secuencia,        tp_comprobante,      tp_ofi_oper)
			select 
			@w_fecha,            @w_operacion,        @w_fecha,
			@w_sec,              'ING',               @w_am_dividendo,
			@w_concepto_fng,     co_codigo * 1000 + @w_estado * 10 + 0,@w_diferencia,
			1,                    0,                  @w_oficina_op 
			from ca_concepto
			where co_concepto = @w_concepto_fng
			
	        if @@error <> 0
	           return 708165		
     end   

end

return 0

go



