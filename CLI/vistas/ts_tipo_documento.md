# ts_tipo_documento

## Descripción
Vista de servicio para consulta de tipos de documentos de identificación.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| td_codigo | catalogo | 10 | NOT NULL | Código del tipo de documento | |
| td_descripcion | descripcion | 64 | NOT NULL | Descripción del tipo de documento | |
| td_mascara | Varchar | 30 | NULL | Máscara de validación | |
| td_longitud | Tinyint | 1 | NULL | Longitud del documento | |
| td_estado | estado | 1 | NULL | Estado del tipo de documento | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| td_tipo_ente | Char | 1 | NULL | Tipo de ente aplicable | P=Persona<br>C=Compañía<br>A=Ambos |
| td_validacion | Char | 1 | NULL | Requiere validación | S=Sí<br>N=No |

## Relaciones
- Vista basada en cl_tipo_documento

## Notas
Esta vista facilita la consulta de tipos de documentos de identificación válidos.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
