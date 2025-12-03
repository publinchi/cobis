/************************************************************************/
/*      Archivo:                contacat.sp                             */
/*      Stored procedure:       sp_contabilidad_cat                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           E.pelaez                                */
/*      Fecha de escritura:     mar.2003                                */
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
/*      BUSQUEDA ENTIDAD PRESTAMISTA                                    */
/*      Parametro : EP-CXP						*/
/*      Transaccion: 7401						*/
/************************************************************************/

use cobis
go

if exists (select 1 from sysobjects where name = 'sp_contabilidad_cat')
   drop proc sp_contabilidad_cat
go

create proc sp_contabilidad_cat
@i_criterio1	char(10)=null
as


/*TBLAS TEMOPRALES TMP */

create table #entidad(
entidad	char(10),
descripcion_ent	varchar(45)
)


/*create table #programa (
programa 	char(10),
descripcion_org	varchar(45)
)*/



insert into #entidad
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_tipo_linea' )


/*insert into #programa
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'ca_subtipo_linea' )*/


select @i_criterio1 = isnull(@i_criterio1,'')


set rowcount 20

select 'Entidad Prestamista' = entidad,
       'Descripcion' =  descripcion_ent 
from  #entidad
where  entidad > @i_criterio1
order by entidad


set rowcount 0

return 0
go