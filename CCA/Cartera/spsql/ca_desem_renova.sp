/************************************************************************/
/*   Archivo:                   ca_desem_renov.sp                       */
/*   Stored procedure:          sp_desem_renov                          */
/*   Base de datos:             cob_cartera                             */
/*   Producto:                  Cartera                                 */
/*   Disenado por:              Ivonne Torres                           */
/*   Fecha de escritura:        Febrero-2010                            */
/************************************************************************/
/*                             IMPORTANTE                               */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'.                                                       */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/************************************************************************/
/*                             PROPOSITO                                */
/*	 Debe generarse un archivo de desembolsos de las oficinas           */
/*   en un rango de fechas (Fecha Inicial - Fecha Final)                */
/*   Campos:                                                            */
/*   Fecha Desembolso                                                   */
/*   Oficina Desembolso                                                 */
/*   Monto                                                              */
/*                                                                      */  
/*   Cuando se trate de desembolsos realizados a causa de una           */
/*   RENOVACION, solo se debe tomar en cuenta el valor entregado al     */
/*   cliente.	                                                        */ 
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_desem_renov')
    drop proc sp_desem_renov
go
create proc sp_desem_renov
@i_param1  varchar(10),
@i_param2  varchar(10)
as

set ansi_warnings off

declare
@w_error              int,           -- VALOR QUE RETORNA
@w_sp_name            varchar(32),   -- NOMBRE STORED PROC
@w_msg                varchar(255),  -- MENSAJE DE ERROR
@w_fecha_hora         datetime,      -- FECHA Y HORA DE CORRDIDA
@w_path_s_app         varchar(250),
@w_fecha              datetime,      -- FECHA EN QUE SE REPORTA EL VALOR DE COBERTURA
@w_path               varchar(250),
@w_s_app              varchar(250),
@w_cmd                varchar(250),
@w_bd                 varchar(250),
@w_tabla              varchar(250),
@w_fecha_arch         varchar(10),
@w_comando            varchar(500),
@w_destino            varchar(250),
@w_errores            varchar(250),
@w_erroresc           varchar(250),
@w_archivoc           varchar(64),
@w_archivod           varchar(64),
@w_destinoc           varchar(250),
@w_archivo            varchar(64),
@w_nombre             varchar(60),
@i_fecha_ini          datetime,
@i_fecha_fin          datetime,
@anio_listado         varchar(10),
@mes_listado          varchar(10),
@dia_listado          varchar(10)


/*FECHA DE EJECUCION*/
select @w_fecha_hora = getdate()


/*PARAMETROS*/   
select 
@i_fecha_ini = convert(datetime,@i_param1),
@i_fecha_fin = convert(datetime,@i_param2)


select @w_path_s_app = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'S_APP'

if @w_path_s_app is null begin
   select @w_msg = 'NO EXISTE PARAMETRO GENERAL S_APP'
   goto ERROR
end
	


/*TABLAS DE TRABAJO*/
if exists (select * from sysobjects where name = 'cab_desembolso')
    drop table cab_desembolso

create table cab_desembolso
(fecha        varchar(30),
 oficina      varchar(30),
 monto        varchar(30)
)


if exists (select * from sysobjects where name = 'det_desembolso')
    drop table det_desembolso

create table det_desembolso
(fecha        varchar(10) null,
 oficina      int         null,
 monto_desem  money       null
)


/* POBLAR TABLAS */

insert into cab_desembolso values('FECHA','OFICINA','MONTO')

insert into det_desembolso
select convert(varchar(10),dm_fecha,101) as fecha, dm_oficina, round(sum(op_monto),2) as monto
from ca_desembolso, ca_operacion
where dm_fecha >= @i_fecha_ini
and   dm_fecha <= @i_fecha_fin
and   dm_producto  in ('EFMN','CHOTBCOS','NCAHO','CHGEREN')
and   dm_operacion  = op_operacion
group by dm_fecha, dm_oficina




/* HAGO EL BCP */

select
@w_s_app      = @w_path_s_app+'s_app'

select
@w_path = ba_path_destino
from cobis..ba_batch
where ba_batch = 7084

                          
select
@w_cmd       = @w_s_app+' bcp -auto -login ',
@w_bd        = 'cob_cartera',
@w_tabla     = 'cab_desembolso',
@w_archivoc  = 'cab_desemsolso'

select 
@w_destinoc  = @w_path + @w_archivoc +'.txt',
@w_erroresc  = @w_path + @w_archivoc +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destinoc + ' -b5000 -c -e'+@w_erroresc + ' -t"~" ' + '-config '+@w_s_app+'.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO CABECERA '+@w_destinoc+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


/* TABLA DEL REPORTE */  -- DATOS
select
@w_cmd      = @w_s_app+' bcp -auto -login ',
@w_bd       = 'cob_cartera',
@w_tabla    = 'det_desembolso',
@w_archivod = 'datos'

select 
@w_destino  = @w_path + @w_archivod +'.txt',
@w_errores  = @w_path + @w_archivod +'.err'

select
@w_comando = @w_cmd + @w_bd + '..' + @w_tabla + ' out ' + @w_destino + ' -b5000 -c -e'+@w_errores + ' -t"~" ' + '-config '+@w_s_app+'.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO '+@w_destino+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


select @w_fecha_arch = convert(varchar, @w_fecha_hora, 112),
       @anio_listado = substring(@w_fecha_arch,1,4),
       @mes_listado  = substring(@w_fecha_arch,5,2), 
       @dia_listado  = substring(@w_fecha_arch,7,2)

select @w_fecha_arch = @mes_listado + @dia_listado + @anio_listado 


/*** CONCATENACION DE ARCHIVO CABECERA CON ARCHIVO DE DATOS  ***/
select @w_nombre = 'ca_desem_renov' + @w_fecha_arch

select
@w_archivo  = @w_path + @w_nombre +'.txt',
@w_comando = 'type ' + @w_destinoc + ' ' + @w_destino + ' > ' + @w_archivo

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


/*** ELIMINACION DE ARCHIVO DE CABECERA Y DATOS  ***/

select
@w_comando = 'rm ' + @w_destinoc 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end

select
@w_comando = 'rm ' + @w_erroresc 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
   goto ERROR
end


select
@w_comando = 'rm ' + @w_destino 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
   select @w_msg = 'ERROR AL GENERAR ARCHIVO FINAL '+@w_archivo+ ' '+ convert(varchar, @w_error)
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
   exec @w_error = sp_errorlog
        @i_fecha      = @w_fecha_hora,
        @i_error      = 1900000,
        @i_usuario    = 'sa',
        @i_tran       = 7086,
        @i_tran_name  = @w_msg,
        @i_rollback   = 'N'

return 1900000

go

