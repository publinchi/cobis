/************************************************************************/
/*      Archivo:                contaces.sp                             */
/*      Stored procedure:       sp_contabilidad_ces                     */
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
/*      cuenta definida como RLC (Riesgo y Clase de Cartera )           */
/*      Transaccion: 7420						*/
/*      EPB:feb-15-2002 actualizaciones circular 50                     */
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_ces')
   drop proc sp_contabilidad_ces
go

create proc sp_contabilidad_ces
@i_criterio1	char(1)=null,
@i_criterio2	char(1)=null

as

/*TBLAS TEMOPRALES TMP */



	
create table #clase (
clase	char(1),
descripcion_cla	varchar(20)
)

create table #estado (
codigo	int,
descripcion_est	varchar(20)
)


insert into #estado
select es_codigo,
       es_descripcion
from cob_cartera..ca_estado



insert into #clase
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )


select @i_criterio1 = isnull(@i_criterio1,'-1'),
       @i_criterio2 = isnull(@i_criterio2,'')


select 'Clase' = clase,
       'Estado' = codigo,
       'Descripcion' = descripcion_cla + '.' + descripcion_est
from  #clase,#estado
where ((clase = @i_criterio1 and codigo > convert(smallint,@i_criterio2)) or
       (clase > @i_criterio1))
order by clase,codigo

set rowcount 0

return 0
go