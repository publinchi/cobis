/************************************************************************/
/*      Archivo:                contarie.sp                             */
/*      Stored procedure:       sp_contabilidad_rie                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Epelaez                                 */
/*      Fecha de escritura:     Mar 2002                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera el catalog de riesgo (calificacion)			*/
/*      Transaccion: 7413						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_rie')
   drop proc sp_contabilidad_rie
go

create proc sp_contabilidad_rie
@i_criterio1	char(1)=null
as

/*TBLAS TEMOPRALES TMP */


create table #riesgo (
calificacion 	char(1),
descripcion_cal	varchar(20)
)

insert into #riesgo
select codigo,valor
from cobis..cl_catalogo
where tabla = (select codigo from cobis..cl_tabla where tabla =  'cr_calificacion' )



select @i_criterio1 = isnull(@i_criterio1,'')

set rowcount 20



select 'Riesgo' = calificacion,
       'Descripcion' = descripcion_cal 
from  #riesgo
where (calificacion = @i_criterio1) or
      (calificacion > @i_criterio1)
order by calificacion


set rowcount 0

return 0
go