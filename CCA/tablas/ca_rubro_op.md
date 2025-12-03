# ca_rubro_op

## Descripción

Tabla que almacena los rubros específicos de cada operación de cartera. Contiene los valores y características particulares de cada rubro aplicado a un préstamo.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| ro_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| ro_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| ro_tipo_monto | char | 1 | NOT NULL | Tipo de monto<br><br>P = Porcentaje<br><br>V = Valor fijo |
| ro_valor | money | 8 | NOT NULL | Valor del rubro (porcentaje o monto) |
| ro_fpago | catalogo | 10 | NULL | Forma de pago del rubro |
| ro_estado | char | 1 | NOT NULL | Estado del rubro<br><br>V = Vigente<br><br>I = Inactivo |
| ro_prioridad | tinyint | 1 | NOT NULL | Prioridad de aplicación |
| ro_provisiona | char | 1 | NOT NULL | Si provisiona<br><br>S = Si<br><br>N = No |

## Índices

- **ca_rubro_op_1** (UNIQUE NONCLUSTERED INDEX): ro_operacion, ro_concepto

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
