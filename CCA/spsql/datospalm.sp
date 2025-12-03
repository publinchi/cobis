/************************************************************************/
/*   Archivo          :      datospalm.sp                               */
/*   Stored procedure :      sp_datos_palm                              */
/*   Base de Datos    :      cob_cartera                                */
/*   Producto         :      Cartera                                    */
/*   Disenado por     :      Xavier Maldonado                           */
/************************************************************************/
/*         IMPORTANTE                                                   */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA",representantes exclusivos para el Ecuador de la           */
/*   AT&T                                                               */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*         PROPOSITO                                                    */
/************************************************************************/
/*         MODIFICACIONES                                               */
/*   FECHA      AUTOR         RAZON                                     */
/************************************************************************/
use cob_cartera
go 


if exists(select 1 from cob_cartera..sysobjects where name = 'sp_datos_palm')
   drop proc sp_datos_palm
go


create proc sp_datos_palm (
        @i_operacionca        int,
        @i_operacion          char(1),           -- "D"esembolso, "P"agos
        @i_monto_cap          money    = null,   --(cap)
        @i_reversa            char(1)  = null,   --S/N
        @i_op_estado_orig     int      = null
)
as

declare 
    @w_sp_name                varchar(20),
    @w_saldo_op               money,
    @w_saldo_cap              money,
    @w_nro_cuotas             int,
    @w_nro_cuotas_ven         int,
    @w_nro_cuotas_pag         int,
    @w_nro_cuotas_pen         int,
    @w_return                 int,
    @w_dias_mora              int,
    @w_fecha_min              datetime,
    @w_fecha_ult_proceso      datetime,
    @w_fecha_proceso          datetime,
    @w_banco                  cuenta,
    @w_cancela                char(1),
    @w_modo                   char(1),
    @w_oficial                int,
    @w_cliente                int,
    @w_tramite                int,
    @w_estado                 int,
    @w_total_cr               money
    
    
return 0


--FECHA DE PROCESO
select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso
  

--DATOS DE LA OBLIGACION  
select
@w_banco             = op_banco,
@w_cliente           = op_cliente,
@w_tramite           = op_tramite,
@w_oficial           = op_oficial,
@w_estado            = op_estado,
@w_fecha_ult_proceso = op_fecha_ult_proceso,
@w_cancela           = case when op_estado = 3 then 'S' else 'N' end
from ca_operacion 
where op_operacion  = @i_operacionca


if @i_op_estado_orig = 3
   select @w_cancela = 'S'

   
--DESEMBOLSOS
--INI AGI. 22ABR19.  Se comenta porque no se encuentra cob_palm..sp_interfaz_palm_pda2
/* 
if @i_operacion = 'D'  begin
      
   exec @w_return = cob_palm..sp_interfaz_palm_pda2
   @i_operacion      = 'D',
   @i_reversa        = @i_reversa,
   @i_tramite        = @w_tramite,
   @i_fecha_proceso  = @w_fecha_proceso,
   @i_banco          = @w_banco,
   @i_oficial        = @w_oficial,
   @i_monto          = @i_monto_cap
   
   if @w_return != 0  return @w_return 
   
end
*/ --FIN AGI

--PAGOS/REVERSA
if @i_operacion = 'P' begin

   select @w_fecha_min = min(di_fecha_ini)
   from  ca_dividendo
   where di_operacion  = @i_operacionca
   and   di_estado = 2
   
   if @w_fecha_min is null or @w_fecha_min = ''
      select @w_dias_mora = 0
   else   
      select @w_dias_mora = datediff(dd,@w_fecha_min,@w_fecha_ult_proceso)  

   select @w_saldo_cap = 0
   select @w_saldo_cap = sum(am_cuota -  am_pagado)
   from  ca_amortizacion
   where am_operacion  = @i_operacionca
   and   am_concepto   = 'CAP'

   select @w_saldo_op = 0
   
   select @w_saldo_op = sum(am_acumulado -  am_pagado)
   from  ca_amortizacion, ca_dividendo
   where am_operacion  = @i_operacionca
   and   am_concepto  != 'CAP'
   and   am_operacion  = di_operacion
   and   am_dividendo  = di_dividendo
   and   di_estado    in (1,2)
  
   select @w_saldo_op = @w_saldo_op + @w_saldo_cap
   
   select @w_nro_cuotas = count(1)
   from   ca_dividendo
   where  di_operacion  = @i_operacionca
   
   select @w_nro_cuotas_ven = count(1)
   from   ca_dividendo
   where  di_operacion  = @i_operacionca
   and    di_estado     = 2

   select @w_nro_cuotas_pag = count(1)
   from   ca_dividendo
   where  di_operacion  = @i_operacionca
   and    di_estado     = 3

   select @w_nro_cuotas_pen = @w_nro_cuotas - @w_nro_cuotas_pag
 
--INI AGI. 22ABR19.  Se comenta porque no se encuentra cob_palm..sp_interfaz_palm_pda2
/*             
   exec @w_return = cob_palm..sp_interfaz_palm_pda2
   @i_operacion        = 'P',
   @i_reversa          = @i_reversa,
   @i_fecha_proceso    = @w_fecha_proceso,
   @i_banco            = @w_banco,
   @i_oficial          = @w_oficial,
   @i_monto            = @i_monto_cap,
   @i_tramite          = @w_tramite,
   @i_cancela_op       = @w_cancela,        --S o N si con el pago cancela total el credito
   @i_dias_vto         = @w_dias_mora,      --Nro dias de mora despues de afectado con el pago
   @i_saldo_cap        = @w_saldo_cap,      --nuevo saldo de capital
   @i_saldo_deuda      = @w_saldo_op,       --nuevo saldo de la deuda
   @i_cuotas_total     = @w_nro_cuotas,     --Nro. de Cuotas del Credito
   @i_cuotas_vencidas  = @w_nro_cuotas_ven, --Nro de Cuotas vencidas
   @i_cuotas_por_pagar = @w_nro_cuotas_pen, --Nro de Cuotas que faltan por pagar del credito
   @i_cuotas_pagadas   = @w_nro_cuotas_pag, --Nro de cuotas que han pagado
   @i_total_creditos   = @w_total_cr        --Nro Total de Creditos del Cliente (no importa el estado)
   
   if @w_return != 0  return @w_return 
*/   --FIN AGI
end


return 0  
go
