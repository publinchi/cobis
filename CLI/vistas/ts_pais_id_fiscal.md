# ts_pais_id_fiscal

## Descripción
Vista de servicio para consulta de identificaciones fiscales por país.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| pf_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| pf_ente | Int | 4 | NOT NULL | Código del ente | |
| pf_pais | catalogo | 10 | NOT NULL | Código del país | |
| pf_numero_identificacion | Varchar | 50 | NULL | Número de identificación fiscal en el país | |
| pf_tipo_identificacion | catalogo | 10 | NULL | Tipo de identificación fiscal | |
| pf_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| pf_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |
| nombre_pais | descripcion | 64 | NULL | Nombre del país | |
| nombre_ente | descripcion | 254 | NULL | Nombre del ente | |

## Relaciones
- Vista basada en cl_pais_id_fiscal con joins a cl_ente y tablas de catálogos

## Notas
Esta vista facilita la consulta de identificaciones fiscales internacionales.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
