/************************************************************************/
/*	Archivo:		detamor.sp   				*/
/*	Stored procedure:	sp_detalle_amortizacion 		*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Credito y Cartera			*/
/*	Disenado por:  		Fabian de la Torre 		   	*/
/*	Fecha de escritura:	Mar 1999	   			*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/
/*				PROPOSITO				*/
/*	Sp Externo del detalle de pagos                                 */
/* 04/10/2010         Yecid Martinez     Fecha valor baja Intensidad    */
/*                                       NYMR 7x24                      */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_detalle_amortizacion')
	drop proc sp_detalle_amortizacion
go

create proc sp_detalle_amortizacion (
   @s_user              login       = null, --NYMR 7x24 
   @s_date              datetime    = null,
   @s_term              descripcion = null,
   @s_ofi               smallint    = null,
   @t_trn               INT         = NULL, --LPO CDIG Cambio de Servicios a Blis                  
   @i_banco             cuenta,
   @i_dividendo         int     = 0,
   @i_tipo_cobro        char(1),
   @i_tipo_proyeccion   char(1) = 'C',
   @i_tasa_prepago      float,
   @i_formato_fecha     int, 
   @i_operacion         char(1) = null,
   @i_opcion            char(1) = 'N',
   @i_fecha             datetime = null,
   @i_moneda            tinyint  = null,
   @i_vlrsec		money	 = null,
   @i_atx               char(1) = 'N' --Inc_7624
)

as declare 
   @w_sp_name         descripcion,
   @w_return          int,
   @w_error           int

/* INICIALIZACION DE VARIABLES */


select	
@w_sp_name       = 'sp_detalle_amortizacion'

exec @w_return   = sp_detalle_amortizacion_int
@s_user              = @s_user, --NYMR 7x24 
@s_term              = @s_term,
@s_date              = @s_date ,
@s_ofi               = @s_ofi,
@i_banco             = @i_banco,
@i_dividendo         = @i_dividendo,
@i_tipo_cobro        = @i_tipo_cobro,
@i_tipo_proyeccion   = @i_tipo_proyeccion,
@i_tasa_prepago      = @i_tasa_prepago,
@i_formato_fecha     = @i_formato_fecha,
@i_fecha             = @i_fecha,
@i_moneda            = @i_moneda,
@i_vlrsec	     = @i_vlrsec,
@i_atx               = @i_atx --Inc_7624

if @w_return != 0 begin 
   select @w_error = @w_return
   goto ERROR
end 


return 0

ERROR:
exec cobis..sp_cerror
@t_debug  ='N',         
@t_file   = null,
@t_from   = @w_sp_name,   
@i_num    = @w_error
--@i_cuenta = ' '

return @w_error

go
