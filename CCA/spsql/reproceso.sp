/************************************************************************/
/*      Archivo:                recaltasvar.sp                          */
/*      Stored procedure:       sp_reproceso_en_batch                   */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     dic. 2005                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Este sp tiene como propósito  volver a recalcular las cuotas    */
/*      NO VIGENES de una operacion que por efecto de FEHA VALOR o RV   */
/*      vuelva a recuperar estas cuotas sin el reproceso efectuado      */
/*      en una fecha dada.                                              */
/*      si al ejecutar el batch para fechas atrasadas, existe un reg.   */
/*      en la tabla ca_reproceso_en_fecha_valor se ejecutara este sp    */
/*      para reprocear las cuotas NO VIGENTES                           */
/************************************************************************/  
/*			                  MODIFICACIONES				                     */
/*	     FECHA		     AUTOR			          RAZON		               */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_reproceso_en_batch')
   drop proc sp_reproceso_en_batch
go

create proc sp_reproceso_en_batch
 @i_operacion    int,
 @i_moneda       int
as
declare
@w_sp_name		     varchar(30),
@w_ro_porcentaje    float,

@w_ro_concepto      catalogo,
@w_num_dec          tinyint,
@w_num_dec_mn       smallint,
@w_div_vigente      int,
@w_re_nuevo_porcentaje  float,
@w_concepto_ioc       catalogo,
@w_moneda_local       smallint,
@w_por_asociado       float,
@w_concepto_asociado  catalogo,
@w_valor_aso          money,
@w_base               money,
@w_valor_rubro        money,
@w_contador1          int,
@w_contador2          int



--- INICIALIZACION VARIABLES 
select @w_sp_name = 'sp_reproceso_en_batch',
       @w_concepto_ioc = ''



--VALIDACION EXISTENCIA DE LA CREACION DE RUBROS

select @w_contador1 = count(1)
 from ca_rubros_recalculo

select @w_contador2 = count(1)
 from ca_rubros_recalculo,ca_concepto
where co_concepto = re_concepto_IOC

if @w_contador1 <> @w_contador2
   return 0


exec  sp_decimales
@i_moneda       = @i_moneda,
@o_decimales    = @w_num_dec out,
@o_mon_nacional = @w_moneda_local out,
@o_dec_nacional = @w_num_dec_mn out

--inicio cursor dos
declare cursor_reproceso cursor for 
     select
     ro_concepto,
     ro_porcentaje,
     re_nuevo_porcentaje,
     re_concepto_IOC
    from ca_rubro_op,
          ca_rubros_recalculo
     where ro_operacion = @i_operacion          
     and    ro_concepto = re_concepto

for read only
open   cursor_reproceso
fetch cursor_reproceso into
      @w_ro_concepto,
      @w_ro_porcentaje,
      @w_re_nuevo_porcentaje ,
      @w_concepto_ioc

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin
     
     PRINT 'reproceso.sp entro @w_re_nuevo_porcentaje' + @w_re_nuevo_porcentaje +  '@w_ro_porcentaje' + @w_ro_porcentaje
     
   if  @w_re_nuevo_porcentaje <>  @w_ro_porcentaje
   begin    ---(1)

   --actualización de las cuotas no vigentes estado 0
    select  @w_div_vigente   = isnull(max(di_dividendo),0)
    from ca_dividendo
    where di_operacion = @i_operacion
    and di_estado = 1

    if @w_div_vigente    > 0
    begin
       update ca_amortizacion  
       set am_cuota = round(am_cuota *  @w_re_nuevo_porcentaje   / @w_ro_porcentaje,0),
           am_acumulado = round(am_cuota *  @w_re_nuevo_porcentaje   / @w_ro_porcentaje,0)
       from ca_amortizacion
       where am_operacion = @i_operacion
       and  am_concepto =  @w_ro_concepto
       and  am_estado = 0
       and am_pagado = 0
       and am_cuota != 0
       and am_dividendo >  @w_div_vigente  
       
       
       set rowcount 1
       select @w_valor_rubro = am_cuota
       from ca_amortizacion
       where am_operacion = @i_operacion
       and  am_dividendo =  @w_div_vigente  + 1
       and am_concepto = @w_ro_concepto
       set rowcount 0
       
       update ca_rubro_op
       set ro_porcentaje = @w_re_nuevo_porcentaje,
           ro_porcentaje_efa =  @w_re_nuevo_porcentaje, 
           ro_porcentaje_aux = @w_re_nuevo_porcentaje,
           ro_valor          = @w_valor_rubro

       where ro_operacion = @i_operacion
       and ro_concepto =  @w_ro_concepto
    
       
       select @w_concepto_asociado = ro_concepto,
              @w_por_asociado      = ro_porcentaje
       from ca_rubro_op
       where ro_operacion = @i_operacion
       and ro_concepto_asociado = @w_ro_concepto
       
       if @@rowcount > 0 ---RECALCULAR LOS IVAS DEL RUBRO
       begin

            insert into ca_reproceso_asociados
            select  am_operacion,am_dividendo,am_concepto,am_cuota,@w_concepto_asociado,0
            from ca_amortizacion
            where am_operacion = @i_operacion
            and am_concepto = @w_ro_concepto
            and  am_estado != 3
            and am_pagado = 0
            and am_dividendo >  @w_div_vigente
            
            update ca_reproceso_asociados
            set valor_rubro_asociado = round(valor_rubro *  @w_por_asociado /100 ,@w_num_dec)
            where operacion = @i_operacion
            and rubro = @w_ro_concepto
            and rubro_asociado = @w_concepto_asociado
            
            update ca_amortizacion  
            set am_cuota = valor_rubro_asociado,
                am_acumulado = valor_rubro_asociado
            from ca_amortizacion,
                  ca_reproceso_asociados
            where am_operacion = @i_operacion
            and  am_concepto =  @w_concepto_asociado
            and am_operacion = operacion
            and am_dividendo = dividendo
            and  am_concepto = rubro_asociado

            
             set rowcount 1
             select @w_valor_aso = valor_rubro_asociado,
                    @w_base      = valor_rubro
             from  ca_reproceso_asociados
             where operacion = @i_operacion
             and   rubro = @w_ro_concepto
             set rowcount 0
             
             update  ca_rubro_op
             set ro_valor = @w_valor_aso,
                 ro_base_calculo = @w_base 
             where ro_operacion = @i_operacion
             and   ro_concepto = @w_concepto_asociado
             
             delete ca_reproceso_asociados
             where operacion >= 0
         
       end ---RECALCULAR LOS IVAS DEL RUBRO
    end  --fin act los vigentes

   End ---(1) si las tasas son diferentes

   select @w_concepto_ioc = ''  
  --cursor dos  
 fetch   cursor_reproceso into
 @w_ro_concepto,
 @w_ro_porcentaje,
 @w_re_nuevo_porcentaje ,
 @w_concepto_ioc
 
end --WHILE CURSOR RUBROS
close cursor_reproceso
deallocate cursor_reproceso
 


return 0
go
