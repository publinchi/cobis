/************************************************************************/
/*      Archivo:                contamon.sp                             */
/*      Stored procedure:       sp_contabilidad_mon                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           MPoveda                                 */
/*      Fecha de escritura:     Agosto 2001                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera las combinaciones de valores para la parte variable de   */
/*      cuenta definida como MON (Moneda)                               */
/*      Transaccion: 7402						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_mon')
   drop proc sp_contabilidad_mon
go

create proc sp_contabilidad_mon
as

select 'Moneda' = mo_moneda,
       'Descripcion' = mo_descripcion
from   cl_moneda


return 0
go