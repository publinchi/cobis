/************************************************************************/
/*      Archivo:                contacmo.sp                             */
/*      Stored procedure:       sp_contabilidad_cmo                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Epelaez                                 */
/*      Fecha de escritura:     Mat 2003                                */
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
/*      OR-IO  INTERES-ORIGEN RECURSOS                                  */
/*      Transaccion: 7415						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_cmo')
   drop proc sp_contabilidad_cmo
go

create proc sp_contabilidad_cmo
@i_criterio1	char(10)=null,
@i_criterio2	char(10)=null
as

/*TBLAS TEMOPRALES TMP */


create table #rubro (
concepto	varchar(10),
descripcion_rub	varchar(20)
)


create table #origen (
origen	char(10),
descripcion_org	varchar(20)
)


insert into #origen
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_categoria_linea' )


insert into #rubro
select co_concepto,co_descripcion
from cob_cartera..ca_concepto
where co_categoria in ('I','O') ---Interes coriente y Comisiones



select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,'')



select 'Rubro' = concepto,
       'Origen Recursos' = origen,
       'Descripcion' = descripcion_rub + '.' + descripcion_org
from  #rubro, #origen
where (concepto = @i_criterio1 and origen > @i_criterio2)  or
      (concepto > @i_criterio1 )
order by concepto, origen


set rowcount 0

return 0

go