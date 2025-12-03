/************************************************************************/
/*  Archivo:                miembro_solidario_int.sp                    */
/*  Stored procedure:       sp_miembro_solidario_int                    */
/*  Producto:               Clientes                                    */
/*  Disenado por:           Bruno Duenas                                */
/*  Fecha de escritura:     28-09-2021                                  */
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
/*   sitio, queda expresamente prohibido sin el debido                  */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada y por lo tanto, derivará en acciones legales civiles       */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*               PROPOSITO                                              */
/*   Este programa es un sp cascara para manejo de validaciones usadas  */
/*   en el servicio rest del sp_miembro_grupo                           */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA       AUTOR          RAZON                                    */
/*  28-09-2021  BDU            Emision inicial                          */
/*  23-11-2021  ACA            Operación eliminar                       */
/*  12-04-23    BDU            Se modifica operacion consulta REST      */
/*  24-072323   BDU            Se deserta miembros en la cancelacion del*/
/*                             grupo R211803                            */
/*  14-12-2023  OGU            R221588: Se controla que el primer       */ 
/*                             miembro a añadir siempre sea presidente  */
/************************************************************************/


use cob_interface
go
set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go
if exists (select 1 from sysobjects where name = 'sp_miembro_solidario_int')
   drop proc sp_miembro_solidario_int
go

create proc sp_miembro_solidario_int (
    @s_culture                  varchar(10)     = 'NEUTRAL',
    @s_ssn                      int             = null,
    @s_sesn                     int             = null,
    @s_user                     login           = null,
    @s_term                     varchar(30)     = null,
    @s_date                     datetime        = null,
    @s_srv                      varchar(30)     = null,
    @s_lsrv                     varchar(30)     = null,
    @s_ofi                      smallint        = null,
    @s_rol                      smallint        = NULL,
    @s_org_err                  char(1)         = NULL,
    @s_error                    int             = NULL,
    @s_sev                      tinyint         = NULL,
    @s_msg                      descripcion     = NULL,
    @s_org                      char(1)         = NULL,
    @t_show_version             bit             = 0,    -- Mostrar la version del programa
    @t_debug                    char(1)         = 'N',
    @t_file                     varchar(10)     = null,
    @t_from                     varchar(32)     = null,
    @t_trn                      int             = null,
    @i_operacion                char(1),                -- Opcion con que se ejecuta el programa
    @i_modo                     tinyint         = null, -- Modo de busqueda
    @i_tipo                     char(2)         = null, -- Tipo de consulta
    @i_filial                   tinyint         = null, -- Codigo de la filial
    @i_oficina                  smallint        = null, -- Codigo de la oficina
    @i_ente                     int             = null, -- Codigo del ente que forma parte del grupo
    @i_grupo                    int             = null, -- Codigo del grupo
    @i_usuario                  login           = null,
    @i_oficial                  int             = null, -- Codigo del oficial
    @i_fecha_asociacion         datetime        = null, -- Fecha de asociación del grupo--i_fecha_reg
    @i_rol                      catalogo        = null, -- Rol que desempeña el miembro de grupo
    @i_estado                   catalogo        = null, -- Estado del Grupo Economico
    @i_calif_interna            catalogo        = null, -- Calificacion Interna
    @i_fecha_desasociacion      datetime        = NULL, -- Fecha de desasociacion del grupo
    @i_cg_ahorro_voluntario     MONEY           = NULL,  -- ahorro voluntario nuevo campo
    @i_cg_lugar_reunion         VARCHAR(10)     = NULL,   -- nuevo campo lugar de reunion
    @i_cg_cuenta_individual     VARCHAR(45)     = NULL,
	@i_mantenimiento            int             = NULL,
    @i_tramite                  int             = NULL,
    @i_tipo_grupo               char(1)         = NULL,
	@i_ente_aux                 int             = NULL,
    @o_validacion_ahorros       int             = null out,
    @o_validacion_cartera       int             = null out,
    @o_mensaje                  varchar(255)    = null out,
    @o_resultado                int             = 0
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_trn_dir               int,
        @w_error                 int,
        @w_valor_campo           varchar(30),
        @w_ttrn                  int
        
        
/* INICIAR VARIABLES DE TRABAJO  */
select @w_sp_name          = 'cob_interface..sp_miembro_solidario_int',
       @w_ttrn             = 172041
   
/* VALIDACIONES */

/* NUMERO DE TRANSACCION */
if @t_trn <>  172215
begin 
   /* Tipo de transaccion no corresponde */ 
   select @w_error = 1720275 
   goto ERROR_FIN
end
if(@i_operacion in ('I','U'))
begin
   /* CAMPOS REQUERIDOS */
   select @w_error            = 1720548
   
   if isnull(@i_ente, '') = ''  and @i_ente <> 0
   begin
      select @w_valor_campo  = 'groupMember'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_grupo,'') = ''  and @i_grupo <> 0
   begin
      select @w_valor_campo  = 'groupSequential'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_rol,'') = '' 
   begin
      select @w_valor_campo  = 'groupRole'
      goto VALIDAR_ERROR   
   end
   
   /* VALIDAR QUE EL CLIENTE EXISTA */
   
   if not exists(select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720411 
      goto ERROR_FIN 
   end
   
   /* VALIDAR QUE EL GRUPO SEA SOLIDARIO */
   
   if (select gr_tipo from cobis..cl_grupo where gr_grupo = @i_grupo) != 'S'
   begin
      select @w_error = 1720339 
      goto ERROR_FIN 
   end
   
   /* VALIDAR GRUPO */
   
   if not exists(select 1 from cobis..cl_grupo where  gr_grupo = @i_grupo)
   begin
      select @w_error = 1720052
      goto ERROR_FIN   
   end
   
   /* VALIDAR QUE EL CLIENTE EXISTA EN EL GRUPO EN ACTUALIZACION */
   
   if @i_operacion = 'U' and not exists(select 1 from cobis..cl_cliente_grupo where  cg_grupo = @i_grupo and cg_ente = @i_ente)
   begin
      select @w_error = 1720237
      goto ERROR_FIN   
   end
   
   --Validacion de presidente solo se realiza en grupo solidario
   if @i_operacion = 'I' and exists(select 1 from cobis..cl_grupo where gr_grupo = @i_grupo and gr_tipo = 'S') --R221588: Se verifica que el primer rol a añadirse sea presidente
   begin
      if @i_rol not in ('P')
      begin
         if not exists (select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_rol = 'P' and cg_ente != @i_ente)
         begin
            select @w_error = 1720221  --DEBE EXISTIR UN PRESIDENTE
            goto ERROR_FIN
         end
      end
   end
   
   -- VALIDACIONES DE CATALOGOS           
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_rol_grupo', @i_valor = @i_rol         
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_rol         
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end

   /* FIN VALIDACIONES */
   exec cobis..sp_miembro_grupo
   @s_ssn                  = @s_ssn,                 
   @s_sesn                 = @s_sesn,                
   @s_culture              = @s_culture,             
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
   @t_show_version         = @t_show_version,        
   @t_debug                = @t_debug,               
   @t_file                 = @t_file,                
   @t_from                 = @t_from,                
   @t_trn                  = @w_ttrn,                 
   @i_operacion            = @i_operacion,           
   @i_modo                 = @i_modo,                
   @i_filial               = @i_filial,              
   @i_oficina              = @i_oficina,             
   @i_ente                 = @i_ente,                
   @i_grupo                = @i_grupo,               
   @i_usuario              = @i_usuario,             
   @i_oficial              = @i_oficial,             
   @i_fecha_asociacion     = @i_fecha_asociacion,    
   @i_rol                  = @i_rol,                 
   @i_estado               = @i_estado,              
   @i_calif_interna        = @i_calif_interna,       
   @i_fecha_desasociacion  = @i_fecha_desasociacion, 
   @i_cg_ahorro_voluntario = @i_cg_ahorro_voluntario,
   @i_cg_lugar_reunion     = @i_cg_lugar_reunion,    
   @i_cg_cuenta_individual = @i_cg_cuenta_individual,
   @i_mantenimiento        = @i_mantenimiento,       
   @i_tramite              = @i_tramite,             
   @i_tipo_grupo           = @i_tipo,          
   @i_ente_aux             = @i_ente_aux,            
   @o_validacion_ahorros   = @o_validacion_ahorros,  
   @o_validacion_cartera   = @o_validacion_cartera,  
   @o_mensaje              = @o_mensaje,             
   @o_resultado            = @o_resultado        
   return 0
end


if @i_operacion = 'S'
begin
   /* CAMPOS REQUERIDOS */
   select @w_error            = 1720548
   if isnull(@i_grupo,'') = ''  and @i_grupo <> 0
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
   
   /* VALIDAR QUE EL CLIENTE EXISTA */
   
   if @i_ente is not null and @i_ente <> 0 and not exists(select 1 from cobis..cl_ente where en_ente = @i_ente)
   begin
      select @w_error = 1720411 
      goto ERROR_FIN 
   end
   
   /* VALIDAR QUE EL CLIENTE EXISTA EN EL GRUPO */
   
   if @i_ente is not null and @i_ente <> 0 and not exists(select 1 from cobis..cl_cliente_grupo where  cg_grupo = @i_grupo and cg_ente = @i_ente)
   begin
      select @w_error = 1720237
      goto ERROR_FIN   
   end
   
   
   
   
   exec cobis..sp_miembro_grupo
   @s_ssn                  = @s_ssn,                 
   @s_sesn                 = @s_sesn,                
   @s_culture              = @s_culture,             
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
   @t_show_version         = @t_show_version,        
   @t_debug                = @t_debug,               
   @t_file                 = @t_file,                
   @t_from                 = @t_from,                
   @t_trn                  = @w_ttrn,                 
   @i_operacion            = @i_operacion,           
   @i_modo                 = @i_modo,                
   @i_tipo                 = @i_tipo,                
   @i_filial               = @i_filial,              
   @i_oficina              = @i_oficina,             
   @i_ente                 = @i_ente,                
   @i_grupo                = @i_grupo,               
   @i_usuario              = @i_usuario,             
   @i_oficial              = @i_oficial,             
   @i_fecha_asociacion     = @i_fecha_asociacion,    
   @i_rol                  = @i_rol,                 
   @i_estado               = @i_estado,              
   @i_calif_interna        = @i_calif_interna,       
   @i_fecha_desasociacion  = @i_fecha_desasociacion, 
   @i_cg_ahorro_voluntario = @i_cg_ahorro_voluntario,
   @i_cg_lugar_reunion     = @i_cg_lugar_reunion,    
   @i_cg_cuenta_individual = @i_cg_cuenta_individual,
   @i_mantenimiento        = @i_mantenimiento,       
   @i_tramite              = @i_tramite,             
   @i_tipo_grupo           = @i_tipo_grupo,          
   @i_ente_aux             = @i_ente_aux,            
   @o_validacion_ahorros   = @o_validacion_ahorros,  
   @o_validacion_cartera   = @o_validacion_cartera,  
   @o_mensaje              = @o_mensaje,             
   @o_resultado            = @o_resultado     
   
      
   return 0
   
end

/*Operacion de eliminar miembro de un grupo*/
if @i_operacion = 'D'
begin
   /* CAMPOS REQUERIDOS */
   select @w_error        = 1720548
   if isnull(@i_grupo,'') = ''   and @i_grupo <> 0
   begin
      select @w_valor_campo  = 'groupSequential'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_ente, '') = ''   and @i_ente <> 0
   begin
      select @w_valor_campo  = 'groupMember'
      goto VALIDAR_ERROR
   end
   
   /* VALIDAR GRUPO */
   
   if not exists(select 1 from cobis..cl_grupo where gr_grupo = @i_grupo)
   begin
      select @w_error = 1720052
      goto ERROR_FIN   
   end
   
   /* VALIDAR QUE EL CLIENTE EXISTA EN EL GRUPO*/
   
   if not exists(select 1 from cobis..cl_cliente_grupo where cg_grupo = @i_grupo and cg_ente = @i_ente)
   begin
      select @w_error = 1720244
      goto ERROR_FIN   
   end
   
   exec cobis..sp_miembro_grupo
   @s_ssn                  = @s_ssn,                 
   @s_sesn                 = @s_sesn,                
   @s_culture              = @s_culture,             
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
   @t_show_version         = @t_show_version,        
   @t_debug                = @t_debug,               
   @t_file                 = @t_file,                
   @t_from                 = @t_from,                
   @t_trn                  = @w_ttrn,                 
   @i_operacion            = @i_operacion,           
   @i_modo                 = @i_modo,                
   @i_tipo                 = @i_tipo,                
   @i_filial               = @i_filial,              
   @i_oficina              = @i_oficina,             
   @i_ente                 = @i_ente,                
   @i_grupo                = @i_grupo,               
   @i_usuario              = @i_usuario,             
   @i_oficial              = @i_oficial,             
   @i_fecha_asociacion     = @i_fecha_asociacion,    
   @i_rol                  = @i_rol,                 
   @i_estado               = @i_estado,              
   @i_calif_interna        = @i_calif_interna,       
   @i_fecha_desasociacion  = @i_fecha_desasociacion, 
   @i_cg_ahorro_voluntario = @i_cg_ahorro_voluntario,
   @i_cg_lugar_reunion     = @i_cg_lugar_reunion,    
   @i_cg_cuenta_individual = @i_cg_cuenta_individual,
   @i_mantenimiento        = @i_mantenimiento,       
   @i_tramite              = @i_tramite,             
   @i_tipo_grupo           = @i_tipo_grupo,          
   @i_ente_aux             = @i_ente_aux,            
   @o_validacion_ahorros   = @o_validacion_ahorros,  
   @o_validacion_cartera   = @o_validacion_cartera,  
   @o_mensaje              = @o_mensaje,             
   @o_resultado            = @o_resultado     
   
      
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
