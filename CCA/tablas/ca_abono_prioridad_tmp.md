# ca_abono_prioridad_tmp

## Descripción

Tabla temporal que almacena la prioridad de aplicación de rubros durante el proceso de ingreso de un pago, antes de su aplicación definitiva.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| apt_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| apt_secuencial_ing | int | 4 | NOT NULL | Secuencial único de ingreso del pago |
| apt_dividendo | smallint | 2 | NOT NULL | Número de dividendo |
| apt_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| apt_prioridad | tinyint | 1 | NOT NULL | Orden de prioridad de aplicación |
| apt_monto | money | 8 | NOT NULL | Monto a aplicar al concepto |
| apt_estado | char | 1 | NOT NULL | Estado de la prioridad<br><br>V = Vigente<br><br>A = Aplicado<br><br>C = Cancelado |

## Índices

- **ca_abono_prioridad_tmp_1** (UNIQUE NONCLUSTERED INDEX): apt_operacion, apt_secuencial_ing, apt_dividendo, apt_concepto

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
