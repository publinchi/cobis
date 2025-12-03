# cr_accion_desercion

## Descripción

Almacena las acciones tomadas ante casos de deserción de clientes.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| ad_secuencial | Int | 4 | NOT NULL | Secuencial de la acción | |
| ad_cliente | Int | 4 | NOT NULL | Código de cliente | |
| ad_causa_desercion | Varchar | 10 | NOT NULL | Código de causa de deserción | |
| ad_fecha_desercion | Datetime | 8 | NOT NULL | Fecha de deserción | |
| ad_accion_tomada | Varchar | 255 | NULL | Descripción de acción tomada | |
| ad_fecha_accion | Datetime | 8 | NULL | Fecha de la acción | |
| ad_usuario | Varchar | 14 | NOT NULL | Usuario que registra | |
| ad_resultado | Varchar | 255 | NULL | Resultado de la acción | |
| ad_estado | Char | 1 | NOT NULL | Estado | P: Pendiente<br>E: Ejecutada<br>C: Cerrada |

## Transacciones de Servicio

21052, 21152

## Índices

- cr_accion_desercion_Key
- cr_accion_desercion_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
