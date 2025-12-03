# ca_det_ciclo

## Descripción

Tabla que almacena el detalle de los ciclos de créditos grupales. Contiene la información de cada miembro del grupo y su participación en el ciclo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dc_grupo | int | 4 | NOT NULL | Código del grupo |
| dc_ciclo | tinyint | 1 | NOT NULL | Número de ciclo |
| dc_operacion | int | 4 | NOT NULL | Número de operación del miembro |
| dc_cliente | int | 4 | NOT NULL | Código del cliente |
| dc_monto | money | 8 | NOT NULL | Monto del préstamo del miembro |
| dc_estado | char | 1 | NOT NULL | Estado del miembro en el ciclo<br><br>V = Vigente<br><br>C = Cancelado<br><br>R = Retirado |
| dc_fecha_ingreso | datetime | 8 | NOT NULL | Fecha de ingreso al ciclo |
| dc_fecha_salida | datetime | 8 | NULL | Fecha de salida del ciclo |
| dc_observacion | varchar | 255 | NULL | Observaciones |

## Índices

- **ca_det_ciclo_1** (UNIQUE NONCLUSTERED INDEX): dc_grupo, dc_ciclo, dc_operacion
- **ca_det_ciclo_2** (NONCLUSTERED INDEX): dc_cliente

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
