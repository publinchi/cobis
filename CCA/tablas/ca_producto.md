# ca_producto

## Descripción

Tabla que define las formas de pago y desembolso disponibles para las operaciones de cartera. Parametriza los métodos de cobro y entrega de fondos.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| pr_codigo | catalogo | 10 | NOT NULL | Código del producto/forma |
| pr_descripcion | descripcion | 64 | NOT NULL | Descripción del producto |
| pr_tipo | char | 1 | NOT NULL | Tipo de producto<br><br>P = Forma de pago<br><br>D = Forma de desembolso |
| pr_categoria | catalogo | 10 | NOT NULL | Categoría del producto |
| pr_requiere_cuenta | char | 1 | NOT NULL | Si requiere número de cuenta<br><br>S = Si<br><br>N = No |
| pr_requiere_banco | char | 1 | NOT NULL | Si requiere código de banco<br><br>S = Si<br><br>N = No |
| pr_automatico | char | 1 | NOT NULL | Si es automático<br><br>S = Si<br><br>N = No |
| pr_estado | char | 1 | NOT NULL | Estado del producto<br><br>V = Vigente<br><br>I = Inactivo |

## Índices

- **ca_producto_1** (UNIQUE NONCLUSTERED INDEX): pr_codigo

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
