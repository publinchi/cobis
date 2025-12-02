/************************************************************************/
/*   Archivo:            ca_plano_migra_cifin.sp                        */
/*   Stored procedure:   sp_plano_migra_cifin                           */
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
/*      Migra Informacion CIFIN                                         */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA              AUTOR         RAZON                              */
/*  Diciembre-16-2013   Luis Guzman  Emision Inicial                    */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_plano_migra_cifin')
   drop proc sp_plano_migra_cifin
go

create proc sp_plano_migra_cifin

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

select @w_sp_name = 'sp_plano_migra_cifin'

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

if exists (select 1 from sysobjects where name = 'ca_venta_cartera_cifin')
   drop table ca_venta_cartera_cifin

select @w_fecha_venta = max(Fecha_Venta)
from cob_cartera..ca_venta_universo

-- CONSULTA CIFIN
select CONVERT(varchar(20), replicate('0',20-len(Numero_Obli_o_Crd)) + Numero_Obli_o_Crd) + CONVERT(varchar(6),replicate('0',6-len(op_oficina)) + convert(varchar(6),op_oficina)) as Registro
into ca_venta_cartera_cifin
from cob_cartera..ca_venta_universo, cob_cartera..ca_operacion
where op_operacion = operacion_interna
and   Estado_Venta = 'P'
and   Fecha_Venta  = @w_fecha_venta

----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select 
@w_nombre       = 'ca_cifin',
@w_nom_tabla    = 'ca_venta_cartera_cifin',
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = convert(varchar(1000), ''),
@w_nombre_cab   = @w_nombre

--Ejecucion para Generar Archivo Datos
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_venta_cartera_cifin out '

select  
@w_destino  = @w_path + 'ca_cifin' + '_' + @w_fecha1 + '.txt',
@w_errores  = @w_path + 'ca_cifin.err'


select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'


exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 
begin
   select @w_mensaje = 'Error Generando Archivo Reporte CIFIN' 
   goto ERROR
end

drop table ca_venta_cartera_cifin

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
