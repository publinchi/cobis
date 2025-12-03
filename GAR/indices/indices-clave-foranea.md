# ÍNDICES POR CLAVE FORÁNEA

## Descripción

Los índices por clave foránea optimizan las consultas que involucran relaciones entre tablas. Estos índices mejoran significativamente el rendimiento de las operaciones JOIN y las búsquedas por campos relacionados.

## Características

- **Rendimiento**: Aceleran las consultas que involucran relaciones entre tablas
- **Integridad Referencial**: Facilitan la validación de relaciones entre registros
- **Optimización de JOIN**: Mejoran el rendimiento de operaciones de unión de tablas

## Listado de Índices

| **No** | **Índice** | **Tabla** | **Columnas Combinadas** | **Descripción** |
| --- | --- | --- | --- | --- |
| 1 | cu_gar_operacion_Key | [cu_garantia_operacion](../tablas/cu_garantia_operacion.md) | go_codigo_externo<br>go_operacion | Relación garantía-operación de cartera |
| 2 | cu_poliza_key2 | [cu_poliza](../tablas/cu_poliza.md) | po_fvigencia_fin | Búsqueda de pólizas por fecha de vencimiento |
| 3 | ipo_codigo_externo | [cu_poliza](../tablas/cu_poliza.md) | po_codigo_externo | Búsqueda de pólizas por código de garantía |
| 4 | i_cu_cliente_i2 | [cu_cliente_garantia](../tablas/cu_cliente_garantia.md) | cg_ente<br>cg_oficial | Búsqueda por cliente y oficial |
| 5 | i_cu_cliente_i3 | [cu_cliente_garantia](../tablas/cu_cliente_garantia.md) | cg_oficial | Búsqueda de garantías por oficial |
| 6 | i_cu_custodia_i2 | [cu_custodia](../tablas/cu_custodia.md) | cu_filial<br>cu_sucursal<br>cu_tipo<br>cu_custodia | Búsqueda por ubicación y tipo |
| 7 | i_cu_custodia_i3 | [cu_custodia](../tablas/cu_custodia.md) | cu_tipo | Búsqueda de garantías por tipo |
| 8 | i_cu_custodia_i4 | [cu_custodia](../tablas/cu_custodia.md) | cu_garante | Búsqueda de garantías por garante |
| 9 | cu_errorlog_1 | [cu_errorlog](../tablas/cu_errorlog.md) | er_fecha_proc | Búsqueda de errores por fecha |
| 10 | i_cu_det_trn | [cu_det_trn](../tablas/cu_det_trn.md) | dtr_codigo_externo | Detalle de transacciones por garantía |
| 11 | i_cu_inspeccion_i2 | [cu_inspeccion](../tablas/cu_inspeccion.md) | in_filial<br>in_sucursal<br>in_tipo_cust<br>in_custodia | Búsqueda de inspecciones por ubicación |
| 12 | cu_recuperacion_1 | [cu_recuperacion](../tablas/cu_recuperacion.md) | re_codigo_externo<br>re_vencimiento | Búsqueda de recuperaciones |
| 13 | cu_transaccion_i2 | [cu_transaccion](../tablas/cu_transaccion.md) | tr_filial<br>tr_fecha_tran | Búsqueda de transacciones por fecha y filial |
| 14 | cu_vencimiento_1 | [cu_vencimiento](../tablas/cu_vencimiento.md) | ve_deudor | Búsqueda de vencimientos por deudor |
| 15 | cu_vencimiento_2 | [cu_vencimiento](../tablas/cu_vencimiento.md) | ve_filial<br>ve_sucursal<br>ve_tipo_cust<br>ve_custodia | Búsqueda de vencimientos por ubicación |
| 16 | cu_vencimiento_3 | [cu_vencimiento](../tablas/cu_vencimiento.md) | ve_cta_debito | Búsqueda de vencimientos por cuenta de débito |

## Relaciones Principales

### Relaciones con cu_custodia (Tabla Maestra)
- **cu_cliente_garantia**: Relaciona clientes con garantías
- **cu_garantia_operacion**: Relaciona garantías con operaciones de cartera
- **cu_inspeccion**: Registra inspecciones de garantías
- **cu_poliza**: Asocia pólizas de seguro a garantías
- **cu_vencimiento**: Registra vencimientos de garantías

### Relaciones Organizacionales
- **Filial/Sucursal**: Múltiples índices permiten búsquedas por estructura organizacional
- **Oficial**: Permite identificar garantías por oficial responsable
- **Cliente/Deudor**: Facilita consultas por cliente o deudor

### Relaciones Temporales
- **Fechas de Transacción**: Optimizan consultas históricas
- **Fechas de Vencimiento**: Facilitan el control de vencimientos
- **Fechas de Vigencia**: Permiten validar vigencia de pólizas

## Consideraciones Técnicas

1. **Nomenclatura Variable**: Los índices de clave foránea no siguen un patrón único de nomenclatura
2. **Índices Compuestos**: Muchos índices combinan múltiples columnas para optimizar consultas específicas
3. **Rendimiento**: Estos índices son críticos para el rendimiento del sistema en operaciones de consulta
4. **Mantenimiento**: Deben mantenerse actualizados para garantizar el rendimiento óptimo

## Recomendaciones de Uso

- Utilizar estos índices en las cláusulas WHERE de las consultas
- Considerar el orden de las columnas en índices compuestos al escribir consultas
- Monitorear el uso de índices para identificar oportunidades de optimización
- Evitar la creación de índices redundantes que puedan afectar el rendimiento de escritura

[Volver al índice principal](../SV-ENL-GAR-DICCIONARIO-DE-DATOS.md)
