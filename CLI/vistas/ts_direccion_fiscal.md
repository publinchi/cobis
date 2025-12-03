# ts_direccion_fiscal

## Descripción
Vista de servicio para consulta de direcciones fiscales de clientes.

**NOTA: No se usa en esta versión**

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| df_ente | Int | 4 | NOT NULL | Código del ente | |
| df_secuencial | Tinyint | 1 | NOT NULL | Secuencial de la dirección fiscal | |
| df_pais | catalogo | 10 | NOT NULL | País de la dirección fiscal | |
| df_direccion | descripcion | 254 | NOT NULL | Dirección fiscal completa | |
| df_ciudad | Int | 4 | NULL | Código de la ciudad | |
| df_codigo_postal | Varchar | 20 | NULL | Código postal | |
| df_tipo | catalogo | 10 | NULL | Tipo de dirección fiscal | PR=Principal<br>SE=Secundaria |
| df_estado | estado | 1 | NULL | Estado | V=Vigente<br>C=Cancelado |
| nombre_pais | descripcion | 64 | NULL | Nombre del país | |

## Relaciones
- Vista basada en cl_direccion_fiscal con joins a tablas de geografía

## Notas
Esta vista no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
