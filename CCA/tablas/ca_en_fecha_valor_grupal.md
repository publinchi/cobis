# ca_en_fecha_valor_grupal

## Descripción

Tabla de parametrización que define las validaciones de fecha valor específicas para préstamos grupales. Establece reglas particulares para operaciones grupales.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| efvg_codigo | int | 4 | NOT NULL | Código del parámetro |
| efvg_toperacion | catalogo | 10 | NOT NULL | Tipo de operación grupal |
| efvg_monto_desde | money | 8 | NOT NULL | Monto desde |
| efvg_monto_hasta | money | 8 | NOT NULL | Monto hasta |
| efvg_dias_gracia | smallint | 2 | NOT NULL | Días de gracia permitidos |
| efvg_permite_fecha_futura | char | 1 | NOT NULL | Si permite fecha valor futura<br><br>S = Si<br><br>N = No |
| efvg_dias_futuros | smallint | 2 | NULL | Cantidad de días futuros permitidos |
| efvg_permite_fecha_pasada | char | 1 | NOT NULL | Si permite fecha valor pasada<br><br>S = Si<br><br>N = No |
| efvg_dias_pasados | smallint | 2 | NULL | Cantidad de días pasados permitidos |
| efvg_aplica_operacion_padre | char | 1 | NOT NULL | Si aplica a operación padre<br><br>S = Si<br><br>N = No |
| efvg_aplica_operacion_hija | char | 1 | NOT NULL | Si aplica a operación hija<br><br>S = Si<br><br>N = No |
| efvg_estado | char | 1 | NOT NULL | Estado del parámetro<br><br>V = Vigente<br><br>I = Inactivo |

## Índices

- **ca_en_fecha_valor_grupal_1** (UNIQUE NONCLUSTERED INDEX): efvg_codigo
- **ca_en_fecha_valor_grupal_2** (NONCLUSTERED INDEX): efvg_toperacion, efvg_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
