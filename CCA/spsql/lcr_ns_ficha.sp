USE cob_cartera
GO
/* ********************************************************************* */
/*      Archivo:                lcr_ns_ficha.sp                        */
/*      Stored procedure:       sp_lcr_ns_ficha_pago                     */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Tania Baidal                             */
/*      Fecha de escritura:     01/19/2018                               */
/* ********************************************************************* */
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      "MACOSA", representantes exclusivos para el Ecuador de la        */
/*      "NCR CORPORATION".                                               */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de MACOSA o su representante.              */
/* ********************************************************************* */
/*                              PROPOSITO                                */
/*   Actualiza estados de las notificaciones                             */
/* ********************************************************************* */


if exists (select 1 from sysobjects where name = 'sp_lcr_ns_ficha_pago')
   drop proc sp_lcr_ns_ficha_pago
go
create proc sp_lcr_ns_ficha_pago(
	@i_operacion		char(1),
	@i_codigo 			int 	= null,
	@i_estado			char(1) = null,
	@i_operacion_banco	int 	= null
)
AS

--Consulta
if @i_operacion = 'Q'
begin
	
	select
	nlr_codigo,
	nlr_operacion
	from ca_ns_lcr_referencia
	where nlr_estado = 'P'--Pendiente
	 
	update ca_ns_lcr_referencia
	set nlr_estado 	 = 'E' --En Proceso
	where nlr_estado = 'P'
    
	if @@rowcount = 0
	begin
		return 1
	end

end

--Actualiza estado
if @i_operacion = 'U'
begin
	update ca_ns_lcr_referencia
	   set nlr_estado 		= @i_estado
	 where nlr_codigo 		= @i_codigo
	 and   nlr_operacion	= @i_operacion_banco
 
end
return 0
