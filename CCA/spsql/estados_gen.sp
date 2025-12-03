/*estados_cca.sp*********************************************************/
/*   Archivo:             estados_gen.sp                                */
/*   Stored procedure:    sp_estados                                    */
/*   Base de datos:       cob_externos                                  */
/*   Producto:            Estados                                       */
/*   Disenado por:        Pedro Rafael Montenegro Rosales               */
/*   Fecha de escritura:  08/Dic/2016                                   */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Retorna los codigos de los estados de un producto en especifico.   */
/************************************************************************/

use cob_externos
go
 
if exists (select 1 from sysobjects where name = 'sp_estados')
   drop proc sp_estados
go
 
create proc sp_estados
@i_producto       tinyint,
@o_est_novigente  tinyint = null out,
@o_est_vigente    tinyint = null out,
@o_est_vencido    tinyint = null out,
@o_est_cancelado  tinyint = null out,
@o_est_castigado  tinyint = null out,
@o_est_diferido   tinyint = null out,
@o_est_anulado    tinyint = null out,
@o_est_condonado  tinyint = null out,
@o_est_suspenso   tinyint = null out,
@o_est_credito    tinyint = null out
as
declare @w_error int

select @w_error = 0

if (@i_producto = 7)
begin
   --CONSULTAR ESTADO VENCIDO/VIGENTE PARA CARTERA
   exec @w_error = cob_cartera..sp_estados_cca
         @o_est_novigente  = @o_est_novigente out,
         @o_est_vigente    = @o_est_vigente out,
         @o_est_vencido    = @o_est_vencido out,
         @o_est_cancelado  = @o_est_cancelado out,
         @o_est_castigado  = @o_est_castigado out,
         @o_est_diferido   = @o_est_diferido out,
         @o_est_anulado    = @o_est_anulado out,
         @o_est_condonado  = @o_est_condonado out,
         @o_est_suspenso   = @o_est_suspenso out,
         @o_est_credito    = @o_est_credito out
end

return @w_error

go
 