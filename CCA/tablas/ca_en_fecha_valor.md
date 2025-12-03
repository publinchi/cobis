# ca_en_fecha_valor

## Descripción

Tabla de parametrización que define las validaciones de montos y fechas valor para las operaciones de cartera. Establece reglas de negocio para la aplicación de pagos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| efv_codigo | int | 4 | NOT NULL | Código del parámetro |
| efv_toperacion | catalogo | 10 | NOT NULL | Tipo de operación |
| efv_monto_desde | money | 8 | NOT NULL | Monto desde |
| efv_monto_hasta | money | 8 | NOT NULL | Monto hasta |
| efv_dias_gracia | smallint | 2 | NOT NULL | Días de gracia permitidos |
| efv_permite_fecha_futura | char | 1 | NOT NULL | Si permite fecha valor futura<br><br>S = Si<br><br>N = No |
| efv_dias_futuros | smallint | 2 | NULL | Cantidad de días futuros permitidos |
| efv_permite_fecha_pasada | char | 1 | NOT NULL | Si permite fecha valor pasada<br><br>S = Si<br><br>N = No |
| efv_dias_pasados | smallint | 2 | NULL | Cantidad de días pasados permitidos |
| efv_estado | char | 1 | NOT NULL | Estado del parámetro<br><br>V = Vigente<br><br>I = Inactivo |

## Índices

- **ca_en_fecha_valor_1** (UNIQUE NONCLUSTERED INDEX): efv_codigo
- **ca_en_fecha_valor_2** (NONCLUSTERED INDEX): efv_toperacion, efv_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
