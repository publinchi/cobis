# ts_ppi_ente

## Descripción
Vista de servicio para consulta de evaluaciones PPI de clientes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| pe_secuencial | Int | 4 | NOT NULL | Secuencial de la evaluación | |
| pe_ente | Int | 4 | NOT NULL | Código del ente | |
| pe_fecha_evaluacion | Datetime | 8 | NOT NULL | Fecha de la evaluación | |
| pe_puntaje_total | Decimal | 5,2 | NULL | Puntaje total obtenido | |
| pe_nivel_pobreza | catalogo | 10 | NULL | Nivel de pobreza calculado | EP=Extrema Pobreza<br>PM=Pobreza Moderada<br>VU=Vulnerable<br>NP=No Pobre |
| pe_probabilidad_pobreza | Decimal | 5,2 | NULL | Probabilidad de estar en pobreza (%) | |
| pe_usuario | login | 14 | NOT NULL | Usuario que realizó la evaluación | |
| pe_estado | estado | 1 | NULL | Estado de la evaluación | V=Vigente<br>C=Cancelado |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |

## Relaciones
- Vista basada en cl_ppi_ente con join a cl_ente

## Notas
Esta vista facilita la consulta de evaluaciones PPI de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
