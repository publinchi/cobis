# ca_amortizacion_his

## Descripción

Tabla histórica que almacena los cambios realizados en la tabla de amortización. Registra todas las modificaciones de rubros por dividendo para mantener un historial de cambios.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| amh_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| amh_dividendo | smallint | 2 | NOT NULL | Número de dividendo/cuota |
| amh_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| amh_secuencial | int | 4 | NOT NULL | Secuencial del histórico |
| amh_estado | tinyint | 1 | NOT NULL | Estado del rubro<br><br>0 = Vigente<br><br>1 = Cancelado<br><br>2 = Vencido<br><br>3 = Castigado |
| amh_cuota | money | 8 | NOT NULL | Monto de la cuota proyectada |
| amh_gracia | char | 1 | NOT NULL | Indica si el dividendo está en período de gracia<br><br>S = Si<br><br>N = No |
| amh_pagado | money | 8 | NOT NULL | Monto pagado del rubro |
| amh_acumulado | money | 8 | NOT NULL | Monto acumulado del rubro |
| amh_en_mora | money | 8 | NOT NULL | Monto en mora del rubro |
| amh_fecha | datetime | 8 | NOT NULL | Fecha del registro histórico |
| amh_usuario | login | 14 | NOT NULL | Usuario que realizó el cambio |
| amh_terminal | descripcion | 160 | NOT NULL | Terminal desde donde se realizó el cambio |

## Índices

- **ca_amortizacion_his_1** (NONCLUSTERED INDEX): amh_operacion, amh_dividendo, amh_concepto, amh_secuencial

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
