
/************************************************************************/
/*  Archivo:                sp_pagos_procesados.sp                      */
/*  Stored procedure:       sp_pagos_procesados                         */
/*  Base de Datos:          cob_cartera                                 */
/*  Producto:               Cartera                                     */
/*  Disenado por:           Nelson Trujillo                             */
/*  Fecha de Documentacion: 15/JAN/2018                                 */
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
/* Opcion Q Realiza consulta de pago procesado Santander   	            */
/* Opcion I Realiza el registro de pago procesado Santander             */
/************************************************************************/
/*          MODIFICACIONES                                              */
/*  FECHA       AUTOR                   RAZON                           */
/*  												                    */
/* **********************************************************************/
USE cob_cartera
GO

if exists(select 1 from sysobjects where name ='sp_pagos_procesados')
	drop proc sp_pagos_procesados
GO


CREATE proc sp_pagos_procesados
	@s_ssn 				int				= null,
	@s_user 			login			= null,
	@s_sesn 			int   			= null,
	@s_term 			varchar(30)		= null,
	@s_date 			datetime		= null,
	@s_srv 				varchar(30)		= null,
	@s_lsrv 			varchar(30) 	= null,
	@s_ofi 				smallint		= null,
	@s_servicio 		int				= null,
	@s_cliente 			int				= null,
	@s_rol 				smallint		= null,
	@s_culture 			varchar(10)		= null,
	@s_org 				char(1)			= null,
	@i_fecha_pago 		varchar(8)      = null,
	@i_nombre_archivo 	varchar(64)     = null,
	@i_referencia 		VARCHAR(64), 
	@i_movimiento 		varchar(64),
	@i_cuenta 			cuenta,	
	@i_operacion 		char(1),
	@i_trn_id_corresp   varchar(8)      = NULL,
	@i_accion           char(1)         = NULL,
	@i_monto_pago       varchar(14)     = null,
    @o_row_count	   	int 			= 0 OUTPUT
AS
BEGIN

	IF @i_operacion = 'I' 
	BEGIN
	
	    if @i_trn_id_corresp is not null and  @i_trn_id_corresp <> '00000000' begin
	  	INSERT INTO ca_santander_pagos_procesados
	  	   (pp_cuenta, pp_referencia, pp_movimiento, pp_fecha_pago, pp_archivo, pp_fecha_proceso, pp_trn_id_corresp, pp_monto_pago)
	  	VALUES
	  	   (@i_cuenta, @i_referencia, @i_movimiento, @i_fecha_pago, @i_nombre_archivo, getdate(), @i_trn_id_corresp, convert(money,isnull(@i_monto_pago,0))/100)
	
		IF @@ERROR <> 0
		BEGIN
			EXEC cobis..sp_cerror 
				@t_from = 'sp_pagos_procesados',
				@i_num = 999,
				@i_msg = 'Error al insertar pago procesadoo reverso'
			RETURN @@ERROR
		END
		end
		else begin
		   EXEC cobis..sp_cerror 
		   	   	@t_from = 'sp_pagos_procesados',
		   	   	@i_num = 999,
		   	   	@i_msg = 'Referencia externa vacía o igual a 0'
		  RETURN @@ERROR
		end
		
	END

	IF @i_operacion = 'Q' 
	BEGIN
	
	   if @i_accion = 'I' or @i_accion is null begin
		SELECT  'referencia' = pp_referencia,
				'cuenta' 	 = pp_cuenta,
				'fecha' 	 = pp_fecha_pago,
				'movimiento' = pp_movimiento	
		FROM ca_santander_pagos_procesados
		WHERE pp_cuenta     = @i_cuenta
		and   pp_referencia = @i_referencia
		and   pp_movimiento = @i_movimiento

	
		IF @@ERROR <> 0
		BEGIN
			EXEC cobis..sp_cerror 
				@t_from = 'sp_pagos_procesados',
				@i_num = 999,
				@i_msg = 'Error al consultar pago procesado'
			RETURN @@ERROR
		END
		
		SELECT  @o_row_count = count(1)
		FROM ca_santander_pagos_procesados
		WHERE pp_cuenta     = @i_cuenta
		and   pp_referencia = @i_referencia
		and   pp_movimiento = @i_movimiento
          
		  
		  
		  IF @@ERROR <> 0
		  BEGIN
		  	EXEC cobis..sp_cerror 
		  		@t_from = 'sp_pagos_procesados',
		  		@i_num = 999,
		  		@i_msg = 'Error al consultar pago procesado'
		  	RETURN @@ERROR
		  END
	  end 
	  else if @i_accion = 'R' begin
	     SELECT  'referencia'     = pp_referencia,
		  		 'cuenta' 	      = pp_cuenta,
		  		 'fecha' 	      = pp_fecha_pago,
		  		 'movimiento'     = pp_movimiento	
		  FROM ca_santander_pagos_procesados
		  WHERE pp_cuenta         = @i_cuenta
		  and   pp_trn_id_corresp = @i_trn_id_corresp
		  and  (pp_referencia     = '' or pp_referencia is null)
		  and  pp_monto_pago      = convert(money,isnull(@i_monto_pago,0))/100
		
		
		IF @@ERROR <> 0
		BEGIN
			EXEC cobis..sp_cerror 
				@t_from = 'sp_pagos_procesados',
				@i_num = 999,
				@i_msg = 'Error al consultar el reverso'
			RETURN @@ERROR
		END
		
		  SELECT  @o_row_count    = count(1)
		  FROM ca_santander_pagos_procesados
		  WHERE pp_cuenta         = @i_cuenta
		  and   pp_trn_id_corresp = @i_trn_id_corresp
		  and  (pp_referencia     = '' or pp_referencia is null)  
          and  pp_monto_pago      = convert(money,isnull(@i_monto_pago,0))/100		  
		  
		  
		  IF @@ERROR <> 0
		  BEGIN
		  	EXEC cobis..sp_cerror 
		  		@t_from = 'sp_pagos_procesados',
		  		@i_num = 999,
		  		@i_msg = 'Error al consultar el reverso'
		  	RETURN @@ERROR
		  END
	  end
	END
	  



	RETURN 0

END
GO

