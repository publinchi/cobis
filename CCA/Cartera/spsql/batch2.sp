/************************************************************************/
/*      Archivo:                sp_batch2.sp                            */
/*      Stored procedure:       sp_batch2                               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sandro Vallejo                          */
/*      Fecha de escritura:     Nov. 2017                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes exclusivos para el Ecuador de la       */
/*      'NCR CORPORATION'.                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Procesar batch de fin de dia de cartera en paralelo.            */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*   19/11/2020   Patricio Narvaez   Esquema de Inicio de Dia, 7x24 y   */
/*                                   Doble Cierre automatico            */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where id=object_id('dbo.sp_batch2') and type='P')
   drop procedure dbo.sp_batch2
go

create procedure sp_batch2 
( 
   @s_user          login, 
   @s_term          varchar(30), 
   @s_date          datetime, 
   @s_ofi           smallint, 
   @i_en_linea      char(1), 
   @i_siguiente_dia datetime = null,  
   @i_pry_pago      char(1)  = 'N',   
   @i_debug         char(1)  = 'N',   
   @i_operacion     char(1)  = 'P',  -- P procesar 
   @i_hilo          tinyint,         -- numero de hilos a generar o hilo que debe procesar 
   @i_sarta         int      = null, 
   @i_batch         int      = null, 
   @i_numreg        int      = null, 
   @i_aplicar_clausula      char(1)   = 'S',
   @i_aplicar_fecha_valor   char(1)   = 'N',
   @i_control_fecha         char(1)   = 'S',
   @i_pago_ext              char(1)   = 'N',  ---req 482
   @i_simular_cierre        datetime  = null  --Simular el cierre enviando la fecha de cierre diferente a la de la tabla   
) 
as 
 
declare @w_cont     SMALLINT,
        @w_return   INT
        

if @i_operacion = 'P' -- procesar 
begin 
   while 1 = 1 
   begin  
      select @w_cont = count(*) 
      from   ca_universo
      where  hilo     = @i_hilo 
      and    intentos < 2 
       
      select @w_cont = @i_numreg - isnull(@w_cont, 0) 
      
      if @w_cont < 0 select @w_cont = @i_numreg 
 
      if @w_cont > 0  
      begin 
         BEGIN TRAN 
         set rowcount @w_cont 
          
         update ca_universo set 
         hilo = @i_hilo 
         where hilo     = 0 
         and   intentos = 0 
        
         if @@rowcount = 0 
         begin 
             COMMIT TRAN  
             return 0 --SALIR 
         end 
          
         COMMIT TRAN  
         set rowcount 0 
      end 
                  
      exec @w_return = sp_batch1
      @s_user                = @s_user,
      @s_term                = @s_term,
      @s_date                = @s_date,
      @s_ofi                 = @s_ofi,
      @i_en_linea            = @i_en_linea,
      @i_siguiente_dia       = @i_siguiente_dia, --LPO CDIG Nuevo Esquema Paralelismo
      @i_pry_pago            = @i_pry_pago,
      @i_aplicar_clausula    = @i_aplicar_clausula,
      @i_aplicar_fecha_valor = @i_aplicar_fecha_valor,
      @i_control_fecha       = @i_control_fecha,
      @i_debug               = @i_debug, 
      @i_pago_ext            = @i_pago_ext, --Req 482
      @i_hilo                = @i_hilo,    --LPO CDIG Nuevo Esquema Paralelismo
      @i_batch               = @i_batch,   --LPO CDIG Nuevo Esquema Paralelismo
      @i_sarta               = @i_sarta,   --LPO CDIG Nuevo Esquema Paralelismo
      @i_simular_cierre      = @i_simular_cierre
   end 
end  -- fin operacion P 
 
return 0 
go
