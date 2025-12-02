/************************************************************************/
/*  Archivo:                genera_data_provision.sp                    */
/*  Stored procedure:       sp_genera_data_provision                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
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
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_genera_data_provision')
    drop proc sp_genera_data_provision
go

create proc sp_genera_data_provision(

	@i_param1 			INT,
	@i_param2			INT,
	@i_param3			CHAR(2),
	@i_param4			MONEY,
	@i_param5			MONEY,
	@i_param6			CHAR(2)
	
)
AS
DECLARE @w_fecha 	DATETIME



SELECT @w_fecha = fp_fecha FROM cobis..ba_fecha_proceso

IF @i_param3 = 'W'
begin
	SELECT @w_fecha = dateadd(ww, @i_param2, @w_fecha)
END
ELSE IF @i_param3 = 'M'
BEGIN
	SELECT @w_fecha = dateadd(mm, @i_param2, @w_fecha)
END

if not exists (select 1 from cob_credito..cr_interface_buro where ib_cliente = @i_param1)
begin
	print 'cobis..cl_cliente'
	insert into cob_credito..cr_interface_buro (ib_cliente, ib_fecha, ib_xml, ib_riesgo)
	select @i_param1 , @w_fecha, 0x1F8B0800000000000000BD,70
END
ELSE
begin
	UPDATE cob_credito..cr_interface_buro 
	SET ib_fecha = @w_fecha
	WHERE ib_cliente = @i_param1
END


insert into cob_credito..cr_buro_cuenta (bc_id_cliente, bc_fecha_actualizacion, bc_registro_impugnado, 
											bc_clave_otorgante, bc_nombre_otorgante, bc_numero_telefono_otorgante, 
											bc_identificador_sociedad_crediticia, bc_numero_cuenta_actual, 	bc_indicador_tipo_responsabilidad, 
											bc_tipo_cuenta, bc_tipo_contrato, bc_clave_unidad_monetaria, 
											bc_valor_activo_valuacion, bc_numero_pagos, bc_frecuencia_pagos, 
											bc_monto_pagar, bc_fecha_apertura_cuenta, bc_fecha_ultimo_pago, 
											bc_fecha_ultima_compra, bc_fecha_cierre_cuenta, bc_fecha_reporte, 
											bc_modo_reportar, bc_ultima_fecha_saldo_cero, bc_garantia, 
											bc_credito_maximo, bc_saldo_actual, bc_limite_credito, 
											bc_saldo_vencido, bc_numero_pagos_vencidos, bc_forma_pago_actual, 
											bc_historico_pagos, bc_fecha_mas_reciente_pago_historicos, bc_fecha_mas_antigua_pago_historicos, 
											bc_clave_observacion, bc_total_pagos_reportados, bc_total_pagos_calificados_mop2,
											bc_total_pagos_calificados_mop3, bc_total_pagos_calificados_mop4, bc_total_pagos_calificados_mop5, 
											bc_importe_saldo_morosidad_hist_mas_grave,bc_fecha_historica_morosidad_mas_grave, bc_mop_historico_morosidad_mas_grave,
											bc_monto_ultimo_pago, bc_fecha_inicio_reestructura)
	select @i_param1 , replace(convert(NVARCHAR, @w_fecha, 111), '/',''), NULL, 
	       'XX99999999', 'BC 1TN', NULL, 
		   NULL, '989898121212', 'I', 
		   'I', 'AU', 'MX', 
		   NULL, 10, 'M', 
		   convert(varchar, @i_param4), '01012016', '01012016', 
		   '01012016', NULL, '09052016', 
		   'M', NULL, NULL, 
		   '50000', @i_param5, '50000', 
		   '0', NULL, @i_param6,
		   NULL, NULL, NULL, 
		   NULL, NULL, NULL, 
		   NULL, NULL, NULL, 
		   NULL, NULL, NULL, 
		   '2000', NULL
		   
RETURN 0




GO

