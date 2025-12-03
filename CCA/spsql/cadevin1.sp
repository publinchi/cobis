/************************************************************************/
/*      Archivo:                cadevin1.sp                             */
/*      Stored procedure:       sp_cont_devint_uno                      */
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
/*      DEVINT - UNO Devolucion de intereses                            */
/*      Transaccion: 7432  					                              */
/************************************************************************/
use cobis
go


if exists (select 1 from sysobjects where name = 'sp_cont_devint_uno')
   drop proc sp_cont_devint_uno
go

create proc sp_cont_devint_uno
@i_criterio1	char(10)=null,
@i_criterio2	char(10)=null
as

create table #categoria (
codigo 	char(10),
descripcion_cat	varchar(20)
)

create table #concepto (
concepto	char(10),
descripcion_con	varchar(20)
)

insert into #categoria
select codigo,
       valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla = 'ca_categoria_linea' )


insert into #concepto
select cp_producto,
       cp_descripcion
from cob_cartera..ca_producto
where cp_producto = 'DEVINT'

select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,'')


select 'Concepto'       = concepto,
       'Origen Recurso' = codigo,
       'Descripcion' = descripcion_con + '.' + descripcion_cat
from  #categoria,#concepto
where ((concepto = @i_criterio1 and codigo > @i_criterio2) or
      (concepto > @i_criterio1))
order by concepto,codigo
set rowcount 0

return 0
go