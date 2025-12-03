/************************************************************************/
/*   Archivo:            sp_cliente_activo_wf.sp                        */
/*   Stored procedure:   sp_cliente_activo_wf                           */
/*   Base de datos:      cob_workflow                                   */
/*   Producto:               Workflow                                   */
/*   Disenado por:                                                      */
/*   Fecha de escritura:     14-Mayo-19                                 */
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
/*   Este programa procesa Verifica si un solicitante es un cliente,    */
/*   caso contrario el flujo no arranca.                                */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*      FECHA           AUTOR        RAZON                              */
/*      14/05/2019      WTOLEDO      Emision Inicial                    */
/************************************************************************/

use cob_workflow
go

if exists (select 1 from sysobjects where name = 'sp_cliente_activo_wf')
   drop proc sp_cliente_activo_wf
go

CREATE PROCEDURE sp_cliente_activo_wf
(
    @s_ssn                int          = null,
    @s_user               varchar(30)  = null,
    @s_sesn               int          = null,
    @s_term               varchar(30)  = null,
    @s_date               datetime     = null,
    @s_srv                varchar(30)  = null,
    @s_lsrv               varchar(30)  = null,
    @s_ofi                smallint     = null,
    @t_trn                int          = null,
    @t_debug              char(1)      = 'N',
    @t_file               varchar(14)  = null,
    @t_from               varchar(30)  = null,
    @s_rol                smallint     = null,
    @s_org_err            char(1)      = null,
    @s_error              int          = null,
    @s_sev                tinyint      = null,
    @s_msg                descripcion  = null,
    @s_org                char(1)      = null,
    @t_show_version       bit          = 0, -- Mostrar la version del programa
    @t_rty                char(1)      = null,
    @i_operacion          char(1)      = 'I',
    @i_login              NOMBRE       = null,
    @i_id_proceso         smallint     = null,
    @i_version            smallint     = null,
    @i_nombre_proceso     NOMBRE       = null,
    @i_id_actividad       int          = null,
    @i_campo_1            int          = null,
    @i_campo_2            varchar(255) = null,
    @i_campo_3            int          = null,
    @i_campo_4            varchar(10)  = null,
    @i_campo_5            int          = null,
    @i_campo_6            money        = null,
    @i_campo_7            varchar(255) = null,
    @i_ruteo              char(1)      = 'M',
    @i_ofi_inicio         smallint     = null,
    @i_ofi_entrega        smallint     = null,
    @i_ofi_asignacion     smallint     = null,
    @i_id_inst_act_padre  int          = null,
    @i_comentario         varchar(255) = null,
    @i_id_usuario         int          = null,
    @i_id_rol             int          = null,
    @i_id_empresa         smallint     = null,
    @i_inst_padre         int          = null,
    @i_inst_inmediato     int          = null,
    @i_vinculado          char(1)      = null,
    @o_siguiente          int          = null out

)As
declare
    @w_sp_name            varchar(64),
    @w_id_proceso         smallint,
    @w_version            smallint,
    @w_tipo               varchar(30),
    @w_grupo              int,
    @w_ente               INT,
    @w_ttramite           varchar(10),
    @w_return             int,
    @w_reunion            varchar(125),
    @w_oficial_grupo      INT,
    @w_oficial_solicitud  INT,
    @w_ecasado            catalogo,
    @w_eunion             catalogo,
    @w_rcony              SMALLINT,
    @w_count              INT

select @w_sp_name = 'sp_cliente_activo_wf'

if @t_show_version = 1
begin
    print 'Stored procedure sp_cliente_activo_wf, Version 1.0.0.0'
    return 0
end

-- Si no se envian ni el id, ni la version del proceso.

if (@i_id_proceso is null) and (@i_version is null)
begin
     -- Por lo menos se debio haber enviado el nombre del mismo.
    if @i_nombre_proceso is not null
    begin
        select @w_id_proceso = pr_codigo_proceso,
               @w_version    = pr_version_prd
        from wf_proceso
        where pr_nombre_proceso = @i_nombre_proceso
    end
    else
    begin
        -- Pero como no se envio ni el id, ni la version y tampoco
        -- el nombre, entonces se despliega un mensaje de error y se
        -- sale del stored procedure.
      /*  exec cobis..sp_cerror
             @i_num  = 3107525,
             @t_from = @w_sp_name*/
        return 3107525
    end
end
else
begin
    -- Se almacenan tanto el id como la version en variables de trabajo.
    select @w_id_proceso = @i_id_proceso
    select @w_version    = pr_version_prd
    from wf_proceso
    where pr_codigo_proceso = @i_id_proceso
end

SELECT @w_ttramite = @i_campo_4

/*
select @w_ttramite = isnull(@w_ttramite, '')
if @w_ttramite = '' return 0
*/

PRINT 'el tipo de tramite es:  ' + convert(VARCHAR(10), @w_ttramite)

IF(@w_ttramite = 'GRUPAL')
BEGIN

    SELECT @w_grupo   = convert(int, @i_campo_1)

    --MTA Validacion de solicitud rechazada
     -- Se elimina validación por #REQ98119
    /*IF EXISTS (SELECT 1 FROM cob_credito..cr_tramite, cob_credito..cr_deudores
           WHERE tr_tramite = de_tramite
           AND tr_estado in ('X','Z')
           AND de_cliente =  @w_grupo)
    begin
        PRINT 'Error: No se puede crear una solicitud de un grupo con solicitud previa rechazada'
        return 70011016
    end*/

    IF EXISTS( SELECT 1 FROM cobis..cl_grupo WHERE gr_grupo=@w_grupo AND gr_estado='C')
       BEGIN
         PRINT 'Error: El Grupo tiene estado Cancelado'

         /*exec cobis..sp_cerror
            @i_num  = 103147,
            @t_from = @w_sp_name*/
        return 103147

       end

    exec @w_return = cob_pac..sp_grupo_busin
    @i_operacion ='V',
    @i_grupo    = @w_grupo,
    @t_trn      = 800

    if @w_return <> 0
    begin
        /* exec cobis..sp_cerror
            @i_num  = 208925, --VALIDACION COMITE
            @t_from = @w_sp_name*/
        return 208925
    end

    SELECT @w_ente = 0
    WHILE 1 = 1
    BEGIN

       SELECT TOP 1 @w_ente = cg_ente FROM cobis..cl_cliente_grupo
       WHERE cg_grupo = @w_grupo AND cg_estado='V'
       AND cg_ente > @w_ente
       ORDER BY cg_ente ASC

       IF @@ROWCOUNT = 0
          BREAK

       IF EXISTS( SELECT 1 FROM cobis..cl_ente_aux WHERE ea_ente = @w_ente AND ea_estado <> 'A')
       BEGIN
         PRINT 'Error: un integrante del grupo no es un Cliente'

         /*exec cobis..sp_cerror
            @i_num  = 103145,
            @t_from = @w_sp_name*/
        return 103145

       end

       SELECT @i_vinculado = en_vinculacion FROM cobis..cl_ente WHERE en_ente = @w_ente

       if (@i_vinculado = 'S')
       begin
            /* Error, uno de los integrantes del grupo es Vinculado */
            return 103158

       end


    END

    select @w_reunion = gr_dir_reunion from cobis..cl_grupo where gr_grupo = @w_grupo

    if ((@w_reunion IS NULL) or (@w_reunion = ' '))    -- Lugar de reunion
    BEGIN
    --PRINT'VALIDAR Lugar de Reunion.'+CONVERT(VARCHAR(30),@w_porcentaje)
      /*exec cobis..sp_cerror
            @i_num  = 208933, --EL GRUPO NO CUENTA CON LUGAR DE REUNION, POR FAVOR INGRESE
            @t_from = @w_sp_name*/
        return 208933
    END

    if exists (select 1 from wf_inst_proceso where io_campo_1 = @w_grupo and io_estado = 'EJE' and io_campo_7 = 'S')
    begin
        PRINT 'Error el grupo tiene un trámite en ejecución.'
       /* exec cobis..sp_cerror
            @i_num  = 103156,
            @t_from = @w_sp_name*/
        return 103156
    end

    PRINT 'PROBLEMA OFICIAL @w_grupo '+convert(VARCHAR(20),@w_grupo)
    PRINT 'PROBLEMA OFICIAL @s_user '+convert(VARCHAR(20),@s_user)

    /* Oficial diferente al del grupo ***/
    SELECT @w_oficial_grupo = gr_oficial
    FROM cobis..cl_grupo
    WHERE gr_grupo = @w_grupo

    SELECT @w_oficial_solicitud = oc_oficial
    FROM cobis..cc_oficial,cobis..cl_funcionario
    WHERE oc_funcionario = fu_funcionario
    AND fu_login = @s_user

        PRINT 'PROBLEMA OFICIAL  @w_oficial_solicitud '+convert(VARCHAR(20),@w_oficial_solicitud)
        PRINT 'PROBLEMA OFICIAL  @w_oficial_grupo '+convert(VARCHAR(20),@w_oficial_grupo)


    IF @w_oficial_grupo <> @w_oficial_solicitud
    BEGIN
       PRINT 'La solicitud tiene otro oficial diferente al del grupo'
       /*exec cobis..sp_cerror
            @i_num  = 101115,
            @t_from = @w_sp_name*/
       return 101115
    END

    /********* Cliente casado y sin conyugue ********/
    SELECT @w_ecasado = pa_char from cobis..cl_parametro WHERE pa_nemonico = 'CDA' AND pa_producto='CLI'
    select @w_eunion = pa_char from cobis..cl_parametro WHERE pa_nemonico = 'UNL' AND pa_producto='CLI'
    select @w_rcony = pa_tinyint from cobis..cl_parametro where pa_nemonico = 'CONY' AND pa_producto='CLI'

    IF EXISTS (SELECT 1 FROM cobis..cl_ente CL
               WHERE en_ente IN (SELECT cg_ente FROM cobis..cl_cliente_grupo WHERE cg_grupo = @w_grupo AND cg_estado = 'V')
               AND p_estado_civil IN (@w_ecasado, @w_eunion)
               AND en_ente NOT IN (SELECT in_ente_d FROM cobis..cl_instancia
                                   WHERE in_ente_d = CL.en_ente
                                   AND in_relacion IN (@w_rcony)))

    BEGIN
    PRINT 'Existe un Cliente casado y sin datos de Conyugue'
    /*exec cobis..sp_cerror
        @i_num  = 103157,
        @t_from = @w_sp_name*/
        return 103157
    END


end -- @w_ttramite = 'GRUPAL'
else
begin -- INDIVIDUAL
    -- VALIDA QUE EL CLIENTE NO TENGA OTRA SOLICITUD EN CURSO
    select @w_count = count(1)
    from   wf_inst_proceso
    inner  join wf_proceso on pr_codigo_proceso = io_codigo_proc and pr_producto = 'CCA'
    where  io_campo_1 = @i_campo_1
    and    io_estado in ('SUS','EJE')
    if @w_count = 1
    begin
        set @w_id_proceso = 0
        select @w_id_proceso = io_id_inst_proc
        from   wf_inst_proceso
        inner  join wf_proceso on pr_codigo_proceso = io_codigo_proc and pr_producto = 'CCA'
        where  io_campo_1 = @i_campo_1
        and    io_estado  = 'EJE'
        and    isnull(io_campo_3,0) = 0 -- SIN TRAMITE ATADO

        if isnull(@w_id_proceso,0) > 0 -- SIGNIFICA QUE TIENE UNA y SOLO UNA SOLICITUD SIN TRAMITE, ENTONCES SE PROCEDE A LA CANCELACION
        begin
            -- CANCELA LA SOLICITUD
            exec @w_return = sp_m_inst_proceso_masivo_wf @t_trn = 73503, @i_id_inst_proc = @w_id_proceso,
                             @i_operacion = 'C', @i_id_rol = @s_rol, @i_id_empresa = @i_id_empresa, @i_sub_operacion = 'A',
                             @i_numero = 0, @i_categoria = '1', @i_oficial = @s_user, @i_delete_temp_obs = ' ',
                             @i_texto_completo = 'ELIMINADO POR INICIO DE PROCESO AUTOMATICO',
                             @s_srv = @s_srv, @s_user = @s_user, @s_term = @s_term, @s_ofi = @s_ofi, @s_rol = @s_rol,
                             @s_ssn = @s_ssn, @s_lsrv = @s_lsrv, @s_date = @s_date, @s_sesn = @s_sesn, @s_org = @s_org
            if @w_return <> 0
            begin
                print 'Ya existe otra solicitud en proceso para el mismo cliente.'
                return 2110110
            end

            -- ELIMINA TABLAS DE LA SOLICITUD
            -- Variables
            delete wf_mod_variable where mv_id_inst_proc = @w_id_proceso
            delete wf_variable_actual where va_id_inst_proc = @w_id_proceso
            -- Detalle de evaluación de reglas
            delete cob_pac..bpl_rule_process_his where rph_id_inst_proc = @w_id_proceso
            -- Observaciones
            delete wf_ob_lineas
            where  ol_id_asig_act in (select aa_id_asig_act
                                      from   wf_asig_actividad
                                      where  aa_id_inst_act in (select ia_id_inst_act
                                                                from   wf_inst_actividad
                                                                where  ia_id_inst_proc = @w_id_proceso))
            delete wf_observaciones
            where  ob_id_asig_act in (select aa_id_asig_act
                                      from   wf_asig_actividad
                                      where  aa_id_inst_act in (select ia_id_inst_act
                                                                from   wf_inst_actividad
                                                                where  ia_id_inst_proc = @w_id_proceso))
            -- Requisito actividad
            delete wf_requisito_actividad where rc_id_inst_proceso = @w_id_proceso
            delete wf_requisito_actividad_tmp where rc_id_inst_proceso =@w_id_proceso
            delete wf_req_inst where ri_id_inst_proc = @w_id_proceso
            -- Atributos asociados a requisitos
            delete wf_attr_doc_inst where adi_id_inst_proc = @w_id_proceso
            -- Ejecución de Paralelas
            delete wf_parallel_start_end where pse_inst_proceso = @w_id_proceso
            -- Otros
            delete wf_paso_automatico_log where pa_id_inst_proc = @w_id_proceso
            delete wf_h_estado_proceso where ep_id_inst_proc = @w_id_proceso
            delete wf_log_info_programa where lip_inst_proceso = @w_id_proceso
            delete wf_bloqueo_inst_proceso where id_inst_proceso = @w_id_proceso
            -- Asignación de actividad
            delete wf_asig_actividad where aa_id_inst_act in (select ia_id_inst_act from wf_inst_actividad where ia_id_inst_proc = @w_id_proceso)
            -- Instancia de Actividad
            delete wf_inst_actividad where ia_id_inst_proc = @w_id_proceso
            -- Instancia de Proceso
            delete wf_inst_proceso WHERE io_id_inst_proc = @w_id_proceso
        end
        else
        begin
            print 'Ya existe otra solicitud en proceso para el mismo cliente.'
            return 2110110
        end
    end
    else if @w_count > 1
    begin
        print 'Ya existe otra solicitud en proceso para el mismo cliente.'
        return 2110110
    end

    SELECT @w_ente   = convert(int,@i_campo_1)
    -- VALIDA QUE EXISTAN LAS SECCIONES
    if not exists (select 1 FROM cobis..cl_seccion_validar where sv_ente = @w_ente)
    begin
        print 'Inconsistencia de datos del cliente del trámite.'
        return 70010001
    end

    IF EXISTS( SELECT 1 FROM cobis..cl_ente_aux WHERE ea_ente = @w_ente AND ea_estado <> 'A')
    begin
        PRINT 'Error: el solicitante no es un Cliente'
        -- VALIDA SI NO TIENE TODAS LAS SECCIONES LLENAS
        if exists (select 1 FROM cobis..cl_seccion_validar
                   where sv_ente       = @w_ente
                   and   sv_seccion    != '4' -- CALIFICACION DEL CLIENTE
                   and   sv_completado = 'N')
        begin
            print 'Primero llene toda la información del prospecto para poder iniciar una solicitud.'
            return 2110108
        end
    end

    SELECT @i_vinculado = en_vinculacion FROM cobis..cl_ente WHERE en_ente = @w_ente

    if (@i_vinculado = 'S')
    begin
        /* Error, el cliente es Vinculado */
        return 103159
    end


    IF EXISTS(SELECT 1 FROM cob_cartera..ca_operacion, cob_credito..cr_tramite_grupal
              WHERE op_banco = tg_prestamo AND op_cliente = @w_ente
              AND op_estado NOT IN (0,99,3))
    begin
        return 103160
    end

end

/*
--VALIDA EL INICIO  DE FLUJOS DE MODIFICACION DE SOBREGIROS

IF EXISTS (select 1 from wf_proceso WHERE pr_codigo_proceso = @w_id_proceso and  pr_producto in('CRE','CTE'))
BEGIN
    IF EXISTS (select 1 from cob_credito..cr_tramite,cob_credito..cr_linea where li_tramite = tr_tramite and tr_toperacion <> 'SGC' and li_num_banco = @i_campo_2)
     begin
        exec cobis..sp_cerror
            @i_num  = 2107048,
            @t_from = @w_sp_name
        return 1
    end
END

*/

--Validación de la oficina del grupo


-- Validacion de Autorizacion de Rol por Producto


if not exists(
   select 1 from wf_usuario
   INNER JOIN wf_usuario_rol ON us_id_usuario = ur_id_usuario
   INNER JOIN cob_credito..cr_rol_producto ON ur_id_rol = rp_rol
   WHERE us_login = @s_user AND rp_toperacion = @i_campo_4 and rp_estado = 'ACT'
)
begin
   return 21000
end

return 0

GO
