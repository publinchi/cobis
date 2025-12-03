# ca_default_toperacion

## Descripción

Tabla de parametrización que contiene los valores por defecto y configuraciones específicas para cada tipo de operación de cartera. Define el comportamiento estándar de cada producto.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dt_toperacion | catalogo | 10 | NOT NULL | Tipo de operación/producto |
| dt_moneda | tinyint | 1 | NOT NULL | Moneda por defecto |
| dt_dias_anio | smallint | 2 | NOT NULL | Días del año para cálculo de intereses (360, 365, 366) |
| dt_tipo_amortizacion | varchar | 10 | NOT NULL | Tipo de amortización por defecto<br><br>FRANCESA<br><br>ALEMANA<br><br>MANUAL |
| dt_cuota_completa | char | 1 | NOT NULL | Si requiere pago de cuota completa<br><br>S = Si<br><br>N = No |
| dt_tipo_cobro | char | 1 | NOT NULL | Tipo de cobro de intereses<br><br>A = Acumulado<br><br>P = Proyectado |
| dt_tipo_reduccion | char | 1 | NOT NULL | Tipo de reducción en pagos anticipados<br><br>C = Cuota<br><br>T = Tiempo<br><br>N = No aplica |
| dt_aceptar_anticipos | char | 1 | NOT NULL | Si acepta pagos anticipados<br><br>S = Si<br><br>N = No |
| dt_precancelacion | char | 1 | NOT NULL | Si permite precancelación<br><br>S = Si<br><br>N = No |
| dt_tipo_aplicacion | char | 1 | NOT NULL | Tipo de aplicación de pagos<br><br>D = Por dividendo<br><br>C = Por concepto |
| dt_evitar_feriados | char | 1 | NOT NULL | Si evita feriados en fechas de vencimiento<br><br>S = Si<br><br>N = No |
| dt_dia_habil | char | 1 | NULL | Manejo de días hábiles<br><br>S = Último día hábil antes<br><br>N = Primer día hábil después |
| dt_reajustable | char | 1 | NOT NULL | Si permite reajuste de tasas<br><br>S = Si<br><br>N = No<br><br>F = Flotante |
| dt_causacion | char | 1 | NULL | Tipo de causación de intereses<br><br>L = Lineal<br><br>E = Exponencial |
| dt_pago_caja | char | 1 | NULL | Si permite pagos por caja<br><br>S = Si<br><br>N = No |
| dt_mora_retroactiva | char | 1 | NULL | Si aplica mora retroactiva<br><br>S = Si<br><br>N = No |
| dt_prepago_desde_lavigente | char | 1 | NULL | Si permite prepago desde la vigente<br><br>S = Si<br><br>N = No |
| dt_calcula_devolucion | char | 1 | NULL | Si calcula devolución de pagos<br><br>S = Si<br><br>N = No |
| dt_nace_vencida | char | 1 | NULL | Si nace vencida<br><br>S = Si<br><br>N = No |
| dt_recalcular_plazo | char | 1 | NULL | Si recalcula plazo<br><br>S = Si<br><br>N = No |
| dt_usar_tequivalente | char | 1 | NULL | Si usa tasa equivalente<br><br>S = Si<br><br>N = No |
| dt_convertir_tasa | char | 1 | NULL | Si convierte tasa<br><br>S = Si<br><br>N = No |
| dt_tipo_redondeo | tinyint | 1 | NULL | Tipo de redondeo a aplicar |
| dt_prd_cobis | tinyint | 1 | NULL | Código de producto COBIS |
| dt_tipo_linea | catalogo | 10 | NULL | Tipo de línea de crédito |
| dt_subtipo_linea | catalogo | 10 | NULL | Subtipo de línea/programa de crédito |
| dt_bvirtual | char | 1 | NULL | Si se muestra en banca virtual<br><br>S = Si<br><br>N = No |
| dt_extracto | char | 1 | NULL | Si genera extractos<br><br>S = Si<br><br>N = No |
| dt_entidad_convenio | catalogo | 10 | NULL | Código de entidad convenio |

## Índices

- **ca_default_toperacion_1** (UNIQUE NONCLUSTERED INDEX): dt_toperacion, dt_moneda

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
