# cr_productos_linea

## Descripción

Almacena los productos financieros asociados a una línea de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| prl_linea | Int | 4 | NOT NULL | Código numérico de línea | |
| prl_producto | Varchar | 10 | NOT NULL | Código de producto | |
| prl_estado | Char | 1 | NOT NULL | Estado del producto en la línea | V: Vigente<br>I: Inactivo |
| prl_monto_maximo | Money | 8 | NULL | Monto máximo para el producto | |
| prl_plazo_maximo | Smallint | 2 | NULL | Plazo máximo en períodos | |

## Transacciones de Servicio

21035, 21135

## Índices

- cr_productos_linea_Key
- cr_productos_linea_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
