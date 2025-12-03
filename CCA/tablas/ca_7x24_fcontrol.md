# ca_7x24_fcontrol

## Descripción

Tabla de control de fecha para el manejo de saldos en el servicio 7x24. Permite mantener la sincronización de fechas entre el sistema transaccional y el servicio de consultas.

## Estructura de la Tabla

| **NOMBRE DEL CAMPO** | **TIPO DE DATO** | **LONG** | **ESTATUS** | **descripcion** |
| --- | --- | --- | --- | --- |
| fc_fecha_proceso | datetime | 8 | NOT NULL | Fecha de proceso del sistema |
| fc_fecha_saldos | datetime | 8 | NOT NULL | Fecha de los saldos disponibles |
| fc_estado | char | 1 | NOT NULL | Estado del control<br><br>A = Actualizado<br><br>P = En proceso<br><br>E = Error |
| fc_fecha_actualizacion | datetime | 8 | NOT NULL | Fecha de última actualización |
| fc_usuario | login | 14 | NOT NULL | Usuario que actualizó |
| fc_observacion | varchar | 255 | NULL | Observaciones |

## Índices

- **ca_7x24_fcontrol_1** (UNIQUE NONCLUSTERED INDEX): fc_fecha_proceso

[Volver al índice principal](../SV_ENL-CCA-DICCIONARIO-DE-DATOS.md)
