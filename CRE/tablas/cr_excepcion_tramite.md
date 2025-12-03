# cr_excepcion_tramite

## Descripción

Almacena las excepciones o dispensas otorgadas a un trámite de crédito respecto a las políticas estándar.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| et_tramite | Int | 4 | NOT NULL | Número de trámite | |
| et_secuencial | Smallint | 2 | NOT NULL | Secuencial de la excepción | |
| et_tipo_excepcion | Varchar | 10 | NOT NULL | Tipo de excepción | (cl_tabla: cr_tipo_excepcion) |
| et_descripcion | Varchar | 255 | NULL | Descripción de la excepción | |
| et_justificacion | Varchar | 1000 | NULL | Justificación de la excepción | |
| et_usuario_solicita | Varchar | 14 | NOT NULL | Usuario que solicita la excepción | |
| et_fecha_solicita | Datetime | 8 | NOT NULL | Fecha de solicitud | |
| et_usuario_aprueba | Varchar | 14 | NULL | Usuario que aprueba la excepción | |
| et_fecha_aprueba | Datetime | 8 | NULL | Fecha de aprobación | |
| et_estado | Char | 1 | NOT NULL | Estado de la excepción | P: Pendiente<br>A: Aprobada<br>R: Rechazada |

## Transacciones de Servicio

21030, 21130, 21230

## Índices

- cr_excepcion_tramite_Key
- cr_excepcion_tramite_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
