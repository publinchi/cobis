# Índices por Clave Foránea

## Descripción
Este documento lista todos los índices de clave foránea definidos en las tablas del módulo de Clientes para garantizar la integridad referencial.

---

## Índices de Relaciones entre Tablas

### cl_actividad_ec
- **Índice:** FK_cl_actividad_ec_subsector
- **Campos:** ac_codSubsector
- **Referencia:** cl_subsector_ec(ss_codigo)

### cl_actualiza
- **Índice:** FK_cl_actualiza_ente
- **Campos:** ac_ente
- **Referencia:** cl_ente(en_ente)

### cl_at_instancia
- **Índice:** FK_cl_at_instancia_relacion
- **Campos:** ai_relacion
- **Referencia:** cl_relacion(rl_relacion)

- **Índice:** FK_cl_at_instancia_ente_i
- **Campos:** ai_ente_i
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_at_instancia_ente_d
- **Campos:** ai_ente_d
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_at_instancia_atributo
- **Campos:** ai_relacion, ai_atributo
- **Referencia:** cl_at_relacion(ar_relacion, ar_atributo)

### cl_at_relacion
- **Índice:** FK_cl_at_relacion_relacion
- **Campos:** ar_relacion
- **Referencia:** cl_relacion(rl_relacion)

### cl_cliente
- **Índice:** FK_cl_cliente_ente
- **Campos:** cl_cliente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_cliente_producto
- **Campos:** cl_det_producto
- **Referencia:** cl_det_producto(dp_cuenta)

### cl_cliente_grupo
- **Índice:** FK_cl_cliente_grupo_ente
- **Campos:** cg_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_cliente_grupo_grupo
- **Campos:** cg_grupo
- **Referencia:** cl_grupo(gr_grupo)

### cl_contacto
- **Índice:** FK_cl_contacto_ente
- **Campos:** co_ente
- **Referencia:** cl_ente(en_ente)

### cl_ejecutivo
- **Índice:** FK_cl_ejecutivo_ente
- **Campos:** ec_ente
- **Referencia:** cl_ente(en_ente)

### cl_direccion
- **Índice:** FK_cl_direccion_ente
- **Campos:** di_ente
- **Referencia:** cl_ente(en_ente)

### cl_hijos
- **Índice:** FK_cl_hijos_ente
- **Campos:** hi_ente
- **Referencia:** cl_ente(en_ente)

### cl_his_ejecutivo
- **Índice:** FK_cl_his_ejecutivo_ente
- **Campos:** he_ente
- **Referencia:** cl_ente(en_ente)

### cl_his_relacion
- **Índice:** FK_cl_his_relacion_relacion
- **Campos:** hr_relacion
- **Referencia:** cl_relacion(rl_relacion)

- **Índice:** FK_cl_his_relacion_ente_i
- **Campos:** hr_ente_i
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_his_relacion_ente_d
- **Campos:** hr_ente_d
- **Referencia:** cl_ente(en_ente)

### cl_instancia
- **Índice:** FK_cl_instancia_relacion
- **Campos:** in_relacion
- **Referencia:** cl_relacion(rl_relacion)

- **Índice:** FK_cl_instancia_ente_i
- **Campos:** in_ente_i
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_instancia_ente_d
- **Campos:** in_ente_d
- **Referencia:** cl_ente(en_ente)

### cl_mala_ref
- **Índice:** FK_cl_mala_ref_ente
- **Campos:** mr_ente
- **Referencia:** cl_ente(en_ente)

### cl_ref_personal
- **Índice:** FK_cl_ref_personal_ente
- **Campos:** rp_ente
- **Referencia:** cl_ente(en_ente)

### cl_referencia
- **Índice:** FK_cl_referencia_ente
- **Campos:** re_ente
- **Referencia:** cl_ente(en_ente)

### cl_refinh
- **Índice:** FK_cl_refinh_ente
- **Campos:** ri_ente
- **Referencia:** cl_ente(en_ente)

### cl_telefono
- **Índice:** FK_cl_telefono_ente
- **Campos:** te_ente
- **Referencia:** cl_ente(en_ente)

### cl_actividad_principal
- **Índice:** FK_cl_actividad_principal_sector
- **Campos:** ap_sector
- **Referencia:** cl_sector_economico(se_codigo)

### cl_ente_aux
- **Índice:** FK_cl_ente_aux_ente
- **Campos:** ea_ente
- **Referencia:** cl_ente(en_ente)

### cl_mod_estados
- **Índice:** FK_cl_mod_estados_ente
- **Campos:** me_ente
- **Referencia:** cl_ente(en_ente)

### cl_subsector_ec
- **Índice:** FK_cl_subsector_ec_sector
- **Campos:** ss_sector
- **Referencia:** cl_sector_economico(se_codigo)

### cl_subactividad_ec
- **Índice:** FK_cl_subactividad_ec_actividad
- **Campos:** sa_actividad
- **Referencia:** cl_actividad_ec(ac_codigo)

### cl_actividad_economica
- **Índice:** FK_cl_actividad_economica_ente
- **Campos:** ae_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_actividad_economica_actividad
- **Campos:** ae_actividad
- **Referencia:** cl_actividad_ec(ac_codigo)

### cl_infocred_central
- **Índice:** FK_cl_infocred_central_ente
- **Campos:** ic_ente
- **Referencia:** cl_ente(en_ente)

### cl_direccion_geo
- **Índice:** FK_cl_direccion_geo_ente
- **Campos:** dg_ente, dg_direccion
- **Referencia:** cl_direccion(di_ente, di_direccion)

### cl_dadicion_ente
- **Índice:** FK_cl_dadicion_ente_ente
- **Campos:** de_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_dadicion_ente_dato
- **Campos:** de_dato_adicional
- **Referencia:** cl_dato_adicion(da_codigo)

### cl_comercial
- **Índice:** FK_cl_comercial_ente
- **Campos:** co_ente
- **Referencia:** cl_ente(en_ente)

### cl_financiera
- **Índice:** FK_cl_financiera_ente
- **Campos:** fi_ente
- **Referencia:** cl_ente(en_ente)

### cl_economica
- **Índice:** FK_cl_economica_ente
- **Campos:** ec_ente
- **Referencia:** cl_ente(en_ente)

### cl_tarjeta
- **Índice:** FK_cl_tarjeta_ente
- **Campos:** ta_ente
- **Referencia:** cl_ente(en_ente)

### cl_negocio_cliente
- **Índice:** FK_cl_negocio_cliente_ente
- **Campos:** nc_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_negocio_cliente_actividad
- **Campos:** nc_actividad
- **Referencia:** cl_actividad_ec(ac_codigo)

### cl_validacion_listas_externas
- **Índice:** FK_cl_validacion_listas_ente
- **Campos:** vl_ente
- **Referencia:** cl_ente(en_ente)

### cl_ptos_matriz_riesgo
- **Índice:** FK_cl_ptos_matriz_riesgo_ente
- **Campos:** pm_ente
- **Referencia:** cl_ente(en_ente)

### cl_info_trn_riesgo
- **Índice:** FK_cl_info_trn_riesgo_ente
- **Campos:** itr_ente
- **Referencia:** cl_ente(en_ente)

### cl_val_iden
- **Índice:** FK_cl_val_iden_ente
- **Campos:** vi_ente
- **Referencia:** cl_ente(en_ente)

### cl_registro_identificacion
- **Índice:** FK_cl_registro_identificacion_ente
- **Campos:** ri_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_registro_identificacion_tipo
- **Campos:** ri_tipo_identificacion
- **Referencia:** cl_tipo_identificacion(ti_codigo)

### cl_registro_cambio
- **Índice:** FK_cl_registro_cambio_ente
- **Campos:** rc_ente
- **Referencia:** cl_ente(en_ente)

### cl_alertas_riesgo
- **Índice:** FK_cl_alertas_riesgo_ente
- **Campos:** ar_ente
- **Referencia:** cl_ente(en_ente)

### cl_analisis_negocio
- **Índice:** FK_cl_analisis_negocio_ente
- **Campos:** an_ente
- **Referencia:** cl_ente(en_ente)

### cl_beneficiario_seguro
- **Índice:** FK_cl_beneficiario_seguro_ente
- **Campos:** bs_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_beneficiario_seguro_producto
- **Campos:** bs_producto
- **Referencia:** cl_det_producto(dp_cuenta)

### cl_control_empresas_rfe
- **Índice:** FK_cl_control_empresas_rfe_ente
- **Campos:** ce_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_control_empresas_rfe_empresa
- **Campos:** ce_empresa
- **Referencia:** cl_ente(en_ente)

### cl_direccion_fiscal
- **Índice:** FK_cl_direccion_fiscal_ente
- **Campos:** df_ente
- **Referencia:** cl_ente(en_ente)

### cl_documento_actividad
- **Índice:** FK_cl_documento_actividad_actividad
- **Campos:** da_actividad
- **Referencia:** cl_actividad_ec(ac_codigo)

### cl_documento_digitalizado
- **Índice:** FK_cl_documento_digitalizado_ente
- **Campos:** dd_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_documento_digitalizado_parametro
- **Campos:** dd_tipo_documento
- **Referencia:** cl_documento_parametro(dp_codigo)

### cl_manejo_sarlaft
- **Índice:** FK_cl_manejo_sarlaft_ente
- **Campos:** ms_ente
- **Referencia:** cl_ente(en_ente)

### cl_notificacion_general
- **Índice:** FK_cl_notificacion_general_ente
- **Campos:** ng_ente
- **Referencia:** cl_ente(en_ente)

### cl_ns_generales_estado
- **Índice:** FK_cl_ns_generales_estado_notif
- **Campos:** ne_notificacion
- **Referencia:** cl_notificacion_general(ng_secuencial)

### cl_pais_id_fiscal
- **Índice:** FK_cl_pais_id_fiscal_ente
- **Campos:** pf_ente
- **Referencia:** cl_ente(en_ente)

### cl_productos_negocio
- **Índice:** FK_cl_productos_negocio_ente
- **Campos:** pn_ente, pn_negocio
- **Referencia:** cl_negocio_cliente(nc_ente, nc_secuencial)

### cl_trabajo
- **Índice:** FK_cl_trabajo_ente
- **Campos:** tr_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_trabajo_actividad
- **Campos:** tr_actividad_empresa
- **Referencia:** cl_actividad_ec(ac_codigo)

### cl_ident_ente
- **Índice:** FK_cl_ident_ente_ente
- **Campos:** ie_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_ident_ente_tipo
- **Campos:** ie_tipo_identificacion
- **Referencia:** cl_tipo_identificacion(ti_codigo)

### cl_ref_telefono
- **Índice:** FK_cl_ref_telefono_referencia
- **Campos:** rt_ente, rt_referencia
- **Referencia:** cl_ref_personal(rp_ente, rp_secuencial)

### cl_listas_negras_log
- **Índice:** FK_cl_listas_negras_log_ente
- **Campos:** ll_ente
- **Referencia:** cl_ente(en_ente)

### cl_indice_pob_respuesta
- **Índice:** FK_cl_indice_pob_respuesta_pregunta
- **Campos:** ir_pregunta
- **Referencia:** cl_indice_pob_preg(ip_codigo)

### cl_ppi_ente
- **Índice:** FK_cl_ppi_ente_ente
- **Campos:** pe_ente
- **Referencia:** cl_ente(en_ente)

### cl_det_ppi_ente
- **Índice:** FK_cl_det_ppi_ente_evaluacion
- **Campos:** dp_evaluacion
- **Referencia:** cl_ppi_ente(pe_secuencial)

- **Índice:** FK_cl_det_ppi_ente_pregunta
- **Campos:** dp_pregunta
- **Referencia:** cl_indice_pob_preg(ip_codigo)

- **Índice:** FK_cl_det_ppi_ente_respuesta
- **Campos:** dp_respuesta
- **Referencia:** cl_indice_pob_respuesta(ir_codigo)

### cl_puntaje_ppi_ente
- **Índice:** FK_cl_puntaje_ppi_ente_ente
- **Campos:** pp_ente
- **Referencia:** cl_ente(en_ente)

- **Índice:** FK_cl_puntaje_ppi_ente_evaluacion
- **Campos:** pp_evaluacion
- **Referencia:** cl_ppi_ente(pe_secuencial)

### cl_tran_servicio
- **Índice:** FK_cl_tran_servicio_ente
- **Campos:** ts_ente
- **Referencia:** cl_ente(en_ente)

---

## Notas sobre Integridad Referencial

Los índices de clave foránea garantizan:

1. **Integridad Referencial:** Aseguran que los valores en las columnas de clave foránea existan en las tablas referenciadas.

2. **Rendimiento:** Mejoran el rendimiento de las consultas que involucran joins entre tablas relacionadas.

3. **Consistencia:** Previenen la inserción de datos huérfanos o inconsistentes.

4. **Cascada:** Algunos índices pueden configurarse con opciones de cascada para actualización o eliminación.

---

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
