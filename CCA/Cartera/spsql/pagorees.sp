/************************************************************************/
/*   Archivo:             pagorees.sp                                   */
/*   Stored procedure:    sp_pagorees                                   */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        RRB                                           */
/*   Fecha de escritura:  2009/05                                       */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Ingreso de abonos en efectico desde caja para Reestructuraciones   */ 
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA                 AUTOR                     CAMBIO            */
/*   2010-04-13   Silvia Portilla S.  Req059:Pago Tabla Reestructuracion*/
/*   20/10/2021        G. Fernandez      Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pagorees')
   drop proc sp_pagorees
go

create proc sp_pagorees
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
   @i_es_normalizacion        char(1)     = 'N',
   @o_secuencial              int         = null out,
   @o_monto                   money       = null out
as declare                    
   @w_sp_name                 descripcion,
   @w_return                  int,
   @w_est_vigente             tinyint,
   @w_est_vencido             tinyint,
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
   @w_fecha_proceso           datetime,
   @w_cotizacion_hoy          money,
   @w_prepago_desde_lavigente char(1),
   @w_monto_mpg               money,
   @w_fecha_cartera           datetime,
   @w_producto                catalogo,
   @w_num_dec                 smallint,
   --SPO Req059 
   @w_val_cobro               money,
   @w_tramite                 int,
   @w_cont                    int,
   @w_val_tram                money
   --SPO Req059 

/*  NOMBRE DEL SP Y FECHA DE HOY */
select  @w_sp_name = 'sp_pagorees'

/* ESTADOS DE CARTERA */
exec @w_return = sp_estados_cca
@o_est_vencido = @w_est_vencido out,
@o_est_vigente = @w_est_vigente out

if @w_return != 0
   return @w_return

/* Fecha de Proceso de Cartera */
select @w_fecha_cartera = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7  -- 7 pertence a Cartera

/*  MONEDA NACIONAL */
select @w_moneda_nacional = pa_tinyint
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'MLO'

select @w_num_dec = pa_tinyint
from cobis..cl_parametro
where pa_nemonico = 'NDE'
and pa_producto = 'CCA'

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

if @@rowcount = 0 return 701025


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

if @i_opcion = 'P' begin

   select @w_producto     = cp_producto
   from   ca_producto 
   where  cp_categoria = 'EFEC'
   and    cp_atx       = 'S'

   if @i_es_normalizacion = 'N'
      --SPO Req059 Valores tabla de rubros
      select @w_tramite = max(tr_tramite)
      from cob_credito..cr_tramite
      where tr_numero_op = @w_operacionca
      and   tr_tipo      = 'E'
      and   tr_estado    <> 'Z'
   else
      select @w_tramite = max(nm_tramite)
      from cob_credito..cr_normalizacion 
      where nm_operacion = @i_banco

   select @w_val_cobro = 0,
          @w_monto_mpg = 0

   select @w_val_cobro = isnull(sum(rp_valor_cobro),0)
   from cob_credito..cr_rub_pag_reest
   where rp_tramite = @w_tramite

   if @w_val_cobro = 0
      select @w_monto_mpg = sum(am_acumulado + am_gracia - am_pagado)
      from ca_amortizacion, ca_rubro_op, ca_dividendo
      where am_operacion   =  @w_operacionca
      and   am_operacion   =  di_operacion
      and   am_dividendo   =  di_dividendo
      and   am_operacion   =  ro_operacion
      and   am_concepto    =  ro_concepto
      and   di_estado      in (@w_est_vencido, @w_est_vigente)
      and   ro_tipo_rubro  != 'C'
   else
   begin
      select @w_val_cobro = isnull(@w_val_cobro,0)
      select @w_monto_mpg = @w_val_cobro
   end
   --SPO Req059 Valores tabla de rubros
     


   /* GENERAR EL SECUENCIAL DE INGRESO */    
   exec @w_secuencial = sp_gen_sec
   @i_operacion       = @w_operacionca
   
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
   @w_cuota_completa,     @w_aceptar_anticipos,  @w_tipo_reduccion,            
   @w_tipo_cobro,         0,                     0,                     
   'ING',                 @w_secuencial,         0,
   0,                     @s_user,               @s_term,                 
   'PAG',                 @s_ofi,                'C',           
   @w_numero_recibo,      0,                     0,          
   @w_prepago_desde_lavigente                    
   )                                             
   if @@error != 0                               
      return 710294 
   
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
   if @@error != 0 
      return 710295
   
   /* INSERTAR PRIORIDADES */
   insert into ca_abono_prioridad (
   ap_secuencial_ing, ap_operacion,   ap_concepto, ap_prioridad)
   select   
   @w_secuencial,     @w_operacionca, ro_concepto, ro_prioridad 
   from ca_rubro_op 
   where ro_operacion =  @w_operacionca
   and   ro_fpago not in ('L','B')
   
   if @@error != 0  
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
      
      if @w_return != 0 
          return @w_return
      
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
      
      if @w_return !=0 
         return @w_return

      update ca_abono_det
      set abd_monto_mpg    = abd_monto_mop
      where abd_operacion  = @w_operacionca
      and   abd_secuencial_ing = @w_secuencial
      and   abd_tipo           = 'PAG'

      update ca_det_trn
      set dtr_monto = dtr_monto_mn
      from ca_abono
      where ab_operacion = @w_operacionca
      and   ab_operacion = dtr_operacion
      and   ab_secuencial_ing = @w_secuencial
      and   ab_secuencial_rpa = dtr_secuencial
      and   dtr_dividendo     = -1
             
   end else
      return 724510
      
end -- Opcion 'P'ago   

/* Saldos Rubros Negociacion */
if @i_opcion = 'S' begin

   select @o_monto    = 0,
          @w_cont     = 0,
          @w_val_tram = 0

   if @i_es_normalizacion = 'N'
      --SPO Req059 Valores tabla de rubros
      select @w_tramite = max(tr_tramite)
      from cob_credito..cr_tramite
      where tr_numero_op = @w_operacionca
      and   tr_tipo      in ('E','M')
      and   tr_estado    <> 'Z'
   else
      select @w_tramite = op_tramite
      from cob_cartera..ca_operacion 
      where op_banco = @i_banco
      
   select @w_val_cobro = 0

   select @w_val_cobro = isnull(sum(rp_valor_cobro),0)
   from cob_credito..cr_rub_pag_reest
   where rp_tramite = @w_tramite

   if @w_val_cobro = 0 -- No se genera pago por que no existe negociacion
      return 0
   else
   begin
      select @w_val_cobro = isnull(@w_val_cobro,0)

      exec cob_cartera..sp_saldo_honorarios
      @i_banco     = @i_banco,
      @i_num_dec   = @w_num_dec,
      @i_saldo_cap = @w_val_cobro,
      @o_saldo_tot = @o_monto out
      
      if @o_monto = 0
         select @o_monto = @w_val_cobro
   end

   select @w_cont     = 1,
          @w_val_tram = tc_valor
   from cob_credito..cr_tramite_cajas
   where tc_tramite = @w_tramite
     and tc_estado  = 'E'
     and  tc_valor = @w_val_cobro

   if @w_cont = 1 and @w_val_tram = @o_monto
      select @o_monto = 0
   
end   -- Opcion 'S'aldos Rubros Negociacion

return 0
go