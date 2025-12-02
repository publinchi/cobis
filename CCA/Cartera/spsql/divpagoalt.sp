/************************************************************************/
/*      Archivo:             divpagoalt.sp                              */
/*      Stored procedure:    sp_dividir_pago_alterna                    */
/*      Base de datos:       cob_cartera                                */
/*      Producto:            Cartera                                    */
/*      Disenado por:        Ivan Jimenez                               */
/*      Fecha de escritura:  Mayo  2006                                 */
/************************************************************************/
/*                            IMPORTANTE                                */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                                 PROPOSITO                            */
/*Almacena informacion para el reprote de obligaciones que nacen por    */
/*el pago de un reconocimiento de garnatias                             */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*      FECHA           AUTOR             RAZON                         */
/*      20/10/2021      G. Fernandez     Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_dividir_pago_alterna')
   drop proc sp_dividir_pago_alterna
go

create proc sp_dividir_pago_alterna
   @i_operacion_original    int,
   @i_operacion_alterna     int,
   @i_secuencial_ing        int,
   @i_num_dec               smallint
as
declare 
   @w_error             int,
   @w_secuencial_alt    int,
   @w_proporcion        float,
   @w_original          money,
   @w_alterna           money
begin
   select @w_proporcion = 0
   
   select @w_alterna = oa_monto_alterna,
          @w_original = oa_monto_original
   from   ca_operacion_alterna
   where  oa_operacion_original = @i_operacion_original
   
   --print 'sp_dividir_pago_alterna: montos origina  %1!   y alterna %2!', @w_original, @w_alterna
   
   select @w_proporcion = oa_monto_alterna / oa_monto_original
   from   ca_operacion_alterna, ca_operacion
   where  oa_operacion_original = @i_operacion_original
   and    op_operacion = oa_operacion_alterna
   and    op_estado in (1,2,9,4)
   
   if @w_proporcion <= 0.0002
      return 0
   
   --print 'sp_dividir_pago_alterna: divpagalct.sp  @w_proporcion %1!', @w_proporcion
   
   exec @w_secuencial_alt = sp_gen_sec
        @i_operacion = @i_operacion_alterna
   
   insert into ca_abono
         (ab_secuencial_ing,     ab_secuencial_rpa,          ab_secuencial_pag,
          ab_operacion,          ab_fecha_ing,               ab_fecha_pag,
          ab_cuota_completa,     ab_aceptar_anticipos,       ab_tipo_reduccion,
          ab_tipo_cobro,         ab_dias_retencion_ini,      ab_dias_retencion,
          ab_estado,             ab_usuario,                 ab_oficina,
          ab_terminal,           ab_tipo,                    ab_tipo_aplicacion,
          ab_nro_recibo,         ab_tasa_prepago,            ab_dividendo,
          ab_calcula_devolucion, ab_prepago_desde_lavigente)
   select @w_secuencial_alt,     0,                          0,
          @i_operacion_alterna,  ab_fecha_ing,               ab_fecha_pag,
          ab_cuota_completa,     ab_aceptar_anticipos,       ab_tipo_reduccion,
          ab_tipo_cobro,         ab_dias_retencion_ini,      ab_dias_retencion,
          ab_estado,             ab_usuario,                 ab_oficina,
          ab_terminal,           ab_tipo,                    ab_tipo_aplicacion,
          ab_nro_recibo,         ab_tasa_prepago,            ab_dividendo,
          ab_calcula_devolucion, ab_prepago_desde_lavigente
   from   ca_abono
   where  ab_operacion      = @i_operacion_original
   and    ab_secuencial_ing = @i_secuencial_ing
   
   if @@error != 0
   begin
      print 'Duplicacion inicial del pago'
      return 710001
   end
   
   insert into ca_abono_det
         (abd_secuencial_ing,  abd_operacion,        abd_tipo,
          abd_concepto,        abd_cuenta,           abd_beneficiario,
          abd_moneda,          abd_monto_mpg,        abd_monto_mop,
          abd_monto_mn,        abd_cotizacion_mpg,   abd_cotizacion_mop,
          abd_tcotizacion_mpg, abd_tcotizacion_mop,  abd_cheque,
          abd_cod_banco,       abd_inscripcion,      abd_carga,
		  abd_solidario)                                         --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   select @w_secuencial_alt,   @i_operacion_alterna, abd_tipo,
          abd_concepto,        abd_cuenta,           abd_beneficiario,
          abd_moneda,          abd_monto_mpg,        abd_monto_mop,
          abd_monto_mn,        abd_cotizacion_mpg,   abd_cotizacion_mop,
          abd_tcotizacion_mpg, abd_tcotizacion_mop,  abd_cheque,
          abd_cod_banco,       abd_inscripcion,      abd_carga,
		  abd_solidario
   from   ca_abono_det
   where  abd_operacion      = @i_operacion_original
   and    abd_secuencial_ing = @i_secuencial_ing
   
   if @@error != 0
   begin
      print 'Duplicacion inicial del detalle del pago'
      return 710001
   end
   
   insert into ca_abono_prioridad
         (ap_secuencial_ing, ap_operacion, ap_concepto, ap_prioridad)
   select @w_secuencial_alt, @i_operacion_alterna, ro_concepto, ro_prioridad
   from   ca_rubro_op
   where  ro_operacion = @i_operacion_alterna
   and    ro_fpago not in ('L','B')
   
   if @@error != 0
   begin
      print 'Duplicacion inicial de prioridades del pago'
      return 710001
   end
   
   -- DETERMINAR LA PORCION QUE LE CORRESPONDE A LA ALTERNA
   update ca_abono_det
   set    abd_monto_mpg  = round(abd_monto_mpg * @w_proporcion, @i_num_dec),
          abd_monto_mop  = round(abd_monto_mop * @w_proporcion, @i_num_dec),
          abd_monto_mn   = round(abd_monto_mn  * @w_proporcion, @i_num_dec)
   where  abd_operacion      = @i_operacion_alterna
   and    abd_secuencial_ing = @w_secuencial_alt
   
   if @@error != 0
   begin
      print 'Actualización de la proporcion de la alterna'
      return 710002
   end
   
   -- ACTUALIZAR LA PORCION QUE LE CORRRESPONDE A LA ORIGINAL
   update o
   set    o.abd_monto_mpg  = o.abd_monto_mpg - a.abd_monto_mpg,
          o.abd_monto_mop  = o.abd_monto_mop - a.abd_monto_mop,
          o.abd_monto_mn   = o.abd_monto_mn  - a.abd_monto_mn
   from   ca_abono_det o, ca_abono_det a
   where  o.abd_operacion      = @i_operacion_original
   and    o.abd_secuencial_ing = @i_secuencial_ing
   and    a.abd_operacion      = @i_operacion_alterna
   and    a.abd_secuencial_ing = @w_secuencial_alt
   and    o.abd_tipo           = a.abd_tipo
   and    o.abd_concepto       = a.abd_concepto
   and    o.abd_cuenta         = a.abd_cuenta
   
   if @@error != 0
   begin
      print 'Actualización de la proporcion de la original'
      return 710002
   end
   
   select @w_original = abd_monto_mop
   from   ca_abono_det
   where  abd_operacion = @i_operacion_original
   and    abd_secuencial_ing = @i_secuencial_ing
   and    abd_tipo = 'PAG'
   
   select @w_alterna = abd_monto_mop
   from   ca_abono_det
   where  abd_operacion = @i_operacion_alterna
   and    abd_secuencial_ing = @w_secuencial_alt
   and    abd_tipo = 'PAG'
   
   --print 'sp_dividir_pago_alterna: divpagaclt.sp  fin con orig %1!  y alterna con %2!', @w_original, @w_alterna
end
return 0

go
