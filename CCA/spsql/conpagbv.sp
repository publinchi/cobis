/************************************************************************/
/*	Archivo: 		conpagbv.sp				*/
/*	Stored procedure: 	sp_consulta_pago_bv 			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Juan Sarzosa				*/
/*	Fecha de escritura: 	ENERO 2001				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".						        */
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Consulta los pagos de una operacion 	                 	*/
/************************************************************************/
/*                            MODIFICACIONES                            */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_consulta_pago_bv')
   drop proc sp_consulta_pago_bv
go

create proc sp_consulta_pago_bv (
	@i_banco		cuenta	= null,
	@i_formato_fecha	int	= null,
        @i_secuencial_ing       int     = 0,
        @i_operacion 		char(1)
)
as

declare @w_return int,
        @w_sp_name varchar(32),
        @w_op_bvirtual char(1)
 
/* Captura nombre de Stored Procedure  */
select @w_sp_name = 'sp_consulta_pago_bv'

/*Verificar que la operaci¢n permita procesamiento virtual */
select @w_op_bvirtual = op_bvirtual 
from ca_operacion 
where op_banco = @i_banco
if @@rowcount = 0
begin
   select @w_return = 710022
   goto ERROR
end 


if @w_op_bvirtual = 'S' begin
 exec @w_return    = sp_datos_operacion 
 @i_operacion      = @i_operacion,
 @i_banco          = @i_banco,
 @i_formato_fecha  = @i_formato_fecha,
 @i_secuencial_ing = @i_secuencial_ing
end
else begin
  select @w_return = 710203
  goto ERROR
end

return 0

ERROR:
exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_return
return @w_return




