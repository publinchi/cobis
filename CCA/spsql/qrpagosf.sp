/************************************************************************/
/*	Archivo: 		      qrpagosf.sp				                           */
/*	Stored procedure: 	sp_qr_pagos_factoring			                  */
/*	Base de datos:  	   cob_cartera				                           */
/*	Producto: 		      Cartera					                           */
/*	Disenado por:  		Xavier Saquicela Z.			                     */
/*	Fecha de escritura: 	Sep. 99					                           */
/************************************************************************/
/*				                IMPORTANTE				                        */
/*	Este programa es parte de los paquetes bancarios propiedad de	      */
/*	'MACOSA',                                                            */
/*	Su uso no autorizado queda expresamente prohibido asi como	         */
/*	cualquier alteracion o agregado hecho por alguno de sus		         */
/*	usuarios sin el debido consentimiento por escrito de la 	            */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*				                 PROPOSITO				                        */
/*	Consulta para front end de pagos de factoring                 	      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      AGO-28-2006       Elcira Pelaez  Cambios para el BAC            */
/*      NOV-02-20006   E.Pelaez       NR-126 Docmentos Descontados      */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_qr_pagos_factoring')
	drop proc sp_qr_pagos_factoring

go

create proc sp_qr_pagos_factoring (
@t_trn             smallint = 7144,
@s_user            login    = null,
@i_banco	          cuenta,
@i_formato_fecha   int, 
@i_modo		   tinyint	=null,
@i_dividendo	   smallint	=null
)
as
declare	
@w_error                	int,
@w_return               	int,
@w_sp_name                      descripcion,
@w_est_novigente                tinyint,
@w_est_vigente                  tinyint,
@w_est_vencido                  tinyint,
@w_est_cancelado                tinyint,
@w_operacionca			int,
@w_fecha_ven			datetime,
@w_moneda_op			smallint,
@w_fecha_proceso		datetime,
@w_op_estado			tinyint,
@w_num_dec_op			tinyint,
@w_di_dividendo			smallint,
@w_capital			money,
@w_mora				money,
@w_int_pag			money,
@w_int_acum			money,
@w_counter			tinyint,
@w_op_tramite                   int,
@w_moneda_descripcion           descripcion,
@w_seg                          money,
@w_otros                        money,
@w_parametro_col                catalogo,
@w_tramite                      int,
@w_seg_ant                      money,
@w_seg_ven                      money,
@w_rowcount                     int


select	
@w_sp_name       = 'sp_qr_pagos_factoring'

select @w_est_novigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'NO VIGENTE'

select @w_est_vigente  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VIGENTE'

select @w_est_vencido  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'VENCIDO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from ca_estado
where rtrim(ltrim(es_descripcion)) = 'CANCELADO'


--- INFORMACION DE OPERACION *

select 
@w_operacionca   = op_operacion,
@w_fecha_ven     = op_fecha_fin,
@w_moneda_op     = op_moneda,
@w_fecha_proceso = op_fecha_ult_proceso,
@w_op_estado     = op_estado,
@w_tramite       = op_tramite
from ca_operacion
where  op_banco = @i_banco

if @@rowcount = 0 begin
   select @w_error = 999999
   goto ERROR
end


--- CODIGO DEL CONCEPTO
select @w_parametro_col = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'COL'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0     begin
   select @w_error = 710314
   goto ERROR
end 


select @w_moneda_descripcion = mo_descripcion
from cobis..cl_moneda
where mo_moneda = @w_moneda_op
and   mo_estado = 'V'


---DEVUELVO LAS CUOTAS DE LOS RUBROS TIPO CAPITAL Y MORA 

if @i_modo = 1 begin
   select	
   'Concepto' = am_concepto,
   'Descripcion' = co_descripcion,
   'Tipo' = ro_tipo_rubro,
   'Monto' = am_cuota + am_gracia - am_pagado
   from ca_amortizacion, ca_rubro_op, ca_concepto
   where am_operacion = @w_operacionca
   and   ro_operacion = am_operacion
   and   am_dividendo = @i_dividendo
   and   am_concepto  = ro_concepto
   and   ro_tipo_rubro in ('C', 'M')
   and   co_concepto = ro_concepto

   return 0
end


---DATOS DE CABECERA 

select 	
op_toperacion,
op_banco,
op_moneda,
op_oficial,
op_oficina,
op_monto_aprobado,
op_monto,
convert(varchar(10), op_fecha_fin, @i_formato_fecha),
op_cliente,
op_nombre,    --10
es_descripcion,
convert(varchar(10), @w_fecha_ven, @i_formato_fecha),
op_tipo_cobro,
op_aceptar_anticipos,
op_tipo_reduccion,
op_tipo_aplicacion,
op_cuota_completa,
convert(varchar(10), op_fecha_ult_proceso, @i_formato_fecha),
'tasa' = (select isnull(sum(ro_porcentaje),0)
         from ca_rubro_op
         where ro_operacion = @w_operacionca
         and   ro_tipo_rubro = 'I'
         and   ro_fpago = 'T'),
op_dias_anio,  --20
convert(varchar(10), op_fecha_ini, @i_formato_fecha),
mo_descripcion,
op_tramite   
from ca_operacion, ca_estado, cobis..cl_moneda
where op_operacion = @w_operacionca
and   es_codigo = op_estado
and   op_estado in (@w_est_vigente,@w_est_vencido)
and   mo_moneda = op_moneda
and   mo_moneda = @w_moneda_op
and   mo_estado = 'V'


--- RUBROS DE LA OPERACION 

select 	
'Concepto' = ro_concepto,
'Descripcion' = co_descripcion,
'Tipo de Rubro' = ro_tipo_rubro,
'Prioridad' = ro_prioridad,
'Porcentaje' = ro_porcentaje
from ca_rubro_op, ca_concepto
where co_concepto = ro_concepto
and ro_operacion = @w_operacionca
and ro_tipo_rubro in ('C', 'M','Q','O','V','I')


--- VALOR DEL COLCHOS

select isnull(sum(ro_valor),0)
from ca_rubro_op
where ro_operacion = @w_operacionca
and   ro_concepto = @w_parametro_col

-- MANEJO DE DECIMALES 

exec @w_return = sp_decimales
@i_moneda = @w_moneda_op,
@o_decimales = @w_num_dec_op out

if @w_return != 0 begin
   select @w_error = @w_return
   goto ERROR
end

delete  ca_facturas_tmp
where gt_operacion = @w_operacionca
and   gt_usuario   = @s_user

insert into ca_facturas_tmp
select di_operacion,@s_user,di_dividendo, di_fecha_ven,0,0,0,0,0,0
from ca_dividendo
where di_operacion = @w_operacionca
and   di_estado != 3
order by di_dividendo


declare cur_facturas cursor for
select gt_dividendo
from ca_facturas_tmp
where gt_operacion = @w_operacionca
and   gt_usuario   = @s_user
for update

open cur_facturas

fetch cur_facturas 
  into @w_di_dividendo

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
 begin

   --- CALCULO DE CAPITAL 

   select @w_capital = isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from ca_amortizacion, ca_rubro_op
   where am_operacion = @w_operacionca
   and   am_dividendo = @w_di_dividendo
   and   ro_operacion = am_operacion
   and   am_concepto = ro_concepto
   and   ro_tipo_rubro = 'C'

   --- CALCULO DEL INTERES 
   
   select @w_int_pag = isnull(sum(fac_pagado),0),
          @w_int_acum = isnull(sum(fac_intant_amo),0)
   from ca_facturas
   where fac_operacion = @w_operacionca
   and fac_nro_dividendo = @w_di_dividendo

   --- CALCULO DE MORA 
   
   select  @w_mora = isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from ca_amortizacion, ca_rubro_op
   where am_operacion = @w_operacionca
   and   ro_operacion = am_operacion
   and   am_dividendo = @w_di_dividendo
   and   am_concepto = ro_concepto
   and   ro_tipo_rubro = 'M'


  --- CALCULO SEGURO 
   
   select  @w_seg_ven = isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from ca_amortizacion, ca_rubro_op,ca_concepto
   where am_operacion = @w_operacionca
   and   ro_operacion = am_operacion
   and   am_dividendo = @w_di_dividendo
   and   am_concepto = ro_concepto
   and   co_concepto  = ro_concepto
   and   co_concepto = am_concepto
   and co_categoria in ('S','A')   ---LAS CATEGORIAS DE LOS CONCEPTOS SEGUROS

---seguros siguientes

   select  @w_seg_ant = isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from ca_amortizacion,
        ca_concepto,
        ca_dividendo,
        ca_rubro_op
   where am_operacion = @w_operacionca
   and   di_operacion = @w_operacionca
   and   ro_operacion = @w_operacionca
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo
   and   di_operacion = ro_operacion
   and   co_concepto = am_concepto
   and   am_concepto  = ro_concepto
   and   co_categoria in ('S','A')
   and   am_estado != 3   
   and  (am_dividendo = @w_di_dividendo + charindex (ro_fpago, 'A'))
   
   select @w_seg = isnull(@w_seg_ven ,0) + isnull(@w_seg_ant,0)
  --- CALCULO OTROS RUBROS 

   select @w_otros = isnull(sum(am_cuota+am_gracia-am_pagado),0)
   from ca_amortizacion, ca_rubro_op,ca_concepto
   where am_operacion = @w_operacionca
   and   ro_operacion = am_operacion
   and   am_dividendo = @w_di_dividendo
   and   am_concepto = ro_concepto
   and   co_concepto  = ro_concepto
   and   co_concepto = am_concepto
   and   ro_fpago <> 'L'
   and co_categoria not in ('M','C','I','S','V') ---LAS CATEGORIAS DE LOS OTROS CONCEPTO

   --- ACTUALIZACION DE LA TABLA TEMPORAL 

   update ca_facturas_tmp
   set gt_capital = isnull(@w_capital, 0),
   gt_int_pag     = isnull(@w_int_pag, 0),
   gt_int_acum    = isnull(@w_int_acum, 0),
   gt_mora        = isnull(@w_mora, 0),
   gt_seg         = isnull(@w_seg, 0),
   gt_otros       = isnull(@w_otros, 0)
   where gt_operacion = @w_operacionca
   and   gt_usuario   = @s_user
   and   gt_dividendo = @w_di_dividendo

   if @@error <> 0 begin
      select @w_error = 710003
      goto ERROR
   end
   
   fetch cur_facturas into @w_di_dividendo

end  --- WHILE DEL CURSOR 

close cur_facturas
deallocate cur_facturas

-- RETORNO AL FRONT-END 
select 	
'DIV.'     = gt_dividendo,
'VENCIMIENTO'    = convert(varchar(10), gt_fecha_ven, @i_formato_fecha),
'CAPITAL'        = convert(float,gt_capital),
'INT.PAGADO'     = convert(float, gt_int_pag),
'INT.AMORTIZADO' = convert(float, gt_int_acum),
'INT.MORA'       = convert(float, gt_mora),
'VAL. SEG'       = convert(float, gt_seg),
'VAL. OTROS'     = convert(float, gt_otros)
from ca_facturas_tmp
where gt_operacion = @w_operacionca
and   gt_usuario   = @s_user
order by gt_dividendo


select  
'NRO.DIVIDENDO'     = fac_nro_dividendo,
'NRO.FACTURA'       = fac_nro_factura,
'FECHA-INI'         = convert(varchar(10),fa_fecini_neg, @i_formato_fecha),
'FECHA-FIn'         = convert(varchar(10),fa_fecfin_neg, @i_formato_fecha),
'VALOR FACTURA'     = fac_valor_negociado,
'VALOR INTANT'      = fac_intant,
'% NEGOCIADO'       = fa_porcentaje
 from ca_facturas,
      cob_credito..cr_facturas
where fac_operacion  = @w_operacionca
and fa_tramite = @w_tramite
and fa_referencia = fac_nro_factura
and fa_dividendo = fac_nro_dividendo
and fac_estado_factura = 1
order by fac_nro_dividendo



return 0

ERROR:

exec cobis..sp_cerror
@t_debug = 'N',
@t_file = null,
@t_from  = @w_sp_name,
@i_num = @w_error
--@i_cuenta= ' '

return @w_error  
go