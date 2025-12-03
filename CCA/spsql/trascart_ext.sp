/************************************************************************/
/*  Archivo:              trascart_ext.sp                               */
/*  Stored procedure:     sp_traslada_cartera                           */
/*  Base de datos:        cob_cartera                                   */
/*  Producto:             Cartera                                       */
/*  Disenado por:         Fabian de la Torre.                           */
/*  Fecha de escritura:   Oct 2009                                      */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA'.                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/  

use cob_cartera
go 
if exists (select 1 from sysobjects where name = 'sp_traslada_cartera_ext')
   drop proc sp_traslada_cartera_ext
go

create proc  sp_traslada_cartera_ext
as

declare 
@w_error         int,
@w_fecha_proceso datetime


select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

exec @w_error = sp_traslada_cartera
@s_user       = 'OPERADOR',      
@s_term       = 'CONSOLA',
@s_date       = @w_fecha_proceso,   
@s_ofi        = 1,
@i_operacion  = 'E'   

return @w_error
    
go
