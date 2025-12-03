# cl_puntaje_ppi_ente

## Descripción
Almacena el historial de puntajes PPI del cliente para análisis de evolución socioeconómica.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| pp_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| pp_ente | Int | 4 | NOT NULL | Código del ente | |
| pp_evaluacion | Int | 4 | NOT NULL | Código de la evaluación | |
| pp_fecha | Datetime | 8 | NOT NULL | Fecha del puntaje | |
| pp_puntaje | Decimal | 5,2 | NOT NULL | Puntaje obtenido | |
| pp_nivel_anterior | catalogo | 10 | NULL | Nivel de pobreza anterior | |
| pp_nivel_actual | catalogo | 10 | NOT NULL | Nivel de pobreza actual | EP=Extrema Pobreza<br>PM=Pobreza Moderada<br>VU=Vulnerable<br>NP=No Pobre |
| pp_variacion | Decimal | 5,2 | NULL | Variación respecto a evaluación anterior | |
| pp_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de pp_ente
- Relacionada con cl_ppi_ente a través de pp_evaluacion

## Notas
Esta tabla permite hacer seguimiento de la evolución del índice de pobreza del cliente a lo largo del tiempo.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
