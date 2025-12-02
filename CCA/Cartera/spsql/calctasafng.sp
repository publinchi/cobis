/************************************************************************/
/*   Archivo:             calctasafng.sp                                 */
/*   Stored procedure:    sp_calcula_tasa_fng                           */
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
/************************************************************************/
/*            MODIFICACIONES                                            */
/*    FECHA                 AUTOR                     CAMBIO            */
/*   2014-09-24   Luis Carlos Moreno  Req436:Normalizacion Cartera      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_calcula_tasa_fng')
   drop proc sp_calcula_tasa_fng
go

create proc sp_calcula_tasa_fng
   @i_fecha_proceso  datetime,
   @i_monto_smmlv    float,
   @i_debug          char         = 'N',
   @o_tasa           float        OUTPUT
as
declare
   @w_error                int,
   @w_factor               float,
   @w_tipo                 varchar(64),
   @w_matriz               catalogo,
   @w_msg                  varchar(100)
begin
   select @w_matriz = 'COMFNGANU'

   select @w_matriz = pa_char
   from   cobis..cl_parametro (rowlock)
   where  pa_nemonico = 'COMFNG'
   and    pa_producto = 'CCA'

	select @w_factor = 0

   if @i_monto_smmlv > 0
   begin     
	   exec @w_error  = sp_matriz_valor
	        @i_matriz      = @w_matriz,      
	        @i_fecha_vig   = @i_fecha_proceso,  
	        @i_eje1        = @i_monto_smmlv,  
	        @o_valor       = @o_tasa  out, 
	        @o_msg         = @w_msg    out    
	         
	   if @w_error <> 0
         return @w_error
	end
   
   return 0
end
go
