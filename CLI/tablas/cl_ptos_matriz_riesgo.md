# cl_ptos_matriz_riesgo

## Descripción
Almacena los puntajes de la matriz de riesgo para evaluación de clientes

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| pm_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| pm_ente | Int | 4 | NOT NULL | Código del ente | |
| pm_factor | catalogo | 10 | NOT NULL | Factor de riesgo evaluado | |
| pm_puntaje | Decimal | 5,2 | NULL | Puntaje obtenido | |
| pm_peso | Decimal | 5,2 | NULL | Peso del factor | |
| pm_puntaje_ponderado | Decimal | 5,2 | NULL | Puntaje ponderado | |
| pm_fecha_evaluacion | Datetime | 8 | NOT NULL | Fecha de evaluación | |
| pm_usuario | login | 14 | NULL | Usuario que evaluó | |
| pm_terminal | descripcion | 64 | NULL | Terminal de evaluación | |
| pm_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de pm_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
