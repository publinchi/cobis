/************************************************************************/
/*      Archivo:                contacte.sp                             */
/*      Stored procedure:       sp_contabilidad_cte                     */
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
/*      cuenta definida como CL_GA_ED-O (Rubro-*Clase de Cartera;       */
/*                                       Garantia;    			*/
/*      Edad de Vencimiento)                                            */
/*      Transaccion: 7400						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_cte')
   drop proc sp_contabilidad_cte
go

create proc sp_contabilidad_cte
@i_criterio1	char(5)=null,
@i_criterio2	char(5)=null,
@i_criterio3	char(5)=null,
@i_criterio4	char(5)=null

as

create table #clase (
clase		char(1),
descripcion	varchar(20)
)



create table #garantia (
garantia	char(1),
descripcion1	varchar(20)
)


create table #cte (
codigo		char(10),
descripcion	varchar(30)
)



create table #rubro (
concepto 	char(10),
descripcion_rub	varchar(20)
)
insert into #clase
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla
               where tabla = 'cr_clase_cartera')

insert into  #garantia
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla
               where tabla = 'cu_clase_custodia')


insert into #rubro
select co_concepto,co_descripcion
from cob_cartera..ca_concepto


select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,''),
       @i_criterio3 = isnull(@i_criterio3,''),
       @i_criterio4 = isnull(@i_criterio4,'-1')

set rowcount 20

select 'Rubro' = concepto,
	'Clase' = clase,
       'Garantia' = garantia,
       'Estado' = es_codigo,
       'Descripcion' = descripcion_rub  + '.' +   descripcion + '.' + descripcion1 + '.' + es_descripcion
from #clase, #garantia, #rubro,cob_cartera..ca_estado
where ((concepto > @i_criterio1  and clase = @i_criterio2 and garantia = @i_criterio3 and es_codigo > convert(smallint,@i_criterio4)) or
      (concepto > @i_criterio1 and clase = @i_criterio2 and garantia > @i_criterio2) or
      (concepto > @i_criterio1)) 
order by concepto,clase, garantia,es_codigo

set rowcount 0

return 0
go