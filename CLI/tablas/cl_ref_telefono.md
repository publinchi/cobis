# cl_ref_telefono

## Descripción
Contiene los números telefónicos de las referencias personales de los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| rt_ente | Int | 4 | NOT NULL | Código del ente | |
| rt_referencia | Tinyint | 1 | NOT NULL | Secuencial de la referencia | |
| rt_secuencial | Tinyint | 1 | NOT NULL | Secuencial del teléfono | |
| rt_tipo_telefono | catalogo | 10 | NULL | Tipo de teléfono | C=Casa<br>O=Oficina<br>M=Móvil |
| rt_numero | telefono | 16 | NULL | Número telefónico | |
| rt_extension | Smallint | 2 | NULL | Extensión telefónica | |
| rt_principal | Char | 1 | NULL | Indica si es teléfono principal | S=Sí<br>N=No |
| rt_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| rt_usuario | login | 14 | NULL | Usuario que registró | |
| rt_terminal | descripcion | 64 | NULL | Terminal de registro | |
| rt_estado | estado | 1 | NULL | Estado del teléfono | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_ente a través de rt_ente
- Relacionada con cl_ref_personal a través de rt_ente y rt_referencia

## Notas
Esta tabla permite almacenar múltiples teléfonos para cada referencia personal del cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
