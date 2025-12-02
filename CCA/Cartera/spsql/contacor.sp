/************************************************************************/
/*      Archivo:                contacor.sp                             */
/*      Stored procedure:       sp_contabilidad_cor                     */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           E.PElaez                                */
/*      Fecha de escritura:     Agosto 2001                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Genera las combinaciones de valores para la parte variable de   */
/*      BUSQUEDA PROGRAMA CARTERA PASIVA FINAGRO		        */
/*      Transaccion: 7405						*/
/************************************************************************/

use cobis
go


if exists (select 1 from sysobjects where name = 'sp_contabilidad_cor')
   drop proc sp_contabilidad_cor
go

create proc sp_contabilidad_cor
@i_criterio1	varchar(10)= null
as


select @i_criterio1 = isnull(@i_criterio1,'')

set rowcount 20

select 'Tipo' = C.codigo,
       'Entidad' = '224',
       'Descripcion' = C.valor + '.' + 'FINAGRO'
from   cl_tabla T, cl_catalogo C
where  T.tabla = 'ca_subtipo_linea'
and    T.codigo = C.tabla
and    C.codigo > @i_criterio1
order by C.codigo

set rowcount 0

return 0
go

--exec sp_contabilidad_cor
