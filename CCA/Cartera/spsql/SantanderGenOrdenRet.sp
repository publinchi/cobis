/************************************************************************/
/*   Archivo:              SantanderGenOrdenRet.sp                      */
/*   Stored procedure:     sp_santander_gen_orden_ret					      */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Raul Altamirano Mendez                       */
/*   Fecha de escritura:   Junio 2017                                   */
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
/*   Genera archivo de interface para ordenes de pagos, de cliente banco*/
/*   SANTANDER MX.                                                      */
/*                              CAMBIOS                                 */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_santander_gen_orden_ret')
   drop proc sp_santander_gen_orden_ret
go

create proc sp_santander_gen_orden_ret
(
 @s_ssn        int         = null,
 @s_user       login       = null,
 @s_sesn       int         = null,
 @s_term       varchar(30) = null,
 @s_date       datetime    = null,
 @s_srv        varchar(30) = null,
 @s_lsrv       varchar(30) = null,
 @s_ofi        smallint    = null,
 @s_servicio   int         = null,
 @s_cliente    int         = null,
 @s_rol        smallint    = null,
 @s_culture    varchar(10) = null,
 @s_org        char(1)     = null,
 @i_debug      CHAR(1)     = 'N',
 @i_opcion     CHAR(1)     = NULL,
 @i_banco      VARCHAR(32) = NULL,
 @i_param1     char(3)     = 'IEN'
)

as

declare
@w_cab_01  char(002),
@w_cab_02  char(007),
@w_cab_03  char(002),
@w_cab_04  char(003),
@w_cab_05  char(001),
@w_cab_06  char(001),
@w_cab_07  char(007),
@w_cab_08  char(008),
@w_cab_09  char(002),
@w_cab_10  char(027),
@w_cab_11  char(040),
@w_cab_12  char(018),
@w_cab_13  char(010),
@w_cab_14  char(172), -- LGU

@w_det_01  char(002),
@w_det_02  char(007),
@w_det_03  char(002),
@w_det_04  char(002),
@w_det_05  char(015),
@w_det_06  char(032),
@w_det_07  char(002),
@w_det_08  char(008),
@w_det_09  char(003),
@w_det_10  char(002),
@w_det_11  char(020),
@w_det_12  char(040),
@w_det_13  char(040),
@w_det_14  char(040),
@w_det_15  char(015),
@w_det_16  char(007),
@w_det_17  char(040),
@w_det_18  char(023),

@w_pie_01  char(002),
@w_pie_02  char(007),
@w_pie_03  char(002),
@w_pie_04  char(007),
@w_pie_05  char(007),
@w_pie_06  char(018),
@w_pie_07  char(257),

@w_sep                char(01),

@w_est_vigente        tinyint,
@w_est_vencida        tinyint,

@w_param_reintento    smallint,
@w_ncta_cli           cuenta,
@w_nombre_cli         varchar(60),
@w_refer_serv_emi     varchar(40),
@w_nomb_tit_serv      varchar(40),
@w_valor_iva          money,
@w_toper_grupal       catalogo,
@w_refer_num_emi      int,
@w_refer_leyen_emi    varchar(40),
@w_param_fpago_ret    catalogo,
@w_param_nomb_ord     varchar(40),
@w_param_nrfc_ord     char(18),
@w_param_abrev_ord    char(30),
@w_gen_arch_dom_pag   char(1),
@w_gen_arch_dom_seg   char(1),

@w_error              int,
@w_fecha_proceso      datetime,
@w_fecha_inicial      datetime,
@w_ult_fecha_ien      DATETIME,
@w_hora               VARCHAR(15), -- PÁRA EL NUEVO CAMPO DE LA CABECERA
@w_fecha_real         datetime,
@w_fecha_hasta        datetime,
@w_banco              cuenta,
@w_operacionca        int,
@w_toperacion         catalogo,
@w_cliente            int,
@w_nombre             varchar(64),
@w_grupo              int,
@w_fecha_ult_proceso  datetime,
@w_refer_grupal       cuenta,
@w_valor_retiro       money,
@w_cuo_vigente        int,
@w_cuo_min_vencida    int,
@w_cuo_max_vencida    int,

@w_count_op           int,
@w_total_retiro       money,
@w_monto_string       varchar(18),
@w_total_string       varchar(18),
@w_iva_string         varchar(18),
@w_detalle            varchar(500),

@w_sp_name_batch      varchar(50),
@w_s_app              varchar(30),
@w_path               varchar(255),
@w_nombre_archivo     varchar(30),
@w_destino            varchar(1000),
@w_errores            varchar(1000),
@w_comando            varchar(1000),
@w_tipo_ret           char(1),
@w_valor_retiro_sol   money,
@w_ciudad_nacional    int ,
@w_param_dias_proceso smallint,

@w_fecha_clave        VARCHAR(32),
@w_domi_fclave_ant    VARCHAR(64),
@w_consecutivo        INT,
@w_fcabecera          DATETIME, -- para la hora de la cabecera
@w_fini_domi          DATETIME --'02/04/2019'

DECLARE
@w_fecha_real_ant DATETIME ,
@w_fecha_proceso_ayer DATETIME ,
@w_tiempo_espera TINYINT


IF @i_opcion = 'D'
BEGIN
	UPDATE ca_santander_orden_retiro SET sor_banco = '-'+@i_banco
	WHERE sor_banco = @i_banco

	RETURN 0
END


select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @w_fini_domi = pa_datetime
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'FDOMI'
and    pa_producto = 'CCA'

SELECT @w_fini_domi = ISNULL (@w_fini_domi , '02/04/2019')

truncate table ca_santander_archivo


/*CONSULTA DE PARAMETROS CONSTANTES*/
select @w_sep = char(124)


select @w_sp_name_batch = 'cob_cartera..sp_santander_gen_orden_ret'

select @w_path = ba_path_destino
from  cobis..ba_batch
where ba_arch_fuente = @w_sp_name_batch

--Obtiene el parametro de la ubicacion del kernel\bin en el servidor
select @w_s_app = pa_char
from  cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'


select @w_param_reintento = pa_tinyint
from   cobis..cl_parametro
where  pa_producto  = 'CCA'
and    pa_nemonico  = 'NRID'

select @w_param_reintento = isnull(@w_param_reintento, 1)

/*CONSULTA DE PARAMETROS CONSTANTES*/
--select @w_param_dias_proceso = 8
select @w_param_dias_proceso = pa_tinyint
from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'DPDES'

select @w_refer_serv_emi = pa_char
from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'RSEMI'

select @w_nomb_tit_serv = pa_char
from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'NTSER'


select @w_param_nomb_ord = pa_char
from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'NOMORD'

select @w_param_nomb_ord = upper(isnull(@w_param_nomb_ord, 'Santander Inclusion Financiera'))

select @w_param_abrev_ord = pa_char
from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'ABRORD'

select @w_param_abrev_ord = isnull(@w_param_abrev_ord, 'SA de CV')

select @w_param_nomb_ord = @w_param_nomb_ord + space(1) + @w_param_abrev_ord

select @w_param_nrfc_ord = pa_char
from cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'RFCORD'

select @w_param_nrfc_ord = isnull(@w_param_nrfc_ord, 'SIF170801PYA')


select @w_gen_arch_dom_pag = pa_char
from   cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'GADOPA'

select @w_gen_arch_dom_pag = isnull(@w_gen_arch_dom_pag, 'S')

select @w_gen_arch_dom_seg = pa_char
from   cobis..cl_parametro
 where pa_producto = 'CCA'
   and pa_nemonico = 'GADOSE'

select @w_gen_arch_dom_seg = isnull(@w_gen_arch_dom_seg, 'N')


select @w_ncta_cli   = null,
       @w_nombre_cli = null

select @w_valor_iva      = 0,
	   @w_refer_num_emi  = null,
	   @w_refer_leyen_emi= null,
	   @w_param_fpago_ret= 'ND_BCO_MN',
	   @w_toper_grupal   = 'GRUPAL'

/* ESTADOS DE CARTERA */
exec @w_error = sp_estados_cca
@o_est_vigente  = @w_est_vigente out,
@o_est_vencido  = @w_est_vencida out


/*DETERMINAR FECHA DE PROCESO*/
select @w_fecha_proceso = fc_fecha_cierre,
       @w_fecha_hasta   = dateadd(dd, @w_param_reintento, fc_fecha_cierre) ,
       @w_fecha_inicial = dateadd(dd, -@w_param_dias_proceso, fc_fecha_cierre)
from cobis..ba_fecha_cierre
where  fc_producto = 7

SELECT @w_fecha_real  = getdate()  --dateadd(hh, +1, )
SELECT @w_fcabecera  = dateadd(hh, +1,getdate() )

SELECT @w_fecha_clave = convert(VARCHAR, @w_fecha_real, 102)+'h'+convert(VARCHAR, @w_fecha_real, 114)
SELECT @w_fecha_clave = replace(@w_fecha_clave, ':','')
SELECT @w_fecha_clave = replace(@w_fecha_clave, '.','')

SELECT @w_hora = substring(convert(VARCHAR, @w_fcabecera, 114), 1,charindex(':',convert(VARCHAR, @w_fcabecera, 114))-1) +
                 replace(convert(VARCHAR, @w_fecha_proceso, 102),'.','')
SELECT @w_hora = replicate('0',10-len(@w_hora)) + @w_hora


/*ASIGNACION DE VARIABLES FIJAS*/
select
@w_cab_01 = '01',
@w_cab_02 = '0000001',
@w_cab_03 = '30',
@w_cab_04 = '014',
@w_cab_05 = 'E',
@w_cab_06 = '2',
@w_cab_07 = '0000001',
@w_cab_08 = convert(varchar(8),@w_fecha_proceso, 112),
@w_cab_09 = '01',
@w_cab_10 = replicate('0', 27),
@w_cab_11 = dbo.LlenarD(@w_param_nomb_ord, space(1), 40),
@w_cab_12 = dbo.LlenarD(@w_param_nrfc_ord, space(1), 18),
@w_cab_13 = @w_hora,
@w_cab_14 = replicate('0', 172),


@w_det_01 = '02',
@w_det_03 = '30',
@w_det_04 = '01',
@w_det_06 = replicate('0', 32),
@w_det_07 = '51',
@w_det_08 = convert(varchar(8),@w_fecha_proceso, 112),
@w_det_09 = '014',
@w_det_10 = '01',
@w_det_18 = replicate('0', 23),

@w_pie_01 = '09',
@w_pie_03 = '30',
@w_pie_04 = '0000001',
@w_pie_07 = replicate('0', 257)


create table #tmp_ca_data_proceso
(
 op_banco     varchar(24) null,
 op_operacion int         null,
 op_cliente   int         null,
 tipo_ret     char(1)     null
)


--CONDICION DE SALIDA EN CASO DE DOBLE CIERRE POR FIN DE MES NO SE DEBE EJECUTAR
if exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_proceso )
          return 0

/*DETERMINAR PROXIMO CONSECUTIVO Y NOMBRE DE ARCHIVOS*/
select @w_consecutivo = isnull(max(sor_consecutivo), 0) + 1
from ca_santander_orden_retiro
where sor_fecha = @w_fecha_proceso

/* FECHA ANTERIOR DOMICILIACION */
SELECT @w_fecha_real_ant = max(sor_fecha_real)
FROM ca_santander_orden_retiro
WHERE sor_fecha_real < @w_fecha_real

select TOP 1
	@w_domi_fclave_ant = sor_fecha_clave
from ca_santander_orden_retiro
where sor_fecha_real  = @w_fecha_real_ant
  AND sor_banco NOT IN ('cabecera','pie')

select
	@w_domi_fclave_ant = isnull(@w_domi_fclave_ant,'SIN_FECHA')

--//////////////////////////////////////////////////////////////
/* INSERTAR EN EL LOG LAS OPERACIONES QUE DIERON ERROR EN STD O
NUNCA LLEGARON DE STD */

insert into ca_santander_log_pagos(
	sl_secuencial,
	sl_fecha_gen_orden,
	sl_banco,
	sl_cuenta,
	sl_monto_pag,
	sl_referencia,
	sl_archivo,
	sl_tipo_error,
	sl_estado,
	sl_mensaje_err,
	sl_dividendo )
SELECT
	convert(MONEY, substring(sor_linea_dato, 3,7)),
	sor_fecha,
	sor_banco,
	substring(sor_linea_dato, 76,20),
	convert(MONEY, substring(sor_linea_dato, 14,15)),
	CASE WHEN substring(sor_linea_dato ,238,3) = 'SEG' THEN 'PAGO SEGURO' ELSE 'PAGO PRESTAMO' END,
	'ARCHIVO.TXT',
	sor_error,
	'7999',
	'PRESTAMOS QUE NO LLEGARON DESDE SANTANDER',
	0
FROM ca_santander_orden_retiro
WHERE sor_fecha_clave = @w_domi_fclave_ant
AND  sor_error = 'DS'
AND sor_banco NOT IN ('cabecera','pie')
AND sor_procesado IN ('S', 'N')  --- los que llegaron de santander + los que no llegaron

if @@error != 0
BEGIN
   print'falla en guardar log en sp_santander_gen_orden_ret'
	return 710002
END



--//////////////////////////////////////////////////////////////

-- HASTA ENCONTRAR EL SIGUIENTE DIA HABIL
select  @w_fecha_hasta  = dateadd(dd,1,@w_fecha_proceso)

while exists( select 1 from cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional  and df_fecha = @w_fecha_hasta)
   select @w_fecha_hasta= dateadd(dd,1,@w_fecha_hasta)

select  @w_fecha_hasta  = dateadd(dd,-1,@w_fecha_hasta)



--//////////////////////////////////////////////////////////////////////////////////////////
/* DETERMINAR INFORMACION A PROCESAR*/
/* Informacion de PAGOS: solo en el primer intento del dia */

if @w_gen_arch_dom_pag = 'S' AND @w_consecutivo = 1
BEGIN
   /* OPERACIONES CUYA CUOTA VENCEN HOY Y HASTA ANTES DEL SIGUIENTE DIA HABIL*/
   insert into #tmp_ca_data_proceso
   select distinct op_banco, op_operacion, op_cliente,tipo_ret ='N'  --Procesar Operaciones que vencen hoy exigibles
   from ca_operacion, ca_dividendo
   where op_estado in (@w_est_vigente, @w_est_vencida)
   and op_forma_pago = @w_param_fpago_ret
   and op_cuenta is not null
   and op_fecha_ult_proceso = @w_fecha_proceso
   and di_operacion = op_operacion
   and di_estado in (@w_est_vigente, @w_est_vencida)
   and di_fecha_ven between @w_fecha_proceso AND @w_fecha_hasta


  /* OPERACIONES QUE HACEN EL REINTENTO, SON LAS DEL DIA ANTERIOR QUE FALLARON EN SANTANDER +
     LAS QUE NO SE PROCESARON EN DIAS CUANDO NO ESTABA ACTIVO EL IEN
   */
   SELECT
   		@w_ult_fecha_ien = max(sl_fecha_gen_orden)
   FROM ca_santander_log_pagos
   WHERE sl_fecha_gen_orden < @w_fecha_proceso

   insert into #tmp_ca_data_proceso
   select distinct op_banco, op_operacion, op_cliente,tipo_ret ='N'  --Procesar Operaciones que vencen hoy exigibles
   from ca_operacion, ca_dividendo, ca_santander_log_pagos
   where op_estado in (@w_est_vigente, @w_est_vencida)
   and op_forma_pago = @w_param_fpago_ret
   and op_cuenta is not null
   and op_fecha_ult_proceso = @w_fecha_proceso
   and di_operacion = op_operacion
   and di_fecha_ven >= @w_ult_fecha_ien    --*** desde la ultima ejecucion
   and di_fecha_ven <  @w_fecha_proceso    --*** antes del dia de hoy
   AND op_banco     = sl_banco
   AND sl_fecha_gen_orden = @w_ult_fecha_ien  -- ULTIMA EJECUCION A LA ACTUAL (DIA ANTERIOR)
   AND sl_tipo_error      = 'DS'
   AND op_operacion NOT IN (SELECT op_operacion FROM #tmp_ca_data_proceso WHERE tipo_ret ='N')  -- para que no se repitam

   --////////////////////////////////////////////////
   -- PAGOS SOLIDARIOS
   insert into #tmp_ca_data_proceso
   select psd_banco, psd_operacion, psd_cliente, 'S' --Pago Solidarios
   from ca_pago_solidario_det
   where psd_fecha  = @w_fecha_proceso
end

--//////////////////////////////////////////////////////////////////////////////////////////

/* Informacion de SEGUROS */
if @w_gen_arch_dom_seg = 'S'
begin

   SELECT @w_tiempo_espera = pa_tinyint
   FROM cobis..cl_parametro
   WHERE pa_nemonico = 'TESEG'
   AND pa_producto = 'CCA'

   SELECT @w_tiempo_espera = isnull(@w_tiempo_espera,60)

   /* FECHA PROCESO ANTERIOR */
	SELECT @w_fecha_proceso_ayer = max(sod_fecha)
	FROM ca_santander_orden_deposito
	WHERE sod_fecha    < @w_fecha_proceso

   /* TODAS LAS OPERACIONES DESEMBOLSADAS DESDE AYER - HASTA HOY, QUE AUN NO PAGAN SEGURO */
   insert into #tmp_ca_data_proceso
   select distinct se_banco, se_operacion, se_cliente, tipo_ret ='E' -- tipo Seguro Desembolsos
   from ca_seguro_externo, ca_operacion
   where se_estado   = 'N'
   AND op_operacion  = se_operacion
   AND op_fecha_liq >= @w_fecha_inicial      -->= @w_fecha_proceso_ayer
	AND op_fecha_liq >  @w_fini_domi

   /* OPERACIONES QUE YA SE MANDARON A DOMICILIAR */
   DELETE FROM #tmp_ca_data_proceso
   FROM ca_santander_orden_retiro
   WHERE op_banco = sor_banco
	AND tipo_ret ='E'

	/* OPERACIONES QUE AUN NO CUMPLEN 1 HORA DE DISPERSADAS */
   DELETE FROM #tmp_ca_data_proceso
   FROM ca_santander_orden_deposito
   WHERE op_banco = sod_banco
   AND sod_tipo = 'DES'
	AND tipo_ret ='E'
	AND sod_fecha_real > dateadd(mi,-@w_tiempo_espera, @w_fecha_real)


	/* AGREGAR LOS RE-INTENTOS, DE LA ULTIMA EJECUCION*/
	/***********************************
   insert into #tmp_ca_data_proceso
   select distinct op_banco, op_operacion, op_cliente, tipo_ret ='E' -- tipo Seguro Desembolsos
   from
   	ca_operacion,
   	ca_santander_orden_retiro
   where op_banco         = sor_banco
   AND sor_error          = 'DS'
   AND op_operacion  NOT IN (SELECT op_operacion FROM #tmp_ca_data_proceso WHERE tipo_ret ='E')  -- para que no se repitam
   AND sor_fecha_real     = @w_fecha_real_ant
	AND sor_banco     NOT IN ('cabecera','pie')
	AND sor_procesado     IN ('S', 'N')  --- los que llegaron de santander + los que no llegaron
	***************************************/
	/* MARCAR PARA QUE EN UNA SIGUIENTE EJECUCION NO VUELVAN A INSERTAR EN EL LOG */
	UPDATE ca_santander_orden_retiro SET
		sor_procesado = CASE WHEN sor_procesado  = 'S' THEN 'RS' ELSE 'RN' END   -- reenviados SI|NO
	WHERE sor_fecha_clave = @w_domi_fclave_ant
	AND  sor_error = 'DS'
	AND sor_banco NOT IN ('cabecera','pie')
	AND sor_procesado IN ('S', 'N')  --- los que llegaron de santander + los que no llegaron

	if @@error != 0
	BEGIN
	   print'falla en actualizar oren retiro sp_santander_gen_orden_ret'
		return 710003
	END


   /* BORRAR LAS OPERACIONES FALLIDAS EN SANTANTER (DS) DE LA ANTE-PENULTIMA EJECUCION */
   /* XQ SOLO SE HACE UN INTENTO */
	delete from #tmp_ca_data_proceso
   where tipo_ret ='E' -- tipo Seguro Desembolsos
   and op_banco in (select op_banco from  ca_operacion, ca_santander_orden_retiro
					   where op_banco         = sor_banco
					   AND sor_error          = 'DS'
					   AND sor_fecha_real     < @w_fecha_real_ant)
end
--//////////////////////////////////////////////////////////////////////////////////////////

/*REGISTRO EN ESTRUCTURA DE CONTROL: CABECERA*/
insert into ca_santander_orden_retiro(
	sor_consecutivo , sor_fecha,  sor_fecha_real,
	sor_linea,      	sor_banco,  sor_operacion,
	sor_linea_dato,   sor_fecha_clave, sor_error,
	sor_procesado)
select
	@w_consecutivo,   @w_fecha_proceso,  @w_fecha_real,
	0,	               'cabecera',        0,
	@w_cab_01 +	@w_cab_02 +	@w_cab_03 +	@w_cab_04 +	@w_cab_05 +	@w_cab_06 +
	@w_cab_07 +	@w_cab_08 +	@w_cab_09 +	@w_cab_10 +	@w_cab_11 +	@w_cab_12 +
	@w_cab_13 + @w_cab_14 + @w_sep,
	@w_fecha_clave, 'DS', 'N'

select @w_operacionca  = 0,
       @w_count_op     = 1,
	    @w_total_retiro = 0

/*PROCESAMIENTO PARA DETALLE DE ARCHIVO*/
declare cur_ordenes_retiro cursor for
select op_banco, op_operacion, op_cliente, tipo_ret
from  #tmp_ca_data_proceso
where op_operacion > 0
order by op_operacion, tipo_ret desc, op_cliente

open cur_ordenes_retiro

fetch cur_ordenes_retiro into @w_banco, @w_operacionca, @w_cliente, @w_tipo_ret

while @@fetch_status = 0
BEGIN
   SELECT
   @w_nombre            = op_nombre,
   @w_ncta_cli          = op_cuenta,
   @w_toperacion        = op_toperacion,
   @w_fecha_ult_proceso = op_fecha_ult_proceso
   from   ca_operacion
   where  op_operacion = @w_operacionca

    --Pagos por Vencimientos de Cuotas
   if @w_tipo_ret = 'N'
   begin
		select @w_valor_retiro_sol = isnull(sum(psd_monto),0)
		from ca_pago_solidario_det
		where psd_fecha     = @w_fecha_proceso
		and   psd_operacion = @w_operacionca

      --Maxima cuota Exigible
      select
			@w_valor_retiro     = isnull(sum(am_cuota + am_gracia - am_pagado), 0) - @w_valor_retiro_sol,
			@w_cuo_min_vencida  = isnull(min(di_dividendo), 0),
      	@w_cuo_max_vencida  = isnull(max(di_dividendo), 0)
      from ca_dividendo, ca_amortizacion
      where di_operacion = @w_operacionca
      and ((di_estado = @w_est_vencida) or
           (di_estado = @w_est_vigente and di_fecha_ven <= @w_fecha_hasta)) --*** LGU
      and am_operacion = di_operacion
      and am_dividendo = di_dividendo
   end

  --Pago Solidario
   if @w_tipo_ret = 'S'
   begin
      select
			@w_valor_retiro      = psd_monto,
			@w_cuo_max_vencida   = 0,
			@w_cuo_min_vencida   = 0,
			@w_ncta_cli          = psd_cuenta
		from ca_pago_solidario_det
		where psd_fecha     = @w_fecha_proceso
		and psd_operacion = @w_operacionca
		and psd_cliente   = @w_cliente
   end

   -- SEGUROS
   if @w_tipo_ret = 'E'
   begin
      select
			@w_valor_retiro = isnull(sum(se_monto),0),
			@w_cuo_max_vencida   = 0,
			@w_cuo_min_vencida   = 0
		from ca_seguro_externo
		where se_operacion = @w_operacionca
   end

   if @w_ncta_cli is null
   begin
      select @w_error = 720905 --Error cuenta ahorros no existe o no pertenece al cliente seleccionado
	  goto SIGUIENTE
   end

   if @w_valor_retiro <= 0 goto SIGUIENTE

   if @w_toperacion = @w_toper_grupal
   begin
		select @w_grupo = tg_grupo,
			@w_refer_grupal = tg_referencia_grupal
		from   cob_credito..cr_tramite_grupal
		where  tg_operacion  = @w_operacionca
		and    tg_prestamo   = @w_banco

		select @w_nomb_tit_serv = gr_nombre
		from  cobis..cl_grupo
		where gr_grupo = @w_grupo
	end
   ELSE
   	select @w_nomb_tit_serv = @w_nombre,
				 @w_grupo         = 0,
				 @w_refer_grupal  = 'INDIVIDUAL'

   select @w_refer_serv_emi = @w_banco

   select @w_nombre_cli = ltrim(rtrim(isnull(p_p_apellido, ''))) + ' ' +
                          ltrim(rtrim(isnull(p_s_apellido, ''))) + ' ' +
						  ltrim(rtrim(isnull(en_nombre, '')))
   from cobis..cl_ente
   where en_ente = @w_cliente

   SELECT @w_nombre_cli = cob_conta_super.dbo.fn_formatea_ascii_ext(@w_nombre_cli , 'AN')
   SELECT @w_nombre_cli = isnull(@w_nombre_cli, 'NO EXISTE CLIENTE')

	select
		@w_count_op      = @w_count_op + 1,
		@w_total_retiro  = @w_total_retiro + @w_valor_retiro,
		@w_monto_string  = convert(varchar, cast(floor(@w_valor_retiro * 100) as decimal(15,0))),
		@w_refer_serv_emi= isnull(@w_refer_serv_emi, space(1)),
		@w_nomb_tit_serv = isnull(@w_nomb_tit_serv, space(1)),
		@w_iva_string    = convert(varchar, cast(floor(isnull(@w_valor_iva, 0) * 100) as decimal(15,0))),
		@w_refer_num_emi = isnull(@w_refer_num_emi, '0')

   /***** Se asigna dependiente si es pago de seguro o de cuota    ****/

	if (@w_cuo_min_vencida > 0 and @w_cuo_max_vencida > 0)
		select @w_refer_leyen_emi = @w_refer_leyen_emi + convert(varchar, @w_cuo_min_vencida) + 'A' + convert(varchar, @w_cuo_max_vencida)

	IF @w_tipo_ret = 'E'   --SEGURO
		select
--			@w_refer_leyen_emi = 'SEG FECHA VALOR ' +
			@w_refer_leyen_emi = 'SEG FV ' +
										substring(ltrim(rtrim(replace(convert(varchar(10), @w_fecha_ult_proceso, 101), '/', ''))), 1, 8) +
										' PS' + ' FH' + @w_fecha_clave
	ELSE
		select
--			@w_refer_leyen_emi = 'PRE FECHA VALOR ' +
			@w_refer_leyen_emi = 'PRE FV ' +
										substring(ltrim(rtrim(replace(convert(varchar(10), @w_fecha_ult_proceso, 101), '/', ''))), 1, 8) +
--										' PAGO CUOTAS'+ ' FH' + @w_fecha_clave
										' PC'+ ' FH' + @w_fecha_clave

	select
		@w_det_02 = dbo.LlenarI(@w_count_op, '0', 7),
		@w_det_05 = dbo.LlenarI(@w_monto_string, '0', 15),
		@w_det_11 = dbo.LlenarI(@w_ncta_cli, '0', 20),
		@w_det_12 = dbo.LlenarD(@w_nombre_cli, space(1), 40),
		@w_det_13 = dbo.LlenarD(@w_refer_serv_emi, space(1), 40),
		@w_det_14 = dbo.LlenarD(@w_nomb_tit_serv, space(1), 40),
		@w_det_15 = dbo.LlenarI(@w_iva_string, '0', 15)

	select
		@w_detalle = @w_det_01 + 	@w_det_02 +   @w_det_03 +
		@w_det_04 +	@w_det_05 +   @w_det_06 +
		@w_det_07 +	@w_det_08 +   @w_det_09 +
		@w_det_10 +	@w_det_11 +   @w_det_12 +
		@w_det_13 +	@w_det_14 +   @w_det_15


   select @w_refer_num_emi = dbo.HashChar(@w_detalle)

   select @w_det_16 = dbo.LlenarI(@w_refer_num_emi, '0', 7),
		  	 @w_det_17 = dbo.LlenarD(@w_refer_leyen_emi, space(1), 40)

   /*REGISTRO EN ESTRUCTURA DE CONTROL: DETALLE*/
   insert into ca_santander_orden_retiro(
		sor_consecutivo,
		sor_fecha,         sor_fecha_real, sor_linea,
		sor_banco,         sor_operacion,
		sor_linea_dato,
		sor_fecha_clave,   sor_error, sor_procesado)
   select
   	@w_consecutivo,
      @w_fecha_proceso,  @w_fecha_real,  @w_count_op,
      @w_banco,          @w_operacionca,
	   @w_det_01 +	       @w_det_02 + @w_det_03 + @w_det_04 + @w_det_05 +
      @w_det_06 +	       @w_det_07 + @w_det_08 + @w_det_09 + @w_det_10 +
	   @w_det_11 +			 @w_det_12 + @w_det_13 + @w_det_14 + @w_det_15 +
	   @w_det_16 +			 @w_det_17 + @w_det_18 + @w_sep,
	   @w_fecha_clave , 'DS', 'N'

	   if @@error != 0
	   begin
	      select @w_error = @@error
	      goto SIGUIENTE
	   end


   SIGUIENTE:
       fetch cur_ordenes_retiro into @w_banco, @w_operacionca, @w_cliente, @w_tipo_ret

end

close cur_ordenes_retiro
deallocate cur_ordenes_retiro


/*ASIGNACION DE VALORES VARIABLES: PIE DE ARCHIVO*/
select @w_total_string = convert(varchar, cast(floor(@w_total_retiro * 100) as decimal(15,0)))

select @w_pie_02 = dbo.LlenarI(convert(varchar,@w_count_op + 1), '0', 7),
       @w_pie_05 = dbo.LlenarI(convert(varchar,@w_count_op - 1), '0', 7),
	    @w_pie_06 = dbo.LlenarI(@w_total_string, '0', 18)

/*REGISTRO EN ESTRUCTURA DE CONTROL: PIE DE ARCHIVO*/
insert into ca_santander_orden_retiro (
	sor_consecutivo,
	sor_fecha, sor_fecha_real, sor_linea,
	sor_banco, sor_operacion,
	sor_linea_dato,
	sor_fecha_clave, sor_error, sor_procesado)
select
	@w_consecutivo,
	@w_fecha_proceso, @w_fecha_real, @w_count_op + 1,
	'pie', 0,
	@w_pie_01 +	@w_pie_02 +	@w_pie_03 +	@w_pie_04 +
	@w_pie_05 +	@w_pie_06 +	@w_pie_07 +	@w_sep,
	@w_fecha_clave, 'DS', 'N'

if @@error != 0
begin
   select @w_error = @@error
   goto ERROR
end


if exists (select 1
           from  ca_santander_orden_retiro
           where sor_fecha = @w_fecha_proceso
           and   sor_consecutivo = @w_consecutivo
           and   sor_banco not in ('cabecera', 'pie'))
begin
   if @i_param1 = 'IEN'
   begin
      select linea_dato = substring(sor_linea_dato, 1, datalength(sor_linea_dato) - 1)
      from  ca_santander_orden_retiro
      where sor_fecha = @w_fecha_proceso
      and   sor_consecutivo = @w_consecutivo
      order by sor_linea
   end
   else
   begin
		insert into ca_santander_archivo
		select linea_dato = substring(sor_linea_dato, 1, datalength(sor_linea_dato) - 1)
		from  ca_santander_orden_retiro
		where sor_fecha = @w_fecha_proceso
		and   sor_consecutivo = @w_consecutivo
		order by sor_linea

		select @w_nombre_archivo = 'SE' + dbo.LlenarI(@w_cab_06, '0', 5)
		select @w_nombre_archivo = @w_nombre_archivo + convert(varchar(8),@w_fecha_proceso, 112)

		select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_santander_archivo out '

		select @w_destino = @w_path + @w_nombre_archivo + '.txt',
				 @w_errores = @w_path + @w_nombre_archivo + '.err'

		select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

		exec @w_error = xp_cmdshell @w_comando

		if @w_error <> 0 print 'Error Generando Archivo'
   end
end

return 0

ERROR:
  return @w_error

go

