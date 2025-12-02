/************************************************************************/
/*	Archivo:		        actnom.sp        			                        */
/*	Stored procedure:	  sp_ca_actualiza_cliente                          */
/*	Base de datos:		  cob_cartera                                      */
/*	Producto: 		     Cartera                                          */
/*	Disenado por:  		Xavier Maldonado                                */
/*	Fecha de escritura:	Agost 2000                                      */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*	Este programa es parte de los paquetes bancarios propiedad de	      */
/*	'MACOSA'.                                                            */
/*	Su uso no autorizado queda expresamente prohibido asi como           */
/*	cualquier alteracion o agregado hecho por alguno de sus              */
/*	usuarios sin el debido consentimiento por escrito de la              */
/*	Presidencia Ejecutiva de MACOSA o su representante.                  */
/*                              PROPOSITO	                              */
/*	                                                                     */ 
/*	I: Actualiza el nombre del cliente desde un proceso del Mis          */
/************************************************************************/
/*	                             MODIFICACIONES                          */
/*	    FECHA		   AUTOR		     RAZON                                */
/*	Agosto 2000    X. Maldonado     Emision Inicial                      */
/* octubre 2004   Elcira Pelaez    Mejoras para el BAC                  */
/* agosto  2005   Elcira Pelaez    Actualizacion directa de cartera     */
/* junio   2006   Elcira Pelaez    Actualizacion segun lo almacenado en */
/*                                 la tabla ..... por el trigger        */
/*                                 def. 6749                            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ca_actualiza_cliente')
	drop proc sp_ca_actualiza_cliente
go

create proc sp_ca_actualiza_cliente(
        @i_fecha		datetime = null)
as

declare @w_sp_name		descripcion,
        @w_cliente_act  int


-- NOMBRE DEL SP Y FECHA DE HOY 
select	@w_sp_name = 'sp_ca_actualiza_cliente'

if @i_fecha is null
begin
   select @i_fecha = fc_fecha_cierre
   from cobis..ba_fecha_cierre
   where fc_producto = 7
end

declare cursor_actnombre cursor
for 
select ca_cliente
from cob_cartera..ca_clientes_actualizados
where ca_fecha >= @i_fecha
and   ca_estado = 'I'
  
for read only
   
open  cursor_actnombre

fetch cursor_actnombre
into  @w_cliente_act

--while @@fetch_status not in (-1,0)
while @@fetch_status = 0
begin 

      BEGIN TRAN
      
      update cob_cartera..ca_operacion
      set op_nombre = en_nomlar
      from cobis..cl_ente
      where en_ente = @w_cliente_act
      and   op_cliente = @w_cliente_act
      
       if @@error <> 0 
        begin
         insert into ca_errorlog
            (er_fecha_proc,      er_error,      er_usuario,
             er_tran,            er_cuenta,     er_descripcion,
             er_anexo)
         values(@i_fecha,       705068,          'operador',
             @w_cliente_act,    '',       'NO SE ACTUALIZO EL CLIENTE',
             ''
             ) 
        end
        else
        begin
         update  cob_cartera..ca_clientes_actualizados
          set ca_estado = 'P'
          where ca_cliente = @w_cliente_act
        end
 
      COMMIT TRAN

   fetch cursor_actnombre
   into  @w_cliente_act

end

close cursor_actnombre
deallocate cursor_actnombre

return 0

go


