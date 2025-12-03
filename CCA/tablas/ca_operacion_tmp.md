# ca_operacion_tmp

## Descripción

Tabla temporal que almacena información de operaciones durante procesos de simulación o modificación, antes de su aplicación definitiva en la tabla principal ca_operacion.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| opt_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| opt_banco | cuenta | 24 | NOT NULL | Número banco del préstamo |
| opt_cliente | int | 4 | NULL | Código del cliente |
| opt_toperacion | catalogo | 10 | NOT NULL | Tipo de operación |
| opt_moneda | tinyint | 1 | NOT NULL | Moneda del préstamo |
| opt_monto | money | 8 | NOT NULL | Monto del préstamo |
| opt_plazo | smallint | 2 | NULL | Plazo del préstamo |
| opt_tplazo | catalogo | 10 | NULL | Tipo de plazo |
| opt_cuota | money | 8 | NULL | Monto de la cuota |
| opt_tasa | float | 8 | NULL | Tasa de interés |
| opt_fecha_ini | datetime | 8 | NOT NULL | Fecha de inicio |
| opt_fecha_fin | datetime | 8 | NOT NULL | Fecha de fin |
| opt_estado | tinyint | 1 | NOT NULL | Estado temporal |
| opt_usuario | login | 14 | NOT NULL | Usuario que creó el registro temporal |
| opt_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |

## Índices

- **ca_operacion_tmp_1** (UNIQUE NONCLUSTERED INDEX): opt_operacion

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
