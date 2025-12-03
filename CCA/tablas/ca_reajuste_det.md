# ca_reajuste_det

## Descripción

Tabla que almacena el detalle de los reajustes de tasas. Contiene la información específica de cómo afecta el reajuste a cada dividendo de la operación.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| rd_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| rd_secuencial | int | 4 | NOT NULL | Secuencial del reajuste |
| rd_dividendo | smallint | 2 | NOT NULL | Número de dividendo afectado |
| rd_concepto | catalogo | 10 | NOT NULL | Concepto afectado |
| rd_cuota_anterior | money | 8 | NOT NULL | Cuota anterior del concepto |
| rd_cuota_nueva | money | 8 | NOT NULL | Cuota nueva del concepto |
| rd_diferencia | money | 8 | NOT NULL | Diferencia entre cuota nueva y anterior |

## Índices

- **ca_reajuste_det_1** (UNIQUE NONCLUSTERED INDEX): rd_operacion, rd_secuencial, rd_dividendo, rd_concepto

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
