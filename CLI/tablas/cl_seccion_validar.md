# cl_seccion_validar

## Descripción
Define las secciones del formulario de cliente que requieren validación o aprobación especial.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| sv_codigo | Int | 4 | NOT NULL | Código de la sección | |
| sv_nombre | Varchar | 64 | NOT NULL | Nombre de la sección | |
| sv_descripcion | descripcion | 254 | NULL | Descripción de la sección | |
| sv_requiere_validacion | Char | 1 | NOT NULL | Requiere validación | S=Sí<br>N=No |
| sv_nivel_aprobacion | catalogo | 10 | NULL | Nivel de aprobación requerido | B=Básico<br>M=Medio<br>A=Alto |
| sv_tipo_ente | Char | 1 | NULL | Tipo de ente aplicable | P=Persona<br>C=Compañía<br>A=Ambos |
| sv_orden | Smallint | 2 | NULL | Orden de presentación | |
| sv_activo | Char | 1 | NULL | Indica si está activa | S=Sí<br>N=No |
| sv_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| sv_usuario | login | 14 | NULL | Usuario que registró | |
| sv_terminal | descripcion | 64 | NULL | Terminal de registro | |
| sv_estado | estado | 1 | NULL | Estado | V=Vigente<br>C=Cancelado |

## Relaciones
No tiene relaciones directas con otras tablas

## Notas
Esta tabla permite configurar qué secciones del formulario de cliente requieren validación adicional.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
