use cobis
go
/************************************************************/
/*   ARCHIVO:         sp_batch_data_ofuscada.sp            */
/*   NOMBRE LOGICO:   sp_batch_data_ofuscada               */
/*   PRODUCTO:        COBIS CREDITO                         */
/************************************************************/
/*                     IMPORTANTE                           */
/*   Esta aplicacion es parte de los  paquetes bancarios    */
/*   propiedad de MACOSA S.A.                               */
/*   Su uso no autorizado queda  expresamente  prohibido    */
/*   asi como cualquier alteracion o agregado hecho  por    */
/*   alguno de sus usuarios sin el debido consentimiento    */
/*   por escrito de MACOSA.                                 */
/*   Este programa esta protegido por la ley de derechos    */
/*   de autor y por las convenciones  biginternacionales de */
/*   propiedad bigintelectual.  Su uso  no  autorizado dara */
/*   derecho a MACOSA para obtener ordenes  de secuestro    */
/*   o  retencion  y  para  perseguir  penalmente a  los    */
/*   autores de cualquier infraccion.                       */
/************************************************************/
/*                     PROPOSITO                            */
/*  Generar el archivo DataOfuscada.properties              */
/************************************************************/
/*                     MODIFICACIONES                       */
/*   FECHA            AUTOR              RAZON              */
/* 06/Agosto/2018     Alexander Inca     Emision inicial    */
/************************************************************/
if exists(select 1 from sysobjects where name = 'sp_batch_data_ofuscada')
   drop proc sp_batch_data_ofuscada
go
create proc sp_batch_data_ofuscada (
  @t_show_version       bit         =   0
)as
declare
  @w_sp_name        varchar(20), 
  @w_destino        varchar(255),
  @w_nombre         varchar(100),
  @w_comando        varchar(100),
  @w_error          int,
  @w_errores        varchar(1500),
  @w_path           varchar(255),
  @w_cuerpo         varchar(100)

select   @w_sp_name= 'sp_batch_data_ofuscada'

--Versionamiento del Programa --
if @t_show_version = 1
begin
 print 'Stored Procedure=' + @w_sp_name + ' Version=' + '1.0.0.0'
 return 0
end

--Captura de la ruta y el nombre del archivo
select @w_path=ba_path_destino,@w_nombre=ba_arch_resultado 
from cobis..ba_batch
where ba_nombre='GENERACION ARCHIVO DRP'

--Inicialización del cuerpo del archivo
  select @w_cuerpo='flag=true'

  -- Sección creación del archivo con el nombre y la ruta especificada
select @w_destino  = @w_path +'\' +@w_nombre,
       @w_errores  = @w_path +'\' + @w_nombre  + '.err'

SET @w_comando = 'echo '+@w_cuerpo+'>'+@w_destino

--Ejecucion para Generar Archivo Datos
execute @w_error = xp_cmdshell @w_comando
if @w_error <> 0 begin
print 'Fallo la creación del archivo'
end
 
go
