# cl_cliente

## Descripción
Todos los clientes que han contratado un producto COBIS.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| cl_cliente | Int | 4 | NOT NULL | Código Cobis del cliente al cual se asocia un producto Cobis. | |
| cl_det_producto | Int | 4 | NOT NULL | Secuencial correspondiente al producto específico dentro de la tabla cl_det_producto. | |
| cl_rol | Char | 1 | NOT NULL | Rol del cliente para el producto. | T= Titular. A= Alternante. |
| cl_ced_ruc | numero | 30 | NOT NULL | Número de cédula o ruc del cliente. | |
| cl_fecha | Datetime | 8 | NOT NULL | Fecha de contratación del producto Cobis. | |

## Relaciones
- Relacionada con cl_ente a través de cl_cliente
- Relacionada con cl_det_producto a través de cl_det_producto

## Notas
Esta tabla vincula a los clientes (entes) con los productos COBIS que han contratado.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
