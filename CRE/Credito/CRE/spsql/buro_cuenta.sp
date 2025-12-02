/************************************************************************/
/*  Archivo:                buro_cuenta.sp                              */
/*  Stored procedure:       sp_buro_cuenta                              */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_buro_cuenta' and type = 'P')
   drop proc sp_buro_cuenta
go

CREATE PROCEDURE sp_buro_cuenta(
   @s_ssn            int         = null,
   @s_user           login       = null,
   @s_term           varchar(32) = null,
   @s_date           datetime    = null,
   @s_sesn           int         = null,
   @s_culture        varchar(10) = null,
   @s_srv            varchar(30) = null,
   @s_lsrv           varchar(30) = null,
   @s_ofi            smallint    = null,
   @s_rol            smallint    = NULL,
   @s_org_err        char(1)     = NULL,
   @s_error          int         = NULL,
   @s_sev            tinyint     = NULL,
   @s_msg            descripcion = NULL,
   @s_org            char(1)     = NULL,
   @t_debug          char(1)     = 'N',
   @t_file           varchar(10) = null,
   @t_from           varchar(32) = null,
   @t_trn            smallint    = null,   
   @t_show_version   bit  = 0,   --* Mostrar la version del programa
   @i_operacion      char(1),             -- Opcion con la que se ejecuta el programa
   @i_tipo           char(1)     	= null,  -- Tipo de busqueda
   @i_modo           int         	= null,  -- Modo de consulta
   @i_ente			 int,
   @i_fecha_actualizacion     				  VARCHAR(8)    = null,
   @i_registro_impugnado      				  VARCHAR(4)   	= null,
   @i_clave_otorgante         				  VARCHAR(10)  	= null,
   @i_nombre_otorgante        				  VARCHAR(16)  	= null,
   @i_numero_telefono_otorgante      				  VARCHAR(11)  	= null,
   @i_identificador_sociedad_crediticia       VARCHAR(11)  	= null,
   @i_numero_cuenta_actual   				  VARCHAR(25)  	= null,
   @i_indicador_tipo_responsabilidad          VARCHAR (1) 	= null,
	@i_tipo_cuenta                            VARCHAR (1) 	= null,
	@i_tipo_contrato                          VARCHAR (2) 	= null,
	@i_clave_unidad_monetaria                 VARCHAR (2) 	= null,
	@i_valor_activo_valuacion                 VARCHAR (9) 	= null,
	@i_numero_pagos                           VARCHAR (4) 	= null,
	@i_frecuencia_pagos                       VARCHAR (1) 	= null,
	@i_monto_pagar                            VARCHAR (9) 	= null,
	@i_fecha_apertura_cuenta                  VARCHAR (8) 	= null,
	@i_fecha_ultimo_pago                      VARCHAR (8) 	= null,
	@i_fecha_ultima_compra                    VARCHAR (8) 	= null,
	@i_fecha_cierre_cuenta                    VARCHAR (8) 	= null,
	@i_fecha_reporte                          VARCHAR (8) 	= null,
	@i_modo_reportar                          VARCHAR (1) 	= null,
	@i_ultima_fecha_saldo_cero                VARCHAR (8) 	= null,
	@i_garantia                               VARCHAR (40) 	= null,
	@i_credito_maximo                         VARCHAR (9) 	= null,
	@i_saldo_actual                           VARCHAR (9) 	= null,
	@i_limite_credito                         VARCHAR (9) 	= null,
	@i_saldo_vencido                          VARCHAR (9) 	= null,
	@i_numero_pagos_vencidos                  VARCHAR (4) 	= null,
	@i_forma_pago_actual                      VARCHAR (2) 	= null,
	@i_historico_pagos                        VARCHAR (24) 	= null,
	@i_fecha_mas_reciente_historico_pagos     VARCHAR (8) 	= null,
	@i_fecha_mas_antigua_historico_pagos      VARCHAR (8) 	= null,
	@i_clave_observacion                      VARCHAR (2) 	= null,
	@i_total_pagos_reportados                 VARCHAR (3) 	= null,
	@i_total_pagos_calificados_m_o_p2           VARCHAR (2) 	= null,
	@i_total_pagos_calificados_m_o_p3           VARCHAR (2) 	= null,
	@i_total_pagos_calificados_m_o_p4           VARCHAR (2) 	= null,
	@i_total_pagos_calificados_m_o_p5           VARCHAR (2) 	= null,
	@i_importe_saldo_morosidad_hist_mas_grave VARCHAR (9) 	= null,
	@i_fecha_historica_morosidad_mas_grave    VARCHAR (8) 	= null,
	@i_mop_historico_morosidad_mas_grave      VARCHAR (2) 	= null,
	@i_monto_ultimo_pago                      VARCHAR (9) 	= null,
	@i_fecha_inicio_reestructura              VARCHAR (8) 	= null
)
as
begin
declare @w_today   datetime,
  @w_sp_name       varchar(32),
  @w_return        INT,
  @w_error_number  int


set @w_sp_name = 'sp_buro_cuenta'

--* VERSIONAMIENTO DEL PROGRAMA
  if @t_show_version = 1
  begin
    print 'Stored Procedure=sp_buro_cuenta Version=1.0.0'
    return 0
  end

if @i_operacion='Q'
begin

	select 	'ente' 												= bc_id_cliente, 
			'fecha_actualizacion' 								= bc_fecha_actualizacion, 
			'registro_impugnado' 								= bc_registro_impugnado, 
			'clave_otorgante'									= bc_clave_otorgante, 
			'clave_otorgante'       							= bc_nombre_otorgante, 
			'numero_telefono_otorgante' 						= bc_numero_telefono_otorgante, 
			'identificador_sociedad_crediticia' 				= bc_identificador_sociedad_crediticia, 
			'numero_cuenta_actual' 								= bc_numero_cuenta_actual, 
			'indicador_tipo_responsabilidad' 					= bc_indicador_tipo_responsabilidad, 
			'tipo_cuenta' 										= bc_tipo_cuenta, 
			'tipo_contrato' 									= bc_tipo_contrato, 
			'clave_unidad_monetaria' 							= bc_clave_unidad_monetaria, 
			'valor_activo_valuacion' 							= bc_valor_activo_valuacion, 
			'numero_pagos'										= bc_numero_pagos, 
			'frecuencia_pagos' 									= bc_frecuencia_pagos, 
			'monto_pagar' 										= bc_monto_pagar, 
			'fecha_apertura_cuenta' 							= bc_fecha_apertura_cuenta, 
			'fecha_ultimo_pago' 								= bc_fecha_ultimo_pago, 
			'fecha_ultima_compra' 								= bc_fecha_ultima_compra, 
			'fecha_cierre_cuenta' 								= bc_fecha_cierre_cuenta, 
			'fecha_reporte' 									= bc_fecha_reporte, 
			'modo_reportar' 									= bc_modo_reportar, 
			'ultima_fecha_saldo_cero' 							= bc_ultima_fecha_saldo_cero,	
			'garantia' 											= bc_garantia, 
			'credito_maximo' 									= bc_credito_maximo, 
			'saldo_actual' 										= bc_saldo_actual, 
			'limite_credito' 									= bc_limite_credito, 
			'saldo_vencido' 									= bc_saldo_vencido, 
			'numero_pagos_vencidos' 							= bc_numero_pagos_vencidos, 
			'forma_pago_actual' 								= bc_forma_pago_actual, 
			'historico_pagos' 									= bc_historico_pagos, 
			'fecha_mas_reciente_pago_historicos' 				= bc_fecha_mas_reciente_pago_historicos, 
			'fecha_mas_antigua_pago_historicos' 				= bc_fecha_mas_antigua_pago_historicos, 
			'clave_observacion' 								= bc_clave_observacion, 
			'total_pagos_reportados' 							= bc_total_pagos_reportados, 
			'total_pagos_calificados_mop2' 						= bc_total_pagos_calificados_mop2, 
			'total_pagos_calificados_mop3' 						= bc_total_pagos_calificados_mop3, 
			'total_pagos_calificados_mop4' 						= bc_total_pagos_calificados_mop4, 
			'total_pagos_calificados_mop5' 						= bc_total_pagos_calificados_mop5, 
			'importe_saldo_morosidad_hist_mas_grave' 			= bc_importe_saldo_morosidad_hist_mas_grave, 
			'fecha_historica_morosidad_mas_grave' 				= bc_fecha_historica_morosidad_mas_grave, 
			'mop_historico_morosidad_mas_grave' 				= bc_mop_historico_morosidad_mas_grave, 
			'monto_ultimo_pago, bc_fecha_inicio_reestructura' 	= bc_monto_ultimo_pago, bc_fecha_inicio_reestructura
  from cr_buro_cuenta
  where bc_id_cliente = @i_ente
  
end --@i_operacion

If @i_operacion = 'I' 
begin
	

	INSERT INTO cr_buro_cuenta 	   (bc_id_cliente, bc_fecha_actualizacion, 
									bc_registro_impugnado, bc_clave_otorgante, 
									bc_nombre_otorgante, bc_numero_telefono_otorgante, 
									bc_identificador_sociedad_crediticia, bc_numero_cuenta_actual, 
									bc_indicador_tipo_responsabilidad, bc_tipo_cuenta, 
									bc_tipo_contrato, bc_clave_unidad_monetaria, 
									bc_valor_activo_valuacion, bc_numero_pagos, 
									bc_frecuencia_pagos, bc_monto_pagar, 
									bc_fecha_apertura_cuenta, bc_fecha_ultimo_pago, 
									bc_fecha_ultima_compra, bc_fecha_cierre_cuenta, 
									bc_fecha_reporte, bc_modo_reportar, 
									bc_ultima_fecha_saldo_cero,	bc_garantia, 
									bc_credito_maximo, bc_saldo_actual, 
									bc_limite_credito, bc_saldo_vencido, 
									bc_numero_pagos_vencidos, bc_forma_pago_actual, 
									bc_historico_pagos, bc_fecha_mas_reciente_pago_historicos, 
									bc_fecha_mas_antigua_pago_historicos, bc_clave_observacion, 
									bc_total_pagos_reportados, bc_total_pagos_calificados_mop2, 
									bc_total_pagos_calificados_mop3, bc_total_pagos_calificados_mop4, 
									bc_total_pagos_calificados_mop5, bc_importe_saldo_morosidad_hist_mas_grave, 
									bc_fecha_historica_morosidad_mas_grave, bc_mop_historico_morosidad_mas_grave, 
									bc_monto_ultimo_pago, bc_fecha_inicio_reestructura)
							VALUES (@i_ente, @i_fecha_actualizacion,
									@i_registro_impugnado, @i_clave_otorgante ,
									@i_nombre_otorgante, @i_numero_telefono_otorgante,
									@i_identificador_sociedad_crediticia, @i_numero_cuenta_actual,
									@i_indicador_tipo_responsabilidad,@i_tipo_cuenta,
									@i_tipo_contrato,@i_clave_unidad_monetaria,
									@i_valor_activo_valuacion,@i_numero_pagos,
									@i_frecuencia_pagos,@i_monto_pagar,
									@i_fecha_apertura_cuenta,@i_fecha_ultimo_pago,
									@i_fecha_ultima_compra,	@i_fecha_cierre_cuenta,
									@i_fecha_reporte,@i_modo_reportar,
									@i_ultima_fecha_saldo_cero,	@i_garantia,
									@i_credito_maximo,	@i_saldo_actual,
									@i_limite_credito,	@i_saldo_vencido,
									@i_numero_pagos_vencidos,	@i_forma_pago_actual,
									@i_historico_pagos,	@i_fecha_mas_reciente_historico_pagos,
									@i_fecha_mas_antigua_historico_pagos,	@i_clave_observacion,
									@i_total_pagos_reportados,	@i_total_pagos_calificados_m_o_p2,
									@i_total_pagos_calificados_m_o_p3,	@i_total_pagos_calificados_m_o_p4,
									@i_total_pagos_calificados_m_o_p5,	@i_importe_saldo_morosidad_hist_mas_grave,
									@i_fecha_historica_morosidad_mas_grave,	@i_mop_historico_morosidad_mas_grave,
									@i_monto_ultimo_pago,	@i_fecha_inicio_reestructura)


	if @@error <> 0 
	begin
         set @w_error_number = 357043        
         goto ERROR
     end

end  --@i_operacion


if @i_operacion = 'U' 
begin

	UPDATE cr_buro_cuenta
	SET bc_fecha_actualizacion = isnull(@i_fecha_actualizacion,bc_fecha_actualizacion),
		bc_registro_impugnado = isnull(@i_registro_impugnado,bc_registro_impugnado),
		bc_clave_otorgante = isnull(@i_clave_otorgante,bc_clave_otorgante),
		bc_nombre_otorgante = isnull(@i_nombre_otorgante,bc_nombre_otorgante),
		bc_numero_telefono_otorgante = isnull(@i_numero_telefono_otorgante,bc_numero_telefono_otorgante),
		bc_identificador_sociedad_crediticia = isnull(@i_identificador_sociedad_crediticia,bc_identificador_sociedad_crediticia),
		bc_numero_cuenta_actual = isnull(@i_numero_cuenta_actual,bc_numero_cuenta_actual),
		bc_indicador_tipo_responsabilidad = isnull(@i_indicador_tipo_responsabilidad,bc_indicador_tipo_responsabilidad),
		bc_tipo_cuenta = isnull(@i_tipo_cuenta,bc_tipo_cuenta),
		bc_tipo_contrato = isnull(@i_tipo_contrato,bc_tipo_contrato),
		bc_clave_unidad_monetaria = isnull(@i_clave_unidad_monetaria,bc_clave_unidad_monetaria),
		bc_valor_activo_valuacion = isnull(@i_valor_activo_valuacion,bc_valor_activo_valuacion),
		bc_numero_pagos = isnull(@i_numero_pagos,bc_numero_pagos),
		bc_frecuencia_pagos = isnull(@i_frecuencia_pagos,bc_frecuencia_pagos),
		bc_monto_pagar = isnull(@i_monto_pagar,bc_monto_pagar),
		bc_fecha_apertura_cuenta = isnull(@i_fecha_apertura_cuenta,bc_fecha_apertura_cuenta),
		bc_fecha_ultimo_pago = isnull(@i_fecha_ultimo_pago,bc_fecha_ultimo_pago),
		bc_fecha_ultima_compra = isnull(@i_fecha_ultima_compra,bc_fecha_ultima_compra),
		bc_fecha_cierre_cuenta = isnull(@i_fecha_cierre_cuenta,bc_fecha_cierre_cuenta),
		bc_fecha_reporte = isnull(@i_fecha_reporte,bc_fecha_reporte),
		bc_modo_reportar = isnull(@i_modo_reportar,bc_modo_reportar),
		bc_ultima_fecha_saldo_cero = isnull(@i_ultima_fecha_saldo_cero,bc_ultima_fecha_saldo_cero),
		bc_garantia = isnull(@i_garantia,bc_garantia),
		bc_credito_maximo = isnull(@i_credito_maximo,bc_credito_maximo),
		bc_saldo_actual = isnull(@i_saldo_actual,bc_saldo_actual),
		bc_limite_credito = isnull(@i_limite_credito,bc_limite_credito),
		bc_saldo_vencido = isnull(@i_saldo_vencido,bc_saldo_vencido),
		bc_numero_pagos_vencidos = isnull(@i_numero_pagos_vencidos,bc_numero_pagos_vencidos),
		bc_forma_pago_actual = isnull(@i_forma_pago_actual,bc_forma_pago_actual),
		bc_historico_pagos = isnull(@i_historico_pagos,bc_historico_pagos),
		bc_fecha_mas_reciente_pago_historicos = isnull(@i_fecha_mas_reciente_historico_pagos,bc_fecha_mas_reciente_pago_historicos),
		bc_fecha_mas_antigua_pago_historicos = isnull(@i_fecha_mas_antigua_historico_pagos,bc_fecha_mas_antigua_pago_historicos),
		bc_clave_observacion = isnull(@i_clave_observacion,bc_clave_observacion),
		bc_total_pagos_reportados = isnull(@i_total_pagos_reportados,bc_total_pagos_reportados),
		bc_total_pagos_calificados_mop2 = isnull(@i_total_pagos_calificados_m_o_p2,bc_total_pagos_calificados_mop2),
		bc_total_pagos_calificados_mop3 = isnull(@i_total_pagos_calificados_m_o_p3,bc_total_pagos_calificados_mop3),
		bc_total_pagos_calificados_mop4 = isnull(@i_total_pagos_calificados_m_o_p4,bc_total_pagos_calificados_mop4),
		bc_total_pagos_calificados_mop5 = isnull(@i_total_pagos_calificados_m_o_p5,bc_total_pagos_calificados_mop5),
		bc_importe_saldo_morosidad_hist_mas_grave = isnull(@i_importe_saldo_morosidad_hist_mas_grave,bc_importe_saldo_morosidad_hist_mas_grave),
		bc_fecha_historica_morosidad_mas_grave = isnull(@i_fecha_historica_morosidad_mas_grave,bc_fecha_historica_morosidad_mas_grave),
		bc_mop_historico_morosidad_mas_grave = isnull(@i_mop_historico_morosidad_mas_grave,bc_mop_historico_morosidad_mas_grave),
		bc_monto_ultimo_pago = isnull(@i_monto_ultimo_pago,bc_monto_ultimo_pago),
		bc_fecha_inicio_reestructura = isnull(@i_fecha_inicio_reestructura,bc_fecha_inicio_reestructura)
		where bc_id_cliente = @i_ente
	
	if @@error <> 0 
	begin
         set @w_error_number = 708152        
         goto ERROR
     end
  
end  --@i_operacion

if @i_operacion = 'D' 
begin
	delete from cr_buro_cuenta where  bc_id_cliente = @i_ente
end

return 0

ERROR:
    EXEC cobis..sp_cerror
        @t_from  = @w_sp_name,
        @i_num   = @w_error_number

    RETURN 1
end

GO
