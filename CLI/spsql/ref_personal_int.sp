/************************************************************************/
/*  Archivo:             ref_personal_int.sp                            */
/*  Stored procedure:    sp_referencias_personal_int                    */
/*  Base de datos:       cob_interface                                  */
/*  Producto:            Clientes                                       */
/*  Disenado por:        COB                                            */
/*  Fecha de escritura:  13-septiembre-21                               */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_referencias_personal_int                */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA           AUTOR           RAZON                               */
/*  13/09/21        COB          Emision Inicial                        */
/*  22/01/24        BDU          R224055-Validar oficina app            */
/************************************************************************/
use cob_interface
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects 
           where name = 'sp_referencias_personal_int')
   drop proc sp_referencias_personal_int 
go

create proc sp_referencias_personal_int
(
   @s_ssn                int,
   @s_sesn               int           = null,
   @s_user               login         = null,
   @s_term               varchar(32)   = null,
   @s_date               datetime,
   @s_srv                varchar(30)   = null,
   @s_lsrv               varchar(30)   = null,
   @s_ofi                smallint      = null,
   @s_rol                smallint      = null,
   @s_org_err            char(1)       = null,
   @s_error              int           = null,
   @s_sev                tinyint       = null,
   @s_msg                descripcion   = null,
   @s_org                char(1)       = null,
   @s_culture            varchar(10)   = 'NEUTRAL',
   @t_debug              char(1)       = 'n',
   @t_file               varchar(10)   = null,
   @t_from               varchar(32)   = null,
   @t_trn                int           = null,
   @t_show_version       bit           = 0,       -- versionamiento
   @i_ente               int           = null,
   @i_referencia         int           = null,
   @i_operacion          char(1),
   @i_nombre             varchar(60)   = null,
   @i_p_apellido         varchar(32)   = null,
   @i_s_apellido         varchar(20)   = null,
   @i_parentesco         catalogo      = null,
   @o_id                 int           = null  OUTPUT
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_relacion              int,
        @w_oficial               int,
        @w_estado_prospecto      char(1),
        @w_lado_relacion         char(1),
        @w_ente_c                int,
        @w_trn_dir               int,
        @w_error                 int,
        @w_operacion             char(1),
        @w_existente             bit,
        @w_catalogo_valor        varchar(30),
        @w_init_msg_error        varchar(256)

/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_referencias_personal_int',
@w_error            = 1720548

/* VALIDACIONES */

-- Obligatorios
-- cliente
if isnull(@i_ente,'') = '' and @i_ente <> 0
begin
   select @w_catalogo_valor = 'personSequential'
   goto VALIDAR_ERROR
end
if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
begin
   select @w_error = 1720104
   goto ERROR_FIN
end

if(@i_operacion = 'S')
begin
   select
      'NUMERO'                = rp_referencia,
      'NOMBRE'                = rp_nombre,
      'PRIMER_APELLIDO'       = rp_p_apellido,
      'SEGUNDO_APELLIDO'      = rp_s_apellido,
      'DIRECCION'             = substring(rp_direccion,1,32),
      'NEXO_CON_EL_CLIENTE'   = rp_parentesco,
      'TELEFONO_DOMICILIO'    = RTRIM(rp_telefono_d),
      'TELEFONO_EMPRESA'      = rp_telefono_e,
      'TELEFONO_OTRO'         = rp_telefono_o,
      'OBSERVACIONES'         = rp_descripcion,
      'FECHA_REGISTRO'        = (select format (rp_fecha_registro, 'dd/MM/yyyy HH:mm:ss') as date),
      'FECHA_ULT_MODIF'       = (select format (rp_fecha_modificacion, 'dd/MM/yyyy HH:mm:ss') as date),
      'VIGENTE'               = rp_vigencia,
      'VERIF.'                = rp_verificacion,
      'DEPARTAMENTO'          = rp_departamento,
      'CIUDAD'                = rp_ciudad,
      'BARRIO'                = rp_barrio,
      'OBS.VERIFICADO'        = rp_obs_verificado,
      'CALLE'                 = rp_calle,
      'NRO'                   = rp_nro,
      'COLONIA'               = rp_colonia,
      'LOCALIDAD'             = rp_localidad,
      'MUNICIPIO'             = rp_municipio,
      'CODESTADO'             = rp_estado,
      'CODPOSTAL'             = rp_codpostal,
      'CODPAIS'               = rp_pais,
      'TIEMPO_CONOCI'         = rp_tiempo_conocido,
      'CORREO'                = rp_direccion_e
    from   cobis..cl_ref_personal
    where  rp_persona = @i_ente

   if @@rowcount = 0
   begin
      select @w_error = 1720019
      goto ERROR_FIN
   end

   return 0
end

if @i_operacion in ('U','D')
begin
   --referencia
   if isnull(@i_referencia,'') = '' and @i_referencia <> 0
   begin
      select @w_catalogo_valor = 'refSequential'
      goto VALIDAR_ERROR
   end
   if not exists (select 1 from cobis..cl_ref_personal where rp_persona = @i_ente and rp_referencia = @i_referencia)
   begin
      select @w_error = 1720561
      goto ERROR_FIN
   end
end

if(@i_operacion = 'D')
begin
   exec @w_error = cobis..sp_refpersonal
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @s_user        = @s_user,
   @t_trn         = 172078,
   @i_operacion   = 'D',
   @i_ente        = @i_ente,
   @i_referencia  = @i_referencia
   
   if @w_error <> 0
   begin
      return @w_error
   end

   return 0
end

--nombre
if isnull(@i_nombre,'') = ''
begin
   select @w_catalogo_valor = 'name'
   goto VALIDAR_ERROR
end
else
   select @i_nombre = UPPER(@i_nombre)

--apellido
if isnull(@i_p_apellido,'') = ''
begin
   select @w_catalogo_valor = 'lastname'
   goto VALIDAR_ERROR
end
else
   select @i_p_apellido = UPPER(@i_p_apellido)

--parentesco
if isnull(@i_parentesco,'') = ''
begin
   select @w_catalogo_valor = 'relation'
   goto ERROR_FIN
end
exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_parentesco', @i_valor = @i_parentesco
if @w_error <> 0 and @w_error != 1720018
   goto ERROR_FIN
else if @w_error = 1720018 
begin 
   select @w_catalogo_valor = @i_parentesco
   select @w_error = 1720552
   goto VALIDAR_ERROR
end

--segundo apellido
if isnull(@i_s_apellido,'') <> ''
   select @i_s_apellido = UPPER(@i_s_apellido)

if(@i_operacion = 'I')
begin
   exec @w_error = cobis..sp_refpersonal
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @s_user        = @s_user,
   @t_trn         = 172076,
   @s_ofi         = @s_ofi,
   @i_operacion   = 'I',
   @i_ente        = @i_ente,
   @i_nombre      = @i_nombre,
   @i_p_apellido  = @i_p_apellido,
   @i_s_apellido  = @i_s_apellido,
   @i_parentesco  = @i_parentesco,
   @o_siguiente   = @o_id out

   if @w_error <> 0 or @o_id is null
   begin
      return @w_error
   end

end
else if(@i_operacion = 'U')
begin

   exec @w_error = cobis..sp_refpersonal
   @s_ssn         = @s_ssn,
   @s_date        = @s_date,
   @s_user        = @s_user,
   @s_ofi         = @s_ofi,
   @t_trn         = 172077,
   @i_operacion   = 'U',
   @i_ente        = @i_ente,
   @i_referencia  = @i_referencia,
   @i_nombre      = @i_nombre,
   @i_p_apellido  = @i_p_apellido,
   @i_s_apellido  = @i_s_apellido,
   @i_parentesco  = @i_parentesco

   if @w_error <> 0 or @o_id is null
   begin
      return @w_error
   end
end

return 0

VALIDAR_ERROR:
   select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_catalogo_valor, @w_error, @s_culture)
   goto ERROR_FIN

ERROR_FIN:
   select @w_sp_msg = UPPER(@w_sp_msg)

   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_msg   = @w_sp_msg,
        @i_num   = @w_error
       
return @w_error

go
