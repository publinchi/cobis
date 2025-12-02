/***********************************************************************/
/*      Producto:                       Cartera                        */
/*      Disenado por:                   Elcira Pelaez                  */
/*      Fecha de Documentacion:         NOv-2013                       */
/*      Procedimiento                   ca_querySF.sp                  */
/***********************************************************************/
/*                      IMPORTANTE                                     */
/*      Este programa es parte de los paquetes bancarios propiedad de  */
/*      'MACOSA',representantes exclusivos para el Ecuador de la       */
/*      AT&T                                                           */
/*      Su uso no autorizado queda expresamente prohibido asi como     */
/*      cualquier autorizacion o agregado hecho por alguno de sus      */
/*      usuario sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante             */
/***********************************************************************/
/*                      PROPOSITO                                      */
/*      Este stored procedure genera iformacion de la tabla            */
/*      cobis..cl_autoriza_sarlaft_lista                               */
/***********************************************************************/
/*                      MODIFICACIONES                                 */
/*      FECHA           AUTOR                   RAZON                  */
/***********************************************************************/
use cob_cartera
go

-----CREACION DE tABLAS DE TRABAJO
if exists (select 1 from sysobjects where name = 'Totales_sarlaft_tmp')
drop table Totales_sarlaft_tmp
go
create table Totales_sarlaft_tmp (
                   
t_mensaje                varchar(200) null ,
t_sec_refinh             char(1) null,     
t_totales                int null
)
go

if exists (select 1 from sysobjects where name = 'detalle1_sarlaft_tmp')
drop table detalle1_sarlaft_tmp
go
create table detalle1_sarlaft_tmp (
                   
S_SEC_REFINH           int       null,                                  
S_TIPO_IDEN            char    (5) null,                                
S_IDENTIFICAION        char    (13) null,                               
S_NOMBRE_LARGO         varchar (100) null,                              
S_ORIGEN_REFINH        varchar (10) null,  --ofiinca detalle clientes   
S_ESTADO_REFINH        varchar (10)  null, ---actividad detalle lcientes
S_FECHA_REFINH         varchar(20)     null,                              
S_AUT_SARLAFT          char    (1)   null,                              
S_OBSERVACION_SARLAFT  varchar (80) null,  ---des actividad             
S_USR_SARLAFT          login        null,  ----producto                 
S_FECHA_SARLAFT        varchar(20)     null,                               
S_AUT_CIAL             char    (1)  null,                               
S_OBS_CIAL             varchar (80) null,  ---des producto              
S_USR_CIAL             login        null,  ---canal                     
S_FECHA_CIAL           varchar(20)     null,                               
S_VALIDA_TOTAL         char    (1) null,                                
S_OFICINA              smallint    null 
)
go

if exists (select 1 from sysobjects where name = 'detalle2_Comercial_tmp')
drop table detalle2_Comercial_tmp
go
create table detalle2_Comercial_tmp (
                   
C_SEC_REFINH           int       null,                                  
C_TIPO_IDEN            char    (5) null,                                
C_IDENTIFICAION        char    (13) null,                               
C_NOMBRE_LARGO         varchar (100) null,                              
C_ORIGEN_REFINH        varchar (10) null,  --ofiinca detalle clientes   
C_ESTADO_REFINH        varchar (10)  null, ---actividad detalle lcientes
C_FECHA_REFINH         varchar(20)      null,                              
C_AUT_SARLAFT          char    (1)   null,                              
C_OBSERVACION_SARLAFT  varchar (80) null,  ---des actividad             
C_USR_SARLAFT          login        null,  ----producto                 
C_FECHA_SARLAFT        varchar(20)     null,                               
C_AUT_CIAL             char    (1)  null,                               
C_OBS_CIAL             varchar (80) null,  ---des producto              
C_USR_CIAL             login        null,  ---canal                     
C_FECHA_CIAL           varchar(20)    null,                               
C_VALIDA_TOTAL         char    (1) null,                                
C_OFICINA              smallint    null 
)
go

if exists (select 1 from sysobjects where name = 'detalle_cliente_tmp')
drop table detalle_cliente_tmp
go
create table detalle_cliente_tmp (
Ente            int null,
Tipo_Doc        catalogo null,
Documento       char(15) null,
Nombre          varchar(100), 
Oficina         int null,
Actividad       catalogo null,
Des_Actividad   varchar(80) null,
Nro_Operacion   cuenta null,
EstadoOp        catalogo null,
Producto        tinyint null,
Des_producto    varchar(80) null,
Canal           catalogo null 
)
go

if exists (select * from sysobjects where name = 'sp_cl_querySF')
   drop proc sp_cl_querySF
go
---ORS 639 NOV.28.2013
create proc sp_cl_querySF 

as

declare
@w_error            int,
@w_msg              varchar(250),
@w_sp_name          varchar(30),
@w_fecha_arch       varchar(8),
@w_comando          varchar(1000),
@w_cmd              varchar(300),
@w_s_app            varchar(30),
@w_path_listados    varchar(250),
@w_archivo_tmp1          varchar(300),
@w_archivo_tmp2          varchar(300),
@w_archivo_tmp3          varchar(300),
@w_archivo_tmp4          varchar(300),
@w_batch            int,
@w_fecha_proc       varchar(10),
@w_errores          varchar(250),
@w_destino            varchar(255),
@w_cabecera1          varchar(355),
@w_cabecera_clintes   varchar(255),
@w_cabecera_totales   varchar(255)

truncate table detalle1_sarlaft_tmp 
truncate table detalle2_Comercial_tmp 
truncate table detalle_cliente_tmp 
truncate table Totales_sarlaft_tmp 

print ''
print 'GENERANDO TOTALES'
PRINT ''
print ''
print 'APROBADO POR SARLAFT'
print ''
print '[Aprobaciones Realizadas por Sarlaft y Aprobadas por Comercial]'
insert into Totales_sarlaft_tmp
select '[Aprobaciones Realizadas por Sarlaft y Aprobadas por Comercial]',as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_sarlaft = 'S'
and    as_aut_cial    = 'S'
group by as_aut_sarlaft 

print '[Aprobaciones Realizadas por Sarlaft y Rechazadas por Comercial]'
insert into Totales_sarlaft_tmp
select '[Aprobaciones Realizadas por Sarlaft y Rechazadas por Comercial]',as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_sarlaft = 'S'
and    as_aut_cial    = 'N'
group by as_aut_sarlaft 

print '[Aprobaciones realizadas por sarlaft y Pendientes de verificacion por Comercial]'
insert into Totales_sarlaft_tmp
select  '[Aprobaciones realizadas por sarlaft y Pendientes de verificacion por Comercial]', as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_sarlaft = 'S'
and    as_aut_cial is null
group by as_aut_sarlaft 

print ''
print 'RECHAZADO POR SARLAFT'
print ''
print '[Rechazadas por Sarlaft y Aprobadas por Comercial]'
insert into Totales_sarlaft_tmp
select '[Rechazadas por Sarlaft y Aprobadas por Comercial]',as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_sarlaft = 'N'
and    as_aut_cial    = 'S'
group by as_aut_sarlaft 

print '[Rechazadas por Sarlaft y Rechazadas por Comercial'
insert into Totales_sarlaft_tmp
select '[Rechazadas por Sarlaft y Rechazadas por Comercial',as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_sarlaft = 'N'
and    as_aut_cial    = 'N'
group by as_aut_sarlaft 

print '[Rechazadas por sarlaft y Pendientes de verificacion por Comercial]'
insert into Totales_sarlaft_tmp
select '[Rechazadas por sarlaft y Pendientes de verificacion por Comercial]',as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_sarlaft = 'N'
and    as_aut_cial is null
group by as_aut_sarlaft 

print ''
print 'PENDIENTES DE GESTIONAR POR SARLAFT'
print ''
print '[Pendientes por Sarlaft y Aprobadas por Comercial]'
insert into Totales_sarlaft_tmp
select '[Pendientes por Sarlaft y Aprobadas por Comercial]',as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_cial = 'S'
and    as_aut_sarlaft is null
group by as_aut_sarlaft 

print '[Pendientes por Sarlaft y Rechazadas por Comercial]'
insert into Totales_sarlaft_tmp
select '[Pendientes por Sarlaft y Rechazadas por Comercial]',as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_cial = 'N'
and    as_aut_sarlaft is null
group by as_aut_sarlaft 

print '[Pendientes por Sarlaft y Pendientes de Verificacion por Comercial]'
insert into Totales_sarlaft_tmp
select '[Pendientes por Sarlaft y Pendientes de Verificacion por Comercial]',as_aut_sarlaft, count(0)
from   cobis..cl_autoriza_sarlaft_lista with (nolock)
where  as_aut_sarlaft is null
and    as_aut_cial    is null
group by as_aut_sarlaft 

PRINT ''
PRINT 'Fin generacion Totales'


print ''
print 'Detalle Gestion Realizada por Sarlaft'
print ''
insert into detalle1_sarlaft_tmp 
select distinct
as_sec_refinh,
as_tipo_id,
as_nro_id,
replace(replace(replace(as_nombrelargo, char(13) + char(10), ''), char(9), ''), char(13), '') as as_nombrelargo,
as_origen_refinh,
as_estado_refinh,
as_fecha_refinh,
as_aut_sarlaft,
replace(replace(replace(as_obs_sarlaft, char(13) + char(10), ''), char(9), ''), char(13), '') as as_obs_sarlaft,
as_usr_sarlaft,
as_fecha_sarlaft,
as_aut_cial,
replace(replace(replace(as_obs_cial, char(13) + char(10), ''), char(9), ''), char(13), '') as as_obs_cial,
as_usr_cial,
as_fecha_cial,
as_valida_total,
as_oficina
from  cobis..cl_autoriza_sarlaft_lista with (nolock)
where as_aut_sarlaft in('N','S')

print ''
print 'Detalle Gestion Realizada por Comercial'
print ''
insert into detalle2_Comercial_tmp 
select distinct
as_sec_refinh,
as_tipo_id,
as_nro_id,
replace(replace(replace(as_nombrelargo, char(13) + char(10), ''), char(9), ''), char(13), '') as as_nombrelargo,
as_origen_refinh,
as_estado_refinh,
as_fecha_refinh,
as_aut_sarlaft,
replace(replace(replace(as_obs_sarlaft, char(13) + char(10), ''), char(9), ''), char(13), '') as as_obs_sarlaft,
as_usr_sarlaft,
as_fecha_sarlaft,
as_aut_cial,
replace(replace(replace(as_obs_cial, char(13) + char(10), ''), char(9), ''), char(13), '') as as_obs_cial,
as_usr_cial,
as_fecha_cial,
as_valida_total,
as_oficina
from  cobis..cl_autoriza_sarlaft_lista with (nolock)
where as_aut_cial in('N','S')

print ''
print '[Detalle Clientes]'
print ''
insert into detalle_cliente_tmp 
select distinct
en_ente, 
en_tipo_ced, 
en_ced_ruc,  
en_nombre, 
en_oficina, 
en_actividad, 
(select b.valor 
    from cobis..cl_tabla a, 
         cobis..cl_catalogo b 
    where a.tabla = 'cl_actividad' 
    and b.tabla = a.codigo 
    and b.codigo = en_actividad),
dp_cuenta,
dp_estado_ser,
dp_producto,
(select pd_descripcion 
     from cobis..cl_producto 
     where pd_producto = dp_producto), 
'OFI'
from  cobis..cl_autoriza_sarlaft_lista with (nolock),
      cobis..cl_det_producto with (nolock), 
      cobis..cl_ente with (nolock)
where en_ced_ruc    = as_nro_id
and   en_ente       = dp_cliente_ec
and   dp_estado_ser = 'V'
and   en_tipo_ced = as_tipo_id


print ''
print '---Iniciooo  Generacion del plano'
print ''
---------------------------------------------------------------------------------------
select @w_fecha_proc = convert(varchar, fp_fecha, 101)
from cobis..ba_fecha_proceso

if @@rowcount = 0 begin
   select @w_error = 2101084
   print  'ERROR AL OBTENER LA FECHA DE PROCESO'
   goto ERROR
end

select @w_fecha_arch    = convert(char(8),fp_fecha,112)
from cobis..ba_fecha_proceso

-----------------GENERACION PLANO -----------------------------------------------------------------------------------------

select @w_archivo_tmp1 = 'PLANO_GEST_REALIZO_SARLAFT_1_' + @w_fecha_arch 
select @w_archivo_tmp2 = 'PLANO_GEST_REALIZO_COMERCIAL_2_' + @w_fecha_arch 
select @w_archivo_tmp3 = 'PLANO_DETALLE_CLIENTES_3_' + @w_fecha_arch 
select @w_archivo_tmp4 = 'PLANO_TOTALES_4_' + @w_fecha_arch 

select @w_cabecera1 ='SEC_REFINH|tdocumento|IDENTIFICAION|NOMBRE_LARGO|ORIGEN_REFINH|ESTADO_REFINH|FECHA_REFINH|AUT_SARLAFT|OBSERVACION_SARLAFT| USR_SARLAFT|FECHA_SARLAFT|AUT_CIAL|OBS_CIAL|USR_CIAL|FECHA_CIAL|VALIDA_TOTAL|OFICINA'
select @w_cabecera_clintes = 'Ente|Tipo_Doc|Documento|Nombre|Oficina|Actividad|Des_Actividad|Nro_Operacion|EstadoOper|Producto|Des_producto|Canal'  
select @w_cabecera_totales = 'mensaje|sec_refinh|total'

select @w_s_app   = pa_char
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'S_APP'

if @@rowcount = 0 begin
 print 'ERROR AL OBTENER EL PARAMETRO GENERAL S_APP DE ADM'
 select @w_error = 2101084
 goto ERROR
end

select  @w_batch = ba_batch
from cobis..ba_batch
where ba_arch_fuente = 'cob_cartera..sp_cl_querySF'

select @w_path_listados = ba_path_destino
from cobis..ba_batch
where ba_batch = @w_batch

print'---GEneracion archivo plano 1 gestionados SARLAFT'
---===================================================================================================
select @w_comando  = 'ERASE ' + @w_path_listados + 'ARCHIVO_TMP1.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'ARCHIVO_TMP1.TXT'
    print @w_comando
    select @w_error = 2101084
   goto ERROR
end

select @w_comando  = 'ERASE ' +  @w_path_listados + @w_archivo_tmp1 + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + @w_archivo_tmp1
    print @w_comando
	 select @w_error = 2101084
	 goto ERROR    
end


select @w_errores  = @w_path_listados + @w_archivo_tmp1 + '.err'
select @w_cmd      = @w_s_app + 's_app bcp cob_cartera..detalle1_sarlaft_tmp out '
select @w_comando  = @w_cmd + @w_path_listados + 'ARCHIVO_TMP1.TXT' + ' -b5000 -c -e' + @w_errores + ' -t"|" ' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + 'ARCHIVO_TMP1.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end

select 'est es la cabecera'
select  @w_cabecera1

select @w_comando = 'echo ' +   '"' + @w_cabecera1 +  ' >> ' + @w_path_listados + @w_archivo_tmp1 + '.txt' + '"'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + @w_archivo_tmp1
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'TYPE ' + @w_path_listados + 'ARCHIVO_TMP1.TXT >> ' + @w_path_listados + @w_archivo_tmp1 + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error uniendo archivos Archivo: ' + @w_archivo_tmp1
    select @w_error = 2101084
    goto ERROR    
end

select @w_comando  = 'ERASE ' + @w_path_listados + 'ARCHIVO_TMP1.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'ARCHIVO_TMP1.TXT'
    select @w_error = 2101084
    goto ERROR    
end

-----fin generacion archivo 1
---===================================================================================================

print '---GEneracion archivo plano 2 gestionados SARLAFT'
---===================================================================================================
select @w_comando  = 'ERASE ' + @w_path_listados + 'ARCHIVO_TMP2.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'ARCHIVO_TMP2.TXT'
    print @w_comando
    select @w_error = 2101084
   goto ERROR
end

select @w_comando  = 'ERASE ' +  @w_path_listados + @w_archivo_tmp2 + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + @w_archivo_tmp2
    print @w_comando
	 select @w_error = 2101084
	 goto ERROR    
end


select @w_errores  = @w_path_listados + @w_archivo_tmp2 + '.err'
select @w_cmd      = @w_s_app + 's_app bcp cob_cartera..detalle2_Comercial_tmp out '
select @w_comando  = @w_cmd + @w_path_listados + 'ARCHIVO_TMP2.TXT' + ' -b5000 -c -e' + @w_errores + ' -t' + '"' +'|'+ '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + 'ARCHIVO_TMP2.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'echo ' +   '"' + @w_cabecera1 +  ' >> ' + @w_path_listados + @w_archivo_tmp2 + '.txt' + '"'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + @w_archivo_tmp2
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'TYPE ' + @w_path_listados + 'ARCHIVO_TMP2.TXT >> ' + @w_path_listados + @w_archivo_tmp2 + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error uniendo archivos Archivo: ' + @w_archivo_tmp2
    select @w_error = 2101084
    goto ERROR    
end

select @w_comando  = 'ERASE ' + @w_path_listados + 'ARCHIVO_TMP2.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'ARCHIVO_TMP2.TXT'
    select @w_error = 2101084
    goto ERROR    
end

-----fin generacion archivo 2
---===================================================================================================

print '---GEneracion archivo plano 3 Detalle clientes'
---===================================================================================================
select @w_comando  = 'ERASE ' + @w_path_listados + 'ARCHIVO_TMP3.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'ARCHIVO_TMP3.TXT'
    print @w_comando
    select @w_error = 2101084
   goto ERROR
end

select @w_comando  = 'ERASE ' +  @w_path_listados + @w_archivo_tmp3 + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + @w_archivo_tmp3
    print @w_comando
	 select @w_error = 2101084
	 goto ERROR    
end


select @w_errores  = @w_path_listados + @w_archivo_tmp3 + '.err'
select @w_cmd      = @w_s_app + 's_app bcp cob_cartera..detalle_cliente_tmp  out '
select @w_comando  = @w_cmd + @w_path_listados + 'ARCHIVO_TMP3.TXT' + ' -b5000 -c -e' + @w_errores + ' -t' + '"' +'|'+ '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + 'ARCHIVO_TMP3.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'echo ' +   '"' + @w_cabecera_clintes +  ' >> ' + @w_path_listados + @w_archivo_tmp3 + '.txt' + '"'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + @w_archivo_tmp3
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'TYPE ' + @w_path_listados + 'ARCHIVO_TMP3.TXT >> ' + @w_path_listados + @w_archivo_tmp3 + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error uniendo archivos Archivo: ' + @w_archivo_tmp3
    select @w_error = 2101084
    goto ERROR    
end

select @w_comando  = 'ERASE ' + @w_path_listados + 'ARCHIVO_TMP3.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'ARCHIVO_TMP3.TXT'
    select @w_error = 2101084
    goto ERROR    
end

-----fin generacion archivo 3
---===================================================================================================

print'---GEneracion archivo plano Totales'
---===================================================================================================
select @w_comando  = 'ERASE ' + @w_path_listados + 'ARCHIVO_TMP4.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'ARCHIVO_TMP4.TXT'
    print @w_comando
    select @w_error = 2101084
   goto ERROR
end

select @w_comando  = 'ERASE ' +  @w_path_listados + @w_archivo_tmp4 + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + @w_archivo_tmp4
    print @w_comando
	 select @w_error = 2101084
	 goto ERROR    
end


select @w_errores  = @w_path_listados + @w_archivo_tmp4 + '.err'
select @w_cmd      = @w_s_app + 's_app bcp cob_cartera..Totales_sarlaft_tmp  out '
select @w_comando  = @w_cmd + @w_path_listados + 'ARCHIVO_TMP4.TXT' + ' -b5000 -c -e' + @w_errores + ' -t' + '"' +'|'+ '"' + ' -auto -login ' + '-config ' + @w_s_app + 's_app.ini'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + 'ARCHIVO_TMP4.TXT'
    print @w_comando
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'echo ' +   '"' + @w_cabecera_totales +  ' >> ' + @w_path_listados + @w_archivo_tmp4 + '.txt' + '"'
exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error generando Archivo: ' + @w_archivo_tmp4
	select @w_error = 2101084
	goto ERROR    
end

select @w_comando = 'TYPE ' + @w_path_listados + 'ARCHIVO_TMP4.TXT >> ' + @w_path_listados + @w_archivo_tmp4 + '.txt'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error uniendo archivos Archivo: ' + @w_archivo_tmp4
    select @w_error = 2101084
    goto ERROR    
end

select @w_comando  = 'ERASE ' + @w_path_listados + 'ARCHIVO_TMP4.TXT'

exec @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
    print 'Error borrando Archivo: ' + 'ARCHIVO_TMP4.TXT'
    select @w_error = 2101084
    goto ERROR    
end

-----fin generacion archivo Totales
---===================================================================================================

return 0


ERROR:
return @w_error

go


