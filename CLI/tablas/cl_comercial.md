# cl_comercial

## Descripción
Contiene información comercial de los clientes, incluyendo datos sobre su negocio, ventas y actividad comercial.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| co_ente | Int | 4 | NOT NULL | Código del ente | |
| co_nombre_comercial | descripcion | 254 | NULL | Nombre comercial del negocio | |
| co_ruc_comercial | numero | 30 | NULL | RUC del negocio | |
| co_fecha_inicio_actividad | Datetime | 8 | NULL | Fecha de inicio de actividades | |
| co_num_empleados | Int | 4 | NULL | Número de empleados | |
| co_ventas_anuales | money | 8 | NULL | Ventas anuales estimadas | |
| co_activos | money | 8 | NULL | Total de activos | |
| co_pasivos | money | 8 | NULL | Total de pasivos | |
| co_patrimonio | money | 8 | NULL | Patrimonio | |
| co_local_propio | Char | 1 | NULL | Local propio | S=Sí<br>N=No |
| co_valor_local | money | 8 | NULL | Valor del local | |
| co_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| co_usuario | login | 14 | NULL | Usuario que registró | |
| co_terminal | descripcion | 64 | NULL | Terminal de registro | |
| co_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de co_ente

## Notas
Esta tabla almacena información comercial y financiera básica de los negocios de los clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
