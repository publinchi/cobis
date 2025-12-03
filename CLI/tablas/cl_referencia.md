# cl_referencia

## Descripción
Guarda información de referencias bancarias y comerciales

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| re_ente | Int | 4 | NOT NULL | Código del ente | |
| re_secuencial | Tinyint | 1 | NOT NULL | Secuencial de la referencia | |
| re_tipo | Char | 1 | NULL | Tipo de referencia | B=Bancaria<br>C=Comercial |
| re_institucion | descripcion | 64 | NULL | Nombre de la institución | |
| re_ciudad | Int | 4 | NULL | Código de la ciudad | |
| re_telefono | telefono | 16 | NULL | Teléfono de contacto | |
| re_contacto | descripcion | 64 | NULL | Nombre del contacto | |
| re_producto | descripcion | 64 | NULL | Producto o servicio | |
| re_monto | money | 8 | NULL | Monto de referencia | |
| re_plazo | Smallint | 2 | NULL | Plazo en meses | |
| re_fecha_desde | Datetime | 8 | NULL | Fecha desde | |
| re_fecha_hasta | Datetime | 8 | NULL | Fecha hasta | |
| re_calificacion | catalogo | 10 | NULL | Calificación de la referencia | |
| re_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de re_ente
- Relacionada con cl_ciudad a través de re_ciudad

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
