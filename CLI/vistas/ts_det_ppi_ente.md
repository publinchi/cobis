# ts_det_ppi_ente

## Descripción
Vista de servicio para consulta del detalle de respuestas en evaluaciones PPI.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| dp_secuencial | Int | 4 | NOT NULL | Secuencial del detalle | |
| dp_evaluacion | Int | 4 | NOT NULL | Código de la evaluación | |
| dp_pregunta | Int | 4 | NOT NULL | Código de la pregunta | |
| dp_respuesta | Int | 4 | NOT NULL | Código de la respuesta seleccionada | |
| dp_puntaje | Decimal | 5,2 | NOT NULL | Puntaje obtenido en esta pregunta | |
| texto_pregunta | descripcion | 254 | NULL | Texto de la pregunta | |
| texto_respuesta | descripcion | 254 | NULL | Texto de la respuesta | |
| pe_ente | Int | 4 | NULL | Código del ente evaluado | |

## Relaciones
- Vista basada en cl_det_ppi_ente con joins a cl_ppi_ente, cl_indice_pob_preg y cl_indice_pob_respuesta

## Notas
Esta vista facilita la consulta del detalle de respuestas en evaluaciones PPI.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
