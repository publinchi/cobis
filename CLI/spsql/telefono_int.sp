/********************************************************************/
/*    NOMBRE LOGICO:       sp_telefono_int                          */
/*    NOMBRE FISICO:       telefono_int.sp                          */
/*    PRODUCTO:            Clientes                                 */
/*    Disenado por:        COB                                      */
/*    Fecha de escritura:  30-Agosto-21                             */
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
/*   usadas en el servicio rest del sp_direccion_dml                */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*      FECHA           AUTOR           RAZON                       */
/*      30/08/21         COB       Emision Inicial                  */
/*      16/03/22         PJA       Se agrega operacion [D] y [Q]    */
/*      18/08/23         EBA       R-213344 validación teléfono     */
/*                                 fijo no obligatorio              */
/*      22/01/24         BDU       R224055-Validar oficina app      */
/********************************************************************/

use cob_interface
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_telefono_int')
   drop proc sp_telefono_int
go

create procedure sp_telefono_int (
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
       @t_show_version         bit           = 0,     -- versionamiento
       @i_ente                 int           = null,
       @i_direccion            int           = null,
       @i_secuencial           int           = null,
       @i_operacion            char(1)       = null,
       @i_valor                varchar(16)   = null,  -- Numero de telefono
       @i_tipo_telefono        char(2)       = null,  -- Tipo de telefono
       @i_cod_area             varchar(10)   = null, 
       @i_prefijo              varchar(10)   = null,
       @o_id                   int           = null out
 
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
        @w_init_msg_error        varchar(256),
        @w_catalogo_valor        varchar(30)


/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_telefono_int',
@w_operacion        = '',
@w_error            = 1720548

select @w_init_msg_error = convert(varchar,@w_error)+ ' - ' + re_valor                                                                                                                                                                           
   from   cobis..cl_errores inner join cobis..ad_error_i18n on (numero = pc_codigo_int                                                                                                                                                                                                                        
   and    re_cultura = UPPER(@s_culture))                                                                                                                                                                                                           
   where numero = @w_error 

/* VALIDACIONES */

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

if isnull(@i_direccion,'') = '' and @i_direccion <> 0
   begin
      select @w_catalogo_valor = 'addressId'
      goto VALIDAR_ERROR
   end
   if not exists (select 1 from cobis..cl_direccion where di_ente = @i_ente and di_direccion = @i_direccion)
   begin
      select @w_error = 1720115
      goto ERROR_FIN
   end

if @i_operacion in ('U','D')
begin
   if isnull(@i_secuencial,'') = '' and @i_secuencial <> 0
   begin
      select @w_catalogo_valor = 'phoneId'
      goto VALIDAR_ERROR
   end

   if not exists(select 1 from cobis..cl_telefono 
   where te_ente = @i_ente and te_direccion = @i_direccion and te_secuencial = @i_secuencial)
   begin
      select @w_error = 1720379
      goto ERROR_FIN
   end
end

if @i_operacion = 'Q'
begin
   if not exists(select 1 from cobis..cl_telefono 
   where te_ente = @i_ente and te_direccion = @i_direccion)
   begin
      select @w_error = 1720379
      goto ERROR_FIN
   end
end


if @i_operacion in ('I','U') 
begin
   if isnull(@i_tipo_telefono,'') = ''
   begin
      select @w_catalogo_valor = 'phoneType'
      goto VALIDAR_ERROR
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_ttelefono', @i_valor = @i_tipo_telefono          
   if @w_error <> 0 and @w_error != 1720018
      goto ERROR_FIN
   else if @w_error = 1720018 
   begin 
      select @w_catalogo_valor = @i_tipo_telefono
      select @w_error = 1720552
      goto VALIDAR_ERROR
   end

   if isnull(@i_prefijo,'') = ''
   begin
      select @w_catalogo_valor = 'prefix'
      goto VALIDAR_ERROR
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_area_pais', @i_valor = @i_prefijo          
   if @w_error <> 0 and @w_error != 1720018
      goto ERROR_FIN
   else if @w_error = 1720018 
   begin 
      select @w_catalogo_valor = @i_prefijo
      select @w_error = 1720552
      goto VALIDAR_ERROR
   end
end

/* FIN CAMPOS REQUERIDOS */

if(@i_operacion = 'I')
begin
   if @i_valor is not null and @i_valor <> ''
   begin
      exec @w_error = cobis..sp_telefono
      @s_ssn           = @s_ssn,
      @s_date          = @s_date,
      @s_user          = @s_user,
      @s_ofi           = @s_ofi,
      @t_trn           = 172031,
      @i_operacion     = 'I',
      @i_ente          = @i_ente,
      @i_direccion     = @i_direccion,
      @i_valor         = @i_valor,
      @i_tipo_telefono = @i_tipo_telefono,
      @i_cod_area      = @i_cod_area,
      @i_prefijo       = @i_prefijo,
      @o_siguiente     = @o_id out
      
      if @w_error <> 0
      begin
         goto ERROR_FIN 
      end
   end
end
else if (@i_operacion = 'U')
begin
   if @i_valor is not null and @i_valor <> ''
   begin
      exec @w_error = cobis..sp_telefono
      @s_ssn           = @s_ssn,
      @s_date          = @s_date,
      @s_user          = @s_user,
      @s_ofi           = @s_ofi,
      @t_trn           = 172032,
      @i_operacion     = 'U',
      @i_ente          = @i_ente,
      @i_direccion     = @i_direccion,
      @i_secuencial    = @i_secuencial,
      @i_valor         = @i_valor,
      @i_tipo_telefono = @i_tipo_telefono,
      @i_cod_area      = @i_cod_area,
      @i_prefijo       = @i_prefijo
      
      if @w_error <> 0
      begin
         goto ERROR_FIN 
      end
   end
end
else if (@i_operacion = 'Q')
begin
   exec @w_error = cobis..sp_telefono
   @s_ssn           = @s_ssn,
   @s_date          = @s_date,
   @s_user          = @s_user,
   @s_ofi           = @s_ofi,
   @t_trn           = 172033,
   @i_operacion     = 'Q',
   @i_ente          = @i_ente,
   @i_direccion     = @i_direccion,
   @i_secuencial    = @i_secuencial,
   @i_valor         = @i_valor,
   @i_tipo_telefono = @i_tipo_telefono,
   @i_cod_area      = @i_cod_area,
   @i_prefijo       = @i_prefijo

   if @w_error <> 0
   begin
      goto ERROR_FIN 
   end
end
else if (@i_operacion = 'D')
begin
   exec @w_error = cobis..sp_telefono
   @s_ssn           = @s_ssn,
   @s_date          = @s_date,
   @s_user          = @s_user,
   @s_ofi           = @s_ofi,
   @t_trn           = 172034,
   @i_operacion     = 'D',
   @i_ente          = @i_ente,
   @i_direccion     = @i_direccion,
   @i_secuencial    = @i_secuencial,
   @i_valor         = @i_valor,
   @i_tipo_telefono = @i_tipo_telefono,
   @i_cod_area      = @i_cod_area,
   @i_prefijo       = @i_prefijo

   if @w_error <> 0
   begin
      goto ERROR_FIN 
   end
end

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