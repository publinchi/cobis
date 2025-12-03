/*************************************************************************/
/*  Archivo          : compania_ins.sp                                   */
/*  Stored procedure : sp_compania_ins                                   */
/*  Base de datos    : cobis                                             */
/*  Producto         : Clientes                                          */
/*  Disenado por     : Mauricio Bayas/Sandra Ortiz                       */
/*  Fecha de document: 10/Nov/1993                                       */
/*************************************************************************/
/*                              IMPORTANTE                               */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad         */
/*  de COBISCorp.                                                        */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como     */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus     */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.    */
/*  Este programa esta protegido por la ley de   derechos de autor       */
/*  y por las    convenciones  internacionales   de  propiedad inte-     */
/*  lectual.   Su uso no  autorizado dara  derecho a    COBISCorp para   */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir         */
/*  penalmente a los autores de cualquier   infraccion.                  */
/*************************************************************************/
/*              PROPOSITO                                                */
/*  Este stored procedure procesa:                                       */
/*  - Insercion de compania                                              */
/*  - Actualizacion de compania                                          */
/*************************************************************************/
/*                         MODIFICACIONES                                */
/* FECHA                AUTOR                         RAZON              */
/* 22/Enero/2021        Jesus Garcia      Selecion la columna fecha      */
/* 03/Mayo/2021         Carlos Obando     Se agrega origen de emision ID */
/* 10/Enero/2022        Bruno Duenas      Se agrega upper para las       */
/*                                        identificaciones               */
/*************************************************************************/


use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where name = 'sp_compania_ins')
   drop proc sp_compania_ins
go

create procedure sp_compania_ins (
   @s_ssn                     int           = null,
   @s_user                    login         = null,
   @s_term                    varchar(32)   = null,
   @s_date                    datetime      = null,
   @s_srv                     varchar(30)   = null,
   @s_lsrv                    varchar(30)   = null,
   @s_ofi                     int           = null,
   @t_trn                     int,
   @t_show_version            bit           = 0,
   @i_operacion               char(1),
   @i_ente                    int           = null,
   @i_ced_ruc                 varchar(20)   = null,
   @i_tipo_ced                varchar(10)   = null,--'RFC'
   @i_nombre                  varchar(64)   = null,
   @i_pais                    smallint      = null,
   @i_filial                  tinyint       = null,
   @i_oficina                 smallint      = null,
   @i_retencion               char(1)       = null,
   @i_actividad               catalogo      = null,
   @i_comentario              varchar(254)  = null, 
   @i_sector                  catalogo      = null,
   @i_total_activos           money         = null, 
   @i_otros_ingresos          money         = null,
   @i_origen_ingresos         descripcion   = null,  
   @i_ea_estado               varchar(10)   = null,
   @i_ea_actividad            varchar(10)   = null,
   @i_ea_remp_legal           int           = null,
   @i_egresos                 catalogo      = null,
   @i_mnt_pasivo              money         = null,
   @i_ventas                  money         = null,
   @i_ct_ventas               money         = null,
   @i_ct_operativos           money         = null,
   @i_rep_legal               int           = null,
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
   @i_mala_referencia         char(1)       = null,
   @i_formato_fecha           tinyint       = null,
   @i_tipo_iden               varchar(13)   = null,
   @i_numero_iden             varchar(20)   = null,
   @i_ciudad_emision          int           = null,
   @i_oficial                 int           = null,
   @i_migrado                 varchar(30)   = null,
   @o_ente                    int           = null out

)
as
declare
   @w_today                datetime,
   @w_error                int,
   @w_sp_name              varchar(32),
   @w_sp_msg               varchar(132),
   @w_ente                 int,
   @w_rep_legal            int,
   @w_rep_cedula           varchar(24),
   @w_rep_nombre           varchar(254),
   @w_nacionalidad         varchar(10),
   @w_pais_local           int

        
/* captura nombre de stored procedure  */
select 
@w_sp_name = 'sp_compania_ins',
@w_sp_msg  = ''


/*--VERSIONAMIENTO--*/
if @t_show_version = 1 begin
   select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
   select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
   print  @w_sp_msg
   return 0
end


select @w_today = @s_date
select @i_numero_iden = upper(@i_numero_iden)
select @i_ced_ruc     = upper(@i_ced_ruc)
  
select @w_pais_local      = pa_smallint 
from cobis..cl_parametro 
where pa_nemonico = 'CP'    
and pa_producto = 'CLI'  -- PAIS DONDE ESTÁ EL BANCO

if @w_pais_local <> @i_pais 
begin
   select @w_nacionalidad = 'E'
end
else
begin
   select @w_nacionalidad = 'N'
end
  
--VALIDACION DE ESTADO DE TIPO DE IDENTIFICACION TRIBUTARIA
if(select ti_estado from cl_tipo_identificacion 
   where ti_codigo         = @i_tipo_ced 
   and   ti_tipo_documento = 'T' 
   and   ti_nacionalidad   = @w_nacionalidad 
   and   ti_tipo_cliente   = 'C') != 'V'
begin
   select @w_error = 1720607
   goto ERROR_FIN
end 
  
if @i_operacion = 'I' begin

   if @t_trn <> 172008 begin
      select @w_error = 1720075
      goto ERROR_FIN
   end
   
   /* CAMPOS OBLIGATORIOS */
   if isnull(@i_tipo_ced,'') = '' begin
      select @w_error = 101221
      goto ERROR_FIN   
   end
   
   if isnull(@i_ced_ruc,'') = '' begin
      select @w_error = 101221
      goto ERROR_FIN   
   end

   if isnull(@i_nombre,'') = '' begin
      select @w_error = 101221
      goto ERROR_FIN   
   end
   
   /* VALIDAR QUE NO EXISTA OTRA PERSONA CON ESE TIPO Y NUMERO DE DOCUMENTO */
   if exists (select 1 from   cobis..cl_ente
   where  en_tipo_ced = @i_tipo_ced
   and    en_ced_ruc  = @i_ced_ruc)
   begin
      select @w_error = 1720047
      goto ERROR_FIN
   end
   
   /* VALIDAR QUE NO EXISTA OTRA PERSONA CON ESE NUMERO DE IDENTIFICACION TRIBUTARIA */
   if exists (select 1 from   cobis..cl_ente
   where  en_nit  = @i_ced_ruc)
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
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_sector_economico', @i_valor = @i_sector      if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_actividad_ec',     @i_valor = @i_actividad   if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_tip_soc',          @i_valor = @i_tipo_soc    if @w_error <> 0 goto ERROR_FIN
   exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_nivel_egresos',    @i_valor = @i_egresos     if @w_error <> 0 goto ERROR_FIN


   /* encontrar un nuevo secuencial para compania */
   exec cobis..sp_cseqnos--cambiar antes de begin tran
   @t_debug     = 'N',
   @t_file      = '',
   @t_from      = @w_sp_name,
   @i_tabla     = 'cl_ente',
   @o_siguiente = @o_ente out

   if isnull(@i_oficial,'') = ''
   begin
      select @i_oficial = (select oc_oficial 
                           from   cl_funcionario f,
                                  cc_oficial o
                           where  fu_nombre = @s_user 
                           and    o.oc_funcionario = f.fu_funcionario)
   end
   
   begin tran

   if (@i_tipo_ced = 'RFC') begin
      insert into cl_ente (
      en_ente,                  en_subtipo,               en_nombre, 
      en_fecha_crea,            en_fecha_mod,             en_filial,
      en_oficina,               en_retencion,             en_mala_referencia,
      en_tipo_ced,              c_fecha_const,            en_pais,
      en_sector,                en_actividad,             c_tipo_soc,
      en_ced_ruc,               en_firma_electronica,     en_rfc,
      en_nit,                   en_comentario,            c_total_activos,
      c_pasivo,                 en_otros_ingresos,        en_origen_ingresos,
      c_rep_legal,              en_nivel,                 en_tipo_doc_tributario,
      en_tipo_iden,             en_numero_iden,           en_ciudad_emision,
      en_oficial,               en_ente_migrado)
      values (
      @o_ente,                  'C',                      @i_nombre,
      @w_today,                 @w_today,                 @i_filial,
      @i_oficina,               isnull(@i_retencion,'N'), @i_mala_referencia,
      @i_tipo_ced,              @i_fecha_crea,            @i_pais,
      @i_sector,                @i_actividad,             @i_tipo_soc,
      @i_ced_ruc,               @i_firma_electronica,     @i_ced_ruc,
      @i_ced_ruc,               @i_comentario,            @i_total_activos,
      @i_mnt_pasivo,            @i_otros_ingresos,        @i_origen_ingresos,
      @i_rep_legal,             '3',                      null,
      @i_tipo_iden,             @i_numero_iden,           @i_ciudad_emision,
      @i_oficial,               @i_migrado)
   end
   else 
   begin
      
      insert into cl_ente (
      en_ente,                  en_subtipo,               en_nombre, 
      en_fecha_crea,            en_fecha_mod,             en_filial,
      en_oficina,               en_retencion,             en_mala_referencia,
      en_tipo_ced,              c_fecha_const,            en_pais,
      en_sector,                en_actividad,             c_tipo_soc,
      en_ced_ruc,               en_firma_electronica,     en_rfc,
      en_nit,                   en_comentario,            c_total_activos,
      c_pasivo,                 en_otros_ingresos,        en_origen_ingresos,
      c_rep_legal,              en_nivel,                 en_tipo_doc_tributario,
      en_tipo_iden,             en_numero_iden,           en_ciudad_emision,
      en_oficial,               en_ente_migrado,          en_nomlar)   --PQU integración, por el originador se necesita el en_nomlar en persona jurídica
      values (
      @o_ente,                  'C',                      @i_nombre,
      @w_today,                 @w_today,                 @i_filial,
      @i_oficina,               isnull(@i_retencion,'N'), @i_mala_referencia,
      @i_tipo_ced,              @i_fecha_crea,            @i_pais,
      @i_sector,                @i_actividad,             @i_tipo_soc,
      @i_ced_ruc,               @i_firma_electronica,     @i_ced_ruc,
      @i_ced_ruc,               @i_comentario,            @i_total_activos,
      @i_mnt_pasivo,            @i_otros_ingresos,        @i_origen_ingresos,
      @i_rep_legal,             '3',                      @i_tipo_ced,
      @i_tipo_iden,             @i_numero_iden,           @i_ciudad_emision,
      @i_oficial,               @i_migrado,               @i_nombre)  --PQU integración, por el originador se necesita el en_nomlar en persona jurídica
      
   end

   if (@@error <> 0) begin
      select @w_error = 1720077
      goto ERROR_FIN /* 'Error en creacion de compania'*/
   end
   
       
   insert into cl_ente_aux(
   ea_ente,            ea_fatca,                  ea_crs,
   ea_s_inversion_ifi, ea_s_inversion,            ea_ifid,
   ea_c_merc_valor,    ea_c_nombre_merc_valor,    ea_ong_sfl,
   ea_ifi_np,          ea_estado,                 ea_actividad, 
   ea_remp_legal,      ea_num_serie_firma,        ea_ct_operativo,
   ea_ct_ventas,       ea_ventas,                 ea_nivel_egresos)
   values(
   @o_ente,            @i_fatca,                  @i_crs,
   @i_s_inversion_ifi, @i_s_inversion,            @i_ifid,
   @i_c_merc_valor,    @i_c_nombre_merc_valor,    @i_ong_sfl,
   @i_ifi_np,          isnull(@i_ea_estado, 'P'), @i_actividad, 
   @i_ea_remp_legal,   @i_firma_electronica,      @i_ct_operativos,
   @i_ct_ventas,       @i_ventas,                 @i_egresos) 
   
   
   if (@@error <> 0) begin
      select @w_error = 1720077
      goto ERROR_FIN /* 'Error en creacion de compania'*/
   end

   --Registro despues del cambio
   insert into ts_compania(
   secuencial,          tipo_transaccion,    clase,
   fecha,               usuario,             terminal,
   srv,                 lsrv,                compania,
   nombre,              ruc,                 actividad,
   rep_legal,           tipo,                pais,
   oficina,             retencion,           fecha_mod,
   oficial,             fecha_const,         nombre_completo,
   tipo_soc,            ciudad,              total_activos
   )
   select
   @s_ssn,              @t_trn,              'I',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @o_ente,
   en_nombre,           en_ced_ruc,          en_actividad,
   c_rep_legal,         en_tipo_ced,         en_pais,
   @s_ofi,              en_retencion,        en_fecha_mod,
   en_oficial,          c_fecha_const,       en_nomlar,
   c_tipo_soc,          en_ciudad_emision,   c_total_activos
   from cl_ente
   where en_ente    = @o_ente
      
   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end
   
   commit tran
   
   return 0
 
end

/* **** Update *** */
if (@i_operacion = 'U') begin
   
   if @t_trn <> 172009 begin
      select @w_error = 1720075
      goto ERROR_FIN
   end
   
   exec @w_error = sp_compania_upd
   @s_ssn                 = @s_ssn,
   @s_user                = @s_user,
   @s_term                = @s_term,
   @s_date                = @s_date,
   @s_srv                 = @s_srv,
   @s_lsrv                = @s_lsrv,
   @s_ofi                 = @s_ofi,
   @t_trn                 = 172023,
   @i_operacion           = 'U',
   @i_compania            = @i_ente,
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
   
   if @w_error <> 0 goto ERROR_FIN
   
   return 0
   

end


/* **** Select *** */
if (@i_operacion = 'S') begin 
   
   if @t_trn <> 172108 begin
      select @w_error = 1720075
      goto ERROR_FIN
   end
   
   select @w_rep_legal = c_rep_legal 
   from cobis..cl_ente 
   where en_ente = @i_ente
   
   if @@rowcount = 0 begin
      select @w_error = 1720081
      goto ERROR_FIN --NO EXISTEN REGISTROS
   end
   
   select 
   @w_rep_cedula = en_ced_ruc,
   @w_rep_nombre = en_nomlar
   from cobis..cl_ente 
   where en_ente = @w_rep_legal
    
   if @@rowcount = 0 begin
      select 
      @w_rep_cedula = 'NO EXISTE',
      @w_rep_nombre = 'NO EXISTE'   
   end
        
   select   
   'ENTE'            = en_ente,      
   'NOMBRE'          = en_nombre,
   'FECHA_CONST'     = convert(varchar,c_fecha_const,101),
   'PAIS'            = en_pais,
   'SECTOR'          = en_sector,
   'ACTIVIDAD'       = en_actividad,
   'TIPO_SOCIEDAD'   = c_tipo_soc,
   'FILIAL'          = en_filial, 
   'OFICINA'         = en_oficina, 
   'FECHA_MOD'       = convert(varchar,en_fecha_mod,101), 
   'RETENCION'       = en_retencion, 
   'MALA_REF'        = en_mala_referencia,
   'REP_LEGAL'       = c_rep_legal,
   'RFC'             = en_ced_ruc,
   'NOMBRE REP'      = @w_rep_nombre,
   'IDENT REP'       = @w_rep_cedula,
   'FIRMA E'          = en_firma_electronica,
   'TIPO_ID_TRIB'    = en_tipo_ced,
   'NUM_ID_TRIB'     = en_ced_ruc,
   'TIPO_ID_ADIC'    = en_tipo_iden,
   'NUM_ID_ADIC'     = en_numero_iden,
   'FECHA_CREACION'  = convert(varchar,en_fecha_crea,101),
   'CIUDAD EMISION'  = en_ciudad_emision,
   'NUMERO OFICIAL'  = en_oficial,
   'NOMBRE OFICIAL'  = (select fu_nombre
                        from   cl_funcionario f,
                               cc_oficial o
                        where  c.en_oficial     = o.oc_oficial
                        and    o.oc_funcionario = f.fu_funcionario),
   'MIGRADO'         = en_ente_migrado,
   'NRO CICLO'       = isnull(en_nro_ciclo,0)
   from cl_ente c
   where en_ente = @i_ente
      
    return 0
    
end


/* **** Delete *** */
if @i_operacion = 'D' begin

   select   
   @w_ente               = en_ente    
   from cobis..cl_ente  
   where en_ente = @i_ente

   if (@@rowcount <> 1) begin
      select @w_error = 1720079
      goto ERROR_FIN --NO EXISTE CLIENTE   
   end
   
   --Registro antes del cambio
   insert into ts_compania(
   secuencial,          tipo_transaccion,    clase,
   fecha,               usuario,             terminal,
   srv,                 lsrv,                compania,
   nombre,              ruc,                 actividad,
   rep_legal,           tipo,                pais,
   oficina,             retencion,           fecha_mod,
   oficial,             fecha_const,         nombre_completo,
   tipo_soc,            ciudad,              total_activos
   )
   select
   @s_ssn,              @t_trn,              'E',
   getdate(),           @s_user,             @s_term,
   @s_srv,              @s_lsrv,             @i_ente,
   en_nombre,           en_ced_ruc,          en_actividad,
   c_rep_legal,         en_tipo_ced,         en_pais,
   @s_ofi,              en_retencion,        en_fecha_mod,
   en_oficial,          c_fecha_const,       en_nomlar,
   c_tipo_soc,          en_ciudad_emision,   c_total_activos
   from cl_ente
   where en_ente    = @i_ente

   --ERROR EN CREACION DE TRANSACCION DE SERVICIO
   if @@error <> 0 begin
      select @w_error = 1720049
      goto ERROR_FIN
   end
   
   if @i_rep_legal is not null 
   begin
      update cobis..cl_ente
      set c_rep_legal = null
      where en_ente = @i_ente
      
   end 
   else 
   begin
      delete from cobis..cl_ente where en_ente = @i_ente
   end
  
end

return 0

ERROR_FIN:

while @@trancount > 0 rollback

exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = '',
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error

GO

