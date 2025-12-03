# cl_scripts

## Descripción
Almacena scripts o guiones para procesos automatizados del módulo de clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| sc_codigo | Int | 4 | NOT NULL | Código del script | |
| sc_nombre | descripcion | 64 | NOT NULL | Nombre del script | |
| sc_descripcion | descripcion | 254 | NULL | Descripción del script | |
| sc_tipo | catalogo | 10 | NULL | Tipo de script | V=Validación<br>P=Proceso<br>C=Cálculo<br>R=Reporte |
| sc_contenido | Text | - | NULL | Contenido del script | |
| sc_lenguaje | Varchar | 20 | NULL | Lenguaje del script | SQL=SQL<br>JS=JavaScript<br>PY=Python |
| sc_activo | Char | 1 | NULL | Indica si está activo | S=Sí<br>N=No |
| sc_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| sc_usuario_crea | login | 14 | NULL | Usuario que creó | |
| sc_fecha_mod | Datetime | 8 | NULL | Fecha de modificación | |
| sc_usuario_mod | login | 14 | NULL | Usuario que modificó | |
| sc_terminal | descripcion | 64 | NULL | Terminal de creación | |
| sc_estado | estado | 1 | NULL | Estado del script | V=Vigente<br>C=Cancelado<br>E=Eliminado |

## Relaciones
No tiene relaciones directas con otras tablas

## Notas
Esta tabla permite almacenar scripts personalizados para automatización de procesos.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
