# ca_operacion_datos_adicionales

## Descripción

Tabla que almacena datos adicionales de las operaciones de cartera. Permite extender la información de los préstamos con campos personalizados según las necesidades del negocio.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| oda_operacion | int | 4 | NOT NULL | Número interno de operación de cartera |
| oda_campo | varchar | 50 | NOT NULL | Nombre del campo adicional |
| oda_valor | varchar | 255 | NULL | Valor del campo adicional |
| oda_tipo_dato | char | 1 | NOT NULL | Tipo de dato<br><br>C = Carácter<br><br>N = Numérico<br><br>F = Fecha<br><br>M = Money |
| oda_obligatorio | char | 1 | NOT NULL | Indica si el campo es obligatorio<br><br>S = Si<br><br>N = No |
| oda_visible | char | 1 | NOT NULL | Indica si el campo es visible<br><br>S = Si<br><br>N = No |

## Índices

- **ca_operacion_datos_adicionales_1** (UNIQUE NONCLUSTERED INDEX): oda_operacion, oda_campo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
