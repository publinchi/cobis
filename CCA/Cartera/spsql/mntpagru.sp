/******************************************************************/
/*   Archivo:            mntpagru.sp                              */
/*   Stored procedure:   sp_monto_pago_rubro                      */
/*   Base de datos:      cob_cartera                              */
/*   Producto:           Cartera                                  */
/*   Disenado por:       MPO                                      */
/*   Fecha de escritura: Diciembre / 1997                         */
/******************************************************************/
/*                          IMPORTANTE                            */
/*   Este programa es parte de los paquetes bancarios propiedad   */
/*   de "MACOSA"                                                  */
/*   Su uso no autorizado queda expresamente prohibido asi como   */
/*   cualquier alteracion o agregado hecho por alguno de sus      */
/*   usuarios sin el debido consentimiento por escrito de la      */
/*   Presidencia Ejecutiva de MACOSA o su representante.          */
/******************************************************************/  
/*                           PROPOSITO                            */
/*   Procedimiento que permite consultar el monto de pago de una  */
/*   cuota por prioridad, ya sea en valor presente, anticipado o  */
/*   proyectado                                                   */
/******************************************************************/  
/*                        MODIFICACIONES                          */
/*   FECHA           AUTOR       CAMBIO                           */
/*   MAY-31-2002     EPB         Manejo de secuencias hecha para  */
/*                               INTANT, no debe afectar CON      */
/* 13/01/2021         P.Narvaez    Rubros anticipados, CoreBase         */
/******************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_monto_pago_rubro')
   drop proc sp_monto_pago_rubro
go

create proc sp_monto_pago_rubro
@i_operacionca       int      = null,
@i_dividendo         int      = null,
@i_tipo_cobro        char(1)  = null,
@i_fecha_pago        datetime = null,
@i_concepto          catalogo = null,
@i_dividendo_vig     int,  --Para Factoring es el dividendo seleccionado de fornt-end
@i_cancelar          char(1)  = 'N',
@i_en_gracia_int     char(1)  = 'N',
@o_monto             money    = null out
as
declare
@w_sp_name           descripcion,
@w_monto_pago        money,
@w_monto_pago1       money,
@w_monto_pago_ant    money,
@w_monto_pago_ant2   money,
@w_monto_pago_ant3   money,
@w_est_novigente     tinyint,
@w_est_cancelado     tinyint
   
--INICIALIZACION DE VARIABLES 
select @w_sp_name = 'sp_monto_pago_rubro',
       @w_est_novigente = 0,
       @w_est_cancelado  = 3

/*PRINT '(mntpagru.sp) @i_tipo_cobro  %1!,
                     @i_dividendo_vig  %2!,
                     @i_concepto  %3!,
                     @i_dividendo %4!',@i_tipo_cobro ,@i_dividendo_vig,@i_concepto,@i_dividendo*/


-- CONSULTA DE LOS MONTOS DE PAGO 
if @i_tipo_cobro = 'A'
begin -- Acumualdos
   select @w_monto_pago = isnull(sum(am_acumulado+ am_gracia - am_pagado), 0)                          -- REQ 175: PEQUEÑA EMPRESA
                          /*case
                          when @i_en_gracia_int = 'N' then sum(am_acumulado+ am_gracia - am_pagado)
                          else sum(am_acumulado - am_pagado)
                          end*/
   from ca_amortizacion, ca_rubro_op, ca_concepto
   where am_operacion = @i_operacionca
   and   am_concepto  = @i_concepto
   and   ro_operacion = @i_operacionca
   and   ro_concepto  = am_concepto
   and   ro_concepto  = co_concepto
   and    am_estado  != @w_est_cancelado   
   and   (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir
          (     am_dividendo between @i_dividendo and @i_dividendo + charindex (ro_fpago, 'A')
           and not(co_categoria in ('S','A') and am_secuencia > 1)
          )
          or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @i_dividendo)
         )
end

if @i_tipo_cobro = 'P'
begin -- Proyectado
   select @w_monto_pago = sum(am_cuota+ am_gracia - am_pagado)
   from ca_amortizacion, ca_rubro_op, ca_concepto
   where am_operacion = @i_operacionca
   and   am_concepto  = @i_concepto
   and   ro_operacion = @i_operacionca
   and   ro_concepto  = am_concepto
   and   ro_concepto  = co_concepto
   and    am_estado  != @w_est_cancelado      
   and   (--between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir
          (     am_dividendo between @i_dividendo and @i_dividendo + charindex (ro_fpago, 'A')
           and not(co_categoria in ('S','A') and am_secuencia > 1)
          )
          or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @i_dividendo)
         )
end

select 
@w_monto_pago     = isnull(@w_monto_pago,0.00),
@w_monto_pago1     = isnull(@w_monto_pago1, 0.00),
@w_monto_pago_ant = isnull(@w_monto_pago_ant,0.00), 
@w_monto_pago_ant2= isnull(@w_monto_pago_ant2,0.00), 
@w_monto_pago_ant3= isnull(@w_monto_pago_ant3,0.00) 

/*PRINT '(mntpagru.sp) @w_monto_pago_ant %1!,
                     @w_monto_pago_ant2  %2!,
                     @w_monto_pago_ant3  %3!,
                     @i_dividendo_vig %4!,
                     @w_monto_pago %5!',@w_monto_pago_ant,@w_monto_pago_ant2,@w_monto_pago_ant3,@i_dividendo_vig,@w_monto_pago*/
                 

select @w_monto_pago = @w_monto_pago + @w_monto_pago1 + @w_monto_pago_ant+ @w_monto_pago_ant2 + @w_monto_pago_ant3

if @w_monto_pago < 0 select @w_monto_pago = 0.00

select @o_monto = @w_monto_pago

return 0
go       

