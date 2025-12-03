# cl_negocio_cliente

## Descripción
Contiene información sobre los negocios o emprendimientos de los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| nc_ente | Int | 4 | NOT NULL | Código del ente | |
| nc_secuencial | Tinyint | 1 | NOT NULL | Secuencial del negocio | |
| nc_nombre_negocio | descripcion | 254 | NULL | Nombre del negocio | |
| nc_actividad | catalogo | 10 | NULL | Actividad económica del negocio | |
| nc_fecha_inicio | Datetime | 8 | NULL | Fecha de inicio del negocio | |
| nc_num_empleados | Int | 4 | NULL | Número de empleados | |
| nc_direccion | descripcion | 254 | NULL | Dirección del negocio | |
| nc_ciudad | Int | 4 | NULL | Ciudad del negocio | |
| nc_telefono | telefono | 16 | NULL | Teléfono del negocio | |
| nc_ventas_mensuales | money | 8 | NULL | Ventas mensuales promedio | |
| nc_utilidad_mensual | money | 8 | NULL | Utilidad mensual promedio | |
| nc_local_propio | Char | 1 | NULL | Local propio | S=Sí<br>N=No |
| nc_valor_arriendo | money | 8 | NULL | Valor del arriendo si aplica | |
| nc_estado | estado | 1 | NULL | Estado del negocio | V=Vigente<br>C=Cerrado |
| nc_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| nc_usuario | login | 14 | NULL | Usuario que registró | |
| nc_terminal | descripcion | 64 | NULL | Terminal de registro | |
| nc_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de nc_ente
- Relacionada con cl_actividad_ec a través de nc_actividad
- Relacionada con cl_ciudad a través de nc_ciudad

## Notas
Esta tabla permite registrar múltiples negocios por cliente, útil para microempresarios.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
