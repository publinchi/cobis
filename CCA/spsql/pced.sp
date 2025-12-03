/************************************************************************/
/*      Archivo:                pced.sp                                 */
/*      Stored procedure:       sp_pcca_ed                              */
/*      Base de datos:          cobis                                   */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Enero. 1999                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".	                                                */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Parametros para Edad Perfiles contables                         */
/************************************************************************/

use cobis
go

if exists (select 1 from sysobjects where name = 'sp_pcca_ed')
        drop proc sp_pcca_ed
go


create proc sp_pcca_ed (
   @i_criterio1          varchar(10) = null
)
as

declare
   @w_sp_name            varchar(32)

/* INICIALIZACION DE VARIABLES DE TRABAJO */
select @w_sp_name = 'sp_pcca_ed'

/* MOSTRAR A FRONT END LISTA DE CLASES DE CARTERA */

select 
'CODIGO'      =  convert(varchar(2), es_codigo),
'DESCRIPCION' =  es_descripcion
from cob_cartera..ca_estado 
where es_descripcion like 'EDA%' 
order by es_codigo

if @@rowcount = 0 begin
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 190100 
   return 1 
end
                                                                                                                                                                                                                                      
return 0
go
