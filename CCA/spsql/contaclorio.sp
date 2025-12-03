/************************************************************************/
/*      Archivo:                contaclorio.sp                          */
/*      Stored procedure:       sp_contabilidad_io                      */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           X.Maldonado                             */
/*      Fecha de escritura:     Marzo  2003                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera las combinaciones de valores para la parte variable de   */
/*      cuenta definida como CL_OR_IO                                   */
/*                              CAMBIOS                                 */
/************************************************************************/
/*   FECHA          AUTOR            CAMBIO                             */
/*   abr 18 2005    Elcira Pelaez    NR-379                             */
/*   FEB-2021       K. Rodríguez     Se comenta uso de concepto CXCINTES*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_io')
   drop proc sp_contabilidad_io
go

create proc sp_contabilidad_io
as



declare
@w_parametro_cxcintes         catalogo,   ---NR 379
@w_concepto_traslado          catalogo    ---NR 379


select @w_parametro_cxcintes = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'CXCINT'
set transaction isolation level read uncommitted

/*  -- KDR Sección no aplica para la versión de Finca
select @w_concepto_traslado  = co_concepto
from cob_cartera..ca_concepto
where co_concepto = @w_parametro_cxcintes

if @@rowcount = 0 
   return 711017
*/ -- FIN KDR


/*TBLAS TEMOPRALES TMP */

create table #origen (
clase	        char(2),
descripcion	varchar(40)
)


insert into #origen
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_categoria_linea' )
and   valor like 'RECURSOS%'


select 'CONCEPTO'    = co_concepto, 
       'CLASE'       = codigo,
       'ORIGEN'      = clase,  
       'DESCRIPCION' = convert(char(20),co_descripcion) +  ' ' + convert(char(12),valor) +  '    ' +  substring(descripcion,1,25)
from cob_cartera..ca_concepto, cobis..cl_catalogo, #origen
where co_categoria in ('M','I','C')
and   tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )
union
select 'CONCEPTO'    = co_concepto, 
       'CLASE'       = codigo,
       'ORIGEN'      = clase,  
       'DESCRIPCION' = convert(char(20),co_descripcion) +  ' ' + convert(char(12),valor) +  '    ' +  substring(descripcion,1,25)
from cob_cartera..ca_concepto, cobis..cl_catalogo, #origen
where co_concepto = @w_concepto_traslado
and   tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )


return 0
go