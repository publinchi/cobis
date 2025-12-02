/************************************************************************/
/*      Archivo:                cadevint.sp                             */
/*      Stored procedure:       sp_cont_devint                          */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           E.Pelaez                                */
/*      Fecha de escritura:     Feb 2004                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera las combinaciones de valores para la parte variable de   */
/*      DEVINT Devolucion de intereses		                              */
/*      Transaccion: 7431  					                              */
/************************************************************************/
use cobis
go


if exists (select 1 from sysobjects where name = 'sp_cont_devint')
   drop proc sp_cont_devint
go

create proc sp_cont_devint
as

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


select 'CONCEPTO'    = cp_producto, 
       'CLASE'       = codigo,
       'ORIGEN'      = clase,  
       'DESCRIPCION' = convert(char(20),cp_descripcion) +  ' ' + convert(char(12),valor) +  '    ' +  substring(descripcion,1,25)
from cob_cartera..ca_producto, cobis..cl_catalogo, #origen
where cp_producto = 'DEVINT'
and   tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )


return 0
go