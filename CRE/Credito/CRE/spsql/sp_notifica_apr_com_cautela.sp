/************************************************************************/
/*  Archivo:                         sp_notifica_apr_com_cautela.sp     */
/*  Stored procedure:                sp_notifica_apr_com_cautela        */
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
/*  Notificaciones correo electronico Aprobacion Comite Clientes Lista  */
/*  Cautela                                                             */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR           RAZON                           */
/*      11-11-2022      PJA           Emision Inicial - S732928         */
/************************************************************************/
use cob_credito
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_notifica_apr_com_cautela')
   drop proc sp_notifica_apr_com_cautela
go
CREATE PROCEDURE sp_notifica_apr_com_cautela (
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
        @t_rty                           char(1)      = null,
        @t_debug                         char(1)      = 'N',
        @t_file                          varchar(14)  = null,
        @t_from                          varchar(30)  = null,
        @t_trn                           int          = null,
        @t_show_version                  bit          = 0,
        @i_id_inst_proc                  int,
        @i_id_inst_act                   int,
        @i_id_empresa                    int          = null,
        @o_id_resultado                  smallint     out      --1 Ok --2 Devolver



        )
as
declare 
        @w_sp_name                   varchar(32),
        @w_sp_msg                    varchar(100),
        @w_return                    int,
        @w_error                     int,       
        @w_subject                   varchar(250),
        @w_desc_actividad            varchar(250),
        @w_desc_excepcion            varchar(250),
        @w_codigo_proc               int,
        @w_version_proc              int,       
        @w_codigo_alterno            varchar(50),
        @w_tramite                   int,       
        @w_codigo_act                int,
        @w_asig_principal            char(1),
        @w_es_todo_comite            char(1),
        @w_oficina_crea              int,
        @w_id_destinatario           int,
        @w_nombre_oficial            varchar(64),
        @w_nombre_rol                varchar(64),
        @w_nombre_rol_com            varchar(64),
        @w_id_usuario_cabecera       int,  
        @w_ente                      int,
        @w_id                        int,
        @w_tipo_destinatario         varchar(10),
        @w_template                  int,
        @w_xml                       nvarchar(2000),
        @w_xml_aux                   nvarchar(2000),
        @w_email_oficial             varchar(2000),
        @w_email_oficial_aux         varchar(2000),
        @w_email_oficial_auxs        varchar(2000),
        @w_email_destinatario        varchar(2000)


select  @w_sp_name             = 'sp_notifica_apr_com_cautela',
        @w_nombre_oficial      = '',
        @w_nombre_rol          = '',
        @w_nombre_rol_com      = '',
        @w_email_oficial       = '',
        @w_email_oficial_aux   = '',
        @w_email_oficial_auxs  = '',
        @w_xml                 = '', 
        @w_xml_aux             = '',
        @w_email_destinatario  = '',
        @w_ente                = 0,
        @w_id                  = 0

--Parametro Actividad
select  @w_desc_actividad = pa_char from cobis..cl_parametro where pa_producto = 'CRE' and pa_nemonico = 'AAPRCC'

--Parametro Notificaciones
select  @w_subject = pa_parametro from cobis..cl_parametro where pa_producto = 'CRE' and pa_nemonico = 'NAPRCC'

--Template
select @w_template = te_id from cobis..ns_template  where te_nombre  = 'CorreoAprobacionComiteCautela.xslt'

--Parametro Excepcion
select  @w_desc_excepcion = pa_char from cobis..cl_parametro where pa_producto = 'CRE' and pa_nemonico = 'EXCCLC'

      
--Actividad Aprobacion Comite Clientes Lista Cautela
select @w_codigo_proc     = io_codigo_proc,
       @w_version_proc    = io_version_proc,
       @w_oficina_crea    = io_oficina_inicio ,
       @w_codigo_alterno  = io_codigo_alterno,
       @w_tramite         = io_campo_3
  from cob_workflow..wf_inst_proceso, cob_workflow..wf_inst_actividad
 where io_id_inst_proc = ia_id_inst_proc
   and io_id_inst_proc = @i_id_inst_proc
   and ia_id_inst_act  = @i_id_inst_act


--Excepcion Politica
if(OBJECT_ID('tempdb..#temp') is not null)
   drop table #temp
   
select 'inst_act' = max(ia_id_inst_act), ia_id_paso
  into #temp
  from cob_workflow..wf_inst_actividad
 where ia_id_inst_proc = @i_id_inst_proc 
   and ia_id_inst_act <= @i_id_inst_act
 group by ia_id_paso

if exists (select distinct @w_tramite, rl_acronym, 'P' , TE.inst_act
            from #temp TE
           inner join cob_pac..bpl_rule_process_his RPH on RPH.rph_id_inst_proc = @i_id_inst_proc and TE.inst_act = RPH.rph_id_inst_act
           inner join cob_pac..bpl_rule RU  on RU.rl_id = RPH.rph_rule_id
           where RPH.rph_valor = 'EXCEPCION'
             and ('S' is null or 'S' = RPH.rph_ultima_evaluacion)
             and rl_acronym = @w_desc_excepcion )

begin

    --Tabla Temporal
    if exists (select 1 from sysobjects where name = '#tmp_destinatario')
       drop table #tmp_destinatario
       
    create table #tmp_destinatario
    (
      de_id_oficial      int null,
      de_oficial_inst    varchar(64)  null,
      de_em_oficial_inst varchar(64)  null,
      de_nombre_rol      varchar(64)  null
    )

    --Rol Destinatario Actividad
    select @w_codigo_act = ac_codigo_actividad 
      from cob_workflow..wf_actividad 
     where ac_nombre_actividad = @w_desc_actividad 

    select @w_id_destinatario   = de_id_destinatario,
           @w_tipo_destinatario = de_tipo_destinatario,
           @w_asig_principal    = de_asig_principal, 
           @w_es_todo_comite    = de_es_todo_comite
         from cob_workflow..wf_destinatario 
        where de_codigo_proceso = @w_codigo_proc 
          and de_version_proceso = @w_version_proc 
          and de_codigo_actividad = @w_codigo_act
       
    if (@w_tipo_destinatario = 'COM')
    begin   
       if (@w_asig_principal = 'S')
       begin
        select @w_id_usuario_cabecera = ro_id_usuario_cabecera,
               @w_nombre_rol_com      = ro_nombre_rol
          from cob_workflow..wf_rol 
         where ro_id_rol = @w_id_destinatario 
           and ro_es_comite = 1

        select @w_nombre_rol = @w_nombre_rol_com
        
        insert into #tmp_destinatario
        select de_id_oficial      = @w_id_usuario_cabecera,
               de_oficial_inst    = (select fu_nombre from cobis..cl_funcionario where fu_funcionario = @w_id_usuario_cabecera),
               de_em_oficial_inst = (select fu_correo_electronico from cobis..cl_funcionario where fu_funcionario = @w_id_usuario_cabecera),
               de_nombre_rol      = @w_nombre_rol_com
       end
       
       if (@w_es_todo_comite = 'S')
        begin
            select @w_nombre_rol_com  = ro_nombre_rol
              from cob_workflow..wf_rol 
             where ro_id_rol = @w_id_destinatario 
               and ro_es_comite = 1

            select @w_nombre_rol = @w_nombre_rol_com

        insert into #tmp_destinatario
        select de_id_oficial      = ur_id_usuario,
               de_oficial_inst    = (select fu_nombre from cobis..cl_funcionario where fu_funcionario = ur_id_usuario),
               de_em_oficial_inst = (select fu_correo_electronico from cobis..cl_funcionario where fu_funcionario = ur_id_usuario),
               de_nombre_rol      = ro_nombre_rol 
        from cob_workflow..wf_rol,
             cob_workflow..wf_usuario_rol,
             cob_workflow..wf_usuario
        where ro_id_rol     = ur_id_rol
          and ur_id_usuario = us_id_usuario  
              and ro_id_rol     = @w_id_destinatario
          and ro_es_comite  = 1
          and (us_estado_usuario  = 'ACT' or (us_estado_usuario = 'INA' and ur_id_usuario_sustituto in (select us_id_usuario from cob_workflow..wf_usuario where us_estado_usuario = 'ACT')))
    end
    end 
    else if(@w_tipo_destinatario = 'USR')
    begin 
   
        insert into #tmp_destinatario
        select top 1 de_id_oficial      = ur_id_usuario,
                     de_oficial_inst    = (select fu_nombre from cobis..cl_funcionario where fu_funcionario = ur_id_usuario),
                     de_em_oficial_inst = (select fu_correo_electronico from cobis..cl_funcionario where fu_funcionario = ur_id_usuario),
                     de_nombre_rol      = ro_nombre_rol
            from cob_workflow..wf_rol,
                 cob_workflow..wf_usuario_rol,
                 cob_workflow..wf_usuario
            where ro_id_rol     = ur_id_rol
              and ur_id_usuario = us_id_usuario
              and ur_id_usuario = @w_id_destinatario
              --and ro_id_rol     = @w_id_destinatario
              --and us_oficina    = @w_oficina_crea
              and (us_estado_usuario  = 'ACT' or (us_estado_usuario = 'INA' and ur_id_usuario_sustituto in (select us_id_usuario from cob_workflow..wf_usuario where us_estado_usuario = 'ACT')))                             
          
        select @w_nombre_rol = de_nombre_rol from #tmp_destinatario     
    end
    else
    begin   
        insert into #tmp_destinatario
        select de_id_oficial      = ur_id_usuario,
               de_oficial_inst    = (select fu_nombre from cobis..cl_funcionario where fu_funcionario = ur_id_usuario),
               de_em_oficial_inst = (select fu_correo_electronico from cobis..cl_funcionario where fu_funcionario = ur_id_usuario),
               de_nombre_rol      = ro_nombre_rol
         from cob_workflow..wf_rol,
              cob_workflow..wf_usuario_rol,
              cob_workflow..wf_usuario
        where ro_id_rol     = ur_id_rol
          and ur_id_usuario = us_id_usuario  
          --and ur_id_usuario = @w_id_destinatario
          and ro_id_rol     = @w_id_destinatario
          --and us_oficina    = @w_oficina_crea
          and (us_estado_usuario  = 'ACT' or (us_estado_usuario = 'INA' and ur_id_usuario_sustituto in (select us_id_usuario from cob_workflow..wf_usuario where us_estado_usuario = 'ACT')))   

        select @w_nombre_rol_com  = ro_nombre_rol
          from cob_workflow..wf_rol 
         where ro_id_rol = @w_id_destinatario 

        select @w_nombre_rol = @w_nombre_rol_com
    end  
     
    select @w_xml = '<?xml version="1.0" encoding="UTF-8"?><data>'

    while 1 = 1
    begin
        select top 1 @w_id = de_id_oficial, @w_nombre_oficial = de_oficial_inst
         from #tmp_destinatario
         where de_id_oficial > @w_id
         order by de_id_oficial asc     

        if @@rowcount = 0
            break

       select @w_xml_aux = @w_xml_aux + '<oficial><nombreOficial>'+ UPPER(@w_nombre_oficial) + '</nombreOficial></oficial>'
    end
	
    select @w_xml = @w_xml + @w_xml_aux + '<codigoAlterno>' + @w_codigo_alterno + '</codigoAlterno><codigoTramite>' + convert(varchar(10),@w_tramite) + '</codigoTramite></data>' 

    --Email To
    select @w_email_oficial = (select STUFF((SELECT CAST(';' AS varchar(MAX)) + de_em_oficial_inst from #tmp_destinatario FOR XML PATH('') ), 1, 1, ''))

    select @w_email_destinatario = @w_email_oficial   

    if isnull(@w_email_destinatario,'') = '' or @w_email_destinatario = ''
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
         @i_to              = @w_email_destinatario,
         @i_cc              = null,
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
        select @o_id_resultado = 2 --Devolver
        return @w_error
    end
   
end
select @o_id_resultado = 1 --Ok

return 0

ERROR_FIN:
exec cobis..sp_cerror
    @t_debug    = @t_debug,
    @t_file     = @t_file,
    @t_from     = @w_sp_name,
    @i_msg      = @w_sp_msg,
    @i_num      = @w_error  

select @o_id_resultado = 2 --Devolver	
return @w_error

go
