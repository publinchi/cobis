# cl_economica

## Descripción
Contiene información económica detallada de los clientes, incluyendo datos sobre ingresos, egresos, activos y pasivos.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ec_ente | Int | 4 | NOT NULL | Código del ente | |
| ec_ingreso_mensual | money | 8 | NULL | Ingreso mensual promedio | |
| ec_egreso_mensual | money | 8 | NULL | Egreso mensual promedio | |
| ec_otros_ingresos | money | 8 | NULL | Otros ingresos mensuales | |
| ec_total_activos | money | 8 | NULL | Total de activos | |
| ec_total_pasivos | money | 8 | NULL | Total de pasivos | |
| ec_patrimonio | money | 8 | NULL | Patrimonio neto | |
| ec_num_cargas | Tinyint | 1 | NULL | Número de cargas familiares | |
| ec_gastos_vivienda | money | 8 | NULL | Gastos de vivienda | |
| ec_gastos_educacion | money | 8 | NULL | Gastos de educación | |
| ec_gastos_salud | money | 8 | NULL | Gastos de salud | |
| ec_otros_gastos | money | 8 | NULL | Otros gastos | |
| ec_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| ec_usuario | login | 14 | NULL | Usuario que registró | |
| ec_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ec_fecha_actualizacion | Datetime | 8 | NULL | Fecha de última actualización | |
| ec_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de ec_ente

## Notas
Esta tabla almacena información económica consolidada del cliente para análisis de capacidad de pago.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
