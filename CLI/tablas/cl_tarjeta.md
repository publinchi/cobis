# cl_tarjeta

## Descripción
Contiene información de tarjetas de crédito o débito asociadas a los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ta_ente | Int | 4 | NOT NULL | Código del ente | |
| ta_secuencial | Tinyint | 1 | NOT NULL | Secuencial de la tarjeta | |
| ta_numero | Varchar | 20 | NULL | Número de tarjeta (encriptado) | |
| ta_tipo | catalogo | 10 | NULL | Tipo de tarjeta | C=Crédito<br>D=Débito |
| ta_marca | catalogo | 10 | NULL | Marca de la tarjeta | V=Visa<br>M=Mastercard<br>A=American Express<br>D=Diners<br>O=Otros |
| ta_banco_emisor | descripcion | 64 | NULL | Banco emisor | |
| ta_fecha_emision | Datetime | 8 | NULL | Fecha de emisión | |
| ta_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |
| ta_cupo | money | 8 | NULL | Cupo de la tarjeta | |
| ta_estado | estado | 1 | NULL | Estado de la tarjeta | V=Vigente<br>C=Cancelada<br>B=Bloqueada |
| ta_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| ta_usuario | login | 14 | NULL | Usuario que registró | |
| ta_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ta_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de ta_ente

## Notas
Esta tabla almacena información de tarjetas para análisis de capacidad crediticia y medios de pago.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
