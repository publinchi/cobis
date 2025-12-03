# cl_pais_id_fiscal

## Descripción
Contiene información de países para identificación fiscal de clientes con obligaciones tributarias internacionales.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| pf_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| pf_ente | Int | 4 | NOT NULL | Código del ente | |
| pf_pais | catalogo | 10 | NOT NULL | Código del país | |
| pf_numero_identificacion | Varchar | 50 | NULL | Número de identificación fiscal en el país | |
| pf_tipo_identificacion | catalogo | 10 | NULL | Tipo de identificación fiscal | |
| pf_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| pf_usuario | login | 14 | NULL | Usuario que registró | |
| pf_terminal | descripcion | 64 | NULL | Terminal de registro | |
| pf_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |
| pf_observacion | descripcion | 254 | NULL | Observaciones | |
| pf_fecha_actualizacion | Datetime | 8 | NULL | Fecha de última actualización | |

## Relaciones
- Relacionada con cl_ente a través de pf_ente

## Notas
Esta tabla es importante para cumplimiento de normativas internacionales como FATCA y CRS.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
