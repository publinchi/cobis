/************************************************************************/
/*      Archivo:                mensajecontraofer.sp                    */
/*      Stored procedure:       sp_mensaje_contraoferta                 */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Credito y Cartera                       */
/*      Disenado por:           Henry Muñoz                             */
/*      Fecha de escritura:     11/2011                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*								                                     	*/
/************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_mensaje_contraoferta')
   drop proc sp_mensaje_contraoferta
go

create proc sp_mensaje_contraoferta(
@s_date            datetime     =null,
@i_banca           int          ,
@i_evento          char(3)      ,
@i_fecha           datetime     ,   
@o_mensaje_mat     descripcion   out,
@o_msg             descripcion   out) 
as declare
@w_sp_name         varchar(30),
@w_commit          char(1),  
@w_msg             varchar (255),
@w_error           int,
@w_matriz          catalogo,
@w_valor           int,
@w_return          int,
@w_mat             catalogo,
@w_fecha           datetime,
@w_evento          int,
@w_valor_ret       float,
@w_banca           int,
@w_estado_men      char(1)


/*INICIALIZO VARIABLES*/

select @w_matriz = ma_matriz                  
from ca_matriz    
where ma_matriz = 'MSGCONPRES'   

exec  @w_error = sp_matriz_valor 
@i_matriz    =@w_matriz  ,
@i_fecha_vig =@i_fecha   ,
@i_eje1      =@i_banca   ,
@i_eje2      =@i_evento  ,
@o_valor     =@w_valor_ret out,
@o_msg       =@o_msg out

if @w_error <> 0 return @w_error

select @w_estado_men = estado 
from cobis..cl_catalogo x, cobis..cl_tabla y 
where x.tabla = y.codigo 
and y.tabla ='cl_mensaje_contraofertas'
and x.codigo = @w_valor_ret

if @w_estado_men <> 'V'begin
   select 
   @w_error = 1,
   @w_msg = 'El mensaje No esta Vigente'
end
else begin 
   select @o_mensaje_mat= valor 
   from cobis..cl_catalogo x, cobis..cl_tabla y 
   where x.tabla = y.codigo 
   and y.tabla ='cl_mensaje_contraofertas'
   and x.codigo = @w_valor_ret 
end

return  0

go
  

             