/************************************************************************/
/*   Archivo:             normherdif.sp                                 */
/*   Stored procedure:    sp_norm_herencia_diferidos                    */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Fabian Gregorio Quintero De La Espriella      */
/*   Fecha de escritura:  2014/11                                       */
/*   Nro. de SP        :  12                                            */
/************************************************************************/
/*            IMPORTANTE						                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/*            PROPOSITO                                                 */
/*   Realiza la herencia de diferidos para operaciones nuevas           */
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA       AUTOR       CAMBIO                                    */
/*   2014-11-05   F.Quintero  Req436:Normalizacion Cartera              */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_norm_herencia_diferidos')
   drop proc sp_norm_herencia_diferidos
go

create proc sp_norm_herencia_diferidos
@i_tramite           int

as
declare
   @w_error          int,
   @w_op_estado      int,
   @w_op_operacion   int
begin
   select @w_op_operacion  = op_operacion,
          @w_op_estado     = op_estado
   from   ca_operacion
   where  op_tramite = @i_tramite

   if @@ROWCOUNT = 0
      return 70012001 -- LA NUEVA OPERACION NO SE ENCUENTRA

   if @w_op_estado <> 0
   begin
      return 70012002 -- ESTADO NO VALIDO DE LA OPERACION NUEVA
   end

   if exists(select 1
             from   ca_diferidos
             where  dif_operacion = @w_op_operacion)
   begin
      return 70012003 -- LA OPERACION NUEVA YA TIENE DIFERIDOS, NO PUEDE HEREDAR
   end

   insert into ca_diferidos
         (dif_operacion, dif_concepto, dif_valor_total, dif_valor_pagado)
   select @w_op_operacion,
          dif.dif_concepto,
          total = sum(dif_valor_total - dif_valor_pagado),
          pagado = sum(0)
   from   cob_credito..cr_normalizacion,
          cob_cartera..ca_operacion odif,
          cob_cartera..ca_diferidos dif
   where  nm_tramite = @i_tramite
   and    odif.op_banco = nm_operacion
   and    odif.op_estado in (1, 2, 4, 9)
   and    dif_operacion = odif.op_operacion
   group  by dif.dif_concepto

   /*delete ca_diferidos
   from   cob_credito..cr_normalizacion,
          cob_cartera..ca_operacion odif
   where  nm_tramite = @i_tramite
   and    odif.op_banco = nm_operacion
   and    odif.op_estado in (1, 2, 4, 9)
   and    dif_operacion = odif.op_operacion*/
end
go

