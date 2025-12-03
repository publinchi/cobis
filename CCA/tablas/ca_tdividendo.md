# ca_tdividendo

## Descripción

Tabla de catálogo que define los tipos de dividendo o periodicidad de pago disponibles en el módulo de cartera (mensual, quincenal, semanal, etc.).

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| td_codigo | catalogo | 10 | NOT NULL | Código del tipo de dividendo |
| td_descripcion | descripcion | 64 | NOT NULL | Descripción del tipo de dividendo |
| td_dias | smallint | 2 | NOT NULL | Cantidad de días del período |
| td_factor | float | 8 | NOT NULL | Factor de conversión anual |
| td_estado | char | 1 | NOT NULL | Estado del tipo de dividendo<br><br>V = Vigente<br><br>I = Inactivo |

## Índices

- **ca_tdividendo_1** (UNIQUE NONCLUSTERED INDEX): td_codigo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
