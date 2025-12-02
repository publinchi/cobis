/************************************************************************/
/*      Archivo:                contaeor.sp                             */
/*      Stored procedure:       sp_contabilidad_eor                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           E.Pelaez                                */
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
/*      Entidad INTERES-PRESTAMISTA   Parametro EP-GYC                  */
/*      Transaccion: 7403						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_eor')
   drop proc sp_contabilidad_eor
go

create proc sp_contabilidad_eor
@i_criterio1	char(10) = null,
@i_criterio2	char(10) = null

as

create table #entidad (
entidad		char(10),
descripcion	varchar(45)
)



create table #intereses (
concepto	char(10),
descripcion1	varchar(20)
)


insert into #intereses
select co_concepto, co_descripcion 
from cob_cartera..ca_concepto
where co_categoria = 'I'


insert into #entidad
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_tipo_linea' )


select @i_criterio1 = isnull(@i_criterio1,'')
select @i_criterio2 = isnull(@i_criterio2,'')

set rowcount 20

select 'Rubro' = concepto,
	'Entidad' = entidad,
       'Descripcion' = descripcion 
from   #entidad,#intereses
where  ((concepto >  @i_criterio1 and entidad > @i_criterio2) or
         (concepto >  @i_criterio1))
order by entidad

set rowcount 0

return 0
go