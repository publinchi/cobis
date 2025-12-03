# cl_infocred_central

## Descripción
Almacena información crediticia de centrales de riesgo

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ic_ente | Int | 4 | NOT NULL | Código del ente | |
| ic_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| ic_central | catalogo | 10 | NULL | Código de la central de riesgo | |
| ic_fecha_consulta | Datetime | 8 | NOT NULL | Fecha de consulta | |
| ic_calificacion | catalogo | 10 | NULL | Calificación crediticia | |
| ic_score | Int | 4 | NULL | Puntaje de score | |
| ic_monto_deuda | money | 8 | NULL | Monto de deuda reportado | |
| ic_num_operaciones | Int | 4 | NULL | Número de operaciones | |
| ic_usuario | login | 14 | NULL | Usuario que consultó | |
| ic_terminal | descripcion | 64 | NULL | Terminal de consulta | |
| ic_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de ic_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
