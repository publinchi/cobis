/************************************************************************/
/*   Archivo            :    actrubro.sp                                */
/*   Stored procedure   :    sp_actualiza_rubros                        */
/*   Base de datos      :    cob_cartera                                */
/*   Producto           :    Cartera                                    */
/*   Disenado por       :    Diego Aguilar                              */
/*   Fecha de escritura :    Mayo /99                                   */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Procedimiento interno para recalcular el ro_porcentaje de los      */
/*      rubros tipo interes con la tasa equivalente en modalidad y pe-  */
/*      riodicidad actual de la operacion                               */
/*                      CAMBIOS                                         */
/*      FECHA           AUTOR               MODIFICACION                */
/*      11/18/2005   ElciraPelaez Manejo del programa tasaactu.sp       */
/*                                       desdeeste sp                   */
/*      22/05/2017   Jorge Salazar         CGS-S112643                  */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualiza_rubros')
   drop proc sp_actualiza_rubros
go

create proc sp_actualiza_rubros(
        @i_operacionca       int      = null,
        @i_tipo_rubro        char(1)  = 'I',
        @i_crear_op          char(1)  = 'N',
        @i_tasa              float    = null --JSA Santander
)
as
declare
@w_sp_name            descripcion,
@w_return             int,
@w_concepto           catalogo,
@w_tipo               char(1),
@w_convierte_tasa     char(1),
@w_fecha_ini          datetime,
@w_porcentaje         float,
@w_porcentaje_efa     float,
@w_tasa_referencial   catalogo,
@w_fecha              datetime,
@w_valor_tasa_ref     float,
@w_fecha_tasaref      datetime,
@w_ts_tasa_ref        catalogo,
@w_valor_aplicar      catalogo


--- Captura nombre de Stored Procedure
select   @w_sp_name = 'sp_actualiza_rubros'


if @i_tipo_rubro not in ('I','M')
   return 0


select
@w_tipo              = opt_tipo,
@w_convierte_tasa    = opt_convierte_tasa,
@w_fecha_ini         = opt_fecha_ini
from ca_operacion_tmp
where opt_operacion   = @i_operacionca


if @w_tipo = 'D'
   return 0


declare rubros_op cursor for
select  rot_concepto,
        rot_referencial

from  ca_rubro_op_tmp
where rot_operacion  = @i_operacionca
and   rot_fpago     in ('P','A','T')
and   rot_tipo_rubro = @i_tipo_rubro
and   rot_referencial is not null  --SOLO SI TIENE UN VALOR A APLICAR
order by rot_concepto
for read only

open rubros_op

fetch rubros_op into
   @w_concepto,
   @w_valor_aplicar

while (@@fetch_status = 0)
begin
    if (@@fetch_status <> 0)
	begin
	    close rubros_op
        deallocate rubros_op
        return 710124
	end



      if @w_convierte_tasa = 'S'
      begin
           ---print'actrubro.sp @w_valor_aplicar ' + cast(@w_valor_aplicar as varchar) + ' @w_concepto : ' + cast(@w_concepto as varchar) + '  @w_fecha_ini: ' + cast( @w_fecha_ini as varchar)

            exec @w_return            = sp_tasas_actuales
                 @i_operacionca       =  @i_operacionca,
                 @i_referencia        =  @w_valor_aplicar,
                 @i_concepto          =  @w_concepto,
                 @i_reajuste          =  'N',
                 @i_temporales        =  'S',
                 @i_fecha_proceso     =  @w_fecha_ini,
                 @o_tasa_nom          =  @w_porcentaje output,
                 @o_tasa_efa          =  @w_porcentaje_efa output,
                 @o_valor_tasa_ref    =  @w_valor_tasa_ref output,
                 @o_fecha_tasa_ref    =  @w_fecha_tasaref  output,
                 @o_ts_tasa_ref       =  @w_ts_tasa_ref output

            if @w_return <> 0
             begin
               --print 'actrubro.sp salio por aqui'
               return @w_return
             end
            else
            begin

               if @w_concepto = 'INT' -- JSA Santander
                  select @w_porcentaje = isnull(@i_tasa, @w_porcentaje),
                         @w_porcentaje_efa = isnull(@i_tasa, @w_porcentaje)
               
               update ca_rubro_op_tmp with (rowlock)  set
               rot_porcentaje     = @w_porcentaje,        
               rot_porcentaje_efa = @w_porcentaje_efa,     
               rot_porcentaje_aux = @w_porcentaje_efa, 
               rot_valor = 0
               where rot_operacion = @i_operacionca
               and   rot_concepto  = @w_concepto

               if @@error <> 0 return 705006
            end
         end  --convertir tasa

 fetch rubros_op into
   @w_concepto,
   @w_valor_aplicar
end

close rubros_op
deallocate rubros_op

return 0

go

