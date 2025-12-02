/************************************************************************/
/*	Archivo:		intmesa.sp				*/
/*	Stored procedure:	sp_interfaz_mesacambio			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera		  			*/
/*	Disenado por:  		Juan Sarzosa                            */
/*	Fecha de escritura:	Ene. 2001 				*/
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
/*	Cargar las tabla definitiva ca_interfaz_mesacambio con los      */
/*      datos totalizados de la tabla temporal.				*/
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interfaz_mesacambio')
   drop proc sp_interfaz_mesacambio
go

create proc sp_interfaz_mesacambio
@i_fecha_ini		datetime,	--MPO Ref. 017 02/14/2002
@i_fecha_fin		datetime	--MPO Ref. 017 02/14/2002
as 
declare 
@w_return           	int,
@w_error 	    	int,	
@w_sp_name          	descripcion,
@w_mt_fecha		datetime,
@w_mt_banco		cuenta,
@w_mt_tran		catalogo,
@w_mt_moneda		smallint,
@w_mt_monto		money,
@w_mt_cotizacion	money,
@w_mt_monto_mn		money,
@w_mt_en_linea		char(1),
@w_mt_secuencial	int,
@w_mt_comprobante	int,	 --MPO Ref. 017 02/14/2002
@w_mt_fecha_cont	datetime,--MPO Ref. 017 02/14/2002
@w_op_num_deuda_ext	cuenta,
@w_ro_tea		float,
@w_op_cliente		int,
@w_saldo_capital	money,
@w_op_dias_anio		smallint,
@w_op_operacion		int,
@w_op_sector		catalogo,
@w_op_toperacion	catalogo,
@w_op_moneda		smallint,
@w_concepto_interes	catalogo,
@w_concepto_capital	catalogo,
@w_concepto_int_ant	catalogo,
@w_ro_porcentaje_efa	float,
@w_ro_referencial	catalogo,
@w_ro_signo		char(1),
@w_ro_factor		money,
@w_vd_referencia	catalogo,
@w_im_referencia	varchar(30),
@w_im_tipo		char(1),
@w_dt_naturaleza	char(1),
@w_moneda_legal		smallint,
@w_moneda_dolar		smallint,
@w_num_dec_ml		tinyint,
@w_num_dec_me		tinyint,
@w_im_tasa_dol		money,
@w_im_monto_dol		money,
@w_factor		varchar(10)

/** NOMBRE DEL SP **/
select @w_sp_name = 'sp_interfaz_mesacambio'

--MPO Ref. 017 02/14/2002
/** LIMPIAR TABLA DE REGITROS **/
delete ca_interfaz_mesacambio
where  im_fecha >= @i_fecha_ini
and    im_fecha <= @i_fecha_fin
--MPO Ref. 017 02/14/2002

/** VALORES DE VARIABLES GENERALES **/
select @w_concepto_capital = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'CAP'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_concepto_interes = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INT'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_concepto_int_ant = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'INTANT'
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

/* MONEDA LEGAL */
select @w_moneda_legal = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'
set transaction isolation level read uncommitted

/* MONEDA DOLAR */
select @w_moneda_dolar = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'CDOLAR'
set transaction isolation level read uncommitted

/** DECIMALES PARA MONEDAS **/
exec @w_return  = sp_decimales
@i_moneda       = @w_moneda_dolar,
@o_decimales    = @w_num_dec_me out,
@o_dec_nacional = @w_num_dec_ml out

if @w_return <> 0 return @w_return

/** SELECCION DE DATOS PARA TABLA DE MESA DE CAMBIO **/
declare cursor_mesa cursor for
select
mt_fecha,	mt_banco,	mt_tran,
mt_moneda,	mt_monto,	mt_cotizacion,
mt_monto_mn,	mt_en_linea,	mt_comprobante, --MPO Ref. 017 02/14/2002
mt_fecha_cont					--MPO Ref. 017 02/14/2002
from ca_mesacambio_temp
for read only 

open cursor_mesa

fetch cursor_mesa into
@w_mt_fecha,	@w_mt_banco,	@w_mt_tran,
@w_mt_moneda,	@w_mt_monto,	@w_mt_cotizacion,
@w_mt_monto_mn,	@w_mt_en_linea, @w_mt_comprobante,
@w_mt_fecha_cont

while @@fetch_status = 0 begin

   /** DATOS DE OPERACION **/
   select @w_op_num_deuda_ext = op_num_deuda_ext,
   @w_op_cliente   = op_cliente,
   @w_op_dias_anio = op_dias_anio,
   @w_op_operacion = op_operacion,
   @w_op_sector    = op_sector,
   @w_op_toperacion= op_toperacion,
   @w_op_moneda    = op_moneda
   from ca_operacion
   where op_banco  = @w_mt_banco

   /** CONVERSION DE MONEDAS **/
   if @w_op_moneda <> @w_moneda_dolar begin
      exec  @w_return = sp_conversion_moneda
      @s_date                 = @w_mt_fecha,	--MPO Ref. 017 02/14/2002
      @i_opcion               = 'L',
      @i_moneda_monto	      = @w_op_moneda,
      @i_moneda_resultado     = @w_moneda_dolar,
      @i_monto		      = @w_mt_monto,
      @i_fecha                = @w_mt_fecha,
      @o_monto_resultado      = @w_im_monto_dol out,
      @o_tipo_cambio          = @w_im_tasa_dol  out   

      if @w_return != 0 return @w_return
   end else begin
      select @w_im_monto_dol = @w_mt_monto,
      @w_im_tasa_dol = 1.0
   end

   /** NATURALEZA DE LA OPERACION **/
   select @w_dt_naturaleza = dt_naturaleza
   from   ca_default_toperacion
   where  dt_toperacion = @w_op_toperacion
   and    dt_moneda     = @w_op_moneda

   if @w_dt_naturaleza = 'A' begin
      if @w_mt_tran in ('PRV', 'AMO')	--MPO Ref. 017 02/14/2002
         select @w_im_tipo = 'C'
      else
         select @w_im_tipo = 'V'
   end

   if @w_dt_naturaleza = 'P' begin
      if @w_mt_tran in ('PRV', 'AMO')	--MPO Ref. 017 02/14/2002
         select @w_im_tipo = 'V'
   end

   /** DATOS DE TASA DE INTERES **/
   select @w_ro_porcentaje_efa = ro_porcentaje_efa,
   @w_ro_referencial = ro_referencial,
   @w_ro_signo = ro_signo,
   @w_ro_factor = ro_factor
   from   ca_rubro_op
   where  ro_operacion = @w_op_operacion
   and    ro_concepto in (@w_concepto_interes,@w_concepto_int_ant)

   /** TASA REFERENCIAL **/
   select @w_vd_referencia = vd_referencia
   from   ca_valor_det
   where  vd_tipo = @w_ro_referencial
   and    vd_sector = @w_op_sector

   select @w_factor = convert(varchar,@w_ro_factor)

   select @w_im_referencia = @w_vd_referencia + ' ' + @w_ro_signo + ' ' + @w_factor
      
   /** SALDO DE CAPITAL **/
   select @w_saldo_capital = sum((abs(am_acumulado - am_pagado) + (am_acumulado - am_pagado))/2)
   from   ca_amortizacion
   where  am_operacion = @w_op_operacion
   and    am_concepto  = @w_concepto_capital
   and    am_estado    != 3
 
   exec @w_mt_secuencial = sp_gen_sec
   @i_operacion = -1
  
   /** INSERCION DE LOS DATOS **/
   insert ca_interfaz_mesacambio
   (
   im_producto,		im_secuencial,		im_fecha,		
   im_obligacion,
   im_deuda_ext,	im_cliente,		im_base,
   im_referencia,	im_tea,			im_trn,
   im_saldo_cap,	im_moneda,		im_tipo,
   im_monto,		im_monto_dol,		im_tasa_dol,
   im_monto_ml,		im_tasa_ml,		im_estado,	
   im_sec_mesa,		im_comprobante,		im_fecha_cont		--MPO Ref. 017 02/14/2002
   )
   values
   (
   7,			@w_mt_secuencial,	@w_mt_fecha,		
   @w_mt_banco,
   @w_op_num_deuda_ext,	@w_op_cliente,		@w_op_dias_anio,
   @w_im_referencia,	@w_ro_porcentaje_efa,	@w_mt_tran,
   @w_saldo_capital,	@w_mt_moneda,		@w_im_tipo,
   @w_mt_monto,		@w_im_monto_dol,	@w_im_tasa_dol,
   @w_mt_monto_mn,	@w_mt_cotizacion,	'V',
   0,			@w_mt_comprobante,	@w_mt_fecha_cont	--MPO Ref. 017 02/14/2002
   )

   if @@error != 0 return 710311
   
   fetch cursor_mesa into
   @w_mt_fecha,		@w_mt_banco,	@w_mt_tran,
   @w_op_moneda,	@w_mt_monto,	@w_mt_cotizacion,
   @w_mt_monto_mn,	@w_mt_en_linea, @w_mt_comprobante,	--MPO Ref. 017 02/14/2002
   @w_mt_fecha_cont						--MPO Ref. 017 02/14/2002
end

close cursor_mesa
deallocate cursor_mesa

return 0
go