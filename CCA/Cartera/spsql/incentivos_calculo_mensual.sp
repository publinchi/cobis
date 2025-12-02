/************************************************************************/
/*   NOMBRE LOGICO:      incentivos_calculo_mensual.sp                  */
/*   NOMBRE FISICO:      sp_incentivos_calculo_mensual                  */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Guisela Fernandez                              */
/*   FECHA DE ESCRITURA: 12/12/2022                                     */
/************************************************************************/
/*                     IMPORTANTE                                       */
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
/*  Proceso para el calculo de incentivos                               */
/************************************************************************/
/* CAMBIOS                                                              */
/* FECHA           AUTOR             CAMBIO                             */
/* 12/12/2022     G. Fernandez       Versión inicial                    */
/* 16/01/2023     G. Fernandez       B754767 Control de transacciones   */
/* 30/01/2024     K. Rodríguez       R224404 Ajuste cols reporte RRHH   */
/* 08/04/2024     K. Rodríguez       R225308 Ajuste nómina reporte RRHH */
/************************************************************************/

use cob_cartera
go

if exists(select 1 from sysobjects where name ='sp_incentivos_calculo_mensual')
   drop proc sp_incentivos_calculo_mensual

go

create proc sp_incentivos_calculo_mensual
(
@i_param1        datetime  = null, --fecha_proceso
@i_param2        varchar(255) = 'C:\cobis\vbatch\cartera\listados' -- Directorio de ubicacion de archivos
)
as 

declare
@w_sp_name               varchar (32),
@w_error                 int = 0,
@w_return                int,
@w_inicio_mes            DATETIME,
@w_oficina               int,
@w_oficial               int,
@w_anio                  int,
@w_mes                   int,
@w_fecha_proceso         datetime,
@w_nombre_arch           varchar(255),
@w_num_oficinas          int,
@w_contador_oficina      int

-->Fecha de Porceso 
select @w_fecha_proceso = isnull(@i_param1,fc_fecha_cierre)
from cobis..ba_fecha_cierre
where fc_producto = 7


--Obtencion de año y mes
select @w_anio = datepart(yy, @w_fecha_proceso)
select @w_mes  = datepart(MM, @w_fecha_proceso)

--Validacion si existen datos para calculo
if not exists (select 1 from ca_incentivos_calculo_comisiones where icc_anio = @w_anio and icc_mes = @w_mes )
begin
   select @w_error = 725236 
   goto ERROR
end

begin tran
--Carga de reglas desde el administrador
exec @w_return = sp_carga_reglas_incentivos
if @w_return <> 0
begin
	select @w_error = @w_return
    goto ERROR
end

--Valores de porcentajes de clientes
update ca_incentivos_calculo_comisiones
set icc_porc_clientes = isnull(irc_porcentaje_incentivo,0)
from ca_incentivos_rangos_clientes
where (icc_indicador_clientes between irc_rango_inicial and irc_rango_final)
and   irc_cargo           = icc_tipo_cargo
and   icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725236
	goto ERROR
end

--Valores de porcentajes de riesgo
update ca_incentivos_calculo_comisiones
set icc_porc_riesgo = isnull(irr_porcentaje_incentivo,0)
from ca_incentivos_rangos_riesgo
where (icc_indicador_riesgo between irr_rango_inicial and irr_rango_final)
and   irr_cargo           = icc_tipo_cargo
and   icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725236
	goto ERROR
end

--Valores de porcentajes de cumplimiento
update ca_incentivos_calculo_comisiones
set icc_porc_cumplimiento = isnull(ircc_porcentaje_incentivo,0)
from ca_incentivos_rangos_cumplimiento_cartera
where (icc_indicador_cumplimiento between ircc_rango_inicial and ircc_rango_final)
and   ircc_cargo          = icc_tipo_cargo
and   icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725236
	goto ERROR
end

--Montos de incentivos 
update ca_incentivos_calculo_comisiones
set icc_incen_clientes     =  isnull(round(icc_porc_clientes * icc_indicador_interes,2),0),
    icc_incen_riesgo       =  isnull(round(icc_porc_riesgo   * icc_indicador_interes,2),0),
	icc_incen_cumplimineto =  isnull(round(icc_porc_cumplimiento  * icc_indicador_interes,2),0)
where icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725237
	goto ERROR
end
	
--Sumatoria de total mensualizado
update ca_incentivos_calculo_comisiones
set icc_total_mensual = round(icc_incen_clientes + icc_incen_riesgo + icc_incen_cumplimineto,2)
where icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725238
	goto ERROR
end	

--Validacion de comisiones Maximas
update ca_incentivos_calculo_comisiones
set icc_total_mensual = case when icc_total_mensual > (select c.valor 
                                             from cobis..cl_tabla t, cobis..cl_catalogo c
                                             where t.codigo = c.tabla 
                                             and   t.tabla = 'ca_incentivos_tam_ofi_comimax'
                                             and c.codigo = (select c.valor 
                                                             from cobis..cl_tabla t, cobis..cl_catalogo c
                                                             where t.codigo = c.tabla 
                                                             and   t.tabla = 'ca_incentivos_tamanio_oficina'
                                                             and c.codigo = icc_oficial))
	                          then (select c.valor 
                                    from cobis..cl_tabla t, cobis..cl_catalogo c
                                    where t.codigo = c.tabla 
                                    and   t.tabla = 'ca_incentivos_tam_ofi_comimax'
                                    and c.codigo = (select c.valor 
                                                    from cobis..cl_tabla t, cobis..cl_catalogo c
                                                    where t.codigo = c.tabla 
                                                    and   t.tabla = 'ca_incentivos_tamanio_oficina'
                                                    and c.codigo = icc_oficial))
							  else icc_total_mensual end
where icc_tipo_cargo      = 'S'
and   icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725239
	goto ERROR
end	

--Inicalmente se igual el valor mensual ajustaso al valor inicial
update ca_incentivos_calculo_comisiones
set icc_total_mensual_ajustado = round(icc_total_mensual,2)
where  icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725240
	goto ERROR
end	
	
--Actualizacion de total mesualizado si existen ajuste
update ca_incentivos_calculo_comisiones
set icc_total_mensual_ajustado = isnull(ie_monto,icc_total_mensual),
    icc_descripcion_ajuste     = ie_comentarios_ajuste
from  ca_incentivos_excepciones
where icc_oficial         = ie_oficial
and   icc_anio            = ie_anio
and   icc_mes             = ie_mes
and   ie_tipo_excepcion   = 3
and   icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725240
	goto ERROR
end	

-- calculo de valor quincenal
update ca_incentivos_calculo_comisiones
set icc_pago_quincenal = round(icc_total_mensual_ajustado / 2,2)
where icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725241
	goto ERROR
end	

commit tran

if exists(select 1 from sysobjects where name ='calculo_comisiones_mensuales')
begin
   DROP TABLE calculo_comisiones_mensuales
end

create table calculo_comisiones_mensuales (
   icc_oficina                 varchar(64),
   icc_cod_funcionario         varchar(64),
   icc_oficial                 varchar(64),
   icc_nombre_oficial          varchar(64),
   icc_indicador_clientes      varchar(64),
   icc_indicador_riesgo        varchar(64),
   icc_indicador_cumplimiento  varchar(64),
   icc_indicador_interes       varchar(64),
   icc_porc_clientes           varchar(64),
   icc_porc_riesgo             varchar(64),
   icc_porc_cumplimiento       varchar(64),
   icc_incen_clientes          varchar(64),
   icc_incen_riesgo            varchar(64),
   icc_incen_cumplimineto      varchar(64),
   icc_total_mensual           varchar(64),
   icc_total_mensual_ajustado  varchar(64),
   icc_pago_quincenal          varchar(64),
   icc_descripcion_ajuste      descripcion
)

insert into calculo_comisiones_mensuales values 
('AGENCIA','COD. EMPLEADO','CARTERA','ASESORES','INDICADORES CLIENTES','INDICADORES RIESGO','INDICADORES CUMPLIMIENTO', 'INDICADORES INTERES',
'PORCENTAJES CLIENTES','PORCENTAJES RIESGO','PORCENTAJES CUMPLIMIENTO','INCENTIVOS CLIENTES','INCENTIVOS RIESGO','INCENTIVOS CUMPLIMIENTO',
'TOTAL','TOTAL MENSUAL AJUSTADO','PAGO QUINCENAL', 'DESCRIPCION DE AJUSTE')

--Exportacion de archivos
insert into calculo_comisiones_mensuales
select  convert(varchar(24),icc_oficina),
        convert(varchar(24),icc_cod_funcionario),
        convert(varchar(24),icc_oficial),
        icc_nombre_oficial,
        convert(varchar(24),icc_indicador_clientes),
        convert(varchar(24),icc_indicador_riesgo),
        convert(varchar(24),icc_indicador_cumplimiento),
        convert(varchar(24),icc_indicador_interes),
        convert(varchar(24),icc_porc_clientes),
        convert(varchar(24),icc_porc_riesgo),
        convert(varchar(24),icc_porc_cumplimiento),
        convert(varchar(24),icc_incen_clientes),
        convert(varchar(24),icc_incen_riesgo),
        convert(varchar(24),icc_incen_cumplimineto),
        convert(varchar(24),icc_total_mensual),
        convert(varchar(24),icc_total_mensual_ajustado),
        convert(varchar(24),icc_pago_quincenal),
        icc_descripcion_ajuste
from ca_incentivos_calculo_comisiones
where icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio

if @@error <> 0 
begin
	select @w_error = 725242
	goto ERROR
end	

select @w_nombre_arch  = @i_param2 + '\incentivos_all_' + convert(VARCHAR(24),@w_fecha_proceso,23)+ '.csv'

exec @w_return          = cobis..sp_bcp_archivos
	@i_sql              = 'cob_cartera..calculo_comisiones_mensuales',   --select o nombre de tabla para generar archivo plano
	@i_tipo_bcp         = 'out',                             --tipo de bcp in,out,queryout
	@i_rut_nom_arch     = @w_nombre_arch,                    --ruta y nombre de archivo
	@i_separador        = ';'                                --separador
	
if @w_return != 0
begin
  select @w_error   = 725243
  GOTO ERROR
end

select @w_num_oficinas      = max(icc_oficina),
       @w_contador_oficina  = min(icc_oficina)
from ca_incentivos_calculo_comisiones

while (@w_contador_oficina < = @w_num_oficinas)
begin
   --Exportacion de archivos
   truncate table calculo_comisiones_mensuales
   
   insert into calculo_comisiones_mensuales values 
   ('AGENCIA','COD. EMPLEADO','CARTERA','ASESORES','INDICADORES CLIENTES','INDICADORES RIESGO','INDICADORES CUMPLIMIENTO', 'INDICADORES INTERES',
   'PORCENTAJES CLIENTES','PORCENTAJES RIESGO','PORCENTAJES CUMPLIMIENTO','INCENTIVOS CLIENTES','INCENTIVOS RIESGO','INCENTIVOS CUMPLIMIENTO',
   'TOTAL','TOTAL MENSUAL AJUSTADO','PAGO QUINCENAL', 'DESCRIPCION DE AJUSTE')
   
   insert into calculo_comisiones_mensuales
   select  convert(varchar(24),icc_oficina),
           convert(varchar(24),icc_cod_funcionario),
           convert(varchar(24),icc_oficial),
           icc_nombre_oficial,
           convert(varchar(24),icc_indicador_clientes),
           convert(varchar(24),icc_indicador_riesgo),
           convert(varchar(24),icc_indicador_cumplimiento),
           convert(varchar(24),icc_indicador_interes),
           convert(varchar(24),icc_porc_clientes),
           convert(varchar(24),icc_porc_riesgo),
           convert(varchar(24),icc_porc_cumplimiento),
           convert(varchar(24),icc_incen_clientes),
           convert(varchar(24),icc_incen_riesgo),
           convert(varchar(24),icc_incen_cumplimineto),
           convert(varchar(24),icc_total_mensual),
           convert(varchar(24),icc_total_mensual_ajustado),
           convert(varchar(24),icc_pago_quincenal),
           icc_descripcion_ajuste
   from ca_incentivos_calculo_comisiones
   where icc_fecha_proceso   = @w_fecha_proceso
   and   icc_mes             = @w_mes
   and   icc_anio            = @w_anio
   and icc_oficina = @w_contador_oficina

   if @@error <> 0 
   begin
   	  select @w_error = 725242
   	  goto ERROR
   end	
   
   --select @w_nombre_arch  is null
   select @w_nombre_arch  = @i_param2 + '\incentivos_'+ convert(varchar(12),@w_contador_oficina)+'_'+ convert(VARCHAR(24),@w_fecha_proceso,23)+ '.csv'
   
   exec @w_return       = cobis..sp_bcp_archivos
   	@i_sql              = 'cob_cartera..calculo_comisiones_mensuales',   --select o nombre de tabla para generar archivo plano
   	@i_tipo_bcp         = 'out',                             --tipo de bcp in,out,queryout
   	@i_rut_nom_arch     = @w_nombre_arch,                    --ruta y nombre de archivo
   	@i_separador        = ';'                                --separador
   	
   if @w_return != 0
   begin
     select @w_error   = 725243
     GOTO ERROR
   end
   
   select @w_contador_oficina  = min(icc_oficina)
   from ca_incentivos_calculo_comisiones
   where icc_oficina > @w_contador_oficina
   
end

--Creacción de tabla de planilla
if exists(select 1 from sysobjects where name ='incentivos_nomina')
begin
   DROP TABLE incentivos_nomina
end

create table incentivos_nomina(
codigo    varchar(24) ,
concepto  varchar(24),
cantidad  varchar(24),
monto     varchar(24),
CC        varchar(24),
planilla  varchar(24)
)

insert into incentivos_nomina values ('CODIGO','COMCEPTO','CANTIDAD','MONTO','CC','PLANILLA')

insert into incentivos_nomina
select  on_nomina, -- convert(varchar(24),icc_cod_planilla),
        '0001-B012',
		'',
        convert(varchar(24),icc_pago_quincenal),
		'',
        '0001'
from ca_incentivos_calculo_comisiones, ca_oficial_nomina
where icc_fecha_proceso   = @w_fecha_proceso
and   icc_mes             = @w_mes
and   icc_anio            = @w_anio
and   icc_oficial         = on_oficial
and   on_estado           = 'A'        -- Activo (I: Inactivo)

if @@error <> 0 
begin
	select @w_error = 725242
	goto ERROR
end	

select @w_nombre_arch  = null
select @w_nombre_arch  = @i_param2 + '\incentivos_rrhh_' + convert(VARCHAR(24),@w_fecha_proceso,23)+ '.txt'

exec @w_return          = cobis..sp_bcp_archivos
	@i_sql              = 'cob_cartera..incentivos_nomina',   --select o nombre de tabla para generar archivo plano
	@i_tipo_bcp         = 'out',                             --tipo de bcp in,out,queryout
	@i_rut_nom_arch     = @w_nombre_arch,                    --ruta y nombre de archivo
	@i_separador        = ';'                                --separador
	
if @w_return != 0
begin
  select @w_error   = 725243
  GOTO ERROR
end

drop table calculo_comisiones_mensuales
drop table incentivos_nomina

return 0

ERROR:      
while @@trancount > 0 ROLLBACK TRAN
exec cobis..sp_cerror
@t_debug   = 'N',
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error 

go
