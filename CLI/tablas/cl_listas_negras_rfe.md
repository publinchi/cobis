# cl_listas_negras_rfe

## Descripción
Contiene información de listas negras relacionadas con RFE (Relación Financiera con el Ente).

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| lr_secuencial | Int | 4 | NOT NULL | Secuencial del registro | |
| lr_nombre | descripcion | 254 | NOT NULL | Nombre completo | |
| lr_identificacion | Varchar | 50 | NULL | Número de identificación | |
| lr_tipo_identificacion | catalogo | 10 | NULL | Tipo de identificación | |
| lr_tipo_lista | catalogo | 10 | NOT NULL | Tipo de lista | OFAC=OFAC<br>ONU=ONU<br>PEP=PEP<br>OTR=Otros |
| lr_pais | catalogo | 10 | NULL | País de origen | |
| lr_fecha_inclusion | Datetime | 8 | NULL | Fecha de inclusión en la lista | |
| lr_fecha_registro | Datetime | 8 | NOT NULL | Fecha de registro en el sistema | |
| lr_fuente | descripcion | 64 | NULL | Fuente de información | |
| lr_observacion | descripcion | 254 | NULL | Observaciones | |
| lr_usuario | login | 14 | NULL | Usuario que registró | |
| lr_terminal | descripcion | 64 | NULL | Terminal de registro | |
| lr_estado | estado | 1 | NULL | Estado del registro | V=Vigente<br>C=Cancelado |
| lr_fecha_actualizacion | Datetime | 8 | NULL | Fecha de última actualización | |

## Relaciones
No tiene relaciones directas con otras tablas

## Notas
Esta tabla almacena información de listas restrictivas para validación de relaciones financieras.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
