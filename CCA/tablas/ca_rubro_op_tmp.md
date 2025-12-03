# ca_rubro_op_tmp

## Descripción

Tabla temporal que almacena rubros de operaciones durante procesos de simulación o modificación, antes de su aplicación definitiva.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| rot_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| rot_concepto | catalogo | 10 | NOT NULL | Código del concepto/rubro |
| rot_tipo_monto | char | 1 | NOT NULL | Tipo de monto<br><br>P = Porcentaje<br><br>V = Valor fijo |
| rot_valor | money | 8 | NOT NULL | Valor del rubro (porcentaje o monto) |
| rot_fpago | catalogo | 10 | NULL | Forma de pago del rubro |
| rot_estado | char | 1 | NOT NULL | Estado del rubro<br><br>V = Vigente<br><br>I = Inactivo |
| rot_prioridad | tinyint | 1 | NOT NULL | Prioridad de aplicación |
| rot_provisiona | char | 1 | NOT NULL | Si provisiona<br><br>S = Si<br><br>N = No |

## Índices

- **ca_rubro_op_tmp_1** (UNIQUE NONCLUSTERED INDEX): rot_operacion, rot_concepto

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
