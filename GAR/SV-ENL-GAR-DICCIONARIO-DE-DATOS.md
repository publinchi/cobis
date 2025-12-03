# COBIS GARANTÍAS - DICCIONARIO DE DATOS

## Tabla de Contenido

1. [Introducción](#introducción)
2. [Diccionario de Datos](#diccionario-de-datos)
   - [Tablas cob_custodia](#tablas-cob_custodia)
   - [Tablas de Transacciones de servicio](#tablas-de-transacciones-de-servicio)
   - [Índices por Clave Primaria](#indices-por-clave-primaria)
   - [Índices por Clave Foránea](#indices-por-clave-foranea)

## Introducción

En este diccionario se encuentran enumeradas las tablas que componen el módulo junto con una pequeña descripción de su uso, también se muestran los campos que tiene cada tabla y se describe su uso.

## Diccionario de Datos

### Tablas cob_custodia

A continuación se muestra el diccionario de datos de este módulo:

- [cu_almacenera](./tablas/cu_almacenera.md)
- [cu_cambios_estado](./tablas/cu_cambios_estado.md)
- [cu_cliente_garantia](./tablas/cu_cliente_garantia.md)
- [cu_cliente_garantia_tmp](./tablas/cu_cliente_garantia_tmp.md)
- [cu_control_inspector](./tablas/cu_control_inspector.md)
- [cu_custodia](./tablas/cu_custodia.md)
- [cu_det_trn](./tablas/cu_det_trn.md)
- [cu_errorlog](./tablas/cu_errorlog.md)
- [cu_estados_garantia](./tablas/cu_estados_garantia.md)
- [cu_garantia_operacion](./tablas/cu_garantia_operacion.md)
- [cu_gastos](./tablas/cu_gastos.md)
- [cu_inspeccion](./tablas/cu_inspeccion.md)
- [cu_inspector](./tablas/cu_inspector.md)
- [cu_inst_operativa](./tablas/cu_inst_operativa.md)
- [cu_item](./tablas/cu_item.md)
- [cu_item_custodia](./tablas/cu_item_custodia.md)
- [cu_mig_custodia](./tablas/cu_mig_custodia.md)
- [cu_poliza](./tablas/cu_poliza.md)
- [cu_por_inspeccionar](./tablas/cu_por_inspeccionar.md)
- [cu_recuperacion](./tablas/cu_recuperacion.md)
- [cu_secuenciales](./tablas/cu_secuenciales.md)
- [cu_seqnos](./tablas/cu_seqnos.md)
- [cu_tipo_custodia](./tablas/cu_tipo_custodia.md)
- [cu_tran_conta](./tablas/cu_tran_conta.md)
- [cu_tran_cust](./tablas/cu_tran_cust.md)
- [cu_transaccion](./tablas/cu_transaccion.md)
- [cu_vencimiento](./tablas/cu_vencimiento.md)

### Tablas de Transacciones de servicio

- [cu_tran_servicio](./tablas/cu_tran_servicio.md)

### INDICES POR CLAVE PRIMARIA

Descripción de los índices por clave primaria definidos para las tablas del sistema Garantías.

Para más detalles, consulte la [documentación completa de índices por clave primaria](./indices/indices-clave-primaria.md).

| **No** | **Índice** | **Tabla** | **Columnas Combinadas** |
| --- | --- | --- | --- |
| 1 | cu_almacenera_Key | cu_almacenera | al_almacenera |
| 2 | cu_cliente_garantia_Key | cu_cliente_garantia | cg_codigo_externo<br>cg_ente |
| 3 | cu_control_inspector_Key | cu_control_inspector | ci_inspector<br>ci_fenvio_carta |
| 4 | cu_custodia_Key | cu_custodia | cu_codigo_externo |
| 5 | cu_gastos_Key | cu_gastos | ga_codigo_externo<br>ga_gastos |
| 6 | cu_inspeccion_Key | cu_inspeccion | in_codigo_externo<br>in_fecha_insp |
| 7 | cu_inspector_Key | cu_inspector | is_inspector |
| 8 | cu_instruccion_Key | cu_inst_operativa | io_codigo_externo<br>io_numero |
| 9 | cu_item_custodia_Key | cu_item_custodia | ic_codigo_externo<br>ic_secuencial<br>ic_item |
| 10 | cu_item_Key | cu_item | it_tipo_custodia<br>it_item |
| 11 | cu_mig_custodia_Key | cu_mig_custodia | mc_garante<br>mc_ente<br>mc_operacion |
| 12 | cu_poliza_Key | cu_poliza | po_aseguradora<br>po_poliza<br>po_codigo_externo |
| 13 | cu_por_inspeccionar_Key | cu_por_inspeccionar | pi_codigo_externo<br>pi_fecha_insp |
| 14 | cu_recuperacion_Key | cu_recuperacion | re_codigo_externo<br>re_vencimiento |
| 15 | cu_tipo_custodia_Key | cu_tipo_custodia | tc_tipo |
| 16 | cu_conta_Key | cu_tran_conta | to_secuencial |
| 17 | cu_transaccion_Key | cu_transaccion | tr_codigo_externo<br>tr_transaccion |
| 18 | cu_vencimiento_Key | cu_vencimiento | ve_codigo_externo<br>ve_vencimiento |

### INDICES POR CLAVE FORANEA

Descripción de los índices por clave foránea definidos para las tablas del sistema Garantías.

Para más detalles, consulte la [documentación completa de índices por clave foránea](./indices/indices-clave-foranea.md).

| **No** | **Índice** | **Tabla** | **Columnas Combinadas** |
| --- | --- | --- | --- |
| 1 | cu_gar_operacion_Key | cu_garantia_operacion | go_codigo_externo<br>go_operacion |
| 2 | cu_poliza_key2 | cu_poliza | po_fvigencia_fin |
| 3 | ipo_codigo_externo | cu_poliza | po_codigo_externo |
| 4 | i_cu_cliente_i2 | cu_cliente_garantia | cg_ente<br>cg_oficial |
| 5 | i_cu_cliente_i3 | cu_cliente_garantia | cg_oficial |
| 6 | i_cu_custodia_i2 | cu_custodia | cu_filial<br>cu_sucursal<br>cu_tipo<br>cu_custodia |
| 7 | i_cu_custodia_i3 | cu_custodia | cu_tipo |
| 8 | i_cu_custodia_i4 | cu_custodia | cu_garante |
| 9 | cu_errorlog_1 | cu_errorlog | er_fecha_proc |
| 10 | i_cu_det_trn | cu_det_trn | dtr_codigo_externo |
| 11 | i_cu_inspeccion_i2 | cu_inspeccion | in_filial<br>in_sucursal<br>in_tipo_cust<br>in_custodia |
| 12 | cu_recuperacion_1 | cu_recuperacion | re_codigo_externo<br>re_vencimiento |
| 13 | cu_transaccion_i2 | cu_transaccion | tr_filial<br>tr_fecha_tran |
| 14 | cu_vencimiento_1 | cu_vencimiento | ve_deudor |
| 15 | cu_vencimiento_2 | cu_vencimiento | ve_filial<br>ve_sucursal<br>ve_tipo_cust<br>ve_custodia |
| 16 | cu_vencimiento_3 | cu_vencimiento | ve_cta_debito |
