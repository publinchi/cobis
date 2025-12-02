/************************************************************************/
/*   Archivo:              abonrudd.sp                                  */
/*   Stored procedure:     sp_abona_rubro_dd                            */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         EPB                                          */
/*   Fecha de escritura:   NOviembre 2005                               */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                           PROPOSITO                                  */
/*   Procedimiento que realiza el abono de los rubros de Cartera.       */
/*   a Operaciones de Documentos Descontados                            */
/************************************************************************/  
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_abona_rubro_dd')
   drop proc sp_abona_rubro_dd
go

create proc sp_abona_rubro_dd
@s_ofi                  smallint,
@s_sesn                 int,
@s_user                 login,
@s_term                 varchar (30)    = NULL,
@s_date                 datetime        = NULL,
@i_secuencial_pag       int,            -- Secuencial del pago (PAG)
@i_operacionca          int,            -- Operacion a la que pertenece el rubro
@i_dividendo            smallint,       -- Dividendo al cual pertenece el rubro
@i_monto_pago           money,          -- Monto Total del abono
@i_cotizacion           float,
@i_tcotizacion          char(1)         = NULL,
@i_moneda               smallint = 0,
@i_condonacion          char(1)  = null,
@i_colchon              char(1)  = null,
@o_sobrante_pago        money     = NULL   out


as
declare 
   @w_error                 int,
   @w_pago                  money,
   @w_pago_rubro            money,
   @w_pago_rubro_mn         money,
   @w_monto_rubro           money,
   @w_codvalor              int,
   @w_codvalor_con1         int,
   @w_codvalor1             int,
   @w_am_pagado             money,
   @w_am_acumulado          float,
   @w_am_estado             tinyint,
   @w_am_periodo            tinyint,
   @w_am_secuencia          tinyint,
   @w_am_gracia             money,
   @w_am_cuota              money,
   @w_est_condonado         tinyint,
   @w_est_cancelado         tinyint,
   @w_moneda_n              smallint,
   @w_afectacion            char(1),
   @w_dividendo             int,
   @w_num_dec               tinyint,
   @w_di_estado             tinyint,
   @w_num_dec_n             smallint,
   @w_prepago_int           money,    
   @w_am_estado_ar          tinyint,
   @w_afectacion_ar         char(1),
   @w_codvalor4             int,
   @w_parametro_col         catalogo,
   @w_tipo_rubro            char(1),
   @w_concepto              catalogo,
   @w_concepto_ar           catalogo,
   @w_tasa_pago             float,
   @w_rowcount              int


--CODIGO DEL CONCEPTO
select @w_parametro_col = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'COL'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
   return 710314
   

select @w_est_condonado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CONDONADO'

select @w_est_cancelado  = isnull(es_codigo, 255)
from   ca_estado
where  rtrim(ltrim(es_descripcion)) = 'CANCELADO'



select @w_pago = @i_monto_pago,
       @o_sobrante_pago = @i_monto_pago


-- LECTURA DE DECIMALES
exec @w_error = sp_decimales
     @i_moneda       = @i_moneda,
     @o_decimales    = @w_num_dec out,
     @o_mon_nacional = @w_moneda_n out,
     @o_dec_nacional = @w_num_dec_n out

if @w_error != 0 
   return @w_error

select @w_num_dec  = isnull(@w_num_dec,0)

if @i_moneda = 2
   select @w_num_dec_n = 2
 

select @w_afectacion = 'C' 


-- COMPROBAR QUE EL SOBRANTE SEA MAYOR A CERO
if @o_sobrante_pago < 0
   select @o_sobrante_pago = 0

declare
   secuencia_rubro cursor
      for select am_cuota,      am_acumulado,  am_pagado,
                 am_periodo,    am_estado,
                 am_secuencia,  am_gracia,     am_dividendo,
                 am_concepto
          from   ca_amortizacion
          where  am_operacion   =  @i_operacionca
          and    am_dividendo  =  @i_dividendo
          and    am_estado     !=  @w_est_cancelado
         union
         select am_cuota,      am_acumulado,  am_pagado,
                          am_periodo,    am_estado,
                          am_secuencia,  am_gracia,     am_dividendo,
                          am_concepto
            from ca_amortizacion,
                 ca_concepto,
                 ca_dividendo,
                 ca_rubro_op
            where am_operacion = @i_operacionca
            and   di_operacion = @i_operacionca
            and   ro_operacion = @i_operacionca
            and   am_operacion = di_operacion
            and   am_dividendo = di_dividendo
            and   di_operacion = ro_operacion
            and   co_concepto = am_concepto
            and   am_concepto  = ro_concepto
            and   co_categoria in ('S','V')
            and   am_estado != 3   
            and  (am_dividendo = @i_dividendo + charindex (ro_fpago, 'A'))
         order  by am_concepto, am_secuencia



          for read only

open secuencia_rubro

fetch secuencia_rubro
into  @w_am_cuota,      @w_am_acumulado,  @w_am_pagado,
      @w_am_periodo,    @w_am_estado,
      @w_am_secuencia,  @w_am_gracia,     @w_dividendo,
      @w_concepto

--while   @@fetch_status not in (-1, 0)
while   @@fetch_status = 0
begin
   
   if @w_pago <= 0
   begin
      break  
   end
   

   -- SELECCION DE CODIGO VALOR PARA EL RUBRO
   select @w_codvalor = co_codigo
   from   ca_concepto
   where  co_concepto = @w_concepto
   
   if @@rowcount = 0 
   begin
      PRINT 'abonrudd.sp @w_concepto ' + cast(@w_concepto as varchar)
      return 701151
   end
   
   
   select @w_tipo_rubro = ro_tipo_rubro,
          @w_tasa_pago  = isnull(ro_porcentaje,0.0)
   from ca_rubro_op
   where ro_operacion = @i_operacionca
   and ro_concepto = @w_concepto
   
   select @w_monto_rubro = @w_am_acumulado + @w_am_gracia - @w_am_pagado 
   select @o_sobrante_pago =  @o_sobrante_pago - @w_monto_rubro
   
   if @w_monto_rubro >= 0
   begin 
      
      
      if (@w_pago >= @w_monto_rubro)  
         select @w_pago_rubro = @w_monto_rubro
      else 
         select @w_pago_rubro = @w_pago 
      
   
      select @w_pago = @w_pago - @w_pago_rubro --REBAJO PAGO
      
      select @w_pago_rubro_mn =  round(@w_pago_rubro * @i_cotizacion, @w_num_dec)
      select @w_pago_rubro    =  round(@w_pago_rubro,@w_num_dec)
      select @w_pago_rubro_mn =  round(@w_pago_rubro_mn,@w_num_dec_n) 
      
      
      ---PRINT 'abonorudd.sp concepto %1! valor_rubro %2!'+@w_concepto+@w_monto_rubro
      
      -- GENERACION DE LOS CODIGOS VALOR
      select @w_codvalor1     = (@w_codvalor * 1000) + (@w_am_estado * 10) + @w_am_periodo,
             @w_codvalor_con1 = (@w_codvalor * 1000) + (@w_am_estado * 10) + @w_est_condonado
      

         select @w_am_estado_ar    = @w_am_estado,
                @w_concepto_ar     = @w_concepto,
                @w_afectacion_ar   = @w_afectacion
         
         if exists(select 1 from ca_det_trn
                   where dtr_operacion  = @i_operacionca
                   and   dtr_secuencial = @i_secuencial_pag
                   and   dtr_dividendo  = @w_dividendo 
                   and   dtr_concepto   = @w_concepto
                   and   dtr_codvalor   = @w_codvalor1)   
         begin
            update ca_det_trn
            set    dtr_monto            = dtr_monto    + @w_pago_rubro,
                   dtr_monto_mn         = dtr_monto_mn + @w_pago_rubro_mn
            where dtr_operacion  = @i_operacionca
            and   dtr_secuencial = @i_secuencial_pag
            and   dtr_dividendo  = @w_dividendo 
            and   dtr_concepto   = @w_concepto
            and   dtr_codvalor   = @w_codvalor1
            
            if @@error != 0 return 708166
         end
         ELSE
         begin
               insert into ca_det_trn
                     (dtr_secuencial,     dtr_operacion,  dtr_dividendo,
                      dtr_concepto,       dtr_estado,     dtr_periodo,
                      dtr_codvalor,       dtr_monto,      dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion, dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,     dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag,  @i_operacionca, @w_dividendo,
                      @w_concepto,        @w_am_estado,   @w_am_periodo,
                      @w_codvalor1,       @w_pago_rubro,  @w_pago_rubro_mn,
                      @i_moneda,          @i_cotizacion,  @i_tcotizacion,
                      @w_afectacion,      '00000',        'CARTERA',
                      0.00)
               
               if @@error != 0
                  return 708166
         end 
         
         -- GENERACION DE LA AFECTACION CONTABLE CASO CONDONACION
         if @i_condonacion = 'S'  and @i_colchon = 'N' 
         begin
            select @w_am_estado_ar    = @w_est_condonado,
                   @w_concepto_ar     = @w_concepto,
                   @w_afectacion_ar   = @w_afectacion
            
            if exists (select 1 from ca_det_trn
                       where dtr_operacion  = @i_operacionca
                       and   dtr_secuencial = @i_secuencial_pag
                       and   dtr_dividendo  = @w_dividendo 
                       and   dtr_concepto   = @w_concepto
                       and   dtr_codvalor   = @w_codvalor_con1)   
            begin
               update ca_det_trn
               set    dtr_monto    = dtr_monto    + @w_pago_rubro,
                      dtr_monto_mn = dtr_monto_mn + @w_pago_rubro_mn
               where dtr_operacion  = @i_operacionca
               and   dtr_secuencial = @i_secuencial_pag
               and   dtr_dividendo  = @w_dividendo 
               and   dtr_concepto   = @w_concepto
               and   dtr_codvalor   = @w_codvalor_con1
               
               if @@error != 0 return 708166
            end 
            ELSE 
            begin
               insert into ca_det_trn
                     (dtr_secuencial,   dtr_operacion, dtr_dividendo,
                      dtr_concepto,       dtr_estado,    dtr_periodo,
                      dtr_codvalor,       dtr_monto,     dtr_monto_mn,
                      dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
                      dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
                      dtr_monto_cont)
               values(@i_secuencial_pag, @i_operacionca,  @w_dividendo,
                      @w_concepto,       @w_est_condonado,@w_am_periodo,
                      @w_codvalor_con1,  @w_pago_rubro,   @w_pago_rubro_mn,
                      @i_moneda,      @i_cotizacion,   @i_tcotizacion,   
                      'D',              '00000',      'CARTERA',
                      0.00)
               
               if @@error != 0 return 708166
            end 
         end -- Condonacion
         
         -- Colchon
         if @i_colchon = 'S'  
         begin
            select @w_am_estado_ar    = @w_am_estado,
                   @w_concepto_ar     = @w_parametro_col,
                   @w_afectacion_ar   = 'D'
            
            select @w_codvalor4 = co_codigo * 1000  
            from  ca_concepto
            where co_concepto  = @w_parametro_col
            
            insert into ca_det_trn
                  (dtr_secuencial,   dtr_operacion, dtr_dividendo,
                   dtr_concepto,       dtr_estado,    dtr_periodo,
                   dtr_codvalor,       dtr_monto,     dtr_monto_mn,
                   dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
                   dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
                   dtr_monto_cont)
            values(@i_secuencial_pag, @i_operacionca,  @w_dividendo,
                   @w_parametro_col,  @w_am_estado,    @w_am_periodo,
                   @w_codvalor4,       @w_pago_rubro,   @w_pago_rubro_mn,
                   @i_moneda,       @i_cotizacion,   @i_tcotizacion,   
                   'D',              '00000',      'CARTERA',
                   0.00)
         end 
         -- Fin Colchon
         
         -- Alimentar tabla ca_abono_rubro
         insert into ca_abono_rubro
               (ar_fecha_pag,        ar_secuencial,             ar_operacion,                ar_dividendo,
                ar_concepto,         ar_estado,                 ar_monto,
                ar_monto_mn,         ar_moneda,                 ar_cotizacion,               ar_afectacion,
                ar_tasa_pago,        ar_dias_pagados)
         values(@s_date,             @i_secuencial_pag,      @i_operacionca,       @w_dividendo,
                @w_concepto_ar,      @w_am_estado_ar,        @w_pago_rubro,
                @w_pago_rubro_mn,    @i_moneda,           @i_cotizacion,         @w_afectacion_ar,
                @w_tasa_pago,        0)
      
      -- ACTUALIZAR LA AMORTIZACION DEL RUBRO
         update ca_amortizacion
         set    am_pagado    = am_pagado + @w_pago_rubro
         where  am_operacion = @i_operacionca
         and    am_dividendo = @w_dividendo
         and    am_concepto  = @w_concepto
         and    am_secuencia = @w_am_secuencia
         
         if @@error ! = 0
            return 705050  
      
      
         if @w_tipo_rubro <> 'M'
         begin
            update ca_amortizacion
            set    am_estado = @w_est_cancelado
            where  am_cuota     = am_pagado
            and    am_operacion = @i_operacionca
            and    am_dividendo = @w_dividendo
            and    am_concepto  = @w_concepto
            and    am_secuencia = @w_am_secuencia
            
            if @@error ! = 0
               return 705050 
         end
 


      update ca_amortizacion
      set    am_acumulado = am_cuota
      where  am_cuota     = am_pagado
      and    am_operacion = @i_operacionca
      and    am_dividendo = @w_dividendo
      and    am_concepto  = @w_concepto
      and    am_secuencia = @w_am_secuencia
      and    @w_tipo_rubro != 'I'
      
      if @@error ! = 0
         return 705050  
         
   end       
   
   fetch secuencia_rubro
   into  @w_am_cuota,      @w_am_acumulado,  @w_am_pagado,
         @w_am_periodo,    @w_am_estado,
         @w_am_secuencia,  @w_am_gracia,     @w_dividendo,
         @w_concepto
end -- CA_AMORTIZACION

close secuencia_rubro
deallocate secuencia_rubro

return 0
go
