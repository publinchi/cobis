# ca_cuota_adicional

## Descripción

Tabla que almacena información sobre cuotas adicionales que se pueden generar en un préstamo, fuera de la tabla de amortización regular.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ca_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| ca_secuencial | int | 4 | NOT NULL | Secuencial de la cuota adicional |
| ca_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| ca_monto | money | 8 | NOT NULL | Monto de la cuota adicional |
| ca_fecha_generacion | datetime | 8 | NOT NULL | Fecha de generación de la cuota |
| ca_fecha_vencimiento | datetime | 8 | NOT NULL | Fecha de vencimiento de la cuota |
| ca_estado | char | 1 | NOT NULL | Estado de la cuota<br><br>V = Vigente<br><br>P = Pagada<br><br>A = Anulada |
| ca_observacion | varchar | 255 | NULL | Observaciones de la cuota adicional |
| ca_usuario | login | 14 | NOT NULL | Usuario que generó la cuota |
| ca_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |

## Índices

- **ca_cuota_adicional_1** (UNIQUE NONCLUSTERED INDEX): ca_operacion, ca_secuencial

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
