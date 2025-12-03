# ca_valor

## Descripción

Tabla de parametrización que almacena los valores y tasas configurables del módulo de cartera (tasas de referencia, porcentajes, límites, etc.).

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| va_codigo | catalogo | 10 | NOT NULL | Código del valor |
| va_descripcion | descripcion | 64 | NOT NULL | Descripción del valor |
| va_tipo | char | 1 | NOT NULL | Tipo de valor<br><br>T = Tasa<br><br>P = Porcentaje<br><br>M = Monto<br><br>N = Número |
| va_moneda | tinyint | 1 | NULL | Moneda del valor (si aplica) |
| va_toperacion | catalogo | 10 | NULL | Tipo de operación asociado |
| va_estado | char | 1 | NOT NULL | Estado del valor<br><br>V = Vigente<br><br>I = Inactivo |
| va_fecha_inicio | datetime | 8 | NOT NULL | Fecha de inicio de vigencia |
| va_fecha_fin | datetime | 8 | NULL | Fecha de fin de vigencia |

## Índices

- **ca_valor_1** (UNIQUE NONCLUSTERED INDEX): va_codigo
- **ca_valor_2** (NONCLUSTERED INDEX): va_toperacion, va_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
