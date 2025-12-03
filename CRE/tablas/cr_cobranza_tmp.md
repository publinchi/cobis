# cr_cobranza_tmp

## Descripción

Tabla temporal para procesos de cobranza masiva.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| tmp_operacion | Int | 4 | NOT NULL | Número de operación | |
| tmp_cliente | Int | 4 | NULL | Código de cliente | |
| tmp_saldo_capital | Money | 8 | NULL | Saldo de capital | |
| tmp_saldo_interes | Money | 8 | NULL | Saldo de interés | |
| tmp_dias_mora | Smallint | 2 | NULL | Días de mora | |
| tmp_estado | Char | 1 | NULL | Estado temporal | |

## Transacciones de Servicio

Utilizada en procesos batch de cobranza.

## Índices

- tmp_operacion_idx

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
