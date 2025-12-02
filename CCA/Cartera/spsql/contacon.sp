/************************************************************************/
/*      Archivo:                contatge.sp                             */
/*      Stored procedure:       sp_contabilidad_con                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           E. Pelaez                               */
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
/*      Genera las combinaciones de valores para la parte variable de   */
/*      BUSQUEDA INT-IMO CLAE - ORIGEN RECURSOS                         */
/*      Transaccion: 7413						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_con')
   drop proc sp_contabilidad_con
go

create proc sp_contabilidad_con
@i_criterio1	varchar(10)=null,
@i_criterio2	varchar(10)=null,
@i_criterio3	varchar(10)=null
as

create table #origrecursos (
origenrecurso	char(10),
descripcion1	varchar(45)
)



create table #clase (
clase	char(1),
descripcion3	varchar(20)
)

create table #intereses (
concepto	char(10),
descripcion2	varchar(20)
)


insert into #intereses
select co_concepto, co_descripcion 
from cob_cartera..ca_concepto
where co_categoria in ('I','M')



insert into #origrecursos
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_categoria_linea' 
               )
and codigo = '15'


insert into #clase
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )


select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,''),
       @i_criterio3 = isnull(@i_criterio3,'')

set rowcount 20

select 'Concepto'        = concepto,
       'Clase'           = clase,
       'Origen Recursos' = origenrecurso,	
       'Descripcion'     = descripcion2 + '.' + descripcion3 + '.' + descripcion1
from   #origrecursos,#intereses,#clase
where  ((concepto = @i_criterio1 and clase > @i_criterio2 and origenrecurso > @i_criterio3) or
       (concepto > @i_criterio1 and clase > @i_criterio2) or 
       (concepto > @i_criterio1))
order by concepto,clase,origenrecurso

set rowcount 0

return 0
go