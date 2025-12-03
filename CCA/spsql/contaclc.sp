/************************************************************************/
/*      Archivo:                contaclc.sp                             */
/*      Stored procedure:       sp_contabilidad_clc                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           E.Pelaez                                */
/*      Fecha de escritura:     Marzo  2003                             */
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
/*      cuenta definida como CL-IC (Clase deCartera  paraINT-CONTINGENT)*/
/*      Transaccion: 7408						*/
/*  									*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_clc')
   drop proc sp_contabilidad_clc
go

create proc sp_contabilidad_clc
@i_criterio1	char(1)=null
as

/*TBLAS TEMOPRALES TMP */



create table #clase (
clase	char(1),
descripcion_cla	varchar(20)
)



insert into #clase
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_clase_cartera' )


select @i_criterio1 = isnull(@i_criterio1,'')



select 'Clase'       = clase,
       'Descripcion' = descripcion_cla
from  #clase
where clase > @i_criterio1
order by clase

set rowcount 0

return 0
go