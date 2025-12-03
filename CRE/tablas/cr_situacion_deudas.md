# cr_situacion_deudas

## Descripción

Almacena información sobre las deudas actuales del cliente en otras instituciones financieras.

## Estructura de la Tabla

| Campo | Tipo | Longitud | Requerido | Descripción | Descripción Funcional |
| --- | --- | --- | --- | --- | --- |
| sd_tramite | Int | 4 | NOT NULL | Número de trámite | |
| sd_secuencial | Smallint | 2 | NOT NULL | Secuencial de la deuda | |
| sd_ente | Int | 4 | NOT NULL | Código de cliente | |
| sd_institucion | Varchar | 64 | NULL | Nombre de la institución financiera | |
| sd_tipo_credito | Varchar | 10 | NULL | Tipo de crédito | |
| sd_monto_original | Money | 8 | NULL | Monto original del crédito | |
| sd_saldo_actual | Money | 8 | NULL | Saldo actual de la deuda | |
| sd_cuota_mensual | Money | 8 | NULL | Cuota mensual | |
| sd_fecha_vencimiento | Datetime | 8 | NULL | Fecha de vencimiento | |
| sd_estado | Varchar | 10 | NULL | Estado de la deuda | |
| sd_dias_mora | Smallint | 2 | NULL | Días de mora | |

## Transacciones de Servicio

21037, 21137, 21237

## Índices

- cr_situacion_deudas_Key
- cr_situacion_deudas_idx1

[Volver al índice principal](../SV-ENL-SPR-CRE-DICCIONARIO-DE-DATOS.md)
