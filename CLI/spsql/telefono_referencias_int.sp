/************************************************************************/
/*  Archivo:                         telefono_referencias_int.sp        */
/*  Stored procedure:                sp_telefono_referencias_int        */
/*  Base de datos:                   cobis                              */
/*  Producto:                        Clientes                           */
/*  Disenado por:                    ACA                                */
/*  Fecha de escritura:              20-09-2021                         */
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
/*                          PROPOSITO                                   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      20/09/21        ACA           Emision Inicial                   */
/************************************************************************/
use cob_interface
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_telefono_referencias_int')
   drop proc sp_telefono_referencias_int
go
CREATE PROCEDURE sp_telefono_referencias_int (
        @s_ssn                  int         = null,
        @s_user                 login       = null,
        @s_term                 varchar(32) = null,
        @s_sesn                 int         = null,
        @s_culture              varchar(10) = 'NEUTRAL',
        @s_date                 datetime    = null,
        @s_srv                  varchar(30) = null,
        @s_lsrv                 varchar(30) = null,
        @s_rol                  smallint    = NULL,
        @s_org_err              char(1)     = NULL,
        @s_error                int         = NULL,
        @s_sev                  tinyint     = NULL,
        @s_msg                  descripcion = NULL,
        @s_org                  char(1)     = NULL,
        @s_ofi                  smallint    = NULL,
        @t_debug                char(1)     = 'N',
        @t_file                 varchar(14) = null,
        @t_from                 varchar(30) = null,
        @t_trn                  int         = null,
        @t_show_version         bit         = 0,     -- Mostrar la version del programa
        @i_operacion            char        = null,  -- Valor de la operacion a realizar
        @i_ente                 int         = NULL,  -- Código del cliente
        @i_referencia           char(1)     = NULL,  -- Tipo de Referencia (L,P)
        @i_tipo_telefono        char(1)     = NULL,  -- Tipo de teléfono (C,D)
        @i_pais                 varchar(10) = NULL,  -- Prefijo del país
        @i_area                 varchar(10) = NULL,  -- Área del País
        @i_numero_tel           varchar(16) = NULL,  -- Número de teléfono
        @i_secuencial           tinyint     = NULL,  -- secuencial del registro
        @i_sec_ref              tinyint     = NULL,  -- secuencial de la Referencia
		@o_secuencial           tinyint     = NULL output  -- secuencial de salida
		)
as
declare 
        @w_sp_name          varchar(32),
        @w_return           int,
        @w_cp               smallint, --Parámetro código de país
        @w_respuesta        tinyint,   --Respuesta para función valida teléfono
        @w_longitud         tinyint,  --longitud de la cadena valor de teléfono
        @w_valida_long      tinyint,  --Valor de Parámetro de validación de longitud
		@w_error            int,
        @w_secuencial       smallint,
		@w_valor_campo      varchar(30),
		@w_sp_msg           varchar(132)
		
select @w_sp_name = 'sp_telefono_referencias_int',
       @w_error   = 1720548 --Campos requeridos
	  
if isnull(@i_ente,'') = '' and @i_ente <> 0
begin
   select @w_valor_campo = 'personSequential'
   goto VALIDAR_ERROR  
end

if isnull(@i_referencia,'') = ''
begin
   select @w_valor_campo = 'referenceType'
   goto VALIDAR_ERROR  
end    

if isnull(@i_sec_ref,'') = '' and @i_sec_ref <> 0
begin
   select @w_valor_campo = 'referenceSequential'
   goto VALIDAR_ERROR  
end

if @i_referencia not in ('L','P')
begin
   select @w_error = 1720558
   goto ERROR_FIN
end

if @i_referencia = 'P'
begin
   if not exists (select 1 from cobis..cl_ref_personal where rp_persona = @i_ente and rp_referencia = @i_sec_ref)
   begin
      select @w_error = 1720561
      goto ERROR_FIN
   end
end--Fin
else if (@i_referencia = 'L')
begin
   if not exists (select 1 from cobis..cl_trabajo where tr_persona = @i_ente and tr_trabajo = @i_sec_ref)
   begin
      select @w_error = 1720570
      goto ERROR_FIN
   end
end
	
select @t_trn = 172197

if @i_operacion in ('I','U') begin
   
   if isnull(@i_pais,'') = ''
   begin
      select @w_valor_campo = 'prefix'
      goto VALIDAR_ERROR  
   end
   
   if isnull(@i_tipo_telefono,'') = ''
   begin
      select @w_valor_campo = 'phoneType'
      goto VALIDAR_ERROR  
   end
   
   if isnull(@i_numero_tel,'') = ''
   begin
      select @w_valor_campo = 'phoneNumber'
      goto VALIDAR_ERROR  
   end
   
   if @i_operacion = 'U' and isnull(@i_secuencial,'') = '' and @i_secuencial <> 0
   begin
      select @w_valor_campo = 'phoneId'
      goto VALIDAR_ERROR  
   end
   
   select @w_error = 0
   
   /*Validaciones */
   /*1. Exista el tipo de telefono*/
   exec @w_error = cobis..sp_validar_catalogo  
      @i_tabla = 'cl_ttelefono', 
      @i_valor = @i_tipo_telefono
   
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
   begin 
	  select @w_valor_campo = @i_tipo_telefono 
	  select @w_error = 1720552 -- mensaje genérico: 
	  goto VALIDAR_ERROR 
   end
       
   /*2. Exista el prefijo de telefono*/
   exec @w_error = cobis..sp_validar_catalogo  
        @i_tabla = 'cl_area_pais', 
        @i_valor = @i_pais
   
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
   begin 
	  select @w_valor_campo = @i_pais 
	  select @w_error = 1720552 -- mensaje genérico: 
	  goto VALIDAR_ERROR 
   end

   select @w_error = 0
   
   exec @w_error = cobis..sp_ref_telefono
      @s_ssn            = @s_ssn,          
      @s_user           = @s_user,         
      @s_term           = @s_term,        
      @s_sesn           = @s_sesn,         
      @s_culture        = @s_culture,
      @s_date           = @s_date,     
      @s_srv            = @s_srv,
      @s_lsrv           = @s_lsrv,
      @s_rol            = @s_rol,
      @s_org_err        = @s_org_err,
      @s_error          = @s_error,
      @s_sev            = @s_sev,
      @s_msg            = @s_msg,
      @s_org            = @s_org,
      @s_ofi            = @s_ofi,
      @t_debug          = @t_debug,
      @t_file           = @t_file,
      @t_from           = @t_from,
      @t_trn            = @t_trn,
      @t_show_version   = @t_show_version,
      @i_operacion      = @i_operacion,
      @i_ente           = @i_ente,
      @i_referencia     = @i_referencia,
      @i_tipo_telefono  = @i_tipo_telefono,
      @i_pais           = @i_pais,
      @i_area           = @i_area,
      @i_numero_tel     = @i_numero_tel,
      @i_secuencial     = @i_secuencial,
      @i_sec_ref        = @i_sec_ref,
      @o_secuencial     = @o_secuencial	out
	  
   if @w_error <> 0 begin
      return @w_error
   end

end--Fin validaciones
	
if @i_operacion in ('Q','D') --Consulta
begin
   
   if @i_operacion = 'D' and isnull(@i_secuencial,'') = '' and @i_secuencial <> 0
   begin
      select @w_valor_campo = 'phoneId'
      goto VALIDAR_ERROR  
   end

   if not exists (select 1
   from cobis..cl_ref_telefono
   where rt_ente         = @i_ente
   and   rt_referencia   = @i_referencia
   and   rt_sec_ref      = @i_sec_ref) and @i_operacion = 'Q'
   begin
      select @w_error = 1720019
	  goto ERROR_FIN
   end
   
   select @w_error = 0
   
   exec @w_error = cobis..sp_ref_telefono
      @s_ssn            = @s_ssn,          
      @s_user           = @s_user,         
      @s_term           = @s_term,        
      @s_sesn           = @s_sesn,         
      @s_culture        = @s_culture,
      @s_date           = @s_date,     
      @s_srv            = @s_srv,
      @s_lsrv           = @s_lsrv,
      @s_rol            = @s_rol,
      @s_org_err        = @s_org_err,
      @s_error          = @s_error,
      @s_sev            = @s_sev,
      @s_msg            = @s_msg,
      @s_org            = @s_org,
      @s_ofi            = @s_ofi,
      @t_debug          = @t_debug,
      @t_file           = @t_file,
      @t_from           = @t_from,
      @t_trn            = @t_trn,
      @t_show_version   = @t_show_version,
      @i_operacion      = @i_operacion,
      @i_ente           = @i_ente,
      @i_referencia     = @i_referencia,
      @i_secuencial     = @i_secuencial,
      @i_sec_ref        = @i_sec_ref
	  
   if @w_error <> 0 begin
	  return @w_error
   end
   
end --Fin consulta

return 0

VALIDAR_ERROR:

select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo, @w_error, @s_culture)
goto ERROR_FIN

ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
	@i_msg		= @w_sp_msg,
    @i_num      = @w_error
return @w_error

go
