/************************************************************************/
/* Base de datos:          cob_cartera                                  */
/* Producto:               Cartera                                      */
/* Archivo:                aplprop.sp                                   */
/* Procedimiento:          sp_aplicacion_proporcional                   */
/* Disenado por:           FQ                                           */
/* Fecha de escritura:     16 de Marzo 2005                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Aplica el abono directo a capital de forma proporcional         */
/*      Este progarma se ejecuta desde al aboncoa.sp solo si el tipo    */
/*      de aplicacion es Proporcional P                                 */
/*      Aplica directamente a capital                                   */
/************************************************************************/
/*                              CAMBIOS                                 */
/*  CONTROL Junio 04 -2007 DEF 8293 Aplicacion de pago proporcional     */
/*  para cualquier obligacion                                           */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/*      JUL-10-2007      EPB                  def 8414 sp_agotada       */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_aplicacion_proporcional')
   drop proc sp_aplicacion_proporcional
go
---Ver.7 julo-10-2007
create proc sp_aplicacion_proporcional
@s_user                  login,
@s_term                  varchar(30),
@s_date                  datetime, 
@s_ofi                   int,
@i_operacionca           int,
@i_secuencial_pag        int,
@i_monto_pago            money,
@i_moneda                smallint,
@i_cotizacion            float,
@i_num_dec               tinyint,
@i_fpago                 catalogo,
@i_en_linea              char(1) = 'S',
@i_banco                 cuenta,
@i_fecha_proceso         datetime,
@o_sobrante              money      = null out


as
declare
   @w_error              int,
   @w_saldo              float,
   @w_di_dividendo       int,
   
   @w_saldo_cuota        float,
   @w_proporcion_cuota   float,
   @w_monto_pag_cuota    float,
   @w_monto_pag_cuota_mn float,
   
   @w_am_estado          tinyint,
   @w_am_periodo         tinyint,
   @w_codigo_concepto    int,
   @w_concepto_cap       catalogo,
   @w_codvalor           int,
   @w_beneficiario       char(64),
   @w_sobrante           money,
   @w_tipo               char(1),
   @w_tramite            int,
   @w_monto_aplicado_cap money,
   @w_monto_aplicado_cap_mn money,
   @w_moneda                smallint,
   @w_saldo_cap_gar         money,
   @w_capitaliza            char(1)

begin
   
 
   select @w_tipo = op_tipo,
          @w_tramite = op_tramite,
          @w_moneda  = op_moneda
   from ca_operacion
   where  op_operacion = @i_operacionca       
   
   select @w_concepto_cap  = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'CAP'
   set transaction isolation level read uncommitted
   
   select @w_codigo_concepto = co_codigo
   from   ca_concepto
   where  co_concepto = @w_concepto_cap
   
   select @w_saldo = sum(am_acumulado - am_pagado)
   from   ca_amortizacion, ca_dividendo
   where  am_operacion = @i_operacionca
   and    am_concepto = @w_concepto_cap
   and    di_operacion = @i_operacionca
   and    di_estado    in (0, 1)
   and    am_dividendo = di_dividendo
   
   if @w_saldo <= 0
    return 710442

   if @i_monto_pago > @w_saldo
     return 710442

   ---SALDO PARA sp_aagotada debe ser antes de la aplicacion del pago
   --------------------------------------------------------------------     

   select @w_saldo_cap_gar = @i_cotizacion * (sum(am_cuota - am_pagado))
   from   ca_amortizacion, ca_rubro_op
   where  ro_operacion  = @i_operacionca
   and    ro_tipo_rubro = 'C'
   and    am_operacion  = @i_operacionca
   and    am_estado <> 3
   and    am_concepto   = ro_concepto
     
   
   -- CURSOR POR LOS DIVIDENDOS CON SALDO DE CAPITAL
   declare
      cur_dividendo cursor
      for select di_dividendo
          from   ca_dividendo
          where  di_operacion = @i_operacionca
          and    di_estado in (0, 1)
          order  by di_dividendo
      for read only
   
   open cur_dividendo
   
   fetch cur_dividendo
   into  @w_di_dividendo

--   while @@fetch_status not in (-1, 0)   
   while @@fetch_status = 0
   begin
      -- CALCULAR SALDO DE LA CUOTA
      select @w_saldo_cuota = sum(am_acumulado + am_gracia - am_pagado)
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_di_dividendo
      and    am_concepto  = @w_concepto_cap

      select @w_am_estado = am_estado,
             @w_am_periodo = am_periodo
      from   ca_amortizacion
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_di_dividendo
      and    am_concepto  = @w_concepto_cap
      
      -- PROPORCION DE LA CUOTA EN EL SALDO
      select @w_proporcion_cuota = @w_saldo_cuota / @w_saldo

      select @w_monto_pag_cuota = @i_monto_pago *  @w_proporcion_cuota
      
      select @w_monto_pag_cuota = round(@w_monto_pag_cuota, @i_num_dec)
      
      -- ESTO ES POR SI ACASO EL SALDO FINAL SOBREPASA EL SALDO DE LA CUOTA POR EL REDONDEO
      if @w_monto_pag_cuota > @w_saldo_cuota
         select @w_monto_pag_cuota = @w_saldo_cuota
      
      select @w_monto_pag_cuota_mn = round(@w_monto_pag_cuota * @i_cotizacion, 0)
      
      select @w_codvalor = (@w_codigo_concepto * 1000) + (@w_am_estado * 10) + @w_am_periodo
      
      -- INSERTAR LOS REGISTROS DE ca_det_trn y actualizar ca_amortizacion
      
      ---PRINT 'aplprop.sp @w_di_dividendo %1! @w_monto_pag_cuota %2!',@w_di_dividendo,@w_monto_pag_cuota
      
      update ca_amortizacion
      set    am_pagado = am_pagado + @w_monto_pag_cuota
      where  am_operacion = @i_operacionca
      and    am_dividendo = @w_di_dividendo
      and    am_concepto  = @w_concepto_cap
      
      if @w_monto_pag_cuota_mn > 0
      begin
         select @w_beneficiario = 'PAGO PROPORCIONAL ' +  cast(@i_fpago as varchar)    --ESTABA COMENTADO
         insert into ca_det_trn
               (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                dtr_concepto,       dtr_estado,     dtr_periodo,
                dtr_codvalor,       dtr_monto,      dtr_monto_mn,
                dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                dtr_monto_cont)
         values(@i_secuencial_pag,  @i_operacionca, @w_di_dividendo,
                @w_concepto_cap,    @w_am_estado,   @w_am_periodo,
                @w_codvalor,        @w_monto_pag_cuota,
                @w_monto_pag_cuota_mn,
                @i_moneda,          @i_cotizacion,  'N',
                'C',                '00000',        @w_beneficiario,
                0.00)
         
         if @@error != 0
            return 708166
         
         -- ALIMENTAR TABLA CA_ABONO_RUBRO
         insert into ca_abono_rubro
               (ar_fecha_pag,          ar_secuencial,       ar_operacion,  ar_dividendo,
                ar_concepto,           ar_estado,           ar_monto,
                ar_monto_mn,           ar_moneda,           ar_cotizacion, ar_afectacion,
                ar_tasa_pago,          ar_dias_pagados)
         values(@s_date,               @i_secuencial_pag,   @i_operacionca,   @w_di_dividendo,
                @w_concepto_cap,       @w_am_estado,        @w_monto_pag_cuota,
                @w_monto_pag_cuota_mn, @i_moneda,           @i_cotizacion,       'C',
                0,                     0)
      end
      select @w_saldo = @w_saldo - @w_saldo_cuota
      select @i_monto_pago = @i_monto_pago - @w_monto_pag_cuota
      
      ---
      fetch cur_dividendo
      into  @w_di_dividendo
   end
   
   close cur_dividendo
   deallocate cur_dividendo
   
   select @w_sobrante = @i_monto_pago -- ESTO SIEMPRE DEBERIA SER 0
   
   select @o_sobrante =   @w_sobrante

   if @w_sobrante > 0
      return  710462
   
   ---REAJSUTAR LA TABLA EN INTERESES
   exec @w_error = sp_reajuste_interes
        @s_user           = @s_user,
        @s_term           = @s_term,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @i_operacionca    = @i_operacionca,
        @i_fecha_proceso  = @i_fecha_proceso,
        @i_banco          = @i_banco,
        @i_en_linea       = @i_en_linea
   
   if @w_error != 0 
      return @w_error


---   -- INTERFAZ CON CREDITO Y GARANTIAS

if @w_tipo not in ('D','G','R')
begin
         
   select @w_monto_aplicado_cap = sum(dtr_monto)
   from   cob_cartera..ca_det_trn
   where  dtr_operacion  = @i_operacionca
   and    dtr_secuencial = @i_secuencial_pag
   and    dtr_concepto   = @w_concepto_cap
   and    dtr_codvalor != 10099
   and    dtr_codvalor != 10019
   and    dtr_codvalor != 10370
   and    dtr_codvalor != 10990
   and    dtr_codvalor != 21370
   and    dtr_codvalor != 19370 
   and    dtr_codvalor != 52370 
   
   select @w_monto_aplicado_cap_mn = sum(dtr_monto_mn)
   from   cob_cartera..ca_det_trn
   where  dtr_operacion  = @i_operacionca
   and    dtr_secuencial = @i_secuencial_pag
   and    dtr_concepto   = @w_concepto_cap
   and    dtr_codvalor != 10099
   and    dtr_codvalor != 10019
   and    dtr_codvalor != 10370
   and    dtr_codvalor != 10990
   and    dtr_codvalor != 21370
   and    dtr_codvalor != 19370 
   and    dtr_codvalor != 52370 


   if (@w_monto_aplicado_cap > 0 and @w_tramite is not null)
   begin
         declare
            @w_cu_estado            char(1),
            @w_cu_agotada           char(1),
            @w_cu_abierta_cerrada   char(1),
            @w_cu_tipo_gar          varchar(64),
            @w_cu_contabilizar      char(1)
         
         select @w_cu_estado          = cu_estado,
                @w_cu_agotada         = cu_agotada,
                @w_cu_abierta_cerrada = cu_abierta_cerrada,
                @w_cu_tipo_gar        = cu_tipo
         from   cob_custodia..cu_custodia,
                cob_credito..cr_gar_propuesta
         where  gp_garantia = cu_codigo_externo 
         and    cu_agotada = 'S'
         and    gp_tramite = @w_tramite
         
         select @w_cu_contabilizar = tc_contabilizar
         from   cob_custodia..cu_tipo_custodia
         where  tc_tipo = @w_cu_tipo_gar
         
         if (@w_cu_estado = 'V'
            and @w_cu_agotada = 'S'
            and @w_cu_abierta_cerrada = 'C'
            and @w_cu_contabilizar = 'S')
         begin


         select @w_capitaliza = 'N'
         if exists (select 1 from ca_acciones
                    where ac_operacion = @i_operacionca)
                    select @w_capitaliza = 'S'    ---433
               
               exec @w_error = cob_custodia..sp_agotada 
                    @s_ssn             = 1,
                    @s_date            = @s_date,
                    @s_user            = @s_user,
                    @s_term            = @s_term,
                    @s_ofi             = @s_ofi,
                    @t_trn             = 19911,
                    @t_debug           = 'N',
                    @t_file            = NULL,
                    @t_from            = NULL,
                    @i_operacion       = 'P',                      --- PAGO  'R' REVERSA DE PAGO
                    @i_monto           = @w_monto_aplicado_cap,    --- MONTO DEL PAGO
                    @i_monto_mn        = @w_monto_aplicado_cap_mn, ---MONTO MONEDA NACIONAL
                    @i_moneda          = @i_moneda,                --- MONEDA DEL PAGO
                    @i_saldo_cap_gar   = @w_saldo_cap_gar,         ---Antes de hacer el pago
                    @i_tramite         = @w_tramite,
                    @i_capitaliza      = @w_capitaliza --- NR 433                --- TRAMITE 
               
               if @@error != 0 
                  return  720308
               
               if @w_error != 0
                  return @w_error
                  
         end --garantia agotada
     end -- pago capital
    end --es activa valida

end --Geenral
return 0

go
