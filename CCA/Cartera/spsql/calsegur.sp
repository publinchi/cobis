/************************************************************************/
/*      Archivo:                calsegur.sp                             */
/*      Stored procedure:       sp_calculo_seguros_sinsol               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     ene. 2003                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "COBISCorp".							                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCorp o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo de rubros con base saldo insoluto , este sp es llamado  */
/*      desde el sp gentabla.sp                      			        */
/*                              CAMBIOS                                 */
/*    FECHA            AUTOR              CAMBIO	                    */
/*    ENE-28-2005      Elcira Pelaez     Cambios para el BAC            */
/*      MAY-2006        E.Pelaez               DEF-6487                 */
/*    25-Mar-2022      G. Fernandez    Cerrar de cursos al generar error*/
/*    18-May-2022      K. Rodriguez    Cerrado cursor                   */
/*    01-Jun-2022      G. Fernandez    Se comenta prints                */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_calculo_seguros_sinsol')
   drop proc sp_calculo_seguros_sinsol
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_calculo_seguros_sinsol
@i_operacion	int = NULL

as
declare
@w_sp_name		varchar(30),
@w_concepto		catalogo,
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
@w_saldo_insoluto       money,
@w_saldo_otros          money,
@w_porcentaje           float,
@w_error                int,
@w_saldo_cap            money,
@w_monto                money,
@w_saldo_para_cuota     money,
@w_categoria            char(1),
@w_numero_codeudores    int,
@w_segvida              catalogo,
@w_dividendo_nv         int,
@w_estado_op            tinyint,
@w_estado_rubro         tinyint,
@w_op_tramite           int




--- INICIALIZACION VARIABLES 
select @w_sp_name = 'sp_calculo_seguros_sinsol',
@w_concepto	  = '',
@w_min_div	  = 0,
@w_max_div	  = 0,
@w_contador	  = 0,
@w_valor_presente = 0,
@w_total_presente = 0,
@w_cuota_fija	  = 0,
@w_saldo_otros    = 0,
@w_saldo_insoluto = 0


select @w_est_vigente = 1,
       @w_est_novigente = 0


select @w_segvida = pa_char 
from cobis..cl_parametro
where pa_producto  = 'CCA'
and pa_nemonico    = 'SEGURO'



--- VALIDAR EXISTENCIA DE RUBROS  SEGURO DE VIDA 
if not exists (select 1 from   ca_rubro_op_tmp
where  rot_operacion = @i_operacion
and    rot_fpago     in ('P','A')
and    rot_saldo_insoluto = 'S')
return 0


--- DATOS OPERACION 
select  @w_moneda         = opt_moneda,
        @w_monto          = opt_monto,
        @w_estado_op      = opt_estado,
        @w_op_tramite     = opt_tramite
from ca_operacion_tmp
where opt_operacion	= @i_operacion




---  NUMERO DE DECIMALES
exec @w_return = sp_decimales
@i_moneda    = @w_moneda,
@o_decimales = @w_num_dec out
if @w_return != 0 
   return  @w_return



---CODEUDORES QUE TIENEN SEGVIDA PARA ESTA OBLIGACION 
if @w_op_tramite is not null
begin
   select @w_numero_codeudores = count(1)
   from cob_credito..cr_deudores
   where de_tramite = @w_op_tramite
   and   de_segvida = 'S'
   
   if @w_numero_codeudores = 0
      select @w_numero_codeudores = 1
end
else
begin

   select @w_numero_codeudores = count(1)
   from ca_deu_segvida
   where dt_operacion  = @i_operacion
   and   dt_segvida = 'S'

   if @w_numero_codeudores = 0
      select @w_numero_codeudores = 1   
end




declare cursor_rubros_saldo_insoluto cursor for 
select rot_concepto, 
       rot_porcentaje
from   ca_rubro_op_tmp
where  rot_operacion = @i_operacion
and    rot_fpago     in ('P','A')
and    rot_saldo_insoluto = 'S'
order by rot_concepto
for read only

open cursor_rubros_saldo_insoluto

fetch   cursor_rubros_saldo_insoluto into
@w_concepto,
@w_porcentaje

while   @@fetch_status = 0 begin  ---WHILE CURSOR PRINCIPAL

   if (@@fetch_status = -1) return 708999

   select @w_contador = 0

   if  @w_porcentaje <=  0 
   begin
       --GFP se suprime print
       --PRINT 'calsegur.sp error el porcentaje esta en 0'
	   close cursor_rubros_saldo_insoluto              --GFP 25-Mar-2022
       deallocate cursor_rubros_saldo_insoluto
       select @w_error = 710387
       return @w_error
   end


   --- CALCULAR VALOR PRESENTE DEL CONCEPTO SEGURO DE VIDA 
   select @w_max_div = max(dit_dividendo)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion


   if @w_max_div = 0
   begin
      close cursor_rubros_saldo_insoluto          -- KDR 18/05/2022
      deallocate cursor_rubros_saldo_insoluto   
      return 0
   end


   select @w_min_div = min(dit_dividendo)
   from   ca_dividendo_tmp
   where  dit_operacion = @i_operacion
   
   select @w_contador = @w_min_div 


   --- PARA OBLIGACIONES DESEMBOLSADAS
   if @w_numero_codeudores > 0 and @w_estado_op <> 0   --XMA201 el rubro segvida se actualiza desde el div novigente para op VIGENTES
   begin
      select @w_dividendo_nv = min(dit_dividendo)
      from ca_dividendo_tmp
      where dit_operacion  = @i_operacion
      and   dit_estado = 0
     
      select @w_contador  = @w_dividendo_nv

   end

   while @w_contador <= @w_max_div 
   begin

   --- INICIALIZAR VARIABLES 
   select @w_valor_seguro = 0,
   @w_valor_presente      = 0,
   @w_saldo_cap           = 0,
   @w_saldo_para_cuota    = 0,
   @w_saldo_otros         = 0,
   @w_saldo_insoluto      = 0,
   @w_valor_seguro        = 0
   

   if @w_contador > 1
   select @w_saldo_cap = isnull(sum(amt_cuota),0)
   from ca_amortizacion_tmp,
        ca_rubro_op_tmp
   where  amt_operacion   = rot_operacion
   and    amt_operacion   = @i_operacion
   and    amt_concepto    = rot_concepto
   and    amt_dividendo  < @w_contador
   and    rot_tipo_rubro  = 'C'


  select @w_categoria = co_categoria
  from ca_concepto
  where co_concepto = @w_concepto


   select @w_saldo_cap         = isnull(@w_saldo_cap,0)
      
   select @w_saldo_para_cuota  = (@w_monto - @w_saldo_cap)
  

   if @w_contador = @w_max_div and @w_saldo_para_cuota = 0
   begin
      --El saldo es el mismo inicial por que  en la primera cuota hay gracia de CAPITAL
      select @w_saldo_para_cuota = isnull(sum(amt_cuota),0)
      from ca_amortizacion_tmp,
           ca_rubro_op_tmp
      where  amt_operacion   = rot_operacion
      and    amt_operacion   = @i_operacion
      and    amt_concepto    = rot_concepto
      and    amt_dividendo  = @w_contador
      and    rot_tipo_rubro  = 'C'
   end


  select @w_saldo_otros = isnull(sum(amt_acumulado - amt_pagado),0)
   from   ca_amortizacion_tmp,ca_concepto
   where  amt_operacion  = @i_operacion
   and    amt_dividendo  = @w_contador
   and    amt_concepto = co_concepto
   and    co_categoria in ('A','I','H','G','R','O','M','S')
   and    amt_concepto <> @w_concepto  --Para no incluir el mismo rubro que se calcula
   
   select @w_dias_div = dit_dias_cuota
   from ca_dividendo_tmp
   where dit_operacion =  @i_operacion
   and   dit_dividendo  = @w_contador
   
   select @w_saldo_insoluto = isnull(@w_saldo_para_cuota + @w_saldo_otros ,0)
   select @w_valor_seguro   = @w_saldo_insoluto * @w_dias_div * (@w_porcentaje/100) / 360
   select @w_valor_seguro   = round(@w_valor_seguro,@w_num_dec)

   ---SE ACTUALIZA EL VALOR DEL SEGURO, DE ACUERDO AL NUMERO DE CODEUDORES CON SEGURO DE VIDA
   if exists (select 1 from ca_deudores_tmp
              where dt_operacion  = @i_operacion) and (@w_segvida = @w_concepto) 
   begin
         if @w_numero_codeudores > 0
         select @w_valor_seguro   = round((@w_valor_seguro * @w_numero_codeudores),@w_num_dec)
   end
   

   if @w_contador = 1
   begin
   update ca_rubro_op_tmp
   set rot_base_calculo = @w_saldo_insoluto,
       rot_valor        = @w_valor_seguro
   where  rot_operacion = @i_operacion
   and    rot_concepto  = @w_concepto
   end


   if @w_segvida = @w_concepto   --XMA 201
   begin
      select @w_estado_rubro =  am_estado
      from ca_amortizacion
      where am_operacion  = @i_operacion
      and   am_dividendo  = @w_contador
      and   am_concepto   = @w_concepto

      if @w_estado_rubro = 3   ---significa que el 1er div NOVIGENTE, tiene el SEGVIDA cancelado
         select @w_contador = @w_contador + 1

   end  




   --- ACTUALIZAR TABLA DE AMORTIZACION 
   
   update ca_amortizacion_tmp
   set  amt_cuota     = @w_valor_seguro,
        amt_acumulado = @w_valor_seguro
   from ca_amortizacion_tmp
   where  amt_operacion = @i_operacion
   and    amt_dividendo = @w_contador
   and    amt_concepto  = @w_concepto	

   select @w_contador = @w_contador + 1

end   ---WHILE

fetch cursor_rubros_saldo_insoluto into
@w_concepto,
@w_porcentaje

end /*WHILE CURSOR RUBROS*/
close cursor_rubros_saldo_insoluto
deallocate cursor_rubros_saldo_insoluto

return 0
go


