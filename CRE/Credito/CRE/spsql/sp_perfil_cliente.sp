/********************************************************************/
/*   NOMBRE LOGICO:        sp_perfil_cliente                        */
/*   NOMBRE FISICO:        sp_perfil_cliente.sp                     */
/*   BASE DE DATOS:        cob_credito                              */
/*   PRODUCTO:             Credito                                  */
/*   DISENADO POR:         D. Morales                               */
/*   FECHA DE ESCRITURA:   24-Ene-2023                              */
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
/*  Este stored procedure permite consultar informacion del perfil  */
/*  cliente                                                         */
/********************************************************************/
/*                     MODIFICACIONES                               */
/*   FECHA              AUTOR              RAZON                    */
/*   24-Ene-2023        D. Morales.      Emision Inicial - S762876  */
/*   23-Mar-2023        D. Morales.      Se corrige select participa*/
/*   30-Mar-2023        P. Jarrin.       Se agrega orden - S801301  */
/*   16-Ene-2025        G. Romero        REq 248888                 */
/*   03-Jul-2025        G. Romero        Psedónimo y NRC error imprime*/
/*   03-Jul-2025        F. Rincon        limpieza variables de traba*/
/********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_perfil_cliente')
   drop proc sp_perfil_cliente
go

CREATE proc sp_perfil_cliente (
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
    @i_tipo                 char(1),    
    @i_id_ente              int             = null
)
as
declare @w_sp_name              varchar(32),
        @w_tipo_relacion        int,
        @w_conyuge              int,
        @w_ente                 int,
        @w_provincia            smallint,
        @w_ciudad               int,
        @w_parroquia            int,
        @w_casa                 varchar(40),
        @w_num_casa             varchar(40),
        @w_sector               catalogo,
        @w_descripcion_dir      varchar(255),
        @w_tenencia_vivienda    catalogo,
        @w_tiempo_residen       int,
        @w_cod_trabajo          int,
        @w_empresa_trabajo      descripcion,
        @w_actividad            catalogo,
        @w_telf_trabajo         varchar(16),
        @w_cod_oficial          int,
        @w_desc_oficial         varchar(64),
        @w_fecha_ini            date,
        @w_tramite              int,
        @w_cod_seudonimo        int,
        @w_cod_contribuyente_iva varchar(10),
		@w_cod_nrc              int,          
        @w_seudonimo            varchar(160),
        @w_contribuyente_iva    varchar(160),
        @w_referencia           int,
        @w_telf_vivienda        varchar(16),
        @w_telf_celular         varchar(16),
        @w_error                int,
        @w_trn                  int
        

declare @w_participantes as table(
cod_cliente         int             null,
fecha_impre         varchar(30)     null,
fehca_evaluacion    varchar(30)     null,
nombre_completo     varchar(255)    null,
conocido_por        varchar(255)    null,
seudonimo           varchar(160)    null,
est_civil           varchar(64)     null,
sexo                varchar(64)     null,
escolaridad         varchar(64)     null,
anios_activi        int             null,
tipo_identifi       varchar(64)     null,
ocupacion           varchar(64)     null,
dni                 varchar(30)     null,
nit                 varchar(30)     null,
ciudad_emision      varchar(64)     null,
fecha_emision       varchar(30)     null,
fecha_vencimiento   varchar(30)     null,
nacionalidad        varchar(160)    null,
lugar_nac           varchar(64)     null,
fecha_nac           varchar(30)     null,
departamento        varchar(64)     null,
municipio           varchar(64)     null,
canton              varchar(64)     null,
avenida             varchar(64)     null,
num_casa            varchar(40)     null,
area                varchar(64)     null,
ref_domiciliar      varchar(255)    null,
contribuyente       varchar(160)     null,
es_expuesta_poli    char(1)         null,
es_vinculada_poli   varchar(100)    null,
telf_vivienda       varchar(16)     null,
telf_celular        varchar(16)     null,
nombre_conyuge      varchar(215)    null,
lugar_trabajo       varchar(16)     null,
trabajo             varchar(64)     null,
telf_trabajo        varchar(16)     null,
num_miembros_fami   int             null,
tenencia_vivienda   varchar(64)     null,  
tiempo_residencia   varchar(64)     null,
nombre_oficial      varchar(64)     null,
sujeto_retencion    char(1)         null    
)

declare @w_referencias as table(
nombre_completo     varchar(255)    null,
telf_vivienda       varchar(16)     null,
telf_celular        varchar(16)     null,
parentesco          catalogo        null
)
       
        
select @w_sp_name = 'sp_perfil_cliente',
       @w_trn     = isnull(@t_trn,21863)


select  @w_tipo_relacion = pa_tinyint from cobis..cl_parametro where pa_nemonico = 'CONY' and pa_producto = 'CLI'
if (@w_tipo_relacion is null )
begin
    select @w_error = 609327
    goto ERROR
end
select  @w_cod_seudonimo = pa_int from cobis..cl_parametro where pa_nemonico = 'CODSEU' and pa_producto = 'CLI'
if (@w_cod_seudonimo is null )
begin
    select @w_error = 609327
    goto ERROR
end
select  @w_cod_contribuyente_iva = pa_char from cobis..cl_parametro where pa_nemonico = 'CONIVA' and pa_producto = 'CLI'
if (@w_cod_contribuyente_iva is null )
begin
    select @w_error = 609327
    goto ERROR
end

select  @w_cod_nrc = pa_smallint from cobis..cl_parametro where pa_nemonico = 'DADNRC' and pa_producto = 'CLI'
if (@w_cod_nrc is null )
begin
    select @w_error = 609327
    goto ERROR
end

if(@i_id_ente is null and @i_tramite is null)
begin
    select @w_error = 2110256
    goto ERROR
end


if(@i_operacion = 'Q')
begin
    if(@i_tipo = 'C')
    begin   
        if(@i_id_ente is not null)
        begin 
            declare cur_participantes cursor read_only for (select @i_id_ente , null)
        end 
        else if(@i_tramite is not null)
        begin       
            if exists(select 1 from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)
            begin
            
                IF OBJECT_ID('tempdb..#tmp_participantes') IS NOT NULL
                drop table #tmp_participantes

                create table #tmp_participantes
                (
                    cliente    int,
                    tramite    int null,
                    rol        char(1),
                    orden      smallint 
                )

                insert into #tmp_participantes
                select tg_cliente, 
                       op_tramite, 
                       (select cg_rol from cobis..cl_cliente_grupo where  cg_ente = tg_cliente and cg_grupo = tg_grupo),
                       0
                      from cob_credito..cr_tramite_grupal 
                     inner join cob_cartera..ca_operacion on tg_operacion = op_operacion
                     where tg_tramite = @i_tramite and tg_participa_ciclo = 'S'
                     order by tg_cliente
                       
                update #tmp_participantes
                   set orden = 1
                 where rol = 'P'

                update #tmp_participantes
                   set orden = 2
                 where rol not in ('P' , 'M')

                update #tmp_participantes
                   set orden = 3
                 where rol = 'M'
         
                declare cur_participantes cursor read_only for select cliente, tramite from #tmp_participantes order by orden
            end
            else
            begin
                
                if not exists(select 1 from cob_credito..cr_tramite where tr_tramite = @i_tramite)
                begin
                    select @w_error = 2110152
                    goto ERROR
                end
                
                declare cur_participantes cursor read_only for ( select de_cliente, de_tramite from cob_credito..cr_deudores where de_tramite = @i_tramite)
    
            end     
        end 
    
    
        open cur_participantes
        fetch cur_participantes into @w_ente, @w_tramite
        while (@@fetch_status = 0)
        begin
		
            select @w_conyuge = null,
                   @w_empresa_trabajo = null,
                   @w_cod_trabajo = null,
                   @w_actividad = null,
                   @w_telf_trabajo = null,
                   @w_cod_oficial = null,
                   @w_fecha_ini = null,
                   @w_desc_oficial = null
           
            select @w_conyuge = in_ente_d from cobis..cl_instancia with(nolock) where in_relacion = @w_tipo_relacion and in_ente_i = @w_ente 
            select  @w_provincia            = di_provincia, 
                    @w_ciudad               = di_ciudad, 
                    @w_parroquia            = di_parroquia, 
                    @w_casa                 = di_casa, 
                    @w_num_casa             = di_numero_casa,
                    @w_sector               = di_sector,
                    @w_descripcion_dir      = di_descripcion,
                    @w_tenencia_vivienda    = di_tipo_prop,
                    @w_tiempo_residen       = di_tiempo_reside
            from cobis..cl_direccion with(nolock) where di_ente = @w_ente and di_tipo = 'RE'
            
		    select  @w_empresa_trabajo  = tr_empresa, 
                    @w_cod_trabajo      = tr_trabajo, 
                    @w_actividad        = tr_cod_actividad 
            from cobis..cl_trabajo where tr_persona = @w_ente and  tr_fecha_salida is null
            
            
             select @w_telf_trabajo = rt_numero_tel from cobis..cl_ref_telefono where rt_ente = @w_ente and rt_referencia = 'L' and rt_secuencial = @w_cod_trabajo
            
            if(@w_tramite is not null)
            begin
            
                select  @w_cod_oficial  = op_oficial,
                        @w_fecha_ini    = op_fecha_ini
                from cob_cartera..ca_operacion where op_tramite = @w_tramite 
                
                select @w_desc_oficial = fu_nombre from cobis..cc_oficial with(nolock), cobis..cl_funcionario with(nolock)
                                    where oc_oficial =  @w_cod_oficial and oc_funcionario = fu_funcionario
                                    
            end
            else
            begin
                select @w_cod_oficial   = en_oficial from cobis..cl_ente where en_ente = @w_ente   
                select @w_desc_oficial = fu_nombre from cobis..cc_oficial with(nolock), cobis..cl_funcionario with(nolock)
                                    where oc_oficial =  @w_cod_oficial and oc_funcionario = fu_funcionario
                select  @w_fecha_ini = fp_fecha from cobis..ba_fecha_proceso 
            end 
                        
            insert into @w_participantes 
            select 
            en_ente, --1
            convert(varchar,getdate(), 103),
            convert(varchar,@w_fecha_ini , 103), --revisar cuando es clientes o xsell
            (isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido + ' ','') + isnull(p_c_apellido,'')),
            (select ea_conocido_como from cobis..cl_ente_aux with(nolock)  where ea_ente = en_ente),
            (select de_valor from cobis..cl_dadicion_ente where de_dato = @w_cod_seudonimo and de_ente = en_ente),
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)  
                on C.tabla = T.codigo  where T.tabla = 'cl_ecivil' and C.codigo = p_estado_civil),
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_sexo' and C.codigo = p_sexo),
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_nivel_estudio' and C.codigo = p_nivel_estudio),
            (select top 1 nc_tiempo_actividad from cobis..cl_negocio_cliente with(nolock) where nc_ente = en_ente), --10
            (select top 1 ti_descripcion from cobis..cl_tipo_identificacion  with(nolock) where ti_codigo =  en_tipo_ced),
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_ocupacion' and C.codigo = p_ocupacion),
            en_ced_ruc,
            en_nit,
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_ciudad' and C.codigo = en_ciudad_emision),
            convert(varchar,p_fecha_emision, 103),
            convert(varchar,p_fecha_expira, 103),       
            (select top 1 pa_nacionalidad from cobis..cl_pais  with(nolock) where pa_pais = en_pais_nac),
            (select top 1 pv_descripcion from cobis..cl_provincia where pv_provincia = en_provincia_nac and pv_pais = en_pais_nac),
            convert(varchar,p_fecha_nac, 103),--20
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_provincia' and C.codigo = @w_provincia),
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_ciudad' and C.codigo = @w_ciudad),
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_parroquia' and C.codigo = @w_parroquia),
            @w_casa,
            @w_num_casa,
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_sector_geografico' and C.codigo = @w_sector),
            @w_descripcion_dir,
            (select de_valor from cobis..cl_dadicion_ente where de_dato = @w_cod_nrc and de_ente = en_ente),
            (case  when (p_tipo_pep is not null and p_tipo_pep > 0 ) then 'S' else 'N' end ),
            (case  when ( en_nombre_pep_relac is not null) then 'S' else 'N' end ), --30
            (select top 1 te_valor from cobis..cl_telefono with(nolock) where te_ente = en_ente),
            (select ea_telef_recados   from cobis..cl_ente_aux with(nolock) where ea_ente = en_ente),
            (select isnull(en_nombre + ' ','') + isnull(p_s_nombre + ' ','') + isnull(p_p_apellido + ' ','') + isnull(p_s_apellido,'')
                from cobis..cl_ente where en_ente = @w_conyuge),
			(Select en_inf_laboral FROM cobis..cl_ente WHERE en_ente=@w_conyuge),
            
			(select C.valor from cobis..cl_catalogo C with(nolock) 
			inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo
			inner join cobis..cl_ente E with(nolock)
				on E.en_actividad = C.codigo	where T.tabla = 'cl_actividad_ec' and E.en_ente = @w_conyuge),
				
            (Select ea_telef_recados FROM cobis..cl_ente_aux WHERE ea_ente=@w_conyuge),
            p_num_cargas,
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_tipo_vivienda' and C.codigo = @w_tenencia_vivienda),
            (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                on C.tabla = T.codigo  where T.tabla = 'cl_referencia_tiempo' and C.codigo = @w_tiempo_residen),
            @w_desc_oficial, --39
			en_retencion         
            from cobis..cl_ente where en_ente = @w_ente 
            if @@error <> 0 
            begin
                select @w_error = 2610180
                goto ERROR
                close cur_participantes
                deallocate cur_participantes
            end
            
            fetch cur_participantes into @w_ente, @w_tramite
        end
        close cur_participantes
        deallocate cur_participantes
        
        select
            'COD_CLIENTE'       =   cod_cliente         ,
            'FECHA_IMPRE'       =   fecha_impre         ,
            'FEHCA_EVALUACION'  =   fehca_evaluacion    ,
            'NOMBRE_COMPLETO'   =   nombre_completo     ,
            'CONOCIDO_POR'      =   conocido_por        ,
            'SEUDONIMO'         =   seudonimo           ,
            'EST_CIVIL'         =   est_civil           ,           
            'SEXO'              =   sexo                ,
            'ESCOLARIDAD'       =   escolaridad         ,
            'ANIOS_ACTIVI'      =   anios_activi        ,
            'TIPO_IDENTIFI'     =   tipo_identifi       ,
            'OCUPACION'         =   ocupacion           ,
            'DNI'               =   dni                 ,
            'NIT'               =   nit                 ,
            'CIUDAD_EMISION'    =   ciudad_emision      ,
            'FECHA_EMISION'     =   fecha_emision       ,
            'FECHA_VENCIMIENTO' =   fecha_vencimiento   ,
            'NACIONALIDAD'      =   nacionalidad        ,
            'LUGAR_NAC'         =   lugar_nac           ,
            'FECHA_NAC'         =   fecha_nac           ,
            'DEPARTAMENTO'      =   departamento        ,
            'MUNICIPIO'         =   municipio           ,
            'CANTON'            =   canton              ,
            'AVENIDA'           =   avenida             ,
            'NUM_CASA'          =   num_casa            ,
            'AREA'              =   area                ,
            'REF_DOMICILIAR'    =   ref_domiciliar      ,
            'CONTRIBUYENTE'     =   contribuyente       ,
            'ES_EXPUESTA_POLI'  =   es_expuesta_poli    ,
            'ES_VINCULADA_POLI' =   es_vinculada_poli   ,
            'TELF VIVIENDA'     =   telf_vivienda       ,
            'TELF CELULAR'      =   telf_celular        ,
            'NOMBRE_CONYUGE'    =   nombre_conyuge      ,
            'LUGAR_TRABAJO'     =   lugar_trabajo       ,
            'TRABAJO'           =   trabajo             ,
            'TELF_TRABAJO'      =   telf_trabajo        ,
            'NUM_MIEMBROS_FAMI' =   num_miembros_fami   ,
            'TENENCIA_VIVIENDA' =   tenencia_vivienda   ,
            'TIMEPO_RESIDENCIA' =   tiempo_residencia   ,
            'NOMBRE_OFICIAL'    =   nombre_oficial,
			'SUJETO_RETENCION'  =   sujeto_retencion       
            from @w_participantes
            
    end
    
    
    if(@i_tipo = 'R')
    begin
        if(@i_id_ente is null)
        begin
            select @w_error = 2110225
            goto ERROR
        end
        
        
        declare cur_referencias cursor read_only for (select rp_referencia from cobis..cl_ref_personal where rp_persona = @i_id_ente)

        open cur_referencias
        fetch cur_referencias into @w_referencia
        while (@@fetch_status = 0)
        begin
        
            select @w_telf_celular =  rt_numero_tel from cobis..cl_ref_telefono  with(nolock)
                                        where rt_tipo_tel = 'C' and rt_ente = @i_id_ente and rt_sec_ref = @w_referencia
                                        and rt_referencia = 'P' order by rt_secuencial desc
                                        
            select @w_telf_vivienda =  rt_numero_tel from cobis..cl_ref_telefono  with(nolock)
                                        where rt_tipo_tel = 'D' and rt_ente = @i_id_ente and rt_sec_ref = @w_referencia
                                        and rt_referencia = 'P' order by rt_secuencial desc
        
        
            insert into @w_referencias
            select 
            (isnull(rp_nombre + ' ','') + isnull(rp_p_apellido + ' ','') + isnull(rp_s_apellido,'')),
             @w_telf_vivienda,
              @w_telf_celular,
             (select C.valor from cobis..cl_catalogo C with(nolock) inner join cobis..cl_tabla  T with(nolock)
                                    on C.tabla = T.codigo  where T.tabla = 'cl_parentesco' and C.codigo = rp_parentesco)
            from cobis..cl_ref_personal  where rp_persona = @i_id_ente and rp_referencia = @w_referencia
            
            if @@error <> 0 
            begin
                select @w_error = 2610180
                goto ERROR
                close cur_referencias
                deallocate cur_referencias
            end
            
            fetch cur_referencias into @w_referencia
        end
        close cur_referencias
        deallocate cur_referencias
        

            
        if exists(select 1 from @w_referencias )
        begin
            select
            'NOMBRE_REF'        =  nombre_completo,
            'TELF_VIVIENDA_REF' =  telf_vivienda,   
            'CEL_VIVIENDA_REF'  =  telf_celular ,
            'PARENTESCO_REF'    =  parentesco          
            from @w_referencias
        end
        else
        begin
            select
            'NOMBRE_REF'        =  '',
            'TELF_VIVIENDA_REF' =  '', 
            'CEL_VIVIENDA_REF'  =  '',
            'PARENTESCO_REF'    =  '' 
        end
        
    end 
 
end 

return 0

ERROR:
    exec cobis..sp_cerror
     @t_debug = @t_debug,
     @t_file  = @t_file,
     @t_from  = @w_sp_name,
     @i_num   = @w_error
    return @w_error
go
