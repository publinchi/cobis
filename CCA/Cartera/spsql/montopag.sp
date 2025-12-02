/************************************************************************/
/*   Archivo:            montopag.sp                                    */
/*   Stored procedure:   sp_monto_pago                                  */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       MPO                                            */
/*   Fecha de escritura: Diciembre / 1997                               */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                           PROPOSITO                                  */
/*   Procedimiento que permite consultar el monto de pago de una        */
/*   cuota, ya sea en valor presente, anticipado o proyectado           */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      FECHA               AUTOR                 RAZON                 */
/*      05/12/2016          R. Sánchez            Modif. Apropiación    */
/* 18/01/2021         P.Narvaez    Rubros anticipados, CoreBase         */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_monto_pago')
   drop proc sp_monto_pago
go

create proc sp_monto_pago
@i_operacionca       int,
@i_dividendo         int,
@i_tipo_cobro        char(1),
@i_fecha_pago        datetime,
@i_prioridad         int,
@i_secuencial_ing    int,
@i_dividendo_vig     int,
@i_cancelar          char(1) = 'N',
@i_en_gracia_int     char(1) = 'N',
@o_monto             money = null out   
as
declare
@w_monto_pago        money,
@w_monto_pago1       money,
@w_monto_pago_ant    money,
@w_monto_pago_ant1   money,
@w_monto_pago_ant2   money,
@w_sp_name           descripcion,
@w_est_novigente     tinyint,
@w_est_cancelado     tinyint,
@w_comando          varchar(500),
@w_destino          varchar(500),
@w_error            int,
@w_saldo_cap_borrar money
-- INICIALIZACION DE VARIABLES
select @w_sp_name       = 'sp_monto_pago',
       @w_monto_pago    = 0,
       @w_est_novigente = 0,
       @w_est_cancelado = 3


-- CONSULTA DE LOS MONTOS DE PAGO
if @i_tipo_cobro = 'A' -- ACUMULADOS 
begin
   select @w_monto_pago =  isnull(sum(am_acumulado + am_gracia - am_pagado), 0)                          -- REQ 175: PEQUEÑA EMPRESA                       
   from  ca_amortizacion, ca_abono_prioridad, ca_rubro_op, ca_concepto, ca_dividendo
   where am_operacion     = @i_operacionca
   and ap_secuencial_ing  = @i_secuencial_ing
   and ap_operacion       = @i_operacionca
   and di_operacion       = @i_operacionca
   and di_dividendo       = @i_dividendo 
   and ap_prioridad       = @i_prioridad
    and di_operacion       = am_operacion
   and di_dividendo       = am_dividendo
   and am_concepto        = ap_concepto
   and ro_operacion       = @i_operacionca
   and ro_concepto        = am_concepto
   and ro_concepto      = co_concepto
   and am_dividendo       = @i_dividendo
   and ((co_categoria in ('S','A') and di_estado in (2,1))
        or (co_categoria not in ('S','A') and di_estado <> @w_est_cancelado)
         )
    
   
   select @w_monto_pago = isnull(@w_monto_pago,0)
 
   select @w_monto_pago_ant1 = isnull(@w_monto_pago_ant1,0)

   select @w_monto_pago_ant = isnull(@w_monto_pago_ant,0)

   select @w_monto_pago_ant2 = isnull(@w_monto_pago_ant2,0)
end

if @i_tipo_cobro = 'P' -- PROYECTADO
begin
   select @w_monto_pago =   sum(am_cuota + am_gracia - am_pagado)
   from ca_amortizacion,ca_abono_prioridad, ca_rubro_op, ca_concepto
   where am_operacion    = @i_operacionca
   and ap_secuencial_ing = @i_secuencial_ing
   and ap_operacion      = @i_operacionca
   and ap_concepto       = am_concepto  
   and am_estado        <> @w_est_cancelado
   and ap_prioridad      = @i_prioridad
   and ro_operacion      = @i_operacionca
   and ro_concepto       = am_concepto
   and   ro_concepto  = co_concepto
   and   (      --between en caso de que no se haya pagado el rubro anticipado, se lo debe incluir
          (     am_dividendo between @i_dividendo and @i_dividendo + charindex (ro_fpago, 'A')
           and not(co_categoria in ('S','A') and am_secuencia > 1)
          )
          or (co_categoria in ('S','A') and am_secuencia > 1 and am_dividendo = @i_dividendo)
         )
  
   select @w_monto_pago =   isnull(@w_monto_pago,0)

end


select @w_monto_pago      = isnull(@w_monto_pago,0.00),
       @w_monto_pago1      = isnull(@w_monto_pago1, 0.00),
       @w_monto_pago_ant  = isnull(@w_monto_pago_ant,0.00),
       @w_monto_pago_ant1 = isnull(@w_monto_pago_ant1,0.00),
       @w_monto_pago_ant2 = isnull(@w_monto_pago_ant2,0.00)

select @w_monto_pago = @w_monto_pago + @w_monto_pago1 + @w_monto_pago_ant + @w_monto_pago_ant1 + @w_monto_pago_ant2

if @w_monto_pago < 0 select @w_monto_pago = 0.00



select @o_monto = @w_monto_pago

return 0
go       

