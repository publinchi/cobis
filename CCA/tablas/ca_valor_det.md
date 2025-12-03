# ca_valor_det

## Descripción

Tabla que almacena el detalle de los valores parametrizados. Contiene los valores específicos y sus rangos de aplicación.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| vd_codigo | catalogo | 10 | NOT NULL | Código del valor (referencia a ca_valor) |
| vd_secuencial | int | 4 | NOT NULL | Secuencial del detalle |
| vd_fecha_vigencia | datetime | 8 | NOT NULL | Fecha de vigencia del valor |
| vd_valor | float | 8 | NOT NULL | Valor numérico |
| vd_rango_desde | money | 8 | NULL | Rango desde (si aplica) |
| vd_rango_hasta | money | 8 | NULL | Rango hasta (si aplica) |
| vd_plazo_desde | smallint | 2 | NULL | Plazo desde (si aplica) |
| vd_plazo_hasta | smallint | 2 | NULL | Plazo hasta (si aplica) |
| vd_estado | char | 1 | NOT NULL | Estado del detalle<br><br>V = Vigente<br><br>I = Inactivo |
| vd_usuario | login | 14 | NOT NULL | Usuario que registró el valor |
| vd_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |

## Índices

- **ca_valor_det_1** (UNIQUE NONCLUSTERED INDEX): vd_codigo, vd_secuencial
- **ca_valor_det_2** (NONCLUSTERED INDEX): vd_fecha_vigencia
- **ca_valor_det_3** (NONCLUSTERED INDEX): vd_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
