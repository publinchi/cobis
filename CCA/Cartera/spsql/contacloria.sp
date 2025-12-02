/************************************************************************/
/*      Archivo:                contacloria.sp                             */
/*      Stored procedure:       sp_contabilidad_clor                  */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           X.Maldonado                             */
/*      Fecha de escritura:     Marzo  2003                             */
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
/*      cuenta definida como CL-IA                                      */
/*      Transaccion:    						*/
/*  									*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_clor')
   drop proc sp_contabilidad_clor
go

create proc sp_contabilidad_clor
as


create table #origen (
clase	        char(2),
descripcion	varchar(40)
)


insert into #origen
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_categoria_linea' )
and   valor like 'RECURSOS P%'


select 'CONCEPTO'    = co_concepto, 
       'CLASE'       = codigo,
       'ORIGEN'      = clase,  
       'DESCRIPCION' = convert(char(20),co_descripcion) +  ' ' + convert(char(12),valor) +  '    ' +  substring(descripcion,1,25)
from cob_cartera..ca_concepto, cobis..cl_catalogo, #origen
where co_categoria ='I'
and   co_concepto  = 'INTANT'
and   tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )



set rowcount 0

return 0
go