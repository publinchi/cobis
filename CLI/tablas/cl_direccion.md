# cl_direccion

## Descripción
Contiene las direcciones de los clientes (entes) registrados en el sistema.

## Estructura de la tabla

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
| di_fecha_registro | Datetime | 8 | NULL | Fecha de registro de la dirección | |
| di_vigencia | Char | 1 | NULL | Vigencia de la dirección | S=Vigente<br>N=No vigente |
| di_provincia | Int | 4 | NULL | Código de la provincia | |
| di_barrio | descripcion | 64 | NULL | Barrio de la dirección | |
| di_referencia | descripcion | 254 | NULL | Referencia de ubicación | |

## Relaciones
- Relacionada con cl_ente a través de di_ente
- Relacionada con cl_ciudad (tabla de administración) a través de di_ciudad
- Relacionada con cl_parroquia (tabla de administración) a través de di_parroquia
- Relacionada con cl_provincia (tabla de administración) a través de di_provincia

## Notas
Esta tabla almacena múltiples direcciones por cliente, permitiendo clasificarlas por tipo y establecer una como principal.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
