/************************************************************************/
/*      Archivo:                contacci.sp                             */
/*      Stored procedure:       sp_contabilidad_cci                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           MPoveda                                 */
/*      Fecha de escritura:     Marzo 2002                              */
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
/*      cuenta definida como RLC (Riesgo y Clase de Cartera )           */
/*      Transaccion: 7417						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_cci')
   drop proc sp_contabilidad_cci
go

create proc sp_contabilidad_cci
@i_criterio1	char(1)=null,
@i_criterio2	char(1)=null

as

/*TBLAS TEMOPRALES TMP */



create table #categoria_linea (
categoria  	char(1),
descripcion_cat	varchar(20)
)


create table #clase (
clase	char(1),
descripcion_cla	varchar(20)
)




insert into #clase
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )



insert into #categoria_linea
select codigo,
       valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_categoria_linea' )


select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,'')


set rowcount 20

select 'Clase' = clase,
       'Categoria' = categoria,
       'Descripcion' = descripcion_cla + '.' + descripcion_cat
from  #clase,#categoria_linea
where ((clase = @i_criterio1 and categoria> @i_criterio2) or
      (clase > @i_criterio1))
order by clase,categoria

set rowcount 0

return 0
go