/************************************************************************/
/*      Archivo:                sp_debitos_batch.sp                     */
/*      Stored procedure:       sp_debitos_batch                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sandro Vallejo                          */
/*      Fecha de escritura:     AGO 2020                                */
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
/*      Proceso Paralelo de debitos automáticos para operaciones        */
/*      de cartera, escoge grupos por hilo                              */
/************************************************************************/
/*                              MODIFICACIONES                          */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_debitos_batch')
   drop proc sp_debitos_batch
go
create procedure sp_debitos_batch
(
 @s_user          varchar(14),
 @s_term          varchar(30),
 @s_date          datetime,
 @s_sesn          int,
 @i_tipo          char(1) = 'F',  -- 'I=Intento en Linea  F=En Batch
 @i_hilo          tinyint,        -- numero de hilos a generar o hilo que debe procesar
 @i_numreg        int             -- numero de registros por hilo
)
as

declare
   @w_sp_name         descripcion,
   @w_cont            smallint,
   @w_fecha           datetime

select 
@w_sp_name = 'sp_debitos_batch'

/* SELECCIONAR LA FECHA DE PROCESO */
select @w_fecha = fc_fecha_cierre from cobis..ba_fecha_cierre WHERE fc_producto = 7

while 1 = 1
begin 
   select @w_cont = count(*)
   from   ca_universo_debitos
   where  hilo     = @i_hilo
   and    intentos < 2
      
   select @w_cont = @i_numreg - isnull(@w_cont, 0)
      
   if @w_cont < 0 select @w_cont = @i_numreg

   if @w_cont > 0 
   begin
      BEGIN TRAN

      set rowcount @w_cont
         
      update ca_universo_debitos
      set    hilo = @i_hilo
      where  hilo     = 0
      and    intentos = 0
       
      if @@rowcount = 0
      begin
         COMMIT TRAN 
         return 0 --SALIR
      end
         
      COMMIT TRAN 
      set rowcount 0
   end

   exec sp_debitos_batch_INT
   @s_user          = @s_user,
   @s_term          = @s_term,
   @s_date          = @s_date,
   @s_sesn          = @s_sesn,
   @i_fecha_proceso = @w_fecha,
   @i_tipo          = @i_tipo,
   @i_hilo          = @i_hilo
end

return 0
go
