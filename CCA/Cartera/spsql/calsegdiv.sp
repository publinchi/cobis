/************************************************************************/
/*   Archivo:              calseg.sp                                    */
/*   Stored procedure:     sp_cal_segdiv                                */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Xavier Maldonado                             */
/*   Fecha de escritura:   Nov. 2.001                                   */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                                   PROPOSITO                          */
/*   Consulta saldo de una operaci¢n a la fecha.                        */
/*   Q: Consulta de negociacion de abonos automaticos                   */
/*   F: Finaciaci¢n de Obligaciones                                     */
/************************************************************************/
/*                                 MODIFICACIONES                       */
/*   FECHA      AUTOR            RAZON                                  */
/*                                                                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cal_segdiv')
   drop proc sp_cal_segdiv
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


create proc sp_cal_segdiv
   @i_operacion          int,
   @i_op_moneda          smallint,
   @i_fecha_ult_proceso  datetime,
   @i_dividendo          int,
   @i_estado_div         tinyint,
   @i_fecha_ven          datetime,
   @i_concepto           catalogo = null,
   @w_saldo_seg          money = null output,
   @w_saldo_seg_mn       money = null output,
   @w_saldo_seg_cot_hoy  money = null output
as
declare
   @w_sp_name           descripcion,
   @w_return            int,
   @w_fecha_hoy         datetime,
   @w_fecha_ven         datetime,
   @w_est_vigente       tinyint,
   @w_capital           money,
   @w_moneda            smallint,
   @w_dividendo         int,
   @w_cotizacion_hoy    float,
   @w_seguro_vencido    money,
   @w_seguro_vencido_mn money,
   @w_estado            tinyint,
   @w_numdec_op         tinyint,
   @w_interes           money,
   @w_est_novigente     tinyint,
   @w_div_vigente       int,
   @w_seguro_total      money

-- LECTURA DATOS DE LA OPERACION
select @w_div_vigente       = 0,
       @w_seguro_vencido    = 0,
       @w_seguro_vencido_mn = 0,
       @w_seguro_total      = 0


-- MANEJO DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda    = @w_moneda,
     @o_decimales = @w_numdec_op out


   if @i_estado_div = 2 --Vencido
      exec sp_buscar_cotizacion
      @i_moneda     = @i_op_moneda,
      @i_fecha      = @i_fecha_ven,
      @o_cotizacion = @w_cotizacion_hoy output

   if @i_estado_div = 1 or @i_estado_div = 0   --Vigente o no Vigente
      exec sp_buscar_cotizacion
      @i_moneda     = @i_op_moneda,
      @i_fecha      = @i_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion_hoy output


   ---print 'cotizacion....%1!',@w_cotizacion_hoy
  if @i_concepto is null
    select @w_saldo_seg = isnull(sum(am_cuota + am_gracia - am_pagado),0)
    from ca_amortizacion, ca_concepto
    where am_operacion = @i_operacion
    and   am_dividendo = @i_dividendo + 1
    and   am_concepto  = co_concepto
    and   co_categoria = 'S'
  else
    select @w_saldo_seg = isnull(sum(am_cuota + am_gracia - am_pagado),0)
    from ca_amortizacion
    where am_operacion = @i_operacion
    and   am_dividendo = @i_dividendo + 1
    and   am_concepto  = @i_concepto

   select @w_saldo_seg_mn = round(@w_saldo_seg * @w_cotizacion_hoy,4)

   /*VALOR DEL SEGURO EN UVR A LA COTIZACION HOY */
  
   if @i_estado_div = 2 --Vencido
   begin
      exec sp_buscar_cotizacion
      @i_moneda     = @i_op_moneda,
      @i_fecha      = @i_fecha_ult_proceso,
      @o_cotizacion = @w_cotizacion_hoy output

      ---PRINT 'calsegvid.sp @w_saldo_seg %1!  @w_cotizacion_hoy %2!',@w_saldo_seg,@w_cotizacion_hoy

      select @w_saldo_seg_cot_hoy = round(@w_saldo_seg_mn / @w_cotizacion_hoy,4)
   end 

return 0
go      

