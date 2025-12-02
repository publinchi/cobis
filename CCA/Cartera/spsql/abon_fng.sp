/*abon_fng.sp************************************************************/
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Julio 2008                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Registra los pagos realizados por el FNG para su posterior      */
/*      recuperacion de acuerdo a los pagos del cliente.                */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abono_fng')
   drop proc sp_abono_fng
go

create proc sp_abono_fng
@i_operacionca    int,
@i_secuencial     int,
@i_forma_pago     catalogo,
@i_monto_pago     money,
@i_num_dec_op     int,
@i_num_dec_mn     int,
@o_sobrante_pago  money out,
@o_msg            varchar(100) = null out 
as


declare
@w_toperacion     catalogo,
@w_rubro_fng      catalogo,
@w_moneda         int,
@w_moneda_local   int,
@w_error          int,
@w_ult_dividendo  int,
@w_codvalor       int,
@w_cotizacion     float,
@w_porcentaje_fng float,
@w_monto_fng      money,
@w_dev_fng        money,
@w_saldo_fng      money,
@w_monto_dev      money,
@w_monto_dev_mn   money,
@w_operacion      char(3),
@w_fecha_ult_proc datetime
--PRINT '<<<<<<<<<< ENTRO A ABON_FNG >>>>>>>>>>'
/* INICIALIZAR VARIABLES DE TRABAJO */
select
@o_sobrante_pago = @i_monto_pago,
@o_msg           = ''

/* CONDICION DE SALIDA INMEDIATA */
if isnull(@i_monto_pago,0) < 0.01 return 0

/* DETERMINAR DATOS DEL PRESTAMO */
select
@w_moneda         = op_moneda,
@w_toperacion     = op_toperacion,
@w_fecha_ult_proc = op_fecha_ult_proceso
from ca_operacion
where op_operacion = @i_operacionca

if @@rowcount = 0 begin
   select
   @w_error = 710001,
   @o_msg   = 'NO SE ENCUENTRA LA OPERACION INGRESADA DESDE EL PARAMETRO DE ENTRADA'
   goto ERROR
end


/* DETERMINAR EL CODIGO DE LA MONEDA LOCAL */
select @w_moneda_local = pa_tinyint
from   cobis..cl_parametro
where  pa_nemonico = 'MLO'
and    pa_producto = 'ADM'

if @@rowcount = 0 begin
   select
   @w_error = 710001,
   @o_msg   = 'NO SE ENCUENTRA EL PARAMETRO MLO DEL ADMIN'
   goto ERROR
end


/* DETERMINAR EL NOMBRE DEL RUBRO DONDE SE REGISTRARAN LOS PAGOS DEL FONDO */
select @w_rubro_fng = pa_char
from cobis..cl_parametro
where pa_nemonico = 'FNG_RU'
and   pa_producto = 'CCA'
   
if @@rowcount = 0 begin
   select
   @w_error = 710001,
   @o_msg   = 'NO SE ENCUENTRA EL PARAMETRO FNG_RU DE CARTERA'
   goto ERROR
end

/* DETERMINA LA COTIZACION A USAR */
select @w_cotizacion = 1

if @w_moneda <> @w_moneda_local begin
   exec sp_buscar_cotizacion
   @i_moneda = @w_moneda,
   @i_fecha  = @w_fecha_ult_proc,
   @o_cotizacion = @w_cotizacion out
end

if isnull(@w_cotizacion,0) = 0 begin
   select
   @w_error = 710001,
   @o_msg   = 'NO SE ENCUENTRA LA COTIZACION PARA LA MONEDA DE LA OPERACION'
   goto ERROR
end

/* DETERMINAR LOS VALORES PAGADOS POR EL FONDO */
select @w_monto_fng  = isnull(sum(af_monto), 0)
from ca_abono_fng
where af_operacion = @i_operacionca
and   af_accion    = 'PAG'


/* DETERMINAR LOS VALORES DEVUELTOS AL FONDO */
select @w_dev_fng = isnull(sum(af_monto),0)
from ca_abono_fng
where af_operacion = @i_operacionca
and   af_accion    = 'DEV'

select @w_saldo_fng = @w_monto_fng - @w_dev_fng


/* POR DEFECTO EL PROGRAMA NO REALIZA NINGUNA ACCION */
select @w_operacion = ''

/* EN CASO DE PAGOS REALIZADOS POR EL FONDO, LA OPERACION ES 'PAG' */
-- SE COMENTO ESTA LINEA YA QUE SQL NO LA INTERPRETA BIEN: if isnull(@i_forma_pago,'') like @w_fpago_fng

if @i_forma_pago is null select @i_forma_pago = ''
if SUBSTRING(@i_forma_pago,1,4) = 'FNG_'
begin
   select @w_operacion = 'PAG',  --es un pago del fng
          @w_monto_fng = @w_monto_fng + @i_monto_pago  --ajustamos el total pagado por el fondo en este prestamo
end
else
begin 
   /* SI EL PAGO ES NORMAL Y SI EXISTE UN SALDO POR DEVOLVER FONDO, LA OPERACION ES 'DEV' */
   if @w_saldo_fng >= 0.01 select @w_operacion = 'DEV' --es una devolucion al fondo
end

/* SI EL PROGRAMA NO ENCUENTRA UN ACCION A SEGUIR TERMINA */
if @w_operacion = '' return 0


/* DETERMINAR EL NUMERO DE LA ULTIMA CUOTA DE LA OPERACION */
select @w_ult_dividendo = isnull(max(di_dividendo),0)
from ca_dividendo
where di_operacion = @i_operacionca
   
if @w_ult_dividendo = 0 begin
   select
   @w_error = 710001,
   @o_msg   = 'ERROR, LA OPERACION NO TIENE CUOTAS'
   goto ERROR
end

/* (OPERACION DEV)DEVOLVER EL DINERO AL FONDO */
if @w_operacion = 'DEV' begin

   /* DETERMINAR EL PROCENTAJE DEL PAGO DEL CLIENTE QUE SE DEVOLVERA AL FONDO */
   select @w_porcentaje_fng = isnull(pa_float,0)
   from cobis..cl_parametro
   where pa_nemonico = 'FNG_PO'
   and   pa_producto = 'CCA'
   
   if @@rowcount = 0 begin
      select
      @w_error = 710001,
      @o_msg   = 'NO SE ENCUENTRA EL PARAMETRO FNG_RU DE CARTERA'
      goto ERROR
   end
   
   /* DETERMINAR EL VALOR A DEVOVER AL FONDO */
   select @w_monto_dev    = round(@i_monto_pago * @w_porcentaje_fng / 100.00 , @i_num_dec_op)

   /* CONTROLAR NO DEVOLVER VALORES MAYORES AL SALDO */
   if @w_monto_dev > @w_saldo_fng select @w_monto_dev = @w_saldo_fng
   
   /* CALCULAR EL MONTO A DEVOLVER EN MONEDA NACIONAL */
   select @w_monto_dev_mn = round(@w_monto_dev * @w_cotizacion , @i_num_dec_mn)
/*
   PRINT 'ABONO_FNG: @i_monto_pago ' + CAST(@i_monto_pago AS VARCHAR)
   PRINT 'ABONO_FNG: @w_porcentaje_fng ' + CAST(@w_porcentaje_fng AS VARCHAR)
   PRINT 'ABONO_FNG: @i_num_dec_op ' + CAST(@i_num_dec_op AS VARCHAR)
   PRINT 'ABONO_FNG: @w_monto_dev ' + CAST(@w_monto_dev AS VARCHAR)
   PRINT 'ABONO_FNG: @w_cotizacion ' + CAST(@w_cotizacion AS VARCHAR)
   PRINT 'ABONO_FNG: @i_num_dec_mn ' + CAST(@i_num_dec_mn AS VARCHAR)
*/   
   if @w_monto_dev >= 0.01 begin

      /* DETERMINAR EL CODIGO VALOR DEL RUBRO FNG */
      select @w_codvalor = co_codigo * 1000 + 10  -- estado vigente, periodo 0
      from   ca_concepto
      where  co_concepto = @w_rubro_fng

      if @@rowcount = 0 begin
      	 select 
      	 @w_error = 701151,
      	 @o_msg   = 'NO SE ENCUENTRA EL CODIGO VALOR DEL RUBRO ' + @w_rubro_fng
      	 goto ERROR
      end
      
      /* REGISTRAR EL DETALLE CONTABLE */
      insert into ca_det_trn(
      dtr_secuencial,    dtr_operacion,  dtr_dividendo,
      dtr_concepto,      dtr_estado,     dtr_periodo,
      dtr_codvalor,      dtr_monto,      dtr_monto_mn,
      dtr_moneda,        dtr_cotizacion, dtr_tcotizacion,
      dtr_afectacion,    dtr_cuenta,     dtr_beneficiario,
      dtr_monto_cont)
      values(
      @i_secuencial,     @i_operacionca, @w_ult_dividendo,
      @w_rubro_fng,      1,              0,
      @w_codvalor,       @w_monto_dev,   @w_monto_dev_mn,
      @w_moneda,         @w_cotizacion,  'N',
      'C',               '',             '',
      0.00)

      if @@error <> 0 begin
         select
         @w_error = 710001,
         @o_msg   = 'ERROR AL REGISTRAR EL DETALLE CONTABLE DE LA DEVOLUCION DEL DINERO AL FONDO'
         goto ERROR
      end   	
      
--      PRINT 'ABON_FNG 1: @w_rubro_fng ' + CAST(@w_rubro_fng AS VARCHAR) + ' @w_monto_dev_mn ' + CAST(@w_monto_dev_mn AS VARCHAR)
      
      select 
      @o_sobrante_pago = @i_monto_pago - @w_monto_dev, --descontar del monto pagado por el cliente el valor devuelto al fondo
      @w_dev_fng       = @w_dev_fng    + @w_monto_dev  --ajustar el total devuelto al fondo para registrarlo en ca_amortizacion

--      PRINT 'ABON_FNG 2: @i_monto_pago ' + CAST(@i_monto_pago AS VARCHAR) + ' @w_monto_dev ' + CAST(@w_monto_dev AS VARCHAR)
--      PRINT 'ABON_FNG 3: @w_dev_fng ' + CAST(@w_dev_fng AS VARCHAR)      

      /* REGISTRAR LA DEVOLUCION DEL DINERO AL FONDO PARA LA TABLA DE REPORTES */
      insert into ca_abono_fng(
      af_operacion,    af_fecha,     af_secuencial,
      af_monto,        af_accion)
      values(
      @i_operacionca,  @w_fecha_ult_proc, @i_secuencial,
      @w_monto_dev,    'DEV')
      
      if @@error <> 0 begin
         select
         @w_error = 710001,
         @o_msg   = 'ERROR, AL REGISTRAR EL MONTO DEVUELTO AL FONDO EN LA TABLA PARA REPORTE'
         goto ERROR
      end
      
   end
   
   /* ANTES DE TERMINAR, REGENERAMOS EL RUBRO FNG EN LA TABLA DE AMORTIZACION */
   select @w_operacion = 'REG'
	
end -- operacion = DEV


/* (OPERACION PAG) PAGO DEL FONDO NACIONAL DE GARANTIA */
/* (OPERACION REG) REGENERAR EL RUBRO FNG EN LA TABLA DE AMORTIZACION */
if @w_operacion in ('PAG','REG') begin
	
   /* VALIDAR QUE EL TIPO DE OPERACION ADMITA EL RUBRO FNG */
   if not exists(select 1 from ca_rubro
   where  ru_toperacion = @w_toperacion
   and    ru_moneda     = @w_moneda 
   and    ru_concepto   = @w_rubro_fng) begin
      select
      @w_error = 710001,
      @o_msg   = 'NO ESTA PARAMETRIZADO EL RUBRO ' + @w_rubro_fng +' EN EL TIPO DE OPERACION '+ @w_toperacion
      goto ERROR
   end
   
   
   /* CREAR EL RUBRO FNG EN CASO QUE NO EXISTA EN LA OPERACION */
   if not exists(select 1 from ca_rubro_op 
   where ro_operacion = @i_operacionca
   and   ro_concepto  = @w_rubro_fng)  
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
      @i_operacionca,           @w_rubro_fng,                ru_tipo_rubro,
      ru_fpago,                 ru_prioridad,                ru_paga_mora,
      'N',                      null,                        0,
      ru_referencial,           '+',                         0,
      null,                     0,                           0,
      0,                        0,                           'N',
      null,                     ru_concepto_asociado,        0,     
      null,                     'N',                         'N', 
      0.00,                     @i_num_dec_op,               ru_tipo_garantia,   
      null,                     'N',                         'N',
      'M',                      1,                           'N',
      0,                        ru_iva_siempre
      from   ca_rubro
      where  ru_toperacion = @w_toperacion
      and    ru_moneda     = @w_moneda 
      and    ru_concepto   = @w_rubro_fng
   
      if @@error <> 0 begin
         select
         @w_error = 710001,
         @o_msg   = 'ERROR AL CREAR EL RUBRO ' + @w_rubro_fng + 'EN LA TABLA CA_RUBRO_OP'
         goto ERROR
      end
   
   end
   
   
   
   /* ENTRAR BORRANDO EL RUBRO PARA ASEGURARNOS QUE SIEMPRE ESTE EN LA ULTIMA CUOTA */
   delete ca_amortizacion 
   where am_operacion = @i_operacionca
   and   am_concepto  = @w_rubro_fng
   
   if @@error <> 0 begin
      select
      @w_error = 710003,
      @o_msg   = 'ERROR, AL ELIMINAR REGISTROS ANTERIORES DE PAGOS DEL FONDO'
      goto ERROR
   end

   /* REGISTRAR EL RUBRO FNG EN LA ULTIMA CUOTA DE LA TABLA DE AMORTIZACION */
   insert into ca_amortizacion(
   am_operacion,   am_dividendo,     am_concepto, 
   am_cuota,       am_gracia,        am_pagado,
   am_acumulado,   am_estado,        am_periodo,
   am_secuencia)
   values(
   @i_operacionca, @w_ult_dividendo,  @w_rubro_fng,
   @w_monto_fng ,  0,                 0,
   @w_dev_fng,     1,                 0,
   1)

   if @@error <> 0 begin
      select
      @w_error = 710001,
      @o_msg   = 'ERROR, AL REGISTRAR EL MONTO PAGADO POR EL FONDO'
      goto ERROR
   end
      
   
   /* SOLO SI ES OPERACION PAG, REGISTRAR EL PAGO DEL FONDO EN LA TABLA PARA REPORTES*/
   if @w_operacion = 'PAG' begin
   
      insert into ca_abono_fng(
      af_operacion,    af_fecha,     af_secuencial,
      af_monto,        af_accion)
      values(
      @i_operacionca,  @w_fecha_ult_proc, @i_secuencial,
      @i_monto_pago,  'PAG')
      
      if @@error <> 0 begin
         select
         @w_error = 710001,
         @o_msg   = 'ERROR, AL REGISTRAR EL MONTO PAGADO POR EL FONDO EN LA TABLA PARA REPORTE'
         goto ERROR
      end
   end
end  -- operacion = 'PAG'

return 0

ERROR:
return @w_error

go

