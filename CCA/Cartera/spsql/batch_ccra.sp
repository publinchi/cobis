/************************************************************************/
/*   Archivo:             batch_cca.sp                                  */
/*   Stored procedure:    sp_batch_ccra                                 */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        RRB                                           */
/*   Fecha de escritura:  Mar. 09.                                      */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/*            PROPOSITO                                                 */
/*   Procedimiento que realiza la ejecucion del fin de dia de           */
/*   cartera.                                                           */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*   23/abr/2010   Fdo Carvajal Interfaz Ahorros-CCA                    */
/*   03/Mar/2020   Luis Ponce   Parametro para no cortar el batch el fin*/
/*                              de fin de mes cuando es feriado         */
/*   09/Mar/2022   G. Fernandez Se incluye parametros 7, 8, 9 y 10 solo */
/*                              parapruebas de una operacion y          */
/*                              simulación de cierre                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_batch_ccra')
   drop proc sp_batch_ccra
go

create proc sp_batch_ccra
@i_param1              varchar(255)  = null, 
@i_param2              varchar(255)  = null, 
@i_param3              varchar(255)  = null, 
@i_param4              varchar(255)  = null, 
@i_param5              varchar(255)  = null, 
@i_param6              varchar(255)  = null,   -- FCP Interfaz Ahorros
@i_param7              varchar(255)  = null,   -- GFP Debug
@i_param8              varchar(255)  = null,   -- GFP Parametro solo para pruebas de una sola operacion
@i_param9              varchar(255)  = null,   -- GFP Parametro solo para pruebas se envia fecha de proceso
@i_param10             varchar(255)  = null    -- GFP Parametro solo para pruebas se envia fecha de cierre
as  

declare @w_return          INT,
        @w_control_fecha   CHAR(1)        

--LPO TEC Cortar batch Fin de Mes 
SELECT @w_control_fecha = pa_char
FROM cobis..cl_parametro
WHERE pa_nemonico = 'COFIME'
  AND pa_producto = 'CCA'

IF @i_param8 = 'NULL'
  SELECT @i_param8 = null

exec @w_return = sp_batch 
@i_param1 = @i_param1,                                
@i_param2 = @i_param2,                                
@i_param3 = @i_param3,                                
@i_param4 = @i_param4,                                
@i_param5 = @i_param5,                                
@i_param6 = @i_param6,                  -- FCP Interfaz Ahorros
@i_debug  = @i_param7,                  -- GFP Debug
@i_banco  = @i_param8,                  -- GFP Parametro solo para pruebas de una sola operacion
@i_siguiente_dia  = @i_param9,          -- GFP Parametro solo para pruebas se envia fecha de proceso
@i_simular_cierre = @i_param10,          -- GFP Parametro solo para pruebas se envia fecha de cierre
@i_control_fecha = @w_control_fecha     --LPO Parametro para cortar el batch a fin de mes. N es No cortar el batch en fin de mes

if @w_return <> 0
   return @w_return

return 0
go
