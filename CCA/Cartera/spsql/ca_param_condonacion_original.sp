/************************************************************************/
/*      Archivo:                ca_param_condonacion_original.sp        */
/*      Script :                sp_param_condonacion_original.sp        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Fecha de escritura:     Noviembre 2013                          */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/* Toma las tablas ca_param_condona_COPY y ca_rol_condona_COPY          */
/* y pasa a las definitivas.                                            */ 
/* (Una vez se finalice el proceso de venta de cartera)                 */                                                     
/************************************************************************/
/*                              CAMBIOS                                 */
/*  FECHA     AUTOR             RAZON                                   */
/*  12-16-13  L.Guzman          Emisión Inicial                         */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_param_condonacion_original')
   drop proc sp_param_condonacion_original
go

create proc sp_param_condonacion_original

as
declare 
@w_msg           varchar(255),
@w_error         int,
@w_fecha_proceso datetime,
@w_sp_name       varchar(255)

if exists (select 1 from sysobjects where name = 'ca_param_condona_COPY')
begin
   if exists (select 1 from ca_param_condona_COPY)
   begin
      
      delete  ca_param_condona WHERE pc_codigo >= 0
      

      if @@error <> 0
      begin
         select @w_msg = 'Error al eliminar parametria en ca_param_condona',
                @w_error = 708155
         goto ERROR
      end
      
      insert into ca_param_condona select * from ca_param_condona_COPY      
      
      if @@error <> 0
      begin
         select @w_msg = 'Error al insertar parametria en ca_param_condona',
                @w_error = 708154
         goto ERROR
      end
   end          
end

if exists (select 1 from sysobjects where name = 'ca_rol_condona_COPY')
begin
   if exists (select 1 from ca_rol_condona_COPY)
   begin
      delete  ca_rol_condona WHERE rc_rol >= 0
      
      if @@error <> 0
      begin
         select @w_msg = 'Error al eliminar parametria en ca_param_condona',
                @w_error = 708155
         goto ERROR
      end

      insert into ca_rol_condona select * from  ca_rol_condona_COPY
      
      if @@error <> 0
      begin
         select @w_msg = 'Error al insertar parametria en ca_rol_condona',
                @w_error = 708154
         goto ERROR
      end      
   end   
end

return 0

ERROR:
exec cob_cartera..sp_errorlog 
@i_fecha       = @w_fecha_proceso,
@i_error       = @w_error, 
@i_usuario     = 'OPERADOR', 
@i_tran        = null,
@i_tran_name   = @w_sp_name,
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return @w_error

go



