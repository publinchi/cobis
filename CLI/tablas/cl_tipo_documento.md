# cl_tipo_documento

## Descripción
Contiene el catálogo de tipos de documentos de identificación válidos en el sistema.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| td_codigo | catalogo | 10 | NOT NULL | Código del tipo de documento | |
| td_descripcion | descripcion | 64 | NOT NULL | Descripción del tipo de documento | |
| td_mascara | Varchar | 30 | NULL | Máscara de validación | |
| td_longitud | Tinyint | 1 | NULL | Longitud del documento | |
| td_estado | estado | 1 | NULL | Estado del tipo de documento | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| td_tipo_ente | Char | 1 | NULL | Tipo de ente aplicable | P=Persona<br>C=Compañía<br>A=Ambos |
| td_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| td_usuario | login | 14 | NULL | Usuario que creó | |
| td_terminal | descripcion | 64 | NULL | Terminal de creación | |
| td_validacion | Char | 1 | NULL | Requiere validación | S=Sí<br>N=No |

## Relaciones
No tiene relaciones directas con otras tablas

## Notas
Esta tabla define los tipos de documentos de identificación aceptados (cédula, RUC, pasaporte, etc.).

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
