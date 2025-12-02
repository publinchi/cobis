/************************************************************************/
/*  Archivo:                         sp_notifica_cli_inact.sp           */
/*  Stored procedure:                sp_notifica_cli_inact              */
/*  Base de datos:                   cob_credito                        */
/*  Producto:                        Credito                            */
/*  Disenado por:                    PJA                                */
/*  Fecha de escritura:              11-11-2022                         */
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
/*                          PROPOSITO                                   */
/*  Notificaciones correo electronico Clientes Inactivos                */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      11-11-2022      PJA             Emision Inicial - S732902       */
/*      11-14-2023      BDU             R219316 Aumentar tamaño XML     */
/*      04-04-2024      BDU             R231536 Corregir query jefe ofi */
/************************************************************************/
use cob_credito
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_notifica_cli_inact')
   drop proc sp_notifica_cli_inact
go
CREATE PROCEDURE sp_notifica_cli_inact (
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
        @t_show_version                  bit          = 0,
        @i_tramite                       int,
        @i_oficina_crea                  int
        )
as
declare 
        @w_sp_name                   varchar(32),
        @w_sp_msg                    varchar(100),
        @w_return                    int,
        @w_error                     int,       
        @w_subject                   varchar(250),
        @w_nombre_rol                varchar(64),
        @w_tramite                   int,
        @w_oficina_crea              int,
        @w_grupo                     int,
        @w_nombre_grupo              varchar(160),
        @w_oficial_gr                varchar(200),
        @w_em_oficial_gr             varchar(60),
        @w_oficial_nsup              varchar(200),
        @w_em_oficial_nsup           varchar(60),
        @w_id_rol                    int,      
        @w_oficial_inst              varchar(200),
        @w_em_oficial_inst           varchar(60),
        @w_fecha_desembolso          datetime,
        @w_ente                      int,
        @w_nomlar                    varchar(200),
        @w_template                  int,
        @w_xml                       varchar(max),
        @w_xml_aux                   varchar(max),
        @w_email_oficial             varchar(2000)

select  @w_sp_name             = 'sp_notifica_cli_inact',
        @w_email_oficial       = '',
        @w_xml                 = '', 
        @w_xml_aux             = ''

--Parametro Notificaciones
select  @w_subject = pa_parametro from cobis..cl_parametro where pa_producto = 'CRE' and pa_nemonico = 'NCINA'

--Template
select @w_template = te_id from cobis..ns_template  where te_nombre  = 'CorreoClientesInactivos.xslt'
    
--Rol Jefe AGENCIA
select @w_nombre_rol = 'JEFE DE AGENCIA'

--Tramite y Oficina de la Solicitud
select @w_tramite = isnull(@i_tramite,0),
       @w_oficina_crea = isnull(@i_oficina_crea,0)

-- Oficial Grupo
select top 1 @w_grupo = tg_grupo from cob_credito..cr_tramite_grupal WHERE tg_tramite = @w_tramite

select @w_nombre_grupo    = gr_nombre,
       @w_oficial_gr      = (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial where fu_funcionario = oc_funcionario and oc_oficial = gr_oficial),
       @w_em_oficial_gr   = (select fu_correo_electronico from cobis..cl_funcionario, cobis..cc_oficial where fu_funcionario = oc_funcionario and oc_oficial = gr_oficial),
       @w_oficial_nsup    = (select fu_nombre from cobis..cl_funcionario, cobis..cc_oficial where fu_funcionario = oc_funcionario and oc_oficial = (select oc_ofi_nsuperior from cobis..cc_oficial where oc_oficial = gr_oficial)),
       @w_em_oficial_nsup = (select fu_correo_electronico from cobis..cl_funcionario, cobis..cc_oficial where fu_funcionario = oc_funcionario and oc_oficial = (select oc_ofi_nsuperior from cobis..cc_oficial where oc_oficial = gr_oficial))         
 from  cobis..cl_grupo
where  gr_grupo = @w_grupo

--Oficial Solicitud
 select @w_oficial_inst    = cf.fu_nombre, 
        @w_em_oficial_inst = cf.fu_correo_electronico
 from cob_workflow.dbo.wf_rol wr with (nolock)       
 inner join cob_workflow.dbo.wf_usuario_rol wur with (nolock)  on wr.ro_id_rol = wur.ur_id_rol 
 inner join cob_workflow.dbo.wf_usuario wu with (nolock) on wu.us_id_usuario = wur.ur_id_usuario 
 inner join cobis.dbo.cl_funcionario cf with (nolock) on cf.fu_login = wu.us_login 
 where wr.ro_nombre_rol = @w_nombre_rol
 and us_oficina         = @w_oficina_crea
 and (us_estado_usuario  = 'ACT' or (us_estado_usuario = 'INA' and ur_id_usuario_sustituto in (select us_id_usuario from cob_workflow..wf_usuario where us_estado_usuario = 'ACT')))

--Fecha Desembolso
select @w_fecha_desembolso = op_fecha_liq from cob_cartera..ca_operacion where op_tramite = @w_tramite

--Clientes Participa Ciclo N
--Tabla Temporal
if exists (select 1 from sysobjects where name = '#tmp_ente')
   drop table #tmp_ente
   
create table #tmp_ente
(
  tg_cliente int ,
  tg_nombre  varchar(200)
)

insert into #tmp_ente
select tg_cliente,
       tg_nombre = (select en_nomlar from cobis..cl_ente where en_ente = tg_cliente) 
  from cob_credito..cr_tramite_grupal, cobis..cl_ente
 where tg_tramite = @w_tramite
   and tg_cliente = en_ente
   and tg_participa_ciclo = 'N'
   order by tg_cliente asc
  
select @w_ente = 0

select @w_xml = '<?xml version="1.0" encoding="UTF-8"?><data><nombreOficialGr>' + UPPER(@w_oficial_gr) + '</nombreOficialGr><fechaDesembolso>' + convert(varchar(10),@w_fecha_desembolso,101) + '</fechaDesembolso><codigoGrupo>' + convert(varchar(10),@w_grupo) + '</codigoGrupo><nombreGrupo>'+ UPPER(@w_nombre_grupo) + '</nombreGrupo>'

while 1 = 1
begin
    select top 1 @w_ente = tg_cliente, 
                 @w_nomlar = tg_nombre
      from #tmp_ente
     where tg_cliente > @w_ente
     order by tg_cliente asc     

    if @@rowcount = 0
        break

    select @w_xml_aux = @w_xml_aux + '<cliente><codigoCliente>' + convert(varchar(10),@w_ente) + '</codigoCliente><nombreCliente>'+ UPPER(@w_nomlar) + '</nombreCliente></cliente>'
end

select @w_xml = @w_xml + @w_xml_aux + '</data>'    
                          
--Email To
select @w_email_oficial = @w_em_oficial_gr + ';'+ @w_em_oficial_nsup   

if isnull(@w_email_oficial,'') = '' or @w_email_oficial = ''
begin
    select @w_error = 1720580
    goto ERROR_FIN
end  


exec @w_error = cobis..sp_despacho_ins
     @i_cliente         = @w_ente,
     @i_template        = @w_template,
     @i_servicio        = 1,
     @i_estado          = 'P',
     @i_tipo            = 'MAIL',
     @i_tipo_mensaje    = 'I',
     @i_prioridad       = 1,
     @i_from            = null,
     @i_to              = @w_email_oficial,
     @i_cc              = @w_em_oficial_inst,
     @i_bcc             = null,
     @i_subject         = @w_subject,
     @i_body            = @w_xml,
     @i_content_manager = 'HTML',
     @i_retry           = 'S',
     @i_fecha_envio     = null,
     @i_hora_ini        = null,
     @i_hora_fin        = null,
     @i_tries           = 0,
     @i_max_tries       = 2

if @w_error <> 0
begin
    return @w_error
end

return 0

ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_error  
return @w_error

go
