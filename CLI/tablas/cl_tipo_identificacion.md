# cl_tipo_identificacion

## Descripción
Catálogo de tipos de identificación válidos en el sistema, complementario a cl_tipo_documento.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ti_codigo | catalogo | 10 | NOT NULL | Código del tipo de identificación | |
| ti_descripcion | descripcion | 64 | NOT NULL | Descripción del tipo | |
| ti_abreviatura | Varchar | 10 | NULL | Abreviatura | |
| ti_mascara | Varchar | 30 | NULL | Máscara de validación | |
| ti_longitud_min | Tinyint | 1 | NULL | Longitud mínima | |
| ti_longitud_max | Tinyint | 1 | NULL | Longitud máxima | |
| ti_tipo_ente | Char | 1 | NULL | Tipo de ente aplicable | P=Persona<br>C=Compañía<br>A=Ambos |
| ti_pais | catalogo | 10 | NULL | País emisor | |
| ti_requiere_validacion | Char | 1 | NULL | Requiere validación | S=Sí<br>N=No |
| ti_estado | estado | 1 | NULL | Estado | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| ti_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| ti_usuario | login | 14 | NULL | Usuario que creó | |
| ti_terminal | descripcion | 64 | NULL | Terminal de creación | |

## Relaciones
No tiene relaciones directas con otras tablas

## Notas
Esta tabla complementa cl_tipo_documento con información adicional de validación.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
