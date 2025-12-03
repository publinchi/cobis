/************************************************************************/
/*      Archivo:                aplmora.sp                              */
/*      Stored procedure:       sp_aplica_mora                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Luis Carlos Moreno                      */
/*      Fecha de escritura:     Septiembtre 2014                        */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Aplica abono a rubros de mora. Aplicacion por Concepto          */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*      FECHA          AUTOR          CAMBIO                            */
/*      2014-09-23     Luis Moreno    REQ 436 - Normalizacion de Cartera*/
/************************************************************************/
use cob_cartera
go
if exists(select 1 from sysobjects where name = 'sp_aplica_mora')
   drop proc sp_aplica_mora
go

create procedure sp_aplica_mora
@s_sesn                  int        = NULL,
@s_user                  login      = NULL,
@s_term                  varchar(30)= NULL,
@s_date                  datetime   = NULL,
@s_ofi                   smallint   = NULL,
@i_fecha_proceso         datetime,
@i_operacionca           int,
@i_monto_pago            money,
@i_cotizacion            money,
@i_cotizacion_dia_sus    float      = NULL,
@i_secuencial_pag        int,
@i_en_linea              char(1)    = NULL,
@i_debug                 char(1)    = 'N',
@o_sobrante_pago         money      = NULL out

as

declare @w_total_mora    money,
        @w_di_dividendo  int,
        @w_am_concepto   varchar(10),
        @w_monto_rubro   money,
        @w_ro_fpago      char(1),
        @w_error         int,
        @w_msg           varchar(132),
        @w_sp_name       varchar(32)

select @w_total_mora = 0,
       @o_sobrante_pago = 0

/* OBTIENE EL VALOR TOTAL DE MORA DE LA OPERACION */
select @w_total_mora = sum(am_acumulado - am_pagado)
from ca_dividendo, ca_amortizacion, ca_rubro_op
where di_operacion = @i_operacionca
and   am_operacion = di_operacion
and   am_dividendo = di_dividendo
and   am_operacion = ro_operacion
and   di_estado = 2
and   am_estado <> 3
and   ro_tipo_rubro = 'M'
and   am_concepto = ro_concepto

if @@ROWCOUNT = 0
begin
   select @w_msg = 'ERROR, OPERACION NO TIENE VALORES EN MORA PENDIENTES DE PAGO',
          @w_error = 708153
          
   goto ERRORFIN
end

--/* VALIDA QUE EL VALOR TOTAL DE MORA SEA IGUAL AL MONTO DE PAGO */
--if @i_monto_pago > @w_total_mora
--begin
--   select @w_msg = 'ERROR, EL MONTO DE PAGO ES MAYOR AL VALOR EN MORA',
--          @w_error = 708153
          
--   goto ERRORFIN
--end


/* APLICA PAGO A RUBROS EN MORA PARA CADA UNA DE LOS DIVIDENDOS EN ESTADO VENCIDO */
declare
   secuencia_mora cursor
   for select di_dividendo, am_concepto, sum(am_acumulado - am_pagado), max(ro_fpago)
       from ca_dividendo, ca_amortizacion, ca_rubro_op
       where di_operacion = @i_operacionca
       and   am_operacion = di_operacion
       and   am_dividendo = di_dividendo
       and   am_operacion = ro_operacion
       and   di_estado = 2
       and   ro_tipo_rubro = 'M'
       and   am_estado <> 3
       and   am_acumulado - am_pagado > 0
       and   am_concepto = ro_concepto
       group by di_dividendo, am_concepto
       order by di_dividendo, am_concepto
   for read only
   
   open secuencia_mora

fetch secuencia_mora
into  @w_di_dividendo,  @w_am_concepto,  @w_monto_rubro,   @w_ro_fpago

while   @@fetch_status = 0
begin
   /* APLICA PAGO A VALORES EN MORA POR DIVIDENDO */
   exec @w_error = sp_abona_rubro
                   @s_ofi                = @s_ofi,
                   @s_sesn               = @s_sesn,
                   @s_user               = @s_user,
                   @s_term               = @s_term,
                   @s_date               = @s_date,
                   @i_secuencial_pag     = @i_secuencial_pag,
                   @i_operacionca        = @i_operacionca,
                   @i_dividendo          = @w_di_dividendo,
                   @i_concepto           = @w_am_concepto,
                   @i_monto_pago         = @i_monto_pago,
                   @i_monto_prioridad    = @w_monto_rubro,
                   @i_monto_rubro        = @w_monto_rubro,
                   @i_tipo_cobro         = 'A',
                   @i_en_linea           = @i_en_linea,
                   @i_tipo_rubro         = 'M',
                   @i_fecha_pago         = @i_fecha_proceso,
                   @i_condonacion        = 'N',
                   @i_cotizacion         = @i_cotizacion,
                   @i_tcotizacion        = 'N',
                   @i_inicial_prioridad  = @w_monto_rubro,
                   @i_inicial_rubro      = @w_monto_rubro,
                   @i_fpago              = @w_ro_fpago,
                   @i_cotizacion_dia_sus = @i_cotizacion_dia_sus,
                   @i_aplicacion_concepto = 'S',
                   @o_sobrante_pago      = @i_monto_pago out
                  
   if @w_error <> 0
   begin
      select @w_msg = 'ERROR, AL APLICAR EL PAGO. CUOTA '+CAST(@w_di_dividendo as varchar)+
                      ' @w_monto_rubro:'+CAST(@w_monto_rubro as varchar)+' @i_monto_pago:'+CAST(@i_monto_pago as varchar),
             @w_error = 708153
          
      goto ERRORFIN
   end

   fetch secuencia_mora
   into  @w_di_dividendo,  @w_am_concepto,  @w_monto_rubro,   @w_ro_fpago
end
      
close secuencia_mora
deallocate secuencia_mora


select @o_sobrante_pago = @i_monto_pago

return 0
 
ERRORFIN:

   if @i_debug = 'S'
      print @w_msg
      
   return @w_error

go