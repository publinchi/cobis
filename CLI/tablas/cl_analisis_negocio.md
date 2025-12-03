# cl_analisis_negocio

## Descripción
Contiene información del análisis de negocio realizado a los clientes para evaluación crediticia.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| an_secuencial | Int | 4 | NOT NULL | Secuencial del análisis | |
| an_ente | Int | 4 | NOT NULL | Código del ente | |
| an_fecha_analisis | Datetime | 8 | NOT NULL | Fecha del análisis | |
| an_tipo_negocio | catalogo | 10 | NULL | Tipo de negocio | CO=Comercio<br>SE=Servicios<br>PR=Producción<br>AG=Agrícola<br>OT=Otros |
| an_antiguedad_negocio | Int | 4 | NULL | Antigüedad del negocio en meses | |
| an_num_empleados | Int | 4 | NULL | Número de empleados | |
| an_ventas_promedio | money | 8 | NULL | Ventas promedio mensuales | |
| an_costos_promedio | money | 8 | NULL | Costos promedio mensuales | |
| an_utilidad_promedio | money | 8 | NULL | Utilidad promedio mensual | |
| an_inventario_promedio | money | 8 | NULL | Inventario promedio | |
| an_cuentas_cobrar | money | 8 | NULL | Cuentas por cobrar | |
| an_cuentas_pagar | money | 8 | NULL | Cuentas por pagar | |
| an_activos_fijos | money | 8 | NULL | Activos fijos | |
| an_pasivos_financieros | money | 8 | NULL | Pasivos financieros | |
| an_capacidad_pago | money | 8 | NULL | Capacidad de pago calculada | |
| an_observaciones | descripcion | 254 | NULL | Observaciones del análisis | |
| an_usuario | login | 14 | NULL | Usuario que realizó el análisis | |
| an_terminal | descripcion | 64 | NULL | Terminal de registro | |
| an_estado | estado | 1 | NULL | Estado del análisis | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_ente a través de an_ente

## Notas
Esta tabla almacena análisis detallados del negocio del cliente para evaluación de capacidad de pago.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
