/*****************************************************************************/
/* Archivo           :  regrepr0453.sp                                       */
/* Stored procedure  :  sp_reporte_r0453                                     */
/* Base de datos     :  cob_conta_super                                      */
/*****************************************************************************/
/*                            IMPORTANTE                                     */
/* Esta aplicacion es parte de los paquetes bancarios propiedad de COBISCorp */
/* Su uso no autorizado queda  expresamente  prohibido asi como cualquier    */
/* alteracion o agregado hecho  por alguno de sus usuarios sin el debido     */
/* consentimiento por escrito de COBISCorp. Este programa esta protegido por */
/* la ley de derechos de autor y por las convenciones internacionales de     */
/* propiedad intelectual.  Su uso  no  autorizado dara derecho a COBISCORP   */
/* para obtener ordenes  de secuestro o  retencion  y  para  perseguir       */
/* penalmente a  los autores de cualquier infraccion.                        */
/*****************************************************************************/
/*                            PROPOSITO                                      */
/* Programa que genera el reporte regulatorio C- 0453                        */
/*****************************************************************************/
/*                           MODIFICACIONES                                  */
/* FECHA           AUTOR               RAZON                                 */
/* 09/11/2016      Nolberto Vite       Emision Inicial                       */
/*****************************************************************************/
use cob_conta_super
go
if exists (select 1 from sysobjects where name = 'sp_reporte_r0453')
   drop proc sp_reporte_r0453
go
 
create proc sp_reporte_r0453
(  
   @t_show_version   bit = 0,
   @i_param1         datetime,  -- inicio semana
   @i_param2         tinyint    -- Periodicidad
)

as 
declare
   @i_fecha          datetime,
   @i_periodicidad   tinyint,

   @w_return         int,     /* valor que retorna */
   @w_sp_name        varchar(32),
   @w_bancamia       varchar(24),
   @w_clave          varchar(30),
   @w_subreporte     varchar(30),
   @w_fecha_ini      datetime,
   @w_prod_pcame     varchar(10),
   @w_prod_pcaaso    varchar(10),
   @w_prod_pcaasa    varchar(10),
   @w_mayor_edad     tinyint,
   @w_cod_rel        int,
   @w_mes_fecha      tinyint,
   @w_moneda_local   tinyint,
   @w_s_app          varchar(50),
   @w_path           varchar(50),
   @w_destino        varchar(2500),
   @w_msg            varchar(200),
   @w_error          int,
   @w_errores        varchar(1500),
   @w_comando        varchar(2500)

select
   @w_sp_name        = 'sp_reporte_r0453',
   @i_fecha          = @i_param1,
   @i_periodicidad   = @i_param2

--Versionamiento del Programa --
if @t_show_version = 1
begin
  print 'Stored Procedure=' + @w_sp_name + ' Version=' + '4.0.0.0'
  return 0
end

delete sb_errorlog
 where er_fuente = @w_sp_name

--Valida periodicidad trimestral
select @w_mes_fecha = datepart(mm, @i_fecha)
if @w_mes_fecha % @i_periodicidad <> 0 goto FIN

--Clave de Entidad
select @w_clave = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'CLAVEN'
   and pa_producto = 'REC'
   
if @@rowcount <> 1
begin
   select @w_msg = 'NO EXISTE PARAMETRO CLAVEN'
   goto ERRORFIN
end

--Subreporte
select @w_subreporte = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'SUBREP'
   and pa_producto = 'REC'
   
if @@rowcount <> 1
begin
   select @w_msg = 'NO EXISTE PARAMETRO SUBREP'
   goto ERRORFIN
end

select @w_s_app = pa_char
  from cobis..cl_parametro with (nolock)
 where pa_producto = 'ADM'
   and pa_nemonico = 'S_APP'

if @@rowcount <> 1
begin
   select @w_msg = 'NO EXISTE PARAMETRO S_APP'
   goto ERRORFIN
end

select @w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 36001

if @@rowcount <> 1
begin
   select @w_msg = 'NO EXISTE RUTA PATH DESTINO'
   goto ERRORFIN
end

--Fecha inicio mes segun periodicidad
select @w_fecha_ini = dateadd(mm,-(@i_periodicidad - 1),@i_fecha)
select @w_fecha_ini = dateadd(dd,-(datepart(day,@w_fecha_ini)) + 1, @w_fecha_ini)

select 	r0453_periodo 				= convert(varchar, datepart(yy, do_fecha)) + right('0'+ convert(varchar,datepart(mm,do_fecha)),2), --1
		r0453_clave_entidad			= convert(numeric(6),@w_clave),                                                                    --2
		r0453_subreporte			= convert(numeric(4),@w_subreporte),                                                               --3
		r0453_identificador_acred	= convert(varchar(12),dc_cliente),                                                         --6
		r0453_persona_jurid			= (select convert(numeric(3),eq_valor_cat)
                                             from cob_conta_super..sb_equivalencias
                                            where eq_catalogo  = 'TIPO_ENTE'
                                              and eq_valor_arch = dc_subtipo),
		r0453_nom_raz_social		= upper(ltrim(rtrim(isnull(dc_nombre,'0')))),                                                      --6
		r0453_p_apellido			= dc_subtipo/*case dc_subtipo
										when 'P' then upper(ltrim(rtrim(isnull(dc_p_apellido,'0'))))                                --7
										else '0'
									  end*/,
		r0453_s_apellido			= dc_subtipo/*case dc_subtipo
										when 'P' then upper(ltrim(rtrim(isnull(dc_s_apellido,'0'))))                                --8
										else '0'
									  end*/,
		r0453_rfc_socio				= upper(ltrim(rtrim(isnull(dc_nit,'0')))), 
		r0453_curp_socio			= case dc_subtipo                                                                                  --10
										when 'P' then (select case dc_tipo_ced
																when 'CC' then isnull(dc_ced_ruc,'0')
																else '0'
										end)
										else '0'
									 end,
		r0453_genero				= '',/*case when dc_sexo in('F','M')                                                                    --11
										then (select convert(numeric(3),eq_valor_cat)
												from cob_conta_super..sb_equivalencias
												where eq_catalogo  = 'CL_SEXO'
												and eq_valor_arch = dc_sexo)
										else 3
									  end,*/
		r0453_ope_banco				= do_banco,
		r0453_oficina				= convert(varchar(6),do_oficina),
		r0453_clasif_cred			= convert(numeric(12),do_clase_cartera),
		r0453_product_credit		= convert(varchar(200),do_tipo_operacion) + '',
		r0453_fecha_conse			= isnull(convert(varchar,do_fecha_concesion,112),'19000101'),
		r0453_fecha_vencimiento		= isnull(convert(varchar,do_fecha_vencimiento,112),'19000101'),
		r0453_tipo_modalidad		= do_mod_pago,
		r0453_monto					= convert(numeric(16),do_monto),
		r0453_fecha_ult_pago_cap    = isnull(convert(varchar,do_fecha_ult_pago,112),'19000101'),
		r0453_valor_ult_pago_cap	= convert(varchar(20),do_valor_ult_pago),
		r0453_fecha_ult_pago_int    = isnull(convert(varchar,do_fecha_ult_pago,112),'19000101'),
		r0453_valor_ult_pago_int	= convert(varchar(20),do_valor_ult_pago),
		r0453_fec_pri_amort_cubi	= isnull(convert(varchar,do_fec_pri_amort_cubierta,112),'19000101'),
		r0453_dias_mora				= DATEDIFF(day,do_fec_pri_amort_cubierta,@i_param1),
		r0453_tipo_cred				= case 
											when ((do_reestructuracion = NULL or do_reestructuracion = 'N') and (do_no_renovacion = NULL or do_no_renovacion = 0)) 
												then 1
											when (do_reestructuracion = 'N') and (do_no_renovacion > 0) 
												then 2
											when (do_reestructuracion = 'S') and (do_no_renovacion = 0) 
												then 3
									  end,
		r0453_saldo_capital			= do_saldo_cap,
		r0453_saldo_interes			= do_saldo_int,
		r0453_mora					= do_valor_mora,--do_mora,
		r0453_inte_refinan			= null,--consultar
		r0453_monto_castigo			= null,--consultar
		r0453_monto_condo			= null,--consultar
		r0453_monto_boni			= null,--consultar
		r0453_fecha_castigo			= null,--consultar
		r0453_tipo_acred_rel		= null,--consultar
		r0453_estima_prevent_total	= null,--consultar
		r0453_clave_preven			= null,--'pendiente',
		r0453_fecha_sic				= null,--'pendiente',
		r0453_tipo_cobranza			= null,--'pendiente',
		r0453_garantia_liquida		= do_valor_garantias,
		r0453_garantia_hipotecaria	= do_valor_garantias
			
  into #reporte_r0453

  from cob_conta_super..sb_dato_operacion,
       cob_conta_super..sb_dato_cliente,
       cob_conta_super..sb_dato_direccion
	   
 where do_codigo_cliente = dc_cliente
   --and dd_cliente    = dc_cliente
   --and dc_fecha      = (select max(dc_fecha) from cob_conta_super..sb_dato_cliente where dc_cliente = do_codigo_cliente)
   --and dd_fecha      = (select max(dd_fecha) from cob_conta_super..sb_dato_direccion where dd_cliente = do_codigo_cliente)
   and do_fecha between @w_fecha_ini and @i_fecha
   and do_estado_cartera in (4)
   and dd_principal  = 'S'
   and do_aplicativo in (select eq_valor_arch
                           from sb_equivalencias
                          where eq_catalogo   = 'TIPRODUCTO'
                            and eq_valor_cat  in ('CARTERA'))


if @@error <> 0 begin
   select @w_msg = 'ERROR INSERTANDO DATOS DE AHORROS EN #reporte_r0453'
   goto ERRORFIN
end

truncate table cob_conta_super..sb_reporte_r0453

insert into cob_conta_super..sb_reporte_r0453
(
	PERIODO,				CLAVE_ENTIDAD,		SUBREPORTE,			IDENTIFICADOR_ACRED,	PERSONA_JURID,
	NOM_RAZ_SOCIAL,			APELLIDO_PATERNO,	APELLIDO_MATERNO,	RFC_SOCIO,				CURP_SOCIO,
	GENERO,					OPE_BANCO,			OFICINA,			CLASIF_CRED,			PRODUCT_CREDIT,
	FECHA_CONSE,			FECHA_VENCIMIENTO,	TIPO_MODALIDAD,		MONTO,					FECHA_ULT_PAGO_CAP,	
	VALOR_ULT_PAGO_CAP,		FECHA_ULT_PAGO_INT, VALOR_ULT_PAGO_INT,		FEC_PRI_AMORT_CUBI,	DIAS_MORA,			
	TIPO_CRED,				SALDO_CAPITAL,		SALDO_INTERES,			INTERES_MORA,		INTE_REFINAN,		
	MONTO_CASTIGO,			MONTO_CONDO,		MONTO_BONI,				FECHA_CASTIGO,		TIPO_ACRED_REL,		
	ESTIMA_PREVENT_TOTAL,	CLAVE_PREVEN,		FECHA_SIC,				TIPO_COBRANZA,		GARANTIA_LIQUIDA,	
	GARANTIA_HIPOTECARIA
)
select
	r0453_periodo,				r0453_clave_entidad,		r0453_subreporte,			r0453_identificador_acred,	r0453_persona_jurid,
	r0453_nom_raz_social,		r0453_p_apellido,			r0453_s_apellido,			r0453_rfc_socio,			r0453_curp_socio,
	r0453_genero,				r0453_ope_banco,			r0453_oficina,				r0453_clasif_cred,			r0453_product_credit,
	r0453_fecha_conse,			r0453_fecha_vencimiento,	r0453_tipo_modalidad,		r0453_monto,				r0453_fecha_ult_pago_cap,	
	r0453_valor_ult_pago_cap,	r0453_fecha_ult_pago_int,	r0453_valor_ult_pago_int,	r0453_fec_pri_amort_cubi,	r0453_dias_mora,			
	r0453_tipo_cred,			r0453_saldo_capital,		r0453_saldo_interes,		r0453_mora,					r0453_inte_refinan,			
	r0453_monto_castigo,		r0453_monto_condo,			r0453_monto_boni,			r0453_fecha_castigo,		r0453_tipo_acred_rel,		
	r0453_estima_prevent_total,	r0453_clave_preven,			r0453_fecha_sic,			r0453_tipo_cobranza,		r0453_garantia_liquida,		
	r0453_garantia_hipotecaria
  from #reporte_r0453

if @@error <> 0 begin
   select @w_msg = 'ERROR INSERTANDO DATOS DE AHORROS EN SB_reporte_r0453'
   goto ERRORFIN
end

--Ejecucion para Generar Archivo Datos
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_conta_super..sb_reporte_r0453 out '

select @w_destino  = @w_path + 'reporte_r0453_' + convert(varchar, datepart(yy, @i_fecha)) + right('0'+ convert(varchar,datepart(mm,@i_fecha)),2) + '.txt',
       @w_errores  = @w_path + 'reporte_r0453_' + convert(varchar, datepart(yy, @i_fecha)) + right('0'+ convert(varchar,datepart(mm,@i_fecha)),2) + '.err'

select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e -T -C' + @w_errores + ' -t"\t" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 begin
   select @w_msg = 'ERROR EN EJECUCION ' + @w_comando
   goto ERRORFIN
end

FIN:
return 0

ERRORFIN: 

   exec cob_conta_super..sp_errorlog
   @i_operacion     = 'I',
   @i_fecha_fin     = @i_fecha,
   @i_fuente        = @w_sp_name,
   @i_origen_error  = '28016',
   @i_descrp_error  = @w_msg
   
   return 1
go
