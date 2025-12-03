/************************************************************************/
/*   Archivo:                 eliintegrup.sp                            */
/*   Stored procedure:        sp_eliminacion_integrante_grupo           */
/*   Base de Datos:           cob_cartera                               */
/*   Producto:                Cartera                                   */
/*   Disenado por:            Edison Cajas M.                           */
/*   Fecha de Documentacion:  Julio. 2019                               */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier autorizacion o agregado hecho por alguno de sus          */
/*   usuario sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante                 */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Programa para indicar si se puede o no eliminar a un integrante de */
/*   un grupo                                                           */
/************************************************************************/ 
/*                              MODIFICACIONES                          */ 
/*      FECHA           AUTOR           RAZON                           */
/*   22/Jul/2019   Edison Cajas.   Emision Inicial                      */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_eliminacion_integrante_grupo')
    drop proc sp_eliminacion_integrante_grupo
go

create proc sp_eliminacion_integrante_grupo
(
   @i_grupo    int,
   @i_cliente  int,
   @o_retorno  int           out,
   @o_mensaje  varchar(255)  out
)
as

declare 
     @w_sp_name             descripcion   ,@w_error              int
	 
select @w_sp_name = 'sp_eliminacion_integrante_grupo'
select @o_retorno = 0

if exists(select 1 from ca_operacion where op_cliente = @i_cliente and op_grupo = @i_grupo and op_estado not in (0,3,6,99))
begin
   print 'No se puede eliminar integrante de un grupo'
   select @w_error = 725059
   select @o_mensaje = mensaje, @o_retorno = @w_error from cobis..cl_errores where numero = @w_error	
   goto ERROR
end

if exists(select 1 from ca_operacion where op_cliente = @i_cliente and op_grupo = @i_grupo and op_estado = 0
          and op_ref_grupal in (select op_banco from ca_operacion where op_estado not in (0,3,6,99)))
begin 
   print 'No se puede eliminar integrante de un grupo'
   select @w_error = 725059
   select @o_mensaje = mensaje, @o_retorno = @w_error from cobis..cl_errores where numero = @w_error	
   goto ERROR
end 

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',
        @t_file   = null, 
        @t_from   = @w_sp_name,
        @i_num    = @w_error
	  
return 1

go
