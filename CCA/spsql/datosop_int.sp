/************************************************************************/
/*   Archivo:                datosopint.sp                              */
/*   Stored procedure:       sp_datos_operacion_int                     */
/*   Base de datos:          cob_interface                              */
/*   Producto:               Cartera                                    */
/*   Disenado por:           Guisela Fernandez                          */
/*   Fecha de escritura:     07/09/2021                                 */
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
/*   Este programa ejecuta el query de operaciones de cartera           */
/*   llamado por el SP sp_operacion_qry.   para el servicio de          */
/*   Consulta de datos de prestamos de datos adicionales                */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR             RAZON                          */
/* 07/09/2021      G. Fernandez        Emision Inicial                  */
/************************************************************************/

use cob_interface
go

if exists (select 1 from sysobjects where name = 'sp_datos_operacion_int')
   drop proc sp_datos_operacion_int
go

create proc sp_datos_operacion_int (
@s_user                  varchar(14),
@s_term                  varchar(30),
@s_date                  datetime,
@s_ofi                   smallint,
@t_trn                  INT       = NULL, --LPO CDIG Cambio de Servicios a Blis                  
@i_banco                cuenta  = null,
@i_formato_fecha        int     = null,
@i_operacion            char(1) = null
)
as

declare 
@w_sp_name             varchar(32),
@w_error               int

select
@w_sp_name = 'sp_datos_operacion_int'

if @t_trn = 77555
begin
	exec cob_cartera..sp_datos_operacion
	@t_trn            = 7020,
	@i_banco          = @i_banco,
	@i_operacion      = 'P',
	@i_formato_fecha   = @i_formato_fecha

	exec cob_cartera..sp_datos_operacion
	@t_trn            = 7020,
	@i_banco          = @i_banco,
	@i_operacion      = 'R',
	@i_formato_fecha   = @i_formato_fecha
end
else
begin
	select @w_error = 725082
	GOTO ERROR
end
return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

GO
