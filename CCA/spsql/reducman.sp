/************************************************************************/
/*      Archivo:                erducman.sp                             */
/*      Stored procedure:       sp_reduccion_manual                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian Quintero por Solicitud de        */
/*                              Anthony Zapata                          */
/*      Fecha de escritura:     Ene. 2003                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Realiza la reduccion de (T)iempo o (C)uota en una tabla de      */
/*      Amortizacion MANUAL                                             */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reduccion_manual')
   drop proc sp_reduccion_manual
go

create proc sp_reduccion_manual
  @s_user            login        = NULL,
  @s_term            varchar (30) = NULL,
  @s_date            datetime     = NULL,
  @s_ofi             int          = NULL,
  @i_secuencial      int,
  @i_operacionca     int,
  @i_fecha_proceso   datetime,
  @i_monto_extra     float,
  @i_tipo_reduccion  char,
  @i_decimales       int,
  @i_periodo_int     int,
  @i_dias_anio       int

as
declare 
  @w_error         int,
  @w_primer_novig  int,
  @w_ultimo_novig  int,
  @w_concepto_cap  catalogo,
  @w_saldo         float,
  @w_proporcion    float,
  @w_dividendo     int,
  @w_acumulado     float,
  @w_pagado        float,
  @w_reduccion     float,
  @w_fpago         char,
  @w_tdividendo    catalogo,
  @w_base_calculo  char,
  @w_banco         cuenta

if isnull(@i_monto_extra, 0) = 0
   return 0

select @w_primer_novig = isnull(min(di_dividendo), 0)
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_estado = 1


select @w_ultimo_novig = isnull(max(di_dividendo), 0)
from   ca_dividendo
where  di_operacion = @i_operacionca
and    di_estado = 0

if @w_primer_novig = 0
   return 0

select @w_fpago = min(ro_fpago)
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_tipo_rubro = 'I'

select @w_concepto_cap = min(ro_concepto)
from   ca_rubro_op
where  ro_operacion = @i_operacionca
and    ro_tipo_rubro = 'C'

select @w_saldo = sum(am_acumulado - am_pagado)
from   ca_amortizacion
where  am_operacion = @i_operacionca
and    am_dividendo >= @w_primer_novig
and    am_concepto  = @w_concepto_cap

if @i_tipo_reduccion = 'C' -- REDUCCION DE CUOTA
  begin
    select @w_proporcion = @i_monto_extra / @w_saldo
    
    -- CURSOR POR LA CUOTAS DE CAPITAL PARA REDUCIRLAS
    declare cur_amort cursor
    for select am_dividendo, am_acumulado, am_pagado
        from   ca_amortizacion
        where  am_operacion = @i_operacionca
        and    am_dividendo >= @w_primer_novig
        and    am_concepto = @w_concepto_cap
        order by am_dividendo
        for read only

    open cur_amort
    
    fetch cur_amort
    into  @w_dividendo, @w_acumulado, @w_pagado
    
    -- ACTUALIZAR LAS CUOTAS EXCEPTO LA ULTIMA
    while (@@fetch_status = 0 and @w_dividendo < @w_ultimo_novig)
    begin
       select @w_reduccion = round((@w_acumulado - @w_pagado) * @w_proporcion, @i_decimales)
       -- ACTUALIZAR LA CUOTA
       update ca_amortizacion
       set    am_acumulado = am_acumulado - @w_reduccion,
              am_cuota     = am_cuota - @w_reduccion
       where  am_operacion = @i_operacionca
       and    am_dividendo = @w_dividendo
       and    am_concepto  = @w_concepto_cap
       --
       select @i_monto_extra = @i_monto_extra - @w_reduccion
       --
       fetch cur_amort
       into  @w_dividendo, @w_acumulado, @w_pagado
    end
    
    deallocate cur_amort
    
    -- ACTUALIZAR LA ULTIMA CUOTA
    update ca_amortizacion
    set    am_acumulado = am_acumulado - @i_monto_extra,
           am_cuota     = am_cuota - @i_monto_extra
    where  am_operacion = @i_operacionca
    and    am_dividendo = @w_ultimo_novig
    and    am_concepto  = @w_concepto_cap
    
  end
else -- REDUCCION DE TIEMPO
  begin
    select @w_saldo = @w_saldo - @i_monto_extra
    -- CURSOR POR LA CUOTAS DE CAPITAL DETERMINAR ALCANCE
    declare cur_amort cursor
    for select am_dividendo, am_acumulado, am_pagado
        from   ca_amortizacion
        where  am_operacion = @i_operacionca
        and    am_dividendo >= @w_primer_novig
        and    am_concepto = @w_concepto_cap
        order by am_dividendo
        for read only

    open cur_amort
    
    fetch cur_amort
    into  @w_dividendo, @w_acumulado, @w_pagado
    
    select @w_reduccion = 0
    
    -- RECORRER LAS CUOTAS
    while (@@fetch_status = 0)
    begin
       select @w_reduccion = @w_reduccion + (@w_acumulado - @w_pagado)
       -- VERIFICACION DE PARADA
       if @w_reduccion >= @w_saldo
          break
       --
       fetch cur_amort
       into  @w_dividendo, @w_acumulado, @w_pagado
    end
    
    deallocate cur_amort
    
    -- ACTUALIZACION DE SALDO, @w_dividendo tiene la ultima cuota valida
    if @w_dividendo < @w_ultimo_novig
      begin
         delete ca_dividendo
         where  di_operacion = @i_operacionca
         and    di_dividendo > @w_dividendo
         
         delete ca_amortizacion
         where  am_operacion = @i_operacionca
         and    am_dividendo > @w_dividendo
      end
    
    if (@w_saldo != @w_reduccion)
      begin
        update ca_amortizacion
        set    am_acumulado = am_acumulado - (@w_reduccion - @w_saldo),
               am_cuota     = am_cuota - (@w_reduccion - @w_saldo)
        where  am_operacion = @i_operacionca
        and    am_dividendo = @w_dividendo
        and    am_concepto  = @w_concepto_cap
      end
  end

  select @w_tdividendo   = op_tdividendo,
         @w_base_calculo = op_base_calculo,
         @w_banco        = op_banco
  from   ca_operacion
  where  op_operacion = @i_operacionca

  exec @w_error = sp_reajuste_interes
       @s_user           = @s_user,
       @s_term           = @s_term,
       @s_date           = @s_date,
       @s_ofi            = @s_ofi,
       @i_operacionca    = @i_operacionca,
       @i_fecha_proceso  = @i_fecha_proceso,
--       @i_dias_anio      = @i_dias_anio,
       @i_num_dec        = @i_decimales,
       @i_secuencial     = @i_secuencial,
       @i_fpago          = @w_fpago,
       @i_periodo_int    = @i_periodo_int,
       @i_tdividendo     = @w_tdividendo,
       @i_base_calculo   = @w_base_calculo,
       @i_banco          = @w_banco
  
  if @w_error != 0
     return @w_error
  
  return 0
go

