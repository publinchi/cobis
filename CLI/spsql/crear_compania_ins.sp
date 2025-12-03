/************************************************************************/
/*   Archivo:                sp_crear_compania_ins.sp                   */
/*   Stored procedure:       sp_crear_compania_ins                      */
/*   Base de datos:          cob_pac                                    */      
/*   Producto:               Clientes                                   */
/*   Disenado por:           JMEG                                       */
/*   Fecha de escritura:     30-Abril-19                                */
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
/*   Este programa procesa las transacciones                            */
/*   DML de direcciones                                                 */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      30/04/19        JMEG          Emision Inicial                   */
/*      07/07/20        FSAP          Estandarizacion Clientes          */
/************************************************************************/

use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_crear_compania_ins')
   drop proc sp_crear_compania_ins
go

create proc sp_crear_compania_ins (
    @s_ssn                      int,
    @s_user                     login           = null,
    @s_term                     varchar(32)     = null,
    @s_date                     datetime,   
    @s_srv                      varchar(30)     = null,
    @s_lsrv                     varchar(30)     = null,
    @s_ofi                      smallint        = NULL,
    @s_rol                      smallint        = NULL,
    @s_org_err                  char(1)         = NULL,
    @s_error                    int             = NULL,
    @s_sev                      tinyint         = NULL,
    @s_msg                      descripcion     = NULL,
    @s_org                      char(1)         = NULL,
    @t_debug                    char(1)         = 'N',
    @t_file                     varchar(10)     = null,
    @t_from                     varchar(32)     = null,
    @t_trn                      int             = null,
    @t_show_version             bit             = 0,    -- Versionamiento
    @i_compania                 int             = null, -- Codigo secuencial de la compania
    @i_nombre                   varchar(128)    = null, -- Nombre comercial de la compania
    @i_razon_social             varchar(254)    = null, -- Razon social de la compania
    @i_ruc                      numero          = null, -- Numero de identificacion de la compania
    @i_tipo_ced                 char(4),
    @i_dir_virtual              varchar(50)     = null,
    @i_fecha_constitucion       datetime        = null,
    @i_ea_fecha_vigencia        datetime        = null,
    @i_login_oficial            varchar(20),
    @i_filial                   tinyint         = null, -- Codigo de la filial
    @i_oficina                  smallint        = null, -- Codigo de la oficina
    @i_operacion                char(1),
    @o_ente                     int             = null  out,
    @o_dire                     int             = null  out
)
as
declare @w_sp_name              varchar(30),
            @w_sp_msg               varchar(132), 
            @w_relacion             int,
            @w_pais                 int,
            @w_oficial              int,
            @w_tipo_direccion       char(2),
            @w_estado_prospecto     char(1),
            @w_lado_relacion        char(1)

select @w_sp_name = 'cob_pac..sp_crear_compania_ins'

---- VERSIONAMIENTO DEL PROGRAMA -------------------------------------------
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
        
if @i_operacion = 'I'
begin
  begin tran
    select @w_tipo_direccion = 'CE'     --Correo Electrónico
    select @w_estado_prospecto = 'P'    --Tipo Persona: Prospecto
        
    
    -- Consulta país por defecto
    select  @w_pais = pa_smallint
    from    cobis..cl_parametro
    where pa_nemonico = 'CP'
            
        
    if @w_pais is null
    begin
        exec cobis..sp_cerror
            @t_debug     = @t_debug,
            @t_file      = @t_file,
            @t_from      = @w_sp_name,
            @i_num       = 7300003
        return 1
    end
    
    
    select  @w_oficial  = oc_oficial
      from  cobis..cc_oficial,
            cobis..cl_funcionario
     where  fu_login       = @i_login_oficial 
       and  fu_funcionario   = oc_funcionario
  
    if @w_oficial is null
    begin
        exec cobis..sp_cerror
                @t_debug     = @t_debug,
                @t_file      = @t_file,
                @t_from      = @w_sp_name,
                @i_num       = 1720161
        return 1
    end
    
    exec cobis..sp_compania_ins
                @i_nombre               =  @i_nombre,   
                @i_razon_social         =  @i_razon_social,
                @i_ruc                  =  @i_ruc,
                @i_nacionalidad         =  @w_pais, 
                @i_ea_estado            =  @w_estado_prospecto,          
                @i_fecha_constitucion   =  @i_fecha_constitucion,
                @i_ea_fecha_vigencia    =  @i_ea_fecha_vigencia,
                @i_tipo_nit             =  @i_tipo_ced,
                @i_filial               =  @i_filial,
                @i_oficina              =  @i_oficina,     
                @i_oficial              =  @w_oficial,
                @i_operacion            =  @i_operacion,
                @i_exc_sipla            = 'N',
                @i_retencion            = 'S',
                @t_trn                  =  105,             
                @s_srv                  =  @s_srv,
                @s_user                 =  @s_user, 
                @s_lsrv                 =  @s_lsrv, 
                @s_term                 =  @s_term, 
                @s_date                 =  @s_date,
                @s_ofi                  =  @s_ofi,
                @s_org                  =  @s_org,
                @s_rol                  =  @s_rol,
                @s_ssn                  =  @s_ssn,
                @o_siguiente            =  @o_ente out
                
    if @o_ente is null
    begin
        exec cobis..sp_cerror
                @t_debug     = @t_debug,
                @t_file      = @t_file,
                @t_from      = @w_sp_name,
                @i_num       = 7300008
        return 1
    end
    
    
    exec cobis..sp_direccion_dml 
                    @i_ente             = @o_ente, 
                    @i_descripcion      = @i_dir_virtual, 
                    @i_tipo             = @w_tipo_direccion,
                    @i_operacion        = @i_operacion, 
                    @s_srv              = @s_srv, 
                    @s_user             = @s_user, 
                    @s_term             = @s_term, 
                    @s_ofi              = @s_ofi, 
                    @s_rol              = @s_rol, 
                    @s_ssn              = @s_ssn, 
                    @s_lsrv             = @s_lsrv, 
                    @s_date             = @s_date, 
                    @s_org              = @s_org, 
                    @t_trn              = 109,
                    @o_dire             = @o_dire out
                    
                    
    if @o_dire is null
    begin
        exec cobis..sp_cerror
                @t_debug     = @t_debug,
                @t_file      = @t_file,
                @t_from      = @w_sp_name,
                @i_num       = 7300006
        return 1
    end
        
    
    
  commit tran
return 0
end
    
go