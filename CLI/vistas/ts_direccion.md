# ts_direccion

## Descripción
Vista de servicio para consulta de direcciones de clientes.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| di_ente | Int | 4 | NOT NULL | Código del ente | |
| di_direccion | Tinyint | 1 | NOT NULL | Secuencial de la dirección | |
| di_descripcion | descripcion | 254 | NULL | Descripción de la dirección | |
| di_ciudad | Int | 4 | NULL | Código de la ciudad | |
| di_sector | descripcion | 64 | NULL | Sector de la dirección | |
| di_parroquia | Int | 4 | NULL | Código de la parroquia | |
| di_tipo | catalogo | 10 | NULL | Tipo de dirección | R=Residencia<br>T=Trabajo<br>O=Otros |
| di_principal | Char | 1 | NULL | Indica si es dirección principal | S=Sí<br>N=No |
| di_provincia | Int | 4 | NULL | Código de la provincia | |
| di_barrio | descripcion | 64 | NULL | Barrio de la dirección | |
| di_referencia | descripcion | 254 | NULL | Referencia de ubicación | |
| nombre_ciudad | descripcion | 64 | NULL | Nombre de la ciudad | |
| nombre_provincia | descripcion | 64 | NULL | Nombre de la provincia | |

## Relaciones
- Vista basada en cl_direccion con joins a tablas de geografía

## Notas
Esta vista facilita la consulta de direcciones con información geográfica completa.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
