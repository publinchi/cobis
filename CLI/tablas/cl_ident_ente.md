# cl_ident_ente

## Descripción
Almacena identificaciones adicionales de los entes, permitiendo múltiples documentos de identificación por cliente.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ie_secuencial | Int | 4 | NOT NULL | Secuencial de la identificación | |
| ie_ente | Int | 4 | NOT NULL | Código del ente | |
| ie_tipo_identificacion | catalogo | 10 | NOT NULL | Tipo de identificación | |
| ie_numero | Varchar | 50 | NOT NULL | Número de identificación | |
| ie_pais_emision | catalogo | 10 | NULL | País de emisión | |
| ie_fecha_emision | Datetime | 8 | NULL | Fecha de emisión | |
| ie_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |
| ie_lugar_emision | descripcion | 64 | NULL | Lugar de emisión | |
| ie_principal | Char | 1 | NULL | Indica si es identificación principal | S=Sí<br>N=No |
| ie_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| ie_usuario | login | 14 | NULL | Usuario que registró | |
| ie_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ie_estado | estado | 1 | NULL | Estado de la identificación | V=Vigente<br>C=Cancelado<br>E=Expirado |
| ie_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de ie_ente
- Relacionada con cl_tipo_identificacion a través de ie_tipo_identificacion

## Notas
Esta tabla permite que un cliente tenga múltiples documentos de identificación registrados.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
