/************************************************************************/
/*   Archivo:             repo_tasas.sp                                 */
/*   Stored procedure:    sp_repo_tasas                                 */
/*   Base de datos:       cob_credito                                   */
/*   Producto:            Cartera                                       */
/*   Disenado por:        Oscar Saavedra                                */
/*   Fecha de escritura:  17 de Diciembre de 2013                       */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   "MACOSA". Su uso no autorizado queda expresamente prohibido asi    */
/*   como cualquier alteracion o agregado hecho por alguno de sus       */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                             PROPOSITO                                */
/*   Generacion reportes Seguimiento de Tasas                           */
/************************************************************************/
/*                              CAMBIOS                                 */
/*   FECHA              AUTOR             CAMBIOS                       */
/*   17/Dic/2013        Oscar Saavedra    Emision Inicial ORS 000727    */
/************************************************************************/

use cob_cartera
go

SET NOCOUNT ON
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

if exists (select 1 from sysobjects where name = 'sp_repo_tasas')
   drop proc sp_repo_tasas
go
---INC 115011 MAR.14.2014
create proc sp_repo_tasas(
@i_param1         datetime, --Fecha de Inicio
@i_param2         datetime  --Fecha de Fin
)
as
declare 
@i_fecha          datetime,
@w_fecha_ini      datetime,
@w_msg            varchar(254),
@w_path_s_app     varchar(254),
@w_path           varchar(254),
@w_s_app          varchar(254),
@w_cmd            varchar(254),
@w_bd             varchar(254),
@w_tabla          varchar(254),
@w_tablac         varchar(254),
@w_tablad         varchar(254),
@w_destino        varchar(254),
@w_errores        varchar(254),
@w_erroresc       varchar(254),
@w_destinoc       varchar(254),
@w_comando        varchar(512),
@w_fecha_arch     varchar(10),
@w_nombre         varchar(64),
@w_archivo        varchar(64),
@w_archivoc       varchar(64),
@w_archivod       varchar(64),
@w_arch_out       varchar(64),
@w_batch          int,
@w_error          int,
@w_cont           int,
@anio_listado     varchar(10),
@mes_listado      varchar(10),
@dia_listado      varchar(10)

select @i_fecha = fp_fecha from cobis..ba_fecha_proceso

if exists (select 1 from sysobjects where name = 'cr_reporte_tasas_cab')
    drop table cr_reporte_tasas_cab

create table cr_reporte_tasas_cab(
rtc_credito                     varchar(30),
rtc_oficina                     varchar(30),
rtc_vr_credito                  varchar(30),
rtc_tasa_credito                varchar(30),
rtc_tipo_seguro                 varchar(30),
rtc_desc_seg1                   varchar(30),
rtc_monto_seg1                  varchar(30),
rtc_tasa_seg1                   varchar(30),
rtc_desc_seg2                   varchar(30),
rtc_monto_seg2                  varchar(30),
rtc_tasa_seg2                   varchar(30),
rtc_desc_seg3                   varchar(30),
rtc_monto_seg3                  varchar(30),
rtc_tasa_seg3                   varchar(30),
rtc_desc_seg4                   varchar(30),
rtc_monto_seg4                  varchar(30),
rtc_tasa_seg4                   varchar(30))

insert into cr_reporte_tasas_cab
values(
'NR_CREDITO',        'OFICINA',           'VALOR CREDITO',  'TASA CREDITO',      'TIPO SEGURO1', 
'DESCRIPCION SEG1',  'MONTO SEG1',        'TASA SEG1',      'DESCRIPCION SEG2',  'MONTO SEG2',
'TASA SEG2',         'DESCRIPCION SEG3',  'MONTO SEG3',     'TASA SEG3',         'DESCRIPCION SEG4',
'MONTO SEG4',        'TASA SEG4')

if exists (select 1 from sysobjects where name = 'cr_reporte_tasas_det')
    drop table cr_reporte_tasas_det

select C.codigo, C.valor
into   #catalogo
from   cobis..cl_catalogo C, cobis..cl_tabla T   
where  T.tabla  = 'cr_cli_pref_campana'
and    T.codigo = C.tabla

select
NR_CREDITO        = op_banco, 
OFICINA           = op_oficina, 
VALOR_CREDITO     = op_monto, 
TASA_CREDITO      = (select ro_porcentaje_aux from cob_cartera..ca_rubro_op where ro_concepto in ('INT') and ro_operacion = op_operacion) ,
TIPO_SEGURO1      = sed_tipo_seguro, 
DESCRIPCION_SEG1 = (select substring(se_descripcion, 1, 20)  from cob_credito..cr_tipo_seguro where se_tipo_seguro = sed_tipo_seguro),
MONTO_SEG1       = sum(sed_cuota_cap),
TASA_SEG1        = (select ro_porcentaje from cob_cartera..ca_rubro_op where ro_concepto in ('SEGVIDIND') and ro_operacion = op_operacion),
DESCRIPCION_SEG_2 = convert(varchar(255),''),
MONTO_SEG_2       = convert(money,0),
TASA_SEG_2        = convert(float, 0.00),
DESCRIPCION_SEG_3 = convert(varchar(255),''),
MONTO_SEG_3       = convert(money, 0),
TASA_SEG_3        = convert(float, 0.00),
DESCRIPCION_SEG_4 = convert(varchar(255),''),
MONTO_SEG_4       = convert(money, 0),
TASA_SEG_4        = convert(float, 0.00)
into #plan
from cob_cartera..ca_operacion       with(nolock),
     cob_cartera..ca_seguros_det     with(nolock),
     cob_cartera..ca_seguros         with(nolock),
     cob_credito..cr_seguros_tramite with (nolock)
where op_fecha_liq        >= @i_param1
and   op_fecha_liq        <= @i_param2
and   se_tramite           = op_tramite
and   op_estado            = 1
and   se_operacion         = op_operacion
and   se_tramite          = st_tramite
and   st_secuencial_seguro = se_sec_seguro 
and   st_secuencial_seguro = sed_sec_seguro 
and   st_tipo_seguro       = 1
and   se_operacion         = sed_operacion
and   sed_sec_seguro       = se_sec_seguro 
and   sed_tipo_seguro      = 1
and   se_tipo_seguro       = sed_tipo_seguro
group by  op_banco, sed_tipo_seguro, op_oficina, op_monto,op_operacion
order by  op_banco, op_oficina

select
NR_CREDITO2       = op_banco, 
OFICINA           = op_oficina, 
VALOR_CREDITO     = op_monto, 
TASA_CREDITO      = (select ro_porcentaje_aux from cob_cartera..ca_rubro_op where ro_concepto in ('INT') and ro_operacion = op_operacion) ,
TIPO_SEGURO1      = sed_tipo_seguro, 
DESCRIPCION_SEG1 = '',
MONTO_SEG1       = convert(money, 0),
TASA_SEG1        = convert(float, 0.00),
DESCRIPCION_SEG_2 = convert(varchar(255),(select substring(se_descripcion, 1, 20)  from cob_credito..cr_tipo_seguro where se_tipo_seguro = sed_tipo_seguro)),
MONTO_SEG_2       =  convert(money,sum(sed_cuota_cap),0),
TASA_SEG_2        = convert(float,(select ro_porcentaje from cob_cartera..ca_rubro_op where ro_concepto in ('SEGVIDPRI') and ro_operacion = op_operacion)),
DESCRIPCION_SEG_3 = '',
MONTO_SEG_3       = convert(money, 0),
TASA_SEG_3        = convert(float, 0.00),
DESCRIPCION_SEG_4 = '',
MONTO_SEG_4       = convert(money, 0),
TASA_SEG_4        = convert(float, 0.00)
into #plan2
from cob_cartera..ca_operacion       with(nolock),
     cob_cartera..ca_seguros_det     with(nolock),
     cob_cartera..ca_seguros         with(nolock),
     cob_credito..cr_seguros_tramite with (nolock)
where op_fecha_liq        >= @i_param1
and   op_fecha_liq        <= @i_param2
and   se_tramite           = op_tramite
and   op_estado            = 1
and   se_operacion         = op_operacion
and   se_tramite          = st_tramite
and   st_secuencial_seguro = se_sec_seguro 
and   st_secuencial_seguro = sed_sec_seguro 
and   st_tipo_seguro       = 2
and   se_operacion         = sed_operacion
and   sed_sec_seguro       = se_sec_seguro 
and   sed_tipo_seguro      = 2
and   se_tipo_seguro       = sed_tipo_seguro
group by  op_banco, sed_tipo_seguro, op_oficina, op_monto,op_operacion
order by  op_banco, op_oficina


update #plan set
#plan.DESCRIPCION_SEG_2 = #plan2.DESCRIPCION_SEG_2,
#plan.MONTO_SEG_2       = #plan2.MONTO_SEG_2,
#plan.TASA_SEG_2        = #plan2.TASA_SEG_2
from   #plan2 
where  #plan.NR_CREDITO    = #plan2.NR_CREDITO2

insert into #plan 
select * from #plan2
where NR_CREDITO2 not in ( select #plan2.NR_CREDITO2 from   #plan,#plan2 where  #plan.NR_CREDITO    = #plan2.NR_CREDITO2)

select
NR_CREDITO3       = op_banco, 
OFICINA           = op_oficina, 
VALOR_CREDITO     = op_monto, 
TASA_CREDITO      = (select ro_porcentaje_aux from cob_cartera..ca_rubro_op where ro_concepto in ('INT') and ro_operacion = op_operacion) ,
TIPO_SEGURO1      = sed_tipo_seguro, 
DESCRIPCION_SEG1 = convert(varchar(255), ''),
MONTO_SEG1       = convert(money, 0),
TASA_SEG1        = convert(float, 0.00),
DESCRIPCION_SEG_2 = convert(varchar(255), ''),
MONTO_SEG_2       = convert(money, 0),
TASA_SEG_2        = convert(float, 0.00),
DESCRIPCION_SEG_3 = convert(varchar(20),(select substring(se_descripcion, 1, 20)  from cob_credito..cr_tipo_seguro where se_tipo_seguro = sed_tipo_seguro)),
MONTO_SEG_3       = convert(money,sum(sed_cuota_cap)),
TASA_SEG_3        = convert(float,(select ro_porcentaje from cob_cartera..ca_rubro_op where ro_concepto in ('SEGEXEQ') and ro_operacion = op_operacion)),
DESCRIPCION_SEG_4 = convert(varchar(255), ''),
MONTO_SEG_4       = convert(money, 0),
TASA_SEG_4        = convert(float, 0.00)
into #plan3
from cob_cartera..ca_operacion       with(nolock),
     cob_cartera..ca_seguros_det     with(nolock),
     cob_cartera..ca_seguros         with(nolock),
     cob_credito..cr_seguros_tramite with (nolock)
where op_fecha_liq        >= @i_param1
and   op_fecha_liq        <= @i_param2
and   se_tramite           = op_tramite
and   op_estado            = 1
and   se_operacion         = op_operacion
and   se_tramite          = st_tramite
and   st_secuencial_seguro = se_sec_seguro 
and   st_secuencial_seguro = sed_sec_seguro 
and   st_tipo_seguro       = 3
and   se_operacion         = sed_operacion
and   sed_sec_seguro       = se_sec_seguro 
and   sed_tipo_seguro      = 3
and   se_tipo_seguro       = sed_tipo_seguro
group by  op_banco, sed_tipo_seguro, op_oficina, op_monto,op_operacion
order by  op_banco, op_oficina

update #plan set
#plan.DESCRIPCION_SEG_3    = #plan3.DESCRIPCION_SEG_3,
#plan.MONTO_SEG_3          = #plan3.MONTO_SEG_3,
#plan.TASA_SEG_3           = #plan3.TASA_SEG_3
from   #plan3 
where  #plan.NR_CREDITO    = #plan3.NR_CREDITO3

insert into #plan 
select * from #plan3
where NR_CREDITO3 not in ( select #plan3.NR_CREDITO3 from   #plan,#plan3 where  #plan.NR_CREDITO    = #plan3.NR_CREDITO3)

select
NR_CREDITO4       = op_banco, 
OFICINA           = op_oficina, 
VALOR_CREDITO     = op_monto, 
TASA_CREDITO      = (select ro_porcentaje_aux from cob_cartera..ca_rubro_op where ro_concepto in ('INT') and ro_operacion = op_operacion) ,
TIPO_SEGURO1      = sed_tipo_seguro, 
DESCRIPCION_SEG1 = convert(varchar(255), ''),
MONTO_SEG1       = convert(money, 0),
TASA_SEG1        = convert(float, 0.00),
DESCRIPCION_SEG_2 = convert(varchar(255), ''),
MONTO_SEG_2       = convert(money, 0),
TASA_SEG_2        = convert(float, 0.00),
DESCRIPCION_SEG_3 = convert(varchar(255), ''),
MONTO_SEG_3       = convert(money, 0),
TASA_SEG_3        = convert(float, 0.00),
DESCRIPCION_SEG_4 = convert(varchar(20),(select substring(se_descripcion, 1, 20)  from cob_credito..cr_tipo_seguro where se_tipo_seguro = sed_tipo_seguro)),
MONTO_SEG_4       = convert(money,sum(sed_cuota_cap)),
TASA_SEG_4        = convert(float,(select ro_porcentaje from cob_cartera..ca_rubro_op where ro_concepto in ('SEGDAMAT') and ro_operacion = op_operacion))
into #plan4
from cob_cartera..ca_operacion       with(nolock),
     cob_cartera..ca_seguros_det     with(nolock),
     cob_cartera..ca_seguros         with(nolock),
     cob_credito..cr_seguros_tramite with (nolock)
where op_fecha_liq        >= @i_param1
and   op_fecha_liq        <= @i_param2
and   se_tramite           = op_tramite
and   op_estado            = 1
and   se_operacion         = op_operacion
and   se_tramite          = st_tramite
and   st_secuencial_seguro = se_sec_seguro 
and   st_secuencial_seguro = sed_sec_seguro 
and   st_tipo_seguro       = 4
and   se_operacion         = sed_operacion
and   sed_sec_seguro       = se_sec_seguro 
and   sed_tipo_seguro      = 4
and   se_tipo_seguro       = sed_tipo_seguro
group by  op_banco, sed_tipo_seguro, op_oficina, op_monto,op_operacion
order by  op_banco, op_oficina

update #plan set
#plan.DESCRIPCION_SEG_4 = #plan4.DESCRIPCION_SEG_4,
#plan.MONTO_SEG_4       = #plan4.MONTO_SEG_4,
#plan.TASA_SEG_4        = #plan4.TASA_SEG_4
from   #plan4 
where  #plan.NR_CREDITO    = #plan4.NR_CREDITO4

insert into #plan 
select * from #plan4
where NR_CREDITO4 not in ( select #plan4.NR_CREDITO4 from   #plan,#plan4 where  #plan.NR_CREDITO    = #plan4.NR_CREDITO4)

select *
into cr_reporte_tasas_det
from #plan

select
@w_cont      = 0,
@w_bd        = 'cob_cartera',
@w_tablac    = 'cr_reporte_tasas_cab',
@w_tablad    = 'cr_reporte_tasas_det',
@w_arch_out  = 'cr_reporte_tasas_',
@w_batch     = 7987
goto BCP

BCP:

/*Creacion BCP*/
select @w_path_s_app = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'S_APP'

if @w_path_s_app is null begin
   select @w_msg = 'NO EXISTE PARAMETRO GENERAL S_APP'
   goto ERROR
end

select
@w_s_app = @w_path_s_app + 's_app'

/*Path destino archivo BCP*/
select
@w_path = ba_path_destino
from  cobis..ba_batch
where ba_batch = @w_batch

/*Generacion archivo cabecera*/
select 
@w_cmd       = @w_s_app + ' bcp -auto -login ',
@w_tabla     = @w_tablac,
@w_archivoc  = @w_tablac

select 
@w_destinoc  = @w_path + @w_archivoc +'.txt',
@w_erroresc  = @w_path + @w_archivoc +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tablac + ' out ' + @w_destinoc + ' -b5000 -c -e' + @w_erroresc + ' -t"|" ' + '-config ' + @w_s_app + '.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO CABECERA ' + @w_destinoc + ' ' + convert(varchar, @w_error)
   goto ERROR
end

/*Generacion archivo datos*/
select
@w_cmd      = @w_s_app + ' bcp -auto -login ',
@w_tabla    = @w_tablad,
@w_archivod = @w_tablad

select 
@w_destino  = @w_path + @w_archivod +'.txt',
@w_errores  = @w_path + @w_archivod +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tablad + ' out ' + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config ' + @w_s_app + '.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO ' + @w_destino + ' ' + convert(varchar, @w_error)
   goto ERROR
end

select @w_fecha_arch = convert(varchar, @i_fecha, 112),
       @anio_listado = substring(@w_fecha_arch,1,4),
       @mes_listado  = substring(@w_fecha_arch,5,2), 
       @dia_listado  = substring(@w_fecha_arch,7,2)

select @w_fecha_arch = @mes_listado + @dia_listado + @anio_listado 

/*Fusion archivos de cabecera y de datos*/
select @w_nombre = @w_arch_out + @w_fecha_arch

select
@w_archivo  = @w_path + @w_nombre +'.txt',
@w_comando = 'type ' + @w_destinoc + ' ' + @w_destino + ' > ' + @w_archivo

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL ' + @w_archivo + ' ' + convert(varchar, @w_error)
   goto ERROR
end

/*Eliminacion Archivo de cabecera y de datos*/
select
@w_comando = 'rm ' + @w_destinoc 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL ' + @w_archivo + ' '+ convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_erroresc 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL ' + @w_archivo + ' ' + convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_destino 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL ' + @w_archivo+ ' ' + convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_errores 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end
 
return 0

ERROR:
print @w_msg 

exec @w_error = cobis..sp_errorlog
@i_fecha      = @i_fecha,
@i_error      = 22681,
@i_usuario    = 'op_batch',
@i_tran       = 7946,
@i_tran_name  = @w_msg,
@i_rollback   = 'N'
return 22681