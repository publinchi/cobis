# cr_transaccion_linea

## Descripción

Almacena las transacciones realizadas sobre líneas de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tl_secuencial | Int | 4 | NOT NULL | Secuencial de la transacción | |
| tl_linea | Int | 4 | NOT NULL | Código numérico de línea | |
| tl_fecha | Datetime | 8 | NOT NULL | Fecha de la transacción | |
| tl_tipo_transaccion | Varchar | 10 | NOT NULL | Tipo de transacción | DES: Desembolso<br>PAG: Pago<br>AJU: Ajuste |
| tl_monto | Money | 8 | NOT NULL | Monto de la transacción | |
| tl_operacion | Int | 4 | NULL | Número de operación relacionada | |
| tl_usuario | Varchar | 14 | NOT NULL | Usuario que realiza la transacción | |
| tl_oficina | Smallint | 2 | NOT NULL | Oficina donde se realiza | |
| tl_observacion | Varchar | 255 | NULL | Observaciones | |
| tl_estado | Char | 1 | NOT NULL | Estado de la transacción | V: Vigente<br>A: Anulada |

## Transacciones de Servicio

21046, 21146, 21246

## Índices

- cr_transaccion_linea_Key
- cr_transaccion_linea_idx1
- cr_transaccion_linea_idx2

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
