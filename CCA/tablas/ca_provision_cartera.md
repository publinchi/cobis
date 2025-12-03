# ca_provision_cartera

## Descripción

Tabla que almacena los datos de provisión de cartera. Registra los montos provisionados para cada operación según su calificación y días de mora.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| pc_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| pc_fecha_proceso | datetime | 8 | NOT NULL | Fecha del proceso de provisión |
| pc_calificacion | char | 1 | NOT NULL | Calificación de la operación |
| pc_dias_mora | smallint | 2 | NOT NULL | Días de mora |
| pc_saldo_capital | money | 8 | NOT NULL | Saldo de capital |
| pc_porcentaje_provision | float | 8 | NOT NULL | Porcentaje de provisión aplicado |
| pc_monto_provision | money | 8 | NOT NULL | Monto provisionado |
| pc_provision_anterior | money | 8 | NOT NULL | Provisión del período anterior |
| pc_diferencia | money | 8 | NOT NULL | Diferencia de provisión |
| pc_estado | char | 1 | NOT NULL | Estado de la provisión<br><br>V = Vigente<br><br>R = Reversada |

## Índices

- **ca_provision_cartera_1** (UNIQUE NONCLUSTERED INDEX): pc_operacion, pc_fecha_proceso
- **ca_provision_cartera_2** (NONCLUSTERED INDEX): pc_fecha_proceso

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
