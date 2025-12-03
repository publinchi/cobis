# cl_mercado

## Descripción
Guarda información de mercados o segmentos de clientes

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| me_codigo | Int | 4 | NOT NULL | Código del mercado | |
| me_descripcion | descripcion | 64 | NULL | Descripción del mercado | |
| me_estado | estado | 1 | NULL | Estado del mercado | V=Vigente<br>C=Cancelado<br>E=Eliminado |
| me_fecha_crea | Datetime | 8 | NULL | Fecha de creación | |
| me_usuario | login | 14 | NULL | Usuario que creó el registro | |
| me_terminal | descripcion | 64 | NULL | Terminal de creación | |

## Relaciones
No aplica

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
