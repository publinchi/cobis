# cl_refinh

## Descripción
Contiene información de referencias inhabilitadas o bloqueadas del sistema.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ri_secuencial | Int | 4 | NOT NULL | Secuencial de la referencia inhabilitada | |
| ri_ente | Int | 4 | NULL | Código del ente relacionado | |
| ri_tipo_referencia | catalogo | 10 | NULL | Tipo de referencia | P=Personal<br>B=Bancaria<br>C=Comercial |
| ri_nombre | descripcion | 64 | NULL | Nombre de la referencia | |
| ri_identificacion | numero | 30 | NULL | Número de identificación | |
| ri_motivo | descripcion | 254 | NULL | Motivo de inhabilitación | |
| ri_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| ri_usuario | login | 14 | NULL | Usuario que registró | |
| ri_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ri_estado | estado | 1 | NULL | Estado | V=Vigente<br>C=Cancelado |
| ri_fecha_inhabilitacion | Datetime | 8 | NULL | Fecha de inhabilitación | |
| ri_observacion | descripcion | 254 | NULL | Observaciones adicionales | |

## Relaciones
- Relacionada con cl_ente a través de ri_ente

## Notas
Esta tabla registra referencias que han sido inhabilitadas por diversos motivos, evitando su uso futuro.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
