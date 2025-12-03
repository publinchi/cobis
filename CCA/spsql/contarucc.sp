/************************************************************************/
/*      Archivo:                contarucc.sp                             */
/*      Stored procedure:       sp_contabilidad_rucc                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           X.Maldonado	                        */
/*      Fecha de escritura:     Mar.2003                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera las combinaciones de valores para la parte variable de   */
/*      RU_CC								*/
/*      Transaccion: 							*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_rucc')
   drop proc sp_contabilidad_rucc
go

create proc sp_contabilidad_rucc
@i_criterio1	catalogo = null

as

if @i_criterio1 is null
   select @i_criterio1 = ''
set rowcount 20

select 'Concepto' = co_concepto,
       'Descripcion' = co_descripcion 
from cob_cartera..ca_concepto
where  co_concepto > @i_criterio1
order by co_concepto

set rowcount 0

return 0
go