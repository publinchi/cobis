# cl_ente_aux

## Descripción
Tabla auxiliar que contiene información complementaria de los entes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ea_ente | Int | 4 | NOT NULL | Código del ente | |
| ea_campo | Varchar | 30 | NOT NULL | Nombre del campo adicional | |
| ea_valor | Varchar | 254 | NULL | Valor del campo | |
| ea_tipo_dato | Char | 1 | NULL | Tipo de dato | C=Carácter<br>N=Numérico<br>F=Fecha<br>M=Monto |
| ea_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| ea_usuario | login | 14 | NULL | Usuario que registró | |
| ea_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ea_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_ente a través de ea_ente

## Notas
Esta tabla permite almacenar información adicional y dinámica de los entes sin modificar la estructura principal.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
