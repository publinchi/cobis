USE cob_cartera
GO

IF OBJECT_ID ('dbo.sp_ingresar_resultado_cobro') IS NOT NULL
	DROP PROCEDURE dbo.sp_ingresar_resultado_cobro
GO

CREATE PROCEDURE sp_ingresar_resultado_cobro
	@s_ssn int = null,
	@s_user login = null,
	@s_sesn int = null,
	@s_term varchar(30) = null,
	@s_date datetime = null,
	@s_srv varchar(30) = null,
	@s_lsrv varchar(30) = null,
	@s_ofi smallint = null,
	@s_servicio int = null,
	@s_cliente int = null,
	@s_rol smallint = null,
	@s_culture varchar(10) = null,
	@s_org char(1) = null,

	@i_sl_secuencial int,
	@i_sl_fecha_gen_orden datetime,
	@i_sl_monto_pag money,
	@i_sl_estado_cobis catalogo = NULL,
	@i_sl_estado_santander catalogo,
	@i_sl_mensaje_err_cobis descripcion = NULL,
	@i_sl_mensaje_err_std descripcion = NULL
AS
BEGIN
	INSERT INTO cob_cartera.dbo.ca_santander_log_pagos
	(
		sl_secuencial, 
		sl_fecha_gen_orden, 
		sl_monto_pag, 
		sl_estado_cobis, 
		sl_estado_santander, 
		sl_mensaje_err_cobis, 
		sl_mensaje_err_std
	)
	VALUES
	(
		@i_sl_secuencial,
		@i_sl_fecha_gen_orden,
		@i_sl_monto_pag,
		@i_sl_estado_cobis,
		@i_sl_estado_santander,
		@i_sl_mensaje_err_cobis,
		@i_sl_mensaje_err_std
	)

	IF @@ERROR <> 0
	BEGIN
		EXEC cobis..sp_cerror 
			@t_from = 'sp_ingresar_resultado_cobro',
			@i_num = 999,
			@i_msg = 'Error al registrar resultado de Cobro'
		RETURN @@ERROR
	END
	ELSE
		RETURN 0

END

GO


