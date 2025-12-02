/************************************************************************/
/*   Archivo:            venta_universo_log.sp                          */
/*   Stored procedure:   sp_venta_universo_log                          */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Fecha de escritura: Nov. 2013                                      */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                          PROPOSITO                                   */
/*                                                                      */
/*      Migra Informacion VENTA CARTERA CASTIGADA                       */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR         RAZON                              */
/*  Diciembre-16-2013   Luis Guzman  Emision Inicial                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_venta_universo_log')
   drop proc sp_venta_universo_log
go

create proc sp_venta_universo_log

as
declare
@w_fecha_proceso  datetime,
@w_error          int,
--parametros para bcp
@w_s_app          varchar(50),
@w_path           varchar(60),
@w_cmd            varchar(255),
@w_destino        varchar(255),
@w_mensaje        varchar(255),
@w_comando        varchar(5000),
@w_errores        varchar(1500),
@w_path_destino   varchar(255),
@w_anio			  varchar(4),
@w_mes			  varchar(2),
@w_dia			  varchar(2),
@w_fecha1		  varchar(50),
@w_msg			  descripcion,
@w_nombre		  varchar(255),
@w_columna		  varchar(100),
@w_nom_tabla	  varchar(100),
@w_col_id		  int,
@w_cabecera		  varchar(5000),
@w_nombre_cab	  varchar(255),
@w_nombre_plano	  varchar(2500),
@w_sp_name        varchar(50),
@w_fecha_venta    datetime

select @w_sp_name = 'sp_venta_universo_log'

-- SELECCIONA LA FECHA DE PROCESO
select @w_fecha_proceso = fp_fecha
from   cobis..ba_fecha_proceso

-----------------------------------------------------------------------
--GENERANDO BCP
-----------------------------------------------------------------------

select @w_s_app = pa_char
from   cobis..cl_parametro
where  pa_producto = 'ADM'
and    pa_nemonico = 'S_APP'

/***Generación de los listado ***/
select @w_path = pp_path_destino 
from   cobis..ba_path_pro
where  pp_producto = 7
	
select @w_anio    = convert(varchar(4),datepart(yyyy,@w_fecha_proceso)),
       @w_mes     = convert(varchar(2),datepart(mm,@w_fecha_proceso)), 
       @w_dia     = convert(varchar(2),datepart(dd,@w_fecha_proceso))

select @w_fecha1 = (right('00' + @w_mes,2) + right('00'+ @w_dia,2) +  @w_anio)

if @@rowcount = 0
begin
   select 
   @w_error = 2902797, 
   @w_mensaje   = 'Fecha de Proceso Incorrecta'
   goto ERROR
end			

if exists (select 1 from sysobjects where name = 'ca_venta_universo_log')
   drop table ca_venta_universo_log

select @w_fecha_venta = max(Fecha_Venta)
from cob_cartera..ca_venta_universo

-- CA_VENTA_UNIVERSO_LOG
select * into ca_venta_universo_log from ca_venta_universo
where Estado_Venta = 'P'
and   Fecha_Venta  = @w_fecha_venta

----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select 
@w_nombre       = 'ca_venta_log',
@w_nom_tabla    = 'ca_venta_universo_log',
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = convert(varchar(1000), ''),
@w_nombre_cab   = @w_nombre

select @w_nombre_plano = @w_path + @w_nombre_cab + '_' + @w_fecha1 + '.txt'				

while 1 = 1 
begin
   set rowcount 1
   select 
   @w_columna = c.name,
   @w_col_id  = c.colid
   from cob_cartera..sysobjects o, cob_cartera..syscolumns c
   where o.id    = c.id
   and   o.name  = @w_nom_tabla
   and   c.colid > @w_col_id
   order by c.colid

   if @@rowcount = 0 
   begin
	  set rowcount 0
	  break
   end

   select @w_cabecera = @w_cabecera + @w_columna + '^|'
end

select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 2)

--Escribir Cabecera
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_plano

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 
begin
   select @w_error = 2902797, @w_mensaje = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERROR
end

--Ejecucion para Generar Archivo Datos
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_venta_universo_log out '

select  
@w_destino  = @w_path + 'ca_venta_log.txt',
@w_errores  = @w_path + 'ca_venta_log.err'


select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'


exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 
begin
   select @w_mensaje = 'Error Generando Archivo Reporte VENTA' 
   goto ERROR
end

----------------------------------------
--Union de archivos (cab) y (dat)
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_plano + ' + ' + @w_path + 'ca_venta_log.txt' + ' ' + @w_nombre_plano


exec @w_error = xp_cmdshell @w_comando

	
select @w_cmd = 'del ' + @w_destino 
exec xp_cmdshell @w_cmd


if @w_error <> 0 
begin
   select @w_error = 2902797, 
          @w_mensaje = 'EJECUCION comando bcp FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS'
   goto ERROR
end

drop table ca_venta_universo_log

return 0

ERROR:

exec sp_errorlog
@i_fecha     = @w_fecha_proceso,
@i_error     = @w_error ,
@i_usuario   = 'user' ,
@i_tran      = NULL ,
@i_tran_name = @w_mensaje,
@i_rollback  = 'N' 

return @w_error
go
