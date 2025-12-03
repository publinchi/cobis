/*************************************************************************/
/*   Archivo:              sp_rep_errores_logs.sp                        */
/*   Stored procedure:     sp_rep_errores_logs                           */
/*   Base de datos:        cob_cartera                                   */
/*   Producto:             Cartera                                       */
/*   Disenado por:         ACHP                                          */
/*   Fecha de escritura:   Enero 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'COBIS'.                                                            */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de COBIS o su representante legal.            */
/*************************************************************************/
/*                                   PROPOSITO                           */
/*   Obtiene informacion de la tabla cobis..ba_log entre la fecha actual */
/*   y el día habil anterior                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                 AUTOR                 RAZON                  */
/*    10/Ene/19             ACHP             emision inicial             */
/*                                                                       */
/*************************************************************************/
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_rep_errores_logs')
    drop proc sp_rep_errores_logs
go

create proc sp_rep_errores_logs
(
	@i_param1  datetime
)
AS

DECLARE
@w_sp_name          varchar(64),
@w_msg              varchar(255),
@w_ciudad_nacional  smallint,
@w_sep              char(1)

DECLARE
@w_return            int,
@w_file_rpt          varchar(100),
@w_file_rpt_1        varchar(140),
@w_file_rpt_1_out    varchar(140),
@w_bcp               varchar(2000),
@w_path_destino      varchar(200),
@w_s_app             varchar(40),
@w_fecha_r           varchar(10),
@w_mes               varchar(2),
@w_dia               varchar(2),
@w_anio              varchar(4),
@w_fecha_desde       datetime,
@w_fecha_hasta       datetime


SELECT @w_sp_name  = 'sp_rep_errores_logs',
       @w_fecha_hasta    = @i_param1

select @w_ciudad_nacional = pa_int
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CIUN'
and    pa_producto = 'ADM'

select @w_ciudad_nacional = isnull(@w_ciudad_nacional,9999)
	
select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

select @w_path_destino = pp_path_destino
from   cobis..ba_path_pro
where  pp_producto = 8 -- FUENTE: C:\Cobis\vbatch\objetos\	DESTINO: C:\Cobis\vbatch\listados\

select @w_file_rpt = 'REPORTE_LOGS'

select @w_mes         = substring(convert(varchar,@w_fecha_hasta, 101),1,2)
select @w_dia         = substring(convert(varchar,@w_fecha_hasta, 101),4,2)
select @w_anio        = substring(convert(varchar,@w_fecha_hasta, 101),7,4)

select @w_fecha_r = @w_dia + '_' + @w_mes + '_' + @w_anio

--RUTA
select @w_file_rpt_1     = @w_path_destino + @w_file_rpt + '_' + @w_fecha_r + '.txt'
select @w_file_rpt_1_out = @w_path_destino + @w_file_rpt + '_' + @w_fecha_r + '.err'

--FECHA 
select @w_fecha_desde = dateadd(dd, -1, @w_fecha_hasta)   
while exists(SELECT 1 FROM cobis..cl_dias_feriados where df_ciudad = @w_ciudad_nacional and df_fecha = @w_fecha_desde)
begin
   select @w_fecha_desde = dateadd(dd, -1, @w_fecha_desde)   
end

print '---@w_fecha_desde:'+convert(varchar,@w_fecha_desde)
print '---@w_fecha_hasta:'+convert(varchar,@w_fecha_hasta)
TRUNCATE TABLE ca_error_log_rep_tmp
----------------------------------------
-------- DATOS PARA REPORTE LOG
----------------------------------------
INSERT INTO ca_error_log_rep_tmp ( rtbl_campo1,  rtbl_campo2,  rtbl_campo3,  rtbl_campo4,     rtbl_campo5,  rtbl_campo6,  rtbl_campo7,    rtbl_campo8,
                                 rtbl_campo9,  rtbl_campo10, rtbl_campo11, rtbl_campo12,    rtbl_campo13, rtbl_campo14, rtbl_campo15 )
SELECT                          'ba_log',      'SARTA',      'BATCH',      'SECUENCIAL',    'CORRIDA',    'OPERADOR',   'FECHA_INICIO', 'FECHA_TERMINACION', 
                                'NUM_REG_PRO', 'ESTATUS',    'RAZON',      'FECHA_PROCESO', 'PROCESO',    'PARAMETRO',  'INTENTO'
INSERT INTO ca_error_log_rep_tmp ( rtbl_campo1,  rtbl_campo2,  rtbl_campo3,  rtbl_campo4,     rtbl_campo5,  rtbl_campo6,  rtbl_campo7,    rtbl_campo8,
                                 rtbl_campo9,  rtbl_campo10, rtbl_campo11, rtbl_campo12,    rtbl_campo13, rtbl_campo14, rtbl_campo15 )
select 'ba_log',
       convert(varchar(255),isnull(lo_sarta,'')),
	   convert(varchar(255),isnull(lo_batch,'')),
	   convert(varchar(255),isnull(lo_secuencial,'')),
	   convert(varchar(255),isnull(lo_corrida,'')),
	   convert(varchar(255),isnull(lo_operador,'')),
	   convert(varchar(255),isnull(lo_fecha_inicio,'')),
	   convert(varchar(255),isnull(lo_fecha_terminacion,'')),
	   convert(varchar(255),isnull(lo_num_reg_proc,'')),
	   convert(varchar(255),isnull(lo_estatus,'')),
	   convert(varchar(255),isnull(lo_razon,'')),
	   convert(varchar(255),isnull(lo_fecha_proceso,'')),
	   convert(varchar(255),isnull(lo_proceso,'')),
	   convert(varchar(255),isnull(lo_parametro,'')),
	   convert(varchar(255),isnull(lo_intento,''))
from   cobis..ba_log
where  lo_estatus <> 'F'
and    lo_fecha_proceso between @w_fecha_desde and @w_fecha_hasta

----------------------------------------
-------- DATOS PARA REPORTE CB_BOC
----------------------------------------
INSERT INTO ca_error_log_rep_tmp ( rtbl_campo1, rtbl_campo2,  rtbl_campo3,  rtbl_campo4,  rtbl_campo5,  rtbl_campo6,  rtbl_campo7, rtbl_campo8,  rtbl_campo9)
SELECT                           'cb_boc',    'FECHA',      'CUENTA',     'OFICINA',    'CLIENTE',    'VAL_OPERA',  'VAL_CONTA', 'DIFERENCIA', 'PRODUCTO'

-- AGI COMENTADO PORQUE NO EXISTE EL CAMPO bo_cliente, bo_val_opera, bo_val_conta Y bo_diferencia EN LA TABLA cob_conta..cb_boc
/*
INSERT INTO ca_error_log_rep_tmp ( rtbl_campo1, rtbl_campo2,  rtbl_campo3,  rtbl_campo4,  rtbl_campo5,  rtbl_campo6,  rtbl_campo7, rtbl_campo8,  rtbl_campo9)
select 'cb_boc',
       convert(varchar(255),isnull(bo_fecha,'')),
       convert(varchar(255),isnull(bo_cuenta,'')),
	   convert(varchar(255),isnull(bo_oficina,'')),
	   convert(varchar(255),isnull(bo_cliente,'')),
	   convert(varchar(255),isnull(bo_val_opera,'')),
	   convert(varchar(255),isnull(bo_val_conta,'')),
	   convert(varchar(255),isnull(bo_diferencia,'')),
	   convert(varchar(255),isnull(bo_producto,''))
from  cob_conta..cb_boc
where bo_diferencia <> 0
and   bo_fecha between @w_fecha_desde and @w_fecha_hasta
*/--FIN AGI
----------------------------------------
-------- DATOS PARA REPORTE BA_ERROR_BATCH
----------------------------------------
INSERT INTO ca_error_log_rep_tmp ( rtbl_campo1,      rtbl_campo2,       rtbl_campo3,     rtbl_campo4, rtbl_campo5,   rtbl_campo6,  rtbl_campo7,    
                                 rtbl_campo8,      rtbl_campo9,       rtbl_campo10,    rtbl_campo11, rtbl_campo12, rtbl_campo13)
SELECT                           'ba_error_batch', 'SECUENCIA_ERROR', 'FECHA_PROCESO', 'SARTA',     'BATCH',       'SECUENCIAL', 'CORRIDA', 
                                 'INTENTO',        'FECHA_ERROR',     'ERROR',         'TRAN',      'OPERACION',   'DETALLE'

INSERT INTO ca_error_log_rep_tmp ( rtbl_campo1,      rtbl_campo2,       rtbl_campo3,     rtbl_campo4, rtbl_campo5,   rtbl_campo6,  rtbl_campo7,    
                                 rtbl_campo8,      rtbl_campo9,       rtbl_campo10,    rtbl_campo11, rtbl_campo12, rtbl_campo13)
select 'ba_error_batch',
       convert(varchar(255),isnull(er_secuencial_error,'')),
       convert(varchar(255),isnull(er_fecha_proceso,'')),
       convert(varchar(255),isnull(er_sarta,'')),
       convert(varchar(255),isnull(er_batch,'')),
       convert(varchar(255),isnull(er_secuencial,'')),
       convert(varchar(255),isnull(er_corrida,'')),
       convert(varchar(255),isnull(er_intento,'')),
       convert(varchar(255),isnull(er_fecha_error,'')),
       convert(varchar(255),isnull(er_error,'')),
       convert(varchar(255),isnull(er_tran,'')),
       convert(varchar(255),isnull(er_operacion,'')),
       convert(varchar(255),isnull(replace(replace(rtrim(ltrim(er_detalle)), char(13),''), char(10),'') ,''))
from   cobis..ba_error_batch
where  er_fecha_proceso between @w_fecha_desde and @w_fecha_hasta

----------------------------------------
-------- DATOS PARA REPORTE CB_ERRORES
----------------------------------------
INSERT INTO ca_error_log_rep_tmp ( rtbl_campo1,  rtbl_campo2,     rtbl_campo3,   rtbl_campo4, rtbl_campo5,  rtbl_campo6)
SELECT                           'cb_errores', 'PROCEDIMIENTO', 'DETALLE_ERR', 'CAMPO_ERR', 'CAMPO_DATO', 'FECHA_ERR'

INSERT INTO ca_error_log_rep_tmp ( rtbl_campo1,  rtbl_campo2,     rtbl_campo3,   rtbl_campo4, rtbl_campo5,  rtbl_campo6)								 
select 'cb_errores',
       convert(varchar(255),isnull(cbe_procedimiento,'')),
	   convert(varchar(255),isnull(cbe_detalle_err,'')),
	   convert(varchar(255),isnull(cbe_campo_err,'')),
	   convert(varchar(255),isnull(cbe_campo_dato,'')),
	   convert(varchar(255),isnull(cbe_fecha_err,''))
from   cob_conta..cb_errores
where  cbe_fecha_err between @w_fecha_desde and @w_fecha_hasta

SELECT @w_bcp = @w_s_app + 's_app bcp -auto -login ' + 'cob_cartera..ca_error_log_rep_tmp' + ' out ' + @w_file_rpt_1 + ' -c -t\t -b 5000 -e' + @w_file_rpt_1_out + ' -config ' + @w_s_app + 's_app.ini'
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

exec @w_return       = cob_conta_super..sp_errorlog
     @i_operacion    = 'I',
     @i_fecha_fin    = @i_param1,
     @i_origen_error = @w_return,
     @i_fuente       = @w_sp_name,
     @i_descrp_error = @w_msg

return @w_return

GO
