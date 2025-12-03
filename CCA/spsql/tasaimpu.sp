/************************************************************************/
/*   Archivo:              tasaimpu.sp                                  */
/*   Stored procedure:     sp_actualiza_tasa_impuestos                  */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez B.                             */
/*   Fecha de escritura:   2003                                         */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Procedimiento para  actualizar las tasas                           */
/*   para IVA y TIMBRE en el modulo de CARTERA                          */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_tasa_impuestos')
   drop proc sp_actualiza_tasa_impuestos
go

create proc sp_actualiza_tasa_impuestos
       @i_fecha_proceso       datetime = null,
       @s_user			         login = null
as
declare
   @w_sp_name              varchar(30),
   @w_return               int,
   @w_error                int,
   @w_concepto_conta_iva   catalogo,
   @w_concepto_conta_itim  catalogo,
   @w_parametro_tasaiva    catalogo,
   @w_parametro_tasatim    catalogo,
   @w_tasa_iva             float,
   @w_tasa_timbre          float,
   @w_tasa_actual_iva      float,
   @w_tasa_actual_tim      float,
   @w_base                 money,
   @w_timbre               catalogo,
   @w_actualizar_iva       char(1),
   @w_actualizar_tim       char(1),
   @w_op_operacion         int,
   @w_ro_concepto          catalogo,
   @w_ro_concepto_asociado catalogo,
   @w_concepto_timbre      catalogo,
   @w_op_monto_aprobado    money,
   @w_op_estado            tinyint,
   @w_valor_timbre         money,
   @w_valor_base           money,
   @w_valor_iva            money,
   @w_rango_min            money,
   @w_rango_max            money,
   @w_ro_fpago             char(1),
   @w_contador_iva         int,
   @w_contador_tim         int,
   @w_secuencial           int,
   @w_decimales_nal        smallint,
   @w_rowcount             int
   
-- INICIALIZAR VARIABLES
select @w_sp_name        = 'sp_actualiza_tasa_impuestos',
       @w_contador_iva   = 0,     
       @w_contador_tim   = 0




exec sp_decimales
     @i_moneda = 0,
     @o_decimales = @w_decimales_nal out

-- PARAMETROS GENERALES
select @w_concepto_timbre = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico  =  'TIMBRE' 
and    pa_producto = 'CCA'
set transaction isolation level read uncommitted

select @w_concepto_conta_iva = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CONIVA'
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error =  710449
   goto ERROR
end

select @w_concepto_conta_itim =  pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'CONTIM'
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   select @w_error =  710450
   goto ERROR
end

select @w_parametro_tasaiva = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico  =  'TASIVA'
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error =  710451
   goto ERROR
end

select @w_parametro_tasatim =  pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'TASTIM'
and    pa_producto = 'CCA'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error =  710452
   goto ERROR
end

-- PARA IVA CONCEPTO

select @w_tasa_iva = iva_des_porcen 
from   cob_conta..cb_iva
where  iva_codigo = @w_concepto_conta_iva ---'0200'
set transaction isolation level read uncommitted

-- PARA TIMBRE

select @w_tasa_timbre = cr_porcentaje,
       @w_base        = cr_base
from   cob_conta..cb_conc_retencion
where  cr_codigo = @w_concepto_conta_itim ---'0345'
set transaction isolation level read uncommitted

-- CODIGO DEL RUBRO TIMBRE
select @w_timbre = pa_char
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'TIMBRE'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
begin
   select @w_error = 710120
   goto ERROR
end 

-- VERIFICAR LA TASA ACTUAL DEL IVA
set rowcount 1
select @w_tasa_actual_iva =  vd_valor_default
from   cob_cartera..ca_valor_det
where  vd_tipo        =  @w_parametro_tasaiva
set rowcount 0

-- COMPARA Y ACTUALIZA
select @w_actualizar_iva = 'N'

if @w_tasa_actual_iva <> @w_tasa_iva
begin
   update cob_cartera..ca_valor_det
   set    vd_valor_default = @w_tasa_iva
   where  vd_tipo          = @w_parametro_tasaiva
   
   select @w_actualizar_iva = 'S'
end

-- VERIFICAR LA TASA ACTUAL DEL TIMBRE
set rowcount 1
select @w_tasa_actual_tim =  vd_valor_default
from   cob_cartera..ca_valor_det
where  vd_tipo        =  @w_parametro_tasatim 
set rowcount 0

-- COMPARA Y ACTUALIZA
select @w_actualizar_tim = 'N'

if @w_tasa_actual_tim <> @w_tasa_timbre
begin
   update cob_cartera..ca_valor_det
   set    vd_valor_default = @w_tasa_timbre
   where  vd_tipo        =  @w_parametro_tasatim 
   
   update cob_cartera..ca_tablas_un_rango
   set    tur_valor_min  = @w_base,
          tur_valor_max  = @w_base
   where  tur_concepto =  @w_timbre
   
   if @@error != 0 
   begin
     select @w_error = 710453
     goto ERROR
   end 
   
   select @w_actualizar_tim = 'S'
end

--ACTUALIZAR EL IVA EN LAS OPERACIONES
if @w_actualizar_iva = 'S' or @w_actualizar_tim = 'S'
begin
   declare cursor_act_iva_timbre cursor
      for select op_operacion, ro_concepto,       ro_concepto_asociado,
                 op_estado,    op_monto_aprobado, ro_fpago
          from   ca_rubro_op, ca_operacion, ca_concepto
          where  ro_operacion = op_operacion
          and    op_estado not in (3,6)
          and    co_concepto = ro_concepto
          and    co_categoria in ('A', 'T')
          and    ro_valor > 0
          order  by ro_concepto
          for read only

   open cursor_act_iva_timbre 
   
   fetch cursor_act_iva_timbre
   into  @w_op_operacion, @w_ro_concepto,       @w_ro_concepto_asociado,
         @w_op_estado,    @w_op_monto_aprobado, @w_ro_fpago
   
   while   @@fetch_status = 0
   begin
      if (@@fetch_status = -1)
      begin
         select @w_error = 710004
         goto ERROR
      end
      
      if @w_actualizar_iva = 'S' and  @w_ro_concepto <> @w_concepto_timbre and (@w_ro_fpago <> 'L' or @w_op_estado in(0,99))
      begin
         select @w_contador_iva   = @w_contador_iva + 1
         
         select @w_valor_base = 0
         
         select @w_valor_base = ro_valor
         from ca_rubro_op
         where ro_operacion = @w_op_operacion
         and ro_concepto    = @w_ro_concepto_asociado
         
         if @w_valor_base > 0
         begin
            select @w_valor_iva = round(@w_tasa_iva * @w_valor_base / 100.0, @w_decimales_nal)
            
            update ca_rubro_op
            set    ro_valor             = @w_valor_iva,
                   ro_porcentaje        = @w_tasa_iva,
                   ro_porcentaje_efa    = @w_tasa_iva,
                   ro_porcentaje_aux    = @w_tasa_iva
            where  ro_operacion  = @w_op_operacion 
            and    ro_concepto   = @w_ro_concepto
            
            update ca_amortizacion
            set    am_cuota     =   @w_valor_iva,
                   am_acumulado = @w_valor_iva 
            where  am_operacion  = @w_op_operacion 
            and    am_concepto   = @w_ro_concepto
            and    am_pagado     = 0
            and    am_estado     != 3
         end  --@w_alor_base > 0
         
         exec @w_secuencial = sp_gen_sec
              @i_operacion       = @w_op_operacion
         
         insert into ca_tasas
               (ts_operacion,      ts_dividendo,   ts_fecha,
                ts_concepto,       ts_porcentaje,  ts_secuencial,
                ts_porcentaje_efa, ts_referencial, ts_signo,
                ts_factor)
         values(@w_op_operacion,    0,                    @i_fecha_proceso,
                @w_ro_concepto,     @w_tasa_actual_iva,   @w_secuencial,
                @w_tasa_actual_iva, @w_parametro_tasaiva, '+',
                0.0)
         
         if @@error <> 0
         begin
            select @w_error = 703118
            goto ERROR
         end
      end ---IVA
      
      if @w_actualizar_tim = 'S' and  @w_ro_concepto = @w_concepto_timbre and @w_op_estado in (0,99)
      begin
         select @w_contador_tim   = @w_contador_tim + 1
         
         select @w_rango_min  = tur_valor_min,
                @w_rango_max  = tur_valor_max
         from   ca_tablas_un_rango
         where  tur_concepto = @w_ro_concepto
         
         if @w_op_monto_aprobado >= @w_rango_min
         begin  
            select @w_valor_timbre = round(@w_op_monto_aprobado * @w_tasa_timbre / 100.0, @w_decimales_nal)
            
            update ca_rubro_op
            set    ro_valor             = @w_valor_timbre,
                   ro_porcentaje        = @w_tasa_timbre,
                   ro_porcentaje_efa    = @w_tasa_timbre,
                   ro_porcentaje_aux    = @w_tasa_timbre
            where  ro_operacion   = @w_op_operacion 
            and    ro_concepto    = @w_ro_concepto
         end
         
         exec @w_secuencial = sp_gen_sec
              @i_operacion       = @w_op_operacion
         
         insert into ca_tasas
               (ts_operacion,      ts_dividendo,   ts_fecha,
                ts_concepto,       ts_porcentaje,  ts_secuencial,
                ts_porcentaje_efa, ts_referencial, ts_signo,
                ts_factor)
         values(@w_op_operacion,    0,                    @i_fecha_proceso,
                @w_ro_concepto,     @w_tasa_actual_tim,   @w_secuencial,
                @w_tasa_actual_tim, @w_parametro_tasatim, '+',
                0.0)
         
         if @@error <> 0
         begin
            select @w_error = 703118
            goto ERROR
         end
      end ---TIMBRE
      
      fetch cursor_act_iva_timbre
      into  @w_op_operacion,  @w_ro_concepto,       @w_ro_concepto_asociado,
            @w_op_estado,     @w_op_monto_aprobado, @w_ro_fpago
   end -- WHILE CURSOR ACTUALIZA IVA
   
   close cursor_act_iva_timbre
   deallocate cursor_act_iva_timbre
end --Actualizaciones 

return 0

ERROR:  
exec sp_errorlog
     @i_fecha       = @i_fecha_proceso,
     @i_error       = @w_error,
     @i_usuario     = @s_user,
     @i_tran        = 7000, 
     @i_tran_name   = @w_sp_name,
     @i_rollback    = 'N',  
     @i_cuenta      = '',
     @i_descripcion = 'tasaimpu.sp ERROR ACTUALIZANDO TASAS PARA IVA - TIMBRE'
  
return 0
go
