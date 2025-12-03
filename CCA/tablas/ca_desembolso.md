# ca_desembolso

## Descripción

Tabla que almacena la información de los desembolsos realizados a los préstamos. Registra el detalle de cada liquidación de fondos al cliente.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| de_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| de_secuencial | int | 4 | NOT NULL | Secuencial del desembolso |
| de_fecha_desembolso | datetime | 8 | NOT NULL | Fecha del desembolso |
| de_monto | money | 8 | NOT NULL | Monto desembolsado |
| de_forma_desembolso | catalogo | 10 | NOT NULL | Forma de desembolso (efectivo, transferencia, cheque, etc.) |
| de_cuenta_destino | cuenta | 24 | NULL | Cuenta destino del desembolso |
| de_banco_destino | catalogo | 10 | NULL | Banco destino |
| de_referencia | varchar | 50 | NULL | Referencia del desembolso |
| de_estado | char | 1 | NOT NULL | Estado del desembolso<br><br>P = Pendiente<br><br>A = Aplicado<br><br>R = Reversado |
| de_usuario | login | 14 | NOT NULL | Usuario que realizó el desembolso |
| de_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| de_oficina | smallint | 2 | NOT NULL | Oficina donde se realizó el desembolso |
| de_terminal | descripcion | 160 | NOT NULL | Terminal desde donde se realizó |
| de_secuencial_trn | int | 4 | NULL | Secuencial de la transacción asociada |

## Índices

- **ca_desembolso_1** (UNIQUE NONCLUSTERED INDEX): de_operacion, de_secuencial
- **ca_desembolso_2** (NONCLUSTERED INDEX): de_fecha_desembolso
- **ca_desembolso_3** (NONCLUSTERED INDEX): de_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
