/************************************************************************/
/*      Archivo:                pccl.sp                                 */
/*      Stored procedure:       sp_pcca_cl                              */
/*      Base de datos:          cobis                                   */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Fabian de la Torre                      */
/*      Fecha de escritura:     Enero. 1999                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA", representantes exclusivos para el Ecuador de la       */
/*      "NCR CORPORATION".                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Parametros para Clase de cartera Perfiles contables             */
/************************************************************************/

use cobis
go

if exists (select 1 from sysobjects where name = 'sp_pcca_cl')
        drop proc sp_pcca_cl
go

create proc sp_pcca_cl (
@i_criterio1          varchar(10) = null
)
as

declare
@w_sp_name            varchar(32),
@w_rowcount           int

/* INICIALIZACION DE VARIABLES DE TRABAJO */
select @w_sp_name = 'sp_pcca_cl'

/* MOSTRAR A FRONT END LISTA DE CLASES DE CARTERA */
set rowcount 20

select 
'CODIGO'      =  A.codigo,
'DESCRIPCION' =  A.valor 
from cobis..cl_catalogo A, cobis..cl_tabla B 
where A.codigo > @i_criterio1 or @i_criterio1 is null
and   B.tabla = 'cr_clase_cartera'
and   A.tabla = B.codigo   
order by A.codigo
select @w_rowcount = @@rowcount
set transaction isolation level read uncommitted

if @w_rowcount = 0 begin
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = 190100 
   return 1 
end
                                                                                                                                                                                                                                       
return 0
go
