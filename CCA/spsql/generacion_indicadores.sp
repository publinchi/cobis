/************************************************************************/
/*  NOMBRE LOGICO:        generacion_indicadores.sp                     */
/*  NOMBRE FISICO:        sp_generacion_indicadores                     */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         Guisela Fernandez                             */
/*  FECHA DE ESCRITURA:   24/11/2022                                    */
/************************************************************************/
/*                           IMPORTANTE                                 */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Proceso para obtencion de indicadores                               */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR         CAMBIO                                 */
/* 24/11/2022     G. Fernandez   Versión inicial                        */
/* 16/01/2023     G. Fernandez   B754767 Validación de metas            */
/*                               cargadas                               */
/* 15/18/2023     K. Rodriguez   B880695 Corr. división por cero        */
/* 02/10/2023     G. Fernandez   R216466 Corr. de calculos  de ofic.    */
/*                               con validación de fecha de proceso     */
/* 29/11/2023     K. Rodriguez   R218340 Ajustes de calculo varios      */
/* 20/12/2023     K. Rodriguez   R221519 Ajustes de calculo varios      */
/* 05/01/2024     K. Rodriguez   R222131 Ajustes cal. val sin riesgo    */
/* 05/01/2024     K. Rodriguez   R223885 Ajuste indicadores J. Agencia  */
/* 21/03/2024     K. Rodriguez   R229919 Ajuste ind. riesgo y calidad   */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_generacion_indicadores')
   drop proc sp_generacion_indicadores 
go

create proc sp_generacion_indicadores 
(
@i_param1         datetime    = null,                              --fecha_proceso
@i_param2        varchar(255) = 'C:\cobis\vbatch\cartera\listados' -- Directorio de ubicacion de archivos
)
as 

declare
@w_sp_name               varchar (32),
@w_error                 int = 0,
@w_inicio_mes            DATETIME,
@w_oficina               int,
@w_oficial               int,
@w_supervisor            int,
@w_anio                  int,
@w_mes                   int,
@w_fecha_proceso         datetime,
@w_nombre_arch           varchar(255),
@w_return                int

-->Fecha de Porceso 
select @w_fecha_proceso = isnull(@i_param1,fp_fecha)
from cobis..ba_fecha_proceso

--Fecha de inicio de mes, identificacion de año y mes
select @w_inicio_mes =  dateadd(dd,-(day(@w_fecha_proceso)-1),@w_fecha_proceso),
       @w_anio = datepart(yy, @w_fecha_proceso),
       @w_mes  = datepart(MM, @w_fecha_proceso)

begin tran
--Validacion de operaciones ya ingresadas en la fecha de proceso
if exists (select 1 from ca_incentivos_detalle_operaciones where ido_fecha_proceso = @w_fecha_proceso )
begin
   delete from ca_incentivos_detalle_operaciones
   where ido_fecha_proceso = @w_fecha_proceso
end

--Inicia de generación de universo de operaciones
insert into ca_incentivos_detalle_operaciones
select  @w_fecha_proceso,    do_banco,          do_estado_contable,    do_codigo_cliente,    
        do_oficial,          do_oficina,        do_tipo_operacion,     0, 0, 
		do_saldo_cap_total,  do_dias_mora_365,  0
from cob_conta_super..sb_dato_operacion
where do_estado_contable not in (0,99, 6)
and   do_fecha = @w_fecha_proceso

if @@error <> 0 
begin
   select @w_error = 725224
   goto ERROR
end

--Obtención de montos de interes
select op_banco, 'monto_interes' =isnull(sum(dtr_monto),0)
into #tabla_interes
from ca_incentivos_detalle_operaciones,
     ca_operacion,
     ca_transaccion,
     ca_det_trn,
     ca_abono,
     ca_abono_det
where op_banco          = ido_banco
and   ab_operacion      = op_operacion
and   ab_operacion      = abd_operacion
and   ab_operacion      = tr_operacion
and   ab_operacion      = dtr_operacion
and   ab_secuencial_ing = abd_secuencial_ing
and   ab_secuencial_pag = tr_secuencial
and   dtr_secuencial    = tr_secuencial
and   ab_estado         = 'A'
and   abd_tipo          = 'PAG'
and   tr_fecha_mov      between @w_inicio_mes and @w_fecha_proceso
and   tr_estado         in ('ING','CON')
and   dtr_concepto      in ('INT','IMO' ) --cambiar la identificacion de concepto por busqueda en la tabla
and   abd_concepto      in (select c.codigo 
                            from cobis..cl_tabla t, 
							     cobis..cl_catalogo c
                            where t.tabla = 'ca_formas_pago_incentivos'
                            and t.codigo  = c.tabla
							and c.estado  = 'V')
--and  (abd_concepto      like '%EFMN%' or abd_concepto like '% NA%' or abd_concepto like '%COLEC%')
and   ido_fecha_proceso = @w_fecha_proceso
group by op_banco 

update ca_incentivos_detalle_operaciones
set ido_intereses = monto_interes
from #tabla_interes
where ido_banco = op_banco
and   ido_fecha_proceso = @w_fecha_proceso

if @@error <> 0 
begin
   select @w_error = 725225
   goto ERROR
end

--Proceso para identificar capital con mora
update ca_incentivos_detalle_operaciones
set ido_capital_conmora = CASE when do_cap_vencido <= 0 then 0 else 1 end
from cob_conta_super..sb_dato_operacion
where ido_banco = do_banco
and ido_fecha_proceso = do_fecha
and   ido_fecha_proceso = @w_fecha_proceso

if @@error <> 0 
begin
   select @w_error = 725226
   goto ERROR
end

update ca_incentivos_detalle_operaciones
set ido_riesgo = isnull(ido_saldo_tot_cap, 0)
where ido_capital_conmora > 0
and   ido_fecha_proceso = @w_fecha_proceso

if @@error <> 0 
begin
   select @w_error = 725227
   goto ERROR
end

--Aplicación de filtros, se excluye operaciones por catalogo
delete from ca_incentivos_detalle_operaciones
where ido_toperacion     in (select c.valor from cobis..cl_tabla t, cobis..cl_catalogo c
                             where t.codigo = c.tabla 
                             and   t.tabla = 'ca_toperaciones_sin_incentivos') --creacion de catalogo
and   ido_fecha_proceso  = @w_fecha_proceso

if @@error <> 0 
begin
   select @w_error = 725228
   goto ERROR
end

--Creación de tabla de observaciones_validaciones

if exists(select 1 from sysobjects where name ='comentario_validaciones')
begin
   DROP TABLE comentario_validaciones
end

create table comentario_validaciones (
   oficina         int,
   oficial         int,
   comentario      descripcion
)

   ----------------------------------------------
--|       SECCION DE CALCULO DE OFICIALES        |--
   ----------------------------------------------

--Validacion de operaciones ya ingresadas en la fecha de proceso
if exists (select 1 from ca_incentivos_calculo_comisiones where icc_fecha_proceso = @w_fecha_proceso )
begin
   delete from ca_incentivos_calculo_comisiones
   where icc_fecha_proceso = @w_fecha_proceso
end

--Validación de registro de indicadores con metas
insert into comentario_validaciones
select distinct ido_oficina, 
                ido_oficial, 
                'No existe la meta registrada para el oficial ' + convert(varchar(10),ido_oficial) + ' en la oficina ' + + convert(varchar(10),ido_oficina)   AS comentario
from ca_incentivos_detalle_operaciones
left join ca_incentivos_metas 
on ido_oficina  = im_oficina 
and ido_oficial = im_cod_asesor
and im_anio     = datepart(yy, @w_fecha_proceso)
and im_mes      = datepart(mm, @w_fecha_proceso)
where im_oficina        is null
and im_cod_asesor       is null
and ido_fecha_proceso   = @w_fecha_proceso
order by ido_oficina, ido_oficial

--Ingreso inicial de registro de oficiales 
insert into ca_incentivos_calculo_comisiones (icc_oficina, icc_oficial,icc_fecha_proceso)
select distinct ido_oficina, ido_oficial, @w_fecha_proceso
from ca_incentivos_detalle_operaciones, ca_incentivos_metas
where im_anio = datepart(yy,  @w_fecha_proceso)
and im_mes = datepart(MM,  @w_fecha_proceso)
and im_oficina = ido_oficina
and im_cod_asesor = ido_oficial
and ido_fecha_proceso   = @w_fecha_proceso

-- Datos de iniciales de funcionarios 
update ca_incentivos_calculo_comisiones 
set icc_anio                       = @w_anio,
    icc_mes                        = @w_mes,
    icc_cod_ofi_superior           = oc_ofi_nsuperior,
	icc_cod_funcionario            = oc_funcionario,
    icc_nombre_oficial             = fu_nombre, 
    icc_cod_planilla               = fu_nomina, 
    icc_tipo_cargo                 = 'O',
	icc_saldo_total                = 0,
    icc_saldo_vencimiento          = 0,
    icc_saldo_castigo              = 0,
    icc_saldo_sin_riesgo           = 0,
    icc_saldo_excepciones          = 0,
    icc_calculo_calidad            = 0,
    icc_riesgo_grupal              = 0,
    icc_metas_mes                  = 0,
	icc_indicador_clientes         = 0,
    icc_indicador_riesgo           = 0,
    icc_indicador_cumplimiento     = 0,
    icc_indicador_interes          = 0,
    icc_porc_clientes              = 0,
    icc_porc_riesgo                = 0,
    icc_porc_cumplimiento          = 0,
    icc_incen_clientes             = 0,
    icc_incen_riesgo               = 0,
    icc_incen_cumplimineto         = 0,
    icc_total_mensual              = 0,
    icc_total_mensual_ajustado     = 0,
    icc_pago_quincenal             = 0
from cobis..cc_oficial, cobis..cl_funcionario
where oc_oficial        = icc_oficial
and   oc_funcionario    = fu_funcionario
and icc_fecha_proceso   = @w_fecha_proceso
		
if @@error <> 0 
begin
   select @w_error = 725229
   goto ERROR
end

--Obtencion de total clientes y Saldo cap (De Operaciones con estado distinto de Canceladas y castigadas)
select 'oficina'   = ido_oficina, 
       'oficial'   = ido_oficial, 
       'clientes'  = count(distinct(ido_cliente)), 
       'saldo_cap' = sum(ido_saldo_tot_cap)
into #incentivos_suma_valores
from ca_incentivos_detalle_operaciones
where ido_fecha_proceso   = @w_fecha_proceso
and   ido_estado not in (3,4)
group by ido_oficina, ido_oficial

update ca_incentivos_calculo_comisiones
set icc_indicador_clientes  = round(clientes,2),
	icc_saldo_total         = round(saldo_cap,2)
from #incentivos_suma_valores
where icc_oficina       = oficina
and   icc_oficial       = oficial
and   icc_fecha_proceso = @w_fecha_proceso
        
if @@error <> 0 
begin
	select @w_error = 725230
	goto ERROR
end

--Obtencion de intereses
select 'oficina'   = ido_oficina, 
       'oficial'   = ido_oficial, 
       'intereses' = sum(ido_intereses)
into #incentivos_suma_valores_int
from ca_incentivos_detalle_operaciones
where ido_fecha_proceso   = @w_fecha_proceso
group by ido_oficina, ido_oficial

update ca_incentivos_calculo_comisiones
set icc_indicador_interes   = round(intereses,2)
from #incentivos_suma_valores_int
where icc_oficina       = oficina
and   icc_oficial       = oficial
and   icc_fecha_proceso = @w_fecha_proceso
        
if @@error <> 0 
begin
	select @w_error = 725230
	goto ERROR
end

--Saldo de capital vencido	
select 'oficina'        = ido_oficina, 
       'oficial'        = ido_oficial, 
       'saldo_cap_ven'  = isnull(sum(ido_saldo_tot_cap),0)
into #saldo_riesgo
from ca_incentivos_detalle_operaciones
where ido_capital_conmora > 0
and   ido_fecha_proceso   = @w_fecha_proceso
and   ido_estado not in (3,4)		
group by ido_oficina, ido_oficial

update ca_incentivos_calculo_comisiones
set icc_saldo_vencimiento      =  isnull(saldo_cap_ven,0)
from  #saldo_riesgo 
where icc_oficina       = oficina
and   icc_oficial       = oficial
and   icc_fecha_proceso = @w_fecha_proceso
        
if @@error <> 0 
begin
	select @w_error = 725230
	goto ERROR
end

--Saldo de capital sin riesgo	
update ca_incentivos_calculo_comisiones
set icc_saldo_sin_riesgo      = icc_saldo_total - isnull(icc_saldo_vencimiento,0)
from  #saldo_riesgo full outer join ca_incentivos_calculo_comisiones
on    icc_oficina       = oficina
and   icc_oficial       = oficial
and   icc_fecha_proceso = @w_fecha_proceso
        
if @@error <> 0 
begin
	select @w_error = 725230
	goto ERROR
end

--Calculo de riesgo grupal
select 'oficina_tg'   = ido_oficina, 
       'saldo_cap'    = sum(ido_saldo_tot_cap)
into #saldo_total_grupal
from ca_incentivos_detalle_operaciones
where ido_fecha_proceso = @w_fecha_proceso
and   ido_estado not in (3,4)
group by ido_oficina

select 'oficina_rg'        = ido_oficina,  
       'saldo_riesgo'  = isnull(sum(ido_saldo_tot_cap),0)
into #saldo_riesgo_grupal
from ca_incentivos_detalle_operaciones
where ido_capital_conmora > 0
and   ido_estado not in (3,4)
and ido_fecha_proceso = @w_fecha_proceso		
group by ido_oficina

update ca_incentivos_calculo_comisiones
set icc_riesgo_grupal = round((saldo_riesgo / saldo_cap) * 100,2)
from #saldo_total_grupal, #saldo_riesgo_grupal
where icc_oficina = oficina_tg
and   oficina_tg  = oficina_rg
and   icc_fecha_proceso = @w_fecha_proceso

if @@error <> 0 
begin
	select @w_error = 725231
	goto ERROR
end
		
--Actualización de campo saldo castigo
update ca_incentivos_calculo_comisiones
set icc_saldo_castigo    = isnull(round(ie_monto,2),0)
from ca_incentivos_excepciones
where icc_oficial       = ie_oficial
and   icc_anio          = ie_anio
and   icc_mes           = ie_mes
and   ie_tipo_excepcion = 1
and   icc_fecha_proceso = @w_fecha_proceso

if @@error <> 0 
begin
	select @w_error = 725232
	goto ERROR
end

--Actializacion de excepciones de riesgo de oficiales
update ca_incentivos_calculo_comisiones
set icc_saldo_excepciones = round(ie_monto,2)
from  ca_incentivos_excepciones
where icc_oficial       = ie_oficial
and   icc_anio          = ie_anio
and   icc_mes           = ie_mes
and   ie_tipo_excepcion = 2
and   icc_fecha_proceso = @w_fecha_proceso

--actualizaciones de valores 

update ca_incentivos_calculo_comisiones
set icc_saldo_sin_riesgo = case when (icc_saldo_sin_riesgo + icc_saldo_excepciones) > icc_saldo_total
                           then icc_saldo_total
                           else (icc_saldo_sin_riesgo + icc_saldo_excepciones)
                           end
where icc_saldo_total    != icc_saldo_sin_riesgo
and   icc_fecha_proceso   = @w_fecha_proceso

if @@error <> 0 
begin
	select @w_error = 725232
	goto ERROR
end

-- Calculo de indicador de riego
update ca_incentivos_calculo_comisiones
set icc_calculo_calidad  = case when (icc_saldo_total + icc_saldo_castigo ) > 0.0
                                then round((icc_saldo_sin_riesgo * 100  / isnull((icc_saldo_total + icc_saldo_castigo ),0) * 100)/ 100,2)
								when isnull(icc_saldo_total,0) > 0
								then round((icc_saldo_sin_riesgo * 100 / isnull(icc_saldo_total,0)*100)/ 100,2)
                                else 0
                                end,
    icc_indicador_riesgo = case when (icc_saldo_total + icc_saldo_castigo ) > 0.0
                                then 100 - round((icc_saldo_sin_riesgo * 100 / isnull((icc_saldo_total + icc_saldo_castigo ),0) * 100)/ 100,2)
								when isnull(icc_saldo_total,0) > 0
								then 100 - round((icc_saldo_sin_riesgo * 100/ isnull(icc_saldo_total,0)* 100)/ 100,2)
                                else 0
                                end
where icc_fecha_proceso   = @w_fecha_proceso

if @@error <> 0 
begin
	select @w_error = 725230
	goto ERROR
end

--Ingreso de valor de metas
update ca_incentivos_calculo_comisiones
set icc_metas_mes = im_monto_proyectado
from ca_incentivos_metas
where im_anio             = icc_anio 
and   im_mes              = icc_mes
and   im_oficina          = icc_oficina
and   im_cod_asesor       = icc_oficial
and   icc_anio            = @w_anio
and   icc_mes             = @w_mes
and   icc_fecha_proceso   = @w_fecha_proceso

if @@error <> 0 
begin
	select @w_error = 725230
	goto ERROR
end

--Calculo de cumplimiento
update ca_incentivos_calculo_comisiones
set icc_indicador_cumplimiento = case icc_metas_mes when 0 then 0 else round((icc_saldo_total/icc_metas_mes) * 100,2) end  
where icc_anio            = @w_anio
and   icc_mes             = @w_mes
and   icc_fecha_proceso   = @w_fecha_proceso

if @@error <> 0 
begin
	select @w_error = 725230
	goto ERROR
end

   -------------------------------------------------
--|       SECCION DE CALCULO DE SUPERVISORES        |--
   -------------------------------------------------
select distinct 
      icc_oficina as oficina, 
      icc_cod_ofi_superior as oficial,
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY icc_indicador_clientes) OVER(PARTITION BY icc_oficina, icc_cod_ofi_superior) as indicador_cliente,
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY icc_indicador_riesgo) OVER(PARTITION BY icc_oficina, icc_cod_ofi_superior) as indicador_riesgo,      
      PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY icc_indicador_cumplimiento) OVER(PARTITION BY icc_oficina, icc_cod_ofi_superior)as indicador_cumplimiento              			  
into #ca_indicadores_supervisores				
from ca_incentivos_calculo_comisiones
where icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

select 'oficial'          = icc_cod_ofi_superior, 
       'oficina'          = icc_oficina,
       'promedio_interes' = avg(icc_indicador_interes)              			  
into #ca_indicadores_supervisores_interes				
from ca_incentivos_calculo_comisiones
where icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio
group by icc_cod_ofi_superior,icc_oficina

insert into ca_incentivos_calculo_comisiones(
       icc_fecha_proceso, 
	   icc_anio, 
	   icc_mes, 
	   icc_oficina,
       icc_oficial,
       icc_cod_funcionario,	   
	   icc_nombre_oficial, 
	   icc_cod_planilla, 
	   icc_cod_ofi_superior,
	   icc_tipo_cargo,
	   icc_indicador_clientes,    
	   icc_indicador_riesgo,      
       icc_indicador_cumplimiento)
select @w_fecha_proceso, 
       @w_anio, 
	   @w_mes, 
	   oficina,
       oficial, 
	   oc_funcionario,
	   fu_nombre,
       fu_nomina, 
	   oc_ofi_nsuperior,
	   'S',
	   round(indicador_cliente,2), 
	   round(indicador_riesgo,2),
	   round(indicador_cumplimiento,2)
from #ca_indicadores_supervisores , cobis..cc_oficial, cobis..cl_funcionario
where oc_oficial     = oficial
and   oc_funcionario = fu_funcionario

if @@error <> 0 
begin
	select @w_error = 725233
	goto ERROR
end

		
update ca_incentivos_calculo_comisiones
set icc_indicador_interes = round(promedio_interes,2)
from #ca_indicadores_supervisores_interes
where icc_oficina         = oficina
and   icc_oficial         = oficial
and   icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio
and   icc_tipo_cargo      = 'S'

if @@error <> 0 
begin
	select @w_error = 725233
	goto ERROR
end

   --------------------------------------
--|SECCION DE CALCULO DE JEFES DE OFICINA|--
   --------------------------------------
select 'oficina'          = ioi1.icc_oficina,
       'oficial'          = ioi1.icc_cod_ofi_superior, 
	   'promedio_cliente' = avg(ioi2.icc_indicador_clientes),
       'promedio_interes' = avg(ioi2.icc_indicador_interes),
       'cumplimiento'     = case sum(ioi2.icc_metas_mes) when 0 then 0 else (sum(ioi2.icc_saldo_total)/ sum(ioi2.icc_metas_mes)) * 100  end  
into #ca_indicadores_jefes_oficina				
from ca_incentivos_calculo_comisiones ioi1
inner join ca_incentivos_calculo_comisiones ioi2 on ioi1.icc_oficial = ioi2 .icc_cod_ofi_superior
where ioi1.icc_fecha_proceso   = @w_fecha_proceso
and   ioi1.icc_mes             = @w_mes
and   ioi1.icc_anio            = @w_anio
and   ioi1.icc_tipo_cargo      = 'S'
and   ioi1.icc_fecha_proceso   = ioi2.icc_fecha_proceso
and   ioi1.icc_mes             = ioi2.icc_mes
and   ioi1.icc_anio            = ioi2.icc_anio
group by ioi1.icc_cod_ofi_superior,ioi1.icc_oficina

insert into ca_incentivos_calculo_comisiones(
       icc_fecha_proceso, 
	   icc_anio, 
	   icc_mes, 
	   icc_oficina,
       icc_oficial, 
	   icc_cod_funcionario,
	   icc_nombre_oficial, 
	   icc_cod_planilla, 
	   icc_cod_ofi_superior,
	   icc_tipo_cargo,
	   icc_indicador_clientes,
       icc_indicador_cumplimiento,	   
	   icc_indicador_interes)
select @w_fecha_proceso, 
       @w_anio, 
	   @w_mes, 
	   oficina,
       oficial,
       oc_funcionario,	   
	   fu_nombre,
       fu_nomina, 
	   oc_ofi_nsuperior,
	   'J',
	   round(promedio_cliente,2),
	   round(fo.cumplimiento,2),
	   round(promedio_interes,2) 
from #ca_indicadores_jefes_oficina fo, cobis..cc_oficial, cobis..cl_funcionario
where oc_oficial     = oficial
and   oc_funcionario = fu_funcionario

if @@error <> 0 
begin
	select @w_error = 725234
	goto ERROR
end

update ca_incentivos_calculo_comisiones
set icc_indicador_riesgo = round((saldo_riesgo / saldo_cap) *100,2)
from #saldo_total_grupal, #saldo_riesgo_grupal
where icc_oficina    = oficina_tg
and   oficina_tg     = oficina_rg
and   icc_tipo_cargo  = 'J'
and icc_fecha_proceso = @w_fecha_proceso
and icc_anio          = @w_anio
and icc_mes           = @w_mes

if @@error <> 0 
begin
	select @w_error = 725234
	goto ERROR
end

commit tran

--Salida de archivo con observaciones de validaciones
select @w_nombre_arch  =  @i_param2 +'\comentarios_validaciones'+ convert(VARCHAR(24),@w_fecha_proceso,23)+ '.csv'

exec @w_return       = cobis..sp_bcp_archivos
	@i_sql              = 'cob_cartera..comentario_validaciones',   --select o nombre de tabla para generar archivo plano
	@i_tipo_bcp         = 'out',                                    --tipo de bcp in,out,queryout
	@i_rut_nom_arch     = @w_nombre_arch,                           --ruta y nombre de archivo
	@i_separador        = ';'                                       --separador
	
if @w_return != 0
begin
  select @w_error   = 725243
  GOTO ERROR
end

return 0

ERROR: 
while @@trancount > 0 ROLLBACK TRAN         
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error 

go
