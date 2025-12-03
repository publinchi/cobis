# ca_datos_adicionales_pasivas_t

## Descripción

Tabla temporal que almacena datos adicionales de operaciones de cartera pasiva durante procesos de simulación o modificación, antes de su aplicación definitiva.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| dapt_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| dapt_campo | varchar | 50 | NOT NULL | Nombre del campo adicional |
| dapt_valor | varchar | 255 | NULL | Valor del campo adicional |
| dapt_tipo_dato | char | 1 | NOT NULL | Tipo de dato<br><br>C = Carácter<br><br>N = Numérico<br><br>F = Fecha<br><br>M = Money |
| dapt_obligatorio | char | 1 | NOT NULL | Indica si el campo es obligatorio<br><br>S = Si<br><br>N = No |

## Índices

- **ca_datos_adicionales_pasivas_t_1** (UNIQUE NONCLUSTERED INDEX): dapt_operacion, dapt_campo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
