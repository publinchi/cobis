# bpl_rule_process_his_cli

## Descripción

Tabla histórica de procesamiento de reglas de negocio para clientes en la base de datos cob_pac.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| brp_secuencial | Int | 4 | NOT NULL | Secuencial del proceso | |
| brp_cliente | Int | 4 | NOT NULL | Código de cliente | |
| brp_regla | Varchar | 64 | NOT NULL | Código de regla procesada | |
| brp_fecha_proceso | Datetime | 8 | NOT NULL | Fecha de procesamiento | |
| brp_resultado | Varchar | 10 | NULL | Resultado del proceso | |
| brp_detalle | Varchar | 1000 | NULL | Detalle del resultado | |
| brp_usuario | Varchar | 14 | NULL | Usuario que ejecuta | |

## Transacciones de Servicio

Utilizada en procesos de reglas de negocio PAC.

## Índices

- bpl_rule_process_his_cli_Key
- bpl_rule_process_his_cli_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
