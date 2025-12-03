/************************************************************************/
/*      Archivo:                ca_procesa_comfag.sp                    */
/*      Stored procedure:       sp_procesa_comfag                       */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               CARTERA                                 */
/*      Creado por:             Andres Muñoz                            */
/*      Fecha de escritura:     18-Dic-2014                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP', representantes exclusivos para el Ecuador de la    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este store procedure recibe un plano y aplica pago o IOC        */
/*      Segun validaciones que se hacen para FINAGRO                    */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR              RAZON                        */
/*      18-Dic-2014     Andres Muñoz       Emision Inicial              */
/*      20/10/2021      G. Fernandez     Ingreso de nuevo campo de      */
/*                                       solidario en ca_abono_det      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_procesa_comfag' and type = 'P')
   drop proc sp_procesa_comfag
go
---VERsion Dic.19.2014
create proc sp_procesa_comfag(
@i_banco             varchar(40), --OBLIGACION
@i_valor             money,       --VALOR FINAGRO
@i_archivo           varchar(25), --NOMBRE ARCHIVO PROCESAR
@i_fpago             catalogo,
@i_user              login,
@i_terminal          varchar(50)
)
as 
declare
@w_operacion         int,
@w_fecha_cartera     datetime,
@w_secuencial        int,
@w_numero_recibo     int,
@w_cuota_completa    char(1),
@w_aceptar_anticipos char(1),
@w_prep_desde_lavig  char(1),
@w_fecha_ult_proceso datetime,
@w_moneda            tinyint,
@w_cotizacion_mpg    money,
@w_cotizacion_hoy    money,
@w_moneda_nacional   smallint,
@w_oficina           smallint,
@w_tipo_cobro        char(1),
@w_error             int


---  MONEDA NACIONAL 
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'
if @@ROWCOUNT = 0
  return  708153


---  Fecha de Proceso de Cartera 
select @w_fecha_cartera = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7


---  LECTURA DE LA OPERACION VIGENTE 
select 
@w_operacion               = op_operacion,
@w_moneda                  = op_moneda,
@w_fecha_ult_proceso       = op_fecha_ult_proceso,
@w_cuota_completa          = op_cuota_completa,
@w_aceptar_anticipos       = op_aceptar_anticipos,
@w_tipo_cobro              = op_tipo_cobro,
@w_prep_desde_lavig        = op_prepago_desde_lavigente,
@w_oficina                 = op_oficina
from  ca_operacion, ca_estado
where op_banco             = @i_banco
and   op_estado            = es_codigo
and   es_acepta_pago       = 'S'

---  DETERMINAR EL VALOR DE COTIZACION DEL DIA / MONEDA OPERACION 
if @w_moneda = @w_moneda_nacional
   select @w_cotizacion_hoy = 1.0
else begin
   exec sp_buscar_cotizacion
   @i_moneda     = @w_moneda,
   @i_fecha      = @w_fecha_ult_proceso,
   @o_cotizacion = @w_cotizacion_hoy output
end

---  VALOR COTIZACION MONEDA DE PAGO 
exec sp_buscar_cotizacion
@i_moneda     = @w_moneda,
@i_fecha      = @w_fecha_ult_proceso,
@o_cotizacion = @w_cotizacion_mpg output

---  GENERAR EL SECUENCIAL DE INGRESO     
exec @w_secuencial = sp_gen_sec
@i_operacion       = @w_operacion

if @w_secuencial  =  0  or @w_secuencial is null
   return  @w_error


---GENERAL NRO. RECIBO
exec @w_error  = sp_numero_recibo
@i_tipo    = 'P',
@i_oficina = @w_oficina,
@o_numero  = @w_numero_recibo out
   
if @w_error  <> 0 
   return  @w_error

   
---  INSERCION DE CA_ABONO 
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
@w_operacion,          @w_fecha_cartera,      @w_fecha_cartera,            
@w_cuota_completa,     @w_aceptar_anticipos,  'N',            
@w_tipo_cobro,         0,                     0,                     
'ING',                 @w_secuencial,         0,
0,                     @i_user,               @i_terminal,                 
'PAG',                 @w_oficina,            'C',           
@w_numero_recibo,      0,                     0,          
@w_prep_desde_lavig                    
)                                             

if @@error <> 0 
   return  710294

---  INSERCION DE CA_DET_ABONO                
insert into ca_abono_det                      
(                                             
abd_secuencial_ing,    abd_operacion,         abd_tipo,                 
abd_concepto,          abd_cuenta,            abd_beneficiario,             
abd_monto_mpg,         abd_monto_mop,         abd_monto_mn,          
abd_cotizacion_mpg,    abd_cotizacion_mop,    abd_moneda,
abd_tcotizacion_mpg,   abd_tcotizacion_mop,   abd_cheque,               
abd_cod_banco,         abd_solidario                          --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
)                                             
values                                        
(                                             
@w_secuencial,         @w_operacion,          'PAG',                    
@i_fpago,              '',                    @i_archivo,   
@i_valor,              @i_valor,              @i_valor,          
@w_cotizacion_mpg,     @w_cotizacion_hoy,     @w_moneda,
'N',                   'N',                   0,                
'',                    'N'
)
if @@error <> 0 
   return  710295


---  INSERTAR PRIORIDADES 
insert into ca_abono_prioridad
(ap_secuencial_ing, ap_operacion, ap_concepto, ap_prioridad)
select @w_secuencial, @w_operacion, ro_concepto, ro_prioridad
from   ca_rubro_op
where  ro_operacion = @w_operacion
and    ro_fpago not in ('L','B')

if @@rowcount = 0  or @@error <> 0 
   return 710234
   
--- PONER LA PRIORIDADES QUE TIENE 0 EN 1    
update ca_abono_prioridad
set ap_prioridad = 1
where ap_operacion  = @w_operacion
and ap_prioridad = 0
if @@error <> 0 
   return  710089
--- PONER LA PRIORIDAD 0 A CAPITAL PARA QUE SOLO PAGUE CAPITAL
 
update ca_abono_prioridad
set ap_prioridad = 0
where ap_operacion  = @w_operacion
and ap_concepto = 'CAP'
if @@error <> 0 
   return  710089   

   
---APLICAR EL PAGO EN LINEA SOLO SI LA FECHA DE LA OPERACION ES IGUAL A LA FECHA
---DEL SISTEMA
if @w_fecha_cartera = @w_fecha_ult_proceso 
begin

   --- CREACION DEL REGISTRO DE PAGO
   
   exec @w_error    = sp_registro_abono
   @s_user           = @i_user,
   @s_term           = @i_terminal,
   @s_date           = @w_fecha_cartera,
   @s_ofi            = @w_oficina,
   @i_secuencial_ing = @w_secuencial,
   @i_en_linea       = 'S',
   @i_fecha_proceso  = @w_fecha_cartera,
   @i_operacionca    = @w_operacion,
   @i_cotizacion     = @w_cotizacion_hoy
   if @w_error <> 0
      return  @w_error 
   
   --- APLICACION EN LINEA DEL PAGO SIN RETENCION
   
   exec @w_error = sp_cartera_abono
   @s_user           = @i_user,
   @s_term           = @i_terminal,
   @s_date           = @w_fecha_cartera,
   @i_secuencial_ing = @w_secuencial,
   @i_fecha_proceso  = @w_fecha_cartera,
   @i_en_linea       = 'S',
   @i_operacionca    = @w_operacion,
   @i_cotizacion     = @w_cotizacion_hoy,
   @i_por_rubros     = 'S'
   
   if @w_error <> 0
      return  @w_error

   update ca_abono_det
   set abd_monto_mpg    = abd_monto_mop
   where abd_operacion  = @w_operacion
   and   abd_secuencial_ing = @w_secuencial
   and   abd_tipo           = 'PAG'
   
   if @@error <> 0
      return  710568          
   
   update ca_det_trn
   set dtr_monto = dtr_monto_mn
   from ca_abono
   where ab_operacion = @w_operacion
   and   ab_operacion = dtr_operacion
   and   ab_secuencial_ing = @w_secuencial
   and   ab_secuencial_rpa = dtr_secuencial
   and   dtr_dividendo     = -1
   
   if @@error <> 0
      return 710509          
      
end  --- APLICO EN LINEA

go