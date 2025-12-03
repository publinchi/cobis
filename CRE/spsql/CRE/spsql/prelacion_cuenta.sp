/************************************************************************/
/*  Archivo:                prelacion_cuenta.sp                         */
/*  Stored procedure:       sp_prelacion_cuenta                         */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           JOSE ESCOBAR                                */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          jfescobar        Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_prelacion_cuenta')
    drop proc sp_prelacion_cuenta
go

CREATE proc sp_prelacion_cuenta
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
	@i_operacion char(1)
AS
BEGIN

	IF @i_operacion = 'Q' 
	BEGIN
	
		SELECT  'producto' 		= pc_producto,
				'subproducto' 	= pc_subproducto,
				'nivel' 		= pc_nivel,
				'prioridad' 	= pn_prioridad		
		FROM cr_prelacion_cuenta c
		INNER JOIN cr_prelacion_nivel n
		ON c.pc_nivel = n.pn_nivel
		order by n.pn_prioridad

	
		IF @@ERROR <> 0
		BEGIN
			EXEC cobis..sp_cerror 
				@t_from = 'sp_prelacion_cuenta',
				@i_num = 999,
				@i_msg = 'Error al consultar parametrización niveles prelacion cuenta'
			RETURN @@ERROR
		END
		
	END


	RETURN 0

END
go
