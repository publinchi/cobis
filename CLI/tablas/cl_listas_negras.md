# cl_listas_negras

## Descripción
Contiene información de personas o entidades que están en listas negras o restrictivas

**NOTA: No se usa en esta versión**

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| ln_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| ln_nombre | descripcion | 254 | NOT NULL | Nombre completo | |
| ln_identificacion | numero | 30 | NULL | Número de identificación | |
| ln_tipo_identificacion | catalogo | 10 | NULL | Tipo de documento | |
| ln_tipo_lista | catalogo | 10 | NULL | Tipo de lista | N=Narcotráfico<br>T=Terrorismo<br>L=Lavado de Activos<br>O=Otros |
| ln_pais | catalogo | 10 | NULL | País de origen | |
| ln_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro | |
| ln_usuario | login | 14 | NULL | Usuario que registró | |
| ln_terminal | descripcion | 64 | NULL | Terminal de registro | |
| ln_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |
| ln_fuente | descripcion | 64 | NULL | Fuente de información | |
| ln_observacion | descripcion | 254 | NULL | Observaciones | |

## Relaciones
No tiene relaciones directas con otras tablas

## Notas
Esta tabla no se utiliza en la versión actual del sistema. Se utiliza cl_narcos en su lugar.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
