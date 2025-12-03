# cr_imp_documento

## Descripción

Almacena información sobre documentos impresos relacionados con trámites de crédito.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| id_tramite | Int | 4 | NOT NULL | Número de trámite | |
| id_tipo_documento | Varchar | 10 | NOT NULL | Tipo de documento impreso | |
| id_fecha_impresion | Datetime | 8 | NOT NULL | Fecha de impresión | |
| id_usuario | Varchar | 14 | NOT NULL | Usuario que imprime | |
| id_numero_copias | Smallint | 2 | NULL | Número de copias impresas | |
| id_observacion | Varchar | 255 | NULL | Observaciones | |

## Transacciones de Servicio

21031, 21131

## Índices

- cr_imp_documento_Key
- cr_imp_documento_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
