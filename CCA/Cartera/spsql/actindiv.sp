/************************************************************************/
/*  Archivo:                        actindiv.sp                         */
/*  Stored procedure:               sp_actualiza_hijas                  */
/*  Base de datos:                  cob_cartera                         */
/*  Producto:                       Cartera                             */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBISCORP o su representante              */
/************************************************************************/
/*                                  PROPOSITO                           */
/*  Actualiza las operaciones hijas de una operacion grupal             */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   25/Jun/2019   Luis Ponce          Emision Inicial                  */
/*   01/Jun/2022   Guisela Fernendes   Se comenta prints                */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_hijas')
    drop proc sp_actualiza_hijas
go

create proc sp_actualiza_hijas
       @i_banco               cuenta  = null       --cuenta grupal padre
as
declare @w_sp_name              descripcion,
        @w_error                int,
        @w_operacionca          int,
        @w_monto                money,
        @w_porcentaje_tot       float,
        @w_porcentaje           float,
        @w_op_cuota             money,
        @w_op_ultima            int,
        @w_op_fecha_ini         datetime,
        @w_op_fecha_liq         datetime,
        @w_op_fecha_fin         datetime,
        @w_op_fecha_ult_proceso datetime,
        @w_op_oficina           int,
        @w_am_dividendo         int, 
        @w_am_concepto          catalogo,
        @w_am_estado            int,
        @w_am_periodo           int,
        @w_am_cuota             money,
        @w_am_gracia            money,
        @w_am_pagado            money,
        @w_am_acumulado         money,
        @w_am_cuota_tot         money,
        @w_am_gracia_tot        money,
        @w_am_pagado_tot        money,
        @w_am_acumulado_tot     money,
        @w_ro_concepto          catalogo,
        @w_ro_valor             money,
        @w_ro_valor_tot         MONEY,
        @w_op_oficial           INT    --LPO TEC
     
select @w_sp_name = 'sp_actualiza_hijas'

/* VERIFICAR EXISTENCIA DE OPERACION GRUPAL */
select @w_operacionca          = op_operacion,
       @w_monto                = op_monto,
       @w_op_cuota             = op_cuota,
       @w_op_fecha_ini         = op_fecha_ini,
       @w_op_fecha_liq         = op_fecha_liq,
       @w_op_fecha_fin         = op_fecha_fin,
       @w_op_fecha_ult_proceso = op_fecha_ult_proceso,
       @w_op_oficina           = op_oficina,
       @w_op_oficial           = op_oficial --LPO TEC
from   ca_operacion                                                                                                                                                                                                                                    
where  op_banco = @i_banco

if @@rowcount = 0
begin
   --GFP se suprime print
   --print 'Esta operacion no existe ' + @i_banco
   return 0
end

/* CREAR TABLAS TEMPORALES */                                                                                                                                                                                                                                              
/* CREAR TABLA DE OPERACIONES HIJAS */
create table #TMP_operaciones (
       operacion   int,
       monto       money,
       porcentaje  float)

/* DETERMINAR PORCENTAJES DE LAS OPERACIONES HIJAS */
insert into #TMP_operaciones
select op_operacion , op_monto , round(((op_monto * 100.0) / @w_monto),2)
from   ca_operacion                                                                                                                                                                                                                                    
where  op_ref_grupal = @i_banco    
order by op_operacion

/* DETERMINAR QUE EXISTA OPERACIONES HIJAS */
if not exists (select 1 from #TMP_operaciones)
begin
   --GFP se suprime print
   --print 'No existe operaciones hijas, para la operacion grupal ' + @i_banco
   return 0
end

/* DETERMINAR ULTIMA OPERACION HIJA */
set rowcount 1

select @w_op_ultima = operacion
from   #TMP_operaciones
order by operacion desc

set rowcount 0

/* DETERMINAR EL PORCENTAJE TOTAL DE LAS OPERACIONES HIJAS */
select @w_porcentaje_tot = sum(porcentaje)
from   #TMP_operaciones

/* VALIDAR QUE EL PORCENTAJE SEA EL 100% */
if @w_porcentaje_tot <> 100.00
begin
   select @w_porcentaje = 100.00 - @w_porcentaje_tot

   /* ACTUALIZAR EL PORCENTAJE DE LA ULTIMA HIJA */
   update #TMP_operaciones
   set    porcentaje = porcentaje + @w_porcentaje
   where  operacion  = @w_op_ultima
end

/* RUBROS GRUPAL */
select * 
into   #TMP_rubro_op
from   ca_rubro_op
where  ro_operacion = @w_operacionca

/* DIVIDENDOS GRUPAL */
select * 
into   #TMP_dividendo
from   ca_dividendo
where  di_operacion = @w_operacionca

/* AMORTIZACION GRUPAL */
select * 
into   #TMP_amortizacion
from   ca_amortizacion
where  am_operacion = @w_operacionca

/* ATOMICIDAD POR TRANSACCION */
begin tran

/* ACTUALIZAR DATOS DE LA OPERACION */
update ca_operacion
set    op_cuota             = round(((@w_op_cuota * porcentaje) / 100.0),2),
       op_fecha_ini         = @w_op_fecha_ini,
       op_fecha_liq         = @w_op_fecha_liq,
       op_fecha_fin         = @w_op_fecha_fin,
       op_fecha_ult_proceso = @w_op_fecha_ult_proceso,
       op_oficina           = @w_op_oficina,
       op_oficial           = @w_op_oficial --LPO TEC
from   #TMP_operaciones
where  op_operacion = operacion

/* ACTUALIZAR DATOS DE LOS DIVIDENDOS */
delete ca_dividendo
where  di_operacion in (select operacion from #TMP_operaciones)

if @@error <> 0 
begin
   select @w_error = 710003
   goto ERROR
end

insert into ca_dividendo
select operacion,     di_dividendo, di_fecha_ini,   di_fecha_ven, di_de_capital,
       di_de_interes, di_gracia,    di_gracia_disp, di_estado,    di_dias_cuota,
       di_intento,    di_prorroga,  di_fecha_can
from   #TMP_dividendo, #TMP_operaciones
                                                                                                                                                                                                                                                            
if @@error != 0
begin
   select @w_error = 710003
   goto ERROR
end

/* ACTUALIZAR DATOS DE LA AMORTIZACION */
delete ca_amortizacion
where  am_operacion in (select operacion from #TMP_operaciones)

if @@error <> 0 
begin
   select @w_error = 710004
   goto ERROR
end

insert into ca_amortizacion
select operacion, am_dividendo, am_concepto, am_estado, am_periodo,
       round(((am_cuota * porcentaje) / 100.0),2), round(((am_gracia * porcentaje) / 100.0),2),
       round(((am_pagado * porcentaje) / 100.0),2), round(((am_acumulado * porcentaje) / 100.0),2), 
       am_secuencia
from   #TMP_amortizacion, #TMP_operaciones
                                                                                                                                                                                                                                                            
if @@error != 0
begin
   select @w_error = 710003
   goto ERROR
end

/* VALIDAR LOS DATOS DE AMORTIZACION DE LAS HIJAS RESPECTO A LA OPERACION GRUPAL */
declare cursor_amortizacion cursor for
select  am_dividendo, am_concepto, am_estado, am_periodo,
         round(sum(am_cuota),2), round(sum(am_gracia),2), round(sum(am_pagado),2), round(sum(am_acumulado),2)
from    #TMP_amortizacion
group   by am_dividendo, am_concepto, am_estado, am_periodo
for read only
   
open    cursor_amortizacion
fetch   cursor_amortizacion 
into    @w_am_dividendo, @w_am_concepto, @w_am_estado, @w_am_periodo,
        @w_am_cuota,     @w_am_gracia,   @w_am_pagado, @w_am_acumulado
   
/* WHILE cursor_amortizacion */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) return 710003

   /* TOTALES DE LAS OPERACIONES HIJAS */
   select @w_am_cuota_tot     = round(sum(am_cuota),2),
          @w_am_gracia_tot    = round(sum(am_gracia),2),
          @w_am_pagado_tot    = round(sum(am_pagado),2),
          @w_am_acumulado_tot = round(sum(am_acumulado),2)
   from   ca_amortizacion
   where  am_operacion in (select operacion from #TMP_operaciones)
   and    am_dividendo = @w_am_dividendo
   and    am_concepto  = @w_am_concepto
   and    am_estado    = @w_am_estado
   and    am_periodo   = @w_am_periodo

   /* VERIFICAR CUADRE DE VALORES */
   if @w_am_cuota     <> @w_am_cuota_tot 
   or @w_am_gracia    <> @w_am_gracia_tot
   or @w_am_pagado    <> @w_am_pagado_tot 
   or @w_am_acumulado <> @w_am_acumulado_tot 
   begin
      select @w_am_cuota     = @w_am_cuota - @w_am_cuota_tot,
             @w_am_gracia    = @w_am_gracia - @w_am_gracia_tot,
             @w_am_pagado    = @w_am_pagado - @w_am_pagado_tot,  
             @w_am_acumulado = @w_am_acumulado - @w_am_acumulado_tot

      update ca_amortizacion
      set    am_cuota     = am_cuota + @w_am_cuota,
             am_gracia    = am_gracia + @w_am_gracia,
             am_pagado    = am_pagado + @w_am_pagado,
             am_acumulado = am_acumulado + @w_am_acumulado
      where  am_operacion = @w_op_ultima
      and    am_dividendo = @w_am_dividendo
      and    am_concepto  = @w_am_concepto
      and    am_estado    = @w_am_estado
      and    am_periodo   = @w_am_periodo

      if @@error <> 0
      begin
         close cursor_amortizacion
         deallocate cursor_amortizacion

         select @w_error = 710003
         goto ERROR
      end
   end

   fetch   cursor_amortizacion 
   into    @w_am_dividendo, @w_am_concepto, @w_am_estado, @w_am_periodo,
           @w_am_cuota,     @w_am_gracia,   @w_am_pagado, @w_am_acumulado
   
end /* WHILE cursor_amortizacion */

close cursor_amortizacion
deallocate cursor_amortizacion

/* ACTUALIZAR DATOS DE RUBROS */
update ca_rubro_op
set    ro_valor          = (select round(((A.ro_valor * porcentaje) / 100.0),2) from ca_rubro_op A where ro_operacion = @w_operacionca and A.ro_concepto = C.ro_concepto),
       ro_porcentaje     = (select A.ro_porcentaje from ca_rubro_op A where ro_operacion = @w_operacionca and A.ro_concepto = C.ro_concepto),
       ro_porcentaje_aux = (select A.ro_porcentaje_aux from ca_rubro_op A where ro_operacion = @w_operacionca and A.ro_concepto = C.ro_concepto),
       ro_porcentaje_efa = (select A.ro_porcentaje_efa from ca_rubro_op A where ro_operacion = @w_operacionca and A.ro_concepto = C.ro_concepto)
from   #TMP_operaciones B, #TMP_rubro_op C, ca_rubro_op D
where  D.ro_operacion = operacion
and    D.ro_concepto  = C.ro_concepto

/* VALIDAR LOS DATOS DE RUBROS DE LAS HIJAS RESPECTO A LA OPERACION GRUPAL */
declare cursor_rubros cursor for
select  ro_concepto, isnull(ro_valor, 0)
from    #TMP_rubro_op
for read only
   
open    cursor_rubros
fetch   cursor_rubros
into    @w_ro_concepto, @w_ro_valor
   
/* WHILE cursor_rubros */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) return 710005

   /* VERIFICAR QUE EL RUBRO EXISTA EN UNA DE LAS OPERACIONES HIJAS */
   if not exists (select 1 from ca_rubro_op where ro_operacion = @w_op_ultima and ro_concepto = @w_ro_concepto)
   begin
      /* INSERTAR EL RUBRO EN LAS OPERACIONES HIJAS */
      insert into ca_rubro_op (
      ro_operacion,            ro_concepto,       ro_tipo_rubro,     ro_fpago,
      ro_prioridad,            ro_paga_mora,      ro_provisiona,     ro_signo,
      ro_factor,               ro_referencial,    ro_signo_reajuste, ro_factor_reajuste,
      ro_referencial_reajuste, ro_porcentaje,     ro_gracia,         ro_concepto_asociado,
      ro_base_calculo,         ro_porcentaje_aux, ro_principal,      ro_garantia,
      ro_valor)
      select
      operacion,               ro_concepto,       ro_tipo_rubro,     ro_fpago,
      ro_prioridad,            ro_paga_mora,      ro_provisiona,     ro_signo,
      ro_factor,               ro_referencial,    ro_signo_reajuste, ro_factor_reajuste,
      ro_referencial_reajuste, ro_porcentaje,     ro_gracia,         ro_concepto_asociado, 
      ro_base_calculo,         ro_porcentaje_aux, ro_principal,      ro_garantia,
      round(((ro_valor * porcentaje) / 100.0),2)
      from   #TMP_rubro_op, #TMP_operaciones
      where  ro_concepto = @w_ro_concepto

      if @@error <> 0
      begin
         close cursor_rubros
         deallocate cursor_rubros

         select @w_error = 710005
         goto ERROR
      end
   end

   /* TOTALES DE LAS OPERACIONES HIJAS */
   select @w_ro_valor_tot = isnull(round(sum(ro_valor),2), 0)
   from   ca_rubro_op
   where  ro_operacion in (select operacion from #TMP_operaciones)
   and    ro_concepto   = @w_ro_concepto

   /* VERIFICAR CUADRE DE VALORES */
   if @w_ro_valor <> @w_ro_valor_tot 
   begin
      select @w_ro_valor = @w_ro_valor - @w_ro_valor_tot

      update ca_rubro_op
      set    ro_valor = ro_valor + @w_ro_valor
      where  ro_operacion = @w_op_ultima
      and    ro_concepto  = @w_ro_concepto

      if @@error <> 0
      begin
         close cursor_rubros
         deallocate cursor_rubros

         select @w_error = 710005
         goto ERROR
      end
   end

   fetch   cursor_rubros
   into    @w_ro_concepto, @w_ro_valor
   
end /* WHILE cursor_rubros */

close cursor_rubros
deallocate cursor_rubros

/* ATOMICIDAD POR TRANSACCION */
commit tran

return 0
                                                                                                                                                                                                                                                      
ERROR:
while @@trancount > 0 rollback tran
                                                                                                                                                                                                                                                        
return @w_error
                                                                                                                                                                                                                                              
GO

