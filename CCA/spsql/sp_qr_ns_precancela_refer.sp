/************************************************************************/
/*  Archivo:                sp_qr_ns_precancela_refer.sp                */
/*  Stored procedure:       sp_qr_ns_precancela_refer                   */
/*  Base de Datos:          cobis                                       */
/*  Producto:               Credito                                     */
/*  Disenado por:           P. Ortiz                                    */
/*  Fecha de Documentacion: 14/Dic/2017                                 */
/************************************************************************/
/*          IMPORTANTE                                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "MACOSA",representantes exclusivos para el Ecuador de la            */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de MACOSA o su representante                  */
/************************************************************************/
/*          PROPOSITO                                                   */
/* Procedure que permite consultar el estado de una notificación        */
/* de referencia de precancelacion                                      */
/************************************************************************/
/*          MODIFICACIONES                                              */
/*  FECHA       AUTOR                   RAZON                           */
/*  14/Dic/2017 P. Ortiz             Emision Inicial                    */
/* **********************************************************************/

USE cob_cartera
GO


IF OBJECT_ID ('dbo.sp_qr_ns_precancela_refer') IS NOT NULL
	DROP PROCEDURE dbo.sp_qr_ns_precancela_refer
GO

create proc sp_qr_ns_precancela_refer (	
	@i_operacion		char(1),
	@i_codigo 			int 	= null,
	@i_estado			char(1) = null,
	@i_operacion_banco	int 	= null
)
AS


--Consulta
if @i_operacion = 'Q'
begin
	
	select npr_codigo,
		   npr_operacion
	  from ca_ns_precancela_refer
	 where npr_estado = 'P' --Pendiente
	 
	 update ca_ns_precancela_refer
	   set npr_estado 	= 'E' --En Proceso
	 where npr_estado 	= 'P'
     
	if @@rowcount = 0
	begin 
		return 1
	end

end

--Actualiza estado
if @i_operacion = 'U'
begin
	update ca_ns_precancela_refer
	   set npr_estado 		= @i_estado
	 where npr_codigo 		= @i_codigo
	 and   npr_operacion	= @i_operacion_banco
 
end
return 0


GO

