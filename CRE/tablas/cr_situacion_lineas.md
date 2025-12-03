# cr_situacion_lineas

## Descripción

Almacena información sobre las líneas de crédito existentes del cliente.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sl_tramite | Int | 4 | NOT NULL | Número de trámite | |
| sl_secuencial | Smallint | 2 | NOT NULL | Secuencial de la línea | |
| sl_ente | Int | 4 | NOT NULL | Código de cliente | |
| sl_institucion | Varchar | 64 | NULL | Institución financiera | |
| sl_numero_linea | Varchar | 24 | NULL | Número de línea | |
| sl_monto_aprobado | Money | 8 | NULL | Monto aprobado | |
| sl_monto_utilizado | Money | 8 | NULL | Monto utilizado | |
| sl_monto_disponible | Money | 8 | NULL | Monto disponible | |
| sl_fecha_aprobacion | Datetime | 8 | NULL | Fecha de aprobación | |
| sl_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |
| sl_estado | Char | 1 | NULL | Estado de la línea | |

## Transacciones de Servicio

21041, 21141, 21241

## Índices

- cr_situacion_lineas_Key
- cr_situacion_lineas_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
