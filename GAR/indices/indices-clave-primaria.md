# ÍNDICES POR CLAVE PRIMARIA

## Descripción

Los índices por clave primaria garantizan la unicidad de los registros en cada tabla del sistema de Garantías. Estos índices se crean automáticamente sobre las columnas que conforman la clave primaria de cada tabla.

## Características

- **Unicidad**: Garantizan que no existan registros duplicados
- **Rendimiento**: Optimizan las búsquedas por clave primaria
- **Integridad**: Aseguran la integridad referencial del sistema

## Listado de Índices

| **No** | **Índice** | **Tabla** | **Columnas Combinadas** | **Descripción** |
| --- | --- | --- | --- | --- |
| 1 | cu_almacenera_Key | [cu_almacenera](../tablas/cu_almacenera.md) | al_almacenera | Identifica únicamente cada almacenera |
| 2 | cu_cliente_garantia_Key | [cu_cliente_garantia](../tablas/cu_cliente_garantia.md) | cg_codigo_externo<br>cg_ente | Identifica la relación cliente-garantía |
| 3 | cu_control_inspector_Key | [cu_control_inspector](../tablas/cu_control_inspector.md) | ci_inspector<br>ci_fenvio_carta | Control de inspectores por fecha de envío |
| 4 | cu_custodia_Key | [cu_custodia](../tablas/cu_custodia.md) | cu_codigo_externo | Identificador único de cada garantía |
| 5 | cu_gastos_Key | [cu_gastos](../tablas/cu_gastos.md) | ga_codigo_externo<br>ga_gastos | Identifica gastos por garantía |
| 6 | cu_inspeccion_Key | [cu_inspeccion](../tablas/cu_inspeccion.md) | in_codigo_externo<br>in_fecha_insp | Identifica inspecciones por fecha |
| 7 | cu_inspector_Key | [cu_inspector](../tablas/cu_inspector.md) | is_inspector | Identificador único de inspector |
| 8 | cu_instruccion_Key | [cu_inst_operativa](../tablas/cu_inst_operativa.md) | io_codigo_externo<br>io_numero | Identifica instrucciones operativas |
| 9 | cu_item_custodia_Key | [cu_item_custodia](../tablas/cu_item_custodia.md) | ic_codigo_externo<br>ic_secuencial<br>ic_item | Identifica ítems de cada garantía |
| 10 | cu_item_Key | [cu_item](../tablas/cu_item.md) | it_tipo_custodia<br>it_item | Identifica ítems por tipo de custodia |
| 11 | cu_mig_custodia_Key | [cu_mig_custodia](../tablas/cu_mig_custodia.md) | mc_garante<br>mc_ente<br>mc_operacion | Control de migración de garantías |
| 12 | cu_poliza_Key | [cu_poliza](../tablas/cu_poliza.md) | po_aseguradora<br>po_poliza<br>po_codigo_externo | Identifica pólizas de seguro |
| 13 | cu_por_inspeccionar_Key | [cu_por_inspeccionar](../tablas/cu_por_inspeccionar.md) | pi_codigo_externo<br>pi_fecha_insp | Control de garantías pendientes de inspección |
| 14 | cu_recuperacion_Key | [cu_recuperacion](../tablas/cu_recuperacion.md) | re_codigo_externo<br>re_vencimiento | Identifica recuperaciones por vencimiento |
| 15 | cu_tipo_custodia_Key | [cu_tipo_custodia](../tablas/cu_tipo_custodia.md) | tc_tipo | Identificador único de tipo de garantía |
| 16 | cu_conta_Key | [cu_tran_conta](../tablas/cu_tran_conta.md) | to_secuencial | Identificador de transacción contable |
| 17 | cu_transaccion_Key | [cu_transaccion](../tablas/cu_transaccion.md) | tr_codigo_externo<br>tr_transaccion | Identifica transacciones por garantía |
| 18 | cu_vencimiento_Key | [cu_vencimiento](../tablas/cu_vencimiento.md) | ve_codigo_externo<br>ve_vencimiento | Identifica vencimientos de garantías |

## Consideraciones Técnicas

1. **Nomenclatura**: Todos los índices de clave primaria siguen el patrón `[tabla]_Key`
2. **Obligatoriedad**: Las columnas que conforman la clave primaria son siempre NOT NULL
3. **Claves Compuestas**: Varias tablas utilizan claves primarias compuestas por múltiples columnas
4. **Código Externo**: Muchas tablas utilizan `codigo_externo` como parte de su clave primaria para facilitar la integración

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
