# ts_identificaciones_adicionales

## Descripción
Vista de servicio para consulta de identificaciones adicionales de entes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ie_secuencial | Int | 4 | NOT NULL | Secuencial de la identificación | |
| ie_ente | Int | 4 | NOT NULL | Código del ente | |
| ie_tipo_identificacion | catalogo | 10 | NOT NULL | Tipo de identificación | |
| ie_numero | Varchar | 50 | NOT NULL | Número de identificación | |
| ie_pais_emision | catalogo | 10 | NULL | País de emisión | |
| ie_fecha_emision | Datetime | 8 | NULL | Fecha de emisión | |
| ie_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |
| ie_principal | Char | 1 | NULL | Indica si es identificación principal | S=Sí<br>N=No |
| ie_estado | estado | 1 | NULL | Estado de la identificación | V=Vigente<br>C=Cancelado<br>E=Expirado |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |
| descripcion_tipo | descripcion | 64 | NULL | Descripción del tipo de identificación | |

## Relaciones
- Vista basada en cl_ident_ente con joins a cl_ente y cl_tipo_identificacion

## Notas
Esta vista facilita la consulta de múltiples identificaciones por cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
