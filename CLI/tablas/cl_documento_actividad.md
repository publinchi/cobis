# cl_documento_actividad

## Descripción
Relaciona documentos con actividades económicas específicas

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| da_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| da_actividad | catalogo | 10 | NOT NULL | Código de la actividad económica | |
| da_tipo_documento | catalogo | 10 | NOT NULL | Tipo de documento requerido | |
| da_obligatorio | Char | 1 | NOT NULL | Indica si es obligatorio | S=Sí<br>N=No |
| da_descripcion | descripcion | 254 | NULL | Descripción del documento | |
| da_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| da_usuario | login | 14 | NULL | Usuario que registró | |
| da_terminal | descripcion | 64 | NULL | Terminal de registro | |
| da_estado | estado | 1 | NULL | Estado | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_actividad_ec a través de da_actividad

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
