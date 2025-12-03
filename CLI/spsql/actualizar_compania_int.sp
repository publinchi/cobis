/**************************************************************************/
/*  Archivo:                actualizar_compania_int.sp                    */
/*  Stored procedure:       sp_actualizar_compania_int                    */
/*  Producto:               Clientes                                      */
/*  Disenado por:           Bruno Duenas                                  */
/*  Fecha de escritura:     30-08-2021                                    */
/**************************************************************************/
/*                              IMPORTANTE                                */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad          */
/*  de COBISCorp.                                                         */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como      */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus      */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.     */
/*  Este programa esta protegido por la ley de   derechos de autor        */
/*  y por las    convenciones  internacionales   de  propiedad inte-      */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para    */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir          */
/*  penalmente a los autores de cualquier   infraccion.                   */
/**************************************************************************/
/*               PROPOSITO                                                */
/*   Este programa es un sp cascara para manejo de validaciones usadas    */
/*   en el servicio rest del sp_compania_upd                              */
/**************************************************************************/
/*                        MODIFICACIONES                                  */
/*  FECHA       AUTOR           RAZON                                     */
/*  30-08-2021  BDU             Emision inicial                           */
/**************************************************************************/


use cob_interface
GO
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
if exists (select 1 from sysobjects where name = 'sp_actualizar_compania_int')
   drop proc sp_actualizar_compania_int
go

create proc sp_actualizar_compania_int (
   @s_ssn                     int,
   @s_sesn                    int           = null,
   @s_user                    login         = null,
   @s_term                    varchar(32)   = null,
   @s_date                    datetime,
   @s_srv                     varchar(30)   = null,
   @s_lsrv                    varchar(30)   = null,
   @s_ofi                     smallint      = null,
   @s_rol                     smallint      = null,
   @s_org_err                 char(1)       = null,
   @s_error                   int           = null,
   @s_sev                     tinyint       = null,
   @s_msg                     descripcion   = null,
   @s_org                     char(1)       = null,
   @s_culture                 varchar(10)   = 'NEUTRAL',
   @t_debug                   char(1)       = 'n',
   @t_file                    varchar(10)   = null,
   @t_from                    varchar(32)   = null,
   @t_trn                     int           = null,
   @t_show_version            bit           = 0,     -- versionamiento
   @i_operacion               char(1),              
   @i_compania                int           = null,
   @i_ced_ruc                 varchar(20)   = null,
   @i_tipo_ced                varchar(10)   = null,
   @i_nombre                  varchar(50)   = null, 
   @i_pais                    smallint      = null, 
   @i_filial                  tinyint       = null, 
   @i_oficina                 smallint      = null, 
   @i_retencion               char(1)       = 'N', 
   @i_actividad               catalogo      = null,
   @i_comentario              varchar(254)  = null,   
   @i_sector                  catalogo      = null,
   @i_total_activos           money         = null, 
   @i_otros_ingresos          money         = null,
   @i_origen_ingresos         descripcion   = null,  
   @i_ea_estado               varchar(10)   = null,
   @i_ea_actividad            varchar(10)   = null,
   @i_egresos                 catalogo      = null,
   @i_mnt_pasivo              money         = null,
   @i_ventas                  money         = null,
   @i_ct_ventas               money         = null,
   @i_ct_operativos           money         = null,
   @i_rep_legal               int           = null,
   @i_ea_remp_legal           int           = null,
   @i_firma_electronica       varchar(30)   = null,
   @i_tipo_soc                catalogo      = null,
   @i_fecha_crea              datetime      = null,
   @i_fatca                   char(1)       = null,
   @i_crs                     char(1)       = null,
   @i_s_inversion_ifi         char(1)       = null, 
   @i_s_inversion             char(1)       = null, 
   @i_ifid                    char(1)       = null, 
   @i_c_merc_valor            char(1)       = null,
   @i_c_nombre_merc_valor     varchar(100)  = null, 
   @i_ong_sfl                 char(1)       = null,
   @i_ifi_np                  char(1)       = null,
   @i_tipo_iden               varchar(13)   = null,
   @i_numero_iden             varchar(20)   = null,
   @i_ciudad_emision          int           = null,
   @i_oficial                 int           = null,
   @i_migrado                 varchar(30)   = null
)
as
declare @w_sp_name               varchar(30),
        @w_sp_msg                varchar(132),
        @w_oficial               int,
        @w_trn_dir               int,
        @w_error                 int,
        @w_operacion             char(1),
        @w_existente             bit,
        @w_init_msg_error        varchar(256),
        @w_mask                  varchar(64),
        @w_valor_campo           varchar(30)
        
/* INICIAR VARIABLES DE TRABAJO  */
select
@w_sp_name          = 'cob_interface..sp_actualizar_compania_int',
@w_oficial          = @i_oficial,
@w_operacion        = '',
@w_error            = 1720548

   
/* VALIDACIONES */

/* NUMERO DE TRANSACCION */
if @t_trn <> 172200 
begin 
   /* Tipo de transaccion no corresponde */ 
   select @w_error = 1720275 
   goto ERROR_FIN
end

/* CAMPOS REQUERIDOS */
   if isnull(@i_compania,'') = '' and @i_compania <> 0
   begin
      select @w_valor_campo  = 'personSequential'
      goto VALIDAR_ERROR   
   end

   if isnull(@i_tipo_ced,'') = '' 
   begin
      select @w_valor_campo  = 'typeIdentification'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_ced_ruc,'') = '' 
   begin
      select @w_valor_campo  = 'identificationNumber'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_rep_legal,'') = '' and @i_rep_legal <> 0
   begin
      select @w_valor_campo  = 'legalRepresentative'
      goto VALIDAR_ERROR   
   end
   
   if isnull(@i_fecha_crea,'') = '' 
   begin
      select @w_valor_campo  = 'creationDate'
      goto VALIDAR_ERROR   
   end

   if isnull(@i_nombre,'') = '' 
   begin
      select @w_valor_campo  = 'companyName'
      goto VALIDAR_ERROR   
   end
   
   /* VALIDAR TIPO DE DOCUMENTO */ 
   
   if exists (select 1 from cobis..cl_tipo_identificacion where ti_codigo = @i_tipo_ced)
   begin
      select @w_mask = (select ti_mascara from cobis..cl_tipo_identificacion where ti_codigo = @i_tipo_ced and ti_tipo_cliente = 'C' and ti_tipo_documento = 'T')
      
      /* VALIDAR MASCARA DE DOCUMENTO */ 
      
      if(len(@w_mask) <> len(@i_ced_ruc))
      begin
         select @w_error = 1720550
         goto ERROR_FIN 
      end
   end
   else
   begin
      select @w_error = 1720549
      goto ERROR_FIN 
   end   
   /* VALIDAR OFICIAL */
   
   if not exists (select 1
                  from cobis..cl_funcionario, 
                       cobis..cc_oficial, 
                       cobis..ad_usuario
                  where fu_funcionario = oc_funcionario
                  and   oc_oficial     = @i_oficial
                  and   us_oficina     = @i_oficina
                  and   us_login       = fu_login)   
   begin
      select @w_error = 1720551
      goto ERROR_FIN
   end
   /* VALIDAR QUE NO EXISTA OTRA PERSONA CON ESE TIPO Y NUMERO DE DOCUMENTO */
   
   if exists (select 1 from   cobis..cl_ente
   where  en_tipo_ced = @i_tipo_ced
   and    en_ced_ruc  = @i_ced_ruc
   and    en_ente     != @i_compania)
   begin
      select @w_error = 1720047
      goto ERROR_FIN
   end
   
   /* VALIDAR QUE NO EXISTA OTRA PERSONA CON ESE NUMERO DE IDENTIFICACION TRIBUTARIA */
   if exists (select 1 from   cobis..cl_ente
   where  en_nit  = @i_ced_ruc
   and    en_ente != @i_compania)
   begin
      select @w_error = 1720076
      goto ERROR_FIN
   end
   
   /* VALIDAR QUE EXISTA EL REPRESENTANTE LEGAL */
   if  isnull(@i_rep_legal,0) <> 0
   and not exists(select 1 from cobis..cl_ente 
                  where en_ente    = @i_rep_legal 
                  and   en_subtipo = 'P')   -- tiene que ser una persona natural
   begin
      select @w_error  = 1720078
      goto ERROR_FIN 
   end
   
   
   -- VALIDACIONES DE CATALOGOS           
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_sector_economico', @i_valor = @i_sector          
   if @w_error <> 0 and @w_error != 1720018 goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_sector         
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_actividad_ec',     @i_valor = @i_actividad       
   if @w_error <> 0 and @w_error != 1720018 
   goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_actividad      
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_tip_soc',          @i_valor = @i_tipo_soc        
   if @w_error <> 0 and @w_error != 1720018 
   goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_tipo_soc       
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_ciudad',           @i_valor = @i_ciudad_emision  
   if @w_error <> 0 and @w_error != 1720018 
   goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_ciudad_emision 
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   
   exec @w_error = cobis..sp_validar_catalogo  @i_tabla = 'cl_pais',             @i_valor = @i_pais            
   if @w_error <> 0 and @w_error != 1720018 
   goto ERROR_FIN 
   else if @w_error = 1720018 
   begin 
      select @w_valor_campo  = @i_pais           
      select @w_error = 1720552 
      goto VALIDAR_ERROR 
   end
   
   /* VALIDAR QUE LA CIUDAD COINCIDA CON EL PAIS */
   if not exists(select 1 from cobis..cl_ciudad where ci_pais = @i_pais and ci_ciudad = @i_ciudad_emision)
   begin
      select @w_error  = 1720557
      goto ERROR_FIN 
   end
   
/* FIN VALIDACIONES */
/* NOMBRE A MAYUSCULAS */
set @i_nombre = upper(@i_nombre)

exec @w_error = cobis..sp_compania_upd
   @s_ssn                 = @s_ssn,
   @s_user                = @s_user,
   @s_term                = @s_term,
   @s_date                = @s_date,
   @t_trn                 = 172023,
   @i_operacion           = 'U',
   @i_compania            = @i_compania,
   @i_ced_ruc             = @i_ced_ruc,
   @i_tipo_ced            = @i_tipo_ced,--'RFC'
   @i_nombre              = @i_nombre, 
   @i_pais                = @i_pais, 
   @i_filial              = @i_filial, 
   @i_oficina             = @i_oficina, 
   @i_retencion           = @i_retencion, 
   @i_actividad           = @i_actividad,
   @i_comentario          = @i_comentario, 
   @i_sector              = @i_sector,
   @i_total_activos       = @i_total_activos, 
   @i_otros_ingresos      = @i_otros_ingresos,
   @i_origen_ingresos     = @i_origen_ingresos,  
   @i_ea_estado           = @i_ea_estado,
   @i_ea_actividad        = @i_ea_actividad,
   @i_egresos             = @i_egresos,
   @i_mnt_pasivo          = @i_mnt_pasivo,
   @i_ventas              = @i_ventas,
   @i_ct_ventas           = @i_ct_ventas,
   @i_ct_operativos       = @i_ct_operativos,
   @i_rep_legal           = @i_rep_legal,
   @i_ea_remp_legal       = @i_ea_remp_legal,
   @i_firma_electronica   = @i_firma_electronica,
   @i_tipo_soc            = @i_tipo_soc,
   @i_fecha_crea          = @i_fecha_crea,
   @i_fatca               = @i_fatca,
   @i_crs                 = @i_crs,
   @i_s_inversion_ifi     = @i_s_inversion_ifi, 
   @i_s_inversion         = @i_s_inversion, 
   @i_ifid                = @i_ifid, 
   @i_c_merc_valor        = @i_c_merc_valor,
   @i_c_nombre_merc_valor = @i_c_nombre_merc_valor, 
   @i_ong_sfl             = @i_ong_sfl,
   @i_ifi_np              = @i_ifi_np,
   @i_migrado             = @i_migrado
   
if @w_error <> 0
begin   
   return @w_error
end
   
return 0

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
