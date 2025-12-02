/************************************************************************/
/*   Archivo:              actllare.sp                                  */
/*   Stored procedure:     sp_actualizar_llave_red                      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Elcira Pelaez                                */
/*   Fecha de escritura:   Dic-2002                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*                               PROPOSITO                              */
/*   Procedimiento que realiza la actualizacion de la llave de          */
/*   redescuento en la ca_oepracion_his en el batch                     */
/*                                                                      */
/*                                 CAMBIOS                              */
/*   Xavier Maldonado         Cambios x Funcionalidad                   */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_actualizar_llave_red')
   drop proc sp_actualizar_llave_red
go

create proc sp_actualizar_llave_red
@s_date           datetime   = Null,
@s_user           login   = Null,
@t_debug          char(1)    = 'N',
@t_file           varchar(14)= Null,
@t_from           varchar(30)= Null,
@s_term           varchar(64)= Null,
@s_ssn            int   = Null,
@i_en_linea       char(1)   = Null,
@i_fecha_proceso  datetime

as 
declare 
   @w_error                int,   
   @w_return               int,
   @w_operacion_activa     int,
   @w_operacion_pasiva     int,
   @w_llave_antes          varchar(64),
   @w_llave_nueva          varchar(64),
   @w_commit               char(1),
   @w_oph_operacion        int,
   @w_llave_activa         cuenta,
   @w_llave_pasiva         cuenta,
   @w_sp_name              varchar(32)

-- CURSOR.No.1 ..
declare
   cursor_busca_llave cursor
   for select al_operacion_activa,  al_operacion_pasiva,  al_llave_antes, al_llave_nueva
       from   ca_actualiza_llave_tmp 
       where  al_fecha_act = @i_fecha_proceso
       and    al_estado    <> 'P'
   for read only

open  cursor_busca_llave
    
fetch cursor_busca_llave
into  @w_operacion_activa, @w_operacion_pasiva, @w_llave_antes, @w_llave_nueva

while @@fetch_status = 0   
begin
   if @@fetch_status = -1 
      return  70899 
   
   begin tran --atomicidad por registro
   
   select @w_commit = 'S'
   
   -- CURSOR.No.2 ..
   declare
      cursor_actualiza_llave cursor
      for select op_operacion
          from   ca_operacion
          where  op_operacion in (isnull(@w_operacion_activa,0), isnull(@w_operacion_pasiva,0))
      for read only
   
   open   cursor_actualiza_llave
   
   fetch cursor_actualiza_llave
   into  @w_oph_operacion
   
   while @@fetch_status = 0 
   begin
      if @@fetch_status = -1
         return  70899
      
      -- ACTUALIZACION DE LLAVE DE REDESCUENTO
      update ca_operacion_his
      set    oph_codigo_externo = @w_llave_nueva
      where  oph_operacion = @w_oph_operacion
      
      if @@error != 0 
      begin
         select @w_error = 710366
         
         close cursor_actualiza_llave
         deallocate cursor_actualiza_llave
         goto ERROR
      end
      
      fetch cursor_actualiza_llave
      into @w_oph_operacion
   end -- CURSOR_ACTUALIZA_LLAVE
   
   close cursor_actualiza_llave
   deallocate cursor_actualiza_llave
   
   commit tran     ---Fin de la transaccion
   select @w_commit = 'N'
   
   -- ACTUALIZACION EN LA TABLA ORIGINAL
   select @w_llave_activa = ''
   
   select @w_llave_activa = op_codigo_externo
   from   ca_operacion
   where  op_operacion = @w_operacion_activa
   
   if (@w_llave_activa <> '') and (@w_llave_activa <> @w_llave_nueva) 
   begin
      update ca_operacion         
      set    op_codigo_externo = @w_llave_nueva
      where  op_operacion      = @w_operacion_activa
   end
   
   select @w_llave_pasiva = ''
   
   select @w_llave_pasiva = op_codigo_externo
   from   ca_operacion
   where  op_operacion = @w_operacion_pasiva
   
   if ( @w_llave_pasiva <> '' ) and  ( @w_llave_pasiva <> @w_llave_nueva)
   begin
      update ca_operacion            
      set    op_codigo_externo = @w_llave_nueva
      where  op_operacion = @w_operacion_pasiva
   end
   
   goto SIGUIENTE
   
   ERROR:
   rollback  
   if @i_en_linea = 'S'
      return @w_error
   else
   begin                                         
      exec sp_errorlog                                             
           @i_fecha         = @s_date,
           @i_error         = @w_error,
           @i_usuario       = @s_user,
           @i_tran          = 7000, 
           @i_tran_name     = @w_sp_name,
           @i_rollback      = 'S',  
           @i_cuenta        = @w_llave_nueva,
           @i_descripcion   = 'ACTUALIZACION LLAVE REDESCUENTO'
      goto SIGUIENTE
   end
   
   SIGUIENTE:
   fetch cursor_busca_llave
   into @w_operacion_activa, @w_operacion_pasiva, @w_llave_antes, @w_llave_nueva
end -- CURSOR_BUSCA_LLAVE

--ACTUALIZAR LA TABLA
update ca_actualiza_llave_tmp 
set    al_estado = 'P'
where  al_fecha_act = @i_fecha_proceso

close cursor_busca_llave                                           
deallocate cursor_busca_llave                               

return 0
go

