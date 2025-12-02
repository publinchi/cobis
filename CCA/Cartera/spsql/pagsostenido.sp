/************************************************************************/
/*   Archivo:                 pasostenido.sp                            */
/*   Stored procedure:        sp_verifica_pago_sostenido_op             */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Fabián Altamirano                         */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Retorna S/N si operacion tiene pago sostenido                      */
/*   Para determinar si un cliente ha realizado un “pago sostenido”     */
/*   sobre un préstamo este deberá Verificar si se ha pagado al menos   */
/*   3 cuotas del crédito desde la fecha de su paso a vencido, siempre  */
/*   y cuando los días de mora de la obligación luego de realizados     */
/*   estos pagos sea menor a 90 días.                                   */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA         AUTOR        RAZON                                */
/*   7/Dic/2016      J. Tagle     Emisión Inicial                       */ 
/*  DIC/23/2020   P. Narvaez A�adir cambio de estado Judicial y Suspenso*/
/************************************************************************/

use cob_cartera
go

if exists(select * from sysobjects where name = 'sp_verifica_pago_sostenido_op')
   drop proc sp_verifica_pago_sostenido_op
go

create proc sp_verifica_pago_sostenido_op
   @i_operacion      int          = null,   
   @o_psostenido     char(5)   = null out   

as
declare
@w_sp_name                varchar(32),
@w_error                  int,   
@w_operacion              int,       -- operacion
@w_num_cuotas             int,       -- cuotas de la operacion

@w_op_estado              tinyint,   -- estado de operacion
@w_op_fecha_paso_vencido  datetime,
@w_op_fecha_ult_proceso   datetime,

@w_est_vencido            tinyint,   -- codigo estado vencido
@w_est_cancelado          tinyint,   -- codigo estado Cancelado
                       
@w_div_pagado             tinyint,   -- ultimo div pagado antes de vencer operacion
@w_cont_pag_ven           tinyint,   -- contador de pagos luego de vencer operacion
                       
@w_dias_vencido           int,       -- diferencia entre @w_fecha_pri_vencido y @i_Fecha_proceso
@w_op_anterior            int,
@w_par_dias_pag_sos       int,
@w_par_pag_ven            smallint,
@w_est_suspenso           tinyint

-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_verifica_pago_sostenido_op'

-- PAGO SOSTENIDO
select @o_psostenido = 'N'
		
-- Verifica OPERACION (Estado y Fecha de Operacion)
select @w_operacion = @i_operacion

select 
@w_op_estado              = op_estado,
@w_op_fecha_paso_vencido  = op_fecha_suspenso,
@w_op_fecha_ult_proceso   = op_fecha_ult_proceso,
@w_op_anterior            = op_anterior
from ca_operacion
where op_operacion = @w_operacion

if @@rowcount = 0 return 141066

-- Obtener Codigo Estado VENCIDO
exec @w_error = sp_estados_cca
@o_est_vencido    = @w_est_vencido   out,  
@o_est_cancelado  = @w_est_cancelado out,
@o_est_suspenso   = @w_est_suspenso out

if @w_error <> 0 return @w_error
	 
-- Obtener numero de cuotas
select @w_num_cuotas = count(1) from ca_dividendo where di_operacion = @w_operacion

-- Si tiene al menos 3 cuotas y op esta Vencida aplica para Pago Sostenido 
if @w_num_cuotas <= 3 or @w_op_estado not in (@w_est_vencido, @w_est_suspenso)
  return 0


-- se toma MAX(diferencia de fechas) entre la fecha de vencimiento y fecha proceso de la op
select  @w_dias_vencido = isnull(max(DATEDIFF(day,di_fecha_ven,@w_op_fecha_ult_proceso)),0)
from ca_dividendo
where di_operacion = @w_operacion
and   di_estado    = @w_est_vencido --<> @w_est_cancelado

-- PARÁMETRO DIAS DE PAGO SOSTENIDO
select @w_par_dias_pag_sos = pa_int
from cobis..cl_parametro
where pa_nemonico = 'DPAGSO'

if @w_par_dias_pag_sos is null select @w_par_dias_pag_sos = 90

--PARAMETRO NUMERO DE CUOTAS VENCIDAS PARA PAGO SOSTENIDO
select @w_par_pag_ven = pa_smallint
from cobis..cl_parametro
where pa_nemonico = 'CPAGSO'

if @w_par_pag_ven is null select @w_par_pag_ven = 3

if @w_op_anterior is not null --RENOVADA
begin
    -- Obtener numero de cuotas pagadas luego de la fecha de paso a vencido
    select @w_cont_pag_ven = count(1)
    from ca_dividendo 
    where di_operacion = @w_operacion 
    and   di_estado    = @w_est_cancelado
    and   di_fecha_can > @w_op_fecha_paso_vencido
    
    -- Si tiene 3 cuotas pagadas luego de paso a vencido se cuentan dias
    if @w_cont_pag_ven >= @w_par_pag_ven  and @w_dias_vencido < @w_par_dias_pag_sos   select @o_psostenido = 'S'

end
else  if @w_dias_vencido <= 0 select @o_psostenido = 'S'

return 0


go
