/************************************************************************/
/*   Archivo:              calseg.sp                                    */
/*   Stored procedure:     sp_cal_seg                                   */
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

if exists (select 1 from sysobjects where name = 'sp_cal_seg')
   drop proc sp_cal_seg
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_cal_seg
   @i_operacion          int,
   @i_op_moneda          smallint,
   @i_fecha_ult_proceso  datetime,
   @i_dividendo_min_ven  int,
   @i_dividendo_max_ven  int,
   @i_dividendo_vig      int,  
   @w_saldo_seg          money = null output,
   @w_saldo_seg_mn       money = null output
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



if @i_dividendo_min_ven is null
   select @i_dividendo_min_ven  = 0

if @i_dividendo_max_ven is null
   select @i_dividendo_max_ven = 0

if @i_dividendo_vig  is null
   select @i_dividendo_vig = 0


if @i_dividendo_vig  = 0
   select @i_dividendo_vig = @i_dividendo_max_ven


   declare cursor_dividendo cursor for 
   select di_dividendo,di_fecha_ven,di_estado
   from   ca_dividendo
   where  di_operacion = @i_operacion
   and    di_dividendo >= @i_dividendo_min_ven
   and    di_dividendo <= @i_dividendo_vig
   for read only

   open cursor_dividendo
   fetch cursor_dividendo
   into  @w_dividendo, @w_fecha_ven, @w_estado

   while @@fetch_status = 0 
   begin

      if @@fetch_status = -1 
         return  70899 

      if @w_estado = 2 --Vencido
         exec sp_buscar_cotizacion
         @i_moneda     = @i_op_moneda,
         @i_fecha      = @w_fecha_ven,
         @o_cotizacion = @w_cotizacion_hoy output

      if @w_estado = 1 --Vigente
         exec sp_buscar_cotizacion
         @i_moneda     = @i_op_moneda,
         @i_fecha      = @i_fecha_ult_proceso,
         @o_cotizacion = @w_cotizacion_hoy output



         select @w_seguro_vencido  = isnull(sum(am_cuota + am_gracia - am_pagado),0)
         from ca_amortizacion, ca_concepto
         where am_operacion = @i_operacion
         and   am_dividendo = @w_dividendo + 1
         and   am_concepto  = co_concepto
         and   co_categoria = 'S'
      
         select @w_seguro_total = @w_seguro_total + isnull(@w_seguro_vencido, 0)  

         select @w_seguro_vencido_mn = @w_seguro_vencido_mn + @w_seguro_vencido * @w_cotizacion_hoy


         fetch cursor_dividendo
         into  @w_dividendo, @w_fecha_ven, @w_estado
    end

    close cursor_dividendo
    deallocate cursor_dividendo


select @w_saldo_seg    = isnull(@w_seguro_total,0),
       @w_saldo_seg_mn = isnull(@w_seguro_vencido_mn,0)


return 0
go      

