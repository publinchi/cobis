# cr_toperacion

## Descripción

Catálogo de tipos de operación de crédito disponibles en el sistema.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| to_codigo | Varchar | 10 | NOT NULL | Código del tipo de operación | |
| to_descripcion | Varchar | 64 | NOT NULL | Descripción del tipo de operación | |
| to_producto | Varchar | 10 | NOT NULL | Código de producto | CCA: Cartera<br>CEX: Comercio Exterior |
| to_moneda | Tinyint | 1 | NULL | Moneda por defecto | |
| to_plazo_minimo | Smallint | 2 | NULL | Plazo mínimo en períodos | |
| to_plazo_maximo | Smallint | 2 | NULL | Plazo máximo en períodos | |
| to_monto_minimo | Money | 8 | NULL | Monto mínimo | |
| to_monto_maximo | Money | 8 | NULL | Monto máximo | |
| to_tasa_minima | Float | 8 | NULL | Tasa de interés mínima | |
| to_tasa_maxima | Float | 8 | NULL | Tasa de interés máxima | |
| to_estado | Char | 1 | NOT NULL | Estado del tipo de operación | V: Vigente<br>I: Inactivo |
| to_permite_renovacion | Char | 1 | NULL | Permite renovación | S: Sí<br>N: No |
| to_requiere_garantia | Char | 1 | NULL | Requiere garantía | S: Sí<br>N: No |

## Transacciones de Servicio

21045, 21145, 21245

## Índices

- cr_toperacion_Key
- cr_toperacion_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
