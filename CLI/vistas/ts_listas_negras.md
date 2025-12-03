# ts_listas_negras

## Descripción
Vista de servicio para consulta de listas negras o restrictivas.

## Estructura de la vista

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| na_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| na_nombre | descripcion | 254 | NOT NULL | Nombre completo | |
| na_identificacion | numero | 30 | NULL | Número de identificación | |
| na_tipo_identificacion | catalogo | 10 | NULL | Tipo de documento | |
| na_nacionalidad | catalogo | 10 | NULL | Nacionalidad | |
| na_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| na_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |
| na_fuente | descripcion | 64 | NULL | Fuente de información | |

## Relaciones
- Vista basada en cl_narcos

## Notas
Esta vista facilita la consulta de listas restrictivas para validación de clientes.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
