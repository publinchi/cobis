/************************************************************************/
/*      Archivo:                contacga.sp                             */
/*      Stored procedure:       sp_contabilidad_cga                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Epelaez                                 */
/*      Fecha de escritura:     Feb 2002                                */
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
/*      cuenta definida como CL_RI    (Clase de carera,Riesgo           */
/*      Transaccion: 7414						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_cga')
   drop proc sp_contabilidad_cga
go

create proc sp_contabilidad_cga
@i_criterio1	char(1)=null,
@i_criterio2	char(1)=null
as

/*TBLAS TEMOPRALES TMP */

create table #clase (
clase	char(1),
descripcion_cla	varchar(20)
)



create table #riesgo (
calificacion 	char(1),
descripcion_cal	varchar(20)
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



select 'Clase' = clase,
       'Riesgo' = calificacion,
       'Descripcion' = descripcion_cla + '.' + descripcion_cal 
from  #riesgo, #clase
where ((clase = @i_criterio1 and calificacion > @i_criterio2 ) or
      (clase > @i_criterio1))
order by clase,calificacion


set rowcount 0

return 0
go