/************************************************************************/
/*      Archivo:                contaeor.sp                             */
/*      Stored procedure:       sp_contabilidad_epoa                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           X.Maldonado	                        */
/*      Fecha de escritura:     Mar.2003                                */
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
/*      EP_OA								*/
/*      Transaccion: 							*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_epoa')
   drop proc sp_contabilidad_epoa
go

create proc sp_contabilidad_epoa

as

create table #entidad (
entidad		char(10),
descripcion	varchar(45)
)


insert into #entidad
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_tipo_linea' )
--and   valor like ('BANCO DE LA REP%') or  valor like ('FINAGRO%') or  valor like ('I.F.I.%')
order by valor

set rowcount 20

select 'Entidad' = entidad,
       'Descripcion' = descripcion 
from   #entidad
order by entidad

set rowcount 0

return 0
go