/****************************************************************************/
/*   Archivo:                 camestcob.sp                                  */
/*   Stored procedure:        sp_cambio_estado_cobranza                     */
/*   Base de datos:           cob_cartera                                   */
/*   Producto:                Cartera                                       */
/*   Disenado por:            Sandra Mora R.                                */
/*   Fecha de escritura:      Dic.15 de 2006                                */
/****************************************************************************/
/*                           IMPORTANTE                                     */
/*   Este programa es parte de los paquetes bancarios propiedad de 'MACOSA'.*/                                                             
/*   Su uso no autorizado queda expresamente prohibido asi como cualquier   */ 
/*   alteracion o agregado hecho por alguno de sus usuarios sin el debido   */
/*   consentimiento por escrito de la Presidencia Ejecutiva de MACOSA o su  */
/*   representante.                                                         */
/****************************************************************************/
/*                           PROPOSITO                                      */
/*   Coloca al cliente y sus obligaciones activas en un estado pre-jurídico */
/*   especial con la marca de prepago por cobro jurídico a la obligación    */
/*   pasiva para que se realice el prepago automático                       */
/****************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_cambio_estado_cobranza')
   drop proc sp_cambio_estado_cobranza
go

create proc sp_cambio_estado_cobranza
   @i_banco             cuenta,
   @i_estado_cobranza   catalogo
as
declare
   @w_error             int,
   @w_op_estado         tinyint

   
   select @w_op_estado    = op_estado -- Se obtiene el op_estado de la obligación 
   from   ca_operacion
   where op_banco         = @i_banco
   
   if @@rowcount = 0
   begin
      select @w_error = 701049
      return @w_error
   end
      
   if @w_op_estado not in (1,2,4,9)
   begin
      select @w_error = 710563
      return @w_error
   end
   
   select 1 from cobis..cl_tabla T,
   	            cobis..cl_catalogo C
   where T.tabla  = 'cr_estado_cobranza'
   and	  T.codigo = C.tabla
   and	  C.codigo = @i_estado_cobranza
   
   if @@rowcount = 0 -- Si el @i_estado_cobranza no esta definido en el catalogo cr_estado_cobranza devuelve código de error 
   begin
      select @w_error = 15100034 
      return @w_error
   end

   BEGIN TRAN   
      update ca_operacion_tmp set opt_estado_cobranza = @i_estado_cobranza --Actualiza el op_estado_cobranza 
      where opt_banco = @i_banco
      
      if @@error != 0
      begin
         return 15100035
      end
      
      update ca_operacion set op_estado_cobranza = @i_estado_cobranza --Actualiza el op_estado_cobranza 
      where op_banco = @i_banco
      
      if @@error != 0
      begin
         return 15100036
      end
      
      update ca_operacion_his set oph_estado_cobranza = @i_estado_cobranza --Actualizar el op_estado_cobranza 
      where oph_banco = @i_banco
      
      if @@error != 0
      begin
         return 15100037
      end
      
      update cob_cartera_his..ca_operacion_his set oph_estado_cobranza = @i_estado_cobranza --Actualizar el op_estado_cobranza 
      where oph_banco = @i_banco
      
      if @@error != 0
      begin
         return 15100038
      end
   COMMIT TRAN   
return 0
