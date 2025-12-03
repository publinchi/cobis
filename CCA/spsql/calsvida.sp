/************************************************************************/
/*      Archivo:                calsvida.sp                             */
/*      Stored procedure:       sp_calculo_seguro_vida                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Marcelo Poveda                          */
/*      Fecha de escritura:     Jun. 2001                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCORP".							                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo de seguro de vida como cuota fija                       */
/*                              CAMBIOS                                 */
/*    FECHA            AUTOR              CAMBIO	                    */
/*    01-Jun-2022      G. Fernandez    Se comenta prints                */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_calculo_seguro_vida')
   drop proc sp_calculo_seguro_vida
go

create proc sp_calculo_seguro_vida
@i_operacion	int = NULL,
@i_tasa_int     float = null

as
declare
@w_sp_name		varchar(30),
@w_concepto		catalogo,
@w_op_tdividendo	catalogo,
@w_op_periodo_int	int,
@w_dias_div		int,
@w_max_div		int,
@w_min_div		int,
@w_est_vigente		tinyint,
@w_est_novigente	tinyint,
@w_contador		int,
@w_valor_presente	money,
@w_valor_seguro		money,
@w_factor		float,
@w_cuotas_atras		int,
@w_total_presente	money,
@w_num_cuotas		int,
@w_cuota_fija		money,
@w_num_dec              smallint,
@w_moneda               smallint,
@w_return               int,
@w_seguro_vida          catalogo,
@w_seguro_ext           catalogo,
@w_porcentaje           float

/** INICIALIZACION VARIABLES **/
select @w_sp_name = 'sp_calculo_seguro_vida',
@w_concepto	  = '',
@w_min_div	  = 0,
@w_max_div	  = 0,
@w_contador	  = 0,
@w_valor_presente = 0,
@w_total_presente = 0,
@w_cuota_fija	  = 0

select @w_est_vigente = 1,
       @w_est_novigente = 0


/*CODIGO DEL RUBRO SEGURO*/
select @w_seguro_vida = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SEGURO'
and   pa_producto = 'CCA'
set transaction isolation level read uncommitted

/*CODIGO DEL RUBRO SEGURO EXTRAPRIMA*/
select @w_seguro_ext = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SEGEXT'
and   pa_producto = 'CCA'
set transaction isolation level read uncommitted

---EPB_feb-26-2002
/** VALIDAR EXISTENCIA SEGURO DE VIDA **/
if not exists (select 1 from   ca_rubro_op_tmp, ca_concepto
where  rot_operacion = @i_operacion
and    rot_fpago     = 'P'
and    rot_concepto  = co_concepto
and    co_categoria = 'S')
return 0


if @i_tasa_int <= 0 begin
   --GFP se suprime print
   --PRINT 'calsvida.sp ERROR Tasa INTERES No debe ser 0 --->@i_tasa_int ' + cast(@i_tasa_int as varchar)
   return 701162
end

select @i_tasa_int = @i_tasa_int / 100.0
---EPB_feb-26-2002


/** DATOS OPERACION **/
select @w_op_tdividendo  = opt_tdividendo,
       @w_op_periodo_int = opt_periodo_int,
       @w_moneda         = opt_moneda
from ca_operacion_tmp
where opt_operacion	= @i_operacion



/*NUMERO DE DECIMALES*/
exec @w_return = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out
if @w_return != 0 
   return  @w_return


/** NUMERO DE DIAS POR DIVIDENDO **/
select @w_dias_div = td_factor * @w_op_periodo_int
from   ca_tdividendo
where  td_tdividendo = @w_op_tdividendo

---EPB_feb-26-2002
/** CURSOR POR SI HAY MAS DE UN RUBRO DE SEGURO DE VIDA PARAMETRIZADO COMO FIJO**/
declare cursor_rubros_sfijos cursor 
for select rot_concepto, 
           rot_porcentaje
from  ca_rubro_op_tmp, ca_concepto
where rot_operacion = @i_operacion
and   rot_fpago     = 'P'
and   rot_concepto  = co_concepto
and   co_categoria  = 'S'  ---concepto in (@w_seguro_vida,@w_seguro_ext)  ---co_categoria = 'V'   -- ingresar cateforia seguro de vida
for read only

open    cursor_rubros_sfijos

fetch   cursor_rubros_sfijos into
@w_concepto, 
@w_porcentaje

while   @@fetch_status = 0 begin /*WHILE CURSOR PRINCIPAL*/

   if (@@fetch_status = -1) return 708999

   select @w_contador = 0,
   @w_valor_presente  = 0,
   @w_total_presente  = 0,
   @w_cuota_fija      = 0


 /** CALCULAR VALOR PRESENTE DEL CONCEPTO SEGURO DE VIDA **/
 select @w_max_div = max(dit_dividendo)
 from   ca_dividendo_tmp
 where  dit_operacion = @i_operacion
 and    dit_estado in (@w_est_novigente, @w_est_vigente) 	

 if @w_max_div = 0 return 0

 select @w_min_div = min(dit_dividendo)
 from   ca_dividendo_tmp
 where  dit_operacion = @i_operacion
 and    dit_estado in ( @w_est_novigente,@w_est_vigente)

 select @w_contador = @w_max_div 

 while @w_contador >= @w_min_div begin

   /** INICIALIZAR VARIABLES **/
   select @w_valor_seguro = 0,
   @w_valor_presente      = 0

   select @w_valor_seguro = ((amt_cuota - amt_pagado) + abs(amt_cuota - amt_pagado))/2
   from   ca_amortizacion_tmp
   where  amt_operacion  = @i_operacion
   and    amt_dividendo  = @w_contador
   and    amt_concepto   = @w_concepto

   /** CALCULAR EL VALOR PRESENTE DEL SEGURO **/


   select @w_cuotas_atras = @w_contador --- + 1

   select @w_valor_presente = @w_valor_seguro / power((1+(@i_tasa_int*@w_dias_div/360)),@w_cuotas_atras)   

   select @w_total_presente = @w_total_presente + @w_valor_presente

  ---PRINT '(calsvida.sp) TASA INT UTILIZADA  %1!+
  ---       VALOR SOBRE SALDO  %2!+
  ---        CUOTA A CALULAR  %3!+
  ---        VALOR PRESENTE DE LA CUOTA  %4!'+@i_tasa_int+@w_valor_seguro+@w_contador+@w_total_presente

   select @w_contador = @w_contador - 1
  
 end

 /** CALCULAR CUOTA FIJA PARA SEGURO **/
 select @w_num_cuotas = @w_max_div - @w_min_div + 1

 select @w_factor = power((1+(@i_tasa_int*@w_dias_div/360)),@w_num_cuotas)

 ---PRINT 'calsvida.sp VALOR PRESENTE TOTALIZADA %1!',@w_total_presente


 select @w_cuota_fija = @w_total_presente * ((@w_factor*(@i_tasa_int*@w_dias_div/360))/(@w_factor - 1))

---PRINT '(calsvida.sp)  CUOTA DE SEGURO DESPUES DE LA FORMULA DE CUOTA FIJA  %1!',@w_cuota_fija

 select @w_cuota_fija = round(@w_cuota_fija,@w_num_dec)


 /** ACTUALIZAR TABLA DE AMORTIZACION **/
 update ca_amortizacion_tmp
 set  amt_cuota     = @w_cuota_fija,
     amt_acumulado = @w_cuota_fija
 from   ca_amortizacion_tmp
 where  amt_operacion = @i_operacion
 and    amt_dividendo >= @w_min_div
 and    amt_dividendo <= @w_max_div
 and    amt_concepto  = @w_concepto	
 
 update ca_rubro_op_tmp
 set rot_valor = @w_cuota_fija
 where rot_concepto = @w_concepto	

 fetch   cursor_rubros_sfijos into
 @w_concepto, @w_porcentaje

end /*WHILE CURSOR RUBROS SFIJOS*/
close cursor_rubros_sfijos
deallocate cursor_rubros_sfijos



return 0
go
