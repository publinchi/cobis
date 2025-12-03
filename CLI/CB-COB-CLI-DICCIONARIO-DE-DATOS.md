# MANUAL TÉCNICO - DICCIONARIO DE DATOS

## Módulo: Clientes

---

## Tabla de Contenido

1. [INTRODUCCIÓN](#introducción)
2. [OBJETIVO](#objetivo)
3. [ALCANCE](#alcance)
4. [DEFINICIONES](#definiciones)
5. [Diccionario de datos](#diccionario-de-datos)
6. [Índices](#índices)

---

## 1. INTRODUCCIÓN

### 1.1. El módulo Clientes dentro de la estructura general

El presente manual técnico COBIS describe las estructuras que permiten operar el módulo Clientes, en relación a que constituye un elemento de integración de la información, enlazando y relacionando los datos de cada cliente entre los diferentes módulos, consolidando su posición económica, rentabilidad y riesgo ante la Institución. Permite conocer los costos operativos generales de la empresa por cliente y por producto, evitando demoras innecesarias y optimizando tiempo y dinero en el proceso.

Adicionalmente, el módulo de CLIENTES permite la simulación de condiciones operativas de una Institución, el análisis de nuevos productos y servicios considerando las características de los clientes, permitiendo su segmentación por mercados y ubicación geográfica.

Por otra parte, el módulo Clientes interactúa con los siguientes módulos COBIS:

- Administración
- XSell
- Crédito
- Cobranzas
- Cartera
- Plazo Fijo
- Cuentas Corrientes
- Cuentas de Ahorros
- Tesorería
- Servicios Bancarios
- Banca Virtual
- Comercio Exterior
- Activos Fijos

Dentro de la funcionalidad del módulo, es válido destacar los siguientes aspectos:

#### Información para mercadeo

Manejo de información para soporte a las actividades del área de mercadeo de la Institución, con posibilidades de análisis de factibilidad de nuevos productos, distribución geográfica de clientes y evaluación del comportamiento de productos.

El manejo de la distribución geográfica de los clientes se complementa con el análisis de nuevos productos, facilitando la definición de perfiles para potenciales clientes con los atributos que se desee (por ejemplo, edad, ingresos, propiedades, sexo, saldos promedios en cuentas) para encontrar aquellos que cumplan el perfil definido. Además, el conocimiento de la ubicación de estos clientes permite determinar las posibilidades de éxito de productos y realizar la definición de campañas de publicidad dirigidas a los clientes objetivos para cada producto.

#### Información de saldos de clientes

Obtención de información sobre los saldos, saldos promedios y flujo de movimientos de los productos contratados por el cliente.

---

## 2. OBJETIVO

Mostrar el modelo de datos que usa el módulo de Clientes.

---

## 3. ALCANCE

**Diccionario de Datos:** indica la estructura de cada tabla.

**Vistas y Transacciones de Servicio:** En esta parte del manual se indica las tablas para el registro de transacciones, de las cuales se necesita información como: qué usuario realizó la transacción, en qué fecha y hora, desde qué y en qué servidor, código de identificación de la transacción, los datos de la transacción, etc. Además, contiene las Vistas que intervienen en el módulo para consultas de Distribución Geográfica.

---

## 4. DEFINICIONES

No aplica

---

## 5. Diccionario de datos

### 5.1. Detalle de las estructuras de datos

#### Tablas Principales

- [cl_actividad_ec](tablas/cl_actividad_ec.md)
- [cl_actualiza](tablas/cl_actualiza.md) *(No se usa en esta versión)*
- [cl_at_instancia](tablas/cl_at_instancia.md)
- [cl_at_relacion](tablas/cl_at_relacion.md)
- [cl_cliente](tablas/cl_cliente.md)
- [cl_cliente_grupo](tablas/cl_cliente_grupo.md)
- [cl_contacto](tablas/cl_contacto.md) *(No se usa en esta versión)*
- [cl_det_producto](tablas/cl_det_producto.md)
- [cl_ejecutivo](tablas/cl_ejecutivo.md)
- [cl_direccion](tablas/cl_direccion.md)
- [cl_ente](tablas/cl_ente.md)
- [cl_grupo](tablas/cl_grupo.md)
- [cl_hijos](tablas/cl_hijos.md) *(No se usa en esta versión)*
- [cl_his_ejecutivo](tablas/cl_his_ejecutivo.md)
- [cl_his_relacion](tablas/cl_his_relacion.md)
- [cl_instancia](tablas/cl_instancia.md)
- [cl_mala_ref](tablas/cl_mala_ref.md)
- [cl_mercado](tablas/cl_mercado.md) *(No se usa en esta versión)*
- [cl_ref_personal](tablas/cl_ref_personal.md)
- [cl_referencia](tablas/cl_referencia.md) *(No se usa en esta versión)*
- [cl_refinh](tablas/cl_refinh.md)
- [cl_relacion](tablas/cl_relacion.md)
- [cl_telefono](tablas/cl_telefono.md)
- [cl_tipo_documento](tablas/cl_tipo_documento.md)
- [cl_com_liquidacion](tablas/cl_com_liquidacion.md)
- [cl_narcos](tablas/cl_narcos.md)
- [cl_actividad_principal](tablas/cl_actividad_principal.md)
- [cl_ente_aux](tablas/cl_ente_aux.md)
- [cl_mod_estados](tablas/cl_mod_estados.md) *(No se usa en esta versión)*
- [cl_sector_economico](tablas/cl_sector_economico.md)
- [cl_subsector_ec](tablas/cl_subsector_ec.md)
- [cl_subactividad_ec](tablas/cl_subactividad_ec.md)
- [cl_actividad_economica](tablas/cl_actividad_economica.md)
- [cl_listas_negras](tablas/cl_listas_negras.md) *(No se usa en esta versión)*
- [cl_infocred_central](tablas/cl_infocred_central.md) *(No se usa en esta versión)*
- [cl_direccion_geo](tablas/cl_direccion_geo.md)
- [cl_dato_adicion](tablas/cl_dato_adicion.md)
- [cl_dadicion_ente](tablas/cl_dadicion_ente.md)
- [cl_comercial](tablas/cl_comercial.md)
- [cl_financiera](tablas/cl_financiera.md)
- [cl_economica](tablas/cl_economica.md)
- [cl_tarjeta](tablas/cl_tarjeta.md)
- [cl_negocio_cliente](tablas/cl_negocio_cliente.md)
- [cl_validacion_listas_externas](tablas/cl_validacion_listas_externas.md)
- [cl_tipo_identificacion](tablas/cl_tipo_identificacion.md)
- [cl_ptos_matriz_riesgo](tablas/cl_ptos_matriz_riesgo.md) *(No se usa en esta versión)*
- [cl_info_trn_riesgo](tablas/cl_info_trn_riesgo.md)
- [ts_negocio_cliente](tablas/ts_negocio_cliente.md)
- [cl_val_iden](tablas/cl_val_iden.md) *(No se usa en esta versión)*
- [cl_scripts](tablas/cl_scripts.md)
- [cl_registro_identificacion](tablas/cl_registro_identificacion.md)
- [cl_registro_cambio](tablas/cl_registro_cambio.md)
- [cl_alertas_riesgo](tablas/cl_alertas_riesgo.md) *(No se usa en esta versión)*
- [cl_analisis_negocio](tablas/cl_analisis_negocio.md)
- [cl_beneficiario_seguro](tablas/cl_beneficiario_seguro.md)
- [cl_control_empresas_rfe](tablas/cl_control_empresas_rfe.md)
- [cl_direccion_fiscal](tablas/cl_direccion_fiscal.md) *(No se usa en esta versión)*
- [cl_documento_actividad](tablas/cl_documento_actividad.md) *(No se usa en esta versión)*
- [cl_documento_digitalizado](tablas/cl_documento_digitalizado.md)
- [cl_documento_parametro](tablas/cl_documento_parametro.md)
- [cl_manejo_sarlaft](tablas/cl_manejo_sarlaft.md) *(No se usa en esta versión)*
- [cl_notificacion_general](tablas/cl_notificacion_general.md)
- [cl_ns_generales_estado](tablas/cl_ns_generales_estado.md) *(No se usa en esta versión)*
- [cl_pais_id_fiscal](tablas/cl_pais_id_fiscal.md)
- [cl_productos_negocio](tablas/cl_productos_negocio.md)
- [cl_seccion_validar](tablas/cl_seccion_validar.md)
- [cl_trabajo](tablas/cl_trabajo.md)
- [cl_ident_ente](tablas/cl_ident_ente.md)
- [cl_ref_telefono](tablas/cl_ref_telefono.md)
- [cl_listas_negras_log](tablas/cl_listas_negras_log.md)
- [cl_listas_negras_rfe](tablas/cl_listas_negras_rfe.md)
- [cl_indice_pob_preg](tablas/cl_indice_pob_preg.md)
- [cl_indice_pob_respuesta](tablas/cl_indice_pob_respuesta.md)
- [cl_ppi_ente](tablas/cl_ppi_ente.md)
- [cl_det_ppi_ente](tablas/cl_det_ppi_ente.md)
- [cl_puntaje_ppi_ente](tablas/cl_puntaje_ppi_ente.md)

### 5.2. Vistas y transacciones de servicios

- [cl_tran_servicio](vistas/cl_tran_servicio.md)

### 5.3. Vistas

- [ts_persona](vistas/ts_persona.md)
- [ts_compania](vistas/ts_compania.md)
- [ts_control_empresas_rfe](vistas/ts_control_empresas_rfe.md)
- [ts_direccion](vistas/ts_direccion.md)
- [ts_direccion_fiscal](vistas/ts_direccion_fiscal.md)
- [ts_direccion_geo](vistas/ts_direccion_geo.md)
- [ts_grupo](vistas/ts_grupo.md)
- [ts_pais_id_fiscal](vistas/ts_pais_id_fiscal.md)
- [ts_analisis_negocio](vistas/ts_analisis_negocio.md)
- [ts_cliente_grupo](vistas/ts_cliente_grupo.md)
- [ts_persona_prin](vistas/ts_persona_prin.md)
- [ts_persona_sec](vistas/ts_persona_sec.md)
- [ts_productos_negocio](vistas/ts_productos_negocio.md)
- [ts_ref_personal](vistas/ts_ref_personal.md)
- [ts_relacion](vistas/ts_relacion.md)
- [ts_instancia](vistas/ts_instancia.md)
- [ts_telefono](vistas/ts_telefono.md)
- [ts_mala_ref](vistas/ts_mala_ref.md)
- [ts_tipo_documento](vistas/ts_tipo_documento.md)
- [ts_cia_liquidacion](vistas/ts_cia_liquidacion.md)
- [ts_adicion_ente](vistas/ts_adicion_ente.md)
- [ts_referencia](vistas/ts_referencia.md)
- [ts_trabajo](vistas/ts_trabajo.md)
- [ts_listas_negras](vistas/ts_listas_negras.md)
- [ts_identificaciones_adicionales](vistas/ts_identificaciones_adicionales.md)
- [ts_telefono_ref](vistas/ts_telefono_ref.md)
- [ts_indice_pob_preg](vistas/ts_indice_pob_preg.md)
- [ts_indice_pob_respuesta](vistas/ts_indice_pob_respuesta.md)
- [ts_ppi_ente](vistas/ts_ppi_ente.md)
- [ts_det_ppi_ente](vistas/ts_det_ppi_ente.md)

---

## 6. Índices

### 6.1. [Índices por Clave Primaria](indices/indices_clave_primaria.md)

### 6.2. [Índices por Clave Foránea](indices/indices_clave_foranea.md)

---

**Nota:** Los archivos marcados con *(No se usa en esta versión)* se mantienen por compatibilidad pero no están activos en la versión actual del sistema.
