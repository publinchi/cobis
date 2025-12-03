# cl_det_producto

## Descripción
Contiene información de los productos contratados por los clientes en los diferentes módulos de COBIS.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| dp_cuenta | cuenta | 24 | NOT NULL | Número de cuenta del producto contratado | |
| dp_producto | Tinyint | 1 | NOT NULL | Código del producto contratado | 1=Ahorros<br>2=Corriente<br>3=Crédito<br>4=Plazo Fijo |
| dp_oficina | Smallint | 2 | NOT NULL | Código de la oficina donde se contrató el producto | |
| dp_moneda | Tinyint | 1 | NOT NULL | Código de la moneda del producto | |
| dp_fecha_aper | Datetime | 8 | NOT NULL | Fecha de apertura del producto | |
| dp_fecha_ult_mov | Datetime | 8 | NULL | Fecha del último movimiento | |
| dp_fecha_ult_corte | Datetime | 8 | NULL | Fecha del último corte | |
| dp_estado | estado | 1 | NOT NULL | Estado del producto | V=Vigente<br>C=Cancelado |

## Relaciones
- Relacionada con cl_oficina (tabla de administración) a través de dp_oficina
- Relacionada con cl_moneda (tabla de administración) a través de dp_moneda

## Notas
Esta tabla es fundamental para vincular clientes con sus productos contratados en diferentes módulos.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
