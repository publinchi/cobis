/************************************************************************/
/*  Archivo:                referencias_financiera_int.sp               */
/*  Stored procedure:       sp_referencias_financiera_int               */
/*  Producto:               Clientes                                    */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     20-09-2021                                  */
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
/*   en el servicio rest del sp_ref_fin                                 */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA       AUTOR           RAZON                                   */
/*  20-09-2021  BDU             Emision inicial                         */
/************************************************************************/


use cob_interface
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
if exists (select 1 from sysobjects where name = 'sp_referencias_financiera_int')
   drop proc sp_referencias_financiera_int
go

create proc sp_referencias_financiera_int (
        @s_culture              varchar(10)     = 'NEUTRAL',
        @s_ssn                  int             = null,
        @s_user                 login           = null,
        @s_term                 varchar(30)     = null,
        @s_date                 datetime        = null,
        @s_srv                  varchar(30)     = null,
        @s_lsrv                 varchar(30)     = null,
        @s_ofi                  smallint        = null,
        @s_rol                  smallint        = NULL,
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
        @i_treferencia          char(1)         = null,
        @i_banco                smallint        = null,
        @i_toperacion           char(1)         = null,
        @i_tclase               descripcion     = null,
        @i_tipo_cifras          catalogo        = null,
        @i_numero_cifras        tinyint         = null,
        @i_fec_inicio           datetime        = null,
        @i_fec_vencimiento      datetime        = null,
        @i_calificacion         catalogo        = null,
        @i_vigencia             char(1)         = null,
        @i_verificacion         char(1)         ='S',
        @i_fecha_ver            datetime        = null,
        @i_fecha_modificacion   datetime        = null,
        @i_observacion          varchar(254)    = null,
        @i_estatus              char(1)         = null,
        @o_referencia_sec       tinyint         = null output
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_trn_dir               int,
        @w_error                 int,
        @w_init_msg_error        varchar(256),
        @w_valor_campo           varchar(30),
        @w_lista_obs             varchar(125),
        @w_lista_cta             varchar(125),
        @w_caracter              varchar(3),
        @w_long_obs              int,
        @w_today                 date
        
/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_referencias_financiera_int',
@w_error            = 1720548,
@w_lista_obs        = '0-9\a-zA-Z\Á\á\é\í\ó\ú\É\Í\Ó\Ú\Ñ\ñ\,\.\)\_\'+char(39)+'\---\"\&\#\!\¡\(\)\¿\?\ ',
@w_long_obs         = 64,
@w_today            = getdate()
   
/* VALIDACIONES */

/* NUMERO DE TRANSACCION */
if @t_trn <>  172211
begin 
   /* Tipo de transaccion no corresponde */ 
   select @w_error = 1720275 
   goto ERROR_FIN
end
if(@i_operacion in ('I','U'))
begin
   /* CAMPOS REQUERIDOS */
   if isnull(@i_ente,'') = ''  and @i_ente <> 0
   begin
      select @w_valor_campo  = 'personSequential'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_banco,'') = '' and @i_banco <> 0
   begin
      select @w_valor_campo  = 'bank'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_toperacion,'') = '' 
   begin
      select @w_valor_campo  = 'operationType'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_estatus,'') = '' 
   begin
      select @w_valor_campo  = 'status'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_tclase,'') = '' 
   begin
      select @w_valor_campo  = 'classType'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_fec_inicio,'') = '' 
   begin
      select @w_valor_campo  = 'openingDate'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_fec_vencimiento,'') = '' 
   begin
      select @w_valor_campo  = 'expirationDate'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_tipo_cifras,'') = '' 
   begin
      select @w_valor_campo  = 'digitType'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_numero_cifras,'') = '' and @i_numero_cifras <> 0
   begin
      select @w_valor_campo  = 'digitNumber'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_calificacion,'') = '' 
   begin
      select @w_valor_campo  = 'score'
      goto VALIDAR_ERROR   
   end
   
   if @i_operacion = 'U' and isnull(@i_referencia,'') = '' and @i_referencia <> 0
   begin
      select @w_valor_campo  = 'referenceSequential'
      goto VALIDAR_ERROR   
   end
   /* VALIDAR TIPOS*/
   select @w_error = 1720562
   /* VALIDAR TIPO DE OPERACION */
   
   if(@i_toperacion not in ('A', 'P'))
   begin
      select @w_valor_campo  = '(' + @i_toperacion + ') - operationType'
      goto VALIDAR_ERROR   
   end
   
   /* VALIDAR ESTADO */
   
   if(@i_estatus not in ('V', 'P'))
   begin
      select @w_valor_campo  = '(' + @i_estatus + ') - status'
      goto VALIDAR_ERROR   
   end
   
   /* VALIDAR TIPO CLASE */
   
   if(isnumeric(@i_tclase) = 0)
   begin
      select @w_error = 1720567
      select @w_valor_campo  = ' classType'
      goto VALIDAR_ERROR   
   end
   
   /* VALIDAR QUE EL CLIENTE EXISTA */
   
   if not exists(select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720411 
      goto ERROR_FIN 
   end
   
   /* VALIDAR REFERENCIA */
   
   if @i_operacion = 'U' and not exists(select 1 from cobis..cl_financiera where cliente = @i_ente and referencia = @i_referencia)
   begin
      select @w_error = 1720500
      goto ERROR_FIN   
   end
   
   /* VALIDAR FECHA INICIO CON LA DE PROCESO */   
   
   if(@i_fec_inicio > (select  fp_fecha  from cobis..ba_fecha_proceso))
   begin
      select @w_error =  1720559
      goto ERROR_FIN
   end
   
   /* VALIDAR FECHA VENCIMIENTO CON LA FECHA ACTUAL  */   
   
   if(@i_fec_vencimiento < @w_today)
   begin
      select @w_error =  1720569
      goto ERROR_FIN
   end
   
    /* VALIDAR QUE LA FECHA DE VENCICMIENTO NO SEA MENOR A LA DE INICIO */
   if(@i_fec_vencimiento < @i_fec_inicio)
   begin
      select @w_error =  1720568
      goto ERROR_FIN
   end
   
   /* VALIDAR BANCO */
   if(@i_operacion = 'I')
   begin
      if not exists(select 1 from cob_bancos..ba_banco where ba_tipo = @i_treferencia and ba_codigo = @i_banco)
      begin
         select @w_error = 1720560 
         goto ERROR_FIN
      end
   end
   else
   begin
      if not exists(select 1 from cob_bancos..ba_banco where ba_tipo = (select treferencia from cobis..cl_financiera where cliente = @i_ente and referencia = @i_referencia) and ba_codigo = @i_banco)
      begin
         select @w_error = 1720560 
         goto ERROR_FIN
      end
   end
   -- VALIDACIONES DE CATALOGOS           
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_tcifras', @i_valor = @i_tipo_cifras         
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_tipo_cifras         
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_posicion', @i_valor = @i_calificacion         
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_calificacion         
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   
   /* VALIDAR CARACTERES */
   /* OBSERVACION */
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
   
   /* VALIDAR LONGITUD OBSERVACION */
   if(@i_observacion is not null)
   begin
      if len(@i_observacion) > @w_long_obs
      begin
         select @w_error = 1720563 
         set @w_valor_campo = 'observation ' + '(' + convert(varchar, @w_long_obs) + ')'
         goto VALIDAR_ERROR
      end
   end
   
   /* VALIDAR LONGITUD TIPO CLASE */
   if len(@i_tclase) > @w_long_obs
   begin
      select @w_error = 1720563 
      set @w_valor_campo = 'classType ' + '(' + convert(varchar, @w_long_obs) + ')'
      goto VALIDAR_ERROR
   end
    
   /* FIN VALIDACIONES */
   exec @w_error = cobis..sp_ref_fin
   @s_ssn                = @s_ssn,              
   @s_user               = @s_user,              
   @s_term               = @s_term,              
   @s_date               = @s_date,              
   @s_srv                = @s_srv,               
   @s_lsrv               = @s_lsrv,              
   @s_ofi                = @s_ofi,               
   @s_rol                = @s_rol,               
   @s_org_err            = @s_org_err,           
   @s_error              = @s_error,             
   @s_sev                = @s_sev,               
   @s_msg                = @s_msg,               
   @s_org                = @s_org,               
   @t_debug              = @t_debug,             
   @t_file               = @t_file,              
   @t_from               = @t_from,              
   @t_trn                = @t_trn,               
   @i_operacion          = @i_operacion,         
   @i_ente               = @i_ente,              
   @i_referencia         = @i_referencia,        
   @i_treferencia        = @i_treferencia,       
   @i_banco              = @i_banco,             
   @i_toperacion         = @i_toperacion,        
   @i_tclase             = @i_tclase,            
   @i_tipo_cifras        = @i_tipo_cifras,       
   @i_numero_cifras      = @i_numero_cifras,     
   @i_fec_inicio         = @i_fec_inicio,        
   @i_fec_vencimiento    = @i_fec_vencimiento,   
   @i_calificacion       = @i_calificacion,      
   @i_vigencia           = @i_vigencia,          
   @i_verificacion       = @i_verificacion,      
   @i_fecha_ver          = @i_fecha_ver,         
   @i_fecha_modificacion = @i_fecha_modificacion,
   @i_observacion        = @i_observacion,       
   @i_estatus            = @i_estatus,           
   @o_referencia_sec     = @o_referencia_sec output
     
   if @w_error <> 0 or (@i_operacion = 'I' and @o_referencia_sec is null)
   begin   
      goto ERROR_FIN 
   end
      
   return 0
end

if @i_operacion = 'D'
begin
   /* CAMPOS REQUERIDOS */
   if isnull(@i_ente,'') = ''  and @i_ente <> 0
   begin
      select @w_valor_campo  = 'personSequential'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_referencia,'') = ''  and @i_referencia <> 0
   begin
      select @w_valor_campo  = 'referenceSequential'
      goto VALIDAR_ERROR   
   end
   
   /* VALIDAR QUE EL CLIENTE EXISTA */
      
   if not exists(select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720411 
      goto ERROR_FIN 
   end
   
   /* VALIDAR REFERENCIA */
   if not exists(select 1 from cobis..cl_financiera where cliente = @i_ente and referencia = @i_referencia)
   begin
      select @w_error = 1720500
      goto ERROR_FIN   
   end
   
   exec @w_error = cobis..sp_ref_fin
   @s_ssn                  = @s_ssn,
   @s_user                 = @s_user,
   @s_term                 = @s_term,
   @s_date                 = @s_date,
   @s_srv                  = @s_srv,
   @s_lsrv                 = @s_lsrv,
   @s_ofi                  = @s_ofi,
   @s_rol                  = @s_rol,
   @s_org_err              = @s_org_err,
   @s_error                = @s_error,
   @s_sev                  = @s_sev,
   @s_msg                  = @s_msg,
   @s_org                  = @s_org,
   @t_debug                = @t_debug,
   @t_file                 = @t_file,
   @t_from                 = @t_from,
   @t_trn                  = 172189,
   @i_operacion            = @i_operacion,
   @i_ente                 = @i_ente,
   @i_referencia           = @i_referencia
   
   if @w_error <> 0
   begin   
      goto ERROR_FIN
   end
      
   return 0
   
end

if @i_operacion = 'S'
begin
   /* CAMPOS REQUERIDOS */
   if isnull(@i_ente,'') = ''  and @i_ente <> 0
   begin
      select @w_valor_campo  = 'personSequential'
      goto VALIDAR_ERROR   
   end
   
   /* VALIDAR QUE EL CLIENTE EXISTA */
      
   if not exists(select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720411 
      goto ERROR_FIN 
   end
   
   exec @w_error = cobis..sp_ref_fin
   @s_ssn                  = @s_ssn,
   @s_user                 = @s_user,
   @s_term                 = @s_term,
   @s_date                 = @s_date,
   @s_srv                  = @s_srv,
   @s_lsrv                 = @s_lsrv,
   @s_ofi                  = @s_ofi,
   @s_rol                  = @s_rol,
   @s_org_err              = @s_org_err,
   @s_error                = @s_error,
   @s_sev                  = @s_sev,
   @s_msg                  = @s_msg,
   @s_org                  = @s_org,
   @t_debug                = @t_debug,
   @t_file                 = @t_file,
   @t_from                 = @t_from,
   @t_trn                  = 172189,
   @i_operacion            = @i_operacion,
   @i_ente                 = @i_ente,
   @i_treferencia          = @i_treferencia
   
   if @w_error <> 0
   begin   
      goto ERROR_FIN 
   end
      
   return 0
   
end

VALIDAR_ERROR:
   select @w_sp_msg = cob_interface.dbo.fn_concatena_mensaje(@w_valor_campo , @w_error, @s_culture)
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
