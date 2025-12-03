# cl_productos_negocio

## Descripción
Contiene información de los productos o servicios que comercializa el negocio del cliente.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| pn_secuencial | Int | 4 | NOT NULL | Secuencial del producto | |
| pn_ente | Int | 4 | NOT NULL | Código del ente | |
| pn_negocio | Tinyint | 1 | NOT NULL | Secuencial del negocio | |
| pn_producto | descripcion | 254 | NOT NULL | Nombre del producto o servicio | |
| pn_descripcion | descripcion | 254 | NULL | Descripción del producto | |
| pn_precio_venta | money | 8 | NULL | Precio de venta | |
| pn_costo | money | 8 | NULL | Costo del producto | |
| pn_margen | Decimal | 5,2 | NULL | Margen de utilidad en porcentaje | |
| pn_volumen_mensual | Int | 4 | NULL | Volumen de ventas mensual | |
| pn_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| pn_usuario | login | 14 | NULL | Usuario que registró | |
| pn_terminal | descripcion | 64 | NULL | Terminal de registro | |
| pn_estado | estado | 1 | NULL | Estado del producto | V=Vigente<br>C=Cancelado |
| pn_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de pn_ente
- Relacionada con cl_negocio_cliente a través de pn_ente y pn_negocio

## Notas
Esta tabla permite detallar los productos o servicios que comercializa cada negocio del cliente.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
