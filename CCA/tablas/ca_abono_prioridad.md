# ca_abono_prioridad

## Descripción

Tabla que almacena la prioridad de aplicación de los rubros al momento de realizar un pago. Define el orden en que se aplicarán los diferentes conceptos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ap_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| ap_secuencial_ing | int | 4 | NOT NULL | Secuencial único de ingreso del pago |
| ap_dividendo | smallint | 2 | NOT NULL | Número de dividendo |
| ap_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| ap_prioridad | tinyint | 1 | NOT NULL | Orden de prioridad de aplicación |
| ap_monto | money | 8 | NOT NULL | Monto a aplicar al concepto |
| ap_estado | char | 1 | NOT NULL | Estado de la prioridad<br><br>V = Vigente<br><br>A = Aplicado<br><br>C = Cancelado |

## Índices

- **ca_abono_prioridad_1** (UNIQUE NONCLUSTERED INDEX): ap_operacion, ap_secuencial_ing, ap_dividendo, ap_concepto

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
