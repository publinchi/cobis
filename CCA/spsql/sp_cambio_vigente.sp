/************************************************************************/
/*   Archivo:                pagosost.sp                                */
/*   Stored procedure:       sp_cambio_est_vig                          */
/*   Base de datos:          cob_cartera                                */
/*   Producto:               Cartera                                    */
/*   Disenado por:           Ignacio Yupa                               */
/*   Fecha de escritura:     01/Mar./2017                               */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP S.A.'.                                                  */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP S.A. o su representante.        */
/************************************************************************/  
/*                            PROPOSITO                                 */
/*   Consulta de los datos de una operacion                             */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*   FECHA               AUTOR           CAMBIO                         */
/*   01/Mar./2017        Ignacio Yupa    Emision Inicial                */
/************************************************************************/

use cob_cartera
go

set ansi_nulls off
go
 
if exists (select 1 from sysobjects where name = 'sp_cambio_est_vig')
   drop proc sp_cambio_est_vig
go

create proc sp_cambio_est_vig (
 @i_param1      int          = null -- operacion
)
as
declare 
   @w_return              int,
   @w_error               int,
   @w_est_vencido         tinyint,
   @w_operacion           int,
   @w_fecha               datetime,
   @w_mensaje             varchar(100),
   @w_psostenido          char(1)
   
   select @w_fecha = getdate()
 
 
 /* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_vencido    = @w_est_vencido    out

 if @i_param1 is null or @i_param1 = '' or @i_param1 = 0
 begin
      declare cursor_oper_venc cursor for
            SELECT op_operacion
            FROM ca_operacion 
            WHERE op_estado = @w_est_vencido
            
      open cursor_oper_venc
      fetch cursor_oper_venc into @w_operacion
      
      if @@fetch_status = -2
      begin
      
            close cursor_oper_venc
            deallocate cursor_oper_venc
            select @w_mensaje = 'HUBO ERROR EN LA LECTURA DE LOS REGISTROS'
            goto ERRORFIN 
      end

      if @@fetch_status = -1
      begin
            close cursor_oper_venc
            deallocate cursor_oper_venc
            return 0
      end

      while @@fetch_status = 0
      begin
      
      exec @w_error = cob_cartera..sp_cambio_estado_vigente
         @i_operacionca = @w_operacion,
         @s_user = 'usrbatch',
         @s_term = 'consola'
         
      if @w_error <> 0 
      begin
            SELECT @w_mensaje = 'HUBO ERROR EN LA EJECUCION DEL SP DE PAGO SOSTENIDO'
            goto ERRORFIN
      end
      
       fetch cursor_oper_venc into @w_operacion
            if @@fetch_status = -2
            begin
               close cursor_cr_opcns
               deallocate cursor_cr_opcns
               SELECT @w_mensaje = 'HUBO ERROR EN LA LECTURA DE LOS REGISTROS'
               goto ERRORFIN
            end                                
      end --While

 end
 else
 begin
      exec @w_error = cob_cartera..sp_cambio_estado_vigente
         @i_operacionca = @i_param1,
         @s_user = 'usrbatch',
         @s_term = 'consola'
         
      if @w_error <> 0 
      begin
            SELECT @w_mensaje = 'HUBO ERROR EN LA EJECUCION DEL SP DE PAGO SOSTENIDO'
            goto ERRORFIN
      end
            
 end
 
 return 0
 
 ERRORFIN:

   exec cob_cartera..sp_errorlog
    @i_fecha       = @w_fecha,
    @i_error       = @w_error,
    @i_usuario     = 'usrbatch',
    @i_tran_name   = @w_mensaje,
    @i_rollback    = 'N',
    @i_tran        = null,
    @i_descripcion = @w_mensaje


  return @w_error
go

