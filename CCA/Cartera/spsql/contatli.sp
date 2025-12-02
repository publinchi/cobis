/************************************************************************/
/*      Archivo:                contatli.sp                             */
/*      Stored procedure:       sp_contabilidad_tli                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           MPoveda                                 */
/*      Fecha de escritura:     Agosto 2001                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/************************************************************************/
/*      Genera las combinaciones de valores para la parte variable de   */
/*      ORIGEN DE LOS RECURSOS 			                                */
/*      Transaccion: 7404						                        */
/*                              CAMBIOS                                 */
/************************************************************************/
/*   FECHA          AUTOR               CAMBIO                          */
/*   abr 18 2005    Elcira Pelaez    NR-379                             */
/*   FEB 18 2021    K. Rodríguez     Se comenta uso de concepto CXCINTES*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_tli')
   drop proc sp_contabilidad_tli
go

create proc sp_contabilidad_tli
@i_criterio1	char(10)=null,
@i_criterio2	char(10)=null
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
*/
   
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
select co_concepto,
       co_descripcion
from cob_cartera..ca_concepto
where co_categoria in ('I','M','C')
union
select co_concepto,
       co_descripcion
from cob_cartera..ca_concepto
where co_concepto = @w_concepto_traslado

select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,'')



set rowcount 20

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