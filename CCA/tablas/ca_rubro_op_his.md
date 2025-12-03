# ca_rubro_op_his

## Descripción

Tabla histórica que almacena los cambios realizados en los rubros de las operaciones. Registra todas las modificaciones de rubros para mantener un historial de cambios.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| roh_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| roh_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| roh_secuencial | int | 4 | NOT NULL | Secuencial del histórico |
| roh_tipo_monto | char | 1 | NOT NULL | Tipo de monto |
| roh_valor | money | 8 | NOT NULL | Valor del rubro |
| roh_fpago | catalogo | 10 | NULL | Forma de pago del rubro |
| roh_estado | char | 1 | NOT NULL | Estado del rubro |
| roh_prioridad | tinyint | 1 | NOT NULL | Prioridad de aplicación |
| roh_provisiona | char | 1 | NOT NULL | Si provisiona |
| roh_fecha | datetime | 8 | NOT NULL | Fecha del registro histórico |
| roh_usuario | login | 14 | NOT NULL | Usuario que realizó el cambio |
| roh_terminal | descripcion | 160 | NOT NULL | Terminal desde donde se realizó el cambio |

## Índices

- **ca_rubro_op_his_1** (NONCLUSTERED INDEX): roh_operacion, roh_concepto, roh_secuencial

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
