/************************************************************************/
/*   Archivo:              garantias_especiales.sp                      */
/*   Stored procedure:     sp_gar_esp_tramite                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         EPB                                          */
/*   Fecha de escritura:   Mayo/2007                                    */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                           PROPOSITO                                  */
/*   Procedimiento que carga datos para la generacionde reportes        */
/*   para el FNG Unicamente procesa operaciones que tengan el rubro     */
/*   comision FNG en cualquiera de sus modalidades                      */
/************************************************************************/
/*                              CAMBIOS                                 */
/*      FECHA                   AUTOR         CAMBIO                    */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = "sp_gar_esp_tramite")
   drop proc sp_gar_esp_tramite
go

create proc sp_gar_esp_tramite 

as
declare
@w_tipo_esp                 catalogo

begin

   select @w_tipo_esp = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'GAR'
   and    pa_nemonico   = 'GARESP'   
   set transaction isolation level read uncommitted
   
   delete tmp_gar_especial WHERE ge_tipo IS NOT NULL
      
   insert into tmp_gar_especial
   select tc_tipo 
   from   cob_custodia..cu_tipo_custodia
   where  tc_tipo  = @w_tipo_esp
   union
   select tc_tipo 
   from   cob_custodia..cu_tipo_custodia
   where  tc_tipo_superior  = @w_tipo_esp
   union
   select tc_tipo 
   from   cob_custodia..cu_tipo_custodia
   where  tc_tipo_superior in (select tc_tipo from cob_custodia..cu_tipo_custodia
                               where  tc_tipo_superior = @w_tipo_esp)
end



return 0
go