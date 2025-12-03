/************************************************************************/
/*   Archivo:             cons_cliente.sp                               */
/*   Stored procedure:    sp_cons_cliente                               */
/*   Base de datos:       cobis                                         */
/*   Producto:            Clientes                                      */
/*   Disenado por:        ALD                                           */
/*   Fecha de escritura:  30-Abril-2019                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*  de COBISCorp.                                                       */
/*  Su uso no    autorizado queda  expresamente   prohibido asi como    */
/*  cualquier    alteracion o  agregado  hecho por    alguno  de sus    */
/*  usuarios sin el debido consentimiento por   escrito de COBISCorp.   */
/*  Este programa esta protegido por la ley de   derechos de autor      */
/*  y por las    convenciones  internacionales   de  propiedad inte-    */
/*  lectual.    Su uso no  autorizado dara  derecho a    COBISCorp para */
/*  obtener ordenes  de secuestro o  retencion y para  perseguir        */
/*  penalmente a los autores de cualquier   infraccion.                 */
/************************************************************************/
/*                              PROPOSITO                               */
/*   Extraccion de datos de Clientes para repositorio ex_dato_operacion */
/*   Abril 20 2012  Acelis  Repositorio Paquete 3   (Eliminar mensajes  */
/*   Agosto 18 2016 P. Romero   Se agrega paso de tabla cl_ente_aux     */
/*   ABR-2017       T. Baidal     CL_ENTE_AUX POR CL_ENTE_ADICIONAL     */
/************************************************************************/
/*                          MODIFICACIONES                              */
/* FECHA                    AUTOR                       RAZON           */
/* 30/Abril/2019            ALD              Versión Inicial Te Creemos */
/* 20/JUL/2010              FSAP             Estandarizacion clientes   */
/* 16/JUN/2010              ADA              Modificación para Finca Imp*/
/************************************************************************/

use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_cons_cliente')
   drop proc sp_cons_cliente
go

CREATE proc sp_cons_cliente
   @i_param1    varchar(255)

as declare
   @w_error                 int,
   @w_sp_name               varchar(64),
   @w_fecha_proceso         smalldatetime,
   @w_msg                   varchar(64),
   @w_sig_habil             datetime,
   @w_ciudad                int,
   @w_fin_mes               char(1),
   @w_meses_activar         tinyint,
   @w_producto              smallint

SET ANSI_WARNINGS OFF

create table #clientes (ente int null)

/* CARGADO DE VARIABLES DE TRABAJO */
select @w_sp_name = 'sp_cons_cliente',
       @w_fecha_proceso = convert(datetime,@i_param1,101)

/*DETERMINAR LA FECHA DE PROCESO */

if @w_fecha_proceso is null
begin
  select @w_producto = pd_producto
    from cl_producto
   where pd_descripcion = 'CLIENTES'

  select
  @w_fecha_proceso = fc_fecha_cierre
  from cobis..ba_fecha_cierre
  where fc_producto = @w_producto
end
/* MESES PARA DESACTIVAR CLIENTE */
select @w_meses_activar = pa_smallint
  from cobis..cl_parametro
 where pa_producto = 'CLI'
   and pa_nemonico = 'MPIC'


/* CIUDAD DE FERIADOS */
select @w_ciudad = pa_int
from cobis..cl_parametro
where pa_producto = 'ADM'
and   pa_nemonico = 'CIUN'

/* DETERMINAR SI HOY ES EL ULTIMO HABIL DEL MES */
select @w_sig_habil = dateadd(dd, 1, @w_fecha_proceso)

while exists (select 1
                from cobis..cl_dias_feriados
               where df_fecha = @w_sig_habil
                 and df_ciudad = @w_ciudad)
begin
   select @w_sig_habil = dateadd(dd, 1, @w_sig_habil)
end

if datepart(mm, @w_sig_habil) <> datepart(mm, @w_fecha_proceso)
  select @w_fin_mes = 'S'


/* ENTRAR BORRANDO TODA LA INFORMACION GENERADA POR CLIENTES EN COB_EXTERNOS */

truncate table cob_externos..ex_dato_cliente
truncate table cob_externos..ex_dato_direccion
truncate table cob_externos..ex_dato_telefono

/* SELECCIONAR TABLAS MODIFICADAS */
if @w_fin_mes = 'S' begin -- Si es fin de mes paso todos los clientes
  insert into #clientes
  select en_ente
  from cobis..cl_ente
  where convert(varchar(10),en_fecha_crea,101) <= @w_fecha_proceso
end
else
begin
  insert into #clientes
  select en_ente
  from cobis..cl_ente
  where convert(varchar(10),en_fecha_mod,101) = @w_fecha_proceso

  insert into #clientes
  select distinct di_ente
  from cobis..cl_direccion
  where convert(varchar(10),di_fecha_modificacion,101) = @w_fecha_proceso
  and   di_ente not in (select ente from #clientes)

  insert into #clientes
  select distinct te_ente
  from cobis..cl_telefono
  where convert(varchar(10),te_fecha_mod,101) = @w_fecha_proceso
  and   te_ente not in (select ente from #clientes)

end

/* CARGA DE OPERACIONES ACTIVAS */
select
dc_fecha                  = @w_fecha_proceso,
dc_ente                   = en_ente,
dc_nombre                 = en_nombre,
dc_subtipo                = en_subtipo,
dc_tipo_ced               = en_tipo_ced,
dc_ced_ruc                = en_ced_ruc,
dc_nit                    = en_nit,
dc_rfc                    = en_rfc,
dc_tipo_iden              = en_tipo_iden,
dc_numero_iden            = en_numero_iden,
dc_nomlar                 = en_nomlar,
dc_actividad              = en_actividad,
dc_retencion              = en_retencion,
dc_mala_referencia        = en_mala_referencia,
dc_comentario             = en_comentario,
dc_sector                 = en_sector,
dc_referido               = en_referido,
dc_pais                   = en_pais,
dc_oficial                = en_oficial,
dc_cont_malas             = en_cont_malas,
dc_doc_validado           = en_doc_validado,
dc_rep_superban           = en_rep_superban,
dc_asosciada              = en_asosciada,
dc_tipo_dp                = en_tipo_dp,
dc_grupo                  = en_grupo,
dc_p_s_nombre             = p_s_nombre,
dc_p_p_apellido           = p_p_apellido,
dc_p_s_apellido           = p_s_apellido,
dc_p_c_apellido           = p_c_apellido,
dc_p_sexo                 = p_sexo,
dc_p_genero               = p_genero,
dc_p_estado_civil         = p_estado_civil,
dc_p_fecha_nac            = p_fecha_nac,
dc_p_ciudad_nac           = p_ciudad_nac,
dc_p_tipo_persona         = p_tipo_persona,
dc_p_profesion            = p_profesion,
dc_p_ocupacion            = p_ocupacion,
dc_p_lugar_doc            = p_lugar_doc,
dc_p_pasaporte            = p_pasaporte,
dc_p_num_cargas           = p_num_cargas,
dc_p_num_hijos            = p_num_hijos,
dc_p_nivel_ing            = p_nivel_ing,
dc_p_nivel_egr            = p_nivel_egr,
dc_p_nivel_estudio        = p_nivel_estudio,
dc_p_tipo_vivienda        = p_tipo_vivienda,
dc_p_calif_cliente        = p_calif_cliente,
dc_p_personal             = p_personal,
dc_p_propiedad            = p_propiedad,
dc_p_trabajo              = p_trabajo,
dc_p_soc_hecho            = p_soc_hecho,
dc_p_depa_nac             = p_depa_nac,
dc_p_pais_emi             = p_pais_emi,
dc_p_depa_emi             = p_depa_emi,
dc_p_dep_doc              = p_dep_doc,
dc_p_numord               = p_numord,
dc_p_carg_pub             = p_carg_pub,
dc_p_rel_carg_pub         = p_rel_carg_pub,
dc_p_situacion_laboral    = p_situacion_laboral,
dc_p_bienes               = p_bienes,
dc_p_fecha_emision        = p_fecha_emision,
dc_p_fecha_expira         = p_fecha_expira,
dc_c_razon_social         = c_razon_social,
dc_c_segmento             = c_segmento,
dc_c_cap_suscrito         = c_cap_suscrito,
dc_c_posicion             = c_posicion,
dc_c_tipo_compania        = c_tipo_compania,
dc_c_rep_legal            = c_rep_legal,
dc_c_es_grupo             = c_es_grupo,
dc_c_activo               = c_activo,
dc_c_pasivo               = c_pasivo,
dc_c_total_activos        = c_total_activos,
dc_c_total_pasivos        = c_total_pasivos,
dc_c_capital_social       = c_capital_social,
dc_c_reserva_legal        = c_reserva_legal,
dc_c_cap_pagado           = c_cap_pagado,
dc_c_fecha_const          = c_fecha_const,
dc_c_plazo                = c_plazo,
dc_c_direccion_domicilio  = c_direccion_domicilio,
dc_c_fecha_inscrp         = c_fecha_inscrp,
dc_c_fecha_aum_capital    = c_fecha_aum_capital,
dc_c_tipo_nit             = c_tipo_nit,
dc_c_tipo_soc             = c_tipo_soc,
dc_c_num_empleados        = c_num_empleados,
dc_c_sigla                = c_sigla,
dc_c_escritura            = c_escritura,
dc_c_notaria              = c_notaria,
dc_c_ciudad               = c_ciudad,
dc_c_fecha_exp            = c_fecha_exp,
dc_c_fecha_vcto           = c_fecha_vcto,
dc_c_camara               = c_camara,
dc_c_registro             = c_registro,
dc_c_grado_soc            = c_grado_soc,
dc_c_edad_laboral_promedio= c_edad_laboral_promedio,
dc_c_empleados_ley_50     = c_empleados_ley_50,
dc_c_codsuper             = c_codsuper,
dc_c_fecha_registro       = c_fecha_registro,
dc_c_fecha_modif          = c_fecha_modif,
dc_c_fecha_verif          = c_fecha_verif,
dc_c_vigencia             = c_vigencia,
dc_c_verificado           = c_verificado,
dc_c_funcionario          = c_funcionario,
dc_s_tipo_soc_hecho       = s_tipo_soc_hecho,
dc_situacion_cliente      = en_situacion_cliente,
dc_patrimonio_tec         = en_patrimonio_tec,
dc_fecha_patri_bruto      = en_fecha_patri_bruto,
dc_gran_contribuyente     = en_gran_contribuyente,
dc_calificacion           = en_calificacion,
dc_reestructurado         = en_reestructurado,
dc_concurso_acreedores    = en_concurso_acreedores,
dc_concordato             = en_concordato,
dc_vinculacion            = en_vinculacion,
dc_tipo_vinculacion       = en_tipo_vinculacion,
dc_oficial_sup            = en_oficial_sup,
dc_cliente                = en_cliente,
dc_preferen               = en_preferen,
dc_exc_sipla              = en_exc_sipla,
dc_exc_por2               = en_exc_por2,
dc_digito                 = en_digito,
dc_categoria              = en_categoria,
dc_emala_referencia       = en_emala_referencia,
dc_banca                  = en_banca,
dc_pensionado             = en_pensionado,
dc_rep_sib                = en_rep_sib,
dc_max_riesgo             = en_max_riesgo,
dc_riesgo                 = en_riesgo,
dc_mries_ant              = en_mries_ant,
dc_fmod_ries              = en_fmod_ries,
dc_user_ries              = en_user_ries,
dc_reservado              = en_reservado,
dc_pas_finan              = en_pas_finan,
dc_fpas_finan             = en_fpas_finan,
dc_fbalance               = en_fbalance,
dc_relacint               = en_relacint,
dc_otringr                = en_otringr,
dc_exento_cobro           = en_exento_cobro,
dc_doctos_carpeta         = en_doctos_carpeta,
dc_oficina_prod           = en_oficina_prod,
dc_accion                 = en_accion,
dc_procedencia            = en_procedencia,
dc_fecha_negocio          = en_fecha_negocio,
dc_estrato                = en_estrato,
dc_recurso_pub            = en_recurso_pub,
dc_influencia             = en_influencia,
dc_persona_pub            = en_persona_pub,
dc_victima                = en_victima,
dc_bancarizado            = en_bancarizado,
dc_alto_riesgo            = en_alto_riesgo,
dc_fecha_riesgo           = en_fecha_riesgo,
dc_estado                 = en_estado,
dc_calif_cartera          = en_calif_cartera,
dc_cod_otro_pais          = en_cod_otro_pais,
dc_ingre                  = en_ingre,
dc_cem                    = en_cem,
dc_promotor               = en_promotor,
dc_inss                   = en_inss,
dc_licencia               = en_licencia,
dc_id_tutor               = en_id_tutor,
dc_nom_tutor              = en_nom_tutor,
dc_referidor_ecu          = en_referidor_ecu,
dc_otros_ingresos         = en_otros_ingresos,
dc_origen_ingresos        = en_origen_ingresos,
dc_nro_ciclo              = en_nro_ciclo,
dc_emproblemado           = en_emproblemado,
dc_dinero_transac         = en_dinero_transac,
dc_manejo_doc             = en_manejo_doc,
dc_persona_pep            = en_persona_pep,
dc_ing_SN                 = en_ing_SN,
dc_nac_aux                = en_nac_aux,
dc_banco                  = en_banco,
dc_nacionalidad           = en_nacionalidad,
dc_pais_nac               = en_pais_nac,
dc_provincia_nac          = en_provincia_nac,
dc_naturalizado           = en_naturalizado,
dc_forma_migratoria       = en_forma_migratoria,
dc_nro_extranjero         = en_nro_extranjero,
dc_calle_orig             = en_calle_orig,
dc_exterior_orig          = en_exterior_orig,
dc_estado_orig            = en_estado_orig,
dc_firma_electronica      = en_firma_electronica,
dc_localidad              = en_localidad,
dc_actividad_desc         = en_actividad_desc,
dc_nivel                  = en_nivel,
dc_inf_laboral            = en_inf_laboral,
dc_tipo_operacion         = en_tipo_operacion,
dc_provincia_act          = en_provincia_act,
dc_lugar_act              = en_lugar_act,
dc_filial                 = en_filial,
dc_oficina                = en_oficina,
dc_fecha_crea             = en_fecha_crea,
dc_fecha_mod              = en_fecha_mod,
dc_direccion              = en_direccion,
dc_referencia             = en_referencia,
dc_casilla                = en_casilla,
dc_casilla_def            = en_casilla_def,
dc_balance                = en_balance,
dc_tipo_doc_tributario    = en_tipo_doc_tributario,
dc_tipo_residencia        = en_tipo_residencia,
dc_ciudad_emision         = en_ciudad_emision,
dc_ente_migrado           = en_ente_migrado,
dc_codigo_pep_relac       = en_codigo_pep_relac,
dc_nombre_pep_relac       = en_nombre_pep_relac,
dc_p_fecha_inicio_pep     = p_fecha_inicio_pep,
dc_p_fecha_fin_pep        = p_fecha_fin_pep,
dc_p_tipo_pep             = p_tipo_pep
into #ente
from cobis..cl_ente, #clientes
where en_ente = ente


/* Fecha Vinculacion 
select ente  = dc_ente,
       fecha = min(cl_fecha)
into #vinculacion
from cobis..cl_cliente, #ente
where cl_cliente = dc_cliente
group by dc_cliente

update #ente set
dc_fecha_vinculacion = fecha
from #vinculacion
where ente = dc_cliente*/


-- INI - GAL 27/JUL/2010
/*IF EXISTS (SELECT 1 FROM cl_producto WHERE pd_producto=7)
begin
  select
  cliente = op_cliente,
  cant    = count(1)
  into #his
  from cob_cartera..ca_operacion
  where op_estado not in (6, 99)  -- NO EN ESTADO CREDITO Y ANULADO
  group by op_cliente

  insert into #his
  select
  cliente = op_cliente,
  cant    = count(1)
  from cob_cartera_his..ca_operacion
  where op_estado not in (6, 99)  -- NO EN ESTADO CREDITO Y ANULADO
  group by op_cliente

  select
  cliente = cliente,
  cant    = sum(cant)
  into #his_tot
  from #his
  group by cliente

  update #ente set
  dc_num_activas = cant
  from #his_tot
  where dc_cliente = cliente
  -- FIN - GAL 27/JUL/2010

  /* Cliente Activo - InActivo - Operaciones Cartera - req 144 */

  -- Todos aquellos que tengan operacion vigente son Activos
  update #ente set
  dc_estado_cliente = 'A'
  from cob_cartera..ca_operacion
  where dc_cliente = op_cliente
  and   op_estado not in (99, 3, 0, 6)

  -- Tomar operaciones que puedan generar Inactividad de los clientes que quedaron Inactivos.
  select cliente=dc_cliente, fecha=max(op_fecha_ult_proceso)
  into #cli_operacion_cancelada
  from cob_cartera..ca_operacion, #ente
  where dc_cliente = op_cliente
  and   op_estado = 3
  and   dc_estado_cliente = 'I'
  group by dc_cliente

  select @w_fecha_proceso
  select @w_meses_activar


  -- Defino si la fecha de cancelacion Activa al Cliente
  update #ente set
  dc_estado_cliente = 'A'
  from #cli_operacion_cancelada
  where dc_cliente = cliente
  and   dateadd(mm,@w_meses_activar,fecha) >= @w_fecha_proceso
end*/

/* CLIENTES */
insert into cob_externos..ex_dato_cliente
   (
   dc_fecha                  , dc_ente                 , dc_nombre             , dc_subtipo            ,
   dc_tipo_ced               , dc_ced_ruc              , dc_nit                , dc_rfc                ,
   dc_tipo_iden              , dc_numero_iden          , dc_nomlar             , dc_actividad          ,
   dc_retencion              , dc_mala_referencia      , dc_comentario         , dc_sector             ,
   dc_referido               , dc_pais                 , dc_oficial            , dc_cont_malas         ,
   dc_doc_validado           , dc_rep_superban         , dc_asosciada          , dc_tipo_dp            ,
   dc_grupo                  , dc_p_s_nombre           , dc_p_p_apellido       , dc_p_s_apellido       ,
   dc_p_c_apellido           , dc_p_sexo               , dc_p_genero           , dc_p_estado_civil     ,
   dc_p_fecha_nac            , dc_p_ciudad_nac         , dc_p_tipo_persona     , dc_p_profesion        ,
   dc_p_ocupacion            , dc_p_lugar_doc          , dc_p_pasaporte        , dc_p_num_cargas       ,
   dc_p_num_hijos            , dc_p_nivel_ing          , dc_p_nivel_egr        , dc_p_nivel_estudio    ,
   dc_p_tipo_vivienda        , dc_p_calif_cliente      , dc_p_personal         , dc_p_propiedad        ,
   dc_p_trabajo              , dc_p_soc_hecho          , dc_p_depa_nac         , dc_p_pais_emi         ,
   dc_p_depa_emi             , dc_p_dep_doc            , dc_p_numord           , dc_p_carg_pub         ,
   dc_p_rel_carg_pub         , dc_p_situacion_laboral  , dc_p_bienes           , dc_p_fecha_emision    ,
   dc_p_fecha_expira         , dc_c_razon_social       , dc_c_segmento         , dc_c_cap_suscrito     ,
   dc_c_posicion             , dc_c_tipo_compania      , dc_c_rep_legal        , dc_c_es_grupo         ,
   dc_c_activo               , dc_c_pasivo             , dc_c_total_activos    , dc_c_total_pasivos    ,
   dc_c_capital_social       , dc_c_reserva_legal      , dc_c_cap_pagado       , dc_c_fecha_const      ,
   dc_c_plazo                , dc_c_direccion_domicilio, dc_c_fecha_inscrp     , dc_c_fecha_aum_capital,
   dc_c_tipo_nit             , dc_c_tipo_soc           , dc_c_num_empleados    , dc_c_sigla            ,
   dc_c_escritura            , dc_c_notaria            , dc_c_ciudad           , dc_c_fecha_exp        ,
   dc_c_fecha_vcto           , dc_c_camara             , dc_c_registro         , dc_c_grado_soc        ,
   dc_c_edad_laboral_promedio, dc_c_empleados_ley_50   , dc_c_codsuper         , dc_c_fecha_registro   ,
   dc_c_fecha_modif          , dc_c_fecha_verif        , dc_c_vigencia         , dc_c_verificado       ,
   dc_c_funcionario          , dc_s_tipo_soc_hecho     , dc_situacion_cliente  , dc_patrimonio_tec     ,
   dc_fecha_patri_bruto      , dc_gran_contribuyente   , dc_calificacion       , dc_reestructurado     ,
   dc_concurso_acreedores    , dc_concordato           , dc_vinculacion        , dc_tipo_vinculacion   ,
   dc_oficial_sup            , dc_cliente              , dc_preferen           , dc_exc_sipla          ,
   dc_exc_por2               , dc_digito               , dc_categoria          , dc_emala_referencia   ,
   dc_banca                  , dc_pensionado           , dc_rep_sib            , dc_max_riesgo         ,
   dc_riesgo                 , dc_mries_ant            , dc_fmod_ries          , dc_user_ries          ,
   dc_reservado              , dc_pas_finan            , dc_fpas_finan         , dc_fbalance           ,
   dc_relacint               , dc_otringr              , dc_exento_cobro       , dc_doctos_carpeta     ,
   dc_oficina_prod           , dc_accion               , dc_procedencia        , dc_fecha_negocio      ,
   dc_estrato                , dc_recurso_pub          , dc_influencia         , dc_persona_pub        ,
   dc_victima                , dc_bancarizado          , dc_alto_riesgo        , dc_fecha_riesgo       ,
   dc_estado                 , dc_calif_cartera        , dc_cod_otro_pais      , dc_ingre              ,
   dc_cem                    , dc_promotor             , dc_inss               , dc_licencia           ,
   dc_id_tutor               , dc_nom_tutor            , dc_referidor_ecu      , dc_otros_ingresos     ,
   dc_origen_ingresos        , dc_nro_ciclo            , dc_emproblemado       , dc_dinero_transac     ,
   dc_manejo_doc             , dc_persona_pep          , dc_ing_SN             , dc_nac_aux            ,
   dc_banco                  , dc_nacionalidad         , dc_pais_nac           , dc_provincia_nac      ,
   dc_naturalizado           , dc_forma_migratoria     , dc_nro_extranjero     , dc_calle_orig         ,
   dc_exterior_orig          , dc_estado_orig          , dc_firma_electronica  , dc_localidad          ,
   dc_actividad_desc         , dc_nivel                , dc_inf_laboral        , dc_tipo_operacion     ,
   dc_provincia_act          , dc_lugar_act            , dc_filial             , dc_oficina            ,
   dc_fecha_crea             , dc_fecha_mod            , dc_direccion          , dc_referencia         ,
   dc_casilla                , dc_casilla_def          , dc_balance            , dc_tipo_doc_tributario,
   dc_tipo_residencia        , dc_ciudad_emision       , dc_ente_migrado       , dc_codigo_pep_relac   ,
   dc_nombre_pep_relac       , dc_p_fecha_inicio_pep   , dc_p_fecha_fin_pep    , dc_p_tipo_pep         ,
   dc_aplicativo             , dc_origen               , dc_fecha_proc
   )
select 
   dc_fecha                  , dc_ente                 , dc_nombre             , dc_subtipo            ,
   dc_tipo_ced               , dc_ced_ruc              , dc_nit                , dc_rfc                ,
   dc_tipo_iden              , dc_numero_iden          , dc_nomlar             , dc_actividad          ,
   dc_retencion              , dc_mala_referencia      , dc_comentario         , dc_sector             ,
   dc_referido               , dc_pais                 , dc_oficial            , dc_cont_malas         ,
   dc_doc_validado           , dc_rep_superban         , dc_asosciada          , dc_tipo_dp            ,
   dc_grupo                  , dc_p_s_nombre           , dc_p_p_apellido       , dc_p_s_apellido       ,
   dc_p_c_apellido           , dc_p_sexo               , dc_p_genero           , dc_p_estado_civil     ,
   dc_p_fecha_nac            , dc_p_ciudad_nac         , dc_p_tipo_persona     , dc_p_profesion        ,
   dc_p_ocupacion            , dc_p_lugar_doc          , dc_p_pasaporte        , dc_p_num_cargas       ,
   dc_p_num_hijos            , dc_p_nivel_ing          , dc_p_nivel_egr        , dc_p_nivel_estudio    ,
   dc_p_tipo_vivienda        , dc_p_calif_cliente      , dc_p_personal         , dc_p_propiedad        ,
   dc_p_trabajo              , dc_p_soc_hecho          , dc_p_depa_nac         , dc_p_pais_emi         ,
   dc_p_depa_emi             , dc_p_dep_doc            , dc_p_numord           , dc_p_carg_pub         ,
   dc_p_rel_carg_pub         , dc_p_situacion_laboral  , dc_p_bienes           , dc_p_fecha_emision    ,
   dc_p_fecha_expira         , dc_c_razon_social       , dc_c_segmento         , dc_c_cap_suscrito     ,
   dc_c_posicion             , dc_c_tipo_compania      , dc_c_rep_legal        , dc_c_es_grupo         ,
   dc_c_activo               , dc_c_pasivo             , dc_c_total_activos    , dc_c_total_pasivos    ,
   dc_c_capital_social       , dc_c_reserva_legal      , dc_c_cap_pagado       , dc_c_fecha_const      ,
   dc_c_plazo                , dc_c_direccion_domicilio, dc_c_fecha_inscrp     , dc_c_fecha_aum_capital,
   dc_c_tipo_nit             , dc_c_tipo_soc           , dc_c_num_empleados    , dc_c_sigla            ,
   dc_c_escritura            , dc_c_notaria            , dc_c_ciudad           , dc_c_fecha_exp        ,
   dc_c_fecha_vcto           , dc_c_camara             , dc_c_registro         , dc_c_grado_soc        ,
   dc_c_edad_laboral_promedio, dc_c_empleados_ley_50   , dc_c_codsuper         , dc_c_fecha_registro   ,
   dc_c_fecha_modif          , dc_c_fecha_verif        , dc_c_vigencia         , dc_c_verificado       ,
   dc_c_funcionario          , dc_s_tipo_soc_hecho     , dc_situacion_cliente  , dc_patrimonio_tec     ,
   dc_fecha_patri_bruto      , dc_gran_contribuyente   , dc_calificacion       , dc_reestructurado     ,
   dc_concurso_acreedores    , dc_concordato           , dc_vinculacion        , dc_tipo_vinculacion   ,
   dc_oficial_sup            , dc_cliente              , dc_preferen           , dc_exc_sipla          ,
   dc_exc_por2               , dc_digito               , dc_categoria          , dc_emala_referencia   ,
   dc_banca                  , dc_pensionado           , dc_rep_sib            , dc_max_riesgo         ,
   dc_riesgo                 , dc_mries_ant            , dc_fmod_ries          , dc_user_ries          ,
   dc_reservado              , dc_pas_finan            , dc_fpas_finan         , dc_fbalance           ,
   dc_relacint               , dc_otringr              , dc_exento_cobro       , dc_doctos_carpeta     ,
   dc_oficina_prod           , dc_accion               , dc_procedencia        , dc_fecha_negocio      ,
   dc_estrato                , dc_recurso_pub          , dc_influencia         , dc_persona_pub        ,
   dc_victima                , dc_bancarizado          , dc_alto_riesgo        , dc_fecha_riesgo       ,
   dc_estado                 , dc_calif_cartera        , dc_cod_otro_pais      , dc_ingre              ,
   dc_cem                    , dc_promotor             , dc_inss               , dc_licencia           ,
   dc_id_tutor               , dc_nom_tutor            , dc_referidor_ecu      , dc_otros_ingresos     ,
   dc_origen_ingresos        , dc_nro_ciclo            , dc_emproblemado       , dc_dinero_transac     ,
   dc_manejo_doc             , dc_persona_pep          , dc_ing_SN             , dc_nac_aux            ,
   dc_banco                  , dc_nacionalidad         , dc_pais_nac           , dc_provincia_nac      ,
   dc_naturalizado           , dc_forma_migratoria     , dc_nro_extranjero     , dc_calle_orig         ,
   dc_exterior_orig          , dc_estado_orig          , dc_firma_electronica  , dc_localidad          ,
   dc_actividad_desc         , dc_nivel                , dc_inf_laboral        , dc_tipo_operacion     ,
   dc_provincia_act          , dc_lugar_act            , dc_filial             , dc_oficina            ,
   dc_fecha_crea             , dc_fecha_mod            , dc_direccion          , dc_referencia         ,
   dc_casilla                , dc_casilla_def          , dc_balance            , dc_tipo_doc_tributario,
   dc_tipo_residencia        , dc_ciudad_emision       , dc_ente_migrado       , dc_codigo_pep_relac   ,
   dc_nombre_pep_relac       , dc_p_fecha_inicio_pep   , dc_p_fecha_fin_pep    , dc_p_tipo_pep         ,
   @w_producto               , 1                       , Convert(varchar,@w_fecha_proceso,101)
from #ente

if @@error <> 0 begin
   select
   @w_error = 1720351,
   @w_msg = 'Error en al Grabar en tabla cob_externos..ex_dato_cliente'
   goto ERROR
end

/* DIRECCIONES */
select
   dd_fecha               = @w_fecha_proceso,
   dd_ente                = di_ente,
   dd_direccion           = di_direccion,
   dd_descripcion         = di_descripcion,
   dd_parroquia           = di_parroquia,
   dd_ciudad              = di_ciudad,
   dd_tipo                = di_tipo,
   dd_telefono            = di_telefono,
   dd_sector              = di_sector,
   dd_zona                = di_zona,
   dd_oficina             = di_oficina,
   dd_fecha_registro      = di_fecha_registro,
   dd_fecha_modificacion   = di_fecha_modificacion,
   dd_vigencia            = di_vigencia,
   dd_verificado          = di_verificado,
   dd_funcionario         = di_funcionario,
   dd_fecha_ver           = di_fecha_ver,
   dd_principal           = di_principal,
   dd_barrio              = di_barrio,
   dd_provincia           = di_provincia,
   dd_tienetel            = di_tienetel,
   dd_rural_urb           = di_rural_urb,
   dd_observacion         = di_observacion,
   dd_obs_verificado      = di_obs_verificado,
   dd_extfin              = di_extfin,
   dd_pais                = di_pais,
   dd_departamento        = di_departamento,
   dd_tipo_prop           = di_tipo_prop,
   dd_rural_urbano        = di_rural_urbano,
   dd_codpostal           = di_codpostal,
   dd_casa                = di_casa,
   dd_calle               = di_calle,
   dd_codbarrio           = di_codbarrio,
   dd_correspondencia     = di_correspondencia,
   dd_alquilada           = di_alquilada,
   dd_cobro               = di_cobro,
   dd_otrasenas           = di_otrasenas,
   dd_canton              = di_canton,
   dd_distrito            = di_distrito,
   dd_montoalquiler       = di_montoalquiler,
   dd_edificio            = di_edificio,
   dd_so_igu_co           = di_so_igu_co,
   dd_fact_serv_pu        = di_fact_serv_pu,
   dd_nombre_agencia      = di_nombre_agencia,
   dd_fuente_verif        = di_fuente_verif,
   dd_tiempo_reside       = di_tiempo_reside,
   dd_nro                 = di_nro,
   dd_nro_residentes      = di_nro_residentes,
   dd_nro_interno         = di_nro_interno,
   dd_negocio             = di_negocio,
   dd_poblacion           = di_poblacion,
   dd_referencias_dom     = di_referencias_dom,
   dd_otro_tipo           = di_otro_tipo,
   dd_localidad           = di_localidad,
   dd_conjunto            = di_conjunto,
   dd_piso                = di_piso,
   dd_numero_casa         = di_numero_casa
into #direcciones
from cobis..cl_direccion, #clientes
where di_ente = ente

insert into cob_externos..ex_dato_direccion
   (
   dd_fecha,         dd_ente,             dd_direccion,        dd_descripcion,    dd_parroquia,        dd_ciudad,              dd_tipo,
   dd_telefono,      dd_sector,           dd_zona,             dd_oficina,        dd_fecha_registro,   dd_fecha_modificacion,   dd_vigencia,
   dd_verificado,    dd_funcionario,      dd_fecha_ver,        dd_principal,      dd_barrio,           dd_provincia,           dd_tienetel,
   dd_rural_urb,     dd_observacion,      dd_obs_verificado,   dd_extfin,         dd_pais,             dd_departamento,        dd_tipo_prop,
   dd_rural_urbano,  dd_codpostal,        dd_casa,             dd_calle,          dd_codbarrio,        dd_correspondencia,     dd_alquilada,
   dd_cobro,         dd_otrasenas,        dd_canton,           dd_distrito,       dd_montoalquiler,    dd_edificio,            dd_so_igu_co,
   dd_fact_serv_pu,  dd_nombre_agencia,   dd_fuente_verif,     dd_tiempo_reside,  dd_nro,              dd_nro_residentes,      dd_nro_interno,
   dd_negocio,       dd_poblacion,        dd_referencias_dom,  dd_otro_tipo,      dd_localidad,        dd_conjunto,            dd_piso,
   dd_numero_casa,   dd_aplicativo,       dd_origen,           dd_fecha_proc
   )
select
   @w_fecha_proceso,  dd_ente,             dd_direccion,        dd_descripcion,    dd_parroquia,        dd_ciudad,              dd_tipo,
   dd_telefono,      dd_sector,           dd_zona,             dd_oficina,        dd_fecha_registro,   dd_fecha_modificacion,   dd_vigencia,
   dd_verificado,    dd_funcionario,      dd_fecha_ver,        dd_principal,      dd_barrio,           dd_provincia,           dd_tienetel,
   dd_rural_urb,     dd_observacion,      dd_obs_verificado,   dd_extfin,         dd_pais,             dd_departamento,        dd_tipo_prop,
   dd_rural_urbano,  dd_codpostal,        dd_casa,             dd_calle,          dd_codbarrio,        dd_correspondencia,     dd_alquilada,
   dd_cobro,         dd_otrasenas,        dd_canton,           dd_distrito,       dd_montoalquiler,    dd_edificio,            dd_so_igu_co,
   dd_fact_serv_pu,  dd_nombre_agencia,   dd_fuente_verif,     dd_tiempo_reside,  dd_nro,              dd_nro_residentes,      dd_nro_interno,
   dd_negocio,       dd_poblacion,        dd_referencias_dom,  dd_otro_tipo,      dd_localidad,        dd_conjunto,            dd_piso,
   dd_numero_casa,   @w_producto,         2,                   Convert(varchar,@w_fecha_proceso,101)
from #direcciones

if @@error <> 0 begin
   select
   @w_error = 1720352,
   @w_msg = 'Error en al Grabar en tabla cob_externos..ex_dato_direccion'
   goto ERROR
end

/* TELEFONOS */
select
   dt_fecha                 = @w_fecha_proceso,
   dt_ente                  = te_ente,
   dt_direccion             = te_direccion,
   dt_secuencial            = te_secuencial,
   dt_valor                 = te_valor,
   dt_tipo_telefono         = te_tipo_telefono,
   dt_prefijo               = te_prefijo,
   dt_fecha_registro        = te_fecha_registro,
   dt_fecha_mod             = te_fecha_mod,
   dt_tipo_operador         = te_tipo_operador,
   dt_area                  = te_area,
   dt_telf_cobro            = te_telf_cobro,
   dt_funcionario           = te_funcionario,
   dt_verificado            = te_verificado,
   dt_fecha_ver             = te_fecha_ver,
   dt_fecha_modificacion    = te_fecha_modificacion
into #telefonos
from cobis..cl_telefono, #clientes
where te_ente = ente

insert into cob_externos..ex_dato_telefono
   (
   dt_fecha,       dt_ente,            dt_direccion,   dt_secuencial,          dt_valor,        dt_tipo_telefono,
   dt_prefijo,     dt_fecha_registro,  dt_fecha_mod,   dt_tipo_operador,       dt_area,         dt_telf_cobro,
   dt_funcionario, dt_verificado,      dt_fecha_ver,   dt_fecha_modificacion,  dt_aplicativo,   dt_origen,
   dt_fecha_proc
   )
select
   @w_fecha_proceso,       dt_ente,            dt_direccion,   dt_secuencial,          dt_valor,        dt_tipo_telefono,
   dt_prefijo,             dt_fecha_registro,  dt_fecha_mod,   dt_tipo_operador,       dt_area,         dt_telf_cobro,
   dt_funcionario,         dt_verificado,      dt_fecha_ver,   dt_fecha_modificacion,  @w_producto,     3,
   Convert(varchar,@w_fecha_proceso,101)
from #telefonos

if @@error <> 0 begin
  select
  @w_error = 1720353,
  @w_msg = 'Error en al Actualizar table cob_externos..ex_dato_telefono'
  goto ERROR
end


SET ANSI_WARNINGS ON
return 0

ERROR:

SET ANSI_WARNINGS ON
return @w_error

go
