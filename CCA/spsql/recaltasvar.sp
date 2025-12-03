/************************************************************************/
/*      Archivo:                recaltasvar.sp                          */
/*      Stored procedure:       sp_recalculo_tasas_variables            */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira PElaez                           */
/*      Fecha de escritura:     dic. 2005                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Este sp tiene como propósito  revisar    los rubros con         */
/*      tasa referencial, si esta ha cambiado  calcular el valor        */
/*      y sumar o restar al ya generado. Aplica para los rubos diferente*/
/*      de CAP INT e IMO                                                */
/*      este sp es llamado desde el batch1   solo si la operacion  en   */
/*      proceso tiene tasa referencial                                  */
/************************************************************************/  
/*	                  MODIFICACIONES				                    */
/*	FECHA		AUTOR       	   RAZON		                        */
/*  AGO-2011    EPB                 ORS - 28617 BANCAMIA    		    */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_recalculo_tasas_variables')
   drop proc sp_recalculo_tasas_variables
go

create proc sp_recalculo_tasas_variables

as
declare
@w_sp_name		     varchar(30),
@w_ro_porcentaje    float,
@w_tasa_aplicar     catalogo,  
@w_ro_concepto      catalogo,
@w_num_dec          tinyint,
@w_referencial      catalogo,
@w_tasa_base        float,
@w_signo            char(1),
@w_factor           float,
@w_clase            char(1),
@w_nuevo_porcentaje float,
@w_valor_rubro      money,
@w_return           int,
@w_secuencial       int,
@w_por_asociado       float,
@w_concepto_asociado  catalogo,
@w_valor_aso          money,
@w_base               money,
@w_fecha_hoy          datetime,
@w_moneda             smallint,
@w_sector             catalogo,
@w_operacionca        int,
@w_procesa            char(1)


--- INICIALIZACION VARIABLES 
select @w_sp_name = 'sp_recalculo_tasas_variables'

-- REQ 089: ACUERDOS DE PAGO - EN ACUERDOS DE CANCELACION LA OPERACION NO RECALCULA RUBROS - 03/DIC/2010
if exists (select 1
from cob_credito..cr_acuerdo, ca_operacion
where op_operacion                = @w_operacionca
and   ac_banco                    = op_banco
and   ac_estado                   = 'V'                         -- NO ANULADOS
and   ac_tacuerdo                 = 'P'                         -- PRECANCELACION
and   op_fecha_ult_proceso  between ac_fecha_ingreso and ac_fecha_proy)
   return 0

select @w_fecha_hoy = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_procesa = 'N'
if exists (select 1 from ca_cambios_treferenciales,cobis..cl_catalogo with(nolock)
           where ct_fecha_ing = @w_fecha_hoy
           and ct_referencial = valor
           and tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_cambio_otras_tasas')
           )
begin           
   select @w_procesa = 'S'
end
else
begin
  return 0
end
---VERIFICACION EXISTENCIA CAMBIO

if exists (select 1
           from ca_rubro with (nolock),
                ca_valor_det,
                ca_cambios_treferenciales ,
                cobis..cl_catalogo with(nolock)
			where ru_tipo_rubro not in ('I','M','C')
			and  ru_referencial is not null 
			and ru_referencial = vd_tipo
			and vd_referencia is not null
			and ct_referencial = vd_referencia
			and ct_fecha_ing   = @w_fecha_hoy
			and  tabla  in (select codigo from cobis..cl_tabla
			                 where tabla = 'ca_cambio_otras_tasas')
			and  valor = vd_referencia 
			and codigo = ru_concepto
			and  @w_procesa = 'S'
)
begin
   select op_operacion,op_sector,ro_concepto,ro_referencial,ro_porcentaje,op_moneda
   into #Operaciones
   from ca_operacion with (nolock),
        ca_rubro_op   with (nolock)
   where op_estado in (0,99)
   and   ro_operacion = op_operacion
   and   ro_referencial is not null
   and   ro_tipo_rubro not in ('I','M','C')
end
else
begin
   return 0
end
      
declare cursor_rubros_recaltasvar cursor for 

select
ro_porcentaje, 
ro_referencial, 
ro_concepto,
ltrim(rtrim(vd_referencia)),
op_operacion,
op_sector,
isnull(ct_valor,0),
op_moneda
from #Operaciones,
    ca_valor_det,
    ca_cambios_treferenciales ,
    cobis..cl_catalogo with(nolock)
where ro_referencial = vd_tipo
and vd_referencia is not null
and ct_referencial = vd_referencia
and ct_fecha_ing   = @w_fecha_hoy
and  tabla  in (select codigo from cobis..cl_tabla
                 where tabla = 'ca_cambio_otras_tasas')
and  valor = vd_referencia 
and  codigo = ro_concepto
and  op_sector = vd_sector
and ro_porcentaje <> ct_valor

for read only

open   cursor_rubros_recaltasvar

fetch cursor_rubros_recaltasvar into

@w_ro_porcentaje,
@w_tasa_aplicar,  
@w_ro_concepto,
@w_referencial,
@w_operacionca,
@w_sector,
@w_tasa_base,
@w_moneda

while @@fetch_status = 0
begin

         if @w_tasa_base > 0 
         begin
           ---PRINT 'va  Oper ' + CAST (@w_operacionca as varchar)
           exec  sp_decimales
		   @i_moneda    = @w_moneda,
		   @o_decimales = @w_num_dec out

           select
           @w_signo 	= isnull(vd_signo_default, ''),
           @w_factor 	= isnull(vd_valor_default, 0),
           @w_clase	    = va_clase
           from ca_valor, ca_valor_det
           where va_tipo   = @w_tasa_aplicar
           and   vd_tipo   = @w_tasa_aplicar
           and   vd_sector = @w_sector

           if @w_clase = 'V'  --Tipo valor 
              select @w_nuevo_porcentaje = @w_tasa_base,
                     @w_factor = 0
           else 
           begin
              if @w_signo = '+'
	              select @w_nuevo_porcentaje = @w_tasa_base + @w_factor
      
              if @w_signo = '-'
             	  select @w_nuevo_porcentaje = @w_tasa_base - @w_factor
            
               if @w_signo = '/'
      	         select @w_nuevo_porcentaje = @w_tasa_base / @w_factor
            
               if @w_signo = '*'
      	         select @w_nuevo_porcentaje = @w_tasa_base * @w_factor
            end	

             
             update ca_amortizacion
             set  am_cuota = round(am_cuota *  @w_nuevo_porcentaje  / @w_ro_porcentaje,@w_num_dec)
             from ca_amortizacion
             where am_operacion = @w_operacionca
             and  am_concepto   =  @w_ro_concepto
             and  am_estado    = 0
             
             update ca_rubro_op
             set ro_porcentaje     =  @w_nuevo_porcentaje,
                 ro_porcentaje_efa =  @w_nuevo_porcentaje, 
                 ro_porcentaje_aux =  @w_nuevo_porcentaje,
                 ro_factor         =  @w_factor,
                 ro_signo          =  @w_signo

             where ro_operacion    =  @w_operacionca
             and ro_concepto       =  @w_ro_concepto


                select @w_concepto_asociado = ro_concepto,
                       @w_por_asociado      = ro_porcentaje
                from ca_rubro_op
                where ro_operacion = @w_operacionca
                and ro_concepto_asociado = @w_ro_concepto
                
                if @@rowcount > 0 ---RECALCULAR LOS IVAS DEL RUBRO
                begin
                     insert into ca_reproceso_asociados
                     select  am_operacion,am_dividendo,am_concepto,am_cuota,@w_concepto_asociado,0
                     from ca_amortizacion
                     where am_operacion = @w_operacionca
                     and   am_concepto  = @w_ro_concepto
                     and   am_estado   = 0

                     
                     update ca_reproceso_asociados
                     set valor_rubro_asociado = round(valor_rubro *  @w_por_asociado /100 ,@w_num_dec)
                     where operacion    = @w_operacionca
                     and rubro          = @w_ro_concepto
                     and rubro_asociado = @w_concepto_asociado
                     
                     update ca_amortizacion  
                     set am_cuota = valor_rubro_asociado
                     from  ca_amortizacion,
                           ca_reproceso_asociados
                     where am_operacion = @w_operacionca
                     and  am_concepto   =  @w_concepto_asociado
                     and am_operacion   = operacion
                     and am_dividendo   = dividendo
                     and  am_concepto   = rubro_asociado

                     set rowcount 1
                     select @w_base      = valor_rubro
                     from  ca_reproceso_asociados
                     where operacion    = @w_operacionca
                     and   rubro        = @w_ro_concepto
                     set rowcount 0
                     
                     update  ca_rubro_op
                     set     ro_base_calculo = @w_base 
                     where ro_operacion  = @w_operacionca
                     and   ro_concepto   = @w_concepto_asociado
                      
                     delete ca_reproceso_asociados
                     where operacion >= 0
                  
                end ---RECALCULAR LOS IVAS DEL RUBRO     

      end ---Proceo de actualizacion

   
 fetch   cursor_rubros_recaltasvar into
 
@w_ro_porcentaje,
@w_tasa_aplicar,  
@w_ro_concepto,
@w_referencial,
@w_operacionca,
@w_sector,
@w_tasa_base,
@w_moneda
 

end --WHILE CURSOR RUBROS
close cursor_rubros_recaltasvar
deallocate cursor_rubros_recaltasvar

return 0
go
