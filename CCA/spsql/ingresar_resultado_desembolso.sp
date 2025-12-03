/************************************************************************/
/*   Archivo:              ingresar_resultado_desembolso.sp             */
/*   Stored procedure:     sp_santander_gen_orden_dep					*/
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:                                                      */
/*   Fecha de escritura:                                                */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBIS'.                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBIS o su representante legal.           */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Guarda el resultado de los desembolsos realizados en               */
/*   banco SANTANDER MX.                                                */
/*                              CAMBIOS                                 */
/*   26/03/2018        D.Cumbal         Cambios Caso 94602              */
/************************************************************************/

USE cob_cartera
GO

IF OBJECT_ID ('dbo.sp_ingresar_resultado_desembolso') IS NOT NULL
	DROP PROCEDURE dbo.sp_ingresar_resultado_desembolso
GO

CREATE PROCEDURE sp_ingresar_resultado_desembolso
	@s_ssn int 									= null,
	@s_user login 								= null,
	@s_sesn int 								= null,
	@s_term varchar(30) 						= null,
	@s_date datetime 							= null,
	@s_srv varchar(30) 							= null,
	@s_lsrv varchar(30) 						= null,
	@s_ofi smallint 							= null,
	@s_servicio int 							= null,
	@s_cliente int 								= null,
	@s_rol smallint 							= null,
	@s_culture varchar(10) 						= null,
	@s_org char(1) 								= null,
	@i_rd_nombre_archivo [varchar](40) 			= null,
	@i_rd_secuencial [varchar](7) 				= null,
	@i_rd_fecha_transferencia [varchar](8) 		= null,
	@i_rd_monto [varchar](15) 					= null,
	@i_rd_cuenta_ordenante [varchar](20) 		= null,
	@i_rd_nombre_ordenante [varchar](40) 		= null,
	@i_rd_rfc_ordenante [varchar](18) 			= null,
	@i_rd_cuenta_beneficiario [varchar](20) 	= null,
	@i_rd_nombre_beneficiario [varchar](40) 	= null,
	@i_rd_rfc_beneficiario [varchar](18) 		= null,
	@i_rd_referencia_servicio [varchar](40) 	= null,
	@i_rd_referencia_ordenante [varchar](40)	= null,
	@i_rd_motivo_devolucion [varchar](2) 		= null,
	@i_rd_causa_rechazo [varchar](2) 			= null,
	@i_rd_descripcion_referencia [varchar](30) 	= null,
	@i_rd_banco                  [varchar](24) 	= null,
	@i_operacion char(1)
AS

declare 
@w_error             int

BEGIN

IF @i_operacion = 'I' 
BEGIN

	--Intersecta fallidos para reintento de dispersion
	if @i_rd_causa_rechazo != '00' begin
		exec @w_error     	= sp_santander_orden_dep_fallido
		@i_operacion		= 'I',
		@i_fecha 			= @i_rd_fecha_transferencia,
		@i_referencia 		= @i_rd_descripcion_referencia,
		@i_causa_rechazo 	= @i_rd_causa_rechazo
		
		if @w_error <> 0 begin
           EXEC cobis..sp_cerror 
				@t_from = 'sp_ingresar_resultado_desembolso',
				@i_num = 999,
				@i_msg = 'Error al ejeutar sp_santander_orden_dep_fallido'
		   RETURN @@ERROR
        end
	end
	
     select @i_rd_banco = ltrim(rtrim(@i_rd_banco))

	INSERT INTO ca_santander_resultado_desembolso
	(
		[rd_nombre_archivo],
		[rd_secuencial],
		[rd_fecha_transferencia],
		[rd_monto],
		[rd_cuenta_ordenante],
		[rd_nombre_ordenante],
		[rd_rfc_ordenante],
		[rd_cuenta_beneficiario],
		[rd_nombre_beneficiario],
		[rd_rfc_beneficiario],
		[rd_referencia_servicio],
		[rd_referencia_ordenante],	 
		[rd_causa_rechazo],
		[rd_descripcion_referencia],
		[rd_banco]
	)
	VALUES
	(
		@i_rd_nombre_archivo,
		@i_rd_secuencial,
		@i_rd_fecha_transferencia,
		@i_rd_monto,
		@i_rd_cuenta_ordenante,
		@i_rd_nombre_ordenante,
		@i_rd_rfc_ordenante,
		@i_rd_cuenta_beneficiario,
		@i_rd_nombre_beneficiario,
		@i_rd_rfc_beneficiario,
		@i_rd_referencia_servicio,
		@i_rd_referencia_ordenante,	   
		@i_rd_causa_rechazo,
		@i_rd_descripcion_referencia,
		@i_rd_banco
	)

	IF @@ERROR <> 0
	BEGIN
		EXEC cobis..sp_cerror 
			@t_from = 'sp_ingresar_resultado_desembolso',
			@i_num = 999,
			@i_msg = 'Error al registrar resultado de Desembolso'
		RETURN @@ERROR
	END
	
END

IF @i_operacion = 'U'
BEGIN
	
	if @i_rd_motivo_devolucion != '00' begin
		exec @w_error     	= sp_santander_orden_dep_fallido
		@i_operacion		= 'I',
		@i_fecha 			= @i_rd_fecha_transferencia,
		@i_referencia 		= @i_rd_descripcion_referencia,
		@i_causa_rechazo 	= @i_rd_causa_rechazo
		
		if @w_error <> 0 begin
           EXEC cobis..sp_cerror 
				@t_from = 'sp_ingresar_resultado_desembolso',
				@i_num = 999,
				@i_msg = 'Error al ejeutar sp_santander_orden_dep_fallido'
		   RETURN @@ERROR
        end
	end
	
	UPDATE ca_santander_resultado_desembolso
	SET  
		rd_motivo_devolucion 		= @i_rd_motivo_devolucion
	   
	WHERE rd_nombre_archivo 		= @i_rd_nombre_archivo
	AND   rd_secuencial 			= @i_rd_secuencial
   
  

	IF @@ERROR <> 0
	BEGIN
		EXEC cobis..sp_cerror 
			@t_from = 'sp_ingresar_resultado_desembolso',
			@i_num = 999,
			@i_msg = 'Error al actualizar resultado de Desembolso'
		RETURN @@ERROR
	END


END

	RETURN 0

END
GO

