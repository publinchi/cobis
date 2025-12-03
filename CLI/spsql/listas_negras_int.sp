/************************************************************************/
/*   Archivo:            listas_negras_int.sp                           */
/*   Stored procedure:   sp_listas_negras_int                           */
/*   Base de datos:      cobis                                          */
/*   Producto:           Clientes                                       */
/*   Disenado por:       PJA                                            */
/*   Fecha de escritura: 28-Diciembre-21                                */
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
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_listas_negras_int                       */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      28/12/2021      PJA             Emision Inicial                 */
/************************************************************************/

use cob_interface
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_listas_negras_int')
   drop proc sp_listas_negras_int
go

create procedure sp_listas_negras_int (
        @s_ssn                           int          = null,
        @s_user                          login        = null,
        @s_term                          varchar(32)  = null,
        @s_sesn                          int          = null,
        @s_culture                       varchar(10)  = 'NEUTRAL',
        @s_date                          datetime     = null,
        @s_srv                           varchar(30)  = null,
        @s_lsrv                          varchar(30)  = null,
        @s_rol                           smallint     = NULL,
        @s_org_err                       char(1)      = NULL,
        @s_error                         int          = NULL,
        @s_sev                           tinyint      = NULL,
        @s_msg                           descripcion  = NULL,
        @s_org                           char(1)      = NULL,
        @s_ofi                           smallint     = NULL,
        @t_debug                         char(1)      = 'N',
        @t_file                          varchar(14)  = null,
        @t_from                          varchar(30)  = null,
        @t_trn                           int          = null,
        @t_show_version                  bit          = 0,     -- Mostrar la version del programa
        @i_operacion                     char(1)      = null,  -- Valor de la operacion a realizar
        @i_tipo                          char(1)      = null,  -- P o C
        @i_apellido                      varchar(255) = null,
        @i_nombre                        varchar(255) = null,
        @i_nombre_compania               varchar(255) = null,
        @i_nombre_usuario                varchar(255) = null,
        @i_porcentaje_precision          tinyint      = null,
        @i_pais                          varchar(3)   = null,
        @i_parametros_adicionales        varchar(255) = null,
        @i_ente                          int          = null,
        @i_tipo_iden                     varchar(24)  = null,
        @i_numero_iden                   varchar(30)  = null,
        @i_fecha_nacimiento              varchar(10)  = null,
        @i_transaccion_ref               varchar(51)  = null,
        @i_numero_coincidencia           int          = null,
        @i_nro_proceso                   int          = null,
        @i_aml                           varchar(10)  = null,
        @i_justificacion                 varchar(500) = null,
        @i_apellido_casada               varchar(255) = null,
        @o_id_transaccion                varchar(51)  = null out,
        @o_coincidencia                  int          = null out
        ) 
as 
declare
        @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_error                 int,        
        @w_valor_campo           varchar(30)
        
select @w_sp_name          = 'sp_listas_negras_int',
       @w_error            = 1720548 --Campos requeridos

if @t_trn <> 172222 
begin 
   /* Tipo de transaccion no corresponde */ 
   select @w_error = 1720275 
   goto ERROR_FIN
end

/*VALIDAR CODIGO CLIENTE*/
if isnull(@i_ente,'') = '' and @i_ente <> 0
begin
   select @w_valor_campo = 'personSequential'
   goto VALIDAR_ERROR  
end

/*VALIDAR QUE EXISTA EL CLIENTE*/
if not exists (select 1 from cobis..cl_ente where en_ente = @i_ente)
begin
   select @w_error = 1720079
   goto ERROR_FIN
end

/*CODIGO TRANSACCION LISTAS NEGRAS*/
select @t_trn =
case @i_operacion
when 'I' then 172219
end

if ( @i_operacion = 'I')
begin
   /*Verificacion de campos requeridos*/

    -- Tipo de Persona  
    if isnull(@i_tipo,'') = ''
    begin
        select @w_valor_campo  = 'personType'
        goto VALIDAR_ERROR
    end

    --Nombre de la Persona
    if isnull(@i_nombre,'') = ''
    begin
        select @w_valor_campo  = 'personName'
        goto VALIDAR_ERROR
    end
    
    -- Apellido Tipo P (PERSONA NATURAL)
    if (isnull(@i_tipo,'') = 'P')
    begin   
        if isnull(@i_apellido,'') = ''
        begin
            select @w_valor_campo  = 'lastName'
            goto VALIDAR_ERROR
        end
    end
    
    --Usuario que realizar la validacion
    if isnull(@i_nombre_usuario,'') = ''
    begin
        select @w_valor_campo  = 'userName'
        goto VALIDAR_ERROR
    end

    -- Tipo de identificacion
    if isnull(@i_tipo_iden,'') = ''
    begin
        select @w_valor_campo  = 'identificationType'
        goto VALIDAR_ERROR
    end
    
    --Numero de identificacion
    if isnull(@i_numero_iden,'') = ''
    begin
        select @w_valor_campo  = 'identificationNumber'
        goto VALIDAR_ERROR
    end

    --Fecha de nacimiento Tipo P (PERSONA NATURAL)
    if (isnull(@i_tipo,'') = 'P')
    begin   
        if isnull(@i_fecha_nacimiento,'') = ''
        begin
          select @w_valor_campo  = 'birthDate'
          goto VALIDAR_ERROR
        end 
    end

    --Identificador de la verificacion
    if isnull(@i_transaccion_ref,'') = ''
    begin
        select @w_valor_campo  = 'transaccionRef'
        goto VALIDAR_ERROR
    end

    --Numero de coincidencias
    if (isnull(@i_numero_coincidencia,'') = '' and @i_numero_coincidencia <> 0)
    begin
        select @w_valor_campo  = 'coincidenceNumber'
        goto VALIDAR_ERROR
    end 

   select @w_error = 0   
   /*Validaciones */
   /*1. Exista el tipo de persona*/
   exec @w_error = cobis..sp_validar_catalogo  
      @i_tabla = 'cl_tipo_persona', 
      @i_valor = @i_tipo
   
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catalogo
   begin 
      select @w_valor_campo = @i_tipo 
      select @w_error = 1720552 -- mensaje generico: 
      goto VALIDAR_ERROR 
   end
   
   /*2. Exista el tipo documento*/
   exec @w_error = cobis..sp_validar_catalogo  
        @i_tabla = 'cl_tipo_documento', 
        @i_valor = @i_tipo_iden
   
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catalogo
   begin 
      select @w_valor_campo = @i_tipo_iden 
      select @w_error = 1720552 -- mensaje generico: 
      goto VALIDAR_ERROR 
   end  
    
    /* PASO A MAYUSCULAS*/
    select @i_nombre = upper(@i_nombre)
    select @i_apellido = upper(@i_apellido)
    select @i_apellido_casada = upper(@i_apellido_casada)
    
      
   select @w_error = 0
   
   exec @w_error = cobis..sp_listas_negras
      @s_ssn                    = @s_ssn,
      @s_user                   = @s_user,
      @s_term                   = @s_term,
      @s_sesn                   = @s_sesn,
      @s_culture                = @s_culture,
      @s_date                   = @s_date,
      @s_srv                    = @s_srv,
      @s_lsrv                   = @s_lsrv,
      @s_rol                    = @s_rol,
      @s_org_err                = @s_org_err,
      @s_error                  = @s_error,
      @s_sev                    = @s_sev,
      @s_msg                    = @s_msg,
      @s_org                    = @s_org,
      @s_ofi                    = @s_ofi,
      @t_debug                  = @t_debug,
      @t_file                   = @t_file,
      @t_from                   = @t_from,
      @t_trn                    = @t_trn,
      @t_show_version           = @t_show_version,
      @i_operacion              = @i_operacion,
      @i_tipo                   = @i_tipo,
      @i_apellido               = @i_apellido,
      @i_nombre                 = @i_nombre,
      @i_nombre_compania        = @i_nombre_compania,
      @i_nombre_usuario         = @i_nombre_usuario,
      @i_porcentaje_precision   = @i_porcentaje_precision,
      @i_pais                   = @i_pais,
      @i_parametros_adicionales = @i_parametros_adicionales,
      @i_ente                   = @i_ente,
      @i_tipo_iden              = @i_tipo_iden,
      @i_numero_iden            = @i_numero_iden,
      @i_fecha_nacimiento       = @i_fecha_nacimiento,
      @i_transaccion_ref        = @i_transaccion_ref,
      @i_numero_coincidencia    = @i_numero_coincidencia,
      @i_nro_proceso            = @i_nro_proceso,
      @i_aml                    = @i_aml,
      @i_justificacion          = @i_justificacion,
      @i_apellido_casada        = @i_apellido_casada,
      @o_id_transaccion         = @o_id_transaccion out,
      @o_coincidencia           = @o_coincidencia out
    
   if @w_error <> 0 begin
      return @w_error
   end

end   --fin operacion I

return 0

VALIDAR_ERROR:

select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo, @w_error, @s_culture)
goto ERROR_FIN

ERROR_FIN:

exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
         @i_msg      = @w_sp_msg,
         @i_num      = @w_error
         
return @w_error

go
