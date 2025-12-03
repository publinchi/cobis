/************************************************************************/
/*   Archivo:            datos_adic_int.sp                              */
/*   Stored procedure:   sp_datos_adic_int                              */
/*   Base de datos:      cobis                                          */
/*   Producto:           Clientes                                       */
/*   Disenado por:       ACA                                            */
/*   Fecha de escritura: 30-Septiembre-21                               */
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
/*   en el servicio rest del sp_datos_adic_int                          */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/09/21         ACA       Emision Inicial                      */
/************************************************************************/

use cob_interface
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select 1 from sysobjects where name = 'sp_datos_adic_int')
   drop proc sp_datos_adic_int
go

create procedure sp_datos_adic_int (
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
        @i_dato                 smallint        = null,
        @i_descripcion          descripcion     = null,
        @i_tipo_dato            char(1)         = null,
        @i_valor                descripcion     = null,
        @i_tipo_ente            char(1)         = null,
        @i_sec_correccion       int             = null
) as declare
        @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_error                 int,
        @w_tipo_ente             char(1),
        @w_valor_campo           varchar(30),
        @w_valor_int             bigint,
        @w_valor_valido          bigint,
        @w_valor_catalogo        varchar(64),
        @w_ano                   varchar(4),
        @w_dia                   varchar(2),
        @w_mes                   varchar(10),
        @w_fecha                 date
        
select @w_sp_name          = 'sp_datos_adic_int',
       @w_error            = 1720548 --Campos requeridos

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

select @t_trn =
case @i_operacion
when 'I' then 172184
when 'U' then 172186
when 'E' then 172185
when 'Q' then 172183
end


if ( @i_operacion in ('I','U'))
begin
   /*Campos requeridos*/
   
   if isnull(@i_dato,'') = '' and @i_dato <> 0
   begin
      select @w_valor_campo = 'additionalDataSequential'
      goto VALIDAR_ERROR  
   end
   
   /*VALIDAR QUE EXISTA EL CLIENTE*/
   if not exists (select 1 from cobis..cl_dato_adicion where da_codigo = @i_dato)
   begin
      select @w_error = 1720465
      goto ERROR_FIN
   end 
   
   if isnull(@i_valor,'') = ''
   begin
      select @w_valor_campo = 'value'
      goto VALIDAR_ERROR  
   end
   
     

   /*Subtipo del cliente*/
   select @w_tipo_ente = en_subtipo from cobis..cl_ente where en_ente = @i_ente
   
   /*Tipo de cliente del dato adicional*/
   
   select @i_tipo_ente = da_tipo_ente, @w_valor_catalogo = da_catalogo from cobis..cl_dato_adicion where da_codigo = @i_dato
   
   if (@w_tipo_ente <> @i_tipo_ente)
   begin
      select @w_error = 1720572
      goto ERROR_FIN
   end
   
   select @i_tipo_dato = da_tipo_dato from cobis..cl_dato_adicion where da_codigo = @i_dato
   
   /*validaciones de tipos de datos numéricos*/
   
   if @i_tipo_dato in ('I','F','T','S','M')
   begin
      if isnumeric(@i_valor) = 0
      begin
         select @w_error = 1720567
         select @w_valor_campo = 'value'
         goto VALIDAR_ERROR
      end
      
      select @w_valor_int = cast(@i_valor as bigint)
      
      if @i_tipo_dato = 'I'
      begin
         select @w_valor_valido = POWER(2,30) -- valor permitido por tipo de dato entero
         select @w_valor_valido = (@w_valor_valido * 2) - 1
         if ((@w_valor_valido * -1) > @w_valor_int or @w_valor_int > @w_valor_valido)
         begin
            select @w_error = 1720574
            goto ERROR_FIN
         end
      end
      else if @i_tipo_dato = 'S'
      begin
         select @w_valor_valido = POWER(2,15)
         select @w_valor_valido = @w_valor_valido - 1        
         if ((@w_valor_valido * -1) > @w_valor_int or @w_valor_int > @w_valor_valido)
         begin
            select @w_error = 1720574
            goto ERROR_FIN
         end
      end
      else if @i_tipo_dato = 'T'
      begin
         select @w_valor_valido = 255        
         if (0 > @w_valor_int or @w_valor_int > @w_valor_valido) -- Validación tinyint
         begin
            select @w_error = 1720574
            goto ERROR_FIN
         end
      end
   end
   else if (@i_tipo_dato = 'D') --validacion que sea solo fecha
   begin
      if  isdate(@i_valor) = 0
      begin
         select @w_error = 1720573
         select @w_valor_campo = 'value'
         goto VALIDAR_ERROR
      end
      
      select @w_fecha = convert(datetime,@i_valor,103)
      
      /*validar que la fecha este completa*/
      set @w_dia = Datepart(dd,convert(datetime,@w_fecha,103)) 
      set @w_mes = DateName(mm,convert(datetime,@w_fecha,103))
      set @w_ano = Datepart(yy,convert(datetime,@w_fecha,103))
      
      if isnull(@w_dia, '') = '' or isnull(@w_mes, '') = '' or isnull(@w_ano, '') = ''
      begin
         select @w_error = 1720573
         select @w_valor_campo = 'value'
         goto VALIDAR_ERROR
      end     
      /*se asigna la fecha convertida*/
      select @i_valor = convert(varchar(10),@w_fecha,103)
      
   end
   else if (@i_tipo_dato = 'C' and len(@i_valor) > 1) -- Validación de caracter
   begin
      select @w_error = 1720563
      select @w_valor_campo = '1'
      goto VALIDAR_ERROR
   end
   else if (@i_tipo_dato = 'X' and len(@i_valor) > 64)
   begin
      select @w_error = 1720563
      select @w_valor_campo = '64'
      goto VALIDAR_ERROR
   end
   else if (@i_tipo_dato = 'A')
   begin
      exec @w_error = cobis..sp_validar_catalogo  
      @i_tabla = @w_valor_catalogo, 
      @i_valor = @i_valor

      if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
      else if @w_error = 1720018 -- mensaje por defecto que retorna el SP: No existe en catálogo
      begin 
         select @w_valor_campo = @i_valor 
         select @w_error = 1720552 -- mensaje genérico: 
         goto VALIDAR_ERROR 
      end
   end
   
   select @w_error = 0
   
   exec @w_error = cobis..sp_dad_ente
      @s_ssn             = @s_ssn,
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_date            = @s_date,
      @s_srv             = @s_srv,
      @s_lsrv            = @s_lsrv,
      @s_ofi             = @s_ofi,
      @s_rol             = @s_rol,
      @s_org_err         = @s_org_err,
      @s_error           = @s_error,
      @s_sev             = @s_sev,
      @s_msg             = @s_msg,
      @s_org             = @s_org,
      @t_debug           = @t_debug,
      @t_file            = @t_file,
      @t_from            = @t_from,
      @t_trn             = @t_trn,
      @i_operacion       = @i_operacion,
      @i_ente            = @i_ente,
      @i_dato            = @i_dato,
      @i_descripcion     = @i_descripcion,
      @i_tipodato        = @i_tipo_dato,
      @i_valor           = @i_valor,
      @i_tipoente        = @i_tipo_ente
      
      
   if @w_error <> 0 begin
      return @w_error
   end
   
end   --validar errores fin

if (@i_operacion in ('E', 'Q'))
begin

   if @i_operacion = 'E' and isnull(@i_dato,'') = '' and @i_dato <> 0
   begin
      select @w_valor_campo = 'additionalDataSequential'
      goto VALIDAR_ERROR  
   end
   
   /*VALIDAR QUE EXISTA EL CLIENTE*/
   if @i_operacion = 'E' and not exists (select 1 from cobis..cl_dato_adicion where da_codigo = @i_dato)
   begin
      select @w_error = 1720465
      goto ERROR_FIN
   end 
   
   if @i_operacion = 'Q' and not exists (select 1 from cobis..cl_dadicion_ente where de_ente = @i_ente)
   begin
      select @w_error = 1720475
      goto ERROR_FIN
   end

    exec @w_error = cobis..sp_dad_ente
      @s_ssn             = @s_ssn,
      @s_user            = @s_user,
      @s_term            = @s_term,
      @s_date            = @s_date,
      @s_srv             = @s_srv,
      @s_lsrv            = @s_lsrv,
      @s_ofi             = @s_ofi,
      @s_rol             = @s_rol,
      @s_org_err         = @s_org_err,
      @s_error           = @s_error,
      @s_sev             = @s_sev,
      @s_msg             = @s_msg,
      @s_org             = @s_org,
      @t_debug           = @t_debug,
      @t_file            = @t_file,
      @t_from            = @t_from,
      @t_trn             = @t_trn,
      @i_operacion       = @i_operacion,
      @i_ente            = @i_ente,
      @i_dato            = @i_dato,
      @i_descripcion     = @i_descripcion,
      @i_tipodato        = @i_tipo_dato,
      @i_valor           = @i_valor,
      @i_tipoente        = @i_tipo_ente

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
         @i_msg      = @w_sp_msg,
         @i_num      = @w_error
         
return @w_error

go
