# ts_telefono_ref

## Descripción
Vista de servicio para consulta de teléfonos de referencias personales.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| rt_ente | Int | 4 | NOT NULL | Código del ente | |
| rt_referencia | Tinyint | 1 | NOT NULL | Secuencial de la referencia | |
| rt_secuencial | Tinyint | 1 | NOT NULL | Secuencial del teléfono | |
| rt_tipo_telefono | catalogo | 10 | NULL | Tipo de teléfono | C=Casa<br>O=Oficina<br>M=Móvil |
| rt_numero | telefono | 16 | NULL | Número telefónico | |
| rt_extension | Smallint | 2 | NULL | Extensión telefónica | |
| rt_principal | Char | 1 | NULL | Indica si es teléfono principal | S=Sí<br>N=No |
| rt_estado | estado | 1 | NULL | Estado del teléfono | V=Vigente<br>C=Cancelado |
| nombre_referencia | descripcion | 64 | NULL | Nombre de la referencia | |

## Relaciones
- Vista basada en cl_ref_telefono con join a cl_ref_personal

## Notas
Esta vista facilita la consulta de teléfonos de referencias personales.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
