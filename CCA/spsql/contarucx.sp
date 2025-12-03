/************************************************************************/
/*      Archivo:                contaeor.sp                             */
/*      Stored procedure:       sp_contabilidad_rucx                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           X.Maldonado	                        */
/*      Fecha de escritura:     Mar.2003                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera las combinaciones de valores para la parte variable de   */
/*      RU_CXPT								*/
/*      Transaccion: 							*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_rucx')
   drop proc sp_contabilidad_rucx
go

create proc sp_contabilidad_rucx
@i_criterio1	char(10)=null

as

create table #rubro (
concepto	char(10),
descripcion	varchar(45)
)


insert into #rubro
select co_concepto,co_descripcion
from cob_cartera..ca_concepto
where co_categoria in ('A', 'C', 'H', 'M', 'O', 'R', 'S')
order by co_descripcion



select @i_criterio1 = isnull(@i_criterio1,'')

set rowcount 20

select 'Concepto' = concepto,
       'Descripcion' = descripcion 
from   #rubro
where  concepto > @i_criterio1
order by concepto

set rowcount 0

return 0
go