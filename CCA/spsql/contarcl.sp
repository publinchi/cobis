/************************************************************************/
/*      Archivo:                contarcl.sp                             */
/*      Stored procedure:       sp_contabilidad_rcl                     */
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
/*      Transaccion: 7416						*/
/*      EPB:mar-06-2002 actualizaciones circular 50                     */
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_rcl')
   drop proc sp_contabilidad_rcl
go

create proc sp_contabilidad_rcl
@i_criterio1	char(1)=null,
@i_criterio2	char(1)=null

as

/*TBLAS TEMOPRALES TMP */



create table #riesgo (
calificacion 	char(1),
descripcion_cal	varchar(20)
)


create table #clase (
clase	char(1),
descripcion_cla	varchar(20)
)



insert into #riesgo
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_calificacion' )



insert into #clase
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )


select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,'')


set rowcount 20

select 'Riesgo' = calificacion,
       'Clase' = clase,
       'Descripcion' = descripcion_cal + '.' + descripcion_cla
from  #riesgo,#clase
where ((calificacion = @i_criterio1 and clase > @i_criterio2) or
      (calificacion > @i_criterio1))
order by calificacion,clase

set rowcount 0

return 0

return 0
go