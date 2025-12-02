/************************************************************************/
/*      Archivo:                consclau.sp                             */
/*      Stored procedure:       sp_consulta_clausula                    */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan Carlos Espinosa 		        */
/*      Fecha de escritura:     Mayo. 1998                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*				PROPOSITO                               */
/*	Consulta para sp interno dela clusula aceleratoria              */
/************************************************************************/


use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_consulta_clausula')
    drop proc sp_consulta_clausula
go

create proc sp_consulta_clausula (
   @i_dias_dividendo     int,
   @o_dias_a_aplicar     int = NULL out
)
as

declare
@w_sp_name            varchar(32)  /* nombre stored proc*/


select @w_sp_name = 'sp_consulta_clausula'

select                                       
@o_dias_a_aplicar       = da_dias_aceleratoria
from  ca_dias_aceleratoria                   
where da_dias_dividendo = @i_dias_dividendo  
if @@rowcount = 0 begin
   PRINT 'Mensaje de ayuda (consclau.sp) dias dividendo' + cast(@i_dias_dividendo as varchar)
   return  710092
end

return 0

go
