/********************************************************************/
/*   NOMBRE LOGICO:         sp_tramite_miembros                     */
/*   NOMBRE FISICO:         sp_tramite_miembros.sp                  */
/*   BASE DE DATOS:         cob_credito                             */
/*   PRODUCTO:              Credito                                 */
/*   DISENADO POR:          P. Jarrin.                              */
/*   FECHA DE ESCRITURA:    04-Ene-2023                             */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                     PROPOSITO                                    */
/*   Este stored procedure permite consultar informacion y registro */
/*   de log                                                         */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   04-Ene-2023        P. Jarrin.       Emision Inicial - S735667  */
/*   17-Feb-2023        P. Jarrin.       S779052 - Consulta de Buro */
/*   06-Abr-2023        D. Morales.      Se añade operacion V       */
/*   19-Dic-2023        D. Morales.      R221386: Se añade roles    */
/*                                       para crédito individual    */
/********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_tramite_miembros')
   drop proc sp_tramite_miembros
go

CREATE proc sp_tramite_miembros (
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
    @t_show_version         bit             = 0,
    @t_debug                char(1)         = 'N',
    @t_file                 varchar(10)     = null,
    @t_from                 varchar(32)     = null,
    @t_trn                  int             = null,
    @i_tramite              int             = null,
    @i_operacion            char(1),                -- Opcion con que se ejecuta el programa    
    @i_id_ente              int             = null,
    @i_identificacion       varchar(30)     = null, 
    @i_cuota                money           = null,
    @i_saldo_corto_plazo    money           = null,
    @i_calificacion         money           = null, 
    @i_saldo_largo_plazo    money           = null, 
    @i_documento            varchar(255)    = null,
    @i_revisa_buro          varchar(2)      = null,
    @i_comparte_data        varchar(60)     = null
)
as
declare @w_sp_name                      varchar(32),
        @w_doc_deudor                   varchar(100),
        @w_doc_deudor_code              int,
        @w_doc_deudor_conyuge           varchar(100),
        @w_doc_deudor_conyuge_code      int,
        @w_doc_codeudor_1               varchar(100),
        @w_doc_codeudor_code_1          int,
        @w_doc_codeudor_conyuge_1       varchar(100),
        @w_doc_codeudor_conyuge_code_1  int,
        @w_doc_codeudor_2               varchar(100),
        @w_doc_codeudor_code_2          int,
        @w_doc_codeudor_conyuge_2       varchar(100),
        @w_doc_codeudor_conyuge_code_2  int,
        @w_doc_fiador_1                 varchar(100),
        @w_doc_fiador_code_1            int,
        @w_doc_fiador_conyuge_1         varchar(100),
        @w_doc_fiador_conyuge_code_1    int,
        @w_doc_fiador_2                 varchar(100),
        @w_doc_fiador_code_2            int,
        @w_doc_fiador_conyuge_2         varchar(100),
        @w_doc_fiador_conyuge_code_2    int,
        @w_doc_aval_1                   varchar(100),
        @w_doc_aval_code_1              int,
        @w_doc_aval_conyuge_1           varchar(100),
        @w_doc_aval_conyuge_code_1      int,
        @w_doc_aval_2                   varchar(100),
        @w_doc_aval_code_2              int,
        @w_doc_aval_conyuge_2           varchar(100),
        @w_doc_aval_conyuge_code_2      int,
        @w_tiempo                       int,
        @w_fecha_actual                 date,
        @w_validar                      char(1),
        @w_inst_act                     int,
        @w_error                        int,
        @w_trn                          int,
        @w_relacion                     tinyint,
        @w_msg_error                    varchar(132)
        
select @w_sp_name = 'sp_tramite_miembros',
       @w_trn     = isnull(@t_trn,21857)
       
       
select @w_relacion = pa_tinyint
from cobis..cl_parametro
where pa_nemonico   = 'CONY' --Relacion Conyuge
and pa_producto     = 'CLI'    
       
--Parametros
select @w_doc_deudor   = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'DOCBD'
select @w_doc_deudor_code = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_deudor
     

select @w_doc_deudor_conyuge  = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'DOCCB'
select @w_doc_deudor_conyuge_code = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_deudor_conyuge

--CREDITO INDIVIDUAL
--CODEUDOR 1
select @w_doc_codeudor_1 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'DOCBC'
select @w_doc_codeudor_code_1 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_codeudor_1


--CONYUGE CODEUDOR 1
select @w_doc_codeudor_conyuge_1 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'DOCCC1'
select @w_doc_codeudor_conyuge_code_1 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_codeudor_conyuge_1


--CODEUDOR 2
select @w_doc_codeudor_2 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'DOCBC2'
select @w_doc_codeudor_code_2 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_codeudor_2


--CONYUGE CODEUDOR 2
select @w_doc_codeudor_conyuge_2 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'DOCCC2'
select @w_doc_codeudor_conyuge_code_2 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_codeudor_conyuge_2

--FIADOR 1
select @w_doc_fiador_1 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'CIFIA1'
select @w_doc_fiador_code_1 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_fiador_1

--CONYUGE FIADOR 1
select @w_doc_fiador_conyuge_1 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'CIFIC1'
select @w_doc_fiador_conyuge_code_1 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_fiador_conyuge_1

--FIADOR 2
select @w_doc_fiador_2 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'CIFIA2'
select @w_doc_fiador_code_2 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_fiador_2


--CONYUGE FIADOR 2
select @w_doc_fiador_conyuge_2 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'CIFIC2'
select @w_doc_fiador_conyuge_code_2 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_fiador_conyuge_2
    

--AVAL 1
select @w_doc_aval_1 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'CIAVA1'
select @w_doc_aval_code_1 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_aval_1

--CONYUGE AVAL 1
select @w_doc_aval_conyuge_1 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'CIAVC1'
select @w_doc_aval_conyuge_code_1 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_aval_conyuge_1

--AVAL 2
select @w_doc_aval_2 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'CIAVA2'
select @w_doc_aval_code_2 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_aval_2


--CONYUGE AVAL 2
select @w_doc_aval_conyuge_2 = pa_char from cobis..cl_parametro  with (nolock) where pa_nemonico = 'CIAVC2'
select @w_doc_aval_conyuge_code_2 = td_codigo_tipo_doc
      from cob_workflow..wf_tipo_documento
     where td_nombre_tipo_doc = @w_doc_aval_conyuge_2
 

select @w_doc_deudor   = isnull(@w_doc_deudor ,'') + '/DOCBD' 
select @w_doc_deudor_conyuge   = isnull(@w_doc_deudor_conyuge,'')  + '/DOCBD'        

select @w_doc_codeudor_1 = isnull(@w_doc_codeudor_1,'') + '/DOCBD'
select @w_doc_codeudor_conyuge_1 = isnull(@w_doc_codeudor_conyuge_1,'') + '/DOCBD'
select @w_doc_codeudor_2 = isnull(@w_doc_codeudor_2,'') + '/DOCBD'
select @w_doc_codeudor_conyuge_2 = isnull(@w_doc_codeudor_conyuge_2,'') + '/DOCBD'

select @w_doc_fiador_1 = isnull(@w_doc_fiador_1,'') + '/DOCBD'
select @w_doc_fiador_conyuge_1 = isnull(@w_doc_fiador_conyuge_1,'') + '/DOCBD'
select @w_doc_fiador_2 = isnull(@w_doc_fiador_2,'') + '/DOCBD'
select @w_doc_fiador_conyuge_2 = isnull(@w_doc_fiador_conyuge_2,'') + '/DOCBD'

select @w_doc_aval_1 = isnull(@w_doc_aval_1,'') + '/DOCBD'
select @w_doc_aval_conyuge_1 = isnull(@w_doc_aval_conyuge_1,'') + '/DOCBD'
select @w_doc_aval_2 = isnull(@w_doc_aval_2,'') + '/DOCBD'
select @w_doc_aval_conyuge_2 = isnull(@w_doc_aval_conyuge_2,'') + '/DOCBD'

if @i_operacion = 'S'
begin

    create table #roles_permitidos
    (
    tipo_participante   varchar(10)  null
    )
    insert into #roles_permitidos
    select c.codigo  
    from cobis..cl_tabla t with(nolock)
    inner join cobis..cl_catalogo c on c.tabla = t.codigo 
    where t.tabla = 'cr_buro_ci'
    
    create table #tmp_miembros
    (
    posicion        tinyint      null,
    tipo_participante   varchar(10)  null,
    id              int          null,
    nombre          varchar(255) null,
    tramite         int          null,
    valida          char(1)      null,
    identificacion  varchar(30)  null,
    tipo            char(1)      null,
    nombre_doc      varchar(100) null,
    codigo_doc      int          null,
    revisar_buro    varchar(2)   null,
    compartir_data  varchar(60)  null
    )
    
    select @w_inst_act = ia_id_inst_act from 
    cob_workflow..wf_inst_proceso 
    inner join cob_workflow..wf_inst_actividad on ia_id_inst_proc = io_id_inst_proc
    where io_campo_3  = @i_tramite and ia_estado = 'ACT'
            
    if exists ( select 1 from  cob_credito..cr_tramite_grupal t where tg_tramite = @i_tramite)
    begin
        insert into #tmp_miembros 
        select 1,
               '',
               tg_cliente,
               (select en_nomlar from cobis..cl_ente where en_ente = tg_cliente),
               tg_tramite,
               (dbo.fn_valida_burocredito (tg_cliente)),
               (select en_ced_ruc from cobis..cl_ente where en_ente = tg_cliente),
               (select en_subtipo from cobis..cl_ente where en_ente = tg_cliente),
               @w_doc_deudor,
               @w_doc_deudor_code,             
               (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = tg_cliente),
               (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = tg_cliente)
          from cob_credito..cr_tramite_grupal t
         where tg_tramite         = @i_tramite
           and tg_participa_ciclo = 'S' 
         order by tg_cliente         
    end
    else
    begin
        --DEUDOR PRINCIPAL
        if exists( select 1 from #roles_permitidos where tipo_participante = 'DOCBD') --1 requisito
        begin
            insert into #tmp_miembros   
            select
            1,
            'DOCBD',
            de_cliente,
            (select en_nomlar from cobis..cl_ente where en_ente = de_cliente),
            tr_tramite,
            (dbo.fn_valida_burocredito (de_cliente)),
            (select en_ced_ruc from cobis..cl_ente where en_ente = de_cliente),
            (select en_subtipo from cobis..cl_ente where en_ente = de_cliente),
            @w_doc_deudor,
            @w_doc_deudor_code,
            (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = de_cliente),
            (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = de_cliente)
            from cob_credito.dbo.cr_tramite
            inner join  cob_credito.dbo.cr_deudores on de_tramite = tr_tramite
            where tr_tramite = @i_tramite
            and de_rol = 'D'
        end

        --CONYUGE DEUDOR PRINCIPAL
        if exists( select 1 from #roles_permitidos where tipo_participante = 'DOCCB')--1 requisito
        begin
            insert into #tmp_miembros   
            select 
            1,
            'DOCCB',
            en_ente,
            en_nomlar,
            @i_tramite,
            (dbo.fn_valida_burocredito (en_ente)),
            en_ced_ruc,
            en_subtipo,
            @w_doc_deudor_conyuge,
            @w_doc_deudor_conyuge_code ,
            (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = en_ente),
            (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = en_ente)
            from #tmp_miembros  , cobis..cl_instancia ,cobis..cl_ente
            where id = in_ente_i 
            and in_relacion = @w_relacion 
            and in_ente_d = en_ente
            and tipo_participante = 'DOCBD'
        end

        --CODEUDORES
        if exists( select 1 from #roles_permitidos where tipo_participante = 'DOCBC')--2 requisito
        begin
            insert into #tmp_miembros   
            select
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            'DOCBC',
            de_cliente,
            (select en_nomlar from cobis..cl_ente where en_ente = de_cliente),
            tr_tramite,
            (dbo.fn_valida_burocredito (de_cliente)),
            (select en_ced_ruc from cobis..cl_ente where en_ente = de_cliente),
            (select en_subtipo from cobis..cl_ente where en_ente = de_cliente),
            null,
            null,
            (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = de_cliente),
            (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = de_cliente)
            from cob_credito.dbo.cr_tramite
            inner join  cob_credito.dbo.cr_deudores on de_tramite = tr_tramite
            where tr_tramite = @i_tramite
            and de_rol = 'C'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_codeudor_1,
                codigo_doc = @w_doc_codeudor_code_1
            where posicion % 2 <> 0
            and tipo_participante = 'DOCBC'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_codeudor_2,
                codigo_doc = @w_doc_codeudor_code_2
            where posicion % 2 = 0
            and tipo_participante = 'DOCBC'
        end

        --CONYUGE CODEUDORES
        if exists( select 1 from #roles_permitidos where tipo_participante = 'DOCCC')--2 requisito
        begin
            insert into #tmp_miembros   
            select 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            'DOCCC',
            en_ente,
            en_nomlar,
            @i_tramite,
            (dbo.fn_valida_burocredito (en_ente)),
            en_ced_ruc,
            en_subtipo,
            null,
            null,
            (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = en_ente),
            (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = en_ente)
            from #tmp_miembros  , cobis..cl_instancia ,cobis..cl_ente
            where id = in_ente_i 
            and in_relacion = @w_relacion 
            and in_ente_d = en_ente
            and tipo_participante = 'DOCBC'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_codeudor_conyuge_1,
                codigo_doc = @w_doc_codeudor_conyuge_code_1
            where posicion % 2 <> 0
            and tipo_participante = 'DOCCC'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_codeudor_conyuge_2,
                codigo_doc = @w_doc_codeudor_conyuge_code_2
            where posicion % 2 = 0
            and tipo_participante = 'DOCCC'
        end


        --FIADORES
        if exists( select 1 from #roles_permitidos where tipo_participante = 'CIFIA')--2 requisito
        begin
            insert into #tmp_miembros   
            select
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            'CIFIA',
            cu_garante,
            (select en_nomlar from cobis..cl_ente where en_ente = cu_garante),
            gp_tramite,
            (dbo.fn_valida_burocredito (cu_garante)),
            (select en_ced_ruc from cobis..cl_ente where en_ente = cu_garante),
            (select en_subtipo from cobis..cl_ente where en_ente = cu_garante),
            null,
            null,
            (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = cu_garante),
            (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = cu_garante)          
            from cob_credito..cr_gar_propuesta
            inner join cob_custodia..cu_custodia on cu_codigo_externo = gp_garantia
            where gp_tramite = @i_tramite 
            and cu_garante is not null
            
            update #tmp_miembros
            set nombre_doc = @w_doc_fiador_1,
                codigo_doc = @w_doc_fiador_code_1
            where posicion % 2 <> 0
            and tipo_participante = 'CIFIA'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_fiador_2,
                codigo_doc = @w_doc_fiador_code_2
            where posicion % 2 = 0
            and tipo_participante = 'CIFIA'
            
            
        end

        --CONYUGUE FIADORES
        if exists( select 1 from #roles_permitidos where tipo_participante = 'CIFIC')--2 requisito
        begin
            insert into #tmp_miembros   
            select 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            'CIFIC',
            en_ente,
            en_nomlar,
            @i_tramite,
            (dbo.fn_valida_burocredito (en_ente)),
            en_ced_ruc,
            en_subtipo,
            null,
            null,
            (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = en_ente),
            (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = en_ente)
            from #tmp_miembros  , cobis..cl_instancia ,cobis..cl_ente
            where id = in_ente_i 
            and in_relacion = @w_relacion 
            and in_ente_d = en_ente
            and tipo_participante = 'CIFIA'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_fiador_conyuge_1,
                codigo_doc = @w_doc_fiador_conyuge_code_1
            where posicion % 2 <> 0
            and tipo_participante = 'CIFIC'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_fiador_conyuge_2,
                codigo_doc = @w_doc_fiador_conyuge_code_2
            where posicion % 2 = 0
            and tipo_participante = 'CIFIC'
        end

        --AVALES
        if exists( select 1 from #roles_permitidos where tipo_participante = 'CIAVA')--2 requisito
        begin
            insert into #tmp_miembros   
            select
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            'CIAVA',
            cg_ente,
            (select en_nomlar from cobis..cl_ente where en_ente = cg_ente),
            gp_tramite,
            (dbo.fn_valida_burocredito (cg_ente)),
            (select en_ced_ruc from cobis..cl_ente where en_ente = cg_ente),
            (select en_subtipo from cobis..cl_ente where en_ente = cg_ente),
            null,
            null,
            (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = cg_ente),
            (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = cg_ente)
            from cob_credito..cr_gar_propuesta
            inner join cob_custodia..cu_cliente_garantia on cg_codigo_externo = gp_garantia
            where gp_tramite = @i_tramite
            and cg_ente not in (select id from #tmp_miembros )
            
            
            update #tmp_miembros
            set nombre_doc = @w_doc_aval_1,
                codigo_doc = @w_doc_aval_code_1
            where posicion % 2 <> 0
            and tipo_participante = 'CIAVA'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_aval_2,
                codigo_doc = @w_doc_aval_code_2
            where posicion % 2 = 0
            and tipo_participante = 'CIAVA'
        end
        --CONYUGUE AVALES
        if exists( select 1 from #roles_permitidos where tipo_participante = 'CIAVC')--2 requisito
        begin
            insert into #tmp_miembros   
            select 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
            'CIAVC',
            en_ente,
            en_nomlar,
            @i_tramite,
            (dbo.fn_valida_burocredito (en_ente)),
            en_ced_ruc,
            en_subtipo,
            null,
            null,
            (select isnull(ea_antecedente_buro,'N') from cobis..cl_ente_aux where ea_ente = en_ente),
            (select isnull(ea_persona_recados,'N') from cobis..cl_ente_aux where ea_ente = en_ente)
            from #tmp_miembros  , cobis..cl_instancia ,cobis..cl_ente
            where id = in_ente_i 
            and in_relacion = @w_relacion 
            and in_ente_d = en_ente
            and tipo_participante = 'CIAVA'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_aval_conyuge_1,
                codigo_doc = @w_doc_aval_conyuge_code_1
            where posicion % 2 <> 0
            and tipo_participante = 'CIAVC'
            
            update #tmp_miembros
            set nombre_doc = @w_doc_aval_conyuge_2,
                codigo_doc = @w_doc_aval_conyuge_code_2
            where posicion % 2 = 0
            and tipo_participante = 'CIAVC'
        end
    end

    select 'CODIGO'         = id,
           'NOMBRE'         = nombre,  
           'TRAMITE'        = tramite,  
           'VALIDA'         = valida,
           'IDENTIFICACION' = identificacion,
           'TIPO_CLIENTE'   = tipo,
           'DOCUMENTO'      = nombre_doc,
           'COD_DOCMENTO'   = codigo_doc,
           'ACTIVIDAD'      = @w_inst_act,
           'REVISAR_BURO'   = revisar_buro,
           'COMPARTIR_DATA' = compartir_data
      from #tmp_miembros
      order by id
end


if @i_operacion = 'R'
begin
    insert into ts_creditbureau (
    secuencial,              tipo_transaccion,               clase,
    fecha,                   usuario,                        terminal, 
    srv,                     lsrv,                           ente,    
    fecha_consulta,          tramite,                        saldo_cuota,
    saldo_corto_plazo,       saldo_largo_plazo,              calificacion,
    identificacion,          documento)
    values  (
    @s_ssn,                  @w_trn,                         'I',
    getdate(),               @s_user,                        @s_term,
    @s_srv,                  @s_lsrv,                        @i_id_ente,
    getDate(),               @i_tramite,                     @i_cuota,
    @i_saldo_corto_plazo,    @i_saldo_largo_plazo,           @i_calificacion,
    @i_identificacion,       @i_documento)
    
    if @@error <> 0 
    begin
       select @w_error = 2103003
       goto ERROR
    end
end

if @i_operacion = 'M'
begin
    update cobis..cl_ente_aux 
       set ea_antecedente_buro  = isnull(@i_revisa_buro, ea_antecedente_buro),
           ea_persona_recados   = isnull(@i_comparte_data, ea_persona_recados)
    where ea_ente = @i_id_ente
    
    if @@error <> 0 
    begin
       select @w_error = 1720327
       goto ERROR
    end
end

if @i_operacion = 'V'
begin
    
    select 'CONSULTA DISPONIBLE' = dbo.fn_valida_burocredito (@i_id_ente)

end

return 0

ERROR:
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = @w_error,
     @i_msg   = @w_msg_error
    return @w_error
go
