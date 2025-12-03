# ts_telefono

## Descripción
Vista de servicio para consulta de teléfonos de clientes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| te_ente | Int | 4 | NOT NULL | Código del ente | |
| te_secuencial | Tinyint | 1 | NOT NULL | Secuencial del teléfono | |
| te_tipo_telefono | catalogo | 10 | NULL | Tipo de teléfono | C=Casa<br>O=Oficina<br>M=Móvil<br>F=Fax |
| te_valor | telefono | 16 | NULL | Número telefónico | |
| te_extension | Smallint | 2 | NULL | Extensión telefónica | |
| te_principal | Char | 1 | NULL | Indica si es teléfono principal | S=Sí<br>N=No |
| te_estado | estado | 1 | NULL | Estado del teléfono | V=Vigente<br>C=Cancelado |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |

## Relaciones
- Vista basada en cl_telefono con join a cl_ente

## Notas
Esta vista facilita la consulta de teléfonos de clientes con información del ente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
