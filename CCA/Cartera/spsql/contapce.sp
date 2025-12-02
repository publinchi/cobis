/************************************************************************/
/*      Archivo:                contapce.sp                             */
/*      Stored procedure:       sp_contabilidad_pce                     */
/*      Base de datos:          cob_credito                             */
/*      Producto:               Credito                                 */
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
/*      BUSQUEDA RIESGO TIPO GARANTIA CLASE CARTERA                     */
/*      Transaccion: 7407						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_pce')
   drop proc sp_contabilidad_pce
go

create proc sp_contabilidad_pce
@i_criterio1	char(1)=null,
@i_criterio2	char(1)=null,
@i_criterio3	char(1)=null
as

/*TBLAS TEMOPRALES TMP */


create table #garantia (
garantia	char(1),
descripcion_gar	varchar(20)
)



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


insert into #garantia
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cu_clase_custodia' )


select @i_criterio1 = isnull(@i_criterio1,''),
       @i_criterio2 = isnull(@i_criterio2,''),
       @i_criterio3 = isnull(@i_criterio3,'')

set rowcount 20



select 'Riesgo' = calificacion,
       'Garantia' = garantia,
       'Clase' = clase,
       'Descripcion' = descripcion_cal + '.' +  descripcion_gar + '.' +  descripcion_cla 
from  #riesgo, #garantia,#clase
where ((calificacion  = @i_criterio1 and garantia = @i_criterio2 and clase > @i_criterio3) or
      (calificacion  = @i_criterio1 and garantia > @i_criterio2) or
      (calificacion > @i_criterio1))
order by calificacion, garantia ,clase

set rowcount 0

return 0
go
