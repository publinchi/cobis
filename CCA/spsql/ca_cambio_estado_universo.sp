/************************************************************************/
/*   Archivo:            ca_cambio_estado_universo.sp                   */
/*   Stored procedure:   sp_cambio_estado_universo                      */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Fecha de escritura: Nov. 2013                                      */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                          PROPOSITO                                   */
/*                                                                      */
/*      Cambia estado a 6 de las operaciones condonadas en el CC 394    */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR         RAZON                              */
/*  Diciembre-17-2013   Luis Guzman  Emision Inicial                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_universo')
   drop proc sp_cambio_estado_universo
go

create proc sp_cambio_estado_universo
as

print 'Actualiza las Operaciones Condonadas a Estado 6'

update ca_operacion set
op_estado = 6
from ca_venta_universo
where op_operacion = operacion_interna
and   Estado_Venta = 'P'

if @@error <> 0 
begin
   print 'No se pudo actualizar el estado de las Operaciones que fueron condonadas'
   return 708152
end

print 'Registros Actualizados'

return 0
go