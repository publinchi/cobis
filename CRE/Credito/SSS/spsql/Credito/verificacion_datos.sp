/************************************************************************/
/*  Archivo:                verificacion_datos.sp                       */
/*  Stored procedure:       sp_verificacion_datos                       */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*     Este programa procesa las transacciones del stored procedure     */
/*     Inserta actualiza y consulta información para verificación       */
/*     datos                                                            */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR                RAZON                        */
/*  30/05/2017        Adriana Chiluisa     Version Inicial              */
/*  30/04/2019        fjescobar            Version TeCreemos            */
/*  03/06/2019        Estefania Ramirez    Actualizacion Asesor Movil   */
/*  05/02/2020        Gerardo Barron    Correccion en primer dato con isnull   */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_verificacion_datos' and type = 'P')
   drop proc sp_verificacion_datos
go


CREATE proc sp_verificacion_datos (
    @s_ssn                  int             = null,
    @s_sesn                 int             = null,
    @s_culture              varchar(10)     = null,
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

    @i_inst_proceso         int             = null,
    @i_operacion            char(1),                -- Opcion con que se ejecuta el programa
    @i_modo                 tinyint         = null, -- Modo de busqueda
    @i_tipo                 char(1)         = null, -- -- cl_tramite_documento <-> I=INDIVIDUAL, G=GRUPAL

    @i_ente                 int             = null,
    @i_respuesta            char(500)       = null,
    @i_latitud_neg          float           = null,
    @i_longitud_neg         float           = null,
    @i_latitud_dom          float           = null,
    @i_longitud_dom         float           = null,
    @o_resultado            int             = null out--, --LPO CDIG Se comenta porque Cobis Language no soporta XML
--    @o_xml                  XML             = null out  --LPO CDIG Se comenta porque Cobis Language no soporta XML
)
as
--LPO CDIG Se comenta porque Cobis Language no soporta XML INICIO
/*
declare @w_sp_name                  varchar(32),
        @w_error                    int,
        @w_cuestionario             int,
        @w_producto                 catalogo,
        @w_ente                     int,
        @w_puntaje                  smallint,
        @w_puntaje_resul            smallint,
        @w_programa                 varchar(64),
        @w_tramite                  int,
        @w_cat_s_sec                int,
        @w_cat_respu                int,
        @w_xml                      XML,

        @w_siguiente                int,
        @w_return                   int,
        @w_num_cl_gr                int,
        @w_contador                 int,
        @w_respuestas               varchar(200),
        @w_resultado                int,
        @w_actualizar               char(1),
        @w_ingreso_mensual          money,
        @w_gasto_mens_famil         money,
        @w_nombre_grupo             varchar(30),--
        @w_nombre_presi             varchar(30),--
        @w_nombre                   varchar(30),--
        @w_apellido_paterno         varchar(30),--
        @w_apellido_materno         varchar(30),--
        @w_calle                    varchar(30),--
        @w_numero                   varchar(30),--
        @w_colonia                  varchar(30),--
        @w_delegacion_municipio     varchar(30),--
        @w_anos_en_domic_actual     VARCHAR(30), --veri
        @w_ocupacion                varchar(30),--
        @w_nombre_negocio           varchar(30),--
        @w_tiempo_arraigo_negocio   varchar(30),--
        @w_tipo_local               varchar(30),--
        @w_gasto_mens               money,
        @w_cod_tab_negocio          smallint,
        @w_cod_tab_tiempo           smallint,
        @w_fecha_proceso            datetime,
        @w_grupal_aux               char(1),
        @w_grupal                   char(1),
        @w_tecnologico              int,
         @w_codigo                  int
    --declaracion de variables para consultas
declare
    @w_grupo int, @w_rol catalogo, @w_ente_presi int, @w_cod_tab_profesion catalogo,
    @w_cod_tab_parroq catalogo, @w_cod_tab_ciudad catalogo
    -- saco la cadena de respuestas
declare
    @w_cadena varchar(500),
    @w_resultado_aux smallint,
    @w_resp1 varchar(100),
    @w_pos1 smallint,
    @w_col1  SMALLINT,
    @w_resp varchar(100),
    @w_pos smallint,
    @w_preg smallint,
    @w_tipo_resp char(1),
    @w_tiene_registro    char(1),
    @w_id_inst_act       int,
    @w_id_asig_act       int,
    @w_id_paso           int


-------------------------------- VERSIONAMIENTO DE SP --------------------------------
if @t_show_version = 1
begin
    print 'Stored procedure sp_verificacion_datos, Version 5.0.0.0'
    return 0
end
--------------------------------------------------------------------------------------
select @w_sp_name = 'sp_verificacion_datos'

if @t_trn <> 21700
begin
    select @w_error = 151051 -- TRANSACCION NO PERMITIDA
    goto ERROR
end

select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
select @w_producto     = io_campo_4,
       @w_tramite      = io_campo_3,
       @w_ente         = io_campo_1
from   cob_workflow..wf_inst_proceso
where  io_id_inst_proc = @i_inst_proceso

if(@i_tipo = 'G')
begin
    select @w_tramite = io_campo_3 from cob_workflow..wf_inst_proceso where io_id_inst_proc = @i_inst_proceso
    select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso
    select @w_grupal = tr_grupal FROM cob_credito..cr_tramite WHERE tr_tramite = @w_tramite
end

set @w_actualizar = 'N'

if @i_operacion = 'I'
begin
    -- verificar que exista el registro --
    if exists (select 1 from cr_verifica_datos where vd_inst_proceso = @i_inst_proceso and vd_cliente = @i_ente)
    begin
        select @w_error = 2101002 -- REGISTRO YA EXISTE
        goto ERROR
    end
     exec cobis..sp_cseqnos
        @t_debug     = @t_debug,
        @t_file      = @t_file,
        @t_from      = @w_sp_name,
        @i_tabla     = 'cr_verifica_datos',
        @o_siguiente = @w_codigo out

    INSERT INTO cr_verifica_datos (vd_codigo, vd_tipo, vd_producto, vd_cliente,  vd_estado, vd_resultado, vd_inst_proceso, vd_fecha)
    VALUES(@w_codigo, @i_tipo,@w_producto, @i_ente, 'V', @w_resultado , @i_inst_proceso,  @w_fecha_proceso)

    -- Si no se puede modificar, error --
    if @@error <> 0
    begin
        select @w_error = 2103057  --ERROR EN LA ACTUALIZACIÓN
        goto ERROR
    end
end -- Fin Operacion I

if @i_operacion in ('I', 'U')
begin
    set @w_tiene_registro = 'N'
    --Actualizacion latitud , longitud -- negocio
    if (@i_latitud_neg != null and @i_longitud_neg != null and @i_latitud_neg != '' and @i_longitud_neg != '')
    begin
        declare @w_di_direccion_neg int
        select @w_di_direccion_neg = di_direccion
        from cobis..cl_direccion where di_ente = @w_ente and di_tipo = 'AE'

        if exists (select 1 from cobis..cl_direccion_geo
                   where dg_ente =  @w_ente and dg_direccion = @w_di_direccion_neg
                   and dg_secuencial = (select max(dg_secuencial)
                                        from cobis..cl_direccion_geo
                                        where dg_ente =  @w_ente and dg_direccion = @w_di_direccion_neg ))
        begin
            update cobis..cl_direccion_geo
            set dg_lat_seg  = @i_latitud_neg,
                dg_long_seg = @i_longitud_neg
            from cobis..cl_direccion_geo where dg_ente =  @w_ente and dg_direccion = @w_di_direccion_neg and dg_secuencial =
            (select max(dg_secuencial) from cobis..cl_direccion_geo where dg_ente =  @w_ente and dg_direccion = @w_di_direccion_neg )
        end
    end

    --Actualizacion latitud , longitud -- domicilio
    if (@i_latitud_dom != null and @i_longitud_dom != null and @i_latitud_dom != '' and @i_longitud_dom != '')
    begin
        declare @w_di_direccion_dom int
        select @w_di_direccion_dom = di_direccion
        from cobis..cl_direccion where di_ente = @w_ente and di_tipo = 'RE'

        if exists (select 1 from cobis..cl_direccion_geo
                   where dg_ente =  @w_ente and dg_direccion = @w_di_direccion_dom
                   and dg_secuencial = (select max(dg_secuencial)
                                        from cobis..cl_direccion_geo
                                        where dg_ente =  @w_ente and dg_direccion = @w_di_direccion_dom ))
        begin
            update cobis..cl_direccion_geo
            set dg_lat_seg  = @i_latitud_dom,
                dg_long_seg = @i_longitud_dom
            from cobis..cl_direccion_geo where dg_ente =  @w_ente and dg_direccion = @w_di_direccion_dom and dg_secuencial =
            (select max(dg_secuencial) from cobis..cl_direccion_geo where dg_ente =  @w_ente and dg_direccion = @w_di_direccion_dom )
        end
    end -- Fin Actualizacion latitud , longitud

    -- SI TIENE UN CUESTIONARIO 'VIGENTE' ENVIA UN REGISTRO DE SICRONIZACION PARA MODIFICAR A LA APP MOVIL
    select @w_cuestionario = vd_codigo
    from   cob_credito..cr_verifica_datos
    where  vd_tipo     = @i_tipo
    and    vd_producto = @w_producto
    and    vd_cliente  = @w_ente
    and    vd_estado   = 'V'
    if @@rowcount = 1
    begin
        set @w_tiene_registro = 'S'
    end
    else
    begin
        select @w_cuestionario = isnull(max(vd_codigo),0) + 1 from  cr_verifica_datos --LGBC 05/02/2020 isnull
        insert into cr_verifica_datos (vd_codigo, vd_tipo, vd_producto, vd_cliente,  vd_estado, vd_resultado, vd_inst_proceso, vd_fecha)
        values(@w_cuestionario, @i_tipo, @w_producto,@w_ente,'V', @w_resultado , @i_inst_proceso, @w_fecha_proceso)
        if @@error <> 0
        begin
            select @w_error = 2103057  --ERROR EN LA ACTUALIZACIÓN
            goto ERROR
        end
    end

    select @w_cadena = @i_respuesta -- string a evaluar para determinar el resultado
    select @w_cadena = isnull(@w_cadena ,'')
    select @w_col1 = 1
    select @w_resultado_aux = 0
    select @w_resultado = 0
    select @w_tecnologico = 0
    WHILE len(@w_cadena) > 0
    BEGIN
        SELECT @w_pos1 = charindex(';',@w_cadena)
        IF @w_pos1 > 0
        begin
            SELECT @w_resp1 = substring(@w_cadena, 1,@w_pos1 - 1)
            SELECT @w_cadena = substring(@w_cadena, @w_pos1 + 1, 500)
        END
        ELSE
        begin
            SELECT @w_resp1 = @w_cadena
            SELECT @w_cadena = NULL
        END

        SELECT @w_pos = charindex('|',@w_resp1)
        select @w_preg = substring(@w_resp1, 1,@w_pos - 1)
        select @w_resp = substring(@w_resp1, @w_pos + 1, 500)

        -- tengo la respuesta --> asignar puntaje
        if @i_tipo = 'G'
        begin
            if @w_col1 between 1 and 12
            begin
                if @w_col1 in (6,12)
                    if @w_resp1 = 'S'
                        select @w_resultado_aux = @w_resultado_aux + 1
                    else
                        select @w_resultado_aux = @w_resultado_aux - 10
                else
                    if @w_resp1 = 'S'
                        select @w_resultado_aux = @w_resultado_aux + 1
                    else
                        select @w_resultado_aux = @w_resultado_aux - 0
            end
            else -- si @w_col1 >= 14
            begin
                if @w_col1 = 13
                begin
                    if @w_resp1 = 'S' -- diario/semanal
                    begin
                        select @w_resultado_aux = @w_resultado_aux + 1
                        select @w_tecnologico = @w_tecnologico + 1
                    end
                    else
                    begin
                        select @w_resultado_aux = @w_resultado_aux - 0
                        select @w_tecnologico = @w_tecnologico - 0
                    end
                end
                if @w_col1 = 14
                begin
                    if @w_resp1 in ('D', 'S') -- diario/semanal
                    begin
                        select @w_resultado_aux = @w_resultado_aux + 1
                        select @w_tecnologico = @w_tecnologico + 1
                    end
                    else
                    begin
                        select @w_resultado_aux = @w_resultado_aux - 0
                        select @w_tecnologico = @w_tecnologico - 0
                    end
                end
                if @w_col1 = 15
                begin
                    if @w_resp1 in ('F', 'W') -- facebook/wa
                    begin
                        select @w_resultado_aux = @w_resultado_aux + 1
                        select @w_tecnologico = @w_tecnologico + 1
                    end
                    else
                    begin
                        select @w_resultado_aux = @w_resultado_aux - 0
                        select @w_tecnologico = @w_tecnologico - 0
                    end
                end
                if @w_col1 = 16
                begin
                    if @w_resp1 in ('S') -- smartphone
                    begin
                        select @w_resultado_aux = @w_resultado_aux + 1
                        select @w_tecnologico = @w_tecnologico + 1
                    end
                    else
                    begin
                        select @w_resultado_aux = @w_resultado_aux - 0
                        select @w_tecnologico = @w_tecnologico - 0
                    end
                end
                if @w_col1 = 17
                begin
                    if @w_resp1 in ('R') -- renta
                    begin
                        select @w_resultado_aux = @w_resultado_aux + 1
                        select @w_tecnologico = @w_tecnologico + 1
                    end
                    else
                    begin
                        select @w_resultado_aux = @w_resultado_aux - 0
                        select @w_tecnologico = @w_tecnologico - 0
                    end
                end
            end
        end
        else -- @i_tipo = 'I'
        begin
            select @w_tipo_resp = pr_tipo_respuesta
            from cob_credito..cr_pregunta
            where pr_tipo = @i_tipo
            and pr_producto = @w_producto
            and pr_estado = 'V'
            and pr_codigo = @w_preg
			print 'TIPO [' + @i_tipo + '] - PROD[' + @w_producto  +  '] - PREG[' + convert(varchar(10),@w_preg) + '] - RESP [' + @w_resp + ']'

            if @w_tipo_resp in ('C', 'G')
            begin

                select @w_resultado_aux = pv_puntaje
                from cob_credito..cr_pregunta_ver_dat
                where pv_codigo = @w_preg
                and pv_producto = @w_producto
                and pv_valor = @w_resp
                and pv_tipo = @i_tipo
                select @w_resultado = @w_resultado + @w_resultado_aux

                if @w_cuestionario is not null
                begin

                    if exists (select 1 from cob_credito..cr_pregunta_repuesta_c where prc_cuestionario = @w_cuestionario and prc_codigo = @w_preg)
                    begin
                        update cob_credito..cr_pregunta_repuesta_c
                        set prc_respuesta = @w_resp
                        where prc_cuestionario = @w_cuestionario
                        and prc_codigo = @w_preg
                    end
                    else
                    begin
                        insert into cob_credito..cr_pregunta_repuesta_c
                        values (@w_cuestionario, @w_preg, @w_resp)
                    end
                end
            end
            if @w_tipo_resp = 'M'
            begin
                if @w_cuestionario is not null
                begin
                    if exists (select 1 from cob_credito..cr_pregunta_repuesta_m where prm_cuestionario = @w_cuestionario and prm_codigo = @w_preg)
                    begin
                        update cob_credito..cr_pregunta_repuesta_m
                        set prm_respuesta = @w_resp
                        where prm_cuestionario = @w_cuestionario
                        and prm_codigo = @w_preg
                    end
                    else
                    begin
                        insert into cob_credito..cr_pregunta_repuesta_m
                        values (@w_cuestionario, @w_preg, @w_resp)
                    end
                end
            end
            if @w_tipo_resp = 'T'
            begin
                if @w_cuestionario is not null
                begin
                    if exists (select 1 from cob_credito..cr_pregunta_repuesta_t where prt_cuestionario = @w_cuestionario and prt_codigo = @w_preg)
                    begin
                        update cob_credito..cr_pregunta_repuesta_t
                        set prt_respuesta = @w_resp
                        where prt_cuestionario = @w_cuestionario
                        and prt_codigo = @w_preg
                    end
                    else
                    begin
                        insert into cob_credito..cr_pregunta_repuesta_t
                        values (@w_cuestionario, @w_preg, @w_resp)
                    end
                end
            end
            if @w_tipo_resp = 'N'
            begin
                if @w_cuestionario is not null
                begin
                    if exists (select 1 from cob_credito..cr_pregunta_repuesta_n where prn_cuestionario = @w_cuestionario and prn_codigo = @w_preg)
                    begin
                        update cob_credito..cr_pregunta_repuesta_n
                        set prn_respuesta = @w_resp
                        where prn_cuestionario = @w_cuestionario
                        and prn_codigo = @w_preg
                    end
                    else
                    begin
                        insert into cob_credito..cr_pregunta_repuesta_n
                        values (@w_cuestionario, @w_preg, @w_resp)
                    end
                end
            end
        end
        --SELECT @w_col1, @w_resp1, @w_resultado_aux
        SELECT @w_col1 = @w_col1 +1
    END

    --AGREGAR ACTALIZACION AL TECNOLOGICO DEL USUARIO

    if @w_tecnologico >= 4
    begin
        UPDATE cobis..cl_ente_aux SET ea_tecnologico = 'ALTO'
        WHERE ea_ente = @i_ente
    end
    else if @w_tecnologico = 3
    begin
        UPDATE cobis..cl_ente_aux SET ea_tecnologico = 'MEDIO'
        WHERE ea_ente = @i_ente
    end
    else if @w_tecnologico <=2
    begin
        UPDATE cobis..cl_ente_aux SET ea_tecnologico = 'BAJO'
        WHERE ea_ente = @i_ente
    end

    select --@w_respuestas = vd_respuesta,
            @w_resultado_aux  = vd_resultado
    from   cr_verifica_datos
    where  vd_inst_proceso = @i_inst_proceso
    and    vd_cliente = @w_ente

    select @w_resultado = sum (pv_puntaje)
    from cob_credito..cr_pregunta_repuesta_c, cob_credito..cr_pregunta_ver_dat
    where prc_codigo = pv_codigo
    and prc_respuesta = pv_valor
    and prc_cuestionario = @w_cuestionario
    and pv_producto = @w_producto

    if @w_resultado_aux is null or @w_resultado <> @w_resultado_aux
        begin
        set @w_actualizar = 'S'
        end

    -- Actualizacion de registros tanto para el ingreso como para la actualizacion
    IF @w_actualizar = 'S'
    begin
        update cr_verifica_datos
        set    vd_resultado  = @w_resultado,
               vd_fecha      = @w_fecha_proceso
        where  vd_codigo     = @w_cuestionario
        -- Si no se puede modificar, error --
        if @@rowcount = 0
        begin
            select @w_error = 2103057  --ERROR EN LA ACTUALIZACIÓN
            goto ERROR
        end
    end

    -- VALIDA LA ETAPA EN LA QUE SE ENCUENTRA LA SOLICITUD PARA PODER RUTEAR A LA SIGUIENTE ETAPA
    if exists(select 1 from cob_workflow..wf_inst_actividad where ia_id_inst_proc = @i_inst_proceso
              and ia_estado = 'ACT'
              and ( ia_nombre_act in ('INDICA DATO A CORREGIR','APLICA CUESTIONARIO SUPERVISIO') )
              )
    begin
        select @w_id_inst_act = max(ia_id_inst_act) from cob_workflow..wf_inst_actividad where ia_id_inst_proc = @i_inst_proceso
        select @w_id_paso = ia_id_paso from cob_workflow..wf_inst_actividad where ia_id_inst_proc = @i_inst_proceso and ia_id_inst_act = @w_id_inst_act
        select @w_id_asig_act = aa_id_asig_act from cob_workflow..wf_asig_actividad where aa_id_inst_act = @w_id_inst_act

        exec @w_error = cob_workflow..sp_resp_actividad_wf @i_codigo_res = 1,       @i_operacion = 'C',     @t_trn  = 73506,
                                                           @s_srv        = @s_srv,  @s_user      = @s_user, @s_term              = @s_term,  @s_ofi               = @s_ofi,
                                                           @s_rol        = @s_rol,  @s_ssn       = @s_ssn,  @s_lsrv              = @s_lsrv, @s_date              = @s_date,
                                                           @s_sesn       = @s_sesn, @s_org       = 'U',     @s_culture        	 = @s_culture,
                                                           @i_id_inst_proc = @i_inst_proceso,   @i_id_inst_act  = @w_id_inst_act,
                                                           @i_id_asig_act  = @w_id_asig_act,    @i_id_paso      = @w_id_paso
        if @w_error !=0  goto ERROR
    end
end -- Fin Operacion U, I

if @i_operacion = 'S'
begin
    select @w_producto     = io_campo_4,
           @w_tramite      = io_campo_3,
           @w_ente         = io_campo_1
    from   cob_workflow..wf_inst_proceso
    where  io_id_inst_proc = @i_inst_proceso

    select @w_puntaje  = pr_puntaje,
           @w_programa = pp_programa
    from   cr_pregunta_producto
    where  pp_tipo     = @i_tipo
    and    pp_producto = @w_producto

    select @w_cuestionario  = vd_codigo,
           @w_puntaje_resul = vd_resultado
    from   cr_verifica_datos
    where  vd_tipo          = @i_tipo
    and    vd_producto      = @w_producto
    and    vd_cliente       = @w_ente
    and    vd_estado        = 'V'

    -- TABLAs DONDE SE VAN A GUARDAR LAS PREGUNTAS Y REPUESTAS
    create table #cr_pregunta (
        prt_codigo          tinyint       NOT NULL,
        prt_seccion         catalogo      NOT NULL,  -- cr_pregunta_seccion
        prt_tipo_respuesta  char(1)       NOT NULL,  -- P=PRECARGADA, C=Combo(S/N), G=Geolocalización, M=Monto, N=Número, T=Texto, I=Imagen,
        prt_descripcion     varchar(200)  NOT NULL
    )
    create table #cr_respuesta (
        ret_codigo          tinyint       NOT NULL,
        ret_puntaje         smallint      NULL,
        ret_respuesta       varchar(250)  NULL
    )
    create table #cr_validacion (
        val_codigo          tinyint       NOT NULL,
        val_respuesta       varchar(250)  NULL
    )
    insert into #cr_pregunta (prt_codigo, prt_seccion, prt_tipo_respuesta, prt_descripcion)
    select pr_codigo, pr_seccion, pr_tipo_respuesta, pr_descripcion
    from   cr_pregunta
    where  pr_tipo     = @i_tipo
    and    pr_producto = @w_producto
    and    pr_estado   = 'V'
    order by pr_seccion , pr_codigo

    if @i_modo in ( 0 , 1 ) -- ( 'DESDE FRONTEND ORIGINADOR WEB' , 'DESDE TAREA AUTOMATICA' )
    begin
        -- LLAMAR A SP QUE GENERA LAS RESPUESTAS (POR PRODUCTO)
        exec @w_error = @w_programa @i_inst_proceso = @i_inst_proceso,
                                    @i_producto     = @w_producto,
                                    @i_cuestionario = @w_cuestionario,
                                    @i_cliente      = @w_ente,
                                    @i_tramite      = @w_tramite,
                                    @i_modo         = @i_modo,
                                    @i_operacion    = 'S'
        if @w_error <> 0
        begin
            goto ERROR
        end
    end -- @i_modo in ( 0 , 1 )

    if @i_modo = 0 -- DESDE FRONTEND ORIGINADOR WEB
    begin
        -- CONSULTA DE RESPUESTA
        select 'PUNT_APRUEBA' = @w_puntaje,
               'PUNT_ACTUAL'  = @w_puntaje_resul

        select 'CODIGO'    = prt_codigo,
               'SECCION'   = prt_seccion,
               'PREGUNTA'  = prt_descripcion,
               'RESPUESTA' = ret_respuesta,
               'PUNTAJE'   = ret_puntaje
        from   #cr_pregunta
        left join #cr_respuesta on prt_codigo = ret_codigo
        order by prt_seccion , prt_codigo
        return 0
    end -- @i_modo = 0

    if @i_modo = 1 -- DESDE TAREA AUTOMATICA
    begin
        select @w_cat_s_sec   = codigo from cobis..cl_tabla where tabla = 'cr_pregunta_seccion'
        select @w_cat_respu   = codigo from cobis..cl_tabla where tabla = 'cr_respuesta_texto'

        select @w_xml = (
            SELECT tag, parent,
                   [supervision!1!valor],               --1
                   [cuestionario!2!valor],              --2
                   [pregunta!3!valor],                  --3
                   [pregunta!3!codigo!ELEMENT],         --4
                   [pregunta!3!seccion!ELEMENT],        --5
                   [pregunta!3!detalle!ELEMENT],        --6
                   [pregunta!3!respuesta!ELEMENT],      --7
                   [pregunta!3!tipo!ELEMENT],           --8
                   [pregunta!3!puntaje!ELEMENT],        --9
                   [pregunta!3!cabecera!ELEMENT],       --10
                   [respuestas!4!valor],                --11
                   [respuesta!5!valor],                 --12
                   [respuesta!5!pregunta!ELEMENT],      --13
                   [respuesta!5!codigo!ELEMENT],        --14
                   [respuesta!5!detalle!ELEMENT]        --15
            FROM (
                SELECT 1 AS tag,
                       NULL AS parent,
                       NULL AS [supervision!1!valor],               --1
                       NULL AS [cuestionario!2!valor],              --2
                       NULL AS [pregunta!3!valor],                  --3
                       NULL AS [pregunta!3!codigo!ELEMENT],         --4
                       NULL AS [pregunta!3!seccion!ELEMENT],        --5
                       NULL AS [pregunta!3!detalle!ELEMENT],        --6
                       NULL AS [pregunta!3!respuesta!ELEMENT],      --7
                       NULL AS [pregunta!3!tipo!ELEMENT],           --8
                       NULL AS [pregunta!3!puntaje!ELEMENT],        --9
                       NULL AS [pregunta!3!cabecera!ELEMENT],       --10
                       NULL AS [respuestas!4!valor],                --11
                       NULL AS [respuesta!5!valor],                 --12
                       NULL AS [respuesta!5!pregunta!ELEMENT],      --13
                       NULL AS [respuesta!5!codigo!ELEMENT],        --14
                       NULL AS [respuesta!5!detalle!ELEMENT]        --15
                UNION
                SELECT 2 AS tag,
                       1 AS parent,
                       NULL AS [supervision!1!valor],               --1
                       NULL AS [cuestionario!2!valor],              --2
                       NULL AS [pregunta!3!valor],                  --3
                       NULL AS [pregunta!3!codigo!ELEMENT],         --4
                       NULL AS [pregunta!3!seccion!ELEMENT],        --5
                       NULL AS [pregunta!3!detalle!ELEMENT],        --6
                       NULL AS [pregunta!3!respuesta!ELEMENT],      --7
                       NULL AS [pregunta!3!tipo!ELEMENT],           --8
                       NULL AS [pregunta!3!puntaje!ELEMENT],        --9
                       NULL AS [pregunta!3!cabecera!ELEMENT],       --10
                       NULL AS [respuestas!4!valor],                --11
                       NULL AS [respuesta!5!valor],                 --12
                       NULL AS [respuesta!5!pregunta!ELEMENT],      --13
                       NULL AS [respuesta!5!codigo!ELEMENT],        --14
                       NULL AS [respuesta!5!detalle!ELEMENT]        --15
                UNION ALL
                SELECT 3 AS tag,
                       2 AS parent,
                       NULL AS [supervision!1!valor],                           --1
                       NULL AS [cuestionario!2!valor],                          --2
                       NULL AS [pregunta!3!valor],                              --3
                       P.prt_codigo         AS [pregunta!3!codigo!ELEMENT],     --4
                       P.prt_seccion        AS [pregunta!3!seccion!ELEMENT],    --5
                       P.prt_descripcion    AS [pregunta!3!detalle!ELEMENT],    --6
                       R.ret_respuesta      AS [pregunta!3!respuesta!ELEMENT],  --7
                       P.prt_tipo_respuesta AS [pregunta!3!tipo!ELEMENT],       --8
                       R.ret_puntaje        AS [pregunta!3!puntaje!ELEMENT],    --9
                       C.valor              AS [pregunta!3!cabecera!ELEMENT],   --10
                       NULL AS [respuestas!4!valor],                            --11
                       NULL AS [respuesta!5!valor],                             --12
                       NULL AS [respuesta!5!pregunta!ELEMENT],                  --13
                       NULL AS [respuesta!5!codigo!ELEMENT],                    --14
                       NULL AS [respuesta!5!detalle!ELEMENT]                    --15
                       from   #cr_pregunta P
                       left join #cr_respuesta R on P.prt_codigo = R.ret_codigo
                       left join cobis..cl_catalogo C on C.tabla = @w_cat_s_sec and prt_seccion = C.codigo
                UNION
                SELECT 4 AS tag,
                       1 AS parent,
                       NULL AS [supervision!1!valor],               --1
                       NULL AS [cuestionario!2!valor],              --2
                       NULL AS [pregunta!3!valor],                  --3
                       NULL AS [pregunta!3!codigo!ELEMENT],         --4
                       NULL AS [pregunta!3!seccion!ELEMENT],        --5
                       NULL AS [pregunta!3!detalle!ELEMENT],        --6
                       NULL AS [pregunta!3!respuesta!ELEMENT],      --7
                       NULL AS [pregunta!3!tipo!ELEMENT],           --8
                       NULL AS [pregunta!3!puntaje!ELEMENT],        --9
                       NULL AS [pregunta!3!cabecera!ELEMENT],       --10
                       NULL AS [respuestas!4!valor],                --11
                       NULL AS [respuesta!5!valor],                 --12
                       NULL AS [respuesta!5!pregunta!ELEMENT],      --13
                       NULL AS [respuesta!5!codigo!ELEMENT],        --14
                       NULL AS [respuesta!5!detalle!ELEMENT]        --15
                UNION ALL
                (
                SELECT 5 AS tag,
                       4 AS parent,
                       NULL AS [supervision!1!valor],                 --1
                       NULL AS [cuestionario!2!valor],                --2
                       NULL AS [pregunta!3!valor],                    --3
                       NULL AS [pregunta!3!codigo!ELEMENT],           --4
                       NULL AS [pregunta!3!seccion!ELEMENT],          --5
                       NULL AS [pregunta!3!detalle!ELEMENT],          --6
                       NULL AS [pregunta!3!respuesta!ELEMENT],        --7
                       NULL AS [pregunta!3!tipo!ELEMENT],             --8
                       NULL AS [pregunta!3!puntaje!ELEMENT],          --9
                       NULL AS [pregunta!3!cabecera!ELEMENT],         --10
                       NULL AS [respuestas!4!valor],                  --11
                       NULL AS [respuesta!5!valor],                   --12
                       prt_codigo AS [respuesta!5!pregunta!ELEMENT],  --13
                       pv_valor   AS [respuesta!5!codigo!ELEMENT],    --14
                       valor      AS [respuesta!5!detalle!ELEMENT]    --15
                       from   #cr_pregunta P
                       inner join cr_pregunta_ver_dat on pv_tipo = @i_tipo and pv_producto = @w_producto and pv_codigo = prt_codigo
                       left join cobis..cl_catalogo on tabla = @w_cat_respu and pv_valor = codigo
                UNION
                SELECT 5 AS tag,
                       4 AS parent,
                       NULL AS [supervision!1!valor],                 --1
                       NULL AS [cuestionario!2!valor],                --2
                       NULL AS [pregunta!3!valor],                    --3
                       NULL AS [pregunta!3!codigo!ELEMENT],           --4
                       NULL AS [pregunta!3!seccion!ELEMENT],          --5
                       NULL AS [pregunta!3!detalle!ELEMENT],          --6
                       NULL AS [pregunta!3!respuesta!ELEMENT],        --7
                       NULL AS [pregunta!3!tipo!ELEMENT],             --8
                       NULL AS [pregunta!3!puntaje!ELEMENT],          --9
                       NULL AS [pregunta!3!cabecera!ELEMENT],         --10
                       NULL AS [respuestas!4!valor],                  --11
                       NULL AS [respuesta!5!valor],                   --12
                       val_codigo AS [respuesta!5!pregunta!ELEMENT],  --13
                       '1'        AS [respuesta!5!codigo!ELEMENT],    --14
                       val_respuesta AS [respuesta!5!detalle!ELEMENT] --15
                       from   #cr_validacion
                )
        ) AS A FOR XML EXPLICIT )
        set @o_xml = @w_xml
        return 0
    end -- @i_modo = 1
    return 0
end -- @i_operacion = 'S'

if @i_operacion = 'Q'
begin

    SELECT @w_rol = 'P'

    select @w_resultado  = vd_resultado
    from   cr_verifica_datos
    where  vd_inst_proceso = @i_inst_proceso
    and    vd_cliente = @i_ente

    --Seccion catalogos
    select @w_cod_tab_profesion = codigo
    from  cobis..cl_tabla
    where tabla = 'cl_profesion'

    select @w_cod_tab_parroq = codigo
    from   cobis..cl_tabla
    where  tabla  = 'cl_parroquia'

    select @w_cod_tab_ciudad = codigo
    from   cobis..cl_tabla
    where  tabla  = 'cl_ciudad'

    select @w_cod_tab_negocio = codigo
    from   cobis..cl_tabla
    where  tabla  = 'cr_tipo_local'

    select @w_cod_tab_tiempo = codigo
    from   cobis..cl_tabla
    where  tabla  = 'cl_referencia_tiempo'

    --- Para obtener el grupo
    --set rowcount 1
    select top 1
    @w_grupo = tg_grupo
    from   cob_credito..cr_tramite_grupal
    where  tg_tramite = @w_tramite
    --set rowcount 0

    --- Para obtener el presidente
    select @w_ente_presi = cg_ente
    from   cobis..cl_cliente_grupo
    where  cg_grupo = @w_grupo
    and    cg_rol   = @w_rol

    --- Para obtener el nombr del grupo
    select @w_nombre_grupo = gr_nombre
    from   cobis..cl_grupo
    where  gr_grupo = @w_grupo

    --- Para obtener datos del presi
    select @w_nombre_presi = en_nombre + ' ' + p_p_apellido + ' ' + p_s_apellido
    from   cobis..cl_ente
    where  en_ente = @w_ente_presi

    --- Para obtener datos del ente
    select @w_nombre           = en_nombre,
           @w_apellido_paterno = p_p_apellido,
           @w_apellido_materno = p_s_apellido,
           @w_ocupacion        = (select valor from cobis..cl_catalogo
                                  where  tabla = @w_cod_tab_profesion and codigo = E.p_profesion),
           @w_ingreso_mensual  = en_otros_ingresos
    from cobis..cl_ente E
    where en_ente = @i_ente

    -- GASTOS FAMILIARES
    select @w_gasto_mens = ea_ct_ventas
    from cobis..cl_ente_aux
    where ea_ente = @i_ente

    -- NOMBRE NEGOCIO // TIPO DE NEGOCIO
--    set rowcount 1
    select top 1
        @w_nombre_negocio   = nc_nombre,
        @w_tipo_local       = (select valor from cobis..cl_catalogo
                               where  tabla = @w_cod_tab_negocio
                               and    codigo = nc.nc_tipo_local),
        @w_tiempo_arraigo_negocio =  (select valor from cobis..cl_catalogo
                               where  tabla = @w_cod_tab_tiempo
                               and    codigo = nc_tiempo_actividad)
    from cobis..cl_negocio_cliente nc
    where nc_ente  = @i_ente
    and nc_estado_reg = 'V'
    order by nc_codigo desc

    select top 1
           @w_anos_en_domic_actual = (select valor from cobis..cl_catalogo
                                      where  tabla = @w_cod_tab_tiempo
                                      and    codigo = convert(varchar(10),C.di_tiempo_reside)),
           @w_calle                = di_calle,
           @w_numero               = di_nro,
           @w_colonia              = (select valor from cobis..cl_catalogo
                                      where  tabla = @w_cod_tab_parroq
                                      and    codigo = convert(varchar(10),C.di_parroquia)),
           @w_delegacion_municipio= (select valor from cobis..cl_catalogo
                                      where  tabla = @w_cod_tab_ciudad
                                      and    codigo = convert(varchar(10),C.di_ciudad))
    from   cobis..cl_direccion C
    where  di_ente = @i_ente
    and di_tipo <> 'CE'
    order by di_direccion asc
--    set rowcount 0

    select @w_gasto_mens_famil = ea_ct_ventas from cobis..cl_ente_aux
    where  ea_ente = @i_ente

    select
        @w_ingreso_mensual        = isnull(@w_ingreso_mensual       ,0),
        @w_gasto_mens_famil       = isnull(@w_gasto_mens_famil      ,0),
        @w_nombre_grupo           = isnull(@w_nombre_grupo          ,''),
        @w_nombre_presi           = isnull(@w_nombre_presi          ,''),
        @w_nombre                 = isnull(@w_nombre                ,''),
        @w_apellido_paterno  = isnull(@w_apellido_paterno      ,''),
        @w_apellido_materno       = isnull(@w_apellido_materno      ,''),
        @w_calle                  = isnull(@w_calle                 ,''),
        @w_numero                 = isnull(@w_numero                ,''),
        @w_colonia                = isnull(@w_colonia               ,''),
        @w_delegacion_municipio   = isnull(@w_delegacion_municipio  ,''),
        @w_anos_en_domic_actual   = isnull(@w_anos_en_domic_actual  ,0),
        @w_ocupacion              = isnull(@w_ocupacion             ,''),
        @w_nombre_negocio         = isnull(@w_nombre_negocio        ,''),
        @w_tiempo_arraigo_negocio = isnull(@w_tiempo_arraigo_negocio,0),
        @w_tipo_local             = isnull(@w_tipo_local            ,'')


    CREATE TABLE #cr_verifica_tmp (
        vt_tramite        INT NOT NULL,
        vt_cliente        INT NOT NULL,
        vt_codigo         INT NOT NULL,
        vt_pregunta       CHAR(1000) NOT NULL,
        vt_respuesta      VARCHAR(10) NOT null
    )

    --ALTER TABLE #cr_verifica_tmp ADD CONSTRAINT pk_vt_tramite
    --PRIMARY KEY (vt_tramite, vt_cliente, vt_codigo)

    if(@w_grupal = 'S')
        select @w_grupal_aux = 'G'
    else
        select @w_grupal_aux = 'I'

    -- INSERT INTO #cr_verifica_tmp
    -- SELECT @w_tramite, @i_ente, pr_codigo, pr_descripcion, ''
    -- FROM cob_credito..cr_pregunta_ver_dat
    -- where pr_tipo = @w_grupal_aux
    -- ORDER BY pr_codigo ASC

    -- pasear las preguntas para obtener las respuestas
    IF EXISTS(SELECT 1 FROM cob_credito..cr_verifica_datos WHERE vd_inst_proceso = @i_inst_proceso AND vd_cliente = @i_ente)
    BEGIN
        -- SELECT @w_cadena = vd_respuesta
        -- FROM cob_credito..cr_verifica_datos
        -- WHERE vd_inst_proceso = @i_inst_proceso
        -- AND vd_cliente = @i_ente

        SELECT @w_cadena = isnull(@w_cadena ,'')
        SELECT @w_col1 = 1
        WHILE len(@w_cadena) > 0
        BEGIN
            SELECT @w_pos1 = charindex(';',@w_cadena)
            IF @w_pos1 > 0
            begin
                SELECT @w_resp1 = substring(@w_cadena, 1,@w_pos1 - 1)
                SELECT @w_cadena = substring(@w_cadena, @w_pos1 + 1, 200)
            END
            ELSE
            begin
                SELECT @w_resp1 = @w_cadena
                SELECT @w_cadena = NULL
            END

            UPDATE #cr_verifica_tmp SET vt_respuesta = @w_resp1
            WHERE vt_tramite = @w_tramite
            AND vt_cliente = @i_ente
            AND vt_codigo = @w_col1

            SELECT @w_col1 = @w_col1 +1
        END
    END

    if @i_modo = 4  -- para la generacion del XML
    begin
        DELETE cr_verifica_xml_tmp
        WHERE vt_x_tramite = @w_tramite
        AND vt_x_cliente   = @i_ente

        DECLARE
        @w_pregunta SMALLINT,
        @w_item SMALLINT,
        @w_descripcion  VARCHAR(255),
        @w_pos2  SMALLINT


        SELECT @w_pregunta = 0

        CREATE TABLE #cr_verifica_xml_tmp(
        codigo     INT,
        secuencial INT IDENTITY NOT NULL,
        tag        varchar(255),
        respuesta  VARCHAR(10)
        )

        WHILE 1 = 1
        BEGIN
            -- leo la pregunta
            SELECT @w_pregunta = 1
            --    TOP 1 @w_pregunta     = pr_codigo,
            --          @w_descripcion  = pr_descripcion
            FROM cob_credito..cr_pregunta_ver_dat where 1= 2
            -- WHERE pr_tipo = @w_grupal_aux
            -- AND pr_codigo > @w_pregunta
            -- ORDER BY pr_codigo
            IF @@ROWCOUNT = 0 BREAK
            --PRINT '--------->'+convert(VARCHAR, @w_pregunta) + ' - ' + + @w_descripcion
            -- parsear cada pregunta
            SELECT @w_pos1 = charindex('#', @w_descripcion)
EVAL_CAD:
            IF @w_pos1 > 0
            BEGIN
                SELECT @w_pos2 = charindex('#', @w_descripcion, @w_pos1+1)
                -- hay un tag
                IF @w_pos2 > 0
                BEGIN
                    --PRINT 'tag = '+ substring(@w_descripcion, @w_pos1, @w_pos2 - @w_pos1 + 1)
                    INSERT INTO #cr_verifica_xml_tmp VALUES(@w_pregunta, substring(@w_descripcion, @w_pos1, @w_pos2 - @w_pos1 + 1), 'x')
                    SELECT @w_descripcion = substring(@w_descripcion, @w_pos2 + 1, 1000)
                    SELECT @w_pos1 = charindex('#', @w_descripcion)
                    IF @w_pos1 > 0 GOTO EVAL_CAD
                END
                ELSE -- no hay tag
                BEGIN
                    --PRINT '- ' + convert(VARCHAR, @w_pregunta) + ' - ' + @w_descripcion
                    INSERT INTO #cr_verifica_xml_tmp VALUES(@w_pregunta, '**', 'x')
                END
            END
            ELSE -- no hay tag
            BEGIN
                --PRINT '+ ' + convert(VARCHAR, @w_pregunta) + ' - ' + @w_descripcion
                INSERT INTO #cr_verifica_xml_tmp VALUES(@w_pregunta, '**', 'x')
            END
        END -- while


        select
            @w_ingreso_mensual  = isnull (@w_ingreso_mensual,0),
            @w_gasto_mens_famil = isnull (@w_gasto_mens_famil,0),
            @w_nombre_grupo     = isnull (@w_nombre_grupo,''),
            @w_nombre_presi     = isnull (@w_nombre_presi,''),
            @w_nombre           = isnull (@w_nombre,''),
            @w_apellido_paterno = isnull (@w_apellido_paterno,''),
            @w_apellido_materno = isnull (@w_apellido_materno,''),
            @w_calle            = isnull (@w_calle,''),
            @w_numero           = isnull (@w_numero,''),
            @w_colonia          = isnull (@w_colonia,''),
            @w_delegacion_municipio     = isnull (@w_delegacion_municipio,''),
            @w_ocupacion                = isnull (@w_ocupacion,''),
            @w_nombre_negocio           = isnull (@w_nombre_negocio,''),
            @w_tiempo_arraigo_negocio   = isnull (@w_tiempo_arraigo_negocio,''),
            @w_anos_en_domic_actual     = isnull (@w_anos_en_domic_actual,''),
            @w_tipo_local               = isnull (@w_tipo_local,'')

        update #cr_verifica_xml_tmp set tag = replace(tag, '#SUELDO#', convert(varchar,cast(@w_ingreso_mensual as money),1))
        update #cr_verifica_xml_tmp set tag = replace(tag, '#GASTOS#', convert(varchar,cast(@w_gasto_mens_famil as money),1))
        update #cr_verifica_xml_tmp set tag = replace(tag, '#NOM_GRUPO#', convert(varchar, @w_nombre_grupo))
        update #cr_verifica_xml_tmp set tag = replace(tag, '#PRESIDENTE#', convert(varchar, @w_nombre_presi))
        update #cr_verifica_xml_tmp set tag = replace(tag, '#NOM_CLIENTE#', @w_nombre + ' ' + @w_apellido_paterno + ' ' + @w_apellido_materno )
        update #cr_verifica_xml_tmp set tag = replace(tag, '#DIRECCION#', @w_calle + ' ' + @w_numero + ' ' +@w_colonia + ' ' + @w_delegacion_municipio )
        update #cr_verifica_xml_tmp set tag = replace(tag, '#ACTIVIDAD#', @w_ocupacion)
        update #cr_verifica_xml_tmp set tag = replace(tag, '#COMERCIO#', @w_nombre_negocio)
        update #cr_verifica_xml_tmp set tag = replace(tag, '#TIEMPO#', convert(varchar, @w_tiempo_arraigo_negocio))
        update #cr_verifica_xml_tmp set tag = replace(tag, '#TIEMPO_VIV#', @w_anos_en_domic_actual)
        update #cr_verifica_xml_tmp set tag = replace(tag, '#TIEMPO_TR#', @w_tiempo_arraigo_negocio)
        update #cr_verifica_xml_tmp set tag = replace(tag, '#LOCAL#', @w_tipo_local)

        delete cr_verifica_xml_tmp where vt_x_tramite = @w_tramite and vt_x_cliente = @i_ente

        INSERT INTO cr_verifica_xml_tmp
        SELECT @w_tramite, @i_ente, codigo, secuencial, tag, vt_respuesta
        FROM #cr_verifica_xml_tmp, #cr_verifica_tmp
        WHERE vt_tramite = @w_tramite
        AND vt_cliente = @i_ente
        and vt_codigo  = codigo

        drop TABLE #cr_verifica_tmp

        return 0
    END -- mod = 4

    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#SUELDO#', convert(varchar,cast(@w_ingreso_mensual as money),1))
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#GASTOS#', convert(varchar,cast(@w_gasto_mens_famil as money),1))
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#NOM_GRUPO#', convert(varchar, @w_nombre_grupo))
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#PRESIDENTE#', convert(varchar, @w_nombre_presi))
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#NOM_CLIENTE#', @w_nombre + ' ' + @w_apellido_paterno + ' ' + @w_apellido_materno )
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#DIRECCION#', @w_calle + ' ' + @w_numero + ' ' +@w_colonia + ' ' + @w_delegacion_municipio )
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#ACTIVIDAD#', @w_ocupacion)
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#COMERCIO#', @w_nombre_negocio)
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#TIEMPO#', convert(varchar, @w_tiempo_arraigo_negocio))
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#TIEMPO_VIV#', @w_anos_en_domic_actual)
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#TIEMPO_TR#', @w_tiempo_arraigo_negocio)
    update #cr_verifica_tmp set vt_pregunta = replace(vt_pregunta, '#LOCAL#', @w_tipo_local)

    if @i_modo = 1
    begin
        if (@w_grupal = 'S')
        begin
            -- grilla No.1
            SELECT vt_tramite, vt_cliente, vt_codigo, vt_pregunta, vt_respuesta,@w_resultado
            FROM #cr_verifica_tmp
            WHERE vt_tramite = @w_tramite
            AND vt_cliente = @i_ente
            and vt_codigo between 1 and 5
            ORDER BY vt_codigo
        end
        else
        begin
            SELECT vt_tramite, vt_cliente, vt_codigo, vt_pregunta, vt_respuesta,@w_resultado
            FROM #cr_verifica_tmp
            WHERE vt_tramite = @w_tramite
            AND vt_cliente = @i_ente
            and vt_codigo between 1 and 2
            ORDER BY vt_codigo
        end
    end
    if @i_modo = 2
    begin
        if (@w_grupal = 'S')
        begin
           -- grilla No.2
           SELECT vt_tramite, vt_cliente, vt_codigo, vt_pregunta, vt_respuesta,@w_resultado
           FROM #cr_verifica_tmp
           WHERE vt_tramite = @w_tramite
           AND vt_cliente = @i_ente
           and vt_codigo between 6 and 12
           ORDER BY vt_codigo
        end
        else
        begin
           -- grilla No.2
           SELECT vt_tramite, vt_cliente, vt_codigo, vt_pregunta, vt_respuesta,@w_resultado
           FROM #cr_verifica_tmp
           WHERE vt_tramite = @w_tramite
           AND vt_cliente = @i_ente
           and vt_codigo between 3 and 9
           ORDER BY vt_codigo
        end
    end

    if @i_modo = 3
    begin
        if (@w_grupal = 'S')
        begin
           -- grilla No.3
               SELECT vt_tramite, vt_cliente, vt_codigo, vt_pregunta, vt_respuesta,@w_resultado
           FROM #cr_verifica_tmp
           WHERE vt_tramite = @w_tramite
           AND vt_cliente = @i_ente
           and vt_codigo > 12
           ORDER BY vt_codigo
        end
        else
        begin
            -- grilla No.3
               SELECT vt_tramite, vt_cliente, vt_codigo, vt_pregunta, vt_respuesta,@w_resultado
           FROM #cr_verifica_tmp
           WHERE vt_tramite = @w_tramite
           AND vt_cliente = @i_ente
           and vt_codigo > 9
           ORDER BY vt_codigo
        end
    end

end -- Fin Operacion Q

return 0

ERROR:
    begin --Devuelve mensaje de Error
        exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file,
             @t_from  = @w_sp_name,
             @i_num   = @w_error
        return @w_error
    end
*/
--LPO CDIG Se comenta porque Cobis Language no soporta XML FIN

RETURN 0
GO