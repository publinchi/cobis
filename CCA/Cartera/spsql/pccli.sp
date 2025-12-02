/************************************************************************/
/*      Archivo:                pccli.sp                                */
/*      Stored procedure:       sp_pcca_cli                             */
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
/*      Parametros para Clientes Fomento Perfiles contables             */
/************************************************************************/

use cobis
go

if exists (select 1 from sysobjects where name = 'sp_pcca_cli')
        drop proc sp_pcca_cli
go

create proc sp_pcca_cli (
@i_criterio1          varchar(10) = null
)
as

declare
@w_sp_name            varchar(32),
@w_rowcount           int

/* INICIALIZACION DE VARIABLES DE TRABAJO */
select @w_sp_name = 'sp_pcca_cli'

/* MOSTRAR A FRONT END LISTA DE CLASES DE CARTERA */
set rowcount 20

select 
'CODIGO'      =  en_ente,
'DESCRIPCION' =  en_nombre
from cobis..cl_ente
where en_ente >  convert(int, isnull(@i_criterio1,'0'))
order by en_ente
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
