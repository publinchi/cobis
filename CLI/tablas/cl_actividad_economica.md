# cl_actividad_economica

## Descripción
Tabla que relaciona las actividades económicas con los entes, permitiendo que un cliente tenga múltiples actividades económicas registradas.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ae_ente | Int | 4 | NOT NULL | Código del ente | |
| ae_secuencial | Tinyint | 1 | NOT NULL | Secuencial de la actividad | |
| ae_actividad | catalogo | 10 | NOT NULL | Código de la actividad económica | |
| ae_tipo | Char | 1 | NULL | Tipo de actividad | P=Principal<br>S=Secundaria |
| ae_fecha_inicio | Datetime | 8 | NULL | Fecha de inicio de la actividad | |
| ae_fecha_fin | Datetime | 8 | NULL | Fecha de fin de la actividad | |
| ae_estado | estado | 1 | NULL | Estado de la actividad | V=Vigente<br>C=Cancelado |
| ae_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| ae_usuario | login | 14 | NULL | Usuario que registró | |
| ae_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ae_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de ae_ente
- Relacionada con cl_actividad_ec a través de ae_actividad

## Notas
Esta tabla permite que un cliente tenga registradas múltiples actividades económicas, identificando cuál es la principal.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
