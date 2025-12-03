/************************************************************************/
/*   Archivo:            calificacion_cliente.sp                        */
/*   Stored procedure:   sp_calificacion_cliente                        */
/*   Base de datos:      cobis                                          */
/*   Producto:           Clientes                                       */
/*   Disenado por:       COB                                            */
/*   Fecha de escritura: 04-octubre-21                                  */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para  */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa se ejecuta en un procedimiento batch donde lee un    */
/*   archivo, actualiza la calificicacion de los clientes y genera un   */
/*   archivo de salida donde lista los clientes no encontrados          */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      05/10/21         COB       Emision Inicial                      */
/************************************************************************/
use cobis

go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_calificacion_cliente')
   drop proc sp_calificacion_cliente
go

create proc sp_calificacion_cliente (
   @i_param1    varchar(255) = null, --Ruta de archivo
   @i_param2    varchar(50)  = null, --Nombre de archivo de entrada
   @i_param3    varchar(50)  = null, --Nombre de archivo de salida 
   @s_ssn       int          = null,
   @s_user      login        = null,
   @s_term      varchar(32)  = null,
   @s_srv       varchar(30)  = null,
   @t_trn       int          = null
)

as declare
   @w_sp_name           descripcion,
   @w_error             int,
   @w_sql               varchar(255),
   @w_tipo_bcp          varchar(10), 
   @w_separador         varchar(1),
   @w_return            int = 0,
   @w_nombre_arch       varchar(255),
   @w_cod_persona       varchar(50)


-- VARIABLES DE TRABAJO
SELECT @w_sp_name        = 'sp_calificacion_cliente',
       @w_separador      = ','

select @w_sql = 'cobis..calif_cliente_tmp'

if exists (select 1 from sysobjects where name ='calif_cliente_tmp')
begin
	drop table calif_cliente_tmp
end
    
create table calif_cliente_tmp
( 
 cc_numero          varchar(50)   null,        
 cc_calif           char(10)      null
)

/* LECTURA DEL ARCHIVO */
select @w_nombre_arch = concat(@i_param1, @i_param2)

exec @w_return          = cobis..sp_bcp_archivos
     @i_sql             = @w_sql,           --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp        = 'in',             --tipo de bcp in,out,queryout
     @i_rut_nom_arch    = @w_nombre_arch,   --ruta y nombre de archivo
     @i_separador       = @w_separador      --separador

if @w_return != 0
begin
   select @w_error   = 1720575
   goto ERROR
end

--inicializacion de las @s
if isnull(@s_ssn, 0) = 0
begin
   select @s_ssn = 1179449
end

if isnull(@s_srv, '') = ''
begin
   select @s_srv = pa_char
   from cobis..cl_parametro
   where pa_nemonico = 'SRVR'
end

if isnull(@s_user, '') = ''
begin
   select @s_user = 'opbatch'
end

if isnull(@s_term, '') = ''
begin
   select @s_term = 'CONSOLA'
end

if isnull(@t_trn, 0) = 0
begin
   select @t_trn = 172003
end

--Eliminacion de cabecera el archivo
delete from calif_cliente_tmp where isnumeric(cc_numero) = 0

--ANTES LOG
declare enteCursor cursor for select cc_numero from cobis..calif_cliente_tmp where cc_numero in (select en_ente from cobis..cl_ente)
open enteCursor
fetch next from enteCursor into @w_cod_persona

while @@fetch_status = 0
begin

   --Registro antes del cambio
   insert into ts_persona_prin (
   secuencia,              tipo_transaccion,      clase,
   fecha,                  usuario,               terminal,
   srv,                    lsrv,                  persona,
   nombre,                 p_apellido,            s_apellido,
   sexo,                   cedula,                tipo_ced,
   pais,                   profesion,             estado_civil,
   actividad,              num_cargas,            nivel_ing,
   nivel_egr,              tipo,                  filial,
   oficina,                fecha_nac,             grupo,
   oficial,                comentario,            retencion,
   fecha_mod,              fecha_expira,          sector,
   ciudad_nac,             nivel_estudio,         tipo_vivienda,
   calif_cliente,          tipo_vinculacion,      pais_nac,
   provincia_nac,          naturalizado,          forma_migratoria,
   nro_extranjero,         calle_orig,            exterior_orig,
   estado_orig)
   select
   @s_ssn,                 @t_trn,                'A',
   getdate(),              @s_user,               @s_term,
   @s_srv,                 @s_srv,                @w_cod_persona,
   en_nombre,              p_p_apellido,          p_s_apellido,
   p_sexo,                 en_ced_ruc,            en_tipo_ced,
   en_pais,                p_ocupacion,           p_estado_civil,
   en_actividad,           p_num_cargas,          p_nivel_ing,
   p_nivel_egr,            en_subtipo,            en_filial,
   en_oficina,             p_fecha_nac,           en_grupo,
   en_oficial,             en_comentario,         en_retencion,
   en_fecha_mod,           p_fecha_expira,        en_sector,
   p_ciudad_nac,           p_nivel_estudio,       p_tipo_vivienda,
   en_calificacion,        en_tipo_vinculacion,   en_pais_nac,
   en_provincia_nac,       en_naturalizado,       en_forma_migratoria,
   en_nro_extranjero,      en_calle_orig,         en_exterior_orig,
   en_estado_orig
   from cl_ente
   where en_ente = @w_cod_persona

   if @@error <> 0 begin
      close enteCursor
      deallocate enteCursor

      select @w_error = 1720049
      goto ERROR
   end

   fetch next from enteCursor into @w_cod_persona
end

close enteCursor

--Actualizacion de calificacion cliente
update cl_ente 
set cl_ente.en_calificacion = calif_cliente_tmp.cc_calif
from   cl_ente, calif_cliente_tmp
where  cc_numero = en_ente

--DESPUES LOG
open enteCursor
fetch next from enteCursor into @w_cod_persona

while @@fetch_status = 0
begin

   --Registro despues del cambio
   insert into ts_persona_prin (
   secuencia,              tipo_transaccion,      clase,
   fecha,                  usuario,               terminal,
   srv,                    lsrv,                  persona,
   nombre,                 p_apellido,            s_apellido,
   sexo,                   cedula,                tipo_ced,
   pais,                   profesion,             estado_civil,
   actividad,              num_cargas,            nivel_ing,
   nivel_egr,              tipo,                  filial,
   oficina,                fecha_nac,             grupo,
   oficial,                comentario,            retencion,
   fecha_mod,              fecha_expira,          sector,
   ciudad_nac,             nivel_estudio,         tipo_vivienda,
   calif_cliente,          tipo_vinculacion,      pais_nac,
   provincia_nac,          naturalizado,          forma_migratoria,
   nro_extranjero,         calle_orig,            exterior_orig,
   estado_orig)
   select
   @s_ssn,                 @t_trn,                'D',
   getdate(),              @s_user,               @s_term,
   @s_srv,                 @s_srv,                @w_cod_persona,
   en_nombre,              p_p_apellido,          p_s_apellido,
   p_sexo,                 en_ced_ruc,            en_tipo_ced,
   en_pais,                p_ocupacion,           p_estado_civil,
   en_actividad,           p_num_cargas,          p_nivel_ing,
   p_nivel_egr,            en_subtipo,            en_filial,
   en_oficina,             p_fecha_nac,           en_grupo,
   en_oficial,             en_comentario,         en_retencion,
   en_fecha_mod,           p_fecha_expira,        en_sector,
   p_ciudad_nac,           p_nivel_estudio,       p_tipo_vivienda,
   en_calificacion,        en_tipo_vinculacion,   en_pais_nac,
   en_provincia_nac,       en_naturalizado,       en_forma_migratoria,
   en_nro_extranjero,      en_calle_orig,         en_exterior_orig,
   en_estado_orig
   from cl_ente
   where en_ente = @w_cod_persona

   if @@error <> 0 begin
      close enteCursor
      deallocate enteCursor

      select @w_error = 1720049
      goto ERROR
   end

   fetch next from enteCursor into @w_cod_persona
end

close enteCursor
deallocate enteCursor

/* CREACION DE ARCHIVO DE SALIDA */
--Configuracion archivo de salida

select @w_nombre_arch = concat(@i_param1,@i_param3)
select @w_sql = 'select cc_numero from cobis..calif_cliente_tmp where cc_numero not in (select en_ente from cobis..cl_ente)'

exec @w_return          = cobis..sp_bcp_archivos
     @i_sql             = @w_sql,           --select o nombre de tabla para generar archivo plano
     @i_tipo_bcp        = 'queryout',       --tipo de bcp in,out,queryout
     @i_rut_nom_arch    = @w_nombre_arch,   --ruta y nombre de archivo
     @i_separador       = @w_separador      --separador

if @w_return != 0
begin
   select @w_error   = 1720576
   goto ERROR
end

return 0

ERROR:
exec cobis..sp_cerror
@t_debug = 'N',
@t_file  = null,
@t_from  = @w_sp_name,
@i_num   = @w_error 

return @w_error

go
