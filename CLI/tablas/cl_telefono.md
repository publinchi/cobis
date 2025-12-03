# cl_telefono

## Descripción
Contiene los números telefónicos de los clientes (entes) registrados en el sistema.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| te_ente | Int | 4 | NOT NULL | Código del ente | |
| te_secuencial | Tinyint | 1 | NOT NULL | Secuencial del teléfono | |
| te_tipo_telefono | catalogo | 10 | NULL | Tipo de teléfono | C=Casa<br>O=Oficina<br>M=Móvil<br>F=Fax |
| te_valor | telefono | 16 | NULL | Número telefónico | |
| te_extension | Smallint | 2 | NULL | Extensión telefónica | |
| te_principal | Char | 1 | NULL | Indica si es teléfono principal | S=Sí<br>N=No |
| te_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| te_usuario | login | 14 | NULL | Usuario que registró | |
| te_terminal | descripcion | 64 | NULL | Terminal de registro | |
| te_estado | estado | 1 | NULL | Estado del teléfono | V=Vigente<br>C=Cancelado |
| te_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de te_ente

## Notas
Esta tabla permite almacenar múltiples números telefónicos por cliente, clasificados por tipo.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
