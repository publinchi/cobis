use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_recalculo_mipymesIII')
   drop proc sp_recalculo_mipymesIII
go

create proc sp_recalculo_mipymesIII
@i_operacion            int,
@i_factor               float

as

declare
@w_sp_name              varchar(30),
@w_op_monto             money,
@w_di_dividendo         int,
@w_asociado             catalogo,
@w_porcentaje           float,
@w_valor_asociado       money,
@w_mipymes              varchar(10),
@w_error                int,
@w_porcentaje_asociado  float,
@w_dividendo_anualidad  int,
@w_op_estado            int,
@w_clase_cartera        catalogo,
@w_periodo_int          int,
@w_div_anualidad        smallint,
@w_acum_MIPYME          money,
@w_acum_IVAME           money,
@w_valor                money,
@w_di_estado            smallint,
@w_cuota                money,
@w_monto_cap            money,
@w_cuota_mipyme         money,
@w_valor_ac             money,
@w_monto_aprobado       money


--- INICIALIZACION VARIABLES
select 
@w_sp_name        = 'sp_recalculo_mipymesIII',
@w_valor          = 0,
@w_porcentaje     = 0,
@w_valor_asociado = 0,
@w_asociado       = 'IVAMIPYMES',
@w_mipymes        = 'MIPYMES' 
           

--- DETERMINAR PERIODICIDAD DE PAGO DE INTERESES
select @w_periodo_int    = op_periodo_int * (td_factor / 30),
       @w_monto_aprobado = op_monto_aprobado
from ca_operacion, ca_tdividendo
where op_operacion  = @i_operacion
and   op_tdividendo = td_tdividendo
if @@rowcount = 0 
   select @w_periodo_int = 1
  

select am_cuota, di_dividendo, di_estado 
into #dividendos
from   ca_dividendo with (nolock),
       ca_amortizacion with (nolock)
where  di_operacion  = @i_operacion
and    di_operacion = am_operacion
and    di_dividendo = am_dividendo
and    am_pagado = 0
and    am_concepto = @w_mipymes
and    di_estado   = 0
order by di_dividendo

select
@w_cuota_mipyme = 0,
@w_di_dividendo = 0, 
@w_di_estado    = 0

while 1 = 1
begin
   select top 1
   @w_cuota_mipyme = am_cuota, 
   @w_di_dividendo = di_dividendo, 
   @w_di_estado    = di_estado 
   from #dividendos
   order by di_dividendo
   if @@rowcount = 0
      break
   
   delete #dividendos
   where di_dividendo = @w_di_dividendo

   ---CALCULAR MONTO DE CAPITAL
   select @w_monto_cap     = @w_monto_aprobado
     
   ---CALCULAR VALOR MIPYME CON LA NUEVA TASA
   select @w_valor         = round((@w_monto_cap * @w_periodo_int * @i_factor / 1200.0), 0) 

   --PRINT 'CUOTA_MPYME' + cast ( @w_cuota_mipyme as varchar)
   --PRINT 'PERIODO_INT' + cast ( @w_periodo_int as varchar)
   --PRINT 'FACTOR_INT' + cast ( @i_factor_ant as varchar)
   --PRINT 'VALOR' + cast ( @w_valor as varchar)
   

   if @w_di_estado = 0
      select @w_valor_ac = 0       
   else 
      select @w_valor_ac = @w_valor 
       
   if @w_clase_cartera = 1 select @w_valor = 0, @w_valor_ac = 0 


   --- ACTUALIZAR RUBRO MIPYMES 
   update ca_amortizacion  set 
   am_cuota     = @w_valor,
   am_acumulado = @w_valor_ac 
   where  am_operacion = @i_operacion
   and    am_dividendo = @w_di_dividendo
   and    am_concepto  = @w_mipymes
   if (@@error <> 0) 
      PRINT 'Error actualizando  valor MIPYMES ' + cast ( @i_operacion as varchar)
      
   update ca_recalculo_mipymes_datos_III set 
   CAPITAL_BASE  = @w_monto_cap,
   CUOTA_NEW     = @w_valor,
   ACUMULADO_NEW = @w_valor_ac, 
   TASA_NUEVA    = @i_factor
   where  OPERACION    = @i_operacion
   and    DIVIDENDO    = @w_di_dividendo
   and    CONCEPTO     = @w_mipymes
   if (@@error <> 0) 
      PRINT 'Error actualizando  TABLA DE DATOS' + cast ( @i_operacion as varchar)
   
   
	     
   ---CONSULTA RUBRO ASOCIADO A MIPYMES 
   select 
   @w_asociado                  = ro_concepto,
   @w_porcentaje_asociado       = ro_porcentaje
   from   ca_rubro_op
   where  ro_operacion         = @i_operacion
   and    ro_concepto_asociado = @w_mipymes
   
   if @@rowcount = 0 or @w_porcentaje_asociado is null 
      select @w_porcentaje_asociado = 0, @w_asociado = ''       
 
   ---CALCULO RUBRO ASOCIADO
   select @w_valor_asociado = round((@w_valor * @w_porcentaje_asociado / 100.0), 0)	  
	 
   if exists (select 1 from  ca_amortizacion with (nolock)
              where am_operacion = @i_operacion
              and   am_dividendo = @w_di_dividendo
			  and   am_concepto  = @w_asociado)
   begin
      if @w_di_estado = 0
         select @w_valor_ac = 0       
      else 
         select @w_valor_ac = @w_valor_asociado
         
   
      update ca_amortizacion  set 
      am_cuota      = @w_valor_asociado,
      am_acumulado  = @w_valor_ac
      where  am_operacion = @i_operacion
      and    am_dividendo = @w_di_dividendo
      and    am_concepto  = @w_asociado
      if (@@error <> 0) 
         PRINT 'Error actualizando  valor IVAMIPYMES VIGENTE' + cast ( @i_operacion as varchar)

      update ca_recalculo_mipymes_datos_III set 
      CAPITAL_BASE  = @w_valor,
      CUOTA_NEW     = @w_valor_asociado,
      ACUMULADO_NEW = @w_valor_asociado,
      TASA_NUEVA    = @w_porcentaje_asociado
      where  OPERACION    = @i_operacion
      and    DIVIDENDO    = @w_di_dividendo
      and    CONCEPTO     = @w_asociado
      if (@@error <> 0) 
         PRINT 'Error actualizando  TABLA DE DATOS' + cast ( @i_operacion as varchar)

   end   
end ---WHILE CURSOR


return 0
go

