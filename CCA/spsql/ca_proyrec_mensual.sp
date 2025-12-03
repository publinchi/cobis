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

if exists (select 1 from sysobjects where name = 'sp_proyrec_mensual_ext')
   drop proc sp_proyrec_mensual_ext
go

create proc sp_proyrec_mensual_ext
@i_param1       varchar(255) = null
as 
declare 
@w_error int,
@w_fecha datetime

select @w_fecha = convert(datetime, @i_param1, 101)

exec @w_error = cob_cartera..sp_proyrec
@i_fecha      = @w_fecha,
@i_tipo       = 'M'


if @w_error <> 0 return @w_error

return 0

go






