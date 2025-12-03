# ts_negocio_cliente

## Descripción
Vista de servicio para consulta de negocios de clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| nc_ente | Int | 4 | NOT NULL | Código del ente | |
| nc_secuencial | Tinyint | 1 | NOT NULL | Secuencial del negocio | |
| nc_nombre_negocio | descripcion | 254 | NULL | Nombre del negocio | |
| nc_actividad | catalogo | 10 | NULL | Actividad económica | |
| nc_fecha_inicio | Datetime | 8 | NULL | Fecha de inicio | |
| nc_num_empleados | Int | 4 | NULL | Número de empleados | |
| nc_direccion | descripcion | 254 | NULL | Dirección | |
| nc_ciudad | Int | 4 | NULL | Ciudad | |
| nc_telefono | telefono | 16 | NULL | Teléfono | |
| nc_ventas_mensuales | money | 8 | NULL | Ventas mensuales | |
| nc_utilidad_mensual | money | 8 | NULL | Utilidad mensual | |
| nc_estado | estado | 1 | NULL | Estado | |

## Relaciones
- Vista basada en cl_negocio_cliente

## Notas
Esta es una vista de servicio para transacciones que consultan información de negocios.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
