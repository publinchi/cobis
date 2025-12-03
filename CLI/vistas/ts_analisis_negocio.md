# ts_analisis_negocio

## Descripción
Vista de servicio para consulta de análisis de negocios de clientes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| an_secuencial | Int | 4 | NOT NULL | Secuencial del análisis | |
| an_ente | Int | 4 | NOT NULL | Código del ente | |
| an_fecha_analisis | Datetime | 8 | NOT NULL | Fecha del análisis | |
| an_tipo_negocio | catalogo | 10 | NULL | Tipo de negocio | CO=Comercio<br>SE=Servicios<br>PR=Producción<br>AG=Agrícola<br>OT=Otros |
| an_antiguedad_negocio | Int | 4 | NULL | Antigüedad del negocio en meses | |
| an_num_empleados | Int | 4 | NULL | Número de empleados | |
| an_ventas_promedio | money | 8 | NULL | Ventas promedio mensuales | |
| an_utilidad_promedio | money | 8 | NULL | Utilidad promedio mensual | |
| an_capacidad_pago | money | 8 | NULL | Capacidad de pago calculada | |
| an_estado | estado | 1 | NULL | Estado del análisis | V=Vigente<br>C=Cancelado |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |

## Relaciones
- Vista basada en cl_analisis_negocio con join a cl_ente

## Notas
Esta vista facilita la consulta de análisis de negocios para evaluación crediticia.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
