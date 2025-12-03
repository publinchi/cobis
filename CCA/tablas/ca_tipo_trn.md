# ca_tipo_trn

## Descripción

Tabla de catálogo que define los tipos de transacciones que se pueden realizar en el módulo de cartera (desembolso, pago, ajuste, etc.).

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| tt_codigo | char | 3 | NOT NULL | Código del tipo de transacción |
| tt_descripcion | descripcion | 64 | NOT NULL | Descripción del tipo de transacción |
| tt_naturaleza | char | 1 | NOT NULL | Naturaleza de la transacción<br><br>D = Débito<br><br>C = Crédito |
| tt_afecta_saldo | char | 1 | NOT NULL | Si afecta el saldo de la operación<br><br>S = Si<br><br>N = No |
| tt_genera_contabilidad | char | 1 | NOT NULL | Si genera asientos contables<br><br>S = Si<br><br>N = No |
| tt_reversable | char | 1 | NOT NULL | Si la transacción es reversable<br><br>S = Si<br><br>N = No |
| tt_estado | char | 1 | NOT NULL | Estado del tipo de transacción<br><br>V = Vigente<br><br>I = Inactivo |

## Índices

- **ca_tipo_trn_1** (UNIQUE NONCLUSTERED INDEX): tt_codigo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
