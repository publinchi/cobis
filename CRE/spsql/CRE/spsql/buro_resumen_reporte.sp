/************************************************************************/
/*  Archivo:                buro_resumen_reporte.sp                     */
/*  Stored procedure:       sp_buro_resumen_reporte                     */
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

if exists (select 1 from sysobjects where name = 'sp_buro_resumen_reporte' and type = 'P')
   drop proc sp_buro_resumen_reporte
go

CREATE PROCEDURE sp_buro_resumen_reporte(
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
   @t_show_version bit  = 0,   --* Mostrar la version del programa
   @i_operacion      char(1),             -- Opcion con la que se ejecuta el programa
   @i_tipo           char(1)     = null,  -- Tipo de busqueda
   @i_modo           int         = null,  -- Modo de consulta
   @i_ente			 int,
   	@i_fecha_ingreso_b_d                                     VARCHAR (8)= null,
	@i_numero_m_o_p7                                          VARCHAR (2)= null,
	@i_numero_m_o_p6                                          VARCHAR (2)= null,
	@i_numero_m_o_p5                                          VARCHAR (2)= null,
	@i_numero_m_o_p4                                          VARCHAR (2)= null,
	@i_numero_m_o_p3                                          VARCHAR (2)= null,
	@i_numero_m_o_p2                                          VARCHAR (2)= null,
	@i_numero_m_o_p1                                          VARCHAR (2)= null,
	@i_numero_m_o_p0                                          VARCHAR (2)= null,
	@i_numero_m_o_p_u_r                                        VARCHAR (2)= null,
	@i_numero_cuentas                                       VARCHAR (4)= null,
	@i_cuentas_pagos_fijos_hipotecas                        VARCHAR (4)= null,
	@i_cuentas_revolventes_abiertas                         VARCHAR (4)= null,
	@i_cuentas_cerradas                                     VARCHAR (4)= null,
	@i_cuentas_negativas_actuales                           VARCHAR (4)= null,
	@i_cuentas_claves_historia_negativa                     VARCHAR (4)= null,
	@i_cuentas_disputa                                      VARCHAR (2)= null,
	@i_numero_solicitudes_ultimos6_meses                   VARCHAR (2)= null,
	@i_nueva_direccion_reportada_ultimos60_dias            VARCHAR (1)= null,
	@i_mensajes_alerta                                      VARCHAR (8)= null,
	@i_existencia_declaraciones_consumidor                  VARCHAR (1)= null,
	@i_tipo_moneda                                          VARCHAR (2)= null,
	@i_total_creditos_maximos_revolventes                   VARCHAR (9)= null,
	@i_total_limites_credito_revolventes                    VARCHAR (9)= null,
	@i_total_saldos_actuales_revolventes                    VARCHAR (10)= null,
	@i_total_saldos_vencidos_revolventes                    VARCHAR (9)= null,
	@i_total_pagos_revolventes                              VARCHAR (9)= null,
	@i_pct_limite_credito_utilizado_revolventes             VARCHAR (3)= null,
	@i_total_creditos_maximos_pagos_fijos                   VARCHAR (9)= null,
	@i_total_saldos_actuales_pagos_fijos                    VARCHAR (10)= null,
	@i_total_saldos_vencidos_pagos_fijos                    VARCHAR (9)= null,
	@i_total_pagos_pagos_fijos                              VARCHAR (9)= null,
	@i_numero_m_o_p96                                         VARCHAR (2)= null,
	@i_numero_m_o_p97                                         VARCHAR (2)= null,
	@i_numero_m_o_p99                                         VARCHAR (2)= null,
	@i_fecha_apertura_cuenta_mas_antigua                    VARCHAR (8)= null,
	@i_fecha_apertura_cuenta_mas_reciente   VARCHAR (8)= null,
	@i_total_solicitudes_reporte                            VARCHAR (2)= null,
	@i_fecha_solicitud_reporte_mas_reciente                 VARCHAR (8)= null,
	@i_numero_total_cuentas_despacho_cobranza               VARCHAR (2)= null,
	@i_fecha_apertura_cuenta_mas_reciente_despacho_cobranza VARCHAR (8)= null,
	@i_numero_total_solicitudes_despachos_cobranza          VARCHAR (2)= null,
	@i_fecha_solicitud_mas_reciente_despacho_cobranza       VARCHAR (8)= null
)
as
begin
declare @w_today   datetime,
  @w_sp_name       varchar(32),
  @w_return        INT,
  @w_error_number  int


set @w_sp_name = 'sp_buro_resumen_reporte'

--* VERSIONAMIENTO DEL PROGRAMA
  if @t_show_version = 1
  begin
    print 'Stored Procedure=sp_buro_resumen_reporte Version=1.0.0'
    return 0
  end

if @i_operacion='Q'
begin

 select 'ente' 												= br_id_cliente,
	'fecha_ingreso_bd' 										= br_fecha_ingreso_bd,
	'numero_mop7' 											= br_numero_mop7,
	'numero_mop6' 											= br_numero_mop6,
	'numero_mop5' 											= br_numero_mop5,
	'numero_mop4' 											= br_numero_mop4,
	'numero_mop3' 											= br_numero_mop3,
	'numero_mop2' 											= br_numero_mop2,
	'numero_mop1' 											= br_numero_mop1,
	'numero_mop0' 											= br_numero_mop0,
	'numero_mop_ur' 										= br_numero_mop_ur,
	'numero_cuentas' 										= br_numero_cuentas,
	'cuentas_pagos_fijos_hipotecas' 						= br_cuentas_pagos_fijos_hipotecas,
	'cuentas_revolventes_abiertas' 							= br_cuentas_revolventes_abiertas,
	'cuentas_cerradas' 										= br_cuentas_cerradas,
	'cuentas_negativas_actuales' 							= br_cuentas_negativas_actuales,
	'cuentas_claves_historia_negativa' 						= br_cuentas_claves_historia_negativa,
	'cuentas_disputa' 										= br_cuentas_disputa,
	'numero_solicitudes_ultimos_6_meses' 					= br_numero_solicitudes_ultimos_6_meses,
	'nueva_direccion_reportada_ultimos_60_dias' 			= br_nueva_direccion_reportada_ultimos_60_dias,
	'mensajes_alerta' 										= br_mensajes_alerta,
	'existencia_declaraciones_consumidor' 					= br_existencia_declaraciones_consumidor,
	'tipo_moneda' 											= br_tipo_moneda,
	'total_creditos_maximos_revolventes' 					= br_total_creditos_maximos_revolventes,
	'total_limites_credito_revolventes ' 					= br_total_limites_credito_revolventes,
	'total_saldos_actuales_revolventes' 					= br_total_saldos_actuales_revolventes,
	'total_saldos_vencidos_revolventes' 					= br_total_saldos_vencidos_revolventes,
	'total_pagos_revolventes' 								= br_total_pagos_revolventes,
	'pct_limite_credito_utilizado_revolventes' 				= br_pct_limite_credito_utilizado_revolventes,
	'total_creditos_maximos_pagos_fijos' 					= br_total_creditos_maximos_pagos_fijos,
	'total_saldos_actuales_pagos_fijos' 					= br_total_saldos_actuales_pagos_fijos,
	'total_saldos_vencidos_pagos_fijos' 					= br_total_saldos_vencidos_pagos_fijos,
	'total_pagos_pagos_fijos' 								= br_total_pagos_pagos_fijos,
	'numero_mop96' 											= br_numero_mop96,
	'numero_mop97' 											= br_numero_mop97,
	'numero_mop99' 											= br_numero_mop99,
	'fecha_apertura_cuenta_mas_antigua' 					= br_fecha_apertura_cuenta_mas_antigua,
	'fecha_apertura_cuenta_mas_reciente' 					= br_fecha_apertura_cuenta_mas_reciente,
	'total_solicitudes_reporte' 							= br_total_solicitudes_reporte,
	'fecha_solicitud_reporte_mas_reciente' 					= br_fecha_solicitud_reporte_mas_reciente,
	'numero_total_cuentas_despacho_cobranza' 				= br_numero_total_cuentas_despacho_cobranza,
	'fecha_apertura_cuenta_mas_reciente_despacho_cobranza' 	= br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza,
	'numero_total_solicitudes_despachos_cobranza' 			= br_numero_total_solicitudes_despachos_cobranza,
	'fecha_solicitud_mas_reciente_despacho_cobranza' 		= br_fecha_solicitud_mas_reciente_despacho_cobranza
  from cr_buro_resumen_reporte
  where br_id_cliente = @i_ente
  
end --@i_operacion

If @i_operacion = 'I' 
begin
 

	INSERT INTO cr_buro_resumen_reporte (br_id_cliente, 
										br_fecha_ingreso_bd, 
										br_numero_mop7, 
										br_numero_mop6, 
										br_numero_mop5, 
										br_numero_mop4, 
										br_numero_mop3, 
										br_numero_mop2, 
										br_numero_mop1, 
										br_numero_mop0, 
										br_numero_mop_ur, 
										br_numero_cuentas, 
										br_cuentas_pagos_fijos_hipotecas, 
										br_cuentas_revolventes_abiertas, 
										br_cuentas_cerradas, 
										br_cuentas_negativas_actuales, 
										br_cuentas_claves_historia_negativa, 
										br_cuentas_disputa, 
										br_numero_solicitudes_ultimos_6_meses, 
										br_nueva_direccion_reportada_ultimos_60_dias, 
										br_mensajes_alerta, 
										br_existencia_declaraciones_consumidor, 
										br_tipo_moneda, 
										br_total_creditos_maximos_revolventes, 
										br_total_limites_credito_revolventes, 
										br_total_saldos_actuales_revolventes, 
										br_total_saldos_vencidos_revolventes, 
										br_total_pagos_revolventes, 
										br_pct_limite_credito_utilizado_revolventes, 
										br_total_creditos_maximos_pagos_fijos, 
										br_total_saldos_actuales_pagos_fijos, 
										br_total_saldos_vencidos_pagos_fijos, 
										br_total_pagos_pagos_fijos, 
										br_numero_mop96, 
										br_numero_mop97, 
										br_numero_mop99, 
										br_fecha_apertura_cuenta_mas_antigua, 
										br_fecha_apertura_cuenta_mas_reciente, 
										br_total_solicitudes_reporte, 
										br_fecha_solicitud_reporte_mas_reciente, 
										br_numero_total_cuentas_despacho_cobranza, 
										br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza, 
										br_numero_total_solicitudes_despachos_cobranza, 
										br_fecha_solicitud_mas_reciente_despacho_cobranza)   
								VALUES ( @i_ente, 	
										@i_fecha_ingreso_b_d,
										@i_numero_m_o_p7,
										@i_numero_m_o_p6 ,
										@i_numero_m_o_p5 ,
										@i_numero_m_o_p4,
										@i_numero_m_o_p3,
										@i_numero_m_o_p2 ,
										@i_numero_m_o_p1,
										@i_numero_m_o_p0,
										@i_numero_m_o_p_u_r ,
										@i_numero_cuentas,
										@i_cuentas_pagos_fijos_hipotecas,
										@i_cuentas_revolventes_abiertas,
										@i_cuentas_cerradas,
										@i_cuentas_negativas_actuales,
										@i_cuentas_claves_historia_negativa,
										@i_cuentas_disputa,
										@i_numero_solicitudes_ultimos6_meses,
										@i_nueva_direccion_reportada_ultimos60_dias,
										@i_mensajes_alerta,
										@i_existencia_declaraciones_consumidor,
										@i_tipo_moneda,
										@i_total_creditos_maximos_revolventes,
										@i_total_limites_credito_revolventes,
										@i_total_saldos_actuales_revolventes,
										@i_total_saldos_vencidos_revolventes,
										@i_total_pagos_revolventes,
										@i_pct_limite_credito_utilizado_revolventes,
										@i_total_creditos_maximos_pagos_fijos,
										@i_total_saldos_actuales_pagos_fijos,
										@i_total_saldos_vencidos_pagos_fijos,
										@i_total_pagos_pagos_fijos,
										@i_numero_m_o_p96,
										@i_numero_m_o_p97,
										@i_numero_m_o_p99,
										@i_fecha_apertura_cuenta_mas_antigua,
										@i_fecha_apertura_cuenta_mas_reciente,
										@i_total_solicitudes_reporte,
										@i_fecha_solicitud_reporte_mas_reciente,
										@i_numero_total_cuentas_despacho_cobranza,
										@i_fecha_apertura_cuenta_mas_reciente_despacho_cobranza,
										@i_numero_total_solicitudes_despachos_cobranza,
										@i_fecha_solicitud_mas_reciente_despacho_cobranza)
	


end  --@i_operacion


if @i_operacion = 'U' 
begin

	update cr_buro_resumen_reporte 
		set br_fecha_ingreso_bd 									= isnull(@i_fecha_ingreso_b_d, br_fecha_ingreso_bd), 
			br_numero_mop7 											= isnull(@i_numero_m_o_p7, br_numero_mop7), 
			br_numero_mop6 											= isnull(@i_numero_m_o_p6, br_numero_mop6), 
			br_numero_mop5 											= isnull(@i_numero_m_o_p5, br_numero_mop5), 
			br_numero_mop4 											= isnull(@i_numero_m_o_p4, br_numero_mop4), 
			br_numero_mop3 											= isnull(@i_numero_m_o_p3, br_numero_mop3), 
			br_numero_mop2 											= isnull(@i_numero_m_o_p2, br_numero_mop2), 
			br_numero_mop1 											= isnull(@i_numero_m_o_p1, br_numero_mop1), 
			br_numero_mop0 											= isnull(@i_numero_m_o_p0, br_numero_mop0), 
			br_numero_mop_ur 										= isnull(@i_numero_m_o_p_u_r, br_numero_mop_ur), 
			br_numero_cuentas 										= isnull(@i_numero_cuentas, br_numero_cuentas), 
			br_cuentas_pagos_fijos_hipotecas 						= isnull(@i_cuentas_pagos_fijos_hipotecas, br_cuentas_pagos_fijos_hipotecas), 
			br_cuentas_revolventes_abiertas 						= isnull(@i_cuentas_revolventes_abiertas, br_cuentas_revolventes_abiertas), 
			br_cuentas_cerradas 									= isnull(@i_cuentas_cerradas, br_cuentas_cerradas), 
			br_cuentas_negativas_actuales 							= isnull(@i_cuentas_negativas_actuales, br_cuentas_negativas_actuales), 
			br_cuentas_claves_historia_negativa 					= isnull(@i_cuentas_claves_historia_negativa, br_cuentas_claves_historia_negativa), 
			br_cuentas_disputa 										= isnull(@i_cuentas_disputa, br_cuentas_disputa), 
			br_numero_solicitudes_ultimos_6_meses 					= isnull(@i_numero_solicitudes_ultimos6_meses, br_numero_solicitudes_ultimos_6_meses), 
			br_nueva_direccion_reportada_ultimos_60_dias 			= isnull(@i_nueva_direccion_reportada_ultimos60_dias, br_nueva_direccion_reportada_ultimos_60_dias), 
			br_mensajes_alerta 										= isnull(@i_mensajes_alerta, br_mensajes_alerta), 
			br_existencia_declaraciones_consumidor 					= isnull(@i_existencia_declaraciones_consumidor, br_existencia_declaraciones_consumidor), 
			br_tipo_moneda 											= isnull(@i_tipo_moneda, br_tipo_moneda), 
			br_total_creditos_maximos_revolventes 					= isnull(@i_total_creditos_maximos_revolventes, br_total_creditos_maximos_revolventes), 
			br_total_limites_credito_revolventes 					= isnull(@i_total_limites_credito_revolventes, br_total_limites_credito_revolventes), 
			br_total_saldos_actuales_revolventes 					= isnull(@i_total_saldos_actuales_revolventes, br_total_saldos_actuales_revolventes), 
			br_total_saldos_vencidos_revolventes 					= isnull(@i_total_saldos_vencidos_revolventes, br_total_saldos_vencidos_revolventes), 
			br_total_pagos_revolventes 								= isnull(@i_total_pagos_revolventes, br_total_pagos_revolventes), 
			br_pct_limite_credito_utilizado_revolventes 			= isnull(@i_pct_limite_credito_utilizado_revolventes, br_pct_limite_credito_utilizado_revolventes), 
			br_total_creditos_maximos_pagos_fijos 					= isnull(@i_total_creditos_maximos_pagos_fijos, br_total_creditos_maximos_pagos_fijos), 
			br_total_saldos_actuales_pagos_fijos 					= isnull(@i_total_saldos_actuales_pagos_fijos, br_total_saldos_actuales_pagos_fijos), 
			br_total_saldos_vencidos_pagos_fijos 					= isnull(@i_total_saldos_vencidos_pagos_fijos, br_total_saldos_vencidos_pagos_fijos), 
			br_total_pagos_pagos_fijos 								= isnull(@i_total_pagos_pagos_fijos, br_total_pagos_pagos_fijos), 
			br_numero_mop96 										= isnull(@i_numero_m_o_p96, br_numero_mop96), 
			br_numero_mop97 										= isnull(@i_numero_m_o_p97, br_numero_mop97), 
			br_numero_mop99 										= isnull(@i_numero_m_o_p99, br_numero_mop99), 
			br_fecha_apertura_cuenta_mas_antigua 					= isnull(@i_fecha_apertura_cuenta_mas_antigua, br_fecha_apertura_cuenta_mas_antigua), 
			br_fecha_apertura_cuenta_mas_reciente 					= isnull(@i_fecha_apertura_cuenta_mas_reciente, br_fecha_apertura_cuenta_mas_reciente), 
			br_total_solicitudes_reporte 							= isnull(@i_total_solicitudes_reporte, br_total_solicitudes_reporte), 
			br_fecha_solicitud_reporte_mas_reciente 				= isnull(@i_fecha_solicitud_reporte_mas_reciente, br_fecha_solicitud_reporte_mas_reciente), 
			br_numero_total_cuentas_despacho_cobranza 				= isnull(@i_numero_total_cuentas_despacho_cobranza, br_numero_total_cuentas_despacho_cobranza), 
			br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza = isnull(@i_fecha_apertura_cuenta_mas_reciente_despacho_cobranza, br_fecha_apertura_cuenta_mas_reciente_despacho_cobranza), 
			br_numero_total_solicitudes_despachos_cobranza 			= isnull(@i_numero_total_solicitudes_despachos_cobranza, br_numero_total_solicitudes_despachos_cobranza), 
			br_fecha_solicitud_mas_reciente_despacho_cobranza 		= isnull(@i_fecha_solicitud_mas_reciente_despacho_cobranza, br_fecha_solicitud_mas_reciente_despacho_cobranza)
	where br_id_cliente = @i_ente
	
	if @@error <> 0 
	begin
         set @w_error_number = 708152        
         goto ERROR
     end
  
end  --@i_operacion


if @i_operacion = 'D' 
begin
	delete from cr_buro_resumen_reporte where  br_id_cliente = @i_ente
end

return 0

ERROR:
    EXEC cobis..sp_cerror
        @t_from  = @w_sp_name,
        @i_num   = @w_error_number

    RETURN 1
end

GO
