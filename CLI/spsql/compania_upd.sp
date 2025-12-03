/************************************************************************/
/*   Archivo:            compania_upd.sp                                */
/*   Stored procedure:   sp_compania_upd                                */
/*   Base de datos:      cob_pac                                        */
/*   Producto:           Clientes                                       */
/*   Disenado por:       JMEG                                           */
/*   Fecha de escritura: 30-Abril-19                                    */
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
/*                                  PROPOSITO                           */
/*                                                                      */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*   FECHA           AUTOR      RAZON                                   */
/*   30/04/19         JMEG      Emision Inicial                         */
/*   18/05/20         MBA       Cambio nombre y compilacion BDD cobis   */
/*   15/06/20         MBA       Estandarizacion sp y seguridades        */
/*   03/05/2021       COB       Se agrega origen de emision ID          */
/*   10/01/2022       BDU       Se agrega upper para las                */
/*                                        identificaciones              */
/************************************************************************/
use cobis
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

if exists (select * from sysobjects where name = 'sp_compania_upd')
   drop proc sp_compania_upd
go

create procedure sp_compania_upd (
   @s_ssn                     int           = null,
   @s_user                    login         = null,
   @s_term                    varchar(32)   = null,
   @s_date                    datetime      = null,
   @s_srv                     varchar(30)   = null,
   @s_lsrv                    varchar(30)   = null,
   @s_ofi                     int           = null,
   @t_trn                     int           = null,
   @t_show_version            bit           = 0,
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

declare 
@w_sp_name                 varchar(32),
@w_sp_msg                  varchar(132),
@w_error                   int,
@w_estado_ente             char(1),
@w_num                     int,
@w_param                   int, 
@w_diff                    int,
@w_date                    datetime,
@w_bloqueo                 char(1),
@w_nacionalidad            varchar(10),
@w_pais_local              int
   
   
/* INICIAR VARIABLES DE TRABAJO */
select 
@w_sp_name = 'sp_compania_upd'

/* VERSIONAMIENTO */
if @t_show_version = 1 begin
   select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
   select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
   print  @w_sp_msg
   return 0
end

/* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
select @w_param         = pa_int      from cobis..cl_parametro where pa_nemonico = 'MVROC'  and pa_producto = 'CLI'
if @i_compania is not null and @i_compania <> 0
begin
   select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_compania
   if @w_bloqueo = 'S'
   begin
      select @w_error = 1720604
      goto ERROR_FIN
   end
end 

select @w_estado_ente = 'P'  -- prospecto
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


--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn <> 172023 and @i_operacion = 'R') or
   (@t_trn <> 172023 and @i_operacion = 'E') or
   (@t_trn <> 172023 and @i_operacion = 'U') or
   (@t_trn <> 172023 and @i_operacion = 'F')
begin 
   select @w_error = 1720075
   goto ERROR_FIN /* Tipo de transaccion no corresponde */ 
end


--VALIDAR QUE EXISTA LA PERSONA JURIDICA 
if not exists( select 1 from cobis..cl_ente a
where a.en_ente    = @i_compania
and   a.en_subtipo = 'C')
begin
   select @w_error = 1720133
   goto ERROR_FIN  --NO EXISTE COMPANIA
end


/* VALIDAR QUE NO EXISTA OTRA PERSONA CON ESE TIPO Y NUMERO DE DOCUMENTO */
   if exists (select 1 from   cobis..cl_ente
   where  en_tipo_ced = @i_tipo_ced
   and    en_ced_ruc  = @i_ced_ruc
   and    en_ente    != @i_compania)
   begin
      select @w_error = 1720047
      goto ERROR_FIN
   end

-- VALIDACIONES DE CATALOGOS           
exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_sector_economico', @i_valor = @i_sector       if @w_error <> 0 goto ERROR_FIN
exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_actividad_ec',     @i_valor = @i_actividad    if @w_error <> 0 goto ERROR_FIN
exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_tip_soc',          @i_valor = @i_tipo_soc     if @w_error <> 0 goto ERROR_FIN
exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_nivel_egresos',    @i_valor = @i_egresos      if @w_error <> 0 goto ERROR_FIN
exec @w_error = sp_validar_catalogo  @i_tabla = 'cl_pais',             @i_valor = @i_pais         if @w_error <> 0 goto ERROR_FIN


-- SI NO EXISTE, CREAMOS EL REGISTRO EN LA TABLA AUXILIAR
if not exists( select 1 from cobis..cl_ente_aux b
where b.ea_ente = @i_compania) 
begin

   insert into cobis..cl_ente_aux (ea_ente, ea_estado) values (@i_compania, @w_estado_ente)
 
   if @@error <> 0 begin
      select @w_error = 1720133
      goto ERROR_FIN  --NO EXISTE COMPANIA
   end
   
end   
 
if @i_retencion not in ('N', 'S') begin
   select @w_error = 1720114
   goto ERROR_FIN  --PARAMETRO INVALIDO
end
   

-- VALIDA QUE EL REPRESENTANTE LEGAL EXISTA
if @i_rep_legal is not null
and not exists(select 1 from cobis..cl_ente where en_ente= @i_rep_legal and en_subtipo= 'P')
begin
   select @w_error  = 1720078
   goto ERROR_FIN 
end

-- valida si se cambio el oficial, en caso verdadero, valida que no tenga operaciones en cartera
if (@i_oficial <> (select en_oficial from cl_ente where en_ente = @i_compania)) 
   and exists (select 1 from cob_cartera..ca_operacion where op_cliente = @i_compania and op_estado not in (0,3,99,6))
begin
   select @w_error = 1720534
   goto ERROR_FIN 
end

begin tran


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
@s_ssn,              @t_trn,              'A',
getdate(),           @s_user,             @s_term,
@s_srv,              @s_lsrv,             @i_compania,
en_nombre,           en_ced_ruc,          en_actividad,
c_rep_legal,         en_tipo_ced,         en_pais,
@s_ofi,              en_retencion,        en_fecha_mod,
en_oficial,          c_fecha_const,       en_nomlar,
c_tipo_soc,          en_ciudad_emision,   c_total_activos
from cl_ente
where en_ente    = @i_compania

--ERROR EN CREACION DE TRANSACCION DE SERVICIO
if @@error <> 0 begin
   select @w_error = 1720049
   goto ERROR_FIN
end
   
if (@i_tipo_ced = 'RFC') begin
update cobis..cl_ente set 
en_nombre            = isnull(@i_nombre,            en_nombre),
en_ced_ruc           = isnull(@i_ced_ruc,           en_ced_ruc),
en_tipo_ced          = isnull(@i_tipo_ced,          en_tipo_ced),
en_pais              = isnull(@i_pais,              en_pais),
en_fecha_mod         = isnull(@s_date,              en_fecha_mod),
en_retencion         = isnull(@i_retencion,         en_retencion),
en_actividad         = isnull(@i_actividad,         en_actividad),
en_comentario        = isnull(@i_comentario,        en_comentario),
en_sector            = isnull(@i_sector,            en_sector),
c_total_activos      = isnull(@i_total_activos,     c_total_activos),
en_otros_ingresos    = isnull(@i_otros_ingresos,    en_otros_ingresos),
en_origen_ingresos   = isnull(@i_origen_ingresos,   en_origen_ingresos),
en_oficina           = isnull(@i_oficina,           en_oficina),
c_pasivo             = isnull(@i_mnt_pasivo,        c_pasivo),
c_fecha_const        = isnull(@i_fecha_crea,        c_fecha_const),
c_tipo_soc           = isnull(@i_tipo_soc,          c_tipo_soc ),
en_firma_electronica = isnull(@i_firma_electronica, en_firma_electronica),
c_rep_legal          = isnull(@i_rep_legal,         c_rep_legal),
en_oficial           = isnull(@i_oficial,           en_oficial),
en_ciudad_emision    = isnull(@i_ciudad_emision,    en_ciudad_emision),
en_ente_migrado      = isnull(@i_migrado,           en_ente_migrado),
en_nit               = isnull(@i_ced_ruc,           en_nit)
where en_ente    = @i_compania
end
else
begin
update cobis..cl_ente set 
en_nombre              = isnull(@i_nombre,            en_nombre),
en_ced_ruc             = isnull(@i_ced_ruc,           en_ced_ruc),
en_tipo_ced            = isnull(@i_tipo_ced,          en_tipo_ced),
en_pais                = isnull(@i_pais,              en_pais),
en_fecha_mod           = isnull(@s_date,              en_fecha_mod),
en_retencion           = isnull(@i_retencion,         en_retencion),
en_actividad           = isnull(@i_actividad,         en_actividad),
en_comentario          = isnull(@i_comentario,        en_comentario),
en_sector              = isnull(@i_sector,            en_sector),
c_total_activos        = isnull(@i_total_activos,     c_total_activos),
en_otros_ingresos      = isnull(@i_otros_ingresos,    en_otros_ingresos),
en_origen_ingresos     = isnull(@i_origen_ingresos,   en_origen_ingresos),
en_oficina             = isnull(@i_oficina,           en_oficina),
c_pasivo               = isnull(@i_mnt_pasivo,        c_pasivo),
c_fecha_const          = isnull(@i_fecha_crea,        c_fecha_const),
c_tipo_soc             = isnull(@i_tipo_soc,          c_tipo_soc ),
en_firma_electronica   = isnull(@i_firma_electronica, en_firma_electronica),
c_rep_legal            = isnull(@i_rep_legal,         c_rep_legal),
en_tipo_doc_tributario = isnull(@i_tipo_ced,          en_tipo_doc_tributario),    
en_rfc                 = isnull(@i_ced_ruc,           en_rfc),
en_tipo_iden           = isnull(@i_tipo_iden,         en_tipo_iden),
en_numero_iden         = isnull(@i_numero_iden,       en_numero_iden),
en_oficial             = isnull(@i_oficial,           en_oficial),
en_ciudad_emision      = isnull(@i_ciudad_emision,    en_ciudad_emision),
en_ente_migrado        = isnull(@i_migrado,           en_ente_migrado),
en_nomlar              = isnull(@i_nombre,            en_nomlar),  --PQU integración, por el originador se necesita el en_nomlar en persona jurídica
en_nit                 = isnull(@i_ced_ruc,           en_nit)
where en_ente    = @i_compania
end

if @@error <> 0 begin
   select @w_error = 1720128
   goto ERROR_FIN
end
      
update cobis..cl_ente_aux set 
ea_estado              = isnull(@i_ea_estado,          ea_estado),
ea_actividad           = isnull(@i_ea_actividad,       ea_actividad),
ea_remp_legal          = isnull(@i_ea_remp_legal,      ea_remp_legal),
ea_num_serie_firma     = isnull(@i_firma_electronica,  ea_num_serie_firma),
ea_ct_operativo        = isnull(@i_ct_operativos,      ea_ct_operativo),
ea_ct_ventas           = isnull(@i_ct_ventas,          ea_ct_ventas),
ea_fatca               = isnull(@i_fatca,              ea_fatca),
ea_crs                 = isnull(@i_crs,                ea_crs),
ea_s_inversion_ifi     = isnull(@i_s_inversion_ifi,    ea_s_inversion_ifi),
ea_s_inversion         = isnull(@i_s_inversion,        ea_s_inversion),
ea_ifid                = isnull(@i_ifid,               ea_ifid),
ea_c_merc_valor        = isnull(@i_c_merc_valor,       ea_c_merc_valor),
ea_c_nombre_merc_valor = isnull(@i_c_nombre_merc_valor,ea_c_nombre_merc_valor),
ea_ong_sfl             = isnull(@i_ong_sfl,            ea_ong_sfl),
ea_ifi_np              = isnull(@i_ifi_np,             ea_ifi_np),
ea_nivel_egresos       = isnull(@i_egresos,            ea_nivel_egresos),
ea_ventas              = isnull(@i_ventas,             ea_ventas)
where ea_ente = @i_compania
     
if @@error <> 0 begin
   select @w_error = 1720128
   goto ERROR_FIN /* 'Error en actualizacion de compania'*/
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
@s_ssn,              @t_trn,              'D',
getdate(),           @s_user,             @s_term,
@s_srv,              @s_lsrv,             @i_compania,
en_nombre,           en_ced_ruc,          en_actividad,
c_rep_legal,         en_tipo_ced,         en_pais,
@s_ofi,              en_retencion,        en_fecha_mod,
en_oficial,          c_fecha_const,       en_nomlar,
c_tipo_soc,          en_ciudad_emision,   c_total_activos
from cl_ente
where en_ente    = @i_compania

--ERROR EN CREACION DE TRANSACCION DE SERVICIO
if @@error <> 0 begin
   select @w_error = 1720049
   goto ERROR_FIN
end

commit tran

return 0

ERROR_FIN:

while @@trancount > 0 rollback

exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = '',
@t_from    = @w_sp_name,
@i_num     = @w_error,
@i_msg     = null

return @w_error

go
