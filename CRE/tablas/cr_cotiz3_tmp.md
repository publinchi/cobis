# cr_cotiz3_tmp

## Descripción

Tabla temporal utilizada para almacenar información de cotizaciones durante el proceso de evaluación de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| tmp_secuencial | Int | 4 | NOT NULL | Secuencial de cotización | |
| tmp_monto | Money | 8 | NULL | Monto de la cotización | |
| tmp_plazo | Smallint | 2 | NULL | Plazo en períodos | |
| tmp_tasa | Float | 8 | NULL | Tasa de interés | |
| tmp_cuota | Money | 8 | NULL | Valor de la cuota | |
| tmp_fecha | Datetime | 8 | NULL | Fecha de cotización | |

## Transacciones de Servicio

Utilizada en procesos de cotización de créditos.

## Índices

- tmp_tramite_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
