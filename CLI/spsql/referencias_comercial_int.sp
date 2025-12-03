/************************************************************************/
/*   Archivo:            referencias_comercial_int.sp                   */
/*   Stored procedure:   sp_referencias_comercial_int                   */
/*   Base de datos:      cobis                                          */
/*   Producto:           Clientes                                       */
/*   Disenado por:       ACA                                            */
/*   Fecha de escritura: 13-Septiembre-21                               */
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
/*   en el servicio rest del sp_referencias_comercial_int               */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      13/09/21         ACA       Emision Inicial                      */
/************************************************************************/

use cob_interface
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_referencias_comercial_int')
   drop proc sp_referencias_comercial_int
go

create procedure sp_referencias_comercial_int (
        @s_ssn                  int             = null,
        @s_user                 login           = null,
        @s_term                 varchar(30)     = null,
        @s_date                 datetime        = null,
        @s_srv                  varchar(30)     = null,
        @s_lsrv                 varchar(30)     = null,
        @s_ofi                  smallint        = null,
        @s_rol                  smallint        = NULL,
		  @s_culture              varchar(10)     = 'NEUTRAL',
        @s_org_err              char(1)         = NULL,
        @s_error                int             = NULL,
        @s_sev                  tinyint         = NULL,
        @s_msg                  descripcion     = NULL,
        @s_org                  char(1)         = NULL,
        @t_debug                char(1)         = 'N',
        @t_file                 varchar(10)     = null,
        @t_from                 varchar(32)     = null,
        @t_trn                  int             = null,
        @i_operacion            char(1),
        @i_ente                 int             = null,
        @i_referencia           tinyint         = null,
        @i_institucion          descripcion     = null,
        @i_fecha_ingr_en_inst   datetime        = null,
        @i_tipo_cifras          char(2)         = null,
        @i_numero_cifras        tinyint         = null,
        @i_calificacion         catalogo        = null,
        @i_observacion          varchar(254)    = null,
        @i_verificacion         char(1)         = 'S',
        @i_fecha_ver            datetime        = null,
		  @o_secuencial           tinyint         = null   output
) as declare
        @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_mask                  varchar(20),
        @w_oficial               int,
        @w_operacion             char(1),
        @w_error                 int,
        @w_tipo_cliente          char(1),
        @w_valor_campo           varchar(30),
        @w_lista_obs             varchar(155),
        @w_lista_ins             varchar(155),
		@w_caracter              varchar(3),
		@w_long_obs              tinyint
		
select @w_sp_name          = 'cob_interface..sp_referencias_comercial_int',
       @w_operacion        = '',
       @w_error            = 1720548,--Campos requeridos
       @w_tipo_cliente     = null,
	    @w_lista_obs        = '0-9\a-zA-Z\Á\á\é\í\ó\ú\É\Í\Ó\Ú\Ñ\ñ\,\.\)\_\'+char(39)+'\---\"\&\#\!\¡\(\)\¿\?\ ',
       @w_lista_ins        = 'a-zA-Z\Á\á\é\í\ó\ú\É\Í\Ó\Ú\Ñ\ñ\,\.\)\_\'+char(39)+'\---"\&\#\!\¡\(\)\¿\?\ ',
	    @w_long_obs         = 64

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

select @t_trn = 172192 --trn de sp_ref_com

if ( @i_operacion in ('I','U'))
begin
   /*Campos requeridos*/

   if @i_operacion = 'U' and isnull(@i_referencia,'') = '' and @i_referencia <> 0
   begin
      select @w_valor_campo = 'referenceSequential'
      goto VALIDAR_ERROR  
   end
   
   if isnull(@i_institucion,'') = ''
   begin
      select @w_valor_campo = 'institution'
      goto VALIDAR_ERROR  
   end
   
   if isnull(@i_fecha_ingr_en_inst,'') = ''
   begin
      select @w_valor_campo = 'openingDate'
      goto VALIDAR_ERROR  
   end
   
   if isnull(@i_numero_cifras,'') = '' and @i_numero_cifras <> 0
   begin
      select @w_valor_campo = 'digitNumber'
      goto VALIDAR_ERROR  
   end
   
   if isnull(@i_tipo_cifras,'') = ''
   begin
      select @w_valor_campo = 'digitType'
      goto VALIDAR_ERROR  
   end
   
   if isnull(@i_calificacion,'') = ''
   begin
      select @w_valor_campo = 'score'
      goto VALIDAR_ERROR  
   end
   
   /* VALIDAR FECHA APERTURA CON LA DE PROCESO */
   if(@i_fecha_ingr_en_inst > (select fp_fecha from cobis..ba_fecha_proceso))
   begin
      select @w_error = 1720559
      goto ERROR_FIN
   end
   
   /*validar que exista tipo cifras*/
   exec @w_error = cobis..sp_validar_catalogo  
      @i_tabla = 'cl_tcifras', 
      @i_valor = @i_tipo_cifras

   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
   begin 
	  select @w_valor_campo = @i_tipo_cifras 
	  select @w_error = 1720552 -- mensaje genérico: 
	  goto VALIDAR_ERROR 
   end
   
   /*validar que exista calificación*/
   exec @w_error = cobis..sp_validar_catalogo  
      @i_tabla = 'cl_posicion', 
      @i_valor = @i_calificacion

   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
   begin 
	  select @w_valor_campo = @i_calificacion 
	  select @w_error = 1720552 -- mensaje genérico: 
	  goto VALIDAR_ERROR 
   end
   
   /*VALIDAR CARACTERES*/
   if(@i_observacion is not null)
   begin
      select @w_caracter = cob_interface.dbo.fn_valida_caracter(@i_observacion, @w_lista_obs)
      if(@w_caracter is not null)
      begin
         select @w_error = 1720562
         set @w_valor_campo = @w_caracter +' - observation'
         goto VALIDAR_ERROR
      end
   end
   /* INSTITUCIÓN */
   select @w_caracter = cob_interface.dbo.fn_valida_caracter(@i_institucion, @w_lista_ins)
   if(@w_caracter is not null)
   begin
      select @w_error = 1720562
      set @w_valor_campo = @w_caracter +' - institution'
      goto VALIDAR_ERROR
   end
   
   /*VALIDAR LONGITUD DE CARÁCTERES*/
   
   if(@i_observacion is not null)
   begin
      if len(@i_observacion) > 64
	  begin
         select @w_error = 1720563
         set @w_valor_campo = convert(varchar,@w_long_obs) +' - observation'
         goto VALIDAR_ERROR
      end
   end
   
   if len(@i_institucion) > 64
   begin
      select @w_error = 1720563
      set @w_valor_campo = convert(varchar,@w_long_obs) +' - institution'
      goto VALIDAR_ERROR
    end
   
   set @i_institucion = upper(@i_institucion)

   select @w_error = 0
   
   exec @w_error = cobis..sp_ref_com
      @s_ssn                =  @s_ssn,
      @s_user               =  @s_user,
      @s_term               =  @s_term,
      @s_date               =  @s_date,
      @s_srv                =  @s_srv,
      @s_lsrv               =  @s_lsrv,
      @s_ofi                =  @s_ofi,
      @s_rol                =  @s_rol,
      @s_org_err            =  @s_org_err,
      @s_error              =  @s_error,
      @s_sev                =  @s_sev,
      @s_msg                =  @s_msg,
      @s_org                =  @s_org,
      @t_debug              =  @t_debug,
      @t_file               =  @t_file,
      @t_from               =  @t_from,
      @t_trn                =  @t_trn,
      @i_operacion          =  @i_operacion,
      @i_ente               =  @i_ente,
      @i_referencia         =  @i_referencia,
      @i_institucion        =  @i_institucion,
      @i_fecha_ingr_en_inst =  @i_fecha_ingr_en_inst,
      @i_tipo_cifras        =  @i_tipo_cifras,
      @i_numero_cifras      =  @i_numero_cifras,
      @i_calificacion       =  @i_calificacion,
      @i_observacion        =  @i_observacion,
      @i_verificacion       =  @i_verificacion,
      @i_fecha_ver          =  @i_fecha_ver,
      @o_secuencial         =  @o_secuencial out

   if @w_error <> 0 begin
      return @w_error
   end
   
end   --validar errores fin

if (@i_operacion in ('S', 'D'))
begin

   if @i_operacion = 'D' and isnull(@i_referencia,'') = '' and @i_referencia <> 0
   begin
      select @w_valor_campo = 'referenceSequential'
      goto VALIDAR_ERROR  
   end
   
   if not exists (select 1 from cobis..cl_comercial where ente = @i_ente)
   begin
      select @w_error = 1720289
	  goto ERROR_FIN
   end
   
   select @w_error = 0

   exec @w_error = cobis..sp_ref_com
   @s_ssn                =  @s_ssn,
   @s_user               =  @s_user,
   @s_term               =  @s_term,
   @s_date               =  @s_date,
   @s_srv                =  @s_srv,
   @s_lsrv               =  @s_lsrv,
   @s_ofi                =  @s_ofi,
   @s_rol                =  @s_rol,
   @s_org_err            =  @s_org_err,
   @s_error              =  @s_error,
   @s_sev                =  @s_sev,
   @s_msg                =  @s_msg,
   @s_org                =  @s_org,
   @t_debug              =  @t_debug,
   @t_file               =  @t_file,
   @t_from               =  @t_from,
   @t_trn                =  @t_trn,
   @i_operacion          =  @i_operacion,
   @i_ente               =  @i_ente,
   @i_referencia         =  @i_referencia

   if @w_error <> 0 begin
	  return @w_error
   end
	    
end

return 0

VALIDAR_ERROR:

select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo, @w_error, @s_culture)
goto ERROR_FIN

ERROR_FIN:

exec cobis..sp_cerror
         @t_debug    = @t_debug,
         @t_file     = @t_file,
         @t_from     = @w_sp_name,
		   @i_msg		 = @w_sp_msg,
         @i_num      = @w_error
		 
return @w_error

go
