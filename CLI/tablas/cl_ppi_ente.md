# cl_ppi_ente

## Descripción
Almacena la evaluación del índice de pobreza (PPI) realizada a cada cliente.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| pe_secuencial | Int | 4 | NOT NULL | Secuencial de la evaluación | |
| pe_ente | Int | 4 | NOT NULL | Código del ente | |
| pe_fecha_evaluacion | Datetime | 8 | NOT NULL | Fecha de la evaluación | |
| pe_puntaje_total | Decimal | 5,2 | NULL | Puntaje total obtenido | |
| pe_nivel_pobreza | catalogo | 10 | NULL | Nivel de pobreza calculado | EP=Extrema Pobreza<br>PM=Pobreza Moderada<br>VU=Vulnerable<br>NP=No Pobre |
| pe_probabilidad_pobreza | Decimal | 5,2 | NULL | Probabilidad de estar en pobreza (%) | |
| pe_usuario | login | 14 | NOT NULL | Usuario que realizó la evaluación | |
| pe_terminal | descripcion | 64 | NULL | Terminal de registro | |
| pe_estado | estado | 1 | NULL | Estado de la evaluación | V=Vigente<br>C=Cancelado |
| pe_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de pe_ente
- Relacionada con cl_det_ppi_ente para el detalle de respuestas

## Notas
Esta tabla almacena el resultado consolidado de la evaluación PPI del cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
