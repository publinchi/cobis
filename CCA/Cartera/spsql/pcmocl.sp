/************************************************************************/
/*      Archivo:                pcmocl.sp                               */
/*      Stored procedure:       sp_pcca_mocl                            */
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
/*      Parametros para moneda y clase Perfiles contables               */
/************************************************************************/

use cobis
go

if exists (select 1 from sysobjects where name = 'sp_pcca_mocl')
        drop proc sp_pcca_mocl
go

create proc sp_pcca_mocl (
@i_criterio1          varchar(10) = null
)
as

declare
@w_sp_name            varchar(32),
@w_rowcount           int

/* INICIALIZACION DE VARIABLES DE TRABAJO */
select @w_sp_name = 'sp_pcca_mocl'

/* MOSTRAR A FRONT END LISTA DE CLASES DE CARTERA */
select 
'CODIGO'      =  rtrim(A.codigo) + ';'+ C.codigo,
'DESCRIPCION' =  A.valor  + ';'+ C.valor 
from cobis..cl_catalogo A, cobis..cl_tabla B, 
     cobis..cl_catalogo C, cobis..cl_tabla D
where  B.tabla = 'cl_moneda'
and    A.tabla = B.codigo   
and    D.tabla = 'cr_clase_cartera'
and    C.tabla = D.codigo   
order by A.codigo, C.codigo
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
