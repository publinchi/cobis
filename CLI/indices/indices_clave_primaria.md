# Índices por Clave Primaria

## Descripción
Este documento lista todos los índices de clave primaria definidos en las tablas del módulo de Clientes.

---

## Índices de Tablas Principales

### cl_actividad_ec
- **Índice:** PK_cl_actividad_ec
- **Campos:** ac_codigo
- **Tipo:** Primary Key

### cl_actualiza
- **Índice:** PK_cl_actualiza
- **Campos:** ac_ente, ac_fecha, ac_tabla, ac_campo
- **Tipo:** Primary Key

### cl_at_instancia
- **Índice:** PK_cl_at_instancia
- **Campos:** ai_relacion, ai_ente_i, ai_ente_d, ai_atributo
- **Tipo:** Primary Key

### cl_at_relacion
- **Índice:** PK_cl_at_relacion
- **Campos:** ar_relacion, ar_atributo
- **Tipo:** Primary Key

### cl_cliente
- **Índice:** PK_cl_cliente
- **Campos:** cl_cliente, cl_det_producto
- **Tipo:** Primary Key

### cl_cliente_grupo
- **Índice:** PK_cl_cliente_grupo
- **Campos:** cg_ente, cg_grupo
- **Tipo:** Primary Key

### cl_contacto
- **Índice:** PK_cl_contacto
- **Campos:** co_ente, co_secuencial
- **Tipo:** Primary Key

### cl_det_producto
- **Índice:** PK_cl_det_producto
- **Campos:** dp_cuenta
- **Tipo:** Primary Key

### cl_ejecutivo
- **Índice:** PK_cl_ejecutivo
- **Campos:** ec_ente, ec_funcionario
- **Tipo:** Primary Key

### cl_direccion
- **Índice:** PK_cl_direccion
- **Campos:** di_ente, di_direccion
- **Tipo:** Primary Key

### cl_ente
- **Índice:** PK_cl_ente
- **Campos:** en_ente
- **Tipo:** Primary Key

### cl_grupo
- **Índice:** PK_cl_grupo
- **Campos:** gr_grupo
- **Tipo:** Primary Key

### cl_hijos
- **Índice:** PK_cl_hijos
- **Campos:** hi_ente, hi_secuencial
- **Tipo:** Primary Key

### cl_his_ejecutivo
- **Índice:** PK_cl_his_ejecutivo
- **Campos:** he_secuencial
- **Tipo:** Primary Key

### cl_his_relacion
- **Índice:** PK_cl_his_relacion
- **Campos:** hr_secuencial
- **Tipo:** Primary Key

### cl_instancia
- **Índice:** PK_cl_instancia
- **Campos:** in_relacion, in_ente_i, in_ente_d
- **Tipo:** Primary Key

### cl_mala_ref
- **Índice:** PK_cl_mala_ref
- **Campos:** mr_secuencial
- **Tipo:** Primary Key

### cl_mercado
- **Índice:** PK_cl_mercado
- **Campos:** me_codigo
- **Tipo:** Primary Key

### cl_ref_personal
- **Índice:** PK_cl_ref_personal
- **Campos:** rp_ente, rp_secuencial
- **Tipo:** Primary Key

### cl_referencia
- **Índice:** PK_cl_referencia
- **Campos:** re_ente, re_secuencial
- **Tipo:** Primary Key

### cl_refinh
- **Índice:** PK_cl_refinh
- **Campos:** ri_secuencial
- **Tipo:** Primary Key

### cl_relacion
- **Índice:** PK_cl_relacion
- **Campos:** rl_relacion
- **Tipo:** Primary Key

### cl_telefono
- **Índice:** PK_cl_telefono
- **Campos:** te_ente, te_secuencial
- **Tipo:** Primary Key

### cl_tipo_documento
- **Índice:** PK_cl_tipo_documento
- **Campos:** td_codigo
- **Tipo:** Primary Key

### cl_com_liquidacion
- **Índice:** PK_cl_com_liquidacion
- **Campos:** cl_codigo
- **Tipo:** Primary Key

### cl_narcos
- **Índice:** PK_cl_narcos
- **Campos:** na_secuencial
- **Tipo:** Primary Key

### cl_actividad_principal
- **Índice:** PK_cl_actividad_principal
- **Campos:** ap_codigo
- **Tipo:** Primary Key

### cl_ente_aux
- **Índice:** PK_cl_ente_aux
- **Campos:** ea_ente, ea_campo
- **Tipo:** Primary Key

### cl_mod_estados
- **Índice:** PK_cl_mod_estados
- **Campos:** me_ente, me_secuencial
- **Tipo:** Primary Key

### cl_sector_economico
- **Índice:** PK_cl_sector_economico
- **Campos:** se_codigo
- **Tipo:** Primary Key

### cl_subsector_ec
- **Índice:** PK_cl_subsector_ec
- **Campos:** ss_codigo
- **Tipo:** Primary Key

### cl_subactividad_ec
- **Índice:** PK_cl_subactividad_ec
- **Campos:** sa_codigo
- **Tipo:** Primary Key

### cl_actividad_economica
- **Índice:** PK_cl_actividad_economica
- **Campos:** ae_ente, ae_secuencial
- **Tipo:** Primary Key

### cl_listas_negras
- **Índice:** PK_cl_listas_negras
- **Campos:** ln_secuencial
- **Tipo:** Primary Key

### cl_infocred_central
- **Índice:** PK_cl_infocred_central
- **Campos:** ic_ente, ic_secuencial
- **Tipo:** Primary Key

### cl_direccion_geo
- **Índice:** PK_cl_direccion_geo
- **Campos:** dg_ente, dg_direccion
- **Tipo:** Primary Key

### cl_dato_adicion
- **Índice:** PK_cl_dato_adicion
- **Campos:** da_codigo
- **Tipo:** Primary Key

### cl_dadicion_ente
- **Índice:** PK_cl_dadicion_ente
- **Campos:** de_ente, de_dato_adicional
- **Tipo:** Primary Key

### cl_comercial
- **Índice:** PK_cl_comercial
- **Campos:** co_ente
- **Tipo:** Primary Key

### cl_financiera
- **Índice:** PK_cl_financiera
- **Campos:** fi_ente, fi_secuencial
- **Tipo:** Primary Key

### cl_economica
- **Índice:** PK_cl_economica
- **Campos:** ec_ente
- **Tipo:** Primary Key

### cl_tarjeta
- **Índice:** PK_cl_tarjeta
- **Campos:** ta_ente, ta_secuencial
- **Tipo:** Primary Key

### cl_negocio_cliente
- **Índice:** PK_cl_negocio_cliente
- **Campos:** nc_ente, nc_secuencial
- **Tipo:** Primary Key

### cl_validacion_listas_externas
- **Índice:** PK_cl_validacion_listas_externas
- **Campos:** vl_secuencial
- **Tipo:** Primary Key

### cl_tipo_identificacion
- **Índice:** PK_cl_tipo_identificacion
- **Campos:** ti_codigo
- **Tipo:** Primary Key

### cl_ptos_matriz_riesgo
- **Índice:** PK_cl_ptos_matriz_riesgo
- **Campos:** pm_secuencial
- **Tipo:** Primary Key

### cl_info_trn_riesgo
- **Índice:** PK_cl_info_trn_riesgo
- **Campos:** itr_secuencial
- **Tipo:** Primary Key

### cl_val_iden
- **Índice:** PK_cl_val_iden
- **Campos:** vi_secuencial
- **Tipo:** Primary Key

### cl_scripts
- **Índice:** PK_cl_scripts
- **Campos:** sc_codigo
- **Tipo:** Primary Key

### cl_registro_identificacion
- **Índice:** PK_cl_registro_identificacion
- **Campos:** ri_secuencial
- **Tipo:** Primary Key

### cl_registro_cambio
- **Índice:** PK_cl_registro_cambio
- **Campos:** rc_secuencial
- **Tipo:** Primary Key

### cl_alertas_riesgo
- **Índice:** PK_cl_alertas_riesgo
- **Campos:** ar_secuencial
- **Tipo:** Primary Key

### cl_analisis_negocio
- **Índice:** PK_cl_analisis_negocio
- **Campos:** an_secuencial
- **Tipo:** Primary Key

### cl_beneficiario_seguro
- **Índice:** PK_cl_beneficiario_seguro
- **Campos:** bs_secuencial
- **Tipo:** Primary Key

### cl_control_empresas_rfe
- **Índice:** PK_cl_control_empresas_rfe
- **Campos:** ce_secuencial
- **Tipo:** Primary Key

### cl_direccion_fiscal
- **Índice:** PK_cl_direccion_fiscal
- **Campos:** df_ente, df_secuencial
- **Tipo:** Primary Key

### cl_documento_actividad
- **Índice:** PK_cl_documento_actividad
- **Campos:** da_secuencial
- **Tipo:** Primary Key

### cl_documento_digitalizado
- **Índice:** PK_cl_documento_digitalizado
- **Campos:** dd_secuencial
- **Tipo:** Primary Key

### cl_documento_parametro
- **Índice:** PK_cl_documento_parametro
- **Campos:** dp_codigo
- **Tipo:** Primary Key

### cl_manejo_sarlaft
- **Índice:** PK_cl_manejo_sarlaft
- **Campos:** ms_secuencial
- **Tipo:** Primary Key

### cl_notificacion_general
- **Índice:** PK_cl_notificacion_general
- **Campos:** ng_secuencial
- **Tipo:** Primary Key

### cl_ns_generales_estado
- **Índice:** PK_cl_ns_generales_estado
- **Campos:** ne_secuencial
- **Tipo:** Primary Key

### cl_pais_id_fiscal
- **Índice:** PK_cl_pais_id_fiscal
- **Campos:** pf_secuencial
- **Tipo:** Primary Key

### cl_productos_negocio
- **Índice:** PK_cl_productos_negocio
- **Campos:** pn_secuencial
- **Tipo:** Primary Key

### cl_seccion_validar
- **Índice:** PK_cl_seccion_validar
- **Campos:** sv_codigo
- **Tipo:** Primary Key

### cl_trabajo
- **Índice:** PK_cl_trabajo
- **Campos:** tr_ente, tr_secuencial
- **Tipo:** Primary Key

### cl_ident_ente
- **Índice:** PK_cl_ident_ente
- **Campos:** ie_secuencial
- **Tipo:** Primary Key

### cl_ref_telefono
- **Índice:** PK_cl_ref_telefono
- **Campos:** rt_ente, rt_referencia, rt_secuencial
- **Tipo:** Primary Key

### cl_listas_negras_log
- **Índice:** PK_cl_listas_negras_log
- **Campos:** ll_secuencial
- **Tipo:** Primary Key

### cl_listas_negras_rfe
- **Índice:** PK_cl_listas_negras_rfe
- **Campos:** lr_secuencial
- **Tipo:** Primary Key

### cl_indice_pob_preg
- **Índice:** PK_cl_indice_pob_preg
- **Campos:** ip_codigo
- **Tipo:** Primary Key

### cl_indice_pob_respuesta
- **Índice:** PK_cl_indice_pob_respuesta
- **Campos:** ir_codigo
- **Tipo:** Primary Key

### cl_ppi_ente
- **Índice:** PK_cl_ppi_ente
- **Campos:** pe_secuencial
- **Tipo:** Primary Key

### cl_det_ppi_ente
- **Índice:** PK_cl_det_ppi_ente
- **Campos:** dp_secuencial
- **Tipo:** Primary Key

### cl_puntaje_ppi_ente
- **Índice:** PK_cl_puntaje_ppi_ente
- **Campos:** pp_secuencial
- **Tipo:** Primary Key

### cl_tran_servicio
- **Índice:** PK_cl_tran_servicio
- **Campos:** ts_secuencial
- **Tipo:** Primary Key

---

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
