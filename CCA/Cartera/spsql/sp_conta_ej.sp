use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_caconta_ej')
   drop proc sp_caconta_ej
go

create procedure sp_caconta_ej
/*************************************************************************/
/*      Archivo:                sp_caconta_ej.sp                         */
/*      Stored procedure:       sp_caconta_ej                            */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Sandro Vallejo                           */
/*      Fecha de escritura:     Ago 2020                                 */
/*********************************************************************** */
/*                     IMPORTANTE                                        */
/*   Este programa es parte de los paquetes bancarios que son            */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,       */
/*   representantes exclusivos para comercializar los productos y        */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida      */
/*   y regida por las Leyes de la República de España y las              */
/*   correspondientes de la Unión Europea. Su copia, reproducción,       */
/*   alteración en cualquier sentido, ingeniería reversa,                */
/*   almacenamiento o cualquier uso no autorizado por cualquiera         */
/*   de los usuarios o personas que hayan accedido al presente           */
/*   sitio, queda expresamente prohibido; sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de       */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto       */
/*   en el presente texto, causará violaciones relacionadas con la       */
/*   propiedad intelectual y la confidencialidad de la información       */
/*   tratada; y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.                */
/*************************************************************************/
/*                              PROPOSITO                                */
/*      Realizar la invocacion al proceso de contabilizacion de cartera  */
/*      en paralelo.                                                     */
/*************************************************************************/
/*                              MODIFICACIONES                           */
/*       FECHA            AUTOR                 RAZON                    */
/*       30/Jun/2022      Wlopez                CCA-S662865-GFI          */
/*       20/Abr/2023     G. Fernandez      S807925 Salida de paralelismo */
/*                                         cuando se ingresa la operacion*/
/*************************************************************************/
( 
   @i_param1         int           = 0,             --hilo
   @i_param2         login         = 'sp_caconta',  --user
   @i_param3         char(1)       = 'N',           --debug
   @i_param4         cuenta        = null,          --banco
   @i_param5         datetime      = null,          --fecha de proceso
   @i_param6         int           = null           --numero registros
) 
as 
 
declare 
   @w_sp_name        varchar(30), 
   @w_error          int, 
   @w_fecha_proceso  datetime,
   @w_cont           smallint,
   @i_debug          char(1) = 'N',
   @i_hilo           tinyint,        -- numero de hilos a generar o hilo que debe procesar
   @i_numreg         int

IF @i_param4 = 'NULL'
  select @i_param4 = null

select @w_sp_name   = 'sp_caconta_ej',
       @w_error     = 0

select @w_fecha_proceso = fc_fecha_cierre
from   cobis..ba_fecha_cierre with (nolock)
where  fc_producto = 7

select @i_hilo   =  @i_param1,
       @i_debug  =  @i_param3,
       @i_numreg =  @i_param6

-- LAZO DE PROCESAMIENTO POR HILO       
while 1 = 1
begin 
   select @w_cont = count(*)
   from   ca_universo_conta  
   where  hilo     = @i_hilo
   and    intentos < 2

   select @w_cont = @i_numreg - isnull(@w_cont, 0)
      
   if @w_cont < 0 select @w_cont = @i_numreg

   if @w_cont > 0 
   begin
      BEGIN TRAN

      set rowcount @w_cont
         
      update ca_universo_conta 
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

   exec @w_error = cob_cartera..sp_caconta 
      @i_param1 = @i_hilo,   --hilo
      @i_param2 = @i_param2, --user
      @i_param3 = @i_debug,  --debug
      @i_param4 = @i_param4, --banco
      @i_param5 = @i_param5  --fecha de proceso
        
   if @w_error <> 0 
   begin                 
      exec sp_errorlog
      @i_fecha       = @w_fecha_proceso, 
      @i_error       = @w_error, 
      @i_usuario     = 'consola',
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name, 
      @i_rollback    = 'N',
      @i_cuenta      = 'CONTABILIDAD', 
      @i_descripcion = 'ERROR: Ejecucion cob_cartera..sp_caconta_ej '
        
      return @w_error  
   end
   
   if @i_param4 is not null
   begin
      return 0 --SALIR
   end
   
end
 
return 0 

go
