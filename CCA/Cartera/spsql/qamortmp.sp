/************************************************************************/
/*      Archivo:                qamortmp.sp                             */
/*      Stored procedure:       sp_qamortmp                             */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           R Garces                                */
/*      Fecha de escritura:     Jul. 1997                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Consulta una tabla de amortizacion temporal                     */
/************************************************************************/  


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_qamortmp')
   drop proc sp_qamortmp
go

create proc sp_qamortmp
@i_banco		        varchar(24),
@i_dividendo            int,
@i_formato_fecha        int      = null,
@i_concepto             varchar(10) = '',
@i_opcion               tinyint  = null,
@i_tipo_rubro           char(1)  = '',
@t_trn                  INT       = NULL
as
declare 
@w_error		        int ,
@w_return		        int ,
@w_operacionca          int ,
@w_sp_name		        varchar(64),
@w_count                int,
@w_filas                int,
@w_tipo_amortizacion    varchar(10),
@w_filas_rubros         int,
@w_primer_des           int,
@w_opcion_cap           char(1),
@w_num_bytes            smallint,
@w_buffer               int,
@w_num_cuotas           int

/* VARIABLES INICIALES */
select 
@w_sp_name = 'sp_qamortmp',
@w_buffer  = 2500    --TAMANIO DE BYTES MAXIMOS QUE SOPORTA EL BUFFER

/* DATOS GENERALES DEL PRESTAMO */
select 
@w_operacionca       = opt_operacion,
@w_tipo_amortizacion = opt_tipo_amortizacion,
@w_opcion_cap        = opt_opcion_cap
from   ca_operacion_tmp
where  opt_banco = @i_banco 


--print '@w_tipo_amortizacion...%1!',@w_tipo_amortizacion

/* SOLO PARA LA PRIMERA TRANSMISION */
if @i_dividendo = 0 
begin
   /**  TOTAL DE INTERES  **/
   select
   isnull(sum(rot_porcentaje) ,0)   --ESTO SE MAPEA ES PORCENTAJE INTERES
   from ca_rubro_op_tmp
   where rot_operacion  =  @w_operacionca
   and rot_tipo_rubro   =  'I'
   and rot_fpago        in ('P','A','T')

   select @w_opcion_cap /*PARA CONSIDERAR CAPITALIZACION*/

   if @w_opcion_cap is null
      select @w_num_bytes = 8 + 1
   else
      select @w_num_bytes = 1

   /* RUBROS QUE PARTICIPAN EN LA TABLA */
   select rot_concepto, co_descripcion, rot_tipo_rubro,rot_porcentaje
   from ca_rubro_op_tmp, ca_concepto
   where rot_operacion = @w_operacionca
   and rot_fpago in ('P','A', 'M','T')  /* XSA adiciono fpago = M 28/May/99 */
   and   rot_concepto = co_concepto
   and   rot_tipo_rubro <> @i_tipo_rubro 
   order by rot_concepto

   select @w_filas_rubros = @@rowcount

   /*OCULTAR COLUMNA DE SALDO DE CAPITAL */

   /*DIVIDENDOS EN LOS QUE SE HA HECHO DESEMBOLSO*/
   select @w_primer_des = min(dm_secuencial)
   from   ca_desembolso
   where  dm_operacion  = @w_operacionca

   select dtr_dividendo, convert(float, sum(dtr_monto)),'D' /*DESEMBOLSOS PARCIALES*/
   from   ca_det_trn, ca_transaccion, ca_rubro_op_tmp
   where  tr_banco      = @i_banco
   and    tr_secuencial = dtr_secuencial
   and    tr_operacion  = dtr_operacion
   and    dtr_secuencial <> @w_primer_des
   and    rot_operacion = @w_operacionca
   and    rot_tipo_rubro= 'C'
   and    tr_tran      = 'DES'
   and    tr_estado    in ('ING','CON')
   and    rot_concepto  = dtr_concepto
   group by dtr_dividendo
   union
   select dtr_dividendo, convert(float, sum(dtr_monto)),'R' /*REESTRUCTURACION*/
   from ca_det_trn, ca_transaccion, ca_rubro_op_tmp
   where  tr_banco      = @i_banco
   and   tr_secuencial = dtr_secuencial
   and   tr_operacion  = dtr_operacion
   and   rot_operacion = @w_operacionca
   and   rot_concepto  = dtr_concepto
   and   rot_tipo_rubro= 'C'
   and   tr_tran      = 'RES'
   and   tr_estado    in ('ING','CON')
   group by dtr_dividendo

   select @w_filas_rubros = @w_filas_rubros + @@rowcount

   select
   @w_num_cuotas = count(1)
   from ca_dividendo_tmp
   where dit_operacion = @w_operacionca
   and dit_dividendo > @i_dividendo 

   select
   dit_dias_cuota
   from ca_dividendo_tmp
   where dit_operacion = @w_operacionca
   and dit_dividendo > @i_dividendo 
   order by dit_dividendo
   
   select @w_num_bytes = @w_num_bytes + (@w_num_cuotas * 4) 
end

if @i_opcion = 0 begin   /*LAZO CON EL FRONT-END SOLO PARA DIVIDENDOS*/

/*   if @i_dividendo = 0
      select @w_count = (@w_buffer - (@w_filas_rubros*93+@w_num_bytes)) / 18
   else select @w_count = @w_buffer / 18

   if @w_count > 0
      set rowcount @w_count
   else
      set rowcount 0
*/

   /* FECHAS DE VENCIMIENTOS DE DIVIDENDOS */
   select  convert(varchar(10),dit_fecha_ven,@i_formato_fecha), -1 -- antes estaba -> convert(float, dit_max_pago)  pero el campo dit_max_pago se retiro de la tabla
   from ca_dividendo_tmp
   where dit_operacion = @w_operacionca
   and   dit_dividendo > @i_dividendo 
   order by dit_dividendo

   select @w_filas = @@rowcount

   select @w_count

end
else select @w_filas = 0,
            @w_count = 1

if @w_filas < @w_count  /*LAZO CON EL FRONT-END SOLO AMORTIZACION*/
begin

   /*TAMANIO EN BYTES PARA MAPEAR EL BUFFER*/ 
   select @w_count = (@w_buffer - @w_filas * 18)/20

   if @i_dividendo > 0 and @i_opcion = 0
      select @i_dividendo = 0
   
   if @w_count > 0
      set rowcount @w_count
   else
      set rowcount 0
 
   select  dit_dividendo,rot_concepto,convert(float, isnull(sum(amt_cuota+amt_gracia),0)) 
    from    ca_rubro_op_tmp
    inner join ca_dividendo_tmp on
                          (dit_dividendo > @i_dividendo  
                    or    (dit_dividendo = @i_dividendo
                    and   rot_concepto > @i_concepto))     
                    and   rot_operacion = @w_operacionca
                    and   rot_fpago    in ('P', 'A', 'M','T' )
                    and   rot_tipo_rubro <> @i_tipo_rubro
                    and   dit_operacion  = @w_operacionca      
 
        left outer join ca_amortizacion_tmp on 
                        rot_concepto = amt_concepto
                        and dit_dividendo = amt_dividendo
                        where amt_operacion = @w_operacionca
                 group by dit_dividendo,rot_concepto
                 order by dit_dividendo,rot_concepto

   select @w_count 
end

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',         @t_file = null,
@t_from =@w_sp_name,   @i_num = @w_error
--@i_cuenta= ' '

return @w_error
go