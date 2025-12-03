# cl_documento_parametro

## Descripción
Define los parámetros y configuraciones de los tipos de documentos que se pueden digitalizar.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| dp_codigo | catalogo | 10 | NOT NULL | Código del tipo de documento | |
| dp_descripcion | descripcion | 254 | NOT NULL | Descripción del documento | |
| dp_obligatorio | Char | 1 | NOT NULL | Indica si es obligatorio | S=Sí<br>N=No |
| dp_tipo_ente | Char | 1 | NULL | Tipo de ente aplicable | P=Persona<br>C=Compañía<br>A=Ambos |
| dp_extensiones_permitidas | Varchar | 100 | NULL | Extensiones de archivo permitidas | |
| dp_tamanio_maximo | Int | 4 | NULL | Tamaño máximo en KB | |
| dp_vigencia_dias | Int | 4 | NULL | Días de vigencia del documento | |
| dp_requiere_validacion | Char | 1 | NULL | Requiere validación | S=Sí<br>N=No |
| dp_categoria | catalogo | 10 | NULL | Categoría del documento | ID=Identificación<br>FI=Financiero<br>LE=Legal<br>OT=Otros |
| dp_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| dp_usuario | login | 14 | NULL | Usuario que registró | |
| dp_terminal | descripcion | 64 | NULL | Terminal de registro | |
| dp_estado | estado | 1 | NULL | Estado | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_documento_digitalizado para los documentos digitalizados

## Notas
Esta tabla define las reglas y parámetros para la digitalización de documentos de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
