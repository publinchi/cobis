# cr_det_transaccion_linea

## Descripción

Almacena el detalle de las transacciones realizadas sobre líneas de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| dtl_secuencial | Int | 4 | NOT NULL | Secuencial de la transacción | |
| dtl_secuencial_det | Smallint | 2 | NOT NULL | Secuencial del detalle | |
| dtl_concepto | Varchar | 10 | NOT NULL | Código de concepto | |
| dtl_monto | Money | 8 | NOT NULL | Monto del concepto | |
| dtl_descripcion | Varchar | 255 | NULL | Descripción del concepto | |

## Transacciones de Servicio

21046, 21146, 21246

## Índices

- cr_det_transaccion_linea_Key

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
