use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_bocfin_ej')
   drop proc sp_bocfin_ej
go

create procedure sp_bocfin_ej
/*************************************************************************/
/*      Archivo:                sp_bocfin_ej.sp                          */
/*      Stored procedure:       sp_bocfin_ej                             */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Sandro Vallejo                           */
/*      Fecha de escritura:     Sep 2020                                 */
/*********************************************************************** */
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      'MACOSA', representantes exclusivos para el Ecuador de la        */
/*      'NCR CORPORATION'.                                               */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de MACOSA o su representante.              */
/*************************************************************************/
/*                              PROPOSITO                                */
/*      Realizar la invocacion al proceso de afectacion de cuentas de    */
/*      boc de cartera en paralelo                                       */
/*************************************************************************/
/*                              MODIFICACIONES                           */
/*     Fecha        Autor          Razón                                 */
/*     16/07/2021   K. Rodríguez   Estandarización de parámetros         */
/*************************************************************************/
/*************************************************************************/

( 
	@i_param1        datetime,            -- Fecha
	@i_param2        char(1)       = 'N', -- Debug
	@i_param3        tinyint,             -- numero de hilos a generar o hilo que debe procesar
	@i_param4        int                  -- Número de registros.
) 
as 
 
declare 
   @w_sp_name        varchar(30), 
   @w_error          int, 
   @w_cont           smallint,
   @i_debug          char(1),
   @i_fecha          datetime, 
   @i_hilo           tinyint,       
   @i_numreg         int

-- KDR 16/07/21 Paso de parámetros a variables locales.
select @i_fecha   =  @i_param1,        
       @i_debug   =  @i_param2,         
	   @i_hilo    =  @i_param3,
       @i_numreg  =  @i_param4  
 
select @w_sp_name   = 'sp_bocfin_ej',
       @w_error     = 0

-- LAZO DE PROCESAMIENTO POR HILO       
while 1 = 1
begin 
   select @w_cont = count(*)
   from   ca_universo_bocfin  
   where  hilo     = @i_hilo
   and    intentos < 2
      
   select @w_cont = @i_numreg - isnull(@w_cont, 0)
      
   if @w_cont < 0 select @w_cont = @i_numreg

   if @w_cont > 0 
   begin
      BEGIN TRAN

      set rowcount @w_cont
         
      update ca_universo_bocfin 
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

   exec @w_error = cob_cartera..sp_bocfin 
        @i_debug = @i_debug,
        @i_fecha = @i_fecha, 
        @i_hilo  = @i_hilo 
        
   if @w_error <> 0 
   begin                 
      exec sp_errorlog
      @i_fecha       = @i_fecha, 
      @i_error       = @w_error, 
      @i_usuario     = 'consola',
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name, 
      @i_rollback    = 'N',
      @i_cuenta      = 'BOCFIN', 
      @i_descripcion = 'ERROR: Ejecucion cob_cartera..sp_bocfin_ej '
        
      return @w_error  
   end
end
 
return 0 

go
