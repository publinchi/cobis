/************************************************************************/
/*    Archivo:                  sp_pago_masivo.sp                       */
/*    Stored procedure:         sp_pago_masivo                          */
/*    Base de datos:            cob_cartera                             */
/*    Producto:                 Cartera                                 */
/*    Disenado por:             Jorge Escobar                           */
/*    Fecha de escritura:       13/Nov/2019                             */
/************************************************************************/
/*                             IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "MACOSA",  representantes  exclusivos  para  el Ecuador de la     */
/*    "NCR CORPORATION".                                                */
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */
/*    Presidencia Ejecutiva de MACOSA o su representante.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*    Proceso de pagos masivos de prestamos de cartera                  */
/************************************************************************/
/*				MODIFICACIONES				                            */
/*    FECHA		          AUTOR			       RAZON			        */
/*  22/11/2019         EMP-JJEC                Creaciòn                 */
/*  20/10/2021      G. Fernandez        Ingreso de nuevo campo de       */
/*                                       solidario en ca_abono_det      */
/************************************************************************/
use cob_cartera
go
 
if exists (select * from sysobjects where name = 'sp_pago_masivo')
  drop proc sp_pago_masivo
go

create proc sp_pago_masivo 
@s_user          login        = NULL,
@s_term          descripcion  = NULL,
@s_ofi           smallint     = NULL,
@s_date          datetime     = NULL,
@i_operacion     char(1)      = NULL,		--Operacion ha realizar
@i_fecha_ing     datetime     = NULL,		--Fecha de ingreso
@i_banco         cuenta       = NULL,		--Numero de prestamo
@i_forma_pago    catalogo     = NULL,           --Forma de Pago
@i_referencia    cuenta       = NULL,           --Referencia Cuenta o Cheque
@i_valor         money        = 0,              --Monto a Pagar
@i_moneda_pag    tinyint      = NULL,           --Moneda de Pago
@i_descripcion   varchar(10)  = NULL            --Descripcion
as

declare 
@w_sp_name                      varchar(32),
@w_return                       int,
@w_error                        int,
@w_operacionca                  int,
@w_secuencial                   int,
@w_compania                     int,
@w_secuencial_reg               int,
@w_min_divididendo              int,   
@w_desc_error                   varchar(100),
@w_valor                        money,
@w_aceptar_anticipos            char(1),
@w_tipo_reduccion               char(1),
@w_tipo_cobro                   char(1),          
@w_tipo_aplicacion              char(1),
@w_op_moneda                    tinyint,
@w_pcobis                       tinyint,
@w_numero_recibo                int,
@w_monto_mpg                    money,
@w_monto_mn                     money,
@w_cot_moneda                   float,
@w_cotizacion_mpg               float,
@w_tcot_moneda                  char(1),
@w_tcotizacion_mpg              char(1),
@w_concepto                     varchar(30),
@w_prioridad                    int,
@w_estado                       tinyint,
@w_oficina                      smallint,
@w_dias_retencion	        smallint,
@w_beneficiario	               	varchar(50),
@w_cedruc			numero,
@w_estado_registro              varchar(10),
@w_est_cancelado                tinyint,
@w_est_credito                  tinyint,
@w_est_anulado                  tinyint,
@w_est_novigente                tinyint,
@w_est_vigente                  tinyint,
@w_est_vencido                  tinyint,
@w_secuencial_abono             int,
@w_ab_estado                    varchar(3),
@w_secuencial_pag		int,
@w_cuenta			varchar(24),
@w_op_banco                     cuenta,
@w_op_operacion                 int,
@w_c_nombre_completo            varchar(254),
@w_saldo_pagar                  money,
@w_fecha_ven_div                datetime,
@w_cliente                      int,
@w_dividendo_act                int,
@w_moneda_nacional              tinyint,
@w_nrows                        int,
@w_sec_previo                   int,
@w_banco                        cuenta,
@w_cotizacion_hoy               float
	
/* INICIALIZACION DE VARIABLES */
select @w_sp_name = 'sp_pago_masivo'

/* CREAR TABLAS DE TRABAJO */
create table #operacion_convenio(
  oc_banco      cuenta, 
  oc_forma_pago catalogo, 
  oc_referencia cuenta, 
  oc_valor      money,
  oc_nombres    varchar(254))

-- OBTENGO LOS ESTADOS DE CARTERA
exec sp_estados_cca
@o_est_credito    = @w_est_credito    out,
@o_est_anulado    = @w_est_anulado    out,
@o_est_novigente  = @w_est_novigente out,
@o_est_cancelado  = @w_est_cancelado  out,
@o_est_vigente    = @w_est_vigente    out,
@o_est_vencido    = @w_est_vencido    out

if @i_operacion = 'I' --Insertar en tabla ca_pago_masivo, ca_abono, ca_abono_det y ca_abono_prioridad
begin
   select @w_desc_error      = NULL, 
          @w_estado_registro = NULL
   
   select @w_cliente            = op_cliente,
          @w_operacionca        = op_operacion,
          @w_aceptar_anticipos  = op_aceptar_anticipos,
          @w_tipo_reduccion     = op_tipo_reduccion,
          @w_tipo_cobro         = op_tipo_cobro,
          @w_tipo_aplicacion    = op_tipo_aplicacion,
          @w_op_moneda          = op_moneda ,
          @w_estado             = op_estado,
          @w_oficina            = op_oficina
     from cob_cartera..ca_operacion
    where op_banco = @i_banco
      and op_estado not in (@w_est_credito, @w_est_anulado, @w_est_novigente, @w_est_cancelado)
      
   if @@rowcount = 0 
   begin
      select @w_desc_error = 'La operación no existe o esta en estado no permitido para el pago'
      select @w_estado_registro = 'ERROR'
   end  

   if @w_estado_registro = NULL
   begin 
      --Si no envian valor se obtiene el valor a pagar hasta el momento
      if @i_valor = 0
      begin
         -- Dividendo Vigente
         select @w_dividendo_act = di_dividendo
          from ca_dividendo
         where di_operacion = @w_operacionca
           and di_estado in (@w_est_vigente)
           
         if @@rowcount = 0
            select @w_dividendo_act = max(di_dividendo)
              from ca_dividendo
             where di_operacion = @w_operacionca
               and di_estado in (@w_est_vencido)           

         if isnull(@w_dividendo_act,0) = 0
         begin
            select @w_desc_error = 'La operacion se encuentra cancelada o no tiene valores'
            select @w_estado_registro = 'ERROR'
         end
         
         select @w_valor = sum(am_acumulado + am_gracia - am_pagado)
           from ca_dividendo, ca_amortizacion 
          where di_operacion = @w_operacionca
            and di_dividendo <= @w_dividendo_act
            and am_operacion = di_operacion
            and am_dividendo = di_dividendo
            and di_estado not in (@w_est_cancelado)     	
      end
      else
         select @w_valor = @i_valor	

      --Validar existencia de forma de pago
      if not exists (select 1 from ca_producto where cp_producto = @i_forma_pago)
      begin  
         select @w_desc_error = 'No existe forma de pago ingresada'
         select @w_estado_registro = 'ERROR'
      end
      else
      begin
         --Validar que la cuenta sea la correcta cuando se trata de cuentas de ahorro o corriente
         select @w_pcobis = cp_pcobis
         from ca_producto 
         where cp_producto = @i_forma_pago
       
         if @w_pcobis in (3,4)
         begin
            if not exists (select 1 from cob_ahorros..ah_cuenta where ah_cta_banco = @i_referencia) and not exists (select 1 from cob_cuentas..cc_ctacte where cc_cta_banco = @i_referencia)
            begin
               select @w_desc_error = 'No existe la cuenta de debito ingresada'
               select @w_estado_registro = 'ERROR'
            end
         end
      end		
   end
      
   select @w_secuencial_reg = max(pm_secuencial)
   from ca_pago_masivo
   where pm_fecha_ing = @i_fecha_ing
   and pm_usuario     = @s_user
   
   if @w_secuencial_reg = null select @w_secuencial_reg = 0
   
   select @w_secuencial_reg = @w_secuencial_reg + 1
      
   insert ca_pago_masivo (
   pm_secuencial,     pm_usuario,        pm_fecha_ing,      pm_estado,
   pm_desc_error,     pm_compania,       pm_banco,
   pm_cuenta,         pm_valor,          pm_forma_pag)
   values (
   @w_secuencial_reg, @s_user,           @i_fecha_ing,      @w_estado_registro,
   @w_desc_error,     @w_compania,	 @i_banco,
   @i_referencia,     @w_valor,          @i_forma_pago)   

   if @w_estado_registro = NULL
   begin
      BEGIN TRAN
            
      if @i_moneda_pag = null
         select @i_moneda_pag = @w_op_moneda

      exec @w_error = sp_conversion_moneda
      @s_date             = @i_fecha_ing,
      @i_moneda_monto     = @i_moneda_pag,          -- PAG
      @i_moneda_resultado = @w_op_moneda,           -- OP
      @i_monto            = @w_valor,               -- PAG
      @o_monto_resultado  = @w_monto_mpg       out, -- PAG 
      @o_tipo_cambio      = @w_cotizacion_mpg out  -- TCOT MRES

      if @w_error != 0 GOTO ERROR1

      --VALIDAR QUE MONTO A PAGAR NO SEA MAYOR A SALDO DE OPERACION
      if @w_tipo_cobro = 'A'
      begin
         select @w_saldo_pagar = sum(am_acumulado + am_gracia - am_pagado)
         from ca_dividendo, ca_amortizacion 
         where di_operacion =  @w_operacionca
         and am_operacion = di_operacion
         and am_dividendo = di_dividendo
         and di_estado not in (@w_est_cancelado)
      end
      else
      begin  
         select @w_saldo_pagar = sum(am_cuota + am_gracia - am_pagado)
         from ca_dividendo, ca_amortizacion 
         where di_operacion =  @w_operacionca
         and am_operacion = di_operacion
         and am_dividendo = di_dividendo
         and di_estado not in (@w_est_cancelado)
      end
       
      if @w_monto_mpg > @w_saldo_pagar
      begin
         select @w_error = 708149
         goto ERROR1
      end
       
      exec @w_secuencial = sp_gen_sec 
      @i_operacion  = @w_operacionca
       
      /* GENERACION DEL NUMERO DE RECIBO */
      exec @w_error = sp_numero_recibo
      @i_tipo    = 'P',
      @i_oficina = @s_ofi,
      @o_numero  = @w_numero_recibo out
      
      if @w_error != 0 GOTO ERROR1
       
      /* INSERCION EN CA_ABONO */
      
      insert into ca_abono (
      ab_operacion,      ab_fecha_ing,          ab_fecha_pag,
      ab_cuota_completa, ab_aceptar_anticipos,  ab_tipo_reduccion,
      ab_tipo_cobro,     ab_dias_retencion_ini, ab_dias_retencion,
      ab_estado,         ab_secuencial_ing,     ab_secuencial_rpa,
      ab_secuencial_pag, ab_usuario,            ab_terminal,
      ab_tipo,           ab_oficina,            ab_tipo_aplicacion,
      ab_nro_recibo,     ab_dividendo)
      values (
      @w_operacionca,    @i_fecha_ing,          @i_fecha_ing,
      'N',               @w_aceptar_anticipos,  @w_tipo_reduccion,
      @w_tipo_cobro,     0,                     0,
      'ING',             @w_secuencial,         0,
      0,                 @s_user,               @s_term,
      'PAG',             @s_ofi,                @w_tipo_aplicacion,
      @w_numero_recibo,  0)
                
      if @@error != 0 
      begin
         delete ca_abono
         where ab_operacion = @w_operacionca
         and ab_secuencial_ing = @w_secuencial

         select @w_error = 710001
         goto ERROR1
      end  
       
      insert into ca_abono_prioridad (
      ap_operacion, ap_secuencial_ing, ap_concepto, ap_prioridad) 
      select
      @w_operacionca, @w_secuencial, ro_concepto, ro_prioridad
      from ca_rubro_op
      where ro_operacion = @w_operacionca
      and   ro_fpago not in ('L','B','I')
      
      if @@error <> 0
      begin
         delete ca_abono
         where ab_operacion = @w_operacionca
         and ab_secuencial_ing = @w_secuencial
         
         delete ca_abono_prioridad
         where ap_operacion = @w_operacionca
         and ap_secuencial_ing = @w_secuencial
         
         select @w_error = 710001
         goto ERROR1
      end

      if isnull(@i_descripcion,'') = '' 
         select @w_beneficiario = 'PAGO MASIVO'
      else
      	 select @w_beneficiario = @i_descripcion
      	    
      insert into ca_abono_det (
      abd_operacion,       abd_secuencial_ing,     abd_tipo,         
      abd_concepto,        abd_cuenta,             abd_beneficiario,    
      abd_monto_mpg,       abd_monto_mop,          abd_monto_mn,        
      abd_cotizacion_mpg,  abd_cotizacion_mop,     abd_moneda,          
      abd_tcotizacion_mpg, abd_tcotizacion_mop,    abd_solidario) --GFP 19/10/2021 Ingreso de nuevo campo para identificacion de pago solidario
      values (
      @w_operacionca,     @w_secuencial,            'PAG',              
      @i_forma_pago,      isnull(@i_referencia,''), @w_beneficiario,
      @w_monto_mpg,       @w_valor,             @w_monto_mpg,       
      @w_cotizacion_mpg,  1,            @w_op_moneda,         
      'N',     'N',      'N')

      if @@error <> 0
      begin
         delete ca_abono
         where ab_operacion = @w_operacionca
         and ab_secuencial_ing = @w_secuencial
         
         delete ca_abono_prioridad
         where ap_operacion = @w_operacionca
         and ap_secuencial_ing = @w_secuencial
         
         delete ca_abono_det
         where abd_operacion = @w_operacionca
         and abd_secuencial_ing = @w_secuencial
         
         select @w_error = 710001
         goto ERROR1
      end
      
      update ca_pago_masivo
      set pm_operacion      = @w_operacionca,
          pm_secuencial_ing = @w_secuencial,
          pm_estado         = 'ING'
      where pm_banco    = @i_banco
      and pm_secuencial = @w_secuencial_reg
      and pm_fecha_ing  = @i_fecha_ing
      and pm_usuario    = @s_user
      
      COMMIT TRAN
   end   
end

if @i_operacion = 'P' --Procesar los pagos de la tabla ca_pago_masivo ingresados ING
begin

   -- CODIGO DE LA MONEDA LOCAL
   select @w_moneda_nacional = pa_tinyint
   from   cobis..cl_parametro with (nolock)
   where  pa_producto = 'ADM'
   and    pa_nemonico = 'MLO'

   if @@rowcount = 0 begin
      select @w_error = 708174
      goto ERROR1
   end

   select @w_nrows = 1, 
          @w_sec_previo = 0 

   while (@w_nrows > 0) 
   begin 

      select @w_estado_registro = 'PAGADO', 
             @w_desc_error      = null
          
      select top 1
      @w_banco         = pm_banco,
      @w_operacionca   = pm_operacion,
      @w_sec_previo    = pm_secuencial,
      @w_op_moneda     = op_moneda
      from ca_pago_masivo,ca_operacion 
      where pm_usuario    = @s_user
        and pm_fecha_ing  = @i_fecha_ing
        and pm_operacion  = op_operacion
        and pm_estado     = 'ING'
        and pm_secuencial > @w_sec_previo
      order by pm_secuencial
           
      if @@rowcount = 0 break 
 
      -- DETERMINAR EL VALOR DE COTIZACION DEL DIA
      if @w_op_moneda = @w_moneda_nacional begin
         select @w_cotizacion_hoy = 1.0
      end else begin
         exec sp_buscar_cotizacion
         @i_moneda     = @w_op_moneda,
         @i_fecha      = @i_fecha_ing,
         @o_cotizacion = @w_cotizacion_hoy output
      end

      exec @w_return = sp_abonos_batch
           @s_user          = @s_user,
           @s_term          = @s_term,
           @s_date          = @s_date,
           @s_ofi           = @s_ofi,
           @i_en_linea      = 'N',
           @i_fecha_proceso = @i_fecha_ing,
           @i_operacionca   = @w_operacionca,
           @i_banco         = @w_banco,
           @i_cotizacion    = @w_cotizacion_hoy
              
       if  @w_return <> 0
       begin
          select @w_desc_error = mensaje
          from cobis..cl_errores
          where numero = @w_return
          select @w_estado_registro = 'ERRORPAGO'	
       end	   

      update ca_pago_masivo
      set pm_estado     = @w_estado_registro, 
          pm_desc_error = @w_desc_error
      where pm_usuario    = @s_user
        and pm_fecha_ing  = @i_fecha_ing
        and pm_secuencial = @w_sec_previo
   end        
end

return 0

ERROR1:
   select @w_desc_error = mensaje
   from cobis..cl_errores 
   where numero = @w_error
         
   update ca_pago_masivo
   set pm_estado = 'ERROR',
   pm_desc_error = @w_desc_error
   where pm_secuencial = @w_secuencial_reg 
   and pm_fecha_ing    = @i_fecha_ing
   and pm_usuario      = @s_user
   
   COMMIT TRAN
   return 0 

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_from  = @w_sp_name,
@i_num   = @w_error

return @w_error

go
