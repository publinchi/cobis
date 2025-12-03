# cl_val_iden

## Descripción
Tabla para validación de identificaciones

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| vi_secuencial | Int | 4 | NOT NULL | Secuencial de validación | |
| vi_ente | Int | 4 | NOT NULL | Código del ente | |
| vi_tipo_identificacion | catalogo | 10 | NOT NULL | Tipo de identificación | |
| vi_numero | numero | 30 | NOT NULL | Número de identificación | |
| vi_fecha_validacion | Datetime | 8 | NOT NULL | Fecha de validación | |
| vi_resultado | Char | 1 | NULL | Resultado de validación | A=Aprobado<br>R=Rechazado |
| vi_entidad_validadora | descripcion | 64 | NULL | Entidad que validó | |
| vi_usuario | login | 14 | NULL | Usuario que validó | |
| vi_terminal | descripcion | 64 | NULL | Terminal de validación | |
| vi_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
- Relacionada con cl_ente a través de vi_ente

## Notas
Esta tabla no se utiliza en la versión actual del sistema.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
