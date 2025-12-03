# ca_abono_grupal_tmp

## Descripción

Tabla temporal que almacena información de abonos grupales durante el proceso de ingreso, antes de su aplicación definitiva a las operaciones individuales del grupo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| agt_secuencial | int | 4 | NOT NULL | Secuencial del abono grupal |
| agt_grupo | int | 4 | NOT NULL | Código del grupo |
| agt_operacion_padre | int | 4 | NOT NULL | Número de operación padre |
| agt_fecha_pago | datetime | 8 | NOT NULL | Fecha del pago |
| agt_monto_total | money | 8 | NOT NULL | Monto total del pago grupal |
| agt_forma_pago | catalogo | 10 | NOT NULL | Forma de pago |
| agt_referencia | varchar | 50 | NULL | Referencia del pago |
| agt_estado | char | 1 | NOT NULL | Estado del abono<br><br>P = Pendiente<br><br>A = Aplicado<br><br>E = Error |
| agt_usuario | login | 14 | NOT NULL | Usuario que ingresó el pago |
| agt_fecha_registro | datetime | 8 | NOT NULL | Fecha de registro |
| agt_observacion | varchar | 255 | NULL | Observaciones |

## Índices

- **ca_abono_grupal_tmp_1** (UNIQUE NONCLUSTERED INDEX): agt_secuencial
- **ca_abono_grupal_tmp_2** (NONCLUSTERED INDEX): agt_grupo
- **ca_abono_grupal_tmp_3** (NONCLUSTERED INDEX): agt_operacion_padre

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
