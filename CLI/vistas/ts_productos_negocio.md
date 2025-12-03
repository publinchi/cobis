# ts_productos_negocio

## Descripción
Vista de servicio para consulta de productos o servicios que comercializa el negocio del cliente.

## Estructura de la vista

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
| pn_estado | estado | 1 | NULL | Estado del producto | V=Vigente<br>C=Cancelado |
| nombre_negocio | descripcion | 254 | NULL | Nombre del negocio | |

## Relaciones
- Vista basada en cl_productos_negocio con join a cl_negocio_cliente

## Notas
Esta vista facilita la consulta de productos comercializados por los negocios de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
