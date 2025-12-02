/************************************************************************/
/*      Archivo:                ca_err_camlinfin.sp                     */
/*      Stored procedure:       sp_err_camlinfin                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               COBIS-CARTERA                           */
/*      Disenado por:           Luis Guzman                             */
/*      Fecha de escritura:     14-Ene-15                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes  exclusivos  para el  Ecuador  de la   */
/*      'NCR CORPORATION'.                                              */
/*      Su  uso no autorizado  queda expresamente  prohibido asi como   */
/*      cualquier   alteracion  o  agregado  hecho por  alguno de sus   */
/*      usuarios   sin el debido  consentimiento  por  escrito  de la   */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Este programa saca un reporte de los errores generados durante  */
/*      el proceso de cambio de linea de finagro                        */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*   20150812     AJMC            RQ500 ATSK-6010                       */
/*                                Se generan archivos para mensajes de  */
/*                                usuario y de soporte tecnico          */
/************************************************************************/

use cob_cartera
go

SET ANSI_NULLS ON 
GO

if exists (select 1 from sysobjects where name = 'sp_err_camlinfin')
   drop proc sp_err_camlinfin
go
---JUL.30.2015
create proc sp_err_camlinfin
@i_param1 datetime    = null,    -- Fecha de proceso
@i_param2 varchar(60)    -- Nombre del Proceso al que se le desea conocer los errores generados

as
declare
   @w_sp_name           varchar(32),
   @w_msg               descripcion,
   @w_error             int,   
   @w_us_finagro        varchar(30),
   @w_us_finagro2       varchar(30),   
   @w_s_app             varchar(50),
   @w_path              varchar(50),
   @w_comando           varchar(500),   
   @w_mes               varchar(2),
   @w_dia               varchar(2),  
   @w_anio              varchar(4),   
   @w_hora              varchar(2),  
   @w_minuto            varchar(2),  
   @w_segundo           varchar(2),   
   @w_nombre            varchar(255),
   @w_columna           varchar(100),
   @w_nom_tabla         varchar(100),
   @w_col_id            int,
   @w_cabecera          varchar(2500),
   @w_nombre_cab        varchar(255),
   @w_fecha_archivo     datetime,   
   @w_fecha1            varchar(15),
   @w_nombre_planodet   varchar(2500),
   @w_nombre_planocab   varchar(2500),   
   @w_nombre_plano      varchar(2500),
   @w_destino           varchar(255),
   @w_errores           varchar(1500),
   @w_cmd               varchar (2500),
   @w_fecha             datetime
      
set nocount on   

/*INICIALIZA VARIABLES*/
select @w_sp_name    = 'sp_err_camlinfin',
       @w_us_finagro = null
       
select @w_fecha = @i_param1

/*CONSULTA DE PARAMETROS*/

--NOMBRE DE USUARIO QUE SE GUARDA EN LA ca_errorlog
select @w_us_finagro = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'USLIFI'

if @w_us_finagro is null
begin
   select 
   @w_msg     = 'ERROR USUARIO FINAGRO NO EXISTE'
   
   goto ERRORFIN
end

select @w_us_finagro2 = @w_us_finagro + '_USR'

/* PATH RUTA */
select @w_s_app = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

if @w_s_app is null
begin
   select 
   @w_msg     = 'ERROR CARGANDO PARAMETRO BCP'
   
   goto ERRORFIN
end

/* PATH DESTINO */
select @w_path = pp_path_destino 
from cobis..ba_path_pro
where pp_producto = 7

If @w_path is null
begin
   select 
   @w_msg     = 'ERROR CARGANDO LA RUTA BATCH DE DESTINO, REVISAR PARAMETRIZACION'
   
   goto ERRORFIN
end 

if @w_fecha is null
begin
   select 
   @w_msg     = 'ERROR, EL PARAMETRO DE ENTRADA ES NECESARIO'
   
   goto ERRORFIN
end 

if exists (select 1 from sysobjects where name = 'ca_err_camlinfin')
   drop table cob_cartera..ca_err_camlinfin

   
if @i_param2 = '' or @i_param2 is NULL or @i_param2 = 'NULL'
   select @i_param2 = NULL
   
      
select convert(varchar(10),er_fecha_proc,103) Fecha, isnull(er_cuenta,'MENSAJE GENRAL') No_Operacion, isnull(er_anexo,er_descripcion) Mensaje
into cob_cartera..ca_err_camlinfin
from cob_cartera..ca_errorlog
where er_fecha_proc = @w_fecha
and   er_usuario like '%' + @w_us_finagro + '%'
and   er_descripcion like '%' + isnull(@i_param2,er_descripcion) + '%'

if @@rowcount = 0
   print 'NO SE ENCONTRARON REGISTROS PARA ESTA CONSULTA'
----------------------------------------
--Generar Archivo de Cabeceras
----------------------------------------
select 
@w_nombre       = 'CAMBIOLINFINA',
@w_nom_tabla    = 'ca_err_camlinfin',
@w_col_id       = 0,
@w_columna      = '',
@w_cabecera     = convert(varchar(2000), ''),
@w_nombre_cab   = @w_nombre

select @w_fecha_archivo = getdate()

select @w_anio    = convert(varchar(4),datepart(yyyy,@w_fecha_archivo)),
       @w_mes     = convert(varchar(2),datepart(mm,@w_fecha_archivo)), 
       @w_dia     = convert(varchar(2),datepart(dd,@w_fecha_archivo)),
       @w_hora    = convert(varchar(2),datepart(hh,@w_fecha_archivo)), 
       @w_minuto  = convert(varchar(2),datepart(mi,@w_fecha_archivo)), 
       @w_segundo = convert(varchar(2),datepart(ss,@w_fecha_archivo))  

select @w_fecha1  = (@w_anio + right('00' + @w_mes,2) + right('00'+ @w_dia,2) + '_' + right('00'+ @w_hora,2) + right('00'+ @w_minuto,2) + right('00'+ @w_segundo,2))
select @w_nombre_planodet = @w_path + @w_nombre_cab + 'DET_' + @w_fecha1 + '.txt'
select @w_nombre_planocab = @w_path + @w_nombre_cab + 'CAB_' + @w_fecha1 + '.txt'
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
select @w_comando = 'echo ' + @w_cabecera + ' > ' + @w_nombre_planocab

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 
begin
   select 
   @w_msg   = 'EJECUCION comando bcp 1 FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.',
   @w_error = 2902797
   
   goto ERRORFIN
end

--Ejecucion para Generar Archivo Datos
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_err_camlinfin out '

select  
@w_destino  = @w_path + @w_nombre+'DET.txt',
@w_errores  = @w_path + @w_nombre+'DET.err'

select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 
begin
   select @w_msg = 'Error Generando Archivo Reporte Detalle: '+ @w_nombre,
   @w_error = 2902797
   
   goto ERRORFIN
end

----------------------------------------
--Union de archivos (cab) y (dat)
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_planocab + ' + ' + @w_path + @w_nombre+'DET.txt' + ' ' + @w_nombre_planodet 

exec @w_error = xp_cmdshell @w_comando
    
select @w_cmd = 'del ' + @w_destino 
exec xp_cmdshell @w_cmd

if @w_error <> 0 
begin
   select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp 2 FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERRORFIN
end

----------------------------------------
-- GENERACION ARCHIVO DE USUARIO
----------------------------------------
drop table cob_cartera..ca_err_camlinfin

select convert(varchar(10),er_fecha_proc,103) Fecha, isnull(er_cuenta,'MENSAJE GENRAL') No_Operacion, isnull(er_anexo,er_descripcion) Mensaje
into cob_cartera..ca_err_camlinfin
from cob_cartera..ca_errorlog
where er_fecha_proc = @w_fecha
and   er_usuario    = @w_us_finagro2

--Ejecucion para Generar Archivo Datos
select @w_comando = @w_s_app + 's_app bcp -auto -login cob_cartera..ca_err_camlinfin out '

select
@w_destino  = @w_path + @w_nombre+'.txt',
@w_errores  = @w_path + @w_nombre+'.err'

select @w_comando = @w_comando + @w_destino + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + '-config '+ @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando

if @w_error <> 0 
begin
   select @w_msg = 'Error Generando Archivo Reporte de usuario: '+ @w_nombre,
   @w_error = 2902797
   
   goto ERRORFIN
end

----------------------------------------
--Union de archivos (cab) y (dat)
----------------------------------------

select @w_comando = 'copy ' + @w_nombre_planocab + ' + ' + @w_path + @w_nombre+'.txt' + ' ' + @w_nombre_plano 

exec @w_error = xp_cmdshell @w_comando

select @w_cmd = 'del ' + @w_destino 
exec xp_cmdshell @w_cmd

if @w_error <> 0 
begin
   select @w_error = 2902797, @w_msg = 'EJECUCION comando bcp 3 FALLIDA. REVISAR ARCHIVOS DE LOG GENERADOS.'
   goto ERRORFIN
end
         
return 0


ERRORFIN:
print @w_msg
return @w_error

go 