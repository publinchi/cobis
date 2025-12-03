# cl_dadicion_ente

## Descripción
Almacena los valores de los datos adicionales configurados en cl_dato_adicion para cada ente.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| de_ente | Int | 4 | NOT NULL | Código del ente | |
| de_dato_adicional | Int | 4 | NOT NULL | Código del dato adicional | |
| de_valor | Varchar | 254 | NULL | Valor del dato adicional | |
| de_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| de_usuario | login | 14 | NULL | Usuario que registró | |
| de_terminal | descripcion | 64 | NULL | Terminal de registro | |
| de_fecha_modificacion | Datetime | 8 | NULL | Fecha de última modificación | |
| de_usuario_mod | login | 14 | NULL | Usuario que modificó | |

## Relaciones
- Relacionada con cl_ente a través de de_ente
- Relacionada con cl_dato_adicion a través de de_dato_adicional

## Notas
Esta tabla almacena los valores específicos de los campos adicionales configurados para cada cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
