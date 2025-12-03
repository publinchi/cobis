/************************************************************************/
/*   Archivo            :        renautoriza.sp                         */
/*   Stored procedure   :        sp_ren_autoriza                        */
/*   Base de datos      :        cob_cartera                            */
/*   Producto           :        Cartera                                */
/*   Disenado por                Ivan Jimenez                           */
/*   Fecha de escritura :        Agosto 14 de 2006                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Consulta para front end de renovaciones                            */
/************************************************************************/
/*                            MODIFICACIONES                            */
/*       Ago/14/2006    Ivan Jimenez      Emision inicial               */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ren_autoriza')
   drop proc sp_ren_autoriza

go

create proc sp_ren_autoriza(
   @s_user                 login    = null,
   @s_date                 datetime = null,
   @s_term                 varchar(30), 
   @s_ofi                  smallint,
   @t_trn                  int,
   @i_tramite              int,
   @i_usuario              login
)
as
declare
   @w_sp_name        descripcion,
   @w_error          int,
   @w_mensaje        varchar(132)
begin
	select @w_sp_name = 'sp_ren_autoriza'
	
	BEGIN TRAN
	
   insert into ca_ren_autorizada
         (ra_tramite,   ra_fecha_sistema,    ra_fecha_real, 
          ra_terminal,  ra_oficina,				ra_usuario)
   values(@i_tramite,   @s_date, getdate(),
          @s_term,      @s_ofi,  @i_usuario)
   
   if @@error != 0 
   begin
      select @w_error = @@error,
             @w_mensaje = 'Error Al Insertar en Tabla de Autorizacion de Renovación'
		ROLLBACK
      goto ERROR
   end 
   
   COMMIT TRAN
   return 0
end

ERROR:
   exec cobis..sp_cerror
        @t_debug  = 'N',    
        @t_file   =  null,
        @t_from   =  @w_sp_name,
        @i_num    =  @w_error,
        @i_msg    =  @w_mensaje
   return   @w_error
Go
