# cl_documento_digitalizado

## Descripción
Almacena referencias a documentos digitalizados de los clientes.

## Estructura de la tabla

| Nombre | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
|--------|------|----------|-----------|-------------|----------------------|
| dd_secuencial | Int | 4 | NOT NULL | Secuencial del documento | |
| dd_ente | Int | 4 | NOT NULL | Código del ente | |
| dd_tipo_documento | catalogo | 10 | NOT NULL | Tipo de documento | CI=Cédula<br>PA=Pasaporte<br>RU=RUC<br>SE=Servicios Básicos<br>OT=Otros |
| dd_nombre_archivo | Varchar | 254 | NOT NULL | Nombre del archivo digitalizado | |
| dd_ruta_archivo | Varchar | 500 | NULL | Ruta del archivo en el servidor | |
| dd_extension | Varchar | 10 | NULL | Extensión del archivo | |
| dd_tamanio | Int | 4 | NULL | Tamaño del archivo en KB | |
| dd_fecha_digitalizacion | Datetime | 8 | NOT NULL | Fecha de digitalización | |
| dd_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento del documento | |
| dd_usuario | login | 14 | NULL | Usuario que digitalizó | |
| dd_terminal | descripcion | 64 | NULL | Terminal de registro | |
| dd_estado | estado | 1 | NULL | Estado del documento | V=Vigente<br>C=Cancelado<br>O=Obsoleto |
| dd_observacion | descripcion | 254 | NULL | Observaciones | |
| dd_hash | Varchar | 64 | NULL | Hash del archivo para integridad | |

## Relaciones
- Relacionada con cl_ente a través de dd_ente
- Relacionada con cl_documento_parametro a través de dd_tipo_documento

## Notas
Esta tabla gestiona la documentación digitalizada de los clientes, permitiendo trazabilidad y control documental.

[Volver al índice principal](../CB-COB-CLI-DICCIONARIO-DE-DATOS.md)
