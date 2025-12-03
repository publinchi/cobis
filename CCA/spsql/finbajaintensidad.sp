/************************************************************************/
/*  Archivo:            finbajantensidad.sp                             */
/*  Stored procedure:   sp_fin_baja_intensidad                          */
/*  Base de datos:      cob_artera                                      */
/*  Producto:           cartera                                         */
/*  Disenado por:       Yecid Martinez                                  */
/*  Fecha de escritura: 12/Dic/2010                                     */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA".                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  Finaliza proceso de baja intesidad (fin dia cartera on line)        */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA         AUTOR             RAZON                               */
/************************************************************************/

use cob_cartera
go

if object_id('sp_fin_baja_intensidad') is not null
   drop proc sp_fin_baja_intensidad
go

create proc sp_fin_baja_intensidad
as

declare
@w_error                 int

update ca_universo_batch 
set ub_estado = 'Y' 
where ub_estado in ( 'N')

update ca_universo_batch 
set ub_estado = 'X' 
where ub_estado not in ( 'P','N','Y')

return 0
go
