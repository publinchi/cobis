# cr_documento

## Descripción

Almacena la información de los documentos requeridos y presentados para cada trámite de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| do_tramite | Int | 4 | NOT NULL | Número de trámite | |
| do_secuencial | Smallint | 2 | NOT NULL | Secuencial del documento | |
| do_tipo_documento | Varchar | 10 | NOT NULL | Código del tipo de documento | (cl_tabla: cr_tipo_documento) |
| do_descripcion | Varchar | 255 | NULL | Descripción del documento | |
| do_estado | Char | 1 | NOT NULL | Estado del documento | P: Pendiente<br>R: Recibido<br>V: Verificado<br>O: Observado |
| do_obligatorio | Char | 1 | NOT NULL | Indica si es obligatorio | S: Sí<br>N: No |
| do_fecha_recepcion | Datetime | 8 | NULL | Fecha de recepción del documento | |
| do_usuario_recepcion | Varchar | 14 | NULL | Usuario que recibe el documento | |
| do_observacion | Varchar | 255 | NULL | Observaciones sobre el documento | |
| do_ruta_archivo | Varchar | 255 | NULL | Ruta del archivo digital | |

## Transacciones de Servicio

21029, 21129, 21229, 21429, 21529

## Índices

- cr_documento_Key
- cr_documento_idx1
- cr_documento_idx2

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
