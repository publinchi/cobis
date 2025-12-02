/************************************************************************/
/*      Archivo:                ca_quitactas.sp                         */
/*      Stored procedure:       sp_quita_relacion_ctas                  */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez Burbano                   */
/*      Fecha de escritura:     Abr 2012                                */
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
/*      Quta la relaciondelas cuentas de ahorros,de las operaciones     */
/*      segun parametros de Entrada                                     */
/************************************************************************/

use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_quita_relacion_ctas')
   drop proc sp_quita_relacion_ctas
go

---SEP.17.2012

create proc sp_quita_relacion_ctas
   @i_param1  varchar(10),  ---Producto 4 AHO   y 3 CTES
   @i_param2  varchar(10)   ---I Ingresadas C = Canceladas T = Ambas Cancelada e Inactivas
   
as

declare 
@w_producto           smallint,
@w_estado_cta         char(1),
@w_fecha              datetime

---Asignacion de variables

select @w_fecha = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_producto    = @i_param1,
       @w_estado_cta  = @i_param2

---ELiminar registros  qe se desen volver a cargar       
if exists (select 1 from  ca_ctas_no_relaciondas
           where fecha    = @w_fecha 
           and   producto = @w_producto
           and   estado   = @w_estado_cta)
begin
  PRINT 'ATENCION !!!! fecha, producto y estado ya seproceso'
  goto ERROR
end           

if @w_producto = 4 and (@w_estado_cta  <> 'T' and  @w_estado_cta <> 'I' and @w_estado_cta <> 'C')
begin
  PRINT 'ATENCION!!!!! revisar estado enviado No es Valido para el producto de AHORROS'
  goto ERROR
end       

if @w_producto = 4   --producto CUENTA DE AHORROS
begin
   if 'S' = (select pa_char from cobis..cl_parametro where pa_nemonico = 'VALAHO' and pa_producto = 'CCA')
   begin --inicio  existe validacion con cobis-ahorros
       exec cob_interface..sp_verifica_cuenta_aho
            @i_operacion  = 'VAHO5',
            @i_producto   = @w_producto,
            @i_fecha      = @w_fecha,
            @i_estado_cta = 'T'
       if @w_estado_cta = 'T'
       begin
         insert into ca_ctas_no_relaciondas
         select @w_fecha ,getdate(),op_operacion,op_banco,op_cuenta,ah_estado,op_forma_pago,@w_producto
         from cob_cartera..ca_operacion with (nolock),
              cob_ahorros..ah_cuenta with(nolock)
         where op_cliente  = ah_cliente
         and   op_cuenta   = ah_cta_banco
         and   ah_producto = @w_producto
         and   ah_estado   in ('C','I') --Ambas a la vez
         and   op_estado in (1,2,4,9)
      end
      else
      begin
         insert into ca_ctas_no_relaciondas
         select @w_fecha ,getdate(),op_operacion,op_banco,op_cuenta,ah_estado,op_forma_pago,@w_producto
         from cob_cartera..ca_operacion with (nolock),
              cob_ahorros..ah_cuenta with(nolock)
         where op_cliente  = ah_cliente
         and   op_cuenta   = ah_cta_banco
         and   ah_producto = @w_producto
         and   ah_estado   = @w_estado_cta  ---puede ser 'I' o 'C'
         and   op_estado in (1,2,4,9)
      end
   end
end
ELSE 
begin
	if @w_producto = 3
	begin
		exec cob_interface..sp_verifica_cuenta_aho
               @i_operacion  = 'VAHO5',
               @i_producto   = @w_producto,
               @i_fecha      = @w_fecha
	end
end
---Quitar la relacion de la tabla ca_operacion
update ca_operacion
set op_cuenta = null,
    op_forma_pago = null
from ca_operacion ,
     ca_ctas_no_relaciondas
where operacion = op_operacion
and    fecha = @w_fecha

update ca_operacion_his
set oph_cuenta = null,
    oph_forma_pago = null
from ca_operacion_his ,
     ca_ctas_no_relaciondas
where operacion = oph_operacion
and    fecha = @w_fecha


select top 20 * from ca_ctas_no_relaciondas
where fecha = @w_fecha
     
ERROR:

return 0
   
go



