# cr_lin_ope_moneda

## Descripción

Almacena la relación entre líneas de crédito, tipos de operación y monedas permitidas.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| lom_linea | Int | 4 | NOT NULL | Código numérico de línea | |
| lom_toperacion | Varchar | 10 | NOT NULL | Código de tipo de operación | |
| lom_moneda | Tinyint | 1 | NOT NULL | Código de moneda | |
| lom_monto_maximo | Money | 8 | NULL | Monto máximo permitido | |
| lom_plazo_maximo | Smallint | 2 | NULL | Plazo máximo en períodos | |
| lom_estado | Char | 1 | NOT NULL | Estado del registro | V: Vigente<br>I: Inactivo |

## Transacciones de Servicio

21032, 21132

## Índices

- cr_lin_ope_moneda_Key
- cr_lin_ope_moneda_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
