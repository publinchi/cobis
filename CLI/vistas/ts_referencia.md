# ts_referencia

## Descripción
Vista de servicio para consulta de referencias bancarias y comerciales.

**NOTA: No se usa en esta versión**

## Estructura de la vista

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
| re_calificacion | catalogo | 10 | NULL | Calificación de la referencia | |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |
| nombre_ciudad | descripcion | 64 | NULL | Nombre de la ciudad | |

## Relaciones
- Vista basada en cl_referencia con joins a cl_ente y cl_ciudad

## Notas
Esta vista no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
