# cl_alertas_riesgo

## Descripción
Almacena alertas de riesgo generadas para los clientes

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ar_secuencial | Int | 4 | NOT NULL | Secuencial de la alerta | |
| ar_ente | Int | 4 | NOT NULL | Código del ente | |
| ar_tipo_alerta | catalogo | 10 | NOT NULL | Tipo de alerta | TR=Transaccional<br>CO=Comportamiento<br>LI=Listas<br>OT=Otros |
| ar_nivel | catalogo | 10 | NOT NULL | Nivel de la alerta | A=Alto<br>M=Medio<br>B=Bajo |
| ar_descripcion | descripcion | 254 | NOT NULL | Descripción de la alerta | |
| ar_fecha_generacion | Datetime | 8 | NOT NULL | Fecha de generación | |
| ar_estado | estado | 1 | NOT NULL | Estado de la alerta | P=Pendiente<br>R=Revisada<br>C=Cerrada<br>F=Falsa |
| ar_fecha_revision | Datetime | 8 | NULL | Fecha de revisión | |
| ar_usuario_revision | login | 14 | NULL | Usuario que revisó | |
| ar_observacion | descripcion | 254 | NULL | Observaciones | |
| ar_accion_tomada | descripcion | 254 | NULL | Acción tomada | |

## Relaciones
- Relacionada con cl_ente a través de ar_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
