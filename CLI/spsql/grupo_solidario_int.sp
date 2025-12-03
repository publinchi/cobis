/************************************************************************/
/*  Archivo:                grupo_solidario_int.sp                      */
/*  Stored procedure:       sp_grupo_solidario_int                      */
/*  Producto:               Clientes                                    */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     27-09-2021                                  */
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
/*   y penales en contra del infractor segúb corresponda.".             */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_grupo                                   */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA       AUTOR           RAZON                                   */
/*  27-09-2021  BDU             Emision inicial                         */
/*  06-04-2023  BDU             Ajustes APP                             */
/************************************************************************/


use cob_interface
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
if exists (select 1 from sysobjects where name = 'sp_grupo_solidario_int')
   drop proc sp_grupo_solidario_int
go

create proc sp_grupo_solidario_int (
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
    @t_show_version         bit             = 0,    -- Mostrar la version del programa
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
    @i_operacion            char(1),                -- Opcion con que se ejecuta el programa
    @i_modo                 tinyint         = null, -- Modo de busqueda
    @i_tipo                 char(2)         = null, -- Tipo de consulta
    @i_filial               tinyint         = null, -- Codigo de la filial
    @i_oficina              smallint        = null, -- Codigo de la oficina    
    @i_ente                 int             = null, -- Codigo del ente que forma parte del grupo
    @i_grupo                int             = null, -- Codigo del grupo
    @i_nombre               descripcion     = null, -- Nombre del grupo economico
    @i_representante        int             = null, -- Codigo del representante legal
    @i_compania             int             = null, -- Codigo de la compania
    @i_oficial              int             = null, -- Codigo del oficial encargado del grupo economico
    @i_fecha_registro       datetime        = null, -- Fecha de Registro del grupo
    @i_fecha_modificacion   datetime        = null, -- Fecha de Modificacion del grupo 
    @i_ruc                  numero          = null, -- Numero del documento de identificacion
    @i_vinculacion          char(1)         = null, -- Codigo de vinculacion del representante al grupo
    @i_tipo_vinculacion     catalogo        = null, -- Codigo del tipo de vinculacion del representante al grupo
    @i_max_riesgo           money           = null,
    @i_riesgo               money           = null,
    @i_usuario              login           = null,
    @i_reservado            money           = null,
    @i_tipo_grupo           catalogo        = null,
    @i_estado               catalogo        = null, -- Estado del Grupo Economico
    @i_dir_reunion          varchar(125)    = null, -- Direccion de la reunion del grupo
    @i_dia_reunion          catalogo        = null, -- Dia de reunion del grupo
    @i_hora_reunion         varchar(10)     = null, -- Hora de la reunion de del grupo
    @i_comportamiento_pago  varchar(10)     = null, -- 
    @i_num_ciclo            int             = null, --
    @i_gr_tipo              char(1)         = null, -- campo gr_tipo en grupo   
    @i_gr_cta_grupal        VARCHAR(30)     = null, --campo  cuenta grupal
    @i_gr_sucursal          int             = null,
    @i_gr_titular1          int             = null, --campo cliente Titular1
    @i_gr_titular2          int             = NULL, --campo cliente Titular2
    @i_gr_lugar_reunion     char(10)        = null, --campo gr_lugar de Reunion
    @i_gr_tiene_ctagr       char(1)         = null, --campo tiene cuenta grupal
    @i_gr_tiene_ctain       char(1)         = null, --campo tiene cuenta individual
    @i_gr_gar_liquida       char(1)         = null, --campo tiene garatia liquida
    @i_desde_fe             char(1)         = 'N', --Indica que viene desde front end
    @i_rol                  catalogo        = null, -- rol para la consulta
    @o_actualiza_movil      char(1)         = null out,
    @o_grupo                int             = null out
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_trn_dir               int,
        @w_error                 int,
        @w_valor_campo           varchar(30),
        @w_init_msg_error        varchar(256),
        @w_lista_nombre          varchar(125),
        @w_lista_dir             varchar(125),      
        @w_caracter              varchar(3),
        @w_long_nom              int,
        @w_long_dir              int,
        @w_ttrn                  int,
        @w_grupo                 int
        
        
/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_grupo_solidario_int',
@w_lista_nombre     = '0-9\a-zA-Z\Á\á\é\í\ó\ú\É\Í\Ó\Ú\Ñ\ñ\---\ ',
@w_lista_dir        = '0-9\a-zA-Z\Á\á\é\í\ó\ú\É\Í\Ó\Ú\Ñ\ñ\---\.\ ',
@w_long_nom         = 55,
@w_long_dir         = 100
   
/* VALIDACIONES */

/* NUMERO DE TRANSACCION */
if @t_trn <>  172214
begin 
   /* Tipo de transaccion no corresponde */ 
   select @w_error = 1720275 
   goto ERROR_FIN
end
if(@i_operacion in ('I','U'))
begin
   /* CAMPOS REQUERIDOS */
   select @w_error            = 1720548
   if @i_operacion = 'I' and isnull(@i_nombre,'') = '' 
   begin
      select @w_valor_campo  = 'groupName'
      goto VALIDAR_ERROR   
   end

   if isnull(@i_oficial,'') = '' 
   begin
      select @w_valor_campo  = 'officer'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_dir_reunion,'') = '' 
   begin
      select @w_valor_campo  = 'meetingAddress'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_gr_sucursal,'') = '' 
   begin
      select @i_gr_sucursal = cf.fu_oficina
      from cobis.dbo.cc_oficial co
      join cobis.dbo.cl_funcionario cf on co.oc_funcionario = cf.fu_funcionario
      where co.oc_oficial = @i_oficial
   end
   
   if isnull(@i_dia_reunion,'') = '' 
   begin
      select @w_valor_campo  = 'meetingDays'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_hora_reunion,'') = '' 
   begin
      select @w_valor_campo  = 'meetingTime'
      goto VALIDAR_ERROR   
   end
   
   if @i_operacion = 'U' and isnull(@i_grupo,'') = '' and @i_grupo <> 0
   begin
      select @w_valor_campo  = 'groupSequential'
      goto VALIDAR_ERROR   
   end
   
   
   /* VALIDAR QUE EL CLIENTE EXISTA */
   
   if @i_representante is not null and not exists(select 1 from cobis..cl_ente where en_ente = @i_representante)
   begin
      select @w_error = 1720411 
      goto ERROR_FIN 
   end
   
   /* VALIDAR GRUPO */
   
   if @i_operacion = 'U' and not exists(select 1 from cobis..cl_grupo where  gr_grupo = @i_grupo)
   begin
      select @w_error = 1720052
      goto ERROR_FIN   
   end
   
   /* VALIDAR QUE EL CLIENTE NO EXISTA EN OTRO GRUPO */
   if(@i_operacion = 'I')
   begin
      if exists(select 1 from cobis..cl_cliente_grupo where cg_ente = @i_representante)
      begin
         select @w_error = 1720212 
         goto ERROR_FIN 
      end
   end
   else
   begin
      if exists(select 1 from cobis..cl_cliente_grupo where cg_ente = @i_representante and cg_grupo != @i_grupo)
      begin
         select @w_error = 1720212 
         goto ERROR_FIN 
      end
   end
   -- VALIDACIONES DE CATALOGOS           
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_estado_ambito', @i_valor = @i_estado         
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_estado         
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_oficina', @i_valor = @i_oficina         
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_oficina         
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'ad_dia_semana', @i_valor = @i_dia_reunion         
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_dia_reunion         
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_atencion_clientes', @i_valor = @i_hora_reunion         
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_hora_reunion         
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   
   /* VALIDAR OFICIAL */
   if not exists (select 1
                  from cobis..cl_funcionario, 
                       cobis..cc_oficial, 
                       cobis..ad_usuario
                  where fu_funcionario = oc_funcionario
                  and   oc_oficial     = @i_oficial
                  and   us_oficina     = @i_gr_sucursal
                  and   us_login       = fu_login)   
   begin
      select @w_error = 1720551
      goto ERROR_FIN
   end
   
   /* VALIDAR CARACTERES */
   /* NOMBRE DE GRUPO */
   if(@i_operacion = 'I')
   begin
      select @w_caracter = cob_interface.dbo.fn_valida_caracter(@i_nombre, @w_lista_nombre)
      if(@w_caracter is not null)
      begin
         select @w_error = 1720562
         set @w_valor_campo = @w_caracter +' - groupName'
         goto VALIDAR_ERROR
      end
      
      
      /* VALIDAR LONGITUD NOMBRE */
      if len(@i_nombre) > @w_long_nom
      begin
         select @w_error = 1720563 
         set @w_valor_campo = 'groupName ' + '(' + convert(varchar, @w_long_nom) + ')'
         goto VALIDAR_ERROR
      end
      
      /* NOMBRE A MAYUSCULAS */
      set @i_nombre = upper(@i_nombre)
   end
   /* VALIDAR CARACTERES DIRECCION */
   select @w_caracter = cob_interface.dbo.fn_valida_caracter(@i_dir_reunion, @w_lista_dir)
   if(@w_caracter is not null)
   begin
      select @w_error = 1720562
      set @w_valor_campo = @w_caracter +' - meetingAddress'
      goto VALIDAR_ERROR
   end
   
   /* VALIDAR LONGITUD DIRECCION */
   if len(@i_dir_reunion) > @w_long_dir
   begin
      select @w_error = 1720563 
      set @w_valor_campo = 'meetingAddress ' + '(' + convert(varchar, @w_long_dir) + ')'
      goto VALIDAR_ERROR
   end
   
   /* DIRECCION A MAYUSCULAS */
      set @i_dir_reunion = upper(@i_dir_reunion)
   /* VALIDACIONES DE NUMERO DE CICLO */
   set @i_num_ciclo = (select isnull(@i_num_ciclo, 0))
   if(@i_num_ciclo < 0)
   begin
      select @w_error = 1720556
      set @w_valor_campo = 'cyclesNumber'
      goto VALIDAR_ERROR
   end
   /* SETEAR TTRN */
   if(@i_operacion = 'I')
   begin
      set @w_ttrn = 172037
   end
   else
   begin
      set @w_ttrn = 172038
   end
   /* FIN VALIDACIONES */
   exec @w_error = cobis..sp_grupo
   @s_ssn                     = @s_ssn,                
   @s_user                    = @s_user,               
   @s_term                    = @s_term,               
   @s_date                    = @s_date,               
   @s_srv                     = @s_srv,                
   @s_lsrv                    = @s_lsrv,               
   @s_ofi                     = @s_ofi,                
   @s_rol                     = @s_rol,                
   @s_org_err                 = @s_org_err,            
   @s_error                   = @s_error,              
   @s_sev                     = @s_sev,                
   @s_msg                     = @s_msg,                
   @s_org                     = @s_org,                
   @t_show_version            = @t_show_version,       
   @t_debug                   = @t_debug,              
   @t_file                    = @t_file,               
   @t_from                    = @t_from,               
   @t_trn                     = @w_ttrn,                
   @i_operacion               = @i_operacion,          
   @i_modo                    = @i_modo,               
   @i_tipo                    = @i_tipo,               
   @i_filial                  = @i_filial,             
   @i_oficina                 = @i_oficina,            
   @i_ente                    = @i_ente,               
   @i_grupo                   = @i_grupo,              
   @i_nombre                  = @i_nombre,             
   @i_representante           = @i_representante,      
   @i_compania                = @i_compania,           
   @i_oficial                 = @i_oficial,            
   @i_fecha_registro          = @i_fecha_registro,     
   @i_fecha_modificacion      = @i_fecha_modificacion, 
   @i_ruc                     = @i_ruc,                
   @i_vinculacion             = @i_vinculacion,        
   @i_tipo_vinculacion        = @i_tipo_vinculacion,   
   @i_max_riesgo              = @i_max_riesgo,         
   @i_riesgo                  = @i_riesgo,             
   @i_usuario                 = @i_usuario,            
   @i_reservado               = @i_reservado,          
   @i_tipo_grupo              = @i_tipo_grupo,         
   @i_estado                  = @i_estado,             
   @i_dir_reunion             = @i_dir_reunion,        
   @i_dia_reunion             = @i_dia_reunion,        
   @i_hora_reunion            = @i_hora_reunion,       
   @i_comportamiento_pago     = @i_comportamiento_pago,
   @i_num_ciclo               = @i_num_ciclo,          
   @i_gr_tipo                 = @i_gr_tipo,            
   @i_gr_cta_grupal           = @i_gr_cta_grupal,      
   @i_gr_sucursal             = @i_gr_sucursal,        
   @i_gr_titular1             = @i_gr_titular1,        
   @i_gr_titular2             = @i_gr_titular2,        
   @i_gr_lugar_reunion        = @i_gr_lugar_reunion,   
   @i_gr_tiene_ctagr          = @i_gr_tiene_ctagr,     
   @i_gr_tiene_ctain          = @i_gr_tiene_ctain,     
   @i_gr_gar_liquida          = @i_gr_gar_liquida,     
   @i_desde_fe                = @i_desde_fe,           
   @i_rol                     = @i_rol,                
   @o_actualiza_movil         = @o_actualiza_movil,    
   @o_grupo                   = @o_grupo output
     
   if @w_error <> 0 or (@i_operacion = 'I' and @o_grupo is null)
   begin   
      goto ERROR_FIN 
   end
   if @i_representante is not null
   begin
      select @w_grupo = case @i_operacion when 'I' then @o_grupo else @i_grupo end 
      exec @w_error = cobis..sp_miembro_grupo
      @s_ssn             = @s_ssn,   
      @s_user            = @s_user,   
      @s_culture         = @s_culture,               
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
      @t_show_version    = @t_show_version,     
      @t_debug           = @t_debug,           
      @t_file            = @t_file,            
      @t_from            = @t_from,    
      @t_trn             = 172041,        
      @i_operacion       = @i_operacion,
      @i_ente            = @i_representante,
      @i_rol             = 'P',
      @i_grupo           = @w_grupo,
      @i_estado          = 'V'
      
      if @w_error <> 0 
      begin   
         goto ERROR_FIN 
      end
   end
   return 0
end


if @i_operacion = 'S'
begin
   /* CAMPOS REQUERIDOS */
   select @w_error            = 1720548
   if isnull(@i_grupo,'') = '' and @i_grupo <> 0
   begin
      select @w_valor_campo  = 'groupSequential'
      goto VALIDAR_ERROR   
   end
   
   /* VALIDAR GRUPO */
   
   if not exists(select 1 from cobis..cl_grupo where gr_grupo = @i_grupo)
   begin
      select @w_error = 1720052
      goto ERROR_FIN   
   end
   
   exec @w_error = cobis..sp_grupo
   @s_ssn                     = @s_ssn,                
   @s_user                    = @s_user,               
   @s_term                    = @s_term,               
   @s_date                    = @s_date,               
   @s_srv                     = @s_srv,                
   @s_lsrv                    = @s_lsrv,               
   @s_ofi                     = @s_ofi,                
   @s_rol                     = @s_rol,                
   @s_org_err                 = @s_org_err,            
   @s_error                   = @s_error,              
   @s_sev                     = @s_sev,                
   @s_msg                     = @s_msg,                
   @s_org                     = @s_org,                
   @t_show_version            = @t_show_version,       
   @t_debug                   = @t_debug,              
   @t_file                    = @t_file,               
   @t_from                    = @t_from,               
   @t_trn                     = null,                
   @i_operacion               = @i_operacion,          
   @i_modo                    = @i_modo,               
   @i_tipo                    = @i_tipo,               
   @i_filial                  = @i_filial,             
   @i_oficina                 = @i_oficina,            
   @i_ente                    = @i_ente,               
   @i_grupo                   = @i_grupo,              
   @i_nombre                  = @i_nombre,             
   @i_representante           = @i_representante,      
   @i_compania                = @i_compania,           
   @i_oficial                 = @i_oficial,            
   @i_fecha_registro          = @i_fecha_registro,     
   @i_fecha_modificacion      = @i_fecha_modificacion, 
   @i_ruc                     = @i_ruc,                
   @i_vinculacion             = @i_vinculacion,        
   @i_tipo_vinculacion        = @i_tipo_vinculacion,   
   @i_max_riesgo              = @i_max_riesgo,         
   @i_riesgo                  = @i_riesgo,             
   @i_usuario                 = @i_usuario,            
   @i_reservado               = @i_reservado,          
   @i_tipo_grupo              = @i_tipo_grupo,         
   @i_estado                  = @i_estado,             
   @i_dir_reunion             = @i_dir_reunion,        
   @i_dia_reunion             = @i_dia_reunion,        
   @i_hora_reunion            = @i_hora_reunion,       
   @i_comportamiento_pago     = @i_comportamiento_pago,
   @i_num_ciclo               = @i_num_ciclo,          
   @i_gr_tipo                 = @i_gr_tipo,            
   @i_gr_cta_grupal           = @i_gr_cta_grupal,      
   @i_gr_sucursal             = @i_gr_sucursal,        
   @i_gr_titular1             = @i_gr_titular1,        
   @i_gr_titular2             = @i_gr_titular2,        
   @i_gr_lugar_reunion        = @i_gr_lugar_reunion,   
   @i_gr_tiene_ctagr          = @i_gr_tiene_ctagr,     
   @i_gr_tiene_ctain          = @i_gr_tiene_ctain,     
   @i_gr_gar_liquida          = @i_gr_gar_liquida,     
   @i_desde_fe                = @i_desde_fe,           
   @i_rol                     = @i_rol,                
   @o_actualiza_movil         = @o_actualiza_movil     
   
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
