/************************************************************************/
/*   Archivo:             ca_PMatriz.sp                                 */
/*   Stored procedure:    sp_plano_matriz                               */
/*   Base de datos:       cob_cartera                                   */
/*   Producto:            Credito y Cartera                             */
/*   Disenado por:        Elcira PElaez                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Reporte de datos parametrizados en una matriz                      */
/************************************************************************/

use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_plano_matriz')
   drop proc sp_plano_matriz
go
---Ver.INC.79879 partiendo de la version 6
CREATE proc sp_plano_matriz
@i_param1 varchar(255)
as

declare 

@w_fecha_desde     datetime,
@w_fecha_cartera     datetime,
@w_msg             varchar(255),
@w_sp_name         varchar(30),
@w_error           int,

-- VARIABLES BCP 

@w_sp_name_batch     varchar(30),
@w_s_app             varchar(30),
@w_path              varchar(255),
@w_path_listados     varchar(255),
@w_fecha_arch        varchar(10),
@w_hora_arch         varchar(4),
@w_comando           varchar(1000),
@w_nombre_plano      varchar(200),
@w_archivo           varchar(255),
@w_plano_errores     varchar(200),
@w_cmd               varchar(300),
@w_sp                varchar(40),
@w_cabecera          varchar(400),
@w_fecha_ejecutada   varchar(10),
@w_errores           varchar(255),
@w_oficina           int,
@w_proceso           char(1),
@w_cantidad_ejes     int,
@w_nombre_eje        varchar(30),
@w_cont              int,
@w_matriz            varchar(15),
@w_cabe1             varchar(200),
@w_cabe2             varchar(200),
@w_destino           varchar(255),
@w_dia               varchar(2),
@w_mes               varchar(2),
@w_anio              varchar(4),
@w_debug             char(1)

set nocount on
set ANSI_WARNINGS OFF

select @w_cont = 1
select @w_cabecera = ''
select @w_cabe2 = ''
select @w_nombre_eje = ''
select @w_nombre_eje = ''

--- VALIDAR PARAMETROS DE ENTRADA 

if @i_param1 is null begin
   select @w_msg = 'ERROR, PARAMETROS DE ENTRADA SIN VALOR O CON VALOR NULO'
   goto ERRORFIN
end

select @w_debug = 'N'

truncate table ca_matriz_plano

select 
@w_matriz = @i_param1

select @w_cabe1 = 'MATRIZ|' 
select @w_fecha_cartera = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_cantidad_ejes  = count(1)
from ca_eje
where ej_matriz = @w_matriz

select @w_cont = 1
while 1 = 1
begin
    select @w_nombre_eje = ej_descripcion
    from ca_eje
    where ej_matriz = @w_matriz
    and ej_eje = @w_cont
    
    select @w_cabecera = @w_cabecera + @w_nombre_eje + '|'
    
    select @w_cont = @w_cont + 1
    if @w_cont > @w_cantidad_ejes 
       break
end

select @w_nombre_eje = ''

while 1 = 1
begin

    if @w_cont = 16
        select @w_nombre_eje = 'VALOR'
    else
    select @w_nombre_eje = 'NOAPLICA'

    select @w_cabe2 = @w_cabe2+ @w_nombre_eje + '|'
    
    select @w_cont = @w_cont + 1
    if @w_cont > 16
       break
end

---print 'cabecera2'  + cast(@w_cabe2 as varchar)

select @w_cabecera = @w_cabe1  + @w_cabecera  + @w_cabe2
select @w_cabecera = left(@w_cabecera, datalength(@w_cabecera) - 1)
---select @w_cabecera

---CARGAR EL DATO EN LA TABLE
---Segun conversacion con el usuario se desea la data tal cmoesta en la tabla 
--- sin los rangos
insert into ca_matriz_plano 
select mv_matriz,mv_rango1 ,  mv_rango2 ,  
       mv_rango3 ,mv_rango4,  mv_rango5 ,  mv_rango6,mv_rango7 ,  mv_rango8 ,  mv_rango9,
       mv_rango10,mv_rango11,mv_rango12,mv_rango13,mv_rango14,mv_rango15,mv_valor
 from ca_matriz_valor
where mv_matriz = @w_matriz

--- RUTA DE DESTINO DEL ARCHIVO A GENERAR 
select @w_path_listados = ba_path_destino
from cobis..ba_batch
where ba_arch_fuente = 'cob_cartera..sp_plano_matriz'

if @@rowcount = 0 begin
  select @w_error = 2101084, @w_msg = 'ERROR EN LA BUSQUEDA DEL PATH EN LA TABLA ba_batch'
  goto ERRORFIN
end

--- OBTENIENDO EL PARAMETRO DE LA UBIACION DEL kernel\bin EN EL SERVIDOR
select @w_s_app   = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

if @@rowcount = 0 begin
  select @w_error = 2101084, @w_msg = 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
  goto ERRORFIN
end

--- GENERAR LOS ARCHIVOS PLANOS POR BCP
select @w_dia  = convert(varchar(2), datepart (dd, @w_fecha_cartera))
select @w_mes  = convert(varchar(2), datepart (mm, @w_fecha_cartera))
select @w_anio = convert(varchar(4), datepart (yy, @w_fecha_cartera))

--select @w_dia = CASE WHEN convert(int, @w_dia) < 10 then '0' + @w_dia else @w_dia end
if convert(int, @w_dia) < 10
   select @w_dia = '0' + @w_dia
else
   select @w_dia = @w_dia
   
--select @w_mes = CASE WHEN convert(int, @w_mes) < 10 then '0' + @w_mes else @w_mes end
if convert(int, @w_mes) < 10
   select @w_mes = '0' + @w_mes
else
   select @w_mes = @w_mes

select @w_archivo = 'ca_PMatriz_'+ convert(varchar(2), @w_dia) + convert(varchar(2), @w_mes)+ convert(varchar(4), @w_anio)+ '_' + ltrim(rtrim(@w_matriz))

print 'Archivo 1'
print ' '
print @w_archivo

select @w_comando  = 'ERASE ' + @w_path_listados + 'TITULOMZ.TXT'

print 'Comando 1'
print ' '
print  @w_comando 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'TITULOMZ.TXT'
    print @w_comando
end

select @w_comando  = 'ERASE ' +  @w_path_listados + @w_archivo + '.txt'

print 'Comando 2'
print ' '
print  @w_comando 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + @w_archivo
    print @w_comando
end

select @w_errores  = @w_path_listados + @w_archivo + '.err'
select @w_cmd      = @w_s_app + 's_app bcp cob_cartera..ca_matriz_plano out '
select @w_comando  = @w_cmd + @w_path_listados + 'TITULOMZ.TXT' + ' -b5000 -c -e' + @w_errores + ' -t' + '"' + '|' + '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

print 'Comando 3'
print ' '
print  @w_comando 

if @w_debug = 'S' begin
   print 'path salida'
   print @w_cmd
   print @w_path_listados
   print @w_comando 
   print @w_errores
end 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + 'TITULOMZ.TXT'
    print @w_comando
end

select @w_comando = 'echo ' + ''' +  @w_cabecera + ''' + ' >> ' + @w_path_listados + @w_archivo + '.txt'

print 'Comando 4'
print ' '
print  @w_comando 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + @w_archivo
    print @w_comando
    PRINT @w_error
end

waitfor delay '00:00:10'

select @w_comando = 'TYPE ' + @w_path_listados + 'TITULOMZ.TXT >> ' + @w_path_listados + @w_archivo + '.txt'

print 'Comando 5'
print ' '
print  @w_comando 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error uniendo archivos Archivo: ' + @w_archivo
    print @w_comando
    PRINT @w_error
end

waitfor delay '00:00:05'

select @w_comando  = 'ERASE ' + @w_path_listados + 'TITULOMZ.TXT'

print 'Comando 6'
print ' '
print  @w_comando 

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'TITULOMZ.TXT'
    print @w_comando
end

---FIN PLANO BCP

return 0

ERRORFIN:

exec sp_errorlog 
@i_fecha       = @w_fecha_cartera,
@i_error       = 7999, 
@i_usuario     = 'OPERADOR', 
@i_tran        = 7999,
@i_tran_name   = 'sp_plano_matriz',
@i_cuenta      = '',
@i_rollback    = 'N',
@i_descripcion = @w_msg
print @w_msg

return 1
go
