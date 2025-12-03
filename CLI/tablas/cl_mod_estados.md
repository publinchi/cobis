# cl_mod_estados

## Descripción
Guarda información de estados de modificación de datos

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| me_ente | Int | 4 | NOT NULL | Código del ente | |
| me_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| me_tabla | descripcion | 64 | NULL | Nombre de la tabla modificada | |
| me_campo | descripcion | 64 | NULL | Campo modificado | |
| me_valor_anterior | descripcion | 254 | NULL | Valor anterior | |
| me_valor_nuevo | descripcion | 254 | NULL | Valor nuevo | |
| me_fecha | Datetime | 8 | NULL | Fecha de modificación | |
| me_usuario | login | 14 | NULL | Usuario que modificó | |
| me_terminal | descripcion | 64 | NULL | Terminal de modificación | |
| me_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_ente a través de me_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
