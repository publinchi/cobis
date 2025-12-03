use cob_cartera
go
/*************************************************************************/
/*   ARCHIVO:         reporte_pagos.sp                                   */
/*   NOMBRE LOGICO:   sp_reporte_pagos                                   */
/*   Base de datos:   cob_cartera                                        */
/*   PRODUCTO:        Cartera                                            */
/*   Fecha de escritura:   Enero 2018                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/*************************************************************************/
/*                     PROPOSITO                                         */
/*  El archivo deberá generarse diariamente una vez que se               */
/*  hayan ejecutado los procesos de cierre de día de                     */
/*  CARTERA                                                              */
/*************************************************************************/
/*                     MODIFICACIONES                                    */
/*   FECHA         AUTOR            RAZON                                */
/* 09/Ene/2018    Maria Jose Taco   Emision inicial                      */
/* 01/02/2018     Maria Jose Taco   Modificacion al reporte              */
/* 24/07/2018     Nolberto Vite     Reestruturación de reporte           */
/* 22/10/2018     Maria Jose Taco   Caso 106284                          */
/*************************************************************************/

if exists(select 1 from sysobjects where name = 'sp_reporte_pagos')
    drop proc sp_reporte_pagos
go
create proc sp_reporte_pagos (
    @t_show_version     bit         =   0,
    @i_param1           datetime   =   null -- FECHA DE PROCESO
)as
declare
  @w_sp_name        varchar(20),
  @w_s_app          varchar(50),
  @w_path           varchar(255),  
  @w_msg            varchar(200),  
  @w_return         int,
  @w_dia            varchar(2),
  @w_mes            varchar(2),
  @w_anio           varchar(4),
  @w_fecha_r        varchar(10),
  @w_file_rpt       varchar(40),
  @w_file_rpt_1     varchar(140),
  @w_file_rpt_1_out varchar(140),
  @w_bcp            varchar(2000),
  @w_error          int,
  @w_msg_error      varchar(255),
  @w_max_div		int,
  @w_max_div_his	int

select @w_sp_name = 'sp_reporte_pagos'

--Versionamiento del Programa
if @t_show_version = 1
begin
  print 'Stored Procedure=' + @w_sp_name + ' Version=' + '1.0.0.0'
  return 0
end

if(@i_param1 is null)
  select @i_param1 = (SELECT fp_fecha FROM cobis..ba_fecha_proceso)
  select @i_param1
-- -------------------------------------------------------------------------------
-- DIRECCION DEL ARCHIVO A GENERAR
-- -------------------------------------------------------------------------------
select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

truncate table ca_reporte_pago_tmp

select @w_path = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7 -- CARTERA

select @w_max_div = 0, @w_max_div_his = 0

/* DETERMINAR UNIVERSO DE REGISTROS A REPORTAR */
select 
banco          = tr_banco,
operacion      = tr_operacion,
toperacion     = tr_toperacion,
moneda         = tr_moneda,
oficina        = tr_ofi_oper,
secuencial_rpa = abs(tr_secuencial),
secuencial_pag = convert(int, 0),
fecha_val      = tr_fecha_ref,
usuario        = tr_usuario,
reverso        = case when tr_secuencial < 0 then 'SI' else 'NO' end
into #pagos
from ca_transaccion
where tr_fecha_mov = @i_param1
and   tr_tran      = 'RPA'
and   tr_estado   != 'RV'

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener registros de transacciones'
   goto ERROR_PROCESO
end

update #pagos set
secuencial_pag = tr_secuencial
from ca_transaccion
where tr_operacion = operacion
and   tr_secuencial_ref = secuencial_rpa
and	  tr_tran = 'PAG'

if @@error != 0 begin
select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar registro de pagos'
   goto ERROR_PROCESO
end

/*DETERMINAR LA CUOTA EXIGIBLE DE LOS PRESTAMOS */
select 
di_operacion  = di_operacion,
di_secuencial = secuencial_pag,
di_exigible   = max(di_dividendo) 
into #exigible
from ca_dividendo, #pagos
where di_operacion  = operacion
and   di_fecha_ven <= @i_param1
group by di_operacion, secuencial_pag

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener registros de prestamos'
   goto ERROR_PROCESO
end


INSERT INTO  #exigible 
SELECT operacion, secuencial_pag, 0
from ca_dividendo, #pagos
where di_operacion  = operacion
and   @i_param1 BETWEEN di_fecha_ini  AND di_fecha_ven
AND operacion NOT IN (SELECT di_operacion FROM #exigible)
group by operacion, secuencial_pag



/* OBTENER EL DETALLE DE TODAS LAS TRANSACCIONES A REPORTAR */
select
dtr_operacion      = dtr_operacion,
dtr_secuencial     = dtr_secuencial,
dtr_concepto       = dtr_concepto,
dtr_categoria      = convert(varchar(20), ''),
dtr_concepto_asoc  = convert(varchar(20), ''), 
dtr_categoria_asoc = convert(varchar(20), ''),
dtr_dividendo      = dtr_dividendo,
dtr_exigible       = 'S',
dtr_monto          = sum(dtr_monto)
into #pagos_det
from ca_det_trn, #pagos
where dtr_operacion  = operacion
and   dtr_secuencial = secuencial_pag
and   dtr_concepto <> 'VAC0'
group by dtr_operacion, dtr_secuencial, dtr_dividendo, dtr_concepto

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener registros de detalles de transacciones'
   goto ERROR_PROCESO
end

/* MARCAR LOS VALORES NO EXIGIBLES */
update #pagos_det set
dtr_exigible = 'N'
from #exigible
where dtr_operacion = di_operacion
and   dtr_dividendo > di_exigible

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar valores exigibles'
   goto ERROR_PROCESO
end

/* DETERMINAR LOS RUBROS ASOCIADOS DE LOS CONCEPTOS */
update #pagos_det set
dtr_concepto_asoc = ro_concepto_asociado
from ca_rubro_op
where ro_operacion = dtr_operacion
and   ro_concepto  = dtr_concepto

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar detalle de pagos'
   goto ERROR_PROCESO
end

/* DETERMINAR CATEGORIA DEL RUBRO */
update #pagos_det set
dtr_categoria = co_categoria
from ca_concepto
where dtr_concepto  = co_concepto

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar categoria'
   goto ERROR_PROCESO
end

/* DETERMINAR CATEGORIA DEL RUBRO ASOCIADO */
update #pagos_det set
dtr_categoria_asoc = co_categoria
from ca_concepto
where dtr_concepto_asoc  = co_concepto

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar categoria del rubro asociado'
   goto ERROR_PROCESO
end


/* PASAR A MODALIDAD HORIZONTAL */
select 
dh_operacion  = dtr_operacion,
dh_secuencial = dtr_secuencial,
dh_cap_ne      = sum(case when dtr_categoria = 'C' and dtr_exigible = 'N'       then dtr_monto else 0 end), 
dh_cap_ex      = sum(case when dtr_categoria = 'C' and dtr_exigible = 'S'       then dtr_monto else 0 end), 
dh_int         = sum(case when dtr_categoria = 'I'                              then dtr_monto else 0 end), 
dh_iva_int     = sum(case when dtr_categoria = 'A' and dtr_categoria_asoc = 'I' then dtr_monto else 0 end), 
dh_imo         = sum(case when dtr_categoria = 'M'                              then dtr_monto else 0 end), 
dh_iva_imo     = sum(case when dtr_categoria = 'A' and dtr_categoria_asoc = 'M' then dtr_monto else 0 end), 
dh_com         = sum(case when dtr_categoria = 'O'                              then dtr_monto else 0 end), 
dh_iva_com     = sum(case when dtr_categoria = 'A' and dtr_categoria_asoc = 'O' then dtr_monto else 0 end),
dh_sobrante    = sum(case when dtr_concepto  = 'SOBRANTE'                       then dtr_monto else 0 end),
dh_div_min     = min(dtr_dividendo)
into #pagos_det_h
from #pagos_det
group by dtr_operacion, dtr_secuencial

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener registros de detalles de pagos'
   goto ERROR_PROCESO
end

select
region             = convert(varchar(64), ''),
oficina            = convert(varchar(64), ''),  
oficina_id         = oficina,
gerente            = convert(varchar(64), ''),
coordinador        = convert(varchar(64), ''),
asesor             = convert(varchar(64), ''),
asesor_id          = convert(int,0),
contrato           = banco, 
operacion          = operacion,
secuencial         = secuencial_pag,
grupo_id           = convert(int,0),
grupo              = convert(varchar(64), ''),
cliente            = convert(varchar(64), ''),
cliente_id         = convert(int,0),
dia_pago           = convert(varchar(64), ''),
valor_cuota        = convert(money, 0), 
cuotas_pendientes  = convert(int,0),
cuotas_en_atraso   = convert(int,0),
fecha_trn          = @i_param1, 
fecha_valor        = fecha_val,
fecha_ult_pago     = convert(datetime, NULL),
nro_cuota_pagada   = dh_div_min, 
fecha_cuota_pagada = convert(datetime, NULL),
eventos_pago       = convert(int,0),
saldo_cap_antes    = convert(money, 0),
saldo_cap_ex_antes = convert(money, 0),
importe_tot        = dh_cap_ne + dh_cap_ex + dh_int + dh_iva_int + dh_imo + dh_iva_imo + dh_com + dh_iva_com,
importe_cap        = dh_cap_ne + dh_cap_ex ,
importe_int        = dh_int,
importe_iva_int    = dh_iva_int,
importe_imo        = dh_imo,
importe_iva_imo    = dh_iva_imo,
importe_com        = dh_com,
importe_iva_com    = dh_iva_com,
importe_sob        = dh_sobrante,
saldo_cap_desp     = -1*(dh_cap_ne + dh_cap_ex),
saldo_cap_ex_desp  = -1*(dh_cap_ex),
trn_corresp_id     = convert(varchar(24), ''),
tipo_pago          = convert(varchar(15), 'NORMAL'), --validar con fabian
reverso            = reverso,
origen_pago        = convert(varchar(64), ''), 
usuario            = usuario
into #reporte_pagos
from #pagos, #pagos_det_h
where operacion      = dh_operacion
and   secuencial_pag = dh_secuencial

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener registros de pagos'
   goto ERROR_PROCESO
end

/* DETERMINAR SALDO DE CAPITAL ANTES DEL PAGO */
select 
his_operacion = amh_operacion,
his_secuencial= amh_secuencial,
his_cap_ne    = sum(case when amh_dividendo > di_exigible then amh_cuota - amh_pagado else 0 end),
his_cap_ex    = sum(case when amh_dividendo <=di_exigible then amh_cuota - amh_pagado else 0 end)
into #saldo_his
from ca_amortizacion_his, #exigible
where amh_operacion  = di_operacion
and   amh_secuencial = di_secuencial
and   amh_concepto   = 'CAP'
group by amh_operacion, amh_secuencial

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener capital antes del pago'
   goto ERROR_PROCESO
end

/* DETERMINAR SALDO DE CAPITAL ANTES DEL PAGO */
insert into #saldo_his
select 
his_operacion = amh_operacion,
his_secuencial= amh_secuencial,
his_cap_ne    = sum(case when amh_dividendo > di_exigible then amh_cuota - amh_pagado else 0 end),
his_cap_ex    = sum(case when amh_dividendo <=di_exigible then amh_cuota - amh_pagado else 0 end)
from cob_cartera_his..ca_amortizacion_his, #exigible
where amh_operacion  = di_operacion
and   amh_secuencial = di_secuencial
and   amh_concepto   = 'CAP'
group by amh_operacion, amh_secuencial

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener capital antes del pago en historicos'
   goto ERROR_PROCESO
end

update #reporte_pagos set
saldo_cap_antes    = saldo_cap_antes     + his_cap_ex + his_cap_ne,
saldo_cap_ex_antes = saldo_cap_ex_antes  + his_cap_ex ,
saldo_cap_desp     = saldo_cap_desp      + his_cap_ex + his_cap_ne,
saldo_cap_ex_desp  = saldo_cap_ex_desp   + his_cap_ex 
from #saldo_his
where his_operacion = operacion
and   his_secuencial = secuencial

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de historicos'
   goto ERROR_PROCESO
end

--cuota de sobrante
select
so_operacion 		= operacion,
so_cuota			= convert(money,0),
so_dividendo		= convert(int,0)
into #sobrante
from ca_det_trn,#reporte_pagos
where dtr_operacion	= operacion
and dtr_concepto 	=  'SOBRANTE'

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al cargar sobrantes'
   goto ERROR_PROCESO
end

update #sobrante set 
so_dividendo = (select min(di_dividendo) from ca_dividendo where di_operacion = so_operacion and di_fecha_can = @i_param1)
from ca_dividendo
where di_operacion = so_operacion
and di_fecha_can = @i_param1

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener minima cuota de sobrantes'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
nro_cuota_pagada = so_dividendo
from #sobrante
where so_operacion = operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar registro de sobrantes'
   goto ERROR_PROCESO
end
/* MTA Caso 106284
if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener dividencio'
   goto ERROR_PROCESO
end*/

--datos de ca_operacion
update #reporte_pagos set 
asesor_id = op_oficial,
cliente_id = op_cliente
from cob_cartera..ca_operacion
where op_operacion = operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de operaciones'
   goto ERROR_PROCESO
end

--nombre oficina
update #reporte_pagos set
oficina = a.of_nombre,
region = b.of_nombre
from cobis..cl_oficina a,cobis..cl_oficina b 
where a.of_oficina = oficina_id
and b.of_oficina = a.of_regional

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de oficinas'
   goto ERROR_PROCESO
end

--asesor, cordinador, gerente
select
je_asesor_id 		= asesor_id,
je_asesor 			= convert(varchar(64), ''),
je_coordinador_id 	= convert(int,0),
je_coordinador 		= convert(varchar(64), ''),
je_gerente_id 		= convert(int,0),
je_gerente 			= convert(varchar(64), '')
into #jefes
from #reporte_pagos

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al cargar registro de jefes'
   goto ERROR_PROCESO
end

update #jefes set 
je_asesor = fu_nombre,
je_coordinador_id = fu_jefe
from cobis..cl_funcionario
where fu_funcionario = je_asesor_id

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar Asesor'
   goto ERROR_PROCESO
end

update #jefes set 
je_coordinador = fu_nombre,
je_gerente_id = fu_jefe
from cobis..cl_funcionario
where fu_funcionario = je_coordinador_id

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar Coordinador'
   goto ERROR_PROCESO
end

update #jefes set 
je_gerente = fu_nombre
from cobis..cl_funcionario
where fu_funcionario = je_gerente_id

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar Gerente'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
gerente = je_gerente,
coordinador = je_coordinador,
asesor = je_asesor 
from #jefes
where je_asesor_id = asesor_id

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar datos de Jefes'
   goto ERROR_PROCESO
end

--Se obtiene nombre del clientes
update #reporte_pagos set 
cliente = en_nomlar,
grupo_id = en_grupo
from cobis..cl_ente
where en_ente = cliente_id

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de clientes'
   goto ERROR_PROCESO
end

--nombre de grupo
select
gr_operacion 		= operacion,
gr_grupo_id 		= convert(int,0),
gr_grupo_nom 		= convert(varchar(64), '')
into #grupo
from #reporte_pagos

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al cargar registro de grupos'
   goto ERROR_PROCESO
end

update #grupo set 
gr_grupo_id = dc_grupo
from ca_det_ciclo
where dc_operacion = gr_operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar id de grupos'
   goto ERROR_PROCESO
end

update #grupo set 
gr_grupo_nom = gr_nombre
from cobis..cl_grupo
where gr_grupo = gr_grupo_id

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de grupos'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
grupo_id = gr_grupo_id,
grupo = gr_grupo_nom
from #grupo
where gr_operacion = operacion

--Dia de pago
update #reporte_pagos set 
dia_pago = DATENAME(weekday, di_fecha_ven)
from cob_cartera..ca_dividendo
where di_operacion = operacion
and di_dividendo = nro_cuota_pagada

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de dia de pago'
   goto ERROR_PROCESO
end

update #reporte_pagos set
   dia_pago = CASE 
   WHEN dia_pago = 'Monday'  	THEN 'LUNES'
   WHEN dia_pago = 'Tuesday'  	THEN 'MARTES'
   WHEN dia_pago = 'Wednesday'  THEN 'MIERCOLES'
   WHEN dia_pago = 'Thursday'  	THEN 'JUEVES'
   WHEN dia_pago = 'Friday'  	THEN 'VIERNES'
   WHEN dia_pago = 'Saturday'  	THEN 'SABADO'
   WHEN dia_pago = 'Sunday'  	THEN 'DOMINGO'
   end

--Valor cuotas
update #reporte_pagos set
valor_cuota = (select sum(am_cuota) from ca_amortizacion where am_operacion = operacion and am_dividendo = nro_cuota_pagada)
from ca_amortizacion
where am_operacion = operacion
and am_dividendo = nro_cuota_pagada

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de valor de cuota'
   goto ERROR_PROCESO
end

--cuotas pendientes
select
mc_operacion 		= operacion,
mc_max_cuota 		= max(di_dividendo)
into #max_cuota
from #reporte_pagos,ca_dividendo
where operacion = di_operacion
group by operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al crear tablas de max cuotas'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
cuotas_pendientes = mc_max_cuota - nro_cuota_pagada
from #max_cuota
where mc_operacion = operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de cuotas pendientes'
   goto ERROR_PROCESO
end

--cuotas en atraso
update #reporte_pagos set 
cuotas_en_atraso = (select count(di_dividendo) from ca_dividendo where di_operacion = operacion and di_estado = 2)
from ca_dividendo
where di_operacion = operacion
and di_estado = 2

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de cuotas de atraso'
   goto ERROR_PROCESO
end

--fecha de ultimo pago  
update #reporte_pagos set 
fecha_ult_pago = (select max(tr_fecha_mov) from ca_transaccion where tr_operacion = operacion and tr_estado != 'RV' and tr_tran = 'PAG' and tr_fecha_mov < @i_param1 ) 
from ca_transaccion
where tr_operacion = operacion
and tr_estado != 'RV'
and tr_tran = 'PAG'
and tr_fecha_mov < @i_param1

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de cuotas de atraso'
   goto ERROR_PROCESO
end

--Fecha cuota pagada
update #reporte_pagos set 
fecha_cuota_pagada = di_fecha_ven
from ca_dividendo
where di_operacion = operacion
and di_dividendo = nro_cuota_pagada

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de dia de pago'
   goto ERROR_PROCESO
end

--Eventos del pago
update #reporte_pagos set 
eventos_pago = (select count(distinct(tr_secuencial)) from ca_transaccion,ca_det_trn where tr_operacion = dtr_operacion and tr_secuencial = dtr_secuencial and tr_tran = 'PAG' and dtr_operacion = operacion and dtr_dividendo = nro_cuota_pagada and tr_estado != 'RV')
from ca_transaccion,ca_det_trn
where tr_operacion = dtr_operacion
and tr_secuencial = dtr_secuencial
and tr_tran = 'PAG'
and dtr_operacion = operacion
and dtr_dividendo = nro_cuota_pagada
and tr_estado != 'RV'

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de evento de pago'
   goto ERROR_PROCESO
end

--transacion corresponsal id
/*
Se comenta temporalmente mientras pasa el desarrollo de reverso
select
co_operacion 		= operacion,
co_sec_ing			= secuencial,
co_sec				= convert(int,0),
co_corresp_id		= convert(int,0)	
into #correp
from #reporte_pagos

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al cargar registro para trn corresponsal id'
   goto ERROR_PROCESO
end

update #correp set 
co_sec = cd_secuencial
from ca_corresponsal_det
where cd_operacion  = co_operacion
and   cd_secuencial = co_sec_ing

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar registro de secuencial para trn corresponsal id'
   goto ERROR_PROCESO
end

update #correp set 
co_corresp_id = co_trn_id_corresp
from ca_corresponsal_trn
where co_secuencial = co_sec

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registro para trn corresponsal id'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
trn_corresp_id = co_corresp_id
from #correp
where co_operacion = operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar trn corresponsal id definitivo'
   goto ERROR_PROCESO
end
*/
--Origen de pago
select
or_operacion 		= operacion,
or_secuencial		= secuencial_pag,  --MTA Caso 106284
or_origen 			= convert(varchar(64), ''),
or_descripcion 		= convert(varchar(64), ''),
or_tipo_reduccion   = convert(varchar(2), 'N'),
or_tipo_pago        = convert(varchar(64), 'NORMAL')
into #origen_pago
from #pagos

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al cargar registro de origen de pagos'
   goto ERROR_PROCESO
end

--MTA Inicio Caso 106284
/*
update #origen_pago set 
or_origen = dtr_concepto
from ca_det_trn
where dtr_operacion  = or_operacion
and   dtr_secuencial = or_secuencial
and   dtr_concepto <> 'VAC0'
*/

UPDATE #origen_pago                  
SET or_origen         = abd_concepto,
    or_tipo_reduccion = ab_tipo_reduccion
FROM cob_cartera..ca_abono,
     cob_cartera..ca_abono_det
WHERE ab_operacion    = abd_operacion 
AND or_operacion      = ab_operacion
AND ab_secuencial_pag = or_secuencial
AND abd_concepto     != 'SOBRANTE'
AND ab_secuencial_ing = abd_secuencial_ing

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualizar origen de pagos'
   goto ERROR_PROCESO
end

UPDATE #origen_pago
SET or_tipo_pago = CASE 
   WHEN or_tipo_reduccion = 'T'  AND or_origen <> 'GAR_DEB'	THEN convert(varchar(15), 'R. TIEMPO')
   WHEN or_tipo_reduccion = 'T'  AND or_origen = 'GAR_DEB'	THEN convert(varchar(15), 'GARANTIA')
   --WHEN                              or_origen = 'GAR_CRE'  THEN convert(varchar(15), 'GARANTIA'
   WHEN or_tipo_reduccion = 'C'                         	THEN convert(varchar(15), 'R. CUOTA')
   WHEN or_tipo_reduccion = 'N'                         	THEN convert(varchar(15), 'NORMAL')
   end

update #origen_pago set 
or_descripcion = cp_descripcion
from ca_producto
where cp_producto = or_origen

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar descripcion de origen de pagos'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
origen_pago = or_descripcion,
tipo_pago   = or_tipo_pago    --MTA
from #origen_pago
where or_operacion = operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar descripcion de origen de pagos definitivo'
   goto ERROR_PROCESO
end

----Tipo de pago
--R. Tiempo
/*select
div_operacion 		= operacion,
div_max_div		 	= max(di_dividendo),
div_tipo_pago 		= tipo_pago
into #dividendo
from #reporte_pagos,ca_dividendo
where operacion = di_operacion
and di_estado = 1
group by operacion, tipo_pago


if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al cargar registro para obtener dividendos'
   goto ERROR_PROCESO
end

update #dividendo set 
div_tipo_pago = (select case when max(dih_dividendo) > div_max_div then convert(varchar(15), 'R. TIEMPO') else div_tipo_pago end from ca_dividendo_his where dih_operacion = div_operacion)
from ca_dividendo_his
where dih_operacion = div_operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener tipi de pago en reducion de tiempo'
   goto ERROR_PROCESO
end

update #dividendo set 
div_tipo_pago = (select case when max(dih_dividendo) > div_max_div then convert(varchar(15), 'R. TIEMPO') else div_tipo_pago end from cob_cartera_his..ca_dividendo_his where dih_operacion = div_operacion)
from cob_cartera_his..ca_dividendo_his
where dih_operacion = div_operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener tipi de pago en reducion de tiempo'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
tipo_pago = div_tipo_pago
from #dividendo
where div_operacion = operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de historicos'
   goto ERROR_PROCESO
end

--R. Cuota
select
cu_operacion 		= p.operacion,
cu_secuencial		= secuencial_rpa,
cu_cuota		 	= convert(money, 0),
cu_tipo_pago 		= tipo_pago
into #cuotas
from #pagos p, #reporte_pagos r
where p.operacion = r.operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al cargar registro para obtener cuotas'
   goto ERROR_PROCESO
end

update #cuotas set 
cu_cuota = op_cuota
from ca_operacion
where op_operacion = cu_operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener cuota'
   goto ERROR_PROCESO
end

update #cuotas set 
cu_tipo_pago = (select case when oph_cuota > cu_cuota then convert(varchar(15), 'R. CUOTA') else cu_tipo_pago end from ca_operacion_his where oph_operacion = cu_operacion and oph_secuencial = cu_secuencial)
from ca_operacion_his
where oph_operacion = cu_operacion
and oph_secuencial = cu_secuencial

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener tipo de pago en reducion de cuota'
   goto ERROR_PROCESO
end

update #cuotas set 
cu_tipo_pago = (select case when oph_cuota > cu_cuota then convert(varchar(15), 'R. CUOTA') else cu_tipo_pago end from cob_cartera_his..ca_operacion_his where oph_operacion = cu_operacion and oph_secuencial = cu_secuencial)
from cob_cartera_his..ca_operacion_his
where oph_operacion = cu_operacion
and oph_secuencial = cu_secuencial

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener tipi de pago en reducion de cuota'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
tipo_pago = cu_tipo_pago
from #cuotas
where cu_operacion = operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de historicos'
   goto ERROR_PROCESO
end

--Garantia
update #reporte_pagos set 
tipo_pago = convert(varchar(15), 'GARANTIA')
from #origen_pago
where or_operacion = operacion
and or_origen in ('GAR_CRE', 'GAR_DEB')

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar tipo de pago'
   goto ERROR_PROCESO
end
*/ 
--MTA Fin Caso 106284

--P. Cancelacion
select
pc_operacion 		= operacion,
pc_estado		 	= convert(int, 0),
pc_tipo_pago 		= tipo_pago
into #pcancelacion
from #reporte_pagos

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al cargar registro para obtener P. cancelacion'
   goto ERROR_PROCESO
end

update #pcancelacion set 
pc_estado = op_estado
from ca_operacion
where op_operacion = pc_operacion

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al obtener estado'
   goto ERROR_PROCESO
end

update #reporte_pagos set 
tipo_pago = convert(varchar(15), 'P. CANCELACION')
from #pcancelacion
where pc_operacion = operacion
and pc_estado = 3

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al actualziar registros de tipo P.CANCELACION'
   goto ERROR_PROCESO
end

--Carga cabecera
insert into ca_reporte_pago_tmp(
rp_region,            	rp_oficina,           	rp_oficina_id,        
rp_gerente,           	rp_coordinador,       	rp_asesor,            
rp_contrato,          	rp_grupo_id,          	rp_grupo,           
rp_cliente_id,        	rp_cliente,           	rp_dia_pago,          
rp_valor_cuota,       	rp_cuotas_pendientes, 	rp_cuotas_en_atraso,  
rp_fecha_trn,         	rp_fecha_valor,       	rp_saldo_cap_antes, 
rp_saldo_cap_ex_antes,	rp_fecha_ult_pago,    	rp_nro_cuota_pagada,  
rp_fecha_cuota_pagada,	rp_eventos_pago,      	rp_importe_tot, 
rp_importe_cap,       	rp_importe_int,       	rp_importe_iva_int,   
rp_importe_imo,       	rp_importe_iva_imo,   	rp_importe_com,  
rp_importe_iva_com,   	rp_importe_sob,       	rp_saldo_cap_desp,    
rp_saldo_cap_ex_desp, 	rp_trn_corresp_id,    	rp_tipo_pago,   
rp_reverso,           	rp_origen_pago,       	rp_usuario
)
values( 
'REGION',            						'OFICINA',           		'OFICINA ID',        
'GERENTE',           						'COORDINADOR',       		'ASESOR',            
'CONTRATO',          						'ID GRUPO',          		'NOMBRE GRUPO',           
'ID CLIENTE',        						'NOMBRE CLIENTE',       	'DIA DE PAGO',          
'VALOR CUOTA',       						'CUOTAS PENDIENTES', 		'CUOTAS EN ATRASO',  
'FECHA DE TRANSACCION', 					'FECHA VALOR',       		'SALDO CAPITAL ANTES DEL PAGO', 
'SALDO EXIGIBLE CAPITAL ANTES DEL PAGO',	'FECHA ULTIMO PAGO',    	'NRO CUOTA PAGADA',  
'FECHA DE LA CUOTA',						'EVENTOS DE PAGO',      	'IMPORTE PAGO TOTAL', 
'IMPORTE PAGADO CAP',       				'IMPORTE PAGADO INT',       'IMPORTE PAGADO IVA INT',   
'IMPORTE PAGADO IMO',       				'IMPORTE PAGADO IVA IMO',   'IMPORTE PAGADO COM',  
'IMPORTE PAGADO IVA COM',   				'SOBRANTE',       			'SALDO CAPITAL DESPUES DEL PAGO',    
'SALDO EXIGIBLE CAPITAL DESPUES DEL PAGO', 	'TRN CORRESPONSAL ID',    	'TIPO DE PAGO',   
'REVERSO',           						'ORIGEN DE PAGO',       	'USUARIO'
)

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al insertar cabecera'
   goto ERROR_PROCESO
end

--carga tabla definitiva
insert into ca_reporte_pago_tmp(
rp_region,            							rp_oficina,           						rp_oficina_id,        
rp_gerente,           							rp_coordinador,       						rp_asesor,            
rp_contrato,          							rp_grupo_id,          						rp_grupo,           
rp_cliente_id,        							rp_cliente,           						rp_dia_pago,          
rp_valor_cuota,       							rp_cuotas_pendientes, 						rp_cuotas_en_atraso,  
rp_fecha_trn,         							rp_fecha_valor,       						rp_saldo_cap_antes, 
rp_saldo_cap_ex_antes,							rp_fecha_ult_pago,    						rp_nro_cuota_pagada,  
rp_fecha_cuota_pagada,							rp_eventos_pago,      						rp_importe_tot, 
rp_importe_cap,       							rp_importe_int,       						rp_importe_iva_int,   
rp_importe_imo,       							rp_importe_iva_imo,   						rp_importe_com,  
rp_importe_iva_com,   							rp_importe_sob,       						rp_saldo_cap_desp,    
rp_saldo_cap_ex_desp, 							rp_trn_corresp_id,    						rp_tipo_pago,   
rp_reverso,           							rp_origen_pago,       						rp_usuario
)
select 
isnull(region,' '),											isnull(oficina,' '),           							isnull(oficina_id,' '),        
isnull(gerente,' '),       									isnull(coordinador,' '),       							isnull(asesor,' '),         
isnull(contrato,' '),        								isnull(grupo_id,' '),       							isnull(grupo,' '),         
isnull(cliente_id,' '),										isnull(cliente,' '),           						    isnull(	dia_pago,' '),       
isnull(valor_cuota,' '),       								isnull(cuotas_pendientes,' '), 							isnull(cuotas_en_atraso,' '),
isnull(CONVERT(VARCHAR(10), fecha_trn, 103),' '), 			isnull(CONVERT(VARCHAR(10), fecha_valor, 103),' '),     isnull(saldo_cap_antes,' '),
isnull(saldo_cap_ex_antes,' '),								isnull(CONVERT(VARCHAR(10), fecha_ult_pago, 103),' '),  isnull(nro_cuota_pagada,' '),
isnull(CONVERT(VARCHAR(10), fecha_cuota_pagada, 103),' '),	isnull(eventos_pago,' '),							    isnull(	importe_tot,' '),
isnull(importe_cap,' '),    								isnull(importe_int,' '),      							isnull(importe_iva_int,' '),   
isnull(importe_imo,' '), 									isnull(importe_iva_imo,' '),   						    isnull(	importe_com,' '),  
isnull(importe_iva_com,' '),  								isnull(importe_sob,' '),  							    isnull(	saldo_cap_desp,' '),    
isnull(saldo_cap_ex_desp,' '), 								isnull(trn_corresp_id,' '),								isnull(tipo_pago,' '),   
isnull(reverso,' '),        								isnull(origen_pago,' '),       							isnull(usuario,' ')      
from #reporte_pagos

if @@error != 0 begin
   select 
   @w_error = 9999,
   @w_msg_error = 'Error al insertar registro en tabla final ca_reporte_pago_tmp'
   goto ERROR_PROCESO
end
--

select @w_mes   = substring(convert(varchar,@i_param1, 101),1,2)
select @w_dia   = substring(convert(varchar,@i_param1, 101),4,2)
select @w_anio  = substring(convert(varchar,@i_param1, 101),7,4)

select @w_fecha_r = @w_dia + @w_mes + @w_anio

select @w_file_rpt = 'COBRANZA'
select @w_file_rpt_1     = @w_path + @w_file_rpt + '_' + @w_fecha_r + '.txt'
select @w_file_rpt_1_out = @w_path + @w_file_rpt + '_' + @w_fecha_r + '.err'

SELECT @w_bcp = @w_s_app + 's_app bcp -auto -login ' + 'cob_cartera..ca_reporte_pago_tmp' + ' out ' + @w_file_rpt_1 + ' -c -t"\t" -b 5000 -e' + @w_file_rpt_1_out + ' -config ' + @w_s_app + 's_app.ini'
PRINT '===> ' + @w_bcp 

--Ejecucion para Generar Archivo Datos
exec @w_return = xp_cmdshell @w_bcp

if @w_return <> 0 
begin
  select @w_return = 70146,
  @w_msg = 'Fallo el BCP'
  goto ERROR_PROCESO
end

return 0

ERROR_PROCESO:
     select @w_msg = isnull(@w_msg, 'ERROR GENRAL DEL PROCESO')
     exec cob_cartera..sp_errorlog
     @i_fecha     	  = @i_param1,
	 @i_error         = @w_error,
	 @i_usuario       = 'usrbatch',
	 @i_tran          = 26004,
	 @i_tran_name     = null,
	 @i_rollback      = 'S'

go
