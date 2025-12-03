# cl_direccion_fiscal

## Descripción
Contiene las direcciones fiscales de los clientes para efectos tributarios

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| df_ente | Int | 4 | NOT NULL | Código del ente | |
| df_secuencial | Tinyint | 1 | NOT NULL | Secuencial de la dirección fiscal | |
| df_pais | catalogo | 10 | NOT NULL | País de la dirección fiscal | |
| df_direccion | descripcion | 254 | NOT NULL | Dirección fiscal completa | |
| df_ciudad | Int | 4 | NULL | Código de la ciudad | |
| df_codigo_postal | Varchar | 20 | NULL | Código postal | |
| df_tipo | catalogo | 10 | NULL | Tipo de dirección fiscal | PR=Principal<br>SE=Secundaria |
| df_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| df_usuario | login | 14 | NULL | Usuario que registró | |
| df_terminal | descripcion | 64 | NULL | Terminal de registro | |
| df_estado | estado | 1 | NULL | Estado | V=Vigente<br>C=Cancelado |
| df_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de df_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
