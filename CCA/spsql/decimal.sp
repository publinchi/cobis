/************************************************************************/
/*  Archivo:            decimal.sp                                      */
/*  Stored procedure:   sp_decimales                                    */
/*  Base de datos:      cob_cartera                                     */
/*  Producto:           Cartera                                         */
/*  Disenado por:       R Garces                                        */
/*  Fecha de escritura: Jul. 1997                                       */
/************************************************************************/
/*                            IMPORTANTE                                */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  
/*                           PROPOSITO                                  */
/*  Retorna el numero de decimales de una moneda dada y el codigo de    */
/*  la moneda nacional                                                  */
/*                         MODIFICACIONES                               */
/*  XSA (GRUPO CONTEXT)	06/May/1999	      Manejo de decimales para      */
/*                                        moneda IPC.                   */
/*  EPB                 26/jul/2001       Decimales otras monedas       */
/*                                        NDOM                          */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_decimales')
	drop proc sp_decimales
go
create proc sp_decimales
   @i_moneda               tinyint,
   @o_decimales            tinyint out,
   @o_mon_nacional         tinyint          = null out,
   @o_dec_nacional         tinyint          = null out
   
   as
   declare
   
   @w_sp_name               descripcion,
   @w_error                 int,
   @w_decimales             char(1),
   @w_ipc                   tinyint

   select @w_sp_name = 'sp_decimales'

   /* MANEJO DE MONEDA IPC XSA */

   select @w_ipc      = pa_tinyint
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'IPC'
   
   if @@rowcount = 0
   begin
      select @w_error = 101254 
      goto ERROR
   end
   
   set transaction isolation level read uncommitted

   select @o_mon_nacional = pa_tinyint
   from   cobis..cl_parametro
   where  pa_producto     = 'ADM'
   and    pa_nemonico     = 'MLO'
   
   if @@rowcount = 0
   begin
      select @w_error = 101254 
      goto ERROR
   end
   
   set transaction isolation level read uncommitted

   select @w_decimales = mo_decimales
   from   cobis..cl_moneda
   where  mo_moneda    = @i_moneda

   if @w_decimales = 'S'
   begin
      if @i_moneda <> @w_ipc
      begin
         select @o_decimales = pa_tinyint
         from   cobis..cl_parametro
         where  pa_producto  = 'CCA'
         and    pa_nemonico  = 'NDE'
         
         if @@rowcount = 0
   	     begin
   	        select @w_error = 708130
            --print @o_decimales       
   	        goto ERROR
   	     end  

         set transaction isolation level read uncommitted       
      end
	  else
      begin
         select @o_decimales = pa_tinyint
         from   cobis..cl_parametro
         where  pa_producto  = 'CCA'
         and    pa_nemonico  = 'NDEIPC'
         
         if @@rowcount = 0
   	     begin
   	        select @w_error = 708130
            --print @o_decimales       
   	        goto ERROR
   	     end

         set transaction isolation level read uncommitted
      end

      /* DECIMALES PARA OTRAS MONEDAS DIFERENTES A MONEDA LOCAL */
      if @i_moneda <> @o_mon_nacional 
      begin
         select @o_decimales = pa_tinyint
         from   cobis..cl_parametro
         where  pa_producto  = 'CCA'
         and    pa_nemonico  = 'NDEOM'

         if @@rowcount = 0
         begin
            select @w_error = 708130
            goto ERROR
         end

         set transaction isolation level read uncommitted
         
      end
   end
   else
      select @o_decimales = 0 

   select @w_decimales = mo_decimales
   from cobis..cl_moneda
   where mo_moneda = @o_mon_nacional

   if @w_decimales = 'S' 
   begin
      select @o_dec_nacional = pa_tinyint
      from   cobis..cl_parametro
      where  pa_producto = 'CCA'
      and    pa_nemonico = 'NDE'
      
      if @@rowcount = 0
      begin
         select @w_error = 708130
         goto ERROR
      end
      
      set transaction isolation level read uncommitted
    
   end
   else
      select @o_dec_nacional = 0   
   return 0
   
ERROR:

   return @w_error
      
go