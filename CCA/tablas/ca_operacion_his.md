# ca_operacion_his

## Descripción

Tabla histórica que almacena los cambios realizados en las operaciones de cartera. Registra todas las modificaciones importantes de los préstamos para mantener un historial completo de cambios.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| oph_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| oph_secuencial | int | 4 | NOT NULL | Secuencial del histórico |
| oph_fecha | datetime | 8 | NOT NULL | Fecha del cambio |
| oph_usuario | login | 14 | NOT NULL | Usuario que realizó el cambio |
| oph_terminal | descripcion | 160 | NOT NULL | Terminal desde donde se realizó el cambio |
| oph_tipo_cambio | varchar | 50 | NOT NULL | Tipo de cambio realizado |
| oph_campo | varchar | 50 | NOT NULL | Campo modificado |
| oph_valor_anterior | varchar | 255 | NULL | Valor anterior del campo |
| oph_valor_nuevo | varchar | 255 | NULL | Valor nuevo del campo |
| oph_observacion | varchar | 255 | NULL | Observaciones del cambio |

## Índices

- **ca_operacion_his_1** (NONCLUSTERED INDEX): oph_operacion, oph_secuencial
- **ca_operacion_his_2** (NONCLUSTERED INDEX): oph_fecha

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
