/************************************************************************/
/*      Archivo:                ca_proyrec.sp                           */
/*      Stored procedure:       sp_proyrec                              */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Paulina Galindo                         */
/*      Fecha de escritura:     22-Feb-2010                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Proyecci•n de recuperaci•n en n tiempo                          */
/*      Reporte mensual se debe generar despu‚s del cierre del £ltimo   */
/*      d¡a de cada mes.                                                */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre         Proposito                        */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_proyrec_eventual_ext')
   drop proc sp_proyrec_eventual_ext
go

create proc sp_proyrec_eventual_ext
@i_param1       varchar(255) = null,
@i_param2       varchar(255) = null
as 
declare 
@w_error     int,
@w_fecha_min datetime,
@w_fecha_max datetime

select 
@w_fecha_min = convert(datetime, @i_param1, 101),
@w_fecha_max = convert(datetime, @i_param2, 101)

exec @w_error = cob_cartera..sp_proyrec
@i_fecha_min  = @w_fecha_min,   
@i_fecha_max  = @w_fecha_max,   
@i_tipo       = 'E'


if @w_error <> 0 return @w_error

return 0

go






