/************************************************************************/
/*      Archivo:                contatge.sp                             */
/*      Stored procedure:       sp_contabilidad_tge                     */
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
/*      BUSQUEDA INT-IMO ORIGEN RECURSOS                                */
/*      Transaccion: 7409						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_tge')
   drop proc sp_contabilidad_tge
go

create proc sp_contabilidad_tge
@i_criterio1	varchar(10)=null,
@i_criterio2	varchar(10)=null
as



create table #origrecursos (
origenrecurso	char(10),
descripcion1	varchar(45)
)

create table #intereses (
concepto	char(10),
descripcion2	varchar(20)
)


insert into #intereses
select co_concepto, co_descripcion 
from cob_cartera..ca_concepto
where co_categoria in ('I','M','R')



insert into #origrecursos
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_categoria_linea' )



select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,'')

set rowcount 20

select 'Concepto'        = concepto,
       'Origen Recursos' = origenrecurso,	
       'Descripcion'     = descripcion2 + '.' + descripcion1
from   #origrecursos,#intereses
where  ((concepto = @i_criterio1 and origenrecurso > @i_criterio2) or
       (concepto > @i_criterio1))
order by concepto,origenrecurso

set rowcount 0

return 0
go