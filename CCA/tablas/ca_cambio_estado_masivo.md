# ca_cambio_estado_masivo

## Descripción

Tabla que registra los cambios de estado masivos realizados a operaciones de cartera. Permite llevar el control de modificaciones masivas de estados.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| cem_secuencial | int | 4 | NOT NULL | Secuencial del proceso masivo |
| cem_fecha_proceso | datetime | 8 | NOT NULL | Fecha del proceso |
| cem_estado_origen | tinyint | 1 | NOT NULL | Estado origen |
| cem_estado_destino | tinyint | 1 | NOT NULL | Estado destino |
| cem_criterio_seleccion | varchar | 500 | NOT NULL | Criterio de selección de operaciones |
| cem_cantidad_operaciones | int | 4 | NOT NULL | Cantidad de operaciones procesadas |
| cem_cantidad_exitosas | int | 4 | NOT NULL | Cantidad de operaciones exitosas |
| cem_cantidad_errores | int | 4 | NOT NULL | Cantidad de operaciones con error |
| cem_estado | char | 1 | NOT NULL | Estado del proceso<br><br>P = En proceso<br><br>C = Completado<br><br>E = Con errores |
| cem_usuario | login | 14 | NOT NULL | Usuario que ejecutó el proceso |
| cem_fecha_inicio | datetime | 8 | NOT NULL | Fecha de inicio del proceso |
| cem_fecha_fin | datetime | 8 | NULL | Fecha de fin del proceso |
| cem_observacion | varchar | 255 | NULL | Observaciones del proceso |
| cem_autorizado_por | login | 14 | NULL | Usuario que autorizó el cambio |
| cem_fecha_autorizacion | datetime | 8 | NULL | Fecha de autorización |

## Índices

- **ca_cambio_estado_masivo_1** (UNIQUE NONCLUSTERED INDEX): cem_secuencial
- **ca_cambio_estado_masivo_2** (NONCLUSTERED INDEX): cem_fecha_proceso
- **ca_cambio_estado_masivo_3** (NONCLUSTERED INDEX): cem_estado

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
