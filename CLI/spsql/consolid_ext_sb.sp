/************************************************************************/
/*  Archivo:            consolid_ext_sb.sp                              */
/*  Stored procedure:   sp_consolid_ext_sb                              */
/*  Base de datos:      cobis                                           */
/*  Producto:           Clientes                                        */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "COBIS", representantes exclusivos para el Ecuador de la            */
/*  "FINCA IMPACT".                                                     */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de COBIS o su representante.                  */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Este programa renueva los datos de las tablas pertenecientes de     */
/*  consolidado Ext a consolidado Sb                                    */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA           AUTOR    RAZON                                      */
/*  17/06/21        COB      Se crea SP BATCH Consolidador SB           */
/************************************************************************/
use cobis

go

if exists (select 1 from sysobjects where name = 'sp_consolid_ext_sb')
   drop proc sp_consolid_ext_sb
go

create proc sp_consolid_ext_sb (
   @s_ssn              int             = null,
   @s_user             login           = null,
   @s_term             varchar(30)     = null,
   @s_date             datetime        = null,
   @s_srv              varchar(30)     = null,
   @s_lsrv             varchar(30)     = null,
   @s_ofi              smallint        = null,
   @s_rol              smallint        = null,
   @s_org_err          char(1)         = null,
   @s_error            int             = null,
   @s_sev              tinyint         = null,
   @s_msg              descripcion     = null,
   @s_org              char(1)         = null,
   @t_debug            char(1)         = 'N',
   @t_file             varchar(10)     = null,
   @t_from             varchar(32)     = null,
   @t_trn              int             = null,
   @i_param1           date            = null,
   @i_param2           char(1)         = null
)

as
declare
@w_sp_name     varchar(20),
@w_return      int,
@i_operacion   char(1),
@i_fecha_proc  varchar(10)

select @w_sp_name    = 'sp_consolid_ext_sb', 
       @w_return     = 0,
       @i_operacion  = @i_param2,
       @i_fecha_proc = convert(varchar(10),@i_param1,101)

if @i_operacion = 'I'
begin

   print 'Eliminando datos de la tabla sb_dato_cliente'

   delete cob_conta_super..sb_dato_cliente
   where  dc_fecha_proc  = @i_fecha_proc

   print 'Eliminando datos de la tabla sb_dato_direccion'

   delete cob_conta_super..sb_dato_direccion
   where  dd_fecha_proc  = @i_fecha_proc     

   print 'Eliminando datos de la tabla sb_dato_telefono'   

   delete cob_conta_super..sb_dato_telefono
   where  dt_fecha_proc  = @i_fecha_proc

   print 'Insertando en sb_datos_cliente'

   insert into cob_conta_super..sb_dato_cliente(dc_ente,                    dc_nombre,              dc_subtipo,
                                                dc_tipo_ced,                dc_ced_ruc,             dc_nit,
                                                dc_rfc,                     dc_tipo_iden,           dc_numero_iden,
                                                dc_nomlar,                  dc_actividad,           dc_retencion,
                                                dc_mala_referencia,         dc_comentario,          dc_sector,
                                                dc_referido,                dc_pais,                dc_oficial,
                                                dc_cont_malas,              dc_doc_validado,        dc_rep_superban,
                                                dc_asosciada,               dc_tipo_dp,             dc_grupo,
                                                dc_p_s_nombre,              dc_p_p_apellido,        dc_p_s_apellido,
                                                dc_p_c_apellido,            dc_p_sexo,dc_p_genero,  dc_p_estado_civil,
                                                dc_p_fecha_nac,             dc_p_ciudad_nac,        dc_p_tipo_persona,
                                                dc_p_profesion,             dc_p_ocupacion,         dc_p_lugar_doc,
                                                dc_p_pasaporte,             dc_p_num_cargas,        dc_p_num_hijos,
                                                dc_p_nivel_ing,             dc_p_nivel_egr,         dc_p_nivel_estudio,
                                                dc_p_tipo_vivienda,         dc_p_calif_cliente,     dc_p_personal,
                                                dc_p_propiedad,             dc_p_trabajo,           dc_p_soc_hecho,
                                                dc_p_depa_nac,              dc_p_pais_emi,          dc_p_depa_emi,
                                                dc_p_dep_doc,               dc_p_numord,            dc_p_carg_pub,
                                                dc_p_rel_carg_pub,          dc_p_situacion_laboral, dc_p_bienes,
                                                dc_p_fecha_emision,         dc_p_fecha_expira,      dc_c_razon_social,
                                                dc_c_segmento,              dc_c_cap_suscrito,      dc_c_posicion,
                                                dc_c_tipo_compania,         dc_c_rep_legal,         dc_c_es_grupo,
                                                dc_c_activo,                dc_c_pasivo,            dc_c_total_activos,
                                                dc_c_total_pasivos,         dc_c_capital_social,    dc_c_reserva_legal,
                                                dc_c_cap_pagado,            dc_c_fecha_const,       dc_c_plazo,
                                                dc_c_direccion_domicilio,   dc_c_fecha_inscrp,      dc_c_fecha_aum_capital,
                                                dc_c_tipo_nit,              dc_c_tipo_soc,          dc_c_num_empleados,
                                                dc_c_sigla,                 dc_c_escritura,         dc_c_notaria,
                                                dc_c_ciudad,                dc_c_fecha_exp,         dc_c_fecha_vcto,
                                                dc_c_camara,                dc_c_registro,          dc_c_grado_soc,
                                                dc_c_edad_laboral_promedio, dc_c_empleados_ley_50,  dc_c_codsuper,
                                                dc_c_fecha_registro,        dc_c_fecha_modif,       dc_c_fecha_verif,
                                                dc_c_vigencia,              dc_c_verificado,        dc_c_funcionario,
                                                dc_s_tipo_soc_hecho,        dc_situacion_cliente,   dc_patrimonio_tec,
                                                dc_fecha_patri_bruto,       dc_gran_contribuyente,  dc_calificacion,
                                                dc_reestructurado,          dc_concurso_acreedores, dc_concordato,
                                                dc_vinculacion,             dc_tipo_vinculacion,    dc_oficial_sup,
                                                dc_cliente,                 dc_preferen,            dc_exc_sipla,
                                                dc_exc_por2,                dc_digito,              dc_categoria,
                                                dc_emala_referencia,        dc_banca,               dc_pensionado,
                                                dc_rep_sib,                 dc_max_riesgo,          dc_riesgo,
                                                dc_mries_ant,               dc_fmod_ries,           dc_user_ries,
                                                dc_reservado,               dc_pas_finan,           dc_fpas_finan,
                                                dc_fbalance,                dc_relacint,            dc_otringr,
                                                dc_exento_cobro,            dc_doctos_carpeta,      dc_oficina_prod,
                                                dc_accion,                  dc_procedencia,         dc_fecha_negocio,
                                                dc_estrato,                 dc_recurso_pub,         dc_influencia,
                                                dc_persona_pub,             dc_victima,             dc_bancarizado,
                                                dc_alto_riesgo,             dc_fecha_riesgo,        dc_estado,
                                                dc_calif_cartera,           dc_cod_otro_pais,       dc_ingre,
                                                dc_cem,                     dc_promotor,            dc_inss,
                                                dc_licencia,                dc_id_tutor,            dc_nom_tutor,
                                                dc_referidor_ecu,           dc_otros_ingresos,      dc_origen_ingresos,
                                                dc_nro_ciclo,               dc_emproblemado,        dc_dinero_transac,
                                                dc_manejo_doc,              dc_persona_pep,         dc_ing_SN,
                                                dc_nac_aux,                 dc_banco,               dc_nacionalidad,
                                                dc_pais_nac,                dc_provincia_nac,       dc_naturalizado,
                                                dc_forma_migratoria,        dc_nro_extranjero,      dc_calle_orig,
                                                dc_exterior_orig,           dc_estado_orig,         dc_firma_electronica,
                                                dc_localidad,               dc_actividad_desc,      dc_nivel,
                                                dc_inf_laboral,             dc_tipo_operacion,      dc_provincia_act,
                                                dc_lugar_act,               dc_filial,              dc_oficina,
                                                dc_fecha_crea,              dc_fecha_mod,           dc_direccion,
                                                dc_referencia,              dc_casilla,             dc_casilla_def,
                                                dc_balance,                 dc_tipo_doc_tributario, dc_tipo_residencia,
                                                dc_ciudad_emision,          dc_ente_migrado,        dc_codigo_pep_relac,
                                                dc_nombre_pep_relac,        dc_p_fecha_inicio_pep,  dc_p_fecha_fin_pep,
                                                dc_p_tipo_pep,              dc_aplicativo,          dc_origen,
                                                dc_fecha_proc,              dc_fecha)
   
   select                                       dc_ente,                    dc_nombre,              dc_subtipo,
                                                dc_tipo_ced,                dc_ced_ruc,             dc_nit,
                                                dc_rfc,                     dc_tipo_iden,           dc_numero_iden,
                                                dc_nomlar,                  dc_actividad,           dc_retencion,
                                                dc_mala_referencia,         dc_comentario,          dc_sector,
                                                dc_referido,                dc_pais,                dc_oficial,
                                                dc_cont_malas,              dc_doc_validado,        dc_rep_superban,
                                                dc_asosciada,               dc_tipo_dp,             dc_grupo,
                                                dc_p_s_nombre,              dc_p_p_apellido,        dc_p_s_apellido,
                                                dc_p_c_apellido,            dc_p_sexo,dc_p_genero,  dc_p_estado_civil,
                                                dc_p_fecha_nac,             dc_p_ciudad_nac,        dc_p_tipo_persona,
                                                dc_p_profesion,             dc_p_ocupacion,         dc_p_lugar_doc,
                                                dc_p_pasaporte,             dc_p_num_cargas,        dc_p_num_hijos,
                                                dc_p_nivel_ing,             dc_p_nivel_egr,         dc_p_nivel_estudio,
                                                dc_p_tipo_vivienda,         dc_p_calif_cliente,     dc_p_personal,
                                                dc_p_propiedad,             dc_p_trabajo,           dc_p_soc_hecho,
                                                dc_p_depa_nac,              dc_p_pais_emi,          dc_p_depa_emi,
                                                dc_p_dep_doc,               dc_p_numord,            dc_p_carg_pub,
                                                dc_p_rel_carg_pub,          dc_p_situacion_laboral, dc_p_bienes,
                                                dc_p_fecha_emision,         dc_p_fecha_expira,      dc_c_razon_social,
                                                dc_c_segmento,              dc_c_cap_suscrito,      dc_c_posicion,
                                                dc_c_tipo_compania,         dc_c_rep_legal,         dc_c_es_grupo,
                                                dc_c_activo,                dc_c_pasivo,            dc_c_total_activos,
                                                dc_c_total_pasivos,         dc_c_capital_social,    dc_c_reserva_legal,
                                                dc_c_cap_pagado,            dc_c_fecha_const,       dc_c_plazo,
                                                dc_c_direccion_domicilio,   dc_c_fecha_inscrp,      dc_c_fecha_aum_capital,
                                                dc_c_tipo_nit,              dc_c_tipo_soc,          dc_c_num_empleados,
                                                dc_c_sigla,                 dc_c_escritura,         dc_c_notaria,
                                                dc_c_ciudad,                dc_c_fecha_exp,         dc_c_fecha_vcto,
                                                dc_c_camara,                dc_c_registro,          dc_c_grado_soc,
                                                dc_c_edad_laboral_promedio, dc_c_empleados_ley_50,  dc_c_codsuper,
                                                dc_c_fecha_registro,        dc_c_fecha_modif,       dc_c_fecha_verif,
                                                dc_c_vigencia,              dc_c_verificado,        dc_c_funcionario,
                                                dc_s_tipo_soc_hecho,        dc_situacion_cliente,   dc_patrimonio_tec,
                                                dc_fecha_patri_bruto,       dc_gran_contribuyente,  dc_calificacion,
                                                dc_reestructurado,          dc_concurso_acreedores, dc_concordato,
                                                dc_vinculacion,             dc_tipo_vinculacion,    dc_oficial_sup,
                                                dc_cliente,                 dc_preferen,            dc_exc_sipla,
                                                dc_exc_por2,                dc_digito,              dc_categoria,
                                                dc_emala_referencia,        dc_banca,               dc_pensionado,
                                                dc_rep_sib,                 dc_max_riesgo,          dc_riesgo,
                                                dc_mries_ant,               dc_fmod_ries,           dc_user_ries,
                                                dc_reservado,               dc_pas_finan,           dc_fpas_finan,
                                                dc_fbalance,                dc_relacint,            dc_otringr,
                                                dc_exento_cobro,            dc_doctos_carpeta,      dc_oficina_prod,
                                                dc_accion,                  dc_procedencia,         dc_fecha_negocio,
                                                dc_estrato,                 dc_recurso_pub,         dc_influencia,
                                                dc_persona_pub,             dc_victima,             dc_bancarizado,
                                                dc_alto_riesgo,             dc_fecha_riesgo,        dc_estado,
                                                dc_calif_cartera,           dc_cod_otro_pais,       dc_ingre,
                                                dc_cem,                     dc_promotor,            dc_inss,
                                                dc_licencia,                dc_id_tutor,            dc_nom_tutor,
                                                dc_referidor_ecu,           dc_otros_ingresos,      dc_origen_ingresos,
                                                dc_nro_ciclo,               dc_emproblemado,        dc_dinero_transac,
                                                dc_manejo_doc,              dc_persona_pep,         dc_ing_SN,
                                                dc_nac_aux,                 dc_banco,               dc_nacionalidad,
                                                dc_pais_nac,                dc_provincia_nac,       dc_naturalizado,
                                                dc_forma_migratoria,        dc_nro_extranjero,      dc_calle_orig,
                                                dc_exterior_orig,           dc_estado_orig,         dc_firma_electronica,
                                                dc_localidad,               dc_actividad_desc,      dc_nivel,
                                                dc_inf_laboral,             dc_tipo_operacion,      dc_provincia_act,
                                                dc_lugar_act,               dc_filial,              dc_oficina,
                                                dc_fecha_crea,              dc_fecha_mod,           dc_direccion,
                                                dc_referencia,              dc_casilla,             dc_casilla_def,
                                                dc_balance,                 dc_tipo_doc_tributario, dc_tipo_residencia,
                                                dc_ciudad_emision,          dc_ente_migrado,        dc_codigo_pep_relac,
                                                dc_nombre_pep_relac,        dc_p_fecha_inicio_pep,  dc_p_fecha_fin_pep,
                                                dc_p_tipo_pep,              dc_aplicativo,          dc_origen,
                                                dc_fecha_proc,              dc_fecha
   from cob_externos..ex_dato_cliente
   where dc_fecha_proc = @i_fecha_proc      
   
   if @@error <> 0 
   begin
      exec cobis..sp_cerror
         @t_debug     = @t_debug,
         @t_file      = @t_file,
         @t_from      = @w_sp_name,
         @i_num       = 1720528
      return 1720528
   end

   print 'Insertando en sb_dato_direccion'

   insert into cob_conta_super..sb_dato_direccion(dd_ente,           dd_direccion,      dd_descripcion,
                                                  dd_parroquia,      dd_ciudad,         dd_tipo,
                                                  dd_telefono,       dd_sector,         dd_zona,
                                                  dd_oficina,        dd_fecha_registro, dd_fecha_modificacion,
                                                  dd_vigencia,       dd_verificado,     dd_funcionario,
                                                  dd_fecha_ver,      dd_principal,      dd_barrio,
                                                  dd_provincia,      dd_tienetel,       dd_rural_urb,
                                                  dd_observacion,    dd_obs_verificado, dd_extfin,
                                                  dd_pais,           dd_departamento,   dd_tipo_prop,
                                                  dd_rural_urbano,   dd_codpostal,      dd_casa,
                                                  dd_calle,          dd_codbarrio,      dd_correspondencia,
                                                  dd_alquilada,      dd_cobro,          dd_otrasenas,
                                                  dd_canton,         dd_distrito,       dd_montoalquiler,
                                                  dd_edificio,       dd_so_igu_co,      dd_fact_serv_pu,
                                                  dd_nombre_agencia, dd_fuente_verif,   dd_tiempo_reside,
                                                  dd_nro,            dd_nro_residentes, dd_nro_interno,
                                                  dd_negocio,        dd_poblacion,      dd_referencias_dom,
                                                  dd_otro_tipo,      dd_localidad,      dd_conjunto,
                                                  dd_piso,           dd_numero_casa,    dd_aplicativo,
                                                  dd_origen,         dd_fecha_proc,     dd_fecha)

   select                                         dd_ente,           dd_direccion,      dd_descripcion,
                                                  dd_parroquia,      dd_ciudad,         dd_tipo,
                                                  dd_telefono,       dd_sector,         dd_zona,
                                                  dd_oficina,        dd_fecha_registro, dd_fecha_modificacion,
                                                  dd_vigencia,       dd_verificado,     dd_funcionario,
                                                  dd_fecha_ver,      dd_principal,      dd_barrio,
                                                  dd_provincia,      dd_tienetel,       dd_rural_urb,
                                                  dd_observacion,    dd_obs_verificado, dd_extfin,
                                                  dd_pais,           dd_departamento,   dd_tipo_prop,
                                                  dd_rural_urbano,   dd_codpostal,      dd_casa,
                                                  dd_calle,          dd_codbarrio,      dd_correspondencia,
                                                  dd_alquilada,      dd_cobro,          dd_otrasenas,
                                                  dd_canton,         dd_distrito,       dd_montoalquiler,
                                                  dd_edificio,       dd_so_igu_co,      dd_fact_serv_pu,
                                                  dd_nombre_agencia, dd_fuente_verif,   dd_tiempo_reside,
                                                  dd_nro,            dd_nro_residentes, dd_nro_interno,
                                                  dd_negocio,        dd_poblacion,      dd_referencias_dom,
                                                  dd_otro_tipo,      dd_localidad,      dd_conjunto,
                                                  dd_piso,           dd_numero_casa,    dd_aplicativo,
                                                  dd_origen,         dd_fecha_proc,     dd_fecha
   from cob_externos..ex_dato_direccion
   where dd_fecha_proc = @i_fecha_proc   
   
   if @@error <> 0 
   begin
      exec cobis..sp_cerror
         @t_debug     = @t_debug,
         @t_file      = @t_file,
         @t_from      = @w_sp_name,
         @i_num       = 1720529
      return 1720529
   end

   print 'Insertando en sb_dato_telefono'

   insert into cob_conta_super..sb_dato_telefono(dt_ente,           dt_direccion,     dt_secuencial,
                                                 dt_valor,          dt_tipo_telefono, dt_prefijo,
                                                 dt_fecha_registro, dt_fecha_mod,     dt_tipo_operador,
                                                 dt_area,           dt_telf_cobro,    dt_funcionario,
                                                 dt_verificado,     dt_fecha_ver,     dt_fecha_modificacion,
                                                 dt_aplicativo,     dt_origen,        dt_fecha_proc,
                                                 dt_fecha)
                                                 
   select                                        dt_ente,           dt_direccion,     dt_secuencial,
                                                 dt_valor,          dt_tipo_telefono, dt_prefijo,
                                                 dt_fecha_registro, dt_fecha_mod,     dt_tipo_operador,
                                                 dt_area,           dt_telf_cobro,    dt_funcionario,
                                                 dt_verificado,     dt_fecha_ver,     dt_fecha_modificacion,
                                                 dt_aplicativo,     dt_origen,        dt_fecha_proc,
                                                 dt_fecha
   from cob_externos..ex_dato_telefono
   where dt_fecha_proc = @i_fecha_proc 
   
   if @@error <> 0 
   begin
      exec cobis..sp_cerror
         @t_debug     = @t_debug,
         @t_file      = @t_file,
         @t_from      = @w_sp_name,
         @i_num       = 1720530
      return 1720530
   end
end

return @w_return

go
