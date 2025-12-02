/************************************************************************/
/*      Archivo:                contaest.sp                             */
/*      Stored procedure:       sp_contabilidad_est1                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           X.Maldonado                             */
/*      Fecha de escritura:     Mar-2003                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Presenta los diferentes estados para Cartera para el  	 	*/
/*      BUSQUEDA RUBROS DE CARTERA (RU_CXP)                  	        */
/*      Transaccion:    						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_est1')
   drop proc sp_contabilidad_est1
go

create proc sp_contabilidad_est1
@i_criterio1	char(10) = null
as

select @i_criterio1 = isnull(@i_criterio1,' ')

set rowcount 20

select 'Rubro' = co_concepto,
       'Descripcion' = ' ' + co_descripcion
from  cob_cartera..ca_concepto
where co_categoria in ('A','S')
and   co_concepto > @i_criterio1
order by co_concepto

set rowcount 0

return 0
go