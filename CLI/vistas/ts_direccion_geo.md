# ts_direccion_geo

## Descripción
Vista de servicio para consulta de información geográfica de direcciones de clientes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| dg_ente | Int | 4 | NOT NULL | Código del ente | |
| dg_direccion | Tinyint | 1 | NOT NULL | Secuencial de la dirección | |
| dg_latitud | Decimal | 18,6 | NULL | Latitud geográfica | |
| dg_longitud | Decimal | 18,6 | NULL | Longitud geográfica | |
| dg_altitud | Decimal | 10,2 | NULL | Altitud en metros | |
| dg_precision | Decimal | 10,2 | NULL | Precisión de las coordenadas en metros | |
| dg_tipo_coordenada | catalogo | 10 | NULL | Tipo de coordenada | GPS=GPS<br>MAN=Manual<br>EST=Estimada |
| dg_zona | catalogo | 10 | NULL | Zona geográfica | U=Urbana<br>R=Rural |
| dg_referencia_geo | descripcion | 254 | NULL | Referencia geográfica adicional | |
| di_descripcion | descripcion | 254 | NULL | Descripción de la dirección | |

## Relaciones
- Vista basada en cl_direccion_geo con join a cl_direccion

## Notas
Esta vista facilita la consulta de información geográfica de direcciones para análisis espacial.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
