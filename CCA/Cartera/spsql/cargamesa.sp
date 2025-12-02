/************************************************************************/
/*	Archivo:		cargamesa.sp				*/
/*	Stored procedure:	sp_carga_mesacambio			*/
/*	Base de datos:		cob_cartera				*/
/*	Producto: 		Cartera		  			*/
/*	Disenado por:  		Juan Sarzosa                            */
/*	Fecha de escritura:	Ene. 2001 				*/
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
/*	Cargar los datos de las transacciones para ser informados a     */
/*      Mesa de Cambio							*/
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_carga_mesacambio')
   drop proc sp_carga_mesacambio
go

create proc sp_carga_mesacambio
@i_fecha        datetime = null,
@i_banco	cuenta	 = null,
@i_tran		catalogo = null,
@i_moneda	smallint = null,
@i_monto	money    = null,
@i_cotizacion   money	 = null,
@i_monto_mn	money	 = null,
@i_en_linea	char(1)  = 'N' 
as 
declare
@w_sp_name	descripcion


/*NOMBRE DEL SP*/
select @w_sp_name = 'sp_carga_mesacambio'

/** INSERTAR LA INFORMACION **/
insert ca_mesacambio_temp(
mt_fecha,	mt_tran,	mt_moneda,
mt_monto,	mt_cotizacion,	mt_monto_mn,
mt_en_linea,	mt_banco
)
values (
@i_fecha,	@i_tran,	@i_moneda,
@i_monto,	@i_cotizacion,	@i_monto_mn,
@i_en_linea,	@i_banco
)

if @@error != 0
   return 710310

return 0
go

