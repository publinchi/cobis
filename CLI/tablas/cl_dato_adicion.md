# cl_dato_adicion

## Descripción
Define los campos adicionales configurables que se pueden asociar a los entes para capturar información específica no contemplada en las tablas estándar.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| da_codigo | Int | 4 | NOT NULL | Código del dato adicional | |
| da_nombre | Varchar | 64 | NOT NULL | Nombre del campo adicional | |
| da_descripcion | descripcion | 254 | NULL | Descripción del campo | |
| da_tipo_dato | Char | 1 | NOT NULL | Tipo de dato | C=Carácter<br>N=Numérico<br>F=Fecha<br>M=Monto<br>L=Lógico |
| da_longitud | Smallint | 2 | NULL | Longitud del campo | |
| da_obligatorio | Char | 1 | NULL | Indica si es obligatorio | S=Sí<br>N=No |
| da_tipo_ente | Char | 1 | NULL | Tipo de ente aplicable | P=Persona<br>C=Compañía<br>A=Ambos |
| da_catalogo | Varchar | 30 | NULL | Catálogo asociado si aplica | |
| da_estado | estado | 1 | NULL | Estado del campo | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| da_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| da_usuario | login | 14 | NULL | Usuario que creó | |
| da_terminal | descripcion | 64 | NULL | Terminal de creación | |
| da_orden | Smallint | 2 | NULL | Orden de presentación | |

## Relaciones
- Relacionada con cl_dadicion_ente para los valores de estos campos

## Notas
Esta tabla permite configurar campos adicionales dinámicos para capturar información específica de cada institución.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
