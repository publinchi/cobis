# cl_det_ppi_ente

## Descripción
Contiene el detalle de las respuestas dadas por el cliente en la evaluación del índice de pobreza (PPI).

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| dp_secuencial | Int | 4 | NOT NULL | Secuencial del detalle | |
| dp_evaluacion | Int | 4 | NOT NULL | Código de la evaluación | |
| dp_pregunta | Int | 4 | NOT NULL | Código de la pregunta | |
| dp_respuesta | Int | 4 | NOT NULL | Código de la respuesta seleccionada | |
| dp_puntaje | Decimal | 5,2 | NOT NULL | Puntaje obtenido en esta pregunta | |
| dp_observacion | descripcion | 254 | NULL | Observaciones sobre la respuesta | |

## Relaciones
- Relacionada con cl_ppi_ente a través de dp_evaluacion
- Relacionada con cl_indice_pob_preg a través de dp_pregunta
- Relacionada con cl_indice_pob_respuesta a través de dp_respuesta

## Notas
Esta tabla almacena el detalle de cada respuesta dada en la evaluación PPI.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
