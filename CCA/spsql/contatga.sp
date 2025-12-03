/************************************************************************/
/*      Archivo:                contatga.sp                             */
/*      Stored procedure:       sp_contabilidad_tga                     */
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
/*      CL-IA (INTERES CLASE DE CARTERA)                                */
/*      Transaccion: 7419						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_tga')
   drop proc sp_contabilidad_tga
go

create proc sp_contabilidad_tga
@i_criterio1	char(10)=null,
@i_criterio2	char(10)=null

as

/*TBLAS TEMOPRALES TMP */


create table #rubro (
concepto 	char(10),
descripcion_rub	varchar(20)
)


create table #clase (
clase	char(1),
descripcion_cla	varchar(20)
)


insert into #rubro
select co_concepto,co_descripcion
from cob_cartera..ca_concepto
where co_categoria = 'I'


insert into #clase
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )


select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,'')


set rowcount 20

select 'Rubro' = concepto,
       'Clase' = clase,
       'Descripcion' = descripcion_rub + '.' + descripcion_cla
from  #rubro,#clase
where ((concepto = @i_criterio1 and clase > @i_criterio2) or
      (concepto > @i_criterio1))
order by concepto,clase

set rowcount 0

return 0

return 0
go