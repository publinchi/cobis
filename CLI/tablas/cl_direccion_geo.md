# cl_direccion_geo

## Descripción
Contiene información geográfica detallada de las direcciones de los clientes, incluyendo coordenadas y referencias geoespaciales.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| dg_ente | Int | 4 | NOT NULL | Código del ente | |
| dg_direccion | Tinyint | 1 | NOT NULL | Secuencial de la dirección | |
| dg_latitud | Decimal | 18,6 | NULL | Latitud geográfica | |
| dg_longitud | Decimal | 18,6 | NULL | Longitud geográfica | |
| dg_altitud | Decimal | 10,2 | NULL | Altitud en metros | |
| dg_precision | Decimal | 10,2 | NULL | Precisión de las coordenadas en metros | |
| dg_tipo_coordenada | catalogo | 10 | NULL | Tipo de coordenada | GPS=GPS<br>MAN=Manual<br>EST=Estimada |
| dg_fecha_registro | Datetime | 8 | NULL | Fecha de registro | |
| dg_usuario | login | 14 | NULL | Usuario que registró | |
| dg_terminal | descripcion | 64 | NULL | Terminal de registro | |
| dg_zona | catalogo | 10 | NULL | Zona geográfica | U=Urbana<br>R=Rural |
| dg_referencia_geo | descripcion | 254 | NULL | Referencia geográfica adicional | |

## Relaciones
- Relacionada con cl_ente a través de dg_ente
- Relacionada con cl_direccion a través de dg_ente y dg_direccion

## Notas
Esta tabla permite almacenar información geográfica precisa para análisis espacial y geolocalización de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
