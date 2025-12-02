/***********************************************************************/
/*   Archivo:             validaperf.sp                                */
/*   Stored procedure:    sp_valida_perfeccionamiento                  */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Luis Carlos Moreno                            */
/*   Fecha de escritura:  2014/10                                       */
/************************************************************************/
/*            IMPORTANTE                                                */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Realiza validaciones específicas del perfeccionamiento de la       */
/*   Normalizacion                                                      */ 
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA                 AUTOR                     CAMBIO            */
/*   2014-09-24   Luis Carlos Moreno  Req436:Normalizacion Cartera      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_valida_perfeccionamiento')
   drop proc sp_valida_perfeccionamiento
go

create proc sp_valida_perfeccionamiento
   @s_user           login        = null,
   @s_ofi            smallint     = null,
   @s_term           varchar(30)  = null,
   @s_date           datetime     = null,
   @i_tramite        int,
   @i_momento_perf   catalogo,
   @i_debug          char         = 'N'
as
declare
   @w_error    int
begin
   if @i_momento_perf = 'CANCELADAS'
   begin
      if exists(select 1
                from   cob_credito..cr_normalizacion,
                       ca_operacion
                where  nm_tramite = @i_tramite
                and    op_banco = nm_operacion
                and    op_estado != 3)
      begin
         return 70012001
      end
   end
end
go
