# cr_situacion_poliza

## Descripción

Almacena información sobre las pólizas de seguro asociadas al trámite.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sp_tramite | Int | 4 | NOT NULL | Número de trámite | |
| sp_secuencial | Smallint | 2 | NOT NULL | Secuencial de la póliza | |
| sp_numero_poliza | Varchar | 30 | NULL | Número de póliza | |
| sp_aseguradora | Varchar | 64 | NULL | Nombre de la aseguradora | |
| sp_tipo_seguro | Varchar | 10 | NULL | Tipo de seguro | |
| sp_monto_asegurado | Money | 8 | NULL | Monto asegurado | |
| sp_prima | Money | 8 | NULL | Prima del seguro | |
| sp_fecha_inicio | Datetime | 8 | NULL | Fecha de inicio de vigencia | |
| sp_fecha_fin | Datetime | 8 | NULL | Fecha de fin de vigencia | |
| sp_beneficiario | Varchar | 64 | NULL | Beneficiario de la póliza | |
| sp_estado | Char | 1 | NULL | Estado de la póliza | |

## Transacciones de Servicio

21043, 21143, 21243

## Índices

- cr_situacion_poliza_Key
- cr_situacion_poliza_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
