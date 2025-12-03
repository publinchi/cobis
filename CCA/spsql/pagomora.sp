/************************************************************************/
/*   Archivo:             pagomora.sp                                   */
/*   Stored procedure:    sp_pagomora                                   */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Luis Carlos Moreno                            */
/*   Fecha de escritura:  2014/09                                       */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Ingreso de abonos unicamente para los conceptos de mora desde caja */
/*   para Normalizacion Prorroga de Cuota                               */ 
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA                 AUTOR                     CAMBIO            */
/*   2014-09-24   Luis Carlos Moreno  Req436:Normalizacion Cartera      */
/*   20/10/2021   G. Fernandez       Ingreso de nuevo campo de          */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pagomora')
   drop proc sp_pagomora
go

create proc sp_pagomora
   @s_user                    login       = NULL,
   @s_term                    varchar(30) = NULL,
   @s_date                    datetime    = NULL,
   @s_sesn                    int         = NULL,
   @s_ssn                     int         = NULL,
   @s_srv                     varchar(30) = NULL,
   @s_ofi                     smallint    = NULL,
   @i_banco                   cuenta,
   @i_monto                   money       = null,
   @i_opcion                  char(1)     = 'P',
   @i_debug                   char        = 'N',
   @o_secuencial              int         = null out,
   @o_monto                   money       = null out
as

declare                    
   @w_return                  int,
   @w_operacionca             int,
   @w_moneda                  tinyint,
   @w_secuencial              int,
   @w_fecha_ult_proceso       datetime,
   @w_cuota_completa          char(1),
   @w_aceptar_anticipos       char(1),
   @w_tipo_reduccion          char(1),
   @w_tipo_cobro              char(1),
   @w_tipo_aplicacion         char(1),
   @w_cotizacion_mpg          money,
   @w_numero_recibo           int,
   @w_moneda_nacional         smallint,
   @w_cotizacion_hoy          money,
   @w_prepago_desde_lavigente char(1),
   @w_monto_mpg               money,
   @w_fecha_cartera           datetime,
   @w_producto                catalogo,
   @w_num_dec                 smallint,
   @w_error                   int,
   @w_msg                     varchar(132),
   @w_total_mora              money


/* Fecha de Proceso de Cartera */
select @w_fecha_cartera = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

if @@ROWCOUNT = 0
begin
  select @w_msg = 'ERROR, FECHA DE CIERRE DE CARTERA NO ENCONTRADA',
         @w_error = 708153
  goto ERRORFIN
end

/*  MONEDA NACIONAL */
select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'

if @@ROWCOUNT = 0
begin
  select @w_msg = 'ERROR, PARAMETRO GENERAL MONEDA NACIONAL NO EXISTE',
         @w_error = 708153
  goto ERRORFIN
end

select @w_num_dec = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'NDE'
and pa_producto = 'CCA'

if @@ROWCOUNT = 0
begin
  select @w_msg = 'ERROR, PARAMETRO GENERAL NUMERO DECIMAL NO EXISTE',
         @w_error = 708153
  goto ERRORFIN
end

/* LECTURA DE LA OPERACION VIGENTE */
select 
@w_operacionca             = op_operacion,
@w_moneda                  = op_moneda,
@w_fecha_ult_proceso       = op_fecha_ult_proceso,
@w_cuota_completa          = op_cuota_completa,
@w_aceptar_anticipos       = op_aceptar_anticipos,
@w_tipo_reduccion          = op_tipo_reduccion,
@w_tipo_cobro              = op_tipo_cobro,
@w_tipo_aplicacion         = op_tipo_aplicacion,
@w_prepago_desde_lavigente = op_prepago_desde_lavigente
from  ca_operacion, ca_estado
where op_banco             = @i_banco
and   op_estado            = es_codigo
and   es_acepta_pago       = 'S'

if @@ROWCOUNT = 0
begin
  select @w_msg = 'ERROR, NO ES POSIBLE OBTENER DATOS BASICOS DE LA OPERACION',
         @w_error = 701025
  goto ERRORFIN
end

/* DETERMINAR EL VALOR DE COTIZACION DEL DIA / MONEDA OPERACION */
if @w_moneda = @w_moneda_nacional
   select @w_cotizacion_hoy = 1.0
else begin
   exec sp_buscar_cotizacion
   @i_moneda     = @w_moneda,
   @i_fecha      = @w_fecha_ult_proceso,
   @o_cotizacion = @w_cotizacion_hoy output
end

/* VALOR COTIZACION MONEDA DE PAGO */
exec sp_buscar_cotizacion
@i_moneda     = @w_moneda,
@i_fecha      = @w_fecha_ult_proceso,
@o_cotizacion = @w_cotizacion_mpg output

/* OPCION PAGO */
if @i_opcion = 'P' begin

   /* OBTIENE EL CONCEPTO PARA APLICAR EL PAGO EN EFECTIVO */
   select @w_producto     = cp_producto
   from   ca_producto 
   where  cp_categoria = 'EFEC'
   and    cp_atx       = 'S'
   
   if @@ROWCOUNT = 0
   begin
      select @w_msg = 'ERROR, NO ES POSIBLE OBTENER LA FORMA DE PAGO',
             @w_error = 701025
      goto ERRORFIN
   end

   select @w_monto_mpg = @i_monto    

   /* GENERAR EL SECUENCIAL DE INGRESO */    
   exec @w_secuencial = sp_gen_sec
   @i_operacion       = @w_operacionca
   
   if @w_secuencial = 0
   begin
      select @w_msg = 'ERROR, NO ES POSIBLE OBTENER SECUENCIAL PARA EL PAGO',
             @w_error = @w_return
      goto ERRORFIN
   end
   
   select 
   @o_secuencial      = @w_secuencial,
   @w_numero_recibo   = @w_secuencial
     
   /* INSERCION DE CA_ABONO */
   insert into ca_abono 
   (
   ab_operacion,          ab_fecha_ing,          ab_fecha_pag,            
   ab_cuota_completa,     ab_aceptar_anticipos,  ab_tipo_reduccion,            
   ab_tipo_cobro,         ab_dias_retencion_ini, ab_dias_retencion,     
   ab_estado,             ab_secuencial_ing,     ab_secuencial_rpa,
   ab_secuencial_pag,     ab_usuario,            ab_terminal,             
   ab_tipo,               ab_oficina,            ab_tipo_aplicacion,           
   ab_nro_recibo,         ab_tasa_prepago,       ab_dividendo,          
   ab_prepago_desde_lavigente                                      
   )                                                               
   values                                                          
   (                                                               
   @w_operacionca,        @w_fecha_cartera,      @w_fecha_cartera,            
   @w_cuota_completa,     @w_aceptar_anticipos,  'M',            
   @w_tipo_cobro,         0,                     0,                     
   'ING',                 @w_secuencial,         0,
   0,                     @s_user,               @s_term,                 
   'PAG',                 @s_ofi,                'C',           
   @w_numero_recibo,      0,                     0,          
   @w_prepago_desde_lavigente                    
   )                                             
   
   if @@error <> 0 begin
      print 'ERROR EN INGRESO DE ABONO EN TABLA CA_ABONO'
      select @w_error = 710294
   
      goto ERRORFIN
   end
   
   /* INSERCION DE CA_DET_ABONO  */              
   insert into ca_abono_det                      
   (                                             
   abd_secuencial_ing,    abd_operacion,         abd_tipo,                 
   abd_concepto,          abd_cuenta,            abd_beneficiario,             
   abd_monto_mpg,         abd_monto_mop,         abd_monto_mn,          
   abd_cotizacion_mpg,    abd_cotizacion_mop,    abd_moneda,
   abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,               
   abd_cod_banco,         abd_solidario                                  --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
   )                                             
   values                                        
   (                                             
   @w_secuencial,         @w_operacionca,        'PAG',                    
   @w_producto,           '',                    '',   
   @w_monto_mpg,          @i_monto,              @i_monto,          
   @w_cotizacion_mpg,     @w_cotizacion_hoy,     @w_moneda,
   'N',                   'N',                   0,                
   '',                    'N'
   )
   
   if @@error <> 0 begin
      print 'ERROR EN INGRESO DETALLE DE ABONO EN TABLA CA_ABONO_DET'
      select @w_error = 710295
   
      goto ERRORFIN
   end
   
   /* INSERTAR PRIORIDADES */
   insert into ca_abono_prioridad (
   ap_secuencial_ing, ap_operacion,   ap_concepto, ap_prioridad)
   select   
   @w_secuencial,     @w_operacionca, ro_concepto, ro_prioridad 
   from ca_rubro_op 
   where ro_operacion =  @w_operacionca
   and   ro_tipo_rubro = 'M'
   
   if @@error <> 0 begin
      print 'ERROR EN INGRESO DE PRIORIDAD DE ABONO EN TABLA CA_ABONO_PRIORIDAD'
      select @w_error = 710001
   
      goto ERRORFIN
   end
   
   if @@error <> 0  
      return 710001
   
   if @w_fecha_cartera = @w_fecha_ult_proceso begin
   
      /*CREACION DEL REGISTRO DE PAGO*/
      
      exec @w_return    = sp_registro_abono
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_ofi            = @s_ofi,
      @s_sesn           = @s_sesn,
      @s_ssn            = @s_ssn,
      @i_secuencial_ing = @w_secuencial,
      @i_en_linea       = 'S',
      @i_fecha_proceso  = @w_fecha_cartera,
      @i_operacionca    = @w_operacionca,
      @i_cotizacion     = @w_cotizacion_hoy
      
      if @w_return <> 0
      begin
         select @w_msg = 'ERROR, NO ES POSIBLE REGISTRAR EL PAGO',
                @w_error = @w_return
         goto ERRORFIN
      end
      
      /*APLICACION EN LINEA DEL PAGO SIN RETENCION*/
      
      exec @w_return = sp_cartera_abono
      @s_user           = @s_user,
      @s_term           = @s_term,
      @s_date           = @s_date,
      @s_sesn           = @s_sesn,
      @s_ofi            = @s_ofi,
      @i_secuencial_ing = @w_secuencial,
      @i_fecha_proceso  = @w_fecha_cartera,
      @i_en_linea       = 'S',
      @i_operacionca    = @w_operacionca,
      @i_cotizacion     = @w_cotizacion_hoy,
      @i_por_rubros     = 'S'
      
      if @w_return <> 0
      begin
         select @w_msg = 'ERROR, NO ES POSIBLE APLICAR EL PAGO',
                @w_error = @w_return
         goto ERRORFIN
      end


      update ca_abono_det
      set abd_monto_mpg    = abd_monto_mop
      where abd_operacion  = @w_operacionca
      and   abd_secuencial_ing = @w_secuencial
      and   abd_tipo           = 'PAG'
      
      if @@error <> 0
      begin
         select 
         @w_msg = 'ERROR AL ACTUALIZAR DETALLE DE ABONO EN TABLA CA_ABONO_DET',
         @w_error   = 710002          
   
         goto ERRORFIN
      end
      
      update ca_det_trn
      set dtr_monto = dtr_monto_mn
      from ca_abono
      where ab_operacion = @w_operacionca
      and   ab_operacion = dtr_operacion
      and   ab_secuencial_ing = @w_secuencial
      and   ab_secuencial_rpa = dtr_secuencial
      and   dtr_dividendo     = -1
      
      if @@error <> 0
      begin
         select 
         @w_msg = 'ERROR AL ACTUALIZAR DETALLE DE TRANSACCION EN TABLA CA_DET_TRN',
         @w_error   = 710002          
   
         goto ERRORFIN
      end
             
   end else
      return 724510
      
end -- Opcion 'P'ago  

/* Saldos Rubros Mora */
if @i_opcion = 'S' begin

   select @o_monto    = 0,
          @w_total_mora = 0

   /* OBTIENE EL VALOR TOTAL DE MORA DE LA OPERACION */
   select @w_total_mora = isnull(sum(am_acumulado - am_pagado),0)
   from ca_dividendo, ca_amortizacion, ca_rubro_op
   where di_operacion = @w_operacionca
   and   am_operacion = di_operacion
   and   am_dividendo = di_dividendo
   and   am_operacion = ro_operacion
   and   di_estado = 2
   and   am_estado <> 3
   and   ro_tipo_rubro = 'M'
   and   am_concepto = ro_concepto

   select @o_monto = @w_total_mora

end   -- Opcion 'S'aldos Rubros Negociacion

ERRORFIN:
   if @i_debug = 'S'
      print @w_msg

return 0
go