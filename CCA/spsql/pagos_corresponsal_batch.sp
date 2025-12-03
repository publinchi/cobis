/************************************************************************/
/*    Base de datos:          cob_cartera                               */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Javier calderon                         */
/*      Fecha de escritura:     27/06/2017                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*      Tiene como propósito procesar los pagos de los corresponsales   */
/*                                                                      */
/************************************************************************/  


use cob_cartera
go

IF OBJECT_ID ('dbo.sp_pagos_corresponsal_batch') IS NOT NULL
    DROP PROCEDURE dbo.sp_pagos_corresponsal_batch
GO

create proc sp_pagos_corresponsal_batch
(
@i_param1        CHAR(1) = 'B', -- Operacion sp_corresponsal
@i_param2        char(1) = 'S'  -- Realiza Fecha Valor
)
as 
declare 
@w_fecha_pro   datetime,
@w_error       int,
@w_sp_name     descripcion,
@w_msg         descripcion

select @w_fecha_pro = fp_fecha from cobis..ba_fecha_proceso 

select @w_sp_name = 'sp_pagos_corresponsal_batch'

exec  @w_error     = sp_pagos_corresponsal
      @i_operacion      = 'B' ,
      @i_ejecutar_fvalor = @i_param2
	  
if @w_error <> 0
begin 
   select 
   @w_msg = 'Error !:No se pudo procesar el BATCH  de Pagos por Corresponsal'
   goto ERROR_FIN
end	  
	  
	  
return 0
   
ERROR_FIN:
  exec cob_cartera..sp_errorlog 
    @i_fecha       = @w_fecha_pro,
    @i_error       = @w_error,
    @i_usuario     = 'usrbatch',
    @i_tran        = 7999,
    @i_tran_name   = @w_sp_name,
    @i_cuenta      = '',
    @i_descripcion = @w_msg, 
    @i_rollback    = 'S' 
       
return 0




GO

