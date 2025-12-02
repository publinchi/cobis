/************************************************************************/
/*      Archivo:                pccled.sp                               */
/*      Stored procedure:       sp_pcca_cled                            */
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
/*      Parametros para Clase y Edad Perfiles contables                 */
/************************************************************************/

use cobis
go

if exists (select 1 from sysobjects where name = 'sp_pcca_cled')
        drop proc sp_pcca_cled
go


create proc sp_pcca_cled (
@i_criterio1          varchar(10) = null
)
as

declare
@w_sp_name            varchar(32)

/* INICIALIZACION DE VARIABLES DE TRABAJO */
select @w_sp_name = 'sp_pcca_cled'

/* MOSTRAR A FRONT END LISTA DE CLASES DE CARTERA */
select 
'CODIGO'      =  convert(varchar(2),A.codigo) +';'+ 
                 convert(varchar(3), es_codigo),
'DESCRIPCION' =  A.valor +';'+  es_descripcion
from cobis..cl_catalogo A, cobis..cl_tabla B, cob_cartera..ca_estado 
where B.tabla = 'cr_clase_cartera'
and   A.tabla = B.codigo  
order by A.codigo, es_codigo

if @@rowcount = 0 begin
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 190100 
   return 1 
end

return 0
go
