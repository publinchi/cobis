/************************************************************************/
/*   Archivo:             universo_mora.sp                              */
/*   Stored procedure:    sp_universo_mora                              */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Elcira PElaez Burbano                         */
/*   Fecha de escritura:  Oct. 2015                                     */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA".                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Procedimiento que carga un universo especifico de operaciones      */
/*   para revision de la mora en general                                */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA              AUTOR             CAMBIOS                    */
/*   22/OCt/2015   Elcira Pelaez         Universo Moras                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_universo_mora')
   drop proc sp_universo_mora
go

create proc sp_universo_mora
@i_param1      varchar(255)  = null --- castidad de operaciones por items

as
declare
@w_sec           int,
@w_concepto_mora catalogo,
@w_clase         catalogo,
@w_regsitros     int


if @i_param1 is null or @i_param1 = ''
   select @i_param1 = 50


select @w_regsitros = convert(int, @i_param1)

PRINT ''
PRINT 'Nro. de Registros por Items ' + cast (@w_regsitros as varchar )


--- CARGAR UNVERSO DE OPERACIONES VENCIDAS

select distinct  op_operacion, op_clase 
into #OperacionesVencidas
from cob_cartera..ca_operacion with (nolock),
     cob_cartera..ca_dividendo with (nolock),
     cob_cartera..ca_estado with (nolock)
where di_operacion = op_operacion
and di_estado = 2
and es_codigo = op_estado
and es_procesa ='S'

create table #ConceptosMORA (
   sec       int      identity,
   concepto  catalogo null,
   clase     catalogo null)

---CARGAR LOS CONCEPTOS DE MORA QUE HAY EN EL AMBIEBNTE

insert into  #ConceptosMORA
select  co_concepto,c.codigo
 from cob_cartera..ca_concepto,
      cobis..cl_catalogo c
where co_categoria ='M'
and   c.tabla in (select t.codigo from cobis..cl_tabla t
                    where t.tabla = 'cr_clase_cartera')

PRINT ''
PRINT '============================Items a PRocesar ==============================='
PRINT '============================================================================'
PRINT ''
select * from #ConceptosMORA


truncate table ca_universo_batch
select @w_sec      = 0
while 1 = 1 
begin

      set rowcount 1

      select @w_sec           = sec ,
             @w_concepto_mora = concepto,
			 @w_clase         = clase 
             
      from #ConceptosMORA
      where sec > @w_sec
      order by sec 

      if @@rowcount = 0 begin
         set rowcount 0
         break
      end
       
	  ---PRINT ''
	  ---PRINT ' CONCEPTO QUE VA A SER SELECCIONADO  ' + cast (  @w_concepto_mora as varchar) + 'CLASE ' + cast (@w_clase as varchar)
      set rowcount  @w_regsitros
      insert into ca_universo_batch 
      select op_operacion,  'N',   0
      from   #OperacionesVencidas,
	         cob_cartera..ca_rubro_op with (nolock)
      where  op_operacion = ro_operacion
      and    ro_concepto = @w_concepto_mora
      and    op_clase    = @w_clase
      order by op_operacion

	  set rowcount  0

     delete #OperacionesVencidas
     from ca_universo_batch 
     where op_operacion = ub_operacion

end --while   

set rowcount 0
drop table #ConceptosMORA
drop table #OperacionesVencidas

return 0
go

