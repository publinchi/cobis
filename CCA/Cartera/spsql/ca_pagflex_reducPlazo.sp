/************************************************************************/
/*   Archivo:            ca_pagflex_reducPlazo.sp                      */
/*   Stored procedure:   sp_ca_pagflex_reduce_Plazo                     */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Elcira PElaez Burbano                          */
/*   Fecha de escritura: May 2014                                       */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                          PROPOSITO                                   */
/*   Procedimiento  aplica un pago extraordinario a reduciendo plazo    */
/*   en las tablas FLEXIBLES                                            */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA           AUTOR      RAZON                                    */
/*      05/12/2016          R. Sanchez            Modif. Apropiación  */
/*  DIC/03/2020   Patricio Narvaez  Causacion en moneda nacional        */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca_pagflex_reduce_Plazo')
   drop proc sp_ca_pagflex_reduce_Plazo
go

create proc sp_ca_pagflex_reduce_Plazo
   @s_user              login,
   @s_term              varchar(30),
   @s_date              datetime,
   @s_ofi               int,
   @i_operacionca       int,
   @i_dividendo         smallint,
   @i_monto_pago        money,
   @i_secuencial_pag    int,
   @i_rubro_cap         catalogo,
   @i_cotizacion        money     = 1,
   @i_tcotizacion       char(1)   = 'C',
   @i_en_linea          char(1),
   @i_num_dec           int = 0,
   @i_num_dec_n         int = 0,
   @i_tiene_reco        char(1) = 'N',
   @o_monto_sobrante    float = NULL out
   

as  
declare 
   @w_error             int,
   @w_dividendo         smallint,
   @w_operacion         int,
   @w_fecha_ini         datetime,
   @w_fecha_ven         datetime,
   @w_banco             cuenta,
   @w_toperacion        catalogo,
   @w_oficina           int,
   @w_gar_admisible     catalogo,
   @w_reestructuracion  catalogo,
   @w_calificacion      catalogo,
   @w_fecha_proceso     datetime,
   @w_oficial           int,
   @w_moneda            smallint,
   @w_valor_cuota_cap   money,
   @w_valor_sobrante    money,
   @w_salir             char(1),
   @w_codvalor          int,
   @w_pago_cap_mn       money,
   @w_pago_cap          money,
   @w_ult_div_vig       smallint,
   @w_vlr_despreciable  float,
   @w_est_cancelado     tinyint,
   @w_est_novigente     tinyint,
   @w_est_vigente       tinyint,
   @w_bandera_be        char(1),
   @w_tramite           int,
   @w_saldo_cap         money,
   @w_new_fecven_op     datetime,
   @w_vlr_x_amort       money, 
   @w_porc_cubrim       float, 
   @w_vlr_cap           money, 
   @w_concepto_rec      char(1),
   @w_sob_rec           money,
   @w_pago              money,
   @w_estado_op         smallint,
   @w_parametro_fng     catalogo,
   @w_mipymes           catalogo

  
      
--PARAMETROS GENERALES
exec @w_error = sp_estados_cca
@o_est_vigente    = @w_est_vigente   out,
@o_est_cancelado  = @w_est_cancelado out,
@o_est_novigente  = @w_est_novigente out

if @w_error <> 0 return @w_error


select @w_parametro_fng = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'CCA'
and    pa_nemonico = 'COMFNG'

select @w_mipymes = pa_char 
from cobis..cl_parametro with (nolock)
where pa_producto  = 'CCA'
and   pa_nemonico  = 'MIPYME'


create table  #acumulado_vigente(
operacion     int       null, 
concepto      catalogo  null, 
cuota         money     null,
dividendo     smallint   null
)
---ESTA TABLA SE CARGA CON LOS RUBROS QUE SON RECALCULADO EN LA CUOTA VIGENTE
---DESPUES DEL ABONO EXTRAORDINARIO

insert into #acumulado_vigente
select 
am_operacion,
am_concepto,
am_cuota,
am_dividendo
from ca_amortizacion,
     ca_dividendo,
     ca_rubro_op
where am_operacion = @i_operacionca
and  am_operacion = di_operacion
and  am_dividendo = di_dividendo
and  di_estado    = @w_est_vigente
and  am_operacion = ro_operacion
and  am_concepto  = ro_concepto
and  am_cuota      > 0
and  am_acumulado  > 0
and  ro_tipo_rubro in('Q','O')
and  ro_fpago      in ('A','P') 


select @w_vlr_despreciable = 1.0 / power(10, isnull(@i_num_dec, 4)),
       @w_sob_rec = 0
       
-- SALVO EL VALOR INICIAL
select @w_pago        = @i_monto_pago,
       @w_salir      = 'N'
--- SI LA OBLIGACION TIENE RECONOCIMIENTO SE CONSULTAN DATOS ASOCIADOS AL PAGO 
if @i_tiene_reco = 'S'
begin

   exec @w_error = sp_pagxreco
        @i_tipo_oper      = 'Q',
        @i_operacionca    = @i_operacionca,
        @i_secuencial_pag = @i_secuencial_pag,
        @o_porc_cubrim    = @w_porc_cubrim out,
        @o_vlr_x_amort    = @w_vlr_x_amort out,
        @o_concepto_rec   = @w_concepto_rec out

   if @w_error <> 0 
      return @w_error
      
   if @i_tiene_reco = 'S' and @w_concepto_rec = 'N'
      begin
         select @w_vlr_cap = 0
         select @w_vlr_cap = round(@w_pago * @w_porc_cubrim / 100, @i_num_dec)
   
         select @w_pago = @w_pago - @w_vlr_cap
   
      --Amortiza reconocimiento realizando abono extraordinario
         select @w_sob_rec = 0
         exec @w_error = sp_pagxreco
         @s_user             = @s_user,
         @s_term             = @s_term,
         @s_date             = @s_date,
         @i_tipo_oper        = 'P',
         @i_secuencial_pag   = @i_secuencial_pag,
         @i_operacionca      = @i_operacionca,
         @i_en_linea         = @i_en_linea,
         @i_oficina_orig     = @s_ofi,
         @i_num_dec          = @i_num_dec,
         @i_monto_pago       = @w_vlr_cap,
         @o_sobrante         = @w_sob_rec out
   
         if @w_error <> 0 return @w_error
   
         select @w_pago = @w_pago + @w_sob_rec
         
         ---ESTE ES EL VALOR REAL QUE SE APLICA POR QUE EL RESTO ES UN %
         ---QUE DEBE APLICARSE A LA TABLA DE REDESCUENTO
         select @w_valor_sobrante = @w_pago
   end --SE hace reconocimiento
         
end
else
begin
  ---EL VALOR TOTAL ES PARA PAGO EXTRAORDINARIO
   select @w_valor_sobrante = @i_monto_pago
end

if (@w_valor_sobrante is null ) or (@w_valor_sobrante <= 0)
   return 724018
    
select @w_banco             = op_banco,
       @w_tramite           = op_tramite,
       @w_toperacion        = op_toperacion,
       @w_oficina           = op_oficina,
      @w_gar_admisible     = isnull(op_gar_admisible,'N'),
      @w_reestructuracion  = isnull(op_reestructuracion,'N'),
      @w_calificacion      = isnull(op_calificacion,'A'),
      @w_fecha_proceso     = op_fecha_ult_proceso,
      @w_oficial           = op_oficial,
       @w_moneda            = op_moneda
from ca_operacion with (nolock)
where op_operacion = @i_operacionca

select dividendo = di_dividendo,
       operacion = di_operacion,
       fecha_ini = di_fecha_ini,
       fecha_ven = di_fecha_ven
into #dividendos
from ca_dividendo
where di_operacion = @i_operacionca
and di_estado in (1,0)       

select @w_codvalor = (co_codigo * 1000) + (1 * 10)
from ca_concepto
where co_concepto = @i_rubro_cap
       
select @w_ult_div_vig = max(di_dividendo)
from ca_dividendo
where di_operacion = @i_operacionca
and   di_estado = @w_est_vigente

declare cur_reduce_Plazo cursor for select
dividendo,
operacion,
fecha_ini,
fecha_ven
from  #dividendos
where operacion = @i_operacionca
order by dividendo desc 

for read only
open cur_reduce_Plazo
fetch cur_reduce_Plazo into
@w_dividendo,
@w_operacion,
@w_fecha_ini,
@w_fecha_ven

while @@fetch_status  = 0
begin
    
    select @w_valor_cuota_cap = 0,
           @w_pago_cap        = 0
    select @w_valor_cuota_cap = sum(am_cuota - am_pagado)
    from ca_amortizacion with (nolock),
         ca_rubro_op  with (nolock)
    where am_operacion = @i_operacionca
    and am_dividendo = @w_dividendo
    and am_operacion = ro_operacion
    and am_concepto = ro_concepto
    and ro_tipo_rubro = 'C'
   
    if @w_valor_sobrante >= @w_valor_cuota_cap
    begin
       select @w_pago_cap   = @w_valor_cuota_cap
      --- print 'div : ' + cast (@w_dividendo as varchar) + '  @w_valor_cuota_cap: ' + cast(@w_valor_cuota_cap as varchar) + ' @w_valor_sobrante : ' + cast(@w_valor_sobrante as varchar)
       
       ---SE HACE OLA REDUCCION DE LA CUOTA
       delete ca_dividendo
       where di_operacion = @i_operacionca
       and di_dividendo = @w_dividendo
       if @@error <> 0
          return 724011

       delete ca_amortizacion
       where am_operacion = @i_operacionca
       and am_dividendo = @w_dividendo
       and am_pagado = 0
       if @@error <> 0
          return 724012
       
    end --pago y reduce cuota
    ELSE
    begin
         if  @w_valor_sobrante > 0
             select @w_pago_cap  = @w_valor_sobrante
         else
             select @w_pago_cap  = 0
      
        ---print 'COLITA FINAL : ' + cast (@w_dividendo as varchar) + '  @w_valor_cuota_cap: ' + cast(@w_valor_cuota_cap as varchar) + ' @w_valor_sobrante : ' + cast(@w_valor_sobrante as varchar) + ' @w_ult_div_vig : ' + cast (@w_ult_div_vig as varchar)
        select @w_salir = 'S'
        ---HAY QUE REDUCIR ESTE VALOR DE LA TABLA DE LA ULTIMA CUOTA
        ---YA QUE ESTE QUEDA COMO PAGADO EN LA CUOTA VIGENTE
        update ca_amortizacion 
        set    am_cuota      = am_cuota  - @w_pago_cap,
               am_acumulado  = am_acumulado - @w_pago_cap
        where am_operacion   = @i_operacionca
        and   am_dividendo   = @w_dividendo
        and   am_concepto    =  @i_rubro_cap
          if @@error <> 0
             return 724010
      
    end
    --ESTE VALOR SE VA PONIENDO EN LA ULTIMA CUOTA QUE TENGA  VIGENTE
     update ca_amortizacion 
     set    am_pagado     = am_pagado + @w_pago_cap,
            am_cuota      = am_cuota  + @w_pago_cap,
            am_acumulado  = am_acumulado + @w_pago_cap
     where am_operacion   = @i_operacionca
     and   am_dividendo   = @w_ult_div_vig
     and   am_concepto    =  @i_rubro_cap
       if @@error <> 0
          return 724010
            
    ---IR DISMINUYENDO VALOR
    select @w_valor_sobrante = @w_valor_sobrante - @w_pago_cap
    
      ---REGSITRO DETALLE DEL PAGO
      select @w_pago_cap_mn =  round(@w_pago_cap * @i_cotizacion, @i_num_dec)
      insert into ca_det_trn
             (dtr_secuencial,    dtr_operacion,    dtr_dividendo,
              dtr_concepto,      dtr_estado,       dtr_periodo,
              dtr_codvalor,      dtr_monto,        dtr_monto_mn,
              dtr_moneda,        dtr_cotizacion,   dtr_tcotizacion,
              dtr_afectacion,    dtr_cuenta,       dtr_beneficiario,
              dtr_monto_cont)
       values(@i_secuencial_pag, @i_operacionca,   @w_ult_div_vig,
              @i_rubro_cap,      @w_est_vigente,   0,
              @w_codvalor,       @w_pago_cap,      @w_pago_cap_mn,
              @w_moneda,         @i_cotizacion,    @i_tcotizacion,
              'C',               '00000',          'CARTERA',
              0.00)
       
       if @@error <> 0
          return 724008    
          
         -- ALIMENTAR TABLA CA_ABONO_RUBRO
         insert into ca_abono_rubro
               (ar_fecha_pag,    ar_secuencial,       ar_operacion,     ar_dividendo,
                ar_concepto,     ar_estado,           ar_monto,
                ar_monto_mn,     ar_moneda,           ar_cotizacion,    ar_afectacion,
                ar_tasa_pago,    ar_dias_pagados)
         values(@s_date,         @i_secuencial_pag,   @i_operacionca,   @w_ult_div_vig,
                @i_rubro_cap,    @w_est_vigente,      @w_pago_cap,
                @w_pago_cap_mn,  @w_moneda,           @i_cotizacion,    'C',
                1,    1)
       if @@error <> 0
          return 724009                 
                
          
    if @w_salir = 'S'
    begin
       close cur_reduce_Plazo
       deallocate cur_reduce_Plazo
       goto FIN
    end
       
   fetch cur_reduce_Plazo
   into  @w_dividendo, @w_operacion, @w_fecha_ini, @w_fecha_ven      
end ---Cursor

close cur_reduce_Plazo
deallocate cur_reduce_Plazo

FIN:
begin
 ---PRINT 'Salir por que finalizo la aplicacion del pago  @w_valor_sobrante ' + cast ( @w_valor_sobrante as varchar)
    update ca_amortizacion
    set  am_estado = @w_est_cancelado
    where am_operacion = @i_operacionca
    and am_estado <>  @w_est_cancelado
    and (am_acumulado - am_pagado ) = 0
    and am_concepto = @i_rubro_cap
   if @@error <> 0
      return 724028

 select @o_monto_sobrante  = @w_valor_sobrante
 
   select @w_new_fecven_op= max(di_fecha_ven)
   from ca_dividendo
   where di_operacion = @i_operacionca
    
   update ca_operacion
   set op_fecha_fin = @w_new_fecven_op
   where op_operacion = @i_operacionca
   if @@error <> 0
      return 724017

   -- DETERMINACION DEL SALDO DE CAPITAL DE LA OPERACION
   select @w_saldo_cap   = isnull(sum(am_cuota - am_pagado),0)
   from   ca_amortizacion
   where  am_operacion  = @i_operacionca
   and    am_concepto = @i_rubro_cap
   
      -- VERIFICAR SI EL PAGO EXTRAORIDINARIO CANCELO EL PRESTAMO
      if @w_saldo_cap < @w_vlr_despreciable
      begin
      
         --GENERACION DE LA COMISION DIFERIDA
         exec @w_error     = sp_comision_diferida
         @s_date           = @s_date,
         @i_operacion      = 'A',
         @i_operacionca    = @i_operacionca,
         @i_secuencial_ref = @i_secuencial_pag,
         @i_num_dec        = @i_num_dec,
         @i_num_dec_n      = @i_num_dec_n,
         @i_cotizacion     = @i_cotizacion,
         @i_tcotizacion    = @i_tcotizacion  
         
         if @w_error <> 0  return 724589 
      
         update ca_operacion
         set    op_estado = @w_est_cancelado
         where  op_operacion = @i_operacionca
         
         if @@error <> 0
            return 724016
         
         update ca_amortizacion
         set    am_cuota = 0,
                am_acumulado = 0
         from   ca_dividendo
         where  am_operacion = @i_operacionca
         and    am_concepto  = @i_rubro_cap
         and    am_pagado = 0
         and    di_operacion = @i_operacionca 
         and    di_dividendo = am_dividendo
         and    di_estado  <> 3
         if @@error <> 0
            return 724014
         
         
         update ca_dividendo
         set    di_estado    = @w_est_cancelado,
                di_fecha_can = @w_fecha_proceso
         where  di_operacion = @i_operacionca
         and    di_dividendo >= @i_dividendo
         
         if @@error <> 0
           return 724015
         
         update ca_amortizacion
         set    am_estado    = @w_est_cancelado
         where  am_operacion = @i_operacionca
         and    am_dividendo >= @i_dividendo
         
         if @@error <> 0
            return 724013
   
       return 0
     end --cancelar operacion
end ---FIN
---PRINT ' TERMINO  REDUCCION DE PLAZO VA A RECALCULAR OTROS CONCEPTOS  y  EL INT'

select @w_estado_op = op_estado 
from ca_operacion
where  op_operacion = @i_operacionca
         
if @w_estado_op <> @w_est_cancelado
begin
   exec @w_error =  sp_ca_pagflex_recal_otros
      @s_user              = @s_user,
      @s_term              = @s_term,
      @s_date              = @s_date,
      @s_ofi               = @s_ofi,
      @i_operacionca       = @i_operacionca,
      @i_num_dec           = @i_num_dec 
   if @w_error  <> 0 
      return  @w_error   

   if exists (select 1 from ca_amortizacion
             where am_operacion = @i_operacionca
             and am_concepto = @w_parametro_fng
             and am_cuota > 0)
    begin
        exec @w_error =  sp_ca_pagflex_fng
       @s_user              = @s_user,
       @s_term              = @s_term,
       @s_date              = @s_date,
       @s_ofi               = @s_ofi,
       @i_operacionca       = @i_operacionca,
       @i_num_dec           = @i_num_dec 
    if @w_error  <> 0 
        return  @w_error   
    end

   exec @w_error = sp_ca_pagflex_reajuste_int
       @s_user              = @s_user,
       @s_term              = @s_term,
       @s_date              = @s_date,
       @s_ofi               = @s_ofi,
       @i_operacionca       = @i_operacionca,
       @i_fecha_proceso     = @w_fecha_proceso,
       @i_banco             = @w_banco
   if @w_error  <> 0 
        return  @w_error

   if exists (select 1 from ca_amortizacion
              where am_operacion = @i_operacionca
              and am_concepto = @w_mipymes
              and am_cuota > 0)
   begin           
      exec @w_error =  sp_recalc_mipyme_flexible
         @i_operacionca            = @i_operacionca,
         @i_num_dec                = @i_num_dec
      if @w_error  <> 0 
           return  @w_error   
   end

   ---SI ESTA TABLA ESTA CARGADA ES POR QUE LA CUOTA VIGENTE TIENE VALORES
   ---QUE SE RECALCULARON y DESPUES DE ESOS RECALCULOS HAY QUE GENERAR TRANSACCION
   ---SI HAY DIFERENCIA ENTRE EL VALOR ANTERIOR Y EL DE HOY
   
   
    if exists ( select 1 from  #acumulado_vigente
                where operacion = @i_operacionca )
    begin
      select am_operacion,  concepto,   cuota,
             dividendo,    'dif'=am_cuota - cuota
       into #diferencias      
      from ca_amortizacion,#acumulado_vigente
      where am_operacion = operacion
      and am_concepto = concepto
      and am_dividendo = dividendo
      and am_estado <> 3
      and (am_cuota - cuota) <> 0
      
      insert into ca_transaccion_prv 
         (
         tp_fecha_mov,        
         tp_operacion,        
         tp_fecha_ref,
         tp_secuencial_ref,   
         tp_estado,           
         tp_comprobante,
         tp_fecha_cont,      
         tp_dividendo,        
         tp_concepto,
         tp_codvalor,         
         tp_monto,
         tp_secuencia,
         tp_ofi_oper,
         tp_monto_mn,
         tp_moneda,
         tp_cotizacion,
         tp_tcotizacion)
      select @s_date,                                    ---tp_fecha_mov
             @i_operacionca,                             ---tp_operacion
             @w_fecha_proceso,                           ---tp_fecha_ref,
             case  when dif > 0 then @i_secuencial_pag 
                   else -999   end,                      ---tp_secuencal_ref
             'ING',   
             0,
             null,                                       ---tp_fecha_cont
             dividendo,                                  ---tp_dividendo
             concepto,                                   ---tp_concepto
             (co_codigo * 1000 + @w_estado_op * 10 + 0),  ---tp_codvalor
             dif,                                       ---tp_monto
             1,                                          ---tp_secuencia
             @w_oficina,
             round(dif*@i_cotizacion,@i_num_dec_n),
             @w_moneda,
             @i_cotizacion,
             @i_tcotizacion
      from #diferencias,ca_concepto
      where am_operacion = @i_operacionca
      and  co_concepto = concepto
      if @@error <> 0
         return 708165      
                    
    end            
 
end   

 
return 0
go