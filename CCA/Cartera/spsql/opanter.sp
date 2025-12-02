/************************************************************************/
/*   Archivo:             opanter.sp                                    */
/*   Stored procedure:    sp_op_anterior                                */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Juan Bernardo Quinche                         */
/*   Fecha de escritura:  JUN-18-2008                                   */
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
/*   Este programa busca las operaciones anteriores de un credito       */
/*   y las concatena si son varias. STORED PROCEDURE RECURSIVO          */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR             RAZON                          */
/************************************************************************/  

use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_op_anterior')
   drop proc sp_op_anterior
go
create proc sp_op_anterior (
      @i_banco              cuenta = null,
      @o_anterior     varchar(1024) = null out
      
      )
as
declare @w_credito      cuenta,
        @w_op_anterior  varchar(1024)
        
        
select @w_credito = op_anterior
from   ca_operacion
where  op_banco = @i_banco

if ((@w_credito is null) or (@w_credito = ''))
   select @o_anterior = '' 
else
   begin
      execute  sp_op_anterior
               @i_banco    = @w_credito,
               @o_anterior = @w_op_anterior out
               
      if @w_op_anterior = ''
         select @o_anterior = rtrim(@w_credito)
      else
         select @o_anterior = rtrim(@w_credito) +' ; '+ rtrim(@w_op_anterior)
   end
return 0
   