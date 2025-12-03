# ca_param_cargos_gestion_cobranza

## Descripción

Tabla de parametrización que define los cargos por gestión de cobranza. Establece los montos y condiciones para aplicar cargos cuando un préstamo entra en mora o cobranza.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| pcgc_codigo | int | 4 | NOT NULL | Código del parámetro |
| pcgc_toperacion | catalogo | 10 | NOT NULL | Tipo de operación |
| pcgc_concepto | catalogo | 10 | NOT NULL | Concepto del cargo |
| pcgc_dias_mora_desde | smallint | 2 | NOT NULL | Días de mora desde |
| pcgc_dias_mora_hasta | smallint | 2 | NOT NULL | Días de mora hasta |
| pcgc_tipo_cargo | char | 1 | NOT NULL | Tipo de cargo<br><br>F = Fijo<br><br>P = Porcentaje |
| pcgc_valor | money | 8 | NOT NULL | Valor del cargo (monto fijo o porcentaje) |
| pcgc_frecuencia | char | 1 | NOT NULL | Frecuencia de aplicación<br><br>U = Única vez<br><br>M = Mensual<br><br>D = Diaria |
| pcgc_estado | char | 1 | NOT NULL | Estado del parámetro<br><br>V = Vigente<br><br>I = Inactivo |
| pcgc_fecha_inicio | datetime | 8 | NOT NULL | Fecha de inicio de vigencia |
| pcgc_fecha_fin | datetime | 8 | NULL | Fecha de fin de vigencia |

## Índices

- **ca_param_cargos_gestion_cobranza_1** (UNIQUE NONCLUSTERED INDEX): pcgc_codigo
- **ca_param_cargos_gestion_cobranza_2** (NONCLUSTERED INDEX): pcgc_toperacion, pcgc_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
