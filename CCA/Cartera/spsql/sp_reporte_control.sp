use cob_cartera
go
/*************************************************************************/
/*   ARCHIVO:         sp_reporte_control.sp                              */
/*   NOMBRE LOGICO:   sp_reporte_control                                 */
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
/*************************************************************************/

if exists(select 1 from sysobjects where name = 'sp_reporte_control')
    drop proc sp_reporte_control
go
create proc sp_reporte_control (
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
  @w_primer_dia     varchar(10),
  @w_ultimo_dia     varchar(10),
  @w_cabecera       varchar(30),
  @w_op_vigentes    int,
  @w_transacciones  int,
  @w_procesos       int,
  @w_usuarios_app   int   

select @w_sp_name = 'sp_reporte_control'

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

truncate table ca_reporte_control_tmp

select @w_path = pp_path_destino
from cobis..ba_path_pro
where pp_producto = 7 -- CARTERA

select @w_mes         = substring(convert(varchar,@i_param1, 101),1,2)
select @w_dia         = substring(convert(varchar,@i_param1, 101),4,2)
select @w_anio        = substring(convert(varchar,@i_param1, 101),7,4)

select @w_fecha_r = @w_anio + @w_mes + @w_dia

select @w_file_rpt = 'REPORTE_MENSUAL_CONTROL'
select @w_file_rpt_1     = @w_path + @w_file_rpt + '_' + @w_fecha_r + '.txt'
select @w_file_rpt_1_out = @w_path + @w_file_rpt + '_' + @w_fecha_r + '.err'

set @w_cabecera = 'REPORTE MENSUAL DE CONTROL'

insert into ca_reporte_control_tmp
select @w_cabecera,
       ' '

/* Número de Operaciones Vigentes al corte */
SELECT @w_op_vigentes = count(*) FROM cob_conta_super..sb_dato_operacion
WHERE do_estado_cartera NOT IN (3,0,99)
AND do_fecha = @i_param1--@w_fecha_proceso

insert into ca_reporte_control_tmp
select 'Número de Operaciones Vigentes al corte: ',
	   @w_op_vigentes


SELECT @w_primer_dia = convert(VARCHAR(10), DATEADD(month, DATEDIFF(month, 0, @i_param1), 0), 101)
SELECT @w_ultimo_dia = convert(VARCHAR(10), DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@i_param1)+1,0)), 101)

/* Número de Transacciones del mes */
SELECT @w_transacciones = count(*) FROM cob_cartera..ca_transaccion
WHERE tr_fecha_mov >= @w_primer_dia --'08/01/2017' --'01/mes/año'-- primer día del mes de la fecha de proceso
AND tr_fecha_mov <= @w_ultimo_dia --'08/30/2017'--'31/mes/año' --ultimo día del mes de la fecha de proceso

insert into ca_reporte_control_tmp
select 'Número de Transacciones (de CARTERA) del mes: ',
	   @w_transacciones

/* Número de Procesos del mes */
SELECT @w_procesos = count(*) FROM cob_workflow..wf_inst_proceso
WHERE io_fecha_crea >= @w_primer_dia --'08/01/2017'--'01/mes/año'-- primer día del mes de la fecha de proceso
AND io_fecha_crea <= @w_ultimo_dia --'08/30/2017'--'31/mes/año' --ultimo día del mes de la fecha de proceso

insert into ca_reporte_control_tmp
select 'Número de Procesos del mes: ',
	   @w_procesos

/* Número de usuarios conectados al APP Móvil */
select @w_usuarios_app = count(distinct lo_login) from cobis..cts_session, cobis..in_login
where cts_sesn = lo_sesion
and cts_oficina = 9001 --9001 es la oficina del celular
and lo_fecha_in >= @w_primer_dia --'12/01/2017'--'01/mes/año'-- primer día del mes de la fecha de proceso
and lo_fecha_in  <= @w_ultimo_dia --'12/31/2017'--'31/mes/año' --ultimo día del mes de la fecha de proceso
and lo_login = cts_usuario

insert into ca_reporte_control_tmp
select 'Número de usuarios conectados al APP Móvil: ',
	   @w_usuarios_app



SELECT @w_bcp = @w_s_app + 's_app bcp -auto -login ' + 'cob_cartera..ca_reporte_control_tmp' + ' out ' + @w_file_rpt_1 + ' -c -C ACP -t"" -b 5000 -e' + @w_file_rpt_1_out + ' -config ' + @w_s_app + 's_app.ini'
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
     @i_fecha_fin     = @i_param1,
     @i_fuente        = @w_sp_name,
     @i_origen_error  = 70146,
     @i_descrp_error  = @w_msg

go
