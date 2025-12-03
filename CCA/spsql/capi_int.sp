/************************************************************************/
/*     Archivo:                  capi_int.sp                            */
/*     Stored procedure:         sp_realiza_capitalizacion              */
/*     Base de datos:            cob_cartera                            */
/*     Producto:                 Cartera                                */
/*     Fecha de escritura:       Agosto-2005                            */
/************************************************************************/
/*                              IMPORTANTE                              */
/*     Este programa es parte de los paquetes bancarios propiedad de    */
/*     "MACOSA".                                                        */
/*     Su uso no  autorizado  queda  expresamente prohibido asi como    */
/*     cualquier  alteracion  o  agregado  hecho  por  alguno de sus    */
/*     usuarios  sin  el  debido  consentimiento  por  escrito de la    */
/*     Presidencia Ejecutiva de MACOSA o su representante.              */
/************************************************************************/
/*                               PROPOSITO                              */
/*     Este  programa  permite  actualizar el plan de pagos por         */
/*     el valor de capitalizacion segun especificacion del usuario      */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*     FECHA            AUTOR               RAZON                       */
/*     Agosto - 2005    Elcira Pelaez       Programa Inicial            */
/*     mayo-2006        Elcira Pelaez       def. 6537 de BAC            */
/************************************************************************/

use cob_cartera
go

if object_id('sp_realiza_capitalizacion') is not null
   drop proc sp_realiza_capitalizacion
go

create proc sp_realiza_capitalizacion
  @i_operacion          int,
  @i_moneda             smallint,
  @i_fecha_proc         datetime,
  @i_dividendo_ori      int,
  @i_concepto_ori       catalogo,
  @i_cotizacion         float,
  @i_dividendo_fin      int,
  @i_concepto_fin       catalogo,
  
  @i_estado_sec_1       int,
  @i_estado_sec_2       int,
  
  @i_monto_cap_normal   float,
  @i_monto_cap_sus      float,
  
  @i_secuencial         int,
  @i_fecha_proceso      datetime,
  @i_moneda_nac         smallint,
  @i_num_dec            float = 0
as
declare
   @w_num_dec            tinyint,
   @w_monto_mn           money,
   @w_cot_mn             money,
   @w_estado_fin         smallint,
   @w_monto_capitalizado float,
   @w_codvalor_fin       int,
   @w_codvalor_ini       int
   
begin
   ---print 'paga en la cuota %1! en el concepto %2! los montos %3! (normal)  %4! (sus)'+ @i_dividendo_ori+ @i_concepto_ori+ @i_monto_cap_normal+ @i_monto_cap_sus
   
   select @w_estado_fin = am_estado
   from   ca_amortizacion
   where  am_operacion = @i_operacion
   and    am_dividendo = @i_dividendo_fin
   and    am_concepto  =  @i_concepto_fin
   
   if @i_monto_cap_sus > 0.0001
   begin
      select @w_codvalor_ini = (co_codigo * 1000) + (@i_estado_sec_2 * 10)
      from   ca_concepto 
      where  co_concepto = @i_concepto_ori
      if @@rowcount = 0
         PRINT 'no existe codigo valor ' + cast(@i_concepto_ori as varchar)
      
      --CONVERSION POR LA MONEDA
      select @w_monto_mn = @i_monto_cap_sus,
             @w_cot_mn  = 1
      
      if @i_moneda  <> @i_moneda_nac
         select @w_monto_mn = round(@i_monto_cap_sus * @i_cotizacion,@i_num_dec),
                @w_cot_mn   = @i_cotizacion
      
      insert into ca_det_trn
            (dtr_secuencial,  dtr_operacion,    dtr_dividendo,
             dtr_concepto,
             dtr_estado,      dtr_periodo,      dtr_codvalor,
             dtr_monto,       dtr_monto_mn,     dtr_moneda,
             dtr_cotizacion,  dtr_tcotizacion,  dtr_afectacion,
             dtr_cuenta,      dtr_beneficiario, dtr_monto_cont)
      values(@i_secuencial,   @i_operacion,     @i_dividendo_ori,
             @i_concepto_ori,
             @i_estado_sec_2 , 0,                @w_codvalor_ini,
             @i_monto_cap_sus, @w_monto_mn,      @i_moneda,
             @w_cot_mn,       'N',              'D',
             ' ',             ' ',              0)
      
      if @@error != 0
      begin
         PRINT 'capi-int.sp error @i_secuencial ' + cast(@i_secuencial as varchar) + ' @i_concepto_ori ' + cast(@i_concepto_ori as varchar) + ' @i_monto_cap_sus ' + cast(@i_monto_cap_sus as varchar) + ' @w_codvalor_ini ' + cast(@w_codvalor_ini as varchar)
         return 708166
      end
      
      ---ACTAULIZA LA CA_AMORTIZACION CON LOS VALORES EN SUSPENSO
      update ca_amortizacion
      --set    am_pagado = am_pagado + @i_monto_cap_sus
      set    am_gracia = - @i_monto_cap_sus
      where  am_operacion = @i_operacion
      and    am_dividendo = @i_dividendo_ori
      and    am_concepto  = @i_concepto_ori
      and    am_secuencia = 2
      
      if @@error <> 0
         return 710002
      
      ---ACTAULIZA LA CA_OPERACION CON LOS VALORES EN SUSPENSO  EN PESOS     
      update ca_operacion
      set    op_cap_susxcor = op_cap_susxcor + @w_monto_mn
      where  op_operacion = @i_operacion
   end --valores en suspenso
   --
   begin
      select @w_monto_mn = @i_monto_cap_normal,
             @w_cot_mn  = 1
      
      if @i_moneda  <> @i_moneda_nac
         select @w_monto_mn = round(@i_monto_cap_normal * @i_cotizacion,@i_num_dec),
                @w_cot_mn  = @i_cotizacion
      
      select @w_codvalor_ini = (co_codigo * 1000) + (@i_estado_sec_1 * 10)
      from   ca_concepto 
      where  co_concepto = @i_concepto_ori  
      
      insert into ca_det_trn
            (dtr_secuencial,  dtr_operacion,    dtr_dividendo,
             dtr_concepto,
             dtr_estado,      dtr_periodo,      dtr_codvalor,
             dtr_monto,       dtr_monto_mn,     dtr_moneda,
             dtr_cotizacion,  dtr_tcotizacion,  dtr_afectacion,
             dtr_cuenta,      dtr_beneficiario, dtr_monto_cont)
      values(@i_secuencial,   @i_operacion,     @i_dividendo_ori,
             @i_concepto_ori,
             @i_estado_sec_1 ,    0,                @w_codvalor_ini,
             @i_monto_cap_normal, @w_monto_mn,      @i_moneda,
             @w_cot_mn,       'N',              'D',
             ' ',             ' ',              0)
      
      if @@error != 0
      begin
         PRINT 'capi-int.sp error einsertando en ca_det_trn 1'
         return 708166
       end
      
      update ca_amortizacion
      --set    am_pagado = am_pagado + @i_monto_cap_normal
      set    am_gracia = - @i_monto_cap_normal
      where  am_operacion = @i_operacion
      and    am_dividendo = @i_dividendo_ori
      and    am_concepto  = @i_concepto_ori
      and    am_secuencia = 1
      
      if @@error <> 0
         return 710002
   end  --valores normales
   
   select @w_codvalor_fin = (co_codigo * 1000) + (@w_estado_fin * 10)
   from   ca_concepto 
   where  co_concepto = @i_concepto_fin
   
   --ACTUALIZACION DEL RUBRO ORIGEN
   
   --ACTUALIZACION DEL RUBRO DESTINO
   select @w_monto_capitalizado = 0.0
   select @w_monto_capitalizado = @i_monto_cap_normal + @i_monto_cap_sus
   
   update ca_amortizacion
   set    am_cuota = am_cuota +  @w_monto_capitalizado,
          am_acumulado = am_acumulado +  @w_monto_capitalizado
   where  am_operacion = @i_operacion
   and    am_dividendo = @i_dividendo_fin
   and    am_concepto  = @i_concepto_fin
   
   if @@error <> 0
      return 710002
   
   select @w_monto_mn = @w_monto_capitalizado,
          @w_cot_mn  = 1
   
   if @i_moneda  <> @i_moneda_nac
      select @w_monto_mn = round(@w_monto_capitalizado * @i_cotizacion,@i_num_dec),
             @w_cot_mn  = @i_cotizacion
   
   insert into ca_det_trn
         (dtr_secuencial,  dtr_operacion,    dtr_dividendo,
          dtr_concepto,
          dtr_estado,      dtr_periodo,      dtr_codvalor,
          dtr_monto,       dtr_monto_mn,     dtr_moneda,
          dtr_cotizacion,  dtr_tcotizacion,  dtr_afectacion,
          dtr_cuenta,      dtr_beneficiario, dtr_monto_cont)
   values(@i_secuencial,   @i_operacion,   @i_dividendo_fin,
          @i_concepto_fin,
          @w_estado_fin,    0,                @w_codvalor_fin,
          @w_monto_capitalizado, @w_monto_mn,  @i_moneda,
          @w_cot_mn,       'N',              'C',
          ' ',             ' ',              0)
   
   if @@error != 0
   begin
      PRINT 'capi-int.sp error einsertando en ca_det_trn 3'
      return 708166
   end
   
   return 0
end
go
