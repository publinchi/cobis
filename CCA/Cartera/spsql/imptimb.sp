/************************************************************************/
/*	Archivo: 		imptimb.sp		 		*/
/*	Stored procedure: 	sp_impuesto_timbre 			*/
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Juan Carlos Espinosa         	        */
/*	Fecha de escritura: 	Mayo 1998                               */
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA", representantes exclusivos para el Ecuador de la 	*/
/*	"NCR CORPORATION".						*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Calcular en sp_impuesto_timbre los valores de los rubros        */
/*      anticipados                                                     */
/************************************************************************/
/*	Oct.23/98	NydiaVelasco	En cl_ente solo existe el campo */
/*					en_patrimonio_tec.Definir?	*/
/************************************************************************/  
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_impuesto_timbre')
	drop proc sp_impuesto_timbre
go
create proc sp_impuesto_timbre (
   @i_monto         money,
   @i_cliente       int,
   @i_valor         money,
   @o_valor         float = 0 out
)
as
declare	
   @w_sp_name            descripcion,
   @w_valmintimbre       money,
   @w_ingresos           money,                
   @w_limingrbrut        money,
   @w_tipo_comp          catalogo,
   @w_return             int

/*  Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_impuesto_timbre'

select  @o_valor = @i_valor

/*REVISAR SI EL CLIENTE ES COMPANIA PUBLICA*/
select 
@w_tipo_comp = c_tipo_compania,  
--@w_ingresos = en_patrimonio_bruto  NVR oct23/98
@w_ingresos = en_patrimonio_tec
from cobis..cl_ente    
where en_ente  = @i_cliente
and en_subtipo = 'C'
set transaction isolation level read uncommitted

if (@w_tipo_comp = 'B')
   select @o_valor = 0
else                             /*SI EL CLIENTE ES UNA EMPRESA PRIVADA*/
begin
   select  @w_limingrbrut = pa_money
   from    cobis..cl_parametro
   where   pa_nemonico = 'LIBT'
   and     pa_producto = 'CCA'
   set transaction isolation level read uncommitted

   select  @w_valmintimbre = pa_money
   from    cobis..cl_parametro
   where   pa_nemonico = 'VMT'
   and     pa_producto = 'CCA'
   set transaction isolation level read uncommitted

   if (isnull(@w_ingresos,0) < @w_limingrbrut and @i_monto < @w_valmintimbre)
      select @o_valor = 0
end

return 0

go
