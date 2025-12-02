/************************************************************************/
/*   Archivo:              caclient.sp                                  */
/*   Stored procedure:     sp_cambio_cliente_cca                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Ene. 2005                                    */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Cambio de cliente en cartera -credito y cl_cliente                 */
/*                            MODIFICACIONES                            */
/*                                                                      */
/************************************************************************/

use cob_cartera
go



if exists(select 1 from sysobjects where name = 'sp_cambio_cliente_cca')
   drop proc sp_cambio_cliente_cca
go

create proc sp_cambio_cliente_cca
@i_cliente_antes        int,
@i_cliente_nuevo        int

as

declare @w_cedula_antes     numero,
        @w_cedula_nueva     numero,
        @w_nombre_nuevo     descripcion

select getdate()
        
PRINT 'Validacion de existencia cliente  Viejo Antes del Cambio'
select op_cliente,op_banco,op_fecha_ult_proceso,op_nombre
from ca_operacion
where op_cliente = @i_cliente_antes

if not exists (select 1 from  cobis..cl_ente
where en_ente = @i_cliente_nuevo)
begin
      PRINT 'ATENCIOONNNNNNNNN cliente nuevo no existe ' + cast(@i_cliente_nuevo as varchar)
      return 0
end



   ---SACAR EL NUEVO NOMBRE

   select @w_nombre_nuevo = en_nomlar,
          @w_cedula_nueva = en_ced_ruc
   from cobis..cl_ente
   where en_ente = @i_cliente_nuevo
   
   --SACAR LA CEDUAL ANTERIOR
   select @w_cedula_antes = en_ced_ruc
   from cobis..cl_ente
   where en_ente = @i_cliente_antes
   
   PRINT 'Credito'
   
   update cob_credito..cr_dato_operacion
   set  do_codigo_cliente = @i_cliente_nuevo
   where do_tipo_reg in ('M','D')
   and   do_codigo_cliente = @i_cliente_antes
   and   do_codigo_producto = 7
   
   
   update cob_credito..cr_tramite
   set tr_cliente = @i_cliente_nuevo
   where tr_cliente = @i_cliente_antes
   
   
   update cob_credito..cr_deudores
   set   de_cliente = @i_cliente_nuevo,
         de_ced_ruc =  @w_cedula_nueva
   where de_cliente = @i_cliente_antes
   and   de_rol     = 'D'
   
   
   update  cob_credito..cr_calificacion_op 
   set co_cod_cliente = @i_cliente_nuevo
   where co_producto = 7
   and  co_cod_cliente = @i_cliente_antes
      
   if not exists (select 1 from cob_credito..cr_calificacion_cl
                where cl_cod_cliente = @i_cliente_nuevo)
   begin
      update  cob_credito..cr_calificacion_cl
      set cl_cod_cliente = @i_cliente_nuevo,
          cl_id_cliente = @w_cedula_nueva
      where cl_cod_cliente = @i_cliente_antes
   end
   
   update cob_credito..cr_calificaciones_cl
   set cl_cod_cliente = @i_cliente_nuevo
   where cl_cod_cliente = @i_cliente_antes
   
   
   
   update cob_credito..cr_calificacion_op_rep
   set co_cod_cliente = @i_cliente_nuevo
   where co_producto = 7
   and   co_cod_cliente = @i_cliente_antes
      
   if not exists (select 1  from   cob_credito..cr_calificacion_cl_rep
   where cl_cod_cliente = @i_cliente_nuevo)
   begin
      update  cob_credito..cr_calificacion_cl_rep
      set cl_cod_cliente = @i_cliente_nuevo,
          cl_id_cliente  = @w_cedula_nueva
      where cl_cod_cliente = @i_cliente_antes
   end
   
      
   PRINT 'Cobis'
   select getdate()
   
   update cobis..cl_cliente
   set cl_ced_ruc = @w_cedula_nueva,
       cl_cliente =  @i_cliente_nuevo
   from cobis..cl_cliente,
        cobis..cl_det_producto
   where cl_cliente = @i_cliente_antes
   and   cl_cliente = dp_cliente_ec
   and   cl_det_producto = dp_det_producto
   and   cl_rol          = 'D'
   and  dp_producto in(7,21) 

      
   update   cobis..cl_det_producto
   set dp_cliente_ec = @i_cliente_nuevo
   where dp_producto  in(7,21)
   and   dp_tipo      = 'R'
   and   dp_moneda    in (0,2,1)
   and   dp_cliente_ec = @i_cliente_antes
   
   
   PRINT 'Cob_cartera'
   select getdate()
   
   update cob_cartera..ca_operacion
   set op_cliente = @i_cliente_nuevo,
       op_nombre  = @w_nombre_nuevo
   where op_cliente = @i_cliente_antes
   
   update cob_cartera..ca_operacion_his
   set oph_cliente = @i_cliente_nuevo,
       oph_nombre  = @w_nombre_nuevo
   where oph_cliente = @i_cliente_antes
   
    update cob_cartera_his..ca_operacion_his
   set oph_cliente = @i_cliente_nuevo,
       oph_nombre  = @w_nombre_nuevo
   where oph_cliente = @i_cliente_antes
     
   
   update cob_cartera..ca_maestro_operaciones
   set mo_nombre_cliente = @w_nombre_nuevo,
       mo_cliente        = @i_cliente_nuevo
   where mo_cliente  = @i_cliente_antes
   
   PRINT 'cob_compensacion para las fechas respaldadas'

   
   update  cob_compensacion..cr_dato_operacion_rep
   set do_codigo_cliente = @i_cliente_nuevo
   where do_fecha >= '03/01/2004'
   and   do_tipo_reg = 'M'
   and   do_codigo_producto = 7
   and   do_codigo_cliente =  @i_cliente_antes

PRINT 'Fin de Procesar'

select getdate()

PRINT 'Validacion de existencia cliente Despues del Cambio'
select op_cliente,op_banco,op_fecha_ult_proceso,op_nombre
from ca_operacion
where op_cliente = @i_cliente_nuevo
   
return 0

go