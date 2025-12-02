/************************************************************************/
/*      Archivo:                rubcatal.sp                             */
/*      Stored procedure:       sp_rubros_catalogo                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     mar. 2006                               */
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
/*      Genera los rubros de la tabla de catalogo  ca_rubros_catalogos  */
/*      rubro calculados al vencimiento sobre el monto inicial del cred.*/
/*                              CAMBIOS                                 */
/*    FECHA            AUTOR              CAMBIO                        */
/*                                                                      */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_rubros_catalogo')
   drop proc sp_rubros_catalogo  
go

create proc sp_rubros_catalogo  
@i_operacion   int = NULL

as
declare
   @w_sp_name        varchar(30),
   @w_concepto       catalogo,
   @w_dias_div       int,
   @w_max_div        int,
   @w_min_div        int,
   @w_contador       int,
   @w_valor_seguro   money,
   @w_num_dec        smallint,
   @w_moneda         smallint,
   @w_return         int,
   @w_porcentaje     float,
   @w_monto          money,
   @w_dias_anio      smallint,
   @w_fecha_max      datetime,
   @w_meses_max      tinyint,
   @w_rowcount       int

select @w_meses_max = pa_tinyint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'RCTMAX'
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0
   select @w_meses_max = 12

--- INICIALIZACION VARIABLES 
select @w_sp_name    = 'sp_rubros_catalogo',
       @w_concepto   = '',
       @w_min_div      = 0,
       @w_max_div      = 0

select @w_fecha_max = dateadd(mm, @w_meses_max, opt_fecha_ini)
from   ca_operacion_tmp
where  opt_operacion = @i_operacion

if @@rowcount = 0
begin
   select @w_fecha_max = dateadd(mm, @w_meses_max, op_fecha_ini)
   from   ca_operacion
   where  op_operacion = @i_operacion
end

-- VALIDAR EXISTENCIA DE RUBROS  CATALOGO
if exists (select 1 from ca_rubro_op_tmp
           where  rot_operacion = @i_operacion
           and    rot_fpago = 'P'
           and    rot_saldo_por_desem = 'S'
           and    rot_concepto = ( select a.codigo
                                   from   cobis..cl_tabla b,
                                          cobis..cl_catalogo a
                                   where  b.tabla = 'ca_rubros_catalogos'
                                   and    b.codigo = a.tabla)
          )
   select @w_max_div   = @w_max_div
else
   return 0

select @w_max_div = max(dit_dividendo)
from   ca_dividendo_tmp
where  dit_operacion = @i_operacion
and    dit_fecha_ven <= @w_fecha_max

if @w_max_div = 0 
   return 0

select @w_min_div = min(dit_dividendo)
from   ca_dividendo_tmp
where  dit_operacion = @i_operacion

--- DATOS OPERACION 
select @w_moneda         = opt_moneda,
       @w_monto          = opt_monto,
       @w_dias_anio      = opt_dias_anio
from   ca_operacion_tmp
where  opt_operacion   = @i_operacion


---  NUMERO DE DECIMALES
exec @w_return = sp_decimales
     @i_moneda    = @w_moneda,
     @o_decimales = @w_num_dec out
if @w_return != 0 
   return  @w_return

declare
   cursor_rubros_catalogo cursor
   for select rot_concepto, rot_porcentaje
       from   ca_rubro_op_tmp
       where  rot_operacion = @i_operacion
       and    rot_fpago = 'P'
       and    rot_saldo_por_desem = 'S'
       and    rot_concepto = (select a.codigo
                              from   cobis..cl_tabla b,
                                     cobis..cl_catalogo a
                              where  b.tabla = 'ca_rubros_catalogos'
                              and    b.codigo = a.tabla )

order by rot_concepto
for read only

open cursor_rubros_catalogo

fetch cursor_rubros_catalogo
into  @w_concepto, @w_porcentaje

while   @@fetch_status not in(-1,0)
begin 
   select @w_contador = 0
   
   if @w_porcentaje <=  0
      return 710387
   
   select @w_contador = @w_min_div 
   
   while @w_contador <= @w_max_div 
   begin
      select @w_dias_div = dit_dias_cuota
      from   ca_dividendo_tmp
      where  dit_operacion =  @i_operacion
      and    dit_dividendo  = @w_contador
      
      select @w_valor_seguro   = @w_monto * @w_dias_div * (@w_porcentaje/100) / @w_dias_anio
      select @w_valor_seguro   = round(@w_valor_seguro,@w_num_dec)
      
      update ca_amortizacion_tmp
      set    amt_cuota     = @w_valor_seguro,
             amt_acumulado = @w_valor_seguro
      from   ca_amortizacion_tmp
      where  amt_operacion = @i_operacion
      and    amt_dividendo = @w_contador
      and    amt_concepto  = @w_concepto
      
      -- CALCULO DEL IVA
      declare
         @w_concepto_iva   catalogo,
         @w_porcentaje_iva float,
         @w_monto_iva      money
      
      select @w_concepto_iva     = rot_concepto,
             @w_porcentaje_iva   = rot_porcentaje,
             @w_monto_iva        = 0
      from   ca_rubro_op_tmp, ca_concepto
      where  rot_operacion = @i_operacion
      and    rot_concepto_asociado = @w_concepto
      and    co_concepto = rot_concepto
      and    co_categoria = 'A'
      
      if @@rowcount = 1
      begin
         select @w_monto_iva = @w_valor_seguro * @w_porcentaje_iva / 100.0
         select @w_monto_iva = round(@w_monto_iva, @w_num_dec)
         
         update ca_amortizacion_tmp
         set    amt_cuota     = @w_monto_iva,
                amt_acumulado = @w_monto_iva
         from   ca_amortizacion_tmp
         where  amt_operacion = @i_operacion
         and    amt_dividendo = @w_contador
         and    amt_concepto  = @w_concepto_iva
      end
      
      select @w_contador = @w_contador + 1
   end   ---WHILE
   
   -- BORRAR LOS VALORES QUE ESTAN MAS ALLA DE LA FECHA MAXIMA DE GENERACION
   delete ca_amortizacion_tmp
   where  amt_operacion = @i_operacion
   and    amt_dividendo > @w_max_div
   and    amt_concepto  = @w_concepto
   
   delete ca_amortizacion_tmp
   where  amt_operacion = @i_operacion
   and    amt_dividendo > @w_max_div
   and    amt_concepto  = (select rot_concepto
                           from   ca_rubro_op_tmp, ca_concepto
                           where  rot_operacion = @i_operacion
                           and    rot_concepto_asociado = @w_concepto
                           and    co_concepto = rot_concepto
                           and    co_categoria = 'A')
   
   fetch cursor_rubros_catalogo
   into  @w_concepto, @w_porcentaje
end -- WHILE CURSOR RUBROS

close cursor_rubros_catalogo
deallocate cursor_rubros_catalogo

return 0

go
