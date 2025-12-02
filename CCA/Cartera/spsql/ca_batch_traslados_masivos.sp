/************************************************************************/ 
/*    ARCHIVO:         batch_traslados_masivos.sp             	  	    */ 
/*    NOMBRE LOGICO:   sp_batch_traslados_masivos                       */ 
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:   Guisela Fernandez, Johan Hernandez                 */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/ 
/*                     PROPOSITO                                        */ 
/*  Sirve como cascaron del sp_traslados_masivos_cartera y sera llamado */ 
/*  en el proceso Batch, se utiliza en el translado de Oficina 	como    */
/*  de Oficial.                                                         */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA        AUTOR           RAZON                                 */ 
/* 18/03/2021    G. Fernandez	 Versión Inicial                        */
/* 18/03/2021    J. Hernandez	 Versión Inicial                        */
/* 16/07/2021    K. Rodriguez    Estandarización parámetros             */
/************************************************************************/ 

USE cob_cartera
GO



if exists (select 1 from sysobjects where name = 'sp_batch_traslados_masivos')
   drop proc sp_batch_traslados_masivos
go

CREATE PROC sp_batch_traslados_masivos
(
@i_param1             int           = null,
@i_param2             int           = null,
@i_param3             int           = null,
@i_param4             int           = null,
@i_param5             varchar(255)        ,   -- Fecha proceso
@i_param6             varchar(255)        ,   -- Tipo Operación, I=Insertar ....
@i_param7			  varchar(255)            -- Usuario
)
as

DECLARE 
@w_return          	INT,
@w_fecha_proceso 	Datetime,
@w_operacion		Char(1)  

select @w_fecha_proceso = convert (Datetime, @i_param5)
select @w_operacion 	= convert (Char(1), @i_param6)



select @w_fecha_proceso = isnull(@w_fecha_proceso,fc_fecha_cierre)
from cobis..ba_fecha_cierre
where fc_producto = 7

--Llamada a SP con cursores 
exec @w_return = sp_traslados_masivos_cartera 
@i_operacion 		= @w_operacion, 
@i_fecha_proceso 	= @w_fecha_proceso,
@s_user			    = @i_param7
  
if @w_return <> 0
   return @w_return

return 0
go