/********************************************************************/
/*    NOMBRE LOGICO: sp_direccion_dml_int                           */
/*    NOMBRE FISICO: direccion_dml_int.sp                           */
/*    PRODUCTO: CLIENTES                                            */
/*    Disenado por: cobis|topaz                                     */
/*    Fecha de escritura: 30-agosto-21                              */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                           PROPOSITO                              */
/*   Este programa es un sp cascara para manejo de validaciones     */
/*   usadas en el servicio rest del sp_direccion_dml.               */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*  FECHA           AUTOR           RAZON                           */
/*  30/08/21         COB       Emision Inicial                      */
/*  29/09/21         ACA       Agrega consulta y eliminación        */
/*  18/04/22         PQU       Se comenta validacion localidad      */
/*  28/03/22         PJA       Se modifica validacion actualizacion */
/*  11/03/23         EBA       Se quita validacion de domicilio     */
/*  15/03/23         EBA       Se envia codigo postal               */
/*  11/04/23         OGU       Se remueve validación de             */
/*                             geolocalizacion diferente a CERO     */ 
/*  22/01/24         BDU       R224055-Validar oficina app          */
/*  04/07/24         BDU       R238621-Validar valores georeferencia*/
/********************************************************************/


use cob_interface
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_direccion_dml_int')
   drop proc sp_direccion_dml_int
go

create procedure sp_direccion_dml_int (
       @s_ssn                  int,
       @s_sesn                 int           = null,
       @s_user                 login         = null,
       @s_term                 varchar(32)   = null,
       @s_date                 datetime,
       @s_srv                  varchar(30)   = null,
       @s_lsrv                 varchar(30)   = null,
       @s_ofi                  smallint      = null,
       @s_rol                  smallint      = null,
       @s_org_err              char(1)       = null,
       @s_error                int           = null,
       @s_sev                  tinyint       = null,
       @s_msg                  descripcion   = null,
       @s_org                  char(1)       = null,
       @s_culture              varchar(10)   = 'NEUTRAL',
       @t_debug                char(1)       = 'n',
       @t_file                 varchar(10)   = null,
       @t_from                 varchar(32)   = null,
       @t_trn                  int           = null,
       @t_show_version         bit           = 0,       -- versionamiento
       @i_ente                 int           = null,
       @i_direccion            int           = null,
       @i_descripcion          varchar(254)  = null,    -- Descripcion de la direccion   
       @i_tipo                 catalogo      = null,    -- Tipo de direccion
       @i_operacion            char(1)       = null,
       @i_sector               catalogo      = null,    -- En el caso de direccion extranjera, se almacena el pais
       @i_parroquia            int           = null,    -- Codigo de la parroquia de la direccion
       @i_zona                 catalogo      = null,    -- Codigo de la zona postal
       @i_ciudad               int           = null,    -- Codigo del municipio / ito de int a smallint
       @i_principal            char(1)       = 'N',     -- Indicador si la direccion es principal
       @i_provincia            int           = null,    -- Codigo del departamento
       @i_codpostal            char(5)       = null,    -- Codigo Postal
       @i_calle                varchar(70)   = null,    -- Indica la Calle
       @i_tiempo_reside        int           = null,    -- Tiempo de residencia
       @i_pais                 smallint      = null,    -- Codigo pais
       @i_tipo_prop            char(10)      = null,    -- Tipo de vivienda
       @i_nro                  varchar(40)   = NULL,    -- numero de la calle
       @i_nro_residentes       int           = NULL,    -- Numero de residentes en el domicilio
       @i_localidad            varchar(30)   = null,    -- Codigo de localidad
       @i_piso                 varchar(40)   = null,    -- Numero o nombre de piso
       @i_conjunto             varchar(40)   = null,    -- Numero o nombre del conjunto
       @i_numero_casa          varchar(40)   = null,    -- Numero o nombre de casa
       @i_latitud              float         = null,    -- Numero de latitud
       @i_longitud             float         = null,    -- Numero de longitud
       @i_origen               char(1)       = 'O',   -- origen para consulta
       @o_dire                 int           = null out --Numero de la direccion

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
@w_sp_name          = 'cob_interface..sp_direccion_dml_int',
@w_operacion        = '',
@w_error            = 1720548


if (@i_operacion in ('I','U'))
begin
/* VALIDACIONES */

-- Obligatorios
-- cliente
   if isnull(@i_ente,'') = '' and @i_ente <> 0
   begin
      select @w_catalogo_valor = 'personSecuential',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720104
      goto ERROR_FIN
   end
   
   --descripcion de direccion
   if isnull(@i_descripcion,'') = ''
   begin
      select @w_catalogo_valor = 'addressDescription',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
      
   --es direccion principal
   if isnull(@i_principal,'') = ''
   begin
      select @w_catalogo_valor = 'isMainAddress',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   
   if (@i_principal not in ('S', 'N'))
   begin
      select @w_catalogo_valor = @i_principal 
      select @w_error = 1720552 -- mensaje genérico: No existe en el catálogo un valor asociado a...
      goto VALIDAR_ERROR
   end
   
   --tipo de direccion
   if isnull(@i_tipo,'') = ''
   begin
      select @w_catalogo_valor = 'addressType',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   if not exists(
      select 1 from cobis..cl_tabla t, cobis..cl_catalogo c 
      where t.tabla = 'cl_tdireccion' 
      and c.tabla = t.codigo 
      and c.codigo <> 'DE'
      and c.codigo = @i_tipo
   )
   begin 
      select @w_catalogo_valor = @i_tipo
      select @w_error = 1720552
      goto VALIDAR_ERROR
   end
   
   if(@i_operacion = 'U')
   begin
      -- direccion
      if isnull(@i_direccion,'') = '' and @i_direccion <> 0
      begin
         select @w_catalogo_valor = 'addressId',
             @w_error            = 1720548
         goto VALIDAR_ERROR
      end
   end
   
   --SI ES CORREO ELECTRONICO
   if(@i_tipo = (select pa_char from cobis..cl_parametro where pa_nemonico = 'TDW' and pa_producto = 'CLI'))
   begin
      if(@i_operacion = 'I')
      begin
         exec @w_error = cobis..sp_direccion_dml
         @s_ssn              = @s_ssn,
         @s_date             = @s_date,
         @s_user             = @s_user,
         @s_ofi              = @s_ofi,
         @t_trn              = 172016,
         @i_operacion        = 'I',
         @i_ente             = @i_ente,
         @i_descripcion      = @i_descripcion,
         @i_tipo             = @i_tipo,
         @o_dire             = @o_dire out
      end
      else if(@i_operacion = 'U')
      begin
         
         if not exists (select 1 from cobis..cl_direccion where di_ente = @i_ente and di_direccion = @i_direccion and di_tipo = @i_tipo)
         begin
            select @w_error = 1720115
            goto ERROR_FIN
         end
   
         exec @w_error = cobis..sp_direccion_dml
         @s_ssn              = @s_ssn,
         @s_date             = @s_date,
         @s_user             = @s_user,
         @s_ofi              = @s_ofi,
         @t_trn              = 172019,
         @i_operacion        = 'U',
         @i_ente             = @i_ente,
         @i_direccion        = @i_direccion,
         @i_descripcion      = @i_descripcion,
         @i_tipo             = @i_tipo
   
         if @w_error <> 0 or @o_dire is null
         begin
            return @w_error
         end
   
         return 0
      end
   
      if @w_error <> 0 or @o_dire is null
      begin
         return @w_error
      end
   
      return 0
   end
   
   select @i_descripcion = UPPER(@i_descripcion)
   
   if isnull(@i_pais,'') = '' and @i_pais <> 0 
   begin
      select @w_catalogo_valor = 'countryCode',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   if not exists(select 1 from cobis..cl_pais where pa_pais = @i_pais)
   begin
      select @w_error = 1720110
      goto ERROR_FIN
   end
   
   if isnull(@i_provincia,'') = ''
   begin
      select @w_catalogo_valor = 'provinceCode',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   if not exists(select 1 from cobis..cl_provincia 
                 where pv_provincia = @i_provincia
                 and   pv_pais      = @i_pais)
   begin
      select @w_error = 1720110
      goto ERROR_FIN
   end
   
   if isnull(@i_ciudad,'') = '' and @i_ciudad <> 0
   begin
      select @w_catalogo_valor = 'cantonCode',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   if not exists(select 1 from cobis..cl_ciudad 
                 where ci_ciudad    = @i_ciudad
                 and   ci_provincia = @i_provincia)
   begin
      select @w_error = 1720028
      goto ERROR_FIN
   end
   
   if isnull(@i_parroquia,'') = ''
   begin
      select @w_catalogo_valor = 'parishCode',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   if not exists(select 1 from cobis..cl_parroquia
                 where pq_parroquia = @i_parroquia
                 and   pq_ciudad    = @i_ciudad)
   begin
      select @w_error = 1720312
      goto ERROR_FIN
   end
   
   --barrio
   /*
   --PQU se comenta la validacion de la localidad
   if isnull(@i_localidad,'') = ''
   begin
      select @w_catalogo_valor = 'locations',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   if not exists(select 1 from cobis..cl_localidad
                 where  lo_localidad   = @i_localidad)
   begin
      select @w_error = 1720552
      select @w_catalogo_valor = @i_localidad
   
      goto VALIDAR_ERROR
   end
   */
   
   if isnull(@i_zona,'') = ''
   begin
      select @w_catalogo_valor = 'zone',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_zona', @i_valor = @i_zona          
   if @w_error <> 0 and @w_error != 1720018
      goto ERROR_FIN
   else if @w_error = 1720018 
   begin 
      select @w_catalogo_valor = @i_zona
      select @w_error = 1720552
      goto VALIDAR_ERROR
   end
   
   if isnull(@i_calle,'') = ''
   begin
      select @w_catalogo_valor = 'street',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   else
      select @i_calle = UPPER(@i_calle)
   
   if isnull(@i_nro,'') = ''
   begin
      select @w_catalogo_valor = 'addressNumber',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   else
      select @i_nro = UPPER(@i_nro)
   
   if (@i_latitud is null or @i_longitud is null) and @i_operacion != 'U'
   begin
      select @w_catalogo_valor = 'latitude or longitude',
             @w_error            = 1720548
      goto VALIDAR_ERROR
   end
   
   --opcionales
   
   if not isnull(@i_sector, '') = ''
   begin
      exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_sector', @i_valor = @i_sector          
      if @w_error <> 0 and @w_error != 1720018
         goto ERROR_FIN
      else if @w_error = 1720018 
      begin 
         select @w_catalogo_valor = @i_sector
         select @w_error = 1720552
         goto VALIDAR_ERROR
      end
   
   end
   
   if not isnull(@i_codpostal, '') = ''
   begin
      if not exists(select 1 from cobis..cl_codigo_postal 
                    where cp_codigo = @i_codpostal
                    and cp_pais = @i_pais)
      begin
         select @w_error = 1720277
         select @w_catalogo_valor = @i_codpostal
      
         goto ERROR_FIN
      end
   
   end
end

/* FIN CAMPOS REQUERIDOS */

if(@i_operacion = 'I')
begin
   exec @w_error = cobis..sp_direccion_dml
   @s_ssn              = @s_ssn,
   @s_date             = @s_date,
   @s_user             = @s_user,
   @s_ofi              = @s_ofi,
   @t_trn              = 172016,
   @i_operacion        = 'I',
   @i_correspondencia  = 'N',
   @i_ente             = @i_ente,
   @i_descripcion      = @i_descripcion,
   @i_tipo             = @i_tipo,
   @i_sector           = @i_sector,
   @i_parroquia        = @i_parroquia,
   @i_zona             = @i_zona,
   @i_ciudad           = @i_ciudad,
   @i_principal        = @i_principal,
   @i_provincia        = @i_provincia,
   @i_calle            = @i_calle,
   @i_tiempo_reside    = @i_tiempo_reside,
   @i_pais             = @i_pais,
   @i_tipo_prop        = @i_tipo_prop,
   @i_nro              = @i_nro,
   @i_nro_residentes   = @i_nro_residentes,
   --@i_localidad        = @i_localidad, --PQU no enviar localidad 
   @i_piso             = @i_piso,
   @i_conjunto         = @i_conjunto,
   @i_numero_casa      = @i_numero_casa,
   @i_codpostal        = @i_codpostal,
   @o_dire             = @o_dire out
   
   if @w_error <> 0 or @o_dire is null
   begin
      return @w_error
   end

   exec @w_error = cobis..sp_direccion_geo
   @s_ssn              = @s_ssn,
   @s_date             = @s_date,
   @s_user             = @s_user,
   @i_operacion        = 'I',
   @t_trn              = 172047,
   @i_ente             = @i_ente,
   @i_direccion        = @o_dire,
   @i_lat_segundos     = @i_latitud,
   @i_lon_segundos     = @i_longitud

   if @w_error <> 0 or @o_dire is null
   begin
      return @w_error
   end
end
else if (@i_operacion = 'U')
begin

   if not exists (select 1 from cobis..cl_direccion where di_ente = @i_ente and di_direccion = @i_direccion and di_tipo = @i_tipo)
   begin
      select @w_error = 1720115
      goto ERROR_FIN
   end

   exec @w_error = cobis..sp_direccion_dml
   @s_ssn              = @s_ssn,
   @s_date             = @s_date,
   @s_user             = @s_user,
   @s_ofi              = @s_ofi,
   @t_trn              = 172019,
   @i_operacion        = 'U',
   @i_correspondencia  = 'N',
   @i_direccion        = @i_direccion,
   @i_ente             = @i_ente,
   @i_descripcion      = @i_descripcion,
   @i_tipo             = @i_tipo,
   @i_sector           = @i_sector,
   @i_parroquia        = @i_parroquia,
   @i_zona             = @i_zona,
   @i_ciudad           = @i_ciudad,
   @i_principal        = @i_principal,
   @i_provincia        = @i_provincia,
   @i_calle            = @i_calle,
   @i_tiempo_reside    = @i_tiempo_reside,
   @i_pais             = @i_pais,
   @i_tipo_prop        = @i_tipo_prop,
   @i_nro              = @i_nro,
   @i_nro_residentes   = @i_nro_residentes,
   --@i_localidad        = @i_localidad, --PQU no enviar localidad 
   @i_piso             = @i_piso,
   @i_conjunto         = @i_conjunto,
   @i_codpostal        = @i_codpostal,
   @i_numero_casa      = @i_numero_casa
   
   if @w_error <> 0
   begin
      return @w_error
   end
   if @i_latitud is not null or @i_longitud is not null
   begin
      exec @w_error = cobis..sp_direccion_geo
      @s_ssn              = @s_ssn,
      @s_date             = @s_date,
      @s_user             = @s_user,
      @i_operacion        = 'I',
      @t_trn              = 172047,
      @i_ente             = @i_ente,
      @i_direccion        = @i_direccion,
      @i_lat_segundos     = @i_latitud,
      @i_lon_segundos     = @i_longitud
      
      if @w_error <> 0
      begin
         return @w_error
      end
   end
end
   
if (@i_operacion = 'S')
begin
   --Codigo del cliente obligatorio
   if isnull(@i_ente,'') = '' and @i_ente <> 0
   begin
      select @w_catalogo_valor = 'personSecuential',
             @w_error          = 1720548
      goto VALIDAR_ERROR
   end

   /*VALIDAR QUE EXISTA EL CLIENTE*/
   if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720079
      goto ERROR_FIN
   end

   if not exists (select 1 from cobis..cl_direccion where di_ente = @i_ente)
   begin
      select @w_error = 1720227
      goto ERROR_FIN
   end
   
   select @t_trn = 172012,
   @w_error = 0
   
   exec @w_error = cobis..sp_direccion_cons
    @s_ssn            = @s_ssn,
    @s_user           = @s_user,
    @s_term           = @s_term,
    @s_date           = @s_date,
    @s_srv            = @s_srv,
    @s_lsrv           = @s_lsrv,
    @s_ofi            = @s_ofi,
    @s_rol            = @s_rol,
    @s_org_err        = @s_org_err,
    @s_error          = @s_error,
    @s_sev            = @s_sev, 
    @s_msg            = @s_msg,
    @s_org            = @s_org,
    @t_debug          = @t_debug,
    @t_file           = @t_file,
    @t_from           = @t_from,
    @t_trn            = @t_trn,
    @t_show_version   = @t_show_version,
    @i_operacion      = @i_operacion,
    @i_ente           = @i_ente,
    @i_tipo           = @i_tipo, 
    @i_origen         = @i_origen
    
   if @w_error <> 0
   begin
      return @w_error
   end
   
end -- fin operacion consulta  
   
if (@i_operacion = 'D')
begin
   --Codigo del cliente obligatorio
   if isnull(@i_ente,'') = '' and @i_ente <> 0
   begin
      select @w_catalogo_valor = 'personSecuential',
             @w_error          = 1720548
      goto VALIDAR_ERROR
   end

   if isnull(@i_direccion,'') = '' and @i_direccion <> 0
   begin
      select @w_catalogo_valor = 'addressId',
             @w_error          = 1720548
      goto VALIDAR_ERROR
   end

   /*VALIDAR QUE EXISTA EL CLIENTE*/
   if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720079
      goto ERROR_FIN
   end
   
   select @t_trn = 172021,
   @w_error = 0
   
   exec @w_error = cobis..sp_direccion_dml
   @s_ssn              = @s_ssn,
   @s_date             = @s_date,
   @s_user             = @s_user,
   @t_trn              = @t_trn,
   @i_operacion        = 'D',
   @i_ente             = @i_ente,
   @i_direccion        = @i_direccion
    
   if @w_error <> 0
   begin
      return @w_error
   end
   
end -- Fin eliminacion

return 0

VALIDAR_ERROR:
   select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_catalogo_valor, @w_error, @s_culture)
   goto ERROR_FIN

ERROR_FIN:

select @w_sp_msg = UPPER(@w_sp_msg)

exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_msg      = @w_sp_msg,
         @i_num      = @w_error
       
return @w_error

go
