/************************************************************************/
/*	Archivo: 		qrpagvir.sp		 		*/
/*	Stored procedure: 	sp_consulta_pago_virtual		*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Xavier Maldonado       			*/
/*	Fecha de escritura: 	Enero 2001				*/
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
/*	Consulta de los datos a pagar por medio de banca virtual        */
/*      cuando el modulo se encuentra en LINEA                          */
/*                                                                      */
/************************************************************************/  

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_consulta_pago_virtual')
	drop proc sp_consulta_pago_virtual
go

create proc sp_consulta_pago_virtual (
        @i_banco                 cuenta      = null       
)
as

declare @w_sp_name		 descripcion,
        @w_return		 int,
        @w_error                 int,
        @w_ente                  int,
        @w_nombre                descripcion, 
        @w_fecha_ini             datetime,
        @w_cuota_cancelar        int,
        @w_total_apagar          money,
        @w_monto_minimo          money,
        @w_monto_maximo          money,
        @w_fecha_vencimiento     datetime,
        @w_tasa                  float,
        @w_modalidad             char(1),
        @w_cuotas_pendientes     int,
        @w_saldo_precancelacion  money,         
        @w_plazo_total           int,
        @w_estado_prestamo       descripcion,
        @w_negociacion           char(1),
        @w_ro_porcentaje         float,
        @w_ro_referencial        catalogo,
        @w_moda                  char(20), 
        @w_td_tdividendo         catalogo,
        @w_descripcion           descripcion,
        @w_td_estado             estado,
        @w_td_factor             smallint,
        @w_es_descripcion        descripcion,
        @w_di_dividendo          smallint,  
        @w_op_operacionca        int,
        @w_op_banco              cuenta,
        @w_op_cliente            int,
        @w_op_nombre             descripcion,
        @w_op_toperacion         catalogo,
        @w_op_moneda             tinyint,
        @w_op_fecha_ini          datetime,
        @w_op_fecha_fin          datetime,
        @w_op_fecha_liq          datetime,
        @w_op_monto              money,
        @w_op_tipo               char(1),
        @w_op_dias_anio          smallint,
        @w_op_tplazo             catalogo,
        @w_op_plazo              smallint,
        @w_op_tipo_cobro         char(1),
        @w_op_tipo_reduccion     char(1),
        @w_op_estado             tinyint,
        @w_op_cuota_completa     char(1),
        @w_op_precancelacion     char(1),
        @w_op_aceptar_anticipos  char(1),
        @w_op_bvirtual           char(1),
	@w_op_oficina		 smallint,
	@w_oficina		 descripcion,
        @w_plazo_total_dias      int,
        @w_plazo_total_desc      varchar(16),
        @w_tasa_aplicada         float,
        @w_vigente               tinyint,
        @w_vencido               tinyint,
        @w_cancelado             tinyint,
        @w_precancelado          tinyint,
        @w_condonado             tinyint,
        @w_anulado               tinyint,
        @w_credito               tinyint,
        @w_contador              tinyint,
        @w_cuota                 money,
        @w_di_estado             tinyint,
        @w_parametro             money,
        @w_di_fecha_ven          datetime,
        @w_numero_cuota          varchar(10),
        @w_total_pago_cuota      money,
        @w_di_fecha_ini          datetime,
	@w_tipo_credito		 catalogo,
	@w_concepto_int		 catalogo,
	@w_concepto_imo		 catalogo,
	@w_tef_int		 float,
	@w_tef_imo		 float,
	@w_cuota_actual		 int,
	@w_saldo_capital	 money,
	@w_saldo_interes	 money,
	@w_saldo_mora		 money,
	@w_saldo_otros		 money,
	@w_op_fecha_proceso	 datetime,
	@w_fecha_ult_pago	 datetime,
	@w_max_secuencial	 int
 

/** INICIALIZACION DE VARIABLES **/
/*********************************/
select @w_sp_name = 'sp_consulta_pago_virtual'
select @w_saldo_precancelacion = 0,
@w_saldo_capital = 0,
@w_saldo_interes = 0,
@w_saldo_mora = 0,
@w_saldo_otros = 0,
@w_total_pago_cuota = 0


/** VARIABLES GENERALES **/
/*************************/
select @w_concepto_int = pa_char
from  cobis..cl_parametro
where pa_nemonico = 'INT'
and   pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_concepto_imo = pa_char
from  cobis..cl_parametro
where pa_nemonico = 'IMO'
and   pa_producto = 'CCA'
set transaction isolation level read uncommitted

/** ESTADOS DE CARTERA **/
/************************/
select @w_vencido = es_codigo
from ca_estado
where es_descripcion = 'VENCIDO'

select @w_vigente = es_codigo
from ca_estado
where es_descripcion = 'VIGENTE'

select @w_cancelado = es_codigo
from ca_estado
where es_descripcion = 'CANCELADO'

select @w_precancelado = es_codigo
from ca_estado
where es_descripcion = 'PRECANCELADO'

select @w_anulado = es_codigo
from ca_estado
where es_descripcion = 'ANULADO'

select @w_condonado = es_codigo
from ca_estado
where es_descripcion = 'CONDONADO'

select @w_credito = es_codigo
from ca_estado
where es_descripcion = 'CREDITO'

/** DATOS GENERALES DEL CREDITO **/
/*********************************/
select 
@w_op_operacionca       = op_operacion,
@w_op_banco             = op_banco,
@w_op_oficina		= op_oficina,
@w_op_cliente           = op_cliente,
@w_op_nombre            = op_nombre,
@w_op_toperacion        = op_toperacion,
@w_op_fecha_ini         = op_fecha_ini,
@w_op_fecha_fin         = op_fecha_fin,
@w_op_monto             = op_monto,
@w_op_estado            = op_estado,
@w_op_cuota_completa    = op_cuota_completa,
@w_op_tipo_cobro        = op_tipo_cobro,
@w_op_tipo_reduccion    = op_tipo_reduccion,
@w_op_aceptar_anticipos = op_aceptar_anticipos,
@w_op_precancelacion    = op_precancelacion,
@w_op_fecha_proceso	= op_fecha_ult_proceso
from ca_operacion
where op_banco = @i_banco                

if @@rowcount = 0 begin
   return 705068
end

/** DESCRIPCION TIPO DE CREDITO **/
/*********************************/
select @w_tipo_credito = B.valor 
from cobis..cl_tabla A,
cobis..cl_catalogo B
where A.tabla = 'ca_toperacion'
and   A.codigo = B.tabla
and   B.codigo = @w_op_toperacion
set transaction isolation level read uncommitted

/** DESCRIPCION OFICINA **/
/*************************/
select @w_oficina = of_nombre
from cobis..cl_oficina
where of_oficina = @w_op_oficina
set transaction isolation level read uncommitted

/** TASA EFECTIVA INTERES **/
/***************************/
select @w_tef_int  = ro_porcentaje_efa
from ca_rubro_op
where ro_operacion = @w_op_operacionca
and   ro_concepto  = @w_concepto_int

select @w_tef_int = isnull(@w_tef_int, 0)

/** TASA EFECTIVA MORA **/
/************************/
select @w_tef_imo  = ro_porcentaje_efa
from ca_rubro_op
where ro_operacion = @w_op_operacionca
and   ro_concepto  = @w_concepto_imo

select @w_tef_imo = isnull(@w_tef_imo, 0)

/** DIVIDENDO VIGENTE **/
/***********************/
select @w_cuota_actual = isnull(di_dividendo,0)
from   ca_dividendo
where  di_operacion = @w_op_operacionca
and    di_estado    = @w_vigente

/** FECHA ULTIMO PAGO **/
/***********************/
select @w_max_secuencial = max(tr_secuencial)
from   ca_transaccion
where  tr_operacion  = @w_op_operacionca
and    tr_tran       = 'PAG'
and    (tr_estado = 'ING'
        or tr_estado = 'CON')

select @w_fecha_ult_pago = tr_fecha_ref
from   ca_transaccion
where  tr_operacion  = @w_op_operacionca
and    tr_secuencial = @w_max_secuencial

select @w_fecha_ult_pago = isnull(@w_fecha_ult_pago, "")


/** SALDO DE DEUDA **/
/********************/
select @w_saldo_precancelacion = sum((abs(am_acumulado+am_gracia-am_pagado)+(am_acumulado+am_gracia-am_pagado))/2)
from ca_dividendo,ca_amortizacion
where am_operacion = @w_op_operacionca
and   di_operacion = @w_op_operacionca
and   am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   di_estado    != @w_cancelado

/** SALDO CAPITAL **/
/*******************/
select @w_saldo_capital = sum((abs(am_acumulado+am_gracia-am_pagado)+(am_acumulado+am_gracia-am_pagado))/2)
from ca_dividendo,ca_amortizacion, ca_rubro_op
where am_operacion = @w_op_operacionca
and   di_operacion = @w_op_operacionca
and   ro_operacion = @w_op_operacionca
and   am_operacion = di_operacion
and   am_operacion = ro_operacion
and   am_dividendo = di_dividendo
and   di_estado    != @w_cancelado
and   ro_tipo_rubro = 'C'
and   ro_fpago = 'P'
and   ro_concepto  = am_concepto

/** SALDO INTERES **/
/*******************/
select @w_saldo_interes = sum((abs(am_acumulado+am_gracia-am_pagado)+(am_acumulado+am_gracia-am_pagado))/2)
from ca_dividendo,ca_amortizacion, ca_rubro_op
where am_operacion = @w_op_operacionca
and   di_operacion = @w_op_operacionca
and   ro_operacion = @w_op_operacionca
and   am_operacion = di_operacion
and   am_operacion = ro_operacion
and   am_dividendo = di_dividendo
and   di_estado    != @w_cancelado
and   ro_tipo_rubro = 'I'
and   ro_fpago in ('P','A')
and   ro_concepto  = am_concepto

/** SALDO MORA **/
/****************/
select @w_saldo_mora = sum((abs(am_acumulado+am_gracia-am_pagado)+(am_acumulado+am_gracia-am_pagado))/2)
from ca_dividendo,ca_amortizacion, ca_rubro_op
where am_operacion = @w_op_operacionca
and   di_operacion = @w_op_operacionca
and   ro_operacion = @w_op_operacionca
and   am_operacion = di_operacion
and   am_operacion = ro_operacion
and   am_dividendo = di_dividendo
and   di_estado    != @w_cancelado
and   ro_tipo_rubro = 'M'
and   ro_fpago = 'P'
and   ro_concepto  = am_concepto

select @w_saldo_mora = isnull(@w_saldo_mora,0)

/** SALDO OTROS **/
/*****************/
select @w_saldo_otros = sum((abs(am_acumulado+am_gracia-am_pagado)+(am_acumulado+am_gracia-am_pagado))/2)
from ca_dividendo,ca_amortizacion, ca_rubro_op
where am_operacion = @w_op_operacionca
and   di_operacion = @w_op_operacionca
and   ro_operacion = @w_op_operacionca
and   am_operacion = di_operacion
and   am_operacion = ro_operacion
and   am_dividendo = di_dividendo
and   di_estado    != @w_cancelado
and   ro_tipo_rubro != 'C'  
and   ro_tipo_rubro != 'I'
and   ro_tipo_rubro != 'M'
and   ro_concepto  = am_concepto

select @w_saldo_otros = isnull(@w_saldo_otros,0)

/** MONTO A PAGAR **/
/*******************/
if @w_op_tipo_cobro = 'A' begin
   select @w_total_pago_cuota = sum((abs(am_acumulado+am_gracia-am_pagado)+(am_acumulado+am_gracia-am_pagado))/2)
   from  ca_dividendo,ca_amortizacion
   where am_operacion = @w_op_operacionca
   and   di_operacion = @w_op_operacionca
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo
   and   (di_estado = @w_vencido
          or di_estado = @w_vigente)  
end else begin
   select @w_total_pago_cuota = sum((abs(am_cuota+am_gracia-am_pagado)+(am_cuota+am_gracia-am_pagado))/2)
   from  ca_dividendo,ca_amortizacion
   where am_operacion = @w_op_operacionca
   and   di_operacion = @w_op_operacionca
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo
   and   (di_estado = @w_vencido
          or di_estado = @w_vigente)  
end

/** INSERTAR INFORMACION EN TABLA TEMPORAL **/
if exists (select 1 from ca_dat_oper_bv_tmp where bv_no_obligacion = @i_banco)
   delete ca_dat_oper_bv_tmp
   where  bv_no_obligacion = @i_banco

insert into ca_dat_oper_bv_tmp
(
bv_cliente,       bv_no_obligacion, bv_tipo_credito,
bv_oficina,       bv_fecha_consulta,bv_fecha_ult_pago,
bv_monto_inicial, bv_tef_int,       bv_tef_mora,
bv_div_actual,    bv_fecha_ini,     bv_fecha_fin,
bv_saldo_deudor,  bv_saldo_cap,     bv_saldo_int,
bv_saldo_mora,    bv_saldo_otros,   bv_total_pagar,
bv_cuota_completa,bv_tipo_reduccion,bv_aceptar_anticp,
bv_precancelar
)
values
(
@w_op_nombre,   @w_op_banco,  		@w_tipo_credito,
@w_oficina,	@w_op_fecha_proceso, 	@w_fecha_ult_pago,
@w_op_monto,	@w_tef_int,		@w_tef_imo,
@w_cuota_actual,@w_op_fecha_ini, 	@w_op_fecha_fin,
@w_saldo_precancelacion, @w_saldo_capital, @w_saldo_interes,
@w_saldo_mora,	@w_saldo_otros,		@w_total_pago_cuota,
@w_op_cuota_completa, @w_op_tipo_reduccion, @w_op_aceptar_anticipos,
@w_op_precancelacion
) 
  
return 0
go