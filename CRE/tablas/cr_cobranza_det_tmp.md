# cr_cobranza_det_tmp

## Descripción

Tabla temporal para el detalle de procesos de cobranza masiva.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_operacion | Int | 4 | NOT NULL | Número de operación | |
| tmp_secuencial | Smallint | 2 | NOT NULL | Secuencial del detalle | |
| tmp_concepto | Varchar | 10 | NULL | Concepto de cobranza | |
| tmp_monto | Money | 8 | NULL | Monto del concepto | |
| tmp_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |

## Transacciones de Servicio

Utilizada en procesos batch de cobranza.

## Índices

- tmp_operacion_secuencial_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
