# ca_pin_odp

## Descripción

Tabla que almacena los pines generados para desembolsos de operaciones. Permite el control de seguridad en el proceso de entrega de fondos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| po_operacion | int | 4 | NOT NULL | Número de operación |
| po_secuencial | int | 4 | NOT NULL | Secuencial del pin |
| po_pin | varchar | 20 | NOT NULL | Código PIN generado |
| po_fecha_generacion | datetime | 8 | NOT NULL | Fecha de generación del PIN |
| po_fecha_vencimiento | datetime | 8 | NOT NULL | Fecha de vencimiento del PIN |
| po_estado | char | 1 | NOT NULL | Estado del PIN<br><br>G = Generado<br><br>U = Usado<br><br>V = Vencido<br><br>A = Anulado |
| po_fecha_uso | datetime | 8 | NULL | Fecha de uso del PIN |
| po_usuario_genera | login | 14 | NOT NULL | Usuario que generó el PIN |
| po_usuario_usa | login | 14 | NULL | Usuario que usó el PIN |
| po_intentos | tinyint | 1 | NOT NULL | Cantidad de intentos de uso |
| po_monto | money | 8 | NOT NULL | Monto del desembolso asociado |

## Índices

- **ca_pin_odp_1** (UNIQUE NONCLUSTERED INDEX): po_operacion, po_secuencial
- **ca_pin_odp_2** (NONCLUSTERED INDEX): po_pin
- **ca_pin_odp_3** (NONCLUSTERED INDEX): po_estado
- **ca_pin_odp_4** (NONCLUSTERED INDEX): po_fecha_vencimiento

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
